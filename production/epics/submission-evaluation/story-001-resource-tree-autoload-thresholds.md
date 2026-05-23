# Story 001: Resource tree + EvaluationService autoload + threshold load

> **Epic**: Submission & Evaluation
> **Status**: Complete (2026-05-23)
> **Layer**: Feature (Gameplay) / Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3h (M)
> **Performance**: _ready() threshold load < 5ms; no per-frame cost

## Context
**GDD**: `design/gdd/submission-evaluation.md` §3.1 (Resource tree), §3.1.4/§7.1 (thresholds)
**Requirement**: `TR-submission-*` (Resource tree + autoload + threshold externalization)
**ADR Governing Implementation**: ADR-0007 §Decision (Resource tree + autoload THIRD + entities.yaml thresholds)
**ADR Decision Summary**: `PlayerSubmission` (case_id/player_disposition/player_citations/chain_data/submission_time_ms), `EvaluationResult` (case_id/final_score/verdict/subscores/weighted_contributions/comments/correct_set/missed_set/redundant_set/evaluated_at), `CommentTemplates` (Dictionary template_key→한국어). `EvaluationService` autoload THIRD; `_ready()` loads `submission_verdict_thresholds` {pagi:0.7, low:0.3}.
**Engine**: Godot 4.6 | **Risk**: None (class_name/@export/autoload 4.0+ stable)
**Control Manifest Rules**: Feature Layer — typed @export; verdict thresholds global (no per-case override — `per_case_verdict_threshold_override` forbidden)

## Acceptance Criteria
- [ ] AC — `PlayerSubmission` / `EvaluationResult` / `CommentTemplates` Resource classes per ADR-0007 §Decision field trees (typed @export)
- [ ] AC — `EvaluationService` autoload THIRD skeleton with `enum State {IDLE,VALIDATING,COMPUTING,REPORTING,DONE}`, `current_state` (IDLE), signals `evaluation_completed(result)` + `submission_rejected(reason)`
- [ ] AC-12/14 — `_ready()` loads `verdict_threshold_pagi=0.7` + `verdict_threshold_low=0.3` from entities.yaml/registry constant (global lock; no runtime mutation)

## Implementation Notes
Per ADR-0007: `class_name EvaluationServiceClass extends Node` (autoload-name-collision avoidance). Resources in `src/data/`. Thresholds: read from `design/registry/entities.yaml submission_verdict_thresholds` value `{pagi:0.7, low:0.3}` (or inline const mirroring it if registry parse is heavy — ADR-0007 §Alt notes inline const acceptable). class_name globals require `--import` cache regen (TD-005).

## Out of Scope
- Story 002 (scoring), 003 (verdict fn), 004 (state machine/submit), 005 (comments)

## QA Test Cases
- AC: instantiate each Resource → field defaults correct; EvaluationService autoload registered + current_state==IDLE + signals exist; thresholds loaded (0.7/0.3).

## Test Evidence
**Story Type**: Logic | **Required**: `tests/unit/submission_evaluation/resource_tree_test.gd`
**Status**: [ ] Not yet created

## Dependencies
- Depends on: None (epic entry)
- Unlocks: 002/003/004/005

## Completion Notes
**Completed**: 2026-05-23. 3/3 ACs. Files: src/data/player_submission.gd, evaluation_result.gd, comment_templates.gd; src/services/evaluation_service.gd (State enum + IDLE + signals + thresholds); project.godot autoload (EvaluationService, THIRD intent — registered after CaseService). Thresholds as inline const mirroring entities.yaml {pagi:0.7, low:0.3} (ADR-0007 §Alt sanctions inline const). Tests: resource_tree_test.gd 5/5. Full suite 420/0-fail. class cache regenerated (TD-005). Reviewed by orchestrator.
