# Skill Test Spec: /test-helpers

## Skill Summary

`/test-helpers [system-name | all | scaffold]` generates test helper files in
the engine's **helper root** — the only place its test runner compiles them:
`tests/helpers/` on Godot, `Assets/Tests/EditMode/Helpers/` on Unity (inside the
`EditModeTests` assembly), `Source/<Module>/Private/Tests/Helpers/` on Unreal. It
writes base assertion and factory helpers (`scaffold`), and a
`[helper root]/[system]_factory.[ext]` per system built from that system's GDD
(`[system-name]` or `all`). No argument runs `scaffold` when no helpers exist,
else `all`. It reads `engine.name`, `engine.language` and `testing.framework`
from `project.yaml` (falling back to `technical-preferences.md`), samples up to
5 existing test files for house style, and section-greps the GDD (Formulas,
Edge Cases, Detailed Rules/Design) rather than reading it whole.

Helpers must assert through the configured framework's API — never bare
`assert()` — and must not extend the framework's test-suite base class. If the
framework's assertion API cannot be confirmed, the skill says so and generates
no helper. It never overwrites an existing helper: it skips it with a message.
After presenting the file list it asks "May I write these helper files to
`[helper root]`?". No director gates apply. Verdict: COMPLETE when helper files
are created.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing helpers
- [ ] Has a next-step handoff (Next Steps: `/test-setup`, `/dev-story`, `/skill-test`)

---

## Director Gate Checks

None. `/test-helpers` is a scaffolding utility. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Player helper generated for Godot/GDScript

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `engine.language: GDScript`,
  `testing.framework: gdUnit4`; `addons/gdUnit4/` is installed, so its
  assertion API can be confirmed from the project
- `tests/unit/player/player_movement_test.gd` exists
- `design/gdd/player.md` has a Formulas section bounding health to 0–100
- No existing files in `tests/helpers/`; the user approves the write

**Input:** `/test-helpers player`

**Expected behavior:**
1. Skill reads engine, language and framework; samples the existing test file
2. Skill greps `design/gdd/player.md` for the Formulas / Edge Cases / Detailed
   Rules headings instead of reading it whole
3. Skill drafts `tests/helpers/player_factory.gd`: a `class_name` helper that
   `extends RefCounted`, static `make_*` factories with default parameters,
   bound constants commented as coming from the GDD, and a header line
   "Based on: design/gdd/player.md"
4. Every assertion goes through gdUnit4's confirmed API — no bare `assert()`,
   no `FAIL_IF` placeholder
5. Skill presents the file list and asks "May I write these helper files to `tests/helpers/`?"
6. Files written on approval; verdict COMPLETE, followed by the per-engine usage note

**Assertions:**
- [ ] Generated helper is GDScript at `tests/helpers/player_factory.gd`
- [ ] Bound constants trace to the GDD's Formulas section (not invented values)
- [ ] Helper extends `RefCounted`, not the test-suite base class, and uses no Autoload/singleton
- [ ] No bare `assert()` and no unresolved `FAIL_IF` reaches the file
- [ ] Verdict is COMPLETE

---

### Case 2: Engine Not Configured — Stops with /setup-engine

**Fixture:**
- `project.yaml` has no `engine` block; `technical-preferences.md` shows
  `[TO BE CONFIGURED]` for Engine

**Input:** `/test-helpers player`

**Expected behavior:**
1. Skill checks `project.yaml`, then `technical-preferences.md` — no engine in either
2. Skill outputs: "Engine not configured. Run `/setup-engine` first."
3. Skill stops — no test scan, no draft, no write

**Assertions:**
- [ ] The message states the engine is not configured
- [ ] `/setup-engine` is named as the prerequisite
- [ ] No write tool is called
- [ ] Verdict is not COMPLETE (nothing was created)

---

### Case 3: Helper Already Exists — Skipped, never overwritten

**Fixture:**
- Godot/GDScript/gdUnit4 configured as in Case 1
- `tests/helpers/game_assertions.gd` already exists with hand-written additions
- `tests/helpers/game_factory.gd` and `tests/helpers/scene_runner_helper.gd` do
  not exist; the user approves the write

**Input:** `/test-helpers scaffold`

**Expected behavior:**
1. Skill drafts the Godot base helpers only — `game_assertions.gd`,
   `game_factory.gd` and `scene_runner_helper.gd`; no system-specific helpers in
   `scaffold` mode
2. Skill asks "May I write these helper files to `tests/helpers/`?"
3. The two missing files, `tests/helpers/game_factory.gd` and
   `tests/helpers/scene_runner_helper.gd`, are created
4. For the existing file, skill reports: "Skipping `tests/helpers/game_assertions.gd`
   — already exists. Remove the file manually if you want it regenerated."
5. Verdict COMPLETE

**Assertions:**
- [ ] `scaffold` mode generates no `[system]_factory` helper
- [ ] The existing `game_assertions.gd` is left byte-for-byte unchanged
- [ ] The skip message names the existing file and how to regenerate it
- [ ] Only the two missing files are written; Verdict is COMPLETE

---

### Case 4: Framework Assertion API Unconfirmed — No helper generated

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `engine.language: GDScript`;
  `testing.framework` is absent and `technical-preferences.md` shows no Framework
- No `addons/gdUnit4/` and no existing test files to learn the API from

**Input:** `/test-helpers scaffold`

**Expected behavior:**
1. Skill cannot confirm which assertion call registers a failure with the runner
2. Skill says so, and generates no helper rather than guessing a form such as
   `assert_that`, `assert_eq`, `assert_true` or a bare `assert()`
3. No "May I write" is asked and nothing is written

**Assertions:**
- [ ] The skill states it cannot confirm the framework's assertion API
- [ ] No helper file is written
- [ ] No guessed assertion form (and no `FAIL_IF` placeholder) is presented as ready to write
- [ ] Verdict is not COMPLETE

---

### Case 5: Director Gate Check — No gate; test-helpers is a scaffolding utility

**Fixture:**
- Engine and framework configured as in Case 1, no existing helpers

**Input:** `/test-helpers player`

**Expected behavior:**
1. Skill generates and writes the helper file
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

### Case 6: Unity — Helpers under the engine's test root

**Fixture:**
- `project.yaml` has `engine.name: Unity`, `engine.language: C#`,
  `testing.framework: NUnit`; `com.unity.test-framework` is in
  `Packages/manifest.json`, so NUnit's assertion API can be confirmed from the
  installed package
- `/test-setup` has created `Assets/Tests/EditMode/EditModeTests.asmdef`
- No helpers exist yet; the user approves the write

**Input:** `/test-helpers scaffold`

**Expected behavior:**
1. The helper root is `Assets/Tests/EditMode/Helpers/` — inside the
   `EditModeTests` assembly, where Unity compiles it
2. Skill drafts `GameAssertions.cs` and `GameFactory.cs` for that folder,
   asserting through NUnit's `Assert`
3. Skill asks "May I write these helper files to `Assets/Tests/EditMode/Helpers/`?"
4. Files written on approval; the usage note says to reference the test assembly;
   verdict COMPLETE

**Assertions:**
- [ ] Helpers are written under `Assets/Tests/EditMode/Helpers/`
- [ ] Nothing is written under `tests/helpers/` — outside `Assets/`, Unity never compiles it
- [ ] The "May I write" ask names the Unity helper root
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Reads engine, language and test framework before generating any helper
- [ ] Writes helpers only to the engine's helper root (`tests/helpers/`, `Assets/Tests/EditMode/Helpers/` or `Source/<Module>/Private/Tests/Helpers/`)
- [ ] Section-greps the GDD for system helpers (numbered headings such as `## 4. Formulas` included); constants trace to its Formulas section
- [ ] Godot signal asserts keep their flag in a Dictionary the lambda mutates and connect a variadic lambda (`func(...args)`) — a captured `bool` never changes in the caller, and a one-argument lambda fails on any other signal
- [ ] Asserts only through the configured framework — never bare `assert()` — and generates nothing when that API cannot be confirmed
- [ ] Helpers never extend the framework's test-suite base class
- [ ] Never overwrites an existing helper; reports the skip instead
- [ ] Asks "May I write" before any file is created
- [ ] Verdict is COMPLETE when helper files are written

---

## Coverage Notes

- `all` mode (one factory per system with test files) follows Case 1 per system;
  not separately tested.
- Unreal helper generation (`Source/<Module>/Private/Tests/Helpers/`) follows
  Case 6's pattern for its own helper root; not separately tested. Nor is a
  Unity project whose PlayMode tests need the helpers too (the skill asks before
  creating a shared `TestHelpers.asmdef`).
- A requested system with no GDD is not tested; the skill does not define that path.
