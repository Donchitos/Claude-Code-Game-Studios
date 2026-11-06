# /prototype — Phase 3: Choose the Prototype Path
# /prototype — 第三阶段：选择原型路径

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 3: Choose the Prototype Path
## 第三阶段：选择原型路径

**In this file:**

**本文件内容：**

- Path: HTML (browser-playable)
- 路径：HTML（可在浏览器中游玩）
- Path: Engine (engine project)
- 路径：Engine（引擎项目）
- Path: Paper (rules document + play log)
- 路径：Paper（规则文档 + 游玩日志）

Select the prototype path. If `--path [html|engine|paper]` was passed, use that.
Otherwise, use this quick-reference first, then read the full path details below:

选择原型路径。如果传入了 `--path [html|engine|paper]`，就使用该值。否则，先使用下面的快速参考表，然后再阅读下方完整的路径细节：

| Genre | Recommended path | Key reason |
|-------|-----------------|------------|
| Platformer / action / fighter | **Engine** | Feel IS the hypothesis; browser latency produces false results |
| Racing / sports | **Engine** | Same — timing and physics feedback are the point |
| Top-down shooter / twin-stick | **Engine** | Aim feel is timing-sensitive |
| Puzzle (logic) | **HTML** or **Paper** | Timing is not the point; logic and clarity are |
| Card game | **Paper** first | Fastest iteration by hand before touching code |
| Narrative / visual novel | **Paper** (Twine / Ink / Yarn Spinner) | Story is the mechanic — test it without code overhead |
| Strategy / 4X / city builder | **Paper** (spreadsheet sim) | Validate economy and progression rules before building |
| Roguelike (systems-heavy) | **Paper** → Engine | Validate that the ruleset is interesting before building |
| Idle / clicker / incremental | **HTML** | Turn-based logic, no feel sensitivity required |
| Rhythm game | **Paper** first (design levels in audio) | Design levels before the engine exists |
| RPG / open world | **Paper** → Engine | Systems complexity: validate rules, then validate feel |
| Horror / atmospheric | **Engine** | Atmosphere requires real rendering |

| 类型 | 推荐路径 | 关键原因 |
|-------|-----------------|------------|
| 平台跳跃 / 动作 / 格斗 | **Engine** | 手感本身就是假设；浏览器延迟会产生错误结果 |
| 竞速 / 体育 | **Engine** | 同理——时机与物理反馈正是重点 |
| 俯视角射击 / 双摇杆射击 | **Engine** | 瞄准手感对时序敏感 |
| 解谜（逻辑类） | **HTML** 或 **Paper** | 时序不是重点；逻辑与清晰度才是 |
| 卡牌游戏 | 优先 **Paper** | 在写代码之前，手工迭代最快 |
| 叙事 / 视觉小说 | **Paper**（Twine / Ink / Yarn Spinner） | 故事就是机制——无需代码开销即可测试 |
| 策略 / 4X / 城市建造 | **Paper**（电子表格模拟） | 在构建之前验证经济与进程规则 |
| Roguelike（系统繁重） | **Paper** → Engine | 在构建之前验证规则集是否有趣 |
| 放置 / 点击 / 增量游戏 | **HTML** | 回合制逻辑，无需手感敏感性 |
| 音游 | 优先 **Paper**（在音频中设计关卡） | 在引擎存在之前先设计关卡 |
| RPG / 开放世界 | **Paper** → Engine | 系统复杂度：先验证规则，再验证手感 |
| 恐怖 / 氛围类 | **Engine** | 氛围需要真实渲染 |

**Rule of thumb:** "Does this feel right?" → Engine. "Are these rules interesting?" → Paper. "Is this logic correct?" → HTML or Paper.

**经验法则：**"这感觉对吗？"→ Engine。"这些规则有趣吗？"→ Paper。"这个逻辑正确吗？"→ HTML 或 Paper。

### Path: HTML (browser-playable)
### 路径：HTML（可在浏览器中游玩）

**Best for:** Puzzle games, card games, turn-based strategy, word games, idle games,
top-down logic games. Anything where timing precision doesn't matter.

**最适合：** 解谜游戏、卡牌游戏、回合制策略、文字游戏、放置游戏、俯视角逻辑游戏。任何时序精度不重要的场合。

**Reliability:** ~85–90% one-shot. The agent writes a single self-contained HTML
file the user opens in a browser — no install required.

**可靠性：** 一次成功率约 85–90%。智能体编写单个自包含的 HTML 文件，用户在浏览器中打开——无需安装。

**Limitation — browser latency lies about game feel.** Browsers introduce
50–133ms of rendering variance. This makes HTML prototypes fundamentally unreliable
for action games, platformers, fighting games, or anything where input timing,
jump arcs, or collision feel are what you're testing. If feel is the hypothesis,
use the Engine path instead.

**局限——浏览器延迟会让游戏手感失真。** 浏览器会引入 50–133 毫秒的渲染波动。这使 HTML 原型在动作游戏、平台跳跃游戏、格斗游戏，或任何你要测试的是输入时序、跳跃弧线或碰撞手感的情况下，从根本上不可靠。如果手感就是假设，请改用 Engine 路径。

**Alternative tools for this path:** PICO-8 (extreme constraints, great for retro
arcade concepts, web-export in one command), Phaser.js (more capable browser game
framework, still no install needed), or Twine (narrative/choice-based games).
These are faster than raw HTML for their respective genres — suggest them if appropriate.

**此路径的替代工具：** PICO-8（极端约束，非常适合复古街机概念，一条命令即可导出网页版）、Phaser.js（能力更强的浏览器游戏框架，仍然无需安装），或 Twine（叙事/选择类游戏）。对于各自擅长的类型，它们比裸写 HTML 更快——在合适时推荐它们。

**Output:** A single `prototype.html` (or PICO-8/Phaser equivalent) the user opens in any browser.

**输出：** 单个 `prototype.html`（或 PICO-8/Phaser 的等价物），用户可在任意浏览器中打开。

**Distribution — the HTML path's biggest advantage:** Unlike Engine prototypes, this
build can reach real players globally in minutes. Use this actively:
- **itch.io** — upload the file, share the link, get play counts and written feedback
  within hours. Free. The indie community plays rough builds here without expecting
  polish. This is genuine external validation at zero cost.
- **Loom + file share** — share via Google Drive/Dropbox, ask someone to record their
  screen + audio with Loom while playing. You get a video of real first-impression
  reactions and confusion without synchronous scheduling.
- **r/playmygame or r/WebGames** (Reddit) — active communities that specifically
  test early builds and give unsolicited honest feedback.
- **Game dev Discord servers** (GMTK, Brackeys, GameDev.tv) — members test each
  other's prototypes routinely; an HTML file is the easiest possible ask.

**分发——HTML 路径最大的优势：** 与 Engine 原型不同，这个构建可以在几分钟内触达全球的真实玩家。请积极利用：
- **itch.io** —— 上传文件、分享链接，几小时内就能获得游玩次数和文字反馈。免费。独立游戏社区会在这里试玩粗糙的版本，并不期待打磨。这是零成本的真实外部验证。
- **Loom + 文件分享** —— 通过 Google Drive/Dropbox 分享，请某人在游玩时用 Loom 录制屏幕 + 音频。无需同步排期，你就能得到真实第一印象反应和困惑的视频。
- **r/playmygame 或 r/WebGames**（Reddit）—— 专门测试早期版本并主动给出诚实反馈的活跃社区。
- **游戏开发 Discord 服务器**（GMTK、Brackeys、GameDev.tv）—— 成员们经常互相测试原型；HTML 文件是最容易的请求形式。

---

### Path: Engine (engine project)
### 路径：Engine（引擎项目）

**Best for:** Action games, platformers, physics-heavy games, anything where
moment-to-moment feel IS the hypothesis. Use this when HTML latency would lie about
the result.

**最适合：** 动作游戏、平台跳跃游戏、物理密集型游戏，以及任何逐时逐刻的手感本身就是假设的场合。当 HTML 延迟会让结果失真时，使用此路径。

**Reliability:** ~50–60% one-shot. Expect 2–4 rounds of iteration — this is
normal, not a failure.

**可靠性：** 一次成功率约 50–60%。预期会有 2–4 轮迭代——这是正常的，不是失败。

**Limitation — requires engine installed and running.** This path is a
multi-turn collaborative loop:
1. Agent writes the code
2. User runs it in the engine
3. User reports errors or observations
4. Agent fixes and iterates

**局限——需要已安装并可运行的引擎。** 此路径是一个多轮协作循环：
1. 智能体编写代码
2. 用户在引擎中运行
3. 用户报告错误或观察结果
4. 智能体修复并迭代

**Sunk cost rule:** If the user has been iterating for more than 2 hours without
reaching a playable state, stop. The scope is too large or the question is wrong.
Reframe the hypothesis and simplify aggressively, or switch to Paper path.

**沉没成本规则：** 如果用户已迭代超过 2 小时仍未达到可游玩状态，就停止。要么范围太大，要么问题不对。重新构建假设并大幅简化，或者切换到 Paper 路径。

**Output:** A minimal runnable engine project in `prototypes/[name]-concept/`.

**输出：** 一个最小可运行的引擎项目，位于 `prototypes/[name]-concept/`。

**Lighter alternative — Love2D (Lua):** If the project engine (Godot, Unity, Unreal)
feels too heavy to stand up for a throwaway build, consider Love2D — a minimal 2D
framework that installs in minutes, requires no project scaffolding, and renders
natively with no browser latency. Used by many indie devs for rapid 2D action and
platformer prototypes (Balatro prototyped in Love2D; Nuclear Throne's early builds
used it). It sits between HTML overhead and full engine overhead: heavier than
opening a browser, lighter than setting up a full engine project. Best for 2D
action/platformer feel validation when the project engine is 3D-first or takes
significant time to configure.

**更轻量的替代方案——Love2D（Lua）：** 如果项目引擎（Godot、Unity、Unreal）对于一次一次性构建来说过于沉重、很难搭起来，可以考虑 Love2D——一个极简的 2D 框架，几分钟即可安装，无需项目脚手架，且原生渲染、没有浏览器延迟。许多独立开发者用它快速制作 2D 动作和平台跳跃原型（Balatro 曾用 Love2D 做原型；Nuclear Throne 的早期版本也用过它）。它介于 HTML 开销与完整引擎开销之间：比打开浏览器重，比搭建完整引擎项目轻。当项目引擎是 3D 优先或配置耗时较长时，最适合用于 2D 动作/平台跳跃的手感验证。

---

### Path: Paper (rules document + play log)
### 路径：Paper（规则文档 + 游玩日志）

**Best for:** Strategy games, card games, board game-style mechanics, economy
systems, progression loops, any game where the logic can be simulated by hand.
Works for any genre when you need to validate rules, not feel.

**最适合：** 策略游戏、卡牌游戏、桌游式机制、经济系统、进程循环，以及任何逻辑可以手工模拟的游戏。当你需要验证的是规则而非手感时，它适用于任何类型。

**Reliability:** 100%. No code, no engine, no install.

**可靠性：** 100%。无代码、无引擎、无需安装。

**Limitation — cannot validate moment-to-moment feel.** Paper prototypes prove
that the rules are internally consistent and the decisions are interesting. They
cannot tell you whether jumping feels right or whether explosions feel satisfying.

**局限——无法验证逐时逐刻的手感。** Paper 原型能证明规则内部自洽、决策有趣。它们无法告诉你跳跃手感是否正确，或爆炸是否令人满足。

**Paper playtest observation protocol (run this with 5+ people):**
1. Brief the rules once. Hand them the rule summary sheet. Then step back.
2. Do NOT explain further. Do NOT help. Do NOT clarify. Confusion is data.
3. Watch silently. Note every moment they slow down, re-read, or ask a question.
4. After the session, ask one question only: "What was confusing?" — not "Did you like it?"
5. Use fresh testers for each iteration. The same person cannot give new first-impression data.
6. If 3+ testers hit the same confusion point, that rule is broken — redesign it before re-testing.

**Paper 试玩观察流程（用 5 人以上执行）：**
1. 只讲解一次规则。把规则摘要页交给他们。然后退到一边。
2. 不要进一步解释。不要帮忙。不要澄清。困惑就是数据。
3. 安静观察。记录他们每一次放慢、重读或提问的时刻。
4. 会话结束后，只问一个问题："哪里让你困惑？"——而不是"你喜欢它吗？"
5. 每一轮迭代都使用全新的测试者。同一个人无法提供新的第一印象数据。
6. 如果有 3 名以上测试者在同一个困惑点卡住，那条规则就是坏的——在重新测试之前先重新设计它。

**Output:** A printable rules document + a completed play log showing one simulated session.

**输出：** 一份可打印的规则文档 + 一份完整的游玩日志，展示一次模拟会话。

**Narrative tools for this path:** For dialogue-heavy and story-driven games, skip the
generic rules doc — use a dedicated narrative scripting tool instead:
- **Twine** — zero-code hypertext fiction; ideal for branching structure experiments and choice-impact testing
- **Ink** (Inkle) — plain-text scripting language used in *80 Days*, *Heaven's Vault*, and *Overboard*; exports directly to Unity and Godot
- **Yarn Spinner** — dialogue scripting used in *A Short Hike*, *DREDGE*, and *Night in the Woods*; integrates natively with Unity and Godot

**此路径的叙事工具：** 对于对话密集和故事驱动的游戏，跳过通用规则文档——改用专门的叙事脚本工具：
- **Twine** —— 零代码超文本小说；非常适合分支结构实验和选择影响测试
- **Ink**（Inkle）—— 纯文本脚本语言，用于 *80 Days*、*Heaven's Vault* 和 *Overboard*；可直接导出到 Unity 和 Godot
- **Yarn Spinner** —— 对话脚本工具，用于 *A Short Hike*、*DREDGE* 和 *Night in the Woods*；与 Unity 和 Godot 原生集成

All three let you write and playtest branching dialogue in minutes. Key metric for
narrative prototypes: **time to first emotional beat** — how many exchanges before
the player feels something? If it takes more than 3-4 exchanges, the opening is too slow.

这三者都能让你在几分钟内编写并试玩分支对话。叙事原型的关键指标：**到达第一个情感节拍的时间**——玩家在多少次交流之后才会有所感受？如果需要超过 3-4 次交流，那么开场就太慢了。

---

Assess which path best fits the hypothesis, then use `AskUserQuestion` with your
recommendation pre-stated:

评估哪条路径最契合假设，然后使用 `AskUserQuestion`，并预先陈述你的推荐：

- **Prompt**: "Which prototype path would you like to use? (Based on your concept, I'd recommend [path] — [one sentence reason].)"
- **提示**："你想使用哪条原型路径？（根据你的概念，我推荐 [path]——[一句话理由]。）"
- **Options**:
- **选项**：
  - `HTML — browser prototype` — puzzle, card, turn-based, strategy, idle. Opens by double-clicking, no install. 85–90% reliable. **Not suitable for action games** — browser latency lies about feel.
  - `HTML — browser prototype` —— 解谜、卡牌、回合制、策略、放置。双击即可打开，无需安装。85–90% 可靠。**不适合动作游戏**——浏览器延迟会让手感失真。
  - `Engine — native prototype` — action, platformer, physics, or anything where feel IS the hypothesis. 50–60% one-shot; 2–4 iteration rounds are normal. Requires engine installed.
  - `Engine — native prototype` —— 动作、平台跳跃、物理，或任何手感本身就是假设的场合。一次成功率 50–60%；2–4 轮迭代是正常的。需要已安装引擎。
  - `Paper — rules document + play log` — strategy, economy, logic, board-game-style mechanics. 100% reliable. Cannot validate feel.
  - `Paper — rules document + play log` —— 策略、经济、逻辑、桌游式机制。100% 可靠。无法验证手感。

---
