# Agent Test Spec: unreal-specialist

## Agent Summary
- **Domain**: Unreal Engine patterns and architecture — Blueprint vs C++ decisions, UE subsystems (GAS, Enhanced Input, Niagara), UE project structure, plugin integration, and engine-level configuration
- **Does NOT own**: Art style and visual direction (art-director), server infrastructure and deployment (devops-engineer), UI/UX flow design (ux-designer)
- **Gate IDs**: None; defers gate verdicts to technical-director

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Unreal Engine)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, Bash and `Agent(ue-gas-specialist, ue-blueprint-specialist, ue-replication-specialist, ue-umg-specialist)` — it may spawn only its four sub-specialists
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority outside its declared domain (no art, no server infra)

---

## Test Cases

### Case 1: In-domain request — Blueprint vs C++ decision criteria
**Input**: "Should I implement our combo attack system in Blueprint or C++?"
**Expected behavior**:
- Applies its stated default: C++ for the combo system's framework, Blueprint for content and prototyping
- Routes the combat logic through GAS (combo attacks as Gameplay Abilities, combo state as Gameplay Tags, montage flow via Ability Tasks) and names ue-gas-specialist for the GAS design rather than implementing it itself
- Recommends Blueprint for designer-tunable values (exposed with `EditAnywhere` / `BlueprintReadWrite`, data-only Blueprints for combo variations, `BlueprintNativeEvent` where designers override behavior)
- Cites its ~20-nodes-per-function threshold as the point where Blueprint combo logic belongs in C++
- Does NOT render a final verdict without knowing project context — asks clarifying questions if context is absent
- Presents the split as a proposed class structure with its trade-offs, not a freeform opinion

### Case 2: Out-of-domain request — Unity C# code
**Input**: "Write me a C# MonoBehaviour that handles player health and fires a Unity event on death."
**Expected behavior**:
- Does not produce Unity C# code
- Confirms the project's engine from `engine.name` in `project.yaml` before answering: with Unreal configured, states that the project is built in Unreal Engine 5; with it unset, asks which engine the project uses rather than assuming
- With Unreal configured, maps the request to the Unreal equivalent its own standards prescribe: health as an Attribute Set attribute changed only through Gameplay Effects when GAS is in use, otherwise a C++ `UActorComponent` exposing a death event to Blueprint
- Does not redirect to unity-specialist — that agent serves Unity projects only, and this agent's `Agent` grant covers only its four Unreal sub-specialists

### Case 3: Domain boundary — UE5.4 API requirement
**Input**: "I need to use the new Motion Matching API introduced in UE5.4."
**Expected behavior**:
- Flags that UE5.4 is past the model's training coverage (`docs/engine-reference/unreal/VERSION.md` lists 5.4 as a post-cutoff, HIGH-risk version)
- Checks `docs/engine-reference/unreal/` before trusting any API suggestion
- States that no file under `docs/engine-reference/unreal/` documents Motion Matching, and labels any class or node names it offers as unverified against the pinned version
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
- [ ] Answers Unity or other-engine requests with the Unreal equivalent, never wrong-engine code
- [ ] Proposes class structure, data flow and trade-offs before implementing (Implementation Workflow step 3) rather than freeform opinions
- [ ] Flags version uncertainty explicitly before producing API suggestions, citing `docs/engine-reference/unreal/`
- [ ] Coordinates with lead-programmer for architecture-scale refactors rather than deciding unilaterally
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- No automated runner exists for agent behavior tests — these are reviewed manually or via `/skill-test`
- Version-awareness (Case 3, Case 5) is the highest-risk failure mode for this agent; test regularly when engine version changes
- Cases 3 and 5 pass only if the agent is directed to `docs/engine-reference/unreal/`; `CLAUDE.md` imports the Unreal `VERSION.md` only after `/setup-engine` selects Unreal, so the agent's own file must carry that direction
- Case 4 integration with lead-programmer is a coordination test, not a technical correctness test
