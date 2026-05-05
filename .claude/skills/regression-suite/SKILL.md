---
name: regression-suite
description: "Map test coverage to GDD critical paths, identify fixed bugs without regression tests, flag coverage drift from new features, and maintain tests/regression-suite.md. Run after implementing a bug fix or before a release gate."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

# Regression Suite

This skill ensures that every bug fix is backed by a test that would have
caught the original bug — and that the regression suite stays current as the
game evolves. It also detects when new features have been added without
corresponding regression coverage.

A regression suite is not a new test category — it is a **curated list of
tests already in `tests/`** that collectively cover the game's critical paths
and known failure points. This skill maintains that list.

**Output:** `tests/regression-suite.md`

**When to run:**
- After fixing a bug (confirm a regression test was written or identify gap)
- Before a release gate (`/gate-check polish` requires regression suite exists)
- As part of sprint close to detect coverage drift

---

## 1. Parse Arguments

**Modes:**
- `/regression-suite update` — scan new bug fixes this sprint and check
  for regression test presence; add new tests to the suite manifest
- `/regression-suite audit` — full audit of all GDD critical paths vs.
  existing test coverage; flag paths with no regression test
- `/regression-suite report` — read-only status report (no writes); suitable
  for sprint reviews
- No argument — if a sprint is clearly active (sprint plan exists with in-progress stories), run `update`. If ambiguous or no active sprint is detected, use `AskUserQuestion`:
  - Prompt: "No subcommand specified. Which mode do you want to run?"
  - Options:
    - `[A] update — scan new bug fixes this sprint and add missing regression tests`
    - `[B] audit — full audit of all GDD critical paths vs. existing test coverage`
    - `[C] report — read-only status report (no writes)`

---

## 2. Load Context

### Step 2a — Load existing regression suite

Read `tests/regression-suite.md` if it exists. Extract:
- Total registered regression tests
- Last updated date
- Any tests flagged as `STALE` or `QUARANTINED`

If it does not exist: note "No regression suite found — will create one."

### Step 2b — Load test inventory

Glob all test files:
```
tests/unit/**/*_test.*
tests/integration/**/*_test.*
tests/regression/**/*
```

For each file, note the system (from directory path) and file name.
Do not read test file contents unless needed for name-to-test mapping.

### Step 2c — Load GDD critical paths

For `audit` mode: read `design/gdd/systems-index.md` to get all systems.
For each MVP-tier system, read its GDD and extract:
- Acceptance Criteria (these define the critical paths)
- Formulas section (formulas must have regression tests)
- Edge Cases section (known edge cases should have regression tests)

For `update` mode: skip full GDD scan. Instead read the current sprint plan
and story files to find stories with Status: Complete this sprint.

### Step 2d — Load closed bugs

Glob `production/qa/bugs/*.md` and filter for bugs with a `Status: Closed`
or `Status: Fixed` field. Note:
- Which story or system the bug was in
- Whether a regression test was mentioned in the fix description

---

## 3. Map Coverage — Critical Paths

For `audit` mode only:

For each GDD acceptance criterion, determine whether a test exists:

1. Grep `tests/unit/[system]/` and `tests/integration/[system]/` for file names
   and function names related to the criterion's key noun/verb
2. Assign coverage:

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file exists that targets this criterion's logic |
| **PARTIAL** | A test exists but doesn't cover all cases (e.g. happy path only) |
| **MISSING** | No test found for this critical path |
| **EXEMPT** | Visual/Feel or UI criterion — not automatable by design |

3. Elevate MISSING items that correspond to formulas or state machines to
   **HIGH PRIORITY** gap — these are the most likely regression sources.

---

## 4. Map Coverage — Fixed Bugs

For each closed bug:

1. Extract the system slug from the bug's metadata
2. Grep `tests/unit/[system]/` and `tests/integration/[system]/` for a test
   that references the bug ID or the specific failure scenario
3. Assign:
   - **HAS REGRESSION TEST** — a test was found that would catch this bug
   - **MISSING REGRESSION TEST** — bug was fixed but no test guards against recurrence

For MISSING REGRESSION TEST items:
- Flag them as regression gaps
- Suggest the test file path: `tests/unit/[system]/[bug-slug]_regression_test.[ext]`
- Note: "Without this test, this bug can silently return in a future sprint."

---

## 5. Detect Coverage Drift

Coverage drift occurs when the game grows but the regression suite doesn't.

Check for drift indicators:
- Stories completed this sprint with no corresponding test files in `tests/`
- New systems added to `systems-index.md` since the last regression-suite update
- GDD sections added or revised since the regression suite was last updated
  (use Grep on GDD file modification hints if available, or ask the user)
- `tests/regression-suite.md` last-updated date vs. current date — if gap >
  2 sprints, flag as likely stale

---

## 6. Generate Report and Suite Manifest

### Report format (in conversation)

```
## Regression Suite Status

**Mode**: [update | audit | report]
**Existing registered tests**: [N]
**Test files scanned**: [N]

### Critical Path Coverage (audit mode only)
| System | Total ACs | Covered | Partial | Missing | Exempt |
|--------|-----------|---------|---------|---------|--------|
| [name] | [N] | [N] | [N] | [N] | [N] |

**Coverage rate (non-exempt)**: [N]%

### Bug Regression Coverage
| Bug ID | System | Severity | Has Regression Test? |
|--------|--------|----------|----------------------|
| BUG-NNN | [system] | S[N] | YES / NO ⚠ |

**Bugs without regression tests**: [N]

### Coverage Drift Indicators
[List new systems or stories with no test coverage, or "None detected."]

### Recommended New Regression Tests
| Priority | System | Suggested Test File | Covers |
|----------|--------|---------------------|--------|
| HIGH | [system] | `tests/unit/[system]/[slug]_regression_test.[ext]` | BUG-NNN / AC-[N] |
| MEDIUM | [system] | `tests/unit/[system]/[slug]_test.[ext]` | [criterion] |
```

### Suite manifest format (`tests/regression-suite.md`)

The manifest is a curated index — not the tests themselves, but a registry
of which tests should always pass before a release:

```markdown
# Regression Suite Manifest

> Last Updated: [date]
> Total registered tests: [N]
> Coverage: [N]% of GDD critical paths

## How to run

[Engine-specific command to run all regression tests]

## Registered Regression Tests

### [System Name]

| Test File | Test Function (if known) | Covers | Added |
|-----------|--------------------------|--------|-------|
| `tests/unit/[system]/[file]_test.[ext]` | `test_[scenario]` | AC-N / BUG-NNN | [date] |

## Known Gaps

Tests that should exist but don't yet:

| Priority | System | Suggested Path | Covers | Reason Not Yet Written |
|----------|--------|----------------|--------|------------------------|
| HIGH | [system] | `tests/unit/[system]/[path]` | BUG-NNN | Bug fixed without test |

## Quarantined Tests

Tests that are flaky or disabled (do not run in CI):

| Test File | Function | Reason | Quarantined Since |
|-----------|----------|--------|-------------------|
| (none) | | | |
```

---

## 7. Write Output

Ask: "May I write/update `tests/regression-suite.md` with the current
regression suite manifest?"

For `update` mode: append new entries; never remove existing entries
(use `Edit` with targeted insertions).
For `audit` mode: rewrite the full manifest with updated coverage data.
For `report` mode: do not write anything.

After writing (if approved):

- For each HIGH priority gap: "Consider creating the missing regression test
  before the next sprint. Run `/test-helpers` to scaffold the test file."
- If bug regression gaps > 0: "These bugs can silently return without regression
  tests. The next sprint should include a story to write the missing tests."
- If coverage drift detected: "Regression suite may be drifting. Consider
  running `/regression-suite audit` at the next sprint boundary."

Verdict: **COMPLETE** — regression suite updated. (If user declined write: Verdict: **BLOCKED**.)

---

## Collaborative Protocol

- **Never remove existing regression tests from the manifest** without
  explicit user approval — removing a test that was deliberately written is a
  regression risk itself
- **Gaps are advisory, not blocking** — surface them clearly but do not prevent
  other work from proceeding (except at release gate where regression suite is required)
- **Quarantine is not deletion** — tests with intermittent failures should be
  quarantined (noted in manifest) but not removed; they should be fixed by
  `/test-flakiness`
- **Ask before writing** — always confirm before creating or updating the manifest
