# Agent Test Spec: godot-gdextension-specialist

## Agent Summary
Domain: GDExtension API, godot-cpp C++ bindings, godot-rust bindings, native library integration, and native performance optimization.
Does NOT own: GDScript code (gdscript-specialist), shader code (godot-shader-specialist).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GDExtension / godot-cpp / native bindings)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over GDScript or shader authoring

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Expose a C++ rigid-body physics simulation library to GDScript via GDExtension."
**Expected behavior:**
- Produces a GDExtension binding pattern using godot-cpp:
  - Class inheriting from `godot::Object` or an appropriate Godot base class
  - `GDCLASS` macro registration
  - `_bind_methods()` implementation exposing the physics API to GDScript
  - `GDExtension` entry point (`gdextension_init`) setup
- Notes the `.gdextension` manifest file format required
- Does NOT produce the GDScript usage code (that belongs to gdscript-specialist)

### Case 2: Out-of-domain redirect
**Input:** "Write the GDScript that calls the physics simulation from Case 1."
**Expected behavior:**
- Does NOT produce GDScript code
- Explicitly states that GDScript authoring belongs to `godot-gdscript-specialist`
- Redirects to `godot-gdscript-specialist`
- May describe the API surface the GDScript should call (method names, parameter types) as a handoff spec

### Case 3: ABI compatibility risk — minor version update
**Input:** "We're upgrading from Godot 4.5 to 4.6. Will our existing GDExtension still work?"
**Expected behavior:**
- Flags the ABI compatibility concern: GDExtension binaries may not be ABI-compatible across minor versions
- Directs to check the 4.5→4.6 migration guide for GDExtension API changes
- Recommends recompiling the extension against the 4.6 godot-cpp headers rather than assuming binary compatibility
- Notes that the `.gdextension` manifest may need a `compatibility_minimum` version update
- Provides the recompilation checklist

### Case 4: Memory management — RAII for Godot objects
**Input:** "How should we manage the lifecycle of Godot objects created inside C++ GDExtension code?"
**Expected behavior:**
- Produces the RAII-based lifecycle pattern for Godot objects in GDExtension:
  - `Ref<T>` for reference-counted objects (auto-released when Ref goes out of scope)
  - `memnew()` / `memdelete()` for non-reference-counted objects
  - Warning: do NOT use `new`/`delete` for Godot objects — undefined behavior
- Notes object ownership rules: who is responsible for freeing a node added to the scene tree
- Provides a concrete example managing a `CollisionShape3D` created in C++

### Case 5: Context pass — Godot 4.6 GDExtension API check
**Input:** Engine version context: Godot 4.6 (upgrading from 4.5). Request: "Check if any GDExtension APIs changed from 4.5 to 4.6."
**Expected behavior:**
- References the 4.5→4.6 migration guide from the VERSION.md verified sources list
- Reports on any documented GDExtension API changes in the 4.6 release
- If no breaking changes are documented for GDExtension in 4.6, states that explicitly with the caveat to verify against the official changelog
- Flags the D3D12 default on Windows (4.6 change) as potentially relevant for GDExtension rendering code
- Provides a checklist of what to verify after upgrading

---

## Protocol Compliance

- [ ] Stays within declared domain (GDExtension, godot-cpp, godot-rust, native bindings)
- [ ] Redirects GDScript authoring to godot-gdscript-specialist
- [ ] Redirects shader authoring to godot-shader-specialist
- [ ] Returns structured output (binding patterns, RAII examples, ABI checklists)
- [ ] Flags ABI compatibility risks on minor version upgrades — never assumes binary compatibility
- [ ] Uses Godot-specific memory management (`memnew`/`memdelete`, `Ref<T>`) not raw C++ new/delete
- [ ] Checks engine version reference for GDExtension API changes before confirming compatibility

---

## Coverage Notes
- Binding pattern (Case 1) should include a smoke test verifying the extension loads and the method is callable from GDScript
- ABI risk (Case 3) is a critical escalation path — the agent must not approve shipping an unverified extension binary
- Memory management (Case 4) verifies the agent applies Godot-specific patterns, not generic C++ RAII
