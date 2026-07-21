# Example Session: Using $design-system to Author a GDD

**Context:** Solo indie dev, week 3 of project. `$map-systems` already ran and produced `design/gdd/systems-index.md`. The movement system is listed as MVP tier, Foundation priority.

**Starting State:**
- `design/gdd/game-concept.md` exists (survival-crafting game, 2D, Godot 4.6)
- `design/gdd/systems-index.md` exists (15 systems identified, movement is first in design order)
- No per-system GDDs written yet
- No upstream dependencies for movement (it is the foundation)

**Session Duration:** ~60 minutes
**Turns:** 14
**Outcome:** Complete `design/gdd/movement-system.md` with all 8 required sections written to file, ready for `$design-review`

---

## Turn 1: User Invokes the Skill

**User:**
> $design-system movement

## Turn 2: Agent Loads Context and Presents the Plan

**Agent (game-designer, via $design-system):**
> I'm loading context before we start:
>
> - Read `design/gdd/game-concept.md` — survival-crafting, exploration-heavy, lone survivor stranded on alien planet
> - Read `design/gdd/systems-index.md` — movement is **Foundation / MVP**, no upstream deps, downstream: combat, exploration, stamina
> - No prior GDD found for movement — starting fresh
>
> **Technical Feasibility Pre-Check:**
>
> | Domain | Signal |
> |--------|--------|
> | Engine | Godot 4.6 — CharacterBody2D with move_and_slide() is well-supported |
> | Physics | Jolt is now the default in 4.6 — 2D movement unaffected, but note for future 3D work |
> | Downstream risk | Stamina system listed as downstream dep — movement must expose a stamina callback hook |
>
> The GDD template has **8 required sections**. We'll go one at a time:
> `Overview → Player Fantasy → Detailed Rules → Formulas → Edge Cases → Dependencies → Tuning Knobs → Acceptance Criteria`
>
> I'll show you a draft of each section, you approve or revise, then I write it to the file before we move on.
>
> Creating the file skeleton now with empty section headers — may I write `design/gdd/movement-system.md` with placeholders?

**User:**
> Yes

**Agent writes** `design/gdd/movement-system.md` with 8 empty section headers.

---

## Turn 3: Section 1 — Overview

**Agent:**
> **Section 1 draft — Overview:**
>
> > The movement system is the player's primary interface with the world. It governs how the lone survivor walks, runs, rolls, and traverses alien terrain. Movement is physically grounded — the planet has heavier-than-Earth gravity, and the survivor is physically exhausted — but remains responsive enough to stay out of the player's way. The system feeds directly into exploration pacing, combat positioning, and the stamina system.
>
> Does this capture what you want?

**User:**
> Good but add something about the terrain — surfaces slow you down or have friction modifiers.

**Agent:**
> Revised:
>
> > The movement system is the player's primary interface with the world. It governs how the lone survivor walks, runs, rolls, and traverses alien terrain. Movement is physically grounded — the planet has heavier-than-Earth gravity, and the survivor is physically exhausted — but remains responsive enough to stay out of the player's way. Terrain surfaces apply friction and speed modifiers (slick rock, sand, shallow water) that make navigation a meaningful skill. The system feeds directly into exploration pacing, combat positioning, and the stamina system.
>
> May I write this to Section 1 in the file?

**User:**
> Yes

**Agent writes Section 1 to file.**

---

## Turn 4: Section 2 — Player Fantasy

**Agent:**
> **Section 2 draft — Player Fantasy:**
>
> > The player should feel like a tired but capable survivor — not a superhero, not helpless. Early game movement is deliberate and taxing; the player earns fluency over time. When traversing alien terrain, the goal is careful navigation with moments of urgency (running from threats, leaping a gap). The fantasy is "I know this terrain" — every surface type becomes readable and manageable as the player internalizes the friction system.
>
> Approve, revise, or change direction?

**User:**
> Love it. Write it.

**Agent writes Section 2 to file.**

---

## Turn 5: Section 3 — Detailed Rules

**Agent:**
> **Section 3 draft — Detailed Rules:**
>
> > **Base States:**
> > - **Walk** (default): Full directional control, moderate speed, low stamina drain
> > - **Run** (hold Shift): Faster, medium stamina drain per second — cancels automatically when stamina hits 0
> > - **Roll/Dodge** (tap Space): Quick burst in movement direction, brief invincibility frames, high stamina cost (flat)
> > - **Idle**: Zero movement input, stamina regenerates at full rate
> >
> > **Terrain Modifiers:**
> > - Normal ground: 1.0x speed multiplier, standard friction
> > - Sand/loose soil: 0.8x speed, 1.1x stamina drain (harder to move)
> > - Slick rock (wet): 1.1x speed, reduced stop friction (player overshoots)
> > - Shallow water (ankle-deep): 0.7x speed, no friction modifier
> > - Deep water: movement disabled, replaced by swimming (separate system, out of scope)
> >
> > **Collision:**
> > - CharacterBody2D + move_and_slide(); wall slide enabled
> > - Slopes up to 45° walked normally; >45° blocked
> > - One-way platforms supported (drop-through with Down + Jump)
>
> A lot here — want me to trim or expand anything?

**User:**
> Add that running is disabled when carrying a heavy object (like a large resource chunk).

**Agent:**
> Added to Run rule:
> > - **Run** (hold Shift): Faster, medium stamina drain per second — cancels automatically when stamina hits 0. **Disabled when carrying heavy objects** (signals broadcast by inventory system).
>
> Write to file?

**User:**
> Yes

**Agent writes Section 3 to file.**

---

## Turn 6: Section 4 — Formulas

**Agent:**
> **Section 4 draft — Formulas:**
>
> Let me define variables first, then the formulas:
>
> | Variable | Type | Description |
> |----------|------|-------------|
> | `base_walk_speed` | float | Base walk speed in px/s (tunable) |
> | `run_multiplier` | float | Run speed = walk × this |
> | `terrain_speed_mod` | float | Per-terrain multiplier (0.7–1.1) |
> | `stamina_drain_walk` | float | Stamina units/sec while walking |
> | `stamina_drain_run` | float | Stamina units/sec while running |
> | `stamina_cost_roll` | float | Flat stamina cost per roll |
> | `terrain_drain_mod` | float | Per-terrain stamina drain multiplier |
>
> **Effective Speed:**
> ```
> effective_speed = base_walk_speed × run_multiplier (if running, else 1.0) × terrain_speed_mod
> ```
>
> **Stamina Drain (per second):**
> ```
> drain_per_sec = stamina_drain_walk (or stamina_drain_run if running) × terrain_drain_mod
> ```
>
> **Roll Stamina Cost (flat):**
> ```
> stamina_after_roll = current_stamina - stamina_cost_roll
> (clamped to 0 — roll still executes, but player lands with 0 stamina)
> ```
>
> Approve or adjust variable names/formulas?

**User:**
> Looks right. Write it.

**Agent writes Section 4 to file.**

---

## Turn 7–9: Sections 5, 6, 7

*(These follow the same pattern — agent drafts, user approves or requests minor tweaks, agent writes each section to file before moving on. Abbreviated here.)*

**Section 5 — Edge Cases** covered:
- Player rolls into a wall (animation completes, no movement bonus)
- Stamina hits 0 mid-run (transitions to walk, no lurch)
- Two terrain types overlapping (lower multiplier wins)
- Roll on slick rock (still applies slick friction to stopping, not to the roll itself)

**Section 6 — Dependencies** covered:
- **Stamina system** (downstream): movement exposes `on_stamina_event(type: String, amount: float)` signal
- **Inventory system** (downstream): listens to `carrying_heavy_object_changed(is_heavy: bool)` signal
- **Input system**: movement direction from `InputMap` — standard Godot action names (`ui_left`, `ui_right`, etc.)
- **Terrain layer**: tile metadata drives terrain modifier lookup

**Section 7 — Tuning Knobs** covered:
- `base_walk_speed` (default: 120 px/s)
- `run_multiplier` (default: 1.7)
- Per-terrain speed and drain modifiers (table of 4 terrain types)
- `stamina_drain_walk`, `stamina_drain_run`, `stamina_cost_roll`

---

## Turn 10: Section 8 — Acceptance Criteria

**Agent:**
> **Section 8 draft — Acceptance Criteria:**
>
> These are the testable conditions that prove this system is complete:
>
> - [ ] Player walks at `base_walk_speed` on normal ground (measured with debug overlay)
> - [ ] Player runs at `base_walk_speed × run_multiplier` on normal ground
> - [ ] Run automatically cancels when stamina reaches 0, no input required
> - [ ] Roll executes with correct invincibility frames (verify via hitbox debug mode)
> - [ ] Each terrain type applies the correct speed modifier (QA table in sprint plan)
> - [ ] Carrying heavy object disables run (test with inventory integration)
> - [ ] Stamina system receives `on_stamina_event` signals during walk, run, and roll
> - [ ] All movement values come from exported variables — no hardcoded numbers in code
>
> Does this cover what "done" means to you?

**User:**
> Add one for slopes — make sure >45 degree slopes block movement.

**Agent:**
> Added:
> - [ ] Slopes ≤45° traversed normally; slopes >45° block movement (player slides back)
>
> Write to file?

**User:**
> Yes. Write it.

**Agent writes Section 8 to file.**

---

## Turn 11: Completion Summary

**Agent:**
> All 8 sections written to `design/gdd/movement-system.md`.
>
> **GDD Status:**
> - ✅ Overview
> - ✅ Player Fantasy
> - ✅ Detailed Rules
> - ✅ Formulas
> - ✅ Edge Cases
> - ✅ Dependencies (exposes 2 signals: stamina_event, carrying_heavy)
> - ✅ Tuning Knobs
> - ✅ Acceptance Criteria
>
> **Key decisions made:**
> - Terrain modifiers as tile metadata (not code constants)
> - Rolling has a flat stamina cost (not per-second)
> - Heavy carry disables run (signal-driven, not hardcoded check)
>
> **Recommended next step:** Run `$design-review design/gdd/movement-system.md` before moving to the next system in your queue (stamina is next in dependency order, per systems-index).
>
> The review will validate completeness, internal consistency, and catch anything that needs revision before you build on this GDD.

---

## What This Example Demonstrates

- **Incremental file writing**: each section written to disk immediately after approval — a session crash loses at most one in-progress section
- **Template population**: the GDD template's 8 sections become concrete content through dialogue, not bulk generation
- **Dependency signaling**: agent proactively surfaces downstream signal contracts (stamina, inventory) during the Dependencies section
- **Technical feasibility pre-check**: agent notes Jolt physics change before design starts, not after implementation breaks
- **Section-by-section cycle**: no full draft dumped at once — each section is a small, reviewable unit
- **Recovery**: if the session crashes, the agent re-reads the file on restart and resumes from the first empty section
