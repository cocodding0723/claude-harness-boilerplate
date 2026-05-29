# Claude Code PostToolUse hook — Jira auto-transition + comment on git commit/push
param()

$raw  = [Console]::In.ReadToEnd()
$json = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
if (-not $json) { exit 0 }

$tool = $json.tool_name
$cmd  = [string]($json.tool_input.command)

function Invoke-JiraApi {
    param([string]$Method, [string]$Path, [object]$Body)
    $base  = $env:JIRA_BASE_URL
    $user  = $env:JIRA_USER_EMAIL
    $token = $env:JIRA_API_TOKEN
    if (-not $base -or -not $user -or -not $token) { return $null }
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${token}"))
    try {
        $params = @{
            Uri        = "${base}/rest/api/2/${Path}"
            Method     = $Method
            Headers    = @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" }
            TimeoutSec = 5
        }
        if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress) }
        return Invoke-RestMethod @params -ErrorAction Stop
    } catch { return $null }
}

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
        Start-Sleep -Milliseconds 400
        $tray.Dispose()
    } catch {}
}

$ProjectName = $env:PROJECT_NAME ?? "Claude Code"

if ($cmd -match "git commit") {
    # Match any issue key format (PROJ-123, KAN-45, etc.)
    $issueKeys = [regex]::Matches($cmd, "[A-Z]+-\d+") |
        ForEach-Object { $_.Value } | Sort-Object -Unique

    if ($issueKeys.Count -gt 0) {
        $msgMatch = [regex]::Match($cmd, '(?:-m\s+["\x27]?)([^\r\n"]+)')
        $shortMsg = if ($msgMatch.Success) { $msgMatch.Groups[1].Value } else { $cmd }
        if ($shortMsg.Length -gt 150) { $shortMsg = $shortMsg.Substring(0, 150) + "..." }

        $JIRA_IN_PROGRESS_TRANSITION = $env:JIRA_IN_PROGRESS_ID ?? "31"

        foreach ($key in $issueKeys) {
            Invoke-JiraApi -Method "POST" -Path "issue/$key/transitions" -Body @{
                transition = @{ id = $JIRA_IN_PROGRESS_TRANSITION }
            } | Out-Null
            Invoke-JiraApi -Method "POST" -Path "issue/$key/comment" -Body @{
                body = "Claude Code commit: ``$shortMsg``"
            } | Out-Null
        }

        Show-Balloon -Title "$ProjectName — Jira updated" `
                     -Text  "$($issueKeys -join ', ') → In Progress + commit logged" `
                     -Icon  "Information"
    } else {
        Show-Balloon -Title "$ProjectName — No issue key" `
                     -Text  "Commit has no issue key (e.g. PROJ-123).`nExample: feat(scope): PROJ-42 description" `
                     -Icon  "Warning"
    }
    exit 0
}

if ($cmd -match "git push") {
    Show-Balloon -Title "$ProjectName — Git push" `
                 -Text  "Push complete." `
                 -Icon  "Information"
    exit 0
}

exit 0
