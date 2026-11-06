# Unreal Engine 5.8 — Rendering Module Reference
# Unreal Engine 5.8 — 渲染模块参考

**Last verified:** 2026-10-18 (MegaLights tooltip against the 5.8 notes and source); 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.8 has production-ready MegaLights, production-ready Substrate (5.7), Lumen Lite, and Lumen improvements

**最后验证：** 2026-10-18（对照 5.8 发行说明与源码核实 MegaLights 工具提示）；2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.8 具备生产就绪的 MegaLights、生产就绪的 Substrate（5.7）、Lumen Lite 以及 Lumen 改进

> **UE 5.8 changes:** MegaLights is production-ready (enable it in Project
> Settings > Engine > Rendering > Direct Lighting > MegaLights,
> `r.MegaLights.EnableForProject`, default 0). Lumen Lite (Beta) is a
> medium-quality GI setting, about twice as fast as Lumen high quality and the
> default for current-generation handheld consoles. Mobile: multi-pass deferred
> is the default path (forward is opt-in), with SSAO, SSR, deferred decals and
> contact shadows. Lumen applies height fog to reflection ray hits by default
> (`r.Lumen.HeightFog 1`). Substrate has been on for new projects since 5.7
> (`r.Substrate`); Substrate NPR (toon) shading and Fog Screen Space Scattering
> are Experimental. Sources: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8 ;
> `Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h` and
> `Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp` (5.8.1 install).

> **UE 5.8 变更：** MegaLights 已生产就绪（在 Project
> Settings > Engine > Rendering > Direct Lighting > MegaLights 中启用，
> `r.MegaLights.EnableForProject`，默认 0）。Lumen Lite（Beta）是中等质量的 GI 设置，速度约为高质量 Lumen 的两倍，也是当前世代掌机的默认选项。
> 移动端：多通道延迟渲染为默认路径（前向渲染为可选），支持 SSAO、SSR、延迟贴花与接触阴影。Lumen 默认将高度雾应用于反射光线命中
> （`r.Lumen.HeightFog 1`）。Substrate 自 5.7 起对新项目默认开启
> （`r.Substrate`）；Substrate NPR（卡通）着色与 Fog Screen Space Scattering 为实验性。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8 ；
> `Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h` 与
> `Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp`（5.8.1 安装）。

---

## Overview
## 概述

UE 5.8 rendering stack:
- **Lumen**: Real-time global illumination (default)
- **Nanite**: Virtualized geometry for millions of triangles
- **MegaLights**: Many shadow-casting dynamic lights (NEW in 5.5+, production-ready in 5.8)
- **Substrate**: Production-ready modular material system (NEW in 5.7)

UE 5.8 渲染技术栈：
- **Lumen**：实时全局光照（默认）
- **Nanite**：支持数百万三角形的虚拟化几何
- **MegaLights**：大量投射阴影的动态光源（5.5+ 新增，5.8 中生产就绪）
- **Substrate**：生产就绪的模块化材质系统（5.7 新增）

---

## Lumen (Global Illumination)
## Lumen（全局光照）

### Enable Lumen
### 启用 Lumen

```cpp
// Project Settings > Engine > Rendering > Dynamic Global Illumination Method = Lumen
// Real-time GI, no lightmap baking needed
```

### Lumen Quality Settings
### Lumen 质量设置

```ini
; DefaultEngine.ini
[/Script/Engine.RendererSettings]
r.Lumen.DiffuseColorBoost=1.0
r.Lumen.ScreenProbeGather.RadianceCache.NumFramesToKeepCached=2
```

### Lumen in C++
### 在 C++ 中使用 Lumen

```cpp
// Check if Lumen is enabled
bool bIsLumenEnabled = IConsoleManager::Get().FindConsoleVariable(TEXT("r.DynamicGlobalIlluminationMethod"))->GetInt() == 1;
```

---

## Nanite (Virtualized Geometry)
## Nanite（虚拟化几何）

### Enable Nanite on Static Mesh
### 在静态网格上启用 Nanite

1. Static Mesh Editor
2. Details > Nanite Settings > Enable Nanite Support
3. Save mesh (auto-builds Nanite data)

1. Static Mesh Editor
2. Details > Nanite Settings > Enable Nanite Support
3. 保存网格（自动构建 Nanite 数据）

### Nanite in C++
### 在 C++ 中使用 Nanite

```cpp
// Spawn Nanite mesh
UStaticMeshComponent* MeshComp = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
MeshComp->SetStaticMesh(NaniteMesh); // Automatically uses Nanite if enabled
```

### Nanite Limitations
### Nanite 限制

- No vertex animation (skeletal meshes)
- No world position offset (WPO) in materials
- Best for static, high-poly geometry

- 不支持顶点动画（骨骼网格）
- 材质中不支持世界位置偏移（WPO）
- 最适合静态、高面数几何体

---

## MegaLights (UE 5.5+, production-ready in 5.8)
## MegaLights（UE 5.5+，5.8 中生产就绪）

### Enable MegaLights
### 启用 MegaLights

```cpp
// Project Settings > Engine > Rendering > Direct Lighting > MegaLights
//   (r.MegaLights.EnableForProject, default 0; a Post Process Volume can
//   override it, and it can be disabled per light)
// Many shadow-casting lights at a consistent, low GPU cost
```

### The editor tooltip is older than the 5.8 release notes
### 编辑器工具提示早于 5.8 发行说明

In a 5.8.1 install, this setting's tooltip (`RendererSettings.h`) and the
`r.MegaLights.EnableForProject` help text (`MegaLights.cpp`) still end
"Experimental feature." and say MegaLights "requires Hardware Ray Tracing, and
does not support Directional Lights". Follow the release notes and the engine
code instead:

- **Status:** "Megalights is now entering Production Ready status with Unreal
  Engine 5.8" (5.8 release notes, Rendering > Megalights).
- **Ray tracing:** the renderer accepts hardware or software ray tracing support
  (`HasRequiredTracingData` in `MegaLights.cpp`). Shadow rays use hardware ray
  tracing while `r.MegaLights.HardwareRayTracing` is 1, the default. Shadows
  come from ray tracing (the default) or Virtual Shadow Maps:
  `r.MegaLights.DefaultShadowMethod` 0 or 1.
- **Directional lights:** supported behind `r.MegaLights.DirectionalLights`,
  default 0 (off). The 5.7 release notes list Directional Light support.

在 5.8.1 安装中，该设置的提示（`RendererSettings.h`）与
`r.MegaLights.EnableForProject` 的帮助文本（`MegaLights.cpp`）仍以
"Experimental feature." 结尾，并称 MegaLights "requires Hardware Ray Tracing, and
does not support Directional Lights"。请以发行说明与引擎代码为准：

- **状态：** "Megalights is now entering Production Ready status with Unreal
  Engine 5.8"（5.8 发行说明，Rendering > Megalights）。
- **光线追踪：** 渲染器同时接受硬件或软件光线追踪支持
  （`MegaLights.cpp` 中的 `HasRequiredTracingData`）。当 `r.MegaLights.HardwareRayTracing` 为 1（默认值）时，阴影光线使用硬件光线追踪。阴影来自光线追踪（默认）或 Virtual Shadow Maps：
  `r.MegaLights.DefaultShadowMethod` 为 0 或 1。
- **定向光：** 通过 `r.MegaLights.DirectionalLights` 提供支持，
  默认 0（关闭）。5.7 发行说明列出了对 Directional Light 的支持。

Sources, read 2026-10-18: the 5.8 and 5.7 release notes (§ Sources); in a UE
5.8.1 install (CL 56057345), `Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h`,
`Engine/Source/Runtime/Renderer/Private/MegaLights/MegaLights.cpp` and
`MegaLightsRayTracing.cpp`.

来源，读取于 2026-10-18：5.8 与 5.7 发行说明（见 § 来源）；在 UE
5.8.1 安装（CL 56057345）中，`Engine/Source/Runtime/Engine/Classes/Engine/RendererSettings.h`、
`Engine/Source/Runtime/Renderer/Private/MegaLights/MegaLights.cpp` 与
`MegaLightsRayTracing.cpp`。

### MegaLights Usage
### MegaLights 用法

```cpp
// Add point lights as usual
UPointLightComponent* Light = CreateDefaultSubobject<UPointLightComponent>(TEXT("Light"));
Light->SetIntensity(5000.0f);
Light->SetAttenuationRadius(500.0f);

// MegaLights handles many of these at a consistent GPU cost
```

---

## Substrate Materials (Production-Ready in 5.7)
## Substrate 材质（5.7 中生产就绪）

### Enable Substrate
### 启用 Substrate

```cpp
// On by default for new projects created in 5.7+.
// Existing project: Project Settings > Engine > Rendering > Substrate >
//   Substrate materials (r.Substrate), then restart the editor
```

### Substrate Material Nodes
### Substrate 材质节点

- **Substrate Slab**: Physical material layer (diffuse, specular, etc.)
- **Substrate Blend**: Blend multiple layers
- **Substrate Thin Film**: Iridescence, soap bubbles
- **Substrate Hair**: Hair-specific shading

- **Substrate Slab**：物理材质层（漫反射、镜面反射等）
- **Substrate Blend**：混合多个层
- **Substrate Thin Film**：虹彩、肥皂泡
- **Substrate Hair**：头发专用着色

### Example Substrate Material Graph
### Substrate 材质图表示例

```
Substrate Slab (Diffuse)
  └─ Base Color: Texture Sample
  └─ Roughness: Constant (0.5)
  └─ Metallic: Constant (0.0)
  └─ Connect to Material Output
```

---

## Materials (C++ API)
## 材质（C++ API）

### Dynamic Material Instances
### 动态材质实例

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
## 后处理

### Post-Process Volume
### 后期处理体积

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
### 在 C++ 中使用后处理

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
## 光照

### Directional Light (Sun)
### 定向光（太阳）

```cpp
ADirectionalLight* Sun = GetWorld()->SpawnActor<ADirectionalLight>();
Sun->SetActorRotation(FRotator(-45.f, 0.f, 0.f));
Sun->GetLightComponent()->SetIntensity(10.0f);
Sun->GetLightComponent()->bCastShadows = true;
```

### Point Light
### 点光源

```cpp
APointLight* Light = GetWorld()->SpawnActor<APointLight>();
Light->SetActorLocation(FVector(0, 0, 200));
Light->GetPointLightComponent()->SetIntensity(5000.0f);
Light->GetPointLightComponent()->SetAttenuationRadius(1000.0f);
Light->GetPointLightComponent()->SetLightColor(FLinearColor::Red);
```

### Spot Light
### 聚光灯

```cpp
ASpotLight* Spotlight = GetWorld()->SpawnActor<ASpotLight>();
Spotlight->GetSpotLightComponent()->SetInnerConeAngle(20.0f);
Spotlight->GetSpotLightComponent()->SetOuterConeAngle(40.0f);
```

---

## Render Targets (Render to Texture)
## 渲染目标（渲染到纹理）

### Create Render Target
### 创建渲染目标

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
## 自定义渲染通道（进阶）

### Render Dependency Graph (RDG)
### 渲染依赖图（RDG）

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
## 性能

### Render Stats
### 渲染统计

```cpp
// Console commands for profiling:
// stat fps - Show FPS
// stat unit - Show frame time breakdown
// stat gpu - Show GPU timings
// profilegpu - Detailed GPU profile
```

### Scalability Settings
### 可扩展性设置

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
## 调试

### Visualize Render Features
### 可视化渲染特性

```
Console commands:
- r.Lumen.Visualize 1 - Show Lumen debug
- r.Nanite.Visualize 1 - Show Nanite triangles
- viewmode wireframe - Wireframe mode
- viewmode unlit - Disable lighting
- show collision - Show collision meshes
```

```
控制台命令：
- r.Lumen.Visualize 1 - 显示 Lumen 调试信息
- r.Nanite.Visualize 1 - 显示 Nanite 三角形
- viewmode wireframe - 线框模式
- viewmode unlit - 关闭光照
- show collision - 显示碰撞网格
```

---

## Sources
## 来源

- UE 5.8 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- UE 5.7 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes?application_version=5.7
- https://docs.unrealengine.com/5.7/en-US/lumen-global-illumination-and-reflections-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/nanite-virtualized-geometry-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/substrate-materials-in-unreal-engine/
