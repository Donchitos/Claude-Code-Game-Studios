---
paths:
  - "Source/core/**"
---

# Engine Code Rules

- ZERO allocations in hot paths (Tick / physics / rendering) — pre-allocate, pool, reuse buffers
- Engine code must NEVER depend on gameplay code (strict dependency direction: `Source/core` <- `Source/gameplay`)
- All engine APIs must be thread-safe OR explicitly documented as single-thread-only (GameThread / Async)
- Profile before AND after every optimization — record the measured numbers in the PR/ADR
- Use RAII / deterministic cleanup (`TUniquePtr`, `TStrongObjectPtr`, `FScopedReadLock`) for all resources
- Every public API must carry a usage example in its doc comment
- Changes to public interfaces require a deprecation period (`UE_DEPRECATED` macro) + migration guide
- All engine subsystems must support graceful degradation (soft fail, never crash the game thread)
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (zero-alloc hot path in UE C++):

```cpp
// Pre-allocated TArray reused each frame — no per-frame allocation
TArray<AActor*> NearbyCache;

void UEnemySpatialSubsystem::Tick(float DeltaTime)
{
    NearbyCache.Reset(); // Reuse buffer, do not reallocate
    SpatialGrid.QueryRadius(GetOwner()->GetActorLocation(), QueryRadius, NearbyCache);
}
```

**Incorrect** (allocating in hot path):

```cpp
void UEnemySpatialSubsystem::Tick(float DeltaTime)
{
    TArray<AActor*> Nearby;                       // VIOLATION: allocates every frame
    Nearby = GetAllActorsOfClass(GetWorld());     // VIOLATION: full-scene query every frame
}
```
