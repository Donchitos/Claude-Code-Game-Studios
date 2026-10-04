---
name: gate-check
description: "Ready to advance between development phases? PASS/CONCERNS/NOT ASSESSED/FAIL with blockers and required artifacts. 'Can we move to production?'"
argument-hint: "[target-phase: systems-design | technical-setup | pre-production | production | polish | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Phase Gate Validation

This skill validates whether the project is ready to advance to the next development
phase. It checks for required artifacts, quality standards, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

## Production Stages (7)

The project progresses through these stages:

1. **Concept** — Brainstorming, game concept document
2. **Systems Design** — Mapping systems, writing GDDs
3. **Technical Setup** — Engine config, architecture decisions
4. **Pre-Production** — Prototyping, vertical slice validation
5. **Production** — Feature development (Epic/Feature/Task tracking active)
6. **Polish** — Performance, playtesting, bug fixing
7. **Release** — Launch prep, certification

**When a gate passes** (or the user explicitly accepts a CONCERNS verdict's risks — Section 6), update the stage in both `project.yaml` (set `project.stage: <new-stage>`) AND write the new stage name to `production/stage.txt` (single line, e.g. `Production`). Dual-write keeps backward compatibility with hooks that haven't migrated yet. This updates the status line immediately.

---

## 1. Parse Arguments

**Target phase:** `$ARGUMENTS` with any `--review <mode>` pair removed (blank = auto-detect current stage, then validate next transition). `/gate-check --review full` names no phase.


Note: in `solo` mode, director spawns (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE) are skipped — gate-check becomes artifact-existence checks only. In `lean` mode, the phase-gate directors still run (phase gates are the purpose of lean mode); how many of them run is set by `workflow` below.

**`workflow`** (per `.claude/docs/workflow-modes.md`):

`gate-check` runs project-wide, so it uses the project-level `workflow` for the
gate's overall artifact checklist (the loaded gate file), AND consults
`workflow_overrides.system_overrides.<system>` per-system when validating MVP
GDDs — a system pinned to a higher tier must meet that tier's section count
before the gate passes, regardless of the project-level workflow (see Section 2b,
"Per-system overrides").

> **gate-check honors `workflow` but is exempt from `automation`.** The artifact
> checklist changes per tier; the collaborative prompting protocol (the
> Collaborative Protocol section) always applies — a phase gate is a deliberate
> human checkpoint, never auto-run.

**`qa.level`**: controls test enforcement at phase gates, where `workflow`
controls which artifacts are required. `modes.rigor` sets both together; set
`qa.level` explicitly to vary enforcement alone. At `minimal`, no test gates apply — the
test-evidence and unit-test artifact items become non-required and the
Section 3 `testing.strict` check is a no-op; the smoke check is not relaxed (Section 2b) —
but at this level `/smoke-check` runs without game tests (its automated row reads
WAIVED), so the build check (`commands.smoke`, else `commands.build`, when set) and
the launch and critical-path checks are the floor — a build nobody launched is
NOT ASSESSED — and a project with no tests can still pass. At `standard`,
Logic + Integration tests must pass. At `full`, a full coverage check + regression suite are required
(coverage minimum from `qa.coverage_minimum` if set). The retained screenshots
UI and Visual/Feel stories need are not test items: no `qa.level` relaxes them
(Section 2b).

**`team.size`**: does not change how many directors spawn at a phase gate — panel
width is `workflow`'s axis (Section 4b). This value affects only the
**specialist depth within each director's review**.
`individual` uses the core specialist set; `small` the standard set; `studio`
adds engine sub-specialists. It never skips a director — skipping directors is
`review_mode`'s job. Both `review_mode` and `team.size` are now fronted by
`modes.rigor` — one rigor choice sets both — and each still overrides that axis
when set explicitly (a full-rigor project gets the `studio` set; lighter tiers
get `individual`).

- **With argument**: `/gate-check production` — validate readiness for that specific phase
- **No argument**: Auto-detect current stage using the same heuristics as
  `/project-stage-detect`, then **confirm with the user before running**:

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[current stage]**. Running gate for [Current] → [Next] transition. Is this correct?"
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Concept → Systems Design, Systems Design → Technical Setup, Technical Setup → Pre-Production, Pre-Production → Production, Production → Polish, Polish → Release)
  
  Do not skip this confirmation step when no argument is provided.

---

## 2. Phase Gate Definitions

Each gate's checklist — required artifacts, quality checks, and its workflow-tier
reductions — lives in its own file. **Read only the row for the target phase
transition; never load the others.**

| Gate | Definition file |
|------|-----------------|
| Concept → Systems Design | `.claude/skills/gate-check/references/gate-systems-design.md` |
| Systems Design → Technical Setup | `.claude/skills/gate-check/references/gate-technical-setup.md` |
| Technical Setup → Pre-Production | `.claude/skills/gate-check/references/gate-pre-production.md` |
| Pre-Production → Production | `.claude/skills/gate-check/references/gate-production.md` |
| Production → Polish | `.claude/skills/gate-check/references/gate-polish.md` |
| Polish → Release | `.claude/skills/gate-check/references/gate-release.md` |

Each file states the `full` baseline first, then the `standard` and `minimal`
reductions for that gate. Apply the tier resolved in Section 1.

## 2b. Workflow Tier Adjustment

Each gate file carries its own tier reductions (see Section 2). Two rules apply
across all of them:

> **How to apply:** run the loaded gate's checklist, then apply that file's tier
> reduction for the tier resolved in Section 1. **drop** = not checked at this
> tier; **→ recommended** = absent surfaces as CONCERNS, never a Blocker; items
> not named keep their baseline status. Reductions only ever *relax* a
> requirement — the only thing that adds one is `workflow_overrides` (below).
>
> **`qa.level` (Section 1) further relaxes the test items independently of the
> tier:** at `qa.level: minimal` the test-evidence / unit-test items become
> non-required at every workflow tier (so even `workflow: full` does not require
> them); the Section 3 `testing.strict` check is then a no-op.
>
> **It relaxes tests, not the look.** A UI story's retained screenshots, and a
> Visual/Feel story's screenshots plus lead sign-off, are required at every
> `qa.level` wherever the gate file asks for story evidence
> (`.claude/docs/coding-standards.md`: tests are waived at `minimal`, the look
> is not).
>
> **The smoke check is excluded from that relaxation, and is the floor.**
> `qa.level` relaxes *per-story test evidence*; a smoke check is **build health**,
> not story evidence, and the two are already held apart on exactly this basis in
> `.claude/docs/coding-standards.md` ("`/smoke-check` is a build-health gate, not
> a per-story evidence gate ... This divergence is intentional"). So a gate file
> that requires a smoke report keeps requiring it at every `qa.level`.
>
> Without that exclusion the Production → Polish gate had **zero required
> artifacts at `rigor: minimal`** and could not fail on artifacts by
> construction: `minimal` reduced the gate to the smoke check alone, `qa.level`
> then dropped the smoke check too, and one `modes.rigor` setting fires both.

> **A gate with no required artifacts left must say so, and may not return
> PASS.** After applying the tier reduction and the `qa.level` relaxation, count
> what remains required. If the count is zero, report
> **NOT ASSESSED** naming both reducers and the gate — *"Production → Polish at
> `workflow: minimal` + `qa.level: minimal` leaves no required artifact; this
> gate verified nothing"* — rather than a PASS earned by having nothing to check.
> Per `.claude/rules/skill-authoring.md` obligation 1, a run that could not
> assess its scope has not established that the scope is good, and obligation 3
> requires the emptiness to be visible in the output rather than inferable from
> a silent green.
>
> **The one exception: a gate its tier reference file marks "not applicable" at
> this tier** (Systems Design → Technical Setup at `workflow: minimal`). That is
> not a gate with nothing left to check but a transition the tier does not have:
> it PASSes with that file's note, printed in the report. The director panel
> does not run for it — note "Director Panel skipped — gate not applicable at
> `workflow: [tier]`" — and the Section 6 stage write still asks first.
>
> **`performance.enforce` is likewise independent of the tier, and a tier
> reduction never suppresses it.** The performance check in Section 3 runs at
> every workflow tier, and `block` makes a breach a Blocker at every workflow
> tier. Do **not** read a gate file's *"everything else drops"* as dropping it:
> `off` is the only thing that makes budgets informational, and it is a
> deliberate choice the user makes on the same key.
>
> Without this, `performance.enforce: block` is **inert on every `rigor: minimal`
> project** — the Polish gate's `minimal` reduction drops everything outside its
> floor, and "Performance is within budget" sits in the dropped remainder. A
> setting that works only when a rule is disregarded is not wired.

### Per-system overrides (`workflow_overrides.system_overrides`)

Independent of the project-level tier above, and applied **only** on the gates
that validate MVP GDDs (Systems Design → Technical Setup, and the GDD-completeness
checks at Pre-Production → Production). For each system, resolve its effective
tier:

1. If the block's `system_overrides` lists `<system>` → that tier
2. Else the project-level `workflow`

**Before applying any of them, check the block the other way round: does every
KEY match a system?** `<system>` is the GDD filename stem
(`.claude/docs/workflow-modes.md`), so for each key in `system_overrides`, look
for `design/gdd/<key>.md`. Any key with no matching stem is reported, naming the
key and listing the stems that do exist:

> `system_overrides key 'no-such-system' matches no GDD in design/gdd/. Available stems: combat, inventory, hammer-heat-system. This override is doing nothing.`

Surface it as a **CONCERNS**-level finding, not a Blocker — the project is still
gateable, but an override the user believes is in force and is not is exactly how
a documented escape hatch silently stops working.

> **This is the one site that performs the check.** `workflow-modes.md:72` says
> *"a key that matches no system is an error, not a no-op"*, and this is the only
> skill that implements it — the three story skills resolve only in the
> system → override direction, so an orphan key is never looked up and
> never noticed. `/gate-check` is the right home: it already resolves the whole
> block, and it is the project-wide audit rather than a per-story one.

Validate each GDD against its own effective tier's section count:

- A system pinned **higher** than the project (e.g. `system_overrides.combat:
  full` on a `standard` project) **blocks the gate** until that system's GDD
  meets the higher bar (combat → all 8 sections). This is the one case where a
  per-system setting makes the gate *stricter* than the project tier.
- A system pinned **lower** (e.g. `inventory: minimal`) relaxes only that system
  — its GDD is checked at the lower tier; every other system stays at the project
  level. A system pinned **`minimal` imposes no GDD section requirement at all**
  (`minimal` = "game brief replaces GDDs" — `.claude/docs/workflow-modes.md`): it
  never blocks the gate on a missing or incomplete GDD. Do not invent an
  "acceptance-criteria-only" floor for it — there is none.

> **Additive overrides (the only things that make the gate stricter).**
> - `workflow_overrides.art_bible_strict: true` forces the complete (9-section)
>   art bible at the Technical Setup → Pre-Production and Pre-Production →
>   Production gates regardless of tier or whether visual-asset stories exist.
> - `workflow_overrides.edge_cases: true` and `workflow_overrides.tuning_knobs:
>   true` force those GDD sections required when validating GDD completeness,
>   additive on top of the resolved tier (e.g. at `standard`, `tuning_knobs: true`
>   makes the otherwise-optional Tuning Knobs section blocking). These never
>   relax — a `false` value is the default/no-op, never a way to drop a section
>   the tier already requires.

---

## 3. Run the Gate Check

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Systems Design → Technical Setup, pull entries in Economy, Combat, or any GDD domain;
if checking Technical Setup → Pre-Production, pull entries in Architecture, Engine).
Carry these as context — recurring conflict patterns in the target domain warrant
increased scrutiny on those specific checks.

For each item in the target gate:

### Artifact Checks

**Resolve existence and counts deterministically — do not open files to find out
what exists:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [source-phase]
```

Pass the phase being advanced *from* (its steps are the work that must be
complete): `systems-design` for the Systems Design → Technical Setup gate,
`pre-production` for Pre-Production → Production, and so on.

At `workflow: minimal`, also run
`bash .claude/scripts/artifact-check.sh --path minimal`: the brief and stories
live on that path, not on any phase, and its `game-brief` and `create-stories`
rows are this tier's floor.

It reads `workflow-catalog.yaml` — which already encodes each step's `glob`,
`pattern`, `min_count` and `any_of` — and reports per step:

| status | Meaning |
|---|---|
| `PRESENT` | glob matched, `min_count` met, `pattern` found where specified |
| `ABSENT` | nothing matched |
| `SHORT` | matched but fewer than `min_count` (`count=` and `min=` given) |
| `PATTERN_MISS` | files exist but none contains the required marker |
| `NO_CHECK` | the step declares no artifact — **not detectable from disk** |

It emits observations, never a verdict: **you** apply the workflow tier and the
required/optional split from Section 2. An `ABSENT` required artifact is a
blocker at `full` and frequently not one at `minimal`; the script does not know
that and does not decide it.

**`NO_CHECK` is not `PRESENT`.** The header prints a `NO_CHECK:` count before any
row precisely so this cannot be skimmed past. Those steps were *scanned*, not
*satisfied* — carry each into Section 4 (Collaborative Assessment) and ask, or
mark MANUAL CHECK NEEDED. A gate that reports PASS because most of its checklist
was undetectable is the failure mode this count exists to prevent.

**Existence is not adequacy.** The script cannot tell a real document from a
template skeleton. So: for any artifact the verdict actually turns on, spot-read
it and confirm it has real content — the same escalation rule the
`gdd-structure-check.sh` step below uses. Do not spot-read artifacts the verdict
does not turn on.

> **A smoke report is always an artifact the verdict turns on — spot-reading it
> is mandatory, not discretionary.** At `minimal` it is frequently the *only*
> required artifact, so the whole gate rests on one file that nothing generated
> and nothing verifies. Check its claims against the repo, and raise any that the
> tree contradicts:
>
> - It reports a passing automated suite → the engine's test root must actually
>   contain test files and the project must have a runner. "24 passed, 0 failed"
>   in a repo with no test files under that root — `tests/unit/` and
>   `tests/integration/` on Godot, `Assets/Tests/` on Unity,
>   `Source/<Module>/Private/Tests/` on Unreal — and no runner is a finding, not
>   evidence.
> - It marks a critical path PASS → the code for that path must exist in the code
>   root. A PASS on "banking ends the run" with no banking code is a finding.
> - It carries no date, or predates the newest commit touching the code root →
>   say so; a stale smoke report describes a build that no longer exists.
>
> Report a contradiction at the same level the artifact was required at: a
> Blocker where the smoke check is required, CONCERNS where it is recommended.
> Existence plus a verdict-line grep would clear a fabricated report.

For code checks, verify directory structure and file counts.

**Systems Design → Technical Setup gate — cross-GDD review check**:
Use `Glob('design/gdd/gdd-cross-review-*.md')` to find the `/review-all-gdds` report.
If no file matches: at `full` mark the "cross-GDD review report exists" artifact as
**FAIL** and surface it prominently ("No `/review-all-gdds` report found in
`design/gdd/`. Run `/review-all-gdds` before advancing to Technical Setup."); at
`standard` the report is recommended, so mark it **CONCERNS**, not a blocker; at
`minimal` this gate is not applicable (see the gate file). If a file is found, read it and
check the verdict line: a FAIL verdict means the cross-GDD consistency check failed
and must be resolved before advancing. A NOT ASSESSED verdict means that review
could not compare the GDDs, so it satisfies nothing here: mark the item NOT
ASSESSED for this gate, never passed.

### Quality Checks
- For test checks: Run the test suite via `Bash` if a test runner is configured.
  **If no runner is configured, that is `NOT ASSESSED`, not a silent skip** — see
  the trigger in the verdict section. A gate that ran no tests found no test
  failures, which is not the same as passing.
  A test failure's effect on the verdict depends on the `testing.strict` block
  **resolved in Phase 1** (`resolve_config` merges `project.local.yaml` over
  `project.yaml`; reading the file directly would drop a local override), per
  test type:
  - **Logic** — unit-level failures (`tests/unit/` on Godot, Edit Mode on
    Unity), gated by `testing.strict.logic`.
  - **Integration** — failures in `tests/integration/` on Godot, Play Mode on
    Unity, gated by `testing.strict.integration`. On Unreal, where one root
    (`Source/<Module>/Private/Tests/`) holds both, classify a failure by its
    story's Type, or apply the stricter of the two levels when that is unknown.
  - For each type: take `testing.strict.<type>` from that block; use it only
    if its value is `true` or `false` (case-insensitive). If the key is absent,
    empty, or holds any other value, read `testing.strict` as a plain boolean
    (legacy single-value form); if that too is absent or invalid, default to
    `true` (Logic and Integration are both strict by default — behavior unchanged
    from before this setting existed). Surface any unrecognized value to the user.
  - At a strict (`true`) gate level, failures of that type are **Blockers**
    (verdict FAIL). At an advisory (`false`) level, they are **Concerns**
    (verdict minimum CONCERNS, not FAIL) — list them under Recommendations, not
    Blockers.
- For design review checks, gather section presence **deterministically** — do not
  read the GDDs to count headings:

  ```
  Bash: bash .claude/scripts/gdd-structure-check.sh
  ```

  It prints a `PRESENT:` / `ABSENT:` pair per GDD and already accepts
  `## Detailed Design` as satisfying the `Detailed Rules` requirement. It reports
  presence only and makes no REQUIRED/ADVISORY judgment.

  Then apply each GDD's **effective tier** (per-system resolution below) to those
  lists — all 8 sections at `full`, the 5 standard sections (+ conditional
  Formulas) at `standard`. A missing *required* section blocks; a missing section
  that is optional at the effective tier is advisory. A section reported PRESENT
  can still fail review if it is an empty heading — spot-read any section the
  verdict actually turns on.
- For performance checks: read the budgets (`performance.target_framerate`,
  `frame_budget_ms`, `draw_call_limit`, `memory_ceiling_mb`) from `project.yaml`
  (else technical-preferences.md) and compare against any profiling data in
  `tests/performance/` or recent `/perf-profile` output. What a breach *means*
  is set by `performance.enforce`, taken from the Phase 1 resolved block (it is
  locally overridable, so do not read the file for this one):
  - `warn` (default) — breaches are **CONCERNS**, never Blockers.
  - `block` — breaches are **Blockers** from the Polish gate onward.
  - `off` — budgets are informational; do not surface breaches in the verdict.

  Only these three values are recognized. Surface anything else to the user and
  fall back to `warn` rather than guessing.
- For localization checks: `Grep` for hardcoded strings in the **code root** (resolve per `.claude/docs/code-root-resolution.md`). **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**

### Cross-Reference Checks
- Compare `design/gdd/` documents against implementations in the **code root**
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

---

## 4. Collaborative Assessment

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.
An answer resolves the item: "no" or "not yet" is a checked, failed item
(CONCERNS or FAIL, naming the skill that closes it — `/design-review [doc]` for
an unreviewed concept or GDD) — except a play question at the Production gate
(a human has played the Vertical Slice; at `minimal`, the core loop is fun on
the current build), where "not yet" means nobody has played it: NOT ASSESSED
(`gate-production.md`). Only an unanswered item or "I don't know" stays
MANUAL CHECK NEEDED, which Section 5 turns into NOT ASSESSED.

This applies to questions about the project's state. Declining an offer to
produce missing data (e.g. `/perf-profile`) leaves the item NOT ASSESSED; at
`performance.enforce: off` it stays out of the verdict.

---

## 4b. Director Panel Assessment

The panel is set by **two independent axes**, both resolved in Phase 1: `review_mode`
decides *whether* the panel runs, `workflow` decides *how wide* it is.

**Axis 1 — `review_mode` decides whether any director spawns:**
- `solo` → skip the panel entirely. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." Proceed to Phase 5.
- `lean` → run the panel (phase gates always run in lean mode — this is their purpose).
- `full` → run the panel.

**Axis 2 — `workflow` decides the panel width.** Directors are Opus-tier, so a
fixed four-director panel costs a two-system jam exactly what it costs a
thirty-system commercial project. The gate still runs at every tier; only its
breadth scales:

| `workflow` | Panel | Directors |
|---|---|---|
| `minimal` | 1 | `producer` |
| `standard` | 2 | `technical-director`, `producer` |
| `full` | 4 | `creative-director`, `technical-director`, `producer`, `art-director` |

`producer` is in every panel — scope and schedule readiness is the one judgment
no tier makes optional. `technical-director` joins at `standard` because that is
the first tier requiring architecture artifacts. `creative-director` and
`art-director` join at `full`, the only tier requiring the full art bible and
UX spec set for them to assess.

> **Width is not the same as strictness.** A narrower panel does not soften the
> verdict: the escalation rule in `.claude/docs/director-gates.md` is unchanged —
> the strictest verdict returned by *whoever ran* still wins. Do not infer PASS
> from a perspective that was never consulted.

Before generating the final verdict, spawn the directors for the resolved tier as **parallel subagents** via `Agent` using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all the `Agent` calls simultaneously — do not wait for one before starting the next.

**Gate IDs:**

1. **`creative-director`** — gate **CD-PHASE-GATE** (`.claude/docs/director-gates/cd-phase-gate.md`)
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates/td-phase-gate.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates/pr-phase-gate.md`)
4. **`art-director`** — gate **AD-PHASE-GATE** (`.claude/docs/director-gates/ad-phase-gate.md`)

Pass to each the target phase name, the resolved `workflow` tier, the target
gate's required and recommended artifacts at the resolved tier (the loaded gate
file's checklist after its tier reduction and the `qa.level` relaxation — what
this gate asks for, not what a later one will), the list of artifacts present,
and its gate's own context — named here, so this session never has to read the
gate files:
- **CD-PHASE-GATE**: the game pillars and core fantasy (from
  `design/gdd/game-concept.md`, else `design/game-brief.md`).
- **TD-PHASE-GATE**: the architecture document path, the engine reference path
  (`docs/engine-reference/<engine>/VERSION.md`), and the ADR list.
- **PR-PHASE-GATE**: the sprint and milestone artifacts present, `team.size` as
  resolved above (with the current sprint plan's capacity, if a plan exists), and
  the number of stories under `production/epics/` whose status is `Blocked`. At
  `workflow: minimal`, pass the Build order in `design/game-brief.md` as the plan — that
  tier has no sprint plan.
- **AD-PHASE-GATE**: the art and visual artifacts present, the Visual Identity
  Anchor (from `design/gdd/game-concept.md`, else the "Art & audio direction"
  line of `design/game-brief.md`), and the art bible path.

Pass each context item as one of three things, so no director has to guess:
- **Present** — its path or value (`0` blocked stories is a value).
- **"none"** — the target gate (or an earlier one) requires or recommends it at
  this tier and it does not exist (no architecture document at
  `/gate-check pre-production`). For the director that is a fact about the
  project to judge, not a missing input.
- **"not expected before [phase]"** — the target gate does not ask for it yet;
  name the phase whose gate first does (the architecture document and ADRs
  before Pre-Production, the sprint plan before Production). One this tier never
  requires is "not required at `workflow: [tier]`" (any sprint plan at
  `minimal`). Neither is ever passed as "none", and neither is a finding — a
  director judges readiness for the phase being entered, not a later one.

**Name the omissions in the output.** Below the Director Panel summary, when the
panel ran narrower than four, state which perspectives did not run and how to get
them — e.g. "Panel: 2 of 4 (`workflow: standard`). Creative and Art perspectives
not consulted. Raise `modes.rigor` to `full` (or set `modes.workflow: full`) for
the complete panel." Name the setting the config block shows as `workflow`'s
source: when `modes.workflow` is set on its own, raising `modes.rigor` does not
change it. Never point to `--review full` for this — `--review` decides whether
the panel runs, not how wide it is. A silently narrow panel reads as a clean bill
of health from reviewers who never looked.

**Collect every response from the directors that ran, then present the Director Panel summary** (one row per director that ran; name the ones `workflow` left out):

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Art Director:       [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]
```

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (no override turns a FAIL into a stage change — Section 6)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- Any director returns NOT ASSESSED (and none returned NOT READY or CONCERNS) → verdict at best NOT ASSESSED; name the input that director said was missing — it never counts as READY
- Every director that ran returns READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---

## 5. Output the Verdict

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md (design/game-brief.md at `minimal`) — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase —
  the stage advances only if the user explicitly accepts them (Section 6)
- **FAIL**: Critical blockers must be resolved before advancing
- **NOT ASSESSED**: One or more required checks could not be run at all — name
  which, and why, in the Blockers section

### Accepted Risks (only when the user advanced on CONCERNS)
- [each concern, as listed above] — accepted by the user, [date]
```

**`NOT ASSESSED` — when the gate could not look.** Rank: it **outranks PASS**
(a gate that could not check part of its scope has not established the phase is
ready) and **ranks below CONCERNS and FAIL** (a known blocker is more actionable
than an unknown, and demoting it behind an access problem buries it). It is not a
softer FAIL: "I checked and found a blocker" and "I could not check" need
different fixes — one needs work done, the other needs the input produced or made
readable.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**FAIL**, then **CONCERNS**, then **NOT ASSESSED**, then **PASS**. A gate with
both a real blocker and an unassessable check is FAIL: the blocker is the
actionable finding. Stating the order mechanically removes the inference — the
rank sentence above says what outranks what, but only an ordered list says what
to do when two conditions hold at once.

Emit it when any of:

- A **required artifact exists but cannot be assessed** — empty, unreadable, or
  still entirely `[TO BE CONFIGURED]` / template placeholders. Present-but-empty
  is the case that most looks like present.
- A **quality check's input carries no measured data**. Section 3 compares the
  performance budgets against "profiling data in `tests/performance/` or recent
  `/perf-profile` output" — and `/perf-profile`'s report template pre-fills
  `[16.67ms]` as the budget, so it can render ">99% headroom" from zero profiler
  data. Placeholder numbers are not measurements: a budget nobody set is not a
  budget that was met. Absent data already prompts (Section 4 offers to run
  `/perf-profile`); this covers data that is *present and hollow*, which is the
  case that looks like a measurement.
- A **test check the tier requires could not be executed** — no test runner is
  configured, or the runner is configured but failed to start. Section 3 runs the
  suite "if a test runner is configured", and an unconfigured runner produced no
  failures, so the test check contributed nothing to the verdict and the gate
  could still reach PASS. Meanwhile `testing.strict.logic` and
  `.integration` both default to `true`, so the project's own configuration
  called those gates BLOCKING. A blocking gate that never ran is the unknown this
  verdict exists to name. Remediation is already listed under Common Gaps
  (`/test-setup`); this is what the verdict does with it.

  > **Scope this to tiers that require tests.** At `qa.level: minimal` no test
  > gates apply at all (see the config block above), so a missing runner there is
  > the configured posture, not a hole — firing the trigger would make every
  > `minimal` gate permanently NOT ASSESSED and stop stage advancement, the same
  > over-broad reading the director trigger below warns against. Fires only where
  > the resolved tier actually asked for the test check.
- A **`MANUAL CHECK NEEDED` item the user never resolved**. Section 4 already
  refuses to assume PASS for unverifiable items and marks them this way — but
  until now the verdict vocabulary had nowhere to put one, so an unresolved
  manual check had to land inside PASS, CONCERNS or FAIL anyway. This is where it
  goes.
- A director the **resolved tier was supposed to spawn** did not return — it
  errored, produced no verdict, or was interrupted.

  > **Scope this narrowly, and do not read it as "fewer than four directors ran".**
  > Section 4b narrows the panel *by design* — 1 director at `minimal`, 2 at
  > `standard`, 4 at `full`, and none in `solo` — and that narrowing is a
  > deliberate, announced reduction, not a failure to assess. The broad reading
  > makes every `minimal`, `standard` and `solo` gate permanently NOT ASSESSED,
  > which means the verdict can never be PASS and Section 6 can never advance
  > `project.stage`. **That would break stage advancement for most projects,**
  > since those are the common tiers. The trigger fires only when a director the
  > tier *did* call for fails to come back — a hole in the panel you expected,
  > never the panel you deliberately chose.
- A referenced upstream verdict is itself `NOT ASSESSED` — it propagates upward
  rather than resolving to a pass.

Never resolve an unknown by assuming the permissive reading. If the check could
not run, that fact is the finding.

---

## 5a. Chain-of-Verification

After drafting the verdict in Phase 5, challenge it before finalising.

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

> **Tool-action requirement**: At least 2 of the 5 challenge questions below must be answered by re-reading a specific file (Read tool) or re-running a specific check (Grep tool) — not by reflection alone. Mark these with [TOOL ACTION] to indicate a tool was used.

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation? [TOOL ACTION] Re-scan the checklist for any [?] or MANUAL CHECK items."
- "Did I confirm all listed artifacts have real content, not just empty headers? [TOOL ACTION] Re-read the file and check it has non-placeholder content."
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper design problem?"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals a check that **could not be run** rather than one that
  ran and passed → PASS→NOT ASSESSED. The first two PASS-draft questions above
  ("verified by actually reading a file, vs. inferring", "MANUAL CHECK NEEDED
  items I marked PASS") exist to find exactly this, and until now a yes to either
  had no verdict to move to
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- Never revise NOT ASSESSED down to PASS by re-reasoning about the missing input.
  Only obtaining the input clears it
- If answers are consistent → confirm verdict unchanged

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance, write the
new stage to BOTH `project.yaml` and the legacy `production/stage.txt`.

**On CONCERNS, the user may override — explicitly.** Do not offer the stage
write by default. If the user asks to advance anyway, list every concern and
ask: "The gate returned CONCERNS. Accept these risks — [list] — and may I update
`project.stage` in `project.yaml` to '[stage]' (and the legacy
`production/stage.txt`)?" Only on an explicit yes, add the `### Accepted Risks`
section to the gate report (each concern, accepted by the user, with the date)
and write the stage as below. **A FAIL is never overridden into a stage change, and
neither is NOT ASSESSED** — the blockers must be fixed, or the missing input
produced, and the gate re-run.

### 6.1 Primary write — `project.yaml`

Set `project.stage` to the new stage name in `project.yaml` at the repo root.

- **If a `project:` block already exists**: Read `project.yaml` first (the Edit
  tool requires the file to have been read in this session), then use the Edit
  tool to change its `stage:` value.
- **If `project.yaml` exists but has no `project:` block**: Read `project.yaml`
  first, then use the Edit tool to insert the block immediately after the
  `framework:` block (before `modes:`). Insert exactly (replace `<new-stage>`):
  ```yaml
  project:
    stage: <new-stage>
  ```
- **If `project.yaml` does not exist at all**: create it with the Write tool using
  this v1.1 minimal template (replace `<new-stage>` and the date):
  ```yaml
  # CCGS project configuration — single source of truth for project settings.
  # Schema: grep the `## <key>` section of .claude/docs/effects-map.md —
  # it is ~31k tokens whole, ~900 per section. Do not open it entire.

  schema_version: 1

  framework:
    version: 1.1.2
    last_upgraded: <YYYY-MM-DD>

  project:
    stage: <new-stage>
  ```
  Do not seed `modes.review_mode` here. It is a rigor-fronted knob — `modes.rigor`
  supplies its value, so an explicit value would shadow the rigor expansion and pin
  the review mode regardless of the project's rigor.

### 6.2 Legacy fallback write — `production/stage.txt`

Also write the single-line stage name (no trailing newline) so hooks that have not
migrated still work. Ensure the `production/` directory exists first:
```bash
mkdir -p production && printf '%s' "Production" > production/stage.txt
```

### 6.3 Verify both writes

After both writes, Read `project.yaml` and `production/stage.txt` and confirm both
show the new stage. If they diverge, report the discrepancy to the user and stop —
a split stage indicator corrupts future auto-detection.

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the legacy `production/stage.txt`)?" — on an accepted CONCERNS override, the explicit yes above is that ask.

### 6.4 Rigor-fit check (advisory — never affects the verdict)

After the stage advance is confirmed, apply the raise trigger in
`.claude/docs/settings-guidance.md § 4`: if the new stage is **Production** (or
later) while the resolved `modes.workflow` is `minimal` (the `rigor: minimal`
posture, from the config block above), add one line:

> "You're entering [stage] on `rigor: minimal` — most projects this size run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

---

## 7. Closing Next-Step Widget

After the verdict is presented and any stage update is complete (project.yaml + stage.txt), close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran.** The argument names the phase
being entered, so `/gate-check systems-design` is the Concept → Systems Design gate.

**At `workflow: minimal`, skip the menus below.** They walk the phase ladder, and
the minimal route is not the ladder: offer the first incomplete step of
`paths.minimal` instead (the `--path minimal` rows from Section 3):
`/setup-engine`, then `/brainstorm`, then `/create-stories`, then `/dev-story`
on the next story — the route `/help` gives.

For **Concept → Systems Design** (`/gate-check systems-design`) PASS — option [A] is
`/map-systems` when `design/gdd/systems-index.md` does not exist yet (many
projects write it during Concept, as the workflow catalog orders it), otherwise
`/design-system [first system in the index's design order]`:
```
Gate passed. What would you like to do next?
[A] Run /map-systems — decompose the concept into systems and a design order (recommended next step)
    — or, when the systems index already exists: Run /design-system [first system] — author its GDD
[B] Revisit the concept first — return here when it is settled
[C] Stop here for this session
```

For **Systems Design → Technical Setup** (`/gate-check technical-setup`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

> **Note for the Systems Design → Technical Setup PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the master architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

For **Technical Setup → Pre-Production** (`/gate-check pre-production`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (first, if docs/architecture/control-manifest.md does not exist yet)
[B] Run /vertical-slice — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

> **Note for the Technical Setup → Pre-Production PASS**: The Pre-Production sequence is deliberately ordered
> to validate fun before committing to detailed planning:
>
> 1. `/create-control-manifest` — extract technical rules from Accepted ADRs, if not done yet (`/create-epics` requires it at `full`)
> 2. `/vertical-slice` — build the Vertical Slice **FIRST**, before writing epics or stories
> 3. Playtest → `/playtest-report` — at least 1 documented session, 3+ better before committing the full team. `/gate-check production` treats the slice as recommended: skipped → CONCERNS, unplayed → NOT ASSESSED
> 4. `/ux-design [screen]` — UX specs for main menu, core HUD, pause menu (if not done)
> 5. `/create-epics layer:foundation` then `/create-epics layer:core` — plan after fun is validated
> 6. `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new`
>
> **Why prototype before epics?** If the prototype reveals the core loop needs to change,
> epics written before that discovery will be partially wrong. Validate fun cheaply first,
> then plan in detail. This is the #1 lesson from GDC postmortem data.

For all other gates, offer the two most logical next steps for that phase plus "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No art bible?** → `/art-bible` to create the visual identity specification
- **Art bible exists but no asset specs?** → `/asset-spec system:[name]` to generate per-asset visual specs and generation prompts from approved GDDs
- **No game concept?** → `/brainstorm` to create one
- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/reverse-document` or delegate to `game-designer`
- **Small design change needed?** → `/quick-design` for changes under about one week of implementation (bypasses full GDD pipeline)
- **No UX specs?** → `/ux-design [screen name]` to author specs, or `/team-ui [feature]` for full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all` to validate
- **No accessibility requirements doc?** → run `/ux-design` which creates both `design/accessibility-requirements.md` and `design/ux/interaction-patterns.md` in one step
- **No interaction pattern library?** → `/ux-design patterns` to initialize it
- **Concept or a GDD not reviewed?** → `/design-review [doc]`
- **GDDs not cross-reviewed?** → `/review-all-gdds` (run after all MVP GDDs are individually approved)
- **Cross-GDD consistency issues?** → fix flagged GDDs, then re-run `/review-all-gdds`
- **No test framework?** → `/test-setup` to scaffold the framework for your engine
- **No QA plan for current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **ADRs missing engine compatibility sections?** → Re-run `/architecture-decision`
  or manually add Engine Compatibility sections to existing ADRs
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core` (requires control manifest)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before developers pick them up
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **No playtest sessions beyond the minimum?** → Additional sessions give more reliable signal. 3+ total is recommended before committing the full team. Use `/playtest-report` to structure findings.
- **No Difficulty Curve doc?** → Author `design/difficulty-curve.md` by hand from the template at `.claude/docs/templates/difficulty-curve.md`. (`/quick-design` is a related session but writes to `design/quick-specs/`, not to this path — use it to think the curve through, then copy the outcome here.)
- **No player journey map?** → Author `design/player-journey.md` by hand from the template at `.claude/docs/templates/player-journey.md`.

> **Neither of these has a skill that writes it — the remediations must not imply
> otherwise.** Naming "`/ux-design` Phase 2b" would point at the step that *reads*
> `design/player-journey.md`, landing the user back at the check that just
> failed. Naming `/quick-design` would point at a skill that writes
> `design/quick-specs/[name]-[date].md` and would leave this gate still failing.
> Both docs are hand-authored from their templates; say so plainly rather than
> naming a skill that cannot produce them.
- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/localize`
- **No security audit, or open CRITICAL/HIGH findings?** → `/security-audit` (after fixes, `/security-audit quick` to confirm)
- **Ready for release?** → `/launch-checklist`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call on
   what to do next; only the stage write is bound to it (Section 6)
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.

**Never** block a user from working — the verdict decides only whether this skill
writes the new stage. On CONCERNS the user may advance by explicitly accepting the
listed risks, which the report records (Section 6); on FAIL or NOT ASSESSED the
stage stays where it is until a re-run passes, and nothing stops the user working
on the blockers meanwhile.
