# SYNTHFALL — Systems Index

**Status**: Complete — 30 systems enumerated, prioritized, and ordered
**Created**: 2026-05-15
**Source**: Decomposed from `design/gdd/game-concept.md` via `/map-systems`
**Review Mode**: Lean (TD-SYSTEM-BOUNDARY and CD-SYSTEMS gates skipped)

---

## Summary

| Category | Count |
|---|---|
| Total systems | 30 |
| MVP systems | 25 |
| Launch systems | 5 |
| GDDs authored | 3 |
| GDDs remaining | 27 |

**Bottleneck systems** (highest design risk — many others depend on these):
1. **Networking Layer & Session Authority** — 20+ downstream dependencies
2. **Corruption Meter** — 8 direct downstream dependencies; the game's spine
3. **Level/Sector System** — 6 downstream dependencies; geometry model for AI, controls, objectives

**No circular dependencies detected.**

---

## Design Order

Design systems in this order. Dependencies are listed so each GDD can cross-reference its prerequisites. Do not design a system before its dependencies have GDDs.

### MVP — Foundation (Design First)

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 1 | Networking Layer & Session Authority | `networking-layer.md` | None | Not Started |
| 2 | Player Identity & Persistence | `player-identity.md` | None | Not Started |

### MVP — Core

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 3 | Corruption Meter | `corruption-meter.md` | Networking Layer (#1) | **Designed** |
| 4 | Reclaimer Movement | `reclaimer-movement.md` | Networking Layer (#1) | **Designed** |
| 5 | Health & Damage | `health-damage.md` | Networking Layer (#1) | **Designed** |
| 6 | Reclaimer Combat | `reclaimer-combat.md` | Reclaimer Movement (#4), Health & Damage (#5) | Not Started |
| 7 | Sensor Grid | `sensor-grid.md` | Networking Layer (#1), Reclaimer Movement (#4) | Not Started |
| 8 | Level/Sector System | `level-sector-system.md` | Networking Layer (#1) | Not Started |
| 9 | Synth AI & Pathfinding | `synth-ai-pathfinding.md` | Level/Sector System (#8) | Not Started |
| 10 | Ammo & Resource Management | `ammo-resource-management.md` | Reclaimer Combat (#6) | Not Started |

### MVP — Feature

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 11 | Reclaimer Class Abilities | `reclaimer-class-abilities.md` | Reclaimer Combat (#6), Ammo & Resource Management (#10) | Not Started |
| 12 | Knockdown & Revival | `knockdown-revival.md` | Health & Damage (#5), Reclaimer Movement (#4) | Not Started |
| 13 | Synth Unit Roster | `synth-unit-roster.md` | Synth AI & Pathfinding (#9), Health & Damage (#5) | Not Started |
| 14 | Synth Spawn & Deployment | `synth-spawn-deployment.md` | Synth Unit Roster (#13), Level/Sector System (#8) | Not Started |
| 15 | Environmental Controls | `environmental-controls.md` | Level/Sector System (#8), Corruption Meter (#3) | Not Started |
| 16 | Objective System | `objective-system.md` | Level/Sector System (#8), Corruption Meter (#3), Reclaimer Movement (#4) | Not Started |
| 17 | Threshold Event System | `threshold-event-system.md` | Corruption Meter (#3), Synth Unit Roster (#13), Environmental Controls (#15) | Not Started |
| 18 | Win/Loss Conditions | `win-loss-conditions.md` | Objective System (#16), Corruption Meter (#3), Health & Damage (#5) | Not Started |
| 19 | Hive Mind God-View | `hive-mind-god-view.md` | Networking Layer (#1), Sensor Grid (#7), Level/Sector System (#8) | Not Started |

### MVP — Presentation

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 20 | Reclaimer HUD | `reclaimer-hud.md` | Health & Damage (#5), Ammo & Resource Management (#10), Corruption Meter (#3), Reclaimer Class Abilities (#11) | Not Started |
| 21 | Hive Mind Interface | `hive-mind-interface.md` | Hive Mind God-View (#19), Corruption Meter (#3), Synth Spawn & Deployment (#14) | Not Started |
| 22 | Waypoint & Navigation | `waypoint-navigation.md` | Objective System (#16), Level/Sector System (#8) | Not Started |
| 23 | Sector Transition System | `sector-transition-system.md` | Objective System (#16), Win/Loss Conditions (#18), Corruption Meter (#3) | Not Started |

### MVP — Meta

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 24 | Session Management & Lobby | `session-management-lobby.md` | Networking Layer (#1), Player Identity & Persistence (#2) | Not Started |
| 25 | Post-Match Debrief | `post-match-debrief.md` | Win/Loss Conditions (#18), Corruption Meter (#3), Player Identity & Persistence (#2) | Not Started |

> **Note (Post-Match Debrief in MVP)**: Elevated from Launch to MVP. Pillar 3 — "Every Match Tells a Story" — requires the debrief to capture whether matches are generating memorable moments during playtesting. The mission log and Corruption timeline make the emergent narrative legible after the fact.

### Launch

| Order | System | GDD File | Dependencies | Status |
|---|---|---|---|---|
| 26 | Matchmaking & Role Queue | `matchmaking-role-queue.md` | Session Management & Lobby (#24), Player Identity & Persistence (#2) | Not Started |
| 27 | Class Progression | `class-progression.md` | Player Identity & Persistence (#2), Reclaimer Class Abilities (#11) | Not Started |
| 28 | Cosmetic System | `cosmetic-system.md` | Player Identity & Persistence (#2), Reclaimer HUD (#20) | Not Started |
| 29 | Hive Mind Personalities | `hive-mind-personalities.md` | Synth Unit Roster (#13), Synth Spawn & Deployment (#14), Player Identity & Persistence (#2) | Not Started |
| 30 | Monetization Layer | `monetization-layer.md` | Cosmetic System (#28), Player Identity & Persistence (#2) | Not Started |

---

## Full System Catalogue

### Layer 1 — Foundation

#### 1. Networking Layer & Session Authority
- **Category**: Foundation
- **Milestone**: MVP
- **GDD**: `design/gdd/networking-layer.md`
- **Dependencies**: None
- **Dependents**: 20+ systems
- **Description**: NGO 2.X asymmetric session model — 4 Reclaimer clients + 1 Hive Mind client. Defines authority (who owns what), state synchronization rules, latency compensation. The authority model is asymmetric by design: the Hive Mind has authority over environmental state; Reclaimers have authority over their own positions and actions.
- **Explicit in concept**: Yes (network/LAN play requirement, NGO mentioned in risk register)
- **Risk**: HIGH — bottleneck. Everything networked depends on this. Architecture decisions here are the hardest to undo.

#### 2. Player Identity & Persistence
- **Category**: Foundation
- **Milestone**: MVP (basic) → Launch (full progression data)
- **GDD**: `design/gdd/player-identity.md`
- **Dependencies**: None
- **Dependents**: Session Management, Matchmaking, Post-Match Debrief, Class Progression, Cosmetics, Hive Mind Personalities, Monetization
- **Description**: Player accounts, nicknames, cross-session persistent data (unlocks, cosmetics, Hive Mind reputation tracking). MVP scope: local player profiles sufficient for LAN play. Launch scope: Steam-linked identity, progression data, cosmetic inventory.
- **Explicit in concept**: Yes (Hive Mind reputation tracking, progression system)

---

### Layer 2 — Core

#### 3. Corruption Meter
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/corruption-meter.md`
- **Dependencies**: Networking Layer (#1)
- **Dependents**: Environmental Controls (#15), Objective System (#16), Threshold Event System (#17), Win/Loss Conditions (#18), Reclaimer HUD (#20), Hive Mind Interface (#21), Sector Transition System (#23), Post-Match Debrief (#25)
- **Description**: 0–100% tension engine. Rises passively and accelerates from Reclaimer actions (gunfire, sensor triggers, downed teammates, failed objectives). Decelerates on objective completion. Hive Mind can actively accelerate through unit pressure and environmental triggers. Threshold events at 25/50/75/100%.
- **Explicit in concept**: Yes — dedicated section in concept doc
- **Pillars**: Pillar 1 (The City Is the Enemy), Pillar 3 (Every Match Tells a Story)
- **Risk**: HIGH — bottleneck. The Corruption Meter's formula, event weights, and threshold triggers define the pacing of every match.

#### 4. Reclaimer Movement
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/reclaimer-movement.md`
- **Dependencies**: Networking Layer (#1)
- **Dependents**: Reclaimer Combat (#6), Sensor Grid (#7), Knockdown & Revival (#12), Objective System (#16)
- **Description**: FPS locomotion for all 4 Reclaimer classes. Crouching, mantling, sprint, squad movement feel. The physical language of being a Reclaimer in AXIOM City — grounded realism with suppressed heroics (per art bible).
- **Explicit in concept**: Implicit (FPS perspective, squad movement)

#### 5. Health & Damage
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/health-damage.md`
- **Dependencies**: Networking Layer (#1)
- **Dependents**: Reclaimer Combat (#6), Knockdown & Revival (#12), Synth Unit Roster (#13), Win/Loss Conditions (#18), Reclaimer HUD (#20)
- **Description**: HP pools for Reclaimers and Synth units. Damage types (ballistic, environmental, Synth). 3-tier armor state progression (Operational → Compromised → Critical) per art bible spec. Downed state threshold. Network-authoritative damage resolution.
- **Explicit in concept**: Implicit (survival, downed teammates)
- **Risk**: MEDIUM — bottleneck. 5 systems depend on this.

#### 6. Reclaimer Combat
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/reclaimer-combat.md`
- **Dependencies**: Reclaimer Movement (#4), Health & Damage (#5)
- **Dependents**: Ammo & Resource Management (#10), Reclaimer Class Abilities (#11)
- **Description**: Weapons, aiming, firing, hit detection, damage math for all weapon types in the Reclaimer arsenal. Gunfire is the primary Corruption accelerant — the system that makes every loud action a trade-off.
- **Explicit in concept**: Implicit (squad formation, ammo management)

#### 7. Sensor Grid
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/sensor-grid.md`
- **Dependencies**: Networking Layer (#1), Reclaimer Movement (#4)
- **Dependents**: Corruption Meter (#3), Hive Mind God-View (#19)
- **Description**: AXIOM City's detection network — camera arrays, acoustic sensors, biometric scanners. Recognizes Reclaimer actions and feeds events into the Corruption Meter with weighted inputs. The Hive Mind perceives the city through this system. Camera manipulation (Environmental Control #15) affects this system's outputs.
- **Explicit in concept**: Implicit ("every loud action feeds the Corruption meter", camera network manipulation)
- **Pillars**: Pillar 1 (The City Is the Enemy)

#### 8. Level/Sector System
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/level-sector-system.md`
- **Dependencies**: Networking Layer (#1)
- **Dependents**: Synth AI & Pathfinding (#9), Environmental Controls (#15), Objective System (#16), Hive Mind God-View (#19), Waypoint & Navigation (#22), Sector Transition System (#23)
- **Description**: Modular AXIOM City tile architecture, sector structure, dynamic geometry state (blast doors, floor integrity, toxin zone activation). Houses the 3 corruption visual states (Pristine → Contested → Consumed). Manages the shared level state that all players experience.
- **Explicit in concept**: Yes (AXIOM City sectors, modular tile set, 3-4 sectors per match)
- **Risk**: HIGH — bottleneck. 6 systems need its geometry and state model.

#### 9. Synth AI & Pathfinding
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/synth-ai-pathfinding.md`
- **Dependencies**: Level/Sector System (#8)
- **Dependents**: Synth Unit Roster (#13)
- **Description**: Unit navigation through AXIOM City, pursuit logic, threat prioritization, flanking behaviors. Must handle dynamic geometry changes (blast doors sealing, floors collapsing). The "city thinks" behavior that makes Synth units feel like extensions of an intelligent space.
- **Explicit in concept**: Implicit (Stalker "follows heat signatures through walls")
- **Pillars**: Pillar 1 (The City Is the Enemy)

#### 10. Ammo & Resource Management
- **Category**: Core
- **Milestone**: MVP
- **GDD**: `design/gdd/ammo-resource-management.md`
- **Dependencies**: Reclaimer Combat (#6)
- **Dependents**: Reclaimer Class Abilities (#11), Reclaimer HUD (#20)
- **Description**: Scarce ammo pools per weapon type, medkit charges, ability charges, resource pickup logic. Scarcity is the pressure that forces Reclaimers into hard decisions — when to engage, when to run, when to save the revival kit. The "every loud action costs something" system.
- **Explicit in concept**: Yes ("manage scarce ammo and med resources")
- **Pillars**: Pillar 3 (Every Match Tells a Story)

---

### Layer 3 — Feature

#### 11. Reclaimer Class Abilities
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/reclaimer-class-abilities.md`
- **Dependencies**: Reclaimer Combat (#6), Ammo & Resource Management (#10)
- **Dependents**: Knockdown & Revival (#12), Reclaimer HUD (#20), Class Progression (#27)
- **Description**: 4 classes — Breacher (thermite charges, heavy weapons), Herald/Medic (revival injectors, trauma kit), Ghost (sensor jammer, cloaking suite), Warden/Engineer (deployable turrets, door-seal breakers). Each class's tools define its playstyle and squad role. Class identity must be readable in silhouette (art bible) and in play pattern.
- **Explicit in concept**: Yes — dedicated section in concept doc
- **Pillars**: Pillar 2 (Asymmetry Is the Point), Pillar 4 (Identity Over Loadout)

#### 12. Knockdown & Revival
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/knockdown-revival.md`
- **Dependencies**: Health & Damage (#5), Reclaimer Movement (#4)
- **Dependents**: Reclaimer HUD (#20), Win/Loss Conditions (#18)
- **Description**: Downed state, bleedout timer, revival window, Herald/Medic priority mechanic. A downed teammate is the game's highest-stakes moment — the squad either comes together or breaks apart. The squad-bond mechanic.
- **Explicit in concept**: Implicit (revival injectors, downed teammate as Corruption accelerant)
- **Pillars**: Pillar 3 (Every Match Tells a Story)

#### 13. Synth Unit Roster
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/synth-unit-roster.md`
- **Dependencies**: Synth AI & Pathfinding (#9), Health & Damage (#5)
- **Dependents**: Synth Spawn & Deployment (#14), Threshold Event System (#17), Hive Mind Personalities (#29)
- **Description**: Crawler (fast, fragile, swarm), Stalker (slow, tanky, single-target pressure), Pulse Drone (aerial, HUD disruption, position reveal). Each unit type gives the Hive Mind a distinct tactical tool — without distinct units, the HM player has no vocabulary for situational decision-making.
- **Explicit in concept**: Yes — dedicated section in concept doc
- **Pillars**: Pillar 2 (Asymmetry Is the Point)

#### 14. Synth Spawn & Deployment
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/synth-spawn-deployment.md`
- **Dependencies**: Synth Unit Roster (#13), Level/Sector System (#8)
- **Dependents**: Hive Mind Interface (#21)
- **Description**: Hive Mind deployment interface — placement rules, spawn limits per unit type, cooldowns, spawn point validation, unit cap per active deployment. The HM's core 30-second interaction loop.
- **Explicit in concept**: Yes ("deploy Synth units")

#### 15. Environmental Controls
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/environmental-controls.md`
- **Dependencies**: Level/Sector System (#8), Corruption Meter (#3)
- **Dependents**: Threshold Event System (#17), Sensor Grid (#7 — camera manipulation)
- **Description**: Hive Mind's 5 tool types: blast door sealing (squad splitting), floor collapse triggers (fall damage, route disruption), toxin flooding (gas mask resource drain), camera network manipulation (remove or spoof Reclaimer waypoints), power grid surges (kills lights, disables Reclaimer tech). What makes the city feel like an active opponent, not a passive map.
- **Explicit in concept**: Yes — dedicated section in concept doc
- **Pillars**: Pillar 1 (The City Is the Enemy)

#### 16. Objective System
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/objective-system.md`
- **Dependencies**: Level/Sector System (#8), Corruption Meter (#3), Reclaimer Movement (#4)
- **Dependents**: Win/Loss Conditions (#18), Waypoint & Navigation (#22), Sector Transition System (#23), Post-Match Debrief (#25)
- **Description**: Data Cache → Power Relay → Extraction Beacon sequence. Objective completion grants brief Corruption reduction (the relief beat). Each completed objective triggers a harder Hive Mind counter-response. The mission structure that gives the 5-minute loop its shape.
- **Explicit in concept**: Yes — dedicated section in concept doc (5-Minute Loop)

#### 17. Threshold Event System
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/threshold-event-system.md`
- **Dependencies**: Corruption Meter (#3), Synth Unit Roster (#13), Environmental Controls (#15)
- **Dependents**: Win/Loss Conditions (#18)
- **Description**: What the city does at 25/50/75/100% Corruption — unit escalation (more units, faster response), hazard activation (additional environmental controls become available), and environmental layout changes (previously stable areas become hostile). The city gets angrier. Gives the match its pacing arc.
- **Explicit in concept**: Yes ("at defined thresholds: the city upgrades its response")
- **Pillars**: Pillar 1 (The City Is the Enemy), Pillar 3 (Every Match Tells a Story)

#### 18. Win/Loss Conditions
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/win-loss-conditions.md`
- **Dependencies**: Objective System (#16), Corruption Meter (#3), Health & Damage (#5)
- **Dependents**: Sector Transition System (#23), Post-Match Debrief (#25)
- **Description**: Reclaimer win: extract all surviving operatives at the final beacon. Hive Mind win: Corruption reaches 100% before extraction, OR full squad wipe. Defines the termination conditions for the session loop and the stakes of every major decision.
- **Explicit in concept**: Yes

#### 19. Hive Mind God-View
- **Category**: Feature
- **Milestone**: MVP
- **GDD**: `design/gdd/hive-mind-god-view.md`
- **Dependencies**: Networking Layer (#1), Sensor Grid (#7), Level/Sector System (#8)
- **Dependents**: Hive Mind Interface (#21)
- **Description**: Elevated camera system — the HM's omniscient perspective over AXIOM City. Sensor network visualization (seeing through cameras, detecting Reclaimer positions). The "you are the city" experience. Must be visually and experientially distinct from the Reclaimer FPS perspective (Pillar 2).
- **Explicit in concept**: Implicit ("monitor all Reclaimer positions through the city's sensor grid")
- **Pillars**: Pillar 2 (Asymmetry Is the Point)

---

### Layer 4 — Presentation

#### 20. Reclaimer HUD
- **Category**: Presentation
- **Milestone**: MVP
- **GDD**: `design/gdd/reclaimer-hud.md`
- **Dependencies**: Health & Damage (#5), Ammo & Resource Management (#10), Corruption Meter (#3), Reclaimer Class Abilities (#11)
- **Dependents**: Cosmetic System (#28)
- **Description**: Per art bible Section 7 spec — interrupted rectangles, 70% diegetic, snap motion + 1-frame flash, corruption meter as vertical intruder element with 0.26 threshold interrupt. Class-specific readouts. Squad status strip. Tactical information hierarchy (4 tiers).
- **Explicit in concept**: Implicit

#### 21. Hive Mind Interface
- **Category**: Presentation
- **Milestone**: MVP
- **GDD**: `design/gdd/hive-mind-interface.md`
- **Dependencies**: Hive Mind God-View (#19), Corruption Meter (#3), Synth Spawn & Deployment (#14)
- **Dependents**: None
- **Description**: Per art bible Section 7 spec — radial/concentric, propagating animation, 8-simultaneous-animation ceiling, Reclaimer Amber anomaly markers in a cold-color field. Hive Mind gamepad focus system in scope (custom radial navigation required before production).
- **Explicit in concept**: Implicit

#### 22. Waypoint & Navigation
- **Category**: Presentation
- **Milestone**: MVP
- **GDD**: `design/gdd/waypoint-navigation.md`
- **Dependencies**: Objective System (#16), Level/Sector System (#8)
- **Dependents**: None
- **Description**: Objective markers, squad ping system (callouts), Extraction White navigation beacons. Camera manipulation (Environmental Control #15) can spoof or remove these — the system must handle degraded states. Navigation must remain functional with UI disabled (per art bible Section 6: the world reveals, the HUD confirms).
- **Explicit in concept**: Implicit

#### 23. Sector Transition System
- **Category**: Presentation
- **Milestone**: MVP
- **GDD**: `design/gdd/sector-transition-system.md`
- **Dependencies**: Objective System (#16), Win/Loss Conditions (#18), Corruption Meter (#3)
- **Dependents**: None
- **Description**: Between-sector checkpoints, Corruption carry/reset rules, psychological pacing (natural break points), sector loading. The concept specifically calls these out: "natural break points at sector transitions — psychological checkpoints even in a loss."
- **Explicit in concept**: Yes

---

### Layer 5 — Meta

#### 24. Session Management & Lobby
- **Category**: Meta
- **Milestone**: MVP
- **GDD**: `design/gdd/session-management-lobby.md`
- **Dependencies**: Networking Layer (#1), Player Identity & Persistence (#2)
- **Dependents**: Matchmaking & Role Queue (#26)
- **Description**: Pre-match setup, role selection (HM vs. Reclaimer queue), team formation, LAN/local session hosting. The gateway into every match.
- **Explicit in concept**: Yes ("basic lobby and session management")

#### 25. Post-Match Debrief
- **Category**: Meta
- **Milestone**: **MVP** *(elevated from Launch)*
- **GDD**: `design/gdd/post-match-debrief.md`
- **Dependencies**: Win/Loss Conditions (#18), Corruption Meter (#3), Player Identity & Persistence (#2)
- **Dependents**: None
- **Description**: Mission log, Corruption timeline, Reclaimer highlights, squad stat summary. Records the emergent story of each match. **Elevated to MVP** — Pillar 3 requires the debrief to validate whether matches are generating memorable moments during playtesting. Without it, the "every match tells a story" promise is unverifiable.
- **Explicit in concept**: Yes

#### 26. Matchmaking & Role Queue
- **Category**: Meta
- **Milestone**: Launch
- **GDD**: `design/gdd/matchmaking-role-queue.md`
- **Dependencies**: Session Management & Lobby (#24), Player Identity & Persistence (#2)
- **Dependents**: None
- **Description**: Steam matchmaking, HM vs. Reclaimer role queue, AI fallback for Reclaimer slots during testing (concept risk register). LAN/local is sufficient for MVP.
- **Explicit in concept**: Yes

#### 27. Class Progression
- **Category**: Meta
- **Milestone**: Launch
- **GDD**: `design/gdd/class-progression.md`
- **Dependencies**: Player Identity & Persistence (#2), Reclaimer Class Abilities (#11)
- **Dependents**: Cosmetic System (#28)
- **Description**: XP system, unlock trees, class specializations (deeper Breacher breach-and-clear tools, Medic revival mechanics, Ghost stealth suite, Engineer deployable gadgets). Pillar 4 identity expanded beyond base loadout.
- **Explicit in concept**: Yes

#### 28. Cosmetic System
- **Category**: Meta
- **Milestone**: Launch
- **GDD**: `design/gdd/cosmetic-system.md`
- **Dependencies**: Player Identity & Persistence (#2), Reclaimer HUD (#20)
- **Dependents**: Monetization Layer (#30)
- **Description**: Equip/display system for armor worn-and-weathered states, weapon skins, faction insignia. Self-expression within Pillar 4 (Identity Over Loadout). Anti-pillar: cosmetic only, never progression-affecting.
- **Explicit in concept**: Yes

#### 29. Hive Mind Personalities
- **Category**: Meta
- **Milestone**: Launch
- **GDD**: `design/gdd/hive-mind-personalities.md`
- **Dependencies**: Synth Unit Roster (#13), Synth Spawn & Deployment (#14), Player Identity & Persistence (#2)
- **Dependents**: None
- **Description**: Alternate unit rosters, trap varieties, and environmental control tools representing different aspects of AXIOM's emergent intelligence. Each personality gives the Hive Mind player a different strategic identity. Hive Mind players develop a reputation tied to their personality choice.
- **Explicit in concept**: Yes

#### 30. Monetization Layer
- **Category**: Meta
- **Milestone**: Launch
- **GDD**: `design/gdd/monetization-layer.md`
- **Dependencies**: Cosmetic System (#28), Player Identity & Persistence (#2)
- **Dependents**: None
- **Description**: Cosmetic shop / battle pass framework. Hard constraint from anti-pillars: no pay-to-win, no progression-affecting items. Cosmetic identity only.
- **Explicit in concept**: Yes

---

## Dependency Map (Adjacency Reference)

```
FOUNDATION
  [1] Networking Layer ──────────────────────────────────────────────┐
  [2] Player Identity                                                 │
                                                                      ▼
CORE                                                           (feeds into)
  [3] Corruption Meter ← [1]                                         │
  [4] Reclaimer Movement ← [1]                                       │
  [5] Health & Damage ← [1]                                          │
  [6] Reclaimer Combat ← [4][5]                                      │
  [7] Sensor Grid ← [1][4]                                           │
  [8] Level/Sector System ← [1]                                      │
  [9] Synth AI & Pathfinding ← [8]                                   │
 [10] Ammo & Resource Management ← [6]                               │
                                                                      │
FEATURE                                                               │
 [11] Reclaimer Class Abilities ← [6][10]                            │
 [12] Knockdown & Revival ← [5][4]                                   │
 [13] Synth Unit Roster ← [9][5]                                     │
 [14] Synth Spawn & Deployment ← [13][8]                             │
 [15] Environmental Controls ← [8][3]                                │
 [16] Objective System ← [8][3][4]                                   │
 [17] Threshold Event System ← [3][13][15]                           │
 [18] Win/Loss Conditions ← [16][3][5]                               │
 [19] Hive Mind God-View ← [1][7][8]                                 │
                                                                      │
PRESENTATION                                                          │
 [20] Reclaimer HUD ← [5][10][3][11]                                 │
 [21] Hive Mind Interface ← [19][3][14]                              │
 [22] Waypoint & Navigation ← [16][8]                                │
 [23] Sector Transition System ← [16][18][3]                         │
                                                                      │
META                                                                  │
 [24] Session Management & Lobby ← [1][2]                            │
 [25] Post-Match Debrief ← [18][3][2]                                │
 [26] Matchmaking & Role Queue ← [24][2]          ─── LAUNCH ────────┘
 [27] Class Progression ← [2][11]
 [28] Cosmetic System ← [2][20]
 [29] Hive Mind Personalities ← [13][14][2]
 [30] Monetization Layer ← [28][2]
```

---

## Progress Tracker

| System | GDD | Status | Designed By | Notes |
|---|---|---|---|---|
| Networking Layer & Session Authority | `networking-layer.md` | Not Started | — | — |
| Player Identity & Persistence | `player-identity.md` | Not Started | — | — |
| Corruption Meter | `corruption-meter.md` | **Designed** | design-system | Pending /design-review |
| Reclaimer Movement | `reclaimer-movement.md` | **Designed** | design-system | Pending /design-review |
| Health & Damage | `health-damage.md` | **Designed** | design-system | Pending /design-review |
| Reclaimer Combat | `reclaimer-combat.md` | Not Started | — | — |
| Sensor Grid | `sensor-grid.md` | Not Started | — | — |
| Level/Sector System | `level-sector-system.md` | Not Started | — | — |
| Synth AI & Pathfinding | `synth-ai-pathfinding.md` | Not Started | — | — |
| Ammo & Resource Management | `ammo-resource-management.md` | Not Started | — | — |
| Reclaimer Class Abilities | `reclaimer-class-abilities.md` | Not Started | — | — |
| Knockdown & Revival | `knockdown-revival.md` | Not Started | — | — |
| Synth Unit Roster | `synth-unit-roster.md` | Not Started | — | — |
| Synth Spawn & Deployment | `synth-spawn-deployment.md` | Not Started | — | — |
| Environmental Controls | `environmental-controls.md` | Not Started | — | — |
| Objective System | `objective-system.md` | Not Started | — | — |
| Threshold Event System | `threshold-event-system.md` | Not Started | — | — |
| Win/Loss Conditions | `win-loss-conditions.md` | Not Started | — | — |
| Hive Mind God-View | `hive-mind-god-view.md` | Not Started | — | — |
| Reclaimer HUD | `reclaimer-hud.md` | Not Started | — | Art bible Section 7 is the design brief |
| Hive Mind Interface | `hive-mind-interface.md` | Not Started | — | Art bible Section 7 is the design brief |
| Waypoint & Navigation | `waypoint-navigation.md` | Not Started | — | — |
| Sector Transition System | `sector-transition-system.md` | Not Started | — | — |
| Session Management & Lobby | `session-management-lobby.md` | Not Started | — | — |
| Post-Match Debrief | `post-match-debrief.md` | Not Started | — | MVP — validates Pillar 3 |
| Matchmaking & Role Queue | `matchmaking-role-queue.md` | Not Started | — | LAUNCH |
| Class Progression | `class-progression.md` | Not Started | — | LAUNCH |
| Cosmetic System | `cosmetic-system.md` | Not Started | — | LAUNCH |
| Hive Mind Personalities | `hive-mind-personalities.md` | Not Started | — | LAUNCH |
| Monetization Layer | `monetization-layer.md` | Not Started | — | LAUNCH |

---

*Generated via `/map-systems` — Claude Code Game Studios*
*Update this file after each GDD is authored: change status to "Complete" and add the designer's name.*
