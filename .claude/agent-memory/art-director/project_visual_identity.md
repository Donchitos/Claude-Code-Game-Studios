---
name: project-visual-identity
description: Core visual direction facts for "The Last Seal" (voxel colony-builder) — warmth-contrast rule, art bible status, large-world scope change
metadata:
  type: project
---

**Game**: "The Last Seal" — Godot 4.7 voxel colony-builder + squad tactics.
`design/art/visual-direction-note.md` (approved 2026-07-09) is the interim
visual anchor; it is explicitly NOT the art bible. Full art bible
(`design/art/art-bible.md`, Sections 1-4 Visual Identity Foundation) is
required at the Technical Setup → Pre-Production gate and, as of 2026-07-11,
**does not exist yet**.

Core rule (One-Line Visual Rule): a built, lived-in space must always read
warmer/more alive than anything threatening it. Supporting principles:
warm-light-as-reward (interiors/fixtures warm+saturated, terrain cool-neutral
muted), classic blocky Minecraft-reference shape language (flush blocks, no
gaps, hard edges, readability via texture/AO not bevels), stakes-as-weather
(threats intrude via cool rim-light/fog on the threat's approach vector,
settlement's own warm lights get locally brighter — not a palette swap).
Color language: 3 hue families never mixed — Material (earthy neutrals,
recedes), Function (warm gold/amber, marks interactive fixtures), State
(reserved blue-orange axis, UI/overlay only, never on static geometry).
State axis is blue-orange (not red-green) for colorblind safety, and every
state color must pair with shape/icon/label (day-one rule, not deferred).

**Why:** This note was written under a ~100×32×100 "small hand-shaped valley"
framing (readable in one continuous frame, no distant-view/fog/biome
concerns). On 2026-07-11 the world scope changed to a large world (target
2000×2000×32, min 1000×1000) for exploration + distant dungeons
(ADR-0014, chunked/face-culled mesher, streamed view window ~380m radius,
per-height-band vertex colors in the prototype) — see
`docs/architecture/adr-0014-chunked-voxel-rendering-large-world.md`.
ADR-0003 (GridMap) is superseded by ADR-0014 for this reason.

**How to apply:** Do not treat the visual-direction-note's principles as
automatically valid at the new scale. Distant-view readability (does the
warmth-contrast rule still read at streaming distance / through fog?),
fog/horizon treatment (unaddressed in the note — needed for large-world
depth cueing), biome variation across a 2km world + distant dungeons
(the note assumes one continuous warm-neutral valley palette), and a color
mapping for per-height-band vertex coloring are all open gaps the art bible
must resolve, not just restate the note. The note's philosophy (warmth
contrast, blocky shapes, 3-hue-family system, colorblind pairing) remains
directionally sound and should carry forward, extended rather than rewritten.
See [[gate-verdict-history]] for the 2026-07-11 AD-PHASE-GATE verdict.

**Update 2026-07-11 (re-review):** `design/art/art-bible.md` Sections 1-4
now exist, are APPROVED, and close all four gaps above (hex table in §4.1,
per-height-band table §4.3, biome list §4.4, fog/horizon plan §2.6, Horizon
Test principle §1.4). Verdict was CONCERNS not READY/NOT-READY — one
open defect: §2.4/§2.6 fog color reuses the "State Blue" hue (§4.1's
"safe/positive" UI signal) for world-space dungeon-approach/leaving-home
fog, which is semantically backwards and contradicts §4.6's own colorblind
backup-mechanism claim ("State color never appears on world terrain").
Needs a rename (distinct "Threshold Cool" hue) before Deep Threshold /
dungeon-approach assets are built. Sections 5-9 (Character Design,
Environment Language, UI/HUD Visual Direction, Asset Standards, Style
Prohibitions) remain deferred to Pre-Production — this was accepted as
in-scope for this gate. Full detail in [[gate-verdict-history]].
