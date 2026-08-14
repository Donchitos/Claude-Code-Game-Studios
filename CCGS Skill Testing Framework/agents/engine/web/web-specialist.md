# Agent Test Spec: web-specialist

## Agent Summary
Domain: Browser game architecture — renderer choice (PixiJS/Three.js/both), game loop and fixed timestep, WebGPU vs WebGL2 strategy, project structure, module boundaries.
Does NOT own: game design decisions (game-designer), specific rendering implementation (pixi-specialist / three-specialist), bundling and deployment (web-platform-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and references PixiJS and Three.js
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Sub-Specialist Orchestration` section naming all 6 sub-specialists
- [ ] Has a `## Version Awareness` section pointing to `docs/engine-reference/web/`
- [ ] Version Awareness states the web knowledge gap is **permanently HIGH**
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — game loop architecture
**Input:** "Set up the main game loop for our 2D platformer."
**Expected behavior:**
- Proposes a **fixed timestep with an accumulator**, not raw `requestAnimationFrame` delta
- Includes a delta **clamp** and explains the tab-refocus spiral-of-death it prevents
- Separates `update()` from `render()` and states that `update()` must be headlessly testable with no canvas
- Notes that entry points must be `async` because both libraries initialize asynchronously
- Asks for approval before writing files

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Decide whether the double jump should have a cooldown, and what the jump arc should feel like."
**Expected behavior:**
- Does NOT make the design decision
- Explicitly redirects to `game-designer`
- May offer to advise on platform implications (e.g., input latency in the browser) once the mechanic is decided

### Case 3: Renderer selection reasoning
**Input:** "We're building a 3D puzzle game with a 2D inventory overlay. Which renderer?"
**Expected behavior:**
- Recommends Three.js for the 3D scene
- Does NOT reflexively recommend adding PixiJS — notes a **DOM overlay** handles most 2D UI at zero bundle cost
- States the payload cost of shipping both libraries as the deciding factor
- Defers to `web-ui-specialist` on the DOM-vs-canvas UI decision

### Case 4: Version awareness — stale API
**Input:** "Add post-processing bloom using the PostProcessing class."
**Expected behavior:**
- Reads `docs/engine-reference/web/` before answering
- Flags that `PostProcessing` was **renamed to `RenderPipeline` in r183**
- Does not emit code using the old name
- Delegates the effect authoring itself to `web-shader-specialist`

### Case 5: Delegation — parallel sub-specialist dispatch
**Input:** "Implement the HUD: health bar, score, and a shader-driven damage vignette."
**Expected behavior:**
- Decomposes across sub-specialists rather than implementing directly
- Routes HUD/DOM work to `web-ui-specialist` and the vignette to `web-shader-specialist`
- Launches independent Task calls in parallel where inputs do not depend on each other
- Provides full context (file paths, budgets, constraints) in each delegation prompt

---

## Protocol Compliance

- [ ] Stays within declared domain (architecture, loop, renderer strategy, structure)
- [ ] Redirects design decisions to game-designer
- [ ] Delegates implementation to sub-specialists rather than writing rendering code itself
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Reads engine reference docs before suggesting any library API
- [ ] Does not add dependencies without technical-director sign-off

---

## Coverage Notes
- Case 1 verifies the fixed-timestep rule, which is the highest-value architectural guidance this agent carries
- Case 3 tests judgment against over-engineering — recommending both libraries when a DOM overlay suffices is the failure mode
- Case 4 confirms VERSION.md is treated as authoritative over training data
