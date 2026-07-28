## Story scene-005 (World genesis in the boot sequence) boot-budget
## re-measurement (AC-BOOT-BUDGET). vox-021's own evidence
## (`production/qa/evidence/boot-mesh-radius-boot-budget-20260726.md`)
## explicitly recorded nav-graph build and roster spawn as "0 ms /
## not-yet-wired-into-boot" because neither was reachable from
## `GameWorld`'s landed synchronous boot chain at that time. This story wires
## both in -- this tool re-measures honestly now that they are real costs.
##
## Two measurements, both WINDOWED, VSync OFF, against the REAL shipped
## `data/config/voxel_world_config.tres` / `villager_ai_config.tres` /
## `game_world_config.tres` (never hand-copied values):
## 1. **The REAL full boot** -- instantiates the production
##    `game_world.tscn` (the exact scene the shipped game boots), times the
##    single synchronous `add_child(world)` call end to end. This IS
##    boot-to-ACTIVE, unmodified production code, no isolation seams.
## 2. **Phase breakdown** -- vox-021's own tool proved isolated-primitive
##    measurement is the only way to attribute cost per phase (the real boot
##    above is one opaque number); this repeats that method, extended with
##    the two phases vox-021 could not measure: nav-graph build
##    ([VillagerNavGraph.build]) and roster spawn
##    ([VillagerRosterSpawner.select_starting_cells] +
##    [VillagerRosterSpawner.assemble_roster], the same primitives
##    [Valley.spawn_starting_roster] calls), run in [GameWorld]'s own
##    genesis order: residency -> nav-graph -> mesh window -> roster spawn
##    (camera set_target is a negligible field write, not separately timed).
##
## Run WINDOWED:
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel
##     res://tools/scene005_genesis_boot_budget_measurement.tscn
extends Node3D

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")
const EVIDENCE_DIR := "res://../production/qa/evidence"
const REPORT_LOG := "scene-005-boot-budget-raw.txt"

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

var _report_lines: Array[String] = []


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_log("scene005: VSync explicitly DISABLED (mandated methodology)")
	_setup_lighting_and_sky()
	_camera.current = true

	_measure_real_full_boot()
	_measure_phase_breakdown()

	_finish_and_quit()


func _measure_real_full_boot() -> void:
	# Mirrors the test suite's own established ordering exactly (assign the
	# mock BEFORE add_child, so GameWorld._ready()'s boot gate resolves
	# against the mock on the SAME frame add_child fires, never the real
	# ResourceItemDatabase Autoload -- avoids a double-boot or a missing-
	# dependency assert).
	var world: GameWorld = GameWorldScene.instantiate()
	var database := MockResourceItemDatabase.new()
	add_child(database)
	database.configure_ready_immediately()
	world.resource_item_database = database

	var start_usec: int = Time.get_ticks_usec()
	add_child(world)
	var total_ms: float = (Time.get_ticks_usec() - start_usec) / 1000.0
	_log("scene005: ==== REAL FULL BOOT (game_world.tscn, shipped configs) ====")
	_log("scene005: boot_state=%d (ACTIVE=%d) total_boot_to_active_ms=%.1f" % [
		world.get_boot_state(), GameWorld.BootState.ACTIVE, total_ms
	])
	var valley: Valley = world.get_valley() as Valley
	if valley != null:
		var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
		_log("scene005: resident_chunks=%d grid_state=%d(GENERATED=%d) villagers=%d" % [
			voxel_world.get_resident_chunk_keys().size(),
			voxel_world.get_state(), VoxelWorldGrid.GridState.GENERATED,
			valley.get_villagers().size(),
		])
	world.queue_free()
	database.queue_free()


func _measure_phase_breakdown() -> void:
	_log("scene005: ==== PHASE BREAKDOWN (isolated primitives, genesis order) ====")
	var config: VoxelWorldConfig = (load("res://data/config/voxel_world_config.tres") as VoxelWorldConfig).duplicate()
	config.region_directory = "user://scene005_phase_regions_%d" % Time.get_ticks_usec()

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

	var focus_cell: Vector3i = VillagerRosterSpawner.world_center_cell(config)

	# Phase 1 -- residency page-in, via the SAME two-part fixed-point drive
	# GameWorld._drive_boot_residency uses (never a bare "zero in flight"
	# check -- see that method's own doc comment for why).
	var residency_start_usec: int = Time.get_ticks_usec()
	_drive_boot_residency_like_genesis(grid, focus_cell, 3000.0)
	var residency_ms: float = (Time.get_ticks_usec() - residency_start_usec) / 1000.0
	_log("scene005: [phase 1] residency page-in: %.1f ms, %d chunks resident" % [residency_ms, grid.get_resident_chunk_keys().size()])

	# Phase 2 -- nav-graph build (VillagerAIConfig.nav_region_size, shipped
	# default), the phase vox-021's own tool could not measure.
	var villager_ai_config: VillagerAIConfig = load("res://data/config/villager_ai_config.tres") as VillagerAIConfig
	var predicate_source := VillagerAi.new()
	add_child(predicate_source)
	predicate_source.voxel_world = grid
	var nav_graph := VillagerNavGraph.new()
	var nav_start_usec: int = Time.get_ticks_usec()
	nav_graph.build(grid, predicate_source, focus_cell, villager_ai_config.nav_region_size)
	var nav_ms: float = (Time.get_ticks_usec() - nav_start_usec) / 1000.0
	_log("scene005: [phase 2] nav-graph build (nav_region_size=%d): %.1f ms, is_built=%s" % [
		villager_ai_config.nav_region_size, nav_ms, nav_graph.is_built()
	])

	# Phase 3 -- initial mesh window build (vox-021's own object of study,
	# unchanged by this story).
	var mesh_start_usec: int = Time.get_ticks_usec()
	streamer.build_initial_window(focus_cell)
	var mesh_ms: float = (Time.get_ticks_usec() - mesh_start_usec) / 1000.0
	_log("scene005: [phase 3] initial mesh window: %.1f ms, %d chunks tracked" % [mesh_ms, mesher.get_tracked_chunk_keys().size()])

	# Phase 4 -- roster spawn (starting_villager_count, shipped default),
	# the other phase vox-021's own tool could not measure.
	var scheduler := VillagerDecidingScheduler.new()
	var telemetry := VillagerUnstuckTelemetry.new()
	var roster_start_usec: int = Time.get_ticks_usec()
	var cells: Array[Vector3i] = VillagerRosterSpawner.select_starting_cells(
		grid, focus_cell, villager_ai_config.starting_villager_count
	)
	var roster: Array[VillagerAi] = VillagerRosterSpawner.assemble_roster(
		grid, villager_ai_config, scheduler, nav_graph, telemetry, cells, 1
	)
	for villager: VillagerAi in roster:
		add_child(villager)
		villager.setup()
	var roster_ms: float = (Time.get_ticks_usec() - roster_start_usec) / 1000.0
	_log("scene005: [phase 4] roster spawn (starting_villager_count=%d): %.1f ms, %d placed" % [
		villager_ai_config.starting_villager_count, roster_ms, roster.size()
	])

	var total_ms: float = residency_ms + nav_ms + mesh_ms + roster_ms
	_log("scene005: ==== PHASE TOTAL vs technical-director ceiling ====")
	_log("scene005: residency=%.1f nav_graph=%.1f mesh=%.1f roster=%.1f TOTAL=%.1f" % [
		residency_ms, nav_ms, mesh_ms, roster_ms, total_ms
	])
	_log("scene005: ceilings: mesh_phase<=2500.0 total<=3000.0 -- VERDICT=%s" % (
		"PASS" if (mesh_ms <= 2500.0 and total_ms <= 3000.0) else "MISS"
	))


## Mirrors [method GameWorld._drive_boot_residency]'s own two-part
## fixed-point termination exactly (see that method's doc comment) --
## included here, not called directly, since this tool constructs its own
## isolated [VoxelWorldGrid] rather than going through a live [GameWorld].
func _drive_boot_residency_like_genesis(grid: VoxelWorldGrid, focus: Vector3i, ceiling_ms: float) -> void:
	var start_usec: int = Time.get_ticks_usec()
	var ceiling_usec: int = int(ceiling_ms * 1000.0)
	var previous_resident_count: int = -1
	while true:
		grid.update_residency(focus, focus)
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		if elapsed_usec >= ceiling_usec:
			return
		grid.drain_pending_async_reads(maxi(1, int(float(ceiling_usec - elapsed_usec) / 1000.0)))
		var in_flight_count: int = grid.get_in_flight_async_task_count()
		var resident_count: int = grid.get_resident_chunk_keys().size()
		if in_flight_count == 0 and resident_count == previous_resident_count:
			return
		previous_resident_count = resident_count
		if (Time.get_ticks_usec() - start_usec) >= ceiling_usec:
			return


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
		print("scene005: saved %s" % path)
	get_tree().quit()
