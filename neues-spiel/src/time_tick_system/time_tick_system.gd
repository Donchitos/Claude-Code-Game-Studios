## Time & Tick System Autoload (ADR-0001 Autoload tier + ADR-0002 config
## loading). Story tick-001 landed the config-driven tunables and boot
## defaults; story tick-002 added the `game_delta` formula -- computed once
## per physics frame in [method _physics_process] and exposed read-only via
## [method get_game_delta]; story tick-003 added the pause/time-warp
## MUTATION API -- [method pause], [method resume], and [method set_warp] --
## the sanctioned way external callers change [member paused]/[member
## time_warp] from here on (TR-time-tick-system-023/024/039/040/045).
## [member paused] and [member time_warp] remain plain public vars (tick-002's
## formula test already depends on assigning them directly) -- [method pause]/
## [method resume]/[method set_warp] add idempotency guards and
## `time_warp_options` validation on top, they do not replace the fields.
##
## This story (tick-004) adds the drift-free tick accumulator and the single
## global [signal tick] broadcast (TR-time-tick-system-007/028/029/032/033/
## 034). [member _tick_accumulator] banks [member _game_delta] every physics
## frame (in [method _advance_ticks], called from [method _physics_process])
## and fires [signal tick] each time it crosses [method get_tick_interval] --
## via SUBTRACTION only, never a reset to `0.0` -- the drift-free guarantee
## GDD AC9/AC23 require. [method set_warp] already documented (tick-003) that
## it never touches the accumulator (TR-time-tick-system-046); that joint
## guarantee is now assertable and covered by this story's test, since the
## accumulator field finally exists. At the time tick-004 landed, the
## max-ticks-per-frame safety cap (GDD Formulas, `max_ticks_per_frame`) was
## explicitly OUT OF SCOPE -- story tick-005 -- so [method _advance_ticks]'s
## drain loop was intentionally uncapped: a stall producing a large backlog
## fired every due tick in the same frame.
##
## This story (tick-005) lands that cap (GDD Formulas "Max-Ticks-Per-Frame
## Safety Cap", TR-time-tick-system-035/036/037). [method _advance_ticks] now
## computes `raw_ticks = floor(_tick_accumulator / _tick_interval)` and fires
## only `min(raw_ticks, config.max_ticks_per_frame)` ticks; when `raw_ticks`
## exceeds the cap, the excess accumulated time is DISCARDED, not deferred --
## [member _tick_accumulator] resets to `0.0` after the capped ticks fire, so
## a stall never produces a catch-up cascade on a later frame. Below the cap,
## behavior is bit-for-bit unchanged from tick-004: the same per-tick
## subtraction drain, same drift-free residue carry-forward (GDD AC23).
##

## Registered as one of the project's only two genuinely-global Foundation
## Autoloads alongside ResourceItemDatabase (ADR-0001) -- called by its
## global singleton name directly in method bodies everywhere
## (`TimeTickSystem.get_game_delta()` once tick-002 lands), never
## `@export`-injected into any module. `_ready()` runs before the Main Scene
## loads (declared Autoload order, synchronous) and does nothing beyond
## calling [method setup] -- all wiring/validation logic lives there so the
## identical code path runs when a headless test constructs this script
## directly and calls [method setup] without ever entering the SceneTree.
##
## Deliberately carries NO `class_name` (engine constraint discovered during
## tick-001 implementation): Godot 4.7 hard-errors "Class 'TimeTickSystem'
## hides an autoload singleton" if a script both declares `class_name
## TimeTickSystem` AND is registered as the Autoload singleton named
## "TimeTickSystem" -- the Autoload's own global name already provides the
## only reference path this ADR-0001 tier ever uses (nothing holds a typed
## `@export` reference to an Autoload; that is Forbidden). Callers duck-type
## via the registered singleton name, exactly like [GameWorld]'s existing
## `resource_item_database` duck-typed dependency.
extends Node

## Path to this Autoload's own config Resource (ADR-0002 Autoload-tier
## loading: `const CONFIG_PATH` + `load()` inside [method setup] -- no
## injected `@export` wiring layer, unlike Core/Feature/Presentation
## modules).
const CONFIG_PATH: String = "res://data/config/time_tick_config.tres"

## Fires whenever [method pause], [method resume], or [method set_warp]
## actually changes stored state. Idempotent no-ops (TR-time-tick-system-045
## -- e.g. calling [method pause] while already paused) do NOT re-fire this;
## requesting the same state twice must never trigger a duplicate side
## effect for a future listener (audio dampening, a Building UI speed/pause
## indicator -- GDD Visual/Audio Requirements). Carries the full current
## snapshot -- both [member paused] and [member time_warp] -- so one
## listener never needs to separately query the other field after a single
## field's change.
signal time_state_changed(paused: bool, time_warp: int)

## Fires once per drift-free tick-boundary crossing (GDD Formulas "Tick
## Accumulator", TR-time-tick-system-032/033) -- the SOLE global tick
## broadcast in the project (TR-time-tick-system-007): every consumer
## (Villager AI, Needs & Mood, Gathering & Production, Building System)
## connects to this ONE signal, never a per-consumer [Timer]. Carries no
## parameters -- "a game tick happened" is the entire payload, matching the
## GDD Formulas' `fire tick()` pseudocode and ADR-0008's `_on_tick()`
## consumer shape. Never fires while [member paused] (TR-time-tick-system-029)
## because [member _game_delta] is `0.0` that frame, so the accumulator never
## advances far enough to cross [method get_tick_interval] -- no special-case
## branch needed.
##
## Consumer caveat (TR-time-tick-system-036, story tick-005): [method
## _advance_ticks]'s max-ticks-per-frame cap can DISCARD accumulated time
## after a large stall (TR-time-tick-system-035), so "exactly N ticks per
## game-time interval" invariants hold only barring a discard event. Any
## downstream duration math must derive elapsed simulated time from tick
## COUNTS this signal actually delivered, never from wall-clock or
## game-clock arithmetic that assumes no tick was ever lost.
signal tick()

## Tuning-config dependency (ADR-0002). Production leaves this null and
## [method setup] `load()`s it from [constant CONFIG_PATH]; a headless test
## may assign a constructed [TimeTickConfig] directly before calling
## [method setup], which then leaves the pre-assigned instance untouched.
var config: TimeTickConfig

## Player-toggleable pause state (GDD Edge Case "Game boot"). Defaults to
## `false` per TR-time-tick-system-038; re-affirmed explicitly in [method
## setup] rather than relying solely on the field initializer.
var paused: bool = false

## Player-selected time-warp speed, one of [member TimeTickConfig.
## time_warp_options] (GDD Core Rule 2). Defaults to `1` per
## TR-time-tick-system-038; re-affirmed explicitly in [method setup].
var time_warp: int = 1

## Owned runtime state (ADR-0002: never a config field -- this is Time &
## Tick System's own derived value, recomputed every physics frame, not a
## tuning knob). Most recently computed game delta-time (GDD Formulas:
## `game_delta = clamp(raw_delta, 0, max_raw_delta) * time_warp * (paused ?
## 0 : 1)`), exposed read-only to every other system via [method
## get_game_delta] (TR-time-tick-system-022 -- simulation-tier consumers
## query this, never raw engine delta). Starts at `0.0` before the first
## physics frame runs.
var _game_delta: float = 0.0

## Owned runtime state (drift-free tick accumulator, GDD Formulas / story
## tick-004). Banks [member _game_delta] every physics frame in
## [method _physics_process]; drained via SUBTRACTION only, one
## [method get_tick_interval] at a time, in [method _advance_ticks] -- NEVER
## reset to `0.0` (TR-time-tick-system-032). This is what keeps accumulated
## drift under one `tick_interval` even after 10,000 ticks (GDD AC23): unlike
## a modulo/reset scheme, sub-tick residue is preserved and carried forward
## indefinitely rather than discarded. Reset to `0.0` exactly once, in
## [method setup] (fresh boot state) -- never written anywhere else outside
## [method _advance_ticks]. Deliberately untouched by [method set_warp]
## (TR-time-tick-system-046) -- a warp change only ever writes
## [member time_warp], never this field.
var _tick_accumulator: float = 0.0

## Cached `1.0 / config.ticks_per_second` (GDD Formulas: `tick_interval =
## 1 / ticks_per_second`), computed once in [method setup] rather than
## recomputed every physics frame -- config is read-only after boot per
## ADR-0002, so this division's result cannot change at runtime. Exposed
## read-only via [method get_tick_interval] (TR-time-tick-system-033/034).
var _tick_interval: float = 0.0


func _ready() -> void:
	setup()


## Computes this frame's `game_delta` (GDD Formulas) from the engine's own
## raw physics-frame [param delta] via [method compute_game_delta], stores
## the result in [member _game_delta] for [method get_game_delta] to return,
## then advances the drift-free tick accumulator via [method _advance_ticks]
## (TR-time-tick-system-033: the accumulator runs in `_physics_process`,
## fixed step, never `_process`). Runs in `_physics_process` (fixed step, per
## the GDD Formulas section and this story's Engine Notes), never `_process`
## -- so simulation timing stays frame-rate-independent. [param delta] is
## only READ here, never written back to -- every other system's own raw
## `_process`/`_physics_process` delta remains completely unmodified and
## available as normal (TR-time-tick-system-026).
func _physics_process(delta: float) -> void:
	_game_delta = compute_game_delta(delta)
	_advance_ticks(_game_delta)


## Explicitly callable wiring/validation entry point -- the Autoload-tier
## equivalent of ADR-0001's injected-tier `setup()` convention. Loads
## [member config] from [constant CONFIG_PATH] if not already assigned (test
## override), calls `config.validate()` exactly once (ADR-0002 -- single-field
## range issues warn via `push_warning` and clamp in place; this config
## carries no BLOCKING cross-value invariant, so boot always proceeds), then
## sets the GDD-mandated boot defaults for [member paused] and
## [member time_warp].
func setup() -> void:
	if config == null:
		config = load(CONFIG_PATH) as TimeTickConfig
	assert(config != null, "TimeTickSystem.config could not be loaded from %s" % CONFIG_PATH)
	var issues: Array[String] = config.validate()
	for issue: String in issues:
		push_warning(issue)
	paused = false
	time_warp = 1
	_tick_interval = 1.0 / config.ticks_per_second
	_tick_accumulator = 0.0


## Enables Pause (GDD Core Rule 3 / TR-time-tick-system-024): [member paused]
## becomes `true`, so [method compute_game_delta] returns `0.0` on the very
## next physics frame WITHOUT touching [member time_warp] -- the stored warp
## speed survives untouched for [method resume] to pick back up exactly
## (GDD AC3/AC4). Idempotent (TR-time-tick-system-045): if already paused,
## returns immediately -- no field write, no [signal time_state_changed]
## emission -- so requesting pause twice never fires a duplicate side effect
## (e.g. a future audio-dampen listener would otherwise dampen twice).
func pause() -> void:
	if paused:
		return
	paused = true
	time_state_changed.emit(paused, time_warp)


## Disables Pause (GDD Core Rule 3 / TR-time-tick-system-024): [member
## paused] becomes `false`, so [method compute_game_delta] immediately
## resumes multiplying by whatever [member time_warp] currently holds --
## never reset to `1`. Combined with [method set_warp] never touching
## [member paused], this is what makes "pause survives a warp change and a
## warp change survives a pause" hold in both directions
## (TR-time-tick-system-040, GDD AC5/AC20). Idempotent, mirroring
## [method pause]: already-resumed is a no-op, no duplicate emission.
func resume() -> void:
	if not paused:
		return
	paused = false
	time_state_changed.emit(paused, time_warp)


## Sets [member time_warp] to [param new_warp], validated against
## [member TimeTickConfig.time_warp_options] (GDD Core Rule 2 /
## TR-time-tick-system-023): a value outside the configured set is rejected
## outright -- [member time_warp] is left untouched, no emission fires, and
## this method returns `false`. A valid value is accepted even while paused
## (TR-time-tick-system-040): it is stored immediately but has no effect on
## [method compute_game_delta] until [method resume] runs, since the pause
## factor still zeroes the result. Never touches the tick accumulator
## (TR-time-tick-system-046 -- story tick-004's field, not owned here; this
## method only ever writes [member time_warp]). Idempotent: setting the
## already-current value is a no-op, no emission -- matching [method pause]/
## [method resume]'s no-duplicate-side-effect guarantee. Returns `true` for
## any valid, config-listed [param new_warp], whether or not it actually
## changed anything.
func set_warp(new_warp: int) -> bool:
	if not config.time_warp_options.has(new_warp):
		push_warning(
			"TimeTickSystem.set_warp rejected out-of-range value %s (valid: %s)" %
			[new_warp, config.time_warp_options]
		)
		return false
	if new_warp == time_warp:
		return true
	time_warp = new_warp
	time_state_changed.emit(paused, time_warp)
	return true


## Pure formula (GDD Formulas, canonical form -- REVISED 2026-07-10 review:
## the clamp is the authoritative statement, not just an Edge Case note).
## Clamps [param raw_delta] to `[0, config.max_raw_delta]` BEFORE any other
## use (TR-time-tick-system-031), then applies the [member time_warp]
## multiplier and the [member paused] factor (TR-time-tick-system-021).
## Deterministic and side-effect-free -- reads only [member config],
## [member time_warp], and [member paused]; writes nothing -- callable
## directly with fixed inputs in a test, no physics frame or scene tree
## required.
func compute_game_delta(raw_delta: float) -> float:
	var clamped_delta: float = clampf(raw_delta, 0.0, config.max_raw_delta)
	var pause_factor: float = 0.0 if paused else 1.0
	return clamped_delta * float(time_warp) * pause_factor


## Public query surface for [member _game_delta] (TR-time-tick-system-022 --
## every simulation-tier consumer queries THIS, never raw engine delta).
## Read-only: there is no setter, matching ADR-0002's "config/derived state
## is read-only from every consumer's perspective" discipline, extended here
## to this system's own owned runtime state as well.
func get_game_delta() -> float:
	return _game_delta


## Advances [member _tick_accumulator] by [param game_delta] and fires
## [signal tick] up to [member TimeTickConfig.max_ticks_per_frame] times --
## the max-ticks-per-frame safety cap (GDD Formulas "Max-Ticks-Per-Frame
## Safety Cap", TR-time-tick-system-035/037, story tick-005): `raw_ticks =
## floor(tick_accumulator / tick_interval); ticks_to_fire = min(raw_ticks,
## max_ticks_per_frame)`. Below the cap (`raw_ticks <= max_ticks_per_frame`),
## this is bit-for-bit the tick-004 drain: SUBTRACTION only, one
## [method get_tick_interval] at a time, so sub-tick residue always carries
## forward -- drift-free (GDD AC23). At or above the cap, only the capped
## count of ticks fires and [member _tick_accumulator] is reset to `0.0` --
## the excess accumulated time (both the whole extra ticks' worth AND any
## sub-tick residue) is DISCARDED, not deferred (TR-time-tick-system-035): a
## stall never produces a catch-up cascade on a later frame
## (TR-time-tick-system-037). Repeatedly hitting the cap across consecutive
## frames gets no special handling here by design -- it is only a
## performance SIGNAL that the simulation is too slow for the current
## warp/tick rate, meant to be fixed via profiling, not corrected by this
## system. Called every physics frame from [method _physics_process]
## (TR-time-tick-system-033) with that frame's already-computed
## [member _game_delta] -- when [member paused] is `true`, [param game_delta]
## is `0.0`, so `raw_ticks` is `0`, no tick fires, and no discard happens
## either (TR-time-tick-system-029).
func _advance_ticks(game_delta: float) -> void:
	_tick_accumulator += game_delta
	var raw_ticks: int = int(floor(_tick_accumulator / _tick_interval))
	var ticks_to_fire: int = mini(raw_ticks, config.max_ticks_per_frame)
	var fired: int = 0
	while fired < ticks_to_fire:
		tick.emit()
		_tick_accumulator -= _tick_interval
		fired += 1
	if raw_ticks > config.max_ticks_per_frame:
		_tick_accumulator = 0.0


## Public query surface for [member _tick_interval] (GDD Formulas:
## `tick_interval = 1 / ticks_per_second`) -- lets a test (or any future
## consumer) derive the exact tick-boundary value from this system rather
## than re-deriving `1.0 / config.ticks_per_second` itself and risking a
## second, possibly-stale copy of the formula.
func get_tick_interval() -> float:
	return _tick_interval


## Public query surface for [member _tick_accumulator] -- read-only
## observability into the drift-free accumulator's current banked residue
## (GDD Formulas worked example: "0.0034 carries forward"), matching
## [method get_game_delta]'s read-only-derived-state discipline (ADR-0002).
func get_tick_accumulator() -> float:
	return _tick_accumulator
