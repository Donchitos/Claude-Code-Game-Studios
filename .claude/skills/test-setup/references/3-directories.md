# /test-setup — Phase 3: Create Directory Structure

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Create Directory Structure

**In this file:**

- `tests/README.md`
- `production/qa/evidence/.gitkeep`
- Engine-specific files

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
