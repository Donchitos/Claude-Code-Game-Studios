# Model Tier Assignment
# 模型层级分配

> ### When a skill's `model:` is used — skills only
> ### 技能的 `model:` 何时被使用 — 仅限技能
>
> A skill's `model:` overrides the session model for the rest of the turn the
> skill runs in, and your next prompt returns to the session model. Whether the
> override happens depends on how the skill starts:
> 技能的 `model:` 在该技能运行的这一回合剩余时间里覆盖会话模型，
> 你的下一个提示会回到会话模型。是否发生覆盖取决于技能如何启动：
>
> | How the skill starts | Is `model:` used? |
> |---|---|
> | You type `/skill-name` in Manual (`default`) mode | Yes |
> | You type `/skill-name` in auto mode | `sonnet` and `opus`: yes. `haiku`: no — auto mode does not support Haiku, so the session keeps its model |
> | Claude starts the skill itself, through the Skill tool | No — the session model runs it |
>
> | 技能如何启动 | 是否使用 `model:` |
> |---|---|
> | 你在 Manual（`default`）模式下输入 `/skill-name` | 是 |
> | 你在自动模式下输入 `/skill-name` | `sonnet` 和 `opus`：是。`haiku`：否 — 自动模式不支持 Haiku，所以会话保留其模型 |
> | Claude 通过 Skill 工具自行启动技能 | 否 — 由会话模型运行它 |
>
> Two things follow:
> 由此得出两点：
>
> - **An `opus` skill costs more in a Sonnet session.** Typing
>   `/architecture-review`, `/gate-check` or `/review-all-gdds` moves that turn
>   to Opus.
> - **`opus` 技能在 Sonnet 会话中花费更多。** 输入
>   `/architecture-review`、`/gate-check` 或 `/review-all-gdds` 会把那一回合
>   切换到 Opus。
> - **A `haiku` skill saves nothing in auto mode** (this project's settings start
>   terminal sessions in Manual, but a user can switch) — or when Claude starts
>   it. Never tell a user a `haiku` tier is saving them money.
> - **`haiku` 技能在自动模式下不节省任何东西**（本项目的设置以 Manual 模式
>   启动终端会话，但用户可以切换）— 或者当 Claude 启动它时。绝不要告诉用户
>   `haiku` 层级在为他省钱。
>
> Because the override ends at your next prompt, a skill that stops to ask you
> something in chat finishes on the session model after you answer.
> 因为覆盖在你的下一个提示时结束，一个停下来在聊天中问你某些事的技能
> 会在你回答后以会话模型完成。
>
> **This does NOT apply to agents.** `model:` in `.claude/agents/*.md` is a
> different mechanism, spawned as a separate session rather than executed inline,
> and Claude Code documents it as applied: it is second in the subagent model
> order, after a `model` Claude passes for one invocation. See the agent section
> below.
> **这不适用于智能体。** `.claude/agents/*.md` 中的 `model:` 是
> 不同的机制，作为独立会话生成而非内联执行，
> 且 Claude Code 文档记录它会被应用：它在子智能体模型
> 顺序中排第二，位于 Claude 为单次调用传入的 `model` 之后。参见下面的
> 智能体章节。

Skills and agents are assigned tiers by task complexity. A tier is written as
the alias `model:` takes, never as a model ID: Claude Code resolves each alias
to the current model in that family, so this table does not change when a new
model ships.
技能和智能体按任务复杂度分配层级。层级写成
`model:` 所接受的别名，绝不是模型 ID：Claude Code 将每个别名
解析为该系列中的当前模型，因此这张表在新
模型发布时不会改变。

| Tier | `model:` | When to use |
|------|----------|-------------|
| **Haiku** | `haiku` | Read-only status checks, formatting, simple lookups — no creative judgment needed |
| **Sonnet** | `sonnet` | Implementation, design authoring, analysis of individual systems — default for most work |
| **Opus** | `opus` | Multi-document synthesis, high-stakes phase gate verdicts, cross-system holistic review |
| **Session** | `inherit` | Agents only — runs on whatever model the session runs |

| 层级 | `model:` | 何时使用 |
|------|----------|-------------|
| **Haiku** | `haiku` | 只读状态检查、格式化、简单查询 — 无需创造性判断 |
| **Sonnet** | `sonnet` | 实现、设计创作、单个系统的分析 — 大多数工作的默认值 |
| **Opus** | `opus` | 多文档综合、高风险阶段门禁裁决、跨系统整体评审 |
| **Session** | `inherit` | 仅智能体 — 运行在会话所运行的任何模型上 |

Skills with `model: haiku` (5): `/help`, `/onboard`, `/project-stage-detect`,
`/scope-check`, `/sprint-status`
使用 `model: haiku` 的技能（5 个）：`/help`、`/onboard`、`/project-stage-detect`、
`/scope-check`、`/sprint-status`

> `/patch-notes` and `/changelog` are `sonnet`, not `haiku`: both produce
> **player-facing** copy and need judgement the cheapest tier is defined as not
> doing. Full reasoning in each skill's own header.
> `/patch-notes` 和 `/changelog` 是 `sonnet`，不是 `haiku`：两者都产出
> **面向玩家**的文案，需要最便宜层级被定义为不做的判断。
> 完整理由在各技能自己的文件头中。
>
> `/settings` was moved off `haiku` for the same reason. It does not only read
> and format — it resolves every leaf with provenance and then compares the
> configured rigor against the project's observable working practice. That is
> synthesis, which is what the Haiku row is defined as excluding.
> `/settings` 出于同样的原因从 `haiku` 移出。它不只是读取
> 和格式化 — 它带来源解析每个叶子节点，然后将
> 配置的严谨度与项目可观察的工作实践进行对比。那是
> 综合，正是 Haiku 行被定义为排除的内容。

Skills with `model: opus` (3): `/architecture-review`, `/gate-check`, `/review-all-gdds`
使用 `model: opus` 的技能（3 个）：`/architecture-review`、`/gate-check`、`/review-all-gdds`

All other skills are Sonnet. When creating a new skill, assign Haiku if it only
reads and formats; assign Opus if it must synthesize 5+ documents with
high-stakes output; otherwise write `model: sonnet` explicitly. Every skill
declares a tier. Whether the tier takes effect depends on how the skill starts
(see the table at the top of this file).
所有其他技能都是 Sonnet。创建新技能时，如果它只
读取和格式化，就分配 Haiku；如果它必须综合 5+ 份文档并产出
高风险输出，就分配 Opus；否则明确写 `model: sonnet`。每个技能
都声明层级。层级是否生效取决于技能如何启动
（见本文件顶部的表格）。

**Agent model tiers.** 30 agents use `model: inherit` and run on the session's
model. 19 are pinned:
**智能体模型层级。** 30 个智能体使用 `model: inherit` 并运行在会话的
模型上。19 个被固定：

- **opus (3):** `creative-director`, `producer`, `technical-director`. Under an
  Opus session an `opus` pin runs on the session's exact model, `[1m]` included,
  so it never gets a smaller window than its parent.
- **opus（3 个）：** `creative-director`、`producer`、`technical-director`。在
  Opus 会话下，`opus` 固定运行在会话的确切模型上，包括 `[1m]`，
  因此它永远不会得到比其父级更小的窗口。
- **sonnet (16):** `lead-programmer`, `prototyper`, `devops-engineer`,
  `community-manager` and the 12 engine sub-specialists:
  `godot-csharp-specialist`, `godot-gdextension-specialist`,
  `godot-gdscript-specialist`, `godot-shader-specialist`,
  `ue-blueprint-specialist`, `ue-gas-specialist`, `ue-replication-specialist`,
  `ue-umg-specialist`, `unity-addressables-specialist`,
  `unity-dots-specialist`, `unity-shader-specialist`, `unity-ui-specialist`.
  `/dev-story` and `/code-review` spawn the sub-specialists named in
  `project.yaml`'s `specialists` block (which `/setup-engine` writes); `/team-ui` spawns
  `unity-ui-specialist` and `ue-umg-specialist`; `/team-release` spawns
  `devops-engineer` and `community-manager`, and `/team-live-ops` spawns
  `community-manager`.
- **sonnet（16 个）：** `lead-programmer`、`prototyper`、`devops-engineer`、
  `community-manager` 以及 12 个引擎子专家：
  `godot-csharp-specialist`、`godot-gdextension-specialist`、
  `godot-gdscript-specialist`、`godot-shader-specialist`、
  `ue-blueprint-specialist`、`ue-gas-specialist`、`ue-replication-specialist`、
  `ue-umg-specialist`、`unity-addressables-specialist`、
  `unity-dots-specialist`、`unity-shader-specialist`、`unity-ui-specialist`。
  `/dev-story` 和 `/code-review` 生成 `project.yaml` 的 `specialists` 块中命名的
  子专家（该块由 `/setup-engine` 写入）；`/team-ui` 生成
  `unity-ui-specialist` 和 `ue-umg-specialist`；`/team-release` 生成
  `devops-engineer` 和 `community-manager`，`/team-live-ops` 生成
  `community-manager`。
- **haiku (0):** no agent. The Haiku row above is for read-only lookups and
  formatting; every agent drafts, writes or judges. Building CI pipelines and
  writing player-facing text are Sonnet work, as they are for `/patch-notes`.
- **haiku（0 个）：** 没有智能体。上面的 Haiku 行用于只读查询和
  格式化；每个智能体都会起草、写入或评判。构建 CI 流水线和
  编写面向玩家的文本是 Sonnet 工作，与 `/patch-notes` 相同。

Every agent not named above is `inherit`. The `model:` line in the agent's own
file is what runs.
上面未命名的每个智能体都是 `inherit`。智能体自己文件中的
`model:` 行才是实际运行的内容。

A pin gets that model's context window, whatever the session runs. On the
Anthropic API `sonnet` currently resolves to Sonnet 5, which always has a 1M
window, so a `sonnet` pin is not smaller than a 1M session there; `haiku`
resolves to Haiku 4.5 and its 200K window, and behind an LLM gateway a `sonnet`
pin can be smaller too. A subagent starts from
the brief it is given, not the parent's conversation, so this only matters when
a brief is very large. If a pinned agent does overflow, run every subagent on
the session's model with one line in your `.claude/settings.local.json`
(Claude Code v2.1.257 or later):
固定项获得该模型的上下文窗口，无论会话运行什么。在
Anthropic API 上，`sonnet` 目前解析为 Sonnet 5，它始终有 1M
窗口，所以那里的 `sonnet` 固定项不比 1M 会话更小；`haiku`
解析为 Haiku 4.5 及其 200K 窗口，在 LLM 网关后面，`sonnet`
固定项也可能更小。子智能体从
给它的简报开始，而不是父级的对话，所以这仅在
简报非常大时才重要。如果固定的智能体确实溢出，用 `.claude/settings.local.json`
中的一行让每个子智能体都运行在会话的模型上
（Claude Code v2.1.257 或更高版本）：

```json
{ "env": { "CLAUDE_CODE_SUBAGENT_MODEL_FORCE": "1" } }
```

It applies to **every** pin, the three `opus` directors included: under a
Sonnet session they run on Sonnet too. `CLAUDE_CODE_SUBAGENT_MODEL` alone does
not do it: it applies only to agents that set no model of their own.
它适用于**每个**固定项，包括三位 `opus` 总监：在
Sonnet 会话下它们也运行在 Sonnet 上。单独使用 `CLAUDE_CODE_SUBAGENT_MODEL`
做不到：它只适用于没有设置自己模型的智能体。
