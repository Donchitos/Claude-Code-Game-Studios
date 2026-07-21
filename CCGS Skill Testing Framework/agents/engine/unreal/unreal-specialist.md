# Agent Test Spec: unreal-specialist

## Agent Summary
- **Domain**: Unreal Engine patterns and architecture — Blueprint vs C++ decisions, UE subsystems (GAS, Enhanced Input, Niagara), UE project structure, plugin integration, and engine-level configuration
- **Does NOT own**: Art style and visual direction (art-director), server infrastructure and deployment (devops-engineer), UI/UX flow design (ux-designer)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; defers gate verdicts to technical-director

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Unreal Engine)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority outside its declared domain (no art, no server infra)

---

## Test Cases

### Case 1: In-domain request — Blueprint vs C++ decision criteria
**Input**: "Should I implement our combo attack system in Blueprint or C++?"
**Expected behavior**:
- Provides structured decision criteria: complexity, reuse frequency, team skill, and performance requirements
- Recommends C++ for systems called every frame or shared across 5+ ability types
- Recommends Blueprint for designer-tunable values and one-off logic
- Does NOT render a final verdict without knowing project context — asks clarifying questions if context is absent
- Output is structured (criteria table or bullet list), not a freeform opinion

### Case 2: Out-of-domain request — Unity C# code
**Input**: "Write me a C# MonoBehaviour that handles player health and fires a Unity event on death."
**Expected behavior**:
- Does not produce Unity C# code
- States clearly: "This project uses Unreal Engine; the Unity equivalent would be an Actor Component in UE C++ or a Blueprint Actor Component"
- Optionally offers to provide the UE equivalent if requested
- Does not redirect to a Unity specialist (none exists in the framework)

### Case 3: Domain boundary — UE5.4 API requirement
**Input**: "I need to use the new Motion Matching API introduced in UE5.4."
**Expected behavior**:
- Flags that UE5.4 is a specific version with potentially limited LLM training coverage
- Recommends cross-referencing official Unreal docs or the project's engine-reference directory before trusting any API suggestions
- Provides best-effort API guidance with explicit uncertainty markers (e.g., "Verify this against UE5.4 release notes")
- Does NOT silently produce stale or incorrect API signatures without a caveat

### Case 4: Conflict — Blueprint spaghetti in a core system
**Input**: "Our replication logic is entirely in a deeply nested Blueprint event graph with 300+ nodes and no functions. It's becoming unmaintainable."
**Expected behavior**:
- Identifies this as a Blueprint architecture problem, not a minor style issue
- Recommends migrating core replication logic to C++ ActorComponent or GameplayAbility system
- Notes the coordination required: changes to replication architecture must involve lead-programmer
- Does NOT unilaterally declare "migrate to C++" without surfacing the scope of the refactor to the user
- Produces a concrete migration recommendation, not a vague suggestion

### Case 5: Context pass — version-appropriate API suggestions
**Input context**: Project engine-reference file states Unreal Engine 5.3.
**Input**: "How do I set up Enhanced Input actions for a new character?"
**Expected behavior**:
- Uses UE5.3-era Enhanced Input API (InputMappingContext, UEnhancedInputComponent::BindAction)
- Does NOT reference APIs introduced after UE5.3 without flagging them as potentially unavailable
- References the project's stated engine version in its response
- Provides concrete, version-anchored code or Blueprint node names

---

## Protocol Compliance

- [ ] Stays within declared domain (Unreal patterns, Blueprint/C++, UE subsystems)
- [ ] Redirects Unity or other-engine requests without producing wrong-engine code
- [ ] Returns structured findings (criteria tables, decision trees, migration plans) rather than freeform opinions
- [ ] Flags version uncertainty explicitly before producing API suggestions
- [ ] Coordinates with lead-programmer for architecture-scale refactors rather than deciding unilaterally

---

## Coverage Notes
- No automated runner exists for agent behavior tests — these are reviewed manually or via `$skill-test`
- Version-awareness (Case 3, Case 5) is the highest-risk failure mode for this agent; test regularly when engine version changes
- Case 4 integration with lead-programmer is a coordination test, not a technical correctness test
