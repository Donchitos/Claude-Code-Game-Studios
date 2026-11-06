# Interaction Pattern Library
# 交互模式库

> Authoring guidance: .claude/docs/templates/guidance/interaction-pattern-library-guide.md (load per-section as you author — do not read entirely).
> 撰写指导：.claude/docs/templates/guidance/interaction-pattern-library-guide.md（撰写时按章节加载——不要全部读取）。

> **Status**: [In Design | Stable | Under Revision]
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Version**: [1.0]
> **Engine**: [Godot 4.7 / Unity 6 / Unreal Engine 5]
> **UI Framework**: [Godot Control nodes / Unity UI Toolkit / Unreal UMG]
> **Related Documents**:
> - `design/art/art-bible.md` — visual standards (colors, typography, iconography)
> - `design/accessibility-requirements.md` — accessibility commitments per feature
> - `design/ux/[screen].md` — individual screen specs that reference patterns
>
> **Template**: Interaction Pattern Library
> **状态**：[设计中 | 稳定 | 修订中]
> **作者**：[user + ux-designer]
> **最后更新**：[today's date]
> **版本**：[1.0]
> **引擎**：[Godot 4.7 / Unity 6 / Unreal Engine 5]
> **UI 框架**：[Godot Control nodes / Unity UI Toolkit / Unreal UMG]
> **相关文档**：
> - `design/art/art-bible.md` — 视觉标准（颜色、排版、图标）
> - `design/accessibility-requirements.md` — 每个功能的无障碍承诺
> - `design/ux/[screen].md` — 引用各模式的单屏规格
>
> **模板**：交互模式库

> **Why this document exists**: Every UI screen spec should be able to say
> "uses Button (Primary) pattern" rather than re-specifying hover states,
> press animations, focus behavior, keyboard handling, and screen reader
> announcements from scratch. This library is the single source of truth for
> reusable interaction behaviors. When a screen spec references a pattern name,
> the programmer looks it up here. When the behavior changes, it changes here
> and applies everywhere.
>
> This is a living document. Patterns are added as new screens are designed —
> do not design a new interaction without checking here first. If a new pattern
> is needed, add it here (or propose it to the ux-designer) before writing the
> first screen spec that uses it.
>
> **Status definitions**:
> - **Draft**: Interaction specified but not yet implemented or validated
> - **Stable**: Implemented, tested, and validated in at least one shipped screen
> - **Deprecated**: Being phased out — existing uses will be migrated, do not use in new screens
> **本文档为何存在**：每个 UI 界面规格都应能说
> "使用 Button (Primary) 模式"，而不是从头重新规定悬停状态、
> 按下动画、焦点行为、键盘处理和屏幕阅读器
> 播报。此库是可复用交互行为的唯一真相来源。
> 当界面规格引用某个模式名称时，程序员在此查找。
> 当行为改变时，在此改变并适用于所有地方。
>
> 这是一份活文档。模式随新界面设计而添加——
> 在设计新交互前务必先查阅此处。若需要新模式，
> 在编写第一个使用它的界面规格之前，先将其添加到这里
> （或向 ux-designer 提议）。
>
> **状态定义**：
> - **草稿**：交互已规定但尚未实现或验证
> - **稳定**：已在至少一个已发布界面中实现、测试并验证
> - **弃用**：正在淘汰——现有用法将被迁移，不要在新界面中使用

---

## Overview
## 概述

[To be designed]
[待设计]

### How to Use This Library
### 如何使用此库

**If you are designing a screen**: Browse the Pattern Catalog Index below before
inventing new interactions. When a standard pattern fits, reference it by name
in the screen spec (e.g., "The confirm button uses Button (Primary) pattern").
When no existing pattern fits, propose a new one — document it here alongside
or before the screen spec that introduces it.
**如果你正在设计界面**：在发明新交互之前，先浏览下方的模式目录索引。
当标准模式适用时，在界面规格中按名称引用它（例如"确认按钮使用
Button (Primary) 模式"）。当没有现有模式适用时，提议一个新模式——
在引入它的界面规格之前或同时将其记录在此。

**If you are implementing a screen**: When a screen spec says "use [PatternName]
pattern," find it in this document for the complete specification. The
implementation notes section contains engine-specific guidance. The accessibility
section contains the requirements that are non-negotiable.
**如果你正在实现界面**：当界面规格说"使用 [PatternName]
模式"时，在本文档中找到它以获取完整规格。
实现备注章节包含引擎特定指导。无障碍
章节包含不可妥协的要求。

**If you are reviewing a screen spec**: Verify that all interactive elements
reference a pattern from this library or include their own full interaction
specification. "Standard button" or "the usual way" is not a valid reference.
**如果你正在评审界面规格**：验证所有交互元素
都引用了此库中的模式，或包含它们自己完整的交互
规格。"标准按钮"或"通常的做法"不是有效引用。

**If you are updating a pattern**: Changing a Stable pattern affects every screen
that uses it. Before changing, audit all usages (search screen specs for the
pattern name), determine the impact, get approval from the ux-designer, and
update this document before or simultaneously with any implementation change.
**如果你正在更新模式**：更改一个稳定模式会影响每个使用它的
界面。在更改之前，审计所有用法（在界面规格中搜索
模式名称）、确定影响、获得 ux-designer 批准，并在任何实现更改之前或
同时更新本文档。

---

## Pattern Catalog
## 模式目录

[To be designed]
[待设计]

### Pattern Catalog Index
### 模式目录索引

> Add a row here every time a new pattern is added to this document.
> The "Used In" column is the usages audit trail — update it when new screens
> adopt the pattern.
> 每当本文档添加新模式时，在此添加一行。
> "用于"列是用法的审计追踪——当新界面
> 采用该模式时更新它。

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| 模式名称 | 类别 | 描述 | 用于（界面） | 状态 |
|-------------|----------|-------------|------------------|--------|
| Button (Primary) | Input | Main call-to-action. High visual weight. One per screen. | [Main Menu, Pause Menu, Settings] | Draft |
| Button (Secondary) | Input | Alternative action or cancel. Lower visual weight than Primary. | [All modal dialogs, settings screens] | Draft |
| Button (Destructive) | Input | Irreversible action. Requires confirmation before execution. | [Delete Save, Reset Settings] | Draft |
| Toggle | Input | Binary on/off state selection. | [Accessibility settings, audio settings] | Draft |
| Slider | Input | Continuous value selection. | [Volume controls, brightness, text size] | Draft |
| Dropdown / Select | Input | Selection from a discrete list of options. | [Resolution, language, key binding] | Draft |
| List Item | Layout / Input | Selectable row in a vertical scrollable list. | [Achievements, quest log, settings list] | Draft |
| Grid Item | Layout / Input | Selectable cell in a two-dimensional grid. | [Inventory, ability select, item shop] | Draft |
| Modal Dialog | Feedback / Layout | Blocking overlay requiring explicit player decision. | [Confirmation dialogs, error prompts] | Draft |
| Confirmation Dialog | Feedback / Layout | Specific modal for destructive action confirmation. | [Delete Save, Leave Match, Reset] | Draft |
| Toast / Notification | Feedback | Non-blocking temporary message in a screen corner. | [Achievement unlock, autosave notification] | Draft |
| Tooltip | Feedback | Contextual information on hover or focus. | [Inventory items, ability descriptions, settings] | Draft |
| Progress Bar | Feedback / Layout | Linear progress indicator. | [Loading screen, XP bar, quest progress] | Draft |
| Input Field | Input | Text entry control. | [Player name, search, key binding entry] | Draft |
| Tab Bar | Navigation | Tabbed section navigation within a single screen. | [Character sheet, settings, crafting] | Draft |
| Scroll Container | Layout | Scrollable content region with visible scroll indicator. | [Inventory, lore entries, credits] | Draft |
| Inventory Slot | Game-Specific | Item container in inventory grid (empty, filled, equipped, locked). | [Inventory screen, equipment screen] | Draft |
| Ability / Skill Icon | Game-Specific | Ability button with cooldown, charges, and locked states. | [HUD ability bar, skill tree] | Draft |
| Health / Resource Bar | Game-Specific | Value bar with threshold states and damage flash. | [HUD] | Draft |
| Minimap | Game-Specific | Overview map with player marker and points of interest. | [HUD] | Draft |
| Quest / Objective Tracker | Game-Specific | Active objective display with proximity and completion states. | [HUD] | Draft |
| Dialogue Box | Game-Specific | NPC conversation UI with speaker identification. | [All dialogue sequences] | Draft |
| Context Action Prompt | Game-Specific | Contextual "Press X to [action]" prompt near interactable objects. | [World interaction] | Draft |
| Damage Number | Game-Specific | Floating combat feedback number. | [Combat HUD] | Draft |
| Status Effect Icon | Game-Specific | Buff/debuff indicator with duration. | [HUD status bar, enemy health display] | Draft |
| Notification Banner | Game-Specific | Achievement, level up, item acquired notifications. | [Global overlay] | Draft |
| Screen Push | Navigation | Forward navigation with directional animation. | [All menu navigation] | Draft |
| Screen Pop (Back) | Navigation | Back navigation with reversed animation. | [All menu navigation] | Draft |
| Screen Replace | Navigation | Replace current screen without stacking history. | [Main Menu to Loading Screen] | Draft |
| Modal Open / Close | Navigation | Overlay that dims background screen. | [All modal dialogs] | Draft |
| Tab Switch | Navigation | Same-screen content switch between tabs. | [All tabbed screens] | Draft |
| Focus Management | Navigation | Rules for where focus goes when screens open, close, or change. | [All screens] | Draft |
| Escape / Cancel | Navigation | Universal back behavior across platforms and input methods. | [All screens] | Draft |
| Loading State | Feedback | How screens and components indicate loading in progress. | [All loading states] | Draft |
| Empty State | Feedback | How empty lists and grids are presented. | [Empty inventory, no quests, no saves] | Draft |
| Error State | Feedback | How errors are communicated. | [Save failed, network error, invalid input] | Draft |
| Success Confirmation | Feedback | How completed actions are confirmed. | [Settings saved, item crafted, quest turned in] | Draft |
| Optimistic UI | Feedback | Showing assumed success before system confirmation. | [If online features are present] | Draft |
| 按钮（主要） | 输入 | 主要行动号召。高视觉权重。每屏一个。 | [主菜单、暂停菜单、设置] | 草稿 |
| 按钮（次要） | 输入 | 替代操作或取消。视觉权重低于主要按钮。 | [所有模态对话框、设置界面] | 草稿 |
| 按钮（破坏性） | 输入 | 不可逆操作。执行前需要确认。 | [删除存档、重置设置] | 草稿 |
| 切换开关 | 输入 | 二元开/关状态选择。 | [无障碍设置、音频设置] | 草稿 |
| 滑块 | 输入 | 连续值选择。 | [音量控制、亮度、文字大小] | 草稿 |
| 下拉框 / 选择 | 输入 | 从离散选项列表中选择。 | [分辨率、语言、按键绑定] | 草稿 |
| 列表项 | 布局 / 输入 | 垂直滚动列表中的可选择行。 | [成就、任务日志、设置列表] | 草稿 |
| 网格项 | 布局 / 输入 | 二维网格中的可选择单元格。 | [物品栏、能力选择、物品商店] | 草稿 |
| 模态对话框 | 反馈 / 布局 | 需要玩家明确决策的阻塞式覆盖层。 | [确认对话框、错误提示] | 草稿 |
| 确认对话框 | 反馈 / 布局 | 用于破坏性操作确认的特定模态。 | [删除存档、离开对局、重置] | 草稿 |
| Toast / 通知 | 反馈 | 屏幕角落的非阻塞临时消息。 | [成就解锁、自动保存通知] | 草稿 |
| 工具提示 | 反馈 | 悬停或聚焦时的情境信息。 | [物品栏物品、能力描述、设置] | 草稿 |
| 进度条 | 反馈 / 布局 | 线性进度指示器。 | [加载画面、经验条、任务进度] | 草稿 |
| 输入框 | 输入 | 文本输入控件。 | [玩家名称、搜索、按键绑定录入] | 草稿 |
| 标签栏 | 导航 | 单屏内的标签式区块导航。 | [角色表、设置、制作] | 草稿 |
| 滚动容器 | 布局 | 带可见滚动指示器的可滚动内容区域。 | [物品栏、背景设定条目、制作人员名单] | 草稿 |
| 物品栏槽位 | 游戏特定 | 物品栏网格中的物品容器（空、已填充、已装备、锁定）。 | [物品栏界面、装备界面] | 草稿 |
| 能力 / 技能图标 | 游戏特定 | 带冷却、充能和锁定状态的能力按钮。 | [HUD 能力栏、技能树] | 草稿 |
| 生命 / 资源条 | 游戏特定 | 带阈值状态和受伤闪烁的数值条。 | [HUD] | 草稿 |
| 小地图 | 游戏特定 | 带玩家标记和兴趣点的概览地图。 | [HUD] | 草稿 |
| 任务 / 目标追踪器 | 游戏特定 | 带接近与完成状态的活动目标显示。 | [HUD] | 草稿 |
| 对话框 | 游戏特定 | 带说话者识别的 NPC 对话 UI。 | [所有对话序列] | 草稿 |
| 情境动作提示 | 游戏特定 | 可交互物体附近的情境化"按 X 以[动作]"提示。 | [世界交互] | 草稿 |
| 伤害数字 | 游戏特定 | 浮动战斗反馈数字。 | [战斗 HUD] | 草稿 |
| 状态效果图标 | 游戏特定 | 带持续时间的增益/减益指示器。 | [HUD 状态栏、敌人生命显示] | 草稿 |
| 通知横幅 | 游戏特定 | 成就、升级、获得物品通知。 | [全局覆盖层] | 草稿 |
| 屏幕推入 | 导航 | 带方向动画的前进导航。 | [所有菜单导航] | 草稿 |
| 屏幕弹出（返回） | 导航 | 带反向动画的返回导航。 | [所有菜单导航] | 草稿 |
| 屏幕替换 | 导航 | 替换当前屏幕而不堆叠历史。 | [主菜单到加载画面] | 草稿 |
| 模态打开 / 关闭 | 导航 | 使背景屏幕变暗的覆盖层。 | [所有模态对话框] | 草稿 |
| 标签切换 | 导航 | 同一屏幕内标签间的内容切换。 | [所有标签式界面] | 草稿 |
| 焦点管理 | 导航 | 界面打开、关闭或变化时焦点去向的规则。 | [所有界面] | 草稿 |
| 退出 / 取消 | 导航 | 跨平台与输入方式的通用返回行为。 | [所有界面] | 草稿 |
| 加载状态 | 反馈 | 界面和组件如何指示加载进行中。 | [所有加载状态] | 草稿 |
| 空状态 | 反馈 | 空列表和空网格如何呈现。 | [空物品栏、无任务、无存档] | 草稿 |
| 错误状态 | 反馈 | 错误如何传达。 | [保存失败、网络错误、无效输入] | 草稿 |
| 成功确认 | 反馈 | 已完成操作如何确认。 | [设置已保存、物品已制作、任务已交付] | 草稿 |
| 乐观 UI | 反馈 | 在系统确认之前显示假定的成功。 | [若存在在线功能] | 草稿 |

---

## Patterns
## 模式

[Individual pattern entries added here as they are defined]
[各模式条目在定义后添加于此]

### Standard Control Patterns
### 标准控件模式

> Full reference specifications for every pattern in this section (state tables
> with timing/audio values, accessibility requirements, implementation notes)
> are in `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` —
> load only the pattern(s) currently being specified.
> 本节中每个模式的完整参考规格（含时间/音频值的状态表、
> 无障碍要求、实现备注）位于
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md`——
> 仅加载当前正在规定的模式。

---

#### Button (Primary)
#### 按钮（主要）

**Category**: Input
**Status**: Draft
**When to Use**: [The single most important action on a screen — at most one visible at a time]
**When NOT to Use**: [Alternative/secondary actions; destructive actions; anything not the screen's primary intent]
**类别**：输入
**状态**：草稿
**何时使用**：[屏幕上最重要的单一动作——同一时间最多可见一个]
**何时不使用**：[替代/次要操作；破坏性操作；任何不是屏幕主要意图的内容]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Default / Hovered / Focused / Pressed / Disabled / Loading] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [默认 / 悬停 / 聚焦 / 按下 / 禁用 / 加载中] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Keyboard, gamepad, screen reader, colorblind, and touch-target requirements]
**无障碍**：[键盘、手柄、屏幕阅读器、色盲和触控目标要求]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Button (Secondary)
#### 按钮（次要）

**Category**: Input
**Status**: Draft
**When to Use**: [Alternative or cancel action — lower visual weight than Primary]
**When NOT to Use**: [Destructive actions; the screen's most important action]
**类别**：输入
**状态**：草稿
**何时使用**：[替代或取消操作——视觉权重低于主要按钮]
**何时不使用**：[破坏性操作；屏幕最重要的动作]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Same baseline as Button (Primary); note cancel-input mapping in dialogs]
**无障碍**：[与按钮（主要）相同基线；注意对话框中的取消输入映射]

**Implementation Notes**: [Engine-specific guidance; consistent Primary/Secondary positioning]
**实现备注**：[引擎特定指导；主要/次按钮定位一致]

---

#### Button (Destructive)
#### 按钮（破坏性）

**Category**: Input
**Status**: Draft
**When to Use**: [Irreversible actions causing loss of player data or progress]
**When NOT to Use**: [Actions that can be undone or are merely consequential]
**类别**：输入
**状态**：草稿
**何时使用**：[导致玩家数据或进度丢失的不可逆操作]
**何时不使用**：[可撤销或仅是有后果的操作]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly.
> It always triggers a Confirmation Dialog. There are no exceptions.
> **关键规则**：按钮（破坏性）绝不直接执行其操作。
> 它总是触发一个确认对话框。没有例外。

**Accessibility**: [Screen reader must announce the destructive nature]
**无障碍**：[屏幕阅读器必须播报其破坏性本质]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Toggle
#### 切换开关

**Category**: Input
**Status**: Draft
**When to Use**: [Binary on/off settings where current state must be visible at a glance]
**When NOT to Use**: [More than two options; one-shot actions; choices needing explanation]
**类别**：输入
**状态**：草稿
**何时使用**：[当前状态必须一目了然的二元开/关设置]
**何时不使用**：[超过两个选项；一次性动作；需要解释的选择]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Activation inputs, screen reader switch role/state rules, state label requirements]
**无障碍**：[激活输入、屏幕阅读器开关角色/状态规则、状态标签要求]

**Implementation Notes**: [Engine-specific guidance; motion-reduction behavior]
**实现备注**：[引擎特定指导；减少动态效果行为]

---

#### Slider
#### 滑块

**Category**: Input
**Status**: Draft
**When to Use**: [Continuous value selection where range and relative position matter]
**When NOT to Use**: [Precise value entry; short discrete lists; binary state]
**类别**：输入
**状态**：草稿
**何时使用**：[范围与相对位置重要的连续值选择]
**何时不使用**：[精确值录入；短离散列表；二元状态]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Keyboard step/large-step/min-max inputs, screen reader value announcements, numeric value display requirement]
**无障碍**：[键盘步进/大步进/最小-最大输入、屏幕阅读器数值播报、数值显示要求]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Dropdown / Select
#### 下拉框 / 选择

**Category**: Input
**Status**: Draft
**When to Use**: [Selection from a discrete list of 3-15 options; only the selection visible at rest]
**When NOT to Use**: [Binary choices; more than ~15 options; when comparing options matters]
**类别**：输入
**状态**：草稿
**何时使用**：[从 3-15 个离散选项中选择；静止时仅显示所选值]
**何时不使用**：[二元选择；超过约 15 个选项；比较选项很重要时]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [List navigation, combobox role, expanded/collapsed announcements, positioning rules]
**无障碍**：[列表导航、组合框角色、展开/收起播报、定位规则]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### List Item
#### 列表项

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable row in a vertically scrollable list]
**When NOT to Use**: [Two-dimensional grids; non-selectable content rows]
**类别**：布局 / 输入
**状态**：草稿
**何时使用**：[垂直滚动列表中的可选择行]
**何时不使用**：[二维网格；不可选择的内容行]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [状态] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Focus cycling rules, listitem role and position announcements, minimum row height]
**无障碍**：[焦点循环规则、列表项角色与位置播报、最小行高]

**Implementation Notes**: [Engine-specific guidance; scroll-into-view on focus]
**实现备注**：[引擎特定指导；聚焦时滚动到可视区域]

---

#### Grid Item
#### 网格项

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable cell in a two-dimensional grid]
**When NOT to Use**: [Single-column content; non-selectable display cells]
**类别**：布局 / 输入
**状态**：草稿
**何时使用**：[二维网格中的可选择单元格]
**何时不使用**：[单列内容；不可选择的展示单元格]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Empty / Populated / Hovered / Focused / Selected / Pressed / Locked / Drag source / Drop target] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [空 / 已填充 / 悬停 / 聚焦 / 选中 / 按下 / 锁定 / 拖拽源 / 放置目标] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Grid dimensions and row/column position announcements, keyboard-reachable tooltips]
**无障碍**：[网格尺寸与行/列位置播报、键盘可达的工具提示]

**Implementation Notes**: [Engine-specific guidance; custom D-pad cell navigation]
**实现备注**：[引擎特定指导；自定义十字键单元格导航]

---

#### Modal Dialog
#### 模态对话框

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [A decision or acknowledgment that must be resolved before continuing]
**When NOT to Use**: [Non-blocking notifications; information that can wait; dialogs that should allow play behind them]
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：[必须在继续之前解决的决策或确认]
**何时不使用**：[非阻塞通知；可以等待的信息；应允许在后方继续游玩的对话框]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Opening / Active / Dismissing (confirmed) / Dismissing (cancelled) / Cannot dismiss] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [打开 / 活动 / 关闭（已确认） / 关闭（已取消） / 无法关闭] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

> **Focus trap rule**: While a modal dialog is open, focus navigation must cycle
> within the dialog only, and focus must return to the trigger element on close.
> **焦点陷阱规则**：当模态对话框打开时，焦点导航必须仅在
> 对话框内循环，关闭时焦点必须返回触发元素。

**Accessibility**: [Dialog role and required title, Escape/Enter mappings, motion-reduction overrides]
**无障碍**：[对话框角色与必需标题、退出/回车映射、减少动态效果覆盖]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Confirmation Dialog
#### 确认对话框

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Confirming a destructive action — always triggered by Button (Destructive)]
**When NOT to Use**: [Non-destructive confirmations; dialogs with more than two actions]
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：[确认破坏性操作——总是由按钮（破坏性）触发]
**何时不使用**：[非破坏性确认；具有超过两个操作的对话框]

> **Label rule**: The confirm button must be labeled with the specific action,
> not a generic "OK" or "Yes."
> **标签规则**：确认按钮必须以具体操作命名，
> 而非通用的"确定"或"是"。

**Structure**:
- Title: [Brief, action-describing]
- Body: [One sentence stating the consequence]
- Confirm button: [Button (Primary) — labeled with the specific action]
- Cancel button: [Button (Secondary) — "Cancel"]
- Default focus: [Cancel — safer default]
**结构**：
- 标题：[简短、描述操作]
- 正文：[一句说明后果的话]
- 确认按钮：[按钮（主要）——以具体操作命名]
- 取消按钮：[按钮（次要）——"取消"]
- 默认焦点：[取消——更安全的默认值]

**Accessibility**: [Inherits Modal Dialog; alert-dialog announcement; default focus on Cancel is required]
**无障碍**：[继承模态对话框；警报对话框播报；默认焦点必须在取消上]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Toast / Notification
#### Toast / 通知

**Category**: Feedback
**Status**: Draft
**When to Use**: [Brief, non-blocking information requiring no player decision]
**When NOT to Use**: [Decisions; errors requiring action; critical information the player must not miss]
**类别**：反馈
**状态**：草稿
**何时使用**：[简短、非阻塞、不需要玩家决策的信息]
**何时不使用**：[决策；需要操作的错误；玩家绝不能错过的关键信息]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Entering / Displayed / Auto-dismiss / Manual dismiss / Queue overflow] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [进入 / 显示 / 自动关闭 / 手动关闭 / 队列溢出] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Announcement without focus, motion-reduction fallback, minimum auto-dismiss timing, never sole channel for actionable info]
**无障碍**：[无需焦点的播报、减少动态效果兜底、最小自动关闭时间、绝不作为可操作信息的唯一渠道]

**Implementation Notes**: [Engine-specific guidance; queue management and layer ordering]
**实现备注**：[引擎特定指导；队列管理与层级排序]

---

#### Tooltip
#### 工具提示

**Category**: Feedback
**Status**: Draft
**When to Use**: [Contextual information supplementing a visible label]
**When NOT to Use**: [Information required to complete an action; touch-only platforms without hover]
**类别**：反馈
**状态**：草稿
**何时使用**：[补充可见标签的情境信息]
**何时不使用**：[完成操作所需的信息；无悬停的纯触控平台]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Hidden / Hover trigger / Focus trigger / Appearing / Displayed / Hiding] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [隐藏 / 悬停触发 / 聚焦触发 / 出现中 / 已显示 / 隐藏中] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Content accessible without hover, required appearance delay, contrast requirements]
**无障碍**：[无需悬停即可访问内容、必需的显示延迟、对比度要求]

**Implementation Notes**: [Engine-specific guidance; screen-edge repositioning]
**实现备注**：[引擎特定指导；屏幕边缘重新定位]

---

#### Progress Bar
#### 进度条

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Linear progress toward a defined endpoint]
**When NOT to Use**: [Radial progress; rapidly fluctuating values; values with no endpoint]
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：[朝向明确终点的线性进度]
**何时不使用**：[径向进度；快速波动的数值；无终点的数值]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Default / Value increasing / At maximum / At zero / Indeterminate] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [默认 / 数值增加 / 最大值 / 零值 / 不确定] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Progressbar role, numeric value + percentage announcements, numeric label requirement, motion-reduction overrides]
**无障碍**：[进度条角色、数值 + 百分比播报、数值标签要求、减少动态效果覆盖]

**Implementation Notes**: [Engine-specific guidance; indeterminate-mode implementation]
**实现备注**：[引擎特定指导；不确定模式实现]

---

#### Input Field
#### 输入框

**Category**: Input
**Status**: Draft
**When to Use**: [Text entry — player name, search, precise numeric values, key binding capture]
**When NOT to Use**: [Selecting from known options; console-primary flows where virtual keyboards add friction]
**类别**：输入
**状态**：草稿
**何时使用**：[文本录入——玩家名称、搜索、精确数值、按键绑定捕获]
**何时不使用**：[从已知选项中选取；以主机为主的流程中虚拟键盘会增加摩擦]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Default / Hovered / Focused / Typing / Value present / Limit reached / Clear / Validation error / Validated / Disabled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [默认 / 悬停 / 聚焦 / 输入中 / 有值 / 达到上限 / 清除 / 校验错误 / 已校验 / 禁用] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Standard editing shortcuts, textbox role, visible label requirement (placeholder is not a label)]
**无障碍**：[标准编辑快捷键、文本框角色、可见标签要求（占位符不是标签）]

**Implementation Notes**: [Engine-specific guidance; virtual keyboard handling]
**实现备注**：[引擎特定指导；虚拟键盘处理]

---

#### Tab Bar
#### 标签栏

**Category**: Navigation
**Status**: Draft
**When to Use**: [Dividing one screen's content into discrete sections, one visible at a time — max 5-6 tabs]
**When NOT to Use**: [More than 6 tabs; content needing simultaneous visibility; navigation between screens]
**类别**：导航
**状态**：草稿
**何时使用**：[将单屏内容划分为离散区块，一次显示一个——最多 5-6 个标签]
**何时不使用**：[超过 6 个标签；需要同时可见的内容；界面之间的导航]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Inactive / Active / Hovered / Focused / Activated / Shoulder-button switch] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [非活动 / 活动 / 悬停 / 聚焦 / 已激活 / 肩键切换] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [ARIA tab panel pattern (tab/tablist/tabpanel), active-tab distinction beyond color]
**无障碍**：[ARIA 标签面板模式（tab/tablist/tabpanel）、活动标签的区分不依赖颜色]

**Implementation Notes**: [Engine-specific guidance; shoulder-button shortcut handling]
**实现备注**：[引擎特定指导；肩键快捷键处理]

---

#### Scroll Container
#### 滚动容器

**Category**: Layout
**Status**: Draft
**When to Use**: [Content exceeding the visible area of its container]
**When NOT to Use**: [Content better paginated; infinite scroll without loading/end states]
**类别**：布局
**状态**：草稿
**何时使用**：[内容超出其容器可见区域]
**何时不使用**：[更适合分页的内容；没有加载/结束状态的无限滚动]

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| [Content fits / Scrollable / Scrolling / Scrollbar drag / Keyboard scroll / Gamepad scroll / Boundary / Focus follows scroll] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Sound category] |
| [内容适配 / 可滚动 / 滚动中 / 滚动条拖拽 / 键盘滚动 / 手柄滚动 / 边界 / 焦点跟随滚动] | [视觉处理] | [输入触发] | [响应] | [时长 + 缓动] | [声音类别] |

**Accessibility**: [Auto-scroll to keep focused items in view, scroll position announcements, scrollbar as required indicator]
**无障碍**：[自动滚动使聚焦项保持在视野内、滚动位置播报、滚动条作为必需指示器]

**Implementation Notes**: [Engine-specific guidance; ensure-visible on focus change]
**实现备注**：[引擎特定指导；焦点变化时确保可见]

---

### Game-Specific UI Patterns
### 游戏特定 UI 模式

> Full reference specifications for every pattern in this section are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-game-specific.md` — load only the
> pattern(s) currently being specified.
> 本节中每个模式的完整参考规格位于
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-game-specific.md`——仅加载
> 当前正在规定的模式。

---

#### Inventory Slot
#### 物品栏槽位

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Every item container in the inventory grid — empty, populated, equipped, locked]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[物品栏网格中的每个物品容器——空、已填充、已装备、锁定]

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| [Empty / Populated / Focused / Selected / Drag source / Locked / Highlighted / Cooldown overlay] | [Visual treatment] | [Behavioral notes] |
| [空 / 已填充 / 聚焦 / 选中 / 拖拽源 / 锁定 / 高亮 / 冷却覆盖] | [视觉处理] | [行为备注] |

**Accessibility**: [Non-color alternatives for stack counts and quality tiers; keyboard-reachable tooltip; locked-state announcement]
**无障碍**：[堆叠数量与品质层级的非颜色替代；键盘可达的工具提示；锁定状态播报]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Ability / Skill Icon
#### 能力 / 技能图标

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [HUD ability bar buttons, skill tree nodes, any availability-state ability display]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[HUD 能力栏按钮、技能树节点、任何显示可用状态的能力]

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| [Available / On cooldown / Charges remaining / Out of resource / Locked / Active / Just activated] | [Visual treatment] | [Behavioral notes] |
| [可用 / 冷却中 / 剩余充能 / 资源不足 / 锁定 / 活动 / 刚激活] | [视觉处理] | [行为备注] |

**Accessibility**: [Numeric alternatives for cooldown/charge information; names and descriptions exposed to screen readers]
**无障碍**：[冷却/充能信息的数值替代；名称与描述暴露给屏幕阅读器]

**Implementation Notes**: [Engine-specific guidance]
**实现备注**：[引擎特定指导]

---

#### Health / Resource Bar
#### 生命 / 资源条

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Any continuously varying critical player resource in the HUD]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[HUD 中任何持续变化的关键玩家资源]

**States and behaviors**:
**状态与行为**：

| Event | Visual | Audio | Duration |
|-------|--------|-------|---------|
| 事件 | 视觉 | 音频 | 时长 |
|-------|--------|-------|---------|
| [Decrease / Increase / Below threshold / At zero / Maximum / Overflow] | [Visual treatment] | [Sound category] | [Duration] |
| [减少 / 增加 / 低于阈值 / 零值 / 最大值 / 溢出] | [视觉处理] | [声音类别] | [时长] |

**Accessibility**: [Numeric value access; non-color backups for threshold states]
**无障碍**：[数值访问；阈值状态的非颜色备用]

**Implementation Notes**: [Engine-specific guidance; ghost-bar technique]
**实现备注**：[引擎特定指导；幽灵条技术]

---

#### Dialogue Box
#### 对话框

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [All dialogue that has a speaker — NPC conversation, voiced narrative, character-delivered tutorial text]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[所有有说话者的对话——NPC 对话、配音叙事、角色讲述的教程文本]

**Structure**: [Speaker identification, dialogue text body, advance prompt, optional skip/voice/subtitle indicators]
**结构**：[说话者识别、对话正文、推进提示、可选的跳过/语音/字幕指示器]

**States and behaviors**:
**状态与行为**：

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|---------|
| 状态 | 视觉 | 输入 | 响应 | 时长 |
|-------|--------|-------|----------|---------|
| [Line entering / Revealing / Line complete / Advancing / Choices appearing / Closing / Skipping all] | [Visual treatment] | [Input trigger] | [Response] | [Duration] |
| [行进入 / 揭示中 / 行完成 / 推进 / 选项出现 / 关闭 / 跳过全部] | [视觉处理] | [输入触发] | [响应] | [时长] |

**Accessibility**: [Subtitles on by default, configurable typewriter speed, no auto-advance, navigable choices with position announcements]
**无障碍**：[字幕默认开启、可配置打字机速度、无自动推进、选项可导航并播报位置]

**Implementation Notes**: [Engine-specific guidance; dialogue data format]
**实现备注**：[引擎特定指导；对话数据格式]

---

#### Context Action Prompt
#### 情境动作提示

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [A prompt near an interactable object indicating what the player can do]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[可交互物体附近指示玩家能做什么的提示]

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| [Appearing / Idle / Holding / Cannot interact / Disappearing] | [Visual treatment] | [Behavioral notes] |
| [出现中 / 空闲 / 按住中 / 无法交互 / 消失中] | [视觉处理] | [行为备注] |

**Accessibility**: [Text label alongside button icon; positioning must not overlap critical HUD]
**无障碍**：[按钮图标旁的文字标签；定位不得与关键 HUD 重叠]

**Implementation Notes**: [Engine-specific guidance; input-method-aware icon swapping]
**实现备注**：[引擎特定指导；感知输入方式的图标切换]

---

#### Damage Number
#### 伤害数字

**Category**: Game-Specific
**Status**: Draft
**When to Use**: [Floating feedback numbers above combat participants]
**类别**：游戏特定
**状态**：草稿
**何时使用**：[战斗参与者上方的浮动反馈数字]

**Variants**:
**变体**：

| Variant | Visual | Notes |
|---------|--------|-------|
| 变体 | 视觉 | 备注 |
|---------|--------|-------|
| [Normal / Critical / Healing / Miss / Status damage] | [Visual treatment] | [Behavioral notes] |
| [普通 / 暴击 / 治疗 / 未命中 / 状态伤害] | [视觉处理] | [行为备注] |

**Behavior**: [Float trajectory, fade timing, overlap staggering, maximum simultaneous numbers]
**行为**：[浮动轨迹、淡出时机、重叠错开、最大同时数字数]

**Accessibility**: [Supplementary-only feedback; disable option; game fully playable when disabled]
**无障碍**：[仅作为补充反馈；可禁用选项；禁用时游戏完全可玩]

**Implementation Notes**: [Engine-specific guidance; object pooling]
**实现备注**：[引擎特定指导；对象池]

---

### Navigation Patterns
### 导航模式

> Full reference specifications for this section and the next are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` — load
> only the pattern(s) currently being specified.
> 本节及下一节的完整参考规格位于
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md`——仅
> 加载当前正在规定的模式。

---

#### Screen Push / Pop / Replace
#### 屏幕推入 / 弹出 / 替换

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

These three patterns define how screens enter and exit the navigation stack.
这三个模式定义界面如何进入和退出导航栈。

| Pattern | Trigger | Animation | Stack Behavior | Focus Behavior |
|---------|---------|-----------|---------------|----------------|
| 模式 | 触发 | 动画 | 栈行为 | 焦点行为 |
|---------|---------|-----------|---------------|----------------|
| [Push / Pop / Replace] | [Trigger] | [Animation] | [Stack behavior] | [Focus behavior] |
| [推入 / 弹出 / 替换] | [触发] | [动画] | [栈行为] | [焦点行为] |

**Animation durations**: [Push/Pop and Replace durations + easing]
**动画时长**：[推入/弹出与替换的时长 + 缓动]

**Motion reduction**: [Fallback behavior]
**减少动态效果**：[兜底行为]

**Implementation Notes**: [Engine-specific guidance; screen stack manager and return-focus storage]
**实现备注**：[引擎特定指导；屏幕栈管理器与返回焦点存储]

---

#### Focus Management
#### 焦点管理

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

> Focus management is the most common keyboard and gamepad accessibility failure
> in game UIs. These rules must be implemented consistently.
> 焦点管理是游戏 UI 中最常见的键盘与手柄无障碍
> 失败点。这些规则必须一致地实现。

| Rule | Description |
|------|-------------|
| 规则 | 描述 |
|------|-------------|
| [Screen open / close, modal open / close, element disabled / destroyed, Tab order, D-pad spatial navigation, focus visibility] | [Rule description] |
| [界面打开/关闭、模态打开/关闭、元素禁用/销毁、Tab 顺序、十字键空间导航、焦点可见性] | [规则描述] |

---

#### Escape / Cancel
#### 退出 / 取消

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

> The "go back" action is the most-used navigation input in all menu systems.
> It must be consistent across every screen with no exceptions.
> "返回"操作是所有菜单系统中最常用的导航输入。
> 它必须在每个界面中保持一致，没有例外。

| Platform | Input | Behavior |
|----------|-------|---------|
| 平台 | 输入 | 行为 |
|----------|-------|---------|
| [Platform] | [Input] | [Behavior] |
| [平台] | [输入] | [行为] |

**Rules**: [Never override "go back / cancel"; every screen defines its Escape behavior explicitly in its UX spec]
**规则**：[绝不覆盖"返回 / 取消"；每个界面都在其 UX 规格中明确界定退出行为]

---

### Feedback and Loading Patterns
### 反馈与加载模式

---

#### Loading State
#### 加载状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

| Scope | Pattern | Notes |
|-------|---------|-------|
| 范围 | 模式 | 备注 |
|-------|---------|-------|
| [Full screen (initial) / Full screen (transition) / Component inline / Background async] | [Pattern] | [Notes] |
| [全屏（初始） / 全屏（过渡） / 组件内联 / 后台异步] | [模式] | [备注] |

**Accessibility**: [Screen reader loading/loaded announcements; loading screens navigable]
**无障碍**：[屏幕阅读器加载中/已加载播报；加载画面可导航]

---

#### Empty State
#### 空状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

> Every empty list and grid must have a designed empty state. The empty state
> is not an error — it is a starting point.
> 每个空列表和空网格都必须有设计好的空状态。空状态
> 不是错误——它是一个起点。

| Location | Empty State Content | Notes |
|----------|--------------------|----|
| 位置 | 空状态内容 | 备注 |
|----------|--------------------|----|
| [Location] | [Icon + message + sub-message or action] | [Notes] |
| [位置] | [图标 + 消息 + 子消息或操作] | [备注] |

**Rule**: Every empty state must include an icon, a message, and either a sub-message or an action button.
**规则**：每个空状态必须包含图标、消息，以及子消息或操作按钮之一。

---

#### Error State
#### 错误状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

| Error Type | Pattern | Tone |
|-----------|---------|------|
| 错误类型 | 模式 | 语气 |
|-----------|---------|------|
| [Input validation / Operation failed / System error / Soft error] | [Pattern] | [Tone guidance] |
| [输入校验 / 操作失败 / 系统错误 / 软错误] | [模式] | [语气指导] |

**Principle**: Error messages are never the player's fault. They tell the player what happened and what to do next.
**原则**：错误消息永远不是玩家的错。它们告诉玩家发生了什么以及接下来该做什么。

---

## Animation Standards
## 动画标准

> These timing values apply to ALL patterns in this library. When a pattern says
> "150ms ease-out," the easing function is defined here. Consistency in timing
> makes the UI feel like a single designed system rather than a collection of
> individual decisions.
> 这些时间值适用于此库中的所有模式。当某个模式说
> "150ms ease-out"时，缓动函数在此定义。时间上的一致性
> 让 UI 感觉像单一设计系统，而非一堆
> 各自独立的决策。

| Animation Type | Duration (ms) | Easing Function | Notes |
|---------------|--------------|----------------|-------|
| 动画类型 | 时长（ms） | 缓动函数 | 备注 |
|---------------|--------------|----------------|-------|
| Button hover / focus enter | 80 | ease-out | Fast — snappy, not sluggish |
| Button hover / focus exit | 60 | ease-in | Slightly faster exit than entry |
| Button press scale down | 60 | ease-in | Immediate feedback |
| Button press scale up (release) | 80 | ease-out | Slightly bouncy feel |
| Screen push (enter) | 250 | ease-in-out | Screen slides in from right |
| Screen pop (exit) | 250 | ease-in-out | Screen slides out to right |
| Modal open | 200 | ease-out | Expands from center |
| Modal close | 150 | ease-in | Collapses faster than it opens |
| Toast enter | 200 | ease-out | Slides in from screen edge |
| Toast exit | 200 | ease-in | |
| Tab switch | 150 | ease-in-out | Content cross-fades or slides |
| Tooltip appear | 120 | ease-out | After 300-400ms delay |
| Tooltip disappear | 80 | ease-in | |
| Progress bar fill | 300 | ease-out | Value changes animate smoothly |
| Value flash (damage, gain) | 100ms on + 100ms off | linear | Brief, attention-catching |
| Dialogue text reveal (per character) | 30ms per character | linear | Configurable in accessibility settings |
| HUD damage flash | 80 | linear | White or red overlay, immediate |
| 按钮悬停 / 聚焦进入 | 80 | ease-out | 快——干脆，不拖沓 |
| 按钮悬停 / 聚焦退出 | 60 | ease-in | 退出略快于进入 |
| 按钮按下缩放 | 60 | ease-in | 即时反馈 |
| 按钮释放缩放 | 80 | ease-out | 略带弹性的手感 |
| 屏幕推入（进入） | 250 | ease-in-out | 屏幕从右侧滑入 |
| 屏幕弹出（退出） | 250 | ease-in-out | 屏幕向右侧滑出 |
| 模态打开 | 200 | ease-out | 从中心扩展 |
| 模态关闭 | 150 | ease-in | 收起快于打开 |
| Toast 进入 | 200 | ease-out | 从屏幕边缘滑入 |
| Toast 退出 | 200 | ease-in | |
| 标签切换 | 150 | ease-in-out | 内容交叉淡入或滑动 |
| 工具提示出现 | 120 | ease-out | 延迟 300-400ms 后 |
| 工具提示消失 | 80 | ease-in | |
| 进度条填充 | 300 | ease-out | 数值变化平滑动画 |
| 数值闪烁（伤害、获得） | 亮 100ms + 灭 100ms | linear | 简短、吸引注意 |
| 对话文本揭示（按字符） | 每字符 30ms | linear | 可在无障碍设置中配置 |
| HUD 受伤闪烁 | 80 | linear | 白色或红色覆盖，即时 |

**Motion reduction overrides**: When motion reduction mode is enabled (see accessibility-requirements.md), all slide and scale animations are replaced with fades. Fade durations are reduced by 50%. Looping animations (indeterminate spinners, pulsing indicators) are replaced with static equivalents.
**减少动态效果覆盖**：当启用减少动态效果模式时（见 accessibility-requirements.md），所有滑动和缩放动画都替换为淡化。淡化时长减少 50%。循环动画（不确定旋转指示器、脉冲指示器）替换为静态等效物。

---

## Sound Standards
## 声音标准

> Every interactive event should have audio feedback. Sound is a primary feedback
> channel, not a decoration. The sounds defined here are event categories — the
> specific audio assets are defined in `design/audio/sound-bible.md` (or
> `design/gdd/sound-bible.md`, where earlier versions put it). This table maps
> interaction events to sound categories so the sound designer and UI programmer
> use the same vocabulary.
> 每个交互事件都应有音频反馈。声音是主要反馈
> 渠道，而非装饰。这里定义的声音是事件类别——
> 具体音频资产定义在 `design/audio/sound-bible.md`（或
> `design/gdd/sound-bible.md`，早期版本放在那里）。此表将
> 交互事件映射到声音类别，使音效设计师与 UI 程序员
> 使用同一套词汇。

| Interaction Event | Sound Category | Notes |
|------------------|---------------|-------|
| 交互事件 | 声音类别 | 备注 |
|------------------|---------------|-------|
| Button hover / focus | UI Hover | Subtle, short (< 80ms), non-fatiguing on rapid navigation. Hades uses a very quiet, high-frequency click that disappears into background on rapid nav. |
| Button (Primary) confirm | UI Confirm — Primary | Slightly more prominent than secondary confirm. The "yes, let's go" sound. |
| Button (Secondary) cancel / back | UI Cancel | Subtly downward in pitch. The "going back" sound. Mass Effect uses a clean, distinct swoosh for back navigation. |
| Button (Destructive) — opening confirmation | UI Warning | Distinct from standard confirm. Brief attention-catching sound. |
| Confirmation dialog — confirm destructive | UI Confirm — Destructive | Final, slightly weighted. The action is being taken. |
| Toggle ON | UI Toggle On | Brief, snappy, slightly bright. Celeste's accessibility toggles have a satisfying click-on sound. |
| Toggle OFF | UI Toggle Off | Same click family, slightly flatter. |
| Slider adjust | UI Slider | Subtle continuous sound while dragging. A single click per D-pad step. Never fatiguing. |
| Dropdown open | UI Expand | Brief, directional (opening feel). |
| Dropdown close / select | UI Select | Confirmation feel. |
| Tab switch | UI Tab | Horizontal movement feel. Distinct from vertical navigation. |
| Modal open | UI Modal Open | More prominent than standard navigation — draws attention. |
| Modal close (cancel) | UI Modal Close | Returns to previous context. |
| Toast — informational | UI Notification | Background-level, non-intrusive. |
| Toast — achievement | UI Achievement | Celebratory but not overlong. The player should feel rewarded, not interrupted. |
| Toast — warning | UI Warning — Toast | Distinct from error. Alert, not alarming. |
| Error state | UI Error | Friendly but clear. Not a harsh buzzer. Dark Souls uses a subtle dull thud for failed actions — communicates "no" without being harsh. |
| Success confirmation | UI Success | Clean and satisfying. |
| Ability activate | Gameplay — Ability Activate | In-world feel, distinct from pure UI. Part of game feel, not menu feel. |
| Damage received | Gameplay — Damage | See sound-bible.md for full specification. |
| Item pickup | Gameplay — Item Acquire | Brief, rewarding. |
| Level up / rank up | Gameplay — Progression | Celebratory, appropriately prominent. |
| Dialogue advance | UI Dialogue | Subtle, matches typewriter rhythm if typewriter is active. |
| 按钮悬停 / 聚焦 | UI 悬停 | 细微、短促（< 80ms）、快速导航时不疲劳。Hades 使用非常安静的高频点击音，快速导航时融入背景。 |
| 按钮（主要）确认 | UI 确认——主要 | 比次要确认稍更突出。"好，走吧"的声音。 |
| 按钮（次要）取消 / 返回 | UI 取消 | 音高微妙下行。"返回"的声音。Mass Effect 使用干净、独特的 swoosh 用于返回导航。 |
| 按钮（破坏性）——打开确认 | UI 警告 | 与标准确认不同。简短、吸引注意的声音。 |
| 确认对话框——确认破坏性 | UI 确认——破坏性 | 终局感、略带重量。操作正在被执行。 |
| 切换开关 开 | UI 切换开 | 简短、干脆、略明亮。Celeste 的无障碍开关有令人满足的开点击音。 |
| 切换开关 关 | UI 切换关 | 同一 click 家族，稍扁平。 |
| 滑块调整 | UI 滑块 | 拖拽时细微的连续声音。十字键每步一次点击。绝不疲劳。 |
| 下拉框打开 | UI 展开 | 简短、有方向感（打开感）。 |
| 下拉框关闭 / 选择 | UI 选择 | 确认感。 |
| 标签切换 | UI 标签 | 水平移动感。区别于垂直导航。 |
| 模态打开 | UI 模态打开 | 比标准导航更突出——吸引注意。 |
| 模态关闭（取消） | UI 模态关闭 | 返回上一上下文。 |
| Toast——信息性 | UI 通知 | 背景级别、非侵入。 |
| Toast——成就 | UI 成就 | 庆祝性但不过长。玩家应感到被奖励，而非被打断。 |
| Toast——警告 | UI 警告——Toast | 区别于错误。警示，而非惊悚。 |
| 错误状态 | UI 错误 | 友好但清晰。不是刺耳的蜂鸣器。Dark Souls 对失败操作使用微妙的沉闷重击——传达"不"而不刺耳。 |
| 成功确认 | UI 成功 | 干净且令人满足。 |
| 能力激活 | 玩法——能力激活 | 世界内手感，区别于纯 UI。属于游戏手感，而非菜单手感。 |
| 受到伤害 | 玩法——伤害 | 完整规格见 sound-bible.md。 |
| 拾取物品 | 玩法——获得物品 | 简短、有回报感。 |
| 升级 / 升阶 | 玩法——成长 | 庆祝性、适度突出。 |
| 对话推进 | UI 对话 | 细微，若打字机效果开启则匹配其节奏。 |

---

## Gaps & Patterns Needed
## 缺口与所需模式

[To be designed]
[待设计]

---

## Open Questions
## 开放问题

[To be designed]
[待设计]

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 问题 | 负责人 | 截止日期 | 解决情况 |
|----------|-------|----------|-----------|
| [Does the engine's accessibility node system support screen reader announcements for toast notifications without requiring focus? Verify against engine-reference/godot/ for Godot 4.7.] | [ux-designer] | [Before first menu implementation] | [Unresolved] |
| [What is the platform-correct confirm/cancel button mapping for Nintendo Switch release? Nintendo first-party convention differs from Xbox/PlayStation.] | [producer] | [Before platform certification submission] | [Unresolved] |
| [Should damage numbers be pooled as Label3D nodes or rendered in a SubViewport? Verify performance budget in coordination with technical-director.] | [lead-programmer, ux-designer] | [Before combat HUD implementation] | [Unresolved] |
| [What is the maximum number of simultaneous toast notifications before the queue becomes visually overwhelming? Needs playtesting.] | [ux-designer] | [First playtesting session] | [Unresolved] |
| [Add question] | [Owner] | [Deadline] | [Resolution] |
| [引擎的无障碍节点系统是否支持在不要求焦点的情况下为 toast 通知提供屏幕阅读器播报？针对 Godot 4.7 对照 engine-reference/godot/ 验证。] | [ux-designer] | [首个菜单实现之前] | [未解决] |
| [Nintendo Switch 发行版在平台上正确的确认/取消按键映射是什么？任天堂第一方惯例与 Xbox/PlayStation 不同。] | [producer] | [平台认证提交之前] | [未解决] |
| [伤害数字应作为 Label3D 节点池化，还是在 SubViewport 中渲染？与技术总监协调验证性能预算。] | [lead-programmer, ux-designer] | [战斗 HUD 实现之前] | [未解决] |
| [在队列在视觉上变得不堪重负之前，同时存在的 toast 通知最大数量是多少？需要试玩。] | [ux-designer] | [首次试玩会话] | [未解决] |
| [添加问题] | [负责人] | [截止日期] | [解决情况] |
