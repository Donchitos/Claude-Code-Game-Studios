class_name OverridenGetClassTestClass
extends Resource


@warning_ignore("native_method_override")
func get_class() -> String:
	return "OverridenGetClassTestClass"

func foo() -> String:
	prints("foo")
	return "foo"
