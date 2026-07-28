# Sprint 10 — Working Days 91–100 (nominal anchor 2026-07-27) — THE PAYOFF SPRINT

> **Sizing is in stories and sprint-sessions, not agent-days** (milestone-02 Notes). Per-story day
> figures below are **relative-complexity anchors**, never calendar predictions.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **S09 opened the payoff spine. S10 closes it.** Both halves of criterion #5 now exist on disk and
> green: build-validation 001–006 (candidate cells → regions → outside-connection trace →
> ROOM/SEALED → pass lifecycle → shelter classification + `shelter_status_changed`) and needs-mood
> 001–003 (config + BLOCKING ladder invariant → decay + urgent → the three-rung recovery ladder).
> What does **not** exist is the wire between them: no villager can claim a bed, no bed can be
> placed, and no needs value has ever been read by a real villager. **This sprint builds that wire
> and pulls it tight in one test — `needs-mood-010`, the milestone's reason to exist.**

---

## ⚑ The crown: `needs-mood-010` (AC34, milestone criterion #5)

**Why this and nothing else.** The milestone's own Cut-Lever Policy names **end of S10** as
checkpoint #1, and the signal it checks is literally *"Cluster A's build-validation + needs-mood
stories are not both feature-complete, with criterion #5's live-pair test green → trim steps 1–2
(drop C4 and C3)."* S10 is therefore not a sprint that *works toward* criterion #5; it is the sprint
the criterion is **measured at**. Every Must story below is either the crown or something the crown
cannot run without.

**Its dependency closure, verified in each story file's own `## Dependencies` header — not from a
summary table:**

```
needs-mood-010  ← 003 ✓Complete, 004, 006, 007, 008          (in-epic)
                ← villager-ai-018                             (external, must be REAL)
                ← building-028 → 016                          (external, must be REAL)
                ← build-validation shelter classification ✓    (bv-006, Complete 2026-07-26)
   needs-mood-006 ← 002 ✓, 005          needs-mood-007 ← 003 ✓, 005
   needs-mood-008 ← 002 ✓, 003 ✓, 005   needs-mood-004 ← 003 ✓  (independent — start any time)
   villager-ai-018 ← 006 ✓, 009 ✓, 011 ✓  (ALL Complete — schedulable on day one)
   building-028   ← 021 ✓, 022 ✓, RID ✓   building-016 ← 002 ✓
```

That is **9 stories + the crown = 10 Must**, converging from **three lanes** into one integration
test. The three-lane convergence is this sprint's single most important structural fact and it is
strictly worse than S09's one cross-lane handoff — see Critical Path.

---

## ⚑ Two dependency defects found while verifying the crown (surfaced, not absorbed)

Both were found by reading story files rather than trusting tables. Neither is fabricated.

**F1 — `needs-mood-010` contradicts itself about whether the bed must be real.**
Its **Dependencies** section says the furniture chain `building-028 → 016 → 017` must be *"landed and
REAL, not mocked."* Its **Implementation Notes** say *"Mock only what is outside the seam (world
grid, job queue, **the bed's existence**)"*, and its **Out of Scope** section explicitly lists
*"Furniture chain (`building-028 → 016 → 017`): placing and building the bed."* These cannot all be
true.

The seam under test is **Needs ↔ Villager AI**, and that is the only seam the story forbids mocking.
**This plan resolves the contradiction toward the Implementation Notes** and schedules `028 → 016`
(so the bed is a real placeable, buildable, claimable entity — milestone criterion #6's own wording)
while **deferring `017`**. Rationale: `building-017`'s own header depends on `building-009` **and**
`building-015`; `015` depends on `009` + `012`; `012` depends on `009` + `011`. Closing `017`
therefore costs **four extra stories on the Cluster C tier C1 chain** and buys only the
*demolition* half of furniture — which criterion #5 does not exercise. Recorded as **D8** below for
a user ruling; if overturned, S10 grows by 4 stories and the crown moves to S11.

**F2 — `needs-mood-009` claims to unlock `needs-mood-010`; `needs-mood-010` does not list it.**
`009`'s Dependencies read *"Unlocks: 010 (the live pair should run against ratified values)"*, but
`010`'s own Dependencies list is `003, 004, 006, 007, 008` — no `009`. **The consuming story's own
header is authoritative**, so `009` is treated as non-blocking and deferred to S11 (its doc AC is
repo-wide and crosses GDD ownership — open decision D6, still unresolved). Flagged so nobody later
reads `009`'s Unlocks line as a missed dependency.

*(A third, milder asymmetry: `building-028`'s Unlocks names `016`, but `016`'s own Dependencies name
only `building-002` ✓. Sequenced `028 → 016` per the epic's stated direction; they are **not**
serially blocked, so a `028` slip does not stall `016`.)*

---

## Sprint Goal

**Close milestone criterion #5.** Complete the Needs & Mood epic's remaining formula surface
(`004` interruption/re-rating, `005` mood smoothing, `006` spawn init, `007` why-string,
`008` burst/pause/warp determinism), land the two halves the payoff needs from the outside — bed
claiming (`villager-ai-018`) and a real placeable bed (`building-028 → 016`) — then pull them tight
in the unmocked live pair (`needs-mood-010`). In parallel, give the villager a **body**
(`presentation-003`) so the criterion's run-level capture is a picture rather than a log, and so
S11's three blocked `villager-info-ui` stories and the first external playtest (R8) are not standing
on an invisible settlement. Capacity-permitting, extend Build Validation's signal surface
(`bv-007 → 008`, with `009` as the criterion-#7 wiring) and clear the S09 carry-forward
(`building-011`) plus the C1 opener (`building-009`).

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved. **Named consumers, declared up front (the S08/S09 practice):**
  1. **PRIMARY — `needs-mood-010`'s three-lane convergence.** It is the only story in the sprint
     whose inputs come from three separate lanes, it is the last thing to run, and every S09
     precedent says the last integration story is where the surprise lands (`scene-005` measured a
     9082 ms boot against a 3.0 s ceiling on first run; `bv-010` measured 183.55 s against a 60 s
     ceiling). **Named lever, taken from the story's own Implementation Notes:** the full anchor is
     ~1072 ticks to urgent — *seed the need lower for the fast path and run the full anchor exactly
     once*; if the ordering assertion (`need_urgent` → `start_recovery` → `need_satisfied` →
     `stop_recovery` → Deciding) still fails, escalate to technical-director rather than relaxing
     the assertion.
  2. **SECONDARY — `presentation-003`.** Its **story file does not exist**; it is a TD spec
     (VB-2), not a storied AC set, and it touches ADR-0004 collision-layer allocation and
     ADR-0009's `_visual_position` grep guard (which TD item 13 says must be *re-scoped* from a
     filename check to a call-site allowlist). **Named lever:** if authoring reveals it is larger
     than 1.0–1.5, ship VB-1 only (body + `get_visual_position()`) and defer the hit proxy /
     slice hook to S11 — the three `villager-info-ui` stories need the hit proxy, and they are S11.
- **Available:** 8 days
- **Committed:** Must 10 stories = 10.5 story-days *(serial sum)*; Should 3 = 3.0; Nice 2 = 1.5.
- **Measured cadence:** S1–S9 = 8, 9, 9, 8, 8, 13, 12, 13, 18 stories/session, all landing their
  full commit set with zero carryover. **15 stories is inside the band.** Throughput is not the
  binding constraint; the binding constraints are (1) the three-lane convergence on the crown and
  (2) the two still-unratified ruling documents.

### Parallel-lane capacity model

| Lane | Owner | Must sequence | Must lane-days |
|---|---|---|---|
| **A — the crown lane** | `ai-programmer` | `villager-ai-018` → *(Should)* `bv-007` → **`needs-mood-010`** | 2.5 |
| **B — the binding lane** | `godot-gdscript-specialist` *(domain review: `systems-designer`)* | `nm-005` → `nm-004` ∥ → `nm-006` → `nm-007` → `nm-008` → *(Should)* `bv-008` → *(Nice)* `bv-009` | 4.5 |
| **C — substrate lane** | `godot-specialist` | `building-028` → `building-016` → `presentation-003` → *(Should)* `building-011` → *(Nice)* `building-009` | 3.5 |

Max Must lane = **4.5** (lane B), inside 8 with ~3.5 headroom. Adding all Should + Nice takes lane B
to 6.0 and lane C to 5.5 — still inside 8, but headroom drops to ~2.0.

**Honest read:** the Must set fits comfortably; the full set fits with less room than the day totals
suggest, because **lane B gates the crown and lane A ends with it**. A lane-B slip does not just
delay lane B — it delays the only story the milestone is measured on. That is not visible in a
lane-day sum, and it is why `bv-008`/`bv-009` sit at the bottom of lane B as the named first trim.

### Sprint 9 actuals (calibration context)

- **17/17 scheduled Complete** + `build-validation-006` landed untracked = **18 stories shipped**.
  Suite 953 → **1198**, green with 0 orphans on every story commit, independently re-run by the
  parent at close (1198 cases, 0 errors, 0 failures, 0 flaky, 0 skipped, exit 0).
- **The sprint's real theme was "the game became startable"** — three gaps between *the systems
  work* and *you can play it*, none of which any green suite had revealed: no world existed at boot
  (`scene-005`, boot 2.59 s vs a 3.0 s ceiling), fresh terrain could stay invisible (`vox-020`), the
  player drew blind (`building-023`, which also exposed a real multi-frame drag off-by-one in
  already-shipped `building-021` code).
- **`bv-010`'s corpus found ZERO disagreements** across 9,600 verdicts between Build Validation's
  reachability trace and the villager nav graph — R3's worst case (two shipped implementations
  disagreeing) is retired as a *finding*, though the corpus ships at 1/10 sample density (open TD item).
- **The first QA sign-off in project history** was produced (`qa-signoff-sprint-9-2026-07-26.md`),
  verdict **APPROVED WITH CONDITIONS**. Criterion #14's habit has started.
- **Buffer behaviour:** consumed as designed again (nav-graph 6.7 s remediation inside `scene-005`).
  Ninth consecutive sprint with zero carryover and zero unplanned rework.
- Findings carried in: the recurring fixture trap (sealing a gap with a solid block creates a legal
  step-up and reopens the escape — hit independently twice, **relevant to every new build-validation
  fixture this sprint**); Godot 4.7 cannot `@export` `RefCounted`/`Object` (**directly blocks
  `bv-009`'s CD-Ruling-2 sidecar form — TD concurrence required before it is started**).

## Tasks

### Must Have (the crown and its closure)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| villager-ai-018 | **Sleep & home — bed claim (THE MOVE-IN MOMENT).** First Must to start on lane A; the crown's villager half | `production/epics/villager-ai-behavior/story-018-sleep-and-home.md` | ai-programmer | 1.0 | villager-ai-006 ✓, 009 ✓, 011 ✓ — **all Complete; blocked on nothing** | First urgent sleep + unowned reachable bed → **permanent claim** (AC22); owned reachable bed preferred over a **closer unowned** one (AC23/AC44); no reachable bed → ground sleep at the current cell reporting the **correct widened source enum** (`ground_no_bed_owned` vs `ground_bed_unreachable`, AC24); wake + re-enter Deciding at the (mocked) wake threshold (AC25); bed removed while sleeping → immediate wake + ownership dissolves (AC26); owned-but-unoccupied bed removed → ownership dissolves silently, re-claim at next urgent sleep (AC27). **Bed claiming reuses story-011's atomic-claim primitive — do not write a second claim mechanism.** Needs rates stay MOCKED here (they go live in `needs-mood-010`, not here). Passing integration test |
| needs-mood-005 | **F3 mood smoothing, snap rule, `mean_active` & band events.** ⚑ **FIRST on lane B — it gates three Must stories (006, 007, 008)** | `production/epics/needs-mood-system/story-005-mood-smoothing-and-band-events.md` | godot-gdscript-specialist *(review: systems-designer)* | 1.0 | needs-mood-001 ✓, 002 ✓ (both Complete) | F3 EMA once per villager per tick **after F1/F2**, one step, no history buffer; **explicit float division (`/ 40.0`)** — integer division on an int-typed `mood_smoothing_ticks` silently truncates the EMA step to zero; band boundaries (70/40) are a **display contract shared verbatim with Villager Info UI — one owner, no second copy in UI code**; band changes are crossings between ticks, never equality; **grep guard: zero mood-consuming references in work/scheduling code (Rule 8 — MVP mood is display-only, statically checkable)**; passing unit test |
| needs-mood-004 | **Recovery interruption, mid-recovery re-rating & bed revocation.** Independent — start it in parallel with `005` | `production/epics/needs-mood-system/story-004-recovery-interruption-and-re-rating.md` | godot-gdscript-specialist *(review: systems-designer)* | 1.0 | needs-mood-003 ✓ (Complete). **Nothing else** | AC30: source enum changes mid-recovery (`bed_unsheltered` → `bed_sheltered`) → **from the next tick the new rate applies with no restart, no signal, no lost progress**, and the mirror downgrade behaves identically; AC13: interrupted above threshold → `Satisfied`, decays, re-triggers `Urgent` only at the next downward 25-cross; AC31: interrupted at/below threshold → `Urgent` **by value** with **zero** second urgent emission; Edge Case 3: `stop_recovery(reason=&"revoked")` credits **zero** recovery that tick; the `reason` argument is **diagnostic only** — proven by a test that three different reasons produce identical value and state; **this system never subscribes to `furniture_revoked` and never holds a bed id** (the circular punt closed on 2026-07-10 — do not re-open it); passing unit test |
| building-028 | **Furniture placement base — single-cell support + palette query.** ⚑ **FIRST on lane C — it is the bed** | `production/epics/building-system/story-028-furniture-placement-base.md` | godot-specialist | 1.0 | building-021 ✓, 022 ✓, RID ✓ — **all Complete** | Furniture entries queried from RID `furniture_fixture` (MVP: `bed`), tier-0 **free** (no resource consumed); requires **support** (cell below occupied — ground or built floor); occupies its cells one-occupant-per-cell; RID definitions are **opaque ids only** — never resolved internally beyond the id; support/availability is O(cells) per commit. ⚑ **Two blocking ACs inherited from BV-1 that did not exist when this story was written: (a) a FURNITURE-category completion NEVER `bulk_write`s to the grid** (this is what makes `build-validation-002`'s furniture-transparency true by construction — breaking it silently breaks a shipped, tested guarantee); **(b) the registry exposes a placed/removed signal + item enumeration as a duck-typed nil-safe provider.** **Re-read the story against BV-1 before starting.** Passing unit test |
| needs-mood-006 | **F4 spawn initialization & new-need activation** | `production/epics/needs-mood-system/story-006-spawn-init-and-need-activation.md` | godot-gdscript-specialist *(review: systems-designer)* | 0.5 | needs-mood-002 ✓; **needs-mood-005 (in-sprint, HARD — needs `mean_active`/bands)** | Initialization in an **explicitly-callable method reached from the boot path — never `_ready()`**, never inferred from scene state; the active-need set from story 001's schema governs what is initialized; **inactive needs are absent, not zeroed**; **mood is never initialized to 0 or to a literal** — the ordering trap this AC exists to prevent is a mood field left at its zero-default displaying **Low** for ~10 s at `ticks_per_second = 4.0` while the EMA catches up (a cold-start *visual* bug, not a math bug); F4 never re-runs on an existing villager; O(active needs) per villager, once per spawn; passing unit test |
| needs-mood-007 | **Why-string selection, templates & UI-slot precedence** | `production/epics/needs-mood-system/story-007-why-string-templates-and-precedence.md` | godot-gdscript-specialist *(review: systems-designer)* | 1.0 | needs-mood-003 ✓; **needs-mood-005 (in-sprint, HARD — mood band for the empty case)** | Why-string composed **here** and consumed **verbatim** by Villager Info UI — the UI never assembles its own from need values (ADR-0001 leaf rule); selection is a **pure function of current state** — no cached "last reason", no sticky string; **a why-string must never name a fix the player cannot take** (a trapped villager is never told "no bed"); all templates in **one table** so a future localization pass has exactly one place to touch; `get_why_string()` is an O(active needs) pure query safe to call per UI refresh; passing unit test. **Consumed by the crown's unsheltered edge case ("sleeping rough — no shelter")** |
| needs-mood-008 | **Burst ordering, pause & warp determinism (full-cycle tick anchors)** — the crown's determinism harness | `production/epics/needs-mood-system/story-008-burst-pause-and-warp-determinism.md` | godot-gdscript-specialist *(review: systems-designer)* | 1.0 | needs-mood-002 ✓, 003 ✓; **needs-mood-005 (in-sprint, HARD)** | Tick-driven via Time & Tick's signal; rates are functions of **tick count, never wall-clock**; **assert against `TimeTickConfig.max_ticks_per_frame` (landed default 12 per the S8 re-tune) — NEVER the literal 10 the GDD prose still says**; threshold signals are **never coalesced or deduplicated across a burst**; a full `max_ticks_per_frame` burst runs F1–F3 for every villager inside the frame budget at the 20–30 population ceiling; **`SceneTree.paused` and `Engine.time_scale` are project-wide forbidden — grep-guarded**; passing unit test |
| building-016 | **Multi-cell furniture placement (footprint)** — the bed is 2 cells | `production/epics/building-system/story-016-multi-cell-furniture-placement.md` | godot-specialist | 1.0 | building-002 ✓ (its own header). Sequenced after `building-028` per the epic's stated direction — **not serially blocked by it** | `footprint` is a fixed list of cell offsets from the picked anchor, authored on `ItemDefinitionResource`, exposed through the **getter-only** `ItemDefinition` (no setters), typed `Array[Vector3i]`; a commit is valid **iff every offset cell independently** satisfies support + availability; **all footprint cells are ONE entity sharing one occupant id** — never N entities for one footprint; **no partial placement** (Core Rules 8/9 apply per cell); `furniture_cell_count` is per-item; O(footprint size) per commit; passing unit test |
| presentation-003 | **Villager body view, hit proxy & slice hook — THE SUBSTRATE THREE EPICS ARE BLOCKED ON.** ⛔ **STORY FILE DOES NOT EXIST — see the authoring gate below** | *(to be authored)* `production/epics/presentation-experience/story-003-villager-body-view-and-hit-proxy.md` | godot-specialist *(`.gd` review: godot-gdscript-specialist)* | 1.0 | villager-ai-021 ✓ (roster is plural — hard for the integration AC only; every unit AC is testable against a mock roster). **Blocked on nothing else** | Transcribed **verbatim** from `production/architecture-decisions-m02-preflight-2026-07-26.md` **VB-1 §1–§6 + VB-2's own AC list** — the AC set is already written there and must **not** be re-invented. Headline shape: body lives in `presentation-experience` / `src/presentation/`, **never in the Core-layer `villager-ai-behavior` epic** (VB-1 §1 rejects that layering inversion by name); `Area3D` hit proxy on ADR-0004 layer 1; ADR-0009's two-layer position model honoured with `physics_interpolation_mode = OFF`; a new `get_visual_position()` presentation accessor per **TD downstream item 13**, which also requires the `_visual_position` grep guard to be **re-scoped from a filename check to a call-site allowlist** (`villager_ai.gd::_process` + `src/presentation/`) — the invariant is unchanged and stays enforced; roster provider is **duck-typed and nil-safe**; presenter create/free loop written against the real `villager-ai-021` roster (N spawn → N bodies; one despawn → one body freed); blocking headless unit tests under `neues-spiel/tests/unit/presentation/` |
| **needs-mood-010** | **⚑ THE CROWN — Live-pair shelter recovery round trip (AC34, MILESTONE CRITERION #5). Sequenced LAST. The milestone's reason to exist** | `production/epics/needs-mood-system/story-010-live-pair-shelter-recovery.md` | ai-programmer *(cross-lane handoff: `GameWorld` wiring is `godot-specialist`'s file)* | 1.5 | **needs-mood-003 ✓, 004, 006, 007, 008 (all in-sprint)** + **villager-ai-018 (in-sprint)** + **building-028 → 016 (in-sprint)** + **bv-006 ✓ shelter classification (Complete)**. Three-lane convergence | **AC34**: a **REAL** Needs & Mood instance and a **REAL** villager with an **owned sheltered bed**, **no mock at that seam** (neighbours — grid, job queue, the bed's *existence* — may still be doubles); decay 100 → urgent → claim → travel → sleep → recover → satisfied → wake, with the sequence **recorded then asserted as a sequence**, not just its endpoints: `need_urgent` → `start_recovery(bed_sheltered)` → `Recovering` → `need_satisfied` → `stop_recovery` → back in Deciding. Recovery scored at **×1.0** (not ×0.7, not ×0.4) — proving Build Validation → source enum → rate end-to-end. **THE SINGLE MOST VALUABLE ASSERTION: the poll-not-event variant** — re-run with `need_urgent` deliberately **unconnected**; the round trip must still complete identically, because state is truth and the event is a latency hint (Core Rule 3). `start_recovery`/`stop_recovery` called **exactly once each** — no per-tick pushes. **Production wiring**: `GameWorld`'s Booting path assigns the real module to Villager AI's `needs_provider`; confirm **no other call site** assigns it. Determinism: two identical runs produce identical tick indices. Edge cases: bed revoked mid-sleep → wake + `stop_recovery` credits zero that tick; unsheltered bed in the same harness recovers at ×0.7 with the why-string reading "sleeping rough — no shelter". **Evidence: `neues-spiel/tests/integration/needs_mood/shelter_recovery_live_pair_test.gd` + a run-level capture in `production/qa/evidence/` (criterion #5 requires BOTH)** |

### Should Have (extend Build Validation's signal surface; clear the S09 carry-forward)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| bv-007 | **`room_recognized` continuity & celebration pacing** — lane A's gap-filler while lane B runs; unblocks `008` and `009` | `production/epics/build-validation-navigability/story-007-room-recognized-continuity-and-pacing.md` | ai-programmer | 1.0 | build-validation-004 ✓, 005 ✓ (both Complete) | The transient snapshot is **edge-detection memory only, never a compute cache**; emissions synchronous within one pass; **never re-fire `room_recognized`** on a re-analysis that keeps a room valid, or on merges/splits of existing valid rooms; **at most one celebration EVENT per `room_cue_cooldown_ticks` (config, 20 ≈ 5 s at the shipped 4.0 ticks/s — the knob was authored against an earlier rate, so read the config, never the prose)** — a same-pass group counts as one event; ticks from Time & Tick, never wall-clock, never `Engine.time_scale`; passing unit test. **The cue itself is CD-protected (Art Bible §5.6) — this story owns the signal contract and pacing only.** ⚑ Open item **D6(i)**: the *celebration stagger* ("the room cue follows the command flourish by a breath rather than stacking") is unspecified in every document that mentions it and still has no presentation-layer owner |
| bv-008 | **Warning/Info tiers, exclusivity & load-pass emissions** | `production/epics/build-validation-navigability/story-008-warning-info-tiers-and-load-pass.md` | godot-gdscript-specialist | 1.0 | build-validation-005 ✓, 006 ✓ (Complete); **bv-007 (in-sprint, HARD — AC31 asserts both silences)** | Warning and Info are **two separate typed signals, not severity payloads of one — do not collapse them**; **level-triggered re-emission** once per qualifying pass; **there is deliberately NO "cleared" signal** — clearing IS the cessation of re-emission plus the queryable state; **exactly four signals total from this system, no others**; Warning supersedes Info, mutually exclusive **per furniture item**; `shelter_status_changed` (bv-006) is independent of both tiers and fires for **all** furniture regardless of type; **no warning** on a sealed space containing only decorative furniture or only a villager; **grace / dismissal-debounce / re-show timing is UI-owned (ADR-0011) and must NOT be implemented here**; passing unit test |
| building-011 | **Plan-only undo/redo (criterion #12)** — **S09 carry-forward, deferred not dropped; the sign-off says pull it early** | `production/epics/building-system/story-011-plan-only-undo-redo.md` | godot-specialist | 1.0 | building-002 ✓, 032 ✓ (both Complete S7) | **Undo NEVER mutates a Built cell** — the existing non-writer grep guard extended to the undo path (full undo of built geometry is rejected: it would make built geometry non-authoritative and bypass ADR-0009's occupancy/seal semantics and the worker-executed mutation contract); undo of a released-but-unbuilt cell removes the pending job; **redo re-creates only still-valid cells, dropping invalidated ones with feedback**; planning/undo behave identically paused or unpaused (raw-delta input path); the stack is bounded (`undo_stack_depth` 50) and **excluded from `serialize()`** (ADR-0012, TR-033); `plan_only_undo_test.gd` passes. **Also unblocks `building-012`** (which its own header shows depends on `009` + `011`) |

### Nice to Have (pull only if lanes B and C clear)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| bv-009 | **Loop-payoff surface receives real signals (criterion #7)** — ⚠ carries an **unresolved external input** | `production/epics/build-validation-navigability/story-009-loop-payoff-real-signal-wiring.md` | godot-gdscript-specialist | 0.5 | build-validation-006 ✓; **bv-007 (in-sprint)**. ⛔ **EXTERNAL: technical-director concurrence on CD Ruling 2's implementation form — do not start without it** | Injected-tier binding only; `setup()` asserts the surface reference is wired; `_ready()` does nothing beyond optionally calling `setup()`; **grep-guard proves zero placeholder/stub emitters remain anywhere on the payoff path**; `LoopPayoffSignalSurface`'s parameter list is **never reshaped** — a new payoff kind is a new `payoff_type` value; **no `CONNECT_DEFERRED` on this path** (it would break Rule 10's one-pass-one-frame reconciliation unit); the wiring adds **no analysis work**. ⚑ **The collision to resolve first: CD Ruling 2 specifies `PayoffDetail` as a typed `RefCounted` sidecar, and S8 measured that Godot 4.7 cannot `@export` `RefCounted`/`Object`.** CD's own scope note permits TD to substitute an equivalent form (`Resource` vs `RefCounted`) provided the five assertable conditions hold. **This is a decision, not a workaround to improvise in code** |
| building-009 | **Demolition orders (blocks) — the Cluster C tier C1 opener, criterion #11** | `production/epics/building-system/story-009-demolition-orders-blocks.md` | godot-specialist | 1.0 | building-002 ✓ (its own header — **nothing else**) | Worker-executed block demolition with `restore_value` write-back; demolition is **job-based and uniform**, no instant-removal carve-out. **Why it is worth pulling even as a Nice:** its own Unlocks line names `010` (Abriss), `012` (floor-excavation restore), `015` (removal-tool branch) **and `017` (furniture demolition reuses this contract)** — it is the single head of the four-story chain that D8 (below) would need if the user rules that criterion #5 requires a *demolishable* bed. Landing it here de-risks that ruling at a cost of one story. Passing unit test |

## Missing Stories (NOT fabricated — recorded for `/create-stories`)

| Story | Status | Who authors it | Blocks |
|---|---|---|---|
| **`presentation-003`** — villager body view, hit proxy & slice hook | **Scheduled as Must in this sprint, file does NOT exist.** Full spec (owner, type, tier, estimate, governing ADRs, sequencing, and the complete AC list) is written in `production/architecture-decisions-m02-preflight-2026-07-26.md` **VB-1 + VB-2** | **Producer** — VB-2 says so verbatim: *"Spec only. The producer authors the story file; I have not written one."* ⛔ **DAY-ONE GATE: author the file before lane C reaches it.** Transcribe VB-1/VB-2's ACs; invent nothing. Then `/story-readiness` before `/dev-story` | `villager-info-ui-002/005/006`, `building-ui-016`'s characters clause, `presentation-001` Sub-B |
| **Mid-range hardware baseline re-measurement** (criterion #13) | **Still does not exist.** voxel-world ends at `story-021`. Two unowned TD decisions block authoring it (target hardware class, VSync mode) | `technical-director` decides, then `/create-stories` in voxel-world | Criterion #13 (protected — **not** on the cut lever) |
| **building-ui epic (18 stories) + villager-info-ui epic (7 stories)** | No epics, no stories. 25 stories, not the milestone's stated ~14 (D3) | `/create-epics layer: presentation` then `/create-stories` — **must happen before S11 planning closes**, exactly as R2 gated S09 | Criterion #10 |

**Not stories — decisions.** Do not let these be written as work: the **VSync-mode** call and the
**target hardware class** definition (both technical-director); **ratification of the two provisional
ruling documents** (user-owned — carried as an input, never scheduled).

## Milestone-Criteria Advancement Map (what this sprint moves)

| # | Criterion | S10 disposition |
|---|-----------|----------------|
| #1 | Build Validation implemented (AC1–35, 37, 38) | **ADVANCES to near-complete** — `007`/`008` (Should) leave only `009` (Nice, TD-gated). After S10 the epic is 8–9 of 9 stories done. |
| #2 | Reachability corpus green ≤ 60 s in CI | **HELD, with an open TD item.** Green at 44.52 s and 0/9,600 disagreements, but at **1/10 the AC's sampling density**. Per the sign-off: the criterion claim must read *"5,000-verdict spec not yet met; the 1,000-verdict shipped configuration is 0/0 disagreement."* **Do not let this sprint silently upgrade that wording.** |
| #3 | Needs & Mood implemented | **CLOSES to its MVP scope** — `004`–`008` complete the formula surface (`009` doc pass S11, `011` Advisory S11, `012` Save/Load VS-tier out of scope). |
| #4 | Real-time-rate pass recorded | **NOT THIS SPRINT** — `nm-009` deferred to S11 pending D6's cross-GDD ownership call. Non-blocking for the crown (see finding **F2**). |
| #5 | **Payoff loop closes live-pair** | **⚑ THE TARGET.** Chain 1 (build-validation → needs-mood → AC34) completes via `004`/`006`/`007`/`008`; chain 2 (furniture → bed claim → AC34) completes via `028 → 016 → villager-ai-018`; both converge in `needs-mood-010`. **This is the criterion the end-of-S10 cut-lever checkpoint measures.** |
| #6 | Furniture placeable, buildable, claimable | **PLACEABLE + BUILDABLE + CLAIMABLE land** (`028`, `016`, `villager-ai-018`). **Removal/revocation does NOT** — `building-017` deferred (see D8). Criterion #6's wording covers *"removing it dissolves ownership and wakes the sleeper"*, which is proven **mocked** in `villager-ai-018` AC26/AC27 and **not** end-to-end. **Honest status: criterion #6 is 3/4 after S10.** |
| #7 | `presentation-002` signals something real | **Nice-to-have, TD-gated** (`bv-009`). Blocked on TD concurrence + the `@export RefCounted` collision. |
| #10 | Building UI + Villager Info UI ship | **UNBLOCKED FURTHER, NOT STARTED.** `presentation-003` removes the substrate blocker on 3 of villager-info-ui's 7 stories. Cluster D is S11+; **its epics must be created before S11 planning closes.** |
| #11 | Lifecycle breadth — demolition | **OPENS as a Nice** (`building-009`, tier C1's head). C1 is criterion-#11-protected and never on the lever. |
| #12 | Plan-only undo is real | **Should** (`building-011`) — the S09 carry-forward. |
| #13 | Mid-range hardware baseline | **STILL NO STORY, still two unowned decisions.** Escalated for the third consecutive sprint — see D4/E1. |
| #14 | `/team-qa sprint` sign-off every sprint | **HABIT CONTINUES.** S09 produced the first one ever. S10 runs `/team-qa sprint` **and** produces the consolidated smoke artifact the S09 sign-off's condition #4 asked for. |

## Critical Path

**Three lanes converge on one story.** This is the sprint's defining structural fact:

```
lane A  villager-ai-018 ─────────────────────────────────┐
lane B  nm-005 → ┬ nm-006 ┐                              │
                 ├ nm-007 ┼→ (with nm-004, independent) ──┼→  needs-mood-010  (THE CROWN)
                 └ nm-008 ┘                              │
lane C  building-028 → building-016 ──────────────────────┘
```

- **Longest serial chain: `nm-005 → nm-008 → nm-010`, depth 3 + crown, ~3.5 lane-days.** Lane B's
  opener `nm-005` gates *three* Must stories — **start it on day one**, ahead of `nm-004` even
  though `nm-004` is also unblocked.
- **Start `villager-ai-018` and `building-028` on day one too.** Both are blocked on nothing, both
  feed the crown, and both sit on lanes that are otherwise idle while lane B runs.
- **Do not let `needs-mood-010` sit on the last day.** It is the only story the milestone's S10
  checkpoint measures, and it is the buffer's primary named consumer. If lane B is not clear by
  ~day 6, trim `bv-008` and `bv-009` immediately rather than compressing the crown.
- **One cross-lane file handoff inside the crown**: `needs-mood-010`'s production-wiring AC edits
  `GameWorld`'s Booting path — a `godot-specialist` file being changed by the `ai-programmer` lane.
  Serialize it against anything lane C has open in `game_world.gd`.

**Recommended trim order, if one is needed** (decide at mid-sprint, on signal):
1. **`bv-009` (Nice)** — it is externally blocked anyway (TD concurrence + the `@export RefCounted`
   collision). Cutting it costs nothing this sprint.
2. **`building-009` (Nice)** — unless D8 is ruled toward "the bed must be demolishable", in which
   case it becomes the head of a mandatory chain and must **not** be cut.
3. **`bv-008` (Should)** — positional value only; `bv-009` is its only consumer and that is already
   trimmed at step 1.
4. **`building-011` (Should)** — already deferred once; deferring twice is a signal worth noticing,
   not a free move. Prefer trimming `bv-008` first.
5. **Never trim**: any Must, `presentation-003` (it is the S11 unblocker and the crown's evidence
   quality depends on it), or the `/team-qa sprint` sign-off + consolidated smoke artifact.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| `building-011` (plan-only undo/redo) | Deliberately moved to S10 mid-sprint on the producer's own trim recommendation — the Nice item on a lane that became gated. Sign-off §13 says "deferred, not dropped; pull early in S10". **Scheduled as Should.** | 1.0 |
| `presentation-003` (villager bodies) | TD-specced in the S09 pre-flight, story file never authored. Sign-off §13 calls it *"the most consequential open item for S10 planning"*. **Scheduled as Must, with a day-one authoring gate.** | 1.0 |
| `needs-mood-004`–`011` | Epic remainder. `004`–`008` scheduled as Must; `009` deferred (F2 + D6); `010` is the crown; `011` is Advisory and depends on `010` — S11, run with the R8 playtest. | — |
| `build-validation-007`–`009` | `007`/`008` Should, `009` Nice (TD-gated). | — |
| `needs-mood-009`'s stale-real-time pass | Deferred to S11. Not a capacity call: **D6(ii) is unresolved** — the sweep's doc AC is repo-wide but `design/gdd/building-system.md`'s F3 table and both `base_demolition_ticks` mirrors are 2× stale and are **not `nm-009`'s to edit**. Confirm cross-GDD authority or split the story first. | 1.0 (S11) |
| `bv-010`'s corpus density escalation | **Not a story — an open technical-director decision.** Carried per sign-off §13. Root cause is the fixed per-seed cost (terrain gen + full `VillagerNavGraph.build()` per seed), not pair count. **Note the S09 nav-graph finding bears directly on it: `nav_region_size` 200 → 40 cut that build from 6697.6 ms to 266.6 ms — the corpus may be re-measurable at higher density for free.** Flag to TD. | — |
| `build-validation-006`'s untestable `is_need_functional` true branch | Becomes testable **the moment `building-028` lands this sprint**. **Folded into `building-028`'s DoD**: re-verify bv-006's need-functional branch non-vacuously against a real `ItemDefinitionResource`, per the same discipline already applied to BV-1's furniture-transparency guard. | 0 (folded) |

## Sign-Off Conditions Carried In (from `qa-signoff-sprint-9-2026-07-26.md`)

Handled here explicitly so none of them silently lapses:

| Condition | S10 disposition |
|---|---|
| **#1 — Both provisional ruling documents remain unratified** | **User-owned. NOT scheduled as work.** Carried as an inbound external dependency. This plan proceeds AS IF ratified, same posture as S8 and S09. Blast radius is smaller this sprint than last: no S10 Must story is *created* by a ruling, and the only AC-shape exposure is `bv-009` (CD Ruling 2), which is already Nice and already externally gated. |
| **#2 — Mid-sprint additions can miss `sprint-status.yaml`** *(scope: one story, `bv-006`, per the Parent Verification Addendum — not four)* | **Process fix in the DoD**: any story added to S10 after this plan is written must be entered in `sprint-status.yaml` **and** re-checked against the QA plan **before** sign-off, not after. |
| **#3 — `building-023`'s evidence countersignature** | One-line doc edit: point that evidence doc's Sign-off line at `qa-signoff-sprint-9-2026-07-26.md`. **Folded into the DoD as a doc task, not a story.** |
| **#4 — No consolidated smoke artifact per sprint** | **Fixed this sprint.** `production/qa/smoke-[date]-sprint10.md` is a named DoD line item produced at hand-off, not reconstructed from the last story's evidence doc. |
| **#5 — `bv-010` runs at 1/10 the specified sampling density** | Carried as a TD decision (above). **Criterion #2's wording must stay honest** — see the advancement map. |
| **§13 — `building-023`'s art-bible material-tint follow-on** | **No action, deliberately.** No colour-resolution utility from item id to real material colour exists anywhere yet (even the terrain mesher's block colouring is an explicit debug placeholder). Registered as `TR-building-system-093`; revisit when RID colour/texture resolution lands. **Watch item, not scope.** |
| **§10 — the recurring fixture trap** (sealing a gap with a solid block creates a legal step-up and reopens the escape — hit independently twice) | **Named in this plan so the third occurrence does not happen**: every new build-validation fixture in `bv-007`/`bv-008` must assert the seal is still sealed *after* the sealing write, not assume it. |

## Out of Scope (deferred from S10, with honest reasons)

- **`building-017` (furniture demolition)** → S11, pending **D8**. Its own header depends on
  `building-009` **and** `building-015`; `015` depends on `009` + `012`; `012` depends on `009` +
  `011`. Four extra stories to land the demolition half of furniture, which criterion #5 does not
  exercise. `building-009` is pulled as a **Nice** so the chain has its head if D8 rules the other way.
- **`building-012`, `building-015`, `building-010`, `building-006/007/008`, `building-018`,
  `building-013/014`, `building-031`, `villager-ai-017`** — Cluster C. C1's head (`009`) is a Nice;
  the rest is untouched. **The cut lever is NOT pulled this sprint** — see the note below.
- **`needs-mood-009`** → S11 (F2 + D6(ii) above). **`needs-mood-011`** (game-feel probe, Advisory)
  → S11, run in the same session as the first external playtest (R8), which the milestone schedules
  *after* criterion #5 goes green.
- **`needs-mood-012`** (Save/Load) and **build-validation AC26** — VS-tier, explicitly out of M02.
- **Cluster B entirely** (`villager-ai-019`, `013`, `020`, `presentation-001` Sub-B) → **S11, and it
  should open S11.** ⚑ **Note a change: `presentation-001` Sub-B now has an in-epic prerequisite it
  did not have when it was deferred — `presentation-003`** (TD downstream item 16). S10 lands that
  prerequisite, and Cluster A lands the hosts the three unwired ambient components need (room
  recognition → chimney-smoke occupancy; furniture placement → interior clutter). **After S10,
  Cluster B is genuinely the cheapest, highest-mood-value cluster and every one of its blockers is
  gone.** CD-protected; surfaced, not silently dropped.
- **Cluster D entirely** (25 stories) → S11+. **Its two epics still do not exist** — create them
  before S11 planning closes, exactly as R2 gated S09.
- **`villager-ai-023`** (scene-transition continuity, Cluster 0) → S11+. Deferred on value for the
  second sprint: nothing the player sees, no criterion depends on it, no scheduled story lists it.
- **Roof formations beyond Flat, doors/windows as objects, wall-coverage, mood consequences, audio,
  economy** — VS-tier per the milestone's Out of Scope section.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **`needs-mood-010` is a three-lane convergence sequenced last, and it is the only story the end-of-S10 cut-lever checkpoint measures** — a slip anywhere on lanes A, B or C lands on it | **High** | **High** | Buffer's **primary named consumer**. Day-one starts on all three lanes (`nm-005`, `villager-ai-018`, `building-028`). Named lever from the story itself: seed the need lower for the fast path, run the full ~1072-tick anchor exactly once; escalate to TD rather than relaxing the ordering assertion. **Mid-sprint trip-wire: if lane B is not clear by ~day 6, cut `bv-008`/`bv-009` immediately.** |
| **`needs-mood-010`'s own file contradicts itself on whether the bed must be real** (Dependencies say the full furniture chain incl. `017`; Implementation Notes say the bed's existence may be mocked; Out of Scope lists the chain) | **High** | **High** | Resolved in-plan toward the Implementation Notes (real `028`+`016`, `017` deferred) and escalated as **D8** for a user ruling. **If overturned, S10 grows by 4 stories (`009 → 011 → 012 → 015 → 017`) and the crown moves to S11** — which is exactly what the milestone's own success test ("criterion #5 green by end of S11") already allows. `building-009` is pulled as a Nice to pre-buy the chain's head. |
| **`presentation-003` has no story file** — it is a TD spec, scheduled as a Must, and it is a *new* kind of work for this project (first `Node3D`/`Area3D` presentation entity with a collision-layer allocation) | Medium | Med-High | Buffer's **secondary named consumer**. Day-one authoring gate by the producer, transcribing VB-1/VB-2 verbatim with nothing invented, then `/story-readiness`. Named lever: ship VB-1 only (body + `get_visual_position()`) and defer the hit proxy/slice hook to S11. **Cross-check TD item 13 first** — the `_visual_position` grep guard must be re-scoped from a filename check to a call-site allowlist, or the story's own grep AC contradicts a landed guard. |
| **`building-028` inherits two blocking ACs from BV-1 that did not exist when it was written** — FURNITURE-category completion must never `bulk_write` to the grid, and the registry must expose a duck-typed nil-safe provider | Medium | **High** | The first of those is what makes `build-validation-002`'s furniture-transparency guarantee true **by construction** — breaking it silently breaks a shipped, tested, green invariant with no test to catch it. **Re-read `building-028` against BV-1 before starting it** (this plan's AC column carries both). Fold bv-006's now-testable `is_need_functional` true branch into the same story's DoD. |
| **Both pre-flight ruling documents are still PROVISIONAL** after a full sprint | Medium | Medium | **Lower blast radius than S09**: no S10 Must story is *created* by a ruling (S09's `villager-ai-026` was), and the only AC-shape exposure is `bv-009`, already Nice and already externally gated. Every affected story names its ruling in-line. |
| **`bv-009` collides with a measured S8 finding**: CD Ruling 2 specifies `PayoffDetail` as a typed `RefCounted`; Godot 4.7 cannot `@export` `RefCounted`/`Object` | Medium | Low-Med | Kept as **Nice** with an explicit "do not start without TD concurrence" gate. CD's own scope note permits TD to substitute an equivalent form (`Resource` vs `RefCounted`) if the five assertable conditions hold. **This is a decision, not a code workaround.** |
| **The recurring build-validation fixture trap** — sealing a gap with a solid block creates a legal step-up and reopens the escape; hit independently **twice** in S09 | **High** | Low-Med | Named explicitly in `bv-007`/`bv-008`'s guidance: assert the seal is still sealed *after* the sealing write. Cheap to check, expensive to debug blind. |
| **Criterion #6 will be 3/4 after S10** (placeable ✓ buildable ✓ claimable ✓, revocation only mocked) | Medium | Medium | Stated honestly in the advancement map rather than claimed as met. Resolution rides on **D8**. |
| **Criterion #13 has no story and two unowned decisions, for the third consecutive sprint** | **High** | Medium | Escalated again as **E1**. It is a **protected** criterion — it cannot be traded away on the cut lever, so an unowned decision here converts directly into milestone risk. Recommend the user assign the hardware-class call this sprint so the story can be authored for S11. |
| **Cluster D is 25 stories with zero epics, and S11 is where it starts** | **High** | Medium | Same standing risk as S09's D3. **Recommended action this sprint: run `/create-epics layer: presentation` + `/create-stories` as an S11 planning gate**, exactly as R2 gated S09 — that gate worked. |
| **Godot 4.7 API deviations beyond the LLM cutoff** — S10 is lighter than S09 on engine surface, but `presentation-003` is squarely in a post-cutoff-change domain (`Node3D`/`Area3D`/collision layers) | Medium | Low-Med | Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01 and S09. |
| **Recurring typed-Array crash class** (0 occurrences S1–S9) | Low | Low | Regression call retained in the E2E gate; watched on `building-016`'s typed `Array[Vector3i]` footprint field. |

## Dependencies on External Factors

- **USER RATIFICATION of the two pre-flight ruling documents** —
  `production/architecture-decisions-m02-preflight-2026-07-26.md` and
  `production/creative-decisions-m02-preflight-2026-07-26.md`. Outstanding since 2026-07-26.
  **Not scheduled as work — this is a signature, not a task.**
- **USER RULING on D8** (does criterion #5 require a *demolishable* bed?). Decides whether S10 is
  15 stories or 19, and whether the crown lands in S10 or S11.
- **TD concurrence on CD Ruling 2's implementation form** — gates `bv-009` (Nice). Carries the
  `@export RefCounted` collision.
- **TD decision on `bv-010`'s corpus density** — carried from the sign-off. **New input available**:
  S09's `nav_region_size` 200 → 40 retune cut `VillagerNavGraph.build()` from 6697.6 ms to 266.6 ms,
  and that fixed per-seed cost is the corpus's measured root cause — higher density may now be free.
- **Target hardware class + VSync-mode decisions** — both technical-director, both still unowned,
  both blocking criterion #13's story from being authored. Third sprint carrying this.
- **D6(ii): cross-GDD authority for `needs-mood-009`'s repo-wide annotation sweep** — must be
  confirmed or the story split, before S11 schedules it.
- **Control-manifest version 2026-07-23** — every S10 story embeds it. Confirmed current S1–S9;
  re-confirm unchanged before the lanes start. Owner: technical-director.
- **No art/audio external dependency** for the committed set. `presentation-003` is Art-Bible-governed
  (§5.2 two-block scale, §5.3 accent channel) but ships primitive/placeholder geometry, not new art.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed — **criterion #5's live pair is green** and the villager has a body
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (`nm-004`, `nm-005`, `nm-006`, `nm-007`, `nm-008`, `building-028`,
      `building-016`, `building-011`, `bv-007`, `bv-008`, `building-009`) has a passing GdUnit4
      headless unit test under `neues-spiel/tests/unit/…` — **BLOCKING**
- [ ] Every Integration story (`villager-ai-018`, `needs-mood-010`, `presentation-003`, `bv-009`)
      has a passing headless test under `neues-spiel/tests/integration/…` — **BLOCKING**
- [ ] **`needs-mood-010`'s poll-not-event variant passes** — the round trip completes with
      `need_urgent` deliberately unconnected. **BLOCKING; this is the story's correctness argument,
      not a formality** (state is truth, the event is a latency hint)
- [ ] **`needs-mood-010`'s run-level capture exists in `production/qa/evidence/`** — criterion #5
      requires the test **and** the capture. **BLOCKING for the criterion**
- [ ] **`GameWorld`'s Booting path assigns the real Needs module to `needs_provider`, and grep proves
      no other call site assigns it** — **BLOCKING** (the shipped game must exercise the tested path)
- [ ] **`building-028` never `bulk_write`s to the grid on a FURNITURE-category completion** —
      grep-guarded. **BLOCKING**: this is what keeps `build-validation-002`'s furniture-transparency
      guarantee true by construction
- [ ] **`build-validation-006`'s `is_need_functional` true branch re-verified non-vacuously** against
      a real `ItemDefinitionResource` once `building-028` lands — **BLOCKING** (sign-off §13 carry-forward)
- [ ] Grep guards green: undo never mutates a Built cell; mood has zero references in work/scheduling
      code (Rule 8); zero `SceneTree.paused` / `Engine.time_scale`; zero placeholder emitters on the
      payoff path (if `bv-009` lands); `_visual_position` call-site allowlist per TD item 13
- [ ] Every new build-validation fixture **asserts the seal is still sealed after the sealing write**
      (the recurring trap, hit twice in S09)
- [ ] Full blocking suite green **headless with zero orphans on every story commit**; **E2E LOOP green
      on every commit**
- [ ] All engine APIs confirmed against `docs/engine-reference/godot/` — **BLOCKING**
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit tests)
- [ ] **`presentation-003`'s story file authored from VB-1/VB-2 BEFORE its lane reaches it**, and
      `/story-readiness` run against it
- [ ] QA plan exists for Sprint 10 (`production/qa/qa-plan-sprint-10-*.md`) — run `/qa-plan sprint`
      **before implementation begins**
- [ ] **Any story added to S10 after this plan is written is entered in `sprint-status.yaml` AND
      re-checked against the QA plan before sign-off** (sign-off condition #2)
- [ ] **A single consolidated `production/qa/smoke-[date]-sprint10.md` exists at hand-off** — not
      reconstructed from the last story's evidence doc (sign-off condition #4)
- [ ] **`/team-qa sprint` sign-off report exists: APPROVED or APPROVED WITH CONDITIONS** —
      `production/qa/qa-signoff-sprint-10-*.md`. Milestone criterion #14
- [ ] `building-023`'s evidence-doc Sign-off line updated to point at
      `qa-signoff-sprint-9-2026-07-26.md` (sign-off condition #3 — one line, do not let it lapse)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR/registry docs updated for any deviation
- [ ] Code reviewed and merged (trunk-based)
- [ ] **End-of-S10 review: the milestone's Cut-Lever Checkpoint #1** (Producer + CD + TD). The signal
      is criterion #5's live-pair test. **Read the Cut-Lever Policy's anti-signal before pulling
      anything**: a sprint that lands fewer stories for *decision* reasons (D8, unratified rulings)
      is **not** a lever signal.

## Open Decisions Surfaced by This Plan (producer → user)

Surfaced, not resolved. **D8 is new and it is the one that changes this sprint's shape.**

### D8 — ⚑ NEW: does criterion #5 require a bed that can be *demolished*? (decide before lane C reaches `building-016`)

`needs-mood-010` contradicts itself (finding **F1**). Its Dependencies demand the full furniture
chain `028 → 016 → 017` be "landed and REAL"; its Implementation Notes permit mocking "the bed's
existence"; its Out of Scope lists the chain. The seam the story actually forbids mocking is
**Needs ↔ Villager AI**, and nothing else.

- **(a) Ship the crown on `028 + 016` only** *(this plan's choice)*. The bed is a real, placeable,
  buildable, claimable entity; **demolition/revocation stays mocked** (as `villager-ai-018` AC26/AC27
  and `needs-mood-004`'s Edge Case 3 already do by design). Cost: **criterion #6 is 3/4 after S10**,
  and `needs-mood-010`'s "bed revoked mid-sleep" edge case is proven against a mocked revocation
  rather than a real demolition job. Benefit: the crown lands in S10 and the cut-lever checkpoint
  passes.
- **(b) Take the Dependencies section literally.** Add `building-009 → 011 → 012 → 015 → 017` —
  **four stories beyond the Nice already scheduled** — pushing S10 to ~19 and the crown to S11.
  Benefit: criteria #5, #6 **and** #11 all close honestly; the demolition chain is C1, protected, and
  has to be built eventually anyway. Cost: the end-of-S10 checkpoint fires and trims C4+C3 — which is
  darkly ironic, since option (b) *is* Cluster C work.
- **(c) Split the difference** — ship the crown on (a), then schedule the full C1 chain as S11's
  opener and add a **follow-on AC to `needs-mood-010`** re-verifying the revocation edge case
  non-vacuously once `017` lands (the same discipline already applied to BV-1's furniture-transparency
  guard and to `bv-006`'s `is_need_functional` branch).

**Producer recommendation: (c).** It gets the milestone's headline criterion green at the checkpoint
it is measured at, keeps the honest gap named and scheduled rather than papered over, and reuses a
verification pattern this project has now used twice successfully. `building-009` is scheduled as a
**Nice** precisely so option (b) or (c) starts with its head already landed. **This is your call.**

### D4 / E1 — Criterion #13 is protected, unowned, and story-less for the third sprint

**Target hardware class** and **VSync mode**, both technical-director, both "Not started"/"Unowned";
the measurement story does not exist (voxel-world ends at `story-021`). Because criterion #13 is
**never on the cut lever**, an unowned decision here cannot be traded away — it converts one-for-one
into milestone risk. `vox-018`'s tool is reusable verbatim (windowed, culling ON, **VSync OFF for
true compute** — S8 proved VSync floors frame-time measurement at 16.67 ms).
**Recommendation: assign the hardware-class call this sprint so the story can be authored for S11.**

### D3 — Cluster D is 25 stories, not ~14, and its epics still do not exist

Building UI 18 (12 CORE + 6 Polish) + Villager Info UI 7 (4 CORE + 3 Polish). Roll-up moves from ~60
to ~71. **Decision needed before S11 planning: does M02 commit to 16 CORE Cluster D stories, or
pre-declare the polish tail out of MVP now rather than at the S12 trim signal?** Deciding *now* is
worth more than deciding at S12, because it changes what `/create-epics` is asked to produce.

### D1 — The Projects-Panel cross-cluster cut-lever hazard (unchanged, still open)

`building-ui-011` routes intents through `pause_project` (`building-006`, C3) and `queue_demolition`
(`building-010`, C4) — neither call exists, and the lever trims C4 first and C3 second, *before*
Cluster D's step 5. Pulling the lever in its written order ships a panel displaying a lifecycle the
player cannot drive. **Producer recommendation stands: (b) scope `building-ui-011` render-only**, with
re-homing `building-006` out of C3 as the upgrade if C3 survives. **Still costs nothing today**
(`building-ui-011` is not scheduled until S11) — but it is now one sprint from mattering.

### D5 — Villager names: a tone call that will block `villager-info-ui-003`

`VillagerAi` carries only `villager_id: int`; identity generation is Villager AI Open Question 5,
VS-tier. **"Hilda" and "Villager #3" are different games** — creative-director tone decision, not an
engineering default. **No S10 impact, but note that `presentation-003` lands the body this sprint,
which is the moment a nameless villager becomes visible to a human.** Blocks S11.

### D6 — Two orphaned items the CD ruling handed back (unchanged, both still open)

(i) The **celebration stagger** (*"the room cue follows the command flourish by a breath rather than
stacking"*) is unspecified in every document that mentions it and still has no presentation-layer
owner — **it becomes concrete this sprint if `bv-007` lands**, since that story owns the pacing
contract the stagger would sit on. (ii) The **repo-wide `at 1x` annotation sweep** has a home
(`needs-mood-009`) but crosses GDD ownership. **Confirm the sweep's cross-GDD authority or split it —
this now blocks S11 scheduling of `nm-009`, not just tidiness.**

## Notes

- **Dependencies-satisfied check:** every S10 story was verified against its **own story file's
  `## Dependencies` section**, not against the milestone's or the epic's summary tables.
  `villager-ai-018` → 006 ✓/009 ✓/011 ✓; `nm-004` → 003 ✓; `nm-005` → 001 ✓/002 ✓;
  `nm-006` → 002 ✓ + 005 (in-sprint); `nm-007` → 003 ✓ + 005 (in-sprint); `nm-008` → 002 ✓/003 ✓ +
  005 (in-sprint); `nm-010` → 003 ✓ + 004/006/007/008 (in-sprint) + villager-ai-018 (in-sprint) +
  furniture (in-sprint) + bv-006 ✓; `building-028` → 021 ✓/022 ✓/RID ✓; `building-016` → 002 ✓;
  `building-011` → 002 ✓/032 ✓; `bv-007` → 004 ✓/005 ✓; `bv-008` → 005 ✓/006 ✓ + 007 (in-sprint);
  `bv-009` → 006 ✓ + 007 (in-sprint) + **external TD concurrence**; `building-009` → 002 ✓.
  **14 of 15 scheduled story files EXIST and read `Status: Ready` on disk (verified 2026-07-26).
  The fifteenth, `presentation-003`, does not exist and is listed under Missing Stories with a
  named author and a day-one gate — it is not fabricated.**
- **Two dependency defects were found by that check and are recorded above as F1 and F2**, plus a
  milder `building-028`/`016` asymmetry. This is the second consecutive sprint where reading story
  headers rather than tables changed the plan (S09 found the `building-012` inversion).
- **The cut lever is NOT pulled by this plan.** Checkpoint #1 fires at the **end** of S10 and its
  signal is criterion #5. Per the policy's own **anti-signal**: a sprint that lands fewer stories for
  *decision* reasons (D8 unresolved, two rulings unratified) is not a lever signal. Every slip on this
  project has come from a blocked decision, never from capacity — check which one it is before cutting.
- **On the S10-vs-S11 tension in the milestone document itself:** the Cut-Lever Policy expects
  criterion #5 green **by end of S10**, while the Notes' success test says **"by the end of S11."**
  This plan targets S10 and treats S11 as the milestone's own stated slack. If D8 is ruled toward
  option (b), the S11 target is the one that applies and **the checkpoint should not fire a trim** —
  record that explicitly at the checkpoint rather than letting the two statements collide silently.
- **Scope check:** 14 of 15 stories drawn from existing epics with existing `Ready` story files; the
  fifteenth has a written TD spec and a named author. Three items are recorded under Missing Stories
  rather than invented. No story was fabricated. Run `/scope-check sprint-10` before implementation.
- **Velocity:** 10 Must + 3 Should + 2 Nice = **15 stories**, against a measured band of 8–18
  (S1–S9: 8, 9, 9, 8, 8, 13, 12, 13, 18). Max Must lane **4.5** of 8 available; full set takes the
  longest lane to 6.0. **Buffer pre-committed to two named consumers** (`needs-mood-010`'s
  convergence, `presentation-003`'s authoring unknown) rather than held vague — the S8/S09 practice,
  which has now worked twice.
- **We will know this sprint was scoped right if:** `needs-mood-010`'s poll-not-event variant passes
  on the first honest attempt; a human can watch a villager with a *visible body* walk to a bed they
  placed and recover there at ×1.0; criterion #6 reads an honest 3/4 rather than a claimed 4/4; and
  the end-of-S10 checkpoint is a review that *confirms* the lever stays unpulled rather than one that
  pulls it.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story` — and
  **author `presentation-003`'s story file from VB-1/VB-2 first**. Then start `nm-005` (lane B),
  `villager-ai-018` (lane A) and `building-028` (lane C) **in parallel on day one**; all three are
  blocked on nothing and all three feed the crown.


---

## Sprint Result — CLOSED 2026-07-27

**14/16 stories complete.** CORRECTED 2026-07-27 by the QA sign-off, which caught this summary overclaiming: two Nice-tier stories (build-validation-009, building-009) never landed — consistent with the plan's own trim guidance, but they were not delivered. Suite grew 1198 -> 1383 (the earlier figure was also wrong), green with 0 orphans on every story commit.

**THE CROWN LANDED: milestone M02 criterion #5 is met.** A villager gets tired, polls its own need (proven with the signal deliberately disconnected), walks to a bed it claims as its own, sleeps in a room the real Build Validation calls sheltered, and recovers at exactly the full rate — while the same villager in an unsheltered bed recovers at 0.7x. That difference is why a player builds a roof.

Also landed this sprint:
- **Villagers became visible and clickable** (presentation-003) — until now they were pure logic with no body at all. The hit proxy rides the visual position, so clicks land where the player sees them. It also wrote the `_visual_position` single-source-of-truth guard, which had lived only in prose across three documents and was enforced nowhere.
- **The payoff loop can actually start in production** (scene-006). needs-mood-006 shipped `initialize_villager` green and uncalled; without it F1 decay iterates nothing, so a villager never gets tired and the crown's loop could never begin in the shipped game. Its probe is demonstrably non-vacuous — the obvious assertion would have passed on the broken build, so the test measures time instead and was shown to FAIL with the production call removed.
- Furniture as a registry rather than voxels (028), a bed as one entity across two cells (016), bed claiming with ground-sleep fallbacks (villager-ai-018), the full needs system (mood, interruption, spawn init, why-strings, determinism), plan-only undo (011), and room-recognition pacing + warning tiers (bv-007/008).

**Process findings recorded:**
- **Third occurrence of ship-green-and-uncalled** (after generate_terrain and spawn_starting_roster). Countermeasure chosen: a growing boot-invariant assertion block, plus the planning habit that every story adding a public API needs a caller story in the same sprint.
- **A parent misdiagnosis, corrected in the record**: an early wiring attempt was reverted citing 18 errors; the producer re-applied the identical change and measured green. The red run had another lane's half-finished work in the same tree. Lesson: never judge a change by a suite run containing foreign intermediate state.
- The recurring fixture trap (sealing with a solid block creates a legal step-up that reopens the escape) bit a fourth agent, who recognized it from the briefing.

**Blocked by missing content, not by code:** `res://data/items/` has no bed resource, so bv-006's shelter classification and bv-008's warning tiers cannot fire end-to-end for a real bed, and the crown runs on mocked beds. RID content authoring (rid-008/009) is in no sprint — it belongs in Sprint 11.

Carried to Sprint 11: the C1 demolition chain (009 -> 011 -> 012 -> 015) as the opener per decision D8, RID content authoring, bv-009, building-009, the Cluster D UI epics, and the multi-cell furniture redo limitation.
