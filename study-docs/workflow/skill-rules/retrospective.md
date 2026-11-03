# retrospective — 冲刺/里程碑复盘（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/retrospective/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/retrospective [sprint-N|milestone-name]`
- **一句话职责**：基于已完成工作、速度与阻塞，产出冲刺或里程碑复盘——指标、趋势、估计准确度与**可执行的下一代际行动项**。
- **触发前置**：`production/sprints/`（或 `production/milestones/`）有对应计划文件，或 `production/sprint-status.yaml` 存在，或用户手动提供数据，或 `workflow: minimal` 档下有 `Status: Complete` 的故事文件；全无且用户选 Stop → 裁决 BLOCKED。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`automation, workflow, qa.level`（resolve_config） | `workflow: minimal` 无冲刺 → 走"回顾已关闭故事"分支；`qa.level: minimal` 豁免测试 → 无测试关闭的故事不算发现 |
| 读取 | 冲刺计划 `production/sprints/` 或里程碑定义 `production/milestones/`；**`production/sprint-status.yaml`（存在即必须随计划同读，权威真源）**；git log（冲刺期实际提交，见 R7）；代码库 TODO/FIXME/HACK 计数；既往复盘 `production/retrospectives/`（对照上届行动项与速度） | yaml 是故事完成状态的首要来源，markdown 扫描仅在 yaml 不存在时回退 |
| 产出 | `production/retrospectives/retro-sprint-[N]-[date].md`（里程碑：`retro-[milestone-name]-[date].md`），用户同意后才写，目录不存在则创建；"Start fresh" 分支先重命名旧文件加 `-archived-[date]` 后缀（该重命名也是写，须 Phase 5 提问批准） | 结构化复盘文档 |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则
R1. **输入不足先检查，再谈产出**：列出本技能读的全部输入（数据文件、既有报告、profiler 输出、测试结果、registry、源码），逐项记 `FOUND`/`ABSENT`（禁止 "assumed present"）；某节必需输入 ABSENT → 该节记 `NOT ASSESSED — NO DATA`，禁止估算、禁止从相邻产物推断、禁止留空给读者填；**全部**必需输入 ABSENT → 停止并以 `NOT ASSESSED — NO DATA` 作为整体裁决，点名缺什么、哪个技能产它。`NOT ASSESSED` 是**成功**的正确答案——防裁决枚举无"跑不了"状态的报告产出假性干净通过。**证据缺失不等于无问题**：无可扫文件的扫描什么都没验证，必须说清是哪一种。（Insufficient input）
R2. 参数解析（Phase 1）：由参数判定这是冲刺复盘（`sprint-N`）还是里程碑复盘（`milestone-name`）。每次 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录并继续；`automation_always_ask` 类别恒问）。（Phase 1）
R3. 加载任何数据前先查既有复盘（Phase 1b）：冲刺复盘 glob `production/retrospectives/retro-[sprint-slug]-*.md`（**也查备用位置** `production/sprints/sprint-[N]-retrospective.md`）；里程碑复盘 glob `production/retrospectives/retro-[milestone-name]-*.md`。（Phase 1b）
R4. 命中既有文件必问："An existing retrospective was found: [filename]. How do you want to proceed?" 选项 `[A] Update existing — load it and add/revise sections with new data` / `[B] Start fresh — generate a new retrospective (archive the old one)`。选 [A] → 读旧文件、携其内容前进、用新数据修订各节；选 [B] → 空白进入 Phase 2，写新文件前把旧文件重命名加 `-archived-[date]` 后缀——**该重命名也是一次写：放在 Phase 5，且只有那里点名它的提问被批准后才发生**。（Phase 1b）
R5. 加载数据（Phase 2）：从对应位置读冲刺计划（`production/sprints/`）或里程碑定义（`production/milestones/`）。**`production/sprint-status.yaml` 存在即必须随计划同读**：它是故事实际完成状态（`status: done`、`completed` 日期、blockers）的**权威来源**，作为 Phase 3 完成度指标的首要来源；仅当 yaml 不存在才回退 markdown 扫描；yaml 与冲刺计划不一致处（yaml 有计划无的故事、反之亦然）必须注记。（Phase 2）
R6. 计划文件不存在或为空 → 输出："No sprint data found for [sprint/milestone]. Run `/sprint-plan new` to create a sprint (`/sprint-status` only reads one), or provide the sprint details manually."。`workflow: minimal`（已解析）无冲刺 → 主动提议改为回顾至今关闭的故事（`production/epics/*/story-*.md` 中 `Status: Complete` 者）。`qa.level: minimal` 豁免测试 → 无测试关闭的故事**不算发现**；但 Visual/Feel 或 UI 故事没有留存截图就关闭**仍是发现**。（Phase 2）
R7. 缺数据三选项（`AskUserQuestion`，`[C]` 仅 `workflow: minimal` 出现）：`[A] Provide data manually`——用户粘贴或口述冲刺任务、日期、结果，作为复盘真源；`[B] Stop`——中止技能，裁决 **BLOCKED** — no sprint data available；`[C] Look back over the closed stories`——以 `Status: Complete` 的故事为工作记录。选 [A] → 收集后带进 Phase 3；选 [C] → 读那些故事进 Phase 3，**需要冲刺数据的节（planned vs actual、velocity、carryover、estimation accuracy）记 `NOT ASSESSED — NO DATA`**。（Phase 2）
R8. 数据提取：从计划提取 planned tasks、estimated effort、owners、goals。跑 git log 看实际提交了什么、何时提交：`git log --oneline --since="4 weeks ago" 2>/dev/null || git log --oneline -20`（Bash 工具在 Windows 上走 Git Bash——`2>/dev/null` 是 bash 语法，不是 PowerShell）；冲刺时长可从计划得知时调整 `--since` 日期匹配。（Phase 2）
R9. 完成与趋势分析（Phase 3）：对照计划与实际交付，把任务分五类——按计划完成 / 完成但有修改 / 结转（未完成）/ 冲刺中新增（计划外）/ 移除或砍范围。（Phase 3）
R10. **每个 `sprint-status.yaml` 中 `status: blocked` 的故事**都进 Blockers Encountered（`blocker` 字段即 Blocker 列），并在 Action Items for Next Iteration 拿到一条行动项。（Phase 3）
R11. TODO/FIXME 趋势：计当前 TODO/FIXME/HACK 注释数；可得时对照上届冲刺计数（查既往复盘）；注技术债在涨还是在缩。（Phase 3）
R12. 读既往复盘（`production/retrospectives/`，有则读）查三件事：上届行动项是否落实、同类问题是否复发、速度如何趋势。**无更早冲刺或复盘时：Velocity Trend 只保留当前冲刺一行并读 `NOT ASSESSED — NO DATA`，Previous Action Items Follow-Up 就那一行——不编造更早的行、不留空表**。（Phase 3）
R13. 写作准则（全局）：诚实且具体——模糊复盘（"沟通可以更好"）产出的改进同样模糊，用数据和例子；聚焦系统性问题，**不归咎个人**；**行动项限 3-5 条**，更多则稀释焦点；**每条行动项必须有 owner 和 deadline**；核对上届行动项是否完成——反复出现且无人认领的行动项是**流程坏味道**；里程碑复盘还要评估里程碑目标是否达成及其对整体项目时间线的影响。（Guidelines）
R14. 保存（Phase 5）：先呈现复盘与头条发现（完成率、速度趋势、最大阻塞、最重要行动项）；问 "May I write this to `production/retrospectives/retro-sprint-[N]-[date].md`?"（里程碑复盘用 `retro-[milestone-name]-[date].md`）。Phase 1b 选过 Start fresh 时，**同一提问还要点名重命名**："…and rename `[old file]` to `[old file name]-archived-[date].md`?"——yes 则**先重命名再写**；no 则**两件事都不发生**。yes → 写文件（目录不存在则创建 `production/retrospectives/`），裁决 **COMPLETE** — retrospective saved；no → 就此停止，裁决 **BLOCKED** — user declined write。（Phase 5）
R15. 收尾（Phase 6）：`workflow: minimal`（已解析）无冲刺 → **跳过提问**，指向复盘文件并说明行动项进 brief 的 build order。否则问 "Retrospective complete. The action items and velocity data are ready. Would you like to start sprint planning now with this data pre-loaded?" 选项 `[A] Yes — open sprint planning with retro action items and velocity delta pre-populated` / `[B] No — I'll reference the retrospective file manually when I'm ready`。选 [A] → 调 `/sprint-plan new`，传入复盘文件路径与行动项、速度变化摘要供冲刺计划者引用。**里程碑复盘 → 跑 `/gate-check` 正式评估下一阶段就绪度**。（Phase 6）

R9-R12 对应的复盘模板（保留原文结构与表列，Phase 4）：

```markdown
## Retrospective: [Sprint N / Milestone Name]
Period: [Start Date] -- [End Date]
Generated: [Date]

### Metrics
| Metric | Planned | Actual | Delta |
| Tasks | [X] | [Y] | [+/- Z] |
| Completion Rate | -- | [Z%] | -- |
| Story Points / Effort Days | [X] | [Y] | [+/- Z] |
| Bugs Found | -- | [N] | -- |
| Bugs Fixed | -- | [N] | -- |
| Unplanned Tasks Added | -- | [N] | -- |
| Commits | -- | [N] | -- |

### Velocity Trend
| Sprint | Planned | Completed | Rate |
（N-2 / N-1 / N 三行；无更早冲刺时只留当前行并标 NOT ASSESSED — NO DATA）
**Trend**: [Increasing / Stable / Decreasing — 或 NOT ASSESSED — NO DATA]

### What Went Well / What Went Poorly
（Poorly 不指名归咎——聚焦系统性成因；问题须带可测影响，如 "Feature X took 5 days instead of estimated 2, blocking tasks Y and Z"）

### Blockers Encountered
| Blocker | Duration | Resolution | Prevention |

### Estimation Accuracy
| Task | Estimated | Actual | Variance | Likely Cause |
**Overall estimation accuracy**: [X%] of tasks within +/- 20% of estimate

### Carryover Analysis
| Task | Original Sprint | Times Carried | Reason | Action |
（Action = Complete / Descope / Redesign）

### Technical Debt Status
- Current TODO count: [N] (previous: [N]) · FIXME · HACK · Trend: [Growing / Stable / Shrinking]

### Previous Action Items Follow-Up
| Action Item (from Sprint N-1) | Status | Notes |
（Status = Done / In Progress / Not Started；无上届就那一行说明）

### Action Items for Next Iteration
| # | Action | Owner | Priority | Deadline |
（限 3-5 条，每条必有 owner 与 deadline）

### Process Improvements
（2-3 条可执行项，不是愿望清单）

### Summary
（2-3 句：这届好不好？接下来最该改的一件事？）
```

## 4. 门禁与裁决
- 本技能无审查门禁、无派生智能体。内含裁决：
- **保存裁决**：COMPLETE（已写）/ BLOCKED（用户拒写，或无冲刺数据时用户选 Stop）。
- **无数据裁决**：`NOT ASSESSED — NO DATA`（按节或整体，见 R1/R7/R12）。

## 5. 移植建议
- **可直接移植**：R1（NOT ASSESSED 反假性通过）、R3-R4（既有复盘先问更新还是重开；重命名也是写须获批且"no 则两件事都不发生"）、R5（机读状态文件优先于 markdown 扫描、不一致处注记）、R6-R7（数据缺失三选项分流 + minimal 档改回顾已完成任务）、R10（blocked 必产行动项）、R12（无历史不编造行不留空表）、R13（±20% 估计准确度、行动项 3-5 条带 owner/deadline、复现行动项=流程坏味道）、R14（写前必问、先重命名再写）。
- **需替换概念**：sprint → 迭代；story/epic → 任务/特性；`sprint-status.yaml` → 机读任务状态文件；Visual/Feel/UI 留存截图 → 需留存证据的交付物；`/sprint-plan`、`/gate-check` → 计划/阶段评审流程。
- **改写示例**：
  - "复盘的行动项限 3-5 条，每条必须有负责人和截止日期；上一届的行动项必须逐条核对状态，同一行动项连续两届无人认领即标记为流程问题。"
  - "估算准确度以落在估计值 ±20% 以内的任务占比计；速度趋势表无更早迭代数据时只保留当前一行并标注 NOT ASSESSED，禁止虚构历史行。"

## 6. 关联文档
- 上游：`/sprint-plan`（产冲刺计划与 `sprint-status.yaml`）、`/story-done`（产故事 Complete 状态，minimal 档数据源）。
- 下游：`/sprint-plan new`（带着行动项与速度差开下届计划）、`/gate-check`（里程碑复盘后的阶段就绪评估）。
- 引用：`.claude/docs/automation-modes.md`。
