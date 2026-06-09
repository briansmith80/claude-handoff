---
name: catchup
description: Resume work from the latest HANDOFF.md. Reads the committed handoff plus current git state and re-hydrates context so you can continue where a prior session (or another machine) left off. Use at the start of a new session, after switching machines, or after a compaction.
argument-hint: (none)
allowed-tools: Read Bash
---

# Catch Up From the Handoff

Re-hydrate from the curated handoff left by a previous session. This is a READ-ONLY
briefing: do not edit, run, commit, or push anything until the user confirms.

## Live context (collected at load time)

- Branch: !`git rev-parse --abbrev-ref HEAD`
- Sync status: !`git status -sb`
- Uncommitted changes: !`git status --porcelain`
- Last commit: !`git log -1 --oneline`

## Steps

1. **Read `HANDOFF.md` at the repo root** (use the Read tool). If it does not exist, tell
   the user and list any archived handoffs under `.handoffs/`, then stop. If the file
   contains merge-conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`), do NOT brief from it:
   tell the user the handoff is mid-conflict, identify the newer side by comparing the two
   `session_date` values, and have them resolve it (`git checkout --ours/--theirs HANDOFF.md`
   then `git add HANDOFF.md`, or re-run /handoff from the session they want to keep), then
   stop.

2. **Reconcile with git.**
   - **Staleness:** compare the `Last commit` hash recorded in the handoff's Git State
     section with the live `Last commit` above. If they differ, the code has moved since the
     handoff was written: run `git rev-list --count <handoff-hash>..HEAD` and warn
     prominently that the brief and Next Steps may be stale (if the hash is not in current
     history, say so rather than guessing a count).
   - **Branch / behind origin:** if the handoff's `branch` differs from the current branch,
     or the tree is behind origin, surface that prominently. Before suggesting a branch
     switch, check for uncommitted changes: if the tree is dirty, tell the user to commit or
     stash first (`git stash`), since `git switch` will otherwise abort. Once the tree is
     clean, suggest `git fetch && git switch <branch> && git pull` so the code matches the
     handoff.

3. **Brief the user in ~5 lines:** the objective, current status, any blockers, and the
   FIRST item from the handoff's "Next Steps".

4. **Confirm the reproduce/verify commands** in the handoff still apply, then ASK whether to
   start on the first next step (e.g. "Want me to start on step 1?"). Do NOT begin editing or
   running anything until the user confirms.
