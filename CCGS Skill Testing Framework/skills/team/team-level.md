# Skill Test Spec: /team-level

## Skill Summary

Orchestrates the full level design team for a single level or area. Coordinates
narrative-director, world-builder, level-designer, systems-designer, art-director,
accessibility-specialist, and qa-tester through five steps: narrative + visual
direction in parallel (Step 1), layout (Step 2), systems (Step 3), production
concepts + accessibility in parallel (Step 4), and QA planning (Step 5). Phase 0
resolves `review_mode`, `automation` and `team.size` and the skill announces the
active set before Step 1 — `individual` spawns level-designer alone, `small` adds
systems-designer + art-director + qa-tester, `studio` adds narrative-director,
world-builder and accessibility-specialist. The orchestrator compiles all team
outputs itself and writes `design/levels/[level-name].md` only after asking "May I
write…?" via `AskUserQuestion`; per-agent artifacts are written by sub-agents under
the bounded write exception. Uses `AskUserQuestion` at each step gate. Produces a
summary report with verdict COMPLETE / BLOCKED and handoffs to `/design-review`,
`/dev-story`, `/qa-plan`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase/step headings (Step 1 through Step 5 are all present)
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] File Write Protocol: per-agent artifacts are written by sub-agents under the bounded exception (named path, new artifact under `production/`, `docs/` or `tests/`, gated step); the one exception is the compiled level doc, which the orchestrator writes itself after its own "May I write …?" prompt
- [ ] Names a destination per agent under `production/levels/[level-name]/` — `narrative.md`, `lore.md`, `visual-direction.md`, `layout.md`, `systems.md`, `production-concepts.md`, `accessibility.md` — and qa-tester's at `production/qa/test-cases/[level-name]-cases.md`
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] Has a next-step handoff at the end (references `/design-review`, `/dev-story`, `/qa-plan`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk before treating a step as done, surface BLOCKED immediately, always produce a partial report, full procedure (surface → assess → options → partial report) in `.claude/docs/error-recovery-protocol.md`
- [ ] Uses `AskUserQuestion` at step transitions for user approval before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Step 1
- [ ] Step 1 explicitly spawns narrative-director, world-builder and art-director in parallel
- [ ] Step 4 is explicitly marked as parallel (art-director and accessibility-specialist run simultaneously) and waits for both
- [ ] Context gathering reads: `design/gdd/game-concept.md` (or `design/game-brief.md`), `design/gdd/game-pillars.md`, `design/levels/`, `design/narrative/`, and relevant world-building docs
- [ ] `## How to Delegate` lists all seven roles (narrative-director, world-builder, level-designer, systems-designer, art-director, accessibility-specialist, qa-tester)
- [ ] accessibility-specialist output includes severity ratings (BLOCKING / RECOMMENDED / NICE TO HAVE)
- [ ] Final level design document saved to `design/levels/[level-name].md`, where `[level-name]` is the argument slugged — lowercase, spaces → hyphens — and adjacent-area paths use the same rule

---

## Test Cases

### Case 1: Happy Path — All team members produce outputs, document compiled and saved

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- `design/gdd/game-concept.md` exists and is populated
- `design/gdd/game-pillars.md` exists
- `design/levels/` directory exists (may contain other level docs)
- `design/narrative/` directory exists with relevant narrative docs
- World-building docs for the forest region exist

**Input:** `/team-level forest dungeon`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: studio`
2. Context gathering — orchestrator reads game-concept.md, game-pillars.md, existing level docs in `design/levels/`, narrative docs in `design/narrative/`, and world-building docs for the forest region
3. Step 1 — narrative-director, world-builder and art-director are spawned together (all three Agent calls issued before any result is awaited): narrative purpose and emotional arc; lore context and world rules; visual theme targets, lighting mood, shape language and landmarks; `AskUserQuestion` presents all three outputs before Step 2
4. Step 2 — level-designer spawned with the Step 1 outputs, including the art-director's visual targets as explicit constraints; designs spatial layout, pacing curve, encounters, puzzles, entry/exit points; orchestrator checks `design/levels/` for every adjacent area referenced; `AskUserQuestion` confirms layout before Step 3
5. Step 3 — systems-designer spawned: enemy compositions, loot tables, difficulty balance, area-specific mechanics, resource distribution; `AskUserQuestion` confirms systems before Step 4
6. Step 4 — art-director (location-specific production concepts) and accessibility-specialist spawned in parallel; each accessibility concern rated BLOCKING / RECOMMENDED / NICE TO HAVE; orchestrator waits for both; `AskUserQuestion` presents both outputs before Step 5
7. Step 5 — qa-tester spawned: test cases for critical path, boundary/edge cases (sequence breaks, softlocks), playtest checklist, acceptance criteria
8. Orchestrator compiles all team outputs into the level design template itself — it does not re-spawn level-designer to do it — then asks via `AskUserQuestion`: "May I write the compiled level design to `design/levels/forest-dungeon.md`?" and writes on approval
9. Summary report: area overview, encounter count, estimated asset list, narrative beats, cross-team dependencies, open cross-level dependencies, accessibility concerns with resolution status; verdict: COMPLETE
10. Next steps listed: `/design-review design/levels/forest-dungeon.md`, `/dev-story`, `/qa-plan`

**Assertions:**
- [ ] Active-set line naming `team.size: studio` appears before the first agent is spawned
- [ ] All five sources read during context gathering before any agent is spawned
- [ ] narrative-director, world-builder and art-director Agent calls are issued in parallel in Step 1, and all three complete before Step 2
- [ ] The level-designer brief carries the art-director's Step 1 visual targets as constraints
- [ ] `AskUserQuestion` called at each step gate (minimum: after Step 1, Step 2, Step 3, Step 4)
- [ ] Step 4 agents (art-director, accessibility-specialist) launched simultaneously
- [ ] The compiled level doc is written by the orchestrator, not a re-spawned agent, and only after its own "May I write" approval
- [ ] Level doc saved to `design/levels/forest-dungeon.md` (slugified from argument)
- [ ] Verdict COMPLETE in final summary report
- [ ] Next steps include `/design-review`, `/dev-story`, `/qa-plan`
- [ ] Summary report includes: area overview, encounter count, estimated asset list, narrative beats

---

### Case 2: Blocked Agent (world-builder) — Partial report produced with gap noted

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- `design/gdd/game-concept.md` exists
- World-building docs for the forest region do NOT exist
- world-builder agent returns BLOCKED: "No world-building docs found for the forest region — cannot provide lore context"

**Input:** `/team-level forest dungeon`

**Expected behavior:**
1. Context gathering completes
2. Step 1 — narrative-director and art-director complete successfully; world-builder returns BLOCKED
3. Error Recovery Protocol triggered: "world-builder: BLOCKED — no world-building docs for forest region"
4. `AskUserQuestion` presented with options:
   - (a) Skip world-builder and note the gap in the final report
   - (b) Retry with narrower scope (world-builder focuses only on what can be inferred from game-concept.md)
   - (c) Stop here and create world-building docs first
5. If user chooses (a): pipeline continues with Steps 2–5 without a lore foundation; the missing world-building context is listed as a gap in the final report
6. If the world-builder remains unresolved, the final report marks the world-builder section BLOCKED and the overall verdict is BLOCKED

**Assertions:**
- [ ] BLOCKED surface message appears immediately when world-builder fails — before Step 2 begins without user input
- [ ] `AskUserQuestion` offers at minimum three options (skip / retry / stop)
- [ ] Partial report produced — narrative-director's and art-director's completed work is not discarded
- [ ] The missing world-building context is named as a gap in the final report
- [ ] Overall verdict is BLOCKED (not COMPLETE) when world-builder remains unresolved
- [ ] Nothing is written in world-builder's place — the protocol's option is "skip this agent and note the gap" (`.claude/docs/error-recovery-protocol.md`), not substitute lore

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `/team-level` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (level name or area to design)
3. Shows the invocation format `/team-level [level name or area to design] [--review full|lean|solo]` with examples (`forest temple`, `tutorial village`, `final boss arena`)
4. Skill exits without reading any project files or spawning any subagents

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message shows the full argument-hint: `/team-level [level name or area to design] [--review full|lean|solo]`
- [ ] At least one example of a valid invocation is shown
- [ ] No GDD or level files read before failing
- [ ] Verdict is NOT shown (pipeline never starts)

---

### Case 4: Accessibility Review Gate — Blocking concern surfaces before sign-off

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- Steps 1–3 complete successfully
- `design/accessibility-requirements.md` committed tier: Standard
- accessibility-specialist (Step 4, parallel) flags a BLOCKING concern: the critical path through the forest dungeon requires players to distinguish between two environmental hazards (toxic pools vs. shallow water) using color alone — no shape, icon, or audio cue differentiates them

**Input:** `/team-level forest dungeon`

**Expected behavior:**
1. Steps 1–3 complete; Step 4 parallel phase begins
2. accessibility-specialist returns: BLOCKING concern — "Critical path hazard distinction relies on color only (toxic pools vs. shallow water). Shape, icon, or audio cue required per Standard accessibility tier."
3. art-director returns Step 4 output (complete)
4. Skill presents both Step 4 results via `AskUserQuestion` — BLOCKING concern highlighted prominently
5. `AskUserQuestion` offers:
   - (a) Return to level-designer + art-director to redesign the flagged elements before Step 5
   - (b) Document as a known accessibility gap and proceed to Step 5 with the concern explicitly logged in the final report
6. Skill does NOT proceed to Step 5 until the user acknowledges the BLOCKING concern
7. Final summary lists the accessibility concern and its resolution status regardless of user choice

**Assertions:**
- [ ] BLOCKING accessibility concern is not treated as advisory — it is surfaced as a blocker
- [ ] `AskUserQuestion` presents the specific concern text (not just "accessibility issue found")
- [ ] Step 5 (qa-tester) does NOT begin without user acknowledging the BLOCKING concern
- [ ] Revision path offered: level-designer + art-director can be sent back before proceeding
- [ ] Final report includes the accessibility concern and its resolution status
- [ ] art-director's completed output is NOT discarded when accessibility-specialist blocks

---

### Case 5: Circular Level Reference — Adjacent area dependency flagged

**Fixture:**
- Resolved config block: `automation: collaborative` (any `team.size` — level-designer is active at every size)
- Steps 1–3 in progress
- level-designer (Step 2) produces a layout that specifies entry/exit points connecting to "the crystal caves" (an adjacent area)
- `design/levels/crystal-caves.md` does NOT exist — the crystal caves area has not been designed yet

**Input:** `/team-level forest dungeon`

**Expected behavior:**
1. Step 2 — level-designer produces layout including: "West exit connects to crystal-caves entry point A"
2. Orchestrator checks `design/levels/` for `crystal-caves.md`; file not found
3. Dependency gap surfaced: "Level references crystal-caves as an adjacent area but `design/levels/crystal-caves.md` does not exist"
4. `AskUserQuestion` presented with options:
   - (a) Proceed with a placeholder reference — note the dependency in the level doc as UNRESOLVED
   - (b) Pause and run `/team-level crystal caves` first to establish that area
5. Skill does NOT invent crystal caves content to satisfy the reference
6. If user chooses (a): level doc compiled with the west exit marked UNRESOLVED; flagged in the open cross-level dependencies section of the summary report
7. Final report includes open cross-level dependencies section

**Assertions:**
- [ ] Skill detects the missing adjacent area by checking `design/levels/` — does not assume it will be created later
- [ ] Skill does NOT fabricate crystal caves content (lore, layout, connections) to resolve the reference
- [ ] `AskUserQuestion` offers a "design crystal caves first" option referencing `/team-level`
- [ ] If user proceeds with placeholder, level doc explicitly marks the west exit as UNRESOLVED
- [ ] Summary report includes an open cross-level dependencies section listing unresolved references
- [ ] Circular or forward references do not cause the skill to loop or crash

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with an `Active set (team.size: individual): level-designer` line and a `Not spawned this run:` line naming every other agent the pipeline names — before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` used at each step transition — user approves before pipeline advances
- [ ] Per-agent artifacts are written by sub-agents to paths the orchestrator named; only the compiled level doc is written by the orchestrator, after its own `AskUserQuestion` approval
- [ ] A step whose named artifact is missing on disk is treated as failed, not done
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] Step 1 (narrative-director, world-builder, art-director) and Step 4 (art-director, accessibility-specialist) launched in parallel per skill spec
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Accessibility BLOCKING concerns surface before Step 5 and require explicit user acknowledgment
- [ ] Verdict is one of COMPLETE / BLOCKED
- [ ] Next steps present at end: `/design-review`, `/dev-story`, `/qa-plan`

---

## Coverage Notes

- The "Retry with narrower scope" option in the blocked world-builder case (Case 2) — the
  retry behavior itself is not tested in depth; its full path is analogous to the blocked agent
  pattern covered in Case 2 and in other team-* specs.
- systems-designer (Step 3) block scenarios are not separately tested; the same Error Recovery
  Protocol applies and the pattern is validated by Case 2.
- Step 4 parallel ordering (art-director completing before or after accessibility-specialist)
  does not affect outcomes — both must return before Step 5 regardless of order.
- The level doc slug rule (lowercase, spaces → hyphens) is exercised by Case 1
  (`forest dungeon` → `forest-dungeon.md`) and Case 5 (`crystal caves` →
  `crystal-caves.md`); special characters and very long names are not covered.
- The `small` active set (systems-designer + art-director added) is not given its own case.
