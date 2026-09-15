class_name ProductionMovementIntentCarrier
extends RefCounted

## Immutable-by-convention movement snapshot shared by InputSystem and PlayerController.
var direction: Vector2 = Vector2.ZERO
var is_active: bool = false
var press_generation: int = -1
var written_tick: int = -1

## Writes one complete movement snapshot. Example: `carrier.write(Vector2.RIGHT, 1, 42)`.

func write(next_direction: Vector2, generation: int, tick: int) -> bool:
	if not next_direction.is_finite() or generation < 1 or tick < 0:
		return false
	var next_length := next_direction.length()
	if next_direction == Vector2.ZERO or not is_equal_approx(next_length, 1.0):
		return false
	direction = next_direction
	is_active = true
	press_generation = generation
	written_tick = tick
	return true

## Clears movement at the consuming tick. Example: `carrier.clear(43)`.
func clear(tick: int) -> bool:
	if tick < 0:
		return false
	direction = Vector2.ZERO
	is_active = false
	press_generation = -1
	written_tick = tick
	return true
