import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';

void main() {
  group('SAN (standard algebraic notation)', () {
    test('quiet moves from the starting position', () {
      final p = Position.initial;
      expect(sanOf(p, Move.uci('g1f3')), 'Nf3');
      expect(sanOf(p, Move.uci('e2e4')), 'e4');
      expect(sanOf(p, Move.uci('b1c3')), 'Nc3');
    });

    test('pawn capture uses the origin file', () {
      final p = Position.fromFen(
          'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2');
      expect(sanOf(p, Move.uci('e4d5')), 'exd5');
    });

    test('castling', () {
      final p = Position.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(sanOf(p, Move.uci('e1g1')), 'O-O');
      expect(sanOf(p, Move.uci('e1c1')), 'O-O-O');
    });

    test('disambiguation by file when two pieces can reach the square', () {
      final p = Position.fromFen('4k3/8/8/8/8/2N5/8/4K1N1 w - - 0 1');
      expect(sanOf(p, Move.uci('c3e2')), 'Nce2');
      expect(sanOf(p, Move.uci('g1e2')), 'Nge2');
    });

    test('check and checkmate suffixes', () {
      final check = Position.fromFen('k7/8/8/8/8/8/8/K6R w - - 0 1');
      expect(sanOf(check, Move.uci('h1h8')), 'Rh8+');

      final mate = Position.fromFen('6k1/5ppp/8/8/8/8/8/R6K w - - 0 1');
      expect(sanOf(mate, Move.uci('a1a8')), 'Ra8#');
    });

    test('promotion', () {
      final p = Position.fromFen('8/4P3/8/8/8/8/8/K5k1 w - - 0 1');
      expect(sanOf(p, Move.uci('e7e8q')), 'e8=Q');
      expect(sanOf(p, Move.uci('e7e8n')), 'e8=N');
    });
  });

  group('draw detection (single position)', () {
    test('insufficient material', () {
      expect(hasInsufficientMaterial(Position.fromFen('k7/8/8/8/8/8/8/K7 w - - 0 1')),
          isTrue); // K vs K
      expect(
          hasInsufficientMaterial(Position.fromFen('k7/8/8/8/8/8/8/KB6 w - - 0 1')),
          isTrue); // K+B vs K
      expect(
          hasInsufficientMaterial(Position.fromFen('k7/8/8/8/8/8/8/KN6 w - - 0 1')),
          isTrue); // K+N vs K
      expect(
          hasInsufficientMaterial(
              Position.fromFen('k1b5/8/8/8/8/8/8/KB6 w - - 0 1')),
          isTrue); // same-colored bishops
    });

    test('sufficient material', () {
      expect(
          hasInsufficientMaterial(Position.fromFen('k7/8/8/8/8/8/8/KQ6 w - - 0 1')),
          isFalse); // queen
      expect(
          hasInsufficientMaterial(Position.fromFen('k7/7p/8/8/8/8/8/K7 w - - 0 1')),
          isFalse); // a pawn can promote
      expect(
          hasInsufficientMaterial(
              Position.fromFen('kn6/8/8/8/8/8/8/KN6 w - - 0 1')),
          isFalse); // K+N vs K+N is not an automatic draw
    });

    test('fifty-move rule triggers at 100 halfmoves', () {
      expect(isFiftyMoveRule(Position.fromFen('k7/8/8/8/8/8/8/K7 w - - 99 80')),
          isFalse);
      expect(isFiftyMoveRule(Position.fromFen('k7/8/8/8/8/8/8/K7 w - - 100 80')),
          isTrue);
    });
  });

  group('UCI engine interface', () {
    test('a backend can satisfy the transport-agnostic contract', () async {
      final engine = _FixedEngine(Move.uci('e2e4'));
      await engine.start();
      final line = await engine.analyse(Position.initial);
      expect(line.bestMove, Move.uci('e2e4'));
      await engine.stop();
    });
  });
}

/// A trivial in-memory [UciEngine] used only to prove the interface contract
/// compiles and is implementable (real FFI/WASM/remote backends land later).
class _FixedEngine implements UciEngine {
  final Move _move;
  _FixedEngine(this._move);

  @override
  Future<void> start() async {}

  @override
  Future<EngineLine> analyse(Position position,
          {Duration? moveTime, int? depth, int? limitElo}) async =>
      EngineLine(bestMove: _move);

  @override
  Future<void> stop() async {}
}
