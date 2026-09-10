class_name GdUnitSingletonTest
extends GdUnitTestSuite


static var _instance_called := 0

class ExampleSingletonImplementaion extends Object:

	static func instance() -> ExampleSingletonImplementaion:
		return GdUnitSingleton.instance("ExampleSingletonImplementaion", func() -> ExampleSingletonImplementaion:
			GdUnitSingletonTest._instance_called += 1
			return ExampleSingletonImplementaion.new()
		)

func test_instance() -> void:
	var n :Variant = GdUnitSingleton.instance("singelton_test", func() -> Node: return Node.new() )
	assert_object(n).is_instanceof(Node)
	assert_bool(is_instance_valid(n)).is_true()

	# free the singleton
	GdUnitSingleton.unregister("singelton_test")
	assert_bool(is_instance_valid(n)).is_false()


func test_instance_implementaion() -> void:
	assert_bool(Engine.has_meta("ExampleSingletonImplementaion")).is_false()

	var instance1 := ExampleSingletonImplementaion.instance()
	var instance2 := ExampleSingletonImplementaion.instance()

	assert_bool(Engine.has_meta("ExampleSingletonImplementaion")).is_true()
	assert_object(instance1).is_same(instance2)
	assert_int(_instance_called).is_equal(1)

	# finally free it
	GdUnitSingleton.unregister("ExampleSingletonImplementaion")
	assert_bool(Engine.has_meta("ExampleSingletonImplementaion")).is_false()
