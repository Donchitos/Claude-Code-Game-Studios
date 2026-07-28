## Reference/placeholder injected-tier module (ADR-0001 substrate proof).
##
## Exists solely to prove the injected-tier dependency-injection shape
## established by Foundation Spine Story 001: typed [code]@export[/code]
## node-reference dependencies, resolved exclusively via a scene file's
## Inspector in production (or assigned directly after [code]Node.new()[/code]
## in a headless test), with all wiring/validation living in an explicitly
## callable [method setup] -- never in [method _ready].
##
## Concrete Foundation/Core modules (Voxel World, Camera & Input, Building
## System, ...) each implement this same shape in their own epics; this class
## is not one of them and must never gain gameplay behaviour of its own.
class_name ReferenceInjectedModule
extends Node

## First injected-tier dependency slot. Wired via the owning scene's
## Inspector in production; assigned directly to a mock object in headless
## tests. Never read inside [method _ready] -- see [method setup].
@export var dependency_one: Node

## Second injected-tier dependency slot. Same wiring rule as
## [member dependency_one].
@export var dependency_two: Node

## True once [method setup] has completed at least once. Lets callers (and
## tests) confirm the explicit wiring call actually ran, rather than
## inferring it from scene-tree/[method _ready] timing.
var _is_set_up: bool = false


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts each
## [code]@export[/code] dependency was wired before use.
##
## This is the ONLY sanctioned call site for this method's logic: the owning
## root (e.g. [code]GameWorld[/code]) calls it once, after scene-file wiring
## has resolved, and a headless test calls it directly after assigning mocks
## to the [code]@export[/code] properties above -- the exact same code path
## runs in both contexts. Never call this from [method _ready].
func setup() -> void:
	assert(dependency_one != null, "ReferenceInjectedModule.dependency_one not wired")
	assert(dependency_two != null, "ReferenceInjectedModule.dependency_two not wired")
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up
