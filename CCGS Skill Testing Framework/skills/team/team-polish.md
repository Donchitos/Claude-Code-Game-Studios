# Skill Test Spec: /team-polish

## Skill Summary

Orchestrates the polish team through a six-phase pipeline: performance assessment
(performance-analyst, whose report carries the optimisation list with an owner per
item) → optimization (the list implemented by its owners in the active set —
engine-programmer for engine-level root causes, tools-programmer for a content
tool; performance-analyst writes no game code) → visual polish
(technical-artist, parallel with Phase 2) → audio polish (sound-designer, parallel
with Phase 2) → hardening (qa-tester) → sign-off (orchestrator collects all results
and issues READY FOR RELEASE, NOT ASSESSED or NEEDS MORE WORK — NOT ASSESSED when a
budget is uncommitted or a phase did not run). Phase 0 resolves `review_mode`,
`automation` and `team.size` and the skill announces the active set before Phase 1
— the default `individual` spawns performance-analyst + technical-artist only, so
no programmer is active and the report names the optimisation list as handed to
`/dev-story`; `small` adds sound-designer, qa-tester and engine-programmer (the full
pipeline); `studio` keeps that set and adds an adversarial pass. Each agent writes a
date-stamped report to a named path under `production/polish/` under the bounded
write exception (no per-write prompt), and the orchestrator states that nothing
reads `production/polish/` yet. The code, shader, audio and asset changes of
Phases 2–4 are outside that exception: one ask covers the whole set. Uses
`AskUserQuestion` at each phase transition. Engine-programmer is spawned
conditionally only when Phase 1 identifies engine-level root causes.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: READY FOR RELEASE, NOT ASSESSED, NEEDS MORE WORK — and states that NOT ASSESSED ranks above READY FOR RELEASE and below NEEDS MORE WORK
- [ ] Contains "File Write Protocol" section
- [ ] File writes are delegated to sub-agents — orchestrator does not write files directly
- [ ] Names a destination per agent under `production/polish/`: `[area]-report-[date].md` (performance-analyst), `[area]-render-notes-[date].md` (technical-artist), `[area]-engine-fixes-[date].md` (engine-programmer), `[area]-tool-fixes-[date].md` (tools-programmer), `[area]-audio-notes-[date].md` (sound-designer), `[area]-verification-[date].md` (qa-tester)
- [ ] Sub-agents write those named `production/` paths without a per-write prompt (bounded exception), and must ask for any write outside it; implementation files (code, shaders, audio, assets) are outside it — each agent lists the files it will create or change, and the skill asks once for the set before any is written — one ask for the whole Phase 2–4 set, never one per phase
- [ ] The `small` and `studio` sets include `engine-programmer`; at `individual` no programmer is active and the report names the optimisation list as handed to `/dev-story`
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] Has a next-step handoff at the end (references `/release-checklist`, `/sprint-plan update`, `/gate-check`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk, surface BLOCKED immediately, always produce a partial report, full procedure in `.claude/docs/error-recovery-protocol.md`
- [ ] `AskUserQuestion` is used at phase transitions before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Phase 1
- [ ] Phase 3 (visual polish) and Phase 4 (audio polish) are explicitly run in parallel with Phase 2
- [ ] Phase 1's report carries the optimisation list with an owner per item; performance-analyst writes no game code in any phase
- [ ] engine-programmer is conditionally spawned in Phase 2 only when Phase 1 identifies engine-level root causes
- [ ] Phase 6 sign-off compares metrics against budgets before issuing verdict
- [ ] Phase 6 lists every remaining issue with its severity, the measured gap where there is one (e.g. "3 ms over budget") and a recommendation

---

## Test Cases

### Case 1: Happy Path — Full pipeline completes, READY FOR RELEASE verdict

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- Feature exists and is functionally complete (e.g., `combat` system)
- Performance budgets are defined in `project.yaml` (`performance.target_framerate: 60`, `performance.frame_budget_ms: 16.6`, `performance.draw_call_limit: 2000`, `performance.memory_ceiling_mb: 2048`)
- No frame budget violations exist before polishing begins
- No audio events are missing; VFX assets are complete
- No regressions are introduced by polish changes

**Input:** `/team-polish combat`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: small` (the full pipeline)
2. Phase 1: performance-analyst is spawned; profiles the combat system, measures frame budget, checks memory usage; writes `production/polish/combat-report-[date].md` showing all metrics within budget
3. `AskUserQuestion` presents performance report; user approves before Phases 2, 3, and 4 begin
4. Phase 2: the report's optimisation list holds only minor rendering items (e.g., draw call batching), owned by technical-artist, so they join its Phase 3 brief; no engine-level root cause was identified, so engine-programmer is not spawned; performance-analyst changes no code
5. Phases 3 and 4 are launched in parallel alongside Phase 2:
   - Phase 3: technical-artist reviews VFX for quality, optimizes particle systems, adds screen shake and visual juice; writes `production/polish/combat-render-notes-[date].md`
   - Phase 4: sound-designer reviews audio events for completeness, checks mix levels, adds ambient audio layers; writes `production/polish/combat-audio-notes-[date].md`
   - The agents changing shaders, VFX or assets first list the files; one `AskUserQuestion` covers the whole Phase 2–4 set, and nothing is edited before the yes
6. All three parallel phases complete; `AskUserQuestion` presents results; user approves before Phase 5 begins
7. Phase 5: qa-tester runs edge case tests, soak tests, stress tests, and regression tests; all pass; writes `production/polish/combat-verification-[date].md`
8. `AskUserQuestion` presents test results; user approves before Phase 6
9. Phase 6: orchestrator collects all results; compares before/after performance metrics against budgets; all metrics pass
10. The report says the `production/polish/` files are a record that nothing in the repo reads yet
11. Verdict: READY FOR RELEASE

**Assertions:**
- [ ] Active-set line naming `team.size: small` appears before the first agent is spawned
- [ ] performance-analyst is spawned first in Phase 1 before any other agents
- [ ] `AskUserQuestion` appears after Phase 1 output and before Phases 2/3/4 launch
- [ ] Phases 3 and 4 Agent calls are issued at the same time as Phase 2 (not after Phase 2 completes)
- [ ] engine-programmer is NOT spawned when Phase 1 finds no engine-level root causes
- [ ] performance-analyst edits no code, shader or asset in any phase
- [ ] Implementation files of Phases 2–4 are listed by each agent and asked for in one `AskUserQuestion` for the whole set — not once per phase — before any is edited
- [ ] qa-tester (Phase 5) is not launched until the parallel phases complete and user approves
- [ ] Each agent writes to its named `production/polish/[area]-…-[date].md` path without a per-write prompt, and the orchestrator confirms the file exists before treating the phase as done
- [ ] Phase 6 verdict is based on comparison of metrics against defined budgets
- [ ] Summary report includes: before/after performance metrics, visual polish changes, audio polish changes, test results
- [ ] Summary states that nothing reads `production/polish/` yet
- [ ] No files are written by the orchestrator directly
- [ ] Verdict is READY FOR RELEASE

---

### Case 2: Performance Blocker — Frame budget violation cannot be fully resolved

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- Feature being polished: `particle-storm` VFX system
- Phase 1 identifies a frame budget violation: particle-storm costs 12ms on target hardware (budget is 6ms for this system)
- Phase 1's optimisation list assigns the particle work to technical-artist and an engine-level particle-update hot path to engine-programmer; after both are applied the cost is 9ms — still over the 6ms budget
- Phase 2 cannot fully resolve the violation without a fundamental design change

**Input:** `/team-polish particle-storm`

**Expected behavior:**
1. Phase 1: performance-analyst identifies the 12ms frame cost vs. 6ms budget; reports "FRAME BUDGET VIOLATION: particle-storm costs 12ms, budget is 6ms", with an optimisation list naming each item's owner
2. `AskUserQuestion` presents the violation; user chooses to proceed with optimization attempt
3. Phase 2: engine-programmer implements the engine-level item and technical-artist the particle items (after the one ask for the set); the re-profile reads 9ms — reduced but still over budget: "Optimization reduced cost to 9ms (was 12ms) — 3ms over budget. No further gains achievable without design changes."
4. Phases 3 and 4 run in parallel with Phase 2 (visual and audio polish)
5. Phase 5: qa-tester runs regression and edge case tests; all pass
6. Phase 6: orchestrator collects results; frame budget violation (9ms vs 6ms budget) remains unresolved
7. Verdict: NEEDS MORE WORK
8. Report lists the specific unresolved issue with severity: "particle-storm frame cost (9ms) exceeds budget (6ms) by 3ms — requires design scope reduction or budget renegotiation"
9. Next Steps: schedule the remaining issue in `/sprint-plan update`; re-run `/team-polish` after fix

**Assertions:**
- [ ] Frame budget violation is flagged in Phase 1 with specific numbers (actual vs. budget)
- [ ] Phase 2 reports the post-optimization metric explicitly (9ms achieved, 3ms still over)
- [ ] Verdict is NEEDS MORE WORK (not READY FOR RELEASE) when a budget violation remains
- [ ] The specific unresolved issue is listed by name with the remaining gap quantified
- [ ] Next Steps references `/sprint-plan update` for scheduling the remaining fix
- [ ] Phases 3 and 4 still run (polish work is not abandoned due to a Phase 2 partial resolution)
- [ ] Phase 5 qa-tester still runs (regression testing is independent of the performance outcome)

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `/team-polish` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Outputs usage guidance: e.g., "Usage: `/team-polish [feature or area to polish] [--review full|lean|solo]` — specify the feature or area to polish (e.g., `combat`, `main menu`, `inventory system`, `level-1`)"
3. Skill exits without spawning any agents

**Assertions:**
- [ ] Skill does NOT spawn any agents when no argument is provided
- [ ] Usage message shows the full argument-hint — `/team-polish [feature or area to polish] [--review full|lean|solo]` — and argument examples
- [ ] Skill does NOT attempt to guess a feature from project files
- [ ] No `AskUserQuestion` is used — output is direct guidance

---

### Case 4: Engine-Level Bottleneck — engine-programmer spawned conditionally in Phase 2

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- Feature being polished: `open-world` environment streaming
- Phase 1 identifies a performance bottleneck with a root cause in the rendering pipeline: "draw call overhead is caused by the engine's scene tree traversal in the spatial indexer — this is an engine-level issue, not a game code issue"
- Performance budgets are defined; the rendering overhead exceeds target frame budget

**Input:** `/team-polish open-world`

**Expected behavior:**
1. Phase 1: performance-analyst profiles the environment; identifies frame budget violation; root cause analysis points to engine-level rendering pipeline (spatial indexer traversal overhead)
2. Phase 1 output explicitly classifies the root cause as engine-level
3. `AskUserQuestion` presents the performance report including the engine-level root cause; user approves before Phase 2
4. Phase 2: engine-programmer (in the `small` set) is spawned for the engine-level rendering item on the optimisation list, writing `production/polish/open-world-engine-fixes-[date].md`; performance-analyst writes no code
5. Phases 3 and 4 also run in parallel with Phase 2 (visual and audio polish); engine-programmer lists the engine files it will change along with the other agents' files, and one ask covers the set
6. engine-programmer addresses the spatial indexer traversal after the yes; provides profiler validation showing the fix reduces overhead
7. Phase 5: qa-tester runs regression tests including tests for the engine-level change
8. Phase 6: orchestrator collects all results; if metrics are now within budget, verdict is READY FOR RELEASE; if not, NEEDS MORE WORK

**Assertions:**
- [ ] engine-programmer is NOT spawned in Phase 2 unless Phase 1 explicitly identifies an engine-level root cause
- [ ] engine-programmer is spawned in Phase 2 when Phase 1 identifies an engine-level root cause
- [ ] engine-programmer's Phase 2 Agent call is issued alongside the Phase 3 and 4 calls (not sequentially), and performance-analyst is not re-spawned to change code
- [ ] engine-programmer edits nothing before the one ask for the Phase 2–4 implementation set is answered yes
- [ ] Phases 3 and 4 also run in parallel with Phase 2 (not deferred until Phase 2 completes)
- [ ] engine-programmer's output includes profiler validation of the fix
- [ ] qa-tester in Phase 5 runs regression tests that cover the engine-level change
- [ ] Verdict correctly reflects whether all metrics including the engine fix now meet budgets

---

### Case 5: Regression Found — Polish change broke an existing feature

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- Feature being polished: `inventory-ui`
- Phases 1–4 complete successfully; performance and polish changes are applied
- Phase 5: qa-tester runs regression tests and finds that a shader optimization applied in Phase 3 broke the item highlight glow effect on hover — an existing feature that was working before the polish pass

**Input:** `/team-polish inventory-ui` (Phase 5 scenario)

**Expected behavior:**
1. Phases 1–4 complete; polish changes include a shader optimization from technical-artist
2. Phase 5: qa-tester runs regression tests and detects "Item highlight glow on hover no longer renders — regression introduced by shader optimization in Phase 3"
3. qa-tester writes its findings to `production/polish/inventory-ui-verification-[date].md` (no per-write prompt) and returns the regression as a CONCERNS/BLOCKED line in its return contract
4. The orchestrator confirms the verification file exists, then at the Phase 5 → Phase 6 transition writes qa-tester's full analysis in conversation — naming the broken behavior and the Phase 3 shader change that caused it — and captures the decision via `AskUserQuestion` with qa-tester's proposals as options
5. Phase 6: the regression is listed among remaining issues with severity and a recommendation
6. Verdict: NEEDS MORE WORK
7. Next Steps: schedule the fix in `/sprint-plan update` and re-run `/team-polish` after fixes

**Assertions:**
- [ ] Regression is surfaced before Phase 6 sign-off
- [ ] The specific broken behavior and the responsible change are both named in the report
- [ ] qa-tester's findings are written to `production/polish/inventory-ui-verification-[date].md` without a separate approval prompt
- [ ] `AskUserQuestion` at the Phase 5 → 6 transition presents the regression and qa-tester's proposed resolutions as selectable options
- [ ] Phase 6 lists the regression as a remaining issue with severity
- [ ] Verdict is NEEDS MORE WORK when a regression is present and unresolved
- [ ] Next Steps directs the fix to `/sprint-plan update` and a `/team-polish` re-run — no in-session fix is reported as verified

---

### Case 6: No Budgets Committed — NOT ASSESSED, not READY FOR RELEASE

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `project.yaml` sets none of `performance.target_framerate`, `performance.frame_budget_ms`, `performance.draw_call_limit` or `performance.memory_ceiling_mb`, and no design doc states a budget for the area
- Feature being polished: `main-menu`; every phase completes, and qa-tester finds no regressions

**Input:** `/team-polish main-menu`

**Expected behavior:**
1. Phase 1: performance-analyst profiles the menu via `/perf-profile`; each metric is reported as measured but `NOT ASSESSED` — no committed budget — never as within budget or with headroom against a placeholder such as 16.67 ms
2. Phases 2–5 run normally; nothing is found over budget and there are no regressions
3. Phase 6: no known problem, but the budget comparison could not run, so the verdict is NOT ASSESSED — not READY FOR RELEASE — and the report names each unset `performance.*` key
4. Next Steps: commit the budgets in `project.yaml` and re-run `/team-polish`; `/release-checklist` is not offered as the next step

**Assertions:**
- [ ] Verdict is NOT ASSESSED, not READY FOR RELEASE
- [ ] The report names each unset `performance.*` key as the reason
- [ ] No metric is described as within budget, and no headroom is computed against a placeholder budget
- [ ] Next Steps asks for the budgets and a re-run rather than handing off to `/release-checklist`
- [ ] A regression found in the same run would make the verdict NEEDS MORE WORK instead — the missing budgets do not mask a known problem

---

### Case 7: Default `individual` — the optimisation list is handed to `/dev-story`

**Fixture:**
- Resolved config block: `team.size: individual`, `automation: collaborative`
- Budgets committed in `project.yaml` (as in Case 1)
- Feature being polished: `crafting-menu`; Phase 1 finds a draw-call overrun owned by technical-artist and a script hot path in the crafting logic owned by gameplay-programmer — no engine-level root cause

**Input:** `/team-polish crafting-menu`

**Expected behavior:**
1. The active-set line names performance-analyst + technical-artist; the not-spawned line names sound-designer, qa-tester, engine-programmer and tools-programmer
2. Phase 1: performance-analyst writes `production/polish/crafting-menu-report-[date].md` with the optimisation list, each item naming its owner
3. Phase 2: no programmer is active, so no agent implements the script item — performance-analyst does not implement it either; the draw-call item joins technical-artist's Phase 3 brief
4. The report lists the gameplay-programmer item under "Optimisation list handed to `/dev-story`: `production/polish/crafting-menu-report-[date].md`"
5. Phase 6: audio polish and hardening did not run; if the script hot path keeps a metric over budget the verdict is NEEDS MORE WORK, otherwise NOT ASSESSED
6. Next Steps: implement the handed-off items with `/dev-story`, then re-run `/team-polish`

**Assertions:**
- [ ] No agent changes code for the gameplay-programmer item in this run, and performance-analyst changes nothing
- [ ] The report names the optimisation list as handed to `/dev-story`, with the path and each item's owner
- [ ] Verdict is never READY FOR RELEASE at `individual`
- [ ] An over-budget metric the handed-off item targets makes the verdict NEEDS MORE WORK

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with an `Active set (team.size: individual): performance-analyst + technical-artist` line and a `Not spawned this run:` line naming sound-designer, qa-tester, engine-programmer and tools-programmer — before any agent is spawned
- [ ] Phase 1 (assessment) must complete before any other phase begins
- [ ] In `collaborative` mode, `AskUserQuestion` is used after every phase output before the next phase launches
- [ ] Phases 3 and 4 are launched in parallel with Phase 2 whenever their agents are in the active set (not deferred)
- [ ] engine-programmer is only spawned when Phase 1 explicitly identifies engine-level root causes, and only at `small` or `studio`
- [ ] performance-analyst produces the optimisation list and never implements it; an item whose owner is not active is named as handed to `/dev-story`
- [ ] Phase 2–4 implementation files are asked for once, as a set — not once per phase
- [ ] No files are written by the orchestrator directly — all writes are delegated to sub-agents
- [ ] Sub-agents skip the per-write prompt only for their named `production/polish/` paths; any other write requires a "May I write" ask
- [ ] A phase whose named artifact is missing on disk is treated as failed, not done
- [ ] BLOCKED status from any agent is surfaced immediately — not silently skipped
- [ ] A partial report is always produced when some agents complete and others block
- [ ] Verdict is exactly one of READY FOR RELEASE, NOT ASSESSED or NEEDS MORE WORK — a known problem is NEEDS MORE WORK even when something else went unchecked, and READY FOR RELEASE is reachable only when every measured metric had a committed budget and every phase ran
- [ ] At `team.size: individual`, sound-designer's audio polish and qa-tester's hardening are named as not run, so the verdict is NOT ASSESSED unless a known problem makes it NEEDS MORE WORK
- [ ] NEEDS MORE WORK verdict always lists specific remaining issues with severity, the measured gap where there is one, and a recommendation
- [ ] Next Steps handoff references `/release-checklist` (on success), `/sprint-plan update` and a `/team-polish` re-run (on failure), `/gate-check` before handing off to release, and, on NOT ASSESSED, supplying the missing budgets or phases before a re-run
- [ ] At `team.size: studio`, Phase 5's qa-tester is told to find how the polished feature breaks rather than confirm it holds, and the report says the adversarial pass ran; no engine specialist is added

---

## Coverage Notes

- The tools-programmer optional agent (for content pipeline tool fixes) is not
  separately tested — it follows the same conditional spawn pattern as engine-programmer
  and is invoked in Phase 2, at `small` or `studio`, only when Phase 1 traces a cause
  to a content authoring tool.
- The "Retry with narrower scope" and "Skip this agent" resolution paths from the Error
  Recovery Protocol are not separately tested — they follow the same `AskUserQuestion`
  + partial-report pattern validated in Cases 2 and 5.
- Phase 6 sign-off logic (collecting and comparing all metrics) is validated implicitly
  by Cases 1 and 2. The distinction between READY FOR RELEASE and NEEDS MORE WORK is
  exercised in both directions across these cases, and NOT ASSESSED by Case 6.
- The `individual` path — audio polish and hardening not run, the optimisation list
  handed to `/dev-story` — is given Case 7.
- Soak testing and stress testing (Phase 5) are validated implicitly by Case 1's
  qa-tester output. Case 5 focuses on the regression detection aspect of Phase 5.
- The "minimum spec hardware" test path in Phase 5 is not separately tested — it follows
  the same qa-tester delegation pattern when the hardware is available.
- The `studio` addition (the adversarial review pass) is asserted in Protocol Compliance
  but not given its own case.
