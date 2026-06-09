# Claude Code SessionStart hook: surface an existing HANDOFF.md so you never forget to /catchup.
# Emits context only when a HANDOFF.md is present in the session's working directory; otherwise a no-op.
$ErrorActionPreference = 'SilentlyContinue'

if (Test-Path 'HANDOFF.md') {
    $preview = (Get-Content 'HANDOFF.md' -TotalCount 30) -join "`n"
    $msg = "A HANDOFF.md from a previous session exists in this repo. Run /catchup to fully resume where it left off.`n`n--- HANDOFF.md (first 30 lines) ---`n$preview"
    $payload = @{
        hookSpecificOutput = @{
            hookEventName     = 'SessionStart'
            additionalContext = $msg
        }
    }
    $payload | ConvertTo-Json -Depth 6 -Compress
}
exit 0
