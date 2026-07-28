## Story vox-021 boot-to-ACTIVE budget measurement tool (TD ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md` Addendum D
## / D2; ADR-0014 amendment §3; QA plan's AC-BOOT-BUDGET-3S). Reuses the
## vox-018/vox-019 measurement tool's methodology verbatim (real production
## classes, WINDOWED, self-quit, printed stats + raw log + PNG evidence,
## `Time.get_ticks_usec()` deltas around real calls) -- adapted here to a
## BOOT-TIME phase-split measurement instead of vox-018/019's own 90 s
## FPS/draw-call sweep, per this story's own scope.
##
## **Why this tool does NOT call [method VoxelWorldGrid.generate_terrain]**
## (unlike `tools/vox018_60fps_culling_measurement.gd`): that method is a
## full-world eager `Dictionary`-accumulation precompute, measured by that
## tool's own class doc comment to become SEVERELY SUPER-LINEAR above
## ~900x900 cells (did not complete in 200s+ at 1000x1000) -- entirely
## impractical at this story's own "shipped 2000x2000 config" mandate. It is
## also NOT what production boot would ever do: `Valley.gd`'s own class doc
## comment states outright "no `generate_terrain()` call anywhere in the boot
## chain" -- Valley boots with an EMPTY grid; real terrain arrives ONLY
## through the RESIDENCY tier's async, budgeted, per-chunk regen-on-page-in
## (ADR-0015). `tools/vox016_residency_tuning_measurement.gd`'s own class doc
## comment makes exactly this same point when explaining why IT can run the
## full 2000x2000 default directly: "residency's per-chunk regen-on-page-in
## is the ENTIRE mechanism under test, so the full 2000 production default is
## usable directly with no scaling caveat." This tool follows that same
## precedent -- [method VoxelWorldGrid.update_residency] +
## [method VoxelWorldGrid.wait_for_async_residency_idle] populate the boot
## window's real terrain data, bounded by the WINDOW radius, never by total
## world size.
##
## **Honest phase-scope note (not silently narrowed)**: the AC's own phase
## list names "residency page-in / nav-graph build / initial mesh window /
## roster spawn." As landed on `main` at the time this story runs (confirmed
## against `src/scene_world_management/game_world.gd` /
## `src/scene_world_management/valley.gd`), `GameWorld`'s ACTUAL synchronous
## boot chain calls NEITHER [method VillagerNavGraph.build] NOR
## [method Valley.spawn_starting_roster] -- both are documented as
## DELIBERATELY deferred to "a future world-generation story" (`valley.gd`'s
## own Story villager-ai-021 scope note), since a fresh grid has no terrain
## yet at `_ready()` time. This story's own Out-of-Scope section names
## `nav_region_size` as `scene-005`'s lever, not this one's. Measuring phases
## that do not exist in the landed synchronous boot path would manufacture a
## number, which this story's own control manifest forbids -- so this tool
## measures the two phases that DO exist and that this story's own knobs
## govern: residency page-in (for the boot window) and the initial mesh
## window build (`boot_mesh_radius_chunks`). Nav-graph build and roster spawn
## are recorded as 0 ms / not-yet-wired-into-boot in the evidence doc, named
## explicitly rather than silently omitted.
##
## Run WINDOWED (VSync OFF is this story's own mandated methodology,
## restated explicitly rather than relying on the engine default -- though,
## unlike vox-018/019's per-FRAME FPS sweep, VSync does NOT affect this
## tool's own numbers: every timed phase here is a SYNCHRONOUS, non-yielding
## method call measured by [method Time.get_ticks_usec] deltas, never a
## per-frame presentation wait):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel
##     res://tools/vox021_boot_budget_measurement.tscn
extends Node3D

## The shipped production config, loaded directly (never hand-copied values)
## so this measurement can never silently drift from whatever
## `data/config/voxel_world_config.tres` actually ships -- the same "never
## rely on a default silently matching" discipline `tools/vox016_residency_
## tuning_measurement.gd`/`tools/vox018_60fps_culling_measurement.gd` both
## already established, taken one step further here (loaded, not restated).
const SHIPPED_CONFIG_PATH := "res://data/config/voxel_world_config.tres"

## Ceiling this story's own D2 ruling sets (Addendum D / D2 §5).
const TOTAL_BOOT_CEILING_MS := 3000.0
const MESH_PHASE_CEILING_MS := 2500.0

## The one named remediation lever (D2 §5 / AC-BOOT-BUDGET-3S "on MISS")
## applied ONCE if the first measurement misses either ceiling.
const FALLBACK_BOOT_RADIUS := 6

## Generous residency-settle cap -- real seconds, not the API's own default
## 2000 ms (`wait_for_async_residency_idle`'s own default), since a
## from-scratch page-in of the full `view_radius_chunks` window (625 chunks
## at the shipped default) is a real measurement subject here, not a value
## to race past.
const RESIDENCY_SETTLE_CAP_MSEC := 60000

const EVIDENCE_DIR := "res://../production/qa/evidence"
const TOPDOWN_PNG := "vox-021-boot-radius12-topdown-20260726.png"
const OBLIQUE_PNG := "vox-021-boot-radius12-oblique-20260726.png"
const REPORT_LOG := "vox-021-boot-budget-raw-20260726.txt"

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

var _report_lines: Array[String] = []
var _settle_frames_remaining: int = 3
var _capture_focus_world: Vector3 = Vector3.ZERO
enum _Phase { MEASURE, TOPDOWN_SETTLE, OBLIQUE_SETTLE, DONE }
var _phase: _Phase = _Phase.MEASURE


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_log("vox021: VSync explicitly DISABLED (this story's mandated methodology; does not affect the synchronous-call timings below, recorded for compliance)")
	_setup_lighting_and_sky()
	_camera.current = true

	var result: Dictionary = _run_measurement(8, "vox021_boot_regions_primary")
	var mesh_ms: float = result["mesh_ms"]
	var total_ms: float = result["residency_ms"] + result["mesh_ms"]
	var verdict_pass: bool = mesh_ms <= MESH_PHASE_CEILING_MS and total_ms <= TOTAL_BOOT_CEILING_MS
	_log("vox021: ==== PRIMARY VERDICT (boot_mesh_radius_chunks=8, shipped default) ====")
	_log("vox021: residency_page_in_ms=%.1f mesh_window_ms=%.1f total_boot_ms=%.1f" % [result["residency_ms"], mesh_ms, total_ms])
	_log("vox021: ceilings: mesh_phase<=%.1f total<=%.1f" % [MESH_PHASE_CEILING_MS, TOTAL_BOOT_CEILING_MS])
	_log("vox021: VERDICT = %s" % ("PASS" if verdict_pass else "MISS"))

	_capture_focus_world = result["focus_world"]
	var grid_for_screenshot: VoxelWorldGrid = result["grid"]
	var mesher_for_screenshot: VoxelWorldMesher = result["mesher"]
	var streamer_for_screenshot: VoxelWorldMeshStreamer = result["streamer"]

	if not verdict_pass:
		_log("vox021: MISS -- applying the ONE named lever (boot_mesh_radius_chunks 8 -> %d), re-measuring ONCE" % FALLBACK_BOOT_RADIUS)
		var fallback_result: Dictionary = _run_measurement(FALLBACK_BOOT_RADIUS, "vox021_boot_regions_fallback")
		var fb_mesh_ms: float = fallback_result["mesh_ms"]
		var fb_total_ms: float = fallback_result["residency_ms"] + fallback_result["mesh_ms"]
		var fb_pass: bool = fb_mesh_ms <= MESH_PHASE_CEILING_MS and fb_total_ms <= TOTAL_BOOT_CEILING_MS
		_log("vox021: ==== FALLBACK VERDICT (boot_mesh_radius_chunks=%d) ====" % FALLBACK_BOOT_RADIUS)
		_log("vox021: residency_page_in_ms=%.1f mesh_window_ms=%.1f total_boot_ms=%.1f" % [fallback_result["residency_ms"], fb_mesh_ms, fb_total_ms])
		_log("vox021: VERDICT = %s" % ("PASS" if fb_pass else "MISS -- escalate to technical-director, per this story's own AC"))
		grid_for_screenshot.queue_free()
		mesher_for_screenshot.queue_free()
		streamer_for_screenshot.queue_free()
		grid_for_screenshot = fallback_result["grid"]
		mesher_for_screenshot = fallback_result["mesher"]
		streamer_for_screenshot = fallback_result["streamer"]
		_capture_focus_world = fallback_result["focus_world"]

	_log("vox021: ---- honest phase-scope note ----")
	_log("vox021: nav-graph build (VillagerNavGraph.build()) and roster spawn (Valley.spawn_starting_roster()) contribute 0 ms -- NEITHER is called from GameWorld's landed synchronous boot chain today (both deliberately deferred to a future world-generation story, per valley.gd's own doc comments); not fabricated here.")

	# AC-EXTENT-EVIDENCE: grow the SAME window to the full steady-state
	# (view_radius_chunks) radius for the screenshot only -- explicitly NOT
	# part of the timed boot phase above. Residency already paged in the
	# FULL view_radius_chunks window (update_residency's own desired-window
	# math uses view_radius_chunks, independent of boot_mesh_radius_chunks --
	# see this file's own class doc comment), so only the additional mesh
	# ring needs building here, unbounded, for a representative screenshot.
	var steady_radius: int = grid_for_screenshot.config.view_radius_chunks
	grid_for_screenshot.config.boot_mesh_radius_chunks = steady_radius
	var grow_start_usec: int = Time.get_ticks_usec()
	streamer_for_screenshot.build_initial_window(VoxelWorldGrid.world_to_cell(_capture_focus_world))
	var grow_ms: float = (Time.get_ticks_usec() - grow_start_usec) / 1000.0
	_log("vox021: (POST-MEASUREMENT, NOT part of the timed boot phase) grew mesh window to the full steady-state radius=%d for the AC-EXTENT-EVIDENCE screenshot in %.1f ms, %d chunks tracked" % [steady_radius, grow_ms, mesher_for_screenshot.get_tracked_chunk_keys().size()])

	_phase = _Phase.TOPDOWN_SETTLE


func _run_measurement(boot_radius: int, region_dir_suffix: String) -> Dictionary:
	var config: VoxelWorldConfig = (load(SHIPPED_CONFIG_PATH) as VoxelWorldConfig).duplicate()
	config.region_directory = "user://%s_%d" % [region_dir_suffix, Time.get_ticks_usec()]
	config.boot_mesh_radius_chunks = boot_radius
	_log("vox021: config -- world=%dx%d view_radius_chunks=%d boot_mesh_radius_chunks=%d region_directory=%s" % [
		config.world_width_cells, config.world_depth_cells, config.view_radius_chunks, config.boot_mesh_radius_chunks, config.region_directory
	])

	var grid := VoxelWorldGrid.new()
	add_child(grid)
	grid.config = config

	var mesher := VoxelWorldMesher.new()
	add_child(mesher)
	mesher.grid = grid
	mesher.setup()

	var streamer := VoxelWorldMeshStreamer.new()
	add_child(streamer)
	streamer.grid = grid
	streamer.mesher = mesher
	streamer.setup()

	var focus_cell := Vector3i(config.world_width_cells / 2, 0, config.world_depth_cells / 2)
	var focus_world: Vector3 = VoxelWorldGrid.cell_to_world(focus_cell)

	# Phase 1 -- residency page-in (the real ADR-0015 async mechanism, bounded
	# by the WINDOW, not by world size -- see class doc comment).
	var residency_start_usec: int = Time.get_ticks_usec()
	grid.update_residency(focus_cell, focus_cell)
	grid.wait_for_async_residency_idle(RESIDENCY_SETTLE_CAP_MSEC)
	var residency_ms: float = (Time.get_ticks_usec() - residency_start_usec) / 1000.0
	_log("vox021: [boot_mesh_radius_chunks=%d] residency page-in: %.1f ms, %d chunks resident" % [boot_radius, residency_ms, grid.get_resident_chunk_keys().size()])

	# Phase 2 -- initial mesh window build (THIS story's own object of study).
	var mesh_start_usec: int = Time.get_ticks_usec()
	streamer.build_initial_window(focus_cell)
	var mesh_ms: float = (Time.get_ticks_usec() - mesh_start_usec) / 1000.0
	_log("vox021: [boot_mesh_radius_chunks=%d] initial mesh window: %.1f ms, %d chunks tracked" % [boot_radius, mesh_ms, mesher.get_tracked_chunk_keys().size()])

	return {
		"grid": grid, "mesher": mesher, "streamer": streamer,
		"residency_ms": residency_ms, "mesh_ms": mesh_ms, "focus_world": focus_world,
	}


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


## Settle-then-capture phase machine, mirroring `tools/vox018_60fps_culling_
## measurement.gd`'s own established capture convention -- top-down (context)
## then a low-oblique "settlement camera distance" vantage (AC-EXTENT-EVIDENCE),
## both from this SAME session as the printed numbers above, then quit.
func _process(_delta: float) -> void:
	match _phase:
		_Phase.TOPDOWN_SETTLE:
			# Height and FOV chosen so the WHOLE radius-12 extent
			# (visibility_range_end = 192 world units, derived) stays within
			# the mesh's own distance-culling range from this camera position
			# -- a camera farther than 192 units from the terrain would see
			# nothing at all (vox-018's own topdown height of 260 assumed the
			# OLD radius-24/384-unit fade and would cull everything here).
			_camera.fov = 100.0
			_camera.position = Vector3(_capture_focus_world.x, 180.0, _capture_focus_world.z)
			_camera.look_at(_capture_focus_world, Vector3(0.0, 0.0, -1.0))
			_settle_frames_remaining -= 1
			if _settle_frames_remaining <= 0:
				_capture_png(TOPDOWN_PNG)
				_settle_frames_remaining = 3
				_phase = _Phase.OBLIQUE_SETTLE
		_Phase.OBLIQUE_SETTLE:
			# "Settlement camera distance" vantage -- a modest oblique
			# elevation showing the radius-12 (192-unit) extent at a glance,
			# kept within the same visibility_range_end distance budget
			# (offset magnitude ~158 units from focus, safely under 192).
			_camera.fov = 90.0
			_camera.position = _capture_focus_world + Vector3(-100.0, 70.0, -100.0)
			_camera.look_at(_capture_focus_world + Vector3(0.0, 2.0, 0.0), Vector3.UP)
			_settle_frames_remaining -= 1
			if _settle_frames_remaining <= 0:
				_capture_png(OBLIQUE_PNG)
				_phase = _Phase.DONE
				_finish_and_quit()
		_:
			pass


func _capture_png(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("vox021: failed to save %s (error %d)" % [path, err])
	else:
		_log("vox021: saved %s" % path)


func _log(message: String) -> void:
	print(message)
	_report_lines.append(message)


func _finish_and_quit() -> void:
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(REPORT_LOG)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		for line: String in _report_lines:
			file.store_line(line)
		print("vox021: saved %s" % path)
	get_tree().quit()
