#!/usr/bin/env bash
# Installs the Claude handoff tooling into ~/.claude on macOS/Linux.
# Idempotent: safe to re-run after a `git pull`. Open /hooks (or restart Claude Code) to activate the hook.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude="$HOME/.claude"

# 1) Copy skills + hook
mkdir -p "$claude/skills/handoff" "$claude/skills/catchup" "$claude/hooks"
cp "$repo/skills/handoff/"* "$claude/skills/handoff/"
cp "$repo/skills/catchup/"* "$claude/skills/catchup/"
cp "$repo/hooks/load-handoff.sh" "$claude/hooks/"
chmod +x "$claude/hooks/load-handoff.sh"
echo "Copied skills + hook into $claude"

# 2) Merge the SessionStart hook into settings.json (idempotent, preserves existing settings)
settings="$claude/settings.json"
cmd="bash $claude/hooks/load-handoff.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "WARNING: jq not found, so settings.json was NOT modified."
  echo "Install jq, re-run, or add this hook manually (see README.md):"
  echo "  SessionStart -> matcher \"startup|resume|compact\" -> command: $cmd"
  exit 0
fi

if [ -f "$settings" ]; then
  cp "$settings" "$settings.bak"
  echo "Backed up existing settings.json to settings.json.bak"
else
  echo '{}' > "$settings"
fi
tmp="$(mktemp)"
jq --arg cmd "$cmd" '
  .hooks //= {} |
  .hooks.SessionStart //= [] |
  if any(.hooks.SessionStart[]?; ([.hooks[]?.command] | any(. // "" | test("load-handoff.sh"))))
  then .
  else .hooks.SessionStart += [{
    matcher: "startup|resume|compact",
    hooks: [{ type: "command", command: $cmd, statusMessage: "Checking for a session handoff..." }]
  }]
  end
' "$settings" > "$tmp" && mv "$tmp" "$settings"
echo "Ensured SessionStart handoff hook in settings.json"

echo
echo "Done. Open /hooks in Claude Code (or restart) to activate the hook. Skills are live immediately."
