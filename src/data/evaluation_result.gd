## EvaluationResult — the weighted grade produced by EvaluationService (ADR-0007).
##
## Emitted via [code]evaluation_completed(result)[/code]; consumed by #10 Verdict Reveal
## (presentation), #11 Career + Save/Load (persistence), #14 Retrospective Replay.
##
## ADR: docs/architecture/adr-0007-submission-evaluation-algorithm.md
## TR:  TR-submission-*
class_name EvaluationResult extends Resource

@export var case_id: String = ""
## Weighted total in [0.0, 1.0].
@export var final_score: float = 0.0
## Court disposition verdict (파기/파기환송/기각/각하).
@export var verdict: String = ""
## 5 subscore keys → float (penalty negative allowed).
@export var subscores: Dictionary = {}
## 5 keys → float; sum == final_score (AC-16).
@export var weighted_contributions: Dictionary = {}
## Selected comment template bodies (story 005).
@export var comments: Array[String] = []
## Matched correct citations (UI display).
@export var correct_set: Array[String] = []
## Missed correct citations.
@export var missed_set: Array[String] = []
## Redundant (irrelevant) citations.
@export var redundant_set: Array[String] = []
## Unix ms timestamp (excluded from AC-23 byte comparison).
@export var evaluated_at: int = 0
