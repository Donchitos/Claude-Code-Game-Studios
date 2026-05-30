# Map / Arena System — Game Design Document
> **System**: Map / Arena System
> **Priority**: MVP
> **Layer**: Game Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

### What Is a Map in BRAWLZONE?

A **map** (also called an **arena**) is the bounded play space in which a match takes place. Every match session is assigned exactly one map. The map defines:

- The physical dimensions of the play field (width × height in logical game units).
- All static and dynamic structural elements: impassable walls, destructible obstacles, soft cover.
- Named zones used by game modes (capture points, shrinking safe zone boundary).
- Spawn points for players, with mode-specific placement rules.
- Visual presentation data passed to the rendering layer (tile theme, layer assets, thumbnail).

Maps are **static data assets** stored in the Content Catalog. They are not procedurally generated at MVP; every match loads one of the pre-authored map definitions.

### What Data a Map Contains

Each map entry in the Content Catalog is a single JSON object conforming to the Map Schema (see Section 3.1). The schema covers identity, geometry, spawn configuration, obstacle layout, zone definitions, shrink configuration (FFA only), visual theme, and mode compatibility flags.

### How a Map Is Selected

Map selection happens **server-side** at match creation time, before any player client connects. The Match Server:

1. Receives the resolved game mode (Duel / Squad Brawl / FFA).
2. Queries the eligible map pool: all maps whose `mode_compatibility` array includes the requested mode.
3. Applies weighted-random selection from the eligible pool.
4. Applies a **no-immediate-repeat** filter: if a map was the last map played in the same matchmaking bracket/lobby, its selection weight is set to 0 for this pick.
5. Broadcasts the selected map's `id` to all clients in the match session.

### Server vs. Client Responsibility Split

| Concern | Server (Authoritative) | Client (Presentational) |
|---|---|---|
| Map schema / definitions | Loads from Content Catalog; is the ground truth | Receives map `id` from server; loads same JSON from bundled or cached asset |
| Spawn assignment | Assigns spawn indices to player IDs; sends assignments | Renders player at server-assigned spawn |
| Obstacle state | Tracks HP of destructible obstacles; broadcasts destruction events | Renders obstacle alive/destroyed; plays VFX on destruction event |
| Zone boundary | Calculates shrinking zone radius each tick; broadcasts `zone_state` | Renders zone overlay; applies damage UI cue when player is outside zone |
| Collision detection | Authoritative collision against obstacle layout | Performs client-side prediction using same map data; reconciles on correction |
| Minimap data | Not applicable | Renders minimap from local map data + server-broadcast player positions |

---

## 2. Player Fantasy

### Maps as the Stage for Brawler Action

BRAWLZONE's core fantasy is **fast, high-skill, high-drama combat**. Maps amplify this by ensuring that no two matches feel identical, that the terrain itself creates decisions, and that each mode has a distinct spatial personality.

### Mode-Specific Fantasy Goals

**1v1 Duel — "The Cage"**
The Duel map fantasy is a gladiatorial cage: two fighters with no exits, forced into constant confrontation. Maps for Duel use:
- Tight corridors and hard walls that redirect movement rather than allow open-field avoidance.
- Shallow alcoves that reward positional footsies — not deep hideaways.
- A compact footprint so neither player can camp; the pressure is always on.
- Design goal: every 10 seconds of a Duel should have at least one meaningful interaction.

**3v3 Squad Brawl — "The Grind"**
Squad Brawl maps create team-vs-team tension through **choke points**, **flanking corridors**, and **a contested center**. Maps for Squad Brawl feature:
- A clear central lane contested by both teams.
- At least one flanking route per side so teams can split or rotate.
- Soft cover near the center to reward aggressive mid-control without making it a free kill zone.
- Design goal: a team that holds the center lane should win more often — but a coordinated flank should always remain viable.

**8-player FFA — "The Storm"**
FFA maps create emergent chaos by combining a large open area (initial phase) with a shrinking zone that funnels all surviving players into an ever-smaller kill box. Maps for FFA feature:
- A large starting arena with multiple isolated clusters, so early fights are not a free-for-all pile-up.
- A zone that shrinks inward, forcing movement and preventing turtling.
- Scattered soft cover to create micro-duels inside the chaos, rather than one massive team fight.
- Design goal: the last 60 seconds of an FFA match should feel like a chaotic, no-escape final confrontation.

### How Map Variety Sustains Engagement

- Three distinct visual themes at MVP (industrial, jungle, neon/urban) ensure each arena looks and feels different even before gameplay begins.
- Mode compatibility allows some maps to serve multiple modes, giving players familiar arenas in new configurations.
- Weekly featured map rotation (post-MVP) can emphasize a single map to create community moments.

---

## 3. Detailed Rules

### 3.1 Map Data Schema

Every map is a JSON object with the following fields. All fields are required unless marked `optional`.

```jsonc
{
  // --- Identity ---
  "id": "string",                        // Unique slug, e.g. "slag_pit_duel"
  "name": "string",                      // Display name, e.g. "Slag Pit"
  "version": "integer",                  // Schema version; MVP = 1

  // --- Mode Compatibility ---
  "mode_compatibility": ["string"],      // Array of mode IDs: "duel_1v1" | "squad_3v3" | "ffa_8"

  // --- Geometry ---
  "dimensions_units": {
    "width": "number",                   // Logical game units (LGU), positive
    "height": "number"                   // Logical game units (LGU), positive
  },
  "safe_boundary_inset": "number",       // LGU inset from edge where players can exist; default 0.5

  // --- Spawn Points ---
  "spawn_points": [
    {
      "index": "integer",                // 0-based; unique within map
      "x": "number",                     // LGU from origin
      "y": "number",                     // LGU from origin
      "facing_angle_deg": "number",      // Initial facing direction (0 = right, 90 = up)
      "mode_tags": ["string"]            // optional: restricts spawn to specific modes
    }
    // ... minimum spawn counts per mode: Duel = 2, Squad Brawl = 6, FFA = 8
  ],

  // --- Obstacle Layout ---
  "obstacle_layout": [
    {
      "id": "string",                    // Unique within map, e.g. "wall_north_01"
      "type": "static" | "destructible" | "soft_cover",
      "shape": "rect" | "circle",        // MVP supports rect and circle only
      "x": "number",                     // Center x in LGU
      "y": "number",                     // Center y in LGU
      "width": "number",                 // For rect: width in LGU
      "height": "number",                // For rect: height in LGU
      "radius": "number",                // For circle: radius in LGU (omit for rect)
      "hp": "integer",                   // optional; only for type = "destructible"
      "movement_multiplier": "number"    // optional; only for type = "soft_cover" (0.0–1.0)
    }
  ],

  // --- Zone Definitions ---
  "zone_definitions": [
    {
      "id": "string",                    // e.g. "safe_zone", "capture_point_a"
      "type": "shrink_zone" | "static_zone",
      "initial_center_x": "number",      // LGU; used as shrink zone center anchor
      "initial_center_y": "number",
      "initial_radius": "number",        // LGU; full-arena radius at match start
      "mode_tags": ["string"]            // optional: which modes activate this zone
    }
  ],

  // --- Shrink Configuration (required if any zone is type "shrink_zone") ---
  "shrink_config": {
    "start_delay_sec": "number",         // Seconds after match start before zone begins shrinking
    "phases": [
      {
        "phase": "integer",              // 1-based phase index
        "duration_sec": "number",        // How long this phase lasts
        "end_radius_lgu": "number",      // Zone radius at end of this phase
        "damage_per_sec": "number"       // HP damage per second dealt to players outside zone
      }
      // ... 3 phases at MVP
    ],
    "final_hold_sec": "number"           // Seconds zone holds at minimum radius before match force-ends
  },

  // --- Visual / Presentation ---
  "visual_theme": "string",             // e.g. "industrial", "jungle", "neon_urban"
  "tile_layer_ids": ["string"],         // Ordered tile layer asset IDs; passed to render layer
  "thumbnail_asset_id": "string",       // Asset ID for lobby/map-select thumbnail
  "ambient_audio_id": "string"          // optional; background loop asset ID
}
```

### 3.2 Coordinate System

- **Origin**: `(0, 0)` is the **bottom-left corner** of the map.
- **X-axis**: increases to the right.
- **Y-axis**: increases upward.
- **Unit**: 1 Logical Game Unit (LGU) = 1 abstract distance unit. At MVP, 1 LGU = 32 pixels at a reference resolution of 375 × 812 CSS points (iPhone 14 viewport). This scale factor is applied at render time; all game logic operates exclusively in LGU.
- **Safe boundary**: Players and obstacles must not be placed closer than `safe_boundary_inset` LGU to the map edge. Spawn points and obstacle definitions violating this constraint are rejected by the Content Catalog schema validator.
- **Map bounds**: The play field spans `[safe_boundary_inset, width - safe_boundary_inset]` on X and `[safe_boundary_inset, height - safe_boundary_inset]` on Y. The server clamps all player positions to these bounds each tick.

### 3.3 Spawn Point Rules

#### Minimum Spawn Distance by Mode

| Mode | Min Spawn-to-Spawn Distance | Rationale |
|---|---|---|
| Duel (1v1) | 12 LGU | Prevents instant engagement on spawn; gives 1–2 seconds of reaction time |
| Squad Brawl (3v3) | 8 LGU (within team), 16 LGU (between teams) | Team mates can group; opposing teams cannot spawn-camp |
| FFA (8-player) | 10 LGU (all pairs) | Prevents any two players sharing a cluster on spawn |

These distances are enforced at **Content Catalog authoring time** by a validation script. Maps that fail validation are not published. No runtime enforcement is needed.

#### Spawn Assignment Algorithm

1. At match start, the server fetches the map's `spawn_points` array filtered by `mode_tags` matching the current mode (or untagged spawns, which are available to all modes).
2. The server shuffles the filtered spawn list using a seeded random (seed = `match_id` XOR `unix_timestamp_ms`).
3. Players are assigned spawn indices in match-join order (player[0] → spawn[0], player[1] → spawn[1], etc.).
4. **Distance validation pass**: after assignment, the server verifies no two assigned spawns are closer than the mode minimum. If a violation is detected (can occur if map has fewer valid spawns than minimum distance requirements allow), the server re-shuffles and retries up to 5 times before logging a warning and proceeding with the closest valid assignment.
5. Spawn assignments are included in the `match_start` server event and are authoritative. Clients must not override spawn positions.

### 3.4 Obstacle Types

At MVP, three obstacle types exist:

| Type | Impassable? | Destroyable? | Slows Movement? | Blocks Projectiles? | MVP Included? |
|---|---|---|---|---|---|
| `static` | Yes | No | No | Yes | Yes |
| `destructible` | Yes (until destroyed) | Yes (via abilities with `obstacle_damage` attribute) | No | Yes (until destroyed) | Yes |
| `soft_cover` | No | No | Yes (applies `movement_multiplier`) | Yes | Yes |

**Static obstacles** are the primary walls and boundary structures. Treated as immovable AABBs or circles for collision detection.

**Destructible obstacles** have an `hp` value. The server decrements `hp` when an ability with `obstacle_damage > 0` collides with the obstacle. When `hp` reaches 0, the server broadcasts a `obstacle_destroyed` event with the obstacle `id`. Clients transition the obstacle to a destroyed visual state. The destroyed obstacle is no longer included in collision checks.

**Soft cover** (e.g., tall grass, smoke vents) does not block movement but applies `movement_multiplier` to any player whose center point is within its bounds. It blocks projectiles (projectiles terminate on contact). Soft cover has no HP and cannot be destroyed at MVP.

### 3.5 Zone System (FFA Shrinking Zone)

The shrinking zone is only active in **FFA mode** and only on maps that include a `zone_definitions` entry of type `shrink_zone`.

#### Zone Behavior

- At match start, the zone is at `initial_radius`, encompassing essentially the entire play field.
- The zone begins shrinking after `shrink_config.start_delay_sec` seconds.
- The zone shrinks through a series of **phases**. Each phase linearly interpolates the zone radius from its current value to `end_radius_lgu` over `duration_sec` seconds.
- Any player whose position is **outside the zone boundary** (distance from `initial_center` > current zone radius) takes `damage_per_sec` damage per second, applied each server tick.
- The zone center does not move in MVP (it is fixed at `initial_center_x / initial_center_y`).
- After all phases complete, the zone holds at the final radius for `final_hold_sec`, then the server forces the match to end (awarding victory to the last surviving player or highest-score player if multiple remain at 1 HP).

#### Shrink Phases (MVP Default — tunable, see Section 7)

| Phase | Start Time (after `start_delay_sec`) | End Radius | Damage/sec |
|---|---|---|---|
| 1 | 0 sec | 60% of `initial_radius` | 5 HP/sec |
| 2 | 60 sec after phase 1 start | 30% of `initial_radius` | 15 HP/sec |
| 3 | 60 sec after phase 2 start | 10% of `initial_radius` | 40 HP/sec |

These are the MVP defaults baked into each FFA map's `shrink_config`. They can be overridden per-map or globally via tuning knobs.

### 3.6 Mode Compatibility

- A map may declare compatibility with **one or more modes** via its `mode_compatibility` array.
- A map declared as compatible with multiple modes must satisfy the spawn count requirements for all declared modes (i.e., must have at least 8 spawn points if compatible with FFA, even if it also serves Duel).
- At MVP, the recommendation is to author at least one **dedicated map per mode** to ensure optimal spatial design. Shared-mode maps can be added post-MVP.
- The Game Mode System must not assign a map to a mode for which it is not declared compatible. This is enforced server-side at map selection time; a map with an incompatible mode declaration is silently excluded from the eligible pool.

### 3.7 Map Selection Logic

```
eligible_pool = all maps where mode IN map.mode_compatibility
last_map_id   = matchmaking context's last_used_map_id (null if no history)

for each map in eligible_pool:
    weight = map.selection_weight   // base weight from Content Catalog; default 1.0
    if map.id == last_map_id:
        weight = 0                  // hard suppress immediate repeat

selected_map = weighted_random_choice(eligible_pool, weights)
```

- `selection_weight` is a float stored in the map's Content Catalog entry (not in the GDD schema above, as it is a catalog-level metadata field). Default: `1.0`. Higher values increase probability.
- If the eligible pool after suppressing the last map is empty (only one map exists for that mode), the suppression is lifted and the pool is restored to all eligible maps. A warning is logged.
- Map selection is deterministic given the same shuffled pool: the server logs the `selected_map_id` in the match record for replay/audit purposes.

### 3.8 Launch Map Roster (3 MVP Maps)

#### Map 1 — "Slag Pit"
| Field | Value |
|---|---|
| `id` | `slag_pit_duel` |
| `name` | Slag Pit |
| `mode_compatibility` | `["duel_1v1"]` |
| `dimensions_units` | 40 × 40 LGU |
| `visual_theme` | `industrial` |
| **Design intent** | Asymmetric walls create positional footsies. Two short corridors force engagement. One central destructible wall that opens the mid-lane once broken. No soft cover — Duel is raw mechanics. |
| **Spawn count** | 2 (one per player, 20 LGU apart) |
| **Obstacle summary** | 6 static wall segments, 1 destructible center wall, 0 soft cover |

#### Map 2 — "Canopy Clash"
| Field | Value |
|---|---|
| `id` | `canopy_clash_squad` |
| `name` | Canopy Clash |
| `mode_compatibility` | `["squad_3v3"]` |
| `dimensions_units` | 80 × 60 LGU |
| `visual_theme` | `jungle` |
| **Design intent** | Three-lane design: top, mid, bottom. Mid lane has two soft-cover clusters (tall grass) that reward aggressive mid-control. Top and bottom lanes are mirrored flanking corridors with static wall barriers to prevent cross-lane sniping. No shrinking zone. |
| **Spawn count** | 6 (3 per team, clustered in opposing corners with 8 LGU intra-team spacing, 32 LGU inter-team spacing) |
| **Obstacle summary** | 12 static wall segments, 2 destructible barricades (one per side of mid lane), 4 soft-cover grass patches |

#### Map 3 — "Neon Sprawl"
| Field | Value |
|---|---|
| `id` | `neon_sprawl_ffa` |
| `name` | Neon Sprawl |
| `mode_compatibility` | `["ffa_8"]` |
| `dimensions_units` | 120 × 120 LGU |
| `visual_theme` | `neon_urban` |
| **Design intent** | Large open arena with 4 distinct starting quadrants (separated by low static walls), ensuring players do not all pile up at spawn. Central hub is initially open. Shrinking zone forces convergence at center. Eight distributed soft-cover clusters provide temporary shelter as zone closes. Two destructible barricades in the central hub break open during mid-game. |
| **Spawn count** | 8 (two per quadrant, 10 LGU minimum spacing) |
| **Obstacle summary** | 8 static low walls (quadrant dividers), 2 destructible central barricades, 8 soft-cover scatter clusters |
| **Shrink zone** | Yes — `start_delay_sec: 60`, 3 phases (see 3.5 defaults) |

---

## 4. Formulas

### 4.1 Zone Shrink Radius Over Time

The zone radius at any moment `t` (seconds since `start_delay_sec` elapsed) is computed by the server each tick:

```
Let phases = shrink_config.phases  (sorted by phase index)
Let r0 = initial_radius

For each phase i (1-indexed):
    phase_start_t = sum of duration_sec for all phases before i
    phase_end_t   = phase_start_t + phases[i].duration_sec
    r_start       = (i == 1) ? r0 : phases[i-1].end_radius_lgu
    r_end         = phases[i].end_radius_lgu

    if phase_start_t <= t < phase_end_t:
        progress = (t - phase_start_t) / phases[i].duration_sec   // 0.0 → 1.0
        current_radius = r_start + (r_end - r_start) * progress    // linear lerp
        return current_radius

if t >= total_phase_duration:
    return phases[last].end_radius_lgu   // hold at final radius
```

**Zone boundary check per player per tick:**
```
dist = sqrt((player.x - zone.center_x)^2 + (player.y - zone.center_y)^2)
outside = dist > current_radius
if outside:
    player.hp -= phases[current_phase].damage_per_sec * tick_delta_sec
```

### 4.2 Minimum Spawn Distance Formula

For each pair of spawn points `(A, B)` assigned to players in the same match:

```
dist(A, B) = sqrt((A.x - B.x)^2 + (A.y - B.y)^2)

Required:
  Duel:        dist(A, B) >= 12 LGU   for all pairs
  Squad Brawl: dist(A, B) >= 8 LGU    for same-team pairs
               dist(A, B) >= 16 LGU   for cross-team pairs
  FFA:         dist(A, B) >= 10 LGU   for all pairs
```

Validation is run at authoring time (Content Catalog validator) and optionally re-checked server-side at spawn assignment (see Section 3.3 step 4).

### 4.3 Map Selection Weight Formula

```
P(map_i) = W_i / sum(W_j for all j in eligible_pool)

Where:
  W_i = map_i.selection_weight   if map_i.id != last_map_id
  W_i = 0                        if map_i.id == last_map_id

Special case: if sum(W_j) == 0 (all weights are 0 — single-map pool):
  W_i = map_i.selection_weight   (restore original weights, allow repeat)
```

---

## 5. Edge Cases

### EC-01: Fewer Players Than Spawn Points
**Scenario**: A 3-player FFA starts on Neon Sprawl (8 spawn points).
**Handling**: The server selects the first N spawn points from the shuffled list where N = player count. Unneeded spawn points are unused. No error; this is expected behavior for partial lobbies or early starts.

### EC-02: More Players Than Spawn Points (Disconnects Mid-Match)
**Scenario**: An 8-player FFA runs on a map with exactly 8 spawn points. Players disconnect and then reconnect — or a spectator/observer slot overflows the spawn list.
**Handling**: Spawn assignment only happens once at match start. Reconnecting players re-use their originally assigned spawn point (stored in `player_session` record). New players joining a running match (not supported at MVP) would require a fallback spawn; this is deferred. If `player_count > spawn_points.length`, the server wraps spawn indices (index % spawn_points.length) and logs a warning. This state should be impossible at MVP if map roster is correctly validated.

### EC-03: Map Data Fails to Load from Content Catalog
**Scenario**: The Match Server cannot fetch the selected map's JSON at session start (network error, schema version mismatch, missing asset).
**Handling**:
1. Server retries the fetch up to 3 times with 200ms back-off.
2. If all retries fail, the server attempts to fall back to a hardcoded **default map** per mode (Slag Pit for Duel, Canopy Clash for Squad Brawl, Neon Sprawl for FFA) whose JSON is bundled with the server binary.
3. If the bundled fallback also fails (corrupted binary), the match is aborted. Clients receive a `match_error` event with code `MAP_LOAD_FAILURE`. Players are returned to the lobby without penalty (no loss recorded).
4. The incident is logged with severity ERROR and triggers an alert.

### EC-04: Dynamic Obstacle State Desync (Server vs. Client)
**Scenario**: A destructible obstacle is destroyed on the server, but the client fails to receive the `obstacle_destroyed` event (packet drop, reconnect).
**Handling**:
- The full map state (including all destroyed obstacle IDs) is included in the `match_state_snapshot` event that the server sends every 5 seconds and on client reconnect.
- On receipt of a snapshot, the client reconciles its local obstacle states against the authoritative list.
- Clients must not rely solely on incremental `obstacle_destroyed` events; they must always accept snapshot reconciliation.
- If a client's collision prediction fails because it thinks a wall is intact but the server has destroyed it (player passes through the wall on server but is blocked on client), the server correction will teleport the player to the server-authoritative position. The client must handle position corrections gracefully (lerp correction, not snap).

### EC-05: Two Players Assigned the Same Spawn Point (Race Condition)
**Scenario**: Two concurrent match creation requests for the same map shuffle and select the same spawn assignments simultaneously.
**Handling**:
- Match creation is serialized per lobby/bracket. The Match Server processes one `create_match` request per lobby at a time using a lobby-scoped mutex.
- A separate match for a different lobby may share the same map but each match has an independent spawn shuffle; no cross-match spawn conflict is possible.
- Within a single match, spawn assignment is a sequential loop (not concurrent); two players cannot receive the same index.
- **Belt-and-suspenders**: Before broadcasting assignments, the server validates all assigned spawn indices are unique. If a duplicate is detected (should be unreachable), the server re-runs the full shuffle.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| Dependency | System | Contract |
|---|---|---|
| Map definitions (JSON) | **Content Catalog** | Maps are stored as static data entries. The Content Catalog exposes a `GET /catalog/maps/:id` endpoint and a `GET /catalog/maps?mode=:mode` list endpoint. The Map Schema (Section 3.1) is the agreed contract. The Content Catalog validator enforces spawn distance rules and schema conformance at publish time. |
| Asset IDs for visual layers | **Content Catalog / Asset Pipeline** | `tile_layer_ids`, `thumbnail_asset_id`, and `ambient_audio_id` are Content Catalog asset references. Resolution of asset ID → URL is the Content Catalog's responsibility. |

### 6.2 Downstream Dependencies (Consumers)

| Consumer | What It Needs | Contract |
|---|---|---|
| **Combat System** | Collision geometry for all obstacles on the active map | The Match Server provides the active map's `obstacle_layout` as part of the session initialization payload. Destructible obstacle HP state is maintained by the Map System and queried by the Combat System each time an ability with `obstacle_damage > 0` is resolved. |
| **Game Mode System** | Map assignment per mode; mode-valid map pool | The Map System exposes `selectMap(mode, lastMapId)` → `mapId`. The Game Mode System calls this at match creation and owns the mode context. |
| **Match Server** | Full map JSON at session start; dynamic state updates | The Match Server loads the map at session creation and holds the authoritative dynamic state (obstacle HP, zone radius). The Match Server is the runtime host of Map System logic. |
| **In-Match HUD** | Minimap: map dimensions, obstacle positions, zone boundary, player positions | The HUD consumes the map's `dimensions_units` and `obstacle_layout` from the client-side map JSON for static minimap rendering. Live player positions and zone radius are streamed from the server at 20 Hz. The HUD renders zone boundary as a circle overlay on the minimap. |
| **Matchmaking System** (future) | Last-used map ID per bracket for no-repeat logic | At MVP, the Match Server passes `lastMapId` to `selectMap()` from the session record. Post-MVP matchmaking may own this state. |

---

## 7. Tuning Knobs

All knobs below are configurable without code changes, via environment variables or a runtime config document. Default values are the MVP-validated starting point.

| Knob | Key | Default | Range | Effect |
|---|---|---|---|---|
| Zone shrink start delay | `zone.start_delay_sec` | 60 s | 30–120 s | Delays when zone begins closing; more time = more early exploration |
| Zone phase 1 duration | `zone.phase1_duration_sec` | 60 s | 30–90 s | Controls how slowly the zone closes in the opening phase |
| Zone phase 2 duration | `zone.phase2_duration_sec` | 60 s | 30–90 s | Mid-game squeeze speed |
| Zone phase 3 duration | `zone.phase3_duration_sec` | 45 s | 20–60 s | Endgame close speed |
| Zone damage phase 1 | `zone.phase1_dmg_per_sec` | 5 HP/s | 1–20 HP/s | Soft push in early phase; too high punishes exploration |
| Zone damage phase 2 | `zone.phase2_dmg_per_sec` | 15 HP/s | 5–40 HP/s | Meaningful pressure mid-game |
| Zone damage phase 3 | `zone.phase3_dmg_per_sec` | 40 HP/s | 20–80 HP/s | Near-lethal urgency in endgame |
| Zone final hold duration | `zone.final_hold_sec` | 30 s | 10–60 s | Time at minimum radius before force-end |
| Spawn min distance — Duel | `spawn.duel_min_dist_lgu` | 12 LGU | 8–20 LGU | Lower = more aggressive starts |
| Spawn min distance — Squad (intra-team) | `spawn.squad_intra_min_lgu` | 8 LGU | 4–12 LGU | Tighter team clusters |
| Spawn min distance — Squad (inter-team) | `spawn.squad_inter_min_lgu` | 16 LGU | 12–32 LGU | Longer = safer spawn; shorter = hot starts |
| Spawn min distance — FFA | `spawn.ffa_min_dist_lgu` | 10 LGU | 6–16 LGU | Wider spread = more isolated early fights |
| Destructible obstacle HP — light | `obstacle.hp_light` | 100 HP | 50–200 HP | E.g., wooden barricade; broken in 1–2 ability hits |
| Destructible obstacle HP — heavy | `obstacle.hp_heavy` | 300 HP | 150–500 HP | E.g., metal gate; requires sustained team fire |
| Map selection base weight | Per-map `selection_weight` field | 1.0 | 0.1–5.0 | Higher weight = appears more often in rotation |
| Soft cover movement multiplier | Per-obstacle `movement_multiplier` | 0.6 | 0.3–0.9 | 0.6 = 40% speed reduction in soft cover |

---

## 8. Acceptance Criteria

### AC-01: Map Schema Validity
**Given** a map JSON entry is submitted to the Content Catalog
**When** the schema validator runs
**Then** the entry is rejected if any required field is missing, any spawn distance pair violates mode minimums, or any obstacle coordinate falls outside safe boundary — and the validator returns a structured error listing each violation.

### AC-02: Map Selected for Correct Mode
**Given** a Duel match is being created
**When** the server runs map selection
**Then** only maps with `"duel_1v1"` in their `mode_compatibility` array are considered, and the selected map's `id` is returned within 50ms.

### AC-03: No Immediate Map Repeat
**Given** a Squad Brawl match just ended on map `canopy_clash_squad`
**And** a new Squad Brawl match is being created in the same bracket
**When** map selection runs
**Then** `canopy_clash_squad` has weight 0 and is not selected, provided at least one other eligible map exists.

### AC-04: Single-Map Pool Repeat Fallback
**Given** only one Squad Brawl-compatible map exists in the catalog
**When** map selection runs after a match on that map
**Then** the server logs a warning and selects that map anyway (weight suppression is lifted), rather than failing or returning null.

### AC-05: Spawn Assignment — Uniqueness and Distance
**Given** a 1v1 Duel match starts on Slag Pit
**When** the server assigns spawn points
**Then** player 0 and player 1 receive distinct spawn indices, the distance between their spawns is >= 12 LGU, and both spawn positions are within the map's safe boundaries.

### AC-06: Spawn Assignment — FFA
**Given** an 8-player FFA match starts on Neon Sprawl
**When** the server assigns spawn points
**Then** all 8 players receive distinct spawn indices and no two spawns are closer than 10 LGU from each other.

### AC-07: Obstacle Collision — Static
**Given** a player attempts to move through a static obstacle on Slag Pit
**When** the server processes the movement tick
**Then** the player's position is corrected to the nearest point outside the obstacle boundary, and a position correction event is sent to the client.

### AC-08: Destructible Obstacle — Destruction and State Broadcast
**Given** a destructible obstacle has 100 HP and a player uses an ability with `obstacle_damage = 50`
**When** the ability hits the obstacle twice within one match
**Then** after the second hit the server sets the obstacle's HP to 0, broadcasts `obstacle_destroyed` with the obstacle `id`, and excludes the obstacle from all future collision checks in that session.

### AC-09: Destructible Obstacle — Client Reconciliation on Reconnect
**Given** a player disconnects during a match after a destructible obstacle has been destroyed
**When** the player reconnects and the server sends a `match_state_snapshot`
**Then** the snapshot includes the destroyed obstacle `id` in the `destroyed_obstacles` list, and the client renders the obstacle as destroyed within one render frame of receiving the snapshot.

### AC-10: Zone Shrink — Starts After Delay
**Given** an FFA match starts on Neon Sprawl with `start_delay_sec = 60`
**When** 59 seconds have elapsed since match start
**Then** the server-authoritative zone radius equals `initial_radius` (no shrink has begun).

### AC-11: Zone Shrink — Linear Interpolation
**Given** an FFA match on Neon Sprawl, phase 1 begins at t=60s with `initial_radius = 60 LGU` and `end_radius_lgu = 36 LGU` over 60 seconds
**When** the server tick processes t=90s (30s into phase 1)
**Then** the authoritative zone radius equals `60 + (36 - 60) * 0.5 = 48.0 LGU` (± 0.1 LGU for floating-point tolerance).

### AC-12: Zone Damage — Outside Zone
**Given** a player is positioned 5 LGU outside the current zone boundary
**And** the current phase has `damage_per_sec = 15`
**When** the server processes a 50ms tick (delta = 0.05s)
**Then** the player receives exactly `15 * 0.05 = 0.75 HP` of damage that tick.

### AC-13: Zone Damage — Inside Zone
**Given** a player is positioned inside the current zone boundary
**When** the server processes any tick
**Then** the player receives zero zone damage.

### AC-14: Map Load Failure — Fallback
**Given** the Content Catalog returns a 500 error for a map fetch
**When** the server retries 3 times and all fail
**Then** the server loads the bundled fallback map for the mode, logs an ERROR, and the match proceeds normally without player notification beyond a minor delay.

### AC-15: Map Load Failure — Total Failure
**Given** both the Content Catalog fetch and the bundled fallback fail
**When** the server attempts to start the match
**Then** the match is aborted, all connected clients receive a `match_error` event with code `MAP_LOAD_FAILURE`, no loss is recorded for any player, and players are returned to the lobby state.

### AC-16: Minimap Zone Overlay
**Given** an FFA match is in progress and the zone is actively shrinking
**When** the In-Match HUD renders the minimap
**Then** the zone boundary is rendered as a visible circle overlay that updates in real time, and any player position outside the circle is visually distinguishable from positions inside.

### AC-17: Safe Boundary Clamping
**Given** a player's computed position (after movement resolution) is 0.3 LGU from the map edge
**And** `safe_boundary_inset = 0.5 LGU`
**When** the server processes the position
**Then** the player's position is clamped to `safe_boundary_inset` (0.5 LGU) from the edge, preventing players from leaving the defined play area.

---

*End of Map / Arena System GDD — v1.0 MVP Draft*
