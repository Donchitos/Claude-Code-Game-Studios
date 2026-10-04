# /story-done — Handoff Contract

## Role in Pipeline
Closes the implementation loop for a single story by verifying every acceptance criterion, checking test evidence, detecting GDD/ADR deviations, and — after user approval — updating the story file to `Status: Complete` with a `## Completion Notes` section.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/**/*.md` (the story file) | `Status:` (expected: `In Progress`, or `Ready` if `/dev-story` was skipped — `/dev-story` sets `In Progress`, and `/story-done` is the only skill that closes a story it verified — `/dev-story`'s dependency option `[C]` also sets `Complete`, on a dependency the user says is done, after an ask), `Type:`, `Manifest Version`, TR-ID(s), ADR reference(s), `## Acceptance Criteria`, list of files to create/modify, `## Test Evidence` path | No — status and completion notes written after approval |
| `docs/architecture/tr-registry.yaml` | Entry per TR-ID with current `requirement` text | Yes |
| GDD section referenced by each TR-ID | Acceptance criteria and key rules for cross-check | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (referenced ADR) | `## Decision`, `## Consequences` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header date, forbidden patterns | Yes (existence checked; absent = skip staleness check) |
| `production/session-state/active.md` | Active story path (used when no argument given) | No — `<!-- CHECKPOINT -->` block overwritten |

> **Tier.** The TR registry, GDD-section and ADR rows are `standard`/`full` inputs.
> At `workflow: minimal` the story traces to the brief, and Phase 4 runs the
> acceptance-criteria check only (no GDD/ADR traceability); the manifest,
> hardcoded-value and scope checks still run. At `qa.level: minimal` no test
> evidence is required (SKILL.md Phase 3) — but the Visual/UI run-and-observe
> screenshot is not waived.

### Test Evidence Files (presence checked, not pre-required to exist — absence triggers gate)
| Story Type | Expected Location |
|------------|------------------|
| Logic | `tests/unit/[system]/[story-slug]_test.[ext]` |
| Integration | `tests/integration/[system]/[story-slug]_test.[ext]` OR `production/session-logs/` playtest record |
| Visual/Feel | `production/qa/evidence/[story-slug]-evidence.md` + a retained screenshot |
| UI | A retained screenshot of each screen touched, under `production/qa/evidence/` — no evidence doc or sign-off required |
| Config/Data | `production/qa/smoke-*.md` |

### Preconditions
- The story file must be findable either by argument path, in `production/session-state/active.md`, or in the current sprint file as `IN PROGRESS`
- Implementation must have been attempted (source files listed in the story's "files to create/modify" should exist) — this skill does not implement; it verifies
- For Logic and Integration stories, the test file at the `## Test Evidence` path must **exist** before a COMPLETE verdict is possible — unless `testing.strict` in `project.yaml` sets that type to advisory (`testing.strict.logic`/`.integration: false`), in which case a missing test is recorded as a warning but does not block
- For Visual/Feel and UI stories, a retained screenshot must exist under `production/qa/evidence/` before a COMPLETE verdict is possible, and for Visual/Feel an evidence doc with every sign-off `[x] Approved` too (UI needs the screenshot only, as `coding-standards.md` says) — unless `testing.strict.visual`/`.ui` is set to `false`, in which case the gap is recorded as a warning but does not block
- **This skill does not execute the test.** Phase 3 checks existence with `Glob`; nothing runs. A test that exists and FAILS satisfies the gate, so a failing test cannot block a COMPLETE verdict here — this gate is existence, not "exist and pass". Pass/fail is established by `/gate-check` and `/smoke-check`, both of which run a suite and both of which come after story closure. See the note under Phase 3 of `SKILL.md`.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH NOTES` / `NOT ASSESSED` / `BLOCKED`.

`NOT ASSESSED` outranks `COMPLETE` — one or more acceptance criteria could not
be evaluated at all, which is not the same as evaluating them and finding them
met. Precedence is `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH NOTES`,
then `COMPLETE`; see the verdict section of `SKILL.md`. This contract listed no
verdict set at all, so a reader had nothing to branch on.

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/**/*.md` (the story file) | `Status: Complete`, `## Completion Notes` block (date, criteria count, deviations, test evidence path, code review status) | updated after explicit user approval |
| `production/sprint-status.yaml` | `status: done`, `completed: [date]`, top-level `updated` field | updated silently alongside story file if file exists |
| `docs/tech-debt-register.md` | Advisory deviation entries (if user confirms) | appended if advisory deviations exist and user agrees |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` block: current task (story path and verdict), next step (the next story), blocker, tech debt count | block overwritten, never appended (file created from `.claude/docs/templates/session-state.md` if absent) |

### Output Guarantees
- `Status: Complete` is written only after the user explicitly approves: on a COMPLETE or COMPLETE WITH NOTES verdict, or — on a BLOCKED or NOT ASSESSED verdict — only when the user explicitly asks to close anyway (the Phase 7 override, which always prompts as a `scope_changes` decision), with the override risk recorded in `## Completion Notes`
- `## Completion Notes` always contains: completion date, criteria pass count, deviation summary, test evidence path (or "None required"), code review status
- Session state always records the final verdict and the next recommended story path

## Immutability Rules
- READS but does NOT modify: `docs/architecture/tr-registry.yaml`, `docs/architecture/adr-NNNN-[slug].md` (Decision + Consequences only), GDD sections, `docs/architecture/control-manifest.md`, source files under the code root — `src/`, `Assets/` or `Source/` by engine (Grep only) — and test files under the engine's test root (existence checked with Glob; never run or edited)
- MODIFIES: the story `.md` file (status + completion notes), `production/sprint-status.yaml` (if exists), `production/session-state/active.md` (the `<!-- CHECKPOINT -->` block, overwritten), `docs/tech-debt-register.md` (append a row, and update its `Last updated:` and `Total items:` lines, only with user approval)
- Does NOT write to the code root or the test root under any circumstances

## Hard Constraints (Never Violate)
- Never sets `Status: Complete` without explicit user approval ("May I update the story file?")
- Never marks a Logic story Complete on a missing unit test when its resolved gate level is BLOCKING — the level is BLOCKING by default and whenever `testing.strict.logic` is `true`; it is ADVISORY only when `testing.strict.logic` is explicitly `false`
- Never marks an Integration story Complete on missing evidence (integration test file or playtest session log) when its resolved gate level is BLOCKING — BLOCKING by default and under `testing.strict.integration: true`; ADVISORY only under an explicit `false`
- Never marks a Visual/Feel or UI story Complete on a missing retained screenshot in `production/qa/evidence/` when its resolved gate level is BLOCKING — BLOCKING by default and under `testing.strict.visual`/`.ui: true`; ADVISORY only under an explicit `false`. A written description of a visual check is not a substitute for the image
- Never auto-fixes failing acceptance criteria — report failures and ask the user what to do
- Never proceeds to Phase 7 (file update) on its own when the verdict is BLOCKED or NOT ASSESSED — list blockers and offer help resolving them; Phase 7 is reached only on the user's explicit request to close anyway, and then always prompts (`scope_changes`), even in autonomous mode
- Never silently overrides a BLOCKED verdict — if the user insists on advancing despite blockers, document the override risk explicitly in `## Completion Notes`

## Downstream Skill Expects
**Next skill:** `/gate-check` (Production → Polish gate, or end-of-sprint review)
- It will read: story files in `production/epics/` checking `Status: Complete` and presence of `## Completion Notes`
- It will read: `tests/unit/` and `tests/integration/` for test file presence and will run the test suite via Bash
- It assumes: every Complete Logic story whose `testing.strict.logic` gate resolved to BLOCKING (the default) has a corresponding test file that **exists**; under an explicit `testing.strict.logic: false` a Logic story may be Complete with the test gap documented in `## Completion Notes`
  > **Existence, not passing.** `/story-done` checks that the test file exists with `Glob` and runs nothing, so a Complete Logic story may carry a test that fails. `/gate-check` running the suite is the FIRST point at which pass/fail is established, so it must never treat a Complete status as evidence the tests passed — it has to run them. That is also why an unconfigured test runner is `NOT ASSESSED` there rather than a silent skip: with no run, nothing upstream has verified the story either.
- It assumes: Visual/Feel and UI stories that are Complete have a retained screenshot in `production/qa/evidence/`, and Visual/Feel ones a signed-off evidence doc as well — that gate is BLOCKING by default; only under an explicit `testing.strict.visual`/`.ui: false` may such a story be Complete with the deviation documented in `## Completion Notes`
- It will read: `production/sprint-status.yaml` for `status: done` entries if that file exists

## Known Fragile Points
- The story's `## Test Evidence` section must contain the exact file path written by `/dev-story`; a path mismatch causes a false BLOCKING result even if the test file exists under a slightly different name
- If `Type:` is absent from the story header, test evidence gate enforcement is ADVISORY only — stories can slip through without tests
- Manifest version staleness check is skipped if `docs/architecture/control-manifest.md` does not exist; the check being skipped is noted in the report but is non-blocking
- `production/sprint-status.yaml` update is silent (no separate approval); if that file uses a different key structure than expected, the update silently fails and sprint tracking becomes stale
- The traceability table escalation rule (>50% UNTESTED = BLOCKING) can be triggered by deferred Visual/Feel criteria that are legitimately not automatable — ensure deferred criteria are explicitly marked `DEFERRED` (not left as unchecked) to avoid false escalation
