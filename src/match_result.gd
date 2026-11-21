## Stateless, deterministic match calculations for the vertical slice.
## Every tuning value comes from the injected economy configuration.
class_name MatchResult

## Computes the week's force from decision flags and accumulated upgrades.
static func compute_force(started: bool, reinforcements: int, facility_level: int, cut_costs: bool, cfg: Dictionary) -> int:
	var match_cfg: Dictionary = cfg["match"]
	var reinforcement_cfg: Dictionary = cfg["reinforcement"]
	var facility_cfg: Dictionary = cfg["facility"]

	var force: int = 0
	if started:
		force = int(match_cfg["starters_strength"])
	force += reinforcements * int(reinforcement_cfg["strength_bonus"])
	force += facility_level - int(facility_cfg["start_level"])
	if cut_costs:
		force -= int(match_cfg["crowd_penalty"])
	return force

## Maps a force value to points using the configured win and draw thresholds.
static func points_for(force: int, cfg: Dictionary) -> int:
	var match_cfg: Dictionary = cfg["match"]
	if force >= int(match_cfg["win_threshold"]):
		return int(match_cfg["points_win"])
	if force >= int(match_cfg["draw_threshold"]):
		return int(match_cfg["points_draw"])
	return int(match_cfg["points_loss"])
