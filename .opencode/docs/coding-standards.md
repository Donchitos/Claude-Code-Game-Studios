# Coding Standards (OpenCode)

The standards below are the OpenCode counterpart of
`.claude/docs/coding-standards.md`. They are loaded with `AGENTS.md` through the
`instructions` list in `opencode.jsonc`.

- All game code must include doc comments on public APIs.
- Architecture decisions are recorded as ADRs in `docs/architecture/`. **How many
  are required is set by `modes.workflow`** — all ADRs at `full`, critical ADRs
  only at `standard`, and none required at `minimal`, where the decision log and
  `design/game-brief.md` carry the rationale instead. See
  `.claude/docs/workflow-modes.md`.
- Gameplay values must be data-driven (external config), never hardcoded.
- All public methods must be unit-testable (dependency injection over singletons).
- Commits must reference the relevant design document or task ID.
- **Commit messages**: use Conventional Commits — `feat:`, `fix:`, `chore:`,
  `docs:`, `test:`, `refactor:`. Reference the story or task ID in the body
  (for example `Story: EPIC-001-S02`).
- **Verification-driven development**: write tests first when adding gameplay
  systems. For UI changes, verify with screenshots. Compare expected output with
  actual output before marking work complete.
- **A parse check is not a run.** Every story that changes something
  player-observable is launched and observed before it closes, and the
  observation is a retained screenshot in `production/qa/evidence/`. Procedure
  per engine: `.claude/docs/run-and-observe.md`. Not waived at `qa.level:
  minimal` — tests are, the look is not.

## Design Document Standards

- All design docs use Markdown.
- Each mechanic has a dedicated document in `design/gdd/`.
- **How many of the 8 sections are required depends on `modes.workflow`** — all
  8 at `full`, 5 (plus Formulas when the system defines numeric rules) at
  `standard`, and no GDD at all at `minimal`, where `design/game-brief.md` is
  the design record. See `.claude/docs/workflow-modes.md`.
  1. Overview
  2. Player Fantasy
  3. Detailed Rules
  4. Formulas
  5. Edge Cases
  6. Dependencies
  7. Tuning Knobs
  8. Acceptance Criteria
- Balance values must link to their source formula or rationale.

## Testing Standards

All stories need appropriate evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Default Gate |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| **Integration** (multi-system) | Integration test or documented playtest | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel** (animation, VFX, feel) | Retained screenshot + lead sign-off | `production/qa/evidence/` | BLOCKING |
| **UI** (menus, HUD, screens) | Retained screenshot of each screen | `production/qa/evidence/` | BLOCKING |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

The **Default Gate** applies when `testing.strict` is not set in `project.yaml`.
A project may override it per test type with `testing.strict.logic`,
`.integration`, `.visual`, `.ui`, and `.config`.

## Tool Posture

The generated OpenCode agents enforce their Claude-side tool posture with
permissions. Read-only agents cannot edit files; agents without Bash cannot run
shell commands. The safety plugin still blocks the critical commit, push, read,
and write cases. See `.opencode/docs/permissions.md`.
