# GdUnit generated TestSuite
extends GdUnitTestSuite


const PARAMETER_SET_EXAMPLE = """[
		[1, "simple double-quoted string"],
		[2, 'simple single-quoted string'],
		[3, "escape newline\nafter"],
		[4, 'single escape\nnewline'],
		[5, \"\"\"triple\nquoted\"\"\"],
		[6, "braces {and \"inner\" quotes} here"],
		[7, "comma, inside, double, string"],
		[8, 'comma, inside, single, string'],
		[9, "brackets [inside] string"],
		[10, true, false, null],
		[11, 42, 3.14, -7],
		[12, "mixed types", 42, null, true],
		[13, {key: "value", other: 123}],
		[14, ["nested", "array", 99]],
		[15, "
			real multiline
			block string
			"],
		[16, Node2D, Vector2(1, 2)],
		[17, "tab\there and\there"],
		[
			18,
			"badly formatted element",
			true,
			42
		],
		[19, \"\"\"second\ntriple\nquoted\"\"\", false],
		[20, {Node2D: "ER,ROR"}, ["a", "b"]],
		]"""


func test_parse_parameter_single_row_array() -> void:
	var test_parameters := """[
		[1, "flowchart TD\nid>This is a  flag shaped node]"],
		[
			2,
			"flowchart TD\nid(((This is a\tdouble circle node)))"
		],
		[3,
			"flowchart TD\nid((This is a circular node))"],
		[
			4, "flowchart TD\nid>This is a flag shaped node]"
		],
		[5, "flowchart TD\nid{'This is a rhombus node'}"],
		[6, 'flowchart TD\nid((This is a circular node))'],
		[7, 'flowchart TD\nid>This is a flag shaped node]'], [8, 'flowchart TD\nid{"This is a rhombus node"}'],
		[9, \"\"\"
			flowchart TD
			id{"This is a  rhombus node"}
			\"\"\"]
		]"""

	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""[1, "flowchart TD\nid>This is a  flag shaped node]"]""",
		"""[2, "flowchart TD\nid(((This is a\tdouble circle node)))"]""",
		"""[3, "flowchart TD\nid((This is a circular node))"]""",
		"""[4, "flowchart TD\nid>This is a flag shaped node]"]""",
		"""[5, "flowchart TD\nid{'This is a rhombus node'}"]""",
		"""[6, 'flowchart TD\nid((This is a circular node))']""",
		"""[7, 'flowchart TD\nid>This is a flag shaped node]']""",
		"""[8, 'flowchart TD\nid{"This is a rhombus node"}']""",
		"""[9, \"\"\"\nflowchart TD\nid{"This is a  rhombus node"}\n\"\"\"]"""
		]
	)


func test_parse_parameter_multi_row_arrays() -> void:
	var test_parameters := """[
		["test_a", null, "LOG", {}],
		[
			"test_b",
			Node2D,
			null,
			{Node2D: "ER,ROR"}
		],
		[
			"test_c",
			Node2D,
			"LOG",
			{Node2D: "LOG"}
		]
	]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""["test_a", null, "LOG", {}]""",
		"""["test_b", Node2D, null, {Node2D: "ER,ROR"}]""",
		"""["test_c", Node2D, "LOG", {Node2D: "LOG"}]"""
		]
	)


func test_parse_parameter_bad_formatted() -> void:
	var test_parameters := """[
		["test_a", null, "LOG", {}],
		[
				"test_b",
			Node2D,
			null,
			{Node2D: "ER,ROR"}
		],
			[
			"test_c",
			Node2D,
			"LOG",
			{Node2D: "LOG 1"}
		]

			]
		"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""["test_a", null, "LOG", {}]""",
		"""["test_b", Node2D, null, {Node2D: "ER,ROR"}]""",
		"""["test_c", Node2D, "LOG", {Node2D: "LOG 1"}]"""
		]
	)


func test_parse_argument_ends_with_additional_comma() -> void:
	var test_parameters := """
			[
			[true, 'bool'],
			[42, 'int'],
			['foo', 'String'],
		]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""[true, 'bool']""",
		"""[42, 'int']""",
		"""['foo', 'String']"""
		]
	)


func test_parse_parameter_is_callable() -> void:
	var test_parameters := "_test_args()"

	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).is_empty()


func test_parse_parameter_property_references() -> void:
	var test_parameters := "[_data1, _data2]"

	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly(["_data1", "_data2"])


func test_parse_parameter_with_strings_contaning_newlines() -> void:
	assert_array(GdFunctionArgument._parse_parameters("[]"))\
		.is_empty()
	assert_array(GdFunctionArgument._parse_parameters("[_data1, _data2]"))\
		.contains_exactly("_data1", "_data2")

	var test_parameters := """[
		[8, 'flowchart TD\nid{"This is a rhombus node"}'],
		[9, "
			flowchart TD
			id{"This is a rhombus node"}
			"],
		]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets())\
		.contains_exactly(
			"""[8, 'flowchart TD\nid{"This is a rhombus node"}']""",
			"""[9, "\nflowchart TD\nid{"This is a rhombus node"}\n"]""")


func test_parse_parameter_array_literal_with_callable_call() -> void:
	var test_parameters := """[
			parameters_as_array("abc", "d,ef", "foo()")
			]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""parameters_as_array("abc", "d,ef", "foo()")"""
		]
	)


func test_parse_parameter_array_literal_with_multiple_callable_calls() -> void:
	var test_parameters := """[parameters_as_array("abc", "d,ef"), parameters_as_array("x", "y,z")]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""parameters_as_array("abc", "d,ef")""",
		"""parameters_as_array("x", "y,z")"""
		]
	)


# https://github.com/godot-gdunit-labs/gdUnit4/issues/1309
# a literal quote of the *other* quote type, mixed with an escaped quote of the *same*
# quote type, must not corrupt the quote/bracket tracking and merge separate call elements
func test_parse_parameter_array_literal_with_escaped_quotes() -> void:
	var test_parameters := """[parameters_as_array(2, 'y"yy', "d\\"ef"), parameters_as_array(3, "z'zz", 'd\\'ef')]"""
	var fa := GdFunctionArgument.new("test_parameters", TYPE_STRING, test_parameters)
	assert_array(fa.parameter_sets()).contains_exactly([
		"""parameters_as_array(2, 'y"yy', "d\\"ef")""",
		"""parameters_as_array(3, "z'zz", 'd\\'ef')"""
		]
	)


func test_parse_parameter_set() -> void:
	var result := GdFunctionArgument._parse_parameters(PARAMETER_SET_EXAMPLE)
	assert_array(result).contains_exactly([
		"""[1, "simple double-quoted string"]""",
		"""[2, 'simple single-quoted string']""",
		"""[3, "escape newline\nafter"]""",
		"""[4, 'single escape\nnewline']""",
		"""[5, \"\"\"triple\nquoted\"\"\"]""",
		"""[6, "braces {and "inner" quotes} here"]""",
		"""[7, "comma, inside, double, string"]""",
		"""[8, 'comma, inside, single, string']""",
		"""[9, "brackets [inside] string"]""",
		"""[10, true, false, null]""",
		"""[11, 42, 3.14, -7]""",
		"""[12, "mixed types", 42, null, true]""",
		"""[13, {key: "value", other: 123}]""",
		"""[14, ["nested", "array", 99]]""",
		"""[15, "\nreal multiline\nblock string\n"]""",
		"""[16, Node2D, Vector2(1, 2)]""",
		"""[17, "tab\there and\there"]""",
		"""[18, "badly formatted element", true, 42]""",
		"""[19, \"\"\"second\ntriple\nquoted\"\"\", false]""",
		"""[20, {Node2D: "ER,ROR"}, ["a", "b"]]"""
	])


#region performance

func test_parse_parameters_performance() -> void:
	const ITERATIONS := 10000

	var t0 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		GdFunctionArgument._parse_parameters(PARAMETER_SET_EXAMPLE)

	var elapsed_time := Time.get_ticks_usec() - t0

	@warning_ignore_start("integer_division")
	prints("--- _parse_parameters:overall performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(200)
	@warning_ignore_restore("integer_division")
#endregion
