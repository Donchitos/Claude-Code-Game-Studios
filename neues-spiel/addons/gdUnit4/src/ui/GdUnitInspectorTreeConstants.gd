class_name GdUnitInspectorTreeConstants
extends RefCounted


# the inspector panel presantation
enum TREE_VIEW_MODE {
	TREE,
	FLAT
}


# The inspector sort modes
enum SORT_MODE {
	UNSORTED,
	NAME_ASCENDING,
	NAME_DESCENDING,
	EXECUTION_TIME
}


enum STATE {
	INITIAL,
	RUNNING,
	SKIPPED,
	SUCCESS,
	WARNING,
	FLAKY,
	FAILED,
	ERROR,
	ABORDED,
}
