## Typed tuning-config Resource for Build Validation & Navigability (ADR-0002),
## storing every knob `design/gdd/build-validation-navigability.md`'s Tuning
## Knobs table names for story build-validation-001: [member min_room_cells],
## [member max_room_height], [member unsheltered_bed_multiplier],
## [member room_cue_cooldown_ticks].
##
## Wired into [BuildValidation] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/build_validation_config.tres`.
##
## Two cross-value invariants this [method validate] enforces, at DIFFERENT
## tiers (ADR-0002's two-tier policy -- no third severity model is invented
## anywhere below; see the ADVISORY note):
##
## - **AC27 (BLOCKING)**: [member max_room_height] must stay >= the Building
##   System's maximum `wall_height` ([constant WallToolConfig.WALL_HEIGHT_MAX])
##   -- the GDD's own Tuning Knobs note: "the safe range's lower bound IS the
##   invariant." [constant MAX_ROOM_HEIGHT_MIN] is therefore declared as a
##   direct reference to that constant, not a duplicated literal -- the two
##   values are lockstep BY CONSTRUCTION (mirrors the landed precedent
##   `VillagerAi.VILLAGER_CLEARANCE := VillagerWalkabilityRules.VILLAGER_CLEARANCE`),
##   never by manual sync. A value below it is reported as ONE BLOCKING issue
##   and is deliberately NOT ALSO clamped as a single-field range warning (the
##   GDD Implementation Notes: "the blocking path is reserved for the AC27
##   cross-value invariant alone").
## - The ladder-ordering invariant `ground_penalty < unsheltered_bed_multiplier
##   < 1.0` (GDD Tuning Knobs invariant (b)) is an ADVISORY courtesy-duplicate
##   smoke check ONLY -- its BLOCKING enforcement is Needs & Mood's own AC29,
##   validated against ITS config. This story's Dependencies section names no
##   dependency on a live Needs & Mood config instance, so
##   [constant GROUND_PENALTY_ADVISORY_REFERENCE] stands in for
##   `ground_penalty` using Needs & Mood's own DOCUMENTED DEFAULT
##   (`design/gdd/needs-mood-system.md` Tuning Knobs: 0.4) -- a documented
##   `[assumption]`, not a live cross-module read: unlike
##   [constant MAX_ROOM_HEIGHT_MIN] above, `ground_penalty` is a genuine
##   per-module KNOB, not a locked design constant, so there is no
##   `SomeConfig.SOME_CONST`-style value this module could safely reference
##   without holding a live `NeedsMoodConfig` instance (a dependency this
##   story does not have). If Needs & Mood's default is ever retuned, this
##   constant must be updated in the same commit or this advisory check
##   silently drifts from the real value -- recorded as a known limitation of
##   the "courtesy duplicate" design (GDD Implementation Notes), never a
##   boot-halt regardless of drift. The `ADVISORY: ` text prefix on this
##   check's issue string is NOT a new severity tier -- [method
##   ConfigResource.has_blocking_issue] never sees it; it exists purely so a
##   test/reviewer can distinguish this smoke-check string from an ordinary
##   single-field clamp warning in the same returned array.
class_name BuildValidationConfig
extends ConfigResource

## Safe range for [member min_room_cells] (GDD Tuning Knobs: 1-9, Edge Case 9).
const MIN_ROOM_CELLS_MIN: int = 1
const MIN_ROOM_CELLS_MAX: int = 9

## Safe range for [member max_room_height]. The lower bound is NOT a
## locally-authored literal -- it IS the AC27 lockstep invariant, read
## directly from the Building System's own locked maximum (GDD Tuning Knobs:
## "the safe range's lower bound IS the invariant... currently 8 = 8").
const MAX_ROOM_HEIGHT_MIN: int = WallToolConfig.WALL_HEIGHT_MAX
const MAX_ROOM_HEIGHT_MAX: int = 16

## Safe range for [member unsheltered_bed_multiplier] (GDD Tuning Knobs:
## 0.5-0.9).
const UNSHELTERED_BED_MULTIPLIER_MIN: float = 0.5
const UNSHELTERED_BED_MULTIPLIER_MAX: float = 0.9

## Safe range for [member room_cue_cooldown_ticks] (GDD Tuning Knobs: 0-120).
const ROOM_CUE_COOLDOWN_TICKS_MIN: int = 0
const ROOM_CUE_COOLDOWN_TICKS_MAX: int = 120

## See class doc comment's advisory-invariant note. `[assumption]`: Needs &
## Mood's own documented default for `ground_penalty`
## (`design/gdd/needs-mood-system.md` Tuning Knobs), duplicated here ONLY for
## this module's advisory smoke check -- never the source of truth.
const GROUND_PENALTY_ADVISORY_REFERENCE: float = 0.4

## Smallest connected candidate-interior region size that counts as a room
## (GDD Rule 2, default 2, Edge Case 9).
@export var min_room_cells: int = 2

## How high above an interior cell the nearest solid cell may sit and still
## count as "roofed" (GDD Rule 1, default 8). Lockstep invariant with the
## Building System's max `wall_height` -- see class doc comment (AC27).
@export var max_room_height: int = 8

## Middle rung of the sleep recovery ladder -- a sheltered-but-outside-a-room
## bed's rate multiplier (GDD Rule 6, default 0.7). Owned by Needs & Mood's
## rate table; this module supplies only the sheltered/unsheltered
## classification -- this field exists so Build Validation's own courtesy
## advisory check (see class doc comment) has a value to compare, and so the
## GDD's registered Tuning Knob has exactly one authoritative home for this
## story's scope.
@export var unsheltered_bed_multiplier: float = 0.7

## Minimum ticks between `room_recognized` celebration events (GDD Rule 11,
## default 20 = 10s at 1x). Consumed by a later story's pacing logic -- out
## of scope here.
@export var room_cue_cooldown_ticks: int = 20

## Need-functional furniture identification (Story build-validation-006, BV-1
## §6 -- `production/architecture-decisions-m02-preflight-2026-07-26.md`; GDD
## Rule 8: "need-functional furniture -- furniture with a need-recovery
## function -- MVP: the bed; decorative/inert furniture never warns"). A
## typed, data-driven `@export` list of need-functional item ids (ADR-0002) --
## NOT a new [ItemDefinitionResource] field (BV-1 §6 explicitly rules that
## out) -- so a future need-functional item is a data change here, never a
## code change. [method is_need_functional] is the sole consumer of this
## field; [BuildValidationShelterClassifier]'s own shelter/unsheltered
## predicate never reads it -- `shelter_status_changed` fires for ALL
## furniture regardless of need-functional status (GDD Rule 10 /
## [TR-build-validation-navigability-036]). This field exists so story 008's
## sealed-space Warning tier has a config seam ready to consume without a new
## story -- story 006 itself does not call [method is_need_functional]
## anywhere in its own signal logic.
@export var need_functional_item_ids: Array[StringName] = [&"bed"]


## See [ConfigResource.validate]. Clamps every single-field range issue to
## its documented safe bound in place (the sole sanctioned runtime write to
## this config) and appends a warning string per clamped field, EXCEPT
## [member max_room_height]'s lower bound, whose violation is the AC27
## cross-value invariant and is reported as BLOCKING instead (never clamped
## here -- see class doc comment). The ladder-ordering advisory check is
## independent of any clamp and is evaluated against the RAW (pre-clamp)
## [member unsheltered_bed_multiplier] value, so an out-of-safe-range value
## can trip BOTH the ordinary clamp warning AND the advisory warning in the
## same call (GDD's own documented "authoring trap": the two modules' safe
## ranges are not mutually safe at their extremes -- the load check, not the
## ranges, is the guarantee).
func validate() -> Array[String]:
	var issues: Array[String] = []

	if min_room_cells < MIN_ROOM_CELLS_MIN or min_room_cells > MIN_ROOM_CELLS_MAX:
		issues.append(
			"min_room_cells out of range [%s, %s], got %s -- clamped" %
			[MIN_ROOM_CELLS_MIN, MIN_ROOM_CELLS_MAX, min_room_cells]
		)
		min_room_cells = clampi(min_room_cells, MIN_ROOM_CELLS_MIN, MIN_ROOM_CELLS_MAX)

	if max_room_height < MAX_ROOM_HEIGHT_MIN:
		issues.append(ConfigResource.format_blocking(
			(
				"max_room_height (%s) must be >= the Building System's max wall_height (%s)"
				+ " -- lockstep invariant (GDD Tuning Knobs); retune both together"
			) % [max_room_height, WallToolConfig.WALL_HEIGHT_MAX]
		))
	elif max_room_height > MAX_ROOM_HEIGHT_MAX:
		issues.append(
			"max_room_height out of range [%s, %s], got %s -- clamped" %
			[MAX_ROOM_HEIGHT_MIN, MAX_ROOM_HEIGHT_MAX, max_room_height]
		)
		max_room_height = clampi(max_room_height, MAX_ROOM_HEIGHT_MIN, MAX_ROOM_HEIGHT_MAX)

	if not (
		GROUND_PENALTY_ADVISORY_REFERENCE < unsheltered_bed_multiplier
		and unsheltered_bed_multiplier < 1.0
	):
		issues.append(
			(
				"ADVISORY: ladder ordering ground_penalty (%s, this module's advisory"
				+ " reference value) < unsheltered_bed_multiplier (%s) < 1.0 does not hold"
				+ " -- Needs & Mood owns BLOCKING enforcement of this invariant (its own"
				+ " AC29); this is the courtesy duplicate smoke check only, never a"
				+ " boot-halt"
			) % [GROUND_PENALTY_ADVISORY_REFERENCE, unsheltered_bed_multiplier]
		)
	if (
		unsheltered_bed_multiplier < UNSHELTERED_BED_MULTIPLIER_MIN
		or unsheltered_bed_multiplier > UNSHELTERED_BED_MULTIPLIER_MAX
	):
		issues.append(
			"unsheltered_bed_multiplier out of range [%s, %s], got %s -- clamped" %
			[UNSHELTERED_BED_MULTIPLIER_MIN, UNSHELTERED_BED_MULTIPLIER_MAX, unsheltered_bed_multiplier]
		)
		unsheltered_bed_multiplier = clampf(
			unsheltered_bed_multiplier, UNSHELTERED_BED_MULTIPLIER_MIN, UNSHELTERED_BED_MULTIPLIER_MAX
		)

	if (
		room_cue_cooldown_ticks < ROOM_CUE_COOLDOWN_TICKS_MIN
		or room_cue_cooldown_ticks > ROOM_CUE_COOLDOWN_TICKS_MAX
	):
		issues.append(
			"room_cue_cooldown_ticks out of range [%s, %s], got %s -- clamped" %
			[ROOM_CUE_COOLDOWN_TICKS_MIN, ROOM_CUE_COOLDOWN_TICKS_MAX, room_cue_cooldown_ticks]
		)
		room_cue_cooldown_ticks = clampi(
			room_cue_cooldown_ticks, ROOM_CUE_COOLDOWN_TICKS_MIN, ROOM_CUE_COOLDOWN_TICKS_MAX
		)

	return issues


## Whether [param definition_id] identifies need-functional furniture (Story
## build-validation-006, BV-1 §6): resolved through [method
## ResourceItemDatabase.get_by_id] -- NEVER a hardcoded `&"bed"` comparison
## anywhere in this predicate; membership in [member need_functional_item_ids]
## is the only thing that decides the answer, so a retune is a data edit to
## this field, never a code edit here. An id [ResourceItemDatabase] cannot
## resolve (unauthored, or the database not yet Ready) is never
## need-functional -- a fail-safe default consistent with this module's own
## Rule 9 (never fail loudly at the player), not an error.
func is_need_functional(definition_id: StringName) -> bool:
	var definition: ItemDefinition = ResourceItemDatabase.get_by_id(definition_id)
	if definition == null:
		return false
	return need_functional_item_ids.has(definition.get_id())
