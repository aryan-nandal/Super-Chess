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

The content database (`lib/data/content`) uses Drift, whose generated code
(`*.g.dart`) is committed. After changing a table or query, regenerate it with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
