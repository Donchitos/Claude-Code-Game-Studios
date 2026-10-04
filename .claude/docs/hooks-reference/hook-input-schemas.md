# Hook Input/Output Schemas

This documents the JSON payloads each Claude Code hook receives on stdin for every
event type, and how a hook's output reaches the user and Claude. Every payload
also carries the common fields `session_id`, `transcript_path`, `cwd` and
`hook_event_name`; the examples below show the event-specific ones. The full
reference is the Claude Code hooks documentation (https://code.claude.com/docs/en/hooks).

## PreToolUse

Fired before a tool is executed. Exit 2 **blocks** the call. Exit 0 lets it
continue through the normal permission flow — it does not approve it, and the
user can still be asked. To warn without blocking, exit 0 and print hook JSON —
see [Output](#output-warnings-someone-sees) below.

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

The PowerShell tool sends the same shape with `"tool_name": "PowerShell"`, so a
matcher of `Bash|PowerShell` covers both.

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

In real payloads a file tool's `file_path` is absolute, with the platform's own
separators — backslashes on Windows. Strip the project root first, then match
from the start of what is left (`assets/data/`). A segment such as
`/assets/data/` matched anywhere also fires on a parent folder of the same name
and on files outside the project, such as the user's own `~/.claude/skills/`.
`validate-assets.sh` shows the stripping.

## PostToolUse

Fired after a tool completes. **Cannot block** — the tool already ran. Exit 2
shows stderr to Claude, so it can fix what it just wrote. stderr on exit 0 goes to
the debug log only, so an advisory warning must be hook JSON on stdout.

### PostToolUse: Write

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "assets/data/enemy_stats.json",
    "content": "{\"goblin\": {\"health\": 50}}"
  },
  "tool_response": {
    "filePath": "assets/data/enemy_stats.json",
    "type": "create"
  }
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
  "tool_response": { "filePath": "assets/data/enemy_stats.json" }
}
```

## SubagentStart

Fired when a subagent is spawned via the `Agent` tool (named `Task` before
Claude Code 2.1.63; `Task` still works as an alias in permission rules and
`tools:` frontmatter, but the hook payload's `tool_name` is now `Agent`). The
agent's name is in `agent_type` — there is no `agent_name` field.

```json
{
  "agent_id": "agent-abc123",
  "agent_type": "game-designer"
}
```

## SessionStart

Fired when a session starts, resumes, is cleared with `/clear`, or is compacted.
Stdin carries `source`: `startup`, `resume`, `clear`, `compact` or `fork`. Plain stdout is
added to Claude's context — this is the event that restores context after a
compaction.

## PreCompact

Fired before context compaction. Stdin carries `trigger` (`manual` or `auto`).
**Its output does not reach Claude**: stdout goes to the debug log and
`systemMessage` is discarded. Exit 2 blocks the compaction.

## Stop

Fired **every time Claude finishes a response**, not once when the session ends.
Stdin carries the common fields plus `stop_hook_active` and
`last_assistant_message`. Exit 2 keeps Claude working instead of stopping.

## Output: warnings someone sees

A hook that warns but must not block exits 0 — and **on exit 0, stderr reaches
no one**. Print a JSON object on stdout instead:

```json
{
  "systemMessage": "Shown to the user",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Given to Claude next to the tool result"
  }
}
```

- stdout must hold **only** that object.
- `hookEventName` is required inside `hookSpecificOutput`.
- **Leave out `permissionDecision`** unless you mean it: on PreToolUse, `"allow"`
  skips the user's permission prompt.

CCGS hooks use `hook_warn` from `.claude/hooks/yaml-helper.sh`, which builds this
object and escapes the message without needing `jq`:

```bash
. .claude/hooks/yaml-helper.sh
hook_warn PostToolUse "Asset names must be lowercase: $FILE_PATH"
exit 0
```

## Exit Code Reference

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success. A JSON object on stdout is read as hook output; other stdout goes to the debug log, except on UserPromptSubmit, UserPromptExpansion, SessionStart and PostModelSwitch, where it is added to Claude's context. stderr goes to the debug log only. |
| 2 | Blocks on PreToolUse (Claude sees stderr as the reason), UserPromptSubmit (the prompt is erased), UserPromptExpansion, Stop, SubagentStop (the subagent keeps working) and PreCompact. On PostToolUse it shows stderr to Claude — the tool already ran. On SessionStart, SubagentStart, PostCompact and PostModelSwitch it shows stderr to the user only. On Notification it is ignored. The full per-event table is in the Claude Code hooks documentation. |
| Other | Non-blocking error; the action proceeds. |

**Output is capped at 10,000 characters (observed; the Claude Code hooks documentation does not state it).**
Plain stdout, and each of `additionalContext`, `systemMessage` and
`initialUserMessage`, is measured on its own. Past the cap Claude Code saves
the text to a file and passes a path
plus a 2,000-character preview, and nothing tells Claude to read the file. Keep
what Claude must see inside the cap — `session-start.sh` caps its checkpoint
preview for this reason.

## Notes

- Hooks receive JSON on **stdin** (pipe). Use `INPUT=$(cat)` to capture.
- Parse with `jq` if available, fall back to `grep` for cross-platform compatibility.
- On Windows, `grep -P` (Perl regex) is often unavailable. Use `grep -E` (POSIX extended) instead.
- Path separators may be `\` on Windows. Normalize with `sed 's|\\|/|g'` when comparing paths.
