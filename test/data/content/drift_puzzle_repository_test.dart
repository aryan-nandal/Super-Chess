import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/data/content/content_database.dart';
import 'package:super_chess/data/content/drift_puzzle_repository.dart';

void main() {
  late ContentDatabase db;
  late DriftPuzzleRepository repo;

  Future<void> seed(
    String id,
    String fen,
    String moves,
    int rating,
    List<String> themes,
  ) async {
    await db
        .into(db.puzzles)
        .insert(
          PuzzlesCompanion.insert(
            id: id,
            fen: fen,
            movesUci: moves,
            rating: Value(rating),
          ),
        );
    for (final theme in themes) {
      await db
          .into(db.puzzleThemes)
          .insert(PuzzleThemesCompanion.insert(puzzleId: id, theme: theme));
    }
  }

  setUp(() async {
    db = ContentDatabase(NativeDatabase.memory());
    repo = DriftPuzzleRepository(db);
    await seed('p1', 'fen1', 'a7a6 e2e8', 900, ['mateIn1', 'backRankMate']);
    await seed('p2', 'fen2', 'e2e4 e7e5', 1500, ['fork']);
    await seed('p3', 'fen3', 'g1f3 b8c6', 1800, ['fork', 'pin']);
  });

  tearDown(() => db.close());

  test('byId assembles the solution line and sorted themes', () async {
    final p = await repo.byId('p1');
    expect(p, isNotNull);
    expect(p!.fen, 'fen1');
    expect(p.solution, ['a7a6', 'e2e8']);
    expect(p.rating, 900);
    expect(p.themes, ['backRankMate', 'mateIn1']);
    expect(await repo.byId('missing'), isNull);
  });

  test('byTheme filters by theme + rating band, ordered by rating', () async {
    final forks = await repo.byTheme('fork');
    expect(forks.map((p) => p.id), ['p2', 'p3']);

    final lowForks = await repo.byTheme('fork', maxRating: 1600);
    expect(lowForks.map((p) => p.id), ['p2']);

    expect(await repo.byTheme('nonexistent'), isEmpty);
  });

  test('randomByTheme returns a puzzle that has the theme', () async {
    final p = await repo.randomByTheme('fork');
    expect(p, isNotNull);
    expect(p!.themes, contains('fork'));
    expect(await repo.randomByTheme('nonexistent'), isNull);
  });

  test('themes lists distinct motifs, sorted', () async {
    expect(await repo.themes(), ['backRankMate', 'fork', 'mateIn1', 'pin']);
  });
}
