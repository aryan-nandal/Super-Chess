import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game.dart';
import '../../engine/engine.dart';

/// A view snapshot for the board feature wrapping the mutable [game]. The
/// snapshot itself is not deep-immutable — [game] mutates in place on play/undo
/// — but a fresh [GameUiState] instance is emitted on every change so Riverpod
/// notifies its listeners.
class GameUiState {
  final Game game;

  /// The currently selected source square, or `null`.
  final Square? selected;

  /// Legal destination squares from [selected] (empty when nothing selected).
  final List<Square> targets;

  const GameUiState({
    required this.game,
    this.selected,
    this.targets = const [],
  });

  Position get position => game.position;

  /// The most recent move played, or `null` at the start.
  Move? get lastMove => game.moveHistory.isEmpty ? null : game.moveHistory.last;

  GameOutcome get outcome => game.outcome;

  bool get isInCheck => game.isInCheck;

  /// The square of the king that is in check, or `null` when not in check.
  Square? get checkSquare =>
      isInCheck ? kingSquareOf(position, position.turn) : null;
}

/// Drives a single game of chess from board taps. Presentational widgets emit
/// intents here; all rules live in the domain/engine layers.
class GameController extends Notifier<GameUiState> {
  @override
  GameUiState build() => GameUiState(game: Game.initial());

  /// Handles a tap on [square]: selects a piece, moves to a legal target,
  /// reselects another own piece, or clears the selection.
  void selectOrMove(Square square) {
    if (state.outcome.isOver) {
      _clearSelection(); // the game is finished — freeze the board
      return;
    }
    final selected = state.selected;
    if (selected == null) {
      _trySelect(square);
      return;
    }
    if (square == selected) {
      _clearSelection(); // tap the selected square again to deselect
      return;
    }
    if (state.targets.contains(square)) {
      _play(selected, square);
      return;
    }
    _trySelect(square); // a different square — try to (re)select it
  }

  /// Replaces the game with one loaded from [fen] (used for puzzles/tests).
  void loadFen(String fen) {
    state = GameUiState(game: Game.fromFen(fen));
  }

  /// Takes back the last move.
  void undo() {
    state.game.undo();
    state = GameUiState(game: state.game);
  }

  /// Restarts from the initial position.
  void reset() {
    state = GameUiState(game: Game.initial());
  }

  void _trySelect(Square square) {
    final game = state.game;
    final piece = game.position.pieceAt(square);
    if (piece != null && piece.color == game.position.turn) {
      final targets = <Square>{
        for (final m in game.legalMoves)
          if (m.from == square) m.to,
      }.toList();
      state = GameUiState(game: game, selected: square, targets: targets);
    } else {
      _clearSelection();
    }
  }

  void _clearSelection() {
    state = GameUiState(game: state.game);
  }

  void _play(Square from, Square to) {
    final game = state.game;
    final candidates = game.legalMoves
        .where((m) => m.from == from && m.to == to)
        .toList();
    if (candidates.isEmpty) {
      _clearSelection();
      return;
    }
    // Promotion currently defaults to a queen; an explicit picker comes later.
    final move = candidates.firstWhere(
      (m) => m.promotion == null || m.promotion == PieceRole.queen,
      orElse: () => candidates.first,
    );
    game.play(move);
    state = GameUiState(game: game);
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameUiState>(
  GameController.new,
);
