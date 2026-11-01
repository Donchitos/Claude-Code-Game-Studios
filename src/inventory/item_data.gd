class_name ItemData
extends Resource
## Data resource defining inventory items across 5 Sector 9 categories:
## Tüketim (Consumption), Saldırı (Attack), Yardımcı (Utility), Modül (Module), Garip (Strange).

enum Category {
	CONSUMPTION,
	ATTACK,
	UTILITY,
	MODULE,
	STRANGE,
}

@export var id: String = ""
@export var item_name: String = ""
@export var category: Category = Category.CONSUMPTION
@export var max_stack: int = 4
@export var effect_value: float = 25.0
@export var icon: String = "📦"
@export var description: String = ""
