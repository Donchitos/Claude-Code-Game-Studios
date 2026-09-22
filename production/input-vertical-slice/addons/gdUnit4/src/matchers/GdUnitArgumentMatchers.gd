class_name GdUnitArgumentMatchers
extends RefCounted

const TYPE_ANY = TYPE_MAX + 100


static func to_matcher(arguments: Array[Variant], auto_deep_check_mode := false) -> ChainedArgumentMatcher:
	var matchers: Array[Variant] = []
	for arg: Variant in arguments:
		# argument is already a matcher
		if arg is GdUnitArgumentMatcher:
			matchers.append(arg)
		else:
			# pass argument into equals matcher
			matchers.append(EqualsArgumentMatcher.new(arg, auto_deep_check_mode))
	return ChainedArgumentMatcher.new(matchers)


static func any() -> GdUnitArgumentMatcher:
	return  AnyArgumentMatcher.new()


static func by_type(type: int) -> GdUnitArgumentMatcher:
	return AnyBuildInTypeArgumentMatcher.new([type])


static func by_types(types: PackedInt32Array) -> GdUnitArgumentMatcher:
	return AnyBuildInTypeArgumentMatcher.new(types)


static func any_class(clazz: Object) -> GdUnitArgumentMatcher:
	return AnyClazzArgumentMatcher.new(clazz)


static func is_variant_string_matching(value: Variant) -> GdUnitResult:
	if value is String or value is StringName:
		return GdUnitResult.success()
	if value is GdUnitArgumentMatcher:
		if str(value) == "any()" or str(value) == "any_string()":
			return GdUnitResult.success()
		return GdUnitResult.error("Only 'any()' and 'any_string()' argument matchers are allowed!")
	return GdUnitResult.error("Only String or StringName types are allowed!")
