import '../../engine/engine.dart';
import 'tactics_puzzle.dart';

/// The result of the player playing a move in a [TacticsAttempt].
enum MoveOutcome {
  /// Correct, and the puzzle continues (the opponent reply was auto-played).
  correct,

  /// Correct and the final move — the puzzle is solved.
  solved,

  /// Wrong move — the attempt has failed.
  incorrect,
}

/// Drives the solving of a single [TacticsPuzzle]: applies the opponent's setup
/// move, validates each player move against the solution line (accepting any
/// alternative move that delivers checkmate, as the source dataset does),
/// auto-plays the opponent's replies, and tracks solved/failed state.
///
/// Pure domain — built on the engine, no Flutter.
class TacticsAttempt {
  final TacticsPuzzle puzzle;

  Position _position;
  int _index = 0; // index of the next expected solution move
  bool _failed = false;
  Move? _lastMove;

  TacticsAttempt(this.puzzle) : _position = Position.fromFen(puzzle.fen) {
    _apply(Move.uci(puzzle.solution[0])); // opponent's setup move
    _index = 1;
  }

  /// The current position (player to move, unless solved/failed).
  Position get position => _position;

  /// The most recently played move (setup, player, or opponent reply).
  Move? get lastMove => _lastMove;

  bool get isSolved => _index >= puzzle.solution.length && !_failed;
  bool get isFailed => _failed;

  /// Plays the player's [move]. Returns whether it was correct/solved/incorrect.
  /// Once the puzzle is solved or failed, further moves are ignored.
  MoveOutcome playUserMove(Move move) {
    if (isSolved) return MoveOutcome.solved;
    if (_failed) return MoveOutcome.incorrect;

    final expected = Move.uci(puzzle.solution[_index]);
    if (move != expected && !_isCheckmatingMove(move)) {
      _failed = true;
      return MoveOutcome.incorrect;
    }

    _apply(move);
    _index++;
    if (_index >= puzzle.solution.length) return MoveOutcome.solved;

    // Auto-play the opponent's scripted reply.
    _apply(Move.uci(puzzle.solution[_index]));
    _index++;
    return _index >= puzzle.solution.length
        ? MoveOutcome.solved
        : MoveOutcome.correct;
  }

  void _apply(Move move) {
    _position = _position.applyMove(move);
    _lastMove = move;
  }

  bool _isCheckmatingMove(Move move) =>
      generateLegalMoves(_position).contains(move) &&
      isCheckmate(_position.applyMove(move));
}
