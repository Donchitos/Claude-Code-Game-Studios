# Economy Model: [System Name]

*Created: [Date]*
*Owner: economy-designer*
*Status: [Draft / Balanced / Live]*

---

## Overview

[What resources, currencies, and exchange systems does this economy cover?
What player behaviors does it incentivize?]

---

## Currencies

| Currency | Type | Earn Rate | Sink Rate | Cap | Notes |
| ---- | ---- | ---- | ---- | ---- | ---- |
| [Gold] | Soft | [per hour] | [per hour] | [max or none] | [Primary transaction currency] |
| [Gems] | Premium | [per day F2P] | [varies] | [max] | [Premium currency, purchasable] |
| [XP] | Progression | [per action] | [level-up cost] | [none] | [Cannot be traded] |

### Currency Rules
- [Rule 1 — e.g., "Soft currency has no cap but inflation is controlled via sinks"]
- [Rule 2 — e.g., "Premium currency cannot be converted back to real money"]
- [Rule 3]

---

## Sources (Faucets)

| Source | Currency | Amount | Frequency | Conditions |
| ---- | ---- | ---- | ---- | ---- |
| [Quest completion] | Gold | [50-200] | [per quest] | [Scales with quest difficulty] |
| [Enemy drops] | Gold | [1-10] | [per kill] | [Modified by luck stat] |
| [Daily login] | Gems | [5] | [daily] | [Streak bonus: +1 per consecutive day] |
| [Achievement] | XP | [100-500] | [one-time] | [Per achievement tier] |

---

## Sinks (Drains)

| Sink | Currency | Cost | Frequency | Purpose |
| ---- | ---- | ---- | ---- | ---- |
| [Equipment purchase] | Gold | [100-5000] | [as needed] | [Power progression] |
| [Repair costs] | Gold | [10-100] | [per death] | [Death penalty, gold drain] |
| [Cosmetic shop] | Gems | [50-500] | [optional] | [Vanity, premium sink] |
| [Respec] | Gold | [1000] | [rare] | [Build experimentation tax] |

---

## Balance Targets

| Metric | Target | Rationale |
| ---- | ---- | ---- |
| Time to first meaningful purchase | [X minutes] | [Player should feel spending power early] |
| Hourly gold earn rate (mid-game) | [X gold/hr] | [Based on session length and purchase cadence] |
| Days to max level (F2P) | [X days] | [Enough to retain, not so long it frustrates] |
| Sink-to-source ratio | [0.7-0.9] | [Slight surplus keeps players feeling wealthy] |
| Premium currency F2P earn rate | [X/week] | [Enough to buy something monthly, not everything] |

---

## Progression Curves

### Level XP Requirements
| Level | XP Required | Cumulative XP | Estimated Time |
| ---- | ---- | ---- | ---- |
| 1→2 | [100] | [100] | [10 min] |
| 5→6 | [500] | [1,500] | [2 hrs] |
| 10→11 | [1,500] | [7,500] | [8 hrs] |
| 20→21 | [5,000] | [50,000] | [40 hrs] |

*Formula*: `XP(n) = [formula, e.g., 100 * n^1.5]`

### Item Price Scaling
*Formula*: `Price(tier) = [formula, e.g., base_price * 2^(tier-1)]`

---

## Loot Tables

### [Drop Source Name]
| Item | Rarity | Drop Rate | Pity Timer | Notes |
| ---- | ---- | ---- | ---- | ---- |
| [Common item] | Common | [60%] | [N/A] | [Always useful, never feels bad] |
| [Uncommon item] | Uncommon | [25%] | [N/A] | [Noticeable upgrade] |
| [Rare item] | Rare | [12%] | [10 drops] | [Exciting, build-defining] |
| [Legendary item] | Legendary | [3%] | [30 drops] | [Game-changing, celebration moment] |

### Pity System
[Describe how the pity system works to prevent extreme bad luck streaks.]

---

## Economy Health Metrics

| Metric | Healthy Range | Warning Threshold | Action if Breached |
| ---- | ---- | ---- | ---- |
| Average player gold | [X-Y at level Z] | [>Y or <X] | [Adjust faucets/sinks] |
| Gold Gini coefficient | [<0.4] | [>0.5] | [Wealth too concentrated] |
| % players hitting currency cap | [<5%] | [>10%] | [Raise cap or add sinks] |
| Premium conversion rate | [2-5%] | [<1% or >10%] | [Rebalance F2P earn rate] |
| Average time between purchases | [X minutes] | [>Y minutes] | [Nothing worth buying] |

---

## Ethical Guardrails

- [No pay-to-win: premium currency cannot buy gameplay power advantages]
- [Pity timers on all random drops: guaranteed outcome within X attempts]
- [Transparent drop rates displayed to players]
- [Spending limits for minor accounts]
- [No artificial scarcity pressure (FOMO timers) on essential items]

---

## Simulation Results

[Include results from economy simulations if available: player wealth
distribution over time, sink effectiveness, inflation rate, etc.]

---

## Dependencies

- Depends on: [combat balance, quest design, crafting system]
- Affects: [difficulty curve, player retention, monetization]
- Must coordinate with: `game-designer`, `live-ops-designer`, `analytics-engineer`
