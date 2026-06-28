import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tactics/tactics.dart';
import '../../engine/engine.dart';

/// Source of puzzles. Overridden in `main()` (an in-memory repository loaded
/// from the bundled asset) and in tests.
final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  throw UnimplementedError('puzzleRepositoryProvider must be overridden');
});

enum TacticsStatus { loading, solving, solved, failed, empty }

/// View-state for the tactics trainer. The mutable [attempt] lives inside; a
/// fresh state is emitted on every change so Riverpod notifies.
class TacticsUiState {
  final TacticsStatus status;
  final TacticsAttempt? attempt;
  final Square? selected;
  final List<Square> targets;

  /// Short feedback after the last player move.
  final String? feedback;

  const TacticsUiState({
    required this.status,
    this.attempt,
    this.selected,
    this.targets = const [],
    this.feedback,
  });

  TacticsPuzzle? get puzzle => attempt?.puzzle;
  Position? get position => attempt?.position;
  Move? get lastMove => attempt?.lastMove;

  /// The side the player moves for (the side to move once the puzzle is set up).
  PieceColor? get playerColor => attempt?.position.turn;

  bool get isSolved => status == TacticsStatus.solved;
  bool get isFailed => status == TacticsStatus.failed;
}

/// Drives one tactics session: loads a puzzle, validates player moves against
/// the solution via [TacticsAttempt], and exposes board-selection state.
class TacticsController extends Notifier<TacticsUiState> {
  final Random _random;
  late PuzzleRepository _repository;

  TacticsController({Random? random}) : _random = random ?? Random();

  @override
  TacticsUiState build() {
    _repository = ref.watch(puzzleRepositoryProvider);
    _loadNext();
    return const TacticsUiState(status: TacticsStatus.loading);
  }

  Future<void> _loadNext() async {
    final themes = await _repository.themes();
    if (themes.isEmpty) {
      state = const TacticsUiState(status: TacticsStatus.empty);
      return;
    }
    final theme = themes[_random.nextInt(themes.length)];
    final puzzle = await _repository.randomByTheme(theme);
    state = puzzle == null
        ? const TacticsUiState(status: TacticsStatus.empty)
        : TacticsUiState(
            status: TacticsStatus.solving, attempt: TacticsAttempt(puzzle));
  }

  /// Loads a fresh puzzle.
  void nextPuzzle() {
    state = const TacticsUiState(status: TacticsStatus.loading);
    _loadNext();
  }

  /// Restarts the current puzzle from the beginning.
  void retry() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    state = TacticsUiState(
        status: TacticsStatus.solving, attempt: TacticsAttempt(puzzle));
  }

  /// Handles a tap: select a piece, move to a legal target, reselect, or clear.
  void onSquareTap(Square square) {
    final current = state;
    if (current.status != TacticsStatus.solving || current.attempt == null) {
      return;
    }
    final selected = current.selected;
    if (selected == null) {
      _trySelect(square);
    } else if (square == selected) {
      _solving(selected: null);
    } else if (current.targets.contains(square)) {
      _play(selected, square);
    } else {
      _trySelect(square);
    }
  }

  void _trySelect(Square square) {
    final position = state.attempt!.position;
    final piece = position.pieceAt(square);
    if (piece != null && piece.color == position.turn) {
      final targets = <Square>{
        for (final m in generateLegalMoves(position))
          if (m.from == square) m.to,
      }.toList();
      _solving(selected: square, targets: targets);
    } else {
      _solving(selected: null);
    }
  }

  void _play(Square from, Square to) {
    final attempt = state.attempt!;
    final candidates = generateLegalMoves(attempt.position)
        .where((m) => m.from == from && m.to == to)
        .toList();
    if (candidates.isEmpty) {
      _solving(selected: null);
      return;
    }
    final move = candidates.firstWhere(
      (m) => m.promotion == null || m.promotion == PieceRole.queen,
      orElse: () => candidates.first,
    );
    switch (attempt.playUserMove(move)) {
      case MoveOutcome.solved:
        state = TacticsUiState(
            status: TacticsStatus.solved, attempt: attempt, feedback: 'Solved!');
      case MoveOutcome.correct:
        state = TacticsUiState(
            status: TacticsStatus.solving,
            attempt: attempt,
            feedback: 'Correct — keep going');
      case MoveOutcome.incorrect:
        state = TacticsUiState(
            status: TacticsStatus.failed,
            attempt: attempt,
            feedback: 'Not the move — try again');
    }
  }

  void _solving({Square? selected, List<Square> targets = const []}) {
    state = TacticsUiState(
      status: TacticsStatus.solving,
      attempt: state.attempt,
      selected: selected,
      targets: targets,
      feedback: state.feedback,
    );
  }
}

final tacticsControllerProvider =
    NotifierProvider<TacticsController, TacticsUiState>(TacticsController.new);
