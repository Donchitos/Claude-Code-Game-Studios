class_name DirectionalFocusManifest
extends RefCounted

const ALGORITHM_VERSION := "DirectionalFocusNeighborManifestV1.algorithm.v1"

## Builds the canonical left/right rows for visible, enabled focusable nodes.
static func build(nodes: Array[Dictionary], profile_id: String, variant_id: String) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for node in nodes:
		if bool(node.get("visible", false)) and bool(node.get("enabled", false)) and bool(node.get("focusable", false)):
			eligible.append(node)

	var manifest: Array[Dictionary] = []
	for node in eligible:
		manifest.append({
			"profile_id": profile_id,
			"variant_id": variant_id,
			"node_id": node["node_id"],
			"left_node_id": _find_neighbor(node, eligible, -1.0),
			"right_node_id": _find_neighbor(node, eligible, 1.0),
			"algorithm_version": ALGORITHM_VERSION,
		})
	return manifest

static func _find_neighbor(source: Dictionary, candidates: Array[Dictionary], direction: float) -> Variant:
	var source_center: Vector2 = source["center"]
	var best: Dictionary = {}
	for candidate in candidates:
		if candidate["node_id"] == source["node_id"]:
			continue
		var candidate_center: Vector2 = candidate["center"]
		var primary := (candidate_center.x - source_center.x) * direction
		if primary <= 0.0:
			continue
		var cross := absf(candidate_center.y - source_center.y)
		if best.is_empty() or _is_better(primary, cross, int(candidate["stable_order"]), best):
			best = {"node_id": candidate["node_id"], "primary": primary, "cross": cross, "stable_order": int(candidate["stable_order"])}
	return best.get("node_id", 0)

static func _is_better(primary: float, cross: float, stable_order: int, best: Dictionary) -> bool:
	if not is_equal_approx(primary, float(best["primary"])):
		return primary < float(best["primary"])
	if not is_equal_approx(cross, float(best["cross"])):
		return cross < float(best["cross"])
	return stable_order < int(best["stable_order"])
