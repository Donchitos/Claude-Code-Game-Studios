# Sprint 9 — Working Days 81–90 (nominal anchor 2026-07-26) — MILESTONE 02 OPENER

> **Sizing is in stories and sprint-sessions, not agent-days** (milestone-02 Notes; M01 delivered
> 80 stories across 8 sprints, every one landing its full commit set in a single back-to-back
> session — 8/8, 9/9, 9/9, 8/8, 8/8, 13/13, 12/12, 13/13, zero carryover). The per-story day
> figures below are **relative-complexity anchors**, never calendar predictions.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **This is the first sprint of Milestone 02.** M01 proved the forward loop. M02 owes the payoff.
> S09 does two things and only two things: it **opens the protected payoff spine** (the
> build-validation → needs-mood chain that converges on criterion #5) and it **clears Cluster 0's
> loop-facing residue** — the ghost preview (the player currently draws blind), the starting roster
> (the Valley boots with zero villagers), and the build editor mode (the room Cluster D lives in).
> It deliberately starts **no** Cluster C, **no** Cluster D, and **no** Cluster B story.

## ⚑ Provisional-Ruling Notice — this plan is sized against two UNRATIFIED documents

Both were produced away-mode on 2026-07-26 and are **PROVISIONAL pending user ratification**.
This plan proceeds AS IF ratified (per autonomous progression), and says so:

1. **`production/architecture-decisions-m02-preflight-2026-07-26.md`** (technical-director) —
   BV-1 (furniture is registry-resident, never grid-resident), BV-2 (`cells_changed_batch` is
   Build Validation's single trigger), **BV-4 (extract `VillagerWalkabilityRules` — this ruling
   CREATES `villager-ai-026`, the first story of this sprint)**, NM-5/NM-6/NM-7/NM-3.
2. **`production/creative-decisions-m02-preflight-2026-07-26.md`** (creative-director) —
   Ruling 1 (real-time pacing: **Option B unmodified**, ship 0.07 / 0.5 / 40) and Ruling 2
   (loop-payoff `PayoffDetail` sidecar).

**What breaks if they are overturned:** BV-4 reversal removes `villager-ai-026` and re-opens
`build-validation-001`'s DI shape — the sprint's binding lane loses its opener and its first
story's scope. BV-1/BV-2 reversal changes `build-validation-002`'s and `005`'s AC shape but not
their position. CD Ruling 1 reversal changes `needs-mood-001`'s shipped config defaults (a
config-only re-run, cheap). **None of the S09 Must set is invalidated by an overturn; three
stories would need AC edits.** This is the same posture S8 carried against the CD scope ruling.

## ⚑ Amendment 2026-07-26 — `scene-005` added (World genesis in the boot sequence)

**What changed:** one Must story added, `scene-005`
(`production/epics/scene-world-management/story-005-world-genesis-boot-sequence.md`, 2.0 d anchor,
**godot-specialist**, **sequenced FIRST on that lane, ahead of `building-023`**). S09 is now **15 stories**
(12 Must + 2 Should + 1 Nice). *(Superseded by the second amendment above: **17 stories**, and `scene-005`
is now gated by `vox-020`/`vox-021`.)*

**Why it was missing:** the production Valley boots an **EMPTY** `VoxelWorldGrid`.
`VoxelWorldGrid.generate_terrain()` is implemented and tested (vox-006) but called **nowhere in the boot
chain** — `valley.gd`'s own class doc says so and defers **three** things to "a future world-generation
story": terrain, `VillagerNavGraph.build()`, and (since 2026-07-26) `Valley.spawn_starting_roster()`.
Three landed stories hit it independently: **villager-ai-021** shipped `spawn_starting_roster()` as a
ready-and-uncalled surface because a boot-time standable-cell search finds nothing in an empty grid; the
**M01 C4 evidence run** could not wire chimney smoke / interior clutter / foliage for want of a world to
host them; **vox-018** measured a real world only because its own tool hand-built terrain. Grep over
`production/epics/` confirms no epic covered it (`generate_terrain` appears only in vox-006, bv-010
fixtures, and villager-ai-021 noting its absence). Filed to **scene-world-management** because the
deliverable is a **boot-phase ordering change** in `game_world.gd`/`valley.gd` under **ADR-0005** — this
epic's own governing ADR and own files — driving already-landed voxel-world/villager-ai surfaces; it
authors no generation algorithm.

**Why it sequences ahead of `building-023`:** `building-023`'s pick DDA finds no cell in an empty grid, so
no ghost renders and its **Visual/Feel evidence screenshot is not producible** until the world exists. R11
("no external playtest is meaningful until `building-023` lands") is in fact gated on `scene-005` first.

**Large-world shape — decided, not hand-waved:** production genesis is the **ADR-0015 residency page-in of
the boot window**, never a full-extent `generate_terrain()`. Measured (vox-018 evidence): ~63 µs/column
linear to 900×900 (52.2 s) and then **no completion in >200 s at 1000×1000** — a `Dictionary` rehash cliff.
The shipped config is 2000×2000, well past it. Per-chunk regen-from-seed is measured at 0.166 ms avg
(vox-016), so the ≤2,401-chunk boot window is ~0.4 s of parallelised compute. **The real boot cost is the
mesh** (~7.7 ms/chunk post-vox-019 → ~18.5 s projected at a full 49×49 window), so AC-BOOT-BUDGET is
measure-and-lever: 5 s **producer-provisional** ceiling, named lever = a boot-scoped initial mesh radius,
re-measure once, then escalate to technical-director.

**Capacity impact: none to the critical path.** The godot-specialist lane goes 2.0 → 4.0 Must lane-days
(`scene-005` → `building-023` → `building-001`), matching but not exceeding the binding build-validation
lane's ~4.0, inside 8 available. The 2-day buffer's two named consumers are unchanged; `scene-005`'s
boot-budget unknown is absorbed by that lane's own ~4 days of headroom, not by the buffer.

**Newly surfaced missing story (NOT fabricated):** ~~`VoxelWorldMeshStreamer` subscribes to no signal and has
**no mesh-invalidation path** — a meshed chunk is never re-meshed when its cells change (verified: zero
`cells_changed_batch` occurrences in that file).~~ ⚑ **SUPERSEDED 2026-07-26 — the premise was FALSE.** The
grep was true of that file; the invalidation path lives in `VoxelWorldMesher.setup()`
(`voxel_world_mesher.gd:163`). The real defects are the unbudgeted in-handler rebuild and the silent
residency page-in. **Closed by `vox-020`** — see the second amendment block above and D7 below.

## ⚑ Amendment 2026-07-26 (second) — `vox-020` + `vox-021` added (TD Addendum D closes D7 and D2)

**What changed:** two Must stories added to the **`godot-gdscript-specialist` lane**, both from
`production/architecture-decisions-m02-preflight-2026-07-26.md` **Addendum D** (also **PROVISIONAL pending
user ratification**). S09 is now **17 stories** (14 Must + 2 Should + 1 Nice).

| Story | File | Est. | Sequence |
|---|---|---|---|
| **`vox-020`** — mesh invalidation: dirty-marking + budgeted rebuild drain + `chunk_became_resident` | `production/epics/voxel-world/story-020-mesh-invalidation-dirty-set-and-budgeted-rebuild.md` | 1.5 | **BEFORE `scene-005`**; parallel-safe with `building-023` |
| **`vox-021`** — boot-scoped mesh radius + `view_radius_chunks` 24 → 12 | `production/epics/voxel-world/story-021-boot-scoped-mesh-radius-and-view-radius-retune.md` | 1.0 | **AFTER `vox-020`** (same file), **BEFORE `scene-005`** |

**Why they exist, and what moved:**

- **D7 is CLOSED, and its premise was FALSE.** This plan's own D7 entry (and `scene-005`'s Guardrail)
  asserted that *"`VoxelWorldMeshStreamer` subscribes to no signal, so a block the player places is written
  to the grid and never appears."* The zero-`cells_changed_batch` grep was true of that **file**; the
  invalidation path lives one layer down in **`VoxelWorldMesher.setup()` (`voxel_world_mesher.gd:163-164`)**,
  which connects both `cell_changed` and `cells_changed_batch` and rebuilds tracked touched chunks, seam
  neighbours included. **The streamer subscribing to nothing is correct layering** (mesher owns *content*,
  streamer owns *membership*). The two **real** defects `vox-020` fixes: (1) that rebuild is **unbudgeted
  and synchronous inside the signal handler** — ~69 ms for a 9-chunk edit at vox-019's measured 7.7 ms/chunk;
  (2) **residency page-in emits no signal**, so a chunk meshed before its async page-in lands never
  re-meshes — the actual permanent-hole class. **No new budget knob**: a separate rebuild budget would let
  the progress guarantee integrate one chunk per phase — 7.7 + 7.7 = 15.4 ms in a 16.6 ms frame — regressing
  vox-019's measured p95 of **16.947 ms**. The rebuild phase drains **first**, inside the existing
  `mesh_build_budget_ms`.
- **D2 is CLOSED with a bigger answer than the question asked.** `view_radius_chunks = 24` is unaffordable
  **at boot AND in steady state**: shrinking only the boot radius trades an 18.5 s freeze for ~35 s of
  visible pop-in, because `update_view_window` grows the window back to full at ~1 chunk/frame. So both
  knobs move: 24 → 12 in `.tres`, plus a new `boot_mesh_radius_chunks = 8` consumed only by
  `build_initial_window`. **Boot ceiling is now a technical-director decision: 3.0 s total / ≤ 2.5 s mesh
  phase**, replacing the producer's provisional 5 s. Projected mesh phase ~2.2 s.
- **`scene-005` was corrected, not redesigned.** Its Guardrail (built on the false premise) is reworded, its
  AC-MESH-WINDOW-AFTER-GENESIS rationale is restated as a cost preference rather than a hole-prevention
  necessity, AC-BOOT-BUDGET is re-pointed at the 3.0 s ceiling with the radius lever marked **spent** (owned
  by `vox-021`), **Open Decisions #1, #2 and #4 are CLOSED** (#3, the stale `TR-voxel-world-026` figure,
  stays open as a doc task), and it now **sequences after `vox-020`/`vox-021`**.
- ⚑ **One user decision falls out of this and is flagged, not absorbed: the visible extent halves,
  384 → 192 world units.** That is a look-and-feel property of a colony builder, not a technical detail.
  Two named alternatives are recorded in `vox-021`'s Open Decisions: **(a) accept longer visible fill-in**
  at a larger radius, or **(b) fund greedy meshing sooner** (ADR-0014 §2's named optimisation reserve — it
  attacks the 7.7 ms/chunk cost that forces the radius decision at all). Radius 12 is the right default to
  ship now because it is reversible in a `.tres` and is the only value affordable in both phases;
  `vox-021`'s AC-EXTENT-EVIDENCE captures a settlement-distance screenshot so the call is made on a picture.

### Capacity impact — and the honest over-commitment read

**Lane model (per-lane wall-clock, as S5–S8 used):**

| Lane | Must sequence | Must lane-days |
|---|---|---|
| `godot-gdscript-specialist` **(now the longest lane AND still the binding chain)** | ~~`bv-001` ✓~~ → **`vox-020` → `vox-021`** → `bv-002 → 003 → 004` → *(Should)* `005` | 4.0 → **6.5** |
| `godot-specialist` | `scene-005` → `building-023` → `building-001` → *(Nice)* `building-011` | 4.0 (unchanged, but **now gated**) |
| `systems-designer` | `nm-001 → 002 → 003` | 4.0 (unchanged, fully independent) |
| `ai-programmer` | ~~`villager-ai-026` ✓~~ → ~~`villager-ai-021` ✓~~ → *(Should)* `bv-010` | 1.5 (both Must **Complete**) |

**Is Sprint 9 now over-committed? Honest answer: the Must set is not; the Must + Should + Nice set is.**

- **By the lane model:** running `vox-020 → vox-021` **first** on the gdscript lane clears the gate on
  `scene-005` at ~day 2.5, the build-validation chain finishes ~day 6.0, and the godot-specialist lane
  finishes ~day 6.5. That is **6.5 of 8 available lane-days** — it fits, but **headroom collapses from
  ~4.0 days to ~1.5**. Adding both Shoulds and the Nice pushes the sprint to ~7.5–8.5 lane-days, i.e. **at
  or past the line**.
- **By story count — the only metric that has ever predicted anything here:** 17 stories is **above the
  measured 8–13/session band**. But **three are already Complete** (`villager-ai-026`, `build-validation-001`,
  `villager-ai-021`), so **14 remain** — at the top of the band, not beyond it.
- **The new structural fact, and the one that actually matters:** the gdscript lane now carries **both** the
  sprint's binding serial chain **and** a cross-lane gate on the godot-specialist lane. Before this
  amendment, a gdscript slip cost only build-validation. Now it also delays `scene-005`, `building-023` and
  `building-001` — i.e. **every loop-facing, human-visible deliverable in the sprint**. That is the real
  cost of these two stories, and it is not visible in the day totals.
- **The buffer situation changed, favourably on one side and unfavourably on the other.** The 2-day buffer's
  **primary named consumer — `villager-ai-026`'s behavior-preservation proof — is DISCHARGED** (the story
  landed Complete), so that reservation is released. Against that, two new named unknowns arrive:
  `vox-021`'s **boot measurement** (a MISS costs a lever + a re-measure + a TD escalation) and `vox-020`'s
  **budget/ordering assertions** against a 7.7 ms/chunk cost measured on one machine. **Re-point the freed
  buffer at those two**; `build-validation-010`'s 60 s CI ceiling remains the other named consumer. Net: the
  buffer is no better off than it was, but it is still pre-committed to named risks rather than held vague.

### Recommended trim, if one is needed

**Trim now (do it — it costs nothing):**
1. **Drop `building-011` (Nice, plan-only undo/redo) from S09 outright.** It was always opportunistic, it is
   Cluster 0 and never on the cut lever, and its lane is now the gated one. Move it to S10.

**Trim on signal (decide at mid-sprint, when `vox-021` lands or does not):**
2. **Demote `build-validation-005` (Should) to the opener of S10** — *not* `build-validation-010`. Reasoning:
   `bv-005` is **already** positioned as an S10 dependency (`bv-006`, the payoff-chain unblocker and the
   declared head of S10, needs both `004` and `005`), so deferring it crosses one sprint boundary and costs
   nothing else. `bv-010`'s entire value is **early** detection of a divergence between two *shipped*
   implementations (R3) — deferring it is the one trim that actively increases milestone risk. **Cut the
   Should whose value is positional, keep the Should whose value is temporal.**

**Do not trim:** `vox-020`/`vox-021` themselves (they gate `scene-005`), any Must, or the `/team-qa sprint`
sign-off (criterion #14 — the habit starts here regardless of scope).

**Sequencing instruction that replaces the previous "sequence `villager-ai-026` first":** with `026`,
`bv-001` and `villager-ai-021` already Complete, **the day-one instruction is now `vox-020` on the gdscript
lane**, because it is what gates the godot-specialist lane's entire four-story sequence. `nm-001` opens the
systems-designer lane in parallel as before.

## Sprint Goal

Open the protected payoff spine and make the game presentable to a human. Land the TD-mandated
`VillagerWalkabilityRules` extraction (**villager-ai-026** — it gates everything), then drive
Build Validation from scaffold to Room/Sealed verdict (**build-validation-001 → 002 → 003 → 004**)
and Needs & Mood from scaffold to the three-rung recovery ladder (**needs-mood-001 → 002 → 003**),
the two halves that converge on criterion #5. In parallel, clear Cluster 0's three loop-facing
residue stories: **building-023** (ghost preview — the player draws blind today),
**villager-ai-021** (starting roster — the Valley boots empty), and **building-001** (build editor
mode — R10's named unblocker for Building UI). Capacity-permitting, extend the analysis chain
through **build-validation-005** and stand up the milestone's riskiest test artifact,
**build-validation-010** (the AC36 reachability corpus, R3).

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved. **Primary named consumer: `villager-ai-026`'s
  behavior-preservation proof.** Its acceptance bar is *"the existing suite stays green with ZERO
  test edits — if any existing test needs editing, the extraction was not behavior-preserving and
  the story is not done."* That story gates a **serial depth-5 chain** (bv-001→002→003→004→005);
  a failure there stalls the sprint's entire spine, and the remediation is real work, not a retry.
  **Secondary consumer:** `build-validation-010`'s 60 s CI ceiling (R3) — the named lever is
  *reduce sampled pairs per seed before reducing seed count*, then escalate to technical-director.
  - *S8 precedent: the buffer was consumed as planned by `vox-019` and that worked. The practice is
    retained — the buffer is pre-committed to a named risk, not held as a vague reserve.*
- **Available:** 8 days
- **Committed:** Must 11 stories = 10.5 story-days *(serial sum)*; Should 2 = 3.0; Nice 1 = 1.0.
- **Measured cadence:** 8–13 stories/session across S1–S8. Throughput is **not** the binding
  constraint. The binding constraints this sprint are (1) the **serial depth-6 build-validation
  chain** (026 → 001 → 002 → 003 → 004 → 005) and (2) the **two unratified rulings** above.

**Parallel-lane capacity model (as S5–S8 used):** the 8-available figure is **per-lane wall-clock**,
not a serial story-day sum. Four parallel owner-lanes run concurrently:

- **ai-programmer** (the opener + roster + the corpus): `villager-ai-026` **(FIRST — it gates the
  binding lane)** → `villager-ai-021` → *(Should)* `build-validation-010`. ~1.5 Must lane-days.
- **godot-gdscript-specialist — Build Validation lane (THE BINDING LANE):**
  `build-validation-001 → 002 → 003 → 004` → *(Should)* `005`. ~4.0 Must lane-days, **serial
  depth-4 in-sprint, depth-5 counting `villager-ai-026`.**
- **systems-designer — Needs & Mood lane:** `needs-mood-001 → 002 → 003`. ~4.0 lane-days,
  serial depth-3. Runs fully in parallel with Build Validation (stories 001–009 mock the
  build-validation boundary; only story 010 needs it real, and 010 is not this sprint).
- **godot-specialist — Cluster 0 lane:** `building-023` → `building-001` → *(Nice)* `building-011`.
  ~2.0 Must lane-days. All three are independent leaves; no in-sprint chain.

Max Must lane = **~4.0 lane-days** (Build Validation ‖ Needs & Mood), inside 8 with ~4 headroom.
Critical path = the build-validation chain **plus its cross-lane opener** (see Critical Path).

### Sprint 8 actuals (calibration context)

- **13/13 stories Complete** (10 Must + `vox-019` planned-buffer remediation + 2 Nice).
  Suite **843 → 951** blocking, green with 0 orphans on every story commit.
- **Milestone 01 closed to its criteria**: #4 re-tune (worst-case deciding wait 30 → 6 ticks),
  #12 60 FPS with culling (`vox-018` honest MISS → `vox-019` bulk `ChunkSnapshot`: 40.4 → 7.7 ms
  per chunk, byte-identical output, p95 13.06 ms true compute, 21% headroom, draw calls 709),
  #6 four drawing verbs, #7 anti-stuck ladder complete, #5 upgraded to measured values.
- **The buffer worked as designed** — reserved against a named unknown, spent on that unknown.
- **Zero unplanned rework, zero carryover** for the eighth consecutive sprint.
- Findings carried into S09: the spike's 144 cells/s camera speed is stale (real 42.0); **vsync
  floors frame-time measurement at 16.67 ms — measure true compute with vsync off**; Godot 4.7
  cannot `@export` `RefCounted`/`Object` (**directly relevant to CD Ruling 2's `PayoffDetail`
  RefCounted sidecar — flag to TD before build-validation-009 is authored in S10**).

## Tasks

### Must Have (Critical Path — open the payoff spine + clear Cluster 0's loop-facing residue)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| villager-ai-026 | **Extract `VillagerWalkabilityRules` static twin (behavior-preserving) — TD-MANDATED, SEQUENCED FIRST, GATES THE BINDING LANE** — restores ADR-0007's stated "shared pure functions" shape that the landed instance-method form drifted from | `production/epics/villager-ai-behavior/story-026-walkability-rules-static-extraction.md` | ai-programmer | 0.5 | villager-ai-002 ✓, 003 ✓ (both Complete). **Blocked on nothing**; created by the PROVISIONAL BV-4 ruling | New `villager_walkability_rules.gd`, `class_name VillagerWalkabilityRules extends RefCounted`, **static functions only**, never instantiated; `VILLAGER_CLEARANCE`/`MAX_STEP_HEIGHT` declared **there and nowhere else**, re-exported as `const` aliases on `VillagerAi` so every call site compiles unchanged; `VillagerAi`'s methods survive as one-line delegations with unchanged signatures; **the existing suite stays green with ZERO test edits** (`git diff --stat -- neues-spiel/tests/` shows no modification to any pre-existing file — this is the correctness proof for the whole story); one new additive test proving static/instance equivalence + alias identity; `VillagerNavGraph`'s `predicate_source` migrated **or** left as-is, **not both**, choice recorded in the commit body. **The `*_after_write` twins stay untouched — post-M02 tech debt (BV-4 §6).** |
| build-validation-001 | **Config resource, DI scaffold & blocking lockstep invariant** — the epic's foundation; DI surface is *smaller* than originally planned per BV-4 (call the static twin, inject nothing) | `production/epics/build-validation-navigability/story-001-config-and-scaffold.md` | godot-gdscript-specialist | 0.5 | **`villager-ai-026` (in-sprint, HARD — the static call form does not exist until it lands)**; M01 Foundation boot/DI/config spine ✓ | Typed `@export` config per Tuning Knob, `.tres`, `validate()` once at boot; **GDD-declared BLOCKING cross-value invariant → terminal boot-halt** (AC27 lockstep), single-field range → warn+clamp+proceed; injected-tier `setup()` asserting its deps; headless-instantiable via `Node.new()` + mocks; **grep proves zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`** in the module; passing test |
| build-validation-002 | **Candidate interior cell predicate (standable + roofed, furniture-transparent)** — **no longer blocked on `building-028`** per BV-1: furniture transparency is proven **by construction**, not by a branch | `production/epics/build-validation-navigability/story-002-candidate-interior-cell-predicate.md` | godot-gdscript-specialist | 1.0 | build-validation-001 (in-sprint); transitively `villager-ai-026` | Candidate = standable **and** roofed, evaluated by calling `VillagerWalkabilityRules.is_standable(voxel_world, cell)` **statically** — zero duplicated rules, **zero duplicated walkability constant literals** (grep guard tests *literals*, not identifiers); furniture cells evaluate **as if empty**, proven by a test asserting a completed FURNITURE-category job leaves `voxel_world.get_cell()` empty (proof-by-construction, BV-1); the `is_standable` doc comment's Planned-blueprint-cells clause survives the 026 move (AC23 load-bearing); passing unit test |
| build-validation-003 | **Candidate region formation & affected-region scoping** | `production/epics/build-validation-navigability/story-003-region-formation-and-scoping.md` | godot-gdscript-specialist | 1.0 | build-validation-002 (in-sprint) | Orthogonally-connected candidate regions, `min_room_cells` floor from config; affected-region scoping bounds the work to what changed; formation/split/merge deterministic; unbounded uncached flood-fill is the accepted MVP shape (Control Manifest records the ~12k-connected-cell boundary as accepted risk — **do not build a cache**); passing unit test |
| build-validation-004 | **Outside-connection trace & Room/Sealed verdict** — the epic's mechanical heart | `production/epics/build-validation-navigability/story-004-outside-connection-trace-and-verdict.md` | godot-gdscript-specialist | 1.5 | build-validation-003, 002 (in-sprint) | Full-reachability trace from region interior to an open-sky standable cell **walking Villager AI's exact movement graph** (`is_step_legal` via the static twin) — **never a plain 4/8-neighbour flood-fill**; Room vs Sealed verdict; **AC10: the roof-on-pillars "cozy carport" IS a valid room** (accepted MVP design gap, GDD Open Question 1 is a VS decision — do not "fix" it); passing unit test |
| needs-mood-001 | **Config resource, DI scaffold, need schema & BLOCKING ladder invariant** — ships CD Ruling 1's values | `production/epics/needs-mood-system/story-001-config-scaffold-and-ladder-invariant.md` | systems-designer | 1.0 | None in-epic; M01 Foundation spine ✓ (`ConfigResource`, `GameWorld` boot gate, `TimeTickSystem` Autoload) | Typed `@export` config, `.tres`; **the ladder invariant `ground_penalty < unsheltered_bed_multiplier < 1.0` halts boot loudly when violated (AC29) — proven by test, not asserted in prose**; fixed need schema (MVP: `sleep`); **ships CD Ruling 1's values unmodified: `decay_per_tick[sleep]=0.07`, `base_recovery_per_tick[sleep]=0.5`, `mood_smoothing_ticks=40`** (PROVISIONAL — if the ruling is overturned this is a config-only re-run); headless-mockable, zero Autoload registration; passing test |
| needs-mood-002 | **F1 decay, per-need state machine & edge-triggered urgent signal** — carries the TD-canonized `has_urgent_need` seam | `production/epics/needs-mood-system/story-002-decay-state-machine-and-urgent-signal.md` | systems-designer | 1.5 | needs-mood-001 (in-sprint). **TD-owned doc precondition (NM-6): `architecture.md` must document `has_urgent_need(villager_id) -> bool` BEFORE this story starts** | F1 per-tick decay; queryable per-need state machine (**state is truth, edge events are latency hints**); edge-triggered urgent/satisfied signals fire once per transition; **`has_urgent_need(villager_id: int) -> bool` implemented as a REQUIRED pure query** (NM-6) — **no signal emission, no state mutation, no lazy-init as a side effect of being asked**; nil-safety stays on the consumer side (`VillagerAi._has_urgent_need`'s existing guard — do NOT add a null branch here); passing unit test |
| needs-mood-003 | **Recovery-report API, source→rate table & F2 recovery — THE THREE-RUNG LADDER** (the mechanical meaning of "the building IS the game") | `production/epics/needs-mood-system/story-003-recovery-report-api-and-source-rate-table.md` | systems-designer | 1.5 | needs-mood-001, 002 (in-sprint) | **Canonical three-arg form per NM-5: `start_recovery(villager_id: int, need: StringName, source_enum: RecoverySource) -> void`** and symmetrically `stop_recovery(villager_id, need, reason)`; F2 resolves through a **source→rate TABLE LOOKUP** with a test proving a brand-new source id works **with no code change** (AC10 — no hardcoded two-source branch); **three rungs, per TD NM-3: `bed_sheltered` ×1.0 > `unsheltered_bed_multiplier` (0.7) > `ground_penalty` (0.4)** — Core Rule 4 is authoritative, the GDD's F2 variable table is stale. **The two-multiplier form is NEVER to be implemented** — it makes the BLOCKING ladder invariant unenforceable and silently deletes the "the missing roof visibly costs" mechanic. Passing unit test |
| vox-020 | **Mesh invalidation — dirty-marking + budgeted rebuild drain + `chunk_became_resident` (ADDED 2026-07-26, TD Addendum D / D7; FIRST on the gdscript lane — it gates `scene-005` and therefore the whole godot-specialist lane)** | `production/epics/voxel-world/story-020-mesh-invalidation-dirty-set-and-budgeted-rebuild.md` | godot-gdscript-specialist | 1.5 | **Blocked on nothing** (vox-007/015/019 + residency tier all landed). Created by the PROVISIONAL D7 ruling | The mesher's two change handlers **mark dirty instead of rebuilding in-handler** (`_dirty_chunks`, `get_dirty_chunk_keys()`, `clear_dirty()`) — zero `build_chunk()` calls during signal dispatch, asserted; new `VoxelWorldGrid.chunk_became_resident(chunk_key)` emitted from `_integrate_one_finished_read` + `_try_serve_from_in_flight_write` **after** the `_chunks` assignment, feeding the **same** dirty set (no second mechanism); a **rebuild phase drained FIRST** in `_sync_window`, before build-new and before unload, through the **existing** `_drain_budgeted` inside the **EXISTING `mesh_build_budget_ms` — NO NEW KNOB** (a separate budget would permit 7.7 + 7.7 ms in one 16.6 ms frame and **regress vox-019's measured p95 of 16.947 ms**); `unload_chunk()` erases the key and **no cross-unload bookkeeping is built**; untracked chunks record nothing; `_chunk_keys_touched_by()`'s seam-neighbour behaviour **unchanged** and now regression-tested; **streamer subscribes to nothing** (grep-guarded — correct layering, not a bug); `build_initial_window` passes UNBOUNDED to the rebuild phase too. **9 ACs.** Evidence: `tests/integration/voxel_world/mesh_invalidation_budget_test.gd`. Parallel-safe with `building-023` |
| vox-021 | **Boot-scoped mesh radius + `view_radius_chunks` 24 → 12 retune (ADDED 2026-07-26, TD Addendum D / D2)** | `production/epics/voxel-world/story-021-boot-scoped-mesh-radius-and-view-radius-retune.md` | godot-gdscript-specialist | 1.0 | **`vox-020` (in-sprint, HARD sequencing — same file, `voxel_world_mesh_streamer.gd`; serialize them)**. Created by the PROVISIONAL D2 ruling | `view_radius_chunks` **24 → 12** as a pure `.tres` change with rationale (at 7.7 ms/chunk radius 24 = 2401 chunks = 18.5 s and a window `update_view_window` can never maintain); new `boot_mesh_radius_chunks: int = 8` **consumed only by `build_initial_window`**, threaded as a radius parameter into the **existing** `_collect_window` — **no new state, no timer, no camera trigger, no second code path** (grep-guarded single consumer), validated against new MIN/MAX + a **non-BLOCKING clamp+warn** when it exceeds `view_radius_chunks`; **growth to full via the existing budgeted `update_view_window`** (289 → 625 ≈ 5.6 s of gradual fill while the player is already interactive); `visibility_range_end` stays **derived** (12 × 16 = 192 u); ADR-0005 holds — `build_initial_window` still inside WIRING, once, before ACTIVE; **boot ceiling 3.0 s total / ≤ 2.5 s mesh phase**, measured **windowed, real GPU, VSync OFF, phase-split** to `production/qa/evidence/` (projected ~2.2 s). ⚑ **USER DECISION FLAGGED: visible extent halves 384 → 192 u** — look-and-feel, two named alternatives (accept longer fill-in / fund greedy meshing sooner) |
| scene-005 | **World genesis in the boot sequence — terrain, roster and nav graph before ACTIVE (ADDED 2026-07-26; FIRST on the godot-specialist lane) — THE VALLEY BOOTS AN EMPTY GRID TODAY** | `production/epics/scene-world-management/story-005-world-genesis-boot-sequence.md` | godot-specialist | 2.0 | **Blocked on nothing** — every surface it calls is landed (vox-006/010–019, villager-ai-007/021, scene-001/002/004, spine-002/003, cam-001/002) | Genesis runs in WIRING, after the `setup()` sweep and strictly BEFORE the initial mesh window and before ACTIVE; **no production `src/` path calls `generate_terrain()`** (grep-guarded) — genesis is `update_residency()` page-in of the boot window per ADR-0015, so cost scales with the window, not the 2000×2000 extent; deterministic by `terrain_seed` (same seed → identical world, different seed → different); grid reports `GENERATED`; zero per-cell `cell_changed` at boot; **ONE config-derived start-focus cell** shared by residency anchor / mesh-window centre / camera start target / roster centre (today the camera starts at cell 0,0,0 while the roster spawns at 1000,8,1000); `build_initial_window()` still once, now strictly after genesis (the streamer has no invalidation path — a chunk meshed early is a permanent hole); **`spawn_starting_roster()` called exactly once after the world exists** (villager-ai-021's ready surface, dead code until now) with plurality proven at `starting_villager_count > 1`; `VillagerNavGraph.build()` over a config-driven bounded region with point count > 0; **no synchronous per-frame I/O or generation** — `drain_pending_async_reads`/`wait_for_async_residency_idle` grep-absent from every `_process` call graph, boot drain bounded by a config ceiling; **AC-BOOT-BUDGET (Advisory)**: windowed VSync-OFF phase-split boot wall clock recorded to `production/qa/evidence/`, 5 s producer-provisional ceiling, one named lever then escalate to TD |
| building-023 | **Ghost preview rendering + drag re-rasterization + degradation + state tint (Cluster 0) — THE PLAYER CURRENTLY DRAWS BLIND** (run AFTER `scene-005` — no pick, no ghost, no screenshot over an empty grid) | `production/epics/building-system/story-023-ghost-preview-rendering.md` | godot-specialist | 1.0 | building-020 ✓ (pick anchor), 022 ✓ (validity bool), 019 ✓ (tool SM) — all Complete S5/S6 | Pooled `MeshInstance3D` ghost preview over the resolved cell set for all four drawing verbs; re-rasterizes during drag; graceful degradation above the cell cap; state tint (valid/invalid); **no writes to `VoxelWorldGrid`** (grep-guarded as a non-writer, same guard the four tools carry); Visual/Feel evidence screenshot under `production/qa/evidence/`. **R11: no external playtest is meaningful until this lands.** |
| building-001 | **Build/Editor Mode state machine (Cluster 0)** — the mode the tool palette and the whole Building UI live inside; **R10's named unblocker** | `production/epics/building-system/story-001-build-editor-mode.md` | godot-specialist | 1.0 | Camera & Input action signals ✓, tool state machine ✓ (Complete) | Build Mode master gate as a state machine; all placement tools gate through it; mode entry/exit deterministic and testable headlessly; passing unit test. **Unlocks `building-ui-001`/`002` (Cluster D) independently of Cluster A — this is M02 risk R10's stated mitigation and the reason it is Must, not Should.** |
| villager-ai-021 | **Starting roster spawn at world generation (Cluster 0) — THE VALLEY BOOTS WITH ZERO VILLAGERS TODAY** | `production/epics/villager-ai-behavior/story-021-starting-roster-spawn.md` | ai-programmer | 1.0 | villager-ai-001 ✓ (config/scaffold), 002 ✓ (`is_standable` for valid placement) — both Complete | Deterministic starting roster spawned at world generation on valid standable cells; roster size data-driven (`.tres`), never hardcoded; **makes the roster plural** — every downstream playtest, telemetry run and UI story is evaluated against a populated Valley instead of a hand-spawned one; passing integration test. **Note: this is also what makes BV-4's "which villager do I inject?" objection concrete — 026 lands first for exactly this reason.** |

### Should Have (extend the analysis chain; stand up the milestone's riskiest test artifact)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| build-validation-005 | **Analysis pass lifecycle, batched trigger, snapshot & never-blocks guards** — trigger RESOLVED by BV-2 and *simpler* than planned | `production/epics/build-validation-navigability/story-005-analysis-pass-lifecycle-and-snapshot.md` | godot-gdscript-specialist | 1.5 | build-validation-001, 004 (in-sprint) | **ONE subscription: `VoxelWorldGrid.cells_changed_batch`. NEVER `construction_completed`** — that signal can name cells whose deferred write has not landed (ADR-0015 load-before-write), so a pass triggered by it analyses stale data; **new AC proving a deferred/paged write still triggers a pass**; event-driven, never per-frame; incremental snapshot patching; **mock call-count tests proving the module never blocks a placement (AC25) and never calls a villager movement/behavior API (AC33)**; AC19's "at most one pass per frame" test written against **tick dispatches**, not frames (Known Conflict 3, report-only). Sequencing note: this is the last gate before `build-validation-006`, the payoff-chain unblocker — **006 is the head of S10, protect its position.** |
| build-validation-010 | **AC36 reachability property corpus (criterion #2) — THE MILESTONE'S RISKIEST SINGLE TEST ARTIFACT (R3)** | `production/epics/build-validation-navigability/story-010-reachability-property-corpus.md` | ai-programmer | 1.5 | build-validation-004 (in-sprint), 002 (in-sprint); villager-ai-002 ✓/007 ✓ Complete. **Runnable in parallel with 005–009** | 100 checked-in seeds × 50 sampled (start, target) pairs = **5,000 verdicts**, this system's reachability agreeing with Villager AI's pathfinder on **every one**; total corpus runtime **≤ 60 s** recorded in CI; deterministic seeds checked in, no RNG at run time. **Time-boxed. If the 60 s ceiling is missed: REDUCE SAMPLED PAIRS PER SEED BEFORE REDUCING SEED COUNT, re-measure once, then escalate to technical-director** (milestone Cut-Lever Policy). Owner escalation target: technical-director (R3). **A late failure here means one of two SHIPPED implementations is wrong** — that is why it is stood up in S09 and not at the milestone gate. |

### Nice to Have (opportunistic Cluster 0 close — pull only if the Cluster 0 lane clears)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-011 | **Plan-only undo/redo (Cluster 0, milestone criterion #12)** — M01 criterion #6 named "plan-only undo" as-written; only the stack core (`032`) landed | `production/epics/building-system/story-011-plan-only-undo-redo.md` | godot-specialist | 1.0 | building-002 ✓ (project entity + cell micro-states), building-032 ✓ (undo/redo stack core) — both Complete S7 | **Undo NEVER mutates a Built cell** — the existing non-writer grep-guard extended to the undo path; redo symmetric; plan-only scope proven by test (`plan_only_undo_test.gd`); passing unit test. Pull only after `building-023` + `building-001` land with lane headroom. |

## Milestone-Criteria Advancement Map (what this sprint moves)

| # | Criterion | S09 disposition |
|---|-----------|----------------|
| #1 | Build Validation implemented (AC1–35, 37, 38 green) | **OPENS** — 001/002/003/004 (+005 Should) = the analysis spine. 006/007/008/009 are S10. |
| #2 | Reachability property corpus green in CI ≤ 60 s | **STOOD UP as Should** (bv-010). R3's "sequence early" instruction honoured — a late failure here invalidates a shipped implementation. |
| #3 | Needs & Mood implemented | **OPENS** — 001/002/003 = config + ladder invariant + decay + the three-rung recovery table. 004–008 are S10. |
| #4 | Real-time-rate pass recorded | **NOT THIS SPRINT.** `needs-mood-009` depends on 002/003/005/008 — S10. **But its decision input is already resolved** (CD Ruling 1, Option B unmodified), and `needs-mood-001` **ships the ruled values in S09**. |
| #5 | Payoff loop closes live-pair | **BOTH SERIAL CHAINS OPENED, NEITHER CLOSED.** Chain 1 (build-validation → needs-mood → AC34) advances to bv-004/nm-003. Chain 2 (furniture 028 → 016 → villager-ai-018 → AC34) **does not start** — S10. Criterion #5 is an S11 target per the milestone's own success test. |
| #6 | Furniture placeable/buildable/claimable | **NOT STARTED** — deliberate. See Out of Scope. |
| #7 | `presentation-002` signals something real | **NOT STARTED** (bv-009, S10). CD Ruling 2 resolved its signal shape; **one open input remains — TD concurrence on the implementation form, and an S8 finding that bears on it** (Godot 4.7 cannot `@export` `RefCounted`/`Object`). |
| #10 | Building UI + Villager Info UI ship | **UNBLOCKED, NOT STARTED.** `building-001` + `building-023` land in S09 precisely so Building UI can run in S10/S11 independently of Cluster A (R10 mitigation). |
| #12 | Plan-only undo is real | **Nice-to-have** (`building-011`). Cluster 0, never on the cut lever. |
| #13 | Mid-range hardware baseline | **NO STORY EXISTS** (see Missing Stories) and **two decisions are unowned**. Escalated, not scheduled. |
| #14 | `/team-qa sprint` sign-off every sprint | **THE HABIT STARTS HERE.** No sign-off artifact exists for any of S1–S8 (verified: `production/qa/` contains zero `qa-signoff-sprint-*.md`). S09 close runs `/team-qa sprint` without exception. |

## Critical Path

One binding path this sprint, and it crosses a lane boundary at its very first step:

**`villager-ai-026` → `build-validation-001` → `002` → `003` → `004` → *(Should)* `005`**
— serial depth **6**, ~5.5 lane-days. `026` sits on the **ai-programmer** lane while the rest sit
on the **gdscript** lane; this is the sprint's one cross-lane hard handoff and its single most
important sequencing fact.

- **Sequence `villager-ai-026` FIRST, on day one, before anything else on any lane.** It is 0.5
  days of mechanical work that gates 4–5 downstream stories. `villager-ai-021` fills the ai lane
  while it runs — but 021 must not be started *before* 026.
- **Do not let `build-validation-004` sit on the last day.** It is the epic's mechanical heart
  (1.5 days, the reachability trace) and `005` + `010` both wait on it.
- The **Needs & Mood lane runs fully in parallel** and shares no code with Build Validation this
  sprint — stories 001–009 mock the build-validation boundary by design. If the binding lane
  slips, Needs & Mood does not.

**Owner lanes (serialization mitigation):**
- **ai-programmer:** `villager-ai-026` **(FIRST — gates the binding lane)** → `villager-ai-021` →
  *(Should)* `build-validation-010` (starts only after bv-004 lands).
- **godot-gdscript-specialist:** ⚑ **AMENDED 2026-07-26 (second):** ~~`build-validation-001`~~ ✓ Complete →
  **`vox-020` → `vox-021` (FIRST — they gate `scene-005` and therefore the entire godot-specialist lane)** →
  `build-validation-002 → 003 → 004` → *(Should)* `005`. ~6.5 Must lane-days — **now the longest lane, and
  it carries both the binding serial chain and a cross-lane gate.**
- **systems-designer:** `needs-mood-001 → 002 → 003` (independent lane, no cross-lane dependency).
- **godot-specialist:** **`scene-005` (FIRST, amendment 2026-07-26 — but now GATED: it cannot start until
  `vox-020` and `vox-021` land on the gdscript lane, ~day 2.5)** → `building-023 → building-001` →
  *(Nice)* `building-011` **(recommended cut — see the second amendment's trim section)**. `scene-005` is sequenced first because the other three are all evaluated against
  a world that does not exist today; `building-023` in particular cannot produce its evidence screenshot
  before it. ~4.0 Must lane-days.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 8 delivered 13/13 — no carryover, zero unplanned rework, eighth consecutive clean sprint. The M01 CD-ruling deferrals (building 006/007/008/009, villager-ai-013, presentation-001 Sub-B, roof formations, block remove-mode) are **M02 backlog**, not S8 carryover, and are scheduled by cluster below. | — |

## Out of Scope (deferred from S09, with honest reasons)

**Deliberately not started this sprint** — every item below is real M02 work with a named home:

- **`build-validation-006/007/008/009`** → **S10.** `006` (shelter classification + `shelter_status_changed`)
  is the payoff-chain unblocker for Needs & Mood; it needs `004` **and** `005`, both of which land at
  the tail of S09. **`006` is the head of S10 — protect its position in the sequence.**
- **`needs-mood-004` through `011`** → S10/S11. `009` (the real-time-rate pass, criterion #4)
  depends on 002/003/005/008; `010` (the live pair, criterion #5) additionally needs
  `villager-ai-018`, the furniture chain, and build-validation's shelter flag **all real**.
- **The furniture chain (`building-028 → 016 → 017`) and `villager-ai-018`** → **S10.** This is
  criterion #5's *second* serial chain and it is Cluster A / PROTECTED — it is deferred by one
  sprint, not trimmed. ⚑ **Sequencing hazard for S10:** `building-017` (furniture demolition)
  depends on `building-009` (demolition contract) and `building-015` (draft-eraser branch) —
  **both Cluster C tier C1.** C1 is criterion-#11-protected and never on the lever, but it means
  the furniture chain cannot fully close without pulling C1 forward. `028` and `016` are clean.
  Also: `building-028` inherits **two blocking ACs from BV-1** it did not have when it was written
  (FURNITURE-category completion never `bulk_write`s to the grid; the registry exposes a
  placed/removed signal + item enumeration as a duck-typed nil-safe provider).
- **Cluster B entirely** (`villager-ai-019`, `013`, `020`, `presentation-001` Sub-B) → S10/S11.
  **CD-protected — surfaced, not silently dropped.** Deferred on a sequencing argument the
  milestone makes itself: *Cluster A creates the hosts Cluster B's unwired ambient components need*
  (room recognition → chimney-smoke occupancy; furniture placement → interior clutter). Scheduling
  A first is what makes B cheap. B stays cheapest-cluster-by-far (~4 existing Ready stories).
- **Cluster C entirely** (the cut lever) → S10+. C1 (`009/031/015/027-remove`) is protected by
  criterion #11 and is **not** trimmable; C2–C4 are the lever and are untouched this sprint.
- **Cluster D entirely** (25 stories — building-ui 18 + villager-info-ui 7) → S11+. Only its two
  Cluster 0 prerequisites land in S09. **See the escalations below before any Cluster D scheduling.**
- **`villager-ai-023`** (scene-transition simulation continuity, Cluster 0) → S10. It is the one
  Cluster 0 story with **no loop-facing consequence** — nothing the player sees, no criterion
  depends on it, and no S09 or S10 story lists it as a dependency. Deferred on value, not capacity.
- **`building-012`** (floor-excavation restore-value, Cluster 0) → **BLOCKED, cannot be scheduled.**
  See the dependency correction under Notes — its own story file inverts the milestone's stated
  dependency direction.
- **`needs-mood-012`** (save/load) and **`build-validation` AC26** — VS-tier, explicitly out of
  M02 scope. `needs-mood-012` exists only so its TRs are not orphaned.
- **Roof formations beyond Flat, doors/windows as objects, wall-coverage requirement, mood
  consequences, audio, economy** — VS-tier per the milestone's Out of Scope section.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Both pre-flight ruling documents are PROVISIONAL pending user ratification** — the TD rulings *create* `villager-ai-026` (the sprint's opener and the gate on a depth-5 chain) and shape `build-validation-002`/`005`; CD Ruling 1 fixes the config values `needs-mood-001` ships | Medium | **High** | The plan proceeds AS IF ratified (autonomous progression), and every affected story names its ruling and its provisional status in-line. **Blast radius is bounded and stated**: a BV-4 overturn removes 026 and re-opens bv-001's DI shape; BV-1/BV-2 overturns change AC shape, not story position; a CD Ruling 1 overturn is a config-only re-run of `needs-mood-001`. No Must story is *invalidated* by an overturn. Same posture S8 carried successfully against the CD scope ruling. |
| **`villager-ai-026` gates a serial depth-5 chain and its acceptance bar is unusually strict** — "the existing suite stays green with ZERO test edits; if any test needs editing the extraction was not behavior-preserving and the story is not done" | Medium | **High** | Sequenced FIRST on day one, before any other lane starts. **The 2-day buffer's primary named consumer.** The story prescribes an order of work that keeps the suite green at every step (add file → convert to delegations/aliases → run suite → add structural test; *do not batch these*). `villager-ai-021` fills the ai lane while it runs so the lane is never idle. |
| **The build-validation chain is serial depth-4 in-sprint on ONE lane and its heart (`004`) is the largest single story** (1.5 d, the full-reachability trace over Villager AI's exact movement graph) | Medium | Med-High | Each story asserts independently (config invariant / candidate predicate / region formation / verdict). The predicates `004` consumes are proven-green M01 code reached through `026`'s mechanical extraction — the chain consumes a stable seam, not a new one. Do not let `004` sit on the last day; `005` and `010` both wait on it. |
| **`build-validation-010`'s corpus is the milestone's riskiest single test artifact (R3)** — 5,000 cross-implementation verdicts under a 60 s CI ceiling, guarding against pathfinder/validator divergence | Medium | **High** | Scheduled as Should in S09 rather than deferred, precisely because *a late failure means one of two shipped implementations is wrong*. Time-boxed; buffer's secondary consumer. **Named lever: reduce sampled pairs per seed BEFORE reducing seed count**, re-measure once, then escalate to technical-director. |
| **Godot 4.7 cannot `@export` `RefCounted`/`Object`** (S8 finding) **and CD Ruling 2's `PayoffDetail` sidecar is specified as a typed `RefCounted`** | Medium | Medium | Not an S09 blocker (`build-validation-009` is S10), but it is a **known collision between an S8 measured finding and an unratified CD ruling**. Flag to technical-director as part of the TD-concurrence item CD Ruling 2 explicitly hands back. CD's own scope note permits TD to substitute an equivalent form (`Resource` vs `RefCounted`) provided the five assertable conditions hold. |
| **Cluster D is 25 stories, not the milestone's stated ~14** (building-ui 18 + villager-info-ui 7; 12+4 = 16 are minimum-viable CORE, 9 are the polish tail) | **High** | Medium | **Discovered scope, recorded here rather than absorbed silently.** It re-prices the milestone roll-up from ~60 to ~71 stories and makes Cluster D's trim steps 4–5 materially more valuable than the Cut-Lever Policy assumed when it was written. Surfaced as an open decision below; **no S09 impact** (Cluster D starts S11). |
| **Three of villager-info-ui's seven stories are blocked by a substrate that has no story anywhere** — villagers have no body, no collider, no public world position | **High** | Medium | Recorded under Missing Stories. Not an S09 blocker; it is an S11 blocker and it needs a decision + a new story now, because *no UI story can resolve it*. Escalated below. |
| **No `/team-qa sprint` sign-off exists for ANY sprint S1–S8** (verified — `production/qa/` holds eight QA *plans* and zero sign-offs). Standing Production → Polish gate blocker, criterion #14 | **High** | Medium | S09 close runs `/team-qa sprint` without exception. This is where the habit starts. Retro-run for S8 if cheap. |
| **Godot 4.7 API deviations beyond the LLM cutoff** — S09 is lighter on engine surface than S8 (mostly pure GDScript logic), but `building-023`'s pooled `MeshInstance3D` ghosts and `villager-ai-021`'s spawn path touch flagged domains | Low-Med | Low-Med | Cross-reference `docs/engine-reference/godot/` before any engine API use — **BLOCKING**, as in M01. |
| **Recurring typed-Array crash class** (0 occurrences S1–S8) | Low | Low | Regression call retained inside the E2E gate; watched on `026`'s extracted `body_column() -> Array[Vector3i]` return path in particular. |

## Dependencies on External Factors

- **USER RATIFICATION of the two pre-flight ruling documents (the gating dependency)** —
  `production/architecture-decisions-m02-preflight-2026-07-26.md` and
  `production/creative-decisions-m02-preflight-2026-07-26.md`. See the Provisional-Ruling Notice.
- **Three inbound M01 items still owned by the user** (signatures and a demo, **not** M02 content):
  C1 ratify/overturn the CD Scope Ruling 2026-07-25; C2 ratify the re-tune values quick-spec;
  C3-human the build-and-inhabit demo walkthrough. **If C1 is overturned toward as-written M01
  breadth (R9), Cluster C stops being a cut lever and becomes M01 rework that pre-empts roughly
  one M02 sprint** — re-plan S10 with C1+C2 tiers as Must.
- **TD-owned doc precondition, BLOCKING `needs-mood-002`:** `docs/architecture/architecture.md`
  must document `has_urgent_need(villager_id) -> bool` in Needs & Mood's exposed API **before that
  story starts** (NM-6 downstream action #5). Small, but it is a hard gate on a Must story.
- **TD concurrence on CD Ruling 2's implementation form** — needed before `build-validation-009`
  is authored (S10), and it now carries the `@export RefCounted` finding above.
- **Target hardware class definition + the VSync-mode decision** — both **unowned/not started**,
  both technical-director. Criterion #13 cannot be measured until the hardware class is a decision,
  and the story to measure it **does not exist**.
- **Control-manifest version 2026-07-23** — every S09 story embeds this version. Confirmed current
  S1–S8; re-confirm unchanged before the lanes start. Owner: technical-director.
- **No art/audio external dependency** for the committed set. `building-023`'s ghost preview is
  material-tinted pooled geometry, not new art.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed — **the payoff spine is open** (build-validation through the
      Room/Sealed verdict; Needs & Mood through the three-rung recovery ladder) **and Cluster 0's
      three loop-facing residue stories have landed** (ghost preview, starting roster, build mode)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (`villager-ai-026`, bv-002/003/004, nm-002/003, `building-001`,
      `building-011`) has a passing GdUnit4 headless unit test under `neues-spiel/tests/unit/…` — **BLOCKING**
- [ ] Every Integration story (bv-001, bv-005, bv-010, nm-001, `villager-ai-021`) has a passing
      headless test under `neues-spiel/tests/unit/…` or `…/integration/…` — **BLOCKING**
- [ ] `building-023` (Visual/Feel) has a screenshot artifact under `production/qa/evidence/` — ADVISORY
- [ ] **`villager-ai-026`'s zero-test-edit proof recorded**: `git diff --stat -- neues-spiel/tests/`
      shows no modification to any pre-existing test file — **BLOCKING** (this is the story's
      correctness argument, not a formality)
- [ ] Grep guards green: zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` in
      build-validation; **zero duplicated walkability constant *literals*** in `src/`; zero
      `VillagerWalkabilityRules.new(` anywhere; build-validation writes nothing (never blocks a
      placement — AC25; never calls a villager movement API — AC33); `building-023` is a non-writer
- [ ] The Needs & Mood **BLOCKING ladder invariant halts boot loudly when violated** (AC29) —
      proven by test, not asserted in prose — **BLOCKING**
- [ ] F2 recovery resolves through a **table lookup**, with a test proving a brand-new source id
      works with no code change (AC10) — **BLOCKING**
- [ ] Full blocking suite green **headless with zero orphans on every story commit**; **E2E LOOP
      green on every commit** (the S1–S8 standard, and milestone criterion #14)
- [ ] All nav/rendering/Control APIs confirmed against `docs/engine-reference/godot/` — **BLOCKING**
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in
      unit tests)
- [ ] QA plan exists for Sprint 9 (`production/qa/qa-plan-sprint-9-*.md`) — run `/qa-plan sprint`
      **before implementation begins** (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] **`/team-qa sprint` sign-off report exists: APPROVED or APPROVED WITH CONDITIONS** —
      `production/qa/qa-signoff-sprint-09.md`. **Milestone criterion #14; no such artifact exists
      for any of S1–S8 and this is where the habit starts. Non-negotiable.**
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR/registry docs updated for any deviation; the NM-5/NM-3 doc-hygiene batch
      (three-arg `start_recovery` in GDD Rule 10 + TR-042 + registry L2222; F2 variable table →
      Rule 4 lookup) filed to the GDD owner
- [ ] Code reviewed and merged (trunk-based)
- [ ] **End-of-S09 review** (milestone Review Schedule): Cluster 0 landed? Cluster A started?
      Hardware baseline measured? — Producer + TD

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-9 QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA sign-off report,
> which requires a QA plan. `villager-ai-026`'s zero-test-edit proof, the Needs & Mood BLOCKING
> ladder-invariant boot-halt, `build-validation-010`'s 60 s ceiling and its reduce-pairs-first
> lever, and the AC19 tick-dispatch wording in particular need defining up front.

## Open Decisions Surfaced by This Plan (producer → user)

These are **surfaced, not resolved**. None blocks S09 execution; several block S10/S11 planning.

### D1 — The Projects-Panel cross-cluster cut-lever hazard ⚑ (the one the epic authors escalated)

`building-ui-011` (Projects Panel — cards, per-state actions, progress, workers) renders project
lifecycle and routes intents through **`pause_project`** and **`queue_demolition`**. Neither call
exists. They live in **`building-006`** (pause/resume, **Cluster C tier C3**) and **`building-010`**
(Abriss, **Cluster C tier C4**). The Cut-Lever Policy trims **C4 first (step 1) and C3 second
(step 2)** — both *before* Cluster D's step 5. Landed `BuildProject.ProjectState` is exactly
`{DRAFT, BUILDING, PAUSED, DONE}`: no Demolishing state, no demolishing flag, no
`built_cells`/`total_cells` accessors, no project `name` field.

**Pulling the lever in its written order would ship a panel that displays a lifecycle the player
cannot drive** — Pause / Fortsetzen / Abriss buttons with no backing call. **Trim ORDER is a
dependency graph, not just a priority list.** Options:

- **(a) Re-home `building-006` out of C3 into the never-cut set** (as furniture was re-homed out
  of Cluster C into Cluster A at milestone definition). Pause/resume is the cheaper of the two and
  covers the two most-used buttons. Cost: one story leaves the lever, shrinking it by ~1 story.
- **(b) Scope `building-ui-011` to render-only** — cards, progress, workers, no action buttons —
  and file the buttons as a follow-on gated on C3/C4. Cost: the Projects Panel becomes a readout,
  not a controller, in MVP.
- **(c) Accept and re-order the lever** — declare that trim step 5 (Building UI to minimum) fires
  *before* steps 1–2 whenever the Projects Panel is in scope. Cost: complicates a policy whose
  value is that it is mechanical.

**Producer recommendation: (b), with (a) as the upgrade if C3 survives.** It is the only option
that keeps *both* the lever mechanical and the shipped panel honest, and it costs nothing today —
`building-ui-011` is not scheduled until S11.

### D2 — Villagers have no body, and no story exists to give them one

`VillagerAi extends Node` (not `Node3D`). No mesh, no `Area3D`, no `CollisionShape`, no public
world position (`_visual_position` is private with no getter; the only public position API is
`get_current_cell() -> Vector3i`, deliberately the discrete cell). **Verified: no story in any of
the 14 epics covers this.** It blocks `villager-info-ui-002/005/006` (three of seven), makes
`building-ui-016`'s Slice View "characters" clause vacuous, and it is **not a UI story's job to
fix**. Needs: a decision on the shape (Node3D + mesh + `Area3D` on a dedicated collision layer per
ADR-0004), an owner (technical-director + godot-specialist), and a **new story** in
`villager-ai-behavior` or `presentation-experience`. **I have not fabricated one.**

### D3 — Cluster D is 25 stories, not ~14

Building UI 18 (12 CORE + 6 Polish) + Villager Info UI 7 (4 CORE + 3 Polish) = **25**, against the
milestone's stated ~14. Roll-up moves from ~60 to **~71 stories**. This makes Cluster D's trim
steps 4–5 worth roughly **9 stories** instead of the ~4 the policy assumed. **No S09 impact.**
Decision needed before S11 planning: does the milestone commit to 16 CORE Cluster D stories, or
does it pre-declare the polish tail out of MVP now rather than at the S12 trim signal?

### D4 — Unowned technical decisions blocking criterion #13

**Target hardware class** and **VSync mode** (`project.godot` sets no override — the shipped
behaviour is an implicit engine default). Both technical-director, both "Not started"/"Unowned".
The **measurement story does not exist** (voxel-world ends at `story-019`). Criterion #13 is
protected — it is not on the lever — and it currently has neither a decision nor a story.
**Recommendation: escalate both to technical-director this sprint so the story can be authored for
S10**, reusing `vox-018`'s tool verbatim (windowed, culling ON, **VSync OFF for true compute** —
S8 proved VSync floors frame-time measurement at 16.67 ms).

### D5 — Villager names: a tone call blocking `villager-info-ui-003`

The panel's header and its whole fantasy sentence ("a name, what they're doing, how they feel")
need one. `VillagerAi` carries only `villager_id: int`; identity generation is Villager AI Open
Question 5, **VS-tier**. MVP must either ship id-derived placeholders or pull a minimal name
generator forward. **"Hilda" and "Villager #3" are different games** — this is a creative-director
tone decision, not an engineering default. No S09 impact; blocks S11.

### D6 — Two orphaned items the CD ruling handed back

(i) The **celebration stagger** — *"the room cue follows the command flourish by a breath rather
than stacking"* — is unspecified in every document that mentions it; needs a presentation-layer
owner. (ii) The **repo-wide `at 1x` annotation sweep** now has a home (`needs-mood-009`'s doc AC
was widened to cover it) **but crosses GDD ownership** — `design/gdd/building-system.md`'s F3
table and both `base_demolition_ticks` mirrors are 2× stale and are not `needs-mood-009`'s to
edit. Confirm the sweep's cross-GDD authority or split it.

### D7 — ✅ **CLOSED 2026-07-26 by TD Addendum D → story `vox-020`.** *The escalated premise below was FALSE and is retained for the audit trail.* The mesher — not the streamer — owns invalidation and already subscribes (`voxel_world_mesher.gd:163`); the real defects are the unbudgeted in-handler rebuild and the silent residency page-in. **D2's boot-radius half is likewise closed → story `vox-021`.** Original text follows.

### D7 (original) — Mesh invalidation on cell change has no story anywhere (found while authoring `scene-005`)

`VoxelWorldMeshStreamer` connects to **no** signal and rebuilds **nothing**: `_sync_window` builds only
chunks *not already tracked*. Consequences: (i) a chunk meshed while its data was not yet resident stays a
**permanent hole**; (ii) a chunk whose cells change — **including a block the player just built** — is not
re-meshed until it leaves and re-enters the view window. `scene-005`'s genesis-before-mesh ordering closes
the boot case only; the leading edge of a moving camera outrunning async page-in, and the player-placed
block, are both untouched. **Verified: no story in any of the 14 epics covers this.** Needs a
technical-director decision on shape (subscribe the streamer to `cells_changed_batch` and mark chunks dirty
vs. a data-window radius wider than the mesh-window radius) and a new story. **Not fabricated here.** No
S09 blocker; it bears directly on whether the shipped build looks correct to a human playtester.

## Notes

- **Amendment 2026-07-26 (`scene-005`)**: see the Amendment block at the top. Story count 14 → **15**;
  godot-specialist lane 2.0 → 4.0 Must lane-days; critical path and buffer commitments unchanged.
  Also file two doc corrections it surfaces: `TR-voxel-world-026`'s "~2.6 s initial view-window mesh build"
  is a stale ADR-0014 prototype figure (measured ~7.7 ms/chunk → ~7.4 s at 961 chunks), and
  `TR-voxel-world-029`'s Uninitialized→Generated transition is unreachable on the residency path today.
- **Dependencies-satisfied check:** every S09 committed story was verified against its **own story
  file's `## Dependencies` section** (not against the milestone's summary tables). `villager-ai-026`
  → 002 ✓/003 ✓; `bv-001` → **`villager-ai-026` (in-sprint, hard)**; `bv-002` → 001 (in-sprint),
  **`building-028` dependency DROPPED per BV-1**; `bv-003` → 002; `bv-004` → 003 + 002;
  `bv-005` → 001 + 004, **no external blocker (BV-2)**; `bv-010` → 004 + 002, villager-ai-002 ✓/007 ✓;
  `nm-001` → none; `nm-002` → 001; `nm-003` → 001 + 002; `building-023` → 020 ✓/022 ✓/019 ✓;
  `building-001` → Camera & Input ✓ + tool SM ✓; `villager-ai-021` → 001 ✓/002 ✓;
  `building-011` → 002 ✓ + 032 ✓. **All 14 scheduled story files EXIST and are `Status: Ready`**
  (verified on disk 2026-07-26). No unsatisfied dependency in the committed set.
- **⚑ Dependency correction — `building-012`.** The milestone's Internal Dependencies table states
  *"`building-009` demolition depends on `building-012` floor-excavation restore-value"*. The story
  file inverts this: `story-012`'s own `## Dependencies` reads *"Depends on: Story 002, **Story 009
  (demolition writeback)**, **Story 011 (undo restore)**"*. Taking the story file as authoritative
  (it is), **`building-012` is blocked by `building-009` — a Cluster C tier C1 story — and cannot
  be scheduled in S09 despite being listed in Cluster 0.** Cluster 0 is therefore **5 schedulable
  stories, not 6**. Flagged for milestone-document correction; do not schedule 012 before 009.
- **Cluster 0 disposition:** `building-023` ✓ Must, `building-001` ✓ Must, `villager-ai-021` ✓ Must,
  `building-011` Nice, `villager-ai-023` deferred to S10 on value, `building-012` blocked (above).
- **Why `building-001` is Must and not Should:** M02 risk R10's stated mitigation is *"Sequence
  Cluster 0's `building-001`/`023` in S09 so Building UI is unblocked independently of Needs &
  Mood."* Demoting it would re-couple all 18 building-ui stories to Cluster A's schedule, which is
  precisely the coupling R10 exists to prevent.
- **Why the furniture chain is not in S09** even though it is Cluster A / PROTECTED: criterion #5
  needs *both* serial chains, and the analysis chain is the longer one (depth 6 with its opener vs
  depth 3). Starting the shorter chain first would not shorten the milestone, and `building-028`
  now carries two blocking ACs inherited from BV-1 that did not exist when it was written — it
  should be re-read before it is scheduled. Furniture is **deferred by one sprint, not trimmed**;
  it is never on the lever (that re-homing is the most consequential correction in the milestone).
- **The cut lever is NOT pulled this sprint and no signal calls for it.** The first checkpoint is
  end-of-S10. Per the Cut-Lever Policy's **anti-signal**: a sprint that lands fewer stories than
  planned for *decision* reasons (unratified rulings, unowned VSync/hardware calls) is **not** a
  lever signal. Every M01 slip came from a blocked decision, never from capacity — check which one
  it is before cutting scope.
- **Scope check:** all 14 committed stories are drawn from existing epics with existing story files
  (villager-ai-behavior, build-validation-navigability, needs-mood-system, building-system). No
  story was fabricated. Two Cluster 0 items were deliberately **not** scheduled and one is blocked;
  three items are recorded under Missing Stories rather than invented. Run `/scope-check sprint-9`
  before implementation.
- **Velocity:** ~~11 Must + 2 Should + 1 Nice = **14 stories**~~ → **AMENDED 2026-07-26 (second):
  14 Must + 2 Should + 1 Nice = 17 stories**, of which **3 are already Complete** (`villager-ai-026`,
  `build-validation-001`, `villager-ai-021`) → **14 remaining**, at the top of the measured 8–13/session
  band. Max Must lane **~6.5** lane-days (gdscript) inside 8 available — headroom down from ~4.0 to ~1.5.
  The 2-day buffer's primary consumer (`villager-ai-026`'s proof) is **discharged**; re-point the freed
  reservation at `vox-021`'s boot measurement and `vox-020`'s budget/ordering assertions, alongside
  `build-validation-010`'s CI ceiling. **Recommended trim: drop `building-011` (Nice) now; demote
  `build-validation-005` (Should) to S10's opener on signal — never `build-validation-010`.**
- **We will know this sprint was scoped right if:** `villager-ai-026` lands on day one with zero
  test edits; `build-validation-004` renders a Room/Sealed verdict against the real movement graph;
  `needs-mood-003`'s ladder is table-driven and a novel source id works with no code change; and a
  human can open the Valley, see villagers in it, and watch a ghost preview follow their cursor —
  three things that were all false at the start of this sprint.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story`, then
  sequence **`villager-ai-026` FIRST** (it gates the binding lane) with `needs-mood-001`,
  `building-023` and `villager-ai-021` opening the other three lanes in parallel.


### Lane-Korrektur (2026-07-26)

Die Needs-&-Mood-Lane war im Plan als `systems-designer` gefuehrt. Der
systems-designer-Agent hat die Story korrekt abgelehnt: `.gd`-Dateien
routen laut `.claude/docs/technical-preferences.md` und den
Koordinationsregeln zum `godot-gdscript-specialist`; der Designer haelt
die Domaene (Formeln, Tuning-Tabellen), nicht die Implementierung. Er hat
vor dem Ablehnen geprueft, dass keine Design-Entscheidung mehr offen ist
(F1-F4 und die Tuning-Ranges stehen vollstaendig im GDD, CD Ruling 1 hat
die letzte Zahl geklaert). Lane korrigiert auf
`godot-gdscript-specialist`; die Domaenen-Zuordnung im Plan bleibt
`systems-designer` als fachlicher Owner fuer Review.


---

## Sprint Result — CLOSED 2026-07-26

**17/17 scheduled stories complete** (building-011 was deliberately moved to S10 mid-sprint on the producer's trim recommendation). Suite grew 953 -> 1198, green with 0 orphans on every story commit.

**The sprint's real theme turned out to be: the game became startable.** Three gaps between "the systems work" and "you can play it" were found and closed, none of which any green test suite had ever revealed:
- **No world existed at boot.** generate_terrain had been implemented since vox-006 and called nowhere. scene-005 landed the genesis phase; boot measured 2.59s against a 3.0s ceiling.
- **Fresh terrain could stay invisible.** vox-020 found the grid never signalled when a chunk became resident, so a chunk meshed before its page-in landed kept a null mesh forever; it also moved rebuilds out of the signal handler into a shared budgeted drain.
- **The player drew blind.** building-023 landed the ghost preview — and while doing so exposed a real bug in already-shipped code: multi-frame drags resolved their release cell one cell too high.

**Payoff chain**: build-validation 001-006 complete (candidate cells -> regions -> outside-connection trace -> ROOM/SEALED verdict -> analysis pass lifecycle -> shelter classification), and needs-mood 001-003 complete (config + BLOCKING ladder invariant -> decay + urgent signal -> the three-rung recovery ladder). Criterion #5's two halves now exist; their live pairing is needs-mood-010's job.

**Cross-check**: bv-010's corpus found ZERO disagreements between Build Validation's reachability trace and the villager nav graph across 9,600 verdicts.

Findings recorded for future work: the recurring fixture trap (sealing a gap with a solid block creates a legal step-up and reopens the escape — found independently twice); the nav-graph build cost 6.7s at the shipped region size until scene-005 measured it; the corpus ships at 1/10 sample density against a hard CI ceiling (escalated to TD, not absorbed).

Carried to S10: building-011 (plan-only undo), presentation-003 (villager bodies — specced by the TD, story not yet authored), needs-mood 004-011, build-validation 007-009, the Cluster D UI epics.
