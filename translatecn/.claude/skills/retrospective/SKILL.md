---
name: retrospective
description: "Sprint or milestone retrospective from completed work, velocity, blockers. Actionable insights for the next iteration."
argument-hint: "[sprint-N|milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/retrospective/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *)
model: sonnet
---

---
name: retrospective
description: "基于已完成工作、速度和阻碍项的冲刺或里程碑复盘。为下一次迭代提供可执行的洞察。"
argument-hint: "[sprint-N|milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/retrospective/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level`

# Retrospective

# 复盘

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类别始终会询问）。

## Insufficient input — check this before producing any report

## 输入不足 —— 在生成任何报告之前先检查

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

**如果本技能所需的输入不存在，答案就是"无法运行"—— 而不是一份填好的报告。** 先检查，如果检查失败就停止。

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

1. 列出本技能读取的输入（数据文件、此前的报告、性能分析器输出、测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT` —— 而不是"假定存在"。
3. 如果某个小节所需的任何输入为 ABSENT，该小节就是 **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻产物推断它，也不要留下一个由下一个读模板的人来填写的必需单元格。
4. 如果**所有**必需输入都是 ABSENT，停止并把 **`NOT ASSESSED — NO DATA`** 作为整体结论报告，说明缺失了什么以及由哪个技能产生它。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**`NOT ASSESSED` 结论是一种成功。** 在没有数据时，它是"数据说明了什么？"这个问题的正确且有意义的答案。这所防止的失败模式很具体：一份结论枚举中没有"无法运行"状态的报告会产生**虚假的干净通过** —— 在一个没有任何资产和标准的项目上资产审计返回 COMPLIANT，或者在一份零性能分析数据、从未设定预算的情况下性能概况报告">99% 余量，相对 16.67ms 预算"。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

**没有证据从不等于证据表明不存在。** 一次因为没有文件可扫描而未找到任何匹配的扫描，并没有验证任何东西。要说明发生了这两种情况中的哪一种 —— 读者无法从绿色结果中分辨出来。

---

## Phase 1: Parse Arguments

## 阶段 1：解析参数

Determine whether this is a sprint retrospective (`sprint-N`) or a milestone retrospective (`milestone-name`).

判断这是一次冲刺复盘（`sprint-N`）还是一次里程碑复盘（`milestone-name`）。

---

## Phase 1b: Check for Existing Retrospective

## 阶段 1b：检查是否已有复盘

Before loading any data, glob for an existing retrospective file:

在加载任何数据之前，先用 glob 查找已有的复盘文件：

- For sprint retrospectives: `production/retrospectives/retro-[sprint-slug]-*.md`
  (also check `production/sprints/sprint-[N]-retrospective.md` as an alternate location)
- For milestone retrospectives: `production/retrospectives/retro-[milestone-name]-*.md`

- 冲刺复盘：`production/retrospectives/retro-[sprint-slug]-*.md`
  （同时检查备用位置 `production/sprints/sprint-[N]-retrospective.md`）
- 里程碑复盘：`production/retrospectives/retro-[milestone-name]-*.md`

If a matching file is found, use `AskUserQuestion`:
- Prompt: "An existing retrospective was found: [filename]. How do you want to proceed?"
- Options:
  - `[A] Update existing — load it and add/revise sections with new data`
  - `[B] Start fresh — generate a new retrospective (archive the old one)`

如果找到匹配文件，使用 `AskUserQuestion`：
- 提示："发现已有复盘：[filename]。你希望如何处理？"
- 选项：
  - `[A] 更新现有文件 —— 加载它并用新数据新增/修订小节`
  - `[B] 从头开始 —— 生成新复盘（归档旧文件）`

If [A]: read the existing file and carry its content forward, revising sections with new data.
If [B]: continue to Phase 2 with a blank slate. Before writing the new file, rename the existing one with a `-archived-[date]` suffix. That rename is a write too: it happens in Phase 5, only once the ask there — which names it — is approved.

如果选 [A]：读取现有文件并沿用其内容，用新数据修订各小节。
如果选 [B]：以空白状态继续阶段 2。在写入新文件之前，用 `-archived-[date]` 后缀重命名现有文件。这个重命名也是一次写入：它在阶段 5 才发生，且仅当那里（明确点名了它）的询问被批准后才发生。

---

## Phase 2: Load Sprint or Milestone Data

## 阶段 2：加载冲刺或里程碑数据

Read the sprint or milestone plan from the appropriate location:

从相应位置读取冲刺或里程碑计划：

- Sprint plans: `production/sprints/`
- Milestone definitions: `production/milestones/`

- 冲刺计划：`production/sprints/`
- 里程碑定义：`production/milestones/`

**Also check for `production/sprint-status.yaml`**: if it exists, read it alongside the sprint plan. It is the authoritative source for actual story completion status (status: done, completed dates, blockers). Use it as the primary source for completion metrics in Phase 3. Fall back to markdown scanning only if the yaml does not exist. Note discrepancies between the yaml and the sprint plan (e.g., stories in yaml not in plan, or vice versa).

**同时检查 `production/sprint-status.yaml`**：如果存在，就与冲刺计划一并读取。它是故事实际完成状态（status: done、完成日期、阻碍项）的权威来源。在阶段 3 中把它作为完成度指标的主要来源。只有在 yaml 不存在时才回退到 markdown 扫描。记录 yaml 与冲刺计划之间的差异（例如 yaml 中有但计划中没有的故事，或反之）。

**If the file does not exist or is empty**, output:

**如果文件不存在或为空**，输出：

> "No sprint data found for [sprint/milestone]. Run `/sprint-plan new` to create a
> sprint (`/sprint-status` only reads one), or provide the sprint details manually."

> "未找到 [sprint/milestone] 的冲刺数据。运行 `/sprint-plan new` 创建一份
> 冲刺（`/sprint-status` 只读取一份），或手动提供冲刺详情。"

At `workflow: minimal` (resolved above) there are no sprints: offer to look back over the stories
closed so far instead (`production/epics/*/story-*.md` with `Status: Complete`).
At `qa.level: minimal` (resolved above) tests are waived, so a story closed
without one is not a finding; a Visual/Feel or UI story closed without its
retained screenshot still is.

在 `workflow: minimal`（已在上面解析）下没有冲刺：改为提议回顾目前已关闭的故事（`production/epics/*/story-*.md`，其 `Status: Complete`）。
在 `qa.level: minimal`（已在上面解析）下测试被豁免，因此没有测试就关闭的故事不算问题；但一个未保留截图的 Visual/Feel 或 UI 故事仍然算问题。

Then use `AskUserQuestion` to present these options ([C] only at `workflow: minimal`):

然后使用 `AskUserQuestion` 呈现这些选项（[C] 仅在 `workflow: minimal` 下提供）：

- **[A] Provide data manually** — ask the user to paste or describe the sprint
  tasks, dates, and outcomes; use that as the source of truth for the retrospective.
- **[B] Stop** — abort the skill. Verdict: **BLOCKED** — no sprint data available.
- **[C] Look back over the closed stories** — use the stories with
  `Status: Complete` as the record of what was done.

- **[A] 手动提供数据** —— 请用户粘贴或描述冲刺任务、日期和结果；将其作为复盘的真相来源。
- **[B] 停止** —— 中止技能。结论：**BLOCKED** —— 没有可用的冲刺数据。
- **[C] 回顾已关闭的故事** —— 使用 `Status: Complete` 的故事作为已完成工作的记录。

If the user chooses [A], collect the data and continue to Phase 3 using what they provide.
If the user chooses [B], stop here.
If the user chooses [C], read those stories and continue to Phase 3. Sections that
need sprint data (planned vs actual, velocity, carryover, estimation accuracy)
are `NOT ASSESSED — NO DATA`.

如果用户选择 [A]，收集数据并使用其提供的内容继续阶段 3。
如果用户选择 [B]，在此停止。
如果用户选择 [C]，读取那些故事并继续阶段 3。需要冲刺数据的小节（计划 vs 实际、速度、结转、估算准确性）为 `NOT ASSESSED — NO DATA`。

Extract: planned tasks, estimated effort, owners, and goals.

提取：计划任务、预估工作量、负责人和目标。

Run git log for the sprint period to understand what was actually committed and when. Use the Bash tool (which uses Git Bash on Windows — the `2>/dev/null` is bash syntax, not PowerShell):

运行该冲刺期间的 git log，以了解实际提交了什么以及何时提交。使用 Bash 工具（在 Windows 上使用 Git Bash —— `2>/dev/null` 是 bash 语法，不是 PowerShell）：

```
Bash: git log --oneline --since="4 weeks ago" 2>/dev/null || git log --oneline -20
```

```
Bash: git log --oneline --since="4 weeks ago" 2>/dev/null || git log --oneline -20
```

Adjust the `--since` date to match the sprint duration if known from the sprint plan.

如果从冲刺计划中已知冲刺时长，调整 `--since` 日期以与之匹配。

---

## Phase 3: Analyze Completion and Trends

## 阶段 3：分析完成度与趋势

Scan for completed and incomplete tasks by comparing the plan against actual deliverables. Check for:

通过将计划与实际交付物对比，扫描已完成和未完成的任务。检查：

- Tasks completed as planned
- Tasks completed but modified from the plan
- Tasks carried over (not completed)
- Tasks added mid-sprint (unplanned work)
- Tasks removed or descoped

- 按计划完成的任务
- 已完成但与计划有所修改的任务
- 结转的任务（未完成）
- 冲刺中期新增的任务（计划外工作）
- 被移除或缩减范围的任务

Every story with `status: blocked` in `production/sprint-status.yaml` goes under
Blockers Encountered, with its `blocker` field as the Blocker, and gets an action
item in Action Items for Next Iteration.

`production/sprint-status.yaml` 中每个 `status: blocked` 的故事都归入"遇到的阻碍"，其 `blocker` 字段作为阻碍项，并在"下一次迭代的行动项"中获得一个行动项。

Scan the codebase for TODO/FIXME trends:

扫描代码库中的 TODO/FIXME 趋势：

- Count current TODO/FIXME/HACK comments
- Compare to previous sprint counts if available (check previous retrospectives)
- Note whether technical debt is growing or shrinking

- 统计当前的 TODO/FIXME/HACK 注释
- 如有可用数据，与之前冲刺的计数对比（查看此前的复盘）
- 记录技术债务是在增长还是减少

Read previous retrospectives (if any) from `production/retrospectives/` to check:

从 `production/retrospectives/` 读取此前的复盘（如有），以检查：

- Were previous action items addressed?
- Are the same problems recurring?
- How has velocity trended?

- 此前的行动项是否得到处理？
- 同样的问题是否反复出现？
- 速度趋势如何？

With no earlier sprint or retrospective, Velocity Trend keeps only the current
sprint's row and reads `NOT ASSESSED — NO DATA`, and Previous Action Items
Follow-Up is that one line — no invented earlier rows, no empty table.

如果没有更早的冲刺或复盘，速度趋势只保留当前冲刺这一行并标记为 `NOT ASSESSED — NO DATA`，而"此前行动项跟进"就是那一行 —— 不虚构更早的行，也不留空表格。

---

## Phase 4: Generate the Retrospective

## 阶段 4：生成复盘

```markdown
## Retrospective: [Sprint N / Milestone Name]
Period: [Start Date] -- [End Date]
Generated: [Date]

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks | [X] | [Y] | [+/- Z] |
| Completion Rate | -- | [Z%] | -- |
| Story Points / Effort Days | [X] | [Y] | [+/- Z] |
| Bugs Found | -- | [N] | -- |
| Bugs Fixed | -- | [N] | -- |
| Unplanned Tasks Added | -- | [N] | -- |
| Commits | -- | [N] | -- |

### Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| [N-2] | [X] | [Y] | [Z%] |
| [N-1] | [X] | [Y] | [Z%] |
| [N] (current) | [X] | [Y] | [Z%] |

**Trend**: [Increasing / Stable / Decreasing — or `NOT ASSESSED — NO DATA` with no earlier sprint to compare]
[One sentence explaining the trend]

### What Went Well
- [Observation backed by specific data or examples]
- [Another positive observation]
- [Recognize specific contributions or decisions that paid off]

### What Went Poorly
- [Specific issue with measurable impact -- e.g., "Feature X took 5 days
  instead of estimated 2, blocking tasks Y and Z"]
- [Another issue with impact]
- [Do not assign blame -- focus on systemic causes]

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| [What blocked progress] | [How long] | [How it was resolved] | [How to prevent recurrence] |

### Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| [Most overestimated task] | [X] | [Y] | [+Z] | [Why] |
| [Most underestimated task] | [X] | [Y] | [-Z] | [Why] |

**Overall estimation accuracy**: [X%] of tasks within +/- 20% of estimate

[Analysis: Are we consistently over- or under-estimating? For which types of
tasks? What adjustment should we apply?]

### Carryover Analysis

| Task | Original Sprint | Times Carried | Reason | Action |
|------|----------------|---------------|--------|--------|
| [Task that was not completed] | [Sprint N-X] | [N] | [Why] | [Complete / Descope / Redesign] |

### Technical Debt Status
- Current TODO count: [N] (previous: [N])
- Current FIXME count: [N] (previous: [N])
- Current HACK count: [N] (previous: [N])
- Trend: [Growing / Stable / Shrinking]
- [Note any areas of concern]

### Previous Action Items Follow-Up

| Action Item (from Sprint N-1) | Status | Notes |
|-------------------------------|--------|-------|
| [Previous action] | [Done / In Progress / Not Started] | [Context] |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | [Specific, measurable action] | [Who] | [High/Med/Low] | [When] |
| 2 | [Another action] | [Who] | [Priority] | [When] |

### Process Improvements
- [Specific change to how we work, with expected benefit]
- [Another improvement -- keep it to 2-3 actionable items, not a wish list]

### Summary
[2-3 sentence overall assessment: Was this a good sprint/milestone? What is
the single most important thing to change going forward?]
```

```markdown
## 复盘：[Sprint N / Milestone Name]
时间段：[Start Date] -- [End Date]
生成时间：[Date]

### 指标

| 指标 | 计划 | 实际 | 差值 |
|--------|---------|--------|-------|
| 任务数 | [X] | [Y] | [+/- Z] |
| 完成率 | -- | [Z%] | -- |
| 故事点 / 工作量天数 | [X] | [Y] | [+/- Z] |
| 发现的缺陷数 | -- | [N] | -- |
| 修复的缺陷数 | -- | [N] | -- |
| 新增的计划外任务 | -- | [N] | -- |
| 提交数 | -- | [N] | -- |

### 速度趋势

| 冲刺 | 计划 | 已完成 | 完成率 |
|--------|---------|-----------|------|
| [N-2] | [X] | [Y] | [Z%] |
| [N-1] | [X] | [Y] | [Z%] |
| [N]（当前） | [X] | [Y] | [Z%] |

**趋势**：[Increasing / Stable / Decreasing —— 或在没有更早冲刺可对比时标记 `NOT ASSESSED — NO DATA`]
[用一句话解释该趋势]

### 做得好的地方
- [有具体数据或示例支撑的观察]
- [另一项正面观察]
- [认可产生回报的具体贡献或决策]

### 做得不好的地方
- [具有可衡量影响的具体问题 —— 例如："功能 X 花了 5 天
  而非预估的 2 天，阻塞了任务 Y 和 Z"]
- [另一项有影响的问题]
- [不要归咎个人 —— 聚焦系统性原因]

### 遇到的阻碍

| 阻碍项 | 持续时间 | 解决方式 | 预防措施 |
|---------|----------|------------|------------|
| [什么阻碍了进展] | [多久] | [如何解决] | [如何防止再次发生] |

### 估算准确性

| 任务 | 预估 | 实际 | 偏差 | 可能原因 |
|------|-----------|--------|----------|--------------|
| [最被高估的任务] | [X] | [Y] | [+Z] | [原因] |
| [最被低估的任务] | [X] | [Y] | [-Z] | [原因] |

**整体估算准确性**：[X%] 的任务在预估的 +/- 20% 之内

[分析：我们是否持续高估或低估？对哪些类型的任务？
我们应做出什么调整？]

### 结转分析

| 任务 | 原冲刺 | 结转次数 | 原因 | 行动 |
|------|----------------|---------------|--------|--------|
| [未完成的任务] | [Sprint N-X] | [N] | [原因] | [完成 / 缩减范围 / 重新设计] |

### 技术债务状态
- 当前 TODO 数量：[N]（此前：[N]）
- 当前 FIXME 数量：[N]（此前：[N]）
- 当前 HACK 数量：[N]（此前：[N]）
- 趋势：[Growing / Stable / Shrinking]
- [记录任何值得关注的领域]

### 此前行动项跟进

| 行动项（来自 Sprint N-1） | 状态 | 备注 |
|-------------------------------|--------|-------|
| [此前的行动] | [Done / In Progress / Not Started] | [背景] |

### 下一次迭代的行动项

| # | 行动 | 负责人 | 优先级 | 截止日期 |
|---|--------|-------|----------|----------|
| 1 | [具体、可衡量的行动] | [谁] | [High/Med/Low] | [何时] |
| 2 | [另一项行动] | [谁] | [Priority] | [何时] |

### 流程改进
- [对我们工作方式的具体改变，以及预期收益]
- [另一项改进 —— 保持在 2-3 个可执行项，而不是愿望清单]

### 总结
[2-3 句话的整体评估：这次冲刺/里程碑是否顺利？未来最需要
改变的一件事是什么？]
```

---

## Phase 5: Save Retrospective

## 阶段 5：保存复盘

Present the retrospective and top findings to the user (completion rate, velocity trend, top blocker, most important action item).

向用户呈现复盘和主要发现（完成率、速度趋势、最大的阻碍项、最重要的行动项）。

Ask: "May I write this to `production/retrospectives/retro-sprint-[N]-[date].md`?" (or `production/retrospectives/retro-[milestone-name]-[date].md` for milestone retrospectives)

询问："我可以把它写入 `production/retrospectives/retro-sprint-[N]-[date].md` 吗？"（里程碑复盘则使用 `production/retrospectives/retro-[milestone-name]-[date].md`）

After Start fresh in Phase 1b, the same ask also names the rename: "…and rename
`[old file]` to `[old file name]-archived-[date].md`?" On yes, rename first, then
write; on no, neither happens.

在阶段 1b 选择"从头开始"之后，同一次询问也会点明重命名："……并把 `[old file]` 重命名为 `[old file name]-archived-[date].md`？" 若同意，先重命名再写入；若不同意，两者都不发生。

If yes, write the file, creating the `production/retrospectives/` directory if needed. Verdict: **COMPLETE** — retrospective saved.

如果同意，写入文件，必要时创建 `production/retrospectives/` 目录。结论：**COMPLETE** —— 复盘已保存。

If no, stop here. Verdict: **BLOCKED** — user declined write.

如果不同意，在此停止。结论：**BLOCKED** —— 用户拒绝写入。

---

## Phase 6: Next Steps

## 阶段 6：后续步骤

At `workflow: minimal` (resolved above), which has no sprints, skip this question:
point to the retrospective file and say its action items go into the brief's build
order.

在 `workflow: minimal`（已在上面解析）下没有冲刺，跳过此问题：指向复盘文件，并说明其行动项归入简报的构建顺序。

Otherwise, use `AskUserQuestion`:
- Prompt: "Retrospective complete. The action items and velocity data are ready. Would you like to start sprint planning now with this data pre-loaded?"
- Options:
  - `[A] Yes — open sprint planning with retro action items and velocity delta pre-populated`
  - `[B] No — I'll reference the retrospective file manually when I'm ready`

否则，使用 `AskUserQuestion`：
- 提示："复盘已完成。行动项和速度数据已就绪。你希望现在用这些预加载的数据开始冲刺规划吗？"
- 选项：
  - `[A] 是 —— 打开冲刺规划，并预填复盘行动项和速度变化`
  - `[B] 否 —— 我在准备好时手动引用复盘文件`

If the user selects [A]: Proceed to invoke `/sprint-plan new`, passing the retrospective file path and a summary of the action items and velocity change so the sprint planner can reference them.

如果用户选择 [A]：继续调用 `/sprint-plan new`，传入复盘文件路径以及行动项和速度变化的摘要，以便冲刺规划器引用它们。

- If this was a milestone retrospective, run `/gate-check` to formally assess readiness for the next phase.

- 如果这是一次里程碑复盘，运行 `/gate-check` 正式评估进入下一阶段的就绪度。

### Guidelines

### 指南

- Be honest and specific. Vague retrospectives ("communication could be better") produce vague improvements. Use data and examples.
- Focus on systemic issues, not individual blame.
- Limit action items to 3-5. More than that dilutes focus.
- Every action item must have an owner and a deadline.
- Check whether previous action items were completed. Recurring unaddressed items are a process smell.
- If this is a milestone retrospective, also evaluate whether the milestone goals were achieved and what that means for the overall project timeline.

- 诚实且具体。含糊的复盘（"沟通可以更好"）会产生含糊的改进。使用数据和示例。
- 聚焦系统性问题，而不是个人归咎。
- 行动项限制在 3-5 个。更多会稀释焦点。
- 每个行动项都必须有负责人和截止日期。
- 检查此前的行动项是否已完成。反复出现却未被处理的行动项是流程的异味。
- 如果这是一次里程碑复盘，还要评估里程碑目标是否达成，以及这对整体项目时间线意味着什么。
