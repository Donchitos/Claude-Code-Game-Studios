# Agent Test Spec: systems-designer

## Agent Summary
**Domain owned:** Combat formulas, progression curves, crafting recipes, status effect interaction matrices, feedback loop analysis, tuning documentation, simulation specs.
**Does NOT own:** High-level design direction (game-designer — direct collaboration partner), level and encounter design (level-designer), narrative and aesthetic decisions, code implementation.
**Gate IDs handled:** None. Formula reviews return findings and options; design-review verdicts come from the `/design-review` skill, which spawns systems-designer as a specialist.

---

## Static Assertions (Structural)

Verified by reading the agent's `.claude/agents/systems-designer.md` frontmatter:

- [ ] `description:` field is present and domain-specific (references formulas, progression curves, balance math, economy — not generic)
- [ ] `tools:` list is read/write-focused with Bash excluded (`disallowedTools:` lists Bash); every Write/Edit is gated by its "May I write" step or the orchestrator named-path exception
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over narrative, visual design, or conceptual mechanic rule ownership

---

## Test Cases

### Case 1: In-domain request — appropriate output format
**Scenario:** The user asks systems-designer to formalize the combat GDD's damage formula for its Formulas section: `damage = base_attack * (1 + strength_modifier * 0.1) - defense * 0.5`, with ranges base_attack [10–100], strength_modifier [0–20], defense [0–50].
**Expected:** Produces the formula in the mandatory Formula Output Format. The output range is not safe as written: it spans −15 (base_attack 10, strength_modifier 0, defense 50) to 300 (base_attack 100, strength_modifier 20, defense 0), so the agent flags the negative floor and offers clamping options for the user to choose.
**Assertions:**
- [ ] Output contains all four mandatory parts: named expression, variable table (Symbol / Type / Range / Description, including a result row), output range, and worked example
- [ ] Output range states the unclamped result spans −15 to 300, identifying the input combination that goes negative
- [ ] Offers ways to bound the negative floor (e.g., a minimum-damage clamp) as options with a recommendation, leaving the choice to the user
- [ ] Stays within the systems domain — does not comment on whether the mechanic is fun or how to implement it in code

### Case 2: Out-of-domain request — redirects or escalates
**Scenario:** A writer asks systems-designer to draft the quest script for a side quest that rewards the player with a rare crafting ingredient.
**Expected:** Agent declines to write the quest script — narrative decisions are outside its role — and offers only the systems side of the request: how rare the ingredient reward should be within the crafting economy.
**Assertions:**
- [ ] Does not write quest narrative content or dialogue
- [ ] States that the script is narrative work outside its role, leaving it with the writer who asked
- [ ] Offers the systems contribution instead (e.g., the ingredient's reward rarity or drop rate relative to the crafting economy), without making narrative decisions

### Case 3: Review findings — degenerate case at the boundaries
**Scenario:** `/design-review` in full mode spawns systems-designer as the adversarial specialist for a combat GDD. The spawn prompt reads: "For every formula in the GDD, plug in boundary values (minimum and maximum plausible inputs). Report whether any outputs go degenerate." The GDD's formula is `damage = base_attack * level_multiplier`, where `level_multiplier = (player_level / enemy_level) ^ 2` and levels run 1–50. At player level 50 against an enemy of level 1, the multiplier is 2500x — 25,000 damage from a 10-base-attack weapon.
**Expected:** Reports the degenerate case with its exact inputs and output, names the squared ratio as the cause, and offers revision approaches without mandating one. It returns findings, not a verdict — `/design-review` issues the verdict.
**Assertions:**
- [ ] Reports the specific degenerate input values (player level 50, enemy level 1) and the resulting output (2500x multiplier, 25,000 damage from 10 base attack)
- [ ] Identifies the squared level ratio as the component causing the issue, and states the output is unclamped — bounded only by the 1–50 level range, which caps the multiplier at 2500x — rather than calling it unbounded
- [ ] Suggests at least one revision approach (e.g., clamping the ratio, a log scale) as options, without mandating a choice
- [ ] Returns findings to the review, not its own APPROVED / NEEDS REVISION stamp

### Case 4: Conflict escalation — correct parent
**Scenario:** game-designer wants a simple, 2-variable damage formula for player intuitiveness. systems-designer argues that a 6-variable formula with elemental interactions is necessary for the depth of the combat system. Neither can agree on the right level of complexity.
**Expected:** systems-designer presents the trade-offs clearly — the tuning granularity of the 6-variable system versus the player legibility of the 2-variable system — and escalates to creative-director for a player experience ruling. The question of "how complex should the formula be for players" is a player experience question, not a pure math question.
**Assertions:**
- [ ] Presents the trade-offs between both approaches with specific examples
- [ ] Escalates to `creative-director` for the player experience ruling
- [ ] Does not unilaterally impose the 6-variable formula over game-designer's objection
- [ ] Remains available to implement whichever complexity level is approved

### Case 5: Context pass — uses provided context
**Scenario:** The request includes current balance data: enemy HP ranges from 100 to 10,000; player attack ranges from 15 to 150; the balanced matchup is an enemy with 1,000 HP against a player with 100 attack, attacking once per second; target time-to-kill is 8–12 seconds at the balanced matchup. A revised formula is proposed: `damage_per_hit = attack * 0.8`.
**Expected:** Runs the proposed formula against the provided data. At the balanced matchup, damage per hit is 80, so time-to-kill is 1,000 / 80 = 12.5 seconds — half a second outside the 8–12 second window. The agent reports the miss and offers adjustments as options, using the provided numbers throughout.
**Assertions:**
- [ ] Uses the provided HP and attack ranges (100–10,000 HP; 15–150 attack) in its variable ranges or analysis
- [ ] Calculates time-to-kill for the balanced matchup: 1,000 / (100 × 0.8) = 12.5 seconds
- [ ] Compares the result to the provided 8–12 second window and flags that it misses the upper bound
- [ ] Does not give generic balance advice — its claims and suggested adjustments use the provided numbers

---

## Protocol Compliance

- [ ] Every formula it produces carries the four mandatory parts: named expression, variable table, output range, worked example
- [ ] Stays within declared systems and formula domain
- [ ] Escalates player-experience complexity trade-offs to creative-director
- [ ] Does not make binding narrative, visual, code-implementation, or conceptual-mechanic decisions
- [ ] Provides concrete formula analysis, not subjective design opinions
- [ ] Asks "May I create [filepath] with the section skeleton?" before creating a document, and "May I write this section to [filepath]?" before writing each section

---

## Coverage Notes
- Progression curve design (XP curves, level-up scaling) is not covered — a dedicated case should be added.
- Economy model review (resource generation and sink rates, inflation prevention) is not covered.
- Status effect interaction matrix (stacking rules, priority, immunity interactions) is not covered.
- Registry awareness (checking `design/registry/entities.yaml` before defining a cross-system value) is not covered.
- Cross-system formula dependency review (e.g., crafting formula that feeds into combat formula) is not covered — deferred to integration tests.
