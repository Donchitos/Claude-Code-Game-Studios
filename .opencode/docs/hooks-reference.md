# Hooks Reference (OpenCode)

OpenCode does not use `.claude/settings.json`. The adapter in
`.opencode/plugins/ccgs/` subscribes to OpenCode events and invokes the canonical
scripts in `.claude/hooks/`. The scripts are unchanged, so both harnesses run the
same validation logic.

## Mapping

| Canonical hook | Claude event | OpenCode event | Blocking? |
|---|---|---|---|
| `session-start.sh` | SessionStart | `session.prompt` hook, `session.context` hook, `session.compaction.ended` | no — injects context |
| `detect-gaps.sh` | SessionStart | the same prompt/context load | no — injects advisories |
| `pre-compact.sh` | PreCompact | `session.compaction.started` | no — writes a log entry |
| `session-stop.sh` | Stop | `session.execution.succeeded/failed/interrupted`, `session.idle` | no — archives state |
| `validate-commit.sh` | PreToolUse (Bash) | `tool.execute.before` (shell), `permission.evaluate` | **yes** |
| `validate-push.sh` | PreToolUse (Bash) | `tool.execute.before` (shell), `permission.evaluate` | **yes** |
| `validate-read.sh` | PreToolUse (Read) | `tool.execute.before` (read) | **yes** |
| `validate-write.sh` | PreToolUse (Write/Edit) | `tool.execute.before` (write/edit) | advisory |
| `validate-registry.sh` | PreToolUse (Write/Edit) | `tool.execute.before` (write/edit) | advisory |
| `validate-assets.sh` | PostToolUse (Write/Edit) | `tool.execute.after` (write/edit) | advisory; exit 2 is fed back |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | `tool.execute.after` (write/edit) | advisory |
| `notify.sh` | Notification | not ported | — |
| `log-agent.sh` | SubagentStart | not ported | — |
| `log-agent-stop.sh` | SubagentStop | not ported | — |
| `validate-agent-artifact.sh` | SubagentStop | not ported | — |

The status line is also not ported. OpenCode has its own context/model display;
use `/sprint-status` or `/project-stage-detect` for studio state.

## How a hook result is handled

- **Exit 2** — the adapter throws. The model sees the script's stderr as the tool
  error and stops the operation. This is used by commit, push, read, and
  build-breaking asset validation.
- **Exit 0 with plain text** — the text is injected as a synthetic message.
- **Exit 0 with hook JSON** — `systemMessage` and
  `hookSpecificOutput.additionalContext` are extracted and injected.
- **Exit 0 with no output** — nothing is injected.

The canonical scripts still receive Claude-shaped JSON on stdin. The adapter
translates OpenCode's `read`, `write`, `edit`, and `shell` inputs into the
`tool_name` / `tool_input` shape the scripts already parse.

## Session lifecycle

- On the first prompt of a primary session, `session-start.sh` and
  `detect-gaps.sh` run in parallel and their output is cached.
- The `session.context` hook adds the block to the system prompt as
  `<studio-session-context>`, so the model sees it on the first step without a
  second user turn. If a compaction removes it, the cached context is re-added;
  after a compaction the cache is cleared and the scripts run again with
  `source: compact`.
- On idle or execution end, `session-stop.sh` archives
  `production/session-state/active.md`. It is fire-and-forget with a short
  debounce. A one-shot `opencode run` can exit before the child script finishes;
  interactive sessions are the intended path for the audit trail.
- Subagent sessions are detected through `ctx.session.get` → `parentID`; the
  adapter skips the parent-level start/stop hooks for them.
- `session.created` is not used: a one-shot `opencode run` can create the session
  before the plugin's subscription is active. The prompt/context hooks are the
  reliable path.

## The shell safety net

`tool.execute.before` is the primary path. The adapter also registers a
`permission.evaluate` hook for shell commands that contain `git commit` or
`git push`. Permission evaluation runs in the child session's own permission
context, so the commit/push guards still apply if a future OpenCode version does
not route subagent tool calls through `tool.execute.before`.

## Disabling the adapter

Remove or rename `.opencode/plugins/ccgs/` and restart the OpenCode service. The
agent, skill, and command layers keep working; only automated validation and
context injection stop. The permissions in `opencode.jsonc` still apply.

## Adding a hook

1. Add or edit the canonical script in `.claude/hooks/` and wire it for Claude
   Code in `.claude/settings.json`.
2. Add the equivalent event mapping to `.opencode/plugins/ccgs/index.ts`.
3. Test both harnesses.
4. Document the new row above.

Keep scripts POSIX-friendly and fail-open for optional tools. A hook that
silently blocks every call is worse than a missing advisory.
