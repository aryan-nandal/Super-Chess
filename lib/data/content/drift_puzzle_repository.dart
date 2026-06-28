import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/tactics/tactics.dart';
import 'content_database.dart';

/// Drift-backed [PuzzleRepository] over the read-only [ContentDatabase].
class DriftPuzzleRepository implements PuzzleRepository {
  final ContentDatabase db;
  final Random _random;

  DriftPuzzleRepository(this.db, {Random? random}) : _random = random ?? Random();

  @override
  Future<TacticsPuzzle?> byId(String id) async {
    final row = await (db.select(db.puzzles)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _assemble(row);
  }

  @override
  Future<List<TacticsPuzzle>> byTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
    int limit = 50,
  }) async {
    final rows = await (_taggedWithin(theme, minRating, maxRating)
          ..orderBy([OrderingTerm.asc(db.puzzles.rating)])
          ..limit(limit))
        .get();
    final puzzleRows = rows.map((r) => r.readTable(db.puzzles)).toList();
    if (puzzleRows.isEmpty) return [];

    final themesByPuzzle = <String, List<String>>{};
    final themeRows = await (db.select(db.puzzleThemes)
          ..where((t) => t.puzzleId.isIn(puzzleRows.map((p) => p.id))))
        .get();
    for (final t in themeRows) {
      (themesByPuzzle[t.puzzleId] ??= <String>[]).add(t.theme);
    }

    return puzzleRows
        .map((row) => _build(row, themesByPuzzle[row.id] ?? <String>[]))
        .toList();
  }

  @override
  Future<TacticsPuzzle?> randomByTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
  }) async {
    final count = await _countTagged(theme, minRating, maxRating);
    if (count == 0) return null;
    final row = await (_taggedWithin(theme, minRating, maxRating)
          ..orderBy([OrderingTerm.asc(db.puzzles.id)])
          ..limit(1, offset: _random.nextInt(count)))
        .getSingle();
    return _assemble(row.readTable(db.puzzles));
  }

  @override
  Future<List<String>> themes() async {
    final query = db.selectOnly(db.puzzleThemes, distinct: true)
      ..addColumns([db.puzzleThemes.theme]);
    final rows = await query.get();
    return rows.map((r) => r.read(db.puzzleThemes.theme)!).toList()..sort();
  }

  /// Puzzles joined to their theme rows, filtered to [theme] within the rating
  /// band.
  JoinedSelectStatement _taggedWithin(String theme, int minRating, int maxRating) {
    return db.select(db.puzzles).join([
      innerJoin(
        db.puzzleThemes,
        db.puzzleThemes.puzzleId.equalsExp(db.puzzles.id),
      ),
    ])
      ..where(_matches(theme, minRating, maxRating));
  }

  /// Filter for puzzles tagged with [theme] inside the inclusive rating band.
  Expression<bool> _matches(String theme, int minRating, int maxRating) =>
      db.puzzleThemes.theme.equals(theme) &
      db.puzzles.rating.isBetweenValues(minRating, maxRating);

  Future<int> _countTagged(String theme, int minRating, int maxRating) async {
    final count = countAll();
    final row = await (db.selectOnly(db.puzzles).join([
      innerJoin(
        db.puzzleThemes,
        db.puzzleThemes.puzzleId.equalsExp(db.puzzles.id),
      ),
    ])
          ..addColumns([count])
          ..where(_matches(theme, minRating, maxRating)))
        .getSingle();
    return row.read(count)!;
  }

  Future<TacticsPuzzle> _assemble(Puzzle row) async {
    final themeRows = await (db.select(db.puzzleThemes)
          ..where((t) => t.puzzleId.equals(row.id)))
        .get();
    return _build(row, themeRows.map((t) => t.theme).toList());
  }

  TacticsPuzzle _build(Puzzle row, List<String> themes) {
    return TacticsPuzzle(
      id: row.id,
      fen: row.fen,
      solution: row.movesUci.split(' ').where((s) => s.isNotEmpty).toList(),
      rating: row.rating,
      themes: themes..sort(),
    );
  }
}
