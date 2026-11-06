# /create-architecture — Phases 7 and 7b: Write and Sign-Off
# /create-architecture — 阶段 7 与 7b：写入与签核

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 7: Write the Master Architecture Document
## 阶段 7：写入主架构文档

**In this file:**
**本文件内容：**

- Phase 7: the master architecture document template, then the write
- 阶段 7：主架构文档模板，然后写入
- Phase 7b: Technical Director Sign-Off + Lead Programmer Feasibility Review: review mode check, presenting both assessments, recording the sign-off
- 阶段 7b：技术总监签核 + 主程序员可行性评审：评审模式检查、呈现两项评估、记录签核

Once all sections are approved, write the complete document to
`docs/architecture/architecture.md`.
一旦所有小节都获得批准，将完整文档写入 `docs/architecture/architecture.md`。

In an update (Phase 0e `[A]`, or a focus-area argument), write only the chosen
sections instead, replacing each in place with `Edit`, and raise `Version`; the
ask below then names those sections and the version change.
在更新情形下（阶段 0e 的 `[A]`，或聚焦领域参数），改为只写入选定的小节，用
`Edit` 就地替换每一个，并提升 `Version`；下面的询问随后会点名那些小节以及版本
变化。

Display a one-paragraph summary of what the document will contain (layers, modules, data flows, ADR gaps). Then use `AskUserQuestion`:
显示一段摘要，说明文档将包含什么（分层、模块、数据流、ADR 缺口）。然后使用
`AskUserQuestion`：
- "All sections approved. May I write the master architecture document?"
  - [A] Yes — write to `docs/architecture/architecture.md` now
  - [B] Show me the full draft inline first, then ask again
  - [C] Not yet — I have more changes to discuss
- "All sections approved. May I write the master architecture document?"
  （所有小节均已批准。我可以写入主架构文档吗？）
  - [A] Yes — write to `docs/architecture/architecture.md` now
    （是 — 立即写入 `docs/architecture/architecture.md`）
  - [B] Show me the full draft inline first, then ask again
    （先内联给我看完整草稿，然后再问一次）
  - [C] Not yet — I have more changes to discuss
    （暂不 — 我还有更多修改要讨论）

The document structure:
文档结构：

```markdown
# [Game Name] — Master Architecture

## Document Status
- Version: [N]
- Last Updated: [date]
- Engine: [name + version]
- GDDs Covered: [list]
- ADRs Referenced: [list]

## Engine Knowledge Gap Summary
[Condensed from Phase 0d inventory — HIGH/MEDIUM risk domains and their implications]

## System Layer Map
[From Phase 1]

## Module Ownership
[From Phase 2]

## Data Flow
[From Phase 3]

## API Boundaries
[From Phase 4]

## ADR Audit
[From Phase 5]

## Required ADRs
[From Phase 6]

## Architecture Principles
[3-5 key principles that govern all technical decisions for this project,
derived from the game concept, GDDs, and technical preferences]

## Open Questions
[Decisions deferred — must be resolved before the relevant layer is built]
```

```markdown
# [游戏名称] — 主架构

## 文档状态
- Version: [N]
- Last Updated: [日期]
- Engine: [名称 + 版本]
- GDDs Covered: [列表]
- ADRs Referenced: [列表]

## 引擎知识缺口摘要
[摘自阶段 0d 清单 — HIGH/MEDIUM 风险领域及其影响]

## 系统分层图
[来自阶段 1]

## 模块归属
[来自阶段 2]

## 数据流
[来自阶段 3]

## API 边界
[来自阶段 4]

## ADR 审计
[来自阶段 5]

## 必要 ADR
[来自阶段 6]

## 架构原则
[3-5 条支配本项目所有技术决策的关键原则，
源自游戏概念、GDD 和技术偏好]

## 开放问题
[推迟的决策 — 必须在构建相关层之前解决]
```

---

## Phase 7b: Technical Director Sign-Off + Lead Programmer Feasibility Review
## 阶段 7b：技术总监签核 + 主程序员可行性评审

After writing the master architecture document, perform an explicit sign-off before handoff.
在写入主架构文档之后，在交接之前执行一次明确的签核。

**Review mode check** — apply before spawning either gate:
**评审模式检查** — 在启动任一门禁之前应用：
- `solo` → skip both. Note: "TD-ARCHITECTURE and LP-FEASIBILITY skipped — Solo mode." Go to Step 4 and record both as skipped, then Phase 8.
- `solo` → 两者都跳过。注明："TD-ARCHITECTURE and LP-FEASIBILITY skipped — Solo mode."（已跳过，Solo 模式。）转到步骤 4 并将两者记录为已跳过，然后进入阶段 8。
- `lean` → skip both (neither is a PHASE-GATE). Note: "TD-ARCHITECTURE and LP-FEASIBILITY skipped — Lean mode." Go to Step 4 and record both as skipped, then Phase 8.
- `lean` → 两者都跳过（二者都不是 PHASE-GATE）。注明："TD-ARCHITECTURE and LP-FEASIBILITY skipped — Lean mode."（已跳过，Lean 模式。）转到步骤 4 并将两者记录为已跳过，然后进入阶段 8。
- `full` → spawn both, in parallel.
- `full` → 并行启动两者。

**Step 1 — Spawn `technical-director` via `Agent` using gate TD-ARCHITECTURE (`.claude/docs/director-gates/td-architecture.md`):**
**步骤 1 — 使用门禁 TD-ARCHITECTURE（`.claude/docs/director-gates/td-architecture.md`）通过 `Agent` 启动 `technical-director`：**

Pass: the architecture document path (`docs/architecture/architecture.md`), the Technical Requirements Baseline (TR-IDs and count), the ADR list with statuses, and the Engine Knowledge Gap Inventory from Phase 0d. Issue this call and Step 2's before waiting for either result.
传入：架构文档路径（`docs/architecture/architecture.md`）、技术需求基线（TR-ID 和
数量）、带状态的 ADR 清单，以及来自阶段 0d 的引擎知识缺口清单。在等待任一结果
之前，先发出本次调用和步骤 2 的调用。

**Step 2 — Spawn `lead-programmer` via `Agent` using gate LP-FEASIBILITY (`.claude/docs/director-gates/lp-feasibility.md`):**
**步骤 2 — 使用门禁 LP-FEASIBILITY（`.claude/docs/director-gates/lp-feasibility.md`）通过 `Agent` 启动 `lead-programmer`：**

Pass: architecture document path, technical requirements baseline summary, ADR list.
传入：架构文档路径、技术需求基线摘要、ADR 清单。

**Step 3 — Present both assessments to the user:**
**步骤 3 — 向用户呈现两项评估：**

Show the TD-ARCHITECTURE verdict (APPROVE / CONCERNS / REJECT) and the LP-FEASIBILITY verdict (FEASIBLE / CONCERNS / INFEASIBLE) side by side.
并排展示 TD-ARCHITECTURE 裁决（APPROVE / CONCERNS / REJECT）与 LP-FEASIBILITY
裁决（FEASIBLE / CONCERNS / INFEASIBLE）。

Use `AskUserQuestion` — "Technical Director and Lead Programmer have reviewed the architecture. How would you like to proceed?"
Options: `Accept — proceed to handoff` / `Revise flagged items first` / `Discuss specific concerns`.
If either verdict is REJECT or INFEASIBLE, do not offer `Accept` — the blockers are revised (or discussed) first.
`Revise flagged items first` re-drafts each flagged section and shows it for approval as in Phases 1–4; the revised document is then written once, through Phase 7's ask, and Step 4 records `REVISED after [verdict]`.
A `NOT ASSESSED` answer is never recorded as `APPROVE` or `FEASIBLE`: Step 4 records it with the input that was missing (`director-gates.md`).
使用 `AskUserQuestion` — "Technical Director and Lead Programmer have reviewed the architecture. How would you like to proceed?"（技术总监和主程序员已评审了架构。你希望如何继续？）
选项：`Accept — proceed to handoff`（接受 — 进入交接）/ `Revise flagged items first`（先修订被标记的条目）/ `Discuss specific concerns`（讨论具体顾虑）。
若任一裁决为 REJECT 或 INFEASIBLE，不要提供 `Accept` — 必须先修订（或讨论）阻塞项。
`Revise flagged items first` 会重新起草每个被标记的小节，并像阶段 1–4 那样展示以供批准；随后修订后的文档经由阶段 7 的询问一次性写入，而步骤 4 记录 `REVISED after [verdict]`。
`NOT ASSESSED` 的答复绝不记录为 `APPROVE` 或 `FEASIBLE`：步骤 4 会连同缺失的输入一并记录它（`director-gates.md`）。

**Step 4 — Record sign-off in the architecture document:**
**步骤 4 — 在架构文档中记录签核：**

Update the Document Status section:
更新 Document Status 小节：
```
- TD-ARCHITECTURE: [date] — APPROVE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after REJECT / NOT ASSESSED — [missing input] / skipped — [mode] mode
- LP-FEASIBILITY: [date] — FEASIBLE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after INFEASIBLE / NOT ASSESSED — [missing input] / skipped — [mode] mode
```

Show the proposed Document Status block inline, then use `AskUserQuestion`:
内联展示拟议的 Document Status 块，然后使用 `AskUserQuestion`：
- "May I update the Document Status section with the sign-off results?"
  - [A] Yes — apply to `docs/architecture/architecture.md`
  - [B] Not yet — I want to revisit the concerns first
- "May I update the Document Status section with the sign-off results?"
  （我可以将签核结果更新到 Document Status 小节吗？）
  - [A] Yes — apply to `docs/architecture/architecture.md`
    （是 — 应用到 `docs/architecture/architecture.md`）
  - [B] Not yet — I want to revisit the concerns first
    （暂不 — 我想先重新审视这些顾虑）

---
