#!/usr/bin/env bash
#
# mark-ready.sh — promote a DRAFT pull request to "ready for review" ONLY when
# its gates are green. Draft PRs cannot be merged on GitHub (any plan), so on a
# free private repo this is the enforceable gate: a PR stays unmergeable until
# this script flips it to ready, and it refuses to do so unless validation
# actually passed.
#
# Gates checked:
#   1. GitHub CI `validate` check == SUCCESS (analyze + tests + web build)
#   2. no-mistakes pipeline for the branch finished with a REAL pass —
#      outcome passed/checks-passed AND the review+test steps ran (`completed`,
#      not `skipped`; skipped steps mean the branch was already merged / never
#      truly validated).
#
# It also posts a `no-mistakes/gate` commit status to the PR (visible next to
# the merge box) so the state is obvious even though no-mistakes isn't a check.
#
# Usage:
#   scripts/mark-ready.sh <pr-number>            # require both gates
#   scripts/mark-ready.sh <pr-number> --no-nm    # CI only (skip no-mistakes)
#
set -euo pipefail

PR="${1:-}"
MODE="${2:-}"
if [[ -z "$PR" ]]; then
  echo "usage: scripts/mark-ready.sh <pr-number> [--no-nm]" >&2
  exit 2
fi

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
branch=$(gh pr view "$PR" --json headRefName -q .headRefName)
sha=$(gh pr view "$PR" --json headRefOid -q .headRefOid)
draft=$(gh pr view "$PR" --json isDraft -q .isDraft)

echo "PR #$PR  branch=$branch  draft=$draft"

post_status() { # state description
  gh api -X POST "repos/$repo/statuses/$sha" \
    -f state="$1" -f context="no-mistakes/gate" -f description="$2" >/dev/null 2>&1 || true
}

fail() {
  echo "❌ NOT promoting PR #$PR: $1" >&2
  post_status failure "$1"
  exit 1
}

# --- gate 1: GitHub CI `validate` ---
ci=$(gh pr view "$PR" --json statusCheckRollup \
  -q '.statusCheckRollup[] | select(.name=="validate") | .conclusion' 2>/dev/null | head -1)
echo "CI validate: ${ci:-<not found>}"
[[ "$ci" == "SUCCESS" ]] || fail "CI 'validate' is not green (got: ${ci:-none})"

# --- gate 2: no-mistakes ---
if [[ "$MODE" != "--no-nm" ]]; then
  current=$(git branch --show-current)
  [[ "$current" == "$branch" ]] || \
    fail "checkout '$branch' first so 'no-mistakes axi status' resolves its run (currently on '$current')"

  status=$(no-mistakes axi status 2>/dev/null || true)
  grep -Eq "branch: \"?${branch}\"?" <<<"$status" || \
    fail "no no-mistakes run for '$branch' — run the gate before promoting"
  # Never promote a failed run (terminal 'failed' or any failed step).
  grep -q "status: failed" <<<"$status" && fail "no-mistakes run failed"
  grep -q ",failed," <<<"$status" && fail "a no-mistakes step failed"
  # Require REAL validation: review+test+push+pr must have completed. Skipped
  # steps mean the branch was already merged / never validated. We key on the
  # steps (not an 'outcome:' line) because a 'checks-passed' run stays
  # status:running while its ci step keeps monitoring the PR and prints no
  # 'outcome:' line.
  for step in review test push pr; do
    grep -q "${step},completed" <<<"$status" || \
      fail "no-mistakes '${step}' not completed — not a real validation (skipped/incomplete)"
  done
  echo "no-mistakes: validated (review/test/push/pr completed)"
else
  echo "no-mistakes: SKIPPED (--no-nm)"
fi

# --- promote ---
post_status success "gates green"
gh pr ready "$PR"
echo "✅ PR #$PR is READY — gates green, safe to merge."
