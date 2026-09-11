extends SceneTree

# Full normal run; no profile reads/writes, no boosted HP or auto-upgrades.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.title = "macOS内部试玩 · 内置中文字体 · 临时存档"
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	print("MACOS_PLAYTEST_READY transient_profile=true normal_run=true")
