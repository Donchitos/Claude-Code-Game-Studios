# Chunked-mesher feasibility prototype — throwaway code.
# Full 2000x2000 world DATA (packed chunk arrays) + meshing only inside a
# view window (culled heightfield mesher, one ArrayMesh per 16x16 chunk).
# Usage: godot --path . -- --size=2000
extends Node3D

const SpikeMetricsScript := preload("res://metrics.gd")

const SEED := 1337
const CHUNK := 16
const MAX_Y := 32
const VIEW_RADIUS := 24          # meshed window: chunks within this radius (in chunks)
const STREAM_BUDGET := 2         # max chunk meshes built per frame while streaming
const BAND_COLORS: Array[Color] = [
	Color(0.35, 0.55, 0.25), Color(0.45, 0.60, 0.30), Color(0.55, 0.55, 0.45), Color(0.60, 0.58, 0.55),
]

var world_size := 2000
var metrics := SpikeMetricsScript.new()
var rng := RandomNumberGenerator.new()
var heights := PackedByteArray()
var chunk_data := {}    # Vector2i -> PackedByteArray(CHUNK*CHUNK*MAX_Y) — FULL world, packed
var chunk_nodes := {}   # Vector2i -> MeshInstance3D — only inside the view window
var mat := StandardMaterial3D.new()
var chunks_per_axis := 0

var _stream_queue: Array[Vector2i] = []
var _streaming := false
var _stream_build_usec: Array[int] = []

@onready var cam: Camera3D = $Camera3D


func _ready() -> void:
	rng.seed = SEED
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--size="):
			world_size = int(a.get_slice("=", 1))
	chunks_per_axis = world_size / CHUNK
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # sidestep winding bugs; production culls (numbers here are conservative)
	metrics.record("meta/world", "%dx%dx%d" % [world_size, MAX_Y, world_size])
	metrics.record("meta/chunks_total", str(chunks_per_axis * chunks_per_axis))
	metrics.record("meta/view_radius_chunks", str(VIEW_RADIUS))
	_run()


func _run() -> void:
	# 1) heightmap for the FULL world
	var t0 := Time.get_ticks_usec()
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.05
	heights.resize(world_size * world_size)
	for z in world_size:
		if z % 200 == 0:
			print("PROGRESS heights z=%d/%d elapsed_ms=%.0f" % [z, world_size, (Time.get_ticks_usec() - t0) / 1000.0])
			await get_tree().process_frame
		var row := z * world_size
		for x in world_size:
			heights[row + x] = clampi(8 + int(roundf(noise.get_noise_2d(x, z) * 6.0)), 2, MAX_Y - 6)
	metrics.record("gen/heightmap_ms", "%.0f" % ((Time.get_ticks_usec() - t0) / 1000.0))

	# 2) allocate packed chunk data for the FULL world (storage feasibility)
	t0 = Time.get_ticks_usec()
	for cz in chunks_per_axis:
		for cx in chunks_per_axis:
			var arr := PackedByteArray()
			arr.resize(CHUNK * CHUNK * MAX_Y)  # zero-filled = air
			chunk_data[Vector2i(cx, cz)] = arr
	metrics.record("gen/alloc_all_chunks_ms", "%.0f" % ((Time.get_ticks_usec() - t0) / 1000.0))
	metrics.record("gen/mem_static_mb_after_alloc", "%.0f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

	# 3) fill + mesh the view window around world center
	var center_chunk := Vector2i(chunks_per_axis / 2, chunks_per_axis / 2)
	t0 = Time.get_ticks_usec()
	var built := 0
	var build_usec: Array[int] = []
	for cz in range(center_chunk.y - VIEW_RADIUS, center_chunk.y + VIEW_RADIUS):
		for cx in range(center_chunk.x - VIEW_RADIUS, center_chunk.x + VIEW_RADIUS):
			var t1 := Time.get_ticks_usec()
			_fill_chunk_data(Vector2i(cx, cz))
			_build_chunk(Vector2i(cx, cz))
			build_usec.append(Time.get_ticks_usec() - t1)
			built += 1
		if cz % 8 == 0:
			print("PROGRESS mesh cz=%d built=%d" % [cz, built])
			await get_tree().process_frame
	metrics.record("mesh/window_total_ms", "%.0f" % ((Time.get_ticks_usec() - t0) / 1000.0))
	metrics.record("mesh/window_chunks", str(built))
	_record_usec("mesh/chunk_build_usec", build_usec)

	# 4) camera phases inside the meshed window
	var center := Vector3(world_size / 2.0, 10, world_size / 2.0)
	var views := {
		"near": center + Vector3(15, 12, 20),
		"far": center + Vector3(120, 90, 170),
		"horizon": center + Vector3(300, 40, 350),
	}
	for view_name in views:
		cam.position = views[view_name]
		cam.look_at(center)
		await get_tree().create_timer(3.0).timeout
		metrics.start_phase("view_%s" % view_name)
		await get_tree().create_timer(12.0).timeout
		metrics.end_phase()

	# 5) edit bench: single-block edit -> chunk rebuild
	var edit_usec: Array[int] = []
	for i in 100:
		var cc := center_chunk + Vector2i(rng.randi_range(-VIEW_RADIUS + 1, VIEW_RADIUS - 2), rng.randi_range(-VIEW_RADIUS + 1, VIEW_RADIUS - 2))
		var col := Vector2i(rng.randi_range(0, world_size - 1) % CHUNK, rng.randi_range(0, world_size - 1) % CHUNK)
		var gx := cc.x * CHUNK + col.x
		var gz := cc.y * CHUNK + col.y
		var t1 := Time.get_ticks_usec()
		heights[gz * world_size + gx] = mini(heights[gz * world_size + gx] + 1, MAX_Y - 1)
		_fill_chunk_data(cc)
		_build_chunk(cc)
		edit_usec.append(Time.get_ticks_usec() - t1)
	_record_usec("edit/rebuild_usec", edit_usec)

	# 6) streaming: camera flies +X, new chunks mesh on the fly (budgeted)
	_streaming = true
	metrics.start_phase("streaming_flight")
	var flight_time := 20.0
	var elapsed := 0.0
	cam.position = center + Vector3(0, 60, 0)
	cam.look_at(center + Vector3(200, 0, 0))
	while elapsed < flight_time:
		var dt := get_process_delta_time()
		elapsed += dt
		cam.position.x += 25.0 * dt
		_update_stream_window()
		await get_tree().process_frame
	metrics.end_phase()
	_streaming = false
	_record_usec("streaming/chunk_build_usec", _stream_build_usec)
	metrics.record("streaming/chunks_built", str(_stream_build_usec.size()))

	metrics.record("meta/mem_static_mb_final", "%.0f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	metrics.record("meta/video_mem_mb", "%.0f" % (RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0))
	metrics.save_csv("res://results/chunked_%d.csv" % world_size)
	print("SPIKE_DONE chunked %d" % world_size)
	get_tree().quit()


func _process(delta: float) -> void:
	if metrics.sampling:
		metrics.sample(delta)


func _record_usec(key: String, samples: Array[int]) -> void:
	var st: Dictionary = SpikeMetricsScript.usec_stats(samples)
	metrics.record("%s_avg" % key, "%.1f" % st["avg"])
	metrics.record("%s_p95" % key, str(st["p95"]))
	metrics.record("%s_worst" % key, str(st["worst"]))
	metrics.record("%s_n" % key, str(st["n"]))


func _height_at(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= world_size or z >= world_size:
		return 0
	return heights[z * world_size + x]


func _fill_chunk_data(cc: Vector2i) -> void:
	# packed bytes: index = (ly * CHUNK + lz) * CHUNK + lx ; value = material band
	var arr: PackedByteArray = chunk_data[cc]
	for lz in CHUNK:
		var gz := cc.y * CHUNK + lz
		for lx in CHUNK:
			var h := _height_at(cc.x * CHUNK + lx, gz)
			for ly in h:
				arr[(ly * CHUNK + lz) * CHUNK + lx] = 1 + (ly * 3) / MAX_Y


func _build_chunk(cc: Vector2i) -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for lz in CHUNK:
		var gz := cc.y * CHUNK + lz
		for lx in CHUNK:
			var gx := cc.x * CHUNK + lx
			var h := _height_at(gx, gz)
			var col := BAND_COLORS[clampi((h - 2) / 4, 0, 3)]
			var fx := float(gx)
			var fz := float(gz)
			var fh := float(h)
			# top face
			_quad(verts, normals, colors, indices,
				Vector3(fx, fh, fz), Vector3(fx + 1, fh, fz), Vector3(fx + 1, fh, fz + 1), Vector3(fx, fh, fz + 1),
				Vector3.UP, col)
			# side faces where neighbor column is lower (one tall quad per side — vertically greedy)
			var hn := _height_at(gx + 1, gz)
			if hn < h:
				_quad(verts, normals, colors, indices,
					Vector3(fx + 1, hn, fz), Vector3(fx + 1, fh, fz), Vector3(fx + 1, fh, fz + 1), Vector3(fx + 1, hn, fz + 1),
					Vector3.RIGHT, col.darkened(0.2))
			hn = _height_at(gx - 1, gz)
			if hn < h:
				_quad(verts, normals, colors, indices,
					Vector3(fx, hn, fz), Vector3(fx, fh, fz), Vector3(fx, fh, fz + 1), Vector3(fx, hn, fz + 1),
					Vector3.LEFT, col.darkened(0.2))
			hn = _height_at(gx, gz + 1)
			if hn < h:
				_quad(verts, normals, colors, indices,
					Vector3(fx, hn, fz + 1), Vector3(fx, fh, fz + 1), Vector3(fx + 1, fh, fz + 1), Vector3(fx + 1, hn, fz + 1),
					Vector3.BACK, col.darkened(0.35))
			hn = _height_at(gx, gz - 1)
			if hn < h:
				_quad(verts, normals, colors, indices,
					Vector3(fx, hn, fz), Vector3(fx, fh, fz), Vector3(fx + 1, fh, fz), Vector3(fx + 1, hn, fz),
					Vector3.FORWARD, col.darkened(0.35))
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	if chunk_nodes.has(cc):
		(chunk_nodes[cc] as MeshInstance3D).mesh = mesh
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.visibility_range_end = 600.0
		add_child(mi)
		chunk_nodes[cc] = mi


func _quad(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	var base := verts.size()
	verts.append_array([a, b, c, d])
	for i in 4:
		normals.append(n)
		colors.append(col)
	indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


func _update_stream_window() -> void:
	var cam_chunk := Vector2i(int(cam.position.x) / CHUNK, int(cam.position.z) / CHUNK)
	# enqueue missing chunks in radius (front strip first)
	for dz in range(-VIEW_RADIUS, VIEW_RADIUS):
		for dx in range(-VIEW_RADIUS, VIEW_RADIUS):
			var cc := cam_chunk + Vector2i(dx, dz)
			if cc.x < 0 or cc.y < 0 or cc.x >= chunks_per_axis or cc.y >= chunks_per_axis:
				continue
			if not chunk_nodes.has(cc) and not _stream_queue.has(cc):
				_stream_queue.append(cc)
	# build at most STREAM_BUDGET per frame
	var budget := STREAM_BUDGET
	while budget > 0 and not _stream_queue.is_empty():
		var cc: Vector2i = _stream_queue.pop_front()
		var t := Time.get_ticks_usec()
		_fill_chunk_data(cc)
		_build_chunk(cc)
		_stream_build_usec.append(Time.get_ticks_usec() - t)
		budget -= 1
	# unload chunks far behind
	for cc in chunk_nodes.keys():
		if abs(cc.x - cam_chunk.x) > VIEW_RADIUS + 4 or abs(cc.y - cam_chunk.y) > VIEW_RADIUS + 4:
			(chunk_nodes[cc] as MeshInstance3D).queue_free()
			chunk_nodes.erase(cc)
