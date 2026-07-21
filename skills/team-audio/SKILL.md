---
name: team-audio
description: "Orchestrate audio team: audio-director + sound-designer + technical-artist + gameplay-programmer for full audio pipeline from direction to implementation."
---

## Invocation

- Canonical syntax: `$team-audio`
- Expected input: `[feature or area to design audio for] [--review full|lean|solo]`. Input is the text supplied by the user's invoking prompt.

## User interaction

At every decision point described below, pause and ask the user a focused question. Offer concise choices when useful and wait for the answer before continuing.

## Specialist delegation

Use generic Codex sub-agents; repository role profiles do not register custom agent types. For every named specialist delegated below, instruct the sub-agent to read the matching profile before acting, and include full task context, relevant paths, constraints, and expected output.

- [accessibility-specialist](../../roles/accessibility-specialist.md)
- [audio-director](../../roles/audio-director.md)
- [gameplay-programmer](../../roles/gameplay-programmer.md)
- [sound-designer](../../roles/sound-designer.md)
- [technical-artist](../../roles/technical-artist.md)

For a dynamic engine specialist, first resolve the configured role name from `docs/studio/technical-preferences.md`, verify `../../roles/<resolved-role>.md` exists, then inject that profile and the full task context into the generic sub-agent prompt.

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `$team-audio [feature or area]` — specify the feature or area to design audio for (e.g., `combat`, `main menu`, `forest biome`, `boss encounter`). Do not pause and ask the user a focused question here; output the guidance directly.

When this skill is invoked with an argument, orchestrate the audio team through a structured pipeline.

**Decision Points:** At each step transition, pause and ask the user a focused question to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next step.

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed as an argument, use that mode.
2. Else read `production/review-mode.txt` — use whatever is written there.
3. Else default to `lean`.

Modes:
- `full` — spawn all director and lead gates as described
- `lean` — skip director gates unless they are PHASE-GATE type (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE)
- `solo` — skip all director gate spawning entirely; run the skill without any agent gates

Store the resolved mode for use in all subsequent phases.

1. **Read the argument** for the target feature or area (e.g., `combat`,
   `main menu`, `forest biome`, `boss encounter`).

2. **Gather context**:
   - Read relevant design docs in `design/gdd/` for the feature
   - Read the sound bible at `design/gdd/sound-bible.md` if it exists
   - Read existing audio asset lists in `assets/audio/`
   - Read any existing sound design docs for this area

## How to Delegate

Use the generic sub-agent mechanism to spawn each team member as a subagent:
- [audio-director](../../roles/audio-director.md) role profile — Sonic identity, emotional tone, audio palette
- [sound-designer](../../roles/sound-designer.md) role profile — SFX specifications, audio events, mixing groups
- [technical-artist](../../roles/technical-artist.md) role profile — Audio middleware, bus structure, memory budgets
- configured primary engine specialist role profile — Validate audio integration patterns for the engine
- [gameplay-programmer](../../roles/gameplay-programmer.md) role profile — Audio manager, gameplay triggers, adaptive music

Always provide full context in each agent's prompt (feature description, existing audio assets, design doc references).

3. **Orchestrate the audio team** in sequence:

### Step 1: Audio Direction (audio-director)
Spawn the `audio-director` agent to:
- Define the sonic identity for this feature/area
- Specify the emotional tone and audio palette
- Set music direction (adaptive layers, stems, transitions)
- Define audio priorities and mix targets
- Establish any adaptive audio rules (combat intensity, exploration, tension)

### Step 2: Sound Design and Audio Accessibility (parallel)
Spawn the `sound-designer` agent to:
- Create detailed SFX specifications for every audio event
- Define sound categories (ambient, UI, gameplay, music, dialogue)
- Specify per-sound parameters (volume range, pitch variation, attenuation)
- Plan audio event list with trigger conditions
- Define mixing groups and ducking rules

Spawn the `accessibility-specialist` agent in parallel to:
- Identify which audio events carry critical gameplay information (damage received, enemy nearby, objective complete) and require visual alternatives for hearing-impaired players
- Specify subtitle requirements: which audio events need captions, what text format, on-screen duration
- Check that no gameplay state is communicated by audio alone (all must have a visual fallback)
- Review the audio event list for any that could cause issues for players with auditory sensitivities (high-frequency alerts, sudden loud events)
- Output: audio accessibility requirements list integrated into the audio event spec

### Step 3: Technical Implementation (parallel)
Spawn the `technical-artist` agent to:
- Design the audio middleware integration (Wwise/FMOD/native)
- Define audio bus structure and routing
- Specify memory budgets for audio assets per platform
- Plan streaming vs preloaded asset strategy
- Design any audio-reactive visual effects

Spawn the **primary engine specialist** in parallel (from `docs/studio/technical-preferences.md` Engine Specialists) to validate the integration approach:
- Is the proposed audio middleware integration idiomatic for the engine? (e.g., Godot's built-in AudioStreamPlayer vs FMOD, Unity's Audio Mixer vs Wwise, Unreal's MetaSounds vs FMOD)
- Any engine-specific audio node/component patterns that should be used?
- Known audio system changes in the pinned engine version that affect the integration plan?
- Output: engine audio integration notes to merge with the technical-artist's plan

If no engine is configured, skip the specialist spawn.

### Step 4: Code Integration (gameplay-programmer)
Spawn the `gameplay-programmer` agent to:
- Implement audio manager system or review existing
- Wire up audio events to gameplay triggers
- Implement adaptive music system (if specified)
- Set up audio occlusion/reverb zones
- Write unit tests for audio event triggers

4. **Compile the audio design document** combining all team outputs.

5. **Save to** `design/audio/audio-[feature].md`.

   Note: If `design/audio/` does not exist, the sub-agent writing the document should create it (the directory will be created automatically when the file is written).

6. **Output a summary** with: audio event count, estimated asset count,
   implementation tasks, and any open questions between team members.

Verdict: **COMPLETE** — audio design document produced and team pipeline finished.

If the pipeline stops because a dependency is unresolved (e.g., critical accessibility gap or missing GDD not resolved by the user):

Verdict: **BLOCKED** — [reason]

## File Write Protocol

All file writes (audio design docs, SFX specs, implementation files) are delegated
to sub-agents spawned through generic sub-agent delegation. Each sub-agent enforces the "May I write to [path]?"
protocol. This orchestrator does not write files directly.

## Next Steps

- Review the audio design doc with the audio-director before implementation begins.
- Use `$dev-story` to implement the audio manager and event system once the design is approved.
- Run `$asset-audit` after audio assets are created to verify naming and format compliance.

## Error Recovery Protocol

If any spawned agent (through generic sub-agent delegation) returns BLOCKED, errors, or cannot complete:

1. **Surface immediately**: Report "[AgentName]: BLOCKED — [reason]" to the user before continuing to dependent phases
2. **Assess dependencies**: Check whether the blocked agent's output is required by subsequent phases. If yes, do not proceed past that dependency point without user input.
3. **Offer options** via a focused user question with choices:
   - Skip this agent and note the gap in the final report
   - Retry with narrower scope
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed. Never discard work because one agent blocked.

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `$architecture-decision` first
- Scope too large → split into two stories via `$create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
