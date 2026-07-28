# Test Infrastructure

**Engine**: Godot 4.7-stable
**Test Framework**: GdUnit4 v6.1.3 (installed at `neues-spiel/addons/gdUnit4/`)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-07-11 (verified green the same day: 3/3 example tests pass headless)

## Directory Layout

Engine-executed tests live **inside the Godot project** (`neues-spiel/`) so the
engine can load them via `res://`. Process artifacts (smoke checklists, manual
evidence) live here in the repo-root `tests/` directory.

```
neues-spiel/tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests

tests/            # (this directory — process docs, not engine code)
  run-tests.cmd   # Local headless test runner (Windows)
  smoke/          # Critical path test list for /smoke-check gate
  evidence/       # Screenshot logs and manual test sign-off records
```

## Running Tests

Locally (Windows):

```
tests\run-tests.cmd
```

Or directly (any platform; requires `--ignoreHeadlessMode` because GdUnit4
refuses plain headless runs to warn about InputEvent-based tests):

```
godot --headless --path neues-spiel -s -d --remote-debug tcp://127.0.0.1:0 \
  res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode \
  -a res://tests/unit -a res://tests/integration
```

Reports are written to `neues-spiel/reports/` (gitignored).

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[scenario]_[expected]`
- **Suites**: `extends GdUnitTestSuite`, static typing enforced
- **Example**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `neues-spiel/tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `neues-spiel/tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` |
| UI | Manual walkthrough OR interaction test | `tests/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request via
`godot-gdunit-labs/gdUnit4-action` (the action repo moved from MikeSchulze —
the workflow references the new org). A failed test suite blocks merging.

Note: the repo-root `.gitignore` has a global `bin/` rule; an explicit
`!neues-spiel/addons/gdUnit4/bin/` exception keeps the GdUnit4 command-line
runner in git so CI can use it. Do not remove that exception.
