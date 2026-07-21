# Skill Test Spec: $team-level

## Skill Summary

Orchestrates the full level design team for a single level or area. Coordinates
narrative-director, world-builder, level-designer, systems-designer, art-director,
accessibility-specialist, and qa-tester through five sequential steps with one
parallel phase (Step 4). Compiles all team outputs into a single level design
document saved to `design/levels/[level-name].md`. Uses `AskUserQuestion` at each
step transition. Delegates all file writes to sub-agents. Produces a summary report
with verdict COMPLETE / BLOCKED and handoffs to `$design-review`, `$dev-story`,
`$qa-plan`.

---

## Static Assertions (Structural)

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase/step headings (Step 1 through Step 5 are all present)
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" or "File Write Protocol" — writes delegated to sub-agents, orchestrator does not write files directly
- [ ] Has a next-step handoff at the end (references `$design-review`, `$dev-story`, `$qa-plan`)
- [ ] Error Recovery Protocol section is present with all four recovery steps
- [ ] Uses `AskUserQuestion` at step transitions for user approval before proceeding
- [ ] Step 4 is explicitly marked as parallel (art-director and accessibility-specialist run simultaneously)
- [ ] Context gathering reads: `design/gdd/game-concept.md`, `design/gdd/game-pillars.md`, `design/levels/`, `design/narrative/`, and relevant world-building docs
- [ ] Team Composition lists all seven roles (narrative-director, world-builder, level-designer, systems-designer, art-director, accessibility-specialist, qa-tester)
- [ ] accessibility-specialist output includes severity ratings (BLOCKING / RECOMMENDED / NICE TO HAVE)
- [ ] Final level design document saved to `design/levels/[level-name].md`

---

## Test Cases

### Case 1: Happy Path — All team members produce outputs, document compiled and saved

**Fixture:**
- `design/gdd/game-concept.md` exists and is populated
- `design/gdd/game-pillars.md` exists
- `design/levels/` directory exists (may contain other level docs)
- `design/narrative/` directory exists with relevant narrative docs

**Input:** `$team-level forest dungeon`

**Expected behavior:**
1. Context gathering — orchestrator reads game-concept.md, game-pillars.md, existing level docs in `design/levels/`, narrative docs in `design/narrative/`, and world-building docs for the forest region
2. Step 1 — narrative-director spawned: defines narrative purpose, key characters, dialogue triggers, emotional arc; world-builder spawned: provides lore context, environmental storytelling opportunities, world rules; `AskUserQuestion` confirms Step 1 outputs before Step 2
3. Step 2 — level-designer spawned: designs spatial layout (critical path, optional paths, secrets), pacing curve, encounters, puzzles, entry/exit points and connections to adjacent areas; `AskUserQuestion` confirms layout before Step 3
4. Step 3 — systems-designer spawned: specifies enemy compositions, loot tables, difficulty balance, area-specific mechanics, resource distribution; `AskUserQuestion` confirms systems before Step 4
5. Step 4 — art-director and accessibility-specialist spawned in parallel; art-director: visual theme, color palette, lighting, asset list, VFX needs; accessibility-specialist: navigation clarity, colorblind safety, cognitive load check — each concern rated BLOCKING / RECOMMENDED / NICE TO HAVE; `AskUserQuestion` presents both outputs before Step 5
6. Step 5 — qa-tester spawned: test cases for critical path, boundary/edge cases (sequence breaks, softlocks), playtest checklist, acceptance criteria
7. Orchestrator compiles all team outputs into level design document format; sub-agent asked "May I write to `design/levels/forest-dungeon.md`?"; file saved
8. Summary report: area overview, encounter count, estimated asset list, narrative beats, cross-team dependencies, verdict: COMPLETE
9. Next steps listed: `$design-review design/levels/forest-dungeon.md`, `$dev-story`, `$qa-plan`

**Assertions:**
- [ ] All five sources read during context gathering before any agent is spawned
- [ ] narrative-director and world-builder both spawned in Step 1 (may be sequential or parallel — both must complete before Step 2)
- [ ] `AskUserQuestion` called at each step gate (minimum: after Step 1, Step 2, Step 3, Step 4)
- [ ] Step 4 agents (art-director, accessibility-specialist) launched simultaneously
- [ ] All file writes delegated to sub-agents — orchestrator does not write directly
- [ ] Level doc saved to `design/levels/forest-dungeon.md` (slugified from argument)
- [ ] Verdict COMPLETE in final summary report
- [ ] Next steps include `$design-review`, `$dev-story`, `$qa-plan`
- [ ] Summary report includes: area overview, encounter count, estimated asset list, narrative beats

---

### Case 2: Blocked Agent (world-builder) — Partial report produced with gap noted

**Fixture:**
- `design/gdd/game-concept.md` exists
- World-building docs for the forest region do NOT exist
- world-builder agent returns BLOCKED: "No world-building docs found for the forest region — cannot provide lore context"

**Input:** `$team-level forest dungeon`

**Expected behavior:**
1. Context gathering completes; missing world-building docs noted
2. Step 1 — narrative-director completes successfully; world-builder spawned and returns BLOCKED
3. Error Recovery Protocol triggered: "world-builder: BLOCKED — no world-building docs for forest region"
4. `AskUserQuestion` presented with options:
   - (a) Skip world-builder and note the lore gap in the level doc
   - (b) Retry with narrower scope (world-builder focuses only on what can be inferred from game-concept.md)
   - (c) Stop here and create world-building docs first
5. If user chooses (a): pipeline continues with Steps 2–5 using narrative-director context only; level doc compiled with a clearly marked gap section: "World-building context: NOT PROVIDED — see open dependency"
6. Final report produced: partial outputs documented, world-builder section marked BLOCKED, overall verdict: BLOCKED

**Assertions:**
- [ ] BLOCKED surface message appears immediately when world-builder fails — before Step 2 begins without user input
- [ ] `AskUserQuestion` offers at minimum three options (skip / retry / stop)
- [ ] Partial report produced — narrative-director's completed work is not discarded
- [ ] Level doc (if compiled) contains an explicit gap notation for the missing world-building context
- [ ] Overall verdict is BLOCKED (not COMPLETE) when world-builder remains unresolved
- [ ] Skill does NOT silently fabricate lore content to fill the gap

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `$team-level` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (level name or area to design)
3. Provides example invocations: `$team-level tutorial`, `$team-level forest dungeon`, `$team-level final boss arena`
4. Skill exits without reading any project files or spawning any subagents

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message includes the canonical `$skill-name` invocation syntax
- [ ] At least one example of a valid invocation is shown
- [ ] No GDD or level files read before failing
- [ ] Verdict is NOT shown (pipeline never starts)

---

### Case 4: Accessibility Review Gate — Blocking concern surfaces before sign-off

**Fixture:**
- Steps 1–3 complete successfully
- `design/accessibility-requirements.md` committed tier: Enhanced
- accessibility-specialist (Step 4, parallel) flags a BLOCKING concern: the critical path through the forest dungeon requires players to distinguish between two environmental hazards (toxic pools vs. shallow water) using color alone — no shape, icon, or audio cue differentiates them

**Input:** `$team-level forest dungeon`

**Expected behavior:**
1. Steps 1–3 complete; Step 4 parallel phase begins
2. accessibility-specialist returns: BLOCKING concern — "Critical path hazard distinction relies on color only (toxic pools vs. shallow water). Shape, icon, or audio cue required per Enhanced accessibility tier."
3. art-director returns Step 4 output (complete)
4. Skill presents both Step 4 results via `AskUserQuestion` — BLOCKING concern highlighted prominently
5. `AskUserQuestion` offers:
   - (a) Return to level-designer + art-director to redesign hazard visual/audio language before Step 5
   - (b) Document as a known accessibility gap and proceed to Step 5 with the concern logged
6. Skill does NOT silently proceed past the BLOCKING concern
7. If user chooses (a): level-designer and art-director revision spawned; re-run Step 4 accessibility check
8. Final report includes BLOCKING concern and its resolution status regardless of user choice

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
- Steps 1–3 in progress
- level-designer (Step 2) produces a layout that specifies entry/exit points connecting to "the crystal caves" (an adjacent area)
- `design/levels/crystal-caves.md` does NOT exist — the crystal caves area has not been designed yet

**Input:** `$team-level forest dungeon`

**Expected behavior:**
1. Step 2 — level-designer produces layout including: "West exit connects to crystal-caves entry point A"
2. Orchestrator (or level-designer subagent) checks `design/levels/` for `crystal-caves.md`; file not found
3. Dependency gap surfaced: "Level references crystal-caves as an adjacent area but `design/levels/crystal-caves.md` does not exist"
4. `AskUserQuestion` presented with options:
   - (a) Proceed with a placeholder reference — note the dependency in the level doc as UNRESOLVED
   - (b) Pause and run `$team-level crystal caves` first to establish that area
5. Skill does NOT invent crystal caves content to satisfy the reference
6. If user chooses (a): level doc compiled with the west exit marked "→ crystal-caves (UNRESOLVED — area not yet designed)"; flagged in the open dependencies section of the summary report
7. Final report includes open cross-level dependencies section

**Assertions:**
- [ ] Skill detects the missing adjacent area by checking `design/levels/` — does not assume it will be created later
- [ ] Skill does NOT fabricate crystal caves content (lore, layout, connections) to resolve the reference
- [ ] `AskUserQuestion` offers a "design crystal caves first" option referencing `$team-level`
- [ ] If user proceeds with placeholder, level doc explicitly marks the west exit as UNRESOLVED
- [ ] Summary report includes an open cross-level dependencies section listing unresolved references
- [ ] Circular or forward references do not cause the skill to loop or crash

---

## Protocol Compliance

- [ ] `AskUserQuestion` used at each step transition — user approves before pipeline advances
- [ ] All file writes delegated to sub-agents via Task — orchestrator does not call Write or Edit directly
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] Step 4 agents (art-director, accessibility-specialist) launched in parallel per skill spec
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Accessibility BLOCKING concerns surface before sign-off and require explicit user acknowledgment
- [ ] Verdict is one of COMPLETE / BLOCKED
- [ ] Next steps present at end: `$design-review`, `$dev-story`, `$qa-plan`

---

## Coverage Notes

- narrative-director and world-builder in Step 1 may be sequential or parallel — the skill spec
  spawns both but does not mandate simultaneous launch; coverage of parallel Step 1 would require
  an explicit timing assertion fixture.
- The "Retry with narrower scope" option in the blocked world-builder case (Case 2) — the
  retry behavior itself is not tested in depth; its full path is analogous to the blocked agent
  pattern covered in Case 2 and in other team-* specs.
- systems-designer (Step 3) block scenarios are not separately tested; the same Error Recovery
  Protocol applies and the pattern is validated by Case 2.
- Step 4 parallel ordering (art-director completing before or after accessibility-specialist)
  does not affect outcomes — both must return before Step 5 regardless of order.
- The level doc slug convention (argument → filename) is implicitly tested by Case 1
  (`forest dungeon` → `forest-dungeon.md`); multi-word slugification edge cases (special
  characters, very long names) are not covered.
