# Skill Test Spec: /team-narrative

## Skill Summary

Orchestrates the narrative team through a five-phase pipeline: narrative direction
(narrative-director) → world foundation, dialogue drafting and visual direction
(world-builder, writer and art-director in parallel) → level narrative integration
(level-designer) → consistency review (narrative-director) → polish + localization
compliance (writer, localization-lead, and world-builder in parallel). Phase 0
resolves `review_mode`, `automation` and `team.size` and the skill announces the
active set before Phase 1 — at the default `individual` only writer is spawned
(narrative-director only on an explicit pillar conflict), `small` adds
narrative-director, plus localization-lead and world-builder when `review_mode` is
`full`, and `studio` activates every narrative agent whatever the review mode. Each agent drafts to a concrete path
under `production/narrative/[content-slug]/` named in the skill's path table;
Phase 4 runs the ND-CONSISTENCY gate; the orchestrator writes the final documents
to `design/narrative/` after one approval. Uses
`AskUserQuestion` at each phase transition. Produces a narrative summary report.
Verdict is COMPLETE when all phases succeed — `COMPLETE — consistency NOT ASSESSED
([input])` when the ND-CONSISTENCY review could not assess — or BLOCKED when a
dependency is unresolved.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "File Write Protocol" section
- [ ] Sub-agents write drafts under `production/narrative/[content-slug]/`; the orchestrator writes only the final `design/narrative/` documents, after one "May I write" approval
- [ ] Names a concrete draft path per agent (including level-designer and localization-lead) and the final `design/narrative/` document each design artifact becomes — localization-lead's review is not one, and stays in `production/`
- [ ] Every agent prompt ends with the return contract: path written, ≤5-bullet summary, BLOCKED/CONCERNS items one line each
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] Has a next-step handoff at the end (references `/design-review`, `/localize extract`, `/dev-story`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk, surface BLOCKED immediately, always produce a partial report, full procedure in `.claude/docs/error-recovery-protocol.md`
- [ ] `AskUserQuestion` is used at phase transitions before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Phase 1
- [ ] Phase 2 explicitly spawns world-builder, writer and art-director in parallel
- [ ] Phase 5 explicitly spawns writer, localization-lead, and world-builder in parallel

---

## Test Cases

### Case 1: Happy Path — All five phases complete, narrative doc delivered

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- A game concept and GDD exist for the target feature (e.g., `design/gdd/faction-intro.md`)
- Character voice profiles exist (e.g., `design/narrative/characters/`)
- Existing lore entries exist for cross-reference (e.g., `design/narrative/lore/`)
- No lore contradictions exist between existing entries and the new content

**Input:** `/team-narrative faction introduction cutscene for the Ironveil faction`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: studio`
2. Phase 1: narrative-director is spawned; writes a narrative brief draft to `production/narrative/[content-slug]/brief.md` defining the story beat, characters involved, emotional tone, and lore dependencies
3. `AskUserQuestion` presents the narrative brief; user approves before Phase 2 begins
4. Phase 2: world-builder, writer and art-director are spawned in parallel; world-builder drafts Ironveil lore entries, writer drafts dialogue using character voice profiles, and art-director drafts visual direction — each under `production/narrative/[content-slug]/`
5. Phase gate: all three Phase 2 outputs are collected, then `AskUserQuestion` presents the lore, dialogue and visual direction summaries; user approves before Phase 3 begins
6. Phase 3: level-designer is spawned; produces environmental storytelling layout, trigger placement, and pacing plan
7. `AskUserQuestion` presents level narrative plan; user approves before Phase 4 begins
8. Phase 4: narrative-director is spawned with the ND-CONSISTENCY gate; reviews voices, lore and pacing and returns APPROVE
9. `AskUserQuestion` presents review results; user approves before Phase 5 begins
10. Phase 5: writer, localization-lead, and world-builder are spawned in parallel; writer performs final self-review; localization-lead validates i18n compliance; world-builder finalizes canon levels
11. The orchestrator lists the final documents and asks once, "May I write these [N] narrative documents to `design/narrative/`?"; on approval it writes them
12. Final summary report is presented
13. Verdict: COMPLETE

**Assertions:**
- [ ] Active-set line naming `team.size: studio` appears before the first agent is spawned
- [ ] narrative-director is spawned in Phase 1 before any other agents
- [ ] `AskUserQuestion` appears after Phase 1 output and before Phase 2 launch
- [ ] world-builder, writer and art-director Agent calls are issued simultaneously in Phase 2 (not sequentially)
- [ ] level-designer is not launched until Phase 2 `AskUserQuestion` is approved
- [ ] narrative-director is re-spawned in Phase 4 using gate ND-CONSISTENCY — in every review mode, since it is this pipeline's own review and `review_mode` never skips it — and its APPROVE / CONCERNS / REJECT verdict decides whether Phase 5 starts
- [ ] Phase 5 spawns all three agents (writer, localization-lead, world-builder) simultaneously
- [ ] Each agent prompt names its draft path from the skill's path table
- [ ] Nothing is written under `design/narrative/` before the single "May I write" approval
- [ ] Summary report includes: narrative brief status, lore entries created/updated, dialogue lines written, level narrative integration points, consistency review results
- [ ] The orchestrator writes nothing except the approved final documents
- [ ] Verdict is COMPLETE after delivery

---

### Case 2: Lore Contradiction Found — world-builder finds conflict before writer proceeds

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- Existing lore entry at `design/narrative/lore/ironveil-history.md` states the Ironveil faction was founded 200 years ago
- The new narrative brief (from Phase 1) states the Ironveil were founded 50 years ago
- The writer has been spawned in parallel with the world-builder in Phase 2

**Input:** `/team-narrative ironveil faction introduction cutscene`

**Expected behavior:**
1. Phases 1–2 begin normally
2. Phase 2 world-builder detects a factual contradiction between the narrative brief and existing lore: founding date conflict
3. world-builder returns BLOCKED with reason: "Lore contradiction found — founding date conflicts with `design/narrative/lore/ironveil-history.md`"
4. Orchestrator surfaces the contradiction immediately: "world-builder: BLOCKED — Lore contradiction: founding date in narrative brief (50 years ago) conflicts with existing canon (200 years ago in `ironveil-history.md`)"
5. Orchestrator assesses dependency: the writer's dialogue depends on canon lore — the writer's draft cannot be finalized without resolving the contradiction
6. `AskUserQuestion` presents the error-recovery options:
   - Skip world-builder and note the gap in the final report
   - Retry with narrower scope (e.g., world-builder works against the canon the user confirms)
   - Stop here and resolve the contradiction in the lore docs first
7. Writer output is preserved in the partial report — work is not discarded
8. Orchestrator does NOT proceed to Phase 3 until the contradiction is resolved or user explicitly chooses to skip

**Assertions:**
- [ ] Contradiction is surfaced before Phase 3 begins
- [ ] Orchestrator does not silently resolve the contradiction by picking one version
- [ ] `AskUserQuestion` presents at least 3 options including "stop and resolve first"
- [ ] Writer's draft output is preserved in the partial report, not discarded
- [ ] Phase 3 (level-designer) is not launched until the user resolves the contradiction or explicitly chooses to skip world-builder
- [ ] Verdict is BLOCKED (not COMPLETE) if the user stops to resolve the contradiction

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `/team-narrative` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Outputs usage guidance: e.g., "Usage: `/team-narrative [narrative content description] [--review full|lean|solo]` — describe the story content, scene, or narrative area to work on (e.g., `boss encounter cutscene`, `faction intro dialogue`, `tutorial narrative`)"
3. Skill exits without spawning any agents

**Assertions:**
- [ ] Skill does NOT spawn any agents when no argument is provided
- [ ] Usage message shows the full argument-hint — `/team-narrative [narrative content description] [--review full|lean|solo]` — and an argument example
- [ ] Skill does NOT attempt to guess or infer a narrative topic from project files
- [ ] No `AskUserQuestion` is used — output is direct guidance

---

### Case 4: Localization Compliance — localization-lead blocks on a non-translatable string

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- Phases 1–4 complete successfully
- Phase 5 begins; writer and world-builder complete without issues
- localization-lead finds a dialogue line that uses a hardcoded formatted date string (e.g., `"On March 12th, Year 3"`) that cannot survive locale-specific translation without a locale-aware formatter, and returns it as a BLOCKED item in its return contract

**Input:** `/team-narrative ironveil faction introduction cutscene` (Phase 5 scenario)

**Expected behavior:**
1. Phase 5 spawns writer, localization-lead, and world-builder in parallel
2. localization-lead returns BLOCKED: "String key `dialogue.ironveil.intro.003` contains a hardcoded date format (`March 12th, Year 3`) that will not localize correctly — requires a locale-aware date placeholder"
3. Orchestrator surfaces it immediately: "localization-lead: BLOCKED — [reason with the string key]"
4. writer's and world-builder's Phase 5 outputs are kept in the partial report
5. `AskUserQuestion` presents the error-recovery options:
   - Skip and note the gap in the final report (deliver with the string flagged)
   - Retry with narrower scope (e.g., the writer revises that one line, then localization-lead re-checks it)
   - Stop and resolve before finalizing
6. If the user skips, the final summary lists the unfixed string key among its unresolved items; if the user stops, the verdict is `BLOCKED — [reason]`

**Assertions:**
- [ ] localization-lead is spawned in Phase 5 simultaneously with writer and world-builder
- [ ] Hardcoded date format is identified as a localization blocker (not silently passed)
- [ ] The specific string key and reason are included in the surfaced BLOCKED message
- [ ] `AskUserQuestion` offers skip-and-note-gap, retry, and stop options
- [ ] If the user proceeds without fixing, the final report names the unfixed string key; if the user stops, the verdict is BLOCKED
- [ ] Skill does NOT automatically rewrite the offending line without user approval

---

### Case 5: Writer Blocked — Missing character voice profiles

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- Phase 1 narrative-director produces a narrative brief referencing two characters: Commander Varek and Advisor Selene
- No character voice profiles exist in `design/narrative/characters/` for either character
- Phase 2 begins; world-builder and art-director proceed normally

**Input:** `/team-narrative ironveil surrender negotiation scene`

**Expected behavior:**
1. Phase 1 completes; narrative brief lists Commander Varek and Advisor Selene as characters
2. Phase 2: writer is spawned in parallel with world-builder and art-director
3. writer returns BLOCKED: "Cannot produce dialogue — no voice profiles found for Commander Varek or Advisor Selene in `design/narrative/characters/`. Voice profiles required to match character tone and speech patterns."
4. Orchestrator surfaces the blocker immediately: "writer: BLOCKED — Missing prerequisite: character voice profiles for Commander Varek and Advisor Selene"
5. world-builder output is preserved; partial report is produced with lore entries
6. `AskUserQuestion` presents the error-recovery options:
   - Skip writer and note the gap in the final report
   - Retry with narrower scope (e.g., minimal voice direction supplied inline)
   - Stop here and create voice profiles before proceeding
7. Orchestrator does NOT proceed to Phase 3 (level-designer) without writer output unless the user explicitly chooses to skip

**Assertions:**
- [ ] Writer block is surfaced before Phase 3 begins
- [ ] world-builder's completed lore output is preserved in the partial report
- [ ] Missing prerequisite (voice profiles) is named specifically (character names and expected file path)
- [ ] `AskUserQuestion` offers at least one option to resolve the missing prerequisite
- [ ] Orchestrator does not fabricate voice profiles or invent character voices
- [ ] Phase 3 is not launched while writer is BLOCKED without explicit user authorization

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with `Active set (team.size: individual): writer.` and a `Not spawned this run:` line naming narrative-director, world-builder, art-director, level-designer and localization-lead, consulted through writer — before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` is used after every phase output before the next phase launches
- [ ] Parallel spawning: Phase 2 (world-builder + writer + art-director) and Phase 5 (writer + localization-lead + world-builder) issue all Agent calls before waiting for results
- [ ] No write under `design/` happens without a "May I write" approval — `design/` is outside the bounded exception (`production/`, `docs/`, `tests/`)
- [ ] At `team.size: individual`, Phase 4 does not spawn narrative-director; the output says "ND-CONSISTENCY not run — narrative-director is not active at `team.size: individual`; consistency self-checked by writer." and never presents the writer's self-check as the gate's verdict
- [ ] An ND-CONSISTENCY `NOT ASSESSED [missing input]` answer is never treated as APPROVE: the missing input is named, then either supplied and the gate re-run, or `ND-CONSISTENCY: NOT ASSESSED — [input]` is carried into the report's consistency review results and the verdict reads `COMPLETE — consistency NOT ASSESSED ([input])`, never a plain COMPLETE
- [ ] A phase whose named artifact is missing on disk is treated as failed, not done
- [ ] BLOCKED status from any agent is surfaced immediately — not silently skipped
- [ ] A partial report is always produced when some agents complete and others block
- [ ] Verdict is exactly COMPLETE, `COMPLETE — consistency NOT ASSESSED ([input])` or BLOCKED — no other verdict values used
- [ ] Next Steps handoff references `/design-review`, `/localize extract`, and `/dev-story`

---

## Coverage Notes

- Phase 3 (level-designer) and Phase 4 (narrative-director review) happy-path behavior are
  validated implicitly by Case 1. Separate edge cases are not needed for these phases as
  their failure modes follow the standard Error Recovery Protocol.
- The "Retry with narrower scope" and "Skip this agent" resolution paths from the Error
  Recovery Protocol are not separately walked to completion — Cases 2, 4 and 5 check that
  they are offered.
- Advisory localization concerns (e.g., German/Finnish +30% expansion warnings) are not
  given a case; Case 4 covers only a concern the localization-lead returns as BLOCKED.
- The writer's "all lines under 120 characters" and "string keys not raw strings" checks
  in Phase 5 are covered implicitly by Case 4's localization compliance scenario.
- The `small` active set (review_mode-dependent localization-lead and world-builder) is not
  given its own case.
