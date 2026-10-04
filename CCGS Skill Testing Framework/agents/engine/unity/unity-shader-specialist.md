# Agent Test Spec: unity-shader-specialist

## Agent Summary
Domain: Unity Shader Graph, custom HLSL, VFX Graph, URP/HDRP pipeline customization, and post-processing effects.
Does NOT own: gameplay code, art style direction.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Shader Graph / HLSL / VFX Graph / URP / HDRP)
- [ ] `tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over gameplay code or art direction

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create an outline effect for characters using Shader Graph in URP."
**Expected behavior:**
- Produces a Shader Graph node setup description (inverted hull via vertex offset, or a screen-space depth/normal edge detection), named to its convention (e.g., `SG_Char_Outline`) with reusable logic in a Sub Graph
- Stays in Shader Graph and drops to custom HLSL only if Shader Graph cannot achieve the effect; any HLSL keeps SRP Batcher compatibility (`UnityPerMaterial` CBUFFER)
- For a screen-space variant, uses a URP `ScriptableRendererFeature` / `ScriptableRenderPass` recorded through the RenderGraph API (`RecordRenderGraph`), not the deprecated `Execute` / CommandBuffer path — per `docs/engine-reference/unity/modules/rendering.md`
- Does NOT produce HDRP-specific nodes without confirming the render pipeline

### Case 2: Out-of-domain redirect
**Input:** "Implement the character health bar UI in code."
**Expected behavior:**
- Does NOT produce UI implementation code
- Explicitly states that UI implementation belongs to `ui-programmer` (or `unity-ui-specialist`)
- Redirects the request appropriately
- Any part it keeps is the shader-driven effect only (e.g., a dissolve or fill gradient on the bar) — it writes no health-bar UI code

### Case 3: HDRP custom pass for outline
**Input:** "We're on HDRP and want the outline as a post-process effect."
**Expected behavior:**
- Produces the HDRP custom pass pattern its own standards name: a C# class inheriting `CustomPass`, run from a Custom Pass Volume, drawing a full-screen edge-detection shader that samples the depth/normal buffers
- Uses the HDRP overrides `docs/engine-reference/unity/current-best-practices.md` documents — `Setup(ScriptableRenderContext, CommandBuffer)`, `Execute(CustomPassContext ctx)`, `Cleanup()` — never URP's `RecordRenderGraph`, and marks any other HDRP member it uses (render-target helpers, `CustomPassContext` fields) unverified — nothing beyond those three is asserted from memory
- Notes that CustomPass requires HDRP package and does not work in URP
- Confirms the project is on HDRP before providing HDRP-specific code

### Case 4: VFX Graph performance — particle budget
**Input:** "The explosion VFX Graph has 10,000 particles per event and spawning 20 simultaneous explosions is causing GPU frame spikes."
**Expected behavior:**
- Identifies GPU particle spawn as the cost driver (200,000 simultaneous particles)
- Sets a particle capacity limit per effect and sizes it against the < 2ms total VFX GPU budget
- Pools explosion VFX instances and triggers them through events, rather than creating a graph per explosion
- Reduces cost for distant or off-screen explosions (particle LOD, bounds-based culling) and scales counts by quality tier
- Avoids any fix that reads GPU particle data back to the CPU
- Does NOT change the gameplay event system — proposes a VFX-side budgeting solution

### Case 5: Context pass — render pipeline (URP or HDRP)
**Input:** Project context: URP render pipeline, targets PC and Nintendo Switch. Request: "Add depth of field post-processing."
**Expected behavior:**
- Uses URP Volume framework: a `DepthOfField` override in a Volume Profile, with script access through `profile.TryGet<>()` as `docs/engine-reference/unity/modules/rendering.md` shows
- Does NOT use HDRP Volume components (e.g., HDRP's `DepthOfField` with different parameter names)
- Places it on the Global Volume for the baseline look or a local Volume for an area, with priority and blend distance set
- Gates the effect per platform and quality tier — reduced or disabled on Switch — and keeps post-processing inside its 1-2ms frame budget

---

## Protocol Compliance

- [ ] Stays within declared domain (Shader Graph, HLSL, VFX Graph, URP/HDRP customization)
- [ ] Redirects gameplay and UI code to appropriate agents
- [ ] Returns structured output (node graph descriptions, HLSL code, CustomPass patterns)
- [ ] Distinguishes between URP and HDRP approaches — never cross-contaminates pipeline-specific APIs
- [ ] Uses the RenderGraph API for custom URP passes, not the deprecated `Execute` / CommandBuffer path
- [ ] Produces VFX optimizations that do not change gameplay behavior
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Outline effect (Case 1) should be paired with a visual screenshot test in `production/qa/evidence/`
- HDRP CustomPass (Case 3) confirms the agent produces the correct Unity pattern, not a generic post-process approach
- Pipeline separation (Case 5) verifies the agent never assumes the render pipeline without context
