extends SceneTree

const Combat = preload("res://src/gameplay/boss/boss_combat.gd")

func _initialize() -> void:
	var combat = Combat.new()
	combat.initialize(100.0)
	var origin := Vector2.ZERO
	var fans := 0
	var rings := 0
	var summons := 0
	var bites := 0
	for tick in 120:
		combat.advance(origin, Vector2(100, 0))
		assert(not combat.bite_active and not combat.fan_release and not combat.ring_release)
	for tick in 312:
		combat.advance(origin, Vector2(100, 0))
		fans += int(combat.fan_release)
		rings += int(combat.ring_release)
		bites += int(combat.bite_active)
	assert(fans == 1 and rings == 1 and bites == 18, "P1 rotation")
	combat.fsm.apply_hp_receipt(1, 100.0, 50.0)
	for tick in 91:
		combat.advance(origin, Vector2(100, 0))
	fans = 0
	rings = 0
	bites = 0
	for tick in 444:
		combat.advance(origin, Vector2(100, 0))
		fans += int(combat.fan_release)
		rings += int(combat.ring_release)
		summons += int(combat.summon_release)
		bites += int(combat.bite_active)
	assert(fans == 1 and rings == 1 and summons == 1 and bites == 36, "P2 rotation")
	assert(not combat.fan_hits(origin, Vector2(-200, 0), 24), "behind fan is safe")
	print("BOSS_COMBAT_PASS p1_312=true p2_444=true telegraphs=true geometry=true")
	quit()
