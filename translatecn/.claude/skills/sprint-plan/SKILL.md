---
name: sprint-plan
description: "New or updated sprint plan from the current milestone, completed work, and available capacity."
argument-hint: "[new|update|status] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/sprint-plan/../../hooks/yaml-helper.sh" resolve_config *), Bash(ls production/sprints/*)
model: sonnet
---
---
name: sprint-plan
description: "基于当前里程碑、已完成工作与可用容量，创建新的或更新现有的冲刺计划。"
argument-hint: "[new|update|status] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/sprint-plan/../../hooks/yaml-helper.sh" resolve_config *), Bash(ls production/sprints/*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,story_granularity,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Sprint Plan
# 冲刺计划


## Existing Sprints
## 现有冲刺

!`ls production/sprints/ 2>/dev/null || echo "(no production/sprints/ directory yet)"`

Resolved before this skill runs — use it to identify the previous sprint in
Phase 1 rather than re-globbing.
在此技能运行之前已解析 — 用它来在阶段 1 识别上一个冲刺，
而不是重新 glob。

---

## Phase 0: Parse Arguments
## 阶段 0：解析参数

Extract the mode argument (`new`, `update`, or `status`).
提取模式参数（`new`、`update` 或 `status`）。

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.
完整检查模式参见 `.claude/docs/director-gates.md`。各门禁定义位于 `.claude/docs/director-gates/[gate-id].md` — 被启动的智能体读取它自己的门禁文件；不要在父会话中读取它。


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅在重大选择上询问 · 自主模式记录后继续；
`automation_always_ask` 类别总是询问）。

**`story_granularity`** — it sets how
many stories to allocate per sprint, scaled by velocity: **2–4** at `coarse` (the default, via `rigor: minimal`),
**6–10** at `balanced` (`rigor: standard`), **15–25** at `fine`. A Ready backlog
smaller than the range is planned whole — never padded with invented stories.
**`story_granularity`** — 它设定
每个冲刺分配多少个故事，按速度缩放：`coarse`（默认，经由 `rigor: minimal`）下 **2–4**，
`balanced`（`rigor: standard`）下 **6–10**，`fine` 下 **15–25**。Ready 待办
小于该区间时整体规划 — 绝不用凭空编造的故事填充。

**Review mode check** (before gates run):
- Use the review mode from the resolved block above (`--review` overrides it
  for this run) — do not re-resolve it, and do not ask for it. With nothing
  configured it follows `modes.rigor`: `solo` at `minimal`, `lean` at `standard`.
- **Never write a review mode** — not to `project.yaml`, not to
  `production/review-mode.txt`. `modes.review_mode` is one of the knobs
  `modes.rigor` fronts: pinning it in `project.yaml` shadows the rigor
  expansion, and the legacy file sits *above* that expansion, so either write
  would freeze director-review depth for good. `--review` covers a one-off. If
  the user wants a different depth to persist, point them to changing
  `modes.rigor` (`/settings modes.rigor=<minimal|standard|full>`), or to pinning
  it on purpose with `/settings --local modes.review_mode=<full|lean|solo>` (a
  personal override in `project.local.yaml`).
**评审模式检查**（在门禁运行之前）：
- 使用上文已解析块中的评审模式（本次运行 `--review` 会覆盖它）
  — 不要重新解析它，也不要询问它。未配置任何内容时它遵循 `modes.rigor`：
  `minimal` 下为 `solo`，`standard` 下为 `lean`。
- **绝不写入评审模式** — 不写 `project.yaml`，不写
  `production/review-mode.txt`。`modes.review_mode` 是 `modes.rigor`
  所前置的旋钮之一：在 `project.yaml` 中固定它会遮蔽严谨度展开，
  而遗留文件位于该展开*之上*，所以任一写入
  都会永久冻结总监评审深度。`--review` 覆盖一次性使用。若
  用户希望不同的深度持久化，请指引他们更改
  `modes.rigor`（`/settings modes.rigor=<minimal|standard|full>`），或有意
  用 `/settings --local modes.review_mode=<full|lean|solo>` 固定它（在
  `project.local.yaml` 中的个人覆盖）。

---

## Phase 1: Gather Context
## 阶段 1：收集上下文

1. **Read the current milestone** from `production/milestones/` **if it exists**.
   No skill writes this directory — it is authored by hand from
   `.claude/docs/templates/milestone-definition.md`. On the majority of projects
   it is absent, which is the normal state, not a gap: note "no milestone
   defined — planning against the story backlog alone" and continue. Never block
   sprint planning on it, and never infer a milestone from the sprint files.
1. **读取当前里程碑**（来自 `production/milestones/`，**若存在**）。
   没有技能写入该目录 — 它由人依据
   `.claude/docs/templates/milestone-definition.md` 手工编写。在大多数项目中
   它不存在，这是正常状态，而非缺口：注明"未定义里程碑 —
   仅依据故事待办规划"并继续。绝不要因它而阻塞
   冲刺规划，也绝不要从冲刺文件推断里程碑。

2. **Read the previous sprint** (if any) from `production/sprints/` to
   understand velocity and carryover. In `new` mode:
   - The new sprint's number `[N]` is the highest `sprint-NNN.md` in the
     Existing Sprints listing plus one (`001` when there is none). It is the
     `[N]` in the plan's title, its QA plan path and the write ask.
   - Every story of the previous sprint that is not `Complete` — by its status
     in `production/sprint-status.yaml`, else its story file's Status line —
     goes in the Carryover table with a Reason and a New Estimate. It appears
     only there, never again as new Must Have / Should Have / Nice to Have work.
2. **读取上一个冲刺**（若有，来自 `production/sprints/`），以
   了解速度与结转。在 `new` 模式下：
   - 新冲刺的编号 `[N]` 是 Existing Sprints 列表中最高 `sprint-NNN.md`
     加一（没有时为 `001`）。它就是
     计划标题、其 QA 计划路径与写入提问中的 `[N]`。
   - 上一个冲刺中每个非 `Complete` 的故事 — 依据其在
     `production/sprint-status.yaml` 中的状态，否则依据其故事文件的 Status 行 —
     进入结转表，附原因与新估算。它只出现在
     那里，绝不再作为新的 Must Have / Should Have / Nice to Have 工作出现。

3. **Find the stories to plan** — this is the actual backlog, and it is the one
   input this phase cannot do without:
   ```
   Glob production/epics/**/story-*.md
   Grep pattern="^> \*\*Status\*\*" glob="production/epics/**/story-*.md" output_mode="content"
   ```
   Stories live at `production/epics/[epic-slug]/story-NNN-[slug].md` — that is
   where `/create-stories` writes them and where `/dev-story` looks for them. Plan
   from the ones marked `Ready`. Use the grep rather than reading each story: at
   this stage you need status and title, not the body.
3. **找出要规划的故事** — 这就是实际的待办，且它是此阶段
   不可或缺的唯一输入：
   ```
   Glob production/epics/**/story-*.md
   Grep pattern="^> \*\*Status\*\*" glob="production/epics/**/story-*.md" output_mode="content"
   ```
   故事位于 `production/epics/[epic-slug]/story-NNN-[slug].md` — 那正是
   `/create-stories` 写入它们、`/dev-story` 查找它们的位置。从标记为 `Ready`
   的故事进行规划。使用 grep 而非逐个读取故事：在
   此阶段你需要的是状态与标题，而非正文。

   If the glob returns nothing: "No stories found under `production/epics/`. Run
   `/create-stories` first (at `standard`/`full`, `/create-epics` before it)."
   Do not proceed to invent work items — a sprint plan that references stories
   which do not exist cannot be implemented. Verdict: **BLOCKED** — no stories to plan.
   若 glob 返回空："在 `production/epics/` 下未找到故事。请先运行
   `/create-stories`（在 `standard`/`full` 下，先运行 `/create-epics`）。"
   不要继续凭空编造工作项 — 引用了不存在故事的冲刺计划
   无法被实施。裁决：**BLOCKED** — 没有可规划的故事。

4. **Scan design documents** in `design/gdd/` for additional context on the
   features those stories implement. Read each by section: find the headings you
   need with the Grep tool (pattern `^#`, content mode) and Read those ranges
   with offset and limit. At `workflow: minimal` there are no
   per-system GDDs — use `design/game-brief.md` instead, and do not treat the
   absent GDDs as missing work. (Note: `/sprint-plan` is **optional** at
   `minimal` — the brief's Build order already is the plan.)
4. **扫描 `design/gdd/` 中的设计文档**，获取这些故事所实现功能的
   额外上下文。按小节读取每个文档：用 Grep 工具（模式 `^#`，content 模式）
   找到你需要的标题，再用 offset 与 limit 读取那些范围。
   在 `workflow: minimal` 下没有逐系统 GDD — 改用 `design/game-brief.md`，
   且不要把缺失的 GDD 视为缺失的工作。（注：`/sprint-plan` 在
   `minimal` 下是**可选的** — 简报的 Build order 已经是计划。）

5. **Check the risk register** at `production/risk-register/` **if it exists**.
   Like the milestone above, no skill writes it — entries are authored by hand
   from `.claude/docs/templates/risk-register-entry.md`. If the directory is
   absent, say so once ("no risk register — risks assessed from the sprint
   contents only") rather than skipping risk assessment silently.
5. **检查 `production/risk-register/` 中的风险登记册**（**若存在**）。
   与上文里程碑一样，没有技能写入它 — 条目由人依据
   `.claude/docs/templates/risk-register-entry.md` 手工编写。若目录
   缺失，说明一次（"无风险登记册 — 风险仅依据冲刺
   内容评估"），而不是静默跳过风险评估。

---

## Phase 2: Generate Output
## 阶段 2：生成输出

For `new`:
对于 `new`：

**Generate a sprint plan** following this format and present it to the user. Do NOT ask to write yet — the gate phases run first and may require revisions before the file is written: the producer feasibility gate (Phase 4, spawned only in `full` review mode — skipped in `lean`/`solo`) and the QA plan check (Phase 5, all modes).
**生成冲刺计划**，遵循此格式并呈现给用户。**不要**此时请求写入 — 门禁阶段先运行，且在文件写入之前可能需要修订：producer 可行性门禁（阶段 4，仅在 `full` 评审模式下启动 — `lean`/`solo` 中跳过）与 QA 计划检查（阶段 5，所有模式）。

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

### Check the goal's prerequisites
### 检查目标的前置条件

Before you present a `new` plan, check that its goal can be shown working by the
sprint's end. A goal can need something no story builds: a playtest needs a
scene to run in. This check reports and never blocks. It adds no question and no
story of its own.
在你呈现 `new` 计划之前，检查其目标能否在冲刺结束时被展示为可运行。
目标可能需要某个没有故事去构建的东西：试玩需要一个可运行的
场景。此检查只报告，绝不阻塞。它不添加任何问题，也不添加
自己的故事。

1. **Settle the goal.** Quote the milestone's goal when there is one; otherwise
   write one sentence from the stories picked.
2. **List what showing it needs.** A goal the player can see or play (a playable
   loop, a feature working end to end, a playtest) needs the scene or level it
   runs in and the setting that starts it: `run/main_scene` in `project.godot`,
   the scene list in Unity's `ProjectSettings/EditorBuildSettings.asset`, or
   `GameDefaultMap` in Unreal's `Config/DefaultEngine.ini`. Add any file, scene
   or system that a picked story's acceptance criteria, notes or dependencies
   name and no picked story creates. A goal with nothing to run or show (logic
   and tests only) needs none.
3. **Check each one.** It is covered when it exists in the project or a picked
   story builds it. Find scenes by the engine's scene files (`engine.name` in
   `project.yaml`): `*.tscn` for Godot, `Assets/**/*.unity` for Unity,
   `Content/**/*.umap` for Unreal. Find anything else by the path or name the
   stories use. With no engine set, check by name only and say the scene search
   did not run.
4. **Fill in the Goal Prerequisites section**: each need with `exists`,
   `built by [story ID]` or **missing**, or the single row "None: the goal has
   nothing to run or show". Copy each missing one into Risks. When you present
   the plan, name each missing one and the three fixes open to the user: pull in
   the Ready story that builds it (name it, and say if that takes the sprint past
   its `story_granularity` range or needs stories it depends on), write a story
   for it first with `/create-stories`, or reword the goal to promise only what
   the sprint can show. Give them as part of the plan,
   not as a question: the write ask stays the only question, and a user who
   wants a fix says so in reply to it. **Report the gap; do not solve it.** A
   missing prerequisite stays missing in this plan, however small it looks (a
   flat test level, an input map): plan no task for it and put none of its work
   into a picked story, not even as setup. Its work needs a story first, which
   is `/create-stories`' job. Never add a story the backlog does not
   hold, and never widen a picked story or edit a story file to cover the gap.
1. **敲定目标。** 若里程碑有目标则引用它；否则
   从所选故事写出一句话。
2. **列出展示它所需的东西。** 玩家可以看见或游玩的目标（可游玩的
   循环、端到端可用的功能、一次试玩）需要其运行的场景或关卡
   以及启动它的设置：`project.godot` 中的 `run/main_scene`、
   Unity 的 `ProjectSettings/EditorBuildSettings.asset` 中的场景列表，或
   Unreal 的 `Config/DefaultEngine.ini` 中的 `GameDefaultMap`。添加任何
   被选故事的验收标准、说明或依赖所点名、且没有任何被选故事创建的
   文件、场景或系统。没有东西可运行或展示的目标（仅逻辑
   与测试）则不需要。
3. **逐项检查。** 当它存在于项目中，或某个被选故事构建它时，即视为已覆盖。
   按引擎的场景文件（`project.yaml` 中的 `engine.name`）查找场景：
   Godot 为 `*.tscn`，Unity 为 `Assets/**/*.unity`，
   Unreal 为 `Content/**/*.umap`。其他内容按故事使用的路径或名称
   查找。未设置引擎时，仅按名称检查，并说明场景搜索
   未运行。
4. **填写 Goal Prerequisites 小节**：每项需求标注 `exists`、
   `built by [story ID]` 或 **missing**，或写单行"None: the goal has
   nothing to run or show"。将每个缺失项复制到 Risks。呈现
   计划时，点名每个缺失项以及用户可用的三种修复方式：纳入
   构建它的 Ready 故事（点名它，并说明这是否会使冲刺超出
   其 `story_granularity` 区间或需要其依赖的故事）、先用 `/create-stories`
   为它写一个故事，或改写目标以只承诺
   冲刺能展示的内容。将它们作为计划的一部分给出，
   而不是作为问题：写入提问仍是唯一的问题，想要修复的用户
   在回复中说明即可。**报告缺口；不要解决它。** 一个
   缺失的前置条件在此计划中保持缺失，无论它看起来多么小（一个
   扁平测试关卡、一个输入映射）：不为它规划任何任务，也不把它的任何工作
   放进被选故事，哪怕作为设置也不行。它的工作需要先有故事，那是
   `/create-stories` 的职责。绝不添加待办中不存在的
   故事，也绝不拓宽被选故事或编辑故事文件来覆盖该缺口。

For `update`:
对于 `update`：

**Update an existing sprint plan**:
**更新现有冲刺计划**：

1. Read the most recent sprint plan from `production/sprints/`.
2. Present the current story list with their current statuses from `production/sprint-status.yaml`.
3. Ask the user what to change: stories to add, remove, reprioritize, or re-estimate. Use `AskUserQuestion` to gather changes.
4. Apply the changes and re-present the full revised plan for review. If the
   goal or the Must Have stories changed, check the goal's prerequisites again first.
5. Re-run the producer feasibility gate (Phase 4) on the revised plan.
6. Write the updated markdown plan and yaml together (same approval as `new` mode).
1. 从 `production/sprints/` 读取最近的冲刺计划。
2. 从 `production/sprint-status.yaml` 呈现当前故事列表及其当前状态。
3. 询问用户要更改什么：要添加、移除、重新排序优先级或重新估算的故事。使用 `AskUserQuestion` 收集更改。
4. 应用更改并重新呈现完整修订后的计划以供评审。若
   目标或 Must Have 故事发生变化，先再次检查目标的前置条件。
5. 在修订后的计划上重跑 producer 可行性门禁（阶段 4）。
6. 将更新后的 markdown 计划与 yaml 一起写入（批准方式与 `new` 模式相同）。

Note: `update` mode does not reset story statuses. Stories already marked `in-progress` or `done` keep their status. Only `backlog` and `ready-for-dev` stories can be removed or reprioritized freely.
注：`update` 模式不重置故事状态。已标记为 `in-progress` 或 `done` 的故事保持其状态。只有 `backlog` 与 `ready-for-dev` 的故事可以自由移除或重新调整优先级。

For `status`:
对于 `status`：

**Generate a status report**:
**生成状态报告**：

```markdown
# Sprint [N] Status -- [Date]

## Progress: [X/Y tasks complete] ([Z%])

### Completed
| Task | Completed By | Notes |
|------|-------------|-------|

### In Progress
| Task | Owner | % Done | Blockers |
|------|-------|--------|----------|

### Not Started
| Task | Owner | At Risk? | Notes |
|------|-------|----------|-------|

### Blocked
| Task | Blocker | Owner of Blocker | ETA |
|------|---------|-----------------|-----|

## Burndown Assessment
[On track / Behind / Ahead]
[If behind: What is being cut or deferred]

## Emerging Risks
- [Any new risks identified this sprint]
```

---

## Phase 3: Prepare Sprint Status File
## 阶段 3：准备冲刺状态文件

After generating a new sprint plan, also prepare the `production/sprint-status.yaml` content.
This is the machine-readable source of truth for story status — read by
`/sprint-status`, `/story-done`, and `/help` without markdown parsing.
生成新的冲刺计划后，还要准备 `production/sprint-status.yaml` 的内容。
这是故事状态的机器可读真实来源 — 由
`/sprint-status`、`/story-done` 与 `/help` 无需解析 markdown 即可读取。

**Do not write the yaml yet** — hold it in context. The producer feasibility gate (Phase 4, `full` review mode only) may revise the story list; the QA plan check (Phase 5) runs in every mode. Both files are written together after Phase 5 in a single write approval.
**不要此时写入 yaml** — 将其留在上下文中。producer 可行性门禁（阶段 4，仅 `full` 评审模式）可能修订故事列表；QA 计划检查（阶段 5）在每种模式下都运行。两个文件在阶段 5 之后通过一次写入批准一起写入。

Format:
格式：

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

Initialize each story from the sprint plan's task tables:
- Must Have tasks → `priority: must-have`, `status: ready-for-dev`
- Should Have tasks → `priority: should-have`, `status: backlog`
- Nice to Have tasks → `priority: nice-to-have`, `status: backlog`
- Carryover rows → the story's previous `priority`, and the `status` it has now
从冲刺计划的任务表初始化每个故事：
- Must Have 任务 → `priority: must-have`、`status: ready-for-dev`
- Should Have 任务 → `priority: should-have`、`status: backlog`
- Nice to Have 任务 → `priority: nice-to-have`、`status: backlog`
- 结转行 → 该故事先前的 `priority`，以及它当前具有的 `status`

For `update`: read the existing `sprint-status.yaml`, carry over statuses for
stories that haven't changed, add new stories, remove dropped ones.
对于 `update`：读取既有 `sprint-status.yaml`，为未变化的故事结转状态，
添加新故事，移除已丢弃的故事。

---

## Phase 4: Producer Feasibility Gate
## 阶段 4：Producer 可行性门禁

**Review mode check** — apply before spawning PR-SPRINT:
- `solo` → skip. Note: "PR-SPRINT skipped — Solo mode." Proceed to Phase 5 (QA plan gate).
- `lean` → skip (not a PHASE-GATE). Note: "PR-SPRINT skipped — Lean mode." Proceed to Phase 5 (QA plan gate).
- `full` → spawn as normal.
**评审模式检查** — 在启动 PR-SPRINT 之前应用：
- `solo` → 跳过。注明："PR-SPRINT skipped — Solo mode." 进入阶段 5（QA 计划门禁）。
- `lean` → 跳过（不是 PHASE-GATE）。注明："PR-SPRINT skipped — Lean mode." 进入阶段 5（QA 计划门禁）。
- `full` → 照常启动。

Before finalising the sprint plan, spawn `producer` via `Agent` using gate **PR-SPRINT** (`.claude/docs/director-gates/pr-sprint.md`).
在定稿冲刺计划之前，使用门禁 **PR-SPRINT**（`.claude/docs/director-gates/pr-sprint.md`）通过 `Agent` 启动 `producer`。

Pass: proposed story list (titles, estimates, dependencies), total team capacity in hours/days, any carryover from the previous sprint, milestone constraints and deadline, and any missing goal prerequisite.
传入：拟议故事列表（标题、估算、依赖）、团队总容量（小时/天）、上一个冲刺的任何结转、里程碑约束与截止日期，以及任何缺失的目标前置条件。

Present the producer's assessment.
呈现 producer 的评估。

If UNREALISTIC: revise the story selection (defer stories to Should Have or Nice to Have) and re-present the updated plan, then continue to Phase 5.
若为 UNREALISTIC：修订故事选择（将故事推迟到 Should Have 或 Nice to Have），重新呈现更新后的计划，然后进入阶段 5。

If NOT ASSESSED: name the missing input — it is not REALISTIC. Supply it and re-run PR-SPRINT, or record `NOT ASSESSED — [missing input]` for PR-SPRINT in the plan's header (`.claude/docs/director-gates.md`) and continue to Phase 5, repeating it at the write ask.
若为 NOT ASSESSED：指明缺失的输入 — 它不等于 REALISTIC。补充它并重跑 PR-SPRINT，或在计划文件头中为 PR-SPRINT 记录 `NOT ASSESSED — [missing input]`（`.claude/docs/director-gates.md`），继续进入阶段 5，并在写入提问时重复它。

If CONCERNS, use `AskUserQuestion`:
- Prompt: "Producer flagged concerns with this sprint plan. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the risk`
  - `[B] Adjust scope — defer some Should Have stories`
  - `[C] Extend the sprint timeline`
若为 CONCERNS，使用 `AskUserQuestion`：
- 提示："Producer flagged concerns with this sprint plan. How do you want to proceed?"
- 选项：
  - `[A] Proceed as planned — I accept the risk`
  - `[B] Adjust scope — defer some Should Have stories`
  - `[C] Extend the sprint timeline`

If [A]: continue to Phase 5.
If [B]: revise the story list, re-present the updated plan, then continue to Phase 5.
If [C]: adjust sprint dates and capacity, re-present the updated plan, then continue to Phase 5.
若选 [A]：进入阶段 5。
若选 [B]：修订故事列表，重新呈现更新后的计划，然后进入阶段 5。
若选 [C]：调整冲刺日期与容量，重新呈现更新后的计划，然后进入阶段 5。

After handling the producer's verdict, continue to Phase 5. The write comes at
its end, so the file you approve already holds everything Phase 5 adds.
处理 producer 的裁决后，进入阶段 5。写入发生在其
末尾，因此你批准的文件已经包含阶段 5 所添加的一切。

---

## Phase 5: QA Plan Gate
## 阶段 5：QA 计划门禁

Before closing the sprint plan, check whether a QA plan exists for this sprint.
在关闭冲刺计划之前，检查此冲刺是否存在 QA 计划。

Use `Glob` for `production/qa/qa-plan-*.md` — `/qa-plan` writes `qa-plan-[sprint-slug]-[date].md` — and keep a file whose name or content references this sprint number.
用 `Glob` 查找 `production/qa/qa-plan-*.md` — `/qa-plan` 写入 `qa-plan-[sprint-slug]-[date].md` — 并保留名称或内容引用此冲刺编号的文件。

**If a QA plan is found**: note it in the sprint plan output — "QA Plan: `[path]`" — and proceed.
**若找到 QA 计划**：在冲刺计划输出中注明 — "QA Plan: `[path]`" — 并继续。

**If no QA plan exists**: do not silently proceed. Surface this explicitly:
**若不存在 QA 计划**：不要静默继续。明确呈现这一点：

> "This sprint has no QA plan. A sprint plan without a QA plan means test requirements are undefined — developers won't know what 'done' looks like from a QA perspective, and the sprint cannot pass the Production → Polish gate without one.
>
> Run `/qa-plan sprint` now, before starting any implementation. It takes one session and produces the test case requirements each story needs."
> "此冲刺没有 QA 计划。没有 QA 计划的冲刺计划意味着测试要求未定义 — 开发者不会知道从 QA 视角看'完成'意味着什么，且没有它，冲刺无法通过 Production → Polish 门禁。
>
> 现在就运行 `/qa-plan sprint`，在任何实施开始之前。它只需一次会话，并产出每个故事所需的测试用例要求。"

Use `AskUserQuestion`:
- Prompt: "No QA plan found for this sprint. How do you want to proceed?"
- Options:
  - `[A] Run /qa-plan sprint now — I'll do that before starting implementation (Recommended)`
  - `[B] Skip for now — I understand QA sign-off will be blocked at the Production → Polish gate`
使用 `AskUserQuestion`：
- 提示："No QA plan found for this sprint. How do you want to proceed?"
- 选项：
  - `[A] Run /qa-plan sprint now — I'll do that before starting implementation (Recommended)`
  - `[B] Skip for now — I understand QA sign-off will be blocked at the Production → Polish gate`

Wait for this answer before the write ask below — the two are separate questions.
An answer here is never approval to write, even "yes, go ahead" or "once the plan is written":
ask the write question next and write only after a yes to it.
在下方写入提问之前等待此答复 — 二者是分开的问题。
此处的答复绝不是写入批准，哪怕是"好的，继续"或"计划写完后再说"：
接下来询问写入问题，并且只有在得到肯定答复后才写入。

If [A]: note in the plan "QA plan: run `/qa-plan sprint` before implementation begins."
If [B]: add a warning block to the sprint plan document:
若选 [A]：在计划中注明"QA plan: run `/qa-plan sprint` before implementation begins."
若选 [B]：向冲刺计划文档添加一个警告块：

```markdown
> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.
```

### Write the plan
### 写入计划

Ask: "May I write the sprint plan to `production/sprints/sprint-NNN.md` (`[N]` zero-padded to three digits) and
`production/sprint-status.yaml`?" Ask it even when an earlier answer sounded like a yes. If yes, write both files (creating directories as
needed). Verdict: **COMPLETE** — sprint plan and status file created. If no:
Verdict: **BLOCKED** — user declined write.
询问："May I write the sprint plan to `production/sprints/sprint-NNN.md` (`[N]` zero-padded to three digits) and
`production/sprint-status.yaml`?" 即使早先的答复听起来像肯定，也要询问它。若答是，写入两个文件（按需
创建目录）。裁决：**COMPLETE** — 冲刺计划与状态文件已创建。若答否：
裁决：**BLOCKED** — 用户拒绝写入。

After writing, add:
写入之后，添加：

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins.
> **范围检查：** 若此冲刺包含超出原史诗范围而添加的故事，在实施开始之前运行 `/scope-check [epic]` 以检测范围蔓延。

If the user chose `Run /qa-plan sprint now` in Phase 5, close with "Sprint plan written. Run `/qa-plan sprint` next — then begin implementation."
若用户在阶段 5 选择了 `Run /qa-plan sprint now`，以"Sprint plan written. Run `/qa-plan sprint` next — then begin implementation."收尾。

---

## Phase 6: Next Steps
## 阶段 6：后续步骤

After the sprint plan is written and QA plan status is resolved:
在冲刺计划写入且 QA 计划状态已解决之后：

- `/qa-plan sprint` — **required before implementation begins** — defines test cases per story so developers implement against QA specs, not a blank slate
- `/story-readiness [story-file]` — validate a story is ready before starting it
- `/dev-story [story-file]` — begin implementing the first story
- `/sprint-status` — check progress mid-sprint
- `/scope-check [epic]` — verify no scope creep before implementation begins
- `/qa-plan sprint` — **实施开始前必需** — 为每个故事定义测试用例，使开发者依据 QA 规范实现，而不是面对空白
- `/story-readiness [story-file]` — 在开始某个故事之前验证它已就绪
- `/dev-story [story-file]` — 开始实现第一个故事
- `/sprint-status` — 在冲刺中期检查进度
- `/scope-check [epic]` — 在实施开始之前核验没有范围蔓延

**Review mode configuration:** All director gates (producer feasibility, QA review, code review) respect the project review mode, resolved in the block at the top of this skill (`--review` flag → `project.local.yaml` → `modes.review_mode` in `project.yaml` → `production/review-mode.txt` → the `modes.rigor` expansion, which yields `lean` at standard rigor and `solo` at minimal). This skill never asks for it or writes it; Phase 0 says where to point a user who wants a different depth. The mode is one of:
- `lean` — skip non-phase-gate director gates (the `rigor: standard` value)
- `full` — run all director gates as spawned sub-agents
- `solo` — skip all gate spawning unconditionally (single developer, no review)
**评审模式配置：** 所有总监门禁（producer 可行性、QA 评审、代码评审）都遵循项目评审模式，在此技能顶部的块中解析（`--review` 标志 → `project.local.yaml` → `project.yaml` 中的 `modes.review_mode` → `production/review-mode.txt` → `modes.rigor` 展开，后者在标准严谨度下产出 `lean`、在最简严谨度下产出 `solo`）。此技能从不询问它或写入它；阶段 0 说明了想要不同深度时应指引用户到哪里。模式为以下之一：
- `lean` — 跳过非阶段门禁的总监门禁（`rigor: standard` 的值）
- `full` — 以启动的子智能体运行所有总监门禁
- `solo` — 无条件跳过所有门禁启动（单人开发者，无评审）

`modes.review_mode` in `project.yaml` is the primary source; `production/review-mode.txt` is the legacy fallback. Both are read by `/sprint-plan`, `/story-readiness`, `/story-done`, and other gate-using skills at startup.
`project.yaml` 中的 `modes.review_mode` 是主要来源；`production/review-mode.txt` 是遗留回退。二者都在启动时被 `/sprint-plan`、`/story-readiness`、`/story-done` 以及其他使用门禁的技能读取。
