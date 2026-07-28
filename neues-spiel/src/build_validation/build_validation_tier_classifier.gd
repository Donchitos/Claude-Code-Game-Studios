## Warning/Info tier decision for one furniture item (Story build-validation-008,
## ADR-0007 primary; GDD `design/gdd/build-validation-navigability.md` Rule 8,
## [TR-build-validation-navigability-033]/[-034]/[-035]/[-041]/[-042]).
##
## **Per-item, per-pass decision, LEVEL-TRIGGERED** (Implementation Notes:
## "Tier selection is a per-item decision made once per pass: Warning if the
## item is need-functional AND its region is Sealed; else Info if the item is
## a bed, unsheltered, and not inside a sealed region; else nothing"): this
## class holds no memory of its own -- every call is a fresh, independent
## verdict, mirroring [BuildValidationShelterClassifier]'s own "a LIVE lookup,
## never a cached-snapshot read" precedent (Rule 11's edge-detection snapshot
## belongs to [signal BuildValidation.shelter_status_changed]/[signal
## BuildValidation.room_recognized] alone -- Warning/Info are deliberately NOT
## snapshotted anywhere, [TR-build-validation-navigability-046]).
##
## **"Is a bed" collapses to "is need-functional" in MVP, deliberately, not by
## accident.** The GDD's Info-tier wording names "a claimed/placed bed"
## specifically, distinct from the Warning tier's "need-functional furniture"
## wording -- but [BuildValidationConfig.need_functional_item_ids] defaults to
## EXACTLY `[&"bed"]` (BV-1 §6), so no fixture or Acceptance Criterion in this
## story exercises a case where those two sets diverge (AC35's decorative item
## is tested only in the SEALED branch, never the "unsheltered in the open"
## branch, so it never reaches this class's Info check either way). Reusing
## the SAME [param is_need_functional] flag for both tiers therefore satisfies
## every named AC without a second, hardcoded `&"bed"` identity literal
## anywhere in this module (avoiding exactly the kind of hardcoded-bed-check
## `build_validation_shelter_classification_test.gd`'s own grep guard already
## forbids in sibling files) -- if a future story adds a SECOND need-functional
## item that is not a bed, this predicate would then also let it earn the Info
## hint, which is a documented MVP scope call, not an oversight: revisit this
## conflation the day a second need-functional item lands.
##
## **[param sheltered] is a caller-supplied input, not recomputed here** --
## [method BuildValidation._reclassify_all_furniture] already calls
## [method BuildValidationShelterClassifier.is_sheltered] once per item for
## [signal BuildValidation.shelter_status_changed]'s own transition logic;
## passing that same boolean in here avoids a second, redundant "every cell is
## Room" scan and keeps the two signals' underlying sheltered/unsheltered
## verdict provably identical by construction (never two independently-
## computed answers that could silently drift apart).
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [CandidateCellRules]/[BuildValidationRegionFormation]/
## [BuildValidationReachability]/[BuildValidationShelterClassifier]'s own
## established "separate stateless algorithm library" precedent.
class_name BuildValidationTierClassifier
extends RefCounted

## One furniture item's tier verdict for the CURRENT pass (Rule 8 exclusivity,
## [TR-build-validation-navigability-035]): [constant NONE] -- sheltered, or
## unsheltered-but-not-need-functional (AC34's "no furniture" case and AC35's
## decorative-item case both resolve here); [constant WARNING] -- need-
## functional AND at least one occupied cell forms a Sealed region;
## [constant INFO] -- need-functional, unsheltered, and no occupied cell forms
## a Sealed region (i.e. genuinely in the open, including AC28's "no
## candidate region at all" case, which classifies OPEN, never SEALED).
enum Tier { NONE, WARNING, INFO }

## One item's classification result. [member sealed_region] is populated ONLY
## when [member tier] is [constant Tier.WARNING] -- the specific Sealed region
## [method BuildValidation._reclassify_all_furniture] groups this item's
## `sealed_space_warning` emission by (two items whose own sealed regions
## share even one cell are, by region-formation's own connectivity guarantee,
## in the exact same region). `null` for [constant Tier.NONE]/[constant
## Tier.INFO] -- Info's own payload is per-ITEM only (no region cells), and
## NONE needs no region at all.
class ItemTierResult:
	var tier: Tier
	var sealed_region: BuildValidationRegion

	func _init(p_tier: Tier, p_sealed_region: BuildValidationRegion = null) -> void:
		tier = p_tier
		sealed_region = p_sealed_region


## The per-item tier decision (Rule 8, Implementation Notes' own three-branch
## order, preserved exactly):
## 1. [param sheltered] -- already known Room-everywhere; [constant Tier.NONE],
##    no scan at all (AC12/14 territory belongs to [signal shelter_status_changed]
##    alone, never to this signal pair).
## 2. Otherwise, scan every one of [param cells]' own freshly-formed regions
##    ([method BuildValidationRegionFormation.form_region] + [method
##    BuildValidationReachability.classify_region], the same two calls
##    [BuildValidationShelterClassifier] itself makes) for the FIRST cell
##    whose region classifies [constant BuildValidationReachability.Verdict.SEALED].
##    If found AND [param is_need_functional]: [constant Tier.WARNING] carrying
##    that region (AC3/AC17/AC18). If found but NOT need-functional:
##    [constant Tier.NONE] (AC35 -- decorative furniture never warns).
## 3. No cell forms a Sealed region (every non-Room cell classifies OPEN --
##    AC28's "no candidate region at all" included, since [method
##    BuildValidationReachability.classify_region] answers OPEN for a
##    below-`min_room_cells`/empty region, never SEALED): [constant Tier.INFO]
##    iff [param is_need_functional] (AC17's "unsheltered in the open" case),
##    else [constant Tier.NONE].
##
## An empty [param cells] returns [constant Tier.NONE] -- nothing to classify,
## never a crash (mirrors [method BuildValidationShelterClassifier.is_sheltered]'s
## own empty-cells convention).
static func classify_item_tier(
	voxel_world: VoxelWorldGrid,
	cells: Array[Vector3i],
	sheltered: bool,
	is_need_functional: bool,
	min_room_cells: int,
	max_room_height: int,
) -> ItemTierResult:
	assert(
		voxel_world != null, "BuildValidationTierClassifier.classify_item_tier requires voxel_world"
	)
	if sheltered or cells.is_empty():
		return ItemTierResult.new(Tier.NONE)

	var sealed_region: BuildValidationRegion = null
	for cell: Vector3i in cells:
		var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
			voxel_world, cell, max_room_height
		)
		var verdict: BuildValidationReachability.Verdict = BuildValidationReachability.classify_region(
			voxel_world, region, min_room_cells, max_room_height
		)
		if verdict == BuildValidationReachability.Verdict.SEALED:
			sealed_region = region
			break

	if sealed_region != null:
		if is_need_functional:
			return ItemTierResult.new(Tier.WARNING, sealed_region)
		return ItemTierResult.new(Tier.NONE)

	if is_need_functional:
		return ItemTierResult.new(Tier.INFO)
	return ItemTierResult.new(Tier.NONE)
