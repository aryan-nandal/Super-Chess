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

// A second puzzle with a different motif (a legal line; quality irrelevant
// here — we only exercise motif filtering).
const _fork = TacticsPuzzle(
  id: 'f1',
  fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  solution: ['e2e4', 'e7e5'],
  rating: 1200,
  themes: ['fork'],
);

// A two-move (four-ply) line: setup e7e5, player e2e4 (correct, opponent
// auto-replies d7d5), then the player solves with e4xd5.
const _multi = TacticsPuzzle(
  id: 'mm1',
  fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
  solution: ['e7e5', 'e2e4', 'd7d5', 'e4d5'],
  rating: 1100,
  themes: ['pin'],
);

ProviderContainer _container(List<TacticsPuzzle> puzzles) {
  final c = ProviderContainer(
    overrides: [
      puzzleRepositoryProvider.overrideWithValue(
        InMemoryPuzzleRepository(puzzles),
      ),
    ],
  );
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
    expect(
      s.position!.pieceAt(Square.parse('a6')),
      const Piece(PieceColor.black, PieceRole.pawn),
    ); // setup applied
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

  test('intermediate-move feedback survives selecting/deselecting a piece',
      () async {
    final c = _container([_multi]);
    await _loaded(c);
    final ctrl = c.read(tacticsControllerProvider.notifier);

    // Play the correct first move; the opponent auto-replies, leaving the
    // "keep going" feedback while the puzzle is still being solved.
    ctrl.onSquareTap(Square.parse('e2'));
    ctrl.onSquareTap(Square.parse('e4'));
    expect(c.read(tacticsControllerProvider).status, TacticsStatus.solving);
    expect(
        c.read(tacticsControllerProvider).feedback, 'Correct — keep going');

    // Selecting a piece must not wipe the intermediate feedback.
    ctrl.onSquareTap(Square.parse('e4'));
    var s = c.read(tacticsControllerProvider);
    expect(s.selected, Square.parse('e4'));
    expect(s.feedback, 'Correct — keep going');

    // Nor must deselecting it.
    ctrl.onSquareTap(Square.parse('e4'));
    s = c.read(tacticsControllerProvider);
    expect(s.selected, isNull);
    expect(s.feedback, 'Correct — keep going');
  });

  test('an empty library yields the empty status', () async {
    final c = _container([]);
    final s = await _loaded(c);
    expect(s.status, TacticsStatus.empty);
  });

  test('exposes the available motifs, sorted', () async {
    final c = _container([_mate, _fork]);
    final s = await _loaded(c);
    expect(s.motifs, ['fork', 'mateIn1']);
  });

  test('setMotif filters puzzles to the chosen motif', () async {
    final c = _container([_mate, _fork]);
    await _loaded(c);
    c.read(tacticsControllerProvider.notifier).setMotif('fork');
    final s = await _loaded(c);
    expect(s.selectedMotif, 'fork');
    expect(s.puzzle!.id, 'f1');
    expect(s.puzzle!.themes, contains('fork'));
  });

  test('setMotif(null) returns to practicing all motifs', () async {
    final c = _container([_mate, _fork]);
    await _loaded(c);
    final ctrl = c.read(tacticsControllerProvider.notifier);
    ctrl.setMotif('fork');
    await _loaded(c);
    ctrl.setMotif(null);
    final s = await _loaded(c);
    expect(s.selectedMotif, isNull);
  });
}
