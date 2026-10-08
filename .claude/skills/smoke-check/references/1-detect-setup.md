# /smoke-check — Phase 1: Detect Test Setup

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

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
