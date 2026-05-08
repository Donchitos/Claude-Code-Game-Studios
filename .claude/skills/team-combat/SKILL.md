---
name: team-combat
description: "Orchestrate the combat team: coordinates game-designer, gameplay-programmer, ai-programmer, technical-artist, sound-designer, and qa-tester to design, implement, and validate a combat feature end-to-end."
argument-hint: "[combat feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion, TodoWrite
model: sonnet
---
**Argument check:** If no combat feature description is provided, output:
> "Usage: `/team-combat [combat feature description]` — Provide a description of the combat feature to design and implement (e.g., `melee parry system`, `ranged weapon spread`)."
Then stop immediately without spawning any subagents or reading any files.

When this skill is invoked with a valid argument, orchestrate the combat team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next phase.

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed as an argument, use that mode.
2. Else read `production/review-mode.txt` — use whatever is written there.
3. Else default to `lean`.

Modes:
- `full` — spawn all director and lead gates as described
- `lean` — skip director gates unless they are PHASE-GATE type (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE)
- `solo` — skip all director gate spawning entirely; run the skill without any agent gates

Store the resolved mode for use in all subsequent phases.

## Team Composition
- **game-designer** — Design the mechanic, define formulas and edge cases
- **gameplay-programmer** — Implement the core gameplay code
- **ai-programmer** — Implement NPC/enemy AI behavior for the feature
- **technical-artist** — Create VFX, shader effects, and visual feedback
- **sound-designer** — Define audio events, impact sounds, and ambient combat audio
- **engine specialist** (primary) — Validate architecture and implementation patterns are idiomatic for the engine (read from `.claude/docs/technical-preferences.md` Engine Specialists section)
- **qa-tester** — Write test cases and validate the implementation

## How to Delegate

Use the Task tool to spawn each team member as a subagent:
- `subagent_type: game-designer` — Design the mechanic, define formulas and edge cases
- `subagent_type: gameplay-programmer` — Implement the core gameplay code
- `subagent_type: ai-programmer` — Implement NPC/enemy AI behavior
- `subagent_type: technical-artist` — Create VFX, shader effects, visual feedback
- `subagent_type: sound-designer` — Define audio events, impact sounds, ambient audio
- `subagent_type: [primary engine specialist]` — Engine idiom validation for architecture and implementation
- `subagent_type: qa-tester` — Write test cases and validate implementation

Always provide full context in each agent's prompt (design doc path, relevant code files, constraints). Launch independent agents in parallel where the pipeline allows it (e.g., Phase 3 agents can run simultaneously).

## Pipeline

### Phase 1: Design
Delegate to **game-designer**:
- Create or update the design document in `design/gdd/` covering: mechanic overview, player fantasy, detailed rules, formulas with variable definitions, edge cases, dependencies, tuning knobs with safe ranges, and acceptance criteria
- Output: completed design document

### Phase 2: Architecture
Delegate to **gameplay-programmer** (with **ai-programmer** if AI is involved):
- Review the design document
- Design the code architecture: class structure, interfaces, data flow
- Identify integration points with existing systems
- Output: architecture sketch with file list and interface definitions

Then spawn the **primary engine specialist** to validate the proposed architecture:
- Is the class/node/component structure idiomatic for the pinned engine? (e.g., Godot node hierarchy, Unity MonoBehaviour vs DOTS, Unreal Actor/Component design)
- Are there engine-native systems that should be used instead of custom implementations?
- Any proposed APIs that are deprecated or changed in the pinned engine version?
- Output: engine architecture notes — incorporate into the architecture before Phase 3 begins

Use `AskUserQuestion`:
- Prompt: "Architecture sketch complete. Approve to proceed with parallel implementation."
- Options:
  - `[A] Proceed — spawn implementation agents (gameplay-programmer, ai-programmer, technical-artist, sound-designer)`
  - `[B] Revise the architecture first — I'll describe what needs to change`
  - `[C] Stop here — I'll continue later`

Only spawn implementation agents if user selects [A].

### Phase 3: Implementation (parallel where possible)
Delegate in parallel:
- **gameplay-programmer**: Implement core combat mechanic code
- **ai-programmer**: Implement AI behaviors (if the feature involves NPC reactions)
- **technical-artist**: Create VFX and shader effects
- **sound-designer**: Define audio event list and mixing notes

### Phase 4: Integration
- Wire together gameplay code, AI, VFX, and audio
- Ensure all tuning knobs are exposed and data-driven
- Verify the feature works with existing combat systems

### Phase 5: Validation
Delegate to **qa-tester**:
- Write test cases from the acceptance criteria
- Test all edge cases documented in the design
- Verify performance impact is within budget
- File bug reports for any issues found

### Phase 6: Sign-off
- Collect results from all team members
- Report feature status: COMPLETE / NEEDS WORK / BLOCKED
- List any outstanding issues and their assigned owners

## Error Recovery Protocol

If any spawned agent (via Task) returns BLOCKED, errors, or cannot complete:

1. **Surface immediately**: Report "[AgentName]: BLOCKED — [reason]" to the user before continuing to dependent phases
2. **Assess dependencies**: Check whether the blocked agent's output is required by subsequent phases. If yes, do not proceed past that dependency point without user input.
3. **Offer options** via AskUserQuestion with choices:
   - Skip this agent and note the gap in the final report
   - Retry with narrower scope
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed. Never discard work because one agent blocked.

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

## File Write Protocol

All file writes (design documents, implementation files, test cases) are
delegated to sub-agents spawned via Task. Each sub-agent enforces the
"May I write to [path]?" protocol. This orchestrator does not write files directly.

## Output

A summary report covering: design completion status, implementation status per team member, test results, and any open issues.

Verdict: **COMPLETE** — combat feature designed, implemented, and validated.
Verdict: **BLOCKED** — one or more phases could not complete; partial report produced with unresolved items listed.

## Next Steps

- Run `/code-review` on the implemented combat code before closing stories.
- Run `/balance-check` to validate combat formulas and tuning values.
- Run `/team-polish` if VFX, audio, or performance polish is needed.
