---
name: test-setup
description: "Scaffold the test framework and CI — tests/ directory, engine test runner, GitHub Actions workflow. Once, before the first sprint."
argument-hint: "[force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

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
   - Glob `tests/gdunit4_runner.gd` (Godot) or `tests/EditMode/` (Unity) or
     `Source/Tests/` (Unreal) for engine-specific artifacts.

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
  unit/           — Isolated unit tests for formulas, state, and logic
  integration/    — Cross-system tests and save/load round-trips
  smoke/          — Critical path test list (15-minute manual gate)
  README.md       — Test framework documentation

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

```markdown
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

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`.** That is
> where every consumer reads it — `/smoke-check`, `/test-evidence-review`,
> `/qa-plan`, and the evidence table in `.claude/docs/coding-standards.md`. This
> scaffold and this skill's completion summary must name the same path: listing
> `tests/evidence/` here while the summary reports `production/qa/evidence/`
> creates a directory nothing reads and skips the one everything does.

## Running Tests

[Engine-specific command — see below]

## Test Naming

- **Files**: `[system]_[feature]_test.[ext]`
- **Functions**: `test_[scenario]_[expected]`
- **Example**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Manual walkthrough OR interaction test | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
```
```

### Engine-specific files

#### Godot 4 (`Engine: Godot`)

Create `tests/gdunit4_runner.gd`:

```gdscript
# GdUnit4 test runner — invoked by CI and /smoke-check
# Usage: godot --headless --script tests/gdunit4_runner.gd
extends SceneTree

func _init() -> void:
    var runner := load("res://addons/gdunit4/GdUnitRunner.gd")
    if runner == null:
        push_error("GdUnit4 not found. Install via AssetLib or addons/.")
        quit(1)
        return
    var instance = runner.new()
    instance.run_tests()
    quit(0)
```

Create `tests/unit/.gdignore_placeholder` with content:
`# Unit tests go here — one subdirectory per system (e.g., tests/unit/combat/)`

Create `tests/integration/.gdignore_placeholder` with content:
`# Integration tests go here — one subdirectory per system`

Note in the README: **Installing GdUnit4**
```
1. Open Godot → AssetLib → search "GdUnit4" → Download & Install
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: res://addons/gdunit4/ exists
```

#### Unity (`Engine: Unity`)

Create `tests/EditMode/` placeholder file `tests/EditMode/README.md`:
```markdown
# Edit Mode Tests
Unit tests that run without entering Play Mode.
Use for pure logic: formulas, state machines, data validation.
Assembly definition required: `tests/EditMode/EditModeTests.asmdef`
```

Create `tests/PlayMode/README.md`:
```markdown
# Play Mode Tests
Integration tests that run in a real game scene.
Use for cross-system interactions, physics, and coroutines.
Assembly definition required: `tests/PlayMode/PlayModeTests.asmdef`
```

Note in the README: **Enabling Unity Test Framework**
```
Window → General → Test Runner
(Unity Test Framework is included by default in Unity 2019+)
```

#### Unreal Engine (`Engine: Unreal` or `Engine: UE5`)

Create `Source/Tests/README.md`:
```markdown
# Unreal Automation Tests
Tests use the UE Automation Testing Framework.
Run via: Session Frontend → Automation → select "MyGame." tests
Or headlessly: UnrealEditor -nullrhi -ExecCmds="Automation RunTests MyGame.; Quit"

Test class naming: F[SystemName]Test
Test category naming: "MyGame.[System].[Feature]"
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

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Run GdUnit4 Tests
        uses: MikeSchulze/gdUnit4-action@v1
        with:
          godot-version: '[VERSION FROM docs/engine-reference/godot/VERSION.md]'
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
    runs-on: self-hosted  # UE requires a local runner with the editor installed

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Run Automation Tests
        run: |
          "$UE_EDITOR_PATH" "${{ github.workspace }}/[ProjectName].uproject" \
            -nullrhi -nosound \
            -ExecCmds="Automation RunTests MyGame.; Quit" \
            -log -unattended
        shell: bash

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-logs
          path: Saved/Logs/
```

Note: UE CI requires a self-hosted runner with Unreal Editor installed.
Set the `UE_EDITOR_PATH` environment variable on the runner.

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
- tests/unit/ (directory)
- tests/integration/ (directory)
- tests/smoke/critical-paths.md
- production/qa/evidence/ (directory)
[engine-specific files]
- .github/workflows/tests.yml

Next steps:
1. [Engine-specific install step, e.g., "Install GdUnit4 via AssetLib"]
2. Write your first test: create tests/unit/[first-system]/[system]_test.[ext]
3. Run `/qa-plan sprint` before your first sprint to classify stories and set
   test evidence requirements
4. `/smoke-check` before every QA hand-off

Gate note: /gate-check Technical Setup → Pre-Production now requires:
- tests/ directory with unit/ and integration/ subdirectories
- .github/workflows/tests.yml
- At least one example test file
Run /test-setup and write one example test before advancing.

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
