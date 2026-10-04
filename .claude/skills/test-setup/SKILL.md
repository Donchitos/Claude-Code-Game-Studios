---
name: test-setup
description: "Scaffold the test framework and CI — tests/ directory, engine test runner, GitHub Actions workflow. Once, before the first sprint."
argument-hint: "[force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Setup

This skill scaffolds the automated testing infrastructure for the project.
It detects the configured engine, generates the appropriate test runner
configuration, creates the standard directory layout, and wires up CI/CD
so tests run on every push.

Run this once during the Technical Setup phase, before any implementation
begins. A test framework installed at sprint start costs 30 minutes.
A test framework installed at sprint four costs 3 sprints.

**Output:** `tests/` directory structure + `.github/workflows/tests.yml`

---

## Phase 1: Detect Engine and Existing State

1. **Read engine config**:
   - Read `engine.name` from `project.yaml`; if that key is absent or empty
     (including when `project.yaml` has no `engine:` block), fall back to the
     `Engine:` value in `.claude/docs/technical-preferences.md`.
   - If neither source yields a configured engine (project.yaml `engine.name`
     absent/empty and technical-preferences.md shows `[TO BE CONFIGURED]` or is
     missing), stop:
     "Engine not configured. Run `/setup-engine` first, then re-run `/test-setup`."

2. **Check for existing test infrastructure**:
   - Glob `tests/` — does the directory exist?
   - Glob `tests/unit/` and `tests/integration/` — do subdirectories exist?
   - Glob `.github/workflows/` — does a CI workflow file exist?
   - Glob `addons/gdUnit4/bin/GdUnitCmdTool.gd` (Godot — note the capital U) or
     `Assets/Tests/EditMode/` (Unity) or `Source/*/Private/Tests/` (Unreal) for
     engine-specific artifacts. These are the **test roots** in
     `.claude/docs/directory-structure.md`; tests anywhere else are never compiled
     on Unity or Unreal.

3. **Report findings**:
   - "Engine: [engine]. Test directory: [found / not found]. CI workflow: [found / not found]."
   - If everything already exists AND `force` argument was not passed:
     "Test infrastructure appears to be in place. Re-run with `/test-setup force`
     to regenerate. Proceeding will not overwrite existing test files."

If the `force` argument is passed, skip the "already exists" early-exit and
proceed — but still do not overwrite files that already exist at a given path.
Only create files that are missing.

---

## Phase 2: Present Plan

Based on the engine detected and the existing state, present a plan:

```
## Test Setup Plan — [Engine]

I will create the following (skipping any that already exist):

tests/
  unit/           — Isolated unit tests for formulas, state, and logic   (Godot only)
  integration/    — Cross-system tests and save/load round-trips         (Godot only)
  smoke/          — Critical path test list (15-minute manual gate)
  README.md       — Test framework documentation

[Unity/Unreal: unit and integration tests go under the engine's test root
 instead — Unity Assets/Tests/EditMode|PlayMode/, Unreal
 Source/<Module>/Private/Tests/ — because neither compiles code in tests/]

production/qa/
  evidence/       — Screenshot and manual test sign-off records

[Engine-specific files — see per-engine details below]

.github/workflows/tests.yml  — CI: run tests on every push to main

Estimated time: ~5 minutes to create all files.
```

Ask: "May I create these files? I will not overwrite any test files that
already exist at these paths."

**At `collaborative` and `guided`** — do not proceed without approval. These are
**new** files, and `automation-modes.md:81` gates new-file writes in `guided` too,
so the answer is the same in both modes. **At `autonomous`** — create them and log
the decision; do not block. An unconditional gate here would read as "block even
in autonomous" and contradict this skill's own header.

---

## Phase 3: Create Directory Structure

After approval, create the following files:

### `tests/README.md`

````markdown
# Test Infrastructure

**Engine**: [engine name + version]
**Test Framework**: [GdUnit4 | Unity Test Framework | UE Automation]
**CI**: `.github/workflows/tests.yml`
**Setup date**: [date]

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

[Unity/Unreal — replace the unit/integration lines: unit and integration tests
live under the engine's test root, `Assets/Tests/EditMode|PlayMode/[System]/`
or `Source/<Module>/Private/Tests/[System]/`; `tests/` keeps this README and
`smoke/`. Every `tests/unit/` path below means that test root.]

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

[Engine-specific command — see below]

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Godot**: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`
- **Unity**: class `[System]Tests` in `[System]Tests.cs`, method `[Scenario]_[Expected]`
  — `CombatTests.cs` → `BaseAttack_ReturnsExpectedDamage()`
- **Unreal**: class `F[System][Scenario]Test`, test name `<Project>.[System].[Scenario]`
  — `FCombatBaseAttackTest` → `<Project>.Combat.BaseAttack`
  [`<Project>` is the root the filter in `commands.test` uses — write it out:
  the project name, or the distinct root `/setup-engine` chose]

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
````

The README and this skill's completion summary name the same evidence path —
`production/qa/evidence/` is where `/smoke-check`, `/test-evidence-review`,
`/qa-plan` and the evidence table in `.claude/docs/coding-standards.md` read,
so a `tests/evidence/` would be a directory nothing reads.

### `production/qa/evidence/.gitkeep`

Create it empty. Git does not keep an empty directory, and this is where
`/story-done`, `/smoke-check` and `/test-evidence-review` look for screenshots and
sign-off records — the completion summary lists it, so it must exist.

### Engine-specific files

#### Godot 4 (`Engine: Godot`)

**Do not write a runner script.** gdUnit4 ships its own command-line runner,
`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`. The command CI, `/smoke-check`
and `commands.test` use is:

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first. A fresh clone has no `.godot/` class cache, and a run
without one exits **1** — `GdUnitCmdTool.gd` did not load (`Failed to load
script`), so no test ran. A cache older than a new `class_name` fails valid
code with 105. The CI action imports on its own.

Exit code **0** when every test passes and **100** when any fails — verified
on Godot 4.6.1 with gdUnit4 6.1.3. **101** means every test passed but a test
leaked nodes: a warning, not a failure. 103 and 104 mean gdUnit4 could not run
(headless refused, Godot older than 4.3); 105 means a test script does not parse. `-a res://tests` runs every suite
under `tests/`; `--ignoreHeadlessMode` is required because gdUnit4 otherwise
refuses to run headless. `--remote-debug tcp://127.0.0.1:0` is required too —
it is what gdUnit4's own `runtest` script passes. Without it a script error
opens Godot's interactive debugger, and the run waits at a `debug>` prompt
forever instead of exiting 105. The flag makes every run print two `ERROR:`
lines about the remote port (`127.0.0.1:0`); they are expected, not a failure.
A run that finds no tests prints `No test cases found` and exits 0 — that is
not a pass. The folder is `addons/gdUnit4/` with a **capital U**.

Create `tests/unit/.gdignore_placeholder` with content:
`# Unit tests go here — one subdirectory per system (e.g., tests/unit/combat/)`

Create `tests/integration/.gdignore_placeholder` with content:
`# Integration tests go here — one subdirectory per system`

Note in the README: **Installing GdUnit4**
```
1. Open Godot → AssetLib → search "GdUnit4" → Download & Install
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: res://addons/gdUnit4/bin/GdUnitCmdTool.gd exists (capital U)
```

#### Unity (`Engine: Unity`)

Tests live under **`Assets/Tests/`** — Unity compiles only `Assets/` and
`Packages/`. A test under `tests/` is never compiled, and the run then reports
**0 tests, `Passed`, exit 0** (verified on 6000.3.23f1): a false pass.

First check the Test Framework package:
`grep -q 'com.unity.test-framework' Packages/manifest.json`. Without it
`-runTests` does not fail — it hangs. If absent, ask to add
`"com.unity.test-framework"` to `dependencies` at the version your editor
bundles. Unity 6 releases bundle different ones — 1.6.0 in 6000.3.23f1, 1.5.1 in
6000.1.0f1 — so read it rather than copy a number: on Windows it is the
`version` in `Data/Resources/PackageManager/BuiltInPackages/com.unity.test-framework/package.json`
under the folder that holds `Unity.exe`.

Create `Assets/Tests/EditMode/EditModeTests.asmdef` — unit tests, no Play Mode:
```json
{
  "name": "EditModeTests",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

Create `Assets/Tests/PlayMode/PlayModeTests.asmdef` — integration tests in a
running scene: the same JSON with `"name": "PlayModeTests"` and
`"includePlatforms": []`.

> **A test assembly cannot see code in the default `Assembly-CSharp`.** An
> `.asmdef` can reference only other `.asmdef`s. If the game's scripts have no
> `.asmdef` of their own, ask before creating one (e.g. `Assets/Scripts/Game.asmdef`)
> and add `"Game"` to both test assemblies' `references`. Without it the first
> test that names a game class fails to compile. Moving scripts into an
> `.asmdef` changes what they can see, so before creating it:
>
> - **List the packages the scripts use.** `Assembly-CSharp` references every
>   package on its own; an `.asmdef` references only what it names. Read the
>   scripts' `using` lines and add the matching assemblies — commonly
>   `"Unity.InputSystem"`, `"Unity.TextMeshPro"`, `"UnityEngine.UI"`:
>   `{ "name": "Game", "references": ["Unity.InputSystem", "Unity.TextMeshPro"] }`.
>   Name only packages the project has installed.
> - **Give each `Editor/` folder under it its own `.asmdef`** with
>   `"includePlatforms": ["Editor"]` and `"references": ["Game"]`. Otherwise
>   editor scripts join the runtime assembly, and `using UnityEditor;` breaks the
>   player build.

Note in the README: **Running Unity tests** (use the editor executable —
`Unity` on `PATH` may be Unity's separate CLI, not the editor)
```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
Exit **0** when every test passes, **2** when any fails. Exit 1 or 3 is a FAIL
too: 1 is a compile error, which writes no results file, and 3 a failed run.
So is 4 (an unknown `-testPlatform`), and any other non-zero exit.
Delete `test-results/editmode.xml` before each run so an old file is never read
as a new result. Read the `<test-run>`
element of the results file: `testcasecount="0"` means nothing was compiled or
found — report it as not assessed, never as a pass. Do not add `-quit`;
`-runTests` exits by itself. Play Mode is the second line: a separate run with
its own results file, read the same way, and deleted before each run the same
way. An Edit Mode run never runs the tests in `Assets/Tests/PlayMode/`, so
`/smoke-check` runs both whenever that folder holds tests.

#### Unreal Engine (`Engine: Unreal` or `Engine: UE5`)

Tests live **inside the game module**: `Source/<Module>/Private/Tests/`, where
`<Module>` is the primary game module (for a C++ project, the `.uproject` name).
UnrealBuildTool compiles only module folders — a tests folder directly under
`Source/` is not a module, so a test there is silently never built and every
run reports `No automation tests matched`.

Create `Source/<Module>/Private/Tests/README.md`. `<Project>.` in it — and
`[ProjectName].` in the CI filter below — is the test root the filter in
`commands.test` uses: the project name, or the distinct root `/setup-engine`
chose when the project's name is also an engine area. Write that root:
```markdown
# Unreal Automation Tests
Tests use the UE Automation Testing Framework and compile with this module.
Wrap each test file in `#if WITH_DEV_AUTOMATION_TESTS` … `#endif`.
Flags: `EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`
(there is no `GameFilter` flag).

Run via: Session Frontend → Automation → select "<Project>." tests
Or headlessly from the project root, after building the editor target — on a
fresh checkout the editor exits before any test runs:
"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"
"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<Project>.uproject" -ExecCmds="Automation RunTests <Project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput
The project path must be absolute: UE does not find a relative one (exit 1,
"Project file not found"). Those two lines are Windows'. On Linux build with
`Engine/Build/BatchFiles/Linux/Build.sh <Project>Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"` and run
the tests with `Engine/Binaries/Linux/UnrealEditor` and the same arguments; on
macOS build with `Engine/Build/BatchFiles/Mac/Build.sh <Project>Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/<Project>.uproject"`
— Epic documents no command-line editor inside `UnrealEditor.app` for the test
run (see `docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

Read the output, not the exit code: a failing test and a run that matched nothing both exit 255.
`Result={Fail}` is a failure; `No automation tests matched` means no test was
built or named `<Project>.…`.

Test class naming: F[System][Scenario]Test — one class per test; a second
test reusing a class name fails to link
Test name: "<Project>.[System].[Scenario]"
```

---

## Phase 4: Create CI/CD Workflow

### Godot 4

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run GdUnit4 Tests
    runs-on: ubuntu-latest
    # The action publishes its results as a check run. A new repository's
    # token is read-only, and without checks: write the job fails even when
    # every test passes. If you protect main, require the `Run GdUnit4 Tests` job
    # check, not `test-results`: that check run concludes success even when a
    # test fails.
    permissions:
      contents: read
      checks: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      # godot-version must be a full release such as 4.6.1 (`godot --version`
      # shows it); VERSION.md's "4.6" is not one. version: installed runs the
      # gdUnit4 committed in addons/ -- without it the action deletes that
      # copy and installs the latest release, which may not match your tests.
      - name: Run GdUnit4 Tests
        uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: '[FULL GODOT VERSION, e.g. 4.6.1]'
          version: 'installed'
          paths: |
            tests/unit
            tests/integration
          report-name: test-results

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: reports/
```

### Unity

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Unity Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Run Edit Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: editmode
          artifactsPath: test-results/editmode

      - name: Run Play Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: playmode
          artifactsPath: test-results/playmode

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-results/
```

Note: Unity CI requires a `UNITY_LICENSE` secret. Add to GitHub repository
secrets before the first CI run.

### Unreal Engine

Create `.github/workflows/tests.yml`:

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run UE Automation Tests
    runs-on: [self-hosted, windows]  # UE requires a local runner with the editor installed

    # The quoted "{0}" in each `shell:` below: the Windows runner passes bash
    # its script path unquoted, so with plain `shell: bash` every step fails
    # ("No such file or directory") when the runner's folder has a space.
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      # Binaries/ is gitignored, so a fresh checkout has no compiled game
      # module: without this step the editor stops with "The game module could
      # not be found" before running any test. UnrealBuildTool.exe, not
      # Build.bat -- from bash, Build.bat fails on an engine path with spaces.
      - name: Build Editor Target
        run: |
          "$UE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" [ProjectName]Editor Win64 Development \
            -Project="${{ github.workspace }}/[ProjectName].uproject"
        shell: bash --noprofile --norc -eo pipefail "{0}"

      # -stdout -FullStdOutLogOutput: without them the editor prints nothing
      # here, and the results are only in Saved/Logs/.
      - name: Run Automation Tests
        run: |
          "$UE_ROOT/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "${{ github.workspace }}/[ProjectName].uproject" \
            -nullrhi -nosound \
            -ExecCmds="Automation RunTests [ProjectName].; Quit" \
            -unattended -stdout -FullStdOutLogOutput
        shell: bash --noprofile --norc -eo pipefail "{0}"

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-logs
          path: Saved/Logs/
```

Note: UE CI requires a self-hosted Windows runner with Unreal Editor installed.
The `windows` label keeps the job off any Linux self-hosted runner the
repository also has. Set the `UE_ROOT` environment variable on the runner to the engine folder
(e.g. `C:/Program Files/Epic Games/UE_5.8`). `[ProjectName]Editor` is the
editor target in `Source/[ProjectName]Editor.Target.cs`.

---

## Phase 5: Create Smoke Test Seed

Create `tests/smoke/critical-paths.md`:

```markdown
# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. New game / session can be started from the main menu
3. Main menu responds to all inputs without freezing

## Core Mechanic (update per sprint)

<!-- Add the primary mechanic for each sprint here as it is implemented -->
<!-- Example: "Player can move, jump, and the camera follows correctly" -->
4. [Primary mechanic — update when first core system is implemented]

## Data Integrity

5. Save game completes without error (once save system is implemented)
6. Load game restores correct state (once load system is implemented)

## Performance

7. No visible frame rate drops on target hardware (60fps target)
8. No memory growth over 5 minutes of play (once core loop is implemented)
```

---

## Phase 6: Post-Setup Summary

After writing all files, report:

```
Test infrastructure created for [engine].

Files created:
- tests/README.md
- tests/unit/ and tests/integration/ (Godot) — or the engine's test root:
  Unity Assets/Tests/EditMode/ and PlayMode/, Unreal Source/<Module>/Private/Tests/
- tests/smoke/critical-paths.md
- production/qa/evidence/.gitkeep
[engine-specific files]
- .github/workflows/tests.yml

Next steps:
1. [Engine-specific install step, e.g., "Install GdUnit4 via AssetLib"]
2. Write your first test in the engine's test root:
   tests/unit/[system]/[system]_[feature]_test.gd (Godot),
   Assets/Tests/EditMode/[System]Tests.cs (Unity), or
   Source/<Module>/Private/Tests/[System]Test.cpp (Unreal)
3. Run `/qa-plan sprint` before your first sprint to classify stories and set
   test evidence requirements. At `workflow: minimal` — the default — skip
   this: there are no sprints. At `qa.level: minimal`, also the default, tests
   are waived, so `/dev-story` writes none. Raise `qa.level` with `/settings`
   to have it write them
4. `/smoke-check` before every QA hand-off

Gate note: /gate-check Technical Setup → Pre-Production now requires:
- the engine's test root: tests/unit/ and tests/integration/ (Godot),
  Assets/Tests/EditMode/ and Assets/Tests/PlayMode/ (Unity), or
  Source/<Module>/Private/Tests/ (Unreal)
- .github/workflows/tests.yml
- At least one example test file
Run /test-setup and write one example test before advancing.
(At `workflow: minimal` that gate requires only the engine.)

Verdict: **COMPLETE** — test framework scaffolded and CI/CD wired up.
```

---

## Collaborative Protocol

- **Never overwrite existing test files** — only create files that are missing.
  If a test runner file exists, leave it as-is.
- **Always ask before creating files** — Phase 2 requires explicit approval.
- **Engine detection is non-negotiable** — if the engine is not configured,
  stop and redirect to `/setup-engine`. Do not guess.
- **`force` flag skips the "already exists" early-exit but never overwrites.**
  It means "create any missing files even if the directory already exists."
- For Unity CI, note that the `UNITY_LICENSE` secret must be configured
  manually. Do not attempt to automate license management.
