---
name: smoke-check
description: "Critical-path smoke gate before QA hand-off — runs the automated suite. A failed check means the build is not QA-ready."
argument-hint: "[sprint | quick | --platform pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict`



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
run, a FAIL is advisory and never blocks hand-off, and a project with no game
tests is checked by its build, launch and critical paths alone (Phase 1 step 1); at `standard`, it is required
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
   that `tests/` does. Check the engine's **test root** (from step 3; the table
   is in `.claude/docs/directory-structure.md` — Godot `tests/unit/` and
   `tests/integration/`, Unity `Assets/Tests/`, Unreal
   `Source/*/Private/Tests/`) and `tests/smoke/` for actual test files. A
   **test file** is one the engine's test runner executes — a `*_test.gd` suite,
   a C# test class, an Unreal automation test source. Markdown checklists do not
   count: `/test-setup` always writes `tests/smoke/critical-paths.md`, and
   counting it would hide exactly the zero-test state this step exists to catch.
   If none are found **at `qa.level: minimal`**, tests are waived at this level:
   record the automated row as `WAIVED — qa.level: minimal, no game tests`, skip
   the test run in Phase 2 and all of Phase 3 (say so in one line each), run
   Phase 2's **build check**, and go on to Phase 4 — the build check and the
   launch and critical-path checks are the smoke check at this level, so
   a project with no tests can still reach PASS, but never without a run: a
   Batch 1 answer that the build was not launched this session leaves the
   verdict NOT ASSESSED.
   If none are found **at `standard` or `full`**, **deliver a NOT ASSESSED verdict — do not merely stop.**
   "Smoke check: **NOT ASSESSED — no game tests found** under
   [the test root] or `tests/smoke/`. Run `/test-setup` to scaffold the testing
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
   > was ever written. Count actual test files instead; gated on the directory,
   > a project with no build and zero game tests passes this step.

2. **CI check**: check whether `.github/workflows/` contains a workflow file
   referencing tests. Note in the report whether CI is configured.

3. **Engine detection**: read `engine.name` from `project.yaml`; if that key
   is absent or empty (including when `project.yaml` has no `engine:` block),
   fall back to the `Engine:` value in `.claude/docs/technical-preferences.md`
   (a `[TO BE CONFIGURED]` value means not configured). Store this for test
   command selection in Phase 2.

   Then find the **editor executable** — none of the three engines installs
   onto `PATH` by default on Windows or macOS, so a bare `godot` that does not
   resolve says nothing about whether the engine is installed. Take the first
   that resolves (the file exists, or `command -v` finds it): the executable
   `commands.test` names (its quoted path or first word), else the editor
   `engine.path` records, else the engine's name on `PATH` (`godot`). Use it
   wherever Phase 2 writes `godot` or `"<Unity editor>"`, quoting a path with a
   space; on Unreal, `<UE root>` is `engine.path`. If none resolves, the test
   runner is not available (Phase 2) — on Godot,
   `NOT ASSESSED — Godot executable not found (commands.test, engine.path, PATH)`.

4. **Smoke test list**: check whether `production/qa/smoke-tests.md` or
   `tests/smoke/` exists. If a smoke test list is found, load it for use in
   Phase 4. If neither exists, smoke tests will be drawn from the current QA
   plan (Phase 4 fallback).

5. **QA plan check**: glob `production/qa/qa-plan-*.md` and take the most
   recently modified file. If found, note the path — it will be used in
   Phase 3 and Phase 4. If not found, note: "No QA plan found. Run
   `/qa-plan sprint` before smoke-checking for best results." (At `workflow: minimal`,
   which has no sprints, a QA plan is optional — say so rather than recommend one.)

Report findings before proceeding: "Environment: [engine]. Editor: [the
resolved executable / not found]. Test directory:
[found / not found]. CI configured: [yes / no]. QA plan: [path / not found]."

---

## Phase 2: Run Automated Tests

**Run `commands.test` from `project.yaml` when it is set** — it is the
project's own test command, the one `/setup-engine` wrote and CI runs. Use the
per-engine default below only when `commands.test` is absent, and say in the
report which of the two you ran. Wrap it in a timeout (`timeout 900 …`): **a
timeout (exit 124) is a gate FAILURE, never a pass** — the run never completed
and nothing was verified. macOS has no `timeout`: use `gtimeout 900 …` from
Homebrew's `coreutils` (same exit 124), or, with nothing installed,
`perl -e 'alarm shift; exec @ARGV' 900 …`, which exits 142 when time runs out —
a FAILURE the same way. Then read the result for the engine. On every engine
one outcome looks like success and is not; each is named below.

**Godot 4** — first check that `addons/gdUnit4/bin/GdUnitCmdTool.gd` exists —
the folder has a **capital U**. If it does not, report
`NOT ASSESSED — gdUnit4 not installed at addons/gdUnit4/` instead of running
anything. Then import, whether you run `commands.test` or the
default. A fresh clone has no `.godot/` class cache, and without it gdUnit4's
runner does not load; a cache that predates a new `class_name` fails valid
code with 105. The import takes seconds when nothing changed (`godot` below is
the executable Phase 1 step 3 resolved):
```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode 2>&1
```
gdUnit4's exit code gives the verdict (6.1.3):
- **0** — every test passed: PASS. **But exit 0 over zero tests is not a pass:**
  gdUnit4 aborts and still exits 0, so if the output says `No test cases found`,
  the verdict is `NOT ASSESSED — no tests found`.
- **101** — every test passed but a test leaked nodes (orphans): PASS WITH
  WARNINGS, naming the orphan count from the output. Not a failure.
- **100** — a test failed: FAIL. **105** — a test script does not parse: FAIL.
- **103** — gdUnit4 refused to run headless (`--ignoreHeadlessMode` missing);
  **104** — Godot older than 4.3: `NOT ASSESSED`, with that reason.
- **1** — Godot's own error: `GdUnitCmdTool.gd` did not load (`Failed to load
  script`), so no test ran. Usually the import above was skipped; after it,
  exit 1 is a FAIL.

Every run opens with two `ERROR:` lines about the remote port
(`127.0.0.1:0`) — that is the `--remote-debug` flag working, not a failure.
Never drop the flag: without it a script error opens Godot's interactive
debugger and the run hangs at a `debug>` prompt until the timeout.

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

If present, the default is (the **editor** executable — `Unity` on `PATH` may be
Unity's separate CLI). Delete the old results file first, whether you run
`commands.test` or this default:
```bash
rm -f test-results/editmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
```
Exit 0 when every test passes, 2 on a failure. **Exit 1 or 3 is a FAIL**: 1
means the project did not compile (the editor log has the `error CS…` lines),
3 that the run itself failed; 4 (an unknown `-testPlatform`) or any other
non-zero exit is a FAIL too. A compile error writes no results file — which
is why the old one is deleted first: left in place, the last run's pass is read
as this run's. After any exit, no results file is a FAIL. Parse the `<test-run>`
element of the results file for `testcasecount`, `passed` and `failed`. **`testcasecount="0"`
is NOT ASSESSED, never a pass**: tests outside `Assets/` are never compiled, and
Unity then reports `result="Passed"` with exit 0 over zero tests.

**Play Mode is a second run.** `-testPlatform EditMode` — this default, and
`commands.test` as `/setup-engine` writes it — never runs the integration tests
`/test-setup` scaffolds under `Assets/Tests/PlayMode/`. When that folder holds a
test file and the command you ran did not already pass `-testPlatform PlayMode`,
run Play Mode the same way, into its own results file, and read it by the same
rules:
```bash
rm -f test-results/playmode.xml
timeout 900 "<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
Report each platform on its own line — `EditMode: PASS (12/12)`,
`PlayMode: FAIL (1 failure)`. A Play Mode run that could not be made is
reported by name, `PlayMode: NOT RUN — [reason]`: the Edit Mode result does not
cover those tests, so it cannot make the automated-test row a PASS.

**Unreal Engine** — build the editor target first, whether you then run
`commands.test` or the default. `Binaries/` is not committed, and without a
built game module the editor stops with "The game module could not be found",
exit 1, before running any test. The build is incremental — seconds when
nothing changed; a failed build is a FAIL.

**Pick the commands for this machine** with `uname -s`: `Linux` → Linux,
`Darwin` → macOS, anything else (`MINGW*`, `MSYS*`, `CYGWIN*`) → Windows. The
Windows forms below were run on UE 5.7 (not re-checked on 5.8); the Linux and macOS forms come from
Epic's documentation — `docs/engine-reference/unreal/current-best-practices.md`,
"Command Line", has them with their sources. On Windows use
`UnrealBuildTool.exe`, not `Build.bat`: run from bash, `Build.bat` fails on an
engine path with spaces.
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
# macOS (timeout: see the macOS note above)
gtimeout 1800 "<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" 2>&1
```
Then the default. Keep `-stdout -FullStdOutLogOutput`; when `commands.test`
lacks them, add them to the command for this run only: without them the editor
prints nothing, and the lines below are only in `Saved/Logs/<Project>.log`.
Give the project as an **absolute** path — when `commands.test` passes a
relative one, run it with the absolute path instead: UE 5.7 (not re-checked on 5.8)
does not find a relative `<Project>.uproject` and exits 1 (`Project file not
found`). `$(pwd -W 2>/dev/null || pwd)` gives the `C:/…` form in Git Bash and
the plain path elsewhere; `$PWD` alone fails when `MSYS_NO_PATHCONV` is set.
Either way, say in the report what you changed and tell the user to fix
`commands.test` in `project.yaml` — never edit `project.yaml` without asking.
`<Project>.` in the filter is the root the tests are named under: the project
name, or the distinct root `/setup-engine` chose when the project's name is
also an engine area — read one test's name string under
`Source/*/Private/Tests/` if unsure.
```bash
# Windows
timeout 1800 "<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
# Linux
timeout 1800 "<UE root>/Engine/Binaries/Linux/UnrealEditor" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1
```
**macOS has no sourced test command.** Epic documents only the
`UnrealEditor.app` bundle, not a command-line editor inside it. Run a
`commands.test` the user has set and confirmed; with none, report
`NOT ASSESSED — Unreal test command on macOS not sourced; set commands.test to the editor command you use`
instead of guessing a path.
Read the output, not the exit code: a failing test and a run that matched nothing both exit 255.
- `Result={Fail}` on any line → FAIL.
- `No automation tests matched` → `NOT ASSESSED — no tests found` (tests
  outside `Source/<Module>/` are never built), not FAIL.
- Exit 0 with `Result={Success}` lines → PASS.
- Any other non-zero exit (`Project file not found`, `The game module … could
  not be found`) → FAIL: no test ran. The exception: the editor never started (exit 126 or 127, `command not found`) — that is the runner not being
  available, below, and `NOT ASSESSED`.

**Unknown engine / not configured:**
"Engine not configured in `project.yaml` or
`.claude/docs/technical-preferences.md`. Run `/setup-engine` to specify the
engine, then re-run `/smoke-check`."

**If the test runner is not available in this environment** (no editor
executable resolved in Phase 1 step 3, runner script not found, etc.), report
clearly:

"Automated tests could not be executed — engine executable not found (checked
`commands.test`, `engine.path` and `PATH`; set `engine.path`, or put the
editor's full path in `commands.test`). Status will be recorded as NOT RUN.
Confirm test results from your local IDE
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

**Build check — the WAIVED path only** (`qa.level: minimal`, no game tests;
Phase 1 step 1). With no suite to run, run the project's own boot check:
`commands.smoke` when set, else `commands.build` when set, with the executable
Phase 1 step 3 resolved, under the same timeout rules (`timeout 900`, or
`timeout 1800` for `commands.build`; a timeout is a FAIL). On Godot, run the
import line above first. Read the result as `/setup-engine` documents it:
Godot `smoke` exits 0 even on a parse error, so a `SCRIPT ERROR` line in its
output is a FAIL, and so is `Can't run project: no main scene defined` — the
game cannot launch; Unity `smoke` exits 1 on a compile error; any other
non-zero exit is a FAIL. Record `Build check: PASS — [command] exit 0`,
`FAIL — [reason]`, or `NOT RUN — [commands.smoke and commands.build unset |
executable not found]`. A build check that did not run is named in the report
and leaves the launch in Batch 1 to carry the verdict; it never passes on its
own.

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

Draw the smoke test checklist from, in priority order (and name the one you used in the report):
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

**Batch 1 — Core stability (always run):** one call, two questions — an empty
failure list means nothing unless somebody launched the build.
```
question: "Did you launch the current build this session?"
multiSelect: false
options:
  - "Yes — I launched it and checked the items below"
  - "No — I have not launched the current build this session"

question: "Core stability — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Game does not launch or crashes before reaching the main menu"
  - "New game / session fails to start"
  - "Main menu does not respond to inputs"
  - "Crash or hang observed during basic navigation"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

If the build was **not launched**, the Batch 1 checks could not be executed:
record them as `NOT RUN — build not launched this session`, skip Batches 2 and
3 and any platform batch (say so — they need a running build), and ignore the
unselected failure list. The verdict is then NOT ASSESSED unless something else
FAILED.

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

**Status**: [PASS ([N] tests, [N] passing) | PASS WITH WARNINGS ([N] tests
passing; [the runner's warning, e.g. [N] orphan nodes leaked]) | FAIL ([N]
failures, or did not complete: [timeout | compile, parse or build error | no
results file]) | NOT ASSESSED ([reason, e.g. zero tests executed, runner could
not run]) | NOT RUN ([reason]) | WAIVED (qa.level: minimal — no game tests)]

[Unity: one Status line per test platform — `EditMode:` and `PlayMode:`.]

[WAIVED only:] **Build check**: [PASS — `[command]` exit 0 | FAIL — [reason] |
NOT RUN — [commands.smoke and commands.build unset | executable not found]]

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

- [x] Build launched this session — yes [or: `NOT RUN — build not launched this session`; the batches below were not asked]
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
- The automated suite did not complete: a timeout, a compile, parse or build
  error, or no results file after the run (Phase 2 names each engine's form)
- The build check (WAIVED path) failed: a non-zero exit, a timeout, or a Godot
  `SCRIPT ERROR` or no-main-scene line
- Any Batch 1 (core stability) check returned FAIL
- Any Batch 2 (primary sprint mechanic or regression check) returned FAIL

**NOT ASSESSED** if ANY of:
- The automated suite is **unconfirmed NOT RUN** — nobody has reported a result
- The runner could not run (gdUnit4 103 or 104, gdUnit4 or the Unity Test
  Framework not installed), or it ran and executed zero tests
  (`No test cases found`, `testcasecount="0"`, `No automation tests matched`)
- Unity Play Mode tests exist and are `PlayMode: NOT RUN`, unconfirmed — the
  Edit Mode result does not cover them
- A Batch 1 or Batch 2 check could not be executed (no build, engine not
  configured, platform unavailable) as opposed to executing and failing —
  including a Batch 1 answer that the build was not launched this session
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suite passes matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 3 was offered and skipped** ("Performance not checked this session").
  It is not a FAIL, not an execution failure, and not "PASS or N/A", so without
  this line it matches no rule at all and renders as `[-]` beside a PASS

**PASS WITH WARNINGS** if ALL of:
- Automated tests PASS or PASS WITH WARNINGS, WAIVED at `qa.level: minimal`, or
  NOT RUN **and the developer has confirmed the result from their local IDE or CI**
- All Batch 1 and Batch 2 smoke checks PASS
- At least one warning: a Logic/Integration story with MISSING test evidence,
  a runner warning on a passing suite (gdUnit4 101 — orphan nodes leaked), or
  a NOT RUN suite the developer confirmed

**PASS** if ALL of:
- Automated tests PASS, or WAIVED (`qa.level: minimal` and no game tests exist —
  the build check, when `commands.smoke` or `commands.build` is set, and the
  launch and critical-path batches below then carry the verdict)
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
`PlayMode: NOT RUN`, zero tests executed, runner not installed, engine
executable not found, no build, build not launched this session, platform
unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'run `/setup-engine`', 'set `engine.path`',
'produce a build', 'launch the build and play the checks'.]

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
[list MISSING test evidence entries, and any runner warning — e.g. the orphan
count]

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
