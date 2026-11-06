> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.
> interaction-pattern-library.md 的编写指南。仅加载当前正在编写章节所对应的部分 — 不要一次性加载整个文件。

> Covers: **Standard Control Patterns** — full reference specifications for Button (Primary/Secondary/Destructive), Toggle, Slider, Dropdown / Select, List Item, Grid Item, Modal Dialog, Confirmation Dialog, Toast / Notification, Tooltip, Progress Bar, Input Field, Tab Bar, Scroll Container.
> 涵盖：**标准控件模式** — 按钮（主要/次要/破坏性）、开关、滑块、下拉 / 选择、列表项、网格项、模态对话框、确认对话框、轻提示 / 通知、工具提示、进度条、输入框、标签栏、滚动容器的完整参考规格。

## Standard Control Patterns
## 标准控件模式

---

#### Button (Primary)
#### 按钮（主要）

**Category**: Input
**Status**: Draft
**When to Use**: The single most important action on a screen. "Start Game,"
"Confirm," "Accept," "Buy." There should be at most one Primary button visible
at a time. It is the answer to "what does the player most likely want to do here?"
**When NOT to Use**: Alternative or secondary actions; destructive actions that
require confirmation before the consequence is irreversible; any action that is
not the primary intent of the screen.
**类别**：输入
**状态**：草稿
**何时使用**：屏幕上最重要的单一操作。“开始游戏”、“确认”、“接受”、“购买”。同一时刻最多只能有一个主要按钮可见。它回答的是“玩家在此最可能想做什么？”
**何时不要使用**：替代性或次要操作；在后果不可逆之前需要确认的破坏性操作；任何并非该屏幕主要意图的操作。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Full-opacity fill, primary color from art-bible. Label centered. | — | — | — | — |
| Hovered (mouse) | Brightness +15%, subtle scale 1.03x, cursor changes to pointer | Mouse over element | Transition from Default | 80ms ease-out | [UI hover sound — see Sound Standards] |
| Focused (keyboard/gamepad) | Focus ring visible (2px, offset 3px, high contrast color). Same brightness as Hovered. | Tab / D-pad navigation | Transition from Default | 80ms ease-out | [UI focus sound — same as hover] |
| Pressed | Scale 0.97x, brightness -10% | Click / Enter / A (Xbox) / Cross (PS) | Action fires on press-up, not press-down. Scale on press-down. | 60ms ease-in for press; 80ms ease-out on release | [UI confirm sound] |
| Disabled | 40% opacity, no pointer cursor, no hover state | — | No response | — | — |
| Loading (post-press) | Replace label with spinner. Button remains at pressed scale, disabled state. | — | Prevents double-submission | Duration of async operation | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 完全不透明填充，主要颜色取自美术规范（art-bible）。标签居中。 | — | — | — | — |
| 悬停（鼠标） | 亮度 +15%，轻微缩放 1.03 倍，光标变为指针 | 鼠标悬停于元素 | 从默认状态过渡 | 80ms 缓出 | [UI 悬停音效 — 见音效标准] |
| 聚焦（键盘/手柄） | 焦点环可见（2px，偏移 3px，高对比度颜色）。亮度与悬停相同。 | Tab / 方向键导航 | 从默认状态过渡 | 80ms 缓出 | [UI 聚焦音效 — 与悬停相同] |
| 按下 | 缩放 0.97 倍，亮度 -10% | 点击 / Enter / A（Xbox）/ Cross（PS） | 动作在松开时触发，而非按下时。缩放在按下时发生。 | 按下 60ms 缓入；松开 80ms 缓出 | [UI 确认音效] |
| 禁用 | 40% 不透明度，无指针光标，无悬停状态 | — | 无响应 | — | — |
| 加载中（按下后） | 标签替换为旋转指示器。按钮保持按下缩放并处于禁用状态。 | — | 防止重复提交 | 异步操作时长 | — |

**Accessibility**:
- Keyboard: Tab to focus, Enter or Space to activate. Must be reachable from any other interactive element on screen via Tab sequence.
- Gamepad: D-pad or left stick to navigate focus to button. A (Xbox) / Cross (PS) to activate. Focus must be placed on Primary button by default when screen opens.
- Screen reader: Button must expose accessible name matching visible label. Role: "button." State: "dimmed" when disabled. Activation announcement: "[Label] button — [result of action, if known]."
- Colorblind: Do not rely on color alone to distinguish Primary from Secondary. Primary uses higher visual weight (fill vs. outline, or larger size) in addition to color differentiation.
- Minimum touch target: 44x44pt (iOS HIG) / 48x48dp (Android). Apply even on PC if touch support is possible.
**无障碍**：
- 键盘：Tab 聚焦，Enter 或 Space 激活。必须能通过 Tab 序列从屏幕上任何其他可交互元素到达。
- 手柄：方向键或左摇杆将焦点移到按钮。A（Xbox）/ Cross（PS）激活。屏幕打开时，焦点必须默认落在主要按钮上。
- 屏幕阅读器：按钮必须暴露与可见标签匹配的可访问名称。角色："button"。状态：禁用时为"dimmed"。激活播报："[标签] 按钮 — [动作结果，若已知]。"
- 色盲：不要仅依靠颜色区分主要与次要。主要按钮除颜色差异外，还使用更高的视觉权重（填充对比描边，或更大尺寸）。
- 最小触摸目标：44x44pt（iOS HIG）/ 48x48dp（Android）。即使 PC 上可能支持触摸，也应适用。

**Implementation Notes**:
[Godot: Extend `Button` control. Override `_draw()` for custom states rather than
modifying themes mid-state. Use `focus_mode = FOCUS_ALL` to ensure keyboard
focusability. Set `mouse_default_cursor_shape = CURSOR_POINTING_HAND`. For the
scale animation, use a Tween on the `scale` property of the button's parent
Control — scaling the Button itself can clip children.]

**实现说明**：
[Godot：扩展 `Button` 控件。通过重写 `_draw()` 实现自定义状态，而不是在状态中途修改主题。使用 `focus_mode = FOCUS_ALL` 确保键盘可聚焦。设置 `mouse_default_cursor_shape = CURSOR_POINTING_HAND`。缩放动画请对按钮父级 Control 的 `scale` 属性使用 Tween — 直接缩放 Button 自身可能会裁剪子节点。]

---

#### Button (Secondary)
#### 按钮（次要）

**Category**: Input
**Status**: Draft
**When to Use**: Alternative or cancel action. "Back," "Cancel," "Skip," "Maybe
Later." Lower visual weight than Primary — it should recede visually, not compete.
**When NOT to Use**: Destructive actions (use Button (Destructive)). The most
important action on the screen (use Button (Primary)).
**类别**：输入
**状态**：草稿
**何时使用**：替代性或取消操作。“返回”、“取消”、“跳过”、“稍后再说”。视觉权重低于主要按钮 — 它应在视觉上退后，而非与之竞争。
**何时不要使用**：破坏性操作（使用破坏性按钮）。屏幕上最重要的操作（使用主要按钮）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Outlined style (border only, transparent fill), secondary color. Slightly smaller or lower weight than Primary. | — | — | — | — |
| Hovered | Background fill appears at 15% opacity. Border brightens. Scale 1.02x. | Mouse over | Transition from Default | 80ms ease-out | [UI hover sound — softer variant than Primary] |
| Focused | Focus ring, same specification as Primary. | Tab / D-pad | Transition from Default | 80ms ease-out | [UI focus sound] |
| Pressed | Scale 0.97x, fill opacity increases to 30% | Click / Enter / B (Xbox) / Circle (PS) on focused state | Action fires on press-up | 60ms ease-in | [UI cancel/back sound] |
| Disabled | 40% opacity | — | No response | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 描边样式（仅边框，透明填充），次要颜色。比主要按钮略小或权重更低。 | — | — | — | — |
| 悬停 | 背景填充以 15% 不透明度出现。边框变亮。缩放 1.02 倍。 | 鼠标悬停 | 从默认状态过渡 | 80ms 缓出 | [UI 悬停音效 — 比主要按钮更柔和的变体] |
| 聚焦 | 焦点环，规格与主要按钮相同。 | Tab / 方向键 | 从默认状态过渡 | 80ms 缓出 | [UI 聚焦音效] |
| 按下 | 缩放 0.97 倍，填充不透明度增至 30% | 聚焦状态下点击 / Enter / B（Xbox）/ Circle（PS） | 动作在松开时触发 | 60ms 缓入 | [UI 取消/返回音效] |
| 禁用 | 40% 不透明度 | — | 无响应 | — | — |

**Accessibility**: Same requirements as Button (Primary). Accessible name must
match visible label. In a dialog with Primary and Secondary buttons, the Secondary
button typically maps to the platform "cancel" input (B / Circle / Escape) as well
as direct focus activation.
**无障碍**：要求与主要按钮相同。可访问名称必须
与可见标签匹配。在同时具有主要与次要按钮的对话框中，次要
按钮通常映射到平台的“取消”输入（B / Circle / Escape），
同时也可通过直接聚焦激活。

**Implementation Notes**: [Same as Button (Primary). Where a Primary and Secondary
appear together, ensure Secondary is always positioned consistently — right/bottom
of Primary on horizontal layouts, or below Primary on vertical layouts. Consistency
across screens is more important than per-screen aesthetic preference.]
**实现说明**：[与主要按钮相同。当主要与次要按钮
同时出现时，确保次要按钮始终位置一致 — 横向布局中位于主要按钮
右侧/下方，纵向布局中位于主要按钮下方。跨屏幕的一致性
比单屏的审美偏好更重要。]

---

#### Button (Destructive)
#### 按钮（破坏性）

**Category**: Input
**Status**: Draft
**When to Use**: Any action that is irreversible and causes loss of player data or
significant progress: "Delete Save File," "Reset All Settings," "Leave Match,"
"Discard Changes." The visual treatment signals danger before the player presses.
**When NOT to Use**: Actions that can be undone, or actions that are merely
consequential but reversible.
**类别**：输入
**状态**：草稿
**何时使用**：任何不可逆且会造成玩家数据或重要进度丢失的操作：“删除存档”、“重置所有设置”、“离开比赛”、“放弃更改”。视觉处理在玩家按下之前就传递危险信号。
**何时不要使用**：可以撤销的操作，或仅仅后果重大但可逆的操作。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Outlined or filled with destructive color (typically a desaturated red — confirm colorblind compatibility in accessibility-requirements). Label may include a warning icon. | — | — | — | — |
| Hovered / Focused | Same behavior as Button (Primary) hover/focus but with destructive color | — | — | 80ms | [UI hover sound] |
| Pressed (first press) | Does NOT execute the action. Instead, opens Confirmation Dialog pattern (see below). The button itself shows a brief pulse animation. | Click / Enter | Trigger Confirmation Dialog | 100ms pulse | [UI warning sound — distinct from standard confirm] |
| — | Confirmation Dialog handles the actual execution | — | — | — | — |
| Disabled | 40% opacity | — | No response | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 描边或用破坏性颜色填充（通常是低饱和红 — 在无障碍需求文档中确认色盲兼容性）。标签可包含警告图标。 | — | — | — | — |
| 悬停 / 聚焦 | 行为与主要按钮的悬停/聚焦相同，但使用破坏性颜色 | — | — | 80ms | [UI 悬停音效] |
| 按下（首次按下） | 不执行该动作。而是打开确认对话框模式（见下文）。按钮本身显示短暂的脉冲动画。 | 点击 / Enter | 触发确认对话框 | 100ms 脉冲 | [UI 警告音效 — 区别于标准确认音效] |
| — | 确认对话框负责实际执行 | — | — | — | — |
| 禁用 | 40% 不透明度 | — | 无响应 | — | — |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly.
> It always triggers a Confirmation Dialog. There are no exceptions. A player
> who presses it by accident must always have one more opportunity to back out.
> Games that skip confirmation on destructive actions generate the most visible
> negative community sentiment of any UX failure type. See: every "accidentally
> deleted save file" complaint on any game forum.

> **关键规则**：破坏性按钮绝不直接执行其动作。
> 它始终触发确认对话框。没有例外。玩家
> 若误按，必须始终还有一次退出的机会。
> 对破坏性操作跳过确认的游戏，会引发所有 UX 失败类型中最显眼的
> 负面社区情绪。参见：任何游戏论坛上每一条“误删存档”的抱怨。

**Accessibility**: Screen reader must announce the destructive nature: "[Label] button — this action cannot be undone." In addition to accessible name, use the `description` property if available to add the warning text.
**无障碍**：屏幕阅读器必须播报其破坏性：“[标签] 按钮 — 此操作无法撤销。” 除可访问名称外，若可用，还应使用 `description` 属性添加警告文本。

**Implementation Notes**: [Destructive button triggers a separate Confirmation Dialog scene. Pass the action callback to the dialog — the button itself does not hold the execution logic. This separation prevents accidental execution if the confirmation dialog has a bug.]
**实现说明**：[破坏性按钮触发一个独立的确认对话框场景。将动作回调传给对话框 — 按钮本身不持有执行逻辑。这种分离可防止在确认对话框存在缺陷时误执行。]

---

#### Toggle
#### 开关

**Category**: Input
**Status**: Draft
**When to Use**: Binary on/off settings where both states are equally valid and
the current state must be visible at a glance. "Subtitles: On/Off," "Aim Assist:
On/Off," "Notifications: On/Off."
**When NOT to Use**: Selections from more than two options (use Dropdown). Actions
that happen once rather than representing a persistent state (use Button). Cases
where the consequence of toggling is complex enough to need explanation (show
a description field alongside).
**类别**：输入
**状态**：草稿
**何时使用**：两种状态同样有效的二元开/关设置，且当前状态必须一眼可见。“字幕：开/关”、“瞄准辅助：开/关”、“通知：开/关”。
**何时不要使用**：从两个以上选项中做选择（使用下拉）。仅发生一次而非代表持久状态的操作（使用按钮）。切换后果复杂到需要解释的情况（同时显示说明字段）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Off / Default | Track: muted fill. Thumb: leftmost position. Label: "Off" or state label. | — | — | — | — |
| Hovered | Track brightens 10%. Cursor: pointer. | Mouse over | Transition | 60ms | [UI hover sound] |
| Focused | Focus ring around entire toggle element (track + thumb). | Tab / D-pad | — | 60ms | [UI focus sound] |
| Pressed / Activated | Thumb slides to right side. Track fill changes to active color. Label changes to "On" or active state label. State persists. | Click / Enter / A / Cross | Toggle state change. Fire onChange event. Persist value. | 150ms ease-in-out for slide | [Toggle ON sound] |
| Pressed / Deactivated | Thumb slides to left. Track reverts to muted fill. | Same inputs | Toggle state change | 150ms ease-in-out | [Toggle OFF sound — subtly different from ON] |
| Disabled | 40% opacity. No interaction. Current state still visible. | — | No response | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 关闭 / 默认 | 轨道：柔和填充。滑块：最左位置。标签：“关闭”或状态标签。 | — | — | — | — |
| 悬停 | 轨道亮度 +10%。光标：指针。 | 鼠标悬停 | 过渡 | 60ms | [UI 悬停音效] |
| 聚焦 | 焦点环围绕整个开关元素（轨道 + 滑块）。 | Tab / 方向键 | — | 60ms | [UI 聚焦音效] |
| 按下 / 激活 | 滑块滑向右侧。轨道填充变为活动颜色。标签变为“开启”或活动状态标签。状态持久化。 | 点击 / Enter / A / Cross | 切换状态。触发 onChange 事件。持久化值。 | 滑动 150ms 缓入缓出 | [开关开启音效] |
| 按下 / 停用 | 滑块滑向左侧。轨道恢复柔和填充。 | 相同输入 | 切换状态 | 150ms 缓入缓出 | [开关关闭音效 — 与开启音效略有不同] |
| 禁用 | 40% 不透明度。无交互。当前状态仍可见。 | — | 无响应 | — | — |

**Accessibility**:
- Keyboard/Gamepad: Space or Enter to toggle. Avoid requiring directional inputs (left/right) to toggle — some users cannot predict that behavior.
- Screen reader: Role: "switch." State: "on" or "off" — the accessible name should NOT include the state (the screen reader announces state separately). Correct: accessible name "Subtitles," state "on." Incorrect: accessible name "Subtitles On."
- The toggle label (not just the visual thumb position) must change to show current state for players who cannot reliably distinguish left from right positions.
**无障碍**：
- 键盘/手柄：Space 或 Enter 切换。避免要求用方向输入（左/右）切换 — 部分用户无法预判该行为。
- 屏幕阅读器：角色："switch"。状态："on" 或 "off" — 可访问名称不应包含状态（屏幕阅读器会单独播报状态）。正确：可访问名称“字幕”，状态“on”。错误：可访问名称“字幕 开启”。
- 开关标签（而不仅是视觉滑块位置）必须变化以显示当前状态，服务于无法可靠区分左右位置的玩家。

**Implementation Notes**: [Godot: Use a custom Control or a CheckButton. The
built-in CheckButton provides accessibility role but uses a checkbox-style visual;
a custom slide-toggle animation may be needed for the target art style. Ensure
the slide animation is skipped when motion reduction mode is active — in that
case, snap to final state instantly.]
**实现说明**：[Godot：使用自定义 Control 或 CheckButton。内置 CheckButton 提供无障碍角色，但使用复选框风格的视觉；目标美术风格可能需要自定义滑动开关动画。确保在减弱动态效果模式激活时跳过滑动动画 — 该情况下直接跳到最终状态。]

---

#### Slider
#### 滑块

**Category**: Input
**Status**: Draft
**When to Use**: Selecting a value from a continuous range where approximate values
are acceptable and the range and relative position matter. Volume (0–100%), brightness,
text size. The visual representation of position is itself useful information.
**When NOT to Use**: Precise value entry (use Input Field). Selection from a short
discrete list (use Dropdown). Binary state (use Toggle).
**类别**：输入
**状态**：草稿
**何时使用**：从连续范围中选择值，近似值可接受，且范围与相对位置有意义。音量（0–100%）、亮度、文本大小。位置的可视化表示本身就是有用的信息。
**何时不要使用**：精确值输入（使用输入框）。从简短的离散列表中选择（使用下拉）。二元状态（使用开关）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Track (full width). Fill (left of thumb, shows current value). Thumb (draggable handle). Current value label (right of track or above thumb). | — | — | — | — |
| Hovered | Thumb enlarges slightly (1.2x). Track brightens. | Mouse over | — | 60ms | — |
| Focused | Focus ring on thumb. Track brightens. | Tab / D-pad | — | 60ms | [UI focus sound] |
| Dragging (mouse) | Thumb follows cursor. Fill updates in real time. Value label updates in real time. | Click + drag on thumb | Continuous value update. Fire onChange continuously. | Real time | [Slider adjust sound — subtle, loops while dragging] |
| Keyboard / D-pad adjust | Thumb moves one step (5% of range per press, or 1 discrete unit). | Left/Right arrows or Left/Right D-pad while focused | Step value change. Fire onChange per step. | Instant | [Slider step sound — one click per step] |
| Keyboard fast adjust | Larger step (25% of range). | Page Up / Page Down while focused | Large step value change | Instant | [Same step sound] |
| Released | Value locks. onChange fires final value. | Mouse release | — | — | — |
| Disabled | 40% opacity. No interaction. Value visible. | — | No response | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 轨道（全宽）。填充（滑块左侧，显示当前值）。滑块（可拖动手柄）。当前值标签（轨道右侧或滑块上方）。 | — | — | — | — |
| 悬停 | 滑块略微放大（1.2 倍）。轨道变亮。 | 鼠标悬停 | — | 60ms | — |
| 聚焦 | 滑块上有焦点环。轨道变亮。 | Tab / 方向键 | — | 60ms | [UI 聚焦音效] |
| 拖动（鼠标） | 滑块跟随光标。填充实时更新。值标签实时更新。 | 在滑块上点击 + 拖动 | 连续更新值。持续触发 onChange。 | 实时 | [滑块调节音效 — 细微，拖动时循环] |
| 键盘 / 方向键调节 | 滑块移动一步（每次按下为范围的 5%，或 1 个离散单位）。 | 聚焦时左/右方向键或方向键左/右 | 按步改变值。每步触发 onChange。 | 即时 | [滑块步进音效 — 每步一声] |
| 键盘快速调节 | 更大的步长（范围的 25%）。 | 聚焦时 Page Up / Page Down | 大步长改变值 | 即时 | [相同步进音效] |
| 松开 | 值锁定。onChange 触发最终值。 | 鼠标松开 | — | — | — |
| 禁用 | 40% 不透明度。无交互。值可见。 | — | 无响应 | — | — |

**Accessibility**:
- Keyboard: Left/Right arrows to adjust by small step. Page Up/Page Down for large step. Home/End to jump to min/max.
- Screen reader: Role: "slider." Accessible name: the label (e.g., "Music Volume"). Current value announced on every change: "Music Volume, 80 percent." Min/max values announced on first focus.
- All sliders must show a numeric value alongside the visual position. Relying only on track fill position excludes players who cannot perceive relative position.
**无障碍**：
- 键盘：左/右方向键以小步长调节。Page Up/Page Down 用于大步长。Home/End 跳至最小/最大值。
- 屏幕阅读器：角色："slider"。可访问名称：标签（例如“音乐音量”）。每次变化时播报当前值：“音乐音量，80%。” 首次聚焦时播报最小/最大值。
- 所有滑块必须在视觉位置旁显示数值。仅依靠轨道填充位置会排除无法感知相对位置的玩家。

**Implementation Notes**: [Godot `HSlider`: set `step` to appropriate increment.
Override keyboard input to add Page Up/Down support via `_input()`. Bind the
`value_changed` signal to update the displayed numeric label. When motion reduction
mode is enabled, ensure value label updates are the sole feedback — do not suppress
them. Rumble feedback on gamepad slider adjustment is a nice enhancement for
accessibility.]
**实现说明**：[Godot `HSlider`：将 `step` 设为合适的增量。通过 `_input()` 重写键盘输入以添加 Page Up/Down 支持。绑定 `value_changed` 信号以更新显示的数值标签。启用减弱动态效果模式时，确保值标签更新是唯一反馈 — 不要抑制它们。手柄调节滑块时的震动反馈是很好的无障碍增强。]

---

#### Dropdown / Select
#### 下拉 / 选择

**Category**: Input
**Status**: Draft
**When to Use**: Selection from a discrete list of 3-15 options where only the
selected value needs to be visible at rest. Display resolution, language, window
mode, input preset. The closed state shows only the current selection.
**When NOT to Use**: Binary choices (use Toggle). More than ~15 options (use a
full List pattern or a scrollable Select). When comparing options matters as much
as selecting one (show options visibly, e.g., as a horizontal selector or list).
**类别**：输入
**状态**：草稿
**何时使用**：从 3–15 个选项的离散列表中选择，静止时只需显示所选值。显示分辨率、语言、窗口模式、输入预设。关闭状态仅显示当前选择。
**何时不要使用**：二元选择（使用开关）。超过约 15 个选项（使用完整列表模式或可滚动选择器）。比较选项与选择选项同等重要时（将选项可见地展示，例如作为水平选择器或列表）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Closed / Default | Label (left). Current value (right). Chevron-down icon (far right). | — | — | — | — |
| Hovered | Row background fills at 10% opacity | Mouse over | — | 60ms | — |
| Focused (closed) | Focus ring on entire row. | Tab / D-pad | — | 60ms | [UI focus sound] |
| Opening | Dropdown list appears below (or above if near screen bottom). List items visible. Previously selected item highlighted. Focus moves to selected item inside list. | Click / Enter / A / Cross | Open list | 100ms ease-out (expand) | [UI expand sound] |
| List item hovered/focused | List item highlights | Mouse / D-pad | — | 60ms | [UI hover sound] |
| List item selected | List closes. Closed state shows new value. onChange event fires. | Click / Enter / A / Cross on item | Select value, close list | 80ms ease-in (collapse) | [UI confirm sound] |
| Dismissed without selecting | List closes. Value unchanged. | Escape / B / Circle / click outside | Dismiss | 80ms | [UI cancel sound] |
| Disabled | 40% opacity. No interaction. | — | — | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 关闭 / 默认 | 标签（左）。当前值（右）。向下箭头图标（最右）。 | — | — | — | — |
| 悬停 | 行背景以 10% 不透明度填充 | 鼠标悬停 | — | 60ms | — |
| 聚焦（关闭） | 焦点环围绕整行。 | Tab / 方向键 | — | 60ms | [UI 聚焦音效] |
| 打开 | 下拉列表出现在下方（若接近屏幕底部则出现在上方）。列表项可见。先前选中项高亮。焦点移到列表内选中项。 | 点击 / Enter / A / Cross | 打开列表 | 100ms 缓出（展开） | [UI 展开音效] |
| 列表项悬停/聚焦 | 列表项高亮 | 鼠标 / 方向键 | — | 60ms | [UI 悬停音效] |
| 列表项选中 | 列表关闭。关闭状态显示新值。触发 onChange 事件。 | 在项上点击 / Enter / A / Cross | 选择值，关闭列表 | 80ms 缓入（收起） | [UI 确认音效] |
| 未选择即关闭 | 列表关闭。值不变。 | Escape / B / Circle / 点击外部 | 关闭 | 80ms | [UI 取消音效] |
| 禁用 | 40% 不透明度。无交互。 | — | — | — | — |

**Accessibility**:
- Keyboard: Up/Down arrows navigate list items while open. Enter selects. Escape dismisses. First letter of an option jumps focus to first matching item.
- Screen reader: Role: "combobox." Accessible name: the field label. Expanded/collapsed state announced. Current value announced when focused. Each list item announces its value and position: "English, 1 of 12."
- The dropdown list must never obscure the current item or the control that opened it — this is a common failure on small screens.
**无障碍**：
- 键盘：打开时上/下方向键在列表项之间导航。Enter 选择。Escape 关闭。选项首字母将焦点跳至第一个匹配项。
- 屏幕阅读器：角色："combobox"。可访问名称：字段标签。播报展开/收起状态。聚焦时播报当前值。每个列表项播报其值及位置：“英语，第 1 项，共 12 项。”
- 下拉列表绝不能遮挡当前项或打开它的控件 — 这是小屏幕上常见的失败。

**Implementation Notes**: [Godot: Custom implementation using a `Button` (the
closed state) and a `PopupMenu` or a `VBoxContainer` revealed by animation. Native
`OptionButton` provides accessibility but limited visual customization. Ensure
the popup positions itself above the control if it would be clipped by the screen
bottom. Close the popup on `_input` detecting click outside its rect.]
**实现说明**：[Godot：使用 `Button`（关闭状态）和 `PopupMenu` 或通过动画显示的 `VBoxContainer` 进行自定义实现。原生 `OptionButton` 提供无障碍支持，但视觉自定义受限。确保弹出层在会被屏幕底部裁剪时自动定位到控件上方。在 `_input` 检测到点击其矩形外部时关闭弹出层。]

---

#### List Item
#### 列表项

**Category**: Layout / Input
**Status**: Draft
**When to Use**: A single selectable row in a vertically scrollable list. Achievements,
quest log entries, settings categories, save file slots. The list is the container;
this is the row within it.
**When NOT to Use**: Grid layouts where items exist in two dimensions (use Grid Item).
Non-selectable content rows (remove hover/focus states and the pressed state).
**类别**：布局 / 输入
**状态**：草稿
**何时使用**：垂直可滚动列表中的单个可选行。成就、任务日志条目、设置分类、存档槽位。列表是容器；这是其中的行。
**何时不要使用**：项目存在于二维网格中的布局（使用网格项）。不可选择的内容行（移除悬停/聚焦状态和按下状态）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Full-width row. Icon (optional, left). Primary label. Secondary label / metadata (right or below primary). Chevron (right, if navigates deeper). | — | — | — | — |
| Hovered | Row background at 12% opacity highlight. | Mouse over | — | 60ms | — |
| Focused | Focus ring on row OR row background at 20% opacity (consistent with platform convention). | D-pad / Tab | — | 60ms | [UI focus sound] |
| Selected (persistent) | Row background at 25% opacity. May show a selection indicator (left border, checkmark). Distinct from focused state — a row can be selected but not focused. | — | Rendered state | — | — |
| Pressed / Activated | Brief brightness flash, then navigates or performs action | Click / Enter / A / Cross | Navigation or action | 80ms flash | [UI confirm sound] |
| Disabled | 40% opacity. No interaction. | — | — | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 全宽行。图标（可选，左侧）。主标签。次标签 / 元数据（右侧或主标签下方）。箭头（右侧，若导航到更深层级）。 | — | — | — | — |
| 悬停 | 行背景以 12% 不透明度高亮。 | 鼠标悬停 | — | 60ms | — |
| 聚焦 | 行上有焦点环，或行背景以 20% 不透明度显示（与平台惯例一致）。 | 方向键 / Tab | — | 60ms | [UI 聚焦音效] |
| 选中（持久） | 行背景以 25% 不透明度显示。可显示选择指示（左边框、对勾）。区别于聚焦状态 — 一行可被选中但未聚焦。 | — | 渲染状态 | — | — |
| 按下 / 激活 | 短暂亮度闪烁，然后导航或执行动作 | 点击 / Enter / A / Cross | 导航或动作 | 80ms 闪烁 | [UI 确认音效] |
| 禁用 | 40% 不透明度。无交互。 | — | — | — | — |

**Accessibility**:
- Keyboard/Gamepad: Up/Down arrows or D-pad to move between list items. The list must handle focus cycling — reaching the bottom should stop (not wrap) unless wrapping is explicitly designed.
- Screen reader: Role: "listitem." Parent list role: "list." Accessible name: primary label content. Metadata (secondary label) is optionally included in the description. Position announced: "Quest Log, 3 of 12."
- Minimum row height: 44pt / 48dp for touch. For controller-primary platforms, 56px rows are more comfortable.
**无障碍**：
- 键盘/手柄：上/下方向键或方向键在列表项之间移动。列表必须处理焦点循环 — 到达底部应停止（不循环），除非明确设计了循环。
- 屏幕阅读器：角色："listitem"。父列表角色："list"。可访问名称：主标签内容。元数据（次标签）可选地包含在描述中。播报位置：“任务日志，第 3 项，共 12 项。”
- 最小行高：触摸用 44pt / 48dp。对于手柄为主的平台，56px 行更舒适。

**Implementation Notes**: [Godot: Use a `VBoxContainer` inside a `ScrollContainer`.
Each row is a custom `Control` or `PanelContainer` with a `_gui_input` override.
For keyboard navigation inside the scroll container, implement custom focus
traversal — Godot's default Tab navigation does not scroll the container to keep
focused items in view. Use `ensure_control_visible()` on the scroll container.]
**实现说明**：[Godot：在 `ScrollContainer` 内使用 `VBoxContainer`。每一行是自定义 `Control` 或 `PanelContainer`，并重写 `_gui_input`。对于滚动容器内的键盘导航，实现自定义焦点遍历 — Godot 默认的 Tab 导航不会滚动容器以保持聚焦项可见。在滚动容器上使用 `ensure_control_visible()`。]

---

#### Grid Item
#### 网格项

**Category**: Layout / Input
**Status**: Draft
**When to Use**: A selectable cell in a two-dimensional grid. Inventory slots,
ability select, crafting ingredient selection, character portrait selection. The
grid is the container; this is the cell.
**When NOT to Use**: Single-column content (use List Item). Non-selectable display
cells (remove interactive states).
**类别**：布局 / 输入
**状态**：草稿
**何时使用**：二维网格中的可选单元格。库存槽位、能力选择、制作材料选择、角色头像选择。网格是容器；这是单元格。
**何时不要使用**：单列内容（使用列表项）。不可选择的展示单元格（移除交互状态）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Empty | Empty slot visual (subtle border or dashed outline). Different from disabled. | — | — | — | — |
| Populated | Item icon fills cell. Stack count (bottom right, if applicable). Quality indicator (border color or icon overlay). | — | — | — | — |
| Hovered | Brightness +15%. Tooltip appears after 400ms delay. | Mouse over | — | 60ms | — |
| Focused | Focus ring (2px, offset 2px). Same brightness as hovered. Tooltip appears after 400ms delay or immediately on gamepad. | D-pad navigation | — | 60ms | [UI focus sound] |
| Selected (persistent) | Distinct border (thicker, contrasting color). May show selection checkmark. | Click / Enter / A / Cross | Select item. Can coexist with focused state on a different cell. | Instant | [UI select sound] |
| Pressed | Brief scale 0.95x, then executes action | Double-click / Enter / A / Cross | Action (equip, use, inspect — defined by context) | 80ms | [UI confirm sound] |
| Locked | Padlock overlay icon on populated content. No hover/focus states. | — | No interaction | — | — |
| Drag source | Cell dims (50% opacity), drag preview appears at cursor. | Click + drag (mouse only) | Begin drag operation | Instant | [UI grab sound] |
| Drop target (valid) | Cell brightens, accepting color indicator | Item dragged over | — | 60ms | — |
| Drop target (invalid) | Red tint or shake animation | Item dragged over invalid slot | — | 60ms | [UI error sound] |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 空 | 空槽位视觉（细微边框或虚线轮廓）。区别于禁用状态。 | — | — | — | — |
| 已填充 | 物品图标填满单元格。堆叠数量（右下，如适用）。品质指示（边框颜色或图标叠加）。 | — | — | — | — |
| 悬停 | 亮度 +15%。工具提示在 400ms 延迟后出现。 | 鼠标悬停 | — | 60ms | — |
| 聚焦 | 焦点环（2px，偏移 2px）。亮度与悬停相同。工具提示在 400ms 延迟后出现，手柄上则立即出现。 | 方向键导航 | — | 60ms | [UI 聚焦音效] |
| 选中（持久） | 独特边框（更粗、对比色）。可显示选中对勾。 | 点击 / Enter / A / Cross | 选择物品。可与另一单元格的聚焦状态共存。 | 即时 | [UI 选择音效] |
| 按下 | 短暂缩放 0.95 倍，然后执行动作 | 双击 / Enter / A / Cross | 动作（装备、使用、查看 — 由上下文定义） | 80ms | [UI 确认音效] |
| 锁定 | 已填充内容上有挂锁叠加图标。无悬停/聚焦状态。 | — | 无交互 | — | — |
| 拖拽源 | 单元格变暗（50% 不透明度），拖拽预览出现在光标处。 | 点击 + 拖动（仅鼠标） | 开始拖拽操作 | 即时 | [UI 抓取音效] |
| 放置目标（有效） | 单元格变亮，接受颜色指示 | 物品拖过 | — | 60ms | — |
| 放置目标（无效） | 红色着色或抖动动画 | 物品拖过无效槽位 | — | 60ms | [UI 错误音效] |

**Accessibility**:
- Keyboard/Gamepad: D-pad or arrow keys navigate cells. The grid must communicate its dimensions to screen readers. Row/column position announced.
- Screen reader: Role: "gridcell." Parent role: "grid." Accessible name: item name (or "empty slot" for empty cells). State: "selected" when selected, "dimmed" when locked. Position: "row 2, column 3."
- Tooltips must be reachable by keyboard — they must appear when the cell is focused, not only when hovered.
**无障碍**：
- 键盘/手柄：方向键或箭头键在单元格之间导航。网格必须向屏幕阅读器传达其尺寸。播报行/列位置。
- 屏幕阅读器：角色："gridcell"。父角色："grid"。可访问名称：物品名称（空单元格为“空槽位”）。状态：选中时为 "selected"，锁定时为 "dimmed"。位置：“第 2 行，第 3 列。”
- 工具提示必须可通过键盘到达 — 单元格聚焦时必须出现，而不仅是悬停时。

**Implementation Notes**: [Godot: `GridContainer` with fixed column count. Each
cell is a custom `Control`. Implement custom D-pad navigation by overriding
`_gui_input` and calculating the cell to the left/right/above/below based on
index and column count. `GridContainer` does not provide this natively.]
**实现说明**：[Godot：使用固定列数的 `GridContainer`。每个单元格是自定义 `Control`。通过重写 `_gui_input` 并根据索引与列数计算左/右/上/下的单元格，实现自定义方向键导航。`GridContainer` 原生不提供此功能。]

---

#### Modal Dialog
#### 模态对话框

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: A decision or acknowledgment that must be resolved before the
player can continue. The dialog is blocking — background content is dimmed and
non-interactive. "Are you sure?", "Your progress will be saved.", error states.
**When NOT to Use**: Non-blocking notifications (use Toast / Notification). Information
that can wait until the player is ready (add it to a persistent help system instead).
Dialogs that should allow the player to continue playing behind them.
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：必须解决后玩家才能继续的决策或确认。对话框是阻塞的 — 背景内容变暗且不可交互。“确定吗？”、“你的进度将被保存。”、错误状态。
**何时不要使用**：非阻塞通知（使用轻提示 / 通知）。可以等到玩家准备好再处理的信息（改为加入持久帮助系统）。应允许玩家在背后继续游戏的对话框。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Opening | Background overlay animates from 0 to 60% opacity. Dialog panel scales from 0.9 to 1.0. Dialog enters from center (not from an edge). | Triggered by code | Focus moves to first interactive element in dialog (or the Primary button) | 200ms ease-out | [UI modal open sound] |
| Active | Background non-interactive. Dialog has all input focus. Player cannot interact with background. | Keyboard / gamepad navigates within dialog only | — | — | — |
| Dismissing (confirmed) | Dialog panel scales to 1.1 then fades. Overlay fades to 0%. | Primary button pressed | Execute action, return focus to trigger element | 180ms | [UI confirm sound] |
| Dismissing (cancelled) | Dialog panel scales to 0.9 then fades. Overlay fades to 0%. | Secondary button / Escape / B / Circle | No action, return focus to trigger element | 150ms | [UI cancel sound] |
| Cannot dismiss | If the dialog represents a blocking error, do not provide a cancel path. Provide only resolution options. | — | — | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 打开 | 背景遮罩从 0 到 60% 不透明度动画。对话框面板从 0.9 缩放至 1.0。对话框从中心进入（而非从边缘）。 | 由代码触发 | 焦点移到对话框内首个可交互元素（或主要按钮） | 200ms 缓出 | [UI 模态打开音效] |
| 活动 | 背景不可交互。对话框拥有全部输入焦点。玩家无法与背景交互。 | 键盘 / 手柄仅在对话框内导航 | — | — | — |
| 关闭（已确认） | 对话框面板缩放至 1.1 后淡出。遮罩淡出至 0%。 | 主要按钮被按下 | 执行动作，焦点返回触发元素 | 180ms | [UI 确认音效] |
| 关闭（已取消） | 对话框面板缩放至 0.9 后淡出。遮罩淡出至 0%。 | 次要按钮 / Escape / B / Circle | 无动作，焦点返回触发元素 | 150ms | [UI 取消音效] |
| 不可关闭 | 若对话框代表阻塞性错误，不提供取消路径。仅提供解决选项。 | — | — | — | — |

> **Focus trap rule**: While a modal dialog is open, Tab and D-pad navigation
> must cycle within the dialog's interactive elements only. It must not be possible
> to navigate focus outside the dialog to the background content. This is both
> an accessibility requirement (WCAG 2.1 SC 2.1.2) and a UX integrity requirement.
> When the dialog closes, focus must return to the element that triggered it,
> not to the top of the page.

> **焦点陷阱规则**：模态对话框打开时，Tab 与方向键导航
> 必须仅在对话框的可交互元素内循环。必须不可能
> 将焦点导航到对话框外的背景内容。这既是
> 无障碍要求（WCAG 2.1 SC 2.1.2），也是 UX 完整性要求。
> 对话框关闭时，焦点必须返回到触发它的元素，
> 而不是页面顶部。

**Accessibility**:
- Screen reader: Dialog container role: "dialog." Accessible name: dialog title (required — every dialog must have a title, even if visually hidden). On open, screen reader announces dialog title and first focusable element. Focus trap active.
- Keyboard: Escape key always maps to the cancel/dismiss action (same as Secondary button or close button). Enter always maps to the primary/confirm action.
- Motion reduction: Scale animation replaced with instant appear/disappear. Overlay fade retained at 100ms (faster).
**无障碍**：
- 屏幕阅读器：对话框容器角色："dialog"。可访问名称：对话框标题（必需 — 每个对话框都必须有标题，即使视觉上隐藏）。打开时，屏幕阅读器播报对话框标题及首个可聚焦元素。焦点陷阱生效。
- 键盘：Escape 键始终映射到取消/关闭动作（与次要按钮或关闭按钮相同）。Enter 始终映射到主要/确认动作。
- 减弱动态效果：缩放动画替换为即时出现/消失。遮罩淡出保留为 100ms（更快）。

**Implementation Notes**: [Godot: Implement as a `CanvasLayer` with a high layer
value (100+) to ensure it renders above all game content. The background overlay
is a full-screen `ColorRect` at 60% black opacity. Use `grab_focus()` on the
dialog's primary button after the open animation completes. Override `_input()` to
implement the focus trap — intercept Tab navigation and reroute to the dialog's
focusable elements.]
**实现说明**：[Godot：实现为高图层值（100+）的 `CanvasLayer`，确保其渲染在所有游戏内容之上。背景遮罩是全屏 `ColorRect`，60% 黑色不透明度。打开动画完成后，对对话框的主要按钮使用 `grab_focus()`。重写 `_input()` 实现焦点陷阱 — 拦截 Tab 导航并重新路由到对话框的可聚焦元素。]

---

#### Confirmation Dialog
#### 确认对话框

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: The specific case of confirming a destructive action. Always
triggered by Button (Destructive). Always has exactly two options: confirm (labeled
with the specific action, not "OK") and cancel.
**When NOT to Use**: Non-destructive confirmations. Errors or notifications that
do not require a decision. Any dialog with more than two actions.
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：确认破坏性操作的特定情形。始终由破坏性按钮触发。始终恰好有两个选项：确认（以具体操作命名，而非“确定”）与取消。
**何时不要使用**：非破坏性确认。不需要决策的错误或通知。任何具有两个以上操作的对话框。

> **Label rule**: The confirm button must be labeled with the specific action,
> not a generic "OK" or "Yes." "Delete Save File" not "OK." "Leave Match" not
> "Yes." This reduces mistakes for players who have difficulty reading the dialog
> content quickly. The pattern comes from Apple HIG and is validated by decades
> of usability research.

> **标签规则**：确认按钮必须以具体操作命名，
> 而非通用的“确定”或“是”。“删除存档”而非“确定”。“离开比赛”而非
> “是”。这能减少难以快速阅读对话框内容的玩家
> 所犯的错误。该模式源自 Apple HIG，并经过数十年
> 可用性研究的验证。

**Structure**:
- Title: Brief, action-describing. "Delete save file?" not "Are you sure?"
- Body: One sentence stating the consequence. "This cannot be undone."
- Confirm button: Button (Primary) — labeled with the specific action. "Delete Save File."
- Cancel button: Button (Secondary) — "Cancel."
- Default focus: Cancel (safer default — reduces accidental destructive actions).
**结构**：
- 标题：简短、描述操作。“删除存档？”而非“确定吗？”
- 正文：一句话说明后果。“此操作无法撤销。”
- 确认按钮：主要按钮 — 以具体操作命名。“删除存档。”
- 取消按钮：次要按钮 — “取消。”
- 默认焦点：取消（更安全的默认 — 减少误触破坏性操作）。

**Accessibility**: Inherits all Modal Dialog accessibility. Additionally: screen
reader announces "Alert dialog, [title]" to signal destructive context. Default
focus on Cancel is a requirement, not a preference.
**无障碍**：继承所有模态对话框的无障碍要求。此外：屏幕
阅读器播报“警告对话框，[标题]”以标示破坏性上下文。默认
焦点在取消上是要求，而非偏好。

**Implementation Notes**: [Confirmation Dialog is a specific instance of Modal
Dialog — implement it as a subclass or as a parameterized scene. The default
focus on Cancel is critical: set `grab_focus()` on the Cancel button, not the
Confirm button, after open animation completes.]
**实现说明**：[确认对话框是模态对话框的特定实例 — 实现为子类或参数化场景。默认
焦点在取消上至关重要：打开动画完成后，对取消按钮而非
确认按钮设置 `grab_focus()`。]

---

#### Toast / Notification
#### 轻提示 / 通知

**Category**: Feedback
**Status**: Draft
**When to Use**: Brief, non-blocking information that does not require a player
decision. "Game saved." "Achievement unlocked." "Your inventory is full." The player
can continue playing; the notification disappears on its own.
**When NOT to Use**: Information that requires a decision (use Modal Dialog).
Errors that require the player to take action. Critical information that the player
must not miss.
**类别**：反馈
**状态**：草稿
**何时使用**：简短的、非阻塞的信息，不需要玩家决策。“游戏已保存。”、“成就解锁。”、“你的库存已满。” 玩家可以继续游戏；通知会自行消失。
**何时不要使用**：需要决策的信息（使用模态对话框）。需要玩家采取行动的错误。玩家绝不能错过的关键信息。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Entering | Slides in from screen edge (typically bottom-right, away from primary action areas). Fades from 0 to 100% opacity. | Triggered by code | — | 200ms ease-out | [Sound matching notification type — see Sound Standards] |
| Displayed | Full opacity. Optional: icon (left), title, body text (optional), dismiss button (X, optional). | Pointer hover pauses auto-dismiss timer | Pause auto-dismiss | — | — |
| Auto-dismiss | Fades from 100 to 0% opacity, slides out | Timer expires (5 seconds default for one-line; 8 seconds for two-line) | Remove from queue | 200ms ease-in | — |
| Manual dismiss | Fades and slides out immediately | Click/tap X button or swipe on touch | Remove | 150ms | [UI cancel sound, quiet] |
| Queue overflow | New notification pushes oldest out early | New notification triggered while previous is displayed | FIFO queue, max 3 simultaneous | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 进入 | 从屏幕边缘滑入（通常是右下，远离主要操作区域）。从 0 到 100% 不透明度淡入。 | 由代码触发 | — | 200ms 缓出 | [与通知类型匹配的音效 — 见音效标准] |
| 显示 | 完全不透明。可选：图标（左）、标题、正文文本（可选）、关闭按钮（X，可选）。 | 指针悬停暂停自动关闭计时器 | 暂停自动关闭 | — | — |
| 自动关闭 | 从 100 到 0% 不透明度淡出，滑出 | 计时器到期（单行默认 5 秒；双行 8 秒） | 从队列移除 | 200ms 缓入 | — |
| 手动关闭 | 立即淡出并滑出 | 点击/轻触 X 按钮或在触摸上滑动 | 移除 | 150ms | [UI 取消音效，轻柔] |
| 队列溢出 | 新通知提前将最旧的通知挤出 | 先前通知显示时触发新通知 | FIFO 队列，最多 3 个同时显示 | — | — |

**Accessibility**:
- Screen reader: Toasts must be read aloud without requiring focus. In HTML, this uses `role="status"` or `role="alert"`. In game UI, this requires the engine's accessibility notification system. Verify engine support in engine-reference docs.
- Motion reduction: Slide animation replaced with fade only.
- Toasts must never be the sole communication channel for information the player needs to act on. If the information requires action, use a persistent UI element in addition to the toast.
- Auto-dismiss timer: 5 seconds is the minimum. Players with cognitive processing differences may need more time. Consider a setting to extend to 10 or 15 seconds.
**无障碍**：
- 屏幕阅读器：轻提示必须无需焦点即可朗读。在 HTML 中，这使用 `role="status"` 或 `role="alert"`。在游戏 UI 中，这需要引擎的无障碍通知系统。在 engine-reference 文档中验证引擎支持。
- 减弱动态效果：滑入动画仅替换为淡入淡出。
- 轻提示绝不能作为玩家需要据此行动的信息的唯一传达渠道。若信息需要行动，除轻提示外还应使用持久 UI 元素。
- 自动关闭计时器：5 秒是最小值。认知处理方式不同的玩家可能需要更多时间。考虑提供延长至 10 或 15 秒的设置。

**Implementation Notes**: [Godot: Manage a queue of `PanelContainer` scenes in a
`VBoxContainer` anchored to a screen corner. Each toast is instantiated, added to
the container, then auto-removed after a timer. The container should be on a high
`CanvasLayer` (50+) but below modal dialogs (100+). Animate using a `Tween` on
`modulate.a` and `position.x`. When motion reduction is active, skip the position
animation.]
**实现说明**：[Godot：在锚定到屏幕角落的 `VBoxContainer` 中管理 `PanelContainer` 场景队列。每个轻提示被实例化、加入容器，然后在计时器到期后自动移除。容器应位于高 `CanvasLayer`（50+），但低于模态对话框（100+）。使用 `Tween` 对 `modulate.a` 和 `position.x` 进行动画。减弱动态效果激活时，跳过位置动画。]

---

#### Tooltip
#### 工具提示

**Category**: Feedback
**Status**: Draft
**When to Use**: Contextual information that supplements a visible label. Item
descriptions in inventory. Stat explanations on a character sheet. Setting
descriptions in accessibility options. The player must be able to access this
information or proceed without it.
**When NOT to Use**: Information the player MUST read to complete an action — put
that in the label or body text, not a tooltip. Tooltips are not discoverable
on mobile touch without a hover state. On touch-only platforms, use an info button
that opens a description modal instead.
**类别**：反馈
**状态**：草稿
**何时使用**：补充可见标签的上下文信息。库存中的物品描述。角色面板上的属性解释。无障碍选项中的设置描述。玩家必须能够访问此信息，或无需它也能继续。
**何时不要使用**：玩家必须阅读才能完成操作的信息 — 将其放入标签或正文文本，而非工具提示。在没有悬停状态的移动端触摸设备上，工具提示不可被发现。在仅触摸平台上，改用打开描述模态的信息按钮。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Hidden | — | — | — | — | — |
| Hover trigger | — | Mouse enters element | Begin 400ms delay timer | — | — |
| Gamepad/keyboard trigger | — | Element receives focus | Begin 300ms delay timer (shorter because navigation is intentional) | — | — |
| Appearing | Tooltip panel fades in and scales from 0.95 to 1.0. Positioned near element (prefer above, adjust if near screen edge). | Timer expires | Show tooltip | 120ms ease-out | — |
| Displayed | Tooltip visible. Title (optional). Body text. Max width: 300px. Multiple lines allowed. | — | — | — | — |
| Hiding | Tooltip fades out | Mouse leaves element / focus moves away | Hide tooltip | 80ms ease-in | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 隐藏 | — | — | — | — | — |
| 悬停触发 | — | 鼠标进入元素 | 开始 400ms 延迟计时器 | — | — |
| 手柄/键盘触发 | — | 元素获得焦点 | 开始 300ms 延迟计时器（更短，因为导航是有意的） | — | — |
| 出现 | 工具提示面板淡入并从 0.95 缩放至 1.0。定位在元素附近（优先上方，接近屏幕边缘时调整）。 | 计时器到期 | 显示工具提示 | 120ms 缓出 | — |
| 显示 | 工具提示可见。标题（可选）。正文文本。最大宽度：300px。允许多行。 | — | — | — | — |
| 隐藏中 | 工具提示淡出 | 鼠标离开元素 / 焦点移开 | 隐藏工具提示 | 80ms 缓入 | — |

**Accessibility**:
- Screen reader: Tooltip content must be accessible without hover. The accessible name of the parent element should include the most critical tooltip information. The full tooltip text is optionally in the `description` property. Screen reader reads tooltip content when element is focused.
- The delay (300-400ms) prevents accidental tooltip display and is required — instant tooltips are disruptive in gamepad navigation.
- Tooltip text must meet the same contrast requirements as body text (4.5:1 minimum).
**无障碍**：
- 屏幕阅读器：工具提示内容必须无需悬停即可访问。父元素的可访问名称应包含最关键的工具提示信息。完整工具提示文本可选地置于 `description` 属性中。元素聚焦时屏幕阅读器朗读工具提示内容。
- 延迟（300–400ms）可防止意外显示工具提示，是必需的 — 即时工具提示在手柄导航中具有干扰性。
- 工具提示文本必须满足与正文文本相同的对比度要求（最低 4.5:1）。

**Implementation Notes**: [Godot: Attach a custom `TooltipControl` scene as a
child of the trigger element. Show/hide with a `Timer` node. Position the tooltip
using a `CanvasLayer` to ensure it appears above all other UI. For screen edges,
detect if the tooltip rect extends beyond `get_viewport_rect()` and flip the
position to the opposite side.]
**实现说明**：[Godot：将自定义 `TooltipControl` 场景附加为触发元素的子节点。使用 `Timer` 节点显示/隐藏。使用 `CanvasLayer` 定位工具提示，确保其出现在所有其他 UI 之上。对于屏幕边缘，检测工具提示矩形是否超出 `get_viewport_rect()`，并将位置翻转到相反方向。]

---

#### Progress Bar
#### 进度条

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: Linear progress toward a defined endpoint. Loading screens (time
to completion), XP fill toward next level, quest objectives with countable progress
("3 of 10 enemies defeated"), download progress.
**When NOT to Use**: Circular or radial progress (use a separate Radial Progress
pattern if needed). Values that fluctuate up and down rapidly (use Health/Resource
Bar pattern). Values with no defined endpoint.
**类别**：反馈 / 布局
**状态**：草稿
**何时使用**：朝向已定义终点的线性进度。加载界面（完成时间）、距下一级的经验值填充、具有可计数进度的任务目标（“已击败 3/10 名敌人”）、下载进度。
**何时不要使用**：环形或径向进度（如需要，使用单独的径向进度模式）。快速上下波动的值（使用生命/资源条模式）。没有已定义终点的值。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Track (full width, background color). Fill (left to right, value color). Value label (percentage or N/M, outside or inside fill). | — | — | — | — |
| Value increasing | Fill width animates to new value | Value changes | Smooth fill animation | 300ms ease-out | [Context-dependent — XP gain has a sound; loading has none] |
| Value at maximum | Fill reaches full width. Optional: completion animation (pulse, glow). | Value reaches 100% | Completion event fires | 200ms | [Completion sound if appropriate] |
| Value at zero | Fill hidden (zero width). Track still visible. | — | — | — | — |
| Indeterminate (unknown duration) | Animated loop (fill segment moves left-to-right, repeat). Used for loading of unknown duration. | — | — | Infinite loop | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 轨道（全宽，背景色）。填充（从左到右，数值色）。值标签（百分比或 N/M，位于填充外或内）。 | — | — | — | — |
| 值增加 | 填充宽度动画到新值 | 值变化 | 平滑填充动画 | 300ms 缓出 | [视上下文而定 — 获得经验有音效；加载无音效] |
| 值达最大 | 填充达到全宽。可选：完成动画（脉冲、发光）。 | 值达到 100% | 触发完成事件 | 200ms | [如适用，完成音效] |
| 值为零 | 填充隐藏（零宽度）。轨道仍可见。 | — | — | — | — |
| 不确定（时长未知） | 动画循环（填充段从左向右移动，重复）。用于时长未知的加载。 | — | — | 无限循环 | — |

**Accessibility**:
- Screen reader: Role: "progressbar." Accessible name: what is progressing (e.g., "Experience Points," "Loading"). Value: current numeric value AND percentage AND maximum. "Experience Points, 450 of 1000, 45 percent." Update on significant changes (not every pixel).
- Do not rely only on fill color to communicate value. Include a numeric label.
- Indeterminate progress bars: announce "Loading, in progress" — do not announce changes since the value is unknown.
- Motion reduction: Indeterminate animation is replaced with a static "loading" indicator. Smooth fill animation is replaced with instant jump to new value.
**无障碍**：
- 屏幕阅读器：角色："progressbar"。可访问名称：正在进度的内容（例如“经验值”、“加载”）。值：当前数值、百分比和最大值。“经验值，450 / 1000，45%。” 在显著变化时更新（而非每个像素）。
- 不要仅依靠填充颜色传达数值。包含数值标签。
- 不确定进度条：播报“加载中，正在进行” — 由于值未知，不要播报变化。
- 减弱动态效果：不确定动画替换为静态“加载中”指示器。平滑填充动画替换为即时跳到新值。

**Implementation Notes**: [Godot: `ProgressBar` built-in with custom theming.
For indeterminate mode, `ProgressBar` does not have a native indeterminate state
in Godot 4.x — implement using a looping `Tween` on a fill element's position.
Ensure the Tween is paused when motion reduction mode is active and a static
indicator is shown instead.]
**实现说明**：[Godot：使用内置 `ProgressBar` 并自定义主题。对于不确定模式，`ProgressBar` 在 Godot 4.x 中没有原生不确定状态 — 通过对填充元素位置上的循环 `Tween` 实现。确保减弱动态效果模式激活时暂停 Tween，改为显示静态指示器。]

---

#### Input Field
#### 输入框

**Category**: Input
**Status**: Draft
**When to Use**: Text entry. Player name on a new save, search within a list,
remapping a key binding (special case — shows the key press, not typed text),
entering a numeric value precisely.
**When NOT to Use**: Selecting from known options (use Dropdown or List). On
console-primary platforms, minimize text entry — it requires a virtual keyboard,
which is high friction.
**类别**：输入
**状态**：草稿
**何时使用**：文本输入。新存档的玩家名称、列表内搜索、重新映射按键绑定（特殊情况 — 显示按键按下，而非键入文本）、精确输入数值。
**何时不要使用**：从已知选项中选取（使用下拉或列表）。在以主机为主的平台上，尽量减少文本输入 — 它需要虚拟键盘，阻力很高。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default | Field border, placeholder text (label-style, muted color), empty input area. | — | — | — | — |
| Hovered | Border brightens slightly | Mouse over | — | 60ms | — |
| Focused | Border brightens fully. Cursor (blinking, 530ms on/530ms off). Placeholder text hidden. | Tab / click | Open virtual keyboard on console/mobile | Instant | [UI focus sound] |
| Typing | Characters appear. Cursor advances. | Keyboard input | Update field value | Immediate | [Subtle keystroke sound, optional] |
| Value present | Field shows typed value. Placeholder hidden. Clear button appears (X, right of field) if value is non-empty. | — | — | — | — |
| Character limit reached | No further input accepted. Optional: brief shake animation and limit indicator changes color. | Input at limit | Reject further characters | 200ms shake | [UI error sound, subtle] |
| Clear | Field empties. Cursor returns. Clear button disappears. | Click X / gamepad clear input | Clear value | Instant | [UI cancel sound, subtle] |
| Validation error | Border turns error color (red — ensure colorblind safe). Error message appears below field. | On submit or on blur | Show error | Instant | [UI error sound] |
| Validated / correct | Border turns success color (green — ensure colorblind safe). Success icon optional. | On validation pass | — | Instant | — |
| Disabled | 40% opacity, no interaction. Value still visible. | — | — | — | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认 | 字段边框、占位文本（标签样式、柔和颜色）、空输入区。 | — | — | — | — |
| 悬停 | 边框略微变亮 | 鼠标悬停 | — | 60ms | — |
| 聚焦 | 边框完全变亮。光标（闪烁，亮 530ms / 灭 530ms）。占位文本隐藏。 | Tab / 点击 | 在主机/移动端打开虚拟键盘 | 即时 | [UI 聚焦音效] |
| 输入中 | 字符出现。光标前进。 | 键盘输入 | 更新字段值 | 即时 | [细微按键音效，可选] |
| 存在值 | 字段显示键入值。占位文本隐藏。值为非空时出现清除按钮（X，字段右侧）。 | — | — | — | — |
| 达到字符限制 | 不再接受输入。可选：短暂抖动动画且限制指示器变色。 | 达到限制时的输入 | 拒绝更多字符 | 200ms 抖动 | [UI 错误音效，细微] |
| 清除 | 字段清空。光标返回。清除按钮消失。 | 点击 X / 手柄清除输入 | 清除值 | 即时 | [UI 取消音效，细微] |
| 校验错误 | 边框变为错误颜色（红色 — 确保色盲安全）。错误消息出现在字段下方。 | 提交时或失焦时 | 显示错误 | 即时 | [UI 错误音效] |
| 校验通过 / 正确 | 边框变为成功颜色（绿色 — 确保色盲安全）。成功图标可选。 | 校验通过时 | — | 即时 | — |
| 禁用 | 40% 不透明度，无交互。值仍可见。 | — | — | — | — |

**Accessibility**:
- Keyboard: All standard text editing shortcuts (Home, End, Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+Z).
- Screen reader: Role: "textbox." Accessible name: field label (not placeholder text). Current value announced. Character limit announced when reached. Validation errors announced immediately on occurrence.
- Placeholder text must not be used as the only label — a visible label above or beside the field is required. Placeholder text disappears when the player types, causing confusion for players with cognitive or memory impairments.
**无障碍**：
- 键盘：所有标准文本编辑快捷键（Home、End、Ctrl+A、Ctrl+C、Ctrl+V、Ctrl+Z）。
- 屏幕阅读器：角色："textbox"。可访问名称：字段标签（而非占位文本）。播报当前值。达到字符限制时播报。校验错误发生时立即播报。
- 占位文本绝不能作为唯一标签 — 字段上方或旁边需要可见标签。占位文本在玩家输入时消失，会对认知或记忆障碍玩家造成困惑。

**Implementation Notes**: [Godot `LineEdit`: set `placeholder_text` for the hint
but always include a visible `Label` node as the field's accessible name. Bind
`text_changed` signal for real-time validation. Bind `text_submitted` for form
submission on Enter. On console, `LineEdit.call("_popup_keyboard")` or use the OS
virtual keyboard API — verify against engine-reference/godot/ for Godot 4.7
console keyboard API specifics.]
**实现说明**：[Godot `LineEdit`：设置 `placeholder_text` 作为提示，但始终包含一个可见的 `Label` 节点作为字段的可访问名称。绑定 `text_changed` 信号进行实时校验。绑定 `text_submitted` 以在 Enter 时提交表单。在主机上，使用 `LineEdit.call("_popup_keyboard")` 或 OS 虚拟键盘 API — 对照 engine-reference/godot/ 验证 Godot 4.7 主机键盘 API 的具体细节。]

---

#### Tab Bar
#### 标签栏

**Category**: Navigation
**Status**: Draft
**When to Use**: Dividing a single screen's content into discrete sections where
only one section is visible at a time. Character sheet tabs (Stats / Equipment /
Skills), settings tabs (Gameplay / Graphics / Audio / Accessibility). Maximum
5-6 tabs before the pattern breaks down and a sidebar navigation should be
considered instead.
**When NOT to Use**: More than 6 tabs. Content that benefits from simultaneous
visibility (use a layout pattern instead). Navigation between different screens
(use Screen Push).
**类别**：导航
**状态**：草稿
**何时使用**：将单个屏幕的内容划分为离散区块，且一次只显示一个区块。角色面板标签（属性 / 装备 / 技能）、设置标签（玩法 / 图形 / 音频 / 无障碍）。最多 5–6 个标签，超过后该模式失效，应考虑改用侧边栏导航。
**何时不要使用**：超过 6 个标签。受益于同时可见的内容（改用布局模式）。不同屏幕之间的导航（使用屏幕推入）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Default (inactive tab) | Tab label. No active indicator. | — | — | — | — |
| Active tab | Tab label. Active indicator (underline, fill, or contrasting background). Content area shows this tab's content. | — | — | — | — |
| Hovered (inactive) | Tab background fills slightly | Mouse over | — | 60ms | — |
| Focused (keyboard/gamepad) | Focus ring on tab label. | Tab key (within tab bar) or D-pad left/right on tab row | — | 60ms | [UI focus sound] |
| Activated | Active indicator transitions to this tab. Content area transitions (fade or slide). | Click / Enter / A / Cross | Switch active tab. Content update. | 150ms ease | [UI tab switch sound] |
| Gamepad shoulder button | — | L1/R1 (PS) or LB/RB (Xbox) | Switch to previous/next tab (standard platform convention) | 150ms | [UI tab switch sound] |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 默认（非活动标签） | 标签文字。无活动指示器。 | — | — | — | — |
| 活动标签 | 标签文字。活动指示器（下划线、填充或对比背景）。内容区显示此标签的内容。 | — | — | — | — |
| 悬停（非活动） | 标签背景略微填充 | 鼠标悬停 | — | 60ms | — |
| 聚焦（键盘/手柄） | 标签文字上有焦点环。 | Tab 键（在标签栏内）或标签行上的方向键左/右 | — | 60ms | [UI 聚焦音效] |
| 激活 | 活动指示器过渡到此标签。内容区过渡（淡入或滑动）。 | 点击 / Enter / A / Cross | 切换活动标签。更新内容。 | 150ms 缓动 | [UI 标签切换音效] |
| 手柄肩键 | — | L1/R1（PS）或 LB/RB（Xbox） | 切换到上一个/下一个标签（标准平台惯例） | 150ms | [UI 标签切换音效] |

**Accessibility**:
- Keyboard: Arrow keys navigate between tabs within the tab bar (left/right). Tab key moves focus into the content area below. This follows the ARIA tab panel pattern.
- Screen reader: Role: "tab" for individual tabs. Role: "tablist" for the container. Role: "tabpanel" for the content area. Active tab state: "selected." Accessible name: tab label. Tabpanel is labeled by its corresponding tab.
- The active tab must be visually distinguishable by more than color alone (underline, fill pattern, or weight change in addition to color).
**无障碍**：
- 键盘：方向键在标签栏内的标签之间导航（左/右）。Tab 键将焦点移入下方内容区。这遵循 ARIA 标签面板模式。
- 屏幕阅读器：单个标签角色："tab"。容器角色："tablist"。内容区角色："tabpanel"。活动标签状态："selected"。可访问名称：标签文字。标签面板由其对应标签命名。
- 活动标签必须通过颜色以外的方式在视觉上可区分（除颜色外，还使用下划线、填充图案或字重变化）。

**Implementation Notes**: [Godot: `TabContainer` built-in. For custom visual
styling, implement manually with a `HBoxContainer` of tab buttons and a
`MarginContainer` for content. The shoulder button shortcut (LB/RB) must be
implemented in the screen's `_input()` override — it is not built into Godot's
tab system. Check platform conventions: Xbox uses LB/RB; PlayStation uses L1/R1;
both are the same physical button, so a single binding works.]
**实现说明**：[Godot：使用内置 `TabContainer`。对于自定义视觉样式，使用标签按钮的 `HBoxContainer` 和内容区的 `MarginContainer` 手动实现。肩键快捷键（LB/RB）必须在屏幕的 `_input()` 重写中实现 — 它并非内置于 Godot 的标签系统中。核对平台惯例：Xbox 使用 LB/RB；PlayStation 使用 L1/R1；两者是同一个物理按钮，因此单一绑定即可。]

---

#### Scroll Container
#### 滚动容器

**Category**: Layout
**Status**: Draft
**When to Use**: Content that exceeds the visible area of its container. Inventory
lists, lore entry text, credits, long settings lists. The scroll indicator shows
the player that more content exists.
**When NOT to Use**: Content that can be paginated instead (pagination may be
clearer for dense list navigation). Infinite scroll (always provide a loading
state and an end state).
**类别**：布局
**状态**：草稿
**何时使用**：超出容器可见区域的内容。库存列表、背景故事条目文本、制作人员名单、长设置列表。滚动指示器向玩家表明存在更多内容。
**何时不要使用**：可以改为分页的内容（对于密集列表导航，分页可能更清晰）。无限滚动（始终提供加载状态和结束状态）。

**Interaction Specification**:
**交互规格**：

| State | Visual | Input | Response | Duration | Audio |
|-------|--------|-------|----------|----------|-------|
| Content fits | No scrollbar visible (or always-visible scrollbar at full height, depending on art direction). | — | — | — | — |
| Scrollable | Scrollbar appears (right edge). Scrollbar thumb size represents viewport vs. content ratio. | — | — | — | — |
| Scrolling (mouse) | Content moves. Scrollbar thumb moves proportionally. | Mouse wheel | Scroll by 3 lines per wheel tick (configurable in OS) | Smooth | — |
| Scrollbar drag | Content moves. Thumb follows pointer. | Click + drag scrollbar thumb | Scroll proportionally | Real time | — |
| Keyboard scroll | Content moves one item height per keypress. | Up/Down arrows when container is focused and no child is focused | Scroll by one unit | Immediate | — |
| Gamepad scroll | Content moves to keep focused item in view. | D-pad navigation to items beyond visible area | Auto-scroll to keep focused item visible | Smooth 150ms | — |
| Scroll top / bottom | Content stops. Scrollbar thumb at end. | Content boundary reached | Stop scrolling | — | — |
| Focus follows scroll | When a child element receives focus, scroll container ensures it is fully visible. | Any child receives focus | Scroll to reveal focused element | 200ms ease | — |

| 状态 | 视觉 | 输入 | 响应 | 时长 | 音频 |
|-------|--------|-------|----------|----------|-------|
| 内容适配 | 无滚动条可见（或滚动条始终以全高可见，取决于美术方向）。 | — | — | — | — |
| 可滚动 | 滚动条出现（右边缘）。滚动条滑块大小表示视口与内容的比例。 | — | — | — | — |
| 滚动（鼠标） | 内容移动。滚动条滑块按比例移动。 | 鼠标滚轮 | 每格滚轮滚动 3 行（可在 OS 中配置） | 平滑 | — |
| 拖动滚动条 | 内容移动。滑块跟随指针。 | 点击 + 拖动滚动条滑块 | 按比例滚动 | 实时 | — |
| 键盘滚动 | 每次按键内容移动一个项目高度。 | 容器聚焦且无子项聚焦时的上/下方向键 | 滚动一个单位 | 即时 | — |
| 手柄滚动 | 内容移动以保持聚焦项可见。 | 方向键导航到可见区域之外的项目 | 自动滚动以保持聚焦项可见 | 平滑 150ms | — |
| 滚动至顶部 / 底部 | 内容停止。滚动条滑块位于末端。 | 到达内容边界 | 停止滚动 | — | — |
| 焦点跟随滚动 | 当子元素获得焦点时，滚动容器确保其完全可见。 | 任何子项获得焦点 | 滚动以显现聚焦元素 | 200ms 缓动 | — |

**Accessibility**:
- Keyboard/Gamepad: The scroll container itself should not require explicit scrollbar interaction — navigating list items inside it should auto-scroll to keep focused items in view.
- Screen reader: The scroll container announces "scrollable" and the scroll position ("showing items 5 through 15 of 30"). This requires engine accessibility support — verify in engine-reference/godot/.
- Fade edges (content fading at scroll boundaries to indicate more content exists) are a helpful visual affordance but must not be the only indicator that content exists beyond the visible area. Include a scrollbar.
**无障碍**：
- 键盘/手柄：滚动容器本身不应要求显式的滚动条交互 — 在其内部导航列表项时应自动滚动以保持聚焦项可见。
- 屏幕阅读器：滚动容器播报“可滚动”及滚动位置（“显示第 5 至 15 项，共 30 项”）。这需要引擎无障碍支持 — 在 engine-reference/godot/ 中验证。
- 边缘淡出（内容在滚动边界淡出以表明存在更多内容）是有帮助的视觉提示，但绝不能作为可见区域外存在内容的唯一指示。应包含滚动条。

**Implementation Notes**: [Godot `ScrollContainer`: call `ensure_control_visible()`
on the focused child whenever `gui_focus_changed` fires inside the container.
Bind this via a recursive `connect` on the container's `gui_focus_changed` signal.
For smooth scroll animation, use a `Tween` on `scroll_vertical` rather than
setting it directly.]
**实现说明**：[Godot `ScrollContainer`：每当容器内触发 `gui_focus_changed` 时，对聚焦的子项调用 `ensure_control_visible()`。通过在容器的 `gui_focus_changed` 信号上递归 `connect` 来绑定。对于平滑滚动动画，对 `scroll_vertical` 使用 `Tween`，而非直接设置它。]

---
