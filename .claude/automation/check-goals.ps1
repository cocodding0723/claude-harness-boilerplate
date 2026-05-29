# check-goals.ps1 — Project goal achievement tracker
# Called by Stop hook after each session.
# Customize $Goals array for your project's success criteria.

param(
    [string]$DashboardUrl = $env:DASHBOARD_API ?? "http://localhost:4000",
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot ".." "..")
$LogDir      = Join-Path $ProjectRoot ".claude" "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$Now       = Get-Date -Format "yyyy-MM-dd HH:mm"

Write-Host "========================================"
Write-Host " Goal Achievement Check — $Now"
Write-Host "========================================"
Write-Host ""

# ── Customize these goals for your project ───────────────────────────────────
$Goals = @(
    @{
        Id       = "analyze_clean"
        Name     = "Static analysis: 0 errors"
        MaxScore = 25
        Check    = {
            try {
                # Customize: replace with your project's analyze command
                $result = & flutter analyze --no-fatal-infos 2>&1 | Select-String "error"
                if (-not $result) {
                    return @{ Score = 25; Detail = "No errors"; Status = "PASS" }
                }
                return @{ Score = 0; Detail = "Errors found"; Status = "FAIL" }
            } catch {
                return @{ Score = 0; Detail = "Command not available"; Status = "UNKNOWN" }
            }
        }
    },
    @{
        Id       = "tests_pass"
        Name     = "All tests passing"
        MaxScore = 25
        Check    = {
            try {
                $result = & flutter test --reporter compact 2>&1 | Select-String "All tests passed"
                if ($result) {
                    return @{ Score = 25; Detail = "All tests passed"; Status = "PASS" }
                }
                return @{ Score = 0; Detail = "Test failures"; Status = "FAIL" }
            } catch {
                return @{ Score = 0; Detail = "Command not available"; Status = "UNKNOWN" }
            }
        }
    },
    @{
        Id       = "phi_clean"
        Name     = "PHI scan: CLEAN"
        MaxScore = 25
        Check    = {
            $phiLog = Get-ChildItem "$LogDir\phi-scan-*.json" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($phiLog) {
                $data = Get-Content $phiLog.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($data.status -eq "CLEAN") {
                    return @{ Score = 25; Detail = "No PHI plaintext"; Status = "PASS" }
                }
                return @{ Score = 0; Detail = "PHI violations found"; Status = "FAIL" }
            }
            return @{ Score = 12; Detail = "No recent phi-scan log"; Status = "PARTIAL" }
        }
    },
    @{
        Id       = "sprint_completion"
        Name     = "Sprint completion rate ≥90%"
        MaxScore = 25
        Check    = {
            $total  = (git -C $ProjectRoot branch -r 2>$null | Where-Object { $_ -match "feature/" } | Measure-Object).Count
            $merged = (git -C $ProjectRoot branch -r --merged origin/develop 2>$null | Where-Object { $_ -match "feature/" } | Measure-Object).Count
            if ($total -gt 0) {
                $pct   = [Math]::Round($merged / $total * 100)
                $score = [Math]::Round($pct / 100 * 25)
                return @{ Score = $score; Detail = "$pct% ($merged/$total branches)"; Status = if ($pct -ge 90) { "PASS" } elseif ($pct -ge 60) { "PARTIAL" } else { "FAIL" } }
            }
            return @{ Score = 0; Detail = "No feature branches"; Status = "UNKNOWN" }
        }
    }
)
# ─────────────────────────────────────────────────────────────────────────────

$TotalScore  = 0
$MaxTotal    = 0
$GoalResults = @()

foreach ($Goal in $Goals) {
    Write-Host "[ Check ] $($Goal.Name)"
    try {
        $Result = & $Goal.Check
        $Score  = $Result.Score
        $Detail = $Result.Detail
        $Status = $Result.Status
    } catch {
        $Score  = 0
        $Detail = "Error: $($_.Exception.Message)"
        $Status = "ERROR"
    }

    $TotalScore += $Score
    $MaxTotal   += $Goal.MaxScore
    $Icon = switch ($Status) { "PASS" { "✅" } "PARTIAL" { "⚠️" } "FAIL" { "❌" } default { "❓" } }

    Write-Host "  $Icon $Status — $Score/$($Goal.MaxScore) ($Detail)"
    Write-Host ""
    $GoalResults += @{ id = $Goal.Id; name = $Goal.Name; score = $Score; max = $Goal.MaxScore; status = $Status; detail = $Detail }
}

$AchievementPct = [Math]::Round($TotalScore / $MaxTotal * 100)
Write-Host "========================================"
Write-Host " Total: $TotalScore/$MaxTotal ($AchievementPct%)"
Write-Host "========================================"

$GoalPayload = @{
    type            = "goals"
    timestamp       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    achievement_pct = $AchievementPct
    total_score     = $TotalScore
    max_score       = $MaxTotal
    goals           = $GoalResults
} | ConvertTo-Json -Depth 5

# POST to dashboard API (optional)
try {
    Invoke-RestMethod -Uri "$DashboardUrl/api/goals" -Method Post -ContentType "application/json" -Body $GoalPayload -TimeoutSec 3 -ErrorAction Stop | Out-Null
    Write-Host "[check-goals] Dashboard updated"
} catch {
    Write-Host "[check-goals] Dashboard offline — log saved locally"
}

$LogFile = Join-Path $LogDir "goals-$Timestamp.json"
$GoalPayload | Out-File -FilePath $LogFile -Encoding utf8

exit $(if ($AchievementPct -ge 80) { 0 } else { 1 })
