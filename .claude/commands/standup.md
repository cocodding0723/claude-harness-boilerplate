---
description: 일일 스탠드업. git log + 미완료 태스크 + 블로커를 3분 이내로 요약.
allowed-tools: Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(git diff:*)
---

# /standup — Daily Standup

Generates a concise standup summary from git history and working tree state.

## Steps

### 1) Yesterday's work
```bash
git log --oneline --since="yesterday" --all --author="$(git config user.email)"
git log --oneline --since="1 day ago" --all
```

### 2) Today's plan
```bash
git stash list
git branch --list "feature/*" --sort=-committerdate | head -5
git status --short
```

### 3) Blockers
Check for:
- Uncommitted changes older than 4 hours (git status + file mtimes)
- Failed CI (check `.claude/logs/sentinel-*.json` if available)
- Dependency issues (pubspec.lock / package-lock.json conflicts)

## Output format
```
## Daily Standup — YYYY-MM-DD

### Yesterday ✅
- feat: implemented QR scan flow (KAN-34)
- fix: resolved null-check in session timer (KAN-35)

### Today 🎯
- [ ] KAN-36: Implement session history screen
- [ ] KAN-37: Wire up Firebase session listener

### Blockers 🚧
- None

### Branch status
  feature/ge-qr-scan → 3 commits ahead of develop
  feature/ge-session → WIP (2 uncommitted files)
```
