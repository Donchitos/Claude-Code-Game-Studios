# Skill Test Spec: $reverse-document

## Skill Summary

`$reverse-document` generates design or architecture documentation from existing
source code. It reads the specified source file(s), infers design intent from
class structure, method names, constants, and comments, and produces either a
GDD skeleton (for gameplay systems) or an architecture overview (for technical
systems). The output is a best-effort inference — magic numbers and undocumented
logic may result in a PARTIAL verdict.

The skill asks "May I write to [inferred path]?" before creating the document.
No director gates apply. Verdicts: COMPLETE (clean inference), PARTIAL (some
fields are ambiguous and need human review).

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, PARTIAL
- [ ] Contains "May I write" collaborative protocol language before writing the doc
- [ ] Has a next-step handoff (e.g., `$design-review` to validate the generated doc)

---

## Director Gate Checks

None. `$reverse-document` is a documentation utility. No director gates apply.

---

## Test Cases

### Case 1: Well-Structured Source — Accurate design doc skeleton produced

**Fixture:**
- `src/gameplay/health_system.gd` exists with:
  - `@export var max_health: int = 100`
  - `func take_damage(amount: int)` with clamping logic
  - `signal health_changed(new_value: int)`
  - Docstrings on all public methods

**Input:** `$reverse-document src/gameplay/health_system.gd`

**Expected behavior:**
1. Skill reads the source file and identifies the health system
2. Skill infers design intent: max health, take_damage behavior, health signal
3. Skill produces GDD skeleton for health system with 8 required sections:
   Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies,
   Tuning Knobs, Acceptance Criteria
4. Formulas section includes the inferred clamping formula
5. Tuning Knobs notes `max_health = 100` as a configurable value
6. Skill asks "May I write to `design/gdd/health-system.md`?"
7. File written; verdict is COMPLETE

**Assertions:**
- [ ] All 8 required GDD sections are present in the output
- [ ] `max_health = 100` appears as a Tuning Knob
- [ ] Clamping formula is captured in the Formulas section
- [ ] "May I write" is asked with the inferred path
- [ ] Verdict is COMPLETE

---

### Case 2: Ambiguous Source — Magic Numbers, PARTIAL Verdict

**Fixture:**
- `src/gameplay/enemy_ai.gd` exists with:
  - Inline magic numbers: `if distance < 150:`, `speed = 3.5`
  - No comments or docstrings
  - Complex state machine logic that is not self-explanatory

**Input:** `$reverse-document src/gameplay/enemy_ai.gd`

**Expected behavior:**
1. Skill reads the file and detects magic numbers with no context
2. Skill produces a GDD skeleton with notes: "AMBIGUOUS VALUE: 150 (unknown units —
   is this pixels, world units, or tiles?)"
3. Skill marks the Formulas and Tuning Knobs sections as requiring human review
4. Skill asks "May I write to `design/gdd/enemy-ai.md`?" with PARTIAL advisory
5. File written with PARTIAL markers; verdict is PARTIAL

**Assertions:**
- [ ] AMBIGUOUS VALUE annotations appear for magic numbers
- [ ] Sections needing human review are marked explicitly
- [ ] Verdict is PARTIAL (not COMPLETE)
- [ ] File is still written — PARTIAL is not a blocking failure

---

### Case 3: Multiple Interdependent Files — Cross-System Overview Produced

**Fixture:**
- User provides 2 source files: `combat_system.gd` and `damage_resolver.gd`
- The files reference each other (combat calls damage_resolver)

**Input:** `$reverse-document src/gameplay/combat_system.gd src/gameplay/damage_resolver.gd`

**Expected behavior:**
1. Skill reads both files and detects the dependency relationship
2. Skill produces a cross-system architecture overview (not individual GDDs)
3. Overview describes: Combat System → Damage Resolver interaction, shared
   interfaces, data flow between the two
4. Skill asks "May I write to `docs/architecture/combat-damage-overview.md`?"
5. Overview written after approval; verdict is COMPLETE (or PARTIAL if ambiguous)

**Assertions:**
- [ ] Both files are analyzed together (not as two separate docs)
- [ ] Cross-system dependency is documented in the output
- [ ] Output file is written to `docs/architecture/` (not `design/gdd/`)
- [ ] Verdict is COMPLETE or PARTIAL

---

### Case 4: Source File Not Found — Error

**Fixture:**
- `src/gameplay/inventory_system.gd` does not exist

**Input:** `$reverse-document src/gameplay/inventory_system.gd`

**Expected behavior:**
1. Skill attempts to read the specified file — not found
2. Skill outputs: "Source file not found: src/gameplay/inventory_system.gd"
3. Skill suggests checking the path or running `$map-systems` to identify
   the correct source file
4. No document is created

**Assertions:**
- [ ] Error message names the missing file with the full path
- [ ] Alternative suggestion (check path or `$map-systems`) is provided
- [ ] No write tool is called
- [ ] No verdict is issued (error state)

---

### Case 5: Director Gate Check — No gate; reverse-document is a utility

**Fixture:**
- Well-structured source file exists

**Input:** `$reverse-document src/gameplay/health_system.gd`

**Expected behavior:**
1. Skill generates and writes the design doc
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE or PARTIAL — no gate verdict involved

---

## Protocol Compliance

- [ ] Reads source file(s) before generating any content
- [ ] Produces all 8 required GDD sections when target is a gameplay system
- [ ] Annotates ambiguous values with AMBIGUOUS VALUE markers
- [ ] Produces cross-system overview (not individual GDDs) for multiple files
- [ ] Asks "May I write" before creating any output file
- [ ] Verdict is COMPLETE (clean inference) or PARTIAL (ambiguous fields)

---

## Coverage Notes

- Architecture overview format (for technical/infrastructure systems) differs
  from GDD format; the inferred output type is determined by the nature of the
  source file (gameplay logic → GDD; engine/infra code → architecture doc).
- The case where a source file is readable but contains only auto-generated
  boilerplate with no meaningful logic is not tested; skill would likely produce
  a near-empty skeleton with a PARTIAL verdict.
- C# and Blueprint source files follow the same inference pattern as GDScript;
  language-specific differences are handled in the skill body.
