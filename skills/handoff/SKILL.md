---
name: handoff
description: Summarize the current session into a curated, git-syncable HANDOFF.md so a fresh session — or a different machine (work <-> home) — can resume exactly where this left off. Use when context is nearly full, at end of day, or before switching machines.
argument-hint: [optional focus or title for the handoff]
allowed-tools: Read Write Edit Bash
---

# Prepare a Session Handoff

Write a handoff so a FRESH agent — possibly on a DIFFERENT machine with no access to
this chat — can resume fast. Optimize for: zero prior-chat access, reaching a reproducing
state quickly, and never re-litigating decisions that were already settled in this session.

Optional focus from the user: $ARGUMENTS

## Live context (collected at load time)

- Repo root: !`git rev-parse --show-toplevel`
- Branch: !`git rev-parse --abbrev-ref HEAD`
- Sync status (branch + ahead/behind): !`git status -sb`
- Last commit: !`git log -1 --oneline`
- Uncommitted changes: !`git status --porcelain`
- Recent commits: !`git log --oneline -10`

## Steps

1. **Synthesize from THIS conversation — do not dump the transcript.** Distill: the
   objective, what changed, decisions + rationale, what is verified vs assumed, blockers,
   and the ordered next steps. Take file paths and git facts from the live context above
   and keep paths repo-relative.

2. **SECURITY GATE (do this before writing).** This handoff may be committed to a public
   repo — treat it as world-readable. NEVER write secret values (API keys, tokens,
   connection strings, passwords, PII, URLs with embedded tokens). Reference env-var
   NAMES only and point at `.env.example`.

3. **Archive any existing handoff.** Check whether `HANDOFF.md` already exists at the repo
   root (use your tools). If it does, move it into `.handoffs/` named
   `<UTC-timestamp>-prev.md` (e.g. `2026-06-09T1430-prev.md`) before writing the new one;
   create `.handoffs/` if needed. If the old file is tracked by git, use `git mv` so its
   history is preserved. Use the shell that matches the current OS (PowerShell on Windows).

4. **Write a fresh `HANDOFF.md` at the repo root** using the template at
   `${CLAUDE_SKILL_DIR}/HANDOFF.template.md`. Fill EVERY section, replacing the front-matter
   values with the live context above. If a section is genuinely empty, write "None" — never
   leave a placeholder or an unfilled TODO.

5. **Optionally fold in machine-local memory.** If a project memory file exists
   (`~/.claude/projects/<project>/memory/MEMORY.md`), pull only the salient, still-true bits
   into "Context & Gotchas" so those notes also cross machines. Skip anything stale.

6. **Report & offer to sync.** Print the path written and a 3-line summary. Then ask:
   "Commit and push this handoff on branch `<branch>`? (recommended so it reaches your other
   machine)". Only if the user agrees:
   - `git add HANDOFF.md .handoffs/`
   - `git commit -m "chore(handoff): <branch> — <short status>"`
   - `git push`
   NEVER commit or push without explicit confirmation.
