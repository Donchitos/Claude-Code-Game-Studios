# Godot Rendering — Quick Reference

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **`AreaLight3D`**: real-time rectangular area lights
- **HDR output** on Windows, macOS, iOS, visionOS and Linux (Wayland)
- **`DrawableTexture2D`**: simple API for drawing on textures (4.7 release notes: https://godotengine.org/releases/4.7/)
- **`CanvasItem` lines**: no antialiasing feather, so lines look thinner
- **`LinearToSRGB` visual shader** no longer clamps to `[0.0, 1.0]` (Forward+, Mobile)
- **`get_format()`** moved from `ImageTexture` / `PortableCompressedTexture2D` to `Texture2D`
- **`rendering/reflections/sky_reflections/roughness_layers`** default `7` → `8` (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)

### 4.6 Changes
- **Windows rendering backend**: 4.6 announced D3D12 as the default (was Vulkan), but the default depends on version and settings — 4.7.2 (stable) was observed starting on Vulkan
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
- **`Shader` default-texture methods**: `set_default_texture_parameter()` takes and
  `get_default_texture_parameter()` returns `Texture`, not `Texture2D` (the shading
  language's `sampler2D` / `texture()` did not change)
- **Particles `.restart()`**: Added optional `keep_seed` parameter

### 4.3 Changes (in training data)
- **Compositor**: `Compositor` + `CompositorEffect` resources for post-processing chains — `Compositor` is a Resource assigned to the `compositor` property of `WorldEnvironment` or `Camera3D`, not a node

## Current API Patterns

### Post-Processing (4.3+)
```gdscript
# Use Compositor — NOT manual viewport shader chains
# Compositor is a Resource: assign it to the `compositor` property of
# WorldEnvironment or Camera3D (it cannot be added to the scene tree)
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

Windows default backend: depends on version and settings — 4.6 announced D3D12
(was Vulkan pre-4.6), but 4.7.2 (stable) was observed starting on Vulkan
```

## Common Mistakes
- Assuming a fixed default rendering backend on Windows — it depends on version and settings (4.6 announced D3D12; 4.7.2 was observed starting on Vulkan)
- Using manual viewport chains instead of Compositor for post-processing
- Passing or expecting `Texture2D` in `Shader.set_default_texture_parameter()` /
  `get_default_texture_parameter()` (the type is `Texture` since 4.4 — the shading
  language's `sampler2D` / `texture()` did not change)
- Not using Shader Baker for projects with many shader variants
