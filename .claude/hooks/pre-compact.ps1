# Claude Code PreCompact hook — save working state before context compaction
param()

$WorkDir     = $env:PROJECT_ROOT ?? (Get-Location).Path
$ContextFile = Join-Path $WorkDir ".claude" "pre_compact_context.md"

$raw     = [Console]::In.ReadToEnd()
$payload = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
$trigger = if ($payload -and $payload.trigger) { $payload.trigger } else { "unknown" }

$branch = try { (& git -C $WorkDir rev-parse --abbrev-ref HEAD 2>$null).Trim() } catch { "unknown" }

$recentCommits = try {
    $raw10 = & git -C $WorkDir log --oneline -10 2>$null
    if ($raw10) { ($raw10 -split "`n" | Where-Object { $_.Trim() -ne "" }) -join "`n" }
    else { "(no commits)" }
} catch { "(git log failed)" }

$workingTree = try {
    $rawStatus = & git -C $WorkDir status --short 2>$null
    if ($rawStatus) { ($rawStatus -split "`n" | Where-Object { $_.Trim() -ne "" }) -join "`n" }
    else { "(clean)" }
} catch { "(git status failed)" }

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"

$content = @"
# Pre-Compact Context Snapshot

- **Trigger**: $trigger
- **Timestamp**: $timestamp
- **Branch**: $branch

## Recent 10 Commits

``````
$recentCommits
``````

## Working Tree Status

``````
$workingTree
``````
"@

try {
    $content | Set-Content -Path $ContextFile -Encoding UTF8 -Force
} catch {}

$out = [ordered]@{
    systemMessage = "Pre-compact context saved. Reference .claude/pre_compact_context.md in next session."
}
Write-Output ($out | ConvertTo-Json -Compress)

exit 0
