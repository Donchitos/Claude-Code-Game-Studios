---
name: team-narrative
description: "Orchestrate the narrative team — narrative-director, writer, world-builder, level-designer — for story, world lore, narrative-driven levels."
argument-hint: "[narrative content description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-narrative/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: team-narrative
description: "编排叙事团队 —— narrative-director、writer、world-builder、level-designer —— 处理故事、世界传说、叙事驱动的关卡。"
argument-hint: "[narrative content description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-narrative/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Narrative

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-narrative [narrative content description] [--review full|lean|solo]` — describe the story content, scene, or narrative area to work on (e.g., `boss encounter cutscene`, `faction intro dialogue`, `tutorial narrative`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked with an argument, orchestrate the narrative team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

# 叙事团队

如果未提供参数，输出用法指引并退出，不派生任何智能体：
> 用法：`/team-narrative [narrative content description] [--review full|lean|solo]` —— 描述要处理的故事内容、场景或叙事区域（例如 `boss encounter cutscene`、`faction intro dialogue`、`tutorial narrative`）。此处不要使用 `AskUserQuestion`；直接输出指引。

当本技能带参数被调用时，通过结构化流水线编排叙事团队。

**决策点：** 在每个阶段转换处，使用 `AskUserQuestion` 把
子智能体的提议作为可选项呈现给用户。在对话中写出智能体的
完整分析，然后用简洁标签记录决策。
在 `collaborative` 模式下，用户必须批准后才能进入下一阶段。
在 `guided` 模式下，流水线自动推进，除非某个阶段为 BLOCKED；
在 `autonomous` 模式下，它端到端运行，通过
`log_decision` 记录每个阶段的结果。处于 `automation_always_ask` 类别的决策
（`is_always_ask_category` 辅助函数）无论模式如何始终提示。见
`.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.

Phase 4's ND-CONSISTENCY is the exception in every mode: it is this pipeline's own
review, not an optional director gate, so `review_mode` never skips it (`team.size`
still decides who runs it — see Phase 4).

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `writer` only; `narrative-director` invoked only on an explicit pillar conflict. Other agents consulted via the writer, not spawned separately.
- **`small`**: `narrative-director` + `writer`, plus `localization-lead` and `world-builder` when `review_mode` is `full` (at `lean` and `solo` they are consulted through the writer).
- **`studio`**: all six Team Composition agents, whatever the `review_mode` (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

已在上面解析 —— 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
采用 `.claude/docs/config-resolution.md` 中的默认值。

`review_mode` 设定导演门禁的深度，而本流水线没有导演门禁：
下面的任何阶段在任何 `review_mode` 下都不会派生 CD-、TD-、PR- 或 AD-PHASE-GATE。它的
阶段门禁是流水线自己的决策点（定义在下面 `team.size`
下），而在这些点上工作的智能体是团队成员，不是导演门禁。

阶段 4 的 ND-CONSISTENCY 在每种模式下都是例外：它是本流水线自己的
评审，而不是可选的导演门禁，因此 `review_mode` 从不跳过它（`team.size`
仍决定由谁来运行它 —— 见阶段 4）。

`automation` 驱动上面的决策点说明。关于每种模式如何改变流水线行为，见上面的决策点说明和
`.claude/docs/automation-modes.md`。

**`team.size`**：哪些智能体是活跃的（与 review_mode 的门禁深度和工作流文档正交）。
- **`individual`**（默认）：仅 `writer`；`narrative-director` 仅在显式支柱冲突时被调用。其他智能体通过 writer 咨询，不单独派生。
- **`small`**：`narrative-director` + `writer`，外加当 `review_mode` 为 `full` 时的 `localization-lead` 和 `world-builder`（在 `lean` 和 `solo` 下通过 writer 咨询）。
- **`studio`**：全部六个团队组成智能体，无论 `review_mode` 如何（即文档记载的完整流水线）。
在 `individual` 下需要非核心智能体时，通过最近的核心活跃智能体路由并附信息性说明。**"阶段门禁"指本流水线自己列出的、以 `AskUserQuestion` 决策点结尾的任何阶段** —— 上面决策点下的一个转换，或下面流水线中写明的 **Gate** 步骤 —— **无论 `automation` 模式为何。** `guided` 和 `autonomous` 改变的是门禁通过的方式（自动推进，或用 `log_decision` 记录），而不是它是否是门禁，所以下面的有限例外条件（3）在每种模式下对它都成立。受限于"仅阶段门禁"的智能体只在那些点派生，不在其他点派生。这种活跃集范围界定贯穿下面的整个流水线：任何点名活跃集之外智能体的阶段，都通过最近的核心智能体路由，而不是派生它。

**在阶段 1 之前宣布活跃集 —— 绝不让这种收缩悄无声息。**
在派生任何东西之前，用一行说明本次运行实际会派生哪些智能体，以及
下面流水线点名、但在已解析的 `team.size` 下**不会**派生哪些。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

> `Active set (team.size: <resolved>): <上面为该规模列出的智能体>.`
> `Not spawned this run: <本流水线点名的其他所有智能体> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

根据上面紧邻的 `team.size` 列表和本文件自身流水线点名的智能体来填写它 —— 而不是照抄示例。两套集合因编排器而异。

下面的流水线读起来像多智能体扇出，而在发布的默认值下它
就是一两个智能体 —— `team-release` 点名十个却只运行一个，`team-narrative`
在五个阶段点名六个却只运行 `writer` 一个。**这种收缩是正确的**：
`team.size` 由 rigor 前置，而狭窄的默认值就是 token 杠杆。
不说明这一点，读者就无法
区分一次正确收缩的运行和一条损坏的流水线，而上面按智能体的
"通过最近的核心智能体路由并附信息性说明"规则
只在路由时触发，从不说明整次运行的形态。

这与此文件别处关于跳过检查的报告规则相同：**一项被执行却从未呈现的约束，
在阅读输出的人看来，与从未
执行的约束无法区分。**

## Team Composition
- **narrative-director** — Story arcs, character design, dialogue strategy, narrative vision
- **writer** — Dialogue writing, lore entries, item descriptions, in-game text
- **world-builder** — World rules, faction design, history, geography, environmental storytelling
- **art-director** — Character visual design, environmental visual storytelling, cutscene/cinematic tone
- **level-designer** — Level layouts that serve the narrative, pacing, environmental storytelling beats
- **localization-lead** — Localization readiness — flags non-localizable strings, cultural assumptions, and i18n gaps

## 团队组成
- **narrative-director** —— 故事弧线、角色设计、对话策略、叙事愿景
- **writer** —— 对话写作、传说条目、物品描述、游戏内文本
- **world-builder** —— 世界规则、派系设计、历史、地理、环境叙事
- **art-director** —— 角色视觉设计、环境视觉叙事、过场/电影化基调
- **level-designer** —— 服务于叙事的关卡布局、节奏、环境叙事节奏点
- **localization-lead** —— 本地化就绪度 —— 标记不可本地化的字符串、文化假定和 i18n 缺口

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: narrative-director` — Story arcs, character design, narrative vision
- `subagent_type: writer` — Dialogue writing, lore entries, in-game text
- `subagent_type: world-builder` — World rules, faction design, history, geography
- `subagent_type: art-director` — Character visual profiles, environmental visual storytelling, cinematic tone
- `subagent_type: level-designer` — Level layouts that serve the narrative, pacing
- `subagent_type: localization-lead` — Localization readiness — flags non-localizable strings, cultural assumptions, and i18n gaps

**Read the canon first.** Before Phase 1, read the shared inputs that exist — the narrative bible or tone guide, the character and faction files under `design/narrative/`, and the world rules. Never tell an agent to invent canon: if none exists, say so and ask the user before any drafting.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**Substitute a real path for `[path]`.** Agents write drafts under
`production/narrative/[content-slug]/` — inside the bounded exception below. The
finished documents belong in `design/narrative/`, which the exception does **not**
cover, so **you** write those after one approval (see "Write the finals"):

| Agent | Drafts to (`[path]`) | Final document (you write it) |
|---|---|---|
| narrative-director | `production/narrative/[content-slug]/brief.md` | `design/narrative/[content-slug]-brief.md` |
| world-builder | `production/narrative/[content-slug]/lore-[topic].md` | `design/narrative/lore/[topic].md` |
| writer | `production/narrative/[content-slug]/dialogue-[scene-slug].md` | `design/narrative/dialogue/[scene-slug].md` |
| art-director | `production/narrative/[content-slug]/visual-direction.md` | `design/narrative/[content-slug]-visual-direction.md` |
| level-designer | `production/narrative/[content-slug]/level-integration.md` | `design/narrative/[content-slug]-level-integration.md` |
| localization-lead | `production/narrative/[content-slug]/i18n-review.md` | stays in `production/` — a review, not a design document |

> **The final destination is not a free choice.** `design/narrative/` is read by
> `/asset-spec`, `/design-review`, `/localize`, `/onboard`,
> `/project-stage-detect`, `/team-level` and the `cd-narrative` director gate.
> An artifact written anywhere else is invisible to all seven.
>
> The `[path]` contract above has a precondition: the path is one *you* named. A
> skill that states the contract but names no concrete destination leaves every
> run to invent one, which defeats it. `/team-qa` Phase 4 carries the same
> requirement for the same reason.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 2 agents can run simultaneously).

## 如何委派

使用 `Agent` 工具把每位团队成员派生为子智能体：
- `subagent_type: narrative-director` —— 故事弧线、角色设计、叙事愿景
- `subagent_type: writer` —— 对话写作、传说条目、游戏内文本
- `subagent_type: world-builder` —— 世界规则、派系设计、历史、地理
- `subagent_type: art-director` —— 角色视觉档案、环境视觉叙事、电影化基调
- `subagent_type: level-designer` —— 服务于叙事的关卡布局、节奏
- `subagent_type: localization-lead` —— 本地化就绪度 —— 标记不可本地化的字符串、文化假定和 i18n 缺口

**先读正典。** 在阶段 1 之前，读取存在的共享输入 —— 叙事圣经或基调指南、`design/narrative/` 下的角色和派系文件，以及世界规则。绝不要告诉智能体去发明正典：如果不存在，说明这一点并在任何起草前询问用户。

**给每个智能体做简报 —— 不要倾倒上下文。** 把共享输入读**一次**，并内联传递一份提炼过的简报：每个智能体实际需要的那些行，绝不要为一份你已经读过的文档传一个文件路径（拿到路径的智能体会把整个文件重读一遍）。只为你没读过、且只有该智能体需要的文档传路径。

**在每个智能体提示的末尾加上返回契约：** "把你的完整输出写到 `[path]` —— 该具名路径就是下方有限例外下你的写入授权，所以无需单独的批准提示即可写入它。**只**返回 (1) 写入的路径，(2) 不超过 5 条要点的决策摘要，(3) 任何 BLOCKED/CONCERNS 条目，各一行。不要复述你读过的文档。" 没有它，智能体会把它读过的一切都回传到本会话中。

**用真实路径替换 `[path]`。** 智能体在
`production/narrative/[content-slug]/` 下写草稿 —— 位于下方有限例外之内。完成的文档属于 `design/narrative/`，而例外**不**覆盖它，
所以**你**在一次性批准后写那些（见"写入终稿"）：

| 智能体 | 草稿写入（`[path]`） | 最终文档（由你写入） |
|---|---|---|
| narrative-director | `production/narrative/[content-slug]/brief.md` | `design/narrative/[content-slug]-brief.md` |
| world-builder | `production/narrative/[content-slug]/lore-[topic].md` | `design/narrative/lore/[topic].md` |
| writer | `production/narrative/[content-slug]/dialogue-[scene-slug].md` | `design/narrative/dialogue/[scene-slug].md` |
| art-director | `production/narrative/[content-slug]/visual-direction.md` | `design/narrative/[content-slug]-visual-direction.md` |
| level-designer | `production/narrative/[content-slug]/level-integration.md` | `design/narrative/[content-slug]-level-integration.md` |
| localization-lead | `production/narrative/[content-slug]/i18n-review.md` | 留在 `production/` —— 这是一份评审，不是设计文档 |

> **最终目的地不是可以随意选择的。** `design/narrative/` 会被
> `/asset-spec`、`/design-review`、`/localize`、`/onboard`、
> `/project-stage-detect`、`/team-level` 和 `cd-narrative` 导演门禁读取。
> 写在其他任何地方的资产对全部七者都不可见。
>
> 上面的 `[path]` 契约有一个前提：该路径是*你*指定的。一个陈述了契约却不指定任何具体目的地的技能，
> 会让每次运行都去发明一个，从而破坏它。`/team-qa` 阶段 4 出于同样的原因承载同样的要求。

> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问"May I write this to [filepath]?"。此处派生的子智能体**不**询问就写入，这是一个有意的、有界的例外，而非疏忽 —— 与已经为 `consistency-check` 追加到 `active.md` 所做出的同一决定。该例外仅在以下三项全部为真时成立：(1) 路径是**你**在提示中指定的，因此用户在批准阶段时就批准了目的地；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新资产，绝不是对既有源代码或配置的编辑；(3) 产出它的阶段本身在流水线推进前由 `AskUserQuestion` 门控。在这三项之外，智能体必须询问。**不要通过按子智能体逐个询问来"修复"这一点** —— 每个阶段为每个智能体配一个提示会让编排器无法使用，这正是例外存在的原因。

在流水线允许的地方并行启动独立智能体（例如，阶段 2 的智能体可以同时运行）。

## Pipeline

### Phase 1: Narrative Direction
Delegate to **narrative-director**:
- Define the narrative purpose of this content: what story beat does it serve?
- Identify characters involved, their motivations, and how this fits the overall arc
- Set the emotional tone and pacing targets
- Specify any lore dependencies or new lore this introduces
- Output: narrative brief with story requirements

### Phase 2: World Foundation (parallel)
Delegate in parallel — issue all three `Agent` calls simultaneously before waiting for any result:
- **world-builder**: Create or update lore entries for factions, locations, and history relevant to this content. Cross-reference against existing lore for contradictions. Set canon level for new entries.
- **writer**: Draft character dialogue using voice profiles. Ensure all lines are under 120 characters, use named placeholders for variables, and are localization-ready.
- **art-director**: Define character visual design direction for key characters appearing in this content (silhouette, visual archetype, distinguishing features). Specify environmental visual storytelling elements for each key space (prop composition, lighting notes, spatial arrangement). Define tone palette and cinematic direction for any cutscenes or scripted sequences.

**Phase gate:** collect all three Phase 2 outputs, then apply the Decision Points
rule before starting Phase 3 — present the lore, dialogue, and visual direction
summaries and capture approval via `AskUserQuestion` in `collaborative` mode
(auto-advance in `guided` unless a result is BLOCKED; `log_decision` in
`autonomous`).

### Phase 3: Level Narrative Integration
Delegate to **level-designer**:
- Review the narrative brief and lore foundation
- Design environmental storytelling elements in the level
- Place narrative triggers, dialogue zones, and discovery points
- Ensure pacing serves both gameplay and story

### Phase 4: Review and Consistency
Spawn `narrative-director` via `Agent` using gate **ND-CONSISTENCY**
(`.claude/docs/director-gates/nd-consistency.md`). This phase runs in every review
mode — it is this pipeline's own review, not an optional director gate. Pass the
context that gate lists (the Phase 2–3 draft paths, the narrative bible or tone
guide, the world rules, the affected character and faction profiles) — named
here, so do not read the gate file in this session — and add:
- Confirm narrative pacing aligns with level design
- Check that all mysteries have documented "true answers"

Act on the verdict: **APPROVE** → Phase 5. **CONCERNS** → show the listed
inconsistencies and ask via `AskUserQuestion` whether to revise them (re-spawn the
agent that owns each) or accept them. **REJECT** → do not start Phase 5; the
contradictions are fixed first. **NOT ASSESSED [missing input]** → name the
missing input, then supply it and re-run the gate, or carry
`ND-CONSISTENCY: NOT ASSESSED — [input]` into the report's consistency review
results; it is never read as APPROVE (`.claude/docs/director-gates.md`).

**At `team.size: individual`** narrative-director is not in the active set, so the
gate is not spawned. The writer checks the drafts against the same criteria, and
the output says so by name: "ND-CONSISTENCY not run — narrative-director is not
active at `team.size: individual`; consistency self-checked by writer." A
self-check is not the gate's verdict, and the report must not present it as one.

### Phase 5: Polish (parallel)
Delegate in parallel — issue every `Agent` call before waiting for any result:
- **writer**: Final self-review — verify no line exceeds dialogue box constraints, all text uses string keys (not raw strings), placeholder variable names are consistent
- **localization-lead**: Validate i18n compliance — check string key naming conventions, flag any strings with hardcoded formatting that won't survive translation, verify character limit headroom for languages that expand (German/Finnish typically +30%), confirm no cultural assumptions in text that would need locale-specific variants
- **world-builder**: Finalize canon levels for all new lore entries

### Write the finals
You hold every draft. List the final documents from the table above, then ask once
via `AskUserQuestion` — "May I write these [N] narrative documents to
`design/narrative/`?" — and write them on approval. The drafts under
`production/narrative/[content-slug]/` stay as the working record.

## 流水线

### 阶段 1：叙事方向
委派给 **narrative-director**：
- 定义本内容的叙事目的：它服务于哪个故事节奏点？
- 识别涉及的角色、他们的动机，以及这如何契合整体弧线
- 设定情感基调和节奏目标
- 明确任何传说依赖或本次引入的新传说
- 输出：带故事要求的叙事简报

### 阶段 2：世界基础（并行）
并行委派 —— 在等待任何结果之前同时发出全部三个 `Agent` 调用：
- **world-builder**：为本内容相关的派系、地点和历史创建或更新传说条目。与既有传说交叉比对以找出矛盾。为新条目设定正典等级。
- **writer**：使用角色声音档案起草角色对话。确保所有行都少于 120 个字符、对变量使用具名占位符，并且可本地化。
- **art-director**：为本内容中出现的关键角色定义角色视觉设计方向（剪影、视觉原型、区别性特征）。为每个关键空间明确环境视觉叙事元素（道具构图、灯光注记、空间布置）。为任何过场或脚本化序列定义基调色板和电影化方向。

**阶段门禁：** 收集全部三个阶段 2 的输出，然后在开始阶段 3 之前应用决策点
规则 —— 呈现传说、对话和视觉方向
摘要，在 `collaborative` 模式下通过 `AskUserQuestion` 获取批准
（在 `guided` 下自动推进，除非某结果为 BLOCKED；在
`autonomous` 下用 `log_decision`）。

### 阶段 3：关卡叙事整合
委派给 **level-designer**：
- 审阅叙事简报和传说基础
- 在关卡中设计环境叙事元素
- 放置叙事触发器、对话区域和发现点
- 确保节奏同时服务于玩法和故事

### 阶段 4：评审与一致性
通过 `Agent` 使用门禁 **ND-CONSISTENCY**
（`.claude/docs/director-gates/nd-consistency.md`）派生 `narrative-director`。本阶段在每种评审
模式下都运行 —— 它是本流水线自己的评审，而不是可选的导演门禁。传入该门禁列出的
上下文（阶段 2–3 的草稿路径、叙事圣经或基调
指南、世界规则、受影响的角色和派系档案）—— 已在此点名，
所以不要在本会话中读门禁文件 —— 并补充：
- 确认叙事节奏与关卡设计对齐
- 检查所有谜团都有记载的"真正答案"

按结论行动：**APPROVE** → 阶段 5。**CONCERNS** → 展示所列出的
不一致，并通过 `AskUserQuestion` 询问是修订它们（重新派生负责各处的
智能体）还是接受它们。**REJECT** → 不要开始阶段 5；先修复矛盾。
**NOT ASSESSED [missing input]** → 点名
缺失的输入，然后提供它并重跑门禁，或把
`ND-CONSISTENCY: NOT ASSESSED — [input]` 带入报告的一致性评审
结果中；它绝不被读作 APPROVE（`.claude/docs/director-gates.md`）。

**在 `team.size: individual` 下** narrative-director 不在活跃集中，所以该
门禁不会被派生。writer 按同样的标准检查草稿，
输出按名称说明这一点："ND-CONSISTENCY not run — narrative-director is not
active at `team.size: individual`; consistency self-checked by writer." 一次
自检不是门禁的结论，报告绝不能把它呈现为结论。

### 阶段 5：打磨（并行）
并行委派 —— 在等待任何结果之前发出每个 `Agent` 调用：
- **writer**：最终自审 —— 验证没有一行超出对话框约束、所有文本都使用字符串键（而非原始字符串）、占位符变量名一致
- **localization-lead**：验证 i18n 合规 —— 检查字符串键命名约定，标记任何带有硬编码格式、无法经受翻译的字符串，验证会膨胀语言（德语/芬兰语通常 +30%）的字符限制余量，确认文本中没有需要按地区定制变体的文化假定
- **world-builder**：为所有新传说条目最终确定正典等级

### 写入终稿
你掌握每一份草稿。列出上表中的最终文档，然后通过 `AskUserQuestion` 一次性询问
—— "May I write these [N] narrative documents to
`design/narrative/`?" —— 并在批准后写入它们。`production/narrative/[content-slug]/` 下的草稿
保留作为工作记录。

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

## 错误恢复协议

**首先，验证资产。** 如果返回契约点名了一个路径，在把该阶段视为完成之前检查该
路径是否存在 —— **一个不在磁盘上的具名资产就是一个失败的阶段，无论回复读起来多流畅。**
智能体可能耗掉整整一个阶段，什么也没写却返回一段看似合理的前言，那
既不是 BLOCKED，也不是错误，也不是"无法完成"，所以下面的触发器
永远不会触发。带着未满足的契约继续它；上下文
通常还在。

如果任何被派生的智能体返回 BLOCKED、报错或无法完成：**立即呈现它，
不要越过它所阻塞的依赖继续，并始终产出一份部分报告。** 被跳过智能体的章节保留为一个具名缺口 —— 绝不用你自己的内容填补它。完整流程：`.claude/docs/error-recovery-protocol.md`。

常见阻塞项：
- 输入文件缺失（找不到故事、GDD 缺失）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦它被决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆成两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测

## File Write Protocol

Sub-agents write their drafts to the `production/narrative/[content-slug]/` paths
you name, under the **bounded exception** documented above under "Why this does
not violate the Collaboration Protocol" — the path is one you named, the artifact
is new under `production/`, `docs/` or `tests/`, and the phase is gated by an
`AskUserQuestion`. A sub-agent does **not** prompt per write inside those bounds;
outside them it must ask. The **one exception is the final documents under
`design/narrative/`**: you hold every draft, so you write those yourself after
the single "May I write …?" in "Write the finals".

## 文件写入协议

子智能体把草稿写入你指定的 `production/narrative/[content-slug]/` 路径，
依据上面"Why this does not violate the Collaboration Protocol"中记载的**有限例外** —— 路径是你指定的，资产
是 `production/`、`docs/` 或 `tests/` 下的新文件，且该阶段由
`AskUserQuestion` 门控。在这些边界内，子智能体**不**逐次写入都提示；
在边界之外它必须询问。**唯一的例外是 `design/narrative/` 下的最终文档**：
你掌握每一份草稿，所以在"写入终稿"中那次唯一的"May I write …?"之后，你自己写那些。

## Output

A summary report covering: narrative brief status, lore entries created/updated, dialogue lines written, level narrative integration points, consistency review results, and any unresolved contradictions — including any localization issue the user chose to leave unfixed, by string key.

Verdict: **COMPLETE** — narrative content delivered.

If ND-CONSISTENCY answered NOT ASSESSED and that was carried into the report
(Phase 4), the verdict says so — never a plain COMPLETE:

Verdict: **COMPLETE — consistency NOT ASSESSED ([input])** — narrative content delivered; the consistency review could not run for want of [input].

If the pipeline stops because a dependency is unresolved (e.g., lore contradiction or missing prerequisite not resolved by the user):

Verdict: **BLOCKED** — [reason]

## 输出

一份总结报告，涵盖：叙事简报状态、创建/更新的传说条目、写出的对话行数、关卡叙事整合点、一致性评审结果，以及任何未解决的矛盾 —— 包括用户选择暂不修复的任何本地化问题（按字符串键）。

结论：**COMPLETE** —— 叙事内容已交付。

如果 ND-CONSISTENCY 回答 NOT ASSESSED 且该结果被带入报告
（阶段 4），结论要说明这一点 —— 绝不用单纯的 COMPLETE：

结论：**COMPLETE — consistency NOT ASSESSED ([input])** —— 叙事内容已交付；因缺少 [input]，一致性评审无法运行。

如果流水线因依赖未解决而停止（例如，传说矛盾或缺失的前置条件未被用户解决）：

结论：**BLOCKED** —— [reason]

## Next Steps

- Run `/design-review` on the narrative documents for consistency validation.
- Run `/localize extract` to extract new strings for translation after dialogue is finalized.
- Run `/dev-story` to implement dialogue triggers and narrative events in-engine.

## 下一步

- 对叙事文档运行 `/design-review` 进行一致性验证。
- 在对话定稿后运行 `/localize extract` 提取新字符串以供翻译。
- 运行 `/dev-story` 在引擎中实现对话触发器和叙事事件。
