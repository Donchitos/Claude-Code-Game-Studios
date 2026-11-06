> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.
> interaction-pattern-library.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

> Covers: **Navigation Patterns** (Screen Push / Pop / Replace, Focus Management, Escape / Cancel) and **Feedback and Loading Patterns** (Loading State, Empty State, Error State) — full reference specifications.
> 涵盖：**导航模式**（屏幕推入 / 弹出 / 替换、焦点管理、Esc / 取消）和**反馈与加载模式**（加载状态、空状态、错误状态）— 完整参考规格。

## Navigation Patterns
## 导航模式

---

#### Screen Push / Pop / Replace
#### 屏幕推入 / 弹出 / 替换

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

These three patterns define how screens enter and exit the navigation stack.
这三种模式定义屏幕如何进入和退出导航栈。

| Pattern | Trigger | Animation | Stack Behavior | Focus Behavior |
|---------|---------|-----------|---------------|----------------|
| Push | Navigate deeper (open submenu, open detail view) | New screen slides in from right. Previous screen slides left and dims. | Previous screen remains on stack | Focus moves to first interactive element on new screen |
| Pop (Back) | Back button / Escape / B / Circle | Current screen slides right and exits. Previous screen slides in from left and brightens. | Current screen removed from stack | Focus returns to the element that triggered the Push |
| Replace | Navigate to a peer screen (not child, not parent). Loading screen. | Fade out current, fade in new. No directional bias. | Current screen removed. New screen added. | Focus moves to first interactive element on new screen |

| 模式 | 触发 | 动画 | 栈行为 | 焦点行为 |
|---------|---------|-----------|---------------|----------------|
| 推入 | 深入导航（打开子菜单、打开详情视图） | 新屏幕从右侧滑入。前一个屏幕向左滑动并变暗。 | 前一个屏幕保留在栈中 | 焦点移到新屏幕上的第一个交互元素 |
| 弹出（返回） | 返回按钮 / Esc / B / Circle | 当前屏幕向右滑出。前一个屏幕从左侧滑入并变亮。 | 当前屏幕从栈中移除 | 焦点返回到触发推入的元素 |
| 替换 | 导航到同级屏幕（非子级、非父级）。加载屏幕。 | 当前淡出，新屏幕淡入。无方向偏向。 | 当前屏幕移除。新屏幕加入。 | 焦点移到新屏幕上的第一个交互元素 |

**Animation durations**: Push/Pop: 250ms ease-in-out. Replace: 200ms fade out + 200ms fade in.
**动画时长**：推入/弹出：250 毫秒缓入缓出。替换：200 毫秒淡出 + 200 毫秒淡入。

**Motion reduction**: All slide animations become fades. Duration reduces to 100ms.
**减少动态效果**：所有滑动动画变为淡入淡出。时长缩短至 100 毫秒。

**Implementation Notes**: [Godot: Implement as a `ScreenManager` singleton managing
a stack of `Control` scenes. `push(screen_scene)` instantiates and animates in.
`pop()` animates out and frees. `replace(screen_scene)` calls pop then push without
the intermediate stack state. Use `CanvasLayer` per screen to isolate input handling.
Store the "return focus" element reference before pushing so it can be restored on pop.]
**实现说明**：[Godot：实现为 `ScreenManager` 单例，管理 `Control` 场景栈。
`push(screen_scene)` 实例化并动画进入。`pop()` 动画退出并释放。
`replace(screen_scene)` 调用 pop 再 push，但不保留中间栈状态。每个屏幕使用 `CanvasLayer` 隔离输入处理。
推入前保存“返回焦点”元素引用，以便弹出时恢复。]

---

#### Focus Management
#### 焦点管理

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

> Focus management is the most common keyboard and gamepad accessibility failure
> in game UIs. These rules must be implemented consistently. A player should
> never be in a state where they cannot see which element is focused, or where
> Tab/D-pad produces no visible result.
> 焦点管理是游戏 UI 中最常见的键盘和手柄无障碍失败点。这些规则必须一致地实现。
> 玩家绝不应处于看不到哪个元素获得焦点、或按 Tab/方向键没有任何可见结果的状态。

| Rule | Description |
|------|-------------|
| Screen open | Focus is placed on the most logical interactive element — typically the Primary button, the first list item, or the last-focused element if the screen was previously visited. Never on a non-interactive element. |
| Screen close / pop | Focus returns to the element that triggered the navigation (the button that opened the screen, the list item that was selected). If that element no longer exists, focus goes to the nearest preceding interactive element. |
| Modal open | Focus is trapped inside the modal. See Modal Dialog pattern. |
| Modal close | Focus returns to the element that triggered the modal. |
| Element disabled | If the focused element becomes disabled, focus moves to the next available interactive element in the tab order. |
| Element destroyed | If the focused element is removed from the scene, focus moves to the nearest preceding element in the tab order. |
| Screen without interactive elements | Focus management is a no-op. Ensure back/cancel input still works. |
| Tab key (keyboard) | Moves focus forward through interactive elements in document order (left to right, top to bottom). Shift+Tab moves backward. |
| D-pad (gamepad) | Moves focus in the spatial direction pressed. Spatial navigation is preferred over strict tab order for gamepad. Never wrap focus between unrelated regions (e.g., Tab bar and content area should be separate navigation regions). |
| Focus is always visible | Focus ring or equivalent focus indicator must ALWAYS be visible when an element is focused via keyboard or gamepad. Never suppress focus indicators. |

| 规则 | 描述 |
|------|-------------|
| 屏幕打开 | 焦点置于最合理的交互元素 — 通常是主按钮、第一个列表项，或若此前访问过该屏幕，则为上次聚焦的元素。绝不置于非交互元素。 |
| 屏幕关闭 / 弹出 | 焦点返回到触发导航的元素（打开该屏幕的按钮、被选中的列表项）。若该元素已不存在，焦点移到标签顺序中最近的前一个交互元素。 |
| 模态打开 | 焦点被困在模态内部。参见模态对话框模式。 |
| 模态关闭 | 焦点返回到触发模态的元素。 |
| 元素禁用 | 若获得焦点的元素变为禁用，焦点移到标签顺序中下一个可用的交互元素。 |
| 元素销毁 | 若获得焦点的元素从场景中移除，焦点移到标签顺序中最近的前一个元素。 |
| 无交互元素的屏幕 | 焦点管理为空操作。确保返回/取消输入仍有效。 |
| Tab 键（键盘） | 按文档顺序（从左到右、从上到下）向前移动焦点。Shift+Tab 向后移动。 |
| 方向键（手柄） | 按按下的空间方向移动焦点。手柄更偏好空间导航而非严格标签顺序。绝不要在不相关区域之间循环焦点（例如，标签栏和内容区应是独立的导航区域）。 |
| 焦点始终可见 | 当元素通过键盘或手柄获得焦点时，焦点环或等效焦点指示必须**始终**可见。绝不抑制焦点指示。 |

---

#### Escape / Cancel
#### Esc / 取消

**Category**: Navigation
**Status**: Draft
**类别**：导航
**状态**：草稿

> The "go back" action is the most-used navigation input in all menu systems.
> It must be consistent across every screen with no exceptions.
> “返回”操作是所有菜单系统中最常用的导航输入。它必须在每个屏幕上保持一致，无一例外。

| Platform | Input | Behavior |
|----------|-------|---------|
| PC (keyboard) | Escape | Close top-most modal / go back one screen in stack / if at root screen (main menu), open "quit?" confirmation |
| PC (gamepad) | B (Xbox layout) / Circle (PS layout) | Same as Escape |
| Xbox | B button | Same as Escape |
| PlayStation | Circle button | Same as Escape |
| Nintendo Switch | B button | Same as Escape (NOTE: Nintendo uses B for confirm in some first-party titles — verify platform convention for this release and document the decision) |

| 平台 | 输入 | 行为 |
|----------|-------|---------|
| PC（键盘） | Esc | 关闭最上层模态 / 回到栈中上一个屏幕 / 若在根屏幕（主菜单），打开“退出？”确认 |
| PC（手柄） | B（Xbox 布局）/ Circle（PS 布局） | 同 Esc |
| Xbox | B 按钮 | 同 Esc |
| PlayStation | Circle 按钮 | 同 Esc |
| Nintendo Switch | B 按钮 | 同 Esc（注意：任天堂在部分第一方游戏中用 B 确认 — 请核实本次发布的平台惯例并记录该决定） |

**Rules**: This input must never be overridden to do something other than "go back / cancel." If a screen has no back action (e.g., the game is paused and the player must make a choice), Escape does nothing or shows a "you must choose" message — it does not navigate away. Every screen must define its Escape behavior explicitly in its UX spec.
**规则**：此输入绝不能被重写为执行“返回 / 取消”以外的事情。若屏幕没有返回动作（例如，游戏已暂停且玩家必须做出选择），
Esc 无任何效果，或显示“你必须选择”的消息 — 它不会导航离开。每个屏幕都必须在其 UX 规格中明确定义其 Esc 行为。

---

## Feedback and Loading Patterns
## 反馈与加载模式

---

#### Loading State
#### 加载状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

| Scope | Pattern | Notes |
|-------|---------|-------|
| Full screen (initial load) | Full-screen loading screen with game art, progress bar (determinate if possible), tip text (optional). | Never use an empty black screen. Give the player something to read or look at. |
| Full screen (level transition) | Fade to black, loading screen, fade from black to new scene. | The fade removes the pop of the previous scene disappearing. |
| Component / inline | Spinner or skeleton placeholder replaces the loading component. Component does not shift layout when content loads. | Skeleton placeholder (grey boxes approximating content shape) is preferable to spinner for layout-heavy content — it prevents layout shift on load. |
| Background / async | No visual indication unless operation exceeds 2 seconds. After 2 seconds, show a small spinner or toast. | Do not show loading indicators for operations that complete in under 2 seconds — the flash of an indicator is more disruptive than waiting. |

| 范围 | 模式 | 备注 |
|-------|---------|-------|
| 全屏（初始加载） | 带游戏美术、进度条（尽可能确定型）、提示文字（可选）的全屏加载屏幕。 | 绝不使用空的黑屏。给玩家一些可读或可看的内容。 |
| 全屏（关卡过渡） | 淡出至黑、加载屏幕、从黑淡入新场景。 | 淡入淡出消除了前一个场景消失时的突兀感。 |
| 组件 / 内联 | 用旋转指示器或骨架占位替代加载组件。内容加载时组件不引起布局位移。 | 对布局较重的内容，骨架占位（近似内容形状的灰色方块）优于旋转指示器 — 它防止加载时布局位移。 |
| 后台 / 异步 | 除非操作超过 2 秒，否则无视觉指示。2 秒后显示小旋转指示器或 toast。 | 不要在 2 秒内完成的操作上显示加载指示 — 指示器一闪而过比等待更具干扰性。 |

**Accessibility**: Loading states must announce to screen readers: "[Context] loading, please wait." Completion must announce "[Context] loaded." For full-screen loading, ensure the loading screen itself is navigable to screen readers — the tips text and any UI elements must be exposed.
**无障碍**：加载状态必须向屏幕阅读器播报：“[上下文] 正在加载，请稍候。”完成时必须播报“[上下文] 已加载。”
对于全屏加载，确保加载屏幕本身可被屏幕阅读器导航 — 提示文字和任何 UI 元素都必须暴露。

---

#### Empty State
#### 空状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

> Empty states are consistently the least-designed parts of game UIs. They are
> the difference between a player feeling "this is where I'll store my items"
> and "why is nothing here? did something break?" Every empty list and grid must
> have a designed empty state. The empty state is not an error — it is a starting
> point.
> 空状态始终是游戏 UI 中最缺乏设计的部分。它们决定了玩家感受是“这是我存放物品的地方”
> 还是“为什么这里什么都没有？是不是出故障了？”每个空列表和网格都必须有经过设计的空状态。
> 空状态不是错误 — 它是起点。

| Location | Empty State Content | Notes |
|----------|--------------------|----|
| Inventory (no items) | Icon (subtle, large, centered). Message: "Your inventory is empty." Sub-message: "Items you find on your journey will appear here." | Do not say "No items found" — "found" implies a failed search. |
| Quest Log (no active quests) | Icon. Message: "No active quests." Sub-message: "Talk to characters marked with [quest marker icon] to start a quest." | Give the player a clear action. |
| Achievements (none earned) | Icon. Message: "No achievements yet." List of hint achievements: "Try [Action] to earn your first achievement." | Gamified motivation, not just emptiness. |
| Search results (no matches) | Icon. Message: "No results for '[search term]'." Sub-message: "Try a different search or [browse all]." | Mirror the search term back at them. Give an alternative action. |

| 位置 | 空状态内容 | 备注 |
|----------|--------------------|----|
| 库存（无物品） | 图标（细微、大、居中）。消息：“你的库存是空的。”子消息：“你在旅途中找到的物品将出现在这里。” | 不要说“未找到物品” — “找到”暗示搜索失败。 |
| 任务日志（无活跃任务） | 图标。消息：“没有活跃任务。”子消息：“与标有 [任务标记图标] 的角色交谈以开始任务。” | 给玩家一个清晰的动作。 |
| 成就（尚未获得） | 图标。消息：“还没有成就。”提示成就列表：“尝试 [动作] 获得你的第一个成就。” | 游戏化的动机，而不仅仅是空无。 |
| 搜索结果（无匹配） | 图标。消息：“没有 '[搜索词]' 的结果。”子消息：“尝试其他搜索或 [浏览全部]。” | 向他们回显搜索词。给出一个替代动作。 |

**Rule**: Every empty state must include an icon, a message, and either a sub-message or an action button. A blank container with no explanation is never acceptable.
**规则**：每个空状态都必须包含图标、消息，以及子消息或动作按钮之一。没有任何解释的空白容器永远不可接受。

---

#### Error State
#### 错误状态

**Category**: Feedback
**Status**: Draft
**类别**：反馈
**状态**：草稿

| Error Type | Pattern | Tone |
|-----------|---------|------|
| Input validation (form field) | Inline error message below the field. Error icon left of message. Red border on field (colorblind-safe with icon). | Neutral and specific — "Username must be 3-20 characters." Not "Invalid input." |
| Operation failed (save error, network error) | Toast notification for non-critical failures. Modal Dialog for critical failures (save file cannot be written). | Calm and actionable — "Save failed. Check storage space." Not "FATAL ERROR." |
| System error (crash, data corruption) | Full-screen error screen with error code, recovery options ("Restart Game," "Load last save"), and support contact. | Reassuring — acknowledge the problem, give the player agency. Never blame the player. |
| Soft error (action cannot be performed) | Toast or inline message. | Explanatory — "Not enough gold" not "Action unavailable." |

| 错误类型 | 模式 | 语气 |
|-----------|---------|------|
| 输入校验（表单字段） | 字段下方的内联错误消息。错误图标在消息左侧。字段红色边框（配合图标实现色盲安全）。 | 中性且具体 — “用户名必须为 3-20 个字符。”而非“无效输入”。 |
| 操作失败（存档错误、网络错误） | 非关键失败用 toast 通知。关键失败（存档文件无法写入）用模态对话框。 | 平静且可操作 — “存档失败。请检查存储空间。”而非“致命错误”。 |
| 系统错误（崩溃、数据损坏） | 全屏错误屏幕，包含错误代码、恢复选项（“重启游戏”、“读取上次存档”）和支持联系方式。 | 令人安心 — 承认问题，给予玩家掌控感。绝不责怪玩家。 |
| 软错误（动作无法执行） | Toast 或内联消息。 | 解释性 — “金币不足”而非“动作不可用”。 |

**Principle**: Error messages are never the player's fault. They are the game telling the player what happened and what to do next. Remove the word "invalid" from all error messages — replace with specific explanations.
**原则**：错误消息永远不是玩家的错。它们是游戏在告诉玩家发生了什么以及接下来该做什么。
从所有错误消息中删除“无效”一词 — 用具体解释替代。

---
