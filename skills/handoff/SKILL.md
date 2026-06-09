---
name: handoff
description: Summarize the current session into a curated, git-syncable HANDOFF.md so a fresh session (or a different machine, work <-> home) can resume exactly where this left off. Use when context is nearly full, at end of day, or before switching machines.
argument-hint: [optional title/focus for the handoff, or "draft" to write without pushing]
allowed-tools: Read Write Edit Bash
---

# Prepare a Session Handoff

Write a handoff so a FRESH agent, possibly on a DIFFERENT machine with no access to this
chat, can resume fast. Optimize for: zero prior-chat access, reaching a reproducing state
quickly, and never re-litigating decisions that were already settled in this session.

Optional input from the user: $ARGUMENTS

## Live context (collected at load time)

- Repo root: !`git rev-parse --show-toplevel`
- Branch: !`git rev-parse --abbrev-ref HEAD`
- Sync status (branch + ahead/behind): !`git status -sb`
- Last commit: !`git log -1 --oneline`
- Uncommitted changes: !`git status --porcelain`
- Recent commits: !`git log --oneline -10`
- Operator (git user): !`git config user.name`
- Remote URL (for the owner/repo slug): !`git remote get-url origin`
- Default base branch: !`git symbolic-ref --short refs/remotes/origin/HEAD`

## Steps

0. **Precondition: confirm this is a git repo.** If the `Repo root` line above failed
   (its output contains `fatal: not a git repository`), this directory is not under version
   control. Do NOT run git commands and do NOT trust the other git values above. Write
   `HANDOFF.md` to the current working directory with front-matter `repo`/`branch`/`base`
   set to `n/a (not a git repo)` and Git State `Not under version control`, skip the archive
   (step 3) and commit/push (step 6), and tell the user the handoff is local-only and will
   not cross machines until they `git init`, add a remote, and commit. Then stop.

1. **Synthesize from THIS conversation, do not dump the transcript.** Distill: the
   objective, what changed, decisions + rationale, what is verified vs assumed, blockers,
   and the ordered next steps. Take file paths and git facts from the live context above and
   keep paths repo-relative. If `$ARGUMENTS` is non-empty (and is not the bare word `draft`/
   `--no-push`), use it as the one-line title in the H1 (`# Handoff: <title>`) and bias the
   synthesis toward that focus; otherwise derive a concise title from the session's work.
   If a project memory file exists (`~/.claude/projects/<project>/memory/MEMORY.md`), pull
   only the salient, still-true bits into "Context & Gotchas" now (skip anything stale) so
   that folded-in content is covered by the security checks below.

2. **SECURITY GATE (do this before writing).** This handoff may be committed to a public
   repo, so treat it as world-readable. NEVER write secret values (API keys, tokens,
   connection strings, passwords, PII, URLs with embedded tokens). Reference env-var NAMES
   only and point at `.env.example`. Apply this to the MEMORY.md content folded in at step 1
   as well, not just the session synthesis.

3. **Archive any existing handoff.** Check whether `HANDOFF.md` already exists at the repo
   root. Before touching it, make sure the repo is not mid-merge and the file has no conflict
   markers (`<<<<<<<`, `=======`, `>>>>>>>`): if it does, STOP and tell the user to resolve
   the conflict first (a clean overwrite here would silently discard the other machine's
   handoff). Otherwise move the existing file into `.handoffs/` named `<UTC>-prev.md`, where
   `<UTC>` is `YYYYMMDDTHHMMSSZ` (second precision, e.g. `20260609T143007Z-prev.md`); if a
   file with that exact name already exists, append `-2`, `-3`, ... so an archive is never
   overwritten. Create `.handoffs/` if needed. If the old file is tracked by git, use
   `git mv` (it errors rather than clobbering) to preserve history; otherwise use a
   non-clobbering move (`Move-Item` without `-Force` on Windows, `mv -n` on POSIX). Use the
   shell that matches the current OS (PowerShell on Windows).

4. **Write a fresh `HANDOFF.md` at the repo root** using the template at
   `${CLAUDE_SKILL_DIR}/HANDOFF.template.md`. Fill EVERY section. Source the front-matter
   from the live context: `operator` from `git config user.name` (fall back to the git
   email); `repo` by parsing the owner/repo slug from the remote URL (strip the host and any
   `.git` suffix; if there is no remote, write `local-only`); `base` from the default base
   branch line, stripping any leading `origin/` (so `origin/main` becomes `main`); if it is
   unset/empty, infer the repo's default branch or ask, rather than blindly writing `main`;
   `handoff_reason` by choosing the enum value that matches why this
   handoff is happening (context-full / end-of-day / switching-machines / escalation /
   parking), inferred from `$ARGUMENTS` and the trigger. If a section is genuinely empty,
   write "None"; never leave a placeholder or an unfilled TODO.

5. **Scan the written file for secrets before committing.** Run a quick mechanical scan over
   `HANDOFF.md` with the Bash tool (the file exists now) for high-signal secret shapes, e.g.
   on Windows:
   `Select-String -Path HANDOFF.md -Pattern '-----BEGIN','AKIA[0-9A-Z]{16}','xox[baprs]-','ghp_[0-9A-Za-z]{36}','://[^/\s:]+:[^/\s@]+@','(?i)(authorization|bearer)\s+[A-Za-z0-9._-]{20,}'`
   (POSIX: the same patterns via `grep -nEi`). If anything matches, do NOT push: show the
   matching lines and ask the user to confirm or redact. This is a backstop for the step-2
   gate, not a replacement for it.

6. **Commit and push automatically.** Syncing is the expected end state of this skill, so do
   it without asking. The step-2 gate and step-5 scan are what make this safe: if you have
   ANY doubt that the handoff is secret-free, stop and flag it instead of pushing.
   - **Draft escape hatch:** if `$ARGUMENTS` is, or contains, the bare word `draft` or
     `--no-push`, write/archive `HANDOFF.md` and STOP here. Print the exact `git add` /
     `git commit` / `git push` commands for the user to run manually.
   - **Detached HEAD:** if `git status -sb` shows `## HEAD (no branch)` (the branch resolved
     to the literal `HEAD`), do NOT record `HEAD` as the branch and do NOT push, the commit
     would be unreachable. Tell the user to create or switch to a branch
     (`git switch -c <name>`) and re-run. Writing the file is still fine.
   - **Stage and commit:** first run `git check-ignore HANDOFF.md .handoffs/`; if the
     project `.gitignore` matches either path, do NOT proceed silently, tell the user the
     handoff will not sync and either un-ignore it or stage with `-f`. Then
     `git add HANDOFF.md .handoffs/` (only include `.handoffs/` if it exists) and
     `git commit -m "chore(handoff): <branch> - <short status>"`. If `git add` or
     `git commit` exits non-zero (including "nothing to commit"), stop and surface the exact
     error rather than reporting success.
   - **No remote:** if no remote is configured, commit locally and report it as success:
     "Committed locally; no remote is configured, so this handoff stays on this machine
     (fine for same-machine resume). Add a remote and push to cross machines." Do not treat
     this as a failure.
   - **Push:** `git push` (use `git push -u origin <branch>` if the branch has no upstream).
     If the push is REJECTED as non-fast-forward (the other machine pushed first), do NOT
     `git push --force` (it would destroy the other machine's handoff and any other commits).
     Instead: tell the user, run `git pull --rebase`, and if `HANDOFF.md` conflicts (expected,
     both machines rewrote it) keep YOUR newer version: during a `git pull --rebase` your
     local commit is replayed on top, so your `HANDOFF.md` is `theirs` (run
     `git checkout --theirs HANDOFF.md`), then `git add HANDOFF.md` and `git rebase --continue`,
     then `git push`. If any file OTHER than `HANDOFF.md` conflicts, stop and hand it to the
     user. For any other push failure (auth, etc.), surface the exact error and suggested
     fix; do NOT silently leave it uncommitted.
   - **Report:** print the branch + remote pushed to (e.g. "pushed to origin/<branch>", so a
     wrong-branch push is obvious), whether a prior handoff was archived and where, the
     `HANDOFF.md` path, the commit hash, a 3-line summary, and a "Review: open HANDOFF.md or
     run git show <hash>" line.
