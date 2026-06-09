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
  try {
    $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
  } catch {
    Write-Warning "Couldn't parse $settingsPath (JSON comments or a trailing comma?). Leaving it untouched."
    Write-Host "Add the SessionStart hook manually - see the 'Manual hook setup' section of the README."
    exit 0
  }
} else {
  $settings = [pscustomobject]@{}
}

# Quote the script path so a username with a space (e.g. C:/Users/First Last/...) still launches.
$hookCmd = ('powershell -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $claude 'hooks\load-handoff.ps1') + '"') -replace '\\','/'
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
  # Back up once: never overwrite a previously-saved good backup.
  if ((Test-Path $settingsPath) -and -not (Test-Path "$settingsPath.bak")) {
    Copy-Item $settingsPath "$settingsPath.bak"
    Write-Host "Backed up existing settings.json to settings.json.bak"
  }
  $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + $entry
  $json = $settings | ConvertTo-Json -Depth 32
  [System.IO.File]::WriteAllText($settingsPath, $json, (New-Object System.Text.UTF8Encoding $false))
  Write-Host "Added SessionStart handoff hook to settings.json (re-serialized; any // comments were dropped, original saved to settings.json.bak)"
}

# 3) Verify the hook actually registered
if ((Get-Content -Raw $settingsPath) -match 'load-handoff') {
  Write-Host "OK: SessionStart hook registered in $settingsPath"
} else {
  Write-Warning "Hook not found in $settingsPath - add it manually (see README 'Manual hook setup')."
}

Write-Host ""
Write-Host "Two commands are now available: /handoff (save this session) and /catchup (resume it, including on another machine)."
Write-Host "Skills are live immediately. Restart Claude Code (or run /hooks once) to activate the SessionStart hook, then type '/' to confirm /handoff and /catchup appear."
