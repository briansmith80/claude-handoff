<div align="center">

# claude-handoff

**Cross-session, cross-machine context handoffs for [Claude Code](https://code.claude.com).**

[![Version](https://img.shields.io/github/v/tag/briansmith80/claude-handoff?label=version&sort=semver&color=blue)](https://github.com/briansmith80/claude-handoff/blob/main/CHANGELOG.md)
[![License: MIT](https://img.shields.io/github/license/briansmith80/claude-handoff?color=green)](LICENSE)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-555)
[![Made for Claude Code](https://img.shields.io/badge/made%20for-Claude%20Code-d97757)](https://code.claude.com)

*Hand a fresh session everything it needs to continue, on this machine or another.*

</div>

---

`claude-handoff` lets a fresh agent pick up exactly where the last session stopped, *without*
access to the original chat. It solves two related problems:

- **Cross-session (same machine).** Context fills up, you `/compact`, or you just start a new
  session the next morning, and the thread of *why* you made each decision is gone or buried.
  `--resume` replays the entire noisy transcript; `/compact` is lossy and you don't control what
  it keeps. A curated `HANDOFF.md` is a deliberate, high-signal resume point you actually choose.
- **Cross-machine.** Claude Code's built-in continuity (`--resume`, `/compact`, automatic memory)
  is all **machine-local**: it lives in `~/.claude` on one computer and can't carry your
  in-progress work from, say, a work desktop to a home laptop.

The fix for both is the same: a small, git-syncable workflow that distills a session into a
curated handoff note, so any later session, same machine or a different one, resumes fast.

**Contents:** [How it works](#how-it-works) · [Repository layout](#repository-layout) ·
[Install](#install) · [Updating](#updating) · [Uninstall](#uninstall) · [Usage](#usage) ·
[Manual hook setup](#manual-hook-setup) · [Troubleshooting](#troubleshooting) ·
[Notes & conventions](#notes--conventions) · [Changelog](#changelog) · [License](#license)

---

## How it works

The core idea: separate the **tooling** from the **handoff notes**.

- The **tooling** (two skills + one hook) is installed into `~/.claude` on every machine.
  Clone this repo anywhere, run the installer, and the workflow is identical everywhere.
- The **handoff note** (`HANDOFF.md`) is written to the root of *your project's* repo and
  committed there. Because it rides in the project repo, the notes and the exact code they
  describe travel together: pull on another machine and both arrive in sync.

```
┌─────────────── Machine A (work) ───────────────┐
│  Session running low on context / end of day   │
│  → /handoff  →  writes HANDOFF.md in your repo  │
│             →  commits + pushes automatically   │
└─────────────────────────────────────────────────┘
                       │  git
                       ▼
┌─────────────── Machine B (home) ───────────────┐
│  git pull                                       │
│  SessionStart hook spots HANDOFF.md, nudges you │
│  → /catchup  →  reads HANDOFF.md + git state    │
│             →  re-hydrates, resumes work        │
└─────────────────────────────────────────────────┘
```

*Same machine, new session?* Identical loop, minus the git hop: `/handoff` at the end of one
session, `/catchup` at the start of the next. You don't even need to commit; the `HANDOFF.md`
sitting in your working tree is enough (committing just adds durability and is what carries it to
another machine).

### The three pieces

| Piece | Type | What it does |
|-------|------|--------------|
| **`/handoff`** | Skill | Synthesizes the current session into a curated `HANDOFF.md` at the repo root. Archives any prior handoff to `.handoffs/`, then commits + pushes automatically (gated by a secret-safety check). Use `/handoff draft` to write the file without committing. |
| **`/catchup`** | Skill | On a fresh session or another machine, reads `HANDOFF.md` + current git state, reconciles branch/sync differences, and briefs you so you continue where the last session left off. Read-only until you confirm. |
| **SessionStart hook** | Hook | When you start a session inside a repo whose root has a `HANDOFF.md`, quietly injects a reminder to run `/catchup` plus the first 30 lines of the handoff. A no-op otherwise. |

### `/handoff` in detail

When you run `/handoff` (optionally `/handoff <focus or title>`, or `/handoff draft` to skip the
commit and push), the skill:

1. **Confirms it's in a git repo.** If not, it writes a local-only `HANDOFF.md` and skips the git
   steps, telling you it won't cross machines until the directory is a repo with a remote.
2. **Collects live git context:** repo root, branch, ahead/behind sync status, last commit,
   uncommitted changes, recent history, plus the git user, remote URL, and default base branch for
   the front-matter.
3. **Synthesizes from the conversation:** it distills the objective, what changed, decisions and
   their rationale, what's verified vs. assumed, blockers, and ordered next steps, and folds in
   salient, still-true notes from `~/.claude/projects/<project>/memory/MEMORY.md` so they cross
   machines too. It does *not* dump the transcript.
4. **Runs a security gate:** the handoff is treated as world-readable. It writes env-var **names**
   only (pointing at `.env.example`), never secret values, tokens, connection strings, or PII,
   including in anything folded in from memory.
5. **Archives the previous handoff:** if `HANDOFF.md` already exists, it's moved to
   `.handoffs/<UTC-timestamp>-prev.md` (via `git mv` if tracked, preserving history) before the new
   one is written. It refuses to overwrite a handoff that still has unresolved merge-conflict
   markers.
6. **Writes a fresh `HANDOFF.md`** from the template, filling every section ("None" where genuinely
   empty, never a placeholder).
7. **Scans the written file** for high-signal secret shapes as a mechanical backstop to the
   security gate, and stops before pushing if anything matches.
8. **Commits and pushes automatically:** stages `HANDOFF.md` + `.handoffs/`, commits with a
   `chore(handoff): ...` message, and pushes the current branch (setting upstream if needed). It
   reports the branch it pushed to and the commit hash. If the push is rejected because the other
   machine pushed first, it rebases and keeps your newer handoff rather than force-pushing; for a
   repo with no remote it commits locally and says so; in a detached-HEAD state it stops rather
   than orphan the commit. The security gate plus the secret scan are what keep auto-push safe.

### `/catchup` in detail

Run `/catchup` at the start of a new session or after switching machines. It:

1. **Reads `HANDOFF.md`** at the repo root (if missing, it lists any archives under `.handoffs/`
   and stops; if the file contains merge-conflict markers, it stops and tells you to resolve them).
2. **Reconciles with git:** if the handoff's recorded commit differs from the current `HEAD`, it
   warns the brief may be stale. If the handoff's branch differs from your current branch, or your
   tree is behind origin, it flags that and suggests `git fetch && git switch <branch> && git pull`
   (after you commit or stash any local changes). It warns about uncommitted changes that might
   conflict.
3. **Briefs you in ~5 lines:** objective, current status, blockers, and the first next step.
4. **Confirms reproduce/verify commands** still apply and asks before starting on the first step.

### The `HANDOFF.md` template

Each handoff has YAML front-matter (`session_date`, `author`, `operator`, `repo`, `branch`, `base`,
`status`, `handoff_reason`) followed by the sections below (`author` is the agent identity, e.g.
`claude-code`; `operator` is the human):

`TL;DR` · `Objective / Goal` · `Current Status` · `What Changed This Session` ·
`Key Decisions & Rationale` · `Files Touched` (table) · `Commands & Environment to Reproduce` ·
`How to Verify / Test` · `Open Questions / Blockers` · `Next Steps` (ordered checklist) ·
`Git State` · `Context & Gotchas` · `Reference Links`

The goal: a fresh agent with **zero access to the prior chat** can reach a reproducing state fast
and never re-litigate already-settled decisions.

---

## Repository layout

```
claude-handoff/
├── README.md
├── CHANGELOG.md                     # release history
├── LICENSE                          # MIT
├── install.ps1                      # Windows installer
├── install.sh                       # macOS / Linux installer
├── update.ps1                       # Windows: git pull + re-install in one step
├── update.sh                        # macOS / Linux: git pull + re-install in one step
├── .gitignore
├── .gitattributes                   # forces LF on *.sh and *.md, CRLF on *.ps1
├── hooks/
│   ├── load-handoff.ps1             # SessionStart hook (Windows / PowerShell 5.1+)
│   └── load-handoff.sh              # SessionStart hook (macOS / Linux; uses jq or python3)
└── skills/
    ├── handoff/
    │   ├── SKILL.md                 # the /handoff skill
    │   └── HANDOFF.template.md      # the handoff document template
    └── catchup/
        └── SKILL.md                 # the /catchup skill
```

---

## Install

Clone the repo, then run the installer for your OS. It copies the skills + hook into `~/.claude/`
and merges the SessionStart hook into `~/.claude/settings.json` **without touching your other
settings**. Both installers are idempotent, so re-run any time after a `git pull`.

**Windows (PowerShell):**
```powershell
git clone https://github.com/briansmith80/claude-handoff.git
cd claude-handoff
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/briansmith80/claude-handoff.git
cd claude-handoff
bash ./install.sh   # the settings.json auto-merge needs jq or python3; without either, see Manual hook setup
```

After installing, restart Claude Code or open `/hooks` once (this reloads config); the hook only
registers in sessions that started *after* it existed. The `/handoff` and `/catchup` skills are
live immediately (skills hot-reload). To verify, type `/` and confirm `/handoff` and `/catchup`
autocomplete, and open `/hooks` to confirm a SessionStart entry whose command contains
`load-handoff`. Before merging, the installer backs up any existing `settings.json` to
`settings.json.bak` and re-serializes the file, so whitespace and key order may change even though
your settings are preserved (JSON comments are dropped).

### Updating

The installer copies the tooling into `~/.claude`, so a `git pull` alone is **not** enough; you
must re-run the installer to push changes into `~/.claude`. The `update` script does both in one
step. Run it from inside the cloned repo:

```powershell
cd path\to\claude-handoff
powershell -ExecutionPolicy Bypass -File .\update.ps1   # Windows
```
```bash
cd path/to/claude-handoff
bash ./update.sh      # macOS / Linux
```

It pulls the latest (fast-forward only) and re-runs the installer. Skills hot-reload, so the
updated `/handoff` / `/catchup` are active immediately; only hook *changes* need a `/hooks` reload
or a restart.

### Uninstall

Deleting the cloned repo alone does **not** undo the install. To fully remove the tooling:

1. Delete the installed files: `~/.claude/skills/handoff/`, `~/.claude/skills/catchup/`, and
   `~/.claude/hooks/load-handoff.ps1` / `load-handoff.sh`.
2. **Important:** remove the SessionStart entry from `~/.claude/settings.json` whose
   `hooks[].command` contains `load-handoff`. If you skip this, every new session tries to run a
   now-missing script and errors. (`settings.json.bak` only captures the state at the first
   install and is never refreshed afterward, so it may not reflect later manual edits.)

---

## Usage

1. **Wrapping up / context filling / before switching machines:** run `/handoff` (optionally
   `/handoff <focus>`, or `/handoff draft` to write the file without committing or pushing). It
   writes the `HANDOFF.md`, then commits and pushes it automatically.
2. **New session or other machine:** `git pull`, then run `/catchup`.

That's the whole loop. The SessionStart hook reminds you to run `/catchup` whenever you start a
session inside a repo that has a `HANDOFF.md` at its root (active only in sessions started after
install; until you restart or run `/hooks` once, just run `/catchup` yourself, since skills are
live immediately).

---

## Manual hook setup

If the installer skipped `settings.json` (e.g. neither `jq` nor `python3` was available on
macOS/Linux), add this under `hooks` in `~/.claude/settings.json` yourself:

```jsonc
// Windows
"SessionStart": [{
  "matcher": "startup|resume|compact",
  "hooks": [{ "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/<you>/.claude/hooks/load-handoff.ps1\"" }]
}]

// macOS / Linux
"SessionStart": [{
  "matcher": "startup|resume|compact",
  "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/load-handoff.sh\"" }]
}]
```

---

## Troubleshooting

- **`/handoff` committed but the push failed (rejected / no upstream / auth).** Usually your branch
  is behind origin or has no upstream. The `HANDOFF.md` is already committed locally, so nothing is
  lost: run `git pull --rebase` (or `git push -u origin <branch>` to set the upstream), resolve any
  conflict, then `git push`. If both machines wrote a handoff, keep the newer `HANDOFF.md` during
  the rebase.
- **The SessionStart hook didn't nudge me to `/catchup`.** It fires only when a `HANDOFF.md` is at
  the git repo root. If you started Claude Code before installing, restart or open `/hooks` once so
  the hook registers. You can always just run `/catchup` manually.
- **`/handoff` or `/catchup` don't autocomplete.** Confirm the installer copied them:
  `~/.claude/skills/handoff/` and `~/.claude/skills/catchup/` should exist. If not, re-run the
  installer from inside the cloned repo.

---

## Notes & conventions

- **Secrets:** `/handoff` is instructed to write env-var *names* only, never values, and runs a
  mechanical secret scan before pushing. Keep handoffs free of credentials and PII even in private
  repos: good hygiene, and it means a handoff is safe to push to a public repo.
- **Branch hygiene:** do handoff work on a feature branch so `main` stays clean. The rolling
  `HANDOFF.md` lives at the repo root; timestamped archives accumulate in `.handoffs/` and are safe
  to delete at any time (git preserves the prior versions).
- **Hook scope:** the SessionStart hook looks for `HANDOFF.md` at the git repo root (falling back
  to the session's working directory), so it fires anywhere inside the repo. It only reminds about
  `/catchup`; `/handoff` is always triggered by you.
- **No `pwsh` required:** the Windows hook uses the built-in `powershell.exe` (5.1+).
- **Line endings:** `.gitattributes` forces `*.sh` and `*.md` to LF (so shebangs work and synced
  handoffs stay byte-stable after a Windows clone) and `*.ps1` to CRLF.
- **Hook is read-only and safe:** it only ever *reads* `HANDOFF.md` and emits context; it never
  writes, commits, or pushes anything. All git mutations happen only inside `/handoff` (which
  commits and pushes automatically, gated by its secret-safety check); the hook and `/catchup`
  never write, commit, or push.

---

## Changelog

Release history lives in [CHANGELOG.md](CHANGELOG.md).

---

## License

MIT, see [LICENSE](LICENSE).
