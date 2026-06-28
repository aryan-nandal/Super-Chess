import 'package:drift/drift.dart';

part 'content_database.g.dart';

/// One tactics puzzle. [movesUci] is the space-separated UCI solution line
/// (index 0 is the opponent's setup move), matching the Lichess dataset.
class Puzzles extends Table {
  TextColumn get id => text()();
  TextColumn get fen => text()();
  TextColumn get movesUci => text()();
  IntColumn get rating => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Motif tags for a puzzle (a puzzle has many), normalized for `(theme,
/// rating)` lookups like "a fork around 1500".
@TableIndex(name: 'idx_puzzle_themes_theme', columns: {#theme})
class PuzzleThemes extends Table {
  TextColumn get puzzleId =>
      text().references(Puzzles, #id, onDelete: KeyAction.cascade)();
  TextColumn get theme => text()();

  @override
  Set<Column> get primaryKey => {puzzleId, theme};
}

/// The **read-only content database**: the bundled puzzle library (and, later,
/// openings + endgame drills). Kept separate from the writable progress DB so
/// content updates never clobber a player's history.
@DriftDatabase(tables: [Puzzles, PuzzleThemes])
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
