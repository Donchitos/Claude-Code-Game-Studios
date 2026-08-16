# Unreal Engine 5.8 — Rendering Module Reference

**Last verified:** 2026-08-16
**Knowledge Gap:** MegaLights (production-ready in 5.8), production-ready Substrate, Lumen Lite (new in 5.8), Mesh Terrain (experimental in 5.8)

---

## Overview

UE 5.8 rendering stack:
- **Lumen**: Real-time global illumination (default)
- **Lumen Lite**: Medium-quality GI via Irradiance Fields — 2x faster than Lumen high quality (Beta in 5.8)
- **Nanite**: Virtualized geometry for millions of triangles
- **MegaLights**: Hundreds of dynamic shadow-casting area lights (production-ready in 5.8)
- **Substrate**: Production-ready modular material system (since 5.7)

---

## What's New in UE 5.8

- **MegaLights production-ready**: reduced noise, transmission support, froxel translucency, debugging tools; 60fps target on PS5/XSX
- **Lumen Lite (Beta)**: Irradiance Fields with Probe Occlusion; use when full Lumen exceeds the frame budget
- **Substrate NPR shading (Experimental)**: toon/stylized shading within Substrate
- **X-Rite AXF material import** via Substrate
- **Mesh Terrain (Experimental)**: mesh-based terrain (caves, overhangs) on Nanite + virtual textures — not yet production-ready
- **FSSS (Experimental)**: fog screen-space scattering approximation for volumetrics
- **World Partition Insights**: per-cell streaming analysis and debugging for World Partition worlds
- **Mobile**: multi-pass deferred rendering is now the mobile default (forward opt-in)

---

## Lumen (Global Illumination)

### Enable Lumen

```cpp
// Project Settings > Engine > Rendering > Dynamic Global Illumination Method = Lumen
// Real-time GI, no lightmap baking needed
```

### Lumen Quality Settings

```ini
; DefaultEngine.ini
[/Script/Engine.RendererSettings]
r.Lumen.DiffuseColorBoost=1.0
r.Lumen.ScreenProbeGather.RadianceCache.NumFramesToKeepCached=2
```

### Lumen in C++

```cpp
// Check if Lumen is enabled
bool bIsLumenEnabled = IConsoleManager::Get().FindConsoleVariable(TEXT("r.DynamicGlobalIlluminationMethod"))->GetInt() == 1;
```

---

## Nanite (Virtualized Geometry)

### Enable Nanite on Static Mesh

1. Static Mesh Editor
2. Details > Nanite Settings > Enable Nanite Support
3. Save mesh (auto-builds Nanite data)

### Nanite in C++

```cpp
// Spawn Nanite mesh
UStaticMeshComponent* MeshComp = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
MeshComp->SetStaticMesh(NaniteMesh); // Automatically uses Nanite if enabled
```

### Nanite Limitations
- No vertex animation (skeletal meshes)
- No world position offset (WPO) in materials
- Best for static, high-poly geometry

---

## MegaLights (UE 5.5+, Production-Ready in 5.8)

### Enable MegaLights

```cpp
// Project Settings > Engine > Rendering > MegaLights = Enabled
// Hundreds of dynamic shadow-casting area lights with minimal noise
// 5.8 adds transmission support, froxel translucency, and debugging tools
```

### MegaLights Usage

```cpp
// Add point lights as usual
UPointLightComponent* Light = CreateDefaultSubobject<UPointLightComponent>(TEXT("Light"));
Light->SetIntensity(5000.0f);
Light->SetAttenuationRadius(500.0f);

// MegaLights handles hundreds of shadow-casting lights at 60fps on current-gen consoles —
// orders of magnitude more than the ~100-200 limit of the traditional pipeline
```

---

## Substrate Materials (Production-Ready in 5.7)

### Enable Substrate

```cpp
// Project Settings > Engine > Substrate > Enable Substrate
// Restart editor
```

### Substrate Material Nodes
- **Substrate Slab**: Physical material layer (diffuse, specular, etc.)
- **Substrate Blend**: Blend multiple layers
- **Substrate Thin Film**: Iridescence, soap bubbles
- **Substrate Hair**: Hair-specific shading

### Example Substrate Material Graph

```
Substrate Slab (Diffuse)
  └─ Base Color: Texture Sample
  └─ Roughness: Constant (0.5)
  └─ Metallic: Constant (0.0)
  └─ Connect to Material Output
```

---

## Materials (C++ API)

### Dynamic Material Instances

```cpp
// Create dynamic material instance
UMaterialInstanceDynamic* DynMat = UMaterialInstanceDynamic::Create(BaseMaterial, this);

// Set parameters
DynMat->SetVectorParameterValue(TEXT("BaseColor"), FLinearColor::Red);
DynMat->SetScalarParameterValue(TEXT("Metallic"), 0.8f);
DynMat->SetTextureParameterValue(TEXT("DiffuseTexture"), MyTexture);

// Apply to mesh
MeshComp->SetMaterial(0, DynMat);
```

---

## Post-Processing

### Post-Process Volume

```cpp
// Add to level
APostProcessVolume* PPV = GetWorld()->SpawnActor<APostProcessVolume>();
PPV->bUnbound = true; // Affect entire world

// Configure settings
PPV->Settings.bOverride_MotionBlurAmount = true;
PPV->Settings.MotionBlurAmount = 0.5f;

PPV->Settings.bOverride_BloomIntensity = true;
PPV->Settings.BloomIntensity = 1.0f;
```

### Post-Process in C++

```cpp
// Access camera post-process settings
APlayerController* PC = GetWorld()->GetFirstPlayerController();
if (APlayerCameraManager* CamManager = PC->PlayerCameraManager) {
    CamManager->PostProcessBlendWeight = 1.0f;
    CamManager->PostProcessSettings.BloomIntensity = 2.0f;
}
```

---

## Lighting

### Directional Light (Sun)

```cpp
ADirectionalLight* Sun = GetWorld()->SpawnActor<ADirectionalLight>();
Sun->SetActorRotation(FRotator(-45.f, 0.f, 0.f));
Sun->GetLightComponent()->SetIntensity(10.0f);
Sun->GetLightComponent()->bCastShadows = true;
```

### Point Light

```cpp
APointLight* Light = GetWorld()->SpawnActor<APointLight>();
Light->SetActorLocation(FVector(0, 0, 200));
Light->GetPointLightComponent()->SetIntensity(5000.0f);
Light->GetPointLightComponent()->SetAttenuationRadius(1000.0f);
Light->GetPointLightComponent()->SetLightColor(FLinearColor::Red);
```

### Spot Light

```cpp
ASpotLight* Spotlight = GetWorld()->SpawnActor<ASpotLight>();
Spotlight->GetSpotLightComponent()->SetInnerConeAngle(20.0f);
Spotlight->GetSpotLightComponent()->SetOuterConeAngle(40.0f);
```

---

## Render Targets (Render to Texture)

### Create Render Target

```cpp
// Create render target asset (2D texture)
UTextureRenderTarget2D* RenderTarget = NewObject<UTextureRenderTarget2D>();
RenderTarget->InitAutoFormat(512, 512); // 512x512 resolution
RenderTarget->UpdateResourceImmediate();

// Render scene to texture
UKismetRenderingLibrary::DrawMaterialToRenderTarget(
    GetWorld(),
    RenderTarget,
    MaterialToDraw
);
```

---

## Custom Render Passes (Advanced)

### Render Dependency Graph (RDG)

```cpp
// UE5 uses Render Dependency Graph for custom rendering
// Example: Custom post-process pass

#include "RenderGraphBuilder.h"

void RenderCustomPass(FRDGBuilder& GraphBuilder, const FViewInfo& View) {
    FRDGTextureRef SceneColor = /* Get scene color texture */;

    // Define pass parameters
    struct FPassParameters {
        FRDGTextureRef InputTexture;
    };

    FPassParameters* PassParams = GraphBuilder.AllocParameters<FPassParameters>();
    PassParams->InputTexture = SceneColor;

    // Add render pass
    GraphBuilder.AddPass(
        RDG_EVENT_NAME("CustomPass"),
        PassParams,
        ERDGPassFlags::Raster,
        [](FRHICommandList& RHICmdList, const FPassParameters* Params) {
            // Render commands
        }
    );
}
```

---

## Performance

### Render Stats

```cpp
// Console commands for profiling:
// stat fps - Show FPS
// stat unit - Show frame time breakdown
// stat gpu - Show GPU timings
// profilegpu - Detailed GPU profile
```

### Scalability Settings

```cpp
// Get current scalability settings
UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings();
int32 ViewDistanceQuality = Settings->GetViewDistanceQuality(); // 0-4

// Set scalability
Settings->SetViewDistanceQuality(3); // High
Settings->SetShadowQuality(2); // Medium
Settings->ApplySettings(false);
```

---

## Debugging

### Visualize Render Features

```
Console commands:
- r.Lumen.Visualize 1 - Show Lumen debug
- r.Nanite.Visualize 1 - Show Nanite triangles
- viewmode wireframe - Wireframe mode
- viewmode unlit - Disable lighting
- show collision - Show collision meshes
```

---

## Sources
- https://docs.unrealengine.com/5.8/en-US/lumen-global-illumination-and-reflections-in-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/nanite-virtualized-geometry-in-unreal-engine/
- https://docs.unrealengine.com/5.8/en-US/substrate-materials-in-unreal-engine/
