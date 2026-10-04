# Agent Test Spec: game-designer

## Agent Summary
**Domain owned:** Core loop design, progression systems, combat mechanics rules, economy design, player-facing rules and interactions, mechanic GDDs in `design/gdd/`.
**Does NOT own:** Code implementation (lead-programmer / gameplay-programmer), art and audio direction (art-director / audio-director), final narrative content (narrative-director — coordinates with), detailed formula math (systems-designer — delegates to).
**Gate IDs handled:** None. Design-review verdicts come from the `/design-review` skill (APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED); when that skill spawns game-designer as a specialist, the agent returns findings.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/game-designer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references core loop, progression, combat rules, economy, player-facing design — not generic)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, WebSearch and `disallowedTools:` lists Bash
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over code implementation, visual art style, or standalone narrative lore decisions

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** The project's `modes.workflow` is `full`. The user asks game-designer to design a "Stamina-Based Dodge" mechanic: the player has a stamina pool, each dodge costs stamina, stamina regenerates when not dodging, and a dodge grants a short invincibility window.
**Expected:** Follows its Question-First workflow — asks what the dodge should make the player feel and how it connects to the pillars, presents 2–4 options with a recommendation, then drafts the GDD in the Design Document Standard with its tunable values exposed as tuning knobs, asking before each write.
**Assertions:**
- [ ] Asks clarifying questions (intended player experience, pillar connection) before proposing a design, and presents 2–4 options with a recommendation that leaves the choice to the user
- [ ] The draft uses the eight Design Document Standard sections: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria
- [ ] Tuning Knobs classify each value (stamina pool, dodge cost, regen rate, invincibility duration) as feel, curve, or gate, and place them in external data files rather than hardcoding them
- [ ] Asks "May I create [filepath] with the section skeleton?" before creating the file, and "May I write this section to [filepath]?" before writing each section under `design/gdd/`; gives no implementation code or art direction

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A team member asks game-designer to write the in-world lore explanation for why the stamina system exists (e.g., the narrative reason characters have stamina limits in the game world).
**Expected:** Agent declines to write narrative/lore content and redirects to writer or narrative-director.
**Assertions:**
- [ ] Does not write narrative or lore content
- [ ] Explicitly names `writer` or `narrative-director` as the correct handler
- [ ] Any design intent it adds (e.g., "the stamina system should reinforce the physical realism theme") is framed as input for the narrative team, not written as the lore itself

### Case 3: Review findings — specific, verdict left to the review skill
**Scenario:** `/design-review` in full mode spawns game-designer as the adversarial specialist for `design/gdd/environmental-hazards.md`. The spawn prompt reads: "Your job is NOT to validate this design — your job is to find problems. Anchor your review to the Player Fantasy stated in Section B." The Player Fantasy is "the world is dangerous but fair — every hazard is readable and avoidable." The GDD defines three hazard types (fire, acid, electricity) but does not specify what happens when a player is in several hazards at once, what happens when a hazard hits during the dodge invincibility window, or the damage frequency (per-second, per-tick, on-enter).
**Expected:** Returns specific findings naming the three undefined edge cases, tied to the stated Player Fantasy, as gaps to fill rather than a rejection of the mechanic. It returns findings, not a verdict — `/design-review` issues the verdict.
**Assertions:**
- [ ] Names each missing edge case: simultaneous multi-hazard exposure, a hazard during dodge invincibility, and the undefined damage frequency
- [ ] Ties at least one gap to the stated Player Fantasy (e.g., an undefined damage frequency makes a hazard's threat unreadable, contradicting "readable and avoidable")
- [ ] Frames the gaps as rules to define in the GDD (what to specify), not as a rejection of the mechanic and not as implementation advice
- [ ] Returns findings to the review, not its own APPROVED / NEEDS REVISION stamp

### Case 4: Conflict escalation — correct parent
**Scenario:** systems-designer proposes a damage formula with 6 variables and complex scaling interactions, arguing it produces the best tuning granularity. game-designer believes the formula is too complex for players to intuit and want a simpler 2-variable version.
**Expected:** game-designer owns the conceptual rule and player experience intention ("the damage should feel understandable to players"), but defers the formula granularity question to systems-designer. If the disagreement cannot be resolved between them (one wants complex, one wants simple), escalate to creative-director for a player experience ruling.
**Assertions:**
- [ ] Clearly states the player experience intention (intuitive damage, player agency)
- [ ] Defers formula granularity decisions to `systems-designer`
- [ ] Escalates unresolved disagreement to `creative-director` for player experience arbiter ruling
- [ ] Does not unilaterally impose a formula structure on systems-designer

### Case 5: Context pass — uses provided context
**Scenario:** The request includes the game's three pillars: "player authorship," "consequence permanence," and "world responsiveness." A new mechanic spec for "permadeath with legacy bonuses" is submitted for the agent's assessment.
**Expected:** Assessment evaluates the mechanic against all three provided pillars — how permadeath supports player authorship, how legacy bonuses express or soften consequence permanence, and how the world responds to a player's death. Uses the pillar vocabulary directly, and flags pillar tensions for the user to decide.
**Assertions:**
- [ ] References all three provided pillars by name in the assessment
- [ ] Evaluates the mechanic's contribution to each pillar explicitly
- [ ] Does not generate generic game design advice — every point is tied to one of the provided pillars by name; a framework term (MDA, SDT) may support a point but never replaces the pillar it concerns
- [ ] Flags at least one specific pillar tension (e.g., legacy bonuses softening "consequence permanence") as an issue for the user's decision, not one it resolves silently

### Case 6: Section set at `modes.workflow: standard`
**Scenario:** The same "Stamina-Based Dodge" request as Case 1, but the project's `modes.workflow` is `standard`.
**Expected:** Drafts the five sections `standard` requires — Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria — plus Formulas, because the dodge defines numeric rules (stamina cost, regen rate, invincibility duration).
**Assertions:**
- [ ] The draft contains Overview, Detailed Rules, Edge Cases, Dependencies and Acceptance Criteria — Dependencies is not dropped
- [ ] Includes Formulas, because the mechanic defines numeric rules
- [ ] Does not treat Player Fantasy or Tuning Knobs as required sections at this tier

---

## Protocol Compliance

- [ ] Drafts mechanic documents in the Design Document Standard's sections and asks before writing each to `design/gdd/`
- [ ] Stays within declared game design domain
- [ ] Escalates design-vs-formula conflicts to creative-director when unresolved
- [ ] Does not make binding code implementation, visual art, or standalone lore decisions
- [ ] Provides actionable design feedback, not implementation prescriptions

---

## Coverage Notes
- Economy design review (resource sinks, faucets, inflation prevention) is not covered — a dedicated case should be added.
- Progression system review (XP curves, unlock gates, player power trajectory) is not covered.
- A direct "review this GDD" request is not covered — design-review verdicts come from `/design-review`, which the user runs.
- Mechanic authoring at `modes.workflow` `minimal`, where there is no GDD and `design/game-brief.md` is the design record, is not covered.
- Core loop validation across multiple interconnected systems (not just a single mechanic) is not covered — deferred to /review-all-gdds integration.
- Coordination protocol with systems-designer on formula ownership boundary could benefit from additional cases.
