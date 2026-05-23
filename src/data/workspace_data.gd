## WorkspaceData — Persistent Resource for the Reasoning Workspace state machine.
##
## Owns the 4-state lifecycle (INACTIVE → ACTIVE → FROZEN → READ_ONLY) and all
## workspace-scoped fields that must survive session save/load.
##
## AC-21 guard design (Option C):
##   [code]_state[/code] is a private backing variable written only by the three
##   transition functions. The public [code]state[/code] property exposes a getter
##   (read-only in practice) and a setter that calls [code]push_error[/code] and
##   returns without mutation — direct assignment is rejected at runtime with an
##   error message, leaving state unchanged.
##
## Legal transition graph:
##   INACTIVE → ACTIVE      via [method _transition_to_active]
##   ACTIVE   → FROZEN      via [method _transition_to_frozen]
##   FROZEN   → READ_ONLY   via [method _transition_to_read_only]
##   All other transitions: [code]push_error[/code] + no state change.
##
## Story 002 additions:
##   [method build_chain_data] now builds a fully-constructed new Dictionary from
##   the current [member nodes] array using BFS canonical ordering (lex root sort +
##   BFS depth traversal with lex child sort). 5 derivation formulas:
##   depth / max_depth_reached / total_evidence_count / child_count / evidence_count.
##   [method validate_chain_data] enforces the 7-field allow-list per ADR-0007 amend-1.
##   [signal submission_rejected] emitted on schema_violation.
##
##   Freeze cascade (chain_data_snapshot population on FROZEN) → story 007.
##   Crash recovery cascade integration → story 008.
##
## ADR: docs/architecture/adr-0007-amend-1-chain-data-primitive-only.md
##      docs/architecture/adr-0008-workspace-layout.md §1 + amend-1 §A5/§A6
## TR:  TR-WORKSPACE-LAYOUT-001
class_name WorkspaceData extends Resource


# ─── Enum ─────────────────────────────────────────────────────────────────────

## The four lifecycle states of the Reasoning Workspace.
##
## INACTIVE   — case loaded, no player interaction yet.
## ACTIVE     — player has interacted (first node added or first citation drop).
## FROZEN     — player submitted; tree is locked, awaiting evaluation.
## READ_ONLY  — EvaluationResult received; tree visible, no mutations possible.
enum WorkspaceState {
	INACTIVE = 0,
	ACTIVE = 1,
	FROZEN = 2,
	READ_ONLY = 3,
}


# ─── Constants ────────────────────────────────────────────────────────────────

## Allow-list for chain_data node dict fields (schema_version=1 lock).
##
## AC-2 + AC-10 + AC-52: exactly 7 fields permitted. Any other key in a node dict
## triggers [method validate_chain_data] to emit [signal submission_rejected] and
## return false. Field names are locked per ADR-0007 §1 — bump requires explicit
## migration ADR.
const ALLOWED_NODE_FIELDS: Array = [
	"node_id",
	"label",
	"parent_id",
	"evidence",
	"depth",
	"child_count",
	"evidence_count",
]

## Tree structural invariants (entities.yaml v8).
##
## AC-12: Maximum depth a node may occupy. A child add is rejected when
## [code]parent.depth + 1 > MAX_TREE_DEPTH[/code].
const MAX_TREE_DEPTH := 3              # workspace_max_tree_depth

## AC-14: Maximum number of library citations per node.
## Attach is rejected when [code]node.evidence.size() >= EVIDENCE_PER_NODE_CAP[/code].
const EVIDENCE_PER_NODE_CAP := 5       # workspace_evidence_per_node_cap

## AC-15: Hard character limit for a node label (UTF-16 code units, which equals
## codepoints for BMP characters). Input exceeding this is silently truncated.
const NODE_LABEL_CHAR_LIMIT := 60      # workspace_node_label_char_limit

## AC-16: Hard limit for memo text in UTF-8 codepoints.
## GDScript [code]String.length()[/code] returns codepoint count in Godot 4.
## Input exceeding this is silently truncated.
const NODE_MEMO_CHAR_LIMIT := 500      # workspace_node_memo_char_limit (UTF-8 codepoints)


# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted on every legal state transition.
## [param old_state] and [param new_state] are [enum WorkspaceState] integer values.
## AC-20: all transitions emit this signal — subscribers use typed `.connect()`.
## Forbidden pattern: never use string-keyed [code]emit_signal("workspace_state_changed", ...)[/code].
signal workspace_state_changed(old_state: int, new_state: int)

## Emitted when [method validate_chain_data] detects a forbidden node field.
##
## AC-10 + AC-52: schema_violation is the only [param reason] value in story 002.
## Downstream stories (007/008) may emit additional reason values via this signal.
## EvaluationService MUST NOT be called after this signal fires.
signal submission_rejected(reason: String)

## Emitted when a tree mutation violates a structural invariant (story 003a).
##
## [param reason] values:
##   [code]"max_depth"[/code]       — AC-12: child add rejected; parent already at MAX_TREE_DEPTH.
##   [code]"cycle"[/code]           — AC-13: reparent rejected; new_parent is a descendant of node.
##   [code]"evidence_cap"[/code]    — AC-14: attach rejected; node already at EVIDENCE_PER_NODE_CAP.
##   [code]"label_truncated"[/code] — AC-15: label input exceeded NODE_LABEL_CHAR_LIMIT; truncated.
##   [code]"memo_truncated"[/code]  — AC-16: memo input exceeded NODE_MEMO_CHAR_LIMIT; truncated.
##   [code]"frozen_state"[/code]    — AC-19: mutation rejected; workspace is FROZEN or READ_ONLY.
signal tree_invariant_violation(reason: String)


# ─── Exported fields (persisted by ResourceSaver) ─────────────────────────────

## Hypothesis tree nodes. Typed array requires HypothesisNodeData class to exist
## (scaffold in story 001; full fields in story 003).
@export var nodes: Array[HypothesisNodeData] = []

## Library ID of the citation currently pending KB/gamepad two-step attach.
## Empty string means no pending citation.
## ADR-0008 §2 — application-level state; native drag and KB pending are mutually exclusive.
@export var pending_citation: String = ""

## Snapshot of the chain_data Dictionary built at freeze time.
## Populated by [method submit] at the moment the workspace transitions ACTIVE → FROZEN.
## Story 002 defines the schema; story 007 wires the population.
## ADR-0007 amend-1 §A1: values MUST be Variant primitives only
## (String / int / float / bool / Array / Dictionary / null).
## Never store Resource, Object, RID, Callable, Signal, NodePath, StringName,
## or built-in value types (Vector2, Color, etc.) as values.
## AC-24: this is a fully independent copy — post-freeze mutation of [member nodes]
## or any [HypothesisNodeData] does NOT affect this snapshot.
@export var chain_data_snapshot: Dictionary = {}


# ─── Private state ────────────────────────────────────────────────────────────

## Backing variable for the public [member state] property.
## Written only by [method _transition_to_active], [method _transition_to_frozen],
## and [method _transition_to_read_only]. Never assign directly.
var _state: WorkspaceState = WorkspaceState.INACTIVE


# ─── Public read-only property ────────────────────────────────────────────────

## Current workspace state. Read-only via public API.
##
## AC-21: The setter rejects direct assignment with [code]push_error[/code] and
## returns without mutation. Use [method _transition_to_active],
## [method _transition_to_frozen], or [method _transition_to_read_only] instead.
var state: WorkspaceState:
	get:
		return _state
	set(value):
		push_error(
			"WorkspaceData.state cannot be set directly. " +
			"Use _transition_to_active(), _transition_to_frozen(), " +
			"or _transition_to_read_only() instead."
		)


# ─── Public methods ───────────────────────────────────────────────────────────

## Adds a root node and transitions INACTIVE → ACTIVE if currently INACTIVE.
##
## AC-17: first DeskPane interaction (first root added) triggers activation.
## In ACTIVE state, additional roots are appended without a state transition.
## In FROZEN or READ_ONLY, mutation is rejected (AC-19 — "no mutations possible").
## Null [param node_data] is rejected with [code]push_error[/code] + early return
## (production-safe — does not rely on debug-only [code]assert()[/code]).
##
## [param node_data] must be a non-null [HypothesisNodeData] with [code]parent_id == ""[/code].
func add_first_root_node(node_data: HypothesisNodeData) -> void:
	# W1 — production-safe null guard (replaces release-stripped assert)
	if node_data == null:
		push_error("WorkspaceData.add_first_root_node: node_data must not be null")
		return
	# AC-19 enforcement — reject tree mutation in FROZEN / READ_ONLY (qa BUG-CANDIDATE closure)
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.add_first_root_node: tree mutation forbidden in %s state. " % \
			WorkspaceState.find_key(_state) +
			"No mutations possible after freeze (AC-19)."
		)
		return
	nodes.append(node_data)
	if _state == WorkspaceState.INACTIVE:
		_transition_to_active()


## Submits the current hypothesis tree: snapshots [member chain_data_snapshot],
## validates it against the schema allow-list, then transitions ACTIVE → FROZEN.
##
## Returns [code]true[/code] on successful freeze; [code]false[/code] if rejected
## (wrong state or schema violation).
##
## AC-24: [member chain_data_snapshot] is an independent copy built by
## [method build_chain_data]. Post-freeze mutation of [member nodes] or any
## [HypothesisNodeData] does NOT affect [member chain_data_snapshot].
##
## AC-26: [signal workspace_state_changed] emits EXACTLY ONCE (ACTIVE → FROZEN)
## on a successful submit. On rejection, no signal is emitted and state is unchanged.
##
## Validation via [method validate_chain_data] is performed BEFORE the state
## transition — a schema violation returns [code]false[/code] without transitioning
## or emitting, and [signal submission_rejected] is emitted by the validator.
##
## NOTE (scope-split story-007 data-layer): the submit confirmation dialog (KrDialog,
## AC-25/AC-27c/AC-27d) and the EvaluationService handoff are DEFERRED.
## See forward-claim comment inside the method body.
func submit() -> bool:
	if _state != WorkspaceState.ACTIVE:
		push_error(
			"WorkspaceData.submit: requires ACTIVE state; current=%s" % \
			WorkspaceState.find_key(_state)
		)
		return false
	var snapshot: Dictionary = build_chain_data()
	if not validate_chain_data(snapshot):
		# submission_rejected already emitted by validate_chain_data.
		return false
	chain_data_snapshot = snapshot
	_transition_to_frozen()
	# DEFERRED (story #9 / Brief Editor epic): EvaluationService.submit(PlayerSubmission)
	# handoff. PlayerSubmission requires player_disposition + player_citations from the
	# Brief Editor submit dialog (not yet built). See ADR-0007 §Decision.
	# NOTE: ADR-0007 specifies submit(PlayerSubmission) while the control-manifest
	# specifies submit(chain_data: Dictionary) — this discrepancy must be reconciled
	# when EvaluationService is implemented.
	return true


## Builds and returns a brand-new chain_data Dictionary from the current node tree.
##
## AC-23: Returns [code]{}[/code] when state is INACTIVE — no chain_data
## is meaningful before any interaction.
##
## For all other states, performs a full BFS traversal over [member nodes] and
## constructs a new Dictionary with 5 derivation formulas:
##   - [code]depth[/code]: 0 for roots, parent.depth + 1 for children (AC-6)
##   - [code]child_count[/code]: count of nodes where parent_id == this.node_id (AC-7)
##   - [code]evidence_count[/code]: len(node.evidence) (AC-8)
##   - [code]total_evidence_count[/code]: sum of all evidence_count (AC-4)
##   - [code]max_depth_reached[/code]: max(depth) over all nodes; 0 for empty tree (AC-5)
##
## AC-9: The returned Dictionary is fully constructed as a new literal — no live
## reference to WorkspaceData fields. Mutating [member nodes] or any
## [HypothesisNodeData] after this call does NOT affect the returned Dictionary.
##
## AC-11b: nodes[] array follows BFS canonical ordering — roots sorted by
## node_id lexicographically, then BFS within each root subtree with children
## sorted by node_id at each depth level.
##
## ADR-0007 amend-1 §3.1 Rule 6: evidence Arrays are explicitly .duplicate()d.
## ADR-0008 §1: BFS canonical ordering ensures deterministic byte-identical output.
func build_chain_data() -> Dictionary:
	if _state == WorkspaceState.INACTIVE:
		return {}
	var sorted_roots: Array = _roots()
	sorted_roots.sort_custom(func(a: HypothesisNodeData, b: HypothesisNodeData) -> bool:
		return a.node_id < b.node_id
	)
	var bfs_ordered: Array = []
	for root: HypothesisNodeData in sorted_roots:
		_bfs_collect(root, bfs_ordered)
	var nodes_dict_array: Array = []
	var edges_array: Array = []
	var total_ev: int = 0
	var max_depth: int = 0
	for n: HypothesisNodeData in bfs_ordered:
		nodes_dict_array.append({
			"node_id": n.node_id,
			"label": n.label,
			"parent_id": n.parent_id,
			"evidence": n.evidence.duplicate(),
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


## Validates a chain_data Dictionary against the schema_version=1 node field allow-list.
##
## AC-10 + AC-52: iterates every node dict in [code]cd["nodes"][/code] and checks
## each key against [constant ALLOWED_NODE_FIELDS]. On any forbidden field:
##   1. Calls [code]push_error[/code] with a descriptive message.
##   2. Emits [signal submission_rejected] with reason [code]"schema_violation"[/code].
##   3. Returns [code]false[/code] immediately (fail-fast; partial validation is not performed).
##
## Returns [code]true[/code] if all node fields are in the allow-list (or nodes array is empty).
## EvaluationService MUST NOT be called when this returns false.
##
## ADR-0007 §1 schema lock: any v2+ field addition requires an explicit migration ADR.
func validate_chain_data(cd: Dictionary) -> bool:
	for n: Dictionary in cd.get("nodes", []):
		for k: String in n.keys():
			if not ALLOWED_NODE_FIELDS.has(k):
				push_error(
					"chain_data schema_version=1 violation: forbidden field %s" % k
				)
				submission_rejected.emit("schema_violation")
				return false
	return true


# ─── Tree mutation API (story 003a) ──────────────────────────────────────────

## Adds [param child] as a child of the node identified by [param parent_id].
##
## AC-12 guard: rejected when [code]parent.depth + 1 > MAX_TREE_DEPTH[/code].
## AC-19 guard: rejected in FROZEN or READ_ONLY state.
##
## On success: sets [code]child.parent_id[/code] and [code]child.depth[/code] from the
## parent, then appends [param child] to [member nodes].
##
## Returns [code]true[/code] on success; [code]false[/code] on any guard failure.
## Emits [signal tree_invariant_violation] with reason [code]"max_depth"[/code] or
## [code]"frozen_state"[/code] on rejection.
func add_child_to_node(parent_id: String, child: HypothesisNodeData) -> bool:
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.add_child_to_node: tree mutation forbidden in %s state (AC-19)." % \
			WorkspaceState.find_key(_state)
		)
		tree_invariant_violation.emit("frozen_state")
		return false
	if child == null:
		push_error("WorkspaceData.add_child_to_node: child must not be null.")
		return false
	var parent: HypothesisNodeData = _find_node(parent_id)
	if parent == null:
		push_error(
			"WorkspaceData.add_child_to_node: parent_id '%s' not found in nodes." % parent_id
		)
		return false
	if parent.depth + 1 > MAX_TREE_DEPTH:
		push_error(
			"WorkspaceData.add_child_to_node: max tree depth %d exceeded. " % MAX_TREE_DEPTH +
			"이 분기는 더 깊이 추론할 수 없습니다 (최대 %d단계)" % MAX_TREE_DEPTH
		)
		tree_invariant_violation.emit("max_depth")
		return false
	child.parent_id = parent_id
	child.depth = parent.depth + 1
	nodes.append(child)
	return true


## Moves the node identified by [param node_id] to a new parent identified by
## [param new_parent_id], updating depth on the entire moved subtree.
##
## AC-13 guard: rejected when [param new_parent_id] is a descendant of [param node_id]
## (cycle detection via BFS) or when [param new_parent_id] == [param node_id] (self-cycle).
## Depth guard: rejected when reparenting would push any descendant past [constant MAX_TREE_DEPTH].
## AC-19 guard: rejected in FROZEN or READ_ONLY state.
##
## Returns [code]true[/code] on success; [code]false[/code] on any guard failure.
## Emits [signal tree_invariant_violation] with reason [code]"cycle"[/code],
## [code]"max_depth"[/code], or [code]"frozen_state"[/code] on rejection.
## Tree state is unchanged on rejection.
func reparent(node_id: String, new_parent_id: String) -> bool:
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.reparent: tree mutation forbidden in %s state (AC-19)." % \
			WorkspaceState.find_key(_state)
		)
		tree_invariant_violation.emit("frozen_state")
		return false
	var node: HypothesisNodeData = _find_node(node_id)
	if node == null:
		push_error(
			"WorkspaceData.reparent: node_id '%s' not found in nodes." % node_id
		)
		return false
	var new_parent: HypothesisNodeData = _find_node(new_parent_id)
	if new_parent == null:
		push_error(
			"WorkspaceData.reparent: new_parent_id '%s' not found in nodes." % new_parent_id
		)
		return false
	# Cycle detection: reject if new_parent is a descendant of node (or is node itself).
	if node_id == new_parent_id or _is_descendant(node_id, new_parent_id):
		push_error(
			"WorkspaceData.reparent: cycle detected — '%s' is an ancestor of '%s'. " \
			% [node_id, new_parent_id] +
			"노드를 자신의 하위 노드로 이동할 수 없습니다"
		)
		tree_invariant_violation.emit("cycle")
		return false
	# Depth guard: the subtree rooted at node will shift by delta_depth.
	# Reject if any node in the subtree would exceed MAX_TREE_DEPTH.
	var new_node_depth: int = new_parent.depth + 1
	var delta_depth: int = new_node_depth - node.depth
	if delta_depth > 0:
		# Only need to check when depth increases; BFS to find max current subtree depth.
		var subtree_max_depth: int = 0
		var bfs_queue: Array[HypothesisNodeData] = [node]
		while bfs_queue.size() > 0:
			var current: HypothesisNodeData = bfs_queue.pop_front()
			if current.depth > subtree_max_depth:
				subtree_max_depth = current.depth
			for child: HypothesisNodeData in nodes:
				if child.parent_id == current.node_id:
					bfs_queue.append(child)
		if subtree_max_depth + delta_depth > MAX_TREE_DEPTH:
			push_error(
				"WorkspaceData.reparent: reparenting '%s' to '%s' would push subtree past MAX_TREE_DEPTH=%d." \
				% [node_id, new_parent_id, MAX_TREE_DEPTH]
			)
			tree_invariant_violation.emit("max_depth")
			return false
	# Apply: update parent and recursively update depth on the entire subtree.
	node.parent_id = new_parent_id
	_update_subtree_depth(node, new_node_depth)
	return true


## Attaches a library citation to the node identified by [param node_id].
##
## AC-14 guard: rejected when [code]node.evidence.size() >= EVIDENCE_PER_NODE_CAP[/code].
## AC-19 guard: rejected in FROZEN or READ_ONLY state.
##
## Returns [code]true[/code] on success; [code]false[/code] on any guard failure.
## Emits [signal tree_invariant_violation] with reason [code]"evidence_cap"[/code] or
## [code]"frozen_state"[/code] on rejection.
##
## Note: deduplication is NOT performed at this layer (deferred to story 004
## drag-drop pipeline EC-6). Duplicate library_ids are appended.
func attach_evidence(node_id: String, library_id: String) -> bool:
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.attach_evidence: tree mutation forbidden in %s state (AC-19)." % \
			WorkspaceState.find_key(_state)
		)
		tree_invariant_violation.emit("frozen_state")
		return false
	var node: HypothesisNodeData = _find_node(node_id)
	if node == null:
		push_error(
			"WorkspaceData.attach_evidence: node_id '%s' not found in nodes." % node_id
		)
		return false
	if node.evidence.size() >= EVIDENCE_PER_NODE_CAP:
		push_error(
			"WorkspaceData.attach_evidence: evidence cap reached on node '%s'. " % node_id +
			"이 노드에는 인용을 %d개까지만 첨부할 수 있습니다" % EVIDENCE_PER_NODE_CAP
		)
		tree_invariant_violation.emit("evidence_cap")
		return false
	node.evidence.append(library_id)
	return true


## Sets the display label on the node identified by [param node_id].
##
## AC-15: If [param label] exceeds [constant NODE_LABEL_CHAR_LIMIT] characters,
## it is silently truncated to exactly [constant NODE_LABEL_CHAR_LIMIT] chars
## and [signal tree_invariant_violation] is emitted with reason [code]"label_truncated"[/code].
## AC-19 guard: no-op in FROZEN or READ_ONLY state.
##
## Truncation is a soft cap with feedback — the label IS set (to the truncated value);
## the mutation is not rejected.
func update_node_label(node_id: String, label: String) -> void:
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.update_node_label: tree mutation forbidden in %s state (AC-19)." % \
			WorkspaceState.find_key(_state)
		)
		tree_invariant_violation.emit("frozen_state")
		return
	var node: HypothesisNodeData = _find_node(node_id)
	if node == null:
		push_error(
			"WorkspaceData.update_node_label: node_id '%s' not found in nodes." % node_id
		)
		return
	var effective_label: String = label
	if label.length() > NODE_LABEL_CHAR_LIMIT:
		effective_label = label.substr(0, NODE_LABEL_CHAR_LIMIT)
		tree_invariant_violation.emit("label_truncated")
	node.label = effective_label


## Sets the memo text on the node identified by [param node_id].
##
## AC-16: If [param memo] exceeds [constant NODE_MEMO_CHAR_LIMIT] UTF-8 codepoints,
## it is silently truncated to exactly [constant NODE_MEMO_CHAR_LIMIT] codepoints
## and [signal tree_invariant_violation] is emitted with reason [code]"memo_truncated"[/code].
## [code]String.length()[/code] returns codepoint count in Godot 4 — 한글 = 1 codepoint.
## AC-19 guard: no-op in FROZEN or READ_ONLY state.
##
## Truncation is a soft cap with feedback — the memo IS set (to the truncated value);
## the mutation is not rejected.
func update_node_memo(node_id: String, memo: String) -> void:
	if _state == WorkspaceState.FROZEN or _state == WorkspaceState.READ_ONLY:
		push_error(
			"WorkspaceData.update_node_memo: tree mutation forbidden in %s state (AC-19)." % \
			WorkspaceState.find_key(_state)
		)
		tree_invariant_violation.emit("frozen_state")
		return
	var node: HypothesisNodeData = _find_node(node_id)
	if node == null:
		push_error(
			"WorkspaceData.update_node_memo: node_id '%s' not found in nodes." % node_id
		)
		return
	var effective_memo: String = memo
	if memo.length() > NODE_MEMO_CHAR_LIMIT:
		effective_memo = memo.substr(0, NODE_MEMO_CHAR_LIMIT)
		tree_invariant_violation.emit("memo_truncated")
	node.memo = effective_memo


# ─── Transition functions (only legal state-change API) ───────────────────────

## Transitions INACTIVE → ACTIVE.
##
## AC-17: Called by [method add_first_root_node] on first interaction.
## Rejects any origin state other than INACTIVE with [code]push_error[/code].
func _transition_to_active() -> void:
	if _state != WorkspaceState.INACTIVE:
		push_error(
			"WorkspaceData._transition_to_active: illegal transition from %s. " % \
			WorkspaceState.find_key(_state) +
			"Only INACTIVE → ACTIVE is allowed."
		)
		return
	var old: int = _state
	_state = WorkspaceState.ACTIVE
	workspace_state_changed.emit(old, _state)


## Transitions ACTIVE → FROZEN.
##
## AC-18: Only callable from ACTIVE. FROZEN is irreversible within the session
## (no transition out of FROZEN except to READ_ONLY via [method _transition_to_read_only]).
##
## Callers are responsible for populating [member chain_data_snapshot] BEFORE
## calling this method. [method submit] does so — it assigns [member chain_data_snapshot]
## from [method build_chain_data] prior to this call, guaranteeing the snapshot is
## populated at the moment [signal workspace_state_changed] becomes observable.
##
## This method is single-responsibility: state change + signal emit only.
## It does NOT build or validate chain_data.
func _transition_to_frozen() -> void:
	if _state != WorkspaceState.ACTIVE:
		push_error(
			"WorkspaceData._transition_to_frozen: illegal transition from %s. " % \
			WorkspaceState.find_key(_state) +
			"Only ACTIVE → FROZEN is allowed."
		)
		return
	var old: int = _state
	_state = WorkspaceState.FROZEN
	workspace_state_changed.emit(old, _state)


## Transitions FROZEN → READ_ONLY on EvaluationResult arrival.
##
## AC-19: Tree becomes visible but no mutations are possible.
## Only callable from FROZEN.
func _transition_to_read_only() -> void:
	if _state != WorkspaceState.FROZEN:
		push_error(
			"WorkspaceData._transition_to_read_only: illegal transition from %s. " % \
			WorkspaceState.find_key(_state) +
			"Only FROZEN → READ_ONLY is allowed."
		)
		return
	var old: int = _state
	_state = WorkspaceState.READ_ONLY
	workspace_state_changed.emit(old, _state)


# ─── BFS helpers (used by build_chain_data) ───────────────────────────────────

## Returns all root nodes (parent_id == "") from [member nodes].
## AC-11b: caller sorts the result by node_id before BFS traversal.
func _roots() -> Array:
	var result: Array = []
	for n: HypothesisNodeData in nodes:
		if n.parent_id == "":
			result.append(n)
	return result


## Performs a BFS traversal rooted at [param root], appending visited nodes to
## [param accumulator] in BFS order. Children at each depth are sorted by node_id
## lexicographically to guarantee deterministic canonical ordering (AC-11b).
##
## ADR-0008 §1: same workspace state → byte-identical JSON.stringify output.
func _bfs_collect(root: HypothesisNodeData, accumulator: Array) -> void:
	var queue: Array = [root]
	while queue.size() > 0:
		var current: HypothesisNodeData = queue.pop_front()
		accumulator.append(current)
		var children: Array = _children_of(current.node_id)
		children.sort_custom(func(a: HypothesisNodeData, b: HypothesisNodeData) -> bool:
			return a.node_id < b.node_id
		)
		for child: HypothesisNodeData in children:
			queue.append(child)


## Returns all direct children of the node with [param node_id].
## Used by [method _bfs_collect] for BFS traversal and by [method build_chain_data]
## for the child_count derivation formula (AC-7).
func _children_of(node_id: String) -> Array:
	var result: Array = []
	for n: HypothesisNodeData in nodes:
		if n.parent_id == node_id:
			result.append(n)
	return result


# ─── Tree mutation helpers (story 003a) ──────────────────────────────────────

## Returns the first [HypothesisNodeData] in [member nodes] whose [code]node_id[/code]
## matches [param node_id], or [code]null[/code] if not found.
## Used by all tree mutation API methods to resolve node references.
func _find_node(node_id: String) -> HypothesisNodeData:
	for n: HypothesisNodeData in nodes:
		if n.node_id == node_id:
			return n
	return null


## Returns [code]true[/code] if [param candidate_id] is a descendant of
## [param ancestor_id] (BFS traversal from ancestor).
##
## Used by [method reparent] for cycle detection (AC-13):
## [code]_is_descendant(node_id, new_parent_id)[/code] returns true when the
## proposed new parent is already within the subtree rooted at node — a cycle.
func _is_descendant(ancestor_id: String, candidate_id: String) -> bool:
	var queue: Array[String] = []
	# Seed the queue with direct children of ancestor_id.
	for n: HypothesisNodeData in nodes:
		if n.parent_id == ancestor_id:
			queue.append(n.node_id)
	while queue.size() > 0:
		var current_id: String = queue.pop_front()
		if current_id == candidate_id:
			return true
		for n: HypothesisNodeData in nodes:
			if n.parent_id == current_id:
				queue.append(n.node_id)
	return false


## Recursively updates [code]depth[/code] on [param node] and all its descendants
## so that [param node] lands at [param new_depth].
## Called by [method reparent] after cycle and max-depth guards pass.
func _update_subtree_depth(node: HypothesisNodeData, new_depth: int) -> void:
	node.depth = new_depth
	for n: HypothesisNodeData in nodes:
		if n.parent_id == node.node_id:
			_update_subtree_depth(n, new_depth + 1)
