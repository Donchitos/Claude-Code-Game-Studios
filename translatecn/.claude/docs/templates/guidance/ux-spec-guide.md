> Authoring guidance for ux-spec.md. Load only the part covering the section currently being authored — not the whole file at once.
> ux-spec.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

# UX Specification Template — Authoring Guidance
# UX 规格模板 — 编写指南

Guidance is organized by template section number. When authoring a section of a
project's UX spec, read only that section's guidance below.
指南按模板章节编号组织。编写项目 UX 规格的某章节时，只阅读下面该章节的指南。

---

## Section 1 — Purpose & Player Need
## 第 1 节 — 目的与玩家需求

> **Why this section exists**: Every screen must justify its existence from the
> player's perspective. Screens that are designed from a developer perspective ("display
> the save data") produce cluttered, confusing interfaces. Screens designed from the
> player's perspective ("let the player feel confident their progress is safe before they
> put the controller down") produce purposeful, calm interfaces. Write this section before
> touching any layout decisions — it is the filter through which every subsequent choice
> is evaluated.
> **为何存在此节**：每个屏幕都必须从玩家视角证明其存在的理由。以开发者视角设计的屏幕
> （“显示存档数据”）会产生杂乱、令人困惑的界面。以玩家视角设计的屏幕
> （“让玩家在放下手柄前确信自己的进度是安全的”）会产生有目的、平静的界面。
> 在接触任何布局决策之前先写此节 — 它是评估所有后续选择的过滤器。

**Authoring the player need**:
**编写玩家需求**：

[One paragraph. Name the real human need, not the system function. Consider: what would
a player say they want when they open this screen? What would frustrate them if it did
not work? That frustration describes the need.

Example — bad: "Displays the player's current items and equipment."
Example — good: "Lets the player understand what they're carrying and quickly decide what
to take into the next encounter, without breaking their mental model of the game world.
The inventory is the player's planning tool between moments of action."]
[一段话。指出真实的人类需求，而非系统功能。考虑：玩家打开此屏幕时会说他们想要什么？
如果它不工作，什么会让他们沮丧？那种沮丧描述了需求。

示例 — 差：“显示玩家当前物品与装备。”
示例 — 好：“让玩家理解自己携带了什么，并快速决定带什么进入下一次遭遇，同时不破坏他们对游戏世界的
心智模型。库存是玩家在行动间隙的规划工具。”]

**Authoring the player goal**:
**编写玩家目标**：

[One sentence. Specific enough that you could write an acceptance criterion for it.
Example: "Find the item they are looking for within three button presses and equip it
without navigating to a separate screen."]
[一句话。具体到你可以据此写出验收标准。
示例：“在三次按键内找到他们要找的物品，并装备它，无需导航到单独屏幕。”]

**Authoring the game goal**:
**编写游戏目标**：

[One sentence. This is what the system needs from this interaction. Example: "Record the
player's equipment choices and relay them to the combat system before the next encounter
loads." This section prevents UI that looks good but fails to serve the system it is
part of.]
[一句话。这是系统从此交互中需要的东西。示例：“记录玩家的装备选择，并在下一次遭遇加载前
将它们传给战斗系统。”此节防止 UI 看起来好看但未能服务于它所属的系统。]

---

## Section 2 — Player Context on Arrival
## 第 2 节 — 玩家到达时的情境

> **Why this section exists**: Screens do not exist in isolation. A player opening the
> inventory mid-combat is in a completely different cognitive and emotional state than
> a player opening it after clearing a dungeon. The same information architecture can
> feel oppressively complex in one context and trivially simple in another. Document the
> context so that design decisions — what to show first, what to hide, what to animate,
> what to simplify — are calibrated to the actual player arriving at this screen, not
> an abstract user.
> **为何存在此节**：屏幕并非孤立存在。战斗中途打开库存的玩家，与清完地牢后打开库存的玩家，
> 处于完全不同的认知与情绪状态。同一套信息架构在一种情境下可能令人压抑地复杂，
> 在另一种情境下却简单得微不足道。记录情境，以便设计决策 — 先显示什么、隐藏什么、
> 动画什么、简化什么 — 是针对真正到达此屏幕的玩家来校准的，而非抽象用户。

**Worked example answers for the context table**:
**情境表的完整示例答案**：

| Question | Answer |
|----------|--------|
| What was the player just doing? | [e.g., Completed a combat encounter / Pressed Esc from exploration / Triggered a story cutscene] |
| What is their emotional state? | [e.g., High tension — just narrowly survived / Calm — exploring between objectives] |
| What cognitive load are they carrying? | [e.g., High — actively tracking enemy positions / Low — no active threats] |
| What information do they already have? | [e.g., They know they just picked up an item but haven't seen its stats yet] |
| What are they most likely trying to do? | [e.g., Check if the new item is better than their current weapon — primary use case] |
| What are they likely afraid of? | [e.g., Missing something, making an irreversible mistake, losing track of where they were] |

| 问题 | 答案 |
|----------|--------|
| 玩家刚才在做什么？ | [例如，完成战斗遭遇 / 探索时按 Esc / 触发故事过场] |
| 他们的情感状态是什么？ | [例如，高紧张 — 险些丧生 / 平静 — 在目标间探索] |
| 他们承受什么认知负载？ | [例如，高 — 主动追踪敌人位置 / 低 — 无活跃威胁] |
| 他们已有什么信息？ | [例如，他们知道刚拾起物品但还没看其属性] |
| 他们最可能在尝试做什么？ | [例如，检查新物品是否比当前武器更好 — 主要用例] |
| 他们可能害怕什么？ | [例如，错过什么、做出不可逆错误、忘记自己在何处] |

**Authoring the emotional design target**:
**编写情感设计目标**：

[One sentence describing the feeling the player should have while using this screen.
Example: "Confident and in control — the player should feel like they have complete
information and complete authority over their choices, with no ambiguity about outcomes."]
[一句话描述玩家使用此屏幕时应有的感受。
示例：“自信且掌控 — 玩家应觉得自己拥有完整信息，并对自己的选择拥有完全权威，结果毫无歧义。”]

---

## Section 3 — Navigation Position
## 第 3 节 — 导航位置

> **Why this section exists**: A screen that does not know where it sits in the
> navigation hierarchy cannot define its entry/exit transitions, its back-button
> behavior, or its relationship to the game's pause state. Navigation position also
> reveals architectural problems early — if this screen is reachable from eight
> different places, that is a complexity flag that should be resolved in design, not
> implementation.
> **为何存在此节**：不知道自己处于导航层级何处的屏幕，无法定义其进入/退出过渡、返回按钮行为，
> 或与游戏暂停状态的关系。导航位置也能尽早暴露架构问题 — 若此屏幕可从八个不同位置到达，
> 那就是一个复杂度警示，应在设计阶段解决，而非实现阶段。

**Worked example — reachability table**:
**完整示例 — 可达性表**：

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| [e.g., Main Menu → Play] | [Player selects "New Game"] | [Primary entry point] |
| [e.g., Pause Menu → Resume] | [Player presses Start from any gameplay state] | [Secondary entry] |
| [e.g., Game event] | [Tutorial system forces open first time only] | [Systemic entry — must not break if player dismisses] |

| 入口 | 触发者 | 备注 |
|-------------|-------------|-------|
| [例如，主菜单 → 玩] | [玩家选“新游戏”] | [主要入口] |
| [例如，暂停菜单 → 继续] | [玩家从任何游戏状态按 Start] | [次要入口] |
| [例如，游戏事件] | [教程系统仅首次强制打开] | [系统入口 — 玩家消除时不得中断] |

---

## Section 4 — Entry & Exit Points
## 第 4 节 — 进入与退出点

> **Why this section exists**: Entry and exit define the screen's contract with the
> rest of the navigation system. Every entry point must have a corresponding exit point.
> Transitions that are undefined become bugs — the player finds themselves stuck, or the
> game state becomes inconsistent. Fill this table completely before implementation
> begins. Empty cells are a sign that design work is unfinished.
> **为何存在此节**：进入与退出定义屏幕与导航系统其余部分的契约。每个入口点都必须有对应的出口点。
> 未定义的过渡会变成缺陷 — 玩家发现自己卡住，或游戏状态变得不一致。
> 在实现开始前完整填写此表。空白单元格是设计工作未完成的标志。

**Worked example — entry table**:
**完整示例 — 进入表**：

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [e.g., Player presses Inventory button] | [Gameplay / Exploration state] | [Overlay push — game pauses] | [Current player loadout, inventory contents] | [Works from any non-combat state] |
| [e.g., Item pickup prompt accepted] | [Gameplay / Item Pickup dialog] | [Replace dialog with full inventory] | [Newly acquired item pre-highlighted] | [The new item should be visually distinguished on open] |
| [e.g., Quest system directs player to inventory] | [Gameplay / Quest Update notification] | [Overlay push] | [Quest-relevant item ID for highlight] | [Screen should deep-link to the relevant item] |

| 触发 | 源屏幕 / 状态 | 过渡类型 | 传入数据 | 备注 |
|---------|----------------------|-----------------|----------------|-------|
| [例如，玩家按库存按钮] | [游戏 / 探索状态] | [覆盖推入 — 游戏暂停] | [当前玩家装备、库存内容] | [从任何非战斗状态可用] |
| [例如，物品拾取提示接受] | [游戏 / 物品拾取对话框] | [用完整库存替换对话框] | [新获得的物品预先高亮] | [打开时新物品应视觉上区分] |
| [例如，任务系统引导玩家到库存] | [游戏 / 任务更新通知] | [覆盖推入] | [任务相关物品 ID 用于高亮] | [屏幕应深链接到相关物品] |

**Worked example — exit table**:
**完整示例 — 退出表**：

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| [e.g., Player closes inventory (Back/B/Esc)] | [Previous state — Exploration] | [Overlay pop — game resumes] | [Updated equipment loadout committed] | [Changes must be committed before transition begins] |
| [e.g., Player selects "Equip" on item] | [Same screen, updated state] | [In-place state change] | [Loadout change event fired] | [No navigation, just a state refresh] |
| [e.g., Player navigates to Map from inventory shortcut] | [Map Screen] | [Replace] | [No data] | [Inventory state is preserved if player returns] |

| 退出动作 | 目的地 | 过渡类型 | 返回 / 保存的数据 | 备注 |
|-------------|------------|-----------------|----------------------|-------|
| [例如，玩家关闭库存（Back/B/Esc）] | [前一状态 — 探索] | [覆盖弹出 — 游戏继续] | [已提交更新后的装备配置] | [变更必须在过渡开始前提交] |
| [例如，玩家对物品选择“装备”] | [同一屏幕，更新后的状态] | [原地状态变更] | [触发配装变更事件] | [无导航，仅状态刷新] |
| [例如，玩家从库存快捷方式导航到地图] | [地图屏幕] | [替换] | [无数据] | [若玩家返回，库存状态被保留] |

---

## Section 5 — Layout Specification
## 第 5 节 — 布局规格

> **Why this section exists**: The layout specification is the handoff artifact between
> UX design and UI programming. It does not need to be pixel-perfect — it needs to
> communicate hierarchy (what is important), proximity (what belongs together), and
> proportion (what is big vs. small). ASCII wireframes achieve this without requiring
> design software. A programmer who reads this section should be able to build the
> correct structure without guessing. An artist who reads it should know where
> visual weight should be concentrated.
>
> Draw the layout at one standard resolution (e.g., 1920x1080). Note adaptations
> for other resolutions separately.
> **为何存在此节**：布局规格是 UX 设计与 UI 编程之间的交接产物。它不需要像素级完美 —
> 它需要传达层级（什么重要）、邻近关系（什么属于一起）和比例（什么大、什么小）。
> ASCII 线框图无需设计软件即可实现这一点。阅读此节的程序员应能在不猜测的情况下构建正确的结构。
> 阅读此节的艺术家应知道视觉重量应集中在哪里。
>
> 在一个标准分辨率（例如，1920x1080）下绘制布局。单独注明其他分辨率的适配。

**Worked example — wireframe (5.1)**:
**完整示例 — 线框图（5.1）**：

```
Example:
┌──────────────────────────────────────────────┐
│  [← Back]        INVENTORY         [Options] │  ← HEADER ZONE
├──────────────────────────────────────────────┤
│ ┌──────────────┐  ┌─────────────────────────┐│
│ │ CATEGORY NAV │  │  ITEM DETAIL PANEL      ││  ← CONTENT ZONE
│ │  ● Weapons   │  │  Item Name              ││
│ │    Armor     │  │  {item icon}            ││
│ │    Consumable│  │  Stats comparison       ││
│ │    Key Items │  │  Description text...    ││
│ ├──────────────┤  └─────────────────────────┘│
│ │ ITEM GRID    │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ ...          │                             │
│ └──────────────┘                             │
├──────────────────────────────────────────────┤
│   [Equip]     [Drop]     [Compare]  [Close]  │  ← ACTION BAR
└──────────────────────────────────────────────┘
```

```
示例：
┌──────────────────────────────────────────────┐
│  [← 返回]        库存         [选项] │  ← 头部区域
├──────────────────────────────────────────────┤
│ ┌──────────────┐  ┌─────────────────────────┐│
│ │ 分类导航 │  │  物品详情面板      ││  ← 内容区域
│ │  ● 武器   │  │  物品名称              ││
│ │    护甲     │  │  {物品图标}            ││
│ │    消耗品│  │  属性比较       ││
│ │    关键物品 │  │  描述文本...    ││
│ ├──────────────┤  └─────────────────────────┘│
│ │ 物品网格    │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ {□}{□}{□}{□} │                             │
│ │ ...          │                             │
│ └──────────────┘                             │
├──────────────────────────────────────────────┤
│   [装备]     [丢弃]     [比较]  [关闭]  │  ← 动作栏
└──────────────────────────────────────────────┘
```

**Worked example — layout zones table (5.2)**:
**完整示例 — 布局区域表（5.2）**：

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| [e.g., Header Zone] | [Top bar: navigation, screen title, global actions] | [Full width, ~10% height] | [No] | [Truncate long screen names with ellipsis] |
| [e.g., Category Nav] | [Left panel: item category tabs] | [~25% width, ~75% height] | [Yes — vertical if categories exceed panel] | [Scroll indicator appears at bottom of list] |
| [e.g., Item Grid] | [Center: grid of item icons for selected category] | [~45% width, ~75% height] | [Yes — vertical] | [Page-based: 4x4 grid, next page on overflow] |
| [e.g., Detail Panel] | [Right: stats and description for selected item] | [~30% width, ~75% height] | [Yes — vertical for long descriptions] | [Fade at bottom, scroll to reveal] |
| [e.g., Action Bar] | [Bottom: context-sensitive actions for selected item] | [Full width, ~15% height] | [No] | [Actions collapse to icon-only below 4] |

| 区域名称 | 描述 | 大致尺寸 | 可滚动？ | 溢出行为 |
|-----------|-------------|-----------------|-------------|-------------------|
| [例如，头部区域] | [顶部栏：导航、屏幕标题、全局动作] | [全宽，约 10% 高] | [否] | [用省略号截断过长的屏幕名称] |
| [例如，分类导航] | [左侧面板：物品分类标签] | [约 25% 宽，约 75% 高] | [是 — 分类超出面板时垂直滚动] | [列表底部出现滚动指示] |
| [例如，物品网格] | [中央：所选分类的物品图标网格] | [约 45% 宽，约 75% 高] | [是 — 垂直] | [分页：4x4 网格，溢出时翻到下一页] |
| [例如，详情面板] | [右侧：所选物品的属性与描述] | [约 30% 宽，约 75% 高] | [是 — 长描述时垂直] | [底部淡出，滚动显示] |
| [例如，动作栏] | [底部：所选物品的情境相关动作] | [全宽，约 15% 高] | [否] | [动作少于 4 个时折叠为仅图标] |

**Worked example — component inventory table (5.3)**:
**完整示例 — 组件清单表（5.3）**：

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| [e.g., Back Button] | [Button] | [Header] | [Returns to previous screen] | [Yes] | [Yes — standard NavButton component] |
| [e.g., Screen Title Label] | [Text] | [Header] | [Displays "INVENTORY" or context name] | [Yes] | [Yes — ScreenTitle component] |
| [e.g., Category Tab] | [Toggle Button] | [Category Nav] | [Filters item grid by category] | [Yes] | [No — new component needed] |
| [e.g., Item Slot] | [Icon + Frame] | [Item Grid] | [Represents one inventory slot, empty or filled] | [Yes] | [No — new component] |
| [e.g., Item Name Label] | [Text] | [Detail Panel] | [Shows selected item's name] | [Yes] | [Yes — BodyText component] |
| [e.g., Stat Comparison Row] | [Compound — label + value + delta] | [Detail Panel] | [Shows stat value vs. currently equipped] | [Yes] | [No — new component] |
| [e.g., Equip Button] | [Primary Button] | [Action Bar] | [Equips selected item in appropriate slot] | [Yes] | [Yes — PrimaryAction component] |
| [e.g., Empty State Message] | [Text + Icon] | [Item Grid] | [Shown when category has no items] | [Yes] | [Yes — EmptyState component] |

| 组件名称 | 类型 | 区域 | 用途 | 必需？ | 复用现有组件？ |
|----------------|------|------|---------|-----------|---------------------------|
| [例如，返回按钮] | [按钮] | [头部] | [返回上一屏幕] | [是] | [是 — 标准 NavButton 组件] |
| [例如，屏幕标题标签] | [文本] | [头部] | [显示“库存”或情境名称] | [是] | [是 — ScreenTitle 组件] |
| [例如，分类标签] | [开关按钮] | [分类导航] | [按分类筛选物品网格] | [是] | [否 — 需要新组件] |
| [例如，物品槽] | [图标 + 边框] | [物品网格] | [代表一个库存槽位，空或已填充] | [是] | [否 — 新组件] |
| [例如，物品名称标签] | [文本] | [详情面板] | [显示所选物品名称] | [是] | [是 — BodyText 组件] |
| [例如，属性比较行] | [复合 — 标签 + 数值 + 差值] | [详情面板] | [显示属性值对比当前装备] | [是] | [否 — 新组件] |
| [例如，装备按钮] | [主按钮] | [动作栏] | [将所选物品装备到合适槽位] | [是] | [是 — PrimaryAction 组件] |
| [例如，空状态消息] | [文本 + 图标] | [物品网格] | [分类无物品时显示] | [是] | [是 — EmptyState 组件] |

**Worked example — primary focus element on open**: [e.g., The first item in the Item Grid — or, if deep-linked, the highlighted item. If the grid is empty, focus lands on the first Category Tab.]
**完整示例 — 打开时的主要焦点元素**：[例如，物品网格中的第一个物品 — 或若为深链接，则聚焦高亮物品。若网格为空，焦点落在第一个分类标签上。]

---

## Section 6 — States & Variants
## 第 6 节 — 状态与变体

> **Why this section exists**: A screen is not a single picture — it is a set of
> states, each of which must look correct and behave correctly. Screens that are
> designed only in their "happy path" state ship with broken empty states, invisible
> loading indicators, and crashes when data is missing. Document every state before
> implementation. The states table is also the test matrix for QA.
> **为何存在此节**：屏幕不是单一画面 — 它是一组状态，每个状态都必须外观正确、行为正确。
> 只按“顺利路径”状态设计的屏幕，发布时会带着损坏的空状态、不可见的加载指示，
> 以及数据缺失时的崩溃。实现前记录每个状态。状态表也是 QA 的测试矩阵。

**Worked example table**:
**完整示例表**：

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| [Loading] | [Screen is opening, data not yet available] | [Item Grid shows skeleton/shimmer placeholders; Action Bar buttons disabled] | [No interactions possible except Close] | [Should not be visible >500ms under normal conditions; if it is, investigate data fetch performance] |
| [Empty — no items in category] | [Player switches to a category with zero items] | [Item Grid replaced by EmptyState component: icon + "Nothing here yet."] | [Action Bar shows no item actions; Drop/Equip/Compare all hidden] | [Do not show disabled buttons — remove them. Disabled buttons with no tooltip are confusing.] |
| [Populated — items present] | [Category has at least one item] | [Item Grid fills with item slots; first slot is auto-focused] | [All item actions available for selected item] | [Default and most common state] |
| [Item Selected] | [Player navigates to an item slot] | [Detail Panel populates; selected slot has focus ring; Action Bar updates to item's valid actions] | [Equip/Drop/Compare enabled based on item type] | [Equip is disabled if item is already equipped — show a "Equipped" badge instead] |
| [Confirmation Pending — Drop] | [Player selects Drop action] | [Confirmation dialog overlays the screen] | [All background interactions suspended until dialog resolves] | [Use a modal confirmation, not an inline toggle. Items cannot be recovered after dropping.] |
| [Error — data load failed] | [Inventory data could not be retrieved] | [Item Grid shows error state: icon + "Couldn't load items." + Retry button] | [Only Retry and Close are available] | [Log the error; do not expose technical details to player] |
| [Item Newly Acquired] | [Screen opened from item pickup deep-link] | [Newly acquired item has a visual "New" badge; Detail Panel pre-populated with that item] | [Same as Item Selected but with badge until player navigates away] | [Badge persists until the player manually navigates off that slot once] |

| 状态名称 | 触发 | 视觉上什么变化 | 行为上什么变化 | 备注 |
|------------|---------|----------------------|--------------------------|-------|
| [加载中] | [屏幕正在打开，数据尚不可用] | [物品网格显示骨架/微光占位；动作栏按钮禁用] | [除关闭外无法交互] | [正常情况下不应可见超过 500 毫秒；若超过，调查数据获取性能] |
| [空 — 分类中无物品] | [玩家切换到零物品的分类] | [物品网格被 EmptyState 组件替换：图标 + “这里还没有内容。”] | [动作栏不显示物品动作；丢弃/装备/比较全部隐藏] | [不要显示禁用按钮 — 移除它们。没有工具提示的禁用按钮令人困惑。] |
| [已填充 — 有物品] | [分类至少有一个物品] | [物品网格填满物品槽；第一个槽自动获得焦点] | [所选物品的所有动作均可用] | [默认且最常见的状态] |
| [物品已选中] | [玩家导航到一个物品槽] | [详情面板填充；所选槽有焦点环；动作栏更新为该物品的有效动作] | [根据物品类型启用装备/丢弃/比较] | [若物品已装备则禁用装备 — 改为显示“已装备”徽章] |
| [待确认 — 丢弃] | [玩家选择丢弃动作] | [确认对话框覆盖屏幕] | [所有后台交互暂停，直到对话框解决] | [使用模态确认，而非内联开关。物品丢弃后无法恢复。] |
| [错误 — 数据加载失败] | [无法获取库存数据] | [物品网格显示错误状态：图标 + “无法加载物品。” + 重试按钮] | [仅重试和关闭可用] | [记录错误；不要向玩家暴露技术细节] |
| [物品新获得] | [从物品拾取深链接打开屏幕] | [新获得的物品有视觉“新”徽章；详情面板预填充该物品] | [与物品已选中相同，但徽章保留直到玩家导航离开] | [徽章保留，直到玩家手动导航离开该槽一次] |

---

## Section 7 — Interaction Map
## 第 7 节 — 交互映射

> **Why this section exists**: This section is the source of truth for what every
> input does on this screen. It forces the designer to think through every input
> method (mouse, keyboard, gamepad, touch) and every interactive state (hover, focus,
> pressed, disabled). Gaps in this table are bugs waiting to happen. The
> interaction map is also the input for the accessibility audit — if an action is
> only reachable by mouse, it will fail the keyboard and gamepad columns.
> **为何存在此节**：此节是每个输入在此屏幕上做什么的权威来源。它迫使设计师思考每种输入方式
> （鼠标、键盘、手柄、触摸）和每种交互状态（悬停、聚焦、按下、禁用）。
> 此表的空白就是等待发生的缺陷。交互映射也是无障碍审计的输入 — 若某个动作只能通过鼠标到达，
> 它将在键盘和手柄两列上失败。

**Worked example — navigation inputs (7.1)**:
**完整示例 — 导航输入（7.1）**：

| Input | Platform | Action | Visual Response | Audio Cue | Notes |
|-------|----------|--------|-----------------|-----------|-------|
| [Arrow keys / D-Pad] | [All] | [Move focus within active zone] | [Focus ring moves to adjacent element] | [Soft navigation tick] | [Wrap at edges within zone; do not cross zones with arrows alone] |
| [Tab / R1] | [KB / Gamepad] | [Move focus to next zone (Category → Grid → Detail → Action Bar)] | [Focus ring jumps to first element in next zone] | [Distinct zone-change tone] | [Shift+Tab / L1 goes backward] |
| [Mouse hover] | [PC] | [Show hover state on interactive elements] | [Highlight / underline / color shift] | [None] | [Hover does NOT move focus — only click does] |
| [Mouse click] | [PC] | [Select and focus the clicked element] | [Pressed state flash, then selected/focused] | [Soft click] | [Right-click opens context menu if applicable; otherwise no-op] |
| [Touch tap] | [Mobile] | [Select and activate in one gesture] | [Press ripple] | [Soft click] | [Treat tap as click + confirm for low-risk actions; require explicit confirm for destructive actions] |

| 输入 | 平台 | 动作 | 视觉响应 | 音频提示 | 备注 |
|-------|----------|--------|-----------------|-----------|-------|
| [方向键 / D-Pad] | [全部] | [在活跃区域内移动焦点] | [焦点环移到相邻元素] | [柔和导航滴答声] | [在区域内边缘循环；不要仅用方向键跨区域] |
| [Tab / R1] | [键盘 / 手柄] | [将焦点移到下一区域（分类 → 网格 → 详情 → 动作栏）] | [焦点环跳到下一区域的第一个元素] | [独特的区域切换音] | [Shift+Tab / L1 向后] |
| [鼠标悬停] | [PC] | [在交互元素上显示悬停状态] | [高亮 / 下划线 / 颜色变化] | [无] | [悬停**不会**移动焦点 — 只有点击会] |
| [鼠标点击] | [PC] | [选中并聚焦被点击元素] | [按下状态闪烁，然后选中/聚焦] | [柔和点击声] | [右键如适用则打开上下文菜单；否则无操作] |
| [触摸轻点] | [移动端] | [一次手势中选中并激活] | [按下涟漪] | [柔和点击声] | [低风险动作将轻点视为点击 + 确认；破坏性动作需要显式确认] |

**Worked example — action inputs (7.2)**:
**完整示例 — 动作输入（7.2）**：

| Input | Platform | Context (What must be focused) | Action | Response | Animation | Audio Cue | Notes |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [Enter / A button / Left click] | [All] | [Item slot focused] | [Select item → populate Detail Panel] | [Detail panel slides in or updates in place] | [Panel fade/slide in, 120ms] | [Soft select tone] | [If item already selected: no-op] |
| [Enter / A button] | [All] | [Equip button focused] | [Equip selected item] | [Button animates press; item badge updates to "Equipped"; previously equipped item loses badge] | [Badge swap, 80ms] | [Equip success sound] | [Fires EquipItem event to Inventory system] |
| [Triangle / Y button / Right-click] | [All] | [Item slot focused] | [Open item context menu] | [Context menu appears adjacent to item slot] | [Popover, 80ms] | [Menu open sound] | [Context menu contains: Equip, Drop, Inspect, Compare] |
| [Square / X button] | [Gamepad] | [Item slot focused] | [Quick-equip without opening detail] | [Equip animation plays inline on slot] | [Slot flash, 80ms] | [Equip success sound] | [Convenience shortcut; does not change screen state] |
| [Esc / B button / Back] | [All] | [Any, screen level] | [Close screen and return to previous state] | [Screen exit transition plays] | [Slide out, 200ms] | [Back/close tone] | [Commits all changes before closing. No discard — inventory is not a draft.] |
| [F / L2] | [KB / Gamepad] | [Any] | [Toggle filter panel] | [Sort/filter overlay opens] | [Slide in from right, 200ms] | [Panel open tone] | [If no items in category, filter is disabled] |

| 输入 | 平台 | 情境（必须聚焦什么） | 动作 | 响应 | 动画 | 音频提示 | 备注 |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| [Enter / A 按钮 / 左键点击] | [全部] | [物品槽已聚焦] | [选中物品 → 填充详情面板] | [详情面板滑入或原地更新] | [面板淡入/滑入，120 毫秒] | [柔和选择音] | [若物品已选中：无操作] |
| [Enter / A 按钮] | [全部] | [装备按钮已聚焦] | [装备所选物品] | [按钮动画按下；物品徽章更新为“已装备”；先前装备的物品失去徽章] | [徽章切换，80 毫秒] | [装备成功音效] | [向库存系统触发 EquipItem 事件] |
| [Triangle / Y 按钮 / 右键] | [全部] | [物品槽已聚焦] | [打开物品上下文菜单] | [上下文菜单出现在物品槽旁] | [弹出层，80 毫秒] | [菜单打开音效] | [上下文菜单包含：装备、丢弃、查看、比较] |
| [Square / X 按钮] | [手柄] | [物品槽已聚焦] | [快速装备，不打开详情] | [装备动画在槽位上内联播放] | [槽位闪烁，80 毫秒] | [装备成功音效] | [便捷快捷方式；不改变屏幕状态] |
| [Esc / B 按钮 / 返回] | [全部] | [任意，屏幕级] | [关闭屏幕并返回前一状态] | [播放屏幕退出过渡] | [滑出，200 毫秒] | [返回/关闭音] | [关闭前提交所有变更。没有丢弃 — 库存不是草稿。] |
| [F / L2] | [键盘 / 手柄] | [任意] | [切换筛选面板] | [排序/筛选覆盖层打开] | [从右侧滑入，200 毫秒] | [面板打开音] | [若分类中无物品，筛选被禁用] |

**Worked example — state-specific behaviors (7.3)**:
**完整示例 — 状态专属行为（7.3）**：

| State | Input Restriction | Reason |
|-------|------------------|--------|
| [Loading] | [All item and action inputs disabled] | [No data to act on; prevent race conditions] |
| [Confirmation dialog open] | [Only Confirm and Cancel inputs active] | [Modal — background is locked] |
| [Error state] | [Only Retry and Close active] | [No data available to navigate] |

| 状态 | 输入限制 | 原因 |
|-------|------------------|--------|
| [加载中] | [所有物品和动作输入禁用] | [无可操作数据；防止竞态条件] |
| [确认对话框打开] | [仅确认和取消输入有效] | [模态 — 后台被锁定] |
| [错误状态] | [仅重试和关闭有效] | [无数据可导航] |

---

## Section 8 — Data Requirements
## 第 8 节 — 数据需求

> **Why this section exists**: The separation between UI and game state is the most
> important architectural boundary in a game's UI system. UI reads data; it does not
> own it. UI fires events; it does not write state directly. This section defines
> exactly what data this screen needs to display, where it comes from, and how
> frequently it updates. Filling this table before implementation prevents two
> common failure modes: (1) UI developers reaching into systems they should not touch,
> and (2) systems not knowing they need to expose data until a UI is half-built.
> **为何存在此节**：UI 与游戏状态之间的分离是游戏 UI 系统中最重要的架构边界。UI 读取数据；
> 它不拥有数据。UI 触发事件；它不直接写状态。此节确切定义此屏幕需要显示什么数据、
> 数据来自哪里、更新频率如何。实现前填写此表可防止两种常见失败模式：
> (1) UI 开发者伸入他们不该触碰的系统；(2) 系统直到 UI 建了一半才知道它们需要暴露数据。

**Worked example table**:
**完整示例表**：

| Data Element | Source System | Update Frequency | Who Owns It | Format | Null / Missing Handling |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [e.g., Item list] | [Inventory System] | [On screen open; on InventoryChanged event] | [InventorySystem] | [Array of ItemData structs: id, name, icon_path, category, stats, is_equipped] | [Empty array → show Empty State. Never null — system must return array.] |
| [e.g., Equipped loadout] | [Equipment System] | [On screen open; on EquipmentChanged event] | [EquipmentSystem] | [Dict mapping slot_id → item_id] | [Unequipped slot has null value — UI shows empty slot icon] |
| [e.g., Item stat comparisons] | [Stats System] | [On item selection change] | [StatsSystem] | [Dict mapping stat_name → {current, new, delta}] | [If no item selected, detail panel shows placeholder. Stats system must handle this gracefully.] |
| [e.g., Player currency] | [Economy System] | [On screen open only — inventory does not show live currency] | [EconomySystem] | [Int — gold pieces] | [If currency system not active for this game mode, hide the currency row entirely] |
| [e.g., Newly acquired item flag] | [Inventory System] | [On screen open] | [InventorySystem] | [Array of item_ids flagged as new] | [If empty array, no badges shown] |

| 数据元素 | 来源系统 | 更新频率 | 谁拥有它 | 格式 | 空 / 缺失处理 |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| [例如，物品列表] | [库存系统] | [屏幕打开时；InventoryChanged 事件时] | [InventorySystem] | [ItemData 结构体数组：id、name、icon_path、category、stats、is_equipped] | [空数组 → 显示空状态。绝不为 null — 系统必须返回数组。] |
| [例如，已装备配置] | [装备系统] | [屏幕打开时；EquipmentChanged 事件时] | [EquipmentSystem] | [映射 slot_id → item_id 的字典] | [未装备槽的值为 null — UI 显示空槽图标] |
| [例如，物品属性比较] | [属性系统] | [物品选择变化时] | [StatsSystem] | [映射 stat_name → {current, new, delta} 的字典] | [若无选中物品，详情面板显示占位符。属性系统必须优雅处理此情况。] |
| [例如，玩家货币] | [经济系统] | [仅屏幕打开时 — 库存不显示实时货币] | [EconomySystem] | [整数 — 金币] | [若此游戏模式未启用货币系统，完全隐藏货币行] |
| [例如，新获得物品标记] | [库存系统] | [屏幕打开时] | [InventorySystem] | [标记为新物品的 item_ids 数组] | [若数组为空，不显示徽章] |

---

## Section 9 — Events Fired
## 第 9 节 — 触发的事件

> **Why this section exists**: This is the other half of the UI/system boundary.
> Where Section 8 defines what the UI reads, this section defines what the UI
> communicates back to the game. Specifying events at design time prevents UI
> programmers from writing game logic, and prevents game programmers from being
> surprised by what the UI does. Every destructive or state-changing player action
> must appear in this table.
> **为何存在此节**：这是 UI/系统边界的另一半。第 8 节定义 UI 读取什么，此节定义 UI 传回游戏什么。
> 在设计阶段规定事件可防止 UI 程序员编写游戏逻辑，也防止游戏程序员被 UI 的行为惊吓。
> 每个破坏性或改变状态的玩家动作都必须出现在此表中。

**Worked example table**:
**完整示例表**：

| Player Action | Event Fired | Payload | Receiver System | Notes |
|---------------|-------------|---------|-----------------|-------|
| [Player equips an item] | [EquipItemRequested] | [{item_id: string, target_slot: string}] | [Equipment System] | [Equipment System validates the action and fires EquipmentChanged if successful; UI listens for EquipmentChanged to update its display] |
| [Player drops an item] | [DropItemRequested] | [{item_id: string, quantity: int}] | [Inventory System] | [Fires only after player confirms the drop dialog. Inventory System removes the item and fires InventoryChanged.] |
| [Player opens item compare] | [ItemCompareOpened] | [{item_a_id: string, item_b_id: string}] | [Analytics System] | [No game-state change — analytics event only. Compare view is purely local UI state.] |
| [Player closes screen] | [InventoryScreenClosed] | [{session_duration_ms: int}] | [Analytics System] | [Fires on every close regardless of reason. Used for engagement metrics.] |
| [Player navigates between categories] | [InventoryCategoryChanged] | [{category: string}] | [Analytics System] | [Analytics only. No game state change.] |

| 玩家动作 | 触发的事件 | 载荷 | 接收系统 | 备注 |
|---------------|-------------|---------|-----------------|-------|
| [玩家装备物品] | [EquipItemRequested] | [{item_id: string, target_slot: string}] | [装备系统] | [装备系统校验该动作，成功则触发 EquipmentChanged；UI 监听 EquipmentChanged 以更新显示] |
| [玩家丢弃物品] | [DropItemRequested] | [{item_id: string, quantity: int}] | [库存系统] | [仅在玩家确认丢弃对话框后触发。库存系统移除物品并触发 InventoryChanged。] |
| [玩家打开物品比较] | [ItemCompareOpened] | [{item_a_id: string, item_b_id: string}] | [分析系统] | [无游戏状态变更 — 仅分析事件。比较视图纯属本地 UI 状态。] |
| [玩家关闭屏幕] | [InventoryScreenClosed] | [{session_duration_ms: int}] | [分析系统] | [每次关闭时触发，无论原因。用于参与度指标。] |
| [玩家在分类间导航] | [InventoryCategoryChanged] | [{category: string}] | [分析系统] | [仅分析。无游戏状态变更。] |

---

## Section 10 — Transitions & Animations
## 第 10 节 — 过渡与动画

> **Why this section exists**: Transitions are not decoration — they communicate
> hierarchy and causality. A screen that slides in from the right implies the
> player has moved forward. A screen that fades implies a context break. Inconsistent
> transitions make navigation feel broken even when it is technically correct.
> This section ensures transitions are specified intentionally, not left to the
> developer's discretion, and that accessibility settings (reduced motion) are
> planned for from the start.
> **为何存在此节**：过渡不是装饰 — 它们传达层级与因果。从右侧滑入的屏幕暗示玩家向前移动。
> 淡入淡出的屏幕暗示情境断裂。不一致的过渡会让导航感觉损坏，即使技术上正确。
> 此节确保过渡被有意识地规定，而非留给开发者自行决定，并确保无障碍设置（减少动态效果）
> 从一开始就被规划。

**Worked example table**:
**完整示例表**：

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [Screen enter] | [Screen pushed onto stack] | [Slide in from right] | [250] | [Ease out cubic] | [No — must complete before interaction is enabled] | [Yes — instant appear at 0ms] |
| [Screen exit — Back] | [Player presses Back] | [Slide out to right] | [200] | [Ease in cubic] | [No] | [Yes — instant disappear] |
| [Screen exit — Forward] | [Player navigates to child screen] | [Slide out to left] | [200] | [Ease in cubic] | [No] | [Yes — instant] |
| [Detail panel update] | [Player selects a new item] | [Cross-fade content] | [120] | [Linear] | [Yes — if player navigates quickly, previous animation cancels] | [Yes — instant swap] |
| [Loading → Populated] | [Data arrives after load] | [Skeleton shimmer fades out, content fades in] | [180] | [Ease out] | [No] | [Yes — instant reveal] |
| [Action Bar button press] | [Player activates a button] | [Scale down 95% on press, return on release] | [60 down / 60 up] | [Ease out / ease in] | [Yes — if released early, returns to normal] | [No — this is tactile feedback, not decorative motion] |
| [Confirmation dialog open] | [Player initiates destructive action] | [Background dims 60% opacity; dialog scales up from 95%] | [150] | [Ease out] | [No] | [Yes — instant appear, no scale] |
| [New item badge appear] | [Screen opens with newly acquired item] | [Badge pops from 0% to 110% to 100% scale] | [200 total] | [Ease out back] | [No] | [Yes — instant appear at 100% scale] |

| 过渡 | 触发 | 方向 / 类型 | 持续时间（毫秒） | 缓动 | 可中断？ | 被减少动态效果跳过？ |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| [屏幕进入] | [屏幕推入栈] | [从右侧滑入] | [250] | [缓出三次方] | [否 — 必须在交互启用前完成] | [是 — 0 毫秒即时出现] |
| [屏幕退出 — 返回] | [玩家按返回] | [向右滑出] | [200] | [缓入三次方] | [否] | [是 — 即时消失] |
| [屏幕退出 — 前进] | [玩家导航到子屏幕] | [向左滑出] | [200] | [缓入三次方] | [否] | [是 — 即时] |
| [详情面板更新] | [玩家选择新物品] | [内容交叉淡化] | [120] | [线性] | [是 — 若玩家快速导航，前一个动画取消] | [是 — 即时切换] |
| [加载 → 已填充] | [加载后数据到达] | [骨架微光淡出，内容淡入] | [180] | [缓出] | [否] | [是 — 即时显示] |
| [动作栏按钮按下] | [玩家激活按钮] | [按下时缩放至 95%，释放时恢复] | [按下 60 / 弹起 60] | [缓出 / 缓入] | [是 — 若提前释放，恢复正常] | [否 — 这是触觉反馈，而非装饰性运动] |
| [确认对话框打开] | [玩家发起破坏性动作] | [背景变暗至 60% 不透明度；对话框从 95% 放大] | [150] | [缓出] | [否] | [是 — 即时出现，无缩放] |
| [新物品徽章出现] | [屏幕随新获得物品打开] | [徽章从 0% 弹到 110% 再到 100% 缩放] | [共 200] | [缓出回弹] | [否] | [是 — 以 100% 缩放即时出现] |

---

## Section 11 — Input Method Completeness Checklist
## 第 11 节 — 输入方式完整性争夺清单

> **Why this section exists**: Input completeness is not optional — it is a
> certification requirement for console platforms and a legal risk area for
> accessibility laws in multiple markets. Fill this checklist before marking
> the spec as Approved. Any unchecked item blocks implementation start.
> **为何存在此节**：输入完整性不是可选项 — 它是主机平台的认证要求，也是多个市场无障碍法律的
> 法律风险领域。在将规格标记为已批准前填写此争夺清单。任何未勾选项都会阻塞实现开始。

---

## Section 12 — Accessibility
## 第 12 节 — 无障碍

> **Why this section exists**: Accessibility requirements must be specified at design
> time because retrofitting them is expensive and often architecturally impractical.
> This section documents requirements specific to this screen. Project-wide standards
> live in `design/accessibility-requirements.md` — consult it before filling this
> section so you do not duplicate or contradict project-level commitments.
> **为何存在此节**：无障碍需求必须在设计阶段规定，因为事后补做代价高昂且往往在架构上不切实际。
> 此节记录此屏幕专属的需求。项目级标准位于 `design/accessibility-requirements.md` —
> 填写此节前查阅它，以免重复或违背项目级承诺。

**Worked example — text contrast table**:
**完整示例 — 文本对比度表**：

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|---------------|---------------|-------|
| [e.g., Item name in Detail Panel] | [Dark panel background ~#1a1a1a] | [4.5:1 (WCAG AA normal text)] | [TBD — verify in implementation] | [ ] |
| [e.g., Category tab label — inactive] | [Mid-grey tab background] | [4.5:1] | [TBD] | [ ] |
| [e.g., Category tab label — active] | [Accent color background] | [4.5:1] | [TBD] | [ ] |
| [e.g., Action button label] | [Button color (varies by state)] | [4.5:1] | [TBD] | [ ] |
| [e.g., Stat comparison delta (positive)] | [Detail panel] | [4.5:1 — do NOT rely on green color alone] | [TBD] | [ ] |

| 文本元素 | 背景情境 | 所需比率 | 当前比率 | 通过？ |
|--------------|-------------------|---------------|---------------|-------|
| [例如，详情面板中的物品名称] | [深色面板背景约 #1a1a1a] | [4.5:1（WCAG AA 正文）] | [待定 — 实现时验证] | [ ] |
| [例如，分类标签 — 非活跃] | [中灰标签背景] | [4.5:1] | [待定] | [ ] |
| [例如，分类标签 — 活跃] | [强调色背景] | [4.5:1] | [待定] | [ ] |
| [例如，动作按钮标签] | [按钮颜色（随状态变化）] | [4.5:1] | [待定] | [ ] |
| [例如，属性比较差值（正向）] | [详情面板] | [4.5:1 — 不要仅依赖绿色] | [待定] | [ ] |

**Worked example — colorblind mitigations table**:
**完整示例 — 色盲缓解表**：

| Element | Colorblind Risk | Mitigation |
|---------|----------------|------------|
| [e.g., Stat delta indicators (red/green for worse/better)] | [Red-green colorblindness (Deuteranopia) — most common form] | [Add arrow icons (↑ / ↓) and +/- prefix in addition to color. Color is a redundant, not sole, indicator.] |
| [e.g., Item rarity color coding (grey/green/blue/purple/orange)] | [Multiple types — rarity color is a common industry failure] | [Add rarity name text label below icon. Color is supplemental only.] |

| 元素 | 色盲风险 | 缓解措施 |
|---------|----------------|------------|
| [例如，属性差值指示（红色/绿色表示更差/更好）] | [红绿色盲（绿色弱）— 最常见的形式] | [除颜色外添加箭头图标（↑ / ↓）和 +/- 前缀。颜色是冗余指示，而非唯一指示。] |
| [例如，物品稀有度颜色编码（灰/绿/蓝/紫/橙）] | [多种类型 — 稀有度颜色是常见的行业失败] | [在图标下方添加稀有度名称文本标签。颜色仅为补充。] |

**Worked example — focus order**:
**完整示例 — 焦点顺序**：

[e.g.,
1. Back button (Header)
2. Options button (Header)
3. Category Tab 1 — Weapons
4. Category Tab 2 — Armor
5. Category Tab 3 — Consumables
6. Category Tab 4 — Key Items
7. Item Slot [0,0]
8. Item Slot [0,1] ... (grid traverses left-to-right, top-to-bottom)
9. Last item slot
10. Equip button (Action Bar)
11. Drop button (Action Bar)
12. Compare button (Action Bar)
13. Close button (Action Bar)
→ Cycles back to Back button

Focus does not enter the Detail Panel — it is a display panel driven by item focus, not independently navigable.]
[例如，
1. 返回按钮（头部）
2. 选项按钮（头部）
3. 分类标签 1 — 武器
4. 分类标签 2 — 护甲
5. 分类标签 3 — 消耗品
6. 分类标签 4 — 关键物品
7. 物品槽 [0,0]
8. 物品槽 [0,1] ...（网格从左到右、从上到下遍历）
9. 最后一个物品槽
10. 装备按钮（动作栏）
11. 丢弃按钮（动作栏）
12. 比较按钮（动作栏）
13. 关闭按钮（动作栏）
→ 循环回到返回按钮

焦点不进入详情面板 — 它是由物品焦点驱动的显示面板，不可独立导航。]

**Worked example — screen reader announcements table**:
**完整示例 — 屏幕阅读器播报表**：

| State Change | Announcement Text | Announcement Timing |
|--------------|------------------|---------------------|
| [Screen opens] | ["Inventory screen. [N] items. [Active category] selected."] | [On screen focus settle] |
| [Player focuses an item slot] | ["[Item name]. [Category]. [Rarity]. [Key stats summary]. [Equipped / Not equipped]."] | [On focus arrival] |
| [Player equips an item] | ["[Item name] equipped to [slot name]."] | [After EquipmentChanged event confirmed] |
| [Player drops an item] | ["[Item name] dropped."] | [After InventoryChanged event confirmed] |
| [Category changes] | ["[Category name]. [N] items."] | [On category tab focus] |
| [Empty state shown] | ["No items in [category name]."] | [When empty state renders] |

| 状态变化 | 播报文本 | 播报时机 |
|--------------|------------------|---------------------|
| [屏幕打开] | [“库存屏幕。[N] 个物品。已选中 [活跃分类]。”] | [屏幕焦点稳定时] |
| [玩家聚焦物品槽] | [“[物品名称]。[分类]。[稀有度]。[关键属性摘要]。[已装备 / 未装备]。”] | [焦点到达时] |
| [玩家装备物品] | [“[物品名称] 已装备到 [槽位名称]。”] | [EquipmentChanged 事件确认后] |
| [玩家丢弃物品] | [“[物品名称] 已丢弃。”] | [InventoryChanged 事件确认后] |
| [分类变化] | [“[分类名称]。[N] 个物品。”] | [分类标签聚焦时] |
| [显示空状态] | [“[分类名称] 中没有物品。”] | [空状态渲染时] |

**Authoring the cognitive load assessment**:
**编写认知负载评估**：

[Estimate the number of information streams the player is simultaneously tracking while
using this screen. For this screen: (1) item grid position, (2) item detail stats,
(3) current equipment loadout for comparison, (4) available actions, (5) item category.
That is 5 concurrent streams — within the standard 7±2 limit, but at the higher end.
Mitigation: detail panel auto-updates on navigation so the player never needs to
manually retrieve item info. Reduce active decisions by surfacing stat comparison
automatically.]
[估算玩家使用此屏幕时同时跟踪的信息流数量。对此屏幕：(1) 物品网格位置，(2) 物品详情属性，
(3) 用于比较的当前装备配置，(4) 可用动作，(5) 物品分类。
即 5 个并发流 — 在标准 7±2 限制之内，但处于较高端。
缓解：详情面板在导航时自动更新，使玩家永远不需要手动获取物品信息。
通过自动呈现属性比较来减少主动决策。]

---

## Section 13 — Localization Considerations
## 第 13 节 — 本地化考量

> **Why this section exists**: UI built without localization in mind breaks on first
> translation. German text is typically 30–40% longer than English. Arabic and Hebrew
> require right-to-left layout mirroring. Japanese and Chinese text may be significantly
> shorter than English, creating awkward whitespace. These issues are cheap to plan for
> and expensive to fix after a layout is built and shipped. Every text element should
> have an explicit max-character count and a plan for overflow.
> **为何存在此节**：未考虑本地化而构建的 UI 在首次翻译时就会损坏。德语文本通常比英语长 30–40%。
> 阿拉伯语和希伯来语需要从右到左的布局镜像。日语和中文文本可能显著短于英语，造成尴尬的空白。
> 这些问题规划成本低，而在布局构建并发布后修复成本高昂。每个文本元素都应有明确的
> 最大字符数以及溢出处理计划。

**Worked example table**:
**完整示例表**：

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behavior | Overflow Behavior | Risk |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [e.g., Screen title "INVENTORY"] | [9 chars] | [16 chars] | [78%] | [Mirror to right, or center — acceptable] | [Truncate with ellipsis — title is not critical content] | [Low] |
| [e.g., Item name] | [~15 chars avg, max ~35 "Enchanted Dragon Scale Gauntlets"] | [50 chars] | [43%] | [Right-align in RTL layouts] | [Truncate with tooltip showing full name on hover/focus] | [Medium — long fantasy item names are common] |
| [e.g., Item description] | [~80–120 chars] | [200 chars] | [67%] | [Right-align, wrap normally] | [Scroll within Detail Panel — no truncation] | [Low — panel is scrollable] |
| [e.g., Action button "Equip"] | [5 chars] | [14 chars] | [180%] | [Button layout mirrors; text right-aligns] | [Shrink font to 90% minimum, then truncate] | [Medium — "Ausrüsten" in German is 9 chars] |
| [e.g., Category tab "Consumables"] | [11 chars] | [18 chars] | [64%] | [Mirror tab position] | [Abbreviate: "Consum." — define abbreviations per language in loc file] | [High — long localized tab labels are a known problem] |

| 文本元素 | 英语基线长度 | 最大字符数 | 扩展预算 | RTL 行为 | 溢出行为 | 风险 |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| [例如，屏幕标题“INVENTORY”] | [9 字符] | [16 字符] | [78%] | [镜像到右侧，或居中 — 可接受] | [用省略号截断 — 标题不是关键内容] | [低] |
| [例如，物品名称] | [平均约 15 字符，最大约 35 “Enchanted Dragon Scale Gauntlets”] | [50 字符] | [43%] | [RTL 布局中右对齐] | [截断，并在悬停/聚焦时用工具提示显示全名] | [中 — 长奇幻物品名很常见] |
| [例如，物品描述] | [约 80–120 字符] | [200 字符] | [67%] | [右对齐，正常换行] | [在详情面板内滚动 — 不截断] | [低 — 面板可滚动] |
| [例如，动作按钮“Equip”] | [5 字符] | [14 字符] | [180%] | [按钮布局镜像；文本右对齐] | [字体缩小至最低 90%，然后截断] | [中 — 德语“Ausrüsten”为 9 字符] |
| [例如，分类标签“Consumables”] | [11 字符] | [18 字符] | [64%] | [镜像标签位置] | [缩写：“Consum.” — 在本地化文件中按语言定义缩写] | [高 — 较长的本地化标签是已知问题] |

---

## Section 14 — Acceptance Criteria
## 第 14 节 — 验收标准

> **Why this section exists**: Acceptance criteria are the contractual definition of
> "done." Without them, implementation is complete when the developer says it is.
> With them, implementation is complete when a QA tester can verify every item on
> this list. Write criteria that a tester can verify independently, without asking the
> designer what they meant. Every criterion should be binary — pass or fail, not
> subjective.
> **为何存在此节**：验收标准是“完成”的契约式定义。没有它们，开发者说完成就是完成。
> 有了它们，当 QA 测试者能验证此列表的每一项时才算完成。编写测试者可独立验证、
> 无需询问设计师意图的标准。每条标准都应是二元的 — 通过或失败，而非主观。

**Worked example criteria (inventory screen)** — note how each is screen-specific
and independently verifiable:
**完整示例标准（库存屏幕）** — 注意每条如何针对具体屏幕且可独立验证：

- [ ] Navigation between items produces no perceptible frame drop (maintain target framerate ±5fps)
- [ ] All states (Loading, Empty, Populated, Error, Confirmation) render correctly
- [ ] Item grid scrolls smoothly without frame drops when all item slots are populated
- [ ] Inventory changes persist correctly after screen is closed and reopened
- [ ] Screen handles InventoryChanged events fired by other systems while it is open without crashing
- [ ] Stat comparison does not rely on color alone as the sole differentiator
- [ ] Screen reader announces item name and key stats on focus (verify with platform screen reader)
- [ ] 物品间导航不产生可感知的掉帧（保持目标帧率 ±5fps）
- [ ] 所有状态（加载、空、已填充、错误、确认）正确渲染
- [ ] 所有物品槽填充时，物品网格平滑滚动且不掉帧
- [ ] 屏幕关闭并重新打开后，库存变更正确保持
- [ ] 屏幕打开期间能处理其他系统触发的 InventoryChanged 事件且不崩溃
- [ ] 属性比较不依赖颜色作为唯一区分手段
- [ ] 屏幕阅读器在聚焦时播报物品名称与关键属性（用平台屏幕阅读器验证）

---

## Section 15 — Open Questions
## 第 15 节 — 待决问题

**Worked example questions**:
**完整示例问题**：

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [e.g., Should item comparison be automatic (always showing equipped stats) or player-triggered (press Compare)?] | [ux-designer] | [Sprint 4, Day 3] | [Pending] |
| [e.g., Do we support controller cursor (free aim) in the item grid, or d-pad-only grid navigation?] | [lead-programmer + ux-designer] | [Sprint 4, Day 3] | [Pending — depends on ADR-0015 input model decision] |
| [e.g., What is the game's item drop policy — permanent loss or drop-to-world?] | [systems-designer] | [Requires GDD update] | [Blocked on inventory GDD Edge Cases section] |
| [e.g., Maximum inventory size — does the grid have a hard cap or is it infinite-scroll?] | [economy-designer] | [Sprint 3, Day 5] | [Pending] |

| 问题 | 负责人 | 截止日期 | 解决方式 |
|----------|-------|----------|-----------|
| [例如，物品比较应自动进行（始终显示已装备属性）还是由玩家触发（按比较）？] | [ux-designer] | [冲刺 4，第 3 天] | [待定] |
| [例如，我们是否在物品网格中支持手柄光标（自由瞄准），还是仅方向键网格导航？] | [lead-programmer + ux-designer] | [冲刺 4，第 3 天] | [待定 — 取决于 ADR-0015 输入模型决策] |
| [例如，游戏的物品丢弃策略是什么 — 永久丢失还是掉落到世界？] | [systems-designer] | [需要更新 GDD] | [阻塞于库存 GDD 边界情况章节] |
| [例如，最大库存尺寸 — 网格有硬上限还是无限滚动？] | [economy-designer] | [冲刺 3，第 5 天] | [待定] |
