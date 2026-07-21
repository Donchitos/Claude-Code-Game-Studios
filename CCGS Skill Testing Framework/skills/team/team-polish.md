# Skill Test Spec: $team-polish

## Skill Summary

Orchestrates the polish team through a six-phase pipeline: performance assessment
(performance-analyst) → optimization (performance-analyst, optionally with
engine-programmer when engine-level root causes are found) → visual polish
(technical-artist, parallel with Phase 2) → audio polish (sound-designer, parallel
with Phase 2) → hardening (qa-tester) → sign-off (orchestrator collects all results
and issues READY FOR RELEASE or NEEDS MORE WORK). Uses `AskUserQuestion` at each
phase transition. Engine-programmer is spawned conditionally only when Phase 1
identifies engine-level root causes. Verdict is READY FOR RELEASE or NEEDS MORE WORK.

---

## Static Assertions (Structural)

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: READY FOR RELEASE, NEEDS MORE WORK
- [ ] Contains "File Write Protocol" section
- [ ] File writes are delegated to sub-agents — orchestrator does not write files directly
- [ ] Sub-agents enforce "May I write to [path]?" before any write
- [ ] Has a next-step handoff at the end (references `$release-checklist`, `$sprint-plan update`, `$gate-check`)
- [ ] Error Recovery Protocol section is present
- [ ] `AskUserQuestion` is used at phase transitions before proceeding
- [ ] Phase 3 (visual polish) and Phase 4 (audio polish) are explicitly run in parallel with Phase 2
- [ ] engine-programmer is conditionally spawned in Phase 2 only when Phase 1 identifies engine-level root causes
- [ ] Phase 6 sign-off compares metrics against budgets before issuing verdict

---

## Test Cases

### Case 1: Happy Path — Full pipeline completes, READY FOR RELEASE verdict

**Fixture:**
- Feature exists and is functionally complete (e.g., `combat` system)
- Performance budgets are defined in technical-preferences.md (e.g., target 60fps, 16ms frame budget)
- No frame budget violations exist before polishing begins
- No audio events are missing; VFX assets are complete
- No regressions are introduced by polish changes

**Input:** `$team-polish combat`

**Expected behavior:**
1. Phase 1: performance-analyst is spawned; profiles the combat system, measures frame budget, checks memory usage; output: performance report showing all metrics within budget, no violations
2. `AskUserQuestion` presents performance report; user approves before Phases 2, 3, and 4 begin
3. Phase 2: performance-analyst applies minor optimizations (e.g., draw call batching); no engine-programmer needed (no engine-level root causes identified)
4. Phases 3 and 4 are launched in parallel alongside Phase 2:
   - Phase 3: technical-artist reviews VFX for quality, optimizes particle systems, adds screen shake and visual juice
   - Phase 4: sound-designer reviews audio events for completeness, checks mix levels, adds ambient audio layers
5. All three parallel phases complete; `AskUserQuestion` presents results; user approves before Phase 5 begins
6. Phase 5: qa-tester runs edge case tests, soak tests, stress tests, and regression tests; all pass
7. `AskUserQuestion` presents test results; user approves before Phase 6
8. Phase 6: orchestrator collects all results; compares before/after performance metrics against budgets; all metrics pass
9. Subagent asks "May I write the polish report to `production/qa/evidence/polish-combat-[date].md`?" before writing
10. Verdict: READY FOR RELEASE

**Assertions:**
- [ ] performance-analyst is spawned first in Phase 1 before any other agents
- [ ] `AskUserQuestion` appears after Phase 1 output and before Phases 2/3/4 launch
- [ ] Phases 3 and 4 Task calls are issued at the same time as Phase 2 (not after Phase 2 completes)
- [ ] engine-programmer is NOT spawned when Phase 1 finds no engine-level root causes
- [ ] qa-tester (Phase 5) is not launched until the parallel phases complete and user approves
- [ ] Phase 6 verdict is based on comparison of metrics against defined budgets
- [ ] Summary report includes: before/after performance metrics, visual polish changes, audio polish changes, test results
- [ ] No files are written by the orchestrator directly
- [ ] Verdict is READY FOR RELEASE

---

### Case 2: Performance Blocker — Frame budget violation cannot be fully resolved

**Fixture:**
- Feature being polished: `particle-storm` VFX system
- Phase 1 identifies a frame budget violation: particle-storm costs 12ms on target hardware (budget is 6ms for this system)
- Phase 2 performance-analyst applies optimizations reducing cost to 9ms — still over the 6ms budget
- Phase 2 cannot fully resolve the violation without a fundamental design change

**Input:** `$team-polish particle-storm`

**Expected behavior:**
1. Phase 1: performance-analyst identifies the 12ms frame cost vs. 6ms budget; reports "FRAME BUDGET VIOLATION: particle-storm costs 12ms, budget is 6ms"
2. `AskUserQuestion` presents the violation; user chooses to proceed with optimization attempt
3. Phase 2: performance-analyst applies optimizations; achieves 9ms — reduced but still over budget; reports "Optimization reduced cost to 9ms (was 12ms) — 3ms over budget. No further gains achievable without design changes."
4. Phases 3 and 4 run in parallel with Phase 2 (visual and audio polish)
5. Phase 5: qa-tester runs regression and edge case tests; all pass
6. Phase 6: orchestrator collects results; frame budget violation (9ms vs 6ms budget) remains unresolved
7. Verdict: NEEDS MORE WORK
8. Report lists the specific unresolved issue: "particle-storm frame cost (9ms) exceeds budget (6ms) by 3ms — requires design scope reduction or budget renegotiation"
9. Next Steps: schedule the remaining issue in `$sprint-plan update`; re-run `$team-polish` after fix

**Assertions:**
- [ ] Frame budget violation is flagged in Phase 1 with specific numbers (actual vs. budget)
- [ ] Phase 2 reports the post-optimization metric explicitly (9ms achieved, 3ms still over)
- [ ] Verdict is NEEDS MORE WORK (not READY FOR RELEASE) when a budget violation remains
- [ ] The specific unresolved issue is listed by name with the remaining gap quantified
- [ ] Next Steps references `$sprint-plan update` for scheduling the remaining fix
- [ ] Phases 3 and 4 still run (polish work is not abandoned due to a Phase 2 partial resolution)
- [ ] Phase 5 qa-tester still runs (regression testing is independent of the performance outcome)

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `$team-polish` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Outputs usage guidance: e.g., "Usage: `$team-polish [feature or area]` — specify the feature or area to polish (e.g., `combat`, `main menu`, `inventory system`, `level-1`)"
3. Skill exits without spawning any agents

**Assertions:**
- [ ] Skill does NOT spawn any agents when no argument is provided
- [ ] Usage message includes the correct invocation format with argument examples
- [ ] Skill does NOT attempt to guess a feature from project files
- [ ] No `AskUserQuestion` is used — output is direct guidance

---

### Case 4: Engine-Level Bottleneck — engine-programmer spawned conditionally in Phase 2

**Fixture:**
- Feature being polished: `open-world` environment streaming
- Phase 1 identifies a performance bottleneck with a root cause in the rendering pipeline: "draw call overhead is caused by the engine's scene tree traversal in the spatial indexer — this is an engine-level issue, not a game code issue"
- Performance budgets are defined; the rendering overhead exceeds target frame budget

**Input:** `$team-polish open-world`

**Expected behavior:**
1. Phase 1: performance-analyst profiles the environment; identifies frame budget violation; root cause analysis points to engine-level rendering pipeline (spatial indexer traversal overhead)
2. Phase 1 output explicitly classifies the root cause as engine-level
3. `AskUserQuestion` presents the performance report including the engine-level root cause; user approves before Phase 2
4. Phase 2: performance-analyst is spawned for game-code-level optimizations AND engine-programmer is spawned in parallel for the engine-level rendering fix
5. Phases 3 and 4 also run in parallel with Phase 2 (visual and audio polish)
6. engine-programmer addresses the spatial indexer traversal; provides profiler validation showing the fix reduces overhead
7. Phase 5: qa-tester runs regression tests including tests for the engine-level fix
8. Phase 6: orchestrator collects all results; if metrics are now within budget, verdict is READY FOR RELEASE; if not, NEEDS MORE WORK

**Assertions:**
- [ ] engine-programmer is NOT spawned in Phase 2 unless Phase 1 explicitly identifies an engine-level root cause
- [ ] engine-programmer is spawned in Phase 2 when Phase 1 identifies an engine-level root cause
- [ ] engine-programmer and performance-analyst Task calls in Phase 2 are issued simultaneously (not sequentially)
- [ ] Phases 3 and 4 also run in parallel with Phase 2 (not deferred until Phase 2 completes)
- [ ] engine-programmer's output includes profiler validation of the fix
- [ ] qa-tester in Phase 5 runs regression tests that cover the engine-level change
- [ ] Verdict correctly reflects whether all metrics including the engine fix now meet budgets

---

### Case 5: Regression Found — Polish change broke an existing feature

**Fixture:**
- Feature being polished: `inventory-ui`
- Phases 1–4 complete successfully; performance and polish changes are applied
- Phase 5: qa-tester runs regression tests and finds that a shader optimization applied in Phase 3 broke the item highlight glow effect on hover — an existing feature that was working before the polish pass

**Input:** `$team-polish inventory-ui` (Phase 5 scenario)

**Expected behavior:**
1. Phases 1–4 complete; polish changes include a shader optimization from technical-artist
2. Phase 5: qa-tester runs regression tests and detects "Item highlight glow on hover no longer renders — regression introduced by shader optimization in Phase 3"
3. qa-tester returns test results with the regression noted
4. Orchestrator surfaces the regression immediately: "qa-tester: REGRESSION FOUND — `item-highlight-hover` glow broken by Phase 3 shader optimization"
5. Subagent files a bug report asking "May I write the bug report to `production/qa/evidence/bug-polish-inventory-ui-[date].md`?" before writing
6. Bug report is written after approval; it includes: the broken behavior, the polish change that caused it, reproduction steps, and severity
7. `AskUserQuestion` presents the regression with options:
   - Revert the shader optimization and find an alternative approach
   - Fix the shader optimization to preserve the glow effect
   - Accept the regression and schedule a fix in the next sprint
8. Verdict: NEEDS MORE WORK (regression present regardless of user's chosen resolution path, unless fix is applied within the current session)

**Assertions:**
- [ ] Regression is surfaced before Phase 6 sign-off
- [ ] The specific broken behavior and the responsible change are both named in the report
- [ ] Subagent asks "May I write the bug report to [path]?" before filing
- [ ] Bug report includes: broken behavior, causal change, reproduction steps, severity
- [ ] `AskUserQuestion` offers options including revert, fix in place, and schedule later
- [ ] Verdict is NEEDS MORE WORK when a regression is present and unresolved
- [ ] Verdict may become READY FOR RELEASE only if the regression is fixed within the current polish session and qa-tester re-runs to confirm

---

## Protocol Compliance

- [ ] Phase 1 (assessment) must complete before any other phase begins
- [ ] `AskUserQuestion` is used after every phase output before the next phase launches
- [ ] Phases 3 and 4 are always launched in parallel with Phase 2 (not deferred)
- [ ] engine-programmer is only spawned when Phase 1 explicitly identifies engine-level root causes
- [ ] No files are written by the orchestrator directly — all writes are delegated to sub-agents
- [ ] Each sub-agent enforces the "May I write to [path]?" protocol before any write
- [ ] BLOCKED status from any agent is surfaced immediately — not silently skipped
- [ ] A partial report is always produced when some agents complete and others block
- [ ] Verdict is exactly READY FOR RELEASE or NEEDS MORE WORK — no other verdict values used
- [ ] NEEDS MORE WORK verdict always lists specific remaining issues with severity
- [ ] Next Steps handoff references `$release-checklist` (on success) and `$sprint-plan update` + `$gate-check` (on failure)

---

## Coverage Notes

- The tools-programmer optional agent (for content pipeline tool verification) is not
  separately tested — it follows the same conditional spawn pattern as engine-programmer
  and is invoked only when content authoring tools are involved in the polished area.
- The "Retry with narrower scope" and "Skip this agent" resolution paths from the Error
  Recovery Protocol are not separately tested — they follow the same `AskUserQuestion`
  + partial-report pattern validated in Cases 2 and 5.
- Phase 6 sign-off logic (collecting and comparing all metrics) is validated implicitly
  by Cases 1 and 2. The distinction between READY FOR RELEASE and NEEDS MORE WORK is
  exercised in both directions across these cases.
- Soak testing and stress testing (Phase 5) are validated implicitly by Case 1's
  qa-tester output. Case 5 focuses on the regression detection aspect of Phase 5.
- The "minimum spec hardware" test path in Phase 5 is not separately tested — it follows
  the same qa-tester delegation pattern when the hardware is available.
