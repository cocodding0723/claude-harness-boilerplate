# {{PROJECT_NAME}} — Claude Code Harness

{{PROJECT_DESCRIPTION}}

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | {{FRONTEND}} |
| Backend | {{BACKEND}} |
| Database | {{DATABASE}} |
| CI/CD | {{CI_CD}} |

## Repository Structure

```
{{REPO_STRUCTURE}}
```

## Agent Team

| Agent | Role | Model | Scope |
|---|---|---|---|
| `codegen-agent` | Scaffold generation | sonnet | Spec → boilerplate code |
| `qa-agent` | Test writing + PHI audit | haiku | Interface + existing tests |
| `review-agent` | Code review + spec check | sonnet | git diff + spec |
| `be-agent` | Backend (functions, DB rules) | sonnet | functions/ + rules |
| ECC `security-reviewer` | Security / PHI audit | opus | Changed files only |
| ECC `dart-build-resolver` | Build error auto-fix | haiku | Error files only |

**Token economy:**
- 1–5 line fixes: no agent, direct edit
- Simple bugs: haiku / General impl: sonnet / Architecture+Security: opus
- Each agent loads only its layer's files (no full codebase)

## Development Strategy

### Feature mini-sprint (per worktree)

```
1. Spec check      Read spec section for this feature + related ADRs
2. Mock impl       Start with MockRepository (no external deps)
3. TDD first       qa-agent: write failing tests before implementation
4. Implement       fe/be-agent: make tests pass
5. Run tests       Failure → dart-build-resolver (max 3 loops)
6. Conformance     review-agent: spec + DDD + layer check
7. PR              feature/* → develop (CI must pass)
```

## Slash Commands

| Command | Description |
|---|---|
| `/pr-gate` | Pre-PR: flutter-reviewer + qa-agent + security-reviewer **parallel** |
| `/bug-hunt [scope]` | Parallel bug detection → auto-fix loop → issue creation |
| `/standup` | Daily: git log + open tasks + blockers |
| `/e2e-check` | Emulator touch test + Playwright responsive UI/UX check |
| `/maintenance` | Daily orchestrator: standup → sentinel → goal check → doc sync |

## Coding Principles

1. **Think before coding** — State assumptions, ask if ambiguous. Never guess silently.
2. **Simplicity first** — No unrequested features, flexibility, or error handling.
3. **Surgical changes** — Clean only your own changes. No adjacent refactors.
4. **Goal-driven** — Define success criteria (test/verify steps) before starting.
5. **TDD first** — Write tests before implementation. No untested PR merges.

## Security Invariants

- PHI (name, phone, DOB, diagnosis) must be encrypted at rest. Never store plaintext.
- No secrets in git (`*.key`, `.env`, `serviceAccount*.json`, `google-services.json`)
- Crash reporters: never log user IDs or PHI
- API signatures: HMAC-SHA256, timestamp ±5 min validity

## Git Policy

```
main ← develop ← feature/<scope>-<desc>
                  hotfix/<desc>
```

- No direct push to `main`
- `feature/*` → `develop` PR (CI must pass)
- Commit format: `feat(scope): ISSUE-XX <description>`
- `git push --force` prohibited on all branches

## Natural Language Routing

| User intent | Route |
|---|---|
| "PR ready", "review this" | `/pr-gate` |
| "find bugs", "something broken" | `/bug-hunt` |
| "what did we do today" | `/standup` |
| "test the UI", "check screens" | `/e2e-check` |
| "daily check", "maintenance run" | `/maintenance` |
| Build errors, analyze failures | ECC `dart-build-resolver` (haiku) |
| Security review, PHI check | ECC `security-reviewer` (opus) |
| Code review | ECC `flutter-reviewer` (sonnet) |
| 1–5 line fix (typo, format) | Direct edit, no routing |

## Forbidden

- `git push --force` (all branches)
- Plaintext PHI in any database
- Editing auto-generated files (e.g. `*.g.dart`)
- Sequential agent calls when parallel is possible
- `domain` layer importing external dependencies (Firebase, HTTP, etc.)
