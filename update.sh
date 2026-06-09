#!/usr/bin/env bash
# Updates the Claude handoff tooling: pulls the latest from this repo, then re-runs the installer
# so the new skills + hook land in ~/.claude. Safe to run from anywhere.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Pulling latest in $repo ..."
git -C "$repo" pull --ff-only

echo "Re-running installer ..."
bash "$repo/install.sh"
