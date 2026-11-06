# /design-system — Phase 2: Gather Context
# /design-system — 第二阶段：收集上下文

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/design-system` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## 2. Gather Context (Read Phase)
## 2. 收集上下文（读取阶段）

**In this file:**

**本文件内容：**

- 2a: Required Reads
- 2a：必读项
- 2b: Dependency Reads
- 2b：依赖阅读
- 2c: Optional Reads
- 2c：可选阅读
- 2d: Present Context Summary
- 2d：呈现上下文摘要
- 2e: Technical Feasibility Pre-Check
- 2e：技术可行性预检

Read all relevant context **before** asking the user anything. This is the skill's
primary advantage over ad-hoc design — it arrives informed. Read each GDD and ADR
by section: find the headings you need with the Grep tool (pattern `^#`, content
mode) and Read those ranges with offset and limit.

在向用户提出任何问题**之前**，先阅读所有相关上下文。这是本技能相较于临时设计的主要优势——它是有备而来的。按章节阅读每个 GDD 和 ADR：用 Grep 工具（模式 `^#`，content 模式）找到你需要的标题，再用 offset 和 limit 读取这些区段。

### 2a: Required Reads
### 2a：必读项

> **At `minimal`** (design-system is voluntary at this tier): read
> `design/game-brief.md` in place of the game concept, and **skip the systems-index
> read** — neither `game-concept.md` nor `systems-index.md` exists at `minimal`.
> Author from the brief's relevant MVP feature and its core loop.
>
> **This callout keys on the PROJECT tier, not this system's effective tier.**
> The two differ whenever `workflow_overrides.system_overrides` bumps one system
> above a `minimal` project — the configuration `.claude/docs/settings-guidance.md`
> advertises as the reason the override exists ("bump one deep system"). Those two
> files are absent because the *project* is `minimal`; raising *this system* to
> `standard` or `full` does not create them. So on a `minimal` project, take this
> branch **even for an overridden system**, and read the brief.
>
> The effective tier still governs everything downstream — the required section
> set (§1), the skeleton (§3), the section cycle (§4) and §5a. Only the
> required-*reads* branch here follows the project tier.
>
> **Then derive `Category`, `Layer` and `Priority` from the brief, once, here.**
> Six later steps are keyed on the systems index you just skipped — §2e's engine
> domain, Section A's and Section B's recommended options, the Visual/Audio
> REQUIRED table, §6 specialist routing, and §5-pre's Quick reference — and none
> of them has an absent-index branch. An overridden system reaches all six at
> `standard` or `full`, so "skip the index" leaves them with no input at all.
> Derive from the brief instead:
>
> - **`Category`** — one of the nine in `templates/systems-index.md`
>   (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio ·
>   Narrative · Meta`), chosen from what the brief says the system *does*.
> - **`Layer`** — `Foundation` if other systems depend on it, else `Feature`.
> - **`Priority`** — `MVP` if the brief's build order lists it, else `Post-MVP`.
>
> Carry all three for the rest of the run and treat them as the index's answer.
> **Mark them inferred** in §5-pre's Quick reference (*"Category: Gameplay
> (inferred from the brief — no systems index at this tier)"*) so a later reader
> does not mistake a derivation for an indexed fact. Do **not** write a systems
> index to hold them: `/map-systems` owns that file (§5d).
>
> Without this rule, an overridden system resolves to `full`, falls through to
> the fail-fast reads below, and aborts on its first step with *"No game concept
> found. Run `/brainstorm` first"*.

> **在 `minimal` 下**（design-system 在此层级是可选的）：阅读 `design/game-brief.md` 来代替游戏概念，并**跳过系统索引的读取**——在 `minimal` 下 `game-concept.md` 和 `systems-index.md` 都不存在。从简报中相关的 MVP 功能及其核心循环出发撰写。
>
> **这段特别说明依据的是项目层级，而不是本系统的有效层级。**
> 当 `workflow_overrides.system_overrides` 把某个系统提升到 `minimal` 项目之上时，两者就会不同——`.claude/docs/settings-guidance.md` 正是把这种配置宣传为覆盖功能存在的理由（"提升一个深层系统"）。那两个文件缺失是因为*项目*是 `minimal`；把*这个系统*提升到 `standard` 或 `full` 并不会创建它们。因此在一个 `minimal` 项目上，**即使是对被覆盖的系统**也要走这个分支，并阅读简报。
>
> 有效层级仍然支配所有下游环节——必需的章节集合（§1）、骨架（§3）、章节循环（§4）和 §5a。只有这里负责必读*读取*的分支遵循项目层级。
>
> **然后在这里一次性从简报推导出 `Category`、`Layer` 和 `Priority`。**
> 后面有六个步骤依赖于你刚跳过的系统索引——§2e 的引擎域、Section A 和 Section B 的推荐选项、Visual/Audio 的 REQUIRED 表、§6 的专家路由，以及 §5-pre 的快速参考——而它们都没有"索引缺失"的分支。被覆盖的系统在 `standard` 或 `full` 下会走到这全部六处，因此"跳过索引"会让它们完全没有任何输入。改为从简报推导：
>
> - **`Category`** —— `templates/systems-index.md` 中九个之一（`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`），依据简报说明该系统*做什么*来选择。
> - **`Layer`** —— 如果其他系统依赖它则为 `Foundation`，否则为 `Feature`。
> - **`Priority`** —— 如果简报的构建顺序列出了它则为 `MVP`，否则为 `Post-MVP`。
>
> 在本次运行的余下过程中携带这三项，并把它们当作索引的答案。在 §5-pre 的快速参考中**将它们标记为推断**（*"Category: Gameplay（从简报推断——此层级没有系统索引）"*），以免后续读者把推导值误当作索引中的事实。**不要**写一个系统索引来存放它们：那个文件归 `/map-systems` 所有（§5d）。
>
> 如果没有这条规则，被覆盖的系统会解析为 `full`，落入下面的快速失败读取，并在第一步就以 *"No game concept found. Run `/brainstorm` first"* 中止。

- **Game concept**: Read `design/gdd/game-concept.md` — fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- **游戏概念**：阅读 `design/gdd/game-concept.md`——如果缺失则失败：
  > "未找到游戏概念。请先运行 `/brainstorm`。"
- **Systems index**: Read `design/gdd/systems-index.md` — fail if missing:
  > "No systems index found. Run `/map-systems` first to map your systems."
- **系统索引**：阅读 `design/gdd/systems-index.md`——如果缺失则失败：
  > "未找到系统索引。请先运行 `/map-systems` 来梳理你的系统。"
- **Target system**: Find the system in the index. If not listed, warn:
  > "[system-name] is not in the systems index. Would you like to add it, or
  > design it as an off-index system?"
- **目标系统**：在索引中找到该系统。如果未列出，则警告：
  > "[system-name] 不在系统索引中。你希望添加它，还是把它作为索引外系统来设计？"
- **Entity registry**: If `design/registry/entities.yaml` exists, list the
  entries this system owns and the entries that reference it, each whole:
  ```
  bash .claude/scripts/registry.sh slice design/gdd/[system-name].md
  ```
  `referenced_by:` is a block list (the key and its paths are on separate
  lines), so a grep for the path finds the line but not the entry that owns
  it; `slice` prints the owning entry however long its list is. Hold these
  in context as **known facts** — values that other GDDs have already
  established and this GDD must not contradict.
- **实体注册表**：如果 `design/registry/entities.yaml` 存在，列出本系统拥有的条目以及引用它的条目，各取完整条目：
  ```
  bash .claude/scripts/registry.sh slice design/gdd/[system-name].md
  ```
  `referenced_by:` 是一个块列表（键名和各条路径分处不同行），因此用 grep 搜索路径只能找到那一行，却找不到拥有它的条目；`slice` 无论列表多长都会打印出所属条目。把这些保留在上下文中作为**已知事实**——即其他 GDD 已确立、本 GDD 不得与之矛盾的值。
- **Reflexion log**: Read `docs/consistency-failures.md` if it exists.
  Extract entries whose Domain matches this system's category. These are
  recurring conflict patterns — present them under "Past failure patterns"
  in the Phase 2d context summary so the user knows where mistakes have
  occurred before in this domain.
- **反思日志**：如果 `docs/consistency-failures.md` 存在则阅读它。提取 Domain 与本系统类目匹配的条目。这些是反复出现的冲突模式——在第二阶段 2d 的上下文摘要中以"过去的失败模式"呈现，让用户知道该领域此前在哪些地方出过错。

### 2b: Dependency Reads
### 2b：依赖阅读

From the systems index, identify:
- **Upstream dependencies**: Systems this one depends on (decisions this system
  must respect).
- **Downstream dependents**: Systems that depend on this one (expectations this
  system must satisfy).

从系统索引中识别：
- **上游依赖**：本系统所依赖的系统（本系统必须遵守的决策）。
- **下游依赖方**：依赖本系统的系统（本系统必须满足的预期）。

For each dependency GDD that exists, read **only the four sections that carry the
cross-system contract** — not the whole GDD:
```
Grep pattern="^## ([0-9]+\. )?(Dependencies|Formulas|Edge Cases|Tuning Knobs)" glob="design/gdd/[dep].md" output_mode="content" -A 20
```
- Key interfaces and data flow (from Dependencies)
- Formulas that reference this system's outputs
- Edge cases that assume this system's behavior
- Tuning knobs that feed into this system

对于每个存在的依赖 GDD，**只读取承载跨系统约定的那四个章节**——而不是整个 GDD：
```
Grep pattern="^## ([0-9]+\. )?(Dependencies|Formulas|Edge Cases|Tuning Knobs)" glob="design/gdd/[dep].md" output_mode="content" -A 20
```
- 关键接口和数据流（来自 Dependencies）
- 引用本系统输出的 Formulas
- 假设了本系统行为的 Edge Cases
- 输入到本系统的 Tuning Knobs

Much of this is already in `entities.yaml` (loaded in 2a) — the registry's
`formula_map`/`constant_map` carry the owned values with their `source:`. Use the
registry first; the section grep fills what it does not hold.

其中许多内容已经在 `entities.yaml` 中（在 2a 中加载）——注册表的 `formula_map`/`constant_map` 携带了所属的值及其 `source:`。优先使用注册表；章节 grep 用来补充它未包含的内容。

### 2c: Optional Reads
### 2c：可选阅读

- **Game pillars**: Read `design/gdd/game-pillars.md` if it exists
- **Existing GDD**: Read `design/gdd/[system-name].md` if it exists (resume, don't
  restart from scratch)
- **Related systems**: do **not** glob-and-read `design/gdd/*.md` hunting for
  "thematically related" systems — there is no deterministic proxy for that and it
  is the read the registry exists to replace. `entities.yaml` (2a) already holds
  the cross-system facts a related GDD would supply. If a specific overlap is
  known, treat it as a dependency above and section-grep it; otherwise rely on the
  registry.

- **游戏支柱**：如果 `design/gdd/game-pillars.md` 存在则阅读它
- **现有 GDD**：如果 `design/gdd/[system-name].md` 存在则阅读它（继续，而不是从头重来）
- **相关系统**：**不要**用 glob 通读 `design/gdd/*.md` 去寻找"主题相关"的系统——这没有确定性的替代指标，而且这正是注册表要替代的那种读取。`entities.yaml`（2a）已经承载了相关 GDD 会提供的跨系统事实。如果已知某个具体的重叠，就把它当作上面的依赖来处理并对它做章节 grep；否则依赖注册表。

### 2d: Present Context Summary
### 2d：呈现上下文摘要

Before starting design work, present a brief summary to the user:

在开始设计工作之前，向用户呈现一份简要摘要：

> **Designing: [System Name]**
> - Priority: [from index] | Layer: [from index]
> - Depends on: [list, noting which have GDDs vs. undesigned]
> - Depended on by: [list, noting which have GDDs vs. undesigned]
> - Existing decisions to respect: [key constraints from dependency GDDs]
> - Pillar alignment: [which pillar(s) this system primarily serves]
> - **Known cross-system facts (from registry):**
>   - [entity_name]: [attribute]=[value], [attribute]=[value] (owned by [source GDD])
>   - [item_name]: [attribute]=[value], [attribute]=[value] (owned by [source GDD])
>   - [formula_name]: variables=[list], output=[min–max] (owned by [source GDD])
>   - [constant_name]: [value] [unit] (owned by [source GDD])
>   *(These values are locked — if this GDD needs different values, surface
>   the conflict before writing. Do not silently use different numbers.)*
>
> If no registry entries are relevant: omit the "Known cross-system facts" section.

> **正在设计：[System Name]**
> - 优先级：[来自索引] | 层级：[来自索引]
> - 依赖于：[列表，注明哪些已有 GDD，哪些尚未设计]
> - 被以下系统依赖：[列表，注明哪些已有 GDD，哪些尚未设计]
> - 需要遵守的既有决策：[来自依赖 GDD 的关键约束]
> - 支柱对齐：[本系统主要服务于哪个（些）支柱]
> - **已知的跨系统事实（来自注册表）：**
>   - [entity_name]: [attribute]=[value], [attribute]=[value]（由 [source GDD] 拥有）
>   - [item_name]: [attribute]=[value], [attribute]=[value]（由 [source GDD] 拥有）
>   - [formula_name]: variables=[list], output=[min–max]（由 [source GDD] 拥有）
>   - [constant_name]: [value] [unit]（由 [source GDD] 拥有）
>   *（这些值已锁定——如果本 GDD 需要不同的值，请在撰写前把冲突暴露出来。不要悄悄使用不同的数字。）*
>
> 如果没有相关的注册表条目：省略"已知的跨系统事实"部分。

If any upstream dependencies are undesigned, warn:
> "[dependency] doesn't have a GDD yet. We'll need to make assumptions about
> its interface. Consider designing it first, or we can define the expected
> contract and flag it as provisional."

如果有任何上游依赖尚未设计，则警告：
> "[dependency] 还没有 GDD。我们将需要对其接口做出假设。考虑先设计它，或者我们可以定义预期约定并将其标记为临时性的。"

### 2e: Technical Feasibility Pre-Check
### 2e：技术可行性预检

Before asking the user to begin designing, load engine context and surface any
constraints or knowledge gaps that will shape the design.

在请用户开始设计之前，加载引擎上下文，并暴露任何会影响设计的约束或知识空白。

**Step 1 — Determine the engine domain for this system:**
Map the system's category (from systems-index.md) to an engine domain:

**第 1 步——确定本系统的引擎域：**
把系统的类目（来自 systems-index.md）映射到引擎域：

Keyed on the `Category` column of `systems-index.md`. All nine categories
`templates/systems-index.md` defines appear here; where a category spans several
engine domains, pick the row matching what the system actually does and say
which you picked.

以 `systems-index.md` 的 `Category` 列为键。`templates/systems-index.md` 定义的九个类目全部出现在这里；当某个类目横跨多个引擎域时，选择匹配该系统实际行为的那一行，并说明你选了哪一行。

| `Category` | Engine Domain |
|-----------|--------------|
| `Gameplay` | **Physics** for combat / collision / movement; **Navigation** for AI and pathfinding; **Scripting** for rule-only systems with no engine surface |
| `Core` | **Core** — scene management, state, resource loading; **Input** for controls and keybinding |
| `UI` | UI |
| `Audio` | Audio |
| `Narrative` | Scripting — dialogue, quests, cutscenes |
| `Progression` | Scripting — save-adjacent rule logic, no dedicated domain |
| `Economy` | Scripting — data and rule logic, no dedicated domain |
| `Persistence` | Core — save/load, settings, serialization |
| `Meta` | Core — analytics, tutorials, accessibility plumbing |

| `Category` | 引擎域 |
|-----------|--------------|
| `Gameplay` | 战斗 / 碰撞 / 移动用 **Physics**；AI 和寻路用 **Navigation**；无引擎表面的纯规则系统用 **Scripting** |
| `Core` | **Core** —— 场景管理、状态、资源加载；操作与按键绑定用 **Input** |
| `UI` | UI |
| `Audio` | Audio |
| `Narrative` | Scripting —— 对话、任务、过场动画 |
| `Progression` | Scripting —— 与存档相邻的规则逻辑，没有专属域 |
| `Economy` | Scripting —— 数据和规则逻辑，没有专属域 |
| `Persistence` | Core —— 存档/读档、设置、序列化 |
| `Meta` | Core —— 分析、教程、无障碍基础设施 |

> Animation, Rendering and Networking are engine domains with no category of
> their own: a system needing them will be `Gameplay` or `Core`. Name the domain
> you read the reference for, whichever row you came in on.

> Animation、Rendering 和 Networking 是没有自己类目的引擎域：需要它们的系统会属于 `Gameplay` 或 `Core`。无论你从哪一行进来，都要说明你为其阅读了参考文档的那个域。

**Step 2 — Read engine context (if available):**
- Identify the engine and version: read `engine.name` and `engine.version` from `project.yaml`. Resolve each field independently — if its key is absent or empty (including when `project.yaml` has no `engine:` block), fall back to `.claude/docs/technical-preferences.md` (a `[TO BE CONFIGURED]` value means not set)
- If engine is configured, read `docs/engine-reference/[engine]/VERSION.md`
- Read `docs/engine-reference/[engine]/modules/[domain].md` if it exists.
  **If it does not exist, say so by name** — *"no engine reference for `[domain]`
  under `docs/engine-reference/[engine]/modules/`; feasibility not checked against
  the pinned engine"* — and carry that into §5-pre. A silent skip here is
  indistinguishable from a feasibility check that ran and found nothing wrong,
  which is the failure `.claude/rules/skill-authoring.md` obligation 3 exists to
  stop.

  > **This is not a rare branch.** The domain table above names `Scripting` and
  > `Core` for five of the nine categories (`Narrative`, `Progression`, `Economy`
  > → Scripting; `Persistence`, `Meta` → Core), plus a sub-row each under
  > `Gameplay` and `Core`. The Godot reference ships `animation, audio, input,
  > navigation, networking, physics, rendering, ui` — **there is no
  > `scripting.md` and no `core.md`**. So the majority of non-`Gameplay` systems
  > hit the absent branch every time: report it every time.
- Read `docs/engine-reference/[engine]/breaking-changes.md` for domain-relevant entries
- Find the domain-matching ADRs without reading every ADR to learn the field you
  filter on — grep the Domain field first, then read only the matches:
  ```
  Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
  ```
  Read only the ADRs whose Domain matches this system's category (its `## Decision`
  and `## Engine Compatibility` sections); skip the rest.

**第 2 步——阅读引擎上下文（如果可用）：**
- 确定引擎和版本：从 `project.yaml` 读取 `engine.name` 和 `engine.version`。独立地解析每个字段——如果其键缺失或为空（包括 `project.yaml` 中没有 `engine:` 块的情况），就回退到 `.claude/docs/technical-preferences.md`（`[TO BE CONFIGURED]` 值表示未设置）
- 如果引擎已配置，阅读 `docs/engine-reference/[engine]/VERSION.md`
- 如果 `docs/engine-reference/[engine]/modules/[domain].md` 存在则阅读它。
  **如果它不存在，请指名说明**——*"`docs/engine-reference/[engine]/modules/` 下没有 `[domain]` 的引擎参考；未针对锁定的引擎检查可行性"*——并把它带入 §5-pre。此处静默跳过，与"运行了可行性检查且没发现问题"无法区分，而这正是 `.claude/rules/skill-authoring.md` 义务 3 要阻止的失败。

  > **这不是罕见分支。** 上面的域表把九个类目中的五个命名为 `Scripting` 和 `Core`（`Narrative`、`Progression`、`Economy` → Scripting；`Persistence`、`Meta` → Core），再加上 `Gameplay` 和 `Core` 各有一个子行。Godot 参考文档附带的是 `animation, audio, input, navigation, networking, physics, rendering, ui`——**既没有 `scripting.md` 也没有 `core.md`**。因此大多数非 `Gameplay` 系统每次都会命中缺失分支：每次都要报告它。
- 阅读 `docs/engine-reference/[engine]/breaking-changes.md` 中与本域相关的条目
- 找出与域匹配的 ADR，而不必为了解你用来筛选的字段而读遍每一个 ADR——先对 Domain 字段做 grep，然后只读匹配项：
  ```
  Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
  ```
  只阅读 Domain 与本系统类目匹配的 ADR（其 `## Decision` 和 `## Engine Compatibility` 章节）；跳过其余部分。

**Step 3 — Present the Feasibility Brief:**

**第 3 步——呈现可行性简报：**

If engine reference docs exist, present before starting design:

如果引擎参考文档存在，在开始设计之前呈现：

```
## Technical Feasibility Brief: [System Name]
Engine: [name + version]
Domain: [domain]

### Known Engine Capabilities (verified for [version])
- [capability relevant to this system]
- [capability 2]

### Engine Constraints That Will Shape This Design
- [constraint from engine-reference or existing ADR]

### Knowledge Gaps (verify before committing to these)
- [post-cutoff feature this design might rely on — mark HIGH/MEDIUM risk]

### Existing ADRs That Constrain This System
- ADR-XXXX: [decision summary] — means [implication for this GDD]
  (or "None yet")
```

```
## Technical Feasibility Brief: [System Name]
Engine: [name + version]
Domain: [domain]

### Known Engine Capabilities (verified for [version])
- [与本系统相关的引擎能力]
- [能力 2]

### Engine Constraints That Will Shape This Design
- [来自引擎参考或现有 ADR 的约束]

### Knowledge Gaps (verify before committing to these)
- [本设计可能依赖的截止点之后的特性——标记 HIGH/MEDIUM 风险]

### Existing ADRs That Constrain This System
- ADR-XXXX: [决策摘要] —— 意味着 [对本 GDD 的影响]
  （或 "None yet"）
```

If no engine reference docs exist (engine not yet configured), show a short note:
> "No engine configured yet — skipping technical feasibility check. Run
> `/setup-engine` before moving to architecture if you haven't already."

如果没有引擎参考文档（引擎尚未配置），显示一条简短说明：
> "尚未配置引擎——跳过技术可行性检查。如果你还没有运行过，请在进入架构阶段之前运行 `/setup-engine`。"

**Step 4 — Ask before proceeding:**

**第 4 步——在继续之前询问：**

Use `AskUserQuestion`:
- "Any constraints to add before we begin, or shall we proceed with these noted?"
  - Options: "Proceed with these noted", "Add a constraint first", "I need to check the engine docs — pause here"

使用 `AskUserQuestion`：
- "开始之前还有要补充的约束吗，还是我们就按这些已记录的继续？"
  - 选项："Proceed with these noted"（按已记录的继续）、"Add a constraint first"（先添加一个约束）、"I need to check the engine docs — pause here"（我需要查看引擎文档——在此暂停）

---

Use `AskUserQuestion`:
- "Ready to start designing [system-name]?"
  - Options: "Yes, let's go", "Show me more context first", "Design a dependency first"

---

使用 `AskUserQuestion`：
- "准备好开始设计 [system-name] 了吗？"
  - 选项："Yes, let's go"（是，开始吧）、"Show me more context first"（先给我看更多上下文）、"Design a dependency first"（先设计一个依赖项）

---
