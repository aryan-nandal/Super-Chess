/// A single tactics puzzle, in the Lichess open-database shape.
///
/// [solution] is a list of UCI moves where the **first** move is the opponent's
/// move that sets up the puzzle (applied automatically); the player then plays
/// the moves at the odd indices, with the opponent's replies at the even
/// indices played for them. Pure data — no Flutter, no engine state.
class TacticsPuzzle {
  final String id;

  /// The position *before* the opponent's setup move ([solution] index 0).
  final String fen;

  /// UCI moves: index 0 is the opponent setup; the player solves the rest.
  final List<String> solution;

  /// The puzzle's difficulty rating (Glicko, from the source dataset).
  final int rating;

  /// Motif tags (e.g. `fork`, `pin`, `backRankMate`) used by the trainer.
  final List<String> themes;

  const TacticsPuzzle({
    required this.id,
    required this.fen,
    required this.solution,
    this.rating = 0,
    this.themes = const [],
  });
}
