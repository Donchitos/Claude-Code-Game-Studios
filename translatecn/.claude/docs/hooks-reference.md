# Active Hooks
# 活动钩子

Hooks are configured in `.claude/settings.json` and fire automatically:
钩子配置在 `.claude/settings.json` 中，并会自动触发：

| Hook | Event | Trigger | Action |
| 钩子 | 事件 | 触发条件 | 动作 |
| ---- | ----- | ------- | ------ |
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | `git commit` commands | Validates design doc sections, JSON data files, hardcoded values, TODO format |
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | `git commit` 命令 | 验证设计文档章节、JSON 数据文件、硬编码值、TODO 格式 |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | `git push`, `git tag`, `git merge` and release commands | Warns on pushes to protected branches (`main`, `master` and `release/*`), and on the steps that ask first: `git tag` (not a listing), `git merge` (not `--abort`), `gh release`, `butler push` and `steamcmd` with `+run_app_build`. Which commands count is `bash .claude/scripts/write-guard.sh git` |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | `git push`、`git tag`、`git merge` 和发布命令 | 在推送到受保护分支（`main`、`master` 和 `release/*`）时，以及在先询问的步骤上发出警告：`git tag`（不是列表）、`git merge`（不是 `--abort`）、`gh release`、`butler push` 和带 `+run_app_build` 的 `steamcmd`。哪些命令计入由 `bash .claude/scripts/write-guard.sh git` 决定 |
| `validate-registry.sh` | PreToolUse (Write/Edit) | Writes and edits of `design/registry/entities.yaml` and `docs/architecture/tr-registry.yaml` | Warns, and never blocks, when the change would delete or renumber an entry or set a status outside the values the file's header lists. It runs before the write, while the old file can still be compared; the check itself is `bash .claude/scripts/registry.sh compare`. The skills that write a registry also run `registry.sh validate` after writing, because hooks do not run in every tool |
| `validate-registry.sh` | PreToolUse (Write/Edit) | 写入和编辑 `design/registry/entities.yaml` 与 `docs/architecture/tr-registry.yaml` | 当变更会删除或重新编号条目，或设置文件头部所列值之外的状态时，发出警告且从不阻塞。它在写入之前运行，此时旧文件仍可比较；检查本身是 `bash .claude/scripts/registry.sh compare`。编写注册表的技能也会在写入后运行 `registry.sh validate`，因为钩子并非在每个工具中都会运行 |
| `validate-write.sh` | PreToolUse (Write/Edit) | Writes and edits the rules below name | Warns, and never blocks, when a write would replace a file skills never overwrite (an existing `EPIC.md`, `project.godot`, `tests/helpers/*`, the tech-debt register, an engine reference doc, the files `/test-setup` creates), set a config value outside its list or a key `project.local.yaml` cannot hold, set the review mode, leave a prototype file without its `PROTOTYPE` or `VERTICAL SLICE` header or reach between `prototypes/` and the code root, change a string table during an active freeze, or, from a subagent, write anything but a new file under `production/`, `docs/` or `tests/`. The check is `bash .claude/scripts/write-guard.sh check`, which the skills that write these files also run themselves |
| `validate-write.sh` | PreToolUse (Write/Edit) | 写入和编辑下文规则指定的对象 | 当写入会替换技能从不覆盖的文件（已存在的 `EPIC.md`、`project.godot`、`tests/helpers/*`、技术债登记表、引擎参考文档、`/test-setup` 创建的文件）、设置其列表之外的配置值或 `project.local.yaml` 无法容纳的键、设置评审模式、让原型文件缺少其 `PROTOTYPE` 或 `VERTICAL SLICE` 头部或在 `prototypes/` 与代码根之间越界、在活跃冻结期间更改字符串表，或从子智能体写入 `production/`、`docs/` 或 `tests/` 下新文件之外的任何内容时，发出警告且从不阻塞。检查为 `bash .claude/scripts/write-guard.sh check`，编写这些文件的技能也会自行运行它 |
| `validate-read.sh` | PreToolUse (Read) | A Read with no offset and no limit under `design/`, `docs/architecture/` or `production/session-state/` | Blocks a whole-file read of a doc over 40 KB (`features.read_guard_kb`) and answers with the doc's headings by line, so the retry reads one section; a ranged read always passes. `features.read_guard: off` turns it off. The check is `bash .claude/scripts/read-guard.sh check` |
| `validate-read.sh` | PreToolUse (Read) | 在 `design/`、`docs/architecture/` 或 `production/session-state/` 下无 offset 且无 limit 的 Read | 阻止整文件读取超过 40 KB 的文档（`features.read_guard_kb`），并按行返回文档的标题，以便重试时读取单个章节；范围读取始终通过。`features.read_guard: off` 会将其关闭。检查为 `bash .claude/scripts/read-guard.sh check` |
| `validate-agent-artifact.sh` | SubagentStop | A subagent stops | Warns you, and never blocks, when the file its return contract named ("Write your full output to `<path>`") is not on disk, a failed phase however its reply reads. Shown to you only: on this event, text for Claude would keep the subagent running |
| `validate-agent-artifact.sh` | SubagentStop | 子智能体停止 | 当其返回契约所指的文件（"Write your full output to `<path>`"）不在磁盘上时向你发出警告且从不阻塞，无论其回复读起来如何，该阶段都算失败。仅向你显示：在此事件上，发给 Claude 的文本会让子智能体继续运行 |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Asset file changes | Checks data-file JSON under `assets/`, `Assets/` or `Content/`, and asset naming in Godot's `assets/` only |
| `validate-assets.sh` | PostToolUse (Write/Edit) | 资源文件变更 | 检查 `assets/`、`Assets/` 或 `Content/` 下的数据文件 JSON，以及仅在 Godot 的 `assets/` 中的资源命名 |
| `session-start.sh` | SessionStart | Session begins | Loads sprint context, milestone, git activity; detects and previews active session state file for recovery, with one line when its checkpoint names a different branch from the one you are on; one line when a newer release is out, from a cache `update-check.sh` refreshes in the background at most once a day (`updates.check` in `effects-map.md`) |
| `session-start.sh` | SessionStart | 会话开始 | 加载冲刺上下文、里程碑、git 活动；检测并预览活动会话状态文件以进行恢复，当其检查点所指分支与你当前所在分支不同时输出一行；当有更新的发布版本时输出一行，信息来自 `update-check.sh` 在后台最多每天刷新一次的缓存（`effects-map.md` 中的 `updates.check`） |
| `detect-gaps.sh` | SessionStart | Session begins | Detects fresh projects (suggests /start) and missing documentation when code/prototypes exist, suggests /reverse-document or /project-stage-detect |
| `detect-gaps.sh` | SessionStart | 会话开始 | 检测全新项目（建议 /start），以及在代码/原型存在但文档缺失时建议 /reverse-document 或 /project-stage-detect |
| `pre-compact.sh` | PreCompact | Context compression | Appends one line to `production/session-logs/compaction-log.txt` and prints nothing: Claude Code does not add PreCompact output to the conversation. `session-start.sh`, which runs again after every compaction, is what restores context |
| `pre-compact.sh` | PreCompact | 上下文压缩 | 向 `production/session-logs/compaction-log.txt` 追加一行，且不打印任何内容：Claude Code 不会将 PreCompact 输出加入对话。每次压缩后再次运行的 `session-start.sh` 才是恢复上下文的东西 |
| `notify.sh` | Notification (`permission_prompt`, `idle_prompt`) | Claude is waiting on a permission prompt, or has been idle about a minute | Shows Windows toast notification via PowerShell |
| `notify.sh` | Notification（`permission_prompt`、`idle_prompt`） | Claude 正在等待权限提示，或已空闲约一分钟 | 通过 PowerShell 显示 Windows 通知 |
| `session-stop.sh` | Stop, async | **Every response ends** — not once per session | Updates the session log and writes the subagent spawn tally to `production/session-logs/session-cost.md`; prints nothing. Archives `active.md` only when its content hash changed; without that guard a long session appended the whole file on every turn. Runs in the background, so the turn does not wait for it; under `claude -p` it is cancelled if still running when the session ends |
| `session-stop.sh` | Stop，异步 | **每次响应结束** — 不是每个会话一次 | 更新会话日志，并将子智能体生成计数写入 `production/session-logs/session-cost.md`；不打印任何内容。仅当 `active.md` 的内容哈希变化时才归档它；没有该防护，长会话会在每轮追加整个文件。在后台运行，因此该轮不等待它；在 `claude -p` 下，如果会话结束时仍在运行，它会被取消 |
| `log-agent.sh` | SubagentStart | Agent spawned, resumed, or a teammate handles a new message | Audit trail start — logs subagent invocation with timestamp and session id. SubagentStart fires for a resume and for each agent-team message too, so the spawn tally counts those |
| `log-agent.sh` | SubagentStart | 智能体被生成、恢复，或队友处理新消息 | 审计跟踪开始 — 记录子智能体调用及时间戳和会话 ID。SubagentStart 也会在恢复以及每条智能体团队消息时触发，因此生成计数会统计这些 |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes subagent record. Skips Claude Code's internal agents (prompt suggestions, `/btw`), which arrive with an empty `agent_type` |
| `log-agent-stop.sh` | SubagentStop | 智能体停止 | 审计跟踪结束 — 完成子智能体记录。跳过 Claude Code 的内部智能体（提示建议、`/btw`），它们到达时 `agent_type` 为空 |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Skill file changes | Advises running `/skill-test` after any `.claude/skills/` file is written or edited |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | 技能文件变更 | 在任何 `.claude/skills/` 文件被写入或编辑后建议运行 `/skill-test` |

Warnings from the `validate-*` hooks are shown to you and passed to Claude (only
to you from `validate-agent-artifact.sh`)
as hook JSON (`hook_warn` in `yaml-helper.sh`); only a problem that must be fixed
now exits 2, and the read guard's refusal. See `hooks-reference/hook-input-schemas.md` for why stderr is not
enough.
来自 `validate-*` 钩子的警告会显示给你并作为钩子 JSON 传递给 Claude（`validate-agent-artifact.sh` 只显示给你）（`yaml-helper.sh` 中的 `hook_warn`）；只有必须立即修复的问题才以退出码 2 退出，以及读取守卫的拒绝。至于为什么 stderr 不够，见 `hooks-reference/hook-input-schemas.md`。

### Subagent cost visibility
### 子智能体成本可见性

The three hooks above form one chain. `log-agent.sh` writes a record per spawn
to `production/session-logs/agent-audit.log` in a fixed three-field shape:
上述三个钩子构成一条链。`log-agent.sh` 每次生成都会以固定的三字段形状向 `production/session-logs/agent-audit.log` 写入一条记录：

```
YYYYMMDD_HHMMSS | <session_id> | Agent invoked: <agent_type>
```

`session-stop.sh` greps the literal string `" | $SESSION_ID | Agent invoked: "`
to tally the current session, then writes a count plus a per-agent breakdown to
`production/session-logs/session-cost.md`.
`session-stop.sh` 搜索字面字符串 `" | $SESSION_ID | Agent invoked: "` 来统计当前会话，然后将计数加上逐智能体分解写入 `production/session-logs/session-cost.md`。

The field order of that record is fixed. `session-stop.sh` matches it literally,
so a different order silently zeroes the spawn count instead of raising an error.
该记录的字段顺序是固定的。`session-stop.sh` 按字面匹配它，因此不同的顺序会静默将生成计数归零，而不是抛出错误。

When the hook input has no session id, `session-stop.sh` writes no total. A
total spanning every session in the log would look plausible and be wrong, which
is worse than none.
当钩子输入没有会话 ID 时，`session-stop.sh` 不写总计。跨日志中每个会话的总计看起来合理但会是错的，这比没有更糟。

`agent_type` — not `agent_name` — is the field carrying the agent name. See
`hooks-reference/hook-input-schemas.md`.
承载智能体名称的字段是 `agent_type` — 不是 `agent_name`。见 `hooks-reference/hook-input-schemas.md`。

## Events considered and deliberately not added
## 已考虑但刻意未添加的事件

Claude Code offers many more hook events than the eight the hooks above use. These were
evaluated and not adopted, for the reasons given.
Claude Code 提供的钩子事件远多于上述钩子使用的八个。以下这些经过评估但未采用，原因如下。

| Event | Why not |
| 事件 | 未采用的原因 |
| ---- | ---- |
| `UserPromptSubmit` | Would re-inject session state on **every prompt**. `.claude/docs/config-resolution.md` already rejects the weaker version of this — injecting config at session start — because it "would cost tokens on every session whether or not any skill needs config, and it would go stale mid-session as `/settings` writes land". Firing per prompt is the same argument, multiplied. |
| `UserPromptSubmit` | 会在**每个提示**上重新注入会话状态。`.claude/docs/config-resolution.md` 已经拒绝了这一做法的较弱版本 — 在会话启动时注入配置 — 因为它"会在每个会话中消耗 token，无论是否有任何技能需要配置，而且随着 `/settings` 写入落地，它会在会话中途过时"。按提示触发是同样的论据，而且成倍放大。 |
| `ConfigChange` | Fires only for Claude Code's own settings files — user, project, local, policy and skills. It does **not** fire for `project.yaml`, so a hook watching the framework's config here would never run. `FileChanged` is the event that watches arbitrary files. |
| `ConfigChange` | 仅对 Claude Code 自己的设置文件触发 — 用户、项目、本地、策略和技能。它**不会**为 `project.yaml` 触发，因此在此监视框架配置的钩子永远不会运行。监视任意文件的事件是 `FileChanged`。 |
| `FileChanged` on `project.yaml` | Config is resolved per skill invocation, in the skill body, precisely so each run reads fresh values. The only staleness left is text already injected into an earlier invocation, which is the accepted trade in `config-resolution.md`. |
| `project.yaml` 上的 `FileChanged` | 配置在每次技能调用时于技能正文中解析，正是为了让每次运行读取新鲜值。唯一残留的过时内容是已注入到更早调用中的文本，这是 `config-resolution.md` 中已接受的权衡。 |
| `PreToolUse` `updatedInput` | Could rewrite a non-conventional commit message instead of blocking it. Silently editing the user's input contradicts the collaboration protocol: this project blocks and explains rather than acting unasked. |
| `PreToolUse` 的 `updatedInput` | 可以改写非约定式提交消息而不是阻塞它。静默编辑用户的输入违背协作协议：本项目阻塞并解释，而不是未经请求就行动。 |
| `PostToolUseFailure` | Would add another log with no reader. |
| `PostToolUseFailure` | 会增加另一份没有读者的日志。 |
| `SessionEnd` | `session-stop.sh` stays on `Stop`. `SessionEnd` fires on termination, which a crash may never reach, and the content-hash guard already makes the per-response firing cheap. |
| `SessionEnd` | `session-stop.sh` 留在 `Stop`。`SessionEnd` 在终止时触发，而崩溃可能永远无法到达，内容哈希防护已经使按响应触发变得廉价。 |
| `PostCompact` | Its output and `systemMessage` never reach Claude, and `session-start.sh` already restores context after a compaction. A hook here would only cost a process start per compaction. |
| `PostCompact` | 其输出和 `systemMessage` 永远不会到达 Claude，而 `session-start.sh` 已在每次压缩后恢复上下文。此处的钩子只会每次压缩花费一次进程启动。 |
| `InstructionsLoaded` | Useful for debugging which CLAUDE.md and rules files actually loaded, but it is a diagnostic, not a project requirement. Wire it in your own `.claude/settings.local.json` when you need it rather than paying for it on every load. |
| `InstructionsLoaded` | 对于调试实际加载了哪些 CLAUDE.md 和规则文件很有用，但它是诊断工具，不是项目需求。需要时在你自己的 `.claude/settings.local.json` 中接入它，而不是在每次加载时付出代价。 |

Hook reference documentation: `.claude/docs/hooks-reference/`
钩子参考文档：`.claude/docs/hooks-reference/`
Hook input schema documentation: `.claude/docs/hooks-reference/hook-input-schemas.md`
钩子输入模式文档：`.claude/docs/hooks-reference/hook-input-schemas.md`
