# Story 007: Why-string selection, templates & UI-slot precedence

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — 1345/1345 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent building-011)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-045`, `TR-needs-mood-system-046`, `TR-needs-mood-system-047`, `TR-needs-mood-system-064`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (this module is the single owner of the why-string; the UI is a leaf that consumes it verbatim through the query API) — primary; ADR-0002 (templates are owned data, not scattered literals)
**ADR Decision Summary**: Modules find each other through typed injected references and expose narrow query APIs; a leaf consumer (Villager Info UI) owns only its own selection state and never re-derives another module's data. Consequently the why-string is composed here and read verbatim there — the UI never assembles its own from need values.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript string composition. Strings are player-facing text — keep them in one table so a future localization pass has exactly one place to touch.

**Control Manifest Rules (this layer)**:
- Required (Presentation contract): the Villager Info UI consumes values, band, and why-string **verbatim** from this system's query API.
- Required (Feature): selection is a pure function of current state — no cached "last reason", no sticky string.
- Forbidden: the UI re-deriving a reason from need values; a why-string that names a fix the player cannot take (a trapped villager must never be told "no bed").
- Guardrail: `get_why_string()` is an O(active needs) pure query, safe to call per UI refresh — no allocation-heavy formatting per tick.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] Selection rule: the why-string describes the **strongest current drain** — the active need with the **lowest value**, tie-broken by schema order (`sleep` > `food` > `company`); it is **empty** when no need is urgent and mood is Happy. [TR-needs-mood-system-045]
- [ ] **AC32**: Given each reported source enum with an urgent sleep need, When the why-string is queried, Then it matches the Core Rule 11 template for that enum **exactly**: `ground_no_bed_owned` → "tired — no bed"; `ground_bed_unreachable` → "tired — bed unreachable"; `ground_trapped` → "tired — trapped!"; `bed_unsheltered` → "sleeping rough — no shelter"; `bed_sheltered` / not sleeping → no source suffix. **AND** given no urgent need and Happy mood, Then the why-string is empty. [TR-needs-mood-system-045] [TR-needs-mood-system-046]
- [ ] **UI-slot precedence** is documented and queryable for the single why-slot: Villager AI distress/trapped cue > this system's need-why > Build Validation's structural detail string (which appears only in the building/bed context and never competes in the villager panel). This system publishes its own string plus its precedence rank; it does not arbitrate the other two. [TR-needs-mood-system-047]
- [ ] The Villager Info UI contract surface is complete: per-need values (0–100), mood band (3 states + change events), and the why-string are all reachable through query methods on this module. [TR-needs-mood-system-064]
- [ ] The template table is data, keyed by source enum — adding a source rung adds a row, not a branch.

---

## Implementation Notes

*Derived from ADR-0001/0002 Implementation Guidelines:*

- Two inputs, one output: (1) which need is the strongest drain (lowest active value, schema-order tie-break), (2) the **currently reported source enum** for that need (story 003's stored source). No history, no caching.
- The empty case is precisely "nothing urgent AND mood Happy". A Content-mood villager with nothing urgent still yields a string per the selection rule — do not widen the empty case to "nothing urgent".
- `bed_sheltered` and "not currently sleeping" both produce the base string with **no source suffix**. The suffix is the buildable-fix signal; a properly sheltered sleeper has no fix to offer.
- The three `ground_*` values share one recovery rate but **three different strings** — that split is the entire reason the enum was widened at the 2026-07-10 review. Getting this wrong sends the player to build a second bed for a trapped villager (the Pillar-4 failure the GDD names explicitly).
- `ground_trapped` currently has **no production reporter** — `villager-ai-018`'s ACs name only the other two ground values. Implement and test the template anyway; it is exercised by mock until Villager AI reports it.
- Precedence: expose a rank constant/enum with the string so the UI can compare feeders without hardcoding an ordering. This module never suppresses another module's string itself.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the source enum's rate meaning.
- Story 005: the mood band the empty case depends on.
- Villager Info UI: rendering, slot layout, and the actual arbitration between the three feeders (its own epic).
- Build Validation: its structural detail string.

---

## QA Test Cases

- **AC32 (templates)**: Given an urgent sleep need and each source enum in turn, When `get_why_string(id)` is called, Then the returned string equals the template exactly — one case per enum value, including the no-suffix case for `bed_sheltered`.
- **AC32 (empty)**: Given no urgent need and mood ≥ 70, When queried, Then the string is empty.
- **Selection**: Given `sleep = 30` and a mocked active `food = 20`, When queried, Then the string describes `food` (the lower value); Given both at 30, Then it describes `sleep` (schema-order tie-break).
- **Not-sleeping**: Given an urgent sleep need with no recovery in progress and no reported source, When queried, Then the base string with no source suffix.
- **Wrong-fix guard**: Given `ground_trapped`, When queried, Then the string is "tired — trapped!" and does **not** contain "no bed".
- **Precedence**: Given the module's published rank, When compared against the documented order, Then need-why ranks below the Villager AI distress cue and above Build Validation's structural string.
- Edge cases: a villager with no active needs yields an empty string, not an error; querying an unknown villager id yields an empty string without erroring; the string changes on the same tick the source enum changes (no staleness).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/why_string_templates_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (reported source enum), 005 (mood band for the empty case)
- Unlocks: 010; Villager Info UI epic (consumes this contract verbatim)
