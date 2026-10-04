> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — HUD Design Mode


HUD design follows a different order from UX spec mode. Begin with philosophy;
do not touch layout until the information architecture is complete.

#### Section A: HUD Philosophy

Ask the user to describe the game's relationship with on-screen information in
1-2 sentences.

Offer framing examples to help:
- "Nearly HUD-free — atmosphere requires unobstructed immersion (e.g., Hollow Knight, Firewatch)"
- "Minimal but present — only critical information visible, everything else contextual (e.g., Dark Souls)"
- "Information-dense — all decision-relevant data always visible (e.g., Diablo IV, StarCraft II)"
- "Adaptive — HUD density responds to combat state, exploration mode, menus (e.g., God of War)"

This philosophy becomes the design constraint for every subsequent HUD decision.
If a proposed element conflicts with the stated philosophy, surface that conflict.

---

#### Section B: Information Architecture

Complete this before any layout work. Do not skip it.

**Step 1 — Full information inventory**:
Pull all information from GDD UI Requirements sections gathered in Phase 2.
Present the full list: "These are all the things your game systems say they need
to communicate to the player on screen."

**Step 2 — Categorization**:
For each item, ask the user to categorize it:

| Category | Description |
|----------|-------------|
| **Must Show** | Always visible, player needs it for core decisions |
| **Contextual** | Visible only when relevant (in combat, near interactable, etc.) |
| **On Demand** | Player must actively request it (toggle, hold button) |
| **Hidden** | Communicated through world/audio, never on-screen text |

Use `AskUserQuestion` to step through items in groups of 3-4, not all at once.
This is the most consequential design decision in the HUD — do not rush it.

**Conflict check**: If the information philosophy (Section A) says "nearly HUD-free"
but the Must Show list is growing long, surface the conflict explicitly:
> "The current Must Show list has [N] items. That may conflict with the HUD-free
> philosophy. Options: reduce the Must Show list, revise the philosophy, or define
> a hybrid approach where HUD is absent in exploration and present in combat."

---

#### Section C: Layout Zones

Only after the information architecture is approved, design layout zones.

Base layout on:
- Which items are Must Show (they drive the permanent zone decisions)
- Where player attention naturally goes during gameplay (center-screen for action games,
  corners for strategy games)
- Platform and aspect ratio targets

Offer 2-3 zone arrangements. Include rationale based on the HUD philosophy and the
categorization from Section B.

---

#### Section D: HUD Element Specifications

For each element in the layout, specify:
- Element name and category (Must Show / Contextual / On Demand)
- Content displayed
- Visual form (bar, number, icon, counter, map)
- Update behavior (real-time, event-driven, player-queried)
- Contextual trigger (if not always visible)
- Animation behavior (does it pulse when low? Fade in? Slam in?)

Work element by element. Reference the interaction pattern library if relevant patterns
exist for status displays, resource bars, or cooldown indicators.

---

#### Sections E–L: HUD States, Information Hierarchy, Visual Budget, Feedback & Notification, Platform Adaptation, Accessibility, Tuning Knobs, Acceptance Criteria

These parallel the UX spec's States, Interaction, and Accessibility sections.
The guidance you need is below — **do not load `sections-ux-spec.md`; one mode
file applies per invocation.** For the HUD, apply it as follows.

**HUD States by Gameplay Context (states over time).** Cover at least
exploration, combat, dialogue/cutscene and paused — `/ux-review` checks for all
four. Beyond the happy path, capture what changes the HUD mid-gameplay and present
it as a table for approval:

| State / Variant | Trigger | What Changes |
|-----------------|---------|--------------|
| Default | Normal play | — |
| Low-resource | Health/ammo/etc. below threshold | [element pulses, recolors, …] |
| Empty / no-data | Element has nothing to show | [hidden, or placeholder] |
| [etc.] | [trigger] | [changes] |

Ask specifically: what causes the HUD to change density mid-gameplay
(combat vs. exploration), and what fades, pulses, or slams in on each transition?

**Information Hierarchy.** Give every element in HUD Element Specifications a
priority tier — MUST KEEP, SHOULD KEEP, CAN HIDE or ALWAYS HIDE — with the reason,
and what carries its information when it is hidden (a sound, a diegetic cue, or
nothing). This is the order the Visual Budget below drops elements in.

**Visual Budget.** State the maximum number of simultaneous HUD elements and
the maximum share of the screen the HUD may cover, and which elements are dropped
first when a state would exceed it.

**Feedback & Notification Systems.** One row per transient notification type
(pickup, XP gain, objective update, achievement) — trigger system, screen position,
duration, max simultaneous, priority and **queue behavior**: what happens when two
arrive at once, which are held during combat, and which are never queued.
`/ux-review` checks that every notification has queue/priority behavior defined.

**Platform Adaptation.** Does mobile/console require different element sizes or
positions? Note per-platform overrides — touch targets, safe-area insets, and
whether any element moves or is dropped on a given platform.

**Accessibility.** Cross-reference `design/accessibility-requirements.md` if it
exists, then walk this checklist for the HUD:
- Gamepad/keyboard focus order for any interactive HUD element
- Text contrast and minimum readable font sizes at gameplay distance
- Color-independent communication (no state conveyed by color alone — a
  low-health cue must not be red-only)
- Reduced-motion alternative for any pulsing/flashing HUD animation
- Screen-reader considerations for non-text indicators

If no accessibility tier has been defined for this project, note the gap in the
HUD design's Open Questions section (WCAG-AA is a reasonable baseline) and
continue without stopping.

**Tuning Knobs.** List every player-adjustable HUD setting — overall scale,
opacity, per-element show/hide, subtitle size — with its range and default.

**Acceptance Criteria.** At least 5 checkbox criteria a QA tester can verify
without reading another document — `/story-done` closes HUD stories against
them. Cover at least: safe-zone margins on every target platform, the correct
elements in each gameplay context above, the visual budget (screen share in
exploration and in combat), one accessibility criterion for the committed tier,
and notification queueing. Section 12 of `.claude/docs/templates/hud-design.md`
has worked examples.
