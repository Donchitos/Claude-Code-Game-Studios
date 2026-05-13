# Cocos Creator Rendering — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — Renderer rewrite
- New forward renderer, deferred (limited), forward+ (3D lighting)
- **Material / Effect** system: YAML → `CCEffect` + `CCProgram` (3.5 finalized)
- **Batching**: built-in for sprites and meshes; `Instancing` uniforms for GPU instancing
- **RenderTexture**, **Camera**, **Mask**, **Graphics** components rewritten

### v3.5 — Material system stabilized
- Property format `{ value, linear, target }` standardized
- Built-in effects moved to engine (`internal/effects/`)
- `RenderPipeline` API for custom pipeline (early form)

### v3.8 — Custom Render Pipeline (full)
- `CustomRenderPipelineBuilder` API stabilized
- Custom render stages and passes
- Improved post-processing chain

### v3.8.6 — WebGPU + ASTC 5.2
- **WebGPU support strengthened** — experimental on web platforms
- **ASTC texture compression v5.2.0** — faster build-time compression
- **2D Assembler refactor** — internal; affects custom 2D renderers extending `Assembler2D` (rare)

## Current API Patterns

### Camera setup
```typescript
import { Camera } from 'cc';

const cam = this.getComponent(Camera)!;
cam.fov = 60;
cam.near = 0.1;
cam.far = 1000;
cam.clearFlags = Camera.ClearFlag.ALL;
cam.projection = Camera.Projection.PERSPECTIVE;
cam.priority = 0;  // lower = rendered first
```

### Multi-camera compositing
- Multiple cameras render in `priority` order
- Set `camera.visibility` (bitmask) to filter which layers each camera sees
- Use `RenderTexture` to capture a camera's output and use it as a texture elsewhere

### Material assignment
```typescript
import { MeshRenderer, Material } from 'cc';

const renderer = this.getComponent(MeshRenderer)!;
const mat = await loadAsync(bundle, 'materials/character', Material);
renderer.setMaterial(mat, 0);  // 0 = sub-mesh index
```

### Built-in engine uniforms (always available)
```glsl
// In Effect file — these are injected, do NOT redefine
uniform Mat4 cc_matViewProj;       // view-projection matrix
uniform Mat4 cc_matWorld;          // model-to-world
uniform Mat4 cc_matWorldIT;        // world matrix inverse-transpose (for normals)
uniform Vec3 cc_cameraPos;         // camera world position
uniform Vec4 cc_time;              // seconds since startup (x = sec, y = sec/20, z = sec*20, w = frame)
uniform Vec4 cc_screenSize;        // viewport in pixels
uniform Vec4 cc_screenScale;       // DPR-aware scaling
uniform float cc_exposure;         // camera exposure
uniform Vec3 cc_mainLitDir;        // main directional light dir (3D)
uniform Vec4 cc_mainLitColor;     // main light color + intensity
uniform Vec4 cc_ambientLit;        // ambient light color
```

### Custom Render Pipeline (3.8+)
```typescript
import { CustomRenderPipelineBuilder, Camera } from 'cc';

@ccclass('MyPipelineBuilder')
export class MyPipelineBuilder extends CustomRenderPipelineBuilder {
    setupCameras(cameras: Camera[]): void {
        for (const cam of cameras) {
            cam.setCustomStages([
                'MyDepthPrepass',
                'MyOpaque',
                'MyTransparent',
                'MyPostProcess',
            ]);
        }
    }
}
```

In Effect file:
```glsl
CCEffect %{
  techniques:
  - name: opaque
    passes:
    - vert: vs:vert
      frag: fs:frag
      stage: MyOpaque  // custom stage name
      properties: { ... }
}%
```

## Built-in Materials vs. Custom Effects

| Use Case | Approach |
|----------|---------|
| Standard PBR mesh | `builtin-pbr` material (no custom Effect) |
| Unlit mesh | `builtin-unlit` material |
| Sprite with simple texture | `builtin-sprite` material |
| Sprite with tint / clip | `builtin-sprite-tint` material |
| Custom shader (water, dissolve) | Custom `.effect` file |
| Post-processing | Custom render pipeline + Effect |

## Batching Rules

- Same Material + same Texture = auto-batched
- **Custom Effect must declare `batching: true`** to participate in batching
- Use `Instancing` block in Effect for GPU instancing (large number of identical meshes)
- `Mask` and `Graphics` components break batching for their subtree
- Static meshes: enable `batchingStatic` on the MeshRenderer (3.8+)

## Texture Compression Per Platform

| Platform | Format | Compression |
|----------|--------|-------------|
| iOS / iPadOS | `.astc` | ASTC 4x4 or 6x6 |
| Android | `.ktx` | ETC2 (or ASTC for modern devices) |
| Web (Desktop) | `.png` / `.webp` | Uncompressed or WebP |
| Web (Mobile) | `.ktx` | ETC2 (limited WebGL 1) |
| WeChat Mini Game | `.ktx` | ETC2 (or PVRTC fallback) |

Configure in **Asset Import Settings → Texture Compression → Platform Overrides**.

## Performance Targets (per platform)

| Platform | Draw Calls | Triangles | Texture Memory |
|----------|-----------|-----------|---------------|
| Web (Desktop) | < 1500 | < 500K | < 256MB |
| Web (Mobile) | < 300 | < 100K | < 64MB |
| WeChat Mini Game | < 200 | < 50K | < 32MB |
| Native iOS | < 500 | < 200K | < 128MB |
| Native Android | < 400 | < 200K | < 128MB |

## Common Mistakes
- Redefining `cc_matViewProj` etc. in Effect — engine injects these; redefine → black screen
- Forgetting `linear: true` on color properties — wrong gamma after correction
- Using `gl_FragColor` (WebGL 1 name) instead of declared `out vec4 fragColor` — fails on WebGL2 default
- Loading UI textures without atlas — kills batching for whole UI
- Setting mipmap on UI textures — causes edge shimmer
- Custom Effect without `batching: true` → breaks batching, perf cliff
- Using `discard` for cutout effects on mini-game (WebGL 1) — kills early-z
- Forgetting to set `camera.priority` for multi-camera setups — wrong render order
- Texture compression not configured per platform → defaults to uncompressed PNG, huge bundles
