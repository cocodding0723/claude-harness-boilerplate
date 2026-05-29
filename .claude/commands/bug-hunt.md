---
description: 병렬 버그 탐지 → 자동수정 루프 → 이슈 생성 (해결 불가 시). 3개 분석 에이전트 동시 실행.
allowed-tools: Bash(*), Glob(**), Grep(**), Read(**), Agent, Write(.claude/logs/*)
---

# /bug-hunt — Parallel Bug Detection + Auto-fix Loop

Runs 3 parallel finders, auto-fixes what it can, creates issues for the rest.

## Steps

### 1) Scope
```bash
git diff --name-only origin/main..HEAD
```
If no changes: scan entire `src/` or `lib/`.

### 2) Parallel 3-finder agents (single message)

**Finder A — Static analysis**
```
Scope: changed files or src/lib
1. Run project linter (flutter analyze / tsc / eslint)
2. Report: error list, file:line, severity. 300 tokens max.
```

**Finder B — Logic bugs**
```
Scope: changed files
1. Look for: null dereferences, off-by-one, unhandled async errors, missing null checks
2. Report: bug description, file:line, fix suggestion. 300 tokens max.
```

**Finder C — Security / PHI**
```
Scope: changed files
1. Look for: PHI plaintext, hardcoded secrets, SQL injection, SSRF
2. Report: violation, file:line, severity (CRITICAL/HIGH/MEDIUM). 300 tokens max.
```

### 3) Dedup + prioritize
Merge results from A+B+C. Sort by: CRITICAL → HIGH → MEDIUM → LOW.

### 4) Auto-fix loop (max 3 rounds per bug)
For each bug:
```
1. Delegate to appropriate agent (build-resolver for analyze errors, fe/be-agent for logic)
2. Run verify step (flutter analyze / tsc / test)
3. If PASS → mark fixed
4. If FAIL after 3 rounds → mark as unresolved
```

### 5) Commit fixed bugs
```bash
git add <fixed files>
git commit -m "fix: bug-hunt auto-fix $(date +%Y-%m-%d)"
```

### 6) Create issues for unresolved bugs
For each unresolved bug: create a Jira/GitHub issue with:
- Bug description
- File:line reference
- Steps to reproduce (if determinable)
- Severity label

## Output format
```
## Bug Hunt Report — YYYY-MM-DD HH:MM

| Bug | File | Severity | Status |
|---|---|---|---|
| Null check missing | auth_service.dart:42 | HIGH | ✅ Fixed |
| PHI plaintext | user_repo.dart:87 | CRITICAL | ✅ Fixed |
| Off-by-one | session_timer.dart:23 | LOW | ⏭️ Skipped |

Fixed: 2 | Unresolved: 0 | Skipped: 1
```
