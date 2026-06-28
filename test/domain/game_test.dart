import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/game.dart';
import 'package:super_chess/engine/engine.dart';

void main() {
  group('Game — play, history, undo', () {
    test('plays moves and records SAN history', () {
      final game = Game.initial();
      game.play(Move.uci('e2e4'));
      game.play(Move.uci('e7e5'));
      game.play(Move.uci('g1f3'));
      expect(game.ply, 3);
      expect(game.sanHistory, ['e4', 'e5', 'Nf3']);
      expect(game.position.pieceAt(Square.parse('f3')),
          const Piece(PieceColor.white, PieceRole.knight));
    });

    test('playSan parses notation', () {
      final game = Game.initial();
      game.playSan('e4');
      game.playSan('c5');
      game.playSan('Nf3');
      expect(game.sanHistory, ['e4', 'c5', 'Nf3']);
    });

    test('undo reverts the last move and position', () {
      final game = Game.initial();
      game.play(Move.uci('e2e4'));
      final undone = game.undo();
      expect(undone, Move.uci('e2e4'));
      expect(game.ply, 0);
      expect(game.position.toFen(), kStartingFen);
      expect(game.undo(), isNull); // nothing left to undo
    });
  });

  group('Game — outcomes', () {
    test('checkmate sets the winner (fool\'s mate)', () {
      final game = Game.initial();
      for (final san in ['f3', 'e5', 'g4', 'Qh4#']) {
        game.playSan(san);
      }
      final o = game.outcome;
      expect(o.termination, GameTermination.checkmate);
      expect(o.winner, PieceColor.black);
      expect(o.isOver, isTrue);
      expect(o.isDraw, isFalse);
      expect(o.pgnResult, '0-1');
    });

    test('stalemate is a draw with no winner', () {
      final game = Game.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      final o = game.outcome;
      expect(o.termination, GameTermination.stalemate);
      expect(o.winner, isNull);
      expect(o.isDraw, isTrue);
      expect(o.pgnResult, '1/2-1/2');
    });

    test('insufficient material is a draw', () {
      final game = Game.fromFen('k7/8/8/8/8/8/8/KN6 w - - 0 1');
      expect(game.outcome.termination, GameTermination.insufficientMaterial);
    });

    test('fifty-move rule is a draw', () {
      final game = Game.fromFen(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 100 60');
      expect(game.outcome.termination, GameTermination.fiftyMoveRule);
    });

    test('threefold repetition is a draw', () {
      final game = Game.initial();
      // Shuffle both knights out and back twice -> start position occurs 3x.
      for (final san in [
        'Nf3', 'Nf6', 'Ng1', 'Ng8', //
        'Nf3', 'Nf6', 'Ng1', 'Ng8',
      ]) {
        game.playSan(san);
      }
      expect(game.outcome.termination, GameTermination.threefoldRepetition);
    });

    test('an ongoing game has no result', () {
      final game = Game.initial()..playSan('e4');
      expect(game.outcome.termination, GameTermination.ongoing);
      expect(game.outcome.isOver, isFalse);
      expect(game.outcome.pgnResult, '*');
    });
  });

  group('PGN', () {
    test('authors movetext with numbering and result', () {
      final game = Game.initial();
      for (final san in ['e4', 'e5', 'Nf3', 'Nc6']) {
        game.playSan(san);
      }
      final pgn = game.toPgn();
      expect(pgn, contains('[White "?"]'));
      expect(pgn, contains('[Result "*"]'));
      expect(pgn, contains('1. e4 e5 2. Nf3 Nc6'));
      expect(pgn.trimRight(), endsWith('*'));
    });

    test('round-trips a played game', () {
      final game = Game.initial();
      for (final san in ['d4', 'd5', 'c4', 'e6', 'Nc3', 'Nf6']) {
        game.playSan(san);
      }
      final restored = Game.fromPgn(game.toPgn());
      expect(restored.sanHistory, game.sanHistory);
      expect(restored.position.toFen(), game.position.toFen());
    });

    test('parses a PGN with tags, numbers, comments and a result', () {
      const pgn = '''
[Event "Casual game"]
[White "Alice"]
[Black "Bob"]
[Result "0-1"]

1. f3 e5 2. g4 {a blunder} Qh4# 0-1
''';
      final game = Game.fromPgn(pgn);
      expect(game.sanHistory, ['f3', 'e5', 'g4', 'Qh4#']);
      expect(game.tags['White'], 'Alice');
      expect(game.outcome.termination, GameTermination.checkmate);
      expect(game.outcome.winner, PieceColor.black);
    });

    test('round-trips a game that started from a custom FEN', () {
      const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
      final game = Game.fromFen(fen)..playSan('e4');
      final pgn = game.toPgn();
      expect(pgn, contains('[FEN "$fen"]'));
      expect(pgn, contains('[SetUp "1"]'));
      final restored = Game.fromPgn(pgn);
      expect(restored.sanHistory, ['e4']);
      expect(restored.initialPosition.toFen(), fen);
    });
  });
}
