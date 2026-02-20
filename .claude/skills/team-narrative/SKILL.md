---
name: team-narrative
description: "Orchestrate the narrative team: coordinates narrative-director, writer, world-builder, and level-designer to create cohesive story content, world lore, and narrative-driven level design."
argument-hint: "[narrative content description]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, TodoWrite
---
When this skill is invoked, orchestrate the narrative team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next phase.

## Team Composition
- **narrative-director** — Story arcs, character design, dialogue strategy, narrative vision
- **writer** — Dialogue writing, lore entries, item descriptions, in-game text
- **world-builder** — World rules, faction design, history, geography, environmental storytelling
- **level-designer** — Level layouts that serve the narrative, pacing, environmental storytelling beats

## How to Delegate

Use the Task tool to spawn each team member as a subagent:
- `subagent_type: narrative-director` — Story arcs, character design, narrative vision
- `subagent_type: writer` — Dialogue writing, lore entries, in-game text
- `subagent_type: world-builder` — World rules, faction design, history, geography
- `subagent_type: level-designer` — Level layouts that serve the narrative, pacing

Always provide full context in each agent's prompt (narrative brief, lore dependencies, character profiles). Launch independent agents in parallel where the pipeline allows it (e.g., Phase 2 agents can run simultaneously).

## Pipeline

### Phase 1: Narrative Direction
Delegate to **narrative-director**:
- Define the narrative purpose of this content: what story beat does it serve?
- Identify characters involved, their motivations, and how this fits the overall arc
- Set the emotional tone and pacing targets
- Specify any lore dependencies or new lore this introduces
- Output: narrative brief with story requirements

### Phase 2: World Foundation (parallel)
Delegate in parallel:
- **world-builder**: Create or update lore entries for factions, locations, and history relevant to this content. Cross-reference against existing lore for contradictions. Set canon level for new entries.
- **writer**: Draft character dialogue using voice profiles. Ensure all lines are under 120 characters, use named placeholders for variables, and are localization-ready.

### Phase 3: Level Narrative Integration
Delegate to **level-designer**:
- Review the narrative brief and lore foundation
- Design environmental storytelling elements in the level
- Place narrative triggers, dialogue zones, and discovery points
- Ensure pacing serves both gameplay and story

### Phase 4: Review and Consistency
Delegate to **narrative-director**:
- Review all dialogue against character voice profiles
- Verify lore consistency across new and existing entries
- Confirm narrative pacing aligns with level design
- Check that all mysteries have documented "true answers"

### Phase 5: Polish
- Writer reviews all text for localization readiness
- Verify no line exceeds dialogue box constraints
- Confirm all text uses string keys (localization pipeline ready)
- World-builder finalizes canon levels for all new lore

## Output
A summary report covering: narrative brief status, lore entries created/updated, dialogue lines written, level narrative integration points, consistency review results, and any unresolved contradictions.
