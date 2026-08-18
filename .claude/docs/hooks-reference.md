# Active Hooks

Hooks are configured in `.claude/settings.json` and fire automatically:

| Hook | Event | Trigger | Action |
| ---- | ----- | ------- | ------ |
| `validate-commit.sh` | PreToolUse (Bash) | `git commit` commands | Validates design doc sections, JSON data files, hardcoded values, TODO format |
| `validate-push.sh` | PreToolUse (Bash) | `git push` commands | Warns on pushes to protected branches (develop/main) |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Asset file changes | Checks naming conventions and JSON validity for files in `assets/` |
| `session-start.sh` | SessionStart | Session begins | Loads sprint context, milestone, git activity; detects and previews active session state file for recovery |
| `detect-gaps.sh` | SessionStart | Session begins | Detects fresh projects (suggests /start) and missing documentation when code/prototypes exist, suggests /reverse-document or /project-stage-detect |
| `pre-compact.sh` | PreCompact | Context compression | Dumps session state (active.md, modified files, WIP design docs) into conversation before compaction so it survives summarization |
| `post-compact.sh` | PostCompact | After compaction | Reminds Claude to restore session state from `active.md` checkpoint |
| `notify.sh` | Notification | Notification event | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | SessionEnd | Session ends | Summarizes accomplishments and updates session log |
| `log-agent.sh` | SubagentStart | Agent spawned | Audit trail start — logs subagent invocation with timestamp |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes subagent record |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Skill file changes | Advises running `/skill-test` after any `.claude/skills/` file is written or edited |
| `validate-agent-manifest.sh` | PostToolUse (Write/Edit) | Agent file changes | Warns when an agent is missing from `.claude-plugin/plugin.json`, where agents must be listed individually |
| `log-tool-failure.sh` | PostToolUseFailure | A tool call fails | Appends the tool, target, and error to `production/session-logs/tool-failures.log` |
| `log-permission-denied.sh` | PermissionDenied | A tool call is blocked | Appends the attempt and denial reason to `production/session-logs/permission-denials.log` |
| `detect-design-drift.sh` | FileChanged (`design/**.md`) | A design doc changes on disk | Advises `/propagate-design-change` so stale ADRs and stories get caught |
| `log-turn-failure.sh` | StopFailure | Turn ends on an API error | Logs the error type and stamps `active.md` so session recovery knows it resumed from a failure |

When the studio is installed as a **plugin**, these same hooks are registered from
`.claude/hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}` paths instead of from
`.claude/settings.json`. The two files must stay in sync — `hooks.json` is generated
from `settings.json` by replacing `bash .claude/hooks/` with the plugin-root form.
Never register both at once; every hook would fire twice.

Hook reference documentation: `.claude/docs/hooks-reference/`
Hook input schema documentation: `.claude/docs/hooks-reference/hook-input-schemas.md`
