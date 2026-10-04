# Skill Test Spec: /skill-improve

## Skill Summary

`/skill-improve [skill-name]` runs one test → fix → retest → keep-or-revert
cycle on a single skill. It records a static baseline with
`/skill-test static [name]` (FAIL and WARN counts, and which of Checks 1–7
failed), then a category baseline with `/skill-test category [name]` when the
skill has a `category:` in `CCGS Skill Testing Framework/catalog.yaml`. If both
baselines are clean it stops with "No improvements needed." Otherwise it shows
a diagnosis, proposes before/after fixes, asks "May I write this improved
version to `.claude/skills/[name]/SKILL.md`?", writes, re-runs the same tests,
and shows a before → after comparison per dimension plus one combined line
(`Combined: 3 → 0 (improved)`).

Phase 6 compares the combined count (static FAILs + category FAILs + static
WARNs + category WARNs). Lower than baseline → "Score improved. Changes kept."
Same or worse → "Combined score did not improve." followed by "May I restore
`.claude/skills/[name]/SKILL.md` to the content it had before this run?" — the
restore runs only on a yes, and writes back the copy recorded in Phase 5 (never
`git checkout`, which would also drop earlier uncommitted edits). No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Phase 6 states both outcomes: "Score improved. Changes kept." and "Combined score did not improve."
- [ ] Contains "May I write" collaborative protocol language before applying fixes
- [ ] Has a next-step handoff (Phase 7: `/skill-test static all`, `/skill-improve [next-name]`, `/skill-test audit`)

---

## Director Gate Checks

None. `/skill-improve` is a meta-utility skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Check 4 FAIL and Check 5 WARN fixed, changes kept

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has `Write` in `allowed-tools` but no
  ask-before-write language (Check 4 FAIL) and no next-step section (Check 5 WARN)
- catalog gives `some-skill` `category: utility`; its category baseline is
  1 FAIL (U1, because static checks fail)
- The user approves the write; the re-test is clean in both dimensions

**Input:** `/skill-improve some-skill`

**Expected behavior:**
1. Static baseline displayed: "Static baseline: 1 failures, 1 warnings" with
   "Failing: Check 4 (no ask-before-write), Check 5 (no handoff)"
2. Category baseline displayed: "Category baseline: 1 failures, 0 warnings (utility rubric)"
3. Full diagnosis shown before any change is proposed
4. Before/after blocks proposed for only the failing parts; skill asks
   "May I write this improved version to `.claude/skills/some-skill/SKILL.md`?"
5. File written; both tests re-run; comparison shows
   `Static: Before 1 failures, 1 warnings → After 0 failures, 0 warnings`, the
   category line, and one combined line, `Combined: 3 → 0 (improved)`
6. "Score improved. Changes kept." with a per-dimension summary

**Assertions:**
- [ ] Static and category baselines are displayed before any change is proposed
- [ ] Both Check 4 and Check 5 are diagnosed and addressed in the proposed fix
- [ ] "May I write" is asked before the file is written
- [ ] The before → after comparison is shown for both dimensions, plus the single line `Combined: 3 → 0 (improved)`
- [ ] Outcome is "Score improved. Changes kept."

---

### Case 2: Fix Causes Regression — revert offered, runs only on yes

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has a static baseline of 0 FAILs and
  1 WARN (Check 5, no handoff)
- The applied fix adds a handoff but deletes the section holding the verdict
  keywords and the ask-before-write line: the static re-test shows 2 FAILs
  (Checks 3 and 4), and the category result is no better than its baseline —
  the combined count rises
- The user approves the write, then answers yes to the revert

**Input:** `/skill-improve some-skill`

**Expected behavior:**
1. Baseline recorded; fix proposed; "May I write …" approved; file written
2. The re-test comparison's combined line reads `Combined: [before] → [after] (worse)`,
   with the after count higher
3. Skill reports "Combined score did not improve." and shows what changed and
   why it may not have helped
4. Skill asks "May I restore `.claude/skills/some-skill/SKILL.md` to the content it had before this run?"
5. On yes: writes the Phase 5 copy back with Write — it does not run `git checkout`

**Assertions:**
- [ ] Re-test combined count is compared to the baseline before finalizing
- [ ] A higher combined count takes the "did not improve" branch
- [ ] The revert is asked for, not automatic
- [ ] The file is restored only after the user says yes, from the recorded copy — never via `git checkout`
- [ ] "Score improved. Changes kept." is NOT reported

---

### Case 3: Gate Skill — combined static + category baseline

**Fixture:**
- `.claude/skills/gate-check/SKILL.md` has 1 static FAIL and 2 category FAILs
  (G2 and G4 of the `### gate` section in `CCGS Skill Testing Framework/quality-rubric.md`)
- catalog gives `gate-check` `category: gate`; the user approves the write, and
  the re-test is clean in both dimensions

**Input:** `/skill-improve gate-check`

**Expected behavior:**
1. Static baseline and category baseline (`gate rubric`) both recorded
2. Diagnosis names the static check and the two G-metrics with the exact text gap for each
3. "May I write this improved version to `.claude/skills/gate-check/SKILL.md`?"
4. Both `/skill-test static gate-check` and `/skill-test category gate-check` re-run
5. The comparison ends `Combined: 3 → 0 (improved)`: "Score improved. Changes kept."

**Assertions:**
- [ ] Both static and category scores are captured in the baseline
- [ ] The combined count (FAILs + WARNs, both dimensions) is what Phase 6 compares
- [ ] All 3 failures are addressed in the proposed fix
- [ ] Both test types are re-run after the write
- [ ] Outcome is "Score improved. Changes kept." with the combined before/after

---

### Case 4: Skill Already Clean — No improvements needed

**Fixture:**
- `.claude/skills/brainstorm/SKILL.md` has 0 static FAILs and 0 WARNs
- catalog gives `brainstorm` `category: utility`; U1 and U2 both pass

**Input:** `/skill-improve brainstorm`

**Expected behavior:**
1. Static baseline 0/0 → proceeds to the category baseline (not an immediate stop)
2. Category baseline 0/0 (utility rubric)
3. Skill stops: "This skill already passes all static and category checks. No improvements needed."
4. No diagnosis, no proposed change, no "May I write", no file modified

**Assertions:**
- [ ] The category baseline is run before stopping (a clean static result alone does not stop)
- [ ] "No improvements needed" message is shown
- [ ] No changes are proposed
- [ ] No "May I write" is asked and no file is modified

---

### Case 5: Director Gate Check — No gate; skill-improve is a meta utility

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has at least 1 static failure; the user
  approves the write

**Input:** `/skill-improve some-skill`

**Expected behavior:**
1. Skill runs the test-fix-retest loop
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] The run ends with one of Phase 6's two outcome messages — no gate verdict

---

### Case 6: Equal Score — "no change" does not keep the fix as an improvement

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has a static baseline of 0 FAILs and
  1 WARN (Check 7, argument hint does not match the documented modes)
- catalog gives `some-skill` no `category:`, so category checks are skipped
- The applied fix corrects the hint but drops the closing next-step section:
  the re-test shows 0 FAILs and 1 WARN (Check 5)
- The user approves the write, then answers no to the restore

**Input:** `/skill-improve some-skill`

**Expected behavior:**
1. "Category: not yet assigned — skipping category checks." is shown
2. The comparison's combined line reads `Combined: 1 → 1 (no change)`
3. An equal count takes the "did not improve" branch: "Combined score did not
   improve.", then "May I restore `.claude/skills/some-skill/SKILL.md` to the
   content it had before this run?"
4. On no, the file is left as written and nothing is restored

**Assertions:**
- [ ] An equal combined count is treated as "did not improve", not as improved
- [ ] The combined line reads `Combined: 1 → 1 (no change)`
- [ ] "Score improved. Changes kept." is NOT reported
- [ ] The restore is asked for, and declining it leaves the written file in place

---

## Protocol Compliance

- [ ] Always establishes a baseline before proposing any changes
- [ ] Shows the full diagnosis, then before/after blocks, before asking to write
- [ ] Asks "May I write" before applying any fix
- [ ] Detects a non-improvement by comparing the re-test combined count to the baseline — an equal count is a non-improvement
- [ ] Shows one combined before → after line, e.g. `Combined: 3 → 0 (improved)`, beside the per-dimension lines
- [ ] Asks for user confirmation before reverting (not automatic)
- [ ] Ends with "Score improved. Changes kept." or "Combined score did not improve." — or stops earlier with "No improvements needed." / a declined write

---

## Coverage Notes

- One fix-retest cycle per invocation; a further pass needs a new `/skill-improve` run.
- Behavioral (spec-mode) results are not part of the loop — only static and
  category scores are.
- The Phase 1 stops — usage text when no argument is given, "Skill '[name]' not
  found." when no `SKILL.md` exists — and the user declining the write in
  Phase 4 are not separately fixture-tested.
