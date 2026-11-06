# UX Spec: [Screen/Flow Name]
# UX 规格：[界面/流程名称]

> Authoring guidance: .claude/docs/templates/guidance/ux-spec-guide.md (load per-section as you author — do not read entirely).
> 编写指导：.claude/docs/templates/guidance/ux-spec-guide.md（编写时按章节加载——不要整体阅读）。

> **Status**: [In Design | In Review | Approved | Implemented]
> **状态**：[设计中 | 评审中 | 已批准 | 已实现]
> **Author**: [user + ux-designer]
> **作者**：[用户 + ux-designer]
> **Last Updated**: [today's date]
> **最后更新**：[今天的日期]
> **Journey Phase(s)**: [from context]
> **旅程阶段**：[来自上下文]
> **Screen / Flow Name**: [Short identifier used in code and tickets — e.g., `InventoryScreen`, `NewGameFlow`]
> **界面 / 流程名称**：[代码与工单中使用的简短标识 — 例如 `InventoryScreen`、`NewGameFlow`]
> **Platform Target**: [target platforms and input methods from 2h]
> **目标平台**：[来自 2h 的目标平台与输入方式]
> **Related GDDs**: [Links to the GDD sections that generated this UI requirement — e.g., `design/gdd/inventory.md § UI Requirements`]
> **相关 GDD**：[生成本 UI 需求的 GDD 章节链接 — 例如 `design/gdd/inventory.md § UI Requirements`]
> **Related ADRs**: [Any architectural decisions that constrain this screen — e.g., `ADR-0012: UI Framework Selection`]
> **相关 ADR**：[任何约束本界面的架构决策 — 例如 `ADR-0012: UI Framework Selection`]
> **Related UX Specs**: [Sibling and parent screens — e.g., `pause-menu.md`, `settings.md`]
> **相关 UX 规格**：[同级与父级界面 — 例如 `pause-menu.md`、`settings.md`]
> **Accessibility Tier**: Basic | Standard | Comprehensive | Exemplary
> **无障碍层级**：基础 | 标准 | 全面 | 典范
> **Template**: UX Spec
> **模板**：UX 规格

> **Note — Scope boundary**: This template covers discrete screens and flows (menus,
> dialogs, inventory, settings, cutscene UI, etc.). For persistent in-game overlays
> that exist during active gameplay, use `hud-design.md` instead. If a screen is a
> hybrid (e.g., a pause menu that overlays the game world), treat it as a screen spec
> and note the overlay relationship in Navigation Position.
> **注意 — 范围边界**：本模板覆盖离散的界面与流程（菜单、
> 对话框、物品栏、设置、过场 UI 等）。对于游戏进行中持续存在的
> 游戏内叠加层，请改用 `hud-design.md`。若某界面是
> 混合型（例如叠加在游戏世界上的暂停菜单），将其视为界面规格，
> 并在"导航位置"中注明叠加关系。

---

## 1. Purpose & Player Need
## 1. 目的与玩家需求

[To be designed]
[待设计]

**What player need does this screen serve?**
**本界面服务于什么玩家需求？**

[One paragraph — the real human need from the player's perspective, not the system function. See guide Section 1 for good/bad examples.]
[一段话——从玩家视角出发的真实人类需求，而非系统功能。好坏示例见指南第 1 节。]

**The player goal** (what the player wants to accomplish):
**玩家目标**（玩家想要达成的事）：

[One sentence, specific enough to write an acceptance criterion for.]
[一句话，具体到足以据此编写验收标准。]

**The game goal** (what the game needs to communicate or capture):
**游戏目标**（游戏需要传达或获取的内容）：

[One sentence — what the system needs from this interaction.]
[一句话——系统需要从这次交互中获得什么。]

---

## 2. Player Context on Arrival
## 2. 玩家到达时的情境

[To be designed]
[待设计]

| Question | Answer |
|----------|--------|
| What was the player just doing? | [Prior activity / triggering state] |
| What is their emotional state? | [Tension / calm / urgency] |
| What cognitive load are they carrying? | [High / low + what they are tracking] |
| What information do they already have? | [Known context on arrival] |
| What are they most likely trying to do? | [Primary use case] |
| What are they likely afraid of? | [Risks and anxieties to design against] |

| 问题 | 回答 |
|----------|--------|
| 玩家刚刚在做什么？ | [先前活动 / 触发状态] |
| 他们的情绪状态如何？ | [紧张 / 平静 / 急迫] |
| 他们承载多少认知负荷？ | [高 / 低 + 他们在追踪什么] |
| 他们已经掌握哪些信息？ | [到达时已知的上下文] |
| 他们最可能想做什么？ | [主要用例] |
| 他们可能担心什么？ | [需在设计上防范的风险与焦虑] |

**Emotional design target for this screen**:
**本界面的情绪设计目标**：

[One sentence describing the feeling the player should have while using this screen.]
[一句话描述玩家在使用本界面时应有的感受。]

---

## 3. Navigation Position
## 3. 导航位置

[To be designed]
[待设计]

**Screen hierarchy** (use indentation to show parent-child relationships):
**界面层级**（用缩进表示父子关系）：

```
[Root — e.g., Main Menu]
  └── [Parent Screen — e.g., Settings]
        └── [This Screen — e.g., Audio Settings]
              ├── [Child Screen — e.g., Advanced Audio Options]
              └── [Child Screen — e.g., Speaker Test Dialog]
```

```
[根 — 例如：主菜单]
  └── [父界面 — 例如：设置]
        └── [本界面 — 例如：音频设置]
              ├── [子界面 — 例如：高级音频选项]
              └── [子界面 — 例如：扬声器测试对话框]
```

**Modal behavior**: [Modal (blocks everything behind it, requires explicit dismiss) | Non-modal (game continues behind it) | Overlay (renders over game world, game paused) | Overlay-live (renders over game world, game continues)]
**模态行为**：[模态（阻挡其后的所有内容，需要显式关闭）| 非模态（其后的游戏继续运行）| 叠加（渲染于游戏世界之上，游戏暂停）| 实时叠加（渲染于游戏世界之上，游戏继续运行）]

> If this screen is modal: document the dismiss behavior. Can it be dismissed by pressing
> Back/B? By pressing Escape? By clicking outside it? Can it be dismissed at all, or
> must the player complete it? Undismissable modals are high-friction — justify them.
> 若本界面为模态：记录关闭行为。能否通过按返回/B 键关闭？
> 通过按 Escape 关闭？通过点击其外部关闭？到底能否关闭，还是
> 玩家必须完成它？不可关闭的模态摩擦很高——请为其提供理由。

**Reachability — all entry points**:
**可达性 — 所有入口**：

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [Entry point] | [Trigger] | [Notes] |

| 入口 | 触发方式 | 备注 |
|-------------|-------------|-------|
| [入口] | [触发] | [备注] |

---

## 4. Entry & Exit Points
## 4. 进入与退出点

[To be designed]
[待设计]

> Every entry point must have a corresponding exit point. Empty cells are a sign
> that design work is unfinished. See guide Section 4 for worked examples.
> 每个入口都必须有对应的退出点。空白单元格是
> 设计工作尚未完成的标志。完整示例见指南第 4 节。

**Entry table**:
**进入表**：

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [Trigger] | [Source] | [Transition] | [Data in] | [Notes] |

| 触发 | 来源界面 / 状态 | 过渡类型 | 传入数据 | 备注 |
|---------|----------------------|-----------------|----------------|-------|
| [触发] | [来源] | [过渡] | [传入数据] | [备注] |

**Exit table**:
**退出表**：

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [Exit action] | [Destination] | [Transition] | [Data out / committed] | [Notes] |

| 退出动作 | 目标 | 过渡类型 | 返回 / 保存的数据 | 备注 |
|-------------|------------|-----------------|----------------------|-------|
| [退出动作] | [目标] | [过渡] | [传出 / 提交的数据] | [备注] |

---

## 5. Layout Specification
## 5. 布局规格

### 5.1 ASCII Wireframe
### 5.1 ASCII 线框图

[To be designed]
[待设计]

```
[Draw the screen layout using ASCII art. Suggested characters:
 ┌ ┐ └ ┘ │ ─    for borders
 ╔ ╗ ╚ ╝ ║ ═    for emphasized/modal borders
 [ ]              for interactive elements (buttons, inputs)
 { }              for content areas (lists, grids, images)
 ...              for scrollable content
 ●                for the focused element on open

See guide Section 5 for a completed example wireframe.]
```

```
[使用 ASCII 艺术绘制界面布局。建议使用的字符：
 ┌ ┐ └ ┘ │ ─    用于边框
 ╔ ╗ ╚ ╝ ║ ═    用于强调/模态边框
 [ ]              用于交互元素（按钮、输入框）
 { }              用于内容区域（列表、网格、图片）
 ...              用于可滚动内容
 ●                用于打开时获得焦点的元素

完整示例线框图见指南第 5 节。]
```

### 5.2 Layout Zones
### 5.2 布局区域

[To be designed]
[待设计]

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| [Zone] | [Contents and purpose] | [% width x % height] | [Yes/No] | [Overflow handling] |

| 区域名称 | 描述 | 大致尺寸 | 可滚动？ | 溢出行为 |
|-----------|-------------|-----------------|-------------|-------------------|
| [区域] | [内容与目的] | [宽度 % x 高度 %] | [是/否] | [溢出处理] |

### 5.3 Component Inventory
### 5.3 组件清单

[To be designed]
[待设计]

> List every discrete UI component on this screen. This table drives the implementation
> task list — each row becomes a component to build or reuse.
> 列出本界面上的每一个离散 UI 组件。该表驱动实现
> 任务清单——每一行都成为一个需构建或复用的组件。

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [Component] | [Type] | [Zone] | [Purpose] | [Yes/No] | [Yes — pattern/component name, or No — new] |

| 组件名称 | 类型 | 区域 | 目的 | 是否必需？ | 是否复用现有组件？ |
|----------------|------|------|---------|-----------|---------------------------|
| [组件] | [类型] | [区域] | [目的] | [是/否] | [是 — 模式/组件名称，或否 — 新建] |

**Primary focus element on open**: [Element that receives focus when the screen opens, including deep-link and empty-state cases]
**打开时的主要焦点元素**：[界面打开时获得焦点的元素，包括深链接与空状态情形]

### 5.4 Information Hierarchy
### 5.4 信息层级

[To be designed]
[待设计]

[What the player must see first on this screen, what second, and what can wait
behind a tab, a scroll or a button — in that order, with the reason for each.]
[玩家在本界面上必须第一眼看到什么、第二眼看到什么，以及什么可以藏在
标签页、滚动区或按钮之后——按此顺序给出，并说明每一项的理由。]

---

## 6. States & Variants
## 6. 状态与变体

[To be designed]
[待设计]

> Document every state before implementation — at minimum: loading, empty,
> populated, and error. The states table is also the test matrix for QA.
> See guide Section 6 for a worked example.
> 在实现之前记录每个状态——至少包括：加载、空、
> 有内容、错误。状态表同时也是 QA 的测试矩阵。
> 完整示例见指南第 6 节。

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| [Loading / Empty / Populated / Selected / Confirmation / Error / other] | [Trigger] | [Visual changes] | [Behavioral changes] | [Notes] |

| 状态名称 | 触发 | 视觉上的变化 | 行为上的变化 | 备注 |
|------------|---------|----------------------|--------------------------|-------|
| [加载 / 空 / 有内容 / 已选中 / 确认 / 错误 / 其他] | [触发] | [视觉变化] | [行为变化] | [备注] |

---

## 7. Interaction Map
## 7. 交互映射

[To be designed]
[待设计]

> Cover every input method for the platform target (mouse, keyboard, gamepad,
> touch). Gaps in this table are bugs waiting to happen. See guide Section 7.
> 覆盖目标平台的每种输入方式（鼠标、键盘、手柄、
> 触控）。本表中的空缺就是等待发生的缺陷。见指南第 7 节。

### 7.1 Navigation Inputs
### 7.1 导航输入

| Input | Platform | Action | Visual Response | Audio Cue | Notes |
|-------|----------|--------|-----------------|-----------|-------|
| [Input] | [Platform] | [Action] | [Visual response] | [Audio] | [Notes] |

| 输入 | 平台 | 动作 | 视觉响应 | 音频提示 | 备注 |
|-------|----------|--------|-----------------|-----------|-------|
| [输入] | [平台] | [动作] | [视觉响应] | [音频] | [备注] |

### 7.2 Action Inputs
### 7.2 动作输入

| Input | Platform | Context (What must be focused) | Action | Response | Animation | Audio Cue | Notes |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [Input] | [Platform] | [Focus context] | [Action] | [Response] | [Animation + timing] | [Audio] | [Notes] |

| 输入 | 平台 | 情境（必须聚焦什么） | 动作 | 响应 | 动画 | 音频提示 | 备注 |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [输入] | [平台] | [焦点情境] | [动作] | [响应] | [动画 + 时序] | [音频] | [备注] |

### 7.3 State-Specific Behaviors
### 7.3 状态专属行为

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [State] | [Which inputs are disabled] | [Why] |

| 状态 | 输入限制 | 原因 |
|-------|------------------|--------|
| [状态] | [哪些输入被禁用] | [为何] |

---

## 8. Data Requirements
## 8. 数据需求

[To be designed]
[待设计]

> UI reads data; it does not own it. UI fires events; it does not write state
> directly. Every displayed data element needs a source system and owner.
> See guide Section 8 for a worked example.
> UI 读取数据，但不拥有数据。UI 触发事件，但不直接写入状态。
> 每个显示的数据元素都需要来源系统与所有者。
> 完整示例见指南第 8 节。

| Data Element | Source System | Update Frequency | Who Owns It | Format | Null / Missing Handling |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [Data element] | [System] | [When it updates — specific trigger, not "realtime"] | [Owning system — never the UI] | [Type/shape] | [What shows when data is unavailable] |

| 数据元素 | 来源系统 | 更新频率 | 所有者 | 格式 | 空值 / 缺失处理 |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [数据元素] | [系统] | [何时更新 — 具体触发，而非"实时"] | [拥有数据的系统 — 绝不是 UI] | [类型/形态] | [数据不可用时显示什么] |

> **Rule**: This screen must never write directly to any system listed above. All
> player actions fire events (see Section 9). Systems update their own data and
> notify the UI.
> **规则**：本界面绝不可直接写入上述任何系统。所有
> 玩家动作都触发事件（见第 9 节）。系统更新自己的数据并
> 通知 UI。

---

## 9. Events Fired
## 9. 触发的事件

[To be designed]
[待设计]

> Every destructive or state-changing player action must appear in this table.
> See guide Section 9 for a worked example.
> 每个破坏性或改变状态的玩家动作都必须出现在本表中。
> 完整示例见指南第 9 节。

| Player Action | Event Fired | Payload | Receiver System | Notes |
|---------------|-------------|---------|-----------------|-------|
| [Action] | [EventName] | [{fields}] | [System] | [Validation/response flow, or "analytics only"] |

| 玩家动作 | 触发的事件 | 载荷 | 接收系统 | 备注 |
|---------------|-------------|---------|-----------------|-------|
| [动作] | [EventName] | [{fields}] | [系统] | [校验/响应流程，或"仅分析"] |

---

## 10. Transitions & Animations
## 10. 过渡与动画

[To be designed]
[待设计]

> Specify at least the screen enter and exit transitions, plus reduced-motion
> behavior for each. See guide Section 10 for a worked example.
> 至少指定界面进入与退出过渡，以及每一项的减弱动效
> 行为。完整示例见指南第 10 节。

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [Screen enter / exit / in-screen transition] | [Trigger] | [Type] | [ms] | [Easing] | [Yes/No] | [Yes/No + fallback] |

| 过渡 | 触发 | 方向 / 类型 | 时长（毫秒） | 缓动 | 可否中断？ | 减弱动效时跳过？ |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [界面进入 / 退出 / 界面内过渡] | [触发] | [类型] | [毫秒] | [缓动] | [是/否] | [是/否 + 回退方案] |

---

## 11. Input Method Completeness Checklist
## 11. 输入方式完整性检查清单

[To be designed]
[待设计]

> Fill this checklist before marking the spec as Approved. Any unchecked item
> blocks implementation start.
> 在将规格标记为已批准之前填写本清单。任何未勾选项
> 都会阻塞实现启动。

**Keyboard**
**键盘**
- [ ] All interactive elements are reachable using Tab and arrow keys alone
- [ ] 所有交互元素仅用 Tab 与方向键即可到达
- [ ] Tab order follows visual reading order (left-to-right, top-to-bottom within each zone)
- [ ] Tab 顺序遵循视觉阅读顺序（每个区域内从左到右、从上到下）
- [ ] Every action achievable by mouse is also achievable by keyboard
- [ ] 每个可用鼠标完成的动作也可用键盘完成
- [ ] Focus is visible at all times (no element where focus ring disappears)
- [ ] 焦点始终可见（不存在焦点环消失的元素）
- [ ] Focus does not escape the screen while it is open (focus trap for modals)
- [ ] 界面打开期间焦点不会逃逸出界面（模态的焦点陷阱）
- [ ] Esc key closes or cancels (and does not quit the game from within a screen)
- [ ] Esc 键关闭或取消（且不会在界面内退出游戏）

**Gamepad**
**手柄**
- [ ] All interactive elements reachable with D-Pad and left stick
- [ ] 所有交互元素均可用十字键与左摇杆到达
- [ ] Face button mapping documented and consistent with platform conventions (see Section 7.2)
- [ ] 面键映射已记录并与平台惯例一致（见第 7.2 节）
- [ ] No action requires analog stick precision that cannot be replicated with D-Pad
- [ ] 没有动作需要十字键无法复现的摇杆精度
- [ ] Trigger and bumper shortcuts documented if used
- [ ] 若使用扳机与肩键快捷方式，已记录
- [ ] Controller disconnection while screen is open is handled gracefully
- [ ] 界面打开期间手柄断开时能优雅处理

**Mouse**
**鼠标**
- [ ] Hover states defined for all interactive elements
- [ ] 所有交互元素均定义了悬停状态
- [ ] Clickable hit targets are at minimum 32x32px (44x44px preferred)
- [ ] 可点击热区最小为 32x32px（首选 44x44px）
- [ ] Right-click behavior defined (context menu or no-op — not undefined)
- [ ] 右键行为已定义（上下文菜单或空操作——不可未定义）
- [ ] Scroll wheel behavior defined in all scrollable zones
- [ ] 所有可滚动区域均定义了滚轮行为

**Touch (if applicable)**
**触控（如适用）**
- [ ] All touch targets are minimum 44x44px
- [ ] 所有触控目标最小为 44x44px
- [ ] Swipe gestures do not conflict with system-level swipe navigation
- [ ] 滑动手势不与系统级滑动导航冲突
- [ ] All actions achievable with one hand in portrait orientation
- [ ] 竖屏下所有动作均可单手完成
- [ ] Long-press behavior defined if used
- [ ] 若使用长按，其行为已定义

---

## 12. Accessibility
## 12. 无障碍

[To be designed]
[待设计]

> Project-wide standards live in `design/accessibility-requirements.md` — consult it
> before filling this section so you do not duplicate or contradict project-level
> commitments.
> 项目级标准位于 `design/accessibility-requirements.md`——填写本节前请查阅，
> 以免重复或违背项目级承诺。
>
> Accessibility Tiers in this project:
> - Basic: WCAG 2.1 AA text contrast, keyboard navigable, no motion-only information
> - Standard: Basic + screen reader support, colorblind-safe, focus management
> - Comprehensive: Standard + reduced motion support, text scaling, high contrast mode
> - Exemplary: Comprehensive + cognitive load management, AAA equivalent, certified
> 本项目的无障碍层级：
> - 基础：WCAG 2.1 AA 文本对比度、可键盘导航、无仅靠动效传达的信息
> - 标准：基础 + 屏幕阅读器支持、色盲安全、焦点管理
> - 全面：标准 + 减弱动效支持、文本缩放、高对比度模式
> - 典范：全面 + 认知负荷管理、AAA 级同等、已认证

**Text contrast requirements for this screen**:
**本界面的文本对比度要求**：

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|---------------|---------------|-------|
| [Text element] | [Background] | [Ratio — 4.5:1 WCAG AA baseline] | [TBD] | [ ] |

| 文本元素 | 背景情境 | 要求对比度 | 当前对比度 | 是否通过？ |
|--------------|-------------------|---------------|---------------|-------|
| [文本元素] | [背景] | [对比度 — 4.5:1 WCAG AA 基线] | [待定] | [ ] |

**Colorblind-unsafe elements and mitigations**:
**色盲不安全元素及缓解措施**：

| Element | Colorblind Risk | Mitigation |
|---------|----------------|------------|
| [Element] | [Risk type] | [Non-color redundant indicator] |

| 元素 | 色盲风险 | 缓解措施 |
|---------|----------------|------------|
| [元素] | [风险类型] | [非颜色的冗余指示] |

**Focus order** (Tab key sequence, numbered):
**焦点顺序**（Tab 键序列，编号）：

[Numbered focus sequence covering every interactive element, including cycle behavior and any panels focus does not enter — see guide Section 12 for an example]
[覆盖每个交互元素的编号焦点序列，包括循环行为以及焦点不进入的任何面板——示例见指南第 12 节]

**Screen reader announcements for key state changes**:
**关键状态变化的屏幕阅读器播报**：

| State Change | Announcement Text | Announcement Timing |
|--------------|------------------|---------------------|
| [State change] | ["Announcement"] | [When it fires] |

| 状态变化 | 播报文本 | 播报时机 |
|--------------|------------------|---------------------|
| [状态变化] | ["播报内容"] | [何时触发] |

**Cognitive load assessment**:
**认知负荷评估**：

[Count the concurrent information streams the player tracks on this screen; compare against the 7±2 limit and state mitigations — see guide Section 12 for an example]
[统计玩家在本界面上同时追踪的信息流数量；与 7±2 上限比较并说明缓解措施——示例见指南第 12 节]

---

## 13. Localization Considerations
## 13. 本地化考量

[To be designed]
[待设计]

**General rules for this screen**:
**本界面的通用规则**：
- All text elements must tolerate a minimum of 40% expansion from English baseline
- 所有文本元素必须能容忍相对英文基线至少 40% 的扩展
- RTL layout (Arabic, Hebrew): mirrored layout required — document which elements mirror and which do not
- RTL 布局（阿拉伯语、希伯来语）：需要镜像布局——记录哪些元素镜像、哪些不镜像
- CJK languages (Japanese, Korean, Chinese): text may be 20-30% shorter — verify layouts do not look broken with less text
- CJK 语言（日语、韩语、中文）：文本可能短 20-30%——验证布局在文字较少时不显得残缺
- Do not use text in images — all text must be from localization strings
- 不要在图片中使用文字——所有文字必须来自本地化字符串

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behavior | Overflow Behavior | Risk |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [Text element] | [chars] | [max chars] | [%] | [Mirror/align behavior] | [Truncate/scroll/shrink strategy] | [Low/Medium/High] |

| 文本元素 | 英文基线长度 | 最大字符数 | 扩展预算 | RTL 行为 | 溢出行为 | 风险 |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [文本元素] | [字符数] | [最大字符数] | [%] | [镜像/对齐行为] | [截断/滚动/收缩策略] | [低/中/高] |

---

## 14. Acceptance Criteria
## 14. 验收标准

[To be designed]
[待设计]

> Write criteria a QA tester can verify independently, without asking the designer
> what they meant. Every criterion should be binary — pass or fail, not subjective.
> 编写 QA 测试者可独立验证的标准，无需询问设计师
> 其含义。每条标准都应是二元的——通过或失败，而非主观。

**Performance**
**性能**
- [ ] Screen opens (first frame visible) within [200]ms of trigger on minimum-spec hardware
- [ ] 在最低配置硬件上，界面在触发后 [200] 毫秒内打开（首帧可见）
- [ ] Screen is fully interactive (all data loaded) within [500]ms of trigger on minimum-spec hardware
- [ ] 在最低配置硬件上，界面在触发后 [500] 毫秒内完全可交互（所有数据加载完毕）
- [ ] Navigation between elements produces no perceptible frame drop (maintain target framerate ±5fps)
- [ ] 元素间导航不会产生可察觉的掉帧（保持目标帧率 ±5fps）

**Layout & Rendering**
**布局与渲染**
- [ ] Screen displays correctly (no overlap, no cutoff, no overflow) at minimum supported resolution [specify]
- [ ] 界面在最低支持分辨率 [指定] 下正确显示（无重叠、无裁切、无溢出）
- [ ] Screen displays correctly at maximum supported resolution [specify]
- [ ] 界面在最高支持分辨率 [指定] 下正确显示
- [ ] Screen displays correctly at 4:3, 16:9, 16:10, and 21:9 aspect ratios if targeting PC
- [ ] 若目标为 PC，界面在 4:3、16:9、16:10 与 21:9 宽高比下均正确显示
- [ ] No text overflow or truncation in English within defined max-character bounds
- [ ] 在定义的最大字符界限内，英文无文本溢出或截断
- [ ] No text overflow or truncation in the longest-translation language [specify — typically German]
- [ ] 在翻译后最长的语言 [指定——通常为德语] 中无文本溢出或截断
- [ ] All states documented in Section 6 render correctly
- [ ] 第 6 节记录的所有状态均正确渲染
- [ ] Scrollable zones scroll smoothly without frame drops when fully populated
- [ ] 内容填满时，可滚动区域平滑滚动且不掉帧

**Input**
**输入**
- [ ] All interactive elements reachable by keyboard using Tab and arrow keys only
- [ ] 所有交互元素仅用 Tab 与方向键即可由键盘到达
- [ ] All interactive elements reachable by gamepad using D-Pad and face buttons only
- [ ] 所有交互元素仅用十字键与面键即可由手柄到达
- [ ] All interactive elements reachable by mouse without keyboard
- [ ] 所有交互元素无需键盘即可由鼠标到达
- [ ] No action requires simultaneous input that is not documented in Section 7
- [ ] 没有动作需要第 7 节未记录的同步输入
- [ ] Focus is visible at all times on keyboard and gamepad navigation
- [ ] 键盘与手柄导航时焦点始终可见
- [ ] Focus does not escape the screen while it is open
- [ ] 界面打开期间焦点不会逃逸出界面

**Events & Data**
**事件与数据**
- [ ] All events in Section 9 fire with correct payloads on all exit paths (verify with debug logging)
- [ ] 第 9 节的所有事件在所有退出路径上均以正确载荷触发（用调试日志验证）
- [ ] Screen does not write directly to any game system (verify: no direct state mutation calls)
- [ ] 界面不直接写入任何游戏系统（验证：无直接状态变更调用）
- [ ] Changes made on this screen persist correctly after it is closed and reopened
- [ ] 在该界面上所做的更改在关闭并重新打开后正确持久化
- [ ] Screen handles data-change events fired by other systems while it is open without crashing
- [ ] 界面在打开期间能处理其他系统触发的数据变更事件而不崩溃

**Accessibility**
**无障碍**
- [ ] All text passes minimum contrast ratios specified in Section 12
- [ ] 所有文本通过第 12 节指定的最低对比度
- [ ] No information relies on color alone as the sole differentiator
- [ ] 没有信息仅依赖颜色作为唯一区分
- [ ] Screen reader announces documented state changes (verify with platform screen reader)
- [ ] 屏幕阅读器播报已记录的状态变化（用平台屏幕阅读器验证）
- [ ] Reduced motion setting results in instant transitions (no animated transitions)
- [ ] 减弱动效设置会带来瞬时过渡（无动画过渡）
- [ ] High contrast mode (if applicable to Accessibility Tier) renders without visual breakage
- [ ] 高对比度模式（若适用于无障碍层级）渲染无视觉破损

**Localization**
**本地化**
- [ ] No text element overflows its container in any supported language
- [ ] 在任何受支持语言中，没有文本元素溢出其容器
- [ ] RTL layout renders correctly (if RTL is a target language)
- [ ] RTL 布局正确渲染（若 RTL 为目标语言）
- [ ] All text elements are driven by localization strings — no hardcoded display text
- [ ] 所有文本元素均由本地化字符串驱动——无硬编码显示文本

---

## 15. Open Questions
## 15. 待解决问题

[To be designed]
[待设计]

> Track unresolved design questions here. Each question should have a clear owner
> and a deadline. An Approved spec must have zero open questions — move to a decision
> or explicitly document the deferral rationale.
> 在此追踪未解决的设计问题。每个问题都应有明确的负责人
> 与截止日期。已批准的规格必须没有待解决问题——要么做出决定，
> 要么明确记录延期的理由。

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |

| 问题 | 负责人 | 截止日期 | 解决结果 |
|----------|-------|----------|-----------|
| [添加问题] | [负责人] | [截止日期] | [解决结果] |
