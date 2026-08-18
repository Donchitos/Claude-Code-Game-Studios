# Unreal Engine 5.7 — Deprecated APIs

**Last verified:** 2026-02-13 (against UE 5.7)

> **Version note:** this project is pinned to **UE 5.8**. This file was last verified
> against 5.7 and has not been re-checked for 5.8 changes — see `VERSION.md` and the
> 5.7 → 5.8 section of `breaking-changes.md`.

Quick lookup table for deprecated APIs and their replacements.
Format: **Don't use X** → **Use Y instead**

---

## Input

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `InputComponent->BindAction()` | Enhanced Input `BindAction()` | New input system |
| `InputComponent->BindAxis()` | Enhanced Input `BindAxis()` | New input system |
| `PlayerController->GetInputAxisValue()` | Enhanced Input Action Values | New input system |

**Migration:** Install Enhanced Input plugin, create Input Actions and Input Mapping Contexts.

---

## Rendering

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Legacy material nodes | Substrate material nodes | Substrate is production-ready in 5.7 |
| Forward shading (default) | Deferred + Lumen | Lumen is default in UE5 |
| Old lighting workflow | Lumen Global Illumination | Real-time GI |

---

## World Building

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| UE4 World Composition | World Partition (UE5) | Streaming large worlds |
| Level Streaming Volumes | World Partition Data Layers | Better level streaming |

---

## Animation

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Old animation retargeting | IK Rig + IK Retargeter | UE5 retargeting system |
| Legacy control rig | Control Rig 2.0 | Production-ready rigging |

---

## Gameplay

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `UGameplayStatics::LoadStreamLevel()` | World Partition streaming | Use Data Layers |
| Hardcoded input bindings | Enhanced Input system | Rebindable, modular input |

---

## Niagara (VFX)

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Cascade particle system | Niagara | Cascade is fully deprecated |

---

## Audio

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Old audio mixer | MetaSounds | Procedural audio system |
| Sound Cue (for complex logic) | MetaSounds | More powerful, node-based |

---

## Networking

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `DOREPLIFETIME()` (basic) | `DOREPLIFETIME_CONDITION()` | Conditional replication for optimization |

---

## C++ Scripting

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `TSharedPtr<T>` for UObjects | `TObjectPtr<T>` | UE5 type-safe pointers |
| Manual RTTI checks | `Cast<T>()` / `IsA<T>()` | Type-safe casting |

---

## Quick Migration Patterns

### Input Example
```cpp
// ❌ Deprecated
void AMyCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
}

// ✅ Enhanced Input
#include "EnhancedInputComponent.h"

void AMyCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent);
    if (EIC) {
        EIC->BindAction(JumpAction, ETriggerEvent::Started, this, &ACharacter::Jump);
    }
}
```

### Material Example
```cpp
// ❌ Deprecated: Legacy material
// Use standard material graph (still works but not recommended)

// ✅ Substrate Material
// Enable: Project Settings > Engine > Substrate > Enable Substrate
// Use Substrate nodes in material editor
```

### World Partition Example
```cpp
// ❌ Deprecated: Level streaming volumes
// Load/unload levels manually

// ✅ World Partition
// Enable: World Settings > Enable World Partition
// Use Data Layers for streaming
```

### Particle System Example
```cpp
// ❌ Deprecated: Cascade
UParticleSystemComponent* PSC = CreateDefaultSubobject<UParticleSystemComponent>(TEXT("Particles"));

// ✅ Niagara
UNiagaraComponent* NiagaraComp = CreateDefaultSubobject<UNiagaraComponent>(TEXT("Niagara"));
```

### Audio Example
```cpp
// ❌ Deprecated: Sound Cue for complex logic
// Use Sound Cue editor nodes

// ✅ MetaSounds
// Create MetaSound Source asset, use node-based audio
```

---

## Summary: UE 5.7 Tech Stack

| Feature | Use This (2026) | Avoid This (Legacy) |
|---------|------------------|----------------------|
| **Input** | Enhanced Input | Legacy Input Bindings |
| **Materials** | Substrate | Legacy Material System |
| **Lighting** | Lumen + Megalights | Lightmaps + Limited Lights |
| **Particles** | Niagara | Cascade |
| **Audio** | MetaSounds | Sound Cue (for logic) |
| **World Streaming** | World Partition | World Composition |
| **Animation Retarget** | IK Rig + Retargeter | Old Retargeting |
| **Geometry** | Nanite (high-poly) | Standard Static Mesh LODs |

---

**Sources:**
- https://docs.unrealengine.com/5.7/en-US/deprecated-and-removed-features/
- https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
