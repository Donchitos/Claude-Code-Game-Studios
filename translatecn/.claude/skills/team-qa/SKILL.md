---
name: team-qa
description: "Orchestrate the QA team through a full testing cycle — qa-lead strategy and test plan, qa-tester case writing, execution, sign-off."
argument-hint: "[sprint | feature: system-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/team-qa/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: team-qa
description: "编排 QA 团队走完完整测试周期 — qa-lead 策略与测试计划、qa-tester 用例编写、执行、签署。"
argument-hint: "[sprint | feature: system-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/team-qa/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team QA

# QA 团队

When this skill is invoked, orchestrate the QA team through a structured testing cycle.

当本技能被调用时，通过结构化测试周期编排 QA 团队。

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**决策点：** 在每个阶段转换处，使用 `AskUserQuestion` 将
子智能体的提案作为可选项呈现给用户。在对话中写入智能体的
完整分析，然后用简洁标签捕获决策。
在 `collaborative` 模式下，用户必须批准后才能进入下一阶段。
在 `guided` 模式下，除非某阶段为 BLOCKED，流水线自动推进；
在 `autonomous` 模式下，它端到端运行，通过
`log_decision` 记录每个阶段的结果。`automation_always_ask` 类别中的决策
（`is_always_ask_category` 辅助函数）无论模式如何都始终提示。参见
`.claude/docs/automation-modes.md`。

## Phase 0: Resolve Config

## 阶段 0：解析配置

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,qa.level`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

`qa.level` decides what a Logic, Integration or Config/Data story's evidence is:
its automated test at `standard` and `full`; at `minimal`, where tests are waived
(`.claude/docs/coding-standards.md`), the acceptance-criteria walk in Phase 5 —
a story without a test is then WAIVED, not missing its evidence. The UI and
Visual/Feel screenshots are required at every level.

`qa.level` 决定逻辑、集成或配置/数据故事的证据是什么：
在 `standard` 和 `full` 下是其自动化测试；在 `minimal` 下测试被豁免
（`.claude/docs/coding-standards.md`），证据是阶段 5 中的验收标准走查 —
此时没有测试的故事是 WAIVED，而不是缺少证据。UI 和
视觉/手感截图在每个层级都是必需的。

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns CD-, TD-, PR- or AD-PHASE-GATE, at any `review_mode`. Its
phase gates are the pipeline's own decision points (defined under `team.size`
below), and the agents that work at them are team members, not director gates.

`review_mode` 设置总监门禁的深度，而本流水线没有总监门禁：
下面任何阶段在任何 `review_mode` 下都不会派生 CD-、TD-、PR- 或 AD-PHASE-GATE。它的
阶段门禁是流水线自身的决策点（定义于下面的 `team.size` 之下），
而在这些决策点工作的智能体是团队成员，不是总监门禁。

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

`automation` 驱动上述决策点说明。参见上述决策点说明和
`.claude/docs/automation-modes.md`，了解每种模式如何改变流水线行为。

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `qa-tester` only; `qa-lead` invoked at phase gates only.
- **`small`**: `qa-lead` + `qa-tester` pipeline (as documented).
- **`studio`**: `qa-lead` + per-story `qa-tester` spawn + sign-off.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode**: in `guided` or `autonomous`, where that question is skipped or logged, the phase is still a gate. Not every phase is one. Apply the test literally: if the phase below lists no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**`team.size`**：哪些智能体处于活动状态（与 review_mode 门禁深度和 workflow 文档正交）。
- **`individual`**（默认）：仅 `qa-tester`；`qa-lead` 仅在阶段门禁处调用。
- **`small`**：`qa-lead` + `qa-tester` 流水线（如文档所述）。
- **`studio`**：`qa-lead` + 逐故事派生 `qa-tester` + 签署。
在 `individual` 下需要非核心智能体时，经由最近的活动核心智能体路由，并附信息性说明。**"阶段门禁"是指本流水线自身列出的、以 `AskUserQuestion` 决策点结束的任何阶段** — 上述决策点下的一个转换，或下面写入流水线的 **Gate** 步骤 — **无论 `automation` 模式为何**：在 `guided` 或 `autonomous` 下，即使该问题被跳过或记录，该阶段仍是门禁。并非每个阶段都是门禁。按字面测试：如果下面的阶段没有列出决策点，它就不是门禁，被限制为"仅阶段门禁"的智能体不会为它派生。这一活动集范围界定适用于下面的整个流水线：任何点名了活动集之外智能体的阶段，都经由最近的核心智能体路由，而不是派生它。

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

**在阶段 1 之前宣告活动集 — 绝不要让这种收缩保持沉默。**
在派生任何东西之前，用一行说明本次运行实际会派生哪些智能体，
以及下面流水线点名但在所解析的 `team.size` 下**不会**派生哪些。例如：

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.
An agent the resolved size spawns only at phase gates (`qa-lead` at
`individual`) goes in the active set with that qualifier — it is spawned, not
consulted through another agent.

从紧接上方的 `team.size` 列表和本文件自身流水线点名的智能体来填充它 —
而不是从示例。两个集合因编排器而异。
所解析规模仅在阶段门禁处派生的智能体（`individual` 下的 `qa-lead`）
会带着该限定词列入活动集 — 它会被派生，而不是
经由另一个智能体咨询。

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names ten and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever.
Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

下面的流水线读起来像多智能体扇出，而按出厂默认它
是一或两个智能体 — `team-release` 点名十个却运行一个，`team-narrative`
跨五个阶段点名六个却只运行 `writer`。**这种收缩是正确的**：
`team.size` 以严谨度为前置，窄默认正是 token 杠杆。
若不这样说明，读者就无法
分辨一次正确收缩的运行与一条损坏的流水线，而前面那条
"经由最近的核心智能体路由并附信息性说明"的逐智能体规则
在路由时触发，从不说明整次运行的形态。

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

这与本文件其他地方的跳过检查报告是同一条规则：**一项被强制执行却从未呈现的约束，
对阅读输出的人而言，与一项从未被强制执行的约束无法区分。**

## Team Composition

## 团队构成

- **qa-lead** — QA strategy, test plan generation, story classification, sign-off report
- **qa-tester** — Test case writing, bug report writing, manual QA documentation

- **qa-lead** — QA 策略、测试计划生成、故事分类、签署报告
- **qa-tester** — 测试用例编写、缺陷报告编写、手动 QA 文档

## How to Delegate

## 如何委派

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: qa-lead` — Strategy, planning, classification, sign-off
- `subagent_type: qa-tester` — Test case writing and bug report writing

使用 `Agent` 工具将每个团队成员派生为子智能体：
- `subagent_type: qa-lead` — 策略、规划、分类、签署
- `subagent_type: qa-tester` — 测试用例编写与缺陷报告编写

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**为每个智能体写简报 — 不要倾倒上下文。** 只读取共享输入**一次**，并内联传递一份提炼过的简报：每个智能体实际需要的那几行，绝不给你已经读过的文档传文件路径（拿到路径的智能体会重读整个文件）。只为你未读过且只有该智能体需要的文档传递路径。

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**在每个智能体提示末尾加上返回契约：** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." 若没有它，智能体会把它读过的一切重新返回本会话。

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is a phase gate as defined above — one the pipeline lists as ending in an `AskUserQuestion` before it advances, whatever the automation mode. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

> **为什么这不违反协作协议。** `CLAUDE.md` 要求智能体在 Write/Edit 之前询问 "May I write this to [filepath]?"。此处派生的子智能体**不**询问就写入，这是经过深思熟虑的有界例外，而非疏漏 — 与 `consistency-check` 追加到 `active.md` 时已做的同一决定。该例外仅在以下三者同时成立时适用：(1) 路径是**你**在提示中点名的，因此用户在批准该阶段时即批准了目的地；(2) 它是 `production/`、`docs/` 或 `tests/` 下的新产物，绝不是对既有源码或配置的编辑；(3) 产出它的阶段是上文定义的阶段门禁 — 流水线列出的、在推进前以 `AskUserQuestion` 结束的阶段，无论自动化模式为何。三者之外，智能体必须询问。**不要通过逐子智能体询问来"修复"这一点** — 每阶段每智能体一次提示会让编排器不可用，这正是该例外存在的原因。

At `team.size: studio`, Phase 4 spawns one qa-tester per story, in parallel; below that, one spawn covers the whole group.

在 `team.size: studio` 下，阶段 4 为每个故事并行派生一个 qa-tester；低于该规模时，一次派生覆盖整组。

## Pipeline

## 流水线

### Phase 1: Load Context

### 阶段 1：加载上下文

Before doing anything else, gather the full scope:

在做任何其他事情之前，收集完整范围：

1. Detect the current sprint or feature scope from the argument:
   - If argument is a sprint identifier (e.g., `sprint-03`): Glob `production/sprints/sprint-*.md` and match by sprint number — `sprint-3`, `sprint-03` and `sprint-003` all name sprint 3 (`/sprint-plan` writes `sprint-NNN.md`). Read the matched file. If multiple match, use the most recently modified.
   - If argument is `feature: [system-name]`: glob story files tagged for that system
   - If no argument: read `production/session-state/active.md` and `production/sprint-status.yaml` (if present) to infer the active sprint. If there is no sprint — at `rigor: minimal` there are none — ask which epic to cover and use `feature: [epic-slug]`; do not invent a sprint

2. Read `project.stage` from `project.yaml` (fallback `production/stage.txt`) to confirm the current project phase.

3. **Read the open bugs in scope** — the bugs already on file, before QA finds new ones: grep the `**Severity**`, `**Status**` and `**System**` lines of `production/qa/bugs/*.md`, as `/bug-triage` does. A bug is open unless its Status is `Closed` or `Verified Fixed`; it is in scope when its System is one the in-scope stories belong to, or it names an in-scope story — when unsure, list it. These go into the Phase 2 and Phase 6 briefs as **Open bugs in scope**: an open S1 or S2 here already makes the sign-off NOT APPROVED (Phase 6), whatever QA finds. No bug files → "Open bugs in scope: none on file".

4. Count stories found and report to the user:
   > "QA cycle starting for [sprint/feature]. Found [N] stories. Open bugs in scope: [N — S1: n, S2: n, or none on file]. Current stage: [stage]. Ready to begin QA strategy?"

1. 从参数检测当前冲刺或功能范围：
   - 若参数是冲刺标识（例如 `sprint-03`）：Glob `production/sprints/sprint-*.md` 并按冲刺编号匹配 — `sprint-3`、`sprint-03` 和 `sprint-003` 都指冲刺 3（`/sprint-plan` 写入 `sprint-NNN.md`）。读取匹配的文件。若多个匹配，使用最近修改的。
   - 若参数是 `feature: [system-name]`：glob 标记为该系统的故事文件
   - 若无参数：读取 `production/session-state/active.md` 和 `production/sprint-status.yaml`（若存在）以推断活动冲刺。若无冲刺 — 在 `rigor: minimal` 下没有冲刺 — 询问要覆盖哪个史诗并使用 `feature: [epic-slug]`；不要虚构一个冲刺

2. 从 `project.yaml` 读取 `project.stage`（回退 `production/stage.txt`）以确认当前项目阶段。

3. **读取范围内的开放缺陷** — 在 QA 发现新缺陷之前，已在文件中的缺陷：像 `/bug-triage` 那样 grep `production/qa/bugs/*.md` 的 `**Severity**`、`**Status**` 和 `**System**` 行。除非 Status 为 `Closed` 或 `Verified Fixed`，否则缺陷是开放的；当其 System 属于范围内故事所属的系统，或它点名了范围内的故事时，它就在范围内 — 不确定时就列出它。这些作为 **Open bugs in scope** 进入阶段 2 和阶段 6 的简报：这里一个开放的 S1 或 S2 已经使签署为 NOT APPROVED（阶段 6），无论 QA 发现什么。无缺陷文件 → "Open bugs in scope: none on file"。

4. 统计找到的故事数并向用户报告：
   > "QA cycle starting for [sprint/feature]. Found [N] stories. Open bugs in scope: [N — S1: n, S2: n, or none on file]. Current stage: [stage]. Ready to begin QA strategy?"

### Phase 2: QA Strategy (qa-lead)

### 阶段 2：QA 策略（qa-lead）

Spawn `qa-lead` via `Agent` to review all in-scope stories and produce a QA strategy.

通过 `Agent` 派生 `qa-lead` 以评审所有范围内的故事并产出 QA 策略。

Pass the qa-lead the **Open bugs in scope** from Phase 1 (ID, severity, story or system), then prompt it to:
- Read each story file
- Classify each story by type: **Logic** / **Integration** / **Visual/Feel** / **UI** / **Config/Data**
- Identify which stories require automated test evidence vs. manual QA — at `qa.level: minimal` none requires a test: a Logic, Integration or Config/Data story without one reads `WAIVED` under Automated Required and gets its acceptance criteria walked in manual QA
- Flag any stories with missing acceptance criteria or missing test evidence that would block QA
- Estimate manual QA effort (number of test sessions needed)
- **Before assessing smoke status, check for an existing smoke check report**: Glob `production/qa/smoke-*.md` and read the most recently modified file (if found). If a report exists, use its verdict and findings directly — do not re-interview the user. If no report exists, note: "No prior smoke check report found — run `/smoke-check sprint` before proceeding." and set smoke check status to UNKNOWN (treat as PASS WITH WARNINGS for the purpose of continuing). Produce a smoke check verdict: **PASS** / **PASS WITH WARNINGS [list]** / **NOT ASSESSED [what did not run]** / **FAIL [list of failures]** / **UNKNOWN (no report found)**
- Produce a strategy summary table and smoke check result:

  | Story | Type | Automated Required | Manual Required | Blocker? |
  |-------|------|--------------------|-----------------|----------|

  **Smoke Check**: [PASS / PASS WITH WARNINGS / NOT ASSESSED / FAIL / UNKNOWN] — [source: `production/qa/smoke-[date].md` or "no report found"] — [details if not PASS]

  **Open bugs in scope**: [BUG-ID — S[n] — story or system, one per line; or "none on file"] — an open S1 or S2 is named here as a known failure

将阶段 1 的 **Open bugs in scope** 传给 qa-lead（ID、严重度、故事或系统），然后提示它：
- 读取每个故事文件
- 按类型对每个故事分类：**Logic** / **Integration** / **Visual/Feel** / **UI** / **Config/Data**
- 识别哪些故事需要自动化测试证据 vs. 手动 QA — 在 `qa.level: minimal` 下无需任何测试：一个没有测试的逻辑、集成或配置/数据故事在 Automated Required 下读作 `WAIVED`，并在手动 QA 中走查其验收标准
- 标记任何缺少验收标准或缺少测试证据、会阻断 QA 的故事
- 估算手动 QA 工作量（所需测试会话数）
- **在评估冒烟状态之前，检查是否有既有的冒烟检查报告**：Glob `production/qa/smoke-*.md` 并读取最近修改的文件（若找到）。若报告存在，直接使用其结论与发现 — 不要重新访谈用户。若无报告存在，注明："No prior smoke check report found — run `/smoke-check sprint` before proceeding." 并将冒烟检查状态设为 UNKNOWN（为继续起见按 PASS WITH WARNINGS 处理）。产出冒烟检查结论：**PASS** / **PASS WITH WARNINGS [list]** / **NOT ASSESSED [what did not run]** / **FAIL [list of failures]** / **UNKNOWN (no report found)**
- 产出策略摘要表和冒烟检查结果：

  | Story | Type | Automated Required | Manual Required | Blocker? |
  |-------|------|--------------------|-----------------|----------|

  **Smoke Check**: [PASS / PASS WITH WARNINGS / NOT ASSESSED / FAIL / UNKNOWN] — [source: `production/qa/smoke-[date].md` or "no report found"] — [details if not PASS]

  **Open bugs in scope**: [BUG-ID — S[n] — story or system, one per line; or "none on file"] — 此处一个开放的 S1 或 S2 被列为已知失败

If the smoke check result is **FAIL**, the qa-lead must list the failures prominently. QA cannot proceed past the strategy phase with a failed smoke check.

若冒烟检查结果为 **FAIL**，qa-lead 必须醒目地列出失败项。带着失败的冒烟检查，QA 无法越过策略阶段。

Present the qa-lead's full strategy to the user, then use `AskUserQuestion`:

向用户呈现 qa-lead 的完整策略，然后使用 `AskUserQuestion`：

```
question: "QA Strategy Review"
options:
  - "Looks good — proceed to test plan"
  - "Adjust story types before proceeding"
  - "Skip blocked stories and proceed with the rest"
  - "Smoke check failed — fix issues and re-run /team-qa"
  - "Cancel — resolve blockers first"
```

If smoke check **FAIL**: do not proceed to Phase 3. Surface the failures from the smoke check report and stop. The user must fix them, re-run `/smoke-check sprint`, and then re-run `/team-qa`.
If smoke check **UNKNOWN**: surface a warning — "No smoke check report found. Recommend running `/smoke-check sprint` before QA. Proceeding with caution."
If smoke check **NOT ASSESSED**: surface what the report says did not run — "The last smoke check could not assess [what did not run]. Recommend re-running `/smoke-check sprint` once it can. Proceeding with caution." — and continue as for UNKNOWN; the sign-off cannot be APPROVED on it (Phase 6).
If smoke check **PASS WITH WARNINGS**: note the warnings for the sign-off report and continue.
If blockers are present: list them explicitly. The user may choose to skip blocked stories or cancel the cycle.

若冒烟检查为 **FAIL**：不要进入阶段 3。呈现冒烟检查报告中的失败并停止。用户必须修复它们、重新运行 `/smoke-check sprint`，然后重新运行 `/team-qa`。
若冒烟检查为 **UNKNOWN**：呈现警告 — "No smoke check report found. Recommend running `/smoke-check sprint` before QA. Proceeding with caution."
若冒烟检查为 **NOT ASSESSED**：呈现报告所说未运行的内容 — "The last smoke check could not assess [what did not run]. Recommend re-running `/smoke-check sprint` once it can. Proceeding with caution." — 并按 UNKNOWN 处理继续；签署不能据此为 APPROVED（阶段 6）。
若冒烟检查为 **PASS WITH WARNINGS**：为签署报告记下警告并继续。
若有阻断项：明确列出它们。用户可选择跳过被阻断的故事或取消周期。

### Phase 3: Test Plan Generation

### 阶段 3：测试计划生成

Using the strategy from Phase 2, produce a structured test plan document.

使用阶段 2 的策略，产出一份结构化的测试计划文档。

The test plan should cover:
- **Scope**: sprint/feature name, story count, dates
- **Story Classification Table**: from Phase 2 strategy
- **Automated Test Requirements**: which stories need test files, expected paths in `tests/` (none at `qa.level: minimal`: list the waived stories under Manual QA Scope instead)
- **Manual QA Scope**: which stories need manual walkthrough and what to validate
- **Out of Scope**: what is explicitly not being tested this cycle and why
- **Entry Criteria**: what must be true before QA can begin. Always include: (1) Smoke check PASS or PASS WITH WARNINGS report exists at `production/qa/smoke-*.md`, (2) build is stable (no crashes on launch), (3) at sprint scope, all Must Have stories are `in-progress`, `review` or `done` in `production/sprint-status.yaml`; at `feature:` scope, every in-scope story file's Status is In Progress, In Review or Complete. Add any sprint-specific criteria beyond these.
- **Exit Criteria**: what constitutes a completed QA cycle (all stories PASS or FAIL with bugs filed)

测试计划应覆盖：
- **范围**：冲刺/功能名称、故事数量、日期
- **故事分类表**：来自阶段 2 策略
- **自动化测试需求**：哪些故事需要测试文件、`tests/` 中的预期路径（在 `qa.level: minimal` 下没有：改在 Manual QA Scope 下列出被豁免的故事）
- **手动 QA 范围**：哪些故事需要手动走查以及需要验证什么
- **范围之外**：本周期明确不测试什么以及原因
- **进入标准**：QA 开始前必须成立的条件。始终包含：(1) 在 `production/qa/smoke-*.md` 存在 PASS 或 PASS WITH WARNINGS 报告，(2) 构建稳定（启动无崩溃），(3) 在冲刺范围内，所有 Must Have 故事在 `production/sprint-status.yaml` 中为 `in-progress`、`review` 或 `done`；在 `feature:` 范围内，每个范围内故事文件的 Status 为 In Progress、In Review 或 Complete。在这些之外添加任何冲刺专属标准。
- **退出标准**：什么构成一个完成的 QA 周期（所有故事 PASS，或 FAIL 且已提交缺陷）

Ask: "May I write the QA plan to `production/qa/qa-plan-[sprint]-[date].md`?"

询问："May I write the QA plan to `production/qa/qa-plan-[sprint]-[date].md`?"

Write only after receiving approval.

仅在收到批准后写入。

### Phase 4: Test Case Writing (qa-tester)

### 阶段 4：测试用例编写（qa-tester）

> **Smoke check** is performed as part of Phase 2 (QA Strategy). If the smoke check returned FAIL in Phase 2, the cycle was stopped there. This phase only runs when the Phase 2 smoke check was PASS, PASS WITH WARNINGS, NOT ASSESSED, or UNKNOWN.

> **冒烟检查**作为阶段 2（QA 策略）的一部分执行。若阶段 2 中冒烟检查返回 FAIL，周期已在那里停止。本阶段仅在阶段 2 冒烟检查为 PASS、PASS WITH WARNINGS、NOT ASSESSED 或 UNKNOWN 时运行。

For each story requiring manual QA (Visual/Feel, UI, Integration without automated tests — and, at `qa.level: minimal`, where tests are waived, every Logic, Integration and Config/Data story without a test: its cases walk its acceptance criteria):

对于每个需要手动 QA 的故事（Visual/Feel、UI、没有自动化测试的 Integration — 以及在 `qa.level: minimal` 测试被豁免时，每个没有测试的 Logic、Integration 和 Config/Data 故事：其用例走查其验收标准）：

Spawn `qa-tester` via `Agent` — one per story, in parallel, at `team.size: studio`; one spawn covering the whole group at `small` and `individual` — providing, for each story:
- The story file path
- The relevant section of the QA plan for that story
- The GDD acceptance criteria for the system being tested (if available)
- Instructions to write detailed test cases covering all acceptance criteria
- **The output path: `production/qa/test-cases/[story-slug]-cases.md`.** Name it
  explicitly in the prompt, one per story.

通过 `Agent` 派生 `qa-tester` — 在 `team.size: studio` 下每个故事一个、并行；在 `small` 和 `individual` 下一次派生覆盖整组 — 为每个故事提供：
- 故事文件路径
- 该故事在 QA 计划中的相关章节
- 被测系统的 GDD 验收标准（若有）
- 编写覆盖所有验收标准的详细测试用例的指示
- **输出路径：`production/qa/test-cases/[story-slug]-cases.md`。** 在提示中明确
  点名它，每个故事一个。

> **Why the path is stated here rather than left to the orchestrator.** The
> bounded write exception above holds only when "the path is one **you** named in
> the prompt". This is the phase that spawns agents *in parallel*, so it is where
> an unnamed destination does the most damage: each agent improvises its own, and
> two runs file the same artifact in two places. The phase reads correctly right
> up until two agents need somewhere to put their output.

> **为什么在这里说明路径，而不是留给编排器。** 上面的有界写入例外仅在
> "路径是**你**在提示中点名的"时成立。这是*并行*派生智能体的阶段，因此
> 未命名的目的地在此造成最大损害：每个智能体各自即兴决定，两次运行会在两个地方归档同一产物。
> 该阶段的描述一直读起来正确，直到两个智能体都需要地方放输出。

Each test case set should include:
- **Preconditions**: game state required before testing begins
- **Steps**: numbered, unambiguous actions
- **Expected Result**: what should happen
- **Actual Result**: field left blank for the tester to fill in
- **Pass/Fail**: field left blank

每套测试用例应包含：
- **前置条件**：测试开始前所需的游戏状态
- **步骤**：带编号、无歧义的动作
- **预期结果**：应当发生什么
- **实际结果**：留空供测试人员填写
- **通过/失败**：留空

Present the test cases to the user for review before execution. Group by story.

在执行前将测试用例呈现给用户评审。按故事分组。

Use `AskUserQuestion` per story group (batched 3-4 at a time):

对每个故事组使用 `AskUserQuestion`（一次批处理 3-4 个）：

```
question: "Test cases ready for [Story Group]. Review before manual QA begins?"
options:
  - "Approved — begin manual QA for these stories"
  - "Revise test cases for [story name]"
  - "Skip manual QA for [story name] — not ready"
```

### Phase 5: Manual QA Execution

### 阶段 5：手动 QA 执行

Walk through each story in the approved manual QA list.

走查已批准手动 QA 列表中的每个故事。

Batch stories into groups of 3-4 and use `AskUserQuestion` for each. **Wait for
the tester's answer** and record only what they said: a result the tester did not
give is never filled in for them. A story nobody answered for stays unexecuted,
which makes the sign-off NOT ASSESSED — it is not BLOCKED unless they say so.

将故事分成 3-4 个一组，并对每组使用 `AskUserQuestion`。**等待
测试人员的回答**，只记录他们所说的：测试人员未给出的结果
绝不替他们填写。无人回答的故事保持未执行，
这会使签署为 NOT ASSESSED — 除非他们说 BLOCKED，否则它不是 BLOCKED。

```
question: "Manual QA — [Story Title]\n[brief description of what to test]"
options:
  - "PASS — all acceptance criteria verified"
  - "PASS WITH NOTES — minor issues found (describe after)"
  - "FAIL — criteria not met (describe after)"
  - "BLOCKED — cannot test yet (reason)"
```

After each FAIL result: use `AskUserQuestion` to collect the failure description, then spawn `qa-tester` via `Agent` to write a formal bug report in `production/qa/bugs/`, in `/bug-report`'s format — its Severity and Priority labels exactly as that template lists them (`S2-High`, `P1-Fix this sprint`, …), because `/bug-triage` parses them.

对每个 FAIL 结果：使用 `AskUserQuestion` 收集失败描述，然后通过 `Agent` 派生 `qa-tester`，在 `production/qa/bugs/` 中以 `/bug-report` 的格式编写正式缺陷报告 — 其 Severity 和 Priority 标签严格按该模板所列（`S2-High`、`P1-Fix this sprint` 等），因为 `/bug-triage` 会解析它们。

**After each PASS or PASS WITH NOTES on a Visual/Feel or UI story, record its
evidence in `production/qa/evidence/`.** The retained screenshot is the
evidence: ask the tester to save one of each screen or effect the story touched
under `production/qa/evidence/[story-slug]/`, and confirm it is on disk —
`/story-done` checks for a retained image, not just the write-up. A UI story is
closed by those screenshots; a Visual/Feel story also needs the lead sign-off.
Then ask "May I write the evidence for [story titles] to
`production/qa/evidence/`?", once per story group, and write the evidence
artifact `production/qa/evidence/[story-slug]-evidence.md` from
`.claude/docs/templates/test-evidence.md`, carrying the sign-off table intact and
referencing the screenshots. If no screenshot was saved, name that story in the
Phase 5 summary as missing its retained evidence rather than writing a doc that
implies one.

**在 Visual/Feel 或 UI 故事的每个 PASS 或 PASS WITH NOTES 之后，将其
证据记录到 `production/qa/evidence/` 中。** 留存截图就是
证据：请测试人员将该故事涉及的每个界面或效果各保存一张，放在
`production/qa/evidence/[story-slug]/` 下，并确认它已在磁盘上 —
`/story-done` 检查的是留存图像，而不只是文字记录。UI 故事
靠这些截图关闭；Visual/Feel 故事还需要负责人签署。
然后每个故事组询问一次 "May I write the evidence for [story titles] to
`production/qa/evidence/`?"，并依据
`.claude/docs/templates/test-evidence.md` 写入证据产物
`production/qa/evidence/[story-slug]-evidence.md`，完整保留签署表并
引用截图。若未保存任何截图，在阶段 5 摘要中指明该故事缺少留存证据，
而不是写入一份暗示有证据的文档。

> **This is not optional bookkeeping — it is the artifact the next skill gates
> on.** `/story-done` globs `production/qa/evidence/` for Visual/Feel and UI
> stories and reads the sign-off table; `/story-readiness`,
> `/test-evidence-review` and `gate-release` read the same directory. Write
> anywhere else and a story can pass a full manual QA cycle here, then be told by
> `/story-done` that no visual evidence exists. Visual/Feel and UI gates are
> **BLOCKING by default**, so that is a deadlock — QA passed, story cannot
> close. It is a merely confusing flag only where `testing.strict.ui` or
> `.visual` has been explicitly set to `false`.
>
> Leave the sign-off rows **unchecked** unless the sign-off actually happened in
> this session. An evidence file with pre-ticked approvals is worse than none: it
> converts a missing signature into a recorded one.

> **这不是可选簿记 — 它是下一个技能据以门控的产物。**
> `/story-done` 为 Visual/Feel 和 UI 故事 glob `production/qa/evidence/`
> 并读取签署表；`/story-readiness`、
> `/test-evidence-review` 和 `gate-release` 读取同一目录。写到
> 其他任何地方，故事可能在此通过完整手动 QA 周期，然后被
> `/story-done` 告知不存在视觉证据。Visual/Feel 和 UI 门禁
> **默认是阻断的**，因此那会形成死锁 — QA 通过了，故事却无法
> 关闭。仅在 `testing.strict.ui` 或
> `.visual` 被显式设为 `false` 时，它才只是令人困惑的标志。
>
> 除非签署确实在本会话中发生，否则将签署行保持**未勾选**。证据文件中预先打勾的批准比没有更糟：
> 它把缺失的签名变成已记录的签名。

Bug report naming: `BUG-[NNNN].md`, numbered the way `/bug-report` numbers them — the
highest ID in `production/qa/bugs/` plus one, zero-padded to four digits — so
`/bug-report verify` and `close` can find it by its ID.

缺陷报告命名：`BUG-[NNNN].md`，按 `/bug-report` 的编号方式 — `production/qa/bugs/` 中
最高 ID 加一，零填充到四位 — 以便
`/bug-report verify` 和 `close` 能按其 ID 找到它。

After collecting all results, summarize:
- Stories PASS: [count]
- Stories PASS WITH NOTES: [count]
- Stories FAIL: [count] — bugs filed: [IDs]
- Stories BLOCKED: [count]

收集所有结果后，汇总：
- PASS 的故事：[count]
- PASS WITH NOTES 的故事：[count]
- FAIL 的故事：[count] — 已提交缺陷：[IDs]
- BLOCKED 的故事：[count]

### Phase 6: QA Sign-Off Report

### 阶段 6：QA 签署报告

Spawn `qa-lead` via `Agent` to draft the sign-off report using all results from Phases 2–5. **Here the return contract is the report text in its reply, not a file:** the orchestrator writes the sign-off after the ask at the end of this phase, so the qa-lead writes nothing.

通过 `Agent` 派生 `qa-lead`，使用阶段 2–5 的所有结果起草签署报告。**此处的返回契约是其回复中的报告文本，而非文件：** 编排器在本阶段末尾询问后写入签署，因此 qa-lead 不写入任何内容。

**Brief the qa-lead with the evidence and the verdict rules below — never a verdict.** Pass the strategy table, the smoke check verdict and its source, each story's result, the bugs filed in Phase 5 and the **Open bugs in scope** from Phase 1, and the verdict rules below, verbatim. Do not name a verdict, pre-fill the `### Verdict:` line, or say which fact decides it: the qa-lead applies the rules to the evidence. Then check its verdict against the same rules before asking to write; if they disagree, show both and ask — never silently substitute your own.

**用证据和下面的结论规则为 qa-lead 写简报 — 绝不给出结论。** 传入策略表、冒烟检查结论及其来源、每个故事的结果、阶段 5 提交的缺陷、阶段 1 的 **Open bugs in scope**，以及下面逐字不变的结论规则。不要点名结论、预填 `### Verdict:` 行，或说出哪个事实决定它：qa-lead 将规则应用于证据。然后在询问写入前用同样的规则检查其结论；若二者不一致，展示两者并询问 — 绝不悄悄替换为你自己的。

The sign-off report format:

签署报告的格式：

```markdown
## QA Sign-Off Report: [Sprint/Feature]
**Date**: [date]

### Test Coverage Summary
| Story | Type | Auto Test | Manual QA | Result |
|-------|------|-----------|-----------|--------|
| [title] | Logic | PASS | — | PASS |
| [title] | Logic | WAIVED (qa.level: minimal) | PASS — criteria walked | PASS |
| [title] | Visual | — | PASS | PASS |
| [title] | Integration | — | BLOCKED | BLOCKED — [reason]; no executed evidence |

### Bugs Found
| ID | Story | Severity | Status |
|----|-------|----------|--------|
| BUG-0001 | [story] | S2 | Open |

[every open bug in scope — those Phase 1 found on file and those filed in Phase 5]

### Verdict: NOT ASSESSED / APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED

**Conditions** (if any): [list what must be fixed before the build advances]

### Next Step
[guidance based on verdict]
```

**Every story in scope gets a Test Coverage Summary row** — BLOCKED and
unexecuted stories included, with the reason in Result — so a story that never
ran cannot drop out of the report.

**范围内每个故事都获得一行 Test Coverage Summary** — 包括 BLOCKED 和
未执行的故事，原因写在 Result 中 — 这样从未运行的故事
无法从报告中掉出。

Verdict rules:

结论规则：

**Order.** Check **NOT APPROVED first**: any open S1/S2 bug in scope — one already on file (Phase 1) as much as one filed in Phase 5 — or a story that
FAILs without a documented workaround, makes the verdict NOT APPROVED whatever
else went unexecuted — a known failure outranks an unknown, and demoting it to
NOT ASSESSED would bury it (`.claude/rules/skill-authoring.md`, obligation 1).

**顺序。** 先检查 **NOT APPROVED**：范围内任何开放的 S1/S2 缺陷 — 无论是已在文件中（阶段 1）的还是阶段 5 提交的 — 或一个
没有记录变通方案却 FAIL 的故事，都会使结论为 NOT APPROVED，无论
其他还有什么未执行 — 已知失败优先于未知，将其降级为
NOT ASSESSED 会掩埋它（`.claude/rules/skill-authoring.md`，义务 1）。

**Then the precondition.** APPROVED and APPROVED WITH CONDITIONS both require
that **every story in scope produced executed evidence** — a test that ran, or a
manual case that was walked. At `qa.level: minimal` a Logic, Integration or
Config/Data story's acceptance-criteria walk is its executed evidence: its tests
are WAIVED, not missing. If any story is BLOCKED, unexecuted, or has no
evidence, the verdict is **NOT ASSESSED**, not either kind of APPROVED. A smoke
check that was UNKNOWN (no report found) or NOT ASSESSED in Phase 2 also makes it
NOT ASSESSED: the build's health was never checked.

**然后是前提条件。** APPROVED 和 APPROVED WITH CONDITIONS 都要求
**范围内每个故事都产出了已执行的证据** — 运行过的测试，或
走查过的手动用例。在 `qa.level: minimal` 下，逻辑、集成或
配置/数据故事的验收标准走查就是其已执行证据：其测试
是 WAIVED，而非缺失。若任何故事为 BLOCKED、未执行或没有
证据，结论就是 **NOT ASSESSED**，而非任何一种 APPROVED。阶段 2 中为 UNKNOWN（未找到报告）
或 NOT ASSESSED 的冒烟检查也会使其为
NOT ASSESSED：构建的健康状况从未被检查。

- **NOT ASSESSED — NO EVIDENCE**: One or more stories produced no executed
  evidence (BLOCKED, tests not written at `qa.level` standard/full, cases not
  walked, or smoke check FAIL / UNKNOWN / NOT ASSESSED). This is **not** a pass
  and **not** a fail; it means QA did not happen. Say which stories and why.
- **APPROVED**: All stories PASS or PASS WITH NOTES; no S1/S2 bugs open
- **APPROVED WITH CONDITIONS**: S3/S4 bugs open, or PASS WITH NOTES issues documented; no S1/S2 bugs
- **NOT APPROVED**: Any S1/S2 bugs open; or stories FAIL without documented workaround

- **NOT ASSESSED — NO EVIDENCE**：一个或多个故事未产出已执行的
  证据（BLOCKED、在 `qa.level` 为 standard/full 下未编写测试、用例未
  走查，或冒烟检查为 FAIL / UNKNOWN / NOT ASSESSED）。这**不是**通过，
  也**不是**失败；它意味着 QA 没有发生。说明是哪些故事以及原因。
- **APPROVED**：所有故事 PASS 或 PASS WITH NOTES；无开放的 S1/S2 缺陷
- **APPROVED WITH CONDITIONS**：存在开放的 S3/S4 缺陷，或已记录 PASS WITH NOTES 问题；无 S1/S2 缺陷
- **NOT APPROVED**：任何开放的 S1/S2 缺陷；或故事 FAIL 且无记录的变通方案

> **Why the precondition exists.** The three rules below it assume
> every story resolves to PASS or FAIL. A sprint where nothing was executed
> trips none of the NOT APPROVED conditions and **vacuously satisfies "no S1/S2
> bugs open"** — because zero executed tests means zero observed failures. Read
> literally, and without this precondition, the rules let a completely untested
> build reach APPROVED — a `qa-lead` reaching NOT APPROVED on intent would find
> the letter of the rules did not support it. A
> sign-off asserts verified quality; without this precondition the rules cannot
> tell "verified good" from "never looked".

> **为什么存在这个前提条件。** 其下三条规则假设
> 每个故事都归结为 PASS 或 FAIL。一个什么都没执行的冲刺
> 不触发任何 NOT APPROVED 条件，并且**空洞地满足"没有开放的 S1/S2
> 缺陷"** — 因为零次已执行测试意味着零个观察到的失败。按字面阅读，
> 且没有这个前提条件时，规则会让一个完全未经测试的
> 构建达到 APPROVED — 一个凭意图判断 NOT APPROVED 的 `qa-lead` 会发现
> 规则的字面并不支持它。一份
> 签署断言的是已验证的质量；没有这个前提条件，规则无法
> 区分"验证良好"与"从未查看"。

Next step guidance by verdict:
- NOT ASSESSED: "QA did not run to completion. Produce the missing evidence — write the Logic tests (at `qa.level` standard/full) or walk the waived stories' acceptance criteria (at `minimal`), walk the manual cases, run `/smoke-check` — then re-run `/team-qa`. Do not advance the build on this verdict."
- APPROVED: "Build is ready for the next phase. Run `/gate-check` to validate advancement."
- APPROVED WITH CONDITIONS: "Resolve conditions before advancing. S3/S4 bugs may be deferred to polish."
- NOT APPROVED: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing."

按结论的下一步指导：
- NOT ASSESSED："QA did not run to completion. Produce the missing evidence — write the Logic tests (at `qa.level` standard/full) or walk the waived stories' acceptance criteria (at `minimal`), walk the manual cases, run `/smoke-check` — then re-run `/team-qa`. Do not advance the build on this verdict."
- APPROVED："Build is ready for the next phase. Run `/gate-check` to validate advancement."
- APPROVED WITH CONDITIONS："Resolve conditions before advancing. S3/S4 bugs may be deferred to polish."
- NOT APPROVED："Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing."

Ask: "May I write this QA sign-off report to `production/qa/qa-signoff-[sprint]-[date].md`?"

询问："May I write this QA sign-off report to `production/qa/qa-signoff-[sprint]-[date].md`?"

Write only after receiving approval.

仅在收到批准后写入。

## Error Recovery Protocol

## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

**首先，验证产物。** 如果返回契约点名了路径，在把该阶段视为完成之前检查
该路径是否存在 — **一个被点名却不在磁盘上的产物就是一个失败的阶段，无论回应读起来多流畅。**
智能体可以耗费一整个阶段、什么都没写却返回一段看似合理的前言，
这既不是 BLOCKED，也不是错误，也不是"无法完成"，因此下面的触发器
永远不会触发。恢复它并指明未满足的契约；上下文
通常还在那里。

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

如果任何被派生的智能体返回 BLOCKED、出错或无法完成：**立即呈现它，
不要越过它所阻断的依赖继续推进，并始终产出一份
部分报告。** 完整流程：`.claude/docs/error-recovery-protocol.md`。

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

常见阻断项：
- 输入文件缺失（未找到故事、缺少 GDD）→ 重定向到创建它的技能
- ADR 状态为 Proposed → 不要实现；一旦它被决定，用 `/architecture-decision accept ADR-NNNN` 接受它
- 范围过大 → 通过 `/create-stories` 拆分为两个故事
- ADR 与故事之间的指令冲突 → 呈现冲突，不要猜测

## Output

## 输出

A summary covering: stories in scope, smoke check result, manual QA results, bugs filed (with IDs and severities), and the final APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED verdict.

一份摘要，覆盖：范围内的故事、冒烟检查结果、手动 QA 结果、已提交缺陷（含 ID 与严重度），以及最终的 APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED 结论。

Verdict: **COMPLETE** — QA cycle finished.
Verdict: **BLOCKED** — smoke check failed or critical blocker prevented cycle completion; partial report produced.

结论：**COMPLETE** — QA 周期已完成。
结论：**BLOCKED** — 冒烟检查失败或关键阻断项阻止了周期完成；已产出部分报告。

## Session State Update

## 会话状态更新

After the final phase completes (sign-off report written or BLOCKED verdict reached), silently append to `production/session-state/active.md`:

在最终阶段完成后（签署报告已写入或达到 BLOCKED 结论），静默追加到 `production/session-state/active.md`：

```
<!-- QA RUN: [date] | Sprint: [sprint identifier or "ad-hoc"] | Verdict: [APPROVED/APPROVED WITH CONDITIONS/NOT APPROVED/NOT ASSESSED/BLOCKED] | Report: production/qa/qa-signoff-[sprint]-[date].md -->
```
