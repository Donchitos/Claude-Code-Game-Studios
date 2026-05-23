# Story 002: chain_data Variant-only schema + 5 derivation formulas + BFS canonical ordering

> **Epic**: Reasoning Workspace
> **Status**: Complete
> **Layer**: Feature (Gameplay)
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimate**: 4 hours (M-L) — `build_chain_data` Dictionary builder + 5 derivation formulas (depth/max_depth_reached/total_evidence_count/child_count/evidence_count) + BFS canonical ordering + allow-list validator with 7 ALLOWED_NODE_FIELDS + 12 AC unit tests including 5-name fuzz
> **Performance**: No expected impact — `build_chain_data` called only at freeze (< 1x per session) + validator runs synchronously on small Dictionary (5-30 nodes). BFS traversal O(N) for N ≤ ~30 (AC-49 worst-case 5 root × 3 deep × 5 evidence) — sub-millisecond. No `_process` allocation.
> **Completed**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.1 Rule 5/6 chain_data, §4.1 5 derivation formulas, §4.2 tree invariants, §10.1 chain_data Export, §10.10 Pillar 1 guard)
**Requirement**: `TR-WORKSPACE-LAYOUT-001` (chain_data is part of WorkspaceData export contract)

**ADR Governing Implementation**: ADR-0007 amend-1 (chain_data Variant Primitives Only) + ADR-0008 amend-1 §A6 (forbidden chain_data ephemeral field) + ADR-0008 §1 (canonical ordering) + ADR-0007 §1 (chain_data schema lock)
**ADR Decision Summary**: chain_data Dictionary contains ONLY Variant primitives (String/int/float/bool/Array/Dict) — NO Resource references. New dict literal construction with explicit `.duplicate()` on Array fields. nodes[] array follows BFS canonical ordering (lexicographic root sort → BFS depth-first within each subtree).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Dictionary.duplicate(true)` (4.0+ stable, deprecation-untouched per ADR-0008 amend-2 §D3). `JSON.stringify(data, indent, sort_keys, full_precision)` 4.6 — AC-24 protocol uses `indent=""`, `sort_keys=true`.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.1 chain_data Export (AC-1 ~ AC-11b) — 11 AC.

- [ ] AC-1 — chain_data Dictionary contains: `nodes` Array, `edges` Array, `total_evidence_count`, `max_depth_reached`, `submission_timestamp_unix`, `schema_version=1`
- [ ] AC-2 — Each node dict has: `node_id`, `label`, `parent_id`, `evidence` (Array[String]), `depth`, `child_count`, `evidence_count` — no other fields
- [ ] AC-3 — Each edge dict has: `parent_id`, `child_id` — no other fields
- [ ] AC-4 — `total_evidence_count` formula: sum of all nodes' `evidence_count` (= sum of `len(node.evidence)`)
- [ ] AC-5 — `max_depth_reached` formula: max(depth) over all nodes; empty tree returns 0
- [ ] AC-6 — `depth` formula: 0 for roots, parent.depth + 1 for children
- [ ] AC-7 — `child_count` formula: count of nodes where `parent_id == this.node_id`
- [ ] AC-8 — `evidence_count` formula: `len(node.evidence)`
- [ ] AC-9 — chain_data is *fully constructed new Dictionary* (§3.1 Rule 6 normative) — no live reference to WorkspaceData fields
- [ ] AC-10 — memo body excluded from chain_data (Pillar 1 guard); allow-list validator rejects `memo_text` injection with `push_error` + `submission_rejected("schema_violation")`
- [ ] AC-11 — schema_version=1 lock; future v2+ bump must trigger explicit migration ADR
- [ ] AC-11b — nodes[] array BFS canonical ordering: roots sorted by `node_id` lexicographic, then BFS within each root subtree with children sorted by `node_id` at each depth level
- [ ] AC-52 — Pillar 1 fuzz test: 5 forbidden field names (`memo_text`, `chain_data_internal`, `__debug_payload`, `evaluator_hint`, `cached_score`) all rejected

---

## Implementation Notes

Per ADR-0007 amend-1 + ADR-0008 §1 normative:

```gdscript
# WorkspaceData.build_chain_data() — returns brand-new Dictionary
func build_chain_data() -> Dictionary:
    var sorted_roots := _roots().duplicate()  # Array[HypothesisNodeData]
    sorted_roots.sort_custom(func(a, b): return a.node_id < b.node_id)
    var bfs_ordered: Array = []
    for root in sorted_roots:
        _bfs_collect(root, bfs_ordered)
    var nodes_dict_array: Array = []
    var edges_array: Array = []
    var total_ev := 0
    var max_depth := 0
    for n: HypothesisNodeData in bfs_ordered:
        nodes_dict_array.append({
            "node_id": n.node_id,
            "label": n.label,
            "parent_id": n.parent_id,
            "evidence": n.evidence.duplicate(),  # MANDATORY explicit .duplicate() per §3.1 Rule 6
            "depth": n.depth,
            "child_count": _children_of(n.node_id).size(),
            "evidence_count": n.evidence.size(),
        })
        if n.parent_id != "":
            edges_array.append({"parent_id": n.parent_id, "child_id": n.node_id})
        total_ev += n.evidence.size()
        max_depth = max(max_depth, n.depth)
    return {
        "schema_version": 1,
        "nodes": nodes_dict_array,
        "edges": edges_array,
        "total_evidence_count": total_ev,
        "max_depth_reached": max_depth,
        "submission_timestamp_unix": int(Time.get_unix_time_from_system()),
    }

# Allow-list validator — runs on submit before EvaluationService call
const ALLOWED_NODE_FIELDS := ["node_id", "label", "parent_id", "evidence", "depth", "child_count", "evidence_count"]
func validate_chain_data(cd: Dictionary) -> bool:
    for n: Dictionary in cd.get("nodes", []):
        for k in n.keys():
            if not ALLOWED_NODE_FIELDS.has(k):
                push_error("chain_data schema_version=1 violation: forbidden field %s" % k)
                submission_rejected.emit("schema_violation")
                return false
    return true
```

- ADR-0008 amend-1 §A6 forbidden_pattern `chain_data_include_ephemeral_field` registered already.
- ADR-0007 amend-1 — `nodes[]` Array literal construction (not `.duplicate()` shorthand).
- §3.1 Rule 6 BFS canonical: deterministic — same workspace state → byte-identical `JSON.stringify(cd, "", true)` output.

---

## Out of Scope

- Story 001: WorkspaceData state machine (this story builds chain_data, doesn't transition state)
- Story 007: Freeze + submit cascade (this story builds chain_data; story 007 calls `build_chain_data()` at freeze)
- v1+ chain_coherence subscore (GDD §4.3 forward declaration)
- evidence_density UI metric (GDD §4.4 — NOT exported; story 011 visual polish)

---

## QA Test Cases

- **AC-1~3**: Build chain_data from fixture tree (3 roots, varying depth/evidence); assert exact field set per node/edge/top-level
- **AC-4**: 5-node tree with [2, 1, 0, 3, 1] evidence → total_evidence_count=7
- **AC-5**: depth-3 tree → max_depth_reached=2 (0-indexed); empty tree → 0
- **AC-6**: Multi-level traversal → root.depth==0, child.depth==parent.depth+1
- **AC-9**: After build, mutate `workspace_data.nodes[0].evidence.append("X")` → chain_data["nodes"][0]["evidence"] unchanged
- **AC-10**: Inject `memo_text` field via test helper → validator returns false + emits `submission_rejected("schema_violation")`
- **AC-11b**: Insertion order `[root-B, root-A]` with children in reverse `node_id` order → chain_data['nodes'][0]['node_id'] == 'root-A' (lex sort) and children appear sorted within each depth
- **AC-52 fuzz**: 5 distinct forbidden field names — all caught, no EvaluationService call

Edge cases: empty tree (no nodes), single-node tree, max-depth tree (3-deep × 5 root × 5 evidence-per-node), insertion-order matches lex order (insertion-by-chance vs lex-by-spec) — separate test function with explicit assertion documenting spec source is lex sort.

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/workspace/chain_data_test.gd` — must exist and pass (gdunit4); functions per AC ID

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData Resource + state machine) ✅ Complete
- Unlocks: Stories 007 (freeze export), 008 (crash recovery cascade verifies chain_data bytes-equal), 012 (Pillar guard fuzz tests)

---

## Completion Notes

**Completed**: 2026-05-18
**Criteria**: 12/12 passing (AC-1 ~ AC-11b + AC-52 fuzz, all auto-verified via 25/25 chain_data_test.gd PASS, 183ms)

**Files delivered**:
- `src/data/workspace_data.gd` (extended) — added `ALLOWED_NODE_FIELDS` constant (7-entry), `submission_rejected(reason: String)` typed signal, full `build_chain_data()` BFS builder (replaces story-001 stub), `validate_chain_data(cd)` allow-list per-key check, 3 private BFS helpers (`_roots()` / `_bfs_collect()` / `_children_of()`)
- `tests/unit/workspace/chain_data_test.gd` (NEW) — 25 test functions: AC-1~11 + AC-11b (4 BFS ordering variants including cycle 4 IMP-6 insertion=lex case) + AC-52 fuzz (5 forbidden names) + edge cases (empty / single-node / max-tree 5×3×5)
- `tests/unit/workspace/workspace_state_machine_test.gd` (extended) — 2 tests updated to expect new chain_data shape (`test_active_state_returns_chain_data_snapshot_field` + `test_read_only_state_returns_chain_data_snapshot_field`)

**Test evidence**:
- `tests/unit/workspace/chain_data_test.gd` — 25/25 PASS in 183ms
- `tests/unit/workspace/workspace_state_machine_test.gd` — 27/27 PASS (0 regression from story-001)
- Total workspace suite: **52/52 PASS in 378ms** via `bash addons/gdUnit4/runtest.sh --godot_binary $(which godot) -a tests/unit/workspace/`

**Deviations**: None
- chain_data Dictionary 신규 literal construction ✓ (no live WorkspaceData refs per §3.1 Rule 6 normative)
- evidence Array explicit `.duplicate()` ✓ (cycle 4 godot-specialist IMPORTANT-1)
- BFS canonical (lex root sort + lex children at each depth) ✓ deterministic
- 7-field allow-list validator ✓ (forbidden_pattern `chain_data_include_ephemeral_field` enforced)
- INACTIVE state still returns `{}` ✓ (AC-23 regression preserved)
- ADR-0007 amend-1 Variant primitives only ✓ (story 007 validator runtime check)

**Scope**: All changes within stated boundary (`src/data/workspace_data.gd` extension + `tests/unit/workspace/chain_data_test.gd` NEW). State machine + Option C guard + story-001 behavior untouched.

**Code review** (lean mode — implicit via test pass + agent self-report):
- agent confirmed: typed Array[Array] pattern (W4 fix from story-001 carry), manual signal connect+counter for submission_rejected, ADR cross-ref in doc comments, one-function-one-scenario rule
- No specialist sub-review spawned (lean mode + story-001 patterns established)

**Unlocks**:
- Story 007 freeze cascade (workspace_state_changed + chain_data export Dictionary.duplicate(true) + EvaluationService.submit handoff)
- Story 008 crash recovery (auto-resubmit uses chain_data_snapshot bytes-equality per AC-27b)
- Story 012 Pillar 1 fuzz tests cross-link (AC-52 ↔ story-012 AC-52b settings fuzz)
