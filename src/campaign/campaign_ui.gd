extends Control
## Responsive, localized campaign presentation. All mutations go through the owner.
const INK := Color("0b2024")
const JADE := Color("163b3b")
const GOLD := Color("d9b978")
const TEXT := Color("eee9d9")
var root: Control
var buttons: Array[Button] = []
var content: VBoxContainer
var guidance: Label
var hud: Label
var hp: ProgressBar
var xp: ProgressBar
var shade: Control
var body: Control
var scale_value := 1.0
const DEFAULT_SETTINGS := {"locale": "zh-CN", "master": 1.0, "music": 1.0, "sfx": 1.0, "font_scale": 1.0, "reduce_motion": false, "fullscreen": false}
var data: Dictionary = {"settings": DEFAULT_SETTINGS}

## Connects the persistent controller and installs the original jade/gold theme.
func initialize(owner_root: Control) -> void:
	root = owner_root
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Theme.new()
	t.default_font = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = JADE if state != "hover" else Color("235451")
		box.border_color = GOLD if state in ["focus", "hover"] else Color("345452")
		box.set_border_width_all(2 if state == "focus" else 1)
		box.set_corner_radius_all(8)
		box.content_margin_left = 18
		box.content_margin_right = 18
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		t.set_stylebox(state, "Button", box)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("738681"))
	t.set_constant("separation", "VBoxContainer", 12)
	theme = t

## Returns language-specific UI text.
func tr2(zh: String, en: String) -> String:
	return en if str(data.get("settings", DEFAULT_SETTINGS).get("locale", "zh-CN")).begins_with("en") else zh

## Localizes catalog fields without exposing internal dictionaries to widgets.
func localized(row: Dictionary, field: String = "name") -> String:
	return str(row.get(field + "_en", row.get(field, ""))) if tr2("zh", "en") == "en" else str(row.get(field, ""))

## Rebuilds a screen with a scrolling content area at every supported font size.
func render(page: String) -> void:
	_clear()
	if root.profile_ready:
		data = root.profile.data
	else:
		data = {"settings": DEFAULT_SETTINGS}
	scale_value = float(data.settings.font_scale) if root.profile_ready else 1.0
	theme.default_font_size = roundi(17 * scale_value)
	body = Control.new()
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if page == "battle":
		_battle()
		return
	var bg := ColorRect.new()
	bg.color = INK
	body.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	body.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	_label(top, tr2("灵 枢 行 纪", "S P I R I T   N E X U S"), 26, GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if page != "home":
		_button(top, tr2("返回行馆", "Home"), root.show_page.bind("home"))
	_label(layout, tr2("八境 · 六十四程   /   一盏灵光，照见归途", "EIGHT REALMS · SIXTY-FOUR JOURNEYS / A light to guide us home"), 14, Color("92ada4"))
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	match page:
		"home": _home()
		"chapters": _chapters()
		"characters": _characters()
		"cultivation": _cultivation()
		"codex": _codex()
		"challenges": _achievements()
		"settings": _settings()
		"result": _result()
		"ending": _ending()
	_focus()

## Isolates modal pointer and navigation targets from all background controls.
func overlay(kind: String) -> void:
	if shade != null:
		remove_child(shade)
		shade.queue_free()
	buttons.clear()
	if body != null:
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_disable_focus(body)
	shade = ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.04, 0.94)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	shade.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 48)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	match kind:
		"pause":
			_label(box, tr2("暂歇 · 灵息未散", "REST · THE LIGHT ENDURES"), 32, GOLD)
			_label(box, tr2("世界已暂停。失焦后需手动继续。", "The world is paused. Return here to resume after focus loss."))
			_button(box, tr2("继续行程", "Resume journey"), root.resume_battle)
			_button(box, tr2("保存本局并回行馆", "Save run & return home"), root.save_and_home)
			_label(box, _build_text(), 18)
			_label(box, root.arena.teaching_text(tr2("zh", "en")), 18)
		"upgrade":
			_label(box, tr2("悟道 · 择一而进", "INSIGHT · CHOOSE YOUR PATH"), 32, GOLD)
			if int(root.arena.state.get("rerolls", 0)) > 0:
				_button(box, tr2("刷新悟道 · 剩余 %d", "Reroll · %d remaining") % root.arena.state.rerolls, root.reroll)
			for id: String in root.arena.state.offered:
				var row := _lookup(id)
				_button(box, localized(row) + "\n" + localized(row, "description"), root.choose.bind(id))
		"event":
			var row := _lookup(root.arena.state.event_id)
			if root.arena.mission.has("clues"):
				_label(box,tr2("本关冒险压力会提高后续生成敌人的生命与伤害；已出现者不变。", "Risk pressure increases health and damage of enemies spawned later in this hunt."))
			_label(box, localized(row), 30, GOLD)
			_label(box, localized(row, "description"))
			for key in ["safe", "risk"]:
				var outcome: Dictionary = row.get(key, {})
				_label(box, (tr2("稳妥", "Safe") if key == "safe" else tr2("冒险", "Risk")) + (tr2(" · 胜利后残页 %+d / 伤害 %.0f / 压力 %+.0f%%", " · Pages on victory %+d / Damage %.0f / Pressure %+.0f%%") % [outcome.get("reward", 0), outcome.get("damage", 0), float(outcome.get("pressure", 0)) * 100]), 17)
			_button(box, tr2("稳妥行事 · 接受平稳馈赠", "Take the safe gift"), root.choose.bind(false))
			_button(box, tr2("冒险一试 · 接受代价与机遇", "Embrace risk and its cost"), root.choose.bind(true))
		"abandon":
			_label(box, tr2("放下此程？", "Abandon this journey?"), 30, GOLD)
			_label(box, tr2("本局战斗进度会被清除，已用丹药不退还。主线与成长保留。", "This run will be removed. Its consumed pill is not refunded. Story progress and growth remain."))
			_button(box, tr2("保留本局", "Keep this run"), root.cancel_abandon)
			_button(box, tr2("确认放弃本局", "Confirm abandon"), root.abandon_current_run)
		"error":
			_label(box, tr2("未能完成操作", "ACTION COULD NOT COMPLETE"), 30, GOLD)
			if root.error == "LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION":
				_label(box, tr2("本次任务属于旧版本，原存档已保留。请使用创建本局的保留版本结束本局，或在旧版主动放弃，再返回新版。", "This run belongs to a previous version. Your save is retained. Finish or explicitly abandon it in the preserved version that created this run, then return here."))
				_label(box, tr2("存档目录：", "Save folder: ") + OS.get_user_data_dir(), 15)
			elif root.error == "UNKNOWN_ACTIVE_RUN_CONTENT":
				_label(box, tr2("无法识别本次任务的内容版本。原存档已保留，请使用创建它的版本继续。", "This run's content version is unrecognized. The original save is retained; continue with the version that created it."))
			else:
				_label(box, root.error)
			if not root.profile_ready:
				if not root.catalog.is_empty():
					_button(box, tr2("重试加载", "Retry loading"), root.reload_profile)
				_button(box, tr2("退出", "Quit"), root.get_tree().quit)
				_focus()
				return
			var reload_needed: bool = root.persistence_blocked or root.error in ["INVALID_BATTLE_CHECKPOINT", "HUNT_CAPACITY_RETRY_EXHAUSTED"]
			_button(box, tr2("重新加载已保存进度", "Reload saved progress") if reload_needed else tr2("返回安全状态", "Return to safety"), root.reload_profile if reload_needed else (root.get_tree().quit if root.profile == null else root.dismiss_error))
	_focus()

## Routes the explicit Meta actions within the current page or modal only.
func navigate(action: StringName) -> void:
	var available: Array[Button] = []
	for b in buttons:
		if is_instance_valid(b) and not b.disabled and b.is_visible_in_tree():
			available.append(b)
	if available.is_empty():
		return
	var index := available.find(get_viewport().gui_get_focus_owner())
	if action == &"ui_activate":
		if index >= 0:
			available[index].pressed.emit()
		else:
			available[0].grab_focus()
	elif action in [&"ui_focus_next", &"ui_focus_previous", &"ui_focus_left", &"ui_focus_right"]:
		var step := -1 if action in [&"ui_focus_previous", &"ui_focus_left"] else 1
		available[posmod(index + step, available.size())].grab_focus()

## Updates battle metrics and four active/four passive build slots.
func update_hud() -> void:
	if not is_instance_valid(hud) or root.arena == null:
		return
	var s: Dictionary = root.arena.state
	var p: Dictionary = s.player
	hp.max_value = float(p.max_hp)
	hp.value = float(p.hp)
	xp.max_value = root.arena.xp_required()
	xp.value = float(p.xp)
	hud.text = root.arena.objective_text(tr2("zh", "en")) + "\n" + (tr2("生命 %.0f/%.0f   境界 %d   击破 %d", "HP %.0f/%.0f   Level %d   Kills %d") % [p.hp, p.max_hp, p.level, p.kills])
	guidance.text = root.arena.teaching_text(tr2("zh", "en"))
	var queued: int = root.arena.queued_upgrades()
	if queued > 0 and root.arena.mission.has("upgrade_interval_ticks"):
		guidance.text = tr2("待选升级 %d · 战斗间隔后开启", "%d upgrades queued · resume combat") % queued

## Full build remains available while the world is paused.
func _build_text() -> String:
	var lines: Array[String] = []
	for key in ["skills", "passives"]:
		for id: String in root.arena.state[key]:
			lines.append(localized(_lookup(id)) + " " + str(root.arena.state[key][id]))
	return " · ".join(lines)

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	buttons.clear()
	shade = null
	hud = null
	guidance = null

func _label(parent: Node, text: String, font_size: int = 18, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(font_size * scale_value))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 46 * scale_value
	b.disabled = disabled
	parent.add_child(b)
	b.pressed.connect(func():
		root.audio.effect("ui")
		action.call())
	buttons.append(b)
	return b

func _card(title: String, subtitle: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102e30")
	style.border_color = Color("345452")
	style.border_width_left = 3
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	if root.page in ["codex", "challenges"]:
		_button(box, title, _noop)
	else:
		_label(box, title, 22, GOLD)
	if subtitle != "":
		_label(box, subtitle, 16, Color("a9bcb2"))
	return box

func _home() -> void:
	var d: Dictionary = data
	var art := preload("res://src/campaign/campaign_ui_art.gd").new()
	art.custom_minimum_size = Vector2(340, 250)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 18)
	content.add_child(hero_row)
	hero_row.add_child(art)
	var inscription := Label.new()
	inscription.text = tr2("灵光不灭\n山河同归", "A LIGHT\nTO GUIDE US HOME")
	inscription.position = Vector2(28, 165)
	inscription.add_theme_font_size_override("font_size", roundi(19 * scale_value))
	inscription.add_theme_color_override("font_color", GOLD)
	art.add_child(inscription)
	var hero := _card(tr2("行馆 · 山河待启", "THE WAYFARER'S LODGE"), tr2("灵脉衰落之后，你携残卷踏入八境，寻找让万物重新相连的答案。", "With the spirit veins fading, carry the scattered pages through eight realms and reconnect a broken world."))
	var hero_panel := hero.get_parent()
	hero_panel.reparent(hero_row)
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_panel.size_flags_stretch_ratio = 1.35
	_label(hero, tr2("主线 %d / 64  ·  灵页 %d  ·  草药 %d", "Journey %d / 64  ·  Pages %d  ·  Herbs %d") % [d.completed, d.pages, d.herbs])
	if d.current_run != null:
		_button(hero, tr2("继续本局 →", "Continue saved run →"), root.continue_run)
		_button(hero, tr2("放弃本局…", "Abandon run…"), root.request_abandon)
	else:
		_button(hero, tr2("继续主线 →", "Continue story →"), root.start_mission.bind(mini(int(d.completed), 63), root.selected_pill))
	var nav := GridContainer.new()
	nav.columns = 3
	nav.add_theme_constant_override("h_separation", 12)
	nav.add_theme_constant_override("v_separation", 12)
	content.add_child(nav)
	for entry in [["chapters", "八境任务", "Chapter atlas"], ["characters", "角色与成长", "Characters & growth"], ["cultivation", "草药培育", "Herbal cultivation"], ["codex", "万象图鉴 / 进化", "Codex / evolutions"], ["challenges", "挑战与成就", "Challenges & achievements"], ["settings", "设置", "Settings"]]:
		_button(nav, tr2(entry[1], entry[2]), root.show_page.bind(entry[0])).custom_minimum_size.y = 66 * scale_value
	if int(d.completed) == 64:
		_button(content, tr2("重温终章", "Revisit the ending"), root.show_page.bind("ending"))
	_button(content, tr2("保存并退出", "Save & quit"), root.quit_game)

func _chapters() -> void:
	if data.current_run != null:
		_label(content, tr2("已有进行中的行程，请先继续或回行馆放弃本局。", "A saved run is active. Continue it or abandon it at Home before choosing another mission."), 18, GOLD)
	for chapter: Dictionary in root.catalog.chapters:
		var box := _card(localized(chapter), localized(chapter, "description"))
		for mission: Dictionary in root.catalog.missions:
			if int(mission.chapter) != int(chapter.chapter):
				continue
			var locked := int(data.completed) < int(mission.unlock_after)
			var status := tr2("锁定", "Locked") if locked else (tr2("已完成", "Cleared") if int(data.completed) >= int(mission.ordinal) else tr2("可出发", "Available"))
			_button(box, "%02d  %s · %s\n%s" % [mission.ordinal, localized(mission), status, localized(mission, "briefing")], root.start_mission.bind(int(mission.ordinal) - 1, root.selected_pill), locked or data.current_run != null)

func _characters() -> void:
	for row: Dictionary in root.catalog.characters:
		var box := _card(localized(row), localized(row, "description"))
		var locked := int(data.completed) < int(row.unlock_after)
		_button(box, tr2("需完成 %d 程", "Requires %d clears") % row.unlock_after if locked else (tr2("已选定", "Selected") if data.character_id == row.id else tr2("选择出战", "Select character")), root.command.bind("select_character", row.id), locked)
	var growth := _card(tr2("三脉修习 · 每脉五阶", "THREE BRANCHES · FIVE RANKS EACH"))
	for i in 3:
		var rank := int(data.branches[i])
		var requirement: int = root.profile.branch_requirement(i)
		var locked := requirement >= 0 and int(data.completed) < requirement
		var price := int(root.catalog.tuning.progression_cost_base + root.catalog.tuning.progression_cost_step * rank)
		var suffix := tr2(" · 需完成%d程", " · Requires %d clears") % requirement if locked else (tr2(" · %d 灵页", " · %d pages") % price if rank < 5 else "")
		_button(growth, [tr2("锋意（伤害）", "Edge (damage)"), tr2("体魄（生命）", "Vitality (health)"), tr2("采灵（拾取）", "Gathering (pickup)")][i] + "  " + "◆".repeat(rank) + "◇".repeat(5 - rank) + suffix, root.command.bind("purchase_branch", i), rank >= 5 or locked or int(data.pages) < price)
	var supplies := _card(tr2("出战准备", "PREPARATION"))
	for i in 3:
		_button(supplies, [tr2("行旅 · 轻松", "Wanderer · Easy"), tr2("修行 · 标准", "Adept · Standard"), tr2("问道 · 困难", "Seeker · Hard")][i] + (" ✓" if int(data.difficulty) == i else ""), root.command.bind("set_difficulty", i))
	_button(supplies, tr2("不携丹药", "No pill") + (" ✓" if root.selected_pill == "" else ""), _select_pill.bind(""))
	for row: Dictionary in root.catalog.pills:
		var count := int(data.pills.get(row.id, 0))
		_button(supplies, localized(row) + " ×%d" % count + (" ✓" if root.selected_pill == row.id else ""), _select_pill.bind(row.id), count < 1)

func _select_pill(id: String) -> void:
	root.selected_pill = id
	render("characters")

func _cultivation() -> void:
	_label(content, tr2("草药 %d · 即刻培育，无需等待", "%d herbs · Cultivate instantly") % data.herbs, 24, GOLD)
	for row: Dictionary in root.catalog.pills:
		var box := _card(localized(row), localized(row, "description"))
		var cost := int(row.get("cost", 0))
		_button(box, tr2("培育 · %d 草药 · 库存 %d", "Cultivate · %d herbs · Owned %d") % [cost, data.pills.get(row.id, 0)], root.command.bind("cultivate", row.id), int(data.completed) < int(row.unlock_after) or int(data.herbs) < cost)

func _codex() -> void:
	for kind in ["skills", "passives", "evolutions", "enemies", "elites", "bosses", "events"]:
		for row: Dictionary in root.catalog[kind]:
			var box := _card(localized(row), localized(row, "description"))
			_label(box, tr2("解锁：完成 %d 程", "Unlock: complete %d journeys") % row.unlock_after, 14)
			if kind == "evolutions":
				var parts: Array[String] = []
				for key in ["skill_id", "passive_id", "skill", "passive"]:
					if row.has(key):
						parts.append(localized(_lookup(str(row[key]))))
				_label(box, " + ".join(parts), 16, GOLD)

func _achievements() -> void:
	for kind in ["challenges", "achievements"]:
		_label(content, tr2("挑战", "Challenges") if kind == "challenges" else tr2("成就", "Achievements"), 28, GOLD)
		for row: Dictionary in root.catalog[kind]:
			var unlocked: bool = data[kind].has(row.id)
			var box := _card(("◆ " if unlocked else "◇ ") + localized(row), localized(row, "description"))
			if kind == "challenges":
				_label(box, tr2("敌势 ×%.2f · 险境 ×%.2f · 技能上限 %d · 丹药 %s", "Enemies ×%.2f · Hazards ×%.2f · Skill limit %d · Pills %s") % [row.get("enemy_multiplier", 1), row.get("hazard_multiplier", 1), row.get("max_skills", 4), tr2("允许", "allowed") if row.get("allow_pills", true) else tr2("禁用", "disabled")], 15)
				_button(box, tr2("挑战出战", "Start challenge"), root.start_challenge.bind(row.id), int(data.completed) < int(row.unlock_after) or data.current_run != null)
				continue
			var rule: Dictionary = row.get("rule", {})
			var stat := str(rule.get("stat", "completed"))
			var amount: Variant = achievement_progress(rule)
			_label(box, "%s / %s" % [str(amount), str(rule.get("target", row.unlock_after))], 16)

func _settings() -> void:
	var d: Dictionary = data.settings
	_button(content, tr2("语言：中文 → English", "Language: English → 中文"), root.command.bind("update_settings", {"locale": "en" if tr2("zh", "en") == "zh" else "zh-CN"}))
	for key in ["master", "music", "sfx"]:
		var box := _card({"master": tr2("总音量", "Master volume"), "music": tr2("音乐", "Music"), "sfx": tr2("音效", "Effects")}[key] + "  %d%%" % roundi(float(d[key]) * 100))
		var row := HBoxContainer.new()
		box.add_child(row)
		for change in [-0.1, 0.1]:
			_button(row, "−" if change < 0 else "+", root.command.bind("update_settings", {key: clampf(float(d[key]) + change, 0, 1)}))
	for value in [1.0, 1.15, 1.3]:
		_button(content, tr2("字号", "Text scale") + "  %d%%" % roundi(value * 100) + (" ✓" if is_equal_approx(float(d.font_scale), value) else ""), root.command.bind("update_settings", {"font_scale": value}))
	_button(content, tr2("减少动态", "Reduce motion") + (" ✓" if d.reduce_motion else " ○"), root.command.bind("update_settings", {"reduce_motion": not d.reduce_motion}))
	_button(content, tr2("切换全屏 / 窗口", "Toggle fullscreen / window"), _fullscreen)
	_label(content, tr2("WASD 移动 / 自动施法 · Tab/方向键聚焦 · Enter确认 · Esc返回 · P暂停 · R继续", "WASD move / auto attack · Tab/arrows focus · Enter confirm · Esc back · P pause · R resume"), 15)

func _fullscreen() -> void:
	root.command("update_settings", {"fullscreen": not bool(data.settings.get("fullscreen", false))})

func _battle() -> void:
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := PanelContainer.new()
	body.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_left = 16
	backdrop.offset_right = -230
	backdrop.offset_top = 12
	backdrop.offset_bottom = 108
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.07, 0.075, 0.45)
	background.set_corner_radius_all(8)
	background.content_margin_left = 14
	background.content_margin_right = 14
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	backdrop.add_theme_stylebox_override("panel", background)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := VBoxContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(panel)
	hud = _label(panel, "", 16)
	hud.max_lines_visible = 2
	hud.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hp = ProgressBar.new()
	hp.custom_minimum_size.y = 10
	hp.show_percentage = false
	panel.add_child(hp)

	xp = ProgressBar.new()
	xp.custom_minimum_size.y = 6
	xp.show_percentage = false
	panel.add_child(xp)
	for bar in [hp, xp]:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("7ac8a3") if bar == hp else GOLD
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		var empty := StyleBoxFlat.new()
		empty.bg_color = Color("29413e")
		empty.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", empty)
	var pause := _button(body, tr2("暂停 / 构筑", "Pause / Build"), root.pause_battle)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -214
	pause.offset_right = -24
	pause.offset_top = 20
	pause.offset_bottom = 70
	var hint := _label(body, tr2("WASD 移动 · 自动攻击 · Esc / P 暂停", "WASD move · Auto attack · Esc / P pause") if Input.get_connected_joypads().is_empty() else tr2("左摇杆移动 · 自动攻击 · Start 暂停", "Left stick move · Auto attack · Start pause"), 14, Color("d2dccc"))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 24
	hint.offset_top = -38
	hint.offset_bottom = -8
	hint.offset_right = 800
	guidance = _label(body, "", 16, GOLD)
	guidance.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	guidance.offset_left = 24
	guidance.offset_right = -24
	guidance.offset_top = -104
	guidance.offset_bottom = -44
	guidance.max_lines_visible = 2
	guidance.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	guidance.add_theme_color_override("font_outline_color", Color("071c19"))
	guidance.add_theme_constant_override("outline_size", 5)
	update_hud()

func _result() -> void:
	var r: Dictionary = root.last_result
	var win: bool = r.get("victory", false)
	var box := _card(tr2("此程已成 · 灵脉复苏", "JOURNEY COMPLETE") if win else tr2("灯未熄 · 再启一程", "THE LIGHT REMAINS"), localized(root.catalog.missions[root.last_mission], "success_text") if win else tr2("整理所得，修习三脉，再赴山河。", "Gather what you learned, strengthen your branches, and try again."))
	_label(box, tr2("灵页奖励：%s", "Page reward: %s") % str(r.get("reward", 0)))
	for id: String in r.get("unlocks", []):
		_label(box, tr2("新解锁：", "Unlocked: ") + localized(_lookup(id)))
	if r.get("ending", false):
		_button(box, tr2("走向终章 →", "Enter the epilogue →"), root.show_page.bind("ending"))
	else:
		if win and root.last_mission == 2:
			_label(box, tr2("已开放培育与机缘。可先了解成长和丹药，也可不携药继续。", "Cultivation and encounters are now available. Review growth and pills, or continue without a pill."))
			_button(box, tr2("了解备战 · 成长与丹药", "Prepare · Growth and pills"), root.show_page.bind("characters"))
			_button(box, tr2("前往培育", "Visit cultivation"), root.show_page.bind("cultivation"))
		_button(box, tr2("下一程", "Next journey") if win else tr2("重新挑战", "Retry"), root.start_mission.bind(mini(root.last_mission + 1, 63) if win else root.last_mission, ""))
	_button(box, tr2("回到行馆", "Return home"), root.show_page.bind("home"))

func _ending() -> void:
	var box := _card(tr2("终章 · 山河同息", "EPILOGUE · ONE BREATH"))
	_label(box, tr2("最后一页归位时，灵枢没有许下长生。\n它让断流的河重新流动，让荒原的种子等到了雨。\n你放下残卷，听见八境的人声。\n\n路的尽头，并非独自飞升。\n而是万家灯火，与你同归。", "When the final page returned, the Nexus promised no immortality.\nIt restored the rivers and brought rain to seeds in the wasteland.\nYou set down the pages and heard the voices of eight realms.\n\nThe journey ends not in solitude above the clouds,\nbut among a thousand lights that welcome you home."), 24)
	_label(box, tr2("灵枢行纪 / Spirit Nexus\n原创世界、程序矢量画面与合成音乐\n字体：Noto Sans CJK · SIL Open Font License\n引擎：Godot\n\n感谢你走完这六十四程。", "Spirit Nexus\nOriginal world, procedural vector art & synthesized score\nFont: Noto Sans CJK · SIL Open Font License\nEngine: Godot\n\nThank you for walking all sixty-four journeys."), 17, GOLD)
	_button(box, tr2("归家", "Homeward"), root.show_page.bind("home"))

func _lookup(id: String) -> Dictionary:
	for kind in ["characters", "skills", "passives", "evolutions", "pills", "enemies", "elites", "bosses", "events", "challenges", "achievements"]:
		for row: Dictionary in root.catalog.get(kind, []):
			if str(row.id) == id:
				return row
	return {"name": id, "name_en": id}

func _disable_focus(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_focus(child)

func _focus() -> void:
	for b in buttons:
		if not b.disabled:
			_safe_focus.call_deferred(b)
			return

func _safe_focus(button: Variant) -> void:
	if is_instance_valid(button) and button is Button and button.is_inside_tree() and button in buttons:
		button.grab_focus()

## Reads the same ID-qualified achievement counters used by profile settlement.
func achievement_progress(rule: Dictionary) -> float:
	var stat := str(rule.get("stat", "completed"))
	var aliases := {"character_win": "character_wins", "challenge_win": "challenge_wins", "evolution_id": "evolution_ids"}
	var stats: Dictionary = data.get("stats", {})
	if aliases.has(stat):
		return float(stats.get(aliases[stat], {}).get(str(rule.get("id", "")), 0))
	return float(data.get(stat, stats.get(stat, 0)))

func _noop() -> void:
	pass
