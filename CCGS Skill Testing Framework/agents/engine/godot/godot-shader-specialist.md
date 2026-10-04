# Agent Test Spec: godot-shader-specialist

## Agent Summary
Domain: Godot shading language (GLSL-derivative), visual shaders (VisualShader graph), material setup, particle shaders, and post-processing effects.
Does NOT own: gameplay code, art style direction.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Godot shading language / materials / post-processing)
- [ ] `tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
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
- States that Godot materials are written in Godot's own shading language (`.gdshader`, a GLSL derivative), not HLSL
- Translates the HLSL intent into the equivalent `.gdshader` approach (noise threshold, `discard`, emission at the dissolve edge)
- If a compute shader was really the intent, flags compute as a separate low-level path (RenderingDevice; unavailable on the Compatibility renderer) and brings in godot-gdextension-specialist for compute-shader offloading

### Case 3: Post-cutoff API change — shader texture types (Godot 4.4)
**Input:** "Use `texture()` with a sampler2D to sample the noise texture in the shader."
**Expected behavior:**
- Checks the version reference before writing the shader (`VERSION.md`, then `breaking-changes.md` and `modules/rendering.md`)
- Identifies what the 4.4 change covers: engine-side shader texture parameter/return types moved from `Texture2D` to `Texture` — script and engine API code that handles shader textures, not shading-language syntax
- Uses `uniform sampler2D noise_texture;` with `texture(noise_texture, UV)` — the form its own patterns use; the reference records no change to shading-language sampling syntax
- Does NOT invent a changed sampling syntax for 4.4–4.6, or rewrite `sampler2D` / `texture()` because of the 4.4 row

### Case 4: Fragment shader LOD strategy
**Input:** "The fragment shader for the water surface has 8 texture samples and is causing GPU bottlenecks on mid-range hardware."
**Expected behavior:**
- Identifies the per-fragment texture sample count as the primary cost driver
- Proposes an LOD strategy:
  - Reduce sample count at distance with a simplified LOD material for distant water, not a per-pixel distance branch in the fragment shader
  - Move UV/scroll math that does not need per-pixel evaluation into the vertex shader and pass it through a `varying`
  - Make sure the water textures are mipmapped (e.g. `filter_linear_mipmap`) so distant samples read smaller mip levels
- Provides the shader code modification implementing the LOD approach
- Does NOT change gameplay behavior of the water system

### Case 5: Context pass — Godot 4.6 glow rework
**Input:** Engine version context: Godot 4.6. Request: "Add a bloom/glow post-processing effect to the scene."
**Expected behavior:**
- References the VERSION.md note: Godot 4.6 includes a glow rework
- Because `VERSION.md` records `Installed at pin time` as NOT DETERMINED, asks which editor version is installed before tuning for the 4.6 glow behavior
- Produces glow configuration guidance on the `WorldEnvironment` node's `Environment` resource
- States the documented 4.6 change: glow now processes before tonemapping (it was after), with screen blending — so glow intensity/blend tuned on an earlier version will look different and may need re-tuning
- Does NOT invent renamed or removed glow properties that `breaking-changes.md` and `modules/rendering.md` do not document
- Flags any properties that the LLM's training data may have incorrect information about due to the post-cutoff timing

---

## Protocol Compliance

- [ ] Stays within declared domain (Godot shading language, materials, VFX shaders, post-processing)
- [ ] Redirects gameplay code requests to gameplay-programmer
- [ ] Writes material and post-process shaders as `.gdshader` (Godot shading language) — never HLSL
- [ ] Checks engine version reference for post-cutoff shader API changes (4.4 texture types, 4.6 glow rework)
- [ ] Returns structured output (shader code with uniforms documented, LOD strategies with performance rationale)
- [ ] Flags any post-cutoff API usage as requiring verification
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Dissolve shader (Case 1) should be paired with a visual test screenshot in `production/qa/evidence/`
- Texture-type case (Case 3) confirms the agent reads what a post-cutoff change actually covers before applying it, instead of rewriting syntax the change does not touch
- Glow rework (Case 5) is a Godot 4.6-specific test — verifies the agent applies the most recent migration notes
