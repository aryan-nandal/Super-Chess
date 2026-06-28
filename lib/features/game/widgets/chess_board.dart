import 'package:flutter/material.dart';

import '../../../engine/engine.dart';

/// The filled Unicode glyph for a piece [role] (both colors use the filled
/// set and are distinguished by paint color, for crisp rendering on any
/// square).
String pieceGlyph(PieceRole role) => switch (role) {
      PieceRole.king => '♚',
      PieceRole.queen => '♛',
      PieceRole.rook => '♜',
      PieceRole.bishop => '♝',
      PieceRole.knight => '♞',
      PieceRole.pawn => '♟',
    };

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
    final isEnPassantCapture = position.enPassant == square &&
        selected != null &&
        position.pieceAt(selected!)?.role == PieceRole.pawn;
    final isLastMove = lastMove != null &&
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
          if (piece != null) _Piece(piece: piece, colors: colors),
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

class _Piece extends StatelessWidget {
  final Piece piece;
  final ChessBoardColors colors;

  const _Piece({required this.piece, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    return FractionallySizedBox(
      widthFactor: 0.82,
      heightFactor: 0.82,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          pieceGlyph(piece.role),
          style: TextStyle(
            color: isWhite ? colors.whitePiece : colors.blackPiece,
            height: 1,
            shadows: [
              Shadow(
                color: isWhite ? colors.blackPiece : colors.whitePiece,
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetMarker extends StatelessWidget {
  final bool isCapture;
  final Color color;

  const _TargetMarker({super.key, required this.isCapture, required this.color});

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
