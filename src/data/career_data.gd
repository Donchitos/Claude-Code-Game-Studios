## CareerData — career progression state (MVP placeholder).
##
## Owned at the design level by #11 Career Progression; Save/Load only provides the
## serialization infrastructure (ADR-0011 §Enables). MVP stores the completed-case ID
## list + a reputation scalar (#12 Reputation Alpha). Persisted as
## `user://saves/career.tres`.
##
## [member save_file_version] participates in the schema-migration framework (ADR-0011).
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
class_name CareerData extends Resource

## On-disk schema version for this Resource (ADR-0011 migration framework).
@export var save_file_version: int = 1

## Canonical IDs of all completed (Resolved) cases.
@export var completed_case_ids: Array[String] = []

## Reputation score (#12 Reputation Alpha — MVP placeholder).
@export var reputation: float = 0.0
