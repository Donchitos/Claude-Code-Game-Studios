# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name JUnitXmlReportWriterTest
extends GdUnitTestSuite


func test_to_time() -> void:
	assert_str(JUnitXmlReportWriter.to_time(0)).is_equal("0.000")
	assert_str(JUnitXmlReportWriter.to_time(1)).is_equal("0.001")
	assert_str(JUnitXmlReportWriter.to_time(10)).is_equal("0.010")
	assert_str(JUnitXmlReportWriter.to_time(100)).is_equal("0.100")
	assert_str(JUnitXmlReportWriter.to_time(1000)).is_equal("1.000")
	assert_str(JUnitXmlReportWriter.to_time(10123)).is_equal("10.123")


func test_to_type() -> void:
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.SUCCESS)).is_equal("SUCCESS")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.WARN)).is_equal("WARN")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.FAILURE)).is_equal("FAILURE")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.ORPHAN)).is_equal("ORPHAN")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.TERMINATED)).is_equal("TERMINATED")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.INTERUPTED)).is_equal("INTERUPTED")
	assert_str(JUnitXmlReportWriter.to_type(GdUnitReport.ABORT)).is_equal("ABORT")
	assert_str(JUnitXmlReportWriter.to_type(1000)).is_equal("UNKNOWN")
