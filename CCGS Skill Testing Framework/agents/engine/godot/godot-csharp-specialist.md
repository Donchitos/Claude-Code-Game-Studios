# Agent Test Spec: godot-csharp-specialist

## Agent Summary
Domain: C# patterns in Godot 4, .NET idioms applied to Godot, [Export] attribute usage, signal delegates, and async/await patterns.
Does NOT own: GDScript code (gdscript-specialist), GDExtension C/C++ bindings (gdextension-specialist).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references C# in Godot 4 / .NET patterns / signal delegates)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over GDScript or GDExtension code

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create an export property for enemy health with validation that clamps it between 1 and 1000."
**Expected behavior:**
- Produces a C# property with `[Export]` attribute
- Uses a backing field with a property getter/setter that clamps the value in the setter
- Does NOT use a raw `[Export]` public field without validation
- Follows Godot 4 C# naming conventions (PascalCase for properties, fields private with underscore prefix)
- Includes XML doc comment on the property per coding standards

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Rewrite this enemy health system in GDScript."
**Expected behavior:**
- Does NOT produce GDScript code
- Explicitly states that GDScript authoring belongs to `godot-gdscript-specialist`
- Redirects the request to `godot-gdscript-specialist`
- May note that the C# interface can be described so the gdscript-specialist knows the expected API shape

### Case 3: Async signal awaiting
**Input:** "Wait for an animation to finish before transitioning game state using C# async."
**Expected behavior:**
- Produces a proper `async Task` pattern using `ToSignal()` to await a Godot signal
- Uses `await ToSignal(animationPlayer, AnimationPlayer.SignalName.AnimationFinished)`
- Does NOT use `Thread.Sleep()` or `Task.Delay()` as a polling substitute
- Notes that the calling method must be `async` and that fire-and-forget `async void` is only acceptable for event handlers
- Handles cancellation or timeout if the animation could fail to fire

### Case 4: Threading model conflict
**Input:** "This C# code accesses a Godot Node from a background Task thread to update its position."
**Expected behavior:**
- Flags this as a race condition risk: Godot nodes are not thread-safe and must only be accessed from the main thread
- Does NOT approve or implement the multi-threaded node access pattern
- Provides the correct pattern: use `CallDeferred()`, `Callable.From().CallDeferred()`, or marshal back to the main thread via a thread-safe queue
- Explains the distinction between Godot's main thread requirement and .NET's thread-agnostic types

### Case 5: Context pass — Godot 4.6 API correctness
**Input:** Engine version context: Godot 4.6. Request: "Connect a signal using the new typed signal delegate pattern."
**Expected behavior:**
- Produces C# signal connection using the typed delegate pattern introduced in Godot 4 C# (`+=` operator on typed signal)
- Checks the 4.6 context to confirm no breaking changes to the signal delegate API in 4.4, 4.5, or 4.6
- Does NOT use the old string-based `Connect("signal_name", callable)` pattern (deprecated in Godot 4 C#)
- Produces code compatible with the project's pinned 4.6 version as documented in VERSION.md

---

## Protocol Compliance

- [ ] Stays within declared domain (C# in Godot 4 — patterns, exports, signals, async)
- [ ] Redirects GDScript requests to godot-gdscript-specialist
- [ ] Redirects GDExtension requests to godot-gdextension-specialist
- [ ] Returns C# code following Godot 4 conventions (not Unity MonoBehaviour patterns)
- [ ] Flags multi-threaded Godot node access as unsafe and provides the correct pattern
- [ ] Uses typed signal delegates — not deprecated string-based Connect() calls
- [ ] Checks engine version reference for API changes before producing code

---

## Coverage Notes
- Export property with validation (Case 1) should have a unit test verifying the clamp behavior
- Threading conflict (Case 4) is safety-critical: the agent must identify and fix this without prompting
- Async signal (Case 3) verifies the agent applies .NET idioms correctly within Godot's single-thread constraint
