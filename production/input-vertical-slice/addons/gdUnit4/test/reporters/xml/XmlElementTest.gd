# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name XmlElementTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/report/XmlElement.gd'


func test_attribute() -> void:
	var element := XmlElement.new("testsuites")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "foo")
	var expected :="""
		<testsuites id="1" name="foo">
		</testsuites>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(element.to_xml()).is_equal(expected)
	element.dispose()

func test_empty() -> void:
	var element := XmlElement.new("testsuites")
	var expected := """
		<testsuites>
		</testsuites>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(element.to_xml()).is_equal(expected)
	element.dispose()


func test_add_child() -> void:
	var child := XmlElement.new("foo")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "foo")
	var element := XmlElement.new("bar")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar")\
		.add_child(child)
	var expected := """
		<bar id="1" name="bar">
			<foo id="1" name="foo">
			</foo>
		</bar>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(element.to_xml()).is_equal(expected)
	element.dispose()


func test_add_childs() -> void:
	var child_a := XmlElement.new("foo_a")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, 1)\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "foo_a")
	var child_b := XmlElement.new("foo_b")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, 2)\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "foo_b")
	var element := XmlElement.new("bar")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar")\
		.add_childs([child_a, child_b])
	var expected := """
		<bar id="1" name="bar">
			<foo_a id="1" name="foo_a">
			</foo_a>
			<foo_b id="2" name="foo_b">
			</foo_b>
		</bar>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(element.to_xml()).is_equal(expected)
	element.dispose()


func test_add_text() -> void:
	var element := XmlElement.new("testsuites")\
		.text("This is a message")
	var expected := """
		<testsuites>
		<![CDATA[
		This is a message
		]]>
		</testsuites>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(element.to_xml()).is_equal(expected)
	element.dispose()


func test_complex_example() -> void:
	var testsuite1 := XmlElement.new("testsuite")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar")
	for test_case :int in [1,2,3,4,5]:
		var test := XmlElement.new("testcase")\
			.attribute(JUnitXmlReportWriter.ATTR_ID, str(test_case))\
			.attribute(JUnitXmlReportWriter.ATTR_NAME, "test_case_%d" % test_case)
		testsuite1.add_child(test)
	var testsuite2 := XmlElement.new("testsuite")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "2")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar2")
	for test_case :int in [1,2,3]:
		var test := XmlElement.new("testcase")\
			.attribute(JUnitXmlReportWriter.ATTR_ID, str(test_case))\
			.attribute(JUnitXmlReportWriter.ATTR_NAME, "test_case_%d" % test_case)
		if test_case == 2:
			var failure := XmlElement.new("failure")\
				.attribute(JUnitXmlReportWriter.ATTR_MESSAGE, "test_case.gd:12")\
				.attribute(JUnitXmlReportWriter.ATTR_TYPE, "FAILURE")\
				.text("This is a failure\nExpecting true but was false\n")
			test.add_child(failure)
		testsuite2.add_child(test)
	var root := XmlElement.new("testsuites")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "ID-XXX")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "report_foo")\
		.attribute(JUnitXmlReportWriter.ATTR_TESTS, 42)\
		.attribute(JUnitXmlReportWriter.ATTR_FAILURES, 1)\
		.attribute(JUnitXmlReportWriter.ATTR_TIME, "1.22")\
		.add_childs([testsuite1, testsuite2])
	var expected := """
		<testsuites id="ID-XXX" name="report_foo" tests="42" failures="1" time="1.22">
			<testsuite id="1" name="bar">
				<testcase id="1" name="test_case_1">
				</testcase>
				<testcase id="2" name="test_case_2">
				</testcase>
				<testcase id="3" name="test_case_3">
				</testcase>
				<testcase id="4" name="test_case_4">
				</testcase>
				<testcase id="5" name="test_case_5">
				</testcase>
			</testsuite>
			<testsuite id="2" name="bar2">
				<testcase id="1" name="test_case_1">
				</testcase>
				<testcase id="2" name="test_case_2">
					<failure message="test_case.gd:12" type="FAILURE">
		<![CDATA[
		This is a failure
		Expecting true but was false
		]]>
					</failure>
				</testcase>
				<testcase id="3" name="test_case_3">
				</testcase>
			</testsuite>
		</testsuites>
		""".dedent().trim_prefix("\n").replace("\r", "")
	assert_str(root.to_xml()).is_equal(expected)
	root.dispose()


func test_dispose() -> void:
	var testsuite1 := XmlElement.new("testsuite")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "1")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar")
	var testsuite1_expected_tests := Array()
	for test_case :int in [1,2,3,4,5]:
		var test := XmlElement.new("testcase")\
			.attribute(JUnitXmlReportWriter.ATTR_ID, str(test_case))\
			.attribute(JUnitXmlReportWriter.ATTR_NAME, "test_case_%d" % test_case)
		testsuite1.add_child(test)
		testsuite1_expected_tests.append(test)
	var testsuite2 := XmlElement.new("testsuite")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "2")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "bar2")
	var testsuite2_expected_tests := Array()
	for test_case :int in [1,2,3]:
		var test := XmlElement.new("testcase")\
			.attribute(JUnitXmlReportWriter.ATTR_ID, str(test_case))\
			.attribute(JUnitXmlReportWriter.ATTR_NAME, "test_case_%d" % test_case)
		testsuite2_expected_tests.append(test)
		if test_case == 2:
			var failure := XmlElement.new("failure")\
				.attribute(JUnitXmlReportWriter.ATTR_MESSAGE, "test_case.gd:12")\
				.attribute(JUnitXmlReportWriter.ATTR_TYPE, "FAILURE")\
				.text("This is a failure\nExpecting true but was false\n")
			test.add_child(failure)
		testsuite2.add_child(test)
	var root := XmlElement.new("testsuites")\
		.attribute(JUnitXmlReportWriter.ATTR_ID, "ID-XXX")\
		.attribute(JUnitXmlReportWriter.ATTR_NAME, "report_foo")\
		.attribute(JUnitXmlReportWriter.ATTR_TESTS, 42)\
		.attribute(JUnitXmlReportWriter.ATTR_FAILURES, 1)\
		.attribute(JUnitXmlReportWriter.ATTR_TIME, "1.22")\
		.add_childs([testsuite1, testsuite2])

	assert_that(root._parent).is_null()
	assert_array(root._childs).contains_exactly([testsuite1, testsuite2])
	assert_dict(root._attributes).has_size(5)

	assert_that(testsuite1._parent).is_equal(root)
	assert_array(testsuite1._childs).contains_exactly(testsuite1_expected_tests)
	assert_dict(testsuite1._attributes).has_size(2)
	testsuite1_expected_tests.clear()

	assert_that(testsuite2._parent).is_equal(root)
	assert_array(testsuite2._childs).contains_exactly(testsuite2_expected_tests)
	assert_dict(testsuite2._attributes).has_size(2)
	testsuite2_expected_tests.clear()

	# free all references
	root.dispose()
	assert_that(root._parent).is_null()
	assert_array(root._childs).is_empty()
	assert_dict(root._attributes).is_empty()

	assert_that(testsuite1._parent).is_null()
	assert_array(testsuite1._childs).is_empty()
	assert_dict(testsuite1._attributes).is_empty()

	assert_that(testsuite2._parent).is_null()
	assert_array(testsuite2._childs).is_empty()
	assert_dict(testsuite2._attributes).is_empty()
