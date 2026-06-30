# Super Chess

> **The teaching-first chess gym** — play locally against a full rules engine and drill a
> 528-puzzle, motif-by-motif tactics trainer. Beginner→intermediate, offline-first, ad-free.

> [!IMPORTANT]
> **Engineering workflow — automated commit → validate → merge.**
> Every change ships through a two-gate pipeline (`no-mistakes` AI review + GitHub CI),
> merged only when both are green via *draft-until-green*.
> 📄 See **[docs/AUTOMATED_MERGE_FLOW.md](docs/AUTOMATED_MERGE_FLOW.md)** — with flow diagrams.

## What it is

A cross-platform Flutter app (Android · iOS · Web) under the Ninety Nine Labs brand. The
wedge is **pedagogy, not price**: a structured, motif-based path for the adult improver,
built on a correct, offline-first foundation.

## Features

- **Interactive board** — tap-to-select, legal-move dots, and selection / last-move /
  check / en-passant highlights. Local two-side play with **Undo · Flip · Reset**.
- **Full chess rules** — legal move generation, check/checkmate, stalemate, fifty-move,
  threefold repetition, and insufficient-material draws, shown as a live status label.
- **Tactics trainer** — a named-motif puzzle gym backed by **528 curated CC0 Lichess
  puzzles**. A chip row drills one motif (mate in 1/2, fork, pin, skewer, discovered
  attack, deflection, back-rank mate, win material, sacrifice) or **All**; it validates
  your moves against the solution line with **Try again / Skip / Next**.

## Architecture

Layered + feature-first, dependencies pointing downward only:
**Presentation** (widgets) → **Application** (Riverpod) → **Domain** (pure Dart) →
**Data** (repos).

- **Pure-Dart engine** (`lib/engine`) — legal move generation (**perft-verified**),
  FEN/SAN/PGN, draw detection, and a transport-agnostic UCI interface. Zero Flutter
  imports: the durable, fully-tested core.
- **Domain** (`lib/domain`) — game model + the tactics solver, framework-free.
- **Data** (`lib/data`) — a read-only Drift **content DB** and an `InMemoryPuzzleRepository`
  (cross-platform, no SQLite on web) behind one `PuzzleRepository` interface. The CC0
  library is curated **offline and engine-validated** by `tool/curate_puzzles.dart`.
- **Stack** — Riverpod (state), Drift (persistence), go_router (planned), Firebase
  (deferred). **TDD throughout** (~124 tests).

## Running

```sh
flutter pub get
flutter run        # pick a device (Chrome for web)
flutter test
```

Drift generated code (`*.g.dart`) is committed; after changing a table/query:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Regenerating the puzzle library is documented in
[`assets/puzzles/README.md`](assets/puzzles/README.md).
