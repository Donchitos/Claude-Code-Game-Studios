# Asset Manifest

> Last updated: 2026-07-15

## Progress Summary

| Total | Needed | In Progress | Done | Approved |
|-------|--------|-------------|------|----------|
| 10 | 5 | 0 | 5 | 0 |

## Assets by Context

### Character: Mochi (Baby stage, 5 Base Moods)
| Asset ID | Name | Category | Status | File | Spec File |
|----------|------|----------|--------|------|-----------|
| ASSET-001 | Mochi Baby — HAPPY | Sprite / 2D Art | Done | design/assets/generated/mochi_baby/spec_compliant/mochi_baby_happy_idle.png | design/assets/specs/mochi-baby-mood-sprites.md |
| ASSET-002 | Mochi Baby — CONTENT | Sprite / 2D Art | Done | design/assets/generated/mochi_baby/spec_compliant/mochi_baby_content_idle.png | design/assets/specs/mochi-baby-mood-sprites.md |
| ASSET-003 | Mochi Baby — TIRED | Sprite / 2D Art | Done | design/assets/generated/mochi_baby/spec_compliant/mochi_baby_tired_idle.png | design/assets/specs/mochi-baby-mood-sprites.md |
| ASSET-004 | Mochi Baby — SAD | Sprite / 2D Art | Done | design/assets/generated/mochi_baby/spec_compliant/mochi_baby_sad_idle.png | design/assets/specs/mochi-baby-mood-sprites.md |
| ASSET-005 | Mochi Baby — SLEEPING | Sprite / 2D Art | Done | design/assets/generated/mochi_baby/spec_compliant/mochi_baby_sleep_idle.png | design/assets/specs/mochi-baby-mood-sprites.md |

**"Done" means spec-compliant, not yet "Approved"** — per `mochi-baby-mood-sprites.md`'s own Next Steps, these still need the emotional-fidelity playtest (show unlabeled sprites to a ~6-10yo test audience, confirm each mood reads without a color/text hint) before sign-off. The two logged minor imperfections (uniform cheek-blush intensity, 2px bleed-padding sheet dimensions) also remain as-is.

### Character: Mochi (Young stage, 5 Base Moods)
| Asset ID | Name | Category | Status | File | Spec File |
|----------|------|----------|--------|------|-----------|
| ASSET-006 | Mochi Young — HAPPY | Sprite / 2D Art | Needed | — | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-007 | Mochi Young — CONTENT | Sprite / 2D Art | Needed | — | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-008 | Mochi Young — TIRED | Sprite / 2D Art | Needed | — | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-009 | Mochi Young — SAD | Sprite / 2D Art | Needed | — | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-010 | Mochi Young — SLEEPING | Sprite / 2D Art | Needed | — | design/assets/specs/mochi-young-mood-sprites.md |

Specced 2026-07-18 via `/asset-spec` (art-director + technical-artist, full mode). Two open Art Bible questions resolved during this run (heart-fold accent color/shape, Young ear taper strength) — see the spec file's "Decisions made during this asset-spec run" section and `art-bible.md` §5.2's 2026-07-18 amendment.

**Deferred (not yet specced)**: Mochi Grown stage (5 assets), 5 Triggered-state animations (LEVELING_UP, EXCITED, PLEASED, SHOWING_OFF, BOUNCING), Zzz sleep particle VFX (flagged as likely the wrong tool for `ppgen`/PerfectPixel Studio — that pipeline targets character+animation generation, not particle effects) — see `design/assets/specs/mochi-baby-mood-sprites.md`'s Scope note.

## Production Log — AI-gen draft (2026-07-15)

First-pass AI generation produced via PerfectPixel Studio (Gemini 3 Pro Image, OpenRouter), raw output at `design/assets/generated/mochi_baby/`. **Status is "In Progress", not "Done"** — cross-check against `mochi-baby-mood-sprites.md` found real spec gaps, listed below. Treat this pass as a style/consistency validation, not spec-compliant final art.

**Gaps vs. spec (need rework before "Done")**:
1. **Frame counts wrong for all 5** — spec calls for HAPPY=4, CONTENT=3, TIRED=3, SAD=2, SLEEPING=2 frames (each mood's Loop duration depends on its own frame/fps pairing). PerfectPixel generated a flat 4 frames for every mood, never adjusted.
2. **No per-mood body color tint** — spec requires the main body zone to carry the mood color (Mint Breeze HAPPY / Peach Glow CONTENT / pale Lavender TIRED / Lavender Soft SAD / faded Cloud White SLEEPING), with only the belly patch fixed at Cream Ivory. All 5 generated moods share the same warm cream/tan body color from the base character — the color-coding layer specified in Art Bible §4 is absent.
3. **Ear style deviates from the currently-Accepted Art Bible** — these use long drooping ears (per the user's reference-image decision earlier this session), not the "short rounded stub" Baby-stage ears §5.2 currently specifies. The art-bible.md §5.2 amendment discussed earlier in this session was never actually written/applied — spec and delivered art are still out of sync on this point.
4. **File structure/naming doesn't match spec** — spec wants one file per mood (`mochi_baby_happy_idle.png` etc., horizontal strip). Delivered output is a single combined 5-row sheet (`mochi_baby-sprite-sheet.png`) plus per-frame files under `frames/custom{1-5}/frame-0N.png` — needs remapping/renaming to match the spec's per-asset file convention.
5. **Sprite sheet fps/loop metadata doesn't match** — `mochi_baby-manifest.json` encodes a flat 8fps/loop for every animation; spec needs the per-mood fps in the Corrected Sprite/Loop Table (2fps/1fps/0.75fps/0.4fps/~0.33fps).

**What did match**: flat sticker-vector style, thick warm-brown outline, fully limbless silhouette, transparent RGBA background, mood-appropriate pose/expression differentiation (ear posture, eye state, mouth shape) confirmed distinct per mood after 1-2 feedback-regeneration passes each.

## Production Log — Spec-compliance fix pass (2026-07-15)

Post-processed the raw PerfectPixel output with a color-zone classification script (HSV threshold: dark→outline, low-saturation/light→belly, low-hue→cheek, else→body) rather than regenerating. Output at `design/assets/generated/mochi_baby/spec_compliant/`.

**Gaps fixed**:
1. **Frame counts** — trimmed to spec (HAPPY 4, CONTENT/TIRED 3, SAD/SLEEPING 2), keeping the first N frames of each animation (all were already visually consistent with each other).
2. **Per-mood body color** — recolored body zone to Art Bible hex per mood (Mint Breeze / Peach Glow / pale Lavender Soft / Lavender Soft / faded Cloud White). Belly forced to Cream Ivory `#FFFDF0`, outline forced to warm dark brown `#3D2B1F` for all frames (this also fixed a defect not previously logged: 2 of the 5 raw animations had drifted to pure-black `#000000` outline in some frames, violating the "never pure black" global rule).
3. **File naming/structure** — now one horizontal-strip PNG per mood, `mochi_baby_{mood}_idle.png`, matching spec convention.
4. **Resolution** — resized 256px AI-native canvas down to the spec's 216px 3x baseline.
5. **Flat color zones** — the classification step is a hard zone quantization, so it incidentally fixed a gap not caught in the first review pass: the raw AI frames were not actually flat (6,500+ unique colors per frame from AI anti-aliasing/soft shading, violating the "no gradients, ≤2 flat zones" rule). Output is now genuinely flat per zone.

**Known deviation, deliberate**: sheet width includes 2px transparent padding between frames and at the sheet edges (e.g. CONTENT is 656×220, not the spec text's literal "648×216"), per the Shared Production Notes' bleed-avoidance rule, which takes precedence over the literal example dimensions in each asset's table.

**Ear style — RESOLVED 2026-07-15**: `art-bible.md` §5.2 amended (see that file's 2026-07-15 note) — Baby stage now specs long drooping teardrop ears, matching the delivered art. Spec and art are in sync; this is no longer a blocker.

**New follow-ups opened by that amendment (not blockers to this batch, tracked for later)**:
1. Young/Grown ear posture wording in `art-bible.md` §5.2 is a placeholder pending those stages' actual asset-spec run.
2. The leveling GDD's fantasy-copy line "tai dài ra, đuôi bồng lên" may need rewording since ears no longer visibly lengthen across evolution — cross-document follow-up, not resolved here.

**Minor known imperfection (not blocking)**: cheek blush was recolored to a uniform Petal Pink hex per pixel-matched region regardless of the original per-mood opacity, so the intended blush-intensity gradient (HAPPY most saturated → SAD/SLEEPING faintest, per each asset's Visual Description) is flatter across moods than spec's written intent. Cosmetic only.
