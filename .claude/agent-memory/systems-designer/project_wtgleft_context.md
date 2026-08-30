---
name: project-wtgleft-context
description: Core facts about "What the Gods Left Behind" (Godot 4.6 RTS/roguelite) — pillars, GDD set, and cross-system coupling notes relevant to systems design work
metadata:
  type: project
---

The project is "What the Gods Left Behind" — a Godot 4.6 RTS/roguelite. Core pillars:
1. Sacrificio con Peso — permadeath must be truly irreversible, no reload-to-undo.
2. El Pasado es Poder — legacy/pantheon (forged relics, era history) must survive between sessions.
3. Preparación Ritual, Clímax Explosivo — pacing alternates safe prep beats and combat climax beats.
4. Historia Jugada, No Contada — story emerges from play, not exposition.

GDDs authored so far (design/gdd/): game-concept.md, input.md, datos-de-era-civilizacion.md,
systems-index.md, guardado-persistencia.md (Guardado/Persistencia — Foundation layer, save system).

**Why:** These pillars are the arbitration standard for every systems-design tradeoff on this
project — e.g., save/retry failure handling must never silently let a permadeath event go
unpersisted (violates Pillar 1 from a different angle: a crash before a successful autosave
would let a dead hero reappear on reload).

**How to apply:** When designing any new formula or rule for this project, check it against
these four pillars before proposing defaults. Re-read the specific GDD for exact wording rather
than trusting this summary, since pillars phrasing may be refined over time.

Known cross-system coupling note: the Input GDD (`design/gdd/input.md`) defines a `DEATH_HOLD`
input context (all player input suppressed during the permadeath beat) but deliberately does
NOT define its duration — that's owned by a not-yet-authored Permadeath GDD. The
Guardado/Persistencia GDD already specifies that the mandatory autosave on hero death must
complete (blocking) *before* `DEATH_HOLD` is released, so `DEATH_HOLD`'s minimum duration is
implicitly save-write-time + whatever pacing buffer the Permadeath GDD authors want — no
separate timing formula is needed to couple them, sequencing already guarantees it.
