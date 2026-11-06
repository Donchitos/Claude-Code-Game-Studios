# /review-all-gdds — Phase 5: Output the Review Report
# /review-all-gdds — 阶段 5：输出审查报告

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 5: Output the Review Report
## 阶段 5：输出审查报告

**In this file:**
**本文件内容：**

- The report template
- `NOT ASSESSED` and where it ranks

- 报告模板
- `NOT ASSESSED` 及其排序位置

```
## Cross-GDD Review Report
Date: [date]
GDDs Reviewed: [N] of [M] present
Not read: [each GDD that could not be read or is present but empty, by file name — or "none"]
Focus: [full / consistency only — design theory not run / design theory only — consistency not run]
Systems Covered: [list]

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)
🔴 [Issue title]
[What GDDs are involved, what the contradiction is, what needs to change]

#### Warnings (should resolve, but won't block)
⚠️  [Issue title]
[What GDDs are involved, what the concern is]

---

### Game Design Issues

#### Blocking
🔴 [Issue title]
[What the problem is, which GDDs are involved, design recommendation]

#### Warnings
⚠️  [Issue title]
[What the concern is, which GDDs are affected, recommendation]

---

### Cross-System Scenario Issues

Scenarios walked: [N]
[List scenario names]

#### Blockers
🔴 [Scenario name] — [Systems involved]
[Step where failure occurs, nature of the failure mode, what must be resolved]

#### Warnings
⚠️  [Scenario name] — [Systems involved]
[What the unintended outcome is, recommendation]

#### Info
ℹ️  [Scenario name] — [Systems involved]
[Minor ordering ambiguity or note]

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| [system-a].md | Rule contradiction with [system-b].md | Consistency | Blocking |
| [system-b].md | Rule contradiction with [system-a].md | Consistency | Blocking |
| [system-c].md | Stale reference to nonexistent mechanic | Consistency | Blocking |
| [system-d].md | No pillar alignment | Design Theory | Warning |

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: No blocking issues and no warnings.
NOT ASSESSED: One or more review phases could not run — named below.
CONCERNS: Warnings present that should be resolved, but nothing blocking.
FAIL: One or more blocking issues must be resolved before architecture begins.

### If NOT ASSESSED — what could not be reviewed, and why:
[Name each phase that did not run and the input it needed, and each GDD that could not be read or is present but empty, by file name]

### If FAIL — required actions before re-running:
[Specific list of what must change in which GDD]
```

```
## 跨 GDD 审查报告
日期：[date]
已审查 GDD：[N] / 存在的 [M]
未读取：[每个无法读取或存在但为空的 GDD，按文件名列出——或 “none”]
焦点：[full / 仅一致性——未运行设计理论 / 仅设计理论——未运行一致性]
覆盖的系统：[list]

---

### 一致性问题

#### 阻断级（必须在架构开始前解决）
🔴 [问题标题]
[涉及哪些 GDD、矛盾是什么、需要改动什么]

#### 警告级（应当解决，但不阻断）
⚠️  [问题标题]
[涉及哪些 GDD、顾虑是什么]

---

### 游戏设计问题

#### 阻断级
🔴 [问题标题]
[问题是什么、涉及哪些 GDD、设计建议]

#### 警告级
⚠️  [问题标题]
[顾虑是什么、影响哪些 GDD、建议]

---

### 跨系统场景问题

已走查场景数：[N]
[列出场景名称]

#### 阻断级
🔴 [场景名] —— [涉及的系统]
[失败发生的步骤、失效模式的性质、必须解决什么]

#### 警告级
⚠️  [场景名] —— [涉及的系统]
[非预期结果是什么、建议]

#### 信息级
ℹ️  [场景名] —— [涉及的系统]
[轻微的次序歧义或备注]

---

### 被标记需修订的 GDD

| GDD | 原因 | 类型 | 优先级 |
|-----|--------|------|----------|
| [system-a].md | 与 [system-b].md 存在规则矛盾 | Consistency | Blocking |
| [system-b].md | 与 [system-a].md 存在规则矛盾 | Consistency | Blocking |
| [system-c].md | 引用了不存在的机制（过期引用） | Consistency | Blocking |
| [system-d].md | 未与任何支柱对齐 | Design Theory | Warning |

---

### 判定：[PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS：没有阻断级问题，也没有警告。
NOT ASSESSED：一个或多个审查阶段未能运行——在下方点名。
CONCERNS：存在应当解决的警告，但没有任何阻断级问题。
FAIL：必须解决一个或多个阻断级问题，才能开始架构。

### 若为 NOT ASSESSED —— 哪些内容无法审查，以及原因：
[点名每个未运行的阶段及其所需输入，以及每个无法读取或存在但为空的 GDD，按文件名列出]

### 若为 FAIL —— 重新运行前必须完成的动作：
[具体列出哪个 GDD 中必须改动什么]
```

**`NOT ASSESSED` — a cross-review is only as wide as what it could read.** Rank:
**above PASS**, **below CONCERNS and FAIL**. This skill's whole value is
comparing systems *against each other*, so it is unusually easy for it to look
thorough while covering a fraction of the surface. Emit it when any of:

**`NOT ASSESSED` —— 跨审查的广度只能等于它能读取到的范围。** 排序：
**高于 PASS**，**低于 CONCERNS 和 FAIL**。本技能的全部价值在于
把系统*相互对照*，因此它特别容易看起来详尽，实际却只覆盖了一小部分表面。出现以下任一
情况时就给出该判定：

- **Fewer than two GDDs were readable.** Contradiction-hunting across one document
  is not a cross-review; a clean result there means only that nothing was
  compared. This is the single most important trigger in this skill.
- **A whole review phase did not run** — consistency, design theory, economy,
  pillar drift — when it should have. A pass the focus argument left out is not
  this trigger: the user asked for it. Give the verdict for the pass that ran,
  labelled — `PASS (consistency only — design theory not run)` — and fill the
  `Focus:` line. A parallel phase that returned nothing has to be distinguished
  from one that returned no findings; if a spawned agent produced no report, that
  phase is NOT ASSESSED, not clean — an agent can return a fluent sentence,
  write nothing, and consume a phase.
- **The design pillars are undefined**, so pillar-drift has no reference to drift
  from — the same shape as an accessibility gate with no committed tier.
- **A GDD is present but empty** (headings only, or all placeholders), **or
  could not be read**. Present is not the same as reviewable, and a stub
  contradicts nothing.

- **可读取的 GDD 少于两个。** 在单份文档内找矛盾
  不构成跨审查；那里得到干净结果只意味着什么都没有
  被比较过。这是本技能中最重要的单一触发条件。
- **整个审查阶段没有运行**——一致性、设计理论、经济、
  支柱漂移——而它本应运行。因 focus 参数而被有意省略的一轮
  不属于此触发条件：那是用户要求的。对实际运行的那一轮给出判定，
  并加标注——`PASS (consistency only — design theory not run)`——同时填写
  `Focus:` 行。一个返回空结果的并行阶段必须与一个
  没有发现任何问题的阶段区分开；如果被派生的智能体没有产出报告，
  该阶段就是 NOT ASSESSED，而不是干净——智能体可以返回一句流畅的话，
  什么都不写，却消耗掉一个阶段。
- **设计支柱未定义**，因此支柱漂移没有可偏离的基准
  ——这与没有承诺无障碍等级的无障碍关卡是同一种形态。
- **某个 GDD 存在但为空**（只有标题，或全是占位符），**或
  无法读取**。存在不等于可审查，而一个空骨架不会与任何东西
  矛盾。

Report the covered set explicitly either way: `GDDs reviewed: [N] of [M] present`
(`[M]` counts the system GDDs present — the Phase 1c set, not `game-concept.md`,
`game-pillars.md`, `systems-index.md` or an earlier `gdd-cross-review-*.md`),
and the `Not read:` line naming every GDD that could not be read or is present but empty, whatever the
verdict — a FAIL found in the GDDs that were read does not make the unread ones
reviewed.
A cross-review that silently skipped half the systems is indistinguishable from
one that found them consistent.

无论哪种情况，都要明确报告覆盖的集合：`GDDs reviewed: [N] of [M] present`
（`[M]` 统计的是实际存在的系统 GDD——即阶段 1c 的集合，不是 `game-concept.md`、
`game-pillars.md`、`systems-index.md` 或更早的 `gdd-cross-review-*.md`），
以及 `Not read:` 行，逐一列出每个无法读取或存在但为空的 GDD，无论
判定如何——在已读取的 GDD 中发现 FAIL，并不能让未读取的那些
变成已审查。
一份悄悄跳过一半系统的跨审查，与一份发现它们彼此一致的跨审查，
是无法区分的。

---
