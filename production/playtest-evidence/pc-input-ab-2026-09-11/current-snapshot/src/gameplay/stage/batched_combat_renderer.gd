class_name BatchedCombatRenderer
extends Node2D

const KIND_BEETLE := 0
const KIND_WOLF := 1
const KIND_SUMMON := 3
const NORMAL_GEOMETRY_TAG := 0.0
const WOLF_GEOMETRY_TAG := 0.5

var _enemy_batch: MultiMeshInstance2D
var _projectile_batch: MultiMeshInstance2D
var _enemy_count := 0
var _projectile_count := 0
var _initialized := false


## Allocates fixed-capacity geometry batches. Example: `renderer.initialize(320, 392, 19.0, 15.0, 9.0)`.
func initialize(enemy_capacity: int, projectile_capacity: int, beetle_radius: float, wolf_radius: float, projectile_radius: float) -> bool:
	if _initialized or enemy_capacity <= 0 or projectile_capacity <= 0:
		return false
	if not is_finite(beetle_radius) or beetle_radius <= 0.0 or not is_finite(wolf_radius) or wolf_radius <= 0.0 or not is_finite(projectile_radius) or projectile_radius <= 0.0:
		return false
	_enemy_batch = _make_batch(_make_enemy_mesh(beetle_radius, wolf_radius), enemy_capacity, true)
	_enemy_batch.name = "EnemyGeometryBatch"
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
void vertex() {
	if (abs(INSTANCE_CUSTOM.r - UV.x) > 0.1) {
		VERTEX = vec2(0.0);
	}
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	_enemy_batch.material = material
	add_child(_enemy_batch)
	_projectile_batch = _make_batch(_make_projectile_mesh(projectile_radius), projectile_capacity, false)
	_projectile_batch.name = "ProjectileGeometryBatch"
	add_child(_projectile_batch)
	_initialized = true
	finish_frame()
	return true


## Starts a new presentation frame without reallocating instance storage. Example: `renderer.begin_frame()`.
func begin_frame() -> void:
	_enemy_count = 0
	_projectile_count = 0


## Appends one visible non-Boss enemy in caller order. Example: `renderer.append_enemy(kind, position)`.
func append_enemy(kind: int, position_value: Vector2, scale_value: Vector2 = Vector2.ONE) -> bool:
	if not _initialized or _enemy_count >= _enemy_batch.multimesh.instance_count or not position_value.is_finite() or not scale_value.is_finite():
		return false
	if kind not in [KIND_BEETLE, KIND_WOLF, KIND_SUMMON]:
		return false
	var transform := Transform2D(0.0, position_value).scaled_local(scale_value)
	_enemy_batch.multimesh.set_instance_transform_2d(_enemy_count, transform)
	_enemy_batch.multimesh.set_instance_custom_data(_enemy_count, Color(WOLF_GEOMETRY_TAG if kind == KIND_WOLF else NORMAL_GEOMETRY_TAG, 0.0, 0.0, 0.0))
	_enemy_count += 1
	return true


## Appends one visible friendly projectile in caller order. Example: `renderer.append_projectile(position, velocity)`.
func append_projectile(position_value: Vector2, velocity: Vector2, scale_value: Vector2 = Vector2.ONE) -> bool:
	if not _initialized or _projectile_count >= _projectile_batch.multimesh.instance_count or not position_value.is_finite() or not velocity.is_finite() or velocity.is_zero_approx() or not scale_value.is_finite():
		return false
	var transform := Transform2D(velocity.angle(), position_value).scaled_local(scale_value)
	_projectile_batch.multimesh.set_instance_transform_2d(_projectile_count, transform)
	_projectile_count += 1
	return true


## Publishes the compact visible prefixes to RenderingServer. Example: `renderer.finish_frame()`.
func finish_frame() -> void:
	if not _initialized:
		return
	_enemy_batch.multimesh.visible_instance_count = _enemy_count
	_projectile_batch.multimesh.visible_instance_count = _projectile_count


## Reports the submitted visible prefixes for tests and diagnostics. Example: `renderer.visible_counts()`.
func visible_counts() -> Vector2i:
	return Vector2i(_enemy_count, _projectile_count)


func _make_batch(mesh: Mesh, capacity: int, custom_data: bool) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	node.multimesh.use_custom_data = custom_data
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = capacity
	return node


func _make_enemy_mesh(beetle_radius: float, wolf_radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_circle(surface, beetle_radius + 4.0, Color(0.0, 0.0, 0.0, 0.3), NORMAL_GEOMETRY_TAG)
	_add_circle(surface, beetle_radius, Color("a93d49"), NORMAL_GEOMETRY_TAG)
	var points := [Vector2(0.0, -wolf_radius), Vector2(wolf_radius, 0.0), Vector2(0.0, wolf_radius), Vector2(-wolf_radius, 0.0)]
	for index in 4:
		_add_line(surface, points[index], points[(index + 1) % 4], 9.0, Color("e17a45"), WOLF_GEOMETRY_TAG)
	return surface.commit()


func _make_projectile_mesh(projectile_radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_line(surface, Vector2(-16.0, 0.0), Vector2(12.0, 0.0), 7.0, Color("d6f5ff"), 0.0)
	_add_circle(surface, projectile_radius, Color("80d9ef"), 0.0)
	return surface.commit()


func _add_circle(surface: SurfaceTool, radius: float, color: Color, geometry_tag: float, segments: int = 64) -> void:
	for index in segments:
		var angle_a := TAU * index / segments
		var angle_b := TAU * (index + 1) / segments
		_add_triangle(surface, Vector2.ZERO, Vector2(cos(angle_a), sin(angle_a)) * radius, Vector2(cos(angle_b), sin(angle_b)) * radius, color, geometry_tag)


func _add_line(surface: SurfaceTool, from: Vector2, to: Vector2, width: float, color: Color, geometry_tag: float) -> void:
	var normal := from.direction_to(to).orthogonal() * width * 0.5
	_add_triangle(surface, from - normal, to - normal, to + normal, color, geometry_tag)
	_add_triangle(surface, from - normal, to + normal, from + normal, color, geometry_tag)


func _add_triangle(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, color: Color, geometry_tag: float) -> void:
	for point in [a, b, c]:
		surface.set_color(color)
		surface.set_uv(Vector2(geometry_tag, 0.0))
		surface.add_vertex(Vector3(point.x, point.y, 0.0))
