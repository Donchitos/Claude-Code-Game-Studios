# Context Management
# 上下文管理

Context is the most critical resource in a Claude Code session. Manage it actively.
上下文是 Claude Code 会话中最关键的资源。请主动管理。

## File-Backed State (Primary Strategy)
## 文件支撑状态（主要策略）

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.
**文件即记忆，而非对话。** 对话是短暂的，
会被压缩或丢失。磁盘上的文件在压缩和会话崩溃后依然存在。

### Session State File
### 会话状态文件

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:
维护 `production/session-state/active.md` 作为活动检查点。在每个重要里程碑后更新它：

- Design section approved and written to file
- 设计章节获批并写入文件
- Architecture decision made
- 做出架构决策
- Implementation milestone reached
- 达成实现里程碑
- Test results obtained
- 获得测试结果

**Create it from `.claude/docs/templates/session-state.md`** — the file has a
schema, and hooks depend on it.
**从 `.claude/docs/templates/session-state.md` 创建它** — 该文件有
结构模式，钩子依赖它。

Two regions, and the distinction is load-bearing:
两个区域，且这种区分是承重的：

| Region | Who reads it | Rule |
|--------|--------------|------|
| `<!-- STATUS -->` … `<!-- /STATUS -->` | `statusline.sh` (breadcrumb, Production+ only) | Keep the markers even when empty |
| `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` | `session-start.sh` (every start, including after a compaction) | **Overwrite, never append.** Under ~25 lines — shown verbatim |
| Everything after `<!-- /CHECKPOINT -->` | humans, and an agent that wants detail | Free-form; no hook injects it |

| 区域 | 谁读取它 | 规则 |
|--------|--------------|------|
| `<!-- STATUS -->` … `<!-- /STATUS -->` | `statusline.sh`（面包屑，仅 Production 及以上阶段） | 即使为空也保留标记 |
| `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` | `session-start.sh`（每次启动，包括压缩后） | **覆盖，绝不追加。** 约 25 行以内 — 逐字显示 |
| `<!-- /CHECKPOINT -->` 之后的所有内容 | 人类，以及想要细节的智能体 | 自由格式；没有钩子会注入它 |

The checkpoint holds: current task, next step, what it is blocked on, files in
progress, open questions. Write it so a cold reader can resume without opening
anything else.
检查点包含：当前任务、下一步、被什么阻塞、正在处理的文件、待解决的问题。
要写得让一个毫无背景的读者无需打开其他内容就能继续。

> **Why the split.** One append-only file doing both jobs grows without bound,
> and every consumer then reads a different slice of it: the top, the bottom, or
> a block nothing writes. None of them is wrong, because nothing defines where
> the recoverable state lives. With a named region, every consumer reads the
> same part, and the cost is fixed no matter how long the narrative grows.
> **为什么拆分。** 一个仅追加的文件同时承担两项工作会无限制增长，
> 每个消费者随后读取它的不同片段：顶部、底部，或一个无人写入的块。
> 它们都没有错，因为没有任何东西定义可恢复状态位于何处。有了命名区域，
> 每个消费者读取同一部分，无论叙事多长，成本都是固定的。

**Rotation.** When the narrative passes ~200 lines, move it into
`production/session-logs/`:
**轮转。** 当叙事超过约 200 行时，将其移动到
`production/session-logs/`：

```bash
bash .claude/scripts/rotate-session-state.sh            # --dry-run to preview
```

The checkpoint stays, the narrative is appended to a dated log, nothing is
deleted. `session-start.sh` observes when rotation is due but never performs it.
检查点保留，叙事追加到带日期的日志中，不删除任何内容。
`session-start.sh` 会观察何时需要轮转，但从不执行它。

### Status Line Block (Production+ only)
### 状态行块（仅 Production 及以上阶段）

When the project is in Production, Polish, or Release stage, include a structured
status block in `active.md` that the status line script can parse. (The project
stage is resolved from `project.stage` in `project.yaml`, falling back to
`production/stage.txt`.)
当项目处于 Production、Polish 或 Release 阶段时，在 `active.md` 中包含一个
状态行脚本可解析的结构化状态块。（项目阶段从 `project.yaml` 的 `project.stage`
解析，回退到 `production/stage.txt`。）

```markdown
<!-- STATUS -->
Epic: Combat System
Feature: Melee Combat
Task: Implement hitbox detection
<!-- /STATUS -->
```

- All three fields (Epic, Feature, Task) are optional — include only what applies
- 三个字段（Epic、Feature、Task）都是可选的 — 只包含适用的
- Update this block when switching focus areas
- 切换关注区域时更新此块
- The status line displays it as a breadcrumb: `Combat System > Melee Combat > Hitboxes`
- 状态行将其显示为面包屑：`Combat System > Melee Combat > Hitboxes`
- Remove or empty the block when no active work focus exists
- 没有活动工作重心时移除或清空该块

After any disruption (compaction, crash, `/clear`), read the state file first.
在任何中断（压缩、崩溃、`/clear`）之后，先读取状态文件。

### Incremental File Writing
### 增量文件写入

When creating multi-section documents (design docs, architecture docs, lore entries):
创建多章节文档（设计文档、架构文档、世界观条目）时：

1. Ask to create the file ("May I create [path] with the section skeleton?"), then
   create it with every section header and empty bodies
1. 请求创建文件（“我可以创建带有章节骨架的 [path] 吗？”），然后
   创建它，包含每个章节的标题和空正文
2. Discuss and draft one section at a time in conversation
2. 在对话中一次讨论并起草一个章节
3. Write each section to the file as soon as it's approved (a skill that writes
   once at the end, such as `/create-architecture`, records approved sections in
   the session state instead)
3. 每个章节一经批准就写入文件（像 `/create-architecture` 这样在最后一次性写入的技能，
   改为在会话状态中记录已批准的章节）
4. Update the session state file after each section
4. 每个章节完成后更新会话状态文件
5. After writing a section, previous discussion about that section can be safely
   compacted — the decisions are in the file
5. 写入一个章节后，之前关于该章节的讨论可以安全压缩 — 决策已在文件中

This keeps the context window holding only the *current* section's discussion
(~3-5k tokens) instead of the entire document's conversation history (~30-50k tokens).
这样上下文窗口只保留*当前*章节的讨论（约 3-5k token），
而不是整个文档的对话历史（约 30-50k token）。

## Proactive Compaction
## 主动压缩

- **Compact proactively** at ~60-70% context usage, not reactively at the limit
- **主动压缩** 在上下文使用率约 60-70% 时，而不是到极限时被动压缩
- **Use `/clear`** between unrelated tasks, or after 2+ failed correction attempts
- **使用 `/clear`** 在不相关任务之间，或在 2 次以上失败的纠正尝试后
- **Natural compaction points:** after writing a section to file, after committing,
  after completing a task, before starting a new topic
- **自然压缩点：** 将章节写入文件后、提交后、完成任务后、开始新主题前
- **Focused compaction:** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`
- **聚焦压缩：** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`

## Context Budgets by Task Type
## 按任务类型的上下文预算

- Light (read/review): ~3k tokens startup
- 轻量（读取/评审）：启动约 3k token
- Medium (implement feature): ~8k tokens
- 中等（实现功能）：约 8k token
- Heavy (multi-system refactor): ~15k tokens
- 重量（多系统重构）：约 15k token

## Deterministic Helpers — `.claude/scripts/`
## 确定性辅助脚本 — `.claude/scripts/`

The cheapest context saving is not summarising a document, it is **not reading it
at all**. When a question has a deterministic answer, a script should answer it
and the model should spend its budget on judgment instead.
最省上下文的做法不是总结一份文档，而是**根本不读它**。
当一个问题有确定性的答案时，脚本应回答它，
模型则应把预算花在判断上。

Two directories, two purposes — reach for the right one:
两个目录，两种用途 — 选择正确的那个：

| Directory | Purpose | Invoked by |
|---|---|---|
| `.claude/hooks/` | Event-driven — wired into `settings.json` and fired by Claude Code | the harness |
| `.claude/scripts/` | Manually invoked from a skill body | `bash .claude/scripts/<name>.sh` |

| 目录 | 用途 | 调用者 |
|---|---|---|
| `.claude/hooks/` | 事件驱动 — 接入 `settings.json` 并由 Claude Code 触发 | 执行框架 |
| `.claude/scripts/` | 从技能正文手动调用 | `bash .claude/scripts/<name>.sh` |

Current helpers:
当前辅助脚本：

- **`gdd-structure-check.sh`** — which of the 8 standard sections a GDD contains.
  Replaces a full-document read per GDD, and cannot hallucinate a missing
  section. Reports **presence only**; the caller applies the workflow tier.
- **`gdd-structure-check.sh`** — 某个 GDD 包含 8 个标准章节中的哪些。
  替代每个 GDD 的整篇文档读取，且不会凭空捏造缺失的章节。
  仅报告**存在性**；由调用方应用工作流层级。
- **`review-scope.sh`** — which GDDs changed since the last cross-review, plus
  their declared dependencies. Replaces reasoning through git history.
- **`review-scope.sh`** — 自上次交叉评审以来哪些 GDD 发生了变化，以及
  它们声明的依赖关系。替代通过 git 历史进行推理。

Two rules for helpers:
辅助脚本的两条规则：

1. **Grant it the way `.claude/docs/config-resolution.md` shows.** `allowed-tools`
   pre-approves commands; it does not restrict them — a skill without the grant
   still runs the script, after a permission prompt. An injected `` !`cmd` `` in
   the body is stricter: unapproved, it aborts the whole invocation, so it needs
   the exact grant that doc gives.
1. **按 `.claude/docs/config-resolution.md` 所示的方式授权。** `allowed-tools`
   预先批准命令；它不限制命令 — 没有该授权的技能仍会在权限提示后
   运行脚本。正文中注入的 `` !`cmd` `` 更严格：未经批准会中止整个调用，
   因此需要该文档给出的精确授权。
2. **Emit observations, not verdicts.** A script that scores or judges will
   eventually contradict a tier, mode, or per-system override it does not know
   about. Report what is on disk and let the caller decide what it means.
2. **输出观察结果，而非裁决。** 一个打分或评判的脚本最终会与它不知道的
   层级、模式或按系统覆盖相矛盾。报告磁盘上的内容，让调用方决定其含义。

## Subagent Delegation
## 子智能体委派

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context window and return only summaries:
使用子智能体进行研究与探索，以保持主会话整洁。
子智能体在自己的上下文窗口中运行，只返回摘要：

- **Use subagents** when investigating across multiple files, exploring unfamiliar code,
  or doing research that would consume >5k tokens of file reads
- **使用子智能体** 在跨多个文件调查、探索不熟悉的代码，
  或进行会消耗超过 5k token 文件读取的研究时
- **Use direct reads** when you know exactly which 1-2 files to check
- **使用直接读取** 当你确切知道要检查哪 1-2 个文件时
- Subagents do not inherit conversation history — provide full context in the prompt
- 子智能体不继承对话历史 — 在提示中提供完整上下文

## Compaction Instructions
## 压缩指令

When context is compacted, preserve the following in the summary:
上下文被压缩时，在摘要中保留以下内容：

- Reference to `production/session-state/active.md` (read it to recover state)
- 对 `production/session-state/active.md` 的引用（读取它以恢复状态）
- List of files modified in this session and their purpose
- 本次会话修改的文件列表及其用途
- Any architectural decisions made and their rationale
- 做出的任何架构决策及其理由
- Active sprint tasks and their current status
- 活动冲刺任务及其当前状态
- Agent invocations and their outcomes (success/failure/blocked)
- 智能体调用及其结果（成功/失败/阻塞）
- Test results (pass/fail counts, specific failures)
- 测试结果（通过/失败计数、具体失败）
- Unresolved blockers or questions awaiting user input
- 未解决的阻塞项或等待用户输入的问题
- The current task and what step we are on
- 当前任务以及我们处于哪一步
- Which sections of the current document are written to file vs. still in progress
- 当前文档的哪些章节已写入文件、哪些仍在进行中

**After compaction:** Read `production/session-state/active.md` and any files being
actively worked on to recover full context. The files contain the decisions; the
conversation history is secondary.
**压缩之后：** 读取 `production/session-state/active.md` 以及任何正在
积极处理的文件，以恢复完整上下文。文件包含决策；对话历史是次要的。

## Recovery After Session Crash
## 会话崩溃后的恢复

If a session dies ("prompt too long") or you start a new session to continue work:
如果会话终止（“prompt too long”）或你启动新会话继续工作：

1. The `session-start.sh` hook will detect and preview `active.md` automatically
1. `session-start.sh` 钩子会自动检测并预览 `active.md`
2. Read the full state file for context
2. 读取完整状态文件以获取上下文
3. Read the partially-completed file(s) listed in the state
3. 读取状态中列出的部分完成文件
4. Continue from the next incomplete section or task
4. 从下一个未完成的章节或任务继续
