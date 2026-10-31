## Summary

Brief description of what this PR does.

## Type of Change

- [ ] New agent
- [ ] New skill
- [ ] New hook or rule
- [ ] OpenCode adapter / open-model support
- [ ] Bug fix
- [ ] Documentation improvement
- [ ] Other:

## Changes

-
-
-

## Checklist

- [ ] I've tested this in a Claude Code session
- [ ] I've tested this in an OpenCode session (or the change is Claude-only)
- [ ] New agents include the Collaboration Protocol section
- [ ] New skills use the subdirectory format (`.claude/skills/<name>/SKILL.md`)
- [ ] I ran `python3 tools/sync-opencode.py`
- [ ] `python3 tools/sync-opencode.py --check` passes
- [ ] `python3 tools/validate-opencode.py` passes
- [ ] Reference docs are updated (agent-roster, skills-reference, hooks-reference, rules-reference)
- [ ] Hooks use `grep -E` (POSIX) and fail gracefully without jq/python
- [ ] No hardcoded paths or platform-specific assumptions
- [ ] No model pins were added to the generated OpenCode layer
