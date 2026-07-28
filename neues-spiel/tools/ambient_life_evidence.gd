## Story presentation-001 Sub-scope A screenshot-evidence capture tool
## (ambient life wave 1: chimney smoke, foliage sway, interior clutter,
## torch/lantern flicker). NOT part of the production boot chain and NOT
## wired into `GameWorld`/`Valley` -- a standalone tool scene, run WINDOWED
## (headless cannot render a viewport texture), mirroring
## `tools/mesher_evidence.gd`'s established pattern exactly: real production
## classes, a fixed deterministic extent, captured vantages written to
## `production/qa/evidence/`.
##
## Captures, in order:
##  1. Two [ChimneySmokeEmitter] instances side by side over a small terrain
##     patch -- one `set_occupied_lit(true)`, one `false` -- proving the
##     "nobody home" tell (AC-A smoke).
##  2. A small patch of foliage_sway-shaded quads, captured at two different
##     elapsed times so the sway is visible across frames (AC-A foliage).
##  3. An [InteriorClutterPlacer] room of static placeholder props (AC-A
##     clutter).
##  4. A fixed torch + a carried-lantern stand-in, each driven by
##     [TorchFlicker], captured at two different elapsed times with their
##     sampled `light_energy` printed to the log (AC-A torch flicker -- the
##     BINDING sub-3Hz proof is the automated
##     `tests/unit/presentation/torch_flicker_test.gd` zero-crossing
##     measurement; these screenshots are the companion visual evidence the
##     story's Test Evidence section calls for).
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64.exe --path neues-spiel res://tools/ambient_life_evidence.tscn
extends Node3D

const WORLD_EXTENT_CELLS := 32

const EVIDENCE_FILE_NAMES: Dictionary[String, String] = {
	"smoke": "presentation-001-suba-smoke-occupied-vs-empty-20260724-1.png",
	"foliage_1": "presentation-001-suba-foliage-sway-20260724-1.png",
	"foliage_2": "presentation-001-suba-foliage-sway-20260724-2.png",
	"clutter": "presentation-001-suba-interior-clutter-20260724-1.png",
	"torch_1": "presentation-001-suba-torch-flicker-20260724-1.png",
	"torch_2": "presentation-001-suba-torch-flicker-20260724-2.png",
}

var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher
var _config: AmbientLifeConfig

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_config = AmbientLifeConfig.new()
	_config.validate()
	_build_and_mesh_world()
	_setup_lighting_and_sky()
	await _run_capture_sequence()


## Builds a small real [VoxelWorldGrid] + [VoxelWorldMesher] terrain patch --
## mirrors `tools/mesher_evidence.gd`'s established construction precedent --
## purely as a readable ground plane for the ambient-life elements above it.
func _build_and_mesh_world() -> void:
	_grid = VoxelWorldGrid.new()
	add_child(_grid)
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = WORLD_EXTENT_CELLS
	world_config.world_depth_cells = WORLD_EXTENT_CELLS
	_grid.config = world_config
	_grid.generate_terrain()

	_mesher = VoxelWorldMesher.new()
	add_child(_mesher)
	_mesher.grid = _grid
	_mesher.setup()

	var chunk_span: int = WORLD_EXTENT_CELLS / VoxelWorldGrid.CHUNK_SIZE
	for chunk_x in chunk_span:
		for chunk_z in chunk_span:
			_mesher.build_chunk(Vector2i(chunk_x, chunk_z))


func _setup_lighting_and_sky() -> void:
	_light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	_light.light_energy = 1.1

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.85)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.35, 0.4)
	environment.ambient_light_energy = 1.0
	_world_environment.environment = environment


func _run_capture_sequence() -> void:
	_camera.current = true
	await _capture_smoke_vantage()
	await _capture_foliage_vantage()
	await _capture_clutter_vantage()
	await _capture_torch_vantage()
	get_tree().quit()


## AC-A smoke: two [ChimneySmokeEmitter] instances side by side, one lit/
## occupied, one not -- proving the "nobody home" tell reads.
func _capture_smoke_vantage() -> void:
	var occupied_hut: Node3D = _build_placeholder_hut(Vector3(4.0, 0.0, 16.0))
	var empty_hut: Node3D = _build_placeholder_hut(Vector3(12.0, 0.0, 16.0))
	add_child(occupied_hut)
	add_child(empty_hut)

	var occupied_emitter := ChimneySmokeEmitter.new()
	occupied_emitter.config = _config
	occupied_emitter.position = Vector3(4.0, 3.2, 16.0)
	add_child(occupied_emitter)
	occupied_emitter.setup()
	occupied_emitter.set_occupied_lit(true)

	var empty_emitter := ChimneySmokeEmitter.new()
	empty_emitter.config = _config
	empty_emitter.position = Vector3(12.0, 3.2, 16.0)
	add_child(empty_emitter)
	empty_emitter.setup()
	empty_emitter.set_occupied_lit(false)

	_camera.position = Vector3(8.0, 6.0, 24.0)
	_camera.look_at(Vector3(8.0, 2.0, 16.0), Vector3.UP)
	# Give the occupied emitter's particle system real wall-clock time to
	# populate visibly before capturing (GPUParticles3D advances via the
	# rendering server's own per-frame simulation, not a manually-steppable
	# clock).
	await get_tree().create_timer(2.5).timeout
	_capture_and_save(EVIDENCE_FILE_NAMES["smoke"])

	occupied_emitter.queue_free()
	empty_emitter.queue_free()
	occupied_hut.queue_free()
	empty_hut.queue_free()


## AC-A foliage sway: a small patch of foliage_sway-shaded quads, captured
## twice at different elapsed times so the sway is visible across frames.
func _capture_foliage_vantage() -> void:
	# Patch placed well inside the grid interior (never near the world edge,
	# so the vantage below never has to look past an outer boundary wall
	# face) -- world extent is 32x32, so [12, 20] is comfortably interior.
	var patch_base: int = 12
	var patch := Node3D.new()
	add_child(patch)
	var shader: Shader = load("res://assets/shaders/foliage_sway.gdshader")
	for x in 5:
		for z in 5:
			var cell_x: int = patch_base + 2 * x
			var cell_z: int = patch_base + 2 * z
			var ground_y: float = _find_ground_height(cell_x, cell_z)
			var blade := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			mesh.size = Vector2(0.4, 1.0)
			var material := ShaderMaterial.new()
			material.shader = shader
			mesh.surface_set_material(0, material)
			blade.mesh = mesh
			blade.position = Vector3(float(cell_x) + 0.5, ground_y + 0.5, float(cell_z) + 0.5)
			patch.add_child(blade)

	# Camera height (9.0) is safely above ANY possible terrain height here
	# (base_height 4 + amplitude ceiling 3 = 7 max, VoxelWorldConfig GDD
	# ranges) regardless of x/z, so this vantage can never end up looking
	# from inside/underneath the generated terrain mass.
	_camera.position = Vector3(10.0, 9.0, 6.0)
	_camera.look_at(Vector3(16.0, 5.0, 18.0), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	_capture_and_save(EVIDENCE_FILE_NAMES["foliage_1"])

	# A different elapsed engine time (TIME advances every frame on its own)
	# -- wait long enough for the sway phase to visibly differ.
	await get_tree().create_timer(1.0).timeout
	_capture_and_save(EVIDENCE_FILE_NAMES["foliage_2"])

	patch.queue_free()


## AC-A interior clutter: a small enclosed placeholder room with static
## clutter props via [InteriorClutterPlacer].
func _capture_clutter_vantage() -> void:
	var room := _build_placeholder_room(Vector3(20.0, 0.0, 4.0))
	add_child(room)

	var placer := InteriorClutterPlacer.new()
	placer.position = Vector3(20.0, 0.0, 4.0)
	placer.clutter_transforms = [
		Transform3D(Basis(), Vector3(-0.8, 0.3, -0.8)),
		Transform3D(Basis(), Vector3(0.6, 0.3, -0.6)),
		Transform3D(Basis(), Vector3(-0.5, 0.3, 0.7)),
		Transform3D(Basis(), Vector3(0.7, 0.3, 0.7)),
	]
	add_child(placer)
	placer.setup()

	_camera.position = Vector3(20.0, 1.8, 1.0)
	_camera.look_at(Vector3(20.0, 0.3, 4.3), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	_capture_and_save(EVIDENCE_FILE_NAMES["clutter"])

	room.queue_free()
	placer.queue_free()


## AC-A torch flicker: a fixed torch + a carried-lantern stand-in, each
## driven by [TorchFlicker], captured at two elapsed times with sampled
## `light_energy` logged (the automated sub-3Hz proof lives in
## `torch_flicker_test.gd`; this is the companion visual evidence).
func _capture_torch_vantage() -> void:
	var fixed_ground_y: float = _find_ground_height(28, 4)
	var carried_ground_y: float = _find_ground_height(30, 4)

	var fixed_light := OmniLight3D.new()
	fixed_light.position = Vector3(28.0, fixed_ground_y + 1.5, 4.0)
	fixed_light.omni_range = 6.0
	add_child(fixed_light)
	var fixed_flicker := TorchFlicker.new()
	fixed_flicker.config = _config
	fixed_flicker.light = fixed_light
	add_child(fixed_flicker)
	fixed_flicker.setup()
	var fixed_indicator: MeshInstance3D = _build_torch_indicator(fixed_light.position)
	add_child(fixed_indicator)

	var carried_light := OmniLight3D.new()
	carried_light.position = Vector3(30.0, carried_ground_y + 1.2, 4.0)
	carried_light.omni_range = 4.0
	add_child(carried_light)
	var carried_flicker := TorchFlicker.new()
	carried_flicker.config = _config
	carried_flicker.light = carried_light
	add_child(carried_flicker)
	carried_flicker.setup()
	var carried_indicator: MeshInstance3D = _build_torch_indicator(carried_light.position)
	add_child(carried_indicator)

	# Camera height (9.0) is safely above any possible terrain height here
	# (see `_capture_foliage_vantage`'s identical reasoning) -- avoids ending
	# up inside/underneath the generated terrain mass regardless of the
	# ground-height-dependent light/indicator positions above.
	_camera.position = Vector3(28.0, 9.0, -4.0)
	_camera.look_at(Vector3(29.0, fixed_ground_y + 1.0, 4.0), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	print("ambient_life_evidence: torch_1 fixed_energy=%s carried_energy=%s" %
		[fixed_light.light_energy, carried_light.light_energy])
	_update_torch_indicator(fixed_indicator, fixed_light.light_energy)
	_update_torch_indicator(carried_indicator, carried_light.light_energy)
	_capture_and_save(EVIDENCE_FILE_NAMES["torch_1"])

	await get_tree().create_timer(0.6).timeout
	print("ambient_life_evidence: torch_2 fixed_energy=%s carried_energy=%s" %
		[fixed_light.light_energy, carried_light.light_energy])
	_update_torch_indicator(fixed_indicator, fixed_light.light_energy)
	_update_torch_indicator(carried_indicator, carried_light.light_energy)
	_capture_and_save(EVIDENCE_FILE_NAMES["torch_2"])

	fixed_flicker.queue_free()
	carried_flicker.queue_free()
	fixed_light.queue_free()
	carried_light.queue_free()
	fixed_indicator.queue_free()
	carried_indicator.queue_free()


## A small emissive sphere standing in for a torch/lantern's visible flame
## head -- [Light3D] itself has no rendered geometry, so this is purely a
## visualization aid making the sampled `light_energy` value legible in a
## screenshot (via [method _update_torch_indicator]'s emission-multiplier
## write), never a claim about real torch-fixture art (deferred, no
## fixture-art pipeline exists yet).
func _build_torch_indicator(at_position: Vector3) -> MeshInstance3D:
	var indicator := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.75, 0.35)
	mesh.material = material
	indicator.mesh = mesh
	indicator.position = at_position
	return indicator


## Writes [param energy] onto [param indicator]'s emission-energy multiplier
## so its rendered brightness visibly tracks the sampled `light_energy` value
## at capture time (class doc comment).
func _update_torch_indicator(indicator: MeshInstance3D, energy: float) -> void:
	var material: StandardMaterial3D = indicator.mesh.material as StandardMaterial3D
	material.emission_energy_multiplier = energy


## Scans downward from the grid's configured top ([VoxelWorldConfig.max_y])
## to find the topmost solid cell at ([param cell_x], [param cell_z]), so
## foliage placement sits ON the actual generated terrain surface rather
## than floating above it or being buried inside it.
func _find_ground_height(cell_x: int, cell_z: int) -> float:
	for y in range(_grid.config.max_y, _grid.config.min_y - 1, -1):
		var contents: CellContents = _grid.get_cell(Vector3i(cell_x, y, cell_z))
		if contents != null and not contents.is_empty():
			return float(y) + 1.0
	return float(_grid.config.min_y)


## A crude placeholder "hut" (no fixture-art pipeline exists yet) -- just
## enough boxy silhouette for a smoke wisp to visibly rise from.
func _build_placeholder_hut(base_position: Vector3) -> MeshInstance3D:
	var hut := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 2.5, 2.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8B6A4A")
	mesh.material = material
	hut.mesh = mesh
	hut.position = base_position + Vector3(0.0, 1.25, 0.0)
	return hut


## A crude placeholder open-fronted "room" shell for the interior-clutter
## capture -- floor + back/side walls only, open toward the camera.
func _build_placeholder_room(base_position: Vector3) -> Node3D:
	var room := Node3D.new()
	room.position = base_position
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color("6E5A46")

	var floor_instance := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(2.4, 0.1, 2.4)
	floor_mesh.material = wall_material
	floor_instance.mesh = floor_mesh
	room.add_child(floor_instance)

	var back_wall := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(2.4, 1.2, 0.1)
	back_mesh.material = wall_material
	back_wall.mesh = back_mesh
	back_wall.position = Vector3(0.0, 0.6, 1.15)
	room.add_child(back_wall)

	return room


func _capture_and_save(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path("res://../production/qa/evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("ambient_life_evidence: failed to save %s (error %d)" % [path, err])
	else:
		print("ambient_life_evidence: saved %s" % path)
