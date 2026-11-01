class_name MainMenu
extends Control
## Main Menu & Co-op Lobby interface for Sector 9: Cold Protocol.
## Features Solo deployment, Co-op Host/Join, 4-player roster sync, hybrid roles, and clean transitions.

const NetworkManagerScript = preload("res://src/network/network_manager.gd")
const AccessibilityScript = preload("res://src/ui/accessibility_settings.gd")

var network: NetworkManagerScript
var accessibility: AccessibilityScript

# UI Screens
var _screen_landing: VBoxContainer
var _screen_lobby: VBoxContainer
var _screen_join: VBoxContainer
var _screen_settings: VBoxContainer

# Lobby Widgets
var _room_code_label: Label
var _roster_container: VBoxContainer
var _btn_ready: Button
var _btn_start_mission: Button
var _role_buttons: HBoxContainer
var _hybrid_badge: Label

# Join Inputs
var _input_ip: LineEdit
var _input_code: LineEdit
var _join_error_label: Label

const COLOR_BG := Color("0b1322")
const COLOR_PRIMARY := Color("66e0c2")
const COLOR_ACCENT := Color("ffd280")
const COLOR_DANGER := Color("ff5c5c")
const COLOR_PANEL := Color("111a28")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	network = NetworkManagerScript.new()
	network.name = "NetworkManager"
	add_child(network)

	network.roster_updated.connect(_update_lobby_roster)
	network.game_started.connect(_on_game_started)
	network.connection_failed.connect(_on_connection_failed)
	network.connection_succeeded.connect(_on_connection_succeeded)

	accessibility = AccessibilityScript.new()

	_build_ui()
	_show_screen(_screen_landing)


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG
	add_child(bg)

	# Main Centered Container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 560)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = COLOR_PANEL
	p_style.border_color = Color("22344d")
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(14)
	p_style.content_margin_left = 32
	p_style.content_margin_right = 32
	p_style.content_margin_top = 28
	p_style.content_margin_bottom = 28
	panel.add_theme_stylebox_override(&"panel", p_style)
	center.add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override(&"separation", 20)
	panel.add_child(main_vbox)

	# Title Header
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(title_box)

	var title := Label.new()
	title.text = "SECTOR 9 : COLD PROTOCOL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 30)
	title.add_theme_color_override(&"font_color", COLOR_PRIMARY)
	title.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	title.add_theme_constant_override(&"shadow_offset_y", 2)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Çok Oyunculu Taktiksel Sızma & Operasyon Odası"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override(&"font_size", 14)
	subtitle.add_theme_color_override(&"font_color", Color("94a7bd"))
	title_box.add_child(subtitle)

	# 1. Landing Screen
	_screen_landing = VBoxContainer.new()
	_screen_landing.add_theme_constant_override(&"separation", 12)
	_screen_landing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_landing.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(_screen_landing)

	_add_menu_button(_screen_landing, "🎮  SOLO OPERASYON (ANTRENMAN SAHASI)", _on_solo_pressed, COLOR_PRIMARY)
	_add_menu_button(_screen_landing, "📡  CO-OP ODA KUR (HOST)", _on_host_pressed, COLOR_ACCENT)
	_add_menu_button(_screen_landing, "🔗  CO-OP ODAYA KATIL (CLIENT)", _on_join_screen_pressed, Color("e3eaf2"))
	_add_menu_button(_screen_landing, "⚙️  AYARLAR & ERİŞİLEBİLİRLİK", _on_settings_pressed, Color("94a7bd"))
	_add_menu_button(_screen_landing, "🚪  ÇIKIŞ", _on_quit_pressed, Color("718294"))

	# 2. Lobby Screen
	_screen_lobby = VBoxContainer.new()
	_screen_lobby.add_theme_constant_override(&"separation", 14)
	_screen_lobby.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_lobby.visible = false
	main_vbox.add_child(_screen_lobby)

	var lobby_header := HBoxContainer.new()
	_screen_lobby.add_child(lobby_header)

	_room_code_label = Label.new()
	_room_code_label.text = "ODA KODU: S9-0000"
	_room_code_label.add_theme_font_size_override(&"font_size", 18)
	_room_code_label.add_theme_color_override(&"font_color", COLOR_ACCENT)
	_room_code_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lobby_header.add_child(_room_code_label)

	_hybrid_badge = Label.new()
	_hybrid_badge.text = "[ 2 KİŞİLİK MELEZ ROL AKTİF ]"
	_hybrid_badge.add_theme_font_size_override(&"font_size", 13)
	_hybrid_badge.add_theme_color_override(&"font_color", COLOR_PRIMARY)
	_hybrid_badge.visible = false
	lobby_header.add_child(_hybrid_badge)

	# Roster list
	_roster_container = VBoxContainer.new()
	_roster_container.add_theme_constant_override(&"separation", 8)
	_screen_lobby.add_child(_roster_container)

	# Role selection buttons
	var role_label := Label.new()
	role_label.text = "Rolünü Seç:"
	role_label.add_theme_font_size_override(&"font_size", 14)
	role_label.add_theme_color_override(&"font_color", Color("94a7bd"))
	_screen_lobby.add_child(role_label)

	_role_buttons = HBoxContainer.new()
	_role_buttons.add_theme_constant_override(&"separation", 8)
	_screen_lobby.add_child(_role_buttons)

	_add_role_button(_role_buttons, "Kırıcı", "breaker")
	_add_role_button(_role_buttons, "Göz", "scout")
	_add_role_button(_role_buttons, "Kilit", "lock")
	_add_role_button(_role_buttons, "Yük", "carrier")

	# Lobby actions
	var lobby_actions := HBoxContainer.new()
	lobby_actions.add_theme_constant_override(&"separation", 12)
	_screen_lobby.add_child(lobby_actions)

	_btn_ready = _add_action_button(lobby_actions, "✓  HAZIR OL", _on_ready_toggled, COLOR_PRIMARY)
	_btn_ready.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_btn_start_mission = _add_action_button(lobby_actions, "🚀  OPERASYONU BAŞLAT", _on_start_mission_pressed, COLOR_ACCENT)
	_btn_start_mission.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start_mission.visible = false

	var btn_leave := _add_action_button(lobby_actions, "⬅  LOBİDEN AYRIL", _on_leave_lobby_pressed, Color("718294"))
	btn_leave.custom_minimum_size.x = 160

	# 3. Join Screen
	_screen_join = VBoxContainer.new()
	_screen_join.add_theme_constant_override(&"separation", 14)
	_screen_join.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_join.alignment = BoxContainer.ALIGNMENT_CENTER
	_screen_join.visible = false
	main_vbox.add_child(_screen_join)

	var ip_label := Label.new()
	ip_label.text = "Sunucu IP Adresi (Yerel Ağ / Localhost için 127.0.0.1):"
	ip_label.add_theme_font_size_override(&"font_size", 14)
	_screen_join.add_child(ip_label)

	_input_ip = LineEdit.new()
	_input_ip.text = "127.0.0.1"
	_input_ip.custom_minimum_size.y = 42
	_screen_join.add_child(_input_ip)

	var code_label := Label.new()
	code_label.text = "4 Haneli Oda Kodu (Örn: S9-4081):"
	code_label.add_theme_font_size_override(&"font_size", 14)
	_screen_join.add_child(code_label)

	_input_code = LineEdit.new()
	_input_code.placeholder_text = "S9-XXXX"
	_input_code.custom_minimum_size.y = 42
	_screen_join.add_child(_input_code)

	_join_error_label = Label.new()
	_join_error_label.text = ""
	_join_error_label.add_theme_color_override(&"font_color", COLOR_DANGER)
	_join_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_screen_join.add_child(_join_error_label)

	var join_btn_box := HBoxContainer.new()
	join_btn_box.add_theme_constant_override(&"separation", 12)
	_screen_join.add_child(join_btn_box)

	var btn_connect := _add_action_button(join_btn_box, "BAĞLAN", _on_connect_pressed, COLOR_PRIMARY)
	btn_connect.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn_back := _add_action_button(join_btn_box, "GERİ", _on_back_to_landing, Color("718294"))
	btn_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 4. Settings Screen
	_screen_settings = VBoxContainer.new()
	_screen_settings.add_theme_constant_override(&"separation", 14)
	_screen_settings.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_settings.alignment = BoxContainer.ALIGNMENT_CENTER
	_screen_settings.visible = false
	main_vbox.add_child(_screen_settings)

	var s_title := Label.new()
	s_title.text = "ERİŞİLEBİLİRLİK VE GÖRSEL AYARLAR"
	s_title.add_theme_font_size_override(&"font_size", 16)
	s_title.add_theme_color_override(&"font_color", COLOR_PRIMARY)
	_screen_settings.add_child(s_title)

	var btn_fx := _add_action_button(_screen_settings, "F6 : Efekt Azaltma / Ekran Sarsıntısı (Açık/Kapalı)", func():
		accessibility.toggle_reduced_effects()
	, Color("e3eaf2"))

	var btn_hold := _add_action_button(_screen_settings, "T : Hold / Toggle Etkileşim Modu", func():
		accessibility.set_hold_toggle(not accessibility.hold_toggle_enabled)
	, Color("e3eaf2"))

	var btn_settings_back := _add_action_button(_screen_settings, "GERİ DÖN", _on_back_to_landing, COLOR_PRIMARY)


func _show_screen(target: VBoxContainer) -> void:
	_screen_landing.visible = (target == _screen_landing)
	_screen_lobby.visible = (target == _screen_lobby)
	_screen_join.visible = (target == _screen_join)
	_screen_settings.visible = (target == _screen_settings)


func _add_menu_button(parent: Control, label: String, callback: Callable, accent_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override(&"font_size", 16)
	btn.add_theme_color_override(&"font_color", Color.WHITE)
	btn.add_theme_color_override(&"font_focus_color", Color.WHITE)
	btn.add_theme_color_override(&"font_hover_color", accent_color)
	btn.add_theme_color_override(&"font_hover_pressed_color", accent_color)
	btn.add_theme_color_override(&"font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.11, 0.17, 0.26, 0.95)
	normal.border_color = Color(accent_color.r * 0.7, accent_color.g * 0.7, accent_color.b * 0.7, 0.75)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	btn.add_theme_stylebox_override(&"normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.16, 0.24, 0.38, 1.0)
	hover.border_color = accent_color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.content_margin_left = 18
	hover.content_margin_right = 18
	btn.add_theme_stylebox_override(&"hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.06, 0.10, 0.16, 1.0)
	pressed.border_color = accent_color
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(8)
	btn.add_theme_stylebox_override(&"pressed", pressed)

	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override(&"focus", empty)

	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _add_action_button(parent: Control, label: String, callback: Callable, accent_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override(&"font_size", 14)
	btn.add_theme_color_override(&"font_color", Color("e6eef8"))
	btn.add_theme_color_override(&"font_hover_color", accent_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.16, 0.25, 0.95)
	normal.border_color = Color(0.20, 0.30, 0.45, 0.8)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override(&"normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.22, 0.35, 1.0)
	hover.border_color = accent_color
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override(&"hover", hover)

	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override(&"focus", empty)

	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _add_role_button(parent: Control, label: String, role_id: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 40
	btn.add_theme_font_size_override(&"font_size", 13)
	btn.add_theme_color_override(&"font_color", Color("e6eef8"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.13, 0.20, 0.9)
	normal.border_color = Color(0.20, 0.30, 0.45, 0.8)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override(&"normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.22, 0.35, 1.0)
	hover.border_color = COLOR_PRIMARY
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override(&"hover", hover)

	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override(&"focus", empty)

	btn.pressed.connect(func():
		var local_id: int = multiplayer.get_unique_id()
		network.set_player_role(local_id, role_id)
	)
	parent.add_child(btn)


# -----------------------------------------------------------------------------
# Button Callbacks
# -----------------------------------------------------------------------------

func _on_solo_pressed() -> void:
	# Launch singleplayer mechanics lab directly
	get_tree().change_scene_to_file("res://src/lab/mechanics_lab.tscn")


func _on_host_pressed() -> void:
	var code: String = network.host_game()
	if not code.is_empty():
		_room_code_label.text = "ODA KODU: %s" % code
		_btn_start_mission.visible = true
		_show_screen(_screen_lobby)


func _on_join_screen_pressed() -> void:
	_join_error_label.text = ""
	_show_screen(_screen_join)


func _on_connect_pressed() -> void:
	var ip: String = _input_ip.text.strip_edges()
	var code: String = _input_code.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var success: bool = network.join_game(ip, NetworkManagerScript.DEFAULT_PORT, code)
	if not success:
		_join_error_label.text = "Bağlantı başlatılamadı."


func _on_connection_succeeded() -> void:
	_btn_start_mission.visible = false
	_room_code_label.text = "BAĞLANDI: %s" % _input_code.text
	_show_screen(_screen_lobby)


func _on_connection_failed(reason: String) -> void:
	_join_error_label.text = reason


func _on_ready_toggled() -> void:
	var local_id: int = multiplayer.get_unique_id()
	if network.players.has(local_id):
		var currently_ready: bool = network.players[local_id].get("ready", false)
		network.set_player_ready(local_id, not currently_ready)
		_btn_ready.text = "✕  HAZIRLIĞI İPTAL ET" if not currently_ready else "✓  HAZIR OL"


func _on_start_mission_pressed() -> void:
	if network.is_host and network.are_all_players_ready():
		network.start_mission()


func _on_leave_lobby_pressed() -> void:
	network.disconnect_game()
	_show_screen(_screen_landing)


func _on_settings_pressed() -> void:
	_show_screen(_screen_settings)


func _on_back_to_landing() -> void:
	_show_screen(_screen_landing)


func _on_quit_pressed() -> void:
	get_tree().quit(0)


func _on_game_started() -> void:
	get_tree().change_scene_to_file("res://src/lab/mechanics_lab.tscn")


# -----------------------------------------------------------------------------
# Lobby Roster Rendering
# -----------------------------------------------------------------------------

func _update_lobby_roster() -> void:
	if not is_instance_valid(_roster_container):
		return

	for c in _roster_container.get_children():
		c.queue_free()

	_hybrid_badge.visible = network.is_hybrid_mode_active()

	for peer_id in network.players:
		var p: Dictionary = network.players[peer_id]
		var row := PanelContainer.new()
		var r_style := StyleBoxFlat.new()
		r_style.bg_color = Color(0.08, 0.13, 0.20, 0.85)
		r_style.border_color = COLOR_PRIMARY if p.get("ready", false) else Color("22344d")
		r_style.set_border_width_all(1)
		r_style.set_corner_radius_all(6)
		row.add_theme_stylebox_override(&"panel", r_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override(&"separation", 14)
		row.add_child(hbox)

		var name_lbl := Label.new()
		name_lbl.text = ("👑 " if p.get("is_host", false) else "👤 ") + p.get("name", "Operatör")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override(&"font_size", 14)
		hbox.add_child(name_lbl)

		var role_lbl := Label.new()
		var r_name: String = p.get("role", "").capitalize()
		if network.is_hybrid_mode_active():
			r_name = "Baskın Taşıyıcı" if p.get("role") in ["breaker", "carrier"] else "Teknik Gözcü"
		role_lbl.text = "[ %s ]" % r_name
		role_lbl.add_theme_font_size_override(&"font_size", 13)
		role_lbl.add_theme_color_override(&"font_color", COLOR_ACCENT)
		hbox.add_child(role_lbl)

		var ready_lbl := Label.new()
		ready_lbl.text = "HAZIR" if p.get("ready", false) else "BEKLİYOR..."
		ready_lbl.add_theme_font_size_override(&"font_size", 13)
		ready_lbl.add_theme_color_override(&"font_color", COLOR_PRIMARY if p.get("ready", false) else Color("94a7bd"))
		hbox.add_child(ready_lbl)

		_roster_container.add_child(row)

	# Update start mission button state for host
	if network.is_host:
		_btn_start_mission.disabled = not network.are_all_players_ready()
