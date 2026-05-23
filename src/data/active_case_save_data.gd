## ActiveCaseSaveData — the single in-progress case snapshot.
##
## Wraps the live [WorkspaceData] (chain_data snapshot + state) and the
## BriefEditorData (grounds/memo/citations + state) for the one case currently being
## worked. Persisted as `user://saves/active_case.tres` via the debounced autosave
## (story 003) and deleted on resolution (story 005, anti-save-scumming).
##
## [b]Note on [member brief_editor_data][/b]: the concrete `BriefEditorData` class is
## owned by the Brief Editor epic (ADR-0001 amend-2) and does not exist yet — the field
## is typed as [Resource] until that class lands, then it can be tightened.
##
## [member save_file_version] participates in the schema-migration framework (ADR-0011):
## a loaded snapshot with a version higher than
## [code]SaveLoadServiceClass.CURRENT_SAVE_FILE_VERSION[/code] is treated as corruption
## (story 004 recovery cascade).
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
class_name ActiveCaseSaveData extends Resource

## On-disk schema version for this Resource (ADR-0011 migration framework).
@export var save_file_version: int = 1

## Canonical identifier of the active case (e.g. "case:2026-001").
@export var case_id: String = ""

## Reasoning Workspace state snapshot (chain_data_snapshot + 4-state machine).
@export var workspace_data: WorkspaceData = null

## Brief Editor state snapshot. Typed loosely as [Resource] until the
## `BriefEditorData` class exists (Brief Editor epic / ADR-0001 amend-2).
@export var brief_editor_data: Resource = null
