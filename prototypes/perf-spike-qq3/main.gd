# Performance Spike QQ3 driver — throwaway prototype code (see PLAN.md).
# Usage: godot --path . -- --scenario=s1 --config=c2
extends Node3D

const SpikeMetricsScript := preload("res://metrics.gd")
const NavGraphScript := preload("res://nav_graph.gd")

const SEED := 1337
const TICK_LEN := 0.1  # 10 ticks/sec at 1x [assumption — Time & Tick rate TBD]
const VILLAGER_COUNT := 30
var max_deciding_per_tick := 4  # overridable via --mdpt=N
const CANDIDATES_PER_PASS := 15   # max_selection_candidates (GDD)
const BFS_LIMIT := 200            # bounded reachability check per candidate
const WRITES_PER_SEC := 20.0      # write-storm rate at 1x
const MOVE_SPEED := 3.0           # cells/sec at 1x

var scenario := "s1"
var config := "c2"
var world_w := 100
var world_d := 100
var world_max_y := 32
var base_h := 8
var amp := 6

var metrics := SpikeMetricsScript.new()
var rng := RandomNumberGenerator.new()
var occ := {}  # Vector3i -> material id
var gm: GridMap
var nav := NavGraphScript.new()

# S2 state
var villagers: Array[Dictionary] = []
var deciding_queue: Array[int] = []
var warp := 1.0
var tick_accum := 0.0
var s2_running := false
var patch_usec: Array[int] = []
var query_usec: Array[int] = []
var deciding_usec: Array[int] = []
var write_accum := 0.0
var toggled: Array[Vector3i] = []

@onready var cam: Camera3D = $Camera3D


func _ready() -> void:
	rng.seed = SEED
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			scenario = a.get_slice("=", 1)
		elif a.begins_with("--config="):
			config = a.get_slice("=", 1)
		elif a.begins_with("--mdpt="):
			max_deciding_per_tick = int(a.get_slice("=", 1))
		elif a.begins_with("--size="):
			var s := int(a.get_slice("=", 1))
			world_w = s
			world_d = s
			config = "size%d" % s
	if config == "c1":
		world_w = 64; world_d = 64; world_max_y = 16; base_h = 4; amp = 3
	metrics.record("meta/scenario", scenario)
	metrics.record("meta/config", config)
	metrics.record("meta/world", "%dx%dx%d" % [world_w, world_max_y, world_d])
	metrics.record("meta/seed", str(SEED))
	_run()


func _run() -> void:
	match scenario:
		"s1":
			await _scenario_s1()
		"s2":
			await _scenario_s2()
		"s4":
			await _scenario_s4()
		"s5":
			await _scenario_s5()
	metrics.record("meta/mem_static_mb", "%.1f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	var suffix := "_mdpt%d" % max_deciding_per_tick if scenario == "s2" else ""
	metrics.record("meta/mdpt", str(max_deciding_per_tick))
	metrics.save_csv("res://results/%s_%s%s.csv" % [scenario, config, suffix])
	print("SPIKE_DONE %s %s" % [scenario, config])
	get_tree().quit()


func _process(delta: float) -> void:
	if metrics.sampling:
		metrics.sample(delta)
	if s2_running:
		_s2_process(delta)


# ---------- world generation ----------

func _build_world() -> void:
	var lib := MeshLibrary.new()
	var colors: Array[Color] = [Color(0.55, 0.36, 0.2), Color(0.55, 0.55, 0.58), Color(0.83, 0.72, 0.35)]
	for i in 3:
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mesh.material = mat
		lib.create_item(i)
		lib.set_item_mesh(i, mesh)  # no collision shapes: picking is DDA (ADR-0003)
	gm = GridMap.new()
	gm.mesh_library = lib
	gm.cell_size = Vector3.ONE
	add_child(gm)

	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.05
	var t0 := Time.get_ticks_usec()
	# Terrain: full columns (naive GridMap worst case — deliberate, see PLAN.md)
	for x in world_w:
		if x % 10 == 0:
			var mem_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
			print("PROGRESS terrain x=%d/%d occ=%d elapsed_ms=%.0f mem_mb=%.0f" % [x, world_w, occ.size(), (Time.get_ticks_usec() - t0) / 1000.0, mem_mb])
			if mem_mb > 6000.0:  # memory guard: abort cleanly instead of OOM-crashing
				metrics.record("build/ABORTED_mem_guard_mb", "%.0f" % mem_mb)
				metrics.record("build/aborted_at_cells", str(occ.size()))
				metrics.save_csv("res://results/%s_%s_ABORTED.csv" % [scenario, config])
				print("SPIKE_DONE %s %s (MEM GUARD ABORT)" % [scenario, config])
				get_tree().quit()
				return
		for z in world_d:
			var h := clampi(base_h + int(roundf(noise.get_noise_2d(x, z) * amp)), 1, world_max_y - 6)
			for y in h:
				_set_cell(Vector3i(x, y, z), 1, false)
	# Settlement: 8x8 houses on a 14-cell grid, walls h3 + floor + roof slab
	var houses := 0
	var x0 := 4
	while x0 + 8 < world_w - 4:
		var z0 := 4
		while z0 + 8 < world_d - 4:
			houses += 1
			var gh := clampi(base_h + int(roundf(noise.get_noise_2d(x0 + 4, z0 + 4) * amp)), 1, world_max_y - 6)
			for hx in range(x0, x0 + 8):
				for hz in range(z0, z0 + 8):
					_set_cell(Vector3i(hx, gh, hz), 0, false)          # floor
					_set_cell(Vector3i(hx, gh + 4, hz), 2, false)      # roof
					var edge := hx == x0 or hx == x0 + 7 or hz == z0 or hz == z0 + 7
					if edge and not (hx == x0 + 3 and hz == z0):        # door gap
						for wy in range(gh + 1, gh + 4):
							_set_cell(Vector3i(hx, wy, hz), 0, false)  # walls
			z0 += 14
		x0 += 14
	var populate_ms := (Time.get_ticks_usec() - t0) / 1000.0
	metrics.record("build/populate_ms", "%.1f" % populate_ms)
	metrics.record("build/cells", str(occ.size()))
	metrics.record("build/houses", str(houses))


func _set_cell(c: Vector3i, mat: int, do_patch: bool) -> void:
	occ[c] = mat
	gm.set_cell_item(c, mat)
	if do_patch:
		var t := Time.get_ticks_usec()
		nav.patch(c)
		patch_usec.append(Time.get_ticks_usec() - t)


func _clear_cell(c: Vector3i, do_patch: bool) -> void:
	occ.erase(c)
	gm.set_cell_item(c, GridMap.INVALID_CELL_ITEM)
	if do_patch:
		var t := Time.get_ticks_usec()
		nav.patch(c)
		patch_usec.append(Time.get_ticks_usec() - t)


func _build_nav() -> void:
	nav.occ = occ
	nav.max_y = world_max_y
	var t0 := Time.get_ticks_usec()
	nav.build(world_w, world_d)
	metrics.record("nav/build_ms", "%.1f" % ((Time.get_ticks_usec() - t0) / 1000.0))
	metrics.record("nav/points", str(nav.standable_ids.size()))


# ---------- S1: rendering scale ----------

func _scenario_s1() -> void:
	cam.far = maxf(500.0, world_w * 2.5)
	_build_world()
	var center := Vector3(world_w / 2.0, float(base_h), world_d / 2.0)
	var views := {
		"near": center + Vector3(10, 8, 14),
		"far": center + Vector3(30, 25, 45),
		"full": center + Vector3(float(world_w) * 0.7, float(world_w) * 0.55, float(world_d) * 0.75),
	}
	for view_name in views:
		cam.position = views[view_name]
		cam.look_at(center)
		await get_tree().create_timer(3.0).timeout   # settle
		metrics.start_phase("s1_%s" % view_name)
		await get_tree().create_timer(15.0).timeout
		metrics.end_phase()


# ---------- S2/S3: villager stress + nav dynamics ----------

func _scenario_s2() -> void:
	_build_world()
	_build_nav()
	_spawn_villagers()
	cam.position = Vector3(world_w / 2.0, 30, world_d * 0.9)
	cam.look_at(Vector3(world_w / 2.0, base_h, world_d / 2.0))
	await get_tree().create_timer(5.0).timeout  # warmup

	for phase in [{"name": "s2_warp1", "warp": 1.0}, {"name": "s2_warp3", "warp": 3.0}]:
		warp = phase["warp"]
		patch_usec.clear(); query_usec.clear(); deciding_usec.clear()
		s2_running = true
		metrics.start_phase(phase["name"])
		await get_tree().create_timer(30.0).timeout
		# S2b: synchronized mass-Deciding spike mid-phase
		for i in villagers.size():
			_enqueue_deciding(i)
		await get_tree().create_timer(30.0).timeout
		metrics.end_phase()
		s2_running = false
		_record_usec("%s/patch_usec" % phase["name"], patch_usec)
		_record_usec("%s/query_usec" % phase["name"], query_usec)
		_record_usec("%s/deciding_pass_usec" % phase["name"], deciding_usec)

	# S3 dedicated query bench: 200 random long paths
	var bench: Array[int] = []
	for i in 200:
		var a := nav.random_standable(rng)
		var b := nav.random_standable(rng)
		var t := Time.get_ticks_usec()
		var path := nav.astar.get_point_path(a, b)
		bench.append(Time.get_ticks_usec() - t)
		if path.is_empty():
			metrics.record("s3/unconnected_pair_%d" % i, "1")
	_record_usec("s3/query_bench_usec", bench)


func _record_usec(key: String, samples: Array[int]) -> void:
	var st: Dictionary = SpikeMetricsScript.usec_stats(samples)
	metrics.record("%s_avg" % key, "%.1f" % st["avg"])
	metrics.record("%s_p95" % key, str(st["p95"]))
	metrics.record("%s_worst" % key, str(st["worst"]))
	metrics.record("%s_n" % key, str(st["n"]))


func _spawn_villagers() -> void:
	for i in VILLAGER_COUNT:
		var body := Area3D.new()  # per ADR-0004: Area3D, layer 1, mask 0
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = CapsuleShape3D.new()
		body.add_child(shape)
		var vis := MeshInstance3D.new()
		vis.mesh = CapsuleMesh.new()
		body.add_child(vis)
		add_child(body)
		var start := nav.random_standable(rng)
		body.position = nav.astar.get_point_position(start)
		villagers.append({
			"node": body, "state": "deciding", "path": PackedVector3Array(),
			"path_i": 0, "cooldown": 0,
		})
		_enqueue_deciding(i)


func _enqueue_deciding(i: int) -> void:
	if not deciding_queue.has(i):
		deciding_queue.append(i)
		villagers[i]["state"] = "deciding"


func _s2_process(delta: float) -> void:
	var game_delta := delta * warp
	# write-storm
	write_accum += game_delta * WRITES_PER_SEC
	while write_accum >= 1.0:
		write_accum -= 1.0
		_storm_write()
	# ticks
	tick_accum += game_delta
	var safety := 0
	while tick_accum >= TICK_LEN and safety < 12:
		tick_accum -= TICK_LEN
		safety += 1
		_tick()
	# movement (interpolated on game_delta)
	for v in villagers:
		if v["state"] != "traveling":
			continue
		var node: Area3D = v["node"]
		var path: PackedVector3Array = v["path"]
		var idx: int = v["path_i"]
		if idx >= path.size():
			v["state"] = "deciding"
			_enqueue_deciding(villagers.find(v))
			continue
		var target: Vector3 = path[idx]
		var step := MOVE_SPEED * game_delta
		if node.position.distance_to(target) <= step:
			node.position = target
			v["path_i"] = idx + 1
		else:
			node.position += (target - node.position).normalized() * step


func _storm_write() -> void:
	if toggled.size() > 40:
		_clear_cell(toggled.pop_front(), true)
		return
	var id := nav.random_standable(rng)
	if id < 0:
		return
	var pos := nav.astar.get_point_position(id)
	var c := Vector3i(int(pos.x), int(pos.y), int(pos.z))
	_set_cell(c, 0, true)
	toggled.append(c)


func _tick() -> void:
	var budget := max_deciding_per_tick
	while budget > 0 and not deciding_queue.is_empty():
		budget -= 1
		var i: int = deciding_queue.pop_front()
		var t := Time.get_ticks_usec()
		_deciding_pass(i)
		deciding_usec.append(Time.get_ticks_usec() - t)


func _deciding_pass(i: int) -> void:
	var v := villagers[i]
	var node: Area3D = v["node"]
	var from := Vector3i(int(node.position.x), int(node.position.y), int(node.position.z))
	# unreachable-job-dense: scan 15 candidates, bounded BFS each, all fail
	for c in CANDIDATES_PER_PASS:
		var target_id := nav.random_standable(rng)
		var tp := nav.astar.get_point_position(target_id)
		var target := Vector3i(int(tp.x), int(tp.y), int(tp.z))
		nav.bounded_bfs_reachable(from, target, BFS_LIMIT)  # result ignored: cost is the point
	# then wander: real AStar path to a random standable cell
	var t := Time.get_ticks_usec()
	var from_id: int = NavGraphScript.pack(from)
	if not nav.astar.has_point(from_id):
		from_id = nav.random_standable(rng)
	var path: PackedVector3Array = nav.astar.get_point_path(from_id, nav.random_standable(rng))
	query_usec.append(Time.get_ticks_usec() - t)
	if path.is_empty():
		_enqueue_deciding(i)
		return
	v["path"] = path
	v["path_i"] = 0
	v["state"] = "traveling"


# ---------- S5 (QQ5): region-bounded nav graph on the large world ----------
# Data-only (no GridMap, no full-world occupancy — Dictionary fills region+margin
# with near-surface cells + houses, mirroring what standability actually touches).

func _scenario_s5() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.05
	nav.occ = occ
	nav.max_y = world_max_y
	for region_size: int in [100, 200, 300, 400]:
		occ.clear()
		var x0 := world_w / 2 - region_size / 2
		var t0 := Time.get_ticks_usec()
		for x in range(x0 - 2, x0 + region_size + 2):
			for z in range(x0 - 2, x0 + region_size + 2):
				var h := clampi(8 + int(roundf(noise.get_noise_2d(x, z) * 6.0)), 2, world_max_y - 6)
				for y in range(maxi(0, h - 4), h):
					occ[Vector3i(x, y, z)] = 1
		# settlement houses inside the region (same 14-cell grid as _build_world)
		var hx := x0 + 4
		while hx + 8 < x0 + region_size - 4:
			var hz := x0 + 4
			while hz + 8 < x0 + region_size - 4:
				var gh := clampi(8 + int(roundf(noise.get_noise_2d(hx + 4, hz + 4) * 6.0)), 2, world_max_y - 6)
				for lx in range(hx, hx + 8):
					for lz in range(hz, hz + 8):
						occ[Vector3i(lx, gh, lz)] = 1
						occ[Vector3i(lx, gh + 4, lz)] = 1
						var edge := lx == hx or lx == hx + 7 or lz == hz or lz == hz + 7
						if edge and not (lx == hx + 3 and lz == hz):
							for wy in range(gh + 1, gh + 4):
								occ[Vector3i(lx, wy, lz)] = 1
				hz += 14
			hx += 14
		metrics.record("s5_r%d/fill_ms" % region_size, "%.0f" % ((Time.get_ticks_usec() - t0) / 1000.0))
		metrics.record("s5_r%d/occ_cells" % region_size, str(occ.size()))

		t0 = Time.get_ticks_usec()
		nav.build_region(x0, x0, x0 + region_size, x0 + region_size)
		metrics.record("s5_r%d/build_ms" % region_size, "%.0f" % ((Time.get_ticks_usec() - t0) / 1000.0))
		metrics.record("s5_r%d/points" % region_size, str(nav.standable_ids.size()))
		metrics.record("s5_r%d/mem_mb" % region_size, "%.0f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

		var bench: Array[int] = []
		for i in 200:
			var a := nav.random_standable(rng)
			var b := nav.random_standable(rng)
			var t1 := Time.get_ticks_usec()
			nav.astar.get_point_path(a, b)
			bench.append(Time.get_ticks_usec() - t1)
		_record_usec("s5_r%d/query_usec" % region_size, bench)

		var patch_bench: Array[int] = []
		for i in 200:
			var id := nav.random_standable(rng)
			var pos := nav.astar.get_point_position(id)
			var c := Vector3i(int(pos.x), int(pos.y), int(pos.z))
			var t1 := Time.get_ticks_usec()
			occ[c] = 1
			nav.patch(c)
			patch_bench.append(Time.get_ticks_usec() - t1)
			t1 = Time.get_ticks_usec()
			occ.erase(c)
			nav.patch(c)
			patch_bench.append(Time.get_ticks_usec() - t1)
		_record_usec("s5_r%d/patch_usec" % region_size, patch_bench)
		await get_tree().process_frame
	await get_tree().process_frame


# ---------- S4: BFS on merged structures ----------

func _scenario_s4() -> void:
	_build_world()
	nav.occ = occ
	nav.max_y = world_max_y
	# merged slab structures of increasing footprint, BFS full-region pass
	for target_size in [1000, 5000, 20000, 60000]:
		var region := {}
		var y := 0
		while region.size() < target_size and y < world_max_y:
			for x in world_w:
				for z in world_d:
					if region.size() >= target_size:
						break
					region[Vector3i(x, y, z)] = true
			y += 1
		var t0 := Time.get_ticks_usec()
		var seen := {}
		var frontier: Array[Vector3i] = [region.keys()[0]]
		seen[region.keys()[0]] = true
		var head := 0
		while head < frontier.size():
			var cur: Vector3i = frontier[head]
			head += 1
			for d in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1), Vector3i(0, 1, 0), Vector3i(0, -1, 0)]:
				var n: Vector3i = cur + d
				if region.has(n) and not seen.has(n):
					seen[n] = true
					frontier.append(n)
		metrics.record("s4/bfs_ms_footprint_%d" % target_size, "%.2f" % ((Time.get_ticks_usec() - t0) / 1000.0))
		metrics.record("s4/bfs_visited_%d" % target_size, str(seen.size()))
	await get_tree().process_frame
