---
description: 일일 오케스트레이터. standup → sentinel 점검 → goal 체크 → 문서 동기화 순서로 실행.
allowed-tools: Bash(*), Glob(**), Grep(**), Read(**), Agent, Write(.claude/logs/*)
---

# /maintenance — Daily Maintenance Orchestrator

Runs the full daily maintenance pipeline. Designed for daily cron or morning kickoff.

## Pipeline

### Step 1: Standup
Run `/standup` — output yesterday/today/blockers summary.

### Step 2: Sentinel check (parallel, if repos exist)
Run analyze + test across all active repos simultaneously:
```bash
# Per repo:
flutter analyze --no-fatal-infos 2>&1 | tail -5
flutter test --reporter compact 2>&1 | tail -5
```
Report: PASS/FAIL per repo, error counts.

### Step 3: Goal achievement check
```bash
pwsh -NoProfile -NonInteractive -File .claude/automation/check-goals.ps1
```
Output: achievement % + action items.

### Step 4: PHI scan
```bash
bash .claude/automation/phi-scan.sh 2>/dev/null || echo "No phi-scan.sh found"
```

### Step 5: Stale branch cleanup
```bash
git branch --merged origin/develop | grep "feature/" | head -10
```
List merged feature branches that can be deleted. Don't delete — just list.

### Step 6: Discord notification (if webhook configured)
```bash
bash .claude/automation/discord-notify.sh "maintenance" "$OVERALL_STATUS" "$SUMMARY"
```

## Output format
```
## Daily Maintenance — YYYY-MM-DD HH:MM

### Standup
[standup output]

### Sentinel
| Repo | Status | Errors |
|---|---|---|
| src/ | ✅ PASS | 0 |

### Goals
Achievement: 87% (3/4 goals met)

### PHI Scan
✅ CLEAN — no plaintext PHI detected

### Stale branches
  feature/old-auth (merged 5 days ago)
```
