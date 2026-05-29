# Claude Code PreToolUse hook — block dangerous git commands before execution
# Based on Matt Pocock's git-guardrails pattern (github.com/mattpocock/skills)
# Exit code 2 = block, 0 = allow
param()

$raw  = [Console]::In.ReadToEnd()
$json = try { $raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
if (-not $json) { exit 0 }

$cmd = [string]($json.tool_input.command)
if (-not $cmd) { exit 0 }

$blocked = @(
    'git push --force',
    'git push -f ',
    'git push -f$',
    'git reset --hard',
    'git checkout \.',
    'git restore \.',
    'git clean -f',
    'git clean -fd',
    'git branch -D'
)

foreach ($pattern in $blocked) {
    if ($cmd -match $pattern) {
        $msg = @{
            decision = "block"
            reason   = "BLOCKED by git-guardrails: Dangerous git command detected ('$pattern'). Get explicit user confirmation before proceeding."
        }
        Write-Output ($msg | ConvertTo-Json -Compress)
        exit 2
    }
}

exit 0
