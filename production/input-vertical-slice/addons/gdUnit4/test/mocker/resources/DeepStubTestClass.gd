class_name DeepStubTestClass

class XShape:
	var _shape : Shape3D = BoxShape3D.new()

	func get_shape() -> Shape3D:
		return _shape


var _shape :XShape

func add(shape :XShape) -> void:
	_shape = shape

func validate() -> bool:
	return _shape.get_shape().get_margin() == 0.0
