import '../engine/engine.dart';

/// How a game ended (or that it is still ongoing).
enum GameTermination {
  ongoing,
  checkmate,
  stalemate,
  fiftyMoveRule,
  threefoldRepetition,
  insufficientMaterial,
}

/// The result of a game: its [termination] and the [winner] (`null` for a draw
/// or an ongoing game).
class GameOutcome {
  final GameTermination termination;
  final PieceColor? winner;

  const GameOutcome._(this.termination, this.winner);

  static const ongoing = GameOutcome._(GameTermination.ongoing, null);

  const GameOutcome.checkmate(PieceColor this.winner)
      : termination = GameTermination.checkmate;

  const GameOutcome._draw(this.termination) : winner = null;

  bool get isOver => termination != GameTermination.ongoing;
  bool get isDraw => isOver && winner == null;

  /// The PGN result token: `1-0`, `0-1`, `1/2-1/2`, or `*` while ongoing.
  String get pgnResult {
    if (!isOver) return '*';
    if (winner == PieceColor.white) return '1-0';
    if (winner == PieceColor.black) return '0-1';
    return '1/2-1/2';
  }
}

/// A chess game: an initial position plus the sequence of moves played, with
/// SAN history, undo, outcome detection (incl. threefold repetition), and PGN
/// import/export. Pure Dart — built entirely on `lib/engine`.
class Game {
  /// The position the game started from (usually the standard start).
  final Position initialPosition;

  /// PGN header tags (e.g. `White`, `Black`, `Event`). Mutable.
  final Map<String, String> tags;

  // positions[0] == initialPosition; positions.last == current position.
  final List<Position> _positions;
  final List<Move> _moves = [];
  final List<String> _sans = [];

  Game._(this.initialPosition, this.tags)
      : _positions = [initialPosition];

  /// A new game from the standard starting position.
  factory Game.initial() => Game._(Position.initial, {});

  /// A new game starting from [fen].
  factory Game.fromFen(String fen) => Game._(Position.fromFen(fen), {});

  /// The current position (after all moves played so far).
  Position get position => _positions.last;

  /// The number of plies (half-moves) played.
  int get ply => _moves.length;

  /// The moves played, in order.
  List<Move> get moveHistory => List.unmodifiable(_moves);

  /// The moves played, in SAN, in order.
  List<String> get sanHistory => List.unmodifiable(_sans);

  /// The legal moves available in the current position.
  List<Move> get legalMoves => generateLegalMoves(position);

  /// Whether the side to move is in check.
  bool get isInCheck => isCheck(position);

  /// Plays [move] (which must be legal in the current position), recording its
  /// SAN and advancing the position.
  void play(Move move) {
    assert(
      legalMoves.contains(move),
      '$move is not legal in ${position.toFen()}',
    );
    _sans.add(sanOf(position, move)); // SAN is relative to the pre-move position
    _moves.add(move);
    _positions.add(position.applyMove(move));
  }

  /// Parses [san] in the current position and plays it.
  void playSan(String san) => play(sanToMove(position, san));

  /// Takes back the last move, returning it (or `null` if at the start).
  Move? undo() {
    if (_moves.isEmpty) return null;
    _positions.removeLast();
    _sans.removeLast();
    return _moves.removeLast();
  }

  /// The current outcome of the game.
  GameOutcome get outcome {
    final pos = position;
    if (generateLegalMoves(pos).isEmpty) {
      return isCheck(pos)
          ? GameOutcome.checkmate(pos.turn.opposite)
          : const GameOutcome._draw(GameTermination.stalemate);
    }
    if (hasInsufficientMaterial(pos)) {
      return const GameOutcome._draw(GameTermination.insufficientMaterial);
    }
    if (isFiftyMoveRule(pos)) {
      return const GameOutcome._draw(GameTermination.fiftyMoveRule);
    }
    if (_isThreefoldRepetition()) {
      return const GameOutcome._draw(GameTermination.threefoldRepetition);
    }
    return GameOutcome.ongoing;
  }

  /// A position has occurred three times (same placement, side to move,
  /// castling rights, and en-passant field).
  bool _isThreefoldRepetition() {
    final counts = <String, int>{};
    for (final pos in _positions) {
      final key = _repetitionKey(pos);
      final count = (counts[key] ?? 0) + 1;
      counts[key] = count;
      if (count >= 3) return true;
    }
    return false;
  }

  static String _repetitionKey(Position pos) {
    // FEN fields 1–4 (placement, side, castling, en passant) — clocks excluded.
    final fields = pos.toFen().split(' ');
    return '${fields[0]} ${fields[1]} ${fields[2]} ${fields[3]}';
  }

  // --- PGN ---

  static const _sevenTagRoster = ['Event', 'Site', 'Date', 'Round', 'White', 'Black'];

  /// Serializes the game to a PGN string (Seven Tag Roster + movetext + result;
  /// adds `FEN`/`SetUp` tags when the game did not start from the standard
  /// position). Any extra [tags] on this game are preserved.
  String toPgn() {
    final out = StringBuffer();
    final fromStart = initialPosition.toFen() == kStartingFen;

    for (final key in _sevenTagRoster) {
      final fallback = key == 'Date' ? '????.??.??' : '?';
      out.writeln('[$key "${tags[key] ?? fallback}"]');
    }
    out.writeln('[Result "${outcome.pgnResult}"]');
    if (!fromStart) {
      out.writeln('[FEN "${initialPosition.toFen()}"]');
      out.writeln('[SetUp "1"]');
    }
    // Any non-standard tags the caller set.
    for (final entry in tags.entries) {
      if (_sevenTagRoster.contains(entry.key) ||
          entry.key == 'Result' ||
          entry.key == 'FEN' ||
          entry.key == 'SetUp') {
        continue;
      }
      out.writeln('[${entry.key} "${entry.value}"]');
    }
    out.writeln();

    final tokens = <String>[];
    for (var i = 0; i < _sans.length; i++) {
      final movingPos = _positions[i];
      if (movingPos.turn == PieceColor.white) {
        tokens.add('${movingPos.fullmoveNumber}.');
      } else if (i == 0) {
        tokens.add('${movingPos.fullmoveNumber}...');
      }
      tokens.add(_sans[i]);
    }
    tokens.add(outcome.pgnResult);
    out.write(tokens.join(' '));
    return out.toString();
  }

  /// Reconstructs a game from [pgn] (tags, move numbers, comments `{...}`,
  /// variations `(...)`, and NAGs `$n` are handled; the mainline is replayed).
  factory Game.fromPgn(String pgn) {
    final tagPattern = RegExp(r'^\[(\w+)\s+"((?:[^"\\]|\\.)*)"\]\s*$');
    final headers = <String, String>{};
    final moveText = StringBuffer();

    for (final line in pgn.split('\n')) {
      final match = tagPattern.firstMatch(line.trim());
      if (match != null) {
        headers[match.group(1)!] = match.group(2)!;
      } else {
        moveText.writeln(line);
      }
    }

    final game = Game.fromFen(headers['FEN'] ?? kStartingFen);
    game.tags.addAll(headers);

    var text = moveText.toString();
    text = text.replaceAll(RegExp(r'\{[^}]*\}'), ' '); // comments
    while (text.contains('(')) {
      final stripped = text.replaceAll(RegExp(r'\([^()]*\)'), ' '); // variations
      if (stripped == text) break; // unbalanced — stop
      text = stripped;
    }
    text = text.replaceAll(RegExp(r'\$\d+'), ' '); // NAGs

    for (var token in text.split(RegExp(r'\s+'))) {
      token = token.trim();
      if (token.isEmpty) continue;
      if (token == '1-0' ||
          token == '0-1' ||
          token == '1/2-1/2' ||
          token == '*') {
        break;
      }
      token = token.replaceFirst(RegExp(r'^\d+\.(\.\.)?'), ''); // move number
      if (token.isEmpty) continue;
      game.playSan(token);
    }
    return game;
  }
}
