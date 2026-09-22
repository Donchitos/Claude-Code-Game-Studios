@warning_ignore_start("unsafe_method_access")
# GdUnit generated TestSuite
class_name GdUnitTestSuiteTemplatePanelTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/ui/templates/GdUnitTestSuiteTemplatePanel.gd'


func test_show() -> void:
	var template :Variant = spy("res://addons/gdUnit4/src/ui/templates/GdUnitTestSuiteTemplatePanel.tscn")
	scene_runner(template)

	# verify the followup functions are called by _ready()
	verify(template)._ready()
	verify(template).setup_editor_colors()
	verify(template).setup_supported_types()
	verify(template).load_template(GdUnitTestSuiteTemplate.TEMPLATE_ID_GD)
	verify(template).setup_tags_help()


func test_load_template_gd() -> void:
	var runner := scene_runner("res://addons/gdUnit4/src/ui/templates/GdUnitTestSuiteTemplatePanel.tscn")
	runner.invoke("load_template", GdUnitTestSuiteTemplate.TEMPLATE_ID_GD)

	assert_int(runner.get_property("_selected_template")).is_equal(GdUnitTestSuiteTemplate.TEMPLATE_ID_GD)
	assert_str(runner.get_property("_template_editor").text).is_equal(GdUnitTestSuiteTemplate.default_GD_template().replace("\r", ""))


func test_load_template_cs() -> void:
	var runner := scene_runner("res://addons/gdUnit4/src/ui/templates/GdUnitTestSuiteTemplatePanel.tscn")
	runner.invoke("load_template", GdUnitTestSuiteTemplate.TEMPLATE_ID_CS)

	assert_int(runner.get_property("_selected_template")).is_equal(GdUnitTestSuiteTemplate.TEMPLATE_ID_CS)
	assert_str(runner.get_property("_template_editor").text).is_equal(GdUnitTestSuiteTemplate.default_CS_template().replace("\r", ""))
