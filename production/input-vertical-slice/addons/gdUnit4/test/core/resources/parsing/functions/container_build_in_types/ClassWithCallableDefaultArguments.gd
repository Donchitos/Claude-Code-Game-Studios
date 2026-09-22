class_name ClassWithCallableDefaultArguments
extends RefCounted


func on_callable_case1(cb: Callable) -> Callable:
	return cb


func on_callable_case2(cb: Callable = Callable()) -> Callable:
	return cb


func on_callable_case3(cb := Callable()) -> Callable:
	return cb


func on_callable_case4(cb := Callable(null, "method_foo")) -> Callable:
	return cb
