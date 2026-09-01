---
name: project-save-persistence-status
description: Status of the Guardado/Persistencia GDD, which downstream systems are still undesigned, and known dependency-reciprocity gaps, as of 2026-08-09
metadata:
  type: project
---

`design/gdd/guardado-persistencia.md` is a Foundation-layer GDD (no upstream deps). Status field: **"In Design"** (not Approved) as of 2026-08-09. Its Acceptance Criteria section is now written to the file (Given-When-Then, AC-01 through at least AC-35, e.g. AC-33 covers same-frame concurrent autosave serialization) — the "pending approval, not yet written" note from 2026-07-29 is stale, superseded.

Downstream systems that hard-depend on it are **all still undesigned as GDDs**, with Datos de Era/Civilización as a partial exception (it has a documented bidirectional relationship with Guardado, but Datos de Era's own Status is also "In Design", not Approved — see [[project-heroes-system-ac-status]] pattern of not over-crediting "In Design" GDDs as stable):
- Permadeath — undesigned
- Forja de Legado — undesigned
- Transición de Era — undesigned
- Salón Conmemorativo/Panteón — undesigned
- UI/HUD — undesigned

**Why**: several acceptance criteria for the save system's Core Rule 1 (mandatory autosave on hero death / relic forge / era complete) and Core Rule 2 (manual save UI gating) can only be unit-tested today via a mocked trigger call into the Save system's own API. The true end-to-end integration test (real hero-death event → real autosave) is blocked until Permadeath/Forja de Legado/Transición de Era/UI-HUD GDDs exist and define their trigger signal contracts.

**Known reciprocity gap (found 2026-08-09, during `temporizador-de-preparacion-ritual.md` review)**: that GDD claims a **bidirectional** hard dependency on Guardado/Persistencia (elapsed_s + current_phase are "part of the saveable state," persisted on autosave, phase recomputed via its own formula F3 on load — its AC-T23 tests this). `guardado-persistencia.md` does **not** mention Temporizador de Preparación/Ritual anywhere (no dependency-table row, no elapsed_s/current_phase field, no interface). This violates the project's own rule (`.claude/rules/design-docs.md`: "Dependencies must be bidirectional — if system A depends on B, B's doc must mention A"). Practical effect: Temporizador's AC-T23 (save/load phase recompute) rests on a one-sided, unconfirmed persistence schema, but — unlike that GDD's AC-T03b/T05b/T07b — it is **not** tagged "(bloqueado)" with a Mock Contract Assumptions note, which is an inconsistent application of the project's own established blocked-AC pattern (compare Guardado's own AC-01b, or Héroes AC-H11/AC-H25).

**How to apply**: when any of the five undesigned GDDs above get authored, flag their save-system integration hooks and circle back to backfill the blocked integration-level acceptance criteria in `guardado-persistencia.md` (marked "-b" variants in the AC draft, e.g. AC-01b/02b/03b, plus AC-07, AC-09, TK4 UI-display verification). Don't let those GDDs ship without confirming they satisfy the Save system's already-drafted contract (autosave must complete before proceeding to next screen/state; manual save UI must not expose the option during Clímax de Combate / DEATH_HOLD). Additionally: when `guardado-persistencia.md` is next revised, check whether it has added a reciprocal Temporizador de Preparación/Ritual row/field — if not, this is still an open reciprocity gap to flag in any review touching either file.
