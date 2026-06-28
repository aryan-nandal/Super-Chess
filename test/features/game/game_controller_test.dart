import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/game.dart';
import 'package:super_chess/engine/engine.dart';
import 'package:super_chess/features/game/game_controller.dart';

void main() {
  late ProviderContainer container;
  GameController controller() =>
      container.read(gameControllerProvider.notifier);
  GameUiState state() => container.read(gameControllerProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts at the initial position with nothing selected', () {
    expect(state().position.toFen(), kStartingFen);
    expect(state().selected, isNull);
    expect(state().targets, isEmpty);
  });

  test('selecting a piece exposes its legal targets', () {
    controller().selectOrMove(Square.parse('e2'));
    expect(state().selected, Square.parse('e2'));
    expect(
      state().targets,
      containsAll([Square.parse('e3'), Square.parse('e4')]),
    );
  });

  test('tapping an empty non-target square clears the selection', () {
    controller().selectOrMove(Square.parse('e2'));
    controller().selectOrMove(Square.parse('h5')); // not a target
    expect(state().selected, isNull);
    expect(state().targets, isEmpty);
  });

  test('selecting then tapping a target plays the move', () {
    controller().selectOrMove(Square.parse('e2'));
    controller().selectOrMove(Square.parse('e4'));
    expect(state().game.sanHistory, ['e4']);
    expect(
      state().position.pieceAt(Square.parse('e4')),
      const Piece(PieceColor.white, PieceRole.pawn),
    );
    expect(state().selected, isNull);
    expect(state().lastMove, Move.uci('e2e4'));
  });

  test('tapping another own piece reselects it', () {
    controller().selectOrMove(Square.parse('e2'));
    controller().selectOrMove(Square.parse('d2'));
    expect(state().selected, Square.parse('d2'));
    expect(
      state().targets,
      containsAll([Square.parse('d3'), Square.parse('d4')]),
    );
  });

  test('cannot select the opponent\'s piece', () {
    controller().selectOrMove(Square.parse('e7')); // black, white to move
    expect(state().selected, isNull);
  });

  test('promotion defaults to a queen', () {
    // White pawn on a7 about to promote.
    controller().loadFen('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    controller().selectOrMove(Square.parse('a7'));
    controller().selectOrMove(Square.parse('a8'));
    expect(
      state().position.pieceAt(Square.parse('a8')),
      const Piece(PieceColor.white, PieceRole.queen),
    );
  });

  test('undo takes back the last move and clears selection', () {
    controller().selectOrMove(Square.parse('e2'));
    controller().selectOrMove(Square.parse('e4'));
    controller().undo();
    expect(state().position.toFen(), kStartingFen);
    expect(state().selected, isNull);
  });

  test('exposes check and the checked king square', () {
    // Black is in check from the white queen on e7 (scholar's-mate-style).
    controller().loadFen(
      'rnbqkbnr/ppppQppp/8/8/8/8/PPPP1PPP/RNB1KBNR b KQkq - 0 1',
    );
    expect(state().isInCheck, isTrue);
    expect(state().checkSquare, Square.parse('e8'));
  });

  test('reports a checkmate outcome with the winner', () {
    controller().loadFen(
      'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
    );
    final o = state().outcome;
    expect(o.termination, GameTermination.checkmate);
    expect(o.winner, PieceColor.black);
  });

  test('a terminal draw freezes the board against further moves', () {
    // Bare kings: a draw by insufficient material that still has legal moves.
    controller().loadFen('4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    expect(state().outcome.termination, GameTermination.insufficientMaterial);
    expect(state().outcome.isOver, isTrue);

    final fenBefore = state().position.toFen();
    controller().selectOrMove(Square.parse('e1')); // own king
    expect(state().selected, isNull);
    expect(state().targets, isEmpty);
    expect(state().position.toFen(), fenBefore);
  });
}
