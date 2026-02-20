---
name: team-ui
description: "Orchestrate the UI team: coordinates ux-designer, ui-programmer, and art-director to design, implement, and polish a user interface feature from wireframe to final."
argument-hint: "[UI feature description]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion, TodoWrite
---
When this skill is invoked, orchestrate the UI team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next phase.

## Team Composition
- **ux-designer** — User flows, wireframes, accessibility, input handling
- **ui-programmer** — UI framework, screens, widgets, data binding, implementation
- **art-director** — Visual style, layout polish, consistency with art bible

## How to Delegate

Use the Task tool to spawn each team member as a subagent:
- `subagent_type: ux-designer` — User flows, wireframes, accessibility, input handling
- `subagent_type: ui-programmer` — UI framework, screens, widgets, data binding
- `subagent_type: art-director` — Visual style, layout polish, art bible consistency

Always provide full context in each agent's prompt (feature requirements, existing UI patterns, platform targets). Launch independent agents in parallel where the pipeline allows it (e.g., Phase 4 review agents can run simultaneously).

## Pipeline

### Phase 1: UX Design
Delegate to **ux-designer**:
- Define the user flow for this feature (entry points, states, exit points)
- Create wireframes for each screen/state
- Specify interaction patterns: how does keyboard/mouse AND gamepad navigate this?
- Define accessibility requirements: text sizes, contrast, colorblind safety
- Identify data the UI needs to display (what game state does it read?)
- Output: UX spec with wireframes and interaction map

### Phase 2: Visual Design
Delegate to **art-director**:
- Review wireframes against the art bible
- Define visual treatment: colors, typography, spacing, animations
- Specify asset requirements (icons, backgrounds, decorative elements)
- Ensure consistency with existing UI screens
- Output: visual design spec with style notes

### Phase 3: Implementation
Delegate to **ui-programmer**:
- Implement the UI following the UX spec and visual design
- Ensure UI NEVER owns or modifies game state — display only, events for actions
- All text through localization system — no hardcoded strings
- Support both input methods (keyboard/mouse + gamepad)
- Implement accessibility features (text scaling, colorblind mode support)
- Wire up data binding to game state
- Output: implemented UI feature

### Phase 4: Review (parallel)
Delegate in parallel:
- **ux-designer**: Verify implementation matches wireframes and interaction spec. Test keyboard-only and gamepad-only navigation. Check accessibility.
- **art-director**: Verify visual consistency with art bible. Check at minimum and maximum supported resolutions.

### Phase 5: Polish
- Address review feedback
- Verify animations are skippable and respect motion preferences
- Confirm UI sounds trigger through audio event system
- Test at all supported resolutions and aspect ratios

## Output
A summary report covering: UX spec status, visual design status, implementation status, accessibility compliance, input method support, and any outstanding issues.
