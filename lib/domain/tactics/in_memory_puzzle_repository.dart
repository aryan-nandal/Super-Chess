import 'dart:math';

import 'puzzle_repository.dart';
import 'tactics_puzzle.dart';

/// A [PuzzleRepository] backed by an in-memory list. Pure Dart — works on every
/// platform (including web) with no SQLite, so it's the app's default source
/// loaded from the bundled JSON. (The Drift repository is the persisted/scalable
/// alternative behind the same interface.)
class InMemoryPuzzleRepository implements PuzzleRepository {
  final List<TacticsPuzzle> _puzzles;
  final Random _random;

  InMemoryPuzzleRepository(List<TacticsPuzzle> puzzles, {Random? random})
      : _puzzles = List.unmodifiable(puzzles),
        _random = random ?? Random();

  @override
  Future<TacticsPuzzle?> byId(String id) async {
    for (final p in _puzzles) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<TacticsPuzzle>> byTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
    int limit = 50,
  }) async {
    final list = _tagged(theme, minRating, maxRating).toList()
      ..sort((a, b) => a.rating.compareTo(b.rating));
    return list.take(limit).toList();
  }

  @override
  Future<TacticsPuzzle?> randomByTheme(
    String theme, {
    int minRating = 0,
    int maxRating = 4000,
  }) async {
    final list = _tagged(theme, minRating, maxRating).toList();
    if (list.isEmpty) return null;
    return list[_random.nextInt(list.length)];
  }

  @override
  Future<List<String>> themes() async =>
      _puzzles.expand((p) => p.themes).toSet().toList()..sort();

  Iterable<TacticsPuzzle> _tagged(String theme, int minRating, int maxRating) =>
      _puzzles.where((p) =>
          p.themes.contains(theme) &&
          p.rating >= minRating &&
          p.rating <= maxRating);
}
