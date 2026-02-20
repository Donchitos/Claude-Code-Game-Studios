# CLAUDE.local.md Template

Copy this file to the project root as `CLAUDE.local.md` for personal overrides.
This file is gitignored and will not be committed.

```markdown
# Personal Preferences

## Model Preferences
- Prefer Opus for complex design tasks
- Use Haiku for quick lookups and simple edits

## Workflow Preferences
- Always run tests after code changes
- Compact context proactively at 60% usage
- Use /clear between unrelated tasks

## Local Environment
- Python command: python (or py / python3)
- Shell: Git Bash on Windows
- IDE: VS Code with Claude Code extension

## Communication Style
- Keep responses concise
- Show file paths in all code references
- Explain architectural decisions briefly

## Personal Shortcuts
- When I say "review", run /code-review on the last changed files
- When I say "status", show git status + sprint progress
```

## Setup

1. Copy this template to your project root: `cp .claude/docs/CLAUDE-local-template.md CLAUDE.local.md`
2. Edit to match your preferences
3. Verify `CLAUDE.local.md` is in `.gitignore` (Claude Code reads it from the project root)
