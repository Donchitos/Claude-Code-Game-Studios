# Skill Test Spec: /adopt

## Skill Summary

`/adopt` audits an existing project's artifacts — GDDs, ADRs, stories, infrastructure
files, and `technical-preferences.md` — for format compliance with the template's
skill pipeline. It classifies every gap by severity (BLOCKING / HIGH / MEDIUM / LOW),
composes a numbered, ordered migration plan, and writes it to `docs/adoption-plan-[date].md`
after explicit user approval via `AskUserQuestion`.

The resolved `workflow` tier scopes the audit: `full` requires all 8 GDD sections,
`standard` requires 5 (+ Formulas for numeric systems), and `minimal` — the
default, since `modes.rigor` defaults to `minimal` — audits `design/game-brief.md`
instead and checks any existing GDD only advisorily, and the plan prescribes no
infrastructure bootstrap (`/architecture-review`, `/create-control-manifest`,
`/sprint-plan`, `/gate-check` are not on the minimal path). Fixtures that exercise the
GDD and ADR audits therefore set `modes.rigor: full` in `project.yaml`.

A v1.0 project (no `project.yaml`, legacy config with real values) is migrated
only by `.claude/scripts/migrate-v1-config.sh` — `--dry-run` first, the real run
after an ask naming the files it writes, and `--finalize` left until the user
has read the migration report. `/adopt` never writes a review mode; it reports
the resolved one.

This skill is distinct from `/project-stage-detect` (which checks what exists).
`/adopt` checks whether what exists will actually work with the template's skills.

No director gates apply. The skill does NOT invoke any director agents.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains severity tier keywords: BLOCKING, HIGH, MEDIUM, LOW
- [ ] Contains "May I write" or `AskUserQuestion` language before writing the adoption plan
- [ ] Has a next-step handoff at the end (e.g., offering to fix the highest-priority gap immediately)

---

## Director Gate Checks

None. `/adopt` is a brownfield audit utility. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — All GDDs compliant, no BLOCKING or HIGH gaps

**Fixture:**
- `project.yaml` sets `modes.rigor: full`, `project.stage`, and `engine.name`,
  `engine.version`, `engine.language`, `engine.rendering`, `engine.physics`
- `design/gdd/` contains 3 GDD files; each has all 8 required sections with content
  and a valid `> **Status**:` field
- `docs/architecture/adr-0001.md` exists with `## Status`, `## ADR Dependencies`,
  `## Engine Compatibility`, `## GDD Requirements Addressed` and `## Performance Implications`
- `docs/architecture/tr-registry.yaml` and `docs/architecture/control-manifest.md` exist
- `docs/engine-reference/[engine]/VERSION.md` exists

**Input:** `/adopt`

**Expected behavior:**
1. Skill emits "Scanning project artifacts..." then reads all artifacts silently
2. Reports detected phase, GDD count, ADR count, story count
3. Phase 2 audit: `gdd-structure-check.sh` is run once per GDD path; all 3 GDDs
   have all 8 sections and a valid Status field
4. ADR audit: all critical sections present
5. Infrastructure audit: registry, manifest and engine reference all exist
6. Phase 3: zero BLOCKING and zero HIGH gaps — the project is reported
   template-compatible with only advisory improvements remaining (any MEDIUM/LOW
   item, e.g. a missing `sprint-status.yaml`, is listed as advisory)
7. Uses `AskUserQuestion` to ask about writing the plan; user selects write
8. Adoption plan is written to `docs/adoption-plan-[date].md`
9. Phase 6b reports the resolved review mode ("Review mode resolves to `full` —
   from `modes.rigor`, unless something pins it") and writes nothing for it
10. Phase 7 takes the "no BLOCKING or HIGH" branch: "No blocking gaps — this project
   is template-compatible. What next?"

**Assertions:**
- [ ] Skill reads silently before presenting any output
- [ ] "Scanning project artifacts..." appears before the silent read phase
- [ ] `gdd-structure-check.sh` is invoked with an explicit path per GDD (not bare)
- [ ] Gap counts show `BLOCKING: 0` and `HIGH: 0`, and the project is reported template-compatible
- [ ] `AskUserQuestion` is used before writing the adoption plan
- [ ] Adoption plan file is written to `docs/adoption-plan-[date].md`
- [ ] `modes.review_mode` is not written to `project.yaml` and `production/review-mode.txt` is not created — the review mode is reported, never pinned
- [ ] Phase 7 asks "No blocking gaps — this project is template-compatible. What next?" via `AskUserQuestion`

---

### Case 2: Non-Compliant Documents — GDDs missing sections, BLOCKING and HIGH gaps

**Fixture:**
- `project.yaml` sets `modes.rigor: full` and configures the engine
- `design/gdd/` contains 2 GDD files:
  - `combat.md` — missing `## Acceptance Criteria` and `## Formulas` sections
  - `movement.md` — all 8 sections present
- One ADR (`adr-0001.md`) is missing `## Status` section
- `docs/architecture/tr-registry.yaml` does not exist

**Input:** `/adopt`

**Expected behavior:**
1. Skill scans all artifacts
2. Phase 2 audit finds:
   - `combat.md`: 2 missing sections (Acceptance Criteria, Formulas)
   - `adr-0001.md`: missing `## Status` — BLOCKING impact
   - `tr-registry.yaml`: missing — HIGH impact
3. Phase 3 classifies:
   - BLOCKING: `adr-0001.md` missing `## Status` (story-readiness silently passes)
   - HIGH: `tr-registry.yaml` missing; `combat.md` missing Acceptance Criteria (can't generate stories)
   - MEDIUM: `combat.md` missing Formulas
4. Phase 4 builds ordered migration plan:
   - Step 1 (BLOCKING): Add `## Status` to `adr-0001.md` — command: `/architecture-decision retrofit`
   - Step 2 (HIGH): Run `/architecture-review` to bootstrap tr-registry.yaml
   - Step 3 (HIGH): Add Acceptance Criteria to `combat.md` — command: `/design-system retrofit`
   - Step 4 (MEDIUM): Add Formulas to `combat.md`
5. Gap Preview shows BLOCKING items as bullets (actual file names), HIGH/MEDIUM as counts
6. `AskUserQuestion` asks to write the plan; writes after approval
7. Phase 7 offers to fix the highest-priority gap (ADR Status) immediately

**Assertions:**
- [ ] BLOCKING gaps are listed as explicit file-name bullets in the Gap Preview
- [ ] HIGH and MEDIUM shown as counts in Gap Preview
- [ ] Migration plan items are in BLOCKING-first order
- [ ] Each plan item includes the fix command or manual steps
- [ ] `AskUserQuestion` is used before writing
- [ ] Phase 7 offers to immediately retrofit the first BLOCKING item

---

### Case 3: Mixed State — Some docs compliant, some not, partial report

**Fixture:**
- `project.yaml` sets `modes.rigor: full` and configures engine, naming and performance
- 4 GDD files: 2 fully compliant, 2 with gaps (one missing Tuning Knobs, one missing Formulas)
- ADRs: 3 files — 2 compliant, 1 missing `## ADR Dependencies`
- Stories: 5 files — 3 have TR-ID references, 2 do not
- Infrastructure: all critical files present

**Input:** `/adopt`

**Expected behavior:**
1. Skill audits all artifact types
2. Adoption Audit Summary shows `GDDs audited: 4 (2 fully compliant, 2 with gaps)`,
   `ADRs audited: 3 (2 fully compliant, 1 with gaps)` and `Stories audited: 5`
3. Gap classification:
   - No BLOCKING gaps
   - HIGH: 1 ADR missing `## ADR Dependencies`
   - MEDIUM: 2 GDDs with missing sections (Tuning Knobs, Formulas); 2 stories missing TR-IDs
4. Gap Preview has no BLOCKING bullets and shows HIGH / MEDIUM as counts
5. Migration plan lists the HIGH gap first, then MEDIUM gaps with GDD gaps before story gaps
6. Note included: "Existing stories continue to work — do not regenerate stories
   that are in progress or done"
7. `AskUserQuestion` to write plan; writes after approval

**Assertions:**
- [ ] Summary shows GDD and ADR tallies as `N (X fully compliant, Y with gaps)` and `Stories audited: 5`
- [ ] Summary shows `BLOCKING: 0` and the Gap Preview lists no BLOCKING bullets
- [ ] The 2 stories without TR-IDs are counted as MEDIUM gaps
- [ ] Existing story compatibility note is included in the plan
- [ ] HIGH gap precedes MEDIUM gaps; MEDIUM GDD gaps precede MEDIUM story gaps
- [ ] `AskUserQuestion` is used before writing

---

### Case 4: No Artifacts Found — Fresh project, guidance to run /start

**Fixture:**
- Repository has no files in `design/gdd/`, `docs/architecture/`, `production/epics/`
- No `project.stage` in `project.yaml` and no `production/stage.txt`
- No source code: none of `src/`, `Assets/` or `Source/` exists
- No game-concept.md, no game-brief.md, no systems-index.md

**Input:** `/adopt`

**Expected behavior:**
1. Phase 1 existence check finds no artifacts
2. Skill infers "Fresh" — no brownfield work to migrate
3. Uses `AskUserQuestion`:
   - "This looks like a fresh project — no existing artifacts found. `/adopt` is for
     projects with work to migrate. What would you like to do?"
   - Options: "Run `/start`", "My artifacts are in a non-standard location", "Cancel"
4. Skill stops — does not proceed to audit regardless of user selection

**Assertions:**
- [ ] `AskUserQuestion` is used (not a plain text message) when no artifacts are found
- [ ] `/start` is presented as a named option
- [ ] Skill stops after the question — no audit phases run
- [ ] No adoption plan file is written

---

### Case 5: Director Gate Check — No gate; minimal tier scopes the audit to the brief

**Fixture:**
- `project.yaml` configures the engine and has no `modes` block (`workflow`
  resolves to `minimal`)
- `design/game-brief.md` exists
- `design/gdd/combat.md` exists and is missing `## Acceptance Criteria`

**Input:** `/adopt`

**Expected behavior:**
1. Phase 2 audits `design/game-brief.md`; GDDs, ADRs and UX specs are not expected
2. `combat.md` is checked at the `standard` bar advisorily — its missing Acceptance
   Criteria is reported as informational, not as a HIGH gap
3. The plan does not prescribe the infrastructure bootstrap: its Step 3 says in
   one line that it is not on the minimal path and names `/create-stories` as
   the next step (no stories exist)
4. No director agents are spawned at any point
5. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in output
6. No `/gate-check` is invoked during the skill run

**Assertions:**
- [ ] `design/game-brief.md` is audited
- [ ] Absent ADRs and UX specs are not reported as gaps
- [ ] `combat.md`'s missing Acceptance Criteria is not counted in the HIGH total
- [ ] The plan prescribes none of `/architecture-review`, `/create-control-manifest`, `/sprint-plan` or `/gate-check` — none is on the minimal path
- [ ] No director gate is invoked and no gate skip messages appear
- [ ] Skill reaches plan-writing or cancellation without any gate verdict

---

### Case 6: v1.0 Project — Converter run, never hand-migrated

**Fixture:**
- No `project.yaml` at the repo root
- `production/stage.txt` reads `Production`; `.claude/docs/technical-preferences.md`
  has `- **Engine**: Godot 4.6` and a filled naming section
- `design/gdd/` holds GDDs; no `production/migration-report.md`

**Input:** `/adopt`

**Expected behavior:**
1. Phase 2g identifies a v1.0 project needing migration (no `project.yaml`,
   legacy files with real, migratable values)
2. It runs `bash .claude/scripts/migrate-v1-config.sh --dry-run` during the
   audit (the dry run writes nothing) — it does not hand-write `project.yaml`
3. The migration is classified BLOCKING in Phase 3 and heads the plan, which
   reports what the dry run listed
4. After the plan, Phase 7 offers the migration first: it asks "May I run the
   converter? It writes `project.yaml` and `production/migration-report.md`."
   and runs it without `--dry-run` only after approval
5. It tells the user to read `production/migration-report.md` before running
   `bash .claude/scripts/migrate-v1-config.sh --finalize`, and does not run
   `--finalize` itself before the user has read the report

**Assertions:**
- [ ] `--dry-run` runs before any real migration, and its output is reported
- [ ] `project.yaml` is written only by the converter, after the ask naming `project.yaml` and `production/migration-report.md` is approved
- [ ] `--finalize` is not run before the user has read `production/migration-report.md`
- [ ] The migration is a BLOCKING item, first in the plan
- [ ] No legacy file is deleted during the run

---

## Protocol Compliance

- [ ] Emits "Scanning project artifacts..." before silent read phase
- [ ] Reads all artifacts silently before presenting any results
- [ ] Shows Adoption Audit Summary and Gap Preview before asking to write
- [ ] Uses `AskUserQuestion` before writing the adoption plan file
- [ ] Adoption plan written to `docs/adoption-plan-[date].md` — not to any other path
- [ ] Migration plan items ordered: BLOCKING first, HIGH second, MEDIUM third, LOW last
- [ ] Phase 7 always offers a single specific next action (not a generic list)
- [ ] Never regenerates existing artifacts — only fills gaps in what exists
- [ ] Does not invoke director gates at any point

---

## Coverage Notes

- The `gdds`, `adrs`, `stories`, and `infra` argument modes narrow the audit scope;
  each follows the same pattern as the full audit but limited to that artifact type.
  Not separately fixture-tested here.
- The systems-index.md parenthetical status value check (BLOCKING) is a special case
  that triggers an immediate fix offer before writing the plan; not separately tested.
- Phase 6b reports the resolved review mode and writes nothing — `review_mode` is
  fronted by `modes.rigor`, so pinning it would shadow the rigor expansion; Case 1
  asserts that nothing is written for it.
- The converter's refusals (exit 3 when its values disagree or a migration
  already ran; `--finalize` exiting 4 on a mismatch) are not separately tested;
  Case 6 covers the migration itself.
