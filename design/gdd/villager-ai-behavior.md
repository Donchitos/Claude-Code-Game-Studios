# Villager AI & Behavior

> **Status**: Approved (2026-07-10 — full review NEEDS REVISION -> revised -> re-review APPROVED; see design/gdd/reviews/villager-ai-behavior-review-log.md); Slice-revised 2026-07-23 (character scale, anti-stuck safety net, worker attribution — see prototypes/last-seal-vertical-slice/REPORT.md); Patched 2026-07-26 (Rule 15/F5 self-sealed watchdog scope carve-out — see production/qa/evidence/m01-closure-evidence-20260726.md)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-26
> **Last Verified**: 2026-07-09
> **Implements Pillar**: Pillar 2 — A settlement that feels alive (primary); Pillar 1 — The building IS the game (villagers construct and inhabit what the player builds)

## Summary

Villager AI & Behavior owns everything a villager *does*: perceiving the
world, choosing an activity (build, sleep, eat, wander), pathing to it, and
performing it. It is the labor half of the game's two central loops — it
consumes the Building System's construction-job queue to physically build
what the player plans, and it consumes needs (from the Needs & Mood System)
to make villagers live in what gets built. It runs on Time & Tick's game
time, reads Voxel World for physical occupancy, and is bounded by a
deliberate population ceiling of 20–30 concurrent villagers so every
villager can stay an individual with a name, a routine, and (later) a
story — never an anonymous crowd.

> **Quick reference** — Layer: `Core/Gameplay` · Priority: `MVP` · Key deps: `Voxel World, Time & Tick System` · Population ceiling: 20–30 (Full Vision)

## Overview

**Player-facing:** villagers are the game's proof of life (Pillar 2) and
the payoff of Pillar 1: the player never controls them directly — they are
the "unseen steward's" wards. The player builds; villagers claim the work,
walk to the site, hammer blocks into existence, then move into the finished
home, sleep in the bed, and visibly live a daily rhythm. Every emotion the
concept promises — pride, care, emergent stories — is delivered through
watching these agents behave believably. The 20–30 ceiling is a design
choice, not (only) a technical one: it keeps each villager legible as a
person, matching the concept's named-villager/diaries/bonds vision.

**System-facing:** this system is an agent runtime. Each villager is an
autonomous agent that repeatedly: evaluates available activities (a
construction job from the Building System's queue, a need to satisfy, an
idle behavior), commits to one, paths to its target through Voxel World's
physical occupancy, performs it over game ticks, and re-evaluates on
completion or interruption. This GDD owns activity selection, movement,
job-claim mechanics (confirming the Building System's provisional
contract), interruption/abandon semantics, and the villager's observable
day rhythm. It does NOT own: what needs exist and how they decay (Needs &
Mood System), whether a structure is livable (Build Validation &
Navigability), what jobs exist (Building System owns its queue), or combat
behavior (Squad & Combat, Vertical Slice+).

The MVP slice is deliberately tiny: ONE villager, ONE need (sleep), the
construction-job loop, and the move-into-home moment — exactly the
concept's MVP hypothesis ("watch a villager move in and live there").

## Player Fantasy

**"They live because of what I built — and they'd be lost without me."**

An indirect but central fantasy: the player never issues a command to a
villager, yet everything a villager does reflects the player's stewardship.
Three beats:

1. **Watching them work.** The wall I planned is being *built by someone* —
   a small figure walks over, hammers, and the block turns real. My intent
   passes through their hands (delivers the construction half of Pillar 1;
   the Building System's "construction has weight" feel claim is fulfilled
   HERE, by visible labor).
2. **Watching them live.** At dusk the villager stops working, walks home,
   and sleeps in the bed I placed. The settlement has a pulse that keeps
   beating when I'm not steering — the concept's core fantasy of
   "stewardship of a place that feels alive."
3. **Being needed.** When something is wrong — no bed, an unreachable
   build spot — the villager's visible state (wandering at night, orange
   pulsing ghost) tells me *I* am the one who can fix their world. Care,
   not control.

Reference feeling: Stonehearth's hearthlings and RimWorld's colonists —
autonomous wards whose visible routines create attachment. NOT the fantasy:
an RTS unit (no direct orders), a Sims puppet (no possession), or an
anonymous crowd sim (the 20–30 ceiling exists precisely so no villager is
ever "one of thousands").

> `creative-director` not consulted — Lean mode (non-high-risk section).
> Sourced from game-concept.md Core Fantasy ("unseen steward") + MDA table
> (Fellowship = between villagers, vicarious). Review manually before
> production.

## Detailed Design

### Core Rules

**Agent loop**

1. Every villager is an autonomous agent running one loop: **decide →
   travel → perform → re-evaluate**. Decisions and work progress happen on
   game tick events; visible movement interpolates continuously using game
   delta (so motion is smooth but stops dead while paused — consistent
   with Time & Tick's rules). [TR-villager-ai-behavior-048]
2. **Activity selection is a strict priority list** (MVP):
   1. Urgent need — a need below its urgency threshold (threshold values
      owned by the Needs & Mood GDD; MVP: sleep only)
   2. Work — an available construction job (Building System queue)
   3. Idle — wander near the settlement (never leaves the world bounds)
   The list is re-evaluated when an activity completes, when interrupted,
   and periodically every `decision_interval` ticks so an urgent need can
   preempt long work. [TR-villager-ai-behavior-049]
3. **Preemption is graceful, never abrupt**: when an urgent need preempts
   work, the villager finishes the current cell's in-progress tick, then
   releases its job claim back to the queue and pursues the need. This
   defines the "graceful abandon" the Building System's Edge Case 7
   references — from this side of the contract. [TR-villager-ai-behavior-050]

**Job claiming (confirms the Building System's Core Rule 12 contract)**

4. One job (one blueprint cell) per villager at a time. A villager
   selects the **nearest reachable available job** by path distance (the
   Building System's queue order is availability/tie-breaking only —
   proximity choice is explicitly allowed by that contract). Claiming
   locks the job; no other villager may claim it until released. [TR-villager-ai-behavior-051]
   **Claims are sticky**: the periodic re-evaluation (Rule 2) never
   re-runs job selection against a held claim — a claimed job is
   abandoned ONLY via need-preemption (Rule 3), revocation (Edge Case 4),
   or pathing failure (Rule 6). There is no job-vs-job re-selection
   mid-travel *(added by the 2026-07-10 review — without this clause, a
   traveling villager could oscillate between similar-distance jobs as
   the argmin flips)*. [TR-villager-ai-behavior-052] "Available" for the priority list (Rule 2) means
   queue-non-empty — reachability is discovered lazily at selection time
   (F2), never as a gate on the ranking itself. [TR-villager-ai-behavior-053]
   **Claim attribution** *(added by the 2026-07-23 slice revision)*: a
   successful claim records the claiming villager's id on the claim
   record. The Building System's project entity aggregates these ids
   into its `worker_ids` field for per-project attribution (e.g. its
   project window listing who is working a job) — this GDD supplies the
   id only; ownership of the aggregate field stays with the Building
   System (see Dependencies). [TR-villager-ai-behavior-097]
5. **On site** = the villager occupies the job's target cell or an
   orthogonally adjacent cell (including directly above/below), exactly as
   the Building System defines. Work progress accrues only while on site. [TR-villager-ai-behavior-054]
6. **Unreachable jobs**: if pathing to a job fails, the villager reports
   the failure to the Building System (which turns the ghost orange, its
   Edge Case 5), releases the claim, and tries the next-nearest job. All
   villagers retry unreachable jobs every `unreachable_retry_ticks` (this
   GDD owns the cadence the Building System listed as provisional). [TR-villager-ai-behavior-055]
7. **Nudge-aside** (Building System Edge Case 6): when a builder's target
   cell is occupied by another character, the builder requests a vacate.
   An idle or wandering occupant steps to the nearest walkable adjacent
   cell within one tick; an occupant mid-activity (working, sleeping) is
   NOT interrupted — the builder's cell stays deferred until free. A
   villager never nudges another builder off a claimed job. [TR-villager-ai-behavior-056]

**Movement and walkability**

8. Villagers move cell-to-cell on walkable surfaces. A cell is
   **standable** iff: the cell below is solid (terrain or Built block —
   blueprints are non-solid per the Building System's Core Rule 14b), and
   the cell itself plus the two cells above are empty
   (`villager_clearance` = 3 cells, registered constant). [TR-villager-ai-behavior-009] *Consequence:
   the Building System's default `wall_height` of 3 yields exactly the
   minimum walkable interior height — a standard room is walkable with no
   headroom to spare; lowering wall height below 3 makes the interior
   unwalkable.*
8a. **Character scale** *(added by the 2026-07-23 slice revision —
    Minecraft-style proportions, slice-validated Day 2 of the vertical
    slice)*: the villager model is 2 cells tall (a feet cell plus one
    cell directly above forms the visible body). The **body-column** —
    the vertical cell span the anti-stuck rules below (Rules 15–17,
    Edge Cases 13–17) must treat as the villager's own space — is the
    same 3-cell span as standability clearance above: the 2-cell body
    plus one buffer cell of headroom. The numeric clearance constant
    does not change; this rule only names the concept explicitly so the
    anti-stuck rules have a precise, reusable definition of "the
    villager's space" — checking only the feet cell would let a rescue
    or seal-prevention check pass while the model still clips a low
    ceiling. [TR-villager-ai-behavior-098]
9. A step between adjacent standable cells is legal if the height
   difference is at most 1 cell (natural block staircases work; 2+ cliffs
   don't). Orthogonal steps only; a diagonal is legal only when both
   flanking orthogonal cells are also passable (no corner-cutting through
   walls). No jumping, swimming, or climbing in MVP. [TR-villager-ai-behavior-010]
10. These walkability rules are THE definition Build Validation &
    Navigability later checks against — that system asks "can a villager
    (per these rules) reach X?", it does not define its own movement. [TR-villager-ai-behavior-011]
10b. **Re-path filtering is a behavioral contract** *(added by the
    2026-07-10 review; scope widened by the re-review)*: a Voxel World
    write triggers a re-path/re-validation evaluation for **any moving
    villager — Traveling, a Wandering step, a Breather step-away, or an
    F4 vacate step** — ONLY if the changed cell(s) intersect the
    remaining movement's cells or their **clearance envelope, defined
    explicitly as: each movement cell plus the two cells directly above
    it (the `villager_clearance` column, Rule 8) plus, for diagonal
    steps, both flanking orthogonal cells (Rule 9)**. Writes elsewhere
    are ignored by design. This filter is part of the design (AC18's
    correctness depends on it), independent of whatever throttling
    strategy the AI ADR adds on top — without it, the synchronous
    signal fan-out cost at 30 villagers would be baked in structurally. [TR-villager-ai-behavior-012]
10c. **Deciding-pass staggering directive** *(added by the re-review)*:
    when many villagers enter Deciding in the same frame (e.g., a large
    command's completion frees many jobs at once), their F2 selection
    passes are staggered across frames rather than all executing in one
    — a synchronized pass of 30 × 15 pathfinds could alone exceed the
    16.6ms frame budget. The stagger mechanism and per-tick selection
    budget are owned by the performance/AI ADR; this rule only mandates
    THAT staggering exists. Villager order within the stagger follows
    the stable processing order (Edge Case 3) for determinism. [TR-villager-ai-behavior-013]

**Life texture (MVP — added by the 2026-07-10 review)**

7b. **The breather beat**: after `jobs_before_break` (default 4)
    consecutively completed construction jobs, the villager takes a
    **Breather** before claiming another job — a short non-productive
    beat (`breather_duration_ticks`, default 90 ≈ 45s game time at 1x):
    it steps away from the work site (target chosen by F4's selection
    with the just-finished cell as "requester" — reusing the existing
    deterministic rule; the target must be standable per Rule 8), sits
    or stands and looks around. Work-claiming is suppressed for the
    duration; urgent needs still preempt normally. [TR-villager-ai-behavior-057] **Integration
    precisions** *(re-review)*: the Breather check slots into Deciding
    between "job completed" and re-running priority tier 2 — it can
    only ever begin BETWEEN jobs, never mid-claim; its duration runs on
    a dedicated ticks-since-entry counter, independent of
    `decision_interval`; environmental interruptions behave like
    Wandering's (walled-in → Edge Case 2 distress; the block it sits
    on being removed → stand up in place, continue the Breather). [TR-villager-ai-behavior-058]
    *(Rationale: the review found the strict priority list produces a
    tireless machine; the breather is the minimal rhythm that reads as
    "a person working," directly serving Pillar 2's design test. It is
    deliberately cosmetic-plus-pacing — no need value changes.)*
7c. **Idle micro-behaviors**: Wandering is not a single amble — the
    villager varies between walking to a wander target, pausing to look
    around, sitting briefly on a standable block, and drifting toward
    its owned bed's area when one exists — **bed-drift is bounded by
    F3's rules: the drift target is simply the flood-fill cell nearest
    the bed WITHIN `wander_radius`; if the bed lies beyond the radius,
    the villager drifts to the radius edge, never pathing outside F3's
    bounded set** *(re-review: unbounded drift would have been an
    uncounted goal-directed pathfind)*. [TR-villager-ai-behavior-059] [TR-villager-ai-behavior-060] Selection among micro-behaviors
    uses the same injected RNG as F3 (deterministic in tests). [TR-villager-ai-behavior-016] Pure
    flavor, no gameplay effect — but load-bearing for the "settlement
    has a pulse" fantasy the MVP playtest measures.

**Home and sleep (MVP's move-in moment)**

11. Beds have owners: the first villager to need sleep claims an unowned,
    reachable bed permanently (one bed = one owner). Claiming a bed IS the
    "move-in" moment — the MVP hypothesis's payoff. [TR-villager-ai-behavior-061]
12. A villager whose sleep need is urgent goes to its owned bed (or claims
    one, Rule 11). If no reachable bed exists, the villager sleeps on the
    ground where it stands at reduced recovery (values owned by the Needs
    GDD) — visibly worse off, telling the player exactly what's missing
    (Player Fantasy Beat 3: being needed). [TR-villager-ai-behavior-062]
13. Sleeping ends when the need is restored above its wake threshold
    (Needs GDD's value); the villager then re-enters the decision loop. [TR-villager-ai-behavior-063]

**Population**

14. The population ceiling is 20–30 concurrent villagers at Full Vision
    (MVP: exactly 1; Vertical Slice: ~5 per the concept). This ceiling is
    a design commitment (individual legibility, Pillar 2), and the
    performance budget assumes it. [TR-villager-ai-behavior-064]
14b. **Starting roster** *(added by the 2026-07-10 review — resolves the
    VS tier mismatch)*: at world generation, this system places
    `starting_villager_count` villagers (config: MVP = 1, Vertical
    Slice = 5) at valid standable cells near the world center. [TR-villager-ai-behavior-065] This GDD
    owns the STARTING population; Township Progression (Alpha) owns all
    GROWTH beyond it (arrivals, recruitment). This reconciles the
    concept's "~5 villagers at VS" with Rule 14's tiering — without it,
    no system could place villagers 2–5 before Alpha.

**Anti-stuck safety net** *(added by the 2026-07-23 slice revision —
validated as an interim safety net during the vertical slice, commit
64ff918; see Open Questions for the production-grade replacement this
net stands in for)*

15. **Unstuck watchdog**: a villager in **Traveling** or **Working**
    that has zero legal step from its current cell, or **a villager in
    ANY state** whose current cell fails the standability check (Rule
    8) — the **self-sealed** sub-condition — for
    `unstuck_watchdog_threshold_ticks` consecutive ticks (default 12) is
    teleported to the nearest standable, unoccupied cell (F5). Any job
    claim it holds releases back to the queue exactly as Rule 6's
    unreachable-job flow; bed ownership, if any, is unaffected. The
    villager re-enters Deciding at the new cell. A `villager_unstuck`
    event fires, incrementing a per-villager counter and a world total
    counter, exposed to the F3 debug console now and reserved for
    future production analytics (see Dependencies). **Idle, Wandering,
    Sleeping, and Breather villagers are never rescued by the watchdog
    for the zero-legal-step sub-condition** — Edge Case 2's original
    stay-put/distress-cue behavior is unchanged for those states, and
    that sub-condition's scope stays strictly Traveling/Working; the
    self-sealed sub-condition above is the sole exception, rescue-
    eligible in every state, because a self-sealed villager cannot
    rescue itself and its own state transition (e.g. Working's
    unconditional "Cell Built" exit, State Table) would otherwise race
    the stuck counter past threshold before it can ever fire *(M01
    closure fix, 2026-07-26 — see
    production/qa/evidence/m01-closure-evidence-20260726.md)*. [TR-villager-ai-behavior-099]
15b. **Rescue target selection** is a bounded search (F5), never an
    unbounded teleport-anywhere: the nearest standable, unoccupied cell
    within `unstuck_rescue_search_radius`, found by an expanding-ring
    search from the villager's current cell (tie-break by the same
    lexicographic cell-coordinate convention as F2, for determinism).
    If none is found, the radius doubles up to
    `unstuck_rescue_max_radius` before the rescue defers to the next
    tick (Edge Case 14). [TR-villager-ai-behavior-100]
16. **Seal prevention**: a build-job completion (Planned→Built write)
    that would leave its builder with zero legal steps is refused — the
    write does not commit, the claim releases back to the queue, and a
    different villager may claim and complete the job from a position
    that doesn't self-trap (F6). **Dig and demolition jobs are
    exempt** — their completions are never refused for this reason. [TR-villager-ai-behavior-101]
16b. **Livelock escape**: refusing a completion increments an abandon
    counter for that specific (job, villager) pair. After
    `seal_prevention_abandon_limit` (default 3) refusals of the SAME
    villager on the SAME job, the write proceeds unconditionally on the
    next attempt — the builder becomes sealed in by its own completed
    work, and the Unstuck Watchdog (Rule 15) rescues it on its normal
    schedule. This is a deliberate tradeoff: a rare, self-healing
    entrapment beats a job that can never complete. [TR-villager-ai-behavior-102]
17. **Dig onsite exclusion (self-undermine guard)**: for dig and
    demolition jobs specifically, the onsite position (Rule 5) directly
    above the target cell is excluded from eligibility — a villager may
    not stand on the block it is digging out; it must approach from an
    orthogonal side instead. *(Real incident: a villager dug the block
    directly beneath its own feet, instantly failing its own
    standability check the moment the write committed.)* This exclusion
    does not apply to build jobs, where standing on/adjacent to a
    not-yet-Built cell is safe (blueprints are non-solid, Building Core
    Rule 14b). [TR-villager-ai-behavior-103]

### States and Transitions

**Agent state machine** (per villager):

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Deciding | Loop start, activity end, interruption, preemption | Activity chosen (same tick) | Runs the priority list (Rule 2); instantaneous — never a visible "stand and think" pause [TR-villager-ai-behavior-066] |
| Traveling | Activity chosen with a distant target | Arrival on site / target invalidated / preemption / Unstuck Watchdog rescue fires (Rule 15, Edge Case 13) *(Slice revision 2026-07-23)* | Follows the computed path cell-by-cell; re-paths if a Voxel World write blocks the path |
| Working | Arrived at claimed job, on site | Cell Built / job revoked / preemption / Unstuck Watchdog rescue fires (Rule 15, Edge Case 13) *(Slice revision 2026-07-23)* | Applies tick progress to the claimed cell (Building System F3); plays work animation/sound |
| Sleeping | Arrived at owned bed (or ground fallback) with urgent sleep need | Wake threshold reached / bed removed under them | Restores sleep need per tick (rates owned by Needs GDD) |
| Breather | `jobs_before_break` consecutive jobs completed | `breather_duration_ticks` elapse / urgent need preempts | Non-productive rest beat near the work site (sit/look around); work-claiming suppressed; needs still decay and preempt (Rule 7b) |
| Wandering | Decided Idle | Any higher-priority activity appears (checked every `decision_interval` ticks); interruption takes effect at the end of the current 1-cell step | Varies among micro-behaviors (walk, pause-and-look, sit, drift toward owned bed's area — Rule 7c); pure flavor, no gameplay effect [TR-villager-ai-behavior-067] |

*(No "Suspended" state: villagers live in the Valley and keep simulating
during scene transitions and dungeon excursions — Scene/World Management's
Core Rule 4. Villagers pause only when game time pauses.)* [TR-villager-ai-behavior-068]

### Interactions with Other Systems

- **Building System** (MVP, mutual — THE central seam): consumes its
  construction-job queue under the contract its Core Rule 12 defines;
  this GDD CONFIRMS that contract (Rules 4–7 above) and supplies the
  provisional halves it listed: claim mechanics, on-site presence,
  unreachable reporting + retry cadence, graceful abandon, nudge-aside.
  Its GDD's "PROVISIONAL" markers on the job contract can be considered
  resolved once this GDD is approved. **Contract amendment (Slice
  revision 2026-07-23)**: the claim record now carries the claiming
  villager's id (Rule 4), which the Building System's project entity
  aggregates as `worker_ids`; and the Planned→Built write must
  additionally accept a Seal Prevention refusal (Rule 16/F6) — a
  negative-write gate beyond the existing unreachable-job reporting
  (Rule 6) that the Building System's write path must be able to reject
  and requeue.
- **Time & Tick System** (upstream, MVP): decisions/work/need-recovery on
  tick events; movement interpolation on game delta; everything halts in
  pause and accelerates under warp. Never touches raw delta.
- **Voxel World** (upstream, MVP): reads physical occupancy for
  walkability (Rules 8–9) and listens to write signals to re-path when
  the world changes mid-travel. Never mutates the grid (construction
  writes go through the Building System). [TR-villager-ai-behavior-069]
- **Needs & Mood System** (MVP sibling, ✅ Designed — CONFIRMED; stale
  PROVISIONAL marker patched 2026-07-10, this time verified in the file):
  defines which needs exist, decay rates, urgency/wake thresholds, and
  recovery rates. **Consumption model** (its Core Rule 3, pinned
  2026-07-10): this GDD reads the QUERYABLE per-need state at its
  decision points (`decision_interval` — Rules 2/13's level checks are
  the intended reading); the urgent/satisfied events are latency HINTS,
  never the source of truth — a missed event is harmless. [TR-villager-ai-behavior-070] **Recovery
  reporting** (its Core Rule 10): discrete `start_recovery(need,
  source_enum)` / `stop_recovery(need, reason)` calls; the source enum is
  `bed_sheltered` / `bed_unsheltered` / `ground_no_bed_owned` /
  `ground_bed_unreachable` / `ground_trapped` (widened 2026-07-10 from
  binary bed/ground — Rules 11–12 supply reachability/trapped, Build
  Validation supplies the shelter split; the ground_* distinction feeds
  the why-string, not the rates). [TR-villager-ai-behavior-071]
- **Build Validation & Navigability** (MVP, downstream): consumes the
  walkability definition (Rules 8–10) as its ground truth for
  reachability/livability checks.
- **Villager Info UI** (MVP, downstream): displays villager name, current
  activity, and need levels — all state it shows lives here or in Needs.
- **Scene/World Management** (Foundation, upstream): villagers simulate
  continuously through transitions (no Suspended state); hosted in the
  Valley scene.
- **Save/Load & World Persistence** (Vertical Slice, downstream,
  provisional): serializes per-villager state (position, current activity,
  claimed job id, owned bed, need levels via Needs GDD). [TR-villager-ai-behavior-027]
- **Squad & Combat / Wave Defense** (Vertical Slice, downstream,
  provisional): recruits able villagers into squads — out of scope here;
  flagged so the seam isn't forgotten.
- **Stuck Telemetry** (Production, downstream, undesigned — added by the
  2026-07-23 slice revision): the `villager_unstuck` event and its
  per-villager/total counters (Rule 15) are the sizing input
  REPORT.md flags as a hard requirement — production build-order
  planning and scaffolding/ladders (the real fix this safety net stands
  in for) will be tuned against this telemetry. Exposed immediately to
  the F3 debug console (dev tool, no dedicated GDD) pending a formal
  analytics system.

## Formulas

*(`systems-designer` consulted — mandatory for this high-risk section even
in Lean mode. Review produced 3 revisions and 1 added formula; all
incorporated.)*

### F1 — Travel time

`travel_time_game_seconds = path_length_cells / move_speed` [TR-villager-ai-behavior-072]

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `path_length_cells` | float | ≥ 0 | Steps in the computed cell path; orthogonal step = 1.0, diagonal = 1.4. `0` is valid (target is the current/adjacent cell, Rule 5) → immediate arrival |
| `move_speed` | float | 1.5–6.0, default 3.0 | Cells per game-second. Game-time invariant: warp accelerates wall-clock travel proportionally, never the game-time cost [TR-villager-ai-behavior-073] |

Example: a 12-step path at 3.0 → 4.0 game-seconds; at 2x warp = 2.0
wall-clock seconds.

**Arrival/tick-boundary rule**: movement interpolates on game delta, so
arrival routinely happens between ticks. Working state is entered
immediately on arrival (visually), but the first work-progress increment
is credited at the NEXT tick boundary — no partial-tick credit, ever.
**This applies to EVERY Traveling→Working transition, including the
1-cell step between adjacent cells of the same command.** [TR-villager-ai-behavior-029] **Clock
model (pinned by the 2026-07-10 re-review): ticks are a GLOBAL
fixed-cadence heartbeat, never a per-villager countdown that resets on
travel.** [TR-villager-ai-behavior-074] A step shorter than one tick period (e.g., 1 cell at default
`move_speed` 3.0 = 0.667 ticks) is absorbed between global ticks — the
villager arrives before the next scheduled tick and that tick credits
the new cell with zero waste, so a 9-cell adjacent chain costs exactly
36 ticks at default tuning (matching Building F3's example) — **barring
a `max_ticks_per_frame` discard event** *(caveat added 2026-07-10: Time
& Tick's stall cap discards excess simulated time permanently, so
"exactly N ticks" invariants hold only in the no-discard case; consumers
must count observed ticks, never derive durations from clock arithmetic
— see the Consumer caveat in time-tick-system.md)*. [TR-villager-ai-behavior-075] Only when
a step exceeds one tick period (slow `move_speed` tuning, longer travel)
do skipped global ticks become real overhead. Integration test AC40
measures the true total at any tuning. (Cross-reference: Building
System F3 consumes this rule; without it, effective build times would
drift by up to one tick per job.)

### F2 — Job selection

`chosen_job = argmin(path_length_cells)` over available reachable jobs;
tie-break by queue order (older commit first); **same-command ties break
by lexicographic cell coordinates (y, then x, then z)** — all cells of
one command share a commit timestamp, and coordinates are a
Building-System-independent, trivially deterministic secondary key
*(revised by the 2026-07-10 re-review: the earlier "cell index within
the command" cited a rasterization-order artifact Building System only
actually defines for walls, not floors/roofs — coordinates exist for
every cell unconditionally)*. The coding standard requires same-result
every run. [TR-villager-ai-behavior-076]

**Approximation contract** (required for implementations to converge):
candidates are pre-filtered to the nearest `job_candidate_count` (default
5) by straight-line (Chebyshev) distance; only those are true-path
checked; if all fail reachability, the next `job_candidate_count` are
tried — up to a hard total of `max_selection_candidates` (default 15 =
three rounds) per selection pass. If all candidates fail, the villager
falls through the priority list (Edge Case 7) for this pass;
`unreachable_retry_ticks` governs later re-attempts. Worst-case pathfind
attempts per pass are therefore bounded at 15 per villager — never a
full-queue pathfind (cap added by the 2026-07-10 review; uncapped, a
512-job queue × 30 villagers permitted ~15,000 attempts in one pass). [TR-villager-ai-behavior-077]

### F3 — Wander target selection

`wander_target = ` a uniformly chosen cell from the set produced by a
**bounded flood-fill** of standable, reachable cells within
`wander_radius` (default 8) of the current position; re-picked every
`wander_interval` ticks (default 6). Flood-fill guarantees reachability
by construction (no island targets, no post-hoc path validation). [TR-villager-ai-behavior-078]

**Determinism contract**: the random source is injected (dependency
injection per coding standards) — production uses the live RNG;
tests inject a fixed-sequence instance through the same interface, so
wander tests are deterministic without seeding globals. [TR-villager-ai-behavior-016]

### F4 — Nudge-aside target selection

`vacate_target = argmin(height_difference), then argMAX(Chebyshev
distance to requester)` over standable cells orthogonally adjacent to the
occupant; tie-break by a fixed scan order (N, E, S, W — **axis
convention: N = −z, E = +x, S = +z, W = −x**, pinned 2026-07-10 as no
compass→axis mapping existed anywhere in the project). The occupant
steps AWAY from the requesting builder — never toward it *(direction
corrected by the 2026-07-10 review: the original argmin-distance pulled
the occupant into the builder's own working zone; independently
re-verified in the re-review — the diametrically opposite cell uniquely
wins in standard orthogonal geometry)*. Deterministic — the
same situation always produces the same step. If no adjacent standable
cell exists, the vacate request fails and the builder's cell stays
deferred (Building System Edge Case 6). [TR-villager-ai-behavior-079]

**Step semantics**: the vacate is a normal walking step at `move_speed`
(F1 interpolation — never a teleport); the builder's target cell simply
remains deferred until the step completes and the cell is clear. There
is no timing promise tied to tick length *(replaces the original "within
one tick", which broke at `move_speed` < 2.0)*. [TR-villager-ai-behavior-034]

### F5 — Unstuck watchdog trigger and rescue target *(added by the 2026-07-23 slice revision)*

`rescue_fires = (stuck_tick_count >= unstuck_watchdog_threshold_ticks)`

where `stuck_tick_count` increments by 1 each tick either (a) a
Traveling/Working villager has zero legal step from `current_cell`, or
(b) `current_cell` fails the standability check (Rule 8) — the
**self-sealed** sub-condition, evaluated in EVERY state, not only
Traveling/Working *(carve-out added by the M01 closure fix, 2026-07-26 —
a self-sealed villager cannot rescue itself, and its own state
transition would otherwise race the counter past threshold before it
can ever fire)* — and resets to 0 the instant a legal step or standable
cell becomes available again.

`rescue_target = nearest(cell)` such that `cell` is standable (Rule 8)
and unoccupied (no other villager's `current_cell`), found by an
expanding-ring BFS from `current_cell` out to `unstuck_rescue_search_radius`
(tie-break lexicographic `y, x, z`, the F2 convention, for determinism);
if none is found the radius doubles, up to `unstuck_rescue_max_radius`
(Edge Case 14).

| Variable | Type | Range | Description |
|----------|------|-------|--------------|
| `stuck_tick_count` | int | 0 – unbounded (resets on relief) | Consecutive ticks of: a Traveling/Working villager with no legal step, OR (any state) a self-sealed non-standable current cell |
| `unstuck_watchdog_threshold_ticks` | int | 6–30, default 12 | Ticks of continuous stuckness before rescue fires |
| `rescue_target` | cell coordinate | any standable, unoccupied cell within the search radius | Teleport destination |
| `unstuck_rescue_search_radius` | int (Chebyshev cells) | 3–12, default 6 `[assumption]` | Initial BFS ring radius searched for a rescue cell |
| `unstuck_rescue_max_radius` | int (Chebyshev cells) | 12–48, default 24 `[assumption]` | Expansion ceiling before a rescue defers to the next tick |
| `rescue_fires` | bool | {true, false} | Whether the teleport, claim-release, and `villager_unstuck` event occur this tick |

**Output range**: a discrete per-tick boolean gate. When true, exactly
one teleport, one claim release (only if a claim is held), and one
`villager_unstuck` event occur; the counter resets afterward, so a
villager can only be rescued once per stuck episode.

**Provenance note on the threshold's wall-clock equivalent** *(RESOLVED
2026-07-23, Slice revision — tick-rate/furniture resolution)*: `12`
ticks is the portable, tuning-safe value validated during the slice
(commit 64ff918) and remains unchanged. This GDD's registered
`ticks_per_second` was raised from 2.0 to 4.0 by that same slice
revision (see time-tick-system.md Formulas/Tuning Knobs) — the vertical
slice ran at 4.0 throughout, and the user adopted that pace. At
`ticks_per_second = 4.0`, 12 ticks = **3.0 game-seconds at 1x**, which
now MATCHES the "~3 seconds" figure the slice's own ad-hoc debug-clock
instrumentation logged (that instrumentation ran an internal
4-ticks/second timer). The prior discrepancy this note used to flag is
therefore resolved, not merely relabeled: the registered constant and
the slice's own observed pace now agree. The tick count (12) remains
the authoritative, slice-validated value; the wall-clock figure is
derived from this GDD's own `ticks_per_second`, consistent with every
other tick-based tuning knob in this document.

**Worked example**: default tuning. A villager Working a claimed cell
becomes boxed in when a second villager finishes the wall around it.
`stuck_tick_count` increments each tick; at tick 12 (3.0 game-seconds
at 1x, `ticks_per_second = 4.0`) `rescue_fires` becomes true. The BFS finds a standable, empty
cell 2 rings away (well within `unstuck_rescue_search_radius = 6`); the
villager teleports there, its job claim releases back to the queue,
and its per-villager `villager_unstuck` counter increments to 1 (world
total also increments).

### F6 — Seal-prevention refusal and livelock escape *(added by the 2026-07-23 slice revision)*

`allow_write = NOT would_trap_builder OR (abandon_count >= seal_prevention_abandon_limit) OR (job_type != build)`

where `would_trap_builder` evaluates the builder's `current_cell`
against Rules 8–9 as if the write had already committed — true iff the
builder would then have zero legal steps to any standable neighbor.
`abandon_count` is a counter kept per (job, villager) pair, incremented
each time this specific pairing's completion is refused for this
reason; it resets when the job is claimed by a **different** villager.

| Variable | Type | Range | Description |
|----------|------|-------|--------------|
| `would_trap_builder` | bool | {true, false} | Whether completing this write leaves the builder with zero legal steps |
| `abandon_count` | int | 0 – `seal_prevention_abandon_limit` | Refusals of this specific (job, villager) pair so far |
| `seal_prevention_abandon_limit` | int | 1–6, default 3 (slice-validated) | Livelock-escape threshold — after this many refusals the write proceeds unconditionally |
| `job_type` | enum | {build, dig, demolish} | Dig/demolition jobs are exempt — `allow_write` is always true for them (Rule 16) |
| `allow_write` | bool | {true, false} | Whether the Building System's write is permitted to commit this tick |

**Output range**: a per-attempt boolean gate; `abandon_count` is
monotonic per (job, villager) pair and bounded above by
`seal_prevention_abandon_limit` (it stops mattering once `allow_write`
flips true).

**Worked example**: a villager completes the last wall cell of a tiny
1×1 room whose only doorway was sealed moments earlier by a different
job elsewhere. `would_trap_builder = true` (no legal step out) — the
write is refused, the claim releases (`abandon_count` for this
(job, villager) pair = 1). The same villager, being nearest, re-claims
and reaches the identical position twice more (`abandon_count` = 2,
then 3). On the 3rd refusal, `allow_write` flips true regardless of the
trap check: the wall completes, the villager is sealed inside, and 12
ticks later (F5) the watchdog teleports it out.

### Deliberately NOT formulas (and why)

- **The pathfinding algorithm** (A*, flow fields, hierarchical) —
  architecture, **RESOLVED 2026-07-11 via ADR-0007: `AStar3D`** (Godot's
  standalone graph-search utility, manually populated with standable
  cells and legal-step connections, incrementally patched — not
  `NavigationServer3D`/navmesh baking; no `AStarGrid3D` class exists in
  Godot 4.7 to use instead). This GDD's walkability rules (Core Rules
  8–9) remain the canonical predicates the graph is built from — see
  ADR-0007 for the graph-construction mechanism. [TR-villager-ai-behavior-035]
- **Need decay/recovery rates, thresholds, ground-sleep penalty** — owned
  by the Needs & Mood GDD (Core Rules 12–13 reference, never define).
- **Construction progress per tick** — Building System F3.
- **`decision_interval`, `unreachable_retry_ticks`** — authored config
  values (Tuning Knobs), no computation.

## Edge Cases

1. **Path blocked mid-travel** (world changed while walking). The villager
   re-paths from its current cell. If the target is now unreachable: for a
   job — report to the Building System (orange ghost), release the claim,
   pick the next job (F2); for a bed — fall back to ground sleep (Rule 12);
   for a wander target — pick a new one (F3). [TR-villager-ai-behavior-036]
2. **Villager completely walled in** (no legal step from its cell)
   **while Idle, Wandering, Sleeping, or Breather** *(scope narrowed by
   the 2026-07-23 slice revision — see Edge Case 13 for the
   Traveling/Working case, which IS rescued)*. The villager stays put —
   it is **never teleported, clipped, or despawned to escape**. It idles
   in place with a visible distress cue (treatment via Villager Info UI /
   art bible); urgent sleep falls back to ground sleep in place. The
   player resolves it by removing blocks. [TR-villager-ai-behavior-080] *(A trapped
   villager is always the player's own construction — consistent with the
   unreachable-blueprint philosophy: visible, patient, player-fixable.)*
3. **Two villagers race for the same job.** Claims are atomic: exactly one
   succeeds; the loser's F2 selection simply proceeds to its next
   candidate. No error state, no double-work. **Winner determinism**:
   same-tick claim contention resolves in villager processing order
   (stable villager index) — deterministic across runs, matching the
   F2/F3/F4 determinism contracts *(added 2026-07-10)*. [TR-villager-ai-behavior-081]
3b. **Urgent need fires while already Traveling to satisfy that same
   need.** No-op — the villager continues; re-evaluation confirms the
   current activity is already the top priority *(made explicit
   2026-07-10)*. For VS+ with multiple need types: if a DIFFERENT need
   becomes more urgent (lower value) than the one being pursued, the
   standard preemption applies; ties break by a fixed need-priority
   order defined in the Needs GDD when multiple needs land (its schema
   note). [TR-villager-ai-behavior-082]
4. **Job revoked mid-work** (player undo/removal — Building Edge Case 7).
   The villager stops at the current tick boundary, plays no failure
   reaction (the world simply changed), and re-enters Deciding. Its claim
   bookkeeping is cleared by the revocation itself. [TR-villager-ai-behavior-083]
5. **Bed removed while the villager sleeps in it** (Building Edge Case
   11). **Trigger channel** *(pinned 2026-07-10 — "wakes immediately" was
   previously mechanism-free: Rule 10b covers only MOVING villagers and
   cannot notify a stationary sleeper)*: the Building System emits its
   **furniture-revocation event** to the owning villager on removal (its
   Core Rule 17b — symmetric to job revocation). On receiving it, the
   villager wakes immediately, its bed ownership dissolves, it calls
   `stop_recovery` toward Needs (which credits zero recovery for the
   removal tick, Needs Core Rule 10), and it re-enters Deciding —
   typically resuming sleep on the ground (reduced recovery) or claiming
   another free bed if one is reachable. [TR-villager-ai-behavior-084]
6. **Bed removed while owned but unoccupied.** Ownership dissolves
   silently; the villager claims a new bed the next time sleep becomes
   urgent (Rule 11). [TR-villager-ai-behavior-085]
7. **All available jobs unreachable.** Every job gets reported (Building
   System shows orange on each); the villager falls through the priority
   list to Wandering. Retries continue every `unreachable_retry_ticks`. [TR-villager-ai-behavior-086]
8. **No standable wander cell in radius** (flood-fill returns only the
   current cell). The villager stays in place until the next
   `wander_interval` re-pick — visually a calm pause, not an error. [TR-villager-ai-behavior-087]
9. **Tick burst (up to `max_ticks_per_frame = 10`).** Per villager: at
   most one decision re-evaluation per processed tick, work progress per
   the Building System's per-villager burst rule, need recovery per tick.
   A burst never lets a villager make 10 contradictory decisions in one
   frame — decisions consider state as of each processed tick in order. [TR-villager-ai-behavior-088]
10. **Player is in a dungeon (scene transition).** Villagers keep
    simulating in the Valley in real time — building, sleeping, wandering
    (Scene/World Management Core Rule 4). The player returns to visible
    progress, not a freeze-frame. [TR-villager-ai-behavior-068]
11. **Save/Load mid-activity** (Vertical Slice, provisional). Serialized
    claimed-job ids and bed ownership are re-validated on load; a claim
    whose job no longer exists dissolves and the villager re-enters
    Deciding. Never crash on a stale reference. [TR-villager-ai-behavior-027]
12. **MVP degenerate case: zero jobs, zero urgent needs.** The single
    villager idles indefinitely, cycling the Rule 7c micro-behaviors —
    an acceptable MVP baseline (revisit at VS with more villagers and
    the day rhythm): varied idling should read as "waiting for a home,"
    not aimlessness. [TR-villager-ai-behavior-089] The MVP playtest verifies this reading (Game Feel
    criteria) — softened from "correct baseline" per the 2026-07-10
    review; the claim is a hypothesis until tested.

**Added by the 2026-07-23 slice revision (anti-stuck safety net)**

13. **Traveling/Working villager stuck for `unstuck_watchdog_threshold_ticks`;
    self-sealed villager in ANY state.**
    A villager in Traveling or Working with zero legal step from its
    current cell, OR a villager in **any state** whose own current cell
    has become non-standable (the self-sealed sub-condition — a
    completed self-seal build, Rule 16b, is the primary case), for
    `unstuck_watchdog_threshold_ticks` consecutive ticks is teleported to
    the nearest standable, unoccupied cell (F5). Any held job claim
    releases back to the queue exactly as Rule 6's unreachable-job flow;
    the villager re-enters Deciding at the new cell; a `villager_unstuck`
    event fires, incrementing per-villager and world total counters for
    F3 debug/telemetry. This is the sole exception to Edge Case 2's
    "never teleport" rule — the zero-legal-step sub-condition stays
    scoped strictly to Traveling/Working; the self-sealed sub-condition
    is rescue-eligible in every state, because a self-sealed villager
    cannot rescue itself and its own state transition would otherwise
    race the stuck counter past threshold before it can ever fire
    (Rule 15). [TR-villager-ai-behavior-104]
14. **Watchdog rescue search finds no standable, unoccupied cell within
    `unstuck_rescue_search_radius`.** The search radius doubles, up to
    `unstuck_rescue_max_radius` (Rule 15b). If still no cell is found,
    the rescue defers to the next tick — `stuck_tick_count` keeps
    incrementing and the search retries every tick until a cell is
    found — and a `villager_unstuck_search_failed` event fires exactly
    once for the stuck episode (not once per tick), so this pathological
    case is visible without spamming logs. [TR-villager-ai-behavior-105]
15. **Build-job completion would trap its builder.** The write is
    refused, the claim releases back to the queue, and `abandon_count`
    for that (job, villager) pair increments by 1 (F6, Rule 16). A
    different villager may then claim and complete the job from a
    position that doesn't self-trap. Dig and demolition jobs are
    exempt — they are never refused for this reason. [TR-villager-ai-behavior-106]
16. **Same villager refused on the same job 3 times
    (`seal_prevention_abandon_limit`).** On the next attempt the write
    proceeds unconditionally — the builder becomes sealed in by its own
    completed work — and the Unstuck Watchdog (Edge Case 13) rescues it
    on its normal schedule (F6, Rule 16b). This is a deliberate
    tradeoff: a rare, self-healing entrapment beats an unresolvable
    livelock where the job can never complete. [TR-villager-ai-behavior-107]
17. **Dig/demolition job's only onsite position is directly above the
    target cell.** That position is excluded from onsite eligibility for
    dig/demolition jobs specifically — the villager must approach from
    an orthogonal side instead (Rule 17). *(Real incident: a villager
    dug the block directly beneath its own feet, instantly failing its
    own standability check the moment the write committed.)* Does not
    apply to build jobs, where standing on/adjacent to a not-yet-Built
    cell is safe (blueprints are non-solid, Building Core Rule 14b). [TR-villager-ai-behavior-108]

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Voxel World | ✅ Designed | Physical occupancy reads for walkability (Rules 8–9); write signals for mid-travel re-pathing. Never mutates the grid |
| Time & Tick System | ✅ Designed | Tick events (decisions, work, need recovery) + game delta (movement interpolation); pause/warp semantics |
| Building System | ✅ Approved | The construction-job queue and its Core Rule 12 contract — this GDD confirms it and supplies the AI halves (Rules 3–7). *(Slice revision 2026-07-23)*: also depends on Building System's write path accepting a Seal Prevention refusal (Rule 16/F6) as a new negative-write gate |
| Needs & Mood System | ✅ Designed (2026-07-10) | Which needs exist, urgency/wake thresholds, decay and recovery rates (incl. the ground-sleep penalty) — **interface CONFIRMED** by needs-mood-system.md (urgency=25, satisfied=95, ground_penalty=0.4 — registered constants) |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Building System | MVP | ✅ Designed | The mutual seam's other direction: its construction pipeline cannot complete without this system's labor (job claiming, on-site work — its Core Rule 12); listed upstream above for the queue this system consumes (added 2026-07-10, cross-review fix). *(Slice revision 2026-07-23)*: also consumes claim attribution (Rule 4) for its project entity's `worker_ids` field |
| Build Validation & Navigability | MVP | ✅ Designed | The walkability definition (Rules 8–10) as ground truth for reachability (contract confirmed by build-validation-navigability.md) |
| Needs & Mood System | MVP | ✅ Designed — CONFIRMED (2026-07-10) | `start_recovery`/`stop_recovery` reports with the source enum (its Core Rule 10); mutual seam with the upstream row |
| Villager Info UI | MVP | ✅ Designed — CONFIRMED (2026-07-10) | Villager name, current activity/state, distress cues |
| Professions & Ranks | Alpha | Undesigned | The activity-selection layer professions plug into *(provisional)* |
| Relationships & Bonds | Alpha | Undesigned | Villager identity + proximity/interaction events *(provisional)* |
| Township Progression | Alpha | Undesigned | Population (spawning/recruiting is ITS job, bounded by the 20–30 ceiling) *(provisional)* |
| Squad & Combat / Wave Defense | Vertical Slice | Undesigned | Recruits able villagers into squads *(provisional)* |
| Save/Load & World Persistence | Vertical Slice | Undesigned | Per-villager state serialization (position, activity, claimed job id, owned bed) *(provisional)* |
| Stuck Telemetry / Production Analytics | Production | Undesigned | `villager_unstuck` event + per-villager/total counters (Rule 15) — sizing input for build-order-planning and scaffolding/ladders production work *(provisional, added 2026-07-23 slice revision)* |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `move_speed` | 3.0 cells/game-second | 1.5–6.0 | Travel pacing (F1). Too fast: villagers feel skittish/insect-like; too slow: construction stalls on travel time and the settlement feels sluggish |
| `decision_interval` | 2 ticks (= 1.0s at 1x) | 1–10 | How often urgent needs can preempt long activities (Rule 2). Lower = more responsive, more re-evaluation cost |
| `unreachable_retry_ticks` | 20 (= 10s at 1x) | 10–120 | Retry cadence for unreachable jobs (Rule 6 — the value the Building System's Tuning Knobs listed as provisional; owned here) |
| `wander_radius` | 8 cells | 3–16 | How far idle villagers roam (F3). Larger = livelier settlement but villagers drift farther from future jobs |
| `wander_interval` | 6 ticks (= 3s at 1x) | 2–20 | How often a wander target is re-picked (F3) |
| `job_candidate_count` | 5 | 3–10 | F2's pre-filter width. Larger = closer to a true global "nearest" at more pathfinding cost |
| `max_selection_candidates` | 15 | 5–30 | Hard total candidate cap per F2 selection pass (added 2026-07-10). Bounds worst-case pathfinds per villager per pass; exceeded → fall through to Wandering, retry via `unreachable_retry_ticks` |
| `jobs_before_break` | 4 | 2–10 | Consecutive jobs before a Breather (Rule 7b). Lower = more human, slower construction; higher = more machine-like |
| `breather_duration_ticks` | 90 (= 45s at 1x) | 30–240 | Length of the rest beat. Too short reads as a glitch; too long frustrates waiting players |
| `starting_villager_count` | 1 (MVP) / 5 (VS config) | 1–8 | The world-generation starting roster (Rule 14b). Growth beyond it is Township Progression's (Alpha) |
| Population ceiling | 20–30 (Full Vision) | design commitment, not a slider | MVP: 1, Vertical Slice: ~5. Raising it beyond 30 invalidates the per-agent AI assumption AND the Pillar-2 individual-legibility promise — treat as a design change, not a tune |
| `unstuck_watchdog_threshold_ticks` *(added 2026-07-23)* | 12 ticks (= 3.0s at 1x, `ticks_per_second`=4.0 *(updated 2026-07-23, Slice revision — tick-rate/furniture resolution: raised from 2.0; tick count 12 unchanged)*; slice-validated tick count) | 6–30 `[assumption range]` | How long a villager must be fully stuck before the safety-net rescue fires (F5/Rule 15; zero-legal-step counts only in Traveling/Working, self-sealed counts in any state). Lower = rescues faster but risks false-positives during momentary congestion; higher = longer visible "stuck" moments before self-healing |
| `unstuck_rescue_search_radius` *(added 2026-07-23)* | 6 cells `[assumption]` | 3–12 `[assumption]` | Initial BFS ring radius searched for a rescue cell (F5/Rule 15b); larger = more likely to find a cell in one pass at higher per-rescue cost |
| `unstuck_rescue_max_radius` *(added 2026-07-23)* | 24 cells `[assumption]` | 12–48 `[assumption]` | Hard expansion ceiling before deferring a rescue to the next tick (Edge Case 14) |
| `seal_prevention_abandon_limit` *(added 2026-07-23)* | 3 (slice-validated) | 1–6 `[assumption range]` | Livelock-escape threshold (F6/Rule 16b) — after this many refused completions by the same villager on the same job, the write proceeds and the watchdog takes over |

All values data-driven per the coding standard; none are player-facing. [TR-villager-ai-behavior-090]

## Visual/Audio Requirements

**Visual** (specs to the art bible; requirements set here):
- **Activity legibility** (Pillar 4): a viewer must be able to read a
  villager's current state at a glance — distinct silhouettes/animations
  for walking, working (hammering toward the target cell), sleeping
  (lying down; simple zzz-cue acceptable), and wandering (relaxed gait).
- **Distress cue** for trapped/ground-sleeping villagers (Edge Case 2,
  and Rule 12's ground sleep) — visible but gentle, cozy-not-alarming
  (Pillar 3); exact treatment to the art bible.
- **Movement smoothness**: continuous interpolation between cells (F1) —
  a villager must never visibly teleport or snap cell-to-cell. [TR-villager-ai-behavior-042]
- **New assets required** (MVP): one villager model + walk, work, sleep,
  idle animation sets — the largest single asset dependency of the MVP.

**Audio** (MVP-light):
- Work loop (rhythmic hammering while Working — pairs with the Building
  System's per-cell completion tick), soft footsteps, an optional gentle
  sleep cue. Ambient village bed is the Audio System's job (Alpha).

## Game Feel

**Feel reference**: Stonehearth hearthlings — unhurried, purposeful,
watchable. The test: a player who zooms in on a villager for 30 seconds
should feel calm and informed, never confused about what it's doing.

- **No visible hesitation**: Deciding is instantaneous (state table) — a
  villager finishes hammering and *walks off with purpose*. Dead frames
  between activities read as "dumb AI" and are a feel bug.
- **Movement**: smooth game-delta interpolation; pause freezes mid-stride
  (correct and expected under Time & Tick's rules); warp visibly speeds
  walking without animation glitches.
- **Work rhythm**: hammer beats align with tick progress on the claimed
  cell, so construction audibly/visibly ticks toward completion — the
  Building System's "construction has weight" claim is delivered by this
  animation-to-progress lockstep.
- **Feel acceptance criteria** (subjective, playtest-verified): a
  first-time observer can narrate what the villager is doing without UI
  help; nobody describes villager motion as "teleporting" or "jittery";
  the move-in moment (first bed claim + sleep) reads as a small story
  beat, not a state change.
- **Explicit playtest question** *(2026-07-10 re-review)*: the Breather
  + idle micro-behaviors added life texture to Wandering and pauses —
  Working and Sleeping remain purely mechanical by design. Does the
  villager still read as "a person" across a full work-sleep cycle, or
  do the untouched states break the illusion? Author further texture
  ONLY if the playtest says so (evidence before rules).

## UI Requirements

None owned — this system renders no UI. It supplies to the Villager Info
UI (MVP, downstream): villager name, current state (**Deciding/Traveling/
Working/Sleeping/Breather/Wandering** — SIX states as player-readable
labels; *corrected 2026-07-11 by the Villager Info UI review: this list
was stale, omitting Breather, which the state table and Rule 7b added at
this GDD's own review*), current need levels (values via Needs GDD), and
distress flags (**trapped, ground-sleeping** — *"no-bed" folded into
ground-sleeping 2026-07-11, user decision: Rule 12 has no awake-no-bed
limbo state, so bedlessness becomes visible exactly as ground-sleeping;
the "no bed" CAUSE still reaches the player verbatim via Needs' why-string
templates*). The UI renders and never owns. [TR-villager-ai-behavior-091]

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| Construction-job contract (per-cell jobs, on-site, parallel claims) | `design/gdd/building-system.md` | Core Rule 12, Edge Cases 5–7, F3 burst rule | Mutual contract — this GDD CONFIRMS it and fills the AI halves |
| Blueprints non-solid until Built; occupancy authority split | `design/gdd/building-system.md` | Core Rule 14b | Walkability input (Rules 8–9) |
| Tick events, game delta, pause/warp, max_ticks_per_frame | `design/gdd/time-tick-system.md` | Core Rules, Formulas | Time base for the whole agent loop |
| Physical occupancy reads, write signals | `design/gdd/voxel-world.md` | Core Rules 5–6 | Walkability + re-path triggers |
| Valley never pauses during transitions | `design/gdd/scene-world-management.md` | Core Rule 4 | Why there is no Suspended state here |
| Need definitions, thresholds, recovery rates, state+events consumption model, recovery-report API (source enum) | `design/gdd/needs-mood-system.md` | Its Core Rules 3, 4, 10, 11 | CONFIRMED (2026-07-10 — stale "not yet authored — PROVISIONAL" patched; the file exists and resolves this GDD's OQ1) |
| Walkability as validation ground truth | `design/gdd/build-validation-navigability.md` | Rules 8–10 | CONFIRMED (2026-07-10 — stale "not yet authored" patched; the file exists and consumes these rules verbatim) |
| Population ceiling resolution (20–30) | `design/gdd/game-concept.md` + `design/gdd/systems-index.md` | Open Question / high-risk flag | Resolved BY this GDD (patches in Phase 5) |
| `bed` item, `ticks_per_second`, `max_ticks_per_frame`, `cell_size` | `design/registry/entities.yaml` | Registry facts | Data dependency |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Review produced 3 rewrites and 6 missing criteria; all incorporated.
Needs & Mood values are mocked at the "need is urgent" boundary per the
testing standards — those ACs do NOT wait for that GDD.)*

**Decision loop**
1. **GIVEN** an urgent need and an available job, **WHEN** deciding, **THEN** the need is chosen (Rule 2 priority). [TR-villager-ai-behavior-049]
2. **GIVEN** an available job and no urgent need, **WHEN** deciding, **THEN** the job is chosen over wandering. [TR-villager-ai-behavior-049]
3. **GIVEN** no jobs and no urgent needs, **WHEN** deciding, **THEN** the villager wanders — indefinitely and without error (Rule 2, Edge Case 12). [TR-villager-ai-behavior-089]
4. **GIVEN** a Working villager whose need becomes urgent, **WHEN** the `decision_interval` re-check fires, **THEN** the current tick's work completes, the claim is released, and the need is pursued (Rule 3 graceful preemption). [TR-villager-ai-behavior-050]
5. **GIVEN** any activity ends, **WHEN** Deciding runs, **THEN** the next state is assigned before any further tick is processed — assert the tick counter does not increment between activity-end and state assignment within a single decide() invocation. [TR-villager-ai-behavior-066]

**Jobs and construction**
6. **GIVEN** multiple available jobs, **WHEN** selecting, **THEN** the nearest-by-true-path among the straight-line-nearest `job_candidate_count` candidates is chosen; ties break by older commit, then by lexicographic cell coordinates (y, x, z) for same-command ties — deterministic every run (F2, updated wording 2026-07-10 re-review). [TR-villager-ai-behavior-076]
7. **GIVEN** all `job_candidate_count` nearest candidates fail the true-path check, **WHEN** selecting, **THEN** the next `job_candidate_count` candidates are evaluated in turn, deterministically — never a full-queue pathfind (F2 fallback). [TR-villager-ai-behavior-077]
8. **GIVEN** a claimed job, **WHEN** another villager attempts to claim it, **THEN** the claim fails atomically and the loser selects its next candidate (Edge Case 3). [TR-villager-ai-behavior-081]
9. **GIVEN** pathing to a claimed job fails, **WHEN** the failure registers, **THEN** it is reported to the Building System, the claim is released, and the next candidate is tried (Rule 6). [TR-villager-ai-behavior-055]
10. **GIVEN** an unreachable job, **WHEN** `unreachable_retry_ticks` elapse, **THEN** a retry attempt occurs (Rule 6). [TR-villager-ai-behavior-055]
11. **GIVEN** every available job reports unreachable in the same Deciding pass, **WHEN** the priority list completes, **THEN** the villager falls through to Wandering — never stuck in Deciding — and retries resume on cadence (Edge Case 7). [TR-villager-ai-behavior-086]
12. **GIVEN** a villager not in the target or an orthogonally adjacent cell, **WHEN** ticks fire, **THEN** no work progress accrues; **GIVEN** on-site, **THEN** it accrues (Rule 5). [TR-villager-ai-behavior-054]
13. **GIVEN** arrival between two ticks, **WHEN** Working begins, **THEN** the first progress increment is credited at the next tick boundary — never partially (F1 arrival rule). [TR-villager-ai-behavior-029]

**Movement and walkability**
14. **GIVEN** a cell without 3-cell vertical clearance (`villager_clearance`), **WHEN** standability is evaluated, **THEN** it is not standable (Rule 8). [TR-villager-ai-behavior-009]
15. **GIVEN** two adjacent standable cells with height difference 1, **WHEN** stepping, **THEN** the step is legal; **GIVEN** difference ≥ 2, **THEN** illegal (Rule 9). [TR-villager-ai-behavior-010]
16. **GIVEN** a diagonal step whose flanking orthogonal cells are blocked, **WHEN** pathing, **THEN** the diagonal is not used (Rule 9). [TR-villager-ai-behavior-010]
17. **GIVEN** a Planned blueprint cell in the path, **WHEN** pathing, **THEN** the cell is treated as passable (Building Core Rule 14b). [TR-villager-ai-behavior-009]
18. **GIVEN** a Voxel World write blocks the current path mid-travel, **WHEN** the write signal fires, **THEN** the villager re-paths from its current cell (Edge Case 1). [TR-villager-ai-behavior-036]
19. **GIVEN** a Traveling villager whose target becomes invalid before arrival (bed destroyed, job voided) with no re-path possible, **WHEN** detected, **THEN** it exits to Deciding and re-selects — never keeps traveling toward a dead target (state table). [TR-villager-ai-behavior-092]
20. **GIVEN** a sequence of injected `game_delta` values during Traveling (including a warped value), **WHEN** position is sampled after each simulated movement update, **THEN** per-step displacement never exceeds `move_speed × game_delta` — property-based check over ≥5 delta samples, driven against the movement-update function directly (no real engine frames needed). [TR-villager-ai-behavior-093]
21. **GIVEN** pause, **WHEN** real time passes, **THEN** position is unchanged; **GIVEN** 2x warp, **THEN** wall-clock travel halves while game-time cost is constant (F1 invariance). [TR-villager-ai-behavior-073]

**Sleep and home**
22. **GIVEN** a first urgent sleep need and an unowned reachable bed, **WHEN** deciding, **THEN** the villager claims that bed permanently (move-in, Rule 11). [TR-villager-ai-behavior-061]
23. **GIVEN** an owned reachable bed and urgent sleep, **WHEN** deciding, **THEN** the villager sleeps in its own bed. [TR-villager-ai-behavior-062]
24. **GIVEN** no reachable bed and urgent sleep, **WHEN** deciding, **THEN** the villager sleeps on the ground at its current cell and reports the correct ground source enum — `ground_no_bed_owned` if it owns no bed, `ground_bed_unreachable` if it owns one it cannot reach (Rule 12; enum per needs-mood Core Rules 4/10, updated at the 2026-07-10 verification pass from the pre-widening "reduced-recovery flag"; rates mocked). [TR-villager-ai-behavior-062]
25. **GIVEN** the sleep need restored above the wake threshold (mocked), **WHEN** the tick fires, **THEN** the villager wakes and re-enters Deciding (Rule 13). [TR-villager-ai-behavior-063]
26. **GIVEN** a bed removed while the villager sleeps in it, **WHEN** the removal registers, **THEN** the villager wakes immediately and ownership dissolves (Edge Case 5). [TR-villager-ai-behavior-084]
27. **GIVEN** an owned but unoccupied bed removed, **WHEN** the removal registers, **THEN** ownership dissolves and a new bed is claimed at the next urgent sleep (Edge Case 6). [TR-villager-ai-behavior-085]

**Wandering**
28. **GIVEN** any wander target selection, **WHEN** evaluated, **THEN** the target is reachable by construction — never an island cell (F3 flood-fill). [TR-villager-ai-behavior-078]
29. **GIVEN** wander targets over time, **WHEN** sampled, **THEN** all lie within `wander_radius` and world bounds (F3). [TR-villager-ai-behavior-078]
30. **GIVEN** an injected fixed-sequence random source, **WHEN** wandering runs twice from the same state, **THEN** the wander paths are identical (F3 determinism). [TR-villager-ai-behavior-016]
31. **GIVEN** a flood-fill wander search returning only the current cell, **WHEN** `wander_interval` elapses, **THEN** the villager stays in place without error and re-attempts at the next interval (Edge Case 8). [TR-villager-ai-behavior-087]

**Lifecycle and edge behavior**
32. **GIVEN** an Idle, Wandering, Sleeping, or Breather villager with no legal step from its cell, **WHEN** any game time passes, **THEN** it remains in place with the distress flag set and never teleports (Edge Case 2; scope narrowed 2026-07-23 — see AC51 for the Traveling/Working rescue case). [TR-villager-ai-behavior-080]
33. **GIVEN** a job revoked mid-work, **WHEN** the revocation registers, **THEN** the villager stops at the tick boundary and re-enters Deciding without error (Edge Case 4). [TR-villager-ai-behavior-083]
34. **GIVEN** an idle occupant in a builder's target cell, **WHEN** the vacate request fires, **THEN** the occupant steps to the F4 target within one tick; **GIVEN** a Working/Sleeping occupant, **THEN** it is not interrupted (Rule 7). [TR-villager-ai-behavior-056]
35. **GIVEN** a vacate-target tie on height difference and distance, **WHEN** resolved, **THEN** the fixed N/E/S/W scan order breaks the tie identically every run (F4 determinism). [TR-villager-ai-behavior-079]
36. **GIVEN** a tick burst of `max_ticks_per_frame`, **WHEN** processed, **THEN** at most one decision re-evaluation occurs per processed tick, in order (Edge Case 9). [TR-villager-ai-behavior-088]
37. **GIVEN** a scene-transition integration test (`tests/integration/scene_transition/`) driving mocked Scene/World Management transition signals, **WHEN** the transition completes, **THEN** villager tick-driven activities have advanced exactly as many ticks as elapsed Valley game time — continuity verified numerically, not by observation (Edge Case 10). [TR-villager-ai-behavior-068]
38. **[PROVISIONAL — Save/Load undesigned, VS tier]** **GIVEN** a deserialized claimed-job or bed-owner id that no longer exists, **WHEN** load completes, **THEN** the stale claim dissolves and the villager enters Deciding — never crashes (Edge Case 11; testable now against a mocked serializer contract). [TR-villager-ai-behavior-027]
39. **[PROVISIONAL — milestone-gated]** **GIVEN** the Vertical Slice population (~5) and the Full Vision ceiling (30), **WHEN** simulating at 1x and 3x warp, **THEN** the 16.6ms frame budget is maintained — enforced at those milestones, never a blocker for MVP Done (population ceiling). [TR-villager-ai-behavior-041]

**Added by the Building System re-review (2026-07-10) — these fulfill Building AC21/36b's promised integration coverage**
40. **GIVEN** a real villager and one real queued blueprint cell, **WHEN** it claims the job, travels to site, and accumulates ticks to completion, **THEN** the cell transitions to Built via the Building System's write, the job is removed from the queue, and the villager re-enters Deciding — the full claim→build→report cycle (integration test; closes Building System AC21). [TR-villager-ai-behavior-094]
40b. **GIVEN** a builder on-site with its target cell occupied and construction deferred, **WHEN** the occupant vacates via F4, **THEN** the target cell becomes free and construction progress resumes on the next tick without re-claiming the job (occupied→deferred→resumed transition; complements Building AC36 and this GDD's AC34). [TR-villager-ai-behavior-095]
*(Harness note for AC40/40b: `tests/integration/villager_ai/build_job_cycle_test.gd`, using real Building System components — both GDDs are Designed; no playtest-doc fallback.)*

**Added by the 2026-07-10 design review**
41. **GIVEN** a Working villager with no urgent need, **WHEN** the `decision_interval` re-check fires, **THEN** it remains Working with no state change and no job re-selection — the periodic re-check is a preemption check, never an implicit interruption (Rule 2 + Rule 4 claim-stickiness). [TR-villager-ai-behavior-052]
42. **GIVEN** a builder requests a vacate on a cell occupied by a villager mid-work on its own claimed job, **WHEN** the request resolves, **THEN** it is deferred and the occupant's claim is never revoked (Rule 7 negative guarantee). [TR-villager-ai-behavior-056]
43. **GIVEN** two villagers with simultaneous urgent sleep targeting the same unowned reachable bed, **WHEN** claims resolve, **THEN** exactly one succeeds atomically (winner by stable villager processing order — Edge Case 3) and the loser falls back per Rule 12. [TR-villager-ai-behavior-081]
44. **GIVEN** a villager with an owned reachable bed AND a closer unowned free bed, **WHEN** urgent sleep triggers Deciding, **THEN** it goes to its owned bed — never the closer unowned one (Rule 12 owned-bed preference). [TR-villager-ai-behavior-062]
45. **GIVEN** a standable cell exactly at `wander_radius` distance, **WHEN** the flood-fill runs, **THEN** it is included; one cell beyond, excluded — inclusive boundary, deterministic (F3). [TR-villager-ai-behavior-078]
46a. **GIVEN** `jobs_before_break` consecutive completed jobs, **WHEN** the last completes, **THEN** the villager enters Breather (Rule 7b entry). [TR-villager-ai-behavior-057]
46b. **GIVEN** an active Breather and available jobs, **WHEN** ticks fire, **THEN** no job is claimed for the full `breather_duration_ticks` (claim suppression). [TR-villager-ai-behavior-057]
46c. **GIVEN** an active Breather and a mocked urgent need, **WHEN** the need registers, **THEN** the Breather is preempted normally (needs win). [TR-villager-ai-behavior-057]
47. **GIVEN** `starting_villager_count` = N (mocked config), **WHEN** world generation completes, **THEN** exactly N villagers exist at valid standable cells (Rule 14b). [TR-villager-ai-behavior-065]

**Added by the 2026-07-10 re-review**
48. **GIVEN** a Breather with no preemption, **WHEN** `breather_duration_ticks` elapse, **THEN** the villager returns to Deciding and job-claiming resumes on the next Deciding pass (Breather normal exit). [TR-villager-ai-behavior-057]
49. **GIVEN** a Voxel World write NOT intersecting a moving villager's remaining movement cells or their clearance envelope, **WHEN** the signal fires, **THEN** zero re-path evaluations occur for that villager — assert call-count == 0 (Rule 10b negative case; the filter's entire perf purpose). [TR-villager-ai-behavior-012]
50. **GIVEN** an occupant with at least one strictly-farther and one strictly-closer standable adjacent cell relative to the requester, **WHEN** vacating via F4, **THEN** the chosen cell strictly increases Chebyshev distance to the requester — never decreases (F4 direction-correctness; guards the corrected inversion). [TR-villager-ai-behavior-079]

*(Evidence-tier note per the project test table: AC1–8, 10–36, 41–50 are
blocking headless unit tests (incl. the 46a/b/c split); AC9, 37, 40, 40b
are blocking integration tests; AC38 is provisional-integration
(Save/Load); AC39 is formally an Advisory/Performance criterion gated at
VS/Full-Vision milestones — not part of the Logic gate, re-tiered
2026-07-10.)* [TR-villager-ai-behavior-096]

**Added by the 2026-07-23 slice revision (anti-stuck safety net)**
51. **GIVEN** a Traveling or Working villager with zero legal steps from its current cell, OR a villager in **any state** whose own current cell has become non-standable (self-sealed), for `unstuck_watchdog_threshold_ticks` consecutive ticks, **WHEN** the threshold is reached, **THEN** it is teleported to a standable, unoccupied cell, any held job claim releases back to the queue, and a `villager_unstuck` event fires with incremented per-villager and total counters (F5, Edge Case 13). [TR-villager-ai-behavior-104]
52. **GIVEN** a villager holding a claimed job at the moment the watchdog rescues it, **WHEN** the teleport occurs, **THEN** the claim releases back to the queue exactly as Rule 6's unreachable-job flow — no double-release, no orphaned claim; **GIVEN** a villager with no held claim (e.g. Traveling to a bed), **THEN** no claim-release side effect occurs and bed ownership is unaffected (F5). [TR-villager-ai-behavior-104]
53. **GIVEN** the watchdog's search finds no standable, unoccupied cell within `unstuck_rescue_search_radius`, **WHEN** the search completes, **THEN** the radius doubles (up to `unstuck_rescue_max_radius`) before a rescue defers to the next tick, and a `villager_unstuck_search_failed` event fires exactly once for the stuck episode, not once per tick (Edge Case 14). [TR-villager-ai-behavior-105]
54. **GIVEN** a build-job completion that would leave its builder with zero legal steps, **WHEN** the write is evaluated, **THEN** it is refused, the claim releases back to the queue, and `abandon_count` for that (job, villager) pair increments by 1 (F6, Edge Case 15). [TR-villager-ai-behavior-106]
55. **GIVEN** a dig or demolition job whose completion would leave the builder with zero legal steps, **WHEN** the write is evaluated, **THEN** it proceeds unconditionally — dig/demolition jobs never trigger seal-prevention refusal (F6 exemption, Rule 16). [TR-villager-ai-behavior-106]
56. **GIVEN** the same (job, villager) pair refused `seal_prevention_abandon_limit` times, **WHEN** the villager attempts the job again, **THEN** the write proceeds unconditionally regardless of the trap check (F6 livelock escape, Edge Case 16). [TR-villager-ai-behavior-107]
57. **GIVEN** a dig job whose only onsite position (Rule 5) is directly above the target cell, **WHEN** onsite eligibility is evaluated, **THEN** that position is excluded — the villager must approach from an orthogonal side (Rule 17, Edge Case 17). [TR-villager-ai-behavior-108]
58. **GIVEN** `claim_job` succeeds, **WHEN** the claim record is inspected, **THEN** the claiming villager's id is recorded on it and retrievable for the Building System's project `worker_ids` aggregation (Rule 4 attribution). [TR-villager-ai-behavior-097]
59. *[Historical evidence citation, Advisory — not a repeatable production-code AC]* **GIVEN** the automated E2E hut-build regression run during the vertical slice, **THEN** a real Unstuck Watchdog rescue fired at least once (see `prototypes/last-seal-vertical-slice/REPORT.md`, Feel Assessment) — cited as existing evidence the mechanism activates under real play conditions, not only synthetic unit tests. [TR-villager-ai-behavior-109]

*(Evidence-tier addendum: AC51, 52, 54, 55, 56, 57, 58 are blocking
headless unit tests; AC53 is a blocking integration test (search-radius
expansion needs a multi-cell fixture); AC59 is Advisory/historical —
already-observed evidence, not a repeatable gate.)*

## Open Questions

1. **Needs & Mood interface confirmation** — **RESOLVED 2026-07-10**
   *(text updated at the needs-mood review's verification pass — the
   prior wording contradicted the patched Interactions row)*:
   `needs-mood-system.md` confirms the interface — QUERYABLE per-need
   state with edge events as latency hints (its Core Rule 3;
   urgency_threshold=25, satisfied_threshold=95), source-scored recovery
   via the 3-tier ladder (sheltered bed 1.0 / unsheltered bed 0.7 /
   ground 0.4 — shelter flag from Build Validation), reported via
   discrete `start_recovery`/`stop_recovery` calls carrying the 5-value
   source ENUM (bed_sheltered / bed_unsheltered / ground_no_bed_owned /
   ground_bed_unreachable / ground_trapped — its Core Rules 4/10/11),
   all thresholds/multipliers registered constants.
2. **AI architecture** — **RESOLVED 2026-07-11 via ADR-0008: plain explicit
   FSM** (enum state + one function per state, matching this GDD's fixed
   6-state/strict-discrete-priority design directly) — not a behavior tree
   or utility-AI layer, both rejected as solving a flexibility/blended-
   scoring problem this GDD's design doesn't have. Deciding-pass
   staggering (a per-tick budget + stable-order FIFO queue) and an
   explicit no-threading decision (single-threaded, `WorkerThreadPool`
   named only as a future escape hatch) are also settled by ADR-0008.
3. **Pathfinding algorithm + re-path storm cost** — **algorithm choice
   RESOLVED 2026-07-11 via ADR-0007: `AStar3D`** (manually-populated graph
   of standable cells + legal-step connections, incrementally patched on
   Voxel World writes; not `NavigationServer3D`, no `AStarGrid3D` class
   exists in Godot 4.7). **Still open**: whether N villagers re-pathing on
   every Voxel World write signal needs throttling/batching at scale —
   owned by the Villager AI Execution & Threading Strategy ADR (not yet
   written). Also added by the 2026-07-10 re-review:
   (a) **mid-path solidification race** — **RESOLVED 2026-07-11 via
   ADR-0009**: a villager's occupied cell is always the discrete,
   tick-boundary-quantized `current_cell` (occupies `from_cell` for the
   whole transit, never `to_cell` until arrival); continuous interpolation
   is purely cosmetic and never consulted by any occupancy/logic query.
   The residual visual-clipping window is closed by Godot's synchronous
   signal emission — a Voxel World write's re-path-filter notification
   fires in the same call stack as the write, redirecting the villager
   before the next frame's interpolation advances further. This same
   `current_cell` also serves F4 targeting and Edge Case 2 walled-in
   queries identically (see building-system.md OQ 3b for the reciprocal
   note) [TR-villager-ai-behavior-046]; (b) **job-queue scan cost** — now bounded
   per-pass by `max_selection_candidates` (15), but aggregate cost across
   30 villagers remains the ADR's to architect; (c) **wander flood-fill
   aggregate cost** at the population ceiling (small, but include it in
   the spike scope). **The pre-VS performance spike must include a
   synthetic 30-villager stress case** (unreachable-job-dense + parallel
   construction write-storm at 3x warp) even though VS ships with 5 —
   cheap insurance against discovering a structural flaw after Alpha
   content lands (2026-07-10 review recommendation). [TR-villager-ai-behavior-047] Re-review
   additions to the stress scope: synchronized mass-Deciding spikes
   (Rule 10c's stagger under test), Breather step-away/bed-drift
   pathing costs, and Rule 10b's widened all-movement filter scope.
   The per-tick selection budget behind Rule 10c's stagger directive
   is a core deliverable of that ADR. Added 2026-07-10 by the Build
   Validation review: (d) **region flood-fill cost on a sprawling
   MERGED-STRUCTURE world** — Build Validation's region re-analysis
   scales with connected build footprint, NOT villager count (its OQ 5
   axis (b)); the spike must include this case independently of the
   30-villager population stress. → *AI ADR + the
   performance spike before Vertical Slice*
4. **Day/night rhythm** — the concept's "day schedules" (work by day,
   sleep by night) layers on top of the need-driven MVP. Requires a
   day/night clock nobody owns yet (Time & Tick extension?). → *Needs &
   Mood or Professions GDD, Alpha; flag to Time & Tick when scheduled*
5. **Villager identity generation** — names, appearance variation,
   personality seeds (feeds diaries/bonds later). Who owns it and when?
   → *narrative-director / world-builder, Vertical Slice*
6. **Distress cue treatment** — exact visual for trapped/ground-sleeping
   villagers (Edge Case 2, Rule 12). → *art bible + Villager Info UI GDD*
7. **Villager behavior during waves** — flee, hide, keep working?
   → *Wave Defense GDD, after the `/prototype wave-defense` spike*
8. **Bed assignment affordance** *(added by the 2026-07-10 review)* —
   the player never chooses WHO lives WHERE (Rule 11 is
   first-claim-permanent). Fine at MVP (1 villager); at VS+ the
   stewardship fantasy ("they live in what I built") may want a
   reassignment affordance. → *VS revision of this GDD + Villager Info
   UI (a "reassign bed" interaction candidate)*
9. **Engine-reference documentation gaps** *(found by the 2026-07-10
   review)* — `docs/engine-reference/godot/` lacks entries on 4.5+
   physics interpolation (relevant to movement smoothness at warp) and
   4.4+ typed Dictionaries (relevant to the grid-walk hot paths). →
   *engine-reference refresh before the AI/building ADRs*
10. **Extreme-tuning travel caveat** — at max world size (256×256) and
   min `move_speed` (1.5), a villager can spend 340+ game-seconds
   traveling with its need pinned at 0 (harmless per Needs Rule 5, but
   long floor-value stretches). Note when retuning world size or speed.
   → *tuning documentation, no design change*
11. **Production-grade replacement for the anti-stuck safety net** *(added
   by the 2026-07-23 slice revision)* — the Unstuck Watchdog and Seal
   Prevention (Rules 15–17) are a validated INTERIM safety net, not the
   fix: the vertical slice's own recommendation (see
   `prototypes/last-seal-vertical-slice/REPORT.md`, "If Proceeding" §1)
   is that build-order planning (outside-in, roof-from-edge sequencing)
   and scaffolding/ladders are the real solution to villagers sealing
   themselves in. Until that production work lands, the watchdog/seal-
   prevention rules stay in place, and the `villager_unstuck` telemetry
   (Rule 15, Dependencies) is the required sizing input for that work —
   do not remove the safety net when the production fix ships without
   first confirming the telemetry shows near-zero rescues. →
   *game-designer / ai-programmer, Production milestone*
