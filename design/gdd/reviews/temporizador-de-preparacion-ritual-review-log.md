# Review Log — Temporizador de Preparación/Ritual

## Review — 2026-08-09 — Verdict: NEEDS REVISION → fixes aplicados → Approved (sin re-review)
Scope signal: M (single system, 4 formulas, 5 dependencies, no new ADR — pero el fix de dependencias tocó 2 GDDs adicionales)
Specialists: game-designer, systems-designer, qa-lead, ux-designer, audio-director + creative-director (synthesis)
Blocking items: 5 | Recommended: 9 | Nice-to-have: ~12 | Disagreements adjudicated: 2
Prior verdict resolved: First review

### Summary
Arquitectura núcleo sólida (reloj único monotónico con fases como umbrales) — sin defectos estructurales. Los 5 bloqueantes fueron higiene de contrato entre documentos y un requisito de audio no escrito, no un rediseño. Cuatro pares de hallazgos convergieron independientemente entre especialistas de distintas disciplinas (margen de `imminent_window_s`, gap del guideline <20%, gap de schema de `EraDefinition`, contradicción de VA-1) — señal de alta confianza que se usó para priorizar qué era bloqueante.

### BLOCKING (5/5 resueltos en esta sesión)
1. **[systems-designer] Contradicción de save-schema.** Línea 58 decía que se persiste `time_remaining_to_climax_s`; Edge Cases/AC-T23 decían `elapsed_s`. **Fix:** línea 58 corregida a `elapsed_s`, cross-referenciada con `guardado-persistencia.md`.
2. **[systems-designer, qa-lead, creative-director] Contratos de dependencia sobrestimados (3 partes).**
   - (a) `datos-de-era-civilizacion.md` nunca nombraba `approach_duration_s`/`imminent_window_s` en su AC-1 ni en su lista de campos. **Fix:** ambos campos añadidos a Core Rule 1, AC-1, tablas de Interactions/Dependencies y la Open Question relevante de ese GDD.
   - (b) `guardado-persistencia.md` nunca mencionaba este sistema — violaba la regla de bidireccionalidad del proyecto. **Fix:** fila de dependencia añadida en ambas tablas + `elapsed_s`/`current_phase` añadidos al schema de guardado (Rule 4, AC-10).
   - (c) **Conflicto de modelo de inicio del reloj** (hallazgo nuevo de creative-director, no detectado por ningún especialista): `guardado-persistencia.md` asumía una ventana de Preparación previa al inicio del temporizador; este GDD tiene `PREPARATION` como el estado inicial del reloj desde el instante `ACTIVE`. **Decisión del usuario:** no existe ventana previa — el reloj corre desde `ACTIVE`. Rule 2/AC-05 de `guardado-persistencia.md` reescritas en consecuencia.
3. **[audio-director + game-designer, convergencia independiente] VA-1 citaba un driver sin mapeo definido.** El crescendo decía estar dirigido por `kaiju_timer_remaining_ratio` **e** `imminent_local_progress`, pero solo el segundo (7.5% final del runtime) tenía una curva definida — 92.5% de `PREPARATION` sin escalada especificada. **Fix (ruling de creative-director):** VA-1 reescrita — intensificación continua y sutil dirigida por `kaiju_timer_remaining_ratio` durante toda `PREPARATION`, rampa más marcada en `IMMINENT`, beat discreto opcional de mitad de recorrido para Dirección de Música (reutiliza la señal continua existente, sin nueva API).
4. **[qa-lead] ACs de igualdad de punto flotante fallarían tal como estaban escritas.** AC-T11/T11b afirmaban decimales truncados ("exactamente 0.3333") para fracciones periódicas (1/3, 7/9); AC-T03/T09/T12 afirmaban `0.95` exacto (no representable exactamente en binario). **Fix:** convención de tolerancia ±0.0001 añadida a nivel de documento (sección Formulas); las 5 ACs reescritas.
5. **[systems-designer] Referencia cruzada obsoleta.** Dependencies seguía describiendo Héroes OQ-3 como pendiente de actualizar, aunque ya estaba resuelto (mismo 2026-08-07). **Fix:** fila de dependencia y "Nota de consistencia bidireccional" actualizadas a estado resuelto.

### DISAGREEMENTS adjudicados por creative-director
- **Legibilidad vs. "dread"**: game-designer argumentó que Rule 5 (informa, nunca emboscar) está en tensión con el framing de "dread" del Player Fantasy. **Ruling: Rule 5 se mantiene sin cambios** — el dread requiere inevitabilidad conocida + incertidumbre de preparación, no un reloj oculto (precedente: Hitchcock, Darkest Dungeon, FTL). Decisión registrada, no reabrir.
- **Variancia de timing por rejugabilidad**: game-designer recomendó jitter entre partidas para evitar memorización. **Ruling: rechazado** — memorizar el reloj es la maestría prevista (Competence loop), no degradación; la palanca correcta para frescura en rejugabilidad es variar *qué* debe lograrse en la ventana (Encuentro con Kaiju), no *cuándo* termina. Decisión registrada, no reabrir.

### RECOMMENDED y NICE-TO-HAVE (NO aplicados — diferidos, ver revisión completa en el chat de esta sesión)
- Nueva OQ-6 (creative-director): ¿algo amenaza a los héroes antes de `CLIMAX`? Si no, el eje de estaca de H4 casi colapsa (T≈1 siempre). Owner: game-designer, al diseñar Encuentro con Kaiju.
- Elevar el piso seguro de `imminent_window_s` de 30s a 40–45s (margen cero contra la ventana de ~30s de Héroes).
- Advertencia en dev-build para la proporción <20% (hoy silenciosa, AC-T27).
- Conflicto U-1/U-4 (silueta world-space vs. "siempre legible" con cámara RTS pannable) — enrutar a `/ux-design`.
- OQ de arbitraje de audio entre `entered_climax` y los cues A-4/ducking de Héroes — ruling provisional de creative-director: gana el beat de muerte de héroe (Pilar 1 > Pilar 3 en colisión).
- Reinicialización `elapsed_s` entre eras (no bloqueante — multi-era es Vertical Slice, no MVP).
- Diferenciación jugador-perceptible entre la escalada global de IMMINENT y la ventana de ~30s por héroe.
- Techo de frecuencia de flash/strobe para la escalada de IMMINENT (accesibilidad).
- Reescritura conductual de AC-T01 ("verificable por inspección" contradice su tag [Logic/unit]).
- (Nice-to-have adicionales de qa-lead/systems-designer/ux-designer/audio-director — ver transcripción completa de la revisión.)

**Estado:** 5/5 bloqueantes resueltos. Usuario aceptó las revisiones sin re-review (decisión informada — el usuario reconoce que esto omite verificación independiente de los 5 fixes, incluyendo los 2 que tocaron `datos-de-era-civilizacion.md` y `guardado-persistencia.md`). Marcado **Approved** en `systems-index.md`.
