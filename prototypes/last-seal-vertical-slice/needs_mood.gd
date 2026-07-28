# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Needs & Mood per design/gdd/needs-mood-system.md, slice-reduced to the sleep need:
# F1 decay / F2 recovery (source-scored, re-rated live each tick) / F3 mood EMA+snap /
# F4 spawn init. Discrete start_recovery/stop_recovery reports per Core Rule 10 —
# Villager AI reports, this system only ever scores. Tick-driven only.
extends Node

signal need_urgent(villager_id: int, need: String)
signal need_satisfied(villager_id: int, need: String)
signal mood_band_changed(villager_id: int, band: int)   # 0 Happy, 1 Content, 2 Low

enum MoodBand { HAPPY, CONTENT, LOW }

# --- Slice tuning (documented deviations from the GDD's Full Vision defaults) ---
# GDD default decay_per_tick[sleep] = 0.07 (~8.9 min to urgent at 1x) — far too slow
# for a <=5-minute unguided playtest loop. Slice tuning: urgent (100->25) in ~120s
# at 1x: decay_per_tick = 75 / (120s * 4 ticks/s) = 0.15625.
const DECAY_PER_TICK_SLEEP := 0.15625
const BASE_RECOVERY_PER_TICK := 1.2
const MULT_BED_SHELTERED := 1.0
const MULT_BED_UNSHELTERED := 0.7
const MULT_GROUND := 0.4               # shared by all ground_* source variants (GDD Rule 4)
const URGENCY_THRESHOLD := 25.0
const SATISFIED_THRESHOLD := 90.0      # GDD default is 95; slice spec pins 90
const MOOD_SMOOTHING_TICKS := 40.0
const MOOD_SNAP_EPSILON := 0.05
const BAND_HAPPY_MIN := 70.0
const BAND_CONTENT_MIN := 40.0


# Per-need state (MVP schema fills only "sleep" — food/company are Vertical
# Slice/Alpha additions per the GDD's fixed 3-need schema; this record only
# carries what MVP needs).
class NeedState:
	var value: float = 100.0
	var recovering: bool = false
	var source: String = ""            # recovery-source enum reported by Villager AI


class VillagerRecord:
	var id: int = -1
	var sleep: NeedState = NeedState.new()
	var mood: float = 100.0
	var mood_band: int = MoodBand.HAPPY


var _build_validation: Node = null
var _villagers: Dictionary = {}        # int -> VillagerRecord

# CONTRACT ADDITIONS (see villager_ai.gd summary) — optional, GameWorld-wired
# callables that let the why-string (Core Rule 11) reach beyond this system's
# own state without this system reaching INTO Villager AI/Build Validation.
var _context_provider: Callable        # villager_id -> Dictionary{has_bed, bed_reachable}
var _distress_provider: Callable       # villager_id -> String ("trapped" | "" | ...)


# world is intentionally untyped here, mirroring villager_ai.gd's is_standable/
# is_step_legal — the contract signature (CONTRACTS.md) leaves it untyped so a
# unit test can inject a non-Node mock Build Validation double.
func setup(build_validation) -> void:
	_build_validation = build_validation
	# Core Rule 4 config validation: the ladder ordering invariant, enforced
	# HERE (this system owns the source->rate table) — fails loudly at boot.
	assert(MULT_GROUND < MULT_BED_UNSHELTERED and MULT_BED_UNSHELTERED < 1.0,
		"needs_mood: recovery ladder invariant violated — ground_penalty < unsheltered_bed_multiplier < 1.0 required")
	TimeTickSystem.tick.connect(_on_tick)


func set_context_provider(cb: Callable) -> void:
	_context_provider = cb


func set_distress_provider(cb: Callable) -> void:
	_distress_provider = cb


func register_villager(villager_id: int) -> void:
	var rec := VillagerRecord.new()
	rec.id = villager_id
	rec.sleep = NeedState.new()
	rec.sleep.value = 100.0
	rec.mood = 100.0                   # F4: mood == mean_active at spawn, never 0
	rec.mood_band = _band_for(rec.mood)
	_villagers[villager_id] = rec


func start_recovery(villager_id: int, need: String, source: String) -> void:
	if need != "sleep":
		return
	var rec: VillagerRecord = _villagers.get(villager_id)
	if rec == null:
		push_warning("needs_mood: start_recovery for unknown villager_id %d" % villager_id)
		return
	# Idempotent re-rate: calling this again mid-recovery with a new source
	# (shelter upgrade/downgrade) just changes what F2 reads next tick —
	# no restart, no signal (Edge Case 11).
	rec.sleep.recovering = true
	rec.sleep.source = source


func stop_recovery(villager_id: int, need: String, _reason: String) -> void:
	if need != "sleep":
		return
	var rec: VillagerRecord = _villagers.get(villager_id)
	if rec == null:
		return
	rec.sleep.recovering = false
	rec.sleep.source = ""
	# State re-derives from the current value alone (Edge Case 1) — no new
	# urgent event fires here; is_urgent() below is always state-based.


func is_urgent(villager_id: int, need: String) -> bool:
	if need != "sleep":
		return false
	var rec: VillagerRecord = _villagers.get(villager_id)
	return rec != null and rec.sleep.value <= URGENCY_THRESHOLD


func get_display(villager_id: int) -> Dictionary:
	var rec: VillagerRecord = _villagers.get(villager_id)
	if rec == null:
		push_warning("needs_mood: get_display for unknown villager_id %d" % villager_id)
		return {"sleep": 0.0, "band": MoodBand.LOW, "band_label": "Low", "why": ""}
	return {
		"sleep": rec.sleep.value,
		"band": rec.mood_band,
		"band_label": _band_label(rec.mood_band),
		"why": _why_string(rec),
	}


func _band_label(band: int) -> String:
	match band:
		MoodBand.HAPPY:
			return "Happy"
		MoodBand.CONTENT:
			return "Content"
		_:
			return "Low"


func _multiplier_for_source(source: String) -> float:
	if source == "bed_sheltered":
		return MULT_BED_SHELTERED
	elif source == "bed_unsheltered":
		return MULT_BED_UNSHELTERED
	return MULT_GROUND


func _band_for(mood: float) -> int:
	if mood >= BAND_HAPPY_MIN:
		return MoodBand.HAPPY
	elif mood >= BAND_CONTENT_MIN:
		return MoodBand.CONTENT
	return MoodBand.LOW


# Why-string precedence (task spec, resolving GDD Core Rule 11's UI-slot
# precedence for this single-need slice): distress (trapped) > recovering-on-
# ground > urgent-by-context (no bed / bed unreachable) > generic > empty.
func _why_string(rec: VillagerRecord) -> String:
	if _distress_provider.is_valid():
		var distress: String = _distress_provider.call(rec.id)
		if distress == "trapped":
			return "tired — trapped!"
	if rec.sleep.recovering and rec.sleep.source.begins_with("ground"):
		return "sleeping rough — no shelter"
	if rec.sleep.value <= URGENCY_THRESHOLD:
		if _context_provider.is_valid():
			var ctx: Dictionary = _context_provider.call(rec.id)
			var has_bed: bool = ctx.get("has_bed", false)
			var bed_reachable: bool = ctx.get("bed_reachable", true)
			if has_bed and not bed_reachable:
				return "tired — bed unreachable"
		return "tired — no bed"
	if rec.mood_band != MoodBand.HAPPY:
		return "still settling in"
	return ""


func _on_tick() -> void:
	for rec: VillagerRecord in _villagers.values():
		_tick_need(rec)
		_tick_mood(rec)


func _tick_need(rec: VillagerRecord) -> void:
	var need := rec.sleep
	var before := need.value
	if need.recovering:
		# Re-read the CURRENT source every tick (Edge Case 11 upgrade/downgrade).
		var mult := _multiplier_for_source(need.source)
		need.value = minf(100.0, need.value + BASE_RECOVERY_PER_TICK * mult)
		if before < SATISFIED_THRESHOLD and need.value >= SATISFIED_THRESHOLD:
			# Signal.emit() is synchronous: Villager AI's connected handler
			# calls stop_recovery() before this function returns.
			need_satisfied.emit(rec.id, "sleep")
	else:
		need.value = maxf(0.0, need.value - DECAY_PER_TICK_SLEEP)
		if before > URGENCY_THRESHOLD and need.value <= URGENCY_THRESHOLD:
			need_urgent.emit(rec.id, "sleep")


func _tick_mood(rec: VillagerRecord) -> void:
	var mean_active := rec.sleep.value   # MVP: sleep is the only active need
	var diff := mean_active - rec.mood
	if absf(diff) < MOOD_SNAP_EPSILON:
		rec.mood = mean_active
	else:
		rec.mood += diff / MOOD_SMOOTHING_TICKS
	var band := _band_for(rec.mood)
	if band != rec.mood_band:
		rec.mood_band = band
		mood_band_changed.emit(rec.id, band)
