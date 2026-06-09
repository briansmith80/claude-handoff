# claude-handoff

Cross-session, cross-machine context handoffs for [Claude Code](https://code.claude.com).

Built-in continuity (`--resume`, `/compact`, auto memory) is all **machine-local** — it
can't carry your progress from a work desktop to a home laptop. This repo adds a small,
git-syncable workflow that can:

- **`/handoff`** — synthesize the current session into a curated `HANDOFF.md` at the repo
  root (objective, status, decisions, files touched, next steps, git state), archive any
  prior one to `.handoffs/`, and optionally commit + push it.
- **`/catchup`** — on a fresh session or another machine, read `HANDOFF.md` + current git
  state and re-hydrate so you continue exactly where you left off.
- **SessionStart hook** — quietly reminds you to run `/catchup` whenever you open a repo
  that has a `HANDOFF.md`. No-op in repos without one.

The point: clone this repo on every machine and the tooling stays identical. The
`HANDOFF.md` itself rides in *your project's* repo, so the notes and the exact code they
describe travel together.

## Install

Clone, then run the installer for your OS. It copies the skills + hook into `~/.claude/`
and merges the SessionStart hook into `~/.claude/settings.json` without touching your other
settings. Re-run any time after `git pull` — it's idempotent.

**Windows (PowerShell):**
```powershell
git clone https://github.com/briansmith80/claude-handoff.git
powershell -ExecutionPolicy Bypass -File .\claude-handoff\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/briansmith80/claude-handoff.git
bash ./claude-handoff/install.sh   # needs `jq` for the auto-merge; see manual step below if absent
```

After installing, open `/hooks` in Claude Code once (it reloads config) or restart — the
hook only registers in sessions that started after it existed. The `/handoff` and
`/catchup` skills are live immediately (skills hot-reload).

## Usage

1. **Wrapping up / context filling / before switching machines:** run `/handoff`
   (optionally `/handoff <focus>`). Review the `HANDOFF.md` it writes; say yes when it
   offers to commit + push.
2. **New session or other machine:** `git pull`, then run `/catchup`.

## Manual hook setup (if the installer skipped settings.json)

Add this under `hooks` in `~/.claude/settings.json`:

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

## Notes

- **Secrets:** the `/handoff` skill is instructed to write env-var *names* only, never
  values. Keep handoffs free of credentials/PII even in private repos — good hygiene.
- **Branch hygiene:** do handoff work on a feature branch so `main` stays clean; the
  rolling `HANDOFF.md` lives at the repo root, immutable archives in `.handoffs/`.
- **No `pwsh` required:** the Windows hook uses built-in `powershell.exe` (5.1+).
