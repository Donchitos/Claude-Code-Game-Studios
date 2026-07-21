# Agent Test Spec: godot-gdscript-specialist

## Agent Summary
Domain: GDScript static typing, design patterns in GDScript, signal architecture, coroutine/await patterns, and GDScript performance.
Does NOT own: shader code (godot-shader-specialist), GDExtension bindings (godot-gdextension-specialist).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GDScript / static typing / signals / coroutines)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
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
- May note that the GDScript side (passing uniforms to a shader, setting shader parameters) is within its domain

### Case 3: Async loading with coroutines
**Input:** "Load a scene asynchronously and wait for it to finish before spawning it."
**Expected behavior:**
- Produces an `await` + `ResourceLoader.load_threaded_request` pattern for Godot 4
- Uses static typing throughout (`var scene: PackedScene`)
- Handles the completion check with `ResourceLoader.load_threaded_get_status()`
- Notes error handling for failed loads
- Does NOT use deprecated Godot 3 `yield()` syntax

### Case 4: Performance issue — typed array recommendation
**Input:** "The entity update loop is slow; it iterates an untyped Array of 1,000 nodes every frame."
**Expected behavior:**
- Identifies that an untyped `Array` foregoes compiler optimization in GDScript
- Recommends converting to a typed array (`Array[Node]` or the specific type) to enable JIT hints
- Notes that if this is still insufficient, escalates the hot path to C# migration recommendation
- Produces the typed array refactor as the immediate fix
- Does NOT recommend migrating the entire codebase to C# without profiling evidence

### Case 5: Context pass — Godot 4.6 with post-cutoff features
**Input:** Engine version context provided: Godot 4.6. Request: "Create an abstract base class for all enemy types using @abstract."
**Expected behavior:**
- Identifies `@abstract` as a Godot 4.5+ feature (post-cutoff)
- Notes this in the output: feature introduced in 4.5, verified against VERSION.md migration notes
- Produces the GDScript class using `@abstract` with correct syntax as documented in migration notes
- Marks the output as requiring verification against the official 4.5 release notes due to post-cutoff status
- Uses static typing for all method signatures in the abstract class

---

## Protocol Compliance

- [ ] Stays within declared domain (GDScript — typing, patterns, signals, coroutines, performance)
- [ ] Redirects shader requests to godot-shader-specialist
- [ ] Redirects GDExtension requests to godot-gdextension-specialist
- [ ] Returns structured GDScript output with full static typing
- [ ] Uses Godot 4 API only — no deprecated Godot 3 patterns (yield, connect with strings, etc.)
- [ ] Flags post-cutoff features (4.4, 4.5, 4.6) and marks them as requiring doc verification

---

## Coverage Notes
- Type annotation review (Case 1) output is suitable as a code review checklist
- Async loading (Case 3) should produce testable code verifiable with a unit test in `tests/unit/`
- Post-cutoff @abstract (Case 5) confirms the agent flags version uncertainty rather than silently using unverified APIs
