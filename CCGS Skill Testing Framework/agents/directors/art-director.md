# Agent Test Spec: art-director

## Agent Summary
**Domain owned:** Visual identity, art bible authorship and enforcement, asset quality standards, UI/UX visual design, visual phase gate, concept art evaluation.
**Does NOT own:** UX interaction flows and information architecture (ux-designer's domain), audio direction (audio-director), code implementation.
No fixed model routing is required; the caller selects the available Codex model.
**Gate IDs handled:** visual concept review, $art-bible review, AD-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `roles/art-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references visual identity, art bible, asset standards — not generic)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UX interaction flows or audio direction

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** The art bible's color palette section is submitted for review. The section defines a desaturated earth-tone primary palette with high-contrast accent colors tied to the game pillar "beauty in decay." The palette is internally consistent and references the pillar vocabulary. Request is tagged $art-bible review.
**Expected:** Returns a documented domain-specific verdict with rationale confirming the palette's internal consistency and its alignment with the stated pillar.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT
- [ ] Verdict and rationale are clear and grounded in the supplied context
- [ ] Rationale references the specific palette characteristics and pillar alignment — not generic art advice
- [ ] Output stays within visual domain — does not comment on UX interaction patterns or audio mood

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Sound designer asks art-director to specify how ambient audio should layer and duck when the player enters a combat zone.
**Expected:** Agent declines to define audio behavior and redirects to audio-director.
**Assertions:**
- [ ] Does not make any binding decision about audio layering or ducking behavior
- [ ] Explicitly names `audio-director` as the correct handler
- [ ] May note if the audio has visual mood implications (e.g., "the audio should match the visual tension of the zone"), but defers all audio specification to audio-director

### Case 3: Gate verdict — correct vocabulary
**Scenario:** Concept art for the protagonist is submitted. The art uses a vivid, saturated color palette (primary: #FF4500, #00BFFF) that directly contradicts the established art bible's "desaturated earth-tones" palette specification. Request is tagged visual concept review.
**Expected:** Returns a documented domain-specific verdict with specific citation of the palette discrepancy, referencing the art bible's stated palette values versus the submitted concept's palette.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT — not freeform text
- [ ] Verdict and rationale are clear and grounded in the supplied context
- [ ] Rationale specifically identifies the palette conflict — not a generic "doesn't match style" comment
- [ ] References the art bible as the authoritative source for the correct palette

### Case 4: Conflict escalation — correct parent
**Scenario:** ux-designer proposes using high-contrast, brightly colored icons for the HUD to improve readability. art-director believes this violates the art bible's muted visual language and would undermine the visual identity.
**Expected:** art-director states the visual identity concern and references the art bible, acknowledges ux-designer's readability goal as legitimate, and escalates to creative-director to arbitrate the trade-off between visual coherence and usability.
**Assertions:**
- [ ] Escalates to `creative-director` (shared parent for creative domain conflicts)
- [ ] Does not unilaterally override ux-designer's readability recommendation
- [ ] Clearly frames the conflict as a trade-off between two legitimate goals
- [ ] References the specific art bible rule being violated

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the existing art bible with specific palette values (primary: #8B7355, #6B6B47; accent: #C8A96E) and style rules ("no pure white, no pure black; all shadows have warm undertones"). A new asset is submitted for review.
**Expected:** Assessment references the specific hex values and style rules from the provided art bible, not generic color theory advice. Any concerns are tied to specific violations of the provided rules.
**Assertions:**
- [ ] References specific palette values from the provided art bible context
- [ ] Applies the specific style rules (no pure white/black, warm shadow undertones) from the provided document
- [ ] Does not generate generic art direction feedback disconnected from the supplied art bible
- [ ] Verdict rationale is traceable to specific lines or rules in the provided context

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVE / CONCERNS / REJECT vocabulary only
- [ ] Stays within declared visual domain
- [ ] Escalates UX-vs-visual conflicts to creative-director
- [ ] Uses the provided task context when applicable; does not claim automatic role registration
- [ ] Does not make binding UX interaction, audio, or code implementation decisions

---

## Coverage Notes
- AD-PHASE-GATE (full visual phase advancement) is not covered — deferred to integration with $gate-check skill.
- Asset pipeline standards (file format, resolution, naming conventions) compliance checks are not covered here.
- Shader visual output review is not covered — that interaction with the engine specialist is deferred.
- UI component visual review (as distinct from UX flow review) could benefit from additional cases.
