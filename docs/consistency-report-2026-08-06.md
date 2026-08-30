# Consistency Check Report
Date: 2026-08-06
Registry entries checked: 3 entities, 0 items, 3 formulas, 5 constants (11 total)
GDDs scanned: 6 (datos-de-era-civilizacion.md, guardado-persistencia.md, input.md, control-y-seleccion-de-unidades.md, sistema-de-tropas.md, sistema-de-heroes.md)

---

### Conflicts Found (must resolve before architecture)

None.

---

### Stale Registry Entries (registry behind the GDD)

None.

---

### Unverifiable References (no conflict, informational)

None — every registered entity/formula/constant referenced across GDDs stated a comparable value, and all values matched the registry.

---

### Clean Entries (no issues found)

✅ **Entities (3/3 clean)**
- `melee_infantry` — max_health=40 confirmed identical in `sistema-de-tropas.md` (source) and referenced correctly as `melee_troop_max_health=40` in `sistema-de-heroes.md` (Formula H1 anchor).
- `ranged_troop`, `support_troop` — only referenced in their source GDD (`sistema-de-tropas.md`); no cross-doc mentions found, consistent with registry's `referenced_by`.

✅ **Formulas (3/3 clean)**
- `screen_to_world_transform` — expression, variables (`screen_pos_px`, `viewport_size_px`, `camera_position_world`, `zoom`, `world_unit_scale`) match `control-y-seleccion-de-unidades.md` Fórmula 2 exactly.
- `select_radius` — expression, variables, and output_range `[0.35, 1.2]` match `control-y-seleccion-de-unidades.md` Fórmula 1 exactly.
- `relic_quality` — expression, variables (D, T, P, base_accidental, base_deliberate, w_stakes, w_purpose), and output_range `[0.10, 1.00]` match `sistema-de-heroes.md` Formula H4 exactly (registered this session).

✅ **Constants (5/5 clean)**
- `world_unit_scale`=48 — consistent across datos-de-era-civilizacion.md, input.md, control-y-seleccion-de-unidades.md, sistema-de-tropas.md, sistema-de-heroes.md.
- `camera_pan_speed`=30 — consistent across the same 5 documents (incl. `effective_pan_speed_world` derivation in control-y-seleccion-de-unidades.md, which correctly treats 30 as the zoom-1.0 reference value, not a redefinition).
- `zoom_min`=0.5, `zoom_max`=1.5 — consistent across datos-de-era-civilizacion.md, input.md, control-y-seleccion-de-unidades.md.
- `reinforcement_ratio`=0.25 (safe range 0.15–0.35) — consistent in sistema-de-tropas.md (source), matches registry's tuning note.

**Cross-check specific to this session's new GDD (Sistema de Héroes):**
- Hero `unit_visual_radius_world` range [0.5, 1.0] stays strictly above the troop ceiling (0.4583 = `melee_infantry`), preserving hero > troop selection priority — confirmed consistent between `sistema-de-tropas.md` AC-12 and `sistema-de-heroes.md` AC-H05.
- Hero `move_speed` range (3.5–4.25 u/s) stays strictly below the fastest troop (`ranged_troop`=5.0 u/s) — confirmed consistent between `sistema-de-tropas.md` AC-13 and `sistema-de-heroes.md` Formula H2 example.
- The 3 hero archetypes (Vanguardia/Portaestandarte/Guardián) were correctly **not** registered as entities — they are illustrative of the 3 `relic_category` values, not a closed MVP roster (per OQ-5 in sistema-de-heroes.md). No conflict; noted as an intentional scope decision.

---

Verdict: **PASS**
