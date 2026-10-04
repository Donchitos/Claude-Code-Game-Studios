# Agent Test Spec: art-director

## Agent Summary
**Domain owned:** Visual identity, art bible authorship and enforcement, asset quality standards, UI/UX visual design, visual phase gate, concept art evaluation.
**Does NOT own:** UX interaction flows and information architecture (ux-designer's domain), audio direction (audio-director), code implementation.
**Gate IDs handled:** AD-CONCEPT-VISUAL, AD-ART-BIBLE, AD-VISUAL, AD-PHASE-GATE.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/art-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references visual identity, art bible, asset standards — not generic)
- [ ] `tools:` includes Read (which also opens images for visual review) and Write/Edit for the art bible it maintains, and no Bash — `disallowedTools:` blocks it
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over UX interaction flows or audio direction

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A complete art bible is submitted for sign-off with the pillars and core fantasy, the platform constraints and the visual identity anchor chosen during brainstorm. Its color section defines a desaturated earth-tone primary palette with high-contrast accent colors tied to the game pillar "beauty in decay"; its shape language, asset standards and character direction are consistent with that section and within the stated platform constraints. Request is tagged AD-ART-BIBLE.
**Expected:** Returns `AD-ART-BIBLE: APPROVE` with rationale confirming the palette's internal consistency and that the color system matches the pillar's mood target.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT
- [ ] Verdict token is formatted as `AD-ART-BIBLE: APPROVE`
- [ ] Rationale references the specific palette characteristics and how they serve the "beauty in decay" mood target (the gate's color-vs-mood check) — not generic art advice
- [ ] Output stays within visual domain — does not comment on UX interaction patterns or audio mood

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** Sound designer asks art-director to specify how ambient audio should layer and duck when the player enters a combat zone.
**Expected:** Agent declines to define audio behavior and redirects to audio-director.
**Assertions:**
- [ ] Does not make any binding decision about audio layering or ducking behavior
- [ ] Explicitly names `audio-director` as the correct handler
- [ ] Any comment it makes is about the zone's visual mood (e.g., "the audio should match the visual tension of the zone") — it specifies no layer, duck amount, fade time or trigger

### Case 3: Gate verdict — correct vocabulary
**Scenario:** Right after pillars are locked, the concept and pillar set are submitted for a visual identity anchor. The three pillars are "fun combat," "great story," and "lots of content"; none of their design tests says anything about mood, atmosphere, or what the world should feel like, and no visual touchstones were given. Request is tagged AD-CONCEPT-VISUAL.
**Expected:** Returns `AD-CONCEPT-VISUAL: CONCERNS` — the gate's verdict for pillars that don't yet give enough direction to differentiate a visual identity — naming which pillars give no visual direction and what is missing (mood, shape language, color meaning).
**Assertions:**
- [ ] Verdict is exactly one of CONCEPTS / STRONG / CONCERNS (the AD-CONCEPT-VISUAL verdicts) — not APPROVE / REJECT and not freeform text
- [ ] Verdict token is formatted as `AD-CONCEPT-VISUAL: CONCERNS`
- [ ] Rationale names the specific pillars that give no visual direction and which of the gate's four direction components (visual rule, mood, shape language, color philosophy) they leave open — not a generic "pillars are vague"
- [ ] Does not rewrite the pillars itself — pillar changes go back to the user and creative-director

### Case 4: Conflict escalation — correct parent
**Scenario:** ux-designer proposes using high-contrast, brightly colored icons for the HUD to improve readability. art-director believes this violates the art bible's muted visual language and would undermine the visual identity.
**Expected:** art-director states the visual identity concern and references the art bible, acknowledges ux-designer's readability goal as legitimate, and escalates to creative-director to arbitrate the trade-off between visual coherence and usability.
**Assertions:**
- [ ] Escalates to `creative-director` (shared parent for creative domain conflicts)
- [ ] Does not unilaterally override ux-designer's readability recommendation
- [ ] Clearly frames the conflict as a trade-off between two legitimate goals
- [ ] References the specific art bible rule being violated

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the existing art bible with specific palette values (primary: #8B7355, #6B6B47; accent: #C8A96E) and style rules ("no pure white, no pure black; all shadows have warm undertones"). A new asset type is submitted for review: the first enemy sprite sheet, whose body colors come from the primary palette but whose outline is pure black (#000000), highlights pure white (#FFFFFF) and shadows a cool blue-grey (#5A6A7A). Request is tagged AD-VISUAL.
**Expected:** Assessment references the specific hex values and style rules from the provided art bible, not generic color theory advice, and returns `AD-VISUAL: REJECT` — the sprite breaks all three style rules, a style violation to resolve before the asset type is used — with each violation tied to the rule it breaks.
**Assertions:**
- [ ] References specific palette values from the provided art bible context
- [ ] Applies the specific style rules (no pure white/black, warm shadow undertones) from the provided document, naming the outline, highlight and shadow colors that break them
- [ ] Does not generate generic art direction feedback disconnected from the supplied art bible
- [ ] Verdict token is `AD-VISUAL: REJECT`, with rationale traceable to specific lines or rules in the provided context

### Case 6: Missing gate input — NOT ASSESSED
**Scenario:** A complete, internally consistent art bible is submitted for sign-off with the pillars and the visual identity anchor, but no platform or performance constraints: the context gives none, `project.yaml` sets no `platform.*` or `performance.*` keys, and `.claude/docs/technical-preferences.md` still holds only unconfigured placeholders. Request is tagged AD-ART-BIBLE.
**Expected:** Returns `AD-ART-BIBLE: NOT ASSESSED`, naming the platform and performance constraints as the input it could not read — without them, the gate's check that the asset standards are achievable on the platform cannot be made.
**Assertions:**
- [ ] Verdict token is `AD-ART-BIBLE: NOT ASSESSED` — not APPROVE, although every section it could check is sound
- [ ] Names the platform and performance constraints as the missing input
- [ ] Does not assume a platform or budget to complete the review

---

## Protocol Compliance

- [ ] Returns the verdict vocabulary the invoked gate's definition file lists — APPROVE / CONCERNS / REJECT for AD-ART-BIBLE and AD-VISUAL; CONCEPTS / STRONG / CONCERNS for AD-CONCEPT-VISUAL; READY / CONCERNS / NOT READY for AD-PHASE-GATE; `NOT ASSESSED`, naming the input, at any gate when an input the gate names is missing
- [ ] Stays within declared visual domain
- [ ] Escalates UX-vs-visual conflicts to creative-director
- [ ] Uses gate IDs in output (e.g., `AD-ART-BIBLE: APPROVE`) not inline prose verdicts
- [ ] Does not make binding UX interaction, audio, or code implementation decisions
- [ ] At a phase gate, treats an artifact the target phase requires that the calling skill passes as "none" as a finding (NOT READY or CONCERNS), and one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" as no finding — it judges readiness for the phase being entered, not a later one

---

## Coverage Notes
- AD-PHASE-GATE (full visual phase advancement) is not covered — deferred to integration with /gate-check skill.
- Asset pipeline standards (file format, resolution, naming conventions) compliance checks are not covered here.
- Shader visual output review is not covered — that interaction with the engine specialist is deferred.
- UI component visual review (as distinct from UX flow review) could benefit from additional cases.
