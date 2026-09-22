class_name MovementIntentCarrier
extends RefCounted

## Typed, single-writer movement snapshot consumed by PlayerController.
var direction: Vector2 = Vector2.ZERO
var is_active: bool = false
var press_generation: int = -1
var written_tick: int = 0

## Writes one complete movement snapshot.
func write(next_direction: Vector2, generation: int, tick: int) -> void:
	direction = next_direction
	is_active = next_direction != Vector2.ZERO
	press_generation = generation
	written_tick = tick

## Clears the carrier at the exact consuming tick.
func clear(tick: int) -> void:
	direction = Vector2.ZERO
	is_active = false
	press_generation = -1
	written_tick = tick

