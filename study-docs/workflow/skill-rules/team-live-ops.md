# team-live-ops — 长线运营规划团队（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-live-ops/SKILL.md) ｜ 阶段：Phase 7+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-live-ops [season name or event description] [--review full|lean|solo]`
- **一句话职责**：编排长线运营团队规划一个赛季或限时活动——范围→叙事主题→经济设计→分析指标→内容写作→玩家沟通→评审签核（含伦理审查），产出可交生产的赛季计划。
- **触发前置**：必须提供赛季名或活动描述；配置经 resolve_config 解析（`review_mode, automation, team.size, workflow`）；自动化模式遵循 `.claude/docs/automation-modes.md`（collaborative 每阶段须批准 · guided 自动推进除非 BLOCKED · autonomous 端到端 + `log_decision`；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, team.size, workflow`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | 决定门禁深度、自动化、活跃集 |
| 读取 | `design/live-ops/economy-rules.md`（Phase 3 既有经济规则）；`design/live-ops/ethics-policy.md`（Phase 7 伦理审查；**不存在即触发 ETHICS REVIEW SKIPPED 留痕**）；Phase 1 brief、Phase 2 叙事框架等上游阶段产物 | 经济约束、伦理红线、阶段间传递 |
| 产出 | 工作稿 `production/live-ops/[season-slug]/`（slug = 参数转 slug——小写、空格 → 连字符）：`brief.md`（P1）、`narrative.md`（P2）、`economy.md`（P3）、`analytics.md`（P4）、`narrative-text.md` + `copy.md`（P5）、`comms.md`（P6）——一智能体一份，并行阶段绝不共享文件 | 工作稿在 `production/` 下（有界写例外可达） |
| 产出 | 最终文档 `design/live-ops/seasons/S[N]_[name].md`（来自 Phase 1–3）、`S[N]_[name]_analytics.md`（Phase 4）、`S[N]_[name]_comms.md`（Phase 6）——由编排器从工作稿**编译**并**先问后写** | `design/` 不在有界例外三目录内，见 R18 |
| 派生智能体 | `live-ops-designer`（赛季结构、事件节奏、留存机制、battle pass）；`economy-designer`（长线经济平衡、商店轮换内容与定价——cadence 由 live-ops-designer 定、货币定价、pity timer）；`analytics-engineer`（成功指标、A/B 测试设计、事件埋点、看板规格）；`community-manager`（玩家侧公告、活动描述、赛季消息）；`narrative-director`（赛季叙事主题、故事弧、世界事件框架）；`writer`（活动描述、奖励物品名、季节风味文本、公告文案） | 活跃集由 `team.size` 决定（见 R3） |

## 3. 核心规则（逐条编号 R1、R2……）

### 入口与配置
R1. 无参数时输出用法引导：`Usage: /team-live-ops [season name or event description] [--review full|lean|solo]`——然后**立即停止**，不派生任何 subagent、不读任何文件。（出处：Argument check）
R2. 本管线**无 director gate**：任何 `review_mode` 下都不派生 CD-/TD-/PR-/AD-PHASE-GATE；阶段门禁是管线自身决策点，其上是团队成员而非 director gate。（出处：Phase 0: Resolve Config）

### 活跃集（team.size）
R3. `team.size` 决定活跃集：`individual`（默认）= `live-ops-designer` + `economy-designer`，其余经这二者咨询、不单独 spawn；`small` = 上述 + `analytics-engineer` + `community-manager`；`studio` = `small` 集 + `writer` + `narrative-director`（完整文档化管线）。（出处：Phase 0 team.size）
R4. **Phase 1 前必须一行宣布活跃集，禁止让收缩沉默**：声明本次实际 spawn 谁、管线提名但**不** spawn 谁（经最近活跃核心智能体咨询，"Raise team.size to widen"）。"被强制执行却从未浮现的约束与从未执行的约束无法区分"——未说明时读者无法区分正确收缩的运行与坏掉的管线。（出处：Announce the active set）
R5. 活跃集之外的智能体经最近活跃核心智能体路由并附说明性注释，适用全管线；"phase gate" = 本管线自列的以 `AskUserQuestion` 决策点结束的任何阶段（含写进管线的 Gate 步骤），**无论 automation 模式**。（出处：Phase 0 team.size）

### 委派协议
R6. **简报不倾倒上下文**：共享输入只读一次，传蒸馏后的内联简报；已读文档禁止只丢路径（拿到路径的智能体会重读整个文件）；只对未读且仅该智能体需要的文档传路径。（出处：How to Delegate）
R7. **每个智能体 prompt 以返回契约结尾**："把完整输出写到 `[path]`——该命名路径即有界例外下的写授权，无需另问；只返回 (1) 路径、(2) ≤5 条决策摘要、(3) BLOCKED/CONCERNS 各一行；禁止复述读过的文档。"（出处：How to Delegate）
R8. **有界写例外三条件**：(1) 路径是**你**命名的；(2) 是 `production/`、`docs/`、`tests/` 下的**新**产物；(3) 产出它的阶段受 `AskUserQuestion` 门禁。三条件外必须问；**禁止按 subagent 逐个问来"修复"**——每阶段每智能体一问会让编排器不可用。（出处：Why this does not violate the Collaboration Protocol）
R9. 管线允许处并行（Phases 3 与 4 可同时）；每智能体写 `production/live-ops/[season-slug]/` 下各自单独命名的文件（§2 表），一智能体一文件。（出处：How to Delegate）

### 管线
R10. **Phase 1 范围界定**（live-ops-designer）：定义赛季/活动——类型（季节性 seasonal、限时活动 limited-time event、挑战 challenge）、时长、主题方向；列内容清单（新模式、物品、挑战、剧情节拍）；定义留存钩子（什么让玩家每日/每周回访）；识别资源预算（多少内容需新建 vs 复用）。产出含范围、内容清单、留存机制概览的赛季 brief。（出处：Phase 1）
R11. **Phase 2 叙事主题**（narrative-director）：读 Phase 1 brief；设计赛季叙事主题——活动如何连接游戏世界；定义玩家在活动中发现的中心故事钩子；识别本季能推进哪些既有 lore 线。产出叙事框架文档（主题、故事钩子、lore 关联）。（出处：Phase 2）
R12. **Phase 3 经济设计**（economy-designer，与 Phase 4 并行）：读赛季 brief 与 `design/live-ops/economy-rules.md` 的既有经济规则；设计奖励轨道——免费档进度、付费档价值主张；规划季内经济——赛季货币、商店轮换内容与定价；为任何随机元素定义 pity timer 与坏运保护（bad-luck protection）；**验证付费档无 pay-to-win 物品**。产出含奖励表、定价、货币流向的经济设计文档。（出处：Phase 3）
R13. **Phase 4 分析与成功指标**（analytics-engineer，与 Phase 3 并行）：读赛季 brief；定义成功指标——参与率目标、留存提升目标、battle pass 完成率；设计季内 A/B 测试（如不同奖励节奏）；specify 本季内容需要的新遥测事件。产出含成功标准与埋点要求的分析计划。（出处：Phase 4）
R14. **Phase 5 内容写作（并行）**：**仅当 Phase 3 与 Phase 4 结果都收齐后才开始**；并行委派 `narrative-director`（需要时）写游戏内叙事文本（过场脚本、NPC 对话、世界事件描述）+ `writer` 写全部玩家可见文本（活动名、奖励物品描述、挑战目标文本、季节风味文本）；两者都读 Phase 2 叙事框架文档。（出处：Phase 5）
R15. **Phase 6 玩家沟通计划**（community-manager）：读赛季 brief、经济设计与叙事框架；起草赛季发布公告（语气、要点、按平台分版本）；规划沟通节奏——发布前预告、launch 日帖、季中提醒、最后一周 FOMO 推送；为 day-1 patch notes 起草已知问题节占位。产出每个触点带草稿文案的沟通日历。（出处：Phase 6）
R16. **Phase 7 评审与签核**：汇总各阶段产出，呈现整合的赛季计划——内容范围（在做什么）、经济健康检查（奖励轨道是否公平、非掠夺性）、分析就绪（成功标准是否定义并埋点）、伦理审查（见 R17）、开放问题（生产前仍需的决策）。**请用户批准赛季计划后才交给生产团队**；COMPLETE 只在用户批准且无未解决伦理违规后发出。（出处：Phase 7）
R17. **伦理审查（ethics review）——对照 `design/live-ops/ethics-policy.md` 检查 Phase 3 经济设计**：文件不存在 → 标记 "ETHICS REVIEW SKIPPED: `design/live-ops/ethics-policy.md` not found. Economy design was not reviewed against an ethics policy. Recommend creating one before production begins."，该标记纳入赛季设计输出文档，并把"创建 `design/live-ops/ethics-policy.md`"加入 next steps；文件存在且发现违规 → 标记 "ETHICS FLAG: [element] in Phase 3 economy design violates [policy rule]. Approval is blocked until this is resolved."——**不发 COMPLETE、不写输出文档**，用 `AskUserQuestion` 给三选项：修订经济设计 / 带文档理由覆盖 / 取消；选修订 → 重新 spawn economy-designer 出修正设计后回到 Phase 7 评审；选取消 → 结束，Verdict **BLOCKED**（"Live ops design cancelled due to unresolved ethics violation. Resolve the flagged issues and re-run /team-live-ops."）。伦理违规未解决 → 以 Verdict **BLOCKED** 结束。（出处：Phase 7）

### 收尾
R18. **最终文档写 `design/live-ops/`——编排器先问再写**：`design/` **不是**有界写例外覆盖的三目录（`production/`、`docs/`、`tests/`）之一，sub-agent 被给到这些路径时必须 prompt；**禁止扩大例外来消音**。沿 team-level 模式：sub-agents 把工作稿写在例外可达的 `production/` 下；**你**编译最终文档并经 `AskUserQuestion` 问 "May I write the season plan to `design/live-ops/…`?"，批准后才写。（出处：Output Documents）
R19. **先验证工件**：返回契约命名了路径的，先确认路径在盘上——**命名工件不在磁盘即失败阶段，无论回复多流畅**；点名未满足的契约让其续跑。任何智能体 BLOCKED/错误/不能完成：立即呈现、不越过其阻塞的依赖、总出部分报告；跳过智能体的小节保持命名空缺，禁止自己填内容。BLOCKED 不可解 → 以 Verdict **BLOCKED** 结束而非 COMPLETE。（出处：Error Recovery Protocol）
R20. **File Write Protocol**：sub-agents 的工作稿在 `production/` 下走有界例外（R8 三条件）；**最终 `design/live-ops/` 文档（赛季设计、分析计划、沟通日历）是例外之外**——编排器自己编译，并在自己的 "May I write …?" 询问后写。（出处：File Write Protocol）
R21. 汇报覆盖：赛季主题与范围、经济设计要点、成功指标、内容清单、沟通计划、生产前需用户决策的开放问题。Verdict **COMPLETE**——赛季计划已产出并交付生产。（出处：Output）
R22. 下一步：对赛季设计文档跑 `/design-review` 做一致性验证；跑 `/sprint-plan` 排赛季内容创建工作（`workflow: minimal` 无 sprint 时加进 brief 的 build order）；内容就绪时跑 `/team-release` 部署。**以伦理 flag 结束 BLOCKED 时**：对照 `design/live-ops/ethics-policy.md` 修订经济设计后重跑 `/team-live-ops`——上面三步等一个 COMPLETE 的计划。（出处：Next Steps）

## 4. 门禁与裁决
- **Phase 7 用户批准门禁**：用户批准赛季计划是交给生产团队的前提；COMPLETE 仅在批准且无未解决伦理违规时发出。
- **伦理审查三态**：SKIP（政策文件不存在 → 留痕 + 建文件进 next steps，不阻断）/ VIOLATION（存在且违规 → Approval blocked，修订、带理由覆盖或取消）/ 通过。
- **Verdict**：COMPLETE（计划产出并交付）/ BLOCKED（BLOCKED 不可解，或伦理违规未解决/用户取消）。
- 本管线无 director gate（无 CD/TD/PR/AD-PHASE-GATE），门禁即自身决策点。

## 5. 移植建议
- **可直接移植**：R1（无参数即停不派生）、R4-R8（活跃集宣布、路由、返回契约、有界写例外）、R14（汇合门——两个并行阶段的结果都收齐才进下一阶段）、R16-R17（批准前置、伦理审查三态与留痕——违规即阻断批准）、R18（例外目录之外先问后写、禁止扩大例外）、R19（工件在盘核验）。
- **需替换概念**：赛季/battle pass/商店轮换 → 产品的运营周期与会员/订阅/上新机制；`economy-rules.md`/`ethics-policy.md` → 项目的商业化规则与伦理/合规政策（隐私、定价公平、未成年人保护等）；pity timer → 抽奖/随机掉落保护机制；`/design-review`、`/sprint-plan`、`/team-release` → 对应评审、排期、发布技能。
- **改写示例**：
  - R17 → "商业化设计必须对照成文的伦理政策审查。政策文件不存在时不得假装审查已发生——显式留痕'审查被跳过：政策未创建'并把建政策列入后续步骤；发现违规时批准即被阻断，只允许修订、书面理由覆盖或取消三种出路。"
  - R18 → "子代理的工作稿写在允许免问的目录内；最终交付文档若位于例外目录之外，必须由编排者编译后单独询问一次再写。禁止为省一次询问而扩大免写目录的范围。"

## 6. 关联文档
- 上游：`design/live-ops/economy-rules.md`、`design/live-ops/ethics-policy.md`（缺则建）。
- 下游：`/design-review`（赛季设计一致性）、`/sprint-plan`（内容排期）、`/team-release`（内容就绪后部署）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`。
