---
name: create-epics
description: "Turns the GDDs and architecture into epics, one per architectural module. Use when the user wants to break the game into epics or plan the work before writing stories. Not for splitting one epic into stories."
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/gdd-structure-check.sh*), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/write-guard.sh overwrite *)
model: sonnet
---
---
name: create-epics
description: "将 GDD 与架构转化为史诗，每个架构模块一个。当用户想把游戏拆成史诗或在编写故事前规划工作时使用。不用于将一个史诗拆分为故事。"
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/gdd-structure-check.sh*), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/write-guard.sh overwrite *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,docs.density,engine_values,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

用询问工具提问。若无该工具，将选项编号列出并结束回合等待。被跳过或关闭的问题不算回答：
请用纯文本再次询问。

# Create Epics

# 创建史诗

An epic is a bounded body of work for one architectural module: **what** gets built
and which decisions govern it. How to build it is for the stories. Run it once per
layer as development reaches that layer: Feature epics written before Core is
nearly done describe a design that will have changed.

史诗是针对一个架构模块的有界工作体：**什么**会被构建，以及哪些决策管辖它。如何构建则属于故事。
当开发到达某一分层时，对该分层运行一次：在 Core 接近完成之前编写的 Feature 史诗，描述的是
一个将会发生变化的设计。

**Writes:** `production/epics/[epic-slug]/EPIC.md` per epic and its row in
`production/epics/index.md`, each after its own yes.
**Next:** `/create-stories [epic-slug]` per epic. This skill never writes a story.

**写入：** 每个史诗的 `production/epics/[epic-slug]/EPIC.md` 及其在
`production/epics/index.md` 中的行，各自在各自的同意之后写入。
**下一步：** 每个史诗运行 `/create-stories [epic-slug]`。本技能绝不编写故事。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

询问遵循 `.claude/docs/automation-modes.md`（协作模式始终询问，引导模式就重大选择询问，
自主模式记录并继续；`automation_always_ask` 类别始终询问）。

Checklist (copy it and tick as you go):

清单（复制它并随做随勾）：

```
- [ ] Phase 1: scope and tier
- [ ] Phase 2: inputs loaded and reported
- [ ] Phase 3: each epic shown, "Shall I create Epic: …?" asked one at a time
- [ ] Phase 4: producer review run, or its skip noted
- [ ] Phase 5: each EPIC.md and index row written after its own yes
- [ ] Phase 6: closing block printed
```

## Phase 1: Scope and tier

## 阶段 1：范围与层级

The text typed after the skill name, with any `--review <mode>` pair removed:

技能名之后输入的文本，去除任何 `--review <mode>` 对：

- `all`: every system, in layer order.
- `layer: foundation` (or `core`, `feature`, `presentation`): that layer only.
- a system name: that system only.
- nothing: the request's own words when they name a layer or system ("foundation
  and core"); else ask "Which layer or system would you like epics for?"

- `all`：每个系统，按分层顺序。
- `layer: foundation`（或 `core`、`feature`、`presentation`）：仅该分层。
- 一个系统名：仅该系统。
- 无内容：若请求本身的措辞点名了分层或系统（“foundation
  and core”）则采用该措辞；否则询问“你想为哪个分层或系统创建史诗？”

**Tier.** The project's `workflow` value sets what is required (Phase 2). Each
in-scope system's own GDD bar comes from its `system_overrides` row, when it has one.

**层级。** 项目的 `workflow` 取值决定什么是必需的（阶段 2）。每个在范围内系统自身的 GDD
门槛来自其 `system_overrides` 行（若有）。

**At `minimal`, tell the user first:** this step is optional at this tier, because
`/create-stories` builds the epic from `design/game-brief.md` by itself. Then go on
when they asked for epics.

**在 `minimal` 下，先告知用户：** 本步骤在该层级是可选的，因为
`/create-stories` 会自行从 `design/game-brief.md` 构建史诗。然后在他们要求史诗时继续。

## Phase 2: Load the inputs

## 阶段 2：加载输入

### `minimal`: the brief

### `minimal`：简报

Read `design/game-brief.md`. None: stop, "No `design/game-brief.md` — run `/start`
or `/brainstorm` first." Never ask for GDDs, a systems index, an architecture
document, ADRs, a TR registry or a control manifest, and never send the user to
`/design-system`, `/map-systems` or `/create-architecture` first: this tier has none
by design.

读取 `design/game-brief.md`。若无：停止，“无 `design/game-brief.md` — 请先运行 `/start`
或 `/brainstorm`。”绝不索要 GDD、系统索引、架构文档、ADR、TR 注册表或控制清单，也绝不先让用户去
`/design-system`、`/map-systems` 或 `/create-architecture`：该层级按设计就没有这些。

Report first, word for word:

先逐字报告：

```
Loaded: design/game-brief.md · engine [name version from the engine_values line]
At minimal this step is optional: /create-stories builds the epic from the brief by itself.
```

The epics come from the brief's MVP feature list, in its **Build order**. A short
brief is one epic, slugged from the brief's working title (the slug `/create-stories`
uses when nothing is typed). When the user asks for the work grouped, make one epic
per group of MVP features that ship together. Every epic names its slug, since
`/create-stories` needs it typed.

史诗来自简报的 MVP 功能列表，按其**构建顺序**。简短的简报就是一个史诗，slug 取自简报的工作标题
（即未输入任何内容时 `/create-stories` 使用的 slug）。当用户要求将工作分组时，每组一同发布的 MVP
功能创建一个史诗。每个史诗都点名其 slug，因为 `/create-stories` 需要把它输入。

### `standard` and `full`: the design and the architecture

### `standard` 与 `full`：设计与架构

1. **The system GDDs.** `bash .claude/scripts/gdd-structure-check.sh` lists every
   system GDD; the game concept, systems index, pillars, cross-reviews and the other
   non-system documents are left out for you. Their count is **N**. N is 0: stop,
   "No system GDDs found in `design/gdd/` — run `/design-system` first."
2. **What is in scope.** Each GDD's `## Summary` quick reference gives its layer and
   priority. A GDD with no Summary (older GDDs predate it) takes its layer from
   `design/gdd/systems-index.md`. Never treat an absent `## Summary` as an absent system:
   it never drops one from scope.
3. **The architecture.** `docs/architecture/architecture.md` is required at both
   tiers: missing, stop with
   "No `docs/architecture/architecture.md` — run `/create-architecture` first." Never invent module boundaries.
4. **For in-scope systems only**, by section, never whole:
   - each GDD's Overview and Acceptance Criteria
     (`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Overview"`);
   - `bash .claude/scripts/adr-status.sh` for every ADR's status, layer and missing
     sections; then the GDD Requirements Addressed, Decision and Engine
     Compatibility sections of the ADRs that cover in-scope systems;
   - `docs/architecture/tr-registry.yaml`: the entries whose `system:` is an
     in-scope system;
   - the control manifest's `Manifest Version` line (read if present at `standard`,
     required at `full`);
   - `docs/engine-reference/<engine>/VERSION.md` for the engine's risk levels.

1. **系统 GDD。** `bash .claude/scripts/gdd-structure-check.sh` 列出每个
   系统 GDD；游戏概念、系统索引、支柱、交叉评审及其他非系统文档会为你排除。其数量为 **N**。
   N 为 0：停止，“在 `design/gdd/` 中未找到系统 GDD — 请先运行 `/design-system`。”
2. **什么在范围内。** 每个 GDD 的 `## Summary` 快速参考给出其分层与
   优先级。没有 Summary 的 GDD（较旧的 GDD 早于它）从
   `design/gdd/systems-index.md` 取得分层。绝不可将缺失的 `## Summary` 当作缺失系统：
   它绝不使某系统退出范围。
3. **架构。** 两个层级都需要 `docs/architecture/architecture.md`：缺失则停止，提示
   “无 `docs/architecture/architecture.md` — 请先运行 `/create-architecture`。”绝不凭空发明模块边界。
4. **仅对在范围内的系统**，按小节读取，绝不整份读取：
   - 每个 GDD 的 Overview 与 Acceptance Criteria
     （`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Overview"`）；
   - `bash .claude/scripts/adr-status.sh` 获取每个 ADR 的状态、分层与缺失
     小节；然后读取覆盖在范围内系统的 ADR 的 GDD Requirements Addressed、Decision 与 Engine
     Compatibility 小节；
   - `docs/architecture/tr-registry.yaml`：其 `system:` 为在范围内
     系统的条目；
   - 控制清单的 `Manifest Version` 行（`standard` 下若存在则读取，
     `full` 下必需）；
   - `docs/engine-reference/<engine>/VERSION.md` 获取引擎的风险等级。

Report before defining anything, with the real state:

在定义任何内容之前，按真实状态报告：

```
Loaded: [N] system GDDs, [n] in scope ([names]) · [M] ADRs ([A] Accepted, [P] Proposed) · manifest v[date | absent] · engine [name version from the engine_values line]
```

At `full`, every in-scope GDD needs all 8 sections and Approved status, and the TR
registry and control manifest are required. At `standard`, the GDDs need their 5
required sections, and only critical (Foundation-layer) ADRs are expected.

在 `full` 下，每个在范围内 GDD 都需要全部 8 个小节与 Approved 状态，且 TR
注册表与控制清单为必需。在 `standard` 下，GDD 需要其 5 个
必需小节，且仅预期关键（Foundation 层）ADR。

## Phase 3: Define each epic, ask one at a time

## 阶段 3：定义每个史诗，逐个询问

Process by layer: Foundation, then Core, Feature, Presentation; within a layer, the
systems index order (at `minimal`, the brief's Build order). For each system, its
module from `architecture.md` (at `minimal`, the brief's feature group).

按分层处理：Foundation，然后 Core、Feature、Presentation；同一分层内按
系统索引顺序（在 `minimal` 下，按简报的构建顺序）。对每个系统，其模块取自
`architecture.md`（在 `minimal` 下，取自简报的功能分组）。

**Requirement coverage** (not at `minimal`). Each TR-ID of the system is:

**需求覆盖**（非 `minimal`）。系统的每个 TR-ID 为：

- **covered** when an **Accepted** ADR addresses it;
- **untraced** otherwise. A requirement whose only ADR is `Proposed` (or any other
  status) is untraced, never covered: its row reads `❌ No ADR (ADR-NNNN Proposed)`,
  so `/create-stories` still sees that ADR and blocks its story.

- 当有**已接受** ADR 处理它时，为**已覆盖**；
- 否则为**未追溯**。仅有 `Proposed`（或任何其他状态）ADR 的需求即为未追溯，绝不算已覆盖：
  其行读作 `❌ No ADR (ADR-NNNN Proposed)`，这样 `/create-stories` 仍能看到该 ADR 并阻塞其故事。

Untraced requirements are listed under **Untraced Requirements**. The ⚠️ warning
below is for each untraced requirement at `full`, and only for untraced
Foundation-layer requirements at `standard`; any other untraced requirement at
`standard` is listed as information, with no warning.

未追溯需求列在 **Untraced Requirements** 下。下面的 ⚠️ 警告在 `full` 下针对每个未追溯需求，
在 `standard` 下仅针对未追溯的 Foundation 层需求；`standard` 下任何其他未追溯需求作为信息列出，
不附警告。

```
## Epic: [System Name]
**Layer**: [Foundation | Core | Feature | Presentation]
**GDD**: design/gdd/[file].md   (at minimal: design/game-brief.md, MVP features [list])
**Architecture Module**: [module]
**Governing ADRs**: [Accepted ADRs, or "none"]
**Engine Risk**: [LOW | MEDIUM | HIGH — the highest among governing ADRs, else VERSION.md's]
**Requirements covered by Accepted ADRs**: [n / total]
**Untraced Requirements**: [TR-IDs with why, or "None"]
```

The warning, when it applies: "⚠️ [N] requirements in [system] have no Accepted ADR.
Their stories will be written with no governing ADR, or Blocked on a Proposed one.
Run `/architecture-decision` first if they need a decision, or go on and accept the
gap."

警告（在适用时）：“⚠️ [system] 中有 [N] 条需求没有已接受 ADR。
其故事将在没有管辖 ADR 的情况下编写，或因 Proposed ADR 而 Blocked。
若它们需要决策，请先运行 `/architecture-decision`，或继续并接受该
缺口。”

Then ask, **for this epic alone**: "Shall I create Epic: [name]?" Options: Yes,
create it / Skip this epic / Pause — I need to write ADRs first. Show and ask the
next epic only after this answer. Never fold several epics into one question.

然后**仅针对此史诗**询问：“我可以创建 Epic: [name] 吗？”选项：Yes,
create it / Skip this epic / Pause — I need to write ADRs first。只有在此答案之后才展示并询问
下一个史诗。绝不把多个史诗合并到一个问题中。

A yes covers the epic it answers, and only that one, even when it is worded for all
("all of it", "go ahead with everything"): an epic is approved on sight. Show the
next epic's block and ask again, until every epic in scope has been shown and
answered.

一个“是”只涵盖它所回答的那个史诗，且仅此一个，即使措辞针对全部
（“all of it”、“go ahead with everything”）：史诗是看一眼即批准。展示
下一个史诗的块并再次询问，直到范围内每个史诗都已展示并
得到答复。

## Phase 4: Producer review

## 阶段 4：制作人评审

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): no agent; note
`PR-EPIC skipped — [Solo | Lean] mode` in the reply and the closing block.
`skill-gates=run`: read `references/pr-epic-gate.md` and
`.claude/docs/director-gates.md`, and run it now, after every epic in scope is
defined and before any write. On a skip, do not load it.

读取上方的 `review_gate` 行。`skill-gates=skip`（solo 或 lean）：不启用智能体；在回复与收尾块中
注明 `PR-EPIC skipped — [Solo | Lean] mode`。`skill-gates=run`：读取 `references/pr-epic-gate.md` 与
`.claude/docs/director-gates.md`，并在范围内每个史诗都已定义、且在任何写入之前，立即运行。
跳过时不要加载它。

## Phase 5: Write each epic

## 阶段 5：写入每个史诗

For each epic the user said yes to, in order:

对用户同意的每个史诗，按顺序：

**Already has an `EPIC.md`:** never overwrite it. Ask "An EPIC.md already exists for
[name]. Update it in place, or skip it?" Options: Update in place / Skip this epic.
An update edits only what this skill owns (the header fields other than Stories,
Overview, Governing ADRs, GDD Requirements, Definition of Done) and leaves the
`**Stories**` line and any `## Stories` table as they are: `/create-stories` wrote
them, and resetting them orphans the stories already there.

**已有 `EPIC.md`：** 绝不覆盖它。询问“已存在 [name] 的 EPIC.md。
原地更新它，还是跳过？”选项：Update in place / Skip this epic。
更新只编辑本技能所拥有的内容（Stories 之外的头部字段、
Overview、Governing ADRs、GDD Requirements、Definition of Done），并保持
`**Stories**` 行与任何 `## Stories` 表原样：它们是 `/create-stories` 写的，
重置它们会使已有故事变成孤儿。

**New:** ask "May I write `production/epics/[epic-slug]/EPIC.md` and add its row to
`production/epics/index.md`[, creating it]?" This is its own ask, one per epic, after
the Phase 3 yes: that yes approved the epic, not the write. Write only on an explicit
yes to it. Right
before writing, run `bash .claude/scripts/write-guard.sh overwrite
production/epics/[epic-slug]/EPIC.md`. It always prints a `checked` row; an
`OVERWRITE` row back means the file exists after all, so write nothing and ask the
update question instead.

**新建：** 询问“我可以写入 `production/epics/[epic-slug]/EPIC.md` 并将其行添加到
`production/epics/index.md`[, creating it] 吗？”这是它自己的询问，每个史诗一次，在
阶段 3 的同意之后：那次同意批准的是史诗，不是写入。仅在对它的明确
同意时写入。就在
写入之前，运行 `bash .claude/scripts/write-guard.sh overwrite
production/epics/[epic-slug]/EPIC.md`。它总是打印一行 `checked`；若返回
`OVERWRITE` 行，说明文件终究存在，此时不要写入，改为询问更新问题。

`docs.density` sets the depth of the Overview (`terse` bullets, `balanced` a short
paragraph, `thorough` full prose with ADR rationale and risks); the tables stay
whole at every density.

`docs.density` 设定 Overview 的深度（`terse` 为要点条目，`balanced` 为简短段落，
`thorough` 为完整散文并含 ADR 理由与风险）；表格在每个密度下都保持完整。

```markdown
# Epic: [System Name]

> **Layer**: [Foundation | Core | Feature | Presentation]
> **GDD**: design/gdd/[file].md
> **Architecture Module**: [module]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[What this epic implements, from the GDD Overview and the module's responsibilities]

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-NNNN: [title] | [one line] | LOW/MEDIUM/HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from the registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR (ADR-NNNN Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/[file].md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
```

At `minimal`, the GDD line names `design/game-brief.md`, the Governing ADRs and GDD
Requirements tables are left out, and a **Scope** list holds the epic's MVP
features in Build order.

在 `minimal` 下，GDD 行点名 `design/game-brief.md`，Governing ADRs 与 GDD
Requirements 表被省略，并以 **Scope** 列表按构建顺序列出该史诗的 MVP
功能。

**`production/epics/index.md`:** one row per epic. An epic that already has a row
keeps it: update it in place, never add a second row, never reset its Stories cell.

**`production/epics/index.md`：** 每个史诗一行。已有行的史诗保留该行：
原地更新，绝不添加第二行，绝不重置其 Stories 单元格。

```markdown
# Epics Index

Last Updated: [date]
Engine: [name version]

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [name] | [layer] | [system] | [file] | Not yet created | Ready |
```

## Phase 6: Close

## 阶段 6：收尾

At `standard` and `full`, once Foundation and Core epics exist, add: "Foundation and
Core epics are what the Pre-Production → Production gate needs. `/gate-check
production` checks readiness." Never at `minimal`.

在 `standard` 与 `full` 下，一旦 Foundation 与 Core 史诗存在，补充：“Foundation 与
Core 史诗正是前期制作 → 制作门禁所需。`/gate-check
production` 会检查就绪状态。”绝不在 `minimal` 下。

Every epic's content comes from the GDDs, ADRs and architecture docs (the brief at
`minimal`); none is invented.

每个史诗的内容都来自 GDD、ADR 与架构文档（`minimal` 下为简报）；没有一条是凭空编造的。

**The run's last reply ends with this block** (repeat it if you showed it earlier):

**本次运行的最后一次回复以本块结束**（若你此前已展示过，则重复它）：

```
Verdict: COMPLETE — [N] epics written: [slugs]
Review: [PR-EPIC skipped — Solo mode | skipped — Lean mode | its verdict]
Index: production/epics/index.md [created | updated]
Next step: /create-stories [first-epic-slug]
```

When the user skipped or declined every epic: `Verdict: BLOCKED — no epic written
([why])`. No in-scope system found: `Verdict: BLOCKED — no eligible systems in
[scope]`.

当用户跳过或拒绝每个史诗时：`Verdict: BLOCKED — no epic written
([why])`。未找到在范围内系统：`Verdict: BLOCKED — no eligible systems in
[scope]`。
