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
| Concept → Systems Design | `references/gate-systems-design.md` |
| Systems Design → Technical Setup | `references/gate-technical-setup.md` |
| Technical Setup → Pre-Production | `references/gate-pre-production.md` |
| Pre-Production → Production | `references/gate-production.md` |
| Production → Polish | `references/gate-polish.md` |
| Polish → Release | `references/gate-release.md` |

Each file states the `full` baseline first, then the `standard` and `minimal`
reductions for that gate. Apply the tier resolved in Section 1.

## 2b. Workflow Tier Adjustment

**Read `references/2b-workflow-tier.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Run the Gate Check

**Read `references/3-run-gate-check.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Collaborative Assessment

**Read `references/4-assessment.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Output the Verdict

**Read `references/5-verdict.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Update Stage on PASS

**Read `references/6-update-stage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7. Closing Next-Step Widget

**Read `references/7-next-steps.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

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
