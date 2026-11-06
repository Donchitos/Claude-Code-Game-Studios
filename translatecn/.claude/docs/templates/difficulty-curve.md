# Difficulty Curve: [Game Title]
# 难度曲线：[游戏标题]

> **Status**: Draft | In Review | Approved
> **Author**: [game-designer / systems-designer]
> **Last Updated**: [Date]
> **Links To**: `design/gdd/game-concept.md` (or `design/game-brief.md`)
> **Relevant GDDs**: [e.g., `design/gdd/combat.md`, `design/gdd/progression.md`]
> **状态**：草稿 | 审核中 | 已批准
> **作者**：[game-designer / systems-designer]
> **最后更新**：[Date]
> **链接至**：`design/gdd/game-concept.md`（或 `design/game-brief.md`）
> **相关 GDD**：[例如 `design/gdd/combat.md`、`design/gdd/progression.md`]

---

## Difficulty Philosophy
## 难度哲学

[One paragraph establishing this game's relationship with difficulty. This is
not a mechanical description — it is a design value statement that all tuning
decisions must serve.

The four common difficulty philosophies are:

1. **Masochistic challenge as the core fantasy**: Difficulty is the product.
   Overcoming it is the emotional reward. Reducing difficulty removes the
   point. (Dark Souls, Celeste at max assist off)
2. **Accessible entry, optional depth**: The base experience is completable by
   most players; depth and challenge are opt-in for those who want them.
   (Hades, Hollow Knight with accessibility modes)
3. **Difficulty serves narrative pacing**: Challenge rises and falls to match
   story beats. The player must feel capable during story resolution and
   threatened during story crisis. (The Last of Us, God of War)
4. **Relaxed engagement**: Challenge is present but never the focus. Failure
   is gentle and infrequent. The experience prioritizes comfort and expression
   over obstacle. (Stardew Valley, Animal Crossing)

State the philosophy explicitly, then add one sentence on what the player is
permitted to feel: are they allowed to feel frustrated? For how long before the
design must intervene? What is the acceptable cost of failure?]
[一段确立此游戏与难度关系的文字。这不是
机制描述——而是一份设计价值声明，所有调校
决策都必须服务于它。

四种常见的难度哲学是：

1. **受虐式挑战作为核心幻想**：难度就是产品本身。
   克服它就是情感奖励。降低难度就消除了
   意义。（Dark Souls、关闭全部辅助的 Celeste）
2. **易入门，深度可选**：基础体验大多数玩家都能
   通关；深度和挑战供想要的人自行选择。
   （Hades、带无障碍模式的 Hollow Knight）
3. **难度服务于叙事节奏**：挑战随
   故事节拍起伏。玩家在故事收束时必须感到有能力，
   在故事危机时必须感到受威胁。（The Last of Us、God of War）
4. **轻松参与**：挑战存在但从不成为焦点。失败
   温和且不频繁。体验优先考虑舒适与表达，
   而非障碍。（Stardew Valley、Animal Crossing）

明确陈述该哲学，然后加一句话说明允许玩家
感受到什么：允许他们感到挫败吗？在设计必须介入之前
可以持续多久？可接受的失败代价是什么？]

---

## Difficulty Axes
## 难度轴

> **Guidance**: Most games have multiple independent dimensions of challenge.
> Identifying them explicitly prevents the mistake of tuning only one axis
> (usually execution difficulty) while leaving others unexamined. A game can
> feel "easy" on execution but overwhelming on decision complexity — players
> experience this as confusing, not engaging.
>
> For each axis, answer: can the player control or reduce this axis through
> choices, builds, or settings? If not, it is a forced challenge dimension —
> be very intentional about how it is used.
> **指导**：大多数游戏有多个独立的挑战维度。
> 明确识别它们可以避免只调校一个轴
> （通常是执行难度）而其他轴未被审视的错误。一款游戏
> 在执行上可能感觉"简单"，但在决策复杂度上令人不堪重负——玩家
> 会把这种体验感受为困惑，而非投入。
>
> 对每个轴回答：玩家能否通过选择、构筑或设置
> 控制或降低这个轴？如果不能，它就是一个强制的挑战维度——
> 要非常刻意地考虑如何使用它。

| Axis | Description | Primary Systems | Player Control? |
|------|-------------|----------------|-----------------|
| 轴 | 描述 | 主要系统 | 玩家可控？ |
|------|-------------|----------------|-----------------|
| **Execution difficulty** | [The precision and timing demands of core actions. e.g., "Dodging enemy attacks requires correct timing within a 200ms window."] | [e.g., Combat, movement] | [Yes — practice reduces this / No — fixed mechanical threshold] |
| **Knowledge difficulty** | [The cost of not knowing information. e.g., "Enemy weaknesses are not telegraphed; players who have not discovered them take significantly more damage."] | [e.g., Enemy design, UI, lore] | [Yes — through in-game discovery / No — requires external knowledge] |
| **Resource pressure** | [How scarce are the resources needed to progress? e.g., "Health consumables are limited; efficient play is required to sustain long dungeon runs."] | [e.g., Economy, loot, crafting] | [Yes — through build optimization / Partially] |
| **Time pressure** | [Does the player have time to think, or does the game demand rapid decisions? e.g., "Enemy spawn timers and attack windows require real-time response."] | [e.g., Combat pacing, timers] | [Yes — through difficulty settings / No — core to genre] |
| **Decision complexity** | [How many meaningful choices must the player evaluate simultaneously? e.g., "Build decisions interact across 4 systems; suboptimal combinations create compounding disadvantage."] | [e.g., Progression, inventory, skills] | [Yes — through UI and tutorialization / No — inherent to strategy depth] |
| **[Add axis]** | [Description] | [Systems] | [Player control] |
| **执行难度** | [核心动作对精度与时机的要求。例如"闪避敌人攻击需要在 200ms 窗口内把握正确时机。"] | [例如战斗、移动] | [是——练习可降低 / 否——固定机制阈值] |
| **知识难度** | [不知道信息的代价。例如"敌人弱点未被预告；未发现它们的玩家会承受显著更多伤害。"] | [例如敌人设计、UI、背景设定] | [是——通过游戏内发现 / 否——需要外部知识] |
| **资源压力** | [推进所需资源有多稀缺？例如"生命消耗品有限；需要高效游玩才能维持长时间地牢跑。" ] | [例如经济、战利品、制作] | [是——通过构筑优化 / 部分] |
| **时间压力** | [玩家有时间思考，还是游戏要求快速决策？例如"敌人刷新计时器和攻击窗口需要实时反应。" ] | [例如战斗节奏、计时器] | [是——通过难度设置 / 否——类型核心] |
| **决策复杂度** | [玩家必须同时评估多少个有意义的选择？例如"构筑决策在 4 个系统间交互；次优组合会造成累积劣势。" ] | [例如成长、物品栏、技能] | [是——通过 UI 和教程化 / 否——策略深度固有] |
| **[添加轴]** | [描述] | [系统] | [玩家控制] |

---

## Difficulty Curve Overview
## 难度曲线概览

> **Guidance**: This table describes the intended challenge arc across the whole
> game. Difficulty levels use a 1-10 scale where 1 = no meaningful challenge,
> 10 = maximum challenge the game can produce. The scale is relative to THIS game's
> design intent — a 6/10 in a soulslike is not the same as a 6/10 in a cozy sim.
>
> "Primary challenge type" refers to the difficulty axis (from the table above)
> that is doing the most work in this phase. New systems introduced should list
> only systems introduced for the FIRST TIME — the cognitive load of learning
> a new system is itself a form of difficulty.
>
> "Target player state" is the emotional state the designer intends. If the actual
> playtested state diverges from the intended state, this column is what needs
> to be achieved.
> **指导**：此表描述整款游戏的预期挑战弧线。难度级别
> 使用 1-10 刻度，其中 1 = 没有有意义的挑战，
> 10 = 游戏能产生的最大挑战。刻度相对于本游戏
> 的设计意图——soulslike 中的 6/10 与舒适模拟游戏中的 6/10 不同。
>
> "主要挑战类型"指在此阶段承担最多工作
> 的难度轴（来自上表）。新引入的系统应只列出
> 首次引入的系统——学习新系统的认知负荷本身
> 就是一种难度。
>
> "目标玩家状态"是设计者意图的情感状态。如果实际
> 试玩状态偏离意图状态，此列就是需要
> 达成的目标。

| Phase | Duration | Difficulty Level (1-10) | Primary Challenge Type | New Systems Introduced | Target Player State |
|-------|----------|------------------------|----------------------|----------------------|---------------------|
| 阶段 | 时长 | 难度级别（1-10） | 主要挑战类型 | 引入的新系统 | 目标玩家状态 |
|-------|----------|------------------------|----------------------|----------------------|---------------------|
| [Prologue / Tutorial] | [e.g., 0-15 min] | [2/10] | [Knowledge] | [Core movement, basic interaction] | [Safe, curious, building confidence] |
| [Early game] | [e.g., 15 min - 2 hrs] | [3-5/10] | [Execution] | [Combat, inventory, first upgrade path] | [Learning, occasional failure, clear cause-effect] |
| [Mid game - opening] | [e.g., 2-6 hrs] | [5-7/10] | [Decision complexity] | [Build choices, advanced enemies, crafting] | [Engaged, strategizing, feeling growth] |
| [Mid game - depth] | [e.g., 6-15 hrs] | [6-8/10] | [Resource pressure] | [Elite enemies, optional hard content, endgame previews] | [Challenged, invested, approaching mastery] |
| [Late game] | [e.g., 15-25 hrs] | [7-9/10] | [Execution + knowledge] | [Endgame systems, NG+ or equivalent] | [Mastery, confident in build identity, seeking peak challenge] |
| [Optional / Endgame] | [e.g., 25+ hrs] | [8-10/10] | [All axes combined] | [Mastery challenges, achievement targets] | [Expert play, self-imposed goals, community comparison] |
| [序章 / 教程] | [例如 0-15 分钟] | [2/10] | [知识] | [核心移动、基础交互] | [安全、好奇、建立信心] |
| [前期] | [例如 15 分钟 - 2 小时] | [3-5/10] | [执行] | [战斗、物品栏、首条升级路径] | [学习、偶有失败、因果清晰] |
| [中期 - 开启] | [例如 2-6 小时] | [5-7/10] | [决策复杂度] | [构筑选择、高级敌人、制作] | [投入、策略化、感受成长] |
| [中期 - 深入] | [例如 6-15 小时] | [6-8/10] | [资源压力] | [精英敌人、可选高难内容、终局预览] | [受到挑战、已投入、接近精通] |
| [后期] | [例如 15-25 小时] | [7-9/10] | [执行 + 知识] | [终局系统、NG+ 或等效内容] | [精通、对构筑身份有信心、寻求巅峰挑战] |
| [可选 / 终局] | [例如 25+ 小时] | [8-10/10] | [所有轴叠加] | [精通挑战、成就目标] | [专家级游玩、自设目标、社区比较] |

---

## Onboarding Ramp
## 新手引导坡道

> **Guidance**: The first hour deserves its own detailed breakdown because it
> does the most difficult design work: it must teach every foundational skill
> without feeling like a lesson, and it must create enough investment that the
> player commits to the journey ahead. Research on player retention shows that
> most players who leave a game do so in the first 30 minutes — not because
> the game is bad, but because onboarding failed to connect them.
>
> The scaffolding principle (Vygotsky's Zone of Proximal Development, adapted
> for game design): introduce each mechanic in isolation before combining it
> with others. A player cannot learn two skills simultaneously under pressure.
> **指导**：第一个小时值得单独详细分解，因为它
> 承担最难的设计工作：必须教会每一项基础技能
> 而不让人觉得在上课，并且必须创造足够的投入，使
> 玩家承诺踏上后续旅程。玩家留存研究表明，
> 大多数离开游戏的玩家是在前 30 分钟内离开的——不是因为
> 游戏不好，而是因为新手引导未能与他们建立连接。
>
> 脚手架原则（Vygotsky 的最近发展区，经改编
> 用于游戏设计）：在将每个机制与其他机制组合之前，先单独引入它。
> 玩家无法在压力下同时学习两项技能。

### What the Player Knows at Each Stage
### 玩家在每个阶段知道什么

| Time | What the Player Knows | What They Do Not Know Yet |
|------|-----------------------|--------------------------|
| 时间 | 玩家知道什么 | 他们尚不知道什么 |
|------|-----------------------|--------------------------|
| [0 min] | [Literally nothing — treat this row as your most important UX audit. What can a player infer from the title screen alone?] | [Everything] |
| [5 min] | [Core movement verb, basic world reading] | [All progression systems, all secondary mechanics] |
| [15 min] | [Core interaction loop, first goal] | [Build depth, advanced mechanics, danger severity] |
| [30 min] | [Has made at least one strategic choice] | [Whether that choice was optimal] |
| [60 min] | [Has a working model of the core loop] | [Late-game depth, optional systems] |
| [0 分钟] | [字面意义上的什么都没有——把这一行当作你最重要的 UX 审计。玩家仅凭标题画面能推断出什么？] | [一切] |
| [5 分钟] | [核心移动动词、基础世界阅读] | [所有成长系统、所有次要机制] |
| [15 分钟] | [核心交互循环、第一个目标] | [构筑深度、高级机制、危险的严重程度] |
| [30 分钟] | [至少做出过一个策略性选择] | [那个选择是否最优] |
| [60 分钟] | [拥有核心循环的可用心智模型] | [终局深度、可选系统] |

### Mechanic Introduction Sequence
### 机制引入顺序

> The order mechanics are introduced is a design decision with real consequences.
> Introduce the most essential verb first. Introduce mechanics that modify other
> mechanics AFTER the base mechanic is internalized. Never introduce two new
> mechanics in the same encounter.
> 机制引入的顺序是一个有真实后果的设计决策。
> 首先引入最本质的动词。在基础机制内化之后，
> 再引入修改其他机制的机制。绝不在同一遭遇中
> 引入两个新机制。

| Mechanic | Introduced At | Introduction Method | Stakes at Introduction |
|----------|--------------|--------------------|-----------------------|
| 机制 | 引入于 | 引入方法 | 引入时的风险 |
|----------|--------------|--------------------|-----------------------|
| [Core movement / primary verb] | [e.g., First 30 seconds] | [Tutorial prompt / environmental design / NPC instruction] | [None — safe space to experiment] |
| [Primary interaction / action] | [e.g., First 2 minutes] | [Method] | [Low — reversible, forgiving window] |
| [First resource mechanic] | [e.g., 5 min] | [Method] | [Low — abundant at introduction] |
| [First strategic choice] | [e.g., 15 min] | [Method] | [Low — choice can be changed or revisited] |
| [First real failure risk] | [e.g., 20-30 min] | [Method] | [Moderate — player should feel genuine threat but have fair tools to respond] |
| [Add mechanic] | [Timing] | [Method] | [Stakes] |
| [核心移动 / 主动词] | [例如前 30 秒] | [教程提示 / 环境设计 / NPC 指示] | [无——可安全实验的空间] |
| [主要交互 / 动作] | [例如前 2 分钟] | [方法] | [低——可逆、宽容的窗口] |
| [首个资源机制] | [例如 5 分钟] | [方法] | [低——引入时充足] |
| [首个策略性选择] | [例如 15 分钟] | [方法] | [低——选择可以更改或重访] |
| [首个真实失败风险] | [例如 20-30 分钟] | [方法] | [中等——玩家应感到真实威胁，但有公平的工具应对] |
| [添加机制] | [时机] | [方法] | [风险] |

### The First Failure
### 第一次失败

[Describe the intended design of the first moment the player can meaningfully
fail. This is one of the most important beats in the game.

A well-designed first failure teaches rather than punishes. The player should
be able to immediately identify what they did wrong and what they would do
differently. If the cause of failure is ambiguous, the player blames the game.

Answer: What causes the first failure? What does the player learn from it?
How quickly can they retry? What is the cost? Does the game provide any
feedback that bridges cause and effect?]
[描述玩家第一次可以有意义地失败的那一刻的预期设计。
这是游戏中最重要的节拍之一。

设计良好的第一次失败是教学而非惩罚。玩家应
能立即识别自己做错了什么，以及他们会如何
做得不同。如果失败原因含糊，玩家会责怪游戏。

回答：什么导致第一次失败？玩家从中学习什么？
他们能多快重试？代价是什么？游戏是否提供任何
连接因果的反馈？]

### When the Player First Feels Competent
### 玩家何时首次感到胜任

[Identify the specific moment — not a vague window, but a specific beat —
where the player should shift from "learning" to "doing." This is the moment
of first competence: the first time their prediction about the game comes true,
or the first time they execute a plan and it works.

This moment must happen within the first hour. If it does not, the player
will not reach Phase 3 of the journey (First Mastery). Design this moment
deliberately — do not leave it to chance.

What is the moment? What systems create it? What does the player do to
trigger it? How does the game communicate that they have succeeded?]
[识别具体时刻——不是模糊的窗口，而是具体的节拍——
玩家应从"学习"转向"行动"。这是首次胜任的时刻：
他们的预测第一次成真，或他们第一次执行计划并奏效。

这一刻必须在前一小时内发生。如果不发生，玩家
将不会到达旅程的第 3 阶段（首次精通）。刻意设计这一刻——
不要把它交给偶然。

这一刻是什么？哪些系统创造它？玩家做什么来
触发它？游戏如何传达他们已成功？]

---

## Difficulty Spikes and Valleys
## 难度尖峰与低谷

> **Guidance**: A healthy difficulty curve follows a sawtooth pattern
> (Csikszentmihalyi's flow model applied to macro-structure): tension builds
> through a sequence, then releases at a milestone, then re-engages at a
> slightly higher baseline. Flat difficulty creates boredom; uninterrupted
> escalation creates fatigue.
>
> Spikes are intentional peaks that test accumulated skills. Valleys are
> intentional troughs that give the player space to breathe, experiment, and
> feel powerful before the next escalation. Both are designed, not emergent.
>
> "Recovery design" is critical: what happens immediately after a spike? The
> player should exit a hard moment feeling accomplished, not depleted. Give
> them a valley, a reward, or a narrative payoff.
> **指导**：健康的难度曲线遵循锯齿模式
> （Csikszentmihalyi 的心流模型应用于宏观结构）：张力通过一个序列
> 积累，然后在某个里程碑释放，再以
> 略高的基线重新参与。平坦难度制造无聊；不间断
> 升级制造疲劳。
>
> 尖峰是测试累积技能的刻意峰值。低谷是
> 刻意的凹谷，给玩家呼吸、实验并在下一次升级前
> 感到强大的空间。两者都是设计出来的，而非涌现的。
>
> "恢复设计"至关重要：尖峰之后立即发生什么？
> 玩家离开艰难时刻时应有成就感，而不是被耗尽。给
> 他们一个低谷、一份奖励或一个叙事回报。

| Name | Location in Game | Type | Purpose | Recovery Design |
|------|-----------------|------|---------|-----------------|
| 名称 | 游戏中位置 | 类型 | 目的 | 恢复设计 |
|------|-----------------|------|---------|-----------------|
| [e.g., "The First Boss"] | [e.g., End of Area 1, ~1 hr] | [Spike] | [Tests all skills introduced in Area 1. Acts as a gate confirming the player is ready for increased complexity.] | [Post-boss: safe area, upgrade opportunity, story beat that provides emotional relief before Area 2 escalation begins.] |
| [e.g., "The Safe Zone"] | [e.g., Hub area between Areas 1 and 2, ~1.5 hrs] | [Valley] | [Player feels powerful from boss win. Space to experiment with build options before stakes rise.] | [N/A — this IS the recovery from the preceding spike.] |
| [e.g., "The Knowledge Wall"] | [e.g., Area 3 first encounter, ~4 hrs] | [Spike — knowledge type] | [Forces players to engage with a mechanic they may have been avoiding. Survival requires understanding it.] | [Clear feedback on what killed them. Tutorial hint surfaces on third failure. Mechanic becomes standard after this point.] |
| [e.g., "Pre-Climax Valley"] | [e.g., Just before final act, ~20 hrs] | [Valley] | [Emotional breathing room before the final escalation. Player reflects on how far they have come.] | [N/A — designed as relief before the finale's spike.] |
| [Add spike/valley] | [Location] | [Type] | [Purpose] | [Recovery] |
| [例如"第一个 Boss"] | [例如区域 1 末尾，约 1 小时] | [尖峰] | [测试区域 1 中引入的所有技能。充当关卡门，确认玩家已准备好迎接更高复杂度。] | [Boss 后：安全区、升级机会、故事节拍，在区域 2 升级开始前提供情感缓解。] |
| [例如"安全区"] | [例如区域 1 和 2 之间的枢纽区域，约 1.5 小时] | [低谷] | [玩家因击败 Boss 而感到强大。在风险升高前有空间实验构筑选项。] | [不适用——这本身就是前一个尖峰的恢复。] |
| [例如"知识之墙"] | [例如区域 3 首次遭遇，约 4 小时] | [尖峰——知识型] | [迫使玩家接触他们可能一直在回避的机制。生存需要理解它。] | [对死因给出清晰反馈。第三次失败时浮现教程提示。此后该机制成为标准。] |
| [例如"高潮前低谷"] | [例如最终幕之前，约 20 小时] | [低谷] | [最终升级前的情感呼吸空间。玩家反思自己走了多远。] | [不适用——设计为终章尖峰前的缓解。] |
| [添加尖峰/低谷] | [位置] | [类型] | [目的] | [恢复] |

---

## Balancing Levers
## 平衡杠杆

> **Guidance**: Balancing levers are the specific values and parameters that
> tune difficulty at each phase. Centralizing them here makes it possible to
> tune the whole-game difficulty curve without hunting through individual GDDs.
> For each lever, the GDD that owns it should be cross-referenced.
>
> "Current setting" is the design intent at the time of writing — implementation
> values live in `assets/data/`. The tuning range is the safe operating range:
> values outside this range reliably break the intended experience.
> **指导**：平衡杠杆是在每个阶段调校难度的
> 具体数值和参数。将它们集中在这里，使得无需
> 在单个 GDD 中翻找就能调校整款游戏的难度曲线。
> 对每个杠杆，应交叉引用拥有它的 GDD。
>
> "当前设置"是撰写时的设计意图——实现
> 数值位于 `assets/data/`。调校范围是安全操作范围：
> 超出此范围的数值会可靠地破坏预期体验。

| Lever | Phase(s) | Effect | Current Setting | Tuning Range | Notes |
|-------|----------|--------|----------------|-------------|-------|
| 杠杆 | 阶段 | 效果 | 当前设置 | 调校范围 | 备注 |
|-------|----------|--------|----------------|-------------|-------|
| [Enemy health multiplier] | [All] | [Higher = longer fights = more resource pressure and execution time] | [1.0x] | [0.7x - 1.5x] | [Below 0.7x, fights end before player can read enemy patterns. Above 1.5x, attrition replaces skill.] |
| [Enemy aggression timer] | [Mid game onward] | [Time between enemy attacks; lower = less time to react] | [e.g., 2.0s] | [1.2s - 3.0s] | [Below 1.2s, reaction window is sub-human. Above 3.0s, encounters feel passive.] |
| [Resource drop rate] | [Early game] | [Lower = more resource pressure = punishes inefficiency harder] | [e.g., 1.5x baseline] | [0.8x - 2.0x] | [Onboarding generosity; reduces in mid-game as player skill assumed.] |
| [New mechanic introduction density] | [First hour] | [How many new concepts per minute of play; too high = cognitive overload] | [e.g., 1 new mechanic per 8 min] | [1 per 5 min (max) to 1 per 15 min (slow)] | [Above 1 per 5 min in early game causes retention drop. Below 1 per 15 min causes boredom.] |
| [Failure cost] | [All] | [Time lost on failure; higher = more punishing = more tension] | [e.g., 2 min setback] | [30s - 8 min] | [Must scale with encounter frequency. Frequent failures need fast recovery.] |
| [Add lever] | [Phase] | [Effect] | [Setting] | [Range] | [Notes] |
| [敌人生命倍率] | [全部] | [越高 = 战斗越长 = 更多资源压力与执行时间] | [1.0x] | [0.7x - 1.5x] | [低于 0.7x，战斗在玩家能读懂敌人模式之前就结束。高于 1.5x，消耗取代技巧。] |
| [敌人攻击性计时器] | [中期起] | [敌人攻击之间的时间；越低 = 反应时间越少] | [例如 2.0s] | [1.2s - 3.0s] | [低于 1.2s，反应窗口低于人类极限。高于 3.0s，遭遇感觉被动。] |
| [资源掉落率] | [前期] | [越低 = 资源压力越大 = 更严厉惩罚低效] | [例如 1.5x 基线] | [0.8x - 2.0x] | [新手引导期的慷慨；中期随假定玩家技巧提高而降低。] |
| [新机制引入密度] | [第一个小时] | [每分钟游玩引入多少新概念；过高 = 认知超载] | [例如每 8 分钟 1 个新机制] | [每 5 分钟 1 个（上限）到每 15 分钟 1 个（缓慢）] | [前期高于每 5 分钟 1 个会导致留存下降。低于每 15 分钟 1 个会导致无聊。] |
| [失败代价] | [全部] | [失败损失的时间；越高 = 越惩罚 = 越紧张] | [例如 2 分钟倒退] | [30 秒 - 8 分钟] | [必须随遭遇频率缩放。频繁失败需要快速恢复。] |
| [添加杠杆] | [阶段] | [效果] | [设置] | [范围] | [备注] |

---

## Player Skill Assumptions
## 玩家技能假设

> **Guidance**: Every game implicitly assumes players develop a set of skills
> over the course of play. Making these assumptions explicit allows the team to
> verify that each skill is actually taught before it is tested, and that the
> gap between "introduced" and "tested hard" is long enough for internalization.
>
> A skill introduced and tested in the same encounter is a surprise difficulty
> spike. A skill assumed but never formally introduced is an undocumented knowledge
> wall. Both are fixable — but only if they are documented.
>
> "Taught by" refers to the mechanism: tutorial prompt, environmental design,
> safe practice opportunity, NPC instruction, or organic discovery.
>
> "Tested by" refers to the first encounter that REQUIRES this skill to survive
> without taking significant damage or cost.
> **指导**：每款游戏都隐含假定玩家在游玩过程中
> 发展出一组技能。将这些假设明确化，使团队能够
> 验证每项技能在被测试之前确实被教授过，并且
> "引入"与"严格测试"之间的间隔足够长，以便内化。
>
> 一项在同一遭遇中引入并测试的技能是意外的难度
> 尖峰。一项被假定但从未正式引入的技能是未记录的知识
> 之墙。两者都可修复——但只有在被记录的前提下。
>
> "由……教授"指机制：教程提示、环境设计、
> 安全练习机会、NPC 指示或有机发现。
>
> "由……测试"指第一个要求此技能才能在不承受
> 显著伤害或代价下存活的遭遇。

| Skill | Introduced In | Expected Mastered By | Taught By | First Hard Test |
|-------|--------------|---------------------|-----------|-----------------|
| 技能 | 引入于 | 预期精通于 | 由……教授 | 首次严格测试 |
|-------|--------------|---------------------|-----------|-----------------|
| [Core movement / dodging] | [Tutorial area, 0-5 min] | [End of Area 1, ~1 hr] | [Safe practice zone with visible hazards] | [First Elite enemy, ~45 min] |
| [Resource management] | [First shop encounter, ~10 min] | [Mid game, ~4 hrs] | [Resource scarcity in Area 2 forces planning] | [Boss that requires consumables to survive efficiently] |
| [Build decision-making] | [First upgrade choice, ~20 min] | [End of mid game, ~10 hrs] | [Multiple playthroughs / community discussion / in-game build advisor] | [Endgame encounters that punish build incoherence] |
| [Enemy pattern reading] | [Area 1 basic enemies] | [Area 3, ~4 hrs] | [Enemy telegraphs visible and consistent from introduction] | [Elite enemy with 3+ distinct attack patterns] |
| [Add skill] | [When introduced] | [When mastered] | [Taught by] | [First hard test] |
| [核心移动 / 闪避] | [教程区域，0-5 分钟] | [区域 1 末尾，约 1 小时] | [有可见危险的安全练习区] | [首个精英敌人，约 45 分钟] |
| [资源管理] | [首次商店遭遇，约 10 分钟] | [中期，约 4 小时] | [区域 2 的资源稀缺迫使规划] | [需要消耗品才能高效存活的 Boss] |
| [构筑决策] | [首次升级选择，约 20 分钟] | [中期末尾，约 10 小时] | [多次通关 / 社区讨论 / 游戏内构筑顾问] | [惩罚构筑不连贯的终局遭遇] |
| [敌人模式阅读] | [区域 1 基础敌人] | [区域 3，约 4 小时] | [敌人预告从引入起可见且一致] | [拥有 3+ 种不同攻击模式的精英敌人] |
| [添加技能] | [引入时机] | [精通时机] | [由……教授] | [首次严格测试] |

---

## Accessibility Considerations
## 无障碍考量

> **Guidance**: Accessibility in difficulty design is not about making the game
> easier — it is about ensuring players with different needs and skill profiles
> can reach the intended emotional experience. Be explicit about what CAN be
> adjusted and what CANNOT, and justify both.
>
> The principle from Self-Determination Theory: players need to feel competent.
> Accessibility options that help players feel competent without removing the
> feeling of agency are always worth including. Options that make competence
> meaningless undermine the core experience.
> **指导**：难度设计中的无障碍不是让游戏
> 更容易——而是确保有不同需求和技能画像的玩家
> 能到达预期的情感体验。明确说明什么可以
> 调整、什么不能，并为两者提供理由。
>
> 来自自我决定理论的原则：玩家需要感到胜任。
> 帮助玩家感到胜任而不移除能动感的无障碍选项
> 总是值得包含。让胜任感变得无意义的选项会破坏核心体验。

### What Can Be Adjusted
### 可以调整的

| Adjustment | Method | Effect on Experience | Tradeoff |
|-----------|--------|---------------------|----------|
| 调整 | 方法 | 对体验的影响 | 权衡 |
|-----------|--------|---------------------|----------|
| [e.g., Enemy speed reduction] | [Difficulty setting / accessibility menu] | [Lowers execution difficulty without changing knowledge or decision requirements] | [Reduces the tension of combat timing; acceptable for narrative players] |
| [e.g., Extended input windows] | [Accessibility menu] | [Allows players with motor impairments to achieve the same skill outcomes with more time] | [Minimal — skill expression preserved, threshold relaxed] |
| [e.g., Hint frequency] | [Settings toggle] | [Surfaces contextual guidance more or less aggressively based on player preference] | [Higher hints reduce knowledge difficulty; players who want to discover organically may feel over-guided] |
| [Add option] | [Method] | [Effect] | [Tradeoff] |
| [例如降低敌人速度] | [难度设置 / 无障碍菜单] | [降低执行难度而不改变知识或决策要求] | [降低战斗时机的紧张感；对叙事向玩家可接受] |
| [例如延长输入窗口] | [无障碍菜单] | [让有运动障碍的玩家用更多时间达成相同技能结果] | [极小——技能表达得以保留，阈值放宽] |
| [例如提示频率] | [设置开关] | [根据玩家偏好更激进或更保守地呈现情境指导] | [更高提示降低知识难度；想有机发现的玩家可能觉得被过度引导] |
| [添加选项] | [方法] | [效果] | [权衡] |

### What Cannot Be Adjusted (and Why)
### 不能调整的（及原因）

| Fixed Element | Why It Cannot Change | Design Reasoning |
|--------------|---------------------|-----------------|
| 固定元素 | 为何不能改变 | 设计推理 |
|--------------|---------------------|-----------------|
| [e.g., Permadeath in roguelike run] | [Removing it eliminates the resource pressure axis that all encounter balance is built around] | [The weight of each decision comes from permanence; without it, the core loop loses meaning] |
| [e.g., Core narrative pacing] | [Difficulty valleys are timed to story beats; adjustable pacing would decouple challenge from narrative intention] | [Story and difficulty are designed as one arc, not two independent tracks] |
| [Add fixed element] | [Why] | [Reasoning] |
| [例如 roguelike 轮次中的永久死亡] | [移除它会消除所有遭遇平衡所依赖的资源压力轴] | [每个决策的重量来自永久性；没有它，核心循环失去意义] |
| [例如核心叙事节奏] | [难度低谷与故事节拍同步；可调整节奏会使挑战与叙事意图脱钩] | [故事与难度被设计为一条弧线，而非两条独立轨道] |
| [添加固定元素] | [为何] | [推理] |

---

## Cross-System Difficulty Interactions
## 跨系统难度交互

> **Guidance**: When two systems operate simultaneously, their combined
> difficulty is often greater than the sum of their parts — or sometimes
> less. These interactions are frequently unintended and only surface during
> playtesting. Documenting anticipated interactions here creates a checklist
> for QA and playtest sessions.
>
> "Is this intended?" Yes means the interaction is a designed feature.
> No means it should be mitigated. Partial means the interaction is
> acceptable in small doses but problematic if it becomes the dominant
> experience.
> **指导**：当两个系统同时运作时，它们组合的
> 难度常常大于各部分之和——有时
> 更小。这些交互往往是非预期的，只在
> 试玩中浮现。在此记录预期交互，为 QA 和试玩会话
> 创建检查清单。
>
> "是否为预期？"是 表示该交互是设计好的特性。
> 否 表示应予以缓解。部分 表示该交互
> 少量可接受，但若成为主导体验则有问题。

| System A | System B | Combined Effect | Intended? |
|----------|----------|----------------|-----------|
| 系统 A | 系统 B | 组合效果 | 是否预期？ |
|----------|----------|----------------|-----------|
| [Combat difficulty] | [Resource scarcity] | [Resource-poor players face combat encounters with fewer options, compounding difficulty for players already struggling. Can create a death spiral where failing creates worse conditions.] | [Partial — intended as stakes, not as a trap. Pity mechanics required to prevent unrecoverable states.] |
| [Build complexity] | [Time pressure] | [Players who are still learning their build take longer to make decisions under time pressure, increasing cognitive load beyond the intended challenge of either system alone.] | [No — reduce decision complexity demand in high time-pressure encounters.] |
| [New mechanic introduction] | [Resource pressure] | [Introducing a new system while the player is already under resource pressure forces them to learn and optimize simultaneously.] | [No — new mechanics should be introduced in low-resource-pressure environments.] |
| [Enemy density] | [Execution difficulty] | [High enemy counts with individually demanding enemies produce difficulty that scales exponentially, not linearly.] | [Partial — intended for optional challenge content only; not acceptable on the critical path.] |
| [Add System A] | [Add System B] | [Combined effect description] | [Yes / No / Partial] |
| [战斗难度] | [资源稀缺] | [资源匮乏的玩家面对战斗遭遇时选项更少，为已经挣扎的玩家叠加难度。可能形成死亡螺旋，失败会制造更糟的条件。] | [部分——意图作为风险，而非陷阱。需要怜悯机制以防止不可恢复状态。] |
| [构筑复杂度] | [时间压力] | [仍在学习构筑的玩家在时间压力下需要更长时间决策，使认知负荷超出任一系统单独的预期挑战。] | [否——在高时间压力遭遇中降低决策复杂度要求。] |
| [新机制引入] | [资源压力] | [在玩家已处于资源压力下时引入新系统，迫使他们同时学习与优化。] | [否——新机制应在低资源压力环境中引入。] |
| [敌人密度] | [执行难度] | [高敌人数配合单体要求高的敌人会产生指数而非线性缩放的难度。] | [部分——仅用于可选挑战内容；在关键路径上不可接受。] |
| [添加系统 A] | [添加系统 B] | [组合效果描述] | [是 / 否 / 部分] |

---

## Validation Checklist
## 验证清单

> **Guidance**: These checkpoints structure playtesting sessions to verify
> the difficulty curve is achieving its intent. Each item should be checked
> with at least 3 playtester sessions before being marked complete. Note the
> playtester profile that revealed issues — difficulty problems are almost
> always player-profile-specific.
> **指导**：这些检查点组织试玩会话，以验证
> 难度曲线是否达成其意图。每项应至少在 3 次试玩会话中
> 检查后才能标记完成。注意揭示问题的
> 试玩者画像——难度问题几乎总是特定于玩家画像。

### Onboarding (0-30 min)
### 新手引导（0-30 分钟）
- [ ] Players with no prior genre experience complete the tutorial area without external help
- [ ] Zero players cite confusion about what they are supposed to be doing in the first 5 minutes
- [ ] At least one playtester spontaneously says "I want to see what's next" within 15 minutes
- [ ] First failure moment produces a visible learning response (player verbalizes what went wrong)
- [ ] 无该类型经验的玩家在没有外部帮助的情况下完成教程区域
- [ ] 零名玩家在最初 5 分钟内表示对自己该做什么感到困惑
- [ ] 至少一名试玩者在 15 分钟内自发说出"我想看看接下来是什么"
- [ ] 第一次失败时刻产生可见的学习反应（玩家说出哪里出了问题）

### Early Game (30 min - 2 hrs)
### 前期（30 分钟 - 2 小时）
- [ ] Average player reaches the first competence moment within 60 minutes
- [ ] First major encounter (boss or equivalent) is passed within 3-5 attempts on average
- [ ] No player cites a mechanic introduced "too suddenly without warning"
- [ ] Players can describe their current goal without prompting
- [ ] 平均玩家在 60 分钟内到达首次胜任时刻
- [ ] 首个重要遭遇（Boss 或等效内容）平均在 3-5 次尝试内通过
- [ ] 没有玩家提到某机制"太突然，毫无预警"
- [ ] 玩家无需提示即可描述当前目标

### Mid Game (2-10 hrs)
### 中期（2-10 小时）
- [ ] Players discover at least one depth mechanic through organic play (without guide)
- [ ] Playtest sessions report "I want to try a different build / strategy next run"
- [ ] No single difficulty axis dominates player complaints — frustration is distributed
- [ ] Players who fail a mid-game encounter correctly identify the cause without being told
- [ ] 玩家通过有机游玩（不看攻略）发现至少一个深度机制
- [ ] 试玩会话报告"下一轮我想试试不同的构筑 / 策略"
- [ ] 没有单一难度轴主导玩家抱怨——挫败感是分散的
- [ ] 在中场遭遇失败的玩家无需被告知即可正确识别原因

### Late Game (10+ hrs)
### 后期（10+ 小时）
- [ ] Players report the final challenge feels like a culmination of everything they have learned
- [ ] Failure at late-game content does not feel unfair (even if it is hard)
- [ ] Players who complete the main content express a reason to continue playing
- [ ] 玩家报告最终挑战感觉像是所学一切的顶点
- [ ] 后期内容的失败不让人觉得不公平（即便很难）
- [ ] 完成主内容的玩家表达了继续游玩的理由

### Accessibility
### 无障碍
- [ ] All listed accessibility options function without breaking encounter intent
- [ ] Players using accessibility settings report feeling competent, not patronized
- [ ] Fixed difficulty elements are encountered and accepted without negative reception from accessibility playtesters
- [ ] 所有列出的无障碍选项都能运作，且不破坏遭遇意图
- [ ] 使用无障碍设置的玩家报告感到胜任，而非被居高临下对待
- [ ] 固定难度元素被遇到并被接受，且无障碍试玩者未给出负面反馈

---

## Open Questions
## 开放问题

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 问题 | 负责人 | 截止日期 | 解决情况 |
|----------|-------|----------|-----------|
| [Is the onboarding ramp correctly calibrated for players without prior genre experience?] | [game-designer] | [Date] | [Unresolved — schedule genre-naive playtester sessions] |
| [Does the first boss represent the correct difficulty spike or is it a wall?] | [game-designer, systems-designer] | [Date] | [Unresolved — requires 5+ playtester sessions to establish average attempt count] |
| [Do any cross-system interactions produce unrecoverable states?] | [systems-designer] | [Date] | [Unresolved — requires targeted playtest with resource-constrained starting conditions] |
| [Add question] | [Owner] | [Date] | [Resolution] |
| [新手引导坡道对无该类型经验的玩家是否校准正确？] | [game-designer] | [Date] | [未解决——安排类型新手的试玩会话] |
| [第一个 Boss 是否代表正确的难度尖峰，还是一堵墙？] | [game-designer, systems-designer] | [Date] | [未解决——需要 5+ 次试玩会话以确定平均尝试次数] |
| [是否有任何跨系统交互产生不可恢复状态？] | [systems-designer] | [Date] | [未解决——需要在资源受限的起始条件下进行针对性试玩] |
| [添加问题] | [负责人] | [Date] | [解决情况] |
