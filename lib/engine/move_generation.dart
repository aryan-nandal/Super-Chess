import 'move.dart';
import 'piece.dart';
import 'position.dart';
import 'square.dart';

// Direction offsets as [fileDelta, rankDelta].
const List<List<int>> _knightDeltas = [
  [1, 2], [2, 1], [2, -1], [1, -2], //
  [-1, -2], [-2, -1], [-2, 1], [-1, 2],
];
const List<List<int>> _kingDeltas = [
  [1, 0], [1, 1], [0, 1], [-1, 1], //
  [-1, 0], [-1, -1], [0, -1], [1, -1],
];
const List<List<int>> _bishopDirs = [
  [1, 1], [1, -1], [-1, 1], [-1, -1]
];
const List<List<int>> _rookDirs = [
  [1, 0], [-1, 0], [0, 1], [0, -1]
];

Piece? _at(List<Piece?> board, int file, int rank) =>
    (file < 0 || file > 7 || rank < 0 || rank > 7)
        ? null
        : board[rank * 8 + file];

/// Whether [square] is attacked by any piece of color [by] on [board].
///
/// Rays are traced outward from the square (constant work), so this is cheap
/// enough to call once per generated move for the legality filter.
bool isSquareAttacked(List<Piece?> board, Square square, PieceColor by) {
  final f = square.file;
  final r = square.rank;

  // Pawns: an attacker pawn sits one rank "behind" the square relative to its
  // own advance direction (white advances up, so it attacks from below).
  final pawnRank = by == PieceColor.white ? r - 1 : r + 1;
  for (final df in const [-1, 1]) {
    final p = _at(board, f + df, pawnRank);
    if (p != null && p.color == by && p.role == PieceRole.pawn) return true;
  }

  for (final d in _knightDeltas) {
    final p = _at(board, f + d[0], r + d[1]);
    if (p != null && p.color == by && p.role == PieceRole.knight) return true;
  }

  for (final d in _kingDeltas) {
    final p = _at(board, f + d[0], r + d[1]);
    if (p != null && p.color == by && p.role == PieceRole.king) return true;
  }

  for (final d in _bishopDirs) {
    if (_raysHit(board, f, d[0], r, d[1], by, PieceRole.bishop)) return true;
  }
  for (final d in _rookDirs) {
    if (_raysHit(board, f, d[0], r, d[1], by, PieceRole.rook)) return true;
  }
  return false;
}

/// Traces a ray and reports whether the first piece met is a [slider] (or a
/// queen) of color [by].
bool _raysHit(List<Piece?> board, int f, int df, int r, int dr, PieceColor by,
    PieceRole slider) {
  var nf = f + df;
  var nr = r + dr;
  while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
    final p = board[nr * 8 + nf];
    if (p != null) {
      return p.color == by &&
          (p.role == slider || p.role == PieceRole.queen);
    }
    nf += df;
    nr += dr;
  }
  return false;
}

Square _kingSquare(List<Piece?> board, PieceColor color) {
  for (var i = 0; i < 64; i++) {
    final p = board[i];
    if (p != null && p.role == PieceRole.king && p.color == color) {
      return Square(i);
    }
  }
  throw StateError('no $color king on the board');
}

/// Whether the side to move in [pos] is in check.
bool isCheck(Position pos) => isSquareAttacked(
    pos.board, _kingSquare(pos.board, pos.turn), pos.turn.opposite);

/// All fully-legal moves for the side to move in [pos].
List<Move> generateLegalMoves(Position pos) {
  final pseudo = _pseudoLegalMoves(pos);
  final legal = <Move>[];
  for (final move in pseudo) {
    final next = pos.applyMove(move);
    final kingSq = _kingSquare(next.board, pos.turn);
    if (!isSquareAttacked(next.board, kingSq, pos.turn.opposite)) {
      legal.add(move);
    }
  }
  return legal;
}

/// Whether [pos] is checkmate (in check with no legal escape).
bool isCheckmate(Position pos) =>
    isCheck(pos) && generateLegalMoves(pos).isEmpty;

/// Whether [pos] is stalemate (not in check but no legal move).
bool isStalemate(Position pos) =>
    !isCheck(pos) && generateLegalMoves(pos).isEmpty;

List<Move> _pseudoLegalMoves(Position pos) {
  final board = pos.board;
  final us = pos.turn;
  final moves = <Move>[];
  for (var i = 0; i < 64; i++) {
    final piece = board[i];
    if (piece == null || piece.color != us) continue;
    final from = Square(i);
    switch (piece.role) {
      case PieceRole.pawn:
        _pawnMoves(pos, from, moves);
      case PieceRole.knight:
        for (final d in _knightDeltas) {
          _addStep(board, us, from, from.file + d[0], from.rank + d[1], moves);
        }
      case PieceRole.king:
        for (final d in _kingDeltas) {
          _addStep(board, us, from, from.file + d[0], from.rank + d[1], moves);
        }
        _castlingMoves(pos, from, moves);
      case PieceRole.bishop:
        _slidingMoves(board, us, from, _bishopDirs, moves);
      case PieceRole.rook:
        _slidingMoves(board, us, from, _rookDirs, moves);
      case PieceRole.queen:
        _slidingMoves(board, us, from, _bishopDirs, moves);
        _slidingMoves(board, us, from, _rookDirs, moves);
    }
  }
  return moves;
}

void _addStep(List<Piece?> board, PieceColor us, Square from, int nf, int nr,
    List<Move> out) {
  if (nf < 0 || nf > 7 || nr < 0 || nr > 7) return;
  final target = board[nr * 8 + nf];
  if (target == null || target.color != us) {
    out.add(Move(from, Square(nr * 8 + nf)));
  }
}

void _slidingMoves(List<Piece?> board, PieceColor us, Square from,
    List<List<int>> dirs, List<Move> out) {
  for (final d in dirs) {
    var nf = from.file + d[0];
    var nr = from.rank + d[1];
    while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
      final target = board[nr * 8 + nf];
      if (target == null) {
        out.add(Move(from, Square(nr * 8 + nf)));
      } else {
        if (target.color != us) out.add(Move(from, Square(nr * 8 + nf)));
        break;
      }
      nf += d[0];
      nr += d[1];
    }
  }
}

void _pawnMoves(Position pos, Square from, List<Move> out) {
  final board = pos.board;
  final us = pos.turn;
  final f = from.file;
  final r = from.rank;
  final dir = us == PieceColor.white ? 1 : -1;
  final startRank = us == PieceColor.white ? 1 : 6;
  final promoRank = us == PieceColor.white ? 7 : 0;

  // Pushes.
  final r1 = r + dir;
  if (r1 >= 0 && r1 < 8 && board[r1 * 8 + f] == null) {
    _addPawnMove(from, Square(r1 * 8 + f), promoRank, out);
    final r2 = r + 2 * dir;
    if (r == startRank && board[r2 * 8 + f] == null) {
      out.add(Move(from, Square(r2 * 8 + f)));
    }
  }

  // Captures (including en passant).
  for (final df in const [-1, 1]) {
    final cf = f + df;
    final cr = r + dir;
    if (cf < 0 || cf > 7 || cr < 0 || cr > 7) continue;
    final to = Square(cr * 8 + cf);
    final target = board[cr * 8 + cf];
    if (target != null && target.color != us) {
      _addPawnMove(from, to, promoRank, out);
    } else if (target == null && pos.enPassant != null && to == pos.enPassant) {
      out.add(Move(from, to));
    }
  }
}

void _addPawnMove(Square from, Square to, int promoRank, List<Move> out) {
  if (to.rank == promoRank) {
    out.add(Move(from, to, promotion: PieceRole.queen));
    out.add(Move(from, to, promotion: PieceRole.rook));
    out.add(Move(from, to, promotion: PieceRole.bishop));
    out.add(Move(from, to, promotion: PieceRole.knight));
  } else {
    out.add(Move(from, to));
  }
}

void _castlingMoves(Position pos, Square from, List<Move> out) {
  final us = pos.turn;
  final board = pos.board;
  final rank = us == PieceColor.white ? 0 : 7;
  // King must be on its home square and not currently in check.
  if (from.rank != rank || from.file != 4) return;
  final opp = us.opposite;
  if (isSquareAttacked(board, from, opp)) return;

  final kingSide =
      us == PieceColor.white ? pos.castling.whiteKingSide : pos.castling.blackKingSide;
  final queenSide = us == PieceColor.white
      ? pos.castling.whiteQueenSide
      : pos.castling.blackQueenSide;

  if (kingSide &&
      board[rank * 8 + 5] == null &&
      board[rank * 8 + 6] == null &&
      !isSquareAttacked(board, Square(rank * 8 + 5), opp) &&
      !isSquareAttacked(board, Square(rank * 8 + 6), opp)) {
    out.add(Move(from, Square(rank * 8 + 6)));
  }
  if (queenSide &&
      board[rank * 8 + 1] == null &&
      board[rank * 8 + 2] == null &&
      board[rank * 8 + 3] == null &&
      !isSquareAttacked(board, Square(rank * 8 + 2), opp) &&
      !isSquareAttacked(board, Square(rank * 8 + 3), opp)) {
    out.add(Move(from, Square(rank * 8 + 2)));
  }
}
