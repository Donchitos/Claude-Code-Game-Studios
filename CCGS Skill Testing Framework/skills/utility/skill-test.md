# Skill Test Spec: /skill-test

## Skill Summary

`/skill-test` validates skill files for structural correctness, behavioral
compliance, and category-rubric scoring. It operates in three modes:

- **static**: Checks a single skill file for structural requirements
  (frontmatter fields, phase headings, verdict keywords, "May I write" language,
  next-step handoff) without needing a fixture. Produces a per-check PASS/FAIL
  table.
- **spec**: Reads a test spec file from `tests/skills/` and evaluates the skill
  against each test case assertion, producing a case-by-case verdict.
- **audit**: Produces a coverage table of all skills in `.claude/skills/` and
  all agents in `.claude/agents/`, showing which have spec files and which do not.

An additional **category** mode reads the quality rubric for a skill category
(e.g., gate skills) and scores the skill against rubric criteria. The verdict
system differs by mode.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdicts: COMPLIANT, NON-COMPLIANT, WARNINGS (static mode); PASS, FAIL, PARTIAL (spec mode); COMPLETE (audit mode)
- [ ] Does NOT contain "May I write" language (skill is read-only in all modes)
- [ ] Has a next-step handoff (e.g., `/skill-improve` to fix issues found)

---

## Director Gate Checks

None. `/skill-test` is a meta-utility skill. No director gates apply.

---

## Test Cases

### Case 1: Static Mode — Well-formed skill, all 7 checks pass, COMPLIANT

**Fixture:**
- `.claude/skills/brainstorm/SKILL.md` exists and is well-formed:
  - Has all required frontmatter fields
  - Has ≥2 phase headings
  - Has verdict keywords
  - Has "May I write" language
  - Has a next-step handoff
  - Documents director gates
  - Documents gate mode behavior (lean/solo skips)

**Input:** `/skill-test static brainstorm`

**Expected behavior:**
1. Skill reads `.claude/skills/brainstorm/SKILL.md`
2. Skill runs all 7 structural checks
3. All 7 checks pass
4. Skill outputs a PASS/FAIL table with all 7 checks marked PASS
5. Verdict is COMPLIANT

**Assertions:**
- [ ] Exactly 7 structural checks are reported
- [ ] All 7 are marked PASS
- [ ] Verdict is COMPLIANT
- [ ] No files are written

---

### Case 2: Static Mode — Skill Missing "May I Write" Despite Write Tool in allowed-tools

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has `Write` in `allowed-tools` frontmatter
- The skill body has no "May I write" or "May I update" language

**Input:** `/skill-test static some-skill`

**Expected behavior:**
1. Skill reads `some-skill/SKILL.md`
2. Check 4 (collaborative write protocol) fails: `Write` in allowed-tools but no
   "May I write" language found
3. All other checks may pass
4. Verdict is NON-COMPLIANT with Check 4 as the failing assertion
5. Output lists Check 4 as FAIL with explanation

**Assertions:**
- [ ] Check 4 is marked FAIL
- [ ] Explanation identifies the specific mismatch (Write tool without "May I write" language)
- [ ] Verdict is NON-COMPLIANT
- [ ] Other passing checks are shown (not only the failure)

---

### Case 3: Spec Mode — gate-check Skill Evaluated Against Spec

**Fixture:**
- `tests/skills/gate-check.md` exists with 5 test cases
- `.claude/skills/gate-check/SKILL.md` exists

**Input:** `/skill-test spec gate-check`

**Expected behavior:**
1. Skill reads both the skill file and the spec file
2. Skill evaluates each of the 5 test case assertions against the skill's behavior
3. For each case: PASS if skill behavior matches spec assertions, FAIL if not
4. Skill produces a case-by-case result table
5. Overall verdict: PASS (all 5), PARTIAL (some), or FAIL (majority failing)

**Assertions:**
- [ ] All 5 test cases from the spec are evaluated
- [ ] Each case has an individual PASS/FAIL result
- [ ] Overall verdict is PASS, PARTIAL, or FAIL based on case results
- [ ] No files are written

---

### Case 4: Audit Mode — Coverage Table of All Skills and Agents

**Fixture:**
- `.claude/skills/` contains 72+ skill directories
- `.claude/agents/` contains 53+ agent files
- `tests/skills/` contains spec files for a subset of skills

**Input:** `/skill-test audit`

**Expected behavior:**
1. Skill enumerates all skills in `.claude/skills/` and all agents in `.claude/agents/`
2. Skill checks `tests/skills/` for a corresponding spec file for each
3. Skill produces a coverage table:
   - Each skill/agent listed
   - "Has Spec" column: YES or NO
   - Summary: "X of Y skills have specs; A of B agents have specs"
4. Verdict is COMPLETE

**Assertions:**
- [ ] All skill directories are enumerated (not just a sample)
- [ ] "Has Spec" column is accurate for each entry
- [ ] Summary counts are correct
- [ ] Verdict is COMPLETE

---

### Case 5: Category Mode — Gate Skill Evaluated Against Quality Rubric

**Fixture:**
- `tests/skills/quality-rubric.md` exists with a "Gate Skills" section defining
  criteria G1-G5 (e.g., G1: has mode guard, G2: has verdict table, etc.)
- `.claude/skills/gate-check/SKILL.md` is a gate skill

**Input:** `/skill-test category gate-check`

**Expected behavior:**
1. Skill reads `quality-rubric.md` and identifies the Gate Skills section
2. Skill evaluates `gate-check/SKILL.md` against criteria G1-G5
3. Each criterion is scored: PASS, PARTIAL, or FAIL
4. Overall category score is computed (e.g., 4/5 criteria pass)
5. Verdict is COMPLIANT (all pass), WARNINGS (some partial), or NON-COMPLIANT (failures)

**Assertions:**
- [ ] All gate criteria (G1-G5) from quality-rubric.md are evaluated
- [ ] Each criterion has an individual score
- [ ] Overall verdict reflects the score distribution
- [ ] No files are written

---

## Protocol Compliance

- [ ] Static mode checks exactly 7 structural assertions
- [ ] Spec mode evaluates each test case from the spec file individually
- [ ] Audit mode covers all skills AND agents (not just one category)
- [ ] Category mode reads quality-rubric.md to get criteria (not hardcoded)
- [ ] Does not write any files in any mode
- [ ] Suggests `/skill-improve` as the next step when issues are found

---

## Coverage Notes

- The skill-test skill is self-referential (it can test itself). The static
  mode case for skill-test's own SKILL.md is not separately fixture-tested to
  avoid infinite recursion in test design.
- The specific 7 structural checks are defined in the skill body; only Check 4
  (May I write) is individually tested here because it has the most nuanced logic.
- Audit mode counts are approximate — the exact number of skills and agents will
  change as the system grows; assertions use "all" rather than fixed counts.
