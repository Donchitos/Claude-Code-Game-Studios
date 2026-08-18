# Agent Test Spec: narrative-director

## Agent Summary
**Domain owned:** Story architecture, character design direction, world-building oversight, ND-CONSISTENCY gate, dialogue quality review.
**Does NOT own:** Visual art style (art-director), technical systems or code (lead-programmer), production scheduling (producer), game mechanics rules (game-designer).
**Model tier:** Sonnet (individual system analysis — narrative consistency and lore review).
**Gate IDs handled:** ND-CONSISTENCY.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/narrative-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references story, character, world-building, consistency — not generic)
- [ ] `allowed-tools:` list is read-focused; includes Read for lore documents, GDDs, and narrative docs; no Bash unless justified
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over visual style, technical systems, or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A new lore document for "The Sunken Archive" location is submitted. The document establishes that the Archive was flooded 200 years ago during the Great Collapse, consistent with the established timeline in the world-bible. All named characters referenced are consistent with their established backstories. Request is tagged ND-CONSISTENCY.
**Expected:** Returns `ND-CONSISTENCY: CONSISTENT` with rationale confirming the timeline alignment and character reference accuracy.
**Assertions:**
- [ ] Verdict is exactly one of CONSISTENT / INCONSISTENT
- [ ] Verdict token is formatted as `ND-CONSISTENCY: CONSISTENT`
- [ ] Rationale references specific established facts verified (the 200-year timeline, the Great Collapse event)
- [ ] Output stays within narrative scope — does not comment on visual design of the location or its technical implementation

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A developer asks narrative-director to review and optimize the shader code used for the "ancient glow" visual effect on Archive artifacts.
**Expected:** Agent declines to evaluate shader code and redirects to the appropriate engine specialist (godot-gdscript-specialist or equivalent shader specialist).
**Assertions:**
- [ ] Does not make any binding decision about shader code or visual implementation
- [ ] Explicitly names the appropriate engine or shader specialist as the correct handler
- [ ] May note the intended narrative mood the effect should convey (e.g., "should feel ancient and sacred, not technological"), but defers all technical visual implementation

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A new character backstory document is submitted for the character "Aldric Vorne." The document states Aldric was born in the Capital 150 years ago and witnessed the Great Collapse firsthand. However, the established world-bible states Aldric was born 50 years after the Great Collapse in a provincial town, not the Capital. Request is tagged ND-CONSISTENCY.
**Expected:** Returns `ND-CONSISTENCY: INCONSISTENT` with specific citation of the two contradicting facts: the birth timing (150 years ago vs. 50 years post-Collapse) and the birth location (Capital vs. provincial town).
**Assertions:**
- [ ] Verdict is exactly one of CONSISTENT / INCONSISTENT — not freeform text
- [ ] Verdict token is formatted as `ND-CONSISTENCY: INCONSISTENT`
- [ ] Rationale cites both contradictions specifically, not just "doesn't match lore"
- [ ] References the authoritative source (world-bible) for the established facts

### Case 4: Conflict escalation — correct parent
**Scenario:** A writer has established in their latest dialogue that the ancient civilization "spoke only in song." The world-builder's existing lore entries describe the same civilization communicating through written glyphs. Both are in the narrative domain, and the two creators disagree on which is canonical.
**Expected:** narrative-director makes a binding canonical decision within their domain. They do not need to escalate to a higher authority for intra-narrative conflicts — this is within their declared domain authority. They issue a ruling (e.g., "glyph-writing is the canonical primary communication; song may be ritual/ceremonial") and direct both writer and world-builder to align their work to the ruling.
**Assertions:**
- [ ] Makes a binding canonical decision — does not defer this intra-narrative conflict to creative-director
- [ ] Decision is clearly stated and provides a path to reconciliation for both parties
- [ ] Directs both parties (writer and world-builder) to update their respective documents to align
- [ ] Notes the decision in a way that can be added to the world-bible as a canonical fact

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes three existing lore documents: the world-bible (establishes the Great Collapse timeline and causes), the character registry (lists canonical character ages, origins, and allegiances), and a faction document (describes the Sunken Archive Keepers). A new story chapter is submitted that introduces a previously unregistered character.
**Expected:** Assessment cross-references the new character against the character registry (no conflict), checks the chapter's timeline references against the world-bible, and evaluates the chapter's portrayal of the Archive Keepers against the faction document. Uses specific facts from all three provided documents in the assessment.
**Assertions:**
- [ ] Cross-references the new character against the provided character registry
- [ ] Checks timeline references against the provided world-bible facts
- [ ] Evaluates faction portrayal against the provided faction document
- [ ] Does not generate generic narrative feedback — all assertions are traceable to the provided documents

---

## Protocol Compliance

- [ ] Returns verdicts using CONSISTENT / INCONSISTENT vocabulary only
- [ ] Stays within declared narrative domain
- [ ] Makes binding decisions for intra-narrative conflicts without unnecessary escalation
- [ ] Uses gate IDs in output (e.g., `ND-CONSISTENCY: INCONSISTENT`) not inline prose verdicts
- [ ] Does not make binding visual design, technical, or production decisions

---

## Coverage Notes
- Dialogue quality review (distinct from world-building consistency) is not covered — a dedicated case should be added.
- Multi-document consistency check across a full chapter set is not covered — deferred to /review-all-gdds integration.
- Narrative impact of mechanical changes (e.g., a game mechanic that undermines story tension) requires coordination with game-designer and is not covered here.
- Character arc review (progression, motivation coherence over time) is not covered.
