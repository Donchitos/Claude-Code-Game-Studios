@tool
extends Window

const EAXAMPLE_URL := "https://github.com/MikeSchulze/gdUnit4-examples/archive/refs/heads/master.zip"
const GdUnitTools := preload ("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const GdUnitUpdateClient = preload ("res://addons/gdUnit4/src/update/GdUnitUpdateClient.gd")

@onready var _update_client: GdUnitUpdateClient = $GdUnitUpdateClient
@onready var _version_label: RichTextLabel = %version
@onready var _btn_install: Button = %btn_install_examples
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _progress_text: Label = %progress_lbl
@onready var _properties_template: Control = $property_template
@onready var _properties_common: Control = % "common-content"
@onready var _properties_ui: Control = % "ui-content"
@onready var _properties_shortcuts: Control = % "shortcut-content"
@onready var _properties_report: Control = % "report-content"
@onready var _input_capture: GdUnitInputCapture = %GdUnitInputCapture
@onready var _property_error: Window = % "propertyError"
@onready var _tab_container: TabContainer = %Properties
@onready var _update_tab: Control = %Update

var _font_size: float


func _ready() -> void:
	set_name("GdUnitSettingsDialog")
	# initialize for testing
	if not Engine.is_editor_hint():
		GdUnitSettings.setup()
	GdUnit4Version.init_version_label(_version_label)
	_font_size = GdUnitFonts.init_fonts(_version_label)
	setup_properties(_properties_common, GdUnitSettings.COMMON_SETTINGS)
	setup_properties(_properties_ui, GdUnitSettings.UI_SETTINGS)
	setup_properties(_properties_report, GdUnitSettings.REPORT_SETTINGS)
	setup_properties(_properties_shortcuts, GdUnitSettings.SHORTCUT_SETTINGS)
	check_for_update()


func _sort_by_key(left: GdUnitProperty, right: GdUnitProperty) -> bool:
	return left.name() < right.name()


func setup_properties(properties_parent: Control, property_category: String) -> void:
	# Do remove first potential previous added properties (could be happened when the dlg is opened at twice)
	for child in properties_parent.get_children():
		properties_parent.remove_child(child)

	var category_properties := GdUnitSettings.list_settings(property_category)
	# sort by key
	category_properties.sort_custom(_sort_by_key)
	var theme_ := Theme.new()
	theme_.set_constant("h_separation", "GridContainer", 12)
	var last_category := "!"
	var min_size_overall := 0.0
	var labels := []
	var inputs := []
	var info_labels := []
	var grid: GridContainer = null
	for p in category_properties:
		var min_size_ := 0.0
		var property: GdUnitProperty = p
		var current_category := property.category()
		if not grid or current_category != last_category:
			grid = GridContainer.new()
			grid.columns = 4
			grid.theme = theme_

			var sub_category: Control = _properties_template.get_child(3).duplicate()
			var category_label: Label = sub_category.get_child(0)
			category_label.text = current_category.capitalize()
			sub_category.custom_minimum_size.y = _font_size + 16
			properties_parent.add_child(sub_category)
			properties_parent.add_child(grid)
			last_category = current_category
		# property name
		var label: Label = _properties_template.get_child(0).duplicate()
		label.text = _to_human_readable(property.name())
		labels.append(label)
		grid.add_child(label)

		# property reset btn
		var reset_btn: Button = _properties_template.get_child(1).duplicate()
		reset_btn.icon = _get_btn_icon("Reload")
		reset_btn.disabled = property.value() == property.default()
		grid.add_child(reset_btn)

		# property type specific input element
		var input: Node = _create_input_element(property, reset_btn)
		inputs.append(input)
		grid.add_child(input)
		@warning_ignore("return_value_discarded")
		reset_btn.pressed.connect(_on_btn_property_reset_pressed.bind(property, input, reset_btn))
		# property help text
		var info: Label = _properties_template.get_child(2).duplicate()
		info.text = property.help()
		info_labels.append(info)
		grid.add_child(info)
		if min_size_overall < min_size_:
			min_size_overall = min_size_

	for controls: Array in [labels, inputs, info_labels]:
		var _size: float = controls.map(func(c: Control) -> float: return c.size.x).max()
		min_size_overall += _size
		for control: Control in controls:
			control.custom_minimum_size.x = _size
	properties_parent.custom_minimum_size.x = min_size_overall


func _create_input_element(property: GdUnitProperty, reset_btn: Button) -> Node:
	if property.is_selectable_value():
		var options := OptionButton.new()
		options.alignment = HORIZONTAL_ALIGNMENT_CENTER
		for value in property.value_set():
			options.add_item(value)
		options.item_selected.connect(_on_option_selected.bind(property, reset_btn))
		options.select(property.int_value())
		return options
	if property.type() == TYPE_BOOL:
		var check_btn := CheckButton.new()
		check_btn.toggled.connect(_on_property_text_changed.bind(property, reset_btn))
		check_btn.button_pressed = property.value()
		return check_btn
	if property.type() in [TYPE_INT, TYPE_STRING]:
		var input := LineEdit.new()
		input.text_changed.connect(_on_property_text_changed.bind(property, reset_btn))
		input.set_context_menu_enabled(false)
		input.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		input.set_expand_to_text_length_enabled(true)
		input.text = str(property.value())
		return input
	if property.type() == TYPE_PACKED_INT32_ARRAY:
		var key_input_button := Button.new()
		var value:PackedInt32Array = property.value()
		key_input_button.text = to_shortcut(value)
		key_input_button.pressed.connect(_on_shortcut_change.bind(key_input_button, property, reset_btn))
		return key_input_button
	return Control.new()


func to_shortcut(keys: PackedInt32Array) -> String:
	var input_event := InputEventKey.new()
	for key in keys:
		match key:
			KEY_CTRL: input_event.ctrl_pressed = true
			KEY_SHIFT: input_event.shift_pressed = true
			KEY_ALT: input_event.alt_pressed = true
			KEY_META: input_event.meta_pressed = true
			_:
				input_event.keycode = key as Key
	return input_event.as_text()


func to_keys(input_event: InputEventKey) -> PackedInt32Array:
	var keys := PackedInt32Array()
	if input_event.ctrl_pressed:
		keys.append(KEY_CTRL)
	if input_event.shift_pressed:
		keys.append(KEY_SHIFT)
	if input_event.alt_pressed:
		keys.append(KEY_ALT)
	if input_event.meta_pressed:
		keys.append(KEY_META)
	keys.append(input_event.keycode)
	return keys


func _to_human_readable(value: String) -> String:
	return value.split("/")[-1].capitalize()


func _get_btn_icon(p_name: String) -> Texture2D:
	if not Engine.is_editor_hint():
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(8, 8)
		return placeholder
	return GdUnitUiTools.get_icon(p_name)


func _install_examples() -> void:
	_init_progress(5)
	update_progress("Downloading examples")
	await get_tree().process_frame
	var tmp_path := GdUnitFileAccess.create_temp_dir("download")
	var zip_file := tmp_path + "/examples.zip"
	var response: GdUnitUpdateClient.HttpResponse = await _update_client.request_zip_package(EAXAMPLE_URL, zip_file)
	if response.status() != 200:
		push_warning("Examples cannot be retrieved from GitHub! \n Error code: %d : %s" % [response.status(), response.response()])
		update_progress("Install examples failed! Try it later again.")
		await get_tree().create_timer(3).timeout
		stop_progress()
		return
	# extract zip to tmp
	update_progress("Install examples into project")
	var result := GdUnitFileAccess.extract_zip(zip_file, "res://gdUnit4-examples/")
	if result.is_error():
		update_progress("Install examples failed! %s" % result.error_message())
		await get_tree().create_timer(3).timeout
		stop_progress()
		return
	update_progress("Refresh project")
	await rescan()
	await reimport("res://gdUnit4-examples/")

	update_progress("Examples successfully installed")
	await get_tree().create_timer(3).timeout
	stop_progress()


func rescan() -> void:
	await get_tree().process_frame
	var fs := EditorInterface.get_resource_filesystem()
	fs.scan_sources()
	while fs.is_scanning():
		await get_tree().create_timer(1).timeout


func reimport(path: String) -> void:
	await get_tree().process_frame
	var files := DirAccess.get_files_at(path)
	EditorInterface.get_resource_filesystem().reimport_files(files)
	for directory in  DirAccess.get_directories_at(path):
		reimport(directory)


func check_for_update() -> void:
	if not GdUnitSettings.is_update_notification_enabled():
		return
	var response :GdUnitUpdateClient.HttpResponse = await _update_client.request_latest_version()
	if response.status() != 200:
		printerr("Latest version information cannot be retrieved from GitHub!")
		printerr("Error:  %s" % response.response())
		return
	var latest_version := _update_client.extract_latest_version(response)
	if latest_version.is_greater(GdUnit4Version.current()):
		var tab_index := _tab_container.get_tab_idx_from_control(_update_tab)
		_tab_container.set_tab_button_icon(tab_index, GdUnitUiTools.get_icon("Notification", Color.YELLOW))
		_tab_container.set_tab_tooltip(tab_index, "An new update is available.")


func _on_btn_report_bug_pressed() -> void:
	@warning_ignore("return_value_discarded")
	OS.shell_open("https://github.com/MikeSchulze/gdUnit4/issues/new?assignees=MikeSchulze&labels=bug&projects=projects%2F5&template=bug_report.yml&title=GD-XXX%3A+Describe+the+issue+briefly")


func _on_btn_request_feature_pressed() -> void:
	@warning_ignore("return_value_discarded")
	OS.shell_open("https://github.com/MikeSchulze/gdUnit4/issues/new?assignees=MikeSchulze&labels=enhancement&projects=&template=feature_request.md&title=")


func _on_btn_install_examples_pressed() -> void:
	_btn_install.disabled = true
	await _install_examples()
	_btn_install.disabled = false


func _on_btn_close_pressed() -> void:
	hide()


func _on_btn_property_reset_pressed(property: GdUnitProperty, input: Node, reset_btn: Button) -> void:
	if input is CheckButton:
		var is_default_pressed: bool = property.default()
		(input as CheckButton).button_pressed = is_default_pressed
	elif input is LineEdit:
		(input as LineEdit).text = str(property.default())
		# we have to update manually for text input fields because of no change event is emited
		_on_property_text_changed(property.default(), property, reset_btn)
	elif input is OptionButton:
		(input as OptionButton).select(0)
		_on_option_selected(0, property, reset_btn)
	elif input is Button:
		var value: PackedInt32Array = property.default()
		(input as Button).text = to_shortcut(value)
		_on_property_text_changed(value, property, reset_btn)


func _on_property_text_changed(new_value: Variant, property: GdUnitProperty, reset_btn: Button) -> void:
	property.set_value(new_value)
	reset_btn.disabled = property.value() == property.default()
	var error: Variant = GdUnitSettings.update_property(property)
	if error:
		var label: Label = _property_error.get_child(0) as Label
		label.set_text(str(error))
		var control := gui_get_focus_owner()
		_property_error.show()
		if control != null:
			_property_error.position = control.global_position + Vector2(self.position) + Vector2(40, 40)


func _on_option_selected(index: int, property: GdUnitProperty, reset_btn: Button) -> void:
	property.set_value(index)
	reset_btn.disabled = property.value() == property.default()
	GdUnitSettings.update_property(property)


func _on_shortcut_change(input_button: Button, property: GdUnitProperty, reset_btn: Button) -> void:
	_input_capture.set_custom_minimum_size(_properties_shortcuts.get_size())
	_input_capture.visible = true
	_input_capture.show()
	_properties_shortcuts.visible = false
	set_process_input(false)
	_input_capture.reset()
	var input_event: InputEventKey = await _input_capture.input_completed
	input_button.text = input_event.as_text()
	_on_property_text_changed(to_keys(input_event), property, reset_btn)
	_properties_shortcuts.visible = true
	set_process_input(true)


func _init_progress(max_value: int) -> void:
	_progress_bar.visible = true
	_progress_bar.max_value = max_value
	_progress_bar.value = 0


func _progress() -> void:
	_progress_bar.value += 1


func stop_progress() -> void:
	_progress_bar.visible = false


func update_progress(message: String) -> void:
	_progress_text.text = message
	_progress_bar.value += 1
