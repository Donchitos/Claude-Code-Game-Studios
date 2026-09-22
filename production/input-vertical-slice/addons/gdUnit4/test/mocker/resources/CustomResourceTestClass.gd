class_name CustomResourceTestClass
extends Resource

func foo() -> String:
	return "foo"

func foo2() -> Variant:
	return "foo2"

func foo_void() -> void:
	pass

func bar(arg1 :int, arg2 :int = 23, name :String = "test") -> String:
	return "%s_%d" % [name, arg1+arg2]

@warning_ignore("untyped_declaration")
func foo5():
	pass
