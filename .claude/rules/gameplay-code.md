---
paths:
  - "src/gameplay/**"
  - "Assets/**/{Gameplay,gameplay}/**/*.cs"
  - "Source/**/{Gameplay,gameplay}/**/*.{h,cpp}"
---

# Gameplay Code Rules

- ALL gameplay values MUST come from external config/data files, NEVER hardcoded
- Use delta time for ALL time-dependent calculations (frame-rate independence)
- NO direct references to UI code — use events for cross-system communication
  (Godot signals, C# events, Unreal delegates)
- Every gameplay system must implement a clear interface
- State machines must have explicit transition tables with documented states
- Write unit tests for all gameplay logic — separate logic from presentation
- Document which design doc each feature implements in code comments
- No static singletons for game state — use dependency injection

## Examples

**Correct** (data-driven) — Godot:

```gdscript
var damage: float = config.get_value("combat", "base_damage", 10.0)
var speed: float = stats_resource.movement_speed * delta
```

Unity (values from a ScriptableObject):

```csharp
float damage = combatConfig.BaseDamage;
float speed = stats.MovementSpeed * Time.deltaTime;
```

Unreal (values from a data asset):

```cpp
const float Damage = CombatConfig->BaseDamage;
const float Speed = Stats->MovementSpeed * DeltaTime;
```

**Incorrect** (hardcoded):

```gdscript
var damage: float = 25.0   # VIOLATION: hardcoded gameplay value
var speed: float = 5.0      # VIOLATION: not from config, not using delta
```
