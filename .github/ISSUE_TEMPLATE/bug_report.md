---
name: Bug Report
about: Report incorrect framework behavior
title: "[Bug] "
labels: bug
assignees: ''
---

## Description

Describe the incorrect behavior and why it matters.

## Steps To Reproduce

1. Open Codex at the root of a project created from this template.
2. If hooks are involved, state whether the project was trusted.
3. Run `$skill-name`, request a role-profile delegation, or trigger the hook.
4. Record the observed result.

## Expected Behavior

What should have happened?

## Actual Behavior

Include relevant error output with secrets and private project data removed.

## Environment

- **OS**:
- **Shell**:
- **Codex CLI version** (`codex --version`):
- **Git version** (`git --version`):
- **Bash version** (`bash --version`, if hooks are affected):
- **Project hooks trusted?**: Yes / No / Not applicable

## Affected Component

- [ ] `skills/<name>/SKILL.md`
- [ ] `skills/<name>/agents/openai.yaml`
- [ ] `roles/<name>.md`
- [ ] `.codex/hooks.json` or `hooks/`
- [ ] `AGENTS.md` or nested instructions
- [ ] Studio documentation or template
- [ ] `.codex-plugin/plugin.json`
- [ ] Other:

## Additional Context

Provide the smallest reproducible repository state, screenshot, or sanitized
hook payload that demonstrates the issue.
