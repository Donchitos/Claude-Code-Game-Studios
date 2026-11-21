## Pure state machine for one six-week club run: no nodes, no autoload, no UI knowledge.
class_name ClubState extends RefCounted

## Final outcome when the points target is met at the end of the run.
const OUTCOME_VICTORY: String = "victory"
## Final outcome when cash drops below the configured bankruptcy threshold.
const OUTCOME_BANKRUPTCY: String = "bankruptcy"
## Final outcome when the run ends without reaching the points target.
const OUTCOME_DEFEAT: String = "defeat"

## Emitted once per accepted decision, before run_ended on the final week.
signal turn_resolved(state: ClubState, summary: Dictionary)
## Emitted once when the run finishes, after turn_resolved.
signal run_ended(state: ClubState, outcome: String)

## Read-only copy of the economy configuration used by this run.
var config: Dictionary
## Week being played, or the last played week once the run has ended.
var week: int
## Current cash balance.
var cash: int
## Accumulated points.
var points: int
## Current facility level.
var facility_level: int
## Accumulated reinforcements.
var reinforcements: int
## True once the run has reached an outcome.
var ended: bool
## Empty while the run is active; otherwise one of the OUTCOME_* constants.
var outcome: String

## Creates a fresh run from the economy configuration.
func _init(config: Dictionary) -> void:
	self.config = config.duplicate(true)
	week = 1
	cash = int(config["starting_cash"])
	points = 0
	facility_level = int(config["facility"]["start_level"])
	reinforcements = 0
	ended = false
	outcome = ""

## Applies one decision, settles the week and emits turn_resolved (then run_ended if finished).
## Returns an empty Dictionary without signals when the run has already ended.
func apply_decision(decision: String) -> Dictionary:
	if is_finished():
		return {}

	var resolved_week: int = week
	var cash_at_start: int = cash
	var started: bool = false
	var cut_costs: bool = false
	var salary: int = int(config["salary"])

	match decision:
		"escalar_titulares":
			started = true
		"contratar_reforco":
			cash -= int(config["reinforcement"]["cost"])
			reinforcements += 1
		"melhorar_instalacao":
			if facility_level < int(config["facility"]["max_level"]):
				cash -= int(config["facility"]["upgrade_cost"])
				facility_level += 1
		"cortar_gastos":
			cut_costs = true
			salary = int(config["austerity_salary"])

	var force: int = 0
	var points_gained: int = 0

	if not _fail_if_bankrupt():
		force = MatchResult.compute_force(started, reinforcements, facility_level, cut_costs, config)
		points_gained = MatchResult.points_for(force, config)
		points += points_gained

		var gate: Dictionary = config["gate_receipts"]
		cash += int(gate["base"]) + int(gate["per_level"]) * facility_level - salary
		_fail_if_bankrupt()

	if not ended and resolved_week >= int(config["weeks"]):
		if points >= int(config["target_points"]):
			outcome = OUTCOME_VICTORY
		else:
			outcome = OUTCOME_DEFEAT
		ended = true

	if not ended:
		week += 1

	var summary: Dictionary = {
		"week": resolved_week,
		"decision": decision,
		"force": force,
		"points_gained": points_gained,
		"cash_delta": cash - cash_at_start,
		"cash": cash,
		"total_points": points,
		"facility_level": facility_level,
		"reinforcements": reinforcements,
		"outcome": outcome,
	}

	turn_resolved.emit(self, summary)
	if ended:
		run_ended.emit(self, outcome)
	return summary

## Returns true once the run has an outcome.
func is_finished() -> bool:
	return ended

## Returns the current outcome, or an empty String while the run is active.
func get_outcome() -> String:
	return outcome

## Returns a fresh Dictionary copy of all public fields.
func snapshot() -> Dictionary:
	return {
		"config": config.duplicate(true),
		"week": week,
		"cash": cash,
		"points": points,
		"facility_level": facility_level,
		"reinforcements": reinforcements,
		"ended": ended,
		"outcome": outcome,
	}

## Ends the run as a bankruptcy when cash is below the configured threshold.
func _fail_if_bankrupt() -> bool:
	if cash >= int(config["bankruptcy_below"]):
		return false
	outcome = OUTCOME_BANKRUPTCY
	ended = true
	return true
