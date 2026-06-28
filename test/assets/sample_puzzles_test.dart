import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/engine/engine.dart';

/// Validates the bundled sample asset against the real engine, so a malformed
/// or incorrect puzzle can never ship. Reads the file directly from disk.
void main() {
  final puzzles = (jsonDecode(
    File('assets/puzzles/sample_puzzles.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>()
      .map(TacticsPuzzle.fromJson)
      .toList();

  test('the sample asset is non-empty and well-formed', () {
    expect(puzzles, isNotEmpty);
    for (final p in puzzles) {
      expect(p.id, isNotEmpty);
      expect(p.fen, isNotEmpty);
      // At least an opponent setup move + one player move.
      expect(p.solution.length, greaterThanOrEqualTo(2));
      expect(p.themes, isNotEmpty);
    }
  });

  group('every sample puzzle is engine-valid', () {
    for (final p in puzzles) {
      test('${p.id}: legal line${_isMate(p) ? ' ending in checkmate' : ''}',
          () {
        var pos = Position.fromFen(p.fen);
        for (final uci in p.solution) {
          final move = Move.uci(uci);
          expect(generateLegalMoves(pos), contains(move),
              reason: '$uci in ${p.id} must be legal');
          pos = pos.applyMove(move);
        }
        if (_isMate(p)) {
          expect(isCheckmate(pos), isTrue,
              reason: '${p.id} is tagged as mate but does not end in checkmate');
        }
      });
    }
  });

  test('TacticsAttempt solves each sample via its player moves', () {
    for (final p in puzzles) {
      final attempt = TacticsAttempt(p);
      for (var i = 1; i < p.solution.length; i += 2) {
        final outcome = attempt.playUserMove(Move.uci(p.solution[i]));
        expect(outcome, isNot(MoveOutcome.incorrect),
            reason: '${p.id}: player move ${p.solution[i]} was rejected');
      }
      expect(attempt.isSolved, isTrue, reason: '${p.id} should be solved');
    }
  });
}

bool _isMate(TacticsPuzzle p) =>
    p.themes.any((t) => t.toLowerCase().contains('mate'));
