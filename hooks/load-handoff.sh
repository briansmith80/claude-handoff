#!/usr/bin/env bash
# Claude Code SessionStart hook (macOS/Linux): surface an existing HANDOFF.md so you never
# forget to /catchup. Looks for HANDOFF.md at the git repo root (falling back to the current
# directory), so it fires anywhere inside the repo, not only at the root. A no-op otherwise.
# Requires jq OR python3 for JSON output (falls back to plain text if neither is present).
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$root" ] && [ -f "$root/HANDOFF.md" ]; then
  handoff="$root/HANDOFF.md"
elif [ -f HANDOFF.md ]; then
  handoff="HANDOFF.md"
else
  exit 0
fi

preview="$(head -n 30 "$handoff" | tr -d '\r')"
msg="A HANDOFF.md from a previous session exists in this repo. Run /catchup to fully resume where it left off.

--- HANDOFF.md (first 30 lines) ---
$preview"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$msg" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
elif command -v python3 >/dev/null 2>&1; then
  msg="$msg" python3 -c 'import json,os; print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":os.environ["msg"]}}))'
else
  # Last resort: plain text on stdout is also injected as SessionStart context.
  printf '%s\n' "$msg"
fi
exit 0
