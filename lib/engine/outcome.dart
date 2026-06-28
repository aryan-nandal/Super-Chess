import 'piece.dart';
import 'position.dart';
import 'square.dart';

/// Whether [pos] is a dead position by **insufficient mating material** under
/// the FIDE auto-draw cases: K vs K, K+minor vs K, and bishops-only with every
/// bishop on the same color complex. (K+N+N vs K and opposite-colored bishops
/// are *not* automatic draws, since a helpmate exists.)
bool hasInsufficientMaterial(Position pos) {
  final minorSquares = <int>[];
  var hasBishop = false;
  var bishopsOnly = true;

  for (var i = 0; i < 64; i++) {
    final p = pos.board[i];
    if (p == null) continue;
    switch (p.role) {
      case PieceRole.pawn:
      case PieceRole.rook:
      case PieceRole.queen:
        return false; // mating material present
      case PieceRole.bishop:
        hasBishop = true;
        minorSquares.add(i);
      case PieceRole.knight:
        bishopsOnly = false;
        minorSquares.add(i);
      case PieceRole.king:
        break;
    }
  }

  if (minorSquares.length <= 1) return true; // K vs K, or K + single minor

  // Two or more minors: only a draw if they are all bishops sharing one color.
  if (hasBishop && bishopsOnly) {
    final colors = <int>{};
    for (final i in minorSquares) {
      final sq = Square(i);
      colors.add((sq.file + sq.rank) % 2);
    }
    if (colors.length == 1) return true;
  }
  return false;
}

/// Whether the 50-move rule applies (100 halfmoves without a pawn move or
/// capture). Claiming/auto-applying the draw is a game-level concern.
bool isFiftyMoveRule(Position pos) => pos.halfmoveClock >= 100;
