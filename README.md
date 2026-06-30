# super_chess

Super Chess — the teaching-first chess gym.

## Features

- **Interactive board** — tap a piece to see its legal moves, then tap a
  highlighted square to play. The board shows selection, legal-target,
  last-move, and check highlights, and renders en-passant targets with a
  capture ring.
- **Local play** — play both sides on one device, with **Undo**, **Flip**
  (board orientation), and **Reset** controls.
- **Full chess rules** — legal move generation, check/checkmate, stalemate,
  fifty-move rule, threefold repetition, and insufficient-material draws,
  surfaced as a live status label above the board.
- **Tactics trainer** — a named-motif puzzle gym (open it from the board
  screen's puzzle button). A chip row lets you drill one motif (mate in 1/2,
  fork, pin, skewer, discovered attack, deflection, back-rank mate, win
  material, sacrifice) or stay on **All** to draw from every motif. It presents
  a random puzzle, labels it with the chosen (or detected) motif, validates your
  moves against the solution line, and offers **Try again** / **Skip** /
  **Next puzzle**.

Promotion currently defaults to a queen; an explicit picker is planned.

## Running

```sh
flutter pub get
flutter run
```

Run the tests with:

```sh
flutter test
```

At startup the app loads the bundled puzzle library under `assets/puzzles/`
into a cross-platform in-memory repository (`InMemoryPuzzleRepository`, no
SQLite) that backs the tactics trainer. It loads the curated CC0 Lichess set
(`puzzles.json`, ~528 puzzles), falling back to the hand-authored
`sample_puzzles.json` placeholder only if that's missing or empty. The curated
library is produced offline from the CC0 Lichess puzzle database via
`tool/curate_puzzles.dart`; see
[`assets/puzzles/README.md`](assets/puzzles/README.md) for regenerating it.

The content database (`lib/data/content`) uses Drift, whose generated code
(`*.g.dart`) is committed. After changing a table or query, regenerate it with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The Drift content DB is the persisted, scalable alternative behind the same
`PuzzleRepository` interface; `PuzzleSeeder` seeds it (once, idempotently) from
the same bundled library, but seeding is not yet wired into startup.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
