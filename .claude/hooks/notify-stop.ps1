# Claude Code Stop hook — session end: toast + Jira comment + uncommitted file check
param()

$WorkDir     = $env:PROJECT_ROOT ?? (Get-Location).Path
$JiraBase    = $env:JIRA_BASE_URL
$JiraUser    = $env:JIRA_USER_EMAIL
$JiraToken   = $env:JIRA_API_TOKEN
$ProjectName = $env:PROJECT_NAME ?? "Claude Code"

# ── Helpers ──────────────────────────────────────────────────────────────────
function Show-Balloon {
    param([string]$Title, [string]$Text, [string]$Icon = "Information")
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $tray                 = New-Object System.Windows.Forms.NotifyIcon
        $tray.Icon            = [System.Drawing.SystemIcons]::$Icon
        $tray.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$Icon
        $tray.BalloonTipTitle = $Title
        $tray.BalloonTipText  = $Text
        $tray.Visible         = $true
        $tray.ShowBalloonTip(5000)
        Start-Sleep -Milliseconds 500
        $tray.Dispose()
    } catch {}
}

function Invoke-JiraApi {
    param([string]$Method, [string]$Path, [object]$Body)
    if (-not $JiraToken -or -not $JiraBase) { return $null }
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUser}:${JiraToken}"))
    try {
        $params = @{
            Uri        = "${JiraBase}/rest/api/2/${Path}"
            Method     = $Method
            Headers    = @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" }
            TimeoutSec = 8
        }
        if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress) }
        return Invoke-RestMethod @params -ErrorAction Stop
    } catch { return $null }
}

# ── Git status ────────────────────────────────────────────────────────────────
$statusLines = try {
    $raw = & git -C $WorkDir status --short 2>$null
    if ($raw) { $raw -split "`n" | Where-Object { $_.Trim() -ne "" } } else { @() }
} catch { @() }

$recentCommits = try {
    $raw = & git -C $WorkDir log --oneline -5 2>$null
    if ($raw) { $raw -split "`n" | Where-Object { $_.Trim() -ne "" } } else { @() }
} catch { @() }

# ── Jira: comment on referenced issues ───────────────────────────────────────
$kanKeys = @()
foreach ($line in $recentCommits) {
    [regex]::Matches($line, "[A-Z]+-\d+") | ForEach-Object {
        if ($kanKeys -notcontains $_.Value) { $kanKeys += $_.Value }
    }
}

$jiraUpdated = @()
foreach ($key in $kanKeys) {
    $related   = $recentCommits | Where-Object { $_ -match [regex]::Escape($key) } | Select-Object -First 1
    $commitMsg = if ($related) { ($related -replace "^[0-9a-f]{7}\s+", "").Trim() } else { "session complete" }
    $result    = Invoke-JiraApi -Method "POST" -Path "issue/$key/comment" -Body @{
        body = "Claude Code session complete — commit: $commitMsg"
    }
    if ($result) { $jiraUpdated += $key }
}

# ── Toast notification ────────────────────────────────────────────────────────
if ($statusLines.Count -gt 0) {
    $fileList = ($statusLines | Select-Object -First 8) -join "`n"
    $extra    = if ($statusLines.Count -gt 8) { "`n… +$($statusLines.Count - 8) more" } else { "" }
    Show-Balloon -Title "$ProjectName — Uncommitted changes" `
                 -Text  "$($statusLines.Count) files not committed:`n${fileList}${extra}" `
                 -Icon  "Warning"
} else {
    $jiraText = if ($jiraUpdated.Count -gt 0) { "`nJira updated: $($jiraUpdated -join ', ')" } else { "" }
    Show-Balloon -Title "$ProjectName — Done" `
                 -Text  "Agent work complete.${jiraText}" `
                 -Icon  "Information"
}

exit 0
