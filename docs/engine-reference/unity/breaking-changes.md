# Unity 6.3 LTS — Breaking Changes

**Last verified:** 2026-05-15

This document tracks breaking API changes and behavioral differences between Unity 2022 LTS
(likely in model training) and Unity 6.3 LTS (current version). Organized by risk level.

## HIGH RISK — Will Break Existing Code

### Entities/DOTS API Complete Overhaul
**Versions:** Entities 1.0+ (Unity 6.0+)

```csharp
// ❌ OLD (pre-Unity 6, GameObjectEntity pattern)
public class HealthComponent : ComponentData {
    public float Value;
}

// ✅ NEW (Unity 6+, IComponentData)
public struct HealthComponent : IComponentData {
    public float Value;
}

// ❌ OLD: ComponentSystem
public class DamageSystem : ComponentSystem { }

// ✅ NEW: ISystem (unmanaged, Burst-compatible)
public partial struct DamageSystem : ISystem {
    public void OnCreate(ref SystemState state) { }
    public void OnUpdate(ref SystemState state) { }
}
```

**Migration:** Follow Unity's ECS migration guide. Major architectural changes required.

---

### Input System — Legacy Input Deprecated
**Versions:** Unity 6.0+

```csharp
// ❌ OLD: Input class (deprecated)
if (Input.GetKeyDown(KeyCode.Space)) { }

// ✅ NEW: Input System package
using UnityEngine.InputSystem;
if (Keyboard.current.spaceKey.wasPressedThisFrame) { }
```

**Migration:** Install Input System package, replace all `Input.*` calls with new API.

---

### URP/HDRP Renderer Feature API Changes
**Versions:** Unity 6.0+

```csharp
// ❌ OLD: ScriptableRenderPass.Execute signature
public override void Execute(ScriptableRenderContext context, ref RenderingData data)

// ✅ NEW: Uses RenderGraph API
public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
```

**Migration:** Update custom render passes to use RenderGraph API.

---

### Object Finding APIs — RENAMED (Unity 6.0+)
**Impact**: Any code calling `FindObjectsOfType` or `FindObjectOfType` — HIGH for Hive Mind scene scanning

```csharp
// ❌ OLD (deprecated)
Object.FindObjectsOfType<Enemy>();
Object.FindObjectOfType<Player>();

// ✅ NEW
Object.FindObjectsByType<Enemy>(FindObjectsSortMode.None);   // use None for performance
Object.FindFirstObjectByType<Player>();   // deterministic
Object.FindAnyObjectByType<Player>();     // faster, non-deterministic
```

---

### Netcode for GameObjects — 1.X Deprecated (Unity 6.3)
**Impact**: **CRITICAL for SYNTHFALL** — NGO 1.X is deprecated, upgrade to 2.X required.
Multiplay Hosting shuts down March 31, 2026.

```csharp
// ❌ OLD (NGO 1.X)
public override void OnUpdate() { }  // via NetworkTransform base

// ✅ NEW (NGO 2.X)
public override void OnNetworkUpdate() { }
```

**Action**: Pin NGO 2.X from project start. Do not use NGO 1.X.

---

### [SerializeField] Restricted to Fields Only (Unity 6.3)

```csharp
// ❌ OLD (was silently ignored on properties — now compile error)
[SerializeField] public float Speed { get; set; }

// ✅ NEW
[SerializeField] private float _speed;
public float Speed => _speed;
```

---

### Lighting — Enlighten Baked GI Discontinued (Unity 6.0+)

- Projects auto-convert to Progressive Lightmapper on upgrade
- Auto-generated lighting removed — must call `Lightmapping.Bake()` or `Lightmapping.BakeAsync()` explicitly
- Light Probe brightness changed: now 100% (was 94%)

---

### DirectX 12 Default Graphics API (Unity 6.1+)

DirectX 12 replaces DirectX 11 as the default. Projects relying on DX11-specific
rendering behavior may see differences. Override via `PlayerSettings.SetGraphicsAPIs()` if needed.

---

### USS Strict Parsing — UI Toolkit (Unity 6.3)

Previously ignored invalid CSS syntax in `.uss` files now causes errors.
Audit all USS files before upgrading if using UI Toolkit.

---

### Android — UnityPlayer Renamed (Unity 6.0+)

`UnityPlayer` Java class renamed to `UnityPlayerForActivityOrService`.
No longer extends `FrameLayout`. Any native Android plugin referencing
`UnityPlayer` directly must update — not relevant for PC-only SYNTHFALL.

---

## MEDIUM RISK — Behavioral Changes

### Addressables — Asset Loading Returns
**Versions:** Unity 6.2+

Asset loading failures now throw exceptions by default instead of returning null.
Add proper exception handling or use `TryLoad` variants.

```csharp
// ❌ OLD: Silent null on failure
var handle = Addressables.LoadAssetAsync<Sprite>("key");
var sprite = handle.Result; // null if failed

// ✅ NEW: Throws on failure, use try/catch or TryLoad
try {
    var handle = Addressables.LoadAssetAsync<Sprite>("key");
    var sprite = await handle.Task;
} catch (Exception e) {
    Debug.LogError($"Failed to load: {e}");
}
```

---

### Physics — Default Solver Iterations Changed
**Versions:** Unity 6.0+

Default solver iterations increased for better stability.
Check `Physics.defaultSolverIterations` if you rely on old behavior.

---

## LOW RISK — Deprecations (Still Functional)

### UGUI (Legacy UI)
**Status:** Deprecated but supported
**Replacement:** UI Toolkit

UGUI still works but UI Toolkit is recommended for new projects.

---

### Legacy Particle System
**Status:** Deprecated
**Replacement:** Visual Effect Graph (VFX Graph)

---

### Old Animation System
**Status:** Deprecated
**Replacement:** Animator Controller (Mecanim)

---

## Platform-Specific Breaking Changes

### WebGL
- **Unity 6.0+**: WebGPU is now the default (WebGL 2.0 fallback available)
- Update shaders for WebGPU compatibility

### Android
- **Unity 6.0+**: Minimum API level raised to 24 (Android 7.0)

### iOS
- **Unity 6.0+**: Minimum deployment target raised to iOS 13

---

## Migration Checklist

When upgrading from 2022 LTS to Unity 6.3 LTS:

- [ ] Audit all DOTS/ECS code (complete rewrite likely needed)
- [ ] Replace `Input` class with Input System package
- [ ] Update custom render passes to RenderGraph API
- [ ] Add exception handling to Addressables calls
- [ ] Test physics behavior (solver iterations changed)
- [ ] Consider migrating UGUI to UI Toolkit for new UI
- [ ] Update WebGL shaders for WebGPU
- [ ] Verify minimum platform versions (Android/iOS)

---

**Sources:**
- https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/upgrade-guide.html
