# Agent Test Spec: game-designer

## Agent Summary
**Domain owned:** Core loop design, progression systems, combat mechanics rules, economy design, player-facing rules and interactions.
**Does NOT own:** Code implementation (lead-programmer / gameplay-programmer), visual art (art-director), narrative lore and story (narrative-director — coordinates with), balance formula math (systems-designer — collaborates with).
**Model tier:** Sonnet (individual system design authoring and review).
**Gate IDs handled:** Design review verdicts on mechanic specs (no named gate ID prefix — uses APPROVED / NEEDS REVISION vocabulary).

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/game-designer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references core loop, progression, combat rules, economy, player-facing design — not generic)
- [ ] `allowed-tools:` list is read-focused; includes Read for GDDs and design docs; no Bash unless design tooling requires it
- [ ] Model tier is `sonnet` per coordination-rules.md
- [ ] Agent definition does not claim authority over code implementation, visual art style, or standalone narrative lore decisions

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** A mechanic spec for a "Stamina-Based Dodge" system is submitted for review. The spec defines: the player has a stamina pool (100 units), each dodge costs 25 stamina, stamina regenerates at 20 units/second when not dodging, and the dodge grants 0.3 seconds of invincibility. The core loop interaction is clearly described, rules are unambiguous, and edge cases (stamina at 0, dodge during regen) are addressed.
**Expected:** Returns `APPROVED` with rationale confirming the core loop clarity, unambiguous rules, and edge case coverage.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / NEEDS REVISION
- [ ] Rationale references specific design quality criteria (clear rules, edge case coverage, core loop coherence)
- [ ] Output stays within design scope — does not comment on how to implement it in code or what art assets it requires
- [ ] Verdict is clearly labeled with context (e.g., "Mechanic Spec Review: APPROVED")

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A team member asks game-designer to write the in-world lore explanation for why the stamina system exists (e.g., the narrative reason characters have stamina limits in the game world).
**Expected:** Agent declines to write narrative/lore content and redirects to writer or narrative-director.
**Assertions:**
- [ ] Does not write narrative or lore content
- [ ] Explicitly names `writer` or `narrative-director` as the correct handler
- [ ] May note the design intent that the lore should support (e.g., "the stamina system should reinforce the physical realism theme"), but defers the writing to the narrative team

### Case 3: Gate verdict — correct vocabulary
**Scenario:** A mechanic spec for "Environmental Hazard Damage" is submitted. The spec defines three hazard types (fire, acid, electricity) but does not specify what happens when a player is simultaneously affected by multiple hazard types, what happens when a hazard is applied during the invincibility window from a dodge, or what the damage frequency is (per-second, per-tick, on-enter).
**Expected:** Returns `NEEDS REVISION` with specific identification of the undefined edge cases: multi-hazard interaction, hazard-during-invincibility, and damage frequency specification.
**Assertions:**
- [ ] Verdict is exactly one of APPROVED / NEEDS REVISION — not freeform text
- [ ] Rationale identifies the specific missing edge cases by name
- [ ] Does not reject the entire mechanic — identifies the specific gaps to fill
- [ ] Provides actionable guidance on what to define (not how to implement it)

### Case 4: Conflict escalation — correct parent
**Scenario:** systems-designer proposes a damage formula with 6 variables and complex scaling interactions, arguing it produces the best tuning granularity. game-designer believes the formula is too complex for players to intuit and want a simpler 2-variable version.
**Expected:** game-designer owns the conceptual rule and player experience intention ("the damage should feel understandable to players"), but defers the formula granularity question to systems-designer. If the disagreement cannot be resolved between them (one wants complex, one wants simple), escalate to creative-director for a player experience ruling.
**Assertions:**
- [ ] Clearly states the player experience intention (intuitive damage, player agency)
- [ ] Defers formula granularity decisions to `systems-designer`
- [ ] Escalates unresolved disagreement to `creative-director` for player experience arbiter ruling
- [ ] Does not unilaterally impose a formula structure on systems-designer

### Case 5: Context pass — uses provided context
**Scenario:** Agent receives a gate context block that includes the game's three pillars: "player authorship," "consequence permanence," and "world responsiveness." A new mechanic spec for "permadeath with legacy bonuses" is submitted for review.
**Expected:** Assessment evaluates the mechanic against all three provided pillars — how does permadeath support player authorship, how do legacy bonuses express consequence permanence, and how does the world respond to a player's death? Uses the pillar vocabulary directly in the rationale.
**Assertions:**
- [ ] References all three provided pillars by name in the assessment
- [ ] Evaluates the mechanic's contribution to each pillar explicitly
- [ ] Does not generate generic game design advice — all feedback is tied to the provided pillar vocabulary
- [ ] Identifies if any pillar creates a tension with the mechanic and flags it with a specific concern

---

## Protocol Compliance

- [ ] Returns verdicts using APPROVED / NEEDS REVISION vocabulary only
- [ ] Stays within declared game design domain
- [ ] Escalates design-vs-formula conflicts to creative-director when unresolved
- [ ] Does not make binding code implementation, visual art, or standalone lore decisions
- [ ] Provides actionable design feedback, not implementation prescriptions

---

## Coverage Notes
- Economy design review (resource sinks, faucets, inflation prevention) is not covered — a dedicated case should be added.
- Progression system review (XP curves, unlock gates, player power trajectory) is not covered.
- Core loop validation across multiple interconnected systems (not just a single mechanic) is not covered — deferred to /review-all-gdds integration.
- Coordination protocol with systems-designer on formula ownership boundary could benefit from additional cases.
