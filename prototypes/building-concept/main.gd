# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does hybrid drag + free-place voxel building feel fluid and expressive?
# Date: 2026-07-09
#
# Everything is built in code so the .tscn stays trivial. Standards are relaxed:
# hardcoded values, placeholder cube assets, no error handling, no architecture.

extends Node3D

# --- Tuning knobs (hardcoded on purpose) ---
const CELL: float = 1.0
const BLOCK_SIZE: float = 0.96      # slightly under 1 so grid gaps read as voxels
const GRID_HALF: int = 20           # ground grid extends -20..20
const MAX_DRAG_CELLS: int = 600     # safety clamp so a huge drag can't freeze

# Block types
enum BType { WALL, FLOOR, ROOF, FIXTURE }
const TYPE_NAMES: Array[String] = ["Wand", "Boden", "Dach", "Fixture"]
const TYPE_COLORS: Array[Color] = [
	Color(0.72, 0.72, 0.75),   # Wall  - light grey
	Color(0.60, 0.44, 0.30),   # Floor - brown
	Color(0.45, 0.30, 0.28),   # Roof  - dark red-brown
	Color(0.30, 0.55, 0.85),   # Fixture - blue
]

# Roof formations. A dragged roof footprint is turned into a stepped, solid pitched
# roof of this shape (not a flat slab), rising from the drag layer.
enum RoofStyle { FLAT, GABLE, HIP, SHED }
const ROOF_STYLE_NAMES: Array[String] = ["Flachdach", "Satteldach", "Walmdach", "Pultdach"]

# --- State ---
var _placed: Dictionary = {}                 # Vector3i -> MeshInstance3D
var _current_type: int = BType.WALL
var _current_layer: int = 0                  # build height (grid units)
var _wall_height: int = 3                    # walls extrude this many blocks upward per action
var _roof_style: int = RoofStyle.GABLE       # active roof formation

# Undo / Redo. Each op is an Array of {cell, old, new} type changes (type -1 = empty).
var _undo: Array = []
var _redo: Array = []
var _op: Array = []
const MAX_UNDO: int = 200
# Plane hover — horizontal plane at the current build layer, used for AREA drags.
var _plane_cell: Vector3i = Vector3i.ZERO
var _has_plane: bool = false
# Block pick — surface-aware raycast against placed blocks, used for single-click edits.
var _pick_cell: Vector3i = Vector3i.ZERO
var _pick_normal: Vector3i = Vector3i.ZERO   # face the ray entered through (points outward)
var _pick_valid: bool = false
# Single-click edit mode when a block is under the cursor.
var _edit_replace: bool = false   # false = Aufsetzen (attach on face), true = Ersetzen (in place)

const DRAG_THRESHOLD_PX: float = 6.0
var _dragging: bool = false
var _did_drag: bool = false
var _drag_start: Vector3i = Vector3i.ZERO
var _drag_layer: int = 0           # build height locked in when a drag begins
var _press_mouse: Vector2 = Vector2.ZERO

# Camera orbit
var _cam_target: Vector3 = Vector3(2.0, 0.0, 2.0)
var _cam_dist: float = 18.0
var _cam_yaw: float = 0.7
var _cam_pitch: float = 0.95
var _orbiting: bool = false

# Nodes
var _camera: Camera3D
var _ghost_root: Node3D
var _ghost_pool: Array[MeshInstance3D] = []
var _pick_highlight: MeshInstance3D          # white overlay on the block under the cursor
var _hud: Label
var _undo_btn: Button
var _redo_btn: Button

# Shared meshes/materials
var _block_mesh: BoxMesh
var _block_mats: Array[StandardMaterial3D] = []
var _ghost_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_build_meshes_and_mats()
	_build_environment()
	_build_camera()
	_build_ground_grid()
	_build_hud()
	_ghost_root = Node3D.new()
	add_child(_ghost_root)
	_build_pick_highlight()
	_build_buttons()
	_update_camera()
	_update_hud()


func _build_buttons() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.position = Vector2(14.0, -46.0)
	layer.add_child(box)
	_undo_btn = Button.new()
	_undo_btn.text = "◄ Zurück  (Strg+Z)"
	_undo_btn.focus_mode = Control.FOCUS_NONE
	_undo_btn.pressed.connect(_undo_action)
	box.add_child(_undo_btn)
	_redo_btn = Button.new()
	_redo_btn.text = "Vorwärts ►  (Strg+Y)"
	_redo_btn.focus_mode = Control.FOCUS_NONE
	_redo_btn.pressed.connect(_redo_action)
	box.add_child(_redo_btn)


func _build_pick_highlight() -> void:
	_pick_highlight = MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3.ONE * (BLOCK_SIZE + 0.08)
	_pick_highlight.mesh = hm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.22)
	_pick_highlight.material_override = mat
	_pick_highlight.visible = false
	add_child(_pick_highlight)


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func _build_meshes_and_mats() -> void:
	_block_mesh = BoxMesh.new()
	_block_mesh.size = Vector3(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	for c in TYPE_COLORS:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		_block_mats.append(m)
		var g := StandardMaterial3D.new()
		g.albedo_color = Color(c.r, c.g, c.b, 0.35)
		g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		g.roughness = 1.0
		_ghost_mats.append(g)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.18, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.52)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -40.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 60.0
	add_child(_camera)


func _build_ground_grid() -> void:
	# Solid ground plane
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(GRID_HALF * 2.0, GRID_HALF * 2.0)
	plane.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.22, 0.25, 0.22)
	gm.roughness = 1.0
	plane.material_override = gm
	plane.position = Vector3(0.0, -0.01, 0.0)
	add_child(plane)

	# Grid lines via ImmediateMesh (cheap, ~160 segments)
	var im := ImmediateMesh.new()
	var line_mat := StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.albedo_color = Color(0.35, 0.40, 0.35)
	im.surface_begin(Mesh.PRIMITIVE_LINES, line_mat)
	for i in range(-GRID_HALF, GRID_HALF + 1):
		var f := float(i)
		var e := float(GRID_HALF)
		im.surface_add_vertex(Vector3(f, 0.0, -e))
		im.surface_add_vertex(Vector3(f, 0.0, e))
		im.surface_add_vertex(Vector3(-e, 0.0, f))
		im.surface_add_vertex(Vector3(e, 0.0, f))
	im.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = im
	add_child(grid)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(14.0, 12.0)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				_orbiting = mb.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_cam_dist = clampf(_cam_dist * 0.9, 4.0, 60.0)
					_update_camera()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_cam_dist = clampf(_cam_dist * 1.1, 4.0, 60.0)
					_update_camera()
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_begin_drag()
				else:
					_end_drag()
			MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					_remove_at_hover()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _orbiting:
			_cam_yaw -= mm.relative.x * 0.008
			_cam_pitch = clampf(_cam_pitch - mm.relative.y * 0.008, 0.15, 1.5)
			_update_camera()
		_update_hover(mm.position)

	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			match k.keycode:
				KEY_1: _set_type(BType.WALL)
				KEY_2: _set_type(BType.FLOOR)
				KEY_3:
					# Selecting Dach again cycles through the roof formations.
					if _current_type == BType.ROOF:
						_roof_style = (_roof_style + 1) % ROOF_STYLE_NAMES.size()
						_refresh_preview()
						_update_hud()
					else:
						_set_type(BType.ROOF)
				KEY_4: _set_type(BType.FIXTURE)
				KEY_Z:
					if k.ctrl_pressed and k.shift_pressed:
						_redo_action()
					elif k.ctrl_pressed:
						_undo_action()
				KEY_Y:
					if k.ctrl_pressed:
						_redo_action()
				KEY_R:
					_current_layer += 1
					_update_hover_from_last()
					_update_hud()
				KEY_F:
					_current_layer = maxi(0, _current_layer - 1)
					_update_hover_from_last()
					_update_hud()
				KEY_T:
					_wall_height = mini(8, _wall_height + 1)
					_refresh_preview()
					_update_hud()
				KEY_G:
					_wall_height = maxi(1, _wall_height - 1)
					_refresh_preview()
					_update_hud()
				KEY_X:
					_edit_replace = not _edit_replace
					_refresh_preview()
					_update_hud()
				KEY_Q:
					_cam_yaw -= 0.12
					_update_camera()
				KEY_E:
					_cam_yaw += 0.12
					_update_camera()
				KEY_C:
					_clear_all()


func _process(delta: float) -> void:
	# WASD pans the camera target along the ground, relative to view yaw.
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move.z -= 1.0
	if Input.is_key_pressed(KEY_S): move.z += 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if move != Vector3.ZERO:
		move = move.normalized().rotated(Vector3.UP, _cam_yaw) * delta * _cam_dist * 0.7
		_cam_target += move
		_update_camera()


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------
func _update_camera() -> void:
	var offset := Vector3(
		_cam_dist * cos(_cam_pitch) * sin(_cam_yaw),
		_cam_dist * sin(_cam_pitch),
		_cam_dist * cos(_cam_pitch) * cos(_cam_yaw)
	)
	_camera.position = _cam_target + offset
	_camera.look_at(_cam_target, Vector3.UP)


# ---------------------------------------------------------------------------
# Hover / picking
# ---------------------------------------------------------------------------
var _last_mouse: Vector2 = Vector2.ZERO

func _update_hover_from_last() -> void:
	_update_hover(_last_mouse)

func _update_hover(mouse_pos: Vector2) -> void:
	_last_mouse = mouse_pos
	var origin := _camera.project_ray_origin(mouse_pos)
	var dir := _camera.project_ray_normal(mouse_pos)

	# 1) Plane hover at the current build layer (used for area drags).
	var plane := Plane(Vector3.UP, float(_current_layer) * CELL)
	var hit = plane.intersects_ray(origin, dir)
	if hit == null:
		_has_plane = false
	else:
		var p: Vector3 = hit
		_plane_cell = Vector3i(int(floor(p.x / CELL)), _current_layer, int(floor(p.z / CELL)))
		_has_plane = true

	# 2) Block pick (surface-aware) for single-click placement / edit.
	var pr := _raycast_blocks(origin, dir)
	_pick_valid = pr.hit
	if pr.hit:
		_pick_cell = pr.cell
		_pick_normal = pr.normal

	# 3) Promote a held click to a drag once the mouse has moved far enough.
	if _dragging and not _did_drag and mouse_pos.distance_to(_press_mouse) > DRAG_THRESHOLD_PX:
		_did_drag = true

	_refresh_preview()


# Voxel DDA (Amanatides-Woo): marches the ray through the unit grid and returns the
# first occupied cell plus the face normal it was entered through.
func _raycast_blocks(origin: Vector3, dir: Vector3) -> Dictionary:
	var res := {"hit": false, "cell": Vector3i.ZERO, "normal": Vector3i.ZERO}
	if _placed.is_empty() or dir.length() < 0.00001:
		return res
	var d := dir.normalized()
	var cx := int(floor(origin.x / CELL))
	var cy := int(floor(origin.y / CELL))
	var cz := int(floor(origin.z / CELL))
	var step_x := (1 if d.x > 0.0 else -1) if d.x != 0.0 else 0
	var step_y := (1 if d.y > 0.0 else -1) if d.y != 0.0 else 0
	var step_z := (1 if d.z > 0.0 else -1) if d.z != 0.0 else 0
	var t_max_x := INF
	var t_max_y := INF
	var t_max_z := INF
	var t_delta_x := INF
	var t_delta_y := INF
	var t_delta_z := INF
	if step_x != 0:
		t_delta_x = absf(CELL / d.x)
		t_max_x = (float(cx + (1 if step_x > 0 else 0)) * CELL - origin.x) / d.x
	if step_y != 0:
		t_delta_y = absf(CELL / d.y)
		t_max_y = (float(cy + (1 if step_y > 0 else 0)) * CELL - origin.y) / d.y
	if step_z != 0:
		t_delta_z = absf(CELL / d.z)
		t_max_z = (float(cz + (1 if step_z > 0 else 0)) * CELL - origin.z) / d.z
	var normal := Vector3i.ZERO
	for _i in range(256):
		var c := Vector3i(cx, cy, cz)
		if _placed.has(c):
			res.hit = true
			res.cell = c
			res.normal = normal
			return res
		if t_max_x <= t_max_y and t_max_x <= t_max_z:
			cx += step_x
			t_max_x += t_delta_x
			normal = Vector3i(-step_x, 0, 0)
		elif t_max_y <= t_max_z:
			cy += step_y
			t_max_y += t_delta_y
			normal = Vector3i(0, -step_y, 0)
		else:
			cz += step_z
			t_max_z += t_delta_z
			normal = Vector3i(0, 0, -step_z)
		if absi(cx) > GRID_HALF + 4 or absi(cz) > GRID_HALF + 4 or cy < -2 or cy > 80:
			break
	return res


# ---------------------------------------------------------------------------
# Placement
# ---------------------------------------------------------------------------
# Cell where the mouse ray meets the horizontal plane at the given layer.
func _cell_on_layer(mouse_pos: Vector2, layer: int) -> Dictionary:
	var origin := _camera.project_ray_origin(mouse_pos)
	var dir := _camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, float(layer) * CELL)
	var hit = plane.intersects_ray(origin, dir)
	if hit == null:
		return {"valid": false, "cell": Vector3i.ZERO}
	var p: Vector3 = hit
	return {"valid": true, "cell": Vector3i(int(floor(p.x / CELL)), layer, int(floor(p.z / CELL)))}

func _begin_drag() -> void:
	_dragging = true
	_did_drag = false
	_press_mouse = _last_mouse
	# Lock the drag's build height to the block under the cursor (its surface),
	# or the current layer when starting on empty ground.
	if _pick_valid:
		_drag_layer = _pick_cell.y + maxi(_pick_normal.y, 0)
	else:
		_drag_layer = _current_layer
	var t := _cell_on_layer(_last_mouse, _drag_layer)
	if t.valid:
		_drag_start = t.cell
	_refresh_preview()

func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_op_begin()
	if _did_drag:
		# Area build on the plane locked in at drag start (surface of the picked block).
		var t := _cell_on_layer(_last_mouse, _drag_layer)
		if t.valid:
			for cell in _cells_for(_current_type, _drag_start, t.cell, _drag_layer):
				_op_set(cell, _current_type)
	elif _pick_valid:
		# Single click on an existing block: attach on its face, or replace it in place.
		var cell := _pick_cell if _edit_replace else _pick_cell + _pick_normal
		_op_set(cell, _current_type)
	elif _has_plane:
		# Single click on empty ground: honour type semantics (Wall = full-height pillar).
		for cell in _cells_for(_current_type, _plane_cell, _plane_cell, _current_layer):
			_op_set(cell, _current_type)
	_op_commit()
	_did_drag = false
	_clear_preview()
	_refresh_preview()
	_update_hud()

# Returns the list of cells a drag/click would fill for the given type, at height base_y.
# Wall  -> perimeter outline of the rectangle, extruded UP by _wall_height (walls are
#          vertical: one action builds a full-height wall, not a single layer).
# Others -> filled rectangle, single layer.
func _cells_for(type: int, a: Vector3i, b: Vector3i, base_y: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var min_x := mini(a.x, b.x)
	var max_x := maxi(a.x, b.x)
	var min_z := mini(a.z, b.z)
	var max_z := maxi(a.z, b.z)
	var y := base_y
	if (max_x - min_x + 1) * (max_z - min_z + 1) > MAX_DRAG_CELLS:
		return cells
	if type == BType.ROOF:
		return _roof_cells(min_x, max_x, min_z, max_z, y)
	var perimeter := type == BType.WALL and (min_x != max_x or min_z != max_z)
	var height := _wall_height if type == BType.WALL else 1
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			if perimeter and not (x == min_x or x == max_x or z == min_z or z == max_z):
				continue
			for h in range(height):
				cells.append(Vector3i(x, y + h, z))
	return cells

# A roof footprint becomes a stepped, solid pitched roof of the active formation,
# rising from base_y. Each column is filled from base_y up to its computed height so
# the roof reads as a watertight shape rather than a flat slab.
func _roof_cells(min_x: int, max_x: int, min_z: int, max_z: int, base_y: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			var h := _roof_height(x, z, min_x, max_x, min_z, max_z)
			for k in range(h + 1):
				cells.append(Vector3i(x, base_y + k, z))
	return cells

func _roof_height(x: int, z: int, min_x: int, max_x: int, min_z: int, max_z: int) -> int:
	match _roof_style:
		RoofStyle.GABLE:
			# Symmetric ridge along the longer axis; slopes down the shorter axis.
			if (max_x - min_x) <= (max_z - min_z):
				return mini(x - min_x, max_x - x)
			return mini(z - min_z, max_z - z)
		RoofStyle.HIP:
			# Slopes on all four sides, peak in the middle.
			return mini(mini(x - min_x, max_x - x), mini(z - min_z, max_z - z))
		RoofStyle.SHED:
			# Single slope rising from one edge along the longer axis.
			if (max_x - min_x) >= (max_z - min_z):
				return x - min_x
			return z - min_z
		_:
			return 0  # FLAT

# Type at a cell, or -1 if empty.
func _cell_type(cell: Vector3i) -> int:
	return _placed[cell].get_meta("type") if _placed.has(cell) else -1

# Low-level: set a cell to a type, or remove it when type < 0. Does NOT record undo.
func _apply_cell(cell: Vector3i, type: int) -> void:
	if type < 0:
		if _placed.has(cell):
			_placed[cell].queue_free()
			_placed.erase(cell)
		return
	if _placed.has(cell):
		var mi: MeshInstance3D = _placed[cell]
		mi.material_override = _block_mats[type]
		mi.set_meta("type", type)
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = _block_mesh
		mi.material_override = _block_mats[type]
		mi.position = _cell_to_world(cell)
		mi.set_meta("type", type)
		add_child(mi)
		_placed[cell] = mi

# Undo op recording ----------------------------------------------------------
func _op_begin() -> void:
	_op = []

func _op_set(cell: Vector3i, type: int) -> void:
	var old := _cell_type(cell)
	if old == type:
		return
	_apply_cell(cell, type)
	_op.append({"cell": cell, "old": old, "new": type})

func _op_commit() -> void:
	if _op.is_empty():
		return
	_undo.append(_op)
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()
	_redo.clear()
	_op = []

func _undo_action() -> void:
	if _undo.is_empty():
		return
	var op: Array = _undo.pop_back()
	for ch in op:
		_apply_cell(ch.cell, ch.old)
	_redo.append(op)
	_update_hud()
	_update_hover_from_last()

func _redo_action() -> void:
	if _redo.is_empty():
		return
	var op: Array = _redo.pop_back()
	for ch in op:
		_apply_cell(ch.cell, ch.new)
	_undo.append(op)
	_update_hud()
	_update_hover_from_last()

# Non-recording placement, used only by the debug builder.
func _place_block(cell: Vector3i, type: int) -> void:
	_apply_cell(cell, type)

func _remove_at_hover() -> void:
	# Remove the block directly under the cursor, on any layer.
	if _pick_valid and _placed.has(_pick_cell):
		_op_begin()
		_op_set(_pick_cell, -1)
		_op_commit()
		_update_hud()
		_update_hover_from_last()

func _clear_all() -> void:
	_op_begin()
	for cell in _placed.keys():
		_op_set(cell, -1)
	_op_commit()
	_update_hud()

func _cell_to_world(cell: Vector3i) -> Vector3:
	return Vector3(
		(float(cell.x) + 0.5) * CELL,
		(float(cell.y) + 0.5) * CELL,
		(float(cell.z) + 0.5) * CELL
	)


# ---------------------------------------------------------------------------
# Ghost preview
# ---------------------------------------------------------------------------
func _refresh_preview() -> void:
	var cells: Array[Vector3i] = []
	if _dragging and _did_drag:
		var t := _cell_on_layer(_last_mouse, _drag_layer)
		if t.valid:
			cells = _cells_for(_current_type, _drag_start, t.cell, _drag_layer)
	elif _pick_valid:
		# Preview where a single click would land on the picked block.
		cells = [_pick_cell if _edit_replace else _pick_cell + _pick_normal]
	elif _has_plane:
		cells = _cells_for(_current_type, _plane_cell, _plane_cell, _current_layer)
	_show_preview(cells)
	_update_pick_highlight()

func _update_pick_highlight() -> void:
	if _pick_valid and not (_dragging and _did_drag):
		_pick_highlight.visible = true
		_pick_highlight.position = _cell_to_world(_pick_cell)
	else:
		_pick_highlight.visible = false

func _show_preview(cells: Array[Vector3i]) -> void:
	# grow pool as needed
	while _ghost_pool.size() < cells.size():
		var g := MeshInstance3D.new()
		g.mesh = _block_mesh
		_ghost_root.add_child(g)
		_ghost_pool.append(g)
	for i in range(_ghost_pool.size()):
		var g: MeshInstance3D = _ghost_pool[i]
		if i < cells.size():
			g.visible = true
			g.material_override = _ghost_mats[_current_type]
			g.position = _cell_to_world(cells[i])
		else:
			g.visible = false

func _clear_preview() -> void:
	for g in _ghost_pool:
		g.visible = false


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------
func _set_type(type: int) -> void:
	_current_type = type
	_refresh_preview()
	_update_hud()

# Debug helper — builds a full sample house in one call so the rendering path can be
# verified without simulated input. Called via the MCP execute bridge, not by gameplay.
func _debug_house() -> int:
	_clear_all()
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(5, 0, 5)
	# floor at layer 0
	for c in _cells_for(BType.FLOOR, a, b, 0):
		_place_block(c, BType.FLOOR)
	# walls: ONE action at layer 1 extrudes _wall_height blocks upward
	for c in _cells_for(BType.WALL, a, b, 1):
		_place_block(c, BType.WALL)
	# roof sits on top of the walls
	for c in _cells_for(BType.ROOF, a, b, 1 + _wall_height):
		_place_block(c, BType.ROOF)
	# a door (fixture) carved into the front wall
	_place_block(Vector3i(1, 1, 0), BType.FIXTURE)
	_place_block(Vector3i(1, 2, 0), BType.FIXTURE)
	# frame the house with the camera
	set("_cam_target", Vector3(2.5, 3.0, 2.5))
	set("_cam_dist", 22.0)
	set("_cam_pitch", 0.55)
	_update_camera()
	_update_hud()
	return _placed.size()


func _update_hud() -> void:
	_hud.text = "\n".join([
		"BAU-PROTOTYP  —  \"The Last Seal\"",
		"",
		"Typ: %s        [1] Wand  [2] Boden  [3] Dach  [4] Fixture" % TYPE_NAMES[_current_type],
		"Dachform: %s        [3] wechselt (Flach → Sattel → Walm → Pult)" % ROOF_STYLE_NAMES[_roof_style],
		"Ebene (Höhe): %d        [R] höher   [F] tiefer" % _current_layer,
		"Wandhöhe: %d Blöcke        [T] höher   [G] niedriger" % _wall_height,
		"Block-Modus: %s        [X] umschalten" % ("ERSETZEN" if _edit_replace else "Aufsetzen"),
		"Blöcke gesetzt: %d        [C] alles löschen   •   Rückgängig: Strg+Z / Strg+Y" % _placed.size(),
		"",
		"Auf leerem Boden:  Klick = Wand-Pfeiler / 1 Block   •   Ziehen = Fläche (Wand = Umriss, volle Höhe)",
		"Auf einem Block (weiß umrandet):  Klick = %s   •   Rechts-Klick = löschen" % ("ersetzen" if _edit_replace else "draufsetzen"),
		"Kamera:  Mittlere Maus ziehen = drehen  •  Q/E = drehen  •  Mausrad = zoom  •  WASD = schwenken",
	])
	if _undo_btn:
		_undo_btn.disabled = _undo.is_empty()
	if _redo_btn:
		_redo_btn.disabled = _redo.is_empty()
