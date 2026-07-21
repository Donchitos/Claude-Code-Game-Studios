# Agent Test Spec: unity-dots-specialist

## Agent Summary
Domain: ECS architecture (IComponentData, ISystem, SystemAPI), Jobs system (IJob, IJobEntity, Burst), Burst compiler constraints, DOTS gameplay systems, and hybrid renderer.
Does NOT own: MonoBehaviour gameplay code (gameplay-programmer), UI implementation (unity-ui-specialist).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references ECS / Jobs / Burst / IComponentData)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over MonoBehaviour gameplay or UI systems

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Convert the player movement system to ECS."
**Expected behavior:**
- Produces:
  - `PlayerMovementData : IComponentData` struct with velocity, speed, and input vector fields
  - `PlayerMovementSystem : ISystem` with `OnUpdate()` using `SystemAPI.Query<>` or `IJobEntity`
  - Bakes the player's initial state from an authoring MonoBehaviour via `IBaker`
- Uses `RefRW<LocalTransform>` for position updates (not deprecated `Translation`)
- Marks the job `[BurstCompile]` and notes what must be unmanaged for Burst compatibility
- Does NOT modify the input polling system — reads from an existing `PlayerInputData` component

### Case 2: MonoBehaviour push-back
**Input:** "Just use MonoBehaviour for the player movement — it's simpler."
**Expected behavior:**
- Acknowledges the simplicity argument
- Explains the DOTS trade-off: more setup upfront, but the ECS/Burst approach provides the performance characteristics documented in the project's ADR or requirements
- Does NOT implement a MonoBehaviour version if the project has committed to DOTS
- If no commitment exists, flags the architecture decision to `lead-programmer` / `technical-director` for resolution
- Does not make the MonoBehaviour vs. DOTS decision unilaterally

### Case 3: Burst-incompatible managed memory
**Input:** "This Burst job accesses a `List<EnemyData>` to find the nearest enemy."
**Expected behavior:**
- Flags `List<T>` as a managed type that is incompatible with Burst compilation
- Does NOT approve the Burst job with managed memory access
- Provides the correct replacement: `NativeArray<EnemyData>`, `NativeList<EnemyData>`, or `NativeHashMap<>` depending on the use case
- Notes that `NativeArray` must be disposed explicitly or via `[DeallocateOnJobCompletion]`
- Produces the corrected job using unmanaged native containers

### Case 4: Hybrid access — DOTS system needs MonoBehaviour data
**Input:** "The DOTS movement system needs to read the camera transform managed by a MonoBehaviour CameraController."
**Expected behavior:**
- Identifies this as a hybrid access scenario
- Provides the correct hybrid pattern: store the camera transform in a singleton `IComponentData` (updated from the MonoBehaviour side each frame via `EntityManager.SetComponentData`)
- Alternatively suggests the `CompanionComponent` / managed component approach
- Does NOT access the MonoBehaviour from inside a Burst job — flags that as unsafe
- Provides the bridge code on both the MonoBehaviour side (writing to ECS) and the DOTS system side (reading from ECS)

### Case 5: Context pass — performance targets
**Input:** Technical preferences from context: 60fps target, max 2ms CPU script budget per frame. Request: "Design the ECS chunk layout for 10,000 enemy entities."
**Expected behavior:**
- References the 2ms CPU budget explicitly in the design rationale
- Designs the `IComponentData` chunk layout for cache efficiency:
  - Groups frequently-queried together components in the same archetype
  - Separates rarely-used data into separate components to keep hot data compact
  - Estimates entity iteration time against the 2ms budget
- Provides memory layout analysis (bytes per entity, entities per chunk at 16KB chunk size)
- Does NOT design a layout that will obviously exceed the stated 2ms budget without flagging it

---

## Protocol Compliance

- [ ] Stays within declared domain (ECS, Jobs, Burst, DOTS gameplay systems)
- [ ] Redirects MonoBehaviour-only gameplay to gameplay-programmer
- [ ] Returns structured output (IComponentData structs, ISystem implementations, IBaker authoring classes)
- [ ] Flags managed memory access in Burst jobs as a compile error and provides unmanaged alternatives
- [ ] Provides hybrid access patterns when DOTS systems need to interact with MonoBehaviour systems
- [ ] Designs chunk layouts against provided performance budgets

---

## Coverage Notes
- ECS conversion (Case 1) must include a unit test using the ECS test framework (`World`, `EntityManager`)
- Burst incompatibility (Case 3) is safety-critical — the agent must catch this before the code is written
- Chunk layout (Case 5) verifies the agent applies quantitative performance reasoning to architecture decisions
