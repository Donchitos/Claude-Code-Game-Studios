# Godot Rendering — Quick Reference

Last verified: 2026-02-12 | Engine: Godot 4.6

> **Version note:** this project is pinned to **Godot 4.7**. This file was last verified
> against 4.6 — see `../VERSION.md` and the 4.6 → 4.7 section of `../breaking-changes.md`
> before relying on anything version-sensitive.

## What Changed Since ~4.3 (LLM Cutoff)

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
