import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/domain/tactics/tactics.dart';
import 'package:super_chess/features/tactics/tactics_controller.dart';
import 'package:super_chess/features/tactics/tactics_screen.dart';

const _mate = TacticsPuzzle(
  id: 'm1',
  fen: '6k1/p4ppp/8/8/8/8/4R3/6K1 b - - 0 1',
  solution: ['a7a6', 'e2e8'],
  rating: 900,
  themes: ['mateIn1', 'backRankMate'],
);

const _fork = TacticsPuzzle(
  id: 'f1',
  fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  solution: ['e2e4', 'e7e5'],
  rating: 1200,
  themes: ['fork'],
);

String _title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('tactics_motif'))).data!;

Future<void> _pumpLoaded(
  WidgetTester tester,
  List<TacticsPuzzle> puzzles,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        puzzleRepositoryProvider.overrideWithValue(
          InMemoryPuzzleRepository(puzzles),
        ),
      ],
      child: const MaterialApp(home: TacticsScreen()),
    ),
  );
  // Let the async load resolve and rebuild off the loading spinner.
  for (
    var i = 0;
    i < 10 && find.byKey(const ValueKey('tactics_motif')).evaluate().isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('shows the motif title, picker, and board', (tester) async {
    await _pumpLoaded(tester, [_mate]);
    expect(_title(tester), 'Mate in 1');
    expect(find.byKey(const ValueKey('motif_all')), findsOneWidget);
    expect(find.byKey(const ValueKey('sq_e2')), findsOneWidget);
    expect(find.textContaining('to play'), findsOneWidget);
  });

  testWidgets('the motif picker filters to the chosen motif', (tester) async {
    await _pumpLoaded(tester, [_mate, _fork]);
    expect(find.byKey(const ValueKey('motif_fork')), findsOneWidget);
    expect(find.byKey(const ValueKey('motif_mateIn1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('motif_fork')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(_title(tester), 'Fork'); // now practicing the chosen motif
  });

  testWidgets('playing the solution shows Solved + Next', (tester) async {
    await _pumpLoaded(tester, [_mate]);
    await tester.tap(find.byKey(const ValueKey('sq_e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sq_e8')));
    await tester.pump();

    expect(find.text('✓ Solved!'), findsOneWidget);
    expect(find.byKey(const ValueKey('next_button')), findsOneWidget);
  });

  testWidgets('a wrong move shows the retry control', (tester) async {
    await _pumpLoaded(tester, [_mate]);
    await tester.tap(find.byKey(const ValueKey('sq_e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sq_e7'))); // legal but wrong
    await tester.pump();

    expect(find.textContaining('Not the move'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry_button')), findsOneWidget);
  });

  testWidgets('an empty library shows a message', (tester) async {
    await _pumpLoaded(tester, []);
    expect(find.textContaining('No puzzles'), findsOneWidget);
  });
}
