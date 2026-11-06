---
name: vertical-slice
description: "Pre-production validation — end-to-end build to confirm the full loop is achievable before committing to Production. After GDDs, architecture, UX specs."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/vertical-slice/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: vertical-slice
description: "预制作验证 — 通过端到端构建确认完整循环可以实现，然后再投入 Production。在 GDD、架构、UX 规格之后。"
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/vertical-slice/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

上文已解析 — 按原样使用；`--review` 会为本次运行覆盖 `review_mode`。若无
块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Vertical Slice

# 垂直切片

## Purpose

## 目的

The **vertical slice** answers a different question from the concept prototype:
*"Can we build this full game loop at production quality, on schedule?"*

**垂直切片**回答的问题与概念原型不同：
*"我们能否按进度、以生产质量构建出这个完整的游戏循环？"*

**Default use** — run late in Pre-Production, after GDDs, architecture, and UX
specs are complete. It is a near-production-quality build demonstrating one complete
[start → challenge → resolution] cycle.

**默认用法** — 在预制作后期运行，此时 GDD、架构和 UX
规格已经完成。它是一次接近生产质量的构建，演示一个完整的
[开始 → 挑战 → 解决] 循环。

**Post-pivot?** If a PIVOT verdict from an earlier vertical slice sent you back to
revise GDDs and architecture, run this again after revisions to re-validate. It can
be run as many times as needed until a PROCEED or KILL verdict is reached.

**转向之后？** 如果此前一次垂直切片给出的 PIVOT 裁决让你回去
修订 GDD 和架构，那么在修订后再次运行以重新验证。它
可以按需运行任意多次，直到得出 PROCEED 或 KILL 裁决。

It validates:

1. The pipeline (can the team actually produce this quality of content?)
2. Execution feasibility (are the architecture decisions correct for this game?)
3. Fun survival (does the fun from the concept prototype survive full design?)
4. **Velocity** (how long did this take? That's your real production rate estimate.)

它验证：

1. 管线（团队是否真的能产出这种质量的内容？）
2. 执行可行性（这些架构决策对此游戏是否正确？）
3. 乐趣存续（概念原型中的乐趣能否经受完整设计？）
4. **速度**（这花了多长时间？那才是你真实的生产速率估计。）

**Earlier in the project?** If you haven't written GDDs yet and want to validate
whether the core idea is worth designing, run `/prototype` (concept prototype) instead.

**项目更早期？** 如果你还没写 GDD，想验证
核心想法是否值得投入设计，请改为运行 `/prototype`（概念原型）。

---

## Phase 1: Resolve Review Mode and Load Context

## 阶段 1：解析评审模式并加载上下文

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

完整的检查模式见 `.claude/docs/director-gates.md`。各门禁的定义位于 `.claude/docs/director-gates/[gate-id].md`——被生成的智能体会读取自己的门禁文件；不要在父会话中读取它。

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每一次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅询问重大事项 · autonomous 记录并继续；
`automation_always_ask` 类目始终提示询问）。

Read the following files to understand the full design intent. Read each GDD, ADR
and the control manifest by section: find the headings you need with
the Grep tool (pattern `^#`, content mode) and Read those ranges with offset
and limit.
- `CLAUDE.md` — tech stack and engine
- `design/gdd/game-concept.md` — core fantasy and game pillars (or
  `design/game-brief.md`, the one-page brief that replaces it at `rigor: minimal` —
  pitch, core loop and "what they feel" line; it has no pillars)
- `design/gdd/systems-index.md` — MVP systems and their priorities
- `docs/architecture/architecture.md` — layer structure
- `docs/architecture/control-manifest.md` — technical rules for implementation
- Key GDDs for the systems being sliced

读取以下文件以理解完整的设计意图。按章节读取每个 GDD、ADR
和控制清单：用 Grep 工具（模式 `^#`，content 模式）找出所需的标题，
再以 offset 和 limit 读取那些范围。
- `CLAUDE.md` — 技术栈与引擎
- `design/gdd/game-concept.md` — 核心幻想与游戏支柱（或
  `design/game-brief.md`，即在 `rigor: minimal` 下替代它的一页简报——
  卖点、核心循环和"他们的感受"一句话；它没有支柱）
- `design/gdd/systems-index.md` — MVP 系统及其优先级
- `docs/architecture/architecture.md` — 分层结构
- `docs/architecture/control-manifest.md` — 实现的技术规则
- 被切片系统的关键 GDD

---

## Phase 2: Define the Slice Scope and Validation Question

## 阶段 2：定义切片范围与验证问题

Before building, define the **falsifiable validation question**:

在构建之前，定义**可证伪的验证问题**：

> *"Does a player, starting from nothing, experience [core fantasy from game-concept.md or game-brief.md]
> within [N] minutes, without developer guidance — and can we build one such loop
> in [X] days at representative quality?"*

> *"一个从零开始的玩家，能否在没有开发者引导的情况下，在 [N] 分钟内
> 体验到 [game-concept.md 或 game-brief.md 中的核心幻想]——以及我们能否
> 在 [X] 天内以代表性质量构建出这样一个循环？"*

Both parts matter: player experience AND build feasibility.

两部分都重要：玩家体验 AND 构建可行性。

**Scope discipline:**
- Include ALL core loop systems (minimum). If a system is required to complete one
  [start → challenge → resolution] cycle, it must be in the slice.
- **Target scope: 3–5 minutes of polished, continuous gameplay.** This is the
  industry-standard vertical slice length — long enough to demonstrate mechanics
  and tone, short enough to build at representative quality. If your slice would
  take longer than 5 minutes to play through, cut content, not quality.
- **Cut scope before cutting quality.** A low-quality slice that looks nothing like
  the intended game cannot validate production feasibility.
- If the scope feels too large to build in 1–3 weeks, the slice scope is wrong —
  not too big to build, but the slice is trying to prove too much at once.

**范围纪律：**
- 包含全部核心循环系统（至少）。若完成一个
  [开始 → 挑战 → 解决] 循环需要某个系统，它就必须包含在切片中。
- **目标范围：3–5 分钟精致、连续的游戏流程。** 这是
  业界标准的垂直切片长度——长到足以展示机制
  与基调，又短到足以按代表性质量构建。若你的切片通关
  需要超过 5 分钟，削减内容，而不是质量。
- **先削减范围，再削减质量。** 一个看起来完全不像
  目标游戏的低质量切片，无法验证生产可行性。
- 若范围大到觉得 1–3 周内无法构建，那是切片范围错了——
  不是大到无法构建，而是切片想一次证明太多。

**Scope creep warning:** The vertical slice is the highest-risk moment for scope
creep in the pre-production phase. Features feel "almost there" and it's tempting
to add "just one more system." Resist this. Cut, do not extend.

**范围蔓延警告：** 垂直切片是预制作阶段范围蔓延风险最高的时刻。
功能感觉"就差一点"，很容易想再加"就一个系统"。抵抗它。削减，而不是扩展。

Present scope to the user before building and get confirmation.

在构建前向用户呈现范围并取得确认。

---

## Phase 3: Plan the Build

## 阶段 3：规划构建

Define in bullet points:
- Systems implemented (which GDD sections are being exercised)
- The complete game loop cycle ([start] → [challenge] → [resolution] exactly)
- Art and audio quality level (placeholder acceptable, representative preferred)
- Specific, measurable success criteria for the validation question
- Hard time limit: [X] days. If exceeded, scope was wrong — stop and reassess.

用要点定义：
- 实现的系统（正在演练哪些 GDD 章节）
- 完整的游戏循环周期（精确的 [开始] → [挑战] → [解决]）
- 美术与音频质量水平（可接受占位，优先代表性）
- 针对验证问题的具体、可衡量的成功标准
- 硬性时间限制：[X] 天。若超出，范围就错了——停下并重新评估。

Ask the user to confirm scope before building. Name the checkpoint file in that
confirmation: "May I record this plan in `production/session-state/active.md`?"

在构建前请用户确认范围。在确认中指明检查点文件：
"我可以把这个计划记录到 `production/session-state/active.md` 吗？"

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist). Include: concept name,
validation question, systems in scope, art quality level, and current phase ("Phase
4 — Implement"). Update this file at the end of each build day with what was
completed. This is the primary recovery mechanism if the session ends mid-slice —
multi-week Engine builds will span many sessions.

一旦确认，写入一次会话检查点到 `production/session-state/active.md`
（若 `production/session-state/` 不存在则创建它）。包含：概念名称、
验证问题、范围内系统、美术质量水平，以及当前阶段（"阶段
4 — 实现"）。在每个构建日结束时用已完成的内容更新此文件。这是会话在切片中途结束时的
主要恢复机制——跨多周的引擎构建会跨越许多会话。

---

## Phase 4: Implement

## 阶段 4：实现

Ask: "May I create the vertical slice directory at
`prototypes/[concept-name]-vertical-slice/` and begin implementation?"

询问："我可以创建垂直切片目录
`prototypes/[concept-name]-vertical-slice/` 并开始实现吗？"

If yes, create the directory. Every file must begin with:

若是，创建该目录。每个文件都必须以下内容开头：

```
[comment] VERTICAL SLICE - NOT FOR PRODUCTION
[comment] Validation Question: [What this build is proving]
[comment] Date: [Current date]
```

Write `[comment]` in each file's own comment syntax — `#` in GDScript (`.gd`) and
Python, `//` in C#, C++ and JavaScript, `--` in Lua, `<!-- … -->` in HTML and
Markdown. A header in another language's syntax is a parse error, not a label.
Files that cannot hold a comment (JSON, engine-generated scene and project
files) are exempt.

用每个文件自身的注释语法书写 `[comment]`——GDScript（`.gd`）和
Python 中用 `#`，C#、C++ 和 JavaScript 中用 `//`，Lua 中用 `--`，HTML 和
Markdown 中用 `<!-- … -->`。使用另一种语言语法的头会导致解析错误，而不是标签。
无法容纳注释的文件（JSON、引擎生成的场景与项目
文件）豁免。

**Quality standards** — higher than concept prototype, not full production:
- Follow architecture layers from `docs/architecture/control-manifest.md`
- Naming conventions — `naming.*` from `project.yaml`; for any key absent or empty (including when `project.yaml` has no `naming` block), from `.claude/docs/technical-preferences.md`
- No hardcoded gameplay values — use constants or config files
- Basic error handling on critical paths
- Placeholder art acceptable; representative art preferred

**质量标准** — 高于概念原型，但非完整生产：
- 遵循 `docs/architecture/control-manifest.md` 中的架构分层
- 命名约定 — 来自 `project.yaml` 的 `naming.*`；对任何缺失或为空的键（包括当 `project.yaml` 没有 `naming` 块时），取自 `.claude/docs/technical-preferences.md`
- 无硬编码的玩法数值 — 使用常量或配置文件
- 关键路径上具备基本错误处理
- 可接受占位美术；优先代表性美术

**Multi-turn loop:** After writing the initial files, ask the user to run the
build and report what they observe. Iterate until the complete game loop cycle
is demonstrable. Each round:
1. User runs → reports errors or observations
2. Agent fixes errors or adjusts systems
3. Repeat until the full [start → challenge → resolution] cycle is playable

**多轮循环：** 写完初始文件后，请用户运行
构建并报告他们的观察。迭代直到完整的游戏循环周期
可演示。每一轮：
1. 用户运行 → 报告错误或观察
2. 智能体修复错误或调整系统
3. 重复直到完整的 [开始 → 挑战 → 解决] 循环可玩

**Sunk cost checkpoint (day 3 of planned timeline):** If the full game loop cycle
is not yet demonstrable, stop and reassess. Either the scope is too large or an
architectural assumption is wrong. Surface the blocker explicitly rather than
continuing to iterate.

**沉没成本检查点（计划时间线的第 3 天）：** 若完整的游戏循环周期
尚不可演示，停下并重新评估。要么范围太大，要么某个
架构假设是错的。明确暴露该阻碍，而不是
继续迭代。

Conduct at least 1 playtest session once the loop is demonstrable.

一旦循环可演示，至少进行 1 次试玩会话。

**Playtesting tip:** If you can get anyone who hasn't seen the game to play it —
a friend, family member, online community — watch them silently without explaining
anything. Don't guide them. Their confusion reveals what the game isn't
communicating on its own. This gives much better signal than self-testing.

**试玩技巧：** 如果你能让任何没看过这款游戏的人来玩——
朋友、家人、在线社群——默默地观察他们，什么都不解释。
不要引导他们。他们的困惑会揭示游戏自身未能
传达的东西。这比自测能给出好得多的信号。

**No external testers available?** Use rotation within the team: Dev A built
system X, so Dev A is a naive tester for system Y. Even a two-person team can
rotate effectively. Solo? Step away for 2-3 days then play through as a new
player — you won't have perfect first-impression signal but you'll catch the
critical blockers. Also try a "silent walkthrough": play your own slice in one
sitting without stopping to fix anything and log every moment you hesitate.

**没有外部测试者？** 在团队内部轮换：开发者 A 构建了
系统 X，那么开发者 A 就是系统 Y 的天真测试者。即便两人团队也能
有效轮换。单人？离开 2-3 天，然后以新玩家的身份通关——
你不会有完美的第一印象信号，但你会抓住
关键阻碍。也可以试试"静默走查"：一次性玩自己的切片，
中途不停下来修任何东西，并记录你每一次犹豫的时刻。

**Want richer observation data?** Ask the tester to **think aloud** as they play —
narrate what they're doing and why in real time. "I'm trying to figure out how to
attack... I pressed E... nothing... is it click?" This surfaces confusion the
instant it occurs rather than in retrospect. Best for onboarding and UI clarity
validation. Silent observation is still better for feel testing; think-aloud
changes the experience slightly but produces far more granular UX data.

**想要更丰富的观察数据？** 请测试者在游玩时**出声思考**——
实时叙述他们在做什么以及为什么。"我想弄清楚怎么
攻击……我按了 E……没反应……是用点击吗？"这能在困惑
发生的瞬间将其暴露，而不是事后回想。最适合新手引导和 UI 清晰度
验证。静默观察对感受测试仍然更好；出声思考
会略微改变体验，但能产出精细得多的 UX 数据。

**Async remote option:** Record a Loom or OBS session — give someone the build,
ask them to record their screen + audio, and send you the video. You get genuine
first-impression data without synchronous scheduling. Works across timezones.

**异步远程选项：** 录制一次 Loom 或 OBS 会话——把构建交给某人，
请他们录制屏幕 + 音频，并把视频发给你。你能得到真实的
第一印象数据，而无需同步排期。跨时区也可行。

**Testing AI, NPC, or complex system behavior before it's fully implemented?** Use the
**Wizard of Oz** technique: one person plays normally while a second person secretly
controls the NPC or system behavior in real time. The player believes it's automated.
This validates the *design intent* of an AI or economy system before the implementation
is complete — and reveals exactly what behaviors the system must produce to feel correct.
Particularly useful for vertical slices where an AI system is in scope but not yet
polished enough for unguided testing.

**在完全实现之前测试 AI、NPC 或复杂系统行为？** 使用
**绿野仙踪（Wizard of Oz）** 技巧：一个人正常游玩，另一人暗中
实时控制 NPC 或系统行为。玩家以为这是自动化的。
这在实现完成之前就验证了 AI 或经济系统的*设计意图*
——并精确揭示系统必须产出哪些行为才在感受上正确。
尤其适用于 AI 系统在范围内但尚未打磨到足以进行无引导测试的垂直切片。

---

## Phase 5: Playtest Debrief

## 阶段 5：试玩复盘

The loop is demonstrable. Before writing the report, collect structured observations
from actually playing it. Do NOT skip to report generation — the report is only as
good as the observations you capture here.

循环已可演示。在撰写报告之前，从实际游玩的经历中收集结构化观察。
不要直接跳到报告生成——报告的好坏只取决于你在此处捕获的观察。

Say exactly this:
> "Play through the complete [start → challenge → resolution] cycle from scratch,
> as if you're a new player with no knowledge of how it was built. Don't skip ahead
> or use developer shortcuts. Come back when you've completed the full loop —
> or when you've hit something that stopped you."

原话这样说：
> "从头完整地玩一遍 [开始 → 挑战 → 解决] 循环，
> 就像你是一个对它是如何构建的一无所知的新玩家。不要跳过
> 或使用开发者捷径。当你完成整个循环——或当你遇到
> 让你卡住的东西时——再回来。"

Once the user returns, ask these questions **one at a time**:

待用户返回后，**逐个**询问这些问题：

1. **Loop completion:**
   > "Did you complete the full [start → challenge → resolution] cycle on your own,
   > without needing any guidance from me or prior knowledge of the build?"

1. **循环完成度：**
   > "你是否在没有任何来自我的引导、也没有对构建的任何先备知识的情况下，
   > 自行完成了完整的 [开始 → 挑战 → 解决] 循环？"

2. **Time check:**
   > "How long did it take to reach the first meaningful action — the first moment
   > where you felt like you were actually playing the game?"

2. **时间检查：**
   > "到达第一次有意义的操作花了多长时间——即你第一次
   > 感觉自己真正在玩这款游戏的时刻？"

3. **Core fantasy:**
   > "The game is supposed to make you feel [core fantasy from game-concept.md or game-brief.md].
   > Did it? Be honest — not 'kind of' but specifically what you felt and when."

3. **核心幻想：**
   > "这款游戏本该让你感受到 [game-concept.md 或 game-brief.md 中的核心幻想]。
   > 它做到了吗？如实说——不要'差不多'，而是具体说出你感受到了什么、何时感受到的。"

4. **Blockers:**
   > "What stopped you, confused you, or pulled you out of the experience? Any
   > moment where you weren't sure what to do, or where something broke?"

4. **阻碍：**
   > "什么让你停下、困惑，或把你拉出了体验？有没有
   > 任何时刻你不确定该做什么，或某处出了问题？"

5. **Pipeline check:**
   > "As the developer — not the player — does this feel achievable at this quality
   > for the full game? What surprised you about how long things took to build?"

5. **管线检查：**
   > "作为开发者——而不是玩家——你觉得以这种质量做完整款游戏
   > 可行吗？在构建耗时方面，什么让你意外？"

6. **Verdict:**
   > "PROCEED, PIVOT, or KILL — and the specific reason."

6. **裁决：**
   > "PROCEED、PIVOT 还是 KILL——以及具体理由。"

If any answer is vague, ask: "Can you give me the specific moment where that happened?"
Precise observations populate the report. Vague ones produce a useless report.

若任一回答含糊，追问："你能给我那个具体发生的时刻吗？"
精确的观察才能填满报告。含糊的回答会产出无用的报告。

**PROCEED is not available when a validation item is NO.** `/gate-check production`
FAILs a built slice with any NO in its Vertical Slice Validation — a player got
through the loop without developer guidance (question 1), learned what to do
within the first 2 minutes (question 2 — longer is a no), the core mechanic feels
good (question 3), no critical fun-blocker bug (question 4). If any of those
answers is no, the verdict is PIVOT or KILL — the user chooses — and the report
names the NO.

**当任一验证项为 NO 时，PROCEED 不可用。** `/gate-check production`
会使其 Vertical Slice Validation 中含任何 NO 的已构建切片 FAIL——玩家在没有开发者引导的情况下
通关（问题 1）、在前 2 分钟内
学会该做什么（问题 2——更久即为 no）、核心机制感受
良好（问题 3）、无关键的乐趣阻碍缺陷（问题 4）。若其中任一
答案为 no，裁决即为 PIVOT 或 KILL——由用户选择——报告
指出该 NO。

**NOT ASSESSED is the fourth verdict.** When nobody has yet played the complete
loop from scratch — the user cannot play it this session, or stopped before the
end — the validation did not run, and the verdict is **NOT ASSESSED**, with the
reason. It ranks above PROCEED and below PIVOT and KILL: an unplayed slice has not
earned PROCEED, and a slice known to fail is more actionable than one nobody
played. It is never recorded as PROCEED.

**NOT ASSESSED 是第四种裁决。** 当尚无人从头玩过完整
循环时——用户本会话无法游玩，或在结束前
停下——验证并未运行，裁决为 **NOT ASSESSED**，并附上
理由。它排在 PROCEED 之上、PIVOT 与 KILL 之下：未玩过的切片尚未
赢得 PROCEED，而已知失败的切片比无人
玩过的切片更可操作。绝不将其记录为 PROCEED。

---

## Phase 6: Generate Vertical Slice Report

## 阶段 6：生成垂直切片报告

Track velocity throughout the build. Log:
- Day 1: what was built
- Day 2: what was built
- etc.

在整个构建过程中追踪速度。记录：
- 第 1 天：构建了什么
- 第 2 天：构建了什么
- 等等。

This is the most honest data you will ever have about your production rate. Do not
skip it. It feeds directly into sprint planning (at `workflow: minimal`, which has
no sprints, into the brief's build order).

这是你关于生产速率所能拥有的最诚实的数据。不要
跳过它。它直接输入冲刺规划（在 `workflow: minimal` 下没有
冲刺，则输入简报的构建顺序）。

Read `.claude/docs/templates/vertical-slice-report.md` to get the report structure.
If the template file is not found, use this fallback structure:
- `## Vertical Slice Report — [Game Title] — [Date]`
- `### Executive Summary` (PROCEED / PIVOT / KILL / NOT ASSESSED verdict + 2-sentence rationale)
- `### Core Loop Validation` (what was tested, what passed, what failed)
- `### Feel Assessment` (animation, controls, feedback — subjective notes)
- `### Technical Findings` (performance, engine issues, architectural risks)
- `### Velocity Log` (day-by-day actual progress — do not skip)
- `### Lessons Learned` (assumptions broken by building to near-production
  quality; what surprised us about the pipeline or architecture; what we would
  change about the slice scope next time)
- `### Recommended Next Steps`

读取 `.claude/docs/templates/vertical-slice-report.md` 以获取报告结构。
若未找到模板文件，使用此回退结构：
- `## Vertical Slice Report — [Game Title] — [Date]`
- `### Executive Summary`（PROCEED / PIVOT / KILL / NOT ASSESSED 裁决 + 2 句理由）
- `### Core Loop Validation`（测试了什么、什么通过、什么失败）
- `### Feel Assessment`（动画、操作、反馈——主观笔记）
- `### Technical Findings`（性能、引擎问题、架构风险）
- `### Velocity Log`（逐日实际进度——不要跳过）
- `### Lessons Learned`（构建到接近生产质量时被打破的假设；
  管线或架构中让我们意外的地方；下次我们会
  如何改变切片范围）
- `### Recommended Next Steps`

Fill in every section based on what was observed and built during this session.
The velocity log must reflect actual day-by-day progress, not estimates — this is
the most honest production rate data you will ever have. Replace all placeholder
text with real observations. The recommendation carries the Phase 5 verdict,
NOT ASSESSED included, with its reason.

基于本会话观察和构建的内容填写每个章节。
速度日志必须反映实际的逐日进度，而非估计——这是
你所拥有的最诚实的生产速率数据。用真实观察替换所有占位
文本。建议承载阶段 5 的裁决，
包括 NOT ASSESSED，并附理由。

Ask: "May I write this report to
`prototypes/[concept-name]-vertical-slice/REPORT.md` and add its row to
`prototypes/index.md`?"

询问："我可以把这份报告写入
`prototypes/[concept-name]-vertical-slice/REPORT.md`，并把其行添加到
`prototypes/index.md` 吗？"

If yes, write the file. Then update `prototypes/index.md` (create if it does not
exist) — append one row to the vertical slice table: concept name, date, verdict,
and a link to the REPORT.md. Note whether this was a first-run slice or a re-run
after a PIVOT. The velocity log in this report is some of the most valuable data in
the project — cross-reference it with sprint estimates.

若是，写入该文件。然后更新 `prototypes/index.md`（若不存在则
创建）——向垂直切片表追加一行：概念名称、日期、裁决，
以及指向 REPORT.md 的链接。注明这是首次运行切片还是 PIVOT 之后的
重跑。本报告中的速度日志是项目中最有价值的部分数据
——将其与冲刺估算交叉参照。

---

## Phase 7: Creative Director Review

## 阶段 7：创意总监评审

**Review mode check:**
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode."
- `lean` → skip (not a PHASE-GATE). Note: "CD-PLAYTEST skipped — Lean mode."
- `full` → spawn `creative-director` via `Agent` using gate **CD-PLAYTEST**
  (`.claude/docs/director-gates/cd-playtest.md`) — unless the slice's verdict is
  NOT ASSESSED: with no playthrough there is nothing to review, so note
  "CD-PLAYTEST skipped — the slice has not been played yet."

**评审模式检查：**
- `solo` → 跳过。注明："CD-PLAYTEST skipped — Solo mode."
- `lean` → 跳过（不是 PHASE-GATE）。注明："CD-PLAYTEST skipped — Lean mode."
- `full` → 通过 `Agent` 使用门禁 **CD-PLAYTEST**
  （`.claude/docs/director-gates/cd-playtest.md`）生成 `creative-director`——除非切片的裁决是
  NOT ASSESSED：没有试玩就无可评审，因此注明
  "CD-PLAYTEST skipped — the slice has not been played yet."

Pass: the full REPORT.md content, the validation question, game pillars and core
fantasy from `design/gdd/game-concept.md` (or the pitch and "what they feel" line
from `design/game-brief.md` at `rigor: minimal`).

传入：完整的 REPORT.md 内容、验证问题、来自 `design/gdd/game-concept.md`
的游戏支柱与核心幻想（或在 `rigor: minimal` 下，来自 `design/game-brief.md`
的卖点与"他们的感受"一句）。

The creative director evaluates the vertical slice result against the game's
creative vision and pillars and returns one of the gate's verdicts — APPROVE,
CONCERNS or REJECT. Apply it to the recommendation:

创意总监依据游戏的创意愿景与支柱评估垂直切片结果，
并返回该门禁的裁决之一——APPROVE、
CONCERNS 或 REJECT。将其应用到建议上：

- **APPROVE** → the recommendation stands.
- **CONCERNS** → show the concerns alongside the recommendation, then use
  `AskUserQuestion`: `Revise the recommendation` / `Accept with noted concerns` /
  `Discuss further`. The user decides; the director does not.
- **REJECT** (the core fantasy is not present) → a PROCEED recommendation cannot
  stand. Use `AskUserQuestion` to ask the user to choose `PIVOT` or `KILL`, and run
  Phase 8 for that choice. A PIVOT or KILL recommendation stands.
- **NOT ASSESSED** [missing input] → the director made no judgement, so it neither
  backs nor overturns the recommendation (`.claude/docs/director-gates.md`): name
  what was missing, then supply it and re-run the gate, or record
  `CD-PLAYTEST: NOT ASSESSED — [input]` in the report.

- **APPROVE** → 建议维持不变。
- **CONCERNS** → 将顾虑与建议并列展示，然后使用
  `AskUserQuestion`：`Revise the recommendation` / `Accept with noted concerns` /
  `Discuss further`。由用户决定；总监不决定。
- **REJECT**（核心幻想不存在）→ PROCEED 建议不能
  维持。使用 `AskUserQuestion` 请用户选择 `PIVOT` 或 `KILL`，并针对该选择运行
  阶段 8。PIVOT 或 KILL 建议维持不变。
- **NOT ASSESSED** [缺失输入] → 总监未作判断，因此它既不
  支持也不推翻建议（`.claude/docs/director-gates.md`）：指明
  缺失了什么，然后补齐并重新运行门禁，或在报告中记录
  `CD-PLAYTEST: NOT ASSESSED — [input]`。

When the director returned CONCERNS, REJECT or NOT ASSESSED, ask "May I update
`prototypes/[concept-name]-vertical-slice/REPORT.md` and its
`prototypes/index.md` row?", then record the director's verdict and reason in
REPORT.md, and the final recommendation in both if it changed.

当总监返回 CONCERNS、REJECT 或 NOT ASSESSED 时，询问"我可以更新
`prototypes/[concept-name]-vertical-slice/REPORT.md` 及其
`prototypes/index.md` 行吗？"，然后在
REPORT.md 中记录总监的裁决与理由，若最终建议发生变化，则在两处都记录。

---

## Phase 8: Summary and Next Steps

## 阶段 8：总结与后续步骤

Output a summary: the validation question, velocity data, and final recommendation.
Link to `prototypes/[concept-name]-vertical-slice/REPORT.md`.

输出一份总结：验证问题、速度数据，以及最终建议。
链接到 `prototypes/[concept-name]-vertical-slice/REPORT.md`。

**If PROCEED:**
Your vertical slice validated the full game loop. The project is ready for
Production.

**若为 PROCEED：**
你的垂直切片验证了完整的游戏循环。项目已准备好进入
Production。

At `workflow: minimal`: `/create-stories` (from the brief), then `/dev-story`
on the first story — the rest of this list is the `standard`/`full` path.

在 `workflow: minimal` 下：`/create-stories`（基于简报），然后对第一个故事
运行 `/dev-story`——本列表的其余部分是 `standard`/`full` 路径。

Recommended next steps (`standard`/`full`):
- `/create-epics layer:foundation` — plan Foundation layer epics
- `/create-epics layer:core` — plan Core layer epics
- `/create-stories [epic-slug]` — break each epic into implementable stories
- `/sprint-plan` — plan the first sprint using velocity data from the slice
- `/gate-check production` — formally advance the stage to Production

推荐的后续步骤（`standard`/`full`）：
- `/create-epics layer:foundation` — 规划 Foundation 层的史诗
- `/create-epics layer:core` — 规划 Core 层的史诗
- `/create-stories [epic-slug]` — 将每个史诗拆分为可实现的故事
- `/sprint-plan` — 使用切片的速度数据规划第一个冲刺
- `/gate-check production` — 正式将阶段推进到 Production

**Playtest note:** `/gate-check` will look for documented playtest evidence.
At minimum, 1 documented session with a REPORT.md showing PROCEED is required
to pass the gate. More sessions give more reliable signal — 3+ is recommended
before committing the full team to Production, but is not a hard gate.

**试玩说明：** `/gate-check` 会查找有记录的试玩证据。
至少要 1 次有记录的会话，且 REPORT.md 显示 PROCEED，才能
通过门禁。更多会话给出更可靠的信号——在投入整个团队进入 Production 之前建议 3 次以上，
但这并非硬性门禁。

**If PIVOT:**

**若为 PIVOT：**

Before routing back to GDD revision, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

在返回 GDD 修订之前，先捕获结转笔记。逐个
询问以下两个问题（纯文本，一次一个）：

1. "What systems or mechanics worked at this quality level and should be preserved in the revised design?"
2. "What specifically failed — the core loop, the architecture, the pipeline, or the fun?"

1. "哪些系统或机制在这个质量水平上奏效，应当在修订后的设计中保留？"
2. "具体是什么失败了——核心循环、架构、管线，还是乐趣？"

Ask: "May I write this to `prototypes/[concept-name]-vertical-slice/PIVOT-NOTE.md`?"

询问："我可以把这些写入 `prototypes/[concept-name]-vertical-slice/PIVOT-NOTE.md` 吗？"

If yes, write the file with: what worked, what failed, the specific systems or
architecture decisions that need revision, and what the next slice should prove
differently. When `/vertical-slice` is next run after a PIVOT, check the
`prototypes/` directory for a `PIVOT-NOTE.md` — use it to frame the new validation
question and inform scope decisions.

若是，写入该文件，内容包括：什么奏效、什么失败、需要修订的具体系统或
架构决策，以及下一次切片应当以不同方式证明什么。当下次在 PIVOT 之后运行
`/vertical-slice` 时，检查
`prototypes/` 目录中是否有 `PIVOT-NOTE.md`——用它来框定新的验证
问题并指导范围决策。

- Revise affected GDDs with `/design-system [mechanic]`
- Address architecture issues via `/architecture-decision`
- Then re-run `/vertical-slice` to validate the revised direction

- 用 `/design-system [mechanic]` 修订受影响的 GDD
- 通过 `/architecture-decision` 处理架构问题
- 然后重新运行 `/vertical-slice` 验证修订后的方向

**If KILL:**

**若为 KILL：**

Before abandoning the concept, confirm the verdict is sound:

在放弃该概念之前，确认裁决是可靠的：

- [ ] Full game loop takes >5 minutes even for an experienced player?
- [ ] No emotional high point (delight, surprise, satisfaction) observed in any playtest session?
- [ ] 50%+ of testers confused or stuck at the same point after 2+ slice attempts?
- [ ] Architecture issues would require rebuilding more than 50% of what was built?
- [ ] This is the 3rd vertical slice attempt on the same concept?

- [ ] 即便是经验丰富的玩家，完整游戏循环也要超过 5 分钟？
- [ ] 在任何试玩会话中都未观察到情绪高点（愉悦、惊喜、满足）？
- [ ] 在 2 次以上切片尝试后，50%+ 的测试者在同一点困惑或卡住？
- [ ] 架构问题将需要重建已构建内容的 50% 以上？
- [ ] 这是同一概念的第三次垂直切片尝试？

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → one targeted PIVOT may recover the concept.

若勾选 2 项以上 → KILL 裁决是可靠的。若勾选 0–1 项 → 一次有针对性的 PIVOT 或许能挽救该概念。

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

**在 `prototypes/GRAVEYARD.md` 中记录这次终止**（若不存在则创建）。
询问："我可以把它追加到 `prototypes/GRAVEYARD.md` 吗？"若是，添加一条记录：

```
## [Concept Name] Vertical Slice — YYYY-MM-DD
- **Kill reason:** [what specifically prevented the player from experiencing the core fantasy]
- **What worked at slice quality:** [systems or mechanics that held up]
- **What failed:** [core loop issue, architecture decision, or pipeline blocker]
- **Next time:** [one specific change for the next time a similar concept is attempted]
```

- Return to `/brainstorm` with what you learned
- Or run `/prototype [new-concept]` to test a new direction cheaply first

- 带着所学回到 `/brainstorm`
- 或运行 `/prototype [new-concept]`，先低成本地测试一个新方向

**If NOT ASSESSED:**

**若为 NOT ASSESSED：**

The slice is built but not validated. Say which reason applied, then finish the
Phase 5 playthrough and debrief — the `production/session-state/active.md`
checkpoint is where to resume — and, after asking, update REPORT.md and its
`prototypes/index.md` row with the verdict. Do not take the slice to
`/gate-check production` as if it had passed: NOT ASSESSED is not a PROCEED.

切片已构建但未验证。说明适用了哪条原因，然后完成
阶段 5 的通关与复盘——`production/session-state/active.md`
检查点即是恢复之处——并在询问后，更新 REPORT.md 及其
`prototypes/index.md` 行的裁决。不要像已通过那样把该切片带到
`/gate-check production`：NOT ASSESSED 不是 PROCEED。

---

### Important Constraints

### 重要约束

- Vertical slice code must NEVER be refactored into production — it is reference only
- Production code must NEVER import from `prototypes/`
- If recommendation is PROCEED, production implementation is written from scratch
  using the slice as a design reference only
- Scope cuts are acceptable; quality cuts are not — a low-quality slice proves nothing
- Total effort: 1–3 weeks. If longer, scope is too large — cut the slice, not the quality.
- Day 3 sunk cost rule: if the full game loop cycle is not demonstrable by then,
  stop and surface the blocker
- **Networked/multiplayer games:** A local vertical slice cannot validate the feel
  of a networked mechanic. Latency fundamentally changes how combat, movement, and
  prediction feel — testing locally at 0ms will feel entirely different at 80ms
  network delay. The slice can validate that the game loop is interesting and
  complete; it cannot validate that networked mechanics feel good under real
  conditions. Network feel requires real peers or simulated latency.

- 垂直切片的代码绝不可重构进生产 — 它仅供参考
- 生产代码绝不可从 `prototypes/` 导入
- 若建议为 PROCEED，生产实现需从头编写，
  仅将切片作为设计参考
- 削减范围可以接受；削减质量不可接受 — 低质量切片证明不了任何东西
- 总工作量：1–3 周。若更久，范围太大 — 削减切片，而非质量。
- 第 3 天沉没成本规则：若届时完整的游戏循环周期尚不可演示，
  停下并暴露该阻碍
- **联网/多人游戏：** 本地垂直切片无法验证联网机制的
  感受。延迟从根本上改变了战斗、移动和
  预测的手感——在 0ms 下本地测试与在 80ms
  网络延迟下的感受会完全不同。切片可以验证游戏循环有趣且
  完整；它无法验证联网机制在真实
  条件下手感良好。网络手感需要真实对等端或模拟延迟。
