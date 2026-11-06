# /prototype — Phase 1: Define the Question
# /prototype — 第一阶段：定义问题

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 1: Define the Question
## 第一阶段：定义问题

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类目始终提示）。

**Check for spike mode:** If `--spike` was passed, skip to the **Spike Mode** section
at the bottom of this skill.

**检查 spike 模式：** 如果传入了 `--spike`，请跳转到本技能末尾的 **Spike 模式** 章节。

**Check for a carry-forward note:** Glob `prototypes/*/PIVOT-NOTE.md`. If one
exists for this concept (or an earlier version of it), read it and start from its
revised hypothesis instead of forming one from scratch — say which note you used.

**检查是否有结转说明：** 用 Glob 查找 `prototypes/*/PIVOT-NOTE.md`。如果该概念（或它的早期版本）存在这样一份说明，请阅读它，并从其中修订后的假设出发，而不是从零开始构建假设——并说明你使用的是哪一份说明。

Then, unless `--spike` sent you to Spike Mode, use `AskUserQuestion` to confirm
intent before proceeding — with or without a carry-forward note:

接下来，除非 `--spike` 已把你送到 Spike 模式，否则在继续之前使用 `AskUserQuestion` 确认意图——无论是否存在结转说明：

- **Prompt**: "How would you like to use this prototype session?"
- **提示**："你希望如何使用这次原型会话？"
- **Options**:
- **选项**：
  - `Prototype this concept` — build a throwaway build to validate the core idea is fun before writing GDDs (1 day at most)
  - `Prototype this concept` — 构建一个一次性版本，在编写 GDD 之前验证核心想法是否有趣（最多 1 天）
  - `Skip — concept already proven` — I have enough evidence this works; log it and proceed directly to design
  - `Skip — concept already proven` — 我已有足够证据证明这可行；记录下来，直接进入设计
  - `Mid-production spike` — I'm already in Production and want to test a specific mechanic or technical question quickly (~4 hours, no phase gate implications)
  - `Mid-production spike` — 我已经处于量产阶段，想快速测试某个具体机制或技术问题（约 4 小时，不涉及阶段门禁影响）

**If "Skip — concept already proven":**
Ask (plain text, not a widget): "What evidence do you have that the concept works?"
Record the one-line answer, then stop. Note: "Concept prototype skipped — evidence:
[answer]." Suggest next step: `/map-systems` or `/design-system [mechanic]`.

**如果选择 "Skip — concept already proven"：**
询问（纯文本，不用交互组件）："你有什么证据表明这个概念可行？"
记录一句话的答案，然后停止。注明："概念原型已跳过——证据：[answer]。"建议下一步：`/map-systems` 或 `/design-system [mechanic]`。

**If "Mid-production spike"**: skip to the **Spike Mode** section below.

**如果选择 "Mid-production spike"**：跳转到下方的 **Spike 模式** 章节。

**If "Prototype this concept"**: continue with Phase 1 below.

**如果选择 "Prototype this concept"**：继续下面的第一阶段。

---

**A note on prototype strategy:** The research on successful indie development
is consistent — building 2-3 concept variants and letting the best one win is
far more likely to succeed than iterating one concept until it works. This is
your first prototype, not necessarily your only one. If this prototype produces
a PIVOT verdict, consider whether to refine this concept OR start fresh with a
different angle on the same game idea and prototype that instead.

**关于原型策略的说明：** 对成功独立游戏开发的研究结论是一致的——构建 2-3 个概念变体并让最好的那个胜出，远比反复迭代同一个概念直到它可行更容易成功。这是你的第一个原型，但不一定是你唯一的原型。如果这个原型得出的是 PIVOT（转向）判定，请考虑是精炼这个概念，还是针对同一个游戏创意换一个角度重新开始并转而制作那个原型。

**Game jam as a prototype vehicle:** If you're planning a concept prototype anyway,
consider timing it to a game jam (Ludum Dare, GMTK Game Jam, Global Game Jam). Jams
provide a forced timebox (48-72 hours), instant distribution to thousands of players
who rate and review early builds, and a deadline that prevents scope creep by design.
Many shipped games (Celeste, VVVVVV) began as jam prototypes. Not required — but
worth considering if the timing is right.

**把 Game Jam 作为原型载体：** 如果你反正要规划一次概念原型，可以考虑把时间安排在某个 game jam（Ludum Dare、GMTK Game Jam、Global Game Jam）期间。Game jam 提供强制的时间盒（48-72 小时）、向成千上万名会为早期版本打分和评审的玩家即时分发，以及从设计上防止范围蔓延的截止期限。许多已上市的游戏（Celeste、VVVVVV）最初都是 game jam 原型。这不是必需的——但如果时间合适，值得考虑。

Read the concept description from the argument. Before building anything, define
the **falsifiable hypothesis** this prototype must answer:

从参数中读取概念描述。在构建任何东西之前，先定义这个原型必须回答的**可证伪假设**：

> *"If the player [does X], they will feel [Y] — we will know this is true if [measurable signal Z]."*

> *"如果玩家 [做 X]，他们会感到 [Y]——如果 [可测量的信号 Z]，我们就知道这是真的。"*

Good: "If the player swings on grapple hooks, traversal will feel fluid — we'll know if
players chain 3+ swings without stopping within 2 minutes of picking it up."

好的例子："如果玩家用抓钩摆荡，移动会感觉流畅——如果玩家在拿到抓钩后 2 分钟内能连续完成 3 次以上不间断的摆荡，我们就知道这一点成立。"

Bad: "Does this feel fun?" ← not testable, not falsifiable.

糟糕的例子："这好玩吗？" ← 既不可测试，也不可证伪。

**If the concept is too vague to form a hypothesis, stop here.** Ask the user to
narrow the question before proceeding. A prototype without a clear question wastes time.

**如果概念过于模糊，无法形成假设，请在此停止。** 请用户先缩小问题范围再继续。没有清晰问题的原型只是在浪费时间。

Also ask: **"What is the riskiest assumption in this concept?"** That is the first
thing the prototype should test — not the easiest part, the riskiest.

还要问：**"这个概念中风险最大的假设是什么？"** 这才是原型应该首先测试的东西——不是最简单的部分，而是风险最大的部分。

---
