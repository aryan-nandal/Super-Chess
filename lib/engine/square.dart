/// A square on the board, stored as a `0..63` index where `a1 == 0` and
/// `h8 == 63` (i.e. `index = rank * 8 + file`, files `a..h` = `0..7`, ranks
/// `1..8` = `0..7`).
///
/// Immutable value type with structural equality.
class Square {
  /// The `0..63` board index.
  final int index;

  const Square(this.index)
      : assert(index >= 0 && index < 64, 'square index out of range');

  /// Builds a square from a zero-based [file] (`a=0..h=7`) and zero-based
  /// [rank] (`rank 1 = 0 .. rank 8 = 7`).
  factory Square.at({required int file, required int rank}) {
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('file/rank out of range: $file,$rank');
    }
    return Square(rank * 8 + file);
  }

  /// Parses an algebraic name such as `e4`. Throws [FormatException] for
  /// anything that is not exactly a file letter `a..h` followed by a rank
  /// digit `1..8`.
  factory Square.parse(String name) {
    if (name.length != 2) {
      throw FormatException('invalid square: "$name"');
    }
    final file = name.codeUnitAt(0) - 0x61; // 'a'
    final rank = name.codeUnitAt(1) - 0x31; // '1'
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('invalid square: "$name"');
    }
    return Square(rank * 8 + file);
  }

  /// Zero-based file, `a=0 .. h=7`.
  int get file => index % 8;

  /// Zero-based rank, `rank 1 = 0 .. rank 8 = 7`.
  int get rank => index ~/ 8;

  /// Algebraic name, e.g. `e4`.
  String get name =>
      '${String.fromCharCode(0x61 + file)}${String.fromCharCode(0x31 + rank)}';

  @override
  bool operator ==(Object other) => other is Square && other.index == index;

  @override
  int get hashCode => index;

  @override
  String toString() => name;
}
