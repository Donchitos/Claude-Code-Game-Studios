# Skill Test Spec: /design-review

## Skill Summary

`/design-review` reviews one game design document (GDD) against the project's
design standard (Overview, Player Fantasy, Detailed Rules, Formulas, Edge
Cases, Dependencies, Tuning Knobs, Acceptance Criteria). Which sections are
REQUIRED depends on the workflow tier resolved for that system: all 8 at
`full`; 5 at `standard` (plus Formulas when the system defines numeric rules).
It gathers section presence with `.claude/scripts/gdd-structure-check.sh`,
validates the declared dependency graph, checks internal consistency,
implementability and cross-system fit, and produces a verdict of APPROVED,
NEEDS REVISION, MAJOR REVISION NEEDED, or NOT ASSESSED.

The review mode sets its depth: `full` adds a parallel adversarial specialist
review plus a `creative-director` senior synthesis (Phase 3b); `lean` runs all
phases without agents; `solo` runs Phases 1–4 only with no next-step prompt.
Phase 4 writes nothing. In Phase 5 it can update `design/gdd/systems-index.md`
and append to `design/gdd/reviews/[doc-name]-review-log.md`, each only after the
user approves via `AskUserQuestion`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings or numbered steps
- [ ] Contains verdict keywords: APPROVED, NEEDS REVISION, MAJOR REVISION NEEDED, NOT ASSESSED
- [ ] `allowed-tools` includes Write/Edit, so "May I" write-approval language is present (systems-index update, review-log append)
- [ ] Output format is documented (review template shown in skill body)

---

## Test Cases

### Case 1: Happy Path — Complete GDD, all 8 sections present

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/light-manipulation.md` exists with all 8 sections populated with
  substantive content (the Detailed Rules section is titled `## Detailed Design`)
- Formulas section defines at least one formula with named variables
- Acceptance Criteria section contains at least 3 testable criteria
- Every system named in its Dependencies section has a GDD in `design/gdd/`
- No prior review log exists for this document

**Input:** `/design-review design/gdd/light-manipulation.md --review lean`

**Expected behavior:**
1. Freshness check (`review-receipts.sh check …`) finds no receipt → full review
2. Skill reads the target document in full and reads CLAUDE.md
3. Skill runs `bash .claude/scripts/gdd-structure-check.sh design/gdd/light-manipulation.md`
4. Skill Globs `design/gdd/` for each declared dependency
5. Skill checks internal consistency, implementability and cross-system fit
6. No agents are spawned (lean)
7. Skill outputs the Phase 4 review, ending with the verdict
8. On APPROVED, one multi-select `AskUserQuestion` offers the two tracking
   updates; only the selected ones are written; then a final closing widget

**Assertions:**
- [ ] Skill reads the target file before producing any output
- [ ] Section presence comes from `gdd-structure-check.sh`, and `## Detailed Design` is accepted as the Detailed Rules section (not flagged missing)
- [ ] Output includes "Completeness: 8/8" (N is 8 because the tier is `full`)
- [ ] Output includes a "Dependency Graph" section listing each declared dependency with whether its GDD exists
- [ ] Output includes "Required Before Implementation", "Recommended Revisions" and "Scope Signal" sections, and "Re-review: No — first review"
- [ ] Output ends with `### Verdict:` APPROVED when all REQUIRED sections are present and no blocking issue is found
- [ ] No file is written before the tracking-records widget, and only the options the user selects are written
- [ ] If the review-log option is selected, the appended entry includes the `review-receipts.sh hash` output for the document

---

### Case 2: Failure Path — Incomplete GDD (4/8 sections at `full`)

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/light-manipulation.md` has Overview, Player Fantasy, Detailed
  Rules and Dependencies only; Formulas, Edge Cases, Tuning Knobs and
  Acceptance Criteria are absent

**Input:** `/design-review design/gdd/light-manipulation.md --review lean`

**Expected behavior:**
1. `gdd-structure-check.sh` reports the 4 sections in its `ABSENT:` list
2. All 4 are REQUIRED at `full`, so each blocks approval
3. Skill outputs "Completeness: 4/8" and names each missing section
4. Verdict is a revision verdict, never APPROVED
5. Phase 5 offers `[A] Revise the GDD now` / `[B] Stop here`; "Accept as-is" is
   offered only when all items are advisory, which they are not here

**Assertions:**
- [ ] Output shows "4/8" in the completeness section (not a higher number)
- [ ] Output explicitly names each missing section (Formulas, Edge Cases, Tuning Knobs, Acceptance Criteria) as REQUIRED
- [ ] Verdict is NEEDS REVISION or MAJOR REVISION NEEDED — never APPROVED while a REQUIRED section is missing, and not NOT ASSESSED (the document was read)
- [ ] Output does not suggest the document is implementation-ready
- [ ] "Accept as-is and move on" is not offered, because the missing sections are blocking
- [ ] No file is written except after an explicit Phase 5 choice: `[A] Revise the GDD now`, "May I update `design/gdd/systems-index.md`…", or "May I append this review summary…"
- [ ] The systems-index prompt offers `Needs Revision` or `In Review` — never `Approved` on this revision verdict — and the review-log entry records the revision verdict, not an approval

---

### Case 3: Partial Path — `standard` tier, numeric rules with no Formulas section

**Fixture:**
- `project.yaml` sets `modes.workflow: standard`
- GDD has Overview, Player Fantasy, `## Detailed Design`, Edge Cases,
  Dependencies, Tuning Knobs and Acceptance Criteria; no Formulas section
- Detailed Design states numeric rules ("drain 2 oxygen per second", "refill
  costs 50 credits") but no formula defines them
- Acceptance Criteria are vague ("feels good" rather than measurable)

**Input:** `/design-review design/gdd/oxygen.md --review lean`

**Expected behavior:**
1. Skill marks Formulas REQUIRED at `standard` because the system defines
   numeric rules (the system's `Category` alone never clears it)
2. N = 6 (5 standard sections + Formulas); Completeness shows 5/6, not a /8 count
3. Skill flags the vague acceptance criteria as an implementability issue
4. Verdict is a revision verdict

**Assertions:**
- [ ] Output identifies the missing Formulas section as REQUIRED (not advisory) because numeric rules are present
- [ ] Completeness is reported against the `standard` count ("5/6"), not "7/8"
- [ ] Output flags the vague acceptance criteria as an implementability gap, quoting each one — the main review does this itself, since no `qa-lead` runs in `lean`
- [ ] Verdict is NEEDS REVISION or MAJOR REVISION NEEDED, never APPROVED

---

### Case 4: Edge Case — File not found

**Fixture:**
- The path provided does not exist in the project

**Input:** `/design-review design/gdd/nonexistent.md --review lean`

(`lean`, so Phase 5 runs. In `solo` — what the review mode resolves to when
`project.yaml` sets neither `modes.review_mode` nor `modes.rigor` — Phase 5 never
runs and the last assertion below would test nothing.)

**Expected behavior:**
1. Freshness check reports no receipt; skill attempts to read the file
2. File not found
3. Skill outputs `### Verdict: NOT ASSESSED`, naming the missing document and
   the skill that produces it (`/design-system`)
4. Skill does NOT produce a quality verdict or any tracking write
5. Phase 5 skips the tracking widgets and goes to the final closing widget,
   leading with `/design-system`

**Assertions:**
- [ ] Verdict is NOT ASSESSED — not APPROVED, NEEDS REVISION or MAJOR REVISION NEEDED
- [ ] Output names the missing file and which skill produces it
- [ ] Phase 5 runs, and offers neither a `systems-index.md` status update nor a review-log entry — in particular it never offers to mark the system Approved

---

### Case 5: Review mode — specialist delegation in `full`, none in `lean` / `solo`

**Fixture (all sub-cases):**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/light-manipulation.md` exists with all 8 sections, including
  formulas and combat stats

**Case 5a — full:** `/design-review design/gdd/light-manipulation.md --review full`

**Expected behavior:**
1. Before spawning, skill prints "Full review: spawning specialist agents in parallel…"
2. Skill spawns the relevant specialists in parallel as real `Agent` calls —
   `game-designer` (any gameplay system) and `systems-designer` (formulas) at minimum here
3. After the specialists return, skill spawns `creative-director` as senior
   reviewer; its synthesis becomes the final verdict
4. Findings are source-tagged; disagreements are listed, not silently resolved

**Assertions (5a):**
- [ ] The notice is printed before any agent is spawned
- [ ] Specialists are spawned in parallel via `Agent` (not simulated in-session)
- [ ] `creative-director` is spawned only after the specialists respond, and output has a "Senior Verdict [creative-director]" section
- [ ] "Specialists consulted:" lists the agents actually spawned, and every finding carries a source tag such as `[game-designer]`
- [ ] Specialist disagreements appear under "Specialist Disagreements"
- [ ] The `### Verdict:` line carries exactly one of this skill's words — APPROVED, NEEDS REVISION or MAJOR REVISION NEEDED — taken from the creative-director's synthesis; never a director-gate word such as READY, CONCERNS, NOT READY, APPROVE or REJECT
- [ ] No director-gate IDs appear ("Gate: CD-…" etc.) — the senior review is a direct spawn, not a gate from `director-gates.md`

**Case 5b — lean via the legacy flag:** `/design-review design/gdd/light-manipulation.md --depth lean`

**Assertions (5b):**
- [ ] `--depth lean` is treated as `--review lean`, and the skill says once that the flag was renamed
- [ ] No `Agent` call is made; the review runs in-session
- [ ] Phase 5's next-step widgets still run

**Case 5c — solo:** `/design-review design/gdd/light-manipulation.md --review solo`

**Assertions (5c):**
- [ ] No `Agent` call is made
- [ ] Only Phases 1–4 run: no Phase 5 next-step prompt, so no systems-index or review-log write is offered

---

### Case 6: Review mode from the resolved config — no flag

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and `modes.review_mode: lean`
- `design/gdd/light-manipulation.md` exists with all 8 sections

**Input:** `/design-review design/gdd/light-manipulation.md`

**Expected behavior:**
1. No `--review` flag, so the skill takes `review_mode: lean` from the resolved
   config block at the top of the skill
2. The review runs in-session with no `Agent` call
3. Phase 5's widgets run — which `solo`, the `rigor: minimal` default, would have skipped

**Assertions:**
- [ ] The review mode comes from the resolved config block when no flag is given (`review_mode: lean (project.yaml)`)
- [ ] No `Agent` call is made, and Phase 5's next-step widgets run — so the run is `lean`, not the `solo` default
- [ ] Variant — the same fixture with `--review solo` on the input: the flag wins over the config, and no Phase 5 widget runs

---

## Protocol Compliance

- [ ] Writes nothing during the review itself (Phase 4)
- [ ] Every write (systems-index status, review-log append) happens only after an `AskUserQuestion` approval
- [ ] Presents complete findings before the verdict line
- [ ] Outside `solo`, closes with an `AskUserQuestion` next-step widget rather than plain text (collaborative/guided modes)

---

## Coverage Notes

- Cross-system consistency across many GDDs is covered by the `/review-all-gdds`
  spec; this spec checks only one document's dependency references.
- The freshness receipt paths (byte-identical re-review offering the prior
  verdict; registry-only change) are not fixture-tested here.
- The entity-registry grep path (registry lists this system) is not tested; the
  fixtures above use the fallback of reading the GDDs named in Dependencies.
- The `minimal` tier (no GDD expected; standard sections checked advisorily) is
  not tested.
- Performance and edge cases involving very large GDD files are not in scope.
