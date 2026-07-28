## Typed detail sidecar for [LoopPayoffSignalSurface] payoffs (Build
## Validation & Navigability story build-validation-009, milestone criterion
## #7; CD Ruling 2, `production/creative-decisions-m02-preflight-2026-07-26.md`
## -- PROVISIONAL, pending user ratification).
##
## A small, PLAIN `RefCounted` value carrier -- deliberately NOT a
## `Dictionary` (static typing is enforced project-wide, `.claude/docs/
## technical-preferences.md`) -- carrying the per-occurrence facts a payoff's
## `payoff_type`/`subject` key pair alone cannot express: which member rooms
## were involved, whether a cue should fire, and the geometry the event
## happened to, AS OF the emitting pass (CD Ruling 2 minimum 4: "the geometry
## travels with the event... never re-queried afterward"). This class
## performs no logic of its own -- it is data only, constructed fresh by
## [LoopPayoffAdapter] (the sole real production writer) and read back via
## [method LoopPayoffSignalSurface.get_payoff_detail].
##
## `payoff_signaled(payoff_type, subject)` itself stays byte-identical (CD
## Ruling 2's own binding constraint) -- this class is carried ONLY through
## [method LoopPayoffSignalSurface.emit_payoff]'s trailing OPTIONAL parameter
## and [method LoopPayoffSignalSurface.get_payoff_detail]'s return value,
## never through the signal's own parameter list. A consumer that ignores
## this type entirely still compiles and behaves verbatim (Additivity).
##
## Field usage is PER PAYOFF KIND (`payoff_type`), not all-fields-always:
## `&"room_celebrated"`/`&"room_recognized_quiet"` use [member celebrate]/
## [member group_id]/[member subjects]/[member cells]; `&"shelter_status"`
## uses ONLY [member sheltered] (never a second payoff type for the toggle --
## see [LoopPayoffAdapter]'s own doc comment for why). Unused fields simply
## keep their harmless defaults; there is no per-kind subclassing, mirroring
## this codebase's established "one small value shape, defaults cover the
## unused branch" precedent (e.g. [BuildValidationTierClassifier.ItemTierResult]).
class_name PayoffDetail
extends RefCounted

## Room-celebration kinds only: whether this occurrence actually fired a cue
## (`true`, `&"room_celebrated"`) or is a quiet, status-only recognition
## inside the cooldown window (`false`, `&"room_recognized_quiet"`). Defaults
## `false` for `&"shelter_status"`, which carries its own boolean in
## [member sheltered] instead.
var celebrate: bool = false

## Room-celebration kinds only: the same-pass `pass_group_id`
## [BuildValidation.room_recognized] minted for this occurrence (Rule 11
## same-pass grouping) -- repeated here so a consumer never needs to
## re-derive it from `subject` (which, for `&"room_celebrated"`, already
## equals this same value per CD Ruling 2's own "the idempotency key becomes
## the celebration event" design -- kept on the detail too for the quiet kind,
## whose `subject` is a per-region key instead). Empty (`&""`) for
## `&"shelter_status"`.
var group_id: StringName = &""

## `&"room_celebrated"` only: every member region's own subject key recognized
## in this SAME analysis pass (CD Ruling 2 minimum 1 -- "detail.subjects.size()
## == N" for N same-pass recognitions). Always a single-element array for
## `&"room_recognized_quiet"` (that kind is never grouped -- CD Ruling 2's
## table: subject = the region's own key, not the pass group). Empty for
## `&"shelter_status"`.
var subjects: Array[StringName] = []

## `&"room_celebrated"`/`&"room_recognized_quiet"` only: the union of every
## member region's own interior cells AS OF THE EMITTING PASS (CD Ruling 2
## minimum 4) -- never re-queried from [BuildValidation] afterward, so a
## later pass splitting or merging the region cannot retroactively change
## what this detail reports. Empty for `&"shelter_status"`.
var cells: PackedVector3Array = PackedVector3Array()

## `&"shelter_status"` only: whether the item identified by `subject` (its
## item id) is currently sheltered. Defaults `false` for every room-
## celebration kind.
var sheltered: bool = false
