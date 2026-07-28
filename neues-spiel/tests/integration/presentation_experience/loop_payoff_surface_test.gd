## Integration test — Presentation Experience story presentation-002
## (loop-payoff communication scaffolding; ADR-0001 primary).
##
## Proves the event/signal SURFACE ONLY -- emitters and consumers below are
## test stubs/mocks standing in for the real Building System / Villager AI
## emitters and the later Feature-layer mechanic consumer, all out of scope
## for this story:
## 1. AC-1: [LoopPayoffSignalSurface] is headless-mockable -- instantiated
##    with zero scene tree, wired via the explicit [method setup] entry
##    point (ADR-0001), with no Autoload and no file I/O anywhere in its
##    source.
## 2. AC-2: a mock Feature-layer consumer binds to [signal
##    LoopPayoffSignalSurface.payoff_signaled] and receives a stub-emitted
##    payoff without the surface's signature changing; a second consumer
##    binds to the same signal without conflict.
## 3. AC-3: re-emitting the same ([code]payoff_type[/code], [code]subject[/code])
##    key is idempotent for presentation -- no duplicate internal state, no
##    error -- while still refreshing bound consumers in place (mirrors the
##    toast/anchor "keyed re-emit refreshes in place" discipline,
##    design/ux/interaction-patterns.md).
## 4. AC-4: no payoff mechanic and no new simulation exists in this module --
##    structurally verified (no `_process`/`_physics_process`, no
##    mechanic/simulation keywords in actual CODE lines).
##
## NOTE (accumulated pitfall): signal-fire capture uses a captured [Array]
## with `.append()`/`.size()`, never a captured scalar `+= 1` inside a
## lambda -- GDScript closures do not write back captured scalars.
class_name LoopPayoffSurfaceTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC-1 — surface exists, headless-mockable, no Autoload / file I/O
# ---------------------------------------------------------------------------

func test_setup_headless_with_no_scene_tree_completes() -> void:
	# Arrange
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	assert_bool(surface.is_inside_tree()).is_false()
	assert_bool(surface.is_set_up()).is_false()

	# Act
	surface.setup()

	# Assert
	assert_bool(surface.is_set_up()).is_true()


func test_no_autoload_reference_or_file_access_in_source() -> void:
	# Grep-verifiable AC (ADR-0001 "no Autoload, no file I/O in test"):
	# neither Autoload-tier global name may appear in this module's own CODE
	# (comment-stripped -- this codebase's established precedent, see
	# `tests/integration/villager_ai/config_and_scaffold_test.gd`'s
	# `_read_all_gd_source` helper), and it performs no file I/O of its own.
	# Scoped to THIS module's own file, not the whole `src/presentation/`
	# directory (Presentation Experience story presentation-001 added
	# sibling files there with their own, unrelated per-frame presentation
	# code -- e.g. `TorchFlicker`'s `_process`, ADR-0011's sanctioned raw-
	# delta pattern -- a directory-wide scan would wrongly attribute their
	# code to this surface's own compliance checks).
	var source: String = _read_module_source_only()

	var banned_substrings: Array[String] = [
		"ResourceItemDatabase",
		"TimeTickSystem",
		"FileAccess",
		"ConfigFile",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()


# ---------------------------------------------------------------------------
# AC-2 — mock consumer binds without reshaping the surface
# ---------------------------------------------------------------------------

func test_mock_consumer_binds_and_receives_emitted_payoff() -> void:
	# Arrange — a mock Feature-layer consumer is just a bound Callable; no
	# change to the surface's signature was needed to accommodate it.
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	var received: Array = []
	surface.payoff_signaled.connect(func(payoff_type: StringName, subject: StringName) -> void:
		received.append([payoff_type, subject]))

	# Act — a test stub standing in for the real emitter (Building System).
	surface.emit_payoff(&"project_completed", &"project_7")

	# Assert
	assert_int(received.size()).is_equal(1)
	assert_str(String(received[0][0])).is_equal("project_completed")
	assert_str(String(received[0][1])).is_equal("project_7")


func test_second_consumer_binds_to_same_signal_without_conflict() -> void:
	# Arrange — two independently-bound mock consumers.
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	var first_received: Array = []
	var second_received: Array = []
	surface.payoff_signaled.connect(func(payoff_type: StringName, subject: StringName) -> void:
		first_received.append([payoff_type, subject]))
	surface.payoff_signaled.connect(func(payoff_type: StringName, subject: StringName) -> void:
		second_received.append([payoff_type, subject]))

	# Act
	surface.emit_payoff(&"villager_satisfied", &"villager_3")

	# Assert — both consumers received it independently; no conflict.
	assert_int(first_received.size()).is_equal(1)
	assert_int(second_received.size()).is_equal(1)
	assert_str(String(first_received[0][1])).is_equal("villager_3")
	assert_str(String(second_received[0][1])).is_equal("villager_3")


# ---------------------------------------------------------------------------
# AC-3 — idempotent re-emission of the same keyed signal
# ---------------------------------------------------------------------------

func test_reemission_of_same_key_does_not_duplicate_internal_state() -> void:
	# Arrange
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())

	# Act — the same (payoff_type, subject) key fires three times.
	surface.emit_payoff(&"project_completed", &"project_7")
	surface.emit_payoff(&"project_completed", &"project_7")
	surface.emit_payoff(&"project_completed", &"project_7")

	# Assert — exactly one live key, no duplicate-state growth, no error.
	assert_int(surface.get_active_payoff_count()).is_equal(1)
	assert_bool(surface.is_payoff_active(&"project_completed", &"project_7")).is_true()


func test_reemission_of_same_key_still_refreshes_bound_consumers() -> void:
	# Arrange — idempotent internal state must not swallow the refresh: a
	# bound consumer still observes each re-emission (refresh-in-place,
	# never a duplicate-state error and never a silently-dropped signal).
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	var received: Array = []
	surface.payoff_signaled.connect(func(payoff_type: StringName, subject: StringName) -> void:
		received.append([payoff_type, subject]))

	# Act
	surface.emit_payoff(&"project_completed", &"project_7")
	surface.emit_payoff(&"project_completed", &"project_7")

	# Assert
	assert_int(received.size()).is_equal(2)
	assert_int(surface.get_active_payoff_count()).is_equal(1)


func test_different_subjects_same_type_are_tracked_as_distinct_keys() -> void:
	# Arrange + Act — same payoff_type, two different subjects: must not
	# collide into a single key.
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	surface.emit_payoff(&"project_completed", &"project_7")
	surface.emit_payoff(&"project_completed", &"project_8")

	# Assert
	assert_int(surface.get_active_payoff_count()).is_equal(2)
	assert_bool(surface.is_payoff_active(&"project_completed", &"project_7")).is_true()
	assert_bool(surface.is_payoff_active(&"project_completed", &"project_8")).is_true()


func test_clear_payoff_removes_the_live_key() -> void:
	# Arrange
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	surface.emit_payoff(&"project_completed", &"project_7")
	assert_int(surface.get_active_payoff_count()).is_equal(1)

	# Act
	surface.clear_payoff(&"project_completed", &"project_7")

	# Assert
	assert_int(surface.get_active_payoff_count()).is_equal(0)
	assert_bool(surface.is_payoff_active(&"project_completed", &"project_7")).is_false()


# ---------------------------------------------------------------------------
# AC-4 — no payoff mechanic, no new simulation
# ---------------------------------------------------------------------------

func test_no_process_or_physics_process_defined() -> void:
	# Structural check: this is an event-driven surface, never a per-frame
	# simulation hook. Scoped to THIS module's own file -- see
	# test_no_autoload_reference_or_file_access_in_source's doc comment for
	# why a directory-wide scan is no longer correct now that sibling
	# `src/presentation/` files carry their OWN legitimate per-frame
	# presentation code.
	var source: String = _read_module_source_only()

	assert_bool(source.contains("func _process(")).is_false()
	assert_bool(source.contains("func _physics_process(")).is_false()


func test_no_mechanic_or_simulation_keywords_in_source() -> void:
	# Grep-verifiable AC-4: the payoff *mechanic* (needs/mood computation,
	# reward feedback, UI presentation) must not exist in this module's own
	# CODE (comment-stripped -- doc comments are allowed to name the
	# out-of-scope mechanic to document that it is excluded).
	var source: String = _read_module_source_only().to_lower()

	var banned_substrings: Array[String] = [
		"mood",
		"satisfaction",
		"reward_feedback",
		"decay_rate",
		"needsmood",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads `res://src/presentation/loop_payoff_signal_surface.gd` ONLY,
## STRIPPING full-line `#`/`##` doc-comment lines first -- this module's own
## doc comments legitimately name the out-of-scope mechanic to document its
## exclusion, so a naive raw-text scan would flag its own compliance
## documentation as a violation. Stripping comment lines means only actual
## CODE usage can trip the checks above. Deliberately scoped to this ONE
## file rather than the whole `src/presentation/` directory (see
## test_no_autoload_reference_or_file_access_in_source's doc comment) --
## every AC this suite proves is specifically about [LoopPayoffSignalSurface]
## itself, never about whatever else later lands in the same directory.
func _read_module_source_only() -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string("res://src/presentation/loop_payoff_signal_surface.gd")
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive), STRIPPING full-line `#`/`##`
## doc-comment lines first. Mirrors
## `tests/integration/villager_ai/config_and_scaffold_test.gd`'s
## `_read_all_gd_source` helper (this codebase's established precedent).
## Retained for reference/reuse by future tests in this suite; the ACs above
## now use [method _read_module_source_only] instead (see that method's doc
## comment for why).
func _read_all_gd_source(dir_path: String) -> String:
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
