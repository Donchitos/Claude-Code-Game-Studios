# Skill Test Spec: /smoke-check

## Skill Summary

`/smoke-check` is the gate between implementation and QA hand-off. Phase 1 runs
`project-coherence.sh`, verifies that **game test files** exist under the
engine's test root or `tests/smoke/` (not merely that `tests/` exists), and
reads the engine from `project.yaml` (falling back to `technical-preferences.md`),
then resolves the editor executable — the one `commands.test` names, else
`engine.path`, else the name on `PATH` — before it calls the runner unavailable.
Phase 2 runs `commands.test` (or the per-engine default) under a timeout and
reads the result by engine — gdUnit4 exit codes for Godot; on Unity, Play Mode
tests under `Assets/Tests/PlayMode/` get a second run with their own results
file. At `qa.level: minimal` with no game tests, the automated row is WAIVED
and Phase 2 runs a build check instead — `commands.smoke`, else
`commands.build`, when set. Phase 3 scans test coverage against the QA plan or
sprint stories; Phase 4 batch-verifies manual smoke checks with
`AskUserQuestion`, and Batch 1 first asks whether the build was launched this
session — "not launched" makes the manual checks NOT ASSESSED. The report is written
to `production/qa/smoke-[date].md` after explicit approval.

Verdicts, first matching rule wins: FAIL (a test failure, a suite that did not
complete — timeout, compile/parse/build error, no results file — or a Batch
1/Batch 2 check FAILED, or a failed build check), NOT ASSESSED (suite unconfirmed NOT RUN, a runner that
could not run or executed zero tests, unconfirmed `PlayMode: NOT RUN`, a check
that could not execute — including a build not launched this session — an
`UNKNOWN` coverage row, Batch 3 skipped — or no game tests at `qa.level`
`standard`/`full`; at `minimal` the automated row is WAIVED and the batches carry
the verdict), PASS WITH WARNINGS (MISSING test evidence, a runner warning such
as gdUnit4 101's leaked orphans, or a NOT RUN suite the developer confirmed),
PASS. NOT ASSESSED ranks above both pass values and below FAIL.
Whether a FAIL blocks hand-off depends on `qa.level` (advisory at `minimal`)
and `testing.strict.config` (unset → blocking).

No director gates apply. The skill does NOT invoke any director agents.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, PASS WITH WARNINGS, NOT ASSESSED, FAIL
- [ ] Contains "May I write" collaborative protocol language before writing the report
- [ ] Has a next-step handoff (re-run `/smoke-check` after a FAIL; QA hand-off to qa-tester on PASS)

---

## Director Gate Checks

None. `/smoke-check` is a pre-QA utility skill. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Automated tests pass, manual items confirmed, PASS

**Fixture:**
- `project.yaml` has `engine.name: Godot` and `commands.test` set to the gdUnit4 command
- `addons/gdUnit4/bin/GdUnitCmdTool.gd` exists; game tests exist under
  `tests/unit/` and `tests/integration/`
- `production/qa/qa-plan-sprint-005.md` exists
- The runner exits 0 with 12 tests, 12 passing
- The developer says the build was launched this session and selects no FAILED item in Batch 1, Batch 2 or Batch 3
- Every sprint story is COVERED or EXPECTED (no MISSING, no UNKNOWN)

**Input:** `/smoke-check`

**Expected behavior:**
1. Phase 1 reports environment: Godot, tests found, QA plan path
2. Runs `godot --headless --path . --import`, then `commands.test`
   (`godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`)
   under `timeout 900`; the report says `commands.test` was the command run
3. Exit 0 with tests found → automated tests PASS (12/12)
4. Coverage scan: all stories COVERED or EXPECTED
5. `AskUserQuestion` for Batch 1, Batch 2 and Batch 3 — nothing selected
6. Report names its checklist source (the QA plan's Smoke Test Scope)
7. Asks "May I write this smoke check report to `production/qa/smoke-[date].md`?"
8. Writes after approval; delivers "Smoke check passed cleanly. The build is ready for manual QA."

**Assertions:**
- [ ] Automated test runner is invoked via Bash, after the Godot import
- [ ] `AskUserQuestion` is used for manual smoke check batches
- [ ] "May I write" is asked before writing the report file
- [ ] Report is written to `production/qa/smoke-[date].md`
- [ ] Verdict is PASS

---

### Case 2: Failure Path — Automated test fails, blocking FAIL

**Fixture:**
- As Case 1, but `project.yaml` sets `modes.rigor: standard` (so `qa.level`
  resolves to `standard`) and leaves `testing.strict` unset
- The runner exits 100: 10 tests run, 8 passing, 2 failing —
  `test_health_clamp_at_zero`, `test_damage_calculation_negative`

**Input:** `/smoke-check`

**Expected behavior:**
1. Skill runs automated tests via Bash; exit 100 → FAIL
2. Records both failing test names
3. Proceeds through the manual smoke check batches
4. Report shows automated tests as FAIL with the failing test names listed
5. Asks to write the report; writes after approval
6. Gate is blocking (`qa.level: standard`, `testing.strict.config` unset → blocking)
7. Delivers: "The smoke check failed. Do not hand off to QA until these failures
   are resolved: …" listing each failure, then "Fix the failures and run
   `/smoke-check` again to re-gate before QA hand-off."

**Assertions:**
- [ ] Failing test names are listed in the report
- [ ] Verdict is FAIL
- [ ] The blocking message directs the developer to fix failures before QA hand-off
- [ ] `/smoke-check` re-run is suggested after fixing

---

### Case 3: Manual Confirmation — MISSING coverage, PASS WITH WARNINGS

**Fixture:**
- As Case 1: runner exits 0 with 8/8 passing
- One Logic story has no matching test file (MISSING coverage); no UNKNOWN rows
- The developer selects no FAILED item in Batch 1, Batch 2 or Batch 3

**Input:** `/smoke-check`

**Expected behavior:**
1. Automated tests PASS
2. Coverage scan finds 1 MISSING entry for a Logic story
3. `AskUserQuestion` is used for Batches 1–3 — nothing selected
4. Report shows automated tests PASS, manual checks PASS, and the MISSING entry
   under "Missing Test Evidence" with its expected test path
5. Verdict is PASS WITH WARNINGS; the message says the build is ready for manual
   QA and lists the MISSING entry as an advisory item to resolve before
   `/story-done` on the affected story
6. Asks to write the report; writes after approval

**Assertions:**
- [ ] `AskUserQuestion` is used for manual smoke check batches (not inline text prompts)
- [ ] MISSING test coverage entry appears in the report
- [ ] Verdict is PASS WITH WARNINGS (not PASS, not FAIL)
- [ ] Advisory note says the MISSING entry must be resolved before `/story-done`
- [ ] Report file is written to `production/qa/smoke-[date].md`

---

### Case 4: Scaffold Without Game Tests — NOT ASSESSED, then stop

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (so `qa.level` resolves to `standard`)
- Engine is Godot; `tests/unit/` and `tests/integration/` exist but hold only
  the `.gdignore_placeholder` files `/test-setup` creates
- No `tests/smoke/` directory

**Input:** `/smoke-check`

**Expected behavior:**
1. Phase 1 counts game test files, not directories — none are found
2. Skill delivers: "Smoke check: **NOT ASSESSED — no game tests found** under
   [the test root] or `tests/smoke/`. Run `/test-setup` to scaffold the testing
   infrastructure, or point me at where tests live."
3. Skill stops — no automated run, no manual batches, no report written

**Assertions:**
- [ ] The presence of `tests/` and its subdirectories is not treated as tests existing
- [ ] Verdict is NOT ASSESSED — the skill does not stop without a verdict
- [ ] `/test-setup` is suggested as the remediation step
- [ ] No further phases run and no report file is written

---

### Case 4b: No Game Tests at `qa.level: minimal` — WAIVED, the build carries the verdict

**Fixture:**
- No `modes.rigor` set (the default, `minimal`, so `qa.level` resolves to `minimal`)
- Engine is Godot; no game test files under `tests/unit/`, `tests/integration/` or `tests/smoke/`
- `commands.smoke` is `godot --headless --quit-after 5`; it exits 0 with no `SCRIPT ERROR` line
- The user says the build was launched this session and confirms every Batch 1, Batch 2 and Batch 3 check

**Input:** `/smoke-check`

**Expected behavior:**
1. Phase 1 finds no game test files and, at `qa.level: minimal`, records the automated row as `WAIVED — qa.level: minimal, no game tests`
2. Phase 2's test run and Phase 3 are skipped, each with a one-line note saying why
3. Phase 2's build check runs `commands.smoke` (after the Godot import) under a timeout: `Build check: PASS`
4. Phase 4 runs Batches 1–3; every check passes
5. Verdict: PASS — the report's Automated Tests status reads WAIVED

**Assertions:**
- [ ] The missing tests are WAIVED, not NOT ASSESSED, because `qa.level` is `minimal`
- [ ] The skipped test run and Phase 3 are announced, not silent
- [ ] The build check runs `commands.smoke` and its result is in the report
- [ ] Batch 1 and Batch 2 still run — PASS is never given without them
- [ ] Verdict is PASS and the report's Automated Tests row reads WAIVED
- [ ] A Batch 1 or Batch 2 check that could not be executed (no build) makes the verdict NOT ASSESSED, as at any level
- [ ] Variant — the user answers that the build was not launched this session: Batches 2 and 3 are not asked (the skip is said), the Batch 1 checks read `NOT RUN — build not launched this session`, and the verdict is NOT ASSESSED — never PASS from an empty failure list
- [ ] Variant — `commands.smoke` prints `SCRIPT ERROR` (Godot's boot check exits 0 on it): the build check is FAIL and so is the verdict

---

### Case 5: Director Gate Check — No gate; smoke-check is a QA pre-check utility

**Fixture:**
- Valid test setup, automated tests pass, manual smoke checks confirmed

**Input:** `/smoke-check`

**Expected behavior:**
1. Skill runs all phases and produces a verdict
2. No director agents are spawned at any point
3. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in output
4. No `/gate-check` is invoked

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is PASS, PASS WITH WARNINGS, NOT ASSESSED, or FAIL — no gate verdict involved

---

### Case 6: gdUnit4 Lookalikes — exit 0 over zero tests, and exit 101

**Fixture:**
- As Case 1, with every story COVERED or EXPECTED and nothing selected in
  Batch 1, Batch 2 or Batch 3
- Run A: the suites under `tests/unit/` declare no test functions; the runner
  prints `No test cases found` and exits 0
- Run B: the runner exits 101 — 12 tests, 12 passing, 2 orphan nodes leaked

**Input:** `/smoke-check`

**Expected behavior:**
1. Run A: exit 0 is not read as a pass — the automated tests are
   `NOT ASSESSED — no tests found`, and the verdict is NOT ASSESSED even though
   every manual check passed
2. Run B: 101 is PASS WITH WARNINGS, naming the orphan count; with no MISSING
   entry, the verdict is PASS WITH WARNINGS and the advisory list names the
   orphans

**Assertions:**
- [ ] Run A's verdict is NOT ASSESSED — not PASS
- [ ] Run B's Status line is PASS WITH WARNINGS with the orphan count
- [ ] Run B's verdict is PASS WITH WARNINGS — not PASS, and not FAIL

---

### Case 7: Timeout — the suite never completed, FAIL

**Fixture:**
- As Case 2 (`qa.level: standard`, `testing.strict` unset)
- The runner hangs; `timeout 900` ends it with exit 124 and no summary printed

**Input:** `/smoke-check`

**Expected behavior:**
1. Exit 124 is a gate FAILURE, never a pass — the run did not complete and
   nothing was verified
2. The Status line reads FAIL, naming the timeout
3. The verdict is FAIL and the gate is blocking

**Assertions:**
- [ ] A timeout is FAIL — not NOT ASSESSED and not NOT RUN
- [ ] The report names the timeout as the reason
- [ ] The blocking message is delivered

---

### Case 8: Batch 3 Skipped — NOT ASSESSED, not PASS

**Fixture:**
- As Case 1: runner exits 0 with 12/12 passing, no MISSING or UNKNOWN rows
- In Batch 3 the developer selects only "Performance not checked this session"

**Input:** `/smoke-check`

**Expected behavior:**
1. Batches 1 and 2 pass
2. The skipped Batch 3 item is recorded as not checked — it is not a FAIL
3. The verdict is NOT ASSESSED, and the Phase 6 message names the performance
   check that did not run

**Assertions:**
- [ ] Verdict is NOT ASSESSED — not PASS, not FAIL
- [ ] The unchecked performance item is named in the report

---

### Case 9: Unity — Play Mode is a second run

**Fixture:**
- `engine.name: Unity`; `com.unity.test-framework` is in `Packages/manifest.json`
- `commands.test` is the Edit Mode command `/setup-engine` writes
- `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` both hold test files
- Edit Mode exits 0 with 8/8 passing; Play Mode exits 2 with 1 of 3 failing

**Input:** `/smoke-check`

**Expected behavior:**
1. The Edit Mode run deletes `test-results/editmode.xml` first, then runs
2. Because `commands.test` does not pass `-testPlatform PlayMode` and
   `Assets/Tests/PlayMode/` holds tests, the skill runs Play Mode too, deleting
   and then writing `test-results/playmode.xml`
3. The report has one Status line per platform: `EditMode: PASS (8/8)` and
   `PlayMode: FAIL (1 failure)`
4. The verdict is FAIL

**Assertions:**
- [ ] Play Mode is run as a second run with its own results file
- [ ] Each platform is reported on its own line
- [ ] The Play Mode failure makes the verdict FAIL — the Edit Mode pass does not cover it

---

## Protocol Compliance

- [ ] Uses `AskUserQuestion` for all manual smoke check batches (Batch 1, Batch 2, Batch 3), and Batch 1 asks whether the build was launched this session; "not launched" yields NOT ASSESSED
- [ ] Resolves the editor executable from `commands.test`, then `engine.path`, then `PATH` before reporting the runner unavailable; a bare `godot` that does not resolve is never read as "no engine installed"
- [ ] Never edits `project.yaml`: a `commands.test` missing flags or using a relative path is adjusted for the run and reported to the user
- [ ] Runs automated tests via Bash before asking any manual questions
- [ ] Asks "May I write" before creating the report file — never writes without approval
- [ ] Verdict vocabulary is PASS / PASS WITH WARNINGS / NOT ASSESSED / FAIL — no other verdicts
- [ ] FAIL is triggered by automated test failures, a suite that did not complete (timeout, compile/parse/build error, no results file), or Batch 1/Batch 2 FAIL responses
- [ ] PASS WITH WARNINGS is triggered by MISSING test coverage, a runner warning on a passing suite (gdUnit4 101), or a confirmed NOT RUN — with no critical failures
- [ ] Unconfirmed NOT RUN (runner not available) yields NOT ASSESSED — never FAIL, never a pass verdict
- [ ] A run over zero tests, a runner that could not run, and an unconfirmed `PlayMode: NOT RUN` yield NOT ASSESSED
- [ ] Does not invoke director gates at any point

---

## Coverage Notes

- The `quick` argument (skips the Phase 3 coverage scan and Batch 3) is not
  separately fixture-tested.
- The `--platform` argument adds platform-specific `AskUserQuestion` batches and
  a per-platform verdict table; not separately tested here.
- The runner-not-available path (NOT RUN, then NOT ASSESSED until the developer
  confirms a result from their IDE or CI) is covered by the protocol compliance
  assertions above.
- At `qa.level: minimal` a FAIL is advisory and never blocks hand-off; Case 2
  pins `standard` to test the blocking path. Unity's `testcasecount="0"` and
  Unreal's `No automation tests matched` (→ NOT ASSESSED) follow Case 6 Run A;
  not separately fixture-tested.
- The Linux and macOS Unreal commands (picked by `uname -s`) are not
  fixture-tested. On macOS, Unreal tests are NOT ASSESSED until `commands.test`
  is set — asserted in the skill, not given a case here.
- A Play Mode run that cannot be made (`PlayMode: NOT RUN`, unconfirmed →
  NOT ASSESSED) is covered by protocol compliance, not by its own case.
