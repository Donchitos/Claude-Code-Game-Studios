## Unit test — [VillagerBodyView] / [VillagerBodyPresenter] / [VillagerHitProxy]
## (Presentation Experience story presentation-003: "Villager body view, hit
## proxy & slice hook" — the substrate `villager-info-ui-002`/`005`/`006` and
## `building-ui-016`'s "characters" clause are blocked on).
##
## Covers, per the story's own AC list (VB-2, transcribed verbatim into the
## story file):
## - AC-ACCESSOR: [method VillagerAi.get_visual_position] mirrors
##   `_visual_position` exactly; [VillagerAi] stays a [Node].
## - AC-MIRROR / AC-NIL-SAFE: the view stores no position, performs no
##   interpolation, mirrors a mock `ai_source` exactly, and is inert with a
##   `null` one.
## - `physics_interpolation_mode` set explicitly (manifest line 71).
## - AC-PROXY / AC-RAY-HIT / AC-RAY-TRAP: [VillagerHitProxy] collision
##   configuration and the two-sided live physics-query regression guard for
##   manifest line 219's documented `collide_with_areas` default trap.
## - AC-HEIGHT: the placeholder figure's mesh AABB spans exactly 2 cells.
## - AC-SLICE: `set_slice_level` hides the view AND zeroes the hit proxy's
##   `collision_layer` (TRAP 1), keyed off the DISCRETE cell (never the
##   interpolated position).
## - AC-NO-SELECTION: zero Selection API references anywhere in the new
##   presentation-tier files (TRAP 2).
## - AC-ANCHOR / AC-HIGHLIGHT: the `IconAnchor` seam and the highlight-mode
##   state getter.
## - AC-PRESENTER: [VillagerBodyPresenter] create/free lifecycle against a
##   mocked roster provider, no Autoload registered.
## - AC-PURE-MIRROR: zero mutating calls from `src/presentation/` into
##   [VillagerAi].
## - The Parent-ruling call-site allowlist guard (appended to this story's
##   blocking AC list 2026-07-26): `_visual_position` is read only from
##   within `src/villager_ai/` — a call-site allowlist, not a filename
##   check, distinguishing the raw private field from the public
##   `get_visual_position()` accessor by the character immediately
##   preceding each match.
class_name VillagerBodyViewTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (inner helper classes — kept ABOVE every test function)
# ---------------------------------------------------------------------------

## Minimal duck-typed AI-source double (class doc comment on
## [VillagerBodyView]: "exactly four members... get_visual_position()/
## get_current_cell()/get_state()/get_last_micro_behavior()") — mirrors this
## codebase's established small-mock-object precedent (no GdUnit mocking
## framework used anywhere in this suite). `last_micro_behavior` defaults to
## `null`, mirroring [member VillagerAi._last_micro_behavior]'s own "null
## until a real value exists" convention (Story villager-ai-019).
class _MockAiSource:
	var visual_position: Vector3 = Vector3.ZERO
	var cell: Vector3i = Vector3i.ZERO
	var state: int = 0
	var last_micro_behavior: Variant = null

	func get_visual_position() -> Vector3:
		return visual_position

	func get_current_cell() -> Vector3i:
		return cell

	func get_state() -> int:
		return state

	func get_last_micro_behavior() -> Variant:
		return last_micro_behavior


## Minimal duck-typed roster-provider double ([VillagerBodyPresenter]'s own
## class doc comment: mirrors [VillagerRosterSpawner]'s "roster is plural"
## shape).
class _MockRosterProvider:
	var villagers: Array[VillagerAi] = []

	func get_villagers() -> Array[VillagerAi]:
		return villagers


# ---------------------------------------------------------------------------
# AC-ACCESSOR — VillagerAi.get_visual_position()
# ---------------------------------------------------------------------------

func test_get_visual_position_mirrors_visual_position_after_process_and_stays_a_node() -> void:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()

	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.current_cell = Vector3i(0, 0, 0)
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)
	villager._intra_tick_progress = 0.5

	villager._process(0.016)

	var expected: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(0, 0, 0)).lerp(
		VoxelWorldGrid.cell_to_world(Vector3i(1, 0, 0)), 0.5
	)
	assert_vector(villager.get_visual_position()).is_equal(expected)
	assert_vector(villager.get_visual_position()).is_equal(villager._visual_position)
	# VillagerAi is statically declared `extends Node` (villager_ai.gd:348) --
	# a variable of that static type structurally CANNOT also be a Node3D, so
	# the compiler itself is the strongest possible proof of "stays a Node,
	# never a Node3D"; asserting `is Node` here is the runtime-observable half
	# of that same fact.
	assert_bool(villager is Node).is_true()


# ---------------------------------------------------------------------------
# AC-MIRROR / AC-NIL-SAFE
# ---------------------------------------------------------------------------

func test_villager_body_view_headless_instantiable_with_mock_ai_source() -> void:
	var mock_ai := _MockAiSource.new()
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai

	assert_object(view).is_not_null()
	assert_bool(view is Node3D).is_true()


func test_process_with_null_ai_source_is_inert_no_crash() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	add_child(view)
	var position_before: Vector3 = view.global_position

	view._process(0.016)
	view._process(0.016)

	assert_vector(view.global_position).is_equal(position_before)


func test_set_slice_level_with_null_ai_source_stays_visible_no_crash() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	add_child(view)

	view.set_slice_level(0)

	assert_bool(view.visible).is_true()


func test_process_mirrors_ai_source_visual_position_exactly() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.visual_position = Vector3(3.25, 7.5, -1.75)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_vector(view.global_position).is_equal(mock_ai.visual_position)


func test_villager_body_view_source_contains_zero_interpolation_calls() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/presentation/villager_body_view.gd")
	assert_bool(source.contains("lerp" + "(")).is_false()


# ---------------------------------------------------------------------------
# physics_interpolation_mode (manifest line 71 / ADR-0009 mitigation)
# ---------------------------------------------------------------------------

func test_view_sets_physics_interpolation_mode_off_explicitly() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())

	assert_int(view.physics_interpolation_mode).is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)


# ---------------------------------------------------------------------------
# AC-PROXY / AC-RAY-HIT / AC-RAY-TRAP
# ---------------------------------------------------------------------------

func test_hit_proxy_has_expected_collision_configuration() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.villager_id = 42
	add_child(view)

	var proxy: VillagerHitProxy = view.get_hit_proxy()

	assert_object(proxy).is_not_null()
	assert_bool(proxy is Area3D).is_true()
	assert_int(proxy.collision_layer).is_equal(1)
	assert_int(proxy.collision_mask).is_equal(0)
	assert_bool(proxy.monitoring).is_false()
	assert_int(proxy.villager_id).is_equal(42)


func test_ray_query_with_areas_true_hits_and_resolves_correct_villager_id() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.villager_id = 7
	add_child(view)
	view.global_position = Vector3(100.0, 50.0, 100.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state: PhysicsDirectSpaceState3D = view.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(100.0, 60.0, 100.0), Vector3(100.0, 40.0, 100.0)
	)
	query.collision_mask = 1
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result: Dictionary = space_state.intersect_ray(query)

	assert_bool(result.is_empty()).is_false()
	var collider: Object = result.get("collider")
	assert_bool(collider is VillagerHitProxy).is_true()
	assert_int((collider as VillagerHitProxy).villager_id).is_equal(7)


func test_ray_query_with_areas_left_at_default_misses_villager_proxy() -> void:
	# Regression guard for manifest line 219's documented trap:
	# PhysicsRayQueryParameters3D defaults to collide_with_areas = false, so
	# an areas-only query that forgets to set it explicitly must silently
	# miss every time — never a crash, never a false hit.
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.villager_id = 8
	add_child(view)
	view.global_position = Vector3(200.0, 50.0, 200.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state: PhysicsDirectSpaceState3D = view.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(200.0, 60.0, 200.0), Vector3(200.0, 40.0, 200.0)
	)
	query.collision_mask = 1
	# collide_with_areas deliberately LEFT AT ITS DEFAULT (false).
	var result: Dictionary = space_state.intersect_ray(query)

	assert_bool(result.is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-HEIGHT
# ---------------------------------------------------------------------------

func test_figure_aabb_spans_exactly_two_cells() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())

	var aabb: AABB = view.get_figure_aabb()

	assert_float(aabb.size.y).is_equal_approx(2.0, 0.0001)


# ---------------------------------------------------------------------------
# AC-SLICE
# ---------------------------------------------------------------------------

func test_set_slice_level_hides_view_and_zeroes_proxy_layer_above_the_cutoff() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.cell = Vector3i(0, 5, 0)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view.set_slice_level(3)

	assert_bool(view.visible).is_false()
	assert_int(view.get_hit_proxy().collision_layer).is_equal(0)


func test_set_slice_level_restoring_the_level_restores_visibility_and_proxy_layer() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.cell = Vector3i(0, 5, 0)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)
	view.set_slice_level(3)

	view.set_slice_level(5)

	assert_bool(view.visible).is_true()
	assert_int(view.get_hit_proxy().collision_layer).is_equal(1)


func test_set_slice_level_at_or_below_cutoff_stays_visible() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.cell = Vector3i(0, 3, 0)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view.set_slice_level(3)

	assert_bool(view.visible).is_true()
	assert_int(view.get_hit_proxy().collision_layer).is_equal(1)


func test_set_slice_level_uses_the_discrete_cell_not_the_interpolated_position() -> void:
	# Edge case (QA plan): a villager mid-lerp across the cutoff boundary
	# must switch cleanly on the DISCRETE cell, never flicker off the
	# interpolated position. The mock's visual_position sits BELOW the
	# cutoff (would read visible if used), while its discrete cell sits
	# ABOVE it — proving set_slice_level consults get_current_cell(), not
	# get_visual_position().
	var mock_ai := _MockAiSource.new()
	mock_ai.cell = Vector3i(0, 6, 0)
	mock_ai.visual_position = Vector3(0.5, 3.2, 0.5)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view.set_slice_level(3)

	assert_bool(view.visible).is_false()
	assert_int(view.get_hit_proxy().collision_layer).is_equal(0)


# ---------------------------------------------------------------------------
# AC-NO-SELECTION (TRAP 2)
# ---------------------------------------------------------------------------

func test_presentation_module_source_contains_zero_selection_references() -> void:
	var source: String = _read_gd_source_no_comments("res://src/presentation")
	assert_bool(source.contains("Selection")).is_false()


# ---------------------------------------------------------------------------
# AC-ANCHOR / AC-HIGHLIGHT
# ---------------------------------------------------------------------------

func test_icon_anchor_tracks_the_body_every_frame() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.visual_position = Vector3(1.0, 2.0, 3.0)
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)
	var anchor: Node3D = view.get_icon_anchor()
	assert_object(anchor).is_not_null()
	assert_str(anchor.name).is_equal("IconAnchor")

	view._process(0.016)
	var expected_first: Vector3 = mock_ai.visual_position + anchor.position
	assert_vector(anchor.global_position).is_equal(expected_first)

	mock_ai.visual_position = Vector3(9.0, -4.0, 2.5)
	view._process(0.016)
	var expected_second: Vector3 = mock_ai.visual_position + anchor.position
	assert_vector(anchor.global_position).is_equal(expected_second)


func test_set_highlight_is_observable_via_state_getter() -> void:
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	assert_int(view.get_highlight()).is_equal(VillagerBodyView.HighlightMode.NONE)

	view.set_highlight(VillagerBodyView.HighlightMode.HOVER)
	assert_int(view.get_highlight()).is_equal(VillagerBodyView.HighlightMode.HOVER)

	view.set_highlight(VillagerBodyView.HighlightMode.SELECTED)
	assert_int(view.get_highlight()).is_equal(VillagerBodyView.HighlightMode.SELECTED)


# ---------------------------------------------------------------------------
# AC-PRESENTER
# ---------------------------------------------------------------------------

func test_presenter_setup_creates_one_view_per_roster_entry_from_mocked_provider() -> void:
	var provider := _MockRosterProvider.new()
	var v1: VillagerAi = auto_free(VillagerAi.new())
	v1.villager_id = 1
	var v2: VillagerAi = auto_free(VillagerAi.new())
	v2.villager_id = 2
	provider.villagers = [v1, v2]

	var presenter: VillagerBodyPresenter = auto_free(VillagerBodyPresenter.new())
	presenter.roster_provider = provider
	add_child(presenter)

	assert_bool(presenter.is_set_up()).is_false()
	presenter.setup()

	assert_bool(presenter.is_set_up()).is_true()
	assert_int(presenter.get_view_count()).is_equal(2)
	assert_object(presenter.get_view_for(1)).is_not_null()
	assert_object(presenter.get_view_for(2)).is_not_null()


func test_presenter_setup_with_null_provider_creates_zero_views_no_crash() -> void:
	var presenter: VillagerBodyPresenter = auto_free(VillagerBodyPresenter.new())
	add_child(presenter)

	presenter.setup()

	assert_int(presenter.get_view_count()).is_equal(0)


func test_presenter_refresh_frees_the_view_for_a_removed_villager() -> void:
	var provider := _MockRosterProvider.new()
	var v1: VillagerAi = auto_free(VillagerAi.new())
	v1.villager_id = 1
	var v2: VillagerAi = auto_free(VillagerAi.new())
	v2.villager_id = 2
	provider.villagers = [v1, v2]

	var presenter: VillagerBodyPresenter = auto_free(VillagerBodyPresenter.new())
	presenter.roster_provider = provider
	add_child(presenter)
	presenter.setup()
	var removed_view: VillagerBodyView = presenter.get_view_for(2)

	provider.villagers = [v1]
	presenter.refresh()
	await get_tree().process_frame

	assert_int(presenter.get_view_count()).is_equal(1)
	assert_object(presenter.get_view_for(2)).is_null()
	assert_bool(is_instance_valid(removed_view)).is_false()


func test_presenter_registers_no_autoload() -> void:
	var project_text: String = FileAccess.get_file_as_string("res://project.godot")
	var autoload_section_start: int = project_text.find("[autoload]")
	assert_int(autoload_section_start).is_greater_equal(0)
	var next_section: int = project_text.find("\n[", autoload_section_start + 1)
	var autoload_section: String = (
		project_text.substr(autoload_section_start, next_section - autoload_section_start)
		if next_section != -1
		else project_text.substr(autoload_section_start)
	)
	assert_bool(autoload_section.contains("VillagerBodyPresenter")).is_false()


# ---------------------------------------------------------------------------
# AC-PURE-MIRROR
# ---------------------------------------------------------------------------

func test_presentation_module_makes_zero_mutating_calls_into_villager_ai() -> void:
	var source: String = _read_gd_source_no_comments("res://src/presentation")
	var allowed_calls: Array[String] = [
		"get_villager_id",
		"get_visual_position",
		"get_current_cell",
		"get_state",
		"get_villagers",
		"get_last_micro_behavior",
	]
	var pattern := RegEx.new()
	var compile_error: int = pattern.compile("(?:ai_source|villager|villagers)\\.(\\w+)\\s*\\(")
	assert_int(compile_error).is_equal(OK)
	for match_result: RegExMatch in pattern.search_all(source):
		var called: String = match_result.get_string(1)
		assert_bool(allowed_calls.has(called)).is_true()


# ---------------------------------------------------------------------------
# Presentation Experience story presentation-001 Sub-B — idle-behaviour pose
# (villager-ai-019's F3/Rule 7c MicroBehavior read as visible idle behavior:
# "reusing the existing FSM, adding no new simulation")
# ---------------------------------------------------------------------------

func test_process_applies_sit_pose_while_wandering_with_sit_micro_behavior() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.WANDERING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.SIT
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_float(view.get_body_mesh().position.y).is_equal_approx(
		VillagerBodyView.BODY_HEIGHT * 0.5 - VillagerBodyView.SIT_VERTICAL_DROP, 0.0001
	)
	assert_float(view.get_head_mesh().position.y).is_equal_approx(
		VillagerBodyView.BODY_HEIGHT + VillagerBodyView.HEAD_HEIGHT * 0.5 - VillagerBodyView.SIT_VERTICAL_DROP,
		0.0001
	)


func test_process_applies_pause_look_head_tilt_while_wandering_with_pause_look() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.WANDERING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.PAUSE_LOOK
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_float(view.get_head_mesh().rotation.x).is_equal_approx(
		VillagerBodyView.PAUSE_LOOK_HEAD_TILT, 0.0001
	)
	assert_float(view.get_body_mesh().position.y).is_equal_approx(VillagerBodyView.BODY_HEIGHT * 0.5, 0.0001)


func test_process_shows_neutral_pose_while_walking_wander_micro_behavior() -> void:
	# WALK is a stationary-Wandering DRAW but its own EXECUTION is
	# State.TRAVELING (Story villager-ai-019: "a villager mid-walk toward a
	# chosen wander/bed-drift target is State.TRAVELING instead") -- already
	# covered by the neutral-pose gate below; this test pins the case where
	# state is still WANDERING (the brief window before travel starts) with
	# a WALK draw, which must also read as the neutral pose, never a
	# sit/pause-look pose.
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.WANDERING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.WALK
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_float(view.get_body_mesh().position.y).is_equal_approx(VillagerBodyView.BODY_HEIGHT * 0.5, 0.0001)
	assert_float(view.get_head_mesh().rotation.x).is_equal_approx(0.0, 0.0001)


func test_process_ignores_stale_sit_micro_behavior_while_traveling_for_work() -> void:
	# A villager mid-TRAVELING for an actual job still carries whatever
	# MicroBehavior it last drew during a PRIOR Wandering episode ([member
	# VillagerAi._last_micro_behavior] is never reset) -- the idle pose must
	# gate on State.WANDERING, not merely on the micro-behavior value, or a
	# working villager would visibly "sit" mid-job.
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.TRAVELING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.SIT
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_float(view.get_body_mesh().position.y).is_equal_approx(VillagerBodyView.BODY_HEIGHT * 0.5, 0.0001)
	assert_float(view.get_head_mesh().rotation.x).is_equal_approx(0.0, 0.0001)


func test_process_shows_neutral_pose_when_no_micro_behavior_drawn_yet() -> void:
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.WANDERING
	# last_micro_behavior left at its default null — no wander pick has run
	# yet (mirrors VillagerAi._last_micro_behavior's own doc comment).
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_float(view.get_body_mesh().position.y).is_equal_approx(VillagerBodyView.BODY_HEIGHT * 0.5, 0.0001)
	assert_float(view.get_head_mesh().rotation.x).is_equal_approx(0.0, 0.0001)


func test_process_restores_neutral_pose_after_sit_pose_ends() -> void:
	# A pose is re-derived from scratch every frame (never accumulated) —
	# sitting one frame and no longer sitting the next must fully restore
	# the neutral pose, not merely stop moving further away from it.
	var mock_ai := _MockAiSource.new()
	mock_ai.state = VillagerAi.State.WANDERING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.SIT
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)
	view._process(0.016)

	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.BED_DRIFT
	mock_ai.state = VillagerAi.State.TRAVELING
	view._process(0.016)

	assert_float(view.get_body_mesh().position.y).is_equal_approx(VillagerBodyView.BODY_HEIGHT * 0.5, 0.0001)


func test_idle_pose_never_touches_the_view_root_position() -> void:
	# The pure-mirror invariant (story presentation-003) applies to the
	# VIEW ROOT's global_position only — idle-pose offsets must land on the
	# child meshes, never perturb the mirrored position itself.
	var mock_ai := _MockAiSource.new()
	mock_ai.visual_position = Vector3(5.0, 1.0, -2.0)
	mock_ai.state = VillagerAi.State.WANDERING
	mock_ai.last_micro_behavior = VillagerWanderSelector.MicroBehavior.SIT
	var view: VillagerBodyView = auto_free(VillagerBodyView.new())
	view.ai_source = mock_ai
	add_child(view)

	view._process(0.016)

	assert_vector(view.global_position).is_equal(mock_ai.visual_position)


func test_idle_pose_source_contains_no_wall_clock_or_randomization() -> void:
	# QA-plan grep guard (mirrors villager-ai-019's own "no wall-clock
	# dependency" discipline): the idle-pose hook is presentation of
	# EXISTING state only — no new decision-making, no live entropy.
	var source: String = FileAccess.get_file_as_string("res://src/presentation/villager_body_view.gd")
	assert_bool(source.contains("OS.get_ticks_msec")).is_false()
	assert_bool(source.contains("Time.get_ticks_msec")).is_false()
	assert_bool(source.contains("randomize(")).is_false()
	assert_bool(source.contains("RandomNumberGenerator")).is_false()


# ---------------------------------------------------------------------------
# Parent ruling — _visual_position call-site allowlist guard
# ---------------------------------------------------------------------------

func test_visual_position_raw_field_read_only_inside_villager_ai_directory() -> void:
	# TD downstream action #13 / this story's Parent ruling (2026-07-26): the
	# ADR-0009 "never read _visual_position outside the movement/rendering
	# path" invariant existed only as prose (ADR validation criteria, control
	# manifest, a doc comment) — nothing in the suite enforced it
	# mechanically. This is the first story that legitimately reads the
	# visual layer from OUTSIDE villager_ai (via the sanctioned
	# get_visual_position() accessor), so this is the guard that must pass
	# for the legitimate read while still failing a hypothetical fourth
	# reader that bypasses the accessor and touches the raw private field
	# directly.
	var violations: Array[String] = _find_visual_position_field_reads_outside_villager_ai("res://src")
	assert_array(violations).is_empty()


# ---------------------------------------------------------------------------
# Test helpers (kept below the tests that use them is standard GdUnit4 style
# in this suite's own established files; helpers with NO test-ordering
# dependency are grouped here at the end)
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive — `src/presentation` is a flat directory,
## mirrors `world_root_valley_attach_test.gd`'s own established
## `_read_all_gd_source` precedent), STRIPPING full-line `#`/`##`
## doc-comment lines first so this class's own compliance-documentation
## prose (which legitimately NAMES "Selection"/method names as forbidden or
## allowed) is never mistaken for a violation.
func _read_gd_source_no_comments(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined


## Recursively scans every `.gd` file under [param dir_path] for a raw read
## of the PRIVATE `_visual_position` field — distinguished from a call to
## the public `get_visual_position()` accessor by checking the character
## immediately BEFORE each match: if that character is a word character
## (letter/digit/underscore — e.g. the "t" in "get_visual_position"), the
## match is part of a LONGER identifier and is not a raw field read.
## Full-line comments are stripped first (prose that legitimately NAMES the
## field is not a call-site). Returns "path:line" violations found OUTSIDE
## `res://src/villager_ai/` — the one directory the invariant allows (the
## sanctioned accessor's own implementation lives there too).
func _find_visual_position_field_reads_outside_villager_ai(dir_path: String) -> Array[String]:
	var violations: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				violations.append_array(_find_visual_position_field_reads_outside_villager_ai(full_path))
			elif entry.ends_with(".gd"):
				var allowed: bool = full_path.begins_with("res://src/villager_ai/")
				if not allowed:
					violations.append_array(_scan_file_for_raw_visual_position_reads(full_path))
		entry = dir.get_next()
	dir.list_dir_end()
	return violations


func _scan_file_for_raw_visual_position_reads(full_path: String) -> Array[String]:
	var found: Array[String] = []
	var text: String = FileAccess.get_file_as_string(full_path)
	var lines: PackedStringArray = text.split("\n")
	for line_index: int in range(lines.size()):
		var line: String = lines[line_index]
		if line.strip_edges().begins_with("#"):
			continue
		var search_from: int = 0
		while true:
			var idx: int = line.find("_visual_position", search_from)
			if idx == -1:
				break
			var preceded_by_word_char: bool = idx > 0 and _is_word_char(line[idx - 1])
			if not preceded_by_word_char:
				found.append("%s:%d" % [full_path, line_index + 1])
			search_from = idx + 1
	return found


func _is_word_char(character: String) -> bool:
	return character == "_" or character.to_lower() != character.to_upper() or (character >= "0" and character <= "9")
