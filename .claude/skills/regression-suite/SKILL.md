---
name: regression-suite
description: "Map test coverage to GDD critical paths, find fixed bugs lacking regression tests, flag drift from new features."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.


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

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: `modes.workflow` as resolved above — supplied by `modes.rigor`
unless set explicitly — per `.claude/docs/workflow-modes.md`; in `audit` mode consider
`workflow_overrides.system_overrides.<system>` per system as each GDD is read. It
sets whether GDD critical paths are mapped or coverage is smoke-only — see Step 2c.

**`qa.level`**: controls whether the suite is generated at
all. At `minimal`, the regression suite is **not generated** (report that and
stop); at `standard`, generate it at Polish-stage entry; at `full`, at
Production-stage entry. Distinct axis from `workflow`.

## 1. Parse Arguments

**Early `qa.level` guard (resolved above):** if `qa.level: minimal`, the
regression suite is **not generated** — report "Regression suite not generated at
qa.level minimal" and **STOP here, before any scan**, in every mode
(`update` / `audit` / `report`). This is the `qa.level` axis; it is distinct from
the `workflow`-tier `minimal` branch in Step 2c (which only changes the
critical-path *source*, not *whether* the suite runs). Do not enter Step 2c's
`minimal` branch on account of `qa.level`.

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

For `audit` mode: read `design/gdd/systems-index.md` to get all systems, then
scope the scan by each system's workflow tier (resolved above):
- **`full`** — read the GDD and map critical paths from all sections.
- **`standard`** — same, from the required sections (Acceptance Criteria, Edge
  Cases, and Formulas where the system defines numeric rules).
  A system pinned higher via `system_overrides` is mapped at its higher tier.
- **`minimal`** — **skip the GDD critical-path scan**. Instead read the latest
  smoke-check report in `production/qa/smoke-*.md` and take the critical paths it
  exercises as the regression scope (Step 3 maps coverage against those, not GDD
  acceptance criteria). If no smoke report exists, report that and stop — there is
  no critical-path source at minimal without one.

(Tier affects `audit` mode only; `update` and `report` modes are tier-independent.)

For each in-scope MVP-tier system's GDD, extract:
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

For `audit` mode only. (At `minimal` the critical paths come from the smoke-check
report identified in Step 2c, not from GDD acceptance criteria — map coverage
against those smoke paths and skip the GDD-criterion loop below.)

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

> **Before computing coverage, check the denominator.** If the GDD
> glob returns **zero critical paths**, or the test globs return **zero test
> files**, do not emit a percentage — report
> `Coverage: NOT ASSESSED — [no GDDs found | no test files found]` and name which
> side was empty and the skill that produces it (`/map-systems` and
> `/design-system` for GDDs, `/test-setup` for the test scaffold).
>
> A percentage computed from an empty denominator is not a low score; it is not a
> number. `0%` reads as "measured and terrible" and `100%` as "measured and
> perfect" — both are claims about a comparison that never happened. This is the
> same defect `/scope-check` carries a Phase 4 guard against, in the same words:
> *"a percentage computed from no baseline items is not a small number; it is not
> a number."*
>
> **A hand-written list of skills required to carry `NOT ASSESSED` pins what was
> known when it was written**, so a skill added later inherits no obligation and
> nothing notices. Derive that set rather than enumerating it.

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

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never remove existing regression tests from the manifest** without
  explicit user approval — removing a test that was deliberately written is a
  regression risk itself
- **Gaps are advisory, not blocking** — surface them clearly but do not prevent
  other work from proceeding (except at release gate where regression suite is required)
- **Quarantine is not deletion** — tests with intermittent failures should be
  quarantined (noted in manifest) but not removed; they should be fixed by
  `/test-flakiness`
- **Ask before writing** — always confirm before creating or updating the manifest
