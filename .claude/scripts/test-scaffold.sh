#!/usr/bin/env bash
# test-scaffold.sh — creates the files /test-setup scaffolds for one engine,
# never overwriting one that exists, and prints per path whether it was
# created, already there or skipped, then the inputs it still needs.
#
# Replaces the file-by-file creation of a test setup: the README, the evidence
# folder's .gitkeep, the engine's test folders or assembly definitions, the CI
# workflow and the smoke-test seed.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# It reports what it did with each path and what is still missing; whether
# the project may advance a gate on the strength of it is the skill's call.
#
# Usage: bash .claude/scripts/test-scaffold.sh ENGINE [--dry-run | --list] [--root DIR]
#          [--module NAME] [--project NAME] [--date YYYY-MM-DD]
#   ENGINE          godot, unity, unreal or web (the engine.name values, in any case;
#                   UE5 is not one)
#   --dry-run       print what would be created (WOULD_CREATE), write nothing
#   --list          print the project-relative paths this engine's scaffold
#                   creates, one per line and nothing else, whatever already
#                   exists (the write guard reads it for its never-overwrite rule)
#   --root DIR      the project; defaults to the repo this script is in
#   --module NAME   unreal: the game module (Source/NAME/Private/Tests/); default
#                   the name of the one .uproject file in the root
#   --project NAME  unreal: the project name, which is also the test root unless
#                   /setup-engine chose another; default the .uproject name, else
#                   the module name
#   --date D        the setup date for the README (default: today)
#   -h, --help      this text
#
# Files per engine, in this order (the skill's Phases 3 to 5):
#   all      tests/README.md, production/qa/evidence/.gitkeep
#   godot    tests/unit/.gitkeep, tests/integration/.gitkeep
#   unity    Assets/Tests/EditMode/EditModeTests.asmdef,
#            Assets/Tests/PlayMode/PlayModeTests.asmdef
#   unreal   Source/<Module>/Private/Tests/README.md
#   web      tests/unit/.gitkeep, tests/integration/.gitkeep, playwright.config.ts
#            (the web scaffold's own, .claude/engines/web/scaffold/)
#   all      .github/workflows/tests.yml, tests/smoke/critical-paths.md
# The skill asks Godot's two test folders to hold a .gdignore_placeholder file;
# Godot knows no such name (.gdignore would hide the folder from the editor and
# from the test runner), so they hold an empty .gitkeep, which keeps the empty
# folder in git. Unity and Unreal tests live in the engine's test root because
# neither compiles code under tests/.
# The README carries the setup date and the engine version (engine.version of
# project.local.yaml, then project.yaml). The CI workflow carries the full
# Godot version where engine.version has three numbers; a value that is not
# known stays as the skill writes it in square brackets and is listed as an
# input still needed. Local and CI commands are the skill's, and they differ
# on Godot (CI runs tests/unit and tests/integration, the local command runs
# everything under tests/); the README says so.
#
# Output: TSV.
#   engine <name>, mode write|dry-run, then per path
#   CREATED <path> | WOULD_CREATE <path> | EXISTS <path> | SKIPPED <path> <reason>
#   | FAILED <path> <reason>, then created (or would_create) <n>, exists <n>,
#   skipped <n> (and failed <n> when above 0), then
#   NEEDS <id> <file> <what> for each input still needed.
#   EXISTS means the path was there (a file, a folder or a link) and was not
#   touched. A file is written with the shell's noclobber on, so one that
#   appears between the check and the write is left alone too.
#
# Exit codes: 0 every path created or already there; 1 the root cannot be read;
# 2 usage error; 3 a path was skipped (its reason is in the row); 4 a file or
# folder could not be created (FAILED). Never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for sed and the YAML reader.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "test-scaffold: $1 (try --help)" >&2; exit 2; }
TAB=$(printf '\t')

ENGINE=""; MODE=write; ROOT_ARG=""; MODULE_ARG=""; PROJECT_ARG=""; DATE_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) [ "$MODE" != list ] || usage "--list and --dry-run cannot be combined"; MODE=dry-run; shift ;;
    --list) [ "$MODE" != dry-run ] || usage "--list and --dry-run cannot be combined"; MODE=list; shift ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --module) [ $# -ge 2 ] || usage "--module needs a name"; MODULE_ARG="$2"; shift 2 ;;
    --module=*) MODULE_ARG="${1#--module=}"; shift ;;
    --project) [ $# -ge 2 ] || usage "--project needs a name"; PROJECT_ARG="$2"; shift 2 ;;
    --project=*) PROJECT_ARG="${1#--project=}"; shift ;;
    --date) [ $# -ge 2 ] || usage "--date needs a value"; DATE_ARG="$2"; shift 2 ;;
    --date=*) DATE_ARG="${1#--date=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) usage "unknown argument: $1" ;;
    *) [ -z "$ENGINE" ] || usage "one engine at a time, got $ENGINE and $1"; ENGINE="$1"; shift ;;
  esac
done
[ -n "$ENGINE" ] || usage "no engine: godot, unity, unreal or web"
ENG=$(printf '%s' "$ENGINE" | tr '[:upper:]' '[:lower:]')
case "$ENG" in
  godot|unity|unreal|web) ;;
  *) usage "engine must be godot, unity, unreal or web (the engine.name values), got $ENGINE" ;;
esac
# A module or project name goes into paths and file text: letters, digits and _ only.
for _n in "$MODULE_ARG" "$PROJECT_ARG"; do
  case "$_n" in *[!A-Za-z0-9_]*) usage "a module or project name takes letters, digits and _, got $_n" ;; esac
done
if [ -n "$DATE_ARG" ]; then
  case "$DATE_ARG" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) usage "--date takes YYYY-MM-DD, got $DATE_ARG" ;;
  esac
fi

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "test-scaffold: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "test-scaffold: cannot reach the repo root" >&2; exit 1; }
fi

# ------------------------------------------------------------ names and version
# Unreal names: the flags, else the one .uproject in the root (the skill: for a
# C++ project the module is the .uproject name).
UPROJ=""
if [ "$ENG" = unreal ]; then
  _u=$(find . -maxdepth 1 -type f -name '*.uproject' 2>/dev/null | sed 's|^\./||' | sort)
  if [ -n "$_u" ] && [ "$(printf '%s\n' "$_u" | wc -l | tr -d ' ')" = 1 ]; then
    UPROJ="${_u%.uproject}"
    case "$UPROJ" in *[!A-Za-z0-9_]*) UPROJ="" ;; esac
  fi
fi
PROJ_NAME="${PROJECT_ARG:-${UPROJ:-$MODULE_ARG}}"
MOD_NAME="${MODULE_ARG:-${UPROJ:-$PROJECT_ARG}}"

# The engine version, as project-state.sh reads project.yaml: the shared reader.
VER=""
if [ -f "$HERE/yaml-get.awk" ]; then
  for _yf in project.local.yaml project.yaml; do
    if [ -z "$VER" ] && [ -f "$_yf" ]; then
      VER=$(YG_PATH=engine.version awk -f "$HERE/yaml-get.awk" "$_yf")
    fi
  done
fi
# A version goes into file text: keep it to the characters a version has.
case "$VER" in ''|-|*[!A-Za-z0-9._+-]*) VER="" ;; esac

case "$ENG" in
  godot) ENGNAME=Godot ;;
  unity) ENGNAME=Unity ;;
  unreal) ENGNAME=Unreal ;;
  web) ENGNAME=Web ;;
esac
if [ -n "$VER" ]; then ENGTXT="$ENGNAME $VER"; else ENGTXT="$ENGNAME [version]"; fi
# Web's engine.version is the bundler's (Vite for a new project).
[ "$ENG" != web ] || { if [ -n "$VER" ]; then ENGTXT="Web (Vite $VER)"; else ENGTXT="Web (Vite [version])"; fi; }
# Godot CI needs a full release such as 4.7.2; "4.7" is not one.
GODOTVER="[FULL GODOT VERSION, e.g. 4.7.2]"
case "$VER" in
  [0-9]*.[0-9]*.[0-9]*) [ "$ENG" != godot ] || GODOTVER="$VER" ;;
esac
DATE="${DATE_ARG:-$(date +%Y-%m-%d)}"
MODTXT="${MOD_NAME:-<Module>}"
DOCPROJ="${PROJ_NAME:-<Project>}"
CIPROJ="${PROJ_NAME:-[ProjectName]}"

# ---------------------------------------------------------------------- paths
README=tests/README.md
EVID=production/qa/evidence/.gitkeep
CI=.github/workflows/tests.yml
SMOKE=tests/smoke/critical-paths.md
UNREAL_README="Source/$MODTXT/Private/Tests/README.md"
list_paths() {
  echo "$README"
  echo "$EVID"
  case "$ENG" in
    godot) echo tests/unit/.gitkeep; echo tests/integration/.gitkeep ;;
    unity) echo Assets/Tests/EditMode/EditModeTests.asmdef; echo Assets/Tests/PlayMode/PlayModeTests.asmdef ;;
    unreal) echo "$UNREAL_README" ;;
    web) echo tests/unit/.gitkeep; echo tests/integration/.gitkeep; echo playwright.config.ts ;;
  esac
  echo "$CI"
  echo "$SMOKE"
}
if [ "$MODE" = list ]; then
  list_paths
  exit 0
fi

# ------------------------------------------------------------------- contents
# Each file is a function printing it; @TOKENS@ are filled by render.
tpl_readme_godot() {
  cat <<'TPL_README_GODOT'
# Test Infrastructure

**Engine**: @ENGINE@
**Test Framework**: GdUnit4
**CI**: `.github/workflows/tests.yml`
**Setup date**: @DATE@

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first: a fresh clone has no `.godot/` class cache, and a run
without one exits 1 (`GdUnitCmdTool.gd` did not load, so no test ran). Exit 0:
every test passed. Exit 100: a test failed. Exit 101: every test passed but a
test leaked nodes (a warning). Exit 103 or 104: gdUnit4 could not run. Exit 105:
a test script does not parse. A run that finds no tests prints `No test cases
found` and exits 0, which is not a pass. The folder is `addons/gdUnit4/` with a
capital U.

CI runs `tests/unit` and `tests/integration`; the command above runs every suite
under `tests/`.

## Installing GdUnit4

```
1. Open Godot → Asset Store (AssetLib before Godot 4.7) → search "GdUnit4" → install it
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: res://addons/gdUnit4/bin/GdUnitCmdTool.gd exists (capital U)
```

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Godot**: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

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
TPL_README_GODOT
}

tpl_readme_unity() {
  cat <<'TPL_README_UNITY'
# Test Infrastructure

**Engine**: @ENGINE@
**Test Framework**: Unity Test Framework
**CI**: `.github/workflows/tests.yml`
**Setup date**: @DATE@

## Directory Layout

Unity compiles only `Assets/` and `Packages/`, so unit and integration tests
live under the engine's test root, not in `tests/`: a test under `tests/` is never
compiled, and the run reports 0 tests and `Passed`, a false pass.

```
Assets/Tests/
  EditMode/       # Isolated unit tests (formulas, state machines, logic)
  PlayMode/       # Integration tests in a running scene
```

`tests/` keeps this README and `smoke/`. Every `tests/unit/` path below means
that test root.

```
tests/
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

Use the editor executable: `Unity` on `PATH` may be Unity's separate CLI, not
the editor.

```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```

Exit 0: every test passed. Exit 2: a test failed. Exit 1, 3 and 4 (a compile
error, a failed run, an unknown `-testPlatform`) and any other non-zero exit
are failures too; a compile error writes no results file. Delete each results
file before its run so an old file is never read as a new result. Read the
`<test-run>` element of the results file: `testcasecount="0"` means nothing was
compiled or found, which is not a pass. Do not add `-quit`; `-runTests` exits by
itself. An Edit Mode run never runs the tests in `Assets/Tests/PlayMode/`, so
run both.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Unity**: class `[System]Tests` in `[System]Tests.cs`, method `[Scenario]_[Expected]`
  — `CombatTests.cs` → `BaseAttack_ReturnsExpectedDamage()`

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
A failed test suite blocks merging. Unity CI needs the `UNITY_LICENSE`
repository secret.
TPL_README_UNITY
}

tpl_readme_unreal() {
  cat <<'TPL_README_UNREAL'
# Test Infrastructure

**Engine**: @ENGINE@
**Test Framework**: UE Automation
**CI**: `.github/workflows/tests.yml`
**Setup date**: @DATE@

## Directory Layout

UnrealBuildTool compiles only module folders, so unit and integration tests
live inside the game module, not in `tests/`: a test directly under `Source/`
is silently never built.

```
Source/@MODULE@/Private/Tests/   # Unit and integration tests, compiled with the module
```

`tests/` keeps this README and `smoke/`. Every `tests/unit/` path below means
that test root.

```
tests/
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

The commands are in `Source/@MODULE@/Private/Tests/README.md`. Read the output,
not the exit code: a failing test and a run that matched nothing both exit 255.
`Result={Fail}` is a failure; `No automation tests matched` means no test was
built or named `@DOCPROJECT@.…`.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Unreal**: class `F[System][Scenario]Test`, test name `@DOCPROJECT@.[System].[Scenario]`
  — `FCombatBaseAttackTest` → `@DOCPROJECT@.Combat.BaseAttack`

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
A failed test suite blocks merging. Unreal CI needs a self-hosted Windows
runner with Unreal Editor installed and `UE_ROOT` set.
TPL_README_UNREAL
}

tpl_ci_godot() {
  cat <<'TPL_CI_GODOT'
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
        uses: actions/checkout@v7
        with:
          lfs: true

      # godot-version must be a full release such as 4.7.2 (`godot --version`
      # shows it); VERSION.md's "4.7" is not one. version: installed runs the
      # gdUnit4 committed in addons/ -- without it the action deletes that
      # copy and installs the latest release, which may not match your tests.
      - name: Run GdUnit4 Tests
        uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: '@GODOTVER@'
          version: 'installed'
          paths: |
            tests/unit
            tests/integration
          report-name: test-results

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: reports/
TPL_CI_GODOT
}

tpl_ci_unity() {
  cat <<'TPL_CI_UNITY'
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
        uses: actions/checkout@v7
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
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: test-results/
TPL_CI_UNITY
}

tpl_ci_unreal() {
  cat <<'TPL_CI_UNREAL'
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
        uses: actions/checkout@v7
        with:
          lfs: true

      # Binaries/ is gitignored, so a fresh checkout has no compiled game
      # module: without this step the editor stops with "The game module could
      # not be found" before running any test. UnrealBuildTool.exe, not
      # Build.bat -- from bash, Build.bat fails on an engine path with spaces.
      - name: Build Editor Target
        run: |
          "$UE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" @CIPROJECT@Editor Win64 Development \
            -Project="${{ github.workspace }}/@CIPROJECT@.uproject"
        shell: bash --noprofile --norc -eo pipefail "{0}"

      # -stdout -FullStdOutLogOutput: without them the editor prints nothing
      # here, and the results are only in Saved/Logs/.
      - name: Run Automation Tests
        run: |
          "$UE_ROOT/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "${{ github.workspace }}/@CIPROJECT@.uproject" \
            -nullrhi -nosound \
            -ExecCmds="Automation RunTests @CIPROJECT@.; Quit" \
            -unattended -stdout -FullStdOutLogOutput
        shell: bash --noprofile --norc -eo pipefail "{0}"

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-logs
          path: Saved/Logs/
TPL_CI_UNREAL
}

tpl_readme_web() {
  cat <<'TPL_README_WEB'
# Test Infrastructure

**Engine**: @ENGINE@
**Test Framework**: Vitest (the rules) and Playwright (the game in a browser)
**CI**: `.github/workflows/tests.yml`
**Setup date**: @DATE@

## Directory Layout

```
tests/
  unit/           # Vitest: the rules in src/game/, run in Node with no browser
  integration/    # Playwright: the single-file build in a browser, driven through window.game
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

```bash
npm test              # Vitest, then Playwright
npm run test:unit     # Vitest only
npm run test:e2e      # build:single, then Playwright
npm run smoke         # build:single, then the @boot test
```

Playwright opens `dist-single/index.html` from disk (`npm run build:single`
makes it), so no server and no port are needed. It launches the browser
`.claude/scripts/page-shot.sh --which` prints, the one every check uses. With
none, install one, once: `npx playwright install chromium-headless-shell`.
Each half exits 0 when every test passed and non-zero when one failed. A half
with no test file fails too: Vitest prints `No test files found` and Playwright
`No tests found`; neither is a pass.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Web**: file `[module].test.ts` (Vitest) or `[system].spec.ts` (Playwright),
  test `'[scenario] [expected]'` — `rules.test.ts` → `it('keeps the square inside the field')`

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
A failed test suite blocks merging. CI runs `npm ci`, then `npm test`, with
the runner's Chrome.
TPL_README_WEB
}

tpl_ci_web() {
  cat <<'TPL_CI_WEB'
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Vitest and Playwright Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Set up Node
        uses: actions/setup-node@v7
        with:
          node-version: 24

      # npm ci installs exactly what package-lock.json pins.
      - name: Install
        run: npm ci

      # Playwright launches the runner's Chrome, the browser
      # .claude/scripts/page-shot.sh finds, so no browser is downloaded.
      - name: Run Tests
        run: npm test

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: test-results/
          if-no-files-found: ignore
TPL_CI_WEB
}

tpl_smoke() {
  cat <<'TPL_SMOKE'
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
TPL_SMOKE
}

tpl_asmdef_edit() {
  cat <<'TPL_ASMDEF_EDIT'
{
  "name": "EditModeTests",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
TPL_ASMDEF_EDIT
}

tpl_asmdef_play() {
  cat <<'TPL_ASMDEF_PLAY'
{
  "name": "PlayModeTests",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner"],
  "includePlatforms": [],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
TPL_ASMDEF_PLAY
}

tpl_unreal_tests_readme() {
  cat <<'TPL_UNREAL_TESTS'
# Unreal Automation Tests
Tests use the UE Automation Testing Framework and compile with this module.
Wrap each test file in `#if WITH_DEV_AUTOMATION_TESTS` … `#endif`.
Flags: `EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`
(there is no `GameFilter` flag).

Run via: Session Frontend → Automation → select "@DOCPROJECT@." tests
Or headlessly from the project root, after building the editor target — on a
fresh checkout the editor exits before any test runs:
"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" @DOCPROJECT@Editor Win64 Development -Project="$(pwd -W 2>/dev/null || pwd)/@DOCPROJECT@.uproject"
"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/@DOCPROJECT@.uproject" -ExecCmds="Automation RunTests @DOCPROJECT@.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput
The project path must be absolute: UE does not find a relative one (exit 1,
"Project file not found"). Those two lines are Windows'. On Linux build with
`Engine/Build/BatchFiles/Linux/Build.sh @DOCPROJECT@Editor Linux Development -Project="$(pwd -W 2>/dev/null || pwd)/@DOCPROJECT@.uproject"` and run
the tests with `Engine/Binaries/Linux/UnrealEditor` and the same arguments; on
macOS build with `Engine/Build/BatchFiles/Mac/Build.sh @DOCPROJECT@Editor Mac Development -Project="$(pwd -W 2>/dev/null || pwd)/@DOCPROJECT@.uproject"`
— Epic documents no command-line editor inside `UnrealEditor.app` for the test
run (see `docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

Read the output, not the exit code: a failing test and a run that matched nothing both exit 255.
`Result={Fail}` is a failure; `No automation tests matched` means no test was
built or named `@DOCPROJECT@.…`.

Test class naming: F[System][Scenario]Test — one class per test; a second
test reusing a class name fails to link
Test name: "@DOCPROJECT@.[System].[Scenario]"
TPL_UNREAL_TESTS
}


render() {
  sed -e "s|@ENGINE@|$ENGTXT|g" -e "s|@DATE@|$DATE|g" -e "s|@GODOTVER@|$GODOTVER|g" \
      -e "s|@MODULE@|$MODTXT|g" -e "s|@DOCPROJECT@|$DOCPROJ|g" -e "s|@CIPROJECT@|$CIPROJ|g"
}
# content_of <path> -- the file's text, ready to write.
content_of() {
  case "$1" in
    "$README")
      case "$ENG" in godot) tpl_readme_godot ;; unity) tpl_readme_unity ;; unreal) tpl_readme_unreal ;; web) tpl_readme_web ;; esac | render ;;
    "$CI")
      case "$ENG" in godot) tpl_ci_godot ;; unity) tpl_ci_unity ;; unreal) tpl_ci_unreal ;; web) tpl_ci_web ;; esac | render ;;
    "$SMOKE") tpl_smoke ;;
    Assets/Tests/EditMode/EditModeTests.asmdef) tpl_asmdef_edit ;;
    Assets/Tests/PlayMode/PlayModeTests.asmdef) tpl_asmdef_play ;;
    Source/*/Private/Tests/README.md) tpl_unreal_tests_readme | render ;;
    # The web scaffold's own file, so /setup-engine web and /test-setup write the same one.
    playwright.config.ts) cat "$HERE/../engines/web/scaffold/playwright.config.ts" ;;
    *) : ;;
  esac
}
# write_new <path> -- stdin becomes the file; fails (and writes nothing) if it exists.
write_new() {
  mkdir -p "$(dirname "$1")" 2>/dev/null || return 1
  ( set -C; cat > "$1" ) 2>/dev/null
}

# ----------------------------------------------------------------------- run
printf 'engine\t%s\n' "$ENG"
printf 'mode\t%s\n' "$MODE"
NCREATE=0; NEXIST=0; NSKIP=0; NFAIL=0
CREATED_LIST=""
while IFS= read -r p; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf 'EXISTS\t%s\n' "$p"; NEXIST=$((NEXIST + 1)); continue
  fi
  case "$p" in
    Source/*/Private/Tests/README.md)
      if [ -z "$MOD_NAME" ]; then
        printf 'SKIPPED\t%s\tno module name: pass --module or keep one .uproject in the root\n' "$p"
        NSKIP=$((NSKIP + 1)); continue
      fi ;;
    playwright.config.ts)
      if [ ! -f "$HERE/../engines/web/scaffold/playwright.config.ts" ]; then
        printf 'SKIPPED\t%s\tthe web scaffold is missing (.claude/engines/web/scaffold/)\n' "$p"
        NSKIP=$((NSKIP + 1)); continue
      fi ;;
  esac
  if [ "$MODE" = dry-run ]; then
    printf 'WOULD_CREATE\t%s\n' "$p"; NCREATE=$((NCREATE + 1)); CREATED_LIST="$CREATED_LIST|$p|"; continue
  fi
  if content_of "$p" | write_new "$p"; then
    printf 'CREATED\t%s\n' "$p"; NCREATE=$((NCREATE + 1)); CREATED_LIST="$CREATED_LIST|$p|"
  else
    printf 'FAILED\t%s\tcould not create the folder or the file\n' "$p"; NFAIL=$((NFAIL + 1))
  fi
done <<EOF
$(list_paths)
EOF
if [ "$MODE" = dry-run ]; then printf 'would_create\t%d\n' "$NCREATE"; else printf 'created\t%d\n' "$NCREATE"; fi
printf 'exists\t%d\nskipped\t%d\n' "$NEXIST" "$NSKIP"
[ "$NFAIL" -eq 0 ] || printf 'failed\t%d\n' "$NFAIL"

# --------------------------------------------------------------------- needs
# A need belongs to a file this run creates (its placeholders are in it), or
# is a check of the project that no file of ours can satisfy.
made() { case "$CREATED_LIST" in *"|$1|"*) return 0 ;; esac; return 1; }
need() { printf 'NEEDS\t%s\t%s\t%s\n' "$1" "$2" "$3"; }
if made "$README" && [ -z "$VER" ]; then
  need engine_version "$README" "set the engine version on the Engine line (project.yaml has no engine.version)"
fi
case "$ENG" in
  godot)
    if made "$CI" && [ "$GODOTVER" != "$VER" ]; then
      need godot_version "$CI" "replace [FULL GODOT VERSION, e.g. 4.7.2] with the full release (godot --version)"
    fi
    if [ ! -f addons/gdUnit4/bin/GdUnitCmdTool.gd ]; then
      need gdunit4 addons/gdUnit4/bin/GdUnitCmdTool.gd "install GdUnit4 (Asset Store, AssetLib before Godot 4.7, then enable the plugin); the folder has a capital U"
    fi ;;
  unity)
    if [ ! -f Packages/manifest.json ] || ! grep -q 'com.unity.test-framework' Packages/manifest.json; then
      need unity_test_framework Packages/manifest.json 'add "com.unity.test-framework" to dependencies at the version your editor bundles'
    fi
    if made "$CI"; then
      need unity_license "$CI" "add the UNITY_LICENSE secret to the repository (manual)"
    fi
    if made Assets/Tests/EditMode/EditModeTests.asmdef || made Assets/Tests/PlayMode/PlayModeTests.asmdef; then
      # The test assemblies see only other .asmdef files; any outside Assets/Tests is the game's.
      if [ -z "$(find Assets -name '*.asmdef' -not -path 'Assets/Tests/*' 2>/dev/null | head -1)" ]; then
        need game_asmdef Assets/Tests "the test assemblies see only other .asmdef files: with none for the game scripts, ask before adding one and list it in both test assemblies' references"
      fi
    fi ;;
  unreal)
    if made "$UNREAL_README"; then
      need test_root "$UNREAL_README" "$DOCPROJ. is the test root of commands.test: confirm it is the project name, or the distinct root /setup-engine chose"
    fi
    if made "$CI" && [ -z "$PROJ_NAME" ]; then
      need project_name "$CI" "replace [ProjectName] with the project name (the .uproject name)"
    fi
    if made "$CI"; then
      need ue_root "$CI" "set UE_ROOT on the self-hosted Windows runner"
    fi ;;
  web)
    if [ ! -f package.json ]; then
      need package_json package.json "no package.json: /setup-engine web makes the project first"
    else
      for _pk in vitest @playwright/test; do
        grep -q "\"$_pk\"" package.json || need "$_pk" package.json "add $_pk at the version docs/engine-reference/web/VERSION.md pins"
      done
      [ -d node_modules ] || need npm_install node_modules "npm ci (it runs third-party install scripts and needs the network: ask first)"
    fi ;;
esac

[ "$NFAIL" -eq 0 ] || exit 4
[ "$NSKIP" -eq 0 ] || exit 3
exit 0
