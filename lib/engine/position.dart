import 'piece.dart';
import 'square.dart';

/// The standard starting position, in FEN.
const String kStartingFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

/// Immutable castling-availability flags.
class CastlingRights {
  final bool whiteKingSide;
  final bool whiteQueenSide;
  final bool blackKingSide;
  final bool blackQueenSide;

  const CastlingRights({
    this.whiteKingSide = false,
    this.whiteQueenSide = false,
    this.blackKingSide = false,
    this.blackQueenSide = false,
  });

  static const none = CastlingRights();

  /// Parses the castling field of a FEN string (`KQkq`, `-`, a subset, …).
  factory CastlingRights.fromFen(String field) {
    if (field == '-') return none;
    if (field.isEmpty || !RegExp(r'^[KQkq]+$').hasMatch(field)) {
      throw FormatException('invalid castling field: "$field"');
    }
    return CastlingRights(
      whiteKingSide: field.contains('K'),
      whiteQueenSide: field.contains('Q'),
      blackKingSide: field.contains('k'),
      blackQueenSide: field.contains('q'),
    );
  }

  /// Serializes to the FEN castling field (`KQkq` order, or `-` when empty).
  String toFen() {
    final sb = StringBuffer();
    if (whiteKingSide) sb.write('K');
    if (whiteQueenSide) sb.write('Q');
    if (blackKingSide) sb.write('k');
    if (blackQueenSide) sb.write('q');
    return sb.isEmpty ? '-' : sb.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is CastlingRights &&
      other.whiteKingSide == whiteKingSide &&
      other.whiteQueenSide == whiteQueenSide &&
      other.blackKingSide == blackKingSide &&
      other.blackQueenSide == blackQueenSide;

  @override
  int get hashCode => Object.hash(
      whiteKingSide, whiteQueenSide, blackKingSide, blackQueenSide);
}

/// An immutable chess position: piece placement plus all state needed to
/// resume a game (side to move, castling rights, en-passant target, and the
/// halfmove/fullmove clocks).
///
/// Pure Dart — no Flutter, no Firebase. This is the foundational domain value
/// type; move generation and game-end detection build on top of it.
class Position {
  /// 64-entry board indexed by [Square.index] (`a1 == 0`); `null` is an empty
  /// square. Stored unmodifiable.
  final List<Piece?> board;
  final PieceColor turn;
  final CastlingRights castling;

  /// The en-passant *target* square (the square a pawn would move to when
  /// capturing en passant), or `null`.
  final Square? enPassant;

  /// Halfmoves since the last capture or pawn move (for the 50-move rule).
  final int halfmoveClock;

  /// The fullmove number; starts at 1 and increments after Black moves.
  final int fullmoveNumber;

  Position._({
    required this.board,
    required this.turn,
    required this.castling,
    required this.enPassant,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  });

  /// The standard starting position.
  static Position get initial => Position.fromFen(kStartingFen);

  /// The piece on [square], or `null` if empty.
  Piece? pieceAt(Square square) => board[square.index];

  /// Parses a full FEN record (6 space-separated fields).
  factory Position.fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length != 6) {
      throw FormatException('FEN must have 6 fields: "$fen"');
    }
    final board = _parsePlacement(parts[0]);

    final PieceColor turn;
    switch (parts[1]) {
      case 'w':
        turn = PieceColor.white;
      case 'b':
        turn = PieceColor.black;
      default:
        throw FormatException('invalid side to move: "${parts[1]}"');
    }

    final castling = CastlingRights.fromFen(parts[2]);

    Square? enPassant;
    if (parts[3] != '-') {
      enPassant = Square.parse(parts[3]);
    }

    final halfmove = int.tryParse(parts[4]);
    final fullmove = int.tryParse(parts[5]);
    if (halfmove == null || halfmove < 0) {
      throw FormatException('invalid halfmove clock: "${parts[4]}"');
    }
    if (fullmove == null || fullmove < 1) {
      throw FormatException('invalid fullmove number: "${parts[5]}"');
    }

    return Position._(
      board: List.unmodifiable(board),
      turn: turn,
      castling: castling,
      enPassant: enPassant,
      halfmoveClock: halfmove,
      fullmoveNumber: fullmove,
    );
  }

  /// Parses the piece-placement field (rank 8 first, down to rank 1).
  static List<Piece?> _parsePlacement(String placement) {
    final ranks = placement.split('/');
    if (ranks.length != 8) {
      throw FormatException('placement must have 8 ranks: "$placement"');
    }
    final board = List<Piece?>.filled(64, null);
    for (var r = 0; r < 8; r++) {
      final rank = 7 - r; // FEN lists rank 8 first
      var file = 0;
      for (final ch in ranks[r].split('')) {
        final empties = int.tryParse(ch);
        if (empties != null) {
          file += empties;
        } else {
          final piece = Piece.fromFenChar(ch);
          if (piece == null) {
            throw FormatException('invalid piece char: "$ch"');
          }
          if (file > 7) {
            throw FormatException('rank overflow in placement: "${ranks[r]}"');
          }
          board[rank * 8 + file] = piece;
          file++;
        }
      }
      if (file != 8) {
        throw FormatException('rank "${ranks[r]}" does not fill 8 files');
      }
    }
    return board;
  }

  /// Serializes back to a canonical 6-field FEN string.
  String toFen() {
    final sb = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final piece = board[rank * 8 + file];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            sb.write(empty);
            empty = 0;
          }
          sb.write(piece.fenChar);
        }
      }
      if (empty > 0) sb.write(empty);
      if (rank > 0) sb.write('/');
    }
    sb.write(turn == PieceColor.white ? ' w ' : ' b ');
    sb.write(castling.toFen());
    sb.write(' ');
    sb.write(enPassant?.name ?? '-');
    sb.write(' $halfmoveClock $fullmoveNumber');
    return sb.toString();
  }

  @override
  String toString() => 'Position(${toFen()})';
}
