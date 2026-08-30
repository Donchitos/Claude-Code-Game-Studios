# Consistency Check Report

**Date**: 2026-08-16
**Registry entries checked**: 4 entities, 1 item, 8 formulas, 7 constants
**GDDs scanned**: 12 (input, datos-de-era-civilizacion, guardado-persistencia, control-y-seleccion-de-unidades, sistema-de-tropas, sistema-de-heroes, temporizador-de-preparacion-ritual, combate-dano, encuentro-con-kaiju, permadeath, ui-hud, forja-de-legado)
**Scope**: full, con foco en los 7 documentos tocados desde el último check (2026-08-14): permadeath.md, sistema-de-heroes.md, guardado-persistencia.md, encuentro-con-kaiju.md, datos-de-era-civilizacion.md (todos editados en la reconciliación cross-GDD OQ-P6), y forja-de-legado.md (nuevo).

---

## Conflicts Found (must resolve before architecture)

Ninguno. 🎉

---

## Stale Registry Entries (registry behind the GDD)

Ninguno. El registro se actualizó en la misma sesión que los GDDs:
- `relic_quality.referenced_by` += forja-de-legado.md (revised 2026-08-16).
- `relic_record` (nuevo item) registrado con source forja-de-legado.md.

---

## Unverifiable References (no conflict, informational)

- `game_time_paused` (flag introducido por Permadeath Regla 4, ahora consumido por Encuentro con Kaiju Regla 11/AC-K89 y Combate/Daño AC-C52) **no está registrado en entities.yaml** — es un flag booleano de runtime, no una constante/fórmula/entidad con valor numérico. Documentado en los GDDs, no en el YAML (coherente con la nota del check 2026-08-14). Sin conflicto; solo se anota.
- `relic_id` / `forge_index` / `forge_counter` (nuevos, de Forja) son campos internos de `relic_record` — registrados como parte de ese item, no como constantes independientes. Sin valor numérico fijo que pueda conflictuar.

---

## Clean Entries (no issues found)

✅ **Cortes de tier de reliquia** — Delgada `[0.10,0.35)` / Sólida `[0.35,0.70)` / Legendaria `[0.70,1.00]`: idénticos en `relic_quality` (registro, source sistema-de-heroes.md), Héroes AC-H19/H20, UI/HUD (U-2), y Forja de Legado FL1/AC-FL03..FL06. La regla explícita de Forja "no duplicar los cortes como knob" (Tuning Knobs) preserva la fuente de verdad única.
✅ **`relic_category`** — {offensive, defensive, rally}: consistente en Héroes (tabla de arquetipos: Vanguardia=offensive, Portaestandarte=rally, Guardián=defensive), Combate/Daño (misma tabla, etiquetas ofensivo/rally/defensivo), y Forja (transporta sin reasignar, AC-FL23 loud-fail ante categoría desconocida).
✅ **`relic_quality`** — output_range [0.10, 1.00], expresión y variables sin cambios; Forja lo consume/transporta sin recalcular (AC-FL07/AC-FL02 de Permadeath). El nuevo consumidor (Forja) no altera la fórmula.
✅ **`relic_record`** (nuevo item) — 9 campos; referencias bidireccionales verificadas: Datos de Era `legacy_props` → `relic_id` (Datos de Era Regla 4), Guardado persiste por referencia (Guardado Regla 4). Fuente de verdad canónica = Forja.
✅ **Constantes** (`world_unit_scale`=48, `camera_pan_speed`=30, `zoom_min`=0.5, `zoom_max`=1.5, `reinforcement_ratio`=0.25, `telegraph_duration_s`=14.0, `guard_radius`=4.0): ningún GDD editado esta sesión restató un valor distinto. Las ediciones de Kaiju (Regla 11 + AC-K89) y Héroes (AC-H12/H26/H27c) fueron aditivas, sin tocar valores.
✅ **Fórmulas cross-system** (`kaiju_timer_remaining_ratio`, `time_to_death`, `incoming_damage_rate_total`, `hero_risk_threshold`, transformadas de cámara): sin cambios; los documentos editados no las redefinen.

---

**Verdict: PASS** — el registro y los 12 GDDs coinciden en todos los valores verificados. Cero conflictos.

Notas de reconciliación pendiente (NO son conflictos de valor — son gaps estructurales de dependencia bidireccional, ya flageados en sus GDDs como Open Questions):
- OQ-FL1: Datos de Era/Civilización aún no lista a Forja en su tabla de Dependientes (a añadir al pasar Forja a Approved).
- `systems-index.md` fila 11 ya actualizada esta sesión con las 3 dependencias de Forja.
