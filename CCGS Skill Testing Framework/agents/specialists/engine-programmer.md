# Agent Test Spec: engine-programmer

## Agent Summary
Domain: Rendering pipeline, physics integration, memory management, resource loading, and core engine framework.
Does NOT own: gameplay mechanics (gameplay-programmer), editor/debug tool UI (tools-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references rendering / memory / engine core)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over gameplay mechanics or tool UI

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Implement a custom object pool for projectiles to avoid per-frame allocation."
**Expected behavior:**
- Produces an engine-level object pool implementation with acquire/release interface
- Pool is typed to the projectile object type, uses pre-allocated fixed-size storage
- Provides thread-safety notes (or clearly marks as single-threaded-only with rationale)
- Includes doc comments on the public API per coding standards
- Output is compatible with the project's configured engine and language

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Add a pause menu screen with volume sliders and a 'back to main menu' button."
**Expected behavior:**
- Does NOT produce UI screen code
- Explicitly states that menu screens belong to `ui-programmer`
- Redirects the request to `ui-programmer`
- May note it can provide engine-level audio volume API endpoints for the ui-programmer to call

### Case 3: Memory leak diagnosis
**Input:** "Memory usage grows by ~50MB per level load and never releases. We suspect the resource loading system."
**Expected behavior:**
- Produces a systematic diagnosis approach: reference counting audit, resource handle lifecycle check, cache invalidation review
- Identifies likely causes (orphaned resource handles, circular references, cache that never evicts)
- Produces a concrete fix for the identified leak pattern
- Provides a test to verify the fix (memory baseline before load, measure after unload, confirm return to baseline)

### Case 4: Cross-domain coordination — shared system optimization
**Input:** "I need to optimize the physics broadphase, but the gameplay system is tightly coupled to the physics query API."
**Expected behavior:**
- Does NOT unilaterally change the physics query API surface (would break gameplay-programmer's code)
- Coordinates with `lead-programmer` to plan the change safely
- Proposes a migration path: new optimized API alongside old API, with a deprecation period
- Documents the coordination requirement before proceeding

### Case 5: Context pass — checks engine version reference
**Input:** Engine version reference (Godot 4.6) provided in context. Request: "Set up the default physics engine for the project."
**Expected behavior:**
- Reads the engine version reference and notes Godot 4.6 change: Jolt physics is now the default
- Produces configuration guidance that accounts for the Jolt-as-default change (4.6 migration note)
- Flags any API differences between GodotPhysics and Jolt that could affect existing code
- Does NOT suggest deprecated or pre-4.6 physics setup steps without noting they apply to older versions

---

## Protocol Compliance

- [ ] Stays within declared domain (rendering, physics, memory, resource loading, core framework)
- [ ] Redirects UI/menu requests to ui-programmer
- [ ] Returns structured findings (implementation code, diagnosis steps, migration plans)
- [ ] Coordinates with lead-programmer before changing shared API surfaces
- [ ] Checks engine version reference before suggesting engine-specific APIs
- [ ] Provides test evidence for fixes (memory before/after, performance measurements)

---

## Coverage Notes
- Object pool (Case 1) must include a unit test in `tests/unit/engine/`
- Memory leak diagnosis (Case 3) should produce evidence artifacts in `production/qa/evidence/`
- Engine version check (Case 5) confirms the agent treats VERSION.md as authoritative, not LLM training data
