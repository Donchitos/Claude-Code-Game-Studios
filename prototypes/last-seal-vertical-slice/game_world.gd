# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Root integrator: boot order, wiring, environment (fog/light per art bible),
# warmth-as-reward room lights. Slice-relaxed: code wiring instead of @export.
extends Node3D

const VoxelWorldScript := preload("res://voxel_world.gd")
const CameraInputScript := preload("res://camera_input.gd")
const BuildingSystemScript := preload("res://building_system.gd")
const VillagerAIScript := preload("res://villager_ai.gd")
const NeedsMoodScript := preload("res://needs_mood.gd")
const BuildValidationScript := preload("res://build_validation.gd")
const HudScript := preload("res://hud.gd")
const DebugConsoleScript := preload("res://debug_console.gd")

const ROOM_LIGHT_COLOR := Color(0.96, 0.66, 0.24)  # Hearth Gold family
const FOG_COLOR := Color("6B8593")                  # Threshold Cool (art bible fog hue)

var voxel_world: Node3D
var camera_input: Node3D
var building_system: Node3D
var villager_ai: Node3D
var needs_mood: Node
var build_validation: Node
var hud: CanvasLayer

var _room_lights: Dictionary = {}  # anchor cell (Vector3i) -> OmniLight3D


func _ready() -> void:
	# Autoloads are fully ready before the main scene (boot gate, slice-reduced).
	assert(ResourceItemDatabase.is_ready(), "RID must be Ready before world boot")

	voxel_world = VoxelWorldScript.new()
	voxel_world.name = "VoxelWorld"
	add_child(voxel_world)
	voxel_world.setup()

	camera_input = CameraInputScript.new()
	camera_input.name = "CameraInput"
	add_child(camera_input)
	camera_input.setup(voxel_world.get_region_aabb())
	if camera_input.has_method("set_height_provider"):
		camera_input.set_height_provider(voxel_world.terrain_height)

	needs_mood = NeedsMoodScript.new()
	needs_mood.name = "NeedsMood"
	add_child(needs_mood)

	build_validation = BuildValidationScript.new()
	build_validation.name = "BuildValidation"
	add_child(build_validation)

	hud = HudScript.new()
	hud.name = "Hud"
	add_child(hud)

	building_system = BuildingSystemScript.new()
	building_system.name = "BuildingSystem"
	add_child(building_system)
	building_system.setup(voxel_world, camera_input, hud)
	# ANTI-STUCK FEATURE 2 (2026-07-23): wire VillagerAI's script BEFORE
	# villager_ai even exists -- the seal-prevention check only needs the
	# preloaded script's static helpers, not a live instance.
	if building_system.has_method("set_villager_ai_script"):
		building_system.set_villager_ai_script(VillagerAIScript)

	villager_ai = VillagerAIScript.new()
	villager_ai.name = "VillagerAI"
	add_child(villager_ai)

	# Order matters: villager_ai connects to tick BEFORE needs_mood so
	# start/stop_recovery reports land before that tick's decay pass (GDD Rule 10).
	villager_ai.setup(voxel_world, building_system, needs_mood)
	needs_mood.setup(build_validation)
	build_validation.setup(voxel_world, building_system, VillagerAIScript)
	hud.setup(building_system, camera_input, villager_ai, needs_mood, build_validation, voxel_world)

	var debug_console: CanvasLayer = DebugConsoleScript.new()
	debug_console.name = "DebugConsole"
	add_child(debug_console)
	debug_console.setup(voxel_world, camera_input, building_system, villager_ai, needs_mood, build_validation)

	_wire_optional_providers()
	_wire_time_actions()
	_wire_hud_actions()
	_setup_environment()

	build_validation.room_recognized.connect(_on_room_recognized)
	if building_system.has_signal("cells_removed"):
		building_system.cells_removed.connect(func(_cells: Array) -> void: _revalidate_room_lights())


func _wire_optional_providers() -> void:
	# Contract additions reported by module agents — wire defensively.
	if villager_ai.has_method("set_shelter_provider"):
		villager_ai.set_shelter_provider(build_validation.is_cell_sheltered)
	if needs_mood.has_method("set_context_provider") and villager_ai.has_method("get_bed_context"):
		needs_mood.set_context_provider(villager_ai.get_bed_context)
	if needs_mood.has_method("set_distress_provider"):
		needs_mood.set_distress_provider(func(id: int) -> String:
			return villager_ai.get_info(id).get("distress", ""))
	# ANTI-STUCK FEATURE 2: lets BuildingSystem's seal-prevention check look up
	# a claiming villager's current cell without tracking positions itself.
	if building_system.has_method("set_position_provider") and villager_ai.has_method("get_villager_cell"):
		building_system.set_position_provider(villager_ai.get_villager_cell)


func _wire_hud_actions() -> void:
	# Day-1 integration gap (user-found): the HUD's click signals were never
	# routed to the Building System — only the 1-5 key path worked.
	hud.tool_button_pressed.connect(building_system._set_tool)
	hud.material_selected.connect(building_system.select_material)
	hud.formation_selected.connect(building_system.set_formation)
	hud.wall_height_set.connect(building_system._set_wall_height)
	hud.undo_pressed.connect(building_system._undo)
	hud.redo_pressed.connect(building_system._redo)


func _wire_time_actions() -> void:
	camera_input.action_fired.connect(_on_time_action)


func _on_time_action(action: String) -> void:
	match action:
		"time_pause":
			TimeTickSystem.toggle_paused()
		"time_speed_up":
			var idx_up: int = TimeTickSystem.WARPS.find(TimeTickSystem.get_warp())
			TimeTickSystem.set_warp(TimeTickSystem.WARPS[mini(idx_up + 1, TimeTickSystem.WARPS.size() - 1)])
		"time_speed_down":
			var idx_down: int = TimeTickSystem.WARPS.find(TimeTickSystem.get_warp())
			TimeTickSystem.set_warp(TimeTickSystem.WARPS[maxi(idx_down - 1, 0)])
		# BUILD UX PACKAGE (2026-07-22, feature 2): SLICE VIEW keys. Both the
		# HUD's slice buttons and these keys call voxel_world.set_slice_level()
		# directly -- VillagerAI stays in sync via voxel_world's own
		# slice_level_changed signal (see villager_ai.gd setup()), so there is
		# only ONE call site needed per trigger, not a broker function here.
		"slice_up":
			voxel_world.set_slice_level(voxel_world.get_slice_level() + 1)
		"slice_down":
			voxel_world.set_slice_level(voxel_world.get_slice_level() - 1)
		"slice_reset":
			voxel_world.reset_slice_level()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.45, 0.58, 0.72)
	sky_mat.sky_horizon_color = Color(0.78, 0.75, 0.68)   # warm-neutral horizon
	sky_mat.ground_bottom_color = Color(0.22, 0.20, 0.18)
	sky_mat.ground_horizon_color = Color(0.60, 0.56, 0.50)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	# Warm flat ambient — the sky-sourced ambient tinted everything blue-grey
	# and crushed the ground read (found via the mesher agent's A/B render).
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.98, 0.94, 0.86)
	env.ambient_light_energy = 0.5
	# Grounding: GENTLE SSAO only — intensity 2.5 crushed the whole scene
	# (ambient-dominated look); 1.1/0.9 adds contact shading without murk.
	env.ssao_enabled = false  # consistently over-darkens this scene; sun
	# shadows (orthogonal mode) + baked vertex AO carry the grounding.

	# Cozy-at-scale: fog owns the HORIZON only — near field stays warm/readable.
	env.fog_enabled = true
	env.fog_light_color = FOG_COLOR
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.3
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.80)  # warm golden-hour key light
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	# RUN D: PSSM was blanket-shadowing the whole scene from day one (proven
	# by bisect: shadows-off = bright at half the ambient). Single orthogonal
	# split is the robust voxel-scale setup.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_blur = 1.0
	add_child(sun)


func _on_room_recognized(cells: Array, _celebrate: bool) -> void:
	# Warmth-as-reward: a recognized room earns a warm interior light.
	if cells.is_empty():
		return
	var sum := Vector3.ZERO
	for c: Vector3i in cells:
		sum += Vector3(c) + Vector3(0.5, 0.5, 0.5)
	var center := sum / float(cells.size())
	var anchor: Vector3i = cells[0]
	if _room_lights.has(anchor):
		return
	var light := OmniLight3D.new()
	light.position = center + Vector3(0, 0.8, 0)
	light.light_color = ROOM_LIGHT_COLOR
	light.light_energy = 1.3
	light.omni_range = 6.5
	add_child(light)
	_room_lights[anchor] = light


func _revalidate_room_lights() -> void:
	# A light survives only while its anchor cell is still sheltered.
	for anchor: Vector3i in _room_lights.keys():
		if not build_validation.is_cell_sheltered(anchor):
			(_room_lights[anchor] as OmniLight3D).queue_free()
			_room_lights.erase(anchor)
