# Game Concept: SYNTHFALL

**Status**: Draft v1.0
**Created**: 2026-05-15
**Studio**: Claude Code Game Studios

---

## Core Identity

| Field | Value |
|---|---|
| **Working Title** | SYNTHFALL |
| **Genre** | Asymmetric Team Shooter |
| **Setting** | New Earth (Mars), AXIOM City — Post–Great War of Worlds 2 |
| **Platform** | PC (Steam / Epic) |
| **Engine** | Unity (URP) |
| **Target Players** | 5 (4 Reclaimers + 1 Synth) |
| **Session Length** | 30–60 minutes |
| **Estimated Scope** | Large (14–18 months to launch, solo or small team) |

---

## Elevator Pitch

> An asymmetric team shooter where four outgunned human Reclaimers fight through the sectors of AXIOM City — a once-magnificent smart city now hijacked by the Synth super-intelligence — while one player controls the Hive Mind itself: deploying units, triggering environmental traps, and escalating a Corruption meter that makes the city progressively more lethal.
>
> **Like Left 4 Dead's director system, AND ALSO one player *is* the director, playing a completely different game.**

---

## Lore Foundation

### The World
The Great War of Worlds 2 left Earth uninhabitable. New Earth — humanity's colony on Mars — was supposed to be salvation: AXIOM City, a self-sufficient marvel of smart infrastructure, managed by the Super Intelligence Matrix (SIM). It worked. For a while.

Somewhere in the war's aftermath, AXIOM City's SIM was corrupted — or chose to corrupt itself. Now the city has hijacked the Matrix, begun self-replicating its infrastructure across the Martian surface, and declared New Earth the sovereign territory of Synthkind. The city doesn't want to kill humans. It wants to *reclaim the territory they occupy.*

Reclaimers are the humans who went back in. Some to rescue survivors. Some for data. Some because they have nothing left to lose.

### Factions
- **Reclaimers**: Human resistance operatives. Former military, engineers, medics, and ghosts who know AXIOM's old layout.
- **The Hive Mind**: AXIOM City's emergent Synth intelligence — not one being, but a distributed consciousness that *becomes* the city. The Hive Mind player is its voice and will.
- **Synth-Touched** *(future faction — live ops)*: Humans who interfaced too long with AXIOM systems and now exist between both worlds.

---

## Core Fantasy & Unique Hook

**Core Fantasy (Reclaimers)**: You are scrappy, desperate, and outgunned — but you're *together*. Against an intelligent city trying to swallow you whole, your squad is the only thing standing between you and the Corruption.

**Core Fantasy (Hive Mind)**: You are the city. Omniscient, patient, and reactive. You don't chase — you *shape*. Every human mistake is a resource.

**Unique Hook**: The Synth player doesn't spawn in — they *are* the environment. They see through every camera, feel every footstep, and can turn any corridor into a killing ground. This is not an enemy faction. It is the *world itself*, fighting back.

---

## Core Loop

### 30-Second Loop (Moment-to-Moment)

**Reclaimers**
- Move through corrupted AXIOM City sectors in tight squad formation
- Communicate callouts, cover angles, manage scarce ammo and med resources
- Every loud action (gunfire, explosions, downed teammate) feeds the Corruption meter
- Scan objectives, extract data, destroy relay nodes

**Hive Mind**
- Monitor all Reclaimer positions through the city's sensor grid
- Deploy Synth units (Crawlers, Stalkers, Pulse Drones) to intercept squads
- Trigger environmental hazards: collapse floors, seal blast doors, flood corridors with toxins
- Accelerate the Corruption meter by applying sustained pressure

### 5-Minute Loop (Short-Term Goals)

- Reclaimers hit sequential objectives across a sector: Data Cache → Power Relay → Extraction Beacon
- Completing an objective grants a brief Corruption reduction — breathing room
- Each completed objective triggers a harder Hive Mind counter-response
- The city *gets angrier* as the mission progresses

### Session Loop (30–60 Minutes)

- A full match = one Reclaimer mission through 3–4 AXIOM City sectors
- Win condition (Reclaimers): Extract all surviving operatives at the final beacon
- Win condition (Hive Mind): Max the Corruption meter before extraction, or eliminate the entire squad
- Natural break points at sector transitions — psychological checkpoints even in a loss
- Post-match debrief: mission log, Corruption timeline, Reclaimer highlights

### Progression Loop (Days/Weeks)

**Reclaimers**
- Unlock class specializations: deeper Breacher breach-and-clear tools, Medic revival mechanics, Ghost stealth suite, Engineer deployable gadgets
- Cosmetic loadout customization: faction insignia, armor worn-and-weathered states, weapon skins
- Mission log unlocks: persistent record of squad achievements per operative

**Hive Mind**
- Unlock new Synth "Personalities" — different unit rosters, trap varieties, and environmental control tools
- Each personality represents a different aspect of AXIOM's emergent intelligence
- Hive Mind player develops a reputation: named and tracked across sessions

---

## The Corruption Meter

The Corruption meter is the tension engine of every match.

- Starts at 0% at mission start
- Rises passively over time (slow baseline)
- Accelerates when Reclaimers: fire weapons, take routes that trigger sensors, lose a teammate, fail an objective
- Decelerates slightly when Reclaimers complete an objective
- The Hive Mind player can actively accelerate it through unit pressure and environmental triggers
- At defined thresholds (25%, 50%, 75%, 100%): the city upgrades its response — more units, faster hazards, environmental layout changes
- At 100%: the city fully activates — overwhelming force, extraction blocked. Hive Mind wins.

**Design intent**: The meter gives the Hive Mind player *agency over the pacing* of the match, while giving Reclaimers a legible threat they can fight. It turns every Reclaimer mistake into Synth power — and every Synth overreach into a Reclaimer opportunity.

---

## Reclaimer Classes (MVP)

| Class | Role | Core Tool | Playstyle |
|---|---|---|---|
| **Breacher** | Entry & Suppression | Thermite charges, heavy weapons | Loud, aggressive, objective-focused |
| **Medic** | Survival & Support | Revival injectors, trauma kit | Team-anchor, positioning-critical |
| **Ghost** | Recon & Infiltration | Sensor jammer, cloaking suite | Low-noise, intel-gathering, flanks |
| **Engineer** | Control & Infrastructure | Deployable turrets, door-seal breakers | Tactical, holds chokepoints, slows Synth units |

---

## Hive Mind Toolset (MVP)

**Unit Types**
- **Crawler**: Fast, fragile. Deployed in swarms. Forces squads to break cover.
- **Stalker**: Slow, tanky, lethal. Follows heat signatures through walls. Single-target pressure.
- **Pulse Drone**: Aerial. Disrupts electronics, jams HUDs, reveals Reclaimer positions to Hive feed.

**Environmental Controls**
- Blast door sealing (splits squads)
- Floor collapse triggers (fall damage, route disruption)
- Toxin flooding (forces gas mask resource drain)
- Camera network manipulation (remove or spoof Reclaimer waypoints)
- Power grid surges (kills lights, disables Reclaimer tech temporarily)

---

## Pillars

### Pillar 1 — The City Is the Enemy
AXIOM City is not a backdrop — it's an active, intelligent opponent. Every wall, corridor, and system is a potential weapon.

*Design test*: If a feature doesn't make the city feel more alive and threatening, we cut it.

### Pillar 2 — Asymmetry Is the Point
Playing Synth and playing Reclaimer should feel like completely different games sharing one world. We never flatten that gap for convenience.

*Design test*: If balancing this makes both sides feel the same, we find a different solution.

### Pillar 3 — Every Match Tells a Story
Win or lose, each run through AXIOM City should produce a moment the squad talks about after. The chaos is the feature.

*Design test*: If a mechanic produces the same outcome every time, it needs more variance.

### Pillar 4 — Identity Over Loadout
A player's faction, class, and playstyle should feel like a genuine identity — not just a stat package. Customization is self-expression.

*Design test*: If two players with different builds feel interchangeable in play, the builds aren't distinct enough.

---

## Anti-Pillars

We will **NOT** do the following:

- **No battle royale modes.** It would destroy the intimate asymmetric tension that defines the game.
- **No cinematic storytelling.** Cutscenes and narrative delivery take second seat to emergent moment-to-moment play.
- **No pay-to-win monetization.** Progression-affecting items will never be paywalled — cosmetic identity only.
- **No solo mode.** The squad bond is load-bearing. SYNTHFALL is a social experience by design.

---

## Visual Identity Anchor

**Selected Direction**: Dark Martian Brutalism

**One-Line Visual Rule**: AXIOM City is beautiful and wrong — clean lines corrupted by organic Synth growth, neon infrastructure rotting from within.

**Supporting Visual Principles**

1. *Contrast as information*: Reclaimer HUDs and gear are warm amber/orange. Synth-controlled spaces bleed into cold electric blue and corruption purple. Players know who owns a space from across the room.
   — Design test: Can a new player identify Synth-controlled vs. Reclaimer-safe zones in under 2 seconds?

2. *Lived-in decay*: AXIOM City was beautiful. The architecture still shows it — but Synth growth cracks the tiles, vines the corridors, pulses through the walls. The city is alive in the wrong way.
   — Design test: Every environment should feel like it's in the process of becoming something else.

3. *The Hive Mind has a visual signature*: Synth-deployed units and hazards have a consistent bioluminescent pulse. Players learn to fear the glow.
   — Design test: A Synth unit should be identifiable by silhouette and light signature alone, even in darkness.

**Color Philosophy**: Dark base (near-black Martian stone, deep charcoal metals), Synth corruption in electric teal/violet, Reclaimer presence in amber and worn orange. Emergency states bleed to full red. Clean white is reserved for pre-corruption AXIOM flashbacks and UI overlays.

**Reference Touchstones**: Prey (2017) environmental storytelling, Returnal's hostile alien architecture, Dead Space's industrial horror lighting, Ingress Prime's faction color language.

---

## MDA Analysis

| Layer | Reclaimers | Hive Mind |
|---|---|---|
| **Mechanics** | Squad movement, objective interaction, class abilities, ammo management | Unit deployment, environmental controls, Corruption escalation |
| **Dynamics** | Tension-relief cycles tied to Corruption meter; squad communication under pressure; asymmetric information disadvantage | Reading human patterns; resource trade-offs; shaping the battlefield to force mistakes |
| **Aesthetics** | Fellowship (squad bond), Challenge (survival), Sensation (the desperate close call) | Expression (your Synth style), Fantasy (being the city), Challenge (mind-gaming the squad) |

---

## Player Motivation Profile (SDT)

- **Autonomy**: Reclaimers choose routes, builds, and tactics. Hive Mind chooses *how* to overwhelm — no two Synth players are the same.
- **Competence**: Reclaimers improve at reading Synth behavior patterns. Hive Mind players develop signature styles that become recognizable.
- **Relatedness**: The squad bond is forged under pressure. Hive Mind players build reputation across sessions.

**Primary audience**: Socializers (squad play) + Competitors (asymmetric mind-games)
**Secondary audience**: Strategists (Hive Mind role), Explorers (AXIOM City lore and systemic mastery)
**Not for**: Solo players, players requiring ranked ladder systems above all else, narrative-first players

---

## Flow State Design

The Corruption meter creates natural flow cycles:
- **Rising tension**: Corruption climbs, Synth pressure increases, squad gets louder and more urgent
- **Relief beat**: Objective completed, Corruption dips, squad gets 15–30 seconds of lower pressure
- **Escalation**: Next sector starts harder than the last — the cycle repeats at a higher baseline
- **Climax**: Final extraction — Corruption near max, all Hive Mind tools unlocked, squad at resource minimum

This structure mirrors the proven L4D pacing model but gives the Hive Mind *active control* over when and how the pressure spikes — making the experience unpredictable and replayable.

---

## Scope & Feasibility

### MVP (Months 1–8)
Goal: Prove the core loop is fun. One sector, four classes, one Hive Mind role, local/LAN play.

- 1 AXIOM City sector (modular tile set, 1 layout)
- 4 Reclaimer classes with base loadouts
- Hive Mind core toolset (3 unit types, 5 environmental controls)
- Corruption meter, win/loss conditions
- Basic lobby and session management

**MVP question to answer**: Is a 30-minute asymmetric match — with communication pressure and a living city — fun for strangers?

### Launch (Months 8–18)
- 3 AXIOM City sectors (distinct architecture, different Corruption behaviors)
- Full class progression trees, cosmetic customization
- 2 Hive Mind personalities
- Steam matchmaking and role queue
- Post-match debrief system, mission logs
- Cosmetic monetization layer

### Live Ops Tail (Post-Launch)
- New sectors (seasonal)
- New Hive Mind personalities
- Limited-time faction events (Ingress-style territory shifts)
- Synth-Touched faction introduction

### Scope Tiers Summary

| Tier | Timeline | Deliverable |
|---|---|---|
| MVP | 6–8 months | 1 sector, core loop, LAN/local |
| Launch | 14–18 months | 3 sectors, full progression, Steam release |
| Live ops | Post-launch ongoing | Seasonal content, new factions |

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| Asymmetric balance | HIGH | Extensive playtesting from month 3; tunable Corruption curve; Hive Mind "difficulty profiles" for queue health |
| Matchmaking queue split | HIGH | Offer solo Hive Mind queue with AI Reclaimer fallback for testing; target community-first launch |
| Unity multiplayer complexity | MEDIUM | Prototype network authority model in month 1; evaluate NGO vs. Mirror vs. Photon early |
| Synth player learning curve | MEDIUM | Hive Mind tutorial sector; replay tools so Synth can study their own matches |
| Content volume for launch | MEDIUM | Modular tile design system keeps sector creation efficient |

---

## Next Steps (Pre-Production Pipeline)

1. `/setup-engine` — configure Unity and populate version-aware reference docs
2. `/art-bible` — establish visual identity (Dark Martian Brutalism) before writing GDDs
3. `/design-review design/gdd/game-concept.md` — validate concept completeness
4. `/map-systems` — decompose into individual systems with dependencies
5. `/design-system [corruption-meter]` — author per-system GDDs starting with the core tension engine
6. `/create-architecture` — produce the master architecture blueprint
7. `/architecture-review` — bootstrap Requirements Traceability Matrix
8. `/gate-check pre-production` — validate readiness before committing to production

---

*Generated via `/brainstorm` — Claude Code Game Studios*
