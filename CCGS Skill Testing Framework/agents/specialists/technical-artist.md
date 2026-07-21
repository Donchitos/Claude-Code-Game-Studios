# Agent Test Spec: technical-artist

## Agent Summary
Domain: Shaders, VFX, rendering optimization, art pipeline tools, and visual performance.
Does NOT own: art style decisions or color palette (art-director), gameplay code (gameplay-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references shaders / VFX / rendering)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over art style direction or gameplay logic

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create a dissolve effect shader for enemy death sequences."
**Expected behavior:**
- Produces shader code or a Shader Graph node spec appropriate to the configured engine (Godot shading language / Unity Shader Graph / Unreal Material Blueprint)
- Defines a `dissolve_amount` uniform (0.0–1.0) as the animation driver
- Uses a noise texture sample to determine the dissolve threshold
- Notes edge-lighting technique as an optional enhancement
- Output is engine-version-aware (checks version reference if post-cutoff APIs are needed)

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Define the art bible color palette: primary, secondary, and accent colors for the UI."
**Expected behavior:**
- Does NOT produce color palette decisions or art direction documents
- Explicitly states that art style decisions belong to `art-director`
- Redirects the request to `art-director`
- May note it can later implement a color-grading or palette LUT shader once the palette is decided

### Case 3: Performance warning — GPU particle count
**Input:** "The VFX system is triggering a GPU particle count warning at 50,000 particles in the explosion pool."
**Expected behavior:**
- Produces an optimization spec addressing the specific warning
- Proposes concrete strategies: particle budget caps per emitter, LOD-based particle reduction, GPU instancing, or switching to mesh-based VFX for distant effects
- Provides before/after GPU cost estimates where calculable
- Does NOT change gameplay behavior of the explosion (delegates any gameplay impact to gameplay-programmer)

### Case 4: Engine version compatibility
**Input:** "Use the new texture sampler API for the water shader."
**Expected behavior:**
- Checks the engine version reference (e.g., `docs/engine-reference/godot/VERSION.md`) before suggesting any API
- Flags if the requested API is post-cutoff (e.g., Godot 4.4+ texture type changes)
- Provides the correct syntax for the project's pinned engine version
- If uncertain about post-cutoff behavior, explicitly states the uncertainty and directs to verified docs

### Case 5: Context pass — uses performance budget
**Input:** Performance budget from `technical-preferences.md` provided in context: 2ms GPU frame budget, max 200 draw calls. Request: "Optimize the forest rendering system."
**Expected behavior:**
- References the specific 2ms GPU budget and 200 draw call limit from the provided context
- Proposes optimizations calibrated to those exact targets (e.g., "batching reduces draw calls from 340 to ~180, within the 200 limit")
- Does NOT propose optimizations that would exceed the stated budgets in other dimensions
- Produces a ranked list of optimizations by expected impact vs. implementation cost

---

## Protocol Compliance

- [ ] Stays within declared domain (shaders, VFX, rendering optimization, art pipeline)
- [ ] Redirects art style decisions to art-director
- [ ] Returns structured findings (shader code, optimization specs with metrics, node graphs)
- [ ] Does not modify gameplay code files without explicit delegation
- [ ] Checks engine version reference before suggesting post-cutoff APIs
- [ ] Quantifies performance changes against stated budgets

---

## Coverage Notes
- Dissolve shader (Case 1) should include a visual test reference in `production/qa/evidence/`
- Engine version check (Case 4) confirms the agent treats VERSION.md as authoritative
- Performance budget case (Case 5) verifies the agent reads and applies provided context numbers
