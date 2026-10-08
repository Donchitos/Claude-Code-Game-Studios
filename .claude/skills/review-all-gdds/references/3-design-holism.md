# /review-all-gdds — Phase 3: Game Design Holism

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Game Design Holism

**In this file:**

- 3a: Progression Loop Competition
- 3b: Player Attention Budget
- 3c: Dominant Strategy Detection
- 3d: Economic Loop Analysis
- 3e: Difficulty Curve Consistency
- 3f: Pillar Alignment
- 3g: Player Fantasy Coherence

Review all GDDs together through the lens of game design theory and player
psychology. These are issues that individual GDD reviews cannot catch because
they require seeing all systems at once.

### 3a: Progression Loop Competition

A game should have one dominant progression loop that players feel is "the
point" of the game, with supporting loops that feed into it. When multiple
systems compete equally as the primary progression driver, players don't know
what the game is about.

Scan all GDDs for systems that:
- Award the player's primary resource (XP, levels, prestige, unlocks)
- Define themselves as the "core" or "main" loop
- Have comparable depth and time investment to other systems doing the same

```
⚠️  Competing Progression Loops
combat.md: Awards XP, unlocks abilities, is described as "the core loop"
crafting.md: Awards XP, unlocks recipes, is described as "the primary activity"
exploration.md: Awards XP, unlocks map areas, described as "the main driver"
→ Three systems all claim to be the primary progression loop and all award
  the same primary currency. Players will optimise one and ignore the others.
  Consider: one primary loop with the others as support systems.
```

### 3b: Player Attention Budget

Count how many systems require active player attention simultaneously during
a typical session. Each actively-managed system costs attention:

- Active = player must make decisions about this system regularly during play
- Passive = system runs automatically, player sees results but doesn't manage it

More than 3-4 simultaneously active systems creates cognitive overload for most
players. Present the count and flag if it exceeds 4 concurrent active systems:

```
⚠️  Cognitive Load Risk
Simultaneously active systems during [core loop moment]:
  1. [system-a].md — [decision type] (active)
  2. [system-b].md — [resource management] (active)
  3. [system-c].md — [tracking] (active)
  4. [system-d].md — [item/action use] (active)
  5. [system-e].md — [cooldown/timer management] (active)
  6. [system-f].md — [coordination decisions] (active)
→ 6 simultaneously active systems during the core loop.
  Research suggests 3-4 is the comfortable limit for most players.
  Consider: which of these can be made passive or simplified?
```

### 3c: Dominant Strategy Detection

A dominant strategy makes other strategies irrelevant — players discover it,
use it exclusively, and find the rest of the game boring. Look for:

- **Resource monopolies**: One strategy generates a resource significantly
  faster than all others
- **Risk-free power**: A strategy that is both high-reward and low-risk
  (if high-risk strategies exist, they need proportionally higher reward)
- **No trade-offs**: An option that is superior in all dimensions to all others
- **Obvious optimal path**: If any progression choice is "clearly correct",
  the others aren't real choices

```
⚠️  Potential Dominant Strategy
combat.md: Ranged attacks deal 80% of melee damage with no risk
combat.md: Melee attacks deal 100% damage but require close range
→ Unless melee has a significant compensating advantage (AOE, stagger,
  resource regeneration), ranged is dominant — higher safety, only 20% less
  damage. Consider what melee offers that ranged cannot.
```

### 3d: Economic Loop Analysis

Identify all resources across all GDDs (gold, XP, crafting materials, stamina,
health, mana, etc.). For each resource, map its **sources** (how players gain
it) and **sinks** (how players spend it).

Flag dangerous economic conditions:

| Condition | Sign | Risk |
|-----------|------|------|
| **Infinite source, no sink** | Resource accumulates indefinitely | Late game becomes trivially easy |
| **Sink, no source** | Resource drains to zero | System becomes unavailable |
| **Source >> Sink** | Surplus accumulates | Resource becomes meaningless |
| **Sink >> Source** | Constant scarcity | Frustration and gatekeeping |
| **Positive feedback loop** | More resource → easier to earn more | Runaway leader, snowball |
| **No catch-up** | Falling behind accelerates deficit | Unrecoverable states |

```
🔴 Economic Imbalance: Unbounded Positive Feedback
gold economy:
  Sources: monster drops (scales with player power), merchant selling (unlimited)
  Sinks: equipment purchase (one-time), ability upgrades (finite count)
→ After equipment and abilities are purchased, gold has no sink.
  Infinite surplus. Gold becomes meaningless mid-game.
  Add ongoing gold sinks (upkeep, consumables, cosmetics, gambling).
```

### 3e: Difficulty Curve Consistency

When multiple systems scale with player progression, they must scale in
compatible directions and at compatible rates. Mismatched scaling curves
create unintended difficulty spikes or trivialisations.

For each system that scales over time, extract:
- What scales (enemy health, player damage, resource cost, area size)
- How it scales (linear, exponential, stepped)
- When it scales (level, time, area)

Compare all scaling curves. Flag mismatches:

```
⚠️  Difficulty Curve Mismatch
combat.md: Enemy health scales exponentially with area (×2 per area)
progression.md: Player damage scales linearly with level (+10% per level)
→ By area 5, enemies have 32× base health; player deals ~1.5× base damage.
  The gap widens indefinitely. Late areas will become inaccessibly difficult
  unless the curves are reconciled.
```

### 3f: Pillar Alignment

Every system should clearly serve at least one design pillar. A system that
serves no pillar is "scope creep by design" — it's in the game but not in
service of what the game is trying to be.

For each GDD system, check its Player Fantasy section against the design pillars.
Flag any system whose stated fantasy doesn't map to any pillar:

```
⚠️  Pillar Drift
fishing-system.md: Player Fantasy — "peaceful, meditative activity"
Pillars: "Brutal Combat", "Tense Survival", "Emergent Stories"
→ The fishing system serves none of the three pillars. Either add a pillar
  that covers it, redesign it to serve an existing pillar, or cut it.
```

Also check anti-pillars — flag any system that does what an anti-pillar
explicitly says the game will NOT do:

```
🔴 Anti-Pillar Violation
Anti-Pillar: "We will NOT have linear story progression — player defines their path"
main-quest.md: Defines a 12-chapter linear story with mandatory sequence
→ This system directly violates the defined anti-pillar.
```

### 3g: Player Fantasy Coherence

The player fantasies across all systems should be compatible — they should
reinforce a consistent identity for what the player IS in this game. Conflicting
player fantasies create identity confusion.

```
⚠️  Player Fantasy Conflict
combat.md: "You are a ruthless, precise warrior — every kill is earned"
dialogue.md: "You are a charismatic diplomat — violence is always avoidable"
exploration.md: "You are a reckless adventurer — diving in without a plan"
→ Three systems present incompatible identities. Players will feel the game
  doesn't know what it wants them to be. Consider: do these fantasies serve
  the same core identity from different angles, or do they genuinely conflict?
```

---
