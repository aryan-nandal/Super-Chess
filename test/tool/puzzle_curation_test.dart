import 'package:flutter_test/flutter_test.dart';

import '../../tool/puzzle_curation.dart';

const _header =
    'PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags';

// id, fen, moves, rating, ratingDev, popularity, nbPlays, themes, url, openings
const _rows = [
  '00001,fen1,e2e4 e7e5,1500,80,90,500,fork middlegame,url,',
  '00002,fen2,d2d4 d7d5,1500,80,95,800,fork,url,',
  '00003,fen3,g1f3 b8c6,1520,80,40,100,fork,url,', // low popularity
  '00004,fen4,a7a6 e2e8,900,80,90,300,backRankMate mateIn1,url,',
  '00005,fen5,h2h4 a7a5,1500,80,85,50,fork,url,', // low nbPlays
];

void main() {
  group('parseLichessRow', () {
    test('parses a valid row', () {
      final row = parseLichessRow(_rows[0])!;
      expect(row.puzzle.id, '00001');
      expect(row.puzzle.solution, ['e2e4', 'e7e5']);
      expect(row.puzzle.rating, 1500);
      expect(row.puzzle.themes, ['fork', 'middlegame']);
      expect(row.popularity, 90);
      expect(row.nbPlays, 500);
    });

    test('rejects the header, blanks, and malformed rows', () {
      expect(parseLichessRow(_header), isNull);
      expect(parseLichessRow(''), isNull);
      expect(parseLichessRow('too,few,cols'), isNull);
    });
  });

  test('ratingBand floors to the band', () {
    expect(ratingBand(1550), 1400);
    expect(ratingBand(900), 800);
    expect(ratingBand(1500, width: 500), 1500);
  });

  group('curate', () {
    List<LichessPuzzleRow> parsed() =>
        _rows.map(parseLichessRow).whereType<LichessPuzzleRow>().toList();

    test('filters by quality, stratifies per theme×band, dedups, sorts', () {
      final result = curate(
        parsed(),
        perBucket: 1,
        minPopularity: 80,
        minNbPlays: 100,
      );
      // 00003 (low popularity) and 00005 (low nbPlays) are dropped.
      expect(result.map((p) => p.id).toSet(), {'00001', '00002', '00004'});
      // Rating-ascending: the 900 puzzle comes first.
      expect(result.first.id, '00004');
      expect(result.first.rating, 900);
    });

    test('per-bucket cap keeps the most-played', () {
      // fork@1400 band has 00001 (500 plays) and 00002 (800). perBucket:1 keeps
      // the more-played 00002 for that bucket.
      final result = curate(
        parsed(),
        perBucket: 1,
        minPopularity: 80,
        minNbPlays: 100,
        themes: {'fork'},
      );
      expect(result.map((p) => p.id), contains('00002'));
      expect(result.map((p) => p.id), isNot(contains('00004'))); // no fork tag
    });

    test('theme restriction only includes puzzles with that motif', () {
      final result = curate(parsed(), themes: {'fork'});
      expect(result, isNotEmpty);
      expect(result.every((p) => p.themes.contains('fork')), isTrue);
      expect(result.map((p) => p.id), isNot(contains('00004')));
    });

    test('a theme allowlist filters the output themes to the allowlist', () {
      // 00001 is tagged "fork middlegame" — only the allowlisted motif survives.
      final result = curate(parsed(), themes: {'fork'});
      final p = result.firstWhere((p) => p.id == '00001');
      expect(p.themes, ['fork']);
    });

    test('rating range drops out-of-band puzzles', () {
      // 00004 is rated 900; restrict to 1000+ and it's gone.
      final result = curate(parsed(), minRating: 1000);
      expect(result.map((p) => p.id), isNot(contains('00004')));
      expect(result.every((p) => p.rating >= 1000), isTrue);
    });
  });
}
