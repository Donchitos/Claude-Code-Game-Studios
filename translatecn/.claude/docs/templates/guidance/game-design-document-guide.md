> Authoring guidance for game-design-document.md. Load only the part covering the section currently being authored — not the whole file at once.
> game-design-document.md 的编写指南。只加载当前正在编写章节所对应的部分 — 不要一次读完整篇。

# Game Design Document Template — Authoring Guidance
# GDD 模板 — 编写指南

The template is the skeleton every GDD starts from: each section holds
`[To be designed]` until it is written, so a section still holding it reads as
not written yet. This guide says what goes in each section once it is written,
with the tables and columns to use. It is organised by the template's section
headings; when authoring a section, read only that section's guidance below.
模板是每份 GDD 的起点骨架：每个章节在写就之前都保留 `[To be designed]`，因此仍保留该标记的章节
就表示尚未编写。本指南说明每个章节写就后应包含什么，以及应使用的表格和列。
它按模板的章节标题组织；编写某章节时，只阅读下面该章节的指南。

---

## Header
## 头部

- **Status**: one of `In Design` (the skeleton's value), `Designed`,
  `In Review`, `Needs Revision`, `Approved`, `Implemented`.
- **Author**: the agent or person who wrote it.
- **Last Updated**: the date of the last edit.
- **Last Verified**: when this doc was last confirmed accurate against the
  current design.
- **Implements Pillar**: which game pillar this system supports.
- **状态**：以下之一 `In Design`（骨架默认值）、`Designed`、
  `In Review`、`Needs Revision`、`Approved`、`Implemented`。
- **作者**：编写它的智能体或人员。
- **最后更新**：最后一次编辑的日期。
- **最后验证**：本文档最后一次被确认与当前设计一致的时间。
- **实现支柱**：此系统支持哪个游戏支柱。

---

## Summary
## 摘要

2–3 sentences: what this system is, what it does for the player, and why it
exists in this game. Written for tiered context loading — a skill scanning
20 GDDs uses this section to decide whether to read further. No jargon.
2–3 句话：此系统是什么、它为玩家做什么，以及它为何存在于这款游戏中。为分层上下文加载而写 —
扫描 20 份 GDD 的技能会用此章节决定是否继续读取。不要使用术语。

Keep the **Quick reference** line under it, filled in: the system's layer, its
priority and its key dependencies.
保留其下方的**快速参考**行并填写：系统的层级、优先级及其关键依赖。

---

## Overview
## 概述

One paragraph that explains this mechanic to someone who knows nothing about
the project. What is it, what does the player do, and why does it exist?
用一段话向对项目一无所知的人解释此机制。它是什么、玩家做什么，以及它为何存在？

---

## Player Fantasy
## 玩家幻想

What should the player FEEL when engaging with this mechanic? What is the
emotional or power fantasy being served? This section guides all detail
decisions below.
玩家接触此机制时应该**感受**到什么？它服务于怎样的情感或力量幻想？此章节指导下面所有的细节决策。

---

## Detailed Design
## 详细设计

### Core Rules
### 核心规则

Precise, unambiguous rules. A programmer should be able to implement this
section without asking questions. Use numbered rules for sequential processes
and bullet points for properties.
精确、无歧义的规则。程序员应能在不提问的情况下实现此章节。对顺序流程使用编号规则，
对属性使用项目符号。

### States and Transitions
### 状态与转换

If this system has states (e.g., weapon states, status effects, phases),
document every state and every valid transition between states.
若此系统有状态（例如，武器状态、状态效果、阶段），记录每个状态以及状态之间每个有效转换。

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|

| 状态 | 进入条件 | 退出条件 | 行为 |
|-------|----------------|----------------|----------|

### Interactions with Other Systems
### 与其他系统的交互

How does this system interact with combat? Inventory? Progression? UI?
For each interaction, specify the interface: what data flows in, what flows
out, and who is responsible for what.
此系统如何与战斗交互？库存？进度？UI？对每种交互，规定接口：什么数据流入、什么数据流出，
以及各自负责什么。

---

## Formulas
## 公式

Every mathematical formula used by this system. For each formula:
此系统使用的每个数学公式。对每个公式：

### [Formula Name]
### [公式名称]

```
result = base_value * (1 + modifier_sum) * scaling_factor
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_value | float | 1-100 | data file | The base amount before modifiers |
| modifier_sum | float | -0.9 to 5.0 | calculated | Sum of all active modifiers |
| scaling_factor | float | 0.5-2.0 | data file | Level-based scaling |

| 变量 | 类型 | 范围 | 来源 | 描述 |
|----------|------|-------|--------|-------------|
| base_value | float | 1-100 | 数据文件 | 应用修正前的基础值 |
| modifier_sum | float | -0.9 to 5.0 | 计算所得 | 所有生效修正之和 |
| scaling_factor | float | 0.5-2.0 | 数据文件 | 基于等级的缩放 |

**Expected output range**: [min] to [max]
**Edge case**: When modifier_sum < -0.9, clamp to -0.9 to prevent negative results.
**预期输出范围**：[最小值] 至 [最大值]
**边界情况**：当 modifier_sum < -0.9 时，限制为 -0.9 以防止出现负结果。

---

## Edge Cases
## 边界情况

Explicitly document what happens in unusual situations. Each edge case
should have a clear resolution.
明确记录异常情况下会发生什么。每个边界情况都应有清晰的解决方式。

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| [What if X is zero?] | [This happens] | [Because of this reason] |
| [What if both effects trigger?] | [Priority rule] | [Design reasoning] |

| 场景 | 预期行为 | 依据 |
|----------|------------------|-----------|
| [如果 X 为零怎么办？] | [会发生这种情况] | [因为此原因] |
| [如果两个效果同时触发怎么办？] | [优先级规则] | [设计理由] |

---

## Dependencies
## 依赖

List every system this mechanic depends on or that depends on this mechanic.
列出此机制依赖的、或依赖此机制的每个系统。

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| [Combat] | This depends on Combat | Needs damage calculation results |
| [Inventory] | Inventory depends on this | Provides item effect data |

| 系统 | 方向 | 依赖性质 |
|--------|-----------|---------------------|
| [战斗] | 本系统依赖战斗 | 需要伤害计算结果 |
| [库存] | 库存依赖本系统 | 提供物品效果数据 |

---

## Tuning Knobs
## 调参旋钮

Every value that should be adjustable for balancing. Include the current
value, the safe range, and what happens at the extremes.
每个应为平衡而可调的数值。包含当前值、安全范围，以及极端情况下的表现。

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|

| 参数 | 当前值 | 安全范围 | 增加的效果 | 减少的效果 |
|-----------|--------------|------------|-------------------|-------------------|

---

## Visual/Audio Requirements
## 视觉/音频需求

What visual and audio feedback does this mechanic need?
此机制需要怎样的视觉与音频反馈？

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|

| 事件 | 视觉反馈 | 音频反馈 | 优先级 |
|-------|----------------|---------------|----------|

---

## Game Feel
## 游戏手感

> **Why this section exists separately from Visual/Audio Requirements**: Visual/Audio
> Requirements document WHAT feedback events occur (tables of events mapped to assets).
> Game Feel documents HOW the mechanic feels to operate — the responsiveness, weight,
> snap, and kinesthetic quality of the interaction. These are design targets for timing,
> frame data, and physical sensation of control. Game feel must be specified at design
> time because it drives animation budgets, input handling architecture, and hitbox
> timing. Retrofitting feel targets after implementation is expensive and often requires
> fundamental rework.
> **为何此章节独立于视觉/音频需求**：视觉/音频需求记录**发生什么**反馈事件（事件映射到资产的表格）。
> 游戏手感记录机制操作起来的**感受** — 响应性、重量感、干脆感，以及交互的动觉品质。
> 这些是时序、帧数据和操控体感的设计目标。游戏手感必须在设计阶段规定，因为它驱动动画预算、
> 输入处理架构和碰撞盒时序。实现之后再补手感目标代价高昂，且往往需要根本性返工。

Write the section with these six parts.
用以下六个部分来编写此章节。

### Feel Reference
### 手感参考

Name a specific game, mechanic, or moment that captures the target feel. Be precise —
cite the exact mechanic, not just the game. Explain what quality you are borrowing.
Optionally include an anti-reference (what this should NOT feel like).
指出一个能捕捉目标手感的具体游戏、机制或时刻。要精确 — 引用确切机制，而不只是游戏名。
解释你借鉴的是什么品质。可选：加入一个反例参考（它**不应**感觉像什么）。

> Example: "Should feel like Dark Souls weapon swings — weighty, committed, and
> telegraphed, but satisfying on contact. NOT floaty like early Halo melee."
> 示例：“应感觉像 Dark Souls 的武器挥砍 — 有重量感、有承诺感、有预告性，但接触时令人满足。
> **不要**像早期 Halo 近战那样飘。”

### Input Responsiveness
### 输入响应性

Maximum acceptable latency from player input to visible/audible response, per action.
每个动作从玩家输入到可见/可听响应的最大可接受延迟。

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|------------------------|-------|
| [Primary action] | [e.g., 50ms] | [e.g., 3 frames] | |
| [Secondary action] | | | |

| 动作 | 最大输入到响应延迟（毫秒） | 帧预算（60fps 下） | 备注 |
|--------|-----------------------------------|------------------------|-------|
| [主要动作] | [例如，50 毫秒] | [例如，3 帧] | |
| [次要动作] | | | |

### Animation Feel Targets
### 动画手感目标

Frame data targets for each animation in this mechanic. Startup = windup before the
action has any effect. Active = frames when the action is "happening" (hitbox live,
ability firing, etc.). Recovery = committed/vulnerable frames after the action resolves.
此机制中每个动画的帧数据目标。起手 = 动作产生任何效果之前的预备。
生效 = 动作“正在发生”的帧（碰撞盒激活、技能发射等）。收招 = 动作结算后不可取消/易受攻击的帧。

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| [e.g., Light attack] | | | | [e.g., Snappy, low commitment] | |
| [e.g., Heavy attack] | | | | [e.g., Weighty, high commitment] | |

| 动画 | 起手帧 | 生效帧 | 收招帧 | 手感目标 | 备注 |
|-----------|---------------|--------------|----------------|-----------|-------|
| [例如，轻攻击] | | | | [例如，干脆、承诺低] | |
| [例如，重攻击] | | | | [例如，沉重、承诺高] | |

### Impact Moments
### 冲击时刻

Defines the punctuation of the mechanic — the moments of peak feedback intensity that
make actions feel consequential. Every high-stakes event should have at least one entry.
定义机制的标点 — 使动作感觉有分量的反馈强度峰值时刻。每个高风险事件都应至少有一条记录。

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Hit-stop (freeze frames) | [e.g., 80ms] | [Freeze both objects on contact] | Yes |
| Screen shake | [e.g., 150ms] | [Directional, decaying] | Yes |
| Camera impact | | | |
| Controller rumble | | | |
| Time-scale slowdown | | | |

| 冲击类型 | 持续时间（毫秒） | 效果描述 | 可配置？ |
|-------------|--------------|-------------------|---------------|
| 命中停顿（冻结帧） | [例如，80 毫秒] | [接触时冻结双方对象] | 是 |
| 屏幕震动 | [例如，150 毫秒] | [有方向、逐渐衰减] | 是 |
| 相机冲击 | | | |
| 手柄震动 | | | |
| 时间缩放慢动作 | | | |

### Weight and Responsiveness Profile
### 重量与响应性画像

A short prose description of the overall feel target. Answer the following:
对整体手感目标的简短文字描述。回答以下问题：

- **Weight**: Does this feel heavy and deliberate, or light and reactive?
- **Player control**: How much does the player feel in control at every moment?
  (High control = can course-correct mid-action; Low control = committed, momentum-based)
- **Snap quality**: Does this feel crisp and binary, or smooth and analog?
- **Acceleration model**: Does movement/action start instantly (arcade feel) or
  ramp up from zero (simulation feel)? Same question for deceleration.
- **Failure texture**: When the player makes an error, does the mechanic feel fair
  or punishing? What is the read on WHY they failed?
- **重量**：感觉沉重而刻意，还是轻快而反应灵敏？
- **玩家控制**：玩家在每个时刻感到多大程度的掌控？
  （高控制 = 可在动作中途纠正方向；低控制 = 有承诺感、基于动量）
- **干脆感**：感觉锐利且二元，还是平滑且模拟？
- **加速模型**：移动/动作是即时启动（街机感），还是从零逐渐加速（模拟感）？减速同理。
- **失败质感**：当玩家犯错时，机制感觉公平还是惩罚性？对他们**为何**失败的可读性如何？

### Feel Acceptance Criteria
### 手感验收标准

Specific, testable criteria a playtester can verify without measurement instruments.
These are subjective targets stated precisely enough to get consistent verdicts.
具体的、可测试的标准，游戏测试者无需测量仪器即可验证。这些是主观目标，但表述得足够精确，
以获得一致的判定。

- [ ] [e.g., "Combat feels impactful — playtesters comment on weight unprompted"]
- [ ] [e.g., "No reviewer uses the words 'floaty', 'slippery', or 'unresponsive'"]
- [ ] [e.g., "Input latency is imperceptible at target 60fps framerate"]
- [ ] [e.g., "Hit-stop reads as satisfying, not as lag or stutter"]
- [ ] [例如，“战斗感觉有冲击力 — 游戏测试者主动提及重量感”]
- [ ] [例如，“没有评审者使用‘飘’、‘打滑’或‘无响应’等词”]
- [ ] [例如，“在目标 60fps 帧率下输入延迟不可感知”]
- [ ] [例如，“命中停顿读起来令人满足，而非卡顿或迟滞”]

---

## UI Requirements
## UI 需求

What information needs to be displayed to the player and when?
需要向玩家显示什么信息，以及何时显示？

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|

| 信息 | 显示位置 | 更新频率 | 条件 |
|-------------|-----------------|-----------------|-----------|

---

## Cross-References
## 交叉引用

Declare every explicit dependency on another GDD's specific mechanic, value, or
rule. `/review-all-gdds` Phase 2c reads this table — it replaces implicit prose
references with verifiable declarations. If you reference another system's
behaviour anywhere in the document, it must appear here.
声明对另一份 GDD 的具体机制、数值或规则的每项显式依赖。`/review-all-gdds` 阶段 2c 会读取此表 —
它用可验证的声明替代隐含的文字引用。若你在文档任何位置引用了另一系统的行为，它必须出现在这里。

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| [e.g., "combo multiplier feeds score"] | `design/gdd/score.md` | `combo_multiplier` output value | Data dependency |
| [e.g., "death triggers respawn"] | `design/gdd/respawn.md` | Death state transition | State trigger |
| [e.g., "stamina gates dodge"] | `design/gdd/stamina.md` | Stamina depletion rule | Rule dependency |

| 本文档引用 | 目标 GDD | 引用的具体元素 | 性质 |
|--------------------------|-----------|----------------------------|--------|
| [例如，“连击倍率影响得分”] | `design/gdd/score.md` | `combo_multiplier` 输出值 | 数据依赖 |
| [例如，“死亡触发重生”] | `design/gdd/respawn.md` | 死亡状态转换 | 状态触发 |
| [例如，“耐力限制闪避”] | `design/gdd/stamina.md` | 耐力耗尽规则 | 规则依赖 |

> **Note on "Nature"**: use one of — `Data dependency` (we consume their output),
> `State trigger` (their state change triggers our behaviour), `Rule dependency`
> (our rule assumes their rule is also true), `Ownership handoff` (we hand off
> ownership of a value to them).
> **关于“性质”的说明**：使用以下之一 — `Data dependency`（我们消费其输出）、
> `State trigger`（其状态变化触发我们的行为）、`Rule dependency`
> （我们的规则假定其规则也为真）、`Ownership handoff`（我们将某个值的所有权移交给他们）。

---

## Acceptance Criteria
## 验收标准

Testable criteria that confirm this mechanic is working as designed.
确认此机制按设计运作的可测试标准。

- [ ] [Criterion 1: specific, measurable, testable]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] Performance: System update completes within [X]ms
- [ ] No hardcoded values in implementation
- [ ] [标准 1：具体、可测量、可测试]
- [ ] [标准 2]
- [ ] [标准 3]
- [ ] 性能：系统更新在 [X] 毫秒内完成
- [ ] 实现中没有硬编码值

---

## Open Questions
## 待决问题

Anything not yet decided. Each question should have an owner and deadline.
任何尚未决定的事项。每个问题都应有负责人和截止日期。

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|

| 问题 | 负责人 | 截止日期 | 解决方式 |
|----------|-------|----------|-----------|
