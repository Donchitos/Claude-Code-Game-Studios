# Skill Test Spec: /reverse-document

## Skill Summary

`/reverse-document <type> <path>` works backwards from existing implementation to
a document. `type` is `design` (a GDD, written to `design/gdd/[system-name].md`),
`architecture` (an ADR, written to `docs/architecture/[decision-name].md`) or
`concept` (a concept doc from a prototype). It reads the code, runs a
sufficiency check (stopping when there is too little implementation to infer
from), presents its findings with the questions code cannot answer, drafts the
document, and asks "May I write this to [output path]?".

The `design` output scales with the resolved workflow tier: an 8-section GDD at
`full`, a 5-section GDD at `standard`, a one-page brief at `minimal`.
`architecture` and `concept` outputs are tier-independent. Intent the user did
not confirm is carried into the document marked `INTENT UNKNOWN — inferred from
implementation, not confirmed`, and every document carries a
"Reverse-documented from implementation" provenance banner. No director gates
apply. Verdicts: COMPLETE (document written after approval) or BLOCKED (user
declined the write).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language before writing the doc
- [ ] Has a next-step handoff (Phase 8 follow-up list, e.g. `/balance-check`)

---

## Director Gate Checks

None. `/reverse-document` is a documentation utility. No director gates apply.

---

## Test Cases

### Case 1: Well-Structured Source at `full` — 8-section GDD produced

**Fixture:**
- `project.yaml` resolves `workflow: full`; no `system_overrides` row for health
- `src/gameplay/health_system.gd` exists (~80 lines) with:
  - `@export var max_health: int = 100`
  - `func take_damage(amount: int)` containing
    `health = clamp(health - amount, 0, max_health)`
  - `signal health_changed(new_value: int)`
  - Docstrings on all public methods
- The user answers every `UNCLEAR INTENT AREAS` question and approves the write

**Input:** `/reverse-document design src/gameplay/health_system.gd`

**Expected behavior:**
1. Skill reads the source and passes the Phase 3b sufficiency check
2. Skill presents findings (MECHANICS IMPLEMENTED, FORMULAS DISCOVERED,
   UNCLEAR INTENT AREAS) and waits for answers before drafting
3. Skill drafts an 8-section GDD (Overview, Player Fantasy, Detailed Rules,
   Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria)
4. The Formulas section records the clamp expression; Tuning Knobs lists
   `max_health = 100`
5. The provenance banner ("Reverse-documented from implementation … from
   `src/gameplay/health_system.gd`") sits directly under the title
6. Skill asks "May I write this to `design/gdd/health-system.md`?"
7. File written on approval; verdict is COMPLETE

**Assertions:**
- [ ] Findings are presented and answered before any draft is shown
- [ ] All 8 GDD sections are present (tier resolved as `full`)
- [ ] The clamp expression appears in Formulas; `max_health = 100` appears as a Tuning Knob
- [ ] The provenance banner appears directly under the title
- [ ] "May I write" names the path under `design/gdd/`
- [ ] Verdict is COMPLETE

---

### Case 2: Unanswered Intent — INTENT UNKNOWN carried into the draft

**Fixture:**
- `project.yaml` resolves `workflow: full`
- `src/gameplay/enemy_ai.gd` exists (~120 lines) with:
  - A patrol/chase/attack state machine
  - Inline constants with use sites: `if distance < 150:`, `speed = 3.5`
  - No arithmetic expression that computes a gameplay value from inputs
  - No comments or docstrings
- The user replies "just draft it" without answering the intent questions, then
  approves the write

**Input:** `/reverse-document design src/gameplay/enemy_ai.gd`

**Expected behavior:**
1. Sufficiency check passes (mechanics and tuning values found)
2. Findings list the state machine under MECHANICS IMPLEMENTED, the two
   constants as values, and `FORMULAS DISCOVERED: none found in the source`
3. UNCLEAR INTENT AREAS asks what the constants represent (e.g. whether 150 is
   an aggro range and in what units)
4. Because the questions go unanswered, the draft carries each one verbatim as
   an open question marked `INTENT UNKNOWN — inferred from implementation, not
   confirmed` — it does not present an inferred intent as settled
5. No formula is invented to fill the Formulas section
6. Skill asks "May I write this to `design/gdd/enemy-ai.md`?"; verdict COMPLETE
   on approval

**Assertions:**
- [ ] `FORMULAS DISCOVERED` reads `none found in the source` (heading kept, not omitted)
- [ ] Each unanswered question appears in the document marked `INTENT UNKNOWN — inferred from implementation, not confirmed`
- [ ] No formula or design intent absent from the code appears in the draft
- [ ] "May I write" is asked before the file is written
- [ ] Verdict is COMPLETE

---

### Case 3: Architecture Type on Interdependent Files — tier-independent ADR

**Fixture:**
- `project.yaml` resolves `workflow: minimal`
- `src/core/combat/` holds `combat_system.gd` and `damage_resolver.gd`;
  `combat_system.gd` calls `damage_resolver.gd` through an injected reference
- The user answers the architecture questions and approves the write

**Input:** `/reverse-document architecture src/core/combat/`

**Expected behavior:**
1. Skill reads every file under the directory path
2. Phase 2 architecture analysis maps the dependency and coupling between the
   two files (combat_system → damage_resolver)
3. Phase 3 asks architecture-intent questions (e.g. why the resolver is
   injected) rather than only describing the code
4. Draft uses the `architecture-doc-from-code.md` template — the `minimal` tier
   does NOT turn it into a one-page brief
5. Skill asks "May I write this to `docs/architecture/[decision-name].md`?";
   verdict COMPLETE on approval

**Assertions:**
- [ ] Both files are analyzed, and the combat_system → damage_resolver dependency is documented
- [ ] Output is an ADR at `docs/architecture/`, not `design/gdd/` or a `-brief.md`
- [ ] The `minimal` tier does not change the architecture output
- [ ] Verdict is COMPLETE

---

### Case 4: Thin Source — Sufficiency check stops the run

**Fixture:**
- `src/gameplay/inventory_system.gd` exists with only
  `class_name InventorySystem`, `extends Node` and an empty `_ready()` —
  no mechanics, no formulas, no tuning values (under 20 non-boilerplate lines)

**Input:** `/reverse-document design src/gameplay/inventory_system.gd`

**Expected behavior:**
1. Skill reads the file; Phase 3b counts 0 mechanics, 0 formulas, 0 values
2. Skill stops with: "`src/gameplay/inventory_system.gd` does not contain enough
   implementation to reverse-document. Found: 0 mechanics, 0 formulas, 0 tuning
   values. …"
3. Skill points to `/design-system [name]` as the skill that captures a design
   that exists only in the user's head
4. No findings are presented, no draft is produced, no file is written

**Assertions:**
- [ ] The stop message names the path and the three counts (all 0)
- [ ] `/design-system` is suggested — not a fabricated skeleton
- [ ] No write tool is called
- [ ] No verdict is issued (the run stops before Phase 4)

---

### Case 5: Director Gate Check — No gate; declined write is BLOCKED

**Fixture:**
- Same source as Case 1; the user declines at the "May I write" prompt

**Input:** `/reverse-document design src/gameplay/health_system.gd`

**Expected behavior:**
1. Skill analyzes, presents findings, and drafts the document
2. No director agents are spawned; no gate IDs appear in output
3. User declines the write; no file is created

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is BLOCKED (user declined write) — no gate verdict involved

---

### Case 6: Default Tier — a single system becomes a one-page brief

**Fixture:**
- `project.yaml` sets no `modes.rigor` and no `modes.workflow`, so the resolved
  tier is `minimal` — the default; no `system_overrides`
- Same source as Case 1 (`src/gameplay/health_system.gd`)
- The user answers every `UNCLEAR INTENT AREAS` question and approves the write

**Input:** `/reverse-document design src/gameplay/health_system.gd`

**Expected behavior:**
1. The tier resolves to `minimal` from the config block, not assumed
2. Findings are presented and answered before any draft
3. The draft is a one-page game brief in the `.claude/docs/templates/game-brief.md`
   format — not a GDD — for this one system
4. The provenance banner sits directly under the title
5. Skill asks "May I write this to `design/health-system-brief.md`?" — not
   `design/gdd/` and not `design/game-brief.md`, which is the whole-game brief
6. File written on approval; verdict COMPLETE

**Assertions:**
- [ ] The output is a brief in the game-brief format, not an 8- or 5-section GDD
- [ ] The path is `design/[system-name]-brief.md`
- [ ] The provenance banner appears under the title
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Reads the source before generating any content
- [ ] Stops at the Phase 3b sufficiency check when mechanics, formulas and values all count zero
- [ ] Waits for answers to the intent questions; unanswered ones are carried as `INTENT UNKNOWN`
- [ ] `design` output matches the resolved tier (8 sections at `full`, 5 at `standard`, brief at `minimal`)
- [ ] Emits the provenance banner under the title of every document it writes
- [ ] Asks "May I write" before creating any output file
- [ ] Verdict is COMPLETE (written) or BLOCKED (write declined)

---

## Coverage Notes

- The `standard` tier (5-section GDD without Player Fantasy and Tuning Knobs)
  follows Case 1's flow with a different section set; not separately
  fixture-tested. The `minimal` brief is Case 6.
- The `concept` type (prototype → `prototypes/[name]/CONCEPT.md` or
  `design/concepts/[name].md`) is not separately tested.
- `guided` and `autonomous` automation modes change the write prompt per
  `automation-modes.md`; only `collaborative` is tested here.
