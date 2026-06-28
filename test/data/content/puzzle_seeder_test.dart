import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/data/content/content_database.dart';
import 'package:super_chess/data/content/drift_puzzle_repository.dart';
import 'package:super_chess/data/content/puzzle_seeder.dart';

const _json = '''
[
  {"id":"a","fen":"fen-a","moves":"e2e4 e7e5","rating":1200,"themes":["fork"]},
  {"id":"b","fen":"fen-b","moves":"d2d4","rating":900,"themes":["mateIn1","backRankMate"]}
]
''';

void main() {
  late ContentDatabase db;
  late PuzzleSeeder seeder;
  late DriftPuzzleRepository repo;

  setUp(() {
    db = ContentDatabase(NativeDatabase.memory());
    seeder = PuzzleSeeder(db);
    repo = DriftPuzzleRepository(db);
  });
  tearDown(() => db.close());

  test('seeds puzzles and their themes from JSON', () async {
    final inserted = await seeder.seedFromJson(_json);
    expect(inserted, 2);

    final fork = await repo.byId('a');
    expect(fork!.solution, ['e2e4', 'e7e5']);
    expect(fork.rating, 1200);
    expect(fork.themes, ['fork']);

    final mate = await repo.byId('b');
    expect(mate!.themes, ['backRankMate', 'mateIn1']);

    expect(await repo.themes(), ['backRankMate', 'fork', 'mateIn1']);
  });

  test('is idempotent — re-seeding does not duplicate', () async {
    await seeder.seedFromJson(_json);
    final second = await seeder.seedFromJson(_json);
    expect(second, 0); // already populated
    expect((await repo.byTheme('fork')).length, 1);
  });
}
