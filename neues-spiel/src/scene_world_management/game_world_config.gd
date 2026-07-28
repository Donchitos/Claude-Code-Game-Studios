## Typed tuning-config Resource for Scene/World Management's [GameWorld] root
## (ADR-0002) -- the boot-sequencing/world-genesis module's own config,
## following the exact same one-Resource-per-module pattern every other
## injected-tier module already uses (`VoxelWorldConfig`, `CameraInputConfig`,
## `VillagerAIConfig`, ...).
##
## Story scene-005 (world genesis in the boot sequence) is this class's first
## consumer: [method GameWorld._run_world_genesis] bounds its residency-drive
## loop by [member genesis_wall_clock_ceiling_ms] rather than a hardcoded
## literal (ADR-0002's "no literal radii/counts/ceilings in code" mandate,
## Control Manifest Required Patterns).
##
## Deliberately [code]null[/code]-tolerant at the call site, not a hard
## dependency: [GameWorld] itself predates having any config Resource at all,
## and dozens of pre-existing DI/boot-gate-only tests construct
## [code]GameWorld.new()[/code] directly without ever wiring this field (they
## never reach world genesis in the first place -- see [method
## GameWorld._run_world_genesis]'s own guard). [method
## GameWorld._run_world_genesis] falls back to a sane in-code default when
## [member GameWorld.config] is unwired, mirroring
## [Valley.spawn_starting_roster]'s own already-established
## "`if config != null: use its value` else a documented literal default"
## precedent for an optional Resource dependency -- this is NOT a second,
## silently-duplicated ceiling; it is the one place that fallback literal is
## allowed to live, exactly as `spawn_starting_roster`'s own `count = 1`
## fallback is the one place ITS fallback literal lives.
class_name GameWorldConfig
extends ConfigResource

## Safe range for [member genesis_wall_clock_ceiling_ms] -- an
## [code][assumption][/code]: no GDD names this boot-genesis ceiling as a
## Tuning Knob (it did not exist as a concept before this story). Floor is
## generous enough that a pathological world-genesis stall still terminates
## in a fraction of a second rather than spinning unbounded (Control Manifest
## Required: "the boot loop is bounded... never an unbounded spin"); ceiling
## is well under the technical-director's own 3.0s total boot-to-ACTIVE
## ruling (`production/architecture-decisions-m02-preflight-2026-07-26.md`
## Addendum D / D2) -- a ceiling AT or above 3.0s would make this knob
## meaningless as a genesis-specific safety valve distinct from the
## story's own advisory measurement.
const GENESIS_WALL_CLOCK_CEILING_MS_MIN: float = 100.0
const GENESIS_WALL_CLOCK_CEILING_MS_MAX: float = 2500.0

## Wall-clock ceiling, milliseconds, bounding [method
## GameWorld._run_world_genesis]'s residency-drive loop (alternating [method
## VoxelWorldGrid.update_residency] with [method
## VoxelWorldGrid.drain_pending_async_reads] until every desired boot-window
## chunk is resident OR this ceiling elapses -- Story scene-005,
## AC-NO-SYNC-IO-IN-FRAME-PATH: "Boot-time draining is bounded by a
## config-driven wall-clock ceiling and terminates deterministically when it
## is hit"). Measured evidence (`production/qa/evidence/
## boot-mesh-radius-boot-budget-20260726.md`, vox-021): the boot-radius
## residency page-in itself (625 chunks, view_radius_chunks=12) took
## ~112.5-113.1 ms end to end via the equivalent [code]update_residency[/code]
## + settle-loop pattern -- this default carries roughly 8-9x headroom over
## that measured figure, generous enough to also absorb a slower first-run
## disk/OS-cache-cold page-in without being anywhere close to the
## technical-director's 3.0s total ceiling.
@export var genesis_wall_clock_ceiling_ms: float = 1000.0


## See [ConfigResource.validate]. Clamps [member genesis_wall_clock_ceiling_ms]
## to its safe range in place and appends a warning string if it was out of
## range -- the sole sanctioned runtime write to this config (ADR-0002).
func validate() -> Array[String]:
	var issues: Array[String] = []
	if (
		genesis_wall_clock_ceiling_ms < GENESIS_WALL_CLOCK_CEILING_MS_MIN
		or genesis_wall_clock_ceiling_ms > GENESIS_WALL_CLOCK_CEILING_MS_MAX
	):
		issues.append(
			"genesis_wall_clock_ceiling_ms out of range [%s, %s], got %s -- clamped" %
			[GENESIS_WALL_CLOCK_CEILING_MS_MIN, GENESIS_WALL_CLOCK_CEILING_MS_MAX, genesis_wall_clock_ceiling_ms]
		)
		genesis_wall_clock_ceiling_ms = clampf(
			genesis_wall_clock_ceiling_ms, GENESIS_WALL_CLOCK_CEILING_MS_MIN, GENESIS_WALL_CLOCK_CEILING_MS_MAX
		)
	return issues
