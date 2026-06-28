/// The two sides in a game of chess.
enum PieceColor {
  white,
  black;

  PieceColor get opposite => this == white ? black : white;
}

/// The six piece types. Ordering is stable and used by serialization.
enum PieceRole {
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king;

  /// The lowercase letter used in FEN/UCI for this role (`p`, `n`, `b`, `r`,
  /// `q`, `k`).
  String get lowerChar => const ['p', 'n', 'b', 'r', 'q', 'k'][index];

  /// Parses a role from its (case-insensitive) FEN/UCI letter, or returns
  /// `null` if the character is not a piece letter.
  static PieceRole? fromChar(String char) {
    switch (char.toLowerCase()) {
      case 'p':
        return PieceRole.pawn;
      case 'n':
        return PieceRole.knight;
      case 'b':
        return PieceRole.bishop;
      case 'r':
        return PieceRole.rook;
      case 'q':
        return PieceRole.queen;
      case 'k':
        return PieceRole.king;
    }
    return null;
  }
}

/// An immutable (color, role) pair occupying a single square.
class Piece {
  final PieceColor color;
  final PieceRole role;

  const Piece(this.color, this.role);

  /// The FEN character: uppercase for white, lowercase for black.
  String get fenChar =>
      color == PieceColor.white ? role.lowerChar.toUpperCase() : role.lowerChar;

  /// Parses a piece from a single FEN character, or returns `null` if the
  /// character does not denote a piece.
  static Piece? fromFenChar(String char) {
    final role = PieceRole.fromChar(char);
    if (role == null) return null;
    final isWhite = char == char.toUpperCase();
    return Piece(isWhite ? PieceColor.white : PieceColor.black, role);
  }

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.role == role;

  @override
  int get hashCode => Object.hash(color, role);

  @override
  String toString() => 'Piece($fenChar)';
}
