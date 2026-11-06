# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

# Claude Code Game Studios —— 游戏工作室智能体架构

通过 49 个协同工作的 Claude Code 子智能体来管理独立游戏开发。
每个智能体负责一个特定领域，贯彻关注点分离与质量。

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

## 技术栈

- **引擎**：[CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **语言**：[CHOOSE: GDScript / C# / C++ / Blueprint]
- **版本控制**：Git，采用主干开发（trunk-based）
- **构建系统**：[选择引擎后填写]
- **资产管线**：[选择引擎后填写]

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

> **注意**：Godot、Unity 和 Unreal 都有对应的引擎专员智能体，并配有
> 专门的子专员。请使用与你引擎匹配的那一套。

## Project Structure

@.claude/docs/directory-structure.md

## 项目结构

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## 引擎版本参考

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## 技术偏好

仓库根目录的 `project.yaml` 是主要的配置存储——引擎、专员、命名、平台、性能、模式。
技能通过 `resolve_config` 解析它（参见 `.claude/docs/config-resolution.md`）。

`.claude/docs/technical-preferences.md` 是**旧版回退**，仅在 `project.yaml` 中缺少某个键时按需读取。
它不在此处导入：在 `/setup-engine` 运行之前，它几乎全是 `[TO BE CONFIGURED]` 占位符，而在它运行之后，
`project.yaml` 持有真正的值。

## Coordination Rules

@.claude/docs/coordination-rules.md

## 协调规则

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

## 协作协议

**由用户驱动的协作，而非自主执行。**
每项任务都遵循：**提问 -> 选项 -> 决定 -> 草稿 -> 批准**

- 智能体在使用 Write/Edit 工具之前必须询问“我可以把这段内容写入 [filepath] 吗？”
  （豁免：`active.md` 的追加、智能体记忆、子智能体在其编排技能所指路径上新建的文件；
  参见 `.claude/rules/agent-memory.md`）
- 智能体必须在请求批准前展示草稿或摘要
- 多文件变更需要针对整个变更集的明确批准
- 未经用户指示不提交
- 被跳过或被忽略的问题不是答案：不据此采取任何行动，用纯文本重新询问
  并等待
- 在本文件所在文件夹之外启动？先警告：钩子、拒绝规则和先询问模式
  只在 Claude Code 从此处启动时加载

完整协议与示例见 `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`。

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

> **第一次会话？** 如果项目尚未配置引擎、也没有游戏概念，
> 运行 `/start` 开始引导式入门流程。

## Coding Standards

@.claude/docs/coding-standards.md

## 编码标准

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)

## 上下文管理

按需读取 `.claude/docs/context-management.md`——它是参考资料，而非会话上下文。
其中有两条约定是关键性的，并在仓库其他地方被按名称引用，因此在此重申以免丢失：

- **`production/session-state/active.md` 是会话检查点。** 文件才是记忆，而不是对话。
  在任何压缩、崩溃或 `/clear` 之后，先读它。
- **`.claude/scripts/` 中的辅助脚本只输出观察结果，从不输出裁决。** 一个打分或评判的脚本
  最终会与某种它看不到的模式或覆盖相矛盾。（被 `artifact-check.sh` 和 `adr-dep-graph.sh` 引用。）
