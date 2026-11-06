# Claude Code Game Studios -- Complete Workflow Guide
# Claude Code Game Studios —— 完整工作流指南

> **How to go from zero to a shipped game using the Agent Architecture.**
>
> **如何借助智能体架构从零开始直至发布一款游戏。**
>
> This guide walks you through every phase of game development using the
> 49-agent system, 74 slash commands, and 15 automated hooks. It assumes you
> have Claude Code installed and are working from the project root.
>
> 本指南带你走完游戏开发的每一个阶段，使用
> 49 个智能体系统、74 个斜杠命令和 15 个自动化钩子。它假设你已安装
> Claude Code，并从项目根目录开始工作。
>
> The pipeline has 7 phases. At `rigor: standard` and `full`, each phase has
> a formal gate (`/gate-check`) that must pass before you advance. At
> `rigor: minimal` -- the default -- nothing requires a gate; see
> [The Default Path](#the-default-path-rigor-minimal). The authoritative
> phase sequence is defined in `.claude/docs/workflow-catalog.yaml` and read
> by `/help`.
>
> 该流水线包含 7 个阶段。在 `rigor: standard` 和 `full` 下，每个阶段都有一个
> 正式门禁（`/gate-check`），必须通过才能前进。在
> `rigor: minimal`（默认值）下 —— 没有任何环节要求门禁；参见
> [默认路径](#the-default-path-rigor-minimal)。权威的
> 阶段顺序定义在 `.claude/docs/workflow-catalog.yaml` 中，由 `/help` 读取。

---

## Table of Contents
## 目录

1. [Quick Start](#quick-start)
1. [快速开始](#quick-start)
2. [The Default Path: Rigor Minimal](#the-default-path-rigor-minimal)
2. [默认路径：最小严格度](#the-default-path-rigor-minimal)
3. [Phase 1: Concept](#phase-1-concept)
3. [阶段 1：概念](#phase-1-concept)
4. [Phase 2: Systems Design](#phase-2-systems-design)
4. [阶段 2：系统设计](#phase-2-systems-design)
5. [Phase 3: Technical Setup](#phase-3-technical-setup)
5. [阶段 3：技术准备](#phase-3-technical-setup)
6. [Phase 4: Pre-Production](#phase-4-pre-production)
6. [阶段 4：前期制作](#phase-4-pre-production)
7. [Phase 5: Production](#phase-5-production)
7. [阶段 5：制作](#phase-5-production)
8. [Phase 6: Polish](#phase-6-polish)
8. [阶段 6：打磨](#phase-6-polish)
9. [Phase 7: Release](#phase-7-release)
9. [阶段 7：发布](#phase-7-release)
10. [Cross-Cutting Concerns](#cross-cutting-concerns)
10. [横切关注点](#cross-cutting-concerns)
11. [Appendix A: Agent Quick-Reference](#appendix-a-agent-quick-reference)
11. [附录 A：智能体快速参考](#appendix-a-agent-quick-reference)
12. [Appendix B: Slash Command Quick-Reference](#appendix-b-slash-command-quick-reference)
12. [附录 B：斜杠命令快速参考](#appendix-b-slash-command-quick-reference)
13. [Appendix C: Common Workflows](#appendix-c-common-workflows)
13. [附录 C：常用工作流](#appendix-c-common-workflows)

---

## Quick Start
## 快速开始

### What You Need
### 你需要什么

Before you start, make sure you have:
在开始之前，请确保你具备以下条件：

- **Claude Code** installed and working
- **Claude Code** 已安装并可正常使用

- **Git** with Git Bash (Windows) or standard terminal (Mac/Linux)
- **Git**，Windows 下配 Git Bash，Mac/Linux 下使用标准终端

- **jq** (optional but recommended -- hooks fall back to `grep` if missing)
- **jq**（可选但推荐 —— 若缺失，钩子会回退为使用 `grep`）

- **Python 3** (required -- every skill and hook reads `project.yaml` through it; without it every setting silently falls back to its default)
- **Python 3**（必需 —— 每个技能和钩子都通过它读取 `project.yaml`；缺失时所有设置都会静默回退为默认值）

### Step 1: Clone and Open
### 步骤 1：克隆并打开

```bash
git clone <repo-url> my-game
cd my-game
```

### Step 2: Run /start
### 步骤 2：运行 /start

If this is your first session:
如果这是你的第一次会话：

```
/start
```

This guided onboarding asks where you are and routes you to the right phase:
这一引导式入门会询问你当前所处的位置，并将你路由到正确的阶段：

- **Path A** -- No idea yet: routes to `/brainstorm`
- **路径 A** —— 尚无想法：路由至 `/brainstorm`

- **Path B** -- Vague idea: routes to `/brainstorm` with seed
- **路径 B** —— 想法模糊：携带种子路由至 `/brainstorm`

- **Path C** -- Clear concept: routes to `/brainstorm` to write it down, or
  straight to `/setup-engine`
- **路径 C** —— 概念清晰：路由至 `/brainstorm` 将其写下来，或
  直接前往 `/setup-engine`

- **Path D** -- Existing work: routes to `/setup-engine` when no engine is set
  and there is no more than a concept; otherwise to `/project-stage-detect`,
  then `/adopt` for brownfield migration
- **路径 D** —— 已有工作：当未设置引擎且最多只有一个概念时，
  路由至 `/setup-engine`；否则路由至 `/project-stage-detect`，
  再由 `/adopt` 进行棕地迁移

### Step 3: Verify Hooks Are Working
### 步骤 3：验证钩子是否正常工作

Start a new Claude Code session. You should see output from the
`session-start.sh` hook:
启动一个新的 Claude Code 会话。你应当能看到 `session-start.sh`
钩子的输出：

```
=== Claude Code Game Studios -- Session Context ===
Branch: main
Recent commits:
  abc1234 Initial commit
===================================
```

If you see this, hooks are working. If not, check `.claude/settings.json` to
make sure the hook paths are correct for your OS.
如果你看到了这些内容，说明钩子正常工作。如果没有，请检查 `.claude/settings.json`
以确保钩子路径与你的操作系统相符。

### Step 4: Ask for Help Anytime
### 步骤 4：随时寻求帮助

At any point, run:
在任何时候，都可以运行：

```
/help
```

This reads your current phase from `project.stage` in `project.yaml` (falling
back to `production/stage.txt`) -- at `rigor: minimal`, where the stage never
moves, it follows the minimal route instead -- checks which artifacts exist, and tells you
exactly what to do next. It distinguishes between REQUIRED next steps and
OPTIONAL opportunities.
它会从 `project.yaml` 中的 `project.stage` 读取你当前的阶段（回退到
`production/stage.txt`）—— 在 `rigor: minimal` 下，阶段从不
变动，它改为遵循最小化路线 —— 检查存在哪些产物，并确切告诉你
下一步该做什么。它会区分"必需"的下一步和
"可选"的机会。

### Step 5: Create Your Directory Structure
### 步骤 5：创建你的目录结构

Directories are created as needed. The system expects this layout:
目录会按需创建。系统期望如下布局：

```
src/                  # Game source code (Godot; Unity: Assets/, Unreal: Source/<Module>/)
  core/               # Engine/framework code
  gameplay/           # Gameplay systems
  ai/                 # AI systems
  networking/         # Multiplayer code
  ui/                 # UI code
  tools/              # Dev tools
assets/               # Game assets
  art/                # Sprites, models, textures
  audio/              # Music, SFX
  vfx/                # Particle effects
  shaders/            # Shader files
  data/               # JSON config/balance data
design/               # Design documents
  gdd/                # Game design documents
  narrative/          # Story, lore, dialogue
  levels/             # Level design documents
  balance/            # Balance spreadsheets and data
  ux/                 # UX specifications
docs/                 # Technical documentation
  architecture/       # Architecture Decision Records
  api/                # API documentation
  postmortems/        # Post-mortems
tests/                # Test suites
prototypes/           # Throwaway prototypes
production/           # Sprint plans, milestones, releases
  sprints/
  milestones/
  releases/
  epics/              # Epic and story files (from /create-epics + /create-stories)
  playtests/          # Playtest reports
  session-state/      # Ephemeral session state (gitignored)
  session-logs/       # Session audit trail (gitignored)
```

> **Tip:** You do not need all of these on day one. Create directories as you
> reach the phase that needs them. The important thing is to follow this
> structure when you do create them, because the **rules system** enforces
> standards based on file paths. Code in `src/gameplay/` gets gameplay rules,
> code in `src/ai/` gets AI rules, and so on — and the same for C# and C++ in
> Unity and Unreal `Gameplay/` and `AI/` folders.
>
> **提示：** 你不需要在第一天就准备齐全所有目录。在进入需要它们的
> 阶段时再创建目录即可。重要的是，当你确实创建它们时，
> 要遵循这一结构，因为**规则系统**会依据文件路径
> 执行相应的标准。`src/gameplay/` 中的代码适用游戏玩法规则，
> `src/ai/` 中的代码适用 AI 规则，依此类推 —— Unity 与 Unreal 的
> `Gameplay/` 和 `AI/` 文件夹中的 C# 与 C++ 也是如此。

---

## The Default Path: Rigor Minimal
## 默认路径：最小严格度

`modes.rigor` defaults to `minimal` (`/start` infers the tier from your description and shows it
before saving; `/settings` changes it any time). At `minimal` the path to code is four steps:
`modes.rigor` 默认为 `minimal`（`/start` 会根据你的描述推断层级，并在保存前
向你展示；`/settings` 可随时更改）。在 `minimal` 下，通往代码的路径共四步：

1. `/setup-engine` -- configure the engine
1. `/setup-engine` —— 配置引擎

2. `/brainstorm` -- writes the one-page `design/game-brief.md`, which replaces
   the full concept doc, the systems decomposition and the per-system GDDs
2. `/brainstorm` —— 写入一页纸的 `design/game-brief.md`，它取代
   完整概念文档、系统分解以及各系统的 GDD

3. `/create-stories` -- turns the brief's MVP list and build order into stories
   under `production/epics/<slug>/`. No `/create-epics`, no `/sprint-plan`: the
   brief's build order is the plan
3. `/create-stories` —— 将简报中的 MVP 清单和构建顺序转化为
   `production/epics/<slug>/` 下的故事。无需 `/create-epics`，也无需 `/sprint-plan`：
   简报的构建顺序就是计划

4. `/dev-story` then `/story-done`, story by story. `/story-done` names the
   next story, and `/help` knows this route
4. `/dev-story` 然后 `/story-done`，逐个故事推进。`/story-done` 会指出
   下一个故事，而 `/help` 也识别这条路线

Nothing on this path runs `/gate-check`, so `project.stage` stays at Concept --
that is expected. Every skill still runs at any tier; rigor changes what is
required, not what is allowed.
这条路径上没有任何环节运行 `/gate-check`，因此 `project.stage` 会一直停留在 Concept ——
这是预期行为。每个技能在任何层级仍然可以运行；严格度改变的是
必需项，而不是允许项。

The trade: there are no GDDs to catch design problems before they reach code.
Raise rigor with `/settings` when the game outgrows a one-page brief -- several
systems that affect each other, a design someone else implements, a team, or a
firm release date. Existing files stay where they are, and `/help` shows what
the new tier requires next.
代价是：没有 GDD 在设计问题进入代码之前将其拦截。
当游戏规模超出一页纸简报所能承载 —— 多个相互影响的
系统、由他人实现的设计、一个团队，或确定的
发布日期 —— 就用 `/settings` 提高严格度。现有文件保持在原处，`/help` 会显示
新层级接下来要求什么。

The rest of this guide describes the `standard`/`full` pipeline.
本指南其余部分描述的是 `standard`/`full` 流水线。

---

## Phase 1: Concept
## 阶段 1：概念

### What Happens in This Phase
### 本阶段会发生什么

You go from "no idea" or "vague idea" to a structured game concept document
with defined pillars and a player journey. This is where you figure out
**what** you are making and **why**.
你将从"没有想法"或"想法模糊"走向一份结构化的游戏概念文档，
其中包含已定义的支柱和玩家旅程。在这里你要弄清楚自己
在做什么，以及为什么做。

### Phase 1 Pipeline
### 阶段 1 流水线

```
/brainstorm  -->  game-concept.md  -->  /design-review  -->  /setup-engine
     |                                        |                    |
     v                                        v                    v
  10 concepts     Concept doc with       Validation          Engine pinned in
  MDA analysis    pillars, MDA,          of concept          project.yaml
  Player motiv.   core loop, USP         document
                                                                   |
                                                                   v
                                                             /prototype
                                                       (concept prototype — 1 day max)
                                                        PROCEED ↓     PIVOT → /brainstorm
                                                                   |
                                                                   v (PROCEED)
                                                             /map-systems
                                                                   |
                                                                   v
                                                            systems-index.md
                                                            (all systems, deps,
                                                             priority tiers)
```

### Step 1.1: Brainstorm With /brainstorm
### 步骤 1.1：使用 /brainstorm 进行头脑风暴

This is your starting point. Run the brainstorm skill:
这是你的起点。运行头脑风暴技能：

```
/brainstorm
```

Or with a genre hint:
或者带上类型提示：

```
/brainstorm roguelike deckbuilder
```

**What happens:** The brainstorm skill guides you through a collaborative 6-phase
ideation process using professional studio techniques:
**会发生什么：** 头脑风暴技能运用专业工作室的方法，引导你完成一个协作式的
6 阶段创意流程：

1. Asks about your interests, themes, and constraints
1. 询问你的兴趣、主题和约束条件

2. Generates 10 concept seeds with MDA (Mechanics, Dynamics, Aesthetics) analysis
2. 生成 10 个概念种子，并附 MDA（机制、动态、美学）分析

3. You pick 2-3 favorites for deep analysis
3. 你挑选 2-3 个最喜欢的进行深度分析

4. Performs player motivation mapping and audience targeting
4. 执行玩家动机映射和目标受众定位

5. You choose the winning concept
5. 你选出最终胜出的概念

6. Formalizes it into `design/gdd/game-concept.md`
6. 将其正式化为 `design/gdd/game-concept.md`

The concept document includes:
概念文档包含：

- Elevator pitch (one sentence)
- 电梯陈述（一句话）

- Core fantasy (what the player imagines themselves doing)
- 核心幻想（玩家想象自己在做什么）

- MDA breakdown
- MDA 拆解

- Target audience (Bartle types, demographics)
- 目标受众（Bartle 类型、人群画像）

- Core loop diagram
- 核心循环图

- Unique selling proposition
- 独特卖点

- Comparable titles and differentiation
- 可比作品及其差异化

- Game pillars (3-5 non-negotiable design values)
- 游戏支柱（3-5 条不可妥协的设计价值观）

- Anti-pillars (things the game intentionally avoids)
- 反支柱（游戏有意回避的内容）

### Step 1.2: Review the Concept (Optional but Recommended)
### 步骤 1.2：评审概念（可选但推荐）

```
/design-review design/gdd/game-concept.md
```

Validates structure and completeness before you proceed.
在继续之前校验结构与完整性。

### Step 1.3: Choose Your Engine
### 步骤 1.3：选择你的引擎

```
/setup-engine
```

Or with a specific engine:
或指定具体引擎：

```
/setup-engine godot 4.7
```

**What /setup-engine does:**
**/setup-engine 会做什么：**

- Writes engine, language, specialists, naming conventions, and performance
  budgets to `project.yaml` (the source of truth) and mirrors them to
  `.claude/docs/technical-preferences.md` (the human-readable legacy fallback)
- 将引擎、语言、专家、命名约定和性能
  预算写入 `project.yaml`（权威来源），并同步到
  `.claude/docs/technical-preferences.md`（供人阅读的遗留回退文件）

- Detects knowledge gaps (engine version newer than LLM training data) and
  advises cross-referencing `docs/engine-reference/`
- 检测知识空白（引擎版本比 LLM 训练数据更新），并
  建议交叉参考 `docs/engine-reference/`

- Creates version-pinned reference docs in `docs/engine-reference/`
- 在 `docs/engine-reference/` 中创建按版本锁定的参考文档

**Why this matters:** Once you set the engine, the system knows which
engine-specialist agents to use. If you pick Godot, agents like
`godot-specialist`, `godot-gdscript-specialist`, and `godot-shader-specialist`
become your go-to experts.
**为何重要：** 一旦设置引擎，系统就知道该使用哪些
引擎专家智能体。如果你选择 Godot，像
`godot-specialist`、`godot-gdscript-specialist` 和 `godot-shader-specialist` 这样的智能体
就会成为你首选的专家。

### Step 1.4: Decompose Your Concept Into Systems
### 步骤 1.4：将概念分解为系统

Before writing individual GDDs, enumerate all the systems your game needs:
在编写各个 GDD 之前，先枚举游戏所需的所有系统：

```
/map-systems
```

This creates `design/gdd/systems-index.md` -- a master tracking document that:
这会创建 `design/gdd/systems-index.md` —— 一份主跟踪文档，它：

- Lists every system your game needs (combat, movement, UI, etc.)
- 列出游戏所需的每一个系统（战斗、移动、UI 等）

- Maps dependencies between systems
- 映射系统间的依赖关系

- Assigns priority tiers (MVP, Vertical Slice, Alpha, Full Vision)
- 分配优先级层级（MVP、垂直切片、Alpha、完整愿景）

- Determines design order (Foundation > Core > Feature > Presentation > Polish)
- 确定设计顺序（基础 > 核心 > 功能 > 表现 > 打磨）

This step is **required** before proceeding to Phase 2. Research from 155 game
postmortems confirms that skipping systems enumeration costs 5-10x more in
production.
此步骤是进入阶段 2 之前的**必做项**。对 155 份游戏
复盘的研究证实，跳过系统枚举会使制作成本增加 5-10 倍。

### Step 1.5: Art Bible
### 步骤 1.5：美术圣经

```
/art-bible
```

Authors `design/art/art-bible.md`, the visual identity every asset follows.
Run it once the concept is approved; `/art-bible` suggests doing it before
`/map-systems` (Step 1.4). Sections 1–4 are needed before `/gate-check pre-production`, and all
9 before `/gate-check production`. At `standard` it is required only when the
game has visual-asset stories; at `minimal` it is optional.
撰写 `design/art/art-bible.md`，即所有资产都要遵循的视觉识别规范。
在概念获得批准后运行它；`/art-bible` 建议在
`/map-systems`（步骤 1.4）之前完成。第 1–4 节在 `/gate-check pre-production` 之前需要，
全部 9 节则需在 `/gate-check production` 之前完成。在 `standard` 下，只有游戏
包含视觉资产类故事时才必需；在 `minimal` 下它是可选的。

### Phase 1 Gate
### 阶段 1 门禁

```
/gate-check systems-design
```

**Requirements to pass:**
**通过要求：**

- `design/gdd/game-concept.md` with content, the game pillars, and a Visual
  Identity Anchor section (at `minimal`: `design/game-brief.md` with content)
- `design/gdd/game-concept.md` 有实质内容、包含游戏支柱和一个视觉
  识别锚点章节（在 `minimal` 下：`design/game-brief.md` 有实质内容）

- Recommended: a concept prototype whose REPORT.md says PROCEED
- 推荐：一份概念原型，其 REPORT.md 结论为 PROCEED

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-systems-design.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-systems-design.md` 包含完整的
检查清单以及各层级会舍弃的条目。

**Verdict:** PASS / CONCERNS / NOT ASSESSED / FAIL. PASS advances the stage.
On CONCERNS it advances only if you explicitly accept the risks, which are
recorded; a FAIL never advances it. NOT ASSESSED means something required could
not be checked.
**结论：** PASS / CONCERNS / NOT ASSESSED / FAIL。PASS 会推进阶段。
在 CONCERNS 下，只有你明确接受风险（且风险会被记录）才会推进；
FAIL 永远不会推进。NOT ASSESSED 表示某项必需内容无法检查。

---

## Phase 2: Systems Design
## 阶段 2：系统设计

### What Happens in This Phase
### 本阶段会发生什么

You create all the design documents that define how your game works. Nothing
gets coded yet -- this is pure design. Each system identified in the systems
index gets its own GDD, authored section by section, reviewed individually,
and then all GDDs are cross-checked for consistency.
你创建所有定义游戏运作方式的设计文档。此阶段还没有任何代码 ——
这是纯粹的设计。系统索引中识别出的每个系统都有自己的 GDD，
逐章节撰写、逐一评审，最后对所有 GDD 做一致性交叉检查。

### Phase 2 Pipeline
### 阶段 2 流水线

```
/map-systems next  -->  /design-system  -->  /design-review
       |                     |                     |
       v                     v                     v
  Picks next system    Section-by-section     Validates 8
  from systems-index   GDD authoring          required sections
                       (incremental writes)   APPROVED/NEEDS REVISION
       |
       |  (repeat for each MVP system)
       v
/review-all-gdds
       |
       v
  Cross-GDD consistency + design theory review
  PASS / CONCERNS / NOT ASSESSED / FAIL
```

### Step 2.1: Author System GDDs
### 步骤 2.1：撰写系统 GDD

Design each system in dependency order using the guided workflow:
按依赖顺序，使用引导式工作流设计每个系统：

```
/map-systems next
```

This picks the highest-priority undesigned system and hands off to
`/design-system`, which guides you through creating its GDD section by section.
这会选出优先级最高且尚未设计的系统，并移交给
`/design-system`，由后者引导你逐章节创建其 GDD。

You can also design a specific system directly:
你也可以直接设计某个特定系统：

```
/design-system combat-system
```

**What /design-system does:**
**/design-system 会做什么：**

1. Reads your game concept, systems index, and any upstream/downstream GDDs
1. 读取你的游戏概念、系统索引，以及任何上游/下游 GDD

2. Runs a Technical Feasibility Pre-Check (domain mapping + feasibility brief)
2. 运行技术可行性预检（领域映射 + 可行性简报）

3. Walks you through each of the 8 required GDD sections one at a time
3. 带你逐个走完 8 个必填 GDD 章节

4. Each section follows: Context > Questions > Options > Decision > Draft > Approval > Write
4. 每个章节都遵循：背景 > 提问 > 选项 > 决策 > 草稿 > 批准 > 写入

5. Each section is written to file immediately after approval (survives crashes)
5. 每个章节在获得批准后立即写入文件（可抵御崩溃）

6. Flags conflicts with existing approved GDDs
6. 标记与现有已批准 GDD 的冲突

7. Routes to specialist agents per category (systems-designer for math,
   economy-designer for economy, narrative-director for story systems)
7. 按类别路由到专家智能体（数学部分交给 systems-designer，
   经济部分交给 economy-designer，故事系统交给 narrative-director）

**The 8 required GDD sections:**
**8 个必填 GDD 章节：**

| # | Section | What Goes Here |
|---|---------|---------------|
| # | 章节 | 此处填写内容 |
| 1 | **Overview** | One-paragraph summary of the system |
| 1 | **Overview（概览）** | 该系统的一段话概述 |
| 2 | **Player Fantasy** | What the player imagines/feels when using this system |
| 2 | **Player Fantasy（玩家幻想）** | 玩家使用该系统时所想象/感受的内容 |
| 3 | **Detailed Rules** | Unambiguous mechanical rules |
| 3 | **Detailed Rules（详细规则）** | 明确无歧义的机制规则 |
| 4 | **Formulas** | Every calculation, with variable definitions and ranges |
| 4 | **Formulas（公式）** | 每一项计算，附变量定义与取值范围 |
| 5 | **Edge Cases** | What happens in weird situations? Explicitly resolved. |
| 5 | **Edge Cases（边缘情况）** | 在异常情况下会发生什么？需明确解决。 |
| 6 | **Dependencies** | What other systems this connects to (bidirectional) |
| 6 | **Dependencies（依赖）** | 该系统与其他系统的连接（双向） |
| 7 | **Tuning Knobs** | Which values designers can safely change, with safe ranges |
| 7 | **Tuning Knobs（调参旋钮）** | 设计师可安全修改的数值，附安全范围 |
| 8 | **Acceptance Criteria** | How do you test that this works? Specific, measurable. |
| 8 | **Acceptance Criteria（验收标准）** | 如何测试它是否有效？需具体、可衡量。 |

Plus a **Game Feel** section: feel reference, input responsiveness (ms/frames),
animation feel targets (startup/active/recovery), impact moments, weight profile.
此外还有一个 **Game Feel（游戏手感）** 章节：手感参考、输入响应（毫秒/帧）、
动画手感目标（起手/持续/收招）、打击瞬间、重量感特征。

### Step 2.2: Review Each GDD
### 步骤 2.2：评审每份 GDD

Before the next system starts, validate the current one:
在开始下一个系统之前，校验当前系统：

```
/design-review design/gdd/combat-system.md
```

Checks the sections your `modes.workflow` tier requires (all 8 at `full`, 5 at
`standard`) for completeness, formula clarity, edge case resolution,
bidirectional dependencies, and testable acceptance criteria.
检查你的 `modes.workflow` 层级所要求的章节（`full` 下全部 8 个，`standard` 下 5 个）
在完整性、公式清晰度、边缘情况处理、
双向依赖以及可测试的验收标准方面是否达标。

**Verdict:** APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED.
Only APPROVED GDDs should proceed.
**结论：** APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED。
只有 APPROVED 的 GDD 才应继续推进。

### Step 2.3: Small Changes Without Full GDDs
### 步骤 2.3：无需完整 GDD 的小改动

For tuning changes, small additions, or tweaks that do not warrant a full GDD:
对于调参变更、小幅新增，或不值得写完整 GDD 的微调：

```
/quick-design "add 10% damage bonus for flanking attacks"
```

This creates a lightweight spec in `design/quick-specs/` instead of a full
8-section GDD. Use it for tuning, number changes, and small additions.
这会在 `design/quick-specs/` 中创建一份轻量级规格说明，而不是完整的
8 章节 GDD。用于调参、数值变更和小幅新增。

### Step 2.4: Cross-GDD Consistency Review
### 步骤 2.4：跨 GDD 一致性评审

After all MVP system GDDs are approved individually:
在所有 MVP 系统 GDD 各自通过评审之后：

```
/review-all-gdds
```

This reads ALL GDDs simultaneously and runs two analysis phases:
这会同时读取所有 GDD，并运行两个分析阶段：

**Phase 1 -- Cross-GDD Consistency:**
**阶段 1 —— 跨 GDD 一致性：**

- Dependency bidirectionality (A references B, does B reference A?)
- 依赖的双向性（A 引用了 B，B 是否也引用 A？）

- Rule contradictions between systems
- 系统之间的规则矛盾

- Stale references to renamed or removed systems
- 对已重命名或已移除系统的过时引用

- Ownership conflicts (two systems claiming the same responsibility)
- 归属冲突（两个系统声称承担同一职责）

- Formula range compatibility (does System A's output fit System B's input?)
- 公式取值范围兼容性（系统 A 的输出是否符合系统 B 的输入？）

- Acceptance criteria cross-check
- 验收标准交叉核对

**Phase 2 -- Design Theory (Game Design Holism):**
**阶段 2 —— 设计理论（游戏设计整体论）：**

- Competing progression loops (do two systems fight for the same reward space?)
- 相互竞争的进度循环（两个系统是否争夺同一奖励空间？）

- Cognitive load (more than 4 active systems at once?)
- 认知负荷（同时有超过 4 个活跃系统？）

- Dominant strategies (one approach that makes all others irrelevant)
- 支配性策略（一种使其他所有策略都失去意义的玩法）

- Economic loop analysis (sources and sinks balanced?)
- 经济循环分析（产出与消耗是否平衡？）

- Difficulty curve consistency across systems
- 各系统之间难度曲线的一致性

- Pillar alignment and anti-pillar violations
- 与支柱的对齐以及反支柱的违背

- Player fantasy coherence
- 玩家幻想的一致性

**Output:** `design/gdd/gdd-cross-review-[date].md` with a verdict.
**输出：** 带结论的 `design/gdd/gdd-cross-review-[date].md`。

### Step 2.5: Narrative Design (If Applicable)
### 步骤 2.5：叙事设计（如适用）

If your game has story, lore, or dialogue, this is when you build it:
如果你的游戏有故事、世界观设定或对话，此时就开始构建它们：

1. **World-building** -- Use `world-builder` to define factions, history,
   geography, and rules of your world
1. **世界构建** —— 使用 `world-builder` 定义你世界中的阵营、历史、
   地理和规则

2. **Story structure** -- Use `narrative-director` to design story arcs,
   character arcs, and narrative beats
2. **故事结构** —— 使用 `narrative-director` 设计故事弧线、
   角色弧线和叙事节拍

3. **Character sheets** -- Use the `narrative-character-sheet.md` template
3. **角色档案** —— 使用 `narrative-character-sheet.md` 模板

### Phase 2 Gate
### 阶段 2 门禁

```
/gate-check technical-setup
```

**Requirements to pass:**
**通过要求：**

- `design/gdd/systems-index.md` listing at least the MVP systems, with their
  dependencies mapped
- `design/gdd/systems-index.md` 至少列出 MVP 系统，并映射出
  它们之间的依赖关系

- A GDD for every MVP system, each passing `/design-review` (no MAJOR REVISION
  NEEDED)
- 每个 MVP 系统都有 GDD，且各自通过 `/design-review`（无 MAJOR REVISION
  NEEDED）

- A cross-GDD review report from `/review-all-gdds` whose verdict is not FAIL —
  and not NOT ASSESSED, which means the GDDs could not be compared
- 一份来自 `/review-all-gdds` 的跨 GDD 评审报告，其结论不是 FAIL ——
  也不是 NOT ASSESSED（后者意味着这些 GDD 无法比较）

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-technical-setup.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-technical-setup.md` 包含完整的
检查清单以及各层级会舍弃的条目。

---

## Phase 3: Technical Setup
## 阶段 3：技术准备

### What Happens in This Phase
### 本阶段会发生什么

You make key technical decisions, document them as Architecture Decision Records
(ADRs), validate them through review, and produce a control manifest that
gives programmers flat, actionable rules. You also establish UX foundations.
你做出关键技术决策，将其记录为架构决策记录
（ADR），通过评审进行校验，并产出一份控制清单，
为程序员提供扁平、可执行的规则。你还要建立 UX 基础。

### Phase 3 Pipeline
### 阶段 3 流水线

```
/create-architecture  -->  /architecture-decision (x N)  -->  /architecture-review
        |                          |                                   |
        v                          v                                   v
  Master architecture       Per-decision ADRs              Validates completeness,
  document covering         in docs/architecture/          dependency ordering,
  all systems               adr-*.md                       engine compatibility
                                                                      |
                                                                      v
                                                         /create-control-manifest
                                                                      |
                                                                      v
                                                         Flat programmer rules
                                                         docs/architecture/
                                                         control-manifest.md
        Also in this phase:
        -------------------
        /ux-design  -->  /ux-review
        Accessibility requirements doc  (/ux-design accessibility)
        Interaction pattern library     (/ux-design patterns)
        /test-setup  -->  test framework + CI workflow
```

### Step 3.1: Master Architecture Document
### 步骤 3.1：主架构文档

```
/create-architecture
```

Creates the overarching architecture document in `docs/architecture/architecture.md`
covering system boundaries, data flow, and integration points.
在 `docs/architecture/architecture.md` 中创建总体架构文档，
涵盖系统边界、数据流和集成点。

### Step 3.2: Architecture Decision Records (ADRs)
### 步骤 3.2：架构决策记录（ADR）

For each significant technical decision:
对于每一项重要的技术决策：

```
/architecture-decision "State Machine vs Behavior Tree for NPC AI"
```

**What happens:** The skill guides you through creating an ADR with:
**会发生什么：** 该技能引导你创建一份 ADR，包含：

- Context and decision drivers
- 背景与决策驱动因素

- All options with pros/cons and engine compatibility
- 所有选项及其优缺点和引擎兼容性

- Chosen option with rationale
- 所选方案及其理由

- Consequences (positive, negative, risks)
- 后果（正面、负面、风险）

- Dependencies (Depends On, Enables, Blocks, Ordering Note)
- 依赖（依赖项、启用项、阻塞项、排序说明）

- GDD Requirements Addressed (linked by TR-ID)
- 所满足的 GDD 需求（通过 TR-ID 关联）

ADRs go through a lifecycle: Proposed > Accepted > Superseded/Deprecated.
ADR 会经历一个生命周期：Proposed > Accepted > Superseded/Deprecated。

**Minimum 3 Foundation-layer ADRs are required** before the gate check.
在门禁检查之前**至少需要 3 份基础层 ADR**。

**Retrofitting existing ADRs:** If you already have ADRs from a brownfield
project:
**改造现有 ADR：** 如果你从棕地项目中已有 ADR：

```
/architecture-decision retrofit docs/architecture/adr-005.md
```

This detects which template sections are missing and adds only those, never
overwriting existing content.
这会检测缺失哪些模板章节，只补充这些章节，绝不
覆盖已有内容。

### Step 3.3: Architecture Review
### 步骤 3.3：架构评审

```
/architecture-review
```

Validates all ADRs together:
统一校验所有 ADR：

- Topological sort of ADR dependencies (detects cycles)
- 对 ADR 依赖做拓扑排序（检测循环）

- Engine compatibility verification
- 引擎兼容性验证

- GDD Revision Flags (flags GDD sections that need updates based on ADR choices)
- GDD 修订标记（标记那些因 ADR 选择而需要更新的 GDD 章节）

- TR-ID registry maintenance (`docs/architecture/tr-registry.yaml`)
- TR-ID 注册表维护（`docs/architecture/tr-registry.yaml`）

### Step 3.4: Control Manifest
### 步骤 3.4：控制清单

```
/create-control-manifest
```

Takes all Accepted ADRs and produces a flat programmer rules sheet:
汇集所有 Accepted 的 ADR，产出一份扁平的程序员规则表：

```
docs/architecture/control-manifest.md
```

This contains Required patterns, Forbidden patterns, and Guardrails organized
by code layer. Stories created later embed the manifest version date so
staleness can be detected.
其中包含按代码层级组织的"必须使用模式""禁止使用模式"和"防护规则"。
之后创建的故事会嵌入该清单的版本日期，以便
检测是否过期。

### Step 3.5: Accessibility Requirements
### 步骤 3.5：无障碍需求

Create `design/accessibility-requirements.md` using the template. Commit to a
tier (Basic / Standard / Comprehensive / Exemplary) and fill the 4-axis feature
matrix (visual, motor, cognitive, auditory).
使用模板创建 `design/accessibility-requirements.md`。确定一个
层级（Basic / Standard / Comprehensive / Exemplary），并填写四轴功能
矩阵（视觉、运动、认知、听觉）。

This document is required in Phase 3 because UX specs (written in Phase 4)
reference this tier — it is a design prerequisite, not a UX deliverable.
`/ux-design accessibility` authors it; `/ux-design patterns` starts the
interaction pattern library (`design/ux/interaction-patterns.md`), which the same
gate checks.
此文档在阶段 3 是必需的，因为 UX 规格（在阶段 4 编写）
会引用该层级 —— 它是设计前置条件，而不是 UX 交付物。
`/ux-design accessibility` 负责撰写它；`/ux-design patterns` 启动
交互模式库（`design/ux/interaction-patterns.md`），同一道
门禁也会检查后者。

### Step 3.6: Test Framework
### 步骤 3.6：测试框架

```
/test-setup
```

Scaffolds the engine's test root, `.github/workflows/tests.yml` and one example
test; the Pre-Production gate checks for them. `/test-helpers` can follow once
there are systems to test.
搭建引擎的测试根目录、`.github/workflows/tests.yml` 和一个示例
测试；前期制作门禁会检查它们。等有了可测试的系统之后，
再运行 `/test-helpers`。

### Phase 3 Gate
### 阶段 3 门禁

```
/gate-check pre-production
```

**Requirements to pass:**
**通过要求：**

- The engine configured, `project.yaml` populated (engine, naming, performance)
  and the engine reference docs present
- 引擎已配置、`project.yaml` 已填充（引擎、命名、性能），
  且引擎参考文档已存在

- Art bible Sections 1–4 (`design/art/art-bible.md`)
- 美术圣经第 1–4 节（`design/art/art-bible.md`）

- `docs/architecture/architecture.md`, at least 3 ADRs covering Foundation-layer
  systems, an `/architecture-review` report and
  `docs/architecture/requirements-traceability.md`
- `docs/architecture/architecture.md`、至少 3 份覆盖基础层
  系统的 ADR、一份 `/architecture-review` 报告，以及
  `docs/architecture/requirements-traceability.md`

- The test framework in the engine's test root, `.github/workflows/tests.yml`
  and one example test (`/test-setup`)
- 引擎测试根目录中的测试框架、`.github/workflows/tests.yml`
  和一个示例测试（`/test-setup`）

- `design/accessibility-requirements.md` and `design/ux/interaction-patterns.md`
  (`/ux-design accessibility`, `/ux-design patterns`)
- `design/accessibility-requirements.md` 和 `design/ux/interaction-patterns.md`
  （`/ux-design accessibility`、`/ux-design patterns`）

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-pre-production.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-pre-production.md` 包含完整的
检查清单以及各层级会舍弃的条目。

---

## Phase 4: Pre-Production
## 阶段 4：前期制作

### What Happens in This Phase
### 本阶段会发生什么

You create UX specs for key screens, prototype risky mechanics, turn design
documents into implementable stories, plan your first sprint, and build a
Vertical Slice that proves the core loop is fun.
你为关键界面编写 UX 规格、为高风险机制制作原型、把设计
文档转化为可实施的故事、规划第一个冲刺，并构建一个
垂直切片来证明核心循环确实有趣。

### Phase 4 Pipeline
### 阶段 4 流水线

```
/ux-design  -->  /vertical-slice  -->  /create-epics  -->  /create-stories  -->  /sprint-plan
    |                   |                   |                   |                       |
    v                   v                   v                   v                       v
  UX specs       Production-quality   Epic files in       Story files in          First sprint with
  design/ux/     end-to-end build     production/         production/             prioritized stories
                 in prototypes/       epics/*/EPIC.md     epics/*/story-*.md      production/sprints/
                 PROCEED/PIVOT/KILL   (one per module)    (one per behaviour)     sprint-*.md
    |                                                          |
    v                                                          v
 /ux-review                                             /story-readiness
 (validates specs                                       (validates each story
  before epics)                                          before pickup)
                                                               |
                                                               v
                                                           /dev-story
                                                         (implements the story,
                                                          routes to right agent)
```

### Step 4.1: UX Specs for Key Screens
### 步骤 4.1：关键界面的 UX 规格

Before writing epics, create UX specs so that story authors know what screens
exist and what player interactions they must support.
在编写史诗之前，先创建 UX 规格，让故事作者知道
存在哪些界面，以及它们必须支持哪些玩家交互。

**UX Specs:**
**UX 规格：**

```
/ux-design main-menu
/ux-design core-gameplay-hud
```

Three modes: screen/flow, HUD, and interaction patterns. Output goes to
`design/ux/`. Each spec includes: player need, layout zones, states,
interaction map, data requirements, events fired, accessibility, localization.
三种模式：界面/流程、HUD 和交互模式。输出写入
`design/ux/`。每份规格包含：玩家需求、布局分区、状态、
交互映射、数据需求、触发的事件、无障碍、本地化。

Reads your `accessibility-requirements.md` (written in Phase 3) and your
input method config from `project.yaml` (the `platform.*` block, falling back
to `technical-preferences.md`) to drive accessibility and input coverage
checks — no need to re-specify them per screen.
它会读取你的 `accessibility-requirements.md`（在阶段 3 编写）以及
`project.yaml` 中的输入方式配置（`platform.*` 区块，缺失时回退到
`technical-preferences.md`），以驱动无障碍和输入覆盖
检查 —— 无需在每个界面重复指定。

> **Tip:** `/design-system` emits a 📌 UX Flag for every system with UI
> requirements. Use those flags as a checklist for which screens need specs.
>
> **提示：** `/design-system` 会为每个带 UI 需求的系统发出一个 📌 UX 标记。
> 可将这些标记作为清单，判断哪些界面需要规格。

**Interaction Pattern Library:**
**交互模式库：**

```
/ux-design patterns
```

Started in Phase 3 (the Pre-Production gate checks it); extend it here as the
key screens add patterns. `design/ux/interaction-patterns.md` holds 16 standard
controls plus game-specific patterns (inventory slot, ability icon, HUD bar,
dialogue box, etc.) with animation and sound standards.
在阶段 3 启动（前期制作门禁会检查它）；随着关键界面新增模式，
在此处扩展它。`design/ux/interaction-patterns.md` 包含 16 种标准
控件，以及游戏特有的模式（物品栏格子、技能图标、HUD 条、
对话框等），并附带动画与音效标准。

**UX Review:**
**UX 评审：**

```
/ux-review all
```

Validates UX specs for GDD alignment and accessibility tier compliance.
Produces APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED verdict.
校验 UX 规格与 GDD 的对齐情况以及无障碍层级合规性。
产出 APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED 结论。

### Step 4.2: Build the Vertical Slice
### 步骤 4.2：构建垂直切片

The vertical slice is the production-quality proof that you can build the full
game loop end-to-end before committing to full Production.
垂直切片是一份制作级质量的证明：你能在正式投入完整制作
之前端到端地构建出完整的游戏循环。

```
/vertical-slice
```

**What it proves:** Does a player, starting from nothing, experience the core
fantasy within a few minutes, without developer guidance?
**它证明什么：** 玩家从零开始，在没有开发者引导的情况下，
是否能在几分钟内体验到核心幻想？

**What it builds:** A near-production-quality playable build covering at least
one complete [start → challenge → resolution] cycle. Uses real architecture
layers, real naming conventions, no hardcoded values — but not final art or
audio. This is not a throwaway like the concept prototype; it demonstrates
production pipeline feasibility.
**它构建什么：** 一个接近制作级质量的可玩版本，至少覆盖
一个完整的 [开始 → 挑战 → 解决] 循环。使用真实的架构
分层、真实的命名约定、无硬编码数值 —— 但不用最终美术或
音频。它不像概念原型那样是一次性的；它展示的是
制作流水线的可行性。

**Note on concept prototyping:** If you ran `/prototype` in Phase 1 (Concept),
you already validated the core idea is fun. The vertical slice now validates
you can build it properly. They answer different questions. If you skipped the
concept prototype, now is a reasonable time to run one first before investing
in the full slice.
**关于概念原型的说明：** 如果你在阶段 1（概念）运行过 `/prototype`，
那么你已经验证了核心想法很有趣。垂直切片现在验证的是
你能否把它正确地做出来。两者回答的是不同的问题。如果你跳过了
概念原型，那么现在先跑一个原型、再投入完整切片，
是合理的时机。

**Verdict:** The vertical slice produces a PROCEED / PIVOT / KILL verdict, or
NOT ASSESSED while nobody has played it through.
**结论：** 垂直切片会产出 PROCEED / PIVOT / KILL 结论；若
尚无人完整通关体验，则为 NOT ASSESSED。

- **PROCEED** → move to Step 4.3 (epics and stories)
- **PROCEED** → 进入步骤 4.3（史诗与故事）

- **PIVOT** → revise affected GDDs with `/design-system [mechanic]`, then re-run `/vertical-slice`
- **PIVOT** → 用 `/design-system [mechanic]` 修订受影响的 GDD，然后重新运行 `/vertical-slice`

- **KILL** → return to `/brainstorm` with what you learned
- **KILL** → 带着你的收获回到 `/brainstorm`

### Step 4.3: Create Epics and Stories From Design Artifacts
### 步骤 4.3：从设计产物创建史诗与故事

```
/create-epics layer: foundation
/create-stories [epic-slug]   # repeat for each epic
/create-epics layer: core
/create-stories [epic-slug]   # repeat for each core epic
```

`/create-epics` reads your GDDs, ADRs, and architecture to define epic scope —
one epic per architectural module. Then `/create-stories` breaks each epic into
implementable story files in `production/epics/[slug]/`. Each story embeds:
`/create-epics` 读取你的 GDD、ADR 和架构来界定史诗范围 ——
每个架构模块对应一个史诗。随后 `/create-stories` 将每个史诗拆分为
`production/epics/[slug]/` 中可实施的故事文件。每个故事嵌入：

- GDD requirement references (TR-IDs, not quoted text -- stays fresh)
- GDD 需求引用（使用 TR-ID，而非引用原文 —— 可保持新鲜度）

- ADR references (only from Accepted ADRs; Proposed ADRs cause `Status: Blocked`)
- ADR 引用（仅来自 Accepted 的 ADR；引用 Proposed 的 ADR 会导致 `Status: Blocked`）

- Control manifest version date (for staleness detection)
- 控制清单版本日期（用于检测过期）

- Engine-specific implementation notes
- 引擎特定的实现说明

- Acceptance criteria from the GDD
- 来自 GDD 的验收标准

Once stories exist, run `/dev-story [story-path]` to implement one — it routes
automatically to the correct programmer agent.
故事创建之后，运行 `/dev-story [story-path]` 来实施其中一个 —— 它会
自动路由到正确的程序员智能体。

### Step 4.4: Validate Stories Before Pickup
### 步骤 4.4：领取前校验故事

```
/story-readiness production/epics/combat/story-combat-damage-calc.md
```

Checks: Design completeness, Architecture coverage, Scope clarity, Definition
of Done. Verdict: READY / NEEDS WORK / BLOCKED / NOT ASSESSED.
检查：设计完整性、架构覆盖度、范围清晰度、完成定义。
结论：READY / NEEDS WORK / BLOCKED / NOT ASSESSED。

### Step 4.5: Effort Estimation
### 步骤 4.5：工作量估算

```
/estimate production/epics/combat/story-combat-damage-calc.md
```

Provides effort estimates with risk assessment.
提供带风险评估的工作量估算。

### Step 4.6: Plan Your First Sprint
### 步骤 4.6：规划你的第一个冲刺

```
/sprint-plan new
```

**What happens:** The `producer` agent collaborates on sprint planning:
**会发生什么：** `producer` 智能体协作完成冲刺规划：

- Asks for sprint goal and available time
- 询问冲刺目标和可用时间

- Breaks the goal into Must Have / Should Have / Nice to Have tasks
- 将目标拆分为"必须有 / 应该有 / 锦上添花"任务

- Identifies risks and blockers
- 识别风险和阻塞项

- Creates `production/sprints/sprint-001.md`
- 创建 `production/sprints/sprint-001.md`

- Populates `production/sprint-status.yaml` (machine-readable story tracking)
- 填充 `production/sprint-status.yaml`（机器可读的故事跟踪文件）

### Step 4.7: Vertical Slice (recommended)
### 步骤 4.7：垂直切片（推荐）

Before advancing to Production, build and playtest a Vertical Slice:
在进入制作阶段之前，先构建并试玩一个垂直切片：

- One complete end-to-end core loop, playable from start to finish
- 一个完整端到端、可从开始玩到结束的核心循环

- Representative quality (not placeholder everything)
- 具有代表性的质量（不是处处占位）

- Played unguided in at least 1 documented session (3+ recommended)
- 在至少 1 次有记录的会话中无引导试玩（推荐 3 次以上）

- Playtest report written (`/playtest-report`)
- 已编写试玩报告（`/playtest-report`）

`/gate-check production` treats it as recommended, not blocking: a skipped
slice is CONCERNS, a slice nobody has played is NOT ASSESSED, and a built slice
that is broken or not fun is a FAIL. At `workflow: minimal` the slice items
drop: the gate asks instead whether the current build's core loop is fun and
runs end to end.
`/gate-check production` 将其视为推荐项而非阻塞项：跳过切片
记为 CONCERNS，无人试玩过的切片记为 NOT ASSESSED，而构建出的切片
若有问题或不好玩则为 FAIL。在 `workflow: minimal` 下，切片相关条目
不作要求：门禁改为询问当前构建的核心循环是否有趣、
是否能端到端运行。

### Phase 4 Gate
### 阶段 4 门禁

```
/gate-check production
```

**Requirements to pass:**
**通过要求：**

- A first sprint plan in `production/sprints/`, and Foundation and Core epics
  with their stories under `production/epics/`
- `production/sprints/` 中有一份首个冲刺计划，以及基础和核心史诗
  及其故事位于 `production/epics/` 下

- The complete art bible (all 9 sections) with its AD-ART-BIBLE sign-off
  recorded
- 完整的美术圣经（全部 9 节）及其 AD-ART-BIBLE 签核
  已记录

- Every MVP GDD complete, the master architecture document, Foundation and Core
  ADRs `Accepted`, and the control manifest
- 每个 MVP GDD 已完成、主架构文档已就绪、基础与核心
  ADR 均为 `Accepted`，以及控制清单已产出

- UX specs for the key screens (main menu, HUD, pause menu) that passed
  `/ux-review`
- 关键界面（主菜单、HUD、暂停菜单）的 UX 规格已通过
  `/ux-review`

- Recommended, not blocking: a Vertical Slice built and played in at least one
  documented session. Skipped → CONCERNS; built but broken or not fun → FAIL;
  built but not yet played → NOT ASSESSED
- 推荐而非阻塞：垂直切片已构建，并在至少一次
  有记录的会话中试玩过。跳过 → CONCERNS；已构建但有问题或不好玩 → FAIL；
  已构建但尚未试玩 → NOT ASSESSED

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-production.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-production.md` 包含完整的
检查清单以及各层级会舍弃的条目。

---

## Phase 5: Production
## 阶段 5：制作

### What Happens in This Phase
### 本阶段会发生什么

This is the core production loop. You work in sprints (typically 1-2 weeks),
implementing features story by story, tracking progress, and closing stories
through a structured completion review. This phase repeats until your game
is content-complete.
这是核心制作循环。你以冲刺为单位工作（通常 1-2 周），
逐个故事实现功能、跟踪进度，并通过结构化的完成评审
关闭故事。此阶段会不断重复，直到游戏
内容完整。

### Phase 5 Pipeline (Per Sprint)
### 阶段 5 流水线（按冲刺）

```
/sprint-plan new  -->  /story-readiness  -->  implement  -->  /story-done
       |                     |                    |                |
       v                     v                    v                v
  Sprint created       Story validated      Code written     8-phase review:
  sprint-status.yaml   READY verdict        Tests pass       verify criteria,
  populated                                                  check deviations,
                                                             update story status
       |
       |  (repeat per story until sprint complete)
       v
  /sprint-status  (quick 30-line snapshot anytime)
  /scope-check    (if scope is growing)
  /retrospective  (at sprint end)
```

### Step 5.1: The Story Lifecycle
### 步骤 5.1：故事生命周期

The production phase centers on the **story lifecycle**:
制作阶段以**故事生命周期**为核心：

```
/story-readiness  -->  implement  -->  /story-done  -->  next story
```

**1. Story Readiness:** Before picking up a story, validate it:
**1. 故事就绪度：** 在领取一个故事之前，先校验它：

```
/story-readiness production/epics/combat/story-combat-damage-calc.md
```

This checks design completeness, architecture coverage, ADR status (blocks
if ADR is still Proposed), control manifest version (warns if stale), and
scope clarity. Verdict: READY / NEEDS WORK / BLOCKED / NOT ASSESSED.
这会检查设计完整性、架构覆盖度、ADR 状态（若 ADR 仍为 Proposed
则阻塞）、控制清单版本（若过期则警告）以及
范围清晰度。结论：READY / NEEDS WORK / BLOCKED / NOT ASSESSED。

**2. Implementation:** Work with the appropriate agents:
**2. 实施：** 与合适的智能体协作：

- `gameplay-programmer` for gameplay systems
- `gameplay-programmer` 负责游戏玩法系统

- `engine-programmer` for core engine work
- `engine-programmer` 负责核心引擎工作

- `ai-programmer` for AI behavior
- `ai-programmer` 负责 AI 行为

- `network-programmer` for multiplayer
- `network-programmer` 负责多人联机

- `ui-programmer` for UI code
- `ui-programmer` 负责 UI 代码

- `tools-programmer` for dev tools
- `tools-programmer` 负责开发工具

All agents follow the collaborative protocol: they read the design doc, ask
clarifying questions, present architectural options, get your approval, then
implement.
所有智能体都遵循协作协议：它们阅读设计文档、提出
澄清问题、给出架构选项、获得你的批准，然后
实施。

**3. Story Completion:** When a story is done:
**3. 故事完成：** 当一个故事完成后：

```
/story-done production/epics/combat/story-combat-damage-calc.md
```

This runs an 8-phase completion review:
这会运行一个 8 阶段的完成评审：

1. Find and read the story file
1. 找到并读取故事文件

2. Load referenced GDD, ADRs, and control manifest
2. 加载被引用的 GDD、ADR 和控制清单

3. Verify acceptance criteria (auto-checkable, manual, deferred)
3. 校验验收标准（可自动检查、手动检查、延期）

4. Check for GDD/ADR deviations (BLOCKING / ADVISORY / OUT OF SCOPE)
4. 检查与 GDD/ADR 的偏差（BLOCKING / ADVISORY / OUT OF SCOPE）

5. Prompt for code review
5. 提示进行代码评审

6. Generate completion report (COMPLETE / COMPLETE WITH NOTES / BLOCKED)
6. 生成完成报告（COMPLETE / COMPLETE WITH NOTES / BLOCKED）

7. Update story `Status: Complete` with completion notes
7. 将故事状态更新为 `Status: Complete` 并附完成备注

8. Surface the next ready story
8. 呈现下一个就绪的故事

Tech debt discovered during review is logged to `docs/tech-debt-register.md`.
评审过程中发现的技术债会记录到 `docs/tech-debt-register.md`。

### Step 5.2: Sprint Tracking
### 步骤 5.2：冲刺跟踪

Check progress anytime:
随时检查进度：

```
/sprint-status
```

Quick 30-line snapshot reading from `production/sprint-status.yaml`.
从 `production/sprint-status.yaml` 读取的 30 行快速快照。

If scope is growing:
如果范围在膨胀：

```
/scope-check production/sprints/sprint-003.md
```

This compares current scope against the original plan and flags scope increase,
recommends cuts.
这会将当前范围与原始计划对比，标记出范围扩大，
并建议削减项。

### Step 5.3: Content Tracking
### 步骤 5.3：内容跟踪

```
/content-audit
```

Compares GDD-specified content against what has been implemented. Catches
content gaps early.
将 GDD 规定的内容与已实现的内容进行对比。可尽早发现
内容缺口。

### Step 5.4: Design Change Propagation
### 步骤 5.4：设计变更传播

When a GDD changes after stories have been created:
当故事创建之后 GDD 发生变更时：

```
/propagate-design-change design/gdd/combat-system.md
```

Git-diffs the GDD, finds affected ADRs, generates an impact report, and
walks you through Superseded/update/keep decisions.
对 GDD 做 Git 差异比对、找出受影响的 ADR、生成影响报告，并
引导你做出"标记取代/更新/保留"的决策。

### Step 5.5: Multi-System Features (Team Orchestration)
### 步骤 5.5：多系统功能（团队编排）

For features spanning multiple domains, use team skills:
对于跨多个领域的功能，使用团队技能：

```
/team-combat "healing ability with HoT and cleanse"
/team-narrative "Act 2 story content"
/team-ui "inventory screen redesign"
/team-level "forest dungeon level"
/team-audio "combat audio pass"
```

Each team skill coordinates a 6-phase collaborative workflow:
每个团队技能都协调一个 6 阶段的协作式工作流：

1. **Design** -- game-designer asks questions, presents options
1. **设计** —— game-designer 提出问题、给出选项

2. **Architecture** -- lead-programmer proposes code structure
2. **架构** —— lead-programmer 提出代码结构

3. **Parallel Implementation** -- specialists work simultaneously
3. **并行实施** —— 专家同时工作

4. **Integration** -- gameplay-programmer wires everything together
4. **集成** —— gameplay-programmer 将所有部分连接起来

5. **Validation** -- qa-tester runs against acceptance criteria
5. **校验** —— qa-tester 对照验收标准执行

6. **Report** -- coordinator summarizes status
6. **报告** —— 协调者汇总状态

The orchestration is automated, but **decision points stay with you**.
编排是自动化的，但**决策点始终由你掌控**。

### Step 5.6: Sprint Review and Next Sprint
### 步骤 5.6：冲刺评审与下一个冲刺

At the end of a sprint:
在一个冲刺结束时：

```
/retrospective
```

Analyzes planned vs. completed, velocity, blockers, and actionable improvements.
分析计划与实际完成情况、速度、阻塞项以及可落地的改进措施。

Then plan the next sprint:
然后规划下一个冲刺：

```
/sprint-plan new
```

### Step 5.7: Milestone Reviews
### 步骤 5.7：里程碑评审

At milestone checkpoints:
在里程碑检查点：

```
/milestone-review "alpha"
```

Produces feature completeness, quality metrics, risk assessment, and go/no-go
recommendation.
产出功能完整性、质量指标、风险评估，以及继续/不继续（go/no-go）
的建议。

### Phase 5 Gate
### 阶段 5 门禁

```
/gate-check polish
```

**Requirements to pass:**
**通过要求：**

- Every core GDD mechanic implemented, and the main gameplay path playable end
  to end
- 每个核心 GDD 机制都已实现，且主游戏流程可端到端
  游玩

- Tests in the engine's test root covering the Logic and Integration stories,
  and passing
- 引擎测试根目录中的测试覆盖逻辑与集成类故事，
  并且通过

- A smoke-check report in `production/qa/` with PASS or PASS WITH WARNINGS
- `production/qa/` 中有一份冒烟检查报告，结果为 PASS 或 PASS WITH WARNINGS

- A `/team-qa` sign-off (APPROVED or APPROVED WITH CONDITIONS)
- 一份 `/team-qa` 签核（APPROVED 或 APPROVED WITH CONDITIONS）

- At least 3 documented playtest sessions (new player, mid-game, difficulty
  curve) and the fun hypothesis validated or revised
- 至少 3 次有记录的试玩会话（新玩家、中期游戏、难度
  曲线），并且"有趣假设"已获验证或修订

- No open S1 Critical bugs, and performance within budget
- 没有未解决的 S1 致命缺陷，且性能在预算之内

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-polish.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-polish.md` 包含完整的
检查清单以及各层级会舍弃的条目。

---

## Phase 6: Polish
## 阶段 6：打磨

### What Happens in This Phase
### 本阶段会发生什么

Your game is feature-complete. Now you make it good. This phase focuses on
performance, balance, accessibility, audio, visual polish, and playtesting.
你的游戏功能已完整。现在要把它做好。本阶段聚焦于
性能、平衡、无障碍、音频、视觉打磨和试玩测试。

### Phase 6 Pipeline
### 阶段 6 流水线

```
/perf-profile  -->  /balance-check  -->  /asset-audit  -->  /playtest-report (x3)
       |                  |                    |                    |
       v                  v                    v                    v
  Profile CPU/GPU    Analyze formulas     Verify naming,      Cover: new player,
  memory, optimize   and data for         formats, sizes      mid-game, difficulty
  bottlenecks        broken progressions                      curve

  /tech-debt  -->  /team-polish
       |                |
       v                v
  Track and        Coordinated pass:
  prioritize       performance + art +
  debt items       audio + UX + QA

  /security-audit  -->  /localize qa  -->  /release-checklist  -->  /changelog
                        (per language)                           + /patch-notes
  Release readiness: the Polish -> Release gate checks all four.
```

### Step 6.1: Performance Profiling
### 步骤 6.1：性能剖析

```
/perf-profile
```

Guides you through structured performance profiling:
引导你进行结构化的性能剖析：

- Establish targets (FPS, memory, platform)
- 确立目标（FPS、内存、平台）

- Identify bottlenecks ranked by impact
- 按影响程度排序识别瓶颈

- Generate actionable optimization tasks with code locations and expected gains
- 生成可执行的优化任务，附带代码位置和预期收益

### Step 6.2: Balance Analysis
### 步骤 6.2：平衡性分析

```
/balance-check assets/data/combat_damage.json
```

Analyzes balance data for statistical outliers, broken progression curves,
degenerate strategies, and economy imbalances.
分析平衡数据中的统计离群值、断裂的进度曲线、
退化策略以及经济失衡。

### Step 6.3: Asset Audit
### 步骤 6.3：资产审计

```
/asset-audit
```

Verifies naming conventions, file format standards, and size budgets across
all assets.
校验所有资产的命名约定、文件格式标准和体积预算。

### Step 6.4: Playtesting (Required: 3 Sessions)
### 步骤 6.4：试玩测试（要求：3 次会话）

```
/playtest-report
```

Generates structured playtest reports. Three sessions are required, covering:
生成结构化的试玩报告。需要三次会话，覆盖：

- New player experience
- 新玩家体验

- Mid-game systems
- 中期游戏系统

- Difficulty curve
- 难度曲线

### Step 6.5: Technical Debt Assessment
### 步骤 6.5：技术债评估

```
/tech-debt
```

Scans for TODO/FIXME/HACK comments, code duplication, overly complex functions,
missing tests, and outdated dependencies. Each item categorized and prioritized.
扫描 TODO/FIXME/HACK 注释、代码重复、过于复杂的函数、
缺失的测试以及过时的依赖。每个条目都会被分类并排定优先级。

### Step 6.6: Coordinated Polish Pass
### 步骤 6.6：协同打磨轮次

```
/team-polish "combat system"
```

Coordinates 4 specialists in parallel:
并行协调 4 位专家：

1. Performance optimization (performance-analyst lists the optimisations; a
   programmer in the active set implements them — at `team.size: individual`,
   where none is active, the list is handed to `/dev-story`)
1. 性能优化（performance-analyst 列出优化项；活跃集合中的
   程序员负责实施 —— 在 `team.size: individual` 下若没有活跃程序员，
   该清单会交给 `/dev-story`）

2. Visual polish (technical-artist)
2. 视觉打磨（technical-artist）

3. Audio polish (sound-designer)
3. 音频打磨（sound-designer）

4. Feel/juice (gameplay-programmer + technical-artist)
4. 手感/爽感（gameplay-programmer + technical-artist）

You set priorities; the team executes with your approval at each step.
你设定优先级；团队在每一步都经你批准后执行。

### Step 6.7: Localization and Accessibility
### 步骤 6.7：本地化与无障碍

```
/localize scan
```

Scans for hardcoded strings, concatenation that breaks translation, text that
does not account for expansion, and missing locale files.
扫描硬编码字符串、会破坏翻译的字符串拼接、未考虑
文本膨胀的文案，以及缺失的 locale 文件。

Accessibility is audited against the tier committed in Phase 3's accessibility
requirements document.
无障碍性依据阶段 3 无障碍需求文档中承诺的层级进行审计。

### Step 6.8: Security Audit
### 步骤 6.8：安全审计

```
/security-audit
```

Required for the release gate at `standard` and `full`: the newest report must
have no open CRITICAL or HIGH finding. A report whose recommendation is NOT
ASSESSED leaves the gate's security item NOT ASSESSED.
在 `standard` 和 `full` 下，发布门禁要求它：最新报告必须
没有未解决的 CRITICAL 或 HIGH 级别问题。若报告的建议为 NOT
ASSESSED，则门禁的安全项也保持 NOT ASSESSED。

### Step 6.9: Localization QA
### 步骤 6.9：本地化 QA

```
/localize qa
```

Run it for every language you ship. At `full` the release gate needs a PASS (or
PASS WITH CONDITIONS) for each; a locale nobody has checked is NOT ASSESSED.
对你发布的每一种语言都运行它。在 `full` 下，发布门禁要求每种语言
都有 PASS（或 PASS WITH CONDITIONS）；无人检查过的 locale 为 NOT ASSESSED。

### Step 6.10: Release Checklist
### 步骤 6.10：发布检查清单

```
/release-checklist all
```

The argument is the platform scope (`pc`, `console`, `mobile` or `all`), not a
version.
参数是平台范围（`pc`、`console`、`mobile` 或 `all`），而不是
版本号。

Generates a comprehensive pre-release checklist covering:
生成一份全面的发布前检查清单，涵盖：

- Build verification (all platforms compile and run)
- 构建验证（所有平台均可编译并运行）

- Certification requirements (platform-specific)
- 认证要求（平台特定）

- Store metadata (descriptions, screenshots, trailers)
- 商店元数据（描述、截图、预告片）

- Legal compliance (EULA, privacy policy, ratings)
- 法律合规（EULA、隐私政策、分级）

- Save game compatibility
- 存档兼容性

- Analytics verification
- 分析统计验证

### Step 6.11: Changelog and Patch Notes
### 步骤 6.11：更新日志与补丁说明

```
/patch-notes v1.0.0
```

Generates player-friendly patch notes from git history and sprint data.
Translates developer language into player language.
从 git 历史和冲刺数据生成面向玩家的补丁说明。
将开发者语言转换为玩家语言。

```
/changelog v1.0.0
```

Generates an internal changelog (more technical, for the team).
生成内部更新日志（更偏技术性，面向团队）。

The release gate needs the changelog or the patch notes drafted, so write them
now; `/team-release` publishes them once the release is a GO.
发布门禁需要更新日志或补丁说明已完成草稿，所以现在就写好；
`/team-release` 会在发布确定为 GO 之后发布它们。

### Phase 6 Gate
### 阶段 6 门禁

```
/gate-check release
```

**Requirements to pass:**
**通过要求：**

- Every milestone feature implemented and the content complete
- 每个里程碑功能都已实现，内容完整

- A QA test plan and a QA sign-off, and every Must Have story's test evidence
  (UI: retained screenshots; Visual/Feel: screenshots plus lead sign-off)
- 一份 QA 测试计划和一份 QA 签核，以及每个"必须有"故事的测试证据
  （UI：保留的截图；视觉/手感：截图加上负责人签核）

- Smoke check PASS on the release candidate, and the test suite passing
- 发布候选版本冒烟检查 PASS，且测试套件通过

- `/balance-check` run, the release checklist completed, and the changelog or
  patch notes drafted
- 已运行 `/balance-check`、发布检查清单已完成，且更新日志或
  补丁说明已有草稿

- No open S1–S3 bugs, the newest `/security-audit` with no open CRITICAL or
  HIGH finding, and a `/localize qa` pass for every locale you ship
- 没有未解决的 S1–S3 缺陷、最新的 `/security-audit` 没有未解决的 CRITICAL 或
  HIGH 级别问题，且所发布的每种 locale 都通过 `/localize qa`

This is the `full` list. `standard` and `minimal` drop items; the gate's own
file, `.claude/skills/gate-check/references/gate-release.md`, has the full
checklist and what each tier drops.
这是 `full` 的清单。`standard` 和 `minimal` 会减少条目；门禁自身的
文件 `.claude/skills/gate-check/references/gate-release.md` 包含完整的
检查清单以及各层级会舍弃的条目。

---

## Phase 7: Release
## 阶段 7：发布

### What Happens in This Phase
### 本阶段会发生什么

Your game is polished, tested, and ready. Now you ship it.
你的游戏已打磨完毕、经过测试并准备就绪。现在将它发布出去。

### Phase 7 Pipeline
### 阶段 7 流水线

```
/launch-checklist  -->  /team-release
        |                      |
        v                      v
  Full cross-department    Coordinate:
  validation (Go/No-Go     build, QA sign-off,
  per department)          deployment, launch

  The release checklist, security audit and patch notes are done in Polish,
  before /gate-check release.   Also: /hotfix, /day-one-patch
```

### Step 7.1: Launch Readiness (Full Validation)
### 步骤 7.1：发布就绪度（全面校验）

```
/launch-checklist
```

Complete cross-department validation:
完整的跨部门校验：

| Department | What Is Checked |
|-----------|---------------|
| 部门 | 检查内容 |
| **Engineering** | Build stability, crash rates, memory leaks, load times |
| **Engineering（工程）** | 构建稳定性、崩溃率、内存泄漏、加载时间 |
| **Design** | Feature completeness, tutorial flow, difficulty curve |
| **Design（设计）** | 功能完整性、新手引导流程、难度曲线 |
| **Art** | Asset quality, missing textures, LOD levels |
| **Art（美术）** | 资产质量、缺失贴图、LOD 级别 |
| **Audio** | Missing sounds, mixing levels, spatial audio |
| **Audio（音频）** | 缺失音效、混音电平、空间音频 |
| **QA** | Open bug count by severity, regression suite pass rate |
| **QA（质量保证）** | 按严重程度统计的未解决缺陷数、回归套件通过率 |
| **Narrative** | Dialogue completeness, lore consistency, typos |
| **Narrative（叙事）** | 对话完整性、设定一致性、错别字 |
| **Localization** | All strings translated, no truncation, locale testing |
| **Localization（本地化）** | 所有字符串已翻译、无截断、locale 测试 |
| **Accessibility** | Compliance checklist, assistive feature testing |
| **Accessibility（无障碍）** | 合规清单、辅助功能测试 |
| **Store** | Metadata complete, screenshots approved, pricing set |
| **Store（商店）** | 元数据完整、截图已批准、定价已设置 |
| **Marketing** | Press kit ready, launch trailer, social media scheduled |
| **Marketing（营销）** | 媒体包就绪、发布预告片、社交媒体已排期 |
| **Community** | Patch notes draft, FAQ prepared, support channels ready |
| **Community（社区）** | 补丁说明草稿、FAQ 已准备、支持渠道就绪 |
| **Infrastructure** | Servers scaled, CDN configured, monitoring active |
| **Infrastructure（基础设施）** | 服务器已扩容、CDN 已配置、监控已启用 |
| **Legal** | EULA finalized, privacy policy, COPPA/GDPR compliance |
| **Legal（法律）** | EULA 已定稿、隐私政策、COPPA/GDPR 合规 |

What no file can settle — the EULA, pricing, the on-call schedule — is asked
once per section: yes, no, not yet or N/A. A "no" or "not yet" is a failed item.
The overall status is READY, CONDITIONAL (only items with a workaround or an
accepted risk remain), NOT ASSESSED (something is still unconfirmed) or NOT
READY (a blocking item failed).
那些任何文件都无法定论的内容 —— EULA、定价、值班安排 ——
会在每个章节问一次：是、否、尚未、或不适用。回答"否"或"尚未"即为未通过项。
总体状态为 READY、CONDITIONAL（仅剩有替代方案或已接受风险的条目）、
NOT ASSESSED（仍有内容未确认）或 NOT
READY（有阻塞项未通过）。

### Step 7.2: Coordinate the Release
### 步骤 7.2：协调发布

```
/team-release
```

Coordinates release-manager, QA, and DevOps through:
通过以下环节协调 release-manager、QA 和 DevOps：

1. Pre-release validation
1. 发布前校验

2. Build management
2. 构建管理

3. Final QA sign-off
3. 最终 QA 签核

4. Deployment preparation
4. 部署准备

5. Go/No-Go decision
5. Go/No-Go 决策

### Step 7.3: Ship
### 步骤 7.3：发布

The `validate-push` hook will warn you when pushing to `main` or a `release/*` branch.
This is intentional -- release pushes should be deliberate:
当你推送到 `main` 或 `release/*` 分支时，`validate-push` 钩子会向你发出警告。
这是有意为之 —— 发布推送应当是有意识地进行的：

```bash
git tag v1.0.0
git push origin main --tags
```

### Step 7.4: Post-Launch
### 步骤 7.4：发布之后

**Hotfix workflow** for critical production bugs:
针对生产环境致命缺陷的**热修复工作流**：

```
/hotfix "Players losing save data when inventory exceeds 99 items"
```

Bypasses normal sprint processes with a full audit trail:
绕过常规冲刺流程，但保留完整的审计轨迹：

1. Creates a hotfix branch
1. 创建热修复分支

2. Implements the fix
2. 实施修复

3. Ensures the fix is backported to `main` (the trunk)
3. 确保修复被回移至 `main`（主干）

4. Documents the incident
4. 记录该事件

**Post-mortem** after launch stabilizes:
在发布稳定后进行**复盘**：

```
Ask Claude to create a post-mortem using the template at
.claude/docs/templates/post-mortem.md
```

---

## Cross-Cutting Concerns
## 横切关注点

These topics apply across all phases.
这些主题适用于所有阶段。

### Director Review Modes
### 总监评审模式

Director gates are specialist agents that review your work at key workflow steps.
**By default none run.** `modes.review_mode` follows `modes.rigor`, and the
default rigor, `rigor: minimal`, gives `solo`.
总监门禁是在关键工作流步骤评审你工作的专家智能体。
**默认情况下一个都不运行。** `modes.review_mode` 跟随 `modes.rigor`，
而默认严格度 `rigor: minimal` 会给出 `solo`。

| Mode | What runs | The default under | Best for |
|------|-----------|-------------------|----------|
| 模式 | 运行内容 | 默认所属层级 | 最适合 |
| `full` | All director gates at every step | `rigor: full` | Studio-scale projects, learning the system |
| `full` | 每一步都运行所有总监门禁 | `rigor: full` | 工作室级项目、学习该系统 |
| `lean` | Directors only at phase transitions (`/gate-check`) | `rigor: standard` | Experienced devs |
| `lean` | 仅在阶段转换时启用总监（`/gate-check`） | `rigor: standard` | 有经验的开发者 |
| `solo` | No director reviews | `rigor: minimal` | Solo projects, game jams, prototypes |
| `solo` | 无总监评审 | `rigor: minimal` | 个人项目、Game Jam、原型 |

**Change it** with `/settings modes.review_mode=lean` (written to `project.yaml`;
an explicit value wins over rigor), or `/settings --local modes.review_mode=full`
for your machine only. `/start` does not set it.
**更改它**：使用 `/settings modes.review_mode=lean`（写入 `project.yaml`；
显式值优先于严格度），或 `/settings --local modes.review_mode=full`
仅对你的机器生效。`/start` 不会设置它。

**Override for a single run** without changing your setting:
**单次运行临时覆盖**，而不更改你的设置：

```
/brainstorm space horror --review full
/architecture-decision --review solo
```

The `--review` flag works on all gate-using skills. The first of these that is
set wins: the flag, `project.local.yaml`, `project.yaml`, a legacy
`production/review-mode.txt`, then the rigor default. A `review-mode.txt` left
from an older version still overrides rigor — delete it if the mode surprises you.
`--review` 标志对所有使用门禁的技能都有效。以下设置中第一个被设置的生效：
该标志、`project.local.yaml`、`project.yaml`、遗留的
`production/review-mode.txt`，最后是严格度默认值。从旧版本遗留的
`review-mode.txt` 仍会覆盖严格度 —— 如果模式出乎你的意料，就删除它。

Full gate definitions and check pattern: `.claude/docs/director-gates.md`
完整的门禁定义和检查模式：`.claude/docs/director-gates.md`

---

### The Collaboration Protocol
### 协作协议

This system is **user-driven collaborative**, not autonomous.
该系统是**用户驱动的协作式**，而非自主式。

**Pattern:** Question > Options > Decision > Draft > Approval
**模式：** 提问 > 选项 > 决策 > 草稿 > 批准

Every agent interaction follows this pattern:
每一次智能体交互都遵循此模式：

1. Agent asks clarifying questions
1. 智能体提出澄清问题

2. Agent presents 2-4 options with trade-offs and reasoning
2. 智能体给出 2-4 个选项，附权衡和推理

3. You decide
3. 你做出决策

4. Agent drafts based on your decision
4. 智能体基于你的决策起草

5. You review and refine
5. 你评审并细化

6. Agent asks "May I write this to [filepath]?" before writing
6. 智能体在写入前询问"我可以将此写入 [filepath] 吗？"

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for the full protocol with
examples.
完整协议与示例参见 `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`。

### The AskUserQuestion Tool
### AskUserQuestion 工具

Agents use the `AskUserQuestion` tool for structured option presentation.
The pattern is Explain then Capture: full analysis in conversation text first,
then a clean UI picker for the decision. Use it for design choices,
architecture decisions, and strategic questions. Do not use it for open-ended
discovery questions or simple yes/no confirmations.
智能体使用 `AskUserQuestion` 工具以结构化方式呈现选项。
模式是"先解释、再采集"：先在对话文本中给出完整分析，
再用清爽的 UI 选择器来采集决策。用于设计选择、
架构决策和战略性问题。不要用于开放式
探索问题或简单的是/否确认。

### Agent Coordination (3-Tier Hierarchy)
### 智能体协作（三层级体系）

```
Tier 1 (Directors):    creative-director, technical-director, producer
                                          |
Tier 2 (Leads):        game-designer, lead-programmer, art-director,
                       audio-director, narrative-director, qa-lead,
                       release-manager, localization-lead
                                          |
Tier 3 (Specialists):  gameplay-programmer, engine-programmer,
                       ai-programmer, network-programmer, ui-programmer,
                       tools-programmer, systems-designer, level-designer,
                       economy-designer, world-builder, writer,
                       technical-artist, sound-designer, ux-designer,
                       qa-tester, performance-analyst, devops-engineer,
                       analytics-engineer, accessibility-specialist,
                       live-ops-designer, prototyper, security-engineer,
                       community-manager, godot-specialist,
                       godot-gdscript-specialist, godot-shader-specialist,
                       godot-csharp-specialist, godot-gdextension-specialist,
                       unity-specialist, unity-dots-specialist,
                       unity-shader-specialist, unity-addressables-specialist,
                       unity-ui-specialist, unreal-specialist,
                       ue-blueprint-specialist, ue-gas-specialist,
                       ue-replication-specialist, ue-umg-specialist
```

**Coordination rules:**
**协作规则：**

- Vertical delegation: Directors > Leads > Specialists. Never skip tiers for
  complex decisions.
- 垂直委派：总监 > 主管 > 专家。对于复杂决策，切勿跳过层级。

- Horizontal consultation: Agents at the same tier may consult each other but
  must not make binding decisions outside their domain.
- 横向协商：同层级智能体可以相互协商，但
  不得在其领域之外做出有约束力的决策。

- Conflict resolution: Design conflicts go to `creative-director`. Technical
  conflicts go to `technical-director`. Scope conflicts go to `producer`.
- 冲突解决：设计冲突交给 `creative-director`。技术
  冲突交给 `technical-director`。范围冲突交给 `producer`。

- No unilateral cross-domain changes.
- 不做单方面的跨领域变更。

### Automated Hooks (Safety Net)
### 自动化钩子（安全网）

The system has 15 hooks that run automatically:
该系统有 15 个自动运行的钩子：

| Hook | Trigger | What It Does |
|------|---------|-------------|
| 钩子 | 触发时机 | 作用 |
| `session-start.sh` | Session start | Shows branch, recent commits, detects active.md for recovery |
| `session-start.sh` | 会话开始 | 显示分支、最近提交，检测 active.md 以便恢复 |
| `detect-gaps.sh` | Session start | Detects fresh projects (no engine, no concept) and suggests `/start` |
| `detect-gaps.sh` | 会话开始 | 检测全新项目（无引擎、无概念）并建议运行 `/start` |
| `pre-compact.sh` | Before compaction | Logs the compaction (its output does not reach Claude) |
| `pre-compact.sh` | 压缩之前 | 记录压缩操作（其输出不会到达 Claude） |
| `notify.sh` | Permission prompt, or idle about a minute | Shows Windows toast notification via PowerShell |
| `notify.sh` | 权限提示，或空闲约一分钟 | 通过 PowerShell 显示 Windows 通知 |
| `validate-commit.sh` | Before commit | Checks design doc sections, valid JSON, hardcoded values, TODO format |
| `validate-commit.sh` | 提交之前 | 检查设计文档章节、JSON 有效性、硬编码数值、TODO 格式 |
| `validate-push.sh` | Before push, tag, merge or deploy | Warns on pushes to main, master or release/*, and on `git tag`, `git merge`, `gh release`, `butler push` and `steamcmd +run_app_build` |
| `validate-push.sh` | 推送、打标签、合并或部署之前 | 对推送到 main、master 或 release/*，以及 `git tag`、`git merge`、`gh release`、`butler push` 和 `steamcmd +run_app_build` 发出警告 |
| `validate-read.sh` | Before a file read | Refuses a whole-file read of a design doc over 40 KB and answers with its headings |
| `validate-read.sh` | 读取文件之前 | 拒绝对超过 40 KB 的设计文档进行整文件读取，并以标题作答 |
| `validate-write.sh` | Before a file write | Warns when a write would break a rule the skills state (never blocks) |
| `validate-write.sh` | 写入文件之前 | 当写入会违反技能声明的规则时发出警告（从不阻塞） |
| `validate-registry.sh` | Before an entity or TR-ID registry write | Warns when an entry would be deleted or renumbered, or a status is not in the header's list |
| `validate-registry.sh` | 写入实体或 TR-ID 注册表之前 | 当条目将被删除或重新编号，或状态不在头部列表中时发出警告 |
| `validate-assets.sh` | After a file write | Checks data-file JSON, and asset naming in Godot's `assets/` |
| `validate-assets.sh` | 写入文件之后 | 检查数据文件 JSON，以及 Godot `assets/` 中的资产命名 |
| `validate-skill-change.sh` | Skill file written | Advises running `/skill-test` after `.claude/skills/` changes |
| `validate-skill-change.sh` | 写入技能文件 | 建议在 `.claude/skills/` 变更后运行 `/skill-test` |
| `log-agent.sh` | Agent start | Logs agent invocations for audit trail |
| `log-agent.sh` | 智能体启动 | 记录智能体调用，用于审计轨迹 |
| `log-agent-stop.sh` | Agent stop | Completes agent audit trail (start + stop) |
| `log-agent-stop.sh` | 智能体停止 | 补全智能体审计轨迹（启动 + 停止） |
| `validate-agent-artifact.sh` | Agent stop | Warns when a subagent stops without writing the file its brief named |
| `validate-agent-artifact.sh` | 智能体停止 | 当子智能体停止而未写入其任务简报所指文件时发出警告 |
| `session-stop.sh` | **Every response ends** | Session logging and the subagent spawn tally, in the background. Despite the name it fires once per response, not once per session. |
| `session-stop.sh` | **每次响应结束时** | 在后台进行会话日志记录和子智能体派生统计。尽管名称如此，它是每次响应触发一次，而不是每个会话触发一次。 |

### Context Resilience
### 上下文韧性

**Session state file:** `production/session-state/active.md` is a living
checkpoint. Update it after each significant milestone. After any disruption
(compaction, crash, `/clear`), read this file first.
**会话状态文件：** `production/session-state/active.md` 是一个活
检查点。在每个重要里程碑之后更新它。在任何中断
（压缩、崩溃、`/clear`）之后，先读取此文件。

**Incremental writing:** When creating multi-section documents, write each
section to file immediately after approval. This means completed sections
survive crashes and context compactions. Previous discussion about written
sections can be safely compacted.
**增量式写入：** 创建多章节文档时，每章节在获得批准后立即
写入文件。这意味着已完成的章节能在崩溃和上下文压缩后
存活。关于已写入章节的先前讨论可以安全地压缩掉。

**Automatic recovery:** The `session-start.sh` hook detects and previews
`active.md` automatically, and runs again after every compaction, so the
checkpoint comes back when the conversation is summarised.
**自动恢复：** `session-start.sh` 钩子会自动检测并预览
`active.md`，并在每次压缩后再次运行，因此当对话被摘要时
检查点会被重新带回。

**Sprint status tracking:** `production/sprint-status.yaml` is the
machine-readable story tracker. Written by `/sprint-plan` (init) and
`/story-done` (status updates). Read by `/sprint-status`, `/help`, and
`/story-done` (next story). Eliminates fragile markdown scanning.
**冲刺状态跟踪：** `production/sprint-status.yaml` 是
机器可读的故事跟踪文件。由 `/sprint-plan`（初始化）和
`/story-done`（状态更新）写入。由 `/sprint-status`、`/help` 和
`/story-done`（下一个故事）读取。省去了脆弱的 markdown 扫描。

### Brownfield Adoption
### 棕地项目采用

For existing projects that already have some artifacts:
对于已经拥有部分已有产物的项目：

```
/adopt
```

Or targeted:
或针对性采用：

```
/adopt gdds
/adopt adrs
/adopt stories
/adopt infra
```

This audits existing artifacts for **format** (not existence), classifies gaps
as BLOCKING/HIGH/MEDIUM/LOW, builds an ordered migration plan, and writes
`docs/adoption-plan-[date].md`. Core principle: MIGRATION not REPLACEMENT --
it never regenerates existing work, only fills gaps.
这会审计已有产物的**格式**（而不只是是否存在）、将缺口
分类为 BLOCKING/HIGH/MEDIUM/LOW、构建有序的迁移计划，并写入
`docs/adoption-plan-[date].md`。核心原则：迁移而非替换 ——
它绝不重新生成已有工作，只填补缺口。

Individual skills also support retrofit mode:
个别技能也支持改造模式：

```
/design-system retrofit design/gdd/combat-system.md
/architecture-decision retrofit docs/architecture/adr-005.md
```

These detect which sections are present vs. missing and fill only the gaps.
这些会检测哪些章节已存在、哪些缺失，并只填补缺口。

### Gate System
### 门禁系统

Phase gates are formal checkpoints. Run `/gate-check` with the phase you are
entering:
阶段门禁是正式检查点。以你即将进入的阶段来运行 `/gate-check`：

```
/gate-check systems-design       # Concept -> Systems Design
/gate-check technical-setup      # Systems Design -> Technical Setup
/gate-check pre-production       # Technical Setup -> Pre-Production
/gate-check production           # Pre-Production -> Production
/gate-check polish               # Production -> Polish
/gate-check release              # Polish -> Release
```

**Verdicts:**
**结论：**

- **PASS** -- all requirements met, advance to next phase
- **PASS** —— 所有要求均已满足，进入下一阶段

- **CONCERNS** -- risks found; the stage advances only if you explicitly accept
  them, and the accepted risks are recorded
- **CONCERNS** —— 发现了风险；只有当显式接受这些风险时阶段才会推进，
  且已接受的风险会被记录

- **NOT ASSESSED** -- something required could not be checked; the report names
  it, so supply it and re-run
- **NOT ASSESSED** —— 某项必需内容无法检查；报告会指出它，
  请补齐后重新运行

- **FAIL** -- requirements not met, blocks advancement with specific remediation
- **FAIL** —— 要求未满足，会以具体的整改项阻塞推进

When a gate passes — or you accept a CONCERNS verdict's risks — `project.stage`
in `project.yaml` is updated (only then; a FAIL never advances it) — mirrored to
`production/stage.txt`. At `standard` and `full` the stage drives
the status line and `/help`; at `minimal` they follow the brief and stories
instead.
当门禁通过 —— 或你接受 CONCERNS 结论中的风险 —— `project.yaml` 中的
`project.stage` 会被更新（只有此时；FAIL 永不推进）—— 并同步到
`production/stage.txt`。在 `standard` 和 `full` 下，阶段驱动
状态行和 `/help`；在 `minimal` 下，它们改为依据简报和故事。

### Reverse Documentation
### 逆向文档化

For code that exists without design docs (common after brownfield adoption):
对于已有代码但缺少设计文档的情况（棕地采用后很常见）：

```
/reverse-document design src/gameplay/combat/
```

Reads existing code and generates GDD-format design documentation from it.
读取现有代码并据此生成 GDD 格式的设计文档。

---

## Appendix A: Agent Quick-Reference
## 附录 A：智能体快速参考

### "I need to do X -- which agent do I use?"
### "我要做 X —— 该用哪个智能体？"

| I need to... | Agent | Tier |
|-------------|-------|------|
| 我需要…… | 智能体 | 层级 |
| Come up with a game idea | `/brainstorm` skill | -- |
| 想出一个游戏创意 | `/brainstorm` 技能 | -- |
| Design a game mechanic | `game-designer` | 2 |
| 设计一个游戏机制 | `game-designer` | 2 |
| Design specific formulas/numbers | `systems-designer` | 3 |
| 设计具体的公式/数值 | `systems-designer` | 3 |
| Design a game level | `level-designer` | 3 |
| 设计一个游戏关卡 | `level-designer` | 3 |
| Design loot tables / economy | `economy-designer` | 3 |
| 设计掉落表/经济系统 | `economy-designer` | 3 |
| Build world lore | `world-builder` | 3 |
| 构建世界设定 | `world-builder` | 3 |
| Write dialogue | `writer` | 3 |
| 撰写对话 | `writer` | 3 |
| Plan the story | `narrative-director` | 2 |
| 规划故事 | `narrative-director` | 2 |
| Plan a sprint | `producer` | 1 |
| 规划冲刺 | `producer` | 1 |
| Make a creative decision | `creative-director` | 1 |
| 做出创意决策 | `creative-director` | 1 |
| Make a technical decision | `technical-director` | 1 |
| 做出技术决策 | `technical-director` | 1 |
| Implement gameplay code | `gameplay-programmer` | 3 |
| 实现游戏玩法代码 | `gameplay-programmer` | 3 |
| Implement core engine systems | `engine-programmer` | 3 |
| 实现核心引擎系统 | `engine-programmer` | 3 |
| Implement AI behavior | `ai-programmer` | 3 |
| 实现 AI 行为 | `ai-programmer` | 3 |
| Implement multiplayer | `network-programmer` | 3 |
| 实现多人联机 | `network-programmer` | 3 |
| Implement UI | `ui-programmer` | 3 |
| 实现 UI | `ui-programmer` | 3 |
| Build dev tools | `tools-programmer` | 3 |
| 构建开发工具 | `tools-programmer` | 3 |
| Review code architecture | `lead-programmer` | 2 |
| 评审代码架构 | `lead-programmer` | 2 |
| Create shaders / VFX | `technical-artist` | 3 |
| 制作着色器/特效 | `technical-artist` | 3 |
| Define visual style | `art-director` | 2 |
| 定义视觉风格 | `art-director` | 2 |
| Define audio style | `audio-director` | 2 |
| 定义音频风格 | `audio-director` | 2 |
| Design sound effects | `sound-designer` | 3 |
| 设计音效 | `sound-designer` | 3 |
| Design UX flows | `ux-designer` | 3 |
| 设计 UX 流程 | `ux-designer` | 3 |
| Write test cases | `qa-tester` | 3 |
| 编写测试用例 | `qa-tester` | 3 |
| Plan test strategy | `qa-lead` | 2 |
| 规划测试策略 | `qa-lead` | 2 |
| Profile performance | `performance-analyst` | 3 |
| 剖析性能 | `performance-analyst` | 3 |
| Set up CI/CD | `devops-engineer` | 3 |
| 搭建 CI/CD | `devops-engineer` | 3 |
| Design analytics | `analytics-engineer` | 3 |
| 设计分析统计 | `analytics-engineer` | 3 |
| Check accessibility | `accessibility-specialist` | 3 |
| 检查无障碍 | `accessibility-specialist` | 3 |
| Plan live operations | `live-ops-designer` | 3 |
| 规划线上运营 | `live-ops-designer` | 3 |
| Manage a release | `release-manager` | 2 |
| 管理一次发布 | `release-manager` | 2 |
| Manage localization | `localization-lead` | 2 |
| 管理本地化 | `localization-lead` | 2 |
| Prototype quickly | `prototyper` | 3 |
| 快速制作原型 | `prototyper` | 3 |
| Audit security | `security-engineer` | 3 |
| 审计安全 | `security-engineer` | 3 |
| Communicate with players | `community-manager` | 3 |
| 与玩家沟通 | `community-manager` | 3 |
| Godot-specific help | `godot-specialist` | 3 |
| Godot 专项帮助 | `godot-specialist` | 3 |
| GDScript-specific help | `godot-gdscript-specialist` | 3 |
| GDScript 专项帮助 | `godot-gdscript-specialist` | 3 |
| Godot shader help | `godot-shader-specialist` | 3 |
| Godot 着色器帮助 | `godot-shader-specialist` | 3 |
| GDExtension modules | `godot-gdextension-specialist` | 3 |
| GDExtension 模块 | `godot-gdextension-specialist` | 3 |
| Unity-specific help | `unity-specialist` | 3 |
| Unity 专项帮助 | `unity-specialist` | 3 |
| Unity DOTS/ECS | `unity-dots-specialist` | 3 |
| Unity DOTS/ECS | `unity-dots-specialist` | 3 |
| Unity shaders/VFX | `unity-shader-specialist` | 3 |
| Unity 着色器/特效 | `unity-shader-specialist` | 3 |
| Unity Addressables | `unity-addressables-specialist` | 3 |
| Unity Addressables | `unity-addressables-specialist` | 3 |
| Unity UI Toolkit | `unity-ui-specialist` | 3 |
| Unity UI Toolkit | `unity-ui-specialist` | 3 |
| Unreal-specific help | `unreal-specialist` | 3 |
| Unreal 专项帮助 | `unreal-specialist` | 3 |
| Unreal GAS | `ue-gas-specialist` | 3 |
| Unreal GAS | `ue-gas-specialist` | 3 |
| Unreal Blueprints | `ue-blueprint-specialist` | 3 |
| Unreal 蓝图 | `ue-blueprint-specialist` | 3 |
| Unreal replication | `ue-replication-specialist` | 3 |
| Unreal 复制 | `ue-replication-specialist` | 3 |
| Unreal UMG/CommonUI | `ue-umg-specialist` | 3 |
| Unreal UMG/CommonUI | `ue-umg-specialist` | 3 |

### Agent Hierarchy
### 智能体层级

```
                    creative-director / technical-director / producer
                                         |
          ---------------------------------------------------------------
          |            |           |           |          |        |       |
    game-designer  lead-prog  art-dir  audio-dir  narr-dir  qa-lead  release-mgr
          |            |           |           |          |        |        |
     specialists  programmers  tech-art  snd-design  writer   qa-tester  devops
     (systems,    (gameplay,             (sound)     (world-  (perf,     (analytics,
      economy,     engine,                           builder)  access.)   security)
      level)       ai, net,
                   ui, tools)
```

**Escalation rule:** If two agents disagree, go up. Design conflicts go to
`creative-director`. Technical conflicts go to `technical-director`. Scope
conflicts go to `producer`.
**升级规则：** 如果两个智能体意见不一致，就向上走。设计冲突交给
`creative-director`。技术冲突交给 `technical-director`。范围
冲突交给 `producer`。

---

## Appendix B: Slash Command Quick-Reference
## 附录 B：斜杠命令快速参考

### All 74 Commands by Category
### 全部 74 个命令（按类别）

#### Onboarding and Navigation (7)
#### 入门与导航（7）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/start` | Guided onboarding, routes to right workflow | Any (first session) |
| `/start` | 引导式入门，路由到正确的工作流 | 任意（首次会话） |
| `/help` | Context-aware "what do I do next?" | Any |
| `/help` | 感知上下文的"我下一步做什么？" | 任意 |
| `/project-stage-detect` | Full project audit to determine current phase | Any |
| `/project-stage-detect` | 全面项目审计以确定当前阶段 | 任意 |
| `/setup-engine` | Configure engine, pin version, set preferences | 1 |
| `/setup-engine` | 配置引擎、锁定版本、设置偏好 | 1 |
| `/adopt` | Brownfield audit and migration plan | Any (existing projects) |
| `/adopt` | 棕地审计与迁移计划 | 任意（已有项目） |
| `/settings` | View or change project config (rigor, review mode, ...) | Any |
| `/settings` | 查看或更改项目配置（严格度、评审模式等） | 任意 |
| `/skill-improve` | Improve a skill via test-fix-retest loop | Any |
| `/skill-improve` | 通过"测试-修复-重测"循环改进技能 | 任意 |

#### Game Design (6)
#### 游戏设计（6）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/brainstorm` | Collaborative ideation with MDA analysis | 1 |
| `/brainstorm` | 带 MDA 分析的协作式创意构思 | 1 |
| `/map-systems` | Decompose concept into systems index | 1-2 |
| `/map-systems` | 将概念分解为系统索引 | 1-2 |
| `/design-system` | Guided section-by-section GDD authoring | 2 |
| `/design-system` | 引导式逐章节撰写 GDD | 2 |
| `/quick-design` | Lightweight spec for small changes | 2+ |
| `/quick-design` | 针对小改动的轻量级规格 | 2+ |
| `/review-all-gdds` | Cross-GDD consistency and design theory review | 2 |
| `/review-all-gdds` | 跨 GDD 一致性与设计理论评审 | 2 |
| `/propagate-design-change` | Find ADRs/stories affected by GDD changes | 5 |
| `/propagate-design-change` | 找出受 GDD 变更影响的 ADR/故事 | 5 |

#### UX and Interface (2)
#### UX 与界面（2）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/ux-design` | Author UX specs (screen/flow, HUD, patterns) | 3-4 |
| `/ux-design` | 编写 UX 规格（界面/流程、HUD、模式） | 3-4 |
| `/ux-review` | Validate UX specs for accessibility and GDD alignment | 4 |
| `/ux-review` | 校验 UX 规格的无障碍性与 GDD 对齐 | 4 |

#### Architecture (4)
#### 架构（4）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/create-architecture` | Master architecture document | 3 |
| `/create-architecture` | 主架构文档 | 3 |
| `/architecture-decision` | Create or retrofit an ADR | 3 |
| `/architecture-decision` | 创建或改造 ADR | 3 |
| `/architecture-review` | Validate all ADRs, dependency ordering | 3 |
| `/architecture-review` | 校验所有 ADR 与依赖排序 | 3 |
| `/create-control-manifest` | Flat programmer rules from Accepted ADRs | 3 |
| `/create-control-manifest` | 从 Accepted 的 ADR 生成扁平的程序员规则 | 3 |

#### Stories and Sprints (8)
#### 故事与冲刺（8）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/create-epics` | Translate GDDs + ADRs into epics (one per module) | 4 |
| `/create-epics` | 将 GDD + ADR 转化为史诗（每个模块一个） | 4 |
| `/create-stories` | Break a single epic into story files | 4 |
| `/create-stories` | 将单个史诗拆分为故事文件 | 4 |
| `/dev-story` | Implement a story — routes to the correct programmer agent | 5 |
| `/dev-story` | 实施一个故事 —— 路由到正确的程序员智能体 | 5 |
| `/sprint-plan` | Create or manage sprint plans | 4-5 |
| `/sprint-plan` | 创建或管理冲刺计划 | 4-5 |
| `/sprint-status` | Quick 30-line sprint snapshot | 5 |
| `/sprint-status` | 30 行快速冲刺快照 | 5 |
| `/story-readiness` | Validate story is implementation-ready | 4-5 |
| `/story-readiness` | 校验故事是否可实施 | 4-5 |
| `/story-done` | 8-phase story completion review | 5 |
| `/story-done` | 8 阶段的故事完成评审 | 5 |
| `/estimate` | Effort estimation with risk assessment | 4-5 |
| `/estimate` | 带风险评估的工作量估算 | 4-5 |

#### Reviews and Analysis (13)
#### 评审与分析（13）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/design-review` | Validate GDD against 8-section standard | 1-2 |
| `/design-review` | 按 8 章节标准校验 GDD | 1-2 |
| `/code-review` | Architectural code review | 5+ |
| `/code-review` | 架构层面的代码评审 | 5+ |
| `/balance-check` | Game balance formula analysis | 5-6 |
| `/balance-check` | 游戏平衡公式分析 | 5-6 |
| `/asset-audit` | Asset naming, format, size verification | 6 |
| `/asset-audit` | 资产命名、格式、体积校验 | 6 |
| `/asset-spec` | Per-asset visual specs and AI generation prompts | 5-6 |
| `/asset-spec` | 逐资产的视觉规格与 AI 生成提示词 | 5-6 |
| `/content-audit` | GDD-specified content vs. implemented | 5 |
| `/content-audit` | GDD 规定内容与已实现内容的对比 | 5 |
| `/consistency-check` | Cross-GDD entity and formula inconsistency scan | 2+ |
| `/consistency-check` | 跨 GDD 实体与公式不一致性扫描 | 2+ |
| `/scope-check` | Scope creep detection | 5 |
| `/scope-check` | 范围蔓延检测 | 5 |
| `/perf-profile` | Performance profiling workflow | 6 |
| `/perf-profile` | 性能剖析工作流 | 6 |
| `/tech-debt` | Tech debt scanning and prioritization | 6 |
| `/tech-debt` | 技术债扫描与优先级排序 | 6 |
| `/gate-check` | Formal phase gate with PASS/CONCERNS/NOT ASSESSED/FAIL | All transitions |
| `/gate-check` | 正式阶段门禁，结论为 PASS/CONCERNS/NOT ASSESSED/FAIL | 所有阶段转换 |
| `/reverse-document` | Generate design docs from existing code | Any |
| `/reverse-document` | 从现有代码生成设计文档 | 任意 |
| `/security-audit` | Security vulnerability audit (save, network, input) | 6 |
| `/security-audit` | 安全漏洞审计（存档、网络、输入） | 6 |

#### QA and Testing (9)
#### QA 与测试（9）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/qa-plan` | Generate QA test plan for a sprint or feature | 5 |
| `/qa-plan` | 为冲刺或功能生成 QA 测试计划 | 5 |
| `/smoke-check` | Critical path smoke test gate before QA hand-off | 5-6 |
| `/smoke-check` | QA 交接前的关键路径冒烟测试门禁 | 5-6 |
| `/soak-test` | Soak test protocol for extended play sessions | 6 |
| `/soak-test` | 面向长时间游玩会话的浸泡测试协议 | 6 |
| `/regression-suite` | Map test coverage, identify fixed bugs lacking regression tests | 5-6 |
| `/regression-suite` | 梳理测试覆盖，找出缺少回归测试的已修缺陷 | 5-6 |
| `/test-setup` | Scaffold test framework and CI/CD pipeline | 3 |
| `/test-setup` | 搭建测试框架与 CI/CD 流水线 | 3 |
| `/test-helpers` | Generate engine-specific test helper libraries | 3-5 |
| `/test-helpers` | 生成引擎特定的测试辅助库 | 3-5 |
| `/test-evidence-review` | Quality review of test files and manual evidence | 5 |
| `/test-evidence-review` | 评审测试文件与手动证据的质量 | 5 |
| `/test-flakiness` | Detect non-deterministic tests from CI logs | 5-6 |
| `/test-flakiness` | 从 CI 日志中检测非确定性测试 | 5-6 |
| `/skill-test` | Validate skill files for structural and behavioral correctness | Any |
| `/skill-test` | 校验技能文件的结构与行为正确性 | 任意 |

#### Production Management (6)
#### 制作管理（6）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/milestone-review` | Milestone progress and go/no-go | 5 |
| `/milestone-review` | 里程碑进度与 go/no-go 决策 | 5 |
| `/retrospective` | Sprint retrospective analysis | 5 |
| `/retrospective` | 冲刺回顾分析 | 5 |
| `/bug-report` | Structured bug report creation | 5+ |
| `/bug-report` | 创建结构化的缺陷报告 | 5+ |
| `/bug-triage` | Re-evaluate open bugs for priority, severity, and owner | 5+ |
| `/bug-triage` | 重新评估未解决缺陷的优先级、严重程度和负责人 | 5+ |
| `/playtest-report` | Structured playtest session report | 4-6 |
| `/playtest-report` | 结构化的试玩会话报告 | 4-6 |
| `/onboard` | Onboard a new team member | Any |
| `/onboard` | 让新团队成员快速上手 | 任意 |

#### Release (6)
#### 发布（6）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/release-checklist` | Pre-release validation | 6 |
| `/release-checklist` | 发布前校验 | 6 |
| `/launch-checklist` | Full cross-department launch readiness | 7 |
| `/launch-checklist` | 完整的跨部门发布就绪度检查 | 7 |
| `/changelog` | Auto-generate internal changelog | 6 |
| `/changelog` | 自动生成内部更新日志 | 6 |
| `/patch-notes` | Player-facing patch notes | 6 |
| `/patch-notes` | 面向玩家的补丁说明 | 6 |
| `/hotfix` | Emergency fix workflow | 7+ |
| `/hotfix` | 紧急修复工作流 | 7+ |
| `/day-one-patch` | Scoped patch for issues found after gold master | 7+ |
| `/day-one-patch` | 针对压盘母版之后发现问题的限定范围补丁 | 7+ |

#### Creative (4)
#### 创意（4）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/prototype` | Concept prototype — validate core idea before GDDs | 1 |
| `/prototype` | 概念原型 —— 在写 GDD 之前验证核心想法 | 1 |
| `/art-bible` | Guided Art Bible authoring — visual identity spec | 1-4 |
| `/art-bible` | 引导式撰写美术圣经 —— 视觉识别规范 | 1-4 |
| `/vertical-slice` | Production-quality end-to-end build before Production | 4 |
| `/vertical-slice` | 在进入制作前构建制作级质量的端到端版本 | 4 |
| `/localize` | String extraction and validation | 6-7 |
| `/localize` | 字符串提取与校验 | 6-7 |

#### Team Orchestration (9)
#### 团队编排（9）

| Command | Purpose | Phase |
|---------|---------|-------|
| 命令 | 用途 | 阶段 |
| `/team-combat` | Combat feature: design through implementation | 5 |
| `/team-combat` | 战斗功能：从设计到实施 | 5 |
| `/team-narrative` | Narrative content: structure through dialogue | 5 |
| `/team-narrative` | 叙事内容：从结构到对话 | 5 |
| `/team-ui` | UI feature: UX spec through polished implementation | 5 |
| `/team-ui` | UI 功能：从 UX 规格到打磨后的实现 | 5 |
| `/team-level` | Level: layout through dressed encounters | 5 |
| `/team-level` | 关卡：从布局到完成布景的遭遇战 | 5 |
| `/team-audio` | Audio: direction through implemented events | 5-6 |
| `/team-audio` | 音频：从方向到已实现的事件 | 5-6 |
| `/team-polish` | Coordinated polish: perf + art + audio + QA | 6 |
| `/team-polish` | 协同打磨：性能 + 美术 + 音频 + QA | 6 |
| `/team-release` | Release coordination: build + QA + deployment | 7 |
| `/team-release` | 发布协调：构建 + QA + 部署 | 7 |
| `/team-live-ops` | Live-ops planning: seasonal events, battle pass, retention | 7+ |
| `/team-live-ops` | 线上运营规划：赛季活动、战斗通行证、留存 | 7+ |
| `/team-qa` | Full QA cycle: strategy, execution, coverage, sign-off | 6-7 |
| `/team-qa` | 完整 QA 循环：策略、执行、覆盖、签核 | 6-7 |

---

## Appendix C: Common Workflows
## 附录 C：常用工作流

### Workflow 1: "I just started and have no game idea"
### 工作流 1："我刚刚开始，还没有游戏创意"

```
1. /start (routes you based on where you are)
2. /brainstorm (collaborative ideation, pick a concept)
3. /setup-engine (pin engine and version)
4. /design-review on concept doc (optional, recommended)
5. /map-systems (decompose concept into systems with deps and priorities)
6. /gate-check systems-design (verify you're ready for Systems Design)
7. /design-system per system (guided GDD authoring)
```

### Workflow 2: "I have designs and want to start coding"
### 工作流 2："我已有设计，想开始写代码"

```
1. /design-review on each GDD (make sure they're solid)
2. /review-all-gdds (cross-GDD consistency)
3. /gate-check technical-setup
4. /create-architecture + /architecture-decision (per major decision)
5. /architecture-review
6. /create-control-manifest
7. /art-bible (sections 1–4 now) + /test-setup + /ux-design accessibility + /ux-design patterns
8. /gate-check pre-production
9. /ux-design per key screen + /ux-review
10. /vertical-slice (recommended before committing to epics)
11. /create-epics layer: foundation + /create-stories [slug] (define epics, break into stories)
12. /sprint-plan new
13. /gate-check production
14. /story-readiness -> implement -> /story-done (story lifecycle)
```

### Workflow 3: "I need to add a complex feature mid-production"
### 工作流 3："我需要在制作中期加入一个复杂功能"

```
1. /design-system or /quick-design (depending on scope)
2. /design-review to validate
3. /propagate-design-change if modifying existing GDDs
4. /estimate for effort and risk
5. /team-combat, /team-narrative, /team-ui, etc. (appropriate team skill)
6. /story-done when complete
7. /balance-check if it affects game balance
```

### Workflow 4: "Something broke in production"
### 工作流 4："生产环境出了问题"

```
1. /hotfix "description of the issue"
2. Fix is implemented on hotfix branch
3. /code-review the fix
4. Run tests
5. /release-checklist for hotfix build
6. Deploy and backport
```

### Workflow 5: "I have an existing project and want to use this system"
### 工作流 5："我有一个已有项目，想使用这套系统"

```
1. /start (choose Path D -- existing work)
2. /project-stage-detect (determines current phase)
3. /adopt (audits existing artifacts, builds migration plan)
4. /design-system retrofit [path] (fill GDD gaps)
5. /architecture-decision retrofit [path] (fill ADR gaps)
6. /gate-check at appropriate transition
```

### Workflow 6: "Starting a new sprint"
### 工作流 6："开始一个新冲刺"

```
1. /retrospective (review last sprint)
2. /sprint-plan new (create next sprint)
3. /scope-check (ensure scope is manageable)
4. /story-readiness per story before pickup
5. Implement stories
6. /story-done per completed story
7. /sprint-status for quick progress checks
```

### Workflow 7: "Shipping the game"
### 工作流 7："发布游戏"

```
1. /tech-debt (decide what's acceptable at launch)
2. /security-audit (the release gate reads the newest report)
3. /localize qa for every language you ship
4. /release-checklist all
5. /changelog and /patch-notes (drafts; /team-release finalizes them)
6. /gate-check release (verify Polish is complete and the game is ready to release)
7. /launch-checklist (full cross-department validation)
8. /team-release (coordinate the release)
9. Ship!
10. /hotfix if anything breaks post-launch
11. Post-mortem after launch stabilizes
```

### Workflow 8: "I'm lost / don't know what to do next"
### 工作流 8："我迷路了 / 不知道下一步做什么"

```
1. /help (reads your phase, checks artifacts, tells you what's next)
2. If /help doesn't help: /project-stage-detect (full audit)
3. If stage seems wrong: /gate-check at the transition you think you're at
```

---

## Tips for Getting the Most Out of the System
## 充分利用这套系统的建议

1. **Always start with design, then implement.** The agent system is built
   around the assumption that a design document exists before code is written.
   Agents reference GDDs constantly.
1. **始终先设计，再实现。** 该智能体系统建立在这样一个前提之上：
   写代码之前先有设计文档。
   智能体会不断引用 GDD。

2. **Use team skills for cross-cutting features.** Do not try to manually
   coordinate 4 agents yourself -- let `/team-combat`, `/team-narrative`,
   etc. handle the orchestration.
2. **横跨多个领域的功能使用团队技能。** 不要试图自己手动
   协调 4 个智能体 —— 交给 `/team-combat`、`/team-narrative`
   等来处理编排。

3. **Trust the rules system.** When a rule flags something in your code, fix
   it. The rules encode hard-won game development wisdom (data-driven values,
   delta time, accessibility, etc.).
3. **信任规则系统。** 当规则在你的代码中标出问题时，就修复它。
   这些规则凝聚了来之不易的游戏开发经验（数据驱动数值、
   增量时间、无障碍等）。

4. **Compact proactively.** At ~65-70% context usage, compact or `/clear`.
   Your checkpoint in `active.md` survives it, and `session-start.sh` shows it
   again afterwards. Do not wait until you are at the
   limit.
4. **主动压缩上下文。** 当上下文使用率达到约 65-70% 时，就执行压缩或 `/clear`。
   你在 `active.md` 中的检查点能够经受住这一过程，之后 `session-start.sh`
   会再次展示它。不要等到已经逼近
   上限才行动。

5. **Use the right tier of agent.** Do not ask `creative-director` to write a
   shader. Do not ask `qa-tester` to make design decisions. The hierarchy
   exists for a reason.
5. **使用合适层级的智能体。** 不要让 `creative-director` 去写着色器。
   不要让 `qa-tester` 去做设计决策。层级体系的存在
   是有原因的。

6. **Run /help when uncertain.** It reads your actual project state and tells
   you the single most important next step.
6. **不确定时运行 /help。** 它会读取你项目的实际状态，并告诉你
   最重要的那一个下一步。

7. **Run `/design-review` before handing designs to programmers.** This
   catches incomplete specs early, saving rework.
7. **在把设计交给程序员之前运行 `/design-review`。** 这能
   尽早发现不完整的规格，节省返工。

8. **Run `/code-review` after every major feature.** Catch architectural
   issues before they propagate.
8. **在每个主要功能完成后运行 `/code-review`。** 在架构问题
   扩散之前将其拦截。

9. **Prototype risky mechanics first.** A day of prototyping can save a week
   of production on a mechanic that does not work.
9. **先为高风险机制做原型。** 在一个行不通的机制上，一天的
   原型制作可能省下一周的制作时间。

10. **Keep your sprint plans honest.** Use `/scope-check` regularly. Scope
    creep is the number one killer of indie games.
10. **让冲刺计划保持诚实。** 定期使用 `/scope-check`。范围蔓延
    是独立游戏的头号杀手。

11. **Document decisions with ADRs.** Future-you will thank present-you for
    recording *why* things were built the way they were.
11. **用 ADR 记录决策。** 未来的你会感谢现在的你
    记录下了*为什么*要这样构建。

12. **Use the story lifecycle religiously.** `/story-readiness` before pickup,
    `/story-done` after completion. This catches deviations early and keeps
    the pipeline honest.
12. **虔诚地使用故事生命周期。** 领取前 `/story-readiness`，
    完成后 `/story-done`。这能尽早发现偏差，并让
    流水线保持诚实。

13. **Write to files early and often.** Incremental section writing means your
    design decisions survive crashes and compactions. The file is the memory,
    not the conversation.
13. **尽早且频繁地写入文件。** 增量式章节写入意味着你的
    设计决策能在崩溃和压缩后存活。文件才是记忆，
    而不是对话。
