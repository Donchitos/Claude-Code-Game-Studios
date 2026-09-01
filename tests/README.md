# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: GdUnit4
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-08-21

> **Nota de framework**: el proyecto usa **GdUnit4** (MikeSchulze), consistente con el
> comando de CI de `.claude/docs/coding-standards.md` (`godot --headless --script
> tests/gdunit4_runner.gd`). Si `.claude/docs/technical-preferences.md` aún dice
> "GUT (Godot Unit Test)", es una entrada stale — debe decir GdUnit4.

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
  evidence/       # Screenshot logs and manual test sign-off records
```

## Installing GdUnit4

```
1. Open Godot → AssetLib → search "GdUnit4" → Download & Install
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: res://addons/gdunit4/ exists
```

## Running Tests

Headless (CI and `/smoke-check`):

```
godot --headless --script tests/gdunit4_runner.gd
```

In-editor: open the GdUnit4 dock (bottom panel) and run a test suite or the whole
`tests/` tree.

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[scenario]_[expected]`
- **Example**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Determinism & Isolation (project testing-standards)

- No random seeds, no time-dependent assertions — same result every run.
- Each test sets up and tears down its own state; no cross-test ordering.
- No file I/O, DB, or external APIs in unit tests — use dependency injection.
- Float comparisons use a tolerance (`assert_almost_eq` / `±0.0001`), never `==`
  (Temporizador AC-T11, Forja EPSILON_TIER, etc.).
- Injectable seeded `RandomNumberGenerator` for any RNG (Kaiju AC-K71, Reliquias
  AC-RB18); never global `randf`/`randi`.

## Story Type → Test Evidence

| Story Type | Required Evidence | Location | Gate |
|---|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` | BLOCKING |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` | ADVISORY |
| UI | Manual walkthrough OR interaction test | `tests/evidence/` | ADVISORY |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` | ADVISORY |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging (testing-standards: never skip/disable a
failing test to make CI pass — fix the underlying issue).
