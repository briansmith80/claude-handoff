# Claude Code SessionStart hook: surface an existing HANDOFF.md so you never forget to /catchup.
# Looks for HANDOFF.md at the git repo root (falling back to the current directory), so it
# fires anywhere inside the repo, not only when launched from the root. A no-op otherwise.
$ErrorActionPreference = 'SilentlyContinue'

$root = (git rev-parse --show-toplevel 2>$null)
if ($root -and (Test-Path (Join-Path $root 'HANDOFF.md'))) {
    $handoff = Join-Path $root 'HANDOFF.md'
} elseif (Test-Path 'HANDOFF.md') {
    $handoff = 'HANDOFF.md'
} else {
    exit 0
}

$preview = (Get-Content $handoff -TotalCount 30) -join "`n"
$msg = "A HANDOFF.md from a previous session exists in this repo. Run /catchup to fully resume where it left off.`n`n--- HANDOFF.md (first 30 lines) ---`n$preview"
$payload = @{
    hookSpecificOutput = @{
        hookEventName     = 'SessionStart'
        additionalContext = $msg
    }
}
$payload | ConvertTo-Json -Depth 6 -Compress
exit 0
