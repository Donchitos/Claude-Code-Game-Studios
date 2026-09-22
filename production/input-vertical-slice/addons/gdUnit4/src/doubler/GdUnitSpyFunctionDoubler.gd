class_name GdUnitSpyFunctionDoubler
extends GdFunctionDoubler


func double(func_descriptor: GdFunctionDescriptor) -> PackedStringArray:
	return GdUnitFunctionDoublerBuilder.new(func_descriptor)\
		.with_verify_block()\
		.build()
