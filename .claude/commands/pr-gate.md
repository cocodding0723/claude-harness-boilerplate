---
description: PR 직전 3개 검수 에이전트(리뷰·QA·보안)를 병렬 호출해 PASS/FAIL 판정. 모두 PASS여야 PR 생성 가능.
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Task
---

# /pr-gate — Parallel PR Quality Gate

Run before every PR. **All gates must PASS** before creating the PR.

## Steps

### 1) Change summary
```bash
git fetch origin
CURRENT=$(git rev-parse --abbrev-ref HEAD)
BASE_BRANCH=$(git rev-parse --verify origin/develop 2>/dev/null && echo "origin/develop" || echo "origin/main")
git diff --stat $(git merge-base HEAD $BASE_BRANCH)..HEAD
git log --oneline $(git merge-base HEAD $BASE_BRANCH)..HEAD
```
- Zero changes → abort
- 30+ files changed → recommend splitting PR, then block

### 2) Pre-check
Run analyze + tests first. If either fails, stop and fix before proceeding:
```bash
# Dart/Flutter projects:
flutter analyze --no-fatal-infos
flutter test
# Node/TypeScript:
npx tsc --noEmit
npm test
```

### 3) **Parallel 3-agent call — single message**

| Agent | subagent_type | Model | Responsibility |
|---|---|---|---|
| Code Review | `everything-claude-code:flutter-reviewer` OR `everything-claude-code:typescript-reviewer` | sonnet | Idioms, DDD layers, patterns |
| QA | `.claude/agents/qa-agent` | haiku | analyze + test + PHI/secret audit |
| Security | `everything-claude-code:security-reviewer` | opus | PHI plaintext, HMAC bypass, OWASP, security invariants |

Each agent input:
- Changed file list
- "Output ≤500 tokens, PASS/FAIL + ≤3 blockers"

### 4) Result aggregation + REQUEST_CHANGES loop (max 3)

```
Loop (attempt=1, max=3):
  Extract blockers from FAIL gates
  → Delegate fix to appropriate agent (fe/be/build-resolver)
  → Re-check only FAIL gates after fix
  → Break on PASS
  → After 3 tries: create issue + block PR
```

```
## PR Gate Verdict — feature/xxx

| Gate         | Verdict       | Attempt | Blockers |
|---|---|---|---|
| Code Review  | PASS / FAIL   | 1/3     | N        |
| QA           | PASS / FAIL   | 1/3     | N        |
| Security     | PASS / FAIL   | 1/3     | N        |

**Overall**: PASS / FAIL

### Next steps
- All PASS: `gh pr create --base develop` recommended
- FAIL after 3 tries: create issue + block PR
```

## Token budget
- Each agent: 500 tokens max
- 30+ changed files → force split PR
- security-reviewer: changed files only (no full scan)
