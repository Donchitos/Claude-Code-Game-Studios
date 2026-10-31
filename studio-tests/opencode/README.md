# OpenCode Adapter Tests

The canonical behavioral specs live in `studio-tests/skills/` and
`studio-tests/agents/`. This folder covers the generated OpenCode layer: the
conversion, the commands, the permissions, and the plugin.

## Automated checks

Run from the repository root:

```bash
python3 tools/sync-opencode.py --check
python3 tools/validate-opencode.py
bun build .opencode/plugins/ccgs/index.ts --target=bun --outdir /tmp/ccgs-plugin
```

`tools/sync-opencode.py --check` fails when `.opencode/agents`, `.opencode/skills`,
or `.opencode/commands` differ from what the canonical `.claude/` sources would
generate.

`tools/validate-opencode.py` checks:

- 50 agents (49 subagents + `studio`), 74 skills, 74 commands
- agent frontmatter: `mode: subagent`, numeric `steps`, permissions, no Claude
  model or tool fields
- skill frontmatter: no `model`, `allowed-tools`, `argument-hint`, or
  `user-invocable`; `opencode/autoinvoke: false` on the five internal skills
- every command names its skill and passes `$ARGUMENTS`
- no `AskUserQuestion`, `CLAUDE_SKILL_DIR`, or Claude model pins in the adapter
- required OpenCode docs and plugin files exist

## Manual smoke test

`smoke.md` is the human checklist for a release. It covers both harnesses so a
change to the shared hooks cannot silently break Claude Code.

## What is not covered

- **Per-skill tool enforcement**: OpenCode permissions are agent-level. The
  generated skills document their intended posture; the safety plugin blocks the
  critical cases.
- **Notifications and agent transcript audit**: not ported.
- **Status line**: OpenCode has its own display.

These gaps are documented in `.opencode/docs/hooks-reference.md` and
`.opencode/docs/permissions.md`.
