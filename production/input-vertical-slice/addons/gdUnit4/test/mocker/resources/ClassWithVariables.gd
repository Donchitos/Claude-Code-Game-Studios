@tool
class_name ClassWithVariables
extends Node

enum{
	A,
	B,
	C
}

enum ETYPE 	{
	EA,
	EB
	}

# Declare member variables here. Examples:
var a := 2
var b := "text"

# Declare some const variables
const T1 = 1

const T2 = 2

signal source_changed( text:String )

@onready var name_label := load("res://addons/gdUnit4/test/mocker/resources/ClassWithNameA.gd")

@export var path: NodePath = ".."

class ClassA:
	var x := 1
	# some comment
	func foo()->String:
		return ""


func foo(_value :int = T1) -> void:
	var _c := str(a) + b
	pass
