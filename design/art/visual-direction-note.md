# Visual Direction Note: The Last Seal (Voxel)

> **Status**: Approved (user-reviewed 2026-07-09)
> **Created**: 2026-07-09
> **Scope**: Lightweight anchor for Systems Design phase. NOT the art bible
> (full art bible is produced at Technical Setup → Pre-Production).
> **Owner**: art-director | **Referenced by**: Voxel World (#2), Building System (#6),
> Building UI (#10), Villager Info UI (#11), Combat/Wave UI (#25)

---

## 1. The One-Line Visual Rule

> **A built, lived-in space must always read visually warmer and more alive
> than anything threatening it.**

Test any visual decision against this: does the settlement win the warmth
contrast, even mid-wave? If a threat effect, UI color, or lighting choice
makes danger look warmer/cozier than home, or makes a finished home look as
cold/plain as raw terrain, it's off-model. This anchors both the core fantasy
(pride = a plain plot becoming warm and furnished) and Pillar 3 (cozy is the
resting state; stakes visit, they don't overwrite it).

## 2. Supporting Principles

**a) Warm-light-as-reward.** Key/interior light skews warm (golden-hour
amber, not neutral white); ambient/exterior/terrain light stays a cooler,
desaturated neutral. Built structures and their light sources (hearth,
windows, lanterns) are deliberately the warmest, most saturated things in any
frame — they should visually "pop" against the valley. Terrain/sky in muted
warm-neutrals (soft ochre, moss); interiors/fixtures push warmer and more
saturated as build quality increases — warmth becomes the visual reward
signal for building well, not just object count.

**b) Classic blocky shape language — Minecraft as the reference.**
*(User decision 2026-07-09: flush blocks, no inter-block gap; Minecraft is
the explicit shape-language reference.)* Blocks fill their full cell (render
size = cell size 1.0 — the building prototype's 0.96 "voxel gap" is dropped)
and sit flush against each other, forming continuous surfaces the way
Minecraft structures do. Edges stay hard and square — no bevels/chamfers.
Block and edge readability at orbit-camera distance comes from **texture,
per-face shading, and ambient occlusion in the corners**, not from physical
gaps. Silhouettes stay simple and blocky; the "handmade" warmth comes from
the palette and lighting (2a), not from rounding the forms.

**c) Stakes as weather, not a skin swap.** Waves/dungeons/seal-threat should
intrude on the palette rather than replace it: cool rim-light and desaturated
fog creeping in from the threat's approach vector, while the settlement's own
warm light sources get *locally brighter/more prominent* during the
encounter — a beacon-in-the-dark read, not a genre-shift into a different
visual game. This is the concrete answer to "what does cozy look like when
threatened": home doesn't change color, the world around it does.

## 3. Material ↔ Meaning Color Language

Three hue families, never mixed, so no system designer invents ad-hoc hue
coding (the building prototype's grey/brown/red-brown/blue was placeholder,
not a rule):

| Hue Family | Meaning | Examples | Behavior |
|---|---|---|---|
| **Material** (earthy, desaturated neutrals) | Raw structure — walls/floor/roof | wood=warm brown, stone=cool grey, thatch=warm red-brown | Recedes; differentiate by material type via value/texture, not saturation |
| **Function** (warm gold/amber accent) | Fixtures that carry function (bed, table, hearth, door — the Unique Hook) | consistent gold trim/glow tell | Always visually distinct from plain structure — "this block does something" |
| **State** (reserved blue–orange axis) | Mood, needs, danger, wave alert, seal integrity — UI/overlay only | never used in material palette | Exclusive to feedback layer; paired per Section 4 |

Rule: Material color never carries gameplay state, and State color never
appears on static geometry — this keeps materials and feedback from being
visually confused as the systems scale.

## 4. Colorblind-Safe Encoding Rule (day-one, not Full Vision)

**No gameplay-critical state — mood, need, danger, wave alert, seal
integrity, build-menu material category — may be conveyed by hue alone.**
Every state color must be paired with a shape, icon, pattern, or label that
survives grayscale. The state axis is **blue–orange** (user-approved) rather
than red–green — safer for the most common colorblind types; "danger" reads
orange rather than conventional red. Building UI, Villager Info UI, and
Combat/Wave UI GDDs must specify the icon/shape pairing alongside any color
in their own docs — this note only sets the rule, not the icon set.

---

*Next: authored per-system palettes (exact hex values, material swatch sheet)
belong in the future art bible, not here. This note exists to keep Voxel
World, Building System, and the MVP/VS UI GDDs internally consistent until
then.*
