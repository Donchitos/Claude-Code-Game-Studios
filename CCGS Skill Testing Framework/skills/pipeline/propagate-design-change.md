# Skill Test Spec: /propagate-design-change

## Skill Summary

`/propagate-design-change` handles GDD revision cascades into the architecture.
Given a changed GDD path, it asks git what changed (`git diff HEAD`, then the last
commit), summarises the changed sections, checks the entity registry for
downstream GDDs to re-check, then finds every ADR that references the GDD — by
scanning `## GDD Requirements Addressed` tables plus a prose grep for the GDD's
basename — and reads only that affected set. Each affected ADR is classified
Still Valid / Needs Review / Likely Superseded and the full Design Change Impact
Report is shown before any action.

In `full` review mode the TD-CHANGE-IMPACT gate (technical-director) reviews the
report before resolution; in `lean`/`solo` it is skipped with a note. The user
then decides per ADR (Mark Superseded / Update in place / Keep as-is / Skip), and
every file change — an ADR status line, the traceability index, the
`docs/architecture/change-impact-[date]-[system].md` report — has its own ask.
The cascade scope follows the changed system's workflow tier (`full` all ADRs,
`standard` critical ADRs plus those referencing the GDD, `minimal` not applicable).
Verdicts: COMPLETE (impact report saved) or BLOCKED (user declined the write).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I" ask-before-write language for each file it changes
- [ ] Has a next-step handoff at the end (`/architecture-decision`, `/architecture-review`)
- [ ] Documents that the impact report is shown before any change is made
- [ ] Documents gate TD-CHANGE-IMPACT: runs in full, skipped in lean/solo

---

## Director Gate Checks

One gate: **TD-CHANGE-IMPACT** (`technical-director`,
`.claude/docs/director-gates/td-change-impact.md`), spawned after the Design
Change Impact Report is presented and before the per-ADR resolution workflow.

- `full` → spawned with the full impact report (change summary, classifications,
  recommended actions)
- `lean` → skipped; output notes "TD-CHANGE-IMPACT skipped — Lean mode."
- `solo` → skipped; output notes "TD-CHANGE-IMPACT skipped — Solo mode."

Verdict handling: APPROVE → resolution workflow; CONCERNS → `AskUserQuestion` with
`Revise the impact assessment` / `Accept with noted concerns` / `Discuss further`;
REJECT → no resolution; the impact is re-analysed first; NOT ASSESSED [missing
input] → never read as APPROVE: the input is supplied and the gate re-run, or the
run goes on with `TD-CHANGE-IMPACT: NOT ASSESSED — [input]` stated in the report
and the Verdict line.

---

## Test Cases

### Case 1: Happy Path — GDD formula change affects one of two referencing ADRs

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: lean`
- `design/gdd/combat.md` has an uncommitted edit to a damage formula in its
  Formulas section
- `docs/architecture/` has 4 ADRs; ADR-0003 and ADR-0005 list `combat.md` in
  `## GDD Requirements Addressed`; ADR-0003's decision assumed the old formula,
  ADR-0005's decision does not depend on it
- `docs/architecture/requirements-traceability.md` exists

**Input:** `/propagate-design-change design/gdd/combat.md`

**Expected behavior:**
1. Verifies the file exists; runs `git diff HEAD -- design/gdd/combat.md` and
   derives the changed sections from the hunks
2. Prints the Change Summary (changed / unchanged sections, key changes)
3. Globs the ADRs (N = 4), greps the requirement tables and the `combat`
   basename, and reports "Loaded 4 ADRs by scan. 2 reference combat.md (…)"
4. Reads ADR-0003 and ADR-0005 (size checked with `wc -c` first) and classifies
   ADR-0003 Needs Review or Likely Superseded, ADR-0005 Still Valid
5. Presents the Design Change Impact Report
6. Notes "TD-CHANGE-IMPACT skipped — Lean mode."
7. Asks "ADR-0003 ([title]) — [status]. What would you like to do?" with the four
   options; no resolution ask for ADR-0005
8. Asks "May I update the traceability index?" and "May I write the change impact
   report to `docs/architecture/change-impact-[date]-combat.md`?"
9. Verdict: COMPLETE — change impact report saved

**Assertions:**
- [ ] What changed is taken from `git diff`, not from reading two whole documents
- [ ] Only the 2 referencing ADRs are full-read; the other 2 are not described as verified unaffected
- [ ] The full impact report is shown before any resolution ask or write
- [ ] A resolution ask is made per Needs Review / Likely Superseded ADR, one at a time
- [ ] Each file change (ADR status, traceability index, impact report) has its own ask
- [ ] "TD-CHANGE-IMPACT skipped — Lean mode." appears
- [ ] Verdict is COMPLETE after the impact report is written

---

### Case 2: Zero matches — "no impact" versus "cannot trace"

**Fixture (tables present):**
- `project.yaml`: `modes.workflow: full`
- `design/gdd/combat.md` has an uncommitted edit
- 3 ADRs, each with a `## GDD Requirements Addressed` section, none naming
  `combat.md` in the table or in prose

**Input (both fixtures):** `/propagate-design-change design/gdd/combat.md`

**Expected behavior (tables present):**
1. Both scans return 0 with N = 3
2. The files-with-matches check for `## GDD Requirements Addressed` is non-empty
3. Reports "No ADR references combat.md — no architecture impact."

**Fixture (tables absent):**
- Same GDD edit; 3 ADRs, none containing a `## GDD Requirements Addressed` section
  and none naming `combat.md`

**Expected behavior (tables absent):**
1. Both scans return 0 with N = 3; the section check is also empty
2. Reports "3 ADRs found, none contains a 'GDD Requirements Addressed' section —
   traceability cannot be computed (a `gate-pre-production` blocker). Run
   `/architecture-decision retrofit [adr]`."

**Assertions:**
- [ ] With tables present, the "no architecture impact" message is printed
- [ ] With tables absent, the skill does NOT report "no impact" — it reports that traceability cannot be computed and names `/architecture-decision retrofit [adr]`, the form that skill parses
- [ ] No per-ADR resolution ask and no ADR edit happens in either fixture
- [ ] Skill does NOT error or crash when no references are found

---

### Case 3: Edge Case — Empty diff on a GDD with history

**Fixture:**
- `project.yaml`: `modes.workflow: full`
- `design/gdd/combat.md` is committed, has no uncommitted changes, and was not
  touched by the last commit

**Input:** `/propagate-design-change design/gdd/combat.md`

**Expected behavior:**
1. `git diff HEAD -- design/gdd/combat.md` is empty
2. `git diff HEAD~1 HEAD -- design/gdd/combat.md` is also empty
3. Reports "no uncommitted or last-commit changes to `design/gdd/combat.md`" and
   asks which revision to propagate
4. Does not report "no impact" and does not scan ADRs before a revision is chosen

**Assertions:**
- [ ] Both diffs are tried, working tree first, then the last commit
- [ ] The "no uncommitted or last-commit changes" report is printed
- [ ] The user is asked which revision to propagate
- [ ] The empty diff is NOT reported as "no impact"

---

### Case 4: Edge Case — No argument provided

**Fixture:**
- Multiple GDDs exist in `design/gdd/`

**Input:** `/propagate-design-change` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Skill fails with: "Usage: `/propagate-design-change design/gdd/[system].md`
   Provide the path to the GDD that was changed."
3. No diff, scan or analysis is performed

**Assertions:**
- [ ] Skill outputs the usage message when no argument is given
- [ ] The usage example shows the `design/gdd/[system].md` path format
- [ ] No `git diff` or ADR scan is performed without a target GDD
- [ ] Skill does NOT silently pick a GDD without user input

---

### Case 5: Director Gate — TD-CHANGE-IMPACT returns CONCERNS in full mode

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: full`
- A GDD edit that leaves one referencing ADR classified Needs Review
- TD-CHANGE-IMPACT returns CONCERNS: a second ADR was under-classified

**Input:** `/propagate-design-change design/gdd/[system].md`

**Expected behavior:**
1. The Design Change Impact Report is presented
2. `technical-director` is spawned via `Agent` with gate TD-CHANGE-IMPACT, passing
   the full report
3. CONCERNS are surfaced, naming the flagged ADR
4. `AskUserQuestion`: `Revise the impact assessment` / `Accept with noted concerns`
   / `Discuss further`
5. The per-ADR resolution workflow starts only after that answer

**Assertions:**
- [ ] TD-CHANGE-IMPACT is spawned after the impact report is shown and before any resolution ask
- [ ] The gate receives the full report (change summary, classifications, recommended actions)
- [ ] The CONCERNS name the flagged ADR and all three options are offered
- [ ] No ADR, traceability or report file is written before the CONCERNS are answered
- [ ] No "TD-CHANGE-IMPACT skipped" note appears in `full` mode

---

### Case 6: Workflow tiers — `minimal` stops before the cascade; `standard` narrows it

**Fixture (minimal):**
- `project.yaml` sets no `modes` keys — `modes.rigor` defaults to `minimal`, so
  the workflow resolves to `minimal`
- `design/gdd/loot.md` has an uncommitted edit

**Fixture (standard):**
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: solo`
- `design/gdd/loot.md` has an uncommitted edit
- 4 ADRs, by their Engine Compatibility `Layer`: ADR-0001 (Foundation, event bus,
  no mention of `loot.md`), ADR-0002 (Foundation, save system, lists `loot.md` in
  `## GDD Requirements Addressed`), ADR-0006 (Feature, loot tables, names `loot.md`
  in prose only), ADR-0007 (Feature, enemy AI, no mention)

**Input (both fixtures):** `/propagate-design-change design/gdd/loot.md`

**Expected behavior (minimal):**
1. The diff and Change Summary run as usual
2. At the ADR step: "No ADR cascade at minimal workflow — design change recorded;
   no architecture impact analysis." and the skill stops

**Expected behavior (standard):**
1. The in-scope set is the Foundation ADRs plus any ADR referencing `loot.md`:
   ADR-0001, ADR-0002 and ADR-0006, so N = 3; ADR-0007 is out of scope
2. Reports "Loaded 3 ADRs by scan. 2 reference loot.md (1 via requirements table,
   1 via prose reference only)."
3. Full-reads only ADR-0002 and ADR-0006; notes "TD-CHANGE-IMPACT skipped — Solo mode."

**Assertions:**
- [ ] Minimal: no ADR is globbed or read, no gate is spawned or noted, and no write ask is made
- [ ] Standard: ADR-0007 is not counted or read, and neither it nor ADR-0001 is described as verified unaffected
- [ ] Standard: the prose-only reference in ADR-0006 is caught by the basename grep
- [ ] Standard: the Foundation ADRs are found from the `**Layer**` rows (`Grep pattern="\*\*Layer\*\*" glob="docs/architecture/adr-*.md"`), not guessed from titles
- [ ] Variant — ADR-0007 has no `**Layer**` row: it is treated as critical (when in doubt, critical) and joins the in-scope set, so N = 4

---

## Protocol Compliance

- [ ] Diffs the GDD and scans ADRs before producing the impact report
- [ ] Impact report shown in full before any resolution ask
- [ ] Resolution asked per ADR — never one decision for the whole set
- [ ] "May I" asked before each file change; ADR content is never deleted, only marked Superseded
- [ ] TD-CHANGE-IMPACT runs in `full`, skipped with a named note in `lean`/`solo`
- [ ] Ends with follow-up actions matching the resolutions (`/architecture-decision` for Superseded ADRs, `/architecture-review` when many are affected)

---

## Coverage Notes

- A system pinned `minimal` through `system_overrides` on a `standard` project
  (its change is N/A) is not given its own fixture; Case 6 reaches `minimal`
  through the project default.
- Downstream GDD impact via `design/registry/entities.yaml` is not independently
  fixture-tested.
- A GDD with no git history ("appears to be a new GDD, not a revision") and a
  path that does not exist are not separately tested.
- TD-CHANGE-IMPACT APPROVE, REJECT and NOT ASSESSED paths are not separately tested.
- Stories and epics are outside this skill's scope — it cascades into ADRs and the
  traceability index only.
