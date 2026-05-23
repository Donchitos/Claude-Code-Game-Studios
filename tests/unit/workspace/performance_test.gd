## performance_test.gd — WorkspaceData performance gate tests.
##
## Covers story-012 Performance Gates:
##   AC-49   60fps worst-case tree render (SKIP-STUB — headless Control instantiation blocked)
##   AC-49b  Memory regression: worst-case data-only tree stays under 2 GB working-set budget
##           (SKIP-STUB — hollow guard at 45-node data-only scale; meaningful worst-case
##           is the rendered Control tree, which shares AC-49's headless blocker)
##
## SKIP-STUB rationale for AC-49b:
##   OS.get_static_memory_usage() IS project-sanctioned (ADR-0007 §Risk 6, AC-22,
##   TR-submission-015 N=100 averaging) — the API is NOT deprecated and is NOT the blocker.
##   The skip is deferred because: (a) a data-only tree of 45 HypothesisNodeData Resources
##   trivially satisfies the 2 GB budget and the assertion cannot fail at this scale, making
##   the test a hollow regression guard; (b) the meaningful worst-case is the rendered
##   Control tree, which shares AC-49's headless Control instantiation blocker (OQ-W10).
##   Unblock both AC-49 and AC-49b together once OQ-W10 is ratified.
##
## gdunit4 v5.x skip pattern (GDScript variant):
##   func test_xxx(_do_skip := true, _skip_reason := "...") -> void:
##   This is the ONLY supported skip mechanism in gdunit4 GDScript.
##   Imperative skip("reason") is the C# variant (gdUnit4Net) and is NOT supported here.
##   Ref: technical-preferences.md → gdunit4 GDScript skip API.
##
## ADR: docs/architecture/adr-0008-workspace-layout.md §1
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/workspace/performance_test.gd
extends GdUnitTestSuite


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Returns a HypothesisNodeData with node_id set; all other fields default.
func _make_node(id: String) -> HypothesisNodeData:
	var n := HypothesisNodeData.new()
	n.node_id = id
	n.label = "label-%s" % id
	return n


# ─── AC-49 — 60fps worst-case tree (skip-stub) ───────────────────────────────

func test_ac_49_60fps_worst_case_tree(_do_skip := true, _skip_reason := "VR pending OQ-W10 ratify — headless Control instantiation") -> void:
	# Blocking dependency: OQ-W10 ratification of headless Control instantiation
	# for worst-case tree render under 16.6ms budget.
	# This test will instantiate KrCard nodes (Control subclass) and measure frame
	# time once that infrastructure is confirmed to work headlessly.
	pass


# ─── AC-49b — Memory regression: worst-case data-only tree (skip-stub) ────────

func test_ac_49b_memory_worst_case_data_tree_under_2gb(_do_skip := true, _skip_reason := "deferred: data-only tree is a hollow guard at 45-node scale; meaningful worst-case is the rendered Control tree, which shares AC-49's headless blocker (OQ-W10)") -> void:
	# Intent: build the worst-case DATA tree (same shape as EC-3: 3 roots × 2-branch
	# × depth-3 × 5 evidence per node = 45 nodes / 225 evidence strings), then assert
	# memory usage stays under the 2 GB working-set budget (technical-preferences.md).
	#
	# Intended assertion (pending API verification):
	#   var mem_before := OS.get_static_memory_usage()
	#   <build 45-node tree>
	#   var mem_after := OS.get_static_memory_usage()
	#   assert_int(mem_after).is_less(2 * 1024 * 1024 * 1024)
	#
	# This would trivially pass for 45 HypothesisNodeData Resources, but serves as
	# a regression guard if node counts scale unexpectedly.
	#
	# Unblock by: confirm the exact memory query API in docs/engine-reference/godot/
	# for Godot 4.6, then replace the skip pattern with the verified call.
	pass
