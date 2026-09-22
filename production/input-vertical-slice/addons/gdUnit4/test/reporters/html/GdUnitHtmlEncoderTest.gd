class_name GdUnitHtmlEncoderTest
extends GdUnitTestSuite


#region plain text
func test_plain_text_is_unchanged() -> void:
	assert_str(GdUnitHtmlEncoder.encode("hello world")).is_equal("hello world")


func test_empty_string_is_unchanged() -> void:
	assert_str(GdUnitHtmlEncoder.encode("")).is_equal("")
#endregion


#region ampersand
func test_ampersand_is_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode("a & b")).is_equal("a &amp; b")


func test_ampersand_is_not_double_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode("&amp;")).is_equal("&amp;amp;")
#endregion


#region less-than / greater-than
func test_less_than_is_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode("Array<int>")).is_equal("Array&lt;int&gt;")


func test_greater_than_is_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode("x > 0")).is_equal("x &gt; 0")
#endregion


#region quotes
func test_double_quote_is_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode('say "hi"')).is_equal("say &quot;hi&quot;")


func test_single_quote_is_encoded() -> void:
	assert_str(GdUnitHtmlEncoder.encode("it's")).is_equal("it&#39;s")
#endregion


#region mixed
func test_all_special_chars_in_one_string() -> void:
	assert_str(GdUnitHtmlEncoder.encode("<a href='x' title=\"y\">a & b</a>")) \
		.is_equal("&lt;a href=&#39;x&#39; title=&quot;y&quot;&gt;a &amp; b&lt;/a&gt;")


func test_multiline_text_is_preserved() -> void:
	assert_str(GdUnitHtmlEncoder.encode("line1\nline2")).is_equal("line1\nline2")
#endregion
