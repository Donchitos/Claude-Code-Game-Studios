# Unity 6.3 — Rendering Module Reference
# Unity 6.3 — 渲染模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** LLM trained on Unity 2022 LTS; Unity 6 has major rendering changes
**知识盲区：** LLM 基于 Unity 2022 LTS 训练；Unity 6 有重大渲染变更

---

## Overview
## 概述

Unity 6.3 LTS uses **Scriptable Render Pipelines (SRP)** as the modern rendering architecture:
- **URP (Universal Render Pipeline)**: Cross-platform, mobile-friendly (RECOMMENDED)
- **HDRP (High Definition Render Pipeline)**: High-end PC/console, photorealistic
- **Built-in Pipeline**: Deprecated, avoid for new projects

Unity 6.3 LTS 使用 **可脚本化渲染管线（SRP）** 作为现代渲染架构：
- **URP（通用渲染管线）**：跨平台、适合移动端（推荐）
- **HDRP（高清渲染管线）**：高端 PC/主机、照片级写实
- **内置管线（Built-in Pipeline）**：已弃用，新项目应避免使用

---

## Key Changes from 2022 LTS
## 相对 2022 LTS 的关键变更

### RenderGraph API (Unity 6+)
### RenderGraph API（Unity 6+）
Custom render passes now use RenderGraph instead of CommandBuffer:

自定义渲染通道现在使用 RenderGraph 而非 CommandBuffer：

```csharp
// ✅ Unity 6+ (RenderGraph)
public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData) {
    using var builder = renderGraph.AddRasterRenderPass<PassData>("MyPass", out var passData);
    builder.SetRenderFunc((PassData data, RasterGraphContext ctx) => {
        // Rendering commands
    });
}

// ❌ Old (CommandBuffer - still works but deprecated)
public override void Execute(ScriptableRenderContext context, ref RenderingData data) { }
```

### GPU Resident Drawer (Unity 6+)
### GPU Resident Drawer（Unity 6+）
Automatic batching for massive draw call reduction:

自动批处理，大幅减少绘制调用：

```csharp
// Enable in URP Asset settings:
// Rendering > GPU Resident Drawer = Enabled
// Automatically batches thousands of objects with minimal CPU overhead
```

---

## URP Quick Reference
## URP 快速参考

### Creating a URP Asset
### 创建 URP 资源
1. `Assets > Create > Rendering > URP Asset (with Universal Renderer)`
2. Assign to `Project Settings > Graphics > Scriptable Render Pipeline Settings`

1. `Assets > Create > Rendering > URP Asset (with Universal Renderer)`
2. 指派到 `Project Settings > Graphics > Scriptable Render Pipeline Settings`

### URP Renderer Features
### URP 渲染器功能（Renderer Features）
Add custom render passes:

添加自定义渲染通道：

```csharp
using UnityEngine.Rendering.Universal;

public class OutlineRendererFeature : ScriptableRendererFeature {
    OutlineRenderPass pass;

    public override void Create() {
        pass = new OutlineRenderPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData data) {
        renderer.EnqueuePass(pass);
    }
}
```

---

## Materials & Shaders
## 材质与着色器

### Shader Graph (Visual Shader Editor)
### Shader Graph（可视化着色器编辑器）
Unity 6 Shader Graph is production-ready for all shader types:

Unity 6 的 Shader Graph 对所有着色器类型都已生产就绪：

```csharp
// Create: Assets > Create > Shader Graph > URP > Lit Shader Graph
// No code needed, visual node-based editing
```

### HLSL Custom Shaders (URP)
### HLSL 自定义着色器（URP）

```hlsl
// URP Lit shader template
Shader "Custom/URPLit" {
    Properties {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

        Pass {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes input) {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 frag(Varyings input) : SV_Target {
                return half4(1, 0, 0, 1); // Red
            }
            ENDHLSL
        }
    }
}
```

---

## Lighting
## 光照

### Baked Lighting (Unity 6 Progressive Lightmapper)
### 烘焙光照（Unity 6 渐进式光照贴图器）

```csharp
// Mark objects as static: Inspector > Static > Contribute GI
// Bake: Window > Rendering > Lighting > Generate Lighting
```

### Real-Time Lights (URP)
### 实时光照（URP）

```csharp
// Main Light (Directional): Auto-handled by URP
// Additional Lights: Limited by "Additional Lights" setting in URP Asset

// Check light count in shader:
int lightCount = GetAdditionalLightsCount();
```

---

## Post-Processing
## 后处理

### Volume System (Unity 6+)
### Volume 系统（Unity 6+）

```csharp
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// Add Volume component to GameObject
// Add Volume Profile asset
// Configure effects: Bloom, Color Grading, Depth of Field, etc.

// Script access:
Volume volume = GetComponent<Volume>();
if (volume.profile.TryGet<Bloom>(out var bloom)) {
    bloom.intensity.value = 2.5f;
}
```

---

## Performance
## 性能

### SRP Batcher (Auto-batching)
### SRP Batcher（自动批处理）

```csharp
// Enable: URP Asset > Advanced > SRP Batcher = Enabled
// Batches draws with same shader variant (minimal CPU overhead)
```

### GPU Instancing
### GPU 实例化

```csharp
// Material: Enable "Enable GPU Instancing" checkbox
// Batches identical meshes (same material + mesh)

Graphics.RenderMeshInstanced(
    new RenderParams(material),
    mesh,
    0,
    matrices // NativeArray<Matrix4x4>
);
```

### Occlusion Culling
### 遮挡剔除（Occlusion Culling）

```csharp
// Window > Rendering > Occlusion Culling
// Bake occlusion data for static geometry
```

---

## Common Patterns
## 常见模式

### Custom Camera Rendering
### 自定义摄像机渲染

```csharp
// Get URP camera data
var cameraData = frameData.Get<UniversalCameraData>();
var camera = cameraData.camera;

// Access render targets
var colorTarget = cameraData.renderer.cameraColorTargetHandle;
```

### Screen-Space Effects
### 屏幕空间效果

```csharp
// Create ScriptableRendererFeature
// Inject pass at specific point: AfterRenderingOpaques, AfterRenderingTransparents, etc.
```

---

## Debugging
## 调试

### Frame Debugger
### 帧调试器（Frame Debugger）
- `Window > Analysis > Frame Debugger`
- Step through draw calls, inspect state

- `Window > Analysis > Frame Debugger`
- 逐步查看绘制调用，检视状态

### Rendering Debugger (Unity 6+)
### 渲染调试器（Rendering Debugger，Unity 6+）
- `Window > Analysis > Rendering Debugger`
- Live view of URP settings, overdraw, lighting

- `Window > Analysis > Rendering Debugger`
- 实时查看 URP 设置、过度绘制（overdraw）、光照

---

## Sources
## 来源
- https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/index.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/render-pipelines.html
