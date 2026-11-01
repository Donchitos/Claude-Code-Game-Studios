class_name MutatorManager
extends RefCounted
## Deterministic Mutator generator & compatibility engine for Sector 9 missions.
## Manages 10 environmental mutators, conflict matrices, and seed-reproducible combinations.

signal mutator_applied(mutator_name: String)

enum Mutator {
	DARKNESS,   # Limited vision cone, flashlight active
	SLIPPERY,   # Reduced friction
	ECHO,       # Doubled acoustic noise propagation
	SHRINKING,  # Safe zone boundaries constrict
	CONVEYOR,   # Dynamic floor momentum
	FOG,        # Dense volumetric mist
	SLOW_MO,    # Bullet tracers slow down
	ONE_WAY,    # Doors lock irreversibly behind player
	MIRROR,     # Laser beams reflect off solid walls
	SILENCE,    # HUD radar tags disabled
}

# Conflicts: Incompatible pairs that produce unplayable softlocks
const INCOMPATIBLE_PAIRS: Array[Array] = [
	[Mutator.DARKNESS, Mutator.FOG],        # Total zero-visibility softlock
	[Mutator.SILENCE, Mutator.DARKNESS],    # Blind + mute softlock
	[Mutator.SHRINKING, Mutator.SLOW_MO],   # Unreachable boundary softlock
]


## Generate a reproducible pair/trio of compatible mutators for a given seed.
static func generate_mutators_for_seed(seed_value: int, count: int = 2) -> Array[Mutator]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var candidates: Array[Mutator] = []
	for m in range(10):
		candidates.append(m as Mutator)

	var selected: Array[Mutator] = []
	var attempts := 0

	while selected.size() < count and attempts < 40:
		attempts += 1
		var pick: Mutator = candidates[rng.randi_range(0, candidates.size() - 1)]
		if selected.has(pick):
			continue

		var compatible := true
		for existing in selected:
			if are_incompatible(pick, existing):
				compatible = false
				break

		if compatible:
			selected.append(pick)

	return selected


static func are_incompatible(a: Mutator, b: Mutator) -> bool:
	for pair in INCOMPATIBLE_PAIRS:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


static func get_mutator_name(mutator: Mutator) -> String:
	match mutator:
		Mutator.DARKNESS: return "Karanlık"
		Mutator.SLIPPERY: return "Kaygan Zemin"
		Mutator.ECHO: return "Akustik Yankı"
		Mutator.SHRINKING: return "Daralan Saha"
		Mutator.CONVEYOR: return "Konveyör Akımı"
		Mutator.FOG: return "Yoğun Sis"
		Mutator.SLOW_MO: return "Zaman Esnemesi"
		Mutator.ONE_WAY: return "Tek Yönlü Geçiş"
		Mutator.MIRROR: return "Aynalı Lazer"
		Mutator.SILENCE: return "Telsiz Sessizliği"
	return "Mutatör"
