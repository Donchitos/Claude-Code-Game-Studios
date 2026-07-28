# Spike metrics recorder — throwaway prototype code (copied/trimmed from
# prototypes/chunked-mesher/metrics.gd — no frame/draw-call sampling here,
# this spike renders nothing).
class_name SpikeMetrics
extends RefCounted

var rows: Array[String] = []


func record(key: String, value: String) -> void:
	rows.append("%s,%s" % [key, value])
	print("METRIC %s = %s" % [key, value])


static func stats(samples: Array) -> Dictionary:
	if samples.is_empty():
		return {"avg": 0.0, "p95": 0.0, "worst": 0.0, "n": 0}
	var s: Array = samples.duplicate()
	s.sort()
	var avg := 0.0
	for v in s:
		avg += float(v)
	avg /= s.size()
	return {
		"avg": avg,
		"p95": float(s[mini(int(s.size() * 0.95), s.size() - 1)]),
		"worst": float(s[-1]),
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
