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
  - `effect_env_water.effect` (Cocos Creator — store under `assets/effects/`, not `assets/shaders/`)
- Use descriptive names that indicate the material purpose
- Prefix with shader type: `spatial_`, `canvas_`, `particles_`, `post_`
  - Cocos Effect files: the type is implied by the `techniques` block (e.g., `2d-sprite`, `opaque`, `transparent`, `post-process`); the file *name* still uses the `[type]_[category]_[name]` shape
- For Cocos: do **not** redeclare engine-injected uniforms (`cc_matViewProj`, `cc_matWorld`, `cc_cameraPos`, `cc_time`, `cc_screenSize`, `cc_exposure`, etc.) — they are auto-injected and shadowing them causes GLSL compile failure or silent black renders
- For Cocos on mini-game platforms (WeChat / ByteDance / Alipay / Honor): declare `batching: true` on the Effect technique so it can participate in sprite / mesh batching, and avoid `discard` (kills early-z on WebGL 1) — prefer `step()` alpha-test against the texture's `.a` channel

## Code Quality
- All uniforms/parameters must have descriptive names and appropriate hints
- Group related parameters (Godot: `group_uniforms`, Unity: `[Header]`, Unreal: Category, Cocos: nested `properties` blocks in the `CCEffect` header)
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
  - Cocos Creator 3.8+: the CustomRenderPipeline + RenderStage API is stable — when authoring a custom stage, declare it as `stage: <Name>` in the pass block and provide a matching `CustomRenderPipelineBuilder` (TypeScript side) that calls `cam.setCustomStages([...])`
- Do not mix shaders from different render pipelines in the same directory

## Variant Management
- Minimize shader variants — each variant is a separate compiled shader
- Document all keywords/variants and their purpose
- Use feature stripping where possible to reduce build size
- Log and monitor total variant count per shader
