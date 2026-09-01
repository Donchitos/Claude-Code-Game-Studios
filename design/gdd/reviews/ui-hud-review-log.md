# Review Log — UI/HUD

Historial de revisiones de `design/gdd/ui-hud.md`. Cada entrada registra veredicto, alcance y resolución para que futuras re-revisiones puedan rastrear qué cambió.

---

## Review — 2026-08-14 — Verdict: NEEDS REVISION (revisado y aceptado como Approved el mismo día)
Scope signal: L
Specialists: game-designer, systems-designer, ux-designer, ui-programmer, godot-specialist, qa-lead, creative-director (síntesis senior)
Blocking items: 3 | Recommended: 8 | Nice-to-have: 2

**Resumen (síntesis creative-director):** documento estructuralmente sólido (8/8 secciones, bidireccionalidad grep-verificada, contratos bloqueados etiquetados honestamente), pero fallaba en el instante exacto que el sistema existe para servir: la HUD podía quedar en silencio durante la muerte de un héroe. Tres fallos concentrados y arreglables sin rediseño: (1) muerte silenciosa — ráfaga dentro de la ventana de debounce de F1 + muerte fuera de pantalla sin señal (minimapa ausente en MVP, viñeta F3 solo-kaiju); (2) F2 wrong-and-wrong-approach — contradicción de zoom en su propio Edge Case + reimplementación manual de la transformada que derivaría contra `get_screen_center_position()` de Godot 4.6 bajo smoothing de cámara; (3) F3 con ejemplo trabajado ~30% erróneo (0.72, no 0.55) y sin `clamp()` explícito, desbordando 1.10 en el techo del rango seguro de su propio knob `amplitude`. Las tres afirmaciones matemáticas (F3, F2) fueron verificadas independientemente por el revisor principal y por creative-director.

**Blocking items — resolución:**
1. **Muerte silenciosa** → nuevo Core Rule 6b (director de atención multi-canal: marcador de borde + sting audio/háptico + empujón de cámara para AT_RISK/DYING fuera de pantalla) + camino de disparo instantáneo en F1 (`T_instant`=5.0s salta T_show+debounce). ACs nuevas: AC-U12b (ráfaga), AC-U32 (director fuera de pantalla). HU-11, filas de tabla de estados, Edge Cases reescritos. Decisiones de usuario: los 3 canales del director (no solo uno); `T_instant`=5.0s.
2. **F2** → Edge Case de zoom corregido (`zoom_max`=1.5 es el footprint más pequeño, no `zoom_min`); nota de implementación Godot 4.6 obligatoria (deferir a la transformada de canvas nativa / `get_screen_center_position()`; smoothing/stretch/rotación/DPI); Camera2D confirmado.
3. **F3** → `clamp()` explícito añadido a ambos modos; ejemplo trabajado corregido a ≈0.72 con aritmética completa.

**Recommended aplicados:** mouse_filter=MOUSE_FILTER_IGNORE (Core Rule 11); fila HIDDEN→DYING promovida a la tabla de estados; AC-U13 reescrita (multi-muestra temporizada) + AC-U13b (reset); re-tags AC-U27→[Logic/BLOCKING], AC-U02→[Integration], AC-U04→[Logic] con ΔE≤2; AC-U08/U29 con barras de aprobación medibles; AC-U31 enumera las 3 animaciones; AC-U33 (legibilidad N-simultánea); regla de tuning conjunto T_show/T_hide/T_instant; contrato de accesibilidad reforzado + aclaración AccessKit vs flash-rate; flag de playtest para corte de tier; OQ-U7 (tasa de cambio de time_to_death) y OQ-U8 (tope de apilamiento/draw calls).

**Bloqueadas (backfill pendiente upstream):** AC-U17/U18 (verbo de Sacrificio — Combate/Héroes/Control OQ-2; riesgo mayor: la *forma* del mock `order_state` puede resultar incorrecta si upstream aterriza en sacrificio instantáneo), AC-U30 (Reliquias/Bendiciones sin GDD), AC-U31 (Permadeath en In Design, no Approved).

Prior verdict resolved: First review
Resolución: usuario aceptó las revisiones aplicadas → Status Approved (sin re-review en sesión limpia; ítems bloqueantes verificados aritméticamente).
