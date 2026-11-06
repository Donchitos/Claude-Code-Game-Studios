# CLAUDE.local.md Template
# CLAUDE.local.md 模板

Copy this file to the project root as `CLAUDE.local.md` for personal overrides.
将此文件复制到项目根目录并命名为 `CLAUDE.local.md`，用于个人覆盖配置。
This file is gitignored and will not be committed.
此文件已被 gitignore 忽略，不会被提交。

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
## 设置

1. Copy this template to your project root: `cp .claude/docs/CLAUDE-local-template.md CLAUDE.local.md`
1. 将此模板复制到你的项目根目录：`cp .claude/docs/CLAUDE-local-template.md CLAUDE.local.md`
2. Edit to match your preferences
2. 编辑以匹配你的偏好
3. Verify `CLAUDE.local.md` is in `.gitignore` (Claude Code reads it from the project root)
3. 验证 `CLAUDE.local.md` 已包含在 `.gitignore` 中（Claude Code 会从项目根目录读取它）
