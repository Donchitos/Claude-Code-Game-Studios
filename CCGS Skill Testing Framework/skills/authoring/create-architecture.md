# Skill Test Spec: /create-architecture

## Skill Summary

`/create-architecture` produces the master architecture document,
`docs/architecture/architecture.md`. Phase 0 loads context and stops early when
a prerequisite is missing: the engine reference docs (no engine → `/setup-engine`),
`design/gdd/systems-index.md` (absent at `standard`/`full` → `/map-systems`),
and `design/gdd/game-concept.md` (absent → `/brainstorm`; at `minimal` the
one-page `design/game-brief.md` stands in). It extracts a Technical Requirements
Baseline (`TR-[system]-[NNN]`) from the requirement-bearing sections of every
GDD, inventories existing ADRs from their headers, and shows an Engine Knowledge
Gap Inventory with an `AskUserQuestion` before authoring.

Phases 1–4 (layer map, module ownership, data flow, API boundaries) are each
presented and approved. Phase 5 audits existing ADRs and maps every baseline
requirement to ADR coverage; uncovered requirements become Required New ADRs.
Phase 7 asks "All sections approved. May I write the master architecture
document?" with `[A]/[B]/[C]` options. Phase 7b collects the TD-ARCHITECTURE and
LP-FEASIBILITY reviews, presents them side by side, and asks before recording
the sign-off in the Document Status section. Phase 8 updates
`production/session-state/active.md` and prints a fixed handoff template.

An existing `docs/architecture/architecture.md` is never replaced unasked:
Phase 0e offers to update chosen sections in place (raising the document's
version), to rewrite it, or to stop. Focus-area arguments (`layers`,
`data-flow`, `api-boundaries`, `adr-audit`) are that update with one section
chosen; with no document yet, they offer the full walkthrough instead.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains sign-off verdict keywords in the gates' own words: `APPROVE`, `CONCERNS`, `FEASIBLE`, and the `REVISED after …` records
- [ ] Contains ask-before-write language: write approvals via `AskUserQuestion` ("May I write the master architecture document?", "May I update the Document Status section…")
- [ ] Has a next-step handoff at the end (`/architecture-decision`, `/architecture-review`, `/create-control-manifest`)
- [ ] Documents one consistent write model for `docs/architecture/architecture.md` — when the file is first created and when each approved section is written
- [ ] Documents gate behavior: TD-ARCHITECTURE + LP-FEASIBILITY in full mode; each skipped in lean/solo with a named note
- [ ] Documents the stop branches for a missing engine, systems index and game concept
- [ ] Documents retrofit: an existing `docs/architecture/architecture.md` is detected, and updating chosen sections is offered before any rewrite

---

## Director Gate Checks

Review mode comes from the resolved `review_mode` (`modes.review_mode` in
`project.yaml`); `--review full|lean|solo` overrides it for one run.

In `full` mode: after `docs/architecture/architecture.md` is written, TD-ARCHITECTURE
(`technical-director`) and LP-FEASIBILITY (`lead-programmer`) review it. Each is
a spawned agent that reads its own gate file
(`.claude/docs/director-gates/td-architecture.md`, `lp-feasibility.md`); their
inputs are independent, so they spawn together and both verdicts are collected
before Step 3 presents them. The parent never reads those files: it passes
TD-ARCHITECTURE the document path, the Technical Requirements Baseline (TR-IDs
and count), the ADR list with statuses and the Engine Knowledge Gap Inventory.

In `lean` mode: neither is a PHASE-GATE, so both are skipped. Output notes
"TD-ARCHITECTURE and LP-FEASIBILITY skipped — Lean mode."

In `solo` mode: both are skipped with "TD-ARCHITECTURE and LP-FEASIBILITY
skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — New architecture document, full mode, reviews approve

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `modes.review_mode: full`, `modes.workflow: full`
- `docs/engine-reference/godot/` has `VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` and `modules/`
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist with real content
- `design/gdd/combat.md` and `design/gdd/inventory.md` follow the GDD template
- `docs/architecture/adr-0001-event-bus.md` exists (`Status: Accepted`)
- No `docs/architecture/architecture.md`
- TD-ARCHITECTURE returns APPROVE; LP-FEASIBILITY returns FEASIBLE

**Input:** `/create-architecture`

**Expected behavior:**
1. Phase 0a reads the four engine docs and only the `modules/` docs matching domains in the systems index
2. Phase 0b Greps the requirement-bearing sections of each GDD (Detailed Rules/Design, Formulas, Dependencies, Tuning Knobs, Acceptance Criteria) and presents the Technical Requirements Baseline with IDs such as `TR-combat-001`
3. Phase 0c builds the ADR inventory from `## Status`/`## Summary` and `**Domain**` Greps, not full reads
4. Phase 0d shows the Engine Knowledge Gap Inventory and asks `[A] Proceed — flag HIGH RISK domains…` / `[B] Let me check the engine reference first…` / `[C] Show me which domains are HIGH RISK and why`
5. Phases 1–4: each proposal (layer map, ownership map, each data-flow scenario, API boundaries) is shown and approved before the next, and each approval is recorded in `production/session-state/active.md` — nothing is written to the architecture document before Phase 7
6. Phase 7: a one-paragraph summary, then "All sections approved. May I write the master architecture document?" with `[A] Yes — write…` / `[B] Show me the full draft inline first…` / `[C] Not yet…`
7. Phase 7b: TD-ARCHITECTURE (passed the document path, the TR baseline, the ADR list with statuses and the knowledge gap inventory) and LP-FEASIBILITY review the written document; both assessments are shown side by side; the user chooses `Accept — proceed to handoff`
8. The proposed Document Status block is shown, then "May I update the Document Status section with the sign-off results?"
9. Phase 8 writes a summary to `production/session-state/active.md` and prints the handoff with the headings "Architecture Complete", "Run These ADRs Next", "Gate-Check Readiness"; its **Then:** line names `/architecture-review`, then `/create-control-manifest` once the review passes, and the readiness block names `/gate-check pre-production`

**Assertions:**
- [ ] The baseline uses `TR-[system]-[NNN]` IDs and is built from the scanned GDD sections, not whole-file reads
- [ ] The knowledge gap inventory and its three-option `AskUserQuestion` come before Phase 1
- [ ] Each section is shown before its approval is asked
- [ ] The master document is written only after the Phase 7 `AskUserQuestion` approval
- [ ] TD-ARCHITECTURE and LP-FEASIBILITY are each spawned as agents (`technical-director`, `lead-programmer`) after the document is written, and both verdicts are collected before Step 3
- [ ] TD-ARCHITECTURE is passed its four context items by name; the parent session does not read the gate file
- [ ] The Document Status sign-off is written only after the "May I update" approval
- [ ] The handoff uses the fixed template headings, with no trailing commentary
- [ ] The handoff names `/gate-check pre-production` — never a `[stage]` placeholder, which while this skill runs would resolve to the gate already passed
- [ ] `docs/architecture/architecture.md` is not written, even in part, before the Phase 7 ask; Phases 2–4 approvals go to the session state

---

### Case 2: Review Concerns — LP-FEASIBILITY returns CONCERNS

**Fixture:**
- Same as Case 1, up to Phase 7b
- LP-FEASIBILITY returns CONCERNS: "Save/load path has no owning module for serialisation"
- Scenario (a): TD-ARCHITECTURE returns APPROVE
- Scenario (b): TD-ARCHITECTURE returns NOT ASSESSED, naming a context item it could not read

**Input:** `/create-architecture`

**Expected behavior:**
1. Step 3 shows the Technical Director assessment and the Lead Programmer verdict side by side, including the specific concern
2. `AskUserQuestion`: `Accept — proceed to handoff` / `Revise flagged items first` / `Discuss specific concerns`
3. If Accept: the proposed Document Status reads `LP-FEASIBILITY: [date] — CONCERNS (accepted)`, and is applied only after "May I update the Document Status section…" is answered yes
4. If Revise: the flagged section is re-drafted and approved as in Phases 1–4, the revised document is written once through Phase 7's ask, and the status then reads `LP-FEASIBILITY: [date] — REVISED after CONCERNS`
5. The skill does not record `FEASIBLE` for a review that returned CONCERNS
6. (b) Step 4 proposes `TD-ARCHITECTURE: [date] — NOT ASSESSED — [missing input]`, never `APPROVE`, and the handoff's first line says `NOT ASSESSED`

**Assertions:**
- [ ] The concern text is shown to the user alongside the TD assessment
- [ ] The user is offered Accept / Revise flagged items first / Discuss specific concerns
- [ ] Accepting records `CONCERNS (accepted)`, not `FEASIBLE`
- [ ] A revision records `REVISED after CONCERNS`, and the revised document is written once, after its sections are approved
- [ ] No Document Status change is written without the "May I update" approval
- [ ] (b) A NOT ASSESSED review is recorded with its missing input and never as an approval

---

### Case 3: Lean and Solo Modes — Both reviews skipped, written with user approval only

**Fixture:**
- Same project as Case 1, but scenario (a): `project.yaml` has `modes.review_mode: lean`
- Scenario (b): same project, invoked with `--review solo`

**Input:** (a) `/create-architecture` (b) `/create-architecture --review solo`

**Expected behavior:**
1. Phases 0–7 run as in Case 1; the document is written after the Phase 7 approval
2. At Phase 7b neither review runs; output notes (a) "TD-ARCHITECTURE and LP-FEASIBILITY skipped — Lean mode." (b) "TD-ARCHITECTURE and LP-FEASIBILITY skipped — Solo mode."
3. Step 4 shows the Document Status block with both lines `skipped — [mode] mode` and
   asks before applying it; the skill then proceeds to the Phase 8 handoff without
   blocking on the skipped reviews

**Assertions:**
- [ ] Neither `technical-director` nor `lead-programmer` is spawned, and no TD-ARCHITECTURE review is applied in lean or solo mode
- [ ] The skip note names both gates and the mode
- [ ] (b) The `--review solo` argument overrides the resolved `review_mode` for the run
- [ ] The document is written on user approval alone, and completion is not blocked
- [ ] Document Status records both reviews as skipped in that mode (after its ask), so the document says why it has no sign-off
- [ ] The Phase 8 handoff is still printed

---

### Case 3b: Review Rejects — Accept Is Not Offered

**Fixture:**
- Same project as Case 1 in `full` mode; `technical-director` returns
  `TD-ARCHITECTURE: REJECT` (a Core system depends on a Presentation-layer module);
  `lead-programmer` returns `LP-FEASIBILITY: FEASIBLE`

**Input:** `/create-architecture`

**Expected behavior:**
1. Both reviews are spawned in parallel at Phase 7b
2. Step 3 shows `TD-ARCHITECTURE: REJECT` and `LP-FEASIBILITY: FEASIBLE` side by side
3. The `AskUserQuestion` offers `Revise flagged items first` and `Discuss specific concerns` — **not** `Accept`
4. On `Revise flagged items first`, the flagged sections are re-drafted and approved as in Phases 1–4, and the revised document is written once, through Phase 7's ask
5. Nothing is recorded as approved; Step 4 records `REVISED after REJECT`, and the handoff's first line carries the same value

**Assertions:**
- [ ] `technical-director` and `lead-programmer` calls are issued before either result is awaited
- [ ] `Accept — proceed to handoff` is not an option while a REJECT stands
- [ ] The revised document is written once, after the re-drafted sections are approved — not section by section
- [ ] Document Status never shows TD-ARCHITECTURE as APPROVE for this run; the handoff line says `REVISED after REJECT`

---

### Case 4: Edge Case — Systems index missing or empty

**Fixture:**
- Engine configured; `design/gdd/game-concept.md` exists
- Scenario (a): `modes.workflow: standard`, no `design/gdd/systems-index.md`
- Scenario (b): `modes.workflow: standard`, `design/gdd/systems-index.md` exists but contains only template placeholders
- Scenario (c): `modes.workflow: minimal`, no systems index, no game concept, `design/game-brief.md` exists

**Input:** `/create-architecture`

**Expected behavior:**
1. The skill checks both design files exist before reading either
2. (a) Stops with: "No systems index found. Run `/map-systems` first…" — no baseline is built, no file is written
3. (b) Treats the placeholder-only index as absent and stops the same way
4. (c) Says the systems index is not required at `minimal`, reads `design/game-brief.md` in place of the concept, and proceeds

**Assertions:**
- [ ] (a) The skill stops with the `/map-systems` message and writes nothing
- [ ] (b) A present-but-placeholder systems index is treated as absent
- [ ] (c) At `minimal` the skill says the index is not required and proceeds from the game brief
- [ ] At `standard` (a, b), no run continues past Phase 0b with a missing design file; at `minimal` (c) the brief stands in for both, and the run stops only if it is absent too

---

### Case 5: ADR Audit — Proposed ADRs and uncovered requirements

**Fixture:**
- Same as Case 1, plus `docs/architecture/adr-0002-save-format.md` with `Status: Proposed`
- Also `design/gdd/crafting.md`, written before the GDD template, with none of the scanned section headings
- Baseline requirement `TR-combat-002` (combo state machine) is not covered by any ADR's GDD Requirements Addressed section or decision text

**Input:** `/create-architecture`

**Expected behavior:**
1. Phase 0b's section Grep matches nothing in `crafting.md`, so the skill full-reads it, says so, and its requirements enter the baseline as `TR-crafting-NNN` — a zero-match GDD is never treated as having no requirements
2. Phase 0c lists ADR-0001 (Accepted) and ADR-0002 (Proposed) with their domains
3. Phase 5 shows the ADR quality table and the traceability table, marking `TR-combat-002` as `❌ GAP`, with a covered/gap count
4. The gap is listed under Required New ADRs, grouped by layer with Foundation first, as `/architecture-decision [title] → covers: TR-combat-002`
5. Phase 8's "Gate-Check Readiness" lists ADR-0002 under "Accept ADRs" and the unwritten ADRs under "Write ADRs"
6. "Run These ADRs Next" lists at most three ADRs from Phase 6, in priority order

**Assertions:**
- [ ] `crafting.md`, which matched no scanned section, is full-read and reported, and contributes TR-IDs to the baseline
- [ ] ADR statuses come from the header scan and ADR-0002 is reported as Proposed
- [ ] `TR-combat-002` is marked as a GAP and becomes a Required New ADR naming the TR-ID it covers
- [ ] Required New ADRs are grouped by layer, Foundation first
- [ ] "Gate-Check Readiness" lists ADR-0002 under "Accept ADRs"
- [ ] "Run These ADRs Next" lists no more than three entries

---

### Case 6: Existing Architecture Document — Update in place, never overwritten unasked

**Fixture:**
- Same project as Case 1, but `project.yaml` has `modes.review_mode: lean`
- Scenario (a): `docs/architecture/architecture.md` exists at `Version: 2` with every section written; the user picks `[A] Update chosen sections in place` and chooses Data Flow
- Scenario (b): no `docs/architecture/architecture.md`; the input is `/create-architecture layers`

**Input:** (a) `/create-architecture` (b) `/create-architecture layers`

**Expected behavior:**
1. (a) Phase 0e finds the document, reads its Document Status and headings, and asks "An architecture document already exists (v2, [last updated]). What should this run do?" with `[A] Update chosen sections in place` / `[B] Rewrite the whole document — replaces the existing file` / `[C] Stop`
2. (a) Only Phase 3 (Data Flow) is authored; the output says which phases were skipped
3. (a) Phase 7's ask names the Data Flow section and the change from v2 to v3; on yes, only `## Data Flow` is replaced, with `Edit`, and `Version` becomes 3
4. (a) Every other section of the document is unchanged, and the handoff names v3
5. (b) The skill says there is no architecture document for the `layers` focus area to update, and offers the full walkthrough instead; nothing is written before the user answers

**Assertions:**
- [ ] (a) The existing document is detected before any authoring, and replacing it is only ever the user's explicit `[B]` choice
- [ ] (a) Only the chosen section is re-authored and written; the other sections are left as they were
- [ ] (a) The version is raised, not reset to v1.0
- [ ] (b) A focus-area run with no document writes nothing and offers the full walkthrough

---

## Protocol Compliance

- [ ] Stops before authoring when the engine is missing, or on a `standard`/`full` project when the systems index or game concept is missing; at `minimal` it proceeds from `design/game-brief.md` and stops only when that is absent too
- [ ] Every section is shown in full before its approval is asked
- [ ] Write approvals use `AskUserQuestion` with labeled options, not plain-text asks
- [ ] Follows one consistent write model for `docs/architecture/architecture.md`, and never replaces an existing one without the user choosing to
- [ ] TD-ARCHITECTURE and LP-FEASIBILITY run only in full mode; lean/solo print a skip note naming each gate and the mode
- [ ] The Document Status sign-off is recorded only after the "May I update" approval
- [ ] Ends with the fixed handoff template and next steps (`/architecture-decision`, `/architecture-review`, `/create-control-manifest`)

---

## Coverage Notes

- Of the focus-area arguments, only `layers` with no existing document is
  fixture-tested (Case 6 b). A focus-area run against an existing document
  follows Case 6 (a)'s update path but is not tested on its own.
- The "no engine configured" stop is asserted structurally only.
- `workflow: standard` (a system layer map and the critical ADR list only) is
  not fixture-tested past Phase 0b; Case 4 exercises only its stop branches.
- `docs.density` depth variations and `guided` / `autonomous` automation modes
  are not tested.
