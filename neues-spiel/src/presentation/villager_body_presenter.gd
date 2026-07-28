## Owns the create/free lifecycle of one [VillagerBodyView] per roster entry
## (Presentation Experience story presentation-003, VB-1 §1). Valley-hosted
## (a structural child, mirroring every other hosted module's precedent) --
## injected-tier, `setup()`-wired (ADR-0001). The presenter *is*
## Valley-hosted; the views are its own children -- one place that knows how
## many villagers exist, one place that frees them.
##
## [member roster_provider] is a duck-typed, nil-safe [Object] (this
## codebase's established DI precedent: `needs_provider`/`job_queue`/
## `population`) exposing exactly one member this class calls, mirroring
## [VillagerRosterSpawner]'s own "roster is plural" shape:
## `func get_villagers() -> Array[VillagerAi]`. A `null` provider means "no
## villagers" -- correct and non-crashing, exactly like every other landed
## provider seam in this codebase.
##
## [method setup] performs exactly one pass: one [VillagerBodyView] created
## and added as a real child of THIS node per roster entry, each with
## `villager_id`/`ai_source` wired to its corresponding [VillagerAi]. [method
## refresh] re-syncs later -- creating a view for any newly-appeared roster
## entry and freeing the view for any roster entry no longer present
## (villager despawn) -- WITHOUT touching views for villagers still present
## (never a blanket free-and-recreate). No despawn signal exists anywhere in
## this codebase yet, so [method refresh] is the explicit re-sync entry
## point a future despawn/world-generation call site invokes once it knows
## the roster changed -- mirrors [VillagerNavGraph.build]'s own "re-buildable
## on demand, never polled" precedent.
##
## Registers no Autoload -- a plain injected-tier [Node3D], wired via
## `Valley.tscn`'s Inspector / a headless test's direct assignment, exactly
## like every other hosted module.
##
## Guardrail (control manifest, this epic's founding constraint): this class
## makes ZERO mutating calls into [VillagerAi] -- it only ever READS
## `get_villager_id()`/`get_visual_position()`/`get_current_cell()`/
## `get_state()`/`get_last_micro_behavior()` (the last two via the views it
## creates -- story presentation-001 Sub-B's idle-behaviour hook,
## [method VillagerBodyView._apply_idle_pose]). Presentation adds no
## simulation.
class_name VillagerBodyPresenter
extends Node3D

## Roster provider dependency (class doc comment) -- duck-typed, nil-safe,
## deliberately NOT `@export`ed (mirrors [VillagerAi]'s own
## `time_tick_system`/`job_queue` precedent: no Inspector-editable
## representation exists for an arbitrary duck-typed collaborator).
## Production assigns the real Valley roster accessor; a headless test
## assigns a small mock object directly before calling [method setup].
var roster_provider: Object = null

var _is_set_up: bool = false

## villager_id -> the [VillagerBodyView] this presenter created for it --
## the ONLY bookkeeping this class needs to diff a later [method refresh]
## call against the roster provider's current contents.
var _views_by_villager_id: Dictionary[int, VillagerBodyView] = {}


## Explicitly-callable wiring entry point (ADR-0001). Builds the initial
## view set from [member roster_provider]'s current contents -- safe to call
## with a `null` provider (creates zero views, matching every other
## nil-safe provider seam).
func setup() -> void:
	_is_set_up = true
	refresh()


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Re-syncs this presenter's view set against [member roster_provider]'s
## CURRENT roster -- creates a view for any villager not yet represented,
## frees the view for any villager no longer present. Safe to call before
## [method setup] too.
func refresh() -> void:
	var current_ids: Dictionary[int, bool] = {}
	if roster_provider != null:
		@warning_ignore("unsafe_method_access")
		var villagers: Array = roster_provider.get_villagers()
		for villager: Object in villagers:
			@warning_ignore("unsafe_method_access")
			var id: int = villager.get_villager_id()
			current_ids[id] = true
			if not _views_by_villager_id.has(id):
				_views_by_villager_id[id] = _create_view(id, villager)

	# Free any view whose villager is no longer present (despawn) -- collect
	# keys first (two-pass, mirrors UITimerManager's own established
	# "collect keys, then fire+erase" precedent) so this never mutates the
	# Dictionary while iterating it.
	var stale_ids: Array[int] = []
	for id: int in _views_by_villager_id.keys():
		if not current_ids.has(id):
			stale_ids.append(id)
	for id: int in stale_ids:
		var stale_view: VillagerBodyView = _views_by_villager_id[id]
		_views_by_villager_id.erase(id)
		if is_instance_valid(stale_view):
			stale_view.queue_free()


func _create_view(villager_id: int, ai_source: Object) -> VillagerBodyView:
	var view := VillagerBodyView.new()
	view.name = "VillagerBodyView_%d" % villager_id
	view.villager_id = villager_id
	view.ai_source = ai_source
	add_child(view)
	return view


## Returns the number of views this presenter currently owns -- test /
## observability seam.
func get_view_count() -> int:
	return _views_by_villager_id.size()


## Returns the [VillagerBodyView] for [param villager_id], or `null` if none
## exists.
func get_view_for(villager_id: int) -> Variant:
	return _views_by_villager_id.get(villager_id)
