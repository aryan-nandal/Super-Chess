# Bundled puzzle assets

- **`puzzles.json`** — the **curated CC0 Lichess library** the app ships (~528
  puzzles), beginner→intermediate (rating 700–1800), stratified across ten named
  motifs (mateIn1/2, fork, pin, skewer, discovered attack, hanging piece,
  deflection, back-rank mate, sacrifice). Engine-verified by
  `test/assets/curated_puzzles_test.dart` (every solution line legal in our
  engine; mate puzzles really checkmate). Loaded at startup by
  `_loadPuzzleRepository` in `lib/main.dart`.
- **`sample_puzzles.json`** — a tiny hand-authored set for dev/tests and as a
  fallback if `puzzles.json` is missing/empty. Original to this repo, CC0.

## Regenerating the library (CC0)

Curated offline from the **Lichess open puzzle database** (CC0, ~6M puzzles):
<https://database.lichess.org/#puzzles>.

```sh
# 1. download lichess_db_puzzle.csv.zst, decompress to lichess_db_puzzle.csv
#    (or stream the first N rows: curl -s <url> | zstd -dc | head -n 400000 > sample.csv)
# 2. curate a stratified, quality-filtered, engine-validated subset:
dart run tool/curate_puzzles.dart sample.csv assets/puzzles/puzzles.json \
    --per-bucket=9 --min-plays=150 --min-popularity=85 \
    --min-rating=700 --max-rating=1800 \
    --themes=mateIn1,mateIn2,fork,pin,skewer,discoveredAttack,hangingPiece,deflection,backRankMate,sacrifice
```

The tool keeps the most-played puzzles per `motif × rating band`, restricts the
stored tags to the motif allowlist, and **drops any puzzle our own engine can't
replay** (so the bundle is guaranteed playable). The Lichess data is CC0 — no
attribution required, but we credit it anyway.

> The app loads `puzzles.json` into an in-memory repository at startup.
> `PuzzleSeeder` can alternatively seed it (idempotently) into the read-only
> Drift content DB; that path is not yet wired into startup.
