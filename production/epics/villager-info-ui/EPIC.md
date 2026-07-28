# Epic: Villager Info UI

> **Layer**: Presentation
> **GDD**: design/gdd/villager-info-ui.md (368 lines)
> **UX Specs**: design/ux/villager-panel.md (`/ux-review` APPROVED 2026-07-12) · design/ux/hud.md (zone Z4, element E7/E10)
> **Architecture Module**: Villager Info UI (pure mirror — owns exactly one value, the current Selection; reads Villager AI and Needs & Mood every update frame on raw delta)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 7 stories created (see Stories table below)

## Overview

Villager Info UI is how the player reads a villager. Click one while no build
tool is armed and a compact left-edge panel shows their name, what they're doing
(all six AI states), how they feel (mood band), the one MVP need bar (sleep),
and — the panel's actual reason to exist — **the why**, consumed verbatim from
Needs & Mood's template set. Its only always-on element is the overhead distress
icon: a subtle billboarded marker on villagers in genuine trouble (trapped,
ground-sleeping), so problems find the player's eyes without a click.

Like every UI in this project it is a **pure mirror**. It re-reads upstream state
each update frame on raw delta — signals are wake/dirty hints, never value
sources — and it owns exactly one thing: the current Selection, held as a stable
villager handle and never serialized.

This epic is **Milestone 02 Cluster D**, alongside `building-ui`. It is the half
of Cluster D that is **genuinely Cluster-A-gated** (M02 risk R10): it consumes
Needs & Mood's values, mood band and why-string verbatim, and none of that
exists until the needs-mood epic lands. Cut-Lever step 4 reduces this epic to
*"a minimum-viable panel — need bars + mood band + why-string; drop the rest of
the UX spec"* — stories **001–004 are that floor**; stories **005–007** are the
tail the lever drops.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Cross-System UI/World Input Arbitration | **Primary.** This system consumes — never defines — the shared hover-suppression flag (§2) and the Build-Mode/Selection routing (§4). Its villager-hit query is one of the two consumers ADR-0010 names for that one flag; selection routing is Building UI's arbitration, and this system is a leaf on it | HIGH |
| ADR-0004: Physics Backend & Picking Strategy | Villager hit-testing is a **dedicated physics query on a dedicated villager collision layer** (`Area3D`), structurally distinct from Building System's zero-physics DDA block pick — the two hits are merged by comparing world-unit ray distances. **⚑ That layer does not exist in landed code** (Known Conflict 1) | HIGH |
| ADR-0001: Inter-System Reference & DI Pattern | Injected-tier module: typed `@export` refs, all wiring in an explicitly-callable `setup()`, headless-instantiable with mocks. This is what makes all 26 blocking ACs testable against mocked upstreams | MEDIUM |
| ADR-0002: Tuning/Config Data Strategy | The GDD declares **no gameplay-facing tuning knobs**. The one constant, `pick_tie_epsilon`, is a **correctness constant, not a tuning knob** — typed on the config for data-drivenness, documented as non-tunable | LOW |
| ADR-0012: Save/Load Serialization Strategy | Selection is the only owned state and is **never serialized** — save/load never sees this system. Nothing to defer, nothing to re-derive | LOW |

Engine-risk basis (4.7 policy): **HIGH** — UI/Control is a flagged post-cutoff
domain (M02 risk R13), and villager picking sits in the physics-query domain
where 4.6 made Jolt the default. The distress icon's **full billboard** mode
(user decision 2026-07-11 — always camera-facing, readable at every orbit pitch
0.15–1.5 rad) and the selection/hover outline mechanism both need
`godot-shader-specialist` input against the pinned 4.7 docs. Cross-reference
`docs/engine-reference/godot/` before any `Area3D`, billboard, or outline API.

## GDD Requirements

30 TRs registered (`TR-villager-info-ui-*`). ADR-worthy coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-villager-info-ui-002 / -028 / -029 | HUD-hover gate honored; Idle-only selection; Esc routing precedence | ADR-0010 ✅ |
| TR-villager-info-ui-014 / -015 / -016 | Dedicated villager collision layer, separate from block picking; nearest-wins by parametric distance; explicit tie tolerance | ADR-0004 ✅ (mechanism decided; **substrate missing**) |
| TR-villager-info-ui-023 | Headless-mockable via DI — the enabler for the whole blocking AC block | ADR-0001 ✅ |
| TR-villager-info-ui-033 / -010 | State-over-events live mirror; selection handle is the only owned state | ADR-0001 ✅ / ADR-0012 ✅ |
| TR-villager-info-ui-027 | UX spec resolution (billboard mode, hover affordance, panel layout) | RESOLVED by `design/ux/villager-panel.md` ✅ |

**Coverage summary**: Every ADR-worthy TR traces to an Accepted ADR or to the
approved UX spec. The remaining TRs are GDD/UX-specified mirror and presentation
requirements — **except** the six items in **Known Conflicts With Landed Code**,
which are missing upstream surfaces, not undecided architecture.

**At-risk / deferred**:
- **`TR-villager-info-ui-010`** — the selection handle's identity stability across
  Suspended transitions is an `[assumption]` until Villager AI's identity work
  lands (its Open Question 5, **VS-tier**). The UX spec closes this defensively
  with a **stale-handle state**: treated exactly like a despawn — graceful
  deselect, no error surface. Ship that; do not wait for identity.
- **AC24 (multi-need why precedence)** is explicitly **forward-looking** — MVP has
  exactly one need (sleep). Test it against mocks; it validates the precedence
  rule, not a shipped multi-need panel.
- **Keyboard selection is a STATED MVP exemption**, not an oversight
  (`TR-villager-info-ui-030`, user decision 2026-07-11): selecting a villager is
  3D spatial targeting, a different class from HUD chrome. The keyboard path
  (select-cycle / focus-nearest-distressed) is committed to the VS revision
  alongside the roster view.
- **Roster/list view, camera focus on selection, distress-icon clustering,
  portraits/renaming, proactive distress alerting** — all VS+ per the GDD's own
  Open Questions. Do not widen scope toward them.

## Milestone 02 Notes — Cluster D (trimmed SECOND; the A-gated half)

- Delivers the Villager-Info half of criterion **#10** ("…and the villager panel
  showing need values, mood band, and the why-string, consumed verbatim from
  Needs & Mood's Core Rule 11 templates").
- **Cut-Lever Policy, step 4**: *"Cluster D — Villager Info UI reduced to a
  minimum-viable panel (need bars + mood band + why-string; drop the rest of the
  UX spec)."* Stories **001–004 are that minimum**; stories **005–007** (overhead
  distress icons, hover/selection affordances, the advisory evidence pass) are
  what step 4 drops. Note that step 4 fires **before** step 5 — this epic is
  trimmed *ahead of* Building UI.
- **Hard Cluster-A dependency (M02 risk R10).** The panel's three headline values
  — need values, mood band, why-string — are all `needs-mood-system` query APIs
  (its stories 002/005/007), none of which exist yet. A Cluster A slip pushes this
  epic one-for-one. This is a sequencing fact, not a preference.
- **⚑ The distress-icon story additionally depends on Cluster A's furniture chain.**
  Rule 4's two flags are *trapped* **and** *ground-sleeping*; ground-sleeping only
  exists once `villager-ai-018` (sleep & home / bed claim) lands. AC25's negative
  half ("an awake bedless villager shows no icon") is untestable until then.
- No CD-protected item lands here.

## Known Conflicts With Landed Code (report-only — resolve before the affected story)

Recorded here so no story silently invents a resolution. Each names an owner.
Verified against `neues-spiel/src/` on 2026-07-26.

1. **⚑ Villagers have no visual body, no collider, and nothing to click.**
   `VillagerAi extends Node` — **not `Node3D`**. `Valley.tscn` hosts a bare
   `VillagerAi` `Node` with no mesh child. A repo-wide grep for `Area3D` /
   `CollisionShape` under `src/` returns **only doc-comment mentions** (in
   `camera_input.gd`, describing the future villager pick). `_visual_position` is
   a private `var` with **no public getter** — the only public position API is
   `get_current_cell() -> Vector3i` (deliberately the discrete cell, never the
   interpolated value). Consequently there is nothing to hit-test, nothing to
   outline, nothing to hover, and nothing to anchor an overhead icon to.
   `TR-villager-info-ui-014`'s "dedicated villager collision layer" and ADR-0004's
   `Area3D` query have **no substrate**. Owner: technical-director +
   godot-specialist. **Blocks stories 002, 005, 006 entirely** — this is the
   epic's single largest blocker, and it is not a UI story's job to fix.

2. **Villagers have no name.** The panel's C1 header and the fantasy sentence
   ("a name, what they're doing, how they feel") require one. `VillagerAi` carries
   only `villager_id: int`; identity generation is Villager AI **Open Question 5,
   VS-tier**, and the UX spec records portraits/renaming as VS+. MVP must either
   ship id-derived placeholder names or pull a minimal name generator forward —
   a **tone decision**, since "Hilda" and "Villager #3" are different games.
   Owner: creative-director (tone) + game-designer. **Blocks story 003's name AC.**

3. **Distress is ONE boolean, not the two GDD flags.** Rule 4 / AC10 / AC25
   require distinct **trapped** and **ground-sleeping** flags. Landed
   `VillagerAi.is_distressed() -> bool` returns a single `_distressed` set by the
   unstuck-watchdog path (story `villager-ai-015`) — i.e. the *trapped* half only.
   Ground-sleeping depends on `villager-ai-018` (sleep & home / bed claim), which
   is Cluster A and not landed. The panel cannot distinguish the two causes, and
   AC25's no-bed fold cannot be written. Owner: villager-ai + producer
   (sequencing). **Blocks story 005's flag-distinction ACs and part of story 004.**

4. **Needs & Mood's query API does not exist yet.** `get_need_value` (0–100),
   the mood band + `mood_band_changed`, and `get_why_string(id)` are
   `needs-mood-system` stories 002 / 005 / 007 — all `Status: Ready`, none
   landed. The epic's own story 007 confirms the shape ("the Villager Info UI
   contract surface is complete: per-need values, mood band + change events, and
   the why-string are all reachable through query methods on this module",
   `TR-needs-mood-system-064`). Not a defect — a **hard sequencing gate**
   (M02 risk R10). Owner: producer (sequencing). **Blocks stories 003 and 004.**

5. **The GDD says the panel is on the right; the approved UX spec puts it on the
   left.** `villager-info-ui.md` Rule 2 says "(right side, compact)" in passing;
   `hud.md`'s "Quiet left edge" arrangement (user decision 2026-07-11) placed
   inspection **LEFT** so warning toasts (right) never cover the panel of the
   villager they are about, and `villager-panel.md` flags this as a **deliberate
   deviation** with the GDD's parenthetical marked for cleanup at its next
   revision. **Stories cite the UX spec (left, zone Z4).** Owner: game-designer
   (a one-line GDD cleanup). No code impact.

6. **The GDD's Esc routing is stale — it specifies two steps, the owner specifies
   four.** `villager-info-ui.md` Rule 1 describes a **two-step** Esc (release HUD
   focus, then deselect). `building-ui.md` Rule 14 (slice revision 2026-07-23)
   replaced it with a **four-step chain** (HUD focus → armed tool → Selection →
   Build Mode), and building-ui **Open Question 10 explicitly flags the reciprocal
   update to this GDD as pending**. Implement the **four-step** chain — Building UI
   owns it; this system contributes step 3's "is a villager selected" predicate.
   Owner: game-designer (GDD reciprocal update). **Affects stories 001 and 002.**

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Every "Blocking — headless unit tests" AC in `design/gdd/villager-info-ui.md`
  (AC1–17, AC21–26) that is not gated by a Known Conflict above has a passing
  test under `neues-spiel/tests/unit/ui/`
- Every Advisory AC (AC18–20) and every `AC-UX*` in
  `design/ux/villager-panel.md` has an artifact under `production/qa/evidence/`
- Grep proves the module writes nothing: zero setter calls into Villager AI or
  Needs & Mood, zero serialization of the Selection, zero cached copies of an
  upstream value (AC17's "mutate upstream directly, never see a stale panel")
- The six Known Conflicts are each closed by their named owner, or their
  dependent ACs are explicitly deferred with a recorded rationale

## Stories

| # | Story | Type | Tier | Status | ADR |
|---|-------|------|------|--------|-----|
| 001 | Panel scaffold, Z4 host, selection state & the live-mirror loop | Integration | **CORE** | Ready | ADR-0001/0010/0012 |
| 002 | Villager hit query, selection rules & Esc/tool-arm routing | Logic | **CORE** | Ready | ADR-0004/0010 |
| 003 | Panel content — name, six-state activity label, need bar, mood band | Logic | **CORE** | Ready | ADR-0001 |
| 004 | The why-slot — precedence, verbatim pass-through & the distress companion | Logic | **CORE** | Ready | ADR-0001 |
| 005 | Overhead distress icons — one manager, N billboards | Integration | Polish | Ready | ADR-0001 |
| 006 | Hover affordance & selection outline | Integration | Polish | Ready | ADR-0004 |
| 007 | Advisory presentation evidence pass | Integration | Polish | Ready | — |

**Type totals**: 3 Logic, 4 Integration. **Tier totals**: 4 CORE, 3 Polish.

**Dependency order**: 001 → 002 → 003 → 004 → 005 → 006 → 007, with 003 and 004
both gated on the needs-mood epic (Known Conflict 4) and 002/005/006 all gated on
the villager-body/collision-layer decision (Known Conflict 1).

**Needs-decision / flags**:
- **002 / 005 / 006**: blocked on **Known Conflict 1** — villagers have no body,
  no collider, no public world position. **Decide before story 002 starts**;
  it is the epic's critical path.
- **003**: blocked on **Known Conflict 2** (no villager name — a creative-director
  tone call) and **Known Conflict 4** (needs-mood query API).
- **004**: blocked on **Known Conflict 4**; its distress-precedence AC is
  additionally gated on **Known Conflict 3**.
- **005**: blocked on **Known Conflict 3** — the two distress flags do not exist
  as distinct values, and ground-sleeping needs `villager-ai-018` (Cluster A).
- **001 / 002**: implement the **four-step** Esc chain, not the GDD's stale
  two-step (**Known Conflict 6**).
- All stories cite `design/ux/villager-panel.md` for layout — panel on the
  **LEFT** (zone Z4), not the GDD's parenthetical right (**Known Conflict 5**).

## Next Step

Run `/story-readiness production/epics/villager-info-ui/story-001-panel-scaffold-and-selection-state.md`,
then `/dev-story` to begin. Work stories in dependency order — each story's
`Depends on:` field lists what must be DONE first. **Resolve Known Conflict 1
before story 002 is scheduled**; it blocks three of the seven stories and no UI
story can resolve it.
