# Sync and Maintenance

The repository is dual-harness. `.claude/` is canonical; `.opencode/` is a
generated adapter. The rule for contributors is simple:

> Edit `.claude/`, then run the generator. Do not edit generated `.opencode/`
> agent, skill, or command files by hand.

## Commands

```bash
python3 tools/sync-opencode.py            # regenerate
python3 tools/sync-opencode.py --check    # CI check; non-zero when stale
python3 tools/sync-opencode.py --verbose  # list generated files
python3 tools/validate-opencode.py        # structural and policy validation
bun build .opencode/plugins/ccgs/index.ts --target=bun --outdir /tmp/ccgs-plugin
```

## What is generated

| Output | Source |
|---|---|
| `.opencode/agents/*.md` | `.claude/agents/*.md` plus the hand-written `studio` agent |
| `.opencode/skills/**` | `.claude/skills/**` |
| `.opencode/commands/*.md` | `.claude/skills/*/SKILL.md` |
| `.opencode/docs/agents-reference.md` | `.claude/agents/*.md` |
| `.opencode/docs/skills-reference.md` | `.claude/skills/*/SKILL.md` |

Everything else under `.opencode/` is hand-written: `plugins/`, `docs/` (except
the two generated reference tables), and the `studio` agent definition embedded
in the generator.

## What the generator changes

- Removes `name`, `model`, `maxTurns`, `disallowedTools`, `memory`, `skills`, and
  `isolation` from agent frontmatter; adds `mode`, `steps`, and permissions.
- Removes `argument-hint`, `user-invocable`, `allowed-tools`, `model`, and
  `disable-model-invocation` from skill frontmatter; adds
  `metadata.opencode/autoinvoke: false` where needed.
- Generates one command per skill, carrying `$ARGUMENTS`, the argument hint, and
  the skill's shell prelude.
- Rewrites Claude-specific vocabulary: `AskUserQuestion` → the `question` tool,
  the `Agent` tool → `subagent`, `CLAUDE.md` → `AGENTS.md`, and generated paths
  from `.claude/` to `.opencode/` where a generated counterpart exists.
- Keeps shared `.claude/` paths for scripts, hooks, rules, docs, and memory.

## Adding an agent

1. Add `.claude/agents/<name>.md` with the Claude frontmatter.
2. Run `python3 tools/sync-opencode.py`.
3. Run `python3 tools/validate-opencode.py`.
4. Test both harnesses.
5. Add a behavioral spec under `studio-tests/agents/` if the role is new.

## Adding a skill

1. Add `.claude/skills/<name>/SKILL.md` and any `references/`.
2. Run the generator; it creates both the OpenCode skill and the command.
3. Run the validator.
4. Add a spec under `studio-tests/skills/` if the workflow is new.

## Changing the OpenCode adapter

- **Agent conversion / command generation**: edit `tools/sync-opencode.py`.
- **Hooks**: edit `.opencode/plugins/ccgs/index.ts` (and the canonical script in
  `.claude/hooks/`).
- **Permissions**: edit `opencode.jsonc` and, if the posture is role-specific,
  the generator's mapping.
- **Docs**: edit `.opencode/docs/`.

## CI

`.github/workflows/validate.yml` runs the sync check and the OpenCode validator.
A pull request that changes `.claude/` without regenerating `.opencode/` fails.

## Conflict policy

If a hand edit to `.opencode/agents|skills|commands` conflicts with the
generator, the generated version wins. Move the change into `.claude/` or into
the generator. If you need an OpenCode-only skill, put it in a separate skills
source configured in `opencode.jsonc` rather than in `.opencode/skills/`.
