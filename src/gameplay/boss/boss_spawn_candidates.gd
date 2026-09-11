extends RefCounted

var positions := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
var valid := false
var words_used := 0

# Always consume 2 children * 8 candidates * 3 words, including suppressed clusters.
func sample_summons(rng: RandomNumberGenerator, origin: Vector2, player: Vector2, clearance: float, child_radius: float, half_extent: float, room: int, fog_center: Vector2, fog_radius: float) -> void:
	valid = true
	words_used = 0
	for child in 2:
		var found := false
		for attempt in 8:
			var angle_word := rng.randi()
			var radius_word := rng.randi()
			rng.randi() # Reserved third word remains consumed on every attempt.
			words_used += 3
			var angle := float(angle_word) / 4294967296.0 * TAU
			var radius := 90.0 + float(radius_word) / 4294967296.0 * 60.0
			var candidate := origin + Vector2.RIGHT.rotated(angle) * radius
			var allowed := candidate.is_finite() and absf(candidate.x) + child_radius <= half_extent and absf(candidate.y) + child_radius <= half_extent
			allowed = allowed and candidate.distance_to(player) >= clearance + child_radius
			allowed = allowed and candidate.distance_to(fog_center) + child_radius <= fog_radius
			if child == 1:
				allowed = allowed and candidate.distance_to(positions[0]) >= child_radius * 2.0
			if not found and allowed:
				positions[child] = candidate
				found = true
		valid = valid and found
	valid = valid and room >= 2
