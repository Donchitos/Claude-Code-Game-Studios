# Difficulty Curve: [Game Title]

> **Status**: Draft | In Review | Approved
> **Author**: [game-designer / systems-designer]
> **Last Updated**: [Date]
> **Links To**: `design/gdd/game-concept.md`
> **Relevant GDDs**: [e.g., `design/gdd/combat.md`, `design/gdd/progression.md`]

---

## Difficulty Philosophy

[One paragraph establishing this game's relationship with difficulty. This is
not a mechanical description — it is a design value statement that all tuning
decisions must serve.

The four common difficulty philosophies are:

1. **Masochistic challenge as the core fantasy**: Difficulty is the product.
   Overcoming it is the emotional reward. Reducing difficulty removes the
   point. (Dark Souls, Celeste at max assist off)
2. **Accessible entry, optional depth**: The base experience is completable by
   most players; depth and challenge are opt-in for those who want them.
   (Hades, Hollow Knight with accessibility modes)
3. **Difficulty serves narrative pacing**: Challenge rises and falls to match
   story beats. The player must feel capable during story resolution and
   threatened during story crisis. (The Last of Us, God of War)
4. **Relaxed engagement**: Challenge is present but never the focus. Failure
   is gentle and infrequent. The experience prioritizes comfort and expression
   over obstacle. (Stardew Valley, Animal Crossing)

State the philosophy explicitly, then add one sentence on what the player is
permitted to feel: are they allowed to feel frustrated? For how long before the
design must intervene? What is the acceptable cost of failure?]

---

## Difficulty Axes

> **Guidance**: Most games have multiple independent dimensions of challenge.
> Identifying them explicitly prevents the mistake of tuning only one axis
> (usually execution difficulty) while leaving others unexamined. A game can
> feel "easy" on execution but overwhelming on decision complexity — players
> experience this as confusing, not engaging.
>
> For each axis, answer: can the player control or reduce this axis through
> choices, builds, or settings? If not, it is a forced challenge dimension —
> be very intentional about how it is used.

| Axis | Description | Primary Systems | Player Control? |
|------|-------------|----------------|-----------------|
| **Execution difficulty** | [The precision and timing demands of core actions. e.g., "Dodging enemy attacks requires correct timing within a 200ms window."] | [e.g., Combat, movement] | [Yes — practice reduces this / No — fixed mechanical threshold] |
| **Knowledge difficulty** | [The cost of not knowing information. e.g., "Enemy weaknesses are not telegraphed; players who have not discovered them take significantly more damage."] | [e.g., Enemy design, UI, lore] | [Yes — through in-game discovery / No — requires external knowledge] |
| **Resource pressure** | [How scarce are the resources needed to progress? e.g., "Health consumables are limited; efficient play is required to sustain long dungeon runs."] | [e.g., Economy, loot, crafting] | [Yes — through build optimization / Partially] |
| **Time pressure** | [Does the player have time to think, or does the game demand rapid decisions? e.g., "Enemy spawn timers and attack windows require real-time response."] | [e.g., Combat pacing, timers] | [Yes — through difficulty settings / No — core to genre] |
| **Decision complexity** | [How many meaningful choices must the player evaluate simultaneously? e.g., "Build decisions interact across 4 systems; suboptimal combinations create compounding disadvantage."] | [e.g., Progression, inventory, skills] | [Yes — through UI and tutorialization / No — inherent to strategy depth] |
| **[Add axis]** | [Description] | [Systems] | [Player control] |

---

## Difficulty Curve Overview

> **Guidance**: This table describes the intended challenge arc across the whole
> game. Difficulty levels use a 1-10 scale where 1 = no meaningful challenge,
> 10 = maximum challenge the game can produce. The scale is relative to THIS game's
> design intent — a 6/10 in a soulslike is not the same as a 6/10 in a cozy sim.
>
> "Primary challenge type" refers to the difficulty axis (from the table above)
> that is doing the most work in this phase. New systems introduced should list
> only systems introduced for the FIRST TIME — the cognitive load of learning
> a new system is itself a form of difficulty.
>
> "Target player state" is the emotional state the designer intends. If the actual
> playtested state diverges from the intended state, this column is what needs
> to be achieved.

| Phase | Duration | Difficulty Level (1-10) | Primary Challenge Type | New Systems Introduced | Target Player State |
|-------|----------|------------------------|----------------------|----------------------|---------------------|
| [Prologue / Tutorial] | [e.g., 0-15 min] | [2/10] | [Knowledge] | [Core movement, basic interaction] | [Safe, curious, building confidence] |
| [Early game] | [e.g., 15 min - 2 hrs] | [3-5/10] | [Execution] | [Combat, inventory, first upgrade path] | [Learning, occasional failure, clear cause-effect] |
| [Mid game - opening] | [e.g., 2-6 hrs] | [5-7/10] | [Decision complexity] | [Build choices, advanced enemies, crafting] | [Engaged, strategizing, feeling growth] |
| [Mid game - depth] | [e.g., 6-15 hrs] | [6-8/10] | [Resource pressure] | [Elite enemies, optional hard content, endgame previews] | [Challenged, invested, approaching mastery] |
| [Late game] | [e.g., 15-25 hrs] | [7-9/10] | [Execution + knowledge] | [Endgame systems, NG+ or equivalent] | [Mastery, confident in build identity, seeking peak challenge] |
| [Optional / Endgame] | [e.g., 25+ hrs] | [8-10/10] | [All axes combined] | [Mastery challenges, achievement targets] | [Expert play, self-imposed goals, community comparison] |

---

## Onboarding Ramp

> **Guidance**: The first hour deserves its own detailed breakdown because it
> does the most difficult design work: it must teach every foundational skill
> without feeling like a lesson, and it must create enough investment that the
> player commits to the journey ahead. Research on player retention shows that
> most players who leave a game do so in the first 30 minutes — not because
> the game is bad, but because onboarding failed to connect them.
>
> The scaffolding principle (Vygotsky's Zone of Proximal Development, adapted
> for game design): introduce each mechanic in isolation before combining it
> with others. A player cannot learn two skills simultaneously under pressure.

### What the Player Knows at Each Stage

| Time | What the Player Knows | What They Do Not Know Yet |
|------|-----------------------|--------------------------|
| [0 min] | [Literally nothing — treat this row as your most important UX audit. What can a player infer from the title screen alone?] | [Everything] |
| [5 min] | [Core movement verb, basic world reading] | [All progression systems, all secondary mechanics] |
| [15 min] | [Core interaction loop, first goal] | [Build depth, advanced mechanics, danger severity] |
| [30 min] | [Has made at least one strategic choice] | [Whether that choice was optimal] |
| [60 min] | [Has a working model of the core loop] | [Late-game depth, optional systems] |

### Mechanic Introduction Sequence

> The order mechanics are introduced is a design decision with real consequences.
> Introduce the most essential verb first. Introduce mechanics that modify other
> mechanics AFTER the base mechanic is internalized. Never introduce two new
> mechanics in the same encounter.

| Mechanic | Introduced At | Introduction Method | Stakes at Introduction |
|----------|--------------|--------------------|-----------------------|
| [Core movement / primary verb] | [e.g., First 30 seconds] | [Tutorial prompt / environmental design / NPC instruction] | [None — safe space to experiment] |
| [Primary interaction / action] | [e.g., First 2 minutes] | [Method] | [Low — reversible, forgiving window] |
| [First resource mechanic] | [e.g., 5 min] | [Method] | [Low — abundant at introduction] |
| [First strategic choice] | [e.g., 15 min] | [Method] | [Low — choice can be changed or revisited] |
| [First real failure risk] | [e.g., 20-30 min] | [Method] | [Moderate — player should feel genuine threat but have fair tools to respond] |
| [Add mechanic] | [Timing] | [Method] | [Stakes] |

### The First Failure

[Describe the intended design of the first moment the player can meaningfully
fail. This is one of the most important beats in the game.

A well-designed first failure teaches rather than punishes. The player should
be able to immediately identify what they did wrong and what they would do
differently. If the cause of failure is ambiguous, the player blames the game.

Answer: What causes the first failure? What does the player learn from it?
How quickly can they retry? What is the cost? Does the game provide any
feedback that bridges cause and effect?]

### When the Player First Feels Competent

[Identify the specific moment — not a vague window, but a specific beat —
where the player should shift from "learning" to "doing." This is the moment
of first competence: the first time their prediction about the game comes true,
or the first time they execute a plan and it works.

This moment must happen within the first hour. If it does not, the player
will not reach Phase 3 of the journey (First Mastery). Design this moment
deliberately — do not leave it to chance.

What is the moment? What systems create it? What does the player do to
trigger it? How does the game communicate that they have succeeded?]

---

## Difficulty Spikes and Valleys

> **Guidance**: A healthy difficulty curve follows a sawtooth pattern
> (Csikszentmihalyi's flow model applied to macro-structure): tension builds
> through a sequence, then releases at a milestone, then re-engages at a
> slightly higher baseline. Flat difficulty creates boredom; uninterrupted
> escalation creates fatigue.
>
> Spikes are intentional peaks that test accumulated skills. Valleys are
> intentional troughs that give the player space to breathe, experiment, and
> feel powerful before the next escalation. Both are designed, not emergent.
>
> "Recovery design" is critical: what happens immediately after a spike? The
> player should exit a hard moment feeling accomplished, not depleted. Give
> them a valley, a reward, or a narrative payoff.

| Name | Location in Game | Type | Purpose | Recovery Design |
|------|-----------------|------|---------|-----------------|
| [e.g., "The First Boss"] | [e.g., End of Area 1, ~1 hr] | [Spike] | [Tests all skills introduced in Area 1. Acts as a gate confirming the player is ready for increased complexity.] | [Post-boss: safe area, upgrade opportunity, story beat that provides emotional relief before Area 2 escalation begins.] |
| [e.g., "The Safe Zone"] | [e.g., Hub area between Areas 1 and 2, ~1.5 hrs] | [Valley] | [Player feels powerful from boss win. Space to experiment with build options before stakes rise.] | [N/A — this IS the recovery from the preceding spike.] |
| [e.g., "The Knowledge Wall"] | [e.g., Area 3 first encounter, ~4 hrs] | [Spike — knowledge type] | [Forces players to engage with a mechanic they may have been avoiding. Survival requires understanding it.] | [Clear feedback on what killed them. Tutorial hint surfaces on third failure. Mechanic becomes standard after this point.] |
| [e.g., "Pre-Climax Valley"] | [e.g., Just before final act, ~20 hrs] | [Valley] | [Emotional breathing room before the final escalation. Player reflects on how far they have come.] | [N/A — designed as relief before the finale's spike.] |
| [Add spike/valley] | [Location] | [Type] | [Purpose] | [Recovery] |

---

## Balancing Levers

> **Guidance**: Balancing levers are the specific values and parameters that
> tune difficulty at each phase. Centralizing them here makes it possible to
> tune the whole-game difficulty curve without hunting through individual GDDs.
> For each lever, the GDD that owns it should be cross-referenced.
>
> "Current setting" is the design intent at the time of writing — implementation
> values live in `assets/data/`. The tuning range is the safe operating range:
> values outside this range reliably break the intended experience.

| Lever | Phase(s) | Effect | Current Setting | Tuning Range | Notes |
|-------|----------|--------|----------------|-------------|-------|
| [Enemy health multiplier] | [All] | [Higher = longer fights = more resource pressure and execution time] | [1.0x] | [0.7x - 1.5x] | [Below 0.7x, fights end before player can read enemy patterns. Above 1.5x, attrition replaces skill.] |
| [Enemy aggression timer] | [Mid game onward] | [Time between enemy attacks; lower = less time to react] | [e.g., 2.0s] | [1.2s - 3.0s] | [Below 1.2s, reaction window is sub-human. Above 3.0s, encounters feel passive.] |
| [Resource drop rate] | [Early game] | [Lower = more resource pressure = punishes inefficiency harder] | [e.g., 1.5x baseline] | [0.8x - 2.0x] | [Onboarding generosity; reduces in mid-game as player skill assumed.] |
| [New mechanic introduction density] | [First hour] | [How many new concepts per minute of play; too high = cognitive overload] | [e.g., 1 new mechanic per 8 min] | [1 per 5 min (max) to 1 per 15 min (slow)] | [Above 1 per 5 min in early game causes retention drop. Below 1 per 15 min causes boredom.] |
| [Failure cost] | [All] | [Time lost on failure; higher = more punishing = more tension] | [e.g., 2 min setback] | [30s - 8 min] | [Must scale with encounter frequency. Frequent failures need fast recovery.] |
| [Add lever] | [Phase] | [Effect] | [Setting] | [Range] | [Notes] |

---

## Player Skill Assumptions

> **Guidance**: Every game implicitly assumes players develop a set of skills
> over the course of play. Making these assumptions explicit allows the team to
> verify that each skill is actually taught before it is tested, and that the
> gap between "introduced" and "tested hard" is long enough for internalization.
>
> A skill introduced and tested in the same encounter is a surprise difficulty
> spike. A skill assumed but never formally introduced is an undocumented knowledge
> wall. Both are fixable — but only if they are documented.
>
> "Taught by" refers to the mechanism: tutorial prompt, environmental design,
> safe practice opportunity, NPC instruction, or organic discovery.
>
> "Tested by" refers to the first encounter that REQUIRES this skill to survive
> without taking significant damage or cost.

| Skill | Introduced In | Expected Mastered By | Taught By | First Hard Test |
|-------|--------------|---------------------|-----------|-----------------|
| [Core movement / dodging] | [Tutorial area, 0-5 min] | [End of Area 1, ~1 hr] | [Safe practice zone with visible hazards] | [First Elite enemy, ~45 min] |
| [Resource management] | [First shop encounter, ~10 min] | [Mid game, ~4 hrs] | [Resource scarcity in Area 2 forces planning] | [Boss that requires consumables to survive efficiently] |
| [Build decision-making] | [First upgrade choice, ~20 min] | [End of mid game, ~10 hrs] | [Multiple playthroughs / community discussion / in-game build advisor] | [Endgame encounters that punish build incoherence] |
| [Enemy pattern reading] | [Area 1 basic enemies] | [Area 3, ~4 hrs] | [Enemy telegraphs visible and consistent from introduction] | [Elite enemy with 3+ distinct attack patterns] |
| [Add skill] | [When introduced] | [When mastered] | [Taught by] | [First hard test] |

---

## Accessibility Considerations

> **Guidance**: Accessibility in difficulty design is not about making the game
> easier — it is about ensuring players with different needs and skill profiles
> can reach the intended emotional experience. Be explicit about what CAN be
> adjusted and what CANNOT, and justify both.
>
> The principle from Self-Determination Theory: players need to feel competent.
> Accessibility options that help players feel competent without removing the
> feeling of agency are always worth including. Options that make competence
> meaningless undermine the core experience.

### What Can Be Adjusted

| Adjustment | Method | Effect on Experience | Tradeoff |
|-----------|--------|---------------------|----------|
| [e.g., Enemy speed reduction] | [Difficulty setting / accessibility menu] | [Lowers execution difficulty without changing knowledge or decision requirements] | [Reduces the tension of combat timing; acceptable for narrative players] |
| [e.g., Extended input windows] | [Accessibility menu] | [Allows players with motor impairments to achieve the same skill outcomes with more time] | [Minimal — skill expression preserved, threshold relaxed] |
| [e.g., Hint frequency] | [Settings toggle] | [Surfaces contextual guidance more or less aggressively based on player preference] | [Higher hints reduce knowledge difficulty; players who want to discover organically may feel over-guided] |
| [Add option] | [Method] | [Effect] | [Tradeoff] |

### What Cannot Be Adjusted (and Why)

| Fixed Element | Why It Cannot Change | Design Reasoning |
|--------------|---------------------|-----------------|
| [e.g., Permadeath in roguelike run] | [Removing it eliminates the resource pressure axis that all encounter balance is built around] | [The weight of each decision comes from permanence; without it, the core loop loses meaning] |
| [e.g., Core narrative pacing] | [Difficulty valleys are timed to story beats; adjustable pacing would decouple challenge from narrative intention] | [Story and difficulty are designed as one arc, not two independent tracks] |
| [Add fixed element] | [Why] | [Reasoning] |

---

## Cross-System Difficulty Interactions

> **Guidance**: When two systems operate simultaneously, their combined
> difficulty is often greater than the sum of their parts — or sometimes
> less. These interactions are frequently unintended and only surface during
> playtesting. Documenting anticipated interactions here creates a checklist
> for QA and playtest sessions.
>
> "Is this intended?" Yes means the interaction is a designed feature.
> No means it should be mitigated. Partial means the interaction is
> acceptable in small doses but problematic if it becomes the dominant
> experience.

| System A | System B | Combined Effect | Intended? |
|----------|----------|----------------|-----------|
| [Combat difficulty] | [Resource scarcity] | [Resource-poor players face combat encounters with fewer options, compounding difficulty for players already struggling. Can create a death spiral where failing creates worse conditions.] | [Partial — intended as stakes, not as a trap. Pity mechanics required to prevent unrecoverable states.] |
| [Build complexity] | [Time pressure] | [Players who are still learning their build take longer to make decisions under time pressure, increasing cognitive load beyond the intended challenge of either system alone.] | [No — reduce decision complexity demand in high time-pressure encounters.] |
| [New mechanic introduction] | [Resource pressure] | [Introducing a new system while the player is already under resource pressure forces them to learn and optimize simultaneously.] | [No — new mechanics should be introduced in low-resource-pressure environments.] |
| [Enemy density] | [Execution difficulty] | [High enemy counts with individually demanding enemies produce difficulty that scales exponentially, not linearly.] | [Partial — intended for optional challenge content only; not acceptable on the critical path.] |
| [Add System A] | [Add System B] | [Combined effect description] | [Yes / No / Partial] |

---

## Validation Checklist

> **Guidance**: These checkpoints structure playtesting sessions to verify
> the difficulty curve is achieving its intent. Each item should be checked
> with at least 3 playtester sessions before being marked complete. Note the
> playtester profile that revealed issues — difficulty problems are almost
> always player-profile-specific.

### Onboarding (0-30 min)
- [ ] Players with no prior genre experience complete the tutorial area without external help
- [ ] Zero players cite confusion about what they are supposed to be doing in the first 5 minutes
- [ ] At least one playtester spontaneously says "I want to see what's next" within 15 minutes
- [ ] First failure moment produces a visible learning response (player verbalizes what went wrong)

### Early Game (30 min - 2 hrs)
- [ ] Average player reaches the first competence moment within 60 minutes
- [ ] First major encounter (boss or equivalent) is passed within 3-5 attempts on average
- [ ] No player cites a mechanic introduced "too suddenly without warning"
- [ ] Players can describe their current goal without prompting

### Mid Game (2-10 hrs)
- [ ] Players discover at least one depth mechanic through organic play (without guide)
- [ ] Playtest sessions report "I want to try a different build / strategy next run"
- [ ] No single difficulty axis dominates player complaints — frustration is distributed
- [ ] Players who fail a mid-game encounter correctly identify the cause without being told

### Late Game (10+ hrs)
- [ ] Players report the final challenge feels like a culmination of everything they have learned
- [ ] Failure at late-game content does not feel unfair (even if it is hard)
- [ ] Players who complete the main content express a reason to continue playing

### Accessibility
- [ ] All listed accessibility options function without breaking encounter intent
- [ ] Players using accessibility settings report feeling competent, not patronized
- [ ] Fixed difficulty elements are encountered and accepted without negative reception from accessibility playtesters

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Is the onboarding ramp correctly calibrated for players without prior genre experience?] | [game-designer] | [Date] | [Unresolved — schedule genre-naive playtester sessions] |
| [Does the first boss represent the correct difficulty spike or is it a wall?] | [game-designer, systems-designer] | [Date] | [Unresolved — requires 5+ playtester sessions to establish average attempt count] |
| [Do any cross-system interactions produce unrecoverable states?] | [systems-designer] | [Date] | [Unresolved — requires targeted playtest with resource-constrained starting conditions] |
| [Add question] | [Owner] | [Date] | [Resolution] |
