---
name: scope-check
description: "Scope creep check — current scope versus the original plan. Flags additions, quantifies bloat, recommends cuts. 'Any scope creep?'"
argument-hint: "[feature-name or sprint-N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *)
model: haiku
---

---
name: scope-check
description: "范围蔓延检查 —— 当前范围与原始计划对比。标记新增项、量化膨胀程度、建议削减内容。'有范围蔓延吗？'"
argument-hint: "[feature-name or sprint-N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *)
model: haiku
---

# Scope Check

# 范围检查

This skill is read-only — it reports findings but writes no files.

本技能是只读的 —— 它报告发现的问题，但不写入任何文件。

Compares original planned scope against current state to detect, quantify, and triage
scope creep.

将原始计划范围与当前状态进行对比，以检测、量化并分诊范围蔓延。

**Argument:** `$ARGUMENTS` — the whole string: a feature name (it may be several words), sprint number, or milestone name.

**参数：** `$ARGUMENTS` —— 整个字符串：功能名称（可以包含多个词）、冲刺编号或里程碑名称。

---

## Phase 1: Find the Original Plan

## 阶段 1：找到原始计划

Locate the baseline scope document for the given argument:

为给定参数定位基线范围文档：

- **Feature name** → read `design/gdd/[feature].md` or matching file in `design/`
- **Sprint number** (e.g., `sprint-3`) → read `production/sprints/sprint-003.md` (the name `/sprint-plan` writes) or similar
- **Milestone** → read `production/milestones/[name].md`

- **功能名称** → 读取 `design/gdd/[feature].md` 或 `design/` 中的匹配文件
- **冲刺编号**（例如 `sprint-3`）→ 读取 `production/sprints/sprint-003.md`（即 `/sprint-plan` 写入的名称）或类似文件
- **里程碑** → 读取 `production/milestones/[name].md`

If the document is not found, report the missing file and stop. Do not proceed without
a baseline to compare against. Read a GDD by section: find the headings you need with
the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and
limit.

如果未找到文档，请报告缺失的文件并停止。没有可对照的基线时不要继续。按小节读取 GDD：使用 Grep 工具（模式 `^#`，内容模式）找到需要的标题，然后用 offset 和 limit 读取相应范围。

---

## Phase 2: Read the Current State

## 阶段 2：读取当前状态

Check what has actually been implemented or is in progress:

检查实际已实现或正在进行的内容：

- Scan the codebase for files related to the feature/sprint
- Read git log for commits related to this work (`git log --oneline --since=[start-date]`)
- Check for TODO/FIXME comments that indicate unfinished scope additions
- Check active sprint plan if the feature is mid-sprint

- 扫描代码库中与该功能/冲刺相关的文件
- 读取与该工作相关的提交记录（`git log --oneline --since=[start-date]`）
- 检查 TODO/FIXME 注释，它们表示尚未完成的范围新增项
- 如果该功能正处于冲刺中期，检查进行中的冲刺计划

---

## Phase 3: Compare Original vs Current Scope

## 阶段 3：对比原始范围与当前范围

Produce the comparison report:

生成对比报告：

```markdown
## Scope Check: [Feature/Sprint Name]
Generated: [Date]

### Original Scope
[List of items from the original plan]

### Current Scope
[List of items currently implemented or in progress]

> **If Phase 4 will return NOT ASSESSED, do not render the numeric block below.**
> Replace the counts and the Bloat Score with
> `[Baseline | Current state] unusable — see verdict` (whichever side could not
> be read) and give the reason. A rendered
> `Original items: 0 / Net scope change: 0%` one section above a NOT ASSESSED
> verdict re-creates the exact "0% reads as on track" hazard Phase 4 exists to
> kill, one phase earlier — and readers trust a number over a caveat.

### Scope Additions (not in original plan)
| Addition | Source | When | Justified? | Effort |
|----------|--------|------|------------|--------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] |

### Scope Removals (in original but dropped)
| Removed Item | Reason | Impact |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### Bloat Score
- Original items: [N]
- Current items: [N]
- Items added: [N] (+[X]%)
- Items removed: [N]
- Net scope change: [+/-N] ([X]%)

### Risk Assessment
- **Schedule Risk**: [Low/Medium/High] — [explanation]
- **Quality Risk**: [Low/Medium/High] — [explanation]
- **Integration Risk**: [Low/Medium/High] — [explanation]

### Recommendations
1. **Cut**: [Items that should be removed to stay on schedule]
2. **Defer**: [Items that can move to a future sprint/version]
3. **Keep**: [Additions that are genuinely necessary]
4. **Flag**: [Items that need a decision from producer/creative-director]
```

```markdown
## Scope Check: [Feature/Sprint Name]
Generated: [Date]

### Original Scope
[List of items from the original plan]

### Current Scope
[List of items currently implemented or in progress]

> **If Phase 4 will return NOT ASSESSED, do not render the numeric block below.**
> Replace the counts and the Bloat Score with
> `[Baseline | Current state] unusable — see verdict` (whichever side could not
> be read) and give the reason. A rendered
> `Original items: 0 / Net scope change: 0%` one section above a NOT ASSESSED
> verdict re-creates the exact "0% reads as on track" hazard Phase 4 exists to
> kill, one phase earlier — and readers trust a number over a caveat.

### Scope Additions (not in original plan)
| Addition | Source | When | Justified? | Effort |
|----------|--------|------|------------|--------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] |

### Scope Removals (in original but dropped)
| Removed Item | Reason | Impact |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### Bloat Score
- Original items: [N]
- Current items: [N]
- Items added: [N] (+[X]%)
- Items removed: [N]
- Net scope change: [+/-N] ([X]%)

### Risk Assessment
- **Schedule Risk**: [Low/Medium/High] — [explanation]
- **Quality Risk**: [Low/Medium/High] — [explanation]
- **Integration Risk**: [Low/Medium/High] — [explanation]

### Recommendations
1. **Cut**: [Items that should be removed to stay on schedule]
2. **Defer**: [Items that can move to a future sprint/version]
3. **Keep**: [Additions that are genuinely necessary]
4. **Flag**: [Items that need a decision from producer/creative-director]
```

```markdown
## 范围检查：[Feature/Sprint Name]
生成时间：[Date]

### 原始范围
[原始计划中的条目清单]

### 当前范围
[当前已实现或进行中的条目清单]

> **如果阶段 4 将返回 NOT ASSESSED，则不要渲染下面的数值块。**
> 把计数和膨胀评分替换为
> `[Baseline | Current state] unusable — see verdict`（以无法读取的那一侧为准）
> 并给出原因。在 NOT ASSESSED 结论上方渲染
> `Original items: 0 / Net scope change: 0%`，会提前一个阶段重演阶段 4 旨在
> 消除的那种"0% 读起来像进度正常"的风险 —— 而读者往往相信数字胜过警告。

### 范围新增（不在原始计划中）
| 新增项 | 来源 | 时间 | 是否合理？ | 工作量 |
|----------|--------|------|------------|--------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] |

### 范围移除（原计划中有但被放弃）
| 移除项 | 原因 | 影响 |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### 膨胀评分
- 原始条目数：[N]
- 当前条目数：[N]
- 新增条目数：[N]（+[X]%）
- 移除条目数：[N]
- 净范围变化：[+/-N]（[X]%）

### 风险评估
- **进度风险**：[Low/Medium/High] —— [explanation]
- **质量风险**：[Low/Medium/High] —— [explanation]
- **集成风险**：[Low/Medium/High] —— [explanation]

### 建议
1. **削减**：[为保持进度而应移除的条目]
2. **推迟**：[可移至未来冲刺/版本的条目]
3. **保留**：[确实必要的新增项]
4. **标记**：[需要制作人/创意总监决策的条目]
```

---

## Phase 4: Verdict

## 阶段 4：结论

Assign a canonical verdict based on net scope change:

根据净范围变化给出规范结论：

| Net Change | Verdict | Meaning |
|-----------|---------|---------|
| ≤10% | **PASS** | On Track — within acceptable variance |
| >10–25% | **CONCERNS** | Minor Creep — manageable with targeted cuts |
| >25–50% | **FAIL** | Significant Creep — must cut or formally extend timeline |
| >50% | **FAIL** | Out of Control — stop, re-plan, escalate to producer |

| 净变化 | 结论 | 含义 |
|-----------|---------|---------|
| ≤10% | **PASS** | 进度正常 —— 在可接受的变化范围内 |
| >10–25% | **CONCERNS** | 轻微蔓延 —— 通过有针对性的削减即可控制 |
| >25–50% | **FAIL** | 显著蔓延 —— 必须削减或正式延长时间线 |
| >50% | **FAIL** | 失控 —— 停止、重新规划、上报给制作人 |

**Before applying that table, check that the percentage means something.** Emit
**NOT ASSESSED** instead — never a computed percentage — when any of:

**在应用该表格之前，先确认这个百分比是否有意义。** 当出现以下任一情况时，应改为输出 **NOT ASSESSED** —— 而不是计算出的百分比：

- The **baseline document exists but enumerates no scope items** (all headings,
  placeholders, or `[TO BE CONFIGURED]`). Phase 1 stops when the file is *absent*;
  this is the case where it is present and empty, and it is the more dangerous
  one, because zero items yields a 0% net change that renders as **PASS — On
  Track**. Nothing was compared. Nothing was on track.
- The **current state cannot be determined** — no related source files, no commits
  in the window, nothing in progress to read. Comparing a real baseline against an
  unreadable present is not a 0% change, and not the −100% that zero current
  items computes — the table reads both as PASS.
- The denominator would be zero for any other reason. A percentage computed from
  no baseline items is not a small number; it is not a number.

- **基线文档存在但未列举任何范围条目**（全是标题、占位符或 `[TO BE CONFIGURED]`）。阶段 1 在文件*缺失*时就会停止；而这里是文件存在却为空，这是更危险的情况，因为零条目会得出 0% 的净变化，被渲染成 **PASS —— On Track**。实际上什么都没比较，也什么都不在正轨上。
- **无法确定当前状态** —— 没有相关源文件、窗口期内没有提交、没有正在进行可供读取的内容。将真实基线与无法读取的现状做对比，不是 0% 的变化，也不是零个当前条目计算出的 −100% —— 表格会把两者都读成 PASS。
- 分母因任何其他原因为零。用没有基线条目算出的百分比，不是一个很小的数字；它根本不是一个数字。

`NOT ASSESSED` **outranks PASS** (a comparison that never happened has not shown
scope is on track) and **ranks below CONCERNS and FAIL** (measured creep is more
actionable than an unmeasurable baseline).

`NOT ASSESSED` **优先于 PASS**（从未发生过的对比不能证明范围在正轨上），且**低于 CONCERNS 和 FAIL**（已测量的蔓延比无法测量的基线更具可操作性）。

Output the verdict prominently:

醒目的输出结论：

```
**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**
Net change: [+X%] — [On Track / Minor Creep / Significant Creep / Out of Control]
           [or: NOT ASSESSED — [which side could not be read, and why]]
```

```
**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**
Net change: [+X%] — [On Track / Minor Creep / Significant Creep / Out of Control]
           [or: NOT ASSESSED — [which side could not be read, and why]]
```

```
**范围结论：[PASS / CONCERNS / NOT ASSESSED / FAIL]**
净变化：[+X%] —— [进度正常 / 轻微蔓延 / 显著蔓延 / 失控]
           [或：NOT ASSESSED —— [哪一侧无法读取，以及原因]]
```

---

## Phase 5: Next Steps

## 阶段 5：后续步骤

After presenting the report, offer concrete follow-up:

在呈现报告之后，提供具体的后续建议：

- **PASS** → no action required. Suggest re-running before next milestone.
- **NOT ASSESSED** → say which side was unreadable and what would fix it (populate
  the baseline document, or point the skill at where the work actually lives).
  Do not offer a re-run against the same inputs — it will produce the same
  non-answer.
- **CONCERNS** → offer to identify the 2–3 additions with best cut ratio. Reference `/sprint-plan update` to formally re-scope (if the project has no sprint plan, as on the default minimal workflow, re-scope by editing the brief's build order).
- **FAIL** → recommend escalating to producer. Reference `/sprint-plan update` for re-planning (if the project has no sprint plan, as on the default minimal workflow, edit the brief's build order) or `/estimate` to re-baseline timeline.

- **PASS** → 无需采取行动。建议在下一个里程碑之前重新运行。
- **NOT ASSESSED** → 说明哪一侧无法读取，以及如何修复（补齐基线文档，或将技能指向工作实际所在的位置）。不要提议用相同的输入重跑 —— 那只会得到相同的非答案。
- **CONCERNS** → 提议找出削减性价比最高的 2–3 个新增项。引用 `/sprint-plan update` 进行正式重新定范围（如果项目没有冲刺计划，如默认的 minimal 工作流那样，则通过编辑简报中的构建顺序来重新定范围）。
- **FAIL** → 建议上报给制作人。引用 `/sprint-plan update` 重新规划（如果项目没有冲刺计划，如默认的 minimal 工作流那样，则编辑简报中的构建顺序），或引用 `/estimate` 重新建立时间线基线。

End every verdict except NOT ASSESSED with:
> "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

除 NOT ASSESSED 之外，每个结论都以这句话结尾：
> "在做出削减之后再次运行 `/scope-check [name]`，以验证结论有所改善。"

(NOT ASSESSED ends with what would make it assessable, above — a re-run against
the same inputs would repeat the non-answer.)

（NOT ASSESSED 以上文所述"如何使其可评估"作为结尾 —— 用相同输入重跑只会重复这个非答案。）

---

### Rules

### 规则

- Scope creep is additions without corresponding cuts or timeline extensions
- Not all additions are bad — some are discovered requirements. But they must be acknowledged and accounted for
- When recommending cuts, prioritize preserving the core player experience over nice-to-haves
- Always quantify scope changes — "it feels bigger" is not actionable, "+35% items" is

- 范围蔓延指的是没有相应削减或时间线延长的范围新增
- 并非所有新增项都是坏的 —— 有些是发现的需求。但它们必须被承认并纳入考量
- 在建议削减时，优先保留核心玩家体验，而非锦上添花的功能
- 始终量化范围变化 —— "感觉变大了"无法采取行动，"+35% 条目"则可以
