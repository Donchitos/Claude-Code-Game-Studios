---
paths:
  - "assets/shaders/**"
---

# Shader Code Standards

All shader files in `assets/shaders/` must follow these standards to maintain
visual quality, performance, and cross-platform compatibility.

## Naming Conventions
- File naming: `[type]_[category]_[name].[ext]`
  - `spatial_env_water.gdshader` (Godot)
  - `SG_Env_Water` (Unity Shader Graph)
  - `M_Env_Water` (Unreal Material)
  - `post_env_water.frag` / `filter_ui_glow.wgsl` (Web — GLSL and WGSL)
- Use descriptive names that indicate the material purpose
- Prefix with shader type: `spatial_`, `canvas_`, `particles_`, `post_`

## Code Quality
- All uniforms/parameters must have descriptive names and appropriate hints
- Group related parameters (Godot: `group_uniforms`, Unity: `[Header]`, Unreal: Category)
- Comment non-obvious calculations (especially math-heavy sections)
- No magic numbers — use named constants or documented uniform values
- Include authorship and purpose comment at the top of each shader file

## Performance Requirements
- Document the target platform and complexity budget for each shader
- Use appropriate precision: `half`/`mediump` on mobile where full precision isn't needed
- Minimize texture samples in fragment shaders
- Avoid dynamic branching in fragment shaders — use `step()`, `mix()`, `smoothstep()`
- No texture reads inside loops
- Two-pass approach for blur effects (horizontal then vertical)

## Cross-Platform
- Test shaders on minimum spec target hardware
- Provide fallback/simplified versions for lower quality tiers
- Document which render pipeline the shader targets (Forward/Deferred, URP/HDRP, Forward+/Mobile/Compatibility)
- Do not mix shaders from different render pipelines in the same directory

## Variant Management
- Minimize shader variants — each variant is a separate compiled shader
- Document all keywords/variants and their purpose
- Use feature stripping where possible to reduce build size
- Log and monitor total variant count per shader

## Web (PixiJS / Three.js)

Web projects target two graphics backends at once, and a shader supplying only
one language silently breaks for a subset of users.

- **PixiJS filters must ship both WGSL and GLSL sources.** v8 prefers WebGPU with
  WebGL2 fallback; a filter with only `glProgram` or only `gpuProgram` fails on
  the other backend
- **Three.js on `WebGPURenderer` uses TSL / `NodeMaterial`**, not raw GLSL
  `ShaderMaterial`. TSL compiles to both WGSL and GLSL, so it is the portable
  choice — prefer it over hand-written GLSL strings
- Declare precision explicitly in GLSL ES 3.0 — mobile GPUs default differently
  than desktop. `mediump` for colors, `highp` for positions, depth, and
  accumulated values
- Post-processing is **`RenderPipeline`** in Three.js (renamed from
  `PostProcessing` in r183)
- Full-screen passes scale with resolution — cap `devicePixelRatio` and render
  bloom/blur/AO at reduced resolution
- Every shader carries a header comment stating its purpose, expected uniforms,
  and which backends it targets
- Verify effects on real mobile hardware, not just a desktop GPU

See `docs/engine-reference/web/modules/rendering.md`.
