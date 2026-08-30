# Review Log — Sistema de Héroes

## Confirmación (lean) — 2026-08-07 — Verdict: APPROVED
Scope signal: L
Specialists: ninguno (confirmación single-session tras aplicar los fixes de Review 2)
Blocking items: 0 | Recommended: 0 (los diferidos siguen en backlog de vertical slice)
Summary: Pase de confirmación ligero sobre las secciones tocadas por los 2 bloqueantes de Review 2 (H3, H4, Enforcement, familia AC-H23, nuevas ACs). Verificado: arithmética de AC-H23b (0.70) y AC-H23d (0.35) correcta; floors individuales y piso de suma ahora coinciden en 0.70 (consistente); política loud-fail uniforme reflejada en AC-H23 y Enforcement. El pase detectó y corrigió una contradicción residual (el ejemplo de suma mínima en "Interacción crítica" seguía citando 0.65 con el rango viejo de base_deliberate). Doc internamente consistente.
Prior verdict resolved: Sí — Review 2 (2 bloqueantes) cerrado y confirmado. Marcado Approved en systems-index.md.

---

## Review 2 (re-review) — 2026-08-07 — Verdict: NEEDS REVISION → fixes aplicados
Scope signal: L (por contratos provisionales downstream, no por el tamaño de los fixes)
Specialists: systems-designer, game-designer, qa-lead, ux-designer, audio-director, narrative-director + creative-director (synthesis)
Blocking items: 2 (ambos NUEVOS, surgidos de la revisión previa) | Recommended: ~6 | Nice-to-have: ~6
Prior verdict resolved: Sí — los 4 bloqueantes de Review 1 se confirmaron cerrados; la revisión introdujo 2 defectos nuevos.

### Hallazgos y resolución
**BLOCKING (2/2 resueltos en esta sesión):**
- **B1 [systems-designer] — colisión T=0,P=0 en H4.** El enforcement de suma [0.70,1.00] protegía solo la reachability de Tier 3, no el extremo T=0,P=0 (donde relic_quality = base_deliberate exacto). Config legal (base_deliberate=0.30, sum=0.70) mandaba una muerte DELIBERADA a Tier 1, idéntica a una accidental. **Fix:** floor individual enforced `base_deliberate ≥ 0.35` (rango 0.30→0.35); Enforcement, Interacción crítica, tabla H4 y Tuning Knobs reescritas; AC-H23d añadida; entities.yaml actualizado.
- **B2 [systems-designer] — contradicción interna en H3.** Línea de fórmula decía "restringido a ≥0.5" (clamp) pero la fila de tuning decía "<48 → radio <0.5: pierde el piso". **Fix:** resuelto a validación de entrada (`sprite_diameter_px ≥ 48` loud-fail), no clamp de salida; garantiza ≥0.5 coherente con AC-H05.

**Decisión del usuario (desbloqueó B1):** política de enforcement = **loud-fail uniforme** (todos los knobs fuera de rango fallan ruidosamente; se elimina el clamp individual silencioso de AC-H23, coherente con AC-H02). AC-H23 reescrita clamp→loud-fail; AC-H23b reescrita (los floors individuales ahora suman exactamente 0.70, la suma-check queda como defensa-en-profundidad); AC-H23c limpiada; cláusula de aislamiento de test añadida a Enforcement (qa-lead).

**RECOMMENDED aplicados:**
- A-4 [audio-director]: pin de outcome-blindness (cue idéntico en ambas direcciones + sin sting en el cruce del D-gate, que es casi-determinista); AC-H34 añadida (nueva sección G de audio). A-3: restricción negativa (identity-variation no debe correlacionar magnitud con la distribución de tier del arquetipo).
- (bloqueado)-tags [qa-lead]: AC-H30 y AC-H32b ahora taggeadas + Mock Contract Assumptions.
- AC-H32e [qa-lead/ux-designer]: nueva AC de daltonismo/grayscale (cubre la "regla permanente" de U-1 que AC-H32a no verificaba).
- D-gate [game-designer + narrative-director, convergentes]: OQ-11 registra la alternativa (ampliar D=1 a Hold sostenido contra probabilidad letal) + AC-H31b liga el playtest de vertical slice al estado de falla "culpa pura". NO se rediseña el confirm-step para el MVP (ruling del creative-director: es la solución anti-exploit correcta; el feel se valida con controlador, no con otra ronda en papel).
- A-5 [audio-director]: riesgo de telegrafío tragado documentado + OQ-10.
- Label [game-designer]: Combate/Comando → Combate/Daño en todo el doc + entities.yaml.

**DIFERIDOS (recommended/nice-to-have, no aplicados — a vertical slice):**
- ACs completas para A-1/A-2/A-3/A-5 (solo A-4 tiene trigger discreto testeable hoy).
- AC-H31 rúbrica: tie-break para señales mixtas, unidad de análisis, ejemplos anclados, inter-rater check [qa-lead].
- Retitular "Legendaria" (carga de rareza ARPG) [ux/narrative]; legibilidad del marco graduado de 3 estados a 24-32px LOD [ux]; regla de redondeo de H1 int [systems]; redundancia de esquema AC-H01/H01b [systems].
- Riesgo estructural de loot-priming (la escalera de 3 tiers en sí, no su render) — hipótesis de playtest [narrative/ux].

**Convergencia clave:** game-designer + narrative-director independientemente coincidieron en que el confirm-step del D-gate sobre-corrigió a "ritual-as-checkbox" / mecánicamente idéntico entre héroes. Adjudicado por creative-director como RECOMMENDED (no blocking) para MVP → registrado en OQ-11 + AC-H31b, se valida en playtest.

**Estado:** 2 bloqueantes + recomendados aplicados. Pendiente: confirmación final (idealmente re-review ligero tras /clear). Si confirma → Approved.

---

## Revisión aplicada — 2026-08-07 — todos los bloqueantes + recomendados + housekeeping
Decisiones del usuario/autónomas: D-gate opción (c) combinada (comando Sacrificio con confirm-step + orden-activa + muerte-dentro-de-radio); tuning knobs sacrifice_radius=3.0, guard_radius=4.0; identidad de diseño = fórmula limpia por-héroe (escuela Hades), tragedia del contexto autoral; homogeneización resuelta con vía dual de P (defensiva u ofensiva).

**BLOCKING (4/4 resueltos):**
1. H4 suma conjunta → enforcement loud-fail de base_deliberate+w_stakes+w_purpose ∈ [0.70,1.00] (Tuning Knobs "Enforcement" + "Interacción crítica" reescritas); AC-H23b/AC-H23c añadidas; nota falsa del registro corregida (entities.yaml, revised 2026-08-07).
2. D-gate → definición de D reescrita (3 condiciones) en H4; Regla 5, Edge Cases (5 casos incl. knockback-dentro-de-radio y confirm-step), AC-H21/H21b/H21c reescritas; sacrifice_radius/guard_radius como knobs; OQ-2 actualizada; snapshot de D clarificado.
3. UI daltonismo → U-1/U-2 reescritas a patrón multi-canal (forma/marco + movimiento + color terciario, art bible 7.5), resuelve también loot-priming; A-4 cue de audio/haptic en cruce de tier.
4. AC-H32 → dividida en AC-H32a-d + AC-H33 (marcador de selección U-6).

**RECOMMENDED (aplicados):**
5. U-3 → trigger por time_to_death (contrato conjunto con Encuentro con Kaiju), no HP; OQ-6 actualizada; AC-H29 con Mock Contract Assumptions.
6. Homogeneización → vía dual de P; nota de simetría en H4; OQ-7 (alternativa pesos por arquetipo).
7. QA hardening → AC-H21 taggeada (bloqueado); "Mock Contract Assumptions" en AC-H11/H21/H25/H29; AC-H27b (DEAD inaccionable); AC-H31 con rúbrica de 3 registros + dueño qa-tester.
8. Audio → A-2 (silencio permitido, sin presuponer orquesta), A-3 (outcome-blind pero identity-varied), A-4 (audio de ventana de decisión), A-5 (ducking kaiju).
+ Schema (systems #3): abilities: Array[AbilityDefinition] en Regla 1 + OQ-9; AC-H01b (validación de stats derivados al cargar). Knobs pan_speed_fraction/sprite_diameter_px añadidos a Tuning Knobs.

**HOUSEKEEPING:**
- Header GDD → Status "In Design — revisado post design-review", Last Updated 2026-08-07.
- control-y-seleccion-de-unidades.md → filas de Sistema de Héroes y Tropas actualizadas de "Sin GDD" a "Diseñado"; notas provisionales corregidas.
- entities.yaml → variable P renombrada protected_objective → served_purpose (comentario).

**Estado:** GDD sigue "Designed" (NO Approved) — pendiente RE-CORRER /design-review tras /clear. Si pasa → Approved.
OQ abiertas nuevas: OQ-7 (pesos por arquetipo), OQ-8 (cue intra-banda), OQ-9 (schema de AbilityDefinition).

---


## Review — 2026-08-07 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, ux-designer, audio-director, narrative-director + creative-director (synthesis)
Blocking items: 4 | Recommended: 4 | Nice-to-have: 5 + 1 open design-identity decision
Prior verdict resolved: First review

### Summary
GDD excepcionalmente disciplinado (0 lenguaje no-testeable en las 32 AC), arquitectura sólida, concepto intacto — no requiere rediseño. Pero 4 bloqueantes, dos de ellos en el corazón mecánico: (1) defecto de suma conjunta en Fórmula H4 que hace Tier 3 Legendaria matemáticamente inalcanzable en el mínimo conjunto de los rangos "seguros"; (2) el D-gate ("coincide exactamente") es a la vez inimplementable (knockback/pathfinding) y explotable (Hold reflejo). Un tercero viola la regla permanente de daltonismo del art bible (4.5) en el único elemento de UI que carga todo el payoff en tiempo real. El cuarto (AC-H32) tergiversa la completitud del propio doc. Todos los fixes son quirúrgicos, no estructurales.

### BLOCKING (4)
1. **H4 defecto de suma conjunta** [systems-designer/qa-lead/game-designer]. En D=1, relic_quality = base_deliberate + w_stakes·T + w_purpose·P (base_accidental se cancela). Los 3 knobs se clampan individualmente pero la SUMA nunca se valida. Mínimo conjunto (0.30+0.20+0.15=0.65) → Tier 3 Legendaria INALCANZABLE (rompe AC-H18). Máximo conjunto (1.20) → Legendaria a T=0. Fix: assert de carga rechazando base_deliberate+w_stakes+w_purpose ∉ [0.70, 1.00] (patrón loud-fail de AC-H02) + AC nueva junto a AC-H23. ADEMÁS: corregir la nota falsa en design/registry/entities.yaml (fórmula relic_quality) que dice "sum = 1.00 (techo)" como invariante garantizado — solo es cierto en defaults; propagará el error a GDDs downstream.
2. **D-gate inimplementable + explotable** [game-designer/narrative-director/systems-designer]. "Destino coincide exactamente con el lugar de muerte" (Regla 5 / Edge Case / AC-H21) no funciona en 2D continuo (knockback/pathfinding → sacrificios legítimos marcan D=0 por mala suerte, y el readout puede mentir todo el combate y saltar a Tier 1 en el frame de muerte); pero Hold-default-a-tile-actual permite farmear D=1 con cero intención. NI D ("coincide") NI P ("radio de guardia") tienen tolerancia numérica definida. REQUIERE DECISIÓN DEL USUARIO (ver Disagreement A abajo). Actualizar OQ-2.
3. **U-1..U-4 violan la regla de daltonismo del art bible 4.5** [ux-designer]. Señaliza estado solo por intensidad de dorado; 4.5 exige respaldo de forma/animación/posición y nombra Oro Reliquia vs Hueso/Ocre como el par de mayor riesgo. Fix: heredar el patrón diegético del art bible 7.5 (cambio discreto de forma/marco + cue de audio/haptic en transiciones de tier). BONUS: este mismo cambio arregla el riesgo de "loot-priming" de narrative-director #4 (el glow dorado por tier se lee como rareza de loot ARPG para esta audiencia).
4. **AC-H32 obsoleta** [qa-lead]. Todavía dice que UI Requirements está "[To be designed]" y se declara advisory, aunque U-1..U-7 ya están escritas. Dividir en AC-H32a-d (transición discreta en boundaries de tier / umbral de visibilidad / freeze-on-snapshot / sin texto editorializante) + AC nueva para U-6 (marcador de selección héroe vs tropa, hoy sin cobertura).

### DISAGREEMENTS a adjudicar
- **A (crítico) — cómo arreglar el D-gate**: game-designer dice que es demasiado ESTRICTO → order-intent-persistence + radio generoso de destino. narrative-director dice que es demasiado EXPLOTABLE → un comando Sacrificio distinto con confirm-step/costo, no un booleano reflejo. Recomendación del creative-director: HACER AMBOS (componen) — un verbo Commit/Sacrificio deliberado (peso + anti-exploit) cuyo D=1 resuelve vía orden-activa + muerte-dentro-de-radio (implementable + anti-mala-suerte). Sirve al Pilar 4. El usuario decide la forma exacta (confirm-step / costo de recurso / verbo dedicado).
- **B (menor) — A-3 (sin audio diferenciado por tier)**: audio-director en desacuerdo parcial con el propio GDD: A-3 sobre-corrige (aplana toda muerte en audio idéntico) y confunde "outcome-blind" (mantener) con "identity-blind" (sin resolver). creative-director coincide: apuntar a outcome-blind pero identity-varied.

### RECOMMENDED (4)
5. Ventana de decisión de ~30s (AC-H29) puede ser estructuralmente ilegible: el trigger de visibilidad de U-3 (HP) está desacoplado de time-to-death. Hacerlo contrato conjunto con Encuentro con Kaiju (time-to-death/incoming-damage). Además, la ventana no tiene NINGUNA spec de audio.
6. Homogeneización de arquetipos: con P=0, héroes ofensivos necesitan T≥0.857 para Legendaria vs defensivos que la alcanzan fácil con P=1 → meta de "siempre parkear héroes en objetivos". Considerar pesos relativos al arquetipo o un equivalente ofensivo de P.
7. Endurecimiento QA: taggear AC-H21 (bloqueado) + backfill list; líneas "Mock Contract Assumptions" en las AC bloqueadas como gate de DoD en las stories de Permadeath/Kaiju/Combate; AC-H27b (actuar sobre héroe DEAD se rechaza); nombrar qa-tester como dueño de evidencia de AC-H31.
8. Resolución de feedback intra-banda (U-2/U-3): la mayor parte de la influencia táctica cae DENTRO de una banda de tier → decisiones reales pueden no producir cambio visible.

### NICE-TO-HAVE + housekeeping
Onboarding de la primera exposición al dorado (ux #4); comparación multi-héroe de un vistazo (ux #5); relic_category como decisión de caracterización (narrative #3); runway de apego con 2-3 héroes/era (narrative #5); ducking de vocalización del kaiju (audio #4). Stale: header "Status: In Design / Last Updated 2026-07-23"; control-y-seleccion-de-unidades.md todavía lista este sistema como "Sin GDD (contrato propuesto)".

### DECISIÓN DE IDENTIDAD DE DISEÑO (abierta, no bloqueante)
narrative-director: la fórmula es un scorer genérico idéntico por héroe, justificado citando muertes hand-authored (Arthas/Cristina/Quirón). Posición del creative-director: mantener la fórmula limpia y aprendible para el MVP es legítimo (escuela Hades) — que la tragedia venga del contexto autoral, no de variación de fórmula por héroe — PERO registrar la decisión conscientemente. Decisión del usuario.
