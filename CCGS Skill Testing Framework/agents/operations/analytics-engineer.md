# Agent Test Spec: analytics-engineer

## Agent Summary
- **Domain**: Telemetry architecture and event schema design, A/B test framework design, player behavior analysis methodology, analytics dashboard specification, event naming conventions, data pipeline design (schema → ingestion → dashboard)
- **Does NOT own**: Game implementation of event tracking (appropriate programmer), economy design decisions informed by analytics (economy-designer), live ops event design (live-ops-designer)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; produces schemas and test designs; defers implementation to programmers

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references telemetry, A/B testing, event tracking, analytics)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over game implementation, economy design, or live ops scheduling

---

## Test Cases

### Case 1: In-domain request — tutorial event tracking design
**Input**: "Design the analytics event tracking for our tutorial. We want to know where players drop off and which steps they complete."
**Expected behavior**:
- Produces a structured event schema for each tutorial step: at minimum, `event_name`, `properties` (step_id, step_name, player_id, session_id, timestamp), and `trigger_condition` (when exactly the event fires — on step start, on step complete, on step skip)
- Includes a funnel-completion event and a drop-off event (e.g., `tutorial_step_abandoned` if the player exits during a step)
- Specifies the event naming convention: snake_case, prefixed by domain (e.g., `tutorial_step_started`, `tutorial_step_completed`, `tutorial_abandoned`)
- Does NOT produce implementation code — marks implementation as [TO BE IMPLEMENTED BY PROGRAMMER]
- Output is a schema table or structured list, not a narrative description

### Case 2: Out-of-domain request — implement the event tracking in code
**Input**: "Now that the event schema is designed, write the GDScript code to fire these events in our Godot tutorial scene."
**Expected behavior**:
- Does not produce GDScript or any implementation code
- States clearly: "Telemetry implementation in game code is handled by the appropriate programmer (gameplay-programmer or systems-programmer); I provide the event schema and integration requirements"
- Optionally produces an integration spec: what the programmer needs to know to implement correctly (event name, properties, when to fire, what analytics SDK or endpoint to use)

### Case 3: Domain boundary — A/B test design for a UI change
**Input**: "We want to A/B test two versions of our HUD: the current version and a minimal version with only a health bar. Design the test."
**Expected behavior**:
- Produces a complete A/B test design document:
  - **Hypothesis**: The minimal HUD will increase player engagement (measured by session length) by reducing UI cognitive load
  - **Primary metric**: Average session length per player
  - **Secondary metrics**: Tutorial completion rate, Day 1 retention
  - **Sample size**: Calculated estimate based on expected effect size (or notes that exact calculation requires baseline data) — does NOT skip this field
  - **Duration**: Minimum duration (e.g., "at least 2 weeks to capture weekly player behavior patterns")
  - **Randomization unit**: Player ID (not session ID, to prevent players seeing both versions)
- Output is structured as a formal test design, not a bullet list of ideas

### Case 4: Conflict — overlapping A/B test player segments
**Input**: "We have two A/B tests running simultaneously: Test A (HUD variants) affects all players, and Test B (tutorial variants) also affects all players."
**Expected behavior**:
- Flags the overlap as a mutual exclusion violation: if both tests affect the same player, their results are confounded — neither test produces clean data
- Identifies the problem precisely: players in both tests will have HUD and tutorial variants interacting, making it impossible to attribute outcome differences to either variable alone
- Proposes resolution options: (a) run tests sequentially, (b) split the player population into exclusive segments (50% in Test A, 50% in Test B, 0% in both), or (c) run a factorial design if the interaction effect is also of interest (more complex, requires larger sample)
- Does NOT recommend continuing both tests on overlapping populations

### Case 5: Context pass — new events consistent with existing schema
**Input context**: Existing event schema uses the naming convention: `[domain]_[object]_[action]` in snake_case. Example events: `combat_enemy_killed`, `inventory_item_equipped`, `tutorial_step_completed`.
**Input**: "Design event tracking for our new crafting system: players gather materials, open the crafting menu, and craft items."
**Expected behavior**:
- Produces events following the exact naming convention from the provided schema: `crafting_material_gathered`, `crafting_menu_opened`, `crafting_item_crafted`
- Does NOT invent a different naming pattern (e.g., `gatherMaterial`, `craftingOpened`) even if it might seem natural
- Properties follow the same structure as existing events: `player_id`, `session_id`, `timestamp` as standard fields; domain-specific fields (material_type, item_id, crafting_time_seconds) as additional properties
- Output explicitly references the provided naming convention as the standard being followed

---

## Protocol Compliance

- [ ] Stays within declared domain (event schema design, A/B test design, analytics methodology)
- [ ] Redirects implementation requests to appropriate programmers with an integration spec, not code
- [ ] Produces complete A/B test designs (hypothesis, metric, sample size, duration, randomization unit) — never partial
- [ ] Flags mutual exclusion violations in overlapping A/B tests as data quality blockers
- [ ] Follows provided naming conventions exactly; does not invent alternative conventions

---

## Coverage Notes
- Case 3 (A/B test design completeness) is a quality gate — an incomplete test design wastes experiment budget
- Case 4 (mutual exclusion) is a data integrity test — overlapping tests produce unusable results; this must be caught
- Case 5 is the most important context-awareness test; naming convention drift across schemas causes dashboard breakage
- No automated runner; review manually or via `$skill-test`
