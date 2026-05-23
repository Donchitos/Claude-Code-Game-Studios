## PlayerSubmission — the player's brief submitted for evaluation (ADR-0007).
##
## Built by the Brief Editor submit flow; passed to
## [code]EvaluationService.submit(submission)[/code] (TD-001: PlayerSubmission is the
## canonical entry — the grading algorithm scores disposition + citations, neither of
## which is in chain_data alone).
##
## ADR: docs/architecture/adr-0007-submission-evaluation-algorithm.md
## TR:  TR-submission-*
class_name PlayerSubmission extends Resource

@export var case_id: String = ""
## library_dispositions_court enum member (파기/파기환송/기각/각하).
@export var player_disposition: String = ""
## Cited Library IDs, insertion order preserved.
@export var player_citations: Array[String] = []
## v1+ reasoning chain (MVP: empty Dict — GDD §3.1.1). Variant primitives only (ADR-0007 amend-1).
@export var chain_data: Dictionary = {}
## Telemetry — NOT scored.
@export var submission_time_ms: int = 0
