## Per-villager hit-test collision shape (Presentation Experience story
## presentation-003, VB-1 §4; ADR-0004 Decision §2). A child of
## [VillagerBodyView] -- moves with the visual body for free, which is the
## behaviourally correct answer (a click lands where the player SEES the
## villager, not where its discrete `current_cell` is mid-transit).
##
## [Area3D], never [StaticBody3D]/[CharacterBody3D] (ADR-0004 Alternative C
## rejected) -- no physical collision response is ever wanted, only
## ray-detectability. `collision_layer = 1` (ADR-0004's "villagers" layer),
## `collision_mask = 0` (villagers detect nothing themselves -- only ARE
## detected), `monitoring = false` (never needs to detect anything entering
## it), `monitorable = true` (must stay detectable by an external
## `intersect_ray()` query). Set in [method _init] so every instance is
## correct from construction, never relying on a caller to configure it.
##
## [member villager_id] is a TYPED public field the picker resolves
## `intersect_ray()`'s `collider` against directly (never `set_meta()` --
## control manifest / ADR-0004: "a typed proxy class... honours the
## project's static-typing standard and is greppable").
##
## TRAP 1 (control manifest, VB-1 §5): Slice View hiding must zero
## [member Area3D.collision_layer] in lockstep with the owning
## [VillagerBodyView]'s `visible` -- Godot does NOT disable an [Area3D]'s
## collision just because an ancestor's `visible` went false. That toggle
## lives on [VillagerBodyView.set_slice_level], not here -- this class only
## carries the shape and its identity.
class_name VillagerHitProxy
extends Area3D

## Which villager this proxy represents -- matches its owning
## [VillagerBodyView]'s own `villager_id`.
var villager_id: int = 0


func _init() -> void:
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
