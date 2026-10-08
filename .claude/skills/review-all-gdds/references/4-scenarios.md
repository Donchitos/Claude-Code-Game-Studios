# /review-all-gdds — Phase 4: Cross-System Scenario Walkthrough

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Cross-System Scenario Walkthrough

Walk through the game from the player's perspective to find problems that only
appear at the interaction boundary between multiple systems — things static
analysis of individual GDDs cannot surface.

### 4a: Identify Key Multi-System Moments

Scan all GDDs and identify the 3–5 most important player-facing moments where
multiple systems activate simultaneously. Look specifically for:

- **Combat + Economy overlap**: killing enemies that drop resources, spending
  resources during combat, death/respawn interacting with economy state
- **Progression + Difficulty overlap**: level-up triggering mid-fight, ability
  unlocks changing combat viability, difficulty scaling at progression milestones
- **Narrative + Gameplay overlap**: dialogue choices locking/unlocking mechanics,
  story beats interrupting resource loops, quest completion triggering system
  state changes
- **3+ system chains**: any player action that triggers System A, which feeds
  into System B, which triggers System C (these are highest-risk interaction paths)

List each identified scenario with a one-line description before proceeding.

### 4b: Walk Through Each Scenario

For each scenario, step through the sequence explicitly:

1. **Trigger** — what player action or game event starts this?
2. **Activation order** — which systems activate, in what sequence?
3. **Data flow** — what does each system output, and is that output a valid
   input for the next system in the chain?
4. **Player experience** — what does the player see, hear, or feel at each step?
5. **Failure modes** — are there any of the following?
   - **Race conditions**: two systems trying to modify the same state simultaneously
   - **Feedback loops**: System A amplifies System B which re-amplifies System A
     with no cap or dampener
   - **Broken state transitions**: a system assumes a state that a previous
     system may have changed (e.g., "player is alive" assumption after a combat
     step that could have caused death)
   - **Contradictory messaging**: player receives conflicting feedback from two
     systems reacting to the same event (e.g., "success" sound + "failure" UI)
   - **Compounding difficulty spikes**: two systems both scaling up at the same
     progression point, multiplying the intended difficulty increase
   - **Reward conflicts**: two systems both reacting to the same trigger with
     rewards that together exceed the intended value (double-dipping)
   - **Undefined behavior**: the GDDs don't specify what happens in this combined
     state (neither system's rules cover it)

```
Example walkthrough:
Scenario: Player kills elite enemy at level-up threshold during active quest

Trigger: Player lands killing blow on elite enemy
→ combat.md: awards kill XP (100 pts)
→ progression.md: XP total crosses level threshold → triggers level-up
  Output: new level, stat increases, ability unlock popup
→ quest.md: kill-count criterion met → triggers quest completion event
  Output: quest reward XP (500 pts), completion fanfare
→ progression.md (again): quest XP added → triggers SECOND level-up in same frame
  ⚠️  Data flow issue: quest.md awards XP without checking if a level-up
  is already in progress. progression.md has no guard against concurrent
  level-up events. Undefined behavior: does the player level up once or twice?
  Does the ability popup fire twice? Does the second level use the updated or
  pre-update stat baseline?
```

### 4c: Flag Scenario Issues

For each problem found during the walkthrough, categorize severity:

- **BLOCKER**: undefined behavior, broken state transition, or contradictory
  player messaging — the experience is broken or incoherent in this scenario
- **WARNING**: compounding spikes, feedback loops without caps, reward conflicts —
  the experience works but produces unintended outcomes
- **INFO**: minor ordering ambiguity or messaging overlap — worth noting but
  unlikely to cause player-visible problems

Add all findings to the output report under **"Cross-System Scenario Issues"**.
Each finding must cite: the scenario name, the specific systems involved, the
step where the issue occurs, and the nature of the failure mode.

---
