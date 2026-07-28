# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Time & Tick per design/gdd/time-tick-system.md: game_delta = clamp(raw) * warp * (paused?0:1),
# drift-free float64 accumulator in _physics_process, tick cap discards excess.
extends Node

signal tick
signal time_state_changed(paused: bool, warp: int)

const TICKS_PER_SECOND := 4.0
const MAX_TICKS_PER_FRAME := 10
const MAX_RAW_DELTA := 0.1
const WARPS := [1, 2, 3, 10, 20]  # 10x/20x: simulation/testing gears (user 2026-07-21)

var game_delta: float = 0.0
var total_ticks: int = 0   # lifetime simulated ticks (sim clock)

var _paused := false
var _warp := 1
var _accumulator: float = 0.0


func _physics_process(delta: float) -> void:
	var raw: float = clampf(delta, 0.0, MAX_RAW_DELTA)
	game_delta = raw * float(_warp) * (0.0 if _paused else 1.0)
	if _paused:
		return
	_accumulator += game_delta
	var tick_interval := 1.0 / TICKS_PER_SECOND
	var raw_ticks := int(_accumulator / tick_interval)
	var ticks_to_fire := mini(raw_ticks, MAX_TICKS_PER_FRAME)
	# Discard excess beyond the cap (never deferred).
	_accumulator -= float(raw_ticks) * tick_interval
	for i in ticks_to_fire:
		total_ticks += 1
		tick.emit()


func set_paused(p: bool) -> void:
	if _paused == p:
		return  # idempotent, no duplicate side effects
	_paused = p
	time_state_changed.emit(_paused, _warp)


func toggle_paused() -> void:
	set_paused(not _paused)


func set_warp(w: int) -> void:
	if not w in WARPS or w == _warp:
		return
	_warp = w  # never touches the accumulator's banked time
	time_state_changed.emit(_paused, _warp)


func get_paused() -> bool:
	return _paused


func get_warp() -> int:
	return _warp
