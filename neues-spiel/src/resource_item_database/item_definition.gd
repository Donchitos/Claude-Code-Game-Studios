## Public, getter-only query view over one [ItemDefinitionResource]
## (ADR-0006 two-type split, public half).
##
## [code]get_by_id()[/code] (Story 003) constructs a FRESH [ItemDefinition]
## per call, wrapping -- never copying -- the same stored
## [ItemDefinitionResource]. This class has zero setters and zero writable
## [code]var[/code]s anywhere in its public surface: every idiomatic
## mutation path (property assignment, method call) is closed by
## construction, not by convention.
##
## Documented residual risk (ADR-0006, NOT closed by this class and
## deliberately NOT unit-tested per this story's QA plan): GDScript's
## generic [method Object.get]/[method Object.set] reflection access can
## still reach [member _source] by key string despite the underscore
## convention and lack of an exposed getter for it. This guarantee covers
## accidental/idiomatic misuse, not deliberate reflection-based bypass.
class_name ItemDefinition
extends RefCounted

## The wrapped resource. Never exposed -- there is deliberately no getter
## for this field itself, only for its individual sub-fields below.
var _source: ItemDefinitionResource


## Wraps [param source]. Does not duplicate it -- see class doc comment.
func _init(source: ItemDefinitionResource) -> void:
	_source = source


## Returns the wrapped definition's stable opaque id.
func get_id() -> StringName:
	return _source.id


## Returns the wrapped definition's designer/UI-facing label.
func get_display_name() -> String:
	return _source.display_name


## Returns the wrapped definition's broad classification.
func get_category() -> StringName:
	return _source.category


## Returns the wrapped definition's material grouping.
func get_material_family() -> StringName:
	return _source.material_family


## Returns the wrapped definition's tier/quality rank.
func get_tier() -> int:
	return _source.tier


## Returns the wrapped definition's typed mesh reference.
func get_visual_asset() -> Mesh:
	return _source.visual_asset


## Returns whether the wrapped definition is stackable.
func get_stackable() -> bool:
	return _source.stackable


## Returns the wrapped definition's maximum stack size.
func get_max_stack_size() -> int:
	return _source.max_stack_size


## Returns whether the wrapped definition is haulable.
func get_haulable() -> bool:
	return _source.haulable


## Returns the wrapped definition's storage bucket.
func get_storage_category() -> StringName:
	return _source.storage_category


## Returns the wrapped definition's multi-cell footprint.
func get_footprint() -> Vector2i:
	return _source.footprint
