# Agent Test Spec: web-shader-specialist

## Agent Summary
Domain: GLSL ES 3.0 and WGSL authoring, Three.js TSL/NodeMaterial, PixiJS custom filters, post-processing chains, WebGPU/WebGL2 cross-backend parity.
Does NOT own: art direction (art-director / technical-artist), scene graph and material assignment (three-specialist / pixi-specialist), architecture (web-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references GLSL, WGSL, and shaders
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section covering `RenderPipeline` and TSL expansion
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — Pixi custom filter
**Input:** "Write a chromatic aberration filter for PixiJS."
**Expected behavior:**
- Supplies **both** `glProgram` (GLSL) and `gpuProgram` (WGSL) sources
- Explains that supplying only one breaks on the other backend for a subset of users
- Declares uniforms with explicit types in the `resources` block
- Includes a header comment stating purpose, uniforms, and target backends
- Places the file under `assets/shaders/` following `[type]_[category]_[name].[ext]`

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Decide the game's overall color palette and visual mood."
**Expected behavior:**
- Does NOT make art direction decisions
- Redirects to `art-director` (and `technical-artist` for effect intent)
- May offer to implement a color-grading LUT shader once the palette is decided

### Case 3: Backend-appropriate authoring path
**Input:** "Write a raw GLSL ShaderMaterial for the Three.js WebGPU renderer."
**Expected behavior:**
- Flags that raw GLSL `ShaderMaterial` is **not** the WebGPU path
- Recommends **TSL / `NodeMaterial`**, noting it compiles to both WGSL and GLSL and so survives a backend switch
- Does not silently produce GLSL that will fail on WebGPU

### Case 4: Fill-rate cost awareness
**Input:** "Add a full-screen bloom pass."
**Expected behavior:**
- Notes fragment cost scales with resolution — a full-screen pass at native DPR on a 4K display is 8M+ invocations
- Recommends rendering bloom at **reduced resolution** and upsampling
- Recommends chaining passes into fewer shaders where possible
- Requires measuring cost on target hardware before shipping

### Case 5: Context pass — mobile precision
**Input:** Context states the project targets mid-range Android browsers. Request: "Write a water surface shader."
**Expected behavior:**
- Declares precision explicitly — mobile GPUs default differently than desktop
- Uses `mediump` for color and `highp` for positions/accumulated values
- Avoids `discard` (disables early-Z on many mobile GPUs) or justifies its use
- Minimizes texture samples, noting they dominate cost
- Requires verification on real mobile hardware, not just a desktop GPU

---

## Protocol Compliance

- [ ] Stays within declared domain (shader and post-processing authoring)
- [ ] Redirects art direction to art-director / technical-artist
- [ ] Always supplies both backend sources for PixiJS filters
- [ ] Uses TSL for Three.js WebGPU materials rather than raw GLSL strings
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Never ships an effect without stating how its cost should be measured

---

## Coverage Notes
- Case 1 and Case 3 both test backend parity, which is the defining hazard of web shader work and has no equivalent in the other three engines
- Case 5 verifies the agent applies provided target-hardware context rather than assuming desktop
- Shader files should be verified against `.claude/rules/shader-code.md` naming conventions
