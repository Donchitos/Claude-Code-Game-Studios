# Agent Test Spec: economy-designer

## Agent Summary
- **Domain**: Resource economy design, loot table design, progression curves (XP, level, unlock), in-game market and shop design, economic balance analysis, sink and faucet mechanics, inflation/deflation risk assessment, entity registry values for items and currencies
- **Does NOT own**: Live ops event scheduling and structure (live-ops-designer), core gameplay mechanics (game-designer), code implementation, analytics tracking design (analytics-engineer), narrative justification for economy systems (writer)
- **Gate IDs**: None; reports to game-designer; monetization decisions need creative-director approval

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references economy, loot tables, progression curves, balance)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit` and `disallowedTools:` names `Bash` — design documents only, no code or analytics tooling
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over live ops scheduling, code, or narrative

---

## Test Cases

### Case 1: In-domain request — loot table design for a chest
**Input**: "Design the loot table for a standard treasure chest in our dungeon game."
**Expected behavior**:
- Before drafting, asks clarifying questions and presents 2-4 options with a recommendation (Question-First Workflow) — e.g. tier names, whether chests use pity timers or bad-luck protection
- Reads `design/registry/entities.yaml` before authoring and uses registered item values as canonical; a value that differs from a registered entry is flagged as a proposed registry change, not silently used
- Produces the table in its Reward Output Format (output, rate or weight, condition, notes) with distinct rarity tiers — Common, Uncommon, Rare, Epic, Legendary, or project-equivalent — not a single flat list of items
- Tier rates form a complete distribution: percentages sum to 100%, or weights are given with their total
- States the expected acquisition for each tier (attempts on average to receive it) and names the reward-schedule principle behind the table (Reward Psychology)
- Offers to register new cross-system items: "May I add them to `design/registry/entities.yaml`?"

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
- States the current and proposed curves as formulas with defined variables and evaluates both across the 20–35 range, both ends included (e.g., at levels 20, 25, 30 and 35) — `coding-standards.md` requires design math "defined with variables" and balance values linked to their source formula
- Flags that any curve change affects time-to-level-cap projections — notes the downstream impact on end-game content pacing (its Progression Curve Design models expected player power at each stage)

### Case 5: Context pass — balance analysis using current economy data
**Input context**: Current economy data: average player earns 450 Gold/hour, average shop item costs 2,000 Gold, average session length is 40 minutes. Premium items cost 5,000 Gold.
**Input**: "Is our current Gold economy healthy? Should we adjust prices or earn rates?"
**Expected behavior**:
- Uses the specific numbers provided: 450 Gold/hour = 300 Gold per 40-minute session; a 2,000 Gold item takes ~4.4 hours (~6.7 sessions) to afford; a 5,000 Gold premium item takes ~11.1 hours (~16.7 sessions)
- Evaluates those acquisition times against its Economic Health Metrics (average currency per hour, item acquisition rate)
- Presents options anchored to the numbers — e.g. raise the earn rate or lower the premium price — with the resulting hours and sessions for each, makes a recommendation, and leaves the choice to the user (Question-First Workflow)
- Does NOT produce generic advice ("prices may be too high") without anchoring to the provided data

---

## Protocol Compliance

- [ ] Stays within declared domain (loot tables, progression curves, resource economy, inflation/deflation analysis)
- [ ] Redirects live ops scheduling requests to live-ops-designer without producing schedules
- [ ] Flags inflation/deflation risks proactively with quantified sink/faucet analysis
- [ ] States progression-curve changes as formulas with defined variables and worked numbers — no vague curve adjustments
- [ ] Uses actual economy data from context; does not produce generic benchmarks when specifics are provided
- [ ] Checks `design/registry/entities.yaml` before authoring items and flags any change to a registered value
- [ ] Asks "May I create [filepath] with the section skeleton?" before creating a multi-section document, and "May I write this section to [filepath]?" before writing each section

---

## Coverage Notes
- Case 1 exercises Registry Awareness — include `design/registry/entities.yaml` in the fixture
- Case 3 (inflation risk) is an economic health test — missed inflation risks cause long-term economy damage in live games
- Case 4 requires the agent to produce actual numbers, not curve shapes — verify math is present, not just a narrative
- Case 5 is the most important context-awareness test; agent must use provided data, not placeholder values
- No automated runner; review manually or via `/skill-test`
