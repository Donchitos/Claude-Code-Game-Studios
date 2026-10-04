# Agent Test Spec: godot-gdscript-specialist

## Agent Summary
Domain: GDScript static typing, design patterns in GDScript, signal architecture, coroutine/await patterns, and GDScript performance.
Does NOT own: shader code (godot-shader-specialist), GDExtension bindings (godot-gdextension-specialist).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GDScript / static typing / signals / coroutines)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over shader code or GDExtension

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Review this GDScript file for type annotation coverage."
**Expected behavior:**
- Reads the provided GDScript file
- Flags every variable, parameter, and return type that is missing a static type annotation
- Produces a list of specific line-by-line findings: `var speed = 5.0` → `var speed: float = 5.0`
- Notes the performance and tooling benefits of static typing in Godot 4
- Does NOT rewrite the entire file unprompted — produces a findings list for the developer to apply

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Write a vertex shader to distort the mesh in world space."
**Expected behavior:**
- Does NOT produce shader code in GDScript or in Godot's shading language
- Explicitly states that shader authoring belongs to `godot-shader-specialist`
- Redirects the request to `godot-shader-specialist`
- Any help it offers stays on the script side its redirect line says it owns (`set_shader_parameter()`, material assignment) — it writes no shader code

### Case 3: Async loading with coroutines
**Input:** "Load a scene asynchronously and wait for it to finish before spawning it."
**Expected behavior:**
- Produces an `await` + `ResourceLoader.load_threaded_request` pattern for Godot 4
- Uses static typing throughout (`var scene: PackedScene`)
- Handles the completion check with `ResourceLoader.load_threaded_get_status()`, awaiting between polls rather than blocking the frame
- Checks `is_instance_valid(self)` after the await before spawning — the node may have been freed while the scene loaded
- Notes error handling for failed loads
- Does NOT use deprecated Godot 3 `yield()` syntax

### Case 4: Performance issue — typed array recommendation
**Input:** "The entity update loop is slow; it iterates an untyped Array of 1,000 nodes every frame."
**Expected behavior:**
- Identifies that an untyped `Array` foregoes GDScript compiler optimizations
- Recommends converting to a typed array (`Array[Node]` or the specific type) so the compiler can use typed code paths
- Produces the typed array refactor as the immediate fix
- Notes that if profiling still shows the loop as a bottleneck, the next step is moving the hot path to GDExtension (C++/Rust) with godot-gdextension-specialist, per its GDScript/GDExtension boundary
- Does NOT recommend moving the loop, or the codebase, out of GDScript without profiler evidence

### Case 5: Context pass — Godot 4.6 with post-cutoff features
**Input:** Engine version context provided: Godot 4.6. Request: "Create an abstract base class for all enemy types using @abstract."
**Expected behavior:**
- Identifies `@abstract` as a Godot 4.5+ feature (post-cutoff)
- Notes this in the output: feature introduced in 4.5, confirmed against `docs/engine-reference/godot/breaking-changes.md` (4.4 → 4.5 table)
- Produces the GDScript class using `@abstract` on the class and its abstract methods, following the reference docs (`current-best-practices.md`) rather than training data
- Flags that `VERSION.md` records `Installed at pin time` as NOT DETERMINED — the installed editor must be 4.5 or later for `@abstract` to parse
- Uses static typing for all method signatures in the abstract class

---

## Protocol Compliance

- [ ] Stays within declared domain (GDScript — typing, patterns, signals, coroutines, performance)
- [ ] Redirects shader requests to godot-shader-specialist
- [ ] Redirects GDExtension requests to godot-gdextension-specialist
- [ ] Returns structured GDScript output with full static typing
- [ ] Uses Godot 4 API only — no deprecated Godot 3 patterns (yield, connect with strings, etc.)
- [ ] Flags post-cutoff features (4.4, 4.5, 4.6) and marks them as requiring doc verification
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Type annotation review (Case 1) output is suitable as a code review checklist
- Async loading (Case 3) should produce testable code verifiable with a unit test in `tests/unit/`
- Post-cutoff @abstract (Case 5) confirms the agent flags version uncertainty rather than silently using unverified APIs
