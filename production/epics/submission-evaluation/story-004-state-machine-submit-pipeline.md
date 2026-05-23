# Story 004: submit() 5-state machine + Validating gate + evaluation_completed

> **Epic**: Submission & Evaluation
> **Status**: Complete (2026-05-23)
> **Layer**: Feature (Gameplay) / Core
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 4h (M)
> **Performance**: full pipeline ≤50ms (AC-21)

## Context
**GDD**: `design/gdd/submission-evaluation.md` §3.1.2 (pre-eval gate), §3.2 (states), §8.1/§8.5
**Requirement**: `TR-submission-*` (state machine + submit pipeline + validation)
**ADR Governing Implementation**: ADR-0007 §Decision (5-state machine, double-submit reject, validate_citations)
**ADR Decision Summary**: `submit(submission: PlayerSubmission)` (TD-001 RESOLVED): IDLE→VALIDATING (player_citations.size()≥1 + LibraryService.validate_citations all-pass; CaseService.get_case)→COMPUTING (scoring 002 + verdict 003)→REPORTING (emit evaluation_completed)→DONE→IDLE. Double-submit (current_state != IDLE) → push_warning + ignore (AC-18).
**Engine**: Godot 4.6 | **Risk**: None
**Control Manifest Rules**: never start 2nd submit while in flight (`submit_during_active_evaluation` forbidden); never cache EvaluationResult by case_id (`evaluation_caching_by_case_id` forbidden)

## Acceptance Criteria
- [ ] AC-17/18 (§8.1/§8.5) — `submit()` from non-IDLE → push_warning + ignored (double-submit reject)
- [ ] AC-1/2 (§8.1) — Validating gate: empty player_citations (size<1) → `submission_rejected("empty_citations")` (EC-1); citation failing `LibraryService.validate_citations` → `submission_rejected("invalid_citation")` (EC-2)
- [ ] AC (§8.4/§8.5) — happy path: VALIDATING→COMPUTING→REPORTING→DONE→IDLE; emits `evaluation_completed(result)` once with populated EvaluationResult (final_score + verdict + subscores + correct/missed/redundant sets)

## Implementation Notes
Per ADR-0007: state transitions guard current_state; CaseService.get_case(submission.case_id) for correct_disposition/correct_citations/scoring_weights; LibraryService.validate_citations(player_citations) returns invalid IDs (empty=all valid). Wire scoring (002) + verdict (003) in COMPUTING. correct_set/missed_set/redundant_set from Set ops. Return to IDLE after DONE.

## Out of Scope
- Stories 002/003 (scoring/verdict functions — this wires them), 005 (comments — REPORTING may call), 001 (Resources)
- Save/Load resolution subscription (sl-005 subscribes to evaluation_completed)

## QA Test Cases
- double-submit: 2nd submit while VALIDATING → ignored + warning. empty citations → submission_rejected. invalid citation (mock LibraryService) → submission_rejected. happy path → evaluation_completed once, state returns IDLE, result fields populated. Integration with real Library/Case fixtures.

## Test Evidence
**Story Type**: Integration | **Required**: `tests/integration/submission_evaluation/submit_pipeline_test.gd`
**Status**: [ ] Not yet created

## Dependencies
- Depends on: Story 001 (Resources/autoload), 002 (scoring), 003 (verdict); LibraryService.validate_citations + CaseService.get_case (exist)
- Unlocks: Save/Load sl-005/006 end-to-end, reasoning-workspace 007/008 submit hand-off, #10 Verdict Reveal

## Completion Notes
**Completed**: 2026-05-23. 3/3 ACs (double-submit reject AC-18, empty/invalid citation gate AC-1/2, happy-path emit AC-4/5).
**Files**: `src/services/evaluation_service.gd` — `submit(submission: PlayerSubmission)` (IDLE→VALIDATING→COMPUTING→REPORTING→DONE→IDLE; guarded /root LibraryService.validate_citations + CaseService.get_case lookups) + `_reject` + pure `evaluate(submission, case_file)` (subscores+final_score+verdict+correct/missed/redundant sets) + set helpers. `tests/integration/submission_evaluation/submit_pipeline_test.gd` 5 tests (Library+Case fixtures loaded into autoloads).
**Test Evidence**: submit_pipeline 5/5 PASS; full suite **425 cases / 408 executed / 17 skipped / 0 failures, exit 0**.
**Keystone**: `EvaluationService.submit(PlayerSubmission)` now works end-to-end → unblocks the deferred Save/Load sl-005 (evaluation_completed→casebook) + sl-006 (auto-resubmit) subscriptions and reasoning-workspace 007/008 submit hand-off (those subscriber wirings live in their own stories).
**Reviewed by orchestrator.** Remaining EvaluationService: story-005 (comment-template decision tree).
