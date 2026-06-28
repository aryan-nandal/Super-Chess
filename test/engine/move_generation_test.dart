import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';

/// Counts the number of legal move sequences of the given [depth] — the
/// standard "perft" correctness benchmark for a move generator.
int perft(Position pos, int depth) {
  if (depth == 0) return 1;
  final moves = generateLegalMoves(pos);
  if (depth == 1) return moves.length;
  var nodes = 0;
  for (final m in moves) {
    nodes += perft(pos.applyMove(m), depth - 1);
  }
  return nodes;
}

void main() {
  // Reference node counts from the Chess Programming Wiki perft results.
  group('perft', () {
    test('starting position', () {
      final p = Position.initial;
      expect(perft(p, 1), 20);
      expect(perft(p, 2), 400);
      expect(perft(p, 3), 8902);
      expect(perft(p, 4), 197281);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Kiwipete (castling, checks, en passant)', () {
      final p = Position.fromFen(
          'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1');
      expect(perft(p, 1), 48);
      expect(perft(p, 2), 2039);
      expect(perft(p, 3), 97862);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('position 3 (en passant, promotion edge cases)', () {
      final p = Position.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1');
      expect(perft(p, 1), 14);
      expect(perft(p, 2), 191);
      expect(perft(p, 3), 2812);
      expect(perft(p, 4), 43238);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('position 4 (pins, promotions)', () {
      final p = Position.fromFen(
          'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1');
      expect(perft(p, 1), 6);
      expect(perft(p, 2), 264);
      expect(perft(p, 3), 9467);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('position 5 (promotions, tight)', () {
      final p = Position.fromFen(
          'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8');
      expect(perft(p, 1), 44);
      expect(perft(p, 2), 1486);
      expect(perft(p, 3), 62379);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('move generation specifics', () {
    test('20 legal moves from the start', () {
      expect(generateLegalMoves(Position.initial).length, 20);
    });

    test('an absolutely pinned piece cannot move off the pin', () {
      // White Ke1, white Be2 pinned along the e-file by black Re8.
      final p = Position.fromFen('4r3/8/8/8/8/8/4B3/4K3 w - - 0 1');
      final moves = generateLegalMoves(p);
      expect(moves.where((m) => m.from == Square.parse('e2')), isEmpty);
      expect(moves, isNotEmpty); // the king can still move
    });

    test('castling through an attacked square is illegal', () {
      // Black Rf8 attacks the f-file; white may not O-O (passes f1) but may O-O-O.
      final p = Position.fromFen('5rk1/8/8/8/8/8/8/R3K2R w KQ - 0 1');
      final uci = generateLegalMoves(p).map((m) => m.uci).toSet();
      expect(uci.contains('e1g1'), isFalse);
      expect(uci.contains('e1c1'), isTrue);
    });

    test('en passant capture removes the passed pawn', () {
      final p = Position.fromFen(
          'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3');
      final after = p.applyMove(Move.uci('e5f6'));
      expect(after.pieceAt(Square.parse('f6')),
          const Piece(PieceColor.white, PieceRole.pawn));
      expect(after.pieceAt(Square.parse('f5')), isNull);
    });

    test('castling moves the rook too', () {
      final p = Position.fromFen('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1');
      final after = p.applyMove(Move.uci('e1g1'));
      expect(after.pieceAt(Square.parse('g1')),
          const Piece(PieceColor.white, PieceRole.king));
      expect(after.pieceAt(Square.parse('f1')),
          const Piece(PieceColor.white, PieceRole.rook));
      expect(after.pieceAt(Square.parse('h1')), isNull);
      expect(after.castling.whiteKingSide, isFalse);
      expect(after.castling.whiteQueenSide, isFalse);
    });

    test('checkmate: no legal moves and in check (fool\'s mate)', () {
      final p = Position.fromFen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3');
      expect(generateLegalMoves(p), isEmpty);
      expect(isCheck(p), isTrue);
      expect(isCheckmate(p), isTrue);
      expect(isStalemate(p), isFalse);
    });

    test('stalemate: no legal moves and not in check', () {
      final p = Position.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(generateLegalMoves(p), isEmpty);
      expect(isCheck(p), isFalse);
      expect(isStalemate(p), isTrue);
      expect(isCheckmate(p), isFalse);
    });
  });
}
