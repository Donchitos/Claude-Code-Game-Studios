# Story 008: Warning/Info tiers, exclusivity & load-pass emissions

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-27 — 1383/1383 suite green 0 orphans, parent-verified; end-to-end bed emission pending RID content)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-033`, `TR-build-validation-navigability-034`, `TR-build-validation-navigability-035`, `TR-build-validation-navigability-041`, `TR-build-validation-navigability-042`, `TR-build-validation-navigability-043`, `TR-build-validation-navigability-046`, `TR-build-validation-navigability-047`, `TR-build-validation-navigability-051`, `TR-build-validation-navigability-055`, `TR-build-validation-navigability-060`, `TR-build-validation-navigability-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (room analysis); ADR-0011 (UI Timer & Expiry Management) as the **downstream** contract — grace/debounce/re-show are UI-owned, not implemented here
**ADR Decision Summary**: Warning and Info are **level-triggered re-emissions**, one per qualifying analysis pass. There is deliberately **no "cleared" signal**: clearing IS the cessation of re-emission plus the queryable current state. The UI reconciles its active toasts against each pass's emissions (Building UI Rules 9–9c implement grace, dismissal debounce, and tier-swap reconciliation; `TR-building-ui-014` requires its grace-expiry callback to **re-query** this system's state, never trust the triggering event).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Warning and Info are **separate typed signals**, not severity payloads of one signal — do not collapse them. Emissions are synchronous within the pass; a tier swap appears as the Warning ceasing and the Info beginning in the same pass.

**Control Manifest Rules (this layer)**:
- Required: level-triggered re-emission per qualifying pass; queryable current state is the clearing mechanism; exactly four signals total from this system, no others.
- Forbidden: a "warning cleared" signal; emitting both tiers for the same item in one pass; implementing dismissal/re-show/grace timing here (UI-owned); warning on a sealed space containing only decorative furniture or only a villager.
- Guardrail: Warning supersedes Info, mutually exclusive **per furniture item**; `shelter_status_changed` (story 006) is independent of both tiers and fires for ALL furniture regardless of type.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] **Warning — sealed space with need-functional furniture**: `sealed_space_warning` carries `(region cells, affected item ids, why-string)` and re-emits every qualifying analysis pass while a sealed space contains **need-functional** furniture (furniture with a need-recovery function — MVP: the bed; decorative/inert furniture never warns). [TR-033] [TR-041]
- [ ] **Info — unsheltered bed**: `unsheltered_furniture_info` carries `(item id, why-string)` and re-emits every qualifying pass while a claimed/placed bed sits outside any valid room AND not inside a sealed space (i.e. in the open). [TR-034] [TR-042]
- [ ] **The tiers are mutually exclusive per furniture item — Warning supersedes Info**: a bed in a sealed space emits the sealed-space Warning only, never additionally the unsheltered Info hint. [TR-035]
- [ ] Warning and Info are **separate typed signals**, not severity payloads of one signal; `shelter_status_changed` is the only signal Needs consumes, the other three are presentational. [TR-043]
- [ ] There is deliberately **NO "cleared" signal** — clearing IS the cessation of re-emission plus the queryable current state; a tier change appears as the Warning ceasing and the Info beginning in the same pass, and the UI retires the stale Warning surface as part of that reconcile. [TR-046] [TR-047]
- [ ] **AC3**: **GIVEN** a sealed region containing a bed, **WHEN** analyzed, **THEN** the sealed-space warning is raised; **GIVEN** the same region empty, **THEN** no warning. [TR-027]
- [ ] **AC17**: **GIVEN** an unsheltered bed in the open vs. a bed in a sealed space, **WHEN** classified, **THEN** the former emits exactly one `unsheltered_furniture_info` and ZERO `sealed_space_warning`, and the latter exactly one `sealed_space_warning` per pass and ZERO `unsheltered_furniture_info` — distinct signal types, mutually exclusive per item. [TR-035]
- [ ] **AC18**: **GIVEN** a region seals with both a villager and a bed inside, **WHEN** analyzed, **THEN** the sealed-space warning fires (and the Info-tier emission count for that bed is 0) and the bed flips to unsheltered, independently of Villager AI's distress signal — no suppression or coupling between the two (AI signal mocked separately). [TR-055]
- [ ] **AC22**: **GIVEN** a warning's cause persists, **WHEN** any later re-analysis runs, **THEN** the warning event re-emits every qualifying pass regardless of prior UI dismissal — dismiss/re-show presentation is the UI's own (advisory-tier) behavior. [TR-041]
- [ ] **AC28**: **GIVEN** a floored, fully roofed structure whose roof sits exactly 2 cells above the floor, **WHEN** analyzed, **THEN** zero candidate interior cells exist, no region forms, and a bed inside is unsheltered with an Info-tier emission and NO sealed-space warning (Edge Case 13). [TR-060]
- [ ] **AC34**: **GIVEN** a region seals with a villager but NO furniture inside, **WHEN** analyzed, **THEN** no sealed-space warning fires from this system — Villager AI's distress is the only cue (mocked separately). [TR-027]
- [ ] **AC35** *[PROVISIONAL — no non-need-functional furniture exists in MVP; mocked definition]*: **GIVEN** a decorative furniture item in a sealed space, **WHEN** analyzed, **THEN** `shelter_status_changed` fires (unsheltered) but Warning and Info emission counts are both 0. [TR-036]
- [ ] **AC31**: **GIVEN** a world load's initial full analysis pass over a world containing valid rooms, a persisting sealed-bed cause, AND an unsheltered-in-the-open bed, **WHEN** the pass completes, **THEN** zero `room_recognized` and zero `shelter_status_changed` emissions occur, all statuses are queryable and equal pre-save statuses, AND both the `sealed_space_warning` and the `unsheltered_furniture_info` re-emissions DO fire on this pass (silent seeding — transitions silent, persisting causes re-warned, both tiers). [TR-051]

---

## Implementation Notes

*Derived from ADR-0007/0011 Implementation Guidelines:*

- Tier selection is a per-item decision made once per pass: `Warning` if the item is need-functional AND its region is Sealed; else `Info` if the item is a bed, unsheltered, and **not** inside a sealed region; else nothing. One item, one tier, per pass.
- "Need-functional" is a property of the furniture definition (MVP: the bed). AC35 mocks a decorative item — the classification must read a definition flag, not a hardcoded bed check.
- AC28's case produces **no region at all** (story 002's standability gate). The Info tier must therefore also handle items whose cell belongs to no region — "unsheltered in the open" is the default, not a region lookup failure.
- The why-strings originate here ("the bed can't be reached — the room has no opening", "a roof would make this a proper home"). The UI presents them; it does not author them.
- The load pass fires Warning/Info but not transitions — the silencing hook is story 005's; this story asserts the split (AC31).
- **Do not implement** first-appearance grace, dismissal debounce, minimum re-show interval, or tier-swap toast retirement. All four are Building UI's (Rules 9–9c). This module stays honest and stateless about a transient seal during a natural build order — that is deliberate.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: `shelter_status_changed` itself.
- Story 007: `room_recognized` and celebration pacing.
- Building UI epic: grace, debounce, re-show, tier-swap reconciliation, the on-demand inspection surface.
- Villager AI: the trapped-villager distress signal (mocked here).

---

## QA Test Cases

- **AC3**: sealed region with a bed → warning; same region empty → none.
- **AC17**: unsheltered-in-the-open bed → 1 Info, 0 Warning; sealed-space bed → 1 Warning per pass, 0 Info.
- **AC18**: region seals with villager + bed → Warning fires, Info count 0, bed unsheltered; mocked AI distress fires independently with no suppression either way.
- **AC22**: cause persists across 3 re-analyses → 3 emissions (dismissal state is irrelevant to this module).
- **AC28**: roof exactly 2 above floor → zero candidate cells, no region, bed unsheltered, 1 Info, 0 Warning.
- **AC34**: sealed region with a villager and no furniture → 0 Warning from this system.
- **AC35**: decorative item in a sealed space → 1 `shelter_status_changed`, 0 Warning, 0 Info.
- **AC31**: load pass over rooms + sealed bed + open bed → 0 `room_recognized`, 0 `shelter_status_changed`, ≥1 Warning, ≥1 Info, all statuses queryable.
- **Tier swap**: seal is opened but the bed remains unsheltered in the open → in that same pass the Warning ceases and the Info begins; no "cleared" signal is emitted.
- Signal-contract guard: across every case above, the total set of emitted signal names is exactly the four contracted ones.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/warning_info_tiers_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 006 (shelter classification), 007 (room_recognized — AC31 asserts both silences), 005 (load pass + silencing hook)
- Unlocks: 009

