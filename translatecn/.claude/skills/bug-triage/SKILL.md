---
name: bug-triage
description: "Re-evaluate open bugs — priority vs severity, assign to sprints, surface systemic trends. Run when the count grows."
argument-hint: "[sprint | full | trend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/bug-triage/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: bug-triage
description: "重新评估未关闭缺陷——优先级与严重程度、分配到冲刺、揭示系统性问题趋势。当数量增长时运行。"
argument-hint: "[sprint | full | trend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/bug-triage/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与每次文件写入都遵循 `.claude/docs/automation-modes.md`（协作模式总是询问 · 引导模式仅重大问题 · 自主模式记录并继续；`automation_always_ask` 类别总是提示）。

# Bug Triage
# 缺陷分类

This skill processes the open bug backlog into a prioritised, sprint-assigned
action list. It distinguishes between **severity** (how bad is the impact?) and
**priority** (how urgently must we fix it?), detects systemic trends, and
ensures no critical bug is lost between sprints.

本技能将未关闭的缺陷积压处理为一份按优先级排序、已分配冲刺的行动清单。它区分**严重程度**（影响有多糟糕？）与**优先级**（必须多紧急地修复？），检测系统性问题趋势，并确保没有关键缺陷在冲刺之间被遗漏。

**Output:** `production/qa/bug-triage-[date].md`

**输出：** `production/qa/bug-triage-[date].md`

**When to run:**
- Sprint start — assign open bugs to the new sprint or backlog
- After `/team-qa` completes and new bugs have been filed
- When the bug count crosses 10+ open items

**何时运行：**
- 冲刺开始——将未关闭缺陷分配到新冲刺或待办
- 在 `/team-qa` 完成且新缺陷已提交之后
- 当未关闭缺陷数量超过 10+ 项时

---

## 1. Parse Arguments
## 1. 解析参数

**Modes:**
- `/bug-triage sprint` — triage against the current sprint; assign fixable bugs
  to the sprint backlog; defer the rest
- `/bug-triage full` — full triage of all bugs regardless of sprint scope
- `/bug-triage trend` — trend analysis only (no assignment); read-only report
- No argument — run sprint mode if a current sprint exists, else full mode

**模式：**
- `/bug-triage sprint`——针对当前冲刺进行分类；将可修复缺陷分配到冲刺待办；其余延后
- `/bug-triage full`——无论冲刺范围如何，对所有缺陷进行完整分类
- `/bug-triage trend`——仅趋势分析（不分配）；只读报告
- 无参数——如果存在当前冲刺则运行冲刺模式，否则运行完整模式

---

## 2. Load Bug Backlog
## 2. 加载缺陷积压

### Step 2a — Discover bug files
### 步骤 2a——发现缺陷文件

Glob for bug reports in priority order:
1. `production/qa/bugs/*.md` — individual bug report files (preferred format)
2. `production/qa/bugs.md` — single consolidated bug log (fallback)
3. Any `production/qa/qa-plan-*.md` "Bugs Found" table (last resort)

按优先级顺序 Glob 查找缺陷报告：
1. `production/qa/bugs/*.md`——单个缺陷报告文件（首选格式）
2. `production/qa/bugs.md`——单一合并缺陷日志（后备）
3. 任何 `production/qa/qa-plan-*.md` 的 "Bugs Found" 表（最后手段）

If no bug files found:
> "No bug files found in `production/qa/bugs/`. If bugs are tracked in a
> different location, adjust the glob pattern. If no bugs exist yet, there is
> nothing to triage."

如果未找到缺陷文件：
> “在 `production/qa/bugs/` 中未找到缺陷文件。如果缺陷记录在其他位置，请调整 glob 模式。如果目前还没有缺陷，则无需分类。”

Stop and report. Do not proceed if no bugs exist. Verdict: **COMPLETE** — no bug files in `production/qa/bugs/`; nothing to triage.

停止并报告。如果不存在缺陷，不得继续。结论：**COMPLETE**——`production/qa/bugs/` 中没有缺陷文件；无需分类。

**In `trend` mode, do not read full bug bodies.** Trend metrics (volume, severity
mix, by-system, by-date) are computable from the header fields alone:
```
Grep pattern="\*\*(Severity|Priority|Status|System|Category|Reported)\*\*" glob="production/qa/bugs/*.md" output_mode="content"
```
(Bug-report fields are bolded — `**Severity**:`, `- **System**:` — so match the
`**field**` form, not a bare line-start `Field:`.)
Full bug bodies are needed only for the priority-vs-severity **re-evaluation** in
`sprint`/`full` modes; `trend` is a read-only report and skips it. (The one
deviation check that needs a story's status — "bug filed against a Complete
story" — is a targeted story-status grep either way, not a bug-body read.)

**在 `trend` 模式下，不要读取完整缺陷正文。** 趋势指标（数量、严重程度构成、按系统、按日期）仅凭头部字段即可计算：
```
Grep pattern="\*\*(Severity|Priority|Status|System|Category|Reported)\*\*" glob="production/qa/bugs/*.md" output_mode="content"
```
（缺陷报告字段为粗体——`**Severity**:`、`- **System**:`——因此匹配 `**field**` 形式，而不是行首的裸 `Field:`。）
完整缺陷正文仅在 `sprint`/`full` 模式下为优先级与严重程度的**重新评估**所需；`trend` 是只读报告，会跳过它。（唯一需要故事状态的偏差检查——“针对已完成故事提交的缺陷”——无论如何都是针对故事状态的定向 grep，而不是读取缺陷正文。）

### Step 2b — Load sprint context
### 步骤 2b——加载冲刺上下文

Read the most recently modified file in `production/sprints/` to understand:
- Current sprint number / name
- Stories in scope (for assignment target)
- Sprint capacity constraints (if noted)

读取 `production/sprints/` 中最近修改的文件，以了解：
- 当前冲刺编号 / 名称
- 范围内的故事（用于分配目标）
- 冲刺容量约束（如有说明）

If no sprint file exists: note "No sprint plan found — assigning to backlog only." At `workflow: minimal` there are no sprints by design — say that instead, and name the P1 bugs as the next fixes, ahead of the next story in the brief's build order.

如果不存在冲刺文件：注明“未找到冲刺计划——仅分配到待办。”在 `workflow: minimal` 下按设计没有冲刺——改为说明这一点，并将 P1 缺陷列为下一批修复，排在简报构建顺序中的下一个故事之前。

### Step 2c — Load severity reference
### 步骤 2c——加载严重程度参考

Read `.claude/docs/coding-standards.md` for severity/priority definitions if they
exist. If they do not exist, use the standard definitions in Step 3.

如果存在 `.claude/docs/coding-standards.md`，读取其中的严重程度/优先级定义。如果不存在，使用步骤 3 中的标准定义。

---

## 3. Classify Each Bug
## 3. 分类每个缺陷

For each bug, extract or infer:

对于每个缺陷，提取或推断：

### Severity (impact of the bug)
### 严重程度（缺陷的影响）

| Severity | Definition |
|----------|-----------|
| **S1 — Critical** | Game crashes, data loss, or complete feature failure. Cannot proceed past this point. |
| **S2 — High** | Major feature broken but game is still playable. Significant wrong behaviour. |
| **S3 — Medium** | Feature degraded but a workaround exists. Minor wrong behaviour. |
| **S4 — Low** | Visual glitch, cosmetic issue, typo. No gameplay impact. |

| 严重程度 | 定义 |
|----------|-----------|
| **S1 — 严重** | 游戏崩溃、数据丢失或功能完全失效。无法越过此点继续。 |
| **S2 — 高** | 主要功能损坏但游戏仍可游玩。显著错误行为。 |
| **S3 — 中** | 功能降级但存在变通方法。轻微错误行为。 |
| **S4 — 低** | 视觉故障、外观问题、错别字。无玩法影响。 |

### Priority (urgency of the fix)
### 优先级（修复的紧迫性）

| Priority | Definition |
|----------|-----------|
| **P1 — Fix this sprint** | Blocks QA, blocks release, or is regression from last sprint |
| **P2 — Fix soon** | Should be resolved before the next major milestone |
| **P3 — Backlog** | Would be good to fix, but no active blocking impact |
| **P4 — Won't fix / Deferred** | Accepted risk or out of scope for current product scope |

| 优先级 | 定义 |
|----------|-----------|
| **P1 — 本冲刺修复** | 阻塞 QA、阻塞发布，或是上一冲刺的回归 |
| **P2 — 尽快修复** | 应在下一个重大里程碑前解决 |
| **P3 — 待办** | 最好修复，但没有当前阻塞影响 |
| **P4 — 不修复 / 延后** | 已接受风险或超出当前产品范围 |

### Assignment
### 分配

For each P1/P2 bug in `sprint` mode:
- Identify which story or epic the fix belongs to
- Check whether the current sprint has remaining capacity
- If capacity exists: assign to sprint (`Sprint: [current]`)
- If capacity is full: flag as `Priority overflow — consider pulling from sprint`

对于 `sprint` 模式下的每个 P1/P2 缺陷：
- 确定修复属于哪个故事或史诗
- 检查当前冲刺是否有剩余容量
- 如果存在容量：分配到冲刺（`Sprint: [current]`）
- 如果容量已满：标记为 `Priority overflow — consider pulling from sprint`

For `full` mode: assign all P1 to current sprint, P2 to next sprint estimate,
P3+ to backlog.

对于 `full` 模式：将所有 P1 分配到当前冲刺，P2 分配到下一冲刺估算，P3+ 分配到待办。

### Deviation check
### 偏差检查

Flag bugs that suggest **systematic problems**:
- 3+ bugs from the same system in the same sprint → "Potential design or
  implementation quality issue in [system]"
- 2+ S1/S2 bugs in the same story → "Story may need to be reopened and
  re-reviewed before shipping"
- Bug filed against a story marked Complete → "Regression in completed story —
  story should be re-opened in sprint tracking"

标记暗示**系统性问题**的缺陷：
- 同一冲刺中同一系统出现 3+ 个缺陷 → “Potential design or implementation quality issue in [system]”
- 同一故事中 2+ 个 S1/S2 缺陷 → “Story may need to be reopened and re-reviewed before shipping”
- 针对标记为 Complete 的故事提交的缺陷 → “Regression in completed story — story should be re-opened in sprint tracking”

---

## 4. Trend Analysis
## 4. 趋势分析

After classifying all bugs, generate trend metrics:

在分类所有缺陷之后，生成趋势指标：

### Volume trends
- Total open bugs: [N]
- Opened this sprint: [N]
- Closed this sprint: [N]
- Net change: [+N / -N]

### 数量趋势
- 未关闭缺陷总数：[N]
- 本冲刺开启：[N]
- 本冲刺关闭：[N]
- 净变化：[+N / -N]

### System hot spots
- Which system has the most open bugs?
- Which system has the highest S1/S2 ratio?

### 系统热点
- 哪个系统的未关闭缺陷最多？
- 哪个系统的 S1/S2 比例最高？

### Age analysis
- How many bugs are older than 2 sprints?
- Are any S1/S2 bugs un-assigned (sprint = none)?

### 年龄分析
- 有多少缺陷超过 2 个冲刺？
- 是否有任何 S1/S2 缺陷未分配（sprint = none）？

### Regression indicator
- Any bugs filed against previously-completed stories?
- Count: [N] regression bugs (story reopened implied)

### 回归指标
- 是否有任何缺陷针对之前已完成的故事提交？
- 数量：[N] 个回归缺陷（暗示故事重新开启）

---

## 5. Generate Triage Report
## 5. 生成分类报告

```markdown
# Bug Triage Report

> **Date**: [date]
> **Mode**: [sprint | full | trend]
> **Generated by**: /bug-triage
> **Open bugs processed**: [N]
> **Sprint in scope**: [sprint name, or "N/A"]

---

## Triage Summary

| Priority | Count | Notes |
|----------|-------|-------|
| P1 — Fix this sprint | [N] | [N] assigned to sprint, [N] overflow |
| P2 — Fix soon | [N] | Scheduled for next sprint |
| P3 — Backlog | [N] | Deferred |
| P4 — Won't fix | [N] | Accepted risk |

**Critical (S1/S2) unfixed count**: [N]

---

## P1 Bugs — Fix This Sprint

| ID | System | Severity | Summary | Assigned to | Story |
|----|--------|----------|---------|-------------|-------|
| BUG-NNNN | [system] | S[1-4] | [one-line description] | [sprint] | [story path] |

---

## P2 Bugs — Fix Soon

| ID | System | Severity | Summary | Target Sprint |
|----|--------|----------|---------|---------------|
| BUG-NNNN | [system] | S[1-4] | [one-line description] | Sprint [N+1] |

---

## P3/P4 Bugs — Backlog / Won't Fix

| ID | System | Severity | Summary | Disposition |
|----|--------|----------|---------|-------------|
| BUG-NNNN | [system] | S4 | [one-line description] | Backlog |

---

## Systemic Issues Flagged

[List any patterns from Step 3 deviation check, or "None identified."]

---

## Trend Analysis

**Volume**: [N] open / [+N] net change this sprint
**Hot spot**: [system with most bugs]
**Regressions**: [N] bugs against completed stories
**Aged bugs (>2 sprints old)**: [N]

[If N aged S1/S2 bugs > 0:]
> ⚠️ [N] high-severity bugs have been open for more than 2 sprints without
> assignment. These represent accepted risk that should be explicitly reviewed.

---

## Recommended Actions

1. [Most urgent action — usually "fix P1 bugs before QA hand-off"]
2. [Second action — usually "investigate [hot spot system] quality"]
3. [Third action — optional improvement]
```

```markdown
# 缺陷分类报告

> **日期**：[date]
> **模式**：[sprint | full | trend]
> **生成者**：/bug-triage
> **处理的未关闭缺陷**：[N]
> **范围内的冲刺**：[sprint name, or "N/A"]

---

## 分类摘要

| 优先级 | 数量 | 备注 |
|----------|-------|-------|
| P1 — 本冲刺修复 | [N] | [N] 已分配到冲刺，[N] 溢出 |
| P2 — 尽快修复 | [N] | 计划在下一冲刺 |
| P3 — 待办 | [N] | 延后 |
| P4 — 不修复 | [N] | 已接受风险 |

**关键（S1/S2）未修复数量**：[N]

---

## P1 缺陷——本冲刺修复

| ID | 系统 | 严重程度 | 摘要 | 分配给 | 故事 |
|----|--------|----------|---------|-------------|-------|
| BUG-NNNN | [system] | S[1-4] | [one-line description] | [sprint] | [story path] |

---

## P2 缺陷——尽快修复

| ID | 系统 | 严重程度 | 摘要 | 目标冲刺 |
|----|--------|----------|---------|---------------|
| BUG-NNNN | [system] | S[1-4] | [one-line description] | Sprint [N+1] |

---

## P3/P4 缺陷——待办 / 不修复

| ID | 系统 | 严重程度 | 摘要 | 处置 |
|----|--------|----------|---------|-------------|
| BUG-NNNN | [system] | S4 | [one-line description] | Backlog |

---

## 标记的系统性问题

[列出步骤 3 偏差检查中的任何模式，或 "None identified."]

---

## 趋势分析

**数量**：[N] 未关闭 / 本冲刺净变化 [+N]
**热点**：[缺陷最多的系统]
**回归**：[N] 针对已完成故事的缺陷
**陈旧缺陷（超过 2 个冲刺）**：[N]

[如果 N 个陈旧 S1/S2 缺陷 > 0:]
> ⚠️ [N] 个高严重程度缺陷已超过 2 个冲刺仍未分配。这些代表应被明确评审的已接受风险。

---

## 建议行动

1. [最紧急行动——通常是“在 QA 交接前修复 P1 缺陷”]
2. [第二行动——通常是“调查 [hot spot system] 质量”]
3. [第三行动——可选改进]
```

---

## 6. Write and Gate
## 6. 写入与门禁

Present the report in conversation. If any bug is a P4 candidate, first ask
"Are these acceptable as Won't Fix?" and keep its disposition `P4 candidate`
until the user answers. Then ask:

在对话中展示报告。如果有任何缺陷是 P4 候选，先询问“这些作为 Won't Fix 可以接受吗？”并在用户回答前将其处置保持为 `P4 candidate`。然后询问：

"May I write this triage report to `production/qa/bug-triage-[date].md`?"

“我可以将此分类报告写入 `production/qa/bug-triage-[date].md` 吗？”

Write only after approval.

仅在批准后写入。

After writing:
- If any S1 bugs are unassigned: "S1 bugs must be assigned before the sprint
  can be considered healthy. Run `/sprint-status` to see current capacity."
- If regression bugs exist: "Regressions found — consider re-opening the
  affected stories in sprint tracking and running `/smoke-check` to re-gate."
- If no P1 bugs exist: "No P1 bugs — build is in good shape for QA hand-off."

写入后：
- 如果有任何 S1 缺陷未分配：“S1 缺陷必须在冲刺被视为健康之前分配。运行 `/sprint-status` 查看当前容量。”
- 如果存在回归缺陷：“发现回归——考虑在冲刺跟踪中重新开启受影响的故事，并运行 `/smoke-check` 重新设门禁。”
- 如果不存在 P1 缺陷：“无 P1 缺陷——构建状态良好，可交接 QA。”

Then, whether or not P1 bugs exist: Verdict: **COMPLETE** — triage report written.

然后，无论是否存在 P1 缺陷：结论：**COMPLETE**——分类报告已写入。

If user declined write: Verdict: **BLOCKED** — user declined write.

如果用户拒绝写入：结论：**BLOCKED**——用户拒绝写入。

---

## Collaborative Protocol
## 协作协议

- **Never close or mark bugs Won't Fix without user approval** — surface them
  as P4 candidates and ask: "Are these acceptable as Won't Fix?"
- **Never auto-assign to a sprint at capacity** — flag overflow and let the
  sprint owner decide what to pull
- **Severity is objective; priority is a team decision** — present severity
  classifications as recommendations, not mandates
- **Trend data is informational** — do not block work on trend findings alone;
  surface them as observations

- **未获用户批准，绝不关闭或将缺陷标记为 Won't Fix**——将其列为 P4 候选并询问：“这些作为 Won't Fix 可以接受吗？”
- **绝不自动分配到已满容量的冲刺**——标记溢出，让冲刺负责人决定拉取什么
- **严重程度是客观的；优先级是团队决策**——将严重程度分类作为建议而非强制
- **趋势数据仅供信息参考**——不要仅因趋势发现就阻塞工作；将其作为观察呈现
