# Godot Navigation — Quick Reference
# Godot 导航 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

### 4.7 Changes
### 4.7 变更
- **No navigation-specific changes** are listed in the 4.7 migration guide (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- 4.7 迁移指南中**未列出导航相关的变更**（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）

### 4.5 Changes
### 4.5 变更
- **Dedicated 2D navigation server**: No longer a proxy to 3D NavigationServer
- **专用 2D 导航服务器**：不再是 3D NavigationServer 的代理
  - Reduces export binary size for 2D-only games
  - 减小纯 2D 游戏的导出二进制体积
  - API remains the same for both 2D and 3D
  - 2D 和 3D 的 API 保持不变

### 4.3 Changes (in training data)
### 4.3 变更（在训练数据中）
- **`NavigationRegion2D`**: Removed `avoidance_layers` and `constrain_avoidance` properties
- **`NavigationRegion2D`**：移除了 `avoidance_layers` 和 `constrain_avoidance` 属性

## Current API Patterns
## 当前 API 模式

### NavigationAgent3D (Preferred for Most Cases)
### NavigationAgent3D（多数情况下的首选）
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
### 底层路径查询（3D）
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
### 避障
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
### 导航层
```gdscript
# Use layers to separate walkable areas by agent type
# Layer 1: Ground units
# Layer 2: Flying units
# Layer 3: Swimming units
nav_agent.navigation_layers = 1  # Ground only
nav_agent.navigation_layers = 1 | 2  # Ground + Flying
```

## Common Mistakes
## 常见错误
- Calling `get_next_path_position()` without checking `is_navigation_finished()`
- 未检查 `is_navigation_finished()` 就调用 `get_next_path_position()`
- Not setting `velocity` on the agent when avoidance is enabled (required for RVO2)
- 启用避障时未在代理上设置 `velocity`（RVO2 需要此设置）
- Using `NavigationRegion2D.avoidance_layers` (removed in 4.3)
- 使用 `NavigationRegion2D.avoidance_layers`（4.3 中已移除）
- Forgetting to bake navigation mesh after modifying geometry
- 修改几何体后忘记烘焙导航网格
- Not setting `navigation_layers` (defaults to all layers)
- 未设置 `navigation_layers`（默认使用所有层）
