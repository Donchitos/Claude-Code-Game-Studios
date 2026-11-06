# vertical-slice — 生产级垂直切片（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/vertical-slice/SKILL.md) ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/vertical-slice [--review full|lean|solo]`
- **一句话职责**：预生产末段的端到端验证构建——用一个近生产质量的 [start → challenge → resolution] 完整循环回答"我们能否按时、以生产质量构建这个完整游戏循环？"，产出 PROCEED/PIVOT/KILL/NOT ASSESSED 裁决与真实生产率（velocity）数据
- **触发前置**：GDD、架构、UX 规格已完成（生产前晚期运行）；验证的是流水线、执行可行性、乐趣存续（fun survival）与 velocity 四件事。早于此（还没写 GDD、只想验证核心创意）→ 跑 `/prototype`。PIVOT 后修订完 GDD/架构再跑本技能重验；可反复运行直到 PROCEED 或 KILL

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, workflow` | `--review` 覆盖 `review_mode`（本次运行） |
| 读取 | `CLAUDE.md`、`design/gdd/game-concept.md`（或 `rigor: minimal` 的 `design/game-brief.md`：pitch、core loop、"what they feel" 行，无 pillars）、`design/gdd/systems-index.md`（MVP 系统与优先级）、`docs/architecture/architecture.md`（分层结构）、`docs/architecture/control-manifest.md`（实现技术规则）、被切片系统的关键 GDD | 每个 GDD/ADR/manifest 按节读（Grep `^#` + offset/limit） |
| 读取 | `project.yaml` 的 `naming.*`（命名约定） | 键缺失/为空（含无 `naming` 块）回退 `.claude/docs/technical-preferences.md` |
| 读取 | `.claude/docs/templates/vertical-slice-report.md` | 报告结构；缺失时用内置 fallback 结构（见 R13） |
| 产出 | `prototypes/[concept-name]-vertical-slice/`（每文件带 VERTICAL SLICE 头）、`REPORT.md`（含逐日 Velocity Log）、`prototypes/index.md` 追加行、`PIVOT-NOTE.md`（PIVOT 时）、`prototypes/GRAVEYARD.md`（KILL 时）、`production/session-state/active.md` checkpoint（每个构建日更新） | velocity log 直接喂给 `/sprint-plan`（`minimal` 档喂给 brief 的 build order） |
| 派生智能体 | `creative-director`（CD-PLAYTEST 门禁，`full` 档） | 其余主会话直接执行 |

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 1 解析档位与加载上下文**
R1. 读全部设计意图文件（见 §2）；`/gate-check production` 会校验本技能的产出，切片必须能在真实设计语境下自证。

**Phase 2 定义切片范围与验证问题**
R2. 构建前定义**可证伪验证问题**："Does a player, starting from nothing, experience [core fantasy] within [N] minutes, without developer guidance — and can we build one such loop in [X] days at representative quality?"——玩家体验与构建可行性**两部分缺一不可**。
R3. **范围纪律**：必须含全部核心循环系统（完成一个 [start → challenge → resolution] 循环所必需的系统都得在切片里）；**目标 3–5 分钟打磨的连续玩法**（行业标准切片长度——足以展示机制与调性、短到能以代表性质量构建），预计超 5 分钟就**砍内容、不砍质量**；**砍 scope 永远先于砍质量**——不像目标游戏的低质量切片验证不了生产可行性；1–3 周建不完说明切片范围错了——不是太大，是一次想证明太多。
R4. **Scope creep 警告**：垂直切片是预生产阶段范围蔓延风险最高的时刻——功能看着"差不多了"，忍不住加"就一个系统"。**抵抗，砍而不加**。范围先呈报用户确认再动工。

**Phase 3 计划**
R5. 以 bullet 定义：实现的系统（练到哪些 GDD 节）、完整的 [start] → [challenge] → [resolution] 循环（精确表述）、美术音频质量水平（占位可接受、代表性优先）、针对验证问题的可测成功标准、**硬时限 [X] 天**——超时即范围错了，停下重估。
R6. 确认 scope 时点名 checkpoint 文件："May I record this plan in `production/session-state/active.md`?"。确认后写 checkpoint（目录不存在则创建）：概念名、验证问题、范围内系统、美术质量水平、当前阶段（"Phase 4 — Implement"）；**每个构建日结束时更新**——多周引擎构建跨大量会话，这是主要恢复机制。

**Phase 4 实现**
R7. 先问 "May I create the vertical slice directory at `prototypes/[concept-name]-vertical-slice/` and begin implementation?"。每个文件**必须**以三行头开始：`VERTICAL SLICE - NOT FOR PRODUCTION`、`Validation Question: [本构建在证明什么]`、`Date:`——用该文件自己的注释语法（GDScript/Python `#`、C#/C++/JS `//`、Lua `--`、HTML/MD `<!-- … -->`）；**写错语言语法是解析错误不是标签**；无法写注释的文件（JSON、引擎生成的场景/项目文件）豁免。
R8. **质量标准**（高于概念原型、非全生产）：遵循 `docs/architecture/control-manifest.md` 的架构分层；命名约定取 `naming.*`；**禁止硬编码玩法数值**——用常量或配置文件；关键路径要有基本错误处理；占位美术可接受、代表性美术优先。
R9. 多轮循环：写完初版请用户运行并回报错误/观察，迭代直到完整循环可演示（用户跑 → 报错 → 修复/调整 → 重复）。**Sunk cost checkpoint（计划时间线第 3 天）**：届时完整循环仍不可演示 → 停下重估——scope 太大或架构假设错了；**显式浮出阻塞项，禁止继续闷头迭代**。
R10. 循环可演示后至少进行 **1 次文档化的试玩 session**。试玩方法：找没见过游戏的人**沉默观察**（不引导；困惑揭示游戏没自我传达的东西）；无外部测试者 → 团队轮换（建 X 系统的 Dev 是 Y 系统的天真测试者）；solo → 离开 2-3 天再以新玩家身份通玩，或做 "silent walkthrough"（一次坐下通玩、途中不停下来修、记录每个迟疑时刻）；要更细 UX 数据可请测试者 **think aloud**（手感测试仍以沉默观察为佳）；异步远程可用 Loom/OBS 录屏；AI/NPC 未完成时用 **Wizard of Oz**（第二人实时秘密扮演系统行为）验证设计意图。

**Phase 5 试玩复盘**
R11. 循环可演示后、写报告前必须收集结构化观察，**禁止跳过复盘直接生成报告**。给确切话术："Play through the complete [start → challenge → resolution] cycle from scratch, as if you're a new player with no knowledge of how it was built. Don't skip ahead or use developer shortcuts. Come back when you've completed the full loop — or when you've hit something that stopped you."
R12. 用户回来后**一次一问**（等答再问），共 6 问：① 循环完成——无需我引导或构建先验知识，独立完成全循环？② 时间检查——到第一个有意义动作（真正"在玩游戏"的第一个瞬间）多久？③ 核心幻想——"这游戏应该让你感到 [core fantasy]。感受到了吗？诚实说——不是'差不多'，说具体感受与发生时刻"；④ 阻塞项——什么让你停住/困惑/出戏？哪个时刻不确定该做什么或东西坏了？⑤ 流水线检查——"作为开发者（不是玩家）：以这个质量做完整游戏感觉可达吗？构建时长有什么意外？"⑥ 裁决——PROCEED/PIVOT/KILL + 具体理由。含糊回答必须追问具体时刻。
R13. **验证项出现 NO 时 PROCEED 不可用**：`/gate-check production` 对 Vertical Slice Validation 有任何 NO 即 FAIL——玩家无开发者引导完成循环（问 1）、2 分钟内学会该做什么（问 2，超时即 NO）、核心机制手感好（问 3）、无关键 fun-blocker bug（问 4）。任何一项为 NO，裁决只能是 **PIVOT 或 KILL（用户选择）**，且报告必须点名那个 NO。
R14. **NOT ASSESSED 是第四个裁决**：无人从头玩过完整循环（本会话没法玩，或中途停了）= 验证未运行 → 裁决 **NOT ASSESSED** 并记录原因。位次：**高于 PROCEED、低于 PIVOT 和 KILL**——没玩过的切片没挣到 PROCEED；已知会失败的切片比没人玩过的切片更有行动价值。**绝不记录为 PROCEED**。

**Phase 6 报告**
R15. 构建全程记录 **velocity**：逐日写下当天构建内容——"这是你对生产率最诚实的数据，禁止跳过"；直接喂给 sprint planning（`minimal` 档为 brief 的 build order）。
R16. 读报告模板填每个节；模板缺失用 fallback 结构：`Executive Summary`（裁决 + 2 句理由） / `Core Loop Validation`（测了什么、过了什么、败了什么） / `Feel Assessment`（动画、操控、反馈——主观注记） / `Technical Findings`（性能、引擎问题、架构风险） / `Velocity Log`（逐日**实际**进度，不是估算） / `Lessons Learned`（被近生产质量构建推翻的假设、流水线/架构的意外、下次切片范围会改什么） / `Recommended Next Steps`。占位文本一律换真实观察；建议携带 Phase 5 裁决（NOT ASSESSED 也含）及原因。
R17. 问 "May I write this report to `prototypes/[concept-name]-vertical-slice/REPORT.md` and add its row to `prototypes/index.md`?" 后写盘并更新 index（不存在则创建）：概念名、日期、裁决、REPORT 链接，并注明是首跑还是 PIVOT 后重跑；velocity log 与后续 sprint 估计交叉引用。

**Phase 7 创意总监审查** — 见 §4。

**Phase 8 总结与后续**
R18. 输出摘要：验证问题、velocity 数据、最终建议，链接 REPORT.md。
R19. **PROCEED**：`workflow: minimal` → `/create-stories`（从 brief）再 `/dev-story` 首个 story；`standard`/`full` 顺序：`/create-epics layer:foundation` → `/create-epics layer:core` → `/create-stories [epic-slug]` → `/sprint-plan`（用切片 velocity 数据）→ `/gate-check production`（正式推进到 Production）。试玩注记：`/gate-check` 要找文档化试玩证据——**最少 1 次有 REPORT.md 且裁决 PROCEED 的 session 才能过门禁**；3+ 次更可靠但非硬门禁。
R20. **PIVOT**：先按次序两问（纯文本）：①"哪些系统/机制在这个质量水平上成立、应在修订设计中保留？"②"具体什么失败了——核心循环、架构、流水线还是乐趣？"；问 "May I write this to …/PIVOT-NOTE.md?" 后写入：成立项、失败项、需修订的具体系统/架构决策、下一次切片该不同地证明什么。下次运行 `/vertical-slice` 时**必须检查 `prototypes/` 里的 PIVOT-NOTE.md**，用它框定新验证问题与范围决策。随后：`/design-system [mechanic]` 修订受影响 GDD → `/architecture-decision` 处理架构问题 → 重跑 `/vertical-slice` 验证修订方向。
R21. **KILL 前先确认裁决成立**：完整循环对老手也超 5 分钟？任何试玩 session 都无情绪高点（愉悦/惊喜/满足）？2+ 次切片尝试后 50%+ 测试者卡在同一点？架构问题需要重建超过 50% 已建内容？已是同一概念第 3 次切片尝试？——**2+ 项成立 → KILL 成立；0–1 项 → 一次聚焦 PIVOT 可能救回概念**。KILL 后问 "May I append this to `prototypes/GRAVEYARD.md`?"，按固定条目写入（Kill reason：具体是什么阻止玩家体验 core fantasy / What worked at slice quality / What failed / Next time 一个具体改变）。然后带着所学回 `/brainstorm`，或先 `/prototype [new-concept]` 便宜测新方向。
R22. **NOT ASSESSED**：构建了但未验证——说明适用原因，完成 Phase 5 的通玩与复盘（`production/session-state/active.md` checkpoint 是恢复点），问过后更新 REPORT.md 与 index 行的裁决。**绝不带着 NOT ASSESSED 去过 `/gate-check production`——NOT ASSESSED 不是 PROCEED**。

**硬约束（SKILL.md 尾部）**
R23. 切片代码**绝不**被重构进生产——仅作参考；生产代码**绝不** import `prototypes/`；PROCEED 后生产实现**从零写**，切片仅作设计参考。**砍 scope 可接受、砍质量不可**——低质量切片什么都证明不了。总工作量 **1–3 周**，更长即 scope 太大——砍切片不砍质量。Day 3 sunk cost rule 见 R9。**网络/多人游戏**：本地切片无法验证网络机制手感——0ms 本地与 80ms 网络延迟下战斗/移动/预测手感完全不同；切片可验证循环"有趣且完整"，不能验证网络机制在真实条件下的手感——那需要真实 peer 或模拟延迟。

## 4. 门禁与裁决
- **硬门禁（gate-check production）**：Vertical Slice Validation 四项（R13）任一为 NO 即 FAIL——PROCEED 不可用，PIVOT/KILL 由用户选择，报告点名 NO。至少 1 次文档化试玩 session（REPORT.md 裁决 PROCEED）才能过 `/gate-check production`。
- **CD-PLAYTEST**（创意总监审查，Phase 7）：`solo` → 跳过，注记 "CD-PLAYTEST skipped — Solo mode."；`lean` → 跳过（非 PHASE-GATE），注记 "…Lean mode."；`full` → spawn `creative-director` 执行门禁——**除非裁决为 NOT ASSESSED**：没玩过就没有可审的东西，注记 "CD-PLAYTEST skipped — the slice has not been played yet."。传入：完整 REPORT.md、验证问题、pillars 与 core fantasy（brief 档传 pitch 与 "what they feel" 行）。
- **裁决应用**：APPROVE → 建议成立。CONCERNS → 与建议并列展示，AskUserQuestion 三选（`Revise the recommendation` / `Accept with noted concerns` / `Discuss further`）——用户决定，总监不决定。REJECT（core fantasy 不在场）→ PROCEED 建议不能成立；AskUserQuestion 让用户选 PIVOT 或 KILL，并按该选择跑 Phase 8；PIVOT/KILL 建议不受影响。NOT ASSESSED [缺失输入] → 总监未做判断，既不支持也不推翻建议：命名缺失输入、补齐重跑，或记录 `CD-PLAYTEST: NOT ASSESSED — [input]` 于报告。
- 总监返回 CONCERNS/REJECT/NOT ASSESSED 时问 "May I update REPORT.md and its `prototypes/index.md` row?" 后记录裁决与理由（及变化后的最终建议）。
- **裁决词**：PROCEED / PIVOT / KILL / NOT ASSESSED；位序 FAIL > NOT ASSESSED > {PROCEED, PIVOT/KILL}（未验证高于未挣得的通过）。

## 5. 移植建议
- **可直接移植**：R2（可证伪验证问题——体验与可行性双半）、R3-R4（范围纪律：最小完整闭环、砍内容不砍质量、抗 scope creep）、R5-R6（硬时限+逐日 checkpoint）、R9（Day 3 sunk cost 检查点）、R12（六问复盘一次一问）、R13-R14（NO 项封死 PROCEED + NOT ASSESSED 第四裁决及位次）、R15（velocity log 是最诚实的数据）、R20-R22（PIVOT-NOTE 承前/GRAVEYARD/NOT ASSESSED 不充 PROCEED）、R23（验证构建与生产代码隔离）。
- **需替换概念**：游戏核心循环 [start → challenge → resolution] → 产品关键用户旅程（onboarding → 核心价值交付 → 收益确认）；"3–5 分钟打磨玩法" → 能走完关键旅程的最小端到端切片；GDD/架构/control-manifest → 产品规格/技术架构文档/实现规范；sprint-plan velocity → 迭代速率估算的实测输入；creative-director → 品牌或体验负责人。
- **改写示例**：
  - "做端到端验证构建前必须写下可证伪问题：『新用户能否在无引导的情况下于 N 分钟内体验到 [核心价值]，且我们能在 X 天内以代表性质量建完这一闭环？』——体验与可行性两半缺一不可；范围超限时砍内容，永不砍质量。"
  - "验证项出现任何 NO 时『通过』裁决不可用；无人完整跑通验证流程时记 NOT ASSESSED——它高于『通过』、低于『失败/转向』，且绝不允许被当作通过使用。逐日记录实际构建进度：这是项目能得到的最诚实的产能数据。"

## 6. 关联文档
- 上游：`/prototype`（概念验证在前）、`/design-system` + `/review-all-gdds` + `/create-architecture` + `/ux-design`（GDD/架构/UX 完成是前提）、`/setup-engine`
- 下游：`/gate-check production`（硬门禁）、`/create-epics`、`/create-stories`、`/sprint-plan`（吃 velocity 数据）；PIVOT → `/design-system`、`/architecture-decision`、重跑本技能；KILL → `prototypes/GRAVEYARD.md`、`/brainstorm`
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/director-gates.md`、`.claude/docs/director-gates/cd-playtest.md`、`.claude/docs/templates/vertical-slice-report.md`、`.claude/docs/technical-preferences.md`
