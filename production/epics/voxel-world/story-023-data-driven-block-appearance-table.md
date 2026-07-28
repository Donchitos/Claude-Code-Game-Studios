# Story 023: Block appearance becomes DATA — the palette owner can change a colour by editing data and nothing else

> **Epic**: Voxel World / Grid Data
> **Status**: Complete (2026-07-27 — 1577/1577 suite green, 0 orphans, parent-verified; the shipped game renders four distinct terrain colours)
> **Layer**: Presentation (the mesher's appearance tier) → consumes Foundation (`vox-022`'s ids)
> **Type**: Logic
> **Estimate**: **1.0 day** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*. Authored at gate G2 of Sprint 12; the sprint anchored 1.0 and authoring did **not** move it, but authoring did add a **third** lever the sprint had not named (§ Anti-Vacuity Lever 3) — the sprint's own deepest rule applied to this story's exact shape.
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

---

## Context

### The gap this closes, verified by direct source read on 2026-07-27

```gdscript
# src/voxel_world/voxel_world_mesher.gd:146
const DEBUG_BLOCK_COLORS: Dictionary[int, Color] = {
	1: Color("9CAD6E"),  # art-bible SS4.3 Lowland band -- Story 006's only terrain block-type id today
}
const DEBUG_UNKNOWN_COLOR: Color = Color(1.0, 0.0, 1.0)   # everything else renders magenta
```

Consumed once, at `voxel_world_mesher.gd:448`:

```gdscript
var color: Color = DEBUG_BLOCK_COLORS.get(block_type_id, DEBUG_UNKNOWN_COLOR)
```

into `arrays[Mesh.ARRAY_COLOR]`, sampled by the shared `ShaderMaterial` as plain unlit
albedo (class doc comment, line 77–79).

**The project's palette owner cannot change a single terrain colour without a code edit.**
That is the whole defect. `vox-022` gives the world more than one id; this story is what
turns that into a surface the user owns.

### The precedent this follows exactly — `presentation-004`, landed 2026-07-27

`world_lighting_config.gd` / `data/config/world_lighting_config.tres` solved the identical
problem one layer over, and its own class doc comment states the property this story is
buying:

> *"Because this recipe now lives in a config `Resource` (ADR-0002) rather than scattered
> script literals, overturning this provisional call later is a `.tres` NUMBER EDIT, not a
> code change — exactly the property ADR-0002 exists to buy."*

That is the landed precedent, it is one sprint old, and this story copies it rather than
inventing a shape. Same ADR, same `.tres` location, same `validate()` discipline, same
Inspector wiring on `Valley.tscn`, same grep guard.

### ⚑ Why the magenta stays

`DEBUG_UNKNOWN_COLOR` is **retained**, unchanged, as the visible-fail path for an unmapped
id. This project's rule is *visible fail, never silent* — an id with no appearance entry
must render screaming magenta, not a plausible default. A "sensible fallback colour" here
would be the same class of defect the whole sprint exists to hunt: a permissive default
that lets a missing mapping ship unnoticed. Its own name may lose the `DEBUG_` prefix once
it is config-adjacent rather than a debug stub; its **behaviour must not change**, and there
must be a test that proves it is still reachable — an unreachable visible-fail path is dead
code pretending to be a safety net.

**GDD**: `design/gdd/voxel-world.md` (Core Rule 2 — a cell holds a block-type id and a
material id; Visual/Audio Requirements — *"All visible/audible feedback about blocks
(placement, textures, sounds) belongs to the Building System and the rendering ADR"*)
**Art**: `design/art/art-bible.md` §4.3 (the four band hexes this table's shipped values
come from), §4.1 (the Primary Palette they belong to), §8.4 (Palette Discipline)
**Requirement**:
- `TR-voxel-world-023` — Voxel World's tuning values live in a config `Resource` (ADR-0002).
- `TR-voxel-world-028` — block-type ids are opaque **to the data tier**. This story is where
  an id is finally resolved to an appearance, and it resolves it **from data**, in the
  Presentation tier, never inside `VoxelWorldGrid`.
- `TR-voxel-world-052` — CW winding + backface culling **ENABLED**; untouched by this story
  and must survive it.

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0002** (Tuning/Config Data Strategy — the config
`Resource` pattern, `validate()`, the two-tier severity model) — primary; **ADR-0001**
(Inter-System Reference & DI — the config arrives as a typed `@export`, wired on
`Valley.tscn`, read in `setup()` and never in `_ready()`) — primary; **ADR-0014** (Decision
§2 — one shared `ShaderMaterial`, vertex-colour albedo, CW winding, culling enabled) —
secondary, and **unchanged by this story**.

**Engine**: Godot 4.7-stable | **Risk**: **MEDIUM** — the logic is a dictionary lookup moved
from a `const` to a `Resource`, but `.tres` serialisation of a keyed colour table is a
**post-cutoff-change domain** (typed collections and Resource export changed across 4.4–4.7).
See **Open Decision 1** and the BLOCKING engine-reference check.

**Control Manifest Rules (this layer — Presentation / voxel appearance):**
- **Required**: one custom `Resource`-derived config class extending `ConfigResource`
  (`@abstract`, `src/foundation/config_resource.gd`), a matching **text** `.tres` under
  `res://data/config/`, `validate()` called exactly once inside the owning module's
  `setup()`, Inspector-wired on `Valley.tscn` like every other injected-tier dependency.
- **Forbidden**: any block colour literal in `src/voxel_world/` (the one retained
  unknown-colour constant is the single named exception); writing to a config `Resource`
  field at runtime outside its own `validate()` clamp (CONTRACTS.md §2); resolving appearance
  inside `VoxelWorldGrid` (TR-voxel-world-028); **build-state colouring on world geometry** —
  the control manifest is explicit that draft/released/paused/done colouring lives on
  ghost/overlay presentation and the Projects Panel, **never baked into committed-block
  materials**; changing winding, culling, or the one-shared-material rule (ADR-0014 §2).
- **Guardrail**: **an acceptance assertion that passes on today's build is not an
  assertion.** All three levers below fail on the pre-story build.

---

## ⚑ The sprint's deepest rule, applied to this story by name

From `sprint-12.md`'s risk table, the lesson from Sprint 11's worst finding:

> *"Both villager gates defaulted **permissive** when unwired, so `ConstructionTickLoop`
> credited work to absent villagers, and a null validation made **criterion #5 inert in the
> product while green in test**. ⚑ **Rule for this sprint: any injected collaborator whose
> absence changes behaviour must assert at boot or appear in the boot-invariant block. Never
> both optional and consequential.** … `vox-023`'s appearance table is exactly this shape."*

The sprint is right, and the failure mode is specific enough to write down. If the
appearance config is a nullable `@export` that quietly falls back to a built-in table when
unwired, then:

- the game renders **correctly coloured terrain**,
- the `.tres` is **dead data**,
- the palette owner edits it, sees **nothing change**, and
- **every test still passes**, because the fallback is the same table.

That is instance #10 of ship-green-and-uncalled, pre-built, in the exact place the sprint
predicted it. **Therefore: no fallback table exists in code, `setup()` asserts the config is
wired, and the wiring appears in Valley's boot-invariant block.** An unwired appearance
config is a loud boot failure, never a working render. This is AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL
and its deletion probe is Lever 3.

`VoxelWorldMesher.setup()` already establishes the shape verbatim, in this same file:

```gdscript
assert(grid != null, "VoxelWorldMesher.grid not wired")
assert(grid.config != null, "VoxelWorldMesher.grid.config not wired")
```

---

## ⚑ Open Decision 1 — how the table is stored in the `.tres`, and who has to read it

The user **owns the palette** and must be able to change a terrain colour by editing data
and nothing else. That makes the `.tres`'s hand-editability a real acceptance concern, not a
formatting preference — the art bible, `design/art/palette.json`, `palette-system.md` and
`palette_tables.md` all speak **hex**.

- **(a) Parallel typed arrays** — `@export var block_type_ids: PackedInt32Array` +
  `@export var block_colors_hex: PackedStringArray` (hex strings, converted once in the
  config's own accessor). `validate()` returns a **BLOCKING** issue on length mismatch,
  duplicate id, out-of-range id, or malformed hex. Diffs read as
  `block_colors_hex = PackedStringArray("9CAD6E", "A98F5E", …)` — the exact strings the art
  bible and the palette files use. Serialisation is boringly well-supported.
- **(b) Parallel typed arrays with `PackedColorArray`** — same shape, Inspector colour
  pickers work, but a `.tres` diff reads `Color(0.612, 0.678, 0.431, 1)` and the palette
  owner cannot recognise their own hex.
- **(c) A single `@export var block_colors: Dictionary[int, Color]`** — the closest match to
  today's `const`, and the most natural to read in code. ⚑ **Typed-`Dictionary` `@export`
  round-tripping through `.tres` is a post-cutoff behaviour** (typed collections landed
  after the model's knowledge cutoff and Resource export changed again in 4.6/4.7); it must
  be **verified against `docs/engine-reference/godot/` before being chosen — BLOCKING**.

**Producer recommendation: (a).** It is the only option that keeps the palette owner
working in the notation they already use everywhere else, it gives `validate()` real
BLOCKING invariants to enforce, and it depends on no post-cutoff serialisation behaviour.
⚑ **Whichever is chosen, record the choice and its engine-reference verification in the
commit body** — this is a small implementer/TD call, not a silent one.

---

## Acceptance Criteria

- [x] **AC-APPEARANCE-IS-A-CONFIG-RESOURCE**: `voxel_world_mesher.gd`'s
      `const DEBUG_BLOCK_COLORS` is **gone**, replaced by a `Resource`-derived config class
      extending `ConfigResource`, with a matching **text** `.tres` at
      `res://data/config/` — the `world_lighting_config.gd` / `world_lighting_config.tres`
      precedent from `presentation-004`, followed rather than reinvented. The mesher receives
      it as a typed `@export`, Inspector-wired on `Valley.tscn` like every other
      injected-tier dependency, read in `setup()` and **never** in `_ready()`.
      [ADR-0002, ADR-0001, CONTRACTS.md §1/§2]
- [x] **AC-VALIDATE-RUNS-ONCE-AND-BLOCKS**: the config exposes
      `func validate() -> Array[String]`, called exactly once from the mesher's `setup()`.
      Structural defects — duplicate id, id outside `0–255`, malformed colour, mismatched
      parallel-array lengths, an empty table — return a `ConfigResource.format_blocking()`
      issue and halt boot through the **existing terminal path** (`GameWorld` → `HALTED` +
      `boot_halted`), never a new severity model and never a silent clamp.
      [ADR-0002 two-tier policy, CONTRACTS.md §5]
- [x] **AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL** ⚑ *the sprint's deepest rule, and this story's
      named shape*: there is **no fallback appearance table anywhere in code**. The mesher's
      `setup()` asserts the appearance config is wired — the same shape as the two asserts
      already in that method — **and** the wiring appears in `Valley`'s boot-invariant block
      alongside `_assert_lighting_boot_invariant()` /
      `_assert_build_validation_gates_boot_invariant()` /
      `_assert_loop_payoff_wiring_boot_invariant()`. **An unwired appearance config is a loud
      boot failure, never a correct-looking render.** Proven by Lever 3's deletion probe.
- [x] **AC-VISIBLE-FAIL-SURVIVES**: the magenta unknown-colour path is **retained** and
      **still reachable**. An id with no entry in the table renders `Color(1, 0, 0, 1)`-loud
      magenta exactly as today, and a test drives an unmapped id through the real mesher and
      asserts magenta faces are produced. ⚑ **A visible-fail path with no test is dead code
      wearing a safety net's uniform.** Renaming the constant is allowed; changing its
      behaviour is not.
- [x] **AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD** ⚑ *the user's own requirement, made
      testable*: editing a colour value in the `.tres` — **and touching no `.gd` file, no
      scene, and no test** — changes the vertex colour the mesher emits for that id. Asserted
      by loading a second `.tres` fixture with different values and observing the produced
      `Mesh.ARRAY_COLOR` change. **The palette owner's loop is: edit one number, see one
      colour move.**
- [x] **AC-SHIPPED-VALUES-ARE-THE-ART-BIBLE'S**: the shipped `.tres` carries the art bible
      §4.3 band hexes verbatim — Lowland `#9CAD6E`, Midland `#A98F5E`, Highland `#7C818A`,
      Peak `#C9D3D8` — keyed to the ids `vox-022` ratified, with id **1 = Lowland**
      (`vox-022`'s AC-ID-1-STAYS-LOWLAND compatibility constraint). ⚑ **No producer-invented
      colour enters this file.** If `vox-022` shipped fewer than four bands, the table carries
      exactly the ids that exist and no speculative rows.
- [x] **AC-COVERS-EVERY-ID-VOX-022-CAN-EMIT** ⚑ *the cross-story seam, driven from data and
      never from a literal list*: for **every** id the ratified band rule can produce, the
      table has an entry. The test reads the id set from `vox-022`'s band configuration —
      **it does not paste a list** — so the two stories cannot drift apart in a later tuning
      pass. [see Lever 2]
- [x] **AC-NO-STATE-COLOUR-ON-WORLD-GEOMETRY**: the appearance table carries **material**
      colour only. No draft / released / paused / done / validity colouring enters it, and
      none is baked into committed-block vertex colours — build-state colouring stays on
      ghost/overlay presentation and the Projects Panel. *(Control manifest, Presentation
      Layer Rules: "State colors never render on world geometry", source ADR-0014 + ADR-0016.)*
- [x] **AC-MESHER-CONTRACTS-UNCHANGED**: CW winding, backface culling **ENABLED**, and the
      **one shared `ShaderMaterial`** constructed exactly once are all untouched
      (TR-voxel-world-052, ADR-0014 §2). The existing winding-conformance test still passes
      unmodified. This story changes which colour a vertex carries and nothing else about how
      geometry is built.
- [x] **AC-NO-APPEARANCE-IN-THE-DATA-TIER**: `voxel_world_grid.gd` gains **zero** knowledge of
      colour or material appearance — the seam between the two stories remains the opaque
      integer (TR-voxel-world-028).
- [x] **AC-SUITE-GREEN-AND-DIAGNOSED**: the full blocking suite is green headless, 0 orphans,
      exit 0, both checked explicitly. Any pre-existing test that changes is **named
      individually in the commit body with its reason** — a test that changes because the
      colour now comes from data is legitimate; a test that changes because it was asserting
      the hardcoded table must be called out by name.

---

## ⚑ Anti-Vacuity Lever

**Three levers. All three FAIL on today's build. Levers 1 and 2 are carried verbatim in
substance from `sprint-12.md`'s Must table; Lever 3 is added by authoring, because the
sprint's own risk table names this story's shape as the next place a permissive default
could hide.** Every observed pre-story failure goes in the commit body — the `scene-006` /
`scene-007` deletion-probe discipline.

### Lever 1 — zero hardcoded block colours in `src/voxel_world/`

> **Grep-assert zero hardcoded block colours in `src/voxel_world/`.**

Fails today against `voxel_world_mesher.gd:147`, `1: Color("9CAD6E")`.

⚑ **The guard must name its one exception explicitly or it is unwritable**: the retained
unknown-colour constant is the single permitted `Color(...)` construction in
`src/voxel_world/`. Everything else — any `Color("…")`, any `Color(r, g, b)`, any colour
literal in a dictionary or array — must be zero. Built on the established
non-writer/literal-guard precedent (`building-023`, `build-validation-002`, and
`shelter_recovery_live_pair_test.gd`'s `_find_files_assigning` helper — reuse it, it already
generalises).

### Lever 2 — zero unknown-colour faces for every id `vox-022` can emit

> **Assert the mesher renders ZERO `DEBUG_UNKNOWN_COLOR` faces for EVERY id `vox-022`'s
> generator can emit.**

Fails the instant `vox-022` emits id 2 against today's one-entry table: every face of every
Midland cell comes back magenta.

**Mechanism, named so it is not invented twice**: build a chunk through the real
`build_chunk()` path over terrain generated by `vox-022`'s ratified band rule, read the
produced surface's `Mesh.ARRAY_COLOR`, and assert **no** vertex carries the unknown colour.
The id set under test is **read from `vox-022`'s band configuration**, never pasted as a
literal — that is what makes the two stories un-driftable. Pair it with the inverse
(AC-VISIBLE-FAIL-SURVIVES): an id deliberately outside the table **does** produce magenta,
so the assertion is not passing because the magenta path was quietly deleted.

### Lever 3 — the appearance table is never both optional and consequential *(added by authoring)*

> **Remove the appearance config's Inspector wiring on `Valley.tscn` once, boot the real
> `GameWorld`, and record the observed failure.** The expected observation is a **loud boot
> failure** — the `setup()` assert and/or the boot-invariant block firing — **not** a
> correctly coloured world.

Fails today by construction: there is nothing to unwire, and the colours come from a `const`
that no amount of unwiring can disturb. After the story, a run whose terrain still renders
correctly with the config unwired is a **failed** probe and the story has not closed.

Restore verbatim, confirm `git diff` is clean, re-run green — the `scene-007` deletion-probe
record is the format to copy.

⚑ **Explicitly banned vacuous shapes here**: `assert(appearance_config != null)` as the only
evidence; asserting the `.tres` file exists on disk; asserting the config class has the
right fields; asserting the shipped hexes equal the art bible's hexes **in a test that reads
both from the same constant**; and any assertion whose expected value does not change when
the `.tres` is edited.

---

## Out of Scope

*Handled elsewhere, or surfaced as missing — do not implement here:*

- **Which ids terrain generation emits, and where the bands sit.** `vox-022` owns that,
  including its Open Decision 1 band anchor. This story consumes the ids and never chooses
  them.
- **A texture atlas, per-face materials, or any move away from vertex-colour albedo.**
  ADR-0014 §2's one-shared-material, vertex-colour design is unchanged. The class doc
  comment's "placeholder, not a real atlas lookup" note stays honest: this story makes the
  placeholder **data-driven**, it does not replace it with atlasing.
- **⚑ Built cells share the Lowland band's id — recorded, escalated, NOT fixed here.**
  `blueprint_cell.gd:183` writes `CellContents.new(1, 0)` for every built cell, so a built
  wall takes whatever colour id 1 carries — the Lowland olive — while art bible §4.1 gives
  built structures their own Material family (Timber Brown `#8B5E3C`, Hearth-stone Grey
  `#8A8D8F`, Thatch Umber `#A8642F`). Giving built cells their own ids is a **Building
  System** change plus an art-director mapping. ⚑ **It will be visible in this story's own
  captures and in `presentation-004` AC3's re-shoot — name it in the sign-off rather than
  letting it read as a bug in this story.**
- **Build-state colouring of any kind** (draft/released/paused/done, validity feedback) —
  control manifest: never on world geometry.
- **Lighting values.** `presentation-004`'s provisional 0.95 / 0.28 and its AC3 sign-off are
  a separate, deliberately later item — sequenced **after** this story precisely because the
  provisional values exist to compensate for the one-colour world this story ends.
- **Material ids.** `CellContents.material_id` exists and is written as `0` everywhere; a
  material-id-driven appearance dimension is not this story's.
- **Any change to `VoxelWorldGrid`.**

---

## QA Test Cases

- **AC-APPEARANCE-IS-A-CONFIG-RESOURCE**: Given the source tree, When `src/voxel_world/` is
  scanned, Then `DEBUG_BLOCK_COLORS` no longer exists and the mesher holds a typed `@export`
  config; Given `Valley.tscn`, Then the `.tres` is Inspector-wired.
- **AC-VALIDATE-RUNS-ONCE-AND-BLOCKS**: Given a config with a duplicate id, When `validate()`
  runs, Then a `BLOCKING:`-prefixed issue is returned; Given that config at boot, Then
  `GameWorld` reaches `HALTED` via the existing terminal path and no further `setup()` runs.
  Given a valid config, When boot completes, Then `validate()` was called exactly once.
- **AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL**: Given the source, When scanned for a fallback
  colour table, Then none exists. Given the real booted `GameWorld` with the config
  **unwired**, Then boot fails loudly at the mesher's `setup()` assert / the Valley
  boot-invariant block — it does **not** render correct colours. *(Lever 3.)*
- **AC-VISIBLE-FAIL-SURVIVES**: Given a chunk containing a block-type id absent from the
  table, When the chunk is meshed, Then its faces carry the unknown-colour magenta.
- **AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD**: Given two `.tres` fixtures differing only in one
  colour value, When the same chunk is meshed against each, Then the produced
  `Mesh.ARRAY_COLOR` differs at exactly that id's faces, with **zero** `.gd` edits between
  the two runs.
- **AC-SHIPPED-VALUES-ARE-THE-ART-BIBLE'S**: Given the shipped `.tres`, Then its entries are
  the art bible §4.3 hexes for the ids `vox-022` ships, with id 1 = Lowland `#9CAD6E`.
- **AC-COVERS-EVERY-ID-VOX-022-CAN-EMIT**: Given the ratified band configuration, When the id
  set it can produce is enumerated, Then the appearance table has an entry for every one, and
  a real meshed chunk over generated terrain produces **zero** unknown-colour vertices.
  **Negative control:** remove one id's row — this test FAILS with magenta faces.
- **AC-NO-STATE-COLOUR-ON-WORLD-GEOMETRY**: Given the config class and `.tres`, Then no
  build-state field or value exists in either.
- **AC-MESHER-CONTRACTS-UNCHANGED**: Given the landed winding-conformance test, Then it
  passes unmodified; Given the mesher, Then exactly one `ShaderMaterial` is constructed for
  its lifetime and culling remains enabled.
- **AC-SUITE-GREEN-AND-DIAGNOSED**: Given `tests/run-tests.cmd`, Then exit code 0 with 0
  errors, 0 failures, 0 orphans.

---

## Test Evidence

**Story Type**: Logic (**BLOCKING** — automated unit test required, `coding-standards.md`
Test Evidence table)

**Required evidence**:

- `neues-spiel/tests/unit/voxel_world/block_appearance_config_test.gd` — the config class's
  own `validate()` coverage, including every BLOCKING case (duplicate id, out-of-range id,
  malformed colour, mismatched lengths, empty table).
- `neues-spiel/tests/unit/voxel_world/data_driven_block_appearance_test.gd` — a **new** file,
  carrying all three levers:
  - ⚑ **LEVER 1 — the grep guard**: *zero hardcoded block colours in `src/voxel_world/`*,
    with the retained unknown-colour constant as the single named exception. Fails today
    against `voxel_world_mesher.gd:147`.
  - ⚑ **LEVER 2 — zero unknown-colour faces**: mesh a real chunk over `vox-022`-generated
    terrain through the real `build_chunk()` path, read `Mesh.ARRAY_COLOR`, assert **no**
    vertex carries the unknown colour, **for every id the band configuration can emit** —
    the id set read from that configuration, never pasted. Fails the instant `vox-022`
    emits id 2 against today's one-entry table.
  - The inverse of Lever 2 (AC-VISIBLE-FAIL-SURVIVES): an unmapped id **does** produce
    magenta, so Lever 2 cannot pass by the magenta path having been deleted.
  - AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD's two-fixture comparison.
- `neues-spiel/tests/integration/voxel_world/` (or the established scene-boot integration
  location) — the boot assertion for AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL: the real booted
  `GameWorld` reaches ACTIVE with the appearance config wired and validated.
- ⚑ **LEVER 3 — the deletion probe, recorded in the commit body**, not a separate artifact:
  name the removed wiring (`Valley.tscn`'s appearance-config Inspector assignment), quote
  the observed failure verbatim (assert message / test name / statistics line / exit code),
  confirm the restore was byte-for-byte, confirm the re-run was green with `git diff` clean.
  `scene-007`'s Deletion-Probe Record is the format to copy.
- **The observed pre-story failures of Levers 1 and 2, in the commit body.**
- **The Open Decision 1 storage choice and its `docs/engine-reference/godot/` verification,
  in the commit body.**

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on**:
  - ⚑ **`vox-022` (in-sprint, HARD).** Colouring one id differently is vacuous — the sprint
    states this and it is the reason lane T is a two-deep sequence rather than two parallel
    items. Lever 2 is literally undefined until `vox-022`'s band id set exists.
  - `vox-007` (chunked mesher, CW winding, culling — Complete), `presentation-004` (the
    config-Resource precedent this copies, Complete 2026-07-27), `scene-007` (the
    `Valley`-hosts / `GameWorld`-calls-`setup()` hosting precedent, Complete),
    `scene-008` (the boot-invariant block this extends, Complete).
- **Blocked on**: `vox-022` only.
- **Unlocks**:
  - **The user's palette lane.** This is the story that hands the project's palette owner a
    surface they can change without a programmer.
  - **`presentation-004` AC3** — the lighting sign-off, which the sprint sequences strictly
    after this story because the shipped 0.95 / 0.28 was chosen to compensate for the single
    terrain colour this story finally makes data.
  - Milestone criterion #8's golden-hour re-shoot, which is only meaningful against real
    materials.
- **Open decisions this story surfaces (producer → user / technical-director)**:
  1. **`.tres` storage shape for the table** — § Open Decision 1. *Recommendation: parallel
     `PackedInt32Array` + hex `PackedStringArray`, because the palette owner works in hex and
     it depends on no post-cutoff serialisation behaviour.* **BLOCKING engine-reference check
     if a typed `Dictionary` `@export` is chosen instead.** **We will know this was right if**
     the user changes a band colour by editing one string and nothing else.
  2. **Built cells share the Lowland band's id** (building-system + art-director) — see
     **Out of Scope**. Recorded, not absorbed; it becomes visible the moment this story
     lands.

---

## Notes

- Cross-reference `docs/engine-reference/godot/` before touching any engine API
  (**BLOCKING**, as in M01 and S09–S11). The sprint's own risk table names this story as a
  post-cutoff-change domain (materials/shaders, Resource export, typed collections). Verify
  before choosing the storage shape, not after.
- ⚑ **Tree hygiene / palette hand-off**: the user's asset-and-palette lane
  (`design/art/palette.json`, `palette-system.md`, `palette_tables.md`, the palette PNGs,
  `tools/asset-pipeline/`) is actively uncommitted. It touches no `.gd` and no `src/`, so it
  does not poison a suite run — **but this story lands in that area conceptually and the
  hand-off must be coordinated explicitly rather than discovered.** The shipped `.tres` takes
  the art bible §4.3 hexes; if the user's in-flight palette edit changes them, that is a
  `.tres` number edit afterwards, which is exactly the property this story exists to buy.
- **Sequencing note for the captures**: this story is what makes `presentation-004` AC3's
  windowed capture honest. Take the terrain captures **after** it lands, not before.
</content>
</invoke>

---

## Closure Note (2026-07-27) — and one thing the story did NOT settle

Landed. The mesher's hardcoded colour dict is gone; appearance is
`data/config/block_appearance_config.tres`, and changing a hex there changes
exactly one colour in the built mesh — asserted, not assumed. Magenta survives
as the visible-fail path for an unmapped id, with an inverse test proving nobody
quietly deleted it.

Lever 3 is worth recording in full because it is the shape Sprint 12's risk table
demands: unwiring the `.tres` on `Valley.tscn` produced **296 errors**, the
assertion `VoxelWorldMesher.appearance not wired` repeated, and exit code 100 —
a loud, unmissable failure rather than a correct-looking render. Never both
optional and consequential.

### AESTHETIC FINDING, owed to the art director / user — NOT a defect

The world now renders four colours, and it does not look like a valley. Grey
Highland and pale Peak dominate; Lowland olive survives only in patches. The
cause is decision D11's band anchoring, taken provisionally while the user was
away: bands anchored to the ACHIEVABLE terrain range put the boundaries at
[2, 4, 5] in a world whose columns top out between y = 1 and y = 7, so the
material changes every one to two blocks. That satisfies vox-022's lever (four
bands genuinely appear) while reading as stripes rather than terrain.

Two remedies, both data, neither taken here because both are composition calls:
 1. Widen the boundaries so Lowland owns the valley floor and Highland/Peak are
    reserved for genuine crests. Costs nothing; may make band 4 rare or absent
    again, which is what D11 was avoiding.
 2. Raise `max_y` so the bands have real vertical room. Doubles chunk payload
    against ADR-0015's residency budget — a TD question, not only a taste one.

Evidence: `production/qa/evidence/settlement-overview-eyelevel-3.png` and
`-topdown-2.png`, captured through the shipped camera with the tool supplying
no lighting of its own.

THIS MUST BE SETTLED BEFORE presentation-004's AC3 lighting sign-off, which
Sprint 12 already sequences after these two stories — signing off exposure
against striped terrain would repeat the exact mistake AC3's ordering exists to
prevent.
