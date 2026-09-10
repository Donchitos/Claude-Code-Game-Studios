# GdUnit generated TestSuite
class_name GdUnitObjectAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitObjectAssertImpl.gd'


func test_is_equal() -> void:
	assert_object(Mesh.new()).is_equal(Mesh.new())

	assert_failure(func() -> void: assert_object(Mesh.new()).is_equal(Skin.new())) \
		.is_failed()
	assert_failure(func() -> void: assert_object(null).is_equal(Skin.new())) \
		.is_failed() \
		.has_message("Expecting:\n"
			+ " <Skin>\n"
			+ " but was\n"
			+ " '<null>'")


func test_is_not_equal() -> void:
	assert_object(null).is_not_equal(Skin.new())
	assert_object(Mesh.new()).is_not_equal(Skin.new())

	assert_failure(func() -> void: assert_object(Mesh.new()).is_not_equal(Mesh.new())) \
		.is_failed()


func test_is_instanceof() -> void:
	# engine class test
	assert_object(auto_free(Path3D.new())).is_instanceof(Node)
	assert_object(auto_free(Camera3D.new())).is_instanceof(Camera3D)
	# script class test
	assert_object(auto_free(Udo.new())).is_instanceof(Person)
	# inner class test
	assert_object(auto_free(CustomClass.InnerClassA.new())).is_instanceof(Node)
	assert_object(auto_free(CustomClass.InnerClassB.new())).is_instanceof(CustomClass.InnerClassA)

	assert_failure(func() -> void: assert_object(auto_free(Path3D.new())).is_instanceof(Tree)) \
		.is_failed() \
		.has_message("Expected instance of:\n 'Tree'\n But it was 'Path3D'")
	assert_failure(func() -> void: assert_object(null).is_instanceof(Tree)) \
		.is_failed() \
		.has_message("Expected instance of:\n 'Tree'\n But it was '<null>'")


func test_is_valid() -> void:
	assert_object(auto_free(Node.new())).is_valid()
	assert_object(RefCounted.new()).is_valid()

	var freed_obj := Node.new()
	freed_obj.free()
	assert_failure(func() -> void: assert_object(freed_obj).is_valid()) \
		.is_failed() \
		.has_message("Expecting the object is a valid unfreed instance.")
	assert_failure(func() -> void: assert_object(null).is_valid()) \
		.is_failed() \
		.has_message("Expecting the object is a valid unfreed instance.")


func test_is_not_instanceof() -> void:
	assert_object(null).is_not_instanceof(Tree)
	# engine class test
	assert_object(auto_free(Path3D.new())).is_not_instanceof(Tree)
	# script class test
	assert_object(auto_free(City.new())).is_not_instanceof(Person)
	# inner class test
	assert_object(auto_free(CustomClass.InnerClassA.new())).is_not_instanceof(Tree)
	assert_object(auto_free(CustomClass.InnerClassB.new())).is_not_instanceof(CustomClass.InnerClassC)

	assert_failure(func() -> void: assert_object(auto_free(Path3D.new())).is_not_instanceof(Node)) \
		.is_failed() \
		.has_message("Expected not be a instance of <Node>")


func test_is_inheriting() -> void:
	# test on native Godot class
	assert_object(auto_free(TabContainer.new()))\
		.is_inheriting(Container)\
		.is_inheriting(Control)\
		# we need to specify by string name because is an abstract class
		.is_inheriting("CanvasItem")\
		.is_inheriting(Node)\
		.is_inheriting(Object)
	assert_failure(func() -> void:
		assert_object(auto_free(TabContainer.new())).is_inheriting(Node3D)
	).is_failed().has_message("Expected type to inherit from <Node3D>")

	# test on user custom class
	assert_object(auto_free(MyNode.new()))\
		.is_inheriting(Node)\
		.is_inheriting(Object)
	assert_object(auto_free(MyExtendedNode.new()))\
		.is_inheriting(GdUnitObjectAssertImplTest.MyNode)\
		.is_inheriting(Node)\
		.is_inheriting(Object)
	assert_failure(func() -> void:
		assert_object(auto_free(MyExtendedNode.new())).is_inheriting(Node3D)
	).is_failed().has_message("Expected type to inherit from <Node3D>")

	# using not Object type
	assert_failure(func() -> void:
		assert_object([]).is_inheriting(Node)
	).is_failed().has_message("Expected '[]' to inherit from at least Object.")


func test_is_not_inheriting() -> void:
	# test on native Godot class
	assert_object(auto_free(TabContainer.new()))\
		.is_not_inheriting(Node2D)\
		.is_not_inheriting(Node3D)

	assert_failure(func() -> void:
		assert_object(auto_free(TabContainer.new()))\
			.is_not_inheriting(Node2D)\
			.is_not_inheriting(Container)
	).is_failed().has_message("Expected type to not inherit from <Container>")
	# using not Object type
	assert_failure(func() -> void:
		assert_object([]).is_not_inheriting(Node)
	).is_failed().has_message("Expected '[]' to inherit from at least Object.")

func test_is_null() -> void:
	assert_object(null).is_null()

	assert_failure(func() -> void: assert_object(auto_free(Node.new())).is_null()) \
		.is_failed() \
		.starts_with_message("Expecting: '<null>' but was <Node>")


func test_is_not_null() -> void:
	assert_object(auto_free(Node.new())).is_not_null()

	assert_failure(func() -> void: assert_object(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_same() -> void:
	var obj1 :Variant = auto_free(Node.new())
	var obj2 :Variant = obj1
	@warning_ignore("unsafe_method_access")
	var obj3 :Variant = auto_free(obj1.duplicate())
	assert_object(obj1).is_same(obj1)
	assert_object(obj1).is_same(obj2)
	assert_object(obj2).is_same(obj1)

	assert_failure(func() -> void: assert_object(null).is_same(obj1)) \
		.is_failed() \
		.has_message("Expecting:\n"
			+ " <Node>\n"
			+ " to refer to the same object\n"
			+ " '<null>'")
	assert_failure(func() -> void: assert_object(obj1).is_same(obj3)) \
		.is_failed()
	assert_failure(func() -> void: assert_object(obj3).is_same(obj1)) \
		.is_failed()
	assert_failure(func() -> void: assert_object(obj3).is_same(obj2)) \
		.is_failed()


func test_is_not_same() -> void:
	var obj1 :Variant = auto_free(Node.new())
	var obj2 :Variant = obj1
	@warning_ignore("unsafe_method_access")
	var obj3 :Variant = auto_free(obj1.duplicate())
	assert_object(null).is_not_same(obj1)
	assert_object(obj1).is_not_same(obj3)
	assert_object(obj3).is_not_same(obj1)
	assert_object(obj3).is_not_same(obj2)

	assert_failure(func() -> void: assert_object(obj1).is_not_same(obj1)) \
		.is_failed() \
		.has_message("""
			Expecting not same:
			 <Node>"""
			.dedent()
			.trim_prefix("\n"))
	assert_failure(func() -> void: assert_object(obj1).is_not_same(obj2)) \
		.is_failed() \
		.has_message("""
			Expecting not same:
			 <Node>"""
			.dedent()
			.trim_prefix("\n"))
	assert_failure(func() -> void: assert_object(obj2).is_not_same(obj1)) \
		.is_failed() \
		.has_message("""
			Expecting not same:
			 <Node>"""
			.dedent()
			.trim_prefix("\n"))


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_object(1)) \
		.is_failed() \
		.has_message("GdUnitObjectAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_object(1.3)) \
		.is_failed() \
		.has_message("GdUnitObjectAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_object(true)) \
		.is_failed() \
		.has_message("GdUnitObjectAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_object("foo")) \
		.is_failed() \
		.has_message("GdUnitObjectAssert inital error, unexpected type <String>")


func test_override_failure_message() -> void:
	assert_object(assert_object(auto_free(Node.new())).override_failure_message("error")).is_instanceof(GdUnitObjectAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_object(auto_free(Node.new())) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_object(auto_free(Node.new())).append_failure_message("error")).is_instanceof(GdUnitObjectAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_object(auto_free(Node.new())) \
			.append_failure_message("custom failure data") \
			.is_null()) \
		.is_failed() \
		.has_message("""
			Expecting: '<null>' but was <Node>
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_object(null).is_null()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_object(RefCounted.new()).is_null()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_object(null).is_null()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()


class MyNode extends Node:
	pass

class MyExtendedNode extends MyNode:
	pass
