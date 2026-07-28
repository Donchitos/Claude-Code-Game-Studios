## Typed tuning-config Resource for Voxel World / Grid Data's block-appearance
## table (ADR-0002) -- Story vox-023, "Block appearance becomes DATA". Replaces
## `voxel_world_mesher.gd`'s `const DEBUG_BLOCK_COLORS` (a one-entry hardcoded
## `Dictionary[int, Color]`) with a config [Resource] the project's palette
## owner edits directly -- following `presentation-004`'s [WorldLightingConfig]
## precedent verbatim: same ADR, same `.tres` location convention
## (`res://data/config/`), same `validate()` discipline, same Inspector wiring
## on `Valley.tscn`.
##
## ⚑ THE POINT (story vox-023, one sentence): the user must be able to change a
## terrain colour by editing data and nothing else. Every field below is a
## typed `@export`; there is no block-colour literal anywhere in
## `src/voxel_world/` except [VoxelWorldMesher]'s own retained
## `DEBUG_UNKNOWN_COLOR` (the visible-fail path for an unmapped id -- this
## project's "visible fail, never silent" rule, unchanged by this story).
##
## Storage shape (Open Decision 1, story vox-023) -- parallel
## `Array[int]` + `Array[String]` (hex), chosen over BOTH options the story
## named:
## - NOT a typed `Dictionary[int, Color]` (Open Decision 1 option (c)): typed
##   `Dictionary` `@export` round-tripping through `.tres` is a genuine
##   post-cutoff-risk behavior the story itself flags BLOCKING
##   (`docs/engine-reference/godot/breaking-changes.md`'s 4.4-4.7 entries cover
##   typed-collection and Resource-export changes across exactly that span) --
##   avoided entirely.
## - NOT the story's own suggested `PackedInt32Array`/`PackedStringArray`
##   (Open Decision 1 option (a) as literally worded): those carry no
##   correctness risk either, but they have ZERO existing `@export`/`.tres`
##   precedent anywhere in this project's config Resources.
## - CHOSEN: `Array[int]` + `Array[String]` -- GDScript's typed-Array syntax
##   predates the model's knowledge-cutoff by a full engine generation
##   (introduced Godot 4.0, years before the 4.4-4.7 post-cutoff window this
##   project's own `VERSION.md` warns about) and, more importantly, is
##   ALREADY PROVEN in this exact repo, in this exact engine install:
##   [VoxelWorldConfig.band_ids] (`Array[int]`, story vox-022, shipped and
##   green) and [BuildValidationConfig.need_functional_item_ids]
##   (`Array[StringName]`, story build-validation-006, shipped and green) are
##   both typed-Array `@export` fields on a `ConfigResource` subclass, backed
##   by a real `.tres` file, read at real boot, today. This is therefore the
##   STRICTLY SAFER of the two named options, not merely an equally-safe
##   alternative -- recorded here per Open Decision 1's own instruction
##   ("record the choice and its engine-reference verification in the commit
##   body").
## - [method get_color]'s hex-to-[Color] conversion uses the plain
##   `Color(String)` constructor -- the SAME call [VoxelWorldMesher]'s own
##   pre-story `DEBUG_BLOCK_COLORS` entry already used
##   (`Color("9CAD6E")`, that file's own line 147 before this story) -- not a
##   new engine surface, the one already proven in this exact file.
##
## Wired into [VoxelWorldMesher] (injected-tier, ADR-0001) as a typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/block_appearance_config.tres`.
##
## AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL (Story vox-023, sprint-12's own deepest
## rule, Lever 3): this config has NO fallback table anywhere in code.
## [VoxelWorldMesher.setup] asserts this config is wired, exactly like its
## existing `grid`/`grid.config` asserts, and `Valley`'s own boot-invariant
## block additionally asserts the wiring -- an unwired appearance config is a
## loud boot failure, never a correct-looking render.
##
## Two-tier validation policy (ADR-0002): every issue [method validate] can
## return here is a structural/cross-value defect (mismatched array lengths,
## duplicate id, out-of-range id, malformed hex, an empty table) -- there is
## no single "nearest valid" fix for any of these (unlike e.g.
## [VoxelWorldConfig]'s scalar knobs), so EVERY issue this config's
## [method validate] returns is [method ConfigResource.format_blocking]-tagged;
## the non-blocking clamp-and-warn tier simply never applies to this
## particular config's field shape.
class_name BlockAppearanceConfig
extends ConfigResource

## Safe range for a [member block_type_ids] entry -- the same dig-order-
## eligible "1..5 value family" GDD Core Rule 8 / TR-voxel-world-051 reserves
## for terrain bands and sand ([VoxelWorldConfig.BAND_ID_MIN]/
## [VoxelWorldConfig.BAND_ID_MAX]'s own identical family, mirrored here on the
## appearance side rather than re-derived).
const BLOCK_TYPE_ID_MIN: int = 1
const BLOCK_TYPE_ID_MAX: int = 5

## Every terrain block-type id this table has an appearance entry for, keyed
## positionally with [member block_colors_hex]: `block_type_ids[i]`'s colour
## is `block_colors_hex[i]`. Shipped defaults are `vox-022`'s ratified band ids
## (`VoxelWorldConfig.band_ids`'s own shipped value) -- id 1 stays Lowland, the
## SAME compatibility constraint that story's own `AC-ID-1-STAYS-LOWLAND`
## already established (every already-serialized region file and
## `blueprint_cell.gd`'s built-cell default both assume id 1 is the Lowland
## olive).
@export var block_type_ids: Array[int] = [1, 2, 3, 4]

## Parallel hex colour string per id in [member block_type_ids] -- the art
## bible SS4.3 hexes verbatim (AC-SHIPPED-VALUES-ARE-THE-ART-BIBLE'S): Lowland
## `9CAD6E`, Midland `A98F5E`, Highland `7C818A`, Peak `C9D3D8`. Six hex digits,
## no leading `#` -- the exact bare-hex notation `design/art/palette.json` /
## `palette-system.md` / `palette_tables.md` already use, so the palette
## owner's own working notation is what they see and edit here.
@export var block_colors_hex: Array[String] = ["9CAD6E", "A98F5E", "7C818A", "C9D3D8"]


## See [ConfigResource.validate]. Every issue is BLOCKING (class doc comment)
## -- an empty table, a length mismatch, an out-of-family id, a duplicate id,
## or a malformed hex string all halt boot through the existing terminal path
## (ADR-0002/0005), never a silent clamp -- there is no single "nearest valid"
## id or colour to clamp any of these to.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if block_type_ids.is_empty():
		issues.append(ConfigResource.format_blocking("block_type_ids must not be empty"))
		return issues
	if block_colors_hex.size() != block_type_ids.size():
		issues.append(ConfigResource.format_blocking(
			"block_colors_hex length (%s) must equal block_type_ids length (%s)" %
			[block_colors_hex.size(), block_type_ids.size()]
		))
		return issues
	var seen_ids: Dictionary[int, bool] = {}
	for i in block_type_ids.size():
		var id: int = block_type_ids[i]
		if id < BLOCK_TYPE_ID_MIN or id > BLOCK_TYPE_ID_MAX:
			issues.append(ConfigResource.format_blocking(
				"block_type_ids[%s] (%s) must be within the dig-order-eligible [%s, %s] family (TR-voxel-world-051)" %
				[i, id, BLOCK_TYPE_ID_MIN, BLOCK_TYPE_ID_MAX]
			))
		if seen_ids.has(id):
			issues.append(ConfigResource.format_blocking(
				"block_type_ids[%s] (%s) duplicates an earlier entry" % [i, id]
			))
		seen_ids[id] = true
		if not _is_valid_hex(block_colors_hex[i]):
			issues.append(ConfigResource.format_blocking(
				"block_colors_hex[%s] (\"%s\") is not a valid 6-digit hex colour string" % [i, block_colors_hex[i]]
			))
	return issues


## Resolves [param block_type_id] to its configured [Color], or
## [param fallback] if no entry exists -- the ONE lookup this config exposes,
## consumed by [VoxelWorldMesher] in place of its old `DEBUG_BLOCK_COLORS`
## dictionary lookup. Rebuilt by linear scan on every call rather than cached:
## this table is small (a handful of entries) and read-mostly (once per solid
## cell face during a chunk build), so a cache would trade a trivial cost for
## real invalidation fragility this config does not need to own.
func get_color(block_type_id: int, fallback: Color) -> Color:
	for i in block_type_ids.size():
		if block_type_ids[i] == block_type_id:
			return Color(block_colors_hex[i])
	return fallback


## Returns whether [param hex] is a well-formed, bare 6-digit hex colour
## string (optional leading `#`) -- validated explicitly rather than trusting
## [Color]'s own constructor, which parses malformed input permissively
## (falling back to black/magenta silently) instead of raising an error.
static func _is_valid_hex(hex: String) -> bool:
	var stripped: String = hex.trim_prefix("#")
	if stripped.length() != 6:
		return false
	for c: String in stripped:
		if not c.is_valid_hex_number():
			return false
	return true
