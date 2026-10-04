extends SceneTree
## Parse-checks Godot scripts the way the game loads them.
##
## Usage, from the project root, after `godot --headless --path . --import`
## (which builds the class cache that `class_name` lookups need):
##
##   godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://src/a.gd res://src/b.gd
##
## Prints `ok: <path>` or `PARSE FAIL: <path>` per script, with Godot's own
## error lines above each failure. Exit 0 when every script loads, 1 when any
## does not, 2 when no script was given.
##
## Why not `--check-only`: it compiles the file with no autoloads
## registered, so valid code that names an autoload exits 1 with
## "Identifier not found". Loading in `_initialize()` runs after startup has
## registered them; `_init()` runs before, and fails the same way.


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		printerr("godot-parse-check: no scripts given. Pass res:// paths after `--`.")
		quit(2)
		return
	var failed := 0
	for path in paths:
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("PARSE FAIL: ", path)
			failed += 1
		else:
			print("ok: ", path)
	quit(1 if failed > 0 else 0)
