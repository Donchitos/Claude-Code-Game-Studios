# Test Infrastructure

**Engine**: Flutter 3.44.4 / Flame 1.37.0 (Dart 3.12.2)
**Test Framework**: `flutter_test` (unit + widget), `flame_test` (Flame component tests)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-07-08

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, pure logic)
  integration/    # Cross-system + Firestore-emulator + flame_test component tests
  smoke/          # Critical-path list for the /smoke-check gate
  evidence/       # Screenshots + manual test sign-off records
```

> **Note on directory name**: this project uses `tests/` (plural, per
> `.claude/docs/directory-structure.md` and `coding-standards.md`), NOT Flutter's
> default `test/`. `flutter test` takes an explicit path, so tests are run with
> `flutter test tests/` (see below). When the Flutter package is scaffolded, keep
> the package's `pubspec.yaml` `dev_dependencies` (`flutter_test`, `flame_test`,
> `mocktail`/`fake_cloud_firestore`) but point the runner at `tests/`.

## Running Tests

```bash
flutter pub get
flutter analyze
flutter test tests/                 # all tests
flutter test tests/unit/            # unit only
flutter test tests/ --coverage      # with coverage → coverage/lcov.info
```

> ⚠️ Requires the Flutter package (`pubspec.yaml` with `flutter_test`/`flame_test`
> in `dev_dependencies`) to exist. As of setup the game package is not yet
> scaffolded — CI activates once it is (see the workflow's `working-directory` note).

## Test Naming (per `coding-standards.md`)

- **Files**: `[system]_[feature]_test.dart`
- **Functions/blocks**: `test('[scenario] [expected]', ...)` inside `group('[System]', ...)`
- **Example**: `pet_state_machine_mood_test.dart` →
  `group('PetStateMachine', () { test('energy 80 maps to HAPPY', ...); })`

## Story Type → Test Evidence (per `coding-standards.md`)

| Story Type | Required Evidence | Location | Gate |
|---|---|---|---|
| Logic (formulas, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| Integration (multi-system, save/load) | Integration test OR playtest doc | `tests/integration/[system]/` | BLOCKING |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` | ADVISORY |
| UI | Manual walkthrough OR interaction test | `tests/evidence/` | ADVISORY |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` | ADVISORY |

## Coverage Target

`technical-preferences.md`: **70% minimum** for game logic and economy systems.
Required-test systems: balance formulas, task reward calculations, economy
(Currency/Shop), pet state machine. These map to accepted ADRs — see the
Validation Criteria section of each ADR in `docs/architecture/`.

## Determinism Rules (per `coding-standards.md`)

- No random seeds, no wall-clock assertions — inject `now`/`Random` (see ADR-0005
  `computeEnergy(now:)` and ADR-0012-to-be Gacha RNG injectability).
- Each test sets up + tears down its own state; no order dependence.
- No live Firestore/network — use the Firebase emulator or `fake_cloud_firestore`.

## Recommended dev_dependencies (add to the Flutter package's pubspec.yaml)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flame_test: ^1.x           # Flame component test helpers (pin to the 1.37-compatible line)
  mocktail: ^1.x             # mocking (DI per coding-standards)
  fake_cloud_firestore: ^3.x # in-memory Firestore for unit tests (no live network)
```

## CI

Tests run automatically on every push to `main` and every PR
(`.github/workflows/tests.yml`). A failed suite blocks merging.
