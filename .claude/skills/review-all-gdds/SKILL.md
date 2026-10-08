---
name: review-all-gdds
description: "Holistic cross-GDD review — contradictions between systems, dominant strategies, economic imbalance, cognitive overload, pillar drift."
argument-hint: "[focus: full | consistency | design-theory | since-last-review]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/review-all-gdds/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides`

# Review All GDDs

This skill reads every system GDD simultaneously and performs two complementary
reviews that cannot be done per-GDD in isolation:

1. **Cross-GDD Consistency** — contradictions, stale references, and ownership
   conflicts between documents
2. **Game Design Holism** — issues that only emerge when you see all systems
   together: dominant strategies, broken economies, cognitive overload, pillar
   drift, competing progression loops

**This is distinct from `/design-review`**, which reviews one GDD for internal
completeness. This skill reviews the *relationships* between all GDDs.

**When to run:**
- After all MVP-tier GDDs are individually approved
- After any GDD is significantly revised mid-production
- Before `/create-architecture` begins (architecture built on inconsistent GDDs
  inherits those inconsistencies)

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Argument modes:**

**Focus:** `$ARGUMENTS` (blank = `full`)

- **No argument / `full`**: Both consistency and design theory passes
- **`consistency`**: Cross-GDD consistency checks only (faster)
- **`design-theory`**: Game design holism checks only
- **`since-last-review`**: Only GDDs modified since the last review report (git-based)

---

**`workflow`** per GDD (per `.claude/docs/workflow-modes.md`): each GDD validates
against its effective tier — the project value, overridden per system by the
`system_overrides` row for that system when the block lists one. At `full`, validate all 8
sections across all GDDs. At `standard`, validate the 5 required sections;
optional sections (Player Fantasy, Tuning Knobs, conditional Formulas) are
surfaced as advisory only. At `minimal`, this skill is not applicable (no GDDs).

## Phase 1: Load Everything

**Read `references/1-load.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

### Parallel Execution

Phase 2 (Consistency) and Phase 3 (Design Theory) are independent — they read
the same GDD inputs but produce separate reports. Spawn both as parallel `Agent`
agents simultaneously rather than waiting for Phase 2 to complete before
starting Phase 3. Collect both results before writing the combined report.

Spawn both as `game-designer` sub-agents (`subagent_type: game-designer`) — GDD
consistency and design-theory review is its domain.

**When spawning the Phase 2 and Phase 3 agents, always pass:**
- The loaded GDD **content** each phase needs — **not file paths**. Paste the
  sections; the sub-agent has its own context and cannot re-read Phase 1's
  results, so a path forces a full re-read (and contradicts the "do not re-read"
  rule below). Pass only the phase's slice: Phase 2 (consistency) needs each GDD's
  Dependencies, Detailed Design/Rules, Formulas, Tuning Knobs and Acceptance
  Criteria; Phase 3 (design theory) needs Player Fantasy, progression/reward
  structure and the game pillars.
- The full entity registry contents (`design/registry/entities.yaml`) if loaded in Phase 1b (paste the registry text, not just a file path)
- The specific checklist items assigned to that agent's phase (Phase 2 gets 2a–2f; Phase 3 gets 3a–3g)
- The engine name and version — `engine.name` and `engine.version` from `project.yaml`, resolving each field independently (if its key is absent or empty, use `.claude/docs/technical-preferences.md`) — plus `docs/engine-reference/[engine]/VERSION.md`

Do not rely on the subagent to re-read these files — it has its own context window and cannot access Phase 1 results unless they are explicitly passed in the `Agent` prompt.

---

## Phase 2: Cross-GDD Consistency

**Read `references/2-consistency.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Game Design Holism

**Read `references/3-design-holism.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Cross-System Scenario Walkthrough

**Read `references/4-scenarios.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Output the Review Report

**Read `references/5-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Write Report and Flag GDDs

**Read `references/6-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Handoff

**Read `references/7-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer GDDs / single-system). Full procedure:
`.claude/docs/error-recovery-protocol.md`.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md`. In `autonomous` mode the
PASS/CONCERNS/FAIL verdict is still printed and logged — only the closing
handoff widget is skipped.

1. **Read silently** — load all GDDs before presenting anything
2. **Show everything** — present the full consistency and design theory analysis
   before asking for any action
3. **Distinguish blocking from advisory** — not every issue needs to block
   architecture; be clear about which do
4. **Don't make design decisions** — flag contradictions and options, but never
   unilaterally decide which GDD is "right"
5. **Ask before writing** — confirm before writing the report or updating the
   systems index
6. **Be specific** — every issue must cite the exact GDD, section, and text
   involved; no vague warnings
