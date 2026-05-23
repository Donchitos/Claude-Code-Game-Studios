## Casebook — the lawyer's archive of all Resolved cases.
##
## Eager-loaded at boot (story 004) and appended to by the resolution cascade
## (story 005). Persisted as `user://saves/casebook.tres`. Consumed by #11 Career
## and #14 Retrospective Replay.
##
## [member save_file_version] participates in the schema-migration framework
## (ADR-0011). Nested [CasebookEntry] resources are serialized inline.
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
class_name Casebook extends Resource

## On-disk schema version for this Resource (ADR-0011 migration framework).
@export var save_file_version: int = 1

## All archived Resolved cases, in insertion (resolution) order.
@export var entries: Array[CasebookEntry] = []
