# Game Concept: The Last Seal (Voxel)

*Created: 2026-07-09*
*Status: Draft*

> Working title — carried over from the predecessor prototype (`The_Last_Seal`,
> Godot grid-idle). This project is a clean-slate reimplementation in a voxel
> look, keeping the proven design and discarding accreted code. Rename is open.

---

## Elevator Pitch

> It's a **voxel colony-builder with squad tactics** where you grow a living
> settlement — villagers build their own homes, learn trades and form bonds —
> and lead a squad to hold off waves and delve the dungeons behind failing seals.

Test: a newcomer gets it in 10 seconds — "Build a blocky village that lives on
its own, then fight to protect it." ✅

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Colony-builder / settlement sim + squad tactics RPG |
| **Platform** | PC (Windows first) |
| **Target Audience** | Fans of cozy-but-deep base-builders who also want stakes (see profile) |
| **Player Count** | Single-player |
| **Session Length** | 30–90 min; real-time with pause and time-warp |
| **Monetization** | none yet (premium later) |
| **Estimated Scope** | Large (9+ months) — but staged: MVP → Vertical Slice first |
| **Comparable Titles** | Stonehearth, RimWorld, Stardew Valley (village life) |

---

## Core Fantasy

You are the unseen steward of a small band of settlers in a blocky **wide
land** — your settlement starts as a clearing in a vast, explorable world.
You don't control them like puppets — you **shape their world**, and
they live in what you build: they move into the houses you lay out, take up
trades, eat and sleep in the rooms you furnished. When the old seals weaken and
monsters come, you rally the able ones into a squad and stand in the gap. The
fantasy is **stewardship of a place that feels alive** — pride when a plain
plot becomes a warm, furnished home, and a village that visibly lives because
of what you built — plus the pull of **the horizon**: distant seal-dungeons
and unexplored terrain that make leaving the settlement an expedition.

> **World-scale decision (2026-07-11, creative director)**: the world is
> LARGE — target **2000×2000×32 cells** (minimum 1000×1000), motivated by
> exploration and distant dungeons; density grows over the game's life. The
> settlement core stays compact (villager life happens there); the far world
> is expedition space. Feasibility proven in `prototypes/chunked-mesher/`;
> architecture in ADR-0014 (supersedes ADR-0003). This replaces the earlier
> "small hand-shaped valley (~100×100)" framing throughout older documents —
> where an older doc says "valley bound", read "settlement core region".
> **Far-world content direction (2026-07-11, creative director — headline only,
> design deferred)**: the space between settlement and seals is filled by
> (1) encounters, both hostile AND friendly, (2) resource nodes, (3) ruins.
> To be designed in dedicated GDDs before the dungeon/exploration epics;
> answers the CD gate condition "far world must not read hollow".

> **World-scale production target (2026-07-23, slice revision)**: the
> production target is now **16,000×16,000×32 cells** — up from the
> 2026-07-11 target of 2000×2000×32 recorded above. The 2000×2000×32 figure
> is not superseded as a claim; it is now the **slice-validated baseline**:
> the vertical slice built and held 60 FPS on a 2000×2000×32 view window
> (ADR-0014), so that scale is proven, not merely feasibility-projected. The
> 8x linear jump to 16,000×16,000 is GATED on a storage/streaming spike: a
> naive projection of the slice's packed-chunk storage at 16k×16k×32 is
> ≈11 GB of chunk data resident at boot — roughly 3x over the project's
> 4 GB memory ceiling (`.claude/docs/technical-preferences.md`). This is a
> **storage problem, not a rendering problem** — draw calls are already
> decoupled from world size via the streamed view window (the slice held
> 60 FPS regardless of how much world existed outside that window); the open
> question is how much of the 16k world's cell data can stay resident vs.
> paged/on-demand. Until that spike resolves, treat 16,000×16,000×32 as the
> target and 2000×2000×32 as the currently-built, currently-proven floor.
> Full detail: `design/gdd/voxel-world.md` Tuning Knobs and Open Questions.
> (Slice revision 2026-07-23)
>
> **Character scale (2026-07-23, slice revision)**: villagers and other
> characters are **2 blocks (cells) tall** — a Minecraft-proportions
> direction (blocky, no rounding) with a Stonehearth-chibi head ratio
> (bigger head-to-body weight than a realistic 2-block figure would carry).
> This was validated in the vertical slice's Minecraft-readability pass. The
> full visual spec (head:body split, limb block count, silhouette rules) is
> owned by **Art Bible §5.2 "Villager Visual Archetype — 2-Block
> Proportions"** (`design/art/art-bible.md`) — this document defers to it
> rather than duplicating the spec. (Slice revision 2026-07-23)


---

## Unique Hook

**It's like Stonehearth's self-built houses — AND ALSO every piece of furniture
carries the home's function, so a house is literally the sum of what you put in
it.** You draw walls/roof/floor to make an enclosed room; a bed makes it shelter,
a table makes it a dining spot, a hearth makes it social, a door makes it a
*real home*. Building isn't decoration on top of stats — the building **is** the
stats. This fuses base-building and colony-needs into one loop, and it's the
thing the predecessor proved fun and this project makes central.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 4 | Cozy voxel look, warm light, readable blocky forms |
| **Fantasy** | 2 | Steward of a living settlement in a threatened valley |
| **Narrative** | 5 | Emergent villager stories (bonds, diaries) + light seal arc |
| **Challenge** | 3 | Wave defense & dungeon delves; economy pressure |
| **Fellowship** | 6 | Between villagers (relationships), not player-to-player |
| **Discovery** | 4 | Emergent systems, seed variety, dungeons, township growth |
| **Expression** | 1 | **Primary** — how you build & furnish your village is you |
| **Submission** | 3 | Calm real-time settlement management between threats |

### Key Dynamics (Emergent player behaviors)
- Players lay out and refurnish homes to nudge villager mood and needs.
- Players specialize villagers into trades and master-crafters for better goods.
- Players read the settlement's rhythm (day plan, needs) and pre-empt problems.
- Players build a defensible, prosperous town, then push into dungeons.

### Core Mechanics (Systems we build)
1. **Player-driven building** — templates + rooms (wall/roof/floor) + doors/
   windows + furniture-carries-function + quality + build-over-time.
2. **Living settlement** — needs (sleep/food/company), mood, professions &
   ranks, day schedules, personalities & bonds.
3. **Economy & production** — gather → refine → craft chains, storage, trade.
4. **Squad tactics** — wave defense + seal dungeons; classes, gear, talismans.
5. **Township progression** — prosperity tiers unlock content and raise stakes.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Free-form building, who does what, how the town grows | Core |
| **Competence** | Mastering the economy, crafting quality, winning waves | Core |
| **Relatedness** | Caring about named villagers whose lives you shape | Supporting |

### Player Type Appeal (Bartle Taxonomy)
- [x] **Achievers** — township tiers, unlocks, master-crafters, deliveries.
- [x] **Explorers** — emergent systems, seed variety, dungeons, building depth.
- [x] **Socializers** — vicarious: villager relationships, diaries, community life.
- [ ] **Killers/Competitors** — not a focus (no PvP).

### Flow State Design
- **Onboarding**: first minutes = place a room, drop a bed, watch a villager
  move in and sleep — the build→life loop taught by doing.
- **Difficulty scaling**: waves harden with township tier; economy demands grow.
- **Feedback clarity**: mood/needs UI, building appeal, transparent build costs.
- **Recovery from failure**: settlement setbacks are recoverable; real-time pause
  lets the player think; permadeath is scoped to combat, not the whole run.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Place/adjust building pieces, assign a villager, queue a craft, watch the world
tick. The satisfying atom: laying a room and seeing it take shape.

### Short-Term (5–15 minutes)
Complete a house (shell → furnish → villager moves in), stand up a production
chain, prep for the next wave. "One more room / one more upgrade."

### Session-Level (30–90 minutes)
Grow the settlement a visible step: new homes, a new trade, survive a wave or
clear a dungeon floor. Ends at a natural lull with an obvious next goal.

### Long-Term Progression
Township tiers (hamlet → village → keep), master-crafters, unlocked seeds/
recipes/buildings, deeper dungeons as seals fail.

### Retention Hooks
- **Curiosity**: what's behind the next seal; what the next tier unlocks.
- **Investment**: the town you built, and the villagers living in it.
- **Mastery**: tighter economy, higher-quality goods, harder waves.

---

## Game Pillars

### Pillar 1: The building IS the game
Every structure and furnishing has mechanical meaning; building and colony-sim
are one system, not two.
*Design test*: If a build feature is "pure decoration," it must still feed
appeal/function — otherwise cut it.

### Pillar 2: A settlement that feels alive
Villagers have needs, moods, trades, routines and relationships the player
reads and shapes.
*Design test*: If a system doesn't make villagers feel more like people, it's
lower priority than one that does.

### Pillar 3: Cozy, but with stakes
Calm creative base-building punctuated by real threat (waves, dungeons).
*Design test*: A threat (wave, dungeon delve, alarm) must not lock the player
out of building/decorating for more than **10 minutes** in a single
interruption. If a proposed feature would force a longer building-lockout, cut
or shorten it rather than accept the interruption. (10 min is a provisional
value — revisit once the wave-defense system is playtested.)

### Pillar 4: Clarity over complexity
Deep systems, legibly presented (costs, needs, mood shown up front).
*Design test*: If a mechanic can't be made readable in the UI, simplify the
mechanic, not the UI.

### Anti-Pillars (What This Game Is NOT)
- **NOT a free voxel-editor**: building is purposeful and structured (rooms,
  walls, and roofs are first-class objects) — but free single-block placement
  and edits are allowed *within* that structure for expressive detail (validated
  by the `/prototype building` concept prototype, 2026-07-09, verdict PROCEED).
  We will NOT support unbounded terraforming/mining outside the settlement's
  buildable footprint — that would drown the colony sim.
- **NOT a god-object codebase**: no single mega-script; modular systems from day
  one (the explicit lesson from the predecessor).
- **NOT a twitch action game**: combat is tactical/positional, real-time-with-
  pause, not reflex-driven.
- **NOT multiplayer**: single-player focus keeps scope honest.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Stonehearth | Self-built houses (templates, walls/roof/floor, door/window fixtures, build-over-time), voxel look | Grid/room abstraction (not full voxel construction); furniture *carries* function | Validates the build fantasy is the draw |
| RimWorld | Colony needs, mood, emergent stories | Cozier tone, lighter threat, building-centric | Validates emergent villager drama |
| Stardew Valley | Professions, value-chain economy, quality tiers, seasons | Multi-villager settlement, not a single farmer | Validates the production loop |

**Non-game inspirations**: cozy small-town life; the quiet pride of tidying and
furnishing a space; folk-tale "the seals that hold back the dark."

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 20–40 |
| **Gaming experience** | Mid-core |
| **Time availability** | 30–90 min evening sessions |
| **Platform preference** | PC |
| **Current games they play** | Stonehearth, RimWorld, Stardew Valley |
| **What they're looking for** | Base-building with meaning + villagers they care about, without punishing micromanagement |
| **What would turn them away** | Fiddly block-by-block building; opaque systems; all-combat or all-idle |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4.7-stable / GDScript** — matches team expertise, existing engine reference & tooling, Blender voxel pipeline. Voxel rendering approach: **TBD — see building ADR** (GridMap vs. MultiMeshInstance3D vs. a chunked/greedy mesher is a real architecture trade-off, not pre-decided — see Open Questions). `.vox` assets via MagicaVoxel/Blender remain the source pipeline regardless of the rendering approach chosen. |
| **Key Technical Challenges** | Building system (room→wall/roof/floor graph, door/window openings, build-over-time); many villagers/entities at performance (MultiMesh/servers); save/load of a large mutable world |
| **Art Style** | 3D stylized **voxel** (MagicaVoxel `.vox`), warm palette, top-down/orbit camera |
| **Art Pipeline Complexity** | Medium — voxel assets via MagicaVoxel/Blender; reusable block kit |
| **Audio Needs** | Moderate — ambient village bed, light stingers for waves |
| **Networking** | None |
| **Content Volume** | Target VS: ~6 buildable furniture types, ~5 villagers, 1 wave, 1 dungeon floor; Full: multiple trades, seed/recipe trees, township tiers, dungeon depth |
| **Procedural Systems** | Light — dungeon layout; settlement is player-authored |

---

## Risks and Open Questions

### Design Risks
- Building must feel *better* than the predecessor's grid rooms, or the pivot
  isn't justified — doors/windows/build-over-time must land.
- Balancing "cozy" vs "stakes" so neither half feels bolted on.

### Technical Risks
- Voxel building system is the hard core — must be prototyped before committing.
- Entity performance at village scale (proven approach: MultiMesh/servers).

### Market Risks
- Stonehearth-adjacent space is loved but niche; differentiation = the
  furniture-carries-function hook + polish.

### Scope Risks
- Full vision is large; MUST gate via MVP → Vertical Slice before production.
- Re-implementing the predecessor's breadth is tempting — resist until the core
  build loop is proven.

### Open Questions
- How much of the building graph (columns/walls/roof) do we model vs abstract?
  → resolved by the **building prototype** (2026-07-09): rooms/walls/roofs are
  structured objects, walls extrude full-height in one action, and individual
  blocks/fixtures can be freely placed and edited within that structure.
- Voxel rendering approach at production scale: GridMap vs MultiMeshInstance3D
  vs a chunked/greedy mesher? → resolve via **building ADR** (`/create-architecture`).
  The concept prototype validated the *interaction* (free per-block placement,
  undo/redo, surface-aware editing) using individual MeshInstance3D nodes — not
  GridMap's fixed-palette-per-cell model — so this is a real architecture
  trade-off, not the pre-decided "GridMap/MultiMesh" this doc used to state.
- Real-time-with-pause tick model carried over as-is, or revised? → design doc.
- **Wave-defense ↔ freeform-base spatial contract**: waves have no stated
  attack-vector/chokepoint logic against a fully player-authored settlement —
  a player could trivialize every wave (moat-and-bridge) or build an
  undefendable perimeter with no fair tell. This is the untested half of
  Pillar 3 (building alone was validated; stakes were not). → resolve with a
  dedicated **wave-defense/freeform-base prototype**, the recommended next
  validation priority per the 2026-07-09 design review.
- **Freeform building navigability**: does a room need a validated path (e.g.,
  a door) before it's marked "livable," or can a player accidentally wall off
  a bed with no reachable opening, stalling a villager's AI? →
  **RESOLVED 2026-07-10 (design half)**: yes — reachability is a room
  condition (`build-validation-navigability.md` Rule 2: valid room =
  roofed + floored + villager-walkable opening); sealed structures raise
  visible warnings, never block building, and villager AI never stalls
  (jobs stay queued, villagers never teleport). The technical half
  (NavigationServer3D runtime-rebake cost) remains open → building/AI ADR
  + pre-VS performance spike.
- **Township "prosperity"**: what measurable variable actually gates
  progression tiers — population? cumulative build/furnishing value? days
  survived? a composite score? Currently unnamed even as a candidate. →
  resolve before `/map-systems` locks the township-progression system; this
  also feeds the wave-difficulty curve ("waves harden with township tier").
- **Villager population ceiling**: what's the target max concurrent villagers
  at Full Vision scope? Bounds the AI architecture choice (behavior-tree-per-
  agent vs. shared utility AI vs. LOD'd simulation) and the performance budget.
  → **RESOLVED 2026-07-10: 20–30 concurrent villagers** (user decision,
  recorded in `design/gdd/villager-ai-behavior.md` — a design commitment for
  individual legibility per Pillar 2, permitting deep per-agent AI. MVP: 1,
  Vertical Slice: ~5).

---

## MVP Definition

**Core hypothesis**: *"Drawing a room, furnishing it, and watching a villager
move in and live there is satisfying enough to be the heart of the game."*

> **Test-scope note (2026-07-10 cross-review, user decision)**: the MVP as
> scoped (1 villager, 1 need, 1 furniture item, free tier-0 materials, no
> threats) tests the **first ~10 minutes** of the build→furnish→live loop —
> the moment-to-moment satisfaction of the core verb — NOT sustained
> engagement. Sustained pull (goals, scarcity, threats, more needs) arrives
> with Vertical Slice content (doors, food, first wave). Interpret MVP
> playtest results accordingly: "I built the room, watched the move-in, and
> then wanted more" is a PASS for this hypothesis, not a failure. Two known
> MVP gaps are accepted and documented: walls are mechanically inert (see
> build-validation-navigability.md Edge Case 6) and no scarcity exists —
> both are Vertical Slice priorities, not MVP defects.

**Required for MVP**:
1. Draw a room (wall/roof/floor) on a grid, choose material.
2. Place functional furniture (bed = shelter) inside; build happens over time.
3. One villager with needs (sleep) that the home satisfies + visible mood.

**Explicitly NOT in MVP** (defer):
- Combat/waves/dungeons, professions/economy depth, township tiers, trade,
  templates library, doors/windows (add in Vertical Slice).

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 room + 1 bed + 1 villager | Build→furnish→need-satisfied loop | ~2–3 wks |
| **Vertical Slice** | A small buildable homestead + 1 wave | Building (templates, door/window, build-over-time) + needs + 1 combat beat | ~6–8 wks |
| **Alpha** | All core systems, placeholder content | Economy, professions, township, dungeons rough | TBD |
| **Full Vision** | Full content, polished | All pillars realized | TBD |

---

## Next Steps

- [ ] Get concept approval from creative-director (`/design-review design/gdd/game-concept.md`)
- [x] Engine choice: **Godot 4 / GDScript** (recorded in CLAUDE.md; finalize via `/setup-engine`)
- [ ] Create game pillars document
- [ ] **Prototype the building core** (`/prototype building`) — validate before GDDs
- [ ] If prototype PROCEEDS: decompose into systems (`/map-systems`)
- [ ] Design each system (`/design-system [name]`)
- [ ] Build vertical slice (`/vertical-slice`)
- [ ] Plan first milestone (`/sprint-plan new`)
