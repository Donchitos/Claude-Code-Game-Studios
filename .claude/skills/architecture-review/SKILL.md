---
name: architecture-review
description: "Traceability matrix mapping GDD requirements to ADRs. Finds gaps, cross-ADR conflicts, engine compatibility. PASS/CONCERNS/NOT ASSESSED/FAIL."
argument-hint: "[focus: full | coverage | consistency | engine | single-gdd path/to/gdd.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-review/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`



# Architecture Review

The architecture review validates that the complete body of architectural decisions
covers all game design requirements, is internally consistent, and correctly targets
the project's pinned engine version. It is the quality gate between Technical Setup
and Pre-Production.

**Argument modes:**
- **No argument / `full`**: Full review — all phases
- **`coverage`**: Traceability only — which GDD requirements have no ADR
- **`consistency`**: Cross-ADR conflict detection only
- **`engine`**: Engine compatibility audit only
- **`single-gdd [path]`**: Review architecture coverage for one specific GDD
- **`rtm`**: Requirements Traceability Matrix — extends the standard matrix
  to include story file paths and test file paths; outputs
  `docs/architecture/requirements-traceability.md` with the full
  GDD requirement → ADR → Story → Test chain. Use in Production phase when
  stories and tests exist.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full traceability matrix across all GDDs and all ADRs.
- `standard` — reduced scope: architecture doc + critical ADRs only.
- `minimal` — not applicable (no architecture doc required).

## Phase 1: Load Everything

### Phase 1a — L0: Summary Scan (fast, low tokens)

**Freshness check before any scan.** Locate the latest prior report — Glob
`docs/architecture/architecture-review-*.md` and take the newest — then:

```
Bash: bash .claude/scripts/review-receipts.sh check "[latest-report]" docs/architecture/adr-*.md design/gdd/*.md
```

- **Any `UNRESOLVED`** — check this FIRST; it disqualifies every option
  below. One of the two globs matched no file, so that whole document class
  was never examined and the comparison covered less than it appears to.
  Say which pattern came back unresolved and stop: an ADR or GDD directory
  that is empty, renamed or misspelled is a finding about the project, not a
  reason to stand on a prior report. Never read a set of `UNCHANGED` lines as
  "everything is current" while an `UNRESOLVED` line is present — the set
  compared was not the set requested.
- **Everything `UNCHANGED`** (and no `UNRESOLVED`) — nothing this review
  reads has changed since that report; re-running reproduces it. Surface the
  prior report's date and verdict and offer via `AskUserQuestion`: `[A] Stand
  on the prior report (Recommended)` / `[B] Re-run the full review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and stands on the prior report.
- **Some `CHANGED`/`NEW`** — name them, then scope instead of re-running
  everything: recommend `/architecture-review [system]` (single-system mode)
  for just the changed systems. A full re-run stays available on request,
  and structural changes (a `NEW` ADR, a deleted file) warrant one.
- **`RECEIPT: NONE`** — no prior report, or one written before receipts
  existed. Proceed with the full review; this run's report will carry the
  first stamps.

Before reading any full document, use Grep to extract `## Summary` sections
from all GDDs and ADRs:

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/gdd/*.md` and count **N**. A scan matching fewer than N means those GDDs
predate `## Summary` (`/design-system` emits it, but older GDDs lack it) — never
treat an absent Summary as a system out of scope. A zero-match scan means "no GDD
carries a Summary yet", not "nothing to review": full-read the unmatched set.

For `single-gdd [path]` mode: use the target GDD's summary to identify which
ADRs reference the same system (Grep ADRs for the system name), then load only
those ADRs' sections per Phase 1b. Skip unrelated GDDs entirely.

For `engine` mode: load ADR sections only — GDDs are not needed for engine checks.
In practice this is the `## Engine Compatibility` scan alone.

For `coverage` or `full` mode: proceed to Phase 1b for the full in-scope set.
**This is a section load, not a full-file load** — see below for why, and for the
narrow cases that still justify escalating to a whole document.

### Phase 1b — L1/L2: Targeted Section Load

Load the sections the later phases actually consume — **not whole files**. This
skill reads the two largest document sets in the project (every GDD *and* every
ADR); at realistic sizes a full load of both exhausts the context window before
Phase 2 starts, and most of what it loads is narrative this skill never uses.

**Establish the denominator first.** Glob `design/gdd/*.md` and count **N_gdd**;
glob `docs/architecture/adr-*.md` and count **N_adr**. Report both. A section
scan matching fewer than the denominator means those documents lack the section —
**never treat an absent section as an absent document.** The scan narrows the
*read* set; it never shrinks the *in-scope* set.

### Design Documents

Phase 2 extracts *technical requirements* — data structures, performance
constraints, engine capabilities, cross-system communication, persistence,
threading, platform needs. Those live in a known set of sections; Overview and
Player Fantasy are narrative and yield none.

```
Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
```

Accept **either** `## Detailed Rules` or `## Detailed Design` — the design
standard and the GDD template disagree on the name and they denote the same
required section. Full-read a single GDD only when a scanned section
cross-references material outside itself, or when a GDD matched zero sections
(it predates the template — read it whole and say so).

- `design/gdd/systems-index.md` — the authoritative list of systems; read whole (small, and it is an index)

### Architecture Documents

Phases 3–5 need the traceability table, the decision itself, engine claims, and
the dependency edges — not Context, Consequences, Alternatives, Migration Plan or
Validation Criteria, which explain *why* a decision was made.

```
Grep pattern="^## (Status|Decision|GDD Requirements Addressed|Engine Compatibility|ADR Dependencies|Performance Implications)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```

Interpret against **N_adr**, and distinguish the two zero-match cases — they are
not the same finding:

| Result | Meaning | Action |
|---|---|---|
| N_adr matches | Normal. | Proceed on the scanned sections. |
| Some ADRs match, some do not | Those ADRs are missing sections. | Record each as a **structural gap** in the Phase 7 report — a missing `## GDD Requirements Addressed` is itself a traceability finding. |
| **0 matches, N_adr > 0** | **Malformed ADRs**, not "no architecture". | "[N_adr] ADRs found, none carries a scannable section — run `/architecture-decision [file] retrofit` on each." Do **not** report zero coverage; that would read as a design failure when it is a format failure. |

Escalate to a full read of one ADR only when judging a conflict needs its
reasoning (Phase 4) — that is a per-ADR decision, not a blanket load.

- `docs/architecture/architecture.md` if it exists

### Engine Reference
- `docs/engine-reference/[engine]/VERSION.md`
- `docs/engine-reference/[engine]/breaking-changes.md`
- `docs/engine-reference/[engine]/deprecated-apis.md`
- **Only the module docs the in-scope ADRs actually name** — take the union of
  each ADR's `References Consulted` and `Post-Cutoff APIs Used` fields (already
  captured by the `## Engine Compatibility` scan above) and read those files.
  Reading the whole `modules/` directory loads engine subsystems the project may
  not use at all. If no ADR names any module, read none and note it: Phase 5
  cannot cross-check engine claims that were never made.

### Project Standards
- `project.yaml` — `naming.*` and `performance.*`; plus `.claude/docs/technical-preferences.md` for those keys when absent and for forbidden patterns / allowed libraries

Report a count: "Loaded [N] GDDs, [M] ADRs, engine: [name + version]."

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the systems under review (Architecture, Engine, or any GDD domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.

---

## Phase 2: Extract Technical Requirements from Every GDD

### Pre-load the TR Registry

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.

For each requirement you extract, the matching rule is:
1. **Exact/near match** to an existing registry entry for the same system →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the GDD wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
2. **No match** → assign a new ID: next available `TR-[system]-NNN` for that
   system, starting from the highest existing sequence + 1.
3. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[system]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the GDD intentionally.

For each GDD, read it and extract all **technical requirements** — things the
architecture must provide for the system to work. A technical requirement is any
statement that implies a specific architectural decision.

Categories to extract:

| Category | Example |
|----------|---------|
| **Data structures** | "Each entity has health, max health, status effects" → needs a component/data schema |
| **Performance constraints** | "Collision detection must run at 60fps with 200 entities" → physics budget ADR |
| **Engine capability** | "Inverse kinematics for character animation" → IK system ADR |
| **Cross-system communication** | "Damage system notifies UI and audio simultaneously" → event/signal architecture ADR |
| **State persistence** | "Player progress persists between sessions" → save system ADR |
| **Threading/timing** | "AI decisions happen off the main thread" → concurrency ADR |
| **Platform requirements** | "Supports keyboard, gamepad, touch" → input system ADR |

For each GDD, produce a structured list:

```
GDD: [filename]
System: [system name]
Technical Requirements:
  TR-[GDD]-001: [requirement text] → Domain: [Physics/Rendering/etc]
  TR-[GDD]-002: [requirement text] → Domain: [...]
```

This becomes the **requirements baseline** — the complete set of what the
architecture must cover.

---

## Phase 3: Build the Traceability Matrix

For each technical requirement extracted in Phase 2, search the ADRs:

1. Use the ADRs **already loaded in Phase 1b** — do not re-read them. Extract each
   ADR's "GDD Requirements Addressed" section from what is already in context.
   (If Phase 1b ran in a mode that did not load every ADR, `Grep pattern="## GDD
   Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content"
   -A 15` fills the gap without a full re-read.)
2. Check if it explicitly references the requirement or its GDD
3. Check if the ADR's decision text implicitly covers the requirement
4. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An **Accepted** ADR explicitly addresses this requirement |
| 🟡 **Covered (Proposed)** | An ADR addresses it, but that ADR is still `Proposed` |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |
| ❓ **Not assessed** | The ADR is unreadable, or has no `## Status` section |

> **Read each ADR's `## Status` before marking coverage — an unaccepted decision
> is not coverage.** If `✅` meant only that *an ADR addresses this*, with no
> status qualification, a requirement covered entirely by `Proposed` ADRs would
> count as covered and this review could return **PASS: All requirements
> covered** over an architecture nobody had accepted. Four skills downstream
> (`create-control-manifest`, `create-epics`, `create-stories`, `gate-check`)
> require `Accepted`, so a PASS on that basis sends work forward that every one
> of them will refuse.
>
> `🟡` is **not** a pass state: it caps the verdict at **CONCERNS**, and names the
> route out — `/architecture-decision accept ADR-NNNN`. That route is the only
> thing that moves an ADR to `Accepted`; without it, grading `Proposed` as
> covered would be the only option, which is why it must never be graded so.

Build the full matrix:

```
## Traceability Matrix

| Requirement ID | GDD | System | Requirement | ADR Coverage | Status |
|---------------|-----|--------|-------------|--------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection < 1 frame | ADR-0003 | ✅ |
| TR-combat-002 | combat.md | Combat | Combo window timing | — | ❌ GAP |
| TR-inventory-001 | inventory.md | Inventory | Persistent item storage | ADR-0005 | ✅ |
```

Count the totals: X covered, Y partial, Z gaps.

---

## Phase 3b: Story and Test Linkage (RTM mode only)

*Skip this phase unless the argument is `rtm` or `full` with stories present.*

This phase extends the Phase 3 matrix to include the story that implements
each requirement and the test that verifies it — producing the full
Requirements Traceability Matrix (RTM).

### Step 3b-1 — Load stories

Glob `production/epics/**/*.md` (excluding EPIC.md index files) to establish the
denominator. Then collect the fields with **targeted section greps, not a full
read of each story** — the same two-grep form `/test-evidence-review` uses for
this identical extraction:

```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="TR-" glob="production/epics/**/story-*.md" output_mode="content"
```

- **TR-ID** — from the second grep.
- **Test file path** — under `## Test Evidence`, captured by the first grep's `-A 8`.
- **Status** — from the story header; add `Grep pattern="^> \*\*Status\*\*"` if not already captured.
- **Story path and title** — from the file name and path; no read at all.

Full-read a story only when its Test Evidence section is missing or ambiguous.

### Step 3b-2 — Load test files

Glob `tests/unit/**/*_test.*` and `tests/integration/**/*_test.*`.
Build an index: system → [test file paths].

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.

### Step 3b-3 — Build the extended RTM

For each TR-ID in the Phase 3 matrix, add:
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Test File**: the test file path stated in the story's Test Evidence section
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated, story type may be Visual/Feel/UI) /
  NO STORY (requirement has no story yet — pre-production gap)

Extended matrix format:

```
## Requirements Traceability Matrix (RTM)

| TR-ID | GDD | Requirement | ADR | Story | Test File | Test Status |
|-------|-----|-------------|-----|-------|-----------|-------------|
| TR-combat-001 | combat.md | Hitbox < 1 frame | ADR-0003 | story-001-hitbox.md | tests/unit/combat/hitbox_test.gd | COVERED |
| TR-combat-002 | combat.md | Combo window | — | story-002-combo.md | — | NONE (Visual/Feel) |
| TR-inventory-001 | inventory.md | Persistent storage | ADR-0005 | — | — | NO STORY |
```

RTM coverage summary:
- COVERED: [N] — requirements with ADR + story + passing test
- MISSING test: [N] — story exists but test file not found
- NO STORY: [N] — requirements with ADR but no story yet
- NO ADR: [N] — requirements without architectural coverage (from Phase 3 gaps)
- Full chain complete (COVERED): [N/total] ([%])

---

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other ADR to detect contradictions. A conflict
exists when:

- **Data ownership conflict**: Two ADRs claim exclusive ownership of the same data
- **Integration contract conflict**: ADR-A assumes System X has interface Y, but
  ADR-B defines System X with a different interface
- **Performance budget conflict**: ADR-A allocates N ms to physics, ADR-B allocates
  N ms to AI, together they exceed the total frame budget
- **Dependency cycle**: ADR-A says System X initialises before Y; ADR-B says Y
  initialises before X
- **Architecture pattern conflict**: ADR-A uses event-driven communication for a
  subsystem; ADR-B uses direct function calls to the same subsystem
- **State management conflict**: Two ADRs define authority over the same game state
  (e.g. both Combat ADR and Character ADR claim to own the health value)

For each conflict found:

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / State]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

After conflict detection, analyse the dependency graph across all ADRs.

**Build the graph deterministically — do not trace it by hand:**

```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It collects every `Depends On` edge, runs Kahn's algorithm, and emits
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `CYCLE:`. A model tracing A→B→C→A across
a dozen ADRs eventually misses an edge; the algorithm cannot. It reports
observations, not a verdict — you apply the meaning below.

**`NO_DEPS_SECTION` is load-bearing**: it makes "no cycles because the graph is
clean" distinguishable from "no cycles because half the ADRs declare no
dependencies". Report the second case as a structural gap, never as a clean graph.

Then interpret:

1. **Topological sort**: the emitted order — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
2. **Flag unresolved dependencies**: cross the `EDGES:` list against the `## Status`
   values already scanned in Phase 1b. If ADR-A depends on an ADR that is still
   `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
3. **Cycle detection**: every `CYCLE:` line the script emitted is a
   `DEPENDENCY CYCLE` — report each one. Do not re-derive them by hand:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
4. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---

## Phase 5: Engine Compatibility Cross-Check

Across all ADRs, check for engine consistency:

### Version Consistency
- Do all ADRs that mention an engine version agree on the same version?
- If any ADR was written for an older engine version, flag it as potentially stale

### Post-Cutoff API Consistency
- Collect all "Post-Cutoff APIs Used" fields from all ADRs
- For each, verify against the relevant module reference doc
- Check that no two ADRs make contradictory assumptions about the same post-cutoff API

### Deprecated API Check
- Grep all ADRs for API names listed in `deprecated-apis.md`
- Flag any ADR referencing a deprecated API

### Missing Engine Compatibility Sections
- List all ADRs that are missing the Engine Compatibility section entirely
- These are blind spots — their engine assumptions are unknown

Output format:
```
### Engine Audit Results
Engine: [name + version]
ADRs with Engine Compatibility section: X / Y total

Deprecated API References:
  - ADR-0002: uses [deprecated API] — deprecated since [version]

Stale Version References:
  - ADR-0001: written for [older version] — current project version is [version]

Post-Cutoff API Conflicts:
  - ADR-0004 and ADR-0007 both use [API] with incompatible assumptions
```

---

### Engine Specialist Consultation

After completing the engine audit above, spawn the **primary engine specialist** via `Agent` for a domain-expert second opinion:
- Resolve the primary specialist: `<engine>-specialist` derived from `engine.name` in `project.yaml` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`); if `engine.name` is absent or empty, read the Primary line of the `## Engine Specialists` section in `.claude/docs/technical-preferences.md`
- If no engine is configured (neither source yields an engine), skip this consultation **Record `Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.
- Spawn `subagent_type: [primary specialist]` with: all ADRs that contain engine-specific decisions or `Post-Cutoff APIs Used` fields, the engine reference docs, and the Phase 5 audit findings. Ask them to:
  1. Confirm or challenge each audit finding — specialists may know of engine nuances not captured in the reference docs
  2. Identify engine-specific anti-patterns in the ADRs that the audit may have missed (e.g., using the wrong Godot node type, Unity component coupling, Unreal subsystem misuse)
  3. Flag ADRs that make assumptions about engine behaviour that differ from the actual pinned version

Incorporate additional findings under `### Engine Specialist Findings` in the Phase 5 output. These feed into the final verdict — specialist-identified issues carry the same weight as audit-identified issues.

---

## Phase 5b: Design Revision Flags (Architecture → GDD Feedback)

For each **HIGH RISK engine finding** from Phase 5, check whether any GDD makes an
assumption that the verified engine reality contradicts.

Specific cases to check:

1. **Post-cutoff API behaviour differs from training-data assumptions**: If an ADR
   records a verified API behaviour that differs from the default LLM assumption,
   check all GDDs that reference the related system. Look for design rules written
   around the old (assumed) behaviour.

2. **Known engine limitations in ADRs**: If an ADR records a known engine limitation
   (e.g. "Jolt ignores HingeJoint3D damp", "D3D12 is now the default backend"), check
   GDDs that design mechanics around the affected feature.

3. **Deprecated API conflicts**: If Phase 5 flagged a deprecated API used in an ADR,
   check whether any GDD contains mechanics that assume the deprecated API's behaviour.

For each conflict found, record it in the GDD Revision Flags table:

```
### GDD Revision Flags (Architecture → Design Feedback)
These GDD assumptions conflict with verified engine behaviour or accepted ADRs.
The GDD should be revised before its system enters implementation.

| GDD | Assumption | Reality (from ADR/engine-reference) | Action |
|-----|-----------|--------------------------------------|--------|
| combat.md | "Use HingeJoint3D damp for weapon recoil" | Jolt ignores damp — ADR-0003 | Revise GDD |
```

If no revision flags are found, write: "No GDD revision flags — all GDD assumptions
are consistent with verified engine behaviour."

Before asking, display the proposed change inline — show the current systems-index row for each flagged GDD and the proposed updated row side by side so the user can see exactly what will change.

Then use `AskUserQuestion`:
- "I found [N] GDD revision flag(s). May I update the systems index?"
  - [A] Yes — apply all [N] updates to the systems index now
  - [B] Show me the full diff first, then ask again
  - [C] No — leave the systems index unchanged for now

If [A]: apply the updates. Status field must be exactly `Needs Revision` — no parentheticals
(other skills match that exact string and parentheticals break the match).
If [B]: display the complete proposed systems-index section, then re-ask with `AskUserQuestion`.

---

## Phase 6: Architecture Document Coverage

**If `docs/architecture/architecture.md` does not exist, say so in the report** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— and carry it into the Phase 7 verdict per the trigger list below. Phase 5
already models this for the engine consultation (*"A skipped check that says
nothing is indistinguishable from a check that passed"*); this phase is the one
that did not. Silently producing no Phase 6 findings reads as an architecture
document that was checked and found clean, which is the opposite of what
happened.

If it exists, validate it against GDDs:

- Does every system from `systems-index.md` appear in the architecture layers?
- Does the data flow section cover all cross-system communication defined in GDDs?
- Do the API boundaries support all integration requirements from GDDs?
- Are there systems in the architecture doc that have no corresponding GDD
  (orphaned architecture)?

---

## Phase 7: Output the Review Report

```
## Architecture Review Report
Date: [date]
Engine: [name + version]
GDDs Reviewed: [N]
ADRs Reviewed: [M]

[output of: Bash: bash .claude/scripts/review-receipts.sh hash docs/architecture/adr-*.md design/gdd/*.md
 — one Reviewed-Content-Hash line per file reviewed; Phase 1a's freshness
 check reads these on the next run to skip or scope an unchanged re-review]

---

### Traceability Summary
Total requirements: [N]
✅ Covered: [X]
⚠️ Partial: [Y]
❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
For each gap:
  ❌ TR-[id]: [GDD] → [system] → [requirement]
     Suggested ADR: "/architecture-decision [suggested title]"
     Domain: [Physics/Rendering/etc]
     Engine Risk: [LOW/MEDIUM/HIGH]

### Cross-ADR Conflicts
[List all conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted implementation order from Phase 4 — dependency ordering section]
[Unresolved dependencies and cycles if any]

### GDD Revision Flags
[GDD assumptions that conflict with verified engine behaviour — from Phase 5b]
[Or: "None — all GDD assumptions consistent with verified engine behaviour"]

### Engine Compatibility Issues
[List all engine issues from Phase 5]

### Architecture Document Coverage
[List missing systems and orphaned architecture from Phase 6]

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: All requirements covered by **Accepted** ADRs, no conflicts, engine consistent
NOT ASSESSED: The review could not be performed over its stated scope — name why
CONCERNS: Some gaps, partial coverage, or coverage resting on `Proposed` ADRs,
      but no blocking conflicts
FAIL: Critical gaps (Foundation/Core layer requirements uncovered),
      or blocking cross-ADR conflicts detected

**`NOT ASSESSED` ranks above PASS and below CONCERNS and FAIL.** Emit it when:

- **No ADRs exist, or none could be read.** Zero requirements traced is not full
  coverage — it is an untraced architecture, and a matrix of `❌ Gap` rows at
  least says so while an empty matrix says nothing.
- **The requirement source is missing** — no `tr-registry.yaml` and no GDD
  requirements to trace *from*. A review with no left-hand column cannot report
  coverage; it can only report that it had nothing to compare.
- **An ADR is unreadable or has no `## Status`**, so its rows are `❓` and their
  coverage is unknown rather than absent.
- **Phase 6 could not run** — no `docs/architecture/architecture.md`. This does
  not by itself force NOT ASSESSED for the whole review (ADR traceability is the
  primary scope and can still be complete), but it must appear as a named
  `NOT ASSESSED` **line item** in the report rather than as absent findings. Emit
  the overall NOT ASSESSED verdict only if Phase 6 was the review's stated scope.

Do not resolve any of these to PASS on the grounds that no gap was *found*. No
gap was looked for.

### Blocking Issues (must resolve before PASS)
[List items that must be resolved — FAIL verdict only]

### Required ADRs
[Prioritised list of ADRs to create, most foundational first]
```

---

## Phase 8: Write and Update Traceability Index

Use `AskUserQuestion` for the write approval:
- "Review complete. What would you like to write?"
  - [A] Write all three files (review report + traceability index + TR registry)
  - [B] Write review report only — `docs/architecture/architecture-review-[date].md`
  - [C] Don't write anything yet — I need to review the findings first

### RTM Output (rtm mode only)

For `rtm` mode, use `AskUserQuestion`:
- "May I write the full Requirements Traceability Matrix?"
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
  - [B] Not yet — show me the full RTM data first, then ask again

RTM file format:

```markdown
# Requirements Traceability Matrix (RTM)

> Last Updated: [date]
> Mode: /architecture-review rtm
> Coverage: [N]% full chain complete (GDD → ADR → Story → Test)

## How to read this matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from tr-registry.yaml |
| GDD | Source design document |
| ADR | Architectural decision governing implementation |
| Story | Story file that implements this requirement |
| Test File | Automated test file path |
| Test Status | COVERED / MISSING / NONE / NO STORY |

## Full Traceability Matrix

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
[Full matrix rows from Phase 3b]

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| COVERED — full chain complete | [N] | [%] |
| MISSING test — story exists, no test | [N] | [%] |
| NO STORY — ADR exists, not yet implemented | [N] | [%] |
| NO ADR — architectural gap | [N] | [%] |
| **Total requirements** | **[N]** | **100%** |

## Uncovered Requirements (Priority Fix List)

Requirements where the full chain is broken, prioritised by layer:

### Foundation layer gaps
[list with suggested action per gap]

### Core layer gaps
[list]

### Feature / Presentation layer gaps
[list — lower priority]

## History

| Date | Full Chain % | Notes |
|------|-------------|-------|
| [date] | [%] | Initial RTM |
```

### TR Registry Update

Also ask: "May I update `docs/architecture/tr-registry.yaml` with new requirement
IDs from this review?"

If yes:
- **Append** any new TR-IDs that weren't in the registry before this review
- **Update** `requirement` text and `revised` date for any entries whose GDD
  wording changed (ID stays the same)
- **Mark** `status: deprecated` for any registry entries whose GDD requirement
  no longer exists (confirm with user before marking deprecated)
- **Never** renumber or delete existing entries
- Update the `last_updated` and `version` fields at the top

This ensures all future story files can reference stable TR-IDs that persist
across every subsequent architecture review.

### Reflexion Log Update

After writing the review report, append any 🔴 CONFLICT entries found in Phase 4
to `docs/consistency-failures.md` (if the file exists):

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [specific domain e.g. State Ownership, Performance]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [specific conflict — what each ADR claims]
**Resolution**: [how it was or should be resolved]
**Pattern**: [generalised lesson for future ADR authors in this domain]
```

Only append CONFLICT entries — do not log GAP entries (missing ADRs are expected
before the architecture is complete). Do not create the file if missing — only
append when it already exists.

### Session State Update

After writing all approved files, silently append to
`production/session-state/active.md`:

    ## Session Extract — /architecture-review [date]
    - Verdict: [PASS / CONCERNS / FAIL]
    - Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
    - New TR-IDs registered: [N, or "None"]
    - GDD revision flags: [comma-separated GDD names, or "None"]
    - Top ADR gaps: [top 3 gap titles from the report, or "None"]
    - Report: docs/architecture/architecture-review-[date].md

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

The traceability index format:

```markdown
# Architecture Traceability Index
Last Updated: [date]
Engine: [name + version]

## Coverage Summary
- Total requirements: [N]
- Covered: [X] ([%])
- Partial: [Y]
- Gaps: [Z]

## Full Matrix
[Complete traceability matrix from Phase 3]

## Known Gaps
[All ❌ items with suggested ADRs]

## Superseded Requirements
[Requirements whose GDD was changed after the ADR was written]
```

---

## Phase 9: Handoff

After completing the review and writing approved files, present:

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer)
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅ or ❌:
   - `tests/unit/` and `tests/integration/` directories — if ❌: run `/test-setup`
   - `.github/workflows/tests.yml` — if ❌: run `/test-setup`
   - `design/accessibility-requirements.md` — if ❌: run `/ux-design`
   - `design/ux/interaction-patterns.md` — if ❌: run `/ux-design`
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves"

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
    - [C] Run `/ux-design` — required before gate-check (only show if UX/accessibility files are ❌)
    - [D] Stop here for this session
- If all pre-gate checklist items are ✅ and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/gate-check pre-production`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [C] Stop here for this session

---

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer GDDs / single-system). Full procedure:
`.claude/docs/error-recovery-protocol.md`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — do not narrate every file read
2. **Show the matrix** — present the full traceability matrix before asking for
   anything; let the user see the state
3. **Don't guess** — if a requirement is ambiguous, ask: "Is [X] a technical
   requirement or a design preference?"
4. **Draft before approval** — always show the content that will be written (the
   report, the updated ADR section, the systems-index row) inline in the conversation
   before requesting approval. Never ask to write something the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] so the
   user can choose between "write now", "show full draft first", and "not yet".
   Multi-file changesets must list every file and what changes, then ask once
   with grouped options — not a separate plain-text question per file.
6. **Non-blocking** — the verdict is advisory; the user decides whether to continue
   despite CONCERNS or even FAIL findings
