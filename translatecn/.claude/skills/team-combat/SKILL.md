---
name: team-combat
description: "Orchestrate the combat team — game-designer, gameplay-programmer, ai-programmer, technical-artist, sound-designer, qa-tester — design through implement and validate."
argument-hint: "[combat feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-combat/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-combat
description: "编排战斗团队——game-designer、gameplay-programmer、ai-programmer、technical-artist、sound-designer、qa-tester——从设计到实现并验证。"
argument-hint: "[combat feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-combat/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Combat
# 战斗团队

**Argument check:** If no combat feature description is provided, output:
**参数检查：** 如果未提供战斗功能描述，输出：
> "Usage: `/team-combat [combat feature description] [--review full|lean|solo]` — Provide a description of the combat feature to design and implement (e.g., `melee parry system`, `ranged weapon spread`)."
> "用法：`/team-combat [combat feature description] [--review full|lean|solo]`——提供要设计和实现的战斗功能描述（例如 `melee parry system`、`ranged weapon spread`）。"
Then stop immediately without spawning any subagents or reading any files.
然后立即停止，不派生任何子智能体，也不读取任何文件。

When this skill is invoked with a valid argument, orchestrate the combat team through a structured pipeline.
当此技能带着有效参数被调用时，通过一条结构化的管线编排战斗团队。

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.
**决策点：** 在每个阶段转换处，使用 `AskUserQuestion` 将子智能体的提案作为可选项呈现给
用户。在对话中写出智能体的完整分析，然后用简洁的标签捕获决策。
在 `collaborative` 模式下，用户必须在进入下一阶段前批准。
在 `guided` 模式下，管线自动推进，除非某个阶段为 BLOCKED；
在 `autonomous` 模式下，它端到端运行，通过 `log_decision` 记录每个阶段的结果。`automation_always_ask` 类别中的决策
（`is_always_ask_category` 辅助函数）无论模式如何都总是提示。参见
`.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config
## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析——按原样使用；`--review` 会覆盖 `review_mode`。没有配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.
`review_mode` 设定导演门禁深度，而此管线没有导演门禁：
下面没有任何阶段会派生 CD-、TD-、PR- 或 AD-PHASE-GATE，无论 `review_mode` 为何。它的
阶段门禁是管线自身的决策点（定义在下方 `team.size` 之下），在其中工作的智能体是团队成员，不是导演门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.
`automation` 驱动上文的决策点说明。参见上文决策点说明和
`.claude/docs/automation-modes.md`，了解每种模式如何改变管线行为。

`workflow` sizes the Phase 1 design document the way `/design-system` does:
`## Summary` plus all 8 sections at `full`; at `standard`, Overview, Detailed
Design, Edge Cases, Dependencies and Acceptance Criteria, plus Formulas whenever
the mechanic defines numeric rules (a combat mechanic almost always does); at
`minimal` the game brief is the design record and the GDD is optional — draft
those five sections and tell the user it is optional at this workflow level.
`workflow` 以与 `/design-system` 相同的方式确定阶段 1 设计文档的规模：
`full` 时包含 `## Summary` 加全部 8 个小节；`standard` 时为概述、详细
设计、边界情况、依赖和验收标准，再加公式（只要机制定义了数值规则——战斗机制几乎总是如此）；
`minimal` 时游戏简报就是设计记录，GDD 是可选的——起草
那五个小节，并告诉用户在此工作流级别下它是可选的。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `gameplay-programmer` runs the pipeline; escalate `ai-programmer` only if the feature flags AI work. Other Team Composition agents are consulted via the gameplay-programmer, not spawned separately.
- **`small`**: the full Team Composition pipeline below, as documented.
- **`studio`**: full pipeline + engine sub-specialists + an adversarial review pass. *Engine sub-specialists*: the primary engine specialist's prompt says it may hand parts of its review to the sub-specialists its `tools:` grant names (for example `ue-gas-specialist` for abilities); below `studio` it answers alone. *Adversarial review pass*: Phase 5's qa-tester is told "your job is not to confirm this works — find how it breaks", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.
**`team.size`**：哪些智能体处于活动状态（与 review_mode 门禁深度和 workflow 文档正交）。
- **`individual`**（默认）：`gameplay-programmer` 运行管线；仅当功能标记了 AI 工作时才升级 `ai-programmer`。其他团队构成智能体经由 gameplay-programmer 咨询，不单独派生。
- **`small`**：下方按文档执行的完整团队构成管线。
- **`studio`**：完整管线 + 引擎子专家 + 一轮对抗性评审。*引擎子专家*：主引擎专家的提示词说明它可以将部分评审交给其 `tools:` 授权所命名的子专家（例如能力相关的 `ue-gas-specialist`）；在 `studio` 以下它独自作答。*对抗性评审*：阶段 5 的 qa-tester 被告知"你的职责不是确认它能工作——而是找出它如何失效"，且报告会说明该轮评审已运行。
在 `individual` 下需要的非核心智能体，经由最近的活动核心智能体转交，并附一条说明。**"阶段门禁"指此管线自身列出的、以 `AskUserQuestion` 决策点结束的任何阶段**——上文决策点下的转换，或下方管线中写明的 **Gate** 步骤——**无论 `automation` 模式为何。** `guided` 和 `autonomous` 改变的是门禁如何被通过（自动推进，或用 `log_decision` 记录），而不是它是否为门禁，因此下文的有界例外条件 (3) 在任何模式下都在它身上成立。被限制为"仅阶段门禁"的智能体只在这些点派生，其他点不派生。这种活动集范围限定贯穿下方整条管线：任何点名了活动集之外智能体的阶段，都会经由最近的核心智能体转交而不是直接派生。

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:
**在阶段 1 之前公布活动集——绝不要让这种收缩悄无声息。**
在派生任何东西之前，用一行说明本次运行实际会派生哪些智能体，以及下方管线点名但在解析出的
`team.size` 下**不会**派生的智能体。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`
> `活动集（team.size: <已解析值>）：<上方为该规模列出的智能体>。`
> `本次运行不派生：<此管线点名的其他所有智能体>——经由`
> `<最近的活动核心智能体>咨询。提高 team.size（或 modes.rigor）以扩大范围。`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.
从正上方的 `team.size` 列表以及此文件自身管线所点名的智能体来填写——不要照抄示例。两组集合因编排器而异。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.
下方管线读起来像多智能体扇出，而在出厂默认下它是一两个智能体——`team-release` 点名十个却只运行一个，`team-narrative`
在五个阶段中点名六个却只运行 `writer` 一个。**这种收缩是正确的**：
`team.size` 以严格度为前置，而窄默认值是 token 杠杆。
不说明这一点，读者就无法
区分一次正确收缩的运行与一条损坏的管线，而上文那条按智能体适用的
"经由最近的核心智能体转交并附说明"规则在路由时触发，却从不陈述整次运行的形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**
这与此文件其他地方关于跳过检查上报的规则相同：**一条被强制执行却从未呈现的约束，
对阅读输出的人而言，与一条从未被强制执行的约束无法区分。**

## Team Composition
## 团队构成
- **game-designer** — Design the mechanic, define formulas and edge cases
- **gameplay-programmer** — Implement the core gameplay code
- **ai-programmer** — Implement NPC/enemy AI behavior for the feature
- **technical-artist** — Create VFX, shader effects, and visual feedback
- **sound-designer** — Define audio events, impact sounds, and ambient combat audio
- **engine specialist** (primary) — Validate architecture and implementation patterns are idiomatic for the engine (the primary specialist is `<engine>-specialist` from `engine.name` — Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`; fall back to the Primary line of `## Engine Specialists` in `technical-preferences.md`)
- **qa-tester** — Write test cases and validate the implementation
- **game-designer** — 设计机制，定义公式和边界情况
- **gameplay-programmer** — 实现核心玩法代码
- **ai-programmer** — 为该功能实现 NPC/敌人 AI 行为
- **technical-artist** — 创建 VFX、着色器效果和视觉反馈
- **sound-designer** — 定义音频事件、打击音效和环境战斗音频
- **engine specialist**（主）——校验架构和实现模式是否符合引擎习惯（主专家是由 `engine.name` 得出的 `<engine>-specialist`——Godot→`godot-specialist`、Unity→`unity-specialist`、Unreal→`unreal-specialist`；回退到 `technical-preferences.md` 中 `## Engine Specialists` 的 Primary 行）
- **qa-tester** — 编写测试用例并验证实现

## How to Delegate
## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: game-designer` — Design the mechanic, define formulas and edge cases
- `subagent_type: gameplay-programmer` — Implement the core gameplay code
- `subagent_type: ai-programmer` — Implement NPC/enemy AI behavior
- `subagent_type: technical-artist` — Create VFX, shader effects, visual feedback
- `subagent_type: sound-designer` — Define audio events, impact sounds, ambient audio
- `subagent_type: [primary engine specialist]` — Engine idiom validation for architecture and implementation
- `subagent_type: qa-tester` — Write test cases and validate implementation
使用 `Agent` 工具将每位团队成员派生为子智能体：
- `subagent_type: game-designer` — 设计机制，定义公式和边界情况
- `subagent_type: gameplay-programmer` — 实现核心玩法代码
- `subagent_type: ai-programmer` — 实现 NPC/敌人 AI 行为
- `subagent_type: technical-artist` — 创建 VFX、着色器效果、视觉反馈
- `subagent_type: sound-designer` — 定义音频事件、打击音效、环境音频
- `subagent_type: [primary engine specialist]` — 针对架构和实现的引擎习惯校验
- `subagent_type: qa-tester` — 编写测试用例并验证实现

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.
**给每个智能体一份简报——不要倾倒上下文。** **只读一次**共享输入，并在提示中就地传递一份提炼过的简报：每个智能体实际需要的那几行，绝不要为你已经读过的文档传文件路径（拿到路径的智能体会重新读取整个文件）。只有对于你未读过且只有该智能体需要的文档，才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session. **Implementation files are the exception:** an agent writing code or assets first returns the files it will create or change, and its return contract names them only after you have asked once for the set and the user said yes (File Write Protocol) — that answer, not the bounded exception, authorises those writes.
**在每个智能体提示词结尾加上返回契约：** "将你的完整输出写入 `[path]`——该命名路径就是下文有界例外下你的写入授权，因此无需单独的批准提示即可写入。**只**返回 (1) 已写入的路径，(2) 不超过 5 条的项目符号决策摘要，(3) 任何 BLOCKED/CONCERNS 项，每项一行。不要复述你读过的文档。" 没有它，智能体会把它读过的一切都返回进此会话。**实现文件是例外：** 编写代码或资产的智能体会先返回它将创建或更改的文件，只有在你就整个集合询问一次且用户同意后，其返回契约才会点名这些文件（文件写入协议）——授权那些写入的是那个回答，而不是有界例外。

**Substitute a real path for `[path]`.** Every phase that produces an artifact
names one; most are fixed by the skill that already reads them:
**用真实路径替换 `[path]`。** 每个产出产物的阶段都
点明了一个路径；多数由已读取它们的技能固定：

| Phase / agent | Writes to | Destination fixed by |
|---|---|---|
| 1 game-designer (draft) | `production/combat/[feature]-gdd-draft.md` | this skill — you write the final `design/gdd/[feature].md` (Phase 1) |
| 2 gameplay-programmer | `docs/architecture/[feature]-sketch.md` | see note below |
| 2 engine specialist | `docs/architecture/[feature]-engine-notes.md` | see note below |
| 3 gameplay-programmer, ai-programmer, technical-artist | the code root and `assets/` — the files the Phase 3 approval lists | outside the bounded exception: asked once for the set (File Write Protocol) |
| 3 sound-designer | `production/combat/[feature]-audio-events.md` | this skill |
| 5 qa-tester (test cases) | `production/qa/test-cases/[feature]-cases.md` | `/team-qa` Phase 4 |
| 5 qa-tester (bugs) | `production/qa/bugs/BUG-[NNNN].md` | `/team-qa` Phase 5 |

| 阶段 / 智能体 | 写入到 | 目标位置由谁固定 |
|---|---|---|
| 1 game-designer（草稿） | `production/combat/[feature]-gdd-draft.md` | 本技能——最终 `design/gdd/[feature].md` 由你写入（阶段 1） |
| 2 gameplay-programmer | `docs/architecture/[feature]-sketch.md` | 见下方说明 |
| 2 engine specialist | `docs/architecture/[feature]-engine-notes.md` | 见下方说明 |
| 3 gameplay-programmer、ai-programmer、technical-artist | 代码根目录和 `assets/`——阶段 3 批准所列的文件 | 超出有界例外：就整个集合询问一次（文件写入协议） |
| 3 sound-designer | `production/combat/[feature]-audio-events.md` | 本技能 |
| 5 qa-tester（测试用例） | `production/qa/test-cases/[feature]-cases.md` | `/team-qa` 阶段 4 |
| 5 qa-tester（缺陷） | `production/qa/bugs/BUG-[NNNN].md` | `/team-qa` 阶段 5 |

Phase 6 is a spoken status report, not an artifact — no path, and none needed.
阶段 6 是一份口头状态报告，不是产物——没有路径，也不需要。

> **Every phase above names a concrete destination, deliberately.** The Error
> Recovery Protocol below says "a named artifact that is not on disk is a failed
> phase" — a check that cannot run when no path was named.
>
> **The two `docs/architecture/` entries are a judgement call, not a convention.**
> That directory holds ADRs (`adr-NNNN-*.md`); a sketch is a precursor to one, not
> one itself, and **nothing in the repo reads either file**. Say so when
> reporting, so the sketch is understood as a record rather than an input to a
> later gate.
> **上文每个阶段都刻意点明了一个具体去向。** 下文的错误
> 恢复协议说"一个不在磁盘上的命名产物就是失败的阶段"——一项在未命名路径时无法运行的检查。
>
> **`docs/architecture/` 中的两个条目是判断性选择，而非惯例。**
> 该目录存放 ADR（`adr-NNNN-*.md`）；草图是 ADR 的前身，而不是
> ADR 本身，且**仓库中没有任何东西读取这两个文件**。在
> 报告时说明这一点，以便将草图理解为一份记录，而不是后续门禁的
> 输入。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.
> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问 "May I write this to [filepath]?"。在此派生的子智能体**不**经询问即可写入，这是一个刻意设定的有界例外，而非疏忽——与 `consistency-check` 追加到 `active.md` 时已做出的相同决定。只有当以下三项全部成立时例外才成立：(1) 路径是**你**在提示词中点名的，因此用户在批准该阶段时已批准了目的地；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不对现有源代码或配置的编辑；(3) 产出它的阶段本身在管线推进前受到 `AskUserQuestion` 门禁约束。超出这三项之外，智能体必须询问。**不要通过按子智能体逐个询问来"修复"这一点**——每个阶段对每个智能体都弹提示会让编排器无法使用，这正是例外存在的原因。

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 3 agents can run simultaneously).
在管线允许的地方并行启动独立智能体（例如阶段 3 的智能体可以同时运行）。

## Pipeline
## 管线

### Phase 1: Design
### 阶段 1：设计
Delegate to **game-designer**:
- Create or update the design document for `design/gdd/[feature].md` from `.claude/docs/templates/game-design-document.md`, with `## Summary` and the sections `workflow` requires (Phase 0) — at `full`: mechanic overview, player fantasy, detailed rules, formulas with variable definitions, edge cases, dependencies, tuning knobs with safe ranges, and acceptance criteria
- Output: completed design document, drafted to `production/combat/[feature]-gdd-draft.md`
委派给 **game-designer**：
- 依据 `.claude/docs/templates/game-design-document.md` 创建或更新 `design/gdd/[feature].md` 的设计文档，包含 `## Summary` 以及 `workflow` 要求的小节（阶段 0）——`full` 时为：机制概述、玩家幻想、详细规则、含变量定义的公式、边界情况、依赖、含安全范围的调参旋钮，以及验收标准
- 输出：完整的设计文档，草稿写入 `production/combat/[feature]-gdd-draft.md`

`design/` is outside the bounded write exception above, so the game-designer
drafts and **you** write the GDD — the pattern `/team-level` and
`/team-narrative` use. At the Phase 1 decision point, present the draft and ask
via `AskUserQuestion`: "May I write the design document to
`design/gdd/[feature].md`?" Write it on approval; nothing is written under
`design/` before that answer.
`design/` 超出上文的有界写入例外，因此游戏设计师
起草，而**你**写入 GDD——`/team-level` 和
`/team-narrative` 使用的模式。在阶段 1 决策点，呈现草稿并通过
`AskUserQuestion` 询问："May I write the design document to
`design/gdd/[feature].md`?" 批准后写入；在该回答之前，`design/` 下不写入
任何东西。

### Phase 2: Architecture
### 阶段 2：架构
Delegate to **gameplay-programmer** (with **ai-programmer** if AI is involved):
- Review the design document, reading it by section: find the headings you need with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit
- Design the code architecture: class structure, interfaces, data flow
- Identify integration points with existing systems
- Output: architecture sketch with file list and interface definitions
委派给 **gameplay-programmer**（如果涉及 AI，则加上 **ai-programmer**）：
- 审阅设计文档，按小节读取：用 Grep 工具（模式 `^#`，内容模式）找到你需要的标题，再用 offset 和 limit 读取这些范围
- 设计代码架构：类结构、接口、数据流
- 识别与现有系统的集成点
- 输出：包含文件列表和接口定义的架构草图

Then spawn the **primary engine specialist** to validate the proposed architecture:
- Is the class/node/component structure idiomatic for the pinned engine? (e.g., Godot node hierarchy, Unity MonoBehaviour vs DOTS, Unreal Actor/Component design)
- Are there engine-native systems that should be used instead of custom implementations?
- Any proposed APIs that are deprecated or changed in the pinned engine version?
- Output: engine architecture notes — incorporate into the architecture before Phase 3 begins
然后派生**主引擎专家**来校验所提议的架构：
- 类/节点/组件结构是否符合所固定引擎的习惯？（例如 Godot 节点层级、Unity MonoBehaviour vs DOTS、Unreal Actor/Component 设计）
- 是否存在应替代自定义实现的引擎原生系统？
- 是否有提议的 API 在所固定的引擎版本中已弃用或变更？
- 输出：引擎架构说明——在阶段 3 开始前纳入架构

If no engine is configured, skip the specialist spawn. **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed.
如果未配置引擎，则跳过专家派生。**在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一项什么也不说的被跳过检查，与一项已通过的检查无法区分。

Use `AskUserQuestion`:
- Prompt: "Architecture sketch complete. Approve to proceed with parallel implementation."
- Options:
  - `[A] Proceed — spawn implementation agents (gameplay-programmer, ai-programmer, technical-artist, sound-designer)`
  - `[B] Revise the architecture first — I'll describe what needs to change`
  - `[C] Stop here — I'll continue later`
使用 `AskUserQuestion`：
- 提示："Architecture sketch complete. Approve to proceed with parallel implementation."
- 选项：
  - `[A] Proceed — spawn implementation agents (gameplay-programmer, ai-programmer, technical-artist, sound-designer)`
  - `[B] Revise the architecture first — I'll describe what needs to change`
  - `[C] Stop here — I'll continue later`

Only spawn implementation agents if user selects [A]. (In `guided`/`autonomous`
mode this architecture gate is a normal phase transition — proceed to
implementation unless the architecture sketch came back BLOCKED, recording the
decision via `log_decision` in autonomous mode. The gate is not a release-
critical or irreversible decision, so it follows the standard pipeline rule.)
仅当用户选择 [A] 时才派生实现智能体。（在 `guided`/`autonomous`
模式下，此架构门禁是正常的阶段转换——除非架构草图返回 BLOCKED，否则继续进行
实现，在自主模式下通过 `log_decision` 记录
决策。该门禁不是发布关键或不可逆的决策，因此遵循标准管线规则。）

### Phase 3: Implementation (parallel where possible)
### 阶段 3：实现（尽可能并行）
Delegate in parallel:
- **gameplay-programmer**: Implement core combat mechanic code
- **ai-programmer**: Implement AI behaviors (if the feature involves NPC reactions)
- **technical-artist**: Create VFX and shader effects
- **sound-designer**: Define audio event list and mixing notes, drafted to `production/combat/[feature]-audio-events.md`
并行委派：
- **gameplay-programmer**：实现核心战斗机制代码
- **ai-programmer**：实现 AI 行为（如果功能涉及 NPC 反应）
- **technical-artist**：创建 VFX 和着色器效果
- **sound-designer**：定义音频事件列表和混音说明，草稿写入 `production/combat/[feature]-audio-events.md`

The code, VFX and shader work is outside the bounded write exception: each of
those agents first returns the files it will create or change, you ask once for
the whole set, and they write only after a yes (File Write Protocol).
代码、VFX 和着色器工作超出有界写入例外：这些智能体各自先
返回它将创建或更改的文件，你就整个集合询问一次，
并且只有在得到同意后它们才写入（文件写入协议）。

### Phase 4: Integration
### 阶段 4：集成
- Wire together gameplay code, AI, VFX, and audio
- Ensure all tuning knobs are exposed and data-driven
- Verify the feature works with existing combat systems
- 将玩法代码、AI、VFX 和音频连接起来
- 确保所有调参旋钮都已暴露且数据驱动
- 验证该功能与现有战斗系统协同工作

**Gate**: Use `AskUserQuestion` to present the integration result and confirm before proceeding to Phase 5.
**门禁**：使用 `AskUserQuestion` 呈现集成结果，并在进入阶段 5 前确认。

### Phase 5: Validation
### 阶段 5：验证
Delegate to **qa-tester**:
- Write test cases from the acceptance criteria
- Test all edge cases documented in the design
- Verify performance impact is within budget
- File bug reports for any issues found
委派给 **qa-tester**：
- 根据验收标准编写测试用例
- 测试设计中记录的所有边界情况
- 验证性能影响在预算内
- 为发现的任何问题提交缺陷报告

### Phase 6: Sign-off
### 阶段 6：签收
- Collect results from all team members
- Report feature status: COMPLETE / NEEDS WORK / BLOCKED
- List any outstanding issues and their assigned owners
- 收集所有团队成员的结果
- 报告功能状态：COMPLETE / NEEDS WORK / BLOCKED
- 列出任何未解决的问题及其指派的负责人

## Error Recovery Protocol
## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.
**首先，验证产物。** 如果返回契约点明了路径，在将该阶段视为完成之前检查
路径是否存在——**一个不在磁盘上的命名产物就是失败的阶段，无论回应读起来多么流畅。** 一个智能体可以
耗尽整个阶段，什么也没写却返回一段看似合理的开场白，这
既不是 BLOCKED，也不是错误，也不是"无法完成"，因此下方的触发器
永远不会触发。以点名未满足的契约来恢复它；上下文通常
仍在。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.
如果任何被派生的智能体返回 BLOCKED、出错或无法完成：**立即暴露它，
不要越过它所阻塞的依赖继续推进，并始终产出一份
部分报告。** 被跳过智能体的小节保持为具名空白——绝不用你自己的内容填充它。完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
常见阻塞因素：
- 输入文件缺失（找不到故事、GDD 不存在）→ 转向创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦决策确定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆分为两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测

## File Write Protocol
## 文件写入协议

All file writes (design drafts, implementation files, test cases) are
delegated to sub-agents spawned via `Agent`, under two rules:
所有文件写入（设计草稿、实现文件、测试用例）都
委派给通过 `Agent` 派生的子智能体，遵循两条规则：

- **Drafts, sketches and QA artifacts** — the path table's destinations under
  `production/`, `docs/` or `tests/` — follow the **bounded exception** documented
  above under "Why this does not violate the Collaboration Protocol": the path is
  one you named, the artifact is new, and the phase is gated by an
  `AskUserQuestion`. The sub-agent writes them without a per-write prompt.
- **Implementation files** — Phase 3's code, VFX and shader files, and any
  Phase 4 integration edits, under the code root and `assets/` — are outside
  that exception, as the agents' own files say. Each implementing agent first
  returns the files it will create or change with a one-line summary each; ask
  once for the whole set ("May I have [agents] write these [N] files?") and have
  them write only after a yes. An edit to an existing file is always on that
  list, never implied by the pre-Phase 3 gate.
- **草稿、草图和 QA 产物**——路径表中位于
  `production/`、`docs/` 或 `tests/` 下的目的地——遵循上文"为什么这不违反
  协作协议"中记录的**有界例外**：路径是
  你点名的，产物是新的，且该阶段受
  `AskUserQuestion` 门禁约束。子智能体写入它们时无需逐次写入提示。
- **实现文件**——阶段 3 的代码、VFX 和着色器文件，以及任何
  阶段 4 集成编辑，位于代码根目录和 `assets/` 下——超出
  该例外，正如智能体各自的文件所述。每个实现智能体先
  返回它将创建或更改的文件，各附一行摘要；就整个集合询问
  一次（"May I have [agents] write these [N] files?"），并让它们
  只在得到同意后写入。对现有文件的编辑总是在那份
  清单上，绝不由阶段 3 前的门禁暗示。

The **one exception is the design document**: the orchestrator writes
`design/gdd/[feature].md` itself, from the game-designer's draft, after its own
"May I write …?" prompt (Phase 1). It writes no other file.
**唯一的例外是设计文档**：编排器在自身的
"May I write …?" 提示（阶段 1）之后，依据游戏设计师的草稿，亲自写入
`design/gdd/[feature].md`。它不写其他任何文件。

## Output
## 输出

A summary report covering: design completion status, implementation status per team member, test results, and any open issues.
一份摘要报告，涵盖：设计完成状态、每位团队成员的实现状态、测试结果，以及任何未解决的问题。

Verdict: **COMPLETE** — combat feature designed, implemented, and validated.
判定：**COMPLETE**——战斗功能已设计、实现并验证。

If the engine validation was skipped (Phase 2, no engine configured), the verdict
says so — never a plain COMPLETE:
如果引擎校验被跳过（阶段 2，未配置引擎），判定
会说明这一点——绝不是单纯的 COMPLETE：

Verdict: **COMPLETE — engine validation NOT ASSESSED ([reason])** — combat feature designed, implemented, and validated; the engine specialist never reviewed the architecture.
判定：**COMPLETE — engine validation NOT ASSESSED（[原因]）**——战斗功能已设计、实现并验证；引擎专家从未审阅架构。

Verdict: **NEEDS WORK** — every phase ran, but Phase 5 validation left failures or open bugs unresolved; the report lists each with its owner.
判定：**NEEDS WORK**——每个阶段都运行了，但阶段 5 验证留下了未解决的失败或未关闭缺陷；报告会逐一列出并注明其负责人。

Verdict: **BLOCKED** — one or more phases could not complete, or an agent was skipped (`.claude/docs/error-recovery-protocol.md` step 5); partial report produced with unresolved items listed.
判定：**BLOCKED**——一个或多个阶段无法完成，或某个智能体被跳过（`.claude/docs/error-recovery-protocol.md` 第 5 步）；已产出部分报告并列出未解决项。

## Next Steps
## 后续步骤

- Run `/code-review` on the implemented combat code before closing stories.
- Run `/balance-check` to validate combat formulas and tuning values.
- Run `/team-polish` if VFX, audio, or performance polish is needed.
- 在关闭故事之前对已实现的战斗代码运行 `/code-review`。
- 运行 `/balance-check` 以校验战斗公式和调参数值。
- 如果需要 VFX、音频或性能打磨，运行 `/team-polish`。
