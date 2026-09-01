# Example / bootstrap test — proves the GdUnit4 harness + CI run green from day one.
# SELF-CONTAINED: it does not depend on game code (none exists yet). When Combate/Daño
# is implemented (see docs/architecture/adr-0001-combat-stat-modifier-layer.md), replace
# the local `_apply_damage` helper with the real single damage path and keep the cases.
#
# Naming convention: file [system]_[feature]_test.gd; function test_[scenario]_[expected].
class_name CombatDamageTest
extends GdUnitTestSuite


# Combate/Daño Fórmula F1: health_after = clamp(health_before - attack_damage, 0, max_health)
# Overkill is discarded (clamp to 0), health is never negative (combate-dano.md Regla 5 / F1).
static func _apply_damage(health_before: int, attack_damage: int, max_health: int) -> int:
	return clampi(health_before - attack_damage, 0, max_health)


func test_base_attack_returns_expected_damage() -> void:
	# Defender at 40 HP takes 12 -> 28. No mitigation, no multiplier (Regla 5).
	assert_int(_apply_damage(40, 12, 40)).is_equal(28)


func test_overkill_clamps_to_zero_never_negative() -> void:
	# 999 damage on a 5 HP unit -> 0, never -994 (F1 / AC-C17/C18).
	assert_int(_apply_damage(5, 999, 200)).is_equal(0)


func test_exact_lethal_hit_reaches_zero() -> void:
	# Death triggers at the 0-crossing (<= threshold, not <): 40 - 40 -> 0 (is_dead true).
	assert_int(_apply_damage(40, 40, 40)).is_equal(0)


func test_zero_damage_leaves_health_unchanged() -> void:
	assert_int(_apply_damage(120, 0, 200)).is_equal(120)
