import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';
import 'package:super_chess/features/game/board_screen.dart';
import 'package:super_chess/features/game/game_controller.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BoardScreen()),
      ),
    );
  }

  GameUiState state() => container.read(gameControllerProvider);

  testWidgets('tapping a piece then a target plays the move', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('sq_e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sq_e4')));
    await tester.pump();

    expect(state().game.sanHistory, ['e4']);
    expect(
      state().position.pieceAt(Square.parse('e4')),
      const Piece(PieceColor.white, PieceRole.pawn),
    );
    expect(find.textContaining('Black to move'), findsOneWidget);
  });

  testWidgets('undo takes back the move', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('sq_e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sq_e4')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('undo_button')));
    await tester.pump();
    expect(state().position.toFen(), kStartingFen);
  });

  testWidgets('announces checkmate with the winner', (tester) async {
    await pumpScreen(tester);
    container
        .read(gameControllerProvider.notifier)
        .loadFen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
        );
    await tester.pump();
    expect(find.textContaining('Checkmate'), findsOneWidget);
    expect(find.textContaining('Black wins'), findsOneWidget);
  });
}
