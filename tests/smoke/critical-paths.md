# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. New game / session can be started from the main menu
3. Main menu responds to all inputs without freezing

## Core Mechanic (update per sprint — "What the Gods Left Behind" MVP loop)

<!-- Add the primary mechanic for each sprint as it is implemented. -->
4. [Input/Control] Se puede seleccionar tropas/héroes y darles órdenes de movimiento (clic + box-select; prioridad héroe>tropa)
5. [Temporizador] El reloj de preparación avanza PREPARATION→IMMINENT→CLIMAX y dispara `entered_climax`
6. [Combate] `apply_damage` reduce vida y una tropa/héroe muere en el cruce por 0 sin error
7. [Kaiju] El kaiju aparece en `entered_climax`, telegrafía, y `STRIKING` aplica daño
8. [Permadeath] La muerte de un héroe dispara el beat `DEATH_HOLD` (pausa cooperativa vía TimeControl) y se resuelve
9. [Legado] La muerte forja una `RelicRecord` de extremo a extremo (permadeath → forja)
10. [Reliquias] Con pool pre-sembrado, una invocación en CLIMAX ofrece 3-choose-1 y aplica el efecto elegido

## Data Integrity

11. Guardado completa sin error (autosave en `DYING`; escritura atómica) — una vez implementado ADR-0003
12. Cargar restaura el estado correcto (era_id, reliquias, `elapsed_s`/fase recomputada) — una vez implementado ADR-0003
13. Recuperación por crash: un `DYING` persistido se coacciona a `DEAD` y forja su reliquia al cargar (AC-H27c)

## Performance

14. Sin caídas visibles de framerate en hardware objetivo (target 60fps) con banda + esbirros en CLIMAX
15. Sin crecimiento de memoria sostenido en 5 min de loop central
