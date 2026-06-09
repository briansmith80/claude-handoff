---
name: catchup
description: Resume work from the latest HANDOFF.md. Reads the committed handoff plus current git state and re-hydrates context so you can continue where a prior session — or another machine — left off. Use at the start of a new session, after switching machines, or after a compaction.
argument-hint: (none)
allowed-tools: Read Bash
---

# Catch Up From the Handoff

Re-hydrate from the curated handoff left by a previous session.

## Live context (collected at load time)

- Branch: !`git rev-parse --abbrev-ref HEAD`
- Sync status: !`git status -sb`
- Uncommitted changes: !`git status --porcelain`
- Last commit: !`git log -1 --oneline`

## Steps

1. **Read `HANDOFF.md` at the repo root** (use the Read tool). If it does not exist, tell
   the user and list any archived handoffs under `.handoffs/`, then stop.

2. **Reconcile with git.** If the handoff's `branch` differs from the current branch, or the
   working tree is behind origin, surface that prominently and suggest:
   `git fetch && git switch <branch> && git pull` (so the code matches the handoff). Flag any
   uncommitted local changes that might conflict with what the handoff describes.

3. **Brief the user in ~5 lines:** the objective, current status, any blockers, and the FIRST
   item from the handoff's "Next Steps".

4. **Confirm the reproduce/verify commands** in the handoff still apply, then offer to start
   on the first next step.
