---
paths:
  - "Source/gameplay/**"
---

# Gameplay Code Rules

- ALL gameplay values MUST come from data (`UDataAsset` / `UDataTable` / `DataRegistry`), NEVER hardcoded
- State machines must use explicit transition tables with documented states (prefer `UStateTree` / Gameplay Tags over ad-hoc `enum` switches)
- Use `DeltaTime` for ALL time-dependent calculations — frame-rate independence is mandatory
- NO direct references to UI code — communicate via events / Gameplay Tag queries / delegates
- Every gameplay system must expose a clear interface (Blueprint-callable boundary defined in the ADR)
- No static singletons for game state — use subsystems (`UGameInstanceSubsystem` / `UWorldSubsystem`) or dependency injection
- Write unit/automation tests for all gameplay logic — separate logic from presentation
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (data-driven, frame-rate independent):

```cpp
// Damage pulled from a UPrimaryDataAsset, never hardcoded
const float Damage = CombatData->BaseDamage * Stats->DamageMultiplier;
const float MoveDelta = Stats->MoveSpeed * DeltaTime; // frame-rate independent
```

**Incorrect** (hardcoded, ignores DeltaTime):

```cpp
const float Damage   = 25.0f;  // VIOLATION: hardcoded gameplay value
const float MoveDelta = 5.0f;  // VIOLATION: not from data, ignores DeltaTime
```
