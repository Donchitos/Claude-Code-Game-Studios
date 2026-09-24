---
name: milestone-review
description: "Milestone progress review — completeness, quality metrics, risk, go/no-go recommendation. At checkpoints or before a deadline."
argument-hint: "[milestone-name|current] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`



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
specific and has been observed in practice: report templates whose verdict
enum had no "could not run" state produced **false clean passes** — an asset audit
returning COMPLIANT on a project with no assets and no standards, and a
performance profile reporting ">99% headroom against a 16.67ms budget" with zero
profiler data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 0: Parse Arguments

Extract the milestone name (`current` or a specific name).

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

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

> **These alternates are copied from `/sprint-plan`'s emitted headings — keep
> them in sync with it, not with what a milestone review wishes existed.** The
> previous pattern asked for `Summary|Goal|Velocity|Completed|Blockers|
> Retrospective`, none of which `/sprint-plan` writes (it emits `## Sprint
> Goal`, not `## Goal`). Only `Carryover` matched — and that was the trap: a
> non-zero match count meant the zero-match escape hatch below could never
> fire, so every milestone review silently aggregated carryover tables and
> nothing else while reporting full coverage.

Full-read a single sprint report when its scanned sections point outside
themselves, or when it matched nothing — a zero-match report predates the
template and must be read, never silently dropped from the milestone's history.
Report any sprint that contributed nothing: a milestone summary that quietly
omits a sprint understates the work and the slippage both.

---

## Phase 2: Scan Codebase Health

- Scan for `TODO`, `FIXME`, `HACK` markers that indicate incomplete work
- Check the risk register at `production/risk-register/` if it exists (hand-authored from `.claude/docs/templates/risk-register-entry.md`; no skill writes it, so absence is normal — note it rather than skipping risk assessment silently)

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
| Feature | Acceptance Criteria | Test Status |
|---------|-------------------|-------------|

### Partially Complete
| Feature | % Done | Remaining Work | Risk to Milestone |
|---------|--------|---------------|------------------|

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

Do not issue a GO against an OFF TRACK verdict unless the user explicitly selects [B] above.

---

## Phase 4: Save Review

Present the review to the user.

Ask: "May I write this to `production/milestones/[milestone-name]-review.md`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — milestone review saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 5: Next Steps

- Run `/gate-check` for a formal phase gate verdict if this milestone marks a development phase boundary.
- Run `/sprint-plan` to adjust the next sprint based on the scope recommendations above.
