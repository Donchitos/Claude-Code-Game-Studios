# /prototype — Phase 5: Implement
# /prototype — 第五阶段：实现

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 5: Implement
## 第五阶段：实现

Ask: "May I create the prototype directory at `prototypes/[concept-name]-concept/`
and begin implementation?"

询问："我可以在 `prototypes/[concept-name]-concept/` 创建原型目录并开始实现吗？"

If yes, create the directory. Every file must begin with:

如果同意，就创建该目录。每个文件都必须以以下内容开头：

```
[comment] PROTOTYPE - NOT FOR PRODUCTION
[comment] Question: [Core question being tested]
[comment] Date: [Current date]
```

Write `[comment]` in each file's own comment syntax — `#` in GDScript (`.gd`) and
Python, `//` in C#, C++ and JavaScript, `--` in Lua, `<!-- … -->` in HTML and
Markdown. A header in another language's syntax is a parse error, not a label.
Files that cannot hold a comment (JSON, engine-generated scene and project
files) are exempt.

用每个文件自身的注释语法书写 `[comment]`——GDScript（`.gd`）和 Python 用 `#`，C#、C++ 和 JavaScript 用 `//`，Lua 用 `--`，HTML 和 Markdown 用 `<!-- … -->`。使用其他语言语法的头是解析错误，而不是标签。无法容纳注释的文件（JSON、引擎生成的场景和项目文件）不受此要求约束。

Standards are intentionally relaxed:

标准是有意放宽的：

- Hardcode values freely
- 可随意硬编码数值
- Use placeholder assets (colored rectangles, debug shapes)
- 使用占位资源（彩色矩形、调试形状）
- Skip error handling entirely
- 完全跳过错误处理
- Use the simplest approach that works
- 使用能起作用的最简单方案
- Copy code rather than importing from production
- 复制代码，而不是从生产代码中导入
- No architecture, no patterns, no abstractions
- 不要架构、不要模式、不要抽象

**Do not add polish.** No menus, no game over screens, no music, no tutorial text
unless the tutorial IS the mechanic being tested. Every addition beyond the
hypothesis is waste.

**不要添加打磨。** 不要菜单、不要游戏结束界面、不要音乐、不要教程文字，除非教程本身就是被测试的机制。任何超出假设的新增都是浪费。

**Playtesting tip:** If you have access to anyone who hasn't seen the game —
friends, family, strangers online — watching them play without explanation gives
far better signal than testing it yourself. Watch silently; don't guide them.
Confusion is data. Ask one question after: "What was confusing?" Not "Did you
like it?"

**试玩建议：** 如果你能接触到任何没见过这个游戏的人——朋友、家人、网上的陌生人——在不解释的情况下观察他们游玩，会比自己测试得到好得多的信号。安静观察；不要引导他们。困惑就是数据。事后只问一个问题："哪里让你困惑？"而不是"你喜欢它吗？"

**No external testers available?** Use rotation: if you built system A, you're a
naive tester for system B. In a two-person team this works well. Solo developer?
Step away for 2-3 days before playing fresh — you won't have perfect first-impression
signal, but you'll surface the worst blockers. Another option: play your own
prototype as a speedrun (force yourself through it in 5 minutes without stopping
to fix things) — the friction you feel is what strangers will hit.

**没有外部测试者？** 使用轮换：如果你构建了系统 A，那么对系统 B 来说你就是一个无先入之见的测试者。在两人团队中这很有效。独自开发？先离开 2-3 天再以全新状态游玩——你不会得到完美的第一印象信号，但会暴露出最糟糕的阻塞点。另一个选择：把自己的原型当作速通来玩（强迫自己在 5 分钟内通关，中途不停下来修东西）——你感受到的摩擦就是陌生人会遇到的。

**Want more granular UX data?** Ask the tester to **think aloud** as they play —
narrate their thoughts in real time: "I'm pressing space... nothing happened... is
that the jump key?" This surfaces confusion the moment it happens rather than
waiting for a post-play debrief. Best for UI/UX and onboarding clarity. Silent
observation is still better for testing raw feel; think-aloud changes how people
play slightly but gives much richer data about why they're confused.

**想要更细粒度的 UX 数据？** 请测试者边玩边**出声思考**——实时叙述他们的想法："我在按空格……什么也没发生……那是跳跃键吗？"这能在困惑发生的当下就浮现出来，而不必等到试玩后的复盘。最适合 UI/UX 和新手引导的清晰度测试。对于测试原始手感，安静观察仍然更好；出声思考会略微改变玩家的玩法，但能提供更丰富的关于他们为何困惑的数据。

**HTML prototype?** itch.io, Reddit (r/playmygame), and Discord (GMTK, Brackeys)
let you reach strangers today at zero cost — see the distribution options in the
HTML path section above.

**HTML 原型？** itch.io、Reddit（r/playmygame）和 Discord（GMTK、Brackeys）让你今天就能零成本触达陌生人——参见上方 HTML 路径章节的分发选项。

**Testing AI, NPC, or complex system behavior before writing the code?** Use the
**Wizard of Oz** technique: one person plays normally while a second person secretly
controls the NPC, enemy, or system behavior in real time — making the decisions a
human would make, not an algorithm. The player believes it's automated. This lets
you validate whether your AI design *feels right* before writing a single line of
pathfinding or decision tree code. When you observe what responses the human
controller naturally produces, you learn exactly what the AI needs to do.

**要在写代码之前测试 AI、NPC 或复杂系统的行为？** 使用 **Wizard of Oz（绿野仙踪）** 技术：一个人正常游玩，另一个人在幕后实时秘密控制 NPC、敌人或系统行为——做出人类会做的决策，而不是算法的决策。玩家会以为这是自动的。这让你在编写任何一行寻路或决策树代码之前，就能验证你的 AI 设计是否*感觉正确*。当你观察人类控制者自然产生的反应时，你就确切地了解到 AI 需要做什么。

### Engine path: multi-turn loop
### Engine 路径：多轮循环

After writing the initial code:

在写完初始代码之后：

> "The prototype files are written. Run the project in your engine now.
> If there are errors, paste them here and I'll fix them. If it runs,
> describe what you see and whether it feels like it's answering the question."

> "原型文件已写好。现在在你的引擎中运行这个项目。如果有错误，粘贴到这里，我来修复。如果它能运行，描述你看到的内容，以及它感觉上是否在回答那个问题。"

Iterate until the prototype is playable. Each loop:
1. User runs → reports errors or observations
2. Agent fixes errors or adjusts the mechanic
3. Repeat until playable or sunk cost rule triggers

不断迭代，直到原型可游玩。每一轮循环：
1. 用户运行 → 报告错误或观察结果
2. 智能体修复错误或调整机制
3. 重复，直到可游玩或沉没成本规则触发

### HTML path: single output
### HTML 路径：单一输出

Write a single `prototype.html` to `prototypes/[concept-name]-concept/`. Include
all styles, logic, and assets inline. The file must be openable by double-clicking
with no server required.

向 `prototypes/[concept-name]-concept/` 写入单个 `prototype.html`。将所有样式、逻辑和资源内联。该文件必须能双击打开，无需服务器。

### Paper path: document + log
### Paper 路径：文档 + 日志

Write `prototypes/[concept-name]-concept/rules.md` (the game rules) and
`prototypes/[concept-name]-concept/play-log.md` (a simulated session walking
through one complete play cycle step by step with dice rolls, decisions, and
outcomes narrated).

写入 `prototypes/[concept-name]-concept/rules.md`（游戏规则）和
`prototypes/[concept-name]-concept/play-log.md`（一次模拟会话，逐步走过一个完整的游玩循环，并叙述骰子掷数、决策和结果）。

---
