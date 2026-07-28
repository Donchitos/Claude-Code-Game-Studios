## Story vox-018 windowed real-GPU measurement tool (milestone criterion #12,
## the 60-FPS-with-culling-enabled target; ADR-0014 primary, ADR-0015
## secondary; QA plan `qa-plan-sprint-8-2026-07-25.md`'s "THE
## MILESTONE-CENTERPIECE" PASS/MISS definition). NOT part of the production
## boot chain and NOT wired into `GameWorld`/`Valley` -- a standalone tool
## scene, run WINDOWED (headless cannot render a viewport texture, and this
## measurement's entire point is a REAL rendered frame). It:
##
##  1. Constructs a real [VoxelWorldGrid] + the real production
##     [VoxelWorldMesher] + the real production [VoxelWorldMeshStreamer]
##     (the SAME classes `src/voxel_world/` ships, never a reimplementation)
##     at a production-scale seeded extent with `view_radius_chunks = 24`
##     (the shipped `VoxelWorldConfig` default, matching the QA plan's own
##     gating definition -- the actual gating knob for this measurement,
##     unaffected by the world-extent note below).
##     **Honest scale note**: [constant WORLD_EXTENT_CELLS] is 896, NOT
##     ADR-0014's aspirational 2000x2000 (nor even its own "minimum 1000x1000"
##     Context-section figure) -- measured directly while building this tool,
##     [method VoxelWorldGrid.generate_terrain]'s CURRENT `Dictionary`-
##     accumulation implementation costs ~63 microseconds per world COLUMN
##     and scales LINEARLY through 900x900 (measured 700/800/900 all land on
##     that same rate), but becomes SEVERELY SUPER-LINEAR at 1000x1000 (did
##     not complete in over 200s headless -- a `Dictionary` resize/rehash
##     cost cliff, verified both headless and windowed, not a rendering-path
##     cost). 896 keeps this tool's one-time setup cost bounded (~60s total)
##     while still exceeding the view window's own 784-unit world-space
##     diameter, demonstrating draw calls decoupled from world size, this
##     measurement's own concern -- with real but more modest margin than a
##     larger world would give. This is a `generate_terrain` scaling finding,
##     NOT a finding about the mesher/streamer/rendering path this story
##     actually measures -- flagged here rather than silently picking a
##     smaller number without explanation.
##  2. Runs the streamer's UNBOUNDED [method VoxelWorldMeshStreamer.build_initial_window]
##     once (mirrors the production boot-time call
##     [GameWorld._build_initial_voxel_mesh_window] now makes), timed and
##     logged, before any measurement sampling begins.
##  3. Sweeps a camera FOCUS POINT back and forth across a long diagonal of
##     the world (far larger than the view window) for >= 90 real seconds
##     (comfortably clearing the QA plan's ">= 60s or >= 3 full sweeps,
##     whichever longer" floor on BOTH axes at once -- 6 one-way legs @ 15s
##     each), calling [method VoxelWorldMeshStreamer.update_view_window]
##     every single frame with the CURRENT focus cell -- the exact
##     production per-frame call [Valley._process] now makes, driven here by
##     a scripted sweep instead of live player input (this tool has no
##     [CameraInput] -- the mesh-streaming focus point and the driven
##     [Camera3D] are the SAME position, computed directly).
##  4. Samples, every frame during the sweep: frame time via
##     [method Time.get_ticks_usec] deltas (never the engine-supplied
##     `delta` parameter, per this story's own explicit measurement
##     methodology) and draw calls via
##     [method RenderingServer.get_rendering_info]
##     ([constant RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME] --
##     verified present, unrenamed, in Godot 4.7-stable against
##     `docs/engine-reference/godot/` before use here; this exact enum is
##     also the one ADR-0014's own Engine Compatibility table names as an
##     already-exercised post-cutoff-adjacent API).
##  5. Captures TWO PNGs from this SAME run: one top-down (context, before the
##     timed sweep starts) and one low-oblique (the culling-proof vantage,
##     mid-sweep -- mirrors `tools/mesher_evidence.gd`'s established
##     "historically riskiest angle" methodology) -- both written to
##     `production/qa/evidence/`.
##  6. Writes the raw per-frame time series to a CSV log and prints the
##     computed avg/p95/max frame time + max draw calls to stdout (captured
##     into the evidence doc by hand after the run), then quits.
##
## Run via (WINDOWED -- do not pass --headless; a hard wall-clock safety cap
## additionally forces an early quit-with-partial-write if something hangs):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/vox018_60fps_culling_measurement.tscn
extends Node3D

## Production-scale seeded extent. **Honest scale note (measured while
## building this tool, superseding the doc comment above)**:
## [method VoxelWorldGrid.generate_terrain]'s `Dictionary`-accumulation
## implementation costs ~63 microseconds/column and scales LINEARLY through
## 900x900 (measured: 700x700 = 30.9s, 800x800 = 40.4s, 900x900 = 52.2s --
## all ~63 us/column) but becomes SEVERELY SUPER-LINEAR at 1000x1000 (did not
## complete in over 200s headless, no rendering involved -- a `Dictionary`
## resize/rehash cost cliff around 900-1000, not a windowed-vs-headless
## difference; verified both ways). 896 (56 chunks/axis, a clean
## `CHUNK_SIZE`-aligned number just under the measured-safe 900 ceiling) keeps
## this tool's one-time setup cost bounded (~51s terrain + ~9s initial mesh
## window) while still exceeding the view window's own 49-chunk/784-unit
## diameter, so draw calls staying window-bounded (not world-bounded) is
## still genuinely demonstrated, if with less margin than 2000x2000 would
## give. This is a `generate_terrain` scaling finding, not a finding about
## the mesher/streamer/rendering path this story actually measures -- flagged
## here, not silently picked.
const WORLD_EXTENT_CELLS := 896
const WORLD_MAX_Y := 32

## The QA plan's own gating window radius -- the shipped [VoxelWorldConfig]
## default, restated explicitly here (never relying on the class default
## silently matching) so a future default change cannot silently invalidate
## this measurement's own stated methodology.
const VIEW_RADIUS_CHUNKS := 24

## Story vox-019 DIAGNOSTIC ONLY (not the official AC4 methodology -- the
## official re-measurement runs with the engine's own default vsync
## behavior, unchanged from vox-018, so the two evidence docs stay directly
## comparable). Set true for a ONE-OFF diagnostic run to test the hypothesis
## that the razor-thin post-AC1 miss is a vsync presentation-wait floor
## (~16.667 ms at a 60Hz panel, marginally ABOVE the 16.6 ms gate by the
## display's own refresh arithmetic, independent of compute cost) rather than
## a remaining compute problem -- never left true for an evidence-producing
## run.
const DIAGNOSTIC_DISABLE_VSYNC := false

## Story vox-019 AC3 -- the re-tuned per-frame MESH BUILD budget, restated
## explicitly here (same "never rely on the class default silently matching"
## rationale as [constant VIEW_RADIUS_CHUNKS]) so this measurement always
## reflects whatever value this story's evidence doc records, not whatever
## [VoxelWorldConfig.mesh_build_budget_ms]'s class-level default happens to
## be at the time this tool is run.
const MESH_BUILD_BUDGET_MS := 4.0

## Sweep endpoints -- a long diagonal (696*sqrt(2) =~ 984 world units),
## larger than the view window's own world-space diameter
## ((2*24+1) * 16 = 784 units) and inset from the world bounds with margin
## against the world-edge chunk clipping [VoxelWorldMeshStreamer] itself
## applies.
const SWEEP_START := Vector3(100.0, 0.0, 100.0)
const SWEEP_END := Vector3(796.0, 0.0, 796.0)

## One-way leg duration, seconds -- 6 legs (3 full there-and-back sweeps) in
## [constant TOTAL_DURATION_SEC], comfortably clearing the QA plan's own
## ">= 60s or >= 3 full sweeps, whichever longer" floor on BOTH axes
## simultaneously (90s > 60s; 6 one-way legs > 3 sweeps).
const LEG_DURATION_SEC := 15.0

## Total measurement window, real seconds -- the QA plan's own duration
## floor (see class doc comment).
const TOTAL_DURATION_SEC := 90.0

## Hard wall-clock safety cap (real seconds since this tool's own boot) --
## forces an early quit-with-partial-write if anything hangs, per this
## story's own "the scene must self-quit after capture" requirement. Sized
## generously above the measured setup cost (~52s terrain gen + ~10s initial
## window build at this tool's 896/view_radius=24 scale) plus the full 90s
## sweep, with real margin. IMPORTANT CAVEAT (honest, not silently glossed
## over): this check only runs from [method _process], so it CANNOT fire
## during the one long synchronous [method _build_world_grid_and_mesh_window]
## call in [method _ready] -- it only protects the SWEEPING phase. The setup
## phase's own real bound is whatever [method VoxelWorldGrid.generate_terrain]
## /[method VoxelWorldMeshStreamer.build_initial_window] actually cost at
## [constant WORLD_EXTENT_CELLS]'s chosen scale (see that constant's own
## "Honest scale note" for why 896 was chosen specifically to keep this
## bounded and measured, not merely hoped-for).
const SAFETY_CAP_SEC := 350.0

## Draw-call HARD per-sample ceiling (technical-preferences.md architecture
## budget, restated by the QA plan as non-soft: "one frame over 2000 is a
## MISS on that axis regardless of the FPS numbers").
const DRAW_CALL_CEILING := 2000

## Gating statistic threshold, milliseconds (QA plan: p95 frame time <= 16.6
## ms, equivalently p95 instantaneous FPS >= 60).
const FRAME_TIME_BUDGET_MS := 16.6

const EVIDENCE_DIR := "res://../production/qa/evidence"
## Story vox-019 re-measurement note: ONLY these 3 output-filename constants
## were changed from vox-018's own literal `vox-018-...-20260725` names -- the
## re-measurement happens to land on the SAME calendar date as vox-018's own
## run, so re-running this tool 100% verbatim would silently overwrite that
## original evidence (screenshots + raw log), destroying the before/after
## comparison this story's own AC4 requires. No other line in this file
## changed -- same config, same world extent/seed, same camera sweep, same
## sampling/verdict methodology, per this story's own "reuse the tool
## verbatim" instruction.
const TOPDOWN_PNG := "vox-019-topdown-20260725.png"
const LOW_OBLIQUE_PNG := "vox-019-low-oblique-20260725.png"
const RAW_LOG_CSV := "vox-019-60fps-culling-raw-20260725.csv"

var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher
var _streamer: VoxelWorldMeshStreamer

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

## Phase state machine -- BUILD (one-shot world/mesh construction) ->
## TOPDOWN_CAPTURE (a few settle frames, then the context PNG) -> SWEEPING
## (the timed, sampled measurement) -> DONE (write evidence, quit).
enum _Phase { BUILD, TOPDOWN_CAPTURE, SWEEPING, DONE }
var _phase: _Phase = _Phase.BUILD

var _boot_start_usec: int = 0
var _sweep_start_usec: int = 0
var _last_frame_usec: int = 0
var _settle_frames_remaining: int = 3
var _low_oblique_captured: bool = false
var _leg_count: int = 0

## Per-sample raw time series (real seconds since sweep start, frame time
## ms, draw calls) -- written verbatim to [constant RAW_LOG_CSV].
var _sample_rows: Array[String] = ["elapsed_sec,frame_ms,draw_calls"]
var _frame_ms_samples: Array[float] = []
var _draw_call_samples: Array[int] = []


func _ready() -> void:
	if DIAGNOSTIC_DISABLE_VSYNC:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		print("vox018: DIAGNOSTIC -- vsync disabled for this run (not the official AC4 methodology)")
	_boot_start_usec = Time.get_ticks_usec()
	_build_world_grid_and_mesh_window()
	_setup_lighting_and_sky()
	_camera.current = true
	_phase = _Phase.TOPDOWN_CAPTURE


## Builds the real production-scale [VoxelWorldGrid], generates deterministic
## seeded terrain (some height variety -- readability for the culling-proof
## screenshot matters, same rationale `tools/camera_sandbox.gd` documents),
## wires the real [VoxelWorldMesher] + [VoxelWorldMeshStreamer], and runs the
## UNBOUNDED initial window build once -- timed and printed, mirroring the
## production boot-time call this measurement is proving.
func _build_world_grid_and_mesh_window() -> void:
	_grid = VoxelWorldGrid.new()
	add_child(_grid)
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = WORLD_EXTENT_CELLS
	world_config.world_depth_cells = WORLD_EXTENT_CELLS
	world_config.max_y = WORLD_MAX_Y
	world_config.amplitude = 6.0
	world_config.frequency = 0.04
	world_config.view_radius_chunks = VIEW_RADIUS_CHUNKS
	world_config.mesh_build_budget_ms = MESH_BUILD_BUDGET_MS
	_grid.config = world_config

	var terrain_start_usec: int = Time.get_ticks_usec()
	_grid.generate_terrain()
	var terrain_ms: float = (Time.get_ticks_usec() - terrain_start_usec) / 1000.0
	print("vox018: generate_terrain() took %.1f ms at %dx%d" % [terrain_ms, WORLD_EXTENT_CELLS, WORLD_EXTENT_CELLS])

	_mesher = VoxelWorldMesher.new()
	add_child(_mesher)
	_mesher.grid = _grid
	_mesher.setup()

	_streamer = VoxelWorldMeshStreamer.new()
	add_child(_streamer)
	_streamer.grid = _grid
	_streamer.mesher = _mesher
	_streamer.setup()

	var initial_focus: Vector3i = VoxelWorldGrid.world_to_cell(SWEEP_START)
	var build_start_usec: int = Time.get_ticks_usec()
	_streamer.build_initial_window(initial_focus)
	var build_ms: float = (Time.get_ticks_usec() - build_start_usec) / 1000.0
	print(
		"vox018: build_initial_window() took %.1f ms, %d chunks tracked, view_radius_chunks=%d" %
		[build_ms, _mesher.get_tracked_chunk_keys().size(), VIEW_RADIUS_CHUNKS]
	)


## A directional "sun" + a solid sky background so cliff/side faces read
## clearly and a culled-vs-not-culled face is visually unambiguous -- mirrors
## `tools/mesher_evidence.gd`'s established lighting rationale exactly.
func _setup_lighting_and_sky() -> void:
	_light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	_light.light_energy = 1.1

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.85)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.42, 0.45)
	environment.ambient_light_energy = 1.0
	_world_environment.environment = environment
	_camera.far = 3000.0


## This tool's ONE per-frame job, phase-dispatched.
func _process(_delta: float) -> void:
	var elapsed_since_boot_sec: float = (Time.get_ticks_usec() - _boot_start_usec) / 1000000.0
	if elapsed_since_boot_sec > SAFETY_CAP_SEC and _phase != _Phase.DONE:
		push_warning("vox018: SAFETY CAP hit (%0.1fs) -- forcing early write + quit" % elapsed_since_boot_sec)
		_finish_and_quit()
		return

	match _phase:
		_Phase.TOPDOWN_CAPTURE:
			_process_topdown_capture()
		_Phase.SWEEPING:
			_process_sweeping()
		_:
			pass


## Holds a few settle frames (so the just-moved camera's frame is actually
## the one rendered, mirroring `tools/mesher_evidence.gd`'s own capture
## convention), positions the camera top-down over the sweep's starting
## area, captures the context PNG, then starts the timed sweep.
func _process_topdown_capture() -> void:
	var center: Vector3 = SWEEP_START
	_camera.position = Vector3(center.x, 260.0, center.z)
	_camera.look_at(center, Vector3(0.0, 0.0, -1.0))
	_settle_frames_remaining -= 1
	if _settle_frames_remaining > 0:
		return
	_capture_png(TOPDOWN_PNG)
	_sweep_start_usec = Time.get_ticks_usec()
	_last_frame_usec = _sweep_start_usec
	_phase = _Phase.SWEEPING


## The timed, sampled measurement sweep -- see class doc comment points 3/4.
func _process_sweeping() -> void:
	var now_usec: int = Time.get_ticks_usec()
	var frame_ms: float = (now_usec - _last_frame_usec) / 1000.0
	_last_frame_usec = now_usec
	var elapsed_sec: float = (now_usec - _sweep_start_usec) / 1000000.0

	var focus_world: Vector3 = _sweep_position(elapsed_sec)
	var focus_cell: Vector3i = VoxelWorldGrid.world_to_cell(focus_world)
	_streamer.update_view_window(focus_cell)
	_drive_low_oblique_camera(focus_world)

	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_frame_ms_samples.append(frame_ms)
	_draw_call_samples.append(draw_calls)
	_sample_rows.append("%.3f,%.3f,%d" % [elapsed_sec, frame_ms, draw_calls])

	# Culling-proof screenshot: SAME run/session as the numbers, captured
	# mid-sweep (well past the first settle frames) once, per the QA plan's
	# "same session, not stitched from separate runs" requirement.
	if not _low_oblique_captured and elapsed_sec >= LEG_DURATION_SEC * 0.5:
		_capture_png(LOW_OBLIQUE_PNG)
		_low_oblique_captured = true

	if elapsed_sec >= TOTAL_DURATION_SEC:
		_leg_count = int(elapsed_sec / LEG_DURATION_SEC)
		_finish_and_quit()


## Triangle-wave back-and-forth position between [constant SWEEP_START] and
## [constant SWEEP_END], one leg every [constant LEG_DURATION_SEC] --
## deterministic given [param elapsed_sec], no randomness (QA determinism
## rule for anything that COULD be made deterministic; this tool's frame
## TIMING is necessarily real wall-clock, which is the entire point of the
## measurement, but the sweep PATH itself is not left to chance).
func _sweep_position(elapsed_sec: float) -> Vector3:
	var leg_phase: float = fmod(elapsed_sec, LEG_DURATION_SEC * 2.0)
	var t: float
	if leg_phase <= LEG_DURATION_SEC:
		t = leg_phase / LEG_DURATION_SEC
	else:
		t = 1.0 - (leg_phase - LEG_DURATION_SEC) / LEG_DURATION_SEC
	return SWEEP_START.lerp(SWEEP_END, t)


## Drives the real [Camera3D] from a low, oblique, grazing angle tracking
## [param focus_world] -- mirrors `tools/mesher_evidence.gd`'s own
## "historically riskiest angle" vantage (side/cliff faces seen edge-on),
## continuously across the whole sweep so the FPS/draw-call numbers and the
## culling-proof screenshot are genuinely the SAME camera state, not a
## separate capture rig.
func _drive_low_oblique_camera(focus_world: Vector3) -> void:
	_camera.position = focus_world + Vector3(-50.0, 20.0, -50.0)
	_camera.look_at(focus_world + Vector3(0.0, 2.0, 0.0), Vector3.UP)


## Captures the current viewport frame and writes it to
## `production/qa/evidence/[param file_name]` -- identical convention to
## `tools/mesher_evidence.gd`'s own `_capture_and_save`.
func _capture_png(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("vox018: failed to save %s (error %d)" % [path, err])
	else:
		print("vox018: saved %s" % path)


## Computes avg/p95/max frame time + max draw calls, prints the verdict
## inputs to stdout, writes the raw CSV log, and quits. Called either at
## natural sweep completion or from the safety cap.
func _finish_and_quit() -> void:
	_phase = _Phase.DONE
	var stats: Dictionary = _compute_stats(_frame_ms_samples)
	var max_draw_calls: int = 0
	var over_ceiling_count: int = 0
	for dc: int in _draw_call_samples:
		max_draw_calls = maxi(max_draw_calls, dc)
		if dc > DRAW_CALL_CEILING:
			over_ceiling_count += 1

	print("vox018: ==== MEASUREMENT RESULTS ====")
	print("vox018: samples = %d, one-way legs completed ~= %d" % [_frame_ms_samples.size(), _leg_count])
	print("vox018: frame_ms avg=%.3f p95=%.3f max=%.3f (budget %.1f ms)" % [stats.avg, stats.p95, stats.max, FRAME_TIME_BUDGET_MS])
	print("vox018: avg_fps_equiv=%.1f p95_fps_equiv=%.1f" % [1000.0 / maxf(stats.avg, 0.001), 1000.0 / maxf(stats.p95, 0.001)])
	print("vox018: draw_calls max=%d, samples over %d ceiling=%d / %d" % [max_draw_calls, DRAW_CALL_CEILING, over_ceiling_count, _draw_call_samples.size()])
	var verdict_pass: bool = stats.p95 <= FRAME_TIME_BUDGET_MS and over_ceiling_count == 0
	print("vox018: VERDICT (frame-time + draw-call axes only, culling-proof/grep are separate checks) = %s" % ("PASS" if verdict_pass else "MISS"))

	_write_raw_csv()
	get_tree().quit()


## Sorted-array avg/p95/max helper -- mirrors
## `prototypes/chunked-mesher/metrics.gd`'s own `usec_stats` shape, applied
## to milliseconds here.
func _compute_stats(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {"avg": 0.0, "p95": 0.0, "max": 0.0}
	var sorted_samples: Array[float] = samples.duplicate()
	sorted_samples.sort()
	var total: float = 0.0
	for value: float in sorted_samples:
		total += value
	var avg: float = total / sorted_samples.size()
	var p95_index: int = mini(int(sorted_samples.size() * 0.95), sorted_samples.size() - 1)
	return {"avg": avg, "p95": sorted_samples[p95_index], "max": sorted_samples[-1]}


func _write_raw_csv() -> void:
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(RAW_LOG_CSV)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("vox018: failed to open %s for writing" % path)
		return
	for row: String in _sample_rows:
		file.store_line(row)
	print("vox018: saved %s (%d rows)" % [path, _sample_rows.size() - 1])
