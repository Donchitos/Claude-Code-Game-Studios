# Settings Guidance — which value to recommend, and when

The **advisory** layer for project settings. This doc answers two questions no
other doc does:

1. **Which value should a skill recommend** for a given project or user?
2. **When should a skill proactively suggest changing** a setting already set?

## Boundary with its siblings — do not duplicate their content here

| Doc | Answers | Nature |
|---|---|---|
| `effects-map.md` | What each setting *does* | Descriptive |
| `config-resolution.md` | How a setting *resolves* (precedence chain) | Mechanical |
| **`settings-guidance.md`** (this file) | Which value to *recommend*, and *when* | Prescriptive |

Skills reference this doc **on demand**, only at a "recommend a setting" moment.
It is deliberately **not** a CLAUDE.md import — advisory content must not ride in
per-turn context (the same reason `context-management.md` was demoted).

---

## 1. The knob that matters most: `modes.rigor`

Almost every "what settings should I use?" question reduces to one choice:
`modes.rigor` (`minimal` | `standard` | `full`, default `minimal`). It fronts six
sub-knobs — `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode`, `team.size`. Recommend **rigor**, not the six; let the
expansion do the rest. Full expansion table lives in `effects-map.md § modes.rigor`
— do not restate it here.

`modes.automation` (`collaborative` | `guided` | `autonomous`) is a **separate
axis** — how often skills stop to confirm — and is *not* fronted by rigor. Pick it
by working style, not by game type (see § 5).

---

## 2. Archetype → rigor presets

Match the project to an archetype; recommend the paired rigor. These are starting
points, not verdicts — the user can always override.

| Archetype | Rigor | Why | Common override |
|---|---|---|---|
| Weekend jam / prototype / throwaway | `minimal` | Shipping beats recording; design lives in the maker's head | Bump one deep system: `workflow_overrides.system_overrides: {combat: full}` |
| Small solo / hobby game (arcade, puzzle, short narrative) | `minimal` → `standard` if it grows | Start light; add rigor when scope proves real | — |
| Focused commercial indie (platformer, roguelike, tactics, deckbuilder) | `standard` | One well-understood loop; enough design to build correctly | "Comprehensive but compact": `rigor: full` + `docs.density: terse` |
| Systems-heavy / long-haul (open-world RPG, colony sim, immersive sim, 4X, survival) | `full` | Many interacting systems; a design mistake costs weeks | Solo dev: keep `full` on disk, set `review_mode: solo` locally |
| Live-service / competitive multiplayer | `full` + domain emphasis | Full pipeline *plus* netcode/security/live-ops | Raise `qa.level` / `testing.strict.*` for the online-critical types |

**The model:** the table picks a baseline; overrides handle the diagonal. Most real
projects are one baseline plus one or two deliberate exceptions.

---

## 3. Seeding rigor from a described concept

When the user has described their game (e.g. `/start` Phase 2 free text), map it to
an archetype and **pre-select** the recommendation rather than asking cold. Signals:

| Concept mentions… | Lean toward |
|---|---|
| open-world, RPG, sim, sandbox, faction, crafting, economy, MMO, multiplayer, "systems" | `full` |
| jam, weekend, prototype, "first game", small, "just trying", experiment | `minimal` |
| "release", "commercial", "on Steam", a single clear core loop | `standard` |
| *ambiguous / nothing above* | `minimal` (the documented default) |

**Rules:** these are heuristics, never locks. Always confirm the pre-selection with
the user in their own terms ("Sounds like a big systems game — I'd suggest `full`
rigor; want that?"). If the user has **no concept yet** (exploring), do not seed
`full` — default `minimal`, and revisit once a concept exists.

"No concept yet" means **no signal**, not a particular onboarding path. A rough
one-line hint is still a description: if it trips the signals above, seed from the
signal. Only fall back to `minimal`-for-exploring when the user has given you
nothing to map. (`/start` Phase 3d states the same rule for its Path A/B branch —
the two must agree, since both drive the identical recommendation.)

---

## 4. When to recommend a *change* (adaptive triggers)

Bidirectional and **threshold-based**. Fire only on a threshold *crossing*, never
every session — that is what keeps this from becoming the nagging the `automation`
modes exist to eliminate.

| Trigger (crossing) | Direction | Detectable signal | Suggested action |
|---|---|---|---|
| Project grew past its band | ↑ raise | System-GDD count crosses ~9, or the code root (`src/`, `Assets/` or `Source/`) crosses the Production threshold, while rigor is `minimal` | "You're at N systems on `rigor: minimal` — most projects this size run `standard`. Revisit? → `/settings`" |
| Stage advanced into Production | ↑ raise | `/gate-check` PASS into Production while rigor is `minimal` | Same, offered once at the gate |
| User sounds overwhelmed by process | ↓ lower | Phrases like "too many steps", "so much documentation", "overwhelmed" — *and* rigor is not already `minimal` | "If the required-doc list feels heavy, a lower rigor trims it → `/settings modes.rigor=standard`" |
| Chosen rigor mismatches described scope | flag once | Onboarding pick contradicts the Phase-2 description | State it in one sentence, offer `/settings`, do not re-ask |

**Frequency guard:** the crossing *is* the gate. Because the hosts (`/gate-check` on
PASS, `/help` on request) are themselves infrequent, no persistent "already nudged"
state is needed — but never emit the same suggestion twice in one session.

---

## 5. Which skills reference this doc, and when

| Skill | Moment | Sections used |
|---|---|---|
| `/start` | Phase 3d/4 — choosing rigor | § 2 (presets), § 3 (seed from concept) |
| `/help` | escalation footer when user sounds stuck/overwhelmed | § 4 (lower trigger) |
| `/gate-check` | on PASS into a new stage | § 4 (raise trigger) |
| `/settings` | view output — further reading | § 2 (choosing a value) |

Each skill carries a **one-line pointer** to this doc, not a copy of its tables.

---

## 6. How to phrase a recommendation

- **Recommend, don't dictate.** State the suggestion and the reason in one line;
  the user decides. (`collaborative`/`guided` require this; even `autonomous`
  treats a rigor change as a `schema_changes` decision and asks.)
- **Always route to `/settings`** — never edit `project.yaml` as a side effect of a
  recommendation.
- **One line, then stop.** A nudge is a nudge, not a lecture.
