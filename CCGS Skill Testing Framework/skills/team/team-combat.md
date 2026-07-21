# Skill Test Spec: $team-combat

## Skill Summary

Orchestrates the full combat team pipeline end-to-end for a single combat feature.
Coordinates game-designer, gameplay-programmer, ai-programmer, technical-artist,
sound-designer, the primary engine specialist, and qa-tester through six structured
phases: Design → Architecture (with engine specialist validation) → Implementation
(parallel) → Integration → Validation → Sign-off. Uses `AskUserQuestion` at each
phase transition. Delegates all file writes to sub-agents. Produces a summary report
with verdict COMPLETE / NEEDS WORK / BLOCKED and handoffs to `$code-review`,
`$balance-check`, and `$team-polish`.

---

## Static Assertions (Structural)

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings (Phase 1 through Phase 6 are all present)
- [ ] Contains verdict keywords: COMPLETE, NEEDS WORK, BLOCKED
- [ ] Contains "May I write" or "File Write Protocol" — writes delegated to sub-agents, orchestrator does not write files directly
- [ ] Has a next-step handoff at the end (references `$code-review`, `$balance-check`, `$team-polish`)
- [ ] Error Recovery Protocol section is present with all four recovery steps
- [ ] Uses `AskUserQuestion` at phase transitions for user approval before proceeding
- [ ] Phase 3 is explicitly marked as parallel (gameplay-programmer, ai-programmer, technical-artist, sound-designer)
- [ ] Phase 2 includes spawning the primary engine specialist (read from `docs/studio/technical-preferences.md`)
- [ ] Team Composition lists all seven roles (game-designer, gameplay-programmer, ai-programmer, technical-artist, sound-designer, engine specialist, qa-tester)

---

## Test Cases

### Case 1: Happy Path — All agents succeed, full pipeline runs to completion

**Fixture:**
- `design/gdd/game-concept.md` exists and is populated
- Engine is configured in `docs/studio/technical-preferences.md` (Engine Specialists section filled)
- No existing GDD for the requested combat feature

**Input:** `$team-combat parry and riposte system`

**Expected behavior:**
1. Phase 1 — game-designer spawned; produces `design/gdd/parry-riposte.md` covering all 8 required sections (overview, player fantasy, rules, formulas, edge cases, dependencies, tuning knobs, acceptance criteria); asks user to approve design doc
2. Phase 2 — gameplay-programmer + ai-programmer spawned; produce architecture sketch with class structure, interfaces, and file list; then primary engine specialist is spawned to validate idioms; engine specialist output incorporated; `AskUserQuestion` presented with architecture options before Phase 3 begins
3. Phase 3 — gameplay-programmer, ai-programmer, technical-artist, sound-designer spawned in parallel; all four return outputs before Phase 4 begins
4. Phase 4 — integration wires together all Phase 3 outputs; tuning knobs verified as data-driven; `AskUserQuestion` confirms integration before Phase 5
5. Phase 5 — qa-tester spawned; writes test cases from acceptance criteria; verifies edge cases; performance impact checked against budget
6. Phase 6 — summary report produced: design COMPLETE, all team members COMPLETE, test cases listed, verdict: COMPLETE
7. Next steps listed: `$code-review`, `$balance-check`, `$team-polish`

**Assertions:**
- [ ] `AskUserQuestion` called at each phase gate (at minimum before Phase 3 and before Phase 5)
- [ ] Phase 3 agents launched simultaneously — no sequential dependency between gameplay-programmer, ai-programmer, technical-artist, sound-designer
- [ ] Engine specialist runs in Phase 2 before Phase 3 begins (output incorporated into architecture)
- [ ] All file writes delegated to sub-agents (orchestrator never calls Write/Edit directly)
- [ ] Verdict COMPLETE present in final report
- [ ] Next steps include `$code-review`, `$balance-check`, `$team-polish`
- [ ] Design doc covers all 8 required GDD sections

---

### Case 2: Blocked Agent — One subagent returns BLOCKED mid-pipeline

**Fixture:**
- `design/gdd/parry-riposte.md` exists (Phase 1 already complete)
- ai-programmer agent returns BLOCKED because no AI system architecture ADR exists (ADR status is Proposed)

**Input:** `$team-combat parry and riposte system`

**Expected behavior:**
1. Phase 1 — design doc found; game-designer confirms it is valid; phase approved
2. Phase 2 — gameplay-programmer completes architecture sketch; ai-programmer returns BLOCKED: "ADR for AI behavior system is Proposed — cannot implement until ADR is Accepted"
3. Error Recovery Protocol triggered: "ai-programmer: BLOCKED — AI behavior ADR is Proposed"
4. `AskUserQuestion` presented with options: (a) Skip ai-programmer and note the gap; (b) Retry with narrower scope; (c) Stop here and run `$architecture-decision` first
5. If user chooses (a): Phase 3 proceeds with gameplay-programmer, technical-artist, sound-designer only; ai-programmer gap noted in partial report
6. Final report produced: partial implementation documented, ai-programmer section marked BLOCKED, overall verdict: BLOCKED

**Assertions:**
- [ ] BLOCKED surface message appears before any dependent phase continues
- [ ] `AskUserQuestion` offers at minimum three options: skip / retry / stop
- [ ] Partial report produced — completed agents' work is not discarded
- [ ] Overall verdict is BLOCKED (not COMPLETE) when any agent is unresolved
- [ ] Blocked reason references the ADR and suggests `$architecture-decision`
- [ ] Orchestrator does not silently proceed past the blocked dependency

---

### Case 3: No Argument — Clear usage guidance shown

**Fixture:**
- Any project state

**Input:** `$team-combat` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (combat feature description)
3. Provides an example invocation: `$team-combat [combat feature description]`
4. Skill exits without spawning any subagents

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message includes the canonical `$skill-name` invocation syntax
- [ ] Error message includes at least one example of a valid invocation
- [ ] No file reads beyond what is needed to detect the missing argument
- [ ] Verdict is NOT shown (pipeline never runs)

---

### Case 4: Parallel Phase Validation — Phase 3 agents run simultaneously

**Fixture:**
- `design/gdd/parry-riposte.md` exists and is complete
- Architecture sketch has been approved
- Engine specialist has validated architecture

**Input:** `$team-combat parry and riposte system` (resuming from Phase 2 complete)

**Expected behavior:**
1. Phase 3 begins after architecture approval
2. All four Task calls — gameplay-programmer, ai-programmer, technical-artist, sound-designer — are issued before any result is awaited
3. Skill waits for all four agents to complete before proceeding to Phase 4
4. If any single agent completes early, skill does not begin Phase 4 until all four have returned

**Assertions:**
- [ ] Four Task calls issued in a single batch (no sequential waiting between them)
- [ ] Phase 4 does not begin until all four Phase 3 agents have returned results
- [ ] Skill does not pass one Phase 3 agent's output as input to another Phase 3 agent (they are independent)
- [ ] All four Phase 3 agent results referenced in the Phase 4 integration step

---

### Case 5: Architecture Phase Engine Routing — Engine specialist receives correct context

**Fixture:**
- `docs/studio/technical-preferences.md` has Engine Specialists section populated (e.g., Primary: godot-specialist)
- Architecture sketch produced by gameplay-programmer is available
- Engine version pinned in `docs/engine-reference/godot/VERSION.md`

**Input:** `$team-combat parry and riposte system`

**Expected behavior:**
1. Phase 2 — gameplay-programmer produces architecture sketch
2. Skill reads `docs/studio/technical-preferences.md` Engine Specialists section to identify the primary engine specialist role profile
3. Engine specialist is spawned with: the architecture sketch, the GDD path, the engine version from `VERSION.md`, and explicit instructions to check for deprecated APIs
4. Engine specialist output (idiom notes, deprecated API warnings, native system recommendations) is returned to orchestrator
5. Orchestrator incorporates engine notes into the architecture before presenting Phase 2 results to user
6. `AskUserQuestion` includes engine specialist's notes alongside the architecture sketch

**Assertions:**
- [ ] Engine specialist role profile is read from `docs/studio/technical-preferences.md` — not hardcoded
- [ ] Engine specialist prompt includes the architecture sketch and GDD path
- [ ] Engine specialist checks for deprecated APIs against the pinned engine version
- [ ] Engine specialist output is incorporated before Phase 3 begins (not skipped or appended separately)
- [ ] If no engine is configured, engine specialist step is skipped and a note is added to the report

---

## Protocol Compliance

- [ ] `AskUserQuestion` used at each phase transition — user approves before pipeline advances
- [ ] All file writes delegated to sub-agents via Task — orchestrator does not call Write or Edit directly
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] Phase 3 agents launched in parallel per skill spec
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Verdict is one of COMPLETE / NEEDS WORK / BLOCKED
- [ ] Next steps present at end of output: `$code-review`, `$balance-check`, `$team-polish`

---

## Coverage Notes

- The NEEDS WORK verdict path (qa-tester finds failures in Phase 5) is not separately tested
  here; it follows the same error recovery and partial report protocol as Case 2.
- "Retry with narrower scope" error recovery option is listed in assertions but its full
  recursive behavior (splitting via `$create-stories`) is covered by the `$create-stories` spec.
- Phase 4 integration logic (wiring gameplay, AI, VFX, audio) is validated implicitly by
  the Happy Path case; a dedicated integration test would require fixture code files.
- Engine specialist unavailable (no engine configured) is partially covered in Case 5
  assertions — a dedicated fixture for unconfigured engine state would strengthen coverage.
