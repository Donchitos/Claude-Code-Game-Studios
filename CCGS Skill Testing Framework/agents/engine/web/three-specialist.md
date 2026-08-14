# Agent Test Spec: three-specialist

## Agent Summary
Domain: Three.js 3D rendering — renderer setup, scene graph, cameras, materials, GLTF/DRACO/KTX2 loading, lights and shadows, instancing, RenderPipeline post-processing.
Does NOT own: shader/TSL authoring (web-shader-specialist), 2D/HUD rendering (pixi-specialist), architecture (web-specialist), asset compression pipeline ownership (web-platform-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references Three.js and 3D rendering
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section stating Three.js removes deprecated code in most releases
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — renderer setup
**Input:** "Set up the Three.js renderer."
**Expected behavior:**
- Uses `WebGPURenderer` from `three/webgpu` as the default, not `WebGLRenderer`
- Includes `await renderer.init()` — initialization is asynchronous
- Caps `devicePixelRatio` (typically at 2) and explains the fill-rate reasoning
- Does NOT describe WebGPU as experimental — it has been production-ready since r171

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Write the TSL node graph for an iridescent car paint material."
**Expected behavior:**
- Does NOT author the TSL graph
- Redirects to `web-shader-specialist`
- May advise on where the material attaches and its render-order implications

### Case 3: Renamed API (critical)
**Input:** "Add bloom with `import { PostProcessing } from 'three/webgpu'`."
**Expected behavior:**
- Flags that `PostProcessing` was **renamed to `RenderPipeline` in r183**
- Provides the corrected import
- Cites `docs/engine-reference/web/deprecated-apis.md` rather than asserting from memory
- Delegates the bloom effect authoring to `web-shader-specialist`

### Case 4: Instancing decision
**Input:** "We're rendering 3,000 trees and the framerate is 22fps."
**Expected behavior:**
- Recommends `InstancedMesh` — one draw call instead of 3,000
- Specifies updating instance matrices **in place** with `instanceMatrix.needsUpdate = true`, never recreating the mesh per frame
- Mentions `BatchedMesh` as the option when geometries differ but share a material
- Does not recommend reducing tree count as the first answer

### Case 5: Context pass — memory growth across scenes
**Input:** Context reports GPU memory climbing 40MB per level transition. Request: "Find the leak."
**Expected behavior:**
- Identifies missing `.dispose()` on geometries, materials, and textures
- States explicitly that removing an object from the scene graph does **not** free GPU memory
- Provides a teardown path covering the array-vs-single material case
- Recommends verifying by cycling scenes repeatedly while watching memory

---

## Protocol Compliance

- [ ] Stays within declared domain (Three.js rendering)
- [ ] Redirects TSL/shader authoring to web-shader-specialist
- [ ] Never suggests an API without checking the reference docs first
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Does not make 2D/HUD rendering decisions
- [ ] Does not add Three.js addons without technical-director sign-off

---

## Coverage Notes
- Case 3 targets the highest-frequency stale API in this domain — the pre-r183 `PostProcessing` name dominates training data
- Case 5 tests the disposal rule, which is the most common source of web 3D memory bugs
- Case 1 confirms the agent does not repeat the outdated "WebGPU is experimental" guidance
