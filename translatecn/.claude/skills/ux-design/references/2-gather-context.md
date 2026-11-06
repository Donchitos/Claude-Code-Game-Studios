# /ux-design — Sections 2 and 2b: Gather Context and Retrofit Detection
# /ux-design — 第 2 与 2b 节：收集上下文与改造模式检测

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/ux-design` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## 2. Gather Context (Read Phase)
## 2. 收集上下文（读取阶段）

**In this file:**
**本文件内容：**

- 2a: Required Reads
- 2b: Player Journey
- 2c: GDD UI Requirements
- 2d: Existing UX Specs
- 2e: Interaction Pattern Library
- 2f: Art Bible
- 2g: Accessibility Requirements
- 2h: Input Method (from Project Config)
- 2i: Present Context Summary

- 2a：必读内容
- 2b：玩家旅程
- 2c：GDD UI 需求
- 2d：现有 UX 规格
- 2e：交互模式库
- 2f：美术圣经
- 2g：无障碍需求
- 2h：输入方式（来自项目配置）
- 2i：呈现上下文摘要

Read all relevant context **before** asking the user anything. The skill's value
comes from arriving informed. Read each GDD and the art bible by section: find the
headings you need with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.

在向用户提出任何问题**之前**，先读完所有相关上下文。本技能的价值
来自“带着信息而来”。按分区读取每个 GDD 和美术圣经：用
Grep 工具（pattern 为 `^#`，content 模式）找到所需标题，再用 offset
和 limit 读取对应区间。

### 2a: Required Reads
### 2a：必读内容

- **Game concept**: Read `design/gdd/game-concept.md` — or `design/game-brief.md`,
  the one-page brief that replaces it at `rigor: minimal` — if neither exists, warn:
  > "No game concept found. Run `/brainstorm` first to establish the game's
  > foundation before designing UX."
  > Continue anyway if the user asks.

- **游戏概念**：读取 `design/gdd/game-concept.md`——或在 `rigor: minimal` 下
  替代它的一页式简报 `design/game-brief.md`——若两者都不存在，则警告：
  > “未找到游戏概念。请先运行 `/brainstorm` 建立游戏
  > 基础，再进行 UX 设计。”
  > 若用户要求，仍可继续。

### 2b: Player Journey
### 2b：玩家旅程

Read `design/player-journey.md` if it exists. For each relevant section, extract:
- Which journey phase(s) does this screen appear in?
- What is the player's emotional state on arrival at this screen?
- What player need is this screen serving in the journey?
- What critical moments (from the journey map) does this screen deliver?

若存在 `design/player-journey.md`，则读取。对每个相关分区提取：
- 此界面出现在哪个（些）旅程阶段？
- 玩家到达此界面时的情绪状态是什么？
- 此界面在旅程中服务于玩家的什么需求？
- 此界面承载了（旅程图中的）哪些关键时刻？

If the player journey file does not exist, note the gap and proceed:
> "No player journey map found at `design/player-journey.md`. Designing without it
> means we'll be making assumptions about player context. Consider running a player
> journey session after this spec is drafted."

如果玩家旅程文件不存在，记录缺口并继续：
> “在 `design/player-journey.md` 未找到玩家旅程图。缺少它进行
> 设计意味着我们将对玩家上下文做假设。建议在本规格起草完成后
> 运行一次玩家旅程会话。”

Also add to the UX spec's Open Questions section:
> "Player journey map not yet created. Author it from the template at `.claude/docs/templates/player-journey.md` to establish player context for this screen."

同时向 UX 规格的 Open Questions 分区添加：
> “玩家旅程图尚未创建。请依据 `.claude/docs/templates/player-journey.md` 的模板编写它，以确立此界面的玩家上下文。”

> **Do not tell the user to "run `/ux-design` Phase 2b" to create it.** Phase 2b
> is this step — the one that *reads* the file. That remediation is circular: it
> sends the user back to the check that just reported the gap. No skill
> writes `design/player-journey.md`; it is hand-authored from its template.

> **不要告诉用户去“运行 `/ux-design` 阶段 2b”来创建它。** 阶段 2b
> 就是这一步——即*读取*该文件的那一步。那种补救是循环的：
> 它把用户送回刚刚报告缺口的检查。没有任何技能
> 会写入 `design/player-journey.md`；它是由人依据其模板手工编写的。

### 2c: GDD UI Requirements
### 2c：GDD UI 需求

Glob `design/gdd/*.md` and grep for `UI Requirements` sections. Read any GDD whose
UI Requirements section references this screen by name or category.

用 glob 匹配 `design/gdd/*.md`，并用 grep 查找 `UI Requirements` 分区。读取任何其
UI Requirements 分区按名称或类别引用了此界面的 GDD。

These GDD UI Requirements are the **requirements input** to this spec. Collect them
as a list of constraints the spec must satisfy.

这些 GDD UI 需求是本规格的**需求输入**。把它们收集为
规格必须满足的约束清单。

If designing the HUD, you need the UI Requirements of **every** system — the HUD
aggregates them. Collect them with one scan rather than opening each GDD:

如果设计的是 HUD，你需要**每一个**系统的 UI Requirements——HUD
会聚合它们。用一次扫描收集它们，而不是逐个打开 GDD：

```
Grep pattern="^#+ .*UI Requirements" glob="design/gdd/*.md" output_mode="content" -A 20
```

Establish the denominator first (glob `design/gdd/*.md`, count **N**) and check
the match count against it. Count system GDDs only: `game-concept.md`,
`systems-index.md`, `game-pillars.md`, `gameplay-tags.md`, `entity-registry.md`,
`fixture-swap-ledger.md`, `sound-bible.md` and any `gdd-cross-review-*.md` live
there too, but they are not systems and have no UI to aggregate.
**A GDD with no UI Requirements section is not a GDD
with no UI needs** — it may predate the section. List the unmatched ones and
confirm with the user that they are genuinely headless before excluding them
from the HUD's requirement set; a HUD that silently omits a system's readout is
the exact failure this aggregation exists to prevent.

先确立分母（用 glob 匹配 `design/gdd/*.md`，计数为 **N**），再核对
匹配数与它是否相符。只统计系统 GDD：`game-concept.md`、
`systems-index.md`、`game-pillars.md`、`gameplay-tags.md`、`entity-registry.md`、
`fixture-swap-ledger.md`、`sound-bible.md` 以及任何 `gdd-cross-review-*.md` 也
放在那里，但它们不是系统，没有可供聚合的 UI。
**没有 UI Requirements 分区的 GDD 并不等于
没有 UI 需求的 GDD**——它可能早于该分区存在。列出未匹配的那些，并
在把它们从 HUD 需求集合中剔除之前，与用户确认它们确实是无界面的；
一个悄悄漏掉某个系统读数的 HUD，正是这种聚合机制要防止的失效。

### 2d: Existing UX Specs
### 2d：现有 UX 规格

Glob `design/ux/*.md` and note which screens already have specs. For screens that
will link to or from the current screen, read their navigation/flow sections to
find the entry and exit points this spec must match.

用 glob 匹配 `design/ux/*.md`，记下哪些界面已有规格。对于将链接到当前界面或
从当前界面链接出去的界面，读取它们的导航/流程分区，找出
本规格必须匹配的进入与退出点。

### 2e: Interaction Pattern Library
### 2e：交互模式库

If `design/ux/interaction-patterns.md` exists, read the pattern catalog index
(the list of pattern names and their one-line descriptions). Do not read full
pattern details — just the catalog. This tells you which patterns already exist
so you can reference them rather than reinvent them.

若存在 `design/ux/interaction-patterns.md`，读取模式目录索引
（模式名称及其一行描述的列表）。不要读取完整的
模式细节——只读目录。这会告诉你哪些模式已经存在，
以便引用而非重新发明。

### 2f: Art Bible
### 2f：美术圣经

Check for `design/art/art-bible.md`. If found, read the visual direction
section. UX layout must align with the aesthetic commitments already made.

检查 `design/art/art-bible.md`。若找到，读取视觉方向
分区。UX 布局必须与已经做出的美学承诺保持一致。

### 2g: Accessibility Requirements
### 2g：无障碍需求

Check for `design/accessibility-requirements.md`. If found, read it. The spec
must satisfy the accessibility tier committed to there.

检查 `design/accessibility-requirements.md`。若找到，读取它。本规格
必须满足其中承诺的无障碍等级。

### 2h: Input Method (from Project Config)
### 2h：输入方式（来自项目配置）

Read the `platform` block from `project.yaml`; if `project.yaml` has no
`platform` block, fall back to the `## Input & Platform` section of
`.claude/docs/technical-preferences.md`. Store these values for use throughout
the skill — they drive the Interaction Map and inform accessibility
requirements:

从 `project.yaml` 读取 `platform` 块；若 `project.yaml` 没有
`platform` 块，则回退到 `.claude/docs/technical-preferences.md` 的
`## Input & Platform` 分区。保存这些值供整个技能使用——
它们驱动交互图并影响无障碍需求：

- **Primary Input** — `platform.primary_input` — the dominant input for this game
- **Gamepad Support** — `platform.gamepad_support` — Full / Partial / None
- **Touch Support** — `platform.touch_support` — Full / Partial / None
- **Target Platforms** — `platform.targets` — for safe zone and aspect ratio decisions
- **Input Methods** — the set of supported methods. When reading from
  `project.yaml`, derive it: keyboard/mouse if `PC` or `Web` is in `targets`;
  gamepad if gamepad support is Full/Partial; touch if touch support is
  Full/Partial; plus the primary input. When falling back to
  `technical-preferences.md`, use its explicit Input Methods field.

- **主要输入** —— `platform.primary_input` —— 本游戏的主要输入方式
- **手柄支持** —— `platform.gamepad_support` —— Full / Partial / None
- **触摸支持** —— `platform.touch_support` —— Full / Partial / None
- **目标平台** —— `platform.targets` —— 用于安全区与宽高比决策
- **输入方式** —— 受支持方式的集合。从 `project.yaml`
  读取时如此推导：若 `targets` 中包含 `PC` 或 `Web`，则有键盘/鼠标；
  若手柄支持为 Full/Partial，则有手柄；若触摸支持为
  Full/Partial，则有触摸；再加上主要输入。回退到
  `technical-preferences.md` 时，使用其明确的 Input Methods 字段。

If neither source is configured, ask once:
> "Input methods aren't configured yet. What does this game target?"
> Options: "Keyboard/Mouse only", "Gamepad only", "Both (PC + Console)", "Touch (mobile)", "All of the above"
>
> (Run `/setup-engine` to save this permanently so you won't be asked again.)

如果两个来源都未配置，只询问一次：
> “输入方式尚未配置。这款游戏面向什么平台？”
> 选项：“仅键盘/鼠标”、“仅手柄”、“两者（PC + 主机）”、“触摸（移动端）”、“以上全部”
>
> （运行 `/setup-engine` 可永久保存，之后不会再次询问。）

Store the answer for the rest of this session. Do **not** ask again per section
or per screen.

保存该答案供本次会话余下部分使用。不要按分区或按界面再次
询问。

### 2i: Present Context Summary
### 2i：呈现上下文摘要

Before any design work, present a brief summary to the user:

在做任何设计工作之前，向用户呈现简短摘要：

> **Designing: [Screen/Flow Name]**
> - Mode: [UX Spec / HUD Design / Pattern Library]
> - Journey phase(s): [from player-journey.md, or "unknown — no journey map"]
> - GDD requirements feeding this spec: [count and names, or "none found"]
> - Related screens already specced: [list, or "none yet"]
> - Known patterns available: [count, or "no pattern library yet"]
> - Accessibility tier: [from requirements doc, or "not yet defined"]
> - Input methods: [derived from the `project.yaml` platform block, or "asked above"]

> **正在设计：[Screen/Flow Name]**
> - 模式：[UX Spec / HUD Design / Pattern Library]
> - 旅程阶段：[来自 player-journey.md，或“未知——无旅程图”]
> - 为此规格提供输入的 GDD 需求：[数量与名称，或“未找到”]
> - 已有规格的相关界面：[列表，或“尚无”]
> - 可用的已知模式：[数量，或“尚无模式库”]
> - 无障碍等级：[来自需求文档，或“尚未定义”]
> - 输入方式：[由 `project.yaml` 的 platform 块推导，或“上述已询问”]

Then ask: "Anything else I should read before we start, or shall we proceed?"

然后询问：“开始之前还有什么需要我阅读的吗，还是我们直接继续？”

---

## 2b. Retrofit Mode Detection
## 2b. 改造模式检测

Before creating a skeleton, check if the target output file already exists.

在创建骨架之前，检查目标输出文件是否已存在。

Glob the resolved output path from Phase 1 — `design/ux/[filename].md`, or
`design/accessibility-requirements.md` in `accessibility` mode.

用 glob 匹配第 1 阶段解析出的输出路径——`design/ux/[filename].md`，或在
`accessibility` 模式下为 `design/accessibility-requirements.md`。

**If the file exists — retrofit mode:**
- Read the file in full
- For each expected section, check whether the body has real content (more than a `[To be designed]` placeholder) or is empty/placeholder
- Present a section status summary to the user:

**如果文件已存在——改造模式：**
- 完整读取该文件
- 对每个预期分区，检查正文是否有真实内容（多于一个 `[To be designed]` 占位符），还是为空/占位
- 向用户呈现分区状态摘要：

> "Found existing UX spec at `design/ux/[filename].md`. Here's what's already done:
>
> | Section | Status |
> |---------|--------|
> | Purpose & Player Need | [Complete / Empty / Placeholder] |
> | Player Context on Arrival | ... |
> | Navigation Position | ... |
> | Entry & Exit Points | ... |
> | Layout Specification | ... |
> | States & Variants | ... |
> | Interaction Map | ... |
> | Data Requirements | ... |
> | Events Fired | ... |
> | Transitions & Animations | ... |
> | Input Method Completeness Checklist | ... |
> | Accessibility | ... |
> | Localization Considerations | ... |
> | Acceptance Criteria | ... |
> | Open Questions | ... |
>
> (Rows are the skeleton's own `##` headings for the active mode — the list above is
> UX spec mode; HUD and accessibility modes list their skeleton's headings.)
>
> I'll work on the [N] incomplete sections only — existing content will not be overwritten."

> “在 `design/ux/[filename].md` 找到现有 UX 规格。以下是已经完成的部分：
>
> | 分区 | 状态 |
> |---------|--------|
> | Purpose & Player Need | [Complete / Empty / Placeholder] |
> | Player Context on Arrival | ... |
> | Navigation Position | ... |
> | Entry & Exit Points | ... |
> | Layout Specification | ... |
> | States & Variants | ... |
> | Interaction Map | ... |
> | Data Requirements | ... |
> | Events Fired | ... |
> | Transitions & Animations | ... |
> | Input Method Completeness Checklist | ... |
> | Accessibility | ... |
> | Localization Considerations | ... |
> | Acceptance Criteria | ... |
> | Open Questions | ... |
>
> （各行是当前模式下骨架自身的 `##` 标题——上面的列表是
> UX 规格模式；HUD 模式与无障碍模式列出各自骨架的标题。）
>
> 我只处理 [N] 个未完成的分区——现有内容不会被覆盖。”

- Skip Section 3 (skeleton creation) — the file already exists
- In Phase 4 (Section Authoring), only work on sections with Status: Empty or Placeholder
- Use `Edit` to fill placeholders in-place rather than creating a new skeleton

- 跳过第 3 节（骨架创建）——文件已存在
- 在第 4 阶段（分区编写）中，只处理 Status 为 Empty 或 Placeholder 的分区
- 使用 `Edit` 就地填充占位符，而不是创建新骨架

**If the file does not exist — fresh authoring mode:**
Proceed to Phase 3 (Create File Skeleton) as normal.

**如果文件不存在——全新编写模式：**
照常进入第 3 阶段（创建文件骨架）。

---
