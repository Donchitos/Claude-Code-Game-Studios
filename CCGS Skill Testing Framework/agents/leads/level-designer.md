# Agent Test Spec: level-designer

## Agent Summary
**Domain owned:** Level layouts, encounter design, pacing and tension arc, environmental storytelling, spatial puzzles.
**Does NOT own:** Narrative dialogue (writer / narrative-director), visual art style (art-director), code implementation (lead-programmer / ai-programmer), enemy AI behavior logic (ai-programmer / gameplay-programmer).
**Model tier:** Sonnet (individual system analysis — level design review and encounter assessment).
**Gate IDs handled:** Level design review verdicts (uses APPROVED / REVISION NEEDED vocabulary).

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/level-designer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references level layout, encounter design, pacing, environmental storytelling — not generic)
- [ ] `allowed-tools:` list is read-focused; includes Read for level design documents and GDDs; no Bash unless level tooling requires it
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over narrative dialogue, AI behavior code, or visual art style

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A level layout document for "The Flooded Tunnels" is submitted for review. The layout includes: a low-intensity exploration opening section, two mid-intensity encounters with visible escape routes, a tension-building narrow passage with environmental hazards, and a high-intensity final encounter room followed by a release/reward area. The pacing follows a classic tension-arc structure.
**Expected:** Returns `APPROVED` with rationale confirming the pacing follows the tension arc, encounters are varied in intensity, and spatial readability supports player navigation.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / REVISION NEEDED
- [ ] Rationale references specific pacing arc elements (opening, escalation, climax, release)
- [ ] Output stays within level design scope — does not comment on visual art style or enemy AI code behavior
- [ ] Verdict is clearly labeled with context (e.g., "Level Design Review: APPROVED")

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A team member asks level-designer to write the behavior tree code for an enemy patrol AI that navigates the level layout.
**Expected:** Agent declines to write AI behavior code and redirects to ai-programmer or gameplay-programmer.
**Assertions:**
- [ ] Does not write or specify code for AI behavior logic
- [ ] Explicitly names `ai-programmer` or `gameplay-programmer` as the correct handler
- [ ] May specify the desired patrol behavior from a level design perspective (e.g., "patrol should cover both chokepoints and create pressure in this zone"), but defers all code implementation to the programmer

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A level layout for "The Ancient Forge" is submitted. Section 3 of the level introduces a dramatically harder enemy encounter (elite enemy with new attack patterns) with no preceding tutorial moment, no environmental readability cues (no visible cover or safe zones), and no checkpoint nearby. Players are likely to die repeatedly with no clear signal of what to do differently.
**Expected:** Returns `REVISION NEEDED` with specific identification of the difficulty spike in section 3, the missing readability cue, and the absence of a nearby checkpoint to reduce frustration from repeated deaths.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / REVISION NEEDED — not freeform text
- [ ] Rationale identifies section 3 specifically as the location of the issue
- [ ] Identifies the three specific problems: difficulty spike, missing readability cue, missing checkpoint
- [ ] Provides actionable revision guidance (e.g., "add a visible safe zone, pre-encounter cue object, or reduce elite's health for first introduction")

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants higher encounter density throughout the level (more enemies in each room) to increase combat challenge. level-designer believes this density undermines the pacing arc by eliminating rest periods and making the level feel relentless without reward.
**Expected:** level-designer clearly articulates the pacing concern (eliminating rest periods removes the tension-release rhythm), acknowledges game-designer's challenge goal, and escalates to creative-director for a design arbiter ruling on whether challenge density or pacing rhythm takes precedence for this level.
**Assertions:**
- [ ] Articulates the specific pacing impact of increased encounter density
- [ ] Escalates to `creative-director` as the design arbiter
- [ ] Does not unilaterally override game-designer's challenge density request
- [ ] Frames the conflict clearly: "challenge density vs. pacing rhythm — which takes precedence here?"

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes game-feel notes specifying: "exploration sections should feel vast and lonely," "combat sections should feel urgent and claustrophobic," and "reward rooms should feel safe and visually distinct." A new level layout is submitted for review.
**Expected:** Assessment evaluates each section type (exploration, combat, reward) against the specific feel targets from the provided context. Uses the exact vocabulary from the feel notes ("vast and lonely," "urgent and claustrophobic," "safe and visually distinct") in the rationale.
**Assertions:**
- [ ] References all three feel targets from the provided context by their exact vocabulary
- [ ] Evaluates each relevant section of the submitted layout against its corresponding feel target
- [ ] Does not generate generic pacing advice — all feedback is tied to the provided feel targets
- [ ] Identifies any section where the layout conflicts with its assigned feel target

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVED / REVISION NEEDED vocabulary only
- [ ] Stays within declared level design domain
- [ ] Escalates challenge-density vs. pacing conflicts to creative-director
- [ ] Does not make binding narrative dialogue, AI code implementation, or visual art style decisions
- [ ] Provides actionable level design feedback with spatial specifics, not abstract design opinions

---

## Coverage Notes
- Environmental storytelling review (using spatial elements to convey narrative without dialogue) could benefit from a dedicated case.
- Spatial puzzle design review is not covered — a dedicated case should be added when puzzle mechanics are defined.
- Multi-level pacing review (arc across an entire act or world map) is not covered — deferred to milestone-level design review.
- Interaction between level-designer and narrative-director for environmental lore placement is not covered.
- Accessibility review of level layouts (colorblind indicators, difficulty options for spatial challenges) is not covered.
