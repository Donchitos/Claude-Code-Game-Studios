@tool
class_name GdUnitFonts
extends RefCounted


static func init_fonts(item: CanvasItem) -> float:
	# set default size
	item.set("theme_override_font_sizes/font_size", 16)

	if Engine.is_editor_hint():
		var base_control := EditorInterface.get_base_control()
		# source modules/mono/editor/GodotTools/GodotTools/Build/BuildOutputView.cs
		# https://github.com/godotengine/godot/blob/9ee1873ae1e09c217ac24a5800007f63cb895615/editor/editor_log.cpp#L65
		var output_source_mono := base_control.get_theme_font("output_source_mono", "EditorFonts")
		var output_source_bold_italic := base_control.get_theme_font("output_source_bold_italic", "EditorFonts")
		var output_source_italic := base_control.get_theme_font("output_source_italic", "EditorFonts")
		var output_source_bold := base_control.get_theme_font("output_source_bold", "EditorFonts")
		var output_source := base_control.get_theme_font("output_source", "EditorFonts")
		var settings := EditorInterface.get_editor_settings()
		var scale_factor := EditorInterface.get_editor_scale()
		var font_size: float = settings.get_setting("interface/editor/main_font_size")

		font_size *= scale_factor
		item.set("theme_override_fonts/normal_font", output_source)
		item.set("theme_override_fonts/bold_font", output_source_bold)
		item.set("theme_override_fonts/italics_font", output_source_italic)
		item.set("theme_override_fonts/bold_italics_font", output_source_bold_italic)
		item.set("theme_override_fonts/mono_font", output_source_mono)
		item.set("theme_override_font_sizes/font_size", font_size)
		item.set("theme_override_font_sizes/normal_font_size", font_size)
		item.set("theme_override_font_sizes/bold_font_size", font_size)
		item.set("theme_override_font_sizes/italics_font_size", font_size)
		item.set("theme_override_font_sizes/bold_italics_font_size", font_size)
		item.set("theme_override_font_sizes/mono_font_size", font_size)
		return font_size
	return 16.0
