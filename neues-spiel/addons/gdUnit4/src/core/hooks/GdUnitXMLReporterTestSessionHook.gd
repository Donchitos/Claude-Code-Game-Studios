class_name GdUnitXMLReporterTestSessionHook
extends GdUnitBaseReporterTestSessionHook


func _init() -> void:
	super(JUnitXmlReportWriter.new(), "GdUnitXMLTestReporter", "The JUnit XML test reporting hook.", convert_report_message)
	set_meta("SYSTEM_HOOK", true)


func convert_report_message(value: String) -> String:
	return value
