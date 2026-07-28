# Resource & Item Database

> **Status**: APPROVED (2026-07-10 — full review NEEDS REVISION → all findings
> revised in-session → verification pass CLEAN; see
> design/gdd/reviews/resource-item-database-review-log.md); Slice-revised
> 2026-07-23 (multi-cell furniture footprint field — see
> prototypes/last-seal-vertical-slice/REPORT.md)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-23
> **Last Verified**: 2026-07-10
> **Implements Pillar**: None directly — Foundation infrastructure for Pillar 1 (building materials) and Pillar 2 (settlement economy)

## Summary

Resource & Item Database is the Foundation-layer data definition system for
every material, item, and resource type in the game — a single source of
truth for what a "thing" is (id, display name, category, stack rules,
material family, base properties) that Building System, Township Progression,
and future economy/inventory systems query rather than duplicate.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Resource & Item Database owns the static, data-driven definition of every
resource and item in the game world — not their placement, ownership, or
behavior, only their *definition*. Per the project's coding standard that
gameplay values must be data-driven, it is authored as a set of external
data resources rather than hardcoded values, and exposed through a lookup
API that other systems query by id. [TR-resource-item-database-020]

It exists because multiple systems need to agree on the same facts about a
given resource or item: the Building System needs to know a material is
valid for placement and which visual material family it belongs to; future
Storage & Inventory needs to know whether an item stacks and can be hauled;
Gathering & Production Chains needs to know what a recipe's inputs and
outputs refer to. Without one authoritative database, these facts would be
duplicated across systems and drift out of sync.

**Explicitly out of scope**: this system does not track where resources are
(Storage & Inventory, Alpha), who carries them to a build or craft site
(Villager AI hauling behavior), what they cost to place (Building System),
or how they are produced (Gathering & Production Chains). It defines the
nouns those systems act on — including the definition fields they will need
later (stackability, haulability, storage category) so the database does
not need a breaking rework when those Alpha systems arrive.

This system has no player-facing behavior of its own — no UI, no on-screen
representation. Players experience it exclusively through the systems built
on top of it: choosing a material in the Building System's placement tools,
or watching villagers gather and consume resources over time.

## Player Fantasy

None directly — this is pure infrastructure. Players never see or touch the
database itself; they feel what it enables through other systems:

- **Building System (Pillar 1)**: the fantasy of choosing *this* wood, *this*
  stone for a wall lives in the building tools — but the palette of materials
  they choose from is defined here.
- **Township Progression / economy (Pillar 2)**: the fantasy of a settlement
  that grows richer — new materials and items appearing over time — is
  delivered by unlock systems, but every unlockable thing is defined here.

The indirect design obligation this creates: material and item definitions
must carry enough identity (name, family, visual hookup per the Visual
Direction Note's material↔meaning color language) that the systems built on
top can make each material feel distinct rather than interchangeable.

> `creative-director` not consulted — Lean mode (non-high-risk section).

## Detailed Design

### Core Rules

1. **One definition per thing.** Every resource, material, and item in the
   game has exactly one definition in this database, identified by a unique,
   stable `snake_case` string id (e.g. `wood_block`). An id, once shipped in
   a save file, is never renamed or reused for a different thing (see Edge
   Cases for handling retired ids). [TR-resource-item-database-024]
2. **Definitions are static data.** Definitions are authored as external
   data resources (per the project coding standard: gameplay values are
   data-driven, never hardcoded). [TR-resource-item-database-002] The database loads once at boot,
   validates, and is immutable for the rest of the session. Nothing in the
   game ever modifies a definition at runtime. [TR-resource-item-database-025]
3. **Definition ≠ availability.** Whether a player can currently use an item
   is not stored here. Unlock/availability state is owned by the Alpha
   unlock systems. **Tier-axis scoping** *(user decision, 2026-07-10
   review)*: `tier` serves EXACTLY ONE gating axis — Township
   Progression's prosperity/availability ladder for materials. Recipe &
   Blueprint Unlocks does NOT key off `tier`: it references item ids plus
   its own independent unlock-condition list (that system depends on both
   Township Progression AND Gathering & Production Chains per the systems
   index — an AND-condition a single monotonic int cannot represent; its
   full condition design belongs to its Alpha GDD). [TR-resource-item-database-026]
4. **Definition schema.** Every entry carries these fields [TR-resource-item-database-027]:

   | Field | Type | Required in MVP | Notes |
   |-------|------|-----------------|-------|
   | `id` | string (snake_case) | Yes | Unique, stable, never reused |
   | `display_name` | string | Yes | Player-facing name (localizable later) |
   | `category` | enum | Yes | See Rule 5 |
   | `material_family` | enum or none | Yes for building materials | `wood` / `stone` / `thatch` per the Visual Direction Note; none for non-material items |
   | `tier` | int ≥ 0 (boot-validated since the 2026-07-10 review) | Yes | `0` = free bootstrap material (see Rule 6); higher tiers gated by Township Progression ONLY — the field's one axis (Rule 3) |
   | `visual_asset` | asset reference | Yes | Mesh/material hookup — the single place art assets bind to game data |
   | `stackable` | bool | Authored, unused until Alpha | Pre-provisioned for Storage & Inventory |
   | `max_stack_size` | int ≥ 1 | Authored, unused until Alpha | Only meaningful when `stackable` |
   | `haulable` | bool | Authored, unused until Alpha | Pre-provisioned for Villager AI hauling |
   | `storage_category` | enum | Authored, unused until Alpha | Which stockpile type accepts this item |
   | `footprint` | Vector2i (`width_cells`, `depth_cells`), both ≥ 1 | Yes for `furniture_fixture`; implicitly `(1,1)` for every other category — never authored on them *(added by the 2026-07-23 slice revision)* | The horizontal cell span the placed item's single model occupies, anchored at its origin cell — see Rule 10 |

   Fields marked "Authored, unused until Alpha" are required-present in MVP
   data files (boot validation enforces presence); only their *consumption*
   is deferred to Alpha. [TR-resource-item-database-028] `footprint` is
   NOT one of these deferred fields — it is consumed immediately at MVP
   (the `bed` entry needs it now).

5. **Fixed category set.** The schema defines five authorable categories
   from day one; MVP fills only the first two with content:
   `building_material` (MVP), `furniture_fixture` (MVP),
   `raw_resource` (Alpha), `consumable` (Alpha), `equipment` (Alpha). [TR-resource-item-database-029]
   A sixth, reserved, NON-authorable category `missing` exists solely for
   the built-in `missing_item` definition (Edge Case 1) — boot validation
   rejects any authored entry using it *(added 2026-07-10 review)*. [TR-resource-item-database-030]
   Adding a category is a schema change (design decision), not a data edit.
   *(Scheduling note, 2026-07-10 review: `consumable` is listed Alpha, but
   needs-mood-system.md schedules the `food` need at Vertical Slice — the
   VS revision of this GDD must populate `consumable` one tier earlier
   than planned; see Open Questions.)*
6. **The tier-0 bootstrap set.** Exactly three building materials ship at
   tier 0 — `wood_block`, `stone_block`, `thatch_block` — one per material
   family in the Visual Direction Note. Tier 0 means: the Building System
   treats them as always available and free of resource cost in the MVP.
   This implements the systems-index resolution of the Building ↔ Township
   Progression circular dependency: building is usable before any economy
   system exists. [TR-resource-item-database-031]
7. **MVP furniture content.** The `furniture_fixture` category is populated
   in MVP, but the exact entry list (which furniture, doors, windows) is
   owned by the Building System GDD — entries are authored here once that
   GDD names them. This GDD owns the schema, not the furniture list.
8. **Read-only lookup API.** Other systems query: get definition by id,
   list ids by category, list ids by material family, list ids by tier
   *(added 2026-07-10 review — Building System's palette queries the
   tier-0 set; without this method every consumer would hardcode ids or
   client-side-filter)*, list all ids. There is no write API. The database
   performs no gameplay logic — it never computes costs, validates
   placement, or spawns anything. [TR-resource-item-database-032] The reserved `missing_item` definition
   is EXCLUDED from all listing queries — it is reachable only via direct
   get-by-id (Edge Cases 1–2), never in a palette or category list. [TR-resource-item-database-033]
9. **Returned definitions are immutable to callers** *(added 2026-07-10
   review; mechanism RESOLVED 2026-07-11 via ADR-0006)*. A caller can never
   alter what a subsequent query returns (AC19) through any idiomatic
   property or method — `get_by_id()` returns a getter-only `ItemDefinition`
   wrapper (no setters exist) around the internally-stored, freely-editable
   `ItemDefinitionResource`. This is deliberately not a defensive copy (no
   per-query duplication cost, which matters directly for the per-frame
   palette/hover query pattern this rule originally flagged as
   performance-sensitive) — the wrapper's lack of any setter is what makes
   sharing the underlying data safe. The guarantee covers accidental/
   idiomatic mutation; deliberate `Object.get()`/`set()` reflection bypass
   is a documented residual risk in ADR-0006, not fully closed. [TR-resource-item-database-010]
10. **Multi-cell furniture footprint** *(added by the 2026-07-23 slice
    revision — user-locked, slice-validated: 2-cell-tall villagers need a
    2-cell bed; resolves Open Question 9)*: `furniture_fixture` entries
    carry a `footprint` (`width_cells` × `depth_cells`, both ≥ 1)
    declaring the horizontal cells the placed item's single model spans,
    anchored at its origin cell. `bed` is `(1, 2)`. Placement remains
    strictly on-grid — this field states only the fact of the span; it
    does not define placement, collision, rotation, or rendering rules
    (Building System owns placement; Art Bible §8.5 owns authoring the
    multi-cell model as one asset, not `width_cells × depth_cells`
    separate pieces). Building materials are voxel blocks and are
    implicitly `(1, 1)` — they never carry this field (Edge Case 10). [TR-resource-item-database-052]

### States and Transitions

*(System lifecycle — individual definitions have no state; they are
immutable data.)*

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|-----------------|----------|
| Unloaded | Before boot loading runs | Loading begins (data files read) *(wording aligned with Validating's entry at the 2026-07-10 review)* | No query is valid [TR-resource-item-database-034] |
| Validating | Data files read | Validation passes or fails | Checks: id uniqueness, id format, known category, known material family, required fields present, `max_stack_size ≥ 1` where stackable, `tier ≥ 0` (integer), category↔material_family pairing (`building_material` requires a family from the Visual Direction Note set; every other category requires `none`), tier-0 family coverage (the tier-0 `building_material` set contains ≥ 1 entry per material family — the Core Rule 6 invariant, now boot-enforced), reserved-id rejection (`missing_item`, category `missing`), retired-ids ledger *(three checks added + invariants formalized at the 2026-07-10 review — the schema declared them but the checklist never enforced them)*, category↔footprint pairing — `furniture_fixture` requires an explicit `footprint` with both dimensions ≥ 1; every other category must omit it (implicit `(1,1)`) *(added by the 2026-07-23 slice revision, Core Rule 10)* [TR-resource-item-database-005] |
| Ready | Validation passes | Never (persists for the session) | All queries valid; contents immutable [TR-resource-item-database-025] |
| Failed | Validation fails | None — TERMINAL *(aligned 2026-07-10 review with scene-world-management.md's boot-HALT model: an error screen is shown, the Valley scene is never attached, nothing further is instantiated, and recovery requires fixing the data and restarting the application — NOT "session ends" process-exit wording, and NOT `SceneTree.paused`)* [TR-resource-item-database-006] | Boot halts with an error naming every invalid entry and its source file (fail loudly at boot — never launch with a partially valid database) [TR-resource-item-database-035] |

**Validation-result contract** *(added 2026-07-10 review)*: validation
produces a STRUCTURED result — a list of records, each carrying at least
the entry id, source file, violated check, and offending field where
applicable. The boot path renders/logs this result AND it is returned by
the validation call itself (dependency-injectable, per the project's
unit-testability standard) so headless tests assert on the structure, not
on log strings. [TR-resource-item-database-007] The exact record schema is implementation detail
(data-architecture ADR).

### Interactions with Other Systems

- **Building System** (MVP, downstream, primary consumer): queries
  `building_material` and `furniture_fixture` entries to populate its
  placement palette; reads `tier` to determine the free tier-0 set; reads
  `material_family` + `visual_asset` to render placed blocks. Building
  System owns costs and placement rules; this database owns what exists. [TR-resource-item-database-036]
- **Voxel World** (Foundation sibling, shared vocabulary): Voxel World cells
  store "a block-type identifier and a material identifier" (its Core Rule
  2). **Identifier mapping** *(user decision, 2026-07-10 review — the prior
  "those identifiers are ids defined here" overclaimed against this GDD's
  single id namespace)*: the **block-type identifier IS this database's
  `id`** (e.g. `wood_block`); the **material identifier IS the entry's
  `material_family` value** (`wood`/`stone`/`thatch`/`none`). There is no
  second id namespace. Voxel World treats both as opaque values and never
  queries this database; consumers that need meaning (Building System,
  rendering) resolve them here. No runtime dependency in either direction —
  voxel-world.md's opaque-value contract already defers all meaning to this
  GDD, so no reciprocal patch is required there. [TR-resource-item-database-037]
- **Storage & Inventory** (Alpha, downstream): will read `stackable`,
  `max_stack_size`, `haulable`, `storage_category`. Fields are authored now
  so no schema rework is needed then.
- **Gathering & Production Chains** (Alpha, downstream): recipe inputs and
  outputs will reference ids from this database.
- **Township Progression** (Alpha, downstream): material availability keys
  off `tier` — the ONE gating axis this field serves (Core Rule 3). [TR-resource-item-database-026]
- **Recipe & Blueprint Unlocks** (Alpha, downstream): unlock state
  references item ids plus its own condition list — explicitly NOT `tier`
  *(split from the former combined row at the 2026-07-10 review; see Core
  Rule 3)*. [TR-resource-item-database-026]
- **Scene/World Management** (Foundation sibling, APPROVED — row added at
  the 2026-07-10 review for bidirectional consistency): its Booting state
  gates on this database reaching Ready before Building System / Villager
  AI initialize (its Edge Case "Boot ordering" + AC17a/b), and its
  boot-HALT is the player-facing face of this system's Failed state. [TR-resource-item-database-019]
- **Needs & Mood System** (MVP sibling, shared vocabulary — row added at
  the 2026-07-10 review): its recovery source→rate table (its Core Rule 4)
  is keyed by item ids defined here (`bed`); like Voxel World, a
  vocabulary relationship with no runtime call in either direction.
- **Save/Load & World Persistence** (Vertical Slice, downstream): save files
  store ids only — never definition contents. On load, stored ids are
  resolved against the current database (see Edge Cases for missing ids). [TR-resource-item-database-021]
- **UI systems** (Building UI et al., downstream): read `display_name` and
  `visual_asset` for player-facing presentation.

## Formulas

*(`systems-designer` consulted — mandatory for this high-risk section even in
Lean mode. Verdict: this system owns no formulas.)*

**None.** This system stores authored configuration values (`tier`,
`max_stack_size`, etc.) — it computes nothing from them. A formula transforms
variable inputs into a derived output; this database only returns what was
written at authoring time, unchanged. All math that *consumes* these values —
build costs, stack-overflow handling, tier-gated unlock checks — is owned by
the downstream systems that query this database (Building System, Storage &
Inventory, Recipe & Blueprint Unlocks), consistent with the same verdict
reached for Scene/World Management.

Deliberately NOT formulas (and why):
- **Id lookup** — a native dictionary get-by-key; no tunable variables, no
  designer-authored curve, no output range. Engine mechanics, not game math.
- **Boot validation checks** — boolean pass/fail invariants against static
  schema rules (see States and Transitions), not value computations.
- **Tier → availability mapping** — a gating function needing inputs this
  system doesn't have (player progress, unlocked-tier state); owned by
  Recipe & Blueprint Unlocks / Township Progression per Core Rule 3.

## Edge Cases

1. **Save file references a retired id.** The database resolves any unknown
   id to a reserved built-in `missing_item` definition, which is FULLY
   INERT *(user decision, 2026-07-10 review — the prior spec left 6
   required fields undefined and hardcoded category `building_material`,
   which would desync retired FURNITURE ids against category-sensitive
   consumers)*: category `missing` (the reserved, non-authorable sixth
   category — Core Rule 5), `material_family: none`, `tier: 0`,
   `stackable: false`, `max_stack_size: 1`, `haulable: false`,
   `storage_category: none`, a deliberately conspicuous error visual
   (magenta placeholder material), display name "Missing Item". It is
   excluded from ALL listing queries (Core Rule 8), never appears in any
   palette, and never satisfies category-, family-, tier-, or
   recovery-source lookups — a consumer can only ever meet it by directly
   resolving a stored id. [TR-resource-item-database-033] Player-built structures are preserved
   cell-for-cell — nothing is silently deleted — and each distinct missing
   id is logged once per load event (a session with multiple loads logs
   per load). [TR-resource-item-database-038] (Same approach as Minecraft's missing-texture handling.)
2. **Runtime query for an unknown id.** The lookup API returns an explicit
   not-found result and logs the id; callers that must render *something*
   (world loading, above) resolve to `missing_item`. An unknown id reaching
   the API in normal play is a programming error, not a player-caused state. [TR-resource-item-database-039]
3. **`missing_item` is reserved.** Boot validation rejects any authored
   entry using the id `missing_item` — it can never be overridden by data. [TR-resource-item-database-030]
4. **Duplicate ids across data files.** Boot validation fails (Failed state)
   naming both entries AND both source files *(harmonized with AC3 at the
   2026-07-10 verification pass — the two locations previously asserted
   "entries" vs "files")*. The game never launches with an ambiguous
   database. [TR-resource-item-database-040]
5. **Unknown category or material_family value in an entry.** Boot
   validation fails naming the entry — categories and families are fixed
   enums (Core Rule 5), not free text. [TR-resource-item-database-041]
6. **Retired ids are never reused.** A retired-ids ledger is kept in the
   data set; boot validation rejects any new entry whose id appears in it. [TR-resource-item-database-042]
   This protects old save files from resolving an id to the *wrong* thing —
   worse than resolving to nothing (case 1).
7. **`max_stack_size` authored on a non-stackable entry.** Ignored,
   SILENTLY — no warning *(reclassified at the 2026-07-10 review: since
   Rule 4 makes the field required-present on EVERY entry, a "warning"
   here would fire on every non-stackable entry on every boot, forever —
   guaranteed noise, not an anomaly signal)*. The field is only meaningful
   when `stackable` is true. [TR-resource-item-database-043]
8. **Query for a category with no entries** (e.g. `raw_resource` in MVP).
   Returns an empty list — a valid result, not an error. Consuming systems
   must handle empty palettes. [TR-resource-item-database-044]
9. **Entries with `tier > 0` exist while no unlock system does (MVP).**
   Consuming systems must treat any non-tier-0 entry as unavailable by
   default. The Building System's MVP palette therefore shows exactly the
   tier-0 set plus the MVP furniture list — a tier-3 item authored early
   must never leak into the palette just because it exists in the database. [TR-resource-item-database-045]
10. **`footprint` authored on a non-`furniture_fixture` entry** *(added by
    the 2026-07-23 slice revision)*. Boot validation fails naming the
    entry — the field applies only to placed multi-cell furniture (Core
    Rule 10); building materials are implicitly `(1,1)` voxel blocks and
    never carry it. [TR-resource-item-database-053]
11. **A `furniture_fixture` entry omits `footprint`, or authors a
    non-positive dimension** *(added by the 2026-07-23 slice revision)*.
    Boot validation fails naming the entry and the invalid dimension —
    unlike the Alpha-deferred fields in Rule 4, `footprint` is consumed
    immediately at MVP by placement and ghost preview, so it cannot be
    silently defaulted. [TR-resource-item-database-054]

## Dependencies

### Upstream (systems this one depends on)

**None.** This is a Foundation-layer leaf: it reads its own authored data
files at boot and depends on no other game system. [TR-resource-item-database-046] Boot sequencing — the
database must reach Ready before dependent systems initialize — is a
DESIGN-level requirement OWNED BY Scene/World Management (its Booting
state, Edge Case "Boot ordering", and AC17a/b make it a formal,
MVP-blocking boot gate with a terminal HALT on failure); only the
*mechanism* is deferred to the boot-order ADR *(reworded at the 2026-07-10
review — the prior "not a design dependency" dismissal contradicted the
since-approved scene-world-management.md)*. [TR-resource-item-database-019]

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Building System | MVP | **Approved** — contract CONFIRMED (its Upstream table + Core Rules 8–9, F5) *(status refreshed 2026-07-10 review; was "Next in design order")* | Palette contents (`building_material`, `furniture_fixture`), `tier` for the free set, `material_family` + `visual_asset` for rendering. *(Slice revision 2026-07-23)*: `footprint` for multi-cell furniture placement (Core Rule 10) — a contract amendment Building System's own placement-rule GDD revision must confirm |
| Scene/World Management | MVP | **Approved** — *(row added 2026-07-10 review, bidirectional)* | Gates its Booting state on this DB reaching Ready; its boot-HALT presents this system's Failed state (its Edge Case "Boot ordering" + AC17a/b) |
| Voxel World | MVP | **Approved** | *Shared vocabulary only, not a runtime dependency*: block-type identifier = this DB's `id`, material identifier = `material_family` (see Interactions — mapping pinned 2026-07-10), treated opaquely |
| Needs & Mood System | MVP | Designed — *(row added 2026-07-10 review)* | *Shared vocabulary only*: recovery source→rate table keyed by item ids (`bed`); no runtime call either direction |
| Building UI | MVP | Designed — contract CONFIRMED (its Rule 5: icon from `visual_asset`, tooltip from `display_name`) *(split from Economy UI + refreshed 2026-07-10)* | `display_name`, `visual_asset` for palette presentation |
| Storage & Inventory | Alpha | Undesigned | `stackable`, `max_stack_size`, `haulable`, `storage_category` *(provisional — fields pre-authored per this GDD's Overview)* |
| Gathering & Production Chains | Alpha | Undesigned | Recipe inputs/outputs reference ids *(provisional)* |
| Township Progression | Alpha | Undesigned | Material availability keys off `tier` — the field's ONE axis (Core Rule 3) *(provisional)* |
| Recipe & Blueprint Unlocks | Alpha | Undesigned | Unlock state references item ids + its own condition list; NOT `tier` *(split 2026-07-10 review; provisional)* |
| Save/Load & World Persistence | Vertical Slice | Undesigned | Saves store ids only; load resolves ids via the lookup API incl. `missing_item` fallback (Edge Case 1) *(provisional)* |
| Economy UI | Alpha | Undesigned | `display_name`, `visual_asset` *(provisional)* |

All "provisional" rows describe expected contracts with undesigned systems —
those GDDs must confirm or renegotiate these interfaces when authored.
Rows for designed/approved systems reflect CONFIRMED contracts as of
2026-07-10.

**Per-item resource cost — deferred, schema anticipates it only** *(note
added by the 2026-07-23 slice revision, user decision)*: the vertical
slice shipped with zero resource costs (all tier-0 materials and `bed`
placed free, per Core Rule 6). Per-item build/placement COSTS remain
owned by the Building System (Core Rule 6's "this database owns what
exists," never costs) and are deferred to a future Production-tier
economy revision (Gathering & Production Chains / Economy Balance
(Sinks) — see Open Questions). This is a distinct fact from Open
Question 7's `base_value` (trade/worth). Consistent with the existing
2026-07-10 field-policy decision (do NOT stub speculative schema
fields), this schema does **not** gain a `cost` field yet — adding a
nullable field later is non-breaking, so the slot is earned only when
its owning GDD is authored, not reserved speculatively now.

## Tuning Knobs

This system is itself the game's primary tuning surface: every definition
field is authored external data (Core Rule 2), so "tuning" here means
editing entries, not code. [TR-resource-item-database-002] The knobs below define the safe ranges those
edits must stay within.

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `tier` (per entry) | 0 (bootstrap set) | 0–9 `[assumption]` — scaffold guess, no unlock system exists to derive it from (its own Open Question 3 says so; labels added 2026-07-10 review per the provenance rule) | Availability gating once Township Progression exists (Alpha). Raising a tier-0 material above 0 breaks the MVP bootstrap guarantee (Core Rule 6) — the tier-0 set must always contain at least one entry per material family (BOOT-ENFORCED since the 2026-07-10 review — see the Validating checks) [TR-resource-item-database-031] |
| `max_stack_size` (per entry) | 50 `[assumption]` | 1–999 `[assumption]` | Storage density and hauling trip counts (Alpha). The "values above ~200 risk trivializing storage" guidance is likewise `[assumption]` — no storage system exists to derive it from; revisit when Storage & Inventory is designed |
| `stackable` / `haulable` (per entry) | true | — | Whether Storage & Inventory / Villager AI hauling can interact with the item at all (Alpha) |
| Tier-0 set composition | `wood_block`, `stone_block`, `thatch_block` | ≥ 1 entry per material family | What players can build with for free in the MVP — changing this changes the entire early-game building experience and must stay aligned with the Visual Direction Note's three material families [TR-resource-item-database-031] |
| `footprint` (per `furniture_fixture` entry) *(added 2026-07-23)* | `bed` = `(1, 2)` (slice-validated, user-locked) | both dims 1–4 `[assumption]` | Placement footprint size (ghost preview, on-grid collision — Building System's rules); larger footprints tighten valid placement spots in small rooms |

Not tuning knobs (and why): `id` (immutable contract — see Edge Case 6),
`category` / `material_family` enums (schema changes, design decisions per
Core Rule 5), `display_name` / `visual_asset` (content, not balance).

## Visual/Audio Requirements

The database has no visuals of its own, but it is the binding point where
art assets attach to game data (`visual_asset`, Core Rule 4):

- Every authored entry must reference a valid visual asset — boot validation
  treats a missing reference as a failure. [TR-resource-item-database-023]
- The three tier-0 materials must visually match the Visual Direction Note's
  material↔meaning language: wood = warm brown, stone = cool grey,
  thatch = warm red-brown.
- **New asset required**: the `missing_item` placeholder needs a deliberately
  conspicuous error material (magenta, per Edge Case 1) — an actual asset to
  produce, not just a convention.
- Audio: none in MVP. If per-material sounds are wanted later (placement
  thunk per family), that becomes an additional schema field — see Open
  Questions.

## Game Feel

Not applicable — pure infrastructure with no player-facing interaction,
motion, or timing. Feel obligations live in the consuming systems (e.g. the
Building System's placement feedback). The database's only "feel" contribution
is indirect: distinct material identity (Player Fantasy section).

## UI Requirements

None owned by this system — it renders nothing. It supplies the fields UI
systems present: `display_name` (must be built localization-ready, even
though MVP ships English-only) and `visual_asset` (palette icons/previews
are derived from it by Building UI). [TR-resource-item-database-047] Any UI for browsing the database
(debug item browser) is a development tool, not a player-facing requirement.

## Cross-References

- `design/gdd/game-concept.md` — Pillars 1 (building materials) and 2
  (settlement economy) that this Foundation system serves
- `design/art/visual-direction-note.md` — material families (wood/stone/
  thatch) and the material↔meaning color language the tier-0 set implements
- `design/gdd/systems-index.md` — Building ↔ Township Progression circular
  dependency resolution that Core Rule 6 (tier-0 set) implements
- `design/gdd/voxel-world.md` — Core Rule 2 (cells store this database's
  `id` as the block-type identifier and `material_family` as the material
  identifier — mapping pinned at the 2026-07-10 review; shared vocabulary,
  no runtime dependency)
- `design/gdd/building-system.md` — primary consumer; contract confirmed
  in its Upstream table (Core Rules 8–9, F5) *(added 2026-07-10 review)*
- `design/gdd/needs-mood-system.md` — recovery source→rate table keyed by
  item ids from this database *(added 2026-07-10 review)*
- `design/gdd/scene-world-management.md` — Booting gate on DB-Ready +
  terminal boot-HALT (its Edge Case "Boot ordering", AC17a/b) *(added
  2026-07-10 review)*
- `.claude/docs/coding-standards.md` — "gameplay values must be data-driven"
  standard that Core Rule 2 implements
- `design/registry/entities.yaml` — registry entries for `wood_block`,
  `stone_block`, `thatch_block` (registered at this GDD's completion)

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. First authoring: 2 rewrites and 6 missing criteria incorporated.
2026-07-10 full review: test-type + scope tags added to ALL ACs
(Foundation-sibling parity), AC3 wording harmonized with Edge Case 4,
AC9 split, AC17/19/21/22 reworked, AC23–29 added. Boot-validation ACs
assert on the STRUCTURED validation result (see the contract under States
and Transitions), never on log strings.)*

1. **GIVEN** valid data files, **WHEN** the game boots, **THEN** the database reaches Ready and every authored entry is queryable by id. *[Logic, MVP]* [TR-resource-item-database-025]
2. **GIVEN** any authored entry, **WHEN** queried by id, **THEN** every returned field matches the authored data exactly — the test fixture must populate ALL eleven schema fields (raised from ten by the 2026-07-23 slice revision's `footprint` field), including the four Alpha-deferred ones, so a partial-field comparison cannot silently pass. *[Logic, MVP]* [TR-resource-item-database-027]
3. **GIVEN** two entries with the same id, **WHEN** the game boots, **THEN** boot halts in Failed state with an error naming both entries AND both source files *(harmonized 2026-07-10 with Edge Case 4 — the two locations previously asserted "entries" vs "files")*. *[Logic, MVP]* [TR-resource-item-database-040]
4. **GIVEN** an entry with an unknown category (4a) or an unknown material_family value (4b), **WHEN** the game boots, **THEN** boot halts naming the entry — both sub-cases independently tested. *[Logic, MVP]* [TR-resource-item-database-041]
5. **GIVEN** an entry missing a required field, **WHEN** the game boots, **THEN** boot halts naming the entry and the field — tested at least twice: once for an always-consumed field (5a, e.g. `display_name`) and once for an Alpha-deferred required-present field (5b, e.g. `storage_category`), so presence-validation of deferred fields cannot silently be skipped. *[Logic, MVP]* [TR-resource-item-database-028]
6. **GIVEN** an entry whose id is not valid snake_case (uppercase 6a, spaces 6b, hyphens 6c), **WHEN** the game boots, **THEN** boot halts naming the entry — each sub-case independently tested. *[Logic, MVP]* [TR-resource-item-database-024]
7. **GIVEN** a data set with THREE independent invalid entries of three different violation classes (e.g. missing field + unknown category + duplicate id), **WHEN** the game boots, **THEN** boot halts and the error names ALL invalid entries, not just the first encountered *(raised from a 2-entry pair at the 2026-07-10 review — "every invalid entry" is unproven at N=2)*. *[Logic, MVP]* [TR-resource-item-database-035]
8. **GIVEN** a runtime query for an id not in the database, **WHEN** the lookup API is called, **THEN** it returns an explicit not-found result, logs the id, and does not crash. *[Logic, MVP]* [TR-resource-item-database-039]
9. Retired-id fallback *(split at the 2026-07-10 review — the prior AC conflated this system's logic with VS-tier Save/Load behavior)*:
   a. **GIVEN** a stored id that is not in the current database, **WHEN** it is resolved via the fallback path, **THEN** it resolves to the fully inert `missing_item` (magenta visual, category `missing`, all fields per Edge Case 1). *[Logic, MVP]* [TR-resource-item-database-038]
   b. **GIVEN** a save file containing retired ids, **WHEN** the save loads, **THEN** all cells are preserved and each distinct missing id is logged exactly once per load event (a second load in the same session logs its own set). *[Integration, VS+ — DEFERRED pending the Save/Load & World Persistence GDD]* [TR-resource-item-database-038]
10. **GIVEN** an authored entry with id `missing_item` (10a) or category `missing` (10b), **WHEN** the game boots, **THEN** boot halts (reserved id / reserved category). *[Logic, MVP]* [TR-resource-item-database-030]
11. **GIVEN** a new entry whose id appears in the retired-ids ledger (synthetic fixture ledger — the shipped MVP ledger is empty), **WHEN** the game boots, **THEN** boot halts naming the entry and the ledger conflict. *[Logic, MVP]* [TR-resource-item-database-042]
12. **GIVEN** a category with zero entries (e.g. `raw_resource` in MVP), **WHEN** queried by category, **THEN** an empty list is returned without error. *[Logic, MVP]* [TR-resource-item-database-044]
13. **GIVEN** the MVP data set, **WHEN** querying by category `building_material` (13a) and by `furniture_fixture` (13b), **THEN** each returns exactly its own authored ids with no cross-category leakage in either direction *(symmetric case added 2026-07-10)*. *[Config/Data, MVP — content smoke check against shipped data; the query logic itself is covered by AC12/AC15 fixture tests]* [TR-resource-item-database-032]
14. **GIVEN** the MVP data set, **WHEN** querying all tier-0 building materials, **THEN** exactly `wood_block`, `stone_block`, `thatch_block` are returned. *[Config/Data, MVP]* [TR-resource-item-database-031]
15. **GIVEN** entries of multiple material families, **WHEN** queried by one family, **THEN** all and only entries of that family are returned. *[Logic, MVP]* [TR-resource-item-database-032]
16. **GIVEN** the MVP data set, **WHEN** "list all ids" is called, **THEN** every authored entry's id is present exactly once and no unauthored id appears (`missing_item` never appears — it is not authored). *[Config/Data, MVP]* [TR-resource-item-database-032]
17. **GIVEN** the database is in any non-Ready state (Unloaded, Validating, or Failed), **WHEN** any lookup API is called, **THEN** the call returns an explicit error result per the validation-result contract — never data, never a partial read *(reworded 2026-07-10: "fails/errors" was ambiguous)*. *[Logic, MVP]* [TR-resource-item-database-034]
18. **GIVEN** a definition queried at boot, **WHEN** the same id is queried again after intervening queries for other ids, **THEN** the returned values equal the boot-time values — this guards internal cache integrity against unrelated queries, distinct from AC19's external-mutation resistance *(distinction stated 2026-07-10)*. *[Logic, MVP]* [TR-resource-item-database-048]
19. **GIVEN** a definition object returned by a query, **WHEN** the caller attempts to mutate the returned object via any idiomatic property or method (there is no such property or method to use — this is enforced by the returned type's shape, not by a runtime check), **THEN** a subsequent query for the same id returns the original, unmutated authored values (Core Rule 9). *[Logic, MVP — RESOLVED 2026-07-11 via ADR-0006: `get_by_id()` returns a getter-only `ItemDefinition` wrapper (no setters exist) around the shared internal `ItemDefinitionResource`; the guarantee covers accidental/idiomatic mutation, not deliberate `Object.get()`/`set()` reflection bypass — see ADR-0006 Risks]* [TR-resource-item-database-010]
20. **GIVEN** a stackable entry with `max_stack_size < 1`, **WHEN** the game boots, **THEN** boot halts naming the entry. *[Logic, MVP]* [TR-resource-item-database-049]
21. **GIVEN** a non-stackable entry with `max_stack_size` authored, **WHEN** the game boots, **THEN** boot succeeds SILENTLY — no warning is emitted *(reworked 2026-07-10 with Edge Case 7: the field is required-present on every entry, so a warning would be guaranteed noise)*. *[Logic, MVP]* [TR-resource-item-database-043]
22. **GIVEN** an entry whose `visual_asset` reference does not resolve to an existing asset, **WHEN** the game boots, **THEN** boot halts naming the entry — distinguishing two failure shapes: (a) the entry's backing `.tres` itself fails to load entirely (a missing/broken `[ext_resource]`), reported as "entry failed to load"; (b) the `.tres` loads but its `visual_asset` field is null, reported as "visual_asset unresolved". *[Config/Data, MVP — RESOLVED 2026-07-11 via ADR-0006 (Open Question 5): `visual_asset` is a typed `Mesh` reference (`@export var visual_asset: Mesh`), not a path string; RID's boot pipeline must check the entry resource itself loaded successfully before checking the field]* [TR-resource-item-database-023]

**Added at the 2026-07-10 review:**
23. **GIVEN** an entry with a negative or non-integer `tier`, **WHEN** the game boots, **THEN** boot halts naming the entry (the Rule 4 `int ≥ 0` declaration, now enforced). *[Logic, MVP]* [TR-resource-item-database-050]
24. **GIVEN** a `building_material` entry with `material_family: none` (24a), or a non-building-material entry with a material family set (24b), **WHEN** the game boots, **THEN** boot halts naming the entry (category↔family pairing, now enforced). *[Logic, MVP]* [TR-resource-item-database-051]
25. **GIVEN** a data set whose tier-0 `building_material` entries do not cover every material family (e.g. wood and stone but no thatch), **WHEN** the game boots, **THEN** boot halts naming the uncovered family (the Core Rule 6 invariant, now boot-enforced). *[Logic, MVP]* [TR-resource-item-database-031]
26. **GIVEN** validation fails, **WHEN** the Failed state is inspected, **THEN** the database exposes the structured validation result (entry id, source file, violated check per record), remains permanently non-Ready for the session, and never partially answers queries — the player-facing HALT presentation is Scene/World Management's AC17b. *[Logic, MVP]* [TR-resource-item-database-006] [TR-resource-item-database-007]
27. **GIVEN** the database is Ready, **WHEN** any listing query runs (by category `missing`, by family, by tier, list-all), **THEN** `missing_item` never appears in any result. *[Logic, MVP]* [TR-resource-item-database-033]
28. **GIVEN** the database is Ready, **WHEN** a second load/initialize call is made mid-session, **THEN** it is rejected (error result) and the Ready contents are unchanged (Core Rule 2 "loads once", now tested). *[Logic, MVP]* [TR-resource-item-database-025]
29. **GIVEN** the tier-0 palette in the Building UI, **WHEN** a first-time playtester views the material picker, **THEN** each of the three materials is identifiable without reading its tooltip — screenshot + lead sign-off, per the Visual Direction Note's material↔meaning language. *[Visual/Feel, Advisory, MVP — the one AC tracing to this GDD's Player Fantasy obligation]*

**Added by the 2026-07-23 slice revision (multi-cell furniture footprint)**
30. **GIVEN** a `furniture_fixture` entry with a valid `footprint` (both dimensions ≥ 1), **WHEN** the game boots, **THEN** it is accepted and `footprint` is queryable exactly as authored. *[Logic, MVP]* [TR-resource-item-database-052]
31. **GIVEN** a `furniture_fixture` entry missing `footprint` (31a) or with a non-positive dimension (31b), **WHEN** the game boots, **THEN** boot halts naming the entry and the violated dimension — both sub-cases independently tested. *[Logic, MVP]* [TR-resource-item-database-054]
32. **GIVEN** a non-`furniture_fixture` entry (e.g. `building_material`) with an authored `footprint` field, **WHEN** the game boots, **THEN** boot halts naming the entry (category↔footprint pairing). *[Logic, MVP]* [TR-resource-item-database-053]
33. **GIVEN** the MVP `bed` entry, **WHEN** queried by id, **THEN** `footprint` returns exactly `(1, 2)` — the slice-validated, user-locked bed footprint. *[Config/Data, MVP]* [TR-resource-item-database-052]

## Open Questions

1. **MVP furniture list** — which furniture/door/window entries exist in MVP
   is owned by the Building System GDD (Core Rule 7). → *Building System GDD*
   **RESOLVED 2026-07-09**: the MVP `furniture_fixture` list is exactly
   `bed` (building-system.md Core Rule 8, per the concept's "1 room + 1 bed
   + 1 villager" MVP). Doors/windows and the ~6 furniture types arrive at
   Vertical Slice.
2. **Provisional `storage_category` enum values** — the field is
   required-present in MVP but its real value set belongs to Storage &
   Inventory (Alpha). MVP needs a provisional enum (e.g. `materials`,
   `furniture`) that Storage & Inventory may later extend — extend, not
   rename, or MVP data files break. → *Storage & Inventory GDD*
3. **Does tier granularity (0–9) match Township Progression's unlock
   structure?** The `tier` int is a scaffold guess; the unlock GDD may want
   named stages instead of numbers. Validate before Alpha data is authored
   at scale. *(Narrowed at the 2026-07-10 review: the AXIS question is
   resolved — tier serves Township only, Core Rule 3; only the granularity
   question remains.)* → *Township Progression GDD*
4. **Per-material placement audio** — if each material family gets its own
   placement sound (wood thunk vs stone clack), that's a new schema field.
   Decide when Building System's feel work lands. → *audio-director /
   Building System GDD*
5. **Data file format and organization** (one resource file per entry vs.
   consolidated tables; hot-reload in editor) — implementation, not design.
   → **RESOLVED 2026-07-11 via ADR-0006**: one `.tres` `ItemDefinitionResource`
   file per entry (matches ADR-0002's config-data idiom), `visual_asset` as
   a typed `Mesh` reference (not a path string). Hot-reload-in-editor
   behavior was not separately assessed — carries forward as an
   implementation detail, not a blocking gap.
6. **Localization pipeline for `display_name`** — MVP ships English-only but
   localization-ready (UI Requirements). The actual string-extraction
   workflow is unowned. → *localization-lead, pre-Alpha*

**Added at the 2026-07-10 review (field policy — user decision: OQ-track,
do NOT stub; adding nullable fields later is non-breaking, so schema slots
are earned by a designed consumer, not reserved speculatively):**

7. **`base_value` / item worth** — Trade System (Alpha) needs item worth,
   and the systems-index high-risk table defines Township prosperity as a
   function of "build value", implying per-item value. Schema slot earned
   when either GDD is authored. → *Township Progression / Trade GDD*
8. **`weight`/bulk** — hauling-capacity math (trip counts) needs either a
   per-item weight or an explicit slot-only capacity model. → *Storage &
   Inventory / hauling design in the Villager AI Alpha revision*
9. **Furniture `footprint`/size** — building-system.md F5 currently
   hardcodes `furniture_cell_count = 1` for all MVP furniture; multi-cell
   furniture (tables, wardrobes — the ~6 VS types) will need a schema field
   or an explicit Building-System-owned table. → *Building System VS
   revision* **RESOLVED 2026-07-23 (slice revision, user-locked)**: this
   GDD gains a `footprint` field (Core Rule 10) — `width_cells` ×
   `depth_cells`, both ≥ 1, required for `furniture_fixture` entries.
   `bed` = `(1, 2)`, slice-validated (2-cell-tall villagers need a 2-cell
   bed). Building System's F5 `furniture_cell_count = 1` hardcode is now
   stale for multi-cell entries and must be reconciled against this
   field in its own VS revision — this GDD only states the fact of the
   span, not how placement/collision consumes it.
10. **`description`/flavor text** — the one identity field this GDD's own
    Player Fantasy obligation ("materials feel distinct") implies but the
    schema lacks; MVP's 3-material palette carries identity via
    display_name + family + visual alone (AC29 tests it), but furniture
    variety and quality tiers will want text. → *this GDD's VS/Alpha
    revision*
11. **Do tier-0 materials stay free forever?** Once Alpha costs attach via
    the blueprint pipeline (building-system.md Open Question 5), a
    permanently free wood/stone/thatch faucet would undercut any gathering
    economy for those materials — but re-costing the bootstrap set changes
    the early game. Neither GDD currently owns this policy call.
    → *Economy Balance (Sinks) / Gathering & Production Chains GDD*
12. **`consumable` content scheduling** — this GDD lists `consumable` as
    Alpha, but needs-mood-system.md schedules the `food` need at Vertical
    Slice (its Open Question 2 defers food-item sourcing to "this GDD's
    Vertical Slice revision"). The one-tier gap is now owned: the VS
    revision of this GDD populates `consumable` alongside the food need.
    → *this GDD's VS revision + Gathering & Production Chains GDD*
13. **Per-item resource cost (build/placement cost)** *(added by the
    2026-07-23 slice revision — user decision)*: the slice shipped with
    zero resource costs (Dependencies note above). This is a DIFFERENT
    fact from OQ7's `base_value` (trade/worth) — it's what an item costs
    to PLACE, not what it's worth to trade. Per the OQ-track field
    policy above (do not stub), this schema does not gain a `cost` field
    yet; it anticipates one structurally. → *Gathering & Production
    Chains / Economy Balance (Sinks) GDD, Production milestone*
