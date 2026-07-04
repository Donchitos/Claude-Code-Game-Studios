# Systems Index: The Drop

> **Status**: Draft
> **Created**: 2026-07-04
> **Last Updated**: 2026-07-04
> **Source Concept**: `design/gdd/game-concept.md`
> **Visual Source**: `design/art/art-bible.md`
> **Review Mode**: Full backfill complete 2026-07-04
> **Backfilled Reviews**: CD-SYSTEMS APPROVE; TD-SYSTEM-BOUNDARY CONCERNS; PR-SCOPE OPTIMISTIC; Concept -> Systems phase gate CONCERNS overall, no blockers

---

## Overview

The Drop needs a small set of deeply connected systems: deterministic top-down
diving, four-slot relic builds, legible wreck state, oxygen/extraction pressure,
one creature, one rival, and a broadcast layer that records and publicizes what
happened. The full vision includes bloodlines, memorials, sponsors, multiplayer,
and seasons, but near-term design must protect the smallest real game: one great
wreck where fog, greed, relics, oxygen, and authored danger already work.

The social design is intentionally scoped around one backbone: the **Public
Ledger**. NPC rival reactions, sponsor flavor, memorial text, and Showrunner
callbacks are not separate management games. They are later consumers of the same
structured dive facts: who killed, spared, betrayed, drowned, extracted, carried
trophies, and survived the deep.

---

## Scope Guardrails

- **Build the ledger once**: every social feature reads structured event facts
  rather than inventing its own memory system.
- **MVP social scope is small**: event log, per-dive Heat, 3-5 public Marks, and
  an end-of-dive recap. Persistent sponsor and memorial systems are deferred.
- **NPCs mean rival divers first**: no townspeople, quest givers, dialogue trees,
  faction schedules, or settlement simulation.
- **Sponsors are flavor until proven**: sponsor output can be contract labels,
  insurance text, and barks before it becomes an economy.
- **Memorials are rare receipts**: the wall and heirloom use the ledger when true
  death exists; they are not part of the MVP dive loop.
- **Netcode is staged**: the game must be complete solo with NPC rivals before
  human contested dives become a production dependency.
- **First Playable Proof is narrower than MVP-Complete**: the first implementation
  target proves one playable loop, not all 13 MVP systems at full design scope.
- **Wet substrate is capped by readability**: six properties are the full budget;
  the first playable proof should use only the 2-3 properties that are visible,
  teachable, and compositionally useful.
- **Runtime facts stay raw**: the Event Log records authored facts; Feed, Heat,
  Marks, Recap, and Public Ledger derive interpretation from those facts.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---:|---|---|---|---|---|---|
| 1 | Dive Runtime & Event Log | Core | MVP | Reviewed 2026-07-04 — NEEDS REVISION, blockers resolved in-doc; 5 ADRs + TD perf-budget pending | `design/gdd/dive-runtime-event-log.md` | - |
| 2 | Player Controls, Camera & Casting | Core | MVP | Not Started | `design/gdd/player-controls-camera-casting.md` | - |
| 3 | Wreck Layout, Navigation & Fog | Gameplay | MVP | Not Started | `design/gdd/wreck-layout-navigation-fog.md` | Dive Runtime; Controls |
| 4 | Oxygen, Extraction & Greed Loop | Gameplay | MVP | Not Started | `design/gdd/oxygen-extraction-greed-loop.md` | Dive Runtime; Wreck Layout |
| 5 | Relic Loadouts & Item Verbs | Gameplay / Economy | MVP | Not Started | `design/gdd/relic-loadouts-item-verbs.md` | Dive Runtime; Controls |
| 6 | Wet Substrate Simulation | Gameplay | MVP | Not Started | `design/gdd/wet-substrate-simulation.md` | Dive Runtime; Wreck Layout |
| 7 | Combat, Health & Defeat | Gameplay | MVP | Not Started | `design/gdd/combat-health-defeat.md` | Dive Runtime; Controls; Relics; Wet Substrate |
| 8 | Creature AI & Ecology | Gameplay / AI | MVP | Not Started | `design/gdd/creature-ai-ecology.md` | Dive Runtime; Wet Substrate; Combat |
| 9 | Rival Diver AI & Habits | Gameplay / AI | MVP | Not Started | `design/gdd/rival-diver-ai-habits.md` | Dive Runtime; Controls; Wreck Layout; Combat; Wet Substrate |
| 10 | Loot, Salvage & Banking | Economy | MVP | Not Started | `design/gdd/loot-salvage-banking.md` | Dive Runtime; Oxygen/Extraction |
| 11 | Feed, Heat, Marks & Public Ledger | Narrative / UI / Meta | MVP | Not Started | `design/gdd/feed-heat-marks-public-ledger.md` | Dive Runtime & Event Log; Combat; Loot; Extraction |
| 12 | HUD, Onboarding & Relic Readability (inferred) | UI | MVP | Not Started | `design/gdd/hud-onboarding-relic-readability.md` | Controls; Relics; Oxygen; Combat; Wreck Layout; Feed/Ledger |
| 13 | Dive Feedback, VFX & Audio Cues (inferred) | Presentation / Audio | MVP | Not Started | `design/gdd/dive-feedback-vfx-audio.md` | Controls; Relics; Wet Substrate; Combat; Creature AI; Rival AI |
| 14 | Save/Profile Persistence (inferred) | Persistence | Vertical Slice | Not Started | `design/gdd/save-profile-persistence.md` | Dive Runtime; Event Log; Loot |
| 15 | Bloodline, Scars & Death Dial | Progression / Persistence | Vertical Slice | Not Started | `design/gdd/bloodline-scars-death-dial.md` | Combat/Defeat; Save/Profile; Event Log; Public Ledger |
| 16 | Barge Hub & Loadout Flow (inferred) | UI / Meta | Vertical Slice | Not Started | `design/gdd/barge-hub-loadout-flow.md` | Save/Profile; Relics; Loot; Bloodline |
| 17 | Dive Board & Match Types | Meta | Vertical Slice | Not Started | `design/gdd/dive-board-match-types.md` | Save/Profile; Loot; Rival AI; Public Ledger |
| 18 | Showrunner Director & Booking | AI / Narrative | Vertical Slice | Not Started | `design/gdd/showrunner-director-booking.md` | Public Ledger; Feed; Dive Board; Rival AI; Bloodline |
| 19 | Accessibility, Settings & Input Options (inferred) | UI / Meta | Vertical Slice | Not Started | `design/gdd/accessibility-settings-input.md` | Controls; HUD; Feedback |
| 20 | Progression & Depth Gates | Progression | Alpha | Not Started | `design/gdd/progression-depth-gates.md` | Loot; Save/Profile; Dive Board |
| 21 | Persistent NPC Rival Bloodlines & Grudges | AI / Narrative | Alpha | Not Started | `design/gdd/npc-rival-bloodlines-grudges.md` | Rival AI; Save/Profile; Public Ledger; Showrunner |
| 22 | Memorial, Heirloom & Wall | Narrative / Persistence | Alpha | Not Started | `design/gdd/memorial-heirloom-wall.md` | Bloodline; Public Ledger; Save/Profile; Feed |
| 23 | Contracts & Sponsor Flavor | Economy / Meta | Alpha | Not Started | `design/gdd/contracts-sponsor-flavor.md` | Public Ledger; Loot; Bloodline; Dive Board |
| 24 | Episode Formats & Modifiers | Meta | Alpha | Not Started | `design/gdd/episode-formats-modifiers.md` | Showrunner; Dive Board; Relics; Wet Substrate |
| 25 | Alliance, Betrayal & Reputation | Meta / Social | Alpha | Not Started | `design/gdd/alliance-betrayal-reputation.md` | Public Ledger; Feed; Rival/Human Participants; Dive Board |
| 26 | Multiplayer Contested Dives & Netcode | Network / Core | Alpha | Not Started | `design/gdd/multiplayer-contested-dives-netcode.md` | Dive Runtime; Controls; Combat; Event Log |
| 27 | Showdown Ladder & Seasons | Progression / Meta | Full Vision | Not Started | `design/gdd/showdown-ladder-seasons.md` | Dive Board; Feed; Save/Profile; NPC/Multiplayer Showdowns |
| 28 | Tier 3 LLM Narrative Generation | Narrative | Full Vision | Not Started | `design/gdd/tier3-llm-narrative-generation.md` | Public Ledger; Memorial; Showrunner; Template Fallback |

---

## Categories

| Category | Description | Systems |
|---|---|---|
| **Core** | Runtime, input, camera, deterministic simulation, and online boundaries | Dive Runtime; Controls; Multiplayer |
| **Gameplay** | Moment-to-moment dive rules and authored danger | Wreck/Fog; Oxygen; Relics; Wet Substrate; Combat; Creature AI; Rival AI |
| **Economy** | Loot, risk, banking, contracts, and non-power progression inputs | Loot/Banking; Relics; Contracts |
| **Persistence** | Save data and continuity between dives | Save/Profile; Bloodline; Memorial |
| **UI** | Player-facing clarity, onboarding, HUD, and loadout flows | HUD; Barge Hub; Accessibility |
| **Presentation / Audio** | Readability and sensory feedback around water, combat, and broadcast | Dive Feedback; VFX; Audio cues |
| **AI / Narrative** | Rival behavior, Showrunner logic, callbacks, and authored memory | Rival AI; Showrunner; NPC Bloodlines; LLM |
| **Meta / Social** | Dive selection, public marks, reputation, alliances, ladder, seasons | Public Ledger; Dive Board; Alliance; Ladder |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|---|---|---|---|
| **MVP** | Required to test whether the dive loop is fun and readable | First real playable loop | Design FIRST |
| **Vertical Slice** | Required for one complete, polished wreck experience | Vertical slice / demo | Design SECOND |
| **Alpha** | Complete mechanical scope in rough form | Alpha milestone | Design THIRD |
| **Full Vision** | Release-scale meta, online, and advanced narrative features | Beta / Release | Design as needed |

### Milestone Cut Lines

| Cut Line | Purpose | Included Scope | Explicitly Deferred |
|---|---|---|---|
| **First Playable Proof** | Prove the smallest real dive loop before broad MVP implementation | Runtime/event log, controls/casting, one wreck slice, oxygen/extraction, 4-6 relics, basic combat, one creature, one simple rival, loot/banking, HUD clarity, minimal recap | Broad Feed economy, many Marks, persistent rival bloodlines, memorials, sponsors, ladder, multiplayer, LLM generation |
| **MVP-Complete** | Complete the 13 MVP systems listed below at constrained scope | All MVP systems, with Feed/Ledger limited to event facts, end recap, and 1-2 Marks until core loop proof | Vertical-slice persistence, bloodline systems, hub flow, dive board, Showrunner booking |
| **Vertical Slice** | One polished, repeatable wreck experience | Persistence-lite, bloodline/scar basics, loadout flow, dive board, simple Showrunner pacing/callbacks | Full economy breadth, many rival bloodlines, seasons, public matchmaking, advanced narrative generation |

### MVP Systems

MVP systems are the minimum needed to preserve the v3 wins and fix the v3
failures: sweaty-hands movement, fog pressure, full-kit agency, clear goals,
legible relics, larger/denser rooms, and first-contact pressure with context.
First-dive objective clarity is a shared MVP acceptance burden for `Oxygen,
Extraction & Greed Loop`, `HUD, Onboarding & Relic Readability`, and `Loot,
Salvage & Banking`.

| System | Why |
|---|---|
| Dive Runtime & Event Log | Every authored outcome and future social callback depends on reliable structured facts. |
| Player Controls, Camera & Casting | The embodied WASD + mouse feel is the validated core hypothesis. |
| Wreck Layout, Navigation & Fog | Preserves the best v3 beat: not seeing the enemy, then revealing and shooting it down. |
| Oxygen, Extraction & Greed Loop | Gives the first dive a goal and makes greed a readable pressure curve. |
| Relic Loadouts & Item Verbs | Build-is-class only works if the player understands their four verbs immediately. |
| Wet Substrate Simulation | The composition engine that makes simple items form deep sentences. |
| Combat, Health & Defeat | Deterministic pressure needs readable consequences and no output RNG. |
| Creature AI & Ecology | Makes the deep the third fighter, not just a backdrop. |
| Rival Diver AI & Habits | The solo-complete pressure source and future PvP substitute. |
| Loot, Salvage & Banking | Extraction tension needs something concrete to risk and bank. |
| Feed, Heat, Marks & Public Ledger | The show becomes social memory without creating four separate meta-games. |
| HUD, Onboarding & Relic Readability | Directly addresses the prototype's clarity failure. |
| Dive Feedback, VFX & Audio Cues | Immersion is now a design requirement, but readability remains the gate. |

### Vertical Slice Systems

These turn the dive into a complete repeatable experience around one excellent
wreck without opening the full economy, season, or multiplayer scope.

| System | Why |
|---|---|
| Save/Profile Persistence | Needed once stash, diver identity, Marks, and history survive between dives. |
| Bloodline, Scars & Death Dial | Creates attachment and stakes while keeping ordinary duel losses from ending careers too fast. |
| Barge Hub & Loadout Flow | Gives the player a place to read risk, kit four relics, and requeue cleanly. |
| Dive Board & Match Types | Frames salvage, contested claims, and showdowns without requiring netcode. |
| Showrunner Director & Booking | Turns ledger facts into pressure, callbacks, and authored episode logic. |
| Accessibility, Settings & Input Options | Locks the control/readability baseline before systems get harder to change. |

### Alpha Systems

Alpha systems broaden the loop after the core dive is proven. They are valuable,
but none should block the first complete wreck.

| System | Why |
|---|---|
| Progression & Depth Gates | Adds long-term curiosity and access without PvP power creep. |
| Persistent NPC Rival Bloodlines & Grudges | Makes solo rivals feel like recurring people, not disposable bots. |
| Memorial, Heirloom & Wall | Pays off rare true death after bloodline attachment exists. |
| Contracts & Sponsor Flavor | Lets public Marks create opportunities without a full sponsor sim. |
| Episode Formats & Modifiers | Adds variety after the base dive loop is stable. |
| Alliance, Betrayal & Reputation | Social drama depends on stable Public Ledger and participant rules. |
| Multiplayer Contested Dives & Netcode | The largest technical risk; staged after solo loop proof. |

### Full Vision Systems

These should remain out of near-term planning unless the vertical slice proves
the core loop has legs.

| System | Why |
|---|---|
| Showdown Ladder & Seasons | Gives competitive structure, but only after match types and rivals are stable. |
| Tier 3 LLM Narrative Generation | High-value garnish for rare personal moments; never required in-water. |

---

## Dependency Map

### Foundation Layer

1. **Dive Runtime & Event Log** - owns deterministic state, tick order, and the
   structured facts every later social/narrative system consumes.
2. **Player Controls, Camera & Casting** - defines the embodied interface and
   input contracts for combat, items, AI, HUD, and accessibility.
3. **Save/Profile Persistence** - a vertical-slice foundation for all between-
   dive continuity.

### Core Layer

1. **Wreck Layout, Navigation & Fog** - depends on Dive Runtime; Controls.
2. **Oxygen, Extraction & Greed Loop** - depends on Dive Runtime; Wreck Layout.
3. **Relic Loadouts & Item Verbs** - depends on Dive Runtime; Controls.
4. **Wet Substrate Simulation** - depends on Dive Runtime; Wreck Layout.
5. **Combat, Health & Defeat** - depends on Dive Runtime; Controls; Relics; Wet
   Substrate.

### Feature Layer

1. **Creature AI & Ecology** - depends on Runtime; Wet Substrate; Combat.
2. **Rival Diver AI & Habits** - depends on Runtime; Controls/Casting contract;
   Wreck/Fog; Combat; Wet Substrate.
3. **Loot, Salvage & Banking** - depends on Runtime; Oxygen/Extraction.
4. **Feed, Heat, Marks & Public Ledger** - depends on Event Log; Combat; Loot;
   Extraction.
5. **Bloodline, Scars & Death Dial** - depends on Combat/Defeat; Persistence;
   Public Ledger.
6. **Dive Board & Match Types** - depends on Persistence; Loot; Rival AI; Public
   Ledger.
7. **Showrunner Director & Booking** - depends on Public Ledger; Feed; Dive
   Board; Rival AI; Bloodline.
8. **Progression & Depth Gates** - depends on Loot; Persistence; Dive Board.
9. **Persistent NPC Rival Bloodlines & Grudges** - depends on Rival AI;
   Persistence; Public Ledger; Showrunner.
10. **Contracts & Sponsor Flavor** - depends on Public Ledger; Loot; Bloodline;
    Dive Board.
11. **Episode Formats & Modifiers** - depends on Showrunner; Dive Board; Relics;
    Wet Substrate.
12. **Alliance, Betrayal & Reputation** - depends on Public Ledger; Feed;
    participant rules; Dive Board.
13. **Multiplayer Contested Dives & Netcode** - depends on Runtime; Controls;
    Combat; Event Log.

### Presentation Layer

1. **HUD, Onboarding & Relic Readability** - depends on Controls; Relics; Oxygen;
   Combat; Wreck/Fog; Feed/Ledger.
2. **Dive Feedback, VFX & Audio Cues** - depends on Controls; Relics; Wet
   Substrate; Combat; Creature AI; Rival AI.
3. **Barge Hub & Loadout Flow** - depends on Persistence; Relics; Loot; Bloodline.
4. **Memorial, Heirloom & Wall** - depends on Bloodline; Public Ledger;
   Persistence; Feed.

### Polish Layer

1. **Accessibility, Settings & Input Options** - depends on Controls; HUD;
   Feedback.
2. **Showdown Ladder & Seasons** - depends on Dive Board; Feed; Persistence;
   NPC/Multiplayer showdown resolution.
3. **Tier 3 LLM Narrative Generation** - depends on Public Ledger; Memorial;
   Showrunner; template fallback.

---

## GDD Authoring Constraints

These constraints were added by the full-review backfill on 2026-07-04.

- Every MVP GDD must define its **first testable version**, **solo-dev cut line**,
  **explicitly deferred scope**, and **risk trigger for cutting**.
- Foundation and core GDDs must preserve future netcode compatibility even while
  multiplayer remains deferred: deterministic tick order, command inputs, state
  authority, event emission, replay/debug, and server authority readiness.
- `Dive Runtime & Event Log` must specify three internal contracts: simulation
  authority, event emitter, and append-only event log.
- `Feed, Heat, Marks & Public Ledger` must not own raw events. It derives Heat,
  Marks, recap beats, and public memory from the Event Log.
- Presentation-adjacent GDDs must include a **Visual Readability Contract**:
  silhouette, color semantics, motion/audio backup, and failure-state clarity.
- Prototype code is evidence only. Production architecture should not refactor
  `prototypes/the-drop-embodied-concept/sim.gd` into shipped code.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|---:|---|---|---|---|---|
| 1 | Dive Runtime & Event Log | MVP | Foundation | systems-designer, gameplay-programmer | L |
| 2 | Player Controls, Camera & Casting | MVP | Foundation | game-designer, gameplay-programmer | M |
| 3 | Wreck Layout, Navigation & Fog | MVP | Core | level-designer, systems-designer | M |
| 4 | Oxygen, Extraction & Greed Loop | MVP | Core | game-designer | S |
| 5 | Relic Loadouts & Item Verbs | MVP | Core | systems-designer, game-designer | L |
| 6 | HUD, Onboarding & Relic Readability | MVP | Presentation | ux-designer, game-designer | M |
| 7 | Wet Substrate Simulation | MVP | Core | systems-designer, gameplay-programmer | L |
| 8 | Combat, Health & Defeat | MVP | Core | combat-designer, gameplay-programmer | M |
| 9 | Creature AI & Ecology | MVP | Feature | ai-designer, gameplay-programmer | M |
| 10 | Rival Diver AI & Habits | MVP | Feature | ai-designer, game-designer | L |
| 11 | Loot, Salvage & Banking | MVP | Feature | economy-designer, game-designer | S |
| 12 | Feed, Heat, Marks & Public Ledger | MVP | Feature | narrative-designer, systems-designer | M |
| 13 | Dive Feedback, VFX & Audio Cues | MVP | Presentation | technical-artist, sound-designer | M |
| 14 | Save/Profile Persistence | Vertical Slice | Foundation | technical-designer, gameplay-programmer | M |
| 15 | Bloodline, Scars & Death Dial | Vertical Slice | Feature | game-designer, narrative-designer | M |
| 16 | Barge Hub & Loadout Flow | Vertical Slice | Presentation | ux-designer, game-designer | M |
| 17 | Dive Board & Match Types | Vertical Slice | Feature | systems-designer, producer | M |
| 18 | Showrunner Director & Booking | Vertical Slice | Feature | systems-designer, narrative-designer | L |
| 19 | Accessibility, Settings & Input Options | Vertical Slice | Polish | ux-designer, gameplay-programmer | M |
| 20 | Progression & Depth Gates | Alpha | Feature | progression-designer | M |
| 21 | Persistent NPC Rival Bloodlines & Grudges | Alpha | Feature | ai-designer, narrative-designer | L |
| 22 | Memorial, Heirloom & Wall | Alpha | Presentation | narrative-designer, ux-designer | M |
| 23 | Contracts & Sponsor Flavor | Alpha | Feature | economy-designer, narrative-designer | S |
| 24 | Episode Formats & Modifiers | Alpha | Feature | systems-designer, level-designer | M |
| 25 | Alliance, Betrayal & Reputation | Alpha | Feature | systems-designer, narrative-designer | M |
| 26 | Multiplayer Contested Dives & Netcode | Alpha | Feature | network-programmer, gameplay-programmer | L |
| 27 | Showdown Ladder & Seasons | Full Vision | Polish | systems-designer, backend-designer | M |
| 28 | Tier 3 LLM Narrative Generation | Full Vision | Polish | narrative-designer, tools-programmer | L |

Effort estimates: S = one focused design session, M = two to three sessions,
L = four or more sessions or significant technical/design uncertainty.

---

## Circular Dependencies

- **None found** if the Public Ledger is treated as a fact store, not a manager
  of all social systems.

Potential boundary risks:
- **Showrunner Director <-> Dive Board**: resolve by making the Dive Board own
  available dive contracts and making the Director consume/annotate them.
- **Public Ledger <-> Feed**: resolve by making the ledger record facts and the
  Feed interpret/present those facts.
- **Rival AI <-> Persistent NPC Bloodlines**: resolve by designing stateless
  moment-to-moment Rival AI first, then adding persistent memory as a wrapper.

TD-SYSTEM-BOUNDARY backfilled 2026-07-04: CONCERNS, no blockers. Preserve the
raw event/fact split, keep Showrunner as a consumer/request layer, and define
`Dive Runtime & Event Log` internally as simulation authority, event emitter,
and append-only event log contracts.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|---|---|---|---|
| Player Controls, Camera & Casting | Design | Feel is the core product; small input mistakes can make the game feel flat. | Prototype and tune early; keep v3 sweaty-hands benchmark as test target. |
| Wreck Layout, Navigation & Fog | Design | Rooms can become cramped, empty, or unreadable, repeating v3's weakest points. | First wreck GDD must define room scale, landmarks, reveal edges, and density rules. |
| Relic Loadouts & Item Verbs | Scope / Balance | Four-slot builds can balloon into too many verbs or unclear item sentences. | Start with 8-12 relics, strict noun/verb readability, and no vertical power. |
| Wet Substrate Simulation | Scope / Technical | Too many properties can become invisible complexity. | Treat six properties as a budget, not a checklist; first playable proof should use only 2-3 readable properties. |
| Rival Diver AI & Habits | Design / Technical | Rival must be scary, fair, and personality-driven without cheating. | Build one rival habit deeply before adding more rival personalities. |
| Feed, Heat, Marks & Public Ledger | Scope | Social systems can multiply into sponsors, memorials, factions, and sim logic. | Keep one ledger backbone; first playable proof uses raw event facts, end recap, and 1-2 Marks only. |
| Showrunner Director & Booking | Design / Scope | Could become an overbuilt TV simulator. | Vertical slice should only pace pressure, choose simple bookings, and read ledger callbacks. |
| Multiplayer Contested Dives & Netcode | Technical | Largest solo-dev technical risk. | Defer until solo loop works; preserve authoritative deterministic runtime boundaries now. |
| Tier 3 LLM Narrative Generation | Production / Platform | Ops cost, disclosure, player hostility, quality drift. | Full Vision only; template fallback mandatory; between-dive only. |

---

## Progress Tracker

| Metric | Count |
|---|---:|
| Total systems identified | 28 |
| Design docs started | 1 |
| Design docs reviewed | 1 |
| Design docs approved | 0 |
| MVP systems designed | 0 / 13 |
| Vertical Slice systems designed | 0 / 6 |
| Alpha systems designed | 0 / 7 |
| Full Vision systems designed | 0 / 2 |

---

## Gate Notes

- CD-SYSTEMS backfilled 2026-07-04: APPROVE. MVP system set serves the core fantasy; carry forward wet-substrate scope and readability concerns.
- TD-SYSTEM-BOUNDARY backfilled 2026-07-04: CONCERNS. No restructuring blocker; runtime/event log must avoid god-object ownership by splitting simulation authority, event emitter, and append-only log contracts.
- PR-SCOPE backfilled 2026-07-04: OPTIMISTIC. No blocker; split First Playable Proof from MVP-Complete and add solo-dev cut lines to all MVP GDDs.
- Concept -> Systems phase gate backfilled 2026-07-04: CD READY, TD CONCERNS, PR READY WITH CONCERNS, AD READY. Overall: CONCERNS, no blockers; continue Systems Design.

---

## Next Steps

- [ ] Review and approve this systems enumeration.
- [ ] Design MVP-tier systems first with `/design-system [system-name]`.
- [ ] Start with `Dive Runtime & Event Log`.
- [ ] Run `/design-review` on each completed GDD.
- [ ] Run `/gate-check systems-design` when MVP GDDs are complete.
- [ ] Validate highest-risk systems in the vertical slice before committing to
  Production.
