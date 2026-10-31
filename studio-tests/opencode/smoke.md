# Dual-Harness Smoke Test

Run before a release that touches `.claude/`, `.opencode/`, or the plugin.

## Static

- [ ] `python3 tools/sync-opencode.py --check` passes
- [ ] `python3 tools/validate-opencode.py` passes
- [ ] `bun build .opencode/plugins/ccgs/index.ts --target=bun --outdir /tmp/ccgs-plugin` succeeds
- [ ] `bash -n` passes for every `.claude/hooks/*.sh` and `.claude/scripts/*.sh`
- [ ] `opencode debug agents` lists `studio` as primary and 49 subagents
- [ ] `opencode plugin list` shows `ccgs` as a local plugin
- [ ] `opencode debug config` shows `default_agent: studio` and the three
      instruction files

## OpenCode runtime

- [ ] `opencode` starts at the repository root without config errors
- [ ] `/start` runs and asks where the user is
- [ ] `/help` runs and lists the workflow catalog
- [ ] a representative command (`/sprint-status`, `/project-stage-detect`, or
      `/balance-check`) loads its skill and runs its helpers
- [ ] a command with a shell prelude (`/help` or `/project-stage-detect`) shows
      the resolved `workflow` / `project.stage` values in the submitted prompt
- [ ] a subagent spawn works (`/design-review` or a direct `subagent` request)
- [ ] the session-start context appears in a new session
- [ ] after compaction, the session-state checkpoint is restored

## Safety

- [ ] a staged hardcoded gameplay value blocks `git commit`
- [ ] a force-push command is denied by permissions
- [ ] reading a `.env` file is denied
- [ ] a whole-file read of a design doc over 40 KB is refused and returns headings
- [ ] editing `.opencode/agents/` by hand is denied
- [ ] editing a canonical skill triggers the `skill-test` advisory
- [ ] editing a data JSON file with invalid JSON is fed back to the model
- [ ] writing to an entity registry that deletes or renumbers an entry warns

## Claude Code regression

- [ ] `claude` starts at the repository root
- [ ] `/start` and a representative command still work
- [ ] the commit, push, read, and write hooks still fire
- [ ] `.claude/settings.json` still points at `.claude/hooks/`

## Open-model sanity

- [ ] a tool-capable local model can list files, read a section, and write a file
- [ ] the model does not drown in the agent/skill catalog at 32k context
- [ ] a model without tool calling is documented as unable to run editing workflows
