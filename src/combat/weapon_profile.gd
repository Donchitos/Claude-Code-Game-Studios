extends Resource
## Data-only weapon behavior; balance can be changed without controller edits.

@export var display_name: String = "Tabanca"
@export var capacity: int = 7
@export var damage: float = 20.0
@export var distance: float = 22.0
@export var shot_interval: float = 0.20
@export var pellets: int = 1
@export var spread_degrees: float = 0.0
@export var moving_spread: float = 1.5
@export var recoil_spread: float = 0.5
@export var spread_recovery: float = 5.0
@export var noise_radius: float = 12.0
@export var stun_duration: float = 0.0
@export var tone_hz: float = 180.0
