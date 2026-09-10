# example class with inner classes
class_name CustomClass
extends RefCounted


# an inner class
class InnerClassA extends Node:
	var x: Variant

# an inner class inherits form another inner class
class InnerClassB extends InnerClassA:
	var y: Variant

# an inner class
class InnerClassC:

	func foo() -> String:
		return "foo"

class InnerClassD:
	class InnerInnerClassA:
		var x: Variant
