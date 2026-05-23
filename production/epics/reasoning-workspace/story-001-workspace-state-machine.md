# Story 001: WorkspaceData Resource + 4-state machine

> **Epic**: Reasoning Workspace
> **Status**: Complete
> **Layer**: Feature (Gameplay)
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimate**: 3 hours (M) — single Resource class + 4-state enum + 3 transition functions + 7 AC unit tests
> **Performance**: No expected impact — state transitions are event-driven (signal-emit only, not `_process`/`_physics_process`); called < 10x per session (case start, freeze, evaluation arrival). No frame budget allocation needed.
> **Completed**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.2 States and Transitions, §10.3 State Machine)
**Requirement**: `TR-WORKSPACE-LAYOUT-001`
*(Requirement text in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: ADR-0008 Workspace Layout (Accepted 2026-05-17)
**ADR Decision Summary**: DeskPane Control hierarchy + WorkspaceData Resource owns the 4-state machine (INACTIVE / ACTIVE / FROZEN / READ_ONLY). State mutation only via typed signal cascades.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Resource class + Variant primitives in storage fields (per ADR-0007 amend-1). No post-cutoff API specifics required for state machine itself.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.3 State Machine (AC-17 ~ AC-23).

- [ ] AC-17 — Initial state INACTIVE on case load; ACTIVE on first DeskPane interaction (first root added or first drag-drop)
- [ ] AC-18 — ACTIVE → FROZEN only via explicit submit() call; FROZEN state irreversible within the same session except via crash recovery cascade
- [ ] AC-19 — FROZEN → READ_ONLY on EvaluationResult arrival; tree visible, no mutations possible
- [ ] AC-20 — All state transitions emit `workspace_state_changed(old, new)` typed signal
- [ ] AC-21 — Direct `WorkspaceData.state = X` assignment (bypassing transition functions) is forbidden — only `_transition_to_active()` / `_transition_to_frozen()` / `_transition_to_read_only()` allowed
- [ ] AC-22 — Crash recovery: SaveLoadService re-instantiates WorkspaceData with persisted state on session resume
- [ ] AC-23 — INACTIVE state allows no chain_data export (returns empty Dictionary)

---

## Implementation Notes

Per ADR-0008 §1 + ADR-0001 amend-2 lifecycle:

- `WorkspaceData extends Resource` — fields: `state: WorkspaceState` enum, `nodes: Array[HypothesisNodeData]`, `pending_citation: String`, `chain_data_snapshot: Dictionary` (built at freeze)
- WorkspaceState enum: `INACTIVE = 0`, `ACTIVE = 1`, `FROZEN = 2`, `READ_ONLY = 3`
- Transition functions are *only* public state-change API. Assert legal transition graph: INACTIVE→ACTIVE, ACTIVE→FROZEN, FROZEN→READ_ONLY (other transitions: push_error + no change).
- Typed signal: `signal workspace_state_changed(old: int, new: int)` on WorkspaceData. Subscribers (SaveLoadService FIFTH per ADR-0011, BriefEditor for FROZEN handoff per ADR-0001 amend-2) connect via `WorkspaceData.workspace_state_changed.connect(_on_state_changed)`.
- ADR-0008 amend-3 §E1 — drop target state guard scope: DeskPane drop only blocked in non-ACTIVE; Brief Editor CitationPanel uses independent guard.

---

## Out of Scope

- Story 002: chain_data Variant-only schema + derivation formulas (this story only defines `chain_data_snapshot: Dictionary` field, not builders)
- Story 003: HypothesisNode KrCard subclass (this story defines `HypothesisNodeData` Resource only)
- Story 007: Freeze + submit cascade (this story defines `_transition_to_frozen()` skeleton only)
- Story 008: Crash recovery cascade implementation (this story only verifies state can be restored from persisted Resource)

---

## QA Test Cases

- **AC-17**: Given new case load, when WorkspaceData instantiated, then `state == INACTIVE` and `add_first_node()` transitions to ACTIVE
- **AC-18**: Given ACTIVE, when `_transition_to_frozen()` called, then state=FROZEN and signal emitted; subsequent `_transition_to_*` calls assert legal-only
- **AC-19**: Given FROZEN, when EvaluationResult arrives via signal, then `_transition_to_read_only()` fires and state=READ_ONLY
- **AC-20**: Connect test listener to `workspace_state_changed`; verify emission on every legal transition with correct (old, new) args
- **AC-21**: Direct `workspace_data.state = WorkspaceState.FROZEN` assignment must `push_error` and revert (or guard via private setter)
- **AC-22**: Save WorkspaceData to .tres → load → verify state field preserved
- **AC-23**: Given INACTIVE, when `build_chain_data()` called, then returns `{}` (empty Dict)

Edge cases: invalid transitions (READ_ONLY → ACTIVE), null state, missing nodes array on instantiation.

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/workspace/workspace_state_machine_test.gd` — must exist and pass (gdunit4)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Stories 002, 003, 007, 008

---

## Completion Notes

**Completed**: 2026-05-18
**Criteria**: 7/7 passing (AC-17 / AC-18 / AC-19 / AC-20 / AC-21 / AC-22 / AC-23 — all auto-verified via 27/27 gdunit4 PASS, 187ms)

**Files delivered**:
- `src/data/workspace_data.gd` (8.2KB → ~8.6KB post-fix) — `class_name WorkspaceData extends Resource` + 4-state enum + private `_state` + read-only public `state` property (Option C guard with push_error setter) + 3 transition functions (`_transition_to_active` / `_to_frozen` / `_to_read_only`) + `add_first_root_node` with null + FROZEN/READ_ONLY guards + `build_chain_data` stub + `workspace_state_changed(old: int, new: int)` typed signal
- `src/data/hypothesis_node_data.gd` (1.3KB) — minimal Resource scaffold (5 @export fields; full structure deferred to story 003)
- `tests/unit/workspace/workspace_state_machine_test.gd` (~18KB) — 27 test functions covering 7 AC + edge cases + 6 regression guards

**Test evidence**: `tests/unit/workspace/workspace_state_machine_test.gd` — 27/27 PASS via `bash addons/gdUnit4/runtest.sh --godot_binary $(which godot) -a tests/unit/workspace/workspace_state_machine_test.gd` (gdunit4 v5.x, Godot 4.6.1.stable.official.14d19694e, 187ms)

**Deviations**: None (all out-of-scope items deferred to declared follow-up stories — chain_data builder to story 002, full HypothesisNode invariants to story 003, freeze cascade to story 007, crash recovery cascade to story 008)

**Scope**: All changes within stated boundary (src/data/ + tests/unit/workspace/). 0 files outside scope touched.

**Code review** (lean mode):
- godot-gdscript-specialist: workspace_data.gd MINOR ISSUES → CLEAN post-fix (W1 assert→push_error / W2 add guard / W3 keys()→find_key) / hypothesis_node_data.gd CLEAN / test file MINOR → CLEAN post-fix (W4 typed Array[Array])
- qa-tester: GAPS (1 BUG-CANDIDATE + 4 WARNING + 2 NICE-TO-HAVE) → 6 fixes in-pass; AC-19 mutation guard added to `add_first_root_node` closing data-layer behavioral gap; 6 regression tests added (FROZEN/READ_ONLY append rejection + null guard + direct assignment from FROZEN/READ_ONLY + READ_ONLY chain_data return)

**Deferred (acknowledged out-of-scope, NICE-TO-HAVE)**:
- Test naming convention `test_workspace_data_*` prefix (cosmetic, gdunit4 미 enforce)
- AC-21 out-of-range int assignment test (setter always rejects regardless of value)
- I4 reflection bypass via `Object.set("_state", ...)` — Option C inherent 한계, ADR-acknowledged
- Test file release-stale check — release builds strip `assert` but story 001 uses `push_error` exclusively (post-W1 fix)

**Unlocks**:
- Story 002 chain_data Variant-only schema + 5 derivation formulas + BFS canonical ordering (next ready story — depends only on story 001 WorkspaceData Resource definition)
- Story 003 HypothesisNode KrCard subclass + tree construction (depends on story 001 HypothesisNodeData scaffold)
- Story 007 Freeze + submit cascade (depends on story 001 state machine + story 002 chain_data builder)
- Story 008 READ_ONLY + crash recovery (depends on story 001 + story 007)
