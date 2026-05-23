## CasebookEntry — one Resolved case preserved in the casebook.
##
## Written by the resolution cascade (story 005) when an `evaluation_completed`
## arrives: the case's verdict + final score are archived here and appended to
## [Casebook]. Read-only afterward (Pillar 1 — Resolved cases cannot be reverted).
##
## [member save_file_version] participates in the schema-migration framework
## (ADR-0011): a loaded entry with a version higher than
## [code]SaveLoadServiceClass.CURRENT_SAVE_FILE_VERSION[/code] is treated as corruption.
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
class_name CasebookEntry extends Resource

## On-disk schema version for this Resource (ADR-0011 migration framework).
@export var save_file_version: int = 1

## Canonical case identifier (e.g. "case:2026-001").
@export var case_id: String = ""

## The court disposition verdict (library_dispositions_court enum member, as String).
@export var verdict: String = ""

## Final evaluation score in [code][0.0, 1.0][/code].
@export var final_score: float = 0.0
