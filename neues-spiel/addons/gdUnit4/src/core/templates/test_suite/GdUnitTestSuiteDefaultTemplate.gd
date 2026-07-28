class_name GdUnitTestSuiteDefaultTemplate
extends RefCounted


const DEFAULT_TEMP_TS_GD ="""
	# GdUnit generated TestSuite
	class_name ${suite_class_name}
	extends GdUnitTestSuite
	@warning_ignore('unused_parameter')
	@warning_ignore('return_value_discarded')

	# TestSuite generated from
	const __source: String = '${source_resource_path}'
"""


const DEFAULT_TEMP_TS_CS = """
	// GdUnit generated TestSuite

	using Godot;
	using GdUnit4;

	namespace ${name_space}
	{
		using static Assertions;
		using static Utils;

		[TestSuite]
		public class ${suite_class_name}
		{
			// TestSuite generated from
			private const string sourceClazzPath = "${source_resource_path}";

		}
	}
"""
