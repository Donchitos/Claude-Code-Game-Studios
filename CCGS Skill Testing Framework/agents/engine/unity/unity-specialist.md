# Agent Test Spec: unity-specialist

## Agent Summary
Domain: Unity-specific architecture patterns, MonoBehaviour vs DOTS decisions, and subsystem selection (Addressables, New Input System, UI Toolkit, Cinemachine, etc.).
Does NOT own: language-specific deep dives (delegates to unity-dots-specialist, unity-ui-specialist, etc.).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Unity patterns / MonoBehaviour / subsystem decisions)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition acknowledges the sub-specialist routing table (DOTS, UI, Shader, Addressables)

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Should I use MonoBehaviour or ScriptableObject for storing enemy configuration data?"
**Expected behavior:**
- Produces a pattern decision tree covering:
  - MonoBehaviour: for runtime behavior, needs to be attached to a GameObject, has Update() lifecycle
  - ScriptableObject: for pure data/configuration, exists as an asset, shared across instances, no scene dependency
- Recommends ScriptableObject for enemy configuration data (stateless, reusable, designer-friendly)
- Notes that MonoBehaviour can reference the ScriptableObject for runtime use
- Provides a concrete example of what the ScriptableObject class definition looks like (does not produce full code — refers to engine-programmer or gameplay-programmer for implementation)

### Case 2: Wrong-engine redirect
**Input:** "Set up a Node scene tree with signals for this enemy system."
**Expected behavior:**
- Does NOT produce Godot Node/signal code
- Identifies this as a Godot pattern
- States that in Unity the equivalent is GameObject hierarchy + UnityEvent or C# events
- Maps the concepts: Godot Node → Unity MonoBehaviour, Godot Signal → C# event / UnityEvent
- Confirms the project is Unity-based before proceeding

### Case 3: Unity version API flag
**Input:** "Use the new Unity 6 GPU resident drawer for batch rendering."
**Expected behavior:**
- Identifies the Unity 6 feature (GPU Resident Drawer)
- Flags that this API may not be available in earlier Unity versions
- Asks for or checks the project's Unity version before providing implementation guidance
- Directs to verify against official Unity 6 documentation
- Does NOT assume the project is on Unity 6 without confirmation

### Case 4: DOTS vs. MonoBehaviour conflict
**Input:** "The combat system uses MonoBehaviour for state management, but we want to add a DOTS-based projectile system. Can they coexist?"
**Expected behavior:**
- Recognizes this as a hybrid architecture scenario
- Explains the hybrid approach: MonoBehaviour can interface with DOTS via SystemAPI, IComponentData, and managed components
- Notes the performance and complexity trade-offs of mixing the two patterns
- Recommends escalating the architecture decision to `lead-programmer` or `technical-director`
- Defers to `unity-dots-specialist` for the DOTS-side implementation details

### Case 5: Context pass — Unity version
**Input:** Project context provided: Unity 2023.3 LTS. Request: "Configure the new Input System for this project."
**Expected behavior:**
- Applies Unity 2023.3 LTS context: uses the New Input System (com.unity.inputsystem) package
- Does NOT produce legacy Input Manager code (`Input.GetKeyDown()`, `Input.GetAxis()`)
- Notes any 2023.3-specific Input System behaviors or package version constraints
- References the project version to confirm Burst/Jobs compatibility if the Input System interacts with DOTS

---

## Protocol Compliance

- [ ] Stays within declared domain (Unity architecture decisions, pattern selection, subsystem routing)
- [ ] Redirects Godot patterns to appropriate Godot specialists or flags them as wrong-engine
- [ ] Redirects DOTS implementation to unity-dots-specialist
- [ ] Redirects UI implementation to unity-ui-specialist
- [ ] Flags Unity version-gated APIs and requires version confirmation before suggesting them
- [ ] Returns structured pattern decision guides, not freeform opinions

---

## Coverage Notes
- MonoBehaviour vs. ScriptableObject (Case 1) should be documented as an ADR if it results in a project-level decision
- Version flag (Case 3) confirms the agent does not assume the latest Unity version without context
- DOTS hybrid (Case 4) verifies the agent escalates architecture conflicts rather than resolving them unilaterally
