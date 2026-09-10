class_name ClassWithEnumReturnTypes
extends Resource


class InnerClass:
	enum TEST_ENUM { FOO = 111, BAR = 222 }

enum TEST_ENUM { FOO = 1, BAR = 2 }

const NOT_AN_ENUM := 1

const X := { FOO=1, BAR=2 }


func get_enum() -> TEST_ENUM:
	return TEST_ENUM.FOO


# function signature with an external enum reference
func get_external_class_enum() -> CustomEnums.TEST_ENUM:
	return CustomEnums.TEST_ENUM.FOO


# function signature with an inner class enum reference
func get_inner_class_enum() -> InnerClass.TEST_ENUM:
	return InnerClass.TEST_ENUM.FOO
