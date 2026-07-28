## Typed tuning-config Resource for Voxel World / Grid Data (ADR-0002),
## storing every knob from design/gdd/voxel-world.md's Tuning Knobs section.
##
## Wired into [VoxelWorldGrid] (injected-tier, ADR-0001) as a typed `@export`
## dependency; a matching `.tres` instance lives at
## `res://data/config/voxel_world_config.tres`. Defaults are the GDD's
## slice-validated 2000x2000x32 baseline (ADR-0014) -- NOT the 16,000x16,000
## production target, which remains gated behind the storage/streaming spike
## referenced in the GDD's Formulas/Tuning Knobs sections (ADR-0015) and is
## out of this story's scope entirely.
##
## [method validate] applies [ConfigResource]'s two-tier policy: every
## single-field range issue clamps to its nearest GDD-documented safe bound
## and warns; `min_y <= max_y` is the one GDD-declared BLOCKING cross-value
## invariant (there is no single field to clamp for a relationship between
## two fields) -- Core Rule 1 (`design/gdd/voxel-world.md`) requires the grid
## origin fixed at (0,0,0) with no negative cell coordinates, so a violated
## `min_y <= max_y` can never be resolved by clamping either field alone.
class_name VoxelWorldConfig
extends ConfigResource

## Fixed cell edge length (GDD Formulas + Tuning Knobs, TR-voxel-world-012;
## Visual Direction Note §2b) -- blocks are flush, no gap. Deliberately NOT
## an `@export`: the GDD locks this value, it is not a designer tuning knob.
const CELL_SIZE: float = 1.0

## Safe range for [member world_width_cells] (GDD Tuning Knobs: 256-2048
## validated). The 16,000 production target is UNVALIDATED pending the
## storage/streaming spike (ADR-0015) and is out of this story's scope --
## this range intentionally does NOT extend to it.
const WORLD_WIDTH_CELLS_MIN: int = 256
const WORLD_WIDTH_CELLS_MAX: int = 2048

## Safe range for [member world_depth_cells] -- see [constant
## WORLD_WIDTH_CELLS_MIN] (identical range, GDD Tuning Knobs).
const WORLD_DEPTH_CELLS_MIN: int = 256
const WORLD_DEPTH_CELLS_MAX: int = 2048

## [member min_y] carries no GDD-documented safe range of its own beyond
## Core Rule 1's fixed-origin invariant (no negative cell coordinates) --
## this is the only floor enforced as a single-field clamp; the relationship
## to [member max_y] is the separate BLOCKING invariant.
const MIN_Y_FLOOR: int = 0

## Safe range for [member max_y] (GDD Tuning Knobs: 8-32).
const MAX_Y_MIN: int = 8
const MAX_Y_MAX: int = 96

## Floor for [member base_height]. Its GDD-documented upper bound ("0 to
## max_y-1", Tuning Knobs) is relative to [member max_y]'s current value, so
## [method validate] applies it dynamically rather than as a second fixed
## constant.
const BASE_HEIGHT_MIN: int = 0

## Safe range for [member amplitude] (GDD Tuning Knobs: 0-8).
const AMPLITUDE_MIN: float = 0.0
const AMPLITUDE_MAX: float = 32.0

## Safe range for [member frequency] (GDD Tuning Knobs: 0.01-0.2).
const FREQUENCY_MIN: float = 0.01
const FREQUENCY_MAX: float = 0.2

## Safe range for [member region_size_chunks] (Story vox-010, ADR-0015
## Decision §2 -- "a spike-tuned knob", not a GDD Tuning Knob; range is this
## story's own choice, wide enough to cover the spike's validated 32 default
## while still catching a degenerate 0/negative or absurdly large value).
const REGION_SIZE_CHUNKS_MIN: int = 4
const REGION_SIZE_CHUNKS_MAX: int = 128

## Safe range for [member view_radius_chunks] (Story vox-010, ADR-0015
## Decision §1's "camera-near chunks (ADR-0014 view radius)"; spike default
## 24 -- see [member view_radius_chunks]'s own doc comment).
const VIEW_RADIUS_CHUNKS_MIN: int = 2
const VIEW_RADIUS_CHUNKS_MAX: int = 64

## Safe range for [member boot_mesh_radius_chunks] (Story vox-021, TD ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md` Addendum D
## / D2). Floor matches [constant VIEW_RADIUS_CHUNKS_MIN] (a boot window
## smaller than 2 has no meaning); ceiling is [constant VIEW_RADIUS_CHUNKS_MAX]
## itself, NOT [member view_radius_chunks]'s current value -- the separate
## `> view_radius_chunks` check in [method validate] is its own clamp+warn
## tier (a boot window larger than the steady-state window is a configuration
## error, non-BLOCKING, ADR-0002 two-tier) rather than a second range bound.
const BOOT_MESH_RADIUS_CHUNKS_MIN: int = 2
const BOOT_MESH_RADIUS_CHUNKS_MAX: int = VIEW_RADIUS_CHUNKS_MAX

## Safe range for [member settlement_radius_chunks] (Story vox-010, ADR-0015
## Decision §1's "active-settlement chunks (ADR-0007 nav region)"; spike
## default 8 -- see [member settlement_radius_chunks]'s own doc comment).
const SETTLEMENT_RADIUS_CHUNKS_MIN: int = 1
const SETTLEMENT_RADIUS_CHUNKS_MAX: int = 32

## Safe range for [member max_concurrent_async_tasks] (Story vox-011,
## ADR-0015 Decision §6's `MAX_CONCURRENT_ASYNC_TASKS` -- "a config knob" the
## spike measured at 32 and 64 with the worst frame nearly identical between
## them, i.e. "the exact cap is not load-bearing" -- Story 016 measured/
## recorded the tuned production value (see [member
## max_concurrent_async_tasks]'s own doc comment); this range only guards
## against a degenerate 0-or-negative or absurdly large value).
const MAX_CONCURRENT_ASYNC_TASKS_MIN: int = 1
const MAX_CONCURRENT_ASYNC_TASKS_MAX: int = 128

## Safe range for [member max_chunk_generation_cost_ms] (Story vox-016,
## ADR-0015 carried tuning item C1 -- "the per-chunk generation cost must be
## bounded"). This range is this story's own choice, same "spike-tuned knob,
## not a GDD Tuning Knob" rationale as [constant REGION_SIZE_CHUNKS_MIN]/
## [constant MAX] -- wide enough to record a sub-millisecond measured value
## while still catching a degenerate zero-or-negative bound that would make
## the recorded regression guard meaningless.
const CHUNK_GENERATION_COST_MS_MIN: float = 0.001
const CHUNK_GENERATION_COST_MS_MAX: float = 1000.0

## Safe range for [member page_budget_ms]/[member evict_budget_ms] (Story
## vox-012, ADR-0015 Decision §1 -- "a time budget... validated at 4.0 ms
## each"). This range is this story's own choice, same "spike-tuned knob,
## not a GDD Tuning Knob" rationale as [constant REGION_SIZE_CHUNKS_MIN]/
## [constant MAX] -- wide enough that a test can set a deliberately generous
## budget (proving no item-count is silently capped even when time is
## plentiful) while still catching a degenerate zero-or-negative value that
## would defeat the "not a fixed item count" guarantee (a budget of exactly
## 0 would starve every item after the always-progress first one).
const STREAM_BUDGET_MS_MIN: float = 0.1
const STREAM_BUDGET_MS_MAX: float = 1000.0

## Safe range for a [member band_ids] entry (Story vox-022, GDD Core Rule 8 /
## TR-voxel-world-051's dig-order-eligible "1..5 value family" -- terrain
## bands and sand, explicitly EXCLUDING water and trunk/leaves values). Every
## band id this config declares MUST fall inside this range so terrain
## generation can never emit an id dig-order eligibility does not already
## cover -- checked as a BLOCKING cross-value invariant in [method validate],
## the same tier as [member min_y]/[member max_y]'s own relationship, not a
## single-field clamp (there is no single "nearest valid id" to clamp a band
## assignment to).
const BAND_ID_MIN: int = 1
const BAND_ID_MAX: int = 5

## Fallback used by [method validate] when [member region_directory] is
## empty (a single-field clamp-to-default, same two-tier policy as every
## other ranged knob here).
const REGION_DIRECTORY_DEFAULT: String = "user://regions"

## Horizontal world extent along X, in cells (GDD default: 2000 -- the
## slice-validated baseline, ADR-0014; NOT the 16,000 production target).
## [TR-voxel-world-016] [TR-voxel-world-023]
@export var world_width_cells: int = 2000

## Horizontal world extent along Z, in cells (GDD default: 2000). See
## [member world_width_cells]. [TR-voxel-world-016] [TR-voxel-world-023]
@export var world_depth_cells: int = 2000

## Minimum valid cell Y (GDD default: 0). Recommended fixed at 0 -- Core
## Rule 1 fixes the grid origin at (0,0,0) with no negative cell
## coordinates. [TR-voxel-world-027] [TR-voxel-world-023]
@export var min_y: int = 0

## Maximum valid cell Y (GDD default: 16). [TR-voxel-world-023]
@export var max_y: int = 16

## Valley-floor terrain height fed into the procedural terrain height
## formula (GDD default: 4; Story 006 scope). [TR-voxel-world-023]
@export var base_height: int = 4

## Max height variation from noise, fed into the procedural terrain height
## formula (GDD default: 3.0; Story 006 scope). [TR-voxel-world-023]
@export var amplitude: float = 3.0

## Noise scale, fed into the procedural terrain height formula (GDD
## default: 0.05; Story 006 scope). [TR-voxel-world-023]
@export var frequency: float = 0.05

## Deterministic seed for [method VoxelWorldGrid.generate_terrain]'s
## `noise2D` (TR-voxel-world-039: "deterministic, seeded 2D noise function").
## Not itself a named row in the GDD's Tuning Knobs table (added this story
## to satisfy TR-voxel-world-039's seeding requirement without a hardcoded
## literal, per ADR-0002's "data-driven, never hardcoded" mandate) -- any
## `int` is a valid seed, so [method validate] applies no range check here.
## Two [VoxelWorldGrid.generate_terrain] runs with the same [member
## terrain_seed] (and otherwise-identical config) produce byte-identical
## terrain; a different seed produces different terrain (ADR-0015's
## deterministic-seeded-regen premise). [TR-voxel-world-039] [TR-voxel-world-023]
@export var terrain_seed: int = 12345

## Root directory for on-disk region files (Story vox-010, ADR-0015 Decision
## §2/§4) -- the paged residency tier's storage location. Production default
## is a `user://` path: region files are user data, `.gitignore`d BY
## CONSTRUCTION since `user://` resolves to the OS-specific user-data
## directory, entirely outside this project's git-tracked tree -- never
## `res://`, which is git-tracked and read-only at runtime once exported.
## Tests MUST override this to an isolated per-test temp directory and
## remove it in `after_test` -- never share a region directory across test
## runs (region-file test-isolation pitfall).
@export var region_directory: String = REGION_DIRECTORY_DEFAULT

## Region file dimensions, in chunks per axis (ADR-0015 Decision §2's
## `region_size_chunks` -- "a spike-tuned knob"; spike default 32x32
## chunks/region, `prototypes/storage-residency-spike/README.md` "Design
## choices made"). [TR-voxel-world-053]
@export var region_size_chunks: int = 32

## Camera-near residency window radius, in chunks (ADR-0015 Decision §1's
## "camera-near chunks (ADR-0014 view radius)"; spike default 24).
##
## Story vox-015 (ADR-0014 Decision §3): this is the SAME knob
## [VoxelWorldMeshStreamer] reads for the MESH view window's own radius --
## the reconciliation this doc comment previously named as pending is now
## resolved by reuse, not by a second, independent mesh-radius field. The two
## windows can still observe different chunk MEMBERSHIP at any instant
## (residency additionally unions in the active-settlement window, [member
## settlement_radius_chunks], which the mesh tier deliberately does not -- a
## settlement chunk outside camera view has no mesh to show regardless of
## Villager AI needing its DATA resident), but both windows are centered on
## the same camera focus concept at the same radius. [TR-voxel-world-053]
## [TR-voxel-world-025]
##
## Story vox-021 re-tune (TD ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md` Addendum D
## / D2), 24 -> 12: at the MEASURED 7.7 ms/chunk mesh-build cost
## (`voxel-world-60fps-culling-evidence-20260725-vox019.md`), radius 24 is
## 49x49 = 2401 chunks = **18.5 s** of meshing -- a window
## [method VoxelWorldMeshStreamer.update_view_window] can never maintain
## (the budgeted per-frame path integrates at most ~1 chunk/frame once the
## window is already full, so ANY further edit/regrowth at this radius stays
## perpetually behind). Radius 12 is 25x25 = 625 chunks = **4.8 s** -- still
## too slow for a synchronous boot window (see [member
## boot_mesh_radius_chunks] for the boot-scoped answer to that), but
## affordable for [method update_view_window]'s own budgeted, amortized
## per-frame growth in STEADY STATE, which is what this knob actually governs
## day to day. **This is the knob that makes the steady-state window
## actually maintainable at the current mesher cost** -- a pure `.tres` data
## change, instantly reversible, no code.
@export var view_radius_chunks: int = 24

## Boot-scoped initial mesh-window radius, in chunks (Story vox-021, TD ruling
## Addendum D / D2) -- consumed ONLY by [method
## VoxelWorldMeshStreamer.build_initial_window], threaded as a radius
## parameter into the existing [method VoxelWorldMeshStreamer._collect_window]
## -- no new state, no timer, no camera-move trigger, no second code path.
## [method VoxelWorldMeshStreamer.update_view_window] (and [method
## VoxelWorldMeshStreamer.get_desired_window_keys]) continue to read [member
## view_radius_chunks], unchanged -- growth from this boot window to the full
## steady-state window happens over frames via that ALREADY-budgeted path,
## never a second mechanism.
##
## Rationale (D2 arithmetic at the measured 7.7 ms/chunk): radius 8 is
## 17x17 = 289 chunks = **~2.2 s** -- comfortably inside the 2.5 s boot mesh-
## phase ceiling this story's own evidence doc measures against. The decisive
## point: shrinking ONLY this knob while [member view_radius_chunks] stayed
## at its old value of 24 would have moved the cost, not removed it --
## [method VoxelWorldMeshStreamer.update_view_window] would grow the window
## back to the full (unaffordable) radius at ~1 chunk/frame, trading an
## 18.5 s freeze for ~35 s of visible pop-in. Both knobs had to move together
## (this field new at 8; [member view_radius_chunks] retuned 24 -> 12) --
## see that member's own doc comment for its half of the arithmetic.
@export var boot_mesh_radius_chunks: int = 8

## Active-settlement residency window radius, in chunks, around an injected
## settlement anchor (ADR-0015 Decision §1's "active-settlement chunks
## (ADR-0007 nav region)"; spike default 8 -- "smaller than the 24-chunk
## camera view radius"). Villager AI's own nav-region wiring (ADR-0007) does
## not exist in production yet -- this knob stands in for that scale until
## that story lands. [TR-voxel-world-053]
@export var settlement_radius_chunks: int = 8

## Maximum number of in-flight [WorkerThreadPool] tasks Voxel World's
## residency tier will have dispatched at once, SHARED across region-file
## reads, terrain-gen (Story 011), AND eviction-flush writes (ADR-0015
## Decision §6's `MAX_CONCURRENT_ASYNC_TASKS`; spike default 32 -- measured
## at 32 and 64, worst frame nearly identical between them). A chunk that
## needs paging in/out when this cap is already saturated simply stays
## queued for a later call -- it is NEVER read/regenerated/flushed
## synchronously as a fallback (ADR-0015 Decision §6: "a synchronous fallback
## IS the failure mode").
##
## Story vox-016 re-measurement (this revision, ADR-0015 carried tuning item
## C1): re-measured against the REAL production [VoxelWorldGrid]/[method
## update_residency] (never the throwaway `prototypes/storage-residency-
## spike/` code) via `tools/vox016_residency_tuning_measurement.gd` -- a
## full-span corridor traverse at the shipped [CameraInputConfig]'s own real
## max camera speed (`distance_max * pan_speed_factor` = 60.0 * 0.7 = 42.0
## cells/sec -- NOT the spike's stale 144 cells/sec, which was derived from
## an earlier prototype `camera_input.gd`'s now-superseded constants, never
## the shipped production config), at both candidate caps (32, 64), on a
## 2000x2000-cell world (the shipped `world_width_cells`/`world_depth_cells`
## default), 3 full one-way legs, 8,397 `update_residency()` calls sampled
## per cap. MEASURED (2026-07-26): cap 32 -- worst 5.512 ms, p95 3.927 ms,
## avg 2.369 ms; cap 64 -- worst 10.727 ms, p95 2.836 ms, avg 2.359 ms. Both
## caps kept the worst `update_residency()` call comfortably inside the
## 16.6 ms frame budget (cap 32 at 3.0x headroom, cap 64 at 1.5x headroom) --
## confirming the spike's own "the exact cap is not load-bearing" finding
## holds on production code, not just the spike's synthetic terrain-gen
## formula (cap 32's worst frame is, if anything, LOWER than cap 64's here).
## **Kept at 32** (the already-shipped value) rather than moved to 64 --
## there was no measured benefit to the larger cap (worse worst-frame, only
## a marginally better p95), and a smaller cap leaves more
## `WorkerThreadPool` headroom for other systems (mesh building, Villager
## AI) sharing the same pool. See `production/qa/smoke-2026-07-26.md` for
## the full measured numbers.
## Because cap-miss = "stay queued," not "run synchronously" (Story 011),
## this value is NON-CRITICAL to correctness -- never mistake it for a hard
## correctness threshold. [TR-voxel-world-053]
@export var max_concurrent_async_tasks: int = 32

## Recorded, MEASURED per-chunk terrain-generation cost bound, milliseconds
## (Story vox-016, ADR-0015 carried tuning item C1: "the per-chunk
## generation cost must be bounded"). This is NOT a runtime throttle --
## ADR-0015 Decision §6 forbids any synchronous fallback/preemption of an
## in-flight [WorkerThreadPool] task ("a synchronous fallback IS the failure
## mode"), so this value cannot and does not cap [method
## VoxelWorldGrid._bg_regenerate_from_seed]'s actual wall time. It is a
## recorded REGRESSION GUARD: `tools/vox016_residency_tuning_measurement.gd`
## Phase 0 measures the CURRENT production per-chunk regen cost DIRECTLY --
## the exact `static` pure functions [method
## VoxelWorldGrid._bg_regenerate_from_seed] calls
## ([method VoxelWorldGrid._pure_terrain_noise], [method
## VoxelWorldGrid._pure_terrain_height]), timed in isolation from
## [WorkerThreadPool] dispatch/polling overhead -- over 40 distinct
## never-before-touched chunks. MEASURED (2026-07-26): avg 0.166 ms, p95
## 0.212 ms, worst 0.226 ms per chunk (single-octave [FastNoiseLite] height
## per column, `FRACTAL_NONE`, no tree stamping, production
## [constant VoxelWorldGrid.CHUNK_SIZE] = 16 footprint). This value is set
## to 1.0 ms -- roughly 4.7x headroom over the measured p95 (4.4x over the
## measured worst sample) -- a future change that makes terrain generation
## dramatically more expensive (added noise octaves, tree stamping, etc.)
## should be checked against this recorded bound rather than silently
## eroding ADR-0015's "regen_worst = 0.00 ms by construction" async
## guarantee. (The tool's Phase 1 also reports a dispatch+poll wall-time
## number for the same chunks, ~2.0 ms -- that number is dominated by
## [method VoxelWorldGrid.wait_for_async_residency_idle]'s own ~1 ms polling
## granularity, NOT real compute cost, and is deliberately NOT what this
## bound is measured against; see the tool's own class doc comment.) See
## `production/qa/smoke-2026-07-26.md` for the full measured numbers.
## [TR-voxel-world-053]
@export var max_chunk_generation_cost_ms: float = 1.0

## Per-frame TIME budget (milliseconds) for PAGE-IN work -- integrating an
## already-finished background read result into [member _chunks] AND
## dispatching a fresh page-in task for a not-yet-requested chunk (Story
## vox-012, ADR-0015 Decision §1; TR-voxel-world-053) -- NOT a fixed
## chunks-per-frame count. Spike-validated default 4.0 ms, leaving ~12 ms of
## the 16.6 ms frame budget for game work alongside [member evict_budget_ms]'s
## own 4.0 ms. Re-checked after every single processed item
## ([VoxelWorldGrid._drain_budgeted]) -- a burst of ready/queued items in one
## [method VoxelWorldGrid.update_residency] call can never collectively
## exceed this; the excess simply stays unprocessed and is retried the next
## call (the "later frame" ADR-0015 requires). [TR-voxel-world-053]
@export var page_budget_ms: float = 4.0

## Per-frame TIME budget (milliseconds) for EVICTION work -- reaping an
## already-finished background flush result AND dispatching a fresh
## eviction-flush task for a newly-stale dirty chunk (Story vox-012,
## ADR-0015 Decision §1; TR-voxel-world-053) -- see [member page_budget_ms]'s
## doc comment for the shared rationale/mechanism; the eviction counterpart,
## spike-validated default 4.0 ms. Reaping and dispatching each get their OWN
## fresh budget window per [method VoxelWorldGrid.update_residency] call
## (never a shared/cumulative one with page-in or with each other) -- see
## that method's doc comment for why. [TR-voxel-world-053]
@export var evict_budget_ms: float = 4.0

## Per-frame TIME budget (milliseconds) for MESH BUILD work -- meshing a
## newly-entered chunk of the camera VIEW WINDOW (Story vox-015, ADR-0014
## Decision §3's "per-frame build budget" reworked to ADR-0015 Decision §1's
## time-based discipline, applied here to the MESH tier) -- NOT a fixed
## chunks-per-frame count (ADR-0015 Decision §1's "never a fixed
## chunks-per-frame streaming count" rule applies here exactly as it does to
## [member page_budget_ms]/[member evict_budget_ms]'s own data-tier budgets).
## Distinct from those two: this bounds a MESH build (an [ArrayMesh] rebuild
## on the MAIN thread), never disk/regen I/O -- see [VoxelWorldMeshStreamer]
## for the consuming per-frame streaming step.
##
## Story vox-019 re-tune rationale (`production/qa/evidence/voxel-world-60fps-
## culling-evidence-20260725-vox019.md`): [method
## VoxelWorldMesher._build_chunk_arrays]'s read-loop optimization dropped the
## MEASURED real per-chunk build cost from ~40.4 ms (vox-018's own root-cause
## figure, 961 chunks / 38,821 ms) to ~7.7 ms (this story's own re-measurement,
## 961 chunks / 7,395.9 ms at the SAME 896-cell/`view_radius_chunks=24` scale)
## -- a ~5.2x reduction. Empirically re-tested at 2.0 ms, 4.0 ms (unchanged),
## and 8.0 ms with the SAME windowed re-measurement tool: the measured p95/avg
## frame time did NOT improve at either alternative (8.0 ms measured WORSE:
## p95 19.490 ms vs 4.0 ms's 16.947 ms) -- confirms this budget knob's own
## progress-guarantee (the first item in any batch always integrates
## regardless of budget) means the per-frame cost is dominated by the
## guaranteed single chunk build during a continuous camera sweep, not by
## this knob's exact value, as long as it stays below the real per-chunk
## cost (true both before AND after vox-019's read-loop fix -- the knob
## "mattered" in neither state, per that story's own AC3 caveat). Kept at the
## spike-validated 4.0 ms default rather than changed to a value this
## story's own measurements showed was no better (and, at 8.0 ms, measurably
## worse). [TR-voxel-world-025]
@export var mesh_build_budget_ms: float = 4.0

## Per-frame TIME budget (milliseconds) for MESH UNLOAD work -- staggering
## [method VoxelWorldMesher.unload_chunk] calls for chunks that left the
## camera view window (Story vox-015, ADR-0014 Decision §3's "chunks beyond
## radius+margin are unloaded staggered across frames -- the prototype's one
## 133 ms hitch came from an unload burst" / Control Manifest Forbidden:
## "queue_free bursts"). See [member mesh_build_budget_ms]'s doc comment for
## the shared time-based-not-fixed-count rationale. [TR-voxel-world-025]
@export var mesh_unload_budget_ms: float = 4.0

## Ordered terrain height-band ids (Story vox-022, art bible §4.3's four
## bands -- Lowland/Midland/Highland/Peak -- mapped onto GDD Core Rule 8 /
## TR-voxel-world-051's dig-order-eligible "1..5 value family"), paired
## positionally with [member band_boundaries]: `band_ids[i]` is emitted for
## every cell whose Y falls at or below `band_boundaries[i]` (and above
## `band_boundaries[i-1]`, or [member min_y] for `i == 0`); the LAST id in
## this array is emitted for every Y strictly above `band_boundaries`' last
## entry, all the way to [member max_y] -- so [member band_boundaries] is
## always exactly one entry SHORTER than this array (validated in [method
## validate]).
##
## `band_ids[0]` MUST stay `1` -- a compatibility constraint, not a taste
## call (story vox-022 AC-ID-1-STAYS-LOWLAND): every already-serialized
## region file holds id-1 chunks, and `blueprint_cell.gd`'s built-cell
## default is also `CellContents.new(1, 0)` -- renumbering id 1 would
## silently recolour every wall the player has ever built AND every
## persisted region file. [method validate] reports a violation as BLOCKING.
##
## PROVISIONAL -- Open Decision 1 (story vox-022), awaiting art-director +
## user ratification, same status [WorldLightingConfig]'s AC3 fields carry.
## Shipped as 4 bands (matching art bible §4.3 verbatim) rather than the
## sprint's own descope-ladder fallback of 2, because the shipped tuning
## (see [member band_boundaries]'s doc comment) already reaches all four
## bands without a retune.
@export var band_ids: Array[int] = [1, 2, 3, 4]

## Upper-inclusive Y threshold for each band in [member band_ids] EXCEPT the
## last (which has no ceiling of its own -- see that member's doc comment).
## Story vox-022, Open Decision 1's ratified anchor **(a)**: normalises the
## art bible's four bands across the ACHIEVABLE terrain height range
## `[base_height - amplitude, base_height + amplitude]` -- **NOT** the art
## bible's literal "of 32" denominator (§4.3) applied against [member min_y]/
## [member max_y] directly. Read off two files on disk at authoring time
## (2026-07-27): the shipped `.tres` ships `max_y = 16`, `base_height = 4`,
## `amplitude = 3.0`, so `procedural_terrain_height`'s own clamp() means
## every column's top surface lands between Y = 1 and Y = 7 -- entirely
## inside the art bible's literal band 1 (0-8). Applying §4.3's denominator
## verbatim would therefore still emit exactly ONE id after this story
## shipped, which is the exact defect story vox-022 exists to end.
##
## Anchor (a)'s arithmetic, applied once to produce these DEFAULTS (a plain
## `.tres` number edit reverses or retunes this, never a code change):
## achievable range `[1, 7]` (width 6) split into 4 equal quarters of 1.5,
## floored per boundary -- `floor(1 + 1*1.5) = 2`, `floor(1 + 2*1.5) = 4`,
## `floor(1 + 3*1.5) = 5` -- giving band spans Lowland Y∈[0,2], Midland
## Y∈[3,4], Highland Y∈[5,5], Peak Y∈[6,16]. Cost (recorded per Open
## Decision 1): "Peak" snow sits at Y≈6-7, a hilltop rather than a literal
## mountain -- the hue ramp (warm-neutral low → cool-pale high) reads as the
## art bible intends; the literal material story (snow) does not, at this
## tuning. Retuning [member amplitude]/[member base_height] later shifts
## these boundaries' MEANING (they stay in absolute Y) but not their
## validity -- [method validate] only requires them monotonically
## increasing and inside `[min_y, max_y]`, never tied to `amplitude`/
## `base_height`'s current values.
##
## PROVISIONAL -- Open Decision 1 (story vox-022), awaiting art-director +
## user ratification. Because these are typed `@export` fields (ADR-0002)
## rather than a literal inside `voxel_world_grid.gd`, overturning this
## ruling is a `.tres` number edit and nothing else.
@export var band_boundaries: Array[int] = []

## Where the bands split, as FRACTIONS of the achievable terrain range — the
## fix for what [member band_boundaries] got wrong.
##
## Absolute boundaries do not travel. Written for a 16-high world they read
## `[2, 4, 5]`; raise the world to 96 and terrain runs y≈16..64, so every cell
## sits above the top boundary and the entire world renders in one band. Write
## them for the 96-high world instead (`[24, 48, 72]`, quarters of the WORLD)
## and the top band lands above every reachable cell, so that colour never
## appears at all. Both were tried; both were wrong in opposite directions.
##
## Fractions travel. The achievable surface range is `base_height ± amplitude`,
## which is exactly what terrain generation produces, so a split at 0.5 means
## "halfway up the ground that actually exists" at any world size.
##
## DESIGN NOTE, and it is a real choice rather than a detail — art bible §4.3
## thinks of the bands as quarters of the WORLD, because a snow line is an
## absolute height. That reading is self-consistent and it is why a flat world
## has no snow at all. Anchoring to the achievable range instead guarantees all
## four materials appear at every world size, at the cost that in low relief the
## "Peak" material sits on a hilltop rather than a mountain. Defaulting to even
## quarters keeps the art bible's proportions; pushing the last fraction up
## (e.g. `[0.3, 0.6, 0.9]`) reserves the peak material for genuine crests. That
## dial is the art director's, which is why it is data.
##
## Ignored entirely when [member band_boundaries] is non-empty — an explicit
## absolute list always wins, so a specific world can still be hand-tuned.
@export var band_split_fractions: Array[float] = [0.25, 0.5, 0.75]


## The boundaries terrain generation actually uses: [member band_boundaries]
## verbatim when set, otherwise derived from [member band_split_fractions]
## across the achievable surface range.
##
## Derivation, deliberately the same arithmetic the old hand-computed defaults
## used, just no longer frozen at one world size: the surface spans
## `base_height - amplitude` to `base_height + amplitude`, clamped into
## `[min_y, max_y]`; each fraction picks a floor()ed cut across that span. The
## result is monotonic by construction whenever the fractions are, so
## [method validate]'s ordering rule holds without a second check.
func effective_band_boundaries() -> Array[int]:
	if not band_boundaries.is_empty():
		return band_boundaries
	var low: int = maxi(min_y, int(floor(base_height - amplitude)))
	var high: int = mini(max_y, int(ceil(base_height + amplitude)))
	var span: int = maxi(1, high - low)
	var derived: Array[int] = []
	for fraction: float in band_split_fractions:
		derived.append(clampi(low + int(floor(span * fraction)), min_y, max_y))
	return derived


## See [ConfigResource.validate]. Clamps every ranged knob to its
## GDD-documented safe bound in place (the sole sanctioned runtime write to
## this config) and appends a warning string per clamped field; reports
## `min_y <= max_y` as BLOCKING when violated instead of clamping either
## field (ADR-0002 two-tier policy).
func validate() -> Array[String]:
	var issues: Array[String] = []
	if world_width_cells < WORLD_WIDTH_CELLS_MIN or world_width_cells > WORLD_WIDTH_CELLS_MAX:
		issues.append(
			"world_width_cells out of range [%s, %s], got %s -- clamped" %
			[WORLD_WIDTH_CELLS_MIN, WORLD_WIDTH_CELLS_MAX, world_width_cells]
		)
		world_width_cells = clampi(world_width_cells, WORLD_WIDTH_CELLS_MIN, WORLD_WIDTH_CELLS_MAX)
	if world_depth_cells < WORLD_DEPTH_CELLS_MIN or world_depth_cells > WORLD_DEPTH_CELLS_MAX:
		issues.append(
			"world_depth_cells out of range [%s, %s], got %s -- clamped" %
			[WORLD_DEPTH_CELLS_MIN, WORLD_DEPTH_CELLS_MAX, world_depth_cells]
		)
		world_depth_cells = clampi(world_depth_cells, WORLD_DEPTH_CELLS_MIN, WORLD_DEPTH_CELLS_MAX)
	if min_y < MIN_Y_FLOOR:
		issues.append(
			"min_y below floor %s, got %s -- clamped" % [MIN_Y_FLOOR, min_y]
		)
		min_y = MIN_Y_FLOOR
	if max_y < MAX_Y_MIN or max_y > MAX_Y_MAX:
		issues.append(
			"max_y out of range [%s, %s], got %s -- clamped" % [MAX_Y_MIN, MAX_Y_MAX, max_y]
		)
		max_y = clampi(max_y, MAX_Y_MIN, MAX_Y_MAX)
	var base_height_ceiling: int = maxi(max_y - 1, BASE_HEIGHT_MIN)
	if base_height < BASE_HEIGHT_MIN or base_height > base_height_ceiling:
		issues.append(
			"base_height out of range [%s, %s], got %s -- clamped" %
			[BASE_HEIGHT_MIN, base_height_ceiling, base_height]
		)
		base_height = clampi(base_height, BASE_HEIGHT_MIN, base_height_ceiling)
	if amplitude < AMPLITUDE_MIN or amplitude > AMPLITUDE_MAX:
		issues.append(
			"amplitude out of range [%s, %s], got %s -- clamped" % [AMPLITUDE_MIN, AMPLITUDE_MAX, amplitude]
		)
		amplitude = clampf(amplitude, AMPLITUDE_MIN, AMPLITUDE_MAX)
	if frequency < FREQUENCY_MIN or frequency > FREQUENCY_MAX:
		issues.append(
			"frequency out of range [%s, %s], got %s -- clamped" % [FREQUENCY_MIN, FREQUENCY_MAX, frequency]
		)
		frequency = clampf(frequency, FREQUENCY_MIN, FREQUENCY_MAX)
	if region_directory.is_empty():
		issues.append(
			"region_directory is empty -- clamped to default '%s'" % REGION_DIRECTORY_DEFAULT
		)
		region_directory = REGION_DIRECTORY_DEFAULT
	if region_size_chunks < REGION_SIZE_CHUNKS_MIN or region_size_chunks > REGION_SIZE_CHUNKS_MAX:
		issues.append(
			"region_size_chunks out of range [%s, %s], got %s -- clamped" %
			[REGION_SIZE_CHUNKS_MIN, REGION_SIZE_CHUNKS_MAX, region_size_chunks]
		)
		region_size_chunks = clampi(region_size_chunks, REGION_SIZE_CHUNKS_MIN, REGION_SIZE_CHUNKS_MAX)
	if view_radius_chunks < VIEW_RADIUS_CHUNKS_MIN or view_radius_chunks > VIEW_RADIUS_CHUNKS_MAX:
		issues.append(
			"view_radius_chunks out of range [%s, %s], got %s -- clamped" %
			[VIEW_RADIUS_CHUNKS_MIN, VIEW_RADIUS_CHUNKS_MAX, view_radius_chunks]
		)
		view_radius_chunks = clampi(view_radius_chunks, VIEW_RADIUS_CHUNKS_MIN, VIEW_RADIUS_CHUNKS_MAX)
	if boot_mesh_radius_chunks < BOOT_MESH_RADIUS_CHUNKS_MIN or boot_mesh_radius_chunks > BOOT_MESH_RADIUS_CHUNKS_MAX:
		issues.append(
			"boot_mesh_radius_chunks out of range [%s, %s], got %s -- clamped" %
			[BOOT_MESH_RADIUS_CHUNKS_MIN, BOOT_MESH_RADIUS_CHUNKS_MAX, boot_mesh_radius_chunks]
		)
		boot_mesh_radius_chunks = clampi(boot_mesh_radius_chunks, BOOT_MESH_RADIUS_CHUNKS_MIN, BOOT_MESH_RADIUS_CHUNKS_MAX)
	if boot_mesh_radius_chunks > view_radius_chunks:
		issues.append(
			(
				"boot_mesh_radius_chunks (%s) exceeds view_radius_chunks (%s) -- a boot window larger" +
				" than the steady-state window is a configuration error -- clamped to view_radius_chunks"
			) % [boot_mesh_radius_chunks, view_radius_chunks]
		)
		boot_mesh_radius_chunks = view_radius_chunks
	if settlement_radius_chunks < SETTLEMENT_RADIUS_CHUNKS_MIN or settlement_radius_chunks > SETTLEMENT_RADIUS_CHUNKS_MAX:
		issues.append(
			"settlement_radius_chunks out of range [%s, %s], got %s -- clamped" %
			[SETTLEMENT_RADIUS_CHUNKS_MIN, SETTLEMENT_RADIUS_CHUNKS_MAX, settlement_radius_chunks]
		)
		settlement_radius_chunks = clampi(settlement_radius_chunks, SETTLEMENT_RADIUS_CHUNKS_MIN, SETTLEMENT_RADIUS_CHUNKS_MAX)
	if max_concurrent_async_tasks < MAX_CONCURRENT_ASYNC_TASKS_MIN or max_concurrent_async_tasks > MAX_CONCURRENT_ASYNC_TASKS_MAX:
		issues.append(
			"max_concurrent_async_tasks out of range [%s, %s], got %s -- clamped" %
			[MAX_CONCURRENT_ASYNC_TASKS_MIN, MAX_CONCURRENT_ASYNC_TASKS_MAX, max_concurrent_async_tasks]
		)
		max_concurrent_async_tasks = clampi(max_concurrent_async_tasks, MAX_CONCURRENT_ASYNC_TASKS_MIN, MAX_CONCURRENT_ASYNC_TASKS_MAX)
	if max_chunk_generation_cost_ms < CHUNK_GENERATION_COST_MS_MIN or max_chunk_generation_cost_ms > CHUNK_GENERATION_COST_MS_MAX:
		issues.append(
			"max_chunk_generation_cost_ms out of range [%s, %s], got %s -- clamped" %
			[CHUNK_GENERATION_COST_MS_MIN, CHUNK_GENERATION_COST_MS_MAX, max_chunk_generation_cost_ms]
		)
		max_chunk_generation_cost_ms = clampf(max_chunk_generation_cost_ms, CHUNK_GENERATION_COST_MS_MIN, CHUNK_GENERATION_COST_MS_MAX)
	if page_budget_ms < STREAM_BUDGET_MS_MIN or page_budget_ms > STREAM_BUDGET_MS_MAX:
		issues.append(
			"page_budget_ms out of range [%s, %s], got %s -- clamped" %
			[STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX, page_budget_ms]
		)
		page_budget_ms = clampf(page_budget_ms, STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX)
	if evict_budget_ms < STREAM_BUDGET_MS_MIN or evict_budget_ms > STREAM_BUDGET_MS_MAX:
		issues.append(
			"evict_budget_ms out of range [%s, %s], got %s -- clamped" %
			[STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX, evict_budget_ms]
		)
		evict_budget_ms = clampf(evict_budget_ms, STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX)
	if mesh_build_budget_ms < STREAM_BUDGET_MS_MIN or mesh_build_budget_ms > STREAM_BUDGET_MS_MAX:
		issues.append(
			"mesh_build_budget_ms out of range [%s, %s], got %s -- clamped" %
			[STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX, mesh_build_budget_ms]
		)
		mesh_build_budget_ms = clampf(mesh_build_budget_ms, STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX)
	if mesh_unload_budget_ms < STREAM_BUDGET_MS_MIN or mesh_unload_budget_ms > STREAM_BUDGET_MS_MAX:
		issues.append(
			"mesh_unload_budget_ms out of range [%s, %s], got %s -- clamped" %
			[STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX, mesh_unload_budget_ms]
		)
		mesh_unload_budget_ms = clampf(mesh_unload_budget_ms, STREAM_BUDGET_MS_MIN, STREAM_BUDGET_MS_MAX)
	if min_y > max_y:
		issues.append(ConfigResource.format_blocking(
			"min_y (%s) must be <= max_y (%s)" % [min_y, max_y]
		))
	issues.append_array(_validate_bands())
	return issues


## Band-boundary cross-value invariants (Story vox-022, GDD Core Rule 8 /
## TR-voxel-world-051, ADR-0002 two-tier policy) -- every check here is a
## relationship between fields (counts matching, monotonic ordering, id
## family membership, the id-1-stays-Lowland compatibility rule), so each
## violation is reported BLOCKING rather than clamped, the same tier
## [member min_y]/[member max_y]'s own relationship already uses: there is
## no single "nearest valid" band boundary or id to silently clamp to.
func _validate_bands() -> Array[String]:
	var issues: Array[String] = []
	if band_ids.is_empty():
		issues.append(ConfigResource.format_blocking("band_ids must not be empty"))
		return issues
	# DERIVATION MODE: an empty band_boundaries means "derive from
	# band_split_fractions" (see effective_band_boundaries). Validate the
	# fractions instead — the derived list is monotonic and in-range by
	# construction whenever they are, so the absolute checks below would be
	# checking arithmetic this class just performed on itself.
	if band_ids.size() == 1:
		# One band needs no split points at all — neither absolute boundaries
		# nor fractions. Checking either here would reject a perfectly valid
		# single-material world.
		pass
	elif band_boundaries.is_empty():
		if band_split_fractions.size() != band_ids.size() - 1:
			issues.append(ConfigResource.format_blocking(
				"band_split_fractions length (%s) must be exactly band_ids length (%s) minus one" %
				[band_split_fractions.size(), band_ids.size()]
			))
			return issues
		for i in band_split_fractions.size():
			if band_split_fractions[i] < 0.0 or band_split_fractions[i] > 1.0:
				issues.append(ConfigResource.format_blocking(
					"band_split_fractions[%s] (%s) must be within [0.0, 1.0]" %
					[i, band_split_fractions[i]]
				))
			if i > 0 and band_split_fractions[i] <= band_split_fractions[i - 1]:
				issues.append(ConfigResource.format_blocking(
					"band_split_fractions must be strictly increasing -- [%s] (%s) <= [%s] (%s)" %
					[i, band_split_fractions[i], i - 1, band_split_fractions[i - 1]]
				))
	elif band_boundaries.size() != band_ids.size() - 1:
		issues.append(ConfigResource.format_blocking(
			"band_boundaries length (%s) must be exactly band_ids length (%s) minus one" %
			[band_boundaries.size(), band_ids.size()]
		))
		return issues
	for i in band_boundaries.size() if not band_boundaries.is_empty() else 0:
		if band_boundaries[i] < min_y or band_boundaries[i] > max_y:
			issues.append(ConfigResource.format_blocking(
				"band_boundaries[%s] (%s) must be within [min_y, max_y] ([%s, %s])" %
				[i, band_boundaries[i], min_y, max_y]
			))
		if i > 0 and band_boundaries[i] <= band_boundaries[i - 1]:
			issues.append(ConfigResource.format_blocking(
				"band_boundaries must be strictly increasing -- band_boundaries[%s] (%s) <= band_boundaries[%s] (%s)" %
				[i, band_boundaries[i], i - 1, band_boundaries[i - 1]]
			))
	var seen_ids: Dictionary[int, bool] = {}
	for i in band_ids.size():
		var id: int = band_ids[i]
		if id < BAND_ID_MIN or id > BAND_ID_MAX:
			issues.append(ConfigResource.format_blocking(
				"band_ids[%s] (%s) must be within the dig-order-eligible [%s, %s] family (TR-voxel-world-051)" %
				[i, id, BAND_ID_MIN, BAND_ID_MAX]
			))
		if seen_ids.has(id):
			issues.append(ConfigResource.format_blocking(
				"band_ids[%s] (%s) duplicates an earlier entry" % [i, id]
			))
		seen_ids[id] = true
	if band_ids[0] != 1:
		issues.append(ConfigResource.format_blocking(
			"band_ids[0] (%s) must stay 1 -- the Lowland/lowest band's id is a compatibility constraint" %
			[band_ids[0]]
		))
	return issues
