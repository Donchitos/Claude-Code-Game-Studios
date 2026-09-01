---
name: project-troop-system-ac-status
description: Status of Sistema de Tropas GDD's Acceptance Criteria and dependency gaps found while drafting them, as of 2026-08-06
metadata:
  type: project
---

`design/gdd/sistema-de-tropas.md` is a Core-layer GDD. As of 2026-08-06 its Acceptance
Criteria section was drafted (~30 Given-When-Then criteria across Core Rules, States,
Formulas, Edge Cases, Tuning Knobs) but not yet written to the file — pending user approval.

Same pattern as [[project-save-persistence-status]]: several ACs are blocked on undesigned
downstream GDDs (Combate/Daño, Encuentro con Kaiju) and can only be verified today via
mocked signals at the Troop system's boundary:
- MOVING/IDLE→ENGAGED and ENGAGED→IDLE transitions — blocked on Combate/Daño's
  contact/resolution event contract (not yet defined).
- Overkill health-clamp-to-0 — blocked on Combate/Daño owning the actual clamp operation
  (Troop system only owns the `is_dead` threshold reaction, which IS testable today).
- "All troops dead, hero alive → era continues" (no total-troop-loss defeat) — blocked, AND
  flagged as a genuine dependency-table gap: no system in `sistema-de-tropas.md`'s
  Dependencies section currently claims ownership of era win/loss evaluation. Likely
  Transición de Era or Encuentro con Kaiju, both undesigned.

Two additional gaps found (not previously tracked anywhere):
1. **Preparación-phase dependency is undocumented.** Core Rule 2 and multiple Edge Cases
   reference a "fase de Preparación" with a timer boundary ("antes de que el temporizador
   del kaiju inicie"), but no system owning that phase/timer state is listed in the
   Dependencies table. The recruit-cap UI-gating AC is therefore only partially testable
   (cap-enforcement logic yes, UI/phase gating no) until this is resolved.
2. **Encuentro con Kaiju's "troops as targets / exposes positions" interface has zero
   corresponding Core Rule or Edge Case** anywhere in the GDD body — it's asserted only in
   the Dependencies/Interactions tables. When Encuentro con Kaiju is designed, expect
   `sistema-de-tropas.md` to need a new Core Rule or Edge Case (not just a downstream
   interface row) specifying what "exposes positions" means mechanically (polling API?
   signal-per-move? radius-limited query?).
3. Also noted: Guardado/Persistencia is fully designed and troop count/state is confirmed
   as save-relevant, but no round-trip save/load AC currently exists for troops. This is
   testable today (both systems designed) — recommend adding it as a coverage gap fix
   rather than a blocked item.

**Why**: `sistema-de-tropas.md` explicitly implements Pilar 1 (Sacrificio con Peso) by
being the mechanical *opposite* of hero permadeath — Core Rule 6 (troop death does NOT
capture circumstance data or trigger legacy) is the load-bearing negative test protecting
that contrast. Treat any future refactor touching both hero-death and troop-death code
paths as high-risk for silently merging the two and breaking the pillar.

**How to apply**: when Combate/Daño or Encuentro con Kaiju GDDs get authored, circle back
to `sistema-de-tropas.md` to backfill the blocked ACs (ENGAGED transitions, overkill clamp,
total-troop-loss non-defeat) and confirm the two documented gaps above got resolved in
those new GDDs' Dependencies sections.
