# HUD Design
# HUD 设计

> Authoring guidance: .claude/docs/templates/guidance/hud-design-guide.md (load per-section as you author — do not read entirely).
> 编写指南：.claude/docs/templates/guidance/hud-design-guide.md（写作时按章节加载 — 不要整篇通读）。

> **Status**: [In Design | In Review | Approved | Implemented]
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Game**: [Game name — this is a single document per game, not per element]
> **Platform Targets**: [target platforms and input methods from 2h]
> **Related GDDs**: [Every system that exposes information through the HUD — e.g., `design/gdd/combat.md`, `design/gdd/progression.md`, `design/gdd/quests.md`]
> **Accessibility Tier**: Basic | Standard | Comprehensive | Exemplary
> **Style Reference**: [Link to art bible HUD section if it exists — e.g., `design/art/art-bible.md § 7. UI/HUD Visual Direction`]
> **Template**: HUD Design
> **状态**：[设计中 | 审核中 | 已批准 | 已实现]
> **作者**：[用户 + ux-designer]
> **最后更新**：[今天的日期]
> **游戏**：[游戏名称 — 每款游戏一份文档，而非每个元素一份]
> **平台目标**：[来自 2h 的目标平台与输入方式]
> **相关 GDD**：[通过 HUD 暴露信息的每个系统 — 例如，`design/gdd/combat.md`、`design/gdd/progression.md`、`design/gdd/quests.md`]
> **无障碍层级**：基础 | 标准 | 全面 | 示范
> **风格参考**：[如存在，链接到美术指南 HUD 章节 — 例如，`design/art/art-bible.md § 7. UI/HUD Visual Direction`]
> **模板**：HUD 设计

> **Note — Scope boundary**: This document specifies all elements that overlay the
> game world during active gameplay — health bars, ammo counters, minimaps, quest
> trackers, subtitles, damage numbers, and notification toasts. For menu screens,
> pause menus, inventory, and dialogs that the player navigates explicitly, use
> `ux-spec.md` instead. The test: if it appears while the player is directly
> controlling their character, it belongs here.
> **注 — 范围边界**：本文档规定在活跃游戏过程中覆盖游戏世界的所有元素 — 血条、弹药计数器、小地图、
> 任务追踪器、字幕、伤害数字和通知 toast。对于玩家显式浏览的菜单屏幕、暂停菜单、库存与对话框，
> 请改用 `ux-spec.md`。测试：如果它出现在玩家直接控制角色时，则属于此文档。

---

## 1. HUD Philosophy
## 1. HUD 哲学

[To be designed]
[待设计]

**What is this game's relationship with on-screen information?**
**此游戏与屏幕信息的关系是什么？**

[One-paragraph design statement — see guide Section 1 for framing and examples]
[一段话的设计声明 — 框架与示例见指南第 1 节]

**Visibility principle** — when in doubt, show or hide?
**可见性原则** — 拿不准时，显示还是隐藏？

[Default resolution for ambiguous cases: HIDE / SHOW / CONTEXTUAL — see guide]
[模糊情况下的默认处理：隐藏 / 显示 / 情境化 — 见指南]

**The Rule of Necessity for this game**:
**此游戏的必要性规则**：

["A HUD element earns its place when ______________." — see guide for examples]
[“当 ______________ 时，一个 HUD 元素才配得上它的位置。” — 示例见指南]

---

## 2. Information Architecture
## 2. 信息架构

> Categorize EVERY piece of information the game generates — this is the master
> inventory of game information, not just HUD information. See guide Section 2
> for a worked example covering typical information types.
> 对游戏产生的**每一条**信息进行分类 — 这是游戏信息的主清单，而不仅是 HUD 信息。
> 覆盖典型信息类型的完整示例见指南第 2 节。

### 2.1 Full Information Inventory
### 2.1 完整信息清单

[To be designed]
[待设计]

[Every piece of information the game generates, one line each — health, resources, objectives, timers, status effects, subtitles and the rest — whether or not the HUD shows it.]
[游戏产生的每一条信息，每行一条 — 生命、资源、目标、计时器、状态效果、字幕等 — 无论 HUD 是否显示它。]

### 2.2 Categorization
### 2.2 分类

[To be designed]
[待设计]

| Information Type | Always Show | Contextual (show when relevant) | On Demand (menu/button) | Hidden (environmental / diegetic) | Reasoning |
|-----------------|-------------|--------------------------------|------------------------|----------------------------------|-----------|
| [Information type — e.g., Health, resource, minimap, quest objective, subtitles, status effects, timer, XP] | [ ] | [ ] | [ ] | [ ] | [Why this presentation category] |

| 信息类型 | 始终显示 | 情境化（相关时显示） | 按需（菜单/按钮） | 隐藏（环境 / 叙事内） | 理由 |
|-----------------|-------------|--------------------------------|------------------------|----------------------------------|-----------|
| [信息类型 — 例如，生命、资源、小地图、任务目标、字幕、状态效果、计时器、XP] | [ ] | [ ] | [ ] | [ ] | [为何属于此呈现类别] |

---

## 3. Layout Zones
## 3. 布局区域

[To be designed]
[待设计]

### 3.1 Zone Diagram
### 3.1 区域示意图

```
[Draw your HUD layout zones. Customize this to match your game's actual layout.
 Axes represent approximate screen percentage. Adjust zone names and sizes.]

 0%                                             100%
 ┌──────────────────────────────────────────────────┐  0%
 │  [SAFE MARGIN — 10% from edge on all sides]      │
 │  ┌────────────────────────────────────────────┐  │
 │  │ [TOP-LEFT]              [TOP-CENTER]  [TOP-RIGHT] │  ~15%
 │  │  Health, resource       Quest name    Ammo, magazine │
 │  │                                              │  │
 │  │                                              │  │
 │  │               [CENTER-SCREEN]               │  │  ~50%
 │  │                Crosshair / reticle           │  │
 │  │               (minimize HUD here)            │  │
 │  │                                              │  │
 │  │                                              │  │
 │  │ [BOTTOM-LEFT]     [BOTTOM-CENTER]   [BOTTOM-RIGHT] │  ~85%
 │  │  Minimap          Subtitles          Notifications │
 │  │  Ability icons    Tutorial prompts             │  │
 │  └────────────────────────────────────────────┘  │
 │                                                  │
 └──────────────────────────────────────────────────┘  100%
```

```
[绘制你的 HUD 布局区域。以此定制以匹配你游戏的实际布局。
 坐标轴表示大致屏幕百分比。调整区域名称与尺寸。]

 0%                                             100%
 ┌──────────────────────────────────────────────────┐  0%
 │  [安全边距 — 四边各距边缘 10%]      │
 │  ┌────────────────────────────────────────────┐  │
 │  │ [左上]              [顶部居中]  [右上] │  ~15%
 │  │  生命、资源          任务名称    弹药、弹匣 │
 │  │                                              │  │
 │  │                                              │  │
 │  │               [屏幕中心]               │  │  ~50%
 │  │                准星 / 瞄具           │  │
 │  │               （此处尽量少放 HUD）            │  │
 │  │                                              │  │
 │  │                                              │  │
 │  │ [左下]     [底部居中]   [右下] │  ~85%
 │  │  小地图          字幕          通知 │
 │  │  技能图标        教程提示             │  │
 │  └────────────────────────────────────────────┘  │
 │                                                  │
 └──────────────────────────────────────────────────┘  100%
```

> Rule for zone placement: the center 40% of the screen (both horizontally and
> vertically) is the player's primary focus area. Keep this zone as clear as
> possible at all times. HUD elements that appear in the center zone — crosshairs,
> interaction prompts, hit markers — must be minimal, high-contrast, and brief.
> 区域放置规则：屏幕中央 40%（水平和垂直方向）是玩家的主要注视区。应始终保持该区域尽可能清爽。
> 出现在中央区域的 HUD 元素 — 准星、交互提示、命中标记 — 必须极简、高对比且短暂。

### 3.2 Zone Specification Table
### 3.2 区域规格表

| Zone Name | Screen Position | Safe Zone Compliant | Primary Elements | Max Simultaneous Elements | Notes |
|-----------|----------------|---------------------|-----------------|--------------------------|-------|
| [Zone] | [Position] | [Yes/No + margins] | [Elements assigned] | [N] | [Zone purpose] |

| 区域名称 | 屏幕位置 | 符合安全区 | 主要元素 | 最大同时元素数 | 备注 |
|-----------|----------------|---------------------|-----------------|--------------------------|-------|
| [区域] | [位置] | [是/否 + 边距] | [分配的元素] | [N] | [区域用途] |

**Safe zone margins by platform**:
**各平台安全区边距**：

| Platform | Top | Bottom | Left | Right | Notes |
|----------|-----|--------|------|-------|-------|
| [Platform] | [%] | [%] | [%] | [%] | [Platform-specific notes] |

| 平台 | 上 | 下 | 左 | 右 | 备注 |
|----------|-----|--------|------|-------|-------|
| [平台] | [%] | [%] | [%] | [%] | [平台专属备注] |

---

## 4. HUD Element Specifications
## 4. HUD 元素规格

[To be designed]
[待设计]

### 4.1 Element Overview Table
### 4.1 元素总览表

> One row per HUD element. This is the master inventory for implementation planning.
> 每个 HUD 元素一行。这是实现规划的主清单。

| Element Name | Zone | Always Visible | Visibility Trigger | Data Source | Update Frequency | Max Size (% screen W) | Min Readable Size | Overlap Priority | Accessibility Alt |
|-------------|------|---------------|-------------------|-------------|-----------------|----------------------|------------------|-----------------|------------------|
| [Element] | [Zone] | [Yes/No] | [Trigger or N/A] | [Owning system] | [When it updates] | [%] | [px] | [N] | [Non-visual/non-color alternative] |

| 元素名称 | 区域 | 始终可见 | 可见性触发条件 | 数据源 | 更新频率 | 最大尺寸（屏幕宽度 %） | 最小可读尺寸 | 重叠优先级 | 无障碍替代 |
|-------------|------|---------------|-------------------|-------------|-----------------|----------------------|------------------|-----------------|------------------|
| [元素] | [区域] | [是/否] | [触发条件或 N/A] | [所属系统] | [何时更新] | [%] | [px] | [N] | [非视觉/非颜色替代] |

### 4.2 Element Detail Blocks
### 4.2 元素详情块

> For each element in the table above, write a detail block. Copy and complete
> one block per element. See guide Section 4 for completed Health Bar and
> Minimap examples.
> 为上表中的每个元素写一个详情块。每个元素复制并填写一个块。
> 已完成的血条与小地图示例见指南第 4 节。

---

**[Element Name]**
**[元素名称]**

- Visual description: [Shape, fill direction, background, color behavior]
- Data displayed: [Values shown, including any numerical text labels]
- Update behavior: [Animation/lerp timing, flash behavior on large changes]
- Urgency states: [Per-threshold visual states, e.g., Normal / Caution / Critical / Zero]
- Interaction: [Interactive or display-only]
- Player customization: [Opacity, repositioning, size options]
- 视觉描述：[形状、填充方向、背景、颜色行为]
- 显示数据：[显示的数值，包括任何数字文本标签]
- 更新行为：[动画/插值时长、大幅变化时的闪烁行为]
- 紧急状态：[按阈值的视觉状态，例如，正常 / 警戒 / 危急 / 归零]
- 交互：[可交互或仅显示]
- 玩家自定义：[透明度、重新定位、尺寸选项]

---

**[Repeat this block for every element in Section 4.1]**
**[对第 4.1 节中的每个元素重复此块]**

---

## 5. HUD States by Gameplay Context
## 5. 按玩法情境的 HUD 状态

[To be designed]
[待设计]

> Define the HUD transformation for every gameplay context — at minimum:
> exploration, combat, dialogue/cutscene, and paused/menu. See guide Section 5
> for a worked example covering nine contexts.
> 为每种玩法情境定义 HUD 变换 — 至少包括：
> 探索、战斗、对话/过场和暂停/菜单。覆盖九种情境的完整示例见指南第 5 节。

| Context | Elements Shown | Elements Hidden | Elements Modified | Transition Into This State |
|---------|---------------|-----------------|------------------|---------------------------|
| [Context — e.g., Exploration / Combat / Dialogue / Cinematic / Menu open / Death / Loading / Tutorial / Boss] | [Shown] | [Hidden] | [Modified] | [Transition timing + trigger] |

| 情境 | 显示的元素 | 隐藏的元素 | 修改的元素 | 进入此状态的过渡 |
|---------|---------------|-----------------|------------------|---------------------------|
| [情境 — 例如，探索 / 战斗 / 对话 / 过场 / 菜单打开 / 死亡 / 加载 / 教程 / Boss] | [显示] | [隐藏] | [修改] | [过渡时长 + 触发条件] |

---

## 6. Information Hierarchy
## 6. 信息层级

[To be designed]
[待设计]

> Assign every element a priority tier (MUST KEEP / SHOULD KEEP / CAN HIDE /
> ALWAYS HIDE) with reasoning. See guide Section 6 for a worked example.
> 为每个元素分配优先级层级（必须保留 / 应当保留 / 可以隐藏 / 始终隐藏）并给出理由。
> 完整示例见指南第 6 节。

| Element | Priority Tier | Reasoning | What Replaces It If Hidden |
|---------|--------------|-----------|---------------------------|
| [Element] | [MUST KEEP / SHOULD KEEP / CAN HIDE / ALWAYS HIDE] | [Why] | [Fallback channel or N/A] |

| 元素 | 优先级层级 | 理由 | 若隐藏则由什么替代 |
|---------|--------------|-----------|---------------------------|
| [元素] | [必须保留 / 应当保留 / 可以隐藏 / 始终隐藏] | [为何] | [备用渠道或 N/A] |

---

## 7. Visual Budget
## 7. 视觉预算

[To be designed]
[待设计]

> These numbers are hard limits, not guidelines. Every element addition that
> would breach a limit requires explicit approval and must displace or reduce an
> existing element. See guide Section 7 for how to apply the budgets.
> 这些数字是硬性限制，而非指导原则。任何会突破限制的元素新增都需要明确批准，
> 且必须挤占或减少一个现有元素。如何应用预算见指南第 7 节。

| Budget Constraint | Limit | Measurement Method | Current Estimate | Status |
|------------------|-------|--------------------|-----------------|--------|
| Maximum simultaneous active HUD elements | [8] | [Count all visible, non-faded elements at any one frame] | [TBD — verify at implementation] | [To verify] |
| Maximum % of screen occupied by HUD (exploration mode) | [12%] | [Pixel area of all HUD elements / total screen pixels] | [TBD] | [To verify] |
| Maximum % of screen occupied by HUD (combat mode) | [22%] | [Same method — combat adds ammo, crosshair, enemy bars] | [TBD] | [To verify] |
| Maximum % of center screen zone (40% of screen W/H) occupied | [5%] | [Only crosshair and interaction prompt allowed here] | [TBD] | [To verify] |
| Minimum contrast ratio — HUD text on any background | [4.5:1 (WCAG AA)] | [Measured against the darkest and lightest game world areas the element will appear over] | [TBD] | [To verify] |
| Maximum opacity for HUD background panels | [65%] | [Opacity of any panel behind HUD text — must preserve world visibility through panel] | [TBD] | [To verify] |
| Minimum HUD element size at minimum supported resolution | [40px for icons, 18px for text] | [Measure at lowest target resolution] | [TBD] | [To verify] |

| 预算约束 | 限制 | 测量方法 | 当前估计 | 状态 |
|------------------|-------|--------------------|-----------------|--------|
| 同时活跃的 HUD 元素最大数 | [8] | [统计任一帧内所有可见、未淡出的元素] | [待定 — 实现时验证] | [待验证] |
| HUD 占屏幕最大百分比（探索模式） | [12%] | [所有 HUD 元素的像素面积 / 屏幕总像素] | [待定] | [待验证] |
| HUD 占屏幕最大百分比（战斗模式） | [22%] | [相同方法 — 战斗会加入弹药、准星、敌人血条] | [待定] | [待验证] |
| 中心屏幕区域（屏幕宽高 40%）被占用的最大百分比 | [5%] | [此处只允许准星与交互提示] | [待定] | [待验证] |
| 最小对比度 — 任意背景上的 HUD 文字 | [4.5:1（WCAG AA）] | [针对该元素将要出现在其上的最深与最浅游戏世界区域测量] | [待定] | [待验证] |
| HUD 背景面板的最大不透明度 | [65%] | [HUD 文字后任何面板的不透明度 — 必须让世界透过面板仍可见] | [待定] | [待验证] |
| 最低支持分辨率下 HUD 元素最小尺寸 | [图标 40px，文字 18px] | [在最低目标分辨率下测量] | [待定] | [待验证] |

---

## 8. Feedback & Notification Systems
## 8. 反馈与通知系统

[To be designed]
[待设计]

> One row per notification type. Every notification must have queue/priority
> behavior defined. See guide Section 8 for a worked example table and queue rules.
> 每种通知类型一行。每条通知都必须定义队列/优先级行为。
> 完整示例表与队列规则见指南第 8 节。

| Notification Type | Trigger System | Screen Position | Duration (ms) | Animation In / Out | Max Simultaneous | Priority | Queue Behavior | Dismissible? |
|------------------|---------------|-----------------|--------------|-------------------|-----------------|----------|---------------|-------------|
| [Type] | [System] | [Zone] | [ms] | [In / out animation + timing] | [N] | [Priority] | [Queue/merge/preempt behavior] | [Yes/No] |

| 通知类型 | 触发系统 | 屏幕位置 | 持续时间（毫秒） | 进入 / 退出动画 | 最大同时数 | 优先级 | 队列行为 | 可消除？ |
|------------------|---------------|-----------------|--------------|-------------------|-----------------|----------|---------------|-------------|
| [类型] | [系统] | [区域] | [毫秒] | [进入 / 退出动画 + 时长] | [N] | [优先级] | [队列/合并/抢占行为] | [是/否] |

**Notification queue rules**:
1. [Combat-aware queue rule — which priorities are held during combat and how the queue flushes]
2. [Merge rule — when identical notification types merge into one]
3. [Critical bypass rule — which notifications are never queued, never merged]
**通知队列规则**：
1. [战斗感知队列规则 — 战斗中哪些优先级被暂存，以及队列如何刷新]
2. [合并规则 — 相同通知类型何时合并为一条]
3. [关键绕过规则 — 哪些通知从不排队、从不合并]

---

## 9. Platform Adaptation
## 9. 平台适配

[To be designed]
[待设计]

> Every target platform requires explicit layout testing before certification.
> See guide Section 9 for a worked example.
> 每个目标平台在认证前都需要明确的布局测试。完整示例见指南第 9 节。

| Platform | Safe Zone | Resolution Range | Input Method | HUD-Specific Notes |
|----------|-----------|-----------------|-------------|-------------------|
| [Platform] | [Margin] | [Min–max resolution] | [Input] | [Platform-specific HUD constraints] |

| 平台 | 安全区 | 分辨率范围 | 输入方式 | HUD 专属备注 |
|----------|-----------|-----------------|-------------|-------------------|
| [平台] | [边距] | [最小–最大分辨率] | [输入] | [平台专属 HUD 约束] |

**HUD repositionability requirement**: Players must be able to reposition at minimum the following elements using an in-game HUD layout editor (required for accessibility compliance on console):
- [Health bar]
- [Minimap]
- [Ability bar (if present)]
**HUD 可重定位要求**：玩家必须能通过游戏内 HUD 布局编辑器至少重定位以下元素（主机无障碍合规所要求）：
- [血条]
- [小地图]
- [技能栏（如存在）]

Repositioning saves to player profile, not to a single slot. Applies across play sessions.
重定位保存到玩家档案，而非单个存档槽位。跨游戏会话生效。

---

## 10. Accessibility
## 10. 无障碍

[To be designed]
[待设计]

> HUD-specific requirements only — refer to the project's
> `design/accessibility-requirements.md` for the full project standard.
> 仅 HUD 专属需求 — 完整项目标准请参考项目的 `design/accessibility-requirements.md`。

### 10.1 Colorblind Modes
### 10.1 色盲模式

| Element | Color-Only Information Risk | Colorblind Mode Fix |
|---------|----------------------------|---------------------|
| [Element] | [Where color alone carries meaning] | [Non-color alternative: shape, icon, symbol, text] |

| 元素 | 仅靠颜色的信息风险 | 色盲模式修正 |
|---------|----------------------------|---------------------|
| [元素] | [仅靠颜色承载含义之处] | [非颜色替代：形状、图标、符号、文字] |

### 10.2 Text Scaling
### 10.2 文本缩放

[Describe what happens at 150% UI text scale: which elements reflow, clip, or are architecturally blocked from scaling — see guide Section 10 for an example narrative]
[描述 UI 文本缩放至 150% 时会发生什么：哪些元素重排、裁剪，或因架构限制无法缩放 — 示例叙述见指南第 10 节]

**Text scaling test matrix**:
**文本缩放测试矩阵**：

| Element | 100% (baseline) | 125% | 150% | Overflow behavior |
|---------|----------------|------|------|-------------------|
| [Element] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [What happens on overflow] |

| 元素 | 100%（基线） | 125% | 150% | 溢出行为 |
|---------|----------------|------|------|-------------------|
| [元素] | [通过/失败/待定] | [通过/失败/待定] | [通过/失败/待定] | [溢出时会发生什么] |

### 10.3 Motion Sensitivity
### 10.3 运动敏感

| Animation / Motion Element | Severity | Disabled by Reduced Motion Setting? | Replacement Behavior |
|---------------------------|----------|-------------------------------------|---------------------|
| [Animated element] | [Mild/Moderate/High] | [Yes/No/Optional] | [Static replacement] |

| 动画 / 运动元素 | 严重程度 | 是否被减少动态效果设置禁用？ | 替代行为 |
|---------------------------|----------|-------------------------------------|---------------------|
| [动画元素] | [轻微/中等/强烈] | [是/否/可选] | [静态替代] |

### 10.4 Subtitles Specification
### 10.4 字幕规格

> Subtitles are the highest-impact accessibility feature in the HUD. Specify them
> with the same rigor as the rest of the HUD. Do not leave subtitle behavior to
> implementation discretion.
> 字幕是 HUD 中影响最大的无障碍功能。应以与 HUD 其余部分同样的严谨度来规定它们。
> 不要把字幕行为留给实现阶段自行决定。

- **Default setting**: [ON or OFF — document your game's default and the rationale. Industry standard is ON by default.]
- **Position**: [Zone, alignment, relationship to safe zone margin]
- **Max characters per line**: [e.g., 42 characters — the readable limit at minimum text size on TV viewing distance]
- **Max simultaneous lines**: [e.g., 2 lines before scrolling]
- **Speaker identification**: [Name display method — never rely on color alone]
- **Background**: [Panel treatment ensuring contrast against any game world background]
- **Font size minimum**: [px at reference resolution — scales with text scale setting]
- **Line break behavior**: [Break at natural language pause points — never mid-word]
- **Subtitle persistence**: [Hold duration relative to spoken line — never disappear while audio is still playing]
- **Non-dialogue captions**: [Whether ambient sounds, music, and SFX are captioned, and where these appear]
- **默认设置**：[开启或关闭 — 记录你游戏的默认值及理由。行业标准是默认开启。]
- **位置**：[区域、对齐方式、与安全区边距的关系]
- **每行最大字符数**：[例如，42 个字符 — 电视观看距离下最小字号的可读上限]
- **最大同时行数**：[例如，滚动前 2 行]
- **说话人识别**：[名称显示方式 — 绝不要仅依赖颜色]
- **背景**：[确保对任意游戏世界背景都有对比度的面板处理]
- **最小字号**：[参考分辨率下的 px — 随文本缩放设置缩放]
- **换行行为**：[在自然语言停顿处换行 — 绝不在词中间换行]
- **字幕持续**：[相对于语音行的保持时长 — 音频仍在播放时绝不消失]
- **非对话说明文字**：[环境音、音乐与音效是否配字幕，以及这些字幕出现在哪里]

### 10.5 HUD Opacity and Visibility Controls
### 10.5 HUD 透明度与可见性控制

The following player-adjustable settings must be available from the Accessibility menu:
以下玩家可调设置必须可从无障碍菜单访问：

| Setting | Range | Default | Effect |
|---------|-------|---------|--------|
| [HUD Opacity — Global] | [0% (HUD hidden) to 100%] | [100%] | [Scales all HUD element opacities simultaneously] |
| [HUD Text Scale] | [75% to 150%] | [100%] | [Scales all HUD text elements; layout adapts] |
| [Damage Number Visibility] | [On / Off] | [On] | [Enables or disables all floating damage numbers] |
| [Minimap Visibility] | [On / Off / Compass Only] | [On] | [Compass strip shown as fallback when minimap off] |
| [Notification Verbosity] | [All / Important Only / Off] | [All] | [All = all toasts; Important Only = quest + level up; Off = no toasts] |
| [Motion Reduction] | [On / Off] | [Off] | [When On, replaces all animated HUD transitions with instant state changes] |
| [High Contrast Mode] | [On / Off] | [Off] | [Applies high contrast visual theme to all HUD elements — see art bible for HC variants] |

| 设置 | 范围 | 默认 | 效果 |
|---------|-------|---------|--------|
| [HUD 不透明度 — 全局] | [0%（HUD 隐藏）至 100%] | [100%] | [同时缩放所有 HUD 元素的不透明度] |
| [HUD 文本缩放] | [75% 至 150%] | [100%] | [缩放所有 HUD 文本元素；布局自适应] |
| [伤害数字可见性] | [开 / 关] | [开] | [启用或禁用所有飘浮伤害数字] |
| [小地图可见性] | [开 / 关 / 仅罗盘] | [开] | [关闭小地图时以罗盘条作为替代] |
| [通知详细度] | [全部 / 仅重要 / 关闭] | [全部] | [全部 = 所有 toast；仅重要 = 任务 + 升级；关闭 = 无 toast] |
| [减少动态效果] | [开 / 关] | [关] | [开启时，将所有动画 HUD 过渡替换为即时状态切换] |
| [高对比度模式] | [开 / 关] | [关] | [为所有 HUD 元素应用高对比度视觉主题 — 高对比变体见美术指南] |

---

## 11. Tuning Knobs
## 11. 调参旋钮

[To be designed]
[待设计]

> Document all tunable parameters before implementation so the programmer knows
> which values to externalize. See guide Section 11 for a worked example.
> 实现前记录所有可调参数，以便程序员知道哪些值需要外置。完整示例见指南第 11 节。

| Parameter | Current Value | Range | Effect of Increase | Effect of Decrease | Player Adjustable? | Notes |
|-----------|-------------|-------|-------------------|-------------------|-------------------|-------|
| [Parameter] | [Value] | [Min–max] | [Effect] | [Effect] | [Yes/No + how exposed] | [Tuning notes] |

| 参数 | 当前值 | 范围 | 增加的效果 | 减少的效果 | 玩家可调？ | 备注 |
|-----------|-------------|-------|-------------------|-------------------|-------------------|-------|
| [参数] | [数值] | [最小–最大] | [效果] | [效果] | [是/否 + 如何暴露] | [调参备注] |

---

## 12. Acceptance Criteria
## 12. 验收标准

[To be designed]
[待设计]

> These criteria are the certification checklist for the HUD. Every item must
> pass before the HUD can be marked Approved. QA must be able to verify each
> item independently.
> 这些标准是 HUD 的认证争夺清单。每一项都必须通过，HUD 才能标记为已批准。
> QA 必须能够独立验证每一项。

**Layout & Visibility**
- [ ] All HUD elements are within platform safe zone margins on all target platforms
- [ ] No two HUD elements overlap in any documented gameplay context
- [ ] HUD occupies less than [12]% of screen area in exploration context (measure at reference resolution)
- [ ] HUD occupies less than [22]% of screen area in combat context
- [ ] No HUD element occupies the center [40]% of screen during exploration (crosshair excepted during combat)
- [ ] All HUD elements are visible and legible at minimum supported resolution on all platforms
**布局与可见性**
- [ ] 所有 HUD 元素在所有目标平台上都处于平台安全区边距内
- [ ] 在任何已记录的玩法情境中，任意两个 HUD 元素都不重叠
- [ ] 探索情境下 HUD 占用屏幕面积小于 [12]%（在参考分辨率下测量）
- [ ] 战斗情境下 HUD 占用屏幕面积小于 [22]%
- [ ] 探索时没有 HUD 元素占用屏幕中央 [40]%（战斗期间准星除外）
- [ ] 所有 HUD 元素在所有平台的最低支持分辨率下均可见且清晰可读

**Per-Context Correctness**
- [ ] HUD correctly shows only specified elements in every context defined in Section 5
- [ ] Context transitions (combat enter/exit, dialogue, cinematic) show correct elements within transition timing spec
- [ ] Boss health bar appears correctly on boss encounter trigger and disappears after boss defeat
- [ ] Death state correctly hides all gameplay HUD elements
**各情境正确性**
- [ ] 在第 5 节定义的每个情境中，HUD 仅正确显示规定的元素
- [ ] 情境过渡（进入/退出战斗、对话、过场）在过渡时序规格内显示正确的元素
- [ ] Boss 血条在 Boss 遭遇触发时正确出现，并在 Boss 击败后消失
- [ ] 死亡状态正确隐藏所有玩法 HUD 元素

**Accessibility**
- [ ] All HUD text elements meet 4.5:1 contrast ratio against all backgrounds they appear over (test light AND dark scenes)
- [ ] No HUD element uses color as the ONLY differentiator (verify: remove color from each element and confirm information is still communicated)
- [ ] Subtitles appear for all voiced lines and ambient dialogue when subtitle setting is enabled
- [ ] Subtitle text never disappears while audio is still playing
- [ ] Reduced Motion setting disables all HUD animations listed in Section 10.3
- [ ] Text Scale 150% does not cause any HUD text to overflow its container or overlap another element
- [ ] All player-adjustable HUD settings in Section 10.5 are functional and persist between sessions
**无障碍**
- [ ] 所有 HUD 文字元素对其出现的所有背景都满足 4.5:1 对比度（测试明亮**和**昏暗场景）
- [ ] 没有 HUD 元素将颜色作为**唯一**区分手段（验证：从每个元素移除颜色，确认信息仍被传达）
- [ ] 启用字幕设置时，所有配音台词与环境对话都显示字幕
- [ ] 音频仍在播放时，字幕文字绝不消失
- [ ] 减少动态效果设置禁用第 10.3 节列出的所有 HUD 动画
- [ ] 文本缩放 150% 不会导致任何 HUD 文字溢出其容器或与其他元素重叠
- [ ] 第 10.5 节中所有玩家可调 HUD 设置均正常工作，并在会话之间保持

**Notifications**
- [ ] Notifications of the same type that fire within 500ms merge into a single notification
- [ ] Low-priority notifications are queued (not displayed) during combat and released post-combat
- [ ] Critical warnings (low health, hazard) appear immediately regardless of queue state or combat state
- [ ] No more than [3] notification toasts are visible simultaneously
- [ ] Notification queue is cleared correctly on level transition (no stale notifications from previous area)
**通知**
- [ ] 500 毫秒内触发的同类型通知合并为单条通知
- [ ] 低优先级通知在战斗中排队（不显示），并在战斗后释放
- [ ] 关键警告（低生命、危险）无论队列或战斗状态如何都立即出现
- [ ] 同时可见的通知 toast 不超过 [3] 条
- [ ] 关卡过渡时通知队列被正确清空（没有来自上一区域的陈旧通知）

**Platform**
- [ ] All elements respect 10% safe zone margins on console (test on physical TV — not monitor)
- [ ] HUD displays correctly at 1280x720 (Steam Deck) with no element clipping or overlap
- [ ] HUD elements are repositionable (Health, Minimap, Ability Bar) and reposition settings persist
- [ ] Controller disconnection during play does not cause HUD state corruption
**平台**
- [ ] 主机上所有元素遵守 10% 安全区边距（在实体电视上测试 — 而非显示器）
- [ ] HUD 在 1280x720（Steam Deck）下正确显示，无元素裁剪或重叠
- [ ] HUD 元素可重定位（生命、小地图、技能栏），且重定位设置保持
- [ ] 游玩中手柄断连不会导致 HUD 状态损坏

---

## 13. Open Questions
## 13. 待决问题

[To be designed]
[待设计]

> Track unresolved design questions here. All questions must be resolved before
> the HUD design document can be marked Approved. See guide Section 13 for
> example questions.
> 在此跟踪未解决的设计问题。所有问题都必须在 HUD 设计文档标记为已批准前解决。
> 示例问题见指南第 13 节。

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |

| 问题 | 负责人 | 截止日期 | 解决方式 |
|----------|-------|----------|-----------|
| [添加问题] | [负责人] | [截止日期] | [解决方式] |
