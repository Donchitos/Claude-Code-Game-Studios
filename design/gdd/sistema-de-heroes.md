# Sistema de Héroes

> **Status**: Approved (2026-08-07) — 2 ciclos de design-review + confirmación lean. Recomendados diferidos a vertical slice (ver review-log). **Parche cross-GDD 2026-08-15**: AC-H12/H26 y OQ-4 actualizados para incluir `relic_quality` en el payload de `DYING`; nuevo AC-H27c (coacción DYING→DEAD al recargar); nota de implementación V-5/V-6 (`PROCESS_MODE_ALWAYS`) — cierra los ítems #1, #2 y #5 de `design/gdd/permadeath.md` OQ-P6. No re-abre el veredicto Approved (aditivo, no contradice ninguna decisión previa).
> **Parche cross-GDD 2026-08-17**: rango seguro de `base_accidental` estrechado `0.05–0.15` → `0.10–0.15` (piso inferior). Reconciliación con Forja de Legado (su design-review 2026-08-17): en `D=0` la salida de H4 es exactamente `base_accidental`, así que <0.10 emitiría `relic_quality` fuera del dominio `[0.10,1.00]` de Forja. Aditivo/correctivo, coherente con el "Rango de salida [0.10,1.00]" que este GDD ya declaraba — no re-abre el veredicto Approved.
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-17
> **Implements Pillar**: Sacrificio con Peso (Pilar 1 — sistema eje); El Pasado es Poder (Pilar 2)

## Overview

El Sistema de Héroes define y gobierna las unidades nombradas del jugador: comandantes únicos, cada uno con silueta propia, stats distintivos, y un arco narrativo que culmina —casi siempre— en una muerte permanente y significativa. A nivel de datos, cada héroe es una definición tipada (`HeroDefinition`) con stats superiores a los de las tropas, habilidades propias, un `unit_visual_radius_world` mayor (48-96px de sprite), y —crucialmente— un descriptor del **tipo de reliquia que su muerte producirá** (el "elemento asimétrico" del art bible Sección 5.1, que ancla el Pilar 2). A nivel de jugador, el héroe es el corazón emocional del juego: es la unidad con la que el jugador se encariña sabiendo que su pérdida es probable y, cuando ocurre, permanente e irreversible. A diferencia de las tropas —masa intercambiable cuya muerte es solo una baja— la muerte de un héroe dispara toda la cadena de legado (Permadeath → Forja de Legado → Reliquias → Panteón). Sin este sistema no existiría el Pilar 1: no habría nada cuya pérdida pesara, ni nada que convertir en el poder heredable que define al juego.

## Player Fantasy

**El jugador es "El Que Decide Cómo Termina".** No puede salvar a sus héroes — puede decidir para qué mueren. Cada héroe llega ya condenado, y la pregunta que el juego le hace no es "¿sobrevive?", sino "¿esta muerte compró algo, o la desperdiciaste?". Es la fantasía del líder que la Historia recuerda porque supo gastar bien las vidas que no pudo conservar (Pilar 1).

Esta fantasía resuelve la paradoja del apego-bajo-condena de forma estructural, no tonal: el contrato trágico. Como el público griego que ya conocía el destino de Edipo, el jugador se involucra no por suspenso sobre el resultado sino por inversión en *cómo se lleva*. Por eso Arthas, Cristina y Quirón funcionan — ninguno sorprende, todos se *ganan*. La foreknowledge no mata el apego; lo convierte de esperanza-de-supervivencia en esperanza-de-un-buen-final.

Dos válvulas mantienen la fantasía honesta:
- **Anti-nihilismo (una muerte se puede desperdiciar)**: si toda muerte produjera una reliquia igual de buena, encariñarse sería irracional. El jugador debe poder malgastar a un héroe —morir en el momento o la posición equivocados, por nada— y obtener una reliquia delgada y triste que lleva su nombre igual. Esto hace que amar bajo condena sea racional, no sentimental.
- **Anti-melodrama (la reliquia siempre es menos)**: un héroe que comandó un ejército se vuelve una espada de tres usos. El juego nunca editorializa que la muerte fue hermosa — sostiene una silueta y te entrega un objeto (Principio C del art bible). El understatement es lo que separa la tragedia de la telenovela.

El pago emocional del Pilar 2 (el pasado es poder) es la reliquia como *veredicto* sobre cómo gastaste al héroe, no como consuelo automático. Una muerte bien gastada produce una reliquia cuyo poder resuena con la manera de morir; una desperdiciada produce un objeto delgado con el mismo nombre. El legado es una calificación, no un regalo.

**Tests de diseño (este sistema y sus consumidores deben hacerlos cumplir):**
1. Si la muerte de un héroe está por ocurrir y el jugador no pudo, ~30 segundos antes, tomar una decisión táctica que cambiara *lo que esa muerte produce*, el encuentro se rediseña. La muerte puede ser inevitable; el rendimiento nunca lo es.
2. Debe existir al menos un estado de juego alcanzable por era en el que un héroe muere y el jugador siente que lo desperdició.

*Criterio de validación (playtest)*: sabremos que el Marco B funcionó si los playtesters, al describir la muerte de un héroe sin que se les pregunte, dicen qué *compró* o *falló en comprar* esa muerte antes de decir cómo los hizo sentir. Si solo reportan tristeza, la fantasía derivó hacia lo melodramático; si reportan frustración/castigo, derivó hacia la culpa pura.

## Detailed Design

### Core Rules

1. **Héroes data-driven con nombre**: cada héroe es una `Resource` tipada (`HeroDefinition`) con: `hero_id`, `hero_name` (nombre propio, no genérico), `max_health` (superior a tropas), `move_speed`, `unit_visual_radius_world` (≥0.5, sprites 48-96px), `abilities` (`Array[AbilityDefinition]`, ≥1 — la estructura interna de `AbilityDefinition` es un contrato del futuro sistema de Habilidades/Combate, sin GDD aún; ver OQ-9), un `asymmetric_element` (descriptor visual, art bible 5.1), y un `relic_category` (`offensive`/`rally`/`defensive`) que la muerte del héroe producirá. Los inputs de fórmula `sprite_diameter_px` y `hero_hp_multiplier`/`pan_speed_fraction` son campos de autoría de los que se derivan `max_health`/`move_speed`/`unit_visual_radius_world` (H1/H2/H3) — ver AC-H01b para su validación al cargar. Leídos del `unit_roster` (porción de héroes) de la era ACTIVE. El MVP maneja **2-3 héroes por era**.
2. **Categoría de reliquia fija, calidad emergente (Pilar 2)**: el `relic_category` de cada héroe es fijo y su `asymmetric_element` lo telegrafía visualmente (un brazo con arma en alto → ofensiva, un estandarte → rally, una reliquia a la espalda → defensiva). Esto le dice al jugador *qué* produciría una muerte bien gastada. La **calidad** de la reliquia resultante NO es fija — depende de las circunstancias de la muerte (ver Interacción con Permadeath). Categoría = telegrafiada; calidad = veredicto.
3. **Prioridad de selección sobre tropas**: los héroes siempre ganan prioridad de selección sobre tropas cercanas (regla ya fijada en Control y Selección). Entre múltiples héroes en el radio, gana el más cercano al clic (desempate ya fijado).
4. **La muerte es permanente e irreversible**: cuando la vida de un héroe llega a 0, transiciona a un estado terminal de muerte que **no puede revertirse** dentro de la partida (sin "cargar antes de la muerte" — Guardado/Persistencia lo hace cumplir con autosave inmediato). La muerte de un héroe **dispara la cadena de legado** vía Permadeath — esta es la distinción mecánica central respecto a las tropas.
5. **Contrato de exposición al morir (para Permadeath)**: al morir, un héroe expone a Permadeath: su `hero_id`, `hero_name`, `relic_category`, y un conjunto de **datos de circunstancia de muerte** — al menos: el tiempo restante en el temporizador del kaiju al morir (`T`), si murió cumpliendo un comando **Sacrificio** deliberado y dentro de `sacrifice_radius` (`D`, ver Fórmula H4 para la definición completa de las tres condiciones), si sirvió un propósito (`P`), y su posición/contexto. Estos datos alimentan el cálculo de *calidad* de la reliquia (válvula anti-nihilismo: una muerte desperdiciada produce baja calidad). *(Contrato provisional — Permadeath, sin GDD aún, debe respetarlo.)*
6. **El jugador siempre pudo cambiar el rendimiento (Test de diseño 1)**: este sistema, junto con Encuentro con Kaiju, debe garantizar que en los ~30s previos a una muerte de héroe inevitable existió una decisión táctica que cambiaba *qué produce* esa muerte. Este sistema aporta la mitad: expone en tiempo real qué circunstancias mejorarían/empeorarían la reliquia, para que la decisión sea legible.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `ALIVE_IDLE` | En el campo, sin orden, vivo | Instanciación, llegada, fin de combate | `ALIVE_MOVING`, `ALIVE_ENGAGED`, `DYING` |
| `ALIVE_MOVING` | Ejecutando pathfinding hacia un destino | Orden de movimiento | `ALIVE_IDLE`, `ALIVE_ENGAGED`, `DYING` |
| `ALIVE_ENGAGED` | En combate (delegado a Combate/Daño) | Contacto/orden de ataque | `ALIVE_IDLE`, `ALIVE_MOVING`, `DYING` |
| `DYING` | Vida llegó a 0 — beat de muerte sostenido en curso (Principio C) | Cualquier estado ALIVE al llegar vida a 0 | `DEAD` (al liberarse el beat) |
| `DEAD` | Muerte confirmada, reliquia forjada, removido del campo | `DYING` | — (terminal, irreversible) |

- **`DYING` es especial**: dispara el contexto `DEATH_HOLD` del Input (que suprime todo input), sostiene el beat visual (art bible 2.3), y solo tras liberarse el beat se confirma `DEAD` y se dispara la Forja de Legado. Este sistema no controla el timing del beat — Permadeath sí (ya fijado en el contrato de Input).
- La transición `DYING → DEAD` es el momento en que se expone el contrato de circunstancia de muerte a Permadeath.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Datos de Era/Civilización | Datos → este sistema | Lee `unit_roster` (porción de héroes) de la era ACTIVE |
| Control y Selección de Unidades | bidireccional | Provee posición/hitbox y `unit_visual_radius_world` (≥0.5, > tropas) para selección con prioridad; recibe órdenes |
| Combate/Daño | bidireccional | Delega cálculo de daño; recibe eventos que reducen vida; notifica `ALIVE_ENGAGED`/`DYING` |
| Permadeath | este sistema → Permadeath | Al entrar a `DYING`, expone `hero_id`, `hero_name`, `relic_category`, `relic_quality` (evaluada vía Fórmula H4 en el frame del snapshot), y D/T/P snapshoteados como evidencia; también notifica el fin de la animación de resolución (V-5→V-6) que alimenta `animation_done` de Permadeath. Permadeath controla el timing del beat y confirma `DEAD` |
| Encuentro con Kaiju | este sistema → Kaiju | Los héroes son objetivos de alto valor para la IA del kaiju; expone posiciones; comparte el garantizar el Test de diseño 1 (ventana de decisión) |
| Guardado/Persistencia | este sistema → Guardado | La muerte de un héroe dispara autosave obligatorio inmediato (hace irreversible la muerte, Pilar 1) |

*(Nota provisional: Combate/Daño, Permadeath y Encuentro con Kaiju aún no tienen GDD — contratos propuestos. El contrato con Permadeath es el más crítico. Datos de Era/Civilización, Control y Selección y Guardado/Persistencia están confirmados.)*

## Formulas

*(Los 3 arquetipos —Vanguardia/Portaestandarte/Guardián— son ilustrativos de las 3 categorías de reliquia, no una lista de héroes cerrada; los rosters reales por era viven en Datos de Era/Civilización.)*

### Formula H1 — `hero_max_health`

`hero_max_health = melee_troop_max_health × hero_hp_multiplier`

Anclado a la tropa más resistente (melee, 40 HP) para que todo héroe supere visiblemente a toda tropa por el multiplicador, sin excepciones.

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida de tropa melee | `melee_troop_max_health` | int (const) | 40 (registrado) | Ancla — la tropa más resistente |
| Multiplicador de vida | `hero_hp_multiplier` | float | 3.0–5.0 | Por arquetipo; bajo para agresivos/frágiles, alto para ancla/defensivos |
| **Vida de héroe** | `hero_max_health` | int | 120–200 | Pool máximo de vida |

| Arquetipo | relic_category | multiplicador | hero_max_health |
|---|---|---|---|
| Vanguardia | offensive | 3.5× | 140 |
| Portaestandarte | rally | 3.75× | 150 |
| Guardián | defensive | 5.0× | 200 |

### Formula H2 — `hero_move_speed`

`hero_move_speed = camera_pan_speed × pan_speed_fraction` (mismo patrón registrado para tropas).

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Velocidad de paneo | `camera_pan_speed` | float (const) | 30 (registrado) | Ancla de velocidad |
| Fracción por arquetipo | `pan_speed_fraction` | float | 0.10–0.15 | Los héroes no deben superar a la tropa más rápida (ranged @ 0.167) |
| **Velocidad de héroe** | `hero_move_speed` | float | 3.0–4.5 u/s | Salida |

Ejemplos: Vanguardia 0.1417→4.25; Portaestandarte 0.1333→4.0; Guardián 0.1167→3.5. Todos por debajo de camera_pan_speed (30) y de la tropa más rápida (5.0).

### Formula H3 — `hero_unit_visual_radius_world`

`unit_visual_radius_world = sprite_diameter_px / world_unit_scale / 2`. El piso `≥ 0.5` **no** se garantiza con un clamp de salida sino con una **validación de entrada**: `sprite_diameter_px` debe ser `≥ 48`, y un valor menor **falla ruidosamente al cargar** (no se clampa silenciosamente — coherente con la política loud-fail de Tuning Knobs y con AC-H02). Con la entrada validada, la salida es siempre `≥ 0.5` sin clamp.

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Diámetro de sprite | `sprite_diameter_px` | int | 48–96 | Sprite de héroe (art bible LOD 2). `< 48` = error de autoría (loud-fail), nunca produce radio < 0.5 |
| Escala de mundo | `world_unit_scale` | int (const) | 48 (registrado) | px por world unit |
| **Radio visual** | `unit_visual_radius_world` | float | 0.5–1.0 | Siempre ≥0.5 (por validación de entrada, no clamp de salida) y >0.4583 (radio de tropa mayor) |

Ejemplos: Vanguardia 64px→0.6667; Portaestandarte 72px→0.7500; Guardián 80px→0.8333. Todos superan el techo de tropa (0.4583), manteniendo la prioridad héroe>tropa.

### Formula H4 (CLAVE) — `relic_quality` (versión gated)

El corazón mecánico del Marco B y de la válvula anti-nihilismo. La **intención** del jugador (`D`) es una compuerta: una muerte accidental queda topada al piso sin importar la escena; solo una muerte deliberada desbloquea los bonos de estaca (`T`) y propósito (`P`).

```
relic_quality = clamp(
    base_accidental + D × (base_deliberate − base_accidental + w_stakes × T + w_purpose × P),
    0.0, 1.0
)
```

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| ¿Deliberada? | `D` (`was_deliberate`) | bool (0/1) | {0,1} | `D=1` sii se cumplen las **tres** condiciones: (1) el jugador emitió un comando **Sacrificio** dedicado (verbo con confirm-step, no un `hold`/`guard` reflejo) sobre este héroe; (2) ese comando seguía **activo/no-cancelado** en el frame de muerte; (3) la muerte ocurrió **dentro de `sacrifice_radius`** del destino ordenado. En cualquier otro caso `D=0`. El radio tolera el desplazamiento por knockback del kaiju (una muerte legítima empujada fuera del punto sigue contando); el confirm-step evita el farmeo reflejo. *Contrato: Combate/Daño provee la clasificación aplicando esta definición.* |
| Estaca del kaiju | `T` (`kaiju_stakes`) | float | [0,1] | `1 − kaiju_timer_remaining_ratio`. 0=murió en una calma, 1=murió en el clímax exacto. *Contrato: `kaiju_timer_remaining_ratio` lo **posee** el Temporizador de Preparación/Ritual (Regla 3 / Fórmula F2 de ese GDD); Encuentro con Kaiju lo consume en paralelo. Resuelto — ver OQ-3.* |
| ¿Propósito? | `P` (`served_purpose`) | bool (0/1) | {0,1} | `P=1` si la muerte sirvió a un propósito táctico marcado, por cualquiera de dos vías (equivalentes, para no privilegiar arquetipos defensivos — ver nota de arquetipos): **(defensiva)** murió dentro de `guard_radius` de un objetivo/aliado crítico marcado, **o (ofensiva)** murió eliminando/neutralizando una amenaza crítica marcada del kaiju (parte/esbirro señalado). *Contrato: Combate/Kaiju provee la clasificación de ambas vías.* |
| Piso accidental | `base_accidental` | float (const) | 0.10–0.15 (MVP: **0.10**) | Piso de una muerte desperdiciada — garantiza que siempre se forja una reliquia (nunca 0), pero delgada. **Rango estrechado 0.05→0.10 en el piso inferior (2026-08-17):** como en `D=0` la salida es exactamente `base_accidental`, un valor <0.10 emitiría `relic_quality` por debajo del dominio `[0.10,1.00]` que Forja de Legado asume, disparando su loud-fail en cada muerte accidental (Forja design-review 2026-08-17). El piso 0.10 es también coherente con el "Rango de salida [0.10,1.00]" ya declarado abajo |
| Piso deliberado | `base_deliberate` | float (const) | 0.35–0.50 (MVP: **0.40**) | Piso una vez establecida la intención. El floor **0.35** (no 0.30) es load-bearing: en `T=0,P=0` la fórmula da exactamente `base_deliberate`, así que un valor <0.35 haría colisionar una muerte deliberada (D=1) con una accidental en Tier 1 — se pierde la compuerta. Ver Enforcement y AC-H23d |
| Peso de estaca | `w_stakes` | float (const) | 0.20–0.40 (MVP: **0.35**) | Bono máximo por morir en el momento climático |
| Peso de propósito | `w_purpose` | float (const) | 0.15–0.30 (MVP: **0.25**) | Bono máximo por morir defendiendo un objetivo |
| **Calidad de reliquia** | `relic_quality` | float | **[0.10, 1.00]** | Consumido por Permadeath → Forja de Legado para fijar tier/fuerza de reliquia |

**Rango de salida**: [0.10, 1.00], nunca 0 — el `base_accidental` es un piso incondicional. Esto hace cumplir la línea de la fantasía: "una reliquia delgada y triste que lleva su nombre igual" — una muerte se puede desperdiciar, pero nunca produce *nada*.

**Mapeo de tiers** (para que Forja de Legado lo consuma):

| Tier | Rango de `relic_quality` | Etiqueta |
|---|---|---|
| 1 — Delgada | [0.10, 0.35) | Reliquia delgada |
| 2 — Sólida | [0.35, 0.70) | Reliquia sólida |
| 3 — Legendaria | [0.70, 1.00] | Reliquia legendaria |

**Ejemplos:**
1. **Desperdiciada** — héroe idle, sin orden, abatido lejos de todo. `D=0` → `relic_quality = 0.10` → **Tier 1 Delgada.**
2. **Deliberada pero temprana** — orden de Hold al inicio (timer recién reseteado), lejos de objetivos. `D=1, T=0.05, P=0` → `0.10 + (0.30 + 0.35×0.05 + 0) = 0.4175` → **Tier 2 Sólida.**
3. **Bien gastada, climática** — el jugador compromete al héroe a sostener un cuello de botella justo cuando el timer del kaiju toca fondo, tanqueando un golpe destinado a un grupo de tropas en retirada. `D=1, T=0.95, P=1` → `0.10 + (0.30 + 0.35×0.95 + 0.25×1) = 0.9825` → **Tier 3 Legendaria.**

Esto hace legible el Test de diseño 1 en tiempo real: al emitir (o no) el comando **Sacrificio** sobre un héroe condenado, y conforme el timer del kaiju baja, el readout de UI de este score puede cambiar de estado visiblemente o quedarse plano — mostrando qué produciría la muerte en ese momento, ~30s antes, sin narrarlo (ver UI Requirements U-1..U-4).

**Nota de simetría entre arquetipos**: `P` tiene dos vías equivalentes (defensiva = morir en `guard_radius` de un objetivo; ofensiva = morir neutralizando una amenaza marcada del kaiju) precisamente para que un héroe ofensivo (Vanguardia) pueda alcanzar Tier 3 sin verse forzado a morir junto a un objetivo defensivo. Sin esa segunda vía, con `P=0` el techo en `D=1` sería `base_deliberate + w_stakes = 0.75`, alcanzando Legendaria solo con `T ≥ 0.857` (los últimos ~14% del timer) — un embudo que empujaría a todos los héroes a la misma estrategia de "parkear junto a un objetivo antes de sacrificar", homogeneizando arquetipos. *(Alternativa registrada para playtest: pesos `w_stakes`/`w_purpose` relativos al arquetipo. Se prefirió la vía dual de `P` por ser más simple y no multiplicar el espacio de tuning — ver OQ-7.)*

**Nota de identidad de diseño (decisión consciente)**: `D`/`T`/`P` son idénticos en tipo y peso para todo héroe — la fórmula NO varía por identidad de héroe. Es una decisión deliberada (escuela Hades: sistemas legibles y aprendibles por sobre casos especiales bespoke). La carga *narrativa/trágica* de cada muerte no proviene de la fórmula sino del **contexto autoral** (quién era el héroe, qué exigía la era, su `asymmetric_element` y `hero_name`) superpuesto a un ritual mecánico limpio. Se descartó para el MVP añadir inputs que varíen por héroe individual, para no convertir la muerte en un puzzle de optimización per-héroe.

### Formula H5 — Umbral de muerte

`health_current ≤ 0 → transition(ALIVE_*, DYING)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida actual | `health_current` | int | 0–hero_max_health | HP vivo del héroe |

**Distinción de las tropas**: el umbral es mecánicamente idéntico, pero al cruzarlo un héroe **snapshotea** los inputs D/T/P (no los lee tarde, ya que T y P varían en el tiempo) y los congela en el payload de circunstancia de muerte expuesto a Permadeath en la transición `DYING → DEAD` — este sistema evalúa la Fórmula H4 en ese mismo frame y agrega `relic_quality` ya computada al payload (Permadeath no la recalcula, solo la transporta). (Ver Edge Cases — el timing del snapshot es una fuente común de bugs de race-condition.)

## Edge Cases

- **Si un héroe entra a `DYING` (vida cruza 0)**: los inputs `D`/`T`/`P` de `relic_quality` se **snapshotean y congelan en ese frame exacto**, no se leen tarde. `T` (estaca del kaiju) y `P` (propósito/proximidad) varían en el tiempo — leerlos después del frame de muerte produciría una calidad de reliquia incorrecta. `D` también se captura en ese frame desde el estado de comando almacenado (¿comando Sacrificio activo y dentro de `sacrifice_radius`?), no muestreado continuamente — un comando cancelado el instante anterior/posterior al golpe letal se resuelve por el estado en el frame de cruce, coherente con AC-H21c. La captura ocurre en el cruce por 0, antes de que el beat sostenido inicie.
- **Si dos héroes entran a `DYING` en el mismo frame**: cada uno snapshotea sus propios `D`/`T`/`P` independientemente y expone su propio contrato a Permadeath. Permadeath serializa los beats de muerte (no dos beats sostenidos simultáneos) — el orden de resolución lo define Permadeath, no este sistema.
- **Si un héroe muere por overkill** (golpe que lo lleva muy por debajo de 0): Combate/Daño hace clamp de la vida a 0; la transición a `DYING` dispara igual en el cruce por 0. El monto de overkill no afecta `relic_quality` (no es un input de la fórmula).
- **Si un héroe muere sin ningún comando Sacrificio activo** (`D=0`): produce `relic_quality`=0.10 (Tier 1 Delgada) — la muerte no se desperdicia en el sentido de "no producir nada", pero sí es la reliquia más pobre. Es la válvula anti-nihilismo funcionando, no un bug. (Un `hold`/`guard` ordinario **no** cuenta como Sacrificio — solo el comando dedicado con confirm-step, ver Fórmula H4.)
- **Si el jugador emite un comando Sacrificio pero el héroe muere fuera de `sacrifice_radius` del destino**: `D=0` — la muerte no ocurrió donde se comprometió al héroe. Esto evita "gamear" el sistema comprometiendo héroes lejos del combate real.
- **Si un héroe con comando Sacrificio activo es empujado por knockback del kaiju y muere DENTRO de `sacrifice_radius` del destino**: `D=1` — el radio tolera el desplazamiento por knockback/pathfinding, de modo que un sacrificio genuino no se penaliza por mala suerte física. Este es el caso que la definición de exact-match anterior rompía. (Fuera del radio → `D=0`, caso anterior.)
- **Si el comando Sacrificio se canceló/reemplazó antes del frame de muerte**: `D=0` — la condición (2) exige que el comando siga activo al morir. El jugador cambió de intención antes de que la muerte ocurriera.
- **Si el jugador toca Sacrificio reflejamente sobre un héroe condenado sin confirmar**: el comando no se emite — el confirm-step es parte del comando (ver Fórmula H4 y contrato con Combate/Daño). Un tap sin confirmación no produce `D=1`. Esto cierra el farmeo por reflejo.
- **Si un héroe seleccionado entra a `DYING`**: se remueve del conjunto de selección de Control y Selección (su AC-18/19 lo cubre). Durante `DYING`, el Input está en `DEATH_HOLD` y suprime todo input, así que el jugador no puede seleccionar/comandar nada hasta que el beat se libere.
- **Si todos los héroes de la era mueren**: es (casi con certeza) la condición de derrota de la era — pero la evaluación de victoria/derrota **no la posee este sistema** (mismo hueco abierto que en Tropas). Este sistema solo notifica cada muerte; quién declara la derrota es Encuentro con Kaiju o Transición de Era.
- **Si un `HeroDefinition` no declara `relic_category`** (error de datos): falla ruidosamente al cargar en builds de desarrollo — un héroe sin categoría de reliquia rompe el Pilar 2. Nunca se asigna una categoría por defecto silenciosamente.
- **Si el beat de muerte sostenido (`DYING`) es interrumpido por un crash/cierre**: al reiniciar, el autosave obligatorio ya disparado por Guardado/Persistencia (Regla 4) garantiza que el héroe está muerto y la reliquia forjada — el jugador no puede reaparecer con el héroe vivo recargando. La muerte es irreversible incluso a través de un crash.

## Dependencies

**Dependencias hacia arriba (upstream):**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Datos de Era/Civilización | Dura | Lee `unit_roster` (porción de héroes) de la era ACTIVE | ✅ Diseñado |
| Control y Selección de Unidades | Dura (bidireccional) | Provee posición/hitbox y `unit_visual_radius_world` (≥0.5, > tropas); recibe órdenes con prioridad héroe>tropa | ✅ Diseñado — contrato confirmado |

**Dependientes hacia abajo (downstream):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Permadeath | Dura (**consumidor crítico**) | Recibe el contrato de circunstancia de muerte (`hero_id`, `hero_name`, `relic_category`, `relic_quality` ya computada, D/T/P snapshoteados); controla el timing del beat `DEATH_HOLD` y confirma `DEAD` |
| Combate/Daño | Dura (bidireccional) | Delega cálculo de daño; recibe eventos que reducen vida; notifica `ALIVE_ENGAGED`/`DYING`. Provee la clasificación `D` (deliberada) y `P` (protegió objetivo) |
| Temporizador de Preparación/Ritual | Dura | **Dueño** de `kaiju_timer_remaining_ratio` (input `T`); este sistema lo lee en el frame de muerte. ✅ Diseñado — resuelve OQ-3 |
| Encuentro con Kaiju | Dura | ✅ **Approved** (`encuentro-con-kaiju.md`). Los héroes son objetivos de alto valor de la IA del kaiju (Regla 3); Encuentro provee `time_to_death` (F2) **e** `incoming_damage_rate_total` (F6, kaiju+esbirros) por héroe para el trigger del readout (U-3/AC-H29/AC-H32b) — el readout refleja la fuente más peligrosa (Encuentro Regla 6b/AC-K68); el marcado `P` (defensiva/ofensiva) lo produce Encuentro Regla 5. **Consume** (no posee) `kaiju_timer_remaining_ratio` |
| Guardado/Persistencia | Dura | La muerte de un héroe dispara autosave obligatorio inmediato (hace irreversible la muerte, Pilar 1) |
| UI/HUD | Dura | Consume el tier proyectado de `relic_quality` (U-1/U-2), el snapshot D/T/P congelado en `DYING` (U-4), la prioridad de selección héroe>tropa (U-6/AC-H33) y `asymmetric_element`/`relic_category` como ancla visual del readout de veredicto (U-1..U-7). *En diseño (`design/gdd/ui-hud.md`)* |
| Reliquias/Bendiciones | Dura (modificadores de instancia) | Las bendiciones aplican modificadores planos a instancias de héroe vía la capa `CombatState` de Combate (ADR-0001); un modificador activo se descarta con la instancia al entrar el héroe a `DYING` (Reliquias AC-RB41) y **no** altera la clasificación D/T/P de la muerte. El targeting single-hero de la bendición sigue pendiente (Reliquias OQ-RB7) |

**Nota bidireccional (actualizada 2026-08-21)**: Permadeath, Combate/Daño, Encuentro con Kaiju y Reliquias/Bendiciones **ya tienen GDD** — sus contratos están confirmados (la fila recíproca de Reliquias se añadió en la reconciliación cross-GDD, cierra parte de Reliquias OQ-RB3). El contrato con Permadeath sigue siendo el más crítico del proyecto (define cómo la muerte se convierte en legado). Datos de Era/Civilización, Control y Selección y Guardado/Persistencia están confirmados.

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Piso de calidad accidental | `base_accidental` | float | 0.10 | 0.10–0.15 | <0.10: **loud-fail de contrato** — emitiría `relic_quality` bajo el dominio `[0.10,1.00]` de Forja de Legado (en `D=0` la salida ES `base_accidental`), rompiendo el piso anti-nihilismo compartido; >0.15: desperdiciar deja de castigar, se diluye la válvula anti-nihilismo. *(Piso inferior estrechado 0.05→0.10 en reconciliación con Forja, 2026-08-17)* |
| Piso de calidad deliberada | `base_deliberate` | float | 0.40 | 0.35–0.50 | <0.35: una muerte deliberada sin estaca ni propósito (T=0,P=0) colisiona en Tier 1 con una accidental — se pierde la garantía de la compuerta (loud-fail al cargar); >0.50: la intención sola casi alcanza Legendaria, los bonos de clímax/objetivo pierden peso |
| Peso de estaca (timer kaiju) | `w_stakes` | float | 0.35 | 0.20–0.40 | <0.20: morir en el clímax no importa; >0.40: solo el timing determina todo, el propósito se vuelve irrelevante |
| Peso de propósito (objetivo) | `w_purpose` | float | 0.25 | 0.15–0.30 | <0.15: proteger un objetivo no importa; >0.30: eclipsa la estaca del timer |
| Multiplicador de vida de héroe | `hero_hp_multiplier` | float | 3.0–5.0 (por arquetipo) | 3.0–5.0 | <3.0: los héroes no se sienten más resistentes que las tropas; >5.0: se vuelven casi inmortales, se pierde el peso de la muerte |
| Fracción de velocidad de héroe | `pan_speed_fraction` | float | por arquetipo | 0.10–0.15 | <0.10: héroes se arrastran; >0.15: alcanzan/superan a la tropa más rápida (ranged 5.0 u/s), rompiendo el techo de velocidad |
| Diámetro de sprite de héroe | `sprite_diameter_px` | int | por arquetipo | 48–96 | <48 (→radio <0.5): **loud-fail al cargar** (no se clampa) — perdería el piso de radio y la separación héroe>tropa; >96: **loud-fail** — sprite desproporcionado a escala RTS |
| Radio de cumplimiento del Sacrificio | `sacrifice_radius` | float | 3.0 | 2.0–5.0 | Radio alrededor del destino ordenado dentro del cual una muerte cumple el comando Sacrificio (input de `D`). <2.0: el knockback del kaiju hace fallar sacrificios legítimos (D=0 por mala suerte); >5.0: casi cualquier muerte cerca cuenta, se diluye la deliberación |
| Radio de guardia del propósito | `guard_radius` | float | 4.0 | 2.5–6.0 | Radio alrededor de un objetivo/aliado marcado dentro del cual una muerte lo protege (vía defensiva de `P`). <2.5: proteger es casi imposible; >6.0: estar vagamente cerca ya cuenta. *Valor final confirmado con Combate/Kaiju (OQ-2).* |

**Interacción crítica (ENFORZADA, no solo recomendada)**: en `D=1` la fórmula se reduce a `relic_quality = base_deliberate + w_stakes×T + w_purpose×P` (el término `base_accidental` se cancela). Por eso la **suma** `base_deliberate + w_stakes + w_purpose` es load-bearing para la reachability de Tier 3. Con los floors individuales actuales (base_deliberate≥0.35, w_stakes≥0.20, w_purpose≥0.15) el mínimo conjunto es **exactamente 0.70**, así que la mejor muerte posible (D=1,T=1,P=1) llega justo al umbral de Tier 3 Legendaria (≥0.70) — apenas alcanzable, que es la intención. (Nota histórica: sin el floor de base_deliberate=0.35 introducido en re-review, el mínimo conjunto habría sido 0.30+0.20+0.15 = 0.65 y Tier 3 habría sido **inalcanzable** — por eso el floor individual y el piso de suma trabajan juntos, ver "Segundo constraint" abajo.) En el otro extremo, el máximo individual (0.50+0.40+0.30 = 1.20) alcanzaría Legendaria con T=0 (muerte en calma), contradiciendo la fantasía. Por eso la suma se **valida y restringe a `[0.70, 1.00]`**: el piso garantiza que Legendaria sea alcanzable, el techo que siga exigiendo una muerte bien gastada. Los defaults (0.40+0.35+0.25 = 1.00) cumplen.

**Segundo constraint, independiente del anterior**: en el extremo `T=0,P=0` los términos de peso se anulan y `relic_quality = base_deliberate` exactamente. Si `base_deliberate` cayera por debajo de 0.35, una muerte **deliberada** (D=1) pero sin estaca ni propósito produciría <0.35 → **Tier 1 Delgada**, idéntica en tier a una muerte accidental (D=0 → `base_accidental`). Eso colapsaría la compuerta que la fórmula existe para sostener. La restricción de la suma `[0.70,1.00]` **no** atrapa este caso (solo inspecciona la suma, no el término individual), por lo que `base_deliberate ≥ 0.35` es un enforcement individual separado (ver Enforcement punto 3 y AC-H23d).

**Enforcement** (política loud-fail uniforme — nunca se sustituye silenciosamente un valor de config, coherente con AC-H02):
1. **Cada knob fuera de su rango seguro individual falla ruidosamente al cargar** (error/assert en builds de desarrollo) — **no** se clampa al límite más cercano. Clampar en silencio un constante load-bearing (p. ej. `base_deliberate` 0.60→0.50, un swing de 0.10 que mueve los boundaries de tier) ocultaría exactamente el tipo de error que este enforcement existe para atrapar. Ver AC-H23.
2. **Adicionalmente**, si `base_deliberate + w_stakes + w_purpose ∉ [0.70, 1.00]`, la carga también falla ruidosamente — la suma es load-bearing para la reachability de tiers aunque cada término esté en rango. Ver AC-H23b/AC-H23c.
3. El floor individual `base_deliberate ≥ 0.35` (punto 1) es doblemente load-bearing: garantiza que una muerte deliberada (D=1) con `T=0,P=0` produzca ≥0.35 (Tier 2 Sólida), nunca colisionando en Tier 1 con una muerte accidental (que da exactamente `base_accidental`). Ver AC-H23d.
4. **Aislamiento de test**: la configuración se carga en una instancia inyectable/aislada por test, no en un singleton global mutable — un test de config corrupta (AC-H23/b/c/d) no debe contaminar el estado de los tests de fórmula canónica (AC-H13–H20). Coherente con el estándar de Isolation del proyecto.

**Constantes consumidas** (no se duplican): `camera_pan_speed`=30, `world_unit_scale`=48, `melee_troop_max_health`=40 (de `melee_infantry`) → propiedad de otros sistemas (registradas).

## Visual/Audio Requirements

*Referencia rectora: Art Bible "What the Gods Left Behind" — Secciones 2.3 (Muerte/Sacrificio), 5.1 (arquetipo de héroe), 5.2 (rasgo distintivo), 5.3 (pose), 5.4 (LOD). Los requisitos de audio son un **contrato provisional** (sin dirección de audio ni audio bible aún) — deben re-verificarse cuando exista.*

### Visual

**V-1 — Silueta de héroe con elemento asimétrico único (art bible 5.1)**
Cada héroe se construye alrededor de **un solo elemento asimétrico ornamentado** (brazo-arma-en-alto, capa que arrastra, estandarte fuera de eje, reliquia a la espalda); el resto de la silueta se mantiene plano/funcional. Ese elemento es el ancla visual de la futura reliquia y el único punto donde se concentra detalle. **No usa Oro Reliquia en vida** — solo acentos Hueso/Piedra Fría/Ocre (el dorado se reserva para el prop de reliquia post-muerte).

**V-2 — El elemento asimétrico telegrafía la `relic_category` (art bible 5.2, Regla Core 2)**
El *tipo* de elemento asimétrico debe corresponder a la `relic_category` del `HeroDefinition`: brazo-arma-en-alto → `offensive`; estandarte → `rally`; reliquia heredada a la espalda → `defensive`. Es la lectura visual de "qué produciría una muerte bien gastada", legible desde el reclutamiento.

**V-3 — Legibilidad a escala RTS y separación héroe > tropa (art bible 3, 5.2)**
La silueta del héroe debe leerse como "un héroe" a 24-32px por la *presencia* del elemento asimétrico (las tropas carecen de él — regla dura, sin excepciones). Diferenciación héroe-vs-héroe **solo** por cuál es el elemento asimétrico y dónde se ubica, nunca alterando la gramática vertical base.

**V-4 — Dos niveles de LOD, Nivel 2 exclusivo de permadeath (art bible 5.4)**
Dos LOD fijos, no continuos:
- **Nivel 1 (juego)**: silueta + bloque de color; sin detalle facial/ornamento fino.
- **Nivel 2 (detalle pleno pictórico)**: activado **solo** por (a) el beat sostenido `DYING` (2.3), (b) retrato del Salón Conmemorativo, (c) revelación de reliquia. Ninguna acción rutinaria de héroe, muerte de tropa ni idle activa Nivel 2. Se requieren **3 assets de Nivel 2 por héroe** (beat de muerte, retrato memorial, prop de reliquia dorada).

**V-5 — Beat de muerte sostenido (art bible 2.3, 5.3 excepción, Principio C)**
Al entrar a `DYING`, la escena se compone según el Principio C — silueta legible sin obstrucción, pausa compositiva deliberada, **sin corte a negro ni cutscene**. Iluminación: cambio súbito a una única luz clave cálida ("luz divina") que aísla al héroe mientras el combate circundante se desatura/desenfoca; casi-silueta a contraluz. **Pose**: única excepción a la rigidez estatuaria — silueta dinámica de colapso/alcance que carga toda la legibilidad emocional sin rostro ni diálogo.

**V-6 — Resolución del beat: silueta → reliquia (art bible 2.3, Principio A)**
La silueta del héroe se **agrieta en fragmentos de vitral tipo rosetón**, cada fragmento congelado un instante en el aire antes de resolverse en el ícono de la reliquia con borde dorado (Oro Reliquia — su primer momento de render material pleno). Es la transición visual que acompaña `DYING → DEAD`.

**Nota de implementación (contrato con Permadeath, Regla 4 / OQ-P6 #5):** el nodo que reproduce V-5→V-6 debe correr exento de la pausa cooperativa que Permadeath activa durante el beat (`game_time_paused`) — en Godot 4.6, `process_mode = PROCESS_MODE_ALWAYS` (o equivalente), igual que el nodo orquestador de Permadeath. Si esta animación se congelara junto con el resto del mundo pausado, su señal de fin (`animation_done`, consumida por la Fórmula P1 de Permadeath) nunca llegaría y todo beat caería al timeout de seguridad, enmascarando el camino normal (Permadeath AC-P04). Aplica también a los nodos de partícula/audio/tween que impulsan el efecto de vitral, no solo al nodo raíz de la animación.

**V-7 — Radio visual mayor que tropas (Fórmula H3)**
Sprite de héroe 48-96px → `unit_visual_radius_world` en [0.5, 1.0], siempre > 0.4583 (techo de tropa), sosteniendo la prioridad de selección héroe > tropa también a nivel de hitbox visual.

### Audio *(contrato provisional — sin audio bible)*

**A-1 — Tratamiento sonoro del beat sostenido**
El beat `DYING` requiere un tratamiento de audio propio que subraye la pausa del Principio C: caída/filtrado del lecho de combate (el mundo "se aparta"), acentuando el aislamiento del héroe. El *timing* lo controla Permadeath (mismo dueño del beat visual), no este sistema — cuando exista su GDD, el audio debe sincronizarse a sus hit-points (crack de silueta V-6, revelación de reliquia). Contrato con la futura dirección de audio.

**A-2 — Understatement sonoro (Pilar anti-melodrama); el silencio es una herramienta válida**
El audio de muerte **no debe editorializar** que la muerte fue hermosa (paralelo sonoro del Principio C / anti-melodrama): contención, no swell triunfal. **Silencio/casi-silencio (dead air) es una opción explícitamente permitida** — puede ser la forma más fuerte de understatement, no se asume que siempre haya material compuesto activo. *(Nota: no se presupone idioma/instrumentación —"swell orquestal" es solo un ejemplo de lo prohibido, no una afirmación de que exista una orquesta; esa decisión pertenece a Dirección de Música.)*

**A-3 — Ciego al RESULTADO (tier), no ciego a la IDENTIDAD**
El audio del beat **no** anticipa ni "califica" sonoramente el *tier emergente* de la reliquia (Delgada/Sólida/Legendaria) — la calidad es un veredicto legible en la UI (U-1..U-2), no un premio auditivo; esto protege el understatement y el test negativo de agencia. **PERO esto es outcome-blind, no identity-blind**: sí se permite (y se recomienda, para que cada muerte se sienta suya y evitar fatiga de repetición a lo largo de decenas de muertes) variación por **identidad fija del héroe** — su `relic_category` (offensive/rally/defensive, telegrafiada desde el reclutamiento) o rasgos propios. Variar por algo que el jugador ya sabía de antemano no premia un resultado emergente; repetir un audio idéntico en cada muerte sí aplanaría el beat central del juego.

**Restricción negativa (para que "identity-varied" no se filtre a "outcome-signaling")**: `relic_category` **no** es outcome-neutral en la práctica — la nota de simetría de H4 admite que los arquetipos defensivos alcanzan `P=1` más fácil, y difieren en tankiness (H1). Por eso la variación por identidad **no debe correlacionar su peso/intensidad acústica con la distribución típica de `relic_quality` del arquetipo**: p. ej. dar al Guardián un cue de muerte más pesado/resonante "por identidad" enseñaría, a lo largo de decenas de muertes, una correlación identidad→tier — exactamente lo que A-3 prohíbe. La variación permitida es *tímbrica/temática* (que suene a *ese* héroe), no *graduada en magnitud* de un modo que rastree el tier. "Rasgos propios" se limita a atributos fijos y conocidos de antemano, nunca a proxies del resultado.

**A-4 — Audio de la ventana de decisión (no solo del epílogo)**
Los inputs D/T/P se snapshotean en `health≤0`, *antes* de que `DYING` empiece — así que A-1 (audio del beat) llega cuando el resultado ya está sellado. La **ventana de decisión de ~30s** (Test de diseño 1) necesita su propio canal auditivo, porque en un RTS ocupado el sonido es el mejor canal periférico: un **cue discreto en cada cruce de tier del readout** (empareja el cambio de estado de U-2, canal de audio/haptic de U-1) le dice al jugador "tu decisión acaba de cambiar el veredicto" sin que tenga que estar mirando ese sprite. Outcome-blind igual (marca *que* cruzó un boundary, no *qué tier ganó*).

**Pin de outcome-blindness (crítico — el cue puede filtrar tier si no se restringe)**: (1) el cue es **idéntico sin importar la dirección** del cruce (subir o bajar de tier suenan igual) — un "sting ascendente vs. thud descendente" sería un signal de valor directo. (2) **No hay cue distintivo en el cruce del D-gate** (`D` 0→1): confirmar Sacrificio salta el readout de 0.10 a un piso garantizado de ≥0.4175, un cruce casi-determinista; un cue especial ahí enseñaría "acabo de asegurar ≥ Tier 2". El D-gate usa el mismo cue genérico de boundary o ninguno. (3) Como solo existen 2 boundaries (0.35, 0.70) y `T` es ~monótona, un jugador no debe poder reconstruir el tier contando cruces — de ahí (1) y (2). Cubierto por AC-H34.

**A-5 — Ducking del kaiju durante el beat**
A-1 filtra el lecho de combate; queda por decidir explícitamente qué pasa con las **vocalizaciones del kaiju**: opción por defecto propuesta = se duckean con el resto (aísla al héroe, coherente con el Principio C). **Riesgo a resolver (no puramente estético)**: si las vocalizaciones del kaiju cargan telegrafíos de ataque (probable, una vez exista Encuentro con Kaiju) y se duckean durante todo el hold `DYING`, el jugador podría salir de `DEATH_HOLD` a un ataque sin aviso audible. Regla propuesta: los telegrafíos **críticos** del kaiju quedan exentos del ducking de A-1/A-5, o se re-anuncian al liberarse `DEATH_HOLD`. *(Tracked en OQ-10; confirmar con Dirección de Audio y Encuentro con Kaiju cuando existan.)*

## UI Requirements

*Referencia rectora: Art Bible Sección 7 (UI 100% diegética, sin capa de HUD estéril — 7.0), 3.3 (gramática de forma de UI), 7.1-7.5. Esta sección resuelve el placeholder de AC-H32 (posición, formato, umbral de visibilidad del readout).*

**Restricción central (tensión de diseño resuelta):** el readout debe hacer el Test de diseño 1 **legible en tiempo real** (~30s antes de una muerte inevitable, el jugador ve que su decisión cambia el veredicto) **sin narrar** ni convertir la tragedia en una pantalla de min-max. Se resuelve con un indicador **diegético, no numérico y de lectura discreta** anclado al héroe, no un número de HUD.

**U-1 — Indicador de veredicto proyectado, anclado al elemento asimétrico (multi-canal, NO solo color)**
El readout de `relic_quality` proyectada se ancla al **elemento asimétrico del héroe** (V-1/V-2 — el ancla de la futura reliquia), no es un número ni una barra. **Restricción de accesibilidad (art bible 4.5, regla permanente)**: el par Oro Reliquia vs Hueso/Ocre es el de mayor riesgo de daltonismo del sistema, así que el estado **nunca se señaliza solo por hue/intensidad de dorado**. Se hereda el patrón diegético que el art bible 7.5 ya fijó para la legibilidad de vida: el veredicto se comunica por **tres canales redundantes** — (1) **forma/marco**: un cambio discreto de la geometría del ancla o de su marco por tier (p. ej. filigrana plana → borde parcial → borde de rosetón completo), legible en silueta y bajo daltonismo; (2) **movimiento**: un pulso/bloom cuya presencia (no su color) marca "veredicto activo"; (3) **color** (Oro Reliquia) solo como refuerzo terciario, nunca como único portador. Refuerza el entrenamiento "dorado = reliquia ganada" (art bible 5.1) sin depender del color y sin texto.

**U-2 — Lectura discreta de 3 estados (mapea a tiers), por forma primero**
El indicador tiene **tres estados legibles** que corresponden a los tiers de la Fórmula H4 — Delgada [0.10,0.35), Sólida [0.35,0.70), Legendaria [0.70,1.00] — diferenciados **primero por forma/marco** (U-1 canal 1), no por rampa continua de color. Esto tiene un beneficio doble: (a) legible de un vistazo a escala RTS y bajo daltonismo; (b) al diferenciar por forma en vez de por gradiente de rareza de color, **evita leerse como el glow de rareza de loot de un ARPG** (Diablo/WoW) — un riesgo real dado el público mid-core/hardcore, que convertiría "veredicto sobre una vida" en "drop de botín". La transición entre estados es discreta y visible, y se acompaña de un **cue de audio/haptic en el cruce de tier** (ver A-4) para no depender de que el jugador esté mirando ese sprite. *Limitación conocida (OQ-8)*: como la mayor influencia táctica cae dentro de una banda de tier, un cambio marginal que no cruza boundary no altera el estado discreto — a evaluar en playtest si hace falta un cue intra-banda sutil (p. ej. tasa de pulso) sin reintroducir el min-max de decimales.

**U-3 — Umbral de visibilidad: por tiempo-hasta-muerte, no por HP (contrato conjunto con Encuentro con Kaiju)**
El indicador aparece **solo** cuando el héroe está condenado/en riesgo activo **o** está seleccionado. **Corrección clave**: el trigger de "en riesgo" NO puede basarse en HP actual, porque HP% y tiempo-hasta-muerte están desacoplados — un héroe al 90% de vida puede morir en 2s por un burst del kaiju, y ningún umbral de HP fijo garantizaría la ventana de ~30s que el Test de diseño 1 (AC-H29) exige como test duro, no advisory. Por eso el trigger consume una estimación de **`time_to_death`/`incoming_damage_rate`** que debe proveer **Encuentro con Kaiju** (dueño del ritmo del encuentro y de los telegrafíos de ataque): el readout se muestra cuando el tiempo-hasta-muerte proyectado cae bajo la ventana objetivo (~30s). Es un **contrato conjunto**, no un knob de UI en solitario. Un héroe sano y sin muerte inminente no muestra readout — evita ruido de HUD y preserva el understatement. *(El valor concreto de la ventana y su histéresis: OQ-6.)*

**U-4 — Congelado durante `DYING` (coherencia con el snapshot)**
Al entrar a `DYING`, el indicador **se congela en el valor snapshoteado** (D/T/P del cruce por 0, Fórmula H5 / AC-H15) y deja de actualizarse — durante el beat el Input está en `DEATH_HOLD` y el jugador no puede cambiar nada (AC-H09). El estado congelado es el que se resuelve visualmente en la reliquia (V-6). No hay conflicto entre "readout en vivo" (pre-muerte) y "veredicto sellado" (muerte).

**U-5 — Sin editorializar (understatement, Principio C / anti-melodrama)**
Prohibido texto de veredicto ("¡Muerte heroica!", "Reliquia legendaria forjada") durante el beat o el readout. El único lenguaje permitido es el diegético del dorado sobre el ancla y su resolución en el ícono de reliquia. La calificación se *muestra*, no se declara (paralelo UI del A-2/A-3 de audio).

**U-6 — Prioridad de selección legible (Regla Core 3, art bible 7.5)**
La UI de selección debe reflejar la prioridad héroe > tropa: al hacer clic donde se solapan héroe y tropa, el marcador de selección resalta al héroe (AC-H07). El marcador de héroe se diferencia del de tropa por la gramática de forma de UI (7.2/3.3), no solo por tamaño.

**U-7 — Iconografía de reliquia derivada (art bible 7.2)**
El ícono de la reliquia resultante (post-`DEAD`, consumido por Forja de Legado) sigue el estilo "iluminado" de 7.2 — silueta plana base + pasada de plomo dorado integrado — reconocible como reliquia incluso en silueta/daltonismo, independiente del borde dorado de estado. *(Nota: el ícono final es propiedad de Forja de Legado; este sistema solo provee `relic_category` + `relic_quality` que determinan cuál.)*

## Acceptance Criteria

*Convención: cada AC usa formato Dado/Cuando/Entonces y una etiqueta de tipo de evidencia (`[Logic/unit]`, `[Integration]`, `[Visual/Feel]`, `[UI]`) según la taxonomía de evidencia de testing del proyecto. Los AC marcados **(bloqueado)** dependen de un sistema sin GDD aún — hoy solo verificables mediante un mock del contrato en el límite de este sistema; deben re-verificarse contra el GDD real cuando exista.*

### A. Definición de Héroes y Datos (Reglas Core 1-3, Fórmulas H1-H3)

**AC-H01 — Carga válida de `HeroDefinition`** **[Logic/unit]**
Dado un `HeroDefinition` con `hero_id`, `hero_name`, `max_health`, `move_speed`, `unit_visual_radius_world`, ≥1 habilidad, `asymmetric_element` y `relic_category` poblados, cuando el sistema carga el `unit_roster` (porción de héroes) de la era ACTIVE, entonces el héroe se instancia sin error y todos los campos son accesibles con los valores exactos del resource.

**AC-H01b — Validación de stats derivados al cargar** **[Logic/unit]**
Dado un `HeroDefinition` cuyos `max_health`/`move_speed`/`unit_visual_radius_world` autorados NO coinciden con sus fórmulas (H1/H2/H3) a partir de `hero_hp_multiplier`/`pan_speed_fraction`/`sprite_diameter_px` (p. ej. `max_health=50` con multiplicador 3.0 que exige ≥120), cuando el sistema carga el resource, entonces la carga falla de forma ruidosa (error/assert en build de desarrollo) — nunca se usa un stat inconsistente con su fórmula (mismo patrón loud-fail que AC-H02).

**AC-H02 — Falla ruidosa sin `relic_category`** **[Logic/unit]**
Dado un `HeroDefinition` sin `relic_category` asignado, cuando el sistema intenta cargarlo, entonces la carga falla de forma ruidosa (error/assert en build de desarrollo) y **no** se asigna ninguna categoría por defecto silenciosamente.

**AC-H03 — `hero_max_health` (H1) exacto por arquetipo** **[Logic/unit]**
Dado `melee_troop_max_health=40` y `hero_hp_multiplier` de 3.5/3.75/5.0, cuando se calcula `hero_max_health`, entonces el resultado es exactamente 140/150/200, y para cualquier `hero_hp_multiplier` en [3.0, 5.0] el resultado es siempre > 40.

**AC-H04 — `hero_move_speed` (H2) exacto por arquetipo, siempre bajo el techo de tropa** **[Logic/unit]**
Dado `camera_pan_speed=30` y `pan_speed_fraction` de 0.1417/0.1333/0.1167, cuando se calcula `hero_move_speed`, entonces el resultado es exactamente 4.25/4.0/3.5 u/s, y para cualquier `pan_speed_fraction` en [0.10, 0.15] el resultado es siempre < 5.0 u/s (tropa ranged, la más rápida).

**AC-H05 — `unit_visual_radius_world` (H3) exacto, piso 0.5, techo de tropa** **[Logic/unit]**
Dado `sprite_diameter_px` de 64/72/80 y `world_unit_scale=48`, cuando se calcula `unit_visual_radius_world`, entonces el resultado es exactamente 0.6667/0.75/0.8333, es siempre ≥0.5, y es siempre > 0.4583 (radio máximo de tropa).

**AC-H06 — `relic_category` es fijo, no emergente** **[Logic/unit]**
Dado un héroe con `relic_category="offensive"`, cuando el héroe muere con cualquier combinación de D/T/P, entonces `relic_category` expuesto a Permadeath sigue siendo `"offensive"` — solo `relic_quality` varía con la circunstancia de muerte.

**AC-H07 — Prioridad de selección héroe > tropa** **[Integration]**
Dado un héroe y una o más tropas cuyos radios de selección se solapan en el punto de clic, cuando el jugador hace clic, entonces el héroe es seleccionado; si hay múltiples héroes solapados, se selecciona el más cercano al punto de clic.

### B. Estados y Transiciones

**AC-H08 — Umbral de muerte (H5)** **[Logic/unit]**
Dado un héroe en cualquier estado `ALIVE_*` con `health_current > 0`, cuando `health_current` llega a ≤0, entonces el héroe transiciona a `DYING` en ese mismo frame, sin importar el estado `ALIVE_*` de origen.

**AC-H09 — `DYING` activa `DEATH_HOLD`** **[Integration]**
Dado un héroe que transiciona a `DYING`, cuando la transición ocurre, entonces el contexto de Input pasa a `DEATH_HOLD` y toda entrada del jugador queda suprimida hasta que el beat se libere.

**AC-H10 — Héroe seleccionado que muere se remueve de la selección** **[Integration]**
Dado un héroe actualmente en el conjunto de selección activo, cuando transiciona a `DYING`, entonces se remueve inmediatamente de ese conjunto de selección.

**AC-H11 — `DYING → DEAD` solo tras liberar el beat** **(bloqueado — timing propiedad de Permadeath, sin GDD)** **[Integration]**
*Mock Contract Assumptions: el mock de Permadeath asume un único hook síncrono `release_beat()` que dispara la transición. Si el GDD real usa un modelo distinto (callback asíncrono, señal con payload), re-verificar.*
Dado un héroe en `DYING`, cuando el beat sostenido (controlado por Permadeath) se libera, entonces el héroe transiciona a `DEAD`; antes de esa liberación, el héroe permanece en `DYING` sin importar cuánto tiempo pase. Verificable hoy con un mock de Permadeath que controla el timing del beat.

**AC-H12 — Contrato de exposición completo en `DYING→DEAD`** **[Integration]**
Dado un héroe que transiciona de `DYING` a `DEAD`, cuando la transición se confirma, entonces el sistema expone a Permadeath (o a su mock) exactamente `hero_id`, `hero_name`, `relic_category`, `relic_quality` (evaluada vía Fórmula H4 en el frame del snapshot de `DYING`, nunca recalculada después) y el payload D/T/P snapshoteado — sin campos faltantes ni nulos. *(Cierra el contrato que Permadeath asume en su Regla 1/AC-P01/AC-P02 — ver `design/gdd/permadeath.md` OQ-P6 #1.)*

### C. Fórmula `relic_quality` (H4) — el corazón del Marco B

**AC-H13 — Test negativo de agencia: piso incondicional** **[Logic/unit]**
Dado `D=0, T=0.95, P=1` (estaca y propósito máximos, pero sin intención), cuando se calcula `relic_quality`, entonces el resultado es exactamente 0.10 (Tier 1 Delgada) — T y P no tienen ningún efecto sin `D=1`.

**AC-H14 — Test negativo de agencia: la compuerta se abre con D=1** **[Logic/unit]**
Dado las mismas circunstancias que AC-H13 pero con `D=1`, cuando se calcula `relic_quality`, entonces el resultado es estrictamente mayor a 0.10 — confirmando que existe un estado "desperdiciado" alcanzable (AC-H13) y que la intención, no la escena, es la compuerta.

**AC-H15 — Snapshot D/T/P congelado, no releído** **[Logic/unit]**
Dado un héroe cuyo `health_current` cruza 0 con `D=1, T=0.30, P=0` en ese frame, cuando `T` y/o `P` cambian en frames posteriores (antes de que se confirme `DEAD`), entonces el `relic_quality` calculado usa los valores del frame de cruce, no los valores posteriores.

**AC-H16 — Ejemplo canónico 1: Desperdiciada** **[Logic/unit]**
Dado `D=0`, cuando se calcula `relic_quality`, entonces el resultado es exactamente 0.10 → Tier 1 Delgada.

**AC-H17 — Ejemplo canónico 2: Deliberada temprana** **[Logic/unit]**
Dado `D=1, T=0.05, P=0`, cuando se calcula `relic_quality`, entonces el resultado es exactamente 0.4175 → Tier 2 Sólida.

**AC-H18 — Ejemplo canónico 3: Bien gastada, climática** **[Logic/unit]**
Dado `D=1, T=0.95, P=1`, cuando se calcula `relic_quality`, entonces el resultado es exactamente 0.9825 → Tier 3 Legendaria.

**AC-H19 — Boundary de tier inferior (0.35)** **[Logic/unit]**
Dado `relic_quality=0.35` exacto, cuando se mapea a tier, entonces el resultado es Tier 2 Sólida (límite inclusivo); dado `relic_quality=0.3499`, entonces el resultado es Tier 1 Delgada.

**AC-H20 — Boundary de tier superior (0.70)** **[Logic/unit]**
Dado `relic_quality=0.70` exacto, cuando se mapea a tier, entonces el resultado es Tier 3 Legendaria (límite inclusivo); dado `relic_quality=0.6999`, entonces el resultado es Tier 2 Sólida.

**AC-H21 — `D` requiere comando Sacrificio activo + muerte dentro de `sacrifice_radius`** **(bloqueado — clasificación provista por Combate/Daño, sin GDD; ver OQ-2)** **[Logic/unit]**
*Mock Contract Assumptions: el mock de Combate/Daño asume que expone (a) un flag `sacrifice_command_active` por héroe, (b) el destino ordenado del comando, y (c) que el confirm-step ya se resolvió antes de marcar el comando como activo. Re-verificar contra el GDD real de Combate/Daño.*
Dado que el jugador emitió y confirmó un comando Sacrificio con destino X sobre un héroe, cuando el héroe muere con el comando aún activo y dentro de `sacrifice_radius` de X, entonces `D=1`; si muere fuera de `sacrifice_radius` de X, entonces `D=0`.

**AC-H21b — Knockback dentro del radio preserva `D=1`** **(bloqueado — ver OQ-2)** **[Logic/unit]**
*Mock Contract Assumptions: igual que AC-H21.*
Dado un héroe con comando Sacrificio activo hacia X, cuando un knockback lo desplaza del punto X exacto pero muere dentro de `sacrifice_radius` de X, entonces `D=1` — la mala suerte física no penaliza un sacrificio genuino.

**AC-H21c — Comando cancelado o sin confirmar → `D=0`** **(bloqueado — ver OQ-2)** **[Logic/unit]**
*Mock Contract Assumptions: igual que AC-H21; el mock asume que un tap sin confirmación nunca marca `sacrifice_command_active=true`.*
Dado (i) un héroe cuyo comando Sacrificio se canceló/reemplazó antes del frame de muerte, o (ii) un héroe sobre el que se tocó Sacrificio sin completar el confirm-step, cuando el héroe muere, entonces `D=0` en ambos casos.

**AC-H22 — Overkill no afecta `relic_quality`** **[Logic/unit]**
Dado dos escenarios idénticos en D/T/P donde uno recibe un golpe de overkill (vida muy por debajo de 0, clamped) y el otro no, cuando se calcula `relic_quality` en ambos, entonces el resultado es idéntico en ambos casos.

**AC-H23 — Loud-fail de tuning knobs individuales fuera de rango al cargar** **[Logic/unit]**
Dado un valor de configuración fuera de su rango seguro individual (p. ej. `base_accidental=0.20`, rango seguro 0.05–0.15; o `base_deliberate=0.60`, rango 0.35–0.50; o `sprite_diameter_px=40`, rango 48–96), cuando el sistema carga la configuración, entonces la carga **falla ruidosamente** (error/assert en build de desarrollo) y el valor **no** se clampa ni se sustituye silenciosamente — nunca se ejecuta un cálculo de `relic_quality` (ni de H1/H3) con un knob fuera de rango. (Reemplaza el comportamiento de clamp anterior; coherente con AC-H02.)

**AC-H23b — Piso de suma conjunta: Tier 3 alcanzable** **[Logic/unit]**
Dado que los pisos individuales (base_deliberate≥0.35, w_stakes≥0.20, w_purpose≥0.15) suman exactamente 0.70, la suma conjunta **no puede** caer por debajo de 0.70 sin que algún knob viole su piso individual (ya atrapado por AC-H23). El check de suma-floor `< 0.70` se conserva como defensa-en-profundidad (belt-and-suspenders) y como guard si un rango individual se afloja en el futuro: cuando la suma de knobs individualmente válidos es `< 0.70`, la carga **falla ruidosamente**. Verificación de reachability: con la suma = 0.70 exacto (todos en su piso), `relic_quality(D=1,T=1,P=1) = 0.70` mapea a Tier 3 Legendaria (límite inclusivo, AC-H20) — Tier 3 es alcanzable en el mínimo conjunto.

**AC-H23c — Techo de suma conjunta: Legendaria sigue exigente** **[Logic/unit]**
Dado un config donde `base_deliberate + w_stakes + w_purpose > 1.00` (p. ej. 0.50+0.40+0.30 = 1.20, cada término en rango individual), cuando el sistema carga la configuración, entonces la carga **falla ruidosamente** — nunca se usa un config donde Legendaria se alcance con `T=0` (muerte en calma).

**AC-H23d — Piso de `base_deliberate`: una muerte deliberada nunca colisiona con una accidental** **[Logic/unit]**
Dado un config con `base_deliberate < 0.35` (p. ej. 0.30, que satisface la suma conjunta 0.30+0.25+0.15 = 0.70 pero viola el floor individual), cuando el sistema carga la configuración, entonces la carga **falla ruidosamente** — porque `relic_quality(D=1, T=0, P=0) = base_deliberate < 0.35` caería en Tier 1 Delgada, colisionando con una muerte accidental (`D=0` → `base_accidental`). Verificación complementaria: con `base_deliberate = 0.35` exacto y `T=0,P=0`, `relic_quality(D=1) = 0.35` → Tier 2 Sólida (límite inclusivo, AC-H19), estrictamente por encima de cualquier resultado accidental.

### D. Edge Cases de Concurrencia, Overkill y Persistencia

**AC-H24 — Snapshots independientes en muerte simultánea** **[Integration]**
Dado dos héroes cuyo `health_current` cruza 0 en el mismo frame con circunstancias D/T/P distintas entre sí, cuando ambos transicionan a `DYING`, entonces cada uno snapshotea su propio payload independientemente, sin que uno sobreescriba o promedie con el otro.

**AC-H25 — Serialización de beats de muerte simultáneos** **(bloqueado — propiedad de Permadeath, sin GDD)** **[Integration]**
*Mock Contract Assumptions: el mock de Permadeath asume serialización FIFO (orden de llegada). Si el GDD real usa prioridad (p. ej. por relic_quality o por hero_id), re-verificar el orden esperado.*
Dado dos héroes en `DYING` en el mismo frame, cuando Permadeath procesa las muertes, entonces no hay dos `DEATH_HOLD` sostenidos simultáneos — se resuelven en secuencia. Verificable hoy solo con un mock de Permadeath que serialice las llamadas entrantes.

**AC-H26 — Autosave obligatorio en muerte de héroe, con payload completo marcado como pendiente de sellar** **[Integration]**
Dado un héroe que transiciona a `DYING`, cuando la transición ocurre, entonces Guardado/Persistencia recibe un disparo de autosave obligatorio antes de que el flujo continúe a la siguiente pantalla/estado; el snapshot persistido incluye el payload de muerte completo (`hero_id`, `hero_name`, `relic_category`, `relic_quality` ya computada, D/T/P) marcado explícitamente como *muerte pendiente de sellar* — no solo `state=DYING` sin datos. *(Contrato con Permadeath Regla 6 — cierra la ventana de crash de la que AC-H27/AC-H27c dependen; ver `design/gdd/permadeath.md` OQ-P6 #2.)*

**AC-H27 — Irreversibilidad a través de crash** **[Integration]**
Dado un héroe que cruzó `health_current ≤ 0` y el autosave obligatorio ya se disparó, cuando el juego se cierra abruptamente (crash) durante el beat `DYING` y se reinicia, entonces el héroe carga como `DEAD` — nunca como `ALIVE` con vida recargada.

**AC-H27c — Coacción `DYING → DEAD` con reliquia forjada al recargar (contrato con Permadeath Regla 8b / AC-P18-ext)** **[Integration]**
Dado un héroe persistido en `DYING` cuyo autosave incluye el payload completo de muerte marcado como *muerte pendiente de sellar* (AC-H26), cuando el flujo de carga se ejecuta tras un crash o cierre ocurrido en cualquier punto del beat `HOLDING` de Permadeath, entonces el héroe se coacciona a `DEAD` (nunca permanece en `DYING` ni carga como `ALIVE` con vida recargada) y su reliquia se forja desde la `relic_quality` persistida — sin reproducir el beat visual `DEATH_HOLD` (el beat es una experiencia de sesión, no un estado a restaurar). Esta coacción la posee el flujo de carga de Héroes + Guardado/Persistencia; Permadeath no participa — arranca con su cola vacía tras cualquier reload (ver Permadeath AC-P18).

**AC-H27b — Un héroe `DEAD` es inaccionable en sesión (Regla 4, estado terminal)** **[Logic/unit]**
Dado un héroe en estado `DEAD`, cuando se le intenta emitir cualquier orden (movimiento, Sacrificio), aplicar un efecto de curación, o agregarlo al conjunto de selección, entonces toda acción es rechazada/no-op y el héroe permanece `DEAD` — confirma que `DEAD` es terminal sin transiciones salientes (tabla de estados), no solo a través del path de crash de AC-H27.

**AC-H28 — Este sistema no declara victoria/derrota** **[Logic/unit]**
Dado que todos los héroes de la era mueren, cuando la última muerte se procesa, entonces el Sistema de Héroes no emite ninguna señal ni llamada de evaluación de victoria/derrota — solo notifica cada muerte individual a sus consumidores declarados.

### E. Tests de Diseño y Validación de Playtest (Player Fantasy)

**AC-H29 — Ventana de decisión de ~30s (Test de diseño 1)** **(contrato de datos resuelto — Encuentro con Kaiju Approved; queda como Integration sobre era jugable + verbo Sacrificio de Control)** **[Integration]**
*Contrato real (ya no mock, lado Encuentro): Encuentro con Kaiju (Approved) provee `time_to_death` por héroe (F2 = `telegraph_duration_s + kill_time_hits×attack_cooldown_s`, proyección pre-contacto que da 32.0s/36.5s para los arquetipos MVP a HP completo) **e** `incoming_damage_rate_total` (F6, DPS combinado kaiju+esbirros); el readout (U-3) debe reflejar la fuente más peligrosa (Encuentro Regla 6b/AC-K68). Los cross-checks del lado receptor son Encuentro AC-K26/AC-K68. Sigue siendo Integration porque necesita (a) una era jugable y (b) el verbo Sacrificio de Control (aún no escrito, OQ-2) — pero el `time_to_death` ya no es un mock.*
Dado un héroe cuya muerte es inevitable, cuando se observan los ~30 segundos previos a la muerte (proyectados por el `time_to_death` real de Encuentro con Kaiju), entonces existió al menos una decisión táctica disponible al jugador (comando Sacrificio, reposicionamiento) que habría cambiado el D/T/P resultante snapshoteado, y el readout de veredicto fue visible durante esa ventana.

**AC-H30 — Estado "desperdiciado" alcanzable en juego real (Test de diseño 2)** **(contratos de diseño Approved — Combate/Daño + Encuentro con Kaiju; requiere una era jugable implementada)** **[Integration]**
*Nota: los contratos de diseño de los que depende (Combate/Daño y Encuentro con Kaiju) ya están **Approved** — ya no es un hueco de diseño. Sigue siendo un Integration test que requiere una era jugable **implementada** (instanciar un héroe, infligirle daño letal sin comando Sacrificio activo, y leer el `relic_quality` resultante). Se ejecuta en el vertical slice, no contra un mock.*
Dado una era jugable completa, cuando se juega sin emitir ningún comando Sacrificio sobre un héroe que termina muriendo, entonces el resultado es `D=0` → Tier 1 Delgada — confirmando en contexto real (no solo en unit test aislado, AC-H13/AC-H16) que ninguna regla oculta fuerza `D=1`.

**AC-H31 — Validación de playtest: lectura espontánea de la muerte** **[Integration]**
Dado una sesión de playtest documentada tras la muerte de un héroe, cuando se le pide al playtester describir la muerte sin preguntas dirigidas, entonces la transcripción se registra en `production/qa/evidence/` y **qa-tester la codifica contra una rúbrica pre-aprobada por game-designer** que distingue tres registros: (a) trágico-atribuido (nombra al héroe y atribuye el resultado a su acción específica), (b) transaccional-frío (lenguaje de descripción de ítem: "conseguí un Tier 3"), (c) solo-afecto (solo tristeza/frustración, sin mencionar qué compró la muerte). El Marco B se considera validado solo si predomina (a) por sobre (b) y (c). Evidencia cualitativa documentada — no automatizable; requiere ≥1 sesión por era del MVP. *(La rúbrica de 3 registros evita el falso positivo de "mencionó qué compró antes que cómo se sintió" que no distingue tragedia de transaccionalidad frío — ver Player Fantasy.)*

**AC-H31b — El D-gate no deriva a "culpa pura" (validación de feel del confirm-step)** **(playtest — vertical slice; depende del comando Sacrificio real de Combate/Daño)** **[Integration]**
Dado ≥1 sesión de playtest documentada por era del MVP en la que un héroe muere con `D=0` tras un intento **genuino** de sacrificio del jugador (comando Sacrificio emitido pero muerte fuera de `sacrifice_radius`, o el jugador holdeó una línea climática con órdenes ordinarias sin emitir Sacrificio), cuando `qa-tester` codifica la reacción del playtester, entonces se registra si el registro predominante es "veredicto entendido/justo" vs "castigo/gotcha injusto" (culpa pura, ver Player Fantasy §criterio de validación). Si predomina "culpa pura" en ≥[umbral a fijar en QA plan] de los casos, se **activa la alternativa registrada en OQ-11** (ampliar `D=1` a Hold sostenido contra probabilidad letal). Esta AC existe porque la re-review (game-designer + narrative-director, convergentes) señaló que el confirm-step puede sobre-restringir "deliberado" a un solo verbo de menú; el playtest con controlador en mano es el árbitro, no otra ronda de rediseño en papel.

### F. UI Readout

**AC-H32a — Transición discreta de estado en boundaries de tier** **[UI]**
Dado un héroe condenado con readout de veredicto visible, cuando `relic_quality` proyectado cruza un boundary de tier (0.35 o 0.70), entonces el estado visual discreto del readout cambia exactamente en ese boundary (mapeo idéntico a AC-H19/AC-H20), y no se observa ningún estado intermedio/continuo entre los 3 estados. (Ver U-2.)

**AC-H32b — Umbral de visibilidad del readout** **(contrato de datos resuelto — Encuentro con Kaiju Approved provee `time_to_death`; el valor de umbral concreto sigue abierto en OQ-6)** **[UI]**
*Contrato real (ya no mock): Encuentro con Kaiju (Approved) expone `time_to_death`/`incoming_damage_rate_total` por héroe (F2/F6), y el readout se muestra cuando la proyección de la fuente más peligrosa cae bajo la ventana objetivo. La regla binaria (oculto vs visible) es verificable contra el contrato real. El **valor de umbral concreto** (~30s) y su histéresis quedan abiertos (OQ-6, a afinar en `/ux-design` — ver también Encuentro OQ-14 sobre anti-parpadeo de la señal dual).*
Dado un héroe sano y no seleccionado, cuando se observa la pantalla, entonces el readout está oculto; dado un héroe marcado en-riesgo (por el trigger de time-to-death) **o** seleccionado, entonces el readout es visible. (Ver U-3.)

**AC-H32c — Freeze del readout en `DYING`** **[Integration]**
Dado un héroe que entra a `DYING`, cuando ocurre la transición, entonces el readout se congela en el valor snapshoteado (AC-H15) y no vuelve a actualizarse hasta resolverse en el ícono de reliquia (V-6). (Ver U-4.)

**AC-H32d — Sin texto editorializante durante readout/beat** **[UI]**
Dado que el readout de veredicto o el beat de muerte está activo, cuando se observa la pantalla, entonces no se renderiza ningún string de texto de veredicto ("¡Muerte heroica!", "Reliquia legendaria forjada", etc.). Evidencia: walkthrough manual (understatement, U-5 / A-2). (Ver U-5.)

**AC-H32e — Estado de tier distinguible sin color (regla permanente de daltonismo, art bible 4.5)** **[UI]**
Dado el readout de veredicto visible en cualquiera de sus 3 estados de tier, cuando se observa bajo simulación de daltonismo (deuteranopia/protanopia) **o** en escala de grises (canal de color removido), entonces los 3 estados siguen siendo distinguibles entre sí por forma/marco (U-1 canal 1) y por la presencia/ausencia de movimiento — el canal de color (Oro Reliquia) **nunca** es el único diferenciador. Evidencia: walkthrough manual con filtro de daltonismo/grayscale a escala Nivel 1 LOD (24–32px). Cubre la "regla permanente" de U-1 que AC-H32a (solo transición discreta) no verifica. (Ver U-1, art bible 4.5.)

**AC-H33 — Marcador de selección diferencia héroe de tropa** **[UI]**
Dado un héroe y una tropa ambos seleccionables, cuando cada uno se selecciona, entonces el marcador de selección del héroe se distingue visualmente del de la tropa por la gramática de forma de UI (art bible 7.2/3.3), no solo por tamaño — cubre U-6, que AC-H07 (solo lógica de prioridad) no verifica.

### G. Audio (contrato provisional — re-verificar con Dirección de Audio)

*Los requisitos de audio A-1..A-5 son un contrato provisional sin audio bible aún; solo A-4 tiene un trigger discreto testeable hoy. A-1/A-2/A-3/A-5 son cualitativos/de dirección y su evidencia (walkthrough + sign-off de audio-director) se define cuando exista Dirección de Audio — ver Open Questions.*

**AC-H34 — El cue de la ventana de decisión (A-4) es outcome-blind** **(bloqueado — timing/assets de audio dependen de Dirección de Audio, sin GDD)** **[Integration]**
*Mock Contract Assumptions: el mock dispara el cue en cada cruce de boundary (0.35, 0.70) del readout proyectado y en el cruce del D-gate, exponiendo qué muestra de audio se reproduce.*
Dado un readout de veredicto en vivo durante la ventana de decisión, cuando `relic_quality` proyectado cruza un boundary de tier hacia arriba, hacia abajo, **o** cruza el D-gate (`D` 0→1), entonces el cue reproducido es **idéntico en los tres casos** (misma muestra, sin variante direccional ni sting especial en el D-gate) — de modo que el jugador no puede inferir *qué tier* alcanzó ni *en qué dirección* se movió, solo *que* algo cambió. (Ver A-4.)

## Open Questions

*Preguntas abiertas y contratos provisionales que este GDD deja registrados para resolver cuando existan los sistemas dependientes. Ninguna bloquea la validez del diseño actual, pero varias bloquean la *verificación* de AC específicas (ver Acceptance Criteria).*

**OQ-1 — ¿Quién posee la evaluación de victoria/derrota de era?**
Cuando todos los héroes de una era mueren es (casi con certeza) la condición de derrota, pero este sistema **no** posee esa evaluación (AC-H28) — solo notifica cada muerte. Dueño candidato: **Encuentro con Kaiju** o **Transición de Era**. Mismo hueco abierto que en Sistema de Tropas. *Resolver al diseñar esos sistemas.*

**OQ-2 — Contrato de clasificación `D` (deliberada) y `P` (propósito)**
La Fórmula H4 consume `D` (comando Sacrificio activo + muerte dentro de `sacrifice_radius`, ver definición completa en H4) y `P` (murió en `guard_radius` de un objetivo marcado **o** neutralizando una amenaza marcada del kaiju). Ambas clasificaciones las debe proveer **Combate/Daño** (sin GDD aún). Los *thresholds* ya no están indefinidos — son los tuning knobs `sacrifice_radius` (default 3.0) y `guard_radius` (default 4.0); lo pendiente es que Combate/Daño **implemente y confirme** la clasificación (incluido el confirm-step del comando Sacrificio y la vía ofensiva de `P`), no inventar el umbral. Bloquea la verificación real de AC-H21/H21b/H21c y de las AC de `relic_quality` que dependen de `D`/`P` de gameplay (hoy testeables con mock). *Resolver al diseñar Combate/Daño y el sistema de órdenes.*

**OQ-3 — Provisión de `kaiju_timer_remaining_ratio` (input `T`)** — ✅ **RESUELTO (2026-08-07)**
`T = 1 − kaiju_timer_remaining_ratio`. El ratio lo **posee el Temporizador de Preparación/Ritual** (Regla 3 / Fórmula F2 de ese GDD, ya diseñado): va de 1.0 al inicio de la Preparación a 0.0 en el clímax, fijado en 0 durante el clímax. Este sistema lo lee en el frame de muerte para `T`; Encuentro con Kaiju lo consume en paralelo (no lo posee). *Nota: AC-H29 (ventana de decisión de ~30s) sigue bloqueada, pero por una razón más acotada — depende del `time_to_death` por héroe que provee Encuentro con Kaiju (U-3), no del ratio global, que ya tiene dueño.*

**OQ-4 — Contrato crítico con Permadeath (dueño del beat de muerte)** — *(parcialmente resuelto 2026-08-15: Permadeath ya tiene GDD — `design/gdd/permadeath.md`. El payload ahora incluye `relic_quality` (ver AC-H12 actualizado); AC-H11/AC-H25 siguen bloqueados porque su verificación end-to-end requiere Permadeath implementado, no solo diseñado.)*
Permadeath (**consumidor crítico**) recibe el payload de circunstancia (`hero_id`, `hero_name`, `relic_category`, `relic_quality`, D/T/P snapshoteados) y controla el *timing* del beat `DEATH_HOLD` y la confirmación de `DEAD`. Bloquea la verificación de AC-H11 y AC-H25 (hoy testeables con mock, pendientes de Permadeath implementado). Es el contrato más importante del proyecto: define cómo la muerte se convierte en legado.

**OQ-5 — ¿Lockear los 3 arquetipos como héroes reales del MVP?**
Vanguardia / Portaestandarte / Guardián se usan a lo largo del GDD como **ilustraciones** de las 3 `relic_category`, no como un roster cerrado. Decisión pendiente: ¿se vuelven los héroes reales de la primera era del MVP, o quedan solo como plantillas y el roster real se define en Datos de Era/Civilización? *Decidir al poblar el roster de la primera era.*

**OQ-6 — Ventana concreta de `time_to_death` para el readout de UI (U-3)**
El trigger de visibilidad del readout ya está resuelto en *tipo* (por `time_to_death` proyectado, contrato conjunto con Encuentro con Kaiju — U-3), no por HP. Lo que queda abierto es el **valor concreto de la ventana** (~30s objetivo) y su histéresis (para que no parpadee cuando el time-to-death oscila cerca del umbral). *Afinar en Pre-Producción / vertical slice, junto con Encuentro con Kaiju.*

**OQ-7 — ¿Pesos de H4 relativos al arquetipo? (alternativa a la vía dual de `P`)**
La homogeneización de arquetipos (ofensivos castigados con `P=0`) se resolvió dando a `P` una vía ofensiva (ver H4). Alternativa no elegida, a revisitar si el playtest muestra que la vía dual no basta: hacer `w_stakes`/`w_purpose` relativos al arquetipo. Se prefirió la vía dual por simplicidad de tuning. *Revisitar en playtest de balance.*

**OQ-8 — ¿Cue intra-banda para decisiones que no cruzan boundary de tier?**
El readout discreto de 3 estados (U-2) no cambia cuando una decisión mejora `relic_quality` sin cruzar un boundary de tier (p. ej. subir `T` dentro de la banda Sólida). A evaluar en playtest si eso hace sentir que "no pasó nada" y si hace falta un cue intra-banda sutil (tasa de pulso, etc.) sin reintroducir el min-max de decimales que U-2 evita a propósito. *Afinar en playtest.*

**OQ-9 — Estructura de `AbilityDefinition`**
`HeroDefinition.abilities` es `Array[AbilityDefinition]` con ≥1 entrada, pero la estructura interna de `AbilityDefinition` (tipo de habilidad, coste, cooldown, target, efecto) es un contrato del futuro sistema de Habilidades/Combate, sin GDD aún. Este sistema solo exige que el array exista y no esté vacío (AC-H01). *Definir al diseñar Combate/Habilidades.*

**OQ-10 — Exención de telegrafíos del kaiju durante el ducking del beat (A-5)**
Durante el hold `DYING`, A-1/A-5 duckean el lecho de combate y (por defecto propuesto) las vocalizaciones del kaiju. Si esas vocalizaciones cargan telegrafíos de ataque, duckearlas por completo podría hacer que el jugador salga de `DEATH_HOLD` a un ataque sin aviso audible. Regla propuesta: telegrafíos críticos exentos del ducking, o re-anunciados al liberarse el beat. *Resolver con Dirección de Audio y Encuentro con Kaiju (owners del telegrafío) cuando existan.*

**OQ-11 — Alternativa registrada para el D-gate (si el confirm-step deriva a "culpa pura")**
El D-gate actual exige un comando **Sacrificio** dedicado con confirm-step (Regla 5, H4). La re-review de 2026-08-07 (game-designer + narrative-director, convergentes) señaló un riesgo real: el confirm-step puede leerse como "ritual-as-checkbox" y hacer que una muerte holdeando una línea climática con órdenes ordinarias (Hold/Attack-Move) marque `D=0` → Tier 1, contradiciendo la fantasía "El Que Decide Cómo Termina" y potencialmente derivando al estado de falla que el propio Player Fantasy define ("frustración/castigo → culpa pura"). **Decisión consciente (creative-director)**: para el MVP se mantiene el confirm-step (es la solución anti-exploit correcta e implementable que resolvió un bloqueante previo); la preocupación de *feel* es una hipótesis de playtest, no un defecto de spec, y este es el segundo ciclo sobre la misma mecánica — se valida con controlador en mano, no con otra ronda de rediseño en papel. **Alternativa registrada (NO adoptada; se activa si AC-H31b muestra "culpa pura" predominante)**: ampliar `D=1` para que también se dispare con una orden Hold/engage **sostenida contra probabilidad letal** (order-intent-persistence: duración mínima + sin orden de retirada activa), manteniendo el comando Sacrificio como el ritual de mayor techo/opcional — esto restaura la agencia de tácticas orgánicas sin reabrir el exploit del Hold reflejo (duración + no-retirada sigue siendo un compromiso real). **Gap asociado**: la forma de input concreta del confirm-step (hold-duration / doble-clic / modal) no está especificada y debe caber en la ventana de reacción de ~30s — contrato con Combate/Daño. *Resolver en vertical slice.*
