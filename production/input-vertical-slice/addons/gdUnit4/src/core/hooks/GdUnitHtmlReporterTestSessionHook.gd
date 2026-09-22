class_name GdUnitHtmlReporterTestSessionHook
extends GdUnitBaseReporterTestSessionHook

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


func _init() -> void:
	super(GdUnitHtmlReportWriter.new(), "GdUnitHtmlTestReporter", "The Html test reporting hook.", GdUnitTools.richtext_normalize)
	set_meta("SYSTEM_HOOK", true)
