# Hook Input/Output Schemas

This documents the JSON payloads each Claude Code hook receives on stdin for every event type.

## PreToolUse

Fired before a tool is executed. Can **allow** (exit 0) or **block** (exit 2).

### PreToolUse: Bash

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m 'feat: add player health system'",
    "description": "Commit changes with message",
    "timeout": 120000
  }
}
```

### PreToolUse: Write

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/gameplay/health.gd",
    "content": "extends Node\n..."
  }
}
```

### PreToolUse: Edit

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "src/gameplay/health.gd",
    "old_string": "var health = 100",
    "new_string": "var health: int = 100"
  }
}
```

### PreToolUse: Read

```json
{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "src/gameplay/health.gd"
  }
}
```

## PostToolUse

Fired after a tool completes. **Cannot block** (exit code ignored for blocking). Stderr messages are shown as warnings.

### PostToolUse: Write

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "assets/data/enemy_stats.json",
    "content": "{\"goblin\": {\"health\": 50}}"
  },
  "tool_output": "File written successfully"
}
```

### PostToolUse: Edit

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "assets/data/enemy_stats.json",
    "old_string": "\"health\": 50",
    "new_string": "\"health\": 75"
  },
  "tool_output": "File edited successfully"
}
```

## SubagentStart

Fired when a subagent is spawned via the Task tool.

```json
{
  "agent_name": "game-designer",
  "model": "sonnet",
  "description": "Design the combat healing mechanic"
}
```

## SessionStart

Fired when a Claude Code session begins. **No stdin input** — the hook just runs and its stdout is shown to Claude as context.

## PreCompact

Fired before context window compression. **No stdin input** — the hook runs to save state before compression occurs.

## SessionEnd

Fired when the Claude Code session terminates. **No stdin input** — the hook runs for cleanup and logging.

## Stop

Fired when Claude finishes responding — **once per turn, not at session close**. Do not use
`Stop` for session teardown or archival work; it will run on every reply. Use `SessionEnd`
for anything that should happen once when the session ends.

## PostToolUseFailure

Fired after a tool call fails. Supports a tool-name matcher. Cannot block — the failure already happened.

```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "godot --headless --script tests/run.gd" },
  "tool_use_id": "toolu_...",
  "error": "exit status 1: 3 tests failed",
  "timestamp": "2026-08-18T10:46:13Z"
}
```

## PermissionDenied

Fired when a tool call is denied. Supports a tool-name matcher. Cannot block — the denial already happened.

```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "git push --force origin main" },
  "tool_use_id": "toolu_...",
  "permission_mode": "default",
  "classifier_verdict": null,
  "denial_reason": "matches deny rule Bash(git push --force*)"
}
```

A hook may return `{"hookSpecificOutput": {"hookEventName": "PermissionDenied", "retry": true}}`
to let Claude retry — but Claude Code **ignores `retry` when `classifier_verdict` is `null`**.
This project's hook only logs; it never requests a retry.

## FileChanged

Fired when a watched file changes on disk. **Matcher rules differ from other events**: a matcher
containing only letters, digits, `_`, and `|` is an exact-match filename set. Anything else —
hyphens, dots, slashes — switches it to regex mode. This project uses `design/.*\.md$`.

```json
{
  "file_path": "design/gdd/combat-system.md",
  "watch_pattern": "design/.*\\.md$",
  "timestamp": "2026-08-18T10:46:14Z"
}
```

## StopFailure

Fired when a turn ends because of an API error rather than normal completion. Supports a matcher on
error type (`rate_limit`, `overloaded`, `max_output_tokens`, `server_error`, ...). **Output and exit
code are ignored entirely** — this event is only useful for side effects like logging.

```json
{
  "error_type": "overloaded",
  "error_message": "upstream capacity",
  "model": "claude-sonnet-5",
  "timestamp": "2026-08-18T10:46:14Z"
}
```

## Exit Code Reference

| Exit Code | Meaning | Applicable Events |
|-----------|---------|-------------------|
| 0 | Allow / Success | All events |
| 2 | Block (stderr shown to Claude) | PreToolUse only |
| Other | Treated as error, tool proceeds | All events |

## Notes

- Hooks receive JSON on **stdin** (pipe). Use `INPUT=$(cat)` to capture.
- Parse with `jq` if available, fall back to `grep` for cross-platform compatibility.
- On Windows, `grep -P` (Perl regex) is often unavailable. Use `grep -E` (POSIX extended) instead.
- Path separators may be `\` on Windows. Normalize with `sed 's|\\|/|g'` when comparing paths.
