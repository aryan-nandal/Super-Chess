import 'tactics_puzzle.dart';

/// Read-only access to the bundled tactics-puzzle library (the curated CC0
/// Lichess subset). Pure domain interface, so the trainer/UI never depend on
/// the storage engine. Implemented by `InMemoryPuzzleRepository` (the
/// cross-platform default, loaded from the bundled JSON) and by the data
/// layer's Drift repository (the persisted, scalable alternative).
abstract class PuzzleRepository {
  /// The puzzle with [id], or `null` if absent.
  Future<TacticsPuzzle?> byId(String id);

  /// Puzzles tagged with [theme] whose rating is within
  /// `[minRating, maxRating]`, ordered by rating, capped at [limit].
  Future<List<TacticsPuzzle>> byTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
    int limit = 50,
  });

  /// A single random puzzle tagged with [theme] within the rating band, or
  /// `null` if none match.
  Future<TacticsPuzzle?> randomByTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
  });

  /// The distinct motif themes available in the library, sorted.
  Future<List<String>> themes();
}
