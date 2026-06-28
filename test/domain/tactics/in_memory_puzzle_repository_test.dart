import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';

const _puzzles = [
  TacticsPuzzle(id: 'a', fen: 'fa', solution: ['e2e4'], rating: 1200, themes: ['fork']),
  TacticsPuzzle(id: 'b', fen: 'fb', solution: ['d2d4'], rating: 1800, themes: ['fork', 'pin']),
  TacticsPuzzle(id: 'c', fen: 'fc', solution: ['g1f3'], rating: 900, themes: ['mateIn1']),
];

void main() {
  final repo = InMemoryPuzzleRepository(_puzzles, random: Random(1));

  test('byId', () async {
    expect((await repo.byId('b'))!.themes, ['fork', 'pin']);
    expect(await repo.byId('missing'), isNull);
  });

  test('byTheme filters by theme + rating, ordered by rating', () async {
    final forks = await repo.byTheme('fork');
    expect(forks.map((p) => p.id), ['a', 'b']);
    expect((await repo.byTheme('fork', maxRating: 1500)).map((p) => p.id), ['a']);
    expect(await repo.byTheme('nope'), isEmpty);
  });

  test('randomByTheme returns a matching puzzle, or null', () async {
    final p = await repo.randomByTheme('fork');
    expect(['a', 'b'], contains(p!.id));
    expect(await repo.randomByTheme('nope'), isNull);
  });

  test('themes lists distinct motifs, sorted', () async {
    expect(await repo.themes(), ['fork', 'mateIn1', 'pin']);
  });
}
