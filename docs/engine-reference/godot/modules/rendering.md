# Godot Rendering — Quick Reference

Last verified: 2026-08-14 | Engine: Godot 4.7.1

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **`CanvasItem` 画线不再加抗锯齿羽化**：线变细；依赖此行为需手动加粗线宽（GH-105122）。
- **`LinearToSRGB` 视觉着色器不再 clamp 到 `[0,1]`**（Mobile / Forward+ 渲染器，GH-113956）。
- **`ImageTexture.get_format()` / `PortableCompressedTexture2D.get_format()` 移至基类 `Texture2D`**：兼容（GH-109004）。
- **`RenderingServer.particles_request_process_time(time)` → `particles_request_process_time(process_time, process_time_residual)`**：参数重命名+新增，源码级破坏（GH-109142）。
- **`RenderingServer.viewport_set_size()` 新增 `view_count` 可选参数**：兼容（GH-115799）。
- **`Image.save_exr()` / `save_exr_to_buffer()` 新增 `color_image`、`max_linear_value` 可选参数**：兼容（GH-117800）。
- **`AreaLight3D`**：新矩形光源节点，软阴影、更真实反射（3D）。
- **`DrawableTexture2D`**：简化在纹理上绘制的 API，替代 Viewport hack。
- **`GradientTexture2D` 新增 `FILL_CONIC`**：锥形渐变。
- **Control 偏移变换**：Control 节点可平移/旋转/缩放而不影响容器布局（类似 CSS `transform`）。
- **HDR 输出支持**：Windows/macOS/iOS/visionOS/Linux(Wayland)。
- **内联着色器预览**：编辑器内实时预览文本着色器操作。
- **新项目默认 stretch**：mode `canvas_items`、aspect `expand`（适配多分辨率/竖屏有用）。

### 4.6 Changes
- **D3D12 is the default rendering backend on Windows** (was Vulkan)
- **Glow processes before tonemapping** (was after) — uses screen blending mode
- **AgX tonemapper**: new white point and contrast controls
- **SSR overhauled**: better realism, visual stability, and performance

### 4.5 Changes
- **Shader Baker**: Pre-compiles shaders to reduce startup time
- **SMAA 1x**: New anti-aliasing option (sharper than FXAA, cheaper than TAA)
- **Stencil buffer support**: Enables selective geometry masking/portal effects
- **Bent normal maps**: Directional occlusion encoded in normal map textures
- **Specular occlusion**: Ambient occlusion now correctly affects reflections

### 4.4 Changes
- **`RenderingDevice.draw_list_begin`**: Many parameters removed; optional `breadcrumb` added
- **Shader texture types**: Changed from `Texture2D` to `Texture` base type
- **Particles `.restart()`**: Added optional `keep_seed` parameter

### 4.3 Changes (in training data)
- **Compositor node**: `Compositor` + `CompositorEffect` for post-processing chains

## Current API Patterns

### Post-Processing (4.3+)
```gdscript
# Use Compositor node — NOT manual viewport shader chains
# Add Compositor as child of WorldEnvironment or Camera3D
# Create CompositorEffect resources for each post-process step
```

### Anti-Aliasing Options (4.6)
```
Project Settings → Rendering → Anti Aliasing:
- MSAA 2D/3D: Hardware MSAA (quality but expensive)
- Screen Space AA: FXAA (fast, blurry) or SMAA (sharp, moderate cost)  # SMAA new in 4.5
- TAA: Temporal (best quality, ghosting on fast motion)
```

### Rendering Backend Selection (4.6)
```
Project Settings → Rendering → Renderer:
- Forward+ (default): Full featured, desktop-focused
- Mobile: Optimized for mobile/low-end, limited features
- Compatibility: OpenGL 3.3 / WebGL 2, broadest hardware support

Windows default backend: D3D12 (was Vulkan pre-4.6)
```

## Common Mistakes
- Assuming Vulkan is the default backend on Windows (D3D12 since 4.6)
- Using manual viewport chains instead of Compositor for post-processing
- Using `Texture2D` in shader uniform types (use `Texture` since 4.4)
- Not using Shader Baker for projects with many shader variants
