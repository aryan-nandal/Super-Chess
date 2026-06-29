import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/engine/engine.dart';

/// Validates the bundled curated CC0 Lichess library against the real engine,
/// so a malformed or unplayable puzzle can never ship. Reads from disk.
void main() {
  final puzzles = (jsonDecode(
    File('assets/puzzles/puzzles.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>()
      .map(TacticsPuzzle.fromJson)
      .toList();

  const motifs = {
    'mateIn1', 'mateIn2', 'fork', 'pin', 'skewer', 'discoveredAttack',
    'hangingPiece', 'deflection', 'backRankMate', 'sacrifice',
  };

  test('has a healthy number of puzzles (~500)', () {
    expect(puzzles.length, greaterThan(400));
    expect(puzzles.length, lessThan(800));
  });

  test('every puzzle is well-formed, motif-tagged, in the beginner band', () {
    for (final p in puzzles) {
      expect(p.id, isNotEmpty);
      expect(p.solution.length, greaterThanOrEqualTo(2));
      expect(p.rating, inInclusiveRange(700, 1800));
      expect(p.themes.any(motifs.contains), isTrue,
          reason: '${p.id} has no curated motif');
      expect(p.themes.every(motifs.contains), isTrue,
          reason: '${p.id} has a non-motif tag: ${p.themes}');
    }
  });

  test('every solution line is legal in our engine', () {
    for (final p in puzzles) {
      var pos = Position.fromFen(p.fen);
      for (final uci in p.solution) {
        final move = Move.uci(uci);
        expect(generateLegalMoves(pos), contains(move),
            reason: '${p.id}: $uci is illegal');
        pos = pos.applyMove(move);
      }
    }
  });

  test('mate puzzles end in checkmate', () {
    const mateThemes = {'mateIn1', 'mateIn2', 'backRankMate'};
    final mates = puzzles.where((p) => p.themes.any(mateThemes.contains));
    expect(mates, isNotEmpty);
    for (final p in mates) {
      var pos = Position.fromFen(p.fen);
      for (final uci in p.solution) {
        pos = pos.applyMove(Move.uci(uci));
      }
      expect(isCheckmate(pos), isTrue,
          reason: '${p.id} is tagged as mate but does not end in checkmate');
    }
  });
}
