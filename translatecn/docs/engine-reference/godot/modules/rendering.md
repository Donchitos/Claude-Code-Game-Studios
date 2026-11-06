# Godot Rendering — Quick Reference
# Godot 渲染 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

### 4.7 Changes
### 4.7 变更
- **`AreaLight3D`**: real-time rectangular area lights
- **`AreaLight3D`**：实时矩形区域光
- **HDR output** on Windows, macOS, iOS, visionOS and Linux (Wayland)
- **HDR 输出**：支持 Windows、macOS、iOS、visionOS 和 Linux（Wayland）
- **`DrawableTexture2D`**: simple API for drawing on textures (4.7 release notes: https://godotengine.org/releases/4.7/)
- **`DrawableTexture2D`**：用于在纹理上绘制的简单 API（4.7 发行说明：https://godotengine.org/releases/4.7/）
- **`CanvasItem` lines**: no antialiasing feather, so lines look thinner
- **`CanvasItem` 线条**：无抗锯齿羽化，因此线条看起来更细
- **`LinearToSRGB` visual shader** no longer clamps to `[0.0, 1.0]` (Forward+, Mobile)
- **`LinearToSRGB` 视觉着色器**在 Forward+、Mobile 下不再钳制到 `[0.0, 1.0]`
- **`get_format()`** moved from `ImageTexture` / `PortableCompressedTexture2D` to `Texture2D`
- **`get_format()`** 从 `ImageTexture` / `PortableCompressedTexture2D` 移至 `Texture2D`
- **`rendering/reflections/sky_reflections/roughness_layers`** default `7` → `8` (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- **`rendering/reflections/sky_reflections/roughness_layers`** 默认 `7` → `8`（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）

### 4.6 Changes
### 4.6 变更
- **D3D12 is the default rendering backend on Windows** (was Vulkan)
- **Windows 上 D3D12 是默认渲染后端**（原为 Vulkan）
- **Glow processes before tonemapping** (was after) — uses screen blending mode
- **glow 在色调映射之前处理**（原为之后）— 使用屏幕混合模式
- **AgX tonemapper**: new white point and contrast controls
- **AgX 色调映射器**：新增白点和对比度控件
- **SSR overhauled**: better realism, visual stability, and performance
- **SSR 已重构**：更好的真实感、视觉稳定性和性能

### 4.5 Changes
### 4.5 变更
- **Shader Baker**: Pre-compiles shaders to reduce startup time
- **着色器烘焙器**：预编译着色器以缩短启动时间
- **SMAA 1x**: New anti-aliasing option (sharper than FXAA, cheaper than TAA)
- **SMAA 1x**：新的抗锯齿选项（比 FXAA 更锐利，比 TAA 开销更低）
- **Stencil buffer support**: Enables selective geometry masking/portal effects
- **模板缓冲区支持**：可实现选择性几何体遮罩/传送门效果
- **Bent normal maps**: Directional occlusion encoded in normal map textures
- **弯曲法线贴图**：在法线贴图纹理中编码方向性遮蔽
- **Specular occlusion**: Ambient occlusion now correctly affects reflections
- **镜面反射遮蔽**：环境光遮蔽现在能正确影响反射

### 4.4 Changes
### 4.4 变更
- **`RenderingDevice.draw_list_begin`**: Many parameters removed; optional `breadcrumb` added
- **`RenderingDevice.draw_list_begin`**：移除了许多参数；增加了可选 `breadcrumb`
- **`Shader` default-texture methods**: `set_default_texture_parameter()` takes and
  `get_default_texture_parameter()` returns `Texture`, not `Texture2D` (the shading
  language's `sampler2D` / `texture()` did not change)
- **`Shader` 默认纹理方法**：`set_default_texture_parameter()` 接受、`get_default_texture_parameter()` 返回 `Texture`，而非 `Texture2D`（着色语言的 `sampler2D` / `texture()` 未变）
- **Particles `.restart()`**: Added optional `keep_seed` parameter
- **粒子 `.restart()`**：增加了可选 `keep_seed` 参数

### 4.3 Changes (in training data)
### 4.3 变更（在训练数据中）
- **Compositor node**: `Compositor` + `CompositorEffect` for post-processing chains
- **Compositor 节点**：`Compositor` + `CompositorEffect` 用于后处理链

## Current API Patterns
## 当前 API 模式

### Post-Processing (4.3+)
### 后处理（4.3+）
```gdscript
# Use Compositor node — NOT manual viewport shader chains
# Add Compositor as child of WorldEnvironment or Camera3D
# Create CompositorEffect resources for each post-process step
```

### Anti-Aliasing Options (4.6)
### 抗锯齿选项（4.6）
```
Project Settings → Rendering → Anti Aliasing:
- MSAA 2D/3D: Hardware MSAA (quality but expensive)
- Screen Space AA: FXAA (fast, blurry) or SMAA (sharp, moderate cost)  # SMAA new in 4.5
- TAA: Temporal (best quality, ghosting on fast motion)
```

### Rendering Backend Selection (4.6)
### 渲染后端选择（4.6）
```
Project Settings → Rendering → Renderer:
- Forward+ (default): Full featured, desktop-focused
- Mobile: Optimized for mobile/low-end, limited features
- Compatibility: OpenGL 3.3 / WebGL 2, broadest hardware support

Windows default backend: D3D12 (was Vulkan pre-4.6)
```

## Common Mistakes
## 常见错误
- Assuming Vulkan is the default backend on Windows (D3D12 since 4.6)
- 误以为 Vulkan 是 Windows 上的默认后端（自 4.6 起为 D3D12）
- Using manual viewport chains instead of Compositor for post-processing
- 使用手动视口链而非 Compositor 进行后处理
- Passing or expecting `Texture2D` in `Shader.set_default_texture_parameter()` /
  `get_default_texture_parameter()` (the type is `Texture` since 4.4 — the shading
  language's `sampler2D` / `texture()` did not change)
- 在 `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` 中传入或期望 `Texture2D`（自 4.4 起类型为 `Texture` — 着色语言的 `sampler2D` / `texture()` 未变）
- Not using Shader Baker for projects with many shader variants
- 对于有大量着色器变体的项目未使用着色器烘焙器
