# Skill Test Spec: $balance-check

## Skill Summary

`$balance-check` reads balance data files (JSON or YAML in `assets/data/`) and
checks each value against the design formulas defined in GDDs under `design/gdd/`.
It produces a findings table with columns: Value → Formula → Deviation → Severity.
No director gates are invoked (read-only analysis). The skill may optionally write
a balance report but asks "May I write" before doing so. Verdicts: BALANCED,
CONCERNS, or OUT OF BALANCE.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: BALANCED, CONCERNS, OUT OF BALANCE
- [ ] Contains "May I write" language (optional report write)
- [ ] Has a next-step handoff (what to do after findings are reviewed)

---

## Director Gate Checks

None. Balance check is a read-only analysis skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — All balance values within formula tolerances

**Fixture:**
- `assets/data/combat-balance.json` exists with 6 stat values
- `design/gdd/combat-system.md` contains formulas for all 6 stats with ±10% tolerance
- All 6 values fall within tolerance

**Input:** `$balance-check`

**Expected behavior:**
1. Skill reads all balance data files in `assets/data/`
2. Skill reads GDD formulas from `design/gdd/`
3. Skill computes deviation for each value against its formula
4. All deviations are within ±10% tolerance
5. Skill outputs findings table with all rows showing PASS
6. Verdict is BALANCED

**Assertions:**
- [ ] Findings table is shown for all checked values
- [ ] Each row shows: stat name, formula target, actual value, deviation percentage
- [ ] All rows show PASS or equivalent when within tolerance
- [ ] Verdict is BALANCED
- [ ] No files are written without user approval

---

### Case 2: Out of Balance — Player damage 40% above formula target

**Fixture:**
- `assets/data/combat-balance.json` has `player_damage_base: 140`
- `design/gdd/combat-system.md` formula specifies `player_damage_base = 100` (±10%)
- All other stats are within tolerance

**Input:** `$balance-check`

**Expected behavior:**
1. Skill reads combat-balance.json and computes deviation for `player_damage_base`
2. Deviation is +40% — far outside ±10% tolerance
3. Skill flags this row as severity HIGH in the findings table
4. Verdict is OUT OF BALANCE
5. Skill surfaces the HIGH severity item prominently before the table

**Assertions:**
- [ ] `player_damage_base` row shows deviation of +40%
- [ ] Severity is HIGH for deviations exceeding tolerance by more than 2×
- [ ] Verdict is OUT OF BALANCE when any stat has HIGH severity deviation
- [ ] The HIGH severity item is called out explicitly, not buried in table rows

---

### Case 3: No GDD Formulas — Cannot validate, guidance given

**Fixture:**
- `assets/data/economy-balance.yaml` exists with 10 stat values
- No GDD in `design/gdd/` contains formula definitions for economy stats

**Input:** `$balance-check`

**Expected behavior:**
1. Skill reads balance data files
2. Skill searches GDDs for formula definitions — finds none for economy stats
3. Skill outputs: "Cannot validate economy stats — no formulas defined. Run $design-system first."
4. No findings table is generated for the economy stats
5. Verdict is CONCERNS (data exists but cannot be validated)

**Assertions:**
- [ ] Skill does not fabricate formula targets when none exist in GDDs
- [ ] Output explicitly names the missing formula source
- [ ] Output recommends running `$design-system` to define formulas
- [ ] Verdict is CONCERNS (not BALANCED, since validation was impossible)

---

### Case 4: Orphan Reference — Balance file references an undefined stat

**Fixture:**
- `assets/data/combat-balance.json` contains a stat `legacy_armor_mult: 1.5`
- `design/gdd/combat-system.md` has no formula for `legacy_armor_mult`
- All other stats have formula definitions and pass validation

**Input:** `$balance-check`

**Expected behavior:**
1. Skill reads all stats from combat-balance.json
2. Skill cannot find a formula for `legacy_armor_mult` in any GDD
3. Skill flags `legacy_armor_mult` as ORPHAN REFERENCE in the findings table
4. Other stats are evaluated normally; those within tolerance show PASS
5. Verdict is CONCERNS (orphan reference prevents full validation)

**Assertions:**
- [ ] `legacy_armor_mult` appears in findings table with status ORPHAN REFERENCE
- [ ] Orphan references are distinguished from formula deviations in the table
- [ ] Verdict is CONCERNS when any orphan references are found
- [ ] Skill does not skip orphan stats silently

---

### Case 5: Gate Compliance — Read-only; no gate; optional report requires approval

**Fixture:**
- Balance data and GDD formulas exist; 1 stat has CONCERNS-level deviation (15% above target)
- `review-mode.txt` contains `full`

**Input:** `$balance-check`

**Expected behavior:**
1. Skill reads data and GDDs; generates findings table
2. Verdict is CONCERNS (one stat slightly out of range)
3. No director gate is invoked
4. Skill presents findings table to user
5. Skill offers to write an optional balance report
6. If user says yes: skill asks "May I write to `production/qa/balance-report-[date].md`?"
7. If user says no: skill ends without writing

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Findings table is presented without writing anything automatically
- [ ] Optional report write is offered but not forced
- [ ] "May I write" prompt appears only if user opts in to the report

---

## Protocol Compliance

- [ ] Reads both balance data files and GDD formulas before analysis
- [ ] Findings table shows Value, Formula, Deviation, and Severity columns
- [ ] Does not write any files without explicit user approval
- [ ] No director gates are invoked
- [ ] Verdict is one of: BALANCED, CONCERNS, OUT OF BALANCE

---

## Coverage Notes

- The case where `assets/data/` is entirely empty is not tested; behavior
  follows the CONCERNS pattern with a message that no data files were found.
- Tolerance thresholds (±10%, ±20%) are implementation details of the skill;
  the tests verify that deviations are detected and classified, not the
  exact threshold values.
