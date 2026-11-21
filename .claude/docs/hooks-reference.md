# Active Hooks

Hooks are configured in `.claude/settings.json` and fire automatically:

| Hook | Event | Trigger | Action |
| ---- | ----- | ------- | ------ |
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | `git commit` commands | Validates design doc sections, JSON data files, hardcoded values, TODO format |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | `git push`, `git tag`, `git merge` and release commands | Warns on pushes to protected branches (`main`, `master` and `release/*`), and on the steps that ask first: `git tag` (not a listing), `git merge` (not `--abort`), `gh release`, `butler push` and `steamcmd` with `+run_app_build`. Which commands count is `bash .claude/scripts/write-guard.sh git` |
| `validate-registry.sh` | PreToolUse (Write/Edit) | Writes and edits of `design/registry/entities.yaml` and `docs/architecture/tr-registry.yaml` | Warns, and never blocks, when the change would delete or renumber an entry or set a status outside the values the file's header lists. It runs before the write, while the old file can still be compared; the check itself is `bash .claude/scripts/registry.sh compare`. The skills that write a registry also run `registry.sh validate` after writing, because hooks do not run in every tool |
| `validate-write.sh` | PreToolUse (Write/Edit) | Writes and edits the rules below name | Warns, and never blocks, when a write would replace a file skills never overwrite (an existing `EPIC.md`, `project.godot`, `tests/helpers/*`, the tech-debt register, an engine reference doc, the files `/test-setup` creates), set a config value outside its list or a key `project.local.yaml` cannot hold, set the review mode, leave a prototype file without its `PROTOTYPE` or `VERTICAL SLICE` header or reach between `prototypes/` and the code root, change a string table during an active freeze, or, from a subagent, write anything but a new file under `production/`, `docs/` or `tests/`. The check is `bash .claude/scripts/write-guard.sh check`, which the skills that write these files also run themselves |
| `validate-read.sh` | PreToolUse (Read) | A Read with no offset and no limit under `design/`, `docs/architecture/` or `production/session-state/` | Blocks a whole-file read of a doc over 40 KB (`features.read_guard_kb`) and answers with the doc's headings by line, so the retry reads one section; a ranged read always passes. `features.read_guard: off` turns it off. The check is `bash .claude/scripts/read-guard.sh check` |
| `validate-agent-artifact.sh` | SubagentStop | A subagent stops | Warns you, and never blocks, when the file its return contract named ("Write your full output to `<path>`") is not on disk, a failed phase however its reply reads. Shown to you only: on this event, text for Claude would keep the subagent running |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Asset file changes | Checks data-file JSON under `assets/`, `Assets/` or `Content/`, and asset naming in Godot's `assets/` only |
| `session-start.sh` | SessionStart | Session begins | Loads sprint context, milestone, git activity; detects and previews active session state file for recovery, with one line when its checkpoint names a different branch from the one you are on; one line when a newer release is out, from a cache `update-check.sh` refreshes in the background at most once a day (`updates.check` in `effects-map.md`) |
| `detect-gaps.sh` | SessionStart | Session begins | Detects fresh projects (suggests /start) and missing documentation when code/prototypes exist, suggests /reverse-document or /project-stage-detect |
| `pre-compact.sh` | PreCompact | Context compression | Appends one line to `production/session-logs/compaction-log.txt` and prints nothing: Claude Code does not add PreCompact output to the conversation. `session-start.sh`, which runs again after every compaction, is what restores context |
| `notify.sh` | Notification (`permission_prompt`, `idle_prompt`) | Claude is waiting on a permission prompt, or has been idle about a minute | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | Stop, async | **Every response ends** — not once per session | Updates the session log and writes the subagent spawn tally to `production/session-logs/session-cost.md`; prints nothing. Archives `active.md` only when its content hash changed; without that guard a long session appended the whole file on every turn. Runs in the background, so the turn does not wait for it; under `claude -p` it is cancelled if still running when the session ends |
| `log-agent.sh` | SubagentStart | Agent spawned, resumed, or a teammate handles a new message | Audit trail start — logs subagent invocation with timestamp and session id. SubagentStart fires for a resume and for each agent-team message too, so the spawn tally counts those |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes subagent record. Skips Claude Code's internal agents (prompt suggestions, `/btw`), which arrive with an empty `agent_type` |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Skill file changes | Advises running `/skill-test` after any `.claude/skills/` file is written or edited |

Warnings from the `validate-*` hooks are shown to you and passed to Claude (only
to you from `validate-agent-artifact.sh`)
as hook JSON (`hook_warn` in `yaml-helper.sh`); only a problem that must be fixed
now exits 2, and the read guard's refusal. See `hooks-reference/hook-input-schemas.md` for why stderr is not
enough.

### Subagent cost visibility

The three hooks above form one chain. `log-agent.sh` writes a record per spawn
to `production/session-logs/agent-audit.log` in a fixed three-field shape:

```
YYYYMMDD_HHMMSS | <session_id> | Agent invoked: <agent_type>
```

`session-stop.sh` greps the literal string `" | $SESSION_ID | Agent invoked: "`
to tally the current session, then writes a count plus a per-agent breakdown to
`production/session-logs/session-cost.md`.

The field order of that record is fixed. `session-stop.sh` matches it literally,
so a different order silently zeroes the spawn count instead of raising an error.

When the hook input has no session id, `session-stop.sh` writes no total. A
total spanning every session in the log would look plausible and be wrong, which
is worse than none.

`agent_type` — not `agent_name` — is the field carrying the agent name. See
`hooks-reference/hook-input-schemas.md`.

## Events considered and deliberately not added

Claude Code offers many more hook events than the eight the hooks above use. These were
evaluated and not adopted, for the reasons given.

| Event | Why not |
| ---- | ---- |
| `UserPromptSubmit` | Would re-inject session state on **every prompt**. `.claude/docs/config-resolution.md` already rejects the weaker version of this — injecting config at session start — because it "would cost tokens on every session whether or not any skill needs config, and it would go stale mid-session as `/project-settings` writes land". Firing per prompt is the same argument, multiplied. |
| `ConfigChange` | Fires only for Claude Code's own settings files — user, project, local, policy and skills. It does **not** fire for `project.yaml`, so a hook watching the framework's config here would never run. `FileChanged` is the event that watches arbitrary files. |
| `FileChanged` on `project.yaml` | Config is resolved per skill invocation, in the skill body, precisely so each run reads fresh values. The only staleness left is text already injected into an earlier invocation, which is the accepted trade in `config-resolution.md`. |
| `PreToolUse` `updatedInput` | Could rewrite a non-conventional commit message instead of blocking it. Silently editing the user's input contradicts the collaboration protocol: this project blocks and explains rather than acting unasked. |
| `PostToolUseFailure` | Would add another log with no reader. |
| `SessionEnd` | `session-stop.sh` stays on `Stop`. `SessionEnd` fires on termination, which a crash may never reach, and the content-hash guard already makes the per-response firing cheap. |
| `PostCompact` | Its output and `systemMessage` never reach Claude, and `session-start.sh` already restores context after a compaction. A hook here would only cost a process start per compaction. |
| `InstructionsLoaded` | Useful for debugging which CLAUDE.md and rules files actually loaded, but it is a diagnostic, not a project requirement. Wire it in your own `.claude/settings.local.json` when you need it rather than paying for it on every load. |

Hook reference documentation: `.claude/docs/hooks-reference/`
Hook input schema documentation: `.claude/docs/hooks-reference/hook-input-schemas.md`
