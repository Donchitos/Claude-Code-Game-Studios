# [Mechanic/System Name]

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Agent or person]
> **Last Updated**: [Date]
> **Last Verified**: [Date — when this doc was last confirmed accurate against current design]
> **Implements Pillar**: [Which game pillar this supports]

## Summary

[2–3 sentences: what this system is, what it does for the player, and why it
exists in this game. Written for tiered context loading — a skill scanning
20 GDDs uses this section to decide whether to read further. No jargon.]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Alpha | Full Vision]` · Key deps: `[System names or "None"]`

## Overview

[One paragraph that explains this mechanic to someone who knows nothing about
the project. What is it, what does the player do, and why does it exist?]

## Player Fantasy

[What should the player FEEL when engaging with this mechanic? What is the
emotional or power fantasy being served? This section guides all detail
decisions below.]

## Detailed Design

### Core Rules

[Precise, unambiguous rules. A programmer should be able to implement this
section without asking questions. Use numbered rules for sequential processes
and bullet points for properties.]

### States and Transitions

[If this system has states (e.g., weapon states, status effects, phases),
document every state and every valid transition between states.]

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|

### Interactions with Other Systems

[How does this system interact with combat? Inventory? Progression? UI?
For each interaction, specify the interface: what data flows in, what flows
out, and who is responsible for what.]

## Formulas

[Every mathematical formula used by this system. For each formula:]

### [Formula Name]

```
result = base_value * (1 + modifier_sum) * scaling_factor
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_value | float | 1-100 | data file | The base amount before modifiers |
| modifier_sum | float | -0.9 to 5.0 | calculated | Sum of all active modifiers |
| scaling_factor | float | 0.5-2.0 | data file | Level-based scaling |

**Expected output range**: [min] to [max]
**Edge case**: When modifier_sum < -0.9, clamp to -0.9 to prevent negative results.

## Edge Cases

[Explicitly document what happens in unusual situations. Each edge case
should have a clear resolution.]

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| [What if X is zero?] | [This happens] | [Because of this reason] |
| [What if both effects trigger?] | [Priority rule] | [Design reasoning] |

## Dependencies

[List every system this mechanic depends on or that depends on this mechanic.]

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| [Combat] | This depends on Combat | Needs damage calculation results |
| [Inventory] | Inventory depends on this | Provides item effect data |

## Tuning Knobs

[Every value that should be adjustable for balancing. Include the current
value, the safe range, and what happens at the extremes.]

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|

## Visual/Audio Requirements

[What visual and audio feedback does this mechanic need?]

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|

## Game Feel

> **Why this section exists separately from Visual/Audio Requirements**: Visual/Audio
> Requirements document WHAT feedback events occur (tables of events mapped to assets).
> Game Feel documents HOW the mechanic feels to operate — the responsiveness, weight,
> snap, and kinesthetic quality of the interaction. These are design targets for timing,
> frame data, and physical sensation of control. Game feel must be specified at design
> time because it drives animation budgets, input handling architecture, and hitbox
> timing. Retrofitting feel targets after implementation is expensive and often requires
> fundamental rework.

### Feel Reference

[Name a specific game, mechanic, or moment that captures the target feel. Be precise —
cite the exact mechanic, not just the game. Explain what quality you are borrowing.
Optionally include an anti-reference (what this should NOT feel like).]

> Example: "Should feel like Dark Souls weapon swings — weighty, committed, and
> telegraphed, but satisfying on contact. NOT floaty like early Halo melee."

### Input Responsiveness

[Maximum acceptable latency from player input to visible/audible response, per action.]

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|------------------------|-------|
| [Primary action] | [e.g., 50ms] | [e.g., 3 frames] | |
| [Secondary action] | | | |

### Animation Feel Targets

[Frame data targets for each animation in this mechanic. Startup = windup before the
action has any effect. Active = frames when the action is "happening" (hitbox live,
ability firing, etc.). Recovery = committed/vulnerable frames after the action resolves.]

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| [e.g., Light attack] | | | | [e.g., Snappy, low commitment] | |
| [e.g., Heavy attack] | | | | [e.g., Weighty, high commitment] | |

### Impact Moments

[Defines the punctuation of the mechanic — the moments of peak feedback intensity that
make actions feel consequential. Every high-stakes event should have at least one entry.]

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Hit-stop (freeze frames) | [e.g., 80ms] | [Freeze both objects on contact] | Yes |
| Screen shake | [e.g., 150ms] | [Directional, decaying] | Yes |
| Camera impact | | | |
| Controller rumble | | | |
| Time-scale slowdown | | | |

### Weight and Responsiveness Profile

[A short prose description of the overall feel target. Answer the following:]

- **Weight**: Does this feel heavy and deliberate, or light and reactive?
- **Player control**: How much does the player feel in control at every moment?
  (High control = can course-correct mid-action; Low control = committed, momentum-based)
- **Snap quality**: Does this feel crisp and binary, or smooth and analog?
- **Acceleration model**: Does movement/action start instantly (arcade feel) or
  ramp up from zero (simulation feel)? Same question for deceleration.
- **Failure texture**: When the player makes an error, does the mechanic feel fair
  or punishing? What is the read on WHY they failed?

### Feel Acceptance Criteria

[Specific, testable criteria a playtester can verify without measurement instruments.
These are subjective targets stated precisely enough to get consistent verdicts.]

- [ ] [e.g., "Combat feels impactful — playtesters comment on weight unprompted"]
- [ ] [e.g., "No reviewer uses the words 'floaty', 'slippery', or 'unresponsive'"]
- [ ] [e.g., "Input latency is imperceptible at target 60fps framerate"]
- [ ] [e.g., "Hit-stop reads as satisfying, not as lag or stutter"]

## UI Requirements

[What information needs to be displayed to the player and when?]

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|

## Cross-References

[Declare every explicit dependency on another GDD's specific mechanic, value, or
rule. This table is machine-checked by `$review-all-gdds` Phase 2c — it replaces
implicit prose references with verifiable declarations. If you reference another
system's behaviour anywhere in this document, it must appear here.]

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| [e.g., "combo multiplier feeds score"] | `design/gdd/score.md` | `combo_multiplier` output value | Data dependency |
| [e.g., "death triggers respawn"] | `design/gdd/respawn.md` | Death state transition | State trigger |
| [e.g., "stamina gates dodge"] | `design/gdd/stamina.md` | Stamina depletion rule | Rule dependency |

> **Note on "Nature"**: use one of — `Data dependency` (we consume their output),
> `State trigger` (their state change triggers our behaviour), `Rule dependency`
> (our rule assumes their rule is also true), `Ownership handoff` (we hand off
> ownership of a value to them).

## Acceptance Criteria

[Testable criteria that confirm this mechanic is working as designed.]

- [ ] [Criterion 1: specific, measurable, testable]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] Performance: System update completes within [X]ms
- [ ] No hardcoded values in implementation

## Open Questions

[Anything not yet decided. Each question should have an owner and deadline.]

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
