# Installs the Claude handoff tooling into ~/.claude on Windows.
# Idempotent: safe to re-run after a 'git pull'. Open /hooks (or restart Claude Code) to activate the hook.
$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot
$claude = Join-Path $env:USERPROFILE '.claude'

# 1) Copy skills + hook
$dirs = @(
  (Join-Path $claude 'skills\handoff'),
  (Join-Path $claude 'skills\catchup'),
  (Join-Path $claude 'hooks')
)
New-Item -ItemType Directory -Force -Path $dirs | Out-Null
Copy-Item (Join-Path $repo 'skills\handoff\*') (Join-Path $claude 'skills\handoff') -Recurse -Force
Copy-Item (Join-Path $repo 'skills\catchup\*') (Join-Path $claude 'skills\catchup') -Recurse -Force
Copy-Item (Join-Path $repo 'hooks\load-handoff.ps1') (Join-Path $claude 'hooks') -Force
Write-Host "Copied skills + hook into $claude"

# 2) Merge the SessionStart hook into settings.json (idempotent, preserves existing settings)
$settingsPath = Join-Path $claude 'settings.json'
if (Test-Path $settingsPath) {
  $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
} else {
  $settings = [pscustomobject]@{}
}

$hookCmd = ("powershell -NoProfile -ExecutionPolicy Bypass -File " + (Join-Path $claude 'hooks\load-handoff.ps1')) -replace '\\','/'
$entry = [pscustomobject]@{
  matcher = 'startup|resume|compact'
  hooks   = @([pscustomobject]@{ type = 'command'; command = $hookCmd; statusMessage = 'Checking for a session handoff...' })
}

if (-not (Get-Member -InputObject $settings -Name 'hooks')) {
  $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
}
if (-not (Get-Member -InputObject $settings.hooks -Name 'SessionStart')) {
  $settings.hooks | Add-Member -NotePropertyName SessionStart -NotePropertyValue @()
}

$already = $false
foreach ($h in @($settings.hooks.SessionStart)) {
  foreach ($hh in @($h.hooks)) {
    if ($hh.command -like '*load-handoff.ps1*') { $already = $true }
  }
}

if ($already) {
  Write-Host "SessionStart handoff hook already present - left as-is."
} else {
  $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + $entry
  $json = $settings | ConvertTo-Json -Depth 12
  [System.IO.File]::WriteAllText($settingsPath, $json, (New-Object System.Text.UTF8Encoding $false))
  Write-Host "Added SessionStart handoff hook to settings.json"
}

Write-Host ""
Write-Host "Done. Open /hooks in Claude Code (or restart) to activate the hook. Skills are live immediately."
