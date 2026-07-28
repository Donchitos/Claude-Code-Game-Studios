# Asset Specs — Character: Mochi (Young stage, 5 Base Mood sprites)

> **Source**: `design/art/art-bible.md` §5.2 (Evolution Stages — Young row) + §5.3 (Base Mood States, stage-agnostic pose language)
> **Cross-referenced**: `design/gdd/pet-leveling-evolution.md` (L2/L3 = Young stage, no visual difference between L2 and L3), `design/gdd/pet-state-machine.md` (frame/fps/Loop table — reused unchanged from Baby, timing is mood-based not stage-based), `design/assets/specs/mochi-baby-mood-sprites.md` (structural precedent for this spec)
> **Art Bible**: design/art/art-bible.md
> **Generated**: 2026-07-18
> **Status**: 5 assets specced / 0 approved / 0 in production / 0 done
> **Scope note**: Young stage only (112dp), 5 Base Mood states only — mirrors the Baby stage batch exactly in mood coverage. Grown stage and the 5 Triggered states (LEVELING_UP, EXCITED, PLEASED, SHOWING_OFF, BOUNCING) remain deferred to future `/asset-spec` runs.

---

## Decisions made during this asset-spec run (2026-07-18)

Writing this spec required resolving two real open questions the Art Bible left unlocked — both resolved by explicit user decision, not silently:

1. **Young stage's 3rd color-zone accent** (Art Bible §5.2 only offered "e.g., small heart or star fold" as an example, not a locked choice): **decided — a small heart-shaped chest fold, fixed Petal Pink `#FFB5C8`, identical across all 5 moods**, treated as a static identity marking (like the belly patch) rather than a mood signal. Chosen over a star because (a) a star's pointed silhouette conflicts with §3's round-over-sharp rule once rounded enough to comply, it stops reading as a star; (b) Honey Gold already owns "achievement/reward" semantics via the LEVELING_UP glow (§5.4) — a permanent star-shaped marking would visually pre-empt that payoff moment.
2. **Ear continuity risk between Baby and Young** (both now use the same long-teardrop primitive per the 2026-07-15 Baby amendment, differing only by posture): **decided — Young's ears get a visibly stronger taper toward the tip**, a real silhouette difference (not just angle), so the two stages remain distinguishable even in a static, unlabeled 48×48px thumbnail with no animation to sell the distinction. Documented as an amendment to `art-bible.md` §5.2 (2026-07-18 note), not applied only in the generation prompts.

**Interpretation flagged, not a new decision needed**: since Young's *neutral/default* ear posture is already "lift/perk forward" per §5.2 (unlike Baby, where neutral = droop), this spec maps mood → ear angle as an escalating gradient from that new baseline (CONTENT = baseline lift, HAPPY = full perk past baseline, TIRED = asymmetric partial regression, SAD = full symmetric flatten, SLEEPING = full tuck). This keeps §5.3's mood poses (written generically across all 3 stages) non-contradictory at Young stage specifically.

**Open item for the delivered-art review pass** (not blocking this spec): confirm the heart-fold chest marking stays visibly readable across all 5 poses, especially TIRED's shoulder squash and SAD's flattened lie-down — flagged by art-director, to verify once art is generated, not decided here.

---

## Frame/fps/Loop Table (unchanged from Baby — reused verbatim, timing is mood-based not stage-based)

| Mood | Sprite ID | Frames | fps | stepTime | Loop |
|---|---|---|---|---|---|
| HAPPY | `happy_idle` | 4 | 2fps | 0.5s/frame | 2s |
| CONTENT | `content_idle` | 3 | 1fps | 1.0s/frame | 3s |
| TIRED | `tired_idle` | 3 | 0.75fps | 1.333s/frame | 4s |
| SAD | `sad_idle` | 2 | 0.4fps | 2.5s/frame | 5s |
| SLEEPING | `sleep_idle` | 2 | ~0.33fps | 3.0s/frame | 6s |

Verified against `pet-state-machine.md`'s canonical (already-corrected) table — no new defect found; this table is identical to Baby's.

---

## Shared Production Notes (apply to all 5 assets)

- **Native display size**: 112dp (Art Bible §5.2 — CONFIRMED FINAL).
- **Source export**: 3x baseline → **336×336px canvas per frame** (112 × 3, same convention as Baby's 216px = 72 × 3).
- **Padding convention** (reverse-engineered from Baby's delivered sheet dimensions, ≥2px transparent padding between frames and at sheet edges): `paddedWidth = N×336 + (N+1)×2`, `paddedHeight = 336 + 4`. Per-mood padded sheet sizes:

| Mood | Frames (N) | Padded sheet size |
|---|---|---|
| HAPPY | 4 | 1354×340px |
| CONTENT | 3 | 1016×340px |
| TIRED | 3 | 1016×340px |
| SAD | 2 | 678×340px |
| SLEEPING | 2 | 678×340px |

- **Color zones**: exactly 3 flat zones — body (mood tint) + belly patch (fixed Cream Ivory `#FFFDF0`) + heart-fold (fixed Petal Pink `#FFB5C8`) — per Art Bible §5.2 Young row. No gradients, one flat drop shadow only (§5.7).
- **Eyes**: ~35% of face height (down from Baby's ~40% — §5.2's "first subtle sign of growing up").
- **Silhouette**: slightly elongated oval (more oval than Baby's near-sphere), tiny stub-limb hints at the body's base — barely-visible rounded bumps, no defined limbs/joints/fingers.
- **Ears**: long teardrop shape (same length as Baby), visibly tapered/narrower toward the tip (2026-07-18 amendment — real silhouette difference from Baby's uniform-width teardrop, not just posture), rounded tip retained (no pointed tip, round-over-sharp rule).
- **Tail**: small fluffy poof (visibly poofier than Baby's tiny nub) — first "growing" cue per §5.2.
- **Outline**: same fixed ~2-3dp-equivalent, warm dark brown `#3D2B1F`, drawn at ~6-9px in the 336px source canvas (dp-equivalent target, not a proportional scale-up from Baby's stroke — confirmed by technical-artist, this is a density convention not a size convention).
- **Format**: PNG, 8-bit RGBA, transparent background, non-premultiplied alpha, lossless export (pngquant/tinypng-class lossless-quality pass acceptable for ship size) — identical policy to Baby.
- **Filenames**: `mochi_young_happy_idle.png`, `mochi_young_content_idle.png`, `mochi_young_tired_idle.png`, `mochi_young_sad_idle.png`, `mochi_young_sleep_idle.png`.
- **Flame architecture**: renders through the same single `MochiComponent` as Baby (`SpriteAnimationGroupComponent<MoodState>`) — evolution stage swap changes which preloaded `SpriteAnimation` is active, adds **zero** new draw calls (`pet-room-screen-ui.md` Formula 1 fixes `drawCalls_mochiBase = 1` regardless of mood or stage).
- **Engine note (Flame 1.37)**: the `SpriteBatch(bleed:)` fix doesn't directly apply to `MochiComponent`'s sub-rect `SpriteAnimation` sampling path — the ≥2px padding convention above remains the correct defense against sampling bleed for this component type (per `docs/engine-reference/flutter-flame/current-best-practices.md`).
- **Performance budget**: this 5-asset Young batch ≈ 6.15MB (~4.1% of the 150MB ceiling). Combined with Baby's ≈2.57MB (padded-accurate recompute), running total ≈ **8.72MB (~5.8% of 150MB)** — no concern. Forward flag (informational only, not this batch's scope): adding Grown later brings the 3-stage total to ≈20MB (~13%); the real future budget risk is `pet-equipment.md`'s per-stage overlay variants scaling with shop content volume, not the fixed 3 evolution stages.
- **Open implementation question flagged for `flame-specialist`** (not decided here): preload all 3 stages' mood sheets at boot via `images.loadAll()`, or lazy-load per stage during the 3s LEVELING_UP animation? Either is viable at these memory numbers.

---

## ASSET-006 — Mochi Young · HAPPY

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_young_happy_idle.png` |
| Sheet | 4 frames, horizontal strip, 1354×340px @3x source (336×336px/frame + padding) |
| Frame timing | 4 frames @ 2fps, stepTime 0.5s/frame, Loop 2s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Slightly elongated oval body (more oval than Baby's near-sphere), tiny stub-limb hints at the body's base, Mint Breeze `#A8E6CF` body tint, fixed Cream Ivory belly patch, fixed Petal Pink heart-fold on the upper chest. Both tapered teardrop ears fully perked forward — past Young's neutral baseline lift — with an alternating left-right wiggle each bounce cycle, tapered tips flicking visibly during the wiggle. Eyes ~35% of face height, wide open, one small white sparkle highlight each. Open smiling mouth. Poofier tail up with a gentle sway. Cheek blush at its most saturated across the 5-mood set. Frame content mirrors Baby's beat structure: rest(ears at full-perk-center) → rise(ears left, tips flick) → peak-bounce(ears center/up, taper most visible) → fall(ears right) — vertical bob + ear-wiggle + tail-sway all baked into frames per the single-component architecture constraint.

**Art Bible Anchors**: §5.3 HAPPY pose spec · §5.2 Young stage row (112dp, oval silhouette, stub-limb hints, tapered perked ears, 3 color zones, ~35% eyes) · §4 Color System (Mint Breeze = energy/nature, Petal Pink = joy/friendship) · §3 Shape Language (hero oval silhouette, ≥30% ear trait, round-over-sharp) · §5.1 (tail as secondary growth marker) · §5.6 Expressive-to-Exaggerated · §5.7 LOD budget (3-zone cap for Young).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft rice-cake creature, Young evolution stage,
slightly elongated oval body (more oval than a perfect sphere), tiny subtle stub-limb
hint bumps at the base of the body (barely visible, no defined limbs), 112dp scale test,
flat vector illustration, 2D mobile game sprite, Supercell (MO.CO) mobile game art style
blended with Kirby roundness and Jigglypuff-level silhouette softness, thick clean
outline 2-3px stroke color #3D2B1F, exactly 3 flat color zones (body + belly patch +
small heart-shaped chest fold marking), no gradients, no soft shading except one simple
flat drop shadow beneath the character

pose: HAPPY state, mid-bounce (peak of a light vertical bob, not a full jump), both long
teardrop-shaped ears fully perked up and forward (past their relaxed resting lift),
ears show a pronounced soft taper toward the rounded tip (visibly narrower near the tip
than the base — a real silhouette difference, still fully rounded, no pointed tip), one
ear tilted mid-wiggle with the tapered tip visibly flicking, oversized round eyes (~35%
of face height) with one small white sparkle highlight dot each, open smiling mouth
(small open oval curve), saturated pink blush circles on cheeks, small fluffy poof tail
(fuller/rounder than a tiny nub) raised with a gentle sway

color palette (strict): body fill Mint Breeze #A8E6CF, belly patch Cream Ivory #FFFDF0
(fixed, same hex every mood), heart-shaped chest fold Petal Pink #FFB5C8 (fixed, same
hex every mood, small size ~10-15% of body width, centered on upper chest above belly
patch), cheek blush Petal Pink #FFB5C8, outline and eye pupils warm dark brown #3D2B1F,
eye highlight Cloud White #FFFFFF

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft ambient lighting, no directional harsh light,
sticker/icon style, clean silhouette readable at 48x48px thumbnail, heart-fold marking
must remain visible in this pose

--no sharp corners, no pointed ear tips, no full arms/legs, no hands, no fingers, no
visible joints or articulation (stub-limb hints must stay as barely-visible bumps, not
defined limbs), no pure black #000000, no pure red #FF0000, no neon colors, no
photorealistic fur or skin texture, no realistic animal anatomy, no rabbit/cat/dog
species markers, no gradient shading, no busy or detailed background, no star-shaped
marking (heart only), no multiple small details that vanish at small size, no aggressive
expression, no fangs, no realistic muscle deformation, no full jump/leap pose (reserved
for EXCITED), no drooping/passive ear posture (that's Baby stage or this stage's TIRED/SAD),
no uniform-width ear (must show visible taper, distinct from Baby's ear silhouette)
```

**Status**: Needed

---

## ASSET-007 — Mochi Young · CONTENT

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_young_content_idle.png` |
| Sheet | 3 frames, horizontal strip, 1016×340px @3x source (336×336px/frame + padding) |
| Frame timing | 3 frames @ 1fps, stepTime 1.0s/frame, Loop 3s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: This is Young's neutral/default pose, so the ears sit at the stage's baseline forward-lift (~30-40°) established in §5.2 — noticeably more upright than Baby's passive droop, but clearly less lifted/animated than this stage's own HAPPY perk. Slightly elongated oval body, Peach Glow `#FFCBA4` tint, fixed Cream Ivory belly patch, fixed Petal Pink heart-fold. Slow steady breathing pulse on the body only — ears and tail stay still (mirrors Baby's rule that CONTENT's ears don't move, only the body breathes). Calm medium-open eyes (~35% face height) with soft lower-lid curve. Closed-mouth gentle smile line. Moderate/muted cheek blush. Fluffy tail resting still. Frame content: eyes-open/rest → mid-inflate → eyes-closed(blink, breath peak) — ears and tail pixel-identical across all 3 frames.

**Art Bible Anchors**: §5.3 CONTENT pose spec · §5.2 Young stage row (baseline forward-lift ear posture — interpreted as the neutral state per this spec's mood-to-ear-angle gradient) · §4 Color System (Peach Glow = warmth/reward) · §1 P3 Expressive Animation · §5.7 LOD budget.

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft rice-cake creature, Young evolution stage,
slightly elongated oval body, tiny subtle stub-limb hint bumps at the base of the body
(barely visible, no defined limbs), 112dp scale test, flat vector illustration, 2D mobile
game sprite, Supercell (MO.CO) mobile game art style blended with Kirby roundness and
Jigglypuff-level silhouette softness, thick clean outline 2-3px stroke color #3D2B1F,
exactly 3 flat color zones (body + belly patch + small heart-shaped chest fold marking),
no gradients, no soft shading except one simple flat drop shadow beneath the character

pose: CONTENT state, default idle/rest pose for this evolution stage, relaxed neutral
stance, mid-point of a slow gentle breathing pulse (body only, not stretched or
squashed), both long teardrop-shaped ears at their stage-default forward lift angle
(roughly 30-40 degrees forward from vertical — clearly more upright/alert than a
drooping posture, but clearly less lifted than a fully perked "happy" angle), ears show
a pronounced soft taper toward the rounded tip, held still (not wiggling), calm
medium-open round eyes (~35% of face height) with soft natural lower-lid curve,
closed-mouth gentle smile line (soft upward curve, mouth not open), light pink cheek
blush at moderate saturation, small fluffy poof tail resting flat and still

color palette (strict): body fill Peach Glow #FFCBA4, belly patch Cream Ivory #FFFDF0
(fixed, same hex every mood), heart-shaped chest fold Petal Pink #FFB5C8 (fixed, same
hex every mood), cheek blush Petal Pink #FFB5C8 at reduced/muted saturation, outline and
eye pupils warm dark brown #3D2B1F

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft ambient lighting, no directional harsh light,
sticker/icon style, clean silhouette readable at 48x48px thumbnail, must read as
"pleasant and content", not blank or emotionless, heart-fold marking must remain visible

--no sharp corners, no pointed ear tips, no full arms/legs, no hands, no fingers, no
visible joints or articulation, no pure black #000000, no pure red #FF0000, no neon
colors, no photorealistic fur or skin texture, no realistic animal anatomy, no gradient
shading, no busy or detailed background, no vacant/blank stare expression, no open mouth,
no ears fully perked forward (that's this stage's HAPPY), no ears drooping/flat (that's
TIRED/SAD), no star-shaped marking (heart only), no uniform-width ear (must show visible
taper)
```

**Status**: Needed

---

## ASSET-008 — Mochi Young · TIRED

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_young_tired_idle.png` |
| Sheet | 3 frames, horizontal strip, 1016×340px @3x source (336×336px/frame + padding) |
| Frame timing | 3 frames @ 0.75fps, stepTime 1.333s/frame, Loop 4s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Oval body with visible upper-body/shoulder compression (~10% vertical squash, same rule as Baby), pale desaturated Lavender Soft tint, fixed Cream Ivory belly patch, fixed Petal Pink heart-fold. Asymmetric ears — required, deliberate: one ear regresses fully to a Baby-like full droop (losing the alert lift entirely), the other holds at the CONTENT baseline lift (~30-40°) — reads as "fighting to stay awake" against Young's different neutral baseline. Mid-yawn beat: wide open oval mouth, eyes squeezed fully shut. Little to no cheek blush. Tail low, motionless. Frame content: idle-slump → yawn-mid → yawn-peak(eyes squeezed shut) — squash and ear asymmetry baked into all 3 frames.

**Art Bible Anchors**: §5.3 TIRED pose spec (asymmetric ears mandatory, ~10% shoulder squash) · §5.2 Young stage row (tapered ears, applied to the droop/half-up asymmetry) · §4 Color System (pale Lavender Soft, low-energy) · §2 Mood & Atmosphere (no dark vignette/harsh shadow) · §5.3's explicit SAD-distinction rule.

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft rice-cake creature with visible slump, Young
evolution stage, slightly elongated oval body, tiny subtle stub-limb hint bumps at the
base of the body (barely visible, no defined limbs), 112dp scale test, flat vector
illustration, 2D mobile game sprite, Supercell (MO.CO) mobile game art style blended
with Kirby roundness and Jigglypuff-level silhouette softness, thick clean outline 2-3px
stroke color #3D2B1F, exactly 3 flat color zones (body + belly patch + small heart-shaped
chest fold marking), no gradients, no soft shading except one simple flat drop shadow
beneath the character

pose: TIRED state, upper body and shoulder area visibly compressed/slumped (~10%
vertical squash), still fully round/oval overall silhouette, mid-yawn beat: mouth wide
open oval shape, eyes squeezed fully shut, ASYMMETRIC ears — one long teardrop ear fully
drooped down against the side of the head (losing its usual forward lift entirely), the
other ear held at a moderate ~30-40 degree forward angle (its normal relaxed lift, now
reading as "half-up" by contrast with the fully drooped one) — this asymmetry is a
required, deliberate detail, do not make both ears match or both droop equally, both
ears show a pronounced soft taper toward the rounded tip, small fluffy poof tail low and
motionless

color palette (strict): body fill pale desaturated Lavender Soft (base #C5A3E0,
lightened/desaturated ~30%, cool but not dark), belly patch Cream Ivory #FFFDF0 (fixed,
same hex every mood), heart-shaped chest fold Petal Pink #FFB5C8 (fixed, same hex every
mood), outline and eye lines warm dark brown #3D2B1F, no blush or very faint blush only

composition: single character, centered, front-3/4 view, isolated on plain transparent
background, square 1:1 canvas, soft even ambient lighting, no dark vignette, no harsh
directional shadow, gentle cozy mood despite low energy, sticker/icon style, clean
silhouette readable at 48x48px thumbnail, heart-fold marking must remain visible

--no sharp corners, no pointed ear tips, no full arms/legs, no hands, no fingers, no
visible joints or articulation, no pure black #000000, no pure red #FF0000, no neon
colors, no photorealistic fur or skin texture, no realistic animal anatomy, no gradient
shading, no busy or detailed background, no both-ears-symmetrically-drooped, no
both-ears-matching-angle, no dark vignette, no harsh shadow, no sad/crying face (that's
SAD state), no fully flat lying-down body (that's SAD state, TIRED stays more upright),
no star-shaped marking (heart only), no uniform-width ear (must show visible taper)
```

**Status**: Needed

---

## ASSET-009 — Mochi Young · SAD

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_young_sad_idle.png` |
| Sheet | 2 frames, horizontal strip, 678×340px @3x source (336×336px/frame + padding) |
| Frame timing | 2 frames @ 0.4fps, stepTime 2.5s/frame, Loop 5s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Body lies down flat/low — silhouette noticeably flatter than TIRED's upright slump (same required distinguishing rule as Baby). Lavender Soft `#C5A3E0` tint (cool desaturated, never darkened), fixed Cream Ivory belly patch, fixed Petal Pink heart-fold (still visible, unchanged in color — it's an identity marking, not a mood cue, so its cheerful pink hue persists even here by design). Both tapered teardrop ears fully flattened against the head, symmetrically — the full regression from Young's alert-forward default, further than TIRED's one-sided droop. Large round downturned sad eyes; optional single small static teardrop (one only). Small downward mouth curve. Tail pressed to body, motionless. Must read as "come play with me," never as punishment/shame. Frame content: rest-exhale → rest-inhale-nhẹ (very subtle breathing) — silhouette and flat ears baked identically into both frames.

**Art Bible Anchors**: §5.3 SAD pose spec · §2 Mood & Atmosphere overarching rule (invitation, not punishment) · §4 Color System (Lavender Soft desaturate, never black/grey) · §1 global rule (never pure #FF0000/#000000) · §5.2 (ear flatten as the full regression from stage-default lift).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft rice-cake creature, low flattened body lying down,
Young evolution stage, slightly elongated oval body, tiny subtle stub-limb hint bumps at
the base of the body (barely visible, no defined limbs), 112dp scale test, flat vector
illustration, 2D mobile game sprite, Supercell (MO.CO) mobile game art style blended
with Kirby roundness and Jigglypuff-level silhouette softness, thick clean outline 2-3px
stroke color #3D2B1F, exactly 3 flat color zones (body + belly patch + small heart-shaped
chest fold marking), no gradients, no soft shading except one simple flat drop shadow
beneath the character

pose: SAD state, body lying down flat and low, silhouette noticeably flatter and wider
than a "tired slump" pose, both long teardrop ears fully flattened pressed against the
back of the head symmetrically (a full regression from this stage's normal forward-lift
default — further collapsed than the TIRED state's one-sided droop), ears' pronounced
taper still visible even flattened, large round downturned sad eyes with outer corners
curving down, optional single small static teardrop shape at one eye's outer corner
(only one drop, no streaming tears), small downward-curving mouth line (gentle sadness,
not exaggerated crying), small fluffy poof tail pressed against the body, motionless

color palette (strict): body fill Lavender Soft #C5A3E0 (cool desaturated tint, NOT
darkened, NOT grayscale/black), belly patch Cream Ivory #FFFDF0 (fixed, same hex every
mood), heart-shaped chest fold Petal Pink #FFB5C8 (fixed, same hex every mood —
unchanged even in this low-mood state, since this marking is a static identity feature,
not an emotion cue), outline and eye lines warm dark brown #3D2B1F, optional teardrop in
soft Cloud White #FFFFFF / pale blue-gray, no cheek blush

composition: single character, centered, low/ground-level framing to emphasize the lying
pose, isolated on plain transparent background, square 1:1 canvas, soft warm ambient
lighting, cozy and inviting mood despite sadness ("come play with me", not visual failure
or shame), no dark vignette, no harsh shadow, sticker/icon style, clean silhouette
readable at 48x48px thumbnail, heart-fold marking must remain visible even in this
flattened pose

--no sharp corners, no pointed ear tips, no full arms/legs, no hands, no fingers, no
visible joints or articulation, no pure black #000000, no pure red #FF0000, no neon
colors, no photorealistic fur or skin texture, no realistic animal anatomy, no gradient
shading, no busy or detailed background, no dark vignette, no harsh directional shadow,
no fully desaturated grayscale rendering, no streaming/multiple tears, no exaggerated
crying/wailing mouth, no upright slumped pose (that's TIRED, keep SAD clearly flatter/
lower), no asymmetric ears (SAD ears are both flat, symmetric), no star-shaped marking
(heart only), no uniform-width ear (must show visible taper)
```

**Status**: Needed

---

## ASSET-010 — Mochi Young · SLEEPING

| Field | Value |
|---|---|
| Category | Sprite / 2D Art |
| Filename | `mochi_young_sleep_idle.png` |
| Sheet | 2 frames, horizontal strip, 678×340px @3x source (336×336px/frame + padding) |
| Frame timing | 2 frames @ ~0.33fps, stepTime 3.0s/frame, Loop 6s |
| Format | PNG, RGBA, transparent bg |

**Visual Description**: Tightest, roundest silhouette of all 5 Young moods — the elongated oval collapses into a compact curl. Faded/pale Cloud White tint, fixed Cream Ivory belly patch with intentionally low contrast, fixed Petal Pink heart-fold (kept just visible enough to confirm identity, low-contrast pastel treatment consistent with the rest of the palette here). Both tapered ears tucked fully against the body; fluffy tail wraps in/tucks. Eyes fully closed — two flat horizontal lines. Neutral/closed mouth. Outline stays fully visible against the pale fill (same highest-contrast-risk flag as Baby's SLEEPING asset — test at 48×48px before final approval). Zzz particle is out of scope for this sprite (separate VFX scope). Frame content: breathe-out(smallest curl) → breathe-in(largest curl — biggest-amplitude, slowest motion of the Young set).

**Art Bible Anchors**: §5.3 SLEEPING pose spec (tightest/roundest pose, largest-amplitude slowest breathing) · §4 Color System (faded Cloud White) · §5.7 LOD (outline stays visible regardless of fill paleness) · §3 Shape Language (48×48px readability test, highest-risk asset) · §5.2 (ears/tail tuck as the terminal end of the mood-to-ear-angle gradient).

**Generation Prompt**:
```
chibi mascot character, "Mochi", soft rice-cake creature, tightest most-curled-up round
silhouette of the whole Young-stage character set, Young evolution stage, compact curled
oval (collapsing from the stage's normal slightly-elongated oval shape), tiny subtle
stub-limb hint bumps at the base of the body if still visible in the curled pose
(otherwise may be tucked away, barely visible either way), 112dp scale test, flat vector
illustration, 2D mobile game sprite, Supercell (MO.CO) mobile game art style blended with
Kirby roundness and Jigglypuff-level silhouette softness, thick clean outline 2-3px
stroke color #3D2B1F (outline must remain visible even against a pale body fill for
silhouette readability), exactly 3 flat color zones (body + belly patch + small
heart-shaped chest fold marking, all kept low-contrast/pale in this state), no gradients,
no soft shading except one simple flat drop shadow beneath the character

pose: SLEEPING state, curled into the tightest and roundest shape of all mood states at
this evolution stage, both long teardrop ears tucked in fully against the body (barely
visible, absorbed into the silhouette), small fluffy poof tail tucked/wrapped in, eyes
fully closed as two flat straight horizontal lines with zero pupil/iris detail, mouth
neutral/closed or omitted, calm peaceful expression, no visible tension

color palette (strict): body fill faded pale Cloud White (base #FFFFFF blended very
lightly with a hint of body warmth so it stays distinguishable from a pure white
background), belly patch subtle Cream Ivory #FFFDF0 with low contrast (fixed, same hex
every mood), heart-shaped chest fold subtle pale Petal Pink #FFB5C8 kept at low contrast
consistent with this state's faded palette (fixed hue, same as every other mood, just
rendered pale here — still distinguishable as a heart shape, not fully lost), outline
warm dark brown #3D2B1F kept fully visible for silhouette clarity, no cheek blush

composition: single character, centered, compact curled silhouette, isolated on plain
transparent background, square 1:1 canvas, soft dim warm ambient lighting suggesting
nighttime coziness (not dark/harsh), sticker/icon style, clean silhouette readable at
48x48px thumbnail even at low body-fill contrast

--no sharp corners, no pointed ear tips, no full arms/legs, no hands, no fingers, no
visible joints or articulation, no pure black #000000, no pure red #FF0000, no neon
colors, no photorealistic fur or skin texture, no realistic animal anatomy, no gradient
shading, no busy or detailed background, no dark vignette, no harsh shadow, no visible
pupils or iris under closed eyes, no open or half-open eyes, no visible ears poking out
from the silhouette, no elongated/uncurled body pose, no bright saturated color fill
(must read as faded/pale), no star-shaped marking (heart only)
```

**Status**: Needed

---

## Next Steps

1. Generate the 5 sprite sheets via `ppgen` (PerfectPixel Studio's CLI) using the prompts above — expect the same need for spec-compliance post-processing Baby required (frame count trims, color-zone quantization to exact hex, resolution fit) rather than a raw first-pass accept.
2. Run `/asset-audit` once assets are delivered, to validate them against this spec.
3. Conduct the same **emotional-fidelity playtest** required for Baby (Production gate-check exit-criteria #5) — confirm each Young mood is independently identifiable without a text/color hint, and additionally confirm Young is distinguishable from Baby at a glance (the ear-taper amendment's actual goal).
4. Grown stage (152dp) and the 5 Triggered-state animations remain deferred to future `/asset-spec` runs.
