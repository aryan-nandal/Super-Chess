# Bundled puzzle assets

- **`sample_puzzles.json`** — a tiny, hand-authored set that currently doubles
  as the **placeholder library** the app ships (loaded at startup, in dev, and
  in tests) until the curated CC0 set is bundled. Every puzzle is
  engine-verified by `test/assets/sample_puzzles_test.dart` (legal solution
  line; mate-tagged puzzles really checkmate). Original to this repo, released
  CC0.

## Regenerating the real library (CC0)

The production library is curated offline from the **Lichess open puzzle
database** (CC0, ~6M puzzles): <https://database.lichess.org/#puzzles>.

```sh
# 1. download lichess_db_puzzle.csv.zst, then decompress to lichess_db_puzzle.csv
# 2. curate a stratified subset (theme × rating, quality-filtered):
dart run tool/curate_puzzles.dart lichess_db_puzzle.csv \
    assets/puzzles/puzzles.json  50 100 80
#   args: <input.csv> <output.json> [perBucket] [minNbPlays] [minPopularity]
```

Bundle the curated `puzzles.json` and load it from `_loadPuzzleRepository` in
`lib/main.dart` (replacing the `sample_puzzles.json` placeholder) to ship it.
The app loads the bundled JSON into an in-memory repository at startup;
`PuzzleSeeder` can alternatively seed it (idempotently) into the read-only Drift
content DB, though that path is not yet wired into startup. The Lichess data is
CC0, so no attribution is required, but we credit it anyway.
