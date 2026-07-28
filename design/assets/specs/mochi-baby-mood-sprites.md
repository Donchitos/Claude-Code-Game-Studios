# Asset Specs — Character: Mochi (Baby stage, 5 Base Mood sprites)

> **Source**: `design/art/art-bible.md` §5 (Character Design Direction — no dedicated `design/narrative/characters/` profile exists; Art Bible §5 is the authoritative character source for this run)
> **Cross-referenced**: `design/gdd/pet-state-machine.md` (Visual/Audio Requirements, State Definitions), `design/gdd/pet-room-screen-ui.md` (Formula 1 — draw-call budget)
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-07-14
> **Status**: 5 assets specced / 5 approved / 0 in production / 0 done
> **Scope note**: Baby stage only (72dp), 5 Base Mood states only. Young/Grown stages and the 5 Triggered states (LEVELING_UP, EXCITED, PLEASED, SHOWING_OFF, BOUNCING) are deferred to a future `/asset-spec character:mochi` run — this batch is scoped to satisfy Production gate-check exit-criteria #5 ("real Mochi art for 5 moods + emotional-fidelity playtest before Pet Room screen implementation").

---

## Corrections applied during this asset-spec run (2026-07-14)

Writing this spec surfaced one real defect and two ambiguities in existing Approved docs — all resolved by explicit user decision, not silently:

1. **`pet-state-machine.md` fps/Loop mismatch (real defect, fixed)**: the Visual/Audio Requirements table's `fps` values, combined with `frames` count, produced actual loop durations 3–18× faster than the State Definitions table's `Loop` column (e.g. SLEEPING computed to 0.33s instead of the specified 6s). This would have made SAD/SLEEPING flicker quickly instead of reading as "near-motionless"/"deep sleep" per Art Bible §5.3 — breaking the P3 text-off test. **Fixed**: `fps` recalculated to match the existing `Loop` values (`frames` unchanged). See `pet-state-machine.md`'s correction note.
2. **Art Bible §5.7 outline-density ambiguity (clarified)**: "2-3px absolute" was ambiguous between literal raw-pixel-in-source-file vs. dp-equivalent-after-density-export. Resolved: 2-3px is a **dp-equivalent** target — source art at 3x export density draws the outline at ~6-9px so it downscales to the correct ~2-3dp on screen. See Art Bible §5.7's correction note.
3. **`sleep_idle` naming**: kept as-is (not `sleeping_idle`) — confirmed as an intentional shorthand, not a typo, no change needed.
4. **Zzz particle (SLEEPING)**: out of scope for this batch — it's a VFX particle effect, not a character sprite. To be specced separately when the owning system (likely `flame-shader-specialist` domain) is scoped.

---

## Corrected Sprite/Loop Table (for reference — canonical version lives in `pet-state-machine.md`)

| State | Sprite ID | Frames | fps (corrected) | stepTime | Loop |
|---|---|---|---|---|---|
| HAPPY | `happy_idle` | 4 | 2fps | 0.5s/frame | 2s |
| CONTENT | `content_idle` | 3 | 1fps | 1.0s/frame | 3s |
| TIRED | `tired_idle` | 3 | 0.75fps | 1.333s/frame | 4s |
| SAD | `sad_idle` | 2 | 0.4fps | 2.5s/frame | 5s |
| SLEEPING | `sleep_idle` | 2 | ~0.33fps | 3.0s/frame | 6s |

---

## Shared Production Notes (apply to all 5 assets)

- **Native display size**: 72dp (Art Bible §5.2 — CONFIRMED FINAL, this is also the render ceiling per `pet-room-screen-ui.md`'s fixed max-scale=1.0 rule).
- **Source export**: author at 3x baseline (216×216px canvas per frame) — Flame's `Images`/`Sprite.load()` does not auto-select density variants the way Flutter's `AssetImage` does, so there is no `2.0x/`/`3.0x/` folder convention here; ship one file per mood at 216px and let Flame downscale to the 72dp display size.
- **Outline**: ~2-3dp equivalent on screen → ~6-9px drawn in the 216px source file (see Correction #2 above).
- **Color zones**: ≤2 flat zones (body + belly patch), no gradients, one simple flat drop shadow only (Art Bible §5.7).
- **Belly patch color**: fixed **Cream Ivory `#FFFDF0`** across all 5 moods (only the main body zone carries the mood tint) — keeps a consistent "neutral anchor" so Mochi reads as the same character across mood changes.
- **Outline/pupil color**: warm dark brown `#3D2B1F` (never pure black, per Art Bible §4/§1 global rule).
- **Format**: PNG, 8-bit RGBA, transparent background (required — `MochiComponent` must be visible through to the Pet Room background per `pet-room-screen-ui.md` Core Rule 1's z-order). Non-premultiplied alpha. Lossless export; a lossless-quality compression pass (e.g. pngquant/tinypng with clean alpha edges) is acceptable for ship size.
- **Sheet layout**: one PNG per mood, horizontal strip of N frames (N per table above), ≥2px transparent padding between frames and around the sheet edge (avoids sampling bleed — relevant to Flame 1.37's SpriteBatch bleed fix per `docs/engine-reference/flutter-flame/VERSION.md`).
- **Flame architecture**: all 5 moods render through a **single** `MochiComponent` (e.g. `SpriteAnimationGroupComponent<MoodState>`), preloaded via `images.loadAll([...])` in `onLoad()`, switching the active `SpriteAnimation` on mood change. This is a **hard architectural constraint**, not a preference — `pet-room-screen-ui.md` Formula 1 fixes `drawCalls_mochiBase = 1` regardless of mood, so mood changes must never create/destroy components or add draw calls.
- **Atlas packing**: not needed yet at Baby-only scope (5 frames × 216² × 4 bytes ≈ 2MB, ~1.3% of the 150MB RAM budget). Flagged as a future optimization once Young/Grown stages + equipment overlays are added and texture count grows.
- **Performance budget check**: texture memory ~2MB (~1.3% of 150MB ceiling); draw calls: 5 moods share the fixed `drawCalls_mochiBase = 1` (0.5% of the 200/frame ceiling). Neither axis is at risk from this batch.

---

## ASSET-001 — Mochi Baby · HAPPY

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_baby_happy_idle.png` |
| Sheet | 4 frames, horizontal strip, 864×216px @3x source (216×216px/frame) + padding |
| Frame timing | 4 frames @ 2fps, stepTime 0.5s/frame, Loop 2s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Near-perfect sphere body, Mint Breeze `#A8E6CF` main body tint, small oval Cream Ivory `#FFFDF0` belly patch. Both stub ears standing up and angled slightly forward, one ear mid-wiggle. Oversized eyes (~40% face height) with a small white sparkle highlight each. Open smiling mouth. Cheek blush (Petal Pink `#FFB5C8`) at its most saturated across the whole 5-asset set. Frame content: rest(ears center) → rise(ears left) → peak-bounce(ears center/up) → fall(ears right) — vertical bob and ear-wiggle both baked into the frames (required by the single-component architecture constraint).

**Art Bible Anchors**: §5.3 HAPPY pose spec · §4 Color System (Mint Breeze = energy/nature, Petal Pink = joy/friendship) · §3 Shape Language (hero circular silhouette, ≥30% ear trait) · §5.2 Baby stage (72dp, 2 color zones, largest eyes of the 3 stages) · §5.6 Expressive-to-Exaggerated · §5.7 LOD budget.

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft round rice-cake creature, near-perfect sphere body,
Baby evolution stage, 72dp scale test, flat vector illustration, 2D mobile game sprite,
Supercell (MO.CO) mobile game art style blended with Kirby roundness and Jigglypuff-level
silhouette softness, thick clean outline 2-3px stroke color #3D2B1F, exactly 2 flat color
zones (body + small belly patch), no gradients, no soft shading except one simple flat
drop shadow beneath the character

pose: HAPPY state, mid-bounce (peak of a light vertical bob, not a full jump), both short
rounded stub-ears standing up and angled slightly forward, one ear tilted mid-wiggle,
oversized round eyes (~40% of face height) with one small white sparkle highlight dot each,
open smiling mouth (small open oval curve), saturated pink blush circles on cheeks,
tiny closed tail nub raised slightly

color palette (strict): body fill Mint Breeze #A8E6CF, belly patch Cream Ivory #FFFDF0,
cheek blush Petal Pink #FFB5C8, outline and eye pupils warm dark brown #3D2B1F,
eye highlight Cloud White #FFFFFF

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft ambient lighting, no directional harsh light,
sticker/icon style, clean silhouette readable at 48x48px thumbnail

--no sharp corners, no pointed ears, no visible limbs, arms, legs, hands, fingers,
no visible joints or articulation, no pure black #000000, no pure red #FF0000,
no neon colors, no photorealistic fur or skin texture, no realistic animal anatomy,
no rabbit/cat/dog species markers, no gradient shading, no busy or detailed background,
no multiple small details that vanish at small size, no aggressive expression,
no fangs, no realistic muscle deformation, no full jump/leap pose (reserved for EXCITED)
```

**Status**: Needed

---

## ASSET-002 — Mochi Baby · CONTENT

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_baby_content_idle.png` |
| Sheet | 3 frames, horizontal strip, 648×216px @3x source + padding |
| Frame timing | 3 frames @ 1fps, stepTime 1.0s/frame, Loop 3s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Sphere body, Peach Glow `#FFCBA4` tint, Cream Ivory belly patch. Default/most-seen state — must read as pleasant, not blank. Mid-point of a slow breathing pulse, relaxed neutral stance. Ears at relaxed neutral droop (not perked like HAPPY, not flat like TIRED/SAD). Calm medium-open eyes, soft natural lower-lid curve. Closed-mouth gentle smile line. Moderate/muted cheek blush (lighter than HAPPY). Tail resting still. Frame content: eyes-open/rest → mid-inflate → eyes-closed(blink, breath peak) — ears pixel-identical across all 3 frames (they stay still; only the body breathes).

**Art Bible Anchors**: §5.3 CONTENT pose spec · §4 Color System (Peach Glow = warmth/reward) · §1 P3 Expressive Animation (default state must still read via body language) · §5.7 LOD budget.

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft round rice-cake creature, near-perfect sphere body,
Baby evolution stage, 72dp scale test, flat vector illustration, 2D mobile game sprite,
Supercell (MO.CO) mobile game art style blended with Kirby roundness and Jigglypuff-level
silhouette softness, thick clean outline 2-3px stroke color #3D2B1F, exactly 2 flat color
zones (body + small belly patch), no gradients, no soft shading except one simple flat
drop shadow beneath the character

pose: CONTENT state, default idle/rest pose, relaxed neutral stance, mid-point of a slow
gentle breathing pulse (body only, not stretched or squashed), both short rounded
stub-ears at relaxed neutral droop angle (not perked up, not flattened down), calm
medium-open round eyes with soft natural lower-lid curve, closed-mouth gentle smile line
(soft upward curve, mouth not open), light pink cheek blush at moderate saturation
(lighter than HAPPY), tiny closed tail nub resting flat and still

color palette (strict): body fill Peach Glow #FFCBA4, belly patch Cream Ivory #FFFDF0,
cheek blush Petal Pink #FFB5C8 at reduced/muted saturation, outline and eye pupils
warm dark brown #3D2B1F

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft ambient lighting, no directional harsh light,
sticker/icon style, clean silhouette readable at 48x48px thumbnail, must read as
"pleasant and content", not blank or emotionless

--no sharp corners, no pointed ears, no visible limbs, arms, legs, hands, fingers,
no visible joints or articulation, no pure black #000000, no pure red #FF0000,
no neon colors, no photorealistic fur or skin texture, no realistic animal anatomy,
no gradient shading, no busy or detailed background, no vacant/blank stare expression,
no open mouth, no ears fully perked (that's HAPPY), no ears drooping/flat (that's TIRED/SAD)
```

**Status**: Needed

---

## ASSET-003 — Mochi Baby · TIRED

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_baby_tired_idle.png` |
| Sheet | 3 frames, horizontal strip, 648×216px @3x source + padding |
| Frame timing | 3 frames @ 0.75fps, stepTime 1.333s/frame, Loop 4s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Sphere body with visible upper-body/shoulder compression (~10% vertical squash), still fully round overall. Pale desaturated Lavender Soft tint (lighter than SAD's), Cream Ivory belly patch. **Asymmetric ears — required, deliberate detail**: one ear fully drooped flat against the head, the other only half-raised (~45°) — never draw both ears matching. Mid-yawn beat: wide open oval mouth, eyes squeezed fully shut. Little to no cheek blush. Tail low, motionless. Frame content: idle-slump → yawn-mid → yawn-peak(eyes squeezed shut) — squash baked into all 3 frames.

**Art Bible Anchors**: §5.3 TIRED pose spec (asymmetric ears mandatory, ~10% shoulder squash, periodic yawn) · §4 Color System (pale Lavender Soft for low-energy) · §2 Mood & Atmosphere (no dark vignette/harsh shadow even at low energy) · §5.3's explicit distinction from SAD ("still upright slump", not flattened).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft round rice-cake creature, sphere body with visible
slump, Baby evolution stage, 72dp scale test, flat vector illustration, 2D mobile game
sprite, Supercell (MO.CO) mobile game art style blended with Kirby roundness and
Jigglypuff-level silhouette softness, thick clean outline 2-3px stroke color #3D2B1F,
exactly 2 flat color zones (body + small belly patch), no gradients, no soft shading
except one simple flat drop shadow beneath the character

pose: TIRED state, upper body and shoulder area visibly compressed/slumped (~10%
vertical squash), still fully round overall silhouette, mid-yawn beat: mouth wide open
oval shape, eyes squeezed fully shut (closed curved lines, not just droopy), ASYMMETRIC
ears — one ear fully drooped down flat against the side of the head, the other ear only
half-raised at roughly 45 degrees (this asymmetry is a required, deliberate detail,
do not make both ears match), tiny closed tail nub low and motionless

color palette (strict): body fill pale desaturated Lavender Soft (base #C5A3E0, lightened/
desaturated ~30%, cool but not dark), belly patch Cream Ivory #FFFDF0, outline and eye
lines warm dark brown #3D2B1F, no blush or very faint blush only

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft even ambient lighting, no dark vignette, no harsh
directional shadow, gentle cozy mood despite low energy, sticker/icon style, clean
silhouette readable at 48x48px thumbnail

--no sharp corners, no pointed ears, no visible limbs, arms, legs, hands, fingers,
no visible joints or articulation, no pure black #000000, no pure red #FF0000,
no neon colors, no photorealistic fur or skin texture, no realistic animal anatomy,
no gradient shading, no busy or detailed background, no both-ears-symmetrically-drooped,
no dark vignette, no harsh shadow, no sad/crying face (that's SAD state), no fully flat
lying-down body (that's SAD state, TIRED stays more upright)
```

**Status**: Needed

---

## ASSET-004 — Mochi Baby · SAD

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_baby_sad_idle.png` |
| Sheet | 2 frames, horizontal strip, 432×216px @3x source + padding |
| Frame timing | 2 frames @ 0.4fps, stepTime 2.5s/frame, Loop 5s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Body lying down flat/low — silhouette noticeably flatter than TIRED's upright slump (required distinguishing detail between the two low-energy states). Lavender Soft `#C5A3E0` tint (cool desaturated, never darkened/greyscale), Cream Ivory belly patch. Both ears fully flattened against the head, symmetrically (unlike TIRED's asymmetry). Large round downturned sad eyes; optional single small static teardrop (one only, never streaming). Small downward mouth curve — gentle sadness, not exaggerated crying. Tail pressed to body, motionless. Must read as "come play with me," never as visual punishment/shame — no darkened tint, no vignette. Frame content: rest-exhale → rest-inhale-nhẹ (very subtle breathing) — silhouette, flat ears, and any teardrop baked identically into both frames.

**Art Bible Anchors**: §5.3 SAD pose spec · §2 Mood & Atmosphere overarching rule ("mood change is invitation, not punishment" — no darkened tint, no vignette) · §4 Color System (Lavender Soft desaturate, never black/grey) · §1 global rule (never pure #FF0000/#000000).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft round rice-cake creature, low flattened body lying
down, Baby evolution stage, 72dp scale test, flat vector illustration, 2D mobile game
sprite, Supercell (MO.CO) mobile game art style blended with Kirby roundness and
Jigglypuff-level silhouette softness, thick clean outline 2-3px stroke color #3D2B1F,
exactly 2 flat color zones (body + small belly patch), no gradients, no soft shading
except one simple flat drop shadow beneath the character

pose: SAD state, body lying down flat and low, silhouette noticeably flatter and wider
than a "tired slump" pose (clearly more flattened than an upright compressed stance),
both ears fully flattened pressed against the back of the head symmetrically (not just
drooping — fully flat), large round downturned sad eyes with outer corners curving down,
optional single small static teardrop shape at one eye's outer corner (only one drop, no
streaming tears), small downward-curving mouth line (gentle sadness, not exaggerated
crying face), tiny closed tail nub pressed against the body, motionless

color palette (strict): body fill Lavender Soft #C5A3E0 (cool desaturated tint, NOT
darkened, NOT grayscale/black), belly patch Cream Ivory #FFFDF0, outline and eye lines
warm dark brown #3D2B1F, optional teardrop in soft Cloud White #FFFFFF / pale blue-gray,
no cheek blush

composition: single character, centered, low/ground-level framing to emphasize the lying
pose, isolated on plain transparent background, square 1:1 canvas, soft warm ambient
lighting, cozy and inviting mood despite sadness ("come play with me", not visual failure
or shame), no dark vignette, no harsh shadow, sticker/icon style, clean silhouette
readable at 48x48px thumbnail

--no sharp corners, no pointed ears, no visible limbs, arms, legs, hands, fingers,
no visible joints or articulation, no pure black #000000, no pure red #FF0000,
no neon colors, no photorealistic fur or skin texture, no realistic animal anatomy,
no gradient shading, no busy or detailed background, no dark vignette, no harsh
directional shadow, no fully desaturated grayscale rendering, no streaming/multiple
tears, no exaggerated crying/wailing mouth, no upright slumped pose (that's TIRED,
keep SAD clearly flatter/lower), no asymmetric ears (SAD ears are both flat, symmetric)
```

**Status**: Needed

---

## ASSET-005 — Mochi Baby · SLEEPING

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_baby_sleep_idle.png` |
| Sheet | 2 frames, horizontal strip, 432×216px @3x source + padding |
| Frame timing | 2 frames @ ~0.33fps, stepTime 3.0s/frame, Loop 6s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Tightest, roundest silhouette of all 5 moods — near-perfect compact sphere. Faded/pale Cloud White tint (blended lightly with body warmth to stay distinguishable from the Cream Ivory background), Cream Ivory belly patch with intentionally low contrast. Both ears tucked fully against the body (barely visible); tail nub tucked in or omitted at this scale. Eyes fully closed — two flat straight horizontal lines, zero pupil/iris detail. Neutral/closed or omitted mouth. Outline must remain fully visible against the pale fill for silhouette clarity at 48×48px (this asset carries the highest contrast risk of the set — test the silhouette at thumbnail size before final approval, per Art Bible §3's mandatory readability test). Zzz particle is NOT part of this sprite (separate VFX scope, see Corrections section). Frame content: breathe-out(smallest curl) → breathe-in(largest curl — the biggest-amplitude, slowest motion of the whole 5-mood set).

**Art Bible Anchors**: §5.3 SLEEPING pose spec (tightest/roundest pose, largest-amplitude slowest breathing) · §4 Color System (faded Cloud White) · §5.7 LOD (outline stays fully visible regardless of how pale the fill is) · §3 Shape Language (48×48px readability test — flagged as highest-risk asset for this requirement).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft round rice-cake creature, tightest most-curled-up
round silhouette of the whole character set, near-perfect compact sphere, Baby evolution
stage, 72dp scale test, flat vector illustration, 2D mobile game sprite, Supercell (MO.CO)
mobile game art style blended with Kirby roundness and Jigglypuff-level silhouette
softness, thick clean outline 2-3px stroke color #3D2B1F (outline must remain visible
even against a pale body fill for silhouette readability), exactly 2 flat color zones
(body + subtle belly patch), no gradients, no soft shading except one simple flat drop
shadow beneath the character

pose: SLEEPING state, curled into the tightest and roundest shape of all mood states,
both stub-ears tucked in fully against the body (barely visible, absorbed into the
silhouette), tiny tail nub tucked in if visible at all (may be omitted entirely at this
scale), eyes fully closed as two flat straight horizontal lines with zero pupil/iris
detail, mouth neutral/closed or omitted, calm peaceful expression, no visible tension

color palette (strict): body fill faded pale Cloud White (base #FFFFFF blended very
lightly with a hint of body warmth so it stays distinguishable from a pure white
background), belly patch subtle Cream Ivory #FFFDF0 with low contrast, outline warm dark
brown #3D2B1F kept fully visible for silhouette clarity, no cheek blush

composition: single character, centered, compact curled silhouette, isolated on plain
transparent background, square 1:1 canvas, soft dim warm ambient lighting suggesting
nighttime coziness (not dark/harsh), sticker/icon style, clean silhouette readable at
48x48px thumbnail even at low body-fill contrast

--no sharp corners, no pointed ears, no visible limbs, arms, legs, hands, fingers,
no visible joints or articulation, no pure black #000000, no pure red #FF0000,
no neon colors, no photorealistic fur or skin texture, no realistic animal anatomy,
no gradient shading, no busy or detailed background, no dark vignette, no harsh shadow,
no visible pupils or iris under closed eyes, no open or half-open eyes, no visible ears
poking out from the silhouette, no elongated/uncurled body pose, no bright saturated
color fill (must read as faded/pale)
```

**Status**: Needed

---

## Next Steps

1. Produce the 5 sprite sheets (via commissioned artist or AI image generation using the prompts above — each generation prompt still requires human review/cleanup to guarantee frame-to-frame consistency and exact palette hex matches, since AI image tools do not reliably hit exact hex values or maintain perfect character consistency across separate generations).
2. Run `/asset-audit` once assets are delivered, to validate them against this spec.
3. Conduct the **emotional-fidelity playtest** required by Production gate-check exit-criteria #5: show the 5 delivered sprites (without labels) to a test audience matching the target age range (~6-10yo) and confirm each mood is independently identifiable without a text/color hint — this is the concrete test version of Art Bible P3 ("turn off UI text — can you still tell how Mochi feels?").
4. Only after the emotional-fidelity check passes: proceed to Pet Room screen implementation (per gate-check exit-criteria #5's explicit ordering).
