# Accessibility Requirements
# 无障碍需求

> Authoring guidance: .claude/docs/templates/guidance/accessibility-requirements-guide.md (load per-section as you author — do not read entirely).
> 编写指南：.claude/docs/templates/guidance/accessibility-requirements-guide.md（编写时按章节加载 —— 不要整篇通读）。

> **Status**: [In Design | Committed | Audited | Certified]
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Accessibility Tier Target**: [Basic / Standard / Comprehensive / Exemplary]
> **Platform(s)**: [PC / Xbox / PlayStation 5 / Nintendo Switch / iOS / Android]
> **External Standards Targeted**:
> - WCAG 2.1 Level [A / AA / AAA]
> - AbleGamers CVAA Guidelines
> - Xbox Accessibility Guidelines (XAG) [Yes / No / Partial]
> - PlayStation Accessibility (Sony Guidelines) [Yes / No / Partial]
> - Apple / Google Accessibility Guidelines [Yes / No / N/A — mobile only]
> **Accessibility Consultant**: [Name and organization, or "None engaged"]
> **Linked Documents**: `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`
> **Template**: Accessibility Requirements
> **状态**：[设计中 | 已承诺 | 已审计 | 已认证]
> **作者**：[user + ux-designer]
> **最后更新**：[today's date]
> **无障碍层级目标**：[Basic / Standard / Comprehensive / Exemplary]
> **平台**：[PC / Xbox / PlayStation 5 / Nintendo Switch / iOS / Android]
> **对标的外部标准**：
> - WCAG 2.1 [A / AA / AAA] 级
> - AbleGamers CVAA 指南
> - Xbox 无障碍指南（XAG）[是 / 否 / 部分]
> - PlayStation 无障碍（索尼指南）[是 / 否 / 部分]
> - Apple / Google 无障碍指南 [是 / 否 / N/A —— 仅移动端]
> **无障碍顾问**：[姓名与机构，或“未聘请”]
> **关联文档**：`design/gdd/systems-index.md`、`design/ux/interaction-patterns.md`
> **模板**：无障碍需求

> **Why this document exists**: Per-screen accessibility annotations belong in
> UX specs. This document captures the project-wide accessibility commitments,
> the feature matrix across all systems, the test plan, and the audit history.
> It is created once during Technical Setup by the UX designer with
> `/ux-design accessibility` — you pick the tier, against the criteria
> accessibility-specialist sets and audits against — then updated as features
> are added and audits are completed. If a feature conflicts with a commitment
> made here, this document wins — change the feature, not the commitment,
> unless the producer approves a formal revision.
>
> **When to update**: After each `/gate-check` pass, after any accessibility
> audit, and whenever a new game system is added to `systems-index.md`.
> **本文档存在的意义**：逐界面的无障碍标注属于
> UX 规格。本文档记录项目级的无障碍承诺、
> 跨所有系统的功能矩阵、测试计划和审计历史。
> 它在技术搭建阶段由 UX 设计师使用
> `/ux-design accessibility` 创建一次 —— 你选择层级，对照由
> accessibility-specialist 设定并审计的标准 —— 随后在增加功能
> 和完成审计时更新。若某项功能与本文档中的承诺冲突，
> 以本文档为准 —— 更改功能，而非承诺，
> 除非制作人批准正式修订。
>
> **何时更新**：每次 `/gate-check` 通过后、任何无障碍
> 审计之后，以及每当新游戏系统加入 `systems-index.md` 时。

---

## Accessibility Tier Definition
## 无障碍层级定义

[To be designed]
[待设计]

### Tier Definitions
### 层级定义

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Critical player-facing text is readable at standard resolution. No feature requires color discrimination alone. Volume controls exist for music, SFX, and voice independently. The game is completable without photosensitivity risk. | Low — primarily design constraints |
| **Standard** | All of Basic, plus: full input remapping on all platforms, subtitle support with speaker identification, adjustable text size, at least one colorblind mode, and no timed input that cannot be extended or toggled. | Medium — requires dedicated implementation work |
| **Comprehensive** | All of Standard, plus: screen reader support for menus, mono audio option, difficulty assist modes, HUD element repositioning, reduced motion mode, and visual indicators for all gameplay-critical audio. | High — requires platform API integration and significant UI architecture |
| **Exemplary** | All of Comprehensive, plus: full subtitle customization (font, size, color, background, position), high contrast mode, cognitive load assist tools, tactile/haptic alternatives for all audio-only cues, and external third-party accessibility audit. | Very High — requires dedicated accessibility budget and specialist consultation |

| 层级 | 核心承诺 | 典型工作量 |
|------|----------------|----------------|
| **Basic（基础）** | 关键玩家可见文本在标准分辨率下可读。没有任何功能仅依赖颜色辨别。音乐、音效和语音分别有独立音量控制。游戏可在无光敏性风险的情况下通关。 | 低 —— 主要是设计约束 |
| **Standard（标准）** | 包含 Basic 全部内容，另加：所有平台的完整输入重映射、带说话人识别的字幕支持、可调文本大小、至少一种色盲模式，以及所有无法延长或切换的限时输入。 | 中 —— 需要专门的实现工作 |
| **Comprehensive（全面）** | 包含 Standard 全部内容，另加：菜单的屏幕阅读器支持、单声道音频选项、难度辅助模式、HUD 元素重定位、减少动态效果模式，以及所有对玩法关键的音频的视觉指示。 | 高 —— 需要平台 API 集成和大量 UI 架构工作 |
| **Exemplary（典范）** | 包含 Comprehensive 全部内容，另加：完整字幕自定义（字体、大小、颜色、背景、位置）、高对比度模式、认知负荷辅助工具、所有仅音频提示的触觉/震动替代方案，以及外部第三方无障碍审计。 | 极高 —— 需要专门的无障碍预算和专家咨询 |

### This Project's Commitment
### 本项目的承诺

**Target Tier**: [Basic / Standard / Comprehensive / Exemplary]
**目标层级**：[Basic / Standard / Comprehensive / Exemplary]

**Rationale**: [3-5 sentences justifying the tier choice — genre barriers, target audience, platform requirements, team capacity, cost of dropping a tier. See guide for the reasoning checklist and a worked example.]
**理由**：[3-5 句说明层级选择的依据 —— 类型障碍、目标受众、平台要求、团队能力、降低一个层级的代价。推理检查清单和完整示例见指南。]

**Features explicitly in scope (beyond tier baseline)**:
- [Feature elevated above the tier baseline + why]
**明确纳入范围的功能（超出层级基线）**：
- [高于层级基线的功能 + 原因]

**Features explicitly out of scope**:
- [Feature excluded + why — must also appear in Known Intentional Limitations]
**明确排除在外的功能**：
- [排除的功能 + 原因 —— 也必须出现在“已知有意限制”中]

---

## Visual Accessibility
## 视觉无障碍

[To be designed]
[待设计]

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Minimum text size — menu UI | Standard | All menu screens | Not Started | 24px minimum at 1080p. At 4K, scale proportionally. Reference: WCAG 2.1 SC 1.4.4 requires text resizable to 200% without loss of content. |
| Minimum text size — subtitles | Standard | All voiced/captioned content | Not Started | 32px minimum at 1080p. Players viewing on TV at 3m are the constraint. |
| Minimum text size — HUD | Standard | In-game HUD | Not Started | 20px minimum for critical information (health, ammo, objective). Non-critical HUD elements may be smaller. |
| Text contrast — UI text on backgrounds | Standard | All UI text | Not Started | Minimum 4.5:1 ratio for body text (WCAG AA). 3:1 for large text (18px+ or 14px bold). Test with automated contrast checker on final color values. |
| Text contrast — subtitles | Standard | Subtitle display | Not Started | Minimum 7:1 ratio (WCAG AAA) for subtitles — players read them quickly and cannot control background. Use drop shadow or opaque background box by default. |
| Colorblind mode — Protanopia | Standard | All color-coded gameplay | Not Started | Red-green — affects ~6% of men. Primary concern: health bars, enemy indicators, map markers. Shift red signals to orange/yellow; shift green signals to teal. |
| Colorblind mode — Deuteranopia | Standard | All color-coded gameplay | Not Started | Green-red — affects ~1% of men. Similar to Protanopia in practical impact. Often the same palette adjustment covers both. Verify with Coblis or Colour Blindness Simulator. |
| Colorblind mode — Tritanopia | Standard | All color-coded gameplay | Not Started | Blue-yellow — rarer (~0.001%). Shift blue UI elements to purple; shift yellow to orange. |
| Color-as-only-indicator audit | Basic | All UI and gameplay | Not Started | List every place color is the SOLE differentiator in the table below. Each must have a non-color backup (icon, shape, pattern, text label) before shipping. |
| UI scaling | Standard | All UI elements | Not Started | Range: 75% to 150%. Default: 100%. Scaling must not break layout — test all screens at min and max. HUD scaling should be independent from menu scaling. |
| High contrast mode | Comprehensive | Menus (minimum); HUD (preferred) | Not Started | Replace all semi-transparent backgrounds with fully opaque. Replace mid-tone UI colors with black/white/system-high-contrast colors. All interactive elements outlined. |
| Brightness/gamma controls | Basic | Global | Not Started | Exposed in graphics settings. Include a reference calibration image (a gradient or symbol barely visible at correct calibration). Range: -50% to +50% from default. |
| Screen flash / strobe warning | Basic | All cutscenes, VFX | Not Started | (1) Pre-launch warning screen with photosensitivity seizure notice. (2) Audit all flash-heavy VFX against Harding FPA standard (no more than 3 flashes per second above luminance threshold). (3) Optional: flash reduction mode that lowers flash amplitude by 80%. |
| Motion/animation reduction mode | Standard | All UI transitions, camera shake, VFX | Not Started | Reduce or eliminate: screen shake, camera bob, motion blur, parallax scrolling in menus, looping background animations. Cannot fully eliminate: player movement animation (would break readability). Toggle in accessibility settings. |
| Subtitles — on/off | Basic | All voiced content | Not Started | Default: OFF (industry standard — many players prefer immersion). Prominently offered at first launch. |
| Subtitles — speaker identification | Standard | All voiced content | Not Started | Speaker name displayed before dialogue line. Color-coded by speaker IF colors differ by more than hue alone (test for colorblind compatibility). |
| Subtitles — style customization | Comprehensive | Subtitle display | Not Started | Font size (4 sizes minimum), background opacity (0–100%), text color (white / yellow / custom), position (bottom / top / player-relative). |
| Subtitles — sound effect captions | Comprehensive | Gameplay-critical SFX | Not Started | See Auditory Accessibility section for which SFX qualify. Format: [SOUND DESCRIPTION] in brackets, distinct from dialogue. |

| 功能 | 目标层级 | 范围 | 状态 | 实现备注 |
|---------|-------------|-------|--------|---------------------|
| 最小文本尺寸 —— 菜单 UI | Standard | 所有菜单界面 | 未开始 | 1080p 下最小 24px。4K 下按比例缩放。参考：WCAG 2.1 SC 1.4.4 要求文本可放大至 200% 且内容不丢失。 |
| 最小文本尺寸 —— 字幕 | Standard | 所有配音/字幕内容 | 未开始 | 1080p 下最小 32px。以 3 米距离观看电视的玩家为约束条件。 |
| 最小文本尺寸 —— HUD | Standard | 游戏内 HUD | 未开始 | 关键信息（生命值、弹药、目标）最小 20px。非关键 HUD 元素可更小。 |
| 文本对比度 —— 背景上的 UI 文本 | Standard | 所有 UI 文本 | 未开始 | 正文最小对比度 4.5:1（WCAG AA）。大号文本（18px+ 或 14px 粗体）3:1。在最终颜色值上用自动对比度检查器测试。 |
| 文本对比度 —— 字幕 | Standard | 字幕显示 | 未开始 | 字幕最小对比度 7:1（WCAG AAA）—— 玩家阅读速度快且无法控制背景。默认使用投影或非透明背景框。 |
| 色盲模式 —— 红色盲 | Standard | 所有颜色编码玩法 | 未开始 | 红绿色盲 —— 影响约 6% 的男性。主要关注：血条、敌人指示、地图标记。将红色信号转为橙/黄色；将绿色信号转为青色。 |
| 色盲模式 —— 绿色盲 | Standard | 所有颜色编码玩法 | 未开始 | 绿红色盲 —— 影响约 1% 的男性。实际影响与红色盲类似。通常同一套调色调整可覆盖两者。用 Coblis 或色盲模拟器验证。 |
| 色盲模式 —— 蓝黄色盲 | Standard | 所有颜色编码玩法 | 未开始 | 蓝黄色盲 —— 更罕见（约 0.001%）。将蓝色 UI 元素转为紫色；将黄色转为橙色。 |
| 仅颜色指示审计 | Basic | 所有 UI 与玩法 | 未开始 | 在下表中列出所有仅以颜色作为唯一区分手段的地方。发布前每一项都必须有非颜色备份（图标、形状、图案、文本标签）。 |
| UI 缩放 | Standard | 所有 UI 元素 | 未开始 | 范围：75% 到 150%。默认：100%。缩放不得破坏布局 —— 在最小和最大设置下测试所有界面。HUD 缩放应独立于菜单缩放。 |
| 高对比度模式 | Comprehensive | 菜单（最低）；HUD（优先） | 未开始 | 将所有半透明背景替换为完全不透明。将中间色调 UI 颜色替换为黑/白/系统高对比色。所有交互元素加描边。 |
| 亮度/伽马控制 | Basic | 全局 | 未开始 | 在图形设置中提供。包含参考校准图像（在正确校准下仅勉强可见的渐变或符号）。范围：相对默认值 -50% 到 +50%。 |
| 屏幕闪光 / 频闪警告 | Basic | 所有过场动画、VFX | 未开始 | （1）启动前警告界面，含光敏性癫痫提示。（2）依据 Harding FPA 标准审计所有高频闪烁 VFX（亮度阈值以上每秒不超过 3 次闪烁）。（3）可选：闪光减弱模式，将闪光幅度降低 80%。 |
| 动态效果/动画减弱模式 | Standard | 所有 UI 转场、镜头震动、VFX | 未开始 | 减少或消除：屏幕震动、镜头摇晃、运动模糊、菜单视差滚动、循环背景动画。不能完全消除：玩家移动动画（会破坏可读性）。在无障碍设置中提供开关。 |
| 字幕 —— 开/关 | Basic | 所有配音内容 | 未开始 | 默认：关闭（行业标准 —— 许多玩家偏好沉浸感）。首次启动时突出提供。 |
| 字幕 —— 说话人识别 | Standard | 所有配音内容 | 未开始 | 说话人姓名显示在对话行之前。若各说话人颜色差异不止于色相，则按说话人着色（需测试色盲兼容性）。 |
| 字幕 —— 样式自定义 | Comprehensive | 字幕显示 | 未开始 | 字体大小（至少 4 档）、背景不透明度（0–100%）、文本颜色（白色 / 黄色 / 自定义）、位置（底部 / 顶部 / 相对玩家）。 |
| 字幕 —— 音效说明 | Comprehensive | 玩法关键音效 | 未开始 | 哪些音效符合条件见听觉无障碍章节。格式：方括号内的 [SOUND DESCRIPTION]（声音描述），与对话区分。 |

### Color-as-Only-Indicator Audit
### 仅颜色指示审计

> Fill in every gameplay or UI element where color is currently the sole
> differentiator. Resolve each before shipping. A resolved entry has a non-color
> backup that works in all three colorblind modes above. See guide for example rows.
> 填写所有当前仅以颜色作为唯一区分手段的玩法或 UI 元素。发布前逐一解决。
> 已解决的条目具有在以上三种色盲模式下均可用的非颜色
> 备份。示例行见指南。

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| [Add row for each color-coded element] | | | | |

| 位置 | 颜色信号 | 传达的信息 | 非颜色备份 | 状态 |
|----------|-------------|---------------------|-----------------|--------|
| [为每个颜色编码元素添加一行] | | | | |

---

## Motor Accessibility
## 运动无障碍

[To be designed]
[待设计]

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Full input remapping | Standard | All gameplay inputs, all platforms | Not Started | Every input bound by default must be rebindable. Remapping applies to keyboard, mouse, controller, and any supported peripheral independently. No two actions may be bound to the same input simultaneously (warn on conflict). Persist remapping to player profile. |
| Input method switching | Standard | PC | Not Started | Player must be able to switch between keyboard/mouse and gamepad at any moment without restarting. UI must update prompts dynamically (show correct button icons for active input method). |
| One-hand mode | [Tier] | [Identify which features require two simultaneous hands] | Not Started | Audit every multi-input action. For each: can it be executed with a single hand? If not, provide a toggle alternative or hold-to-toggle version. Specify here which features have a one-hand path and which do not. |
| Hold-to-press alternatives | Standard | All hold inputs | Not Started | Every "hold [button] to [action]" must offer a toggle alternative. Toggle mode: first press activates, second press deactivates. Example: "Hold to sprint" becomes optional "toggle sprint" mode. List all hold inputs in the game here. |
| Rapid input alternatives | Standard | Any button mashing / rapid input sequences | Not Started | Any input requiring more than 3 presses per second sustained must offer a single-press toggle alternative. Example: Hades' "Hold to dash repeatedly" solves this elegantly. |
| Input timing adjustments | Standard | QTEs, timed button presses, rhythm inputs | Not Started | Provide a timing window multiplier in accessibility settings. Minimum range: 0.5x to 3.0x. Default: 1.0x. At 3.0x, a 500ms window becomes 1500ms. Document every timed input in this game and test at all multiplier values. |
| Aim assist | Standard | All ranged combat / targeting | Not Started | Not just on/off — provide granularity: Assist Strength (0–100%), Assist Radius, Aim Magnetism (snap-to-target), and Aim Slowdown (near-target deceleration) as separate sliders. Default values should be tuned to feel helpful, not intrusive. |
| Auto-sprint / movement assists | Standard | Movement systems | Not Started | "Hold to sprint" toggle (covered above). Additionally: auto-run option (hold direction, player continues without input). Specify any movement input that is held continuously in normal gameplay. |
| Platforming / traversal assists | [Tier] | [If game has platforming] | Not Started | Evaluate whether auto-grab (generous ledge detection), coyote time extension, and jump height adjustment are appropriate for this game's design. If platforming is not a game system, mark N/A. |
| HUD element repositioning | Comprehensive | All HUD elements | Not Started | Allow players to move health bars, minimaps, and quest trackers to their preferred screen position. Particularly important for players using head-tracking or eye-gaze hardware who may have reduced peripheral vision coverage. |

| 功能 | 目标层级 | 范围 | 状态 | 实现备注 |
|---------|-------------|-------|--------|---------------------|
| 完整输入重映射 | Standard | 所有玩法输入、所有平台 | 未开始 | 默认绑定的每个输入都必须可重绑定。重映射独立适用于键盘、鼠标、控制器及任何支持的外设。不得同时将两个动作绑定到同一输入（冲突时警告）。重映射持久化到玩家配置。 |
| 输入方式切换 | Standard | PC | 未开始 | 玩家必须能在任意时刻在键盘/鼠标与手柄之间切换而无需重启。UI 必须动态更新提示（显示当前输入方式对应的正确按键图标）。 |
| 单手模式 | [Tier] | [识别哪些功能需要双手同时操作] | 未开始 | 审计每个多输入动作。对每一项：能否单手执行？若不能，提供切换替代方案或按住切换版本。在此注明哪些功能有单手路径，哪些没有。 |
| 按住操作替代方案 | Standard | 所有按住输入 | 未开始 | 每个“按住[按钮]以[动作]”都必须提供切换替代方案。切换模式：第一次按下激活，第二次按下停用。示例：“按住冲刺”变为可选的“切换冲刺”模式。在此列出游戏中所有按住输入。 |
| 快速连按替代方案 | Standard | 任何按键连打 / 快速输入序列 | 未开始 | 任何要求持续每秒超过 3 次按下的输入都必须提供单次按下切换替代方案。示例：《哈迪斯》的“按住以连续冲刺”优雅地解决了这一点。 |
| 输入时机调整 | Standard | QTE、限时按键、节奏输入 | 未开始 | 在无障碍设置中提供时间窗口倍率。最小范围：0.5x 到 3.0x。默认：1.0x。在 3.0x 下，500ms 窗口变为 1500ms。记录本游戏中每个限时输入，并在所有倍率值下测试。 |
| 瞄准辅助 | Standard | 所有远程战斗 / 目标选取 | 未开始 | 不只是开/关 —— 提供细分：辅助强度（0–100%）、辅助半径、瞄准磁性（吸附到目标）、瞄准减速（接近目标时减速）作为独立滑杆。默认值应调校为有帮助而不突兀。 |
| 自动冲刺 / 移动辅助 | Standard | 移动系统 | 未开始 | “按住冲刺”切换（见上文）。此外：自动奔跑选项（按住方向，玩家无需输入即持续移动）。注明正常玩法中任何需要持续按住的移动输入。 |
| 平台跳跃 / 位移辅助 | [Tier] | [若游戏有平台跳跃] | 未开始 | 评估自动抓取（宽松边缘检测）、土狼时间延长和跳跃高度调整是否适合本游戏设计。若平台跳跃不是游戏系统，标记 N/A。 |
| HUD 元素重定位 | Comprehensive | 所有 HUD 元素 | 未开始 | 允许玩家将血条、小地图和任务追踪器移动到偏好的屏幕位置。对使用头部追踪或眼动硬件、周边视野覆盖可能减弱的玩家尤为重要。 |

---

## Cognitive Accessibility
## 认知无障碍

[To be designed]
[待设计]

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Difficulty options | Standard | All gameplay difficulty parameters | Not Started | Separate granular sliders where possible (damage dealt, damage received, enemy aggression, enemy speed) rather than a single Easy/Normal/Hard label. Document which parameters are adjustable and which are fixed. Fixed parameters require a design justification. |
| Pause anywhere | Basic | All gameplay states | Not Started | Players must be able to pause during any gameplay state, including cutscenes, dialogue, and tutorial sequences. Document any state where pausing is currently prevented and the design justification for that restriction. Any restriction is a risk. |
| Tutorial persistence | Standard | All tutorials and help text | Not Started | After dismissing a tutorial prompt, the player must be able to retrieve it from a Help section in the menu. Do not rely on players absorbing tutorials on first encounter — AbleGamers research shows many players dismiss prompts on reflex. |
| Quest / objective clarity | Standard | Quest and objective systems | Not Started | The current active objective must be accessible within 2 button presses at all times during gameplay. Display the full objective text on demand, not just a truncated marker. Avoid objectives that require inference ("investigate the northern region" — where exactly?). |
| Visual indicators for audio-only information | Standard | All SFX that carry gameplay information | Not Started | Audit every sound effect that communicates gameplay-critical state. For each: is there a visual equivalent? Directional audio (off-screen enemy) needs a screen-edge indicator. Critical warnings (boss phase transition, trap trigger) need visual cues. See Auditory Accessibility for full list. |
| Reading time for UI | Standard | All auto-dismissing dialogs | Not Started | No dialog, notification, or tooltip that contains actionable information may auto-dismiss in less than 5 seconds. Preferred: do not auto-dismiss at all — require player confirmation. Document every auto-dismissing element here and its current duration. |
| Cognitive load documentation | Comprehensive | Per game system | Not Started | For each system in systems-index.md, document the maximum number of things it asks the player to simultaneously track. Flag any system where the number exceeds 4. This is not a hard rule but a review trigger — high cognitive load systems need compensating UI clarity. See Per-Feature Accessibility Matrix below. |
| Navigation assists | Standard | World navigation | Not Started | Fast travel (to previously visited locations), waypoint system for current objective, optional objective indicator always visible. Document which of these apply to this game's design and which are intentionally omitted. |

| 功能 | 目标层级 | 范围 | 状态 | 实现备注 |
|---------|-------------|-------|--------|---------------------|
| 难度选项 | Standard | 所有玩法难度参数 | 未开始 | 尽可能使用独立的细分滑杆（造成伤害、承受伤害、敌人攻击性、敌人速度），而非单一“简单/普通/困难”标签。记录哪些参数可调、哪些固定。固定参数需要设计理由。 |
| 随处暂停 | Basic | 所有玩法状态 | 未开始 | 玩家必须能在任何玩法状态下暂停，包括过场动画、对话和教程序列。记录当前禁止暂停的任何状态及其设计理由。任何限制都是风险。 |
| 教程持久化 | Standard | 所有教程与帮助文本 | 未开始 | 关闭教程提示后，玩家必须能从菜单的“帮助”章节重新调出它。不要指望玩家在首次遇到时就吸收教程 —— AbleGamers 研究显示许多玩家会条件反射地关闭提示。 |
| 任务 / 目标清晰度 | Standard | 任务与目标系统 | 未开始 | 游戏过程中当前活动目标必须始终能在 2 次按键内访问。按需显示完整目标文本，而不只是截断的标记。避免需要推断的目标（“调查北部地区” —— 具体在哪？）。 |
| 仅音频信息的视觉指示 | Standard | 所有承载玩法信息的音效 | 未开始 | 审计每个传达玩法关键状态的音效。对每一项：是否有视觉等效物？方向性音频（屏幕外敌人）需要屏幕边缘指示器。关键警告（Boss 阶段转换、陷阱触发）需要视觉提示。完整列表见听觉无障碍章节。 |
| UI 阅读时间 | Standard | 所有自动消失的对话框 | 未开始 | 任何含可操作信息的对话框、通知或提示框不得在少于 5 秒内自动消失。首选：完全不自动消失 —— 要求玩家确认。在此记录每个自动消失元素及其当前时长。 |
| 认知负荷记录 | Comprehensive | 按游戏系统 | 未开始 | 对 systems-index.md 中的每个系统，记录它要求玩家同时跟踪的最大事项数。标记任何超过 4 的系统。这不是硬性规则而是评审触发条件 —— 高认知负荷系统需要补偿性的 UI 清晰度。见下方“按功能无障碍矩阵”。 |
| 导航辅助 | Standard | 世界导航 | 未开始 | 快速旅行（前往已访问过的地点）、当前目标的路点系统、可选的目标指示器始终可见。记录哪些适用于本游戏设计、哪些有意省略。 |

---

## Auditory Accessibility
## 听觉无障碍

[To be designed]
[待设计]

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Subtitles for all spoken dialogue | Basic | All voiced content | Not Started | 100% coverage — no exceptions. Include narration, in-engine dialogue, radio/environmental dialogue heard from a distance. Test subtitle sync against voice acting timing. |
| Closed captions for gameplay-critical SFX | Comprehensive | Identified SFX list (below) | Not Started | Not all SFX need captions — only those that communicate state the player cannot infer visually. See the SFX audit table below. |
| Mono audio option | Comprehensive | Global audio output | Not Started | Folds stereo/spatial audio to mono. Preserves volume balance between channels rather than summing to full volume on both sides. Essential for players with single-sided deafness. |
| Independent volume controls | Basic | Music / SFX / Voice / UI audio buses | Not Started | Four independent sliders minimum. Persist to player profile. Range: 0–100%, default 80%. Expose in both main settings and the pause menu. |
| Visual representations for directional audio | Comprehensive | All off-screen threats and audio events | Not Started | Screen-edge indicator pointing toward the audio source. Opacity scales with audio volume (closer = more opaque). Two variants: threat indicators (red) and information indicators (neutral). Example: The Last of Us Part II uses screen-edge indicators for off-screen enemy positions. |
| Hearing aid compatibility mode | Standard | High-frequency audio cues | Not Started | Audit all audio cues for frequency range. Any cue that communicates critical information only through high-frequency sound (above 4kHz) must have a low-frequency or visual equivalent. Hearing aids often filter high frequencies. |

| 功能 | 目标层级 | 范围 | 状态 | 实现备注 |
|---------|-------------|-------|--------|---------------------|
| 所有口语对话的字幕 | Basic | 所有配音内容 | 未开始 | 100% 覆盖 —— 无例外。包括旁白、引擎内对话、远处听到的无线电/环境对话。对照配音时间测试字幕同步。 |
| 玩法关键音效的隐藏字幕 | Comprehensive | 已识别的音效列表（见下方） | 未开始 | 并非所有音效都需要字幕 —— 只有那些传达玩家无法通过视觉推断的状态的音效才需要。见下方音效审计表。 |
| 单声道音频选项 | Comprehensive | 全局音频输出 | 未开始 | 将立体声/空间音频折叠为单声道。保留声道间的音量平衡，而不是把两侧都叠加到满音量。对单侧耳聋玩家至关重要。 |
| 独立音量控制 | Basic | 音乐 / 音效 / 语音 / UI 音频总线 | 未开始 | 至少四个独立滑杆。持久化到玩家配置。范围：0–100%，默认 80%。在主设置和暂停菜单中都提供。 |
| 方向性音频的视觉呈现 | Comprehensive | 所有屏幕外威胁与音频事件 | 未开始 | 屏幕边缘指示器指向声源。不透明度随音量变化（越近越不透明）。两种变体：威胁指示器（红色）与信息指示器（中性色）。示例：《最后生还者 第二部》用屏幕边缘指示器表示屏幕外敌人位置。 |
| 助听器兼容模式 | Standard | 高频音频提示 | 未开始 | 审计所有音频提示的频率范围。任何仅通过高频声音（4kHz 以上）传达关键信息的提示都必须有低频或视觉等效物。助听器常会滤除高频。 |

### Gameplay-Critical SFX Audit
### 玩法关键音效审计

> Identify every sound effect that communicates state the player needs to act on.
> Each entry in this table requires either a confirmed visual backup or a caption.
> See guide for example rows.
> 找出每个传达玩家需要据以行动的状态的音效。
> 本表中的每个条目都需要已确认的视觉备份或说明字幕。
> 示例行见指南。

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| [Add each SFX that changes what the player should do] | | | | |

| 音效 | 传达的信息 | 视觉备份 | 是否需要字幕 | 状态 |
|-------------|---------------------|--------------|-----------------|--------|
| [添加每个会改变玩家应做之事的音效] | | | | |

---

## Platform Accessibility API Integration
## 平台无障碍 API 集成

[To be designed]
[待设计]

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Xbox (GDK) | Xbox Game Core Accessibility / XAG | [Input remapping via Xbox Ease of Access, high contrast support, narrator integration for menus] | Not Started | XAG compliance is required for ID@Xbox Game Pass consideration. Review XAG checklist at https://docs.microsoft.com/gaming/accessibility/guidelines |
| PlayStation 5 | Sony Accessibility Guidelines / AccessibilityNode API | [Screen reader passthrough for menus, mono audio, high contrast] | Not Started | PS5 natively supports system-level audio description and mono audio if the game exposes AccessibilityNode data on UI elements. |
| Steam (PC) | Steam Accessibility Features / SDL | [Controller input remapping via Steam Input, subtitle support] | Not Started | Steam Input allows system-level remapping independent of in-game remapping. In-game remapping still required for keyboard/mouse. |
| iOS | UIAccessibility / VoiceOver | [VoiceOver support for menus if mobile port planned] | N/A | Only required if mobile release is in scope. |
| Android | AccessibilityService / TalkBack | [TalkBack support for menus if mobile port planned] | N/A | Only required if mobile release is in scope. |
| PC (Screen Reader) | JAWS / NVDA / Windows Narrator | [Menu navigation announcements] | Not Started | Requires UI elements to expose accessible names and roles via platform UI layer. Godot 4.5+ AccessKit integration covers this for supported control types. Verify against engine-reference/godot/ docs. |

| 平台 | API / 标准 | 计划的功能 | 状态 | 备注 |
|----------|---------------|-----------------|--------|-------|
| Xbox (GDK) | Xbox Game Core Accessibility / XAG | [通过 Xbox 轻松使用功能进行输入重映射、高对比度支持、菜单叙述器集成] | 未开始 | XAG 合规是进入 ID@Xbox Game Pass 考虑的必要条件。请查阅 XAG 检查清单：https://docs.microsoft.com/gaming/accessibility/guidelines |
| PlayStation 5 | 索尼无障碍指南 / AccessibilityNode API | [菜单的屏幕阅读器直通、单声道音频、高对比度] | 未开始 | 若游戏在 UI 元素上暴露 AccessibilityNode 数据，PS5 原生支持系统级音频描述和单声道音频。 |
| Steam (PC) | Steam 无障碍功能 / SDL | [通过 Steam Input 进行控制器输入重映射、字幕支持] | 未开始 | Steam Input 允许独立于游戏内重映射的系统级重映射。键盘/鼠标仍需要游戏内重映射。 |
| iOS | UIAccessibility / VoiceOver | [若计划移动端移植，菜单的 VoiceOver 支持] | N/A | 仅当移动端发布在范围内时需要。 |
| Android | AccessibilityService / TalkBack | [若计划移动端移植，菜单的 TalkBack 支持] | N/A | 仅当移动端发布在范围内时需要。 |
| PC（屏幕阅读器） | JAWS / NVDA / Windows 讲述人 | [菜单导航播报] | 未开始 | 需要 UI 元素通过平台 UI 层暴露无障碍名称和角色。Godot 4.5+ 的 AccessKit 集成可覆盖受支持的控件类型。对照 engine-reference/godot/ 文档验证。 |

---

## Per-Feature Accessibility Matrix
## 按功能无障碍矩阵

[To be designed]
[待设计]

> When a new system is added to systems-index.md, a row must be added here. If a
> system has an unaddressed accessibility concern, it cannot be marked Approved
> in the systems index. See guide for example rows.
> 当新系统加入 systems-index.md 时，必须在此添加一行。若某系统存在
> 未处理的无障碍问题，则不能在系统索引中标记为 Approved。
> 示例行见指南。

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [Add system from systems-index.md] | | | | | | |

| 系统 | 视觉问题 | 运动问题 | 认知问题 | 听觉问题 | 是否已处理 | 备注 |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [从 systems-index.md 添加系统] | | | | | | |

---

## Accessibility Test Plan
## 无障碍测试计划

[To be designed]
[待设计]

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Text contrast ratios | Automated — contrast analyzer tool on all UI screenshots | All text/background combinations at all game states | All body text ≥ 4.5:1; all large text ≥ 3:1; subtitle backgrounds ≥ 7:1 | ux-designer | Not Started |
| Colorblind modes | Manual — Coblis simulator on all game screenshots with modes enabled | Gameplay screenshots in exploration, combat, inventory in each mode | No essential information is lost in any mode; player can complete all objectives without color discrimination | ux-designer | Not Started |
| Input remapping | Manual — remap all inputs to non-default bindings, complete tutorial and first level | All default inputs rebound; gameplay functions correctly; no binding conflict possible | All actions accessible after remapping; conflict prevention works; bindings persist across restart | qa-tester | Not Started |
| Subtitle accuracy | Manual — verify against voice script, check all lines | All voiced content; subtitle timing; speaker identification | 100% of voiced lines subtitled; speaker identified for all multi-character scenes; no subtitle display for more than 3 seconds after line ends | qa-tester | Not Started |
| Hold input toggles | Manual — enable all toggle alternatives, complete all combat and traversal sequences | All hold inputs in toggle mode | All hold actions completable in toggle mode; no gameplay state requires sustained hold when toggle is enabled | qa-tester | Not Started |
| Reduced motion mode | Manual — enable mode, navigate all menus and complete first hour of gameplay | All menu transitions; all HUD animations; all camera shake events | No looping animations in menus; no camera shake above threshold; all screen transitions are cross-fade or cut | ux-designer | Not Started |
| Platform screen reader (menu) | Manual — enable OS screen reader, navigate all menus | Main menu, settings, pause menu, inventory, map | All interactive menu elements have screen reader announcements; navigation order is logical; no element unreachable by keyboard/D-pad | ux-designer | Not Started |
| User testing — colorblind | User testing with colorblind participants | Full game session with each colorblind mode | Participants complete all content without requesting color clarification; no session-stopping confusion | producer | Not Started |
| User testing — motor impairment | User testing with participants using one hand or adaptive controllers | Full game session with toggle and extended timing modes enabled | Participants complete all MVP content within tolerance of able-bodied completion time | producer | Not Started |

| 功能 | 测试方法 | 测试用例 | 通过标准 | 负责人 | 状态 |
|---------|------------|------------|--------------|-------------|--------|
| 文本对比度 | 自动 —— 对所有 UI 截图运行对比度分析工具 | 所有游戏状态下所有文本/背景组合 | 所有正文 ≥ 4.5:1；所有大号文本 ≥ 3:1；字幕背景 ≥ 7:1 | ux-designer | 未开始 |
| 色盲模式 | 手动 —— 在启用各模式下对所有游戏截图运行 Coblis 模拟器 | 每种模式下的探索、战斗、背包玩法截图 | 任何模式下均不丢失必要信息；玩家无需依赖颜色辨别即可完成所有目标 | ux-designer | 未开始 |
| 输入重映射 | 手动 —— 将所有输入重映射为非默认绑定，完成教程与第一关 | 所有默认输入重绑定；玩法功能正常；不可能出现绑定冲突 | 重映射后所有动作可访问；冲突预防有效；绑定在重启后保留 | qa-tester | 未开始 |
| 字幕准确性 | 手动 —— 对照配音脚本核验，检查所有行 | 所有配音内容；字幕时间；说话人识别 | 100% 配音行有字幕；所有多角色场景均标识说话人；对话结束后字幕显示不超过 3 秒 | qa-tester | 未开始 |
| 按住输入切换 | 手动 —— 启用所有切换替代方案，完成所有战斗与位移序列 | 所有按住输入以切换模式运行 | 所有按住动作在切换模式下可完成；启用切换时没有玩法状态需要持续按住 | qa-tester | 未开始 |
| 减少动态效果模式 | 手动 —— 启用该模式，浏览所有菜单并完成游戏第一小时 | 所有菜单转场；所有 HUD 动画；所有镜头震动事件 | 菜单中无循环动画；无超过阈值的镜头震动；所有界面转场均为交叉淡入或硬切 | ux-designer | 未开始 |
| 平台屏幕阅读器（菜单） | 手动 —— 启用操作系统屏幕阅读器，浏览所有菜单 | 主菜单、设置、暂停菜单、背包、地图 | 所有可交互菜单元素均有屏幕阅读器播报；导航顺序合乎逻辑；没有元素无法通过键盘/方向键访问 | ux-designer | 未开始 |
| 用户测试 —— 色盲 | 与色盲参与者进行用户测试 | 在每种色盲模式下进行完整游戏会话 | 参与者在未要求颜色澄清的情况下完成所有内容；没有令会话中断的困惑 | producer | 未开始 |
| 用户测试 —— 运动障碍 | 与使用单手或自适应控制器的参与者进行用户测试 | 在启用切换与延长时机模式下进行完整游戏会话 | 参与者完成的全部 MVP 内容在健全玩家完成时间的容差范围内 | producer | 未开始 |

---

## Known Intentional Limitations
## 已知有意限制

[To be designed]
[待设计]

> Every entry here is a risk — assess it honestly. See guide for example rows.
> 此处的每一条都是风险 —— 请诚实评估。示例行见指南。

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| [Add any intentionally excluded accessibility feature] | | | | |

| 功能 | 所需层级 | 未纳入的原因 | 风险 / 影响 | 缓解措施 |
|---------|--------------|-----------------|--------------|------------|
| [添加任何有意排除的无障碍功能] | | | | |

---

## Audit History
## 审计历史

[To be designed]
[待设计]

> See guide for example rows.
> 示例行见指南。

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Add row for each audit] | | | | | |

| 日期 | 审计者 | 类型 | 范围 | 发现摘要 | 状态 |
|------|---------|------|-------|-----------------|--------|
| [为每次审计添加一行] | | | | | |

---

## External Resources
## 外部资源

[To be designed]
[待设计]

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 (Web Content Accessibility Guidelines) | https://www.w3.org/TR/WCAG21/ | Foundational accessibility standard — contrast ratios, text sizing, input requirements |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Comprehensive game-specific checklist organized by category and cost |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | User testing service and consulting with disabled gamers |
| Xbox Accessibility Guidelines (XAG) | https://docs.microsoft.com/gaming/accessibility/guidelines | Required reading for Xbox certification; well-structured feature checklist |
| PlayStation Accessibility Guidelines | https://www.playstation.com/en-us/accessibility/ | Sony platform requirements; also contains well-written design guidance |
| Colour Blindness Simulator (Coblis) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Free tool for simulating colorblind modes on screenshots |
| Accessible Games Database | https://accessible.games | Research and examples of accessible game design decisions |
| CVAA (21st Century Communications and Video Accessibility Act) | https://www.fcc.gov/consumers/guides/21st-century-communications-and-video-accessibility-act-cvaa | US legal requirement for games with communication features (voice chat, messaging) |

| 资源 | URL | 相关性 |
|----------|-----|-----------|
| WCAG 2.1（Web 内容无障碍指南） | https://www.w3.org/TR/WCAG21/ | 基础性无障碍标准 —— 对比度、文本尺寸、输入要求 |
| Game Accessibility Guidelines（游戏无障碍指南） | https://gameaccessibilityguidelines.com | 按类别和成本组织的全面游戏专属检查清单 |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | 用户测试服务及与残障玩家的咨询 |
| Xbox 无障碍指南（XAG） | https://docs.microsoft.com/gaming/accessibility/guidelines | Xbox 认证的必读材料；结构良好的功能检查清单 |
| PlayStation 无障碍指南 | https://www.playstation.com/en-us/accessibility/ | 索尼平台要求；也包含写得很好的设计指导 |
| 色盲模拟器（Coblis） | https://www.color-blindness.com/coblis-color-blindness-simulator/ | 用于在截图上模拟色盲模式的免费工具 |
| Accessible Games Database（无障碍游戏数据库） | https://accessible.games | 无障碍游戏设计决策的研究与示例 |
| CVAA（21 世纪通信与视频无障碍法案） | https://www.fcc.gov/consumers/guides/21st-century-communications-and-video-accessibility-act-cvaa | 美国对含通信功能（语音聊天、消息）游戏的法律要求 |

---

## Open Questions
## 待决问题

[To be designed]
[待设计]

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |

| 问题 | 负责人 | 截止日期 | 解决方案 |
|----------|-------|----------|-----------|
| [添加问题] | [Owner] | [Deadline] | [Resolution] |
