import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/engine/engine.dart';
import 'package:super_chess/features/tactics/tactics_controller.dart';

// Engine-verified mate-in-1: setup a7a6, then white mates with Re8.
const _mate = TacticsPuzzle(
  id: 'm1',
  fen: '6k1/p4ppp/8/8/8/8/4R3/6K1 b - - 0 1',
  solution: ['a7a6', 'e2e8'],
  rating: 900,
  themes: ['mateIn1'],
);

ProviderContainer _container(List<TacticsPuzzle> puzzles) {
  final c = ProviderContainer(overrides: [
    puzzleRepositoryProvider
        .overrideWithValue(InMemoryPuzzleRepository(puzzles)),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<TacticsUiState> _loaded(ProviderContainer c) async {
  for (var i = 0; i < 50; i++) {
    final s = c.read(tacticsControllerProvider);
    if (s.status != TacticsStatus.loading) return s;
    await Future<void>.delayed(Duration.zero);
  }
  return c.read(tacticsControllerProvider);
}

void main() {
  test('loads a puzzle and applies the setup move (player to move)', () async {
    final c = _container([_mate]);
    final s = await _loaded(c);
    expect(s.status, TacticsStatus.solving);
    expect(s.puzzle!.id, 'm1');
    expect(s.position!.pieceAt(Square.parse('a6')),
        const Piece(PieceColor.black, PieceRole.pawn)); // setup applied
    expect(s.playerColor, PieceColor.white);
  });

  test('selecting a piece exposes its legal targets', () async {
    final c = _container([_mate]);
    await _loaded(c);
    c.read(tacticsControllerProvider.notifier).onSquareTap(Square.parse('e2'));
    final s = c.read(tacticsControllerProvider);
    expect(s.selected, Square.parse('e2'));
    expect(s.targets, contains(Square.parse('e8')));
  });

  test('the solution move solves the puzzle', () async {
    final c = _container([_mate]);
    await _loaded(c);
    final ctrl = c.read(tacticsControllerProvider.notifier);
    ctrl.onSquareTap(Square.parse('e2'));
    ctrl.onSquareTap(Square.parse('e8'));
    final s = c.read(tacticsControllerProvider);
    expect(s.status, TacticsStatus.solved);
    expect(s.isSolved, isTrue);
  });

  test('a wrong move fails the attempt; retry restarts it', () async {
    final c = _container([_mate]);
    await _loaded(c);
    final ctrl = c.read(tacticsControllerProvider.notifier);
    ctrl.onSquareTap(Square.parse('e2'));
    ctrl.onSquareTap(Square.parse('e7')); // legal rook move, but not the answer
    expect(c.read(tacticsControllerProvider).status, TacticsStatus.failed);

    ctrl.retry();
    final s = c.read(tacticsControllerProvider);
    expect(s.status, TacticsStatus.solving);
    expect(s.selected, isNull);
  });

  test('an empty library yields the empty status', () async {
    final c = _container([]);
    final s = await _loaded(c);
    expect(s.status, TacticsStatus.empty);
  });
}
