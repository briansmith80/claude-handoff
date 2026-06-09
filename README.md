# claude-handoff

**Cross-session, cross-machine context handoffs for [Claude Code](https://code.claude.com).**

Claude Code's built-in continuity — `--resume`, `/compact`, and automatic memory — is all
**machine-local**. It lives in `~/.claude` on one computer and can't carry your in-progress
work from, say, a work desktop to a home laptop. `claude-handoff` closes that gap with a
small, git-syncable workflow: a fresh agent — on the same machine after a context wipe, or a
*different* machine entirely — can pick up exactly where the last session stopped, without
access to the original chat.

---

## How it works

The core idea: separate the **tooling** from the **handoff notes**.

- The **tooling** (two skills + one hook) is installed into `~/.claude` on every machine.
  Clone this repo anywhere, run the installer, and the workflow is identical everywhere.
- The **handoff note** (`HANDOFF.md`) is written to the root of *your project's* repo and
  committed there. Because it rides in the project repo, the notes and the exact code they
  describe travel together — pull on another machine and both arrive in sync.

```
┌─────────────── Machine A (work) ───────────────┐
│  Session running low on context / end of day   │
│  → /handoff  →  writes HANDOFF.md in your repo  │
│             →  commits + pushes (with your OK)  │
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

### The three pieces

| Piece | Type | What it does |
|-------|------|--------------|
| **`/handoff`** | Skill | Synthesizes the current session into a curated `HANDOFF.md` at the repo root. Archives any prior handoff to `.handoffs/`, then offers to commit + push. |
| **`/catchup`** | Skill | On a fresh session or another machine, reads `HANDOFF.md` + current git state, reconciles branch/sync differences, and briefs you so you continue where the last session left off. |
| **SessionStart hook** | Hook | When you open a repo that contains a `HANDOFF.md`, quietly injects a reminder to run `/catchup` plus the first 30 lines of the handoff. A no-op in repos without one. |

### `/handoff` in detail

When you run `/handoff` (optionally `/handoff <focus or title>`), the skill:

1. **Collects live git context** — repo root, branch, ahead/behind sync status, last commit,
   uncommitted changes, recent history.
2. **Synthesizes from the conversation** — it distills the objective, what changed, decisions
   and their rationale, what's verified vs. assumed, blockers, and ordered next steps. It does
   *not* dump the transcript.
3. **Runs a security gate** — the handoff is treated as world-readable. It writes env-var
   **names** only (pointing at `.env.example`), never secret values, tokens, connection
   strings, or PII.
4. **Archives the previous handoff** — if `HANDOFF.md` already exists, it's moved to
   `.handoffs/<UTC-timestamp>-prev.md` (via `git mv` if tracked, preserving history) before the
   new one is written.
5. **Writes a fresh `HANDOFF.md`** from the template, filling every section ("None" where
   genuinely empty — never a placeholder).
6. **Optionally folds in machine-local memory** — salient, still-true notes from
   `~/.claude/projects/<project>/memory/MEMORY.md` get pulled into "Context & Gotchas" so they
   cross machines too.
7. **Reports and offers to sync** — prints the path and a short summary, then asks before
   doing `git add` / `commit` / `push`. **It never commits or pushes without explicit
   confirmation.**

### `/catchup` in detail

Run `/catchup` at the start of a new session or after switching machines. It:

1. **Reads `HANDOFF.md`** at the repo root (if missing, it lists any archives under
   `.handoffs/` and stops).
2. **Reconciles with git** — if the handoff's branch differs from your current branch, or your
   tree is behind origin, it flags that and suggests `git fetch && git switch <branch> && git
   pull`. It warns about uncommitted local changes that might conflict.
3. **Briefs you in ~5 lines** — objective, current status, blockers, and the first next step.
4. **Confirms reproduce/verify commands** still apply and offers to start on the first step.

### The `HANDOFF.md` template

Each handoff has YAML front-matter (`session_date`, `operator`, `repo`, `branch`, `base`,
`status`, `handoff_reason`) followed by these sections:

`TL;DR` · `Objective / Goal` · `Current Status` · `What Changed This Session` ·
`Key Decisions & Rationale` · `Files Touched` (table) · `Commands & Environment to Reproduce` ·
`How to Verify / Test` · `Open Questions / Blockers` · `Next Steps` (ordered checklist) ·
`Git State` · `Context & Gotchas` · `Reference Links`

The goal: a fresh agent with **zero access to the prior chat** can reach a reproducing state
fast and never re-litigate already-settled decisions.

---

## Repository layout

```
claude-handoff/
├── README.md
├── install.ps1                      # Windows installer
├── install.sh                       # macOS / Linux installer
├── .gitignore
├── .gitattributes                   # forces LF on *.sh, CRLF on *.ps1
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

Clone the repo, then run the installer for your OS. It copies the skills + hook into
`~/.claude/` and merges the SessionStart hook into `~/.claude/settings.json` **without touching
your other settings**. Both installers are idempotent — re-run any time after a `git pull`.

**Windows (PowerShell):**
```powershell
git clone https://github.com/briansmith80/claude-handoff.git
powershell -ExecutionPolicy Bypass -File .\claude-handoff\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/briansmith80/claude-handoff.git
bash ./claude-handoff/install.sh   # needs `jq` for the auto-merge (python3 fallback at runtime); see manual step if absent
```

After installing, open `/hooks` in Claude Code once (this reloads config) or restart — the hook
only registers in sessions that started *after* it existed. The `/handoff` and `/catchup`
skills are live immediately (skills hot-reload).

> **Note:** the installer copies the tooling into `~/.claude`. Updating means
> `git pull` in this repo, then re-running the installer.

---

## Usage

1. **Wrapping up / context filling / before switching machines:** run `/handoff` (optionally
   `/handoff <focus>`). Review the `HANDOFF.md` it writes; say yes when it offers to commit +
   push.
2. **New session or other machine:** `git pull`, then run `/catchup`.

That's the whole loop. The SessionStart hook will remind you to run `/catchup` whenever you open
a repo that has a `HANDOFF.md`.

---

## Manual hook setup

If the installer skipped `settings.json` (e.g. `jq` wasn't available on macOS/Linux), add this
under `hooks` in `~/.claude/settings.json` yourself:

```jsonc
// Windows
"SessionStart": [{
  "matcher": "startup|resume|compact",
  "hooks": [{ "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/<you>/.claude/hooks/load-handoff.ps1" }]
}]

// macOS / Linux
"SessionStart": [{
  "matcher": "startup|resume|compact",
  "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/load-handoff.sh" }]
}]
```

---

## Notes & conventions

- **Secrets:** `/handoff` is instructed to write env-var *names* only, never values. Keep
  handoffs free of credentials and PII even in private repos — good hygiene, and it means a
  handoff is safe to push to a public repo.
- **Branch hygiene:** do handoff work on a feature branch so `main` stays clean. The rolling
  `HANDOFF.md` lives at the repo root; immutable, timestamped archives live in `.handoffs/`.
- **No `pwsh` required:** the Windows hook uses the built-in `powershell.exe` (5.1+).
- **Line endings:** `.gitattributes` forces `*.sh` to LF (so shebangs work after a Windows
  clone) and `*.ps1` to CRLF.
- **Hook is read-only and safe:** it only ever *reads* `HANDOFF.md` and emits context; it never
  writes, commits, or pushes anything. All git mutations happen only inside `/handoff`, and only
  after you confirm.
