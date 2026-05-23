# Story 012: Edge cases + performance gates

> **Epic**: Reasoning Workspace
> **Status**: Complete (tree-structural subset, 2026-05-23) / feature & service-dependent ECs + perf gate skip-stubbed pending owning stories
> **Layer**: Feature (Gameplay)
> **Type**: Logic + Visual/Feel (Logic primary)
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§5 Edge Cases — 24 ECs across 7 categories, §10.9 Performance, §10.10 Pillar Compliance Verification, §10.12 Untestable AC Open Questions)
**Requirement**: TR-WORKSPACE-LAYOUT-001 (edge cases + performance gate cross-cover all 5 TRs)

**ADR Governing Implementation**: ADR-0008 §6 Implementation Guidelines + ADR-0008 amend-1 §A6 (forbidden chain_data ephemeral field) + ADR-0010 R6 (class_name collision smoke test) + ADR-0010 KrCustomControl performance budget
**ADR Decision Summary**: Comprehensive edge case coverage of 24 ECs across 7 GDD §5 categories. Performance gate AC-49: 60fps with 5 root × 3 deep × 5 evidence (max MVP tree shape). Pillar compliance fuzz tests (AC-52 from story 002 cross-link). Untestable AC OQ-QA-1/2 disposition documentation.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: gdunit4 v5.0+ skip API uses function-signature parameter pattern (`_do_skip := true, _skip_reason := "..."`) per `.claude/docs/technical-preferences.md`. AC-49 stub test uses skip pattern for headless instantiation if blocked.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.9 Performance (AC-49) + §10.10 Pillar Compliance + §5 24 EC coverage.

> **Tree-structural subset DONE (2026-05-23)**: ECs testable against existing WorkspaceData (no new services) are implemented + passing. Feature/service-dependent ECs are skip-stubbed (gdunit4 `_do_skip` parameter pattern) pending their owning stories (004 drag-drop, 008 crash-recovery, SaveLoadService, SettingsService, UIService.announce_text, UI Foundation, VR-D7 IME). Perf gate AC-49/49b skip-stubbed pending OQ-W10 headless Control ratify. See Completion Notes.

### 24 GDD §5 Edge Cases

- [x] EC-1 — Empty tree → chain_data empty arrays, no errors (cross-link AC-23) — **DONE** (`edge_cases_test.gd`)
- [x] EC-2 — Single root, single evidence → chain_data with 1 node + 1 evidence + 0 edges — **DONE**
- [x] EC-3 — Max tree builds + serializes correctly (3 root × 2-branch × depth-3 × 5 ev = 45 nodes / 225 evidence; JSON round-trip) — **DONE** (story's "~117" was approximate; actual MVP-shape count asserted)
- [x] EC-4 — Attempted depth-4 → rejected (cross-link AC-12) — **DONE**
- [x] EC-5 — Cycle attempt → rejected (cross-link AC-13) — **DONE**
- [ ] EC-6 — Duplicate evidence drop on same node → silent dedupe (no double-add)
- [ ] EC-7 — Drop non-existent library_id (LibraryService validates) → reject + announce
- [ ] EC-8 — Drop on non-ACTIVE state → rejected (cross-link AC-28 state guard)
- [ ] EC-9 — Window resize mid-drag → drag continues, drop region updates
- [ ] EC-10 — State transition during pending citation → pending auto-cancels (story 004 covers ACTIVE→FROZEN)
- [ ] EC-11 — Load corrupted active_case.tres → .backup recovery (cross-link AC-27f story 008)
- [x] EC-12 — Memo char input exactly at cap (500) → no truncation — **DONE** (ASCII + Hangul codepoint variants)
- [x] EC-13 — Memo char input 501 → truncated to 500 (+ `memo_truncated` signal) — **DONE** (announce part deferred — UIService.announce_text not impl)
- [ ] EC-14 — Korean IME composition mid-character at cap boundary → defer truncation per amend-4 §F3 (VR-D7 dependent)
- [ ] EC-15 — Memo focus loss mid-IME → composition committed first then focus lost (Godot 4.6 default)
- [x] EC-16 — Pillar 1 — memo body in chain_data export attempt → rejected (cross-link AC-10, AC-52) — **DONE**
- [x] EC-17 — Pillar 1 — settings value in chain_data → rejected by allow-list validator (ADR-0009 settings_in_chain_data intent) — **DONE**
- [ ] EC-18 — Workspace-Browser boundary — WorkspaceData reference held after case unload → boundary violation logged
- [ ] EC-19 — Drag from LibraryPane while Browser scene swapping → drag cancelled cleanly
- [ ] EC-20 — Auto-resubmit cascade with mismatched schema_version → CriticalBanner + reset (cross-link AC-27f)
- [ ] EC-21 — Camera2D pan at clamp boundary → smooth halt (no jitter)
- [ ] EC-22 — Gamepad two-step with state transition mid-process → pending citation auto-clear on FROZEN
- [ ] EC-23 — Focus loss to off-window → focus restored to last node on window refocus
- [ ] EC-24 — Multiple simultaneous SettingsService changes (text_scale + reduced_motion together) → both apply correctly (no race)

### Performance Gate

- [ ] AC-49 — 60fps with worst-case MVP tree (5 root × 3 deep × 5 evidence per node ≈ 117 nodes) on 1366×768 — stub test until Godot 4.6 headless Control class confirmed (per OQ-QA-2 cycle 5 Tier S-1 closure — gdunit4 v5.x skip API parameter pattern `_do_skip := true, _skip_reason := "VR pending"`)
- [ ] AC-49b — Memory peak < 2GB working set (per technical-preferences.md performance budget) with worst-case tree

### Pillar Compliance Fuzz

- [x] AC-52 cross-link — 5 forbidden field names fuzz (re-validated as suite test) — **DONE**
- [x] AC-52b — Settings inclusion fuzz: 5 settings keys injected into chain_data node → all rejected by allow-list validator — **DONE**

### Untestable AC Disposition

- [ ] OQ-QA-1 disposition documented: AC-46 (gamepad CitationDrop) remains ADVISORY until UI Foundation epic OQ-W9 prototype ratify
- [ ] OQ-QA-2 disposition documented: AC-49 stub uses gdunit4 v5.x skip pattern with `_skip_reason = "VR pending OQ-W10 ratify"` until headless Control instantiation confirmed

---

## Implementation Notes

Per ADR-0008 §6 + gdunit4 v5.x skip API:

```gdscript
# tests/unit/workspace/edge_cases_test.gd
extends GdUnitTestSuite

# 24 ECs as individual test functions for clarity

func test_ec_3_max_tree_serializes(_do_skip := false, _skip_reason := ""):
    var ws := WorkspaceData.new()
    # build 5 × 3 × 5 tree
    var cd := ws.build_chain_data()
    assert_int(cd.nodes.size()).is_equal(117)   # 5 roots + 5*5 depth1 + 5*5*5 depth2 — adjust per actual cap
    assert_int(cd.total_evidence_count).is_equal(117 * 5)   # 5 evidence per node

# AC-49 stub — gdunit4 skip parameter pattern (NOT skip() imperative call)
func test_ac_49_60fps_worst_case_tree(_do_skip := true, _skip_reason := "VR pending OQ-W10 ratify — headless Control instantiation"):
    # When unskipped at impl time:
    var fps := await _measure_fps_for_seconds(3.0, _build_worst_case_tree())
    assert_float(fps).is_greater_equal(60.0)

func test_ec_17_settings_in_chain_data_rejected(_do_skip := false, _skip_reason := ""):
    var cd := {"nodes": [{"node_id": "n1", "label": "x", "parent_id": "", "evidence": [], "depth": 0, "child_count": 0, "evidence_count": 0, "display.text_scale": 1.0}]}
    assert_bool(WorkspaceData.new().validate_chain_data(cd)).is_false()
```

- 24 ECs grouped by GDD §5 sub-category — keep individual test functions per EC for clear failure isolation (one function = one scenario per `/architecture-review` standards)
- AC-49 stub uses gdunit4 v5.x function-signature parameter skip pattern (NOT imperative `skip("reason")` — that's the C# variant per technical-preferences.md Allowed Libraries gdunit4 entry)
- AC-49 unblock condition: OQ-W10 (tree canvas panning Control class decision) ratified at Workspace Layout ADR (covered by ADR-0008 §4 + §6.4) → headless Control instantiation possible → stub becomes real measurement
- Settings inclusion fuzz uses ADR-0009 forbidden_pattern `settings_in_chain_data` — story 012 validates the validator's coverage of settings keys (chain_data validator from story 002 + ADR-0009 settings forbidden_pattern intersection)

---

## Out of Scope

- Per-feature edge cases already handled within their story (cycle detection AC-13 in story 003, drop cap AC-30 in story 004, etc.) — this story is the *catch-all suite* covering ECs not explicitly tested in feature stories
- ADR-0011 SaveLoadService crash recovery (story 008 covers Workspace-side; ADR-0011 owns the cascade)
- ADR-0010 R6 KrCustomControl class_name uniqueness (VR-UI5 — separate UI Foundation epic concern)
- VR-D7 cross-platform Korean IME runtime (EC-14 dependency — non-blocking; story 012 marks EC-14 as `_do_skip` if VR-D7 not yet PASS)

---

## QA Test Cases

- **24 ECs Logic**: One gdunit4 test function per EC; assertions per EC's expected behavior (rejection / no-op / specific cascade)
- **AC-49 Logic (stubbed)**: skip parameter pattern with reason until OQ-QA-2 unblocks
- **AC-49b Logic**: Memory profiler integration — measure working set after building worst-case tree → assert < 2GB
- **AC-52 cross-link**: Story 002's fuzz test sufficient; story 012 adds AC-52b settings fuzz as separate suite entry
- **OQ-QA-1/2 Manual**: Document disposition in `production/qa/evidence/workspace-untestable-ac-disposition.md` — cross-ref to OQ-W9 / OQ-W10 ratify cycle

Edge cases at edge cases (meta): EC test failures during CI → fail entire workspace test suite (24 ECs are atomic).

---

## Test Evidence

**Story Type**: Logic + Visual/Feel
**Required**:
- `tests/unit/workspace/edge_cases_test.gd` — 24 ECs + AC-52b settings fuzz (gdunit4)
- `tests/unit/workspace/performance_test.gd` — AC-49 stub + AC-49b memory measurement (gdunit4)
- `production/qa/evidence/workspace-untestable-ac-disposition.md` — OQ-QA-1/2 disposition log

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-011 (this story's ECs cross-link to all prior story behaviors; runs last as integration safety net)
- Unlocks: Workspace epic Definition of Done — all stories closed + this suite passes

---

## Completion Notes
**Completed**: 2026-05-23 (tree-structural subset)
**Criteria**: 11/26 implemented + passing (EC-1/2/3/4/5/12/13/16/17 + AC-52 + AC-52b). 15 ECs + AC-49/49b skip-stubbed (gdunit4 `_do_skip` parameter pattern) — each names its blocking owner story. OQ-QA-1/2 manual disposition doc deferred.
**Scope split rationale**: This story is the epic's catch-all safety net intended to run last (depends on 001-011). Stories 004/005/006/008/009/010/011 + SaveLoadService/EvaluationService/SettingsService/UIService.announce_text are not yet implemented. The tree-structural / chain_data-validation ECs are testable NOW against the completed data layer (001/002/003a/007) with no new services — implemented as a regression safety net for that layer; the rest are skip-stubbed and unblock incrementally as their owning stories land. Mirrors story-007 data-layer split precedent.
**Files**:
- `tests/unit/workspace/edge_cases_test.gd` (28 functions: 13 real executed + 15 skip-stubs) — EC suite + AC-52/52b fuzz
- `tests/unit/workspace/performance_test.gd` (2 skip-stubs: AC-49 fps, AC-49b memory)
**No production code changed** — verification-only story against existing WorkspaceData. No production bug found during authoring.
**Test Evidence**: workspace suite 128 cases / 111 executed / 17 skipped / 0 failures, exit 0 (independently re-run).
**Code Review**: Complete (godot-gdscript-specialist, 2026-05-23). Verdict MINOR ISSUES → all resolved: `_data_with_nodes` param typed `Array[HypothesisNodeData]`; redundant EC-1 assertion removed; EC-3 round-trip + timestamp-key survival assertion; AC-49b skip reason corrected (API is ADR-0007-sanctioned; true blocker = hollow data-only guard + OQ-W10).
**Deferred (re-open when owning story lands)**: EC-6/8/9/10/22 (story 004 drag-drop), EC-7 (LibraryService + announce), EC-11/20 (SaveLoadService + story 008), EC-14/15 (VR-D7 IME), EC-18/19 (Case Browser), EC-21/23 (UI camera/focus), EC-24 (SettingsService), AC-49/49b (OQ-W10 headless Control), OQ-QA-1/2 (manual disposition doc).

---

## Notes

This story acts as the Workspace epic's safety net. Failures here indicate a regression in one of stories 001-011 — fix the originating story before adjusting EC test. The EC suite is *atomic* (single CI run, all-or-nothing) to catch silent regressions across feature stories.
