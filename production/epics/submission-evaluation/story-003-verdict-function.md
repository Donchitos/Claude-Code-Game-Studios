# Story 003: Verdict function (파기/파기환송/기각/각하)

> **Epic**: Submission & Evaluation
> **Status**: Complete (2026-05-23)
> **Layer**: Feature (Gameplay) / Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 2h (S)
> **Performance**: trivial (comparison only)

## Context
**GDD**: `design/gdd/submission-evaluation.md` §4.7 (verdict 결정 함수), §7.1 (thresholds)
**Requirement**: `TR-submission-*` (verdict determination)
**ADR Governing Implementation**: ADR-0007 §Decision (verdict thresholds global)
**ADR Decision Summary**: verdict(player_disp, correct_disp, final_score) with thresholds pagi=0.7, low=0.3.
**Engine**: Godot 4.6 | **Risk**: None
**Control Manifest Rules**: thresholds global-locked; per-case override forbidden

## Acceptance Criteria
- [ ] AC (§8.3, §4.7) — verdict mapping (GDD §4.7 exact):
  - "파기" if match AND final_score ≥ 0.7
  - "파기환송" if match AND final_score ≥ 0.3 (and < 0.7)
  - "기각" if NOT match AND final_score ≥ 0.3
  - "각하" if final_score < 0.3 (regardless of match)
- [ ] AC-19 (review BLOCKING #3) — every verdict value is reachable; deterministic boundary at exact thresholds

## Implementation Notes
Per GDD §4.7: pure function using `verdict_threshold_pagi`/`verdict_threshold_low` (story 001 loaded). Boundary: ≥ is inclusive. 파기환송·기각 share low=0.3, branch on disposition match.

## Out of Scope
- Story 002 (produces final_score), 005 (comments)

## QA Test Cases
- match+0.7→파기; match+0.69→파기환송; match+0.3→파기환송; match+0.29→각하; mismatch+0.3→기각; mismatch+0.29→각하; mismatch+0.7→기각 (mismatch never 파기). Exact-threshold boundaries deterministic.

## Test Evidence
**Story Type**: Logic | **Required**: `tests/unit/submission_evaluation/verdict_test.gd`
**Status**: [ ] Not yet created

## Dependencies
- Depends on: Story 001 (thresholds), Story 002 (final_score)
- Unlocks: 004 (REPORTING populates verdict)

## Completion Notes
**Completed**: 2026-05-23. 2/2 ACs. EvaluationService.determine_verdict — 파기(match&≥0.7)/파기환송(match&≥0.3)/기각(!match&≥0.3)/각하(<0.3); all 4 reachable; exact-threshold boundaries deterministic; mismatch never 파기. Tests: verdict_test.gd 8/8. Reviewed by orchestrator.
