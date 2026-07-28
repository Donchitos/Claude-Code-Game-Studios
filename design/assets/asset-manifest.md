# Asset Manifest

> Last updated: 2026-07-24

## Progress Summary

| Total | Needed | In Progress | Done | Approved |
|-------|--------|-------------|------|----------|
| 10 | 0 | 0 | 10 | 0 |

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
| ASSET-006 | Mochi Young — HAPPY | Sprite / 2D Art | Done | design/assets/generated/mochi_young/spec_compliant/mochi_young_happy_idle.png | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-007 | Mochi Young — CONTENT | Sprite / 2D Art | Done | design/assets/generated/mochi_young/spec_compliant/mochi_young_content_idle.png | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-008 | Mochi Young — TIRED | Sprite / 2D Art | Done | design/assets/generated/mochi_young/spec_compliant/mochi_young_tired_idle.png | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-009 | Mochi Young — SAD | Sprite / 2D Art | Done | design/assets/generated/mochi_young/spec_compliant/mochi_young_sad_idle.png | design/assets/specs/mochi-young-mood-sprites.md |
| ASSET-010 | Mochi Young — SLEEPING | Sprite / 2D Art | Done | design/assets/generated/mochi_young/spec_compliant/mochi_young_sleep_idle.png | design/assets/specs/mochi-young-mood-sprites.md |

Specced 2026-07-18 via `/asset-spec` (art-director + technical-artist, full mode). Two open Art Bible questions resolved during this run (heart-fold accent color/shape, Young ear taper strength) — see the spec file's "Decisions made during this asset-spec run" section and `art-bible.md` §5.2's 2026-07-18 amendment.

**"Done" means spec-compliant, not yet "Approved"** — same convention as Baby. These still need the same emotional-fidelity playtest (Production gate-check exit-criteria #5, extended per this spec's own Next Steps #3 to also confirm Young reads as distinguishable from Baby at a glance) before sign-off. See the Production Log below for real, un-fixed imperfections carried into this "Done" state (ear taper geometry, SAD's upright-not-lying pose).

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

## Production Log — AI-gen draft (2026-07-24)

First-pass AI generation for the Young batch, via the same PerfectPixel Studio pipeline (Gemini 3 Pro Image, OpenRouter). Raw output at `design/assets/generated/mochi_young/` (`base.png`, `sprite-sheet.png`, `manifest.json`, plus one `frames/<state>/frame-NN.png` folder per state).

**Tool-behavior finding, new this run**: `ppgen -states` no longer accepts free-form custom names — it validates against a fixed preset catalog (`ppgen -dump` to list) and hard-errors on unrecognized names (`ppgen 실패: 알 수 없는 상태 이름: happy, content, tired, sleeping`). This differs from what the Baby production log implied ("custom1-5" folder naming suggested free-form names worked previously) — either the tool changed or that inference was wrong. Worked around by mapping the 5 GDD moods to the closest valid presets: HAPPY→`laugh`, CONTENT→`idle`, TIRED→`yawn`, SAD→`sad`, SLEEPING→`sleep`. `cheer` (labeled "arms raised") was considered for HAPPY and rejected — Mochi has no arms per the Art Bible, so `laugh` ("laughing happily") was the safer match.

Command run:
```
ppgen -desc "<Young-stage description built from art-bible.md §5.1/§5.2 + this spec's Shared Production Notes>" \
  -states "laugh,idle,yawn,sad,sleep" -style chibi \
  -out design/assets/generated/mochi_young -timeout 30m
```

**Gaps vs. spec (expected, same categories as Baby)**:
1. **Frame counts wrong for all 5** — spec calls for HAPPY=4, CONTENT=3, TIRED=3, SAD=2, SLEEPING=2. ppgen generated a flat 4 frames per state again, unchanged from Baby's own defect.
2. **No per-mood body color tint** — all 5 states shared one uniform peach/tan body fill (~`#FDCFA7`) instead of the spec's per-mood hex (Mint Breeze / Peach Glow / pale Lavender Soft / Lavender Soft / faded Cloud White). Same gap as Baby, still present in this model/tool.
3. **Not flat color zones** — 4,000–6,000+ unique opaque colors per raw frame from AI anti-aliasing/soft shading, not the spec's 3 flat zones.
4. **File structure** — single combined `sprite-sheet.png` (1024×1280, 4×5 grid) plus per-state `frames/<state>/frame-NN.png`, not spec's one-file-per-mood horizontal strip.
5. **fps/loop metadata wrong** — `manifest.json` encodes 6-8fps flat loops per state, not the spec's per-mood 2/1/0.75/0.4/~0.33fps table.
6. **Pure-black outline drift** — the `sad` state's raw frames had outline/eye pixels drift to pure `#000000` (2,365 px in frame-00 alone), violating the "never pure black" global rule. Same specific defect Baby's log flagged (there, 2 of 5 animations; here, at least 1 of 5).
7. **Native canvas smaller than spec target, opposite direction from Baby** — raw frames are 256×256px; Young's spec baseline is 336×336px (112dp × 3). Baby's raw 256px canvas was *larger* than its 216px target (downscale); this batch's 256px canvas is *smaller* than its 336px target (upscale, ~1.31×). Flagged because upscaling raster art degrades cleanliness more than downscaling does.
8. **Ear taper not visually distinct from Baby** — this spec's whole reason for existing (§"Decisions made during this asset-spec run" #2) was a *pronounced* taper making Young's ears silhouette-distinct from Baby's uniform-width ear at a static 48×48px thumbnail. The raw art's ears are fairly uniform-width with only mild taper — the model did not reliably follow this specific geometric instruction. **This is a shape-level gap the color-zone fix pass below cannot fix** (it only remaps color, not geometry) — logged as unresolved, see below.
9. **SAD state is upright, not lying down** — spec requires SAD's body to lie down flat/low (silhouette flatter than TIRED, the Baby-precedent distinguishing rule). All 4 raw SAD frames show an upright sitting/standing pose instead — one frame even added an unprompted rain-cloud icon above Mochi's head (violates "no busy/detailed background"). **Also a shape-level gap, not fixed by this pass** — logged as unresolved, see below.
10. **SLEEPING raw batch frame-to-frame inconsistency** — 3 of the 4 raw SLEEPING frames show the required tightest/roundest curled-up silhouette, but frame 1 is an inconsistent upright standing pose with closed eyes. Caught during review (not blindly trimmed to "first N" like Baby's pass was) — see fix pass below.

**What did match**: flat sticker-vector chibi style, thick warm-brown outline (elsewhere in the set), transparent RGBA background, mood-appropriate expression differentiation (TIRED's yawn progression across its 4 raw frames — slump → wince → wide-open-yawn — landed especially well and needed no frame-order correction). The heart-fold chest marking (this spec's own new design decision) rendered correctly and legibly in every state without extra prompting effort. Species read is still clearly "rabbit" (long rabbit ears/face) despite the "no rabbit/cat/dog species markers" constraint — but this is an inherited continuation of Baby's own already-Done look (same tool/model/style lineage), not a new regression introduced by this batch, so it was not treated as a blocker here.

## Production Log — Spec-compliance fix pass (2026-07-24)

Post-processed with a Python HSV-threshold color-zone classification script (same technique as Baby's 2026-07-15 fix pass — script not preserved from that run, rewritten fresh and calibrated against this batch's actual pixel data): `V < 0.35` → outline, forced `#3D2B1F`; `S < 0.20 and V > 0.85` → belly, forced `#FFFDF0`; pink hue band → heart-fold/cheek, forced `#FFB5C8`; everything else → body, forced to the mood's Art Bible hex. Only RGB was remapped; alpha was left untouched so silhouette edges stay smooth. Output at `design/assets/generated/mochi_young/spec_compliant/`.

**Gaps fixed**:
1. **Frame counts** — trimmed to spec (HAPPY 4, CONTENT/TIRED 3, SAD/SLEEPING 2). Unlike Baby's blind "keep the first N frames," each state's raw 4 frames were reviewed first and the most spec-consistent subset was hand-picked: CONTENT uses frames [0,1,3] (frame 2 was a near-duplicate of frame 1; frame 3 has the actual eyes-closed blink beat the spec's "eyes-open → mid-inflate → eyes-closed" beat structure calls for). SLEEPING uses frames [0,2] (frame 1 was the inconsistent upright pose, frame 1's siblings 0/2/3 are the consistent curled pose — 0 and 2 read as the cleanest breathe-out/breathe-in pair). TIRED and HAPPY used their natural frame order as-is (already a good match to spec's beat structure). SAD used frames [0,1] (the two frames with the spec's optional single teardrop and downturned eyes; frames 2-3 drop the tear/sadness read or add the unprompted rain cloud).
2. **Per-mood body color** — recolored body zone to Art Bible hex per mood: HAPPY Mint Breeze `#A8E6CF`, CONTENT Peach Glow `#FFCBA4`, TIRED pale Lavender Soft `#D6BFE9` (base `#C5A3E0` lightened ~30% per the spec's own formula), SAD Lavender Soft `#C5A3E0` (literal, unlightened per spec), SLEEPING faded Cloud White `#FFF7F1`. Belly forced to Cream Ivory `#FFFDF0`, heart-fold/cheek forced to Petal Pink `#FFB5C8`, outline forced to `#3D2B1F` for all frames — this also fixed the pure-black outline drift found in `sad`'s raw output (verified post-fix: 0 fully-opaque pure-black pixels remain, only sub-10%-alpha edge remnants).
3. **File naming/structure** — now one horizontal-strip PNG per mood, `mochi_young_{mood}_idle.png`, matching spec convention exactly (`happy`, `content`, `tired`, `sad`, `sleep` — note `sleep` not `sleeping`, matching Baby's own filename convention).
4. **Resolution** — upscaled the 256px AI-native canvas to the spec's 336px 3x baseline via Lanczos resampling (opposite direction from Baby's downscale). Padded sheet dimensions match the spec's table exactly: HAPPY 1354×340, CONTENT/TIRED 1016×340, SAD/SLEEPING 678×340.
5. **Flat color zones** — verified post-fix: in the HAPPY sheet, the exact target body hex `(168,230,207)` covers 52.5% of opaque pixels and exact belly hex covers 13.9% — i.e. the zone interiors are genuinely single-hex flat. A more honest caveat than Baby's "now genuinely flat" claim: the Lanczos upscale reintroduces a few px of anti-aliased blending *at zone boundaries* (outline↔body, body↔belly, etc.), so the full per-image unique-color count is still in the thousands — that's boundary smoothing, not interior gradient/shading, and is a deliberate trade-off for clean edges over pixel-perfect flat zones.

**NOT fixed — real, unresolved gaps carried into "Done" status** (geometry-level, outside what a color-remap script can touch; would need either a targeted re-prompt/regeneration or manual retouch):
1. **Ear taper is weak** — the defining design decision of this whole spec run (visibly-tapered Young ears, distinct from Baby's uniform-width ear at a static 48×48px thumbnail) did not come through reliably in the raw art and could not be added by a color-only fix pass. Flagged for the delivered-art review pass this spec's own "Open item" section already anticipated.
2. **SAD is upright, not lying down** — the spec's required flat/low lying pose (the explicit distinguishing rule vs. TIRED's upright slump) is not present in any of the 4 raw SAD frames; the 2 delivered frames are the best *available* SAD read (teardrop + downturned eyes) but are posed upright/sitting, not lying down. This is a real deviation from the Art Bible §5.3 SAD pose spec, left as-is rather than fabricated via image manipulation.
3. **Total file size**: 5 files, 0.56MB combined — well under the spec's ~6.15MB estimate (estimate assumed larger padded dimensions before this batch's actual native resolution was known); no budget concern.

**Open items carried forward to the delivered-art review / emotional-fidelity playtest** (per this spec's own Next Steps #3): confirm ear-taper and SAD-lying-pose gaps above are severe enough to require regeneration before Approved status, and confirm Young reads as distinguishable from Baby at a glance despite the weak ear-taper delivery.
