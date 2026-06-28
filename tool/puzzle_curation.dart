// Offline curation logic for the CC0 Lichess puzzle database. Pure Dart, no
// Flutter — lives under tool/ (not lib/) so it never ships in the app; only
// the curated JSON output is bundled. The CLI wrapper is `curate_puzzles.dart`.
import 'dart:convert';

import 'package:super_chess/domain/tactics/tactics.dart';

/// A parsed Lichess CSV row plus the fields used for quality filtering.
class LichessPuzzleRow {
  final TacticsPuzzle puzzle;
  final int popularity;
  final int nbPlays;

  const LichessPuzzleRow(
    this.puzzle, {
    required this.popularity,
    required this.nbPlays,
  });
}

/// Parses one line of `lichess_db_puzzle.csv`. Columns:
/// `PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags`.
/// Returns `null` for the header, blanks, or malformed rows. (Fields in this
/// dataset never contain commas, so a plain split is safe.)
LichessPuzzleRow? parseLichessRow(String line) {
  if (line.trim().isEmpty) return null;
  final c = line.split(',');
  if (c.length < 8 || c[0] == 'PuzzleId') return null;

  final moves = c[2].split(' ').where((s) => s.isNotEmpty).toList();
  if (c[0].isEmpty || c[1].isEmpty || moves.isEmpty) return null;

  return LichessPuzzleRow(
    TacticsPuzzle(
      id: c[0],
      fen: c[1],
      solution: moves,
      rating: int.tryParse(c[3]) ?? 0,
      themes: c[7].split(' ').where((s) => s.isNotEmpty).toList(),
    ),
    popularity: int.tryParse(c[5]) ?? 0,
    nbPlays: int.tryParse(c[6]) ?? 0,
  );
}

/// The lower bound of the rating band [rating] falls in (default width 200).
int ratingBand(int rating, {int width = 200}) => (rating ~/ width) * width;

/// Curates [rows] into a stratified, quality-filtered subset: drop rows below
/// the [minPopularity]/[minNbPlays] thresholds, group by `theme × rating band`,
/// keep the [perBucket] most-played per bucket, de-duplicate by id, and return
/// rating-ascending. If [themes] is given, only those motifs are kept.
List<TacticsPuzzle> curate(
  Iterable<LichessPuzzleRow> rows, {
  int perBucket = 50,
  int minNbPlays = 0,
  int minPopularity = 0,
  int bandWidth = 200,
  Set<String>? themes,
}) {
  final buckets = <String, List<LichessPuzzleRow>>{};
  for (final row in rows) {
    if (row.popularity < minPopularity || row.nbPlays < minNbPlays) continue;
    final band = ratingBand(row.puzzle.rating, width: bandWidth);
    for (final theme in row.puzzle.themes) {
      if (themes != null && !themes.contains(theme)) continue;
      (buckets['$theme@$band'] ??= []).add(row);
    }
  }

  final picked = <String, TacticsPuzzle>{}; // id -> puzzle (dedup)
  for (final bucket in buckets.values) {
    final byPlays = [...bucket]..sort((a, b) => b.nbPlays.compareTo(a.nbPlays));
    for (final row in byPlays.take(perBucket)) {
      picked[row.puzzle.id] = row.puzzle;
    }
  }

  return picked.values.toList()..sort((a, b) => a.rating.compareTo(b.rating));
}

/// Serializes curated puzzles to the bundled JSON shape (pretty-printed).
String curatedToJson(List<TacticsPuzzle> puzzles) =>
    const JsonEncoder.withIndent(
      '  ',
    ).convert(puzzles.map((p) => p.toJson()).toList());
