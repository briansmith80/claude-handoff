#!/usr/bin/env bash
# Updates the Claude handoff tooling: pulls the latest from this repo, then re-runs the installer
# so the new skills + hook land in ~/.claude. Run from the cloned repo (the script resolves its own path).
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found on PATH. Install git, then re-run." >&2; exit 1; }

echo "Pulling latest in $repo ..."
if ! git -C "$repo" pull --ff-only; then
  echo "git pull failed (history likely diverged). Your installed tooling in ~/.claude is UNCHANGED (still the old version). Resolve manually (e.g. git pull --rebase, or stash local commits), then re-run ./update.sh." >&2
  exit 1
fi

echo "Re-running installer ..."
bash "$repo/install.sh"
