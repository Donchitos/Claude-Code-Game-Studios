> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

> 分区编写指导，由 `/ux-design` 仅在当前激活模式下加载。
> 绝不要加载另外两个——每次调用只适用一个模式文件。

# Section Guidance — UX Spec Mode
# 分区指导 — UX 规格模式

**In this file:**
**本文件内容：**

- Section A: Purpose & Player Need
- Section B: Player Context on Arrival
- Section B2: Navigation Position
- Section B3: Entry & Exit Points
- Section C: Layout Specification
- Section D: States & Variants
- Section E: Interaction Map
- Section E2: Events Fired
- Section E3: Transitions & Animations
- Section F: Data Requirements
- Section F2: Input Method Completeness Checklist
- Section G: Accessibility
- Section H: Localization Considerations
- Section I: Acceptance Criteria

- 分区 A：目的与玩家需求
- 分区 B：玩家到达时的上下文
- 分区 B2：导航位置
- 分区 B3：进入与退出点
- 分区 C：布局规格
- 分区 D：状态与变体
- 分区 E：交互图
- 分区 E2：触发的事件
- 分区 E3：转场与动画
- 分区 F：数据需求
- 分区 F2：输入方式完整性检查清单
- 分区 G：无障碍
- 分区 H：本地化考虑
- 分区 I：验收标准

#### Section A: Purpose & Player Need
#### 分区 A：目的与玩家需求

This section is the foundation. Every other decision flows from it.

本分区是基础。其他每一个决策都由它派生。

**Questions to ask**:
- "What player goal does this screen serve? What is the player trying to DO here?"
- "What would go wrong if this screen didn't exist or was hard to use?"
- "Complete this sentence: 'The player arrives at this screen wanting to ___.' "

**要问的问题**：
- “这个界面服务的是玩家的什么目标？玩家在这里想要做什么？”
- “如果这个界面不存在，或难以使用，会出什么问题？”
- “补全这句话：‘玩家来到这个界面是想 ___。’”

Cross-reference the player journey context gathered in Phase 2. The stated purpose
must align with the journey phase and emotional state.

交叉引用阶段 2 收集的玩家旅程上下文。所陈述的目的必须与旅程阶段和情绪状态保持一致。

---

#### Section B: Player Context on Arrival
#### 分区 B：玩家到达时的上下文

**Questions to ask**:
- "When in the game does a player first encounter this screen?"
- "What were they just doing immediately before reaching this screen?"
- "What emotional state should the design assume? (calm, stressed, curious, time-pressured)"
- "Do players arrive at this screen voluntarily, or are they sent here by the game?"

**要问的问题**：
- “玩家在游戏的什么时候第一次遇到这个界面？”
- “在到达这个界面之前，他们刚刚在做什么？”
- “设计应假设什么样的情绪状态？（平静、紧张、好奇、时间紧迫）”
- “玩家是自愿到达这个界面的，还是被游戏送到这里的？”

Offer to map this against the journey phases if the player journey doc exists.

若玩家旅程文档存在，可提出将其与旅程阶段进行映射。

---

#### Section B2: Navigation Position
#### 分区 B2：导航位置

Where does this screen sit in the game's navigation hierarchy? This is a one-paragraph orientation map — not a full flow diagram.

这个界面在游戏的导航层级中处于什么位置？这是一段话的定位说明——不是完整流程图。

**Questions to ask**:
- "Is this screen accessed from the main menu, from pause, from within gameplay, or from another screen?"
- "Is it a top-level destination (always reachable) or a context-dependent one (only accessible in certain states)?"
- "Can the player reach this screen from more than one place in the game?"

**要问的问题**：
- “这个界面是从主菜单、从暂停、从玩法内，还是从另一个界面进入的？”
- “它是顶层目的地（始终可达），还是依赖情境的目的地（仅在某些状态下可进入）？”
- “玩家能否从游戏中的多个位置到达这个界面？”

Present as: "This screen lives at: [root] → [parent] → [this screen]" plus any alternate entry paths.

呈现方式：“此界面位于：[root] → [parent] → [this screen]”，并附上任何替代进入路径。

---

#### Section B3: Entry & Exit Points
#### 分区 B3：进入与退出点

Map every way the player can arrive at and leave this screen.

梳理玩家可以到达和离开此界面的每一种方式。

**Questions to ask**:
- "What are all the ways a player can reach this screen?" (List each trigger: button press, game event, redirect from another screen, etc.)
- "What can the player do to exit? What happens when they do?" (Back button, confirm action, timeout, game event)
- "Are there any exits that are one-way — where the player cannot return to this screen without starting over?"

**要问的问题**：
- “玩家到达这个界面的方式都有哪些？”（列出每个触发：按钮按下、游戏事件、从另一界面重定向等）
- “玩家可以做什么来退出？退出时会发生什么？”（返回按钮、确认操作、超时、游戏事件）
- “是否有单向退出——玩家不重新开始就无法回到这个界面？”

Present as two tables:

用两张表呈现：

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| [screen/event] | [how] | [state/data they arrive with] |

| 进入来源 | 触发 | 玩家携带的上下文 |
|---|---|---|
| [screen/event] | [how] | [他们到达时携带的状态/数据] |

| Exit Destination | Trigger | Notes |
|---|---|---|
| [screen/event] | [how] | [any irreversible state changes] |

| 退出目的地 | 触发 | 备注 |
|---|---|---|
| [screen/event] | [how] | [任何不可逆的状态变化] |

---

#### Section C: Layout Specification
#### 分区 C：布局规格

This is the largest and most interactive section. Work through it in sub-sections:

这是篇幅最大、互动性最强的分区。按子分区逐步推进：

**Sub-section 1 — Information Hierarchy** (establish this before any layout):
- Ask the user to list every piece of information this screen must communicate.
- Then ask them to rank the items: "What is the single most important thing a player
  needs to see first? What is second? What can be discovered rather than immediately visible?"
- Present the resulting hierarchy for approval before moving to zones.

**子分区 1 —— 信息层级**（在做任何布局之前先确立）：
- 请用户列出此界面必须传达的每一条信息。
- 然后请他们排序：“玩家首先需要看到的、最重要的单一信息是什么？
  第二是什么？哪些可以让玩家自行发现、而不必立即可见？”
- 在进入分区规划之前，先呈现得出的信息层级供批准。

**Sub-section 2 — Layout Zones**:
- Based on the information hierarchy, propose rough screen zones (header, content
  area, action bar, sidebar, etc.).
- Offer 2-3 zone arrangements with rationale for each. Reference platform and
  input context gathered from game concept.
- Use `AskUserQuestion` to capture the choice:
  - "Which zone arrangement fits best?"
  - Options: [the 2-3 named arrangements you just presented] + "None — build a custom arrangement"

**子分区 2 —— 布局分区**：
- 基于信息层级，提出粗略的屏幕分区（页头、内容区、
  操作栏、侧栏等）。
- 提供 2-3 种分区排布，并说明各自的理由。参考从游戏概念中
  收集的平台与输入上下文。
- 使用 `AskUserQuestion` 捕获选择：
  - “哪种分区排布最合适？”
  - 选项：[你刚刚呈现的 2-3 种已命名排布] + “都不要——构建自定义排布”

**Sub-section 3 — Component Inventory**:
- For each zone, list the UI components it contains. For each component, note:
  - Component type (button, list, card, stat display, input field, etc.)
  - Content it displays
  - Whether it is interactive
  - If it uses an existing pattern from the library (reference by pattern name)
  - If it introduces a new pattern (flag for later addition to the library)

**子分区 3 —— 组件清单**：
- 对每个分区，列出其包含的 UI 组件。对每个组件注明：
  - 组件类型（按钮、列表、卡片、属性显示、输入框等）
  - 它显示的内容
  - 是否可交互
  - 是否使用库中已有的交互模式（以模式名称引用）
  - 是否引入了新模式（标记以便日后加入库）

**Sub-section 4 — ASCII Wireframe**:
- Offer to generate an ASCII wireframe based on the zone layout and component list.
- Use `AskUserQuestion`: "Want an ASCII wireframe as part of this spec?"
  - Options: "Yes, include one", "No, I'll attach a separate file"
- If yes, produce the wireframe in conversation first. Ask for feedback before
  writing it to file.

**子分区 4 —— ASCII 线框图**：
- 提议基于分区布局与组件清单生成 ASCII 线框图。
- 使用 `AskUserQuestion`：“希望在本规格中包含 ASCII 线框图吗？”
  - 选项：“是，包含一份”、“不，我会另附文件”
- 若是，先在对话中产出线框图。在写入文件之前
  征求反馈。

---

#### Section D: States & Variants
#### 分区 D：状态与变体

Guide the user to think beyond the happy path.

引导用户超越顺利路径（happy path）去思考。

**Questions to ask** (work through these one at a time):
- "What does this screen look like the very first time a player sees it, when there
  is no data yet? (empty state)"
- "What happens when something goes wrong — an error, a failed action, a missing
  resource? (error state)"
- "Is there ever a loading wait on this screen? If so, what does it show? (loading state)"
- "Are there any player progression states that change what this screen shows? For
  example, locked content, premium content, or tutorial-mode overlays?"
- "Does this screen behave differently on any supported platform? (platform variant)"

**要问的问题**（逐条推进）：
- “玩家第一次看到这个界面、尚无任何数据时，它是什么样子？
  （空状态）”
- “出问题时会发生什么——错误、操作失败、缺少
  资源？（错误状态）”
- “这个界面是否有加载等待？若有，它显示什么？（加载状态）”
- “是否有某些玩家进度状态会改变此界面的显示？例如，
  锁定内容、付费内容，或教程模式浮层？”
- “此界面在任一受支持平台上行为是否不同？（平台变体）”

Present the collected states as a table for approval:

把收集到的状态以表格呈现供批准：

| State / Variant | Trigger | What Changes |
|-----------------|---------|--------------|
| Default | Normal load | — |
| Empty | No data available | [content area description] |
| [etc.] | [trigger] | [changes] |

| 状态 / 变体 | 触发 | 变化内容 |
|-----------------|---------|--------------|
| 默认 | 正常加载 | — |
| 空 | 无可用数据 | [内容区描述] |
| [等等] | [触发] | [变化] |

---

#### Section E: Interaction Map
#### 分区 E：交互图

For each interactive component identified in the Layout Specification, define:
- The action (tap, click, press, hold, scroll, drag)
- The platform input(s) that trigger it (mouse click, gamepad A, keyboard Enter)
- The immediate feedback (visual, audio, haptic)
- The outcome (navigation target, state change, data write)

对布局规格中识别出的每个可交互组件，定义：
- 动作（点按、点击、按下、长按、滚动、拖拽）
- 触发它的平台输入（鼠标点击、手柄 A 键、键盘 Enter）
- 即时反馈（视觉、音频、触觉）
- 结果（导航目标、状态变化、数据写入）

Use the input methods resolved in Phase 2h — do
not ask the user again. State them upfront: "Mapping interactions for:
[Input Methods resolved in Phase 2h]. Covering [Gamepad Support] gamepad support."

使用阶段 2h 中已解析的输入方式——
不要再次询问用户。预先说明：“正在为以下输入方式映射交互：
[阶段 2h 解析出的输入方式]。覆盖 [Gamepad Support] 手柄支持。”

Work through components one at a time rather than asking for all at once.
For navigation actions (going to another screen), verify the target matches
an existing UX spec or note it as a spec dependency.

逐个组件推进，而不是一次性询问全部。
对于导航动作（前往另一个界面），验证目标是否与
现有 UX 规格匹配，或将其记为规格依赖。

---

#### Section E2: Events Fired
#### 分区 E2：触发的事件

For every player action in the Interaction Map, document the corresponding event the game or analytics system should fire — or explicitly note "no event" if none applies.

对交互图中的每个玩家动作，记录游戏或分析系统应触发的对应事件——若都不适用，则明确注明“无事件”。

**Questions to ask**:
- "For each action, should the game fire an analytics event, trigger a game-state change, or both?"
- "Are there any actions that should NOT fire an event — and is that a deliberate choice?"

**要问的问题**：
- “对每个动作，游戏应触发分析事件、触发游戏状态变化，还是两者都做？”
- “是否有动作不应触发事件——那是有意选择吗？”

Present as a table alongside the Interaction Map:

以表格形式放在交互图旁边：

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| [action] | [EventName] or none | [data passed with event] |

| 玩家动作 | 触发事件 | 载荷 / 数据 |
|---|---|---|
| [action] | [EventName] 或无 | [随事件传递的数据] |

Flag any action that modifies persistent game state (save data, progress, economy) — these need explicit attention from the architecture team.

标记任何修改持久化游戏状态（存档数据、进度、经济）的动作——这些需要架构团队明确关注。

---

#### Section E3: Transitions & Animations
#### 分区 E3：转场与动画

Specify how the screen enters and exits, and how it responds to state changes.

规定界面如何进入与退出，以及它如何响应状态变化。

**Questions to ask**:
- "How does this screen appear? (fade in, slide from right, instant pop, scale from button)"
- "How does it dismiss? (fade out, slide back, cut)"
- "Are there any in-screen state transitions that need animation? (loading spinner, success state, error flash)"
- "Is there any animation that could cause motion sickness — and does the game have a reduced-motion option?"

**要问的问题**：
- “这个界面如何出现？（淡入、从右侧滑入、瞬间弹出、从按钮缩放）”
- “它如何消失？（淡出、滑回、硬切）”
- “是否有需要动画的界面内状态转换？（加载旋转图标、成功状态、错误闪烁）”
- “是否有任何可能引起晕动的动画——游戏是否提供减少动态效果选项？”

Minimum required:
- Screen enter transition
- Screen exit transition
- At least one state-change animation if the screen has multiple states

最低要求：
- 界面进入转场
- 界面退出转场
- 若界面有多个状态，至少一个状态变化动画

---

#### Section F: Data Requirements
#### 分区 F：数据需求

Cross-reference the GDD UI Requirements sections gathered in Phase 2.

交叉引用阶段 2 收集的 GDD UI Requirements 分区。

For each piece of information the screen displays, ask:
- "Where does this data come from? Which system owns it?"
- "Does this screen need to write data back, or is it read-only?"
- "Is any of this data time-sensitive or real-time? (health bars, cooldown timers)"

对界面显示的每一条信息，询问：
- “这条数据来自哪里？哪个系统拥有它？”
- “此界面需要回写数据，还是只读？”
- “这些数据中是否有时间敏感或实时的？（生命条、冷却计时器）”

Flag any case where the UI would need to own or manage game state as an architectural
concern. UX specs define what the UI needs; they do not dictate how the data is
delivered. That is an architecture decision.

凡是 UI 需要拥有或管理游戏状态的情形，都标记为架构层面的
关注点。UX 规格定义 UI 需要什么；它们不规定数据如何
送达。那是架构决策。

Present the data requirements as a table:

以表格呈现数据需求：

| Data | Source System | Read / Write | Notes |
|------|--------------|--------------|-------|
| [item] | [system] | Read | — |
| [item] | [system] | Write | [concern if any] |

| 数据 | 来源系统 | 读 / 写 | 备注 |
|------|--------------|--------------|-------|
| [item] | [system] | 读 | — |
| [item] | [system] | 写 | [如有顾虑] |

---

#### Section F2: Input Method Completeness Checklist
#### 分区 F2：输入方式完整性检查清单

One checklist block per input method in the spec's **Platform Target** line —
keyboard, gamepad, mouse, touch; drop the blocks for methods this game does not
support and say so. Take the items from section 11 of
`.claude/docs/templates/ux-spec.md` (reachability, tab/d-pad order, visible
focus, focus trap for modals, Esc/back behavior, hit-target sizes, controller
disconnect). Tick an item only when the Interaction Map above already specifies
it; an unticked item is an open implementation question — list it under Open
Questions rather than ticking it.

规格 **Platform Target** 行中的每种输入方式各一块检查清单——
键盘、手柄、鼠标、触摸；对游戏不支持的输入方式，删去对应块
并加以说明。条目取自
`.claude/docs/templates/ux-spec.md` 第 11 节（可达性、Tab/D-pad 顺序、可见
焦点、模态聚焦陷阱、Esc/返回行为、点击目标尺寸、手柄
断连）。只有当上方的交互图已经明确规定某个条目时才勾选它；
未勾选的条目是待解决的实现问题——把它列在 Open
Questions 下，而不是勾选。

---

#### Section G: Accessibility
#### 分区 G：无障碍

Cross-reference `design/accessibility-requirements.md` if it exists.

若存在 `design/accessibility-requirements.md`，则交叉引用。

Walk through the ux-designer agent's standard checklist for this screen:
- Keyboard-only navigation path through all interactive elements
- Gamepad navigation order (if applicable)
- Text contrast and minimum readable font sizes
- Color-independent communication (no information conveyed by color alone)
- Screen reader considerations for any non-text elements
- Any motion or animation that needs a reduced-motion alternative

走查 ux-designer 智能体针对此界面的标准检查清单：
- 仅用键盘遍历所有可交互元素的导航路径
- 手柄导航顺序（如适用）
- 文本对比度与最小可读字号
- 不依赖颜色的信息传达（不得仅用颜色传达信息）
- 针对任何非文本元素的屏幕阅读器考量
- 任何需要减少动态效果替代方案的动效或动画

If no accessibility tier has been defined for this project, note the gap in the UX spec's Open Questions section:
> "Accessibility tier not yet defined — consider WCAG-AA as a baseline. Run `/gate-check` to see whether this blocks any phase gates."
Then continue to the next section without stopping.

如果本项目尚未定义无障碍等级，就在 UX 规格的 Open Questions 分区中记录这一缺口：
> “无障碍等级尚未定义——可考虑以 WCAG-AA 作为基线。运行 `/gate-check` 查看这是否会阻断任何阶段关卡。”
然后不作停留，继续进入下一分区。

---

#### Section H: Localization Considerations
#### 分区 H：本地化考虑

Document constraints that affect how this screen behaves when text is translated.

记录影响此界面在文本翻译后表现的约束。

**Questions to ask**:
- "Which text elements on this screen are the longest? What is the maximum character count that fits the layout?"
- "Are there any elements where text length is layout-critical — e.g., a button label that must stay on one line?"
- "Are there any elements that display numbers, dates, or currencies that need locale-specific formatting?"

**要问的问题**：
- “此界面上哪些文本元素最长？布局能容纳的最大字符数是多少？”
- “是否有元素其文本长度对布局至关重要——例如必须保持单行的按钮标签？”
- “是否有显示数字、日期或货币、需要按区域设置格式的元素？”

Note: aim to flag any element where a 40% text expansion (common in translations from English to German or French) would break the layout. Mark those as HIGH PRIORITY for the localization engineer.

注意：目标是标出任何会因 40% 文本膨胀（从英语翻译为德语或法语时常见）而破坏布局的元素。把这些标为本地化工程师的高优先级事项。

---

#### Section I: Acceptance Criteria
#### 分区 I：验收标准

Write at least 5 specific, testable criteria that a QA tester can verify without reading any other design document. These become the pass/fail conditions for `/story-done`.

至少写出 5 条具体、可测试的标准，使 QA 测试人员无需阅读任何其他设计文档即可验证。这些将成为 `/story-done` 的通过/失败条件。

**Format**: Use checkboxes. Each criterion must be verifiable by a human tester:

**格式**：使用复选框。每条标准都必须能由人工测试者验证：

```
- [ ] Screen opens within [X]ms from [trigger]
- [ ] [Element] displays correctly at [minimum] and [maximum] values
- [ ] [Navigation action] correctly routes to [destination screen]
- [ ] Error state appears when [condition] and shows [specific message or icon]
- [ ] Keyboard/gamepad navigation reaches all interactive elements in logical order
- [ ] [Accessibility requirement] is met — e.g., "all interactive elements have focus indicators"
```

```
- [ ] 界面在 [trigger] 之后 [X]ms 内打开
- [ ] [Element] 在 [minimum] 与 [maximum] 值时显示正确
- [ ] [Navigation action] 正确路由到 [destination screen]
- [ ] 满足 [condition] 时出现错误状态，并显示 [specific message or icon]
- [ ] 键盘/手柄导航按逻辑顺序到达所有可交互元素
- [ ] [Accessibility requirement] 已满足——例如“所有可交互元素都有焦点指示”
```

**Minimum required**:
- 1 performance criterion (load/open time)
- 1 navigation criterion (at least one entry or exit path verified)
- 1 error/empty state criterion
- 1 accessibility criterion (per committed tier)
- 1 criterion specific to this screen's core purpose

**最低要求**：
- 1 条性能标准（加载/打开时间）
- 1 条导航标准（至少验证一条进入或退出路径）
- 1 条错误/空状态标准
- 1 条无障碍标准（按已承诺等级）
- 1 条针对此界面核心目的的标准

Use `AskUserQuestion` to confirm:
- "Do these acceptance criteria cover what would make this screen 'done' for your QA process?"
- Options: "Yes — these are solid", "Add one more criterion", "Remove or rephrase one"

使用 `AskUserQuestion` 确认：
- “这些验收标准是否覆盖了在你的 QA 流程中让此界面‘完成’所需的内容？”
- 选项：“是——这些足够扎实”、“再加一条标准”、“删除或改写一条”
