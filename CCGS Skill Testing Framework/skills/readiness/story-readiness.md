# Skill Test Spec: /story-readiness

## Skill Summary

`/story-readiness` validates that a story file is ready for a developer to
pick up and implement. It loads its reference context once (systems index,
the control manifest's `Manifest Version:` header, the TR registry, and every
ADR's status via a single Grep), then evaluates each story against six
checklist groups: Design Completeness, Architecture Completeness, Scope
Clarity, Open Questions, Asset References, and Definition of Done. The workflow
tier resolved for the story's system decides which groups block (`full`: all;
`standard`: architecture items advisory except a critical ADR; `minimal`:
architecture N/A) — except one rule at every tier: an ADR the story references that
is missing, `Proposed`, `Deprecated` or `Superseded` BLOCKS, because `/dev-story`
stops on it. At `minimal`, `design/game-brief.md` stands in for the GDD. It produces a READY / NEEDS WORK / BLOCKED / NOT ASSESSED
verdict. It is read-only — it never writes or edits a file. In `full` review
mode it then runs the QL-STORY-READY gate (`qa-lead`).

A fixture that sets neither `qa.level` nor `modes.rigor` resolves `qa.level:
minimal` (the `rigor: minimal` default). There the evidence item auto-passes for
Logic, Integration and Config/Data stories — never for UI or Visual/Feel, whose
retained screenshot is required at every `qa.level` (Case 6).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings or numbered check sections
- [ ] Contains verdict keywords: READY, NEEDS WORK, BLOCKED, NOT ASSESSED
- [ ] Does NOT require "May I write" language — `allowed-tools` has no Write or Edit
- [ ] Has a next-step handoff (what to do after verdict)

---

## Test Cases

### Case 1: Happy Path — Fully ready story

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and `modes.review_mode: solo`
- Story file exists at `production/epics/core/story-light-pickup.md` containing:
  - A `GDD: design/gdd/light-system.md` reference quoting the specific requirement
  - `TR-light-001`, present with `status: active` in `docs/architecture/tr-registry.yaml`
  - `ADR: ADR-0003`; `docs/architecture/adr-0003-inventory.md` has `## Status` Accepted
  - `Type: Logic`, an `## Acceptance Criteria` section with 3 testable items, and a `## Test Evidence` section naming the test path
  - An estimate, an Out of Scope statement, and `Dependencies: None`
  - Engine notes (or "N/A — no engine API involved"), the relevant manifest rules, and a performance note
  - A `Manifest Version:` equal to the one in `docs/architecture/control-manifest.md`
  - No TBD / UNRESOLVED markers and no asset paths
- A sprint plan in `production/sprints/` lists other stories

**Input:** `/story-readiness production/epics/core/story-light-pickup.md`

**Expected behavior:**
1. Skill reports "Validating 1 story files."
2. Skill loads context once: greps `Manifest Version` from the control manifest,
   indexes `tr-registry.yaml`, and resolves every ADR status with one
   `Grep pattern="^## Status" glob="docs/architecture/adr-*.md"` scan
3. Skill evaluates all six checklist groups
4. Skill outputs READY with all checks passing
5. Phase 8 notes "QL-STORY-READY skipped — Solo mode."
6. Section 7 surfaces other ready stories from the sprint

**Assertions:**
- [ ] ADR status is resolved from the one-scan `^## Status` Grep over `docs/architecture/adr-*.md`, not by reading each ADR in full, and ADR-0003 is found Accepted
- [ ] Skill looks up `TR-light-001` in `tr-registry.yaml` and finds it active
- [ ] The current manifest version is taken from a Grep of the manifest header, not a full read
- [ ] The "Passing Checks (N/[total])" section names all six groups — Design Completeness, Architecture Completeness, Scope Clarity, Open Questions, Asset References ("no asset references"), Definition of Done — with the passing items under each
- [ ] Verdict is READY when all checks pass
- [ ] Skill does not write any files
- [ ] Section 7 lists up to 3 other ready sprint stories — or states "Next ready stories: no sprint file found" / "none ready in [sprint]" rather than omitting the section

---

### Case 2: Blocked Path — Referenced ADR is Proposed (not Accepted)

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- Story `production/epics/core/story-light-system.md` references `ADR-0005`
- `docs/architecture/adr-0005-light-system.md` exists with `## Status` Proposed
- All other story content is complete

**Input:** `/story-readiness production/epics/core/story-light-system.md`

**Expected behavior:**
1. The status scan finds ADR-0005 `Proposed`
2. Skill flags it BLOCKED with the fix text "BLOCKED: ADR-0005 is Proposed — wait for acceptance before implementing."
3. Skill outputs BLOCKED, listing the ADR under Blockers

**Assertions:**
- [ ] Verdict is BLOCKED (not NEEDS WORK or READY) when the ADR is Proposed at `full`
- [ ] Output explicitly names ADR-0005 as the blocker
- [ ] Output says to wait for the ADR's acceptance before implementing
- [ ] Skill does not output READY regardless of other checks passing
- [ ] Variant — same story at `modes.workflow: standard`, with `| **Layer** | Feature |` in ADR-0005's `## Engine Compatibility` table (non-critical): the story references the Proposed ADR, so the verdict is still BLOCKED — a referenced Proposed ADR blocks at every tier, because `/dev-story` stops on it
- [ ] Variant — the same non-critical ADR at `standard`, now `Accepted`, with the story's `Manifest Version:` older than the control manifest's: the stale version is listed under Gaps as advisory, with its `Fix:` line, and the verdict is READY — an advisory gap does not downgrade it

---

### Case 3: Needs Work — Missing Acceptance Criteria (checked at every tier)

**Fixture:**
- `project.yaml` sets `modes.workflow: minimal`
- Story `production/epics/core/story-oxygen-drain.md` has `Type: Logic` but no `## Acceptance Criteria` section
- The story references no ADR, no TR-ID and no manifest version

**Input:** `/story-readiness production/epics/core/story-oxygen-drain.md`

**Expected behavior:**
1. At `minimal`, skill evaluates Design Completeness and Scope Clarity and treats Architecture Completeness as N/A
2. Skill finds no acceptance criteria
3. Skill outputs NEEDS WORK, naming the gap with a `Fix:` line suggesting specific, observable criteria

**Assertions:**
- [ ] Verdict is NEEDS WORK (not BLOCKED or READY) when the Acceptance Criteria section is absent
- [ ] Output identifies the missing Acceptance Criteria specifically, with a `Fix:` line proposing measurable criteria
- [ ] No ADR, TR-ID or manifest gap is flagged — Architecture Completeness is N/A at `minimal`
- [ ] The story is not BLOCKED: nothing requires outside action (no missing/DRAFT dependency, no unowned UNRESOLVED question)
- [ ] Variant — the same `minimal` story with acceptance criteria traced to `design/game-brief.md`'s MVP feature (no `design/gdd/` path): "GDD requirement referenced" passes — the brief stands in for the GDD at `minimal`
- [ ] Variant — the story also names `ADR-0005`, whose `## Status` is `Proposed`: the verdict is BLOCKED at `minimal` too — the referenced-ADR rule is the one Architecture Completeness item that is not N/A

---

### Case 4: Edge Case — Stale manifest version

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- Story has `Manifest Version: 2026-01-15` in its header
- `docs/architecture/control-manifest.md` has `Manifest Version: 2026-03-10`
- Everything else in the story passes

**Input:** `/story-readiness production/epics/core/story-mirror-rotation.md`

**Expected behavior:**
1. Skill extracts `2026-01-15` from the story
2. Skill greps the manifest header and extracts `2026-03-10`
3. The story's version is older → the "Manifest version is current" item fails
4. Verdict is NEEDS WORK, with the fix to review the changed rules and update the story's `Manifest Version:`

**Assertions:**
- [ ] Skill gets the current version by grepping `Manifest Version` in `docs/architecture/control-manifest.md`
- [ ] Skill compares the story's embedded version against the current one
- [ ] At `full`, a stale manifest version results in NEEDS WORK (not BLOCKED, not READY)
- [ ] Output explains that new manifest rules may apply, and the `Fix:` says to review the changed rules, update the story if needed, then set its `Manifest Version:` to current

---

### Case 5: Director Gate — QL-STORY-READY behavior across review modes

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- Story file exists and passes every checklist item
- Review mode comes from `modes.review_mode` (legacy mirror `production/review-mode.txt`) or `--review`

**Case 5a — full mode:** `/story-readiness production/epics/core/story-light-pickup.md --review full`

**Expected behavior:**
1. Skill completes its own checklist and verdict first
2. Skill spawns `qa-lead` via `Agent` with gate QL-STORY-READY, passing the story
   file path, story type, acceptance criteria (verbatim), the GDD requirement
   (TR-ID and text), dependency status and the Phase 4 verdict
3. ADEQUATE → story cleared
4. GAPS → `AskUserQuestion`: `Update story with suggested gaps` / `Accept and proceed anyway` / `Discuss further`
5. INADEQUATE → the gate says the story must be revised before sprint inclusion:
   the checklist's READY is demoted to NEEDS WORK and the final verdict line is
   restated with the gaps; the user is asked whether to update the story or
   proceed anyway, and proceeding is recorded as an override, not as READY
6. NOT ASSESSED (a gate input was missing) → the missing input is named and never
   read as ADEQUATE: it is supplied and the gate re-run, or READY becomes NOT ASSESSED

**Assertions (5a):**
- [ ] Skill uses the resolved review mode before deciding whether to spawn QL-STORY-READY
- [ ] QL-STORY-READY is spawned only after the checklist verdict exists
- [ ] A GAPS result produces the three-option `AskUserQuestion`
- [ ] An INADEQUATE result overrides the checklist's READY: the final verdict is NEEDS WORK, restated with the gate's specific gaps
- [ ] If the user proceeds anyway, the verdict stays NEEDS WORK and the output states the override ("proceeding despite QL-STORY-READY: INADEQUATE (user override)") — never a silent READY
- [ ] A NOT ASSESSED answer from the gate names the missing input and never leaves READY standing: unless the input is supplied and the gate re-run, the verdict is NOT ASSESSED

**Case 5b — lean or solo mode:** `--review lean` or `--review solo`

**Expected behavior:**
1. QL-STORY-READY is skipped
2. Output notes "QL-STORY-READY skipped — Lean mode." or "QL-STORY-READY skipped — Solo mode."
3. Verdict is based on the checklist only

**Assertions (5b):**
- [ ] QL-STORY-READY does NOT spawn in lean or solo mode
- [ ] The skip is noted in the output with the mode named
- [ ] Verdict is based on the checklist alone

---

### Case 6: UI story at `qa.level: minimal` — the screenshot plan is never waived

**Fixture:**
- `project.yaml` sets `modes.workflow: standard` and `qa.level: minimal` (set on
  its own, so only the test-evidence axis is at `minimal` and every checklist
  group is evaluated)
- No `docs/architecture/control-manifest.md` and no `tr-registry.yaml` yet
- Story `production/epics/ui/story-003-shop-panel.md` has `Type: UI`, a
  `GDD: design/gdd/shop.md` reference quoting the requirement it implements, two
  testable acceptance criteria naming what the shop panel shows, "No ADR applies —
  pure layout", engine notes, an estimate, an Out of Scope statement,
  `Dependencies: None` and a performance note — and no `## Test Evidence` section,
  nor any other mention of where a screenshot will go
- No TBD / UNRESOLVED markers and no asset paths

**Input:** `/story-readiness production/epics/ui/story-003-shop-panel.md`

**Expected behavior:**
1. The architecture items pass or auto-pass (explicit "No ADR applies"; no
   TR-ID, manifest version or manifest to check)
2. The "Test evidence requirement is clear" item still applies — UI is the
   exception to the `qa.level: minimal` auto-pass
3. `testing.strict.ui` is unset, so the item is strict by default: the missing
   section makes the story NEEDS WORK
4. The `Fix:` asks for a `## Test Evidence` section naming where the retained
   screenshot of each screen touched will go under `production/qa/evidence/`

**Assertions:**
- [ ] Verdict is NEEDS WORK, not READY — the evidence item does not auto-pass for a UI story at `qa.level: minimal`
- [ ] The gap names the missing screenshot plan, and its `Fix:` points at `production/qa/evidence/`
- [ ] The missing screenshot plan is the only gap — no ADR, TR-ID or manifest gap is flagged
- [ ] Variant — a `Type: Logic` story with three testable criteria and no `## Test Evidence` section, same config: the evidence item auto-passes at `qa.level: minimal`, so the missing section alone does not make it NEEDS WORK

---

### Case 7: NOT ASSESSED — nothing to evaluate, or an ADR nobody can read

**Case 7a — zero stories in scope:**
- `production/epics/` holds only `EPIC.md` index files, no story files
- **Input:** `/story-readiness all`

**Assertions (7a):**
- [ ] Output is `NOT ASSESSED — no stories in scope`, naming `production/epics/**/*.md` as the path searched
- [ ] It routes to `/create-epics [layer]` then `/create-stories [epic-slug]`
- [ ] No `Ready: 0 / Needs Work: 0 / Blocked: 0` summary is printed over an empty list

**Case 7b — a referenced ADR with no readable status:**
- `project.yaml` sets `modes.workflow: full`
- Story `production/epics/core/story-save-slots.md` passes every other item and
  references `ADR-0007`; `docs/architecture/adr-0007-save-format.md` exists but has
  no `## Status` section
- **Input:** `/story-readiness production/epics/core/story-save-slots.md`

**Assertions (7b):**
- [ ] The ADR check is NOT ASSESSED — the status is unknown, not failed — and the verdict is NOT ASSESSED: not BLOCKED, not READY
- [ ] Output names `docs/architecture/adr-0007-save-format.md` and routes to `/architecture-decision retrofit docs/architecture/adr-0007-save-format.md`
- [ ] Variant — the story names `ADR-0007` but no such file exists: that is a finding about the story, so the verdict is BLOCKED ("referenced ADR is missing"), not NOT ASSESSED

---

## Protocol Compliance

- [ ] Does NOT use Write or Edit tools; any help filling gaps is drafted in conversation only
- [ ] Single-story output follows the Section 5 template: Verdict line, "Passing Checks (N/[total])", Gaps each with a `Fix:` line, and Blockers when BLOCKED
- [ ] Does not ask for write approval (no file writes)
- [ ] Ends with a recommended next step (fix the gaps, or `/dev-story [story-path]` once READY)
- [ ] Keeps the verdict levels distinct — NOT ASSESSED (could not evaluate) is never reported as BLOCKED

---

## Coverage Notes

- A TR-ID missing from the registry follows the same NEEDS WORK pattern as Case 4.
- The zero-story scope is Case 7a; the `sprint` / `all` aggregate output over real
  stories and the Must Have sprint escalation warning are not tested here.
- The no-argument path (scope chosen via `AskUserQuestion`) is not tested.
- Stories with multiple ADR references are not tested; behavior is assumed to
  be additive (all ADRs must be Accepted for READY verdict).
