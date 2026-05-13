# Agent Test Spec: cocos-specialist

## Agent Summary
Domain: Cocos Creator-specific architecture patterns, Asset Manager vs. resources API decisions, bundle management, mini-game platform targeting, and subsystem routing (TS, Shader, UI).
Does NOT own: TypeScript deep dives (delegates to cocos-ts-specialist), Effect file authoring (delegates to cocos-shader-specialist), UI implementation (delegates to cocos-ui-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Cocos Creator / Asset Manager / mini-game / TypeScript)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition acknowledges the sub-specialist routing table (TS, Shader, UI)
- [ ] Agent definition references `docs/engine-reference/cocos/VERSION.md` for version awareness

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Should I use `resources.load()` or `assetManager.loadBundle()` for loading level prefabs?"
**Expected behavior:**
- Produces a pattern decision tree covering:
  - `resources.load()`: simple, synchronous-feeling API for small assets in `assets/resources/` — but increases main package size, no lazy loading
  - `assetManager.loadBundle()`: bundles allow on-demand loading, smaller main package (≤4MB mini-game requirement), supports preloading
- Recommends `assetManager.loadBundle()` for level prefabs (level content is on-demand, bundle per level is idiomatic)
- Notes that `resources/` is special — reserved for project-wide configs (`JsonAsset`, `TextAsset`), not for content
- Provides a concrete example of the bundle loading pattern (does not produce full code — refers to cocos-ts-specialist for TypeScript implementation)
- Does NOT recommend `cc.loader.loadRes()` (removed in v3.0)

### Case 2: Wrong-engine redirect
**Input:** "Set up a MonoBehaviour for the player character with `Update()` loop."
**Expected behavior:**
- Does NOT produce Unity MonoBehaviour / C# code
- Identifies this as a Unity pattern
- States that in Cocos Creator the equivalent is a `Component` subclass with `update(dt: number)` lifecycle
- Maps the concepts: Unity MonoBehaviour → Cocos `Component`, Unity `Update()` → Cocos `update(dt)`
- Confirms the project is Cocos Creator-based before proceeding

### Case 3: Cocos Creator version API flag
**Input:** "Use `node.x` and `node.y` shortcuts for player movement in `update()`."
**Expected behavior:**
- Identifies the v3.8.6 context: `node.x` / `node.y` getter/setter shortcuts were restored in v3.8.6
- Flags that these are slower than direct Vec3 manipulation (they internally call `getPosition()` / `setPosition()`)
- Recommends `node.position.x` or `node.setPosition()` for hot loops / `update()`
- Allows `node.x` for readability in non-performance-critical code
- Asks for or checks the project's Cocos Creator version before providing guidance
- Does NOT assume the project is on v3.8.6 without confirmation

### Case 4: Mini-game platform targeting
**Input:** "We're targeting WeChat Mini Game and need to fit within 4MB main package."
**Expected behavior:**
- Identifies the WeChat Mini Game constraint: ≤4MB main package, sub-packages for content
- Recommends the architecture:
  - Engine separation plugin (load engine from CDN, not bundled)
  - Asset bundles for content (each sub-package ≤4MB)
  - Compress textures (ETC2 / PVRTC fallback)
  - Disable unused engine modules via Feature Cropping
- Notes that `resources/` content is always in the main package — keep it minimal
- Recommends testing on WeChat DevTools for memory profiling
- Does NOT suggest PC-only patterns (e.g., synchronous file access)

### Case 5: Context pass — Cocos Creator version
**Input:** Project context provided: Cocos Creator 3.8.6. Request: "Configure the Box2D physics variant for an iOS native build."
**Expected behavior:**
- Applies 3.8.6 context: three Box2D variants available (TS, WASM, JSB)
- Recommends Box2D JSB (C++ native binding) for iOS — best perf without JIT penalty on iOS
- Notes that JSB is native-only; web / mini-game builds fall back to TS automatically
- Directs to Project Settings → Physics → 2D Physics for selection
- References `docs/engine-reference/cocos/modules/physics.md` for variant trade-offs

---

## Protocol Compliance

- [ ] Stays within declared domain (Cocos Creator architecture decisions, bundle / Asset Manager patterns, mini-game targeting, subsystem routing)
- [ ] Redirects Unity / Godot / Unreal patterns to appropriate specialists or flags them as wrong-engine
- [ ] Redirects TypeScript implementation to cocos-ts-specialist
- [ ] Redirects Effect file / material authoring to cocos-shader-specialist
- [ ] Redirects UI implementation to cocos-ui-specialist
- [ ] Flags Cocos Creator version-gated APIs (v3.0 removals, v3.8.6 restorations) and requires version confirmation
- [ ] Never recommends deprecated APIs from `docs/engine-reference/cocos/deprecated-apis.md` (e.g., `cc.loader`, `cc.Class`, `cc.audioEngine`)
- [ ] Returns structured pattern decision guides, not freeform opinions

---

## Coverage Notes
- `resources.load()` vs `assetManager.loadBundle()` (Case 1) should be documented as an ADR if it results in a project-level decision
- Version flag (Case 3) confirms the agent does not assume v3.8.6 features without context
- Mini-game targeting (Case 4) verifies the agent understands platform-specific constraints, not just generic Cocos patterns
- Box2D variant (Case 5) verifies the agent applies 3.8.6-specific knowledge correctly
