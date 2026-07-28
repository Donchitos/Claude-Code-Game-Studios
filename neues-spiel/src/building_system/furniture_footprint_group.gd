## Building System's shared multi-cell furniture footprint group (Story
## building-016, GDD Core Rule 8/F5, [TR-building-system-124]; Control
## Manifest requirement: "all footprint cells are written/read as ONE
## furniture entity (same occupant id); ... never create N separate entities
## for one footprint").
##
## Every [BlueprintCell] created for the SAME furniture commit's footprint
## ([method CommitPipeline.commit], Story building-016) holds a reference to
## the SAME instance of this class -- never a per-cell copy -- so any one
## footprint cell can discover the CURRENT completion state of every sibling
## without a second registry anywhere. This is the seam [ConstructionTickLoop]
## (Story building-016 revision, [method ConstructionTickLoop._complete_jobs])
## consults to decide WHEN to route a multi-cell footprint's completion to
## [FurnitureRegistry] as exactly ONE [method FurnitureRegistry.place] call:
## GDD Core Rule 12's per-cell-job parallelism is UNCHANGED for furniture --
## a footprint's siblings may be claimed by DIFFERENT villagers and complete
## construction at DIFFERENT tick dispatches, in any order. Checking [member
## cells]' state from whichever sibling happens to complete LAST is what
## makes routing order-independent by construction, with [member
## is_registered] guarding against a second [method FurnitureRegistry.place]
## call when two or more siblings reach [constant
## BlueprintCell.MicroState.BUILT] in the SAME tick dispatch.
##
## `RefCounted`, not `Resource` -- a plain, code-constructed value object
## exactly like [BlueprintCell] itself: never authored, never serialized,
## never shared outside this system. `null` on every [member
## BlueprintCell.footprint_group] for a BLOCK-category cell and for a
## single-cell (1x1) furniture item -- [ConstructionTickLoop]'s completion
## routing falls back to "this cell alone" when unset, the exact pre-016
## behavior Story building-028 already shipped and tested.
class_name FurnitureFootprintGroup
extends RefCounted

## Every [BlueprintCell] belonging to this footprint (including whichever one
## holds this same reference) -- fixed once by [CommitPipeline] at commit
## time, never mutated afterward (no cell is ever added to or removed from
## an existing group).
var cells: Array[BlueprintCell] = []

## `true` once [ConstructionTickLoop] has routed this group's completion to
## [FurnitureRegistry] exactly once -- see class doc comment for why this
## guard is required (two or more siblings completing in the same tick
## dispatch would otherwise both observe "every sibling is Built" and both
## attempt to register the same entity).
var is_registered: bool = false

## Story building-017 addition (GDD Rule 16/[TR-building-system-127], atomic
## multi-cell demolition) -- `true` from the moment ANY footprint cell of
## this group is claimed for demolition ([method
## ConstructionTickLoop.claim_demolition_job]) until that SAME job completes.
## Guards a group-level double-claim [member ConstructionTickLoop._active_jobs]'s
## own per-cell keying cannot see on its own: unlike construction (where each
## sibling is its OWN independent job, keyed at its own cell address), a
## footprint's demolition is exactly ONE job tracked under a single
## representative cell key -- a second claim attempt against a DIFFERENT
## sibling cell of the SAME group would otherwise find [member
## ConstructionTickLoop._active_jobs] empty at THAT address and incorrectly
## succeed, creating two concurrent teardown jobs for what must be a single
## atomic entity removal ([TR-building-system-127]: "never a per-cell partial
## teardown"). Starts `false` -- a freshly-created group has no demolition
## order at all yet.
var is_demolition_active: bool = false
