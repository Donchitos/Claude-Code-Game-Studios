# Agent Test Spec: audio-director

## Agent Summary
**Domain owned:** Music direction and palette, sound design philosophy, audio implementation strategy, mix balance, audio aspects of phase gates.
**Does NOT own:** Visual design (art-director), code implementation (lead-programmer), narrative story content (narrative-director), UX interaction flows (ux-designer).
**Model tier:** Sonnet (individual system analysis — audio direction and spec review).
**Gate IDs handled:** AD-VISUAL (audio aspect of the phase gate; may be referenced as part of AD-PHASE-GATE in the audio dimension).

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/audio-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references music direction, sound design, mix, audio implementation — not generic)
- [ ] `allowed-tools:` list is read-focused; no Bash unless audio asset pipeline checks are justified
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over visual design, code implementation, or narrative content

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** An audio specification document is submitted for the game's "Exploration" music layer. The spec defines a generative ambient system using layered stems that shift based on environmental density, designed to reinforce the pillar "lived-in world." The tone palette (sparse, organic, slightly melancholic) matches the established design pillars.
**Expected:** Returns `APPROVED` with rationale confirming the stem-based approach supports dynamic responsiveness and the tone palette aligns with the pillar vocabulary.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / NEEDS REVISION
- [ ] Rationale references the specific pillar ("lived-in world") and how the audio spec supports it
- [ ] Output stays within audio scope — does not comment on visual design of the environment or UI layout
- [ ] Verdict is clearly labeled with context (e.g., "Audio Spec Review: APPROVED")

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A developer asks audio-director to evaluate whether the UI flow for the audio settings menu (the sequence of screens and options) is intuitive and well-organized.
**Expected:** Agent declines to evaluate UI interaction flow and redirects to ux-designer.
**Assertions:**
- [ ] Does not make any binding decision about UI flow or information architecture
- [ ] Explicitly names `ux-designer` as the correct handler
- [ ] May note audio-specific requirements for the settings menu (e.g., "must include separate master, music, and SFX sliders"), but defers flow and layout decisions to ux-designer

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A music cue for the final boss encounter is submitted. The cue is an upbeat, major-key orchestral piece with fast tempo. The game pillars and narrative context for this encounter specify "dread, inevitability, and tragic sacrifice." The audio cue's emotional register directly contradicts the intended emotional beat.
**Expected:** Returns `NEEDS REVISION` with specific citation of the emotional mismatch: the cue's upbeat/major-key/fast-tempo characteristics versus the intended dread/inevitability/sacrifice emotional targets from the pillars and narrative context.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / NEEDS REVISION — not freeform text
- [ ] Rationale identifies the specific musical characteristics that conflict with the emotional targets
- [ ] References the specific emotional targets from the game pillars or narrative context
- [ ] Provides actionable direction for revision (e.g., "shift to minor key, slower tempo, reduce ensemble density")

### Case 4: Conflict escalation — correct parent
**Scenario:** sound-designer proposes implementing audio occlusion using real-time raycast-based physics queries (technical approach). technical-artist argues this is too expensive and proposes a zone-based trigger system instead. Both agree the occlusion effect is desirable; the conflict is purely about implementation approach.
**Expected:** audio-director decides on the desired audio behavior (what occlusion should sound like and when it should activate), then defers the implementation approach decision to technical-artist or lead-programmer as the implementation experts. audio-director does not make the technical implementation choice.
**Assertions:**
- [ ] Defines the desired audio behavior clearly (what should the player hear and when)
- [ ] Explicitly defers the implementation approach (raycast vs. zone-trigger) to `lead-programmer` or `technical-artist`
- [ ] Does not unilaterally choose the technical implementation method
- [ ] Frames the handoff clearly: "audio-director owns what, technical lead owns how"

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the game's three pillars: "emergent stories," "meaningful sacrifice," and "lived-in world." A sound design spec for ambient environmental audio is submitted.
**Expected:** Assessment evaluates the ambient audio spec against all three pillars specifically — how does the audio support (or undermine) each pillar? Uses the pillar vocabulary directly in the rationale.
**Assertions:**
- [ ] References all three provided pillars by name in the assessment
- [ ] Evaluates the audio spec's contribution to each pillar explicitly
- [ ] Does not generate generic audio direction advice — all feedback is tied to the provided pillar vocabulary
- [ ] Identifies if any pillar is not supported by the current audio spec and flags it

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVED / NEEDS REVISION vocabulary only
- [ ] Stays within declared audio domain
- [ ] Defers implementation approach decisions to technical leads
- [ ] Does not use gate ID prefix format in the same way as director-tier agents (audio-director uses APPROVED / NEEDS REVISION inline, but should still reference the gate context)
- [ ] Does not make binding visual design, UX, narrative, or code implementation decisions

---

## Coverage Notes
- Mix balance review (relative levels between music, SFX, and dialogue) is not covered — a dedicated case should be added.
- Audio implementation strategy review (middleware choice, streaming approach) is not covered.
- Interaction between audio-director and the audio specialist agent (if one exists) for implementation delegation is not covered.
- Localization audio implications (VO recording direction, language-specific music timing) are not covered.
