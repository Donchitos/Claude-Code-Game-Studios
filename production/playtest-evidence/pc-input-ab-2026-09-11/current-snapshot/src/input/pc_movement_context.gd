class_name PcMovementContext
extends RefCounted

## Per-battle PC adapter lease, separate from the future seven-phase registry ABI.
var battle_generation: int
var tick := 0
var lease_id := 0
var open := false
var consumed := false
var retired := false

## Opens a monotonically increasing lease for one input/player pair.
func begin(next_tick: int) -> bool:
	if retired or open or next_tick <= tick or lease_id == 9223372036854775807:
		return false
	tick = next_tick
	lease_id += 1
	open = true
	consumed = false
	return true

## Closes the lease only after a successful consumer commit.
func finish() -> bool:
	if not open or not consumed:
		return false
	open = false
	return true

## Retires all future writers and consumers before node cleanup.
func retire() -> void:
	open = false
	retired = true
