class_name AccessibilitySettings
extends RefCounted
## Comprehensive Accessibility & User Comfort Settings for Sector 9:
## High-contrast symbols, scalable reticle, hold/toggle input, and reduced motion/effects.

signal settings_changed()
signal reduced_effects_toggled(is_reduced: bool)

var cursor_scale: float = 1.0 # 1.0 to 2.0x
var high_contrast: bool = false
var subtitles_enabled: bool = true
var hold_toggle_enabled: bool = false
var reduced_effects: bool = false
var screen_shake_multiplier: float = 1.0 # 0.0 disables shake entirely


func toggle_reduced_effects() -> bool:
	reduced_effects = not reduced_effects
	screen_shake_multiplier = 0.2 if reduced_effects else 1.0
	reduced_effects_toggled.emit(reduced_effects)
	settings_changed.emit()
	return reduced_effects


func set_cursor_scale(scale_val: float) -> void:
	cursor_scale = clampf(scale_val, 0.8, 2.5)
	settings_changed.emit()


func set_hold_toggle(enabled: bool) -> void:
	hold_toggle_enabled = enabled
	settings_changed.emit()


func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	settings_changed.emit()


func reset_defaults() -> void:
	cursor_scale = 1.0
	high_contrast = false
	subtitles_enabled = true
	hold_toggle_enabled = false
	reduced_effects = false
	screen_shake_multiplier = 1.0
	settings_changed.emit()
