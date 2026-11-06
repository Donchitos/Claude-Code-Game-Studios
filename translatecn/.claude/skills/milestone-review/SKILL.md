---
name: milestone-review
description: "Milestone progress review — completeness, quality metrics, risk, go/no-go recommendation. At checkpoints or before a deadline."
argument-hint: "[milestone-name|current] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: milestone-review
description: "里程碑进度评审 —— 完整度、质量指标、风险、go/no-go 建议。在检查点或截止日期前使用。"
argument-hint: "[milestone-name|current] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

已在上面解析 —— 直接使用；`--review` 在本次运行中覆盖 `review_mode`。无
配置块 → 采用 `.claude/docs/config-resolution.md` 中的默认值。

# Milestone Review



## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

# 里程碑评审



## 输入不足 —— 在产出任何报告前检查此项

**如果本技能所需的输入不存在，答案就是"无法运行" ——
而不是一份填满的报告。** 先检查，若检查失败就停下。

1. 列出本技能读取的输入（数据文件、既有报告、性能剖析器输出、
   测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT` —— 而不是"假定存在"。
3. 如果某一节所需的任何输入是 ABSENT，该节就是
   **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻资产推断它，
   也不要留下一张强制表格让下一个读模板的人去填。
4. 如果**所有**必需输入都是 ABSENT，停下并把
   **`NOT ASSESSED — NO DATA`** 作为整体结论报告，点名缺失了什么以及
   哪个技能会产出它。

**`NOT ASSESSED` 的结论是一种成功。** 当没有数据时，它是对
"数据说明了什么？"正确而有用的回答。它防范的失败模式很具体：
一份结论枚举里没有"无法运行"状态的报告会产生
**虚假的干净通过** —— 在既无资产也无标准的项目上返回 COMPLIANT 的资产审计，
或是在零剖析器数据、从未设定预算的情况下，报告"相对 16.67ms 预算有 >99% 余量"的性能剖析。

**证据的缺失从来不是缺失的证据。** 一次因为没有任何文件可扫描而
零匹配的扫描，并没有验证任何东西。说清楚到底发生了这两种情况中的哪一种 ——
读者无法从一个绿色的结果中分辨。

---

## Phase 0: Parse Arguments

Extract the milestone name (`current` or a specific name).

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

---

## 阶段 0：解析参数

提取里程碑名称（`current` 或一个具体名称）。

完整检查模式见 `.claude/docs/director-gates.md`。各个门禁定义位于 `.claude/docs/director-gates/[gate-id].md` —— 被派生的智能体读取它自己的门禁文件；不要在父会话中读取它。


每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重大事项询问 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

---

## Phase 1: Load Milestone Data

Read the milestone definition from `production/milestones/` if it exists. If the
argument is `current`, use the most recently modified milestone file.

> **No skill writes `production/milestones/`** — definitions are authored by hand
> from `.claude/docs/templates/milestone-definition.md`, so most projects have
> none. When the directory is absent or empty, say so and review against the
> sprint reports alone; do not fabricate a definition. Take care with `current`:
> this skill writes its own output as `[milestone-name]-review.md`, so a
> most-recently-modified match can be a previous *review* rather than a
> definition. Skip files ending `-review.md` when selecting.

Gather the sprint reports for sprints within this milestone from
`production/sprints/`. Establish the denominator (glob them, count **N**), then
scan the sections a milestone review actually aggregates rather than reading each
report whole:

```
Grep pattern="^## (Sprint Goal|Capacity|Tasks|Carryover|Risks|Progress|Burndown Assessment|Emerging Risks|Definition of Done)" glob="production/sprints/sprint-*.md" output_mode="content" -A 12
```

> **These alternates are the headings `/sprint-plan` emits** (`## Sprint Goal`,
> not `## Goal`) — not what a milestone review might expect. A pattern that
> matches only one real heading still returns a non-zero count, so the
> zero-match escape hatch below never fires and the review aggregates a fraction
> of each report while reporting full coverage.

Full-read a single sprint report when its scanned sections point outside
themselves, or when it matched nothing — a zero-match report predates the
template and must be read, never silently dropped from the milestone's history.
Report any sprint that contributed nothing: a milestone summary that quietly
omits a sprint understates the work and the slippage both.

**Blocked stories** — the Blocked table and the blocked story count passed to
PR-MILESTONE — are not in the sprint reports' scanned sections. Read them where
they are recorded: the `status: blocked` stories in `production/sprint-status.yaml`
(with their `blocker` field) and, for stories outside that sprint, one grep:

```
Grep pattern="^> \*\*Status\*\*: Blocked|BLOCKED:" glob="production/epics/**/story-*.md" output_mode="content"
```

Each blocked story goes in the Blocked table under the feature its epic folder
implements, with its blocker (the yaml `blocker` field or the story's `BLOCKED:`
note). With no story files and no `sprint-status.yaml`, the Blocked table and the
blocked story count are `NOT ASSESSED — NO DATA`, not zero.

---

## 阶段 1：加载里程碑数据

如果 `production/milestones/` 存在，从中读取里程碑定义。如果
参数是 `current`，使用最近修改的里程碑文件。

> **没有任何技能会写入 `production/milestones/`** —— 定义是依据
> `.claude/docs/templates/milestone-definition.md` 手工编写的，所以大多数项目
> 并没有。当该目录不存在或为空时，说明这一点并仅依据
> 冲刺报告进行评审；不要编造定义。对 `current` 要小心：
> 本技能会把自己的输出写成 `[milestone-name]-review.md`，所以
> 最近修改的匹配项可能是一份之前的*评审*而不是
> 定义。选择时跳过以 `-review.md` 结尾的文件。

从 `production/sprints/` 收集本里程碑范围内各冲刺的冲刺报告。确定分母（glob 它们，数出 **N**），然后
扫描里程碑评审实际聚合的那些章节，而不是整份读取每份报告：

```
Grep pattern="^## (Sprint Goal|Capacity|Tasks|Carryover|Risks|Progress|Burndown Assessment|Emerging Risks|Definition of Done)" glob="production/sprints/sprint-*.md" output_mode="content" -A 12
```

> **这些备选标题正是 `/sprint-plan` 输出的**（`## Sprint Goal`，
> 而不是 `## Goal`）—— 并非里程碑评审可能预期的那样。一个只
> 匹配到一个真实标题的模式仍会返回非零计数，因此下面的
> 零匹配逃生口永远不会触发，评审会在报告完整覆盖的同时，只聚合每份报告的
> 一小部分。

当某份冲刺报告被扫描的章节指向其自身之外，或当它零匹配时，
完整读取该报告 —— 零匹配的报告早于模板，必须读取，
绝不能从里程碑历史中静默删除。
报告任何毫无贡献的冲刺：一份悄悄
遗漏某个冲刺的里程碑总结，会同时低估工作量和延期。

**被阻塞的故事** —— 传给
PR-MILESTONE 的 Blocked 表和阻塞故事计数 —— 不在冲刺报告被扫描的章节中。到它们被记录的地方
读取：`production/sprint-status.yaml` 中 `status: blocked` 的故事
（含其 `blocker` 字段），以及对于该冲刺之外的故事，一次 grep：

```
Grep pattern="^> \*\*Status\*\*: Blocked|BLOCKED:" glob="production/epics/**/story-*.md" output_mode="content"
```

每个被阻塞的故事都归入其史诗文件夹所实现功能下的 Blocked 表，
并带上其阻塞项（yaml 的 `blocker` 字段或故事的 `BLOCKED:`
注记）。若既无故事文件也无 `sprint-status.yaml`，Blocked 表和
阻塞故事计数就是 `NOT ASSESSED — NO DATA`，而不是零。

---

## Phase 2: Scan Codebase Health

- Scan for `TODO`, `FIXME`, `HACK` markers that indicate incomplete work
- Count open bugs by severity for Quality Metrics from `production/qa/bugs/` (one grep of the `**Severity**` and `**Status**` lines, as `/bug-triage` does); with no bug files, the bug lines are `NOT ASSESSED — NO DATA`, not zero
- Check the risk register at `production/risk-register/` if it exists (hand-authored from `.claude/docs/templates/risk-register-entry.md`; no skill writes it, so absence is normal — note it rather than skipping risk assessment silently)

---

## 阶段 2：扫描代码库健康度

- 扫描 `TODO`、`FIXME`、`HACK` 标记，它们表示未完成的工作
- 从 `production/qa/bugs/` 按严重程度统计未关闭的缺陷，用于质量指标（像 `/bug-triage` 那样，对 `**Severity**` 和 `**Status**` 各行做一次 grep）；若无缺陷文件，缺陷相关行就是 `NOT ASSESSED — NO DATA`，而不是零
- 如果 `production/risk-register/` 存在，检查风险登记册（依据 `.claude/docs/templates/risk-register-entry.md` 手工编写；没有技能写入它，所以缺失是正常的 —— 记录它，而不是静默跳过风险评估）

---

## Phase 3: Generate the Milestone Review

```markdown
# Milestone Review: [Milestone Name]

## Overview
- **Target Date**: [Date]
- **Current Date**: [Today]
- **Days Remaining**: [N]
- **Sprints Completed**: [X/Y]

## Feature Completeness

### Fully Complete
Only a feature whose Status is `Complete` goes here or counts toward the completion percentage; a Deferred feature stays in its denominator, named with the milestone it moved to.

| Feature | Acceptance Criteria | Test Status |
|---------|-------------------|-------------|

### Partially Complete
| Feature | % Done | Remaining Work | Risk to Milestone |
|---------|--------|---------------|------------------|

### Blocked
A started feature whose stories are Blocked goes here, not under Partially
Complete — name the blocker, so the review says why it stalled, not only that
the count moved.

| Feature | Blocked Stories | Blocker | Next Action / Owner |
|---------|----------------|---------|---------------------|

### Not Started
| Feature | Priority | Can Cut? | Impact of Cutting |
|---------|----------|----------|------------------|

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
|------|--------|-------------------|------------------|

## Velocity Analysis
- **Planned vs Completed** (across all sprints): [X/Y tasks = Z%]
- **Trend**: [Improving / Stable / Declining]
- **Adjusted estimate for remaining work**: [Days needed at current velocity]

## Scope Recommendations
### Protect (Must ship with milestone)
- [Feature and why]

### At Risk (May need to cut or simplify)
- [Feature and risk]

### Cut Candidates (Can defer without compromising milestone)
- [Feature and impact of cutting]

## Go/No-Go Assessment

**Recommendation**: [NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]

**Conditions** (if conditional):
- [Condition 1 that must be met]
- [Condition 2 that must be met]

**Rationale**: [Explanation of the recommendation]

## Action Items
| # | Action | Owner | Deadline |
|---|--------|-------|----------|
```

---

## 阶段 3：生成里程碑评审

```markdown
# Milestone Review: [Milestone Name]

## Overview
- **Target Date**: [Date]
- **Current Date**: [Today]
- **Days Remaining**: [N]
- **Sprints Completed**: [X/Y]

## Feature Completeness

### Fully Complete
Only a feature whose Status is `Complete` goes here or counts toward the completion percentage; a Deferred feature stays in its denominator, named with the milestone it moved to.

| Feature | Acceptance Criteria | Test Status |
|---------|-------------------|-------------|

### Partially Complete
| Feature | % Done | Remaining Work | Risk to Milestone |
|---------|--------|---------------|------------------|

### Blocked
A started feature whose stories are Blocked goes here, not under Partially
Complete — name the blocker, so the review says why it stalled, not only that
the count moved.

| Feature | Blocked Stories | Blocker | Next Action / Owner |
|---------|----------------|---------|---------------------|

### Not Started
| Feature | Priority | Can Cut? | Impact of Cutting |
|---------|----------|----------|------------------|

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
|------|--------|-------------------|------------------|

## Velocity Analysis
- **Planned vs Completed** (across all sprints): [X/Y tasks = Z%]
- **Trend**: [Improving / Stable / Declining]
- **Adjusted estimate for remaining work**: [Days needed at current velocity]

## Scope Recommendations
### Protect (Must ship with milestone)
- [Feature and why]

### At Risk (May need to cut or simplify)
- [Feature and risk]

### Cut Candidates (Can defer without compromising milestone)
- [Feature and impact of cutting]

## Go/No-Go Assessment

**Recommendation**: [NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]

**Conditions** (if conditional):
- [Condition 1 that must be met]
- [Condition 2 that must be met]

**Rationale**: [Explanation of the recommendation]

## Action Items
| # | Action | Owner | Deadline |
|---|--------|-------|----------|
```

```markdown
# 里程碑评审：[Milestone Name]

## 概览
- **目标日期**：[Date]
- **当前日期**：[Today]
- **剩余天数**：[N]
- **已完成冲刺**：[X/Y]

## 功能完整度

### 完全完成
只有状态为 `Complete` 的功能才进入此处，或计入完成百分比；Deferred（已推迟）的功能仍留在分母中，并注明它被移到了哪个里程碑。

| 功能 | 验收标准 | 测试状态 |
|---------|-------------------|-------------|

### 部分完成
| 功能 | 完成百分比 | 剩余工作 | 对里程碑的风险 |
|---------|--------|---------------|------------------|

### 被阻塞
已启动但故事被阻塞的功能进入此处，而不是放在部分完成
下 —— 点名阻塞项，让评审说明它为何停滞，而不只是
计数变了。

| 功能 | 被阻塞故事 | 阻塞项 | 下一步行动 / 负责人 |
|---------|----------------|---------|---------------------|

### 未开始
| 功能 | 优先级 | 能否砍掉？ | 砍掉的影响 |
|---------|----------|----------|------------------|

## 质量指标
- **未关闭 S1 缺陷**：[N] —— [列表]
- **未关闭 S2 缺陷**：[N]
- **未关闭 S3 缺陷**：[N]
- **测试覆盖率**：[X%]
- **性能**：[在预算内？详情]

## 代码健康度
- **TODO 计数**：[N，整个代码库]
- **FIXME 计数**：[N]
- **HACK 计数**：[N]
- **技术债条目**：[列出关键项]

## 风险评估
| 风险 | 状态 | 若实现的冲击 | 缓解状态 |
|------|--------|-------------------|------------------|

## 速度分析
- **计划 vs 完成**（所有冲刺合计）：[X/Y 个任务 = Z%]
- **趋势**：[上升 / 稳定 / 下降]
- **剩余工作的调整估算**：[当前速度下所需天数]

## 范围建议
### 保护（必须随里程碑交付）
- [功能及原因]

### 有风险（可能需要砍掉或简化）
- [功能及风险]

### 可砍候选（可推迟而不损害里程碑）
- [功能及砍掉的影响]

## Go/No-Go 评估

**建议**：[NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]

**条件**（若为有条件）：
- [必须满足的条件 1]
- [必须满足的条件 2]

**理由**：[建议的说明]

## 行动项
| # | 行动 | 负责人 | 截止日期 |
|---|--------|-------|----------|
```

---

## Phase 3b: Producer Risk Assessment

**Review mode check** — apply before spawning PR-MILESTONE:
- `solo` → skip. Note: "PR-MILESTONE skipped — Solo mode." Present the Go/No-Go section without a producer verdict.
- `lean` → skip (not a PHASE-GATE). Note: "PR-MILESTONE skipped — Lean mode." Present the Go/No-Go section without a producer verdict.
- `full` → spawn as normal.

Before generating the Go/No-Go recommendation, spawn `producer` via `Agent` using gate **PR-MILESTONE** (`.claude/docs/director-gates/pr-milestone.md`).

Pass: milestone name and target date, current completion percentage, blocked story count, velocity data from sprint reports (if available), list of cut candidates.

Present the producer's assessment inline within the Go/No-Go section. The producer's verdict (ON TRACK / AT RISK / OFF TRACK) informs the overall recommendation.

If OFF TRACK, use `AskUserQuestion` before generating the recommendation:

- Prompt: "Producer verdict: OFF TRACK. The milestone is in jeopardy. This review will recommend NO-GO. How do you want to proceed?"
- Options:
  - `[A] Accept NO-GO — generate the full review with that recommendation`
  - `[B] Override to CONDITIONAL GO — I'll document the accepted risks myself`
  - `[C] Stop — I want to address blockers before generating the review`

If AT RISK, use `AskUserQuestion`:
- Prompt: "Producer verdict: AT RISK. Milestone may slip. How should the Go/No-Go section be framed?"
- Options:
  - `[A] CONDITIONAL GO — include producer's conditions in the review`
  - `[B] NO-GO — conditions cannot be met in time`
  - `[C] GO — I accept the risk and want to proceed`

If NOT ASSESSED: name the missing input — it is not ON TRACK, and never recommend GO on it. Supply the input and re-run PR-MILESTONE, or recommend NOT ASSESSED — or CONDITIONAL GO / NO-GO where the review's own findings call for one (the rank in `.claude/docs/director-gates.md`).

Do not issue a GO against an OFF TRACK verdict; issue CONDITIONAL GO only if the user explicitly selects [B] above.

---

## 阶段 3b：制作人风险评估

**评审模式检查** —— 在派生 PR-MILESTONE 之前应用：
- `solo` → 跳过。注明："PR-MILESTONE skipped — Solo mode." 在没有制作人结论的情况下呈现 Go/No-Go 部分。
- `lean` → 跳过（不是 PHASE-GATE）。注明："PR-MILESTONE skipped — Lean mode." 在没有制作人结论的情况下呈现 Go/No-Go 部分。
- `full` → 照常派生。

在生成 Go/No-Go 建议之前，通过 `Agent` 使用门禁 **PR-MILESTONE**（`.claude/docs/director-gates/pr-milestone.md`）派生 `producer`。

传入：里程碑名称和目标日期、当前完成百分比、被阻塞故事计数、来自冲刺报告的速度数据（若有）、可砍候选列表。

在 Go/No-Go 部分内联呈现制作人的评估。制作人的结论（ON TRACK / AT RISK / OFF TRACK）会影响整体建议。

如果为 OFF TRACK，在生成建议前使用 `AskUserQuestion`：

- 提示："制作人结论：OFF TRACK。里程碑岌岌可危。本次评审将建议 NO-GO。你希望如何继续？"
- 选项：
  - `[A] Accept NO-GO — generate the full review with that recommendation`
  - `[B] Override to CONDITIONAL GO — I'll document the accepted risks myself`
  - `[C] Stop — I want to address blockers before generating the review`

如果为 AT RISK，使用 `AskUserQuestion`：
- 提示："制作人结论：AT RISK。里程碑可能延期。Go/No-Go 部分应如何表述？"
- 选项：
  - `[A] CONDITIONAL GO — include producer's conditions in the review`
  - `[B] NO-GO — conditions cannot be met in time`
  - `[C] GO — I accept the risk and want to proceed`

如果为 NOT ASSESSED：点名缺失的输入 —— 它不是 ON TRACK，绝不要据此建议 GO。提供该输入并重跑 PR-MILESTONE，或建议 NOT ASSESSED —— 或在评审自身发现要求时建议 CONDITIONAL GO / NO-GO（排名见 `.claude/docs/director-gates.md`）。

不要针对 OFF TRACK 结论发出 GO；只有当用户显式选择上述 [B] 时才发出 CONDITIONAL GO。

---

## Phase 4: Save Review

Present the review to the user.

Ask: "May I write this to `production/milestones/[milestone-name]-review.md`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — milestone review saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## 阶段 4：保存评审

向用户呈现评审。

询问："我可以把它写入 `production/milestones/[milestone-name]-review.md` 吗？"

如果是，写文件，必要时创建目录。结论：**COMPLETE** —— 里程碑评审已保存。

如果否，停在这里。结论：**BLOCKED** —— 用户拒绝写入。

---

## Phase 5: Next Steps

- Run `/gate-check` for a formal phase gate verdict if this milestone marks a development phase boundary.
- Run `/sprint-plan` to adjust the next sprint based on the scope recommendations above (at `workflow: minimal`, which has no sprints, adjust the brief's build order instead).

## 阶段 5：下一步

- 如果本里程碑标志着一个开发阶段边界，运行 `/gate-check` 获取正式的阶段门禁结论。
- 基于上面的范围建议，运行 `/sprint-plan` 调整下一个冲刺（在 `workflow: minimal` 下没有冲刺，改为调整简报的构建顺序）。
