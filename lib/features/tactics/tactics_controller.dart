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

  /// The motifs available to practice (for the picker), sorted.
  final List<String> motifs;

  /// The motif currently being practiced, or `null` for "all motifs".
  final String? selectedMotif;

  const TacticsUiState({
    required this.status,
    this.attempt,
    this.selected,
    this.targets = const [],
    this.feedback,
    this.motifs = const [],
    this.selectedMotif,
  });

  TacticsPuzzle? get puzzle => attempt?.puzzle;
  Position? get position => attempt?.position;
  Move? get lastMove => attempt?.lastMove;

  /// The side the player moves for (the side to move once the puzzle is set up).
  PieceColor? get playerColor => attempt?.position.turn;

  bool get isSolved => status == TacticsStatus.solved;
  bool get isFailed => status == TacticsStatus.failed;
}

/// Drives one tactics session: loads a puzzle (optionally filtered to a chosen
/// motif), validates player moves against the solution via [TacticsAttempt],
/// and exposes board-selection + motif-picker state.
class TacticsController extends Notifier<TacticsUiState> {
  final Random _random;
  late PuzzleRepository _repository;
  List<String> _motifs = const [];
  String? _selectedMotif;

  /// Identifies the most recently started load. A load only applies its result
  /// if it is still the current generation, so a slow earlier load (e.g. from a
  /// variable-latency repository) can't clobber a newer selection.
  int _loadGeneration = 0;

  TacticsController({Random? random}) : _random = random ?? Random();

  @override
  TacticsUiState build() {
    _repository = ref.watch(puzzleRepositoryProvider);
    _init();
    return const TacticsUiState(status: TacticsStatus.loading);
  }

  Future<void> _init() async {
    _motifs = await _repository.themes();
    await _loadNext();
  }

  Future<void> _loadNext() async {
    final generation = ++_loadGeneration;
    if (_motifs.isEmpty) {
      _set(status: TacticsStatus.empty);
      return;
    }
    final theme = _selectedMotif ?? _motifs[_random.nextInt(_motifs.length)];
    final puzzle = await _repository.randomByTheme(theme);
    if (generation != _loadGeneration) return;
    _set(
      status: puzzle == null ? TacticsStatus.empty : TacticsStatus.solving,
      attempt: puzzle == null ? null : TacticsAttempt(puzzle),
    );
  }

  /// Practices only [motif] (or all motifs when `null`) and loads a fresh one.
  void setMotif(String? motif) {
    if (motif == _selectedMotif) return;
    _selectedMotif = motif;
    _set(status: TacticsStatus.loading);
    _loadNext();
  }

  /// Loads a fresh puzzle (within the selected motif, if any).
  void nextPuzzle() {
    _set(status: TacticsStatus.loading);
    _loadNext();
  }

  /// Restarts the current puzzle from the beginning.
  void retry() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    _set(status: TacticsStatus.solving, attempt: TacticsAttempt(puzzle));
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
      _set(
        status: TacticsStatus.solving,
        attempt: current.attempt,
        feedback: current.feedback,
      );
    } else if (current.targets.contains(square)) {
      _play(selected, square);
    } else {
      _trySelect(square);
    }
  }

  void _trySelect(Square square) {
    final attempt = state.attempt!;
    final position = attempt.position;
    final piece = position.pieceAt(square);
    if (piece != null && piece.color == position.turn) {
      final targets = <Square>{
        for (final m in generateLegalMoves(position))
          if (m.from == square) m.to,
      }.toList();
      _set(
        status: TacticsStatus.solving,
        attempt: attempt,
        selected: square,
        targets: targets,
        feedback: state.feedback,
      );
    } else {
      _set(
        status: TacticsStatus.solving,
        attempt: attempt,
        feedback: state.feedback,
      );
    }
  }

  void _play(Square from, Square to) {
    final attempt = state.attempt!;
    final candidates = generateLegalMoves(
      attempt.position,
    ).where((m) => m.from == from && m.to == to).toList();
    if (candidates.isEmpty) {
      _set(status: TacticsStatus.solving, attempt: attempt);
      return;
    }
    // Promotion auto-selects a queen (no promotion picker yet), so any puzzle
    // whose solution needs a non-mating underpromotion will auto-fail until a
    // picker is added — a deliberate deferral; fine for the curated set.
    final move = candidates.firstWhere(
      (m) => m.promotion == null || m.promotion == PieceRole.queen,
      orElse: () => candidates.first,
    );
    switch (attempt.playUserMove(move)) {
      case MoveOutcome.solved:
        _set(
          status: TacticsStatus.solved,
          attempt: attempt,
          feedback: 'Solved!',
        );
      case MoveOutcome.correct:
        _set(
          status: TacticsStatus.solving,
          attempt: attempt,
          feedback: 'Correct — keep going',
        );
      case MoveOutcome.incorrect:
        _set(
          status: TacticsStatus.failed,
          attempt: attempt,
          feedback: 'Not the move — try again',
        );
    }
  }

  /// Emits a fresh state, always carrying the current motif-picker context.
  void _set({
    required TacticsStatus status,
    TacticsAttempt? attempt,
    Square? selected,
    List<Square> targets = const [],
    String? feedback,
  }) {
    state = TacticsUiState(
      status: status,
      attempt: attempt,
      selected: selected,
      targets: targets,
      feedback: feedback,
      motifs: _motifs,
      selectedMotif: _selectedMotif,
    );
  }
}

final tacticsControllerProvider =
    NotifierProvider<TacticsController, TacticsUiState>(TacticsController.new);
