# Claude Code Game Studios with Codex

Open the repository root in Codex. On Windows, install Git and PowerShell 7
(`pwsh`) and make them available on `PATH`. In the CLI, start `codex` from the
directory containing `AGENTS.md` and `project.yaml`. Grant project trust to
load repository-level Codex settings and hook definitions.

- Use `$start` for guided onboarding or `$next-step` for the current project's
  next step. Use `$project-settings` for the studio's settings workflow.
- Pick a named role from the [agent roster](../.claude/docs/agent-roster.md)
  when asking Codex to delegate to a specialist.
- To review the optional session hook in the CLI, run `/hooks`. Trust the
  current definition if you want the startup context in subsequent sessions.

The checked-in entries under `.agents/skills/` and `.codex/agents/` are ready
to load. Their instructions point to the shared `.claude/skills/` and
`.claude/agents/` sources. `AGENTS.md` maps the workflow vocabulary and points
to `.claude/rules/` for path-specific guidance. Codex uses its own permission
and tool settings.

## Workflow commands

Run these examples from the repository root in PowerShell 7.

```powershell
pwsh -NoProfile -File .codex/scripts/resolve-config.ps1
pwsh -NoProfile -File .codex/scripts/resolve-config.ps1 -Keys 'project.stage,workflow,review_mode'
```

When a workflow requests `resolve_config` in a Claude `!` command block, run
the PowerShell resolver with the same keys in `-Keys`. Pass a system name in
`-System` when the workflow resolves a per-system tier. Use the returned values
and their sources, then apply any explicit flags from the user. `-Keys`
accepts the labels in the configuration reference, plus `framework_version`,
`performance.enforce`, and `cert_tier` (also `platform.cert_tier`). For
resolution order, allowable local overrides, and tier defaults, see the
[configuration reference](../.claude/docs/config-resolution.md).
The reader handles the studio's indented mappings, scalar values, and flat
lists in `project.yaml` and `project.local.yaml`.

Use the canonical workflow's fallback for other Claude command blocks and
helpers. For `$start`, inspect the listed project files directly when gathering
project facts. When the user approves a settings write, follow the setting's
schema and provenance rules and patch the approved keys in `project.yaml` or
`project.local.yaml`. For stage changes, update `project.stage` and
`production/stage.txt` together and read back both values before reporting
success. The [settings schema](../.claude/docs/effects-map.md) describes the
accepted values and storage locations.

Engine builds and test runs use the engine's installed toolchain. When a
workflow requires a shell helper without a native equivalent, report the
missing result and keep any dependent gate pending. Claude-specific command
injection, tool permissions, write guards, and lifecycle logging require
their original Claude Code runtime.

## Session start hook

The optional `.codex/hooks.json` hook runs on `SessionStart` after project and
hook trust are granted. It adds the effective stage, automation mode, and
review mode to the session. It reads from disk and needs `pwsh` and Git on
`PATH`. The `resolve-config.ps1` command is available independently of hook
trust.

For Codex project loading and trust, see the official documentation.
[Skills](https://learn.chatgpt.com/docs/build-skills), [subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents), [hooks](https://learn.chatgpt.com/docs/hooks).

## Updating and testing

Edit the canonical workflow or role first. Then refresh the generated entries
and run the checks from the repository root.

```powershell
pwsh -NoProfile -File .codex/scripts/sync-adapter.ps1
pwsh -NoProfile -File .codex/scripts/sync-adapter.ps1 -Check
pwsh -NoProfile -File .codex/scripts/test-adapter.ps1
```

`-Check` reports missing, changed, and stale generated files without rewriting
them. The test script exercises the adapter without a model login. A live
Codex smoke test can also invoke `$next-step` in a fresh session and confirm
that it reads the canonical workflow and reports the project's next step.
