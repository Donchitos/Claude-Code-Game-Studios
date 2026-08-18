# Godot Navigation — Quick Reference

Last verified: 2026-02-12 | Engine: Godot 4.6

> **Version note:** this project is pinned to **Godot 4.7**. This file was last verified
> against 4.6 — see `../VERSION.md` and the 4.6 → 4.7 section of `../breaking-changes.md`
> before relying on anything version-sensitive.

## What Changed Since ~4.3 (LLM Cutoff)

### 4.5 Changes
- **Dedicated 2D navigation server**: No longer a proxy to 3D NavigationServer
  - Reduces export binary size for 2D-only games
  - API remains the same for both 2D and 3D

### 4.3 Changes (in training data)
- **`NavigationRegion2D`**: Removed `avoidance_layers` and `constrain_avoidance` properties

## Current API Patterns

### NavigationAgent3D (Preferred for Most Cases)
```gdscript
@onready var nav_agent: NavigationAgent3D = %NavigationAgent3D

func _ready() -> void:
    nav_agent.path_desired_distance = 0.5
    nav_agent.target_desired_distance = 1.0
    nav_agent.velocity_computed.connect(_on_velocity_computed)

func navigate_to(target: Vector3) -> void:
    nav_agent.target_position = target

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var direction: Vector3 = global_position.direction_to(next_pos)
    nav_agent.velocity = direction * move_speed

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity = safe_velocity
    move_and_slide()
```

### NavigationAgent2D
```gdscript
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D

func navigate_to(target: Vector2) -> void:
    nav_agent.target_position = target

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector2 = nav_agent.get_next_path_position()
    var direction: Vector2 = global_position.direction_to(next_pos)
    velocity = direction * move_speed
    move_and_slide()
```

### Low-Level Path Query (3D)
```gdscript
# Direct server query for custom pathfinding logic
var query := NavigationPathQueryParameters3D.new()
query.map = get_world_3d().navigation_map
query.start_position = global_position
query.target_position = target_pos
query.navigation_layers = navigation_layers

var result := NavigationPathQueryResult3D.new()
NavigationServer3D.query_path(query, result)
var path: PackedVector3Array = result.path
```

### Avoidance
```gdscript
# Enable RVO2-based local avoidance
nav_agent.avoidance_enabled = true
nav_agent.radius = 0.5
nav_agent.max_speed = move_speed
nav_agent.neighbor_distance = 10.0

# Use velocity_computed signal for avoidance-safe movement
nav_agent.velocity_computed.connect(_on_velocity_computed)

# Set velocity each frame (avoidance needs this)
nav_agent.velocity = desired_velocity
```

### Navigation Layers
```gdscript
# Use layers to separate walkable areas by agent type
# Layer 1: Ground units
# Layer 2: Flying units
# Layer 3: Swimming units
nav_agent.navigation_layers = 1  # Ground only
nav_agent.navigation_layers = 1 | 2  # Ground + Flying
```

## Common Mistakes
- Calling `get_next_path_position()` without checking `is_navigation_finished()`
- Not setting `velocity` on the agent when avoidance is enabled (required for RVO2)
- Using `NavigationRegion2D.avoidance_layers` (removed in 4.3)
- Forgetting to bake navigation mesh after modifying geometry
- Not setting `navigation_layers` (defaults to all layers)
