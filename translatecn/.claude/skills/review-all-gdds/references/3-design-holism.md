# /review-all-gdds — Phase 3: Game Design Holism
# /review-all-gdds — 阶段 3：游戏设计整体性

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 3: Game Design Holism
## 阶段 3：游戏设计整体性

**In this file:**
**本文件内容：**

- 3a: Progression Loop Competition
- 3b: Player Attention Budget
- 3c: Dominant Strategy Detection
- 3d: Economic Loop Analysis
- 3e: Difficulty Curve Consistency
- 3f: Pillar Alignment
- 3g: Player Fantasy Coherence

- 3a：进阶循环竞争
- 3b：玩家注意力预算
- 3c：主导策略检测
- 3d：经济循环分析
- 3e：难度曲线一致性
- 3f：支柱对齐
- 3g：玩家幻想连贯性

Review all GDDs together through the lens of game design theory and player
psychology. These are issues that individual GDD reviews cannot catch because
they require seeing all systems at once.

以游戏设计理论与玩家心理学的视角，把所有 GDD 放在一起审查。这些问题是单个 GDD 审查无法
捕捉的，因为它们需要同时看到所有系统。

### 3a: Progression Loop Competition
### 3a：进阶循环竞争

A game should have one dominant progression loop that players feel is "the
point" of the game, with supporting loops that feed into it. When multiple
systems compete equally as the primary progression driver, players don't know
what the game is about.

一款游戏应当有一个主导的进阶循环，让玩家觉得那才是“游戏的意义”所在，并由若干辅助循环
为其输送。当多个系统同等地竞争“主要进阶驱动”的地位时，玩家会不知道这款游戏究竟讲的是
什么。

Scan all GDDs for systems that:
- Award the player's primary resource (XP, levels, prestige, unlocks)
- Define themselves as the "core" or "main" loop
- Have comparable depth and time investment to other systems doing the same

扫描所有 GDD，找出具备以下特征的系统：
- 给予玩家主要资源（经验值、等级、声望、解锁）
- 将自身定义为“核心”或“主要”循环
- 与其他做同样事情的系统具有相当的深度与时间投入

```
⚠️  Competing Progression Loops
combat.md: Awards XP, unlocks abilities, is described as "the core loop"
crafting.md: Awards XP, unlocks recipes, is described as "the primary activity"
exploration.md: Awards XP, unlocks map areas, described as "the main driver"
→ Three systems all claim to be the primary progression loop and all award
  the same primary currency. Players will optimise one and ignore the others.
  Consider: one primary loop with the others as support systems.
```

```
⚠️  竞争的进阶循环
combat.md：给予经验值、解锁能力，被描述为“核心循环”
crafting.md：给予经验值、解锁配方，被描述为“主要活动”
exploration.md：给予经验值、解锁地图区域，被描述为“主要驱动力”
→ 三个系统都声称自己是主要进阶循环，且都给予同一种主要货币。
  玩家会只优化其中一个而忽略其余。建议：保留一个主要循环，
  其余作为支撑系统。
```

### 3b: Player Attention Budget
### 3b：玩家注意力预算

Count how many systems require active player attention simultaneously during
a typical session. Each actively-managed system costs attention:

统计在一次典型游玩过程中，有多少系统同时需要玩家主动投入注意力。每一个需要主动管理的
系统都会消耗注意力：

- Active = player must make decisions about this system regularly during play
- Passive = system runs automatically, player sees results but doesn't manage it

- 主动 = 玩家必须在游玩过程中经常就该系统做出决策
- 被动 = 系统自动运行，玩家能看到结果但不加以管理

More than 3-4 simultaneously active systems creates cognitive overload for most
players. Present the count and flag if it exceeds 4 concurrent active systems:

同时处于主动状态的系统超过 3-4 个，会让大多数玩家产生认知过载。展示计数结果，并在同时
主动系统超过 4 个时标记：

```
⚠️  Cognitive Load Risk
Simultaneously active systems during [core loop moment]:
  1. [system-a].md — [decision type] (active)
  2. [system-b].md — [resource management] (active)
  3. [system-c].md — [tracking] (active)
  4. [system-d].md — [item/action use] (active)
  5. [system-e].md — [cooldown/timer management] (active)
  6. [system-f].md — [coordination decisions] (active)
→ 6 simultaneously active systems during the core loop.
  Research suggests 3-4 is the comfortable limit for most players.
  Consider: which of these can be made passive or simplified?
```

```
⚠️  认知负荷风险
[core loop moment] 期间同时处于主动状态的系统：
  1. [system-a].md —— [决策类型]（主动）
  2. [system-b].md —— [资源管理]（主动）
  3. [system-c].md —— [追踪]（主动）
  4. [system-d].md —— [物品/动作使用]（主动）
  5. [system-e].md —— [冷却/计时器管理]（主动）
  6. [system-f].md —— [协同决策]（主动）
→ 核心循环期间同时有 6 个主动系统。
  研究表明，对大多数玩家而言 3-4 个是舒适上限。
  建议：其中哪些可以改为被动或简化？
```

### 3c: Dominant Strategy Detection
### 3c：主导策略检测

A dominant strategy makes other strategies irrelevant — players discover it,
use it exclusively, and find the rest of the game boring. Look for:

主导策略会让其他策略变得无关紧要——玩家一旦发现它，就只会专用它，并觉得游戏其余部分
乏味。需要留意：

- **Resource monopolies**: One strategy generates a resource significantly
  faster than all others
- **Risk-free power**: A strategy that is both high-reward and low-risk
  (if high-risk strategies exist, they need proportionally higher reward)
- **No trade-offs**: An option that is superior in all dimensions to all others
- **Obvious optimal path**: If any progression choice is "clearly correct",
  the others aren't real choices

- **资源垄断**：某一策略产生某种资源的速度显著快于其他所有策略
- **无风险收益**：一种既高回报又低风险的策略
  （若存在高风险策略，它们需要相应更高的回报）
- **无取舍**：某个选项在所有维度上都优于其他所有选项
- **显而易见的正解路径**：如果任何进阶选择都“明显正确”，
  其他选择就不是真正的选择

```
⚠️  Potential Dominant Strategy
combat.md: Ranged attacks deal 80% of melee damage with no risk
combat.md: Melee attacks deal 100% damage but require close range
→ Unless melee has a significant compensating advantage (AOE, stagger,
  resource regeneration), ranged is dominant — higher safety, only 20% less
  damage. Consider what melee offers that ranged cannot.
```

```
⚠️  潜在的主导策略
combat.md：远程攻击造成近战伤害的 80%，且没有风险
combat.md：近战攻击造成 100% 伤害，但需要贴近距离
→ 除非近战拥有显著的补偿性优势（范围伤害、硬直、
  资源回复），否则远程就是主导策略——更安全，伤害仅低 20%。
  请考虑近战能提供哪些远程无法提供的东西。
```

### 3d: Economic Loop Analysis
### 3d：经济循环分析

Identify all resources across all GDDs (gold, XP, crafting materials, stamina,
health, mana, etc.). For each resource, map its **sources** (how players gain
it) and **sinks** (how players spend it).

识别所有 GDD 中的所有资源（金币、经验值、制作材料、耐力、生命值、法力等）。对每种资源，
梳理其**来源**（玩家如何获得）与**消耗口**（玩家如何花掉它）。

Flag dangerous economic conditions:

标记危险的经济状况：

| Condition | Sign | Risk |
|-----------|------|------|
| **Infinite source, no sink** | Resource accumulates indefinitely | Late game becomes trivially easy |
| **Sink, no source** | Resource drains to zero | System becomes unavailable |
| **Source >> Sink** | Surplus accumulates | Resource becomes meaningless |
| **Sink >> Source** | Constant scarcity | Frustration and gatekeeping |
| **Positive feedback loop** | More resource → easier to earn more | Runaway leader, snowball |
| **No catch-up** | Falling behind accelerates deficit | Unrecoverable states |

| 状况 | 迹象 | 风险 |
|-----------|------|------|
| **来源无限、无消耗口** | 资源无限累积 | 游戏后期变得毫无难度 |
| **有消耗口、无来源** | 资源耗尽至零 | 系统变得不可用 |
| **来源 >> 消耗口** | 盈余不断累积 | 资源失去意义 |
| **消耗口 >> 来源** | 持续稀缺 | 挫败感与进度卡关 |
| **正反馈循环** | 资源越多 → 越容易获取更多 | 强者愈强、滚雪球 |
| **无追赶机制** | 落后会加速差距扩大 | 无法挽回的状态 |

```
🔴 Economic Imbalance: Unbounded Positive Feedback
gold economy:
  Sources: monster drops (scales with player power), merchant selling (unlimited)
  Sinks: equipment purchase (one-time), ability upgrades (finite count)
→ After equipment and abilities are purchased, gold has no sink.
  Infinite surplus. Gold becomes meaningless mid-game.
  Add ongoing gold sinks (upkeep, consumables, cosmetics, gambling).
```

```
🔴 经济失衡：无上限的正反馈
金币经济：
  来源：怪物掉落（随玩家强度缩放）、向商人出售（无上限）
  消耗口：购买装备（一次性）、能力升级（数量有限）
→ 装备和能力买齐之后，金币就没有消耗口了。
  盈余无限。金币在游戏中期失去意义。
  请加入持续性金币消耗口（维护费、消耗品、外观、博彩）。
```

### 3e: Difficulty Curve Consistency
### 3e：难度曲线一致性

When multiple systems scale with player progression, they must scale in
compatible directions and at compatible rates. Mismatched scaling curves
create unintended difficulty spikes or trivialisations.

当多个系统随玩家进度成长时，它们的成长方向与速率必须相互兼容。不匹配的成长曲线会造成
意料之外的难度尖峰或难度被抹平。

For each system that scales over time, extract:
- What scales (enemy health, player damage, resource cost, area size)
- How it scales (linear, exponential, stepped)
- When it scales (level, time, area)

对每个随时间成长的系统，提取：
- 成长的是什么（敌人生命值、玩家伤害、资源消耗、区域大小）
- 如何成长（线性、指数、阶梯式）
- 何时成长（等级、时间、区域）

Compare all scaling curves. Flag mismatches:

比较所有成长曲线。标记不匹配之处：

```
⚠️  Difficulty Curve Mismatch
combat.md: Enemy health scales exponentially with area (×2 per area)
progression.md: Player damage scales linearly with level (+10% per level)
→ By area 5, enemies have 32× base health; player deals ~1.5× base damage.
  The gap widens indefinitely. Late areas will become inaccessibly difficult
  unless the curves are reconciled.
```

```
⚠️  难度曲线不匹配
combat.md：敌人生命值随区域指数成长（每区域 ×2）
progression.md：玩家伤害随等级线性成长（每等级 +10%）
→ 到第 5 个区域时，敌人生命值为基础值的 32 倍；玩家伤害约为基础值的 1.5 倍。
  差距会不断拉大。若不调和这两条曲线，后期区域将变得难到无法进入。
```

### 3f: Pillar Alignment
### 3f：支柱对齐

Every system should clearly serve at least one design pillar. A system that
serves no pillar is "scope creep by design" — it's in the game but not in
service of what the game is trying to be.

每个系统都应明确服务于至少一个设计支柱。不服务任何支柱的系统是“设计层面的范围蔓延”——
它存在于游戏中，却不服务于游戏想要成为的东西。

For each GDD system, check its Player Fantasy section against the design pillars.
Flag any system whose stated fantasy doesn't map to any pillar:

对每个 GDD 系统，检查其 Player Fantasy 分区是否与设计支柱契合。标记所声明的幻想无法
映射到任何支柱的系统：

```
⚠️  Pillar Drift
fishing-system.md: Player Fantasy — "peaceful, meditative activity"
Pillars: "Brutal Combat", "Tense Survival", "Emergent Stories"
→ The fishing system serves none of the three pillars. Either add a pillar
  that covers it, redesign it to serve an existing pillar, or cut it.
```

```
⚠️  支柱漂移
fishing-system.md：Player Fantasy —— “平和、冥想式的活动”
支柱：“残酷战斗”、“紧张生存”、“涌现式故事”
→ 钓鱼系统不服务于这三个支柱中的任何一个。要么新增一个覆盖它的支柱，
  要么重新设计使其服务于现有支柱，要么砍掉它。
```

Also check anti-pillars — flag any system that does what an anti-pillar
explicitly says the game will NOT do:

还要检查反支柱——标记任何做出反支柱明确表示游戏**不会**做的事情的系统：

```
🔴 Anti-Pillar Violation
Anti-Pillar: "We will NOT have linear story progression — player defines their path"
main-quest.md: Defines a 12-chapter linear story with mandatory sequence
→ This system directly violates the defined anti-pillar.
```

```
🔴 反支柱违背
反支柱：“我们**不会**采用线性剧情推进——玩家自行定义其路径”
main-quest.md：定义了一个 12 章、必须按序推进的线性剧情
→ 该系统直接违背了已定义的反支柱。
```

### 3g: Player Fantasy Coherence
### 3g：玩家幻想连贯性

The player fantasies across all systems should be compatible — they should
reinforce a consistent identity for what the player IS in this game. Conflicting
player fantasies create identity confusion.

所有系统中的玩家幻想应当彼此兼容——它们应强化玩家在这款游戏中“是什么”的一贯身份。
相互冲突的玩家幻想会造成身份混乱。

```
⚠️  Player Fantasy Conflict
combat.md: "You are a ruthless, precise warrior — every kill is earned"
dialogue.md: "You are a charismatic diplomat — violence is always avoidable"
exploration.md: "You are a reckless adventurer — diving in without a plan"
→ Three systems present incompatible identities. Players will feel the game
  doesn't know what it wants them to be. Consider: do these fantasies serve
  the same core identity from different angles, or do they genuinely conflict?
```

```
⚠️  玩家幻想冲突
combat.md：“你是一名冷酷而精准的战士——每一次击杀都是挣来的”
dialogue.md：“你是一名富有魅力的外交家——暴力总是可以避免的”
exploration.md：“你是一名鲁莽的冒险者——不制定计划就一头扎进去”
→ 三个系统呈现出彼此不兼容的身份。玩家会觉得游戏
  不知道自己想让他们成为什么。请考虑：这些幻想是从不同角度服务于
  同一个核心身份，还是确实彼此冲突？
```

---
