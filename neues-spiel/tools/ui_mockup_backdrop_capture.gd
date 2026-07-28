## UI mockup backdrop capture tool.
##
## Renders ONE 1920x1080 golden-hour vista of the Home Valley -- terrain,
## a small settlement, vegetation, villagers -- to be used as the shared
## background layer behind every UI direction mockup in
## `design/art/mockups/`, so competing HUD designs are judged over the SAME
## frame instead of over a blank canvas.
##
## NOT part of the production boot chain and NOT wired into `GameWorld`/
## `Valley` -- a standalone tool scene, following the established pattern of
## `tools/m01_c4_valley_ambient_capture.gd` and
## `tools/vox018_60fps_culling_measurement.gd`.
##
## Renders into a fixed-size [SubViewport] rather than the OS window, so the
## output is exactly 1920x1080 regardless of the operator's desktop
## resolution (both sibling tools capture the main window and therefore
## inherit whatever size it happened to get). Still run WINDOWED -- headless
## cannot render a viewport texture.
##
## HONEST SCOPE NOTES -- what here is real, and what is this tool's own:
##
##  * REAL production systems: [VoxelWorldGrid] + [VoxelWorldMesher] +
##    [VoxelWorldMeshStreamer], driven through the same residency-then-
##    build_initial_window sequence `GameWorld` boots with. The terrain
##    silhouette in the shot is genuinely the shipped mesher's output.
##  * THIS TOOL'S OWN: the per-height-band terrain COLORS (art-bible §4.3),
##    applied via a tool-local material override. The shipped
##    [VoxelWorldMesher] still paints every terrain block with the single
##    Lowland swatch from its own `DEBUG_BLOCK_COLORS` (§4.3's four bands
##    have no implementing story yet) -- this tool shows the SPECIFIED
##    target palette, not today's placeholder, because a mono-green carpet
##    would misrepresent the art direction the UI must sit on top of.
##  * THIS TOOL'S OWN: the settlement geometry, built as plain box meshes in
##    art-bible §4.1 palette colors rather than as real committed voxel
##    cells. Real cells would be repainted by the height-band override above
##    (the mesher has one shared material for ALL chunks by contract), which
##    would make the huts the color of the ground they stand on.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/ui_mockup_backdrop_capture.tscn
extends Node

const OUTPUT_DIR := "res://../design/art/mockups"
const OUTPUT_PNG := "backdrop-valley-1080p.png"

const CAPTURE_SIZE := Vector2i(1920, 1080)

## Small world extent -- this tool renders one static vista, so it needs only
## the chunks under the camera, never the production 2000x2000 (or
## vox-018's 896 stress extent). 256 is [constant
## VoxelWorldConfig.WORLD_WIDTH_CELLS_MIN], the smallest the config validator
## accepts.
const WORLD_EXTENT_CELLS := 256
const WORLD_MAX_Y := 32

## Hard wall-clock safety cap (real seconds since boot) -- forces an early
## quit if residency never settles, mirroring the safety-cap precedent in
## `tools/vox018_60fps_culling_measurement.gd` and
## `tools/m01_c4_valley_ambient_capture.gd`.
const SAFETY_CAP_SEC := 90.0

## Budget for the boot-residency drive, mirroring `GameWorld`'s own
## genesis ceiling shape (bounded loop, never an unbounded spin).
const RESIDENCY_CEILING_MS := 30000.0

## art-bible §4.3 per-height-band terrain color mapping. Applied by this
## tool only -- see the scope note in the class doc comment.
const BAND_LOWLAND := Color("9CAD6E")
const BAND_MIDLAND := Color("A98F5E")
const BAND_HIGHLAND := Color("7C818A")
const BAND_PEAK := Color("C9D3D8")

## art-bible §4.1 primary palette -- the settlement's material tiers.
const TIMBER_BROWN := Color("8B5E3C")
const HEARTHSTONE_GREY := Color("8A8D8F")
const THATCH_UMBER := Color("A8642F")
const HEARTH_GOLD := Color("F5A83C")

const VEGETATION_MODELS: Array[String] = [
	"res://assets/models/vegetation/veg_tree-oak_var01_medium.glb",
	"res://assets/models/vegetation/veg_tree-oak_var02_small.glb",
	"res://assets/models/vegetation/veg_tree-pine_var01_large.glb",
	"res://assets/models/vegetation/veg_shrub_var01_small.glb",
	"res://assets/models/vegetation/veg_stump-oak_var01_small.glb",
	"res://assets/models/vegetation/veg_log-oak_var01_small.glb",
]

## Deterministic scatter -- a fixed seed so re-running this tool reproduces
## the SAME backdrop. Every mockup direction must sit on an identical frame
## for the comparison to mean anything; a re-render that moved the trees
## would silently invalidate that.
const SCATTER_SEED := 20260727

var _viewport: SubViewport
var _camera: Camera3D
var _light: DirectionalLight3D
var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher
var _streamer: VoxelWorldMeshStreamer

var _boot_start_usec: int = 0
var _settle_frames_remaining: int = 8
var _captured: bool = false

## World-space anchor of the settlement, resolved once the terrain under the
## world center is known.
var _settlement_origin := Vector3i.ZERO


func _ready() -> void:
	_boot_start_usec = Time.get_ticks_usec()
	_build_viewport()
	_build_world()
	_apply_golden_hour_lighting()
	_drive_residency()
	_paint_height_bands()
	_settlement_origin = _resolve_settlement_origin()
	_build_settlement()
	_scatter_vegetation()
	_place_villagers()
	_frame_camera()


func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.far = 400.0
	_camera.fov = 45.0
	_viewport.add_child(_camera)

	_light = DirectionalLight3D.new()
	_viewport.add_child(_light)


## The art-bible §2.1 "permanent golden-hour bias" recipe -- the same values
## `tools/m01_c4_valley_ambient_capture.gd` reuses from the vertical slice's
## own documented A/B render, never re-tuned here.
func _apply_golden_hour_lighting() -> void:
	var environment := Environment.new()
	# A graded dusk sky rather than the sibling tools' flat background color
	# -- those capture close-ups where the sky is barely in frame; this is a
	# wide vista where a flat band would read as a rendering error and would
	# also fight whatever the UI puts along the top edge.
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.62, 0.60, 0.66)
	sky_material.sky_horizon_color = Color(0.93, 0.76, 0.55)
	sky_material.ground_horizon_color = Color(0.93, 0.76, 0.55)
	sky_material.ground_bottom_color = Color(0.72, 0.60, 0.47)
	sky_material.sun_angle_max = 12.0
	sky_material.sun_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.98, 0.94, 0.86)
	environment.ambient_light_energy = 0.5
	environment.ssao_enabled = false
	# art-bible §2.6 horizon treatment -- the streaming boundary reads as
	# atmosphere rather than as a hard mesh edge. Threshold Cool is the
	# palette's fog-exclusive hue (§4.1).
	environment.fog_enabled = true
	environment.fog_light_color = Color("6B8593")
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.0

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	_light.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	_light.light_color = Color(1.0, 0.93, 0.80)
	_light.light_energy = 1.7
	_light.shadow_enabled = true
	_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_light.directional_shadow_max_distance = 120.0
	_light.shadow_blur = 1.0


func _build_world() -> void:
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	config.max_y = WORLD_MAX_Y
	config.base_height = 8
	config.amplitude = 6.0
	config.frequency = 0.035
	config.terrain_seed = SCATTER_SEED
	# Only the chunks under this one static camera are ever needed.
	config.view_radius_chunks = 10
	config.boot_mesh_radius_chunks = 10
	config.settlement_radius_chunks = 6
	config.region_directory = "user://ui_mockup_backdrop_regions"

	_grid = VoxelWorldGrid.new()
	_grid.config = config
	_viewport.add_child(_grid)
	_grid.setup()

	_mesher = VoxelWorldMesher.new()
	_mesher.grid = _grid
	_viewport.add_child(_mesher)
	_mesher.setup()

	_streamer = VoxelWorldMeshStreamer.new()
	_streamer.grid = _grid
	_streamer.mesher = _mesher
	_viewport.add_child(_streamer)
	_streamer.setup()


## Mirrors `GameWorld._drive_boot_residency`'s bounded two-part fixed point:
## alternate `update_residency` with `drain_pending_async_reads` until nothing
## is in flight AND the resident count stops growing -- never a bare
## "zero in flight" check (a single call is capped at
## `max_concurrent_async_tasks` dispatches, so a full window needs several
## rounds), and never an unbounded spin.
func _drive_residency() -> void:
	var focus_cell := Vector3i(WORLD_EXTENT_CELLS / 2, 0, WORLD_EXTENT_CELLS / 2)
	var start_usec: int = Time.get_ticks_usec()
	var ceiling_usec: int = int(RESIDENCY_CEILING_MS * 1000.0)
	var previous_resident_count: int = -1

	while true:
		_grid.update_residency(focus_cell, focus_cell)
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		if elapsed_usec >= ceiling_usec:
			push_warning("ui_mockup_backdrop_capture: residency ceiling hit -- capturing a partial world")
			break
		var remaining_msec: int = maxi(1, int(float(ceiling_usec - elapsed_usec) / 1000.0))
		_grid.drain_pending_async_reads(remaining_msec)
		var in_flight: int = _grid.get_in_flight_async_task_count()
		var resident_count: int = _grid.get_resident_chunk_keys().size()
		if in_flight == 0 and resident_count == previous_resident_count:
			break
		previous_resident_count = resident_count

	_grid.mark_generated()
	_streamer.build_initial_window(focus_cell)
	print("ui_mockup_backdrop_capture: %d chunks resident" % _grid.get_resident_chunk_keys().size())


## Applies art-bible §4.3's four height bands as a tool-local material
## override on every built chunk. See the class doc comment's scope note --
## the shipped mesher paints one flat Lowland swatch for all terrain.
func _paint_height_bands() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 band_lowland : source_color;
uniform vec4 band_midland : source_color;
uniform vec4 band_highland : source_color;
uniform vec4 band_peak : source_color;

varying float world_height;

void vertex() {
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	// art-bible §4.3 bands over a max_y of 32, softened at the seams so the
	// terrain reads as a landscape rather than as four painted stripes.
	vec3 albedo = mix(band_lowland.rgb, band_midland.rgb, smoothstep(10.0, 14.0, world_height));
	albedo = mix(albedo, band_highland.rgb, smoothstep(16.0, 20.0, world_height));
	albedo = mix(albedo, band_peak.rgb, smoothstep(23.0, 28.0, world_height));
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("band_lowland", BAND_LOWLAND)
	material.set_shader_parameter("band_midland", BAND_MIDLAND)
	material.set_shader_parameter("band_highland", BAND_HIGHLAND)
	material.set_shader_parameter("band_peak", BAND_PEAK)

	for chunk_key: Vector2i in _mesher.get_tracked_chunk_keys():
		var instance: MeshInstance3D = _mesher.get_chunk_mesh_instance(chunk_key)
		if instance != null:
			instance.material_override = material


## Finds the topmost solid cell under the world center -- the settlement is
## placed on the real generated terrain, never at a guessed altitude.
func _resolve_settlement_origin() -> Vector3i:
	var center_x: int = WORLD_EXTENT_CELLS / 2
	var center_z: int = WORLD_EXTENT_CELLS / 2
	return Vector3i(center_x, _surface_height(center_x, center_z) + 1, center_z)


## Topmost solid Y at a column, or -1 if the column is entirely air.
func _surface_height(x: int, z: int) -> int:
	for y in range(WORLD_MAX_Y - 1, -1, -1):
		var cell := Vector3i(x, y, z)
		if not _grid.is_in_bounds(cell):
			continue
		if not _grid.get_cell(cell).is_empty():
			return y
	return -1


# --- Settlement geometry (tool-local; see class doc comment) ------------------

## Accumulated box positions per palette color, flushed into one
## [MultiMeshInstance3D] per color so the whole settlement costs four draw
## calls rather than one per block.
var _blocks_by_color: Dictionary[Color, Array] = {}


func _place_block(cell: Vector3i, color: Color) -> void:
	if not _blocks_by_color.has(color):
		_blocks_by_color[color] = [] as Array[Vector3i]
	var cells: Array = _blocks_by_color[color]
	cells.append(cell)


func _build_settlement() -> void:
	# Two huts at a slight angle to each other, sharing a stone yard -- the
	# art-bible §6.1 buildable vernacular, kept deliberately small so the
	# frame reads as an early settlement rather than a finished town.
	_build_hut(_settlement_origin + Vector3i(-9, 0, -4), 8, 7, true)
	_build_hut(_settlement_origin + Vector3i(6, 0, 3), 6, 6, false)
	_build_yard(_settlement_origin + Vector3i(-2, 0, 1), 7, 5)
	_build_hearth(_settlement_origin + Vector3i(1, 0, 3))
	_flush_blocks()


## One hut: stone footing, timber walls with a door gap and window gaps, a
## thatch gable roof, and gold-tier furniture inside (§4.1 Function tier --
## "this block does something").
func _build_hut(origin: Vector3i, width: int, depth: int, door_on_south: bool) -> void:
	var wall_height: int = 3

	for x in range(width):
		for z in range(depth):
			var ground: int = _surface_height(origin.x + x, origin.z + z)
			var floor_y: int = ground + 1
			_place_block(Vector3i(origin.x + x, floor_y, origin.z + z), HEARTHSTONE_GREY)

			var is_edge: bool = x == 0 or x == width - 1 or z == 0 or z == depth - 1
			if not is_edge:
				continue

			for h in range(1, wall_height + 1):
				if _is_opening(x, z, h, width, depth, door_on_south):
					continue
				_place_block(Vector3i(origin.x + x, floor_y + h, origin.z + z), TIMBER_BROWN)

	# Thatch gable, ridge running along X, at a full one-cell-per-cell pitch --
	# the classic blocky staircase the visual-direction note names Minecraft
	# as the reference for (§2b). A half pitch was tried first and read as
	# stacked shelf boards: at 1.0 cell size the steps are too shallow to
	# resolve as a roof. Overhang is exactly one cell on the eave sides only;
	# an overhang on the gable ends too is what made the huts look like
	# furniture.
	var base_ground: int = _surface_height(origin.x, origin.z)
	var eave_y: int = base_ground + 1 + wall_height + 1
	var half_depth: int = int(float(depth) / 2.0)
	for x in range(width):
		for z in range(-1, depth + 1):
			var distance_from_ridge: int = absi(z - half_depth)
			var roof_y: int = eave_y + maxi(0, half_depth - distance_from_ridge)
			_place_block(Vector3i(origin.x + x, roof_y, origin.z + z), THATCH_UMBER)

	# Fill the gable triangles at both ends. Without this the hut is open
	# between the wall top and the roof pitch -- you see straight through the
	# building, which reads as broken geometry rather than as architecture.
	for x: int in [0, width - 1]:
		for z in range(depth):
			var distance_from_ridge: int = absi(z - half_depth)
			var roof_y: int = eave_y + maxi(0, half_depth - distance_from_ridge)
			for y in range(eave_y - 1, roof_y):
				_place_block(Vector3i(origin.x + x, y, origin.z + z), TIMBER_BROWN)

	# Interior fixtures -- a bed and a table, the Function tier's gold tell.
	var interior_ground: int = _surface_height(origin.x + 2, origin.z + 2)
	_place_block(Vector3i(origin.x + 2, interior_ground + 2, origin.z + 2), HEARTH_GOLD)
	_place_block(Vector3i(origin.x + 3, interior_ground + 2, origin.z + 2), HEARTH_GOLD)
	_place_block(Vector3i(origin.x + width - 3, interior_ground + 2, origin.z + depth - 3), HEARTH_GOLD)


## Door gap (2 cells tall, centered on one wall) and window gaps (1 cell, at
## eye height on the long walls).
func _is_opening(x: int, z: int, h: int, width: int, depth: int, door_on_south: bool) -> bool:
	var mid_x: int = int(float(width) / 2.0)
	var door_z: int = depth - 1 if door_on_south else 0
	if z == door_z and (x == mid_x or x == mid_x - 1) and h <= 2:
		return true
	if h == 2 and (z == 0 or z == depth - 1) and (x == 1 or x == width - 2):
		return true
	if h == 2 and (x == 0 or x == width - 1) and (z == 1 or z == depth - 2):
		return true
	return false


## A stone yard between the huts -- the settlement reads as a place, not as
## two unrelated buildings.
func _build_yard(origin: Vector3i, width: int, depth: int) -> void:
	for x in range(width):
		for z in range(depth):
			var ground: int = _surface_height(origin.x + x, origin.z + z)
			_place_block(Vector3i(origin.x + x, ground + 1, origin.z + z), HEARTHSTONE_GREY)


## The hearth -- art-bible Principle 1's warmth-as-reward anchor, and the
## warmest, most saturated thing in the frame by design.
func _build_hearth(cell: Vector3i) -> void:
	var ground: int = _surface_height(cell.x, cell.z)
	_place_block(Vector3i(cell.x, ground + 2, cell.z), HEARTH_GOLD)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.36)
	light.light_energy = 4.0
	light.omni_range = 14.0
	light.position = VoxelWorldGrid.cell_to_world(Vector3i(cell.x, ground + 3, cell.z))
	_viewport.add_child(light)


func _flush_blocks() -> void:
	for color: Color in _blocks_by_color:
		var cells: Array = _blocks_by_color[color]
		if cells.is_empty():
			continue

		var box := BoxMesh.new()
		# Flush, full-cell blocks -- visual-direction-note §2b (render size =
		# cell size 1.0, no inter-block gap; the prototype's 0.96 was dropped).
		box.size = Vector3(VoxelWorldConfig.CELL_SIZE, VoxelWorldConfig.CELL_SIZE, VoxelWorldConfig.CELL_SIZE)

		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		material.metallic = 0.0
		material.specular = 0.0
		if color == HEARTH_GOLD:
			# Function-tier fixtures carry their own warm glow.
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = 0.6
		box.material = material

		var multi_mesh := MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.mesh = box
		multi_mesh.instance_count = cells.size()
		for i in range(cells.size()):
			var cell: Vector3i = cells[i]
			multi_mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, VoxelWorldGrid.cell_to_world(cell)))

		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi_mesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_viewport.add_child(instance)


func _scatter_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED

	var scenes: Array[PackedScene] = []
	for path: String in VEGETATION_MODELS:
		var scene: PackedScene = load(path) as PackedScene
		if scene != null:
			scenes.append(scene)
	if scenes.is_empty():
		push_warning("ui_mockup_backdrop_capture: no vegetation models loaded")
		return

	var placed: int = 0
	var attempts: int = 0
	while placed < 90 and attempts < 900:
		attempts += 1
		var x: int = _settlement_origin.x + rng.randi_range(-60, 60)
		var z: int = _settlement_origin.z + rng.randi_range(-60, 60)

		# Keep the settlement clearing readable -- no trees growing through
		# the huts or the yard.
		var distance_to_settlement: float = Vector2(
			float(x - _settlement_origin.x), float(z - _settlement_origin.z)
		).length()
		if distance_to_settlement < 12.0:
			continue

		var ground: int = _surface_height(x, z)
		if ground < 0:
			continue

		var instance: Node3D = scenes[rng.randi_range(0, scenes.size() - 1)].instantiate() as Node3D
		if instance == null:
			continue
		instance.position = VoxelWorldGrid.cell_to_world(Vector3i(x, ground + 1, z))
		instance.rotate_y(rng.randf_range(0.0, TAU))
		_enable_vertex_colors(instance)
		_viewport.add_child(instance)
		placed += 1

	print("ui_mockup_backdrop_capture: placed %d vegetation instances" % placed)


## The vegetation GLBs carry their color in the mesh's COLOR_0 attribute
## (their one material is literally named `veg_leaf_vertexcolor`), but
## Godot's glTF importer does NOT set `vertex_color_use_as_albedo` for a
## material with no base-color texture -- so every plant imports pure white.
##
## FINDING BEYOND THIS TOOL: this affects the real game the moment vegetation
## is hosted in `Valley`, not just this capture. The production fix belongs in
## the asset pipeline (an import script or a `.import` subresource override),
## not in a per-instance walk like this one.
func _enable_vertex_colors(root: Node) -> void:
	var mesh_instance := root as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null:
				material.vertex_color_use_as_albedo = true
				material.roughness = 1.0
				material.metallic = 0.0
	for child: Node in root.get_children():
		_enable_vertex_colors(child)


## Villagers at art-bible §5.2's 2-block proportions -- a body block and a
## head block, no faces (§5.6). Placeholder stand-ins for the real villager
## body presenter, which needs the full production boot chain this tool
## deliberately does not run.
func _place_villagers() -> void:
	# Placed on the camera-facing side of the settlement so they are actually
	# in frame -- villagers hidden behind the huts prove nothing about scale.
	var offsets: Array[Vector3i] = [
		Vector3i(-2, 0, 7),
		Vector3i(1, 0, 8),
		Vector3i(-6, 0, 5),
	]
	var tunic_colors: Array[Color] = [
		Color("6E7B8B"),
		Color("8B6F4E"),
		Color("7C6E8B"),
	]

	for i in range(offsets.size()):
		var cell: Vector3i = _settlement_origin + offsets[i]
		var ground: int = _surface_height(cell.x, cell.z)
		var base: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(cell.x, ground + 1, cell.z))

		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(0.6, 1.0, 0.6)
		var body_material := StandardMaterial3D.new()
		body_material.albedo_color = tunic_colors[i]
		body_material.roughness = 1.0
		body_mesh.material = body_material
		body.mesh = body_mesh
		body.position = base + Vector3(0.0, 0.5, 0.0)
		_viewport.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := BoxMesh.new()
		head_mesh.size = Vector3(0.5, 0.5, 0.5)
		var head_material := StandardMaterial3D.new()
		head_material.albedo_color = Color("C8A882")
		head_material.roughness = 1.0
		head_mesh.material = head_material
		head.mesh = head_mesh
		head.position = base + Vector3(0.0, 1.25, 0.0)
		_viewport.add_child(head)


## A low-oblique settlement vantage in the spirit of the game's orbit camera
## -- close enough that the huts have presence, high enough that the valley
## and the horizon fog are both in frame. The HUD zones being designed sit
## along the edges of exactly this composition.
func _frame_camera() -> void:
	var target: Vector3 = VoxelWorldGrid.cell_to_world(_settlement_origin)
	# Low oblique: the huts must have presence and their WALLS must be
	# visible, not just their roofs. A steeper vantage turns the frame into a
	# roof study and hides everything Principle 1 communicates.
	#
	# Distance is set by THIS IMAGE'S JOB, not by what flatters the huts: it
	# is the backdrop for HUD mockups, so the settlement must sit clear of
	# the center third (hud.md's permanently HUD-free zone) and leave the
	# screen edges -- where every HUD zone actually lives -- readable.
	_camera.position = target + Vector3(-21.0, 13.0, 24.0)
	_camera.look_at(target + Vector3(0.0, 2.0, 0.0), Vector3.UP)


func _process(_delta: float) -> void:
	if _captured:
		return

	var elapsed_sec: float = float(Time.get_ticks_usec() - _boot_start_usec) / 1000000.0
	if elapsed_sec > SAFETY_CAP_SEC:
		push_warning("ui_mockup_backdrop_capture: SAFETY CAP hit (%0.1fs) -- forcing quit" % elapsed_sec)
		get_tree().quit()
		return

	# Hold a few frames so shadows, the fog, and the just-framed camera all
	# land in the captured frame rather than in the one after it.
	_settle_frames_remaining -= 1
	if _settle_frames_remaining > 0:
		return

	_capture()
	_captured = true
	get_tree().quit()


func _capture() -> void:
	var image: Image = _viewport.get_texture().get_image()
	var output_dir: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var path: String = output_dir.path_join(OUTPUT_PNG)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("ui_mockup_backdrop_capture: failed to save %s (error %d)" % [path, err])
	else:
		print("ui_mockup_backdrop_capture: saved %s (%dx%d)" % [path, image.get_width(), image.get_height()])
