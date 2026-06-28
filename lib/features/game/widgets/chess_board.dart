import 'package:flutter/material.dart';

import '../../../engine/engine.dart';

/// The fill and outline colors for a piece, resolved from the palette.
///
/// Pieces are drawn as vector shapes (not font glyphs), so the color is applied
/// directly to the canvas and can never be overridden by emoji-presentation
/// fonts — white pieces stay white and black pieces stay black on every
/// platform.
({Color fill, Color stroke}) pieceFillStroke(
  Piece piece,
  ChessBoardColors colors,
) =>
    piece.color == PieceColor.white
    ? (fill: colors.whitePiece, stroke: colors.blackPiece)
    : (fill: colors.blackPiece, stroke: colors.whitePiece);

/// Color palette for the board. Defaults to a calm classic scheme; the
/// glassmorphism/neon theming lands in a later polish pass.
class ChessBoardColors {
  final Color lightSquare;
  final Color darkSquare;
  final Color selected;
  final Color target;
  final Color lastMove;
  final Color check;
  final Color whitePiece;
  final Color blackPiece;

  const ChessBoardColors({
    this.lightSquare = const Color(0xFFEBECD0),
    this.darkSquare = const Color(0xFF6E8C57),
    this.selected = const Color(0x80F6F669),
    this.target = const Color(0x4D000000),
    this.lastMove = const Color(0x66F6F669),
    this.check = const Color(0x99E53935),
    this.whitePiece = const Color(0xFFFAFAFA),
    this.blackPiece = const Color(0xFF202020),
  });
}

/// A presentational 8×8 chess board. It renders [position] (with optional
/// selection, legal-target, last-move and check highlights) and reports taps
/// via [onSquareTap]. It holds no game logic and no Riverpod — fully reusable
/// and widget-testable.
class ChessBoardView extends StatelessWidget {
  final Position position;

  /// Which color sits at the bottom of the board.
  final PieceColor orientation;

  final Square? selected;
  final List<Square> targets;
  final Move? lastMove;
  final Square? checkSquare;
  final ValueChanged<Square> onSquareTap;
  final ChessBoardColors colors;

  const ChessBoardView({
    super.key,
    required this.position,
    required this.onSquareTap,
    this.orientation = PieceColor.white,
    this.selected,
    this.targets = const [],
    this.lastMove,
    this.checkSquare,
    this.colors = const ChessBoardColors(),
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          for (var displayRow = 0; displayRow < 8; displayRow++)
            Expanded(
              child: Row(
                children: [
                  for (var displayCol = 0; displayCol < 8; displayCol++)
                    Expanded(child: _buildCell(displayRow, displayCol)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(int displayRow, int displayCol) {
    final rank = orientation == PieceColor.white ? 7 - displayRow : displayRow;
    final file = orientation == PieceColor.white ? displayCol : 7 - displayCol;
    final square = Square.at(file: file, rank: rank);

    final isLight = (file + rank).isOdd;
    final piece = position.pieceAt(square);
    final isSelected = selected == square;
    final isTarget = targets.contains(square);
    final isEnPassantCapture =
        position.enPassant == square &&
        selected != null &&
        position.pieceAt(selected!)?.role == PieceRole.pawn;
    final isLastMove =
        lastMove != null &&
        (square == lastMove!.from || square == lastMove!.to);
    final isCheck = checkSquare == square;

    return GestureDetector(
      key: ValueKey('sq_${square.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onSquareTap(square),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: isLight ? colors.lightSquare : colors.darkSquare),
          if (isLastMove)
            ColoredBox(
              key: ValueKey('lastmove_${square.name}'),
              color: colors.lastMove,
            ),
          if (isCheck)
            DecoratedBox(
              key: const ValueKey('check'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colors.check, colors.check.withAlpha(0)],
                ),
              ),
            ),
          if (isSelected)
            ColoredBox(key: const ValueKey('selected'), color: colors.selected),
          if (piece != null)
            PieceShape(
              key: ValueKey('piece_${square.name}'),
              piece: piece,
              colors: colors,
            ),
          if (isTarget)
            _TargetMarker(
              key: ValueKey('target_${square.name}'),
              isCapture: piece != null || isEnPassantCapture,
              color: colors.target,
            ),
        ],
      ),
    );
  }
}

/// A single chess piece rendered as a vector silhouette (filled + outlined).
/// Color comes straight from the palette via [pieceFillStroke], so it is
/// never at the mercy of platform emoji fonts.
class PieceShape extends StatelessWidget {
  final Piece piece;
  final ChessBoardColors colors;

  const PieceShape({super.key, required this.piece, required this.colors});

  @override
  Widget build(BuildContext context) {
    final paint = pieceFillStroke(piece, colors);
    return FractionallySizedBox(
      widthFactor: 0.86,
      heightFactor: 0.86,
      child: CustomPaint(
        painter: _PiecePainter(piece.role, paint.fill, paint.stroke),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final PieceRole role;
  final Color fill;
  final Color stroke;

  _PiecePainter(this.role, this.fill, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final path = _pathFor(role, s);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05 * s
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.role != role || old.fill != fill || old.stroke != stroke;
}

/// Builds the unioned silhouette path for a piece in a square of side [s].
/// Coordinates are authored in a 0..1 unit space (x right, y down) and scaled.
Path _pathFor(PieceRole role, double s) {
  Rect rect(double x, double y, double w, double h) =>
      Rect.fromLTWH(x * s, y * s, w * s, h * s);
  Offset off(double x, double y) => Offset(x * s, y * s);
  Path circle(double cx, double cy, double r) =>
      Path()..addOval(Rect.fromCircle(center: off(cx, cy), radius: r * s));
  Path rrect(double x, double y, double w, double h, double r) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect(x, y, w, h), Radius.circular(r * s)));
  Path poly(List<List<double>> pts) {
    final p = Path()..moveTo(pts.first[0] * s, pts.first[1] * s);
    for (final pt in pts.skip(1)) {
      p.lineTo(pt[0] * s, pt[1] * s);
    }
    return p..close();
  }

  Path union(List<Path> parts) {
    var p = parts.first;
    for (var i = 1; i < parts.length; i++) {
      p = Path.combine(PathOperation.union, p, parts[i]);
    }
    return p;
  }

  // A common pedestal shared by every piece.
  List<Path> base() => [
    rrect(0.24, 0.80, 0.52, 0.10, 0.05), // foot
    rrect(0.30, 0.73, 0.40, 0.08, 0.03), // plinth
  ];

  switch (role) {
    case PieceRole.pawn:
      return union([
        ...base(),
        poly([
          [0.42, 0.42],
          [0.58, 0.42],
          [0.66, 0.75],
          [0.34, 0.75],
        ]),
        circle(0.5, 0.30, 0.135),
      ]);
    case PieceRole.rook:
      return union([
        ...base(),
        poly([
          [0.35, 0.44],
          [0.65, 0.44],
          [0.69, 0.74],
          [0.31, 0.74],
        ]),
        rrect(0.30, 0.34, 0.40, 0.12, 0.01),
        rrect(0.29, 0.25, 0.11, 0.11, 0.01),
        rrect(0.445, 0.25, 0.11, 0.11, 0.01),
        rrect(0.60, 0.25, 0.11, 0.11, 0.01),
      ]);
    case PieceRole.bishop:
      final mitre = Path()
        ..moveTo(0.5 * s, 0.16 * s)
        ..cubicTo(0.66 * s, 0.30 * s, 0.62 * s, 0.46 * s, 0.5 * s, 0.49 * s)
        ..cubicTo(0.38 * s, 0.46 * s, 0.34 * s, 0.30 * s, 0.5 * s, 0.16 * s)
        ..close();
      return union([
        ...base(),
        poly([
          [0.39, 0.48],
          [0.61, 0.48],
          [0.67, 0.74],
          [0.33, 0.74],
        ]),
        rrect(0.37, 0.43, 0.26, 0.07, 0.03),
        mitre,
        circle(0.5, 0.15, 0.05),
      ]);
    case PieceRole.knight:
      return union([
        ...base(),
        poly([
          [0.62, 0.74],
          [0.64, 0.42],
          [0.585, 0.24],
          [0.62, 0.14],
          [0.53, 0.25],
          [0.49, 0.16],
          [0.43, 0.31],
          [0.29, 0.35],
          [0.20, 0.45],
          [0.25, 0.51],
          [0.35, 0.50],
          [0.40, 0.60],
          [0.39, 0.74],
        ]),
      ]);
    case PieceRole.queen:
      final parts = <Path>[
        ...base(),
        poly([
          [0.37, 0.44],
          [0.63, 0.44],
          [0.69, 0.74],
          [0.31, 0.74],
        ]),
        rrect(0.35, 0.36, 0.30, 0.10, 0.02),
      ];
      for (final cx in const [0.30, 0.40, 0.50, 0.60, 0.70]) {
        parts.add(poly([
          [cx - 0.06, 0.40],
          [cx, 0.20],
          [cx + 0.06, 0.40],
        ]));
        parts.add(circle(cx, 0.18, 0.035));
      }
      return union(parts);
    case PieceRole.king:
      return union([
        ...base(),
        poly([
          [0.36, 0.46],
          [0.64, 0.46],
          [0.70, 0.74],
          [0.30, 0.74],
        ]),
        rrect(0.33, 0.40, 0.34, 0.10, 0.04), // shoulders
        rrect(0.41, 0.30, 0.18, 0.12, 0.02), // crown band
        rrect(0.465, 0.10, 0.07, 0.24, 0.01), // cross (vertical)
        rrect(0.40, 0.16, 0.20, 0.07, 0.01), // cross (horizontal)
      ]);
  }
}

class _TargetMarker extends StatelessWidget {
  final bool isCapture;
  final Color color;

  const _TargetMarker({
    super.key,
    required this.isCapture,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: isCapture ? 0.92 : 0.34,
        heightFactor: isCapture ? 0.92 : 0.34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapture ? Colors.transparent : color,
            border: isCapture ? Border.all(color: color, width: 3) : null,
          ),
        ),
      ),
    );
  }
}
