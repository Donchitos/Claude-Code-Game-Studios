# settings.local.json Template
# settings.local.json 模板

Create `.claude/settings.local.json` for personal overrides that should NOT
be committed to version control. The shipped `.gitignore` already ignores it.
创建 `.claude/settings.local.json`，用于不应提交到版本控制的个人覆盖。随附的 `.gitignore` 已经忽略了它。

## Example settings.local.json
## 示例 settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(npm run *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

Put the `*` after the subcommand. `Bash(git commit *)` allows only commits;
`Bash(git *)` would allow every git command, `git push` included. Read-only
commands such as `git status`, `git log` and `ls` need no rule: Claude Code runs
them without asking. Your rules add to the shipped ones in
`.claude/settings.json`, so its deny rules still apply.
将 `*` 放在子命令之后。`Bash(git commit *)` 只允许提交；`Bash(git *)` 会允许所有 git 命令，包括 `git push`。像 `git status`、`git log` 和 `ls` 这样的只读命令不需要规则：Claude Code 无需询问即可运行它们。你的规则会添加到 `.claude/settings.json` 中随附的规则之上，因此其拒绝规则仍然适用。

## Permission Modes
## 权限模式

Claude Code has several permission modes. The shipped `.claude/settings.json`
starts terminal sessions in `default`; to start in another, set
`permissions.defaultMode` here. "One setting CCGS does ship" in
`setup-requirements.md` lists what that can and cannot change. You can also
switch during a session. Suggested for game dev:
Claude Code 有多种权限模式。随附的 `.claude/settings.json` 以 `default` 启动终端会话；要在另一种模式下启动，请在此设置 `permissions.defaultMode`。`setup-requirements.md` 中的 "One setting CCGS does ship" 列出了它能与不能改变什么。你也可以在会话期间切换。游戏开发的建议：

### During Development — Manual (`default`)
### 开发期间 — 手动（`default`）
Claude asks before running most commands and before editing files. This is the
safest for production code.
Claude 在运行大多数命令之前以及编辑文件之前会询问。这对生产代码是最安全的。

### During Prototyping — `acceptEdits`
### 原型制作期间 — `acceptEdits`
File edits and common filesystem commands such as `mkdir` and `mv` are accepted
without asking; other commands still ask. It applies to the whole working
directory, not only `prototypes/`, so switch back when you return to production
code.
文件编辑以及 `mkdir` 和 `mv` 等常见文件系统命令无需询问即被接受；其他命令仍会询问。它适用于整个工作目录，而不仅仅是 `prototypes/`，因此当你回到生产代码时请切换回来。

### During Code Review — `plan`
### 代码评审期间 — `plan`
Claude reads files and runs read-only commands to explore, but does not edit
your source files.
Claude 读取文件并运行只读命令进行探索，但不编辑你的源文件。

### `auto`
### `auto`
Runs without routine prompts: a background classifier checks each action before
it runs. A local `defaultMode` cannot start a terminal session in it; switch
during the session instead (`setup-requirements.md` lists the routes).
无需常规提示即可运行：后台分类器在每次操作运行前检查它。本地 `defaultMode` 无法以它启动终端会话；请改为在会话期间切换（`setup-requirements.md` 列出了这些路径）。

## Customizing Hooks Locally
## 本地自定义钩子

You can add personal hooks in `settings.local.json` that extend (not override)
the project hooks. For example, a personal log line each time Claude finishes a
response:
你可以在 `settings.local.json` 中添加个人钩子，它们扩展（而非覆盖）项目钩子。例如，每次 Claude 完成响应时记录一行个人日志：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo \"Response finished at $(date)\" >> \"$CLAUDE_PROJECT_DIR/production/session-logs/my-stops.log\"'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

A hook's output reaches Claude for only a few events, such as `SessionStart`
and `UserPromptSubmit`. For the others, including `Stop`, Claude Code writes
stdout to the debug log, so a hook that only prints shows nothing: write to a
file, as above, or to another tool. `Stop` fires at the end of every response,
not once per session.
钩子的输出仅在少数事件中到达 Claude，例如 `SessionStart` 和 `UserPromptSubmit`。对于其他事件（包括 `Stop`），Claude Code 会将 stdout 写入调试日志，因此只打印的钩子什么也显示不出来：请像上面那样写入文件，或写入另一个工具。`Stop` 在每次响应结束时触发，而不是每个会话一次。
