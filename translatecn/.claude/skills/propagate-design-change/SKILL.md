---
name: propagate-design-change
description: "Finds architecture decisions (ADRs) made stale by a changed GDD and walks through resolving each. Use when the user changed a number or rule in a GDD and asks which ADRs or architecture decisions are now out of date."
argument-hint: "[path/to/changed-gdd.md] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/propagate-design-change/../../hooks/yaml-helper.sh" resolve_config *), Bash(git diff *), Bash(git log *), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *)
model: sonnet
---

---
name: propagate-design-change
description: "找出因 GDD 变更而过时的架构决策（ADR），并引导逐一解决。当用户更改了 GDD 中的数字或规则并询问哪些 ADR 或架构决策现已过时时使用。"
argument-hint: "[path/to/changed-gdd.md] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/propagate-design-change/../../hooks/yaml-helper.sh" resolve_config *), Bash(git diff *), Bash(git log *), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,automation_always_ask,workflow,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

已在上方解析——按原样使用；`--review` 覆盖本次运行的 `review_mode`。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

使用问题工具询问。如果没有该工具，将选项编号列出并结束回合等待。被跳过或关闭的问题不是回答：用纯文本再次询问。

# Propagate Design Change
# 传播设计变更

When a GDD changes, the architecture decisions written against it may no longer
hold. This skill finds every ADR the change touches, compares what the ADR assumed
with what the GDD says now, and walks the user through each one.

当 GDD 变更时，针对它编写的架构决策可能不再成立。本技能找出该变更触及的每个 ADR，比较 ADR 所假设的内容与 GDD 现在所述的内容，并引导用户逐一处理。

**Example:** `/propagate-design-change design/gdd/combat-system.md`

**示例：** `/propagate-design-change design/gdd/combat-system.md`

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask: an ADR impact here is `schema_changes` and
`architecture_decisions`).

询问遵循 `.claude/docs/automation-modes.md`（协作模式总是询问，引导模式仅重大选择询问，自主模式记录并继续；`automation_always_ask` 类别总是询问：此处的 ADR 影响属于 `schema_changes` 和 `architecture_decisions`）。

**Tier.** `workflow` for the changed GDD's system: its `system_overrides` row if
there is one, else the project value. A system pinned `minimal` has no ADRs even on
a `standard` project. `full` checks every ADR; `standard` checks the critical
(Foundation-layer) ADRs and any ADR that names the changed GDD; `minimal` has
nothing to check (Phase 4).

**层级。** `workflow` 用于变更 GDD 的系统：如果有 `system_overrides` 行则用它，否则用项目值。被固定为 `minimal` 的系统即使在 `standard` 项目上也没有 ADR。`full` 检查每个 ADR；`standard` 检查关键的（Foundation 层）ADR 以及任何命名了变更 GDD 的 ADR；`minimal` 没有可检查的内容（阶段 4）。

## Phase 1: The GDD path
## 阶段 1：GDD 路径

The text typed after the skill name, with any `--review <mode>` pair removed, is the
changed GDD. It is required. Missing: "Usage: `/propagate-design-change
design/gdd/[system].md` — give the path to the GDD that changed." Not a file:
"[path] not found. Check the path and try again."

技能名之后输入的文本，去掉任何 `--review <mode>` 对，就是变更的 GDD。它是必需的。缺失时：“用法：`/propagate-design-change design/gdd/[system].md`——给出已变更 GDD 的路径。”不是文件时：“[path] 未找到。检查路径后重试。”

## Phase 2: What changed
## 阶段 2：变更了什么

Ask git, never compare two whole documents by eye:

询问 git，绝不用肉眼比较两份完整文档：

```bash
git diff HEAD -- design/gdd/[filename].md
```

Empty: the change may be committed already, so widen to the last commit that
touched it: `git diff HEAD~1 HEAD -- design/gdd/[filename].md`.

为空：变更可能已经提交，因此扩大到触及它的最后一次提交：`git diff HEAD~1 HEAD -- design/gdd/[filename].md`。

- No history at all (`git log --oneline -1 -- design/gdd/[filename].md` prints
  nothing): "No previous version in git — this is a new GDD, not a revision.
  Nothing to propagate." Stop.
- History, but both diffs empty: report "no uncommitted or last-commit changes to
  `[file]`" and ask which revision to propagate. An empty diff means nothing changed
  *here*, not that nothing is affected.

- 完全没有历史（`git log --oneline -1 -- design/gdd/[filename].md` 无输出）：“git 中没有先前版本——这是一个新 GDD，不是修订。没有什么可传播。”停止。
- 有历史，但两个 diff 都为空：报告“`[file]` 没有未提交或最后一次提交的变更”，并询问要传播哪个修订。空 diff 意味着*此处*没有变化，而不是没有任何东西受影响。

From the hunks: the `@@` headers name the section each change sits in, so the
changed-section list comes from the diff itself. A section with no hunk is unchanged
by construction. Read the surrounding section only when a hunk cannot be understood
alone (a changed number whose meaning depends on the rule above it), and then only
that section: `bash .claude/scripts/md-section.sh extract design/gdd/[file].md "[Section]"`.

从 hunk 中：`@@` 头命名每个变更所在章节，因此变更章节列表来自 diff 本身。没有 hunk 的章节按构造就是未变的。仅当一个 hunk 无法单独理解时（一个变更数字的含义取决于其上方规则），才读取周围章节，且仅读取该章节：`bash .claude/scripts/md-section.sh extract design/gdd/[file].md "[Section]"`。

## Phase 3: The change summary
## 阶段 3：变更摘要

```
## Change Summary: [GDD filename]
Date of revision: [today]

Changed sections:
- [Section]: [what changed — new rule, removed rule, formula modified, …]

Unchanged sections:
- [Section]

Key changes affecting architecture:
- [change likely to affect ADRs]
```

```
## 变更摘要：[GDD filename]
修订日期：[today]

变更章节：
- [Section]：[变更内容——新规则、移除规则、公式修改，……]

未变更章节：
- [Section]

影响架构的关键变更：
- [可能影响 ADR 的变更]
```

**Other GDDs that use these facts.** When `design/registry/entities.yaml` does not
exist or has no entries (it ships as an empty stub until `/design-system` fills it),
skip this; the ADR check below still runs. Otherwise it records which GDDs depend on
this system's facts: search it for `source: design/gdd/[filename]`. For each entity, constant or formula this GDD owns
whose value the diff changed, its `referenced_by:` list names the GDDs that may now
disagree. List them under "Downstream GDDs to re-check".

**使用这些事实的其他 GDD。** 当 `design/registry/entities.yaml` 不存在或没有条目时（它作为空桩发布，直到 `/design-system` 填充它），跳过此项；下方的 ADR 检查仍会运行。否则它记录哪些 GDD 依赖该系统的这些事实：在其中搜索 `source: design/gdd/[filename]`。对于该 GDD 拥有且 diff 更改了其值的每个实体、常量或公式，其 `referenced_by:` 列表命名了现在可能不一致的 GDD。将它们列在 "Downstream GDDs to re-check" 下。

## Phase 4: The ADRs in scope
## 阶段 4：范围内的 ADR

`bash .claude/scripts/adr-status.sh` lists every ADR with its status, layer and
missing sections.

`bash .claude/scripts/adr-status.sh` 列出每个 ADR 及其状态、层级和缺失章节。

- **`full`:** every ADR.
- **`standard`:** the critical ones (the `layer` column reads Foundation, or holds
  no layer: when in doubt, critical) and any ADR that names the changed GDD.
- **`minimal`:** report "No ADR check at minimal workflow — design change recorded;
  no architecture impact analysis." Stop.

- **`full`：** 每个 ADR。
- **`standard`：** 关键的那些（`layer` 列显示 Foundation，或不含层级：存疑时视为关键）以及任何命名了变更 GDD 的 ADR。
- **`minimal`：** 报告“minimal 工作流下不检查 ADR——设计变更已记录；不做架构影响分析。”停止。

Establish the denominator first: their count is **N**. N is 0: "No ADRs found in `docs/architecture/` — nothing to
check." Stop.

先确立分母：它们的计数为 **N**。N 为 0：“`docs/architecture/` 中未找到 ADR——无可检查。”停止。

**Which ones reference this GDD.** Without reading whole ADRs:

**哪些引用了此 GDD。** 无需读取整个 ADR：

1. each ADR's GDD Requirements Addressed section
   (`bash .claude/scripts/md-section.sh extract <adr> "GDD Requirements Addressed"`),
   for rows naming the changed GDD;
2. a search of the ADRs for the changed GDD's file name, which catches an ADR that
   cites it in prose without a table row.

1. 每个 ADR 的 GDD Requirements Addressed 章节（`bash .claude/scripts/md-section.sh extract <adr> "GDD Requirements Addressed"`），查找命名了变更 GDD 的行；
2. 在 ADR 中搜索变更 GDD 的文件名，这可捕获在散文中引用它但没有表格行的 ADR。

The union of the two is the affected set **M**.

两者的并集是受影响集合 **M**。

| Result | Meaning | Action |
|---|---|---|
| **M ≥ 1** | Normal. | Go on. The N − M others are out of scope for this check: never describe them as verified unaffected. |
| **M = 0**, and every in-scope ADR lacks GDD Requirements Addressed (`missing` column) | Traceability cannot be computed. | "[N] ADRs found, none has a 'GDD Requirements Addressed' section — traceability cannot be computed (a pre-production gate blocker). Run `/architecture-decision retrofit [adr]`." Stop. |
| **M = 0**, the sections exist | No ADR references this GDD. | "No ADR references [gdd] — no architecture impact." Stop. |

| 结果 | 含义 | 行动 |
|---|---|---|
| **M ≥ 1** | 正常。 | 继续。N − M 个其他项超出此检查范围：绝不要将它们描述为已验证未受影响。 |
| **M = 0**，且每个在范围内 ADR 都缺少 GDD Requirements Addressed（`missing` 列） | 无法计算可追溯性。 | “[N] 个 ADR 已找到，均无 'GDD Requirements Addressed' 章节——无法计算可追溯性（预制作门禁阻塞项）。运行 `/architecture-decision retrofit [adr]`。”停止。 |
| **M = 0**，章节存在 | 没有 ADR 引用此 GDD。 | “没有 ADR 引用 [gdd]——无架构影响。”停止。 |

Read `docs/architecture/requirements-traceability.md` when it exists.

当 `docs/architecture/requirements-traceability.md` 存在时读取它。

Report: "Checked [N] ADRs. [M] reference [gdd filename] ([X] in a requirements
table, [Y] in prose only)."

报告：“已检查 [N] 个 ADR。[M] 个引用 [gdd filename]（[X] 个在需求表中，[Y] 个仅在散文中）。”

## Phase 5: Impact analysis
## 阶段 5：影响分析

For each ADR in **M**, read its Context, Decision and Consequences sections with
`md-section.sh extract`: whether a decision still holds needs its reasoning, never
only its table row. Then, for each requirement it lists from the changed GDD:

对于 **M** 中的每个 ADR，用 `md-section.sh extract` 读取其 Context、Decision 和 Consequences 章节：判断一个决策是否仍然成立需要其推理，而绝不仅仅是其表格行。然后，对于它列出的来自变更 GDD 的每项需求：

1. Does the requirement still exist in the current GDD?
2. What did the GDD say when the ADR was written, and what does it say now?
3. Does the decision still hold?

1. 该需求在当前 GDD 中是否仍然存在？
2. ADR 编写时 GDD 是怎么说的，现在又是怎么说的？
3. 该决策是否仍然成立？

Classify each ADR:

分类每个 ADR：

| Status | Meaning |
|--------|---------|
| ✅ **Still Valid** | The change does not touch what this ADR decided |
| ⚠️ **Needs Review** | The change may affect it; human judgement needed |
| 🔴 **Likely Superseded** | The change contradicts what this ADR assumed |

| 状态 | 含义 |
|--------|---------|
| ✅ **Still Valid** | 变更未触及此 ADR 所决定的内容 |
| ⚠️ **Needs Review** | 变更可能影响它；需要人工判断 |
| 🔴 **Likely Superseded** | 变更与该 ADR 所假设的内容相矛盾 |

```
### ADR-NNNN: [title]
Status: [Still Valid | Needs Review | Likely Superseded]

What the ADR assumed about this GDD:
  "[quote from its GDD Requirements Addressed or Context]"

What the GDD now says:
  "[quote from the current GDD]"

Assessment:
  [whether the decision still holds, and why]

Recommended action:
  [Keep as-is | Review and update | Mark Superseded and write a new ADR]
```

```
### ADR-NNNN: [title]
状态：[Still Valid | Needs Review | Likely Superseded]

该 ADR 对此 GDD 的假设：
  "[quote from its GDD Requirements Addressed or Context]"

GDD 现在所述：
  "[quote from the current GDD]"

评估：
  [该决策是否仍然成立，以及为什么]

建议行动：
  [Keep as-is | Review and update | Mark Superseded and write a new ADR]
```

## Phase 6: The impact report, then the review
## 阶段 6：影响报告，然后评审

Show the whole report before asking for any action:

在询问任何行动之前展示整份报告：

```
## Design Change Impact Report
GDD: [filename]
Date: [today]
Changes detected: [N sections changed]
ADRs referencing this GDD: [M]

### Not Affected
[ADRs whose decisions still hold]

### Needs Review ([count])
[ADRs that may need updating]

### Likely Superseded ([count])
[ADRs whose assumptions the change contradicts]
```

```
## 设计变更影响报告
GDD：[filename]
日期：[today]
检测到的变更：[N sections changed]
引用此 GDD 的 ADR：[M]

### 未受影响
[决策仍然成立的 ADR]

### 需要评审（[count]）
[可能需要更新的 ADR]

### 可能被取代（[count]）
[其假设被该变更推翻的 ADR]
```

**The technical review.** Read the `review_gate` line above. `skill-gates=skip`
(solo or lean): no agent; note `TD-CHANGE-IMPACT skipped — [Solo | Lean] mode`.
`skill-gates=run`: hand the review to the `technical-director` agent with gate
**TD-CHANGE-IMPACT** (`.claude/docs/director-gates/td-change-impact.md`; the agent
reads it itself). Brief:

**技术评审。** 读取上方的 `review_gate` 行。`skill-gates=skip`（solo 或 lean）：无智能体；注明 `TD-CHANGE-IMPACT skipped — [Solo | Lean] mode`。`skill-gates=run`：将评审交给 `technical-director` 智能体，门禁为 **TD-CHANGE-IMPACT**（`.claude/docs/director-gates/td-change-impact.md`；该智能体自行读取它）。简报：

- **Objective:** check the impact report before the user acts on it.
- **Give it:** the whole report above: the change summary, every affected ADR with
  its classification and recommended action.
- **Check:** no ADR is under-classified; the recommended actions are sound; no
  knock-on effect on other ADRs or systems was missed.
- **Return:** APPROVE, CONCERNS, REJECT, or NOT ASSESSED naming a missing input.
- **Boundaries:** it edits no file.

- **目标：** 在用户据此行动之前检查影响报告。
- **提供：** 上方整份报告：变更摘要、每个受影响 ADR 及其分类和建议行动。
- **检查：** 没有 ADR 被低估分类；建议行动合理；没有遗漏对其他 ADR 或系统的连锁影响。
- **返回：** APPROVE、CONCERNS、REJECT，或 NOT ASSESSED 并指出缺失输入。
- **边界：** 它不编辑任何文件。

Act on the verdict:

根据结论行动：

- **APPROVE:** go to Phase 7.
- **CONCERNS:** show the flagged ADRs or actions, and ask: "How do you want to go
  on?" Options: Revise the impact assessment / Accept with the noted concerns /
  Discuss further.
- **REJECT:** do not go to Phase 7; analyse the impact again first.
- **NOT ASSESSED:** it is not an approval (`.claude/docs/director-gates.md`). Name
  what was missing, then supply it and run the review again; or, when the user
  chooses to go on without it, go to Phase 7 and state `TD-CHANGE-IMPACT: NOT
  ASSESSED — [input]` in the report and the final verdict line.

- **APPROVE：** 进入阶段 7。
- **CONCERNS：** 展示被标记的 ADR 或行动，并询问：“你想如何进行？”选项：修订影响评估 / 接受并附注关注项 / 进一步讨论。
- **REJECT：** 不要进入阶段 7；先再次分析影响。
- **NOT ASSESSED：** 它不算批准（`.claude/docs/director-gates.md`）。指出缺失了什么，然后补充它并再次运行评审；或者，当用户选择在没有它的情况下继续时，进入阶段 7 并在报告和最终结论行中声明 `TD-CHANGE-IMPACT: NOT ASSESSED — [input]`。

## Phase 7: Resolve each ADR
## 阶段 7：解决每个 ADR

For each ADR marked Needs Review or Likely Superseded, one at a time, ask: "ADR-NNNN
([title]) — [status]. What would you like to do?" Options:

对每个标记为 Needs Review 或 Likely Superseded 的 ADR，一次一个地询问：“ADR-NNNN（[title]）——[status]。你想怎么做？”选项：

- Mark it Superseded (I'll write the new ADR)
- Update it in place (a small revision): note what to revise; the user edits it
- Keep it as it is (the change does not affect this decision)
- Skip it for now (revisit later)

- 标记为 Superseded（我会编写新 ADR）
- 就地更新（小修订）：注明要修订什么；由用户编辑
- 保持原样（变更不影响此决策）
- 暂时跳过（稍后重访）

**Mark Superseded.** Ask "May I set the Status of [ADR file] to Superseded?" On yes,
replace only the body of its `## Status` section:

**标记为 Superseded。** 询问“我可以将 [ADR file] 的 Status 设置为 Superseded 吗？”在同意后，仅替换其 `## Status` 章节的正文：

```
bash .claude/scripts/md-section.sh replace docs/architecture/[adr-file].md "Status" <<'EOF'
Superseded — replacement pending (see docs/architecture/change-impact-[date]-[system-slug].md)
EOF
```

This is the one form this skill writes. `adr-status.sh` reads it as Superseded, so
`/dev-story` and `/create-stories` block the stories that still point at it. The
new ADR, once written, records which one it replaces. Change nothing else in the
ADR: its content stays.

这是本技能写入的唯一形式。`adr-status.sh` 将其读取为 Superseded，因此 `/dev-story` 和 `/create-stories` 会阻塞仍指向它的故事。新 ADR 一旦编写，会记录它取代了哪一个。不要更改 ADR 中的任何其他内容：其内容保持不变。

## Phase 8: The traceability index
## 阶段 8：可追溯性索引

When `docs/architecture/requirements-traceability.md` exists, ask "May I add the
changed requirements to the traceability index?" On yes, add a row per changed
requirement:

当 `docs/architecture/requirements-traceability.md` 存在时，询问“我可以将变更需求添加到可追溯性索引吗？”在同意后，为每项变更需求添加一行：

```markdown
## Superseded Requirements
| Date | GDD | Requirement | Changed To | ADRs Affected | Resolution |
|------|-----|-------------|------------|---------------|------------|
| [date] | [gdd] | [old requirement text] | [new requirement text] | ADR-NNNN | [Superseded/Updated/Valid] |
```

```markdown
## 被取代需求
| 日期 | GDD | 需求 | 更改为 | 受影响 ADR | 解决方式 |
|------|-----|-------------|------------|---------------|------------|
| [date] | [gdd] | [old requirement text] | [new requirement text] | ADR-NNNN | [Superseded/Updated/Valid] |
```

## Phase 9: The change impact document
## 阶段 9：变更影响文档

Ask "May I write the change impact report to
`docs/architecture/change-impact-[date]-[system-slug].md`?" It holds the change
summary, the impact analysis, the resolution chosen for each ADR, and the ADRs that
need writing or updating.

询问“我可以将变更影响报告写入 `docs/architecture/change-impact-[date]-[system-slug].md` 吗？”它包含变更摘要、影响分析、每个 ADR 选择的解决方式，以及需要编写或更新的 ADR。

## Phase 10: Follow-up
## 阶段 10：后续

From the resolutions:

根据解决方式：

- ADRs marked Superseded: "Run `/architecture-decision [title]` to write the
  replacement, then `/propagate-design-change` again to check coverage."
- ADRs to update in place: the fields to change in each.
- Many ADRs affected: "Run `/architecture-review` once they are updated, to check
  the traceability matrix still holds together."

- 标记为 Superseded 的 ADR：“运行 `/architecture-decision [title]` 编写替代项，然后再次运行 `/propagate-design-change` 检查覆盖。”
- 需要就地更新的 ADR：每个中要更改的字段。
- 许多 ADR 受影响：“一旦它们更新完毕，运行 `/architecture-review`，检查可追溯性矩阵是否仍然自洽。”

End with `Verdict: COMPLETE — change impact report saved` after the Phase 9 write,
or `Verdict: BLOCKED — user declined the write` when declined.

在阶段 9 写入后以 `Verdict: COMPLETE — change impact report saved` 结束，若被拒绝则为 `Verdict: BLOCKED — user declined the write`。
