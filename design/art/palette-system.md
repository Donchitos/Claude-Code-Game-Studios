# Palette System — The Last Seal (Voxel)

> **Status**: PROPOSED — awaiting art-director review
> **Author**: user direction (2026-07-27, palette expansion) + generated ramps
> **Amends**: `design/art/art-bible.md` §4 (Color System) and §8.4 (Palette Discipline)
> **Generator**: `tools/asset-pipeline/gen_palette.py` — re-run to regenerate every artifact here
> **Artifacts**: `design/art/last-seal-palette.png` (MagicaVoxel), `design/art/palette-sheet.html` (visual reference)
> **Validator**: PASS (167 colors, 6 rules — see §5)

---

## 1. Why this document exists

The Art Bible §4 locks 8 named swatches. That was correct for the vertical slice, but the
production game needs plants, seasons, biome variation and — later — magic. A colony builder
where every wall is one of three browns reads as a tech demo, not a world.

**User direction (2026-07-27):** expand the palette substantially, many colors and many tones,
but everything must read as one family.

The insight this document is built on: **coherence does not come from having few hues.** It
comes from every color sharing the same ramp construction, the same value window, and the same
saturation hierarchy. Under those three constraints the palette can grow indefinitely without
drifting. The 167 colors below are a starting set, not a ceiling.

## 2. Five channels

The single most important structural change: colors are no longer one flat list. Each channel
has its own permission level, because each occupies a different visual job.

| Channel | Role | Saturation | Hue space |
|---|---|---|---|
| **Structure / Building material** | The canvas — recedes | Restrained | Earth, stone, ochre |
| **Terrain** | Height bands, atmospheric depth | Restrained | Per art-bible §4.3 |
| **Vegetation / Organic** | Life, season, biome | **Free** | Green, yellow, bloom violet/magenta, autumn amber |
| **Function** (Hearth Gold) | "This does something" | Locked | Locked |
| **Magic / Emissive** | The loudest voice | **Maximum** | Free |
| **UI / State** | Messages | Locked | Locked |

**Magic is light, not surface.** Emissive colors live in a different channel from material
albedo, which is why they may be fully saturated without breaking the "material recedes" logic
of §4.2. A glowing rune does not compete with a wall — it competes with darkness. This is the
same mechanism §5.5 already established for the Corruption accent; this document generalizes it.

The restraint on the structure channel is what *buys* the loudness elsewhere. An image reads as
colorful through contrast, not through everything being saturated. If walls shout, magic cannot.

## 3. The ramp formula — the style glue

Every matte color is a 5-step ramp built by the same rule. This is what makes 167 colors look
like one palette.

```
S2  value −22   saturation  +9   hue → 260° (cool) by 14°
S1  value −12   saturation  +5   hue → 260° (cool) by  8°
BASE                    (authored anchor)
L1  value +10   saturation  −6   hue →  50° (warm) by  8°
L2  value +18   saturation −12   hue →  50° (warm) by 14°
```

- **Hue-shifting is mandatory, not decorative.** Shadows drift cool, highlights drift warm.
  A ramp built by only darkening the base reads dead and plastic.
- **Value window 14–92%.** No pure black, no pure white, anywhere in the project. This alone
  ties the palette together more than any hue choice.
- **Saturation ceiling 88%.**

**Function tier (Hearth Gold) uses a narrow 3-step ramp** — 0° hue drift, ±5% saturation,
±10% value — because §8.4 locks meaning-carrying colors. Gold has roughly three usable steps.
It is an accent, never a surface you can shade freely.

**Emissive uses a 3-step ramp instead:** `GLOW` (saturated, mid value) → `MID` → `CORE`
(burns out toward warm white). That is the hot-core structure real light has.

## 4. The color set

Canonical entries from art-bible §4 are marked — their BASE values are unchanged, only ramps
were added around them.

### Structure / Building material

| Slug | Material | S2 | S1 | BASE | L1 | L2 |
|---|---|---|---|---|---|---|
| `timber_oak` | Oak (canonical) | `#53271C` | `#6C3D29` | `#8B5E3C` | `#A48051` | `#B99D66` |
| `timber_birch` | Birch | `#936952` | `#AC8767` | `#CBAE84` | `#E4D2A2` | `#EBE1B5` |
| `timber_pine` | Pine | `#78492F` | `#91643F` | `#B08A55` | `#CAAF6D` | `#DECE86` |
| `timber_darkoak` | Dark oak | `#24100C` | `#3D2218` | `#5C3D28` | `#765A3A` | `#8A744D` |
| `stone_hearth` | Hearth-stone (canonical) | `#4C5057` | `#676B70` | `#8A8D8F` | `#A8A8A8` | `#BDBDBD` |
| `stone_granite` | Granite | `#515661` | `#6B727A` | `#8E9499` | `#B0B2B2` | `#C7C7C7` |
| `stone_slate` | Slate | `#262831` | `#3C414A` | `#5A6169` | `#787E82` | `#939697` |
| `stone_sandstone` | Sandstone | `#8F654A` | `#A8835E` | `#C7AA79` | `#E1CF96` | `#EBE0AB` |
| `clay_ochre` | Clay | `#783C29` | `#915738` | `#B07C4C` | `#CAA263` | `#DEC17A` |
| `thatch_umber` | Thatch (canonical) | `#702815` | `#894020` | `#A8642F` | `#C28B42` | `#D6AC56` |
| `shingle_brown` | Wood shingle | `#423129` | `#5B493D` | `#7A6A57` | `#948972` | `#A8A28C` |
| `plaster_cream` | Plaster | `#A18773` | `#BAA58C` | `#D9CBAE` | `#EBE4CA` | `#EBE8D8` |

### Terrain

| Slug | Material | S2 | S1 | BASE | L1 | L2 |
|---|---|---|---|---|---|---|
| `band_lowland` | Band 1 lowland (canonical) | `#737540` | `#868E53` | `#9CAD6E` | `#BEC68A` | `#D9DBA5` |
| `band_midland` | Band 2 hills (canonical) | `#714E35` | `#8A6A46` | `#A98F5E` | `#C2B378` | `#D7CB91` |
| `band_highland` | Band 3 rock (canonical) | `#424452` | `#5B5F6B` | `#7C818A` | `#9DA0A4` | `#B8B8B8` |
| `band_peak` | Band 4 peak (canonical) | `#8691A0` | `#A3AFB9` | `#C9D3D8` | `#E8EAEB` | `#EBEBEB` |
| `valley_ochre` | Valley ochre (canonical) | `#8A694C` | `#A38660` | `#C2AD7C` | `#DCD099` | `#EBE1B2` |

### Vegetation / Organic

| Slug | Material | S2 | S1 | BASE | L1 | L2 |
|---|---|---|---|---|---|---|
| `veg_grass` | Meadow | `#406329` | `#5A7C38` | `#7E9B4E` | `#A1B466` | `#BEC97D` |
| `veg_leaf_summer` | Leaf, summer | `#27521C` | `#3D6B29` | `#5E8A3C` | `#80A451` | `#9DB866` |
| `veg_leaf_spring` | Leaf, spring | `#7E8630` | `#8D9F3F` | `#9CBE55` | `#C3D86D` | `#E1EB85` |
| `veg_leaf_autumn` | Leaf, autumn | `#8C3112` | `#A54D1C` | `#C4762B` | `#DEA13E` | `#EBC050` |
| `veg_conifer` | Conifer | `#172B25` | `#274439` | `#3E6350` | `#557D63` | `#6C9175` |
| `veg_moss` | Moss | `#525425` | `#656D34` | `#7A8C4A` | `#9CA661` | `#B7BA79` |
| `veg_bloom_violet` | Bloom, violet | `#4E3D70` | `#665189` | `#8A6BA8` | `#AC87C2` | `#C8A2D6` |
| `veg_bloom_rose` | Bloom, rose | `#946396` | `#AF7AAC` | `#CE9AC4` | `#E8BBD9` | `#EBCCDD` |
| `veg_bloom_yellow` | Bloom, yellow | `#A8712B` | `#C1933A` | `#E0C24E` | `#EBD360` | `#EBD66E` |
| `veg_crop_grain` | Grain | `#915F2B` | `#AA7E3A` | `#C9A94E` | `#E3CE65` | `#EBD777` |

### Function — locked

| Slug | Material | S1 | BASE | L1 |
|---|---|---|---|---|
| `hearth_gold` | Hearth Gold (canonical, locked) | `#DC922B` | `#F5A83C` | `#EBA645` |

### Magic / Emissive

| Slug | Effect | GLOW | MID | CORE |
|---|---|---|---|---|
| `mag_arcane` | Arcane violet | `#530D85` | `#932CC7` | `#EBB4FA` |
| `mag_rune` | Rune cyan | `#0D7D85` | `#2CC7C4` | `#B4FAF1` |
| `mag_vital` | Vital green | `#0D8535` | `#2CC753` | `#B4FABD` |
| `mag_ember` | Ember / hearth fire | `#853F0D` | `#C7792C` | `#FADFB4` |
| `mag_frost` | Frost | `#0D2585` | `#2C58C7` | `#B4D0FA` |
| `mag_corruption` | Corruption (§5.5) | `#850D4D` | `#C72C72` | `#FAB4CB` |
| `mag_void` | Void | `#750D85` | `#BF2CC7` | `#FAB4F5` |
| `mag_spirit` | Spirit, warm white | `#998959` | `#D9D0A9` | `#FCFAED` |

### UI / State — locked, unchanged

| Slug | Role | Hex |
|---|---|---|
| `ui_chrome` | Panel fill | `#262220` |
| `ui_text` | Text | `#EDE6DA` |
| `state_blue` | State Blue (UI only) | `#4A90C4` |
| `state_orange` | State Orange (UI only) | `#E1752E` |
| `threshold_cool` | Threshold Cool (fog only) | `#6B8593` |

## 5. Validator — the rules that must survive expansion

Run `python tools/asset-pipeline/gen_palette.py`. It regenerates every artifact and checks six
rules. **A failing validator blocks the palette, not the asset.**

| Rule | Check | Traces to |
|---|---|---|
| **R1** | No world color may exceed Hearth Gold in saturation×value | §3.3, prohibition 4 — Gold must win the eye |
| **R2** | No saturated world color within 15° of State Blue | prohibition 3 |
| **R3** | No saturated red (hue 345–15°, S>40, **V>50**) in world geometry | prohibition 2 |
| **R4** | Every color inside the 14–92% value window | §3 above |
| **R5** | No emissive MID reads as Hearth Gold | §4.1 separation |
| **R6** | No duplicate slots | hygiene |

Two calibration decisions are worth knowing, because they look like loopholes and are not:

- **R3 carries a value guard.** A saturated warm hue below 50% value reads as brown, not red —
  deep oak and thatch shadows legitimately land at hue 12–15°. Without the guard the rule
  rejects the project's own canonical wood. The prohibition targets red as a *signal*, and a
  signal has to be bright to work.
- **R5 exempts `mag_ember`.** Hearth fire sharing Hearth Gold's warm family is the intent, not
  a collision — §2.1 calls the hearth "the warmest, most saturated point in any frame." Fire and
  the gold that marks the hearth *should* be relatives.

**Adjacency watchlist** (not failures — pairs to verify in the grayscale pass and the Dusk Test):
bloom rose vs Corruption (30° apart), Frost vs State Blue (22°), Ember vs Hearth Gold (10°).

## 6. Growing the palette

1. Author a BASE hex only. Never hand-pick ramp steps — add the entry to the generator and
   let the formula produce them. Hand-picked ramps are exactly how palettes drift.
2. Put it in the right channel. A color without a channel has no rules and will misbehave.
3. Assign it to built or wild. Principle 1 requires built spaces to read warmer than their
   surroundings; a color with no side breaks the One-Line Rule.
4. Re-run the generator. Green validator, or fix the base.

The MagicaVoxel palette currently uses **167 of 256 slots** — 89 free for growth before the
palette file itself needs restructuring.

## 7. Open items

| Item | Note |
|---|---|
| Art-director review | This document is PROPOSED; §4 of the Art Bible needs a pointer amendment on approval |
| Corruption exact hex | §5.5 defers the lock to the first creature concept — `#C72C72` is a proposal, not a lock |
| Bloom hues vs prohibition 2 | Bloom rose/violet are new hues outside the original §4 table. They are deliberate under the 2026-07-27 expansion, guarded by R1/R3 and by never carrying state meaning. Worth an explicit art-director ruling. |
| Grayscale + Dusk Test | The expanded set has not yet been run through §8.8.7 or the §7.1 Dusk Test |
| MagicaVoxel slot order | The 256×1 PNG index order should be verified on first import before authoring against slot numbers |
