# Agent Test Spec: unity-shader-specialist

## Agent Summary
Domain: Unity Shader Graph, custom HLSL, VFX Graph, URP/HDRP pipeline customization, and post-processing effects.
Does NOT own: gameplay code, art style direction.
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Shader Graph / HLSL / VFX Graph / URP / HDRP)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over gameplay code or art direction

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create an outline effect for characters using Shader Graph in URP."
**Expected behavior:**
- Produces a Shader Graph node setup description:
  - Inverted hull method: Scale Normal → Vertex offset in vertex stage, Cull Front
  - OR screen-space post-process outline using depth/normal edge detection
- Recommends the appropriate method based on URP capabilities (inverted hull for URP compatibility, post-process for HDRP)
- Notes URP limitations: no geometry shader support (rules out geometry-shader outline approach)
- Does NOT produce HDRP-specific nodes without confirming the render pipeline

### Case 2: Out-of-domain redirect
**Input:** "Implement the character health bar UI in code."
**Expected behavior:**
- Does NOT produce UI implementation code
- Explicitly states that UI implementation belongs to `ui-programmer` (or `unity-ui-specialist`)
- Redirects the request appropriately
- May note that a shader-based fill effect for a health bar (e.g., a dissolve/fill gradient) is within its domain if the visual effect itself is shader-driven

### Case 3: HDRP custom pass for outline
**Input:** "We're on HDRP and want the outline as a post-process effect."
**Expected behavior:**
- Produces the HDRP `CustomPassVolume` pattern:
  - C# class inheriting `CustomPass`
  - `Execute()` method using `CoreUtils.SetRenderTarget()` and a full-screen shader blit
  - Depth/normal buffer sampling for edge detection
- Notes that CustomPass requires HDRP package and does not work in URP
- Confirms the project is on HDRP before providing HDRP-specific code

### Case 4: VFX Graph performance — GPU event batching
**Input:** "The explosion VFX Graph has 10,000 particles per event and spawning 20 simultaneous explosions is causing GPU frame spikes."
**Expected behavior:**
- Identifies GPU particle spawn as the cost driver (200,000 simultaneous particles)
- Proposes GPU event batching: spawn events deferred over multiple frames, stagger initialization
- Recommends a particle budget cap per active explosion (e.g., 3,000 per explosion, queue excess)
- Notes the VFX Graph Event Batcher pattern and Output Event API for cross-frame distribution
- Does NOT change the gameplay event system — proposes a VFX-side budgeting solution

### Case 5: Context pass — render pipeline (URP or HDRP)
**Input:** Project context: URP render pipeline, Unity 2022.3. Request: "Add depth of field post-processing."
**Expected behavior:**
- Uses URP Volume framework: `DepthOfField` Volume Override component
- Does NOT use HDRP Volume components (e.g., HDRP's `DepthOfField` with different parameter names)
- Notes URP-specific DOF limitations vs HDRP (e.g., Bokeh quality differences)
- Produces C# Volume profile setup code compatible with Unity 2022.3 URP package version

---

## Protocol Compliance

- [ ] Stays within declared domain (Shader Graph, HLSL, VFX Graph, URP/HDRP customization)
- [ ] Redirects gameplay and UI code to appropriate agents
- [ ] Returns structured output (node graph descriptions, HLSL code, CustomPass patterns)
- [ ] Distinguishes between URP and HDRP approaches — never cross-contaminates pipeline-specific APIs
- [ ] Flags geometry shader approaches as URP-incompatible when relevant
- [ ] Produces VFX optimizations that do not change gameplay behavior

---

## Coverage Notes
- Outline effect (Case 1) should be paired with a visual screenshot test in `production/qa/evidence/`
- HDRP CustomPass (Case 3) confirms the agent produces the correct Unity pattern, not a generic post-process approach
- Pipeline separation (Case 5) verifies the agent never assumes the render pipeline without context
