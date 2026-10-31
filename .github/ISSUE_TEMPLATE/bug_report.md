---
name: Bug Report
about: Something isn't working as expected
title: "[Bug] "
labels: bug
assignees: ''
---

## Description

A clear description of what the bug is.

## Steps to Reproduce

1. Open Claude Code or OpenCode in a project using this template
2. Run `/<skill>` or trigger `<agent>`
3. ...
4. See error

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened. Include any error messages or unexpected output.

## Environment

- **Harness**: Claude Code / OpenCode
- **Harness version**: (run `claude --version` or `opencode --version`)
- **Provider / model**: (for OpenCode, include the `provider/model` if relevant)
- **OS**: (e.g., Windows 10, macOS 14, Ubuntu 24.04)
- **Shell**: (e.g., Git Bash, zsh, bash)
- **Node.js version**: (run `node --version`)
- **jq installed?**: Yes / No
- **Python installed?**: Yes / No

## Generated Adapter

- [ ] `python3 tools/sync-opencode.py --check` passes
- [ ] `python3 tools/validate-opencode.py` passes
- [ ] The issue also reproduces with the canonical `.claude/` layer (Claude Code)

## Affected Component

- [ ] Agent (which one?):
- [ ] Skill (which one?):
- [ ] Command (which one?):
- [ ] Hook (which one?):
- [ ] Rule (which one?):
- [ ] OpenCode plugin
- [ ] Template
- [ ] Documentation
- [ ] Other:

## Additional Context

Any other context — screenshots, terminal output, or the session log if relevant.
