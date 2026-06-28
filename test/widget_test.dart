import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/features/game/widgets/chess_board.dart';
import 'package:super_chess/main.dart';

void main() {
  testWidgets('app boots into the board with the starting position', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SuperChessApp()));
    expect(find.text('Super Chess'), findsOneWidget);
    expect(find.text('White to move'), findsOneWidget);
    // 32 pieces on the starting board.
    final pieces = find.byWidgetPredicate((w) => w is ChessBoardView);
    expect(pieces, findsOneWidget);
  });
}
