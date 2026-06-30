# Automated Commit → Validate → Merge Flow

Every change is committed on a **feature branch** and gated by **two independent
validators** before it can reach `main`:

1. **`no-mistakes`** — a local, AI-driven pipeline (code review → tests → docs → lint).
2. **CI `validate`** — GitHub Actions (`flutter analyze` + `flutter test` + `flutter build web`).

A change is mergeable **only when both are green**. Direct pushes to `main` never happen.

## Enforcement: draft-until-green

The repo is private on GitHub's free plan, so server-side branch protection isn't
available. Instead we exploit a free, native guarantee: **GitHub never lets a *draft*
PR be merged.**

- Every PR opens as a **draft** (unmergeable by default).
- A guard script, **`scripts/mark-ready.sh <pr>`**, flips it to *ready* **only if**
  CI `validate` == `SUCCESS` **and** the `no-mistakes` run actually passed
  (review + test completed, not skipped). Otherwise it refuses.
- You merge only **ready** PRs — so "ready" *means* "validated."

## End-to-end flow

```mermaid
flowchart LR
    A[Branch off main] --> B[Implement TDD]
    B --> C[Commit + open DRAFT PR]
    C --> D{Two gates}
    D --> E[no-mistakes pipeline]
    D --> F[CI validate: analyze + test + build]
    E --> G[mark-ready.sh]
    F --> G
    G -->|both green| H[PR ready]
    G -->|either red| C
    H --> I[Squash-merge to main]
```

## How `no-mistakes` works

A staged pipeline; each stage can auto-fix and re-run. The **review** stage parks at a
gate where findings are resolved (`fix` / `approve` / escalate to a human), then the
fixed commits flow through the rest and land on the PR.

```mermaid
flowchart TD
    intent[1. intent: what the change is for] --> rebase[2. rebase onto main]
    rebase --> review[3. review: AI code review]
    review --> gate{findings?}
    gate -->|fix| review
    gate -->|approve / none| test
    test[4. test: run suite] --> document[5. document: update docs]
    document --> lint[6. lint: format + analyze]
    lint --> push[7. push: commit fixes to branch]
    push --> pr[8. pr: open / update PR]
    pr --> ci[9. ci: watch GitHub CI]
    ci --> done{outcome}
    done -->|checks-passed| ready([PR ready to merge])
    done -->|failed| retry([fix + re-drive])
```

**Outcomes:** `checks-passed` = validated + CI green (ready to merge) · `failed` =
re-drive after addressing the cause.

## Why two gates

`no-mistakes` is a deep **code-review + auto-fix** layer (catches logic/UX bugs, dead
code, races); CI `validate` is the **fast, reproducible** check on a clean machine and
the **visible, enforceable** signal on the PR. The guard requires both, so a PR is only
mergeable after a real review *and* a clean build — fully hands-off once driven to
`checks-passed`.
