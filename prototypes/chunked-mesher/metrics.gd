# Spike metrics recorder — throwaway prototype code.
class_name SpikeMetrics
extends RefCounted

var rows: Array[String] = []
var _frame_ms: Array[float] = []
var _draw_calls: Array[int] = []
var _phase: String = ""
var sampling := false


func start_phase(phase_name: String) -> void:
	_phase = phase_name
	_frame_ms.clear()
	_draw_calls.clear()
	sampling = true


func sample(delta: float) -> void:
	_frame_ms.append(delta * 1000.0)
	_draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))


func end_phase() -> void:
	sampling = false
	if _frame_ms.is_empty():
		return
	var sorted_ms := _frame_ms.duplicate()
	sorted_ms.sort()
	var avg := 0.0
	for v in sorted_ms:
		avg += v
	avg /= sorted_ms.size()
	var p95: float = sorted_ms[mini(int(sorted_ms.size() * 0.95), sorted_ms.size() - 1)]
	var worst: float = sorted_ms[-1]
	var dc_max := 0
	for d in _draw_calls:
		dc_max = maxi(dc_max, d)
	record("%s/frame_ms_avg" % _phase, "%.3f" % avg)
	record("%s/frame_ms_p95" % _phase, "%.3f" % p95)
	record("%s/frame_ms_worst" % _phase, "%.3f" % worst)
	record("%s/draw_calls_max" % _phase, str(dc_max))
	record("%s/frames" % _phase, str(sorted_ms.size()))


func record(key: String, value: String) -> void:
	rows.append("%s,%s" % [key, value])
	print("METRIC %s = %s" % [key, value])


static func usec_stats(samples: Array[int]) -> Dictionary:
	if samples.is_empty():
		return {"avg": 0.0, "p95": 0, "worst": 0, "n": 0}
	var s := samples.duplicate()
	s.sort()
	var avg := 0.0
	for v in s:
		avg += v
	avg /= s.size()
	return {
		"avg": avg,
		"p95": s[mini(int(s.size() * 0.95), s.size() - 1)],
		"worst": s[-1],
		"n": s.size(),
	}


func save_csv(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write %s" % path)
		return
	f.store_line("key,value")
	for r in rows:
		f.store_line(r)
