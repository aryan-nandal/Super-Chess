import 'move.dart';
import 'position.dart';

/// A single engine evaluation line: the recommended move plus an optional
/// score, expressed either in centipawns or as a forced mate in N plies.
class EngineLine {
  final Move bestMove;

  /// Evaluation in centipawns from the side-to-move's perspective, or `null`
  /// when the engine reports a mate score instead.
  final int? scoreCentipawns;

  /// Plies to forced mate (positive = side-to-move mates), or `null`.
  final int? mateInPlies;

  const EngineLine({
    required this.bestMove,
    this.scoreCentipawns,
    this.mateInPlies,
  });
}

/// Transport-agnostic interface to a UCI-speaking chess engine.
///
/// The domain depends only on this contract; concrete backends — native FFI on
/// mobile, a WASM Web Worker on web, or a remote server — are implemented in the
/// data layer. This boundary is what keeps the (GPL) Stockfish-vs-permissive-vs-
/// server-side decision swappable without touching domain or UI (see
/// docs/PLAN.md §3).
abstract class UciEngine {
  /// Boots the backend (spawns the process/worker, handshakes `uci`/`isready`).
  Future<void> start();

  /// Analyses [position] and returns the best line found, bounded by an
  /// optional [moveTime] or fixed search [depth]. [limitElo] requests
  /// human-strength play where the backend supports `UCI_LimitStrength`.
  Future<EngineLine> analyse(
    Position position, {
    Duration? moveTime,
    int? depth,
    int? limitElo,
  });

  /// Stops any search in progress and releases the backend.
  Future<void> stop();
}
