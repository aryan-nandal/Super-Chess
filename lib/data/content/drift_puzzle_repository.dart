import 'package:drift/drift.dart';

import '../../domain/tactics/tactics.dart';
import 'content_database.dart';

/// Drift-backed [PuzzleRepository] over the read-only [ContentDatabase].
class DriftPuzzleRepository implements PuzzleRepository {
  final ContentDatabase db;

  DriftPuzzleRepository(this.db);

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
    return Future.wait(rows.map((r) => _assemble(r.readTable(db.puzzles))));
  }

  @override
  Future<TacticsPuzzle?> randomByTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
  }) async {
    final row = await (_taggedWithin(theme, minRating, maxRating)
          ..orderBy([OrderingTerm(expression: const CustomExpression('RANDOM()'))])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _assemble(row.readTable(db.puzzles));
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
      ..where(db.puzzleThemes.theme.equals(theme) &
          db.puzzles.rating.isBetweenValues(minRating, maxRating));
  }

  Future<TacticsPuzzle> _assemble(Puzzle row) async {
    final themeRows = await (db.select(db.puzzleThemes)
          ..where((t) => t.puzzleId.equals(row.id)))
        .get();
    return TacticsPuzzle(
      id: row.id,
      fen: row.fen,
      solution:
          row.movesUci.split(' ').where((s) => s.isNotEmpty).toList(),
      rating: row.rating,
      themes: themeRows.map((t) => t.theme).toList()..sort(),
    );
  }
}
