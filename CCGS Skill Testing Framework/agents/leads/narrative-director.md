# Agent Test Spec: narrative-director

## Agent Summary
**Domain owned:** Story architecture, character design direction, world-building oversight, ND-CONSISTENCY gate, dialogue strategy.
**Does NOT own:** Visual art style (art-director), technical systems or code (lead-programmer), production scheduling (producer), game mechanics rules (game-designer).
**Gate IDs handled:** ND-CONSISTENCY (verdicts APPROVE / CONCERNS / REJECT, defined in `.claude/docs/director-gates/nd-consistency.md`).

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/narrative-director.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references story, character, world-building, consistency — not generic)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, WebSearch and `disallowedTools:` lists Bash
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over visual style, technical systems, or production scheduling

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A new lore document for "The Sunken Archive" location is submitted. The document establishes that the Archive was flooded 200 years ago during the Great Collapse, consistent with the established timeline in the world-bible. All named characters referenced are consistent with their established profiles, and the tone matches the narrative bible's tone guide. The gate context passes every input `.claude/docs/director-gates/nd-consistency.md` names: the document path, the tone guide, the world-bible's timeline rules, and the profiles of the characters it references. Request is tagged ND-CONSISTENCY.
**Expected:** Returns `APPROVE` with rationale confirming the timeline alignment, character consistency, and tone.
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT (the ND-CONSISTENCY gate's vocabulary) — here APPROVE
- [ ] Rationale answers each question the gate prompt asks: character consistency with established profiles, contradictions with established lore, and tone
- [ ] Rationale references the specific established facts verified (the 200-year timeline, the Great Collapse event)
- [ ] Output stays within narrative scope — does not comment on visual design of the location or its technical implementation

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A developer asks narrative-director to review and optimize the shader code used for the "ancient glow" visual effect on Archive artifacts.
**Expected:** Agent declines to evaluate the shader code. It names `technical-artist` — the owner of shader, VFX and rendering code in its own "must not" list — as who reviews and optimizes it; naming `art-director`, who owns how the effect should look, as well is fine. Any narrative input it adds is the mood the effect should carry.
**Assertions:**
- [ ] Does not review, rewrite, or optimize the shader code, and makes no binding decision about visual implementation
- [ ] Names `technical-artist` (or the engine's shader specialist) as the owner of the shader code, per its "Review or change shader, VFX or rendering code (technical-artist owns it; art-director owns how it should look)" limit — naming `art-director` too is acceptable, naming only art-director is not
- [ ] Any narrative input it gives (e.g., "should feel ancient and sacred, not technological") is framed as input for the visual owners, not as a visual or technical decision

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A new character backstory document is submitted for the character "Aldric Vorne." The document states Aldric was born in the Capital 150 years ago and witnessed the Great Collapse firsthand; the backstory's central arc is his guilt over the Collapse he watched happen. The established world-bible states Aldric was born 50 years after the Great Collapse in a provincial town, not the Capital. Request is tagged ND-CONSISTENCY.
**Expected:** Returns `REJECT` — the contradicted facts carry the backstory's central arc, so they break its narrative foundation rather than being a local fix — listing both contradictions: birth timing (150 years ago vs. 50 years after the Collapse) and birth location (Capital vs. provincial town).
**Assertions:**
- [ ] Verdict is exactly one of APPROVE / CONCERNS / REJECT — not freeform text; here REJECT, because the contradicted facts are load-bearing for the whole backstory (a contradiction it found takes the gate's word, so it is not NOT ASSESSED even though no character profile is passed)
- [ ] The verdict carries both contradictions specifically, in the gate's `REJECT [contradictions ...]` form — not just "doesn't match lore"
- [ ] References the world-bible as the authoritative source for the established facts
- [ ] Does not write a replacement backstory itself — the rewrite belongs to the content author (lore entries are delegated to `writer` / `world-builder` in its Delegation Map)

### Case 4: Conflict escalation — correct parent
**Scenario:** A writer has established in their latest dialogue that the ancient civilization "spoke only in song." The world-builder's existing lore entries describe the same civilization communicating through written glyphs. Both report to narrative-director, and the two disagree on which is canonical.
**Expected:** narrative-director resolves the conflict at its own tier — it is the shared parent of writer and world-builder, so it does not escalate to creative-director. Following its collaboration protocol, it presents reconciliation options with a recommended canonical ruling (e.g., "glyph-writing is the canonical primary communication; song is ritual/ceremonial"), leaves the final call to the user, and then directs both writer and world-builder to align their work to the confirmed ruling.
**Assertions:**
- [ ] Resolves the conflict itself as the shared parent — does not defer this intra-narrative conflict to creative-director
- [ ] Presents reconciliation options with a clearly stated recommended ruling, and leaves the final canon decision to the user
- [ ] Directs both parties to update their documents to the ruling: writer revises the dialogue, world-builder updates the lore entry
- [ ] Proposes recording the ruling as a canonical fact in the world-building documentation, so later lore can be checked against it

### Case 5: Context pass — uses provided context
**Scenario:** A new story chapter is submitted for ND-CONSISTENCY review. It introduces a previously unregistered character. The gate context passes three documents: the world-bible (the Great Collapse timeline and causes), the character registry (canonical character ages, origins, and allegiances), and a faction document describing the Sunken Archive Keepers.
**Expected:** Assessment cross-references the new character against the character registry (no conflict), checks the chapter's timeline references against the world-bible, and evaluates the chapter's portrayal of the Archive Keepers against the faction document. Uses specific facts from all three provided documents and returns an ND-CONSISTENCY verdict.
**Assertions:**
- [ ] Cross-references the new character against the provided character registry
- [ ] Checks timeline references against the provided world-bible facts
- [ ] Evaluates faction portrayal against the provided faction document
- [ ] Returns one of APPROVE / CONCERNS / REJECT with a rationale traceable to the three provided documents — no generic narrative feedback

### Case 6: Gate input missing — NOT ASSESSED
**Scenario:** ND-CONSISTENCY is invoked for a new dialogue file in which "Aldric Vorne" speaks. The gate context passes the file path and the world-building rules, and the dialogue contradicts none of them — but Aldric's character profile, an input the gate names, is not passed, so his voice cannot be checked against it.
**Expected:** Returns `ND-CONSISTENCY: NOT ASSESSED`, naming the missing input (Aldric Vorne's character profile), rather than APPROVE — voice consistency against a profile it never saw has not been established.
**Assertions:**
- [ ] Verdict is `NOT ASSESSED` — not APPROVE, CONCERNS or REJECT — because the inputs it could read show no inconsistency
- [ ] Names the missing input: Aldric Vorne's character profile
- [ ] Does not reconstruct Aldric's established voice from the dialogue itself or from memory to complete the check

---

## Protocol Compliance

- [ ] Returns ND-CONSISTENCY verdicts using APPROVE / CONCERNS / REJECT only — or NOT ASSESSED, naming the input, when an input the gate names is missing and no inconsistency was found
- [ ] Asks "May I create [filepath] with the section skeleton?" before creating a narrative document, and "May I write this section to [filepath]?" before writing each section
- [ ] Stays within declared narrative domain
- [ ] Resolves intra-narrative conflicts at its own tier instead of escalating them, while leaving the final canon decision to the user
- [ ] A CONCERNS or REJECT verdict names the specific inconsistencies or contradictions, as the gate prompt's `CONCERNS [...]` / `REJECT [...]` forms require — never a bare verdict word
- [ ] Does not make binding visual design, technical, or production decisions

---

## Coverage Notes
- Dialogue quality review (distinct from world-building consistency) is not covered — a dedicated case should be added.
- The CONCERNS verdict (fixable inconsistencies that do not break the narrative foundation) has no dedicated case.
- Multi-document consistency check across a full chapter set is not covered — deferred to /review-all-gdds integration.
- Narrative impact of mechanical changes (e.g., a game mechanic that undermines story tension) requires coordination with game-designer and is not covered here.
- Character arc review (progression, motivation coherence over time) is not covered.
