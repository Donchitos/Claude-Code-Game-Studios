# OpenCode Troubleshooting

## The studio agents or commands do not appear

- Start OpenCode at the repository root, where `opencode.jsonc` and `AGENTS.md`
  live.
- Run `/reload` or save `opencode.jsonc`; OpenCode watches config files.
- Check the adapter:

  ```bash
  python3 tools/sync-opencode.py --check
  python3 tools/validate-opencode.py
  ```

- Confirm `.opencode/agents/studio.md` and `.opencode/commands/start.md` exist.

## A slash command runs but the skill is not loaded

The command asks the model to load the skill with the `skill` tool. If the model
skips that step:

- Check that the skill ID matches the directory name.
- Check the selected agent's `skill` permission. The generated subagents allow
  skills; a custom agent may not.
- Try naming the skill directly in the prompt: `@skill-id`.

## The model cannot edit files

The model must support tool calling. A model that only emits text can plan but
cannot run `/dev-story` or any write workflow. Switch to a tool-capable model and
re-run `/models`.

## Hooks do not run

- Confirm `.opencode/plugins/ccgs/index.ts` and its `package.json` exist.
- Check the OpenCode log at `~/.local/share/opencode/log/opencode.log` for
  `ccgs` errors.
- For an event/hook trace, run a private server with debug enabled:

  ```bash
  rm -f /tmp/ccgs-debug.log
  CCGS_DEBUG=1 opencode --standalone run --model <provider/model> "reply OK"
  cat /tmp/ccgs-debug.log
  ```
- Build the plugin to catch syntax errors:

  ```bash
  bun build .opencode/plugins/ccgs/index.ts --target=bun --outdir /tmp/ccgs-plugin
  ```

- Hooks run from the project root. If `git` or `bash` is missing, the scripts
  fail open and only lose validation.

## A commit or read is blocked unexpectedly

The canonical hook scripts print the reason. Run the same script directly:

```bash
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}' \
  | bash .claude/hooks/validate-commit.sh
```

The rules live in `.claude/hooks/` and the settings that trigger them live in
`.claude/settings.json` for Claude Code and the plugin for OpenCode.

## Subagents cannot spawn specialists

OpenCode's default nesting depth is 1. `opencode.jsonc` sets
`experimental.subagent_depth` to 3. If you removed it, restore it. Higher depth
costs more tokens and is easier to loop; keep it at 3 unless you have a reason.

## The model runs out of context

- Use one workflow at a time and rely on `production/session-state/active.md`.
- Read design docs by section; `validate-read.sh` refuses whole-file reads over
  40 KB.
- Disable unused engine agents (see `opencode-setup.md`).
- Lower `tool_output` limits in `opencode.jsonc`.
- Use a model with 64k+ context for `/review-all-gdds`, `/architecture-review`,
  and `/gate-check`.

## A generated file is stale

```bash
python3 tools/sync-opencode.py
```

Do not hand-edit `.opencode/agents/`, `.opencode/skills/`, or
`.opencode/commands/`. The next generator run replaces them.

## Claude Code and OpenCode disagree

Both harnesses share `.claude/scripts`, `.claude/hooks`, `.claude/rules`, and
`.claude/docs`. If behavior diverges, compare the event mapping in
`hooks-reference.md` and the permission rules in `permissions.md`. The generated
layer is the only thing that should differ.

## Reporting a problem

Include:

- Harness and version (`opencode --version` or `claude --version`)
- Model and provider
- The command or skill
- The failing tool call and the error text
- Whether `python3 tools/validate-opencode.py` passes
