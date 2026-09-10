# GdUnit generated TestSuite
extends GdUnitTestSuite


#region is_known_constant
func test_is_known_constant_resolves_vector_constants() -> void:
	assert_bool(GdBuiltinConstants.is_known_constant("Vector2", "Vector2.ONE")).is_true()
	assert_bool(GdBuiltinConstants.is_known_constant("Vector3", "Vector3.INF")).is_true()
	assert_bool(GdBuiltinConstants.is_known_constant("Vector4i", "Vector4i.MAX")).is_true()


func test_is_known_constant_resolves_color_constants_without_manual_mapping() -> void:
	assert_bool(GdBuiltinConstants.is_known_constant("Color", "Color.RED")).is_true()
	assert_bool(GdBuiltinConstants.is_known_constant("Color", "Color.WEB_GRAY")).is_true()


func test_is_known_constant_rejects_unsupported_type() -> void:
	assert_bool(GdBuiltinConstants.is_known_constant("String", "String.NOPE")).is_false()
	assert_bool(GdBuiltinConstants.is_known_constant("Foo", "Foo.BAR")).is_false()
#endregion

#region value_of
func test_value_of_returns_resolved_value() -> void:
	assert_bool(GdBuiltinConstants.is_known_constant("Vector2", "Vector2.ONE")).is_true()
	assert_object(GdBuiltinConstants.value_of("Vector2.ONE")).is_equal(Vector2.ONE)

	assert_bool(GdBuiltinConstants.is_known_constant("Color", "Color.RED")).is_true()
	assert_object(GdBuiltinConstants.value_of("Color.RED")).is_equal(Color.RED)
#endregion


func test_get_ordinal_value() -> void:
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_NIL")).is_equal(TYPE_NIL)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_BOOL")).is_equal(TYPE_BOOL)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_INT")).is_equal(TYPE_INT)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_FLOAT")).is_equal(TYPE_FLOAT)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_STRING")).is_equal(TYPE_STRING)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR2")).is_equal(TYPE_VECTOR2)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR2I")).is_equal(TYPE_VECTOR2I)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_RECT2")).is_equal(TYPE_RECT2)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_RECT2I")).is_equal(TYPE_RECT2I)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR3")).is_equal(TYPE_VECTOR3)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR3I")).is_equal(TYPE_VECTOR3I)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_TRANSFORM2D")).is_equal(TYPE_TRANSFORM2D)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR4")).is_equal(TYPE_VECTOR4)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_VECTOR4I")).is_equal(TYPE_VECTOR4I)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PLANE")).is_equal(TYPE_PLANE)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_QUATERNION")).is_equal(TYPE_QUATERNION)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_AABB")).is_equal(TYPE_AABB)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_BASIS")).is_equal(TYPE_BASIS)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_TRANSFORM3D")).is_equal(TYPE_TRANSFORM3D)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PROJECTION")).is_equal(TYPE_PROJECTION)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_COLOR")).is_equal(TYPE_COLOR)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_STRING_NAME")).is_equal(TYPE_STRING_NAME)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_NODE_PATH")).is_equal(TYPE_NODE_PATH)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_RID")).is_equal(TYPE_RID)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_OBJECT")).is_equal(TYPE_OBJECT)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_CALLABLE")).is_equal(TYPE_CALLABLE)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_SIGNAL")).is_equal(TYPE_SIGNAL)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_DICTIONARY")).is_equal(TYPE_DICTIONARY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_ARRAY")).is_equal(TYPE_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_BYTE_ARRAY")).is_equal(TYPE_PACKED_BYTE_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_INT32_ARRAY")).is_equal(TYPE_PACKED_INT32_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_INT64_ARRAY")).is_equal(TYPE_PACKED_INT64_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_FLOAT32_ARRAY")).is_equal(TYPE_PACKED_FLOAT32_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_FLOAT64_ARRAY")).is_equal(TYPE_PACKED_FLOAT64_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_STRING_ARRAY")).is_equal(TYPE_PACKED_STRING_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_VECTOR2_ARRAY")).is_equal(TYPE_PACKED_VECTOR2_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_VECTOR3_ARRAY")).is_equal(TYPE_PACKED_VECTOR3_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_COLOR_ARRAY")).is_equal(TYPE_PACKED_COLOR_ARRAY)
	assert_int(GdBuiltinConstants.to_ordinal_value("TYPE_PACKED_VECTOR4_ARRAY")).is_equal(TYPE_PACKED_VECTOR4_ARRAY)
