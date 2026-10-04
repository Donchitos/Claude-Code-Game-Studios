# Skill Test Spec: /team-audio

## Skill Summary

Orchestrates the audio team through a four-step pipeline: audio direction
(audio-director) → sound design + accessibility review in parallel (sound-designer
+ accessibility-specialist) → technical implementation + engine validation in
parallel (technical-artist + primary engine specialist) → code integration
(gameplay-programmer). Phase 0 resolves `review_mode`, `automation` and
`team.size`, and the skill announces the active agent set in one line before
Step 1 — at the default `team.size: individual` only sound-designer is spawned and
every other agent is consulted through it. Reads relevant GDDs, the sound bible (if
present), and existing audio asset lists before spawning agents. Sub-agents write
their working artifacts to paths the orchestrator names, under the bounded write
exception; the orchestrator compiles the audio design document itself and writes it
to `design/audio/audio-[feature].md` only after asking via `AskUserQuestion`. Uses
`AskUserQuestion` at each step transition. Verdict is COMPLETE when the audio design
document is produced, BLOCKED when an unresolved dependency stops the pipeline.
Skips the engine specialist when no engine is configured and records
`Engine validation: NOT ASSESSED`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 step/phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "File Write Protocol" section
- [ ] Sub-agent writes are limited to the bounded exception — a path the orchestrator named, a new artifact under `production/`, `docs/` or `tests/`, in a step gated by `AskUserQuestion`; no per-write prompt inside those bounds, a "May I write" ask outside them; implementation files (code, shaders, audio, assets) are outside it — each agent lists the files it will create or change, and the skill asks once for the set before any is written
- [ ] Names a destination per agent under `production/audio/[feature]/`: `direction.md` (audio-director), `sfx-spec.md` (sound-designer), `accessibility.md` (accessibility-specialist), `integration-plan.md` (technical-artist), `engine-notes.md` (engine specialist)
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] The compiled audio design document is written by the orchestrator only after it asks via `AskUserQuestion` "May I write the audio design to `design/audio/audio-[feature].md`?" (`design/` is outside the bounded exception)
- [ ] Every agent prompt ends with the return contract: path written, ≤5-bullet summary, BLOCKED/CONCERNS items one line each
- [ ] Has a next-step handoff at the end (references `/dev-story`, `/asset-audit`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk before treating a step as done, surface BLOCKED immediately, always produce a partial report, full procedure in `.claude/docs/error-recovery-protocol.md`
- [ ] `AskUserQuestion` is used at step transitions before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `review_mode`, `automation` and `team.size`, and requires a one-line active-set announcement before Step 1
- [ ] Step 2 explicitly spawns sound-designer and accessibility-specialist in parallel, and How to Delegate lists `accessibility-specialist`
- [ ] Step 2 labels a gameplay-critical audio event with no visual cue or subtitle BLOCKING, and Step 3 waits for the user to resolve or accept it
- [ ] Step 3 explicitly spawns technical-artist and engine specialist in parallel (when engine is configured)
- [ ] Skill reads the sound bible at `design/audio/sound-bible.md` during context gathering if it exists; a sound bible still at `design/gdd/sound-bible.md` (the earlier location) is read, with a recommendation to move it
- [ ] Output document is saved to `design/audio/audio-[feature].md`

---

## Test Cases

### Case 1: Happy Path — All steps complete, audio design document saved

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- `engine.name` in `project.yaml` is Godot
- GDD for the target feature exists at `design/gdd/combat.md`
- Sound bible exists at `design/audio/sound-bible.md`
- Existing audio assets are listed in `assets/audio/`
- No accessibility gaps exist in the planned audio event list

**Input:** `/team-audio combat`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: studio`
2. Context gathering: orchestrator reads `design/gdd/combat.md`, `design/audio/sound-bible.md`, and `assets/audio/` asset list before spawning any agent
3. Step 1: audio-director is spawned; defines sonic identity, emotional tone, adaptive music direction, mix targets, and adaptive audio rules for combat
4. `AskUserQuestion` presents audio direction; user approves before Step 2 begins
5. Step 2: sound-designer and accessibility-specialist are spawned in parallel; sound-designer produces SFX specifications, audio event list with trigger conditions, and mixing groups; accessibility-specialist identifies critical gameplay audio events and specifies visual fallback and subtitle requirements
6. `AskUserQuestion` presents SFX spec and accessibility requirements; user approves before Step 3 begins
7. Step 3: technical-artist and `godot-specialist` (derived from `engine.name`) are spawned in parallel; technical-artist designs bus structure, middleware integration, memory budgets, and streaming strategy; engine specialist validates that the integration approach is idiomatic for the pinned engine
8. `AskUserQuestion` presents technical plan; user approves before Step 4 begins
9. Step 4: gameplay-programmer is spawned; first returns the code and test files it will create or change, the orchestrator asks once for that set, and only after the yes it wires up audio events to gameplay triggers, implements adaptive music, sets up occlusion zones and writes unit tests for audio event triggers
10. For every step, the orchestrator checks that the path named in the agent's return contract exists before treating the step as done
11. Orchestrator compiles all outputs into a single audio design document itself (no sub-agent is re-spawned to write it)
12. Orchestrator asks via `AskUserQuestion`: "May I write the audio design to `design/audio/audio-combat.md`?" and writes it only on approval
13. Summary output lists: audio event count, estimated asset count, implementation tasks, and any open questions
14. Verdict: COMPLETE

**Assertions:**
- [ ] Active-set line naming `team.size: studio` appears before the first agent is spawned
- [ ] Sound bible is read during context gathering (before Step 1) when it exists
- [ ] audio-director is spawned before sound-designer or accessibility-specialist
- [ ] `AskUserQuestion` appears after Step 1 output and before Step 2 launch
- [ ] sound-designer and accessibility-specialist Agent calls are issued simultaneously in Step 2
- [ ] technical-artist and `godot-specialist` Agent calls are issued simultaneously in Step 3
- [ ] gameplay-programmer is not launched until Step 3 `AskUserQuestion` is approved
- [ ] gameplay-programmer writes no code or test file before the one ask for its implementation set is answered yes
- [ ] Audio design document is written to `design/audio/audio-combat.md` (not another path), by the orchestrator, only after its `AskUserQuestion` approval
- [ ] Summary includes audio event count and estimated asset count
- [ ] Verdict is COMPLETE after document delivery

---

### Case 2: Accessibility Gap — Critical gameplay audio event has no visual fallback

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- GDD for the target feature exists
- Step 1 and Step 2 are in progress
- sound-designer's audio event list includes "EnemyNearbyAlert" — a spatial audio cue that warns the player an enemy is approaching from off-screen
- accessibility-specialist reviews the event list and finds "EnemyNearbyAlert" has no visual fallback (no on-screen indicator, no subtitle, no controller rumble specified)

**Input:** `/team-audio stealth` (Step 2 scenario)

**Expected behavior:**
1. Steps 1–2 proceed; accessibility-specialist and sound-designer are spawned in parallel
2. accessibility-specialist returns its review with a BLOCKING concern: "`EnemyNearbyAlert` is a critical gameplay audio event (warns player of off-screen threat) with no visual fallback — hearing-impaired players cannot detect this threat."
3. Orchestrator writes the concern in conversation before presenting `AskUserQuestion`
4. `AskUserQuestion` presents the accessibility concern as a BLOCKING issue with options such as:
   - Add a visual indicator for EnemyNearbyAlert (e.g., directional arrow on HUD) and continue
   - Add controller haptic feedback as the fallback and continue
   - Stop here and resolve all accessibility gaps before proceeding to Step 3
5. Step 3 (technical-artist + engine specialist) is not launched until the user resolves or explicitly accepts the gap
6. If the user stops: a partial report of the Step 1–2 outputs is produced and the verdict is `BLOCKED — [reason]` naming the unresolved EnemyNearbyAlert gap
7. If the user accepts the gap and continues: the gap is listed among the open questions in the final summary

**Assertions:**
- [ ] Accessibility gap is labeled BLOCKING (not advisory) in the report
- [ ] The specific event name ("EnemyNearbyAlert") and the nature of the gap are stated
- [ ] `AskUserQuestion` surfaces the gap before Step 3 is launched
- [ ] At least one resolution option is offered (add visual fallback, add haptic fallback)
- [ ] Step 3 is not launched while the gap is unresolved without explicit user authorization
- [ ] If the user stops, the verdict is `BLOCKED — [reason]` naming the gap and the Step 1–2 outputs are kept in a partial report; if the user carries it forward, the final summary lists it as an open question

---

### Case 3: No Argument — Usage guidance or design doc inference

**Fixture:**
- Any project state

**Input:** `/team-audio` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Outputs usage guidance: e.g., "Usage: `/team-audio [feature or area to design audio for] [--review full|lean|solo]` — specify the feature or area to design audio for (e.g., `combat`, `main menu`, `forest biome`, `boss encounter`)"
3. Skill exits without spawning any agents

**Assertions:**
- [ ] Skill does NOT spawn any agents when no argument is provided
- [ ] Usage message shows the full argument-hint — `/team-audio [feature or area to design audio for] [--review full|lean|solo]` — and argument examples
- [ ] Skill does NOT attempt to infer a feature from existing design docs without user direction
- [ ] No `AskUserQuestion` is used — output is direct guidance

---

### Case 4: Missing Sound Bible — Skill notes the gap and proceeds without it

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- GDD for the target feature exists at `design/gdd/main-menu.md`
- No sound bible exists at `design/audio/sound-bible.md` or `design/gdd/sound-bible.md`
- Engine is configured; other context files are present

**Input:** `/team-audio main menu`

**Expected behavior:**
1. Context gathering: orchestrator reads `design/gdd/main-menu.md` and checks for `design/audio/sound-bible.md`
2. Sound bible is not found; orchestrator notes the gap in one line: "No sound bible at `design/audio/sound-bible.md`; audio direction starts from the GDDs alone"
3. Pipeline proceeds normally through all four steps without the sound bible as input
4. audio-director in Step 1 is informed that no sound bible exists and must establish sonic identity from the feature GDD alone
5. Next Steps recommends creating the sound bible and says who writes it: the `audio-director` agent drafts `design/audio/sound-bible.md` from `.claude/docs/templates/sound-bible.md`, starting from this run's Step 1 direction, and asks before writing

**Assertions:**
- [ ] Orchestrator checks for the sound bible during context gathering (before Step 1)
- [ ] Missing sound bible is noted explicitly in conversation — not silently ignored
- [ ] Pipeline does NOT halt due to the missing sound bible
- [ ] audio-director is notified that no sound bible exists in its prompt context
- [ ] Next Steps recommends creating a sound bible and names its author — the `audio-director`, drafting from `.claude/docs/templates/sound-bible.md`
- [ ] The skill does not write `design/audio/sound-bible.md` itself in this run
- [ ] Verdict is still COMPLETE if all other steps succeed

---

### Case 5: Engine Not Configured — Engine specialist step skipped and recorded

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`
- `engine.name` is unset in `project.yaml`, and `.claude/docs/technical-preferences.md` has no Primary engine specialist (shows `[TO BE CONFIGURED]`)
- GDD for the target feature exists
- Sound bible may or may not exist

**Input:** `/team-audio boss encounter`

**Expected behavior:**
1. Steps 1–2 proceed normally (audio-director, sound-designer, accessibility-specialist)
2. Step 3: technical-artist is spawned normally; engine specialist spawn is SKIPPED
3. The run output records: `Engine validation: NOT ASSESSED — no engine configured (engine.name unset in project.yaml)`
4. Step 4: gameplay-programmer still runs — the missing engine is not treated as a blocker
5. Verdict: `COMPLETE — engine validation NOT ASSESSED (no engine configured)` — the skip is graceful, not a blocker, and never a plain COMPLETE

**Assertions:**
- [ ] Engine specialist is NOT spawned when no engine is configured
- [ ] Skill does NOT error out due to the missing engine configuration
- [ ] The run output contains `Engine validation: NOT ASSESSED — no engine configured` with the `engine.name` reason — the skip is not silently omitted
- [ ] Engine integration is never described as validated or passed in this run
- [ ] technical-artist is still spawned in Step 3 (skip applies only to the engine specialist)
- [ ] gameplay-programmer still runs in Step 4
- [ ] Verdict is `COMPLETE — engine validation NOT ASSESSED (…)`, never a plain COMPLETE (engine not configured is a graceful case, not a blocker)

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with `Active set (team.size: individual): sound-designer.` and a `Not spawned this run:` line naming audio-director, accessibility-specialist, technical-artist, the engine specialist and gameplay-programmer, consulted through sound-designer — before any agent is spawned
- [ ] Context gathering (GDDs, sound bible, asset list) runs before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` is used after every step output before the next step launches
- [ ] Parallel spawning: Step 2 (sound-designer + accessibility-specialist) and Step 3 (technical-artist + engine specialist) issue all Agent calls before waiting for results
- [ ] Sub-agents write only to paths the orchestrator named; they skip the per-write prompt only inside the bounded exception (`production/`, `docs/`, `tests/`)
- [ ] The orchestrator writes the compiled audio design document only after an explicit `AskUserQuestion` approval
- [ ] A step whose named artifact is missing on disk is treated as failed and the agent is resumed — not reported as done
- [ ] BLOCKED status from any agent is surfaced immediately as "[AgentName]: BLOCKED — [reason]" — not silently skipped
- [ ] A partial report is always produced when some agents complete and others block
- [ ] Audio design document path follows the pattern `design/audio/audio-[feature].md`
- [ ] Verdict is exactly COMPLETE (qualified `— engine validation NOT ASSESSED ([reason])` when that step was skipped) or BLOCKED — no other verdict values used
- [ ] Next Steps handoff references `/dev-story` and `/asset-audit`

---

## Coverage Notes

- The "Retry with narrower scope" and "Skip this agent" resolution paths from the Error
  Recovery Protocol are not separately tested — they follow the same `AskUserQuestion`
  + partial-report pattern validated in Cases 2 and 5.
- Step 4 (gameplay-programmer) happy-path behavior is validated implicitly by Case 1.
  Failure modes for this step follow the standard Error Recovery Protocol.
- The accessibility-specialist's subtitle and caption requirements (beyond visual fallbacks)
  are validated implicitly by Case 1. Case 2 focuses on the more severe case where a
  critical gameplay event has no fallback at all.
- Engine specialist validation logic (idiomatic integration, version-specific changes) is
  tested only for the configured and unconfigured states. The specific content of the
  engine specialist's output is out of scope for this behavioral spec.
- `guided` and `autonomous` automation modes (auto-advance, `log_decision`) are not given
  dedicated cases; the individual-size collapse is covered by the Protocol Compliance
  announcement check rather than a full run.
