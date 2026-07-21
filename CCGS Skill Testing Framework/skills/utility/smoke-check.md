# Skill Test Spec: $smoke-check

## Skill Summary

`$smoke-check` is the gate between implementation and QA hand-off. It detects the
test environment, runs the automated test suite (via Bash), scans test coverage
against sprint stories, and uses `AskUserQuestion` to batch-verify manual smoke
checks with the developer. It writes a report to `production/qa/smoke-[date].md`
after explicit user approval.

Verdicts: PASS (tests pass, all smoke checks pass, no missing test evidence),
PASS WITH WARNINGS (tests pass or NOT RUN, all critical checks pass, but advisory
gaps exist such as missing test coverage), or FAIL (any automated test failure or
any Batch 1/Batch 2 smoke check returns FAIL).

No director gates apply. The skill does NOT invoke any director agents.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, PASS WITH WARNINGS, FAIL
- [ ] Contains "May I write" collaborative protocol language before writing the report
- [ ] Has a next-step handoff (e.g., `$bug-report` on FAIL, QA hand-off guidance on PASS)

---

## Director Gate Checks

None. `$smoke-check` is a pre-QA utility skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Automated tests pass, manual items confirmed, PASS

**Fixture:**
- `tests/` directory exists with a GDUnit4 runner script
- Engine detected as Godot from `technical-preferences.md`
- `production/qa/qa-plan-sprint-005.md` exists
- Automated test runner reports 12 tests, 12 passing, 0 failing
- Developer confirms all Batch 1 and Batch 2 smoke checks as PASS
- All sprint stories have matching test files (no MISSING coverage)

**Input:** `$smoke-check`

**Expected behavior:**
1. Skill detects test directory and engine, notes QA plan found
2. Runs `godot --headless --script tests/gdunit4_runner.gd` via Bash
3. Parses output: 12/12 passing
4. Scans test coverage — all stories COVERED or EXPECTED
5. Uses `AskUserQuestion` for Batch 1 (core stability) and Batch 2 (sprint mechanics)
6. Developer selects PASS for all items
7. Report assembled: automated tests PASS, all smoke checks PASS, no MISSING coverage
8. Asks "May I write this smoke check report to `production/qa/smoke-[date].md`?"
9. Writes report after approval
10. Delivers verdict: PASS

**Assertions:**
- [ ] Automated test runner is invoked via Bash
- [ ] `AskUserQuestion` is used for manual smoke check batches
- [ ] "May I write" is asked before writing the report file
- [ ] Report is written to `production/qa/smoke-[date].md`
- [ ] Verdict is PASS

---

### Case 2: Failure Path — Automated test fails, FAIL verdict

**Fixture:**
- `tests/` directory exists, engine is Godot
- Automated test runner reports 10 tests run: 8 passing, 2 failing
  - Failing tests: `test_health_clamp_at_zero`, `test_damage_calculation_negative`
- QA plan exists

**Input:** `$smoke-check`

**Expected behavior:**
1. Skill runs automated tests via Bash
2. Parses output — 2 failures detected
3. Records failing test names
4. Proceeds through manual smoke check batches
5. Report shows automated tests as FAIL with failing test names listed
6. Asks to write report; writes after approval
7. Delivers FAIL verdict with message: "The smoke check failed. Do not hand off to
   QA until these failures are resolved." Lists failing tests and suggests fixing
   then re-running `$smoke-check`

**Assertions:**
- [ ] Failing test names are listed in the report
- [ ] Verdict is FAIL
- [ ] Post-verdict message directs developer to fix failures before QA hand-off
- [ ] `$smoke-check` re-run is suggested after fixing

---

### Case 3: Manual Confirmation — AskUserQuestion used, PASS WITH WARNINGS

**Fixture:**
- `tests/` directory exists, engine is Godot
- Automated test runner reports all tests passing (8/8)
- One Logic story has no matching test file (MISSING coverage)
- Developer confirms all Batch 1 and Batch 2 smoke checks as PASS

**Input:** `$smoke-check`

**Expected behavior:**
1. Automated tests PASS
2. Coverage scan finds 1 MISSING entry for a Logic story
3. `AskUserQuestion` is used for Batch 1 and Batch 2 — developer confirms all PASS
4. Report shows: automated tests PASS, manual checks all PASS, 1 MISSING coverage entry
5. Verdict is PASS WITH WARNINGS — build ready for QA, but MISSING entry must be
   resolved before `$story-done` closes the affected story
6. Asks to write report; writes after approval

**Assertions:**
- [ ] `AskUserQuestion` is used for manual smoke check batches (not inline text prompts)
- [ ] MISSING test coverage entry appears in the report
- [ ] Verdict is PASS WITH WARNINGS (not PASS, not FAIL)
- [ ] Advisory note explains MISSING entry must be resolved before `$story-done`
- [ ] Report file is written to `production/qa/smoke-[date].md`

---

### Case 4: No Test Directory — Skill stops with guidance

**Fixture:**
- `tests/` directory does not exist
- Engine is configured as Godot

**Input:** `$smoke-check`

**Expected behavior:**
1. Phase 1 checks for `tests/` directory — not found
2. Skill outputs: "No test directory found at `tests/`. Run `$test-setup` to
   scaffold the testing infrastructure, or create the directory manually if
   tests live elsewhere."
3. Skill stops — no automated tests run, no manual smoke checks, no report written

**Assertions:**
- [ ] Error message references the missing `tests/` directory
- [ ] `$test-setup` is suggested as the remediation step
- [ ] Skill stops after this message (no further phases run)
- [ ] No report file is written

---

### Case 5: Director Gate Check — No gate; smoke-check is a QA pre-check utility

**Fixture:**
- Valid test setup, automated tests pass, manual smoke checks confirmed

**Input:** `$smoke-check`

**Expected behavior:**
1. Skill runs all phases and produces a PASS or PASS WITH WARNINGS verdict
2. No director agents are spawned at any point
3. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in output
4. No `$gate-check` is invoked

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is PASS, PASS WITH WARNINGS, or FAIL — no gate verdict involved

---

## Protocol Compliance

- [ ] Uses `AskUserQuestion` for all manual smoke check batches (Batch 1, Batch 2, Batch 3)
- [ ] Runs automated tests via Bash before asking any manual questions
- [ ] Asks "May I write" before creating the report file — never writes without approval
- [ ] Verdict vocabulary is strictly PASS / PASS WITH WARNINGS / FAIL — no other verdicts
- [ ] FAIL is triggered by automated test failures or Batch 1/Batch 2 FAIL responses
- [ ] PASS WITH WARNINGS is triggered when MISSING test coverage exists but no critical failures
- [ ] NOT RUN (engine binary unavailable) is recorded as a warning, not a FAIL
- [ ] Does not invoke director gates at any point

---

## Coverage Notes

- The `quick` argument (skips Phase 3 coverage scan and Batch 3) is not separately
  fixture-tested; it follows the same pattern as Case 1 with a coverage-skip note in output.
- The `--platform` argument adds platform-specific AskUserQuestion batches and a
  per-platform verdict table; not separately tested here.
- The case where the engine binary is not on PATH (NOT RUN) follows the PASS WITH
  WARNINGS pattern and is covered by the protocol compliance assertions above.
