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
# Quote the script path so a $HOME containing a space still launches.
cmd="bash \"$claude/hooks/load-handoff.sh\""

# Back up once: never overwrite a previously-saved good backup.
backup_once() {
  if [ -f "$settings" ] && [ ! -f "$settings.bak" ]; then
    cp "$settings" "$settings.bak"
    echo "Backed up existing settings.json to settings.json.bak"
  fi
}

if command -v jq >/dev/null 2>&1; then
  backup_once
  [ -f "$settings" ] || echo '{}' > "$settings"
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
  echo "Ensured SessionStart handoff hook in settings.json (via jq)"
elif command -v python3 >/dev/null 2>&1; then
  backup_once
  [ -f "$settings" ] || echo '{}' > "$settings"
  cmd="$cmd" python3 - "$settings" <<'PY'
import json, os, sys
p = sys.argv[1]
try:
    with open(p) as f:
        s = json.load(f)
except (FileNotFoundError, ValueError):
    s = {}
ss = s.setdefault("hooks", {}).setdefault("SessionStart", [])
present = any("load-handoff.sh" in h.get("command", "")
              for g in ss for h in g.get("hooks", []))
if not present:
    ss.append({"matcher": "startup|resume|compact",
               "hooks": [{"type": "command", "command": os.environ["cmd"],
                          "statusMessage": "Checking for a session handoff..."}]})
with open(p, "w") as f:
    json.dump(s, f, indent=2)
PY
  echo "Ensured SessionStart handoff hook in settings.json (via python3)"
else
  echo "WARNING: neither jq nor python3 found, so settings.json was NOT modified."
  echo "Install jq or python3, re-run, or add this hook manually (see README.md):"
  echo "  SessionStart -> matcher \"startup|resume|compact\" -> command: $cmd"
  echo "Note: the hook itself still works without jq/python3, emitting plain-text context (lower fidelity)."
  exit 0
fi

# 3) Verify the hook actually registered
if grep -q 'load-handoff' "$settings" 2>/dev/null; then
  echo "OK: SessionStart hook registered in $settings"
else
  echo "WARNING: hook not found in $settings - add it manually (see README 'Manual hook setup')."
fi

echo
echo "Two commands are now available: /handoff (save this session) and /catchup (resume it, including on another machine)."
echo "Skills are live immediately. Restart Claude Code (or run /hooks once) to activate the SessionStart hook, then type '/' to confirm /handoff and /catchup appear."
