# Consistency Check Report — 2026-08-14

**Trigger**: tras completar `/design-system UI/HUD` (GDD #13 → Designed).
**Registry checked**: 4 entities, 0 items, 8 formulas, 7 constants
**GDDs scanned (11)**: input, control-y-seleccion-de-unidades, datos-de-era-civilizacion, guardado-persistencia, combate-dano, temporizador-de-preparacion-ritual, sistema-de-tropas, encuentro-con-kaiju, sistema-de-heroes, ui-hud, permadeath

**Método**: grep-first. Superficie de riesgo enfocada en los 2 GDDs nuevos desde el último check (ui-hud.md, permadeath.md) y las 2 fórmulas nuevas (`hero_risk_threshold`, `world_to_screen_transform`). Baseline previo (2026-08-12, 9 GDDs, 0 conflictos) intacto: desde entonces solo se añadieron líneas `referenced_by` y una fila de dependencia en sistema-de-heroes.md — ningún valor registrado cambió.

---

## 🔴 Conflicts Found

Ninguno.

## ⚠️ Stale Registry

Ninguna. Todos los valores registrados coinciden con sus GDDs dueños.

## ℹ️ Informational — contratos cross-GDD (no son conflictos de valor de registro)

Fuera de la definición de conflicto de este skill; ya auto-flageados en las Open Questions de permadeath.md; se resolverán en su propio `/design-review`.

- **`game_time_paused`**: contrato nuevo declarado por permadeath.md, aún no presente en el GDD Approved de Encuentro con Kaiju. UI/HUD (AC-U31 / OQ-U5) y Permadeath (AC-P14) lo tratan consistentemente como contrato provisional — concuerdan, sin contradicción.
- **Héroes AC-H12 payload**: permadeath.md (OQ-P6) requiere que Héroes incluya `relic_quality` en el payload de `DYING`; hoy AC-H12 expone solo `hero_id`/`hero_name`/`relic_category`/D/T/P. Brecha de completitud de interfaz, no contradicción de valor. Requiere editar Héroes (Approved) en una revisión futura.

## ✅ Clean Entries

- **8 fórmulas**: `hero_risk_threshold` y `world_to_screen_transform` (nuevas, auto-contenidas en ui-hud.md); `screen_to_world_transform`, `select_radius`, `relic_quality`, `kaiju_timer_remaining_ratio`, `time_to_death`, `incoming_damage_rate_total` (existentes, consumidas con valores consistentes).
- **7 constantes**: `world_unit_scale`=48, `camera_pan_speed`=30, `zoom_min`=0.5, `zoom_max`=1.5, `reinforcement_ratio`=0.25, `telegraph_duration_s`=14.0, `guard_radius`=4.0 — todas coinciden en cada GDD que las cita. Verificación específica en ui-hud.md: `guard_radius`=4.0 ✅, `telegraph_duration_s`=14.0 ✅, `world_unit_scale`=48 ✅, `camera_pan_speed`=30 ✅, `zoom_min/max`=0.5/1.5 ✅.
- **4 entidades**: `melee_infantry`, `ranged_troop`, `support_troop`, `kaiju` — sin restatement de stats en los GDDs nuevos (ui-hud.md y permadeath.md no reafirman valores de combate).

---

## Verdict: PASS

Registro y GDDs concuerdan en todos los valores. Sin correcciones de registro necesarias. Sin entradas nuevas pendientes (las 2 fórmulas nuevas ya se registraron en la Fase 5 de UI/HUD).

**Recomendado a continuación**: `/design-review design/gdd/ui-hud.md` en sesión limpia. Los 2 ítems informativos (game_time_paused, AC-H12 payload) se atenderán al revisar/aprobar permadeath.md.
