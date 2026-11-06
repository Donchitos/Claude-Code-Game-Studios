---
name: quick-design
description: "Lightweight spec for small changes — tuning adjustments, minor mechanics. Embeds directly into stories; skips full GDD."
argument-hint: "[brief description of the change]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/quick-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: quick-design
description: "针对小改动的轻量规范 —— 调参调整、次要机制。直接嵌入故事；跳过完整 GDD。"
argument-hint: "[brief description of the change]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/quick-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

# Quick Design

# 快速设计

This is the **lightweight design path** for changes that don't need a full GDD.
Full GDD authoring via `/design-system` is the heavyweight path. Use this skill
for work under about one week of implementation — tuning adjustments, minor
behavioral tweaks, small additions to existing systems, or standalone features too
small to warrant a full document. Most tweaks are hours; the one-week ceiling is
the limit for a New Small System (see the categories below).

这是针对无需完整 GDD 的改动的**轻量设计路径**。
通过 `/design-system` 编写完整 GDD 是重量级路径。对于大约一周实现以内的工作使用本技能 ——
调参调整、次要行为微调、对现有系统的小幅新增，或因为太小而不值得一份完整文档的独立功能。
大多数微调只需数小时；一周的上限是"新小型系统"的界限（见下面的类别）。

**Output:** `design/quick-specs/[name]-[date].md`

**输出：** `design/quick-specs/[name]-[date].md`

**When to run:** Anytime a change is too small for `/design-system` but too
meaningful to implement without a written rationale.

**何时运行：** 当某项改动小到不必用 `/design-system`，但又重要到没有文字理由就无法实现时。

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类别始终会询问）。

## 1. Classify the Change

## 1. 对改动分类

First, read the argument and determine which category this change falls into:

首先，读取参数并判断该改动属于哪个类别：

- **Tuning** — changing numbers or balance values in an existing system with no
  behavioral change (most minimal path). Example: "increase jump height from 5
  to 6 units", "reduce enemy patrol speed by 10%".
- **Tweak** — a small behavioral change to an existing system that introduces no
  new states, branches, or systems. Example: "make dash invincible on frame 1",
  "allow combo to cancel into roll".
- **Addition** — adding a small mechanic to an existing system that may introduce
  1-2 new states or interactions. Example: "add a parry window to the block
  mechanic", "add a charge variant to the basic attack".
- **New Small System** — a standalone feature small enough that it has no
  existing GDD and is under approximately one week of implementation work.
  Example: "achievement popup system", "simple day/night visual cycle".

- **调参（Tuning）** —— 在现有系统中更改数字或平衡值，没有行为变化（最轻量的路径）。示例："把跳跃高度从 5 单位提高到 6 单位"、"把敌人巡逻速度降低 10%"。
- **微调（Tweak）** —— 对现有系统的小幅行为改动，不引入新状态、分支或系统。示例："让冲刺在第 1 帧无敌"、"允许连招取消进入翻滚"。
- **新增（Addition）** —— 向现有系统添加一个小型机制，可能引入 1-2 个新状态或交互。示例："为格挡机制添加招架窗口"、"为普通攻击添加蓄力变体"。
- **新小型系统（New Small System）** —— 一个足够小的独立功能，没有现成 GDD，且实现工作量约在一周以内。示例："成就弹窗系统"、"简单的昼夜视觉循环"。

If the change does NOT fit these categories — it introduces a new system with
significant cross-system dependencies, requires more than one week of
implementation, or fundamentally alters an existing system's core rules — stop
and redirect to `/design-system` instead. Verdict: **REDIRECTED** — use
`/design-system` for this change.

如果该改动**不符合**这些类别 —— 它引入一个具有显著跨系统依赖的新系统、
需要超过一周的实现，或从根本上改变某个现有系统的核心规则 —— 停止并改为重定向到
`/design-system`。结论：**REDIRECTED** —— 对此改动使用 `/design-system`。

If there is no argument, ask the user to describe the change (plain text prompt), then classify it using the criteria above.

如果没有参数，请用户描述该改动（纯文本提示），然后用上面的标准对其进行分类。

Present the inferred classification using `AskUserQuestion`:
- Prompt: "I've classified this as **[inferred type]** — [brief reason]. Is that correct?"
- Options:
  - `[A] Yes — [inferred type] is correct`
  - `[B] Tuning — changing numbers or balance values only`
  - `[C] Tweak — small behavioral change to an existing system`
  - `[D] Addition — adding a small mechanic to an existing system`
  - `[E] New Small System — standalone feature, under one week of work`
  - `[F] This is too large — redirect me to /design-system`

使用 `AskUserQuestion` 呈现推断出的分类：
- 提示："我把它归类为 **[inferred type]** —— [简短原因]。这样对吗？"
- 选项：
  - `[A] 是 —— [inferred type] 正确`
  - `[B] 调参 —— 仅更改数字或平衡值`
  - `[C] 微调 —— 对现有系统的小幅行为改动`
  - `[D] 新增 —— 向现有系统添加一个小型机制`
  - `[E] 新小型系统 —— 独立功能，工作量在一周以内`
  - `[F] 这太大了 —— 把我重定向到 /design-system`

If [F]: stop. Verdict: **REDIRECTED** — use `/design-system` for this change.
Otherwise: proceed with the selected type.

如果选 [F]：停止。结论：**REDIRECTED** —— 对此改动使用 `/design-system`。
否则：按所选的类型继续。

---

## 2. Context Scan

## 2. 上下文扫描

Before drafting anything, read the relevant context. Read the GDD and the systems
index by section: find the headings you need with the Grep tool (pattern `^#`,
content mode) and Read those ranges with offset and limit.

在起草任何内容之前，先读取相关上下文。按小节读取 GDD 和系统索引：
用 Grep 工具（模式 `^#`，内容模式）找到需要的标题，然后用 offset 和 limit 读取相应范围。

- Search `design/gdd/` for the GDD most relevant to this change. Read the
  sections that this change would affect. If no GDD covers this system — usually
  the case at `workflow: minimal`, where `design/game-brief.md` and the stories are
  the design record — read the brief's lines for it and the story the change
  touches instead, report "No GDD for [system] — using the brief and [story
  path]", and give the brief as the spec's GDD Reference.
- Check whether `design/gdd/systems-index.md` exists. If it does, read it to
  understand where this system sits in the dependency graph and what tier it
  belongs to. If it does not exist, note "No systems index found — skipping
  dependency tier check." and continue.
- Check `design/quick-specs/` for any prior quick specs that touched this
  system — avoid contradicting them.
- If this is a Tuning change, also check `assets/data/` for the data file that
  holds the relevant values.

- 在 `design/gdd/` 中搜索与该改动最相关的 GDD。读取该改动会影响的小节。
  如果没有 GDD 覆盖该系统 —— 在 `workflow: minimal` 下通常是这种情况，此时
  `design/game-brief.md` 和故事就是设计记录 —— 改为读取简报中相关的内容以及该改动涉及的
  故事，报告"没有 [system] 的 GDD —— 使用简报和 [story path]"，并把简报作为该规范的 GDD 参考。
- 检查 `design/gdd/systems-index.md` 是否存在。如果存在，读取它以了解
  该系统在依赖图中的位置以及它属于哪一层级。如果不存在，注明"未找到系统索引 —— 跳过
  依赖层级检查。"并继续。
- 检查 `design/quick-specs/` 中是否有任何此前涉及该系统的快速规范 —— 避免与它们矛盾。
- 如果这是一项调参改动，还要检查 `assets/data/` 中保存相关数值的数据文件。

Report what was found: "Found GDD at [path]. Relevant section: [section name].
Prior quick specs for this system: [each path, and whether it agrees or
conflicts with this change — or "none"]." Name a prior spec even when it
agrees — "no conflicts" alone reads the same as "no prior specs".

报告所发现的内容："在 [path] 找到 GDD。相关小节：[section name]。
此系统此前的快速规范：[每个路径，以及它是与该改动一致还是冲突 —— 或 "none"]。"
即使此前的规范一致也要点名 —— 只写"无冲突"读起来与"没有此前的规范"一样。

---

## 3. Draft the Quick Design Spec

## 3. 起草快速设计规范

Use the appropriate spec format for the change category.

根据改动类别使用相应的规范格式。

### For Tuning changes

### 针对调参改动

Produce a single table:

生成一张表：

```markdown
# Quick Design Spec: [Title]

**Type**: Tuning
**System**: [System name]
**GDD Reference**: `design/gdd/[filename].md` — Tuning Knobs section
**Date**: [today]

## Change

| Parameter | Old Value | New Value | Rationale |
|-----------|-----------|-----------|-----------|
| [param]   | [old]     | [new]     | [why]     |

## Tuning Knob Mapping

Maps to GDD Tuning Knob: [knob name and its documented range].
New value is [within / at the edge of / outside] the documented range.
[If outside: explain why the range should be extended.]

## Acceptance Criteria

- [ ] [Parameter] reads [new value] from `assets/data/[file]`
- [ ] Behavior difference is observable in [specific context]
- [ ] No regression in [related behavior]
```

```markdown
# 快速设计规范：[Title]

**Type**：Tuning
**系统**：[System name]
**GDD 参考**：`design/gdd/[filename].md` —— Tuning Knobs 小节
**日期**：[today]

## 变更

| 参数 | 旧值 | 新值 | 理由 |
|-----------|-----------|-----------|-----------|
| [param]   | [old]     | [new]     | [why]     |

## 调参旋钮映射

对应 GDD 中的调参旋钮：[knob name and its documented range]。
新值 [within / at the edge of / outside] 文档中记录的范围。
[若超出：解释为什么应扩展该范围。]

## 验收标准

- [ ] [Parameter] 从 `assets/data/[file]` 读取到 [new value]
- [ ] 行为差异在 [specific context] 中可观察到
- [ ] [related behavior] 无回归
```

### For Tweak and Addition changes

### 针对微调和新增改动

```markdown
# Quick Design Spec: [Title]

**Type**: [Tweak / Addition]
**System**: [System name]
**GDD Reference**: `design/gdd/[filename].md`
**Date**: [today]

## Change Summary

[1-2 sentences describing what changes and why.]

## Motivation

[Why is this change needed? What player experience problem does it solve?
Reference the relevant MDA aesthetic or player feedback if applicable.]

## Design Delta

Current GDD says (quoting `design/gdd/[filename].md`, [section]):

> [exact quote of the relevant rule or description]

This spec changes that to:

[New rule or description, written with the same precision as a GDD Detailed
Rules section. A programmer should be able to implement from this text alone.]

## New Rules / Values

[Full unambiguous statement of the replacement content. If this introduces
new states, list them. If it introduces new parameters, define their ranges.]

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| [system] | [how it is affected] | [update GDD / update data file / no action] |

## Acceptance Criteria

- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]
- [ ] No regression: [the original behavior this must not break]

## GDD Update Required?

[Yes / No]
[If yes: which file, which section, and what the update should say.]
```

```markdown
# 快速设计规范：[Title]

**Type**：[Tweak / Addition]
**系统**：[System name]
**GDD 参考**：`design/gdd/[filename].md`
**日期**：[today]

## 变更摘要

[用 1-2 句话描述改了什么以及为什么。]

## 动机

[为什么需要这项改动？它解决了什么玩家体验问题？
如适用，引用相关的 MDA 美学或玩家反馈。]

## 设计增量

当前 GDD 写道（引用 `design/gdd/[filename].md`，[section]）：

> [相关规则或描述的准确原文]

本规范将其改为：

[新规则或描述，以与 GDD 详细规则小节相同的精确度撰写。
程序员应能仅凭这段文字就完成实现。]

## 新规则 / 数值

[对替换内容的完整、无歧义的陈述。如果这引入了
新状态，请列出它们。如果它引入了新参数，请定义其范围。]

## 受影响的系统

| 系统 | 影响 | 所需行动 |
|--------|--------|-----------------|
| [system] | [how it is affected] | [update GDD / update data file / no action] |

## 验收标准

- [ ] [具体、可测试的标准 1]
- [ ] [具体、可测试的标准 2]
- [ ] [具体、可测试的标准 3]
- [ ] 无回归：[此改动不得破坏的原有行为]

## 是否需要更新 GDD？

[Yes / No]
[若是：哪个文件、哪个小节，以及更新应写什么。]
```

### For New Small System changes

### 针对新小型系统改动

Use a trimmed GDD structure. Include only the sections that are directly
necessary — skip Player Fantasy, full Formulas, and Edge Cases unless the
system specifically requires them.

使用精简的 GDD 结构。只包含直接必要的小节 —— 跳过玩家幻想、完整公式和
边界情况，除非该系统特别需要它们。

```markdown
# Quick Design Spec: [Title]

**Type**: New Small System
**Scope**: [1-2 sentence description of what this system does and doesn't do]
**Date**: [today]
**Estimated Implementation**: [hours]

## Overview

[One paragraph a new team member could understand. What does this system do,
when does it activate, and what does it produce?]

## Core Rules

[Unambiguous rules for the system. Use numbered lists for sequential behavior
and bullet lists for conditions. Be precise enough that a programmer can
implement without asking questions.]

## Tuning Knobs

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| [name] | [value] | [min–max] | [feel/curve/gate] | [why this default] |

All values must live in `assets/data/[appropriate-file].json`, not hardcoded.

## Acceptance Criteria

- [ ] [Functional criterion: does the right thing]
- [ ] [Functional criterion: handles the edge case]
- [ ] [Experiential criterion: feels right — what a playtest validates]
- [ ] [Regression criterion: does not break adjacent system]

## Systems Index

This system is not currently in `design/gdd/systems-index.md`.
[If it should be added: suggest which layer and priority tier.]
[If it is too small to track: state "This system is below systems-index
tracking threshold — quick spec is sufficient."]
```

```markdown
# 快速设计规范：[Title]

**Type**：New Small System
**范围**：[用 1-2 句话描述该做什么、不做什么]
**日期**：[today]
**预估实现工作量**：[hours]

## 概述

[一段新团队成员能理解的文字。该系统做什么，
何时激活，以及产出什么？]

## 核心规则

[该系统无歧义的规则。对顺序行为使用有序列表，
对条件使用无序列表。精确到程序员可以
不问问题就完成实现。]

## 调参旋钮

| 旋钮 | 默认值 | 范围 | 类别 | 理由 |
|------|---------|-------|----------|-----------|
| [name] | [value] | [min–max] | [feel/curve/gate] | [why this default] |

所有数值必须位于 `assets/data/[appropriate-file].json`，不得硬编码。

## 验收标准

- [ ] [功能标准：做正确的事]
- [ ] [功能标准：处理边界情况]
- [ ] [体验标准：感觉正确 —— 由试玩验证的内容]
- [ ] [回归标准：不破坏相邻系统]

## 系统索引

该系统当前不在 `design/gdd/systems-index.md` 中。
[如果应添加：建议属哪一层以及哪个优先级层级。]
[如果太小不值得跟踪：说明"该系统低于 systems-index 跟踪阈值 —— 快速规范已足够。"]
```

---

## 4. Approval and Filing

## 4. 批准与归档

Present the draft to the user in full. Then use `AskUserQuestion`:
- Prompt: "Here's the Quick Design Spec draft. How do you want to proceed?"
- Options:
  - `[A] Approve — write it as shown`
  - `[B] Revise — I'll describe what to change`
  - `[C] This grew too large — redirect to /design-system instead`

向用户完整呈现草稿。然后使用 `AskUserQuestion`：
- 提示："这是快速设计规范草稿。你希望如何继续？"
- 选项：
  - `[A] 批准 —— 按所示写入`
  - `[B] 修订 —— 我会描述要改什么`
  - `[C] 这变得太大了 —— 改为重定向到 /design-system`

If [B]: collect the requested changes, revise the draft, and re-present this widget.
If [C]: stop. Verdict: **REDIRECTED** — use `/design-system` for this change.

如果选 [B]：收集所要求的修改，修订草稿，并重新呈现此控件。
如果选 [C]：停止。结论：**REDIRECTED** —— 对此改动使用 `/design-system`。

If [A]: ask "May I write this Quick Design Spec to
`design/quick-specs/[kebab-case-title]-[YYYY-MM-DD].md`?"

如果选 [A]：询问"我可以把这份快速设计规范写入
`design/quick-specs/[kebab-case-title]-[YYYY-MM-DD].md` 吗？"

Use today's date in the filename. The title should be a kebab-case description
of the change (e.g., `jump-height-tuning-2026-03-10`,
`parry-window-addition-2026-03-10`).

在文件名中使用今天的日期。标题应是该改动的 kebab-case 描述
（例如 `jump-height-tuning-2026-03-10`、
`parry-window-addition-2026-03-10`）。

If yes, create the `design/quick-specs/` directory if it does not exist, then
write the file.

如果同意，若 `design/quick-specs/` 目录不存在则创建它，然后写入文件。

If a GDD update is required (flagged in the spec), ask separately after
writing the quick spec:

如果需要进行 GDD 更新（已在规范中标记），在写入快速规范之后单独询问：

"This spec modifies rules in [System Name]. May I update
`design/gdd/[filename].md` — specifically the [section name] section?"

"该规范修改了 [System Name] 中的规则。我可以更新
`design/gdd/[filename].md` —— 具体是 [section name] 小节吗？"

Show the exact text that would be changed (old vs. new) before asking. Do not
make GDD edits without explicit approval.

在询问之前展示将要更改的确切文本（旧 vs. 新）。未经明确批准，
不要进行 GDD 编辑。

---

## 5. Handoff

## 5. 交接

After writing the file, output:

写入文件之后，输出：

```
Quick Design Spec written to: design/quick-specs/[filename].md
Type: [Tuning / Tweak / Addition / New Small System]
System: [system name]
GDD update: [Required — pending approval / Applied / Not required]

Next step: This spec is ready for `/story-readiness` validation before
implementation (at `workflow: minimal`, go straight to `/dev-story`). Reference this spec in the story's GDD Reference field.
```

```
Quick Design Spec written to: design/quick-specs/[filename].md
Type: [Tuning / Tweak / Addition / New Small System]
System: [system name]
GDD update: [Required — pending approval / Applied / Not required]

Next step: This spec is ready for `/story-readiness` validation before
implementation (at `workflow: minimal`, go straight to `/dev-story`). Reference this spec in the story's GDD Reference field.
```

```
快速设计规范已写入：design/quick-specs/[filename].md
Type：[Tuning / Tweak / Addition / New Small System]
系统：[system name]
GDD 更新：[Required —— 等待批准 / Applied / Not required]

后续步骤：本规范已可交由 `/story-readiness` 在实现前进行校验
（在 `workflow: minimal` 下，直接进入 `/dev-story`）。在故事的 GDD Reference 字段中引用本规范。
```

### Pipeline Notes

### 流水线说明

Verdict: **COMPLETE** — quick design spec written and ready for implementation.

结论：**COMPLETE** —— 快速设计规范已写入并就绪，可以进入实现。

Quick Design Specs **bypass** `/design-review` and `/review-all-gdds` by
design. They are for small, low-risk, well-scoped changes where the cost of
the full review pipeline exceeds the risk of the change itself.

快速设计规范按设计**绕过** `/design-review` 和 `/review-all-gdds`。
它们适用于小型、低风险、范围明确的改动，对这些改动而言完整评审流水线的成本
超过改动本身的风险。

Redirect to the full pipeline if any of the following are true:
- The change adds a new system that belongs in the systems index
- The change significantly alters cross-system behavior or a system's
  contracts with other systems
- The change introduces new player-facing mechanics that affect the
  game's MDA aesthetic balance
- Implementation is likely to exceed one week of work

如果以下任一情况为真，重定向到完整流水线：
- 该改动添加了一个应归入系统索引的新系统
- 该改动显著改变了跨系统行为，或某个系统与其他系统之间的契约
- 该改动引入了影响游戏 MDA 美学平衡的新的面向玩家的机制
- 实现很可能超过一周的工作量

In those cases: "This change has grown beyond quick-spec scope. I recommend
using `/design-system` to author a full GDD for this."

在这些情况下："该改动已超出快速规范的范围。我建议
使用 `/design-system` 为它编写一份完整 GDD。"

---

## Recommended Next Steps

## 推荐的后续步骤

- Run `/story-readiness [story-path]` to validate the story before implementation begins (skip at `rigor: minimal` — `/dev-story` directly) — reference this spec in the story's GDD Reference field
- Run `/dev-story [story-path]` to implement once the story passes readiness checks
- If the change is larger than expected, run `/design-system [system-name]` to author a full GDD instead

- 运行 `/story-readiness [story-path]` 在实现开始前校验故事（在 `rigor: minimal` 下跳过 —— 直接 `/dev-story`）—— 在故事的 GDD Reference 字段中引用本规范
- 一旦故事通过就绪检查，运行 `/dev-story [story-path]` 进行实现
- 如果改动比预期更大，改为运行 `/design-system [system-name]` 编写完整 GDD
