# milestone-review — 里程碑完整性与 go/no-go 评审（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/milestone-review/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/milestone-review [milestone-name|current] [--review full|lean|solo]`
- **一句话职责**：在检查点或截止日前聚合冲刺报告与代码库健康数据，产出里程碑评审——特性完整性、质量指标、风险、速度分析与 **Go/No-Go 建议**。
- **触发前置**：`production/sprints/` 下有冲刺报告；里程碑定义（`production/milestones/`）可选——缺失时仅对照冲刺报告评审，禁止编造定义。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, workflow`（resolve_config；`--review` 覆盖 `review_mode` 本次运行；无块 → `.claude/docs/config-resolution.md` 默认） | `review_mode` 定 PR-MILESTONE 门禁档；`automation` 定提问/写盘行为；`workflow` 定收尾分支（minimal 无冲刺） |
| 读取 | 里程碑定义 `production/milestones/`（`current` = 最近修改的定义文件，**跳过 `-review.md` 结尾的文件**）；冲刺报告 `production/sprints/sprint-*.md`（先 glob 数出分母 N，再按章节 Grep 扫描，见 R4）；`production/sprint-status.yaml` 的 `status: blocked` 故事及 `blocker` 字段；`production/epics/**/story-*.md` 的 Blocked 标记；`production/qa/bugs/` 的 `**Severity**`/`**Status**` 行；`production/risk-register/`（存在时） | 里程碑定义由人手写（模板 `.claude/docs/templates/milestone-definition.md`），**无技能写它**——目录缺失/为空属正常，明说即可 |
| 产出 | `production/milestones/[milestone-name]-review.md`（用户同意后才写；目录不存在则创建） | 完整评审报告，含 Go/No-Go 建议 |
| 派生智能体 | `full` 档：`producer`（门禁 **PR-MILESTONE**，读 `.claude/docs/director-gates/pr-milestone.md`——派生智能体自己读自己的门禁文件，主会话**禁止**读它）；`solo`/`lean` 档跳过 | lean 档下 PR-MILESTONE 不是 PHASE-GATE，跳过并在 Go/No-Go 节注记 |

## 3. 核心规则
R1. **输入不足先检查，再谈产出**：列出本技能读的全部输入（数据文件、既有报告、profiler 输出、测试结果、registry、源码），逐项记 `FOUND`/`ABSENT`（禁止 "assumed present"）；某节必需的输入 ABSENT → 该节记 `NOT ASSESSED — NO DATA`，禁止估算、禁止从相邻产物推断、禁止留空格让读模板的人自己填；**全部**必需输入 ABSENT → 停止并以 `NOT ASSESSED — NO DATA` 作为整体裁决，点名缺什么、哪个技能产它。（Insufficient input）
R2. `NOT ASSESSED` 是**成功**的正确答案——它是对"数据怎么说"在无数据时的正确回答。要防的失效模式很具体：裁决枚举里没有"跑不了"状态的报告会产出**假性干净通过**——零资产零标准的项目返回 COMPLIANT 的资产审计、零 profiler 数据且从未设预算却报 ">99% headroom against a 16.67ms budget" 的性能画像。**证据缺失不等于无问题**：因无可扫文件而零命中的扫描什么都没验证——必须说清是哪一种，读者无法从绿色结果分辨。（Insufficient input）
R3. 参数解析（Phase 0）：取里程碑名（`current` 或具体名）。每次 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录并继续；`automation_always_ask` 类别恒问）。门禁检查模式见 `.claude/docs/director-gates.md`；各门禁定义在 `.claude/docs/director-gates/[gate-id].md`——**派生智能体读自己的门禁文件，主会话不读**。（Phase 0）
R4. 加载里程碑定义（Phase 1）：从 `production/milestones/` 读定义（存在时）；参数为 `current` → 取**最近修改**的里程碑文件。**无技能写 `production/milestones/`**——定义由人从 `.claude/docs/templates/milestone-definition.md` 手写，多数项目没有；目录缺失或为空 → 明说，仅对照冲刺报告评审，**禁止编造定义**。`current` 有陷阱：本技能自己的输出也叫 `[milestone-name]-review.md`，最近修改命中的可能是上一次**评审**而非定义——**选取时跳过 `-review.md` 结尾的文件**。（Phase 1）
R5. 收集冲刺报告（Phase 1）：从 `production/sprints/` 收本里程碑内的冲刺报告。先建分母（glob 后数出 **N**），再只扫里程碑评审真正聚合的章节而非整读每份报告（Grep 见下方原文）。这些备选项是 **`/sprint-plan` 实际产出的标题**（`## Sprint Goal`，不是 `## Goal`）——不是评审者想当然的标题；只匹配一个真实标题的 pattern 仍返回非零计数，于是零匹配逃生口永不触发，评审聚合了每份报告的一角却报告全覆盖。（Phase 1）

R5 对应的章节扫描（保留原文 pattern）：

```
Grep pattern="^## (Sprint Goal|Capacity|Tasks|Carryover|Risks|Progress|Burndown Assessment|Emerging Risks|Definition of Done)" glob="production/sprints/sprint-*.md" output_mode="content" -A 12
```

R6. 零匹配与外指报告必须整读：某冲刺报告扫描的章节指向自身之外、或一条都没匹配上（早于模板的报告）→ **整读该报告，禁止从里程碑历史中静默丢弃**；任何没贡献内容的冲刺都要点名——静默漏掉一个冲刺会同时低估工作量与延期。（Phase 1）
R7. **Blocked 故事不在冲刺报告的扫描章节里**，必须去它们记录的地方读：`production/sprint-status.yaml` 中 `status: blocked` 的故事（带 `blocker` 字段）+ 冲刺外故事一次 Grep（pattern `^> \*\*Status\*\*: Blocked|BLOCKED:`，glob `production/epics/**/story-*.md`）。每个 blocked 故事进 Blocked 表，按其 epic 文件夹实现的特性归组，带上 blocker（yaml 的 `blocker` 字段或故事的 `BLOCKED:` 注记）。**无故事文件且无 `sprint-status.yaml` → Blocked 表与 blocked 故事计数记 `NOT ASSESSED — NO DATA`，不是零**。（Phase 1）
R8. 代码库健康扫描（Phase 2）：扫 `TODO`/`FIXME`/`HACK` 标记计未完成工作；从 `production/qa/bugs/` 按严重度数开放 bug——一次 Grep `**Severity**` 与 `**Status**` 行，同 `/bug-triage` 的做法；**无 bug 文件 → bug 行记 `NOT ASSESSED — NO DATA`，不是零**。风险登记 `production/risk-register/` 存在时检查（人手写自 `.claude/docs/templates/risk-register-entry.md`，无技能写它，缺失属正常——**注记缺失而非静默跳过风险评估**）。（Phase 2）
R9. 完成度判定铁律（Phase 3）：只有 Status 为 `Complete` 的特性进 Fully Complete 并**计入完成百分比**；**Deferred 特性留在分母里**，并注明移到了哪个里程碑。已启动而故事 Blocked 的特性进 **Blocked 表而非 Partially Complete**——点名 blocker，让评审说出为何停滞，而不只是计数移动。（Phase 3）
R10. Go/No-Go 建议取值（Phase 3）：`NOT ASSESSED / GO / CONDITIONAL GO / NO-GO`；CONDITIONAL 时列出必须满足的条件；Rationale 必须给出解释。（Phase 3）
R11. PR-MILESTONE 门禁档位检查（生成建议前套用）：`solo` → 跳过，注记 "PR-MILESTONE skipped — Solo mode."，Go/No-Go 节不带 producer 裁决呈现；`lean` → 跳过（不是 PHASE-GATE），注记 "PR-MILESTONE skipped — Lean mode."；`full` → 正常派生。派 `producer` 前传入：里程碑名与目标日期、当前完成百分比、blocked 故事数、冲刺报告的速度数据（可得时）、cut candidate 清单。producer 裁决（ON TRACK / AT RISK / OFF TRACK）**内联呈现在 Go/No-Go 节**，影响整体建议。（Phase 3b）
R12. OFF TRACK 必问：producer 裁决 OFF TRACK 时，生成建议前用 `AskUserQuestion`——"Producer verdict: OFF TRACK. The milestone is in jeopardy. This review will recommend NO-GO. How do you want to proceed?" 选项 `[A] Accept NO-GO — generate the full review with that recommendation` / `[B] Override to CONDITIONAL GO — I'll document the accepted risks myself` / `[C] Stop — I want to address blockers before generating the review`。**禁止对 OFF TRACK 发 GO；CONDITIONAL GO 只有用户明确选 [B] 才发**。（Phase 3b）
R13. AT RISK 必问："Producer verdict: AT RISK. Milestone may slip. How should the Go/No-Go section be framed?" 选项 `[A] CONDITIONAL GO — include producer's conditions in the review` / `[B] NO-GO — conditions cannot be met in time` / `[C] GO — I accept the risk and want to proceed`。（Phase 3b）
R14. producer NOT ASSESSED：点名缺失输入——它不是 ON TRACK，**禁止据此推荐 GO**；补输入后重跑 PR-MILESTONE，或推荐 NOT ASSESSED，或按评审自身发现给 CONDITIONAL GO / NO-GO（排序见 `.claude/docs/director-gates.md`）。（Phase 3b）
R15. 保存（Phase 4）：先向用户呈现评审；问 "May I write this to `production/milestones/[milestone-name]-review.md`?"；yes → 写文件（目录不存在则创建），裁决 **COMPLETE** — milestone review saved；no → 就此停止，裁决 **BLOCKED** — user declined write。（Phase 4）
R16. 收尾（Phase 5）：本里程碑标志开发阶段边界 → 跑 `/gate-check` 取正式 phase gate 裁决；跑 `/sprint-plan` 按范围建议调整下个冲刺（`workflow: minimal` 无冲刺，改为调整 brief 的 build order）。（Phase 5）

R7/R9 对应的评审模板（保留原文结构与表列，Phase 3）：

```markdown
# Milestone Review: [Milestone Name]

## Overview
- **Target Date**: [Date]
- **Current Date**: [Today]
- **Days Remaining**: [N]
- **Sprints Completed**: [X/Y]

## Feature Completeness
### Fully Complete
| Feature | Acceptance Criteria | Test Status |
### Partially Complete
| Feature | % Done | Remaining Work | Risk to Milestone |
### Blocked
| Feature | Blocked Stories | Blocker | Next Action / Owner |
### Not Started
| Feature | Priority | Can Cut? | Impact of Cutting |

## Quality Metrics
- **Open S1 Bugs**: [N] -- [List]
- **Open S2 Bugs**: [N]
- **Open S3 Bugs**: [N]
- **Test Coverage**: [X%]
- **Performance**: [Within budget? Details]

## Code Health
- **TODO count**: [N across codebase]
- **FIXME count**: [N]
- **HACK count**: [N]
- **Technical debt items**: [List critical ones]

## Risk Assessment
| Risk | Status | Impact if Realized | Mitigation Status |

## Velocity Analysis
- **Planned vs Completed** (across all sprints): [X/Y tasks = Z%]
- **Trend**: [Improving / Stable / Declining]
- **Adjusted estimate for remaining work**: [Days needed at current velocity]

## Scope Recommendations
### Protect (Must ship with milestone)
### At Risk (May need to cut or simplify)
### Cut Candidates (Can defer without compromising milestone)

## Go/No-Go Assessment
**Recommendation**: [NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]
**Conditions** (if conditional): [Condition 1...]
**Rationale**: [Explanation of the recommendation]

## Action Items
| # | Action | Owner | Deadline |
```

## 4. 门禁与裁决
- **门禁 ID**：PR-MILESTONE（producer 风险评估，`.claude/docs/director-gates/pr-milestone.md`）。`full` → 派 producer 智能体；`solo`/`lean` → 跳过并注记（lean 下它不是 PHASE-GATE）。
- **producer 裁决**：ON TRACK / AT RISK / OFF TRACK / NOT ASSESSED，内联进 Go/No-Go 节。
- **取最严**：OFF TRACK 永不产出 GO；CONDITIONAL GO 仅当用户明确选择；NOT ASSESSED 点名缺失输入且永不折算为 ON TRACK。
- **整体建议枚举**：NOT ASSESSED / GO / CONDITIONAL GO / NO-GO。
- **保存裁决**：COMPLETE（已写）/ BLOCKED（用户拒写）。

## 5. 移植建议
- **可直接移植**：R1-R2（NOT ASSESSED — NO DATA 反假性通过、证据缺失≠无问题）、R4-R6（current 跳过评审文件、章节扫描建分母、零匹配报告整读不丢弃）、R7-R8（Blocked 数据另读、无数据记 NOT ASSESSED 不记零）、R9（Complete 才计分子、Deferred 留分母、Blocked 与 Partially 分开）、R10-R14（四态 go/no-go、OFF TRACK 必问、CONDITIONAL GO 仅限用户明选）、R15（写前必问、拒写即 BLOCKED）。
- **需替换概念**：milestone → 里程碑/版本发布；sprint 报告 → 迭代报告；GDD/epic/story → 需求文档/特性/任务；producer → 项目负责人/交付经理；`/gate-check`、`/sprint-plan` → 阶段评审/迭代计划流程；risk register → 风险登记表。
- **改写示例**：
  - "里程碑评审的完成百分比只统计状态为 Complete 的特性；已延期特性留在分母并注明去向；已启动但被阻塞的特性单列 Blocked 表并点名阻塞原因，不得归入部分完成。"
  - "负责人门禁裁决为 OFF TRACK 时禁止给出 GO 建议，必须先问用户接受 NO-GO、改为有条件 GO（用户自行记录已接受的风险）还是停止先行处理阻塞项。"

## 6. 关联文档
- 上游：`/sprint-plan`（产冲刺报告的章节标题）、`/sprint-status`（产 `sprint-status.yaml` 的 blocked 数据）、`/bug-report`、`/bug-triage`（产 bug 文件）。
- 下游：`/gate-check`（阶段边界的正式裁决）、`/sprint-plan`（按范围建议调整下个冲刺；minimal 档改 brief build order）。
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/director-gates/pr-milestone.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/templates/milestone-definition.md`、`.claude/docs/templates/risk-register-entry.md`。
