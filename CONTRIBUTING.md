# Contributing — merge workflow

This repo is **private on GitHub's free plan**, where branch protection / rulesets
are unavailable, so GitHub cannot hard-block the merge button. Instead we use a
**draft-until-green** convention, which *is* enforceable: **GitHub does not allow
draft PRs to be merged on any plan.**

## The rule

> A PR stays a **draft** (unmergeable) until its gates are green. It only becomes
> **ready** — and therefore mergeable — through `scripts/mark-ready.sh`, which
> refuses unless validation actually passed.

So the safe state is the default: an ungated PR is a draft and *cannot* be merged.

## Flow

1. **Open every PR as a draft:**
   ```sh
   gh pr create --draft --base main --head <branch> --title "…" --body "…"
   ```
2. **Let the gates run:**
   - **CI `validate`** (GitHub Actions): `flutter analyze` + `flutter test` +
     `flutter build web`. Visible in the PR's **Checks** tab.
   - **`no-mistakes`** (local pipeline): drive it and wait for
     `outcome: checks-passed`. It is **not** a GitHub check — watch it with
     `no-mistakes axi status` (a real pass shows `review`/`test` as `completed`,
     not `skipped`).
3. **Promote only when both are green:**
   ```sh
   scripts/mark-ready.sh <pr-number>          # requires CI + no-mistakes
   scripts/mark-ready.sh <pr-number> --no-nm  # CI only, when no-mistakes is N/A
   ```
   The script verifies the CI `validate` check is `SUCCESS` and the
   no-mistakes run for the branch really passed, posts a `no-mistakes/gate`
   commit status on the PR, then flips it to **ready**. If a gate isn't green it
   refuses and posts a `failure` status.
4. **Merge** the now-ready PR.

## Why this exists

PRs #2 and #4 were merged before their validation finished, shipping the
un-validated pre-fix state to `main`. Drafts-can't-be-merged closes that gap
without paying for GitHub Pro.

> Want a true server-side hard gate (the merge button physically disabled until
> checks pass)? That needs **GitHub Pro** (~$4/mo) or a **public** repo, after
> which classic branch protection can require the `validate` check directly.
