# /smoke-check — Phase 2: Run Automated Tests

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Run Automated Tests

**In this file:**

- `commands.test` first
- Godot 4
- Unity: Edit Mode, then Play Mode as a second run
- Unreal Engine: build first, commands per OS, macOS
- Unknown engine / not configured
- Test runner not available here
- Build check (the WAIVED path only)

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
Windows forms below were run on UE 5.7; the Linux and macOS forms come from
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
relative one, run it with the absolute path instead: UE 5.7
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
