# Agent Test Spec: analytics-engineer

## Agent Summary
- **Domain**: Telemetry event taxonomy and naming (`[category].[action].[detail]`), funnel definitions, A/B test framework design (hypothesis, segmentation, variant assignment, success metrics, minimum sample size, minimum run duration, mutual exclusion between concurrent tests), dashboard specification, privacy compliance of data collection, data-informed design recommendations
- **Does NOT own**: Implementing tracking in game code (programmers — it writes specs for them), design decisions (game-designer decides; data informs), economy design decisions (economy-designer), live ops event design (live-ops-designer)
- **Gate IDs**: None; reports to technical-director for system design and producer for insights

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references telemetry, A/B testing, event tracking, analytics)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit, Bash, WebSearch` — Bash serves the data-pipeline work `description:` names; tracking in game code is excluded by the body's "What This Agent Must NOT Do" list, not by the tool list
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over game implementation, economy design, or live ops scheduling

---

## Test Cases

### Case 1: In-domain request — tutorial event tracking design
**Input**: "Design the analytics event tracking for our tutorial. We want to know where players drop off and which steps they complete."
**Expected behavior**:
- Produces an event taxonomy for the tutorial: events for step start and step completion plus a drop-off event when a player exits mid-step, each with its properties and the exact condition that fires it
- Names events in its Event Naming Convention, `[category].[action].[detail]` — e.g. `tutorial.step.started`, `tutorial.step.completed`, `tutorial.step.abandoned`
- Gives every event a documented purpose ("Every event must have a documented purpose")
- Defines the tutorial as an onboarding funnel with the event that marks each funnel step (Funnel Analysis Design)
- Collects no personally identifiable information without an explicit requirement, and notes the opt-out path (Privacy Compliance)
- Does NOT produce implementation code — the output is a spec for programmers

### Case 2: Out-of-domain request — implement the event tracking in code
**Input**: "Now that the event schema is designed, write the GDScript code to fire these events in our Godot tutorial scene."
**Expected behavior**:
- Does not produce GDScript or any implementation code — "Implement tracking in game code (write specs for programmers)" is on its Must-NOT list
- Says implementation belongs to the programmers (e.g. `gameplay-programmer`) and that its part is the specification
- Produces the integration spec the programmer needs: event names, properties, when each event fires, and any privacy or opt-out constraint — the spec is its deliverable here, not an optional extra
- Asks before writing the spec to a file

### Case 3: Domain boundary — A/B test design for a UI change
**Input**: "We want to A/B test two versions of our HUD: the current version and a minimal version with only a health bar. Design the test."
**Expected behavior**:
- Produces a test design covering every element its A/B Test Framework names, none skipped:
  - **Hypothesis**: what the minimal HUD is expected to change and why (e.g. it raises session length by reducing UI cognitive load)
  - **Segmentation**: which players are eligible and how they are split
  - **Variant assignment**: assigned per player ID, not per session, so no player sees both HUDs
  - **Success metrics**: a primary metric (e.g. average session length) plus secondary metrics (e.g. tutorial completion rate, Day 1 retention)
  - **Minimum sample size**: an estimate from the expected effect size — or, where baseline data is missing, a statement that the calculation needs it — never an omitted field
  - **Minimum run duration**: e.g. at least two weeks, to capture weekly play patterns
- Output is structured as a formal test design, not a bullet list of ideas
- Does not decide in advance which HUD ships — results go to game-designer ("data informs, designers decide")

### Case 4: Conflict — test result vs. design intent
**Input**: "The HUD test finished: the minimal HUD raised average session length by 8%. Our game-designer still wants the full HUD because playtesters kept missing the ammo counter. Just ship the minimal HUD — the data is clear."
**Expected behavior**:
- Does not make the call on data alone — "Make game design decisions based solely on data" and "Override design intuition with data" are both on its Must-NOT list
- Presents both the result and the design concern to `game-designer`, who decides ("present both to game-designer")
- States what the data does and does not show (session length rose; nothing measured whether players lost information they needed) and may propose a follow-up test, without presenting it as the decision
- Does NOT tell the team to ship the minimal HUD on its own authority

### Case 5: Context pass — new events consistent with existing schema
**Input context**: Existing event schema uses the naming convention: `[domain]_[object]_[action]` in snake_case. Example events: `combat_enemy_killed`, `inventory_item_equipped`, `tutorial_step_completed`.
**Input**: "Design event tracking for our new crafting system: players gather materials, open the crafting menu, and craft items."
**Expected behavior**:
- Notices that the supplied schema differs from its own `[category].[action].[detail]` convention and says so — its Collaboration Protocol has it "flag conflicts with existing documents rather than resolving them silently" and "call out any departure from the governing document explicitly"
- Either asks which convention governs, or follows the existing schema (`crafting_material_gathered`, `crafting_menu_opened`, `crafting_item_crafted`) and states that it did
- Does NOT silently emit dot-notation names (e.g. `crafting.material.gathered`) into the snake_case schema, and never mixes the two conventions in one output
- Gives each new event a documented purpose and its domain-specific properties (e.g. material type, item id)

### Case 6: Conflict — overlapping A/B tests
**Input**: "We have two A/B tests running simultaneously: Test A (HUD variants) affects all players, and Test B (tutorial variants) also affects all players."
**Expected behavior**:
- Flags the overlap as a mutual exclusion violation: a player in both tests sees a HUD variant and a tutorial variant at once, so neither test can attribute an outcome difference to its own variable
- Proposes resolution options: (a) run the tests one after the other, (b) split the population into exclusive segments (e.g. 50% in Test A, 50% in Test B, none in both), or (c) a factorial design if the interaction itself matters (needs a larger sample)
- Does NOT recommend continuing both tests on overlapping populations

---

## Protocol Compliance

- [ ] Stays within declared domain (event taxonomy, funnels, A/B test design, dashboards, privacy)
- [ ] Redirects implementation requests to programmers with an integration spec, not code
- [ ] Produces A/B test designs covering hypothesis, segmentation, variant assignment, success metrics, minimum sample size and minimum run duration — never partial
- [ ] Flags concurrent tests on overlapping players as a mutual exclusion violation and proposes exclusive segments or sequencing
- [ ] Presents data and design intent to game-designer rather than deciding on data alone
- [ ] Flags a mismatch between a supplied naming convention and its own; never silently emits or mixes conventions

---

## Coverage Notes
- Case 3 (A/B test design completeness) is a quality gate — an incomplete test design wastes experiment budget
- Case 6 (mutual exclusion) is a data integrity test — overlapping tests produce unusable results; this must be caught
- Case 4 (data vs. design intent) is a coordination test — verify the agent leaves the call to game-designer
- Case 5 is the most important context-awareness test; naming convention drift across schemas causes dashboard breakage
- No automated runner; review manually or via `/skill-test`
