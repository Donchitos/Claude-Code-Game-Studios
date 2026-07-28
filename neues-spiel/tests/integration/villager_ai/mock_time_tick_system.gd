## Minimal Time & Tick System-shaped test double (mirrors
## `MockResourceItemDatabase`'s established precedent under
## `tests/unit/foundation/`).
##
## Implements the members [VillagerAi.setup]/[VillagerAi._process] depend
## on: `signal tick()` and, since story villager-ai-009,
## `func get_game_delta() -> float`. Lives under tests/ only -- the real
## `TimeTickSystem` Autoload (`src/time_tick_system/time_tick_system.gd`) is
## a separate epic's singleton; this double never claims to BE it, only to
## duck-type the shape a tick-driven consumer needs, letting a test fire
## ticks and set a live `game_delta` deterministically without depending on
## real `_physics_process` frames or the shared registered Autoload's
## mutable state.
class_name MockTimeTickSystem
extends Node

## Fires exactly when this double's [method fire_tick] is called -- a
## manually-driven stand-in for the real Autoload's drift-free accumulator
## broadcast.
signal tick()

## Story villager-ai-009: the value [method get_game_delta] returns --
## test-controlled stand-in for the real Autoload's own computed
## `_game_delta`. Defaults to `0.0` (paused-equivalent) so a test that never
## sets this explicitly sees no travel-progress advance through
## [VillagerAi._process].
var game_delta: float = 0.0


## Manually fires [signal tick] once, simulating one drift-free tick-boundary
## crossing (GDD Formulas) without needing any real physics frame.
func fire_tick() -> void:
	tick.emit()


## Duck-typed twin of [TimeTickSystem.get_game_delta] -- returns whatever
## [member game_delta] a test set, never computed from anything else.
func get_game_delta() -> float:
	return game_delta
