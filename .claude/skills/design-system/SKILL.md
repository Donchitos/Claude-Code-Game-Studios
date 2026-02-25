---
name: design-system
description: "Guided, section-by-section GDD authoring for a single game system. Gathers context from existing docs, walks through each required section collaboratively, cross-references dependencies, and writes incrementally to file."
argument-hint: "<system-name> (e.g., 'combat-system', 'inventory', 'dialogue')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Parse Arguments & Validate

A system name argument is **required**. If missing, fail with:
> "Usage: `/design-system <system-name>` — e.g., `/design-system combat-system`
> Run `/map-systems` first to create the systems index, then use this skill
> to write individual system GDDs."

Normalize the system name to kebab-case for the filename (e.g., "combat system"
becomes `combat-system`).

---

## 2. Gather Context (Read Phase)

Read all relevant context **before** asking the user anything. This is the skill's
primary advantage over ad-hoc design — it arrives informed.

### 2a: Required Reads

- **Game concept**: Read `design/gdd/game-concept.md` — fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- **Systems index**: Read `design/gdd/systems-index.md` — fail if missing:
  > "No systems index found. Run `/map-systems` first to map your systems."
- **Target system**: Find the system in the index. If not listed, warn:
  > "[system-name] is not in the systems index. Would you like to add it, or
  > design it as an off-index system?"

### 2b: Dependency Reads

From the systems index, identify:
- **Upstream dependencies**: Systems this one depends on. Read their GDDs if they
  exist (these contain decisions this system must respect).
- **Downstream dependents**: Systems that depend on this one. Read their GDDs if
  they exist (these contain expectations this system must satisfy).

For each dependency GDD that exists, extract and hold in context:
- Key interfaces (what data flows between the systems)
- Formulas that reference this system's outputs
- Edge cases that assume this system's behavior
- Tuning knobs that feed into this system

### 2c: Optional Reads

- **Game pillars**: Read `design/gdd/game-pillars.md` if it exists
- **Existing GDD**: Read `design/gdd/[system-name].md` if it exists (resume, don't
  restart from scratch)
- **Related GDDs**: Glob `design/gdd/*.md` and read any that are thematically related
  (e.g., if designing "status-effects", also read "combat-system" even if it's not
  a direct dependency)

### 2d: Present Context Summary

Before starting design work, present a brief summary to the user:

> **Designing: [System Name]**
> - Priority: [from index] | Layer: [from index]
> - Depends on: [list, noting which have GDDs vs. undesigned]
> - Depended on by: [list, noting which have GDDs vs. undesigned]
> - Existing decisions to respect: [key constraints from dependency GDDs]
> - Pillar alignment: [which pillar(s) this system primarily serves]

If any upstream dependencies are undesigned, warn:
> "[dependency] doesn't have a GDD yet. We'll need to make assumptions about
> its interface. Consider designing it first, or we can define the expected
> contract and flag it as provisional."

Use `AskUserQuestion`:
- "Ready to start designing [system-name]?"
  - Options: "Yes, let's go", "Show me more context first", "Design a dependency first"

---

## 3. Create File Skeleton

Once the user confirms, **immediately** create the GDD file with empty section
headers. This ensures incremental writes have a target.

Use the template structure from `.claude/docs/templates/game-design-document.md`:

```markdown
# [System Name]

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Implements Pillar**: [from context]

## Overview

[To be designed]

## Player Fantasy

[To be designed]

## Detailed Design

### Core Rules

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
```

Ask: "May I create the skeleton file at `design/gdd/[system-name].md`?"

After writing, update `production/session-state/active.md` with:
- Task: Designing [system-name] GDD
- Current section: Starting (skeleton created)
- File: design/gdd/[system-name].md

---

## 4. Section-by-Section Design

Walk through each section in order. For **each section**, follow this cycle:

### The Section Cycle

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain, and surface any relevant
   decisions from dependency GDDs that constrain it.

2. **Questions**: Ask clarifying questions specific to this section. Use
   `AskUserQuestion` for constrained questions, conversational text for open-ended
   exploration.

3. **Options**: Where the section involves design choices (not just documentation),
   present 2-4 approaches with pros/cons. Explain reasoning in conversation text,
   then use `AskUserQuestion` to capture the decision.

4. **Decision**: User picks an approach or provides custom direction.

5. **Draft**: Write the section content in conversation text for review. Flag any
   provisional assumptions about undesigned dependencies.

6. **Approval**: Ask "Approve this section, or would you like changes?"

7. **Write**: Use the Edit tool to replace the `[To be designed]` placeholder with
   the approved content. Confirm the write.

After writing each section, update `production/session-state/active.md` with the
completed section name.

### Section-Specific Guidance

Each section has unique design considerations and may benefit from specialist agents:

---

### Section A: Overview

**Goal**: One paragraph a stranger could read and understand.

**Questions to ask**:
- What is this system in one sentence?
- How does a player interact with it? (active/passive/automatic)
- Why does this system exist — what would the game lose without it?

**Cross-reference**: Check that the description aligns with how the systems index
describes it. Flag discrepancies.

---

### Section B: Player Fantasy

**Goal**: The emotional target — what the player should *feel*.

**Questions to ask**:
- What emotion or power fantasy does this serve?
- What reference games nail this feeling? What specifically creates it?
- Is this a "system you love engaging with" or "infrastructure you don't notice"?

**Cross-reference**: Must align with the game pillars. If the system serves a pillar,
quote the relevant pillar text.

---

### Section C: Detailed Design (Core Rules, States, Interactions)

**Goal**: Unambiguous specification a programmer could implement without questions.

This is usually the largest section. Break it into sub-sections:

1. **Core Rules**: The fundamental mechanics. Use numbered rules for sequential
   processes, bullets for properties.
2. **States and Transitions**: If the system has states, map every state and
   every valid transition. Use a table.
3. **Interactions with Other Systems**: For each dependency (upstream and downstream),
   specify what data flows in, what flows out, and who owns the interface.

**Questions to ask**:
- Walk me through a typical use of this system, step by step
- What are the decision points the player faces?
- What can the player NOT do? (Constraints are as important as capabilities)

**Agent delegation**: For complex mechanics, use the Task tool to delegate to
`game-designer` for high-level design review, or `systems-designer` for detailed
mechanical modeling. Provide the full context gathered in Phase 2.

**Cross-reference**: For each interaction listed, verify it matches what the
dependency GDD specifies. If the dependency says "damage is calculated as X" and
this system expects something different, flag the conflict.

---

### Section D: Formulas

**Goal**: Every mathematical formula, with variables defined, ranges specified,
and edge cases noted.

**Questions to ask**:
- What are the core calculations this system performs?
- Should scaling be linear, logarithmic, or stepped?
- What should the output ranges be at early/mid/late game?

**Agent delegation**: For formula-heavy systems (combat, economy, progression),
delegate to `systems-designer` via the Task tool. Provide:
- The Core Rules from Section C (already written to file)
- Tuning goals from the user
- Balance context from dependency GDDs

The agent should return proposed formulas with variable tables and expected output
ranges. Present these to the user for review before approving.

**Cross-reference**: If a dependency GDD defines a formula whose output feeds into
this system, reference it explicitly. Don't reinvent — connect.

---

### Section E: Edge Cases

**Goal**: Explicitly handle unusual situations so they don't become bugs.

**Questions to ask**:
- What happens at zero? At maximum? At negative values?
- What happens when two effects trigger simultaneously?
- What happens if the player tries to exploit this? (Identify degenerate strategies)

**Agent delegation**: For systems with complex interactions, delegate to
`systems-designer` to identify edge cases from the formula space. For narrative
systems, consult `narrative-director` for story-breaking edge cases.

**Cross-reference**: Check edge cases against dependency GDDs. If combat says
"damage cannot go below 1" but this system can reduce damage to 0, that's a
conflict to resolve.

---

### Section F: Dependencies

**Goal**: Map every system connection with direction and nature.

This section is partially pre-filled from the context gathering phase. Present the
known dependencies from the systems index and ask:
- Are there dependencies I'm missing?
- For each dependency, what's the specific data interface?
- Which dependencies are hard (system cannot function without it) vs. soft
  (enhanced by it but works without it)?

**Cross-reference**: This section must be bidirectionally consistent. If this system
lists "depends on Combat", then the Combat GDD should list "depended on by [this
system]". Flag any one-directional dependencies for correction.

---

### Section G: Tuning Knobs

**Goal**: Every designer-adjustable value, with safe ranges and extreme behaviors.

**Questions to ask**:
- What values should designers be able to tweak without code changes?
- For each knob, what breaks if it's set too high? Too low?
- Which knobs interact with each other? (Changing A makes B irrelevant)

**Agent delegation**: If formulas are complex, delegate to `systems-designer`
to derive tuning knobs from the formula variables.

**Cross-reference**: If a dependency GDD lists tuning knobs that affect this system,
reference them here. Don't create duplicate knobs — point to the source of truth.

---

### Section H: Acceptance Criteria

**Goal**: Testable conditions that prove the system works as designed.

**Questions to ask**:
- What's the minimum set of tests that prove this works?
- What performance budget does this system get? (frame time, memory)
- What would a QA tester check first?

**Cross-reference**: Include criteria that verify cross-system interactions work,
not just this system in isolation.

---

### Optional Sections: Visual/Audio, UI Requirements, Open Questions

These sections are included in the template but aren't part of the 8 required
sections. Offer them after the required sections are done:

Use `AskUserQuestion`:
- "The 8 required sections are complete. Do you want to also define Visual/Audio
  requirements, UI requirements, or capture open questions?"
  - Options: "Yes, all three", "Just open questions", "Skip — I'll add these later"

For **Visual/Audio**: Coordinate with `art-director` and `audio-director` if detail
is needed. Often a brief note suffices at the GDD stage.

For **UI Requirements**: Coordinate with `ux-designer` for complex UI systems.

For **Open Questions**: Capture anything that came up during design that wasn't
fully resolved. Each question should have an owner and target resolution date.

---

## 5. Post-Design Validation

After all sections are written:

### 5a: Self-Check

Read back the complete GDD from file (not from conversation memory — the file is
the source of truth). Verify:
- All 8 required sections have real content (not placeholders)
- Formulas reference defined variables
- Edge cases have resolutions
- Dependencies are listed with interfaces
- Acceptance criteria are testable

### 5b: Offer Design Review

Present a completion summary:

> **GDD Complete: [System Name]**
> - Sections written: [list]
> - Provisional assumptions: [list any assumptions about undesigned dependencies]
> - Cross-system conflicts found: [list or "none"]

Use `AskUserQuestion`:
- "Run `/design-review` now to validate the GDD?"
  - Options: "Yes, run review now", "I'll review it myself first", "Skip review"

If yes, invoke the design-review skill on the completed file.

### 5c: Update Systems Index

After the GDD is complete (and optionally reviewed):

- Read the systems index
- Update the target system's row:
  - If design-review was run and verdict is APPROVED: Status → "Approved"
  - If design-review was run and verdict is NEEDS REVISION: Status → "In Review"
  - If design-review was skipped: Status → "Designed" (pending review)
  - If the user chose "I'll review it myself first": Status → "Designed"
  - Design Doc: link to `design/gdd/[system-name].md`
- Update the Progress Tracker counts

Ask: "May I update the systems index at `design/gdd/systems-index.md`?"

### 5d: Update Session State

Update `production/session-state/active.md` with:
- Task: [system-name] GDD
- Status: Complete (or In Review if design-review was run)
- File: design/gdd/[system-name].md
- Sections: All 8 written
- Next: [suggest next system from design order]

### 5e: Suggest Next Steps

Use `AskUserQuestion`:
- "What's next?"
  - Options:
    - "Design next system ([next-in-order])" — if undesigned systems remain
    - "Fix review findings" — if design-review flagged issues
    - "Stop here for this session"
    - "Run `/gate-check`" — if enough MVP systems are designed

---

## 6. Specialist Agent Routing

This skill delegates to specialist agents for domain expertise. The main session
orchestrates the overall flow; agents provide expert content.

| System Category | Primary Agent | Supporting Agent(s) |
|----------------|---------------|---------------------|
| Combat, damage, health | `game-designer` | `systems-designer` (formulas), `ai-programmer` (enemy AI) |
| Economy, loot, crafting | `economy-designer` | `systems-designer` (curves), `game-designer` (loops) |
| Progression, XP, skills | `game-designer` | `systems-designer` (curves), `economy-designer` (sinks) |
| Dialogue, quests, lore | `game-designer` | `narrative-director` (story), `writer` (content) |
| UI systems (HUD, menus) | `game-designer` | `ux-designer` (flows), `ui-programmer` (feasibility) |
| Audio systems | `game-designer` | `audio-director` (direction), `sound-designer` (specs) |
| AI, pathfinding, behavior | `game-designer` | `ai-programmer` (implementation), `systems-designer` (scoring) |
| Level/world systems | `game-designer` | `level-designer` (spatial), `world-builder` (lore) |
| Camera, input, controls | `game-designer` | `ux-designer` (feel), `gameplay-programmer` (feasibility) |

**When delegating via Task tool**:
- Provide: system name, game concept summary, dependency GDD excerpts, the specific
  section being worked on, and what question needs expert input
- The agent returns analysis/proposals to the main session
- The main session presents the agent's output to the user via `AskUserQuestion`
- The user decides; the main session writes to file
- Agents do NOT write to files directly — the main session owns all file writes

---

## 7. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current system and
   which sections are complete
2. Read `design/gdd/[system-name].md` — sections with real content are done;
   sections with `[To be designed]` still need work
3. Resume from the next incomplete section — no need to re-discuss completed ones

This is why incremental writing matters: every approved section survives any
disruption.

---

## Collaborative Protocol

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): Design questions, approach options, draft approval
   - Phase 5: "Run design review? Update systems index? What's next?"
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write
6. **Cross-referencing**: Every section checks existing GDDs for conflicts
7. **Specialist routing**: Complex sections get expert agent input, presented to
   the user for decision — never written silently

**Never** auto-generate the full GDD and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved GDD without flagging the conflict.
**Always** show where decisions come from (dependency GDDs, pillars, user choices).
