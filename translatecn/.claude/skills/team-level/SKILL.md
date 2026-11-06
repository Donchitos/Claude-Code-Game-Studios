---
name: team-level
description: "Orchestrate the level team — level-designer, narrative-director, world-builder, art-director, systems-designer, qa-tester — for complete area creation."
argument-hint: "[level name or area to design] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-level/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: team-level
description: "编排关卡团队——level-designer、narrative-director、world-builder、art-director、systems-designer、qa-tester——以完成完整区域创建。"
argument-hint: "[level name or area to design] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-level/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team Level
# 关卡团队

If no argument is provided, output usage guidance and exit without spawning any agents or reading any design files:
> Usage: `/team-level [level name or area to design] [--review full|lean|solo]` — specify the level or area to design (e.g., `forest temple`, `tutorial village`, `final boss arena`). Do not use `AskUserQuestion` here; output the guidance directly.

如果未提供参数，输出使用指引并退出，不生成任何智能体，也不读取任何设计文件：
> 用法：`/team-level [要设计的关卡名称或区域] [--review full|lean|solo]`——指定要设计的关卡或区域（例如 `forest temple`、`tutorial village`、`final boss arena`）。此处不要使用 `AskUserQuestion`；直接输出该指引。

When this skill is invoked:

当本技能被调用时：

**Decision Points:** At each step transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next step.
In `guided` mode the pipeline advances automatically unless a step is BLOCKED;
in `autonomous` mode it runs end to end, recording each step outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**决策点：** 在每次步骤转换时，使用 `AskUserQuestion` 将子智能体的提案作为可选项呈现给用户。在对话中写出智能体的完整分析，然后用简洁标签捕获决策。在 `collaborative` 模式下，用户必须批准后才能进入下一步。在 `guided` 模式下，流水线自动推进，除非某步骤为 BLOCKED；在 `autonomous` 模式下，它端到端运行，并通过 `log_decision` 记录每个步骤结果。`automation_always_ask` 类别（`is_always_ask_category` 辅助函数）中的决策无论模式如何总是提示。参见 `.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config
## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

已在上方解析——按原样使用；`--review` 覆盖 `review_mode`。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.

`review_mode` 设定总监门禁深度，而此流水线没有总监门禁：以下没有任何阶段会在任何 `review_mode` 下生成 CD-、TD-、PR- 或 AD-PHASE-GATE。它的阶段门禁是流水线自身的决策点（在下方 `team.size` 下定义），在这些决策点工作的智能体是团队成员，而不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

`automation` 驱动上方的决策点说明。参见上方的决策点说明以及 `.claude/docs/automation-modes.md`，了解每种模式如何改变流水线行为。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `level-designer` only. Other agents consulted via the level-designer, not spawned separately.
- **`small`**: + `systems-designer` + `art-director` + `qa-tester`.
- **`studio`**: + `narrative-director` + `world-builder` + `accessibility-specialist` (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**`team.size`**：哪些智能体处于活动状态（与 review_mode 门禁深度及工作流文档正交）。
- **`individual`**（默认）：仅 `level-designer`。其他智能体通过 level-designer 咨询，而不是单独生成。
- **`small`**：+ `systems-designer` + `art-director` + `qa-tester`。
- **`studio`**：+ `narrative-director` + `world-builder` + `accessibility-specialist`（如文档所述的全流水线）。
在 `individual` 下需要的非核心智能体会通过最近的活动核心智能体路由，并附带信息性说明。**“阶段门禁”指任何以本流水线自身列出的 `AskUserQuestion` 决策点结束的阶段**——上方决策点下的转换，或下方流水线中写入的 **Gate** 步骤——**无论 `automation` 模式如何。** `guided` 和 `autonomous` 改变门禁的通过方式（自动推进，或用 `log_decision` 记录），而不改变它是否是门禁，因此下方的有界例外条件（3）在每种模式下都适用于它。被限定为“仅阶段门禁”的智能体只会在那些点生成，不会在其他点生成。这种活动集范围界定贯穿下方整个流水线：任何提到活动集之外智能体的阶段都会通过最近的核心智能体路由，而不是生成它。

**Announce the active set before Step 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

**在步骤 1 之前宣布活动集——绝不能让收缩悄无声息。**
在生成任何内容之前，用一行说明本次运行实际会生成哪些智能体，以及下方流水线提到但在解析出的 `team.size` 下**不会**生成的智能体。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

> `活动集（team.size: <resolved>）：<上方为该尺寸列出的智能体>.`
> `本次未生成：<本流水线提到的其他所有智能体>——通过 <nearest active core agent> 咨询。提高 team.size（或 modes.rigor）以扩大。`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

直接从上方 `team.size` 列表以及本文件自身流水线提到的智能体来填充——不要照搬示例。两个集合因编排器而异。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

下方流水线读起来像是多智能体扇出，而在交付默认值下它是一到两个智能体——`team-release` 提到十个却运行一个，`team-narrative` 在五个阶段提到六个却只单独运行 `writer`。**这种收缩是正确的**：`team.size` 以严谨度为导向，狭窄的默认值是 token 杠杆。若不说明，读者无法区分正确收缩的运行与损坏的流水线，而上文逐智能体的“通过最近核心智能体路由并附带信息性说明”规则在路由时触发，从不说明整体运行的形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

这与本文件其他地方关于跳过检查报告的同一条规则一致：**一个被强制执行却从未呈现的约束，对阅读输出的人而言，与从未被执行的约束无法区分。**

1. **Read the argument** for the target level or area (e.g., `tutorial`,
   `forest dungeon`, `hub town`, `final boss arena`).

1. **读取参数**，获取目标关卡或区域（例如 `tutorial`、`forest dungeon`、`hub town`、`final boss arena`）。

2. **Gather context** (read each design doc by section: find the headings you need
   with the Grep tool with pattern `^#` in content mode, and Read those ranges
   with offset and limit):
   - Read the game concept at `design/gdd/game-concept.md` — or `design/game-brief.md`,
     the one-page brief that replaces it at `rigor: minimal` — if either exists
   - Read game pillars at `design/gdd/game-pillars.md`
   - Read existing level docs in `design/levels/`
   - Read relevant narrative docs in `design/narrative/`
   - Read world-building docs for the area's region/faction

2. **收集上下文**（按章节读取每份设计文档：用 Grep 工具以 `^#` 模式和内容模式查找所需标题，并用 offset 和 limit 读取那些范围）：
   - 读取 `design/gdd/game-concept.md` 处的游戏概念——或 `design/game-brief.md`，即在 `rigor: minimal` 下替代它的一页简报——如果任一存在
   - 读取 `design/gdd/game-pillars.md` 中的游戏支柱
   - 读取 `design/levels/` 中现有的关卡文档
   - 读取 `design/narrative/` 中相关的叙事文档
   - 读取该区域所处地区/阵营的世界构建文档

## How to Delegate
## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: narrative-director` — Narrative purpose, characters, emotional arc
- `subagent_type: world-builder` — Lore context, environmental storytelling, world rules
- `subagent_type: level-designer` — Spatial layout, pacing, encounters, navigation
- `subagent_type: systems-designer` — Enemy compositions, loot tables, difficulty balance
- `subagent_type: art-director` — Visual theme, color palette, lighting, asset requirements
- `subagent_type: accessibility-specialist` — Navigation clarity, colorblind safety, cognitive load
- `subagent_type: qa-tester` — Test cases, boundary testing, playtest checklist

使用 `Agent` 工具将每位团队成员生成为子智能体：
- `subagent_type: narrative-director`——叙事目的、角色、情感弧线
- `subagent_type: world-builder`——设定背景、环境叙事、世界规则
- `subagent_type: level-designer`——空间布局、节奏、遭遇、导航
- `subagent_type: systems-designer`——敌人构成、战利品表、难度平衡
- `subagent_type: art-director`——视觉主题、色彩调色板、光照、资产需求
- `subagent_type: accessibility-specialist`——导航清晰度、色盲安全、认知负荷
- `subagent_type: qa-tester`——测试用例、边界测试、试玩检查清单

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**给每个智能体简要说明——不要倾倒上下文。** 将共享输入**一次**读取，并以内联方式传递精简摘要：每个智能体实际需要的那些行，绝不为已读过的文档传文件路径（拿到路径的智能体会重读整个文件）。只有当你未读过且仅该智能体需要的文档才传路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**在每个智能体提示末尾加上返回契约：**“将你的完整输出写入 `[path]`——该命名路径是下方有界例外下的写入授权，因此无需单独的批准提示即可写入。仅返回 (1) 写入的路径，(2) ≤5 条决策要点摘要，(3) 任何 BLOCKED/CONCERNS 项，每项一行。不要重述你读过的文档。”没有它，智能体会把它读到的一切都返回本会话。

**Substitute a real path for `[path]`.** Working artifacts go under
`production/levels/[level-name]/`, slugged as in the "Save to" step below. One
file per agent, so the parallel steps never share one:

**用真实路径替换 `[path]`。** 工作产物放在 `production/levels/[level-name]/` 下，按下方“保存到”步骤进行 slug 化。每个智能体一个文件，因此并行步骤绝不会共用一个：

| Step / agent | Writes to |
|---|---|
| 1 narrative-director | `production/levels/[level-name]/narrative.md` |
| 1 world-builder | `production/levels/[level-name]/lore.md` |
| 1 art-director | `production/levels/[level-name]/visual-direction.md` |
| 2 level-designer | `production/levels/[level-name]/layout.md` |
| 3 systems-designer | `production/levels/[level-name]/systems.md` |
| 4 art-director | `production/levels/[level-name]/production-concepts.md` |
| 4 accessibility-specialist | `production/levels/[level-name]/accessibility.md` |
| 5 qa-tester | `production/qa/test-cases/[level-name]-cases.md` — test cases, edge cases, playtest checklist, acceptance criteria |

| 步骤 / 智能体 | 写入到 |
|---|---|
| 1 narrative-director | `production/levels/[level-name]/narrative.md` |
| 1 world-builder | `production/levels/[level-name]/lore.md` |
| 1 art-director | `production/levels/[level-name]/visual-direction.md` |
| 2 level-designer | `production/levels/[level-name]/layout.md` |
| 3 systems-designer | `production/levels/[level-name]/systems.md` |
| 4 art-director | `production/levels/[level-name]/production-concepts.md` |
| 4 accessibility-specialist | `production/levels/[level-name]/accessibility.md` |
| 5 qa-tester | `production/qa/test-cases/[level-name]-cases.md`——测试用例、边缘情况、试玩检查清单、验收标准 |

These are working drafts; the durable record is the level design document you
compile from them (`design/levels/[level-name].md`).

这些是工作草稿；持久记录是你从中编译的关卡设计文档（`design/levels/[level-name].md`）。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问“我可以将此写入 [filepath] 吗？”。此处生成的子智能体在写入时**不**询问，这是有意且有界的例外，而非疏忽——与 `consistency-check` 追加到 `active.md` 所做的相同调用。该例外仅在以下三者同时成立时有效：（1）路径是**你**在提示中命名的，因此用户在批准该阶段时也批准了目的地；（2）它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不是对现有源码或配置的编辑；（3）产生它的阶段本身在流水线推进前由 `AskUserQuestion` 设门禁。超出这三者，智能体必须询问。**不要通过为每个子智能体逐一询问来“修复”这一点**——每个智能体每个阶段一次提示会让编排器无法使用，这正是该例外存在的原因。

3. **Orchestrate the level design team** in sequence:

3. **按顺序编排关卡设计团队：**

### Step 1: Narrative + Visual Direction (narrative-director + world-builder + art-director, parallel)
### 步骤 1：叙事 + 视觉方向（narrative-director + world-builder + art-director，并行）

Spawn all three agents simultaneously — issue all three `Agent` calls before waiting for any result.

同时生成三个智能体——在等待任何结果之前发出全部三个 `Agent` 调用。

Spawn the `narrative-director` agent to:
- Define the narrative purpose of this area (what story beats happen here?)
- Identify key characters, dialogue triggers, and lore elements
- Specify emotional arc (how should the player feel entering, during, leaving?)

生成 `narrative-director` 智能体以：
- 定义该区域的叙事目的（这里发生哪些故事节拍？）
- 识别关键角色、对话触发器和设定元素
- 指定情感弧线（玩家进入、期间、离开时应有什么感受？）

Spawn the `world-builder` agent to:
- Provide lore context for the area (history, faction presence, ecology)
- Define environmental storytelling opportunities
- Specify any world rules that affect gameplay in this area

生成 `world-builder` 智能体以：
- 为该区域提供设定背景（历史、阵营存在、生态）
- 定义环境叙事机会
- 指定任何影响该区域玩法的世界规则

Spawn the `art-director` agent to:
- Establish visual theme targets for this area — these are INPUTS to layout, not outputs of it
- Define the color temperature and lighting mood for this area (how does it differ from adjacent areas?)
- Specify shape language direction (angular fortress? organic cave? decayed grandeur?)
- Name the primary visual landmarks that will orient the player
- Read `design/art/art-bible.md` if it exists — anchor all direction in the established art bible. Read it by section: find the headings you need with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit.

生成 `art-director` 智能体以：
- 为该区域建立视觉主题目标——这些是布局的**输入**，而不是它的输出
- 定义该区域的色温和光照氛围（它与相邻区域有何不同？）
- 指定形状语言方向（棱角分明的堡垒？有机洞穴？衰败的宏伟？）
- 命名将引导玩家定位的主要视觉地标
- 如果存在 `design/art/art-bible.md`，读取它——将所有方向锚定在已建立的美术圣经中。按章节读取：用 Grep 工具（模式 `^#`，内容模式）查找所需标题，并用 offset 和 limit 读取那些范围。

**The art-director's visual targets from Step 1 must be passed to the level-designer in Step 2** as explicit constraints. Layout decisions happen within the visual direction, not before it.

**步骤 1 中 art-director 的视觉目标必须作为明确约束传递给步骤 2 的 level-designer。** 布局决策发生在视觉方向之内，而不是之前。

**Gate**: Use `AskUserQuestion` to present all three Step 1 outputs (narrative brief, lore foundation, visual direction targets) and confirm before proceeding to Step 2.

**门禁**：使用 `AskUserQuestion` 呈现步骤 1 的全部三个输出（叙事简报、设定基础、视觉方向目标），并在进入步骤 2 前确认。

### Step 2: Layout and Encounter Design (level-designer)
### 步骤 2：布局与遭遇设计（level-designer）
Spawn the `level-designer` agent with the full Step 1 output as context:
- Narrative brief (from narrative-director)
- Lore foundation (from world-builder)
- **Visual direction targets (from art-director)** — layout must work within these targets, not contradict them

以完整步骤 1 输出作为上下文生成 `level-designer` 智能体：
- 叙事简报（来自 narrative-director）
- 设定基础（来自 world-builder）
- **视觉方向目标（来自 art-director）**——布局必须在这些目标之内工作，而不是与之矛盾

The level-designer should:
- Design the spatial layout (critical path, optional paths, secrets) — ensuring primary routes align with the visual landmark targets from Step 1
- Define pacing curve (tension peaks, rest areas, exploration zones) — coordinated with the emotional arc from narrative-director
- Place encounters with difficulty progression
- Design environmental puzzles or navigation challenges
- Define points of interest and landmarks for wayfinding — these must match the visual landmarks the art-director specified
- Specify entry/exit points and connections to adjacent areas

level-designer 应当：
- 设计空间布局（关键路径、可选路径、秘密）——确保主要路线与步骤 1 的视觉地标目标一致
- 定义节奏曲线（紧张峰值、休息区域、探索区域）——与 narrative-director 的情感弧线协调
- 放置具有难度递进的遭遇
- 设计环境谜题或导航挑战
- 定义用于寻路的兴趣点和地标——这些必须匹配 art-director 指定的视觉地标
- 指定入口/出口点以及与相邻区域的连接

**Adjacent area dependency check**: After the layout is produced, check `design/levels/` for each adjacent area referenced by the level-designer. If any referenced area's `.md` file does not exist, surface the gap:
> "Level references [area-name] as an adjacent area but `design/levels/[area-name].md` does not exist."

**相邻区域依赖检查**：布局产出后，检查 `design/levels/` 中 level-designer 引用的每个相邻区域。如果任何被引用区域的 `.md` 文件不存在，揭示该缺口：
> “关卡将 [area-name] 引用为相邻区域，但 `design/levels/[area-name].md` 不存在。”

Use `AskUserQuestion` with options:
- (a) Proceed with a placeholder reference — mark the connection as UNRESOLVED in the level doc and list it in the open cross-level dependencies section of the summary report
- (b) Pause and run `/team-level [area-name]` first to establish that area

使用 `AskUserQuestion` 提供选项：
- (a) 以占位引用继续——在关卡文档中将该连接标记为 UNRESOLVED，并在摘要报告的开放跨关卡依赖部分列出它
- (b) 暂停并先运行 `/team-level [area-name]` 以建立该区域

Do NOT invent content for the missing adjacent area.

不要为缺失的相邻区域编造内容。

**Gate**: Use `AskUserQuestion` to present Step 2 layout (including any unresolved adjacent area dependencies) and confirm before proceeding to Step 3.

**门禁**：使用 `AskUserQuestion` 呈现步骤 2 布局（包括任何未解决的相邻区域依赖），并在进入步骤 3 前确认。

### Step 3: Systems Integration (systems-designer)
### 步骤 3：系统集成（systems-designer）
Spawn the `systems-designer` agent to:
- Specify enemy compositions and encounter formulas
- Define loot tables and reward placement
- Balance difficulty relative to expected player level/gear
- Design any area-specific mechanics or environmental hazards
- Specify resource distribution (health pickups, save points, shops)

生成 `systems-designer` 智能体以：
- 指定敌人构成和遭遇公式
- 定义战利品表和奖励放置
- 相对于预期玩家等级/装备平衡难度
- 设计任何区域特定机制或环境危害
- 指定资源分布（生命拾取物、存档点、商店）

**Gate**: Use `AskUserQuestion` to present Step 3 outputs and confirm before proceeding to Step 4.

**门禁**：使用 `AskUserQuestion` 呈现步骤 3 输出，并在进入步骤 4 前确认。

### Step 4: Production Concepts + Accessibility (art-director + accessibility-specialist, parallel)
### 步骤 4：制作概念 + 无障碍（art-director + accessibility-specialist，并行）

**Note**: The art-director's directional pass (visual theme, color targets, mood) happened in Step 1. This pass is location-specific production concepts — given the finalized layout, what does each specific space look like?

**注意**：art-director 的方向性处理（视觉主题、色彩目标、氛围）发生在步骤 1。本次处理是位置特定的制作概念——在最终布局已定的情况下，每个具体空间看起来是什么样？

Spawn the `art-director` agent with the finalized layout from Step 2:
- Produce location-specific concept specs for key spaces (entrance, key encounter zones, landmarks, exits)
- Specify which art assets are unique to this area vs. shared from the global pool
- Define sight-line and lighting setups per key space (these are now layout-informed, not directional)
- Specify VFX needs that are specific to this area's layout (weather volumes, particles, atmospheric effects)
- Flag any locations where the layout creates visual direction conflicts with the Step 1 targets — surface these as production risks

以步骤 2 的最终布局生成 `art-director` 智能体：
- 为关键空间（入口、关键遭遇区域、地标、出口）产出位置特定的概念规格
- 指定哪些美术资产是该区域独有，哪些来自全局池共享
- 为每个关键空间定义视线和光照设置（这些现在受布局影响，而非方向性）
- 指定该区域布局特有的 VFX 需求（天气体积、粒子、大气效果）
- 标记任何布局与步骤 1 目标产生视觉方向冲突的位置——将其作为制作风险呈现

Spawn the `accessibility-specialist` agent in parallel to:
- Review the level layout for navigation clarity (can players orient themselves without relying on color alone?)
- Check that critical path signposting uses shape/icon/sound cues in addition to color
- Review any puzzle mechanics for cognitive load — flag anything that requires holding more than 3 simultaneous states
- Check that key gameplay areas have sufficient contrast for colorblind players
- Output: accessibility concerns list with severity (BLOCKING / RECOMMENDED / NICE TO HAVE)

并行生成 `accessibility-specialist` 智能体以：
- 评审关卡布局的导航清晰度（玩家能否在不只依赖颜色的情况下定位自己？）
- 检查关键路径标识在颜色之外还使用形状/图标/声音提示
- 评审任何谜题机制的认知负荷——标记任何需要同时保持超过 3 个状态的内容
- 检查关键玩法区域对色盲玩家有足够的对比度
- 输出：带严重程度（BLOCKING / RECOMMENDED / NICE TO HAVE）的无障碍关注列表

Wait for both agents to return before proceeding.

在继续之前等待两个智能体返回。

**Gate**: Use `AskUserQuestion` to present both Step 4 results. If the accessibility-specialist returned any BLOCKING concerns, highlight them prominently and offer:
- (a) Return to level-designer and art-director to redesign the flagged elements before Step 5
- (b) Document as a known accessibility gap and proceed to Step 5 with the concern explicitly logged in the final report

**门禁**：使用 `AskUserQuestion` 呈现步骤 4 的两个结果。如果 accessibility-specialist 返回任何 BLOCKING 关注项，突出显示它们并提供：
- (a) 回到 level-designer 和 art-director，在步骤 5 前重新设计被标记的元素
- (b) 记录为已知无障碍缺口，并在最终报告中明确记录该关注项的情况下进入步骤 5

Do NOT proceed to Step 5 without the user acknowledging any BLOCKING accessibility concerns.

在用户确认任何 BLOCKING 无障碍关注项之前，不要进入步骤 5。

### Step 5: QA Planning (qa-tester)
### 步骤 5：QA 规划（qa-tester）
Spawn the `qa-tester` agent to:
- Write test cases for the critical path
- Identify boundary and edge cases (sequence breaks, softlocks)
- Create a playtest checklist for the area
- Define acceptance criteria for level completion

生成 `qa-tester` 智能体以：
- 为关键路径编写测试用例
- 识别边界和边缘情况（序列破坏、软锁）
- 为该区域创建试玩检查清单
- 定义关卡完成的验收标准

4. **Compile the level design document** combining all team outputs into the
   level design template format.

4. **编译关卡设计文档**，将所有团队输出合并为关卡设计模板格式。

The orchestrator already holds every sub-agent's output — **compile the document
itself; do not re-spawn `level-designer` and re-send all outputs verbatim.** That
second spawn pays a fresh agent's overhead plus a full re-transmission of context
the orchestrator already has, to move text it is already holding. After compiling
into the level-design template format, ask the user directly via
`AskUserQuestion`: "May I write the compiled level design to
`design/levels/[level-name].md`?" On approval, write it.

编排器已经持有每个子智能体的输出——**自行编译文档；不要重新生成 `level-designer` 并原样重发所有输出。** 第二次生成要付出新智能体的开销，加上编排器已拥有上下文的完整重传，只为移动它已经持有的文本。编译为关卡设计模板格式后，通过 `AskUserQuestion` 直接询问用户：“我可以将编译好的关卡设计写入 `design/levels/[level-name].md` 吗？”批准后写入。

5. **Save to** `design/levels/[level-name].md` after that approval.
   `[level-name]` is the argument as a slug — lowercase, spaces → hyphens
   (`forest dungeon` → `forest-dungeon.md`) — and `[area-name]` in the adjacent
   area check is slugged the same way.

5. 在该批准之后**保存到** `design/levels/[level-name].md`。`[level-name]` 是作为 slug 的参数——小写，空格 → 连字符（`forest dungeon` → `forest-dungeon.md`）——相邻区域检查中的 `[area-name]` 以相同方式 slug 化。

6. **Output a summary** with: area overview, encounter count, estimated asset
   list, narrative beats, any cross-team dependencies or open questions, open
   cross-level dependencies (adjacent areas referenced but not yet designed, each
   marked UNRESOLVED), and accessibility concerns with their resolution status.

6. **输出摘要**，包含：区域概览、遭遇数量、估计资产列表、叙事节拍、任何跨团队依赖或开放问题、开放跨关卡依赖（被引用但尚未设计的相邻区域，每个标记为 UNRESOLVED），以及带解决状态的无障碍关注项。

## File Write Protocol
## 文件写入协议

Per-agent artifacts (narrative docs, test checklists) are written by the
sub-agent that produced them, under the **bounded exception** documented above
under "Why this does not violate the Collaboration Protocol" — the path is one
you named, the artifact is new under `production/`, `docs/` or `tests/`, and the
phase is gated by an `AskUserQuestion`. A sub-agent does **not** prompt per write
inside those bounds; outside them it must ask. The **one exception is the final
compiled level-design document**: the
orchestrator already holds every input, so it compiles and writes that file
itself after its own "May I write …?" prompt (Step 4) — re-spawning an agent
just to write text the orchestrator is already holding is pure overhead.

每个智能体的产物（叙事文档、测试检查清单）由产生它们的子智能体写入，依据上方“为什么这不违反协作协议”中记录的有界例外——路径是你命名的，产物是 `production/`、`docs/` 或 `tests/` 下的新内容，并且该阶段由 `AskUserQuestion` 设门禁。在这些范围内，子智能体**不会**每次写入都提示；超出范围则必须询问。**唯一的例外是最终编译的关卡设计文档**：编排器已经持有每个输入，因此它在自己的“我可以写入……吗？”提示（步骤 4）之后自行编译并写入该文件——仅仅为了写入编排器已持有的文本而重新生成智能体纯属额外开销。

Verdict: **COMPLETE** — level design document produced and all team outputs compiled.
Verdict: **BLOCKED** — one or more agents blocked, or an agent was skipped (`.claude/docs/error-recovery-protocol.md` step 5); partial report produced with unresolved items listed.

结论：**COMPLETE**——关卡设计文档已产出，所有团队输出已编译。
结论：**BLOCKED**——一个或多个智能体受阻，或某智能体被跳过（`.claude/docs/error-recovery-protocol.md` 步骤 5）；已产出部分报告并列出未解决项。

## Next Steps
## 后续步骤

- Run `/design-review design/levels/[level-name].md` to validate the completed level design doc.
- Run `/dev-story` to implement level content once the design is approved.
- Run `/qa-plan` to generate a QA test plan for this level.

- 运行 `/design-review design/levels/[level-name].md` 以验证已完成的关卡设计文档。
- 设计批准后，运行 `/dev-story` 实现关卡内容。
- 运行 `/qa-plan` 为该关卡生成 QA 测试计划。

## Error Recovery Protocol
## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

**首先，验证产物。** 如果返回契约命名了路径，在将该阶段视为完成之前检查路径是否存在——**命名产物不在磁盘上就是失败的阶段，无论响应读起来多么流畅。** 智能体可能耗费整个阶段，却返回一段貌似合理的前言而什么都没写，这既不是 BLOCKED，也不是错误，也不是“无法完成”，因此下方的触发器永远不会触发。以未满足的契约重新启动它；上下文通常仍在。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

如果任何生成的智能体返回 BLOCKED、出错或无法完成：**立即呈现，不要越过它阻塞的依赖继续，并始终产出部分报告。** 被跳过智能体的部分保持为命名缺口——绝不用你自己的内容填充。完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

常见阻塞：
- 输入文件缺失（故事未找到、GDD 不存在）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆分为两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测
