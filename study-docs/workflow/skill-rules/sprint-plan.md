# sprint-plan — 创建冲刺计划（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/sprint-plan/SKILL.md) ｜ 阶段：Phase 4-5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/sprint-plan [new|update|status] [--review full|lean|solo]`
- **一句话职责**：从当前里程碑、已完成工作与可用产能，生成新冲刺计划或更新现有计划（`new`/`update`），或产出冲刺状态报告（`status`）。
- **触发前置**：`production/epics/` 下存在故事卡（`new` 的唯一必需输入）；无故事即 BLOCKED——禁止发明工作项。里程碑（`production/milestones/`）与风险登记册（`production/risk-register/`）为可选、多为人工维护、缺失是常态。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, story_granularity, workflow`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | `story_granularity` 按速率定每冲故事数；`review_mode` 定 PR-SPRINT 门禁；无配置时随 `modes.rigor`：minimal→solo、standard→lean |
| 读取 | `production/sprints/` 现有冲刺（前置已 `ls`，禁止重复 glob）；`production/milestones/`（有则读）；`production/sprint-status.yaml`（carryover 状态判定）；`Glob production/epics/**/story-*.md` + `Grep "^> \*\*Status\*\*"`（只取状态与标题，禁逐个读正文）；`design/gdd/` 按章节扫（`minimal` 用 `design/game-brief.md`）；`production/risk-register/`（有则读）；`production/qa/qa-plan-*.md`（Phase 5 检查）；引擎场景文件（Godot `*.tscn` / Unity `Assets/**/*.unity` / Unreal `Content/**/*.umap`） | 先决条件核查用 |
| 产出 | `production/sprints/sprint-NNN.md`（编号三位零填充）；`production/sprint-status.yaml`（机器可读状态源，`/sprint-status`、`/story-done`、`/help` 直读免 markdown 解析） | 两文件经**同一次**写入批准一起写（Phase 5 末尾） |
| 派生智能体 | `producer`（PR-SPRINT 可行性门禁，仅 `full` 模式，读 `.claude/docs/director-gates/pr-sprint.md`；派生的智能体自己读门禁文件，主会话禁止读） | solo/lean 跳过并注明 |

## 3. 核心规则
R1. 参数解析：模式必须是 `new`、`update` 或 `status`；评审模式用已解析块的值（`--review` 只覆盖本次），禁止重新解析、禁止询问。（Phase 0）
R2. **禁止写评审模式**——不写 `project.yaml`、不写 `production/review-mode.txt`：`modes.review_mode` 是 `modes.rigor` 前置的旋钮之一，钉死会永久遮蔽 rigor 展开。一次性差异用 `--review`；要持久改深度，指引用户改 `modes.rigor`（`/settings modes.rigor=<minimal|standard|full>`），或有意识地用 `/settings --local modes.review_mode=<full|lean|solo>`（`project.local.yaml` 个人覆盖）。（Phase 0）
R3. `story_granularity` 定每冲分配的故事数（按速率）：`coarse`（默认，`rigor: minimal`）**2-4**；`balanced`（`rigor: standard`）**6-10**；`fine` **15-25**。Ready 积压小于区间时整批入计划，禁止编故事凑数。（Phase 0）
R4. 里程碑缺失是正常状态而非缺口：注明"no milestone defined — planning against the story backlog alone"后继续；禁止因它阻塞计划、禁止从冲刺文件反推里程碑（该目录只由人工按 `milestone-definition.md` 模板撰写）。（Phase 1）
R5. 上一冲刺读取（`new` 模式）：新冲编号 = Existing Sprints 列表中最高 `sprint-NNN.md` 加一（无则 `001`）；上一冲所有非 `Complete` 的故事（状态以 `sprint-status.yaml` 为准，无则读故事文件 Status 行）进 **Carryover** 表（含 Reason 与 New Estimate），且只在那里出现——禁止再作为新的 Must/Should/Nice to Have 工作出现。（Phase 1）
R6. 积压扫描用 Glob+Grep 取状态与标题而非读正文；`new` 模式只规划标 `Ready` 的故事。glob 为空：停止并提示先跑 `/create-stories`（`standard`/`full` 先 `/create-epics`）；禁止继续发明工作项——引用不存在故事的计划无法实施；`Verdict: BLOCKED — no stories to plan`。（Phase 1）
R7. 设计文档按章节读（Grep `^#` 找标题 + offset/limit 读区间）；`workflow: minimal` 无系统 GDD，用 `design/game-brief.md`，且不得把缺失的 GDD 当成缺失工作（本技能在 `minimal` 是**可选**的——brief 的 Build order 即计划）。（Phase 1）
R8. 风险登记册缺失时说一次"no risk register — risks assessed from the sprint contents only"，禁止默默跳过风险评估；该目录同样只由人工按模板撰写。（Phase 1）
R9. `new` 生成标准格式计划（Sprint Goal 一句话 / Goal Prerequisites 表 / Capacity 含 **20% buffer** / Must Have(关键路径)·Should Have·Nice to Have 三级任务表（列：ID、Task、Agent/Owner、Est. Days、Dependencies、Acceptance Criteria）/ Carryover 表 / Risks 表 / 外部依赖 / 冲刺 DoD 清单）后**只展示、先不问写**——门禁阶段可能要求修订，写入询问在 Phase 5 末尾。（Phase 2）
R9 对应的新冲刺计划模板（保留原文格式约定）：

```markdown
# Sprint [N] — [Start Date] to [End Date]

## Sprint Goal
[One sentence describing what this sprint achieves toward the milestone]

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|

## Capacity
- Total days: [X]
- Buffer (20%): [Y days reserved for unplanned work]
- Available: [Z days]

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|

## Dependencies on External Factors
- [List any external dependencies]

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-[sprint-slug]-[date].md`, from `/qa-plan sprint`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
```

R10. **先决条件核查**（展示 `new` 计划前）：(1) 定目标——有里程碑引用其目标，无则从所选故事写一句；(2) 列"演示目标需要什么"——玩家可见/可玩的目标需要其运行场景与启动设置（Godot 的 `project.godot` 里 `run/main_scene`、Unity 的 `ProjectSettings/EditorBuildSettings.asset` 场景列表、Unreal 的 `Config/DefaultEngine.ini` 里 `GameDefaultMap`），加上被选故事的 AC/注记/依赖点名而没有任何被选故事创建的文件、场景或系统；纯逻辑+测试的目标不需要；(3) 逐项核对——项目里已存在或被选故事会建即 covered，场景按引擎扩展名找（无引擎设置时只按名字查并说明场景搜索未运行）；(4) 填 Goal Prerequisites 表（`exists` / `built by [story ID]` / **missing**，或单行 "None: the goal has nothing to run or show"），missing 项复制进 Risks。（Phase 2）
R11. 先决条件缺口**只报告不解决**：展示计划时点名每个缺失项与三个用户选项（拉入建它的 Ready 故事——点名并说明是否超 `story_granularity` 区间或还需要其依赖；先 `/create-stories` 写一张卡；改写目标只承诺本冲能演示的）。作为计划的一部分给出而非提问——写入询问仍是唯一的问题。缺失项在本计划里保持缺失（哪怕看起来很小）：禁止为它排任务、禁止把它的活塞进被选故事（哪怕是 setup）——它的活需要先有故事，那是 `/create-stories` 的事；禁止添加积压里没有的故事、禁止加宽被选故事或改故事文件来补缺口。（Phase 2）
R12. `update` 模式：读最近一份冲刺计划；展示当前故事清单及 `sprint-status.yaml` 状态；用提问工具收集改动（增/删/重排/重估）；应用后重新展示完整修订版；目标或 Must Have 变了则先重跑先决条件核查；对修订版重跑 Phase 4 门禁；md 与 yaml 一起写（同 `new` 的批准）。**update 不重置故事状态**——已 `in-progress`/`done` 的保持原状，只有 `backlog` 与 `ready-for-dev` 的故事可自由移除或重排。（Phase 2）
R13. `status` 模式产出状态报告（Progress X/Y 与百分比 / Completed·In Progress·Not Started·Blocked 四表 / Burndown Assessment（落后时写砍什么缓什么）/ Emerging Risks）。（Phase 2）
R14. 生成 `new` 计划后同时准备 `production/sprint-status.yaml` 内容但**暂不写**（留在上下文里）——PR-SPRINT（仅 full）可能修订故事清单、QA plan 检查（所有模式）都会先跑；两文件在 Phase 5 后经单次写入批准一起落盘。yaml 头部注释声明自动生成、禁止手工编辑（用 `/story-done` 更新），并给状态映射：`backlog↔Not Started`、`ready-for-dev↔Ready`、`in-progress↔In Progress`、`review↔In Review`、`done↔Complete`、`blocked↔Blocked`。（Phase 3）
R15. yaml 初始化规则：Must Have → `priority: must-have, status: ready-for-dev`；Should Have → `should-have, backlog`；Nice to Have → `nice-to-have, backlog`；Carryover 行 → 沿用原 `priority` 与当前 `status`。每个条目的 `file` 字段必须原样用 Glob 结果里的真实路径。`update` 模式：读现有 yaml，未变故事沿用状态、加新故事、删被去掉的。（Phase 3）
R14/R15 对应的 `production/sprint-status.yaml` 模板（保留原文格式约定）：

```yaml
# Auto-generated by /sprint-plan. Updated by /story-done and /dev-story.
# DO NOT edit manually — use /story-done to update story status.
#
# Status value mapping (yaml ↔ story file Status field):
#   backlog        ↔  Not Started
#   ready-for-dev  ↔  Ready
#   in-progress    ↔  In Progress
#   review         ↔  In Review
#   done           ↔  Complete
#   blocked        ↔  Blocked

sprint: [N]
goal: "[sprint goal]"
start: "[YYYY-MM-DD]"
end: "[YYYY-MM-DD]"
generated: "[YYYY-MM-DD]"
updated: "[YYYY-MM-DD]"

stories:
  - id: "[epic-story, e.g. 1-1]"
    name: "[story name]"
    file: "[production/epics/[epic-slug]/story-NNN-[slug].md]"   # the real path, verbatim from the Glob above
    priority: must-have        # must-have | should-have | nice-to-have
    status: ready-for-dev      # backlog | ready-for-dev | in-progress | review | done | blocked
    owner: ""
    estimate_days: 0
    blocker: ""
    completed: ""
```

R16. PR-SPRINT 门禁（Phase 4，定稿前）：`solo` → 跳过，注明 "PR-SPRINT skipped — Solo mode."；`lean` → 跳过（非 PHASE-GATE），注明 "PR-SPRINT skipped — Lean mode."；`full` → 正常派 `producer` 智能体（门禁文件 `.claude/docs/director-gates/pr-sprint.md`，由被派智能体自己读）。传递：拟选故事清单（标题/估时/依赖）、团队总产能（小时/天）、上一冲 carryover、里程碑约束与截止日、任何缺失的目标先决条件；然后展示制片人评估。（Phase 4）
R17. PR-SPRINT 裁决处理：`UNREALISTIC` → 修订故事选择（降级到 Should/Nice to Have）并重展更新版计划，再进 Phase 5；`NOT ASSESSED` → 点名缺失输入（它不等于 REALISTIC）——补齐重跑，或在计划头部记 `NOT ASSESSED — [missing input]` 后继续并在写入询问时重申；`CONCERNS` → 必须问"Producer flagged concerns with this sprint plan. How do you want to proceed?"，选项 `[A] Proceed as planned — I accept the risk` / `[B] Adjust scope — defer some Should Have stories` / `[C] Extend the sprint timeline`；A→继续，B→修订重展，C→调整日期与产能重展。（Phase 4）
R18. QA plan 门禁（Phase 5，所有模式）：用 Glob 查 `production/qa/qa-plan-*.md`（`/qa-plan` 写 `qa-plan-[sprint-slug]-[date].md`），保留文件名或内容引用本冲编号者。找到：在计划里注 "QA Plan: `[path]`" 后继续。没有：禁止默默继续，必须显式提示（无 QA plan = 测试要求未定义、过不了 Production → Polish 门）并用提问工具问："No QA plan found for this sprint. How do you want to proceed?"，选项 `[A] Run /qa-plan sprint now — ... (Recommended)` / `[B] Skip for now — I understand QA sign-off will be blocked at the Production → Polish gate`。（Phase 5）
R19. QA plan 问题的答案**永远不是写入批准**（哪怕是"好，写吧"/"计划写完就跑"）：必须先等这个答案，再单独问写入问题，只对写入问题的 yes 才写。选 A → 计划注明 "QA plan: run `/qa-plan sprint` before implementation begins."；选 B → 在计划文档加 ⚠️ 警告块（说明须在最后一张故事实现前补跑，Production → Polish 门需要 QA sign-off report，而它需要 QA plan）。（Phase 5）
R20. 写入询问："May I write the sprint plan to `production/sprints/sprint-NNN.md`（`[N]` 三位零填充）and `production/sprint-status.yaml`?"——即使先前某个答案听着像 yes 也要再问一次。yes → 两文件一起写（按需建目录），`Verdict: COMPLETE — sprint plan and status file created`；no → `Verdict: BLOCKED — user declined write`。（Phase 5）
R21. 写入后追加 **Scope check** 提示：本冲含有超出原史诗范围的故事时，实现开始前跑 `/scope-check [epic]` 检测范围蔓延；用户在 Phase 5 选了"现在跑 /qa-plan sprint"则以"Run `/qa-plan sprint` next — then begin implementation."收尾。（Phase 5）
R22. 后续步骤指引（写完且 QA plan 状态已决后）：`/qa-plan sprint`（实现开始前**必需**——为每张卡定义测试用例，开发者按 QA 规格而非空白实现）；`/story-readiness [story-file]`（开工前校验）；`/dev-story [story-file]`（开始实现第一张）；`/sprint-status`（冲中查进度）；`/scope-check [epic]`（实现前查范围蔓延）。（Phase 6）
R23. 评审模式解析链（本技能永不询问、永不写入）：`--review` 旗标 → `project.local.yaml` → `project.yaml` 的 `modes.review_mode` → `production/review-mode.txt`（legacy 回退）→ `modes.rigor` 展开（standard→lean、minimal→solo）。三值：`lean` 跳过非 phase-gate 导演门禁；`full` 全部以派生智能体运行；`solo` 无条件跳过所有门禁派生（单人开发无评审）。该链同样被 `/story-readiness`、`/story-done` 等门禁技能在启动时读取。（Phase 6）

## 4. 门禁与裁决
- **门禁 ID**：PR-SPRINT（producer feasibility，制片人可行性）。
- **触发**：`full` 模式派生运行；`lean`（非 PHASE-GATE）与 `solo` 跳过并注明；传递内容见 R16。
- **裁决标准**：REALISTIC（继续）/ UNREALISTIC（修订降级重展）/ NOT ASSESSED（点名缺失输入，补齐重跑或记录后继续）/ CONCERNS（三选项问用户：接受风险/缩范围/延时间线）。
- **取最严**：NOT ASSESSED 不得当作 REALISTIC；门禁修订发生在写入之前——写入的文件必须已含 Phase 4/5 的全部结果。

## 5. 移植建议
- **可直接移植**：R3（粒度→每冲容量区间、小积压整批入）、R5（carryover 只进专表不重复排班）、R6（无积压即 BLOCKED、禁发明工作）、R9-R11（三级任务表+20% buffer、先决条件核查只报告不解决）、R12（update 不重置进行中状态）、R14-R15（人读计划+机读状态双文件、单次批准一起写、状态映射表）、R17-R20（门禁四态裁决、QA 计划缺失显式化、答案≠写入批准、写入必再问）、R22-R23（后续步骤与评审模式链）。
- **需替换概念**：milestone → 里程碑/发布目标文档；producer → 资源与排期负责人；QA plan → 测试计划文档；`/qa-plan`、`/team-qa`、`/smoke-check`、`/scope-check` → 对应的测试规划/验收/冒烟/范围核查流程；Godot/Unity/Unreal 场景入口 → 项目的可运行入口配置；`sprint-status.yaml` 状态枚举可直接沿用。
- **改写示例**：
  - "冲刺计划与机读状态文件必须经同一次写入批准一起落盘；任何先前问题的肯定回答都不构成写入批准，写入前必须单独再问一次。"
  - "演示目标所需而当前无故事承建的先决条件，只报告不解决：列为 missing、复制进风险表、给出三个补救选项，禁止为它排任务或加宽既有故事。"

## 6. 关联文档
- 上游：`/create-epics`、`/create-stories`（产积压）、人工维护的 `production/milestones/` 与 `production/risk-register/`。
- 下游：`/qa-plan sprint`（实现前必需）、`/story-readiness`、`/dev-story`、`/sprint-status`、`/scope-check [epic]`、`/team-qa sprint`、`/smoke-check sprint`（DoD 引用）。
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/director-gates/pr-sprint.md`、`.claude/docs/automation-modes.md`、`.claude/docs/templates/milestone-definition.md`、`.claude/docs/templates/risk-register-entry.md`、`.claude/docs/config-resolution.md`。
