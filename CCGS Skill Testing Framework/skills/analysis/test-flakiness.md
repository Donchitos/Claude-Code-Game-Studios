# Skill Test Spec: /test-flakiness

## Skill Summary

`/test-flakiness` finds flaky tests from the results of multiple CI or local
test runs. It takes a log path, `scan` (all available result files — JUnit XML
from gdUnit4 in `reports/` or saved into `test-results/`, NUnit XML from Unity in
`test-results/`, Unreal automation logs in `Saved/Logs/`), or `registry` (remediation guidance for tests already in the
quarantine section of `tests/regression-suite.md`). With no result data it lists
three ways to get some and stops to ask. It builds a per-test history across
runs, classifies each test that both passed and failed by fail rate — >25% High
(quarantine immediately), 5–25% Moderate (fix directly, do not quarantine yet),
1–5% Low (monitor) — and names a likely cause and fix direction from its cause
table, using Grep on the test file. With fewer than 3 runs, every finding is
"suspected", not "confirmed", whatever its fail rate, and nothing is quarantined;
the summary table's Confidence column says which. It asks separately "May I update the quarantine
section of `tests/regression-suite.md`…?" and "May I write a full flakiness
report to `production/qa/flakiness-report-[date].md`?", appends quarantine
entries without removing existing ones, and never deletes test files. No
director gates are invoked. Verdicts: COMPLETE (report written) or BLOCKED
(user declined write).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, and the flakiness tiers High / Moderate / Low
- [ ] Contains "May I" write language for `tests/regression-suite.md` and `production/qa/flakiness-report-[date].md`
- [ ] Has a next-step handoff (Section 7: add skip annotations, schedule fixes before the release gate)

---

## Director Gate Checks

None. Flakiness detection is an advisory quality skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — High flakiness from JUnit history, quarantined on approval

**Fixture:**
- `project.yaml`: `engine.name: godot`; `modes.automation` unset (collaborative)
- `test-results/` holds 6 gdUnit4 JUnit XML files from 6 runs of the same commit
- `test_loot_drop_rolls_rare_item` fails in 2 of the 6 runs (33%); the other 40 tests pass in all 6
- `tests/unit/loot/loot_drop_test.gd` calls `randf()` with no seed
- `tests/regression-suite.md` has a Quarantined Tests table with 1 existing entry

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Skill finds the XML files in `test-results/` and parses `<testcase name=` and `<failure` / `<error` entries
2. Skill builds `test_id → [run1 … run6]` and finds one test with both outcomes
3. 33% is above 25% over 6 runs → **High** flakiness, Confidence confirmed → quarantine immediately
4. Grep of `loot_drop_test.gd` finds `randf` → likely cause Random seed; fix direction: pass an explicit seed
5. The quarantine recommendation names gdUnit4's GDScript skip parameters (`_do_skip := true`, `_skip_reason := "flaky: ..."`) as the way to skip it
6. Summary shows Runs analysed 6, Tests tracked 41, the flaky test with a 33% fail rate, and 40 tests with consistent results
7. Skill asks "May I update the quarantine section of `tests/regression-suite.md` with the flaky tests found?" and, separately, "May I write a full flakiness report to `production/qa/flakiness-report-[date].md`?"
8. On approval, the new entry is appended with `Edit`; the existing entry stays
9. Verdict: **COMPLETE** — flakiness report written

**Assertions:**
- [ ] JUnit XML results in `test-results/` are parsed per test across all 6 runs
- [ ] The flaky test is named with its fail rate, Confidence confirmed, and classified High → quarantine
- [ ] The skip mechanism named is gdUnit4's `_do_skip` / `_skip_reason` parameter pair, not an invented flag
- [ ] The likely cause is Random seed, with the explicit-seed fix direction
- [ ] The two writes are asked about separately, each before it happens
- [ ] The quarantine entry is appended and the existing entry is not removed
- [ ] Verdict is COMPLETE

---

### Case 2: Moderate Flakiness — Fix directly, do not quarantine

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `test-results/` holds 20 JUnit XML files from 20 runs of the same commit
- `test_physics_bounce_height_matches_spec` fails in 3 of 20 runs (15%)
- The test asserts `bounce_height == 0.5`

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Skill computes a 15% fail rate → **Moderate** flakiness
2. Grep of the test file finds a float equality comparison → likely cause Floating point
3. Recommendation: "This test is intermittently unreliable… Do not quarantine yet — fix the test directly", with the fix direction of an epsilon comparison (`is_equal_approx`)

**Assertions:**
- [ ] A 15% fail rate is classified Moderate
- [ ] The recommendation is to fix directly, not to quarantine
- [ ] The cause is Floating point and the fix names an epsilon comparison such as `is_equal_approx`

---

### Case 3: No Result Data — List options and stop

**Fixture:**
- No `test-results/` directory, no `.github/` directory, no `Saved/Logs/`
- No log path is given

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Skill finds no CI or local result data
2. Skill prints "No CI log data found…" with the three options: run the suite at least 3 times and collect logs; save a CI log to `test-results/`; run `/test-flakiness registry`
3. Skill stops and asks the user which option to pursue
4. No flakiness table is produced and nothing is written

**Assertions:**
- [ ] Output states no CI log data was found
- [ ] All three options are listed, including `/test-flakiness registry`
- [ ] Skill stops to ask instead of reporting a clean result
- [ ] No files are written

---

### Case 4: Too Few Runs — Suspected, not confirmed

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `test-results/` holds only 2 JUnit XML files, from 2 runs of the same commit
- `test_save_roundtrip_preserves_inventory` passes in one run and fails in the other

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Skill parses both files and finds the test with both outcomes — a 50% fail rate
2. With fewer than 3 runs, the finding is flagged "suspected", not "confirmed": the summary table's Confidence reads suspected, and the High tier's quarantine-immediately does not apply
3. The test is not quarantined; the recommendation is to collect more runs before acting
4. Skill asks whether more run data is available
5. The Data Limitations section notes that fewer than 5 runs were available, so confidence is low

**Assertions:**
- [ ] The finding is labelled suspected, not confirmed, in the summary table's Confidence column
- [ ] The 50% fail rate does not trigger quarantine — no skip is recommended, and any regression-suite note marks the test suspected
- [ ] Skill asks whether more run data is available
- [ ] Data Limitations states that fewer than 5 runs were analysed

---

### Case 5: Registry Mode in Full Review Mode — Guidance for known quarantined tests, no gates

**Fixture:**
- `project.yaml`: `modes.review_mode: full`
- `tests/regression-suite.md` Quarantined Tests table lists `test_ai_path_recalc_avoids_blocked_tile` (reason: timing) and `test_scene_load_spawns_player` (reason: scene not ready)

**Input:** `/test-flakiness registry`

**Expected behavior:**
1. Skill reads the quarantine section of `tests/regression-suite.md`
2. For each quarantined test it gives remediation guidance from the cause table: Timing / async → explicit await or synchronisation instead of time-based delays; Scene/prefab load race → await one frame after instantiation (`await get_tree().process_frame`)
3. No director gate is invoked regardless of review mode
4. Existing quarantine entries are not removed and no test file is deleted or edited by the skill

**Assertions:**
- [ ] The quarantine section of `tests/regression-suite.md` is the input
- [ ] Each quarantined test gets a fix direction matching its cause
- [ ] No director gate is invoked in any review mode
- [ ] No quarantine entry is removed and no test file is deleted

---

## Protocol Compliance

- [ ] Locates result data (`test-results/` XML, `Saved/Logs/`, or a given log path) before analysis; with none, lists the three options and stops to ask
- [ ] Classifies tests with both outcomes by fail rate: >25% High (quarantine), 5–25% Moderate (fix, do not quarantine), 1–5% Low (monitor)
- [ ] Names a likely cause and fix direction from the cause table, using Grep on the test file
- [ ] Counts a test as flaky only when it both passed and failed across runs with no code change between them
- [ ] With fewer than 3 runs, flags findings as suspected, not confirmed, in the summary's Confidence column, and quarantines nothing
- [ ] Asks separately before updating `tests/regression-suite.md` and before writing `production/qa/flakiness-report-[date].md`
- [ ] Appends quarantine entries, never removes existing ones, and never deletes test files
- [ ] No director gates are invoked
- [ ] Ends with COMPLETE on write or BLOCKED on decline; with no result data it lists the three options and stops to ask instead (Case 3), never reporting a clean result

---

## Coverage Notes

- The no-argument path (run `scan` when CI logs are accessible, else
  `registry`) is not tested here.
- Unity NUnit XML follows the same flow as Case 1, read from `<test-case`
  elements and their `result` attribute; not tested separately.
- Unreal differs and is not tested here: its results are plain-text
  `Result={Success}` / `Result={Fail}` lines in `Saved/Logs/` (each test prints
  `Test Completed. Result={<status>}`), and its skip
  mechanism is NOT SOURCEABLE, so a quarantined Unreal test is logged and the
  user is asked how their CI excludes it. The same applies to gdUnit4 C# tests.
- The Low tier (1–5%) needs 20 or more runs to reach and is not tested.
