## Headless smoke gate — three deterministic ClubState runs, no scene and no UI.
## Story type: Logic/Integration (state machine + economy config); output: tests/smoke/run_smoke.gd; gate: BLOCKING.
## Run: godot --headless --path . -s res://tests/smoke/run_smoke.gd
extends SceneTree

const CONFIG_PATH: String = "res://data/economy.json"
const DECISION_START: String = "escalar_titulares"
const DECISION_REINFORCE: String = "contratar_reforco"
const DECISION_UPGRADE: String = "melhorar_instalacao"
const OUTCOME_VICTORY: String = "victory"
const OUTCOME_BANKRUPTCY: String = "bankruptcy"
const OUTCOME_DEFEAT: String = "defeat"

var _failures: Array[String] = []

## SceneTree script entry point: load the config, run the traces, gate on failures.
func _initialize() -> void:
	var cfg: Dictionary = _load_config()
	if cfg.is_empty():
		printerr("SMOKE FAIL: nao foi possivel carregar ", CONFIG_PATH)
		quit(1)
		return

	_scenario_victory(cfg)
	_scenario_bankruptcy(cfg)
	_scenario_defeat(cfg)

	if not _failures.is_empty():
		for message in _failures:
			printerr("SMOKE FAIL: ", message)
		quit(1)
		return

	print("SMOKE OK")
	quit(0)

## Reads the canonical economy file; an empty result aborts the gate.
func _load_config() -> Dictionary:
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var cfg: Dictionary = parsed
	if not cfg.has_all([
		"weeks", "target_points", "starting_cash", "salary", "bankruptcy_below",
		"gate_receipts", "reinforcement", "facility", "match",
	]):
		return {}
	return cfg

## assert() covers debug builds; the explicit guard covers release and headless runs.
func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
	assert(condition, message)

## Weekly net cash flow (gate receipts minus the active salary) at a facility level.
func _gate_delta(cfg: Dictionary, facility_level: int) -> int:
	var gate: Dictionary = cfg["gate_receipts"]
	return int(gate["base"]) + int(gate["per_level"]) * facility_level - int(cfg["salary"])

## Trace 1: reinforcement, upgrade, then starters through the final week -> 13 pts, victory.
func _scenario_victory(cfg: Dictionary) -> void:
	var decisions: Array[String] = []
	decisions.append(DECISION_REINFORCE)
	decisions.append(DECISION_UPGRADE)
	while decisions.size() < int(cfg["weeks"]):
		decisions.append(DECISION_START)

	var state: ClubState = ClubState.new(cfg)
	var summary: Dictionary = {}
	for decision in decisions:
		summary = state.apply_decision(decision)

	var scaled_weeks: int = 0
	for decision in decisions:
		if decision == DECISION_START:
			scaled_weeks += 1

	var start_level: int = int(cfg["facility"]["start_level"])
	var expected_points: int = int(cfg["match"]["points_loss"]) + int(cfg["match"]["points_draw"])
	expected_points += scaled_weeks * int(cfg["match"]["points_win"])
	var expected_cash: int = int(cfg["starting_cash"]) - int(cfg["reinforcement"]["cost"])
	expected_cash -= int(cfg["facility"]["upgrade_cost"])
	expected_cash += _gate_delta(cfg, start_level)
	# A semana da reforma (s2) ja corre com N+1, por isso entra no fluxo de N+1.
	expected_cash += (scaled_weeks + 1) * _gate_delta(cfg, start_level + 1)

	_expect(scaled_weeks > 0, "vitoria: rastro sem semanas de escalacao")
	_expect(state.points == expected_points, "vitoria: esperado %d pts, obtido %d" % [expected_points, state.points])
	_expect(int(summary["total_points"]) == expected_points, "vitoria: total_points do summary divergente")
	_expect(state.cash == expected_cash, "vitoria: esperado caixa %d, obtido %d" % [expected_cash, state.cash])
	_expect(int(summary["cash"]) == expected_cash, "vitoria: cash do summary divergente")
	_expect(state.ended, "vitoria: run nao encerrou")
	_expect(state.week == int(cfg["weeks"]), "vitoria: semana final %d, obtida %d" % [int(cfg["weeks"]), state.week])
	_expect(state.points >= int(cfg["target_points"]), "vitoria: meta nao atingida")
	_expect(state.outcome == OUTCOME_VICTORY, "vitoria: outcome %s" % state.outcome)
	_expect(str(summary["outcome"]) == OUTCOME_VICTORY, "vitoria: outcome do summary divergente")

## Trace 2: reinforcement, upgrade, upgrade -> cash below zero on the third decision.
func _scenario_bankruptcy(cfg: Dictionary) -> void:
	var decisions: Array[String] = []
	decisions.append(DECISION_REINFORCE)
	decisions.append(DECISION_UPGRADE)
	decisions.append(DECISION_UPGRADE)

	var state: ClubState = ClubState.new(cfg)
	var summary: Dictionary = {}
	for decision in decisions:
		summary = state.apply_decision(decision)

	var start_level: int = int(cfg["facility"]["start_level"])
	var expected_cash: int = int(cfg["starting_cash"]) - int(cfg["reinforcement"]["cost"])
	expected_cash -= int(cfg["facility"]["upgrade_cost"])
	expected_cash += _gate_delta(cfg, start_level)
	expected_cash += _gate_delta(cfg, start_level + 1)
	expected_cash -= int(cfg["facility"]["upgrade_cost"])

	_expect(expected_cash < int(cfg["bankruptcy_below"]), "falencia: rastro nao cruza o limiar de falencia")
	_expect(state.cash == expected_cash, "falencia: esperado caixa %d, obtido %d" % [expected_cash, state.cash])
	_expect(int(summary["cash"]) == expected_cash, "falencia: cash do summary divergente")
	_expect(int(summary["week"]) == decisions.size(), "falencia: semana %d, obtida %d" % [decisions.size(), int(summary["week"])])
	_expect(state.week == decisions.size(), "falencia: semana do estado divergente")
	_expect(state.ended, "falencia: run nao encerrou")
	_expect(state.outcome == OUTCOME_BANKRUPTCY, "falencia: outcome %s" % state.outcome)
	_expect(str(summary["outcome"]) == OUTCOME_BANKRUPTCY, "falencia: outcome do summary divergente")
	_expect(int(summary["points_gained"]) == 0, "falencia: pontos na semana da falencia")
	_expect(int(summary["force"]) == 0, "falencia: partida resolvida apos a falencia")

	var extra: Dictionary = state.apply_decision(DECISION_START)
	_expect(extra.is_empty(), "falencia: decisao posterior foi aceita")
	_expect(state.week == decisions.size(), "falencia: semana avancou apos o encerramento")
	_expect(state.cash == expected_cash, "falencia: caixa mudou apos o encerramento")

## Trace 3: starters only for every week -> 0 pts, defeat, untouched cash.
func _scenario_defeat(cfg: Dictionary) -> void:
	var decisions: Array[String] = []
	while decisions.size() < int(cfg["weeks"]):
		decisions.append(DECISION_START)

	var state: ClubState = ClubState.new(cfg)
	var summary: Dictionary = {}
	for decision in decisions:
		summary = state.apply_decision(decision)

	var expected_points: int = int(cfg["weeks"]) * int(cfg["match"]["points_loss"])
	var expected_cash: int = int(cfg["starting_cash"])
	expected_cash += int(cfg["weeks"]) * _gate_delta(cfg, int(cfg["facility"]["start_level"]))

	_expect(int(cfg["match"]["starters_strength"]) < int(cfg["match"]["draw_threshold"]),
		"derrota: premissa de que escalar nao empata nao vale")
	_expect(state.points == expected_points, "derrota: esperado %d pts, obtido %d" % [expected_points, state.points])
	_expect(int(summary["total_points"]) == expected_points, "derrota: total_points do summary divergente")
	_expect(state.cash == expected_cash, "derrota: esperado caixa %d, obtido %d" % [expected_cash, state.cash])
	_expect(state.ended, "derrota: run nao encerrou")
	_expect(state.week == int(cfg["weeks"]), "derrota: semana final divergente")
	_expect(state.points < int(cfg["target_points"]), "derrota: meta atingida")
	_expect(state.outcome == OUTCOME_DEFEAT, "derrota: outcome %s" % state.outcome)
	_expect(str(summary["outcome"]) == OUTCOME_DEFEAT, "derrota: outcome do summary divergente")
