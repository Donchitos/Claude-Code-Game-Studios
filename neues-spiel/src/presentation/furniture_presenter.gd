## Owns the create/free lifecycle of one [FurnitureView] per placed
## furniture item (Presentation Experience story presentation-005, F7 -- "a
## built bed becomes visible"). Valley-hosted, injected-tier,
## `setup()`-wired (ADR-0001) -- mirrors [VillagerBodyPresenter]'s own landed
## "presenter owns create/free, per-entity view is its own child" precedent
## one-for-one (Open Decision D11, sprint-12.md: the TD render-mechanism call
## is named but not a blocker -- this codebase's only landed precedent for a
## placed-entity's visual is a per-entity presenter, and the sprint's own
## resolution is "follow precedent, record the choice" when no ruling
## exists). MVP has exactly one multi-cell furniture item (a bed) -- the
## MultiMesh scale argument does not bite yet; revisit only on measured need
## (furniture item count/variety growth), never preemptively.
##
## [member furniture_registry] is the SAME [FurnitureRegistry] instance
## [ConstructionTickLoop]/[FurnitureBedProvider]/[BuildValidation] already
## share (constructed once in [method Valley._wire_build_project_lifecycle]) --
## typed directly (not a duck-typed [Object]), mirroring
## [FurnitureBedProvider]/[ConstructionTickLoop]'s own precedent for this
## concrete, already-`class_name`d `RefCounted` collaborator (unlike
## [BuildValidation.furniture_registry], which predates [FurnitureRegistry]'s
## own `class_name` and stayed duck-typed for that historical reason only).
##
## HARD CONSTRAINT (BV-1, ADR-0016; this story's own load-bearing rule,
## grep-guarded -- see `furniture_presenter_test.gd`'s
## AC-READ-ONLY-BY-CONSTRUCTION): this class calls EXACTLY TWO members on
## [member furniture_registry] -- [method FurnitureRegistry.get_placed_furniture]
## (a read) and [signal FurnitureRegistry.furniture_changed] (a
## subscription). It NEVER calls [method FurnitureRegistry.place]/[method
## FurnitureRegistry.remove] or any other mutating member. BV-1's
## prohibition on furniture reaching [VoxelWorldGrid] is exactly what makes
## [BuildValidation]'s transparency guarantee true by construction, and this
## class must never be the exception -- presentation reads simulation state,
## it never writes it (mirrors [VillagerBodyPresenter]'s own class doc
## comment: "Presentation adds no simulation").
##
## [method setup] connects [signal FurnitureRegistry.furniture_changed] to
## [method refresh] (never a payload read -- [FurnitureRegistry]'s own
## documented "re-query, don't inspect the payload" discipline, the SAME
## contract [BuildValidation]'s own batch handler already follows) and
## performs the initial sync. Unlike [VillagerBodyPresenter] (which needs an
## explicit EXTERNAL [method VillagerBodyPresenter.refresh] call after each
## roster spawn, since no "villager added" signal exists), [FurnitureRegistry]
## already emits on every placement AND removal (Story building-017), so this
## class never needs an external caller to re-sync it -- the signal
## subscription alone is sufficient.
##
## A `null` [member furniture_registry] is inert -- [method setup] connects
## nothing and [method refresh] creates zero views, the SAME nil-safe,
## non-crashing shape every other typed/duck-typed provider seam in this
## codebase already establishes ([member VillagerBodyPresenter.roster_provider],
## [member BuildValidation.furniture_registry]). In production this never
## happens: [method Valley._wire_build_project_lifecycle] constructs
## [FurnitureRegistry] unconditionally and wires it here in the same pass --
## [method Valley._assert_furniture_presenter_boot_invariant] asserts this
## loudly at boot regardless (sprint-12's own rule: "no injected collaborator
## is both optional and consequential").
class_name FurniturePresenter
extends Node3D

## Registry dependency (class doc comment) -- code-assigned in [method
## Valley._wire_build_project_lifecycle], deliberately NOT `@export`ed
## ([FurnitureRegistry] is a `RefCounted`, not a `Resource`/`Node` --
## structurally impossible to Inspector-wire, mirrors every other
## `RefCounted` collaborator's own precedent).
var furniture_registry: FurnitureRegistry = null

var _is_set_up: bool = false

## item_id -> the [FurnitureView] this presenter created for it -- mirrors
## [member VillagerBodyPresenter._views_by_villager_id]'s own
## diff-against-current-contents bookkeeping shape exactly, keyed by
## [FurnitureRegistry]'s own `item_id` [String] instead of an `int` villager
## id.
var _views_by_item_id: Dictionary[String, FurnitureView] = {}


## Explicitly-callable wiring entry point (ADR-0001). Subscribes to [signal
## FurnitureRegistry.furniture_changed] (AC-SELF-RESYNCING) and builds the
## initial view set from [member furniture_registry]'s current contents --
## safe to call with a `null` registry (creates zero views, connects
## nothing).
func setup() -> void:
	_is_set_up = true
	if furniture_registry != null:
		if not furniture_registry.furniture_changed.is_connected(refresh):
			furniture_registry.furniture_changed.connect(refresh)
	refresh()


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Re-syncs this presenter's view set against [member furniture_registry]'s
## CURRENT contents -- creates a view for any placed item not yet
## represented, frees the view for any item no longer present (removal,
## Story building-017). Safe to call before [method setup] too, and safe to
## call with a `null` registry (creates/frees nothing). Mirrors [method
## VillagerBodyPresenter.refresh]'s own two-pass "collect stale ids, then
## free" discipline exactly -- never mutates [member _views_by_item_id]
## while iterating it.
func refresh() -> void:
	var current_ids: Dictionary[String, bool] = {}
	if furniture_registry != null:
		for record: Dictionary in furniture_registry.get_placed_furniture():
			var item_id: String = record["item_id"]
			current_ids[item_id] = true
			if not _views_by_item_id.has(item_id):
				_views_by_item_id[item_id] = _create_view(record)

	var stale_ids: Array[String] = []
	for item_id: String in _views_by_item_id.keys():
		if not current_ids.has(item_id):
			stale_ids.append(item_id)
	for item_id: String in stale_ids:
		var stale_view: FurnitureView = _views_by_item_id[item_id]
		_views_by_item_id.erase(item_id)
		if is_instance_valid(stale_view):
			stale_view.queue_free()


## Builds one [FurnitureView] for [param record] (the SAME per-item
## [Dictionary] shape [method FurnitureRegistry.get_placed_furniture]
## returns -- a read, class doc comment's hard constraint). Resolves the
## item's typed [Mesh] via [method ResourceItemDatabase.get_by_id] (ADR-0001:
## Autoload-tier, called by global singleton name directly, never injected --
## the SAME established precedent [method
## BuildValidationConfig.is_need_functional] already uses for this exact
## lookup). A definition [ResourceItemDatabase] cannot resolve (not yet
## Ready, or an unauthored id) leaves the view meshless rather than
## crashing -- mirrors [method ResourceItemDatabase.get_by_id]'s own "null on
## unknown id" contract and [method FurnitureView.set_visual]'s own nil-safe
## path.
func _create_view(record: Dictionary) -> FurnitureView:
	var item_id: String = record["item_id"]
	var definition_id: StringName = record["definition_id"]
	var cells: Array[Vector3i] = record["cells"]

	var view := FurnitureView.new()
	view.name = "FurnitureView_%s" % item_id
	view.item_id = item_id
	view.definition_id = definition_id
	add_child(view)
	view.position_over_footprint(cells)

	var definition: ItemDefinition = ResourceItemDatabase.get_by_id(definition_id)
	if definition != null:
		view.set_visual(definition.get_visual_asset())
	return view


## Returns the number of views this presenter currently owns -- test /
## observability seam, and the anti-vacuity LEVER's own read: the live-tree
## furniture-view count (sprint-12's own "the live-tree-count technique that
## found the missing camera").
func get_view_count() -> int:
	return _views_by_item_id.size()


## Returns the [FurnitureView] for [param item_id], or `null` if none exists.
func get_view_for(item_id: String) -> Variant:
	return _views_by_item_id.get(item_id)
