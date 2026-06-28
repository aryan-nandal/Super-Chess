import 'move.dart';
import 'move_generation.dart';
import 'piece.dart';
import 'position.dart';

/// Renders [move] in Standard Algebraic Notation (SAN) for [pos]: piece letter,
/// minimal disambiguation, captures (`x`), castling (`O-O`/`O-O-O`), promotion
/// (`=Q`), and the check (`+`) / checkmate (`#`) suffix.
///
/// [move] must be legal in [pos].
String sanOf(Position pos, Move move) {
  final piece = pos.pieceAt(move.from);
  if (piece == null) {
    throw ArgumentError('no piece on ${move.from} to render');
  }

  final String body;
  if (piece.role == PieceRole.king && (move.to.file - move.from.file).abs() == 2) {
    body = move.to.file == 6 ? 'O-O' : 'O-O-O';
  } else if (piece.role == PieceRole.pawn) {
    final sb = StringBuffer();
    // A pawn changes file only when capturing (incl. en passant).
    if (move.to.file != move.from.file) {
      sb.write(String.fromCharCode(0x61 + move.from.file));
      sb.write('x');
    }
    sb.write(move.to.name);
    if (move.promotion != null) {
      sb.write('=');
      sb.write(move.promotion!.lowerChar.toUpperCase());
    }
    body = sb.toString();
  } else {
    final sb = StringBuffer();
    sb.write(piece.role.lowerChar.toUpperCase());
    sb.write(_disambiguation(pos, move, piece));
    if (pos.pieceAt(move.to) != null) sb.write('x');
    sb.write(move.to.name);
    body = sb.toString();
  }

  // Check / checkmate suffix.
  final next = pos.applyMove(move);
  if (isCheck(next)) {
    return body + (generateLegalMoves(next).isEmpty ? '#' : '+');
  }
  return body;
}

/// The minimal disambiguation string (file, rank, or full square) needed when
/// another piece of the same role can also reach the destination.
String _disambiguation(Position pos, Move move, Piece piece) {
  final rivals = generateLegalMoves(pos).where((m) {
    if (m.to != move.to || m.from == move.from) return false;
    final p = pos.pieceAt(m.from);
    return p != null && p.role == piece.role && p.color == piece.color;
  }).toList();
  if (rivals.isEmpty) return '';

  final sameFile = rivals.any((m) => m.from.file == move.from.file);
  final sameRank = rivals.any((m) => m.from.rank == move.from.rank);
  if (!sameFile) return String.fromCharCode(0x61 + move.from.file);
  if (!sameRank) return String.fromCharCode(0x31 + move.from.rank);
  return move.from.name;
}
