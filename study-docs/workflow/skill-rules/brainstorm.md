# brainstorm — 协作式头脑风暴产出概念书（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/brainstorm/SKILL.md) ｜ 阶段：Phase 1 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/brainstorm [genre or theme hint, or 'open'] [--review full|lean|solo]`
- **一句话职责**：把"没有想法或粗糙想法"变成下一步可以直接构建的书面设计；写多少由 `workflow` 档位决定
- **触发前置**：无硬性前置（流程起点）；若 `design/gdd/game-concept.md`、`design/gdd/game-pillars.md` 或 `design/game-brief.md` 已存在，必须按节续作（Grep `^#` 定位标题后分段 Read），禁止推倒重来

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, docs.density, workflow`（resolve_config） | 无解析块时用默认值并声明"设置未读取" |
| 读取 | `project.yaml` 的 `engine.name` | 决定下一步是否列 `/setup-engine` |
| 读取 | 既有 concept / pillars / brief | 存在则续作而非重启 |
| 产出 | `minimal`：`design/game-brief.md`（一页）；`standard/full`：`design/gdd/game-concept.md` | 按需创建目录；模板为 `.claude/docs/templates/game-brief.md`（六必填+三单行字段）/ `game-concept.md` |
| 派生智能体 | `creative-director`（CD-PILLARS）、`art-director`（AD-CONCEPT-VISUAL）、`technical-director`（TD-FEASIBILITY）、`producer`（PR-SCOPE） | 仅 `workflow: standard/full` 且 `--review full` 时；各读自己的门禁文件，主会话禁止读 |

**配置解析（resolve_config）**：无解析块时默认 `workflow: minimal`、`review_mode: solo`、`automation: collaborative`、`docs.density: terse`。`--review` 参数覆盖本次运行的 `review_mode`。`docs.density` 决定各节深度：`terse`=要点列表；`balanced`=附简短理由；`thorough`=理由+备选方案。提问遵循 `automation-modes.md`（collaborative 每步问；guided 仅重大决策问；autonomous 记录后继续；`automation_always_ask` 类别恒问）。

## 3. 核心规则（逐条编号 R1、R2……）

**通用提问协议**
R1. 必须用问题工具（AskUserQuestion）提问；没有该工具时，列出编号选项并结束回合等待。问题必须是回复中的最后内容——问题之后禁止再给建议或倾向。（SKILL.md 顶部）
R2. 被跳过或被关闭的问题不是答案：必须用纯文本再问一次。（SKILL.md 顶部）

**workflow 分流**
R3. `workflow: minimal` 时只走 Lean Brief 流：产出一页 `design/game-brief.md` 后停止；禁止 discovery 问题、pillars、director gates 或 `game-concept.md`，禁止加载 `references/full-concept.md`。（SKILL.md 开头）
R4. `workflow: standard/full` 时必须读 `references/full-concept.md` 并遵循其八阶段流程，从 `.claude/docs/templates/game-concept.md` 模板写 `design/gdd/game-concept.md`；门禁遵循 `.claude/docs/director-gates.md`，每个 director agent 只拿自己的门禁文件（`cd-pillars.md`、`ad-concept-visual.md`、`td-feasibility.md`、`pr-scope.md`），主会话不得自己读这些文件。进入前先解析技能名后可能带的体裁/主题提示（`roguelike`、`cozy farming`）；`open` 或空白才从零开始。（SKILL.md 开头、full-concept.md Start）

**Lean Brief 流（minimal）**
R5. 追求几轮对话而非十五轮：用模板写一页 brief；若 `design/game-brief.md` 已存在，必须读取并精炼而非重写。（Lean Brief flow）
R6. 概念提案：从技能名后的提示（无提示则问一个快速开放问题）提出 **2-3 个单行概念**（动词开头，或类型+主题混搭），不是完整概念卡；请用户挑选或组合——这是每次运行必问的唯一创意问题。（步骤 1）
R7. 逐字段填 brief（每次交流填几个字段）：
   - **Working title**：brief 的标题行；从选定概念提供一个默认、允许用户改（`/create-stories` 用它命名 epic 文件夹）
   - **Pitch**：兴奋的一句话
   - **Core loop**：玩家重复执行的 2-4 步
   - **Player goal & fail state**：玩家想做成什么、怎么算输（`/create-stories` 会转成验收标准）
   - **MVP**：让它成为"这个游戏"的短清单，每项变一个 story——**超过 7 项必须推回**：说明对 MVP 太长、提议砍掉核心循环离了也能跑的项、保持 ≤7
   - **Out of scope**：刻意不建的东西（被砍项放这里）
   - **Build order**：最险/最未验证的部分先做
   - **Who it's for and what they feel** / **Art & audio direction** / **Reference game**（最接近的已上市游戏，及 MVP 保留其哪部分）：各一行；提供但不强制（步骤 2）
R8. 写盘门禁：先完整展示填好的 brief，再单独问"Brief is ready. May I write it to `design/game-brief.md`?"（`Yes — write it` / `Revise a field first`）。**只有对此问题的明确 yes 才写盘**——同意砍项或"继续吧"不算 yes。修订时改动命名字段、展示前后对比、再问。写盘按需创建目录；本层级**禁止写 `design/gdd/game-concept.md`**。（步骤 3）
R9. 下一步：读 `engine.name`——`/setup-engine` **仅在 `engine.name` 缺失或为空时**列出（minimal 路径通常已先跑过）；然后 `/create-stories`（MVP 转 stories；minimal 无独立 `/create-epics` 或 `/sprint-plan`，build order 即计划）；再 `/dev-story`。以一行摘要（pitch、MVP 项数、文件路径）收尾，最后一行必须是 `Verdict: COMPLETE — game brief written; next stop is code.`（步骤 4）
R10. 用户在写盘前叫停时，必须声明 brief 未写、只存在于本对话中。（Lean Brief flow 尾）

**full-concept 流（standard/full，来自 references/full-concept.md）**
R11. 每个阶段都要提问，禁止静默生成整个概念；你是引导者，用户做决定；先在回复中写分析，再用短选项标签提问。（full-concept.md 头部）
R12. Phase 1 创意发现：从人而非游戏开始——问打动过他们的游戏时刻、一直想要却没找到的幻想、花时间最多的三款游戏（**必须纯文本问，禁止预设选项**）、爱/避的类型；再合并问三题：想要玩家获得什么体验（Challenge & Mastery / Story & Discovery / Expression & Creativity / Relaxation & Flow）、现实开发时间线（Weeks / Months / 1-2 years / Multi-year）、开发经历（First game / Shipped before / Professional background）。汇总成 3-5 句 **Creative Brief** 回读确认。
R13. Phase 2 概念生成：从 brief 生成**三个**不同方向的概念，方法含动词开头、混搭（genre A + theme B，张力即钩子）、体验先行（MDA 逆向）；每概念含 Working Title、Elevator Pitch（1-2 句、过 10 秒测试）、Core Verb、Core Fantasy、Unique Hook（"like X, and also Y"）、Primary MDA Aesthetic、Estimated Scope、Why It Could Work、Biggest Risk。五选项问用户选哪个/组合/换方向；**此问题在每个 automation 模式下都要问**——没有规则能替用户选创意方向，禁止推向某个选择。
R14. Phase 3 核心循环：为选定概念问核心动作手感（3-4 个贴合类型的选项，各带 `I'll describe it`）与最重要设计变量；随后在回复中依次推演 30 秒循环、5 分钟循环、会话循环（30-120 分钟）、进度循环、以及自决定理论的动机（autonomy / competence / relatedness）。
R15. Phase 4 支柱与边界：起草 **3-5 条 pillars**（各含名称、一句话定义、设计测试"争论 X 还是 Y 时该 pillar 选 __"，支柱间应略有互斥）加 **≥3 条 anti-pillars**（"我们不做 X，因为它会损害 Y"）。问"这些 pillars 合适吗"（`Lock these in` / `Rename or reframe one` / `Swap a pillar out` / `Something else`）；collaborative 反复问直到 `Lock these in`；guided 问一次应用后锁定；autonomous 不问、锁定草案并记录备选。
R16. Phase 5 玩家类型：用 Bartle 类型与 Quantic Foundry 模型判定主要玩家（Achievers / Explorers / Socializers / Competitors / Creators / Storytellers）、次级吸引力、不适合谁、服务同一玩家的成功游戏。
R17. Phase 6 范围与可行性：问平台（PC / Mobile / Console / Web / Multiple，记录给 `/setup-engine`，**不推荐引擎**）；**引擎问题在所有 automation 模式都要问（含 autonomous）**："Do you already have an engine you work in?"（`Godot` / `Unity` / `Unreal Engine 5` / `No preference — help me decide`）；**绝不为用户选引擎**；点名引擎即记录为偏好、不二次猜测；无偏好则只说"本会话后跑 `/setup-engine`"。再覆盖美术管线、内容规模、MVP（验证核心循环是否好玩的最小构建）、最大技术/设计/市场风险、scope tiers（完整愿景 + 时间不够时发布什么）。
R18. Phase 7 写概念：按对话填模板所有节（含 MDA 分析、动机画像、心流设计）加 **Visual Identity Anchor** 节（方向名、一行视觉规则、2-3 条带设计测试的支撑原则、色彩哲学）。Core Identity 表的 Estimated Scope 必须与 Scope Tiers 的完整愿景时间线一致（写"Large (X–Y months, solo)"而非"Large"）。写盘门禁同 R8：单独问"Game concept is ready. May I write it to `design/gdd/game-concept.md`?"（`Yes — write it` / `Not yet — revise a section first`），只有明确 yes 才写；修订时先问改哪节（选项：`Elevator Pitch` / `Core Fantasy & Unique Hook` / `Pillars` / `Core Loop` / `MVP Definition` / `Scope Tiers` / `Risks` / `Something else — I'll describe`），展示前后对比，再问"Ready to write the updated concept document?"（`Yes — write it` / `Revise another section`）；collaborative 问到 yes、guided 问一次后写、autonomous 不问直接写并记录。本层级**禁止写 `design/game-brief.md`**。选定方向即 **Visual Identity Anchor**：写入概念文档并播种 art bible。
R19. Phase 8 下一步：按序列出每一步。设计优先（概念清晰）：`/setup-engine` → `/art-bible`（full 下 Technical Setup 门禁前必需；standard 仅当有视觉资产 story）→ `/design-review design/gdd/game-concept.md` → creative-director 精炼 pillars → `/map-systems` → `/design-system` → `/create-architecture` → `/architecture-decision` → `/architecture-review`（TR 注册表+追踪矩阵）→ `/gate-check`。原型优先（核心机制未验证）：`/setup-engine` → `/prototype`（一天内、丢弃式代码）→ PROCEED 走设计优先 5-10 步（带原型所学）/ PIVOT 重跑 `/brainstorm`；设计与架构完成后、承诺 sprint 前跑 `/vertical-slice`。以摘要收尾（pitch、pillars、主玩家类型、引擎偏好、最大风险、路径），最后一行 `Verdict: COMPLETE — game concept written.`
R20. 长对话预警：Phase 7 前若对话已很长，必须提醒"尚未写入 `game-concept.md` 的内容只存在于本对话中"，并在开新会话前写盘。（full-concept.md 尾）

## 4. 门禁与裁决（如适用）
全部四个门禁仅在 `--review full` 时运行；`solo`/`lean` 时跳过并打印 `"<gate-id> skipped — Solo mode."`（或 Lean mode）后继续：

| 门禁 ID | 审查者 | 裁决标准与处理 |
|---------|--------|----------------|
| CD-PILLARS | `creative-director` | 简报：pillars+设计测试、anti-pillars、core fantasy、hook。APPROVE 后才同问 Pillars（`Lock in as-is` / `Revise [pillar]` / `Discuss further`）与 Visual anchor 两问 |
| AD-CONCEPT-VISUAL | `art-director` | 简报：pitch、pillars、目标平台（若知）、参考游戏。给 2-3 个命名方向各成一选项，加 `Combine elements` / `Describe my own`；STRONG 时给主导方向标 `(Recommended)` |
| TD-FEASIBILITY | `technical-director` | 简报：core loop、平台、引擎或 undecided、技术风险。HIGH RISK：提供 revisiting scope 选项；CONCERNS：记录后继续；NOT ASSESSED：命名缺失输入，概念风险中记为 not assessed，**绝不记为 VIABLE** |
| PR-SCOPE | `producer` | 简报：full vision、MVP、scope tiers、时间线、团队规模。答 REALISTIC / OPTIMISTIC / UNREALISTIC |

- CD-PILLARS 与 AD-CONCEPT-VISUAL 相互独立：能并行就一起派发；两个 agent 只读各自门禁文件并返回裁决，**均不编辑文件**。
- CD-PILLARS 返回 CONCERNS/REJECT：先只问 Pillars 问题解决支柱，再单独问 Visual anchor。任一门禁 **NOT ASSESSED 都不是批准**：命名缺失输入、补齐重跑；不行则 CD-PILLARS NOT ASSESSED 按 CONCERNS 处理，且无 art-director 方向时只提供 `Describe my own direction`。
- PR-SCOPE：UNREALISTIC 时问是否调整 MVP/scope tiers 或保留——用户决定，**概念绝不因此被拒**；OPTIMISTIC 时展示 producer 的调整并问是否应用；NOT ASSESSED 时索取缺失输入（timeline、team size）重跑，或记 scope 为 not assessed，**绝不记为 REALISTIC**。

## 5. 移植建议
- **可直接移植**：R1-R2（提问协议）、R8/R18（写盘需明确 yes、修订展示前后对比）、R13（创意方向问题在所有模式下必问）、R17（工具/平台选择绝不由代理代答）、R20（未落盘内容只存在于对话中的预警）——全部与游戏无关，可进任何项目的 AGENTS.md。
- **需替换概念**：game-concept / game-brief → 项目章程或产品概念文档；pillars → 项目原则/北极星；MDA、Bartle、Quantic Foundry → 目标用户画像框架；`/setup-engine` → 技术选型流程；`/map-systems` → 工作分解结构（WBS）。
- **改写示例**：
  - "产出文档前必须单独询问『May I write to <path>?』；只有对该问题的明确 yes 才写盘，同意某项修改或说『继续』不构成 yes。修订时展示该字段/章节的前后对比后再问。"
  - "所有创意方向类问题（选哪个概念、选哪个方案）在任何自动化模式下都必须问用户；代理不得替用户做创意方向决定，也不得在选项中暗示倾向。"

## 6. 关联文档
- 下游：`/setup-engine`、`/create-stories`（minimal）；`/map-systems`、`/design-review`、`/art-bible`（standard/full）
- 引用：`.claude/docs/config-resolution.md`、`.claude/docs/automation-modes.md`、`.claude/docs/director-gates.md`、`.claude/docs/templates/game-brief.md`、`.claude/docs/templates/game-concept.md`、`references/full-concept.md`
