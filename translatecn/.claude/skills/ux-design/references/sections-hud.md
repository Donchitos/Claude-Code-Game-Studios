> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

> 分区编写指导，由 `/ux-design` 仅在当前激活模式下加载。
> 绝不要加载另外两个——每次调用只适用一个模式文件。

# Section Guidance — HUD Design Mode
# 分区指导 — HUD 设计模式

**In this file:**
**本文件内容：**

- Section A: HUD Philosophy
- Section B: Information Architecture
- Section C: Layout Zones
- Section D: HUD Element Specifications
- Sections E–L: HUD States, Information Hierarchy, Visual Budget, Feedback & Notification, Platform Adaptation, Accessibility, Tuning Knobs, Acceptance Criteria

- 分区 A：HUD 理念
- 分区 B：信息架构
- 分区 C：布局分区
- 分区 D：HUD 元素规格
- 分区 E–L：HUD 状态、信息层级、视觉预算、反馈与通知、平台适配、无障碍、调参旋钮、验收标准

HUD design follows a different order from UX spec mode. Begin with philosophy;
do not touch layout until the information architecture is complete.

HUD 设计遵循与 UX 规格模式不同的顺序。从理念开始；
在信息架构完成之前，不要碰布局。

#### Section A: HUD Philosophy
#### 分区 A：HUD 理念

Ask the user to describe the game's relationship with on-screen information in
1-2 sentences.

请用户用 1-2 句话描述游戏与屏上信息之间的关系。

Offer framing examples to help:
- "Nearly HUD-free — atmosphere requires unobstructed immersion (e.g., Hollow Knight, Firewatch)"
- "Minimal but present — only critical information visible, everything else contextual (e.g., Dark Souls)"
- "Information-dense — all decision-relevant data always visible (e.g., Diablo IV, StarCraft II)"
- "Adaptive — HUD density responds to combat state, exploration mode, menus (e.g., God of War)"

提供框架示例作为帮助：
- “几乎无 HUD——氛围需要无遮挡的沉浸感（例如 Hollow Knight、Firewatch）”
- “极简但存在——只显示关键信息，其余按情境显示（例如 Dark Souls）”
- “信息密集——所有与决策相关的数据始终可见（例如 Diablo IV、StarCraft II）”
- “自适应——HUD 密度响应战斗状态、探索模式、菜单（例如 God of War）”

This philosophy becomes the design constraint for every subsequent HUD decision.
If a proposed element conflicts with the stated philosophy, surface that conflict.

这一理念成为后续每一个 HUD 决策的设计约束。
如果提议的元素与所述理念冲突，就明确揭示该冲突。

---

#### Section B: Information Architecture
#### 分区 B：信息架构

Complete this before any layout work. Do not skip it.

在做任何布局工作之前完成本分区。不要跳过。

**Step 1 — Full information inventory**:
Pull all information from GDD UI Requirements sections gathered in Phase 2.
Present the full list: "These are all the things your game systems say they need
to communicate to the player on screen."

**步骤 1 —— 完整信息清单**：
从阶段 2 收集的 GDD UI Requirements 分区中提取全部信息。
呈现完整清单：“这些就是你的游戏系统声称需要在屏幕上
传达给玩家的全部内容。”

**Step 2 — Categorization**:
For each item, ask the user to categorize it:

**步骤 2 —— 分类**：
对每个条目，请用户将其分类：

| Category | Description |
|----------|-------------|
| **Must Show** | Always visible, player needs it for core decisions |
| **Contextual** | Visible only when relevant (in combat, near interactable, etc.) |
| **On Demand** | Player must actively request it (toggle, hold button) |
| **Hidden** | Communicated through world/audio, never on-screen text |

| 类别 | 描述 |
|----------|-------------|
| **必须显示** | 始终可见，玩家做核心决策需要它 |
| **情境性** | 仅在相关时可见（战斗中、靠近可交互物时等） |
| **按需** | 玩家必须主动请求（切换、长按按钮） |
| **隐藏** | 通过世界/音频传达，绝不以屏上文字呈现 |

Use `AskUserQuestion` to step through items in groups of 3-4, not all at once.
This is the most consequential design decision in the HUD — do not rush it.

使用 `AskUserQuestion` 以每组 3-4 个条目逐步推进，而不是一次性处理全部。
这是 HUD 中影响最大的设计决策——不要急于求成。

**Conflict check**: If the information philosophy (Section A) says "nearly HUD-free"
but the Must Show list is growing long, surface the conflict explicitly:
> "The current Must Show list has [N] items. That may conflict with the HUD-free
> philosophy. Options: reduce the Must Show list, revise the philosophy, or define
> a hybrid approach where HUD is absent in exploration and present in combat."

**冲突检查**：如果信息理念（分区 A）说的是“几乎无 HUD”，
而“必须显示”清单却在变长，就明确揭示该冲突：
> “当前的“必须显示”清单有 [N] 项。这可能与无 HUD
> 理念冲突。可选方案：缩减“必须显示”清单、修改理念，或定义
> 一种混合方案：探索时不显示 HUD，战斗中显示。”

---

#### Section C: Layout Zones
#### 分区 C：布局分区

Only after the information architecture is approved, design layout zones.

只有在信息架构获批之后，才设计布局分区。

Base layout on:
- Which items are Must Show (they drive the permanent zone decisions)
- Where player attention naturally goes during gameplay (center-screen for action games,
  corners for strategy games)
- Platform and aspect ratio targets

布局依据：
- 哪些条目属于“必须显示”（它们驱动常驻分区的决策）
- 玩家在游玩时注意力自然落向何处（动作游戏在屏幕中央，
  策略游戏在四角）
- 平台与宽高比目标

Offer 2-3 zone arrangements. Include rationale based on the HUD philosophy and the
categorization from Section B.

提供 2-3 种分区排布。附上基于 HUD 理念与
分区 B 分类的理由。

---

#### Section D: HUD Element Specifications
#### 分区 D：HUD 元素规格

For each element in the layout, specify:
- Element name and category (Must Show / Contextual / On Demand)
- Content displayed
- Visual form (bar, number, icon, counter, map)
- Update behavior (real-time, event-driven, player-queried)
- Contextual trigger (if not always visible)
- Animation behavior (does it pulse when low? Fade in? Slam in?)

对布局中的每个元素，规定：
- 元素名称与类别（Must Show / Contextual / On Demand）
- 显示的内容
- 视觉形态（条、数字、图标、计数器、地图）
- 更新行为（实时、事件驱动、玩家查询）
- 情境触发条件（若非始终可见）
- 动画行为（低值时是否脉动？淡入？猛冲式入场？）

Work element by element. Reference the interaction pattern library if relevant patterns
exist for status displays, resource bars, or cooldown indicators.

逐个元素推进。若交互模式库中已有适用于状态显示、资源条或冷却指示的
相关模式，则加以引用。

---

#### Sections E–L: HUD States, Information Hierarchy, Visual Budget, Feedback & Notification, Platform Adaptation, Accessibility, Tuning Knobs, Acceptance Criteria
#### 分区 E–L：HUD 状态、信息层级、视觉预算、反馈与通知、平台适配、无障碍、调参旋钮、验收标准

These parallel the UX spec's States, Interaction, and Accessibility sections.
The guidance you need is below — **do not load `sections-ux-spec.md`; one mode
file applies per invocation.** For the HUD, apply it as follows.

这些与 UX 规格的 States、Interaction 和 Accessibility 分区相对应。
你需要的指导就在下文——**不要加载 `sections-ux-spec.md`；每次调用
只适用一个模式文件。** 对 HUD，请按以下方式应用。

**HUD States by Gameplay Context (states over time).** Cover at least
exploration, combat, dialogue/cutscene and paused — `/ux-review` checks for all
four. Beyond the happy path, capture what changes the HUD mid-gameplay and present
it as a table for approval:

**按玩法情境划分的 HUD 状态（随时间变化的状态）。** 至少覆盖
探索、战斗、对话/过场与暂停——`/ux-review` 会检查全部
四种。除顺利路径之外，还要捕捉在玩法中途改变 HUD 的因素，并以表格
呈现供批准：

| State / Variant | Trigger | What Changes |
|-----------------|---------|--------------|
| Default | Normal play | — |
| Low-resource | Health/ammo/etc. below threshold | [element pulses, recolors, …] |
| Empty / no-data | Element has nothing to show | [hidden, or placeholder] |
| [etc.] | [trigger] | [changes] |

| 状态 / 变体 | 触发 | 变化内容 |
|-----------------|---------|--------------|
| 默认 | 正常游玩 | — |
| 低资源 | 生命值/弹药等低于阈值 | [元素脉动、变色……] |
| 空 / 无数据 | 元素无内容可显示 | [隐藏，或占位显示] |
| [等等] | [触发] | [变化] |

Ask specifically: what causes the HUD to change density mid-gameplay
(combat vs. exploration), and what fades, pulses, or slams in on each transition?

特别询问：是什么导致 HUD 在玩法中途改变密度
（战斗 vs. 探索），以及每次转换时有什么淡入、脉动或猛冲入场？

**Information Hierarchy.** Give every element in HUD Element Specifications a
priority tier — MUST KEEP, SHOULD KEEP, CAN HIDE or ALWAYS HIDE — with the reason,
and what carries its information when it is hidden (a sound, a diegetic cue, or
nothing). This is the order the Visual Budget below drops elements in.

**信息层级。** 为 HUD 元素规格中的每个元素指定
优先级层级——MUST KEEP、SHOULD KEEP、CAN HIDE 或 ALWAYS HIDE——并给出理由，
以及它被隐藏时由什么承载其信息（一段声音、一个叙事内提示，或
什么都不承载）。这就是下方视觉预算丢弃元素时所用的顺序。

**Visual Budget.** State the maximum number of simultaneous HUD elements and
the maximum share of the screen the HUD may cover, and which elements are dropped
first when a state would exceed it.

**视觉预算。** 说明同时显示的 HUD 元素的最大数量、
HUD 可占用的屏幕最大比例，以及当某状态将超出该预算时先丢弃
哪些元素。

**Feedback & Notification Systems.** One row per transient notification type
(pickup, XP gain, objective update, achievement) — trigger system, screen position,
duration, max simultaneous, priority and **queue behavior**: what happens when two
arrive at once, which are held during combat, and which are never queued.
`/ux-review` checks that every notification has queue/priority behavior defined.

**反馈与通知系统。** 每种瞬时通知类型（拾取、经验值获得、目标更新、
成就）一行——触发系统、屏幕位置、
时长、最大同时显示数、优先级，以及**队列行为**：两个通知
同时到达时怎么办、哪些在战斗中被暂缓、哪些从不排队。
`/ux-review` 会检查每种通知是否都定义了队列/优先级行为。

**Platform Adaptation.** Does mobile/console require different element sizes or
positions? Note per-platform overrides — touch targets, safe-area insets, and
whether any element moves or is dropped on a given platform.

**平台适配。** 移动端/主机是否需要不同的元素尺寸或
位置？记录各平台覆盖设置——触摸目标、安全区内边距，以及
某元素在给定平台上是否移动或被丢弃。

**Accessibility.** Cross-reference `design/accessibility-requirements.md` if it
exists, then walk this checklist for the HUD:
- Gamepad/keyboard focus order for any interactive HUD element
- Text contrast and minimum readable font sizes at gameplay distance
- Color-independent communication (no state conveyed by color alone — a
  low-health cue must not be red-only)
- Reduced-motion alternative for any pulsing/flashing HUD animation
- Screen-reader considerations for non-text indicators

**无障碍。** 若存在 `design/accessibility-requirements.md` 则
交叉引用，然后按以下清单走查 HUD：
- 任何可交互 HUD 元素的手柄/键盘焦点顺序
- 游玩距离下的文本对比度与最小可读字号
- 不依赖颜色的信息传达（不得仅用颜色传达状态——
  低生命提示不能仅靠红色）
- 任何脉动/闪烁 HUD 动画的减少动态效果替代方案
- 针对非文本指示的屏幕阅读器考量

If no accessibility tier has been defined for this project, note the gap in the
HUD design's Open Questions section (WCAG-AA is a reasonable baseline) and
continue without stopping.

如果本项目尚未定义无障碍等级，就在 HUD 设计的 Open Questions 分区中
记录这一缺口（WCAG-AA 是合理基线），然后
不作停留继续。

**Tuning Knobs.** List every player-adjustable HUD setting — overall scale,
opacity, per-element show/hide, subtitle size — with its range and default.

**调参旋钮。** 列出每一项玩家可调的 HUD 设置——整体缩放、
不透明度、逐元素显隐、字幕大小——以及其范围和默认值。

**Acceptance Criteria.** At least 5 checkbox criteria a QA tester can verify
without reading another document — `/story-done` closes HUD stories against
them. Cover at least: safe-zone margins on every target platform, the correct
elements in each gameplay context above, the visual budget (screen share in
exploration and in combat), one accessibility criterion for the committed tier,
and notification queueing. Section 12 of `.claude/docs/templates/hud-design.md`
has worked examples.

**验收标准。** 至少 5 条复选框标准，使 QA 测试人员无需阅读另一份文档
即可验证——`/story-done` 依据它们关闭 HUD
故事。至少覆盖：每个目标平台上的安全区边距、上述
每种玩法情境中的正确元素、视觉预算（探索与战斗中的
屏幕占比）、一条针对已承诺无障碍等级的标准，
以及通知排队。`.claude/docs/templates/hud-design.md`
第 12 节有已完成的示例。
