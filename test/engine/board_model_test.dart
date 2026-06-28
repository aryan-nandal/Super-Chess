import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';

void main() {
  group('Square', () {
    test('a1 is index 0, h8 is index 63', () {
      expect(Square.parse('a1').index, 0);
      expect(Square.parse('h8').index, 63);
      expect(Square.parse('e4').index, Square.at(file: 4, rank: 3).index);
    });

    test('file, rank and name round-trip', () {
      for (final name in ['a1', 'h1', 'a8', 'h8', 'e4', 'd5', 'c6']) {
        final s = Square.parse(name);
        expect(s.name, name);
      }
      final e4 = Square.parse('e4');
      expect(e4.file, 4); // a=0 ... e=4
      expect(e4.rank, 3); // rank 4 -> 0-based 3
    });

    test('rejects malformed names', () {
      expect(() => Square.parse('z9'), throwsFormatException);
      expect(() => Square.parse('e'), throwsFormatException);
    });

    test('equality by index', () {
      expect(Square.parse('e4'), Square.at(file: 4, rank: 3));
      expect(Square.parse('e4').hashCode, Square.at(file: 4, rank: 3).hashCode);
    });
  });

  group('Piece', () {
    test('FEN chars: white uppercase, black lowercase', () {
      expect(const Piece(PieceColor.white, PieceRole.king).fenChar, 'K');
      expect(const Piece(PieceColor.black, PieceRole.queen).fenChar, 'q');
      expect(const Piece(PieceColor.white, PieceRole.knight).fenChar, 'N');
      expect(const Piece(PieceColor.black, PieceRole.pawn).fenChar, 'p');
    });

    test('parses from FEN char', () {
      expect(Piece.fromFenChar('R'),
          const Piece(PieceColor.white, PieceRole.rook));
      expect(Piece.fromFenChar('b'),
          const Piece(PieceColor.black, PieceRole.bishop));
      expect(Piece.fromFenChar('x'), isNull);
    });

    test('value equality', () {
      expect(const Piece(PieceColor.white, PieceRole.king),
          const Piece(PieceColor.white, PieceRole.king));
      expect(const Piece(PieceColor.white, PieceRole.king),
          isNot(const Piece(PieceColor.black, PieceRole.king)));
    });
  });

  group('Move', () {
    test('uci round-trip for a quiet move', () {
      final m = Move.uci('e2e4');
      expect(m.from, Square.parse('e2'));
      expect(m.to, Square.parse('e4'));
      expect(m.promotion, isNull);
      expect(m.uci, 'e2e4');
    });

    test('uci round-trip for a promotion', () {
      final m = Move.uci('e7e8q');
      expect(m.from, Square.parse('e7'));
      expect(m.to, Square.parse('e8'));
      expect(m.promotion, PieceRole.queen);
      expect(m.uci, 'e7e8q');
    });

    test('equality', () {
      expect(Move.uci('g1f3'), Move.uci('g1f3'));
      expect(Move.uci('e7e8q'), isNot(Move.uci('e7e8n')));
    });
  });

  group('FEN', () {
    test('parses the standard starting position', () {
      final p = Position.initial;
      expect(p.turn, PieceColor.white);
      expect(p.fullmoveNumber, 1);
      expect(p.halfmoveClock, 0);
      expect(p.enPassant, isNull);
      expect(p.castling.toFen(), 'KQkq');

      expect(p.pieceAt(Square.parse('e1')),
          const Piece(PieceColor.white, PieceRole.king));
      expect(p.pieceAt(Square.parse('d8')),
          const Piece(PieceColor.black, PieceRole.queen));
      expect(p.pieceAt(Square.parse('a2')),
          const Piece(PieceColor.white, PieceRole.pawn));
      expect(p.pieceAt(Square.parse('e4')), isNull);
    });

    test('starting position serializes back to the canonical FEN', () {
      expect(Position.initial.toFen(),
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    });

    test('round-trips a mid-game FEN (Kiwipete) exactly', () {
      const fen =
          'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
      expect(Position.fromFen(fen).toFen(), fen);
    });

    test('round-trips an en-passant FEN', () {
      const fen =
          'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3';
      final p = Position.fromFen(fen);
      expect(p.enPassant, Square.parse('f6'));
      expect(p.toFen(), fen);
    });

    test('handles missing castling rights and a move clock', () {
      const fen = '8/8/8/4k3/8/4K3/8/8 b - - 12 34';
      final p = Position.fromFen(fen);
      expect(p.turn, PieceColor.black);
      expect(p.castling.toFen(), '-');
      expect(p.halfmoveClock, 12);
      expect(p.fullmoveNumber, 34);
      expect(p.toFen(), fen);
    });

    test('rejects malformed FEN', () {
      expect(() => Position.fromFen('not a fen'), throwsFormatException);
      expect(() => Position.fromFen('8/8/8/8/8/8/8 w - - 0 1'),
          throwsFormatException); // only 7 ranks
    });
  });
}
