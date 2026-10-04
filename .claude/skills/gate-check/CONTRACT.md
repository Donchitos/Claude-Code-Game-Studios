# /gate-check — Handoff Contract

## Role in Pipeline
Validates whether the project is ready to advance from one development phase to the next by auditing required artifacts and quality checks, producing a PASS / NOT ASSESSED / CONCERNS / FAIL verdict (NOT ASSESSED outranks PASS — a gate that could not check part of its scope has not established readiness; see SKILL.md's verdict section for the precedence order), and — on PASS with user confirmation, or on CONCERNS when the user explicitly accepts the listed risks — writing the new stage name to `project.stage` in `project.yaml` (and legacy `production/stage.txt` for backward compatibility).

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `project.yaml` (`project.stage`, fallback `production/stage.txt`) | Stage name (used when no argument provided, to auto-detect current stage) | Yes |
| `project.yaml` (`modes.workflow`, which follows `modes.rigor` — `minimal` by default; `workflow_overrides.system_overrides.*`, `workflow_overrides.art_bible_strict`) | Workflow tier — selects the per-gate artifact checklist (Section 2b); per-system overrides resolved when validating MVP GDDs | Yes |
| `docs/engine-reference/[engine]/VERSION.md` | Engine version, post-cutoff risk levels (read during engine validation checks) | Yes |
| `.claude/docs/technical-preferences.md` | Legacy fallback for `engine.*`, `naming.*` and `performance.*` when those keys are absent or empty in `project.yaml`; sole source for forbidden patterns (never migrated). Referenced in quality checks | Yes — required only for keys absent from `project.yaml` |
| `docs/consistency-failures.md` | Domain-tagged entries surfaced as increased-scrutiny context (read if exists; skip if absent) | Yes |

### Phase-specific inputs (subset read depending on target gate)
| Target Gate | Key Files Checked |
|-------------|------------------|
| Concept → Systems Design | `design/gdd/game-concept.md`; pillars either inside it **or** in an optional `design/gdd/game-pillars.md` — at the `minimal` tier, `design/game-brief.md` instead (pillars check drops) |
| Systems Design → Technical Setup | `design/gdd/systems-index.md`, all MVP GDDs in `design/gdd/`, cross-GDD review report |
| Technical Setup → Pre-Production | `docs/architecture/` ADRs (≥3), `docs/engine-reference/[engine]/deprecated-apis.md`, `docs/architecture/architecture.md`, `docs/architecture/requirements-traceability.md`, `design/accessibility-requirements.md`, `design/ux/interaction-patterns.md` |
| Pre-Production → Production | `production/sprints/` (first sprint plan), `docs/architecture/control-manifest.md`, `production/epics/` (Foundation + Core layer epics), `design/ux/hud.md`, `design/ux/` key screen specs; recommended, not blocking: `prototypes/*-vertical-slice/REPORT.md` and its playtest in `production/qa/playtests/` — at the `minimal` tier, only a filled `design/game-brief.md` with its build order and stories under `production/epics/` (no sprint plan; the rest drops, the Vertical Slice items included — two checks on the current build replace them: the core loop is fun, and it runs end to end) |
| Production → Polish | code-root subsystems (resolve per `.claude/docs/code-root-resolution.md`), the engine's test root — `tests/unit/` + `tests/integration/` (Godot), `Assets/Tests/` (Unity), `Source/<Module>/Private/Tests/` (Unreal) — with all Logic stories covered, `production/qa/smoke-*.md` (PASS or PASS WITH WARNINGS), `production/qa/playtests/` (≥3 sessions) |
| Polish → Release | Full story test evidence for all Must Have stories, QA sign-off report, localization check, `production/qa/` QA plan, release checklist output, changelog, the newest full-scope `production/security/security-audit-*.md` (plus any later `quick` re-run) |

### Preconditions
- The target phase argument must be one of: `systems-design`, `technical-setup`, `pre-production`, `production`, `polish`, `release`; if omitted, auto-detects from `project.stage` in `project.yaml` (fallback `production/stage.txt`) and validates the next transition
- The skill does not require any prior skill to have run in the same session, but it will surface missing prerequisites (e.g., missing ADRs, missing playtest reports) as blockers in the verdict

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/gate-checks/gate-[phase]-[date].md` (or path chosen by user) | Full checklist with per-item status, Blockers list, Recommendations, Verdict, Chain-of-Verification note | written only after user approves ("May I write this gate check report to production/gate-checks/?") |
| `project.yaml` (`project.stage`) + legacy `production/stage.txt` | New stage name (dual-write for backward compat) | written ONLY when the verdict is PASS and the user explicitly confirms, or the verdict is CONCERNS and the user explicitly accepts the listed risks; never written on FAIL or NOT ASSESSED |

### Output Guarantees
- The gate report always contains: artifact checklist (with file sizes or "MISSING"), quality check results, list of blockers (empty if PASS), recommendations, and the Chain-of-Verification note — plus an `### Accepted Risks` section (each concern, accepted by the user, dated) when the user advanced on CONCERNS
- `project.stage` (and legacy `production/stage.txt`) is updated to the new stage name only on a confirmed PASS, or on CONCERNS after the user explicitly accepts the risks — never speculatively
- Any item that cannot be automatically verified is marked `MANUAL CHECK NEEDED` and the user is asked before the verdict is finalized

## Immutability Rules
- READS but does NOT modify: all GDDs in `design/gdd/`, all ADRs in `docs/architecture/`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `.claude/docs/technical-preferences.md` (legacy fallback), `docs/engine-reference/[engine]/VERSION.md`, `docs/engine-reference/[engine]/deprecated-apis.md`, all story files in `production/epics/`, all sprint files in `production/sprints/`, all playtest files in `production/qa/playtests/`, source files in the code root (Grep only), test files under the engine's test root (run via Bash)
- MODIFIES: `project.yaml` (`project.stage` only) + legacy `production/stage.txt` (both on a confirmed PASS or an accepted CONCERNS override only), `production/gate-checks/[report].md` (new file, with user approval)
- Does NOT modify story files, ADRs, GDDs, or any source/test code

## Hard Constraints (Never Violate)
- Never writes stage (either `project.yaml` `project.stage` or legacy `production/stage.txt`) unless the verdict is PASS and the user has explicitly confirmed advancement, or the verdict is CONCERNS and the user has explicitly accepted every listed risk (recorded in the report's `### Accepted Risks`)
- Never writes stage on a FAIL or NOT ASSESSED verdict under any circumstances — no override turns either into a stage change
- Never auto-advances stage — even a PASS verdict requires explicit user confirmation before the file is written
- Never assumes PASS for items that cannot be automatically verified — always marks them `MANUAL CHECK NEEDED` and asks the user
- Never blocks the user from working — the verdict decides only whether the stage is written; a CONCERNS override records the accepted risks in the gate report
- Never passes a director "none" for an artifact the target gate does not require yet — that is "not expected before [phase]" (or "not required at `workflow: [tier]`"), and not a finding; "none" is reserved for an artifact the gate asks for that does not exist
- Always runs Chain-of-Verification (5 challenge questions) after drafting the verdict before finalizing it
- If any Vertical Slice Validation item is NO at the Pre-Production → Production gate, the verdict is automatically FAIL regardless of all other checks, at `full` and `standard`; at `minimal`, where the slice items drop, a "no" to either current-build check (the core loop is fun, it runs end to end) is FAIL the same way (tier reductions relax what must *exist*, never make a broken build passable)
- Workflow-tier reductions (Section 2b) only ever *relax* a requirement (Required → CONCERNS-if-absent, or drop); they never add one. The sole exception that adds is `workflow_overrides`: a system pinned via `system_overrides` to a higher tier than the project blocks the gate until that one system's GDD meets the higher section count, and `art_bible_strict: true` forces the complete art bible regardless of tier
- gate-check honors `modes.workflow` but is exempt from `modes.automation` — the collaborative prompting protocol (the Collaborative Protocol section) always applies; a phase gate is never auto-run

## Downstream Skill Expects
**Next skill (on PASS):** varies by gate

| Gate Passed | Enabled downstream skill |
|-------------|-------------------------|
| Concept → Systems Design | `/map-systems` — or `/design-system` for the first system when `design/gdd/systems-index.md` already exists |
| Systems Design → Technical Setup | `/create-architecture` first — the master architecture and the ADR work plan (it needs an engine, so `/setup-engine` if none is configured) — then `/architecture-decision` |
| Technical Setup → Pre-Production | `/create-control-manifest` if `docs/architecture/control-manifest.md` does not exist yet, then `/vertical-slice`; `/create-epics` and `/create-stories` once the slice has validated the core loop |
| Pre-Production → Production | `/dev-story`, `/sprint-plan`, `/story-readiness` |
| Production → Polish | `/perf-profile`, `/playtest-report`, `/smoke-check` |
| Polish → Release | `/launch-checklist`, `/team-release` (the release checklist, changelog and security audit are done before this gate) |

- Downstream skills read `project.stage` from `project.yaml` (fallback `production/stage.txt`) to confirm their phase is active before proceeding
- `/create-epics` reads `docs/architecture/control-manifest.md` — required at `full`, read if present at `standard` — and the Pre-Production → Production gate checks it

## Known Fragile Points
- `project.stage` in `project.yaml` (with legacy `production/stage.txt` as fallback) is the authoritative stage indicator — if either is manually edited to a wrong value outside of `/gate-check`, auto-detection in future sessions will be incorrect; never edit them outside `/gate-check`'s stage write
- The Production → Polish gate runs the test suite via Bash. If the test runner command is not configured or fails to start (e.g. gdUnit4 is not installed at `addons/gdUnit4/`), the test check now yields `NOT ASSESSED`, which outranks PASS — so the gate cannot advance a stage on the strength of a suite that never ran. Without the `NOT ASSESSED` branch this masks silent test regressions: Section 3 runs the suite "if a test runner is configured", and with no else an unconfigured runner simply contributes nothing to the verdict
- The Pre-Production → Production gate has a hard Vertical Slice validation block; any subjective checklist item (e.g., "core mechanic feels good") requires a user response via `AskUserQuestion` — if the user answers without playing the build, a false PASS is possible
- Gate report files in `production/gate-checks/` are not validated for completeness by any downstream skill; a partial report written due to a session interruption will look identical to a complete one
- `docs/consistency-failures.md` is optional context that adjusts scrutiny but does not change the formal checklist; if this file exists but is stale, the increased-scrutiny signals may point at resolved issues
