---
name: smoke-check
description: "Critical-path smoke gate before QA hand-off — runs the automated suite. A failed check means the build is not QA-ready."
argument-hint: "[sprint | quick | --platform pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,qa.level,testing.strict`



# Smoke Check

This skill is the gate between "implementation done" and "ready for QA
hand-off". It runs the automated test suite, checks for test coverage gaps,
batch-verifies critical paths with the developer, and produces a PASS/FAIL
report.

The rule is simple: **a build that fails smoke check does not go to QA.**
Handing a broken build to QA wastes their time and demoralises the team.

**Output:** `production/qa/smoke-[date].md`

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`qa.level`**: at `minimal`, smoke-check is **optional** — if
run, a FAIL is advisory and never blocks hand-off; at `standard`, it is required
before a phase transition; at `full`, before every commit. This sits in front of
the Phase 6 `testing.strict.config` resolution (which only matters once a smoke run
gates). Distinct axis from `workflow`.

## Parse Arguments

Arguments can be combined: `/smoke-check sprint --platform console`

**Base mode** (first argument, default: `sprint`):
- `sprint` — full smoke check against the current sprint's stories
- `quick` — skip coverage scan (Phase 3) and Batch 3; use for rapid re-checks

**Platform flag** (`--platform`, default: none):
- `--platform pc` — add PC-specific checks (keyboard, mouse, windowed mode)
- `--platform console` — add console-specific checks (gamepad, TV safe zones,
  platform certification requirements)
- `--platform mobile` — add mobile-specific checks (touch, portrait/landscape,
  battery/thermal behaviour)
- `--platform all` — add all platform variants; output per-platform verdict table

If `--platform` is provided, Phase 4 adds platform-specific batches and
Phase 5 outputs a per-platform verdict table in addition to the overall verdict.

---

## Phase 1: Detect Test Setup

Before running anything, understand the environment:

0. **Config coherence**: run `bash .claude/scripts/project-coherence.sh`.

   It compares what `project.yaml` declares against the real project file, the
   installed engine binary, and the files `commands.*` name. This runs first
   because two of its checks are about *this skill's own inputs*: a
   `commands.test` naming a runner that does not exist, or a `commands.build`
   naming an export preset with no `export_presets.cfg`, will fail here and read
   as a broken build rather than as broken config.

   Report any `[DIFFERS]` lines in the report's Environment section. They do not
   by themselves decide the verdict -- but a smoke check run against a project
   whose declared engine is not the installed one is worth saying out loud.

1. **Test framework check**: verify that **game** test files exist — not merely
   that `tests/` does. Check `tests/unit/`, `tests/integration/` and
   `tests/smoke/` for actual test files.
   If none are found, **deliver a NOT ASSESSED verdict — do not merely stop.**
   "Smoke check: **NOT ASSESSED — no game tests found** under
   `tests/unit|integration|smoke`. Run `/test-setup` to scaffold the testing
   infrastructure, or point me at where tests live." Then stop.

   > A bare halt is the wrong shape here.
   > This is the state with the **least** information about build health, so it is
   > the last one that should exit without a verdict: the caller gets no
   > machine-readable outcome, and "the skill said nothing" is easy to read as
   > "nothing was wrong". Replacing a *wrong* verdict with *no* verdict is not an
   > improvement either — the honest result is the one that names what could not
   > be established.

   > **Do not gate on `tests/` existing.** `/test-setup` creates `tests/unit/`
   > and `tests/integration/` with placeholder files, so the directory tree is
   > present on any project that ran setup — whether or not a single game test
   > was ever written. Count actual test files instead. That is not
   > hypothetical: a fixture with no build and zero game tests passed this step
   > and went on to score **PASS WITH WARNINGS**.

2. **CI check**: check whether `.github/workflows/` contains a workflow file
   referencing tests. Note in the report whether CI is configured.

3. **Engine detection**: read `engine.name` from `project.yaml`; if that key
   is absent or empty (including when `project.yaml` has no `engine:` block),
   fall back to the `Engine:` value in `.claude/docs/technical-preferences.md`
   (a `[TO BE CONFIGURED]` value means not configured). Store this for test
   command selection in Phase 2.

4. **Smoke test list**: check whether `production/qa/smoke-tests.md` or
   `tests/smoke/` exists. If a smoke test list is found, load it for use in
   Phase 4. If neither exists, smoke tests will be drawn from the current QA
   plan (Phase 4 fallback).

5. **QA plan check**: glob `production/qa/qa-plan-*.md` and take the most
   recently modified file. If found, note the path — it will be used in
   Phase 3 and Phase 4. If not found, note: "No QA plan found. Run
   `/qa-plan sprint` before smoke-checking for best results."

Report findings before proceeding: "Environment: [engine]. Test directory:
[found / not found]. CI configured: [yes / no]. QA plan: [path / not found]."

---

## Phase 2: Run Automated Tests

Attempt to run the test suite via Bash. Select the command based on the engine
detected in Phase 1:

**Godot 4:**
```bash
godot --headless --script tests/gdunit4_runner.gd 2>&1
```
If the GDUnit4 runner script does not exist at that path, try:
```bash
godot --headless -s addons/gdunit4/GdUnitRunner.gd 2>&1
```
If neither path exists, note: "GDUnit4 runner not found — confirm the runner
path for your test framework."

**Unity:**
Unity **can** run tests headlessly via shell. Do not skip to reading artifacts.

First confirm the Unity Test Framework is installed. A project without it does
not fail cleanly — it **hangs** until something kills it, which is the
observation the old "Unity cannot test headlessly" advice was generalised from:
```bash
grep -q 'com.unity.test-framework' Packages/manifest.json && echo present || echo ABSENT
```
If ABSENT, report `NOT ASSESSED — Unity Test Framework not installed` and
give the one-line fix (add `com.unity.test-framework` to `Packages/manifest.json`).
**Do not fall through to reading stale artifacts** — an unknown-age XML
reported as a pass is worse than no gate.

If present, run the suite with an explicit timeout:
```bash
timeout 900 "<Unity.exe>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/results.xml
```
Parse `test-results/results.xml` for the `passed` and `failed` counts on the
`<test-run>` element. **A timeout (exit 124) is a gate FAILURE, never a pass** —
the run never completed and nothing was verified.

**Unreal Engine:**
```bash
# List most recent Unreal automation logs (bash) — on Windows PowerShell use the fallback below
ls -t Saved/Logs/ 2>/dev/null | grep -i "test\|automation" | head -5 \
  || powershell -Command "Get-ChildItem Saved/Logs/ -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'test|automation' } | Sort-Object LastWriteTime -Descending | Select-Object -First 5 -ExpandProperty Name"
```
If no matching log found: "UE automation tests must be run via the Session
Frontend or CI pipeline. Please confirm test status manually."

**Unknown engine / not configured:**
"Engine not configured in `project.yaml` or
`.claude/docs/technical-preferences.md`. Run `/setup-engine` to specify the
engine, then re-run `/smoke-check`."

**If the test runner is not available in this environment** (engine binary not
on PATH, runner script not found, etc.), report clearly:

"Automated tests could not be executed — engine binary not found on PATH.
Status will be recorded as NOT RUN. Confirm test results from your local IDE
or CI pipeline. Until you do, the verdict is NOT ASSESSED — not FAIL, and not
a pass either: nothing has been observed about this build yet."

Do not treat NOT RUN as an automatic FAIL. Record it, and let the developer's
manual confirmation in Phase 4 resolve it. Until that confirmation arrives the
verdict is **NOT ASSESSED** (see the verdict rules in Phase 5), which ranks
above both pass values and below FAIL. An unrun suite is not a healthy build; it
is an unknown one, and the two need different follow-ups.

Parse runner output and extract:
- Total tests run
- Passing count
- Failing count
- Names of any failing tests (up to 10; if more, note the count)
- Any crash or error output from the runner itself

---

## Phase 3: Check Test Coverage

Draw the story list from, in priority order:
1. The QA plan found in Phase 1 (its Test Summary table lists expected test
   file paths per story)
2. The current sprint plan from `production/sprints/` (most recently modified
   file)
3. If the `quick` argument was passed, skip this phase entirely and note:
   "Coverage scan skipped — run `/smoke-check sprint` for full coverage
   analysis."

For each story in scope:

1. Extract the system slug from the story's file path
   (e.g., `production/epics/combat/story-001.md` → `combat`)
2. Glob `tests/unit/[system]/` and `tests/integration/[system]/` for files
   whose name contains the story slug or a closely related term
3. Check the story file itself for a `Test file:` header field or a
   "Test Evidence" section

Assign a coverage status to each story:

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file was found matching this story's system and scope |
| **MANUAL** | Story type is Visual/Feel or UI; a test evidence document was found |
| **MISSING** | Logic or Integration story with no matching test file |
| **EXPECTED** | Config/Data story — no test file required; spot-check is sufficient |
| **UNKNOWN** | Story file missing or unreadable |

MISSING entries are advisory gaps. They do not cause a FAIL verdict but must
appear prominently in the report and must be resolved before `/story-done` can
fully close those stories.

---

## Phase 4: Run Manual Smoke Checks

Draw the smoke test checklist from, in priority order:
1. The QA plan's "Smoke Test Scope" section (if QA plan was found in Phase 1)
2. `production/qa/smoke-tests.md` (if it exists)
3. `tests/smoke/` directory contents (if it exists)
4. The standard fallback list below (used only when none of the above exist)

**Name the source you used in the report**, on its own line — *"Checklist source:
`production/qa/smoke-tests.md`"*, or *"Checklist source: standard fallback list —
no QA plan scope, no `production/qa/smoke-tests.md`, no `tests/smoke/`."* The
fallback is a real fallback, so nothing is silently skipped here; what was
missing is that a report drawn from the generic list and one drawn from this
project's own smoke definitions were indistinguishable. `/gate-check` now
validates a smoke report's claims against the repo, and it cannot weigh them
without knowing what the checklist was drawn from.

Tailor batches 2 and 3 to the actual systems identified from the sprint or QA
plan. Replace bracketed placeholders with real mechanic names from the current
sprint's stories.

Use `AskUserQuestion` to batch-verify. Keep to at most 3 calls.

**Batch 1 — Core stability (always run):**
```
question: "Core stability — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Game does not launch or crashes before reaching the main menu"
  - "New game / session fails to start"
  - "Main menu does not respond to inputs"
  - "Crash or hang observed during basic navigation"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

**Batch 2 — Sprint changes and regression (always run):**
```
question: "Sprint changes and regression — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "[Primary mechanic this sprint] — FAILED"
  - "[Second notable change this sprint, if any] — FAILED"
  - "Regression in a previous sprint's feature — FAILED"
  - "Other unexpected breakage observed — FAILED"
```

For any selected item, ask the user to briefly describe what broke before generating the report.

**Batch 3 — Data integrity and performance (run unless `quick` argument):**
```
question: "Data integrity and performance — select any items that FAILED or were skipped (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Save / load — FAILED (data loss or corruption observed)"
  - "Save / load — N/A (save system not yet implemented)"
  - "Frame rate drops or hitches observed — FAILED"
  - "Performance not checked this session"
```

For any FAILED item selected, ask the user to describe what broke before generating the report.

Record each response verbatim for the Phase 5 report.

**Platform Batches** *(run only if `--platform` argument was provided)*:

**PC platform** (`--platform pc` or `--platform all`):
```
question: "PC Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Keyboard controls — FAILED (describe issue after)"
  - "Mouse input or cursor visibility — FAILED (describe issue after)"
  - "Windowed / fullscreen mode — FAILED (describe issue after)"
  - "Resolution change — FAILED (describe issue after)"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

**Console platform** (`--platform console` or `--platform all`):
```
question: "Console Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Gamepad input — FAILED (describe issue after)"
  - "UI outside TV safe zone / text clipped — FAILED (describe what is clipped after)"
  - "Keyboard/mouse fallback shown to gamepad user — FAILED (describe after)"
  - "Cold start (no prior save) — FAILED (describe issue after)"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

**Mobile platform** (`--platform mobile` or `--platform all`):
```
question: "Mobile Platform — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Touch controls — FAILED (describe issue after)"
  - "Orientation change (portrait ↔ landscape) — FAILED (describe what breaks after)"
  - "Background / foreground transition (home button) — FAILED (describe issue after)"
  - "Performance / thermal throttling on target device — FAILED (describe after)"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

---

## Phase 5: Generate Report

Assemble the full smoke check report:

````markdown
## Smoke Check Report
**Date**: [date]
**Sprint**: [sprint name / number, or "Not identified"]
**Engine**: [engine]
**QA Plan**: [path, or "Not found — run /qa-plan first"]
**Argument**: [sprint | quick | blank]

---

### Automated Tests

**Status**: [PASS ([N] tests, [N] passing) | FAIL ([N] failures) |
NOT RUN ([reason])]

[If FAIL, list failing tests:]
- `[test name]` — [brief failure description from runner output]

[If NOT RUN:]
"Manual confirmation required: did tests pass in your local IDE or CI? This
will determine whether the automated test row contributes to a FAIL verdict."

---

### Test Coverage

| Story | Type | Test File | Coverage Status |
|-------|------|-----------|----------------|
| [title] | Logic | `tests/unit/[system]/[slug]_test.[ext]` | COVERED |
| [title] | Visual/Feel | `production/qa/evidence/[slug]-screenshots.md` | MANUAL |
| [title] | Logic | — | MISSING ⚠ |
| [title] | Config/Data | — | EXPECTED |

**Summary**: [N] covered, [N] manual, [N] missing, [N] expected.

---

### Manual Smoke Checks

- [x] Game launches without crash — PASS
- [x] New game starts — PASS
- [x] [Core mechanic] — PASS
- [ ] [Other check] — FAIL: [user's description]
- [x] Save / load — PASS
- [-] Performance — not checked this session

---

### Missing Test Evidence

Stories that must have test evidence before they can be marked COMPLETE via
`/story-done`:

- **[story title]** (`[path]`) — Logic story has no test file.
  Expected location: `tests/unit/[system]/[story-slug]_test.[ext]`

[If none:] "All Logic and Integration stories have test coverage."

---

### Platform-Specific Results *(only if `--platform` was provided)*

| Platform | Checks Run | Passed | Failed | Platform Verdict |
|----------|-----------|--------|--------|-----------------|
| PC | [N] | [N] | [N] | PASS / FAIL |
| Console | [N] | [N] | [N] | PASS / FAIL |
| Mobile | [N] | [N] | [N] | PASS / FAIL |

**Platform notes**: [any platform-specific observations not captured in pass/fail]

Any platform with one or more FAIL checks contributes to the overall FAIL verdict.

---

### Verdict: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[Verdict rules — first matching rule wins:]

**FAIL** if ANY of:
- Automated test suite ran and reported one or more test failures
- Any Batch 1 (core stability) check returned FAIL
- Any Batch 2 (primary sprint mechanic or regression check) returned FAIL

**NOT ASSESSED** if ANY of:
- The automated suite is **unconfirmed NOT RUN** — nobody has reported a result
- A Batch 1 or Batch 2 check could not be executed (no build, engine not
  configured, platform unavailable) as opposed to executing and failing
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suite passes matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 3 was offered and skipped** ("Performance not checked this session").
  It is not a FAIL, not an execution failure, and not "PASS or N/A", so without
  this line it matches no rule at all and renders as `[-]` beside a PASS

**PASS WITH WARNINGS** if ALL of:
- Automated tests PASS, or NOT RUN **and the developer has confirmed the result
  from their local IDE or CI**
- All Batch 1 and Batch 2 smoke checks PASS
- One or more Logic/Integration stories have MISSING test evidence

**PASS** if ALL of:
- Automated tests PASS
- All smoke checks in all batches PASS or N/A
- No MISSING test evidence entries
````

**`NOT ASSESSED` — the build nobody could check.** Rank: it **outranks PASS and
PASS WITH WARNINGS** and **ranks below FAIL**. A suite that never ran has not
shown the build is healthy; a suite that ran and failed is the more actionable
finding and must not be demoted behind one that did not run.

This is a change in where unconfirmed `NOT RUN` lands, and it is deliberate. The
rule below — **never treat NOT RUN as an automatic FAIL** — is unchanged and
still correct: NOT ASSESSED is not a FAIL, and it ranks below one. What changes
is that an unrun suite no longer resolves to a *pass* verdict while waiting for a
confirmation that may never come. Confirmed NOT RUN (the developer reports the
result from their own IDE or CI) still lands at PASS WITH WARNINGS, because
somebody did look.

---

## Phase 6: Write and Gate

Present the full report in conversation, then ask:

"May I write this smoke check report to `production/qa/smoke-[date].md`?"

Write only after approval.

**First apply `qa.level` (resolved earlier).** At `qa.level: minimal`, a FAIL is
**advisory** regardless of `testing.strict.config` — skip the resolution below and
deliver the advisory-FAIL outcome (smoke-check is optional at minimal and never
blocks hand-off). Otherwise:

**Resolve the gate enforcement level.** A FAIL verdict either *blocks* QA
hand-off or is *flagged while hand-off proceeds*, governed by the
`testing.strict` block **resolved in the resolved-config block at the top of this skill** (which merges
`project.local.yaml` over `project.yaml` — read that block, not the file, or a
developer's local override is silently ignored):

1. Take `testing.strict.config` from that resolved block. If its value is `true`
   (case-insensitive) → blocking; if `false` → advisory; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies.
3. Else default to **blocking** — an unset `testing.strict.config` keeps
   smoke-check's FAIL gate blocking (behavior unchanged from before this setting
   existed). Smoke check is a build-health gate, so its unset default is strict
   even though the `config` test type defaults to advisory elsewhere. The
   reciprocal carve-out is recorded in `.claude/skills/story-done/SKILL.md` and
   `.claude/docs/coding-standards.md`, which own the per-story evidence table.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

After writing, deliver the gate verdict:

**If verdict is FAIL and the gate is blocking:**

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing automated test or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again to re-gate before QA hand-off."

**If verdict is FAIL and the gate is advisory** (`testing.strict.config: false`):

"The smoke check failed, but `testing.strict.config` is set to advisory — QA
hand-off is not blocked. Resolve these before release:

[List each failing automated test or smoke check with a one-line description]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification. Re-run `/smoke-check` once the failures
are fixed."

**If verdict is NOT ASSESSED:**

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
engine binary absent, no build, platform unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'run `/setup-engine`', 'produce a build'.]

Re-run `/smoke-check` once any of those is resolved."

This outcome is **not governed by `testing.strict.config`**. That setting decides
whether a *failure* blocks hand-off; it has nothing to say about a check that
never produced a result, and reading an unrun check as advisory-therefore-fine is
the exact substitution this verdict exists to prevent. Say what could not be
checked and let the user decide — do not resolve it to either pass or FAIL on
their behalf.

**If verdict is PASS WITH WARNINGS:**

"Smoke check passed with warnings. The build is ready for manual QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

**If verdict is PASS:**

"Smoke check passed cleanly. The build is ready for manual QA.

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never treat NOT RUN as automatic FAIL** — record it as NOT RUN and let
  the developer confirm status manually. Unconfirmed NOT RUN yields **NOT
  ASSESSED**, not FAIL — and not a pass verdict either, which is what it used to
  yield.
- **Never auto-fix failures** — report them and state what must be resolved.
  Do not attempt to edit source code or test files.
- **PASS WITH WARNINGS does not block QA hand-off** — it records advisory
  gaps for `/story-done` to follow up on.
- **`quick` argument** skips Phase 3 (coverage scan) and Phase 4 Batch 3.
  Use it for rapid re-checks after fixing a specific failure.
- Use `AskUserQuestion` for all manual smoke check verification.
- **Never write the report without asking** — Phase 6 requires explicit
  approval before any file is created.
