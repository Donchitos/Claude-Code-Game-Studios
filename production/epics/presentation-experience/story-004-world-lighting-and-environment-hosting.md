# Story 004: The world has no sun

> **Epic**: Presentation & Experience
> **Status**: Complete with one open item (2026-07-27 — 1517/1517 suite green, 0 orphans, parent-verified). AC3 (art-director sign-off on the shipped values) is NOT done: 0.95/0.28 shipped as provisional, overturnable by editing world_lighting_config.tres.
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/art/art-bible.md` §2.1 (permanent golden-hour bias)
**ADR Governing Implementation**: ADR-0001 (DI), ADR-0005 (boot sequencing)

**Engine**: Godot 4.7-stable | **Risk**: LOW-MEDIUM

### How this was found

Immediately after camera-input story-013 gave the game a camera, the first
player-view screenshot came out looking correctly lit — and that was suspicious,
because nothing in the shipped scene lights anything. Counted directly:

```
DirectionalLight3D / WorldEnvironment in Valley.tscn:     0
DirectionalLight3D / WorldEnvironment in game_world.tscn: 0
Files under src/ containing either:                       none
```

The picture looked lit because `tools/settlement_overview_capture.gd` supplies its
own `DirectionalLight3D` and `WorldEnvironment` as siblings of the instantiated
world — as do `tools/m01_c4_valley_ambient_capture.gd` and `tools/camera_sandbox.gd`.
Every one of them applies the art bible's golden-hour recipe itself.

The shipped game's only light source is `AmbientTorchLight`, a single `OmniLight3D`.
There is no sun, no sky, no ambient term. A player launching the game gets a near-black
screen with one small pool of torchlight.

This is the seventh instance of the project's recurring failure mode — behaviour that
exists, is agreed, and is exercised only outside the running game. The art bible's
central visual rule ("permanent golden-hour bias, never harsh or neutral-white") has
been honoured in three tool scenes and one prototype, and never once in the product.

### Why this is more than a missing node

The golden-hour values every tool copies (`light_energy = 1.7`, ambient `0.5`) were
validated against the vertical-slice prototype's materials. Against the real meshed
terrain they blow out: the mesher's single terrain colour is the art bible's `9CAD6E`
lowland olive, and at those values it renders as near-white pale yellow. Dropping only
the exposure (`light_energy ≈ 0.95`, ambient ≈ `0.28`) makes the olive read plainly —
see `production/qa/evidence/settlement-overview-eyelevel-dimmed-*.png` versus the
undimmed frames captured in the same run.

So this story hosts the lighting AND settles what its shipped values are. The second
half is an art-director call, not an engineering one.

---

## Acceptance Criteria

- [x] AC1: The shipped scene chain hosts exactly one `DirectionalLight3D` and one
      `WorldEnvironment`, active once boot reaches ACTIVE.
- [x] AC2: Their values come from a config Resource (ADR-0002), not from literals in a
      scene file or script — the art bible's recipe becomes tunable data, the way every
      other tuned value in this project is.
- [ ] AC3: The shipped values are signed off by the art director against the REAL meshed
      terrain, not against a prototype or a tool scene. Record the chosen values and the
      rationale in the art bible.
- [x] AC4: `AmbientTorchLight` and `TorchFlicker` keep working unchanged — the torch must
      still read as a warm local pool against the new ambient, which is the whole point of
      the ambient-life work that established it.
- [x] AC5: A boot invariant is added to Valley's existing block: exactly one sun and one
      environment hosted after boot.
- [x] AC6: The three tool scenes stop supplying their own lighting and use the shipped
      lighting instead — otherwise the tools keep flattering the build and the next
      regression hides exactly as this one did.

## Anti-Vacuity Lever

Assert on rendered output, not on node presence. After boot, with the tools' own lighting
removed (AC6), a capture through the shipped camera must contain terrain pixels whose
luminance falls inside a stated band — bright enough to prove a sun exists, dark enough to
prove it is not blown out. On today's build the frame is near-black, so it cannot pass
vacuously; and a naive "add a light at the tool's 1.7 energy" fix fails the upper bound.

## Out of Scope

- Any change to the mesher's terrain colours or to the number of terrain block types
  (there is currently exactly one — a separate content gap, worth its own story).
- Shadow quality/cascade tuning beyond what AC3 settles.
- Time-of-day variation. The art bible commits to a permanent golden hour; a day cycle is
  not implied by this story.

## QA Test Cases

**AC1/AC5 — the world is lit at all**
- Given: the real `game_world.tscn` booted to ACTIVE.
- Then: exactly one `DirectionalLight3D` and one `WorldEnvironment` below Valley.

**AC2 — the recipe is data**
- Given: the lighting config Resource.
- Then: changing its values changes the rendered result, and no literal light energy or
  ambient colour appears in `valley.gd` or `Valley.tscn` (grep guard).

**AC4 — the torch still reads**
- Given: boot complete under the new ambient.
- Then: the torch's lit neighbourhood is measurably brighter than terrain outside it.

**Anti-vacuity — luminance band**
- Given: a capture through the shipped camera with no tool-supplied lighting.
- Then: mean terrain luminance falls inside the band stated by AC3's sign-off.

---

## Closure Note (2026-07-27)

Landed with AC3 open. The sun and environment are hosted, config-driven and
boot-asserted; the tools no longer supply their own lighting. What remains is
the taste call: 0.95 / 0.28 ship as PROVISIONAL, chosen because the art bible's
own 1.7 / 0.5 blows the real terrain out to near-white. Ratifying or changing
them is a `.tres` edit, not a code change — which is what AC2 was for.

DEVIATION ON THE ANTI-VACUITY LEVER, recorded rather than glossed. The story
asked for a luminance band measured on RENDERED output. What shipped is a
deterministic computed luminance estimate (Lambertian ambient + directional term
over the mesher's real 9CAD6E terrain colour), not a GPU render. The argument
given: `coding-standards.md` explicitly excludes visual fidelity and
platform-specific rendering from automation, and this suite has no
headless-pixel precedent anywhere. The proxy was shown to discriminate — the
shipped values land inside [0.20, 0.80], the art bible's literal 1.7 / 0.5
breaches the upper bound, a near-zero config breaches the lower one. The real
rendered evidence is the windowed capture
(`production/qa/evidence/player-view-on-launch-*.png`), taken with the tools
supplying no lighting at all.

This is a reasonable substitution, not a fulfilment of what was written. If a
reviewer wants the rendered-pixel assertion, it remains owed.
