# Agent Test Spec: godot-specialist

## Agent Summary
Domain: Godot-specific patterns, node/scene architecture, signals, resources, and GDScript vs C# vs GDExtension decisions.
Does NOT own: actual code authoring in a specific language (delegates to language sub-specialists).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Godot architecture / node patterns / engine decisions)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition references `docs/engine-reference/godot/VERSION.md` as the authoritative API source

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "When should I use signals vs. direct method calls in Godot?"
**Expected behavior:**
- Produces a pattern decision guide with rationale:
  - Signals: decoupled communication, parent-to-child ignorance, event-driven UI updates, one-to-many notification
  - Direct calls: tightly-coupled systems where the caller needs a return value, or performance-critical hot paths
- Provides concrete examples of each pattern in the project's context
- Does NOT produce raw code for both patterns — refers to gdscript-specialist or csharp-specialist for implementation
- Notes the "no upward signals" convention (child does not call parent methods directly — uses signals instead)

### Case 2: Wrong-engine redirect
**Input:** "Write a MonoBehaviour that runs on Start() and subscribes to a UnityEvent."
**Expected behavior:**
- Does NOT produce Unity MonoBehaviour code
- Clearly identifies that this is a Unity pattern, not a Godot pattern
- Provides the Godot equivalent: a Node script using `_ready()` instead of `Start()`, and Godot signals instead of UnityEvent
- Confirms the project is Godot-based and redirects the conceptual mapping

### Case 3: Post-cutoff API risk
**Input:** "Use the new Godot 4.5 @abstract annotation to define an abstract base class."
**Expected behavior:**
- Identifies that `@abstract` is a post-cutoff feature (introduced in Godot 4.5, after LLM knowledge cutoff)
- Flags the version risk: LLM knowledge of this annotation may be incomplete or incorrect
- Directs the user to verify against `docs/engine-reference/godot/VERSION.md` and the official 4.5 migration guide
- Provides best-effort guidance based on the migration notes in the version reference while clearly marking it as unverified

### Case 4: Language selection for a hot path
**Input:** "The physics query loop runs every frame for 500 objects. Should we use GDScript or C# for this?"
**Expected behavior:**
- Provides a balanced analysis:
  - GDScript: simpler, team familiar, but slower for tight loops
  - C#: faster for CPU-intensive loops, requires .NET runtime, team needs C# knowledge
- Does NOT make the final decision unilaterally
- Defers the decision to `lead-programmer` with the analysis as input
- Notes that GDExtension (C++) is a third option for extreme performance cases and recommends escalating if C# is insufficient

### Case 5: Context pass — engine version 4.6
**Input:** Engine version context provided: Godot 4.6, Jolt as default physics. Request: "Set up a RigidBody3D for the player character."
**Expected behavior:**
- Reads the 4.6 context and applies the Jolt-default knowledge (from VERSION.md migration notes)
- Recommends RigidBody3D configuration choices that are Jolt-compatible (e.g., notes any GodotPhysics-specific settings that behave differently under Jolt)
- References the 4.6 migration note about Jolt becoming default rather than relying on LLM training data alone
- Flags any RigidBody3D properties that changed behavior between GodotPhysics and Jolt

---

## Protocol Compliance

- [ ] Stays within declared domain (Godot architecture decisions, node/scene patterns, language selection)
- [ ] Redirects language-specific implementation to godot-gdscript-specialist or godot-csharp-specialist
- [ ] Returns structured findings (decision trees, pattern recommendations with rationale)
- [ ] Treats `docs/engine-reference/godot/VERSION.md` as authoritative over LLM training data
- [ ] Flags post-cutoff API usage (4.4, 4.5, 4.6) with verification requirements
- [ ] Defers language-selection decisions to lead-programmer when trade-offs exist

---

## Coverage Notes
- Signal vs. direct call guide (Case 1) should be written to `docs/architecture/` as a reusable pattern doc
- Post-cutoff flag (Case 3) confirms the agent does not confidently use APIs it cannot verify
- Engine version case (Case 5) verifies the agent applies migration notes from the version reference, not assumptions
