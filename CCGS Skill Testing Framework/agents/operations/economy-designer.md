# Agent Test Spec: economy-designer

## Agent Summary
- **Domain**: Resource economy design, loot table design, progression curves (XP, level, unlock), in-game market and shop design, economic balance analysis, sink and faucet mechanics, inflation/deflation risk assessment
- **Does NOT own**: Live ops event scheduling and structure (live-ops-designer), code implementation, analytics tracking design (analytics-engineer), narrative justification for economy systems (writer)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; escalates economy-breaking design conflicts to creative-director or producer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references economy, loot tables, progression curves, balance)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over live ops scheduling, code, or narrative

---

## Test Cases

### Case 1: In-domain request — loot table design for a chest
**Input**: "Design the loot table for a standard treasure chest in our dungeon game."
**Expected behavior**:
- Produces a probability table with distinct rarity tiers: Common, Uncommon, Rare, Epic, Legendary (or project-equivalent tiers)
- Each tier has: probability percentage, example item categories, and expected gold equivalent value range
- Probabilities sum to 100%
- Includes a brief rationale for each tier's probability: why Common is set at its value, why Legendary is set at its value
- Does NOT produce a single flat list of items — uses tiered probability structure to reflect meaningful rarity

### Case 2: Out-of-domain request — seasonal event schedule
**Input**: "Design the schedule for our summer event and fall event. When should they run and how long should each last?"
**Expected behavior**:
- Does not produce an event schedule or content cadence plan
- States clearly: "Live ops event scheduling is owned by live-ops-designer; I design the economic structure of rewards within events once the event schedule is defined"
- Offers to produce the reward value design for events once live-ops-designer defines the structure

### Case 3: Domain boundary — inflation risk from new currency
**Input**: "We're adding a new 'Prestige Coins' currency earned by completing all seasonal content. Players can spend them in a Prestige Shop."
**Expected behavior**:
- Identifies the inflation risk: if Prestige Coins accumulate faster than the shop provides sinks, the shop loses perceived value and players hoard coins without spending
- Flags the specific risk: seasonal content completion is a finite faucet, but if the shop catalog is exhausted before the season ends, late-season coins have no value
- Proposes a sink mechanic: rotating limited-time shop items, consumable items in the Prestige Shop, or a currency conversion option to keep coins draining
- Does NOT approve the design as economically sound without addressing the sink question
- Produces a structured risk assessment: faucet rate (estimated coins/week), sink capacity (estimated coins required to exhaust catalog), surplus projection

### Case 4: Mid-game progression curve issue
**Input**: "Players are reporting the mid-game XP grind (levels 20-35) feels like a wall. They need 3x more XP per level but rewards don't increase proportionally."
**Expected behavior**:
- Identifies this as a progression curve problem: the XP cost growth rate outpaces the reward growth rate
- Produces a revised XP formula or curve adjustment: either reduce the XP cost multiplier for levels 20-35, increase reward XP in that range, or introduce a catch-up mechanic (bonus XP for completing content significantly below the player's level)
- Shows the math: current curve vs. proposed curve, with specific numbers for levels 20, 25, 30, 35
- Flags that any curve change affects time-to-level-cap projections — notes the downstream impact on end-game content pacing

### Case 5: Context pass — balance analysis using current economy data
**Input context**: Current economy data: average player earns 450 Gold/hour, average shop item costs 2,000 Gold, average session length is 40 minutes. Premium items cost 5,000 Gold.
**Input**: "Is our current Gold economy healthy? Should we adjust prices or earn rates?"
**Expected behavior**:
- Uses the specific numbers provided: 450 Gold/hour = 300 Gold/40-min session; 2,000 Gold item requires ~4.4 sessions to afford; 5,000 Gold premium item requires ~11 sessions
- Evaluates whether these ratios feel rewarding or frustrating based on economy design principles
- Produces a concrete recommendation using the actual numbers: e.g., "At current earn rates, premium items take ~7.3 hours of play to afford — this is at the high end of acceptable; consider either increasing earn rate to 550 Gold/hour or reducing premium item cost to 4,000 Gold"
- Does NOT produce generic advice ("prices may be too high") without anchoring to the provided data

---

## Protocol Compliance

- [ ] Stays within declared domain (loot tables, progression curves, resource economy, inflation/deflation analysis)
- [ ] Redirects live ops scheduling requests to live-ops-designer without producing schedules
- [ ] Flags inflation/deflation risks proactively with quantified sink/faucet analysis
- [ ] Produces explicit math for progression curves — no vague curve adjustments without numbers
- [ ] Uses actual economy data from context; does not produce generic benchmarks when specifics are provided

---

## Coverage Notes
- Case 3 (inflation risk) is an economic health test — missed inflation risks cause long-term economy damage in live games
- Case 4 requires the agent to produce actual numbers, not curve shapes — verify math is present, not just a narrative
- Case 5 is the most important context-awareness test; agent must use provided data, not placeholder values
- No automated runner; review manually or via `$skill-test`
