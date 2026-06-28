/// Super Chess — pure-Dart chess engine (the durable, license-clean domain
/// asset). Zero Flutter / Firebase imports.
///
/// Phase 0 build order: model + FEN (here) → legal move generation + perft →
/// SAN/PGN + draw detection → UCI client interface. See docs/ARCHITECTURE.md.
library;

export 'piece.dart';
export 'square.dart';
export 'move.dart';
export 'position.dart';
