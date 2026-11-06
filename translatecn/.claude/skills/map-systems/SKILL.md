---
name: map-systems
description: "Decompose a concept into individual systems, map dependencies, prioritize design order, create the systems index."
argument-hint: "[next | system-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Agent, Bash(bash "*/.claude/skills/map-systems/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: map-systems
description: "将概念分解为各个系统、映射依赖关系、确定设计顺序优先级、创建系统索引。"
argument-hint: "[next | system-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Agent, Bash(bash "*/.claude/skills/map-systems/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,project.stage`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Map Systems

# 映射系统


When this skill is invoked:

本技能被调用时：

## Parse Arguments

## 解析参数

Two modes:

两种模式：

- **No argument**: `/map-systems` — Run the full decomposition workflow (Phases 1-5)
  to create or update the systems index.
- **`next`**: `/map-systems next` — Pick the highest-priority undesigned system
  from the index and hand off to `/design-system` (Phase 6).

- **无参数**：`/map-systems` — 运行完整的分解工作流（阶段 1-5）
  以创建或更新系统索引。
- **`next`**：`/map-systems next` — 从索引中挑选优先级最高的未设计系统，
  并交接给 `/design-system`（阶段 6）。


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

完整的检查模式见 `.claude/docs/director-gates.md`。各项门禁定义位于 `.claude/docs/director-gates/[gate-id].md` 中 — 被派生的智能体读取自己的门禁文件；不要在父会话中读取它。


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). In collaborative mode the
system list, dependency, priority and write approvals are separate questions:
each waits for its answer before the next step runs.

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重大事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终提示）。在协作模式下，系统列表、依赖、优先级和
写入批准是彼此独立的问题：每一个都会等到其回答后才运行下一步。

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = one-line system descriptions;
`balanced` = a brief paragraph per system + dependency notes (`rigor: standard`);
`thorough` = full system-by-system rationale + relationship analysis. Apply it to
every section you author.

**`docs.density`** — 它控制每个章节的*深度*，而 `workflow`
控制哪些章节存在。`modes.rigor` 同时设置两者；若要单独改变深度，请显式设置
`docs.density`：`terse`（默认，经由 `rigor: minimal`）= 一行系统描述；
`balanced` = 每个系统一段简述 + 依赖注释（`rigor: standard`）；
`thorough` = 完整的逐系统理由 + 关系分析。将其应用于
你编写的每个章节。

> **Where the per-system prose goes.** `templates/systems-index.md`'s Systems
> Enumeration is a fixed-column table with no description column, so at
> `balanced` and `thorough` the prose belongs in `## Overview` — one short
> paragraph per system at `balanced`, plus relationship analysis at `thorough` —
> and in the `## Dependency Map` layer notes. **Do not add a column to the
> enumeration table** — it is a fixed contract in
> `.claude/docs/templates/systems-index.md`, and its consumers
> (`/design-system` §6 and §7, `/create-epics`) are written against the columns it
> defines. Widening it is a schema change, not a formatting choice.
>
> **How the consumers actually read it.** Nothing parses this table
> positionally. The two scripts that mention `systems-index.md`
> (`gdd-structure-check.sh:51`, `review-scope.sh:40`) match it **by filename** in a
> `case` statement and parse no columns at all; the two skills key on the
> **`Category` column by name** (`design-system:229`, `:780`). So `Category` is
> the column that must never be renamed or dropped, and the table stays a fixed
> contract because every consumer is written against the set of columns the
> template defines.
> At `terse`, the table plus a one-paragraph `## Overview` is the whole output.

> **逐系统文字应该放在哪里。** `templates/systems-index.md` 的 Systems
> Enumeration 是一个固定列、没有描述列的表，因此在
> `balanced` 和 `thorough` 下，文字应放在 `## Overview` 中 — 在 `balanced` 下单系统一段简述，
> 再加上 `thorough` 下的关系分析 —
> 以及 `## Dependency Map` 的分层注释中。**不要给
> 枚举表增加列** — 它是
> `.claude/docs/templates/systems-index.md` 中的固定契约，其消费者
> （`/design-system` §6 和 §7、`/create-epics`）是针对它所定义的列编写的。
> 加宽它是一种模式变更，而非格式选择。
>
> **消费者实际如何读取它。** 没有任何东西按位置解析此表。
> 提及 `systems-index.md` 的两个脚本
> （`gdd-structure-check.sh:51`、`review-scope.sh:40`）在
> `case` 语句中**按文件名**匹配它，完全不解析任何列；两个技能则
> **按名称以 `Category` 列**为键（`design-system:229`、`:780`）。因此 `Category` 是
> 绝不能重命名或删除的列，而该表之所以保持固定
> 契约，是因为每个消费者都是针对模板所定义的列集合编写的。
> 在 `terse` 下，该表加一段 `## Overview` 就是全部输出。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` / `standard` — required before `/design-system` (systems must be mapped
  before per-system GDDs are authored).
- `minimal` — not required (the game brief replaces the systems index). Can
  still be run voluntarily.

**`workflow`**（见 `.claude/docs/workflow-modes.md`）：
- `full` / `standard` — `/design-system` 之前必需（必须先映射系统，
  才能编写逐系统 GDD）。
- `minimal` — 非必需（游戏简报替代系统索引）。仍可
  自愿运行。

---

## Phase 1: Read Concept (Required Context)

## 阶段 1：读取概念（必需上下文）

Read the game concept and any existing design work. This provides the raw material
for systems decomposition. Read each doc by section: find the headings you need with
the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and
limit.

读取游戏概念和任何既有设计工作。这为系统分解提供原材料。
按章节读取每个文档：用 Grep 工具（pattern `^#`，content 模式）找到所需标题，
再用 offset 和 limit 读取那些区间。

**Required:**
- Read `design/gdd/game-concept.md` (at `minimal`, read `design/game-brief.md`
  instead) — **fail with a clear message if neither is found**:
  > "No game concept found. Run `/brainstorm` first to create one, then come back
  > to decompose it into systems."

**必需：**
- 读取 `design/gdd/game-concept.md`（在 `minimal` 下改为读取 `design/game-brief.md`）
  — **若两者都找不到，则以清晰消息失败**：
  > "No game concept found. Run `/brainstorm` first to create one, then come back
  > to decompose it into systems."

**Optional (read if they exist):**
- Read `design/gdd/game-pillars.md` — pillars constrain priority and scope
- Read `design/gdd/systems-index.md` — if exists, **resume** from where it left off
  (update, don't recreate from scratch)
- Glob `design/gdd/*.md` — check which system GDDs already exist

**可选（存在则读取）：**
- 读取 `design/gdd/game-pillars.md` — 支柱约束优先级与范围
- 读取 `design/gdd/systems-index.md` — 若存在，**从中断处继续**（更新，而非从头重建）
- Glob `design/gdd/*.md` — 检查哪些系统 GDD 已经存在

**If the systems index already exists:**
- Read it and present current status to the user
- Use `AskUserQuestion` to ask:
  "The systems index already exists with [N] systems ([M] designed, [K] not started).
  What would you like to do?"
  - Options: "Update the index with new systems", "Design the next undesigned system",
    "Review and revise priorities"

**如果系统索引已存在：**
- 读取它并向用户呈现当前状态
- 使用 `AskUserQuestion` 询问：
  "The systems index already exists with [N] systems ([M] designed, [K] not started).
  What would you like to do?"
  - 选项："Update the index with new systems"、"Design the next undesigned system"、
    "Review and revise priorities"

---

## Phase 2: Systems Enumeration (Collaborative)

## 阶段 2：系统枚举（协作）

Extract and identify all systems the game needs. This is the creative core of the
skill — it requires human judgment because concept docs rarely enumerate every
system explicitly.

提取并识别游戏需要的所有系统。这是本技能的创造性核心 —
它需要人的判断，因为概念文档很少显式枚举每一个系统。

### Step 2a: Extract Explicit Systems

### 步骤 2a：提取显式系统

Scan the game concept for directly mentioned systems and mechanics:
- Core Mechanics section (most explicit)
- Core Loop section (implies what systems drive each loop tier)
- Technical Considerations section (networking, procedural generation, etc.)
- MVP Definition section (required features = required systems)

扫描游戏概念中直接提到的系统与机制：
- Core Mechanics 章节（最显式）
- Core Loop 章节（暗示哪些系统驱动每个循环层级）
- Technical Considerations 章节（网络、程序生成等）
- MVP Definition 章节（必需功能 = 必需系统）

### Step 2b: Identify Implicit Systems

### 步骤 2b：识别隐式系统

For each explicit system, identify the **hidden systems** it implies. Games always
need more systems than the concept doc mentions. Use this inference pattern:

- "Inventory" implies: item database, equipment slots, weight/capacity rules,
  inventory UI, item serialization for save/load
- "Combat" implies: damage calculation, health system, hit detection, status effects,
  enemy AI, combat UI (health bars, damage numbers), death/respawn
- "Open world" implies: streaming/chunking, LOD system, fast travel, map/minimap,
  point of interest tracking, world state persistence
- "Multiplayer" implies: networking layer, lobby/matchmaking, state synchronization,
  anti-cheat, network UI (ping, player list)
- "Crafting" implies: recipe database, ingredient gathering, crafting UI,
  success/failure mechanics, recipe discovery/learning
- "Dialogue" implies: dialogue tree system, dialogue UI, choice tracking, NPC
  state management, localization hooks
- "Progression" implies: XP system, level-up mechanics, skill tree, unlock
  tracking, progression UI, progression save data

对每个显式系统，识别它所隐含的**隐藏系统**。游戏需要的系统总是
比概念文档提到的更多。使用以下推断模式：

- "Inventory" 隐含：物品数据库、装备槽、重量/容量规则、
  背包 UI、用于存档/读档的物品序列化
- "Combat" 隐含：伤害计算、生命值系统、命中检测、状态效果、
  敌人 AI、战斗 UI（血条、伤害数字）、死亡/重生
- "Open world" 隐含：流式加载/分块、LOD 系统、快速旅行、地图/小地图、
  兴趣点追踪、世界状态持久化
- "Multiplayer" 隐含：网络层、大厅/匹配、状态同步、
  反作弊、网络 UI（延迟、玩家列表）
- "Crafting" 隐含：配方数据库、材料采集、制作 UI、
  成功/失败机制、配方发现/学习
- "Dialogue" 隐含：对话树系统、对话 UI、选择追踪、NPC
  状态管理、本地化钩子
- "Progression" 隐含：经验值系统、升级机制、技能树、解锁
  追踪、成长 UI、成长存档数据

Explain in conversation text why each implicit system is needed (with examples).

在对话文本中说明为什么需要每个隐式系统（附示例）。

### Step 2c: User Review

### 步骤 2c：用户评审

Present the enumeration organized by category. For each system, show:
- Name
- Category
- Brief description (1 sentence)
- Whether it was explicit (from concept) or implicit (inferred)

按类别组织呈现枚举结果。对每个系统，显示：
- 名称
- 类别
- 简述（1 句话）
- 它是显式的（来自概念）还是隐式的（推断而来）

Then use `AskUserQuestion` to capture feedback:
- "Are there systems missing from this list?"
- "Should any of these be combined or split?"
- "Are there systems listed that this game does NOT need?"

然后使用 `AskUserQuestion` 收集反馈：
- "Are there systems missing from this list?"
- "Should any of these be combined or split?"
- "Are there systems listed that this game does NOT need?"

**At `collaborative`** — iterate until the user approves the enumeration.
**At `guided`** — ask once, apply the answer, and proceed; do not loop.
**At `autonomous`** — do not ask. Record the enumeration and its inferred systems
via `log_decision` and proceed.

**在 `collaborative` 下** — 迭代直到用户批准该枚举。
**在 `guided` 下** — 询问一次，应用回答，然后继续；不要循环。
**在 `autonomous` 下** — 不要询问。通过 `log_decision` 记录枚举及其推断系统，
然后继续。

---

## Phase 3: Dependency Mapping (Collaborative)

## 阶段 3：依赖映射（协作）

For each system, determine what it depends on. A system "depends on" another if
it cannot function without that other system existing first.

对每个系统，确定它依赖什么。如果一个系统必须在另一个系统先存在的情况下
才能运作，则称它"依赖"另一个。

### Step 3a: Map Dependencies

### 步骤 3a：映射依赖

For each system, list its dependencies. Use these dependency heuristics:
- **Input/output dependencies**: System A produces data System B needs
- **Structural dependencies**: System A provides the framework System B plugs into
- **UI dependencies**: Every gameplay system has a corresponding UI system that
  depends on it (but UI is designed after the gameplay system)

对每个系统，列出其依赖。使用以下依赖启发式：
- **输入/输出依赖**：系统 A 产出系统 B 需要的数据
- **结构依赖**：系统 A 提供系统 B 接入的框架
- **UI 依赖**：每个玩法系统都有对应的 UI 系统依赖它
  （但 UI 在玩法系统之后设计）

### Step 3b: Sort by Dependency Order

### 步骤 3b：按依赖顺序排序

Arrange systems into layers:
1. **Foundation**: Systems with zero dependencies (designed and built first)
2. **Core**: Systems depending only on Foundation systems
3. **Feature**: Systems depending on Core systems
4. **Presentation**: UI and feedback systems that wrap gameplay systems
5. **Polish**: Meta-systems, tutorials, analytics, accessibility

将系统安排到分层中：
1. **Foundation**：零依赖的系统（最先设计和构建）
2. **Core**：仅依赖 Foundation 系统的系统
3. **Feature**：依赖 Core 系统的系统
4. **Presentation**：包裹玩法系统的 UI 与反馈系统
5. **Polish**：元系统、教程、分析、无障碍

### Step 3c: Detect Circular Dependencies

### 步骤 3c：检测循环依赖

Check for cycles in the dependency graph. If found:
- Highlight them to the user
- Propose resolutions (interface abstraction, simultaneous design, breaking the
  cycle by defining a contract between the two systems)

检查依赖图中的环。若发现：
- 向用户突出显示它们
- 提出解决方案（接口抽象、同时设计、通过在两个系统之间
  定义契约来打破环）

### Step 3d: Present to User

### 步骤 3d：向用户呈现

Show the dependency map as a layered list. Highlight:
- Any circular dependencies
- Any "bottleneck" systems (many others depend on them — these are high-risk)
- Any systems with no dependents (leaf nodes — lower risk, can be designed late)

以分层列表展示依赖图。突出显示：
- 任何循环依赖
- 任何"瓶颈"系统（许多其他系统依赖它们 — 这些是高风险的）
- 任何没有依赖者的系统（叶节点 — 风险较低，可以较晚设计）

Use `AskUserQuestion` to ask: "Does this dependency ordering look right? Any
dependencies I'm missing or that should be removed?"

使用 `AskUserQuestion` 询问："Does this dependency ordering look right? Any
dependencies I'm missing or that should be removed?"

**Review mode check** — apply before spawning TD-SYSTEM-BOUNDARY:
- `solo` → skip. Note: "TD-SYSTEM-BOUNDARY skipped — Solo mode." Proceed to priority assignment.
- `lean` → skip (not a PHASE-GATE). Note: "TD-SYSTEM-BOUNDARY skipped — Lean mode." Proceed to priority assignment.
- `full` → spawn as normal.

**评审模式检查** — 在派生 TD-SYSTEM-BOUNDARY 之前应用：
- `solo` → 跳过。注明："TD-SYSTEM-BOUNDARY skipped — Solo mode." 进入优先级分配。
- `lean` → 跳过（不是 PHASE-GATE）。注明："TD-SYSTEM-BOUNDARY skipped — Lean mode." 进入优先级分配。
- `full` → 正常派生。

**After dependency mapping is approved, spawn `technical-director` via `Agent` using gate TD-SYSTEM-BOUNDARY (`.claude/docs/director-gates/td-system-boundary.md`) before proceeding to priority assignment.**

**依赖映射获批后，在进入优先级分配之前，通过 `Agent` 派生 `technical-director`，使用门禁 TD-SYSTEM-BOUNDARY（`.claude/docs/director-gates/td-system-boundary.md`）。**

Pass: the dependency graph (each system → what it depends on), layer assignments, bottleneck systems, and any circular dependencies with their proposed resolutions.

传入：依赖图（每个系统 → 它依赖什么）、分层分配、瓶颈系统，以及任何循环依赖及其提出的解决方案。

Present the assessment. If REJECT, revise the system boundaries with the user, show the revised dependency map, and only then move to priority assignment. If CONCERNS, note them inline in the systems index and continue. If NOT ASSESSED [missing input], it is not an APPROVE: name what was missing, then supply it and re-run the gate, or continue with `TD-SYSTEM-BOUNDARY: NOT ASSESSED — [input]` noted in the index draft.

呈现评估。若为 REJECT，与用户修订系统边界，展示修订后的依赖图，
然后才进入优先级分配。若为 CONCERNS，在系统索引中就地注明并继续。若为 NOT ASSESSED [missing input]，
它不是 APPROVE：指明缺失了什么，然后补上并重新运行门禁，或继续并在索引草稿中
注明 `TD-SYSTEM-BOUNDARY: NOT ASSESSED — [input]`。

---

## Phase 4: Priority Assignment (Collaborative)

## 阶段 4：优先级分配（协作）

Assign each system to a priority tier based on what milestone it's needed for.

根据系统所需的里程碑，将每个系统分配到一个优先级层级。

### Step 4a: Auto-Assign Based on Concept

### 步骤 4a：基于概念自动分配

Use these heuristics for initial assignment:
- **MVP**: Systems mentioned in the concept's "Required for MVP" section, plus their
  Foundation-layer dependencies
- **Vertical Slice**: Systems needed for a complete experience in one area
- **Alpha**: All remaining gameplay systems
- **Full Vision**: Polish, meta, and nice-to-have systems

初始分配使用以下启发式：
- **MVP**：概念"Required for MVP"章节中提到的系统，加上它们的
  Foundation 层依赖
- **Vertical Slice**：在一个区域内提供完整体验所需的系统
- **Alpha**：所有剩余玩法系统
- **Full Vision**：打磨、元系统以及其他锦上添花的系统

### Step 4b: User Review

### 步骤 4b：用户评审

Present the priority assignments in a table. For each tier, explain why systems
were placed there.

在表格中呈现优先级分配。对每个层级，解释系统为何
被放在那里。

Use `AskUserQuestion` to ask: "Do these priority assignments match your vision?
Which systems should be higher or lower priority?"

使用 `AskUserQuestion` 询问："Do these priority assignments match your vision?
Which systems should be higher or lower priority?"

Explain reasoning in conversation: "I placed [system] in MVP because the core loop
requires it — without [system], the 30-second loop can't function."

在对话中解释理由："I placed [system] in MVP because the core loop
requires it — without [system], the 30-second loop can't function."

**How to phrase the reasoning** — this governs what you *say*, not a column you
write. Neither table has a `Why` column: Systems Enumeration is
`# / Name / Category / Priority / Status / Design Doc / Depends On`, and
Recommended Design Order is `Order / System / Priority / Layer / Agent(s) /
Est. Effort`. The rationale lives in the conversation above and, for anything
the user should still see after the session, in the index's `## Overview`
paragraph. Do not invent a column for it.

**如何措辞表达理由** — 这管辖你*说*什么，而不是你写入的某一列。
两个表都没有 `Why` 列：Systems Enumeration 是
`# / Name / Category / Priority / Status / Design Doc / Depends On`，而
Recommended Design Order 是 `Order / System / Priority / Layer / Agent(s) /
Est. Effort`。理由存在于上述对话中，以及对于用户在会话之后仍应看到的内容，
位于索引的 `## Overview` 段中。不要为它虚构一列。

Mix technical necessity with player-experience reasoning. A purely technical
justification — "the damage system needs damage math" — is insufficient on its
own when the system directly shapes what the player feels. Good reasoning names
both, and cites the pillar it serves:
- "Required for the core loop — without it the player's main choice has no
  consequence (Pillar [N]: [pillar name])"
- "This is where [system]'s identity is established — the stat definitions here
  are what make it feel different from [the sibling system]"
- "Foundation for every later economy decision — the player must understand
  costs before any of the choices built on top of it mean anything"

将技术必要性与玩家体验理由混合。当系统直接塑造玩家的感受时，纯粹的技术
论证 — "the damage system needs damage math" — 单凭自身是不充分的。
好的理由会同时说出两者，并引用它所服务的支柱：
- "Required for the core loop — without it the player's main choice has no
  consequence (Pillar [N]: [pillar name])"
- "This is where [system]'s identity is established — the stat definitions here
  are what make it feel different from [the sibling system]"
- "Foundation for every later economy decision — the player must understand
  costs before any of the choices built on top of it mean anything"

> **Fill the brackets from *this* project.** The bracketed slots are not
> decoration. Reasoning copied from another game's worked example carries that
> game's vocabulary instead of this one's.

> **用*本项目*填充方括号。** 方括号槽位不是
> 装饰。从另一款游戏的范例中抄来的理由会带着那款
> 游戏而非本游戏的词汇。

**Review mode check** — apply before spawning PR-SCOPE:
- `solo` → skip. Note: "PR-SCOPE skipped — Solo mode." Proceed to Step 4c.
- `lean` → skip (not a PHASE-GATE). Note: "PR-SCOPE skipped — Lean mode." Proceed to Step 4c.
- `full` → spawn as normal.

**评审模式检查** — 在派生 PR-SCOPE 之前应用：
- `solo` → 跳过。注明："PR-SCOPE skipped — Solo mode." 进入步骤 4c。
- `lean` → 跳过（不是 PHASE-GATE）。注明："PR-SCOPE skipped — Lean mode." 进入步骤 4c。
- `full` → 正常派生。

**After priorities are approved, spawn `producer` via `Agent` using gate PR-SCOPE (`.claude/docs/director-gates/pr-scope.md`) before writing the index.**

**优先级获批后，在写入索引之前，通过 `Agent` 派生 `producer`，使用门禁 PR-SCOPE（`.claude/docs/director-gates/pr-scope.md`）。**

Pass the gate's fields from the index: the full vision scope (every system in the index), the MVP definition (the MVP tier's systems), the scope tiers (system count per milestone tier, with estimated implementation volume — system count × average complexity), the stated project timeline as the timeline estimate, and team size.

从索引传入门禁字段：完整愿景范围（索引中的每个系统）、MVP 定义（MVP 层级的系统）、范围层级（每个里程碑层级的系统数量，含估算实现量 — 系统数量 × 平均复杂度）、所述项目时间线作为时间线估算，以及团队规模。

Present the assessment. PR-SCOPE answers REALISTIC / OPTIMISTIC / UNREALISTIC.
If UNREALISTIC, offer to revise priority tier assignments before writing the
index. If OPTIMISTIC, show the producer's suggested adjustments and ask whether to
apply them to the tiers before writing; if the user declines, note them and
continue. If NOT ASSESSED [missing input] — often the team size or timeline — it
is not a REALISTIC: name what was missing, then supply it and re-run the gate, or
continue with `PR-SCOPE: NOT ASSESSED — [input]` noted in the index draft.

呈现评估。PR-SCOPE 回答 REALISTIC / OPTIMISTIC / UNREALISTIC。
若为 UNREALISTIC，在写入索引前提议修订优先级层级分配。
若为 OPTIMISTIC，展示制作人建议的调整，并在写入前询问是否将其
应用到层级；如果用户拒绝，注明它们并继续。若为 NOT ASSESSED [missing input] —
通常是团队规模或时间线 — 它不是 REALISTIC：指明缺失了什么，然后补上并重新运行门禁，或
继续并在索引草稿中注明 `PR-SCOPE: NOT ASSESSED — [input]`。

### Step 4c: Determine Design Order

### 步骤 4c：确定设计顺序

Combine dependency sort + priority tier to produce the final design order:
1. MVP Foundation systems first
2. MVP Core systems second
3. MVP Feature systems third
4. Vertical Slice Foundation/Core systems
5. ...and so on

将依赖排序 + 优先级层级结合，得出最终设计顺序：
1. 先 MVP Foundation 系统
2. 其次 MVP Core 系统
3. 再次 MVP Feature 系统
4. Vertical Slice Foundation/Core 系统
5. ……以此类推

This is the order the team should write GDDs in.

这是团队编写 GDD 的顺序。

---

## Phase 5: Create Systems Index (Write)

## 阶段 5：创建系统索引（写入）

### Step 5a: Draft the Document

### 步骤 5a：起草文档

Using the template at `.claude/docs/templates/systems-index.md`, populate the
systems index with all data from Phases 2-4:
- Fill the enumeration table
- Fill the dependency map
- Fill the recommended design order
- Fill the high-risk systems
- Fill progress tracker (all systems "Not Started" initially, unless GDDs already exist)

使用 `.claude/docs/templates/systems-index.md` 中的模板，用阶段 2-4 的所有数据
填充系统索引：
- 填充枚举表
- 填充依赖图
- 填充推荐设计顺序
- 填充高风险系统
- 填充进度追踪器（所有系统初始为"Not Started"，除非 GDD 已存在）

### Step 5b: Approval

### 步骤 5b：批准

Present a summary of the document:
- Total systems count by category
- MVP system count
- First 3 systems in the design order
- Any high-risk items

呈现文档摘要：
- 按类别的系统总数
- MVP 系统数量
- 设计顺序中的前 3 个系统
- 任何高风险项

**At `automation: collaborative`** — ask: "May I write the systems index to
`design/gdd/systems-index.md`?" Wait for approval. Write the file only after
"yes."

**在 `automation: collaborative` 下** — 询问："May I write the systems index to
`design/gdd/systems-index.md`?" 等待批准。仅在得到
"yes" 后写入文件。

**At `automation: guided`** — a **new** index gets the same "May I write …?"
question, because `.claude/docs/automation-modes.md` has `guided` ask "May I
write?" for new files. When the index already exists, present the summary above,
name the destination (`design/gdd/systems-index.md`), and write the update without
waiting for an explicit "yes". Say what you wrote afterwards.

**在 `automation: guided` 下** — **新**索引会得到同样的 "May I write …?"
问题，因为 `.claude/docs/automation-modes.md` 规定 `guided` 对新文件
询问 "May I write?"。当索引已存在时，呈现上述摘要，
指明目标（`design/gdd/systems-index.md`），并直接写入更新，无需
等待明确的 "yes"。之后说明你写了什么。

**Review mode check** — apply before spawning CD-SYSTEMS:
- `solo` → skip. Note: "CD-SYSTEMS skipped — Solo mode." Proceed to Step 5c.
- `lean` → skip (not a PHASE-GATE). Note: "CD-SYSTEMS skipped — Lean mode." Proceed to Step 5c.
- `full` → spawn as normal.

**评审模式检查** — 在派生 CD-SYSTEMS 之前应用：
- `solo` → 跳过。注明："CD-SYSTEMS skipped — Solo mode." 进入步骤 5c。
- `lean` → 跳过（不是 PHASE-GATE）。注明："CD-SYSTEMS skipped — Lean mode." 进入步骤 5c。
- `full` → 正常派生。

**After the systems index is written, spawn `creative-director` via `Agent` using gate CD-SYSTEMS (`.claude/docs/director-gates/cd-systems.md`).**

**系统索引写入后，通过 `Agent` 派生 `creative-director`，使用门禁 CD-SYSTEMS（`.claude/docs/director-gates/cd-systems.md`）。**

Pass: systems index path; game pillars and core fantasy — from `design/gdd/game-concept.md`, or at `minimal` the pitch and "what they feel" line of `design/game-brief.md`, which has no pillars; the priority tier assignments for every tier (MVP / Vertical Slice / Alpha / Full Vision); and the high-risk and bottleneck systems from the dependency map.

传入：系统索引路径；游戏支柱与核心幻想 — 来自 `design/gdd/game-concept.md`，或在 `minimal` 下取自 `design/game-brief.md` 的推介语和"what they feel"一行（该文件没有支柱）；每个层级（MVP / Vertical Slice / Alpha / Full Vision）的优先级层级分配；以及依赖图中的高风险与瓶颈系统。

Present the assessment. If REJECT, revise the system set with the user before GDD authoring begins. If CONCERNS, show them and use `AskUserQuestion`: `Revise the system set` / `Accept — record them in the index` / `Discuss further`. On *Revise*, rework the affected systems with the user and ask again before re-writing the index. On *Accept* — the option names the edit, so choosing it is the ask — record them in the systems index as a `> **Creative Director Note**`
placed **directly beneath the `## Priority Tiers` table**, naming the tier each
concern applies to — e.g. `> **Creative Director Note** (MVP): …`.
`templates/systems-index.md` has a Priority Tiers *definition table*, not a
section per tier, so there is no "top of the tier section" to write to — do not
direct the writer to one. If NOT ASSESSED [missing input], it is not an APPROVE
(`.claude/docs/director-gates.md`): name what was missing, then supply it and
re-run the gate, or ask before recording `> **Creative Director Note**:
CD-SYSTEMS NOT ASSESSED — [input]` in the same place.

呈现评估。若为 REJECT，在 GDD 编写开始前与用户修订系统集合。若为 CONCERNS，展示它们并使用 `AskUserQuestion`：`Revise the system set` / `Accept — record them in the index` / `Discuss further`。在 *Revise* 时，与用户重做受影响的系统，并在重写索引前再次询问。在 *Accept* 时 — 该选项命名了编辑动作，因此选择它就是询问 — 将其记录在系统索引中，作为一条 `> **Creative Director Note**`
放在**紧接 `## Priority Tiers` 表的下方**，指明每条关注点适用的
层级 — 例如 `> **Creative Director Note** (MVP): …`。
`templates/systems-index.md` 有一个 Priority Tiers *定义表*，而不是
每个层级一个章节，因此没有"层级章节顶部"可写入 — 不要
引导写作者去那里。若为 NOT ASSESSED [missing input]，它不是 APPROVE
（`.claude/docs/director-gates.md`）：指明缺失了什么，然后补上并
重新运行门禁，或在同一位置记录 `> **Creative Director Note**:
CD-SYSTEMS NOT ASSESSED — [input]` 之前先询问。

### Step 5c: Update Session State

### 步骤 5c：更新会话状态

After writing, create `production/session-state/active.md` if it does not exist, then update it with:
- Task: Systems decomposition
- Status: Systems index created
- File: design/gdd/systems-index.md
- Next: Design individual system GDDs

写入后，若 `production/session-state/active.md` 不存在则创建它，然后用以下内容更新它：
- 任务：系统分解
- 状态：系统索引已创建
- 文件：design/gdd/systems-index.md
- 下一步：设计各个系统 GDD

**Verdict: COMPLETE** — systems index written to `design/gdd/systems-index.md`.
If the user declined: **Verdict: BLOCKED** — user did not approve the write.

**结论：COMPLETE** — 系统索引已写入 `design/gdd/systems-index.md`。
若用户拒绝：**结论：BLOCKED** — 用户未批准写入。

---

## Phase 6: Design Individual Systems (Handoff to /design-system)

## 阶段 6：设计各个系统（交接至 /design-system）

This phase is entered when:
- The user says "yes" to designing systems after creating the index
- The user invokes `/map-systems [system-name]`
- The user invokes `/map-systems next`

进入此阶段的情形：
- 用户在创建索引后对设计系统回答"yes"
- 用户调用 `/map-systems [system-name]`
- 用户调用 `/map-systems next`

### Step 6a: Select the System

### 步骤 6a：选择系统

- If a system name was provided, find it in the systems index
- If `next` was used, pick the highest-priority undesigned system (by design order)
- If the user just finished the index, ask:
  "Would you like to start designing individual systems now? The first system in
  the design order is [name]. Or would you prefer to stop here and come back later?"

- 如果提供了系统名称，在系统索引中找到它
- 如果使用了 `next`，挑选优先级最高的未设计系统（按设计顺序）
- 如果用户刚完成索引，询问：
  "Would you like to start designing individual systems now? The first system in
  the design order is [name]. Or would you prefer to stop here and come back later?"

Use `AskUserQuestion` for: "Start designing [system-name] now, pick a different
system, or stop here?"

使用 `AskUserQuestion` 提问："Start designing [system-name] now, pick a different
system, or stop here?"

### Step 6b: Hand Off to /design-system

### 步骤 6b：交接至 /design-system

Once a system is selected, invoke the `/design-system [system-name]` skill.

选定系统后，调用 `/design-system [system-name]` 技能。

The `/design-system` skill handles the full GDD authoring process:
- Gathers context from game concept, systems index, and dependency GDDs
- Creates a file skeleton immediately
- Walks through all 8 required sections one at a time (collaborative, incremental)
- Cross-references existing docs to prevent contradictions
- Routes to specialist agents for domain expertise
- Writes each section to file as soon as it's approved
- Runs `/design-review` when complete
- Updates the systems index

`/design-system` 技能处理完整的 GDD 编写流程：
- 从游戏概念、系统索引和依赖 GDD 收集上下文
- 立即创建文件骨架
- 一次一个地走完全部 8 个必需章节（协作式、增量式）
- 交叉引用既有文档以防止矛盾
- 将领域专业问题路由给专家智能体
- 每个章节一经批准即写入文件
- 完成后运行 `/design-review`
- 更新系统索引

**Do not duplicate the /design-system workflow here.** This skill owns the systems
*index*; `/design-system` owns individual system *GDDs*.

**不要在此复制 /design-system 的工作流。** 本技能负责系统*索引*；
`/design-system` 负责各个系统的 *GDD*。

### Step 6c: Loop or Stop

### 步骤 6c：循环或停止

After `/design-system` completes, use `AskUserQuestion`:
- "Continue to the next system ([next system name])?"
- "Pick a different system?"
- "Stop here for this session?"

`/design-system` 完成后，使用 `AskUserQuestion`：
- "Continue to the next system ([next system name])?"
- "Pick a different system?"
- "Stop here for this session?"

If continuing, return to Step 6a.

若继续，返回步骤 6a。

---

## Phase 7: Suggest Next Steps

## 阶段 7：建议后续步骤

After the systems index is created (or after designing some systems), present next actions using `AskUserQuestion`:

系统索引创建后（或设计了一些系统后），使用 `AskUserQuestion` 呈现后续动作：

- "Systems index is written. What would you like to do next?"
  - [A] Start designing GDDs — run `/design-system [first-system-in-order]`
  - [B] Run `/gate-check systems-design` — the Concept → Systems Design gate; offer this only while `project.stage` is still Concept
  - [C] Run `/gate-check technical-setup` — the Systems Design → Technical Setup gate, once the MVP systems have GDDs
  - [D] Stop here for this session

- "Systems index is written. What would you like to do next?"
  - [A] Start designing GDDs — run `/design-system [first-system-in-order]`
  - [B] Run `/gate-check systems-design` — 概念 → 系统设计门禁；仅在 `project.stage` 仍为 Concept 时提供此项
  - [C] Run `/gate-check technical-setup` — 系统设计 → 技术设置门禁，在 MVP 系统拥有 GDD 之后
  - [D] Stop here for this session

**The gate-check option ([C]) is worth knowing about**: `/gate-check technical-setup` checks that the Systems Design phase's required artifacts exist and runs the phase-gate directors before you commit to architecture. CD-SYSTEMS and TD-SYSTEM-BOUNDARY are this skill's own gates — they run here, in `full` review mode, not in `/gate-check`.

**门禁检查选项（[C]）值得了解**：`/gate-check technical-setup` 检查系统设计阶段的必需产物是否存在，并在你承诺架构之前运行阶段门禁总监。CD-SYSTEMS 和 TD-SYSTEM-BOUNDARY 是本技能自身的门禁 — 它们在此处、在 `full` 评审模式下运行，而不在 `/gate-check` 中。

After any individual GDD is completed:
- "Run `/design-review design/gdd/[system].md` in a fresh session to validate quality"
- "Run `/gate-check technical-setup` when all MVP GDDs are complete"

任何单个 GDD 完成后：
- "Run `/design-review design/gdd/[system].md` in a fresh session to validate quality"
- "Run `/gate-check technical-setup` when all MVP GDDs are complete"

---

## Collaborative Protocol

## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

**适用于 `collaborative` 模式（默认）。** 对于 `guided` 和
`autonomous` 模式，见 `.claude/docs/automation-modes.md` — 以下规则
描述的是协作模式的要求，而非普遍行为。

This skill follows the collaborative design principle at every phase:

本技能在每个阶段都遵循协作设计原则：

1. **Question -> Options -> Decision -> Draft -> Approval** at every step
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Missing systems? Combine or split?"
   - Phase 3: "Dependency ordering correct?"
   - Phase 4: "Priority assignments match your vision?"
   - Phase 5: "May I write the systems index?"
   - Phase 6: "Start designing, pick different, or stop?" then hand off to `/design-system`
3. **"May I write to [filepath]?"** before every file write
4. **Incremental writing**: Update the systems index after each system is designed
5. **Handoff**: Individual GDD authoring is owned by `/design-system`, which handles
   incremental section writing, cross-referencing, design review, and index updates
6. **Session state updates**: Write to `production/session-state/active.md` after
   each milestone (index created, system designed, priorities changed)

1. 每一步都遵循 **问题 -> 选项 -> 决策 -> 草稿 -> 批准**
2. 每个决策点都使用 **AskUserQuestion**（解释 -> 捕获模式）：
   - 阶段 2："Missing systems? Combine or split?"
   - 阶段 3："Dependency ordering correct?"
   - 阶段 4："Priority assignments match your vision?"
   - 阶段 5："May I write the systems index?"
   - 阶段 6："Start designing, pick different, or stop?" 然后交接给 `/design-system`
3. 每次文件写入前都问 **"May I write to [filepath]?"**
4. **增量写入**：每设计完一个系统后更新系统索引
5. **交接**：单个 GDD 编写由 `/design-system` 负责，它处理
   增量章节写入、交叉引用、设计评审和索引更新
6. **会话状态更新**：在每个里程碑（索引已创建、系统已设计、优先级已更改）后
   写入 `production/session-state/active.md`

**Never** auto-generate the full systems list and write it without review.
**Never** start designing a system without user confirmation.
**Always** show the enumeration, dependencies, and priorities for user validation.

**绝不**自动生成完整系统列表并在未经评审的情况下写入它。
**绝不**在未经用户确认的情况下开始设计系统。
**始终**展示枚举、依赖和优先级以供用户验证。

## Context Window Awareness

## 上下文窗口感知

If context reaches or exceeds 70% at any point, append this notice:

如果上下文在任何时候达到或超过 70%，追加此提示：

> **Context is approaching the limit (≥70%).** The systems index is saved to
> `design/gdd/systems-index.md`. Open a fresh Claude Code session to continue
> designing individual GDDs — run `/map-systems next` to pick up where you left off.

> **上下文正在接近上限（≥70%）。** 系统索引已保存到
> `design/gdd/systems-index.md`。打开一个新的 Claude Code 会话以继续
> 设计各个 GDD — 运行 `/map-systems next` 以从你中断处继续。

---

## Recommended Next Steps

## 推荐的后续步骤

- Run `/design-system [first-system-in-order]` to author the first GDD (use design order from the index)
- Run `/map-systems next` to always pick the highest-priority undesigned system automatically
- Run `/design-review design/gdd/[system].md` in a fresh session after each GDD is authored
- Run `/gate-check technical-setup` when all MVP GDDs are authored and reviewed

- 运行 `/design-system [first-system-in-order]` 编写第一个 GDD（使用索引中的设计顺序）
- 运行 `/map-systems next` 以始终自动挑选优先级最高的未设计系统
- 每个 GDD 编写完成后，在新会话中运行 `/design-review design/gdd/[system].md`
- 当所有 MVP GDD 编写并评审完成后，运行 `/gate-check technical-setup`
