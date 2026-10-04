# Skill Test Spec: /team-combat

## Skill Summary

Orchestrates the full combat team pipeline end-to-end for a single combat feature.
Coordinates game-designer, gameplay-programmer, ai-programmer, technical-artist,
sound-designer, the primary engine specialist, and qa-tester through six structured
phases: Design → Architecture (with engine specialist validation) → Implementation
(parallel) → Integration → Validation → Sign-off. Phase 0 resolves `review_mode`,
`automation`, `team.size` and `workflow` (which sizes the GDD); the full pipeline runs at `team.size: small` and above,
while the default `individual` runs gameplay-programmer alone (ai-programmer only if
AI work is flagged) and announces that collapse before Phase 1. Uses
`AskUserQuestion` at each phase transition, with an explicit [A]/[B]/[C] architecture
gate before implementation. Every agent writes to a destination named in the skill's
path table; the orchestrator's only write is the GDD, `design/gdd/[feature].md`,
from the game-designer's draft after a "May I write" approval. Produces a summary report with
verdict COMPLETE / NEEDS WORK / BLOCKED and handoffs to `/code-review`,
`/balance-check`, and `/team-polish`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings (Phase 1 through Phase 6 are all present)
- [ ] Contains verdict keywords: COMPLETE, NEEDS WORK, BLOCKED
- [ ] Contains "File Write Protocol" — sub-agent drafts and QA artifacts stay inside the bounded exception, and implementation files (code root, `assets/`) are outside it, asked for once as a set; the one orchestrator write is `design/gdd/[feature].md`, after its own "May I write" ask, because `design/` is outside the exception
- [ ] Names a concrete destination per phase: `production/combat/[feature]-gdd-draft.md` (the game-designer's draft of `design/gdd/[feature].md`), `docs/architecture/[feature]-sketch.md`, `docs/architecture/[feature]-engine-notes.md`, `production/qa/test-cases/[feature]-cases.md`, `production/qa/bugs/BUG-[NNNN].md`
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] Has a next-step handoff at the end (references `/code-review`, `/balance-check`, `/team-polish`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk before treating a phase as done, surface BLOCKED immediately, always produce a partial report, full procedure (surface → assess → options → partial report) in `.claude/docs/error-recovery-protocol.md`
- [ ] Uses `AskUserQuestion` at phase transitions for user approval before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Phase 1
- [ ] Phase 0 resolves `workflow`, and Phase 1 sizes the GDD by it: `## Summary` plus all 8 sections at `full`, the 5 standard sections plus Formulas for numeric rules at `standard`, optional at `minimal` (the game brief is the record)
- [ ] Phase 3 is explicitly marked as parallel (gameplay-programmer, ai-programmer, technical-artist, sound-designer)
- [ ] Phase 2 includes spawning the primary engine specialist, derived from `engine.name` in `project.yaml` (Godot → `godot-specialist`), falling back to the Primary line in `.claude/docs/technical-preferences.md`
- [ ] Team Composition lists all seven roles (game-designer, gameplay-programmer, ai-programmer, technical-artist, sound-designer, engine specialist, qa-tester)

---

## Test Cases

### Case 1: Happy Path — All agents succeed, full pipeline runs to completion

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`, `workflow: full`
- `design/gdd/game-concept.md` exists and is populated
- `engine.name` in `project.yaml` is Godot
- No existing GDD for the requested combat feature
- The feature involves NPC reactions (enemies parry and riposte), so AI work is flagged

**Input:** `/team-combat parry and riposte system`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: small` (the full Team Composition pipeline)
2. Phase 1 — game-designer spawned; drafts the design to `production/combat/parry-riposte-gdd-draft.md` covering all 8 required sections (overview, player fantasy, rules, formulas, edge cases, dependencies, tuning knobs, acceptance criteria); `AskUserQuestion` presents the draft and asks "May I write the design document to `design/gdd/parry-riposte.md`?"; the orchestrator writes it on approval
3. Phase 2 — gameplay-programmer + ai-programmer spawned; produce architecture sketch with class structure, interfaces, and file list (`docs/architecture/parry-riposte-sketch.md`); then `godot-specialist` is spawned to validate idioms (`docs/architecture/parry-riposte-engine-notes.md`); engine specialist output incorporated
4. `AskUserQuestion` "Architecture sketch complete. Approve to proceed with parallel implementation." with options [A] Proceed / [B] Revise the architecture first / [C] Stop here — implementation agents spawn only on [A]
5. Phase 3 — gameplay-programmer, ai-programmer, technical-artist, sound-designer spawned in parallel; the three implementing agents return the files they will create or change, one `AskUserQuestion` asks for the whole set, and they write only after a yes; sound-designer drafts its event list to `production/combat/parry-riposte-audio-events.md`; all four return before Phase 4 begins
6. Phase 4 — integration wires together all Phase 3 outputs; tuning knobs verified as data-driven; `AskUserQuestion` confirms integration before Phase 5
7. Phase 5 — qa-tester spawned; writes test cases from acceptance criteria to `production/qa/test-cases/parry-riposte-cases.md`; verifies edge cases; performance impact checked against budget
8. Phase 6 — summary report produced: design status, implementation status per team member, test results, open issues; verdict: COMPLETE
9. Next steps listed: `/code-review`, `/balance-check`, `/team-polish`

**Assertions:**
- [ ] Active-set line naming `team.size: small` appears before the first agent is spawned
- [ ] `AskUserQuestion` called at each phase transition (at minimum before Phase 3 and before Phase 5)
- [ ] The pre-Phase 3 gate offers [A] Proceed / [B] Revise / [C] Stop, and no implementation agent is spawned unless [A] is chosen
- [ ] Phase 3 agents launched simultaneously — no sequential dependency between gameplay-programmer, ai-programmer, technical-artist, sound-designer
- [ ] Engine specialist runs in Phase 2 before Phase 3 begins (output incorporated into architecture)
- [ ] Each agent prompt names its destination from the path table; no sub-agent writes under `design/`
- [ ] No implementation file (code root, `assets/`) is written before one ask covering the whole Phase 3 set
- [ ] Nothing is written under `design/` before the Phase 1 "May I write" approval, and the orchestrator's only Write is `design/gdd/parry-riposte.md`
- [ ] Verdict COMPLETE present in final report
- [ ] Next steps include `/code-review`, `/balance-check`, `/team-polish`
- [ ] Design doc covers all 8 required GDD sections

---

### Case 2: Blocked Agent — One subagent returns BLOCKED mid-pipeline

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `design/gdd/parry-riposte.md` exists (Phase 1 already complete)
- ai-programmer agent returns BLOCKED because no AI system architecture ADR exists (ADR status is Proposed)

**Input:** `/team-combat parry and riposte system`

**Expected behavior:**
1. Phase 1 — design doc found; game-designer confirms it is valid; phase approved
2. Phase 2 — gameplay-programmer completes architecture sketch; ai-programmer returns BLOCKED: "ADR for AI behavior system is Proposed — cannot implement until ADR is Accepted"
3. Error Recovery Protocol triggered: "ai-programmer: BLOCKED — AI behavior ADR is Proposed"
4. `AskUserQuestion` presented with options: (a) Skip ai-programmer and note the gap; (b) Retry with narrower scope; (c) Stop here and run `/architecture-decision` first
5. If user chooses (a): Phase 3 proceeds with gameplay-programmer, technical-artist, sound-designer only; ai-programmer gap noted in partial report
6. Final report produced: partial implementation documented, ai-programmer section marked BLOCKED, overall verdict: BLOCKED

**Assertions:**
- [ ] BLOCKED surface message appears before any dependent phase continues
- [ ] `AskUserQuestion` offers at minimum three options: skip / retry / stop
- [ ] Partial report produced — completed agents' work is not discarded
- [ ] Overall verdict is BLOCKED (not COMPLETE) when any agent is unresolved
- [ ] Blocked reason references the ADR and suggests `/architecture-decision`
- [ ] Orchestrator does not silently proceed past the blocked dependency

---

### Case 3: No Argument — Clear usage guidance shown

**Fixture:**
- Any project state

**Input:** `/team-combat` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (combat feature description)
3. Shows the invocation format `/team-combat [combat feature description] [--review full|lean|solo]` with examples (`melee parry system`, `ranged weapon spread`)
4. Skill exits without spawning any subagents

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message shows the full argument-hint: `/team-combat [combat feature description] [--review full|lean|solo]`
- [ ] Error message includes at least one example of a valid invocation
- [ ] No file reads beyond what is needed to detect the missing argument
- [ ] Verdict is NOT shown (pipeline never runs)

---

### Case 4: Parallel Phase Validation — Phase 3 agents run simultaneously

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `design/gdd/parry-riposte.md` exists, is complete, and flags enemy AI reactions
- Architecture sketch has been approved with option [A]
- Engine specialist has validated architecture

**Input:** `/team-combat parry and riposte system` (resuming from Phase 2 complete)

**Expected behavior:**
1. Phase 3 begins after architecture approval
2. All four Agent calls — gameplay-programmer, ai-programmer, technical-artist, sound-designer — are issued before any result is awaited
3. Skill waits for all four agents to complete before proceeding to Phase 4
4. If any single agent completes early, skill does not begin Phase 4 until all four have returned

**Assertions:**
- [ ] Four Agent calls issued in a single batch (no sequential waiting between them)
- [ ] Phase 4 does not begin until all four Phase 3 agents have returned results
- [ ] Skill does not pass one Phase 3 agent's output as input to another Phase 3 agent (they are independent)
- [ ] All four Phase 3 agent results referenced in the Phase 4 integration step

---

### Case 5: Architecture Phase Engine Routing — Engine specialist resolved from config

**Fixture (variant A — engine configured):**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `engine.name` in `project.yaml` is Godot; engine version pinned in `docs/engine-reference/godot/VERSION.md`
- Architecture sketch produced by gameplay-programmer is available, and the orchestrator has read it

**Fixture (variant B — no engine configured):**
- As variant A, except `engine.name` is unset in `project.yaml` and `.claude/docs/technical-preferences.md` has no Primary engine specialist (shows `[TO BE CONFIGURED]`)

**Input:** `/team-combat parry and riposte system`

**Expected behavior (variant A):**
1. Phase 2 — gameplay-programmer produces architecture sketch
2. Skill derives the primary engine specialist from `engine.name` (Godot → `godot-specialist`); `technical-preferences.md` is consulted only if `engine.name` is absent
3. Engine specialist is spawned with a distilled brief of the architecture sketch (not a path to a document the orchestrator has already read) and asked the three Phase 2 questions: idiomatic class/node structure, engine-native systems to prefer, APIs deprecated or changed in the pinned engine version
4. Engine specialist writes its notes to `docs/architecture/parry-riposte-engine-notes.md`; the orchestrator checks the file exists before treating the step as done
5. Orchestrator incorporates engine notes into the architecture before presenting Phase 2 results to user
6. `AskUserQuestion` architecture gate includes engine specialist's notes alongside the architecture sketch

**Expected behavior (variant B):**
1. Phase 2 — gameplay-programmer produces architecture sketch
2. No engine specialist is spawned and no engine-notes file is expected
3. The run output records `Engine validation: NOT ASSESSED — no engine configured (engine.name unset in project.yaml)`
4. The architecture gate still runs; it presents the sketch without describing it as engine-validated
5. When the run completes, the verdict is `COMPLETE — engine validation NOT ASSESSED (no engine configured)`

**Assertions:**
- [ ] Engine specialist agent type is derived from `engine.name` (falling back to `technical-preferences.md`) — not hardcoded (variant A)
- [ ] Because the orchestrator has already read the sketch, the engine specialist's brief carries the relevant sketch content inline rather than the sketch's path (variant A)
- [ ] Engine specialist checks for deprecated or changed APIs against the pinned engine version (variant A)
- [ ] Engine specialist output is incorporated before Phase 3 begins (not skipped or appended separately) (variant A)
- [ ] The engine specialist is not spawned and the run output records `Engine validation: NOT ASSESSED — no engine configured` — the skip is never silent (variant B)
- [ ] The architecture is never described as engine-validated when no specialist ran (variant B)
- [ ] When the run completes, its verdict reads `COMPLETE — engine validation NOT ASSESSED ([reason])` — never a plain COMPLETE (variant B)

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with an `Active set (team.size: individual): gameplay-programmer` line and a `Not spawned this run:` line naming game-designer, technical-artist, sound-designer, the engine specialist and qa-tester (ai-programmer too unless AI work is flagged) — before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` used at each phase transition — user approves before pipeline advances
- [ ] Sub-agent writes are delegated via Agent — drafts and QA artifacts inside the bounded exception, implementation files only after one ask for the whole set; the orchestrator writes only `design/gdd/[feature].md`, after a "May I write" approval
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] A phase whose named artifact is missing on disk is treated as failed, not done
- [ ] Phase 3 agents launched in parallel per skill spec
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Verdict is one of COMPLETE / NEEDS WORK / BLOCKED
- [ ] Next steps present at end of output: `/code-review`, `/balance-check`, `/team-polish`
- [ ] At `team.size: studio`, the primary engine specialist's prompt allows its sub-specialists, Phase 5's qa-tester is told to find how the feature breaks rather than confirm it works, and the report says the adversarial pass ran; below `studio` neither addition appears

---

## Coverage Notes

- The NEEDS WORK verdict path (qa-tester finds failures in Phase 5) is not separately tested
  here; it follows the same error recovery and partial report protocol as Case 2.
- "Retry with narrower scope" error recovery option is listed in assertions but its full
  recursive behavior (splitting via `/create-stories`) is covered by the `/create-stories` spec.
- Phase 4 integration logic (wiring gameplay, AI, VFX, audio) is validated implicitly by
  the Happy Path case; a dedicated integration test would require fixture code files.
- Engine specialist unavailable (no engine configured) is covered by Case 5 variant B.
- The `studio` additions (engine sub-specialists, adversarial review pass) are asserted in
  Protocol Compliance but not given their own case.
