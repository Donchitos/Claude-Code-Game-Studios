## Retired-ids ledger (GDD Edge Case 6 / Core Rule 1's "never reused"
## guarantee; TR-resource-item-database-042).
##
## A tiny, freely [code]@export[/code]-editable [Resource] listing every id
## that was once shipped and has since been retired. Boot validation (Story
## rid-005, [ResourceItemDatabase._validate_single_entry]) rejects any NEW
## authored entry whose [code]id[/code] appears here -- this protects old
## save files from resolving a retired id to the WRONG thing, which is
## worse than the `missing_item` fallback (GDD Edge Case 1 vs. Edge Case 6).
##
## The shipped MVP ledger is empty (GDD: "the shipped MVP ledger is
## empty") -- this class only defines the schema and the loading contract
## ([ResourceItemDatabase.ledger_path] / [ResourceItemDatabase.
## DEFAULT_LEDGER_PATH]); a missing ledger file at that path is NOT a boot
## failure, it degrades to "zero retired ids" (mirrors [member
## ResourceItemDatabase.data_dir]'s own missing-directory tolerance).
## Populating this ledger with real retired ids as they occur is future
## content-authoring work, not this class's or Story rid-005's scope.
class_name RetiredIdsLedgerResource
extends Resource

## Every id that is no longer authorable. Empty in the shipped MVP data set.
@export var retired_ids: Array[StringName] = []
