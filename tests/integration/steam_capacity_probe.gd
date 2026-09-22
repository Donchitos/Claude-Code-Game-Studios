extends SceneTree
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS = {"max_bytes": 8000000, "max_depth": 48}
const OUT = "res://production/playtest-evidence/steam-domains-2026-09-11/"
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "capacity-fixtures.json"))
	var rows: Array = []
	var failures := 0
	var temp := OS.get_cache_dir().path_join("xiuxian-steam-capacity-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec()))
	if DirAccess.make_dir_absolute(temp) != OK:
		quit(1)
		return
	for fixture: Dictionary in manifest.cases:
		var raw := FileAccess.get_file_as_bytes(OUT + fixture.case + ".payload.json")
		var timings: Array = []
		var observed_delta := 0
		for iteration in 5:
			var baseline := OS.get_static_memory_usage()
			var t := Time.get_ticks_usec()
			var decoded := Codec.decode(raw, LIMITS)
			var decoded_at := Time.get_ticks_usec()
			if decoded.status != "OK":
				failures += 1
				continue
			var inner := Codec.encode(decoded.value, LIMITS)
			var wrapper := Codec.encode({"format": "STEAM_SAVE_V2", "payload_json": inner.text, "payload_sha256": inner.sha256}, LIMITS)
			var encoded_at := Time.get_ticks_usec()
			if wrapper.status != "OK" or wrapper.bytes != int(fixture.slot_bytes):
				failures += 1
			var path := temp.path_join("slot.tmp")
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file == null:
				failures += 1
				continue
			file.store_string(wrapper.text)
			file.flush()
			var write_error := file.get_error()
			file.close()
			var readback := FileAccess.get_file_as_bytes(path)
			var disk := Codec.decode(readback, LIMITS)
			if write_error != OK or disk.status != "OK" or disk.value.payload_sha256 != inner.sha256 or disk.value.payload_json.to_utf8_buffer() != raw:
				failures += 1
			var finished := Time.get_ticks_usec()
			observed_delta = maxi(observed_delta, OS.get_static_memory_usage() - baseline)
			timings.append({"decode_reencode_us": decoded_at - t, "encode_inner_outer_us": encoded_at - decoded_at, "write_flush_readback_validate_us": finished - encoded_at, "total_us": finished - t})
		rows.append({"case": fixture.case, "payload_bytes": int(fixture.payload_bytes), "slot_bytes": int(fixture.slot_bytes), "samples": timings, "observed_live_allocation_delta_bytes": observed_delta})
	DirAccess.remove_absolute(temp.path_join("slot.tmp"))
	DirAccess.remove_absolute(temp)
	var report := {"platform": OS.get_name(), "engine": Engine.get_version_info().string, "samples_per_case": 5, "cases": rows, "failures": failures,
		"allocator_peak_whole_process_bytes": OS.get_static_memory_peak_usage(), "commercial_maximum_proven": false, "durable_protocol_tested": false,
		"note": "cache-directory FileAccess write/flush/readback probe; no OS lock, slot replacement, process kill, power loss or Windows evidence"}
	var file := FileAccess.open(OUT + "envelope-measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("STEAM_CAPACITY_PROBE cases=%d samples=%d failures=%d allocator_peak_process=%d" % [rows.size(), rows.size() * 5, failures, OS.get_static_memory_peak_usage()])
	quit(0 if failures == 0 else 1)
