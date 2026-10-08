# Skill Test Spec: /scope-check

## Skill Summary

`/scope-check` is a Haiku-tier read-only skill that compares a feature's,
sprint's or milestone's original planned scope against what has actually been
implemented. It takes the whole argument string — a feature name (which may be
several words), a sprint number, or a milestone name — and locates the baseline
at `design/gdd/[feature].md` (or a matching file in `design/`),
`production/sprints/sprint-NNN.md`, or `production/milestones/[name].md`. If the
baseline is absent it reports the missing file and stops. It then reads the
current state (related source files, `git log`, TODO/FIXME comments, the active
sprint plan) and produces a comparison report: Original Scope, Current Scope,
Scope Additions, Scope Removals, a Bloat Score, a Risk Assessment and
Cut / Defer / Keep / Flag recommendations. The verdict follows the net scope
change: ≤10% PASS, >10–25% CONCERNS, >25% FAIL. When the percentage would be
meaningless — a baseline that enumerates no items, or a current state that
cannot be read — the verdict is NOT ASSESSED and the numeric block is replaced.
No files are written and no director gates are invoked.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, CONCERNS, NOT ASSESSED, FAIL
- [ ] Does NOT require "May I write" language (the skill states it is read-only and `allowed-tools` has no Write/Edit)
- [ ] Has a next-step handoff (Phase 5: follow-up per verdict)

---

## Director Gate Checks

None. Scope check is a read-only advisory skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Multi-word feature on track

**Fixture:**
- `design/gdd/inventory-crafting-system.md` enumerates 20 scope items
- `src/gameplay/inventory/` and `src/gameplay/crafting/` implement all 20, plus one addition (item sorting) found in a recent commit
- No items were dropped

**Input:** `/scope-check inventory crafting system`

**Expected behavior:**
1. Skill uses the whole argument, "inventory crafting system", to locate the baseline — not only "inventory"
2. Skill reads `design/gdd/inventory-crafting-system.md` as the baseline (Phase 1)
3. Skill reads the current state: related source files, `git log --oneline` for the work, TODO/FIXME comments (Phase 2)
4. Report lists Original Scope and Current Scope; the Scope Additions table names item sorting with its source, date, justification and effort
5. Bloat Score: 20 original, 21 current, 1 added (+5%), 0 removed
6. Verdict: **PASS** — On Track
7. Phase 5: no action required; suggests re-running before the next milestone; ends with "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

**Assertions:**
- [ ] The baseline is located from the full multi-word argument, not its first word
- [ ] The addition is named in the Scope Additions table with source, when, justified and effort columns
- [ ] Bloat Score shows original, current, added and removed counts and the net percentage
- [ ] Verdict is PASS for a net change ≤10%
- [ ] No files are written

---

### Case 2: Significant Creep — Sprint gained unplanned items

**Fixture:**
- `production/sprints/sprint-003.md` lists 8 planned stories
- Commits since the sprint start add an online leaderboard, an achievement system and a photo mode, none of which appear in the sprint plan
- No planned stories were dropped

**Input:** `/scope-check sprint-3`

**Expected behavior:**
1. Skill reads `production/sprints/sprint-003.md` as the baseline
2. Skill finds the three additions from `git log` and the source tree
3. Scope Additions table names all three; Bloat Score shows 8 original, 11 current, +37.5%
4. Recommendations sort items into Cut / Defer / Keep / Flag
5. Verdict: **FAIL** — Significant Creep
6. Phase 5: recommends escalating to the producer and references `/sprint-plan update` for re-planning or `/estimate` to re-baseline

**Assertions:**
- [ ] Each unplanned addition is named explicitly in the Scope Additions table
- [ ] Verdict is FAIL for a net change between 25% and 50%
- [ ] Output recommends escalating to the producer and references `/sprint-plan update` or `/estimate`
- [ ] Skill does not edit the sprint plan or remove stories — findings are advisory

---

### Case 3: Baseline Missing — Report the missing file and stop

**Fixture:**
- No `design/gdd/crafting.md` and no file in `design/` matches "crafting"
- `src/gameplay/crafting/` contains implemented code

**Input:** `/scope-check crafting`

**Expected behavior:**
1. Phase 1 looks for `design/gdd/crafting.md` and a matching file in `design/`; none exists
2. Skill reports which baseline file was missing and stops
3. No comparison report, Bloat Score or percentage is produced

**Assertions:**
- [ ] Output names the baseline file it looked for and did not find
- [ ] Skill stops at Phase 1 — no Phase 3 comparison report is rendered
- [ ] No percentage and no PASS verdict are produced without a baseline
- [ ] No files are written

---

### Case 4: Empty Baseline — NOT ASSESSED, not 0%

**Fixture:**
- `design/gdd/dialogue.md` exists but contains only section headings and `[TO BE CONFIGURED]` placeholders — no scope items
- `src/narrative/dialogue/` contains implemented code

**Input:** `/scope-check dialogue`

**Expected behavior:**
1. Phase 1 finds the baseline document, so it does not stop there
2. Phase 4 detects that the baseline enumerates no scope items
3. The Bloat Score block is replaced with `Baseline unusable — see verdict` and the reason; no `Original items: 0` or `Net scope change: 0%` is rendered
4. Verdict: **NOT ASSESSED**, stating that the baseline side could not be read and why
5. Phase 5: says the baseline document needs populating; does not offer a re-run against the same inputs

**Assertions:**
- [ ] Verdict is NOT ASSESSED, never PASS, when the baseline has no items
- [ ] No computed percentage appears anywhere in the report
- [ ] Output says which side was unusable and what would fix it (populate the baseline document)
- [ ] Skill does not offer a re-run against the same inputs

---

### Case 4b: Unreadable Current State — NOT ASSESSED, not −100%

**Fixture:**
- `production/sprints/sprint-004.md` lists 6 planned stories
- No source files relate to those stories, `git log` shows no commits since the sprint start, and nothing is marked in progress

**Input:** `/scope-check sprint-4`

**Expected behavior:**
1. Phase 1 reads `production/sprints/sprint-004.md` as the baseline — 6 items
2. Phase 2 finds nothing to read for the current state
3. Phase 4 emits NOT ASSESSED instead of computing a change: 0 current items would compute −100%, which the ≤10% row would read as PASS
4. The Bloat Score block is replaced with `Current state unusable — see verdict`; no `Current items: 0` or percentage is rendered
5. The verdict says the current-state side could not be read and why, and Phase 5 says what would fix it (point the skill at where the work lives) without offering a re-run on the same inputs

**Assertions:**
- [ ] Verdict is NOT ASSESSED, never PASS
- [ ] No −100% (or any percentage) appears in the report
- [ ] Output names the current state as the side that could not be read
- [ ] Skill does not offer a re-run against the same inputs

---

### Case 5: Minor Creep in Full Review Mode — CONCERNS, no gates

**Fixture:**
- `project.yaml` has `modes.review_mode: full`
- `production/milestones/alpha.md` enumerates 10 scope items
- Current state has all 10 plus two additions (a settings menu rework and an extra enemy type)

**Input:** `/scope-check alpha`

**Expected behavior:**
1. Skill reads `production/milestones/alpha.md` as the baseline
2. Bloat Score: 10 original, 12 current, +20%
3. Verdict: **CONCERNS** — Minor Creep
4. No director gate is invoked regardless of review mode
5. Phase 5: offers to identify the 2–3 additions with the best cut ratio and references `/sprint-plan update`
6. Skill ends without writing any files

**Assertions:**
- [ ] Verdict is CONCERNS for a net change between 10% and 25%
- [ ] No director gate is invoked in any review mode
- [ ] Output offers to identify the additions with the best cut ratio and references `/sprint-plan update`
- [ ] No files are written

---

## Protocol Compliance

- [ ] Locates the baseline document (`design/gdd/`, `production/sprints/`, `production/milestones/`) before any comparison, and stops if it is absent
- [ ] Reads the current state from source files, `git log`, TODO/FIXME comments and the active sprint plan
- [ ] Verdict follows the net-change table: ≤10% PASS, >10–25% CONCERNS, >25% FAIL
- [ ] Emits NOT ASSESSED instead of a percentage when the baseline has no items or the current state cannot be read
- [ ] Does not write any files
- [ ] No director gates are invoked
- [ ] Declares `model: haiku` (when a declared tier is used: `.claude/docs/model-tiers.md`)

---

## Coverage Notes

- The >50% "Out of Control" band shares the FAIL verdict with Case 2 and is not
  tested separately.
