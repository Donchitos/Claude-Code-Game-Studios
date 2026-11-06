# Hook Input/Output Schemas
# 钩子输入/输出模式

This documents the JSON payloads each Claude Code hook receives on stdin for every
event type, and how a hook's output reaches the user and Claude. Every payload
also carries the common fields `session_id`, `transcript_path`, `cwd` and
`hook_event_name`; the examples below show the event-specific ones. The full
reference is the Claude Code hooks documentation (https://code.claude.com/docs/en/hooks).
本文档记录了每种事件类型下，每个 Claude Code 钩子通过 stdin 接收的 JSON 载荷，以及钩子的输出如何送达用户和 Claude。每个载荷还携带通用字段 `session_id`、`transcript_path`、`cwd` 和 `hook_event_name`；下面的示例展示的是事件特有的字段。完整参考见 Claude Code 钩子文档（https://code.claude.com/docs/en/hooks）。

## PreToolUse
## PreToolUse

Fired before a tool is executed. Exit 2 **blocks** the call. Exit 0 lets it
continue through the normal permission flow — it does not approve it, and the
user can still be asked. To warn without blocking, exit 0 and print hook JSON —
see [Output](#output-warnings-someone-sees) below.
在工具执行前触发。退出码 2 **阻止**该调用。退出码 0 让其继续走正常的权限流程——它并不代表批准，用户仍可能被询问。要在不阻止的情况下发出警告，请退出 0 并打印钩子 JSON——见下方[输出](#output-warnings-someone-sees)一节。

### PreToolUse: Bash
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
PowerShell 工具发送的结构相同，只是 `"tool_name": "PowerShell"`，因此匹配器 `Bash|PowerShell` 可同时覆盖两者。

### PreToolUse: Write
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
在真实载荷中，文件工具的 `file_path` 是绝对路径，并使用平台自身的分隔符——Windows 上是反斜杠。先剥离项目根目录，再从头匹配剩余部分（`assets/data/`）。像 `/assets/data/` 这样在任何位置匹配的片段，也会在同名的父文件夹上触发，还会在项目之外的文件上触发，例如用户自己的 `~/.claude/skills/`。`validate-assets.sh` 展示了这一剥离过程。

## PostToolUse
## PostToolUse

Fired after a tool completes. **Cannot block** — the tool already ran. Exit 2
shows stderr to Claude, so it can fix what it just wrote. stderr on exit 0 goes to
the debug log only, so an advisory warning must be hook JSON on stdout.
在工具完成后触发。**无法阻止**——工具已经运行过了。退出码 2 会向 Claude 显示 stderr，以便它修正刚刚写入的内容。退出码 0 时 stderr 只进入调试日志，因此提示性警告必须是通过 stdout 输出的钩子 JSON。

### PostToolUse: Write
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
## SubagentStart

Fired when a subagent is spawned via the `Agent` tool (named `Task` before
Claude Code 2.1.63; `Task` still works as an alias in permission rules and
`tools:` frontmatter, but the hook payload's `tool_name` is now `Agent`). The
agent's name is in `agent_type` — there is no `agent_name` field.
当通过 `Agent` 工具生成子智能体时触发（在 Claude Code 2.1.63 之前名为 `Task`；在权限规则和 `tools:` 前置元数据中 `Task` 仍可作为别名使用，但钩子载荷中的 `tool_name` 现在是 `Agent`）。智能体的名称位于 `agent_type` 中——并不存在 `agent_name` 字段。

```json
{
  "agent_id": "agent-abc123",
  "agent_type": "game-designer"
}
```

## SessionStart
## SessionStart

Fired when a session starts, resumes, is cleared with `/clear`, or is compacted.
Stdin carries `source`: `startup`, `resume`, `clear`, `compact` or `fork`. Plain stdout is
added to Claude's context — this is the event that restores context after a
compaction.
在会话启动、恢复、通过 `/clear` 清除或压缩时触发。stdin 携带 `source`：`startup`、`resume`、`clear`、`compact` 或 `fork`。普通 stdout 会被加入 Claude 的上下文——这正是压缩后恢复上下文的事件。

## PreCompact
## PreCompact

Fired before context compaction. Stdin carries `trigger` (`manual` or `auto`).
**Its output does not reach Claude**: stdout goes to the debug log and
`systemMessage` is discarded. Exit 2 blocks the compaction.
在上下文压缩前触发。stdin 携带 `trigger`（`manual` 或 `auto`）。**其输出不会送达 Claude**：stdout 进入调试日志，`systemMessage` 被丢弃。退出码 2 会阻止压缩。

## Stop
## Stop

Fired **every time Claude finishes a response**, not once when the session ends.
Stdin carries the common fields plus `stop_hook_active` and
`last_assistant_message`. Exit 2 keeps Claude working instead of stopping.
**每当 Claude 完成一次响应**时触发，而不是在会话结束时只触发一次。stdin 携带通用字段以及 `stop_hook_active` 和 `last_assistant_message`。退出码 2 会让 Claude 继续工作而不是停止。

## Output: warnings someone sees
## 输出：有人能看到的警告

A hook that warns but must not block exits 0 — and **on exit 0, stderr reaches
no one**. Print a JSON object on stdout instead:
一个只发出警告但不应阻止的钩子会以 0 退出——而**在退出码 0 时，stderr 不会送达任何人**。请改为在 stdout 上打印一个 JSON 对象：

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

- stdout 中必须**只**包含该对象。
- `hookSpecificOutput` 内必须提供 `hookEventName`。
- 除非确实有此意图，否则**省去 `permissionDecision`**：在 PreToolUse 上，`"allow"`
  会跳过用户的权限提示。

CCGS hooks use `hook_warn` from `.claude/hooks/yaml-helper.sh`, which builds this
object and escapes the message without needing `jq`:
CCGS 钩子使用 `.claude/hooks/yaml-helper.sh` 中的 `hook_warn`，它会构建该对象并转义消息，无需 `jq`：

```bash
. .claude/hooks/yaml-helper.sh
hook_warn PostToolUse "Asset names must be lowercase: $FILE_PATH"
exit 0
```

## Exit Code Reference
## 退出码参考

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success. A JSON object on stdout is read as hook output; other stdout goes to the debug log, except on UserPromptSubmit, UserPromptExpansion, SessionStart and PostModelSwitch, where it is added to Claude's context. stderr goes to the debug log only. |
| 2 | Blocks on PreToolUse (Claude sees stderr as the reason), UserPromptSubmit (the prompt is erased), UserPromptExpansion, Stop, SubagentStop (the subagent keeps working) and PreCompact. On PostToolUse it shows stderr to Claude — the tool already ran. On SessionStart, SubagentStart, PostCompact and PostModelSwitch it shows stderr to the user only. On Notification it is ignored. The full per-event table is in the Claude Code hooks documentation. |
| Other | Non-blocking error; the action proceeds. |

| 退出码 | 含义 |
|-----------|---------|
| 0 | 成功。stdout 上的 JSON 对象会被读取为钩子输出；其他 stdout 进入调试日志，但在 UserPromptSubmit、UserPromptExpansion、SessionStart 和 PostModelSwitch 上，它会被加入 Claude 的上下文。stderr 仅进入调试日志。 |
| 2 | 在 PreToolUse（Claude 将 stderr 视为原因）、UserPromptSubmit（提示被抹除）、UserPromptExpansion、Stop、SubagentStop（子智能体继续工作）和 PreCompact 上阻止。在 PostToolUse 上它会向 Claude 显示 stderr——因为工具已经运行过了。在 SessionStart、SubagentStart、PostCompact 和 PostModelSwitch 上它仅向用户显示 stderr。在 Notification 上它会被忽略。完整的分事件表格见 Claude Code 钩子文档。 |
| 其他 | 非阻塞错误；操作继续执行。 |

**Output is capped at 10,000 characters (observed; the Claude Code hooks documentation does not state it).**
Plain stdout, and each of `additionalContext`, `systemMessage` and
`initialUserMessage`, is measured on its own. Past the cap Claude Code saves
the text to a file and passes a path
plus a 2,000-character preview, and nothing tells Claude to read the file. Keep
what Claude must see inside the cap — `session-start.sh` caps its checkpoint
preview for this reason.
**输出上限为 10,000 个字符（此为实测结果；Claude Code 钩子文档并未说明）。**
普通 stdout，以及 `additionalContext`、`systemMessage` 和 `initialUserMessage` 各自独立计量。超过上限后，Claude Code 会将文本保存到文件，并传递一个路径加 2,000 字符的预览，而且没有任何提示告诉 Claude 去读取该文件。请把 Claude 必须看到的内容控制在上限之内——`session-start.sh` 正是出于这个原因对其检查点预览设了上限。

## Notes
## 备注

- Hooks receive JSON on **stdin** (pipe). Use `INPUT=$(cat)` to capture.
- 钩子通过 **stdin**（管道）接收 JSON。使用 `INPUT=$(cat)` 捕获。
- Parse with `jq` if available, fall back to `grep` for cross-platform compatibility.
- 如可用，使用 `jq` 解析；否则回退到 `grep` 以保证跨平台兼容性。
- On Windows, `grep -P` (Perl regex) is often unavailable. Use `grep -E` (POSIX extended) instead.
- 在 Windows 上，`grep -P`（Perl 正则）通常不可用。请改用 `grep -E`（POSIX 扩展正则）。
- Path separators may be `\` on Windows. Normalize with `sed 's|\\|/|g'` when comparing paths.
- Windows 上路径分隔符可能是 `\`。比较路径时使用 `sed 's|\\|/|g'` 进行规范化。
