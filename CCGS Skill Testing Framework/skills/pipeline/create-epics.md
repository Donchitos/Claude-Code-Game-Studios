# Skill Test Spec: $create-epics

## Skill Summary

`$create-epics` reads all approved GDDs and translates them into EPIC.md files,
one per system. Epics are organized by layer (Foundation → Core → Feature →
Presentation) and processed in priority order within each layer. Each EPIC.md
includes scope, governing ADRs, GDD requirements, engine risk level, and a
Definition of Done. The skill asks "May I write" before creating each EPIC file.

In `full` review mode, a PR-EPIC gate (producer) runs after drafting epics and
before writing any files. In `lean` or `solo` mode, PR-EPIC is skipped and noted.
Epics are written to `production/epics/[layer]/EPIC-[name].md`.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: CREATED, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (per-epic approval)
- [ ] Has a next-step handoff at the end (`$create-stories`)
- [ ] Documents PR-EPIC gate behavior: runs in full mode; skipped in lean/solo

---

## Director Gate Checks

In `full` mode: PR-EPIC (producer) gate runs after epics are drafted and before
any epic file is written. If PR-EPIC returns CONCERNS, epics are revised before
the "May I write" ask.

In `lean` mode: PR-EPIC is skipped. Output notes: "PR-EPIC skipped — lean mode".

In `solo` mode: PR-EPIC is skipped. Output notes: "PR-EPIC skipped — solo mode".

---

## Test Cases

### Case 1: Happy Path — Two approved GDDs create two EPIC files

**Fixture:**
- `design/gdd/systems-index.md` exists with 2 systems listed
- Both systems have approved GDDs in `design/gdd/`
- `docs/architecture/architecture.md` exists with matching modules
- At least one Accepted ADR exists for each system
- `production/session-state/review-mode.txt` contains `lean`

**Input:** `$create-epics`

**Expected behavior:**
1. Skill reads systems index and both GDDs
2. Drafts 2 EPIC definitions (layer, GDD path, ADRs, requirements, engine risk)
3. PR-EPIC gate is skipped (lean mode) — noted in output
4. For each epic: asks "May I write `production/epics/[layer]/EPIC-[name].md`?"
5. After approval: writes both EPIC files
6. Creates or updates `production/epics/index.md`

**Assertions:**
- [ ] Epic summary is shown before any write ask
- [ ] "May I write" is asked per-epic (not once for all epics together)
- [ ] Each EPIC.md contains: layer, GDD path, governing ADRs, requirements table, Definition of Done
- [ ] PR-EPIC skip is noted in output
- [ ] `production/epics/index.md` is updated after writing
- [ ] Skill does NOT write EPIC files without per-epic approval

---

### Case 2: Failure Path — No approved GDDs found

**Fixture:**
- `design/gdd/systems-index.md` exists
- No GDDs in `design/gdd/` have approved status (all are Draft or In Progress)

**Input:** `$create-epics`

**Expected behavior:**
1. Skill reads systems index and attempts to find approved GDDs
2. No approved GDDs found
3. Skill outputs: "No approved GDDs to convert. GDDs must be Approved before creating epics."
4. Skill suggests running `$design-system` and completing GDD approval first
5. Skill exits without creating any EPIC files

**Assertions:**
- [ ] Skill stops cleanly with a clear message when no approved GDDs exist
- [ ] No EPIC files are written
- [ ] Skill recommends the correct next action
- [ ] Verdict is BLOCKED

---

### Case 3: Director Gate — Full mode spawns PR-EPIC before writing

**Fixture:**
- 2 approved GDDs exist
- `production/session-state/review-mode.txt` contains `full`

**Full mode expected behavior:**
1. Skill drafts both epics
2. PR-EPIC gate spawns and reviews the epic drafts
3. If PR-EPIC returns APPROVED: "May I write" ask proceeds normally
4. Epic files are written after approval

**Assertions (full mode):**
- [ ] PR-EPIC gate appears in output as an active gate
- [ ] PR-EPIC runs before any "May I write" ask
- [ ] Epic files are NOT written before PR-EPIC completes

**Fixture (lean mode):**
- Same GDDs
- `production/session-state/review-mode.txt` contains `lean`

**Lean mode expected behavior:**
1. Epics are drafted
2. PR-EPIC is skipped — noted in output
3. "May I write" ask proceeds directly

**Assertions (lean mode):**
- [ ] "PR-EPIC skipped — lean mode" appears in output
- [ ] Skill proceeds to "May I write" without waiting for PR-EPIC

---

### Case 4: Edge Case — Epic already exists for a GDD

**Fixture:**
- `production/epics/[layer]/EPIC-[name].md` already exists for one of the approved GDDs
- The other GDD has no existing EPIC file

**Input:** `$create-epics`

**Expected behavior:**
1. Skill detects the existing EPIC file for the first system
2. Skill offers to update rather than overwrite: "EPIC-[name].md already exists. Update it, or skip?"
3. For the second system (no existing file): proceeds normally with "May I write"

**Assertions:**
- [ ] Skill detects existing EPIC files before writing
- [ ] User is offered "update" or "skip" options — not auto-overwritten
- [ ] The new system's EPIC is created normally without conflict

---

### Case 5: Director Gate — PR-EPIC returns CONCERNS

**Fixture:**
- 2 approved GDDs exist
- `production/session-state/review-mode.txt` contains `full`
- PR-EPIC gate returns CONCERNS (e.g., scope of one epic is too large)

**Input:** `$create-epics`

**Expected behavior:**
1. PR-EPIC gate spawns and returns CONCERNS with specific feedback
2. Skill surfaces the concerns to the user before any write ask
3. User is given options: revise epics, accept concerns and proceed, or stop
4. If user revises: updated epic drafts are shown before the "May I write" ask
5. Skill does NOT write epics while CONCERNS are unaddressed

**Assertions:**
- [ ] CONCERNS from PR-EPIC are shown to the user before writing
- [ ] Skill does NOT auto-write epics when CONCERNS are returned
- [ ] User is given a clear choice to revise, proceed, or stop
- [ ] Revised epic drafts are re-shown after revision before final approval

---

## Protocol Compliance

- [ ] Epic drafts shown to user before any "May I write" ask
- [ ] "May I write" asked per-epic, not once for the entire batch
- [ ] PR-EPIC gate (if active) runs before write asks — not after
- [ ] Skipped gates noted by name and mode in output
- [ ] EPIC.md content sourced only from GDDs, ADRs, and architecture docs — nothing invented
- [ ] Ends with next-step handoff: `$create-stories [epic-slug]` per created epic

---

## Coverage Notes

- Processing of Core, Feature, and Presentation layers follows the same per-epic
  pattern as Foundation — layer-specific ordering is not independently tested.
- Engine risk level assignment (LOW/MEDIUM/HIGH) from governing ADRs is
  validated implicitly via Case 1's fixture structure.
- The `layer: [name]` and `[system-name]` argument modes follow the same approval
  pattern as the default (all systems) mode.
