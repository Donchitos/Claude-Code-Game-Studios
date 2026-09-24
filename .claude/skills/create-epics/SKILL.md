---
name: create-epics
description: "Turn GDDs plus architecture into epics — one per architectural module, with untraced requirements. Then /create-stories [epic-slug]."
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Create Epics

An epic is a named, bounded body of work that maps to one architectural module.
It defines **what** needs to be built and **who owns it architecturally**. It
does not prescribe implementation steps — that is the job of stories.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the design
will have changed.

**Output:** `production/epics/[epic-slug]/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass
(at `full`). At `standard`, critical ADRs + a control manifest suffice. At
`minimal`, this skill is **optional and not part of the path** — `/create-stories`
synthesizes the epic from `design/game-brief.md` itself (Option A). If run anyway,
it decomposes directly from the brief with no GDD/ADR/manifest prerequisite.

> **At `minimal`, this skill is optional — `/create-stories` synthesizes the epic**
> (Option A). At that tier `/create-stories` reads `design/game-brief.md`
> directly, writes a lightweight implicit `production/epics/<slug>/EPIC.md`, and
> generates stories from the MVP list — so the path is `/brainstorm` →
> `/create-stories` → `/dev-story`, with no separate `/create-epics` or
> `/sprint-plan` step. **At `standard`/`full` an epic IS required**:
> `/create-stories` reads `production/epics/[slug]/EPIC.md`, and skipping this
> skill there leaves `/dev-story` with no story to implement — a dead end, not a
> shortcut.

---

## 1. Parse Arguments


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (per `.claude/docs/workflow-modes.md`):

create-epics runs project-wide: it uses the project-level tier for its
prerequisite expectations and consults
`workflow_overrides.system_overrides.<system>` per-system when reading each
in-scope GDD. See "Workflow tier adjustment" in Step 2.

**`story_granularity`** — it sizes the
epic's story breakdown: expect **3–5** child stories per epic at `coarse`, **5–10**
at `balanced` (default), **10–20** at `fine`.

**`docs.density`** — it controls the *depth* of each epic's written scope and
rationale, not the story count (that is `story_granularity`). `modes.rigor` sets
it alongside `workflow`; set `docs.density` explicitly to vary epic prose alone:
`terse` = scope as bullets, one-line rationale; `balanced` = a scope paragraph
with light rationale (default); `thorough` = full scope prose with governing-ADR
rationale and risk discussion. The EPIC.md tables (GDD requirements, governing
ADRs) are structural and stay whole at every density.

**Modes:**
- `/create-epics all` — process all systems in layer order
- `/create-epics layer: foundation` — Foundation layer only
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [system-name]` — one specific system
- No argument — ask: "Which layer or system would you like to create epics for?"

---

## 2. Load Inputs

### Step 2a — Summary scan (fast, fail-open)

**Establish the denominator first.** Glob `design/gdd/*.md`, excluding the
non-system docs (`game-concept.md`, `systems-index.md`, `game-pillars.md`,
`gameplay-tags.md`, `entity-registry.md`, `fixture-swap-ledger.md`, and any
`gdd-cross-review-*.md` — the same set `gdd-structure-check.sh` skips). Call the
count **N**. If N is 0, there are no system GDDs — report "No system GDDs found
in `design/gdd/` — run `/design-system` first" and stop.

Scan for Summary sections:

```
Grep pattern="^## Summary" glob="design/gdd/*.md" output_mode="content" -A 5
```

Interpret the **M** matches against N. These are three different outcomes, and
a zero-match scan is **never** the same as "nothing in scope":

| Result | Meaning | Action |
|---|---|---|
| **M = N** | Every GDD has a Summary. | For `layer:`/`[system-name]` modes, use the Summary Quick-reference (Layer/Priority) to pick the in-scope set; skip full-reading the rest. |
| **0 < M < N** | Partial adoption — older GDDs predate `## Summary`. | Scope the M by their Summaries; determine the scope of the **N − M** unmatched from `systems-index.md` (layer/priority) and full-read those. |
| **0 matches, N > 0** | Expected for GDDs authored before `/design-system` emitted `## Summary`. | Determine scope for **all N** from `systems-index.md` and full-read the in-scope set. This is the pre-optimization behaviour — correct, only more expensive. Note once: "No `## Summary` sections found across [N] GDDs — scoping from `systems-index.md` instead of Summary." |

**Never treat an absent `## Summary` as an absent system.** The scan narrows the
*read* set when it succeeds; it never shrinks the *in-scope* set. In `all` mode
every system is in scope regardless of Summary, so the scan is a convenience
only — never a filter.

### Step 2b — Full document load (in-scope systems only)

Using the Step 2a grep results, identify which systems are in scope. Read full documents **only for in-scope systems** — do not read GDDs or ADRs for out-of-scope systems or layers.

Read for in-scope systems:

- `design/gdd/systems-index.md` — authoritative system list, layers, priority
- In-scope GDDs only (Approved or Designed status, filtered by Step 2a results)
- `docs/architecture/architecture.md` — module ownership and API boundaries
- Accepted ADRs **whose domains cover in-scope systems only** — skip ADRs for
  unrelated domains entirely. For each in-scope ADR, load only the "GDD
  Requirements Addressed", "Decision", and "Engine Compatibility" sections —
  never an unbounded full read:
  ```
  Grep pattern="^## (GDD Requirements Addressed|Decision|Engine Compatibility)" path="docs/architecture/[adr-file].md" output_mode="content" -n
  ```
  then `Read(offset, limit)` bounded to each match through the next `## `
  heading (or to end of file for the last match). This matters most on a
  large ADR — measured at 47k tokens this way vs. 103k for an unbounded
  read of the same size file.
- `docs/architecture/control-manifest.md` — manifest version date from header
- `docs/architecture/tr-registry.yaml` — for tracing requirements to ADR coverage
- `docs/engine-reference/[engine]/VERSION.md` — engine name, version, risk levels

Report: "Loaded [N] GDDs, [M] ADRs, engine: [name + version]."

> **Workflow tier adjustment** (resolved in Step 1; per-system via
> `system_overrides`). The inputs above are the `full` baseline:
> - **`full`** — every in-scope GDD must be Approved with all 8 sections; TR
>   registry + control manifest are required inputs; untraced requirements
>   (Step 4) are flagged before proceeding.
> - **`standard`** — GDDs need the 5 required sections (+ conditional Formulas)
>   approved; only **critical (Foundation-layer) ADRs** are expected; the control
>   manifest is read if present, not required. A system pinned higher via
>   `system_overrides` must still meet its higher bar.
> - **`minimal`** — decompose against `design/game-brief.md` +
>   acceptance criteria. Do not require GDDs, ADRs, the TR registry, or the
>   manifest; skip the untraced-requirement gate. If run, the epic is still
>   produced — but note `/create-stories` also synthesizes one from the brief when
>   this skill is skipped (the default `minimal` path).

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies)
2. **Core** (depends on Foundation)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

Within each layer, use the order from `systems-index.md`.

> **At `minimal` there is no `systems-index.md`** — `/map-systems` is not required
> at that tier, so nothing has produced one. Derive the layer split and ordering
> from `design/game-brief.md` instead: its **Build order** field names what must
> exist first. Do not stop, and do not send the user to `/map-systems` to satisfy
> an ordering hint — the tier deliberately skips it.

---

## 4. Define Each Epic

For each system, map it to an architectural module from `architecture.md`.

Check ADR coverage against the TR registry **per the resolved tier** (Step 1):
- **`full`** — trace every TR-ID; warn on each untraced requirement (below).
- **`standard`** — only **critical (Foundation-layer) ADRs** are expected; trace
  those. Treat untraced non-critical requirements as informational (list them, do
  not block or emit the Blocked-story warning).
- **`minimal`** — skip this check entirely (no TR registry / ADR expected).

- **Traced requirements**: TR-IDs that have an Accepted ADR covering them
- **Untraced requirements**: TR-IDs with no ADR — warn before proceeding (full only)

Present to user before writing anything:

```
## Epic: [System Name]

**Layer**: [Foundation / Core / Feature / Presentation]
**GDD**: design/gdd/[filename].md
**Architecture Module**: [module name from architecture.md]
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Engine Risk**: [LOW / MEDIUM / HIGH — highest risk among governing ADRs]
**GDD Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list TR-IDs with no ADR, or "None"]
```

If there are untraced requirements:
> "⚠️ [N] requirements in [system] have no ADR. The epic can be created, but
> stories for these requirements will be marked Blocked until ADRs exist.
> Run `/architecture-decision` first, or proceed with placeholders."

Use `AskUserQuestion`:
- Prompt: "Shall I create Epic: [name]?"
- Options:
  - `[A] Yes, create it`
  - `[B] Skip this epic`
  - `[C] Pause — I need to write ADRs first`

---

## 4b. Producer Epic Structure Gate

**Review mode check** — apply before spawning PR-EPIC:
- `solo` → skip. Note: "PR-EPIC skipped — Solo mode." Proceed to Step 5 (write epic files).
- `lean` → skip (not a PHASE-GATE). Note: "PR-EPIC skipped — Lean mode." Proceed to Step 5 (write epic files).
- `full` → spawn as normal.

After all epics for the current layer are defined (Step 4 completed for all in-scope systems), and before writing any files, spawn `producer` via `Agent` using gate **PR-EPIC** (`.claude/docs/director-gates/pr-epic.md`).

Pass: the full epic structure summary (all epics, their scope summaries, governing ADR counts), the layer being processed, milestone timeline and team capacity.

Present the producer's assessment.

If UNREALISTIC: offer to revise epic boundaries (split overscoped or merge underscoped epics). Revise and re-run the gate before writing.

If CONCERNS, use `AskUserQuestion`:
- Prompt: "Producer raised concerns about the epic structure. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the producer's concerns`
  - `[B] Revise epic boundaries — split or merge as recommended`
  - `[C] Stop — I want to reconsider the scope`

If [A]: proceed to Step 5.
If [B]: revise epic definitions from Step 4 and re-run the producer gate.
If [C]: stop. Verdict: **BLOCKED** — user wants to reconsider epic scope.

Do not write epic files until the producer gate resolves.

---

## 5. Write Epic Files

After approval, ask: "May I write the epic file to `production/epics/[epic-slug]/EPIC.md`?"

After user confirms, write:

### `production/epics/[epic-slug]/EPIC.md`

```markdown
# Epic: [System Name]

> **Layer**: [Foundation / Core / Feature / Presentation]
> **GDD**: design/gdd/[filename].md
> **Architecture Module**: [module name]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[1 paragraph describing what this epic implements, derived from the GDD Overview
and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/[filename].md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

### Update `production/epics/index.md`

Create or update the master index:

```markdown
# Epics Index

Last Updated: [date]
Engine: [name + version]

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [name] | Foundation | [system] | [file] | Not yet created | Ready |
```

---

## 6. Gate-Check Reminder

After writing all epics for the requested scope:

- **Foundation + Core complete**: These are required for the Pre-Production →
  Production gate. Run `/gate-check production` to check readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before developers can pick up work.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **One epic at a time** — present each epic definition before asking to create it
2. **Warn on gaps** — flag untraced requirements before proceeding
3. **Ask before writing** — per-epic approval before writing any file
4. **No invention** — all content comes from GDDs, ADRs, and architecture docs
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: BLOCKED** — user declined all epics, or no eligible systems found.
