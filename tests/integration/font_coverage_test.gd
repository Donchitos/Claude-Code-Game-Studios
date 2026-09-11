extends SceneTree
var failures := 0
var checked: Dictionary = {}
var font: FontFile
func _initialize() -> void:
	font = load("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	font.allow_system_fallback = false
	_scan("res://src")
	for character in "击杀敌潮韩立修为体力剩余飞剑首领扇毒暂停试炼失败":
		_check(character.unicode_at(0))
	print("FONT_COVERAGE_%s unique_cjk=%d system_fallback=false" % ["PASS" if failures == 0 else "FAIL", checked.size()])
	quit(0 if failures == 0 else 1)
func _check(code: int) -> void:
	if checked.has(code):
		return
	checked[code] = true
	if not font.has_char(code):
		failures += 1
		push_error("Missing glyph U+%04X" % code)
func _scan(path: String) -> void:
	var directory := DirAccess.open(path)
	for entry in directory.get_directories():
		_scan(path.path_join(entry))
	for entry in directory.get_files():
		if entry.get_extension() not in ["gd", "tscn"]:
			continue
		var content := FileAccess.get_file_as_string(path.path_join(entry))
		for index in content.length():
			var code := content.unicode_at(index)
			if code >= 0x4e00 and code <= 0x9fff:
				_check(code)
