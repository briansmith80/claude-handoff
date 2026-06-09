#!/usr/bin/env bash
# Claude Code SessionStart hook (macOS/Linux): surface an existing HANDOFF.md so you
# never forget to /catchup. Emits context only when HANDOFF.md is present in the
# session's working directory; otherwise a no-op. Requires jq OR python3 for JSON output.
set -euo pipefail

[ -f HANDOFF.md ] || exit 0

preview="$(head -n 30 HANDOFF.md)"
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
