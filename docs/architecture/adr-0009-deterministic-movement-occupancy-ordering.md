# ADR-0009: Deterministic Movement/Occupancy Intra-Frame Ordering

## Status
Accepted (2026-07-11 — dependency ADR-0007 accepted after spike QQ3 PASS; see prototypes/perf-spike-qq3/REPORT.md. User-delegated decision.)

**(Slice propagation 2026-07-23)** Remains Accepted. Extended in place for the vertical-slice batch: occupancy now covers the villager's **body-column** derived from the discrete `current_cell` (2-block character scale); the **unstuck watchdog teleport** is added as a second sanctioned discrete `current_cell` mutation path (the "never teleport / only place it changes" wording is revised accordingly); **seal prevention** is recorded as a new consumer of discrete occupancy. Determinism guarantees are unchanged. See `change-impact-2026-07-23-slice-batch.md`.

**(Story villager-ai-024, 2026-07-27)** Remains Accepted. The wall-plateau fix adds a **third and fourth sanctioned discrete `current_cell` mutation**, both realizing one generalized rule ("when this villager's own construction work leaves it standing somewhere `VillagerNavGraph` cannot reach from anywhere else, move it to the nearest standable cell that IS reachable") through two directional call sites sharing one mutation primitive (`VillagerAi._snap_current_cell_to`): (3) `VillagerAi.climb_onto_self_sealed_cell` — called by `VillagerSealPreventionGate` at the instant its pre-existing self-seal exemption fires, steps the villager to `sealed_cell + (0,1,0)` deterministically (no search — this direction must land exactly on the column's next blueprint cell); and (4) `VillagerAi._relocate_if_marooned` — called by `VillagerAi._complete_claimed_job`/`_abandon_claimed_job` the instant a claim finishes or is revoked, reuses `VillagerRescueTargetSearch.find_rescue_target` (the SAME BFS/tie-break the watchdog already trusts, never a second search) to find the nearest reachable standable cell when finishing a column leaves the villager on an isolated graph node with nothing left to build there. Root cause this fixes: `VillagerNavGraph` only ever connects cells with a non-zero HORIZONTAL offset (a "step" is inherently horizontal); a cell directly above another in the same column can never coexist as a standable graph point with it, so a wall column's 3rd layer and above patches in as a genuinely edge-less point once its own support cell goes solid — reachable from nowhere, by construction, independent of tick budget. Neither addition widens the Unstuck Watchdog's own `stuck_tick_count` trigger to `State.WANDERING` (Story villager-ai-019's Edge Case 2 — a genuinely walled-in Idle/Wandering villager still stays put, never rescued — is completely unaffected: both new mutation points are reachable ONLY through a just-finished/just-revoked CONSTRUCTION claim, never through a Wandering re-entry into Deciding). Determinism guarantees are unchanged (both directions are pure functions of already-deterministic state — a fixed offset, or the SAME deterministic BFS/tie-break the watchdog already uses — no RNG, no wall-clock). See `docs/architecture/control-manifest.md`'s own updated bullet and `production/epics/villager-ai-behavior/story-024-villagers-cannot-finish-a-wall.md`'s AC2 write-up for the full root-cause evidence.

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Core / Scripting (signal timing, movement interpolation) |
| **Knowledge Risk** | LOW-MEDIUM — no dedicated engine-reference module; verifies an already-assumed synchronous-signal-emission guarantee and checks relevance of Godot 4.5's physics-interpolation rearchitecture (this project hand-rolls its own interpolation, likely making that change irrelevant) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — synchronous signal emission is accurate and unchanged 4.4→4.7; 4.5's physics-interpolation rearchitecture is irrelevant to this hand-rolled design, with one defensive `physics_interpolation_mode = OFF` note added. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0007 (AI Pathfinding, Navigation & Room-Analysis) — shares Voxel World's occupancy data and the walkability predicates this ADR's occupancy semantics must stay consistent with |
| **Enables** | Villager AI and Building System `/dev-story` implementation, specifically the movement/occupancy-check code paths both flagged as an unresolved seam |
| **Blocks** | Both systems' implementation of the affected code paths (F4 nudge-aside targeting, walled-in detection, Building's deferred-construction check) |
| **Ordering Note** | None beyond depending on ADR-0007 |

## Context

### Problem Statement
`building-system.md` (TR-building-system-040) and `villager-ai-behavior.md` (TR-villager-ai-behavior-046) both independently flag the same unresolved seam: villager movement is continuous visual interpolation (F1's "never snap/teleport" rule), while Building System's construction-completion and its "never solid under a character" guarantee (Building's deferred-construction rule, TR-building-system-037) are tick-discrete. During a villager's mid-transit between two cells, which cell does it "occupy" for the purposes of an occupancy check, F4's nudge-aside targeting, and Edge Case 2's walled-in detection? Neither GDD resolves this — both defer it to "the building/AI ADR," which is this one.

### Constraints
- F1: villager movement is continuous per-frame interpolation for visual smoothness; must never snap or teleport (TR-villager-ai-behavior-042)
- F1 also establishes tick-boundary-only arrival crediting: "work progress credited only at tick boundaries, never partial-tick" (TR-villager-ai-behavior-029) — the discrete-arrival principle already exists for construction progress, just not yet stated for occupancy
- F4's nudge-aside step already states "target cell stays deferred until the step completes" (TR-villager-ai-behavior-034) — an existing precedent for exactly this kind of discrete-until-arrival semantics
- Building System's deferred-construction rule (TR-building-system-037) needs an unambiguous, single-cell answer to "is a character occupying this cell" — not a blended/interpolated one
- Godot signals are assumed to fire synchronously elsewhere in this project (Building System's self-write-exemption reasoning, TR-building-system-024) — this ADR must confirm that assumption still holds and lean on it explicitly here

### Requirements
- A single, unambiguous rule for "which cell does a mid-transit villager occupy," consulted identically by Building System's occupancy check, Villager AI's F4 targeting, and walled-in detection
- The rule must not require Building System or any consumer to reason about interpolation progress (a float 0.0-1.0) at all — occupancy must be a discrete cell, always
- A closed answer to the actual race: if Building System's write would solidify a cell a villager is currently interpolating toward, what stops the villager from visually clipping through newly-solid geometry, and for how long is that window open

## Decision

**A villager's occupied cell is always discrete and tick-boundary-quantized — it occupies `from_cell` for the entire duration of a travel step, becoming `to_cell` atomically only at tick-boundary arrival. Continuous visual interpolation is a pure rendering concern with zero bearing on any logic query. The residual visual-clipping race is closed by Godot's synchronous signal emission, which lets the existing re-path-on-blocking-write contract redirect a villager before its next frame's interpolation step — no new mechanism, an explicit statement of an implicit ordering.**

**(Slice propagation 2026-07-23) Body-column occupancy.** With the 2-block character scale, a villager's occupancy is a **body-column** — the discrete `current_cell` (feet) plus the cell(s) directly above spanning the villager's height — NOT a single cell. Every occupancy query below reads/derives this column from the single authoritative discrete `current_cell`; the tick-boundary-quantized principle is unchanged, only the cardinality (one cell → a column derived from it). No consumer reasons about interpolation progress; the column is a pure function of `current_cell`.

**(Slice propagation 2026-07-23) Watchdog teleport — a second sanctioned discrete mutation.** The original "must never snap or teleport" (F1) is now qualified: the **unstuck watchdog** (villager-ai Rule 15/F5) performs a *sanctioned, deterministic* teleport of a Traveling/Working villager to a rescue cell. This is a discrete jump, not interpolated travel — it sets `current_cell` atomically at a tick boundary and snaps `_visual_position` to match. Determinism is preserved: the rescue fires at a deterministic stuck-tick threshold and the target is chosen by an expanding-ring BFS with the F2 lexicographic (`y,x,z`) tie-break.

**(Story villager-ai-024, 2026-07-27) Construction-completion relocation — a third and fourth sanctioned discrete mutation.** Two more deliberate jumps, one generalized rule ("move the builder to the nearest reachable standable cell when its own work leaves it somewhere the nav graph cannot reach") realized in two directions: (c) `VillagerAi.climb_onto_self_sealed_cell` — a deterministic `+1` in Y at the exact instant villager-ai Rule 16's self-seal exemption fires, so the villager lands exactly on the wall column's next blueprint cell instead of staying entombed; and (d) `VillagerAi._relocate_if_marooned` — a search-based jump (reusing the SAME expanding-ring BFS/tie-break (b) already uses, never a second one) the instant a construction claim finishes or is revoked, if doing so left the villager on a now-isolated graph node with nothing left to build there. Both are atomic, tick-boundary-adjacent (fired from within the SAME tick's construction-completion handling, never mid-frame), and snap `_visual_position` to match, mirroring (b)'s own "no lerp" discipline exactly.

`current_cell` therefore changes at exactly FOUR sanctioned points: (a) tick-boundary travel arrival, (b) a watchdog rescue at a tick boundary, (c) a self-seal climb at the instant of a self-sealing completion write, and (d) a marooned-relocation at the instant a construction claim finishes/is revoked and leaves the villager unreachable — all discrete, all either tick-quantized or fired synchronously within a tick's own construction-completion handling. The "never teleport" prohibition remains true for *ordinary travel* (interpolation must never snap); (b)/(c)/(d) are the deliberate, narrowly-scoped exceptions.

**1. Two-layer position model.** Every villager exposes:
```gdscript
var current_cell: Vector3i        # DISCRETE — the sole authoritative value for
                                    # every logic/occupancy query, ever
var _visual_position: Vector3      # CONTINUOUS — interpolated every frame for
                                    # rendering ONLY, never read by any logic
```
While `TRAVELING`, `current_cell` remains the villager's `from_cell` for the entire step; it updates to `to_cell` in a single atomic assignment exactly at the tick boundary where F1's arrival is credited (the same tick-boundary-only crediting rule TR-villager-ai-behavior-029 already established for construction progress — this ADR applies the identical principle to occupancy). `_visual_position` is a separate, purely cosmetic value, lerped every `_process` frame from `from_cell`'s world position toward `to_cell`'s world position, scaled by intra-tick progress — it is never read by Building System's occupancy check, Villager AI's own F4 targeting, or walled-in detection.

**2. Occupancy check semantics.** Building System's deferred-construction check (TR-building-system-037: "is a character occupying this cell") queries `current_cell` — the discrete value — never `_visual_position` and never an interpolation-progress float. A villager mid-transit from A to B occupies A, full stop, until tick-boundary arrival; B is not considered occupied by them before that. This gives Building System (and every other consumer — F4 targeting, walled-in detection) a single, unambiguous cell per villager at all times, matching F4's own already-stated precedent ("target cell stays deferred until the step completes"). **(Slice propagation 2026-07-23)** Where a consumer needs the villager's full footprint (seal prevention, walled-in detection at 2-block scale), it derives the body-column from this same discrete `current_cell` — the derivation is deterministic and interpolation-free, so the "single unambiguous answer" property holds for the column exactly as it did for the single cell.

**(Slice propagation 2026-07-23) 2b. Seal prevention is a new consumer of these semantics.** Villager AI's seal-prevention rule (villager-ai Rule 16/F6) gates a Planned→Built write that would entrap a villager: the check reads the discrete `current_cell`/body-column (never `_visual_position`) to decide whether the write would seal a villager in — a negative-write gate the Building System write path must accept. This reinforces rather than changes this ADR: it is precisely why occupancy must be a single unambiguous discrete answer. (The one deliberate exception — a builder sealing itself with its own same-job completion write — proceeds unconditionally and is self-healed by the watchdog, per villager-ai Rule 16.)

**3. The residual race — visual clipping — is closed by signal ordering, not a new mechanism.** Consider: a villager is interpolating from A toward B; Building System completes construction at B in the same tick (legitimately, since the villager's discrete `current_cell` is still A, not B). The villager's continuous interpolation is still headed toward B and could, without intervention, visually pass through B's newly-solid geometry for the remainder of that step. This is closed by an already-existing contract, not a new one: Voxel World's write signal (`cell_changed`) fires synchronously (Godot's standard signal-emission behavior, confirmed below), so Villager AI's already-GDD-mandated re-path filter (TR-villager-ai-behavior-012/036: "mid-travel re-path required when a Voxel World write blocks the current path") receives the notification in the same call stack as Building's write — before the next frame's `_process` advances `_visual_position` any further. The villager's travel target is redirected (or the step aborted) at that point, bounding the worst-case visual-clipping window to at most the interpolation progress already computed before the write happened in that same frame — not a full tick, and not an indefinite pass-through.

### Architecture Diagram
```
Villager TRAVELING from cell A to cell B:
  current_cell = A                              (discrete, unambiguous)
  _visual_position = lerp(world(A), world(B), intra_tick_progress)  (cosmetic only)

Every consumer of occupancy reads current_cell, NEVER _visual_position:
  Building System's deferred-construction check → current_cell
  Villager AI's own F4 nudge-aside targeting     → current_cell
  Walled-in / Edge Case 2 detection              → current_cell

Race closure (same frame, same call stack — Godot signals are synchronous):
  Building System writes cell B solid
        │
        ▼ (synchronous signal, same call stack, same frame)
  Voxel World emits cell_changed(B, ...)
        │
        ▼ (synchronous connection, same call stack)
  Villager AI's re-path filter (TR-012/036, already GDD-mandated)
  redirects/aborts the current travel step
        │
        ▼ (next _process frame)
  _visual_position stops advancing toward the now-solid B;
  villager re-paths around it — clipping window bounded to the
  frame(s) between the write and the redirect, not indefinite

At tick boundary (only): current_cell atomically becomes B, IF the
villager actually arrives (i.e., wasn't redirected away first)
```

### Key Interfaces
```gdscript
# Villager AI's public occupancy query (extends architecture.md's API Boundaries):
func get_current_cell(villager_id: int) -> Vector3i   # ALWAYS discrete, never derived from interpolation progress

# Internal implementation detail — the two-layer model:
var current_cell: Vector3i     # authoritative, tick-boundary-quantized
var _from_cell: Vector3i
var _to_cell: Vector3i
var _visual_position: Vector3  # cosmetic only

func _process(_delta: float) -> void:
    # Recompute visual position every frame from _intra_tick_progress ONLY —
    # never touches current_cell. NOTE: _intra_tick_progress is advanced by the
    # tick system (game_delta), NOT by this raw-delta _process. When the game is
    # paused (game_delta = 0) ticks stop firing, so _intra_tick_progress is frozen
    # and _visual_position resolves to the same point every frame — villagers do
    # NOT glide while paused. This _process only re-reads a tick-owned value; it
    # must never integrate raw `_delta` into _intra_tick_progress itself, which
    # would violate technical-preferences.md's game_delta-only rule for entity
    # motion (the raw-delta exemption is for camera/UI/overlays, not villagers).
    _visual_position = _from_cell.lerp(_to_cell, _intra_tick_progress)

func _on_tick() -> void:
    # tick-boundary arrival crediting — one of the two sanctioned places
    # current_cell changes (the other is a watchdog rescue, below). Both are
    # tick-boundary discrete mutations; neither is derived from interpolation.
    # (Slice propagation 2026-07-23)
    if _travel_complete():
        current_cell = _to_cell
        ...

func _on_watchdog_rescue(rescue_cell: Vector3i) -> void:
    # (Slice propagation 2026-07-23) The SECOND sanctioned discrete mutation of
    # current_cell — a deterministic teleport (villager-ai F5). Sets current_cell
    # atomically and snaps _visual_position to match; villager re-enters Deciding.
    # NOT interpolated travel — the "never snap" rule applies to ordinary travel,
    # not this deliberate rescue exception.
    current_cell = rescue_cell
    _visual_position = current_cell  # snap; no lerp for a rescue
    ...
```

## Alternatives Considered

### Alternative A: Discrete `current_cell` (tick-quantized) + cosmetic-only continuous interpolation — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: single, unambiguous occupancy answer at all times, for every consumer; no consumer ever needs to reason about interpolation progress; reuses the tick-boundary-crediting principle and the synchronous-signal/re-path-on-write contract this project already committed to elsewhere — no new mechanism invented.
- **Cons**: a villager's `current_cell` "lags" its visual position slightly (it's still `from_cell` even when visually most of the way to `to_cell`) — a naming/mental-model subtlety a future contributor must understand.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Interpolation-progress-aware occupancy (a villager occupies "both cells, weighted by progress")
- **Description**: occupancy checks consider a villager to partially occupy both `from_cell` and `to_cell`, weighted by interpolation progress, with some threshold (e.g. >50% progress) flipping which cell "counts."
- **Pros**: might feel more visually accurate at the exact midpoint of a transit.
- **Cons**: every consumer (Building System, F4 targeting, walled-in detection) would need to handle a two-cell or probabilistic occupancy answer instead of one clean cell — real complexity spreading to every consumer for a distinction that provides no gameplay value (nothing in any GDD asks for partial-occupancy semantics).
- **Rejection Reason**: solves a precision problem nothing asked for, at a real complexity cost spread across every consumer.

### Alternative C: Snap-to-cell occupancy updates mid-transit (occupancy flips at the interpolation midpoint, not tick boundary)
- **Description**: `current_cell` flips from `from_cell` to `to_cell` when visual interpolation crosses 50% progress, independent of tick boundaries.
- **Pros**: occupancy "feels" more visually synchronized with the villager's apparent position.
- **Cons**: contradicts F1's own tick-boundary-only crediting principle (TR-villager-ai-behavior-029) and introduces a SECOND timing model (interpolation-progress-based) alongside the tick-based one already established for construction progress — two clocks governing the same kind of state is exactly the pattern this project's `architecture.md` Data Flow section avoided elsewhere (raw delta for cosmetics, game-tick for logic, never blended).
- **Rejection Reason**: introduces a second, competing timing model where a consistent one (tick-boundary-only) already exists and works.

## Consequences

### Positive
- Every consumer of villager occupancy gets one clean, discrete cell, always — no interpolation-aware logic needed anywhere outside the movement system itself.
- Closes both GDDs' flagged seam using contracts already committed to elsewhere (tick-boundary crediting, synchronous signals, re-path-on-write) rather than inventing new machinery.
- F4's pre-existing "target cell stays deferred until the step completes" language is now the stated GENERAL rule, not a special case only nudge-aside follows.

### Negative
- The clipping-window bound ("at most the interpolation progress already computed before the write, that same frame") is a soft, frame-timing-dependent guarantee, not a hard zero — a villager could, in principle, show a single frame of visual overlap with newly-solid geometry before redirecting. Not eliminated, bounded.
- Requires discipline: any future code that's tempted to read `_visual_position` for a logic decision (e.g., "is the villager close enough to X to interact") must use `current_cell` instead, or risk reintroducing exactly the ambiguity this ADR resolves.

### Risks
- **Risk** (defensive clarification added during engine-specialist validation): Godot's `Node.physics_interpolation_mode` defaults to `INHERIT`, and the project-wide `physics/common/physics_interpolation` setting (default OFF) could, if ever enabled for an unrelated reason elsewhere in the project (e.g. VFX smoothing), stack Godot's own built-in transform interpolation on top of this ADR's hand-rolled `_visual_position` lerp — double-interpolation jitter — but only if a villager's visual node is ever a physics body (`CharacterBody3D`/`RigidBody3D`) moved in `_physics_process` elsewhere, which nothing in this ADR's design does.
  **Mitigation**: set the villager's visual node's `physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` explicitly, defensively, rather than relying on the project-wide default ever staying OFF.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed the synchronous-signal-emission claim is accurate and unchanged across 4.4→4.7 — default (non-`CONNECT_DEFERRED`) signal connections have always invoked connected callables synchronously, within the `emit()` call stack, in connection order; this is core `Object`/`Signal` behavior, not something any version-pinned breaking-changes entry touches. Confirmed the "hand-rolled interpolation makes 4.5's physics-interpolation rearchitecture irrelevant" reasoning is correct, with one defensive gotcha flagged (addressed above): Godot's built-in physics interpolation could theoretically stack with this ADR's hand-rolled lerp if the project-wide setting were ever enabled elsewhere and the villager's visual node were a physics body — neither is true in this design, but explicit `physics_interpolation_mode = OFF` is cheap insurance. Verdict: "safe to accept as written," with that one addition, now included above.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| building-system.md | TR-building-system-040: "Mid-path solidification race: intra-frame ordering between AI position update and occupancy check is undefined" | Discrete `current_cell` + synchronous re-path-on-write, Decision §1-3 |
| villager-ai-behavior.md | TR-villager-ai-behavior-046: "Mid-path solidification race... also affects F4 targeting and walled-in queries" | Same discrete `current_cell` serves F4 targeting and walled-in detection identically, Decision §2 |

## Performance Implications
- **CPU**: Negligible — no new computation, just a clarified read-path (occupancy reads `current_cell`, an existing field, instead of an ambiguous or nonexistent value).
- **Memory**: Negligible — `current_cell`/`_visual_position` split is two existing-scale fields, not new data structures.
- **Load Time**: N/A.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- A unit test places a villager mid-transit (from_cell set, to_cell set, interpolation progress > 0 but < 1) and asserts `get_current_cell()` returns `from_cell`, not `to_cell` and not an interpolation-derived value.
- A unit test simulates a Voxel World write at a villager's `to_cell` mid-transit and asserts the re-path filter fires within the same synchronous call stack (not deferred to next frame), redirecting the villager before `_visual_position` advances further toward the now-solid cell.
- Grep-verifiable: `_visual_position` (or equivalent) is never referenced outside the movement/rendering code path — no occupancy, targeting, or walled-in check reads it.

## Related Decisions
- Depends on ADR-0007 for the walkability predicates and Voxel World occupancy data this ADR's `current_cell` semantics must stay consistent with.
- Reuses the synchronous-signal assumption already established informally in `building-system.md`'s self-write-exemption reasoning — this ADR is the first to state it as a load-bearing architectural guarantee rather than an incidental note.
