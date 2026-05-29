# Claude Code PostToolUse hook — Windows toast notification on file change
param()

$raw = [Console]::In.ReadToEnd()
$json = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
if (-not $json) { exit 0 }

$tool  = $json.tool_name
$title = $env:PROJECT_NAME ?? "Claude Code"
$msg   = ""

switch ($tool) {
    "Write" {
        $f    = $json.tool_input.file_path
        $name = if ($f) { Split-Path $f -Leaf } else { "file" }
        $msg  = "Created: $name"
    }
    "Edit" {
        $f    = $json.tool_input.file_path
        $name = if ($f) { Split-Path $f -Leaf } else { "file" }
        $msg  = "Edited: $name"
    }
    default { exit 0 }
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $tray                    = New-Object System.Windows.Forms.NotifyIcon
    $tray.Icon               = [System.Drawing.SystemIcons]::Information
    $tray.BalloonTipIcon     = [System.Windows.Forms.ToolTipIcon]::Info
    $tray.BalloonTipTitle    = $title
    $tray.BalloonTipText     = $msg
    $tray.Visible            = $true
    $tray.ShowBalloonTip(3000)
    Start-Sleep -Milliseconds 300
    $tray.Dispose()
} catch { exit 0 }
