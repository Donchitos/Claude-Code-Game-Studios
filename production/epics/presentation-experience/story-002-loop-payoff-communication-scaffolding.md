# Story 002: Loop-payoff communication scaffolding — event/signal surface

> **Epic**: Presentation Experience
> **Status: Complete (2026-07-24 — 507/507 suite green, parent-verified; CD SIGN-OFF APPROVED — advisory for M02: wire clear_payoff as the moment-resolved return-to-ambient hook)
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~0.5–1 day (scaffolding-only: the surface, not the mechanic)
> **Manifest Version**: 2026-07-23
> **Last Updated**: —
> **M01 tag**: Should-Ship (CD-protected — exit criterion #10)

## Context

**GDD**: N/A — source is `design/art/art-bible.md` §5.3/§5.6/§6.5 (the "alive"/payoff-communication direction) + milestone-01 exit criterion #10 (the scaffolding-vs-mechanic split).
**Requirement**: Art-Bible-traced + milestone-defined (no TR-ID — see epic "Requirements" note).

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern) — primary; the signal/DI contract this surface is built on.
**ADR Decision Summary**: Injected-tier modules communicate via typed signals wired in `setup()`, never `_ready()`; modules are headless-mockable via DI. This story builds a *surface* on that contract — a stable set of signals/events representing loop-payoff moments — so a Feature-layer mechanic can bind to it later without the surface changing shape.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Pure signal/DI wiring — no rendering/physics/nav/input HIGH-risk domain. Use the spine's typed-signal pattern (`CONTRACTS.md`); verify signal-connection APIs against `docs/engine-reference/godot/` only where post-cutoff behavior applies.

**Control Manifest Rules (this layer):**
- Required: injected-tier, headless-mockable, wired in `setup()`; the surface is a level-triggered-safe signal contract that consumers can bind to idempotently.
- Forbidden: implementing the payoff *mechanic* here (needs/mood feedback, reward feedback, UI presentation) — that is the Feature-layer plug-in, out of scope; no new simulation.
- Guardrail: the surface shape is stable — adding the Feature-layer mechanic later must not require reshaping the signals.

---

## Acceptance Criteria

*From milestone-01 exit criterion #10 (scaffolding-only) + ADR-0001, scoped to this story:*

- [ ] A typed event/signal surface exists that represents core-loop payoff moments (e.g. a project completes → a "payoff" signal carrying the subject; a villager's satisfied-state changes) — **the surface only, emitters and consumers are stubs/mocks here**.
- [ ] The surface is injected-tier and headless-mockable (no Autoload, no file I/O in test), wired via `setup()` per ADR-0001.
- [ ] A Feature-layer mechanic (needs/mood or reward feedback) can bind to the surface without the surface changing shape — demonstrated with a mock consumer in the test.
- [ ] Re-emission of the same keyed payoff signal is idempotent for presentation (level-triggered-safe), consistent with the project's existing signal discipline.
- [ ] No payoff *mechanic* and no new simulation is introduced — grep/review-verified; this is scaffolding only.

---

## Implementation Notes

*Derived from ADR-0001 + CONTRACTS.md signal patterns (no dedicated ADR for the payoff mechanic — it does not exist yet):*

- Define the signal surface as a typed, injected-tier contract on the spine pattern. Name and shape the signals for the loop-payoff moments the milestone cares about (project/build completion, villager contentment change) — but emit only from test stubs; the real emitters are the Building/Villager systems and the real consumer is the Feature-layer mechanic, both out of scope.
- Keep signals keyed and idempotent (mirror the toast/anchor "keyed by (signal type, subject), re-emit refreshes in place" discipline already in the codebase) so the later mechanic gets level-triggered-safe re-emits for free.
- This is deliberately the *scaffolding* half of the milestone's own split: M01 proves the surface; the Feature-layer mechanic (needs/mood + reward feedback) plugs into it in a later milestone.

---

## Out of Scope

*Handled elsewhere / later — do not implement here:*

- The payoff *mechanic* itself — needs/mood feedback, reward feedback, UI presentation of payoff (Feature layer, later milestone).
- The real emitters (Building construction-complete, Villager contentment) — those systems emit into this surface later; here they are mocks.
- Any new simulation, needs, or mood logic.

---

## QA Test Cases

- **AC-1 (surface exists, mockable)**: Given: the module wired via `setup()` with mock deps. When: instantiated headless. Then: the payoff signal surface is present and connectable with no Autoload/file I/O.
- **AC-2 (mock consumer binds without reshaping)**: Given: a mock Feature-layer consumer. When: it binds to the surface and a stub emits a payoff signal. Then: the consumer receives it; the surface signature did not have to change to accommodate the consumer. Edge cases: a second consumer binds to the same signal without conflict.
- **AC-3 (idempotent re-emit)**: Given: a payoff signal keyed by (type, subject). When: re-emitted with the same key. Then: presentation-idempotent (refresh-in-place semantics), no duplicate-state error.
- **AC-4 (no mechanic, no sim)**: Given: the story diff. When: grep/review. Then: no payoff mechanic and no new simulation — scaffolding only.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/presentation_experience/loop_payoff_surface_test.gd` (signal-contract + mock-consumer bind) — must exist and pass. CD sign-off on the scaffolding scope (CD-protected item).
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `foundation-spine` (DI + typed-signal contract, `CONTRACTS.md`) — CLOSED (S2). No other hard dependency, because this is the *surface* only.
- Unlocks: the Feature-layer loop-payoff mechanic (needs/mood + reward feedback) that binds to this surface in a later milestone.
- **Schedulable earlier than story-001** — its only hard dep (the spine) is already DONE — but it remains Presentation-pass CD-protected work; sequence it in the Presentation pass (Sprint 5+) alongside story-001 unless pulled forward.
