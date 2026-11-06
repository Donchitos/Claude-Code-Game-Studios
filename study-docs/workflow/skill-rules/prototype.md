# prototype — 概念原型验证（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/prototype/SKILL.md)（含 references/1~9 与 spike-mode） ｜ 阶段：Phase 1 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/prototype [concept-description] [--path html|engine|paper] [--review full|lean|solo] [--spike]`
- **一句话职责**：用一次性（throwaway）快速构建回答一个问题——"这个核心创意到底好不好玩？"——产出 PROCEED/PIVOT/KILL/NOT ASSESSED 裁决，决定概念是否值得投入完整设计文档
- **触发前置**：默认在 `/brainstorm` 与 `/setup-engine` 之后、写 GDD/架构文档之前运行；生产中任何阶段可传 `--spike` 进入 spike 模式（~4 小时轻量构建，无 GDD 前置、无阶段门禁影响）。已有 GDD 与架构、想验证完整游戏循环 → 改跑 `/vertical-slice`

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, workflow` | `--review` 覆盖 `review_mode`（本次运行） |
| 读取 | `design/gdd/game-concept.md`（或 `rigor: minimal` 档的 `design/game-brief.md`） | 提取 core fantasy（玩家该感受什么）与 core loop；按节读（Grep `^#` 定标题，Read offset/limit） |
| 读取 | `project.yaml` 的 `engine.name`/`engine.language` | 各字段独立解析；键缺失/为空（含无 `engine:` 块）回退 `CLAUDE.md` 与 `.claude/docs/technical-preferences.md`；`[TO BE CONFIGURED]` 视为未设置 |
| 读取 | Glob `prototypes/*/PIVOT-NOTE.md`、`.claude/docs/templates/prototype-report.md` | 承前笔记（PIVOT 链）；报告结构模板 |
| 产出 | `prototypes/[concept-name]-concept/`（HTML 单文件 / 引擎项目 / rules.md + play-log.md）、`REPORT.md`、`prototypes/index.md` 追加行、`PIVOT-NOTE.md`（PIVOT 时）、`prototypes/GRAVEYARD.md`（KILL 时）、`production/session-state/active.md` checkpoint | spike 模式产出 `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md` |
| 派生智能体 | `creative-director`（CD-PLAYTEST 门禁，`full` 档） | 其余步骤主会话直接执行 |

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 1 定义问题（references/1）**
R1. 每个 AskUserQuestion 遵守 automation-modes（collaborative 恒问 · guided 只问重大 · autonomous 记录后继续）。入口先问本次会话用途：`Prototype this concept`（1 天内验证核心创意）/ `Skip — concept already proven` / `Mid-production spike`（~4 小时，无门禁影响）。
R2. 选 "Skip" 时用纯文本（非 widget）问 "What evidence do you have that the concept works?"，记录一行答案即停，注明 "Concept prototype skipped — evidence: [answer]"，建议 `/map-systems` 或 `/design-system [mechanic]`。选 "Mid-production spike" 跳转 Spike Mode。
R3. 开工前 Glob `prototypes/*/PIVOT-NOTE.md`：本概念（或其早期版本）有笔记则读它、从其 revised hypothesis 起步而非从零假设，并说明用了哪份笔记。
R4. 必须定义**可证伪假设（falsifiable hypothesis）**："If the player [does X], they will feel [Y] — we will know this is true if [measurable signal Z]."（好例："如果玩家荡抓钩，移动会感觉流畅——玩家上手 2 分钟内连荡 3+ 次不停即证"。"Does this feel fun?" 不可测、不可证伪，禁用）。概念太模糊无法成假设 → **停下**，要求用户先收窄问题。
R5. 必问 "What is the riskiest assumption in this concept?"——原型**先测最险的假设，不是最容易的**。
R6. 策略注记：构建 2-3 个概念变体择优（natural selection）远比把一个概念迭代到底更可能成功；可考虑把概念原型对齐 game jam（Ludum Dare/GMTK/Global Game Jam——48-72 小时强制时间盒 + 天然玩家分发）。

**Phase 2 加载概念上下文（references/2）**
R7. 按节读 game-concept（或 brief），只提取 core fantasy 与 core loop；按 R2 表规则解析引擎与语言。

**Phase 3 选择原型路径（references/3）**
R8. `--path` 已传则直接用；否则按假设类型推荐并经 widget 确认（预述推荐理由）。Rule of thumb："Does this feel right?" → Engine；"Are these rules interesting?" → Paper；"Is this logic correct?" → HTML or Paper。类型表：平台/动作/格斗/竞速 → Engine（feel 即假设，浏览器延迟出假结果）；解谜 → HTML 或 Paper；卡牌/桌游式/策略/4X/城建 → Paper 优先；叙事/视觉小说 → Paper（Twine/Ink/Yarn Spinner）；Roguelike/RPG → Paper → Engine（先证规则再证手感）；Idle/点击 → HTML；恐怖氛围 → Engine（需真实渲染）。
R9. **HTML 路径**：单自包含 `prototype.html`，双击可开、无需服务器；一次成功率 ~85–90%。**浏览器 50–133ms 渲染差异使手感失真**——feel 是假设时禁用。分发是最大优势，应主动利用：itch.io（数小时拿到游玩数与文字反馈）、Loom + 网盘（录屏+语音获取真实第一印象）、r/playmygame 或 r/WebGames、游戏开发 Discord（GMTK、Brackeys、GameDev.tv）。可建议 PICO-8/Phaser.js/Twine 替代。
R10. **Engine 路径**：一次成功率 ~50–60%，2–4 轮迭代属正常而非失败；多轮协作循环（agent 写码 → 用户跑 → 报错/观察 → agent 修）。**Sunk cost rule：迭代超 2 小时仍不可玩 → 停**，重构假设并激进简化，或转 Paper。项目引擎太重时可建议 Love2D（Lua，分钟级安装、无脚手架、原生渲染无浏览器延迟）。
R11. **Paper 路径**：100% 可靠，无代码无引擎；**不能验证 moment-to-moment 手感**，只证规则自洽与决策有趣。5+ 人观察协议：讲解规则一次后即退后；**不解释、不帮助、不澄清——confusion is data**；沉默观察并记下每次减速/重读/提问；结束后只问 "What was confusing?"（不问 "Did you like it?"）；每次迭代用全新测试者（同一人给不出新的第一印象数据）；**3+ 测试者卡同一困惑点 → 该规则坏了，重设计再测**。产出 `rules.md` + `play-log.md`（逐步模拟一个完整循环，含掷骰/决策/结果）。叙事原型关键指标：**time to first emotional beat**——超过 3-4 次交换才有情绪即开场太慢。

**Phase 4 计划（references/4）**
R12. 以 3–5 个 bullet 定义最小可行原型：假设是什么；最险假设是什么、本原型如何先测它；回答问题所需的绝对最小内容；**明确砍掉什么**（菜单、存档、错误处理、打磨、架构——全砍）。Scope 纪律：概念原型只测**一个机制**；拿不准就多砍。
R13. 构建前呈现计划并确认，确认中点名 checkpoint 文件："May I record this plan in `production/session-state/active.md`?" 确认后写 checkpoint（目录不存在则创建）：概念名、假设、所选路径、scope bullets、当前阶段（"Phase 5 — Implement"）——多日 Engine 构建跨会话靠它恢复。

**Phase 5 实现（references/5）**
R14. 先问 "May I create the prototype directory at `prototypes/[concept-name]-concept/` and begin implementation?"。每个文件**必须**以三行头开始：`PROTOTYPE - NOT FOR PRODUCTION`、`Question: [被测核心问题]`、`Date:`——用该文件自己的注释语法（GDScript/Python 用 `#`，C#/C++/JS 用 `//`，Lua 用 `--`，HTML/MD 用 `<!-- … -->`）；**用错语言语法是解析错误不是标签**；无法写注释的文件（JSON、引擎生成的场景/项目文件）豁免。
R15. 标准刻意放松：随意硬编码、占位资产（色块/debug 形状）、完全跳过错误处理、最简单可行方案、复制代码而非从生产导入、无架构无模式无抽象。**不加 polish**：无菜单、无 game over、无音乐、无 UI——除非 UI/教程**就是**被测机制；假设之外的每一项添加都是浪费。
R16. 测试技巧：找没见过游戏的人**沉默观察**（不引导；confusion is data；事后只问 "What was confusing?"）；无外部测试者 → 团队轮换（建 A 系统的人当 B 系统的天真测试者）；solo → 离开 2-3 天再玩；或 5 分钟 speedrun 自测（途中不修东西——你感到的摩擦就是陌生人会撞上的）。要更细 UX 数据可请测试者 **think aloud**（实时说出所想）；测原始手感仍以沉默观察为佳。
R17. **Wizard of Oz**：写 AI/NPC/复杂系统代码前，由第二人实时秘密扮演系统行为，验证设计意图"感觉对不对"，并从人类控制者的反应学出系统该产生什么行为。
R18. Engine 路径多轮循环至可玩；HTML 路径单文件输出；Paper 路径写 rules.md + play-log.md。

**Phase 6 试玩复盘（references/6）**
R19. 构建完交回用户收集真实体验，**禁止跳过复盘直接生成报告**——报告质量取决于此处收集的观察。按路径给确切话术（HTML："像新玩家一样玩它，慢慢来，玩完回来"；Paper："通读 rules.md、走一遍 play-log.md，最好找人实际跑一轮"）。
R20. **本会话无人玩过 → 不得索要裁决、不得从构建外观推断裁决**：裁决是 **NOT ASSESSED — built, not played**，照此写报告（先问）并命名下一步。
R21. 用户回来后**一次一问**（等答再问）：① 假设检验（CONFIRMED / PARTIALLY CONFIRMED / REFUTED？）；② 最佳时刻；③ 最差时刻（要具体——不是 "it felt slow" 而是 "跳跃响应半秒，像在对抗操控"）；④ 意外；⑤ 裁决 PROCEED/PIVOT/KILL + 一句理由。回答含糊（"it felt fine"）必须追问具体——模糊观察使报告无用。

**Phase 7 报告（references/7）**
R22. 读模板 `prototype-report.md` 填每个 section，占位文本一律换成真实观察、禁泛泛填充。问 "May I write this report to `prototypes/[concept-name]-concept/REPORT.md` and add its row to `prototypes/index.md`?" 后写盘并更新 index（不存在则创建）：概念名、日期、所用路径、裁决（PROCEED/PIVOT/KILL，或无人玩时的 NOT ASSESSED）、REPORT 链接；存在 PIVOT 链则注明——index 是项目"试过什么、学到什么"的完整历史。

**Phase 8 创意总监审查（references/8）** — 见 §4 门禁。

**Phase 9 总结与后续（references/9）**
R23. **PROCEED**：`workflow: minimal` → `/create-stories`（从 brief）再 `/dev-story` 首个 story；`standard`/`full` 推荐顺序：`/design-review design/gdd/game-concept.md` → `/gate-check` → `/art-bible`（可选但建议在 GDD 前）→ `/map-systems` → `/design-system [mechanic]`（把原型所学用于 Tuning Knobs 与 Formulas 节）→ `/review-all-gdds`。HTML 路径后手感仍不确定 → 写 GDD 前先做一个针对手感的引擎路径小原型。
R24. **PIVOT**：先按次序问两问（纯文本）："本原型有什么值得在下一版保留？"、"最重要的单一改动是什么？"；问 "May I write this to …/PIVOT-NOTE.md?" 后写入：原假设、保留项、改动项、修订假设——下次 `/prototype` 在 Phase 1 自动拾起。随后跑 `/prototype [revised-concept]`，或概念需更根本重思时跑 `/brainstorm [hint]`。
R25. **KILL 前先确认裁决成立**（防一时挫败）：核心机制 2+ 次试玩后测试者仍不懂？任何 session 都观察不到 fun moment（微笑/大笑/主动重试）？同一概念 3+ 次 PIVOT 迭代无明确改善？概念只在大量解释或开发者引导下才成立？做它像义务而非兴奋？——**2+ 项成立 → KILL 成立；0–1 项 → 考虑再做一次聚焦 PIVOT**。KILL 后问 "May I append this concept to `prototypes/GRAVEYARD.md`?"，按固定条目写入（Kill reason 要具体阻塞器 / What worked 2-3 条 / What failed / Next time 一条明确动作）——该文件的存在是让同一错误不在下一个概念上重犯。然后 `/brainstorm open` 或新 hint。
R26. **NOT ASSESSED**：无乐趣证据，PROCEED/PIVOT/KILL 全部不可达——报告 NOT ASSESSED 并停，不得猜测；玩过后再跑 `/prototype [same concept]`；报告与 index 行在 playtest 发生前保持 NOT ASSESSED。

**Spike Mode（references/spike-mode）**
R27. 触发：`--spike` 或 Phase 1 选 "Mid-production spike"。适用：测新机制是否该加、技术方案是否可行、设计变更前后对比、GDD 难点先行验证、性能 spike。**无 GDD 前置、无阶段门禁影响、硬上限 ~4 小时**；替代 Phase 1–9 全流程。
R28. 流程：① 纯文本定义问题（一句话 "Can we [do X] using [approach Y]?"）；② 同 Phase 3 widget 选路径；③ Scope 最多 2-3 bullets（一个机制、一个技术问题，别无其它）；④ 先问 "May I create `prototypes/[concept-name]-spike-[date]/` and build the spike there?"，同概念原型的放松标准与文件头；4 小时内演示不了 = 问题太大，拆分；⑤ 问 "Did the spike answer the question? YES or NO, and why in one sentence."（无正式复盘）；⑥ 一次性请求两步："May I write SPIKE-NOTE.md and clear the spike from `production/session-state/active.md`?"——note 含问题、结果（YES / NO / PARTIAL — needs more investigation）、下一步（add to current sprint（`minimal` 档为 brief 的 build order）/ investigate further / abandon）；⑦ 更新 active.md 清除 spike 回到当前 sprint 状态。
R29. **无 CD 门禁、无阶段门禁、无 PROCEED/PIVOT/KILL**——spike 结果为决策提供输入，不做决策；是否把机制/方案加入 backlog 由开发者决定。
R30. **Performance spike 特例**：大开放世界、大量物理体、重型粒子、复杂着色器的游戏，应在写玩法代码前先确认目标硬件撑得住帧率。问题形式是 "can the engine render [scene X] at 60fps on [minimum spec hardware]?"（不是"好玩吗"）；输出是基准数字不是手感裁决；无需玩法逻辑，只搭最大预期场景负载（地形、draw call、物理对象、粒子）；仍在 ~4 小时内（spike 只搭渲染负载不搭游戏）；**若该 scope 下答案是 NO，这是影响下游一切的架构/范围约束——现在浮出好过 Sprint 8 才发现**。

**硬约束（SKILL.md 主体）**
R31. 原型代码**绝不** import 生产源文件；生产代码**绝不** import 原型目录；PROCEED 时生产实现**从零写**——原型代码**绝不**被重构进生产。总工作量硬上限 **1 天**（概念原型测一个机制）；scope 膨胀 → 停下简化问题。引擎迭代卡 2 小时 → 重构问题或换路径。**3 次 PIVOT 迭代 → 强制 KILL 决策**，问 "Is this the right idea, or am I in the sunk cost trap?"——新概念的全新原型几乎总是胜过挣扎概念的第四次迭代。
R32. **网络/多人游戏**：本地原型无法验证网络机制手感——0ms 本地与 80ms 网络延迟下的战斗/移动/预测手感完全不同。本地原型只用于验证机制"有趣"，**不得**作为"网络下手感好"的证据；网络手感需真实 peer 或模拟延迟（限流工具、网络状况模拟器）。

## 4. 门禁与裁决
- **CD-PLAYTEST**（创意总监审查，Phase 8）：`solo` → 跳过并注记 "CD-PLAYTEST skipped — Solo mode."；`lean` → 跳过（非 PHASE-GATE）并注记 "…Lean mode."；`full` → spawn `creative-director`——前提是 `design/gdd/game-concept.md` 有 pillars 或 `design/game-brief.md` 存在（brief 无 pillars 时其 pitch 与 "what they feel" 行顶替）；两者皆无 → 注记 "CD-PLAYTEST skipped — game pillars not yet defined at concept prototype stage."。传入：完整 REPORT.md、原假设、pillars/core fantasy。
- **裁决应用**：APPROVE → 建议成立。CONCERNS → 与建议并列展示，AskUserQuestion 三选（`Revise the recommendation` / `Accept with noted concerns` / `Discuss further`）——**用户决定，总监不决定**。REJECT（core fantasy 不在场）→ PROCEED 建议不能成立；AskUserQuestion 让用户选 PIVOT 或 KILL 并按该选择跑 Phase 9；PIVOT/KILL 建议不受影响。NOT ASSESSED（总监缺输入）→ **不是批准**：命名缺失输入、补齐重跑，或记录 NOT ASSESSED 由用户决定建议是否成立。
- CONCERNS/REJECT/NOT ASSESSED 时问 "May I update REPORT.md and its `prototypes/index.md` row?" 后记录总监裁决与理由（及变化后的最终建议）。
- **裁决词**：PROCEED / PIVOT / KILL / NOT ASSESSED；假设检验词：CONFIRMED / PARTIALLY CONFIRMED / REFUTED；3 PIVOT → 强制 KILL。

## 5. 移植建议
- **可直接移植**：R4-R5（可证伪假设+先测最险假设）、R12（3-5 bullet 最小计划+明确砍掉项）、R14-R15（抛弃式构建的文件头标记与放松标准）、R19-R21（复盘一次一问+NOT ASSESSED 防推断）、R22（写盘前先问+历史索引）、R24-R25（PIVOT-NOTE 承前/GRAVEYARD 复盘）、R26-R29（spike 模式）、R31（原型与生产代码隔离）。
- **需替换概念**：游戏机制 → 产品的核心交互/核心价值主张；"fun" 假设 → "用户会完成关键行为/感受到价值"的假设；HTML/Engine/Paper 三路径 → 可运行的等价物（原型工具 vs 生产栈 vs 纸面推演/表格模拟）；game jam → 黑客马拉松/产品 sprint 演示日；`prototypes/index.md` 与 `GRAVEYARD.md` → 实验登记表与"墓园"复盘文件；creative-director → 创意/品牌负责人。
- **改写示例**：
  - "每个原型开工前必须写出可证伪假设：'如果用户 [做 X]，他们会 [感到 Y]——当且仅当 [可测信号 Z] 出现即成立'。禁止'好不好用'这类不可证伪的问法；概念太模糊无法成假设时，先停下收窄问题，再动手。"
  - "原型/实验代码与生产代码双向隔离：生产代码绝不导入实验目录，实验代码绝不导入生产源文件；实验结论为继续时，生产实现必须从零重写。同一方向累计 3 次 PIVOT 后强制裁决 KILL，防止沉没成本陷阱。"

## 6. 关联文档
- 上游：`/brainstorm`（概念）、`/setup-engine`
- 下游：PROCEED → `/map-systems`、`/design-system`、`/art-bible`、`/design-review`、`/gate-check`；PIVOT → `/prototype [revised]`、`/brainstorm`；KILL → `prototypes/GRAVEYARD.md`、`/brainstorm open`；GDD 齐备验证全循环 → `/vertical-slice`
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/director-gates.md`、`.claude/docs/director-gates/cd-playtest.md`、`.claude/docs/templates/prototype-report.md`、references/1~9 + spike-mode
