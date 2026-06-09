---
session_date: <ISO-8601 UTC, e.g. 2026-06-09T14:30:00Z>
author: claude-code
operator: <human, e.g. brian.smith>
repo: <owner/repo>
branch: <work branch>
base: <merge target, e.g. main>
status: <in-progress | blocked | ready-for-review | done>
handoff_reason: <context-full | end-of-day | switching-machines | escalation | parking>
---

# Handoff: <one-line title of the work>

## TL;DR
> 2-3 sentences: what this is, where it stands, and the single most important next action.
> If the reader stops here, they should still be unblocked.

## Objective / Goal
> The outcome we're driving toward and the definition of done. Link the issue/spec.
> In user/business terms, not implementation terms.

## Current Status
> What works, what's half-built, what's verified vs assumed. Be honest about confidence
> ("passes locally, not in CI").

## What Changed This Session
> Bullet list of concrete changes (behavioral, not line-by-line). Past tense. The "diff in English".

## Key Decisions & Rationale
> Each: what we chose, what we rejected, and WHY. Prevents re-opening settled questions.

## Files Touched
| Path (repo-relative) | Change | Why it matters |
|------|--------|----------------|
| `path/to/file` | NEW/MODIFIED/DELETED | one line; where to start reading |

## Commands & Environment to Reproduce
> Copy-pasteable install/build/run/test from a clean clone. Note runtime versions and
> OS gotchas. Required env by NAME ONLY (never values), see `.env.example`.

## How to Verify / Test
> The specific check that proves correctness. "Done = X observable result."

## Open Questions / Blockers
> Tag each: [BLOCKER] hard-stop, [QUESTION] needs answer, [RISK] might bite later.
> Name who/what each waits on.

## Next Steps (ordered, actionable)
> 1. [ ] Front-load the unblocking step. Each is a concrete action, not a theme.
> 2. [ ] ...

## Git State
> - Branch: `<branch>` (pushed: yes/no, up to date with origin: yes/no)
> - Last commit: `<hash short message>`
> - Uncommitted: NONE, or list them and say where (stash ref / committed on branch / patch)
> - To get current state (commit or stash local changes first): `git fetch && git switch <branch> && git pull`

## Context & Gotchas
> Non-obvious traps: flaky tests, deceptive names, "looks wrong but intentional",
> load-bearing magic numbers, slow steps. One bullet each.

## Reference Links
> Issue/PR URLs, design docs, prior handoffs. Links, not pasted content.
