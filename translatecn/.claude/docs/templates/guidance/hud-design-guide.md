> Authoring guidance for hud-design.md. Load only the part covering the section currently being authored — not the whole file at once.
> hud-design.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

# HUD Design Template — Authoring Guidance
# HUD 设计模板 — 编写指南

Guidance is organized by template section number. When authoring a section of a
project's HUD design document, read only that section's guidance below.
指南按模板章节编号组织。编写项目 HUD 设计文档的某章节时，只阅读下面该章节的指南。

---

## Section 1 — HUD Philosophy
## 第 1 节 — HUD 哲学

> **Why this section exists**: The HUD design philosophy is not decoration — it is a
> design constraint that every subsequent decision is measured against. Without a
> philosophy, individual elements get added on request ("the quest tracker wants a
> bigger icon") without any principled way to push back. With a philosophy, there is
> a shared, explicit standard. More importantly, the philosophy prevents the HUD from
> slowly growing to cover the game world while each individual addition seemed
> reasonable in isolation. Write this before specifying any elements.
> **为何存在此节**：HUD 设计哲学不是装饰 — 它是衡量每个后续决策的设计约束。没有哲学，
> 单个元素会按请求添加（“任务追踪器想要更大的图标”）而没有任何有原则的反驳方式。有了哲学，
> 就有共享的、显式的标准。更重要的是，哲学防止 HUD 缓慢增长以覆盖游戏世界，
> 而每个单独添加在孤立看时似乎合理。在规定任何元素之前先写此节。

**Authoring the philosophy statement**:
**编写哲学声明**：

[One paragraph. This is a design statement, not a description of features. Consider
the game's genre, pacing, and player fantasy. A stealth game's HUD philosophy might
be: "The world is the interface. If the player has to look away from the environment
to survive, the HUD has failed." A tactics game might say: "Complete situational
awareness is the game. The HUD is not an overlay — it is the battlefield."

Reference comparable games if helpful, but describe your specific stance:
Example — diegetic-first action RPG: "We treat screen information as a concession,
not a feature. Every HUD element must earn its pixel space by answering the question:
would the player make demonstrably worse decisions without this information visible?
If the answer is 'they'd adapt,' we put it in the environment instead."]
[一段话。这是设计声明，而非功能描述。考虑游戏类型、节奏与玩家幻想。
潜行游戏的 HUD 哲学可能是：“世界即是界面。如果玩家必须从环境移开视线才能生存，HUD 就失败了。”
战术游戏可能说：“完全的态势感知就是游戏。HUD 不是覆盖层 — 它是战场。”

如有帮助可参考同类游戏，但要描述你自己的具体立场：
示例 — 叙事内优先的动作 RPG：“我们把屏幕信息视为一种让步，而非功能。每个 HUD 元素都必须通过回答
这个问题来赢得它的像素空间：如果这些信息不可见，玩家会做出明显更差的决策吗？
如果答案是‘他们会适应’，我们就把它放进环境里。”]

**Authoring the visibility principle**:
**编写可见性原则**：

[State the default resolution for ambiguous cases. Options:
- Default to HIDE: information is available on demand (e.g., Dark Souls — no quest tracker, no minimap, stats are in a menu)
- Default to SHOW: players prefer to be informed; cluttered is better than uncertain
- Default to CONTEXTUAL: information appears when it becomes relevant and fades when it does not
Most games benefit from contextual defaults. State your game's default clearly so every element decision is consistent.]
[说明模糊情况下的默认处理。选项：
- 默认隐藏：信息按需可得（例如，Dark Souls — 无任务追踪器、无小地图，属性在菜单中）
- 默认显示：玩家更愿意被告知；杂乱好过不确定
- 默认情境化：信息在变得相关时出现，在不相关时淡出
大多数游戏受益于情境化默认。清楚说明你游戏的默认值，以便每个元素决策都一致。]

**Authoring the Rule of Necessity**:
**编写必要性规则**：

[Complete this sentence: "A HUD element earns its place when ______________."

Example: "...the player would have to stop playing to find the same information
elsewhere, or would make meaningfully worse decisions without it."

Example: "...removing it in playtesting causes measurable frustration or confusion
in more than 25% of testers within the first hour of play."

This rule is the veto power over feature requests to add HUD elements. Document it
so it can be cited in design reviews.]
[补全这句话：“当 ______________ 时，一个 HUD 元素才配得上它的位置。”

示例：“...玩家必须停止游玩才能在其他地方找到相同信息，或者没有它就会做出明显更差的决策。”

示例：“...在游戏测试中移除它，会在游玩第一小时内导致超过 25% 的测试者出现可测量的沮丧或困惑。”

此规则是对添加 HUD 元素的功能请求的否决权。记录它，以便在设计评审中引用。]

---

## Section 2 — Information Architecture
## 第 2 节 — 信息架构

> **Why this section exists**: Before specifying any HUD element's visual design,
> position, or behavior, you must answer a more fundamental question: should this
> information be on the HUD at all? This section is a forcing function — it requires
> you to categorize EVERY piece of information the game world generates and make an
> explicit, intentional decision about how each is presented. "We'll figure that out
> later" is how games end up with 18 elements competing for the player's peripheral
> vision. This table is the master inventory of game information, not just HUD information.
> **为何存在此节**：在规定任何 HUD 元素的视觉设计、位置或行为之前，你必须回答一个更根本的问题：
> 这条信息到底该不该出现在 HUD 上？此节是一种强制机制 — 它要求你对游戏世界产生的**每一条**信息
> 进行分类，并就每条如何呈现做出显式、有意的决策。“我们以后再想”正是游戏最终出现 18 个元素
> 争夺玩家周边视觉的原因。此表是游戏信息的主清单，而不仅是 HUD 信息。

**Worked example table** (typical information types and categorization reasoning):
**完整示例表**（典型信息类型与分类理由）：

| Information Type | Always Show | Contextual (show when relevant) | On Demand (menu/button) | Hidden (environmental / diegetic) | Reasoning |
|-----------------|-------------|--------------------------------|------------------------|----------------------------------|-----------|
| [Health / Vitality] | [X if action game — player needs constant awareness] | [X if exploration game — show only when injured] | [ ] | [ ] | [Example: always visible because health decisions (retreat, heal) must be instant in combat] |
| [Primary resource (mana / stamina / ammo)] | [ ] | [X — show when resource is being consumed or is critically low] | [ ] | [ ] | [Example: contextual because stable resource levels are not decision-relevant] |
| [Secondary resource (currency / materials)] | [ ] | [ ] | [X — check in inventory] | [ ] | [Example: on-demand because resource totals don't affect immediate gameplay decisions] |
| [Minimap / Compass] | [X] | [ ] | [ ] | [ ] | [Example: always visible because navigation decisions are constant during exploration] |
| [Quest objective] | [ ] | [X — show when objective changes or player is near it] | [ ] | [ ] | [Example: contextual — player knows their objective; only remind at key moments] |
| [Enemy health bar] | [ ] | [X — show only during combat encounters] | [ ] | [ ] | [Example: contextual because enemy health is irrelevant outside combat] |
| [Status effects (buffs/debuffs)] | [ ] | [X — show when active] | [ ] | [ ] | [Example: contextual because status effects only affect decisions when present] |
| [Dialogue subtitles] | [X when dialogue is playing] | [ ] | [ ] | [ ] | [Example: always show while dialogue is active — accessibility requirement] |
| [Combo / streak counter] | [ ] | [X — show while combo is active, hide on reset] | [ ] | [ ] | [Example: contextual because it communicates active performance, not baseline state] |
| [Timer] | [ ] | [X — show only in timed sequences] | [ ] | [ ] | [Example: contextual because timers only exist in specific encounter types] |
| [Tutorial prompts] | [ ] | [X — show for first-time situations only] | [ ] | [ ] | [Example: contextual and one-time; never repeat to experienced players] |
| [Score / points] | [ ] | [X — show in score-relevant modes only] | [ ] | [ ] | [Example: contextual by game mode; hidden in modes where score is irrelevant] |
| [XP / level progress] | [ ] | [ ] | [X — available via character screen] | [ ] | [Example: on-demand because progression does not affect in-moment gameplay decisions] |
| [Waypoint / objective marker] | [ ] | [X — show when player is navigating to objective] | [ ] | [ ] | [Example: contextual — suppress during cutscenes, cinematic moments, and free exploration] |

| 信息类型 | 始终显示 | 情境化（相关时显示） | 按需（菜单/按钮） | 隐藏（环境 / 叙事内） | 理由 |
|-----------------|-------------|--------------------------------|------------------------|----------------------------------|-----------|
| [生命 / 体力] | [若为动作游戏则标 X — 玩家需要持续感知] | [若为探索游戏则标 X — 仅在受伤时显示] | [ ] | [ ] | [示例：始终可见，因为战斗中生命决策（撤退、治疗）必须即时] |
| [主要资源（法力 / 耐力 / 弹药）] | [ ] | [X — 资源被消耗或极低时显示] | [ ] | [ ] | [示例：情境化，因为稳定的资源水平与决策无关] |
| [次要资源（货币 / 材料）] | [ ] | [ ] | [X — 在库存中查看] | [ ] | [示例：按需，因为资源总量不影响即时玩法决策] |
| [小地图 / 罗盘] | [X] | [ ] | [ ] | [ ] | [示例：始终可见，因为探索期间导航决策持续存在] |
| [任务目标] | [ ] | [X — 目标变化或玩家靠近时显示] | [ ] | [ ] | [示例：情境化 — 玩家知道自己的目标；只在关键时刻提醒] |
| [敌人血条] | [ ] | [X — 仅在战斗遭遇期间显示] | [ ] | [ ] | [示例：情境化，因为敌人生命在战斗外无关紧要] |
| [状态效果（增益/减益）] | [ ] | [X — 激活时显示] | [ ] | [ ] | [示例：情境化，因为状态效果只在存在时影响决策] |
| [对话字幕] | [对话播放时标 X] | [ ] | [ ] | [ ] | [示例：对话活跃时始终显示 — 无障碍要求] |
| [连击 / 连续命中计数器] | [ ] | [X — 连击活跃时显示，重置时隐藏] | [ ] | [ ] | [示例：情境化，因为它传达活跃表现，而非基线状态] |
| [计时器] | [ ] | [X — 仅在限时序列中显示] | [ ] | [ ] | [示例：情境化，因为计时器只存在于特定遭遇类型中] |
| [教程提示] | [ ] | [X — 仅在首次遇到的情境显示] | [ ] | [ ] | [示例：情境化且一次性；绝不向有经验玩家重复] |
| [分数 / 点数] | [ ] | [X — 仅在分数相关模式中显示] | [ ] | [ ] | [示例：按游戏模式情境化；在分数无关的模式中隐藏] |
| [XP / 等级进度] | [ ] | [ ] | [X — 通过角色屏幕查看] | [ ] | [示例：按需，因为进度不影响当下玩法决策] |
| [航点 / 目标标记] | [ ] | [X — 玩家导航到目标时显示] | [ ] | [ ] | [示例：情境化 — 过场、电影化时刻和自由探索期间抑制] |

---

## Section 3 — Layout Zones
## 第 3 节 — 布局区域

> **Why this section exists**: The game world is the primary content — the HUD is a
> frame around it. Before placing any element, divide the screen into named zones
> with explicit positions and safe zone margins. This section prevents two failure
> modes: (1) elements placed ad-hoc until the screen is cluttered, and (2) elements
> that overlap platform-required safe zones and get rejected in certification.
> Every element in Section 4 must be assigned to a zone defined here.
> **为何存在此节**：游戏世界是主要内容 — HUD 是围绕它的画框。在放置任何元素之前，
> 将屏幕划分为具名区域，并明确位置和安全区边距。此节防止两种失败模式：
> (1) 元素临时放置直到屏幕杂乱；(2) 元素与平台要求的安全区重叠并在认证中被拒。
> 第 4 节的每个元素都必须分配到此处定义的区域。

**Worked example — zone specification table**:
**完整示例 — 区域规格表**：

| Zone Name | Screen Position | Safe Zone Compliant | Primary Elements | Max Simultaneous Elements | Notes |
|-----------|----------------|---------------------|-----------------|--------------------------|-------|
| [Top Left] | [Top-left corner, within safe margin] | [Yes — 10% from top, 10% from left] | [Health bar, stamina bar, shield bar] | [3] | [Vital status — player's own resources. Priority zone for player state.] |
| [Top Center] | [Top edge, centered horizontally] | [Yes — 10% from top] | [Quest objective, area name (on enter)] | [1 — only one message at a time] | [Use for narrative context, not mechanical information. Keep text minimal.] |
| [Top Right] | [Top-right corner, within safe margin] | [Yes — 10% from top, 10% from right] | [Ammo count, ability cooldowns] | [2] | [Weapon/ability state. Most relevant during active combat.] |
| [Center] | [Screen center ±15%] | [N/A — not a margin zone] | [Crosshair, interaction prompt, hit marker] | [1 active at a time] | [CRITICAL: Nothing persistent here. Only momentary indicators.] |
| [Bottom Left] | [Bottom-left corner, within safe margin] | [Yes — 10% from bottom, 10% from left] | [Minimap, ability icons] | [2] | [Navigation and ability readout. Small, non-intrusive.] |
| [Bottom Center] | [Bottom edge, centered horizontally] | [Yes — 10% from bottom] | [Subtitles, tutorial prompts] | [2 — subtitle + tutorial may coexist] | [Highest-priority accessibility zone. Never place other elements here.] |
| [Bottom Right] | [Bottom-right corner, within safe margin] | [Yes — 10% from bottom, 10% from right] | [Notification toasts, pick-up feedback] | [3 stacked] | [Transient notifications. Stack vertically. Oldest disappears first.] |

| 区域名称 | 屏幕位置 | 符合安全区 | 主要元素 | 最大同时元素数 | 备注 |
|-----------|----------------|---------------------|-----------------|--------------------------|-------|
| [左上] | [左上角，在安全边距内] | [是 — 距顶部 10%，距左侧 10%] | [血条、耐力条、护盾条] | [3] | [生命状态 — 玩家自身资源。玩家状态的优先区域。] |
| [顶部居中] | [顶部边缘，水平居中] | [是 — 距顶部 10%] | [任务目标、区域名称（进入时）] | [1 — 一次仅一条消息] | [用于叙事情境，而非机械信息。文字保持极简。] |
| [右上] | [右上角，在安全边距内] | [是 — 距顶部 10%，距右侧 10%] | [弹药数、技能冷却] | [2] | [武器/技能状态。在活跃战斗中最相关。] |
| [中央] | [屏幕中心 ±15%] | [N/A — 非边距区域] | [准星、交互提示、命中标记] | [一次 1 个活跃] | [关键：此处不放任何常驻内容。只放瞬时指示。] |
| [左下] | [左下角，在安全边距内] | [是 — 距底部 10%，距左侧 10%] | [小地图、技能图标] | [2] | [导航与技能读数。小巧、不干扰。] |
| [底部居中] | [底部边缘，水平居中] | [是 — 距底部 10%] | [字幕、教程提示] | [2 — 字幕 + 教程可共存] | [最高优先级无障碍区域。绝不在此放置其他元素。] |
| [右下] | [右下角，在安全边距内] | [是 — 距底部 10%，距右侧 10%] | [通知 toast、拾取反馈] | [3 堆叠] | [瞬态通知。垂直堆叠。最旧的先消失。] |

**Worked example — safe zone margins by platform**:
**完整示例 — 各平台安全区边距**：

| Platform | Top | Bottom | Left | Right | Notes |
|----------|-----|--------|------|-------|-------|
| [PC — windowed] | [0% — no safe zone required] | [0%] | [0%] | [0%] | [But respect minimum resolution — elements must not crowd at 1280x720] |
| [PC — fullscreen] | [3%] | [3%] | [3%] | [3%] | [Slight margin for 4K TV-connected PCs] |
| [Console — TV] | [10%] | [10%] | [10%] | [10%] | [Action-safe zone for broadcast-spec TVs. Some TVs overscan beyond this.] |
| [Steam Deck] | [5%] | [5%] | [5%] | [5%] | [Small screen; safe zone is smaller but crowding risk is higher] |
| [Mobile — portrait] | [15% top] | [10% bottom] | [5%] | [5%] | [15% top avoids notch/camera cutout on most devices] |
| [Mobile — landscape] | [5%] | [5%] | [15% left] | [15% right] | [Thumb placement on landscape — side zones are obscured by hands] |

| 平台 | 上 | 下 | 左 | 右 | 备注 |
|----------|-----|--------|------|-------|-------|
| [PC — 窗口模式] | [0% — 无需安全区] | [0%] | [0%] | [0%] | [但要遵守最低分辨率 — 1280x720 下元素不能拥挤] |
| [PC — 全屏] | [3%] | [3%] | [3%] | [3%] | [为连接 4K 电视的 PC 留出轻微边距] |
| [主机 — 电视] | [10%] | [10%] | [10%] | [10%] | [广播规格电视的动作安全区。部分电视会在此之外过扫描。] |
| [Steam Deck] | [5%] | [5%] | [5%] | [5%] | [小屏幕；安全区更小但拥挤风险更高] |
| [移动端 — 竖屏] | [顶部 15%] | [底部 10%] | [5%] | [5%] | [顶部 15% 避开大多数设备的刘海/摄像头开口] |
| [移动端 — 横屏] | [5%] | [5%] | [左侧 15%] | [右侧 15%] | [横屏时的拇指位置 — 侧边区域会被手遮挡] |

---

## Section 4 — HUD Element Specifications
## 第 4 节 — HUD 元素规格

> **Why this section exists**: Each HUD element needs its own specification to be
> built correctly. Ad-hoc implementation of HUD elements produces inconsistent
> sizing, mismatched update frequencies, missing urgency states, and accessibility
> failures. This section is the implementation brief for every element — fill it
> completely before any element moves into development.
> **为何存在此节**：每个 HUD 元素都需要自己的规格才能正确构建。HUD 元素的临时实现会产生
> 不一致的尺寸、不匹配的更新频率、缺失的紧急状态和无障碍失败。此节是每个元素的实现简报 —
> 在任何元素进入开发之前完整填写它。

**Worked example — element overview table (4.1)**:
**完整示例 — 元素总览表（4.1）**：

| Element Name | Zone | Always Visible | Visibility Trigger | Data Source | Update Frequency | Max Size (% screen W) | Min Readable Size | Overlap Priority | Accessibility Alt |
|-------------|------|---------------|-------------------|-------------|-----------------|----------------------|------------------|-----------------|------------------|
| [Health Bar] | [Top Left] | [Yes] | [N/A] | [PlayerStats] | [On value change] | [20%] | [120px wide] | [1 — highest] | [Numerical text label showing current/max: "80/100"] |
| [Stamina Bar] | [Top Left] | [No — context] | [Show when consuming stamina; hide 3s after full] | [PlayerStats] | [Realtime during use] | [15%] | [80px wide] | [2] | [Numerical label, or hide if full (accessible assumption)] |
| [Shield Indicator] | [Top Left] | [No — context] | [Show when shield is active or recently hit] | [PlayerStats] | [On value change] | [20%] | [120px wide] | [3] | [Numerical label. Must not use color alone — add shield icon.] |
| [Ammo Counter] | [Top Right] | [No — context] | [Show when weapon is equipped; hide when unarmed] | [WeaponSystem] | [On fire / on reload] | [10%] | ["88/888" readable at game's min resolution] | [4] | [Text-only fallback: "32 / 120"] |
| [Minimap] | [Bottom Left] | [Yes] | [N/A — but suppressed in cinematic mode] | [NavigationSystem] | [Realtime] | [18%] | [150x150px] | [5] | [Cardinal direction compass strip as fallback; must be toggleable] |
| [Quest Objective] | [Top Center] | [No — context] | [Show on objective change; show when near objective location; hide after 5s] | [QuestSystem] | [On event] | [30%] | [Legible at body text size] | [6] | [Read aloud on objective change via screen reader] |
| [Crosshair] | [Center] | [No — context] | [Show when ranged weapon equipped; hide in melee or unarmed] | [WeaponSystem / AimSystem] | [Realtime] | [3%] | [12px diameter minimum] | [1 — center zone priority] | [Reduce motion: static crosshair only. Option to enlarge.] |
| [Interaction Prompt] | [Center] | [No — context] | [Show when player is within interaction range of an interactive object] | [InteractionSystem] | [On enter/exit interaction range] | [15%] | [24px icon + readable text] | [2 — center zone] | [Text description of interaction always present, not icon-only] |
| [Subtitles] | [Bottom Center] | [No — always on when dialogue plays, if setting enabled] | [Show during any voiced line or ambient dialogue] | [DialogueSystem] | [Per dialogue line] | [60%] | [Minimum 24px font] | [1 — highest in zone] | [This IS the accessibility feature — see Section 8 for subtitle spec] |
| [Damage Numbers] | [World-space / anchored to entity] | [No — context] | [Show on any damage event; duration 800ms] | [CombatSystem] | [On event] | [5% per number] | [18px minimum] | [3] | [Option to disable; numbers can overwhelm for photosensitive players] |
| [Status Effect Icons] | [Top Left — below health bar] | [No — context] | [Show when any status effect is active on player] | [StatusSystem] | [On effect add/remove] | [3% per icon] | [24px per icon] | [3] | [Icon + text label on hover/focus. Never icon-only.] |
| [Notification Toast] | [Bottom Right] | [No — event-driven] | [On loot, XP gain, achievement, quest update] | [Multiple — see Section 6] | [On event] | [25%] | [Legible at body text size] | [7 — lowest] | [Queued; never overlapping. Read by screen reader if subtitle mode on.] |

| 元素名称 | 区域 | 始终可见 | 可见性触发条件 | 数据源 | 更新频率 | 最大尺寸（屏幕宽度 %） | 最小可读尺寸 | 重叠优先级 | 无障碍替代 |
|-------------|------|---------------|-------------------|-------------|-----------------|----------------------|------------------|-----------------|------------------|
| [血条] | [左上] | [是] | [N/A] | [PlayerStats] | [数值变化时] | [20%] | [宽 120px] | [1 — 最高] | [显示当前/最大值的数字文本标签：“80/100”] |
| [耐力条] | [左上] | [否 — 情境] | [消耗耐力时显示；满后 3 秒隐藏] | [PlayerStats] | [使用期间实时] | [15%] | [宽 80px] | [2] | [数字标签，或满时隐藏（无障碍假设）] |
| [护盾指示] | [左上] | [否 — 情境] | [护盾激活或最近受击时显示] | [PlayerStats] | [数值变化时] | [20%] | [宽 120px] | [3] | [数字标签。不得仅用颜色 — 添加护盾图标。] |
| [弹药计数器] | [右上] | [否 — 情境] | [装备武器时显示；徒手时隐藏] | [WeaponSystem] | [开火 / 换弹时] | [10%] | [“88/888”在游戏最低分辨率下可读] | [4] | [仅文本备选：“32 / 120”] |
| [小地图] | [左下] | [是] | [N/A — 但电影化模式中抑制] | [NavigationSystem] | [实时] | [18%] | [150x150px] | [5] | [基本方位罗盘条作为备选；必须可开关] |
| [任务目标] | [顶部居中] | [否 — 情境] | [目标变化时显示；靠近目标位置时显示；5 秒后隐藏] | [QuestSystem] | [事件时] | [30%] | [正文字号可读] | [6] | [目标变化时通过屏幕阅读器朗读] |
| [准星] | [中央] | [否 — 情境] | [装备远程武器时显示；近战或徒手时隐藏] | [WeaponSystem / AimSystem] | [实时] | [3%] | [直径最小 12px] | [1 — 中央区域优先] | [减少动态效果：仅静态准星。可选放大。] |
| [交互提示] | [中央] | [否 — 情境] | [玩家进入可交互物体的交互范围时显示] | [InteractionSystem] | [进入/退出交互范围时] | [15%] | [24px 图标 + 可读文字] | [2 — 中央区域] | [始终提供交互的文字描述，而非仅图标] |
| [字幕] | [底部居中] | [否 — 若设置启用，对话播放时始终开启] | [任何配音台词或环境对话期间显示] | [DialogueSystem] | [每行对话] | [60%] | [最小 24px 字号] | [1 — 区域内最高] | [这**本身**就是无障碍功能 — 字幕规格见第 8 节] |
| [伤害数字] | [世界空间 / 锚定到实体] | [否 — 情境] | [任何伤害事件时显示；持续 800 毫秒] | [CombatSystem] | [事件时] | [每个数字 5%] | [最小 18px] | [3] | [可禁用；数字可能使光敏感玩家不堪重负] |
| [状态效果图标] | [左上 — 血条下方] | [否 — 情境] | [玩家身上有任何状态效果激活时显示] | [StatusSystem] | [效果添加/移除时] | [每个图标 3%] | [每个图标 24px] | [3] | [图标 + 悬停/聚焦时文字标签。绝不只有图标。] |
| [通知 toast] | [右下] | [否 — 事件驱动] | [战利品、XP 获得、成就、任务更新时] | [多个 — 见第 6 节] | [事件时] | [25%] | [正文字号可读] | [7 — 最低] | [排队；绝不重叠。若字幕模式开启，由屏幕阅读器读取。] |

**Worked example — element detail blocks (4.2)**:
**完整示例 — 元素详情块（4.2）**：

---

**Health Bar**
**血条**

- Visual description: [Horizontal fill bar. Left-to-right fill direction. Segmented at 25/50/75% to aid reading at a glance. Background: dark semi-transparent (40% opacity). Fill color: context-dependent — see Urgency States.]
- Data displayed: [Current HP as fill percentage. Numerical value displayed as text below bar at all times: "80 / 100".]
- Update behavior: [Bar fill decreases or increases smoothly using a lerp over 150ms per change. Large damage (>25% single hit) triggers a brief flash (1 frame white, then drain).]
- Urgency states:
  - Normal (>50% HP): [Green fill, no special behavior]
  - Caution (25–50% HP): [Yellow fill, low warning pulse every 4 seconds]
  - Critical (<25% HP): [Red fill, persistent slow pulse (1 Hz), vignette appears at screen edges]
  - Zero (0% HP): [Bar empties and turns grey; death state begins]
- Interaction: [Display only. Not interactive. Player cannot click, hover, or focus this element as an action target.]
- Player customization: [Opacity adjustable (see Section 7 Tuning Knobs). Can be repositioned to any corner by player in accessibility settings.]
- 视觉描述：[水平填充条。从左到右填充方向。在 25/50/75% 处分段，以便一眼读取。背景：深色半透明（40% 不透明度）。填充颜色：依情境而定 — 见紧急状态。]
- 显示数据：[当前 HP 以填充百分比表示。数值始终以条下方文字显示：“80 / 100”。]
- 更新行为：[条形填充使用插值在每次变化 150 毫秒内平滑减少或增加。大额伤害（单次命中 >25%）触发短暂闪烁（1 帧白色，然后排空）。]
- 紧急状态：
  - 正常（>50% HP）：[绿色填充，无特殊行为]
  - 警戒（25–50% HP）：[黄色填充，每 4 秒低强度警告脉动]
  - 危急（<25% HP）：[红色填充，持续慢速脉动（1 Hz），屏幕边缘出现暗角]
  - 归零（0% HP）：[条形清空并变灰；死亡状态开始]
- 交互：[仅显示。不可交互。玩家不能点击、悬停或聚焦此元素作为动作目标。]
- 玩家自定义：[不透明度可调（见第 7 节调参旋钮）。玩家可在无障碍设置中重定位到任意角落。]

---

**Minimap**
**小地图**

- Visual description: [Circular mask, radius = 75px at reference resolution 1920x1080. Player icon at center. North always up unless player has unlocked "Rotate minimap" setting. Range = configurable, default 80 world units radius.]
- Data displayed: [Player position, nearby enemies (if detection perk unlocked), quest markers within range, points of interest icons, traversal obstacles (walls, drops).]
- Update behavior: [Realtime. Updates every frame. Enemy icons fade in/out as they enter/leave detection range over 300ms.]
- Urgency states: [None for the map itself. Enemy icons turn red when they are in combat-alert state.]
- Interaction: [Not interactive in-game. Press dedicated Map button to open the full map screen (separate UX spec).]
- Player customization: [Size: S/M/L (70/90/110px radius). Opacity: 30–100%. Rotation: locked-north or player-relative. Can be disabled entirely (compass strip shows as fallback).]
- 视觉描述：[圆形遮罩，参考分辨率 1920x1080 下半径 = 75px。玩家图标在中心。除非玩家解锁“旋转小地图”设置，否则北始终朝上。范围 = 可配置，默认半径 80 世界单位。]
- 显示数据：[玩家位置、附近敌人（若解锁侦测特长）、范围内任务标记、兴趣点图标、通行障碍（墙、落差）。]
- 更新行为：[实时。每帧更新。敌人图标在 300 毫秒内进入/离开侦测范围时淡入/淡出。]
- 紧急状态：[地图本身无。敌人图标在其处于战斗警戒状态时变红。]
- 交互：[游戏内不可交互。按专用地图按钮打开完整地图屏幕（单独的 UX 规格）。]
- 玩家自定义：[尺寸：S/M/L（半径 70/90/110px）。不透明度：30–100%。旋转：锁定北向或相对于玩家。可完全禁用（以罗盘条作为备选显示）。]

---

## Section 5 — HUD States by Gameplay Context
## 第 5 节 — 按玩法情境的 HUD 状态

> **Why this section exists**: The HUD is not a static overlay — it is a dynamic
> system that must adapt to what the player is doing. A HUD designed only for
> standard gameplay will look wrong in cutscenes, feel cluttered in exploration,
> and occlude critical information in boss fights. This section defines the
> transformations the HUD undergoes in each gameplay context. It is also the spec
> for the system that manages HUD visibility — the HUD state machine.
> **为何存在此节**：HUD 不是静态覆盖层 — 它是一套动态系统，必须适应玩家正在做什么。
> 仅为标准玩法设计的 HUD 在过场中会显得错误、在探索中会感觉杂乱、在 Boss 战中会遮挡关键信息。
> 此节定义 HUD 在每种玩法情境中经历的变换。它也是管理 HUD 可见性的系统 — HUD 状态机 — 的规格。

**Worked example table**:
**完整示例表**：

| Context | Elements Shown | Elements Hidden | Elements Modified | Transition Into This State |
|---------|---------------|-----------------|------------------|---------------------------|
| [Exploration — no threats] | [Minimap, Quest Objective (faded, 60%), Subtitles (if active)] | [Ammo Counter, Crosshair, Damage Numbers, Status Effects (if none active)] | [Health Bar fades to 40% opacity — visible but not dominant] | [Fade transition, 500ms, when no enemies detected for 10s] |
| [Combat — active threat] | [Health Bar (full opacity), Stamina Bar (when used), Ammo Counter, Crosshair, Damage Numbers, Status Effects, Enemy Health Bars] | [Quest Objective (temporarily hidden), Notification Toasts (paused queue)] | [Minimap scales down 15% and raises opacity to 100%] | [Immediate snap in on first enemy detection — no fade. Combat readiness requires instant info.] |
| [Dialogue / Cutscene] | [Subtitles, Dialogue speaker name] | [All gameplay HUD elements: health, ammo, minimap, crosshair, damage numbers] | [N/A] | [All gameplay elements fade out over 300ms when cutscene flag is set] |
| [Cinematic (scripted camera sequence)] | [Subtitles only] | [Everything else including speaker name] | [Letterbox bars appear (if applicable to this game's style)] | [Immediate on cinematic flag; letterbox slides in from top/bottom over 400ms] |
| [Inventory / Menu open] | [None — inventory renders full-screen or as overlay] | [All HUD elements] | [Game world visible but paused behind inventory screen] | [All HUD elements hide over 150ms as menu opens] |
| [Death / Respawn pending] | [Death screen overlay — separate spec] | [All gameplay HUD elements] | [Screen desaturates and darkens over 800ms] | [Death state begins when HP reaches 0 — HUD elements fade over 600ms] |
| [Loading / Transition] | [Loading indicator, tip text] | [All gameplay HUD elements] | [N/A] | [Instant on level transition trigger] |
| [Tutorial — new mechanic] | [Standard context HUD + Tutorial Prompt overlay] | [Nothing additional hidden] | [Tutorial prompt dims background subtly to draw attention to prompt] | [Tutorial system fires ShowTutorial event; prompt fades in over 200ms] |
| [Boss Encounter] | [Boss health bar appears (large, bottom of screen or top center), all combat elements] | [Quest Objective] | [Boss bar renders in a distinct visual style — must not be confused with player health] | [Boss health bar slides in on boss encounter trigger over 400ms] |

| 情境 | 显示的元素 | 隐藏的元素 | 修改的元素 | 进入此状态的过渡 |
|---------|---------------|-----------------|------------------|---------------------------|
| [探索 — 无威胁] | [小地图、任务目标（淡化，60%）、字幕（若活跃）] | [弹药计数器、准星、伤害数字、状态效果（若无活跃）] | [血条淡至 40% 不透明度 — 可见但不主导] | [10 秒未侦测到敌人时的淡入淡出过渡，500 毫秒] |
| [战斗 — 活跃威胁] | [血条（全不透明度）、耐力条（使用时）、弹药计数器、准星、伤害数字、状态效果、敌人血条] | [任务目标（暂时隐藏）、通知 toast（暂停队列）] | [小地图缩小 15%，不透明度提升至 100%] | [首次侦测到敌人时立即切入 — 无淡化。战斗就绪需要即时信息。] |
| [对话 / 过场] | [字幕、对话说话人名称] | [所有玩法 HUD 元素：生命、弹药、小地图、准星、伤害数字] | [N/A] | [设置过场标记时，所有玩法元素在 300 毫秒内淡出] |
| [电影化（脚本化相机序列）] | [仅字幕] | [其他一切，包括说话人名称] | [出现黑边（若适用此游戏风格）] | [电影化标记时立即生效；黑边在 400 毫秒内从上/下滑入] |
| [库存 / 菜单打开] | [无 — 库存全屏或作为覆盖层渲染] | [所有 HUD 元素] | [游戏世界可见但在库存屏幕后暂停] | [菜单打开时所有 HUD 元素在 150 毫秒内隐藏] |
| [死亡 / 待重生] | [死亡屏幕覆盖层 — 单独规格] | [所有玩法 HUD 元素] | [屏幕在 800 毫秒内去饱和并变暗] | [HP 归零时开始死亡状态 — HUD 元素在 600 毫秒内淡出] |
| [加载 / 过渡] | [加载指示、提示文字] | [所有玩法 HUD 元素] | [N/A] | [关卡过渡触发时立即] |
| [教程 — 新机制] | [标准情境 HUD + 教程提示覆盖层] | [不额外隐藏任何内容] | [教程提示轻微压暗背景以将注意力引向提示] | [教程系统触发 ShowTutorial 事件；提示在 200 毫秒内淡入] |
| [Boss 遭遇] | [出现 Boss 血条（大型，屏幕底部或顶部居中），所有战斗元素] | [任务目标] | [Boss 条以独特视觉风格渲染 — 不得与玩家生命混淆] | [Boss 遭遇触发时 Boss 血条在 400 毫秒内滑入] |

---

## Section 6 — Information Hierarchy
## 第 6 节 — 信息层级

> **Why this section exists**: Not all HUD information is equally important. When
> screen space is limited, when the player is under high stress, or when elements
> compete for the same zone, there must be a principled priority order that governs
> which elements survive and which get suppressed. This section formalizes that
> hierarchy so it can be enforced systematically and not just "feels obvious" decisions
> made at implementation time.
> **为何存在此节**：并非所有 HUD 信息都同等重要。当屏幕空间有限、玩家处于高压状态，
> 或元素争夺同一区域时，必须有一个有原则的优先级顺序，决定哪些元素保留、哪些被抑制。
> 此节将这一层级形式化，以便系统性地执行，而不是只在实现时凭“感觉明显”做决策。

**Worked example table**:
**完整示例表**：

| Element | Priority Tier | Reasoning | What Replaces It If Hidden |
|---------|--------------|-----------|---------------------------|
| [Subtitles] | [MUST KEEP — never hide during dialogue] | [Accessibility requirement. Legal requirement in some markets. Story clarity.] | [N/A — nothing replaces subtitles] |
| [Health Bar] | [MUST KEEP — during any state where the player can be damaged] | [Without health visibility, survival decisions become impossible] | [Auditory cues (heartbeat, breathing) supplement but do not replace] |
| [Crosshair] | [MUST KEEP — while aiming with a ranged weapon] | [Targeting without a crosshair is a precision failure, not a difficulty feature] | [Alternative: dot-only mode for minimalists; never fully hidden while aiming] |
| [Interaction Prompt] | [MUST KEEP — when player is in interaction range] | [Without it, interactive objects are invisible to the player] | [Environmental visual cues can supplement but interaction affordance must be explicit] |
| [Ammo Counter] | [SHOULD KEEP] | [Low ammo decisions (switch weapon, reload) require awareness; can be contextual] | [Auditory "click" on empty chamber is acceptable fallback for experienced players] |
| [Minimap] | [SHOULD KEEP] | [Navigation requires spatial awareness; loss forces repeated map opens] | [Compass strip (simplified directional indicator) is acceptable fallback] |
| [Status Effects] | [SHOULD KEEP — while active] | [Active debuffs change what actions are viable; invisible debuffs feel unfair] | [Character animation states can partially communicate status effects (limping, sparks)] |
| [Quest Objective] | [CAN HIDE] | [Player can hold objective in memory for extended periods; contextual is correct default] | [Player remembers objective from context] |
| [Damage Numbers] | [CAN HIDE] | [Feedback element, not decision-critical. Many players turn these off.] | [Hit sounds and enemy reactions communicate hit registration] |
| [Notification Toasts] | [CAN HIDE in high-intensity moments] | [Mid-combat "You gained 50 XP" is noise, not signal. Queue and show after combat.] | [Queue held and released when combat ends] |
| [Combo Counter] | [ALWAYS HIDE when combo resets or player is not attacking] | [Stale combo information is actively misleading] | [N/A — simply hidden] |

| 元素 | 优先级层级 | 理由 | 若隐藏则由什么替代 |
|---------|--------------|-----------|---------------------------|
| [字幕] | [必须保留 — 对话期间绝不隐藏] | [无障碍要求。部分市场的法律要求。故事清晰度。] | [N/A — 没有什么能替代字幕] |
| [血条] | [必须保留 — 在玩家可能受伤的任何状态期间] | [没有生命可见性，生存决策变得不可能] | [听觉提示（心跳、呼吸）补充但不替代] |
| [准星] | [必须保留 — 使用远程武器瞄准时] | [没有准星瞄准是精度失败，而非难度特性] | [替代：极简者的仅点模式；瞄准时绝不完全隐藏] |
| [交互提示] | [必须保留 — 玩家处于交互范围时] | [没有它，可交互物体对玩家不可见] | [环境视觉线索可补充，但交互可供性必须显式] |
| [弹药计数器] | [应当保留] | [低弹药决策（换武器、换弹）需要感知；可情境化] | [空膛时的听觉“咔嗒”声对经验丰富的玩家是可接受的备选] |
| [小地图] | [应当保留] | [导航需要空间感知；失去它会迫使反复打开地图] | [罗盘条（简化的方向指示）是可接受的备选] |
| [状态效果] | [应当保留 — 激活时] | [活跃减益改变哪些动作可行；不可见的减益让人感觉不公平] | [角色动画状态可部分传达状态效果（跛行、火花）] |
| [任务目标] | [可以隐藏] | [玩家能在较长时间内记住目标；情境化是正确的默认] | [玩家从情境中记住目标] |
| [伤害数字] | [可以隐藏] | [反馈元素，而非决策关键。许多玩家会关闭它们。] | [受击音效和敌人反应传达命中判定] |
| [通知 toast] | [高强度时刻可以隐藏] | [战斗中途的“你获得了 50 XP”是噪音，而非信号。排队并在战斗后显示。] | [队列保持并在战斗结束时释放] |
| [连击计数器] | [连击重置或玩家未攻击时始终隐藏] | [过时的连击信息会主动误导] | [N/A — 直接隐藏] |

---

## Section 7 — Visual Budget
## 第 7 节 — 视觉预算

> **Why this section exists**: Without explicit budget constraints, HUD elements
> accumulate until the game world is nearly invisible. These numbers are hard limits,
> not guidelines. Every element addition that would breach a limit requires explicit
> approval and must displace or reduce an existing element.
> **为何存在此节**：没有明确的预算约束，HUD 元素会不断累积，直到游戏世界几乎不可见。
> 这些数字是硬性限制，而非指导原则。任何会突破限制的元素新增都需要明确批准，
> 且必须挤占或减少一个现有元素。

> **How to apply these budgets**: For every new HUD element proposed during
> production, require the proposer to state (1) which budget line it affects,
> (2) what the new total will be, and (3) what existing element will be reduced or
> made contextual to stay within budget. "It's a small icon" is not an analysis.
> **如何应用这些预算**：对于制作期间提出的每个新 HUD 元素，要求提出者说明
> (1) 它影响哪条预算线，(2) 新的总量将是多少，(3) 为保持在预算内，将减少哪个现有元素
> 或将其改为情境化。“这只是个小图标”不是分析。

---

## Section 8 — Feedback & Notification Systems
## 第 8 节 — 反馈与通知系统

> **Why this section exists**: Notifications are the most frequently-added and
> worst-controlled part of most HUDs. Every system wants to tell the player
> something. Without explicit rules about notification priority, stacking limits,
> and queue behavior, the notification zone becomes a firehose of overlapping
> toasts that players learn to ignore entirely. This section establishes the
> notification contract for all systems.
> **为何存在此节**：通知是大多数 HUD 中最常添加、最难控制的部分。每个系统都想告诉玩家一些事情。
> 没有关于通知优先级、堆叠上限和队列行为的明确规则，通知区域就会变成重叠 toast 的消防水管，
> 玩家学会完全忽略它们。此节为所有系统建立通知契约。

**Worked example table**:
**完整示例表**：

| Notification Type | Trigger System | Screen Position | Duration (ms) | Animation In / Out | Max Simultaneous | Priority | Queue Behavior | Dismissible? |
|------------------|---------------|-----------------|--------------|-------------------|-----------------|----------|---------------|-------------|
| [Item Pickup] | [InventorySystem] | [Bottom Right — toast] | [2000] | [Slide in from right 200ms / fade out 300ms] | [3 stacked] | [Low] | [FIFO queue; older toasts pushed up as new ones enter] | [No — auto-dismiss] |
| [XP Gain] | [ProgressionSystem] | [Bottom Right — toast, below item toasts] | [1500] | [Fade in 150ms / fade out 300ms] | [1 — XP messages merge: "XP +150"] | [Very Low — suppress during combat, queue for post-combat] | [Combat-aware queue] | [No] |
| [Level Up] | [ProgressionSystem] | [Center screen — persistent until dismissed] | [Persistent — requires input to dismiss] | [Scale up from 80% + fade in 400ms] | [1] | [High — interrupts normal toasts] | [Pauses all other notifications until dismissed] | [Yes — any input] |
| [Quest Update] | [QuestSystem] | [Top Center] | [4000] | [Slide down from top 250ms / fade out 400ms] | [1 — top center is single-message zone] | [Medium] | [If quest update arrives while previous is visible, extend duration by 2000ms; do not stack] | [No] |
| [Objective Complete] | [QuestSystem] | [Top Center] | [3000] | [Same as Quest Update but with additional completion sound] | [1] | [Medium-High — preempts Quest Update] | [Preempts any queued top-center message] | [No] |
| [Critical Warning (low health, hazard)] | [CombatSystem / EnvironmentSystem] | [Screen edge vignette + text at center-bottom] | [Persistent while condition active] | [Fade in 200ms; fades out 500ms when condition clears] | [1 per warning type] | [Critical — never suppressed] | [Renders immediately, bypasses all queues] | [No] |
| [Achievement Unlocked] | [AchievementSystem] | [Bottom Right — distinct from item toasts] | [4000] | [Slide in from right with icon expansion 300ms / fade out 400ms] | [1] | [Low] | [Queues behind item toasts; never more than one achievement toast at a time] | [No] |
| [Hint / Tutorial] | [TutorialSystem] | [Bottom Center] | [Persistent — until player performs the action or dismisses] | [Fade in 300ms] | [1] | [Medium] | [Only one tutorial hint at a time; queue others] | [Yes — B button / Esc] |

| 通知类型 | 触发系统 | 屏幕位置 | 持续时间（毫秒） | 进入 / 退出动画 | 最大同时数 | 优先级 | 队列行为 | 可消除？ |
|------------------|---------------|-----------------|--------------|-------------------|-----------------|----------|---------------|-------------|
| [物品拾取] | [InventorySystem] | [右下 — toast] | [2000] | [从右侧滑入 200 毫秒 / 淡出 300 毫秒] | [3 堆叠] | [低] | [FIFO 队列；新 toast 进入时旧 toast 上推] | [否 — 自动消失] |
| [XP 获得] | [ProgressionSystem] | [右下 — toast，位于物品 toast 下方] | [1500] | [淡入 150 毫秒 / 淡出 300 毫秒] | [1 — XP 消息合并：“XP +150”] | [极低 — 战斗中抑制，战后排队] | [战斗感知队列] | [否] |
| [升级] | [ProgressionSystem] | [屏幕中央 — 持续直到消除] | [持续 — 需要输入来消除] | [从 80% 放大 + 淡入 400 毫秒] | [1] | [高 — 打断普通 toast] | [暂停所有其他通知直到消除] | [是 — 任意输入] |
| [任务更新] | [QuestSystem] | [顶部居中] | [4000] | [从顶部滑下 250 毫秒 / 淡出 400 毫秒] | [1 — 顶部居中是单消息区域] | [中] | [若前一条可见时任务更新到达，时长延长 2000 毫秒；不堆叠] | [否] |
| [目标完成] | [QuestSystem] | [顶部居中] | [3000] | [同任务更新，但附加完成音效] | [1] | [中高 — 抢占任务更新] | [抢占任何排队的顶部居中消息] | [否] |
| [关键警告（低生命、危险）] | [CombatSystem / EnvironmentSystem] | [屏幕边缘暗角 + 底部居中文字] | [条件活跃期间持续] | [淡入 200 毫秒；条件清除时淡出 500 毫秒] | [每种警告 1 条] | [关键 — 绝不抑制] | [立即渲染，绕过所有队列] | [否] |
| [成就解锁] | [AchievementSystem] | [右下 — 区别于物品 toast] | [4000] | [从右侧滑入并图标扩展 300 毫秒 / 淡出 400 毫秒] | [1] | [低] | [排在物品 toast 之后；一次绝不超过一条成就 toast] | [否] |
| [提示 / 教程] | [TutorialSystem] | [底部居中] | [持续 — 直到玩家执行动作或消除] | [淡入 300 毫秒] | [1] | [中] | [一次仅一条教程提示；其他排队] | [是 — B 按钮 / Esc] |

**Worked example — notification queue rules**:
1. Combat-aware queue: notifications tagged as Low priority are queued, not displayed, when the player is in combat state. The queue is flushed in a batch when the player exits combat, with a max of 3 items displayed in sequence.
2. Merge rule: identical notification types that fire within 500ms of each other are merged into a single notification with a combined value (e.g., "Item Pickup x3" rather than three separate toasts).
3. Critical notifications (health warning, environmental hazard) are never queued, never merged, and always displayed immediately regardless of combat state or existing notifications.
**完整示例 — 通知队列规则**：
1. 战斗感知队列：当玩家处于战斗状态时，标记为低优先级的通知会排队而不显示。玩家退出战斗时队列批量刷新，最多按顺序显示 3 条。
2. 合并规则：彼此在 500 毫秒内触发的相同通知类型合并为一条带合计值的通知（例如，“物品拾取 x3”，而非三条独立 toast）。
3. 关键通知（生命警告、环境危险）从不排队、从不合并，并且无论战斗状态或现有通知如何都立即显示。

---

## Section 9 — Platform Adaptation
## 第 9 节 — 平台适配

> **Why this section exists**: A HUD designed at 1920x1080 on a monitor may be
> illegible on a 55-inch TV at 4K, broken at 1280x720 on Steam Deck, or hidden
> behind a notch on mobile. Platform adaptation is not optional post-ship work —
> it is a design requirement that must be specified before implementation so the
> architecture can support it from the start. Every platform listed here requires
> explicit layout testing before certification.
> **为何存在此节**：在显示器上以 1920x1080 设计的 HUD，在 55 英寸 4K 电视上可能无法辨认，
> 在 Steam Deck 的 1280x720 下可能损坏，或在移动端被刘海遮挡。平台适配不是可选的发布后工作 —
> 它是必须在实现前规定好的设计需求，以便架构从一开始就能支持它。此处列出的每个平台
> 在认证前都需要明确的布局测试。

**Worked example table**:
**完整示例表**：

| Platform | Safe Zone | Resolution Range | Input Method | HUD-Specific Notes |
|----------|-----------|-----------------|-------------|-------------------|
| [PC — Windows, 1920x1080 reference] | [3% margin] | [1280x720 min to 3840x2160 max] | [Mouse + keyboard, controller optional] | [HUD must scale correctly at all resolutions. Test at 1280x720 — minimum before cert. Consider ultrawide (21:9) — minimap must not stretch.] |
| [PC — Steam Deck, 1280x800] | [5% margin] | [Fixed 1280x800] | [Controller + touchscreen] | [Smaller screen means minimum text sizes are critical. Test ALL elements at this resolution. Touch targets irrelevant (controller-only by default).] |
| [PlayStation 5 / Xbox Series X] | [10% margin] | [1080p to 4K] | [Controller] | [Console certification requires TV safe zone compliance. Action-safe is 90% of screen area. Test on a real TV, not a monitor — overscan behavior differs.] |
| [Mobile — iOS / Android] | [15% top, 10% other sides] | [360x640 min to 414x896 common] | [Touch] | [Notch/camera cutout avoidance at top. Bottom home indicator zone avoidance. Portrait and landscape layouts may differ significantly — specify both.] |

| 平台 | 安全区 | 分辨率范围 | 输入方式 | HUD 专属备注 |
|----------|-----------|-----------------|-------------|-------------------|
| [PC — Windows，1920x1080 参考] | [3% 边距] | [最低 1280x720 至最高 3840x2160] | [鼠标 + 键盘，手柄可选] | [HUD 必须在所有分辨率下正确缩放。在 1280x720 测试 — 认证前的最低要求。考虑超宽屏（21:9）— 小地图不得拉伸。] |
| [PC — Steam Deck，1280x800] | [5% 边距] | [固定 1280x800] | [手柄 + 触摸屏] | [屏幕更小意味着最小字号至关重要。在此分辨率下测试**所有**元素。触摸目标无关紧要（默认仅手柄）。] |
| [PlayStation 5 / Xbox Series X] | [10% 边距] | [1080p 至 4K] | [手柄] | [主机认证要求电视安全区合规。动作安全区为屏幕面积的 90%。在真实电视上测试，而非显示器 — 过扫描行为不同。] |
| [移动端 — iOS / Android] | [顶部 15%，其他边 10%] | [最低 360x640 至常见 414x896] | [触摸] | [顶部避开刘海/摄像头开口。底部避开主屏幕指示条区域。竖屏和横屏布局可能显著不同 — 两者都要规定。] |

---

## Section 10 — Accessibility
## 第 10 节 — 无障碍

> **Why this section exists**: HUD accessibility failures are the most visible
> accessibility failures in games — players encounter the HUD in every session,
> in every gameplay moment. Color-blind failures, illegible text at minimum scale,
> and inability to disable distracting animations are among the top accessibility
> complaints in game reviews. This section defines HUD-specific requirements; refer
> to the project's `design/accessibility-requirements.md` for the full project standard.
> **为何存在此节**：HUD 无障碍失败是游戏中最显眼的无障碍失败 — 玩家在每个会话、每个玩法时刻
> 都会遇到 HUD。色盲失败、最小缩放下的不可读文字，以及无法禁用干扰性动画，
> 是游戏评测中最常见的无障碍投诉。此节定义 HUD 专属需求；完整项目标准请参考项目的
> `design/accessibility-requirements.md`。

**Worked example — colorblind modes table (10.1)**:
**完整示例 — 色盲模式表（10.1）**：

| Element | Color-Only Information Risk | Colorblind Mode Fix |
|---------|----------------------------|---------------------|
| [Health bar fill] | [Red = low health uses red/green distinction] | [Add icon pulse + vignette as non-color indicators. Red fill is supplemental, not sole indicator.] |
| [Damage numbers] | [Red = taken, green = healed] | [Add minus (-) prefix for damage, plus (+) for healing. Symbols, not color.] |
| [Enemy health bars] | [If colored by faction or threat level] | [Add text label or icon badge for faction/threat level. Never color-only.] |
| [Status effect icons] | [If icon tint communicates status type] | [All status icons must have distinct shapes, not just distinct colors. Shape encodes meaning; color is secondary.] |
| [Minimap icons] | [If player vs. enemy vs. objective distinguished by color] | [Distinct icon shapes: circle = player, triangle = enemy, star = objective. Color supplements shape.] |

| 元素 | 仅靠颜色的信息风险 | 色盲模式修正 |
|---------|----------------------------|---------------------|
| [血条填充] | [红色 = 低生命使用了红/绿区分] | [添加图标脉动 + 暗角作为非颜色指示。红色填充是补充，而非唯一指示。] |
| [伤害数字] | [红色 = 受到，绿色 = 治疗] | [为伤害添加负号（-）前缀，为治疗添加正号（+）。用符号而非颜色。] |
| [敌人血条] | [若按阵营或威胁等级着色] | [为阵营/威胁等级添加文字标签或图标徽章。绝不只用颜色。] |
| [状态效果图标] | [若图标色调传达状态类型] | [所有状态图标必须有独特形状，而不只是独特色彩。形状编码含义；颜色是次要的。] |
| [小地图图标] | [若玩家 vs. 敌人 vs. 目标以颜色区分] | [独特图标形状：圆形 = 玩家，三角形 = 敌人，星形 = 目标。颜色补充形状。] |

**Authoring the text scaling narrative (10.2)**:
**编写文本缩放叙述（10.2）**：

[Describe what happens when the player sets the UI text scale to 150% (the maximum required for your Accessibility Tier). Which elements reflow? Which elements clip? Which elements are architecturally blocked from scaling (e.g., fixed-size canvases)?

Example: "Health bar numerical label grows with text scale — bar expands slightly to accommodate. Quest objective text wraps at 150% scale — verify Top Center zone can accommodate two-line objectives. Damage numbers do not scale (they are world-space, not screen-space) — this is an accepted limitation documented here."]
[描述玩家将 UI 文本缩放设为 150%（你的无障碍层级所要求的最大值）时会发生什么。哪些元素重排？
哪些元素裁剪？哪些元素因架构限制无法缩放（例如，固定尺寸画布）？

示例：“血条数字标签随文本缩放增大 — 条形略微扩展以容纳。任务目标文本在 150% 缩放下换行 —
验证顶部居中区域能容纳两行目标。伤害数字不缩放（它们是世界空间，而非屏幕空间）—
这是此处记录的可接受限制。”]

**Worked example — text scaling test matrix (10.2)**:
**完整示例 — 文本缩放测试矩阵（10.2）**：

| Element | 100% (baseline) | 125% | 150% | Overflow behavior |
|---------|----------------|------|------|-------------------|
| [Health bar label] | [Pass] | [Pass] | [TBD] | [Bar expands; does not overlap stamina bar] |
| [Quest objective text] | [Pass] | [TBD] | [TBD] | [Wraps to second line; zone height expands] |
| [Notification toast text] | [Pass] | [TBD] | [TBD] | [Toast width expands to max 35% screen width, then wraps] |
| [Subtitle text] | [Pass] | [TBD] | [TBD] | [Dedicated subtitle zone — must accommodate scale] |

| 元素 | 100%（基线） | 125% | 150% | 溢出行为 |
|---------|----------------|------|------|-------------------|
| [血条标签] | [通过] | [通过] | [待定] | [条形扩展；不与耐力条重叠] |
| [任务目标文本] | [通过] | [待定] | [待定] | [换行到第二行；区域高度扩展] |
| [通知 toast 文本] | [通过] | [待定] | [待定] | [toast 宽度扩展至最大屏幕宽度的 35%，然后换行] |
| [字幕文本] | [通过] | [待定] | [待定] | [专用字幕区域 — 必须容纳缩放] |

**Worked example — motion sensitivity table (10.3)**:
**完整示例 — 运动敏感表（10.3）**：

| Animation / Motion Element | Severity | Disabled by Reduced Motion Setting? | Replacement Behavior |
|---------------------------|----------|-------------------------------------|---------------------|
| [Health bar low-HP pulse] | [Mild] | [Yes] | [Solid fill, no pulse. Vignette remains as it is less likely to trigger sensitivity.] |
| [Screen edge vignette] | [Moderate] | [Optional — separate toggle] | [Replace with static darkened corners at 30% opacity] |
| [Damage numbers float upward] | [Mild] | [Yes] | [Instant appear/disappear in place, no float] |
| [Notification toast slide-in] | [Mild] | [Yes] | [Instant appear at final position] |
| [Level up center animation] | [High] | [Yes — required] | [Static level up card, no scale animation, no particle effects] |
| [Combo counter scale pulse] | [Mild] | [Yes] | [Number increments without scale animation] |

| 动画 / 运动元素 | 严重程度 | 是否被减少动态效果设置禁用？ | 替代行为 |
|---------------------------|----------|-------------------------------------|---------------------|
| [血条低 HP 脉动] | [轻微] | [是] | [实心填充，无脉动。暗角保留，因为它较不可能触发敏感。] |
| [屏幕边缘暗角] | [中等] | [可选 — 单独开关] | [替换为 30% 不透明度的静态压暗角落] |
| [伤害数字向上飘浮] | [轻微] | [是] | [原地即时出现/消失，不飘浮] |
| [通知 toast 滑入] | [轻微] | [是] | [在最终位置即时出现] |
| [升级中央动画] | [强烈] | [是 — 必需] | [静态升级卡片，无缩放动画，无粒子效果] |
| [连击计数器缩放脉动] | [轻微] | [是] | [数字递增，无缩放动画] |

---

## Section 11 — Tuning Knobs
## 第 11 节 — 调参旋钮

> **Why this section exists**: HUD behavior should be data-driven to the same degree
> as gameplay systems. Values that are hardcoded are values that require an engineer
> to change. Values that are in config can be tuned by a designer or adjusted for
> player preferences. Document all tunable parameters before implementation so the
> programmer knows which values to externalize.
> **为何存在此节**：HUD 行为应像玩法系统一样数据驱动。硬编码的值是需要工程师才能更改的值。
> 配置中的值可由设计师调整，或根据玩家偏好调整。实现前记录所有可调参数，
> 以便程序员知道哪些值需要外置。

**Worked example table**:
**完整示例表**：

| Parameter | Current Value | Range | Effect of Increase | Effect of Decrease | Player Adjustable? | Notes |
|-----------|-------------|-------|-------------------|-------------------|-------------------|-------|
| [Notification display duration (default)] | [2000ms] | [500ms – 5000ms] | [Toasts persist longer — less likely to be missed, more screen clutter] | [Toasts disappear faster — cleaner, higher miss risk] | [No — but player can adjust verbosity level] | [Per-type overrides in Section 8 take precedence] |
| [Notification queue max size] | [8] | [3 – 15] | [More messages preserved but queue takes longer to clear] | [Older messages dropped earlier] | [No] | [Expand if playtesting reveals important messages being lost] |
| [Health bar low-HP pulse frequency] | [1 Hz] | [0.5 – 2 Hz] | [More urgent feeling — can become fatiguing] | [Calmer — may fail to communicate urgency] | [No — but Reduced Motion disables it] | [Linked to accessibility setting] |
| [Combat HUD reveal duration] | [0ms (instant)] | [0 – 300ms] | [Softer reveal — feels less jarring] | [Instant — highest responsiveness] | [No] | [Keep at 0ms — combat information must be instant] |
| [Exploration HUD fade-out delay] | [10000ms (10s after last threat)] | [3000 – 30000ms] | [HUD fades sooner — cleaner exploration] | [HUD stays longer — more reassurance] | [No] | [Tune based on playtest; 10s is a starting estimate] |
| [Minimap range (world units visible)] | [80] | [40 – 200] | [More map context visible] | [Tighter local view] | [Yes — Small/Medium/Large preset] | [Exposed as S/M/L, not raw unit value] |
| [Minimap size (px radius at 1080p)] | [75] | [50 – 120] | [Larger map, more screen space consumed] | [Smaller, less intrusive] | [Yes — S/M/L preset] | [Three sizes exposed to player] |
| [Damage number duration (ms)] | [800] | [400 – 1500] | [Numbers linger longer — easier to read, more cluttered] | [Numbers clear faster — cleaner, harder to parse] | [No] | [Tune based on visual noise in dense combat] |
| [Global HUD opacity] | [100%] | [0 – 100%] | [Fully visible] | [Fully hidden] | [Yes — opacity slider in Accessibility settings] | [0% = full HUD off; some players prefer this] |

| 参数 | 当前值 | 范围 | 增加的效果 | 减少的效果 | 玩家可调？ | 备注 |
|-----------|-------------|-------|-------------------|-------------------|-------------------|-------|
| [通知显示时长（默认）] | [2000 毫秒] | [500 毫秒 – 5000 毫秒] | [toast 停留更久 — 更不易错过，屏幕更杂乱] | [toast 消失更快 — 更清爽，错过风险更高] | [否 — 但玩家可调整详细度级别] | [第 8 节的按类型覆盖优先] |
| [通知队列最大容量] | [8] | [3 – 15] | [保留更多消息，但队列清空更慢] | [较早的消息更早被丢弃] | [否] | [若游戏测试发现重要消息丢失则扩大] |
| [血条低 HP 脉动频率] | [1 Hz] | [0.5 – 2 Hz] | [更紧迫的感觉 — 可能变得令人疲劳] | [更平静 — 可能无法传达紧迫感] | [否 — 但减少动态效果会禁用] | [与无障碍设置联动] |
| [战斗 HUD 显示时长] | [0 毫秒（即时）] | [0 – 300 毫秒] | [更柔和的显示 — 感觉不那么突兀] | [即时 — 最高响应性] | [否] | [保持 0 毫秒 — 战斗信息必须即时] |
| [探索 HUD 淡出延迟] | [10000 毫秒（最后威胁后 10 秒）] | [3000 – 30000 毫秒] | [HUD 更早淡出 — 探索更清爽] | [HUD 停留更久 — 更多安心感] | [否] | [根据游戏测试调整；10 秒是起始估计] |
| [小地图范围（可见世界单位）] | [80] | [40 – 200] | [可见更多地图情境] | [更紧凑的局部视图] | [是 — 小/中/大预设] | [以 S/M/L 暴露，而非原始单位值] |
| [小地图尺寸（1080p 下 px 半径）] | [75] | [50 – 120] | [更大的地图，占用更多屏幕空间] | [更小，更不干扰] | [是 — 小/中/大预设] | [向玩家暴露三种尺寸] |
| [伤害数字持续时长（毫秒）] | [800] | [400 – 1500] | [数字停留更久 — 更易读，更杂乱] | [数字清除更快 — 更清爽，更难解析] | [否] | [根据密集战斗中的视觉噪音调整] |
| [全局 HUD 不透明度] | [100%] | [0 – 100%] | [完全可见] | [完全隐藏] | [是 — 无障碍设置中的不透明度滑块] | [0% = 完全关闭 HUD；部分玩家偏好如此] |

---

## Section 12 — Acceptance Criteria
## 第 12 节 — 验收标准

> **Why this section exists**: These criteria are the certification checklist for the
> HUD. Every item must pass before the HUD can be marked Approved. QA must be able
> to verify each item independently.
> **为何存在此节**：这些标准是 HUD 的认证争夺清单。每一项都必须通过，HUD 才能标记为已批准。
> QA 必须能够独立验证每一项。

---

## Section 13 — Open Questions
## 第 13 节 — 待决问题

**Worked example questions**:
**完整示例问题**：

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [e.g., Should the minimap show enemy positions by default, or only after a detection skill is unlocked?] | [systems-designer + ux-designer] | [Sprint 5, Day 2] | [Pending — depends on progression GDD decision] |
| [e.g., Does the game have a boss health bar, or do bosses use the standard enemy health bar? Bosses need a visually distinct treatment if they are significantly more important than normal enemies.] | [game-designer] | [Sprint 5, Day 1] | [Pending] |
| [e.g., Damage numbers: diegetic (floating in world space, occluded by geometry) or screen space (always readable, overlaid on HUD layer)?] | [ux-designer + lead-programmer] | [Sprint 4, Day 5] | [Pending — architecture decision affects rendering layer choice] |
| [e.g., Mobile portrait vs. landscape: does the game support both orientations? If yes, each requires its own zone layout.] | [producer] | [Sprint 3, Day 3] | [Pending — platform scope decision required first] |

| 问题 | 负责人 | 截止日期 | 解决方式 |
|----------|-------|----------|-----------|
| [例如，小地图应默认显示敌人位置，还是仅在解锁侦测技能后才显示？] | [systems-designer + ux-designer] | [冲刺 5，第 2 天] | [待定 — 取决于进度 GDD 决策] |
| [例如，游戏有 Boss 血条吗，还是 Boss 使用标准敌人血条？若 Boss 比普通敌人重要得多，则需要视觉上独特的处理。] | [game-designer] | [冲刺 5，第 1 天] | [待定] |
| [例如，伤害数字：叙事内（在世界空间中飘浮，被几何体遮挡）还是屏幕空间（始终可读，叠加在 HUD 层上）？] | [ux-designer + lead-programmer] | [冲刺 4，第 5 天] | [待定 — 架构决策影响渲染层选择] |
| [例如，移动端竖屏 vs. 横屏：游戏支持两种方向吗？若支持，每种都需要自己的区域布局。] | [producer] | [冲刺 3，第 3 天] | [待定 — 需先做平台范围决策] |
