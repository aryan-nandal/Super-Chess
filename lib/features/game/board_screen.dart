import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game.dart';
import '../../engine/engine.dart';
import '../tactics/tactics_screen.dart';
import 'game_controller.dart';
import 'widgets/chess_board.dart';

/// The local-play board screen: wires [gameControllerProvider] to the
/// presentational [ChessBoardView] and offers undo / reset / flip.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  PieceColor _orientation = PieceColor.white;

  void _flip() => setState(
    () => _orientation = _orientation == PieceColor.white
        ? PieceColor.black
        : PieceColor.white,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Chess'),
        actions: [
          IconButton(
            key: const ValueKey('open_tactics'),
            icon: const Icon(Icons.extension),
            tooltip: 'Tactics',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TacticsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _statusLabel(state),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: ChessBoardView(
                    position: state.position,
                    orientation: _orientation,
                    selected: state.selected,
                    targets: state.targets,
                    lastMove: state.lastMove,
                    checkSquare: state.checkSquare,
                    onSquareTap: controller.selectOrMove,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    key: const ValueKey('undo_button'),
                    onPressed: state.game.ply > 0 ? controller.undo : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('flip_button'),
                    onPressed: _flip,
                    icon: const Icon(Icons.flip),
                    label: const Text('Flip'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('reset_button'),
                    onPressed: controller.reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(GameUiState state) {
    final outcome = state.outcome;
    if (outcome.isOver) {
      switch (outcome.termination) {
        case GameTermination.checkmate:
          final winner = outcome.winner == PieceColor.white ? 'White' : 'Black';
          return 'Checkmate — $winner wins';
        case GameTermination.stalemate:
          return 'Draw — stalemate';
        case GameTermination.fiftyMoveRule:
          return 'Draw — fifty-move rule';
        case GameTermination.threefoldRepetition:
          return 'Draw — threefold repetition';
        case GameTermination.insufficientMaterial:
          return 'Draw — insufficient material';
        case GameTermination.ongoing:
          break;
      }
    }
    final mover = state.position.turn == PieceColor.white ? 'White' : 'Black';
    return state.isInCheck ? '$mover to move — Check!' : '$mover to move';
  }
}
