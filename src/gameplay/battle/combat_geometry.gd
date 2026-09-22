extends RefCounted

# Clip travel to the current player-relative retention circle. An outside origin
# is already retired; closed-boundary hits on the final segment remain eligible.
static func retention_fraction(origin: Vector2, end: Vector2, center: Vector2, radius_squared: float) -> float:
	if not origin.is_finite() or not end.is_finite() or not center.is_finite() or not is_finite(radius_squared) or radius_squared < 0.0:
		return -1.0
	var offset := origin - center
	var c := offset.length_squared() - radius_squared
	if c > 0.0:
		return -1.0
	if end.distance_squared_to(center) <= radius_squared:
		return 1.0
	var step := end - origin
	var a := step.length_squared()
	if a <= 0.0:
		return 0.0
	var b := offset.dot(step)
	return clampf((-b + sqrt(maxf(0.0, b * b - a * c))) / a, 0.0, 1.0)

# Earliest circle contact along a swept projectile, including initial overlap.
static func sweep_fraction(origin: Vector2, end: Vector2, center: Vector2, radius: float) -> float:
	var offset := origin - center
	var c := offset.length_squared() - radius * radius
	if c <= 0.0:
		return 0.0
	var step := end - origin
	var a := step.length_squared()
	if a <= 0.0:
		return -1.0
	var b := offset.dot(step)
	var discriminant := b * b - a * c
	if discriminant < 0.0:
		return -1.0
	var hit := (-b - sqrt(discriminant)) / a
	return hit if hit >= 0.0 and hit <= 1.0 else -1.0

static func sector_hits(origin: Vector2, axis: Vector2, length: float, half_angle: float, center: Vector2, radius: float) -> bool:
	var offset := center - origin
	var angle := absf(axis.angle_to(offset))
	if angle <= half_angle:
		return offset.length() <= length + radius
	for side in [-1, 1]:
		var edge := origin + axis.rotated(side * half_angle) * length
		var closest := Geometry2D.get_closest_point_to_segment(center, origin, edge)
		if closest.distance_squared_to(center) <= radius * radius:
			return true
	return false
