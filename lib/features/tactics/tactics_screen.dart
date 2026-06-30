import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../game/widgets/chess_board.dart';
import 'tactics_controller.dart';

const _motifNames = {
  'mateIn1': 'Mate in 1',
  'mateIn2': 'Mate in 2',
  'backRankMate': 'Back-rank mate',
  'queenMate': 'Queen mate',
  'fork': 'Fork',
  'pin': 'Pin',
  'skewer': 'Skewer',
  'discoveredAttack': 'Discovered attack',
  'hangingPiece': 'Win material',
};

/// Friendly motif name from a puzzle's themes (first recognized one).
String motifLabel(List<String> themes) {
  for (final t in themes) {
    final name = _motifNames[t];
    if (name != null) return name;
  }
  return themes.isNotEmpty ? themes.first : 'Tactics';
}

/// The named-motif tactics trainer: present a puzzle, validate the solution
/// line, and teach the motif. Reuses [ChessBoardView] and [TacticsController].
class TacticsScreen extends ConsumerWidget {
  const TacticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tacticsControllerProvider);
    final controller = ref.read(tacticsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tactics')),
      body: SafeArea(
        child: Column(
          children: [
            if (state.motifs.isNotEmpty) _motifPicker(state, controller),
            Expanded(child: _body(context, state, controller)),
          ],
        ),
      ),
    );
  }

  /// A horizontal row of motif chips ("All" + each motif) for choosing what to
  /// practice. Stays visible across loading/solving/solved so it's always
  /// reachable.
  Widget _motifPicker(TacticsUiState state, TacticsController controller) {
    Widget chip(String? motif, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            key: ValueKey('motif_${motif ?? 'all'}'),
            label: Text(label),
            selected: state.selectedMotif == motif,
            onSelected: (_) => controller.setMotif(motif),
          ),
        );

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          chip(null, 'All'),
          for (final motif in state.motifs) chip(motif, motifLabel([motif])),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    TacticsUiState state,
    TacticsController controller,
  ) {
    switch (state.status) {
      case TacticsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TacticsStatus.empty:
        return const Center(child: Text('No puzzles available yet.'));
      case TacticsStatus.solving:
      case TacticsStatus.solved:
      case TacticsStatus.failed:
        return _puzzle(context, state, controller);
    }
  }

  Widget _puzzle(
    BuildContext context,
    TacticsUiState state,
    TacticsController controller,
  ) {
    final position = state.position!;
    final theme = Theme.of(context);
    final inCheck = isCheck(position);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                motifLabel(state.puzzle!.themes),
                key: const ValueKey('tactics_motif'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _statusLine(state),
                key: const ValueKey('tactics_status'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: switch (state.status) {
                    TacticsStatus.solved => Colors.green,
                    TacticsStatus.failed => theme.colorScheme.error,
                    _ => null,
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: ChessBoardView(
                position: position,
                orientation: state.playerColor ?? PieceColor.white,
                selected: state.selected,
                targets: state.targets,
                lastMove: state.lastMove,
                checkSquare: inCheck
                    ? kingSquareOf(position, position.turn)
                    : null,
                onSquareTap: controller.onSquareTap,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (state.isFailed)
                FilledButton.tonalIcon(
                  key: const ValueKey('retry_button'),
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              FilledButton.icon(
                key: const ValueKey('next_button'),
                onPressed: controller.nextPuzzle,
                icon: const Icon(Icons.arrow_forward),
                label: Text(state.isSolved ? 'Next puzzle' : 'Skip'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLine(TacticsUiState state) {
    switch (state.status) {
      case TacticsStatus.solved:
        return '✓ Solved!';
      case TacticsStatus.failed:
        return '✗ ${state.feedback ?? 'Try again'}';
      case TacticsStatus.solving:
        final side = state.playerColor == PieceColor.white ? 'White' : 'Black';
        return state.feedback ?? '$side to play — find the best move';
      case TacticsStatus.loading:
      case TacticsStatus.empty:
        return '';
    }
  }
}
