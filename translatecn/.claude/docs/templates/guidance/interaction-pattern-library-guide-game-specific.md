> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.
> interaction-pattern-library.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

> Covers: **Game-Specific UI Patterns** — full reference specifications for Inventory Slot, Ability / Skill Icon, Health / Resource Bar, Dialogue Box, Context Action Prompt, Damage Number.
> 涵盖：**游戏专属 UI 模式** — 库存槽位、技能 / 技能图标、生命 / 资源条、对话框、情境操作提示、伤害数字的完整参考规格。

## Game-Specific UI Patterns
## 游戏专属 UI 模式

---

#### Inventory Slot
#### 库存槽位

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Every item container in the inventory grid. Empty slots, populated
slots, equipped slots, locked slots. The slot is the frame; the item icon is the
content.
**类别**：游戏专属
**状态**：草稿
**何时使用**：库存网格中的每个物品容器。空槽、已填充槽、已装备槽、锁定槽。
槽位是框架；物品图标是内容。

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| Empty | Subtle slot border, no content. Not the same as disabled. Empty slots are interactable (receive items). | Avoid fully invisible empty slots — players lose track of grid dimensions |
| Populated | Item icon fills 80% of slot area. Stack count bottom-right (if applicable). Quality border (colorblind-safe — icon + color). Equipped badge (top-right, if equipped). | |
| Focused | Focus ring. Tooltip appears after 300ms. | |
| Selected | Thicker or contrasting border. Used when multi-select is supported. | |
| Drag source | Slot dims, drag ghost follows pointer. | See Grid Item for full drag spec |
| Locked | Padlock icon overlay. No interaction. May show item at 50% opacity behind lock. | Used for locked loadout slots, DLC content, etc. |
| Highlighted | Animated border glow (pulsing). Used for quest-relevant items or newly acquired items. | Respect motion reduction — replace pulse with a static badge |
| Cooldown overlay | Radial fill overlay from 12 o'clock, clockwise, depleting as cooldown expires. | Only applicable if slots represent active items with cooldowns |

| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| 空 | 细微槽位边框，无内容。不同于禁用。空槽可交互（可接收物品）。 | 避免完全不可见的空槽 — 玩家会失去对网格尺寸的感知 |
| 已填充 | 物品图标填充槽位面积的 80%。堆叠数在右下（如适用）。品质边框（色盲安全 — 图标 + 颜色）。已装备徽章（右上，如已装备）。 | |
| 获得焦点 | 焦点环。300 毫秒后出现工具提示。 | |
| 已选中 | 更粗或对比色边框。支持多选时使用。 | |
| 拖拽源 | 槽位变暗，拖拽残影跟随指针。 | 完整拖拽规格见网格项 |
| 锁定 | 挂锁图标覆盖。无交互。可在锁后以 50% 不透明度显示物品。 | 用于锁定的配装槽、DLC 内容等 |
| 高亮 | 动画边框光晕（脉动）。用于任务相关物品或新获得物品。 | 遵循减少动态效果 — 用静态徽章替代脉动 |
| 冷却覆盖 | 从 12 点方向顺时针的径向填充覆盖，随冷却结束而消退。 | 仅当槽位代表带冷却的主动物品时适用 |

**Accessibility**: Stack counts and quality tiers must have text or icon alternatives to color coding. Tooltip is the primary accessibility mechanism — ensure it is reachable by keyboard and screen reader. Locked slots must announce "locked" to screen readers.
**无障碍**：堆叠数与品质层级必须有文字或图标来替代颜色编码。工具提示是主要的无障碍机制 —
确保键盘和屏幕阅读器可到达。锁定槽必须向屏幕阅读器播报“已锁定”。

**Implementation Notes**: [Godot: Custom `Control` node. Quality border implemented as a `StyleBoxFlat` swapped based on rarity — avoid using `modulate` color for quality, as it affects the icon color. Drag and drop implemented via `get_drag_data()` and `can_drop_data()` / `drop_data()` override methods.]
**实现说明**：[Godot：自定义 `Control` 节点。品质边框实现为基于稀有度切换的 `StyleBoxFlat` —
避免用 `modulate` 颜色表示品质，因为它会影响图标颜色。拖放通过 `get_drag_data()` 和
`can_drop_data()` / `drop_data()` 重写方法实现。]

---

#### Ability / Skill Icon
#### 技能 / 技能图标

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Ability buttons in the HUD ability bar, skill tree nodes, and
any context where an ability must show availability state.
**类别**：游戏专属
**状态**：草稿
**何时使用**：HUD 技能栏中的技能按钮、技能树节点，以及任何必须显示可用状态的技能情境。

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| Available | Full opacity icon. Keybinding label below. | |
| On cooldown | Radial overlay depleting clockwise from 12 o'clock. Remaining time shown as a number in the center when > 2 seconds remain. | |
| Charges remaining | Charge pip indicators below icon (e.g., 3 filled circles = 3 charges). Number alternative for screen readers. | |
| Out of resource | Icon desaturates to ~20%. Border dims. Keybinding label dims. Distinct from cooldown — resource-gated, not time-gated. | |
| Locked / not unlocked | Icon silhouette only (no full art visible). Padlock badge. May show unlock condition in tooltip. | |
| Active / channeling | Pulsing border. Radial fill shows channel duration remaining. | |
| Just activated | Brief scale 0.9x then spring to 1.0x (overshoot to 1.05x). | Example: Guild Wars 2 and Path of Exile both use press-depress animations on ability use to confirm activation. Respect motion reduction. |

| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| 可用 | 全不透明度图标。下方有键位标签。 | |
| 冷却中 | 从 12 点方向顺时针消退的径向覆盖。剩余时间大于 2 秒时在中心以数字显示。 | |
| 剩余充能 | 图标下方的充能点指示（例如，3 个实心圆 = 3 次充能）。为屏幕阅读器提供数字替代。 | |
| 资源不足 | 图标去饱和至约 20%。边框变暗。键位标签变暗。区别于冷却 — 受资源限制，而非时间限制。 | |
| 锁定 / 未解锁 | 仅显示图标剪影（不显示完整美术）。挂锁徽章。可在工具提示中显示解锁条件。 | |
| 激活 / 引导中 | 脉动边框。径向填充显示剩余引导时长。 | |
| 刚刚激活 | 短暂缩放至 0.9x 后弹回 1.0x（过冲到 1.05x）。 | 例如：Guild Wars 2 和 Path of Exile 都在技能使用时用按下-回弹动画确认激活。遵循减少动态效果。 |

**Accessibility**: All cooldown/charge information must have a numeric value (screen reader cannot parse radial overlays). The cooldown timer number satisfies this. Ability names and descriptions must be exposed to screen readers via tooltip.
**无障碍**：所有冷却/充能信息都必须有数值（屏幕阅读器无法解析径向覆盖）。冷却计时数字满足此要求。
技能名称与描述必须通过工具提示暴露给屏幕阅读器。

**Implementation Notes**: [Godot: Custom `TextureButton` subclass with overlay
`Control` nodes for cooldown radial and charge pips. The cooldown radial uses a
custom shader on a `ColorRect` rotating a mask — or implement with a
`ProgressBar` styled as circular if engine supports it. Verify against
engine-reference/godot/ for Godot 4.7 shader support for this pattern.]
**实现说明**：[Godot：自定义 `TextureButton` 子类，并叠加 `Control` 节点用于冷却径向和充能点。
冷却径向使用 `ColorRect` 上的自定义着色器旋转遮罩 — 若引擎支持，也可用样式化为圆形的
`ProgressBar` 实现。请对照 engine-reference/godot/ 核实 Godot 4.7 对此模式的着色器支持。]

---

#### Health / Resource Bar
#### 生命 / 资源条

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Any continuously varying value in the HUD that represents a
critical player resource. Health, mana, stamina, shield, fuel.
**类别**：游戏专属
**状态**：草稿
**何时使用**：HUD 中任何代表关键玩家资源、且持续变化的数值。生命、法力、耐力、护盾、燃料。

**States and behaviors**:
**状态与行为**：

| Event | Visual | Audio | Duration |
|-------|--------|-------|---------|
| Value decrease (damage) | Fill shrinks. Brief "damage flash" on the fill (white or red flash). Ghost bar lingers at previous value and drains to new value over 0.5s ("damage indicator"). | [Damage taken sound — varies by amount] | Instant decrease, 500ms ghost bar drain |
| Value increase (heal) | Fill grows. Brief heal color flash (green — ensure colorblind safe with icon/glow backup). | [Heal sound] | 300ms ease-in |
| Below 25% threshold | Fill changes color to warning state. Border pulses (or static badge in motion reduction mode). Optional: heartbeat audio cue (paired with visual if audio is sole signal). | [Low health sound — loops until above threshold] | Continuous |
| At zero | Bar empty. Optional: bar shakes briefly. Death/depletion event fires. | [Death/depletion sound] | 200ms shake |
| Maximum | Fill at 100%, brief glow. | — | 200ms |
| Overflow (shield) | A separate bar segment appears beyond the natural fill area, in shield color. | [Shield gain sound] | 200ms |

| 事件 | 视觉 | 音频 | 持续时间 |
|-------|--------|-------|---------|
| 数值下降（伤害） | 填充收缩。填充上短暂“伤害闪烁”（白色或红色闪烁）。残影条停留在之前数值，并在 0.5 秒内排空至新数值（“伤害指示”）。 | [受到伤害音效 — 随数值变化] | 即时下降，500 毫秒残影条排空 |
| 数值上升（治疗） | 填充增长。短暂治疗颜色闪烁（绿色 — 确保通过图标/光晕作为色盲安全备选）。 | [治疗音效] | 300 毫秒缓入 |
| 低于 25% 阈值 | 填充变为警告状态颜色。边框脉动（减少动态效果模式下为静态徽章）。可选：心跳音频提示（若音频是唯一信号，则与视觉配对）。 | [低生命音效 — 循环直到高于阈值] | 持续 |
| 归零 | 条形清空。可选：条形短暂抖动。触发死亡/耗尽事件。 | [死亡/耗尽音效] | 200 毫秒抖动 |
| 最大值 | 填充至 100%，短暂发光。 | — | 200 毫秒 |
| 溢出（护盾） | 在自然填充区域之外出现独立的条形段，使用护盾颜色。 | [获得护盾音效] | 200 毫秒 |

**Accessibility**: The current value must be accessible as a number (tooltip or persistent display, or both). Color-coded threshold states must have non-color backups (icon, flashing, or audio visual warning). Warning state at 25% must have a visual signal independent of the color change.
**无障碍**：当前数值必须能以数字方式访问（工具提示或常驻显示，或两者兼有）。颜色编码的阈值状态
必须有非颜色备选（图标、闪烁或音频视觉警告）。25% 的警告状态必须有一个独立于颜色变化的视觉信号。

**Implementation Notes**: [Godot: Two overlapping `ProgressBar` nodes for ghost
bar effect — back bar holds previous value (drains via Tween), front bar holds
current value (updates instantly). Threshold states trigger `StyleBoxFlat` swaps
on the front bar. Ghost bar Tween duration is tunable as a designer parameter.]
**实现说明**：[Godot：两个重叠的 `ProgressBar` 节点实现残影条效果 — 后层条保存之前数值（通过 Tween 排空），
前层条保存当前数值（即时更新）。阈值状态触发前层条的 `StyleBoxFlat` 切换。
残影条 Tween 时长可作为设计师参数调节。]

---

#### Dialogue Box
#### 对话框

**Category**: Game-Specific
**Status**: Draft
**When to Use**: NPC conversation, voiced narrative dialogue, tutorial text
delivered through a character. All dialogue that has a speaker.
**类别**：游戏专属
**状态**：草稿
**何时使用**：NPC 对话、有配音的叙事对话、通过角色传达的教程文本。所有有说话人的对话。

**Structure**: Speaker portrait or name tag (top of box or left side). Dialogue text body. Continue/advance prompt (bottom right). Optional: skip-all button, voice acting indicator, subtitle indicator.
**结构**：说话人头像或名称标签（框顶或左侧）。对话正文。继续/推进提示（右下）。可选：跳过全部按钮、配音指示、字幕指示。

**States and behaviors**:
**状态与行为**：

| State | Visual | Input | Response | Duration |
|-------|--------|-------|----------|---------|
| Line entering | Text reveals character-by-character (typewriter effect). Or: text fades in at full speed if accessibility option set. | — | — | Speed: configurable in accessibility settings |
| Revealing | Text animating in. Continue prompt hidden or pulsing at slow opacity. | [Any advance input] | Skip to end of current line instantly (show full line, stop typewriter) | Immediate |
| Line complete | Full line shown. Continue prompt visible and animated. | — | — | — |
| Advancing to next line | Continue prompt hides. Text fades out or wipes. New line begins. | [Any advance input] — Enter / A / Cross / Space / mouse click | Advance | 100ms transition |
| Choices appearing | Choice buttons appear below dialogue text. Continue prompt hidden. Navigation focus moves to first choice. | D-pad / keyboard to select, Enter / A / Cross to confirm | Select choice | 150ms enter animation |
| Closing | Box fades out | Final line advanced | Return control to player | 200ms |
| Skipping all (if supported) | Brief confirmation prompt: "Skip dialogue?" | Dedicated skip button | Skip to post-dialogue state | — |

| 状态 | 视觉 | 输入 | 响应 | 持续时间 |
|-------|--------|-------|----------|---------|
| 行进入 | 文本逐字符显示（打字机效果）。或：如设置了无障碍选项，则文本以全速淡入。 | — | — | 速度：可在无障碍设置中配置 |
| 显示中 | 文本正在动画进入。继续提示隐藏，或以低不透明度脉动。 | [任何推进输入] | 立即跳到当前行末尾（显示整行，停止打字机） | 即时 |
| 行完成 | 显示完整行。继续提示可见并动画。 | — | — | — |
| 推进到下一行 | 继续提示隐藏。文本淡出或擦除。新行开始。 | [任何推进输入] — Enter / A / Cross / 空格 / 鼠标点击 | 推进 | 100 毫秒过渡 |
| 选项出现 | 选项按钮出现在对话文本下方。继续提示隐藏。导航焦点移到第一个选项。 | 方向键 / 键盘选择，Enter / A / Cross 确认 | 选择选项 | 150 毫秒进入动画 |
| 关闭 | 框淡出 | 最后一行已推进 | 将控制权交还玩家 | 200 毫秒 |
| 跳过全部（如支持） | 简短确认提示：“跳过对话？” | 专用跳过按钮 | 跳到对话后状态 | — |

**Accessibility**: Subtitles are always enabled by default for all voiced dialogue. Typewriter animation speed is a user setting (see accessibility-requirements.md). The dialogue box must not auto-advance — players must control pacing. Speaker name is always shown. All choice buttons must be navigable by keyboard and gamepad. Choices must be accessible to screen readers with position announced.
**无障碍**：所有配音对话默认始终启用字幕。打字机动画速度是用户设置（见 accessibility-requirements.md）。
对话框不得自动推进 — 玩家必须掌控节奏。说话人名称始终显示。所有选项按钮必须可由键盘和手柄导航。
选项必须可被屏幕阅读器访问，并播报其位置。

**Implementation Notes**: [Godot: `RichTextLabel` with `bbcode_enabled` for
formatting. Typewriter effect via `visible_characters` property animated by a
`Timer`. Bind the advance input to a function that either skips typewriter
(sets `visible_characters = -1`) or advances the dialogue state. Speaker name
displayed in a separate `Label` above or beside the box. Dialogue data loaded from
JSON or a dedicated dialogue format (e.g., Dialogic, Yarn Spinner for Godot).]
**实现说明**：[Godot：使用 `bbcode_enabled` 的 `RichTextLabel` 进行格式化。打字机效果通过 `Timer`
驱动 `visible_characters` 属性动画。将推进输入绑定到函数：要么跳过打字机
（设置 `visible_characters = -1`），要么推进对话状态。说话人名称显示在框上方或旁边的独立 `Label` 中。
对话数据从 JSON 或专用对话格式加载（例如，Dialogic、适用于 Godot 的 Yarn Spinner）。]

---

#### Context Action Prompt
#### 情境操作提示

**Category**: Game-Specific
**Status**: Draft
**When to Use**: A prompt that appears near an interactable game object indicating
what the player can do. "Press [A] to open chest." "Hold [E] to pick up." Appears
when the player enters the interaction zone, disappears when they leave.
**类别**：游戏专属
**状态**：草稿
**何时使用**：出现在可交互游戏对象附近、指示玩家可做什么的提示。“按 [A] 打开箱子。”
“按住 [E] 拾取。”玩家进入交互区域时出现，离开时消失。

**States**:
**状态**：

| State | Visual | Notes |
|-------|--------|-------|
| Appearing | Fades in and rises 8px from object anchor point. | Respect motion reduction — fade only, no rise |
| Idle | Platform-correct button icon + action label. Icon matches current input method (updates if player switches). | Always show platform-correct icon — do not hardcode "Press A" for all platforms |
| Holding (for hold inputs) | Radial fill on the button icon shows hold progress. Label changes to active verb ("Opening..."). | |
| Cannot interact (blocked) | Icon dims. Label shows reason if known ("Too heavy", "Need key"). | Optional — only show blocked state if the reason is meaningful to the player |
| Disappearing | Fades out. | Triggered when player exits interaction zone |

| 状态 | 视觉 | 备注 |
|-------|--------|-------|
| 出现 | 淡入并从对象锚点上升 8px。 | 遵循减少动态效果 — 仅淡入，不上升 |
| 空闲 | 平台正确按钮图标 + 动作标签。图标匹配当前输入方式（玩家切换时更新）。 | 始终显示平台正确图标 — 不要把所有平台都硬编码为“按 A” |
| 按住中（用于长按输入） | 按钮图标上的径向填充显示按住进度。标签变为进行时动词（“正在打开...”）。 | |
| 无法交互（受阻） | 图标变暗。如已知，标签显示原因（“太重”、“需要钥匙”）。 | 可选 — 仅当原因对玩家有意义时才显示受阻状态 |
| 消失 | 淡出。 | 玩家离开交互区域时触发 |

**Accessibility**: The button icon must be accompanied by a text label — do not rely on icon alone (some players use custom button labels or adaptive controllers with non-standard icons). The prompt must be positioned to not overlap character health or critical HUD information.
**无障碍**：按钮图标必须伴随文字标签 — 不要仅依赖图标（部分玩家使用自定义按钮标签或非标准图标的
自适应控制器）。提示的位置不得与角色生命或关键 HUD 信息重叠。

**Implementation Notes**: [Godot: Attach as a `Node3D` child (or `Node2D` child in 2D) of the interactable object. Use a `BillboardMesh` or a `SubViewport` with a UI scene for 3D games — this keeps the prompt facing the camera without code. Update the button icon texture based on `Input.get_joy_name()` or keyboard detection via `InputEventKey` vs `InputEventJoypadButton`. Hold progress implemented as an `AnimationPlayer` or `Tween` on a radial mask shader.]
**实现说明**：[Godot：作为可交互对象的 `Node3D` 子节点（2D 中为 `Node2D` 子节点）附加。
3D 游戏使用 `BillboardMesh` 或带 UI 场景的 `SubViewport` — 这无需代码即可让提示始终面向相机。
根据 `Input.get_joy_name()` 或通过 `InputEventKey` 与 `InputEventJoypadButton` 的键盘检测更新按钮图标纹理。
按住进度在径向遮罩着色器上通过 `AnimationPlayer` 或 `Tween` 实现。]

---

#### Damage Number
#### 伤害数字

**Category**: Game-Specific
**Status**: Draft
**When to Use**: Floating feedback numbers above combat participants. Normal
damage, critical damage, healing, miss.
**类别**：游戏专属
**状态**：草稿
**何时使用**：战斗参与者上方的飘浮反馈数字。普通伤害、暴击伤害、治疗、未命中。

**Variants**:
**变体**：

| Variant | Visual | Notes |
|---------|--------|-------|
| Normal damage | White number, normal weight, medium size. | |
| Critical hit | Larger size (1.5x), bold weight, orange or yellow — verify colorblind safe. Brief scale impact (1.3x → 1.0x on appear). | Example: Path of Exile and Diablo IV both use scale-pop for crits to make them immediately recognizable by size alone, independent of color. |
| Healing | Green (verify colorblind safe — use + prefix and upward trajectory as non-color backups). | |
| Miss / Evade | "MISS" text, grey, italic. Floats at smaller size. | |
| Status damage (DoT) | Smaller size, distinct color matching the status effect. | |

| 变体 | 视觉 | 备注 |
|---------|--------|-------|
| 普通伤害 | 白色数字，常规字重，中等尺寸。 | |
| 暴击 | 更大尺寸（1.5x），粗字重，橙色或黄色 — 验证色盲安全。短暂缩放冲击（出现时 1.3x → 1.0x）。 | 例如：Path of Exile 和 Diablo IV 都用缩放弹跳表现暴击，使其仅凭尺寸即可立即识别，不依赖颜色。 |
| 治疗 | 绿色（验证色盲安全 — 使用 + 前缀和向上轨迹作为非颜色备选）。 | |
| 未命中 / 闪避 | “MISS”文本，灰色，斜体。以较小尺寸飘浮。 | |
| 状态伤害（持续伤害） | 较小尺寸，与状态效果匹配的独特色彩。 | |

**Behavior**: Numbers float upward from the hit location over 1.0 second. Numbers fade from 100% to 0% during the last 0.4 seconds. Multiple numbers from rapid hits stagger horizontally to avoid overlap. Maximum simultaneous damage numbers on screen: [define per game — typically 8-12 per character].
**行为**：数字在 1.0 秒内从命中位置向上飘浮。数字在最后 0.4 秒内从 100% 淡出到 0%。
快速连续命中产生的多个数字在水平方向错开以免重叠。屏幕上同时存在的伤害数字上限：
[按游戏定义 — 通常每个角色 8-12 个]。

**Accessibility**: Damage numbers are purely supplementary feedback — they must never be the only way to understand combat state. Health bars are the authoritative source. Provide an option to disable damage numbers entirely (some players find them visually overwhelming). When disabled, the game must remain fully playable.
**无障碍**：伤害数字纯属补充反馈 — 它们绝不能成为理解战斗状态的唯一方式。血条是权威来源。
提供完全禁用伤害数字的选项（部分玩家觉得视觉上过于刺激）。禁用时，游戏必须仍完全可玩。

**Implementation Notes**: [Godot: Pool of `Label3D` (3D games) or `Label` (2D games)
instances recycled via an object pool. Each instance is given a random small
horizontal offset on spawn (±20px) to reduce overlap. Float animation via
`Tween` on `position.y` and `modulate.a`. Critical hit scale-pop via Tween
with `EASE_OUT` on scale followed by linear settle.]
**实现说明**：[Godot：`Label3D`（3D 游戏）或 `Label`（2D 游戏）实例池，通过对象池回收。
每个实例在生成时获得随机的小水平偏移（±20px）以减少重叠。飘浮动画通过
`position.y` 和 `modulate.a` 上的 `Tween` 实现。暴击缩放弹跳通过带 `EASE_OUT` 的缩放
Tween 随后线性回稳实现。]

---
