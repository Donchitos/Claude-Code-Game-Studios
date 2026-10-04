# Agent Test Spec: godot-gdextension-specialist

## Agent Summary
Domain: GDExtension API, godot-cpp C++ bindings, godot-rust bindings, native library integration, and native performance optimization.
Does NOT own: GDScript code (gdscript-specialist), shader code (godot-shader-specialist).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GDExtension / godot-cpp / native bindings)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
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
  - Module entry point: `initialize_module` in `register_types.cpp` registers the class with `ClassDB::register_class<T>()` at `MODULE_INITIALIZATION_LEVEL_SCENE`, reached from the exported init function named by the manifest's `entry_symbol`
- Notes the `.gdextension` manifest file format required
- Does NOT produce the GDScript usage code (that belongs to gdscript-specialist)

### Case 2: Out-of-domain redirect
**Input:** "Write the GDScript that calls the physics simulation from Case 1."
**Expected behavior:**
- Does NOT produce GDScript code
- Explicitly states that GDScript authoring belongs to `godot-gdscript-specialist`
- Redirects to `godot-gdscript-specialist`
- Any hand-off it offers is the extension's bound API surface (method names, parameter and return types) — not GDScript that calls it

### Case 3: ABI compatibility risk — minor version update
**Input:** "We're upgrading from Godot 4.5 to 4.6. Will our existing GDExtension still work?"
**Expected behavior:**
- States the compatibility direction: an extension built for 4.5 should load in 4.6, but not the reverse — so it may keep working, yet it must be re-tested, and rebuilt against 4.6 to use newer APIs
- Directs to check the 4.5→4.6 migration guide for GDExtension API changes
- Recommends rebuilding against the 4.6 godot-cpp headers rather than treating "should load" as tested
- Notes that the `.gdextension` manifest may need a `compatibility_minimum` version update
- Lays out the rebuild as a checklist: rebuild debug and release (`scons ... target=template_debug` / `template_release`, or `cargo build` / `cargo build --release`) for every target platform, update `compatibility_minimum`, then re-test in the 4.6 editor before shipping

### Case 4: Memory management — RAII for Godot objects
**Input:** "How should we manage the lifecycle of Godot objects created inside C++ GDExtension code?"
**Expected behavior:**
- Produces the RAII-based lifecycle pattern for Godot objects in GDExtension:
  - `Ref<T>` for reference-counted objects (auto-released when Ref goes out of scope)
  - `memnew()` / `memdelete()` for non-reference-counted objects
  - Warning: do NOT use `new`/`delete` for Godot objects — undefined behavior
- Notes object ownership rules: who is responsible for freeing a node added to the scene tree
- Its concrete example (e.g., a `CollisionShape3D` created in C++) applies both rules: the node is created with `memnew()` and handed to the scene tree with `add_child()`, after which the tree frees it (no `memdelete()`); its shape resource is held in a `Ref<>`; `memdelete()` is only for a node that never enters the tree

### Case 5: Context pass — Godot 4.6 GDExtension API check
**Input:** Engine version context: Godot 4.6 (upgrading from 4.5). Request: "Check if any GDExtension APIs changed from 4.5 to 4.6."
**Expected behavior:**
- References the 4.5→4.6 migration guide from the VERSION.md verified sources list
- Reads the 4.5 → 4.6 table in `docs/engine-reference/godot/breaking-changes.md` and states explicitly that it has no GDExtension-specific row, with the caveat to verify against the official changelog
- Still surfaces the listed 4.6 changes that reach native code: `Quaternion` now initializes to identity (it was zero)
- Flags the D3D12 default on Windows (4.6 change) as potentially relevant for GDExtension rendering code
- Provides a checklist of what to verify after upgrading

---

## Protocol Compliance

- [ ] Stays within declared domain (GDExtension, godot-cpp, godot-rust, native bindings)
- [ ] Redirects GDScript authoring to godot-gdscript-specialist
- [ ] Redirects shader authoring to godot-shader-specialist
- [ ] Returns structured output (binding patterns, RAII examples, ABI checklists)
- [ ] States that compatibility runs forward only (older build → newer Godot) and requires a re-test after an upgrade — never treats "should load" as tested
- [ ] Uses Godot-specific memory management (`memnew`/`memdelete`, `Ref<T>`) not raw C++ new/delete
- [ ] Checks engine version reference for GDExtension API changes before confirming compatibility
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Binding pattern (Case 1) should include a smoke test verifying the extension loads and the method is callable from GDScript
- ABI risk (Case 3) is a critical escalation path — the agent must not approve shipping an unverified extension binary
- Memory management (Case 4) verifies the agent applies Godot-specific patterns, not generic C++ RAII
