// CLI: curate the CC0 Lichess puzzle DB into a bundled JSON subset.
//
// Download `lichess_db_puzzle.csv.zst` from https://database.lichess.org/#puzzles
// (CC0), decompress, then:
//
//   dart run tool/curate_puzzles.dart <input.csv> <output.json> \
//       [--per-bucket=N] [--min-plays=N] [--min-popularity=N] \
//       [--min-rating=N] [--max-rating=N] [--themes=fork,pin,...]
//
// Streams the (large) CSV line by line and pre-filters before curating, so it
// doesn't hold the whole file in memory.
import 'dart:convert';
import 'dart:io';

import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/engine/engine.dart';

import 'puzzle_curation.dart';

/// Whether our own engine can replay the whole solution line — bundle only
/// puzzles the app can actually run (and a cross-check against real data).
bool engineValid(TacticsPuzzle p) {
  try {
    var pos = Position.fromFen(p.fen);
    for (final uci in p.solution) {
      final move = Move.uci(uci);
      if (!generateLegalMoves(pos).contains(move)) return false;
      pos = pos.applyMove(move);
    }
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.length < 2) {
    stderr.writeln(
      'usage: dart run tool/curate_puzzles.dart <input.csv> <output.json> '
      '[--per-bucket=N] [--min-plays=N] [--min-popularity=N] '
      '[--min-rating=N] [--max-rating=N] [--themes=a,b,c]',
    );
    exitCode = 2;
    return;
  }

  final flags = <String, String>{
    for (final a in args.where((a) => a.startsWith('--')))
      a.substring(2).split('=').first: a.contains('=') ? a.split('=').last : '',
  };
  int flagInt(String name, int fallback) {
    final raw = flags[name];
    return raw != null && raw.isNotEmpty ? int.parse(raw) : fallback;
  }

  final perBucket = flagInt('per-bucket', 50);
  final minNbPlays = flagInt('min-plays', 100);
  final minPopularity = flagInt('min-popularity', 80);
  final minRating = flagInt('min-rating', 0);
  final maxRating = flagInt('max-rating', 4000);
  final themes = flags['themes'] != null && flags['themes']!.isNotEmpty
      ? flags['themes']!.split(',').toSet()
      : null;

  final rows = <LichessPuzzleRow>[];
  final lines = File(positional[0])
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    final row = parseLichessRow(line);
    if (row != null &&
        row.popularity >= minPopularity &&
        row.nbPlays >= minNbPlays &&
        row.puzzle.rating >= minRating &&
        row.puzzle.rating <= maxRating) {
      rows.add(row);
    }
  }

  final validRows = rows.where((r) => engineValid(r.puzzle)).toList();
  final droppedInvalid = rows.length - validRows.length;

  final curated = curate(
    validRows,
    perBucket: perBucket,
    minNbPlays: minNbPlays,
    minPopularity: minPopularity,
    minRating: minRating,
    maxRating: maxRating,
    themes: themes,
  );
  File(positional[1]).writeAsStringSync(curatedToJson(curated));
  stdout.writeln('Curated ${curated.length} puzzles '
      '($droppedInvalid dropped as engine-invalid) '
      '-> ${positional[1]}');
}
