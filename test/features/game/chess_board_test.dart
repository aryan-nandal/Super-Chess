import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';
import 'package:super_chess/features/game/widgets/chess_board.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders all 64 squares', (tester) async {
    await tester.pumpWidget(
      _host(ChessBoardView(position: Position.initial, onSquareTap: (_) {})),
    );
    expect(find.byKey(const ValueKey('sq_a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sq_h8')), findsOneWidget);
    expect(find.byKey(const ValueKey('sq_e4')), findsOneWidget);
    final cells = find.byWidgetPredicate(
      (w) => w.key.toString().contains('sq_'),
    );
    expect(cells, findsNWidgets(64));
  });

  Finder pieces(bool Function(Piece) test) =>
      find.byWidgetPredicate((w) => w is PieceShape && test(w.piece));

  testWidgets('renders the starting pieces', (tester) async {
    await tester.pumpWidget(
      _host(ChessBoardView(position: Position.initial, onSquareTap: (_) {})),
    );
    expect(pieces((p) => true), findsNWidgets(32));
    expect(pieces((p) => p.role == PieceRole.pawn), findsNWidgets(16));
    expect(pieces((p) => p.role == PieceRole.king), findsNWidgets(2));
    expect(pieces((p) => p == const Piece(PieceColor.white, PieceRole.queen)),
        findsOneWidget);
  });

  testWidgets('white and black pieces keep their own colors', (tester) async {
    // The reported bug: pieces collapsed to one color after a move because the
    // glyph font ignored the tint. Vector pieces resolve color directly.
    await tester.pumpWidget(
      _host(ChessBoardView(position: Position.initial, onSquareTap: (_) {})),
    );
    const colors = ChessBoardColors();
    final white =
        pieceFillStroke(const Piece(PieceColor.white, PieceRole.pawn), colors);
    final black =
        pieceFillStroke(const Piece(PieceColor.black, PieceRole.pawn), colors);
    expect(white.fill, colors.whitePiece);
    expect(black.fill, colors.blackPiece);
    expect(white.fill, isNot(black.fill));
  });

  testWidgets('reports the tapped square', (tester) async {
    Square? tapped;
    await tester.pumpWidget(
      _host(
        ChessBoardView(
          position: Position.initial,
          onSquareTap: (s) => tapped = s,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('sq_e2')));
    expect(tapped, Square.parse('e2'));
  });

  testWidgets('shows the selection and its target markers', (tester) async {
    await tester.pumpWidget(
      _host(
        ChessBoardView(
          position: Position.initial,
          selected: Square.parse('e2'),
          targets: [Square.parse('e3'), Square.parse('e4')],
          onSquareTap: (_) {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('target_e3')), findsOneWidget);
    expect(find.byKey(const ValueKey('target_e4')), findsOneWidget);
  });

  testWidgets('highlights the last move and a checked king', (tester) async {
    await tester.pumpWidget(
      _host(
        ChessBoardView(
          position: Position.initial,
          lastMove: Move.uci('e2e4'),
          checkSquare: Square.parse('e1'),
          onSquareTap: (_) {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('lastmove_e2')), findsOneWidget);
    expect(find.byKey(const ValueKey('lastmove_e4')), findsOneWidget);
    expect(find.byKey(const ValueKey('check')), findsOneWidget);
  });

  testWidgets('renders without error when flipped to black orientation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ChessBoardView(
          position: Position.initial,
          orientation: PieceColor.black,
          onSquareTap: (_) {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('sq_a1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
