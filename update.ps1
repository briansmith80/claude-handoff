# Updates the Claude handoff tooling: pulls the latest from this repo, then re-runs the installer
# so the new skills + hook land in ~/.claude. Safe to run from anywhere.
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

Write-Host "Pulling latest in $repo ..."
git -C $repo pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "git pull failed - resolve manually, then re-run." }

Write-Host "Re-running installer ..."
& (Join-Path $repo 'install.ps1')
