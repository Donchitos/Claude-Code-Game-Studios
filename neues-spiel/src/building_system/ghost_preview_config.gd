## Typed tuning-config Resource for [GhostPreview] (ADR-0002) -- GDD Tuning
## Knobs `preview_degradation_threshold` [TR-building-system-035],
## `draft_ghost_alpha` and `queued_ghost_alpha` (both Slice revision
## 2026-07-23, `design/gdd/building-system.md` Tuning Knobs table).
##
## Wired into [GhostPreview] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/ghost_preview_config.tres`. Mirrors
## [CommitPipelineConfig]/[WallToolConfig]'s established one-config-per-module
## precedent -- created fresh here rather than folded into a not-yet-existing
## shared `BuildingSystemConfig`.
##
## [member draft_ghost_alpha]/[member queued_ghost_alpha] are the PERSISTENT
## blueprint-ghost alpha tiers (Planned vs UnderConstruction, TR-069) -- they
## are NOT the live drag/hover preview's valid/invalid tint alpha, which
## [GhostPreview] keeps as a fixed, non-configurable overlay constant
## (mirrors [PlacementPick]'s own established "translucent, unshaded... no
## dedicated tuning knob" cursor-highlight precedent, see that class's
## `_ensure_highlight_mesh` doc comment) -- the GDD names no separate knob for
## the live preview's own alpha, only for the two PERSISTED-ghost tiers below.
class_name GhostPreviewConfig
extends ConfigResource

## Safe range for [member preview_degradation_threshold] (`design/gdd/
## building-system.md` Tuning Knobs: 32-512, default 128 -- "Above this cell
## count, the live drag preview degrades from per-cell ghosts to an outline/
## bounding representation" [TR-building-system-035]).
const PREVIEW_DEGRADATION_THRESHOLD_MIN: int = 32
const PREVIEW_DEGRADATION_THRESHOLD_MAX: int = 512

## Above this many pending cells, [GhostPreview]'s live drag preview degrades
## from per-cell ghosts to a single outline/bounding representation (AC50,
## [TR-building-system-035]/[TR-building-system-039]) -- protects the frame
## budget on a large drag while the eventual commit stays cell-exact.
@export var preview_degradation_threshold: int = 128

## Safe range for [member draft_ghost_alpha] (`design/gdd/building-system.md`
## Tuning Knobs, Slice revision 2026-07-23: 0.30-0.70, default 0.50).
const DRAFT_GHOST_ALPHA_MIN: float = 0.30
const DRAFT_GHOST_ALPHA_MAX: float = 0.70

## Translucency of a PERSISTED Planned blueprint ghost (GDD Tuning Knobs,
## TR-building-system-069's own "static translucent ghost" tier) -- the more
## tentative visual tier, distinct from [member queued_ghost_alpha].
@export var draft_ghost_alpha: float = 0.50

## Safe range for [member queued_ghost_alpha] (`design/gdd/building-system.md`
## Tuning Knobs, Slice revision 2026-07-23: 0.50-0.90, default 0.70).
const QUEUED_GHOST_ALPHA_MIN: float = 0.50
const QUEUED_GHOST_ALPHA_MAX: float = 0.90

## Translucency of a PERSISTED UnderConstruction blueprint ghost (GDD Tuning
## Knobs) -- more opaque than [member draft_ghost_alpha], reading as "actively
## being worked" (TR-building-system-069's "visible progress" tier; this
## story renders the distinct STATE, not Story 029's tick-driven progress
## fraction -- see [GhostPreview]'s own class doc comment). Must stay
## strictly greater than [member draft_ghost_alpha] (GDD: "or the two tiers
## become indistinguishable") -- enforced as a BLOCKING cross-value invariant
## in [method validate], never clamped (ADR-0002 two-tier policy: there is no
## single "nearest bound" fix for a relationship between two fields).
@export var queued_ghost_alpha: float = 0.70


## See [ConfigResource.validate]. Clamps each single-field range issue to its
## documented safe bound (the sole sanctioned runtime write to this config)
## and appends a warning string per clamped field, THEN checks the
## `queued_ghost_alpha > draft_ghost_alpha` cross-value invariant against the
## final (possibly-clamped) values -- reported as BLOCKING via [method
## ConfigResource.format_blocking] instead of clamped (mirrors
## [BuildValidationConfig]'s AC27 precedent for a self-contained, non-cross-
## module invariant this config itself fully owns).
func validate() -> Array[String]:
	var issues: Array[String] = []

	if (
		preview_degradation_threshold < PREVIEW_DEGRADATION_THRESHOLD_MIN
		or preview_degradation_threshold > PREVIEW_DEGRADATION_THRESHOLD_MAX
	):
		issues.append(
			"preview_degradation_threshold out of range [%s, %s], got %s -- clamped" %
			[PREVIEW_DEGRADATION_THRESHOLD_MIN, PREVIEW_DEGRADATION_THRESHOLD_MAX, preview_degradation_threshold]
		)
		preview_degradation_threshold = clampi(
			preview_degradation_threshold, PREVIEW_DEGRADATION_THRESHOLD_MIN, PREVIEW_DEGRADATION_THRESHOLD_MAX
		)

	if draft_ghost_alpha < DRAFT_GHOST_ALPHA_MIN or draft_ghost_alpha > DRAFT_GHOST_ALPHA_MAX:
		issues.append(
			"draft_ghost_alpha out of range [%s, %s], got %s -- clamped" %
			[DRAFT_GHOST_ALPHA_MIN, DRAFT_GHOST_ALPHA_MAX, draft_ghost_alpha]
		)
		draft_ghost_alpha = clampf(draft_ghost_alpha, DRAFT_GHOST_ALPHA_MIN, DRAFT_GHOST_ALPHA_MAX)

	if queued_ghost_alpha < QUEUED_GHOST_ALPHA_MIN or queued_ghost_alpha > QUEUED_GHOST_ALPHA_MAX:
		issues.append(
			"queued_ghost_alpha out of range [%s, %s], got %s -- clamped" %
			[QUEUED_GHOST_ALPHA_MIN, QUEUED_GHOST_ALPHA_MAX, queued_ghost_alpha]
		)
		queued_ghost_alpha = clampf(queued_ghost_alpha, QUEUED_GHOST_ALPHA_MIN, QUEUED_GHOST_ALPHA_MAX)

	if queued_ghost_alpha <= draft_ghost_alpha:
		issues.append(ConfigResource.format_blocking(
			(
				"queued_ghost_alpha (%s) must be > draft_ghost_alpha (%s) -- the two"
				+ " Planned-vs-UnderConstruction ghost tiers would become indistinguishable"
				+ " (GDD Tuning Knobs); retune both together"
			) % [queued_ghost_alpha, draft_ghost_alpha]
		))

	return issues
