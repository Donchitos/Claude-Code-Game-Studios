---
name: test-flakiness
description: "Find flaky tests from CI logs — aggregates pass rates, spots intermittent failures, recommends quarantine. After multiple runs."
argument-hint: "[ci-log-path | scan | registry]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Bash(bash "*/.claude/skills/test-flakiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Flakiness Detection

A flaky test is one that sometimes passes and sometimes fails without any code
change. Flaky tests are worse than no tests in some ways — they train the team
to ignore red CI runs, masking genuine failures. This skill identifies them,
explains likely causes, and recommends whether to quarantine or fix each one.

**Output:** Updated `tests/regression-suite.md` quarantine section + optional
`production/qa/flakiness-report-[date].md`

**When to run:**
- Polish phase (tests have had many runs; statistical signal is reliable)
- When developers start dismissing CI failures as "probably flaky"
- After `/regression-suite` identifies quarantined tests that need diagnosis

---

## 1. Parse Arguments

**Modes:**
- `/test-flakiness [ci-log-path]` — analyse a specific CI run log file
- `/test-flakiness scan` — scan all available CI logs in `.github/` or
  standard log output directories
- `/test-flakiness registry` — read existing regression-suite.md quarantine
  section and provide remediation guidance for already-known flaky tests
- No argument — auto-detect: run `scan` if CI logs are accessible, else
  `registry`

---

## 2. Locate CI Log Data

### Option A — GitHub Actions (preferred)

Check for test result artifacts:
```bash
ls -t .github/ 2>/dev/null
ls -t test-results/ 2>/dev/null
```

For Godot projects: GdUnit4 outputs XML results compatible with JUnit format,
under `reports/` (its default report folder, `res://reports/`). Check `reports/`,
and any `test-results/` you saved runs into, for `.xml` files.

For Unity projects: game-ci test runner outputs NUnit XML to `test-results/`
by default.

For Unreal projects: automation logs go to `Saved/Logs/`. Grep for
`Result={Success}` and `Result={Fail}` — each test prints
`Test Completed. Result={<status>}`
(`docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

### Option B — Local log files

If a path argument is provided, read that file directly.

### Option C — No log data available

If no logs found:
> "No CI log data found. To detect flaky tests, this skill needs test result
> history from multiple runs. Options:
> 1. Run the test suite at least 3 times and collect the output logs
> 2. Check CI pipeline output and save a log to `test-results/`
> 3. Run `/test-flakiness registry` to review tests already flagged as flaky
>    in `tests/regression-suite.md`"

Stop and ask the user which option to pursue.

---

## 3. Parse Test Results

For each CI log or result file found, parse:

**JUnit XML format** (GdUnit4):
- Grep for `<testcase name=` to get test names
- Grep for `<failure` or `<error` to identify failures
- Parse `classname` and `name` attributes for full test identifiers

**NUnit XML format** (Unity — the file whose `<test-run>` element `/smoke-check`
reads):
- Each test is a `<test-case` element; its `fullname` attribute is the identifier
- Its `result` attribute is `Passed`, `Failed`, `Inconclusive` or `Skipped`
  (`docs/engine-reference/unity/current-best-practices.md`, "Command Line");
  only `Passed` and `Failed` enter the history

**Plain text logs**:
- Grep for pass/fail patterns:
  - Godot: `PASSED` / `FAILED` adjacent to test names
  - Unreal: `Result={Success}` / `Result={Fail}`
  - Unity: `Test passed` / `Test failed`

Build a table: `test_id → [run1_result, run2_result, run3_result, ...]`

---

## 4. Identify Flaky Tests

A test is **flaky** if it appears in the result history with both PASS and
FAIL outcomes across runs with no code changes between them.

Flakiness thresholds:
- **High flakiness**: Fails in >25% of runs — quarantine immediately
- **Moderate flakiness**: Fails in 5–25% of runs — investigate and fix soon
- **Low/suspected flakiness**: Fails in 1–5% of runs — monitor; may be
  genuinely rare failure

**With fewer than 3 runs, every finding is *suspected*, whatever its fail rate.**
One failure in two runs reads as 50%, but it is one data point: do not
quarantine it, label it suspected, and ask whether more run data is available.
The tiers above, and quarantine, apply from 3 runs up.

For each flaky test, classify the likely cause:

### Cause classification

| Cause | Symptoms | Fix direction |
|-------|----------|---------------|
| **Timing / async** | Fails after awaiting signals or timers; pass rate correlates with system load | Add explicit await/synchronisation; avoid time-based delays |
| **Order dependency** | Fails when run after specific other tests; passes in isolation | Add proper setup/teardown; ensure test isolation |
| **Random seed** | Fails intermittently with no pattern; involves RNG | Pass explicit seed; don't use `randf()` in tests |
| **Resource leak** | Fails more often later in a test run | Fix cleanup in teardown; check orphan nodes (Godot) or object disposal (Unity) |
| **External state** | Fails when a file, scene, or global exists from a prior test | Isolate test from file system; use in-memory mocks |
| **Floating point** | Fails on comparisons like `== 0.5` | Use epsilon comparison (`is_equal_approx`, `Assert.AreApproximately`) |
| **Scene/prefab load race** | Fails when scenes are not yet ready | Await one frame after instantiation; use `await get_tree().process_frame` |

Use Grep to check the test file for timing calls, randf, global state access,
or equality comparisons on floats to narrow down the cause.

---

## 5. Recommend Action

For each flaky test:

**Quarantine (High flakiness):**
> "Quarantine this test immediately. Skip it with the engine's own mechanism,
> log it in the `tests/regression-suite.md` quarantine section, and fix the root
> cause before removing quarantine."

Skip mechanisms, by engine — name only the one for the project's engine:
- **Godot (gdUnit4), GDScript**: a skip parameter on the test function —
  `func test_x(_do_skip := true, _skip_reason := "flaky: [cause]")`. gdUnit4 reads
  the argument names `do_skip` and `skip_reason` (a leading `_` is allowed) in
  `addons/gdUnit4/src/core/GdUnitTestSuiteScanner.gd`, as of gdUnit4 6.1.3;
  confirm them there for the installed version.
- **Godot (gdUnit4), C#**: **NOT SOURCEABLE** — gdUnit4's C# test attributes are
  not in the `addons/gdUnit4/` source, and `docs/engine-reference/godot/` does not
  cover them. Log it in the quarantine section and ask the user how their C#
  tests are skipped; do not invent an attribute.
- **Unity (NUnit)**: `[Ignore("flaky: [cause]")]` — NUnit 3 requires the reason
- **Unreal**: **NOT SOURCEABLE** — `docs/engine-reference/unreal/` documents no way
  to skip an automation test. Log it in the quarantine section and ask the user
  how their CI excludes a test; do not invent a flag.

**Investigate and fix soon (Moderate):**
> "This test is intermittently unreliable. Root cause appears to be [cause].
> Suggested fix: [specific fix based on cause classification]. Do not quarantine
> yet — fix the test directly."

**Monitor (Low/suspected):**
> "This test shows suspected flakiness. Collect more run data before
> quarantining. Note it as 'suspected' in the regression suite."

---

## 6. Generate Reports

### In-conversation summary

```
## Flakiness Detection Results

**Runs analysed**: [N]
**Tests tracked**: [N]

### Flaky Tests Found

| Test | System | Fail Rate | Confidence | Likely Cause | Recommendation |
|------|--------|-----------|------------|--------------|----------------|
| [test_name] | [system] | [N]% | confirmed | Timing | Quarantine + fix async |
| [test_name] | [system] | [N]% | confirmed | Float comparison | Fix: use epsilon compare |
| [test_name] | [system] | [N]% | suspected (fewer than 3 runs) | Order dependency | Collect more runs before acting |

### Clean Tests (no flakiness detected)

[N] tests ran across [N] runs with consistent results — no flakiness detected.

### Data Limitations

[Note if fewer than 5 runs were available — fewer runs = less statistical confidence]
```

---

## 7. Update Regression Suite + Optional Report File

Ask: "May I update the quarantine section of `tests/regression-suite.md`
with the flaky tests found?"

If yes: use `Edit` to append entries to the Quarantined Tests table.
Never remove existing quarantine entries — only add new ones.

Ask (separately): "May I write a full flakiness report to
`production/qa/flakiness-report-[date].md`?"

The full report includes per-test analysis with cause details and
engine-specific fix snippets.

After writing:

- For each quarantined test: "Add the engine-specific skip annotation to
  disable this test in CI. Re-enable after the root cause is fixed."
- For fix-eligible tests: "The fix for [test] is straightforward —
  change the equality comparison on line [N] to use `is_equal_approx`."
- Summary: "Once all quarantine annotations are applied, CI should run green.
  Schedule fix work for the [N] quarantined tests before the release gate."

---

## Collaborative Protocol

- **Never delete test files** — quarantine means annotate + list, not remove
- **Statistical confidence matters** — with < 3 runs, flag findings as
  "suspected" not "confirmed"; ask if more run data is available
- **Fix is always the goal** — quarantine is temporary; surface the fix
  direction even when recommending quarantine
- **Ask before writing** — both the regression-suite update and the report
  file require explicit approval. On write: Verdict: **COMPLETE** — flakiness report written. On decline: Verdict: **BLOCKED** — user declined write.
- **Flakiness in CI is a team problem** — surface the list and recommended
  actions clearly; do not just silently quarantine without the team knowing
