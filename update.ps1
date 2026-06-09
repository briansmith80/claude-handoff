# Updates the Claude handoff tooling: pulls the latest from this repo, then re-runs the installer
# so the new skills + hook land in ~/.claude. Run from the cloned repo (the script resolves its own path).
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git not found on PATH. Install git, then re-run."
}

Write-Host "Pulling latest in $repo ..."
git -C $repo pull --ff-only
if ($LASTEXITCODE -ne 0) {
  throw "git pull failed (history likely diverged). Your installed tooling in ~/.claude is UNCHANGED (still the old version). Resolve manually (e.g. git pull --rebase, or stash local commits), then re-run .\update.ps1."
}

Write-Host "Re-running installer ..."
& (Join-Path $repo 'install.ps1')
