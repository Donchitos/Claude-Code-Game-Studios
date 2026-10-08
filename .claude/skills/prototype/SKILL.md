---
name: prototype
description: "Concept prototype before GDDs — throwaway HTML, Engine or Paper build, PROCEED/PIVOT/KILL/NOT ASSESSED. After /brainstorm and /setup-engine."
argument-hint: "[concept-description] [--path html|engine|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Prototype

## Purpose

This is the **concept prototype** — a fast, throwaway build that answers one question:
*"Is this core idea actually fun to interact with?"*

**Default use** — run right after `/brainstorm` and `/setup-engine`, before writing
GDDs or architecture docs. Its verdict determines whether the concept is worth the
investment of full design documentation.

**Mid-production?** You can also run this at any stage to test a specific mechanic,
design change, or technical question. Pass `--spike` to activate spike mode: a
lightweight ~4-hour build with no GDD prerequisites and no phase gate implications.

**Already have GDDs and architecture complete?** To validate the full game loop
before committing to Production, run `/vertical-slice` instead.

---

## Phase 1: Define the Question

**Read `references/1-question.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Load Concept Context

**Read `references/2-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Choose the Prototype Path

**Read `references/3-choose-path.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Plan the Prototype

**Read `references/4-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Implement

**Read `references/5-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Playtest Debrief

**Read `references/6-debrief.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Generate Prototype Report

**Read `references/7-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Creative Director Review

**Read `references/8-cd-review.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 9: Summary and Next Steps

**Read `references/9-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Spike Mode

**Triggered by:** `--spike` flag OR "Mid-production spike" entry choice in Phase 1.

**Read `references/spike-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

### Important Constraints

- Prototype code must NEVER import from production source files
- Production code must NEVER import from prototype directories
- If the recommendation is PROCEED, production implementation is written from
  scratch — prototype code is never refactored into production
- Total effort is hard-capped at 1 day (concept prototypes test one mechanic)
- Test ONE mechanic — if scope grows, stop and simplify the question
- No polish. No menus, no game over, no music, no UI unless it IS the mechanic
- If stuck after 2 hours of engine iteration, reframe the question or switch paths
- **3 PIVOT iterations → force a KILL decision.** If this is the third time the
  same concept has produced a PIVOT verdict, the concept likely doesn't work.
  Ask: "Is this the right idea, or am I in the sunk cost trap?" A new concept
  prototyped fresh will almost always beat a fourth iteration of a struggling one.
- Building 2-3 different concept variants and picking the best one is a healthier
  strategy than iterating one concept to death. Natural selection between prototypes
  beats willpower.
- **Networked/multiplayer games:** A local prototype cannot validate the feel of a
  networked mechanic. Latency fundamentally changes how combat, movement, and
  prediction feel — a prototype running at 0ms local will feel entirely different at
  80ms network delay. Use a local prototype to validate that the mechanic is
  *interesting*. Do not use it as evidence that it *feels good* under real network
  conditions. Network feel requires real peers or simulated latency (e.g., throttle
  tools, network condition simulators).
