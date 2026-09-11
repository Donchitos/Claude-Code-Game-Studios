extends SceneTree

const Geometry = preload("res://src/gameplay/battle/combat_geometry.gd")
const Batch = preload("res://src/gameplay/battle/player_damage_batch.gd")
const Candidates = preload("res://src/gameplay/boss/boss_spawn_candidates.gd")
const Player = preload("res://src/gameplay/player/player_controller.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	check(is_equal_approx(Geometry.sweep_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(50, 0), 10), 0.4), "fast projectile must hit between endpoints")
	check(Geometry.sweep_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(50, 11), 10) < 0, "near miss")
	# Near the sector corner: old radius/angle expansion admitted this false hit.
	var corner := Vector2.RIGHT.rotated(deg_to_rad(37.0)) * 441.0
	check(not Geometry.sector_hits(Vector2.ZERO, Vector2.RIGHT, 420, deg_to_rad(35), corner, 24), "sector corner must not overdamage")
	check(Geometry.sector_hits(Vector2.ZERO, Vector2.RIGHT, 420, deg_to_rad(35), Vector2(444, 0), 24), "arc tangency counts")
	var player = Player.new()
	player.max_hp = 100.0
	player.hp = 35.0
	player.longchun_charge_count = 1
	player.invulnerability_left = 1.0
	var batch = Batch.new()
	batch.add(12, true)
	batch.add(20)
	batch.add(20)
	check(batch.commit(player), "batch accepted")
	var committed_events: int = player.damage_event_count
	check(not batch.commit(player) and player.damage_event_count == committed_events, "batch cannot commit twice")
	check(player.hp == 0 and player.longchun_charge_count == 1, "lethal aggregate suppresses recovery; contact cooldown does not swallow attacks")
	player.hp = 100.0
	batch.clear()
	batch.add(NAN)
	check(not batch.commit(player) and player.hp == 100.0, "nonfinite batch performs zero writes")
	player.hit_feedback_left = 0.0
	var prior_events: int = player.damage_event_count
	batch.clear()
	batch.add(12, true)
	check(batch.commit(player) and player.damage_event_count == prior_events and player.hit_feedback_left == 0.0, "blocked contact has no feedback")
	batch.clear()
	batch.add(16.8, false, "首领扇毒")
	check(batch.commit(player) and player.damage_event_count == prior_events + 1, "accepted hit publishes one feedback event")
	var committed_hp: float = player.hp
	check(not batch.commit(player) and player.hp == committed_hp, "nonlethal duplicate does not damage again")
	batch.add(1.0)
	check(not batch.commit(player) and player.hp == committed_hp, "cannot append to committed batch")
	check(player.last_damage_sources == "首领扇毒" and is_equal_approx(player.last_damage_amount, 16.8), "feedback preserves actual damage and cause")
	player.run_phase(&"PLAYER_MOVE", Vector2.ZERO, 0.1)
	check(is_equal_approx(player.hit_feedback_left, 1.3), "feedback advances with gameplay clock")
	player.reset_run()
	check(player.hit_feedback_left == 0.0 and player.last_damage_sources.is_empty(), "reset clears feedback")
	batch.clear()
	batch.add(1.0e308, true)
	batch.add(1.0e308)
	check(not batch.commit(player) and player.hp == player.max_hp, "combined overflow has zero writes")
	player.free()
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 1234
	rng_b.seed = 1234
	var available = Candidates.new()
	var full = Candidates.new()
	available.sample_summons(rng_a, Vector2.ZERO, Vector2(500, 500), 100, 19, 10000, 2, Vector2.ZERO, 600)
	full.sample_summons(rng_b, Vector2.ZERO, Vector2(500, 500), 100, 19, 10000, 1, Vector2.ZERO, 600)
	check(available.valid and not full.valid, "two-slot admission")
	check(available.words_used == 48 and full.words_used == 48 and rng_a.state == rng_b.state, "capacity suppression must consume identical RNG words")
	print("COMBAT_PROTOCOL_%s swept_collision=true sector=true aggregate_damage=true fixed_rng=true" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
