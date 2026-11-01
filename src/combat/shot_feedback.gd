extends Node3D
## Short-lived tracers and synthesized shot/impact sound; effects can be reduced together.

var reduced := false
var _effects: Array[Dictionary] = []
var _casings: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _decals: Array[Dictionary] = []
var _audio: AudioStreamPlayer
var _tones: Dictionary = {}

const MAX_DECALS: int = 32

func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.max_polyphony = 8
	_audio.volume_db = -20.0
	add_child(_audio)

func _exit_tree() -> void:
	_audio.stop()
	_audio.stream = null
	_tones.clear()


func _process(delta: float) -> void:
	for index in range(_effects.size() - 1, -1, -1):
		_effects[index].remaining -= delta
		if _effects[index].remaining <= 0.0:
			_effects[index].node.queue_free()
			_effects.remove_at(index)

	for index in range(_casings.size() - 1, -1, -1):
		var casing: Dictionary = _casings[index]
		casing.remaining -= delta
		if casing.remaining <= 0.0:
			casing.node.queue_free()
			_casings.remove_at(index)
			continue
		casing.velocity.y -= 22.0 * delta
		var pos: Vector3 = casing.node.global_position + casing.velocity * delta
		if pos.y <= 0.02:
			pos.y = 0.02
			casing.velocity.y = -casing.velocity.y * 0.35
			casing.velocity.x *= 0.65
			casing.velocity.z *= 0.65
			casing.spin *= 0.65
		casing.node.global_position = pos
		casing.node.rotation += casing.spin * delta

	for index in range(_sparks.size() - 1, -1, -1):
		var spark: Dictionary = _sparks[index]
		spark.remaining -= delta
		if spark.remaining <= 0.0:
			spark.node.queue_free()
			_sparks.remove_at(index)
			continue
		spark.velocity.y -= 14.0 * delta
		spark.node.global_position += spark.velocity * delta

	for index in range(_decals.size() - 1, -1, -1):
		var decal: Dictionary = _decals[index]
		decal.remaining -= delta
		if decal.remaining <= 0.0:
			decal.node.queue_free()
			_decals.remove_at(index)
		elif decal.remaining < 2.0:
			var mat: StandardMaterial3D = decal.node.material_override
			mat.albedo_color.a = decal.remaining / 2.0

## Show a bounded short tracer; hit tint confirms actual target damage, not every collision.
func trace_shot(start: Vector3, finish: Vector3, hit: bool) -> void:
	var length: float = start.distance_to(finish)
	if length <= 0.001:
		return
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.018 if reduced else 0.035, 0.018, length)
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffae73") if hit else Color("c6e8df")
	visual.material_override = material
	add_child(visual)
	visual.global_position = (start + finish) * 0.5
	visual.look_at(finish)
	_effects.append({"node": visual, "remaining": 0.05 if reduced else 0.08})

## Emit procedural shot and impact audio without external assets.
func play_tone(hz: float, impact := false) -> void:
	if reduced:
		return
	var key := "%s:%s" % [hz, impact]
	if not _tones.has(key):
		var data := PackedByteArray()
		var count := 1600 if impact else 3200
		for sample in range(count):
			var t: float = float(sample) / float(count)
			var envelope: float = pow(1.0 - t, 4.0 if impact else 2.5)
			var wave: float = sin(TAU * hz * sample / 22050.0)
			# Shotgun low-end blast noise
			if hz <= 90.0:
				wave = wave * 0.7 + randf_range(-0.3, 0.3)
			# Shock electric harmonic
			elif hz >= 400.0 and not impact:
				wave = wave * 0.65 + sin(TAU * hz * 2.5 * sample / 22050.0) * 0.35
			var value: float = clampf(wave * envelope, -1.0, 1.0)
			data.append(int(value * 120.0) & 255)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_8_BITS
		stream.mix_rate = 22050
		stream.data = data
		_tones[key] = stream
	_audio.stream = _tones[key]
	_audio.play()

## Remove active effects on reset and pause their lifetime/audio with gameplay.
func eject_casing(origin: Vector3, right_dir: Vector3) -> void:
	if reduced and randf() > 0.5:
		return
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, 0.08)
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d4af37")
	mat.metallic = 0.85
	mat.roughness = 0.35
	visual.material_override = mat
	add_child(visual)
	visual.global_position = origin
	var r: Vector3 = right_dir.normalized() if not right_dir.is_zero_approx() else Vector3.RIGHT
	var vel: Vector3 = r * randf_range(1.6, 2.4) + Vector3.UP * randf_range(1.6, 2.5) + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	var spin: Vector3 = Vector3(randf_range(-18, 18), randf_range(-18, 18), randf_range(-18, 18))
	_casings.append({
		"node": visual,
		"velocity": vel,
		"spin": spin,
		"remaining": 0.6 if reduced else 1.4
	})


## Spawn short burst of spark particles upon impact with target or surface.
## Also emits a directional ricochet spark bouncing off the surface normal.
func spawn_impact_sparks(point: Vector3, normal: Vector3, hit: bool, incoming_dir: Vector3 = Vector3.ZERO) -> void:
	var count: int = 2 if reduced else 5
	var color: Color = Color("ffa64d") if hit else Color("c0d8f0")
	var n: Vector3 = normal.normalized() if not normal.is_zero_approx() else Vector3.UP
	for i in range(count):
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.025, 0.025, 0.025)
		visual.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		visual.material_override = mat
		add_child(visual)
		visual.global_position = point
		var rand_dir: Vector3 = (n + Vector3(randf_range(-0.8, 0.8), randf_range(0.2, 0.8), randf_range(-0.8, 0.8))).normalized()
		var vel: Vector3 = rand_dir * randf_range(2.5, 5.5)
		_sparks.append({
			"node": visual,
			"velocity": vel,
			"remaining": 0.12 if reduced else 0.18
		})

	# Ricochet spark bouncing off surface
	if not hit and not incoming_dir.is_zero_approx() and not reduced:
		var rico_dir: Vector3 = incoming_dir.normalized().bounce(n)
		var rico_mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.02, 0.06)
		rico_mesh.mesh = box
		var rico_mat := StandardMaterial3D.new()
		rico_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rico_mat.albedo_color = Color("fff0aa")
		rico_mesh.material_override = rico_mat
		add_child(rico_mesh)
		rico_mesh.global_position = point + n * 0.04
		_sparks.append({
			"node": rico_mesh,
			"velocity": rico_dir * randf_range(9.0, 15.0),
			"remaining": 0.15
		})


## Spawn a persistent bullet hole / scorch decal on hit surface.
func spawn_impact_decal(point: Vector3, normal: Vector3) -> void:
	if reduced:
		return

	# Limit maximum active decals to preserve performance
	if _decals.size() >= MAX_DECALS:
		var oldest: Dictionary = _decals.pop_front()
		if is_instance_valid(oldest.node):
			oldest.node.queue_free()

	var decal := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.012, 0.12)
	decal.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.14, 0.16, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	decal.material_override = mat
	add_child(decal)

	var n: Vector3 = normal.normalized() if not normal.is_zero_approx() else Vector3.UP
	decal.global_position = point + n * 0.008

	if absf(n.y) > 0.95:
		decal.rotation.x = 0.0
	else:
		decal.look_at(point + n * 2.0, Vector3.UP)
		decal.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

	_decals.append({
		"node": decal,
		"remaining": 8.0
	})


func reset_effects() -> void:
	for effect in _effects:
		effect.node.queue_free()
	_effects.clear()
	for casing in _casings:
		casing.node.queue_free()
	_casings.clear()
	for spark in _sparks:
		spark.node.queue_free()
	_sparks.clear()
	for decal in _decals:
		decal.node.queue_free()
	_decals.clear()
	_audio.stop()

func set_paused(value: bool) -> void:
	set_process(not value)
	_audio.stream_paused = value
