class_name MovementTuning
extends Resource
## Shared, read-only tuning for the solo movement lab. Inject per-instance copies
## when changing values at runtime; assets/data/movement_default.tres is the preset.

@export_group("Locomotion")
@export_range(0.0, 30.0, 0.1) var move_speed: float = 6.0
@export_range(0.0, 100.0, 0.1) var acceleration: float = 32.0
@export_range(0.0, 100.0, 0.1) var deceleration: float = 40.0
@export_range(0.0, 1.0, 0.01) var walk_multiplier: float = 0.4
@export_range(0.0, 100.0, 0.1) var gravity: float = 24.0
@export_range(0.0, 100.0, 0.1) var turn_sharpness: float = 13.2

@export_group("Jump")
## Desired ballistic apex above takeoff; nonpositive height/gravity disables jumping.
@export_range(0.0, 5.0, 0.05) var jump_height: float = 1.0

@export_group("Jump Animation")
## Visual-only controls; they never delay or modify physical takeoff or collision.
@export_range(0.0, 1.0, 0.01) var jump_takeoff_duration: float = 0.10
@export_range(0.0, 1.0, 0.01) var jump_landing_duration: float = 0.16
@export_range(0.0, 0.5, 0.01) var jump_stretch: float = 0.16
@export_range(0.0, 0.5, 0.01) var jump_squash: float = 0.18
@export_range(0.0, 100.0, 0.1) var jump_pose_sharpness: float = 16.0
## Zero disables jump poses without changing physics; one applies the full pose.
@export_range(0.0, 1.0, 0.01) var jump_animation_strength: float = 1.0

@export_group("Camera")
@export_range(0.1, 50.0, 0.1) var camera_height: float = 16.0
@export_range(0.1, 50.0, 0.1) var camera_depth: float = 11.2
@export_range(1.0, 179.0, 0.1) var camera_fov: float = 50.0
@export_range(0.0, 40.0, 0.1) var camera_follow_sharpness: float = 8.0
@export var camera_edge_pan_enabled: bool = true
@export_range(0.0, 15.0, 0.1) var camera_edge_pan: float = 4.0
## Fraction of screen width/height at which the right/bottom edge band begins.
## 0.85 means the outer 15% of each edge; the middle 70% stays neutral.
@export_range(0.5, 0.99, 0.01) var camera_edge_threshold: float = 0.85
