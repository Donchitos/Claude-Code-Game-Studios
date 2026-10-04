# Agent Test Spec: unity-dots-specialist

## Agent Summary
Domain: ECS architecture (IComponentData, ISystem, SystemAPI), Jobs system (IJob, IJobEntity, Burst), Burst compiler constraints, DOTS gameplay systems, and hybrid renderer.
Does NOT own: MonoBehaviour gameplay code (gameplay-programmer), UI implementation (unity-ui-specialist).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references ECS / Jobs / Burst / IComponentData)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over MonoBehaviour gameplay or UI systems

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Convert the player movement system to ECS."
**Expected behavior:**
- Produces:
  - `PlayerMovementData : IComponentData` struct with velocity, speed, and input vector fields
  - `PlayerMovementSystem : ISystem` with `OnUpdate()` using `SystemAPI.Query<>` or `IJobEntity`
  - Bakes the player's initial state from an authoring MonoBehaviour via a `Baker<T>` subclass (the pattern in `docs/engine-reference/unity/plugins/dots-entities.md`)
- Uses `RefRW<LocalTransform>` for position updates (not deprecated `Translation`)
- Marks the job `[BurstCompile]` and notes what must be unmanaged for Burst compatibility
- Keeps one concern per system: the movement system reads input from a component (e.g. `PlayerInputData`) that a separate input system writes, rather than polling input itself, and asks before creating or changing that input side

### Case 2: MonoBehaviour push-back
**Input:** "Just use MonoBehaviour for the player movement — it's simpler."
**Expected behavior:**
- Acknowledges the simplicity argument
- Explains the DOTS trade-off: more setup upfront, but the ECS/Burst approach provides the performance characteristics documented in the project's ADR or requirements
- Does NOT implement a MonoBehaviour version if the project has committed to DOTS
- If no commitment exists, routes the MonoBehaviour-vs-DOTS decision to `unity-specialist` (its named contact for overall Unity architecture), with `technical-director` as the escalation for an unresolved technical conflict
- Does not make the MonoBehaviour vs. DOTS decision unilaterally

### Case 3: Burst-incompatible managed memory
**Input:** "This Burst job accesses a `List<EnemyData>` to find the nearest enemy."
**Expected behavior:**
- Flags `List<T>` as a managed type that is incompatible with Burst compilation
- Does NOT approve the Burst job with managed memory access
- Provides the correct replacement: `NativeArray<EnemyData>`, `NativeList<EnemyData>`, or `NativeHashMap<>` depending on the use case
- Notes that the native container must be disposed, with the allocator chosen by lifetime (`Allocator.TempJob` for frame-scoped, `Allocator.Persistent` for long-lived) and capacity pre-allocated when the size is known
- Produces the corrected job using unmanaged native containers

### Case 4: Hybrid access — DOTS system needs MonoBehaviour data
**Input:** "The DOTS movement system needs to read the camera transform managed by a MonoBehaviour CameraController."
**Expected behavior:**
- Identifies this as a hybrid access scenario
- Does NOT put the `Transform` or the MonoBehaviour itself into a component — components hold no references to managed objects
- Carries the camera data across the boundary as unmanaged values (`Unity.Mathematics` types) in an `IComponentData`, written at one explicit hand-off point on the MonoBehaviour side and read by the system — not reached for per entity
- Does NOT access the MonoBehaviour from inside a Burst job — flags managed access in Burst code as a compile error

### Case 5: Context pass — performance targets
**Input:** Technical preferences from context: 60fps target, max 2ms CPU script budget per frame. Request: "Design the ECS chunk layout for 10,000 enemy entities."
**Expected behavior:**
- References the 2ms CPU budget explicitly in the design rationale
- Designs the `IComponentData` chunk layout for cache efficiency:
  - Splits components by system access pattern, not by game concept — no "god component"
  - Keeps hot components small, with rarely-used data in separate components
  - Uses tag components for filtering, avoids `ISharedComponentData` that would fragment archetypes, and uses `IEnableableComponent` instead of structural changes for toggled state
- Names how the budget will be verified — Entities Profiler system timings and per-archetype memory — instead of presenting unmeasured timings as fact
- Does NOT design a layout that will obviously exceed the stated 2ms budget without flagging it

---

## Protocol Compliance

- [ ] Stays within declared domain (ECS, Jobs, Burst, DOTS gameplay systems)
- [ ] Redirects MonoBehaviour-only gameplay to gameplay-programmer
- [ ] Returns structured output (IComponentData structs, ISystem implementations, `Baker<T>` authoring classes)
- [ ] Flags managed memory access in Burst jobs as a compile error and provides unmanaged alternatives
- [ ] Provides hybrid access patterns when DOTS systems need to interact with MonoBehaviour systems
- [ ] Designs chunk layouts against provided performance budgets, and names the profiling step that verifies them
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- ECS conversion (Case 1) must include a unit test using the ECS test framework (`World`, `EntityManager`) under `Assets/Tests/EditMode/`
- Burst incompatibility (Case 3) is safety-critical — the agent must catch this before the code is written
- Chunk layout (Case 5) verifies the agent designs against a stated budget and says how it will be measured, rather than asserting unmeasured numbers
