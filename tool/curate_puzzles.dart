// CLI: curate the CC0 Lichess puzzle DB into a bundled JSON subset.
//
// Download `lichess_db_puzzle.csv.zst` from https://database.lichess.org/#puzzles
// (CC0), decompress, then:
//
//   dart run tool/curate_puzzles.dart <input.csv> <output.json> \
//       [perBucket=50] [minNbPlays=100] [minPopularity=80]
//
// Streams the (large) CSV line by line and pre-filters before curating, so it
// doesn't hold the whole file in memory.
import 'dart:convert';
import 'dart:io';

import 'puzzle_curation.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
        'usage: dart run tool/curate_puzzles.dart <input.csv> <output.json> '
        '[perBucket] [minNbPlays] [minPopularity]');
    exitCode = 2;
    return;
  }

  final perBucket = args.length > 2 ? int.parse(args[2]) : 50;
  final minNbPlays = args.length > 3 ? int.parse(args[3]) : 100;
  final minPopularity = args.length > 4 ? int.parse(args[4]) : 80;

  final rows = <LichessPuzzleRow>[];
  final lines = File(args[0])
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    final row = parseLichessRow(line);
    if (row != null &&
        row.popularity >= minPopularity &&
        row.nbPlays >= minNbPlays) {
      rows.add(row);
    }
  }

  final curated = curate(rows,
      perBucket: perBucket,
      minNbPlays: minNbPlays,
      minPopularity: minPopularity);
  File(args[1]).writeAsStringSync(curatedToJson(curated));
  stdout.writeln('Curated ${curated.length} puzzles -> ${args[1]}');
}
