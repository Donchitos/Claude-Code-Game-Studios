## Unit test — Needs & Mood System story needs-mood-007 (why-string selection,
## templates & UI-slot precedence; GDD Core Rule 11, ADR-0001 primary [this
## module is the sole owner of the why-string, the UI reads it verbatim],
## ADR-0002 secondary [templates are owned data, not scattered literals]).
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double every sibling needs_mood test file already
## establishes):
## 1. **AC32 (templates)**: each reported [enum NeedsMood.RecoverySource] value
##    produces its Core Rule 11 template EXACTLY, including the no-suffix
##    `bed_sheltered` case and the "not currently recovering" base case.
## 2. **AC32 (empty)**: nothing urgent AND mood Happy yields an empty string.
## 3. **Selection**: the strongest drain is the lowest tracked need value,
##    schema-order tie-broken (sleep > food > company) — proven both via the
##    private selection helper (poking a schema-inactive "mocked active food"
##    record directly, this codebase's established test convention) and via
##    the public [method NeedsMood.get_why_string] API end-to-end.
## 4. **Wrong-fix guard**: `ground_trapped` never contains "no bed".
## 5. **Precedence**: this module's published [enum NeedsMood.WhySlotFeeder]
##    rank sits strictly between Villager AI's distress cue and Build
##    Validation's structural string in the single why-slot's order.
## 6. **No staleness**: the string updates the same call the reported source
##    changes, with no tick required.
## 7. **Edge cases**: no active needs at all, and an unknown villager id, both
##    yield an empty string without erroring.
##
## Every input is a fixed literal — deterministic, no random seeds, no
## wall-clock assertions, no scene tree, no Autoload registration.
class_name NeedsMoodWhyStringTemplatesTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to the
## caller-owned [param mock_tick] double — zero scene tree, zero Autoload
## (same precedent as every sibling needs_mood test file's own
## `_make_needs_mood`).
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Arranges an urgent-feeling sleep need (value 20.0, below the default
## `urgency_threshold` 25.0) with mood explicitly set to a Content value
## (50.0, not Happy) — the sanctioned way (Implementation Notes: "a
## Content-mood villager with nothing urgent still yields a string per the
## selection rule") to bypass the empty-case gate ([method
## NeedsMood.has_urgent_need] reads false once a need is Recovering rather
## than Urgent, so the empty gate would otherwise fire on mood alone) and
## reach the real selection + template logic every AC32 case below exercises.
func _make_needs_mood_with_content_mood_sleep_need(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 20.0)
	needs_mood.set_mood_value(1, 50.0)
	return needs_mood


# ---------------------------------------------------------------------------
# AC32 — templates, one per reported source enum
# ---------------------------------------------------------------------------

func test_ac32_ground_no_bed_owned_template_matches_exactly() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.GROUND_NO_BED_OWNED)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired — no bed")


func test_ac32_ground_bed_unreachable_template_names_a_path_not_another_bed() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.GROUND_BED_UNREACHABLE)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired — bed unreachable")


func test_ac32_ground_trapped_template_is_the_wrong_fix_guard() -> void:
	# ground_trapped has no production reporter yet (villager-ai-018's ACs
	# name only the other two ground values) -- implemented and exercised by
	# mock here, per this story's own Implementation Notes.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.GROUND_TRAPPED)

	var why_string: String = needs_mood.get_why_string(1)
	assert_str(why_string).is_equal("tired — trapped!")
	assert_str(why_string).not_contains("no bed")


func test_ac32_bed_unsheltered_template_is_the_build_a_room_signal() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)

	assert_str(needs_mood.get_why_string(1)).is_equal("sleeping rough — no shelter")


func test_ac32_bed_sheltered_has_no_source_suffix() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired")


func test_ac32_not_currently_recovering_has_no_source_suffix() -> void:
	# No start_recovery call at all -- Urgent by value alone, no reported
	# source. Same base-string outcome as bed_sheltered, via the SAME
	# fallback branch (Implementation Notes: "both produce the base string
	# with no source suffix").
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired")


# ---------------------------------------------------------------------------
# AC32 — empty case
# ---------------------------------------------------------------------------

func test_ac32_empty_when_nothing_urgent_and_mood_happy() -> void:
	# Arrange -- sleep fully satisfied (100.0, the fresh-spawn default), no
	# mood explicitly set (defaults to the "unknown, fine" HAPPY band).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 100.0)

	assert_str(needs_mood.get_why_string(1)).is_empty()


func test_content_mood_with_nothing_urgent_still_yields_a_string_never_widened() -> void:
	# Implementation Notes: "do not widen the empty case to 'nothing
	# urgent'" -- a Content-mood villager (mood explicitly 50.0, not Happy)
	# with a satisfied (non-urgent, non-recovering) sleep need still yields
	# its base why-string.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 60.0)
	needs_mood.set_mood_value(1, 50.0)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired")


# ---------------------------------------------------------------------------
# Selection — lowest tracked value wins, schema-order tie-break
# ---------------------------------------------------------------------------

func test_selection_lower_value_food_wins_over_higher_value_sleep() -> void:
	# Arrange -- sleep=30.0, food=20.0 mocked as an "active" tracked need
	# directly via set_need_value (food is schema-inactive per
	# NeedsMood.ACTIVE_NEEDS in MVP, but the selection rule must still honor
	# ANY tracked record per this story's own QA Test Case).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.set_need_value(1, &"food", 20.0)

	# Act -- poking the private selection helper directly (this codebase's
	# established "poke private state" test convention, see
	# recovery_source_rate_table_test.gd's own _source_rate_table pokes) to
	# assert on the SELECTION outcome independent of food's own (not-yet-
	# authored) base why-string word.
	var strongest: NeedsMood.NeedRecord = needs_mood._strongest_drain_record(1)

	# Assert
	assert_int(strongest.need).is_equal(NeedsMood.Need.FOOD)


func test_selection_tie_break_favors_schema_order_sleep_over_food() -> void:
	# Arrange -- both tracked at the SAME value (30.0); schema order (sleep >
	# food > company, NeedsMood.NEED_NAMES' own insertion order) must resolve
	# the tie toward sleep.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.set_need_value(1, &"food", 30.0)

	var strongest: NeedsMood.NeedRecord = needs_mood._strongest_drain_record(1)

	assert_int(strongest.need).is_equal(NeedsMood.Need.SLEEP)


func test_selection_via_public_api_reflects_the_strongest_drain_end_to_end() -> void:
	# Same scenario as the lower-value-food case above, exercised through the
	# PUBLIC get_why_string API end-to-end (not the private helper) -- mood
	# set to Content so the empty-case gate does not mask the selection.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.set_need_value(1, &"food", 20.0)
	needs_mood.set_mood_value(1, 50.0)

	# food (20.0) is selected over sleep (30.0); food has no own base word
	# yet (MVP fills only sleep, NeedsMood.NEED_WHY_BASE), so the correctly
	# selected need surfaces as an empty base string -- proving selection
	# picked food (NOT sleep's "tired") without requiring food's own
	# out-of-scope base word to be authored by this story.
	assert_str(needs_mood.get_why_string(1)).is_equal("")


# ---------------------------------------------------------------------------
# Precedence — UI-slot rank
# ---------------------------------------------------------------------------

func test_precedence_rank_sits_between_villager_ai_and_build_validation() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	var rank: NeedsMood.WhySlotFeeder = needs_mood.get_why_string_precedence_rank()

	assert_int(rank).is_equal(NeedsMood.WhySlotFeeder.NEEDS_MOOD_WHY)
	assert_bool(rank > NeedsMood.WhySlotFeeder.VILLAGER_AI_DISTRESS).is_true()
	assert_bool(rank < NeedsMood.WhySlotFeeder.BUILD_VALIDATION_STRUCTURAL).is_true()


# ---------------------------------------------------------------------------
# No staleness — the string updates same-call, no tick required
# ---------------------------------------------------------------------------

func test_no_staleness_string_updates_immediately_when_source_changes_mid_recovery() -> void:
	# Mirrors Edge Case 11's mid-recovery upgrade (shelter_status_changed):
	# the source enum changes from bed_unsheltered to bed_sheltered with NO
	# tick in between -- the very next get_why_string call must already
	# reflect the new source, never a cached prior string.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood_with_content_mood_sleep_need(mock_tick)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)
	assert_str(needs_mood.get_why_string(1)).is_equal("sleeping rough — no shelter")

	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	assert_str(needs_mood.get_why_string(1)).is_equal("tired")


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_edge_no_tracked_need_at_all_yields_empty_string_not_an_error() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	assert_str(needs_mood.get_why_string(1)).is_empty()


func test_edge_unknown_villager_id_yields_empty_string_without_erroring() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 20.0)
	needs_mood.set_mood_value(1, 50.0)

	assert_str(needs_mood.get_why_string(999)).is_empty()
