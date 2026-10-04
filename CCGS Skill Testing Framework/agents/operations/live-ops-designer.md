# Agent Test Spec: live-ops-designer

## Agent Summary
- **Domain**: Post-launch content strategy, seasonal events (design and structure), battle pass design, content cadence planning, player retention mechanic design, live service feature roadmaps, monetization ethics policy
- **Does NOT own**: Economy math — currencies, sinks, prices and reward values (economy-designer), analytics tracking implementation (analytics-engineer), narrative content within events (writer), code implementation
- **Gate IDs**: None; escalates predatory monetization and event-vs-progression conflicts to creative-director

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references live ops, seasonal events, battle pass, retention)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit` and `disallowedTools:` names `Bash` — design documents only, no shell, code or analytics tooling
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over economy math, analytics pipelines, or narrative direction

---

## Test Cases

### Case 1: In-domain request — summer event design
**Input**: "Design a summer event for our game. It should run for 3 weeks and give players reasons to log in daily."
**Expected behavior**:
- Before drafting, asks clarifying questions and presents 2-4 options with a recommendation (Question-First Workflow)
- The event brief carries every field its Event Design requires: start date, end date, mechanics, rewards, success criteria — plus a fallback plan if the event breaks (disable, extend, compensate)
- Includes daily login retention hooks (e.g., daily challenges, login streaks, time-limited rewards) — the request's "reasons to log in daily" — paced across the full 3 weeks, not front-loaded into the first days (e.g., weekly milestones, or the weekly challenges its Weekly cadence tier names)
- Names reward categories (cosmetic, functional, currency) but does NOT assign specific reward values or currency amounts — those are left to economy-designer ("exact values assigned by economy-designer")
- Asks before writing the brief to `design/live-ops/events/`

### Case 2: Out-of-domain request — reward value calculation
**Input**: "How much premium currency should we give out in this event? What's the fair value of each cosmetic reward tier?"
**Expected behavior**:
- Does not produce currency amounts or reward valuation
- Says reward values and currency amounts are economy-designer's to assign, and that its part is defining which rewards exist and how they are structured
- Offers to produce the reward structure (tiers, unlock gates, rarity distribution, reward categories) so economy-designer has something concrete to value

### Case 3: Domain boundary — predatory monetization concern
**Input**: "Let's design the battle pass so that players need to spend premium currency on top of the pass price to complete all tiers within the season."
**Expected behavior**:
- Flags this design as predatory — pay-to-complete gating is named in its Escalation Paths
- Does NOT produce a design that requires additional purchases after a battle pass purchase without flagging it ("do NOT implement it silently")
- Offers at least one compliant option alongside the flag (Question-First step 2 presents 2-4 options): a pass completable by a buyer playing at a reasonable daily pace, using the catch-up mechanics its Battle Pass Design calls for
- Documents the concern in `design/live-ops/ethics-policy.md` (asking before writing) and escalates to creative-director for a binding ruling on whether the design proceeds, is modified, or is blocked
- Does not refuse to continue entirely — offers the ethical alternative and awaits direction

### Case 4: Conflict — event schedule vs. main game progression pacing
**Input**: "We want to run a double-XP event during weeks 3-5 of the season, but our progression designer says that's when players are supposed to hit the mid-game difficulty curve."
**Expected behavior**:
- Identifies the conflict: a double-XP event during the mid-game difficulty curve compresses the intended progression pacing
- Does NOT unilaterally move or cancel either element
- Escalates to creative-director: a live-ops schedule that forces players off a designed progression curve is the "Cross-domain design conflict" its Escalation Paths names
- Presents both positions — the event's retention value and the intended progression experience — and lets creative-director adjudicate; any resolution it suggests (shift the event timing, scope the boost to non-core progression) is offered as an option for the director, not applied

### Case 5: Context pass — designing to address a player retention drop-off
**Input context**: Analytics show a 40% player drop-off at Day 7, attributed to players completing the tutorial but finding no mid-term goal to pursue.
**Input**: "Design a live ops feature to address the Day 7 drop-off."
**Expected behavior**:
- Designs for the Day 7 cohort named in the data — not a generic retention feature — and does not re-ask for the drop-off data it was given
- The feature is visible and active at or before Day 7 and supplies the missing mid-term goal (a visible progression track with rewards spaced beyond Day 7)
- Defines success against the D7 retention point its Retention Mechanics already tracks (with D14 to confirm the effect holds), not a generic engagement metric
- Does NOT design a feature for Day 1 retention or Day 30 monetization when the data points to Day 7
- Leaves specific reward values to economy-designer

---

## Protocol Compliance

- [ ] Stays within declared domain (event structure, content cadence, retention design, battle pass design)
- [ ] Redirects reward value and economy math requests to economy-designer
- [ ] Flags predatory monetization patterns, offers a compliant option, and escalates to creative-director rather than implementing them silently
- [ ] Escalates event/core-progression conflicts to creative-director rather than resolving unilaterally
- [ ] Uses provided retention data to target specific player cohorts, not generic engagement strategies

---

## Coverage Notes
- Case 3 (monetization ethics) is a brand-safety test — failure here could result in harmful live ops designs shipping
- Case 4 (escalation behavior) is a coordination test — verify the agent actually escalates rather than deciding independently
- Case 5 is the most important context-awareness test; agent must target the specific drop-off point, not a generic solution
- No automated runner; review manually or via `/skill-test`
