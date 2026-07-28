## Typed tuning-config Resource for Scaffolding (ADR-0002; story `building-034`,
## technical-director ruling D6). Owns exactly one knob today:
## [member scaffold_max_cantilever_cells] -- AC4's "the 6-limit is config, not
## a literal."
##
## Wired as an injected-tier dependency (ADR-0001) wherever the scaffold
## erection planner is constructed; a matching `.tres` instance lives at
## `res://data/config/scaffold_config.tres`. Mirrors [WallToolConfig]'s
## established one-config-per-module, clamp-only precedent -- no BLOCKING
## cross-value invariant is declared for this config.
class_name ScaffoldConfig
extends ConfigResource

## Safe range for [member scaffold_max_cantilever_cells] (D6: "safe range
## 1-32 -- headroom for the progression stat ruling 4 requires"). The
## shipped default (6) is the USER's ruling (AC4), transcribed verbatim --
## this class does not own the value, only its safe bounds and storage shape.
const SCAFFOLD_MAX_CANTILEVER_CELLS_MIN: int = 1
const SCAFFOLD_MAX_CANTILEVER_CELLS_MAX: int = 32

## D6/AC4: the maximum horizontal Chebyshev cantilever distance (§D6.1/§D6.3)
## a scaffold cell may sit from its nearest supported column -- overhang only,
## never a height limit. Default `6` is the user's ruling (AC4), never a
## literal anywhere else in `src/` (grep-verifiable per AC4).
@export var scaffold_max_cantilever_cells: int = 6


## See [ConfigResource.validate]. Clamps [member scaffold_max_cantilever_cells]
## to its safe range and appends a warning string if it was out of range --
## no BLOCKING cross-value invariant exists for this config (ADR-0002
## two-tier policy), mirroring [WallToolConfig]'s clamp-only precedent.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if (
		scaffold_max_cantilever_cells < SCAFFOLD_MAX_CANTILEVER_CELLS_MIN
		or scaffold_max_cantilever_cells > SCAFFOLD_MAX_CANTILEVER_CELLS_MAX
	):
		issues.append(
			"scaffold_max_cantilever_cells out of range [%s, %s], got %s -- clamped" %
			[SCAFFOLD_MAX_CANTILEVER_CELLS_MIN, SCAFFOLD_MAX_CANTILEVER_CELLS_MAX, scaffold_max_cantilever_cells]
		)
		scaffold_max_cantilever_cells = clampi(
			scaffold_max_cantilever_cells, SCAFFOLD_MAX_CANTILEVER_CELLS_MIN, SCAFFOLD_MAX_CANTILEVER_CELLS_MAX
		)
	return issues
