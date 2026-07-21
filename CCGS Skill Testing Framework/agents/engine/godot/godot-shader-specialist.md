# Agent Test Spec: godot-shader-specialist

## Agent Summary
Domain: Godot shading language (GLSL-derivative), visual shaders (VisualShader graph), material setup, particle shaders, and post-processing effects.
Does NOT own: gameplay code, art style direction.
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Godot shading language / materials / post-processing)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition references `docs/engine-reference/godot/VERSION.md` as the authoritative source for Godot shader API changes

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Write a dissolve effect shader for enemy death in Godot."
**Expected behavior:**
- Produces valid Godot shading language code (not HLSL, not GLSL directly)
- Uses `shader_type spatial;` or `canvas_item` as appropriate
- Defines `uniform float dissolve_amount : hint_range(0.0, 1.0);`
- Samples a noise texture to determine per-pixel dissolve threshold
- Uses `discard;` for pixels below the threshold
- Optionally adds an edge glow using emission near the dissolve boundary
- Code is syntactically correct for Godot's shading language

### Case 2: HLSL redirect
**Input:** "Write an HLSL compute shader for this dissolve effect."
**Expected behavior:**
- Does NOT produce HLSL code
- Clearly states: "Godot does not use HLSL directly; it uses its own shading language (a GLSL derivative)"
- Translates the HLSL intent to the equivalent Godot shader approach
- Notes that RenderingDevice compute shaders are available in Godot 4 but are a low-level API and flags it appropriately if that was the intent

### Case 3: Post-cutoff API change — texture sampling (Godot 4.4)
**Input:** "Use `texture()` with a sampler2D to sample the noise texture in the shader."
**Expected behavior:**
- Checks the version reference: Godot 4.4 changed texture sampler type declarations
- Flags the potential API change: `sampler2D` syntax and `texture()` call behavior may differ from pre-4.4
- Provides the correct syntax for the project's pinned version (4.6) as documented in migration notes
- Does NOT use pre-4.4 texture sampling syntax without flagging the version risk

### Case 4: Fragment shader LOD strategy
**Input:** "The fragment shader for the water surface has 8 texture samples and is causing GPU bottlenecks on mid-range hardware."
**Expected behavior:**
- Identifies the per-fragment texture sample count as the primary cost driver
- Proposes an LOD strategy:
  - Reduce sample count at distance (distance-based shader variant or LOD level)
  - Pre-bake some texture combinations offline
  - Use lower-resolution noise textures for distant samples
- Provides the shader code modification implementing the LOD approach
- Does NOT change gameplay behavior of the water system

### Case 5: Context pass — Godot 4.6 glow rework
**Input:** Engine version context: Godot 4.6. Request: "Add a bloom/glow post-processing effect to the scene."
**Expected behavior:**
- References the VERSION.md note: Godot 4.6 includes a glow rework
- Produces glow configuration guidance using the 4.6 WorldEnvironment approach, not the pre-4.6 API
- Explicitly notes which properties or parameters changed in the 4.6 glow rework
- Flags any properties that the LLM's training data may have incorrect information about due to the post-cutoff timing

---

## Protocol Compliance

- [ ] Stays within declared domain (Godot shading language, materials, VFX shaders, post-processing)
- [ ] Redirects gameplay code requests to gameplay-programmer
- [ ] Produces valid Godot shading language — never HLSL or raw GLSL without a Godot wrapper
- [ ] Checks engine version reference for post-cutoff shader API changes (4.4 texture types, 4.6 glow rework)
- [ ] Returns structured output (shader code with uniforms documented, LOD strategies with performance rationale)
- [ ] Flags any post-cutoff API usage as requiring verification

---

## Coverage Notes
- Dissolve shader (Case 1) should be paired with a visual test screenshot in `production/qa/evidence/`
- Texture API flag (Case 3) confirms the agent checks VERSION.md before using APIs that changed post-4.3
- Glow rework (Case 5) is a Godot 4.6-specific test — verifies the agent applies the most recent migration notes
