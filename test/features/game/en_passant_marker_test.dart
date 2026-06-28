import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/engine/engine.dart';
import 'package:super_chess/features/game/widgets/chess_board.dart';

/// Evidence directory supplied by the validation harness.
const _evidenceDir =
    '/var/folders/fp/s8p187hs0g39wv_67yjvnr8m0000gn/T/no-mistakes-evidence/01KW6K1CTV3Q35CCSP8H9MQDBF';

/// White to move; the black d-pawn has just played d7-d5, so e5xd6 e.p. is
/// available and the en-passant target square is the (empty) d6.
const _enPassantFen =
    'rnbqkbnr/ppp1p1pp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3';

/// Loads a real Unicode font so the chess piece glyphs render as pieces
/// (not the Ahem test-font boxes) in the captured screenshot.
Future<void> _loadChessFont() async {
  const candidates = [
    '/Library/Fonts/Arial Unicode.ttf',
    '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    '/System/Library/Fonts/Apple Symbols.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader('ChessFont')
        ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      await loader.load();
      return;
    }
  }
}

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'ChessFont'),
            child: SizedBox(width: 480, height: 480, child: child),
          ),
        ),
      ),
    );

Future<void> _capture(WidgetTester tester, Key boundaryKey, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  // toImage / toByteData drive the real engine, so they must run outside the
  // fake-async test zone.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_evidenceDir).createSync(recursive: true);
    File('$_evidenceDir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Reads the BoxDecoration of the circular marker rendered under [targetKey].
BoxDecoration _markerDecoration(WidgetTester tester, String targetKey) {
  final decorated = tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byKey(ValueKey(targetKey)),
      matching: find.byType(DecoratedBox),
    ),
  );
  return decorated.first.decoration as BoxDecoration;
}

void main() {
  testWidgets('en-passant target square renders a capture ring', (tester) async {
    await _loadChessFont();
    tester.view.physicalSize = const Size(540, 540);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final position = Position.fromFen(_enPassantFen);
    const boundaryKey = ValueKey('ep_board');

    await tester.pumpWidget(_host(
      RepaintBoundary(
        key: boundaryKey,
        child: ChessBoardView(
          position: position,
          selected: Square.parse('e5'),
          // The two legal moves for the e5 pawn: a quiet push to e6 and the
          // en-passant capture onto the empty d6.
          targets: [Square.parse('e6'), Square.parse('d6')],
          onSquareTap: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Both target squares are marked.
    expect(find.byKey(const ValueKey('target_d6')), findsOneWidget);
    expect(find.byKey(const ValueKey('target_e6')), findsOneWidget);

    // The empty en-passant square d6 is drawn as a capture RING: transparent
    // fill with a visible border, exactly like a capture onto an occupied
    // square (and unlike the small solid dot used for a quiet move).
    final d6 = _markerDecoration(tester, 'target_d6');
    expect(d6.shape, BoxShape.circle);
    expect(d6.color, Colors.transparent,
        reason: 'en-passant capture marker should be a hollow ring');
    expect(d6.border, isNotNull,
        reason: 'en-passant capture marker should have a ring border');

    // The quiet push to e6 stays a small solid dot (filled, no border).
    final e6 = _markerDecoration(tester, 'target_e6');
    expect(e6.color, isNot(Colors.transparent));
    expect(e6.border, isNull,
        reason: 'a quiet move should be a solid dot, not a ring');

    await _capture(tester, boundaryKey, 'en_passant_capture_ring.png');
  });

  testWidgets('without a selected pawn the e.p. square shows no ring',
      (tester) async {
    await _loadChessFont();
    final position = Position.fromFen(_enPassantFen);
    const boundaryKey = ValueKey('ep_board_unselected');

    await tester.pumpWidget(_host(
      RepaintBoundary(
        key: boundaryKey,
        child: ChessBoardView(
          position: position,
          onSquareTap: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Nothing selected => no target markers at all on d6.
    expect(find.byKey(const ValueKey('target_d6')), findsNothing);

    await _capture(tester, boundaryKey, 'en_passant_unselected.png');
  });
}
