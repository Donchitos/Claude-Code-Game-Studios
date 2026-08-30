# Game Concept: What the Gods Left Behind

*Created: 2026-07-20*
*Status: Draft*

---

## Elevator Pitch

> Es un RTS narrativo con elementos roguelite donde comandas civilizaciones distintas a lo largo de la historia, cada una enfrentando a un kaiju que amenaza con destruirla — y las muertes permanentes de tus héroes se convierten literalmente en las reliquias y bendiciones que la siguiente civilización usará para sobrevivir a la próxima bestia.
>
> Test de 10 segundos: comandas un héroe y su ejército contra un kaiju gigante; si tu héroe muere, esa muerte se vuelve un arma legendaria para la próxima era. Se entiende de inmediato.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | RTS narrativo / Roguelite de meta-progresión |
| **Platform** | Multiplataforma (PC como plataforma principal, consola como objetivo posterior) |
| **Target Audience** | Fans de campañas narrativas RTS (Warcraft 3, Age of Mythology) y de roguelites con permadeath significativo (Hades, Darkest Dungeon) |
| **Player Count** | Un jugador |
| **Session Length** | 30-120 min (una "era"/campaña corta por sesión) |
| **Monetization** | Premium (pago único) |
| **Estimated Scope** | Grande (15-21 meses, en solitario) |
| **Comparable Titles** | Warcraft 3 (campaña con héroes), Age of Mythology (civilizaciones/mitología jugable), Hades (meta-progresión entre corridas con permadeath significativo) |

---

## Core Fantasy

Eres el líder que la Historia recuerda por haber pagado el precio necesario para que la humanidad sobreviviera un poco más. No ganas simplemente batallas: decides quién muere, cómo muere, y qué queda de esa muerte para que la siguiente generación pueda pelear. Es la fantasía de ser Arthas, Ezio o Aquiles en el momento exacto en que la tragedia se vuelve mito — y de ver esa tragedia convertirse, generaciones después, en la espada que otro héroe empuña.

---

## Unique Hook

Es como Age of Mythology (civilizaciones con poder mitológico jugable), Y ADEMÁS los "mitos" que usas en combate son literalmente las decisiones y muertes de tus propias partidas anteriores — cada reliquia legendaria tiene el nombre de un héroe que tú viste morir, y su poder mecánico refleja quién fue y cómo cayó (su rol define el tipo de bendición; qué tan bien se gastó su muerte define su potencia).

Esto afecta directamente el gameplay (no es solo lore): el pool de reliquias/bendiciones disponibles en una era depende enteramente de cómo jugó el usuario las eras anteriores.

> **Precisión de fidelidad (Pilar 2):** el poder de una reliquia refleja **quién fue el héroe y cómo cayó** — su rol/arquetipo determina el *tipo* de bendición (ofensiva/defensiva/rally, `relic_category`), y qué tan bien se gastó su muerte (deliberada, en juego alto, sirviendo un propósito) determina su *potencia* (tier). No es que cada muerte genere un efecto único e irrepetible; es que cada reliquia lleva el nombre y la circunstancia de una tragedia que el jugador vivió, y su fuerza mecánica está atada a esa circunstancia.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 2 | Pixel art gótico de alto detalle, clímax de combate contra kaijus con contraste de escala brutal |
| **Fantasy** (make-believe, role-playing) | 3 | El jugador ES el líder histórico cuyas decisiones se vuelven mito |
| **Narrative** (drama, story arc) | 1 | Estructura de tragedia por era; legado mecánico directo entre campañas |
| **Challenge** (obstacle course, mastery) | 4 | Combate táctico deliberado, gestión de reliquias limitadas |
| **Fellowship** (social connection) | N/A | Sin foco multijugador en el MVP |
| **Discovery** (exploration, secrets) | 5 | Descubrir qué reliquia nace de cada tipo de muerte/decisión |
| **Expression** (self-expression, creativity) | 6 | Construcción de un panteón propio de reliquias a través de las eras |
| **Submission** (relaxation, comfort zone) | N/A | No es un objetivo de diseño |

### Key Dynamics (Emergent player behaviors)
- Los jugadores empezarán a tomar decisiones tácticas pensando en "qué reliquia quiero que nazca de esto", no solo en ganar la batalla inmediata.
- Los jugadores se encariñarán con héroes sabiendo que su muerte es probable y mecánicamente valiosa, generando apego emocional real en lugar de frustración por permadeath.
- Los jugadores compararán y compartirán los panteones únicos de reliquias que construyeron a partir de sus propias decisiones.

### Core Mechanics (Systems we build)

1. **Combate ritual-clímax**: fases de preparación/posicionamiento pausadas que desembocan en enfrentamientos breves e intensos contra el kaiju de la era.
2. **Permadeath con forja de legado**: la muerte de un héroe es permanente y genera mecánicamente una reliquia/hechizo específico basado en quién fue y cómo cayó (rol → tipo; calidad de la muerte → potencia), disponible en eras futuras.
3. **Bendiciones aleatorias por reliquia**: durante el combate se ofrecen bendiciones sorteadas desde el panteón de reliquias acumuladas, generando variedad de build por partida (estilo "boons" de Hades).
4. **Transición narrativa entre eras**: cada civilización/era es una campaña acotada que termina en una decisión de consecuencia permanente, conectando mecánica y narrativamente con la siguiente era.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | El jugador decide activamente qué héroe sacrifica, cómo, y qué reliquia se forja de esa decisión | Core |
| **Competence** (mastery, skill growth) | Dominio táctico de invocar bendiciones/reliquias en el momento correcto del clímax contra el kaiju | Core |
| **Relatedness** (connection, belonging) | Vínculo emocional fuerte con héroes que probablemente no sobrevivirán, y con el panteón histórico que el jugador mismo construyó | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: construir un panteón completo de reliquias legendarias a través de todas las eras
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: descubrir qué reliquia/bendición nace de cada tipo de muerte o decisión táctica
- [ ] **Socializers** (relationships, cooperation, community) — No es un foco del MVP
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — No es un foco del MVP; explícitamente excluido (ver Anti-Pilares)

### Flow State Design

- **Onboarding curve**: la primera era/civilización enseña el loop completo (preparación → clímax → decisión de legado) en una sola campaña corta, sin exponer aún el sistema de bendiciones aleatorias hasta la segunda partida.
- **Difficulty scaling**: cada kaiju siguiente exige combinaciones más específicas de reliquias heredadas, empujando al jugador a planear decisiones de sacrificio con más cuidado.
- **Feedback clarity**: cada reliquia lleva el nombre y la escena de la muerte que la originó, haciendo visible de inmediato la conexión entre decisión pasada y poder presente.
- **Recovery from failure**: la derrota (o la muerte de un héroe) nunca es un game-over — se transforma automáticamente en contenido jugable futuro, haciendo del fracaso una fuente narrativa y mecánica, no un castigo vacío.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Fases de posicionamiento y preparación ritual (mover tropas, invocar bendiciones limitadas) que estallan en choques breves, densos y de alta tensión contra el kaiju — el ritmo alterna deliberadamente entre calma táctica y clímax explosivo.

### Short-Term (5-15 minutes)
Ciclos de "avance de era": recolectar recursos y posicionar fuerzas mientras el kaiju se acerca en un temporizador visible, decidiendo cuándo invocar una reliquia heredada (recurso limitado, no se puede abusar).

### Session-Level (30-120 minutes)
Una campaña-era completa (una civilización, un kaiju) que siempre termina en una decisión de consecuencia permanente: qué héroe muere, cómo muere, y qué reliquia se forja de esa muerte para la siguiente era.

### Long-Term Progression
El jugador construye su propio panteón de reliquias legendarias a través de las eras de la historia. El objetivo final no es "ganar" una batalla individual, sino completar la cadena histórica completa y ver qué mitología terminó construyendo con sus propias decisiones.

### Retention Hooks
- **Curiosity**: qué reliquia nacerá de la próxima muerte, y cómo cambiará la próxima era.
- **Investment**: héroes por los que el jugador desarrolló apego emocional, y el panteón acumulado que no quiere "perder" abandonando el juego.
- **Social**: (secundario) comparar el panteón único construido con el de otros jugadores.
- **Mastery**: dominar la sincronización de bendiciones y reliquias en el clímax de combate contra kaijus cada vez más exigentes.

---

## Game Pillars

### Pillar 1: Sacrificio con Peso
La muerte de un héroe es permanente y define el futuro del juego, nunca un simple game-over.

*Design test*: Si dudamos entre dar un reintento gratuito o dejar que la caída del héroe sea definitiva y genere legado, elegimos que sea definitiva.

### Pillar 2: El Pasado es Poder
Las decisiones y muertes de campañas anteriores se convierten literalmente en herramientas mecánicas (reliquias, hechizos, bendiciones) en el futuro.

*Design test*: Si un sistema nuevo no puede conectarse con claridad a una decisión pasada del jugador, no pertenece al juego.

### Pillar 3: Preparación Ritual, Clímax Explosivo
El ritmo alterna entre construcción/posicionamiento pausado y enfrentamientos breves e intensos contra el kaiju.

*Design test*: Si una mecánica alarga el combate sin aumentar la tensión, se recorta.

### Pillar 4: Historia Jugada, No Contada
Los momentos trágicos se viven a través de decisiones tácticas del jugador, no de cinemáticas pasivas.

*Design test*: Si un momento narrativo clave puede resolverse sin que el jugador tome una decisión, se rediseña para que dependa de él.

### Anti-Pillars (What This Game Is NOT)

- **NOT multijugador competitivo en el MVP**: comprometería el Pilar 2, ya que la progresión de legado es un viaje personal del jugador con su propio panteón.
- **NOT construcción de base/economía masiva estilo Age of Empires clásico**: comprometería el Pilar 3; el ritmo se diluiría con micromanagement económico extenso.
- **NOT generación procedural de mapas o civilizaciones completas**: comprometería el Pilar 4; la narrativa autoral se perdería en contenido puramente aleatorio. La aleatoriedad se limita a las bendiciones/reliquias ofrecidas en combate, no a la estructura narrativa de las eras.

---

## Visual Identity Anchor

**Dirección visual seleccionada**: Gótico Pixelado Sagrado (referencia directa: Blasphemous 2)

**Regla visual de una línea**: Cada escena debe leerse como un fresco de vitral renderizado en píxeles — ornamentado, oscuro y reverente.

**Principios visuales de soporte**:
1. Pixel art de alto detalle con iluminación pictórica. *Design test*: si un sprite se ve genérico o sin ornamento, se rehace.
2. Contraste de escala brutal entre los kaijus y las unidades pequeñas con armadura gótica. *Design test*: si el kaiju no empequeñece la pantalla en un encuentro de clímax, la composición falla.
3. Color como señal ritual. *Design test*: si un elemento legendario (reliquia, bendición) no resalta claramente contra el mundo apagado, no está cumpliendo su función.

**Filosofía de color**: Paleta apagada de piedra, sangre seca y hueso como base por civilización/era, reservando acentos dorados y luminosos exclusivamente para reliquias y elementos legendarios — reforzando mecánica y visualmente que el legado es literalmente lo más sagrado y brillante del mundo del juego.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Warcraft 3 | Héroes centrales con arcos narrativos trágicos, combate táctico deliberado con pocas unidades | El arco trágico de un héroe se vuelve mecánicamente heredable, no solo un recuerdo narrativo | Valida que el público de RTS ya ama este tipo de peso narrativo |
| Age of Mythology | Civilizaciones distintas con poder mitológico jugable | La mitología no es fija/histórica: es literalmente generada por las partidas pasadas del jugador | Valida el atractivo de facciones históricas con poder sobrenatural jugable |
| Hades / Rogue Legacy | Meta-progresión entre corridas, permadeath con propósito, bendiciones aleatorias | Sin estructura de "corridas" cortas repetidas: las eras son campañas narrativas largas y acotadas, no runs infinitos | Valida que el permadeath con recompensa mecánica genera apego, no frustración |

**Non-game inspirations**: La caída de Arthas en Warcraft 3, la muerte de Cristina en Assassin's Creed Brotherhood, y el sacrificio de Quirón en Age of Mythology — todos comparten el patrón de tragedia personal dentro de un conflicto histórico más grande, que es el núcleo emocional de este juego.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-40 |
| **Gaming experience** | Mid-core a hardcore |
| **Time availability** | Sesiones de 30-120 minutos, capaces de completar una campaña-era por sesión |
| **Platform preference** | PC primero, consola después |
| **Current games they play** | Warcraft 3 (Reforged/clásico), Age of Mythology, Hades, Darkest Dungeon |
| **What they're looking for** | Un RTS con el peso narrativo y las consecuencias permanentes que sienten que faltan en el género desde Warcraft 3 |
| **What would turn them away** | Enfoque competitivo/PvP, micromanagement económico pesado sin recompensa narrativa, permadeath sin recompensa mecánica clara |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 (ya pineado en el proyecto; buen soporte 2D, gratuito, adecuado para el alcance de un desarrollador solo) |
| **Key Technical Challenges** | Persistencia de datos de legado entre "eras"/campañas; balance del pool de reliquias/bendiciones a medida que crece; UI clara para mostrar la procedencia narrativa de cada reliquia |
| **Art Style** | Pixel art gótico de alto detalle (2D) |
| **Art Pipeline Complexity** | Media-alta (animación cuidadosa de sprites, iluminación pictórica, sin necesidad de modelado 3D) |
| **Audio Needs** | Moderado a alto — música orquestal/coral que refuerce el tono trágico, diseño de sonido de impacto para los clímax contra kaijus |
| **Networking** | Ninguno en el MVP (un jugador) |
| **Content Volume** | Visión completa: 4-5 civilizaciones/eras jugables, 4-5 kaijus únicos, estimado de 15-20 horas de campaña total |
| **Procedural Systems** | Limitado — solo el sorteo de bendiciones/reliquias en combate es aleatorio; mapas y estructura narrativa son autorales |

---

## Risks and Open Questions

### Design Risks
- El sistema de legado directo/mecánico (reliquias con nombre propio por muerte de héroe) podría volverse difícil de balancear si el pool crece sin control entre eras.
- El apego emocional a los héroes depende de una escritura y presentación fuertes; si la narrativa no logra ese peso, el permadeath se siente como un castigo vacío en vez de una tragedia significativa.

### Technical Risks
- Godot 4.6 es una versión reciente (post-cutoff del modelo) — hay que validar patrones de UI y persistencia de guardado entre "eras" temprano, cruzando referencia con `docs/engine-reference/godot/VERSION.md`.
- El sistema de persistencia de legado entre campañas es una arquitectura de datos nueva sin muchos referentes RTS directos.

### Market Risks
- El género de RTS narrativo de un jugador es nicho; el público existe (fans de Warcraft 3/AoM) pero es más pequeño que el RTS competitivo tradicional.
- La combinación con permadeath/roguelite podría alejar a jugadores de RTS tradicionales que esperan poder "guardar y cargar" sin penalización.

### Scope Risks
- El Alpha (4-5 civilizaciones completas) es el tramo de mayor riesgo de tiempo para un desarrollador solo.
- El arte pixel gótico de alto detalle es lento de producir en solitario y podría extender el pipeline de arte más de lo estimado.

### Open Questions
- ¿Cuántas reliquias/bendiciones por era son suficientes para sentir variedad sin volverse inmanejables de balancear? — a resolver con `/prototype` del sistema de legado.
- ¿Cómo se comunica visualmente en la UI que una reliquia proviene de una decisión pasada del jugador y no de contenido genérico? — a resolver con `/art-bible` y `/ux-design`.

---

## MVP Definition

**Core hypothesis**: Los jugadores encuentran satisfactorio el ciclo de preparación ritual → clímax contra el kaiju → consecuencia permanente de legado, incluso dentro de una sola era.

**Required for MVP**:
1. Una civilización jugable completa (una era) con su propio kaiju y clímax de combate.
2. Sistema de permadeath de héroe funcionando de principio a fin, incluyendo la **producción** de la reliquia: una muerte presenciada por el jugador se forja en una `RelicRecord` de extremo a extremo (permadeath → forja de legado). Esta es la mitad del Pilar 2 que una sola era **sí** puede validar.
3. El **consumo** de reliquias (invocar bendiciones durante el clímax, el draft 3-choose-1) validado con un **panteón pre-sembrado** de héroes de una "era 0" establecida en la ficción. La otra mitad del Pilar 2 —*invocar tu propia muerte presenciada en una era anterior*— es inherentemente cross-era y se difiere al **Vertical Slice** (2 eras conectadas), donde ese loop realmente vive. Esto es coherente con la curva de onboarding del propio concepto ("las bendiciones aleatorias no se exponen hasta la 2ª partida").

> **Nota de scope (reconciliación cross-review 2026-08-18):** el requisito de "2-3 reliquias heredables" del MVP **no** significa invocar reliquias de héroes muertos en la misma era/pelea — `reliquias-bendiciones.md` Regla 10 prohíbe el drafteo intra-era (preserva el peso trágico: no draftear a quien murió hace 90s). El MVP prueba la *producción* de reliquias desde muertes presenciadas (in-era) y el *feel de invocación* (con panteón pre-sembrado) por separado; la unión de ambos —presenciar una muerte y usar esa reliquia más tarde— es la promesa del Vertical Slice.

**Explicitly NOT in MVP** (defer to later):
- Sistema multi-era / transición de legado entre civilizaciones (se prueba en Vertical Slice).
- Arte final pulido para más de una civilización.
- Cualquier funcionalidad multijugador o de comparación social de panteones.

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 civilización, 1 kaiju | Loop ritual→clímax + permadeath + legado básico (2-3 reliquias) | 3-4 meses |
| **Vertical Slice** | 2 civilizaciones/eras conectadas | + transición de legado entre eras | 2-3 meses adicionales |
| **Alpha** | 4-5 civilizaciones (todas las eras), arte placeholder en zonas nuevas | Todos los sistemas, panteón completo | 6-8 meses adicionales |
| **Full Vision** | Todo pulido, arte final, narrativa completa (15-21 meses, solo) | Todo + balance + polish | 4-6 meses adicionales |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine`)
- [ ] Create game pillars document (`/design-review` to validate)
- [ ] **Prototype core idea** (`/prototype [core-mechanic]`) — before writing GDDs, validate the concept is worth designing
- [ ] If prototype PROCEEDS: Decompose concept into systems (`/map-systems`)
- [ ] Design each system (`/design-system [system-name]`) — use prototype learnings in Tuning Knobs and Formulas sections
- [ ] Build vertical slice in Pre-Production (`/vertical-slice`) — validate full game loop before committing to Production
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
