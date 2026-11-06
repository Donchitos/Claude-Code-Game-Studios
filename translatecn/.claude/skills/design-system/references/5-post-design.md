# /design-system — Phase 5: Post-Design Validation
# /design-system — 第五阶段：设计后验证

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/design-system` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## 5. Post-Design Validation
## 5. 设计后验证

**In this file:**

**本文件内容：**

- 5-pre: Author the Summary
- 5-pre：撰写 Summary（摘要）
- 5a: Self-Check
- 5a：自检
- 5a-bis: Creative Director Pillar Review
- 5a-bis：创意总监支柱评审
- 5b: Update Entity Registry
- 5b：更新实体注册表
- 5c: Offer Design Review
- 5c：提供设计评审
- 5d: Update Systems Index
- 5d：更新系统索引
- 5e: Update Session State
- 5e：更新会话状态
- 5f: Suggest Next Steps
- 5f：建议下一步

After all sections are written:

在所有章节写完之后：

### 5-pre: Author the Summary
### 5-pre：撰写 Summary（摘要）

Write `## Summary` and its `> **Quick reference**` line now — after the design
exists, so the summary distils real content rather than intentions. This runs
**at every tier**, including `standard` and a voluntary `minimal` GDD: the
Summary is what lets a later skill scan 20 GDDs and decide which to read in full
(`/create-epics`, `/architecture-review`, `/review-all-gdds` all grep it), so a
GDD without it silently forces those consumers back to full reads.

现在写下 `## Summary` 及其 `> **Quick reference**` 行——在设计已经存在之后，这样摘要提炼的是真实内容而不是意图。这在**每个层级**都会运行，包括 `standard` 和自愿的 `minimal` GDD：正是 Summary 让后续技能能够扫描 20 个 GDD 并决定哪些需要完整阅读（`/create-epics`、`/architecture-review`、`/review-all-gdds` 都会 grep 它），因此缺少它的 GDD 会悄然迫使这些消费者退回完整读取。

- **Summary body**: 2–3 sentences — what this system is, what it does for the
  player, why it exists in this game. No jargon; a reader who has not seen the
  GDD should learn whether it is relevant to their task.
- **Quick reference**: `Layer` and `Priority` from the systems index
  (`design/gdd/systems-index.md`); `Key deps` from the Dependencies section just
  written (system names, or `None`).

- **Summary 正文**：2–3 句话——这个系统是什么、它为玩家做什么、它为何存在于这款游戏中。不要术语行话；一个没见过该 GDD 的读者也应当能了解到它是否与自己的任务相关。
- **Quick reference**：`Layer` 和 `Priority` 来自系统索引（`design/gdd/systems-index.md`）；`Key deps` 来自刚刚写好的 Dependencies 章节（系统名称，或 `None`）。

Replace the `[To be designed]` Summary placeholder in the skeleton. Then apply
the section cycle's Write step as for any other section.

替换骨架中的 `[To be designed]` Summary 占位符。然后像对待任何其他章节一样应用章节循环的 Write（写入）步骤。

### 5a: Self-Check
### 5a：自检

Read back the complete GDD from file (not from conversation memory — the file is
the source of truth). This step needs the whole GDD: read it in ranges by its
headings (found with the Grep tool: pattern `^#`, content mode), since a whole-file
Read over 40 KB is refused. Verify:
- The `## Summary` and its Quick reference are populated (not the placeholder)
- Every section **required at this system's effective tier** has real content
  (not placeholders) — §1: 8 at `full`, 5 + conditional Formulas at `standard`,
  5 at a voluntary `minimal`. Do not verify against a fixed count of 8: below
  `full` that reports a correctly-authored GDD as incomplete
- Formulas reference defined variables
- Edge cases have resolutions
- Dependencies are listed with interfaces
- Acceptance criteria are testable

从文件中回读完整的 GDD（而不是从对话记忆中——文件才是事实来源）。这一步需要整个 GDD：按其标题分段读取（用 Grep 工具找到：模式 `^#`，content 模式），因为超过 40 KB 的整文件 Read 会被拒绝。验证：
- `## Summary` 及其 Quick reference 已填充（不是占位符）
- 在**本系统的有效层级**下必需的每个章节都有真实内容（不是占位符）——§1：`full` 下 8 个，`standard` 下 5 个 + 条件性 Formulas，自愿的 `minimal` 下 5 个。不要对照固定的 8 个来验证：在 `full` 以下，那样会把撰写正确的 GDD 报告为不完整
- Formulas 引用了已定义的变量
- Edge cases 有解决方案
- Dependencies 列明了接口
- Acceptance criteria 可测试

### 5a-bis: Creative Director Pillar Review
### 5a-bis：创意总监支柱评审

**Review mode check** — apply before spawning CD-GDD-ALIGN:
- `solo` → skip. Note: "CD-GDD-ALIGN skipped — Solo mode." Proceed to Step 5b.
- `lean` → skip (not a PHASE-GATE). Note: "CD-GDD-ALIGN skipped — Lean mode." Proceed to Step 5b.
- `full` → spawn as normal.

**评审模式检查** —— 在生成 CD-GDD-ALIGN 之前应用：
- `solo` → 跳过。注明："CD-GDD-ALIGN skipped — Solo mode."
- `lean` → 跳过（不是 PHASE-GATE）。注明："CD-GDD-ALIGN skipped — Lean mode." 继续执行第 5b 步。
- `full` → 照常生成。

Before finalizing the GDD, spawn `creative-director` via `Agent` using gate **CD-GDD-ALIGN** (`.claude/docs/director-gates/cd-gdd-align.md`).

在最终确定 GDD 之前，通过 `Agent` 使用门禁 **CD-GDD-ALIGN**（`.claude/docs/director-gates/cd-gdd-align.md`）生成 `creative-director`。

Pass: completed GDD file path, game pillars (from `design/gdd/game-concept.md` or `design/gdd/game-pillars.md`; if there is neither, the pitch and "what they feel" line of `design/game-brief.md`), MDA aesthetics target, and the GDD's Player Fantasy section — or, when this tier did not author one, say so.

传入：已完成的 GDD 文件路径、游戏支柱（来自 `design/gdd/game-concept.md` 或 `design/gdd/game-pillars.md`；如果两者都没有，则用 `design/game-brief.md` 的推介语和"他们感受什么"一句）、MDA 美学目标，以及 GDD 的 Player Fantasy 章节——或者，当此层级没有撰写该章节时，说明这一点。

Handle verdict per the standard rules in `director-gates.md`.
On `Revise flagged items`, or to resolve a REJECT, each flagged section runs its
section cycle again — its specialist consulted as that section's review-mode
check says — and is re-approved through its "Approve the [Section Name]
section?" widget before the Edit that writes it; then record `REVISED [date]`.
A `NOT ASSESSED` answer is never an approval: name the missing input, then
supply it and re-run the gate, or record `NOT ASSESSED`.
After resolution, record the verdict in the GDD Status header:
`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`

按 `director-gates.md` 中的标准规则处理判定。
在 `Revise flagged items`（修订被标记项）时，或为了消解 REJECT，每个被标记的章节会再次运行其章节循环——按该章节评审模式检查的要求咨询其专家——并在写入它的 Edit 之前，通过其"Approve the [Section Name] section?"组件重新获批；然后记录 `REVISED [date]`。
`NOT ASSESSED` 的回答永远不是批准：指明缺失的输入，然后补齐并重新运行门禁，或者记录 `NOT ASSESSED`。
解决之后，在 GDD 的 Status 头部记录判定：
`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`

---

### 5b: Update Entity Registry
### 5b：更新实体注册表

Scan the completed GDD for cross-system facts that should be registered:
- Named entities (enemies, NPCs, bosses) with stats or drops
- Named items with values, weights, or categories
- Named formulas with defined variables and output ranges
- Named constants referenced by value in more than one place

扫描已完成的 GDD，找出应当登记的跨系统事实：
- 带属性或掉落物的具名实体（敌人、NPC、Boss）
- 带数值、权重或类别的具名物品
- 带已定义变量和输出范围的具名公式
- 在不止一处按值引用的具名常量

**First check the registry exists** — §2a reads it *"if it exists"*, and this
step needs the same guard. At `standard` and below the file is often
absent, and a grep against a missing path returns nothing, which is
indistinguishable from "no candidate is registered yet":

**首先检查注册表是否存在**——§2a 是在它*"如果存在"*时读取它，而这一步需要同样的守卫。在 `standard` 及以下层级，该文件常常不存在，而对缺失路径做 grep 会返回空，这与"尚无候选被登记"无法区分：

- **Absent** — say so, and ask whether to create it:
  *"`design/registry/entities.yaml` does not exist. May I create it with these
  [N] entries?"* If the user declines, skip 5b and say the registry was not
  written — do not treat the skip as a clean pass.
- **Present but empty** — every list is `[]`, or the only matches are inside
  comment blocks. Treat it as present, register the candidates, but say which
  state you found: *"registry exists and is empty — all [N] entries are new."*
  The shipped template's comments carry fully-formed examples referencing
  `design/gdd/inventory.md` with real-looking values (`base_inventory_slots: 20`,
  `gold_carry_limit: 9999`), so §2a's registry greps return **comment
  lines** on an empty registry — and §2d would then present those invented numbers to the user as
  *"These values are locked."* Match entries under a live `entities:`/`items:`/
  `formulas:`/`constants:` key, never a commented example.
- **Present** — for each candidate, check whether it is already registered:

- **缺失** —— 说明这一点，并询问是否创建它：*"`design/registry/entities.yaml` 不存在。我可以用这 [N] 个条目创建它吗？"* 如果用户拒绝，跳过 5b 并说明注册表未被写入——不要把这次跳过当作干净通过。
- **存在但为空** —— 每个列表都是 `[]`，或唯一匹配项位于注释块内。把它视为存在，登记候选条目，但说明你发现的是哪种状态：*"registry exists and is empty — all [N] entries are new."*（注册表存在且为空——全部 [N] 个条目都是新的。）随附模板的注释包含完整成形的示例，引用了 `design/gdd/inventory.md` 以及看似真实的数值（`base_inventory_slots: 20`、`gold_carry_limit: 9999`），因此在空注册表上 §2a 的注册表 grep 会返回**注释行**——然后 §2d 会把这些编造的数值作为*"这些值已锁定。"* 呈现给用户。只在活跃的 `entities:`/`items:`/`formulas:`/`constants:` 键下匹配条目，绝不要匹配被注释掉的示例。
- **存在** —— 对每个候选，检查它是否已经登记：

```
Grep pattern="  - name: [candidate_name]" path="design/registry/entities.yaml"
```

Present a summary:
```
Registry candidates from this GDD:
  NEW (not yet registered):
    - [entity_name] [entity]: [attribute]=[value], [attribute]=[value]
    - [item_name] [item]: [attribute]=[value], [attribute]=[value]
    - [formula_name] [formula]: variables=[list], output=[min–max]
  ALREADY REGISTERED (referenced_by will be updated):
    - [constant_name] [constant]: value=[N] ← matches registry ✅
```

呈现一份摘要：
```
Registry candidates from this GDD:
  NEW (not yet registered):
    - [entity_name] [entity]: [attribute]=[value], [attribute]=[value]
    - [item_name] [item]: [attribute]=[value], [attribute]=[value]
    - [formula_name] [formula]: variables=[list], output=[min–max]
  ALREADY REGISTERED (referenced_by will be updated):
    - [constant_name] [constant]: value=[N] ← 与注册表匹配 ✅
```
（本 GDD 产生的注册表候选：NEW（尚未登记）：……；ALREADY REGISTERED（将更新 referenced_by）：……）

Ask: "May I update `design/registry/entities.yaml` with these [N] new entries
and update `referenced_by` for the existing entries?" (If the file was absent
and the user approved creating it, the wording is *create*, not *update*, and
there are no `referenced_by` arrays to merge.)

询问："我可以把这 [N] 个新条目更新到 `design/registry/entities.yaml`，并更新现有条目的 `referenced_by` 吗？"（如果文件原本缺失且用户已同意创建它，措辞应为*创建*而不是*更新*，且没有需要合并的 `referenced_by` 数组。）

If yes: append new entries and update `referenced_by` arrays. Never modify
existing `value` / attribute fields without surfacing it as a conflict first.

如果同意：追加新条目并更新 `referenced_by` 数组。绝不要修改现有的 `value` / 属性字段，除非先把这一点作为冲突暴露出来。

After writing, run `bash .claude/scripts/registry.sh validate` and fix every row
about an entry this write added or changed (a DUPLICATE, STATUS or LAYOUT row,
or a PATH_MISSING row for a path it named) before you go on; name rows about
other entries to the user rather than fixing them unasked. If the script is
missing or prints nothing, say the registry check did not run, then re-read the
entries you wrote against the rules in the file's header.

写入之后，运行 `bash .claude/scripts/registry.sh validate`，并在继续之前修复每一行关于本次写入新增或改动的条目（DUPLICATE、STATUS 或 LAYOUT 行，或它所指路径的 PATH_MISSING 行）；关于其他条目的行，向用户指出而不是未经请求就修复。如果脚本缺失或没有输出任何内容，说明注册表检查未运行，然后对照文件头部的规则重新阅读你写入的条目。

### 5c: Offer Design Review
### 5c：提供设计评审

Present a completion summary:

呈现一份完成摘要：

> **GDD Complete: [System Name]**
> - Sections written: [list]
> - Provisional assumptions: [list any assumptions about undesigned dependencies]
> - Cross-system conflicts found: [list or "none"]

> **GDD 完成：[System Name]**
> - 已写章节：[list]
> - 临时假设：[列出任何关于未设计依赖的假设]
> - 发现的跨系统冲突：[list 或 "none"]

> **To validate this GDD, open a fresh Claude Code session and run:**
> `/design-review design/gdd/[system-name].md`
>
> **Never run `/design-review` in the same session as `/design-system`.** The reviewing
> agent must be independent of the authoring context. Running it here would inherit
> the full design history, making independent critique impossible.

> **要验证这个 GDD，请打开一个新的 Claude Code 会话并运行：**
> `/design-review design/gdd/[system-name].md`
>
> **绝不要在与 `/design-system` 相同的会话中运行 `/design-review`。** 评审智能体必须独立于撰写上下文。在这里运行它会继承完整的设计历史，使独立批评变得不可能。

**NEVER offer to run `/design-review` inline.** Always direct the user to a fresh window.

**绝不要提供就地运行 `/design-review` 的选项。** 始终引导用户使用新窗口。

### 5d: Update Systems Index
### 5d：更新系统索引

After the GDD is complete (and optionally reviewed):

在 GDD 完成（并可选地经评审）之后：

**First check the systems index exists.** §2a skips it at `minimal` because it is
never written at that tier, and this step needs the same guard as §5b. It
matters most on a `minimal` project with a
`system_overrides` bump, where the effective tier is `standard` or `full` and
nothing else in §5 hints the file may be absent.

**首先检查系统索引是否存在。** §2a 在 `minimal` 下跳过它，因为该层级从不写它，而这一步需要与 §5b 相同的守卫。这一点在带有 `system_overrides` 提升的 `minimal` 项目上最为重要：此时有效层级是 `standard` 或 `full`，而 §5 中其他地方都没有提示该文件可能缺失。

- **Absent** — say so in one line (*"no `design/gdd/systems-index.md` at this
  workflow tier; nothing to update"*) and skip to §5e. Do **not** offer to create
  one: `/map-systems` owns that file, and a stub written here would be a systems
  index listing exactly one system.
- **Present** — continue:

- **缺失** —— 用一行说明（*"此工作流层级没有 `design/gdd/systems-index.md`；无需更新"*）并跳到 §5e。**不要**提供创建一个的选项：那个文件归 `/map-systems` 所有，而在此处写一个存根会得到只列出一个系统的系统索引。
- **存在** —— 继续：

- Read the systems index by section: find the headings you need with
  the Grep tool (pattern `^#`, content mode) and Read those ranges with
  offset and limit
- Update the target system's row:
  - If design-review was run and verdict is APPROVED: Status → "Approved"
  - If design-review was run and verdict is NEEDS REVISION or MAJOR REVISION NEEDED: Status → "Needs Revision" (that exact string — `/design-review` sets "In Review" only once the revisions are applied)
  - If design-review was skipped: Status → "Designed" (pending review)
  - If the user chose "I'll review it myself first": Status → "Designed"
  - Design Doc: link to `design/gdd/[system-name].md`
- Update the Progress Tracker counts

- 按章节读取系统索引：用 Grep 工具（模式 `^#`，content 模式）找到你需要的标题，再用 offset 和 limit 读取这些区段
- 更新目标系统的行：
  - 如果运行了 design-review 且判定为 APPROVED：Status → "Approved"
  - 如果运行了 design-review 且判定为 NEEDS REVISION 或 MAJOR REVISION NEEDED：Status → "Needs Revision"（就用这个确切的字符串——`/design-review` 只有在修订被应用后才设置 "In Review"）
  - 如果跳过了 design-review：Status → "Designed"（待评审）
  - 如果用户选择 "I'll review it myself first"（我先自己评审）：Status → "Designed"
  - Design Doc：链接到 `design/gdd/[system-name].md`
- 更新 Progress Tracker 计数

Ask: "May I update the systems index at `design/gdd/systems-index.md`?"

询问："我可以更新 `design/gdd/systems-index.md` 中的系统索引吗？"

### 5e: Update Session State
### 5e：更新会话状态

Update `production/session-state/active.md` with:
- Task: [system-name] GDD
- Status: Complete (or In Review if design-review was run)
- File: design/gdd/[system-name].md
- Sections: [list the sections actually authored, by name] — **never a fixed
  count**; §5a forbids verifying against `/8`, and the same reasoning applies to
  recording it. Below `full` a correctly-authored GDD has fewer than 8 sections,
  and writing "All 8 written" into session state makes the next reader believe
  a complete GDD is incomplete
- Next: [suggest next system from design order]

用以下内容更新 `production/session-state/active.md`：
- Task: [system-name] GDD（任务：[system-name] 的 GDD）
- Status: Complete（完成）（如果运行了 design-review 则为 In Review）
- File: design/gdd/[system-name].md
- Sections: [按名称列出实际撰写的章节] —— **绝不要用固定数量**；§5a 禁止对照 `/8` 验证，同样的道理也适用于记录。在 `full` 以下，撰写正确的 GDD 少于 8 个章节，而把 "All 8 written"（全部 8 个已写）写进会话状态，会让下一个读者以为一个完整的 GDD 是不完整的
- Next: [根据设计顺序建议下一个系统]

### 5f: Suggest Next Steps
### 5f：建议下一步

Use `AskUserQuestion`:
- "What's next?"
  - Options:
    - "Run `/consistency-check` — verify this GDD's values don't conflict with existing GDDs (recommended before designing the next system)"
    - "Design next system ([next-in-order])" — if undesigned systems remain
    - "Fix review findings" — if design-review flagged issues
    - "Stop here for this session"
    - "Run `/gate-check`" — if enough MVP systems are designed

使用 `AskUserQuestion`：
- "接下来做什么？"
  - 选项：
    - "Run `/consistency-check`" —— 验证本 GDD 的数值不与现有 GDD 冲突（建议在设计下一个系统之前执行）
    - "Design next system ([next-in-order])"（设计下一个系统）—— 如果还有未设计的系统
    - "Fix review findings"（修复评审发现）—— 如果 design-review 标记了问题
    - "Stop here for this session"（本次会话到此为止）
    - "Run `/gate-check`" —— 如果已有足够多的 MVP 系统完成设计

---
