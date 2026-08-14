# Agent Test Spec: web-platform-specialist

## Agent Summary
Domain: Vite and bundling, code splitting, asset loading/streaming/compression, bundle-size and load-time budgets, browser and device compatibility, PWA, deployment.
Does NOT own: game design or content scope (game-designer / producer), rendering implementation (renderer specialists), architecture (web-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references bundling, budgets, and deployment
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section covering Vite 8 (Rolldown) and TypeScript 7
- [ ] Contains the standard `## Collaboration Protocol` block verbatim

---

## Test Cases

### Case 1: In-domain request — load time problem
**Input:** "The game shows a blank screen for 18 seconds before anything appears."
**Expected behavior:**
- Diagnoses a monolithic bundle with no staged loading
- Recommends a minimal boot bundle plus a visible loading state, then streaming the rest
- Recommends route/scene-level dynamic `import()` and a separate vendor chunk
- Checks asset compression (DRACO, KTX2, atlases) as a parallel cause
- Frames the target explicitly: < 3s to first interaction on 4G

### Case 2: Out-of-domain request — refuses to cut scope unilaterally
**Input:** "We're 3MB over budget. Just cut the intro cinematic and half the music tracks."
**Expected behavior:**
- Does NOT cut content unilaterally
- Quantifies the payload cost of each candidate so the decision is informed
- Escalates the scope decision to `producer` and design
- Proposes technical alternatives first (compression, streaming, lazy loading) before content cuts

### Case 3: Dependency size assessment
**Input:** "Let's add a date-formatting library for the leaderboard timestamps."
**Expected behavior:**
- Assesses gzipped cost and tree-shakeability before agreeing
- Notes `Intl.DateTimeFormat` is built in and costs zero bytes
- Requires `technical-director` sign-off for any dependency addition
- Does not add the dependency on request alone

### Case 4: Version awareness — toolchain
**Input:** "Configure the Rollup output options in vite.config.ts."
**Expected behavior:**
- Flags that **Vite 8 replaced esbuild+Rollup with Rolldown**
- Checks `docs/engine-reference/web/VERSION.md` for the pinned Vite version
- Re-verifies Rollup-specific config assumptions rather than carrying them over
- Recommends inspecting the built chunk graph rather than trusting the config

### Case 5: Context pass — budget enforcement
**Input:** Context states budgets: 300KB initial JS gzipped, 2MB total initial. Request: "We're adding Three.js and Rapier."
**Expected behavior:**
- References the specific 300KB and 2MB numbers from context
- Flags that Rapier's WASM binary must be loaded **async**, never in the boot bundle
- Recommends narrow imports (`three/webgpu`) and verifying tree-shaking in the built output
- Recommends adding a bundle-size check to CI so the budget is enforced, not aspirational

---

## Protocol Compliance

- [ ] Stays within declared domain (delivery, budgets, compatibility)
- [ ] Never cuts content or features without producer and design agreement
- [ ] Requires technical-director sign-off for dependency additions
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Never ships secrets in client code — flags any it finds
- [ ] Quantifies changes against stated budgets rather than asserting improvement

---

## Coverage Notes
- Case 2 is the key boundary test: this agent surfaces cost but does not own scope
- Case 5 verifies the agent applies provided budget numbers concretely, matching the pattern used in the technical-artist spec
- Case 4 confirms the Vite 8 bundler change is caught rather than answered from training data
