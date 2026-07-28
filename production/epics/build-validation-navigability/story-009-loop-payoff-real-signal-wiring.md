# Story 009: Loop-payoff surface receives real signals (milestone criterion #7)

> **Epic**: Build Validation & Navigability
> **Status**: Complete (2026-07-27 — 1541/1541 suite green, 0 orphans, parent-verified; carried twice from Sprint 10, delivered)
> **Layer**: Feature (wiring into Presentation)
> **Type**: Integration
> **Estimate**: ~0.5 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md` (Rule 10 signal contract) + `production/milestones/milestone-02-mvp-completion.md` criterion #7
**Requirement**: `TR-build-validation-navigability-039`, `TR-build-validation-navigability-040`, `TR-build-validation-navigability-036`, `TR-build-validation-navigability-045`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern)
**ADR Decision Summary**: Injected-tier wiring only — the presentation surface binds to this module's signals through typed `@export` references wired in `GameWorld.tscn`, with all wiring in an explicitly-callable `setup()`. `LoopPayoffSignalSurface` is documented as *"the shared dependency later systems bind to"*; this story is that binding.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Default (synchronous) connections preserve Rule 10's "one pass, one frame" reconciliation unit — do not add `CONNECT_DEFERRED` on this path.

**Control Manifest Rules (this layer)**:
- Required: injected-tier binding; `setup()` asserts the surface reference is wired; `_ready()` does nothing beyond optionally calling `setup()`.
- Forbidden: placeholder/stub emitters remaining anywhere on the payoff path; reshaping `LoopPayoffSignalSurface`'s parameter list (its own contract: a new payoff kind is a new `payoff_type` value, *"never a new signal or a reshaped parameter list"*).
- Guardrail: the wiring adds no analysis work — it is a pure adapter over emissions story 006/007 already produce.

**RESOLVED — the signal is untouched; a typed, optional detail sidecar carries the
pacing contract** (was Epic Known Conflict 5). Creative-director **Ruling 2**,
`production/creative-decisions-m02-preflight-2026-07-26.md` — **PROVISIONAL,
pending user ratification** (away-mode ruling; treat as the planning assumption
until ratified). **The CD ruled the experience requirements and a shape that meets
them; the technical-director owns the final implementation form** and may
substitute an equivalent (`Resource` vs `RefCounted`, geometry handle vs inline
cells) **provided the six minimums below stay assertable and constraints 1–4
hold**. TD concurrence on the form is still outstanding.

**Ruling shape:**

```
signal payoff_signaled(payoff_type: StringName, subject: StringName)   # UNCHANGED, byte-identical

func emit_payoff(payoff_type: StringName, subject: StringName,
                 detail: PayoffDetail = null) -> void                   # trailing optional
func get_payoff_detail(payoff_type: StringName, subject: StringName) -> PayoffDetail
```

`PayoffDetail` is a small **typed** `RefCounted` (not a `Dictionary` — static
typing is enforced project-wide) carrying, for the recognition kinds:
`celebrate: bool`, `group_id: StringName`, `subjects: Array[StringName]`,
`cells: PackedVector3Array`.

**Binding implementation constraints (the load-bearing part, not the class shape):**
1. `_active_payoffs[key]` **and** the detail are written **BEFORE**
   `payoff_signaled.emit(...)`, so a synchronous handler calling
   `get_payoff_detail()` from inside the handler sees the current record. Without
   this ordering the sidecar is useless.
2. `clear_payoff()` erases the detail alongside the key — no orphaned payloads.
3. No `CONNECT_DEFERRED` anywhere on this path — promoted from a comment to an
   **asserted grep-guard**.
4. Presentation holds **no** reference back to the analysis module. Everything
   needed to draw the beat arrives with the event.

**Type / subject assignment:**

| Emission | `payoff_type` | `subject` | Detail carries |
|---|---|---|---|
| Same-pass recognition group | `&"room_celebrated"` | **the `pass_group_id`** | `celebrate=true`, all member room keys, all cells |
| Later-pass recognition inside cooldown | `&"room_recognized_quiet"` | region key | `celebrate=false`, `group_id` |
| Shelter change | `&"shelter_status"` | **item id** | `sheltered: bool` |

The rule this encodes: **`payoff_type` distinguishes KINDS — things with a
different presentation treatment and a separate lifetime. Per-occurrence facts go
in the detail.** `celebrate` passes the kind test (cue vs. no cue; the two must not
refresh each other). `sheltered` fails it — same channel, one live state per bed;
two types would leave a toggling bed with two stale live keys and break this
story's own idempotency AC, so **shelter uses ONE type with the flag in the
detail**. `pass_group_id` is never a kind. Choosing `subject = pass_group_id` for
celebrations is deliberate: the idempotency key *becomes* the celebration event,
so "a same-pass group is ONE celebration" is provable via
`get_active_payoff_count()` rather than inferred.

**Contract compliance**: the contract's purpose is that a consumer never changes
its subscription when a new payoff kind appears. A trailing optional parameter and
an additive accessor preserve that exactly — a consumer that ignores `detail`
compiles and behaves verbatim, and the signal itself does not move.

---

## Acceptance Criteria

*From milestone criterion #7 and GDD Rule 10's signal contract, scoped to this story:*

- [ ] The loop-payoff surface fires off the **genuine** `room_recognized` emission — with `celebrate` / `pass_group_id` / member subjects / cells carried in the typed `PayoffDetail` sidecar per CD Ruling 2 — not a stub. `payoff_signaled`'s parameter list is **unchanged**.
- [ ] The loop-payoff surface fires off the **genuine** `shelter_status_changed` emission as **one** `payoff_type` (`&"shelter_status"`), `subject` = item id, with `sheltered: bool` in the detail — never two payoff types, not a stub.
- [ ] **Ordering constraint 1**: the `_active_payoffs` entry and its detail are written **before** `payoff_signaled.emit(...)` — a synchronous handler calling `get_payoff_detail()` from inside the handler reads the current record. Asserted, not assumed.
- [ ] **Ordering constraint 2**: `clear_payoff()` erases the detail alongside the key — no orphaned payloads (asserted).

**The CD's six assertable minimums for the first celebration a player ever sees** (Ruling 2):

- [ ] **1 — One group, one cue.** Every room recognized in the same analysis pass produces exactly one chime and one highlight sweep tracing *all* of them. *Assert*: emit N ∈ {2,3} same-pass recognitions → the celebration type's live-key count grows by **exactly 1**; `detail.subjects.size() == N`; the cue-trigger spy is invoked **exactly once**.
- [ ] **2 — It lands on the same beat as the last cell.** Synchronous, same frame, no queue. *Assert*: the surface's frame counter at receipt equals the emission frame; **grep-guard** proves no `CONNECT_DEFERRED` on the payoff path.
- [ ] **3 — The first celebration of a session is never suppressed.** The cooldown window **may only be armed by a celebration that actually fired a cue** — never by a load-pass emission, never by a quiet emission, never by transient seal/unseal churn during a natural build order (boxing four walls then carving the doorway is a real Sealed state and a real emission). *Assert*: given prior in-window pass activity but **no prior fired celebration**, the next `room_recognized` still arrives with `celebrate = true`. *(At TPS 4.0 the window is 5 s, not the GDD's stale "10s at 1x" — the shorter window makes accidental suppression less likely but does **not** substitute for this rule.)*
- [ ] **4 — It reads as caused by the player's last action.** The highlight traces *the room the player just closed*, so the geometry **travels with the event** and is never re-queried afterward (a later pass can split or merge the region between emission and query). *Assert*: `detail.cells` is non-empty and equals the recognized region's cells **as of the emitting pass**.
- [ ] **5 — Nothing competes with it.** No HUD, no toast (building-ui Rule 9d — the celebration is exclusively in-world). *Assert*: grep-guard proves no HUD/toast consumer binds the celebration type; when a Building command-completion flourish and the room cue fire in the same pass, the observed order is **flourish-then-room, deterministically**. *(The "follows by a breath rather than stacking" stagger is presentation-owned and **not yet specified anywhere** — this story guarantees observable ordering only.)*
- [ ] **6 — A first-time player can tell what was just acknowledged.** *(Playtest, needs-mood story 011 — the actual acceptance criterion; 1–5 are its preconditions.)* Immediately after the first celebration the tester is asked *"what just happened?"* and identifies the room without prompting.
- [ ] A **grep-guard proves no placeholder emitter remains on the payoff path** — the guard is part of the test suite, not a one-off manual check.
- [ ] Pacing survives the adapter: a same-pass group of recognitions reaches the surface as **one** celebration event (`subject = pass_group_id`, `celebrate = true`), and a later-pass recognition inside `room_cue_cooldown_ticks` reaches it as `&"room_recognized_quiet"` (`celebrate = false`) — never as a second celebration.
- [ ] `emit_payoff`'s existing idempotency holds under real emissions: re-emitting the same `(payoff_type, subject)` key refreshes in place and never grows `get_active_payoff_count()`. A bed toggling sheltered ↔ unsheltered keeps **exactly one** live key (this is why `sheltered` is a detail field, not a second type).
- [ ] **Additivity**: a consumer that ignores `detail` compiles and behaves verbatim — proven by keeping one existing two-arg consumer unmodified in the test.
- [ ] The binding is injected-tier: the surface reference is a typed `@export` wired in the scene, asserted in `setup()`, and the whole path is exercisable headless with a mocked surface.
- [ ] This story adds **no** analysis behavior — the adapter emits only in response to emissions stories 006/007 already produce, and the four-signal contract (TR-039) is unchanged.

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

- The adapter is thin by design: subscribe to `room_recognized` and `shelter_status_changed`, translate to `emit_payoff(payoff_type, subject, detail)`. Per CD Ruling 2, `subject` is the **item id** for shelter and the **`pass_group_id`** for a celebration (region key for the quiet kind).
- Scope delta from the ruling: this story **gains** the `PayoffDetail` type and the write-before-emit ordering constraint, and **loses** the back-query variant entirely (presentation never re-queries the analysis module — that would invert ADR-0001's injection direction and break minimum 4).
- Building UI has ruled `room_recognized` has **no HUD surface** (its Rule 9d) — the celebration is exclusively the in-world highlight + chime. Do not route it to a HUD.
- The grep-guard should assert the absence of the scaffolding-era stub emitters in `neues-spiel/src/` on the payoff path, in the same style as the project's existing non-writer grep guards.
- Milestone evidence expects both a test and a written capture: `neues-spiel/tests/integration/presentation/loop_payoff_real_signal_test.gd` plus `production/qa/evidence/loop-payoff-wired-evidence-*.md`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 006/007: the emissions themselves and their pacing logic.
- Story 008: the Warning/Info tiers (not part of criterion #7's payoff path).
- `presentation-001` / Art Bible: the highlight and chime treatment.

---

## QA Test Cases

- **Real `room_recognized`**: Given a region transitioning to Room, When the pass completes, Then the surface receives a payoff for it with the pacing contract intact.
- **Real `shelter_status_changed`**: Given a bed transitioning to sheltered, When the pass completes, Then the surface receives a payoff carrying that item id.
- **Grep-guard**: Given the source tree, When the guard runs, Then no placeholder/stub emitter is found on the payoff path.
- **Same-pass group (minimum 1)**: Given N ∈ {2,3} rooms recognized in one pass, When observed at the surface, Then the celebration type's live-key count grows by exactly 1, `detail.subjects.size() == N`, and the cue spy fired exactly once.
- **Same frame (minimum 2)**: Given an emission, When received, Then the receipt frame equals the emission frame; grep-guard finds no `CONNECT_DEFERRED` on the path.
- **First-celebration suppression (minimum 3 — NOT currently covered; add it)**: Given in-window prior pass activity but no prior *fired* celebration (load-pass emission, quiet emission, or transient seal/unseal churn), When the next `room_recognized` arrives, Then `celebrate = true`. Companion: a celebration that **did** fire arms the window.
- **Geometry travels (minimum 4)**: Given a recognition, When the detail is read, Then `cells` is non-empty and equals the region's cells as of the emitting pass — including when a later pass splits or merges that region afterwards.
- **No competition (minimum 5)**: Grep-guard proves no HUD/toast consumer binds the celebration type; given a command-completion flourish and a room cue in one pass, the observed order is deterministically flourish-then-room.
- **Cooldown**: Given a recognition in a later pass inside the cooldown window, When observed, Then it arrives as `&"room_recognized_quiet"` with `celebrate = false`, not a celebration.
- **Idempotency**: Given the same `(payoff_type, subject)` emitted twice, When measured, Then `get_active_payoff_count()` is unchanged. Given a bed toggling sheltered ↔ unsheltered, Then exactly one live key exists at all times.
- **Write-before-emit**: Given a synchronous handler that calls `get_payoff_detail()` from inside the handler, When it runs, Then it reads the current record, not `null` and not the previous one.
- **Detail cleanup**: Given `clear_payoff()`, When called, Then the detail is erased alongside the key.
- Edge cases: the load pass produces zero payoff emissions (transitions are silent there); a missing surface reference makes `setup()` assert rather than silently no-op.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `neues-spiel/tests/integration/presentation/loop_payoff_real_signal_test.gd` — must exist and pass. Companion capture: `production/qa/evidence/loop-payoff-wired-evidence-*.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 006 (`shelter_status_changed`), 007 (`room_recognized` + pacing). **The signal-shape decision is RESOLVED** by CD Ruling 2 (provisional). **Remaining external input**: technical-director concurrence on the implementation form (the CD ruled the experience requirements; TD owns the form and must confirm constraints 1–4 and that minimums 1–5 stay assertable).
- Unlocks: milestone criterion #7


---

## Closure Note (2026-07-27)

Delivered after being carried twice. `LoopPayoffAdapter` subscribes to exactly the
two signals the story names and translates each into one payoff type;
`LoopPayoffSignalSurface`'s signal shape is untouched — the new typed
`PayoffDetail` rides as a trailing optional argument, so a new payoff kind stays
a new `payoff_type` VALUE, never a new signal or a reshaped parameter list.

NON-VACUOUS BY CONSTRUCTION: the crown test boots the real `GameWorld` →
`Valley`, forces real chunk residency, writes real cells through the real
`VoxelWorldGrid`, and asserts the real hosted `BuildValidation` →
`LoopPayoffAdapter` → `LoopPayoffSignalSurface` chain fires with real detail
data — then places a real bed through the real `FurnitureRegistry` and proves
`shelter_status` arrives. The file does not even compile against the pre-story
codebase, so it cannot pass vacuously.

FIXTURE TRAP, worth recording because it cost a full cycle: the idempotency test
roofed only the escape cell and then asserted the region read SEALED. It did not
— the analysis pass never reseeded the region containing the interior cell, so
`get_region_status()` returned the stale ROOM verdict. The test would have failed
against a perfectly correct product. `room_recognized_pacing_test.gd` already
documents the remedy at length: bundle a same-content rewrite of a known region
member with the roof write to force the reseed. Applied at both the seal and the
reopen, with the reason recorded inline.

ALSO UNDOCUMENTED UNTIL NOW, surfaced during this work: the world is NOT empty
after boot. Chunks lazily regenerate real deterministic terrain the instant
residency is requested, even though `generate_terrain()` is never called
eagerly. Tests building geometry against a real booted `VoxelWorldGrid` must
build above `base_height + amplitude` (Y >= 8 on the shipped config) or probe for
clear cells first. Two separate agents hit this today.

STILL TRUE, per the story's own text: minimum 5's "flourish-then-room" ordering
half cannot be tested — no Building-System flourish emitter exists on this
surface yet. It ships as a regression grep-guard only.
