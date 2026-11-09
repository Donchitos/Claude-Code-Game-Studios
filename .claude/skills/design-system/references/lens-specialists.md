# Lenses: the routing-table specialists (Section C, Visual/Audio)

Read at Section C when its specialist step runs, and at Visual/Audio. Use only
the rows SKILL.md §6 picks for this system: its Primary and Supporting roles.
Each row is what that agent checked.

## How to use them at Section C

Before drafting, look at the section's inputs (concept, pillars, dependency GDD
excerpts) through **each picked role in turn**, and write one short block per
role: what it would add, what it warns about. Then draft. Where two roles pull
different ways (feel vs telegraph time, depth vs readability, design vs
feasibility), **show both positions and put the choice to the person with
`AskUserQuestion`**; never settle it inside the draft. A tension between the
person's idea and a pillar or a dependency GDD is shown the same way.

## Roles

- **game-designer** — the core loop this system serves; the player's decisions
  and what makes each interesting; what the player cannot do; whether the
  rules deliver the Player Fantasy.
- **systems-designer** — rules precise enough to implement; states and every
  valid transition (flag an impossible or missing one); interaction matrices
  where elements combine; feedback loops. See `lens-systems-designer.md`.
- **economy-designer** — faucets and sinks; prices against progression;
  dominant purchases; registry values for items.
- **ai-programmer** — what enemies or agents perceive and decide; telegraphs
  and reaction windows readable by the player; cost of the behaviour.
- **gameplay-programmer** — feasibility: frame-rate independence, input
  buffering, which rules are data-driven; what is expensive to build.
- **engine-programmer** — integration: loading, save format, threading, what
  the engine already gives.
- **ux-designer** — the flow and its steps; the most important information is
  the most prominent; feedback for every action; accessibility floor (nothing
  by colour alone, remappable input, readable text).
- **ui-programmer** — feasibility of the screens: states, transitions, data
  binding, localisation room in text fields.
- **art-director** — visual feedback for the system's events, style
  constraints, which art bible principles apply.
- **technical-artist** — render, shader and rig constraints; the budget the
  effect fits in.
- **narrative-director** — the story beat the system carries; consistency with
  world and character arcs.
- **writer** — the player-facing text the system needs and its voice.
- **audio-director** / **sound-designer** — what each event sounds like and
  why; the mix priority of a warning cue.
- **level-designer** — the spaces the system needs; pacing across a level.
- **world-builder** — lore consistency of names, factions, places.

## Visual/Audio (the art-director row)

Read `design/art/art-bible.md` sections 1-4 by heading if it exists. Specify:
(1) the VFX and visual feedback for each of this system's events, (2) the
animation or style constraints, (3) the art bible principles that apply,
cited by name. Without an art bible, say so and draft from the pillars; never
leave a required Visual/Audio section `[To be designed]`.

## Limits

These lenses advise the draft; the person decides. No code, no file writes
outside the skill's own section cycle.
