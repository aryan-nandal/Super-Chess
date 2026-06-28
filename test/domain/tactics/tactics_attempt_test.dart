import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/engine/engine.dart';

void main() {
  // A clean mate-in-1: Black plays the setup move a7a6, then White mates with
  // the rook to e8 (back-rank, king boxed in by its own f/g/h pawns).
  const mateInOne = TacticsPuzzle(
    id: 'm1',
    fen: '6k1/p4ppp/8/8/8/8/4R3/6K1 b - - 0 1',
    solution: ['a7a6', 'e2e8'],
    rating: 900,
    themes: ['mateIn1', 'backRankMate'],
  );

  group('puzzle data integrity (engine-verified)', () {
    test('the whole solution line is legal and ends in checkmate', () {
      var pos = Position.fromFen(mateInOne.fen);
      for (final uci in mateInOne.solution) {
        final move = Move.uci(uci);
        expect(generateLegalMoves(pos), contains(move),
            reason: '$uci must be legal');
        pos = pos.applyMove(move);
      }
      expect(isCheckmate(pos), isTrue);
    });
  });

  group('TacticsAttempt', () {
    test('applies the opponent setup move and hands the turn to the player', () {
      final attempt = TacticsAttempt(mateInOne);
      expect(attempt.position.pieceAt(Square.parse('a6')),
          const Piece(PieceColor.black, PieceRole.pawn));
      expect(attempt.position.turn, PieceColor.white); // player to move
      expect(attempt.lastMove, Move.uci('a7a6'));
      expect(attempt.isSolved, isFalse);
      expect(attempt.isFailed, isFalse);
    });

    test('the solution move solves the puzzle', () {
      final attempt = TacticsAttempt(mateInOne);
      final outcome = attempt.playUserMove(Move.uci('e2e8'));
      expect(outcome, MoveOutcome.solved);
      expect(attempt.isSolved, isTrue);
    });

    test('a wrong move fails the attempt', () {
      final attempt = TacticsAttempt(mateInOne);
      final outcome = attempt.playUserMove(Move.uci('e2e7')); // legal but wrong
      expect(outcome, MoveOutcome.incorrect);
      expect(attempt.isFailed, isTrue);
      expect(attempt.isSolved, isFalse);
    });

    test('an alternative move that also checkmates is accepted', () {
      // Same idea but a second rook gives a second mating move (d2d8) that is
      // not the listed solution (e2e8).
      const twoMates = TacticsPuzzle(
        id: 'm1b',
        fen: '6k1/p4ppp/8/8/8/8/3RR3/6K1 b - - 0 1',
        solution: ['a7a6', 'e2e8'],
      );
      final attempt = TacticsAttempt(twoMates);
      final outcome = attempt.playUserMove(Move.uci('d2d8')); // alternative mate
      expect(outcome, MoveOutcome.solved);
      expect(attempt.isSolved, isTrue);
    });

    test('multi-move: a correct move auto-plays the opponent reply', () {
      // Quiet 4-ply line to exercise the flow: setup e4, then the player (Black)
      // plays e5, White auto-replies Nf3, the player plays Nc6 -> solved.
      const line = TacticsPuzzle(
        id: 'flow',
        fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        solution: ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
      );
      final attempt = TacticsAttempt(line);
      expect(attempt.position.turn, PieceColor.black); // player is Black here

      final first = attempt.playUserMove(Move.uci('e7e5'));
      expect(first, MoveOutcome.correct);
      expect(attempt.isSolved, isFalse);
      // The opponent's reply Nf3 was applied automatically.
      expect(attempt.position.pieceAt(Square.parse('f3')),
          const Piece(PieceColor.white, PieceRole.knight));
      expect(attempt.lastMove, Move.uci('g1f3'));

      final second = attempt.playUserMove(Move.uci('b8c6'));
      expect(second, MoveOutcome.solved);
      expect(attempt.isSolved, isTrue);
    });

    test('moves after the puzzle is solved are ignored', () {
      final attempt = TacticsAttempt(mateInOne)..playUserMove(Move.uci('e2e8'));
      expect(attempt.isSolved, isTrue);
      final outcome = attempt.playUserMove(Move.uci('g1g2'));
      expect(outcome, MoveOutcome.solved);
    });
  });
}
