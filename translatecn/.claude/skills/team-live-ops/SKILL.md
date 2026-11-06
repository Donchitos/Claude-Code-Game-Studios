---
name: team-live-ops
description: "Orchestrate the live-ops team — live-ops-designer, economy-designer, analytics-engineer, community-manager, writer — for a season or live event."
argument-hint: "[season name or event description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-live-ops/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-live-ops
description: "编排实况运营团队 — live-ops-designer、economy-designer、analytics-engineer、community-manager、writer — 为一个赛季或实况活动服务。"
argument-hint: "[season name or event description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-live-ops/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Live Ops

**Argument check:** If no season name or event description is provided, output:
> "Usage: `/team-live-ops [season name or event description] [--review full|lean|solo]` — Provide the name or description of the season or live event to plan."
Then stop immediately without spawning any subagents or reading any files.

When this skill is invoked with a valid argument, orchestrate the live-ops team through a structured planning pipeline.

# 实况运营团队

**参数检查：** 如果没有提供赛季名称或活动描述，输出：
> "Usage: `/team-live-ops [season name or event description] [--review full|lean|solo]` — 请提供要规划的赛季或实况活动的名称或描述。"
然后立即停止，不派生任何子智能体，也不读取任何文件。

当此技能以有效参数被调用时，通过一个结构化的规划流水线编排实况运营团队。

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**决策点：** 在每次阶段转换时，使用 `AskUserQuestion` 将子智能体的提案作为可选项呈现给
用户。在对话中写出智能体的完整分析，然后用简洁的标签捕获决策。
在 `collaborative` 模式下，用户必须先批准才能进入下一阶段。
在 `guided` 模式下，除非某阶段处于 BLOCKED，流水线自动推进；
在 `autonomous` 模式下，它端到端运行，并通过
`log_decision` 记录每个阶段的结果。属于 `automation_always_ask` 类别的决策
（`is_always_ask_category` 辅助函数）无论何种模式都始终提示。参见
`.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow`

已在上方解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.

`review_mode` 设定总监门禁的深度，而此流水线没有总监门禁：
在下方任何 `review_mode` 下，都没有阶段会派生 CD-、TD-、PR- 或 AD-PHASE-GATE。它的
阶段门禁是流水线自身的决策点（定义于下方的 `team.size`
之下），而在这些决策点上工作的智能体是团队成员，不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

`automation` 驱动上方的决策点说明。关于每种模式如何改变流水线行为，参见上方的决策点说明
与 `.claude/docs/automation-modes.md`。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `live-ops-designer` + `economy-designer`. Other agents consulted via these two, not spawned separately.
- **`small`**: + `analytics-engineer` + `community-manager`.
- **`studio`**: + `writer` + `narrative-director` (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**`team.size`**：哪些智能体是活跃的（与 review_mode 的门禁深度和工作流文档正交）。
- **`individual`**（默认）：`live-ops-designer` + `economy-designer`。其他智能体通过这些智能体咨询，不单独派生。
- **`small`**：+ `analytics-engineer` + `community-manager`。
- **`studio`**：+ `writer` + `narrative-director`（如文档记录的完整流水线）。
在 `individual` 下需要的非核心智能体会通过最近的核心智能体路由，并附一条信息性说明。**"阶段门禁"指此流水线自身列出的、以 `AskUserQuestion` 决策点结尾的任何阶段** — 上方决策点中的一次转换，或下方流水线中写明的 **Gate** 步骤 — **无论 `automation` 模式为何。** `guided` 和 `autonomous` 改变的是门禁如何被通过（自动推进，或用 `log_decision` 记录），而不是它是否是一个门禁，因此下方的有界例外条件（3）在任何模式下都在其上成立。被限制为"仅阶段门禁"的智能体只在这些点上派生，不在其他点派生。这种活跃集范围限定贯穿下方的整个流水线：任何点名了活跃集之外智能体的阶段，都会通过最近的核心智能体路由，而不是派生它。

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

**在阶段 1 之前公布活跃集 — 绝不要让这次收窄悄无声息。**
在派生任何东西之前，用一行说明本次运行实际会派生哪些智能体，以及下方流水线点名但在
解析出的 `team.size` 下**不会**派生哪些智能体。例如：

> `Active set (team.size: <resolved>): <上方为该规模列出的那些智能体>.`
> `Not spawned this run: <此流水线点名的所有其他智能体> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

用正上方的 `team.size` 列表以及本文件自身流水线点名的智能体来填写它 — 不要照抄示例。
两个集合会随编排器不同而不同。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

下方的流水线读起来像是多智能体扇出，而在出厂默认下它是一个或两个智能体 — `team-release` 点名十个却只运行一个，`team-narrative`
在五个阶段中点名六个却只运行 `writer` 一个。**这种收窄是正确的**：
`team.size` 以严谨度为导向，狭窄的默认值就是 token 杠杆。
如果不说明这一点，读者就无法
把正确收窄的运行与破损的流水线区分开，而上文那条逐个智能体的
"通过最近的核心智能体路由并附信息性说明"规则
在路由时触发，却从不说明整次运行的形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

这与本文件其他地方关于跳过检查的报告规则相同：**一项被强制执行却从未呈现出来的约束，
在阅读输出的人看来，与一项从未被执行的约束无从区分。**

## Team Composition
- **live-ops-designer** — Season structure, event cadence, retention mechanics, battle pass
- **economy-designer** — Live economy balance, store rotation contents and prices (live-ops-designer sets its cadence), currency pricing, pity timers
- **analytics-engineer** — Success metrics, A/B test design, event tracking, dashboard specs
- **community-manager** — Player-facing announcements, event descriptions, seasonal messaging
- **narrative-director** — Seasonal narrative theme, story arc, world event framing
- **writer** — Event descriptions, reward item names, seasonal flavor text, announcement copy

## 团队组成
- **live-ops-designer** — 赛季结构、活动节奏、留存机制、战斗通行证
- **economy-designer** — 实况经济平衡、商店轮换内容与价格（由 live-ops-designer 设定其节奏）、货币定价、保底计时器
- **analytics-engineer** — 成功指标、A/B 测试设计、事件埋点、仪表盘规格
- **community-manager** — 面向玩家的公告、活动描述、季节性传达
- **narrative-director** — 赛季叙事主题、故事弧线、世界事件框架
- **writer** — 活动描述、奖励物品名称、赛季风味文本、公告文案

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: live-ops-designer` — Season/event structure and retention mechanics
- `subagent_type: economy-designer` — Live economy balance and reward pricing
- `subagent_type: analytics-engineer` — Success metrics, A/B tests, event instrumentation
- `subagent_type: community-manager` — Player-facing communication and messaging
- `subagent_type: narrative-director` — Seasonal theme and narrative framing
- `subagent_type: writer` — All player-facing text: event descriptions, item names, copy

## 如何委派

使用 `Agent` 工具将每位团队成员派生为子智能体：
- `subagent_type: live-ops-designer` — 赛季/活动结构与留存机制
- `subagent_type: economy-designer` — 实况经济平衡与奖励定价
- `subagent_type: analytics-engineer` — 成功指标、A/B 测试、事件埋点
- `subagent_type: community-manager` — 面向玩家的沟通与传达
- `subagent_type: narrative-director` — 赛季主题与叙事框架
- `subagent_type: writer` — 所有面向玩家的文本：活动描述、物品名称、文案

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**为每个智能体做简要说明 — 不要倾倒上下文。** 将共享输入**只读一次**，并内联传递提炼后的简述：每个智能体实际需要的那几行，绝不要为你已经读过的文档传文件路径（拿到路径的智能体会重新读整个文件）。只有对于你没有读过、且只有该智能体需要的文档，才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**每个智能体提示词都以返回契约结尾：**"将你的完整输出写入 `[path]` — 该命名路径即你在下方有界例外下的写入授权，因此无需单独的批准提示即可写入。**只**返回 (1) 写入的路径，(2) 不超过 5 条要点的决策摘要，(3) 任何 BLOCKED/CONCERNS 事项，各一行。不要重述你读过的文档。" 没有它，智能体会把它读过的一切都回传进本会话。

**Substitute a real path for `[path]`.** Working artifacts go under
`production/live-ops/[season-slug]/`, where `[season-slug]` is the argument as a
slug — lowercase, spaces → hyphens. One file per agent, so the parallel phases
never share one:

**用真实路径替换 `[path]`。** 工作产物放在
`production/live-ops/[season-slug]/` 下，其中 `[season-slug]` 是把参数转为
slug — 小写、空格 → 连字符。每个智能体一个文件，因此并行阶段
永不共用同一个：

| Phase / agent | Writes to |
|---|---|
| 1 live-ops-designer | `production/live-ops/[season-slug]/brief.md` |
| 2 narrative-director | `production/live-ops/[season-slug]/narrative.md` |
| 3 economy-designer | `production/live-ops/[season-slug]/economy.md` |
| 4 analytics-engineer | `production/live-ops/[season-slug]/analytics.md` |
| 5 narrative-director | `production/live-ops/[season-slug]/narrative-text.md` |
| 5 writer | `production/live-ops/[season-slug]/copy.md` |
| 6 community-manager | `production/live-ops/[season-slug]/comms.md` |

| 阶段 / 智能体 | 写入位置 |
|---|---|
| 1 live-ops-designer | `production/live-ops/[season-slug]/brief.md` |
| 2 narrative-director | `production/live-ops/[season-slug]/narrative.md` |
| 3 economy-designer | `production/live-ops/[season-slug]/economy.md` |
| 4 analytics-engineer | `production/live-ops/[season-slug]/analytics.md` |
| 5 narrative-director | `production/live-ops/[season-slug]/narrative-text.md` |
| 5 writer | `production/live-ops/[season-slug]/copy.md` |
| 6 community-manager | `production/live-ops/[season-slug]/comms.md` |

These are working drafts; the final documents under `design/live-ops/seasons/`
are compiled from them (Output Documents).

这些是工作草稿；`design/live-ops/seasons/` 下的最终文档
由它们汇编而成（输出文档）。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问"我可以把它写入 [filepath] 吗？"。在此派生的子智能体会**不询问**就写入，这是一项刻意设定的有界例外，而非疏忽 — 与已为 `consistency-check` 追加到 `active.md` 所做的同类决定一致。只有在以下三点全部成立时例外才成立：(1) 该路径是**你**在提示词中点名的，因此用户批准该阶段时就批准了目标位置；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不编辑现有源码或配置；(3) 产生它的阶段本身在流水线推进前受 `AskUserQuestion` 门禁。在这三点之外，智能体必须询问。**不要通过为每个子智能体逐一询问来"修复"这一点** — 每阶段每智能体一次提示会让编排器不可用，这正是该例外存在的原因。

Launch independent agents in parallel where the pipeline allows it (Phases 3 and 4 can run simultaneously).

在流水线允许的地方并行启动独立智能体（阶段 3 和阶段 4 可同时运行）。

## Pipeline

### Phase 1: Season/Event Scoping
Delegate to **live-ops-designer**:
- Define the season or event: type (seasonal, limited-time event, challenge), duration, theme direction
- Outline the content list: what's new (modes, items, challenges, story beats)
- Define the retention hook: what brings players back daily/weekly during this season
- Identify resource budget: how much new content needs to be created vs. reused
- Output: season brief with scope, content list, and retention mechanic overview

## 流水线

### 阶段 1：赛季/活动范围界定
委派给 **live-ops-designer**：
- 定义赛季或活动：类型（季节性、限时活动、挑战）、持续时间、主题方向
- 概述内容清单：什么是新的（模式、物品、挑战、故事节拍）
- 定义留存钩子：本季中什么能让玩家每天/每周回来
- 确定资源预算：需要创建多少新内容，对比复用多少
- 输出：包含范围、内容清单和留存机制概述的赛季简报

### Phase 2: Narrative Theme
Delegate to **narrative-director**:
- Read the season brief from Phase 1
- Design the seasonal narrative theme: how does this event connect to the game world?
- Define the central story hook players will discover during the event
- Identify which existing lore threads this season can advance
- Output: narrative framing document (theme, story hook, lore connections)

### 阶段 2：叙事主题
委派给 **narrative-director**：
- 读取阶段 1 的赛季简报
- 设计赛季叙事主题：此活动如何与游戏世界相连？
- 定义玩家在活动期间将发现的核心故事钩子
- 确定本季可以推进哪些现有的世界观线索
- 输出：叙事框架文档（主题、故事钩子、世界观关联）

### Phase 3: Economy Design (parallel with Phase 4)
Delegate to **economy-designer**:
- Read the season brief and existing economy rules from `design/live-ops/economy-rules.md`
- Design the reward track: free tier progression, premium tier value proposition
- Plan the in-season economy: seasonal currency, store rotation contents, pricing
- Define pity timer mechanics and bad-luck protection for any random elements
- Verify no pay-to-win items in premium track
- Output: economy design doc with reward tables, pricing, and currency flow

### 阶段 3：经济设计（与阶段 4 并行）
委派给 **economy-designer**：
- 读取赛季简报以及 `design/live-ops/economy-rules.md` 中现有的经济规则
- 设计奖励轨道：免费层级进度、付费层级的价值主张
- 规划赛季内经济：赛季货币、商店轮换内容、定价
- 为任何随机元素定义保底计时器机制与防脸黑保护
- 验证付费轨道中没有付费获胜类物品
- 输出：包含奖励表、定价和货币流转的经济设计文档

### Phase 4: Analytics and Success Metrics (parallel with Phase 3)
Delegate to **analytics-engineer**:
- Read the season brief
- Define success metrics: participation rate target, retention lift target, battle pass completion rate
- Design any A/B tests to run during the season (e.g., different reward cadences)
- Specify new telemetry events needed for this season's content
- Output: analytics plan with success criteria and instrumentation requirements

### 阶段 4：分析与成功指标（与阶段 3 并行）
委派给 **analytics-engineer**：
- 读取赛季简报
- 定义成功指标：参与率目标、留存提升目标、战斗通行证完成率
- 设计赛季期间要运行的所有 A/B 测试（例如不同的奖励节奏）
- 说明本季内容所需的新遥测事件
- 输出：包含成功标准与埋点需求的分析计划

### Phase 5: Content Writing (parallel)
Start only after both Phase 3 and Phase 4 results are collected. Delegate in parallel:
- **narrative-director** (if needed): Write any in-game narrative text (cutscene scripts, NPC dialogue, world event descriptions) for the season
- **writer**: Write all player-facing text — event names, reward item descriptions, challenge objective text, seasonal flavor text
- Both should read the narrative framing doc from Phase 2

### 阶段 5：内容写作（并行）
仅在阶段 3 与阶段 4 的结果都收集完毕后开始。并行委派：
- **narrative-director**（如需）：为本季撰写任何游戏内叙事文本（过场脚本、NPC 对话、世界事件描述）
- **writer**：撰写所有面向玩家的文本 — 活动名称、奖励物品描述、挑战目标文本、赛季风味文本
- 两者都应阅读阶段 2 的叙事框架文档

### Phase 6: Player Communication Plan
Delegate to **community-manager**:
- Read the season brief, economy design, and narrative framing
- Draft the season launch announcement (tone, key highlights, platform-specific versions)
- Plan the communication cadence: pre-launch teaser, launch day post, mid-season reminder, final week FOMO push
- Draft known-issues section placeholder for day-1 patch notes
- Output: communication calendar with draft copy for each touchpoint

### 阶段 6：玩家沟通计划
委派给 **community-manager**：
- 读取赛季简报、经济设计与叙事框架
- 起草赛季上线公告（语调、关键亮点、各平台专属版本）
- 规划沟通节奏：上线前预告、上线当日帖子、季中提醒、最后一周 FOMO 推动
- 为首日补丁说明起草已知问题小节的占位内容
- 输出：包含每个触点的草稿文案的沟通日历

### Phase 7: Review and Sign-off
Collect outputs from all phases and present a consolidated season plan:
- Season brief (Phase 1)
- Narrative framing (Phase 2)
- Economy design and reward tables (Phase 3)
- Analytics plan and success metrics (Phase 4)
- Written content inventory (Phase 5)
- Communication calendar (Phase 6)

### 阶段 7：评审与签核
收集所有阶段的输出，并呈现一份整合的赛季计划：
- 赛季简报（阶段 1）
- 叙事框架（阶段 2）
- 经济设计与奖励表（阶段 3）
- 分析计划与成功指标（阶段 4）
- 书面内容清单（阶段 5）
- 沟通日历（阶段 6）

Present a summary to the user with:
- **Content scope**: what is being created
- **Economy health check**: does the reward track feel fair and non-predatory?
- **Analytics readiness**: are success criteria defined and instrumented?
- **Ethics review**: check the Phase 3 economy design against `design/live-ops/ethics-policy.md`
  - If the file does not exist: flag "ETHICS REVIEW SKIPPED: `design/live-ops/ethics-policy.md` not found. Economy design was not reviewed against an ethics policy. Recommend creating one before production begins." Include this flag in the season design output document. Add to next steps: create `design/live-ops/ethics-policy.md`.
  - If the file exists and a violation is found: flag "ETHICS FLAG: [element] in Phase 3 economy design violates [policy rule]. Approval is blocked until this is resolved." Do NOT issue a COMPLETE verdict or write output documents. Use `AskUserQuestion` with options: revise economy design / override with documented rationale / cancel. If user chooses to revise: re-spawn economy-designer to produce a corrected design, then return to Phase 7 review. If user selects Cancel: end with Verdict: BLOCKED — "Live ops design cancelled due to unresolved ethics violation. Resolve the flagged issues and re-run /team-live-ops."
- **Open questions**: decisions still needed before production begins

向用户呈现摘要，包含：
- **内容范围**：正在创建什么
- **经济健康检查**：奖励轨道感觉公平且非掠夺性吗？
- **分析就绪度**：成功标准是否已定义并埋点？
- **伦理评审**：依据 `design/live-ops/ethics-policy.md` 检查阶段 3 的经济设计
  - 如果文件不存在：标记 "ETHICS REVIEW SKIPPED: `design/live-ops/ethics-policy.md` not found. Economy design was not reviewed against an ethics policy. Recommend creating one before production begins." 将此标记纳入赛季设计输出文档。在后续步骤中加入：创建 `design/live-ops/ethics-policy.md`。
  - 如果文件存在且发现违规：标记 "ETHICS FLAG: [element] in Phase 3 economy design violates [policy rule]. Approval is blocked until this is resolved." 不要发出 COMPLETE 判定，也不要写输出文档。使用 `AskUserQuestion`，选项：修订经济设计 / 以书面理由覆盖 / 取消。如果用户选择修订：重新派生 economy-designer 产出修正后的设计，然后回到阶段 7 评审。如果用户选择取消：以 Verdict: BLOCKED 结束 — "Live ops design cancelled due to unresolved ethics violation. Resolve the flagged issues and re-run /team-live-ops."
- **待决问题**：生产开始前仍需的决定

Ask the user to approve the season plan before delegating to production teams. Issue the COMPLETE verdict only after the user approves and no unresolved ethics violations remain. If an ethics violation is unresolved, end with Verdict: **BLOCKED**.

在委派给生产团队之前，请用户批准赛季计划。只有在用户批准且不存在未解决的伦理违规时，才发出 COMPLETE 判定。如果伦理违规未解决，以 Verdict: **BLOCKED** 结束。

## Output Documents

All documents save to `design/live-ops/` — **but the orchestrator asks before
writing them.** `design/` is NOT one of the three directories the bounded write
exception covers (`production/`, `docs/`, `tests/`), so a sub-agent handed one of
these paths must prompt. Do not widen the exception to silence that.
Follow `team-level`'s pattern instead: sub-agents write their working artifacts
under `production/`, where the exception does reach them; **you** compile the
final documents and ask via `AskUserQuestion` — "May I write the season plan to
`design/live-ops/…`?" — writing them only on approval.

## 输出文档

所有文档都保存到 `design/live-ops/` — **但编排器在写入前会先询问。**
`design/` 不属于有界写入例外所覆盖的三个目录之一
（`production/`、`docs/`、`tests/`），因此被交给这些路径之一的子智能体
必须提示询问。不要通过扩大例外来消除这一点。
改为遵循 `team-level` 的模式：子智能体将其工作产物写在
`production/` 下，例外确实覆盖那里；**你** 汇编最终文档并通过
`AskUserQuestion` 询问 — "May I write the season plan to
`design/live-ops/…`?" — 仅在批准后才写入。

Paths:
- `seasons/S[N]_[name].md` — Season design document (from Phase 1-3)
- `seasons/S[N]_[name]_analytics.md` — Analytics plan (from Phase 4)
- `seasons/S[N]_[name]_comms.md` — Communication calendar (from Phase 6)

路径：
- `seasons/S[N]_[name].md` — 赛季设计文档（来自阶段 1-3）
- `seasons/S[N]_[name]_analytics.md` — 分析计划（来自阶段 4）
- `seasons/S[N]_[name]_comms.md` — 沟通日历（来自阶段 6）

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

## 错误恢复协议

**首先，验证产物。** 如果返回契约点名了一个路径，在把该阶段视为完成之前检查
该路径是否存在 — **一个不在磁盘上的命名产物就是一个失败的阶段，无论回复读起来多么流畅。** 智能体可能
烧掉整个阶段，返回一段看似合理的前言却什么也没写，这
既不是 BLOCKED，也不是错误，也不是"无法完成"，因此下方的触发器
永远不会触发。以点名未满足契约的方式恢复它；上下文
通常还在。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

如果任何派生的智能体返回 BLOCKED、出错或无法完成：**立即将其呈现出来，
不要跨越它阻断的依赖继续推进，并始终产出
部分报告。** 被跳过的智能体的章节保持为具名缺口 — 绝不用你自己的内容填充它。完整流程：`.claude/docs/error-recovery-protocol.md`。

If a BLOCKED state is unresolvable, end with Verdict: **BLOCKED** instead of COMPLETE.

如果 BLOCKED 状态无法解决，以 Verdict: **BLOCKED** 结束，而不是 COMPLETE。

## File Write Protocol

Sub-agents write their working artifacts under `production/`, following the
**bounded exception** documented above under "Why this does not violate the
Collaboration Protocol" — the path is one you named, the artifact is new under
`production/`, `docs/` or `tests/`, and the phase is gated by an `AskUserQuestion`.
A sub-agent does **not** prompt per write inside those bounds; outside them it must
ask. The **final documents under `design/live-ops/`** — season design, analytics
plan, communication calendar — are the exception: the orchestrator compiles and
writes them itself after its own "May I write …?" prompt (Output Documents above).

## 文件写入协议

子智能体将其工作产物写在 `production/` 下，遵循上方"为什么这不违反
协作协议"中记录的**有界例外** — 路径是你点名的，产物是
`production/`、`docs/` 或 `tests/` 下的新文件，且该阶段受 `AskUserQuestion` 门禁。
子智能体在这些边界内**不会**为每次写入提示；在边界外它必须
询问。**`design/live-ops/` 下的最终文档** — 赛季设计、分析
计划、沟通日历 — 是例外：编排器在自己的"May I write …?"提示之后
自行汇编并写入它们（上方的输出文档）。

## Output

A summary covering: season theme and scope, economy design highlights, success metrics, content list, communication plan, and any open decisions needing user input before production.

Verdict: **COMPLETE** — season plan produced and handed off for production.

## 输出

一份摘要，涵盖：赛季主题与范围、经济设计亮点、成功指标、内容清单、沟通计划，以及在进入生产前需要用户输入的任何待决事项。

Verdict: **COMPLETE** — 赛季计划已产出并移交生产。

## Next Steps

- Run `/design-review` on the season design document for consistency validation.
- Run `/sprint-plan` to schedule content creation work for the season (at `workflow: minimal`, which has no sprints, add it to the brief's build order instead).
- Run `/team-release` when the season content is ready to deploy.
- If the run ended **BLOCKED** on an ethics flag: revise the economy design against
  `design/live-ops/ethics-policy.md` and re-run `/team-live-ops`; the three steps
  above wait for a COMPLETE plan.

## 后续步骤

- 对赛季设计文档运行 `/design-review` 进行一致性校验。
- 运行 `/sprint-plan` 为赛季安排内容创作工作（在 `workflow: minimal` 下没有冲刺，改为将其加入简报的构建顺序）。
- 当赛季内容可以部署时运行 `/team-release`。
- 如果本次运行因伦理标记而**BLOCKED**：依据
  `design/live-ops/ethics-policy.md` 修订经济设计并重新运行 `/team-live-ops`；上述三个步骤
  会等待一份 COMPLETE 的计划。
