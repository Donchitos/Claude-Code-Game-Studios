# Story 022: Multi block-type terrain generation — the world stops being one material

> **Epic**: Voxel World / Grid Data
> **Status**: Complete (2026-07-27 — 1559/1559 suite green, 0 orphans, parent-verified; a full extent now yields ids [1, 2, 3])
> **Layer**: Foundation (world data) → drives Presentation (the mesher, via `vox-023`)
> **Type**: Logic
> **Estimate**: **1.5 days** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*. Authored at gate G2 of Sprint 12; the sprint anchored 1.5 and authoring did **not** move it — but authoring did surface one blocking design question (§ Open Decision 1) and one storage question with a definite answer (§ Open Decision 2). See **Sizing and the descope ladder**.
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

---

## Context

### The gap this closes, verified by direct source read on 2026-07-27

```gdscript
# src/voxel_world/voxel_world_grid.gd:262
const TERRAIN_BLOCK_TYPE_ID: int = 1
```

That constant is written in exactly two places, and they are the only two places
terrain block data is ever produced:

| Path | Line | What it writes |
|---|---|---|
| `generate_terrain()` — the boot/full-world generator | `voxel_world_grid.gd:637` | `CellContents.new(TERRAIN_BLOCK_TYPE_ID, TERRAIN_MATERIAL_ID)` for every column cell |
| `_bg_regenerate_from_seed()` — the lazy per-chunk page-in regenerator (ADR-0015 §6, off-thread) | `voxel_world_grid.gd:1783` | `block_type_ids[offset] = TERRAIN_BLOCK_TYPE_ID` |

**One id in, one colour out.** No palette work — none — can produce a single pixel of
visual variation in the terrain until the world generates more than one block type. This
story is the generator half of that; `vox-023` is the appearance half, and it is vacuous
without this one (colouring a single id differently is not variation).

### Why the two paths are the whole difficulty

`_bg_regenerate_from_seed()`'s own doc comment states the constraint that shapes this
story's design:

> *"Deliberately reads NOTHING from `config` or any other shared instance state — every
> value this needs is captured on the MAIN thread and bound in before dispatch … so two
> calls with the same `terrain_seed` produce byte-identical terrain regardless of which
> thread runs them (TR-voxel-world-039)."*

So the band rule **cannot** be an instance method reading `config`, and it **must not** be
copied into both paths — two copies of a height-band rule is a drift bug waiting for the
first tuning pass. The codebase already solved this exact problem once, for the height
formula itself: `static func _pure_terrain_height(...)` and
`static func _pure_terrain_noise(...)` are pure statics parameterized entirely by
primitives, called by **both** paths. **This story follows that landed precedent and
introduces no new mechanism.**

### The bands are the art bible's, and the ids are the GDD's — this story invents neither

**Art bible §4.3 — Per-Height-Band Terrain Color Mapping (ADR-0014)**, verbatim:

| Band | Elevation (of 32) | Name | Hex | Read |
|---|---|---|---|---|
| 1 | 0–8 | Lowland | `#9CAD6E` | Grass/valley floor — warm-neutral |
| 2 | 8–16 | Midland | `#A98F5E` | Earth/hills — warmer transitional brown |
| 3 | 16–24 | Highland | `#7C818A` | Stone/rock — cooler slate grey |
| 4 | 24–32 | Peak | `#C9D3D8` | Snow/frost — cool pale, blends into the expedition fog |

**GDD Core Rule 8 / TR-voxel-world-051** already fixes the id space these bands must live
in: *"a bounded set of terrain block-type values — terrain bands and sand, informally **the
1..5 value family**, explicitly EXCLUDING water and EXCLUDING trunk/leaves values — may be
fully removed … via a released dig order."* Four bands as ids **1, 2, 3, 4** sit inside that
family by construction, so dig-order eligibility keeps working without a single change to
the dig-order rules. Ids outside 1..5 would silently break it.

**GDD**: `design/gdd/voxel-world.md` (Core Rules 2, 3, 8; Formulas → `procedural_terrain_height`; Tuning Knobs)
**Art**: `design/art/art-bible.md` §4.3 (the bands), §4.1 (the Primary Palette those hexes belong to)
**Requirement**:
- `TR-voxel-world-028` — block-type ids are **opaque** to this system; it stores them and never resolves their meaning. **This story does not change that**: it chooses which opaque id a generated cell carries; it still resolves nothing.
- `TR-voxel-world-029` — terrain cells are populated procedurally within the bounded extent.
- `TR-voxel-world-038` / `-039` — the `procedural_terrain_height` formula; deterministic seeded noise, byte-identical across threads.
- `TR-voxel-world-051` — the dig-order-eligible **1..5 value family**.
- `TR-voxel-world-041` — the ~1–4 B/cell storage budget (`block_type_ids` is a `PackedByteArray`; ids must stay 0–255).

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0014** (chunked rendering & packed chunk storage — the `PackedByteArray` this writes into) — primary; **ADR-0015** (paged region-file residency; §5's *"cheap, deterministic, **versioned** regen — a real constraint on terrain gen"* is the clause this story lands on, and §6's off-thread regen is why the rule must be a pure static) — primary; **ADR-0002** (tuning data is config, never literals) — secondary.

**Engine**: Godot 4.7-stable | **Risk**: **MEDIUM** — no new engine API is expected (this is arithmetic and array writes), but it is the **first change to terrain generation since `vox-006`**, it feeds ADR-0015's on-disk region files, and per the sprint's own risk table it invalidates any test fixture that assumes a single terrain block type.

**Control Manifest Rules (this layer — Voxel World data tier):**
- **Required**: the band rule is expressed **once**, as a pure `static func` parameterized by primitives, called by both `generate_terrain()` and `_bg_regenerate_from_seed()` — the landed `_pure_terrain_height` precedent. Every emitted id stays inside `0–255` (the existing `set_cell`/`bulk_write` byte assertions) **and** inside the 1..5 dig-order family (TR-voxel-world-051). Band boundaries derive from values already carried on `VoxelWorldConfig` (ADR-0002) — never from a literal buried in the generator.
- **Forbidden**: a second copy of the band rule; reading `config` (or any instance state) from the background path (TR-voxel-world-039); resolving what a band id *means* inside Voxel World (TR-voxel-world-028 — this story assigns ids, `vox-023` assigns appearance); an id outside `0–255`; an id outside the 1..5 family; changing the on-disk region-file layout (see Open Decision 2 — a format change is escalated, never invented).
- **Guardrail**: **an acceptance assertion that passes on today's build is not an assertion.** The lever below fails on the pre-story build and its failure must be recorded in the commit body.

---

## ⚑ Open Decision 1 — the band boundaries do not fit the shipped world, and the producer must not invent them

**This is the single thing authoring found that the sprint plan had not priced, and it
blocks the story's own lever from passing.** Stated plainly, from two files read on disk:

`data/config/voxel_world_config.tres` ships `min_y = 0`, `max_y = 16`, `base_height = 4`,
`amplitude = 3.0`. The GDD's own formula is
`h(x,z) = clamp(round(base_height + amplitude * noise2D(...)), min_y, max_y)`, and `noise2D`
returns `[-1, 1]`, so **every terrain column in the shipped game has a top surface between
y = 1 and y = 7.**

The art bible's bands are stated as elevations **"of 32"** — 0–8 / 8–16 / 16–24 / 24–32.
Read as absolute y values against the shipped world, **every cell in the game falls in
band 1 (Lowland)**. Applying §4.3 literally therefore produces exactly one id — the state
this story exists to end — and this story's own anti-vacuity lever would still fail after
the story shipped.

**The four bands and their four hex values are settled design and are not in question.**
What is missing is the *anchor*: what the "of 32" denominator maps onto in a world whose
configured height is 16 and whose terrain occupies 1–7 of it. Three options, with the
consequence of each on the lever stated so the choice is made with its arithmetic visible:

- **(a) Normalise the four bands across the *achievable terrain height range*** —
  `[base_height − amplitude, base_height + amplitude]`, i.e. `[1, 7]` today — in equal
  quarters. **Consequence: all four bands appear in the shipped world**, so the lever's
  target of ≥ 3 distinct ids is met with margin, and the bands stay meaningful at any
  `amplitude`/`base_height` the designer later picks. Cost: "Peak" snow sits at y ≈ 6–7,
  which is a hilltop, not a mountain — the *hue ramp* reads as the art bible intends
  (warm-neutral low → cool-pale high) but the *literal* material story (snow) does not.
- **(b) Normalise across the *configured world extent*** `[min_y, max_y]` = `[0, 16]` in
  equal quarters (0–4 / 4–8 / 8–12 / 12–16) — the closest structural analogue to "of 32".
  **Consequence: only bands 1 and 2 ever appear** at today's tuning. The lever's `≥ 2`
  floor passes; its stated **target of 3 does not**. Highland and Peak become dead ids
  until someone retunes.
- **(c) Change the world to fit the art bible** — raise `max_y` 16 → 32 (inside the GDD's
  own stated safe range of 8–32) and raise `amplitude` so terrain actually reaches the
  upper bands. **Consequence: this is a Tuning-Knob change with real cost** — the per-chunk
  payload is `2 × CHUNK_SIZE² × (max_y − min_y + 1)` bytes, so doubling the height doubles
  every chunk's resident and on-disk footprint, against ADR-0015's residency budget. It is
  also a *design* change to how the valley feels, not a mapping fix.

**Producer recommendation: (a), ratified by the art-director against the user's palette,
with the band boundaries recorded as `VoxelWorldConfig` fields (ADR-0002) rather than
literals — so overturning this is a `.tres` number edit, exactly as `presentation-004`
made the lighting call overturnable.** (a) is the only option that satisfies this story's
own lever at the shipped tuning without also changing world size or terrain feel, and it
degrades gracefully: retune `amplitude` later and the bands follow.

⚑ **This is an art-director + user call, not a producer call. The story is BLOCKED on it
only to the extent of the boundary numbers** — every other AC below is implementable
against whichever anchor is chosen, because the anchor is a config value, not a code shape.
**Record the ruling in this file before `/dev-story`.** If it is not ruled, ship (a) as
provisional with the same explicit "PROVISIONAL — awaiting sign-off" doc comment
`world_lighting_config.gd` uses, and say so in the commit body; do **not** silently pick a
denominator.

---

## ⚑ Open Decision 2 — the region-file question, stated rather than discovered

The sprint's risk table requires this be written down before any code. It was checked
against `src/voxel_world/region_file.gd` and `voxel_world_grid.gd`'s
`_serialize_chunk_buffer`/`_deserialize_chunk_buffer` on 2026-07-27. **The answer is
definite, and it is good news with one sharp edge.**

**Do already-serialized region files stay readable? YES — no format change, no migration.**
The region file is a fixed header of 8-byte slot entries (`RegionFile.HEADER_ENTRY_BYTES`)
plus fixed-length payloads; the payload is `block_type_ids` followed by `material_ids`, two
`PackedByteArray`s whose lengths derive from `CHUNK_SIZE` and `max_y − min_y + 1`. **This
story changes only which byte *values* appear in `block_type_ids`, never the layout, never
the length, never the header.** Every existing file parses exactly as before.

**The sharp edge — content, not format.** `_bg_regenerate_from_seed()` only runs for a chunk
with **no persisted entry**. A region file written by the pre-story generator holds
all-id-1 chunks, and paging one back in returns single-colour terrain **forever**, because
regeneration never re-runs for a persisted chunk. There is **no terrain-generation version
stamp anywhere in the format** — this is precisely the constraint ADR-0015 §5 named in
advance: *"leans on cheap, deterministic, **versioned** regen — a real constraint on terrain
gen."*

Concretely: any developer with a populated `user://regions` will see a mix of new banded
terrain and old flat-lowland terrain, and it will look like a bug in `vox-023`'s
screenshots and in `presentation-004` AC3's re-shoot.

- **(i) Document a `user://regions` clear** as a one-line dev step in this story, the commit
  body, and the sprint's smoke artifact. Zero code. Legitimate for MVP: region files are
  user data, `.gitignore`d (ADR-0015 §4), and MVP ships no save/load feature yet.
- **(ii) Add a terrain-generation version stamp to the region header** so a stale chunk
  regenerates on page-in. ⚑ **This is a region-file FORMAT change and therefore a
  technical-director call. This story must NOT invent it** — the sprint's named lever is
  explicit: *"escalate a format question to TD rather than inventing a migration."*

**Producer recommendation: (i) now, and escalate (ii) to the technical-director as a named
decision for the save/load work**, since ADR-0015 §5's sparse-regen layer will need a
generation version anyway. **If the TD rules that (ii) is required inside this story, this
story escalates and re-scopes rather than authoring a migration.**

---

## Sizing and the descope ladder (pre-declared, per the sprint's named lever)

The sprint's buffer entry names the lever precisely: *"reduce the design scope — ship 2–3
height-banded ids rather than a biome system — **never the data-driven-ness**. A hardcoded
three-colour table is the same defect as a hardcoded one-colour table."*

| Sub-scope | Contents | Anchor | Carries |
|---|---|---|---|
| **A — the shared band rule** | the pure static, called by both paths; ids in the 1..5 family; band boundaries as config fields | 1.0 | **Everything.** Without A there is still exactly one id and `vox-023` is vacuous |
| **B — the fixture sweep** | re-read and fix every test fixture that assumes a single terrain block type | 0.5 | The suite stays honest rather than being loosened to accommodate the change |

**Ladder if a trim is needed** (decide on signal, not by default):
1. **Reduce the band count, never the mechanism** — ship 2 bands (Lowland/Midland) instead
   of 4 if Open Decision 1 stalls. The static, the config fields, and both call sites are
   identical; only the boundary table is shorter. Lever still passes at `≥ 2`.
2. **Never** collapse the rule back into per-path literals, and **never** hardcode the band
   boundaries. That is the same defect in a new coat, and it is the one thing the sprint's
   lever forbids by name.
3. **Never** absorb a region-file format change. Escalate (Open Decision 2).

---

## Acceptance Criteria

- [x] **AC-ONE-RULE-TWO-PATHS** ⚑ *the story's structural requirement*: the band → id rule
      exists exactly **once**, as a `static func` on `VoxelWorldGrid` parameterized entirely
      by primitives (the landed `_pure_terrain_height` / `_pure_terrain_noise` precedent),
      and **both** `generate_terrain()` and `_bg_regenerate_from_seed()` call it. Grep-guarded
      by test: `TERRAIN_BLOCK_TYPE_ID` no longer appears as the written value in either
      write path, and no second implementation of the boundary comparison exists anywhere in
      `src/voxel_world/`. [ADR-0015 §6, TR-voxel-world-039]
- [x] **AC-BACKGROUND-PATH-READS-NO-INSTANCE-STATE**: `_bg_regenerate_from_seed()` still reads
      **nothing** from `config` or any other shared instance state — every value the band
      rule needs is captured on the main thread in `_try_dispatch_read()` and bound into the
      task before dispatch, exactly as `base_height`/`amplitude`/`frequency`/`min_y`/`max_y`
      already are. Determinism is unchanged: two runs with the same `terrain_seed` produce
      **byte-identical** chunk payloads. [TR-voxel-world-039, ADR-0015 §6]
- [x] **AC-BOTH-PATHS-AGREE** ⚑ *the drift guard, and the reason the rule is expressed once*:
      for the same chunk key and the same seed, the chunk produced by `generate_terrain()`
      and the chunk produced by `_bg_regenerate_from_seed()` are **byte-identical in
      `block_type_ids`**, not merely "both banded". This assertion is what makes a future
      one-sided edit fail loudly instead of silently splitting the world into two terrains.
- [x] **AC-IDS-ARE-IN-RANGE-AND-DIG-ELIGIBLE**: every emitted terrain id is inside `0–255`
      (the existing `set_cell`/`bulk_write` packed-byte assertions still hold, unmodified and
      unweakened) **and** inside the **1..5 value family** GDD Core Rule 8 /
      TR-voxel-world-051 reserves for terrain bands and sand — so dig-order eligibility keeps
      working with **zero** change to the dig-order rules. Asserted against the id set the
      band rule can produce, not against a literal list. [TR-voxel-world-051, TR-voxel-world-041]
- [x] **AC-ID-1-STAYS-LOWLAND** ⚑ *a compatibility constraint read off disk, not a taste
      call*: the lowest band keeps id **1**. Two reasons, both verified: (a) every
      already-serialized region file holds id-1 chunks, and (b) `blueprint_cell.gd:183`
      defaults every **built** cell to `CellContents.new(1, 0)`, so renumbering id 1 would
      silently change the colour of every wall and floor the player has ever built.
      Renumbering is out of scope; new bands take ids **above** 1. (The built-cell id
      collision itself is recorded in **Out of Scope** and escalated, not fixed here.)
- [x] **AC-BAND-BOUNDARIES-ARE-CONFIG-NOT-LITERALS**: the band boundaries live on
      `VoxelWorldConfig` as typed `@export` fields with GDD-defaulted values and a
      `validate()` rule (monotonically increasing, inside `[min_y, max_y]`, count matching
      the id set — a mismatch is a **BLOCKING** issue per ADR-0002's two-tier policy, not a
      silent clamp). Changing where a band starts is a `.tres` number edit and nothing else.
      **No band boundary appears as a literal in `voxel_world_grid.gd`.** [ADR-0002,
      CONTRACTS.md §2]
- [x] **AC-BAND-ANCHOR-RULING-RECORDED**: the anchor chosen in **Open Decision 1** is written
      into this file and into the config class's doc comment, with its rationale. If it ships
      unratified, it carries the same explicit `PROVISIONAL — awaiting art-director sign-off`
      marker `world_lighting_config.gd` uses, and the commit body says so. ⚑ **A silently
      chosen denominator is a producer-invented palette by another name.**
- [x] **AC-REGION-FILES-STAY-READABLE**: a region file written by the **pre-story** build is
      still read back without error by the post-story build, with its `block_type_ids`
      preserved exactly — proving the on-disk layout did not change. The **stale-content**
      consequence (a persisted pre-story chunk pages back in as single-colour, because
      regeneration never re-runs for a persisted chunk, and there is no generation version
      stamp) is **stated in the commit body and in the sprint smoke artifact**, together with
      the `user://regions` clear step. **No format change and no migration are authored here**
      (Open Decision 2). [ADR-0015 §2/§4/§5]
- [x] **AC-NO-MEANING-RESOLVED-HERE**: `VoxelWorldGrid` still resolves **nothing** about what
      a block-type id means — no colour, no material name, no RID lookup enters this file.
      Appearance is `vox-023`'s, and the seam between them is the opaque integer.
      [TR-voxel-world-028]
- [x] **AC-FIXTURE-SWEEP-IS-EXPLICIT** ⚑ *the sprint's own named trap*: every existing test
      fixture that assumed a single terrain block type is **found, listed by name in the
      commit body, and corrected** — not loosened. A fixture that asserted `block_type_id == 1`
      because that was the only id becomes an assertion about the band rule's actual output;
      it does not become `is_greater(0)`. Any fixture that must change is named individually
      with the reason.
- [x] **AC-SUITE-GREEN-AND-DIAGNOSED**: the full blocking suite is green headless, 0 orphans,
      exit 0, both checked explicitly. A red run is re-run **in isolation** before any change
      is reverted on its basis (S10 §5), and never concurrently with a second suite — CPU
      starvation makes the reachability corpus breach its 60 s ceiling and that is a load
      artifact which must never be "fixed".

---

## ⚑ Anti-Vacuity Lever

**Carried verbatim in substance from `sprint-12.md`'s Must table. It FAILS on today's
build, and its failure must be observed and recorded in the commit body** — the
`scene-006` / `scene-007` deletion-probe discipline.

> **Generate a chunk column spanning the full height range and assert at least 2 distinct
> non-empty `block_type_id` values are present. Target ≥ 3.**

Why it cannot pass vacuously: `TERRAIN_BLOCK_TYPE_ID = 1` is the only id written anywhere in
the repo today, so the assertion returns exactly **1** distinct non-empty id on the
pre-story build and fails. **Record the observed failure — test name, the observed distinct
count of 1, exit code — in the commit body.**

**Two hardenings this story adds, because a naive fix would pass the lever while leaving the
defect in place:**

1. **The lever runs against BOTH paths.** Once via `generate_terrain()`, once via a chunk
   produced by the lazy page-in regenerator. Fixing only `generate_terrain()` leaves every
   streamed-in chunk single-coloured — which is most of the world, most of the time, under
   ADR-0015 residency. A one-path fix must fail the lever.
2. **The distinct-id count is compared against the band rule's own declared id set**, not
   against a literal `2`. If the ratified anchor produces 4 bands, the lever expects the
   bands that the configured world can actually reach — computed from the config, never
   pasted in. A lever whose expected value is a literal drifts the moment `amplitude`
   changes.

⚑ **Explicitly banned vacuous shapes here**: asserting the static function exists; asserting
`block_type_id != 0` (empty is already excluded by the premise); asserting on a
hand-constructed `PackedByteArray` rather than on real generator output; and any assertion
whose expected value does not change when the band rule is reverted to
`TERRAIN_BLOCK_TYPE_ID`.

---

## Out of Scope

*Handled elsewhere, or surfaced as missing — do not implement here:*

- **Block appearance of any kind.** No colour, no material, no atlas. `vox-023` owns the
  appearance table and this story's only contract with it is the opaque id
  (TR-voxel-world-028).
- **⚑ Built cells share the Lowland band's id — recorded, escalated, NOT fixed here.**
  `blueprint_cell.gd:183` writes `CellContents.new(1, 0)` for every built cell, so after
  this story a built wall renders in the **Lowland band's olive**, indistinguishable from
  the valley floor, while art bible §4.1 gives built structures their own Material family
  (Timber Brown `#8B5E3C`, Hearth-stone Grey `#8A8D8F`, Thatch Umber `#A8642F`). Giving
  built cells their own ids is a **Building System** change plus an art-director mapping,
  and it is a separate story. ⚑ **It will be visible in `presentation-004` AC3's re-shoot
  and in `vox-023`'s captures — name it in the sign-off rather than letting it read as a
  bug in this story.**
- **A biome system.** Art bible §4.4's three launch biomes (Home Valley / Expedition
  Highlands / Deep Threshold) are horizontal-temperature rules, not height bands. The
  sprint's named lever forbids growing this story into one.
- **Any region-file format change or migration** — Open Decision 2, escalated to the
  technical-director.
- **Any retune of `max_y`, `amplitude`, `base_height` or `frequency`.** These are GDD Tuning
  Knobs owned by design; Open Decision 1 option (c) names the possibility and hands it back.
- **Water, trunk and leaves values.** Explicitly outside the 1..5 family
  (TR-voxel-world-051) and outside this story.
- **The mesher's shared material, winding, or culling** (ADR-0014 §2, TR-voxel-world-052) —
  untouched.

---

## QA Test Cases

- **AC-ONE-RULE-TWO-PATHS**: Given the source tree, When `src/voxel_world/` is scanned for
  the band-boundary comparison, Then exactly one implementation is found and it is a
  `static func`; When both write paths are scanned, Then neither writes
  `TERRAIN_BLOCK_TYPE_ID` as a cell value.
- **AC-BACKGROUND-PATH-READS-NO-INSTANCE-STATE**: Given the same `terrain_seed`, When
  `_bg_regenerate_from_seed()` runs twice for the same chunk key, Then the two payloads are
  byte-identical. Given the source, When `_bg_regenerate_from_seed`'s body is scanned, Then
  it references no `config` member and no instance field.
- **AC-BOTH-PATHS-AGREE**: Given one chunk key and one seed, When the chunk is produced once
  by `generate_terrain()` and once by the lazy regenerator, Then the two `block_type_ids`
  arrays are byte-identical. **Negative control:** revert the band rule in one path only —
  this test FAILS.
- **AC-IDS-ARE-IN-RANGE-AND-DIG-ELIGIBLE**: Given a generated column spanning the full
  configured height range, Then every non-empty id is within `0–255` and within `1..5`.
- **AC-ID-1-STAYS-LOWLAND**: Given a column at the valley floor, Then its lowest band cells
  carry id `1`.
- **AC-BAND-BOUNDARIES-ARE-CONFIG-NOT-LITERALS**: Given a `.tres` whose band boundaries are
  edited, When terrain is generated, Then the band assignment changes accordingly with no
  code edit. Given a config with non-monotonic boundaries, When `validate()` runs, Then a
  `BLOCKING:`-prefixed issue is returned and boot halts via the existing terminal path
  (never a new one).
- **AC-REGION-FILES-STAY-READABLE**: Given a region file produced by the pre-story build,
  When the post-story build pages that region in, Then the read succeeds and the persisted
  `block_type_ids` are returned unchanged.
- **AC-NO-MEANING-RESOLVED-HERE**: Given `src/voxel_world/voxel_world_grid.gd`, When scanned
  for `Color`, material names, or `ResourceItemDatabase` references, Then none are found.
- **AC-FIXTURE-SWEEP-IS-EXPLICIT**: Given the full suite, Then every fixture that changed is
  named in the commit body with its reason, and none was relaxed to an inequality.
- **AC-SUITE-GREEN-AND-DIAGNOSED**: Given `tests/run-tests.cmd`, Then exit code 0 with 0
  errors, 0 failures, 0 orphans.

---

## Test Evidence

**Story Type**: Logic (**BLOCKING** — automated unit test required, `coding-standards.md`
Test Evidence table)

**Required evidence**:

- `neues-spiel/tests/unit/voxel_world/multi_block_type_terrain_generation_test.gd` — a **new**
  file, carrying:
  - ⚑ **THE ANTI-VACUITY LEVER, in this file, as its own named test**: *generate a chunk
    column spanning the full height range and assert **at least 2 distinct non-empty
    `block_type_id` values** are present (target ≥ 3)* — run **twice**, once against
    `generate_terrain()` output and once against lazy-page-in regenerator output, with the
    expected distinct-id set **computed from the band config**, never a literal. On the
    pre-story build this returns 1 distinct id and fails.
  - The both-paths byte-identity assertion (AC-BOTH-PATHS-AGREE).
  - The id-range and 1..5-family assertions (AC-IDS-ARE-IN-RANGE-AND-DIG-ELIGIBLE).
  - Determinism: same seed → byte-identical payload, twice (AC-BACKGROUND-PATH-…).
- Grep-guard test for AC-ONE-RULE-TWO-PATHS and AC-NO-MEANING-RESOLVED-HERE, on the
  established non-writer/literal-guard precedent (`building-023`, `build-validation-002`,
  and `shelter_recovery_live_pair_test.gd`'s `_find_files_assigning` helper — reuse it, it
  already generalises).
- `neues-spiel/tests/unit/voxel_world/` config validation coverage for the new band-boundary
  fields, including the BLOCKING non-monotonic case.
- A round-trip test for AC-REGION-FILES-STAY-READABLE against a pre-story-shaped payload.
- **The observed pre-story lever failure, recorded in the commit body** — not a separate
  artifact. `scene-006`'s entry is the format to copy: name the test, quote the observed
  output (distinct-id count, failure line, statistics line, exit code), then confirm the
  post-story re-run is green.
- **The named fixture sweep**, in the commit body: every fixture that assumed one terrain
  block type, listed with its correction.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete): `vox-002` (chunked cell storage & accessors — the
  `PackedByteArray` this writes), `vox-006` (procedural terrain generation — the path this
  changes), `vox-010` (region-file paged residency — the disk tier Open Decision 2 answers
  against), `vox-011` (the off-thread regenerator and the `_pure_*` static precedent this
  follows).
- **Blocked on**: **nothing mechanically** — day one on lane T. ⚑ **Blocked in substance on
  Open Decision 1's band anchor** (art-director + user). The code shape is implementable
  either way; the numbers are not the producer's to choose.
- **Unlocks**:
  - **`vox-023` (in-sprint, HARD).** Colouring one id differently is vacuous; this story is
    what makes an appearance table mean anything.
  - **`presentation-004` AC3.** The lighting sign-off is sequenced strictly after this story
    and `vox-023` — the shipped 0.95 / 0.28 exists to compensate for a one-colour world, so
    signing it off against that world would ratify the workaround.
  - **The user's palette lane.** This is the surface the project's palette owner has been
    unable to paint.
- **Open decisions this story surfaces (producer → user / art-director / technical-director)**:
  1. **The band anchor** (art-director + user) — § Open Decision 1. *Recommendation: (a),
     boundaries as config fields.* **We will know this was right if** a terrain colour change
     is a `.tres` edit and the shipped world visibly shows at least three bands.
  2. **The region-file generation version stamp** (technical-director) — § Open Decision 2.
     *Recommendation: (i) now, escalate (ii) for save/load.* **We will know this was right
     if** no capture in this sprint shows mixed stale/fresh terrain without it being named.
  3. **Built cells share the Lowland band id** (building-system + art-director) — see
     **Out of Scope**. Recorded, not absorbed.

---

## Notes

- Cross-reference `docs/engine-reference/godot/` before touching any engine API
  (**BLOCKING**, as in M01 and S09–S11). This story is expected to use **no** new engine
  API — it is integer arithmetic and `PackedByteArray` writes — and any that appears must be
  verified against the reference before use.
- ⚑ **Tree hygiene**: the user's asset/palette lane (`design/art/palette.json`,
  `palette-system.md`, the vegetation `.glb` models, `tools/asset-pipeline/`) is actively
  uncommitted. It touches no `.gd` and no `src/`, so it does not poison a suite run — **but
  the palette hand-off for the band hexes must be coordinated explicitly rather than
  discovered.**
- ⚑ **The "world is not empty after boot" trap applies double here**: chunks lazily
  regenerate real terrain the moment residency is requested, so any test building geometry
  against a real booted grid must build above `base_height + amplitude` or probe for clear
  cells — and after this story that terrain is no longer a single block type.
</content>
</invoke>
