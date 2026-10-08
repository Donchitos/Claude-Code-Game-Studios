# Active Hooks

Hooks are configured in `.claude/settings.json` and fire automatically:

| Hook | Event | Trigger | Action |
| ---- | ----- | ------- | ------ |
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | `git commit` commands | Validates design doc sections, JSON data files, hardcoded values, TODO format |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | `git push` commands | Warns on pushes to protected branches (`main`, `master` and `release/*`) |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Asset file changes | Checks data-file JSON under `assets/`, `Assets/` or `Content/`, and asset naming in Godot's `assets/` only |
| `session-start.sh` | SessionStart | Session begins | Loads sprint context, milestone, git activity; detects and previews active session state file for recovery |
| `detect-gaps.sh` | SessionStart | Session begins | Detects fresh projects (suggests /start) and missing documentation when code/prototypes exist, suggests /reverse-document or /project-stage-detect |
| `pre-compact.sh` | PreCompact | Context compression | Logs the compaction to `production/session-logs/compaction-log.txt`. Its state summary goes to the debug log only: Claude Code does not add PreCompact output to the conversation. `session-start.sh`, which runs again after every compaction, is what restores context |
| `post-compact.sh` | PostCompact | After compaction | Prints a re-read reminder to the debug log. PostCompact output never reaches Claude; recovery comes from `session-start.sh` |
| `notify.sh` | Notification | Notification event | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | Stop | **Every response ends** — not once per session | Summarizes accomplishments, updates session log, and writes the subagent spawn tally to `production/session-logs/session-cost.md`. Archives `active.md` only when its content hash changed; without that guard a long session appended the whole file on every turn. |
| `log-agent.sh` | SubagentStart | Agent spawned, resumed, or a teammate handles a new message | Audit trail start — logs subagent invocation with timestamp and session id. SubagentStart fires for a resume and for each agent-team message too, so the spawn tally counts those |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes subagent record. Skips Claude Code's internal agents (prompt suggestions, `/btw`), which arrive with an empty `agent_type` |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Skill file changes | Advises running `/skill-test` after any `.claude/skills/` file is written or edited |

Warnings from the four `validate-*` hooks are shown to you and passed to Claude
as hook JSON (`hook_warn` in `yaml-helper.sh`); only a problem that must be fixed
now exits 2. See `hooks-reference/hook-input-schemas.md` for why stderr is not
enough.

### Subagent cost visibility

The three hooks above form one chain. `log-agent.sh` writes a record per spawn
to `production/session-logs/agent-audit.log` in a fixed three-field shape:

```
YYYYMMDD_HHMMSS | <session_id> | Agent invoked: <agent_type>
```

`session-stop.sh` greps the literal string `" | $SESSION_ID | Agent invoked: "`
to tally the current session, then writes a count plus a per-agent breakdown to
`production/session-logs/session-cost.md` and echoes a one-line total.

The field order of that record is fixed. `session-stop.sh` matches it literally,
so a different order silently zeroes the spawn count instead of raising an error.

When the hook input has no session id, `session-stop.sh` prints no total. A
total spanning every session in the log would look plausible and be wrong, which
is worse than none.

`agent_type` — not `agent_name` — is the field carrying the agent name. See
`hooks-reference/hook-input-schemas.md`.

## Events considered and deliberately not added

Claude Code offers many more hook events than the nine the hooks above use. These were
evaluated and not adopted, for the reasons given.

| Event | Why not |
| ---- | ---- |
| `UserPromptSubmit` | Would re-inject session state on **every prompt**. `.claude/docs/config-resolution.md` already rejects the weaker version of this — injecting config at session start — because it "would cost tokens on every session whether or not any skill needs config, and it would go stale mid-session as `/settings` writes land". Firing per prompt is the same argument, multiplied. |
| `ConfigChange` | Fires only for Claude Code's own settings files — user, project, local, policy and skills. It does **not** fire for `project.yaml`, so a hook watching the framework's config here would never run. `FileChanged` is the event that watches arbitrary files. |
| `FileChanged` on `project.yaml` | Config is resolved per skill invocation, in the skill body, precisely so each run reads fresh values. The only staleness left is text already injected into an earlier invocation, which is the accepted trade in `config-resolution.md`. |
| `PreToolUse` `updatedInput` | Could rewrite a non-conventional commit message instead of blocking it. Silently editing the user's input contradicts the collaboration protocol: this project blocks and explains rather than acting unasked. |
| `PostToolUseFailure` | Would add another log with no reader. |
| `SessionEnd` | `session-stop.sh` stays on `Stop`. `SessionEnd` fires on termination, which a crash may never reach, and the content-hash guard already makes the per-response firing cheap. |
| `InstructionsLoaded` | Useful for debugging which CLAUDE.md and rules files actually loaded, but it is a diagnostic, not a project requirement. Wire it in your own `.claude/settings.local.json` when you need it rather than paying for it on every load. |

Hook reference documentation: `.claude/docs/hooks-reference/`
Hook input schema documentation: `.claude/docs/hooks-reference/hook-input-schemas.md`
