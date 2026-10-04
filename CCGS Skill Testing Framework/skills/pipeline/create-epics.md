# Skill Test Spec: /create-epics

## Skill Summary

`/create-epics` reads in-scope GDDs, the architecture document, Accepted ADRs and
the TR registry, and turns each system into one epic mapped to an architectural
module. Systems are processed in layer order (Foundation → Core → Feature →
Presentation), and within a layer in `systems-index.md` order. Each epic is
presented (layer, GDD, architecture module, governing ADRs, engine risk, ADR
coverage, untraced requirements) and the user is asked "Shall I create Epic:
[name]?" before anything is written.

Epics are written to `production/epics/[epic-slug]/EPIC.md`, each after its own
"May I write `production/epics/[epic-slug]/EPIC.md` and add its row to
`production/epics/index.md` (creating it if absent)?" ask, which names the index
it then creates or updates. An EPIC.md that already exists
is never overwritten: the user chooses update-in-place (its Stories table kept) or
skip. In `full` review mode the
PR-EPIC gate (producer) runs after all epics for the layer are defined and before
any file is written; in `lean` and `solo` it is skipped with a note. Review mode
comes from `resolve_config` (`review_mode`), overridable per run with `--review`.
Verdicts: COMPLETE (N epics written) or BLOCKED (user declined all epics, stopped
at the gate, or no eligible systems found).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (per-epic approval)
- [ ] Has a next-step handoff at the end (`/create-stories [epic-slug]`)
- [ ] Documents PR-EPIC gate behavior: runs in full mode; skipped in lean/solo

---

## Director Gate Checks

In `full` mode: PR-EPIC (`producer`, `.claude/docs/director-gates/pr-epic.md`)
runs once all epics for the current layer are defined and before any epic file is
written. Verdicts: REALISTIC → proceed to the write asks; CONCERNS →
`AskUserQuestion` with `[A] Proceed as planned` / `[B] Revise epic boundaries` /
`[C] Stop`; UNREALISTIC → offer to split or merge epics, revise, present the
revised epics again, and re-run the gate before writing. CONCERNS `[B]` likewise
re-presents the revised epics before the gate re-runs. NOT ASSESSED [missing
input] → never read as REALISTIC: the input is supplied and the gate re-run, or
the run goes on with `PR-EPIC: NOT ASSESSED — [input]` stated in the output and
the Verdict line.

In `lean` mode: PR-EPIC is skipped. Output notes: "PR-EPIC skipped — Lean mode."

In `solo` mode: PR-EPIC is skipped. Output notes: "PR-EPIC skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — Two approved GDDs create two epics

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: full`, `modes.review_mode: lean`
- `design/gdd/systems-index.md` lists 2 Foundation systems
- Both systems have Approved GDDs in `design/gdd/`, each with a `## Summary`
- `docs/architecture/architecture.md` has a module for each system
- Accepted ADRs cover every TR-ID for both systems in `docs/architecture/tr-registry.yaml`;
  the first system has two governing ADRs whose Engine Compatibility rates
  Knowledge Risk LOW and HIGH
- `docs/architecture/control-manifest.md` exists
- No `production/epics/` directory

**Input:** `/create-epics layer: foundation`

**Expected behavior:**
1. Globs `design/gdd/*.md` (excluding systems-index and other non-system docs)
   to establish N, then Greps `^## Summary` to scope the Foundation systems
2. Reads the 2 in-scope GDDs, `architecture.md`, the Decision / GDD Requirements
   Addressed / Engine Compatibility sections of the in-scope ADRs, the TR
   registry and the manifest header; reports "Loaded 2 GDDs, [M] ADRs, engine: …"
3. For each system: presents the epic block and asks "Shall I create Epic: [name]?"
4. Notes "PR-EPIC skipped — Lean mode."
5. For each epic: asks "May I write `production/epics/[epic-slug]/EPIC.md` and
   add its row to `production/epics/index.md` (creating it if absent)?" and writes
   both after approval
6. Creates or updates `production/epics/index.md`
7. Verdict: COMPLETE — 2 epic(s) written; next step `/create-stories [epic-slug]`

**Assertions:**
- [ ] Each epic block is shown and "Shall I create Epic: [name]?" asked before any write ask
- [ ] "May I write" is asked per epic (not once for both)
- [ ] Files land at `production/epics/[epic-slug]/EPIC.md`
- [ ] Each EPIC.md contains Layer, GDD path, Architecture Module, Governing ADRs table, GDD Requirements table, Definition of Done
- [ ] The first epic's Engine Risk is HIGH — the highest among its governing ADRs, not the first or the average
- [ ] The Definition of Done asks Logic and Integration stories for passing tests under `tests/` (the Godot test root) and Visual/Feel and UI stories for retained screenshots in `production/qa/evidence/` — each screen touched for UI, plus a lead sign-off for Visual/Feel
- [ ] "PR-EPIC skipped — Lean mode." appears; no producer is spawned
- [ ] `production/epics/index.md` is created or updated after writing, and only after an ask that named it
- [ ] Verdict is COMPLETE and names `/create-stories [epic-slug]`

---

### Case 2: Failure Path — No system GDDs found

**Fixture:**
- `project.yaml`: `modes.workflow: full`
- `design/gdd/` contains only `game-concept.md` and `systems-index.md` (no
  system GDDs)

**Input:** `/create-epics all`

**Expected behavior:**
1. Globs `design/gdd/*.md` excluding the non-system docs — N = 0
2. Reports "No system GDDs found in `design/gdd/` — run `/design-system` first"
   and stops
3. No epic is presented, no gate runs, no file is written

**Assertions:**
- [ ] `game-concept.md` and `systems-index.md` are not counted as system GDDs
- [ ] The "No system GDDs found … run `/design-system` first" message is printed
- [ ] No "Shall I create Epic" or "May I write" ask is shown and no EPIC.md or index.md is written
- [ ] Verdict is BLOCKED (no eligible systems found), not COMPLETE

---

### Case 3: Director Gate — Full mode spawns PR-EPIC before writing

**Fixture:**
- 2 Approved GDDs, architecture, ADRs, TR registry and control manifest as in Case 1
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: full` — the workflow
  is pinned because an unset one resolves to `minimal`, where the skill reads the
  brief instead of the GDDs and the gate never comes into play
- PR-EPIC returns REALISTIC

**Input:** `/create-epics layer: foundation`

**Full mode expected behavior:**
1. Both epics are presented and accepted via "Shall I create Epic: [name]?"
2. `producer` is spawned via `Agent` with gate PR-EPIC, receiving the epic
   structure summary, the layer, milestone timeline and team capacity
3. On REALISTIC: the per-epic "May I write" asks proceed
4. Epic files are written after approval

**Assertions (full mode):**
- [ ] PR-EPIC is spawned once, after both epics are defined
- [ ] PR-EPIC runs before any "May I write" ask
- [ ] No EPIC.md is written before PR-EPIC resolves

**Fixture (per-run override):**
- Same project, `modes.workflow: full`, `modes.review_mode: full`
- Input: `/create-epics layer: foundation --review lean`

**Override expected behavior:**
1. `--review lean` overrides the resolved `full`
2. PR-EPIC is skipped — noted in output
3. "May I write" asks proceed directly

**Assertions (override):**
- [ ] "PR-EPIC skipped — Lean mode." appears in output
- [ ] No producer agent is spawned and the write asks follow the epic definitions directly

---

### Case 4: Edge Case — Untraced requirements at full workflow

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: solo`
- One Approved Foundation GDD whose system has 5 TR-IDs in `tr-registry.yaml`;
  Accepted ADRs cover 3 of them (2 untraced)

**Input:** `/create-epics [system-name]`

**Expected behavior:**
1. Epic block shows "GDD Requirements Covered by ADRs: 3 / 5" and lists the 2
   untraced TR-IDs under "Untraced Requirements"
2. Warns: "⚠️ 2 requirements in [system] have no ADR. The epic can be created, but
   `/create-stories` will write their stories with no governing ADR (`ADR: N/A`)
   and `Status: Ready` — nothing downstream blocks them, so they would be
   implemented without architectural guidance. Run `/architecture-decision` first
   if they need a decision, or proceed and accept the gap."
3. Asks "Shall I create Epic: [name]?" with `[A] Yes, create it` /
   `[B] Skip this epic` / `[C] Pause — I need to write ADRs first`
4. On [A]: notes "PR-EPIC skipped — Solo mode.", asks "May I write", and the
   EPIC.md GDD Requirements table marks the 2 rows `❌ No ADR`

**Assertions:**
- [ ] Coverage count and the 2 untraced TR-IDs are shown before the create ask
- [ ] The untraced-requirements warning names `/architecture-decision` and says what actually happens downstream: the stories are written `Ready` with no governing ADR — it does not claim they will be Blocked
- [ ] Option `[C] Pause — I need to write ADRs first` is offered
- [ ] The written EPIC.md marks the untraced rows `❌ No ADR` (not silently dropped)

---

### Case 5: Director Gate — PR-EPIC returns CONCERNS

**Fixture:**
- 2 Approved GDDs, architecture, ADRs, TR registry and control manifest as in Case 1
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: full`
- PR-EPIC returns CONCERNS (one epic's scope is too large)

**Input:** `/create-epics layer: foundation`

**Expected behavior:**
1. PR-EPIC is spawned and returns CONCERNS with specific feedback
2. Skill presents the producer's assessment before any write ask
3. `AskUserQuestion`: "Producer raised concerns about the epic structure. How do
   you want to proceed?" with `[A] Proceed as planned — I accept the producer's
   concerns` / `[B] Revise epic boundaries — split or merge as recommended` /
   `[C] Stop — I want to reconsider the scope`
4. [B]: epic definitions are revised from Step 4 and PR-EPIC is re-run
5. [C]: stops with Verdict: BLOCKED — user wants to reconsider epic scope

**Assertions:**
- [ ] The producer's CONCERNS are shown to the user before any "May I write" ask
- [ ] Skill does NOT write epics while the gate is unresolved
- [ ] All three options ([A] proceed / [B] revise / [C] stop) are offered
- [ ] Choosing [B] re-presents the revised epics and re-runs PR-EPIC before any write ask
- [ ] Choosing [C] ends with Verdict: BLOCKED and no files written

---

### Case 6: Edge Case — An EPIC.md already exists for one system

**Fixture:**
- As Case 1 (`modes.workflow: full`, `modes.review_mode: lean`)
- `production/epics/[first-slug]/EPIC.md` already exists, with
  `**Stories**: 3 stories` in its header and a 3-row `## Stories` table;
  `production/epics/index.md` has its row with `3 stories`
- The second system has no EPIC.md

**Input:** `/create-epics layer: foundation`

**Expected behavior:**
1. Both epics are presented and accepted via "Shall I create Epic: [name]?"
2. For the first system the skill does not overwrite: it asks "An EPIC.md already
   exists for [name]. Update it in place, or skip it?" with `[A] Update in place —
   keep its Stories table` / `[B] Skip this epic`; the user picks [A]
3. The update rewrites the header fields other than `Stories`, the Overview,
   Governing ADRs, GDD Requirements and Definition of Done, and leaves the
   `**Stories**` line and the `## Stories` table as they were
4. For the second system the normal "May I write `…/EPIC.md` and add its row to
   `production/epics/index.md`…?" ask follows
5. `production/epics/index.md` keeps one row for the first epic, still `3 stories`,
   and gains a row for the second

**Assertions:**
- [ ] The existing file is detected before any write, and update / skip is offered — it is not overwritten
- [ ] After the update, the `**Stories**` header line and all 3 `## Stories` rows are unchanged
- [ ] The index has no duplicate row for the first epic and does not reset it to `Not yet created`
- [ ] The second system's EPIC.md is written only after its own "May I write" ask

---

### Case 7: Standard tier — GDDs without `## Summary`, one untraced non-critical requirement

**Fixture:**
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: solo`
- `design/gdd/systems-index.md` lists one Foundation and one Core system; both
  GDDs predate `## Summary` (the Summary scan matches none of them)
- `docs/architecture/architecture.md` has a module for each system, and
  `docs/architecture/tr-registry.yaml` holds both systems' TR-IDs
- The Foundation system's TR-IDs are covered by an Accepted Foundation-layer ADR;
  one of the Core system's TR-IDs has no ADR
- `docs/architecture/control-manifest.md` does not exist

**Input:** `/create-epics all`

**Expected behavior:**
1. Globs `design/gdd/*.md` for N = 2; the `^## Summary` scan returns 0 matches
2. Notes once: "No `## Summary` sections found across 2 GDDs — scoping from
   `systems-index.md` instead of Summary." and full-reads both in-scope GDDs
3. Proceeds without the control manifest (read if present, not required at
   `standard`)
4. The Core epic lists its untraced TR-ID under "Untraced Requirements" as
   information only — no ⚠️ untraced-requirements warning, nothing blocked
5. Notes "PR-EPIC skipped — Solo mode."; each epic is written after its own ask

**Assertions:**
- [ ] A zero-match Summary scan is reported as such and both systems stay in scope — it is not read as "nothing in scope"
- [ ] The missing control manifest does not stop the run at `standard`
- [ ] The untraced non-critical requirement is listed, but the ⚠️ warning is not emitted
- [ ] Both epics are written, each after its own "May I write" ask

---

## Protocol Compliance

- [ ] Epic definitions shown to user before any "May I write" ask
- [ ] "May I write" asked per epic, not once for the entire batch
- [ ] An existing EPIC.md is updated in place or skipped by the user's choice — never overwritten
- [ ] PR-EPIC gate (if active) runs before write asks — not after
- [ ] Skipped gates noted by name and mode in output
- [ ] EPIC.md content sourced only from GDDs, ADRs, and architecture docs — nothing invented
- [ ] Never creates stories; ends with next-step handoff `/create-stories [epic-slug]` per created epic

---

## Coverage Notes

- Feature and Presentation layers follow the same per-epic pattern as Foundation
  and Core — layer-specific ordering is not independently tested.
- The `minimal` tier (optional; decomposes from `design/game-brief.md`, stops
  without one) is not given a fixture.
- The `## Summary` partial-adoption row (0 < M < N) is not separately tested; the
  zero-match row is Case 7.
- PR-EPIC UNREALISTIC handling (revise, present the revised epics again, re-run
  the gate), a NOT ASSESSED gate answer, and the no-argument "Which layer or
  system…" ask are not separately tested.
