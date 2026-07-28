# Systems Index: The Last Seal (Voxel)

> **Status**: Draft
> **Created**: 2026-07-09
> **Last Updated**: 2026-07-09
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

The Last Seal is a voxel colony-builder + squad tactics game whose mechanical scope
spans five interlocking areas: a **freeform-but-structured building system** (the
game's stated soul, Pillar 1), a **living settlement simulation** (villager needs,
mood, professions, bonds — Pillar 2), a **resource economy** feeding both, a
**squad-tactics combat layer** (wave defense + seal dungeons — the "stakes" half of
Pillar 3), and a **township progression** meta-layer that gates content and raises
difficulty over time. 32 systems were identified — 5 explicit "Core Mechanics" from
the concept doc, expanded into their necessary supporting systems (data layers,
AI, validation, UI, persistence). Most of that scope is intentionally NOT in the
MVP: the MVP (11 systems) tests only the concept's core hypothesis — that
drawing a room, furnishing it, and watching a villager live there is satisfying —
using the smallest possible slice of Foundation/Core/Feature/Presentation systems.
Everything else (combat, economy, township) is staged into Vertical Slice, Alpha,
and Full Vision per the concept doc's own scope tiers.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Voxel World / Grid Data System | Core | MVP | Approved | design/gdd/voxel-world.md | — |
| 2 | Camera & Input | Core | MVP | Approved | design/gdd/camera-input.md | — |
| 3 | Time & Tick System | Core | MVP | Approved | design/gdd/time-tick-system.md | — |
| 4 | Save/Load & World Persistence | Core | Vertical Slice | Not Started | — | Voxel World, Resource & Item Database, Scene/World Management |
| 5 | Scene/World Management | Core | MVP | Approved (2026-07-10, 5 review rounds — see review log) | design/gdd/scene-world-management.md | — |
| 6 | Building System | Gameplay | MVP | Approved | design/gdd/building-system.md | Voxel World, Camera & Input, Resource & Item Database, Time & Tick System |
| 7 | Build Validation & Navigability | Gameplay | MVP | Approved (2026-07-10 — 2 review rounds + verification pass CLEAN, see review log) | design/gdd/build-validation-navigability.md | Building System, Villager AI & Behavior |
| 8 | Villager AI & Behavior | Gameplay | MVP | Approved | design/gdd/villager-ai-behavior.md | Voxel World, Time & Tick System, Building System |
| 9 | Needs & Mood System | Gameplay | MVP | Approved (2026-07-10 — review + in-session revision + verification pass CLEAN) | design/gdd/needs-mood-system.md | Villager AI & Behavior, Time & Tick System, Build Validation & Navigability |
| 10 | Professions & Ranks | Gameplay | Alpha | Not Started | — | Villager AI & Behavior, Gathering & Production Chains |
| 11 | Relationships & Bonds | Gameplay | Alpha | Not Started | — | Villager AI & Behavior, Needs & Mood System |
| 12 | Gathering & Production Chains | Gameplay | Alpha | Not Started | — | Resource & Item Database, Time & Tick System |
| 13 | Storage & Inventory | Gameplay | Alpha | Not Started | — | Resource & Item Database |
| 14 | Trade System | Gameplay | Alpha | Not Started | — | Storage & Inventory, Gathering & Production Chains |
| 15 | Squad & Combat System | Gameplay | Vertical Slice | Not Started | — | Time & Tick System, Voxel World |
| 16 | Wave Defense | Gameplay | Vertical Slice | Not Started | — | Squad & Combat System, Voxel World, Building System |
| 17 | Dungeon System | Gameplay | Vertical Slice | Not Started | — | Squad & Combat System |
| 18 | Township Progression / Prosperity | Progression | Alpha | Not Started | — | Gathering & Production Chains, Building System, Villager AI & Behavior |
| 19 | Recipe/Blueprint Unlocks | Progression | Alpha | Not Started | — | Township Progression, Gathering & Production Chains |
| 20 | Resource & Item Database | Economy | MVP | Approved (2026-07-10 — review + in-session revision + verification pass CLEAN) | design/gdd/resource-item-database.md | — |
| 21 | Economy Balance (Sinks) | Economy | Alpha | Not Started | — | Gathering & Production Chains, Storage & Inventory, Building System |
| 22 | Building UI | UI | MVP | Approved (2026-07-10 — MAJOR → rebuild → re-review → verification CLEAN, see review log) | design/gdd/building-ui.md | Building System, Build Validation & Navigability, Resource & Item Database, Time & Tick System |
| 23 | Villager Info UI | UI | MVP | Approved (2026-07-11 — review + in-session revision + verification pass CLEAN) | design/gdd/villager-info-ui.md | Villager AI & Behavior, Needs & Mood System |
| 24 | Economy UI | UI | Alpha | Not Started | — | Storage & Inventory, Trade System |
| 25 | Combat/Wave UI | UI | Vertical Slice | Not Started | — | Squad & Combat System, Wave Defense |
| 26 | Township UI | UI | Alpha | Not Started | — | Township Progression |
| 27 | Main Menu & Settings | UI | Alpha | Not Started | — | Time & Tick System, Save/Load & World Persistence |
| 28 | Audio System | Audio | Vertical Slice | Not Started | — | Time & Tick System |
| 29 | Seal Lore & World Narrative | Narrative | Vertical Slice | Not Started | — | Wave Defense, Dungeon System |
| 30 | Villager Diaries / Emergent Stories | Narrative | Full Vision | Not Started | — | Relationships & Bonds |
| 31 | Onboarding / Tutorial | Meta | Vertical Slice | Not Started | — | Building System, Building UI, Villager Info UI |
| 32 | Accessibility | Meta | Full Vision | Not Started | — | All UI systems |

*Systems 10-32 (except where noted) were inferred, not explicitly named as separate
systems in the concept doc — see the design-review session on 2026-07-09 for the
reasoning chain from each of the 5 "Core Mechanics" to its supporting systems.*

---

## Categories

| Category | Description | Systems in this project |
|----------|-------------|--------------------------|
| **Core** | Foundation systems everything depends on | Voxel World, Camera & Input, Time & Tick, Save/Load, Scene/World Management |
| **Gameplay** | The systems that make the game fun | Building, Build Validation, Villager AI, Needs & Mood, Professions, Relationships, Gathering & Production, Storage, Trade, Squad & Combat, Wave Defense, Dungeon |
| **Progression** | How the player/settlement grows over time | Township Progression, Recipe/Blueprint Unlocks |
| **Economy** | Resource creation and consumption | Resource & Item Database, Economy Balance (Sinks) |
| **UI** | Player-facing information displays | Building UI, Villager Info UI, Economy UI, Combat/Wave UI, Township UI, Main Menu & Settings |
| **Audio** | Sound and music systems | Audio System |
| **Narrative** | Story and dialogue delivery | Seal Lore & World Narrative, Villager Diaries |
| **Meta** | Systems outside the core game loop | Onboarding/Tutorial, Accessibility |

*(Persistence is folded into Core — Save/Load & World Persistence — rather than kept
as a separate category, since this project has exactly one persistence-related system.)*

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype (~2-3 wks) | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice / demo (~6-8 wks) | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone (TBD) | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release (TBD) | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Scene/World Management** — loads the valley/settlement scene everything else runs inside
2. **Camera & Input** — orbit camera + mouse-driven placement is the project's stated core interaction
3. **Time & Tick System** — the real-time-with-pause clock that build-over-time, needs decay, and schedules all key off
4. **Voxel World / Grid Data System** — the block data structure the building system is built on
5. **Resource & Item Database** — pure data (material/item definitions); nothing needs to exist before it

### Core Layer (depends on Foundation)

1. **Building System** — depends on: Voxel World, Camera & Input, Resource & Item Database, Time & Tick System
2. **Villager AI & Behavior** — depends on: Voxel World, Time & Tick System
3. **Gathering & Production Chains** — depends on: Resource & Item Database, Time & Tick System
4. **Storage & Inventory** — depends on: Resource & Item Database
5. **Squad & Combat System** — depends on: Time & Tick System, Voxel World
6. **Save/Load & World Persistence** — depends on: Voxel World, Resource & Item Database, Scene/World Management
7. **Audio System** — depends on: Time & Tick System

### Feature Layer (depends on Core)

1. **Build Validation & Navigability** — depends on: Building System, Villager AI & Behavior
2. **Needs & Mood System** — depends on: Villager AI & Behavior, Time & Tick System
3. **Professions & Ranks** — depends on: Villager AI & Behavior, Gathering & Production Chains
4. **Relationships & Bonds** — depends on: Villager AI & Behavior, Needs & Mood System
5. **Trade System** — depends on: Storage & Inventory, Gathering & Production Chains
6. **Economy Balance (Sinks)** — depends on: Gathering & Production Chains, Storage & Inventory, Building System
7. **Wave Defense** — depends on: Squad & Combat System, Voxel World, Building System
8. **Dungeon System** — depends on: Squad & Combat System
9. **Township Progression / Prosperity** — depends on: Gathering & Production Chains, Building System, Villager AI & Behavior
10. **Recipe/Blueprint Unlocks** — depends on: Township Progression, Gathering & Production Chains
11. **Seal Lore & World Narrative** — depends on: Wave Defense, Dungeon System
12. **Villager Diaries / Emergent Stories** — depends on: Relationships & Bonds

### Presentation Layer (depends on Features)

1. **Building UI** — depends on: Building System
2. **Villager Info UI** — depends on: Needs & Mood System (MVP). Professions & Ranks
   is an *optional/deferred* data source added in Alpha — it must NOT be a hard MVP
   dependency (an MVP presentation system cannot hard-depend on an Alpha feature).
3. **Economy UI** — depends on: Storage & Inventory, Trade System
4. **Combat/Wave UI** — depends on: Squad & Combat System, Wave Defense
5. **Township UI** — depends on: Township Progression
6. **Main Menu & Settings** — depends on: Time & Tick System, Save/Load & World Persistence

### Polish Layer (depends on everything)

1. **Onboarding/Tutorial** — depends on: Building System, Building UI, Villager Info UI
2. **Accessibility** — depends on: all UI systems (cross-cutting — should be baked into each UI system's own design, not bolted on here; this entry tracks the dedicated colorblind-mode/remapping/text-scaling pass)

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Scene/World Management | MVP | Foundation | game-designer | S |
| 2 | Voxel World / Grid Data System | MVP | Foundation | systems-designer, godot-specialist | L |
| 3 | Camera & Input | MVP | Foundation | game-designer | S |
| 4 | Time & Tick System | MVP | Foundation | systems-designer | S |
| 5 | Resource & Item Database | MVP | Foundation | economy-designer | S |
| 6 | Building System | MVP | Core | game-designer, systems-designer | L |
| 7 | Villager AI & Behavior | MVP | Core | ai-programmer, game-designer | L |
| 8 | Build Validation & Navigability | MVP | Feature | game-designer, ai-programmer | M |
| 9 | Needs & Mood System | MVP | Feature | systems-designer | M |
| 10 | Building UI | MVP | Presentation | ux-designer | M |
| 11 | Villager Info UI | MVP | Presentation | ux-designer | S |
| 12 | Squad & Combat System | Vertical Slice | Core | game-designer, systems-designer | L |
| 13 | Save/Load & World Persistence | Vertical Slice | Core | systems-designer | M |
| 14 | Audio System | Vertical Slice | Core | audio-director | S |
| 15 | **Wave Defense** ⚠️ | Vertical Slice | Feature | level-designer, game-designer | L — prototype first (see High-Risk) |
| 16 | Dungeon System | Vertical Slice | Feature | level-designer | M |
| 17 | Seal Lore & World Narrative (minimal) | Vertical Slice | Feature | narrative-director | M |
| 18 | Combat/Wave UI | Vertical Slice | Presentation | ux-designer | S |
| 19 | Onboarding/Tutorial (baseline) | Vertical Slice | Polish | ux-designer | M |
| 20 | Gathering & Production Chains | Alpha | Core | economy-designer | M |
| 21 | Storage & Inventory | Alpha | Core | economy-designer | S |
| 22 | Professions & Ranks | Alpha | Feature | economy-designer, game-designer | M |
| 23 | Trade System | Alpha | Feature | economy-designer | M |
| 24 | Economy Balance (Sinks) | Alpha | Feature | economy-designer | M |
| 25 | Township Progression / Prosperity | Alpha | Feature | economy-designer, systems-designer | L |
| 26 | Recipe/Blueprint Unlocks | Alpha | Feature | economy-designer | S |
| 27 | Relationships & Bonds | Alpha | Feature | narrative-director, systems-designer | M |
| 28 | Economy UI | Alpha | Presentation | ux-designer | S |
| 29 | Township UI | Alpha | Presentation | ux-designer | S |
| 30 | Main Menu & Settings | Alpha | Presentation | ux-designer | S |
| 31 | Villager Diaries / Emergent Stories | Full Vision | Feature | writer, narrative-director | M |
| 32 | Accessibility (full pass) | Full Vision | Polish | accessibility-specialist | M |

*(S = 1 session, M = 2-3 sessions, L = 4+ sessions.)*

---

## Circular Dependencies

- **Building System ↔ Township Progression / Prosperity**: Township Progression
  reads Building System's output (built/furnished value feeds prosperity), but
  which materials/furniture are *available* to build is tier-gated by Township
  Progression — a closed loop with no stated bootstrap point (flagged in the
  2026-07-09 concept-doc design review, systems-designer finding).

  **Resolution**: Define an explicit tier-0 "free" material/furniture set in the
  Building System GDD that requires no economy gating, breaking the cycle at the
  bootstrap point. Keep the dependency one-directional: Building System → Township
  Progression (built value flows in), and route new unlocked content through the
  separate **Recipe/Blueprint Unlocks** system (Township Progression → Recipe/
  Blueprint Unlocks → Building System's catalog) rather than Building System
  depending back on Township Progression directly.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-------------------|------------|
| Voxel World / Grid Data System | Technical | RESOLVED 2026-07-11 (ADR-0014: chunked mesher, prototype-validated at 2000x2000x32) — was: GridMap vs. MultiMeshInstance3D vs. chunked/greedy mesher unresolved; the concept prototype validated the interaction (per-block placement/undo) using individual MeshInstance3D nodes, not GridMap's fixed-palette model. Township-scale performance unproven. | Resolve via building ADR at `/create-architecture`; run a dedicated performance spike before Vertical Slice sign-off (draw calls, memory, at full township block-count extrapolation) |
| Build Validation & Navigability | Design + Technical | ~~Walled-off beds~~ **Design half RESOLVED 2026-07-10** (build-validation-navigability.md: room = roofed + floored + walkable opening; sealed-space warnings; 3-tier shelter ladder; never blocks). Technical half still open: NavigationServer3D rebake cost vs. cell-rule analysis at scale | Confirm rebake/throttling (or navmesh-free cell analysis) in the building/AI ADR + pre-VS performance spike |
| Wave Defense | Design | Zero spatial contract between waves and a fully player-authored settlement — no chokepoint concept; a player could trivialize every wave or build an undefendable perimeter | Run a **dedicated wave-defense/freeform-base prototype** (`/prototype wave-defense`) before this GDD is authored — the design review's top recommended next validation priority |
| Villager AI & Behavior | Scope + Technical | ~~No target population ceiling stated~~ **RESOLVED 2026-07-10: 20–30 ceiling** (villager-ai-behavior.md, user decision) — per-agent AI permitted; architecture choice itself still pending at the AI ADR | Ceiling locked; remaining risk moves to the AI ADR (architecture) and the pre-VS performance spike (re-path storms) |
| Township Progression / Prosperity | Design | "Prosperity" — the core progression-gating variable — is not named or proposed as a candidate anywhere | Must be defined as an explicit function of measurable state (population, build value, etc.) in this GDD's Formulas section |
| Save/Load & World Persistence | Technical | RESOLVED 2026-07-11 (ADR-0012: store_var Dictionary, re-measure payload at VS under ADR-0014) — was: serialization approach completely unspecified; naive per-block dumps risk save-time frame hitches at scale | Resolve chunk format, delta-save strategy, and async/threading approach via architecture ADR before Vertical Slice |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 32 |
| Design docs started | 11 |
| Design docs reviewed | 11 |
| Design docs approved | 11 (all MVP — completed 2026-07-11) |
| MVP systems designed | 11/11 |
| Vertical Slice systems designed | 0/8 |

---

## Next Steps

- [x] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`), starting
      with Scene/World Management → Voxel World → Camera & Input (design order above)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Run `/prototype wave-defense` before authoring the Wave Defense GDD (High-Risk)
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
