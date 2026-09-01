# Systems Index: What the Gods Left Behind

> **Status**: Draft
> **Created**: 2026-07-23
> **Last Updated**: 2026-08-18 (Reliquias/Bendiciones #12 → **Needs Revision** tras `/review-all-gdds` Fase 2+4: FAIL cross-GDD — centro de gravedad de ~8 clústeres bloqueantes [effective_attack_damage sin dueño, 5 filas de dep faltan, offering_time_scale sin dueño, mecanismo Regla 10, tope de banda rally, persistencia, muerte durante OFFERING]; approved 7→6. Reporte: design/gdd/gdd-cross-review-2026-08-18.md. Prev: #12 → Approved sin re-review; #11 Forja Approved; base_accidental 0.05→0.10)
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

"What the Gods Left Behind" es un RTS narrativo con elementos roguelite: el jugador comanda una civilización contra un kaiju por era, alternando fases de preparación ritual (posicionamiento, recursos) con clímax de combate explosivo. El núcleo mecánico único del juego es la cadena **Permadeath → Forja de Legado → Reliquias/Bendiciones → Panteón**, que convierte cada muerte permanente de héroe en poder mecánico heredable para eras futuras (Pilares 1 y 2). Los 18 sistemas de este índice cubren desde la infraestructura RTS estándar (control de unidades, combate, datos de era) hasta el motor de legado que le da identidad propia al juego. El MVP se concentra deliberadamente en probar si ese ciclo central — sacrificio con peso, convertido en poder legible — es divertido en una sola civilización antes de expandir a estructura multi-era.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input | Core | MVP | In Review — design-review 2026-08-19: NEEDS REVISION → 7 bloqueantes aplicados misma sesión; pendiente re-review en sesión limpia (log: design/gdd/reviews/input-review-log.md) | design/gdd/input.md | — |
| 2 | Datos de Era/Civilización | Core | MVP | Designed | design/gdd/datos-de-era-civilizacion.md | — |
| 3 | Guardado/Persistencia | Persistence | MVP | Designed | design/gdd/guardado-persistencia.md | — |
| 4 | Control y Selección de Unidades | Core | MVP | Designed | design/gdd/control-y-seleccion-de-unidades.md | Input |
| 5 | Sistema de Tropas | Gameplay | MVP | Designed | design/gdd/sistema-de-tropas.md | Datos de Era/Civilización |
| 6 | Sistema de Héroes | Gameplay | MVP | Approved | design/gdd/sistema-de-heroes.md | Datos de Era/Civilización |
| 7 | Temporizador de Preparación/Ritual | Gameplay | MVP | Approved | design/gdd/temporizador-de-preparacion-ritual.md | Datos de Era/Civilización |
| 8 | Combate/Daño | Gameplay | MVP | Approved | design/gdd/combate-dano.md | Sistema de Tropas, Sistema de Héroes, Control y Selección de Unidades |
| 9 | Encuentro con Kaiju (incl. esbirros) | Gameplay | MVP | Approved | design/gdd/encuentro-con-kaiju.md | Combate/Daño, Datos de Era/Civilización, Temporizador de Preparación/Ritual |
| 10 | Permadeath | Legado | MVP | In Review — pasada de reconciliación cross-GDD (OQ-P6) completa 2026-08-16 (los 6 ítems aplicados a Héroes/Guardado/Kaiju/Datos de Era); pendiente re-review formal en sesión limpia antes de Approved (además: spike de motor 4.6 OQ-P5, OQ-P2, Forja de Legado sin GDD) | design/gdd/permadeath.md | Sistema de Héroes, Combate/Daño, Datos de Era/Civilización |
| 11 | Forja de Legado | Legado | MVP | Approved (design-review 2026-08-17: NEEDS REVISION → 2 bloqueantes + 8 recomendados aplicados y aceptados) | design/gdd/forja-de-legado.md | Permadeath, Guardado/Persistencia, Datos de Era/Civilización |
| 12 | Reliquias/Bendiciones (incl. balance) | Legado | MVP | Needs Revision | design/gdd/reliquias-bendiciones.md | Forja de Legado, Combate/Daño, Temporizador de Preparación/Ritual, Sistema de Tropas, Sistema de Héroes, Guardado/Persistencia, Datos de Era/Civilización, Input |
| 13 | UI/HUD | UI | MVP | Approved (design-review 2026-08-14: NEEDS REVISION → 3 bloqueantes aplicados y aceptados) | design/gdd/ui-hud.md | Combate/Daño, Reliquias/Bendiciones, Sistema de Héroes, Control y Selección de Unidades, Input |
| 14 | Salón Conmemorativo/Panteón | Legado | Vertical Slice | Not Started | — | Forja de Legado, Reliquias/Bendiciones, Guardado/Persistencia |
| 15 | Transición de Era | Legado | Vertical Slice | Not Started | — | Datos de Era/Civilización, Guardado/Persistencia, Forja de Legado |
| 16 | Audio | Audio | Vertical Slice | Not Started | — | Temporizador de Preparación/Ritual, Combate/Daño, Permadeath |
| 17 | Narrativa Ambiental (inferred) | Narrative | Alpha | Not Started | — | Datos de Era/Civilización, Forja de Legado |
| 18 | Accesibilidad (inferred) | Meta | Alpha | Not Started | — | UI/HUD |

---

## Servicios de Soporte de Infraestructura (Core, no numerados)

Introducidos por ADRs de arquitectura, no por `/map-systems`. No son sistemas de
gameplay; son servicios transversales que muchos sistemas consumen. No se numeran
en la enumeración de 18 para no romper referencias existentes.

| Servicio | Categoría | ADR | Provee | Consumido por |
|----------|-----------|-----|--------|---------------|
| TimeControl | Core (soporte) | ADR-0002 (Accepted 2026-08-21) | Régimen de tiempo de juego: `time_scale`, `game_time_paused`, `game_tick`; pila de precedencia `PAUSED>SLOWED>NORMAL` vía `request_regime`/`release_regime` | Permadeath (solicita PAUSED), Reliquias/Bendiciones (solicita SLOWED), Combate/Daño, Encuentro con Kaiju, Input, Temporizador (lectores read-only) |

---

## Categories

| Category | Description | Systems in This Project |
|----------|-------------|--------------------------|
| **Core** | Infraestructura base de la que depende todo | Input, Datos de Era/Civilización, Control y Selección de Unidades; **TimeControl** (servicio de soporte, ADR-0002) |
| **Gameplay** | Los sistemas que hacen divertido el loop RTS | Sistema de Tropas, Sistema de Héroes, Temporizador de Preparación/Ritual, Combate/Daño, Encuentro con Kaiju |
| **Legado** | El motor narrativo-mecánico único del juego (Pilares 1 y 2) | Permadeath, Forja de Legado, Reliquias/Bendiciones, Salón Conmemorativo/Panteón, Transición de Era |
| **Persistence** | Guardado y continuidad de estado | Guardado/Persistencia |
| **UI** | Pantallas de información al jugador | UI/HUD |
| **Audio** | Sonido y música | Audio |
| **Narrative** | Entrega de historia sin texto/cutscenes (Pilar 4) | Narrativa Ambiental |
| **Meta** | Sistemas fuera del loop central | Accesibilidad |

---

## Priority Tiers

| Tier | Definition | Target Milestone |
|------|------------|-------------------|
| **MVP** | Requerido para probar "¿es divertido el ciclo preparación→clímax→legado?" en una sola civilización | Primer prototipo jugable (3-4 meses) |
| **Vertical Slice** | Requerido para conectar 2+ eras y validar la transición de legado | Vertical slice (2-3 meses adicionales) |
| **Alpha** | Todas las civilizaciones/kaijus, sistemas completos en forma rugosa | Alpha (6-8 meses adicionales) |
| **Full Vision** | Pulido, casos borde, contenido completo | Beta/Release (4-6 meses adicionales) |

---

## Dependency Map

### Foundation Layer (sin dependencias)

1. **Input** — recibe la entrada cruda del jugador, nada depende de él para existir
2. **Datos de Era/Civilización** — define datos estáticos (rosters, kaiju, tileset) que todo lo demás consume; cuello de botella
3. **Guardado/Persistencia** — infraestructura de bajo nivel que otros sistemas usan para escribir/leer estado

### Core Layer (depende de Foundation)

1. **Control y Selección de Unidades** — depende de: Input
2. **Sistema de Tropas** — depende de: Datos de Era/Civilización
3. **Sistema de Héroes** — depende de: Datos de Era/Civilización
4. **Temporizador de Preparación/Ritual** — depende de: Datos de Era/Civilización

### Feature Layer (depende de Core)

1. **Combate/Daño** — depende de: Sistema de Tropas, Sistema de Héroes, Control y Selección de Unidades
2. **Encuentro con Kaiju** — depende de: Combate/Daño, Datos de Era/Civilización, Temporizador de Preparación/Ritual
3. **Permadeath** — depende de: Sistema de Héroes, Combate/Daño, **Datos de Era/Civilización** (lee `get_hero_roster_count()` sobre era-`LOADED`); solicita el régimen `PAUSED` a **TimeControl** (servicio de soporte)
4. **Forja de Legado** — depende de: Permadeath
5. **Reliquias/Bendiciones** — depende de: Forja de Legado, Combate/Daño, Temporizador de Preparación/Ritual, Sistema de Tropas, Sistema de Héroes, Guardado/Persistencia, Datos de Era/Civilización, Input (contexto `BLESSING_SELECT`); solicita el régimen `SLOWED` a **TimeControl** *(deps recíprocas reconciliadas 2026-08-21, cierra OQ-RB3 salvo la fila de Guardado que lleva ADR-0003)*
6. **Transición de Era** — depende de: Datos de Era/Civilización, Guardado/Persistencia, Forja de Legado
7. **Salón Conmemorativo/Panteón** — depende de: Forja de Legado, Reliquias/Bendiciones, Guardado/Persistencia
8. **Narrativa Ambiental** — depende de: Datos de Era/Civilización, Forja de Legado

### Presentation Layer (depende de Feature)

1. **UI/HUD** — depende de: Combate/Daño, Reliquias/Bendiciones, Sistema de Héroes, Control y Selección de Unidades, Input (acciones `ui_*`, `active_input_method`, `input_lockout_active`)
2. **Audio** — depende de: Temporizador de Preparación/Ritual, Combate/Daño, Permadeath

### Polish Layer (depende de todo)

1. **Accesibilidad** — depende de: UI/HUD

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Input | MVP | Foundation | game-designer | S |
| 2 | Datos de Era/Civilización | MVP | Foundation | game-designer, world-builder | M |
| 3 | Guardado/Persistencia | MVP | Foundation | game-designer, engine-programmer | S |
| 4 | Control y Selección de Unidades | MVP | Core | game-designer | S |
| 5 | Sistema de Tropas | MVP | Core | game-designer, systems-designer | M |
| 6 | Sistema de Héroes | MVP | Core | game-designer, systems-designer | M |
| 7 | Temporizador de Preparación/Ritual | MVP | Core | game-designer | S |
| 8 | Combate/Daño | MVP | Feature | systems-designer | M |
| 9 | Encuentro con Kaiju | MVP | Feature | systems-designer, game-designer | L |
| 10 | Permadeath | MVP | Feature | game-designer | M |
| 11 | Forja de Legado | MVP | Feature | game-designer, systems-designer | L |
| 12 | Reliquias/Bendiciones | MVP | Feature | systems-designer, economy-designer | L |
| 13 | UI/HUD | MVP | Presentation | ux-designer, game-designer | M |
| 14 | Transición de Era | Vertical Slice | Feature | game-designer, narrative-director | M |
| 15 | Salón Conmemorativo/Panteón | Vertical Slice | Feature | game-designer, ux-designer | M |
| 16 | Audio | Vertical Slice | Presentation | audio-director, sound-designer | M |
| 17 | Narrativa Ambiental | Alpha | Feature | world-builder, level-designer | S |
| 18 | Accesibilidad | Alpha | Polish | accessibility-specialist, ux-designer | S |

*(Effort: S = 1 sesión, M = 2-3 sesiones, L = 4+ sesiones)*

---

## Circular Dependencies

- **Ninguna a nivel de runtime/inicialización.** Aclaración (reconciliación 2026-08-21): varias aristas se etiquetan "Dura (bidireccional)" en los GDDs, pero eso denota **reciprocidad de documentación** (la regla "si A depende de B, la GDD de B debe mencionar a A"), **no** un ciclo de arranque. Los pares que parecen mutuos se resuelven por ownership claro:
  - **Combate ↔ Tropas/Héroes**: Tropas/Héroes poseen `current_health` y el estado de vida; Combate posee el cálculo de daño y solo *notifica* transiciones vía método del dueño. No hay ciclo de init (los datos de unidad existen antes que Combate resuelva un golpe).
  - **Reliquias → Combate**: Reliquias deposita modificadores vía la API de `CombatState` (ADR-0001); Combate no depende de Reliquias para su cálculo base. Unidireccional.
  - **TimeControl** (servicio de soporte) lo *solicitan* Permadeath/Reliquias y lo *leen* Combate/Kaiju/Input/Temporizador; TimeControl no depende de ninguno de ellos — es una hoja del grafo, sin ciclo.
- Ningún par se describe como dependencia dura de arranque en ambos sentidos.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-------------------|------------|
| Forja de Legado | Design | Mapeo muerte→reliquia sin precedente claro en RTS; podría no sentirse balanceado o significativo | Prototipar temprano (`/prototype`) antes de comprometerse a la GDD completa |
| Reliquias/Bendiciones | Design/Scope | El pool de reliquias podría volverse difícil de balancear a medida que crece entre eras | Definir tope de pool y reglas de escalado explícitas en la GDD; revisar en cada era añadida |
| Encuentro con Kaiju | Technical | IA de kaiju + esbirros + contraste de escala brutal (art bible Principio B) en Godot 4.6, versión post-cutoff del modelo | Cruzar referencia con `docs/engine-reference/godot/VERSION.md`; prototipar el encuentro base temprano |
| Guardado/Persistencia | Technical | Persistencia de legado entre eras es una arquitectura de datos nueva sin muchos referentes RTS directos (ya flageado en el concepto) | Diseñar el esquema de datos temprano (orden #3), validar con un ADR antes de construir sobre él |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 18 |
| Design docs started | 13 |
| Design docs reviewed | 9 |
| Design docs approved | 6 |
| MVP systems designed | 13/13 |
| Vertical Slice systems designed | 0/3 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
