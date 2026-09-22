class_name CustomClassExtendsCustomClass
extends CustomResourceTestClass

# override
@warning_ignore("untyped_declaration")
func foo2():
	return "foo2 overriden"

func bar2() -> String:
	return bar(23, 42)
