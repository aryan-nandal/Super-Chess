import 'piece.dart';
import 'square.dart';

/// A move expressed in long algebraic / UCI terms: an origin square, a
/// destination square, and an optional promotion role.
///
/// This is a *coordinate* move (the form used by UCI and the Lichess puzzle
/// dataset). SAN (`Nf3`, `O-O`, …) is a separate, position-dependent encoding
/// handled by the move-generation layer.
class Move {
  final Square from;
  final Square to;

  /// The promotion target role (only [PieceRole.knight], `bishop`, `rook` or
  /// `queen`), or `null` for a non-promotion move.
  final PieceRole? promotion;

  const Move(this.from, this.to, {this.promotion});

  /// Parses a UCI string such as `e2e4` or `e7e8q`.
  factory Move.uci(String uci) {
    if (uci.length != 4 && uci.length != 5) {
      throw FormatException('invalid UCI move: "$uci"');
    }
    final from = Square.parse(uci.substring(0, 2));
    final to = Square.parse(uci.substring(2, 4));
    PieceRole? promotion;
    if (uci.length == 5) {
      promotion = PieceRole.fromChar(uci[4]);
      if (promotion == null ||
          promotion == PieceRole.pawn ||
          promotion == PieceRole.king) {
        throw FormatException('invalid promotion in UCI move: "$uci"');
      }
    }
    return Move(from, to, promotion: promotion);
  }

  /// The UCI string form, e.g. `e2e4` or `e7e8q`.
  String get uci =>
      '${from.name}${to.name}${promotion != null ? promotion!.lowerChar : ''}';

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => 'Move($uci)';
}
