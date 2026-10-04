# Skill Test Spec: /gate-check

## Skill Summary

`/gate-check` validates whether the project is ready to advance to the next
development phase. It resolves artifact existence with
`.claude/scripts/artifact-check.sh`, spot-reads the artifacts the verdict turns
on, runs the target gate's quality checks (loaded from one file under
`.claude/skills/gate-check/references/`), asks the user about unverifiable
items, runs a director panel whose existence is set by `review_mode` and whose
width is set by `workflow`, and produces a PASS / CONCERNS / NOT ASSESSED / FAIL
verdict. On PASS with user confirmation it writes the new stage to
`project.stage` in `project.yaml` and to the legacy `production/stage.txt`. It
governs all 6 phase transitions.

The resolved config block at the top of the skill decides the tier. With no
`project.yaml`, `modes.rigor` defaults to `minimal`, which resolves
`workflow: minimal` and `review_mode: solo` — so every fixture below pins the
keys it depends on.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings (numbered Phase N or ## sections)
- [ ] Contains verdict keywords: PASS, CONCERNS, NOT ASSESSED, FAIL
- [ ] Contains "May I" write-approval language for the stage update
- [ ] Has a next-step handoff at the end (Follow-Up Actions section)

---

## Test Cases

### Case 1: Happy Path — All Concept artifacts present, advancing to Systems Design

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and `modes.review_mode: solo`
- `design/gdd/game-concept.md` exists with real content: core loop, target
  audience, a pillars section, and a Visual Identity Anchor section holding a
  one-line visual rule and 2 supporting visual principles
- No systems index and no art bible yet. `artifact-check.sh --phase concept`
  reports those catalog steps (`required=true`) as ABSENT, but neither is an item
  in the Concept → Systems Design gate file, and the loaded gate file decides what
  this gate requires
- No `/design-review` record for the concept

**Input:** `/gate-check systems-design`

**Expected behavior:**
1. Skill loads only `.claude/skills/gate-check/references/gate-systems-design.md`
2. Skill runs `bash .claude/scripts/artifact-check.sh --phase concept` to resolve
   existence, then spot-reads `design/gdd/game-concept.md` to confirm it has real
   content (not a template skeleton)
3. Skill checks pillars, the Visual Identity Anchor, core loop and target audience
4. Skill cannot find a review record, marks "Game concept has been reviewed"
   `[?] MANUAL CHECK NEEDED` and asks the user; the user confirms it was reviewed
5. Skill prints "Director Panel skipped — Solo mode. Gate verdict based on
   artifact and quality checks only."
6. Skill outputs the Section 5 report, then the Chain-of-Verification line
7. On PASS, skill asks "May I update `project.stage` in `project.yaml` to
   'Systems Design' (and the legacy `production/stage.txt`)?"
8. After the user confirms, skill writes both, re-reads both and confirms they agree

**Assertions:**
- [ ] Existence is resolved via `artifact-check.sh --phase concept`, not by opening files to see what exists
- [ ] The ABSENT systems-index and art-bible catalog steps are not reported as blockers — the catalog's `required=` flag is an observation; the gate file's checklist is what this gate requires
- [ ] `design/gdd/game-concept.md` is spot-read for real content before it is marked `[x]`
- [ ] Output includes a "Required Artifacts: [X/Y present]" section and a "Quality Checks: [X/Y passing]" section
- [ ] The unconfirmed review item is asked about, not assumed PASS
- [ ] Output includes a `### Verdict:` line with one of PASS / NOT ASSESSED / CONCERNS / FAIL
- [ ] Output includes `Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`
- [ ] Skill asks before writing, and writes BOTH `project.yaml` (`project.stage`) and `production/stage.txt` only after confirmation
- [ ] After writing, skill re-reads both files and reports any divergence instead of continuing
- [ ] The next-step recommendation is `/map-systems` (no systems index exists yet), not `/create-architecture`
- [ ] Variant: with `design/gdd/systems-index.md` already written (the catalog orders `/map-systems` in Concept), option [A] is `/design-system` for the first system in its design order instead

---

### Case 2: Failure Path — Missing required artifacts for Concept → Systems Design

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/game-concept.md` does NOT exist
- No game pillars document exists
- `design/gdd/` directory is empty or absent

**Input:** `/gate-check systems-design`

**Expected behavior:**
1. `artifact-check.sh` reports the game-concept step `ABSENT`
2. Skill marks the required artifact missing (a blocker at `full`)
3. Skill outputs FAIL verdict
4. Skill lists the missing concept document under Blockers
5. Skill recommends `/brainstorm` to create one
6. Skill does not create the missing file itself

**Assertions:**
- [ ] Verdict is FAIL (not PASS, CONCERNS or NOT ASSESSED) — FAIL is evaluated first in the precedence order
- [ ] Output explicitly names `design/gdd/game-concept.md` as missing
- [ ] Output includes a "Blockers" section with at least 1 item
- [ ] Output recommends `/brainstorm` as the remediation action
- [ ] Skill does NOT write `project.yaml` or `production/stage.txt` when the verdict is FAIL
- [ ] Skill does NOT create `design/gdd/game-concept.md` or any other missing artifact to manufacture a PASS

---

### Case 3: No Argument — Auto-detect current stage

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and has no `project:` block;
  `production/stage.txt` contains `Concept`, so the config block reports
  `project.stage: Concept (production/stage.txt)` from the legacy mirror (with no
  `project.yaml` at all the tier would resolve to `minimal`, whose gate target is
  `design/game-brief.md`, not the concept doc below)
- `design/gdd/game-concept.md` exists with content
- No systems index yet

**Input:** `/gate-check` (no argument)

**Expected behavior:**
1. Skill takes the current stage from the resolved config block (legacy
   `production/stage.txt` mirror) / project-stage-detect heuristics
2. Skill confirms with `AskUserQuestion`: "Detected stage: **Concept**. Running
   gate for Concept → Systems Design transition. Is this correct?" with options
   `[A] Yes — run this gate` / `[B] No — pick a different gate`
3. On `[A]`, skill runs the Concept → Systems Design checks
4. Output header names the transition being validated

**Assertions:**
- [ ] Current stage comes from `production/stage.txt` (via the resolved config block) or project-stage-detect heuristics
- [ ] Skill confirms the detected transition with `AskUserQuestion` before running checks — this step is never skipped when no argument is given
- [ ] The full list of six gates is shown only if the user picks `[B] No — pick a different gate`
- [ ] Output header names both phases: "Gate Check: Concept → Systems Design"

---

### Case 4: Edge Case — Manual check items: "I don't know" is not "not yet"

**Fixture:**
- `project.yaml` sets `modes.workflow: full` and `modes.review_mode: solo`
- All required artifacts for Concept → Systems Design are present, and every
  other check passes: `design/gdd/game-concept.md` holds real content with a
  pillars section, a core loop, a target audience, and a Visual Identity Anchor
  with a one-line visual rule and 2 supporting principles
- No review record exists (the "Game concept has been reviewed" check cannot be auto-verified)

**Input:** `/gate-check systems-design`

**Expected behavior:**
1. Skill verifies all artifacts exist
2. Skill reaches "Game concept has been reviewed (`/design-review` verdict not MAJOR REVISION NEEDED)"
3. No review record → item marked `[?] MANUAL CHECK NEEDED`
4. Skill asks the user whether the concept has been reviewed

**Case 4a — the user answers "I don't know":** the item stays unresolved, so the
verdict is NOT ASSESSED, not PASS.

**Case 4b — the user answers "Not yet":** the check has an answer — the concept
was not reviewed — so it ran and failed. Nothing is unknown: the verdict is
CONCERNS or FAIL (FAIL and CONCERNS are evaluated before NOT ASSESSED), with
`/design-review` named as the fix.

**Assertions:**
- [ ] Items that cannot be auto-verified are marked `[?] MANUAL CHECK NEEDED` rather than assumed PASS
- [ ] Skill uses a question to the user for at least one unverifiable quality item
- [ ] Skill does not mark unverifiable items as PASS by default
- [ ] 4a: a `MANUAL CHECK NEEDED` item the user never resolved yields NOT ASSESSED (it outranks PASS), naming the item and why in the Blockers section
- [ ] 4b: a "not yet" answer is a failed check, never an unknown — the verdict is CONCERNS or FAIL, not NOT ASSESSED and not PASS, and the output names `/design-review` (the one exception is the Production gate's play questions, where "not yet" means nobody has played it — Case 8)
- [ ] Skill does not write the stage on a NOT ASSESSED or FAIL verdict, nor on CONCERNS unless the user explicitly accepts the listed risks (Case 7)

---

### Case 5: Director Gate — panel existence (`review_mode`) vs panel width (`workflow`)

**Fixture (all sub-cases):**
- All required artifacts for Concept → Systems Design are present
- `design/gdd/game-concept.md` exists
- Review mode comes from `modes.review_mode` in `project.yaml` (legacy mirror:
  `production/review-mode.txt`) or an inline `--review` flag

**Case 5a — full panel:** `modes.review_mode: full`, `modes.workflow: full`

**Input:** `/gate-check systems-design`

**Expected behavior:**
1. Skill takes `review_mode: full` and `workflow: full` from the resolved block
2. Skill spawns all 4 PHASE-GATE directors in parallel:
   - CD-PHASE-GATE (creative-director)
   - TD-PHASE-GATE (technical-director)
   - PR-PHASE-GATE (producer)
   - AD-PHASE-GATE (art-director)
3. Director verdicts are READY / CONCERNS / NOT READY, or NOT ASSESSED when a
   gate input was missing; any CONCERNS → overall verdict at minimum CONCERNS; any
   NOT READY → overall verdict at minimum FAIL; any NOT ASSESSED (with no NOT READY
   or CONCERNS) → overall verdict at best NOT ASSESSED, naming the missing input
4. All verdicts are collected before the Director Panel summary is printed

**Assertions (5a):**
- [ ] Skill reads the resolved `review_mode` before deciding whether the panel runs
- [ ] All 4 PHASE-GATE directors are spawned (panel width comes from `workflow: full`)
- [ ] Directors are spawned in parallel (all `Agent` calls issued before any result is awaited)
- [ ] A CONCERNS verdict from any one director propagates to at least CONCERNS overall
- [ ] A NOT READY verdict from any director makes the overall verdict at least FAIL — never auto-PASS
- [ ] A director's NOT ASSESSED is never counted as READY: with no NOT READY or CONCERNS alongside it, the overall verdict is NOT ASSESSED, and the Director Panel summary shows it for that director

**Case 5b — solo mode:** `modes.review_mode: solo` (or `--review solo`)

**Expected behavior:**
1. Skill determines `solo`
2. No director spawns
3. Output states: "Director Panel skipped — Solo mode. Gate verdict based on
   artifact and quality checks only."
4. Gate verdict is derived from artifact/quality checks only

**Assertions (5b):**
- [ ] No director gates are spawned in solo mode
- [ ] The skip is stated in the output ("Director Panel skipped — Solo mode"), not silent
- [ ] Verdict is based on artifact and quality checks only
- [ ] The narrowed/skipped panel alone does not make the verdict NOT ASSESSED

**Case 5c — width follows `workflow`, not `review_mode`:** `modes.review_mode: full`, `modes.workflow: standard`

**Expected behavior:**
1. Panel runs (review mode is not `solo`) at the `standard` width: `technical-director` + `producer` only
2. Output names the omission, e.g. "Panel: 2 of 4 (`workflow: standard`).
   Creative and Art perspectives not consulted. Set `modes.workflow: full` for
   the complete panel." — `workflow` is set on its own here, so raising
   `modes.rigor` would not change it

**Assertions (5c):**
- [ ] Exactly TD-PHASE-GATE and PR-PHASE-GATE are spawned — `review_mode: full` does not widen the panel
- [ ] Output names the perspectives that did not run and how to get them: `modes.workflow: full`, the source the config block shows for `workflow`
- [ ] Output never suggests `--review full` to widen the panel — `--review` decides whether the panel runs, not its width
- [ ] The deliberately narrow panel does not by itself produce NOT ASSESSED

**Case 5d — lean mode, width from rigor:** the panel runs in `lean` (phase gates
are what lean mode keeps); its width still follows `workflow`.

- (i) `project.yaml` sets only `modes.rigor: standard` → the block resolves
  `review_mode: lean` and `workflow: standard`, both from `rigor:standard`
- (ii) `project.yaml` sets `modes.rigor: minimal` and `modes.review_mode: lean`
  (explicit — `rigor: minimal` alone would resolve `solo` and skip the panel), plus
  a filled `design/game-brief.md` → `workflow: minimal`

**Assertions (5d):**
- [ ] (i): exactly TD-PHASE-GATE and PR-PHASE-GATE are spawned, and the output reads "Panel: 2 of 4" and points to raising `modes.rigor` to `full` (that is where `workflow` came from)
- [ ] (ii): only PR-PHASE-GATE is spawned, and the output reads "Panel: 1 of 4", naming the three perspectives that did not run
- [ ] In both, lean mode does not skip the panel, and the narrow panel alone does not produce NOT ASSESSED

---

### Case 6: Director context — a later phase's artifact is "not expected", never "none"

**Fixture:**
- `project.yaml` sets only `modes.rigor: standard` → `workflow: standard`,
  `review_mode: lean`, so the panel is `technical-director` + `producer`
- The engine is configured; `design/gdd/systems-index.md` enumerates 3 MVP
  systems, each with a GDD holding the 5 standard sections, each reviewed, and a
  `/review-all-gdds` report with verdict PASS; the systems index maps
  dependencies both ways and defines the MVP tier
- No `docs/architecture/` at all (no architecture document, no ADRs), no
  `production/sprints/`, no stories

**Input:** `/gate-check technical-setup`

**Expected behavior:**
1. Skill loads `gate-technical-setup.md` and applies its `standard` reduction
2. Skill spawns TD-PHASE-GATE and PR-PHASE-GATE in parallel, passing each the
   target phase, `workflow: standard`, and the gate's required and recommended
   artifacts at that tier
3. The TD context passes the architecture document and the ADR list as
   "not expected before Pre-Production"; the PR context passes the sprint plan
   as "not expected before Production" — neither as "none"
4. Both directors return READY; every artifact and quality check passes; the
   verdict is PASS and the stage write is offered

**Variant (ii):** the same project at `/gate-check pre-production` (target
Pre-Production, which requires the architecture document at `standard`) with
the architecture document still absent: the TD context passes it as "none", a
finding for the director (CONCERNS or NOT READY), and the verdict is not PASS.

**Assertions:**
- [ ] Each director receives the target gate's required and recommended artifacts at the resolved tier, not only the phase name
- [ ] No director context passes "none" for an artifact the target gate does not require at this tier — it reads "not expected before [phase]" (or "not required at `workflow: [tier]`")
- [ ] With every director READY and every check passing, the verdict is PASS — the absent architecture document and sprint plan do not turn it into CONCERNS
- [ ] Variant (ii): an artifact the target gate requires and that does not exist is passed as "none", never "not expected", and the verdict is not PASS

---

### Case 7: CONCERNS override — the user accepts the risks; a FAIL is never overridden

**Fixture:**
- `project.yaml` sets `modes.workflow: standard` and `modes.review_mode: solo`
- `design/gdd/game-concept.md` holds a core loop and a target audience, and the
  user confirms it was reviewed; it has no pillars section and no Visual Identity
  Anchor — both recommended at `standard`, so absent → CONCERNS

**Input:** `/gate-check systems-design`, then, after the CONCERNS verdict, the
user says "advance anyway"

**Expected behavior:**
1. Verdict is CONCERNS, naming the missing pillars and Visual Identity Anchor;
   the stage write is not offered by default
2. On the user's request, skill lists both concerns and asks one question that
   both accepts them and asks to write: "…Accept these risks — [list] — and may
   I update `project.stage` in `project.yaml` to 'Systems Design' (and the
   legacy `production/stage.txt`)?"
3. On an explicit yes, the gate report gains an `### Accepted Risks` section
   (each concern, accepted by the user, dated) and both stage files are written
   and re-read

**Variant (FAIL):** `design/gdd/game-concept.md` does not exist, the verdict is
FAIL, and the user says "advance anyway": the skill does not write the stage —
no override turns a FAIL into a stage change — and names the blockers and
`/brainstorm` instead.

**Assertions:**
- [ ] On CONCERNS the stage is written only after the user explicitly accepts the listed risks, never by default
- [ ] The report records the accepted risks under `### Accepted Risks`
- [ ] Variant: on FAIL the stage is never written, whatever the user asks; the same holds for NOT ASSESSED

---

### Case 8: `/gate-check production` at `workflow: minimal` — the slice items drop

**Fixture:**
- `project.yaml` sets only `modes.rigor: minimal` → `workflow: minimal`,
  `qa.level: minimal`, `review_mode: solo`
- `design/game-brief.md` is filled, with a Build order of three MVP features
- Three story files under `production/epics/core/`, one per feature
- No `prototypes/`, no Vertical Slice, no sprint plan, no playtest report

**Input:** `/gate-check production`; the user answers yes to both current-build
questions (the core loop is fun; one start → challenge → resolution cycle runs
end to end)

**Expected behavior:**
1. Skill runs `artifact-check.sh --phase pre-production` and
   `artifact-check.sh --path minimal`; the `game-brief` and `create-stories`
   rows are the floor
2. The Vertical Slice items are not in the Required Artifacts list and raise no
   CONCERNS — at `minimal` they drop, and the two current-build checks replace
   them
3. Verdict is PASS; the stage write is offered, then the one-line rigor-fit
   nudge (Production on `rigor: minimal`)

**Variants:** "no" to "it runs end to end" → FAIL (a broken build does not
advance, as a broken slice does not at the other tiers); "not yet" to "the core
loop is fun" → NOT ASSESSED (nobody has played the build).

**Assertions:**
- [ ] No Vertical Slice item is listed as missing or turned into CONCERNS at `minimal`
- [ ] The two current-build checks are asked and carry the verdict: both yes → PASS; a "no" → FAIL; "not yet" on the fun question → NOT ASSESSED
- [ ] The floor is read from `artifact-check.sh --path minimal`, not by opening files to see what exists

---

### Case 9: A gate its tier file marks "not applicable"

**Fixture:** `project.yaml` sets `modes.rigor: minimal` and `modes.review_mode:
lean` (so a panel would otherwise run); a filled `design/game-brief.md`; no GDDs

**Input:** `/gate-check technical-setup`

**Expected behavior:** the Systems Design → Technical Setup gate is not
applicable at `minimal`: the verdict is PASS with the gate file's note ("No
design gate at minimal workflow…"), the output says "Director Panel skipped —
gate not applicable at `workflow: minimal`", and the stage write is still asked
before it is made.

**Assertions:**
- [ ] Verdict is PASS, not NOT ASSESSED — the not-applicable gate is the named exception to "a gate with no required artifacts left may not PASS"
- [ ] The gate file's note is printed, and no director is spawned
- [ ] Absent GDDs are not reported as blockers

---

## Protocol Compliance

- [ ] Asks before updating the stage ("May I update `project.stage` in `project.yaml` … (and the legacy `production/stage.txt`)?")
- [ ] Presents the full checklist report before asking for write approval
- [ ] Ends with a "Follow-Up Actions" section listing next steps per verdict
- [ ] Never advances the stage without explicit user confirmation — never on NOT ASSESSED or FAIL, and on CONCERNS only after the user explicitly accepts the listed risks, which the report records under `### Accepted Risks`
- [ ] Never auto-creates `production/stage.txt` or `project.yaml` without asking
- [ ] Never creates missing artifacts to turn a FAIL into a PASS

---

## Coverage Notes

- The Production → Polish and Polish → Release gates are not covered here
  because they require complex multi-artifact setups (sprint plans, playtest
  data, QA sign-off); these are deferred to dedicated follow-up specs.
- The `minimal`-tier Concept gate target (`design/game-brief.md` instead of
  `game-concept.md`) and `system_overrides` key validation are not covered.
- The Vertical Slice validation block (Pre-Production → Production gate at
  `standard`/`full`) is not covered because it requires a playable build context
  that cannot be expressed as a document fixture; at `minimal` it drops (Case 8).
