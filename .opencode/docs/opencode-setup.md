# OpenCode Setup

This repository works in two harnesses:

| Harness | Entry point | Agent layer | Hooks |
|---|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/agents/` | `.claude/settings.json` → `.claude/hooks/` |
| OpenCode | `AGENTS.md` | `.opencode/agents/` | `.opencode/plugins/ccgs/` → `.claude/hooks/` |

`.claude/` is the canonical source. `.opencode/` is generated from it. Both use
the same shared scripts, rules, docs, and templates.

## Install and start

1. Install OpenCode V2 from <https://opencode.ai/v2/docs/>.
2. Open a terminal at the repository root — the folder holding `AGENTS.md`,
   `opencode.jsonc`, and `project.yaml`.
3. Start OpenCode:

   ```bash
   opencode
   ```

4. Connect a provider with `/connect` and choose a model with `/models`. The
   studio does not pin one. Do this before the first prompt: with no model
   selected, OpenCode falls back to a catalog default that may not be available
   in your account. See `model-selection.md`.
5. Run `/start`.

Starting in a subfolder such as `src/` still discovers the parent config, but
the cleanest experience is to start at the root so `AGENTS.md` and the project
instructions load together.

## What `/start` sets

`/start` asks where you are starting from, infers a `modes.rigor` value, and
writes `project.yaml` plus `production/stage.txt`. It never runs the next
workflow for you. It is safe to decline the write: the values are kept for the
current run.

The six knobs behind rigor (`modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity`, `modes.review_mode`, `team.size`) stay absent from
`project.yaml` until you set one explicitly. `/settings` changes any of them.

## Configuration files

| File | Purpose |
|---|---|
| `opencode.jsonc` | Default agent, instructions, permissions, subagent depth, model examples |
| `AGENTS.md` | OpenCode master instructions (the counterpart of `CLAUDE.md`) |
| `project.yaml` | Project settings consumed by both harnesses |
| `.opencode/agents/` | Generated subagents and the `studio` primary agent |
| `.opencode/skills/` | Generated workflow skills |
| `.opencode/commands/` | Generated slash commands |
| `.opencode/plugins/ccgs/` | Hook adapter and path-rule injection |
| `.opencode/docs/` | OpenCode-specific guidance |

## Which agent am I?

`studio` is the default primary agent. It is a thin orchestrator: it follows
`AGENTS.md`, delegates with the `subagent` tool, and loads workflows through the
slash commands. The built-in `build` agent also works; commands inherit whichever
primary agent is selected.

All 49 specialists are subagents. You normally reach them through a workflow
(`/design-review` spawns the reviewers, `/team-combat` spawns the combat team)
rather than by switching to them manually.

## Disabling engine agents

The template ships Godot, Unity, and Unreal specialists. To hide the sets you do
not use, add `disabled: true` entries in `opencode.jsonc`:

```jsonc
{
  "agents": {
    "unity-specialist": { "disabled": true },
    "unity-dots-specialist": { "disabled": true },
    "unity-shader-specialist": { "disabled": true },
    "unity-addressables-specialist": { "disabled": true },
    "unity-ui-specialist": { "disabled": true },
    "unreal-specialist": { "disabled": true },
    "ue-gas-specialist": { "disabled": true },
    "ue-replication-specialist": { "disabled": true },
    "ue-umg-specialist": { "disabled": true },
    "ue-blueprint-specialist": { "disabled": true }
  }
}
```

This reduces the subagent catalog and the context cost of choosing an agent.

## Updating the adapter

After editing a canonical agent or skill:

```bash
python3 tools/sync-opencode.py
python3 tools/validate-opencode.py
```

CI runs `python3 tools/sync-opencode.py --check` and fails if the committed
adapter is stale. See `sync-and-maintenance.md`.

## Personal overrides

OpenCode has no project-local config file equivalent to Claude Code's
`settings.local.json`. Use one of:

- The global config at `~/.config/opencode/opencode.json(c)` for personal
  defaults.
- `OPENCODE_CONFIG_CONTENT` for ephemeral overrides.
- A separate `opencode.jsonc` in a parent directory for a workspace-wide setup.

Project settings that are not harness-specific (rigor, review mode, automation)
belong in `project.yaml` or the gitignored `project.local.yaml`.
