# Story 003: Panel content — name, six-state activity label, need bar, mood band

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (Information Hierarchy, Component Inventory C1–C3/C6, **Committed activity-label set**, Localization Considerations)
**Requirement**: `TR-villager-info-ui-031`, `TR-villager-info-ui-049`, `TR-villager-info-ui-045`, `TR-villager-info-ui-033`, `TR-villager-info-ui-044`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern)
**ADR Decision Summary**: Modules find each other through typed injected references and expose **narrow query APIs**; a leaf consumer owns only its own selection state and **never re-derives another module's data**. Consequently need values, the mood band, and the activity state are all read through query methods and rendered as-is — the UI computes nothing.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The need bar renders the **raw value every frame with NO easing** (motion restraint A5) — this is a re-read, not an animation. Activity labels and band icons **swap instantly** on state/band change. Landed `VillagerAi.State` is exactly the six the GDD contracts: `DECIDING`, `TRAVELING`, `WORKING`, `SLEEPING`, `BREATHER`, `WANDERING` (verified 2026-07-26) — the six-way mapping is satisfiable today.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the six-way activity mapping is **the contract**; exact wording is delegated to the UX spec, which commits it. Need bars show the **raw 0–100** value — no UI-side scaling or smoothing.
- Forbidden: a UI-composed label for an unmapped state; UI-side scaling, smoothing, or easing of a need value; a mood icon distinguished by hue alone; permanent mood icons over villagers' heads (the panel is where mood lives).
- Guardrail: mood-band icons are **3 distinct SHAPES** paired with a label/tooltip — colorblind-safe is the mechanism, not a label (Visual Direction Note §4 day-one pairing rule).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-info-ui.md` Rule 2 and `design/ux/villager-panel.md`, scoped to this story:*

- [ ] Information hierarchy follows the fantasy sentence in order: **C1 Name (header, ≥ 18 px) → C2 Activity row (icon + label) → C3 Mood row (shape icon + band label) → [C4 why-slot, story 004] → C6 Need bar "Sleep" + raw value**.
- [ ] **AC6**: Given each of the **SIX** AI activity states (mocked) in turn — Deciding, Traveling, Working, Sleeping, **Breather**, Wandering — When selected, Then the panel shows the correct **distinct** player-readable label for each; When the state changes while selected, Then the label updates **the same frame** (`TR-villager-info-ui-031`).
- [ ] The committed label set is used verbatim from the UX spec: Deciding → **"Thinking"**, Traveling → **"On the way"**, Working → **"Working"**, Sleeping → **"Sleeping"**, Breather → **"Taking a break"**, Wandering → **"Strolling"**.
- [ ] The mapping is **exhaustive over `VillagerAi.State`** — a compile-or-test-time guarantee that adding a seventh state cannot silently render blank.
- [ ] **AC7**: Given mocked need values, When rendered, Then each active need bar shows the **raw 0–100** value — **no UI-side scaling or smoothing** (`TR-villager-info-ui-049`).
- [ ] **AC-UX2**: The need bar renders correctly at value **0** and value **100** (fill, raw number, no easing).
- [ ] **AC8**: Given a mood **band change** event, When received, Then the band icon updates (band signal only — the event is the refresh trigger; `get_mood()`/the band query is the steady-state source) (`TR-villager-info-ui-031`).
- [ ] Mood-band icons are **3 distinct silhouettes** + band label, never hue alone; grayscale-distinguishable (`TR-villager-info-ui-045`, A1).
- [ ] **C1 Name** renders the villager's name as the attachment anchor. **⚑ Blocked — Known Conflict 2**: `VillagerAi` carries only `villager_id: int` and identity generation is VS-tier. Ship the creative-director's ruling (placeholder scheme vs. a minimal generator pulled forward); do **not** invent one in this story.
- [ ] MVP shows exactly **ONE** need bar (sleep) and the layout reads as **minimal-by-design with reserved growth space** — never as an incomplete stat sheet.
- [ ] **Localization budget (HIGH PRIORITY)**: the activity-label column fits **≥ 20 characters** ("Taking a break" = 14 + 40 % expansion ≈ 20); any translation exceeding 20 characters must be **shortened editorially, never auto-truncated**. Verify against the final font.
- [ ] All panel text **wraps, never truncates**; body ≥ 16 px, name/labels ≥ 18 px at 1080p (`TR-villager-info-ui-044`, A3/A4).
- [ ] Every value is re-read each update frame from upstream — no cached copy survives a frame (`TR-villager-info-ui-033`; this is AC17's mechanism, asserted in story 001).

---

## Implementation Notes

*Derived from `villager-panel.md`'s Component Inventory and the landed `VillagerAi`:*

- **⚑ Known Conflict 4 gates this story.** Need values, the mood band, and `mood_band_changed` are `needs-mood-system` stories 002/005 — `Status: Ready`, **not landed**. Drive the ACs against a mocked needs provider matching that epic's committed query surface (`TR-needs-mood-system-064`: per-need values 0–100, mood band + change events, why-string all reachable through query methods).
- Landed `VillagerAi.get_state() -> State` is the activity source and it already has all six values. Map with an exhaustive `match` over the enum with **no default branch** — that is the "adding a seventh state cannot render blank" guarantee, and it is cheaper than a runtime check.
- **"Thinking" is a mapping-completeness label, not an expected player observation** at MVP: Deciding is near-invisible now and only becomes staggered-visible at scale (Villager AI Rule 10c). Ship it; do not design around its visibility.
- The band event is a **refresh trigger**; the band **query** is the value source. Wiring the icon directly off the event payload is the exact state-over-events violation AC17 exists to catch.
- Reserved growth space is a real layout commitment, not padding: the panel must be able to gain need bars at VS **growing upward** without a redesign (`hud.md` Z4 rule, its OQ5).
- Exact panel dimensions/paddings are deferred to implementation against the final font — the specs fix hierarchy, anchors and growth rules only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the why-slot (C4), its precedence, and the distress flag companion (C5).
- Story 005: overhead distress icons.
- Story 006: hover affordance and selection outline.
- Story 007: the grayscale pass, contrast/text-size measurement, and the localization verification against the final font.
- Any mood **consequence** — Needs & Mood Rule 8 keeps mood display-only in MVP (milestone Out of Scope).

---

## QA Test Cases

- **AC6**: Given each of the six `VillagerAi.State` values in turn, Then the rendered label equals the committed string exactly; change the mock's state mid-frame, Then the label updates within the same frame.
- **Exhaustiveness**: Given the enum's value count, Then the label map's key count equals it — a test that fails when a state is added without a label.
- **AC7 / AC-UX2**: Given need values 0, 37, 100, Then the rendered number equals the raw value and the fill ratio equals value/100 with no interpolation across frames.
- **AC8**: Given a band-change event for Happy → Content, Then the icon id changes to Content's; mutate the band query **without** emitting, Then the next frame's render still reflects the query (state-over-events).
- **Mood shapes**: Given the three band icons, Then their shape ids are pairwise distinct and each has a non-empty label.
- **Localization**: Given a 20-character activity label, Then it renders on one line within the column; given 21, Then the test flags it for editorial shortening (never silently truncates).
- **Wrap**: Given a long name, Then it wraps rather than truncating — assert no ellipsis character.

---

## Test Evidence

**Story Type**: Logic (mapping + raw-value rendering rules) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/villager_panel_content_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002; **Known Conflict 4** — `needs-mood-system` stories 002/005 (need values, mood band) must land, or be mocked to their committed surface; **Known Conflict 2** — the villager-name ruling (creative-director) for C1.
- Unlocks: 004.
