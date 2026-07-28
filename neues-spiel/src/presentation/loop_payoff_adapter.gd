## Build Validation & Navigability -> Presentation Experience payoff wiring
## (Story build-validation-009, milestone-02 criterion #7; ADR-0001 primary;
## CD Ruling 2, `production/creative-decisions-m02-preflight-2026-07-26.md`
## -- PROVISIONAL, pending user ratification; GDD `design/gdd/
## build-validation-navigability.md` Rule 10 signal contract).
##
## Closes the ship-green-and-uncalled gap named in this story's own header:
## [LoopPayoffSignalSurface] (`presentation-002`) has existed, shipped, and
## been tested since its own scaffolding story -- but nothing in `src/` ever
## called [method LoopPayoffSignalSurface.emit_payoff] with a REAL payoff.
## This class is that real, first production writer: a thin adapter,
## injected-tier (ADR-0001), that subscribes to [signal
## BuildValidation.room_recognized] and [signal
## BuildValidation.shelter_status_changed] -- the ONLY two signals it
## touches, per this story's own Implementation Notes ("subscribe to
## `room_recognized` and `shelter_status_changed`, translate to
## `emit_payoff(...)`") -- and translates each into exactly one [payoff
## type/subject] pair on the surface, with a [PayoffDetail] sidecar carrying
## the pacing/geometry facts `payoff_type`/`subject` alone cannot express.
## This class adds NO analysis behavior of its own (Guardrail: "the wiring
## adds no analysis work -- it is a pure adapter over emissions story
## 006/007 already produce") -- every field on every [PayoffDetail] it
## constructs is copied verbatim from [BuildValidation]'s own signal
## payload, never recomputed.
##
## **Control Manifest Rules (this story's layer)**: injected-tier binding
## only; [method setup] asserts both [member build_validation] and [member
## payoff_surface] are wired; [method _ready] does nothing beyond optionally
## calling [method setup] (ADR-0001's own "test-path parity" convention --
## see [BuildValidation.setup]'s own identical shape). No `CONNECT_DEFERRED`
## anywhere on this path (Rule 10's "one pass, one frame" reconciliation
## unit) -- both [method Object.connect] calls below use Godot's default
## (synchronous) connection flags.
##
## **Type/subject assignment** (CD Ruling 2's table, reproduced here as the
## load-bearing mapping this class implements):
## [codeblock]
## Same-pass recognition group | &"room_celebrated"        | subject = pass_group_id | celebrate=true,  all member room keys, all cells
## Later-pass quiet recognition | &"room_recognized_quiet" | subject = region key    | celebrate=false, group_id
## Shelter change                | &"shelter_status"        | subject = item id       | sheltered: bool
## [/codeblock]
## `shelter_status` is deliberately ONE payoff type regardless of whether the
## item just became sheltered or unsheltered (CD Ruling 2's own worked
## example: two types would leave a toggling bed with two stale live keys,
## breaking this story's own idempotency AC) -- the boolean lives in the
## detail, never in a second type.
##
## **Same-pass grouping** (CD Ruling 2 minimum 1, "one group, one cue"):
## [signal BuildValidation.room_recognized] fires ONCE PER REGION, not once
## per pass -- every region newly recognized in the SAME pass shares one
## `pass_group_id`, delivered as N separate, synchronous signal emissions
## (see that signal's own doc comment; GDD AC32b). [method
## _on_room_recognized] accumulates every `celebrate == true` region sharing
## the CURRENT `pass_group_id` into the SAME growing [PayoffDetail]
## ([member _celebration_group_id] / [member _celebration_detail]), calling
## [method LoopPayoffSignalSurface.emit_payoff] with the SAME (`&"room_celebrated"`,
## `pass_group_id`) key on every one of those N calls -- so
## [method LoopPayoffSignalSurface.get_active_payoff_count] grows by exactly
## ONE net key (the surface's own idempotent-refresh contract, presentation-002)
## and, by the time the LAST region of the group has arrived, [member
## PayoffDetail.subjects]/[member PayoffDetail.cells] carry every member --
## never a fresh, member-dropping detail per region. A REAL presentation
## consumer (not built by this story -- Out of Scope names `presentation-001`/
## the Art Bible as the owner of the actual highlight/chime treatment) is
## expected to gate its own cue-trigger on the KEY's own first activation
## (mirrors [method LoopPayoffSignalSurface.emit_payoff]'s own documented
## "refresh-in-place, never a fresh occurrence" contract) rather than on every
## raw [signal LoopPayoffSignalSurface.payoff_signaled] firing -- exactly the
## semantic the surface's OWN doc comment already establishes, unmodified by
## this story. The accumulator resets the instant a DIFFERENT `pass_group_id`
## arrives (a later, unrelated pass's group never reads a stale accumulator).
## A `&"room_recognized_quiet"` emission is never grouped (CD Ruling 2's own
## table: its subject is the region's own key, not the pass group) -- [method
## _region_subject_key] derives a small, deterministic, cell-based key via
## the SAME lexicographic `(y, x, z)` tie-break [VillagerJobSelector] already
## established for F2 (reused here purely as a stable ordering, not as a
## pathfinding call) -- a region has no persistent identity of its own (GDD
## Rule 4), so this key is re-derived fresh every emission, never cached.
class_name LoopPayoffAdapter
extends Node

## Injected-tier dependency (ADR-0001): the real analysis module whose
## [signal BuildValidation.room_recognized]/[signal
## BuildValidation.shelter_status_changed] this adapter subscribes to.
## Asserted wired by [method setup].
@export var build_validation: BuildValidation

## Injected-tier dependency (ADR-0001): the shared payoff surface this
## adapter writes every translated payoff onto. Asserted wired by [method
## setup] -- this story's own Control Manifest requirement ("setup() asserts
## the surface reference is wired").
@export var payoff_surface: LoopPayoffSignalSurface

## CD Ruling 2's table -- the three, and ONLY three, `payoff_type` values
## this class ever emits. Never a fourth: this story adds no new payoff
## kind beyond what stories 006/007 already produce.
const PAYOFF_TYPE_ROOM_CELEBRATED: StringName = &"room_celebrated"
const PAYOFF_TYPE_ROOM_RECOGNIZED_QUIET: StringName = &"room_recognized_quiet"
const PAYOFF_TYPE_SHELTER_STATUS: StringName = &"shelter_status"

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## The [param pass_group_id] the current same-pass celebration accumulator
## belongs to (see class doc comment's "Same-pass grouping" paragraph) --
## `&""` (never a real pass_group_id, [BuildValidation] always mints a
## non-empty `"room_group_%d"` string) until the first celebration this
## adapter ever observes.
var _celebration_group_id: StringName = &""

## The growing [PayoffDetail] for [member _celebration_group_id]'s own
## group -- `null` until that group's first region arrives. Re-emitted
## (refreshed) on the surface after every additional member region.
var _celebration_detail: PayoffDetail = null


func _ready() -> void:
	# ADR-0001 test-path parity: does nothing beyond optionally calling
	# setup() -- this class never auto-wires itself. GameWorld's boot-gated
	# injected-tier sweep ([method GameWorld._setup_injected_tier], reached
	# via [Valley.get_injected_tier_modules]) remains the sole production
	# call site (ADR-0005); a headless test calls [method setup] directly.
	pass


## Explicitly-callable wiring entry point (ADR-0001). Asserts both
## dependencies are wired, then connects to [signal
## BuildValidation.room_recognized]/[signal
## BuildValidation.shelter_status_changed] with Godot's default (synchronous)
## connection flags -- never `CONNECT_DEFERRED` (Rule 10's "one pass, one
## frame" reconciliation unit; grep-guarded by
## `loop_payoff_real_signal_test.gd`). Idempotent against a repeated [method
## setup] call (never double-connects), mirroring [BuildValidation.setup]'s
## own established guard shape.
func setup() -> void:
	assert(build_validation != null, "LoopPayoffAdapter.build_validation not wired")
	assert(payoff_surface != null, "LoopPayoffAdapter.payoff_surface not wired")
	if not build_validation.room_recognized.is_connected(_on_room_recognized):
		build_validation.room_recognized.connect(_on_room_recognized)
	if not build_validation.shelter_status_changed.is_connected(_on_shelter_status_changed):
		build_validation.shelter_status_changed.connect(_on_shelter_status_changed)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## [signal BuildValidation.room_recognized] handler -- see class doc
## comment's "Same-pass grouping" paragraph for the full accumulation
## rationale. Every field copied verbatim from [param region_cells]/[param
## celebrate]/[param pass_group_id] -- no re-derivation, no re-query.
func _on_room_recognized(
	region_cells: Array[Vector3i], celebrate: bool, pass_group_id: StringName
) -> void:
	if celebrate:
		_accumulate_and_emit_celebration(region_cells, pass_group_id)
	else:
		var detail := PayoffDetail.new()
		detail.celebrate = false
		detail.group_id = pass_group_id
		var region_key: StringName = _region_subject_key(region_cells)
		detail.subjects = [region_key]
		detail.cells = PackedVector3Array(region_cells)
		payoff_surface.emit_payoff(PAYOFF_TYPE_ROOM_RECOGNIZED_QUIET, region_key, detail)


## Grows (or starts) [member _celebration_detail] for [param pass_group_id]
## with [param region_cells]' own subject key + cells, then emits the
## CURRENT accumulated state onto [member payoff_surface] under the SAME
## (`&"room_celebrated"`, [param pass_group_id]) key every time -- see class
## doc comment for why this is correct (the surface's own idempotent-refresh
## contract; a real cue-triggering consumer gates on the key's first
## activation, not on every refresh).
func _accumulate_and_emit_celebration(region_cells: Array[Vector3i], pass_group_id: StringName) -> void:
	if pass_group_id != _celebration_group_id or _celebration_detail == null:
		_celebration_group_id = pass_group_id
		_celebration_detail = PayoffDetail.new()
		_celebration_detail.celebrate = true
		_celebration_detail.group_id = pass_group_id
	_celebration_detail.subjects.append(_region_subject_key(region_cells))
	for cell: Vector3i in region_cells:
		_celebration_detail.cells.append(cell)
	payoff_surface.emit_payoff(PAYOFF_TYPE_ROOM_CELEBRATED, pass_group_id, _celebration_detail)


## Derives a small, deterministic, per-region subject key from [param
## region_cells]' own lexicographically-smallest member cell ([method
## VillagerJobSelector.lexicographic_cell_less_than], the SAME `(y, x, z)`
## tie-break F2 already established -- reused purely as a stable ordering
## here, no pathfinding call involved). A region carries no persistent
## identity of its own (GDD Rule 4) -- this key is re-derived fresh from
## [param region_cells] every call, never cached or looked up by a stored id.
func _region_subject_key(region_cells: Array[Vector3i]) -> StringName:
	var sorted_cells: Array[Vector3i] = region_cells.duplicate()
	sorted_cells.sort_custom(VillagerJobSelector.lexicographic_cell_less_than)
	var anchor: Vector3i = sorted_cells[0]
	return StringName("room_%d_%d_%d" % [anchor.x, anchor.y, anchor.z])


## [signal BuildValidation.shelter_status_changed] handler -- ONE payoff type
## regardless of [param sheltered]'s value (see class doc comment's own
## "shelter_status is deliberately ONE payoff type" paragraph).
func _on_shelter_status_changed(item_id: String, sheltered: bool) -> void:
	var detail := PayoffDetail.new()
	detail.sheltered = sheltered
	payoff_surface.emit_payoff(PAYOFF_TYPE_SHELTER_STATUS, StringName(item_id), detail)
