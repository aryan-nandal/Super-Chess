/// Bundled puzzle asset paths.
///
/// Kept in its own Drift-free file so the app's startup path (`main.dart`) can
/// reference them without importing the Drift/sqlite3 stack — the app loads
/// puzzles into an in-memory repository and never opens the Drift content DB at
/// runtime.
abstract final class PuzzleAssets {
  /// The curated CC0 Lichess library (`tool/curate_puzzles.dart` output).
  static const library = 'assets/puzzles/puzzles.json';

  /// Tiny hand-authored set for dev/tests and as a fallback.
  static const sample = 'assets/puzzles/sample_puzzles.json';
}
