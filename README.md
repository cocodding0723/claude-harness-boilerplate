# Claude Code Harness Boilerplate

Production-ready Claude Code harness for any software project.
Zero-config start — copy, rename placeholders, and ship.

## What's included

```
.claude/
├── settings.json          # Permissions, env vars, hooks wiring
├── settings.local.json    # Secrets (gitignored)
├── hooks/
│   ├── notify.ps1         # Windows toast on file change
│   ├── notify-stop.ps1    # Session end: toast + Jira comment + git check
│   ├── git-commit-jira.ps1 # Auto Jira transition + comment on commit
│   └── pre-compact.ps1    # Context snapshot before compaction
├── commands/
│   ├── pr-gate.md         # 3-agent parallel PR quality gate
│   ├── bug-hunt.md        # Parallel bug detection + auto-fix loop
│   ├── standup.md         # Daily standup from git log
│   ├── e2e-check.md       # E2E + UI/UX automated check
│   └── maintenance.md     # Daily orchestrator
├── agents/
│   ├── qa-agent.md        # Test writing + PHI/secret audit
│   └── review-agent.md    # Code review + spec conformance
└── automation/
    ├── check-goals.ps1    # Goal achievement tracker
    ├── dashboard-log.sh   # Append log to dashboard API
    └── discord-notify.sh  # Discord webhook notifier
CLAUDE.md                  # Project instructions template
```

## Quick start

```bash
# 1. Copy into your project root
cp -r claude-harness-boilerplate/.claude ./
cp claude-harness-boilerplate/CLAUDE.md ./

# 2. Fill in secrets (never commit this file)
cp .claude/settings.local.json.example .claude/settings.local.json
# Edit settings.local.json with your tokens

# 3. Add to .gitignore
echo ".claude/settings.local.json" >> .gitignore

# 4. Customize CLAUDE.md for your project
# Replace all {{PLACEHOLDER}} values

# 5. Start Claude Code
claude
```

## Customization

### settings.json
- `env` section: add project-specific env vars (no secrets)
- `permissions.allow`: add commands your project needs
- `permissions.deny`: add files that should never be modified

### CLAUDE.md
- Replace `{{PROJECT_NAME}}`, `{{TECH_STACK}}`, `{{TEAM_AGENTS}}`
- Add your DDD / architecture rules
- Define your slash command routing

### Hooks
All hooks use env vars for secrets — never hardcode tokens.
Set in `settings.local.json`:
```json
{
  "env": {
    "JIRA_API_TOKEN": "your-token",
    "DISCORD_WEBHOOK_URL": "https://discord.com/api/webhooks/..."
  }
}
```

## Platform support

| Feature | Windows | macOS/Linux |
|---|---|---|
| Toast notifications | ✅ (notify.ps1) | ❌ (replace with `osascript` / `notify-send`) |
| Jira integration | ✅ | ✅ |
| Git hooks | ✅ | ✅ |
| Discord notify | ✅ (bash.exe) | ✅ |

## License

MIT
