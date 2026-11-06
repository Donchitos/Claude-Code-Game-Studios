> Authoring guidance for accessibility-requirements.md. Load only the part covering the section currently being authored — not the whole file at once.
> accessibility-requirements.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

# Accessibility Requirements Template — Authoring Guidance
# 无障碍需求模板 — 编写指南

Guidance is organized by template section. When authoring a section of a
project's accessibility requirements document, read only that section's
guidance below. The feature tables themselves (Visual / Motor / Cognitive /
Auditory), the platform API table, the test plan, and the external resources
remain in the template — they are the requirement catalog, not guidance.
指南按模板章节组织。编写项目无障碍需求文档的某章节时，只阅读下面该章节的指南。
功能表本身（视觉 / 运动 / 认知 / 听觉）、平台 API 表、测试计划和外部资源仍保留在模板中 —
它们是需求目录，而非指南。

---

## Accessibility Tier Definition
## 无障碍层级定义

> **Why define tiers**: Accessibility is not binary. Defining four tiers gives
> the team a shared vocabulary, forces an explicit commitment at the start of
> production, and prevents scope creep in both directions ("we'll add it later"
> and "we have to support everything"). The tiers below are this project's
> definitions — the industry uses similar but not identical language. Commit to
> a tier with specific feature targets, not just the tier name.
> **为何定义层级**：无障碍不是二元的。定义四个层级为团队提供共享词汇，迫使在制作初期做出明确承诺，
> 并防止两个方向上的范围蔓延（“我们以后再加”和“我们得支持一切”）。
> 以下层级是本项目的定义 — 行业使用的措辞类似但不完全相同。承诺某个层级时要带有具体功能目标，
> 而不是只承诺层级名称。

**Authoring the commitment rationale**:
**编写承诺理由**：

[Write 3-5 sentences justifying the tier choice. Do not simply
state the tier — explain the reasoning. Consider: What is the game's genre and
how does it map to common accessibility barriers (e.g., fast-twitch games have
motor barriers; reading-heavy games have visual barriers)? Who is the target
player and what does the research say about disability prevalence in that group?
What are the platform requirements (Xbox requires XAG compliance for ID@Xbox)?
What is the team's capacity? What would dropping one tier cost the player base,
in concrete terms?

Example: "This is a narrative RPG with turn-based combat targeted at players
25-45. The turn-based structure eliminates the most severe motor barriers common
in action games, but the reading-heavy design creates significant visual and
cognitive barriers. Standard tier addresses all of these. Exemplary tier is not
achievable without a dedicated accessibility engineer. Xbox ID@Xbox program
requires XAG compliance for Game Pass consideration, which Standard meets.
Dropping to Basic would exclude players who rely on colorblind modes or input
remapping, estimated at 8-12% of the target audience based on AbleGamers data."]
[写 3-5 句话论证层级选择。不要仅仅陈述层级 — 要解释理由。考虑：游戏类型是什么，
它如何映射到常见的无障碍障碍（例如，快节奏游戏有运动障碍；文字量大的游戏有视觉障碍）？
目标玩家是谁，研究对目标群体中残障流行率是怎么说的？
平台要求是什么（Xbox 的 ID@Xbox 要求 XAG 合规）？团队能力如何？
降低一个层级会以具体代价损失多少玩家群体？

示例：“这是一款回合制战斗的叙事 RPG，目标玩家为 25-45 岁。回合制结构消除了动作游戏中最严重的运动障碍，
但文字量大的设计造成显著的视觉与认知障碍。标准层级可解决所有这些。示范层级若无专职无障碍工程师
则无法实现。Xbox ID@Xbox 计划要求 XAG 合规以获得 Game Pass 考虑，标准层级满足该要求。
降至基础层级将排除依赖色盲模式或输入重映射的玩家，根据 AbleGamers 数据估计占目标受众的 8-12%。”]

**Example in-scope / out-of-scope entries**:
**范围内的示例 / 范围外的示例条目**：

Features explicitly in scope (beyond tier baseline):
- [e.g., "Full subtitle customization — elevated from Comprehensive because our
  game is dialogue-heavy and subtitles are a primary channel"]
- [e.g., "One-hand mode for controller — we have hold inputs critical to combat"]
明确纳入范围的功能（超出层级基线）：
- [例如，“完整字幕自定义 — 从全面层级提升，因为我们的游戏对话密集，字幕是主要渠道”]
- [例如，“手柄单手模式 — 我们有对战斗至关重要的长按输入”]

Features explicitly out of scope:
- [e.g., "Screen reader for in-game world (not menus) — requires engine work
  beyond current capacity. Documented in Known Intentional Limitations."]
明确排除范围的功能：
- [例如，“游戏世界（非菜单）的屏幕阅读器 — 需要超出当前能力的引擎工作。
  记录在已知有意限制中。”]

---

## Visual Accessibility
## 视觉无障碍

> **Why this section comes first**: Visual impairments affect the largest
> proportion of players who use accessibility features. Color vision deficiency
> alone affects approximately 8% of men and 0.5% of women. Text legibility at
> TV viewing distance is frequently the single largest accessibility failure
> in shipped games. Document every visual feature before implementation begins,
> because retrofitting minimum text sizes or color decisions after assets are
> locked is expensive.
> **为何此章节排在最前**：视觉障碍影响使用无障碍功能的最大比例玩家。仅色觉缺陷就影响约 8% 的男性和
> 0.5% 的女性。电视观看距离下的文字可读性常常是已发行游戏中最大的单一无障碍失败点。
> 在实现开始前记录每个视觉功能，因为在资产锁定后补做最小字号或颜色决策代价高昂。

**Worked example rows — Color-as-Only-Indicator Audit**:
**完整示例行 — 仅靠颜色指示审计**：

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| [Health bar] | [Red = low health] | [Player is near death] | [Bar also shows numeric value and flashes] | [Not Started] |
| [Minimap markers] | [Red = enemy, green = ally] | [Unit allegiance] | [Enemy markers are triangles; ally markers are circles] | [Not Started] |
| [Inventory item rarity] | [Color-coded border (grey/blue/purple/gold)] | [Item quality tier] | [Rarity name shown on hover/focus; icon star count] | [Not Started] |

| 位置 | 颜色信号 | 它传达什么 | 非颜色备选 | 状态 |
|----------|-------------|---------------------|-----------------|--------|
| [血条] | [红色 = 低生命] | [玩家濒临死亡] | [条形同时显示数值并闪烁] | [未开始] |
| [小地图标记] | [红色 = 敌人，绿色 = 盟友] | [单位阵营] | [敌人标记为三角形；盟友标记为圆形] | [未开始] |
| [库存物品稀有度] | [颜色编码边框（灰/蓝/紫/金）] | [物品品质层级] | [悬停/聚焦时显示稀有度名称；图标星数] | [未开始] |

---

## Motor Accessibility
## 运动无障碍

> **Why motor accessibility matters for games**: Games are more motor-demanding
> than most software. A web form requires precise clicks; a game may require
> rapid simultaneous button combinations held for specific durations. Motor
> impairments span a wide range — from tremor (affecting precision) to
> hemiplegia (one functional hand) to RSI (affecting hold duration). The AbleGamers
> Able Assistance program estimates 35 million gamers in the US have a disability
> affecting their ability to play. Many of the features below cost very little
> to implement if planned from the start, and are extremely expensive to add post-launch.
> **为何运动无障碍对游戏重要**：游戏比大多数软件对运动能力要求更高。网页表单需要精确点击；
> 游戏可能需要快速同时按组合键并保持特定时长。运动障碍涵盖很广 — 从震颤（影响精确度）到
> 偏瘫（一只手有功能）到 RSI（影响保持时长）。AbleGamers 的 Able Assistance 项目估计
> 美国有 3500 万玩家存在影响其游玩能力的残障。下面许多功能若从一开始就规划，实现成本很低，
> 而发布后再添加则极其昂贵。

---

## Cognitive Accessibility
## 认知无障碍

> **Why cognitive accessibility is often under-specced**: Cognitive accessibility
> affects players with ADHD, dyslexia, autism spectrum conditions, acquired brain
> injuries, and anxiety disorders — a larger combined population than many studios
> realize. It also benefits all players in high-stress moments. The most common
> failures are: no pause anywhere, tutorial information that can only be seen once,
> and systems that require tracking too many simultaneous states. Games like
> Hades and Celeste have demonstrated that cognitive assist options (god mode,
> persistent reminders, extended text display) do not harm the experience for
> players who don't use them.
> **为何认知无障碍常常规格不足**：认知无障碍影响患有 ADHD、阅读障碍、自闭症谱系状况、获得性脑损伤
> 和焦虑障碍的玩家 — 合计人数比许多工作室意识到的更多。它也在高压时刻让所有玩家受益。
> 最常见的失败是：任何地方都无法暂停、教程信息只能看一次，以及要求同时跟踪过多状态的系统。
> Hades 和 Celeste 等游戏已经证明，认知辅助选项（上帝模式、持续提醒、延长文字显示）
> 不会损害不使用它们的玩家的体验。

---

## Auditory Accessibility
## 听觉无障碍

> **Why auditory accessibility matters even for players without hearing loss**:
> 7% of players are deaf or hard of hearing. Additionally, a large portion of
> players regularly play in environments where audio is reduced or absent (commute,
> shared household, infant sleeping). Any gameplay-critical information delivered
> only through audio is a design failure even before accessibility is considered.
> The guiding principle: every sound that changes what the player should DO next
> must have a visual equivalent.
> **为何听觉无障碍即使对无听力损失的玩家也重要**：7% 的玩家失聪或听力困难。此外，很大一部分玩家
> 经常在音频减弱或缺失的环境中游玩（通勤、合住家庭、婴儿睡觉）。任何仅通过音频传达的关键玩法信息，
> 甚至在考虑无障碍之前就已经是设计失败。指导原则：每个会改变玩家下一步应**做什么**的声音
> 都必须有视觉等效物。

**Worked example rows — Gameplay-Critical SFX Audit**:
**完整示例行 — 关键玩法音效审计**：

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| [Enemy attack windup sound] | [Incoming damage — player should dodge] | [Enemy animation telegraph visible from all camera angles] | [No — visual is sufficient] | [Not Started] |
| [Trap trigger click] | [Trap is about to fire] | [Not always visible depending on camera angle] | [Yes — "[CLICK]" caption with directional indicator] | [Not Started] |
| [Low health heartbeat] | [Player health critical] | [Health bar also shows critical state visually] | [No — visual is sufficient] | [Not Started] |
| [Quest completion chime] | [Objective completed] | [Quest tracker updates visually] | [No — visual is sufficient] | [Not Started] |

| 音效 | 它传达什么 | 视觉备选 | 需要字幕？ | 状态 |
|-------------|---------------------|--------------|-----------------|--------|
| [敌人攻击预备音] | [即将受到伤害 — 玩家应闪避] | [敌人动画预告在所有相机角度下可见] | [否 — 视觉已足够] | [未开始] |
| [陷阱触发咔嗒声] | [陷阱即将发射] | [取决于相机角度，并非始终可见] | [是 — 带方向指示的“[咔嗒]”字幕] | [未开始] |
| [低生命心跳声] | [玩家生命危急] | [血条同时以视觉显示危急状态] | [否 — 视觉已足够] | [未开始] |
| [任务完成提示音] | [目标已完成] | [任务追踪器以视觉更新] | [否 — 视觉已足够] | [未开始] |

---

## Platform Accessibility API Integration
## 平台无障碍 API 集成

> **Why this section exists**: Each platform provides native accessibility APIs
> that, when used, allow OS-level features (system screen readers, display
> accommodations, motor accessibility services) to work with your game. Ignoring
> these APIs does not break the game, but it means players who rely on OS-level
> accessibility tools get no benefit from them inside your game. Xbox in particular
> requires XAG compliance for certification. Verify platform requirements before
> committing to a tier — platform requirements set a floor, not a ceiling.
> **为何存在此章节**：每个平台都提供原生无障碍 API，使用它们可让操作系统级功能（系统屏幕阅读器、
> 显示辅助、运动无障碍服务）与你的游戏协同工作。忽略这些 API 不会破坏游戏，但意味着依赖
> 操作系统级无障碍工具的玩家在你的游戏内无法从中受益。Xbox 尤其要求 XAG 合规才能通过认证。
> 承诺层级前先核实平台要求 — 平台要求设定的是下限，而非上限。

---

## Per-Feature Accessibility Matrix
## 逐功能无障碍矩阵

> **Why this matrix exists**: Accessibility is not a list of settings — it is a
> property of every game system. This matrix creates the "accessibility impact"
> view of the game: which systems have which barriers, and whether those barriers
> are addressed. When a new system is added to systems-index.md, a row must be
> added here. If a system has an unaddressed accessibility concern, it cannot be
> marked Approved in the systems index.
> **为何存在此矩阵**：无障碍不是一份设置列表 — 它是每个游戏系统的属性。此矩阵创建游戏的
> “无障碍影响”视图：哪些系统有哪些障碍，以及这些障碍是否已解决。
> 当 systems-index.md 新增系统时，必须在此添加一行。若系统有未解决的无障碍顾虑，
> 就不能在系统索引中标记为已批准。

**Worked example rows**:
**完整示例行**：

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [Combat System] | [Enemy health bars are color-coded; attack animations may cause motion sickness] | [Rapid input required for combos; hold inputs for guard] | [Track enemy patterns + cooldowns + player resources simultaneously] | [Audio cues for off-screen attacks; critical damage warning sounds] | [Partial] | [Colorblind palette applied; hold-to-block toggle needed] |
| [Inventory / Equipment] | [Item rarity conveyed by border color] | [No motor concerns — turn-based] | [Item stats comparison requires reading multiple values] | [None — no critical audio in this system] | [Partial] | [Non-color rarity indicators in progress] |
| [Dialogue System] | [Subtitle display depends on contrast settings] | [No motor concerns] | [Long dialogue trees with time pressure on dialogue choices] | [All dialogue must be subtitled] | [Not Started] | [Timed dialogue choices must support extended timer option] |
| [Navigation / World Map] | [Map marker colors] | [No motor concerns] | [Quest objective clarity; waypoint visibility] | [Audio pings for objectives have no visual equivalent] | [Not Started] | |

| 系统 | 视觉顾虑 | 运动顾虑 | 认知顾虑 | 听觉顾虑 | 已解决 | 备注 |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [战斗系统] | [敌人血条为颜色编码；攻击动画可能引起晕动症] | [连击需要快速输入；防御需要长按输入] | [需同时跟踪敌人模式 + 冷却 + 玩家资源] | [屏幕外攻击的音频提示；关键伤害警告音] | [部分] | [已应用色盲调色板；需要长按格挡开关] |
| [库存 / 装备] | [物品稀有度通过边框颜色传达] | [无运动顾虑 — 回合制] | [物品属性比较需要阅读多个数值] | [无 — 此系统无关键音频] | [部分] | [非颜色稀有度指示正在进行] |
| [对话系统] | [字幕显示取决于对比度设置] | [无运动顾虑] | [长对话树，对话选项有时间压力] | [所有对话必须配字幕] | [未开始] | [限时对话选项必须支持延长计时选项] |
| [导航 / 世界地图] | [地图标记颜色] | [无运动顾虑] | [任务目标清晰度；航点可见性] | [目标的音频提示没有视觉等效物] | [未开始] | |

---

## Accessibility Test Plan
## 无障碍测试计划

> **Why testing accessibility separately from QA**: Standard QA tests whether
> features work. Accessibility testing tests whether features work for players
> who use them. These are different tests. A subtitle system can pass QA (it
> displays text) and fail accessibility testing (the text is unreadable at TV
> distance by a player with low vision). Plan for three test types: automated
> (contrast ratios, text sizes), manual internal (team members simulating
> impairments using accessibility simulators), and user testing (players who
> actually use these features).
> **为何将无障碍测试与 QA 分开**：标准 QA 测试功能是否工作。无障碍测试测试功能对使用它们的玩家
> 是否工作。这些是不同的测试。字幕系统可以通过 QA（它显示文字），但在无障碍测试中失败
> （低视力玩家在电视距离下无法读取文字）。计划三类测试：自动化（对比度、字号）、
> 内部人工（团队成员用无障碍模拟器模拟障碍）、用户测试（实际使用这些功能的玩家）。

---

## Known Intentional Limitations
## 已知有意限制

> **Why document what is NOT included**: Omissions left undocumented become
> surprises at certification or in community feedback. Documenting a limitation
> with a rationale demonstrates that it was a deliberate choice, not an oversight.
> It also identifies which players are not served and what the mitigation is.
> Every entry here is a risk — assess it honestly.
> **为何记录“未包含”的内容**：未记录的省略会在认证或社区反馈中变成意外。
> 记录限制并附理由，表明这是有意的选择而非疏忽。它还指出哪些玩家未被服务以及缓解措施是什么。
> 此处的每一条都是风险 — 诚实评估它。

**Worked example rows**:
**完整示例行**：

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| [Screen reader support for in-game world (NPCs, objects, environmental text)] | Exemplary | Engine (Godot 4.7) AccessKit integration covers menus only; extending to the game world requires a custom spatial audio description system beyond current scope | Affects blind and low-vision players who can navigate menus but cannot independently explore the game world | Ensure all critical world information is duplicated in accessible menu systems (quest log, map); evaluate for post-launch DLC |
| [Full subtitle customization (font/color/background)] | Comprehensive | Scope reduction — targeting Standard tier. Custom font rendering in Godot requires additional asset pipeline work | Affects deaf and hard-of-hearing players with specific legibility needs; particularly affects players with dyslexia who use custom fonts | Provide two preset subtitle styles (default and high-readability) as a partial mitigation; log for post-launch update |
| [Tactile/haptic alternatives for all audio cues] | Exemplary | Platform rumble API integration for non-Xbox platforms is out of scope for v1.0 | Affects deaf players relying on haptic feedback; PC players with non-Xbox controllers get no haptic response | Xbox controller haptic integration is in scope; evaluate PlayStation DualSense haptic API for a post-launch patch |

| 功能 | 所需层级 | 为何未包含 | 风险 / 影响 | 缓解措施 |
|---------|--------------|-----------------|--------------|------------|
| [游戏世界（NPC、物体、环境文字）的屏幕阅读器支持] | 示范 | 引擎（Godot 4.7）AccessKit 集成仅覆盖菜单；扩展到游戏世界需要超出当前范围的自定义空间音频描述系统 | 影响能浏览菜单但无法独立探索游戏世界的失明和低视力玩家 | 确保所有关键世界信息在可访问的菜单系统（任务日志、地图）中重复呈现；评估发布后 DLC |
| [完整字幕自定义（字体/颜色/背景）] | 全面 | 缩减范围 — 目标为标准层级。Godot 中的自定义字体渲染需要额外的资产管线工作 | 影响有特定可读性需求的失聪和听力困难玩家；尤其影响使用自定义字体的阅读障碍玩家 | 提供两种预设字幕样式（默认与高可读性）作为部分缓解；记录为发布后更新 |
| [所有音频提示的触觉/震动替代] | 示范 | 非 Xbox 平台的震动 API 集成不在 v1.0 范围内 | 影响依赖震动反馈的失聪玩家；使用非 Xbox 手柄的 PC 玩家没有震动响应 | Xbox 手柄震动集成在范围内；评估发布后补丁中的 PlayStation DualSense 震动 API |

---

## Audit History
## 审计历史

> **Why track audit history**: Accessibility is not certified once and done.
> Platform requirements change. New features may introduce new barriers. Legal
> standards evolve. An audit history demonstrates due diligence and helps identify
> regressions between audits.
> **为何跟踪审计历史**：无障碍认证不是一次完成。平台要求会变化。新功能可能引入新障碍。
> 法律标准会演进。审计历史证明尽职，并有助于识别审计之间的回归。

**Worked example rows**:
**完整示例行**：

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Date] | [Internal — ux-designer] | Internal review | [Pre-submission checklist against committed tier] | [e.g., "12 items verified, 3 open issues: subtitle contrast below target in 2 scenes, color-only indicator on minimap not resolved"] | [In Progress] |
| [Date] | [External — AbleGamers Player Panel] | User testing | [Motor accessibility — one-hand mode and timing adjustments] | [e.g., "Toggle modes functional. Timed QTE window at 3x still failed for one participant — recommend 5x option."] | [Findings addressed] |

| 日期 | 审计者 | 类型 | 范围 | 发现摘要 | 状态 |
|------|---------|------|-------|-----------------|--------|
| [日期] | [内部 — ux-designer] | 内部评审 | [对照已承诺层级的提交前争夺清单] | [例如，“已核实 12 项，3 个未决问题：2 个场景中字幕对比度低于目标，小地图上仅颜色指示未解决”] | [进行中] |
| [日期] | [外部 — AbleGamers 玩家小组] | 用户测试 | [运动无障碍 — 单手模式与计时调整] | [例如，“开关模式可用。3x 的限时 QTE 窗口对一名参与者仍失败 — 建议提供 5x 选项。”] | [发现已处理] |

---

## Open Questions
## 待决问题

**Worked example questions**:
**完整示例问题**：

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does Godot 4.7 AccessKit support dynamic accessibility node updates for HUD elements, or only static menus?] | [ux-designer] | [Before Technical Setup gate] | [Unresolved — check engine-reference/godot/ docs] |
| [What is the Xbox ID@Xbox minimum XAG compliance requirement for our release window?] | [producer] | [Before Pre-Production gate] | [Unresolved] |
| [Will the dialogue system support timed choice extensions without a full architecture change?] | [lead-programmer] | [During Technical Design] | [Unresolved] |

| 问题 | 负责人 | 截止日期 | 解决方式 |
|----------|-------|----------|-----------|
| [Godot 4.7 AccessKit 是否支持 HUD 元素的动态无障碍节点更新，还是仅支持静态菜单？] | [ux-designer] | [技术设置关卡前] | [未解决 — 查阅 engine-reference/godot/ 文档] |
| [我们发布窗口的 Xbox ID@Xbox 最低 XAG 合规要求是什么？] | [producer] | [预制作关卡前] | [未解决] |
| [对话系统能否在不做完整架构变更的情况下支持限时选项延长？] | [lead-programmer] | [技术设计期间] | [未解决] |
