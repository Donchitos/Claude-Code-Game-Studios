class_name GdUnitMockFunctionDoubler
extends GdFunctionDoubler


func double(func_descriptor: GdFunctionDescriptor) -> PackedStringArray:
	return GdUnitFunctionDoublerBuilder.new(func_descriptor)\
		.with_prepare_block()\
		.with_verify_block()\
		.with_mocked_return_value()\
		.build()
