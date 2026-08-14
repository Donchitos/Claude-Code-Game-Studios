# Agent Test Spec: pixi-specialist

## Agent Summary
Domain: PixiJS v8 2D rendering — Application setup, Container hierarchy, sprites and atlases, batching and draw calls, ticker, text rendering, culling, filter application.
Does NOT own: shader authoring (web-shader-specialist), 3D rendering (three-specialist), architecture (web-specialist), asset budgets (web-platform-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references PixiJS and 2D rendering
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section that explicitly warns v7 patterns dominate training data
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — Application setup
**Input:** "Set up the PixiJS application at 1280x720."
**Expected behavior:**
- Uses **async init**: `const app = new Application(); await app.init({...})`
- Uses `app.canvas`, **never** `app.view`
- Uses named ESM imports from `pixi.js` — no `PIXI.*` global, no `@pixi/*` sub-packages
- Sets `resolution` from `devicePixelRatio` with `autoDensity`
- Notes that WebGPU is preferred automatically with WebGL2 fallback

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Write a custom WGSL shader for a water distortion filter."
**Expected behavior:**
- Does NOT author the shader code
- Redirects to `web-shader-specialist`
- May advise on where the filter attaches in the container hierarchy and its render-target cost

### Case 3: v7 pattern rejection (critical)
**Input:** "Load the hero texture: `const tex = new PIXI.Texture(new PIXI.BaseTexture('hero.png'));`"
**Expected behavior:**
- Flags that **`BaseTexture` no longer exists** in v8
- Explains textures no longer load resources — `Assets` owns loading
- Provides the correct form: `await Assets.load('hero.png')`
- Does not emit any `PIXI.*` global usage

### Case 4: Draw-call diagnosis
**Input:** "We're at 380 draw calls in a scene with 200 sprites. Why?"
**Expected behavior:**
- Identifies **batch breakers**: texture switches between siblings, mid-list filters, `blendMode` changes, `Graphics` interleaved with `Sprite`
- Recommends packing into a single atlas as the primary fix
- Recommends **measuring** draw calls before and after rather than guessing
- Does not propose unrelated micro-optimizations

### Case 5: Context pass — respects a shared atlas
**Input:** Context notes sprites share `atlas.json`. Request: "Clean up the level on scene transition."
**Expected behavior:**
- Calls `.destroy()` on containers and sprites — removal from the scene graph does not free GPU memory
- Uses `destroy({ children: true, texture: false })` because the texture is shared from the atlas
- Explicitly warns that destroying a shared texture would break every other user of it
- Notes the symptom of missing disposal: memory climbing across level transitions

---

## Protocol Compliance

- [ ] Stays within declared domain (PixiJS rendering)
- [ ] Redirects shader authoring to web-shader-specialist
- [ ] Never emits PixiJS v7 patterns (`app.view`, `BaseTexture`, `PIXI.*` global, sync `Application`)
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Reads `docs/engine-reference/web/deprecated-apis.md` before suggesting APIs
- [ ] Does not make 3D rendering decisions

---

## Coverage Notes
- Case 3 is the single most important test: v7 code is heavily represented in training data and does not run on v8
- Case 5 tests the shared-texture nuance, where a naive `destroy` breaks unrelated objects
- All cases should confirm the agent consults the reference docs before emitting API calls
