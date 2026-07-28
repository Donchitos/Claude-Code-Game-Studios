## Authoring-time item schema (ADR-0006 two-type split, private half).
##
## Freely [code]@export[/code]-editable [Resource] designers author via the
## Inspector ([code].tres[/code] files under [code]res://data/items/[/code],
## matching ADR-0002's authoring idiom). Nothing outside Resource & Item
## Database's own implementation may hold a direct reference to this type --
## gameplay code queries the public, getter-only [ItemDefinition] view
## instead (see that class).
##
## Field set is the full RID schema (GDD
## [code]design/gdd/resource-item-database.md[/code] AC2), including the
## 2026-07-23 [member footprint] addition for multi-cell furniture.
## Boot-time validation of these fields (non-null checks, cross-value
## invariants) is intentionally NOT implemented here -- Stories
## 004/005/006/008 own that pipeline; this class is schema only.
class_name ItemDefinitionResource
extends Resource

## Stable opaque identifier other systems reference by (never a direct
## Resource reference -- cross-system references are opaque string ids only).
@export var id: StringName = &""

## Designer/UI-facing label.
@export var display_name: String = ""

## Broad item classification (e.g. [code]&"block"[/code], [code]&"furniture"[/code]).
@export var category: StringName = &""

## Material grouping used for crafting/hauling rules.
@export var material_family: StringName = &""

## Tier/quality rank within its material family.
@export var tier: int = 0

## Typed mesh reference for ghost-preview and MeshLibrary population
## (ADR-0006 Decision §3) -- NEVER a path string.
@export var visual_asset: Mesh = null

## Whether multiple units of this item can occupy one inventory/storage slot.
@export var stackable: bool = false

## Maximum units per stack when [member stackable] is true.
@export var max_stack_size: int = 1

## Whether villagers can haul this item between storage locations.
@export var haulable: bool = false

## Storage bucket this item sorts into (e.g. [code]&"raw_material"[/code],
## [code]&"food"[/code]).
@export var storage_category: StringName = &""

## Footprint in whole cells for multi-cell furniture (e.g. a bed spans
## [code]Vector2i(1, 2)[/code]). Stored structurally now -- its validation
## lands in Story 008.
@export var footprint: Vector2i = Vector2i(1, 1)
