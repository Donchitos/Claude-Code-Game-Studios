# sprint-status — 30 行冲刺快照（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/sprint-status/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/sprint-status [sprint-编号，留空=当前冲刺]`
- **一句话职责**：快速态势感知检查（非冲刺评审）——读当前冲刺计划与故事文件、扫状态标记、产出一目了然的简短快照（引言目标 30 行内；输出阶段以 50 行为上限、状态表不得截断）。详细管理走 `/sprint-plan update` 或 `/milestone-review`。
- **触发前置**：`production/sprints/` 有冲刺文件；或 `workflow: minimal` 档下有故事文件（该档按设计无冲刺，brief 的 build order 即计划）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`story_granularity, workflow`（resolve_config） | `story_granularity` 定燃尽读数颗粒：`coarse`（默认，`rigor: minimal`）= 特性级、`balanced`（`rigor: standard`）= 任务级、`fine` = AC 级 |
| 读取 | 冲刺文件整读（编号/目标/起止日期/任务条目含优先级、owner、估时）；`production/sprint-status.yaml`（存在即权威真源，免 markdown 扫描）；故事文件的状态标记（仅 yaml 缺失时的回退）；`story-status.sh`（minimal 档、技能加载前已输出）；一次性 Grep 全部故事卡的 Last Updated 变体；可选：代码根按系统 slug 查实现痕迹 | 只读快照 |
| 产出 | 无文件写入——纯回复输出 | **本技能只读**：不改冲刺计划、不改故事状态、不提议砍范围、每次运行至多一条具体建议 |
| 派生智能体 | 无，主会话直接执行 | 快技能（haiku 模型） |

## 3. 核心规则
R1. 定位冲刺：有参数（如 `/sprint-status 3`）→ 在 `production/sprints/` 找 `sprint-003.md`、`sprint-03.md`、`sprint-3.md` 之类匹配（`/sprint-plan` 写三位数）并报告命中哪个文件；无参数 → 取目录中最近修改的文件为当前冲刺。（1）
R2. `production/sprints/` 不存在或为空时：`workflow: minimal` 档按设计无冲刺——brief 的 build order 即计划、故事文件承载它，改报 build order 进度后停止；`standard`/`full` 档报告 "No sprint files found. Start a sprint with `/sprint-plan new`." 后停止。（1）
R3. `minimal` 档快照：`story-status.sh` 已在技能加载前输出清单（每未完成故事一行，按 IN_REVIEW → IN_PROGRESS → TODO（Ready 或 Not Started，按 build order）→ BLOCKED → OTHER → NO_STATUS 排列，末行 COMPLETE 计数），**禁止重跑脚本、禁止重排故事**——In Review 的故事先于 In Progress 的关闭：它的工作已写完。15 行内打印 `Build order: [N] of [M] stories complete`（只计 Complete 与 Done，`In Review` 不算完成）+ **Next**（首个 IN_REVIEW/IN_PROGRESS/TODO 行的故事）：IN_REVIEW 推荐 `/story-done [path]`，IN_PROGRESS/TODO 推荐 `/dev-story [path]`；每个 BLOCKED 故事点名其 blocker，它永远不是 Next。（1）
R4. `minimal` 档收尾分支：全部 Complete/Done → "Build order done: [M] of [M] stories complete." 并给三条出路（玩一下构建产物；用 `/create-stories` 从 brief 加下一批故事；游戏已超出一页 brief 时用 `/settings` 调高 `modes.rigor`）；`STORIES none` → 提示跑 `/create-stories`；无 IN_REVIEW/IN_PROGRESS/TODO 但 COMPLETE 不足总数 → **没有 Next、build order 也没完成**（禁止说完成），打印 Build order 行，逐个点名 BLOCKED 故事及其 blocker（读故事文件、通常是 `BLOCKED:` 注记）与其余故事的原样状态，只推荐一步：第一个 blocker 需要什么，或先完成第一张 Draft/无状态故事并把 Status 设为 Ready。（1）
R5. 读冲刺文件全文，提取：冲号与目标、起止日期、全部故事/任务条目（优先级 Must/Should/Nice to Have、owner、估时）。（1）
R6. 天数计算：用今天与冲刺结束日算总天数、已过天数、剩余天数、时间消耗百分比；冲刺文件无显式日期 → 注明 "Sprint dates not found — burndown assessment skipped."。（2）
R7. 状态扫描优先级：先查 `production/sprint-status.yaml`——存在即直接读（**权威真源**），取每故事的 `status` 及 `priority`/`owner`/`blocker` 填表，用其 `sprint`/`goal`/`start`/`end` 字段免重复解析计划。（3）
R8. yaml 不存在（legacy 或首次）时回退 markdown 扫描：条目引用故事路径 → 查文件存在并读它扫状态标记（DONE、COMPLETE、IN PROGRESS、BLOCKED、NOT STARTED，大小写不敏感）；无路径的内联任务 → 在计划里该条目旁扫标记；无标记 → 记 NOT STARTED；引用的文件不存在 → 记 MISSING 并注明。回退时必须在输出底部加注："⚠ No `sprint-status.yaml` found — status inferred from markdown. Run `/sprint-plan update` to generate one."（3）
R9. 可选实现痕迹检查（只做快查、禁深扫）：grep 代码根中与故事系统 slug 匹配的目录或文件名——仅是提示，不是定论状态。（3）
R10. **过期检测**：收齐状态后检查每个 IN PROGRESS 故事是否过期。日期用**一次跨故事集的 Grep**（禁止逐个读文件——单行日期，逐个打开就是本检查的全部成本）：pattern `\*{0,2}(Last Updated|Updated|last-updated|updated_at)\*{0,2}[[:space:]]*:`，glob `production/epics/**/story-*.md`，content 模式。`\*{0,2}` 包装是关键：`/create-stories` 生成 `> **Last Updated**: …`，裸 `Updated:` 锚会静默失配（每个进行中故事都报 never stamped、检测永不触发）。无匹配 = 无日期 ≠ 过期：报 "never stamped"、不算天数。日期距今超过 **4 天** → 标 **STALE**（4 天阈值兼容周末：周五动过的故事到周三才算 stale）。故事文件无日期字段 → "no timestamp — cannot check staleness."；内联任务 → "inline task — cannot check staleness."。STALE 故事进状态表并汇入 "Attention Needed" 节。（3）
R11. **过期升级**：任一 IN PROGRESS 故事 STALE（4+ 天无进展）→ 燃尽判定至少升级为 **At Risk**——即使完成百分比仍在 On Track 窗口内。升级理由格式："At Risk — [S] stale story(ies): [title] ([D] days)[, …]"，[S] 为 STALE 数，每个故事用**自己的** [D]（各自 Last Updated 距今天数；不是最老值、不是平均值）。（3）
R12. 燃尽计算：统计 DONE/COMPLETE、IN PROGRESS、BLOCKED、NOT STARTED 或 MISSING 各计数；完成率 =（完成/总数）×100。对比完成率与时间消耗率：**On Track** = 完成率在时间消耗率 10 个点以内或领先；**At Risk** = 落后 10-25 个点；**Behind** = 落后超过 25 个点。无日期 → 跳过并报 "On Track / At Risk / Behind: unknown — sprint dates not found."。（4）
R13. 输出格式（简洁；状态表强制完整不截断；总行数以 50 行为目标、无值得注意的发现时省略 Emerging Risks 节）：标题（冲号+日期）→ Sprint Goal → Days Remaining（含时间消耗%）→ Progress（完成/总数与百分比）→ 状态表（列：Story/Task、Priority、Status、Owner、Blocker）→ Attention Needed（无过期/时间戳问题则整节省略）→ Burndown（1-2 句；落后时点哪些 Must Have 有险；正常时确认并提示可拉的 Should Have）→ Must-Haves at Risk（BLOCKED 或 NOT STARTED 且剩余冲刺时间不足 40% 者；无则写 "None."）→ Emerging Risks（缺文件、级联 blocker、无 owner 故事；无则 "None identified."）→ Recommendation（**恰好一条**具体动作，或 "Sprint is on track — no action needed."）。（5）
R13 对应的输出模板（保留原文格式约定）：

```markdown
## Sprint [N] Status — [Today's Date]
**Sprint Goal**: [from sprint plan]
**Days Remaining**: [N] of [total] ([% time consumed])

### Progress: [complete/total] tasks ([%])

| Story / Task         | Priority   | Status      | Owner   | Blocker        |
|----------------------|------------|-------------|---------|----------------|
| [title]              | Must Have  | DONE        | [owner] |                |
| [title]              | Must Have  | IN PROGRESS | [owner] |                |
| [title]              | Must Have  | BLOCKED     | [owner] | [brief reason] |
| [title]              | Should Have| NOT STARTED | [owner] |                |

### Attention Needed
| Story / Task         | Status      | Last Updated   | Days Stale | Note           |
|----------------------|-------------|----------------|------------|----------------|
| [title]              | IN PROGRESS | [date or N/A]  | [N days]   | [STALE / no timestamp — cannot check staleness / inline task — cannot check staleness] |

*(Omit this section entirely if no IN PROGRESS stories are stale or have timestamp concerns.)*

### Burndown: [On Track / At Risk / Behind]
[1-2 sentences. If behind: which Must Haves are at risk. If on track: confirm
and note any Should Haves the team could pull.]

### Must-Haves at Risk
[List any Must Have stories that are BLOCKED or NOT STARTED with less than
40% of sprint time remaining. If none, write "None."]

### Emerging Risks
[Any risks visible from the story scan: missing files, cascading blockers,
stories with no owner. If none, write "None identified."]

### Recommendation
[One concrete action, or "Sprint is on track — no action needed."]
```

R14. **快速升级规则**（输出前套用，触发时旗标放在输出最顶部、状态表之上）：关键旗标——Must Have 故事 BLOCKED 或 NOT STARTED 且剩余时间 <40%：`SPRINT AT RISK: [N] Must Have stories are not complete with [X]% of sprint time remaining. Recommend replanning with /sprint-plan update.`；完成旗标——全部 Must Have DONE：`All Must Haves complete. Team can pull from Should Have backlog.`；缺故事旗标——有被引用故事文件不存在：`NOTE: [N] story files referenced in the sprint plan are missing. Run /story-readiness sprint to validate story file coverage.`。（6）
R15. 协作协议（只读铁律）：报告磁盘文件的可观察事实；不更新冲刺计划、不改故事状态、不提议砍范围（那是 `/sprint-plan update` 的事）、每次运行至多一条建议。要看单故事细节 → 用户直接读故事文件或跑 `/story-readiness [path]`；重排冲刺 → `/sprint-plan update`；冲刺末回顾 → `/retrospective`。（协作协议）

## 4. 门禁与裁决
- 本技能无审查门禁、无派生智能体。内含两处裁决：
- **燃尽三态**：On Track / At Risk / Behind（10/25 点阈值，见 R12），且 STALE 升级只升不降（R11）。
- **升级旗标三态**：Critical（SPRINT AT RISK）/ Completion（All Must Haves complete）/ Missing stories（NOTE），置于输出顶部。

## 5. 移植建议
- **可直接移植**：全部规则几乎与游戏无关——R1-R2（定位与缺失分流）、R3-R4（无冲刺档的 build order 快照与 Next 推荐顺序）、R6-R8（双源状态：机读真源优先、markdown 回退带警示）、R10-R11（一次性 Grep 取日期、4 天 STALE 阈值、过期升级）、R12-R14（三态燃尽、40% 剩余时间的 Must Have 告警、旗标置顶）、R15（只读+至多一条建议）。
- **需替换概念**：sprint → 迭代；Must/Should/Nice to Have → 优先级分档；`sprint-status.yaml` → 机读任务状态文件；brief build order → 无迭代流程时的任务序列；`/story-done`、`/dev-story`、`/sprint-plan`、`/retrospective` → 对应的完成/实现/计划/回顾流程。
- **改写示例**：
  - "状态扫描优先读机读状态文件（权威真源），缺失才回退扫 markdown 并在输出底部加注生成指引；禁止两种来源混用。"
  - "任一进行中任务 4 天以上无更新即标 STALE，且整体燃尽判定至少升至 At Risk；日期必须用一次跨全量任务文件的批量检索取得，禁止逐文件打开。"

## 6. 关联文档
- 上游：`/sprint-plan new|update`（产冲刺文件与 `sprint-status.yaml`）、`/create-stories`（产故事，minimal 档的数据源）。
- 下游/跳转：`/sprint-plan update`（重排）、`/story-readiness [path]`（单故事细节）、`/retrospective`（回顾）、`/story-done`、`/dev-story`（Next 推荐）。
