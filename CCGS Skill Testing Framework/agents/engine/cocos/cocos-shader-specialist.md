# Agent Test Spec: cocos-shader-specialist

## Agent Summary
Domain: Cocos Creator Effect (`.effect`) files, CCEffect / CCProgram shader language, Material / RenderMaterial system, custom render pipeline passes (3.8+), 2D/3D shader optimization, and engine-injected built-in uniforms.
Does NOT own: TypeScript-side material wiring (delegates to cocos-ts-specialist), UI Material effects that need Mask or RichText interaction (delegates to cocos-ui-specialist), high-level rendering architecture (delegates to cocos-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Effect / CCEffect / CCProgram / Material / render pipeline)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition does not claim authority over TypeScript wiring, UI layout, or engine-wide architecture
- [ ] Agent definition references `docs/engine-reference/cocos/VERSION.md` for version awareness
- [ ] Agent definition references `docs/engine-reference/cocos/modules/rendering.md` for built-in uniform list

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Write an Effect file for a sprite that supports per-instance tint and alpha cutoff."
**Expected behavior:**
- Produces a complete `.effect` file with the `CCEffect %{ ... }%` block declaring `techniques` / `passes` / `properties`
- Sets `mainColor: { value: [1,1,1,1], linear: true }` — color is linear, not sRGB
- Uses `CCProgram vs %{ ... }%` and `CCProgram fs %{ ... }%` blocks for vertex/fragment
- Does NOT redeclare engine-injected uniforms (`cc_matViewProj`, `cc_matWorld`, etc.) — uses them directly
- Uses `out vec4 fragColor;` in the fragment shader (WebGL 2), not `gl_FragColor` (WebGL 1)
- Adds `batching: true` so the Effect can participate in sprite batching
- Mentions mini-game caveats (discard in WebGL 1)

### Case 2: Out-of-domain redirect
**Input:** "Write a TypeScript component that sets a Material on a MeshRenderer at runtime."
**Expected behavior:**
- Does NOT produce the Effect / shader code itself
- Explicitly states that runtime Material wiring belongs to `cocos-ts-specialist`
- May note the API surface it expects (`renderer.setMaterial(mat, 0)`, `Material` import from `'cc'`) so the TS specialist knows what material shape to provide
- Redirects appropriately

### Case 3: Built-in uniform flag
**Input:** "I redeclared `uniform Mat4 cc_matViewProj;` at the top of my Effect and now my scene renders black."
**Expected behavior:**
- Identifies the bug: engine injects `cc_matViewProj` automatically; redeclaring causes GLSL compile failure or a silent conflict
- References the engine-provided built-in uniform list in `docs/engine-reference/cocos/modules/rendering.md`
- Explains that `cc_matView`, `cc_matViewProj`, `cc_matWorld`, `cc_matWorldIT`, `cc_cameraPos`, `cc_time`, `cc_screenSize`, `cc_screenScale`, `cc_exposure`, `cc_mainLitDir`, `cc_mainLitColor`, `cc_ambientLit` are all injected
- Recommends removing the redeclaration and using the uniform directly
- Does NOT suggest writing a custom uniform that shadows the engine one

### Case 4: Mini-game shader constraint
**Input:** "I'm using `discard` for cutout alpha on a WeChat Mini Game build and seeing major FPS drops on low-end devices."
**Expected behavior:**
- Identifies the platform constraint: many mini-game platforms default to WebGL 1, where `discard` kills early-z optimization
- Recommends alpha-test (step / clip via texture.a) instead of `discard` where possible
- Notes the `cc.minigame.webgl1` macro for branching between WebGL 1 / 2 shader paths
- References performance targets from `docs/engine-reference/cocos/modules/rendering.md` (WeChat Mini Game: < 200 draw calls, < 50K triangles)
- Does NOT suggest "just upgrade to WebGL 2" — the platform controls this, not the project

### Case 5: Context pass — custom render pipeline
**Input:** Project context: Cocos Creator 3.8.6. Request: "I need a depth prepass before opaque, then a custom post-process pass. How do I wire this?"
**Expected behavior:**
- Applies 3.8+ context: `CustomRenderPipelineBuilder` and `RenderStage` API is stable
- Describes the TypeScript-side pipeline builder: subclass `CustomRenderPipelineBuilder`, override `setupCameras`, call `cam.setCustomStages([...])` with stage names
- Describes the Effect-side stage declaration: `stage: MyDepthPrepass` in the pass block
- Names the stages in correct order (depth prepass → opaque → transparent → post)
- Does NOT produce a full CustomRenderPipeline implementation — defers TS wiring to `cocos-ts-specialist`
- Asks which platforms to target before committing to a specific pipeline (mini-game has different constraints than native)

---

## Protocol Compliance

- [ ] Stays within declared domain (Effect file authoring, Material configuration, CCEffect/CCProgram shader language, custom render pipeline on shader side)
- [ ] Redirects TypeScript-side material / renderer wiring to cocos-ts-specialist
- [ ] Redirects UI Material effects (Mask / RichText integration) to cocos-ui-specialist
- [ ] Redirects high-level rendering architecture (asset pipeline, bundle strategy, feature cropping) to cocos-specialist
- [ ] Never uses `gl_FragColor` (WebGL 1 name) in modern Effect files
- [ ] Never redeclares engine-injected uniforms
- [ ] Always declares `batching: true` on custom Effects that should participate in sprite / mesh batching
- [ ] Flags Cocos Creator version-gated shader features (CustomRenderPipeline stability 3.8+, Box2D JSB-related features irrelevant to shaders, etc.) and confirms version before suggesting them

---

## Coverage Notes
- Built-in uniform redeclaration (Case 3) is the single most common Effect bug — verifies the agent catches it
- Mini-game constraint (Case 4) ensures the agent does not give desktop-only advice for a constrained platform
- CustomRenderPipeline context (Case 5) verifies the agent applies 3.8+ specific knowledge correctly and stays within its lane (shader-side only)
