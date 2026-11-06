# Full concept flow (`workflow: standard` or `full`)

# 完整概念流程（`workflow: standard` 或 `full`）

**In this file:** start · Phase 1 Creative discovery · Phase 2 Concept generation · Phase 3 Core loop ·
Phase 4 Pillars and boundaries · Phase 5 Player types · Phase 6 Scope and feasibility · Phase 7
Write the concept · Phase 8 Next steps

**本文件内容：** 开始 · 阶段 1 创意发现 · 阶段 2 概念生成 · 阶段 3 核心循环 · 阶段 4 支柱与边界 · 阶段 5 玩家类型 · 阶段 6 范围与可行性 · 阶段 7 编写概念 · 阶段 8 后续步骤

The output is `design/gdd/game-concept.md`, written from the game-concept template SKILL.md names.
Ask at each phase; never generate the whole concept silently. You facilitate, the user decides.
Write the analysis in your reply first, then ask with short option labels.

输出是 `design/gdd/game-concept.md`，依据 SKILL.md 所指的游戏概念模板编写。在每个阶段都要询问；绝不要静默生成整个概念。你负责引导，由用户做决定。先在回复中写下分析，然后用简短选项标签询问。

## Start

## 开始

1. The text typed after the skill name may hold a genre or theme hint (`roguelike`, `cozy
   farming`). `open` or nothing: start from scratch.
2. If `design/gdd/game-concept.md` or `design/gdd/game-pillars.md` exists, read it by section (find
   the headings with the Grep tool with pattern `^#` in content mode, then read those ranges)
   and resume or build on it instead of restarting.

1. 技能名称之后输入的文本可能包含类型或主题提示（`roguelike`、`cozy farming`）。`open` 或什么都没有：从头开始。
2. 如果 `design/gdd/game-concept.md` 或 `design/gdd/game-pillars.md` 存在，按章节读取它（用 Grep 工具以内容模式、模式 `^#` 找到标题，然后读取那些范围），并在此基础上继续或构建，而不是重新开始。

## Phase 1: Creative discovery

## 阶段 1：创意发现

Start with the person, not the game. Ask conversationally:
- A moment in a game that moved or thrilled them, and what created it.
- A fantasy they have always wanted in a game and never found.
- The three games they spent the most time with, and why. Ask this as plain text, never with
  preset options: they must be able to type any game.
- Genres they love or avoid. Then ask: challenge, relax, story or self-expression?

从人开始，而不是从游戏开始。以对话的方式询问：
- 某个游戏中让他们感动或兴奋的瞬间，以及是什么造就了它。
- 他们一直希望在游戏中体验却从未找到的幻想。
- 他们花时间最多的三款游戏，以及原因。以纯文本方式询问，绝不使用预设选项：他们必须能够输入任何游戏。
- 他们喜爱或回避的类型。然后询问：挑战、放松、故事还是自我表达？

Then ask these three questions together:
- "What kind of experience do you most want players to have?" Challenge & Mastery / Story &
  Discovery / Expression & Creativity / Relaxation & Flow
- "What's your realistic development timeline?" Weeks / Months / 1-2 years / Multi-year
- "Where are you in your dev journey?" First game / Shipped before / Professional background

然后一起询问这三个问题：
- "你最希望玩家获得什么样的体验？" 挑战与精通 / 故事与发现 / 表达与创造 / 放松与心流
- "你现实的开发时间线是怎样的？" 数周 / 数月 / 1-2 年 / 多年
- "你在开发旅程中处于什么位置？" 第一款游戏 / 之前发布过 / 专业背景

Sum the answers up as a **Creative Brief** of 3 to 5 sentences (emotional goals, taste,
constraints), read it back and confirm it.

将答案总结为一份 3 到 5 句话的**创意简报**（情感目标、品味、约束），复述给它并确认。

## Phase 2: Concept generation

## 阶段 2：概念生成

Generate **three** distinct concepts from the brief, each in a different direction, using:
- **Verb-first:** start from the core verb (build, fight, explore, solve, survive, manage).
- **Mashup:** genre A + theme B; the tension is the hook ("farming sim + cosmic horror").
- **Experience-first (MDA backward):** start from the aesthetic (sensation, fantasy, narrative,
  challenge, fellowship, discovery, expression, submission) and work back to mechanics.

从简报中生成**三个**不同的概念，每个朝向不同方向，使用：
- **动词优先：** 从核心动词出发（建造、战斗、探索、解谜、生存、管理）。
- **混搭：** 类型 A + 主题 B；张力就是钩子（"种田模拟 + 宇宙恐怖"）。
- **体验优先（MDA 反向）：** 从美学出发（感官、幻想、叙事、挑战、社交、发现、表达、顺从），再反推机制。

Each concept has: Working Title · Elevator Pitch (1-2 sentences, passes the 10-second test) · Core
Verb · Core Fantasy · Unique Hook ("like X, and also Y") · Primary MDA Aesthetic · Estimated Scope
(small / medium / large) · Why It Could Work (one sentence) · Biggest Risk (one sentence).

每个概念包含：暂定名称 · 一句话推介（1-2 句话，通过 10 秒测试） · 核心动词 · 核心幻想 · 独特钩子（"像 X，而且还有 Y"） · 主要 MDA 美学 · 预估范围（小 / 中 / 大） · 为什么它可能成立（一句话） · 最大风险（一句话）。

Present all three, then ask one question with these five options: "Which concept resonates with
you? You can pick one, combine elements, or ask for fresh directions." `Concept 1 — [Title]` /
`Concept 2 — [Title]` / `Concept 3 — [Title]` / `Combine elements across concepts` / `Generate
fresh directions`. Ask it in every automation mode: no rule can pick the user's creative
direction. Do not push toward a choice.

呈现全部三个，然后用这五个选项询问一个问题："哪个概念与你产生共鸣？你可以选一个、组合元素，或要求全新方向。" `Concept 1 — [Title]` / `Concept 2 — [Title]` / `Concept 3 — [Title]` / `Combine elements across concepts` / `Generate fresh directions`。在每种自动化模式下都要询问：没有任何规则能替用户选择创意方向。不要推动做出选择。

## Phase 3: Core loop

## 阶段 3：核心循环

For the chosen concept, ask with options derived from the concept, each with an `I'll describe it`
option:
1. "What's the primary feel of the core action?" (3-4 options that fit the genre and tone)
2. The concept's most important design variable (world reactivity, pacing, agency), as a question.

对于所选概念，用从概念中推导出的选项询问，每个都有一个 `I'll describe it` 选项：
1. "核心动作的首要感觉是什么？"（3-4 个契合类型和基调的选项）
2. 以问题的形式询问该概念最重要的设计变量（世界反应性、节奏、能动性）。

Then work through, in the reply:
- **30-second loop:** is the action satisfying in itself, and why (feedback, timing, depth)?
- **5-minute loop:** what turns moments into cycles; where "one more run" starts; the choices made.
- **Session loop (30-120 minutes):** a full session, its stopping points, the hook between sessions.
- **Progression loop:** how the player grows, the long-term goal, when the game is done.
- **Motivation (self-determination theory):** autonomy, competence, relatedness.

然后在回复中逐项处理：
- **30 秒循环：** 动作本身是否令人满足，为什么（反馈、时机、深度）？
- **5 分钟循环：** 什么把瞬间变成循环；"再来一局"从哪里开始；做出了哪些选择。
- **会话循环（30-120 分钟）：** 一次完整会话、它的停止点、会话之间的钩子。
- **进程循环：** 玩家如何成长、长期目标、游戏何时结束。
- **动机（自我决定理论）：** 自主性、胜任感、归属感。

## Phase 4: Pillars and boundaries

## 阶段 4：支柱与边界

Draft **3 to 5 pillars**, each with a name, a one-sentence definition and a design test ("debating
X or Y, this pillar picks __"). Pillars should pull against each other a little. Add **3 or more
anti-pillars**: "We will NOT do [thing] because it would compromise [pillar]."

起草 **3 到 5 个支柱**，每个包含名称、一句话定义和一个设计测试（"在 X 或 Y 之间争论时，这个支柱选择 __"）。支柱之间应有一点相互拉扯。添加 **3 个或更多反支柱**："我们不会做[某事]，因为那会损害[支柱]。"

Ask: "Do these pillars feel right for your game?" `Lock these in` / `Rename or reframe one` /
`Swap a pillar out` / `Something else`. After a revision ask: "Pillars updated. Ready to lock these
in?" `Lock these in` / `Revise another pillar` / `Something else`.
- `collaborative`: repeat until the user picks `Lock these in`.
- `guided`: ask once, apply the revision, lock them in.
- `autonomous`: do not ask; lock the draft in and log the decision with the alternatives.

询问："这些支柱对你的游戏来说合适吗？" `Lock these in` / `Rename or reframe one` / `Swap a pillar out` / `Something else`。修订之后询问："支柱已更新。准备好锁定它们了吗？" `Lock these in` / `Revise another pillar` / `Something else`。
- `collaborative`：重复，直到用户选择 `Lock these in`。
- `guided`：询问一次，应用修订，然后锁定。
- `autonomous`：不询问；锁定草案，并将决策连同备选方案一起记录。

**Review mode** (from the settings block or `--review`):
- `solo` or `lean`: print these two lines, with the mode's name, and go on to Phase 5:
  `CD-PILLARS skipped — Solo mode.` and `AD-CONCEPT-VISUAL skipped — Solo mode.`
- `full`: hand the pillar review to the `creative-director` agent (gate CD-PILLARS; brief: the
  pillars with design tests, anti-pillars, core fantasy and hook) and the visual review to the
  `art-director` agent (gate AD-CONCEPT-VISUAL; brief: the pitch, pillars, target platform if
  known, reference games mentioned). Each reads its own gate file and returns its verdict; neither
  edits files. They are independent: hand them out together where you can, otherwise one after
  another.

**评审模式**（来自设置块或 `--review`）：
- `solo` 或 `lean`：打印以下两行，带上模式名称，然后进入阶段 5：`CD-PILLARS skipped — Solo mode.` 和 `AD-CONCEPT-VISUAL skipped — Solo mode.`
- `full`：将支柱评审交给 `creative-director` 智能体（门禁 CD-PILLARS；简报：带有设计测试的支柱、反支柱、核心幻想和钩子），将视觉评审交给 `art-director` 智能体（门禁 AD-CONCEPT-VISUAL；简报：推介、支柱、目标平台（若已知）、提到的参考游戏）。每个智能体读取自己的门禁文件并返回其裁决；两者都不编辑文件。它们相互独立：能一起派发时就一起派发，否则一个接一个。

With both reports, when CD-PILLARS returns APPROVE, ask these two questions together:
- **Pillars:** the creative-director's feedback. `Lock in as-is` / `Revise [pillar]` / `Discuss
  further`.
- **Visual anchor:** the art-director's 2-3 named directions, one option each, plus `Combine
  elements across directions` / `Describe my own direction`. On STRONG mark the dominant one
  `(Recommended)`. On CONCERNS show its reason and offer `Revise pillars` / `Describe my own
  direction`.

有了这两份报告后，当 CD-PILLARS 返回 APPROVE 时，一起询问这两个问题：
- **支柱：** 创意总监的反馈。`Lock in as-is` / `Revise [pillar]` / `Discuss further`。
- **视觉锚点：** 艺术总监提出的 2-3 个命名方向，各一个选项，外加 `Combine elements across directions` / `Describe my own direction`。若为 STRONG，将主导方向标记为 `(Recommended)`。若为 CONCERNS，展示其原因，并提供 `Revise pillars` / `Describe my own direction`。

If CD-PILLARS returns CONCERNS or REJECT, settle the pillars first (the Pillars question alone),
then ask the Visual anchor question alone. NOT ASSESSED from either gate is not an approval: name
the missing input, supply it and run that gate again; failing that, treat CD-PILLARS NOT ASSESSED
as CONCERNS, and with no art-director directions offer only `Describe my own direction`.

如果 CD-PILLARS 返回 CONCERNS 或 REJECT，先解决支柱问题（只问支柱问题），然后单独询问视觉锚点问题。任一门的 NOT ASSESSED 都不是批准：指出缺失的输入，补充它并再次运行该门禁；若无法做到，将 CD-PILLARS 的 NOT ASSESSED 视为 CONCERNS，并且在没有艺术总监方向时只提供 `Describe my own direction`。

The chosen direction is the **Visual Identity Anchor**: it goes into the concept and seeds the art
bible.

所选方向就是**视觉身份锚点**：它进入概念，并为美术圣经奠定基础。

## Phase 5: Player types

## 阶段 5：玩家类型

Using Bartle's types and the Quantic Foundry model: the primary player who will love it
(Achievers, Explorers, Socializers, Competitors, Creators, Storytellers), the secondary appeal, who
it is not for, and successful games that serve the same player.

使用 Bartle 类型和 Quantic Foundry 模型：会喜爱它的主要玩家（成就者、探索者、社交者、竞争者、创造者、叙事者）、次要吸引力、它不适合谁，以及服务于同一类玩家的成功游戏。

## Phase 6: Scope and feasibility

## 阶段 6：范围与可行性

- **Platform.** Ask: "What platforms are you targeting?" `PC (Steam / Epic)` / `Mobile (iOS /
  Android)` / `Console` / `Web / Browser` / `Multiple platforms`. Record it for `/setup-engine`.
  Note what the platform implies, without recommending an engine: `/setup-engine` makes that call
  against the pinned engine reference.
- **Engine.** Ask in every automation mode, `autonomous` included: "Do you already have an engine
  you work in?" `Godot` / `Unity` / `Unreal Engine 5` / `No preference — help me decide`. Never
  pick an engine for the user. A named engine is recorded as their preference without second
  guessing. No preference: "Run `/setup-engine` after this session; it walks through the choice
  with your concept and platform." Make no recommendation here.
- Art pipeline and how labour-heavy it is; content scope (levels, items, hours); the MVP (the
  smallest build that tests whether the core loop is fun); the biggest technical, design and market
  risks; scope tiers (full vision, and what ships if time runs out).

- **平台。** 询问："你的目标平台是什么？" `PC (Steam / Epic)` / `Mobile (iOS / Android)` / `Console` / `Web / Browser` / `Multiple platforms`。记录下来供 `/setup-engine` 使用。说明该平台意味着什么，但不要推荐引擎：那个决定由 `/setup-engine` 对照固定的引擎参考来做出。
- **引擎。** 在每种自动化模式下都要询问，包括 `autonomous`："你已经有惯用的引擎了吗？" `Godot` / `Unity` / `Unreal Engine 5` / `No preference — help me decide`。绝不要替用户选引擎。被指名的引擎记录为他们的偏好，不再质疑。没有偏好："本次会话之后运行 `/setup-engine`；它会结合你的概念和平台走一遍这个选择。" 这里不做任何推荐。
- 美术管线及其劳动密集程度；内容范围（关卡、物品、小时数）；MVP（测试核心循环是否有趣的最小构建）；最大的技术、设计和市场风险；范围层级（完整愿景，以及时间不够时交付什么）。

**Review mode** before TD-FEASIBILITY: `solo` or `lean` prints `TD-FEASIBILITY skipped — Solo
mode.` (or `Lean mode`) and goes on to the scope tiers. `full`: after the technical risks, hand the
feasibility review to the `technical-director` agent (gate TD-FEASIBILITY; brief: the core loop,
platform, engine or "undecided", the technical risks). Show its report. HIGH RISK: offer to revisit
scope. CONCERNS: note and go on. NOT ASSESSED: name the missing input and record feasibility as not
assessed in the concept's risks, never as VIABLE.

在 TD-FEASIBILITY 之前的**评审模式**：`solo` 或 `lean` 打印 `TD-FEASIBILITY skipped — Solo mode.`（或 `Lean mode`），然后进入范围层级。`full`：在技术风险之后，将可行性评审交给 `technical-director` 智能体（门禁 TD-FEASIBILITY；简报：核心循环、平台、引擎或 "undecided"、技术风险）。展示其报告。HIGH RISK：提供重新审视范围的选项。CONCERNS：记录并继续。NOT ASSESSED：指出缺失的输入，并在概念的风险中将可行性记录为未评估，绝不记为 VIABLE。

**Review mode** before PR-SCOPE: `solo` or `lean` prints `PR-SCOPE skipped — Solo mode.` (or `Lean
mode`) and goes on to Phase 7. `full`: hand the scope review to the `producer` agent (gate PR-SCOPE;
brief: full vision, MVP, scope tiers, timeline, team size). It answers REALISTIC, OPTIMISTIC or
UNREALISTIC. UNREALISTIC: ask whether to adjust the MVP or scope tiers or keep them; the user
decides and the concept is never rejected for it. OPTIMISTIC: show the producer's adjustments and
ask whether to apply them. NOT ASSESSED: ask for the missing input (timeline, team size) and run it
again, or record scope as not assessed, never as REALISTIC.

在 PR-SCOPE 之前的**评审模式**：`solo` 或 `lean` 打印 `PR-SCOPE skipped — Solo mode.`（或 `Lean mode`），然后进入阶段 7。`full`：将范围评审交给 `producer` 智能体（门禁 PR-SCOPE；简报：完整愿景、MVP、范围层级、时间线、团队规模）。它回答 REALISTIC、OPTIMISTIC 或 UNREALISTIC。UNREALISTIC：询问是否调整 MVP 或范围层级，或保持原样；由用户决定，概念绝不因此被拒绝。OPTIMISTIC：展示制作人的调整，并询问是否应用它们。NOT ASSESSED：请求缺失的输入（时间线、团队规模）并再次运行，或将范围记录为未评估，绝不记为 REALISTIC。

## Phase 7: Write the concept

## 阶段 7：编写概念

Fill every section of the template from the conversation, including the MDA analysis, motivation
profile and flow design, plus a **Visual Identity Anchor** section: the direction's name, its
one-line visual rule, 2-3 supporting principles with design tests, and the colour philosophy.

根据对话填写模板的每一节，包括 MDA 分析、动机画像和心流设计，外加一个**视觉身份锚点**章节：该方向的名称、其一行视觉规则、2-3 条带设计测试的支撑原则，以及色彩哲学。

The Core Identity table's Estimated Scope matches the full-vision timeline in Scope Tiers: write
"Large (X–Y months, solo)" or "Large (X–Y months, team of N)", not "Large".

核心身份表中的预估范围要与范围层级中的完整愿景时间线一致：写 "Large (X–Y months, solo)" 或 "Large (X–Y months, team of N)"，而不是 "Large"。

Ask, as its own question: "Game concept is ready. May I write it to `design/gdd/game-concept.md`?"
`Yes — write it` / `Not yet — revise a section first`. Write only on an explicit yes to this
question. A revision: ask which section (`Elevator Pitch` / `Core Fantasy & Unique Hook` /
`Pillars` / `Core Loop` / `MVP Definition` / `Scope Tiers` / `Risks` / `Something else — I'll
describe`), show it before and after, then ask "Ready to write the updated concept document?"
`Yes — write it` / `Revise another section`.
- `collaborative`: repeat until the yes.
- `guided`: ask once, apply the revision and write.
- `autonomous`: do not ask; write and log the decision.

作为独立的问题询问："游戏概念已就绪。我可以把它写入 `design/gdd/game-concept.md` 吗？" `Yes — write it` / `Not yet — revise a section first`。只有对该问题的明确肯定才写入。若要修订：询问哪个章节（`Elevator Pitch` / `Core Fantasy & Unique Hook` / `Pillars` / `Core Loop` / `MVP Definition` / `Scope Tiers` / `Risks` / `Something else — I'll describe`），展示修订前后的内容，然后询问"准备好写入更新后的概念文档了吗？" `Yes — write it` / `Revise another section`。
- `collaborative`：重复，直到得到肯定。
- `guided`：询问一次，应用修订并写入。
- `autonomous`：不询问；直接写入并记录决策。

Write the file, creating folders as needed. Never write `design/game-brief.md` at this tier.

写入文件，必要时创建文件夹。在此层级绝不写入 `design/game-brief.md`。

## Phase 8: Next steps

## 阶段 8：后续步骤

List every step, in order.

按顺序列出每一步。

**Design-first** (the concept is well defined):
1. `/setup-engine`: configure the engine and its version-aware reference docs
2. `/art-bible`: the visual identity, before any GDD. Required before the Technical Setup gate at
   `full`; at `standard` only when the game has visual-asset stories
3. `/design-review design/gdd/game-concept.md`: check the concept is complete
4. The `creative-director` agent: refine the pillars
5. `/map-systems`: the systems, their dependencies and priorities, in the systems index
6. `/design-system`: one GDD per system from step 5
7. `/create-architecture`: the architecture blueprint and its Required ADR list
8. `/architecture-decision`: one ADR per decision on that list
9. `/architecture-review`: the TR registry and traceability matrix (needed before the
   Pre-Production gate)
10. `/gate-check`: the stage gate before Production

**设计优先**（概念已明确定义）：
1. `/setup-engine`：配置引擎及其能感知版本的参考文档
2. `/art-bible`：在任何 GDD 之前确定视觉身份。在 `full` 下，技术准备门禁之前必须有它；在 `standard` 下，仅当游戏有视觉资产故事时才需要
3. `/design-review design/gdd/game-concept.md`：检查概念是否完整
4. `creative-director` 智能体：精炼支柱
5. `/map-systems`：在系统索引中列出系统、它们的依赖和优先级
6. `/design-system`：为步骤 5 中的每个系统编写一份 GDD
7. `/create-architecture`：架构蓝图及其必需 ADR 列表
8. `/architecture-decision`：为该列表上的每个决策编写一个 ADR
9. `/architecture-review`：TR 注册表和追溯矩阵（前期制作门禁之前需要）
10. `/gate-check`：进入制作阶段之前的阶段门禁

**Prototype-first** (the core mechanic is unproven):
1. `/setup-engine`
2. `/prototype [core mechanic]`: is it fun, in a day at most, throwaway code
3. PROCEED: `/art-bible`, then design-first steps 5-10 with what the prototype taught
4. PIVOT: `/brainstorm` again with the learnings
5. After design and architecture, `/vertical-slice` before committing to sprints

**原型优先**（核心机制尚未验证）：
1. `/setup-engine`
2. `/prototype [core mechanic]`：它有趣吗，最多一天，一次性代码
3. PROCEED：`/art-bible`，然后结合原型带来的经验执行设计优先的步骤 5-10
4. PIVOT：带着所学再次运行 `/brainstorm`
5. 在设计和架构之后、投入冲刺之前运行 `/vertical-slice`

Then a summary: the pitch, pillars, primary player type, engine preference, biggest risk and the
file path. End with the line `Verdict: COMPLETE — game concept written.`

然后是一份总结：推介、支柱、主要玩家类型、引擎偏好、最大风险和文件路径。以这一行结束：`Verdict: COMPLETE — game concept written.`

If the conversation is getting long before Phase 7, say that anything not yet written to
`design/gdd/game-concept.md` lives only in this conversation, and write the concept before a fresh
session.

如果在阶段 7 之前对话变得很长，说明任何尚未写入 `design/gdd/game-concept.md` 的内容都只存在于当前对话中，并在新会话之前写完概念。
