# Art Bible — The Last Seal (Voxel)

> **Status**: COMPLETE — all 9 sections APPROVED (1–4: 2026-07-11; 5–9: 2026-07-23 — seven user taste decisions: villager accent colors, Corruption enemy hue, cheap-life-signals first wave, material-tinted ghosts, squared sans typography, 16px texel tier, 16-voxel cell density; ux-designer conflict pass folded into §7; §9 derived, no new decisions)
> **Author**: art-director agent + user (+ ux-designer + technical-artist passes for §7/§8)
> **Last Updated**: 2026-07-23
> **Slice input**: prototypes/last-seal-vertical-slice/REPORT.md — "direction right, mood lacking" drives §5.3/§5.6/§6.5
> **Foundation**: `design/art/visual-direction-note.md` (2026-07-09 interim anchor — this bible supersedes it as the production reference; the note's rules carry forward unless explicitly revised here)
> **World scale**: LARGE (2000×2000×32, ADR-0014) — all sections must hold at expedition distance, not just settlement-camera distance
> **AD-ART-BIBLE sign-off**: **APPROVED** 2026-07-23 (retroactive, recorded during the Pre-Production → Production gate check's AD-PHASE-GATE panel; rationale: complete, self-consistent, closes the mood-gap debrief finding with specifics, standards/prohibitions enforceable as written — remaining gaps are follow-on artifacts outside the bible's scope)

---

## 1. Visual Identity Statement

**The One-Line Rule** *(sharpened from `visual-direction-note.md`, extended for scale)*:

> **A built, lived-in space must always read warmer and more alive than anything around or threatening it — from the doorway to the horizon.**

The addition of "to the horizon" is deliberate: at 2000×2000 scale the player's home is frequently a small warm cluster seen from far away, not a frame-filling subject. The rule has to survive that view, not just the close-up.

### Supporting Principles

**1. Warmth-as-Reward.** Interior/fixture light (hearth, windows, lanterns) is warm and grows more saturated as build quality rises; ambient, exterior, and terrain light stays a cooler, desaturated neutral by comparison.
*Design test:* If an unbuilt, raw cell ever reads as warm or inviting as a furnished room, the palette has failed — warmth must be earned by building, never given for free.
*Serves:* Pillar 1 (*the building IS the game*) — warmth is the visible receipt for mechanical investment, not decoration layered on top.

**2. Blocky Honesty.** Structural geometry is flush, axis-aligned, and hard-edged (1m cells, no bevels, no gaps); readability comes from texture, per-face shading, and corner ambient occlusion, never from rounding or spacing the forms.
*Design test:* If a shape needs a rounded corner or a physical gap between blocks to read clearly, the fix is texture/lighting, not geometry.
*Serves:* Pillar 4 (*clarity over complexity*) — this is the visual half of that pillar's contract: legible forms at a glance.

**3. Stakes as Weather.** Threat intrudes on the existing palette — cool rim-light and desaturated fog creeping in from the threat's approach vector — rather than replacing it; the settlement's own warm lights get *locally brighter and more prominent* during an encounter.
*Design test:* If danger ever makes home look colder or less alive than the danger itself, the scene is off-model — pull back immediately.
*Serves:* Pillar 3 (*cozy, but with stakes*) — this is that pillar's entire visual contract in one sentence.

**4. The Horizon Test — NEW, large-world.** Principles 1–3 must resolve not just in a close establishing shot but at the edge of the streamed view radius (~380m), through the fog band, and in silhouette. Distance is not a rendering afterthought here — the core fantasy explicitly includes "the pull of the horizon" (`game-concept.md`), so the identity has to be legible *as* that pull, not just survive it.
*Design test:* Silhouette-and-screenshot the scene from expedition distance, in fog, at dusk. Without reading any UI, can you still tell "this is home," "this is wilderness," and "this is danger" apart?
*Serves:* Pillar 3 + the horizon-pull fantasy beat — at this world scale, distance itself carries meaning and must be tuned like any other visual signal, not left to whatever the mesher happens to output.

---

## 2. Mood & Atmosphere

### 2.1 Settlement Building (default state)

| | |
|---|---|
| **Emotional target** | Quiet pride, unhurried competence — "I am tending something that is mine." |
| **Lighting** | Warm-neutral daylight base with a permanent golden-hour bias (never harsh/neutral-white, even at "midday"); soft, high-ambient-fill shadows, not dramatic ones. Day/night cycle skews warmer at dusk/dawn as a bonus coziness window. Interior hearth/window light is always the warmest, most saturated point in any frame. |
| **Adjectives** | unhurried, tactile, sun-warmed, handmade, settled |
| **Energy level** | Low–mid, steady — no camera motion, no flicker; visual pacing matches the HUD's own "instant swap, no slide" calm (`interaction-patterns.md`). |
| **Carrying element** | The lit window/hearth glow — the single warmest, most saturated pixel cluster in the frame, legible from orbit-camera distance as the settlement's "we're okay" beacon. |

### 2.2 Expedition / Exploration — NEW, large-world

| | |
|---|---|
| **Emotional target** | The pull of "what's over that ridge" — anticipation and scale, with a little deliberate solitude (you've left the warmth behind, on purpose). |
| **Lighting** | Cooler and higher-contrast than the settlement's (extends `visual-direction-note.md` §2a's "terrain/sky stay cooler neutral" further outward): open-sky directional light, longer shadows, a wider value range. This is *not* the threat's cool rim-light (2.4) — it's exposed, not hostile. |
| **Adjectives** | vast, exposed, quiet, distant, wind-scoured |
| **Energy level** | Low but wide — unhurried pacing, visually big framing (horizon and skybox given real weight in composition). |
| **Carrying element** | The silhouetted landmark on the horizon (a distant seal-dungeon spire, a distinctive peak) — always the highest-contrast, most legible shape against sky/fog, working as a wayfinding beacon that pulls the player forward the way hearth-glow pulls them home. |

### 2.3 Distress / Warning States (villager trapped, unmet need, etc.)

| | |
|---|---|
| **Emotional target** | "Something needs me, but it's not catastrophic yet" — a nudge, not an alarm. Stays inside Pillar 3's cozy-is-the-resting-state default. |
| **Lighting** | No scene-wide change. Material never carries state (Section 4 rule) and accessibility A5 forbids flashing/shake — distress is communicated entirely through the UI/overlay layer. |
| **Adjectives** | pointed, legible, calm-urgent, contained |
| **Energy level** | Low–mid — a static or gently-pulsing icon (sub-3Hz, per A5), never a flash, never a shake. |
| **Carrying element** | The existing billboarded shape+label icon above the affected villager/room (`interaction-patterns.md`'s "shape+label, never hue" convention) — small, localized, dismissable, never full-screen. |

### 2.4 Scene Transition / Dungeon Approach (VS+)

| | |
|---|---|
| **Emotional target** | Threshold-crossing — "I am choosing to leave safety." A held breath, not fear yet. |
| **Lighting** | This is where `visual-direction-note.md` §2c ("stakes as weather") begins literally: cool rim-light and desaturated fog creep in from the approach vector; any light the player carries (torch, lantern) becomes locally brighter — the beacon-in-the-dark read starts at the threshold, not inside the dungeon. |
| **Adjectives** | hushed, cooling, narrowing, charged |
| **Energy level** | Mid, rising — the one state allowed a deliberate pacing shift (existing transition overlay, `scene-world-management.md`), but still obeys A5 (no screen shake, no >3Hz flicker). |
| **Carrying element** | The fog gradient itself, keyed to **Threshold Cool** `#6B8593` (a desaturated slate distinct from State Blue — AD re-review fix 2026-07-11: fog is world-space atmosphere and must never borrow a UI state hue; State Blue means SAFE and only lives in UI chrome). |

### 2.5 Menus / Pause

| | |
|---|---|
| **Emotional target** | Neutral competence — a tool, not a mood. Get in, decide, get out. |
| **Lighting** | N/A — flat UI-space. Background is a dimmed/blurred freeze of the last world frame ("paused, not left"), not a separately lit environment. |
| **Adjectives** | quiet, flat, immediate, unadorned |
| **Energy level** | Minimal — zero ambient motion (no parallax, per A5), instant open/close. |
| **Carrying element** | The dimmed world freeze-frame behind the menu — keeps the player anchored to "their" settlement at zero extra cost. |

### 2.6 Fog / Horizon Treatment for the Streaming Boundary

**Proposal:** fog color is a function of *distance from the settlement core*, not only distance from camera.

- Near the settlement core, atmospheric falloff stays **warm-neutral** (an extension of Valley Ochre, §4.3) — the world doesn't visually go cold right at the edge of home turf.
- Past expedition range, falloff shifts to the **Threshold Cool fog** (`#6B8593`, see 2.4) — signaling "you are now away from home" before any UI does.
- **Silhouetted landmarks** (dungeon spires, distinctive peaks) are placed to poke through the fog band at the streamed view-radius edge as low-detail silhouette proxies, giving the player a next-goal read before that chunk streams in at full detail (this also gives the ~2.6s initial-window-build a visual anchor to hold onto, per ADR-0014's measured load time).

> **CONFIRMED (user decision 2026-07-11):** the recommended option below is now the committed rule. Original note: recommended — warm-to-cool distance-keyed fog + silhouette landmarks, because it does double duty (depth cue *and* narrative "leaving home" signal) at no extra render cost beyond a color ramp. **Alternative:** a single flat neutral-grey fog color regardless of distance (simpler, cheaper to implement, but loses the "leaving home" read and does nothing for Principle 4's Horizon Test).

---

## 3. Shape Language

### 3.1 Character Silhouette Philosophy (Villagers & Squad)

Villagers use **chunky, exaggerated block silhouettes** (oversized head-to-body ratio, in the Minecraft/Stonehearth family) so the silhouette alone — no texture required — reads at small screen size. This serves two distance regimes at once:

- **Settlement-camera distance:** silhouette + Function-gold trim on profession tools/gear reads role at a glance, extending Villager Info UI's existing "shape, never hue" icon convention from the UI layer down into the character model itself.
- **Expedition distance:** villagers themselves rarely appear this far out (they live in the settlement core, per `game-concept.md`), but squad members on dungeon delves do. Same rule applies, with one addition: squad members carry a visible **warm accent** (trim, cape, banner-color) against the cooler expedition/dungeon palette, so "this is mine" reads even off-camera from the settlement — Principle 1 (Warmth-as-Reward) extended to *who*, not just *where*.

### 3.2 Environment Geometry Rules

| Element | Rule |
|---|---|
| **Structural blocks** (wall/floor/roof/foundation) | Strict 1m grid, flush, axis-aligned. Non-negotiable — this is Principle 2 (Blocky Honesty) itself. |
| **Furniture/fixtures** (bed, table, hearth, door) | Grid-cell-based for placement logic, but may use sub-cell silhouette detail within their cell bounding box (a bed can *read* as bed-shaped, not a plain cube) — placement stays on-grid, the model inside the cell is where craft happens. |
| **Vegetation** (grass, bushes, trees) | The one deliberate exception — may deviate from strict block silhouettes (billboard/small non-cubic clusters) for a softer "alive" read against blocky architecture, provided hue never leaves the Material/terrain family and never encroaches on Function-gold. |
| **Distant terrain** (chunked mesher, height-band vertex colors) | Pure blocky/faceted at every distance by construction — the mesher only emits axis-aligned faces (ADR-0014). No separate art ruling needed; this is already structurally locked. |

The vegetation exception is intentional, not a gap: it creates a **built-vs-wild distinction at the silhouette level**, not just the color level — hard edges mean "made," slightly softer edges mean "grown."

### 3.3 Hero vs. Supporting Shapes

- **Hero shapes** = Function-tier fixtures (hearth, bed, table, door — the Unique Hook objects). These get the most silhouette investment: distinct outlines, gold trim, the strongest read in any frame. They're both gameplay-critical and the emotional payoff objects (Principle 1).
- **Supporting shapes** = plain Material blocks (wall/floor/roof segments) stay deliberately plain and repetitive. Gestalt figure-ground: if every block carried equal detail, nothing would pop — Function fixtures need to win that visual contest for Principle 1 to work at all.

### 3.4 UI Shape Grammar

**Position: clean, flat, sharp-cornered HUD — echoes the world's squareness, not its texture.**

The HUD borrows exactly one thing from the voxel world's shape language: **hard, square corners, no rounding** (consistent with Principle 2). It does *not* otherwise mimic voxel texture or depth — no faux-block bevels, no gradient chrome, no skeuomorphism. This is a deliberate two-level grammar:

- **Macro level** (panels, toasts, chips): sharp square corners, flat fills — matches the world's edge language and serves the existing "speed over ornament" / instant-swap HUD feel (`building-ui.md` Game Feel, `interaction-patterns.md`).
- **Micro level** (status/state icons): deliberately *varied* shapes (triangle, circle, diamond) — this is where colorblind differentiation lives (Section 4.6, A1), and variety here is required, not decorative.

> **CONFIRMED (user decision 2026-07-11):** the recommended option below is now the committed rule. Original note: recommended — flat/sharp HUD with world-echoing corners only. **Alternative:** a fully skeuomorphic blocky HUD (chunky pixel-art inventory slots, Minecraft-inventory-style). Rejected as primary because it fights the already-committed "speed over ornament" feel and adds asset/render cost with no gameplay payoff — but it's a viable alternate identity if the team wants a stronger retro-voxel HUD signature later.

---

## 4. Color System

### 4.1 Primary Palette

| Swatch | Name | Hex | Family | Role |
|---|---|---|---|---|
| 🟫 | Timber Brown | `#8B5E3C` | Material | Wood structure — walls, beams, framing |
| ⬜ | Hearth-stone Grey | `#8A8D8F` | Material | Stone structure — foundations, floors |
| 🟧 | Thatch Umber | `#A8642F` | Material | Thatch/roofing — warm red-brown |
| 🟡 | Hearth Gold | `#F5A83C` | Function | Fixtures that carry function (bed, table, hearth, door) — the "this block does something" tell; always the most saturated warm in a built frame |
| 🟨 | Valley Ochre | `#C2AD7C` | Ambient | Terrain/sky base neutral — muted, warm-leaning, recedes near the settlement core |
| 🔵 | State Blue | `#4A90C4` | State | Safe / positive / calm signal — UI and overlay only |
| 🟠 | State Orange | `#E1752E` | State | Danger / alert / warning signal — UI and overlay only |
| 🔲 | Threshold Cool | `#6B8593` | Atmosphere | Distance/dungeon-approach fog ONLY — world-space atmosphere, deliberately distinct from State Blue (which means SAFE and never leaves UI chrome) |

**Deliberate separation note:** Hearth Gold (Function) and State Orange (State) are both warm hues by necessity — the note's own philosophy makes warmth the reward signal, and orange is the safer danger-hue for colorblind accessibility. They stay distinguishable *structurally*, not just by eye: Hearth Gold **only ever appears on static geometry** (fixtures), State Orange **only ever appears in the UI/overlay layer** (Section 4 rule from `visual-direction-note.md` §3, carried forward verbatim) — they are never candidates for confusion in the same visual channel, and both still carry mandatory shape/label pairing regardless (§4.6).

> **CONFIRMED (user decision 2026-07-11):** the recommended option below is now the committed rule. Original note: recommended — amber/gold-leaning warm family (as above), cooler slate-blue state axis. **Alternative:** lean the warm family more toward true orange-red (e.g., Hearth Gold → `#E8873A`-adjacent) for a punchier "campfire" read — rejected as primary because it narrows the gap to State Orange further; worth a swatch-comparison pass once real assets exist.

### 4.2 Semantic Color Vocabulary

| Meaning | Color | Notes |
|---|---|---|
| Structure — recedes | Material family (Timber/Stone/Thatch) | Differentiate by value/texture, not saturation |
| "This does something" | Hearth Gold | Function tier only — never used for plain structure |
| Safe / positive / confirm | State Blue | UI/overlay only |
| Danger / warning / alert | State Orange | UI/overlay only |
| Neutral / info / ambient | Valley Ochre (or a desaturated grey derivative) | Terrain base, non-alert UI chrome |

### 4.3 Per-Height-Band Terrain Color Mapping (ADR-0014)

Bands ramp from warm-neutral (low) to cool-pale (high) — this does double duty as material logic (grass → earth → stone → snow) **and** an atmospheric-perspective depth cue that blends directly into the horizon fog (§2.6):

| Band | Elevation (of 32) | Name | Hex | Read |
|---|---|---|---|---|
| 1 | 0–8 | Lowland | `#9CAD6E` | Grass/valley floor — warm-neutral, welcoming near the settlement |
| 2 | 8–16 | Midland | `#A98F5E` | Earth/hills — warmer transitional brown |
| 3 | 16–24 | Highland | `#7C818A` | Stone/rock — cooler slate grey |
| 4 | 24–32 | Peak | `#C9D3D8` | Snow/frost — cool pale, blends directly into the expedition fog color (§2.6) |

### 4.4 Biome / Area Temperature Rules (2000×2000 world — 3 launch biomes max)

1. **Home Valley** (settlement core & immediate surrounds) — the note's original warm-neutral palette (§2.1), highest warmth ceiling for structures, Valley Ochre base.
2. **Expedition Highlands** (mid-distance, seal-dungeon approach terrain) — cooler, more desaturated, rockier; literalizes Principle 3 (Stakes as Weather) at the terrain level, not just the encounter level.
3. **Deep Threshold** (distant, dungeon-adjacent) — coldest, near-monochrome blue-grey; maximum contrast against any warm light the player carries, so the beacon-in-the-dark read (§2.4) starts working the moment this biome comes into view.

> **CONFIRMED (user decision 2026-07-11):** the recommended option below is now the committed rule. Original note: recommended — the 3 biomes above, chosen because each one maps to an existing narrative/gameplay distance ring (home / expedition / dungeon-threshold) rather than adding new geography for its own sake. **Alternative:** a 2-biome launch (merge Expedition Highlands + Deep Threshold into one "Wilds" biome) — simpler to build/texture for Vertical Slice, at the cost of a less gradual cool-down curve toward dungeons.

### 4.5 UI Palette Divergence

The HUD deliberately does **not** use the full material/terrain palette — it runs a reduced, low-key neutral shell so it never visually competes with the world:

- **Panel/chrome fill:** near-black warm-neutral, `#262220` — low-key enough to recede behind world color.
- **Functional highlight (active/focused state):** Hearth Gold `#F5A83C`.
- **Status only:** State Blue / State Orange, exclusively.
- **Text:** off-white `#EDE6DA` (warm-tinted white, not clinical `#FFFFFF`, to stay in-family) — sized per `accessibility-requirements.md` A4 (16px+ body, 18px+ labels).

### 4.6 Colorblind Backup Table

Per `accessibility-requirements.md` A1: no gameplay-critical state may rely on hue alone. Blue–orange is the safer axis for the most common types (protanopia/deuteranopia), but no axis is fully safe for every type — table below names the residual risk pairs and their backups.

| Pair | Colorblind type at risk | Failure mode | Backup mechanism |
|---|---|---|---|
| State Blue vs. Valley Ochre/terrain neutrals | Tritanopia | Blue can read muddier/greener, may blend into cool terrain neutrals at distance | State color never appears on world terrain (structural rule, §3) — it only ever sits inside UI chrome with icon shape + label |
| Hearth Gold (Function) vs. State Orange (Danger) | Protanopia/deuteranopia (mild), tritanopia (moderate) | Both warm/yellow-orange; saturation is the only differentiator at low contrast | Structurally prevented from co-occurring (Gold = geometry only, Orange = UI only, §4.1); UI additionally pairs distinct icon shape (e.g., triangle-exclaim vs. star-glow) + label, per A1 |
| State Blue vs. State Orange (the core axis) | Verified safe for protanopia/deuteranopia (primary target); mild compression under tritanopia | Edge case only | Every instance ships with a paired shape (square/round/etc. per existing Villager Info UI + Building UI icon conventions) + text label — mandatory day-one, not deferred |

**QA hook:** grayscale pass is the MVP gate (A1); a tritanopia-specific simulator pass is scoped to Vertical Slice QA per `accessibility-requirements.md`'s existing "Colorblind simulation testing beyond grayscale" gap — this table is the checklist for that pass when it runs.

---

## 5. Character Design Direction

### 5.1 The Player Character Question — The Unseen Steward

The game has no player avatar (`game-concept.md`: "you are the **unseen steward**"). This is a scope-reducing constraint, not a design gap — no hero/avatar model, no first-person hands, no camera-attached body. Where the player's identity lives visually instead:

- The **built settlement itself** is the player's self-portrait (Principle 1 — pride is legible as light and warmth, not as an avatar).
- The **squad's warm accent** (trim/cape/banner-color, §3.1) is the closest thing to a player "signature" in the 3D world — it should read as *chosen* by the player (customizable accent), since it's the only on-screen marker of "mine" once the player leaves the settlement.
- The **build ghost/cursor** (Building UI) is the closest thing to a "hand" — already specified there, no new asset need.

*Serves:* Core Fantasy ("unseen steward") + Pillar 1.

### 5.2 Villager Visual Archetype — 2-Block Proportions

Extends §3.1 with the slice-locked scale fact: **villagers are 2 blocks tall**.

| Spec | Value | Rationale |
|---|---|---|
| Total height | 2 cells | User-locked (slice, 2026-07-23) |
| Head : body+legs split | ~45 : 55 | Bigger-headed than a realistic 2-block figure — the head-weight makes the silhouette "Stonehearth-chibi" rather than "Minecraft-adult" (§3.1's "oversized head-to-body ratio"). Resolution of the two references: Minecraft supplies the **texture/readability** language (slice-validated), Stonehearth the **proportion** language. |
| Limb block count | 1 arm-block + 1 leg-block per side, flush, no gaps | Blocky Honesty (Principle 2) — no rounding to soften the chibi look; head-weight alone carries the appeal. |
| Silhouette test | Must read "villager, not squad, not enemy" at settlement-camera distance in solid black silhouette | Horizon-Test methodology (Principle 4) extended to characters. |

**Profession vs. individual identity — two separate visual channels, kept structurally distinct** (mirrors the Gold/Orange separation in §4.1):

- **Profession** reads through *shape + Hearth Gold trim* on the held tool/gear only — never on skin/hair/clothing base color.
- **Individual identity** (5.3) reads through a *separate, non-gold* accent on clothing/hair.

### 5.3 Distinguishing Individuals — the "Alive" Read

Direct art-side answer to the 2026-07-23 debrief ("the world lacks life"): at 20–30 concurrent villagers, profession alone reads as a labor-color-coded machine, not people.

**Rule: personal accent-color palette.** Each villager is assigned one hue from a small curated set (6–8 swatches: muted rust, sage, slate-blue-grey, dusty plum — all desaturated enough to stay inside the Material family's "recedes" logic, §4.2), applied to hair and/or a clothing accent (scarf, apron trim). Cheap (palette-swap on a shared mesh), gives immediate "that's Mira, the one in green" recognition, and composes with the profession-gold channel without collision (different object, different hue family).

> **CONFIRMED (user decision 2026-07-23):** accent-color palette is the committed rule. **Alternative considered:** silhouette-only variation (hairstyle/hat/prop, no added color) — stricter palette but more expensive (unique meshes, not material swaps) and washes out at settlement-camera distance; hue difference is detected pre-attentively, small shape difference is not.

Either way, individuation also carries a **behavioral tell** (5.6) — color reads "a villager," motion reads "this specific person."

*Serves:* Pillar 2 (alive settlement) — directly.

### 5.4 Squad Members vs. Villagers

Squad members are **drawn from the villager roster**, not a separate cast — same 2-block archetype, same individual-accent channel, plus an **equipment layer**:

- Gear/gold-trim intensity scales with squad tier the way Hearth Gold scales with build quality (§2.1) — better-equipped members are visibly *more saturated warm*, extending Principle 1's "warmth is earned" from buildings to people.
- The warm accent must survive the cooler Expedition/Threshold palettes (§2.2, §2.4) — the one character rule that is explicitly *not* Material-recedes: a squad member is the warmest thing in an expedition frame, the way a lit window is in a settlement frame.

*Serves:* §3.1, Principle 1, Principle 3 (the squad is the traveling "home").

### 5.5 Enemies — Seal-Dungeon Creatures

Creature *bodies* stay in a desaturated cool register near Threshold Cool / Deep Threshold tones (§4.3–4.4) so they belong to their environment; a dedicated accent makes them pop (figure-ground, §3.3 applied to threat).

**Rule: dedicated "Corruption" accent hue** — a sickly violet-red, distinct from both Hearth Gold and State Orange, used only as a small emissive/detail accent (eyes, cracks, seal-corruption glow) on creatures and dungeon-threshold corruption detail. Repeats the validated Threshold-Cool precedent (§2.4): a narrow-use world hue keeps "State color never appears on world geometry" (§4.6) structurally true, at the cost of one more hue for the colorblind QA pass to track.

> **CONFIRMED (user decision 2026-07-23):** Corruption hue is the committed rule. **Alternative considered:** reusing State Orange as creature emissive — simpler palette, ties "danger" together across UI and world, but reopens the exact semantic-boundary defect the AD flagged in the 2026-07-11 fog/State-Blue fix. Exact hex to be locked with the first creature concept, verified against the §4.6 table.

*Serves:* Principle 3, §4.6.

### 5.6 Expression & Personality Without Faces

Blocky characters at this scale cannot carry facial nuance — personality lives in **motion and behavior**:

- **Animation timing** — walk/idle cadence varies per personality (bustling worker vs unhurried elder); the character-level equivalent of §2.1's "unhurried, tactile" energy.
- **Idle behaviors** — stretching, glancing at an unfinished build, sitting at a furnished table, brief exchanges between bonded villagers. Cheap (reuses the existing FSM) and exactly the "world feels populated" signal the debrief asks for.
- **Mood-as-posture** — slouched/slow when a need is unmet, brisk/upright when content; presentation of data the needs/mood sim already has, not new simulation.
- **Name tags & state icons** — stay in the Villager Info UI layer (shape+label, §3.4); the model itself never has to convey that information.

*Serves:* Pillar 2 — the cheapest, most direct fix to "the world lacks life."

### 5.7 Character LOD Philosophy

| Distance band | Detail level | Rule |
|---|---|---|
| Close / settlement-camera | Full model, full animation | Profession-gold + individual accent both legible |
| Mid / expedition | Silhouette + warm accent only | Accent must survive the cooler palette (§3.1) |
| Far (below ~10–12px on screen) | Marker icon, no model | Falls back to the shape+label icon convention (§2.3/§3.4), never an unreadable pixel smear |

Exact swap thresholds are the technical-artist's call (§8) — the art requirement: identity (warmth, accent) must not silently disappear before the model does. *Serves:* Principle 4.

---

## 6. Environment Design Language

### 6.1 Architectural Style & Buildable Vernacular

The player builds freely, so "architectural style" means the **palette of buildable materials + fixture silhouettes**, not fixed hero buildings. The Section 4 palette already implies the direction, made explicit here: Timber Brown, Thatch Umber, Hearth-stone Grey and the Peak snow-cap together imply a **northern homestead / timber-and-thatch folk vernacular** — steep-pitched roofs (functional against snow, strong simple silhouette per §3.3), log-and-beam wall logic, warm-toned interiors. Matches the game's own framing ("folk-tale 'the seals that hold back the dark'", `game-concept.md`). Derivation from approved rules, not a new fork.

**Fixture consequence:** doors, windows, beds, tables, hearths read as "made by hand from the Material palette," reinforcing the built/natural (hard/soft edge) split of §3.2. Later biomes may add regional variants (stone-heavy highland vernacular) — new materials, never a new shape grammar.

### 6.2 Texture Philosophy — Stylized Chunky-Texel, Not PBR

**Rule: procedural/hand-painted chunky-texel textures; never a PBR (albedo/normal/roughness/metallic) pipeline for world geometry.**

- **Blocky Honesty (Principle 2):** readability comes from texture/per-face shading/AO — PBR's expressive range (specular/roughness response) reads as material realism, not shape clarity.
- **Lighting model (§2.1):** the permanent warm golden-hour bias with soft fill would be fought by PBR's dramatic specular/reflection response — reintroducing the "harsh/neutral-white" look §2.1 forbids.
- **Slice-validated:** the Minecraft-readability procedural textures were explicitly confirmed in the 2026-07-23 debrief — playtest evidence, not theory.
- **Scale:** at 16k×16k, tileable chunky textures stay cheap (small atlas, no per-material texture sets) exactly where the storage/streaming spike is already under pressure.

**Where extra texture investment IS allowed:** Function-tier fixtures (§3.3 hero shapes) may carry more authored detail than plain Material blocks — bigger texel budget on the same pipeline, never a different pipeline.

### 6.3 Prop Density by Area

| Area | Density | Rationale |
|---|---|---|
| **Settlement core** | High — warm clutter (mugs, tools, laundry, garden rows) | Carries Warmth-as-Reward into set dressing; density is part of the "lived-in" read |
| **Expedition / wilds** | Low–mid, sparse but purposeful (a lone dead tree, a cairn, the §2.6 landmark) | §2.2's "vast, exposed" energy — over-propping would undercut the horizon-pull |
| **Dungeon threshold** | Low density, high signal — cracked ground, corrupted growth, Corruption-accent detail (§5.5) | Every prop is a "stakes as weather" tell (Principle 3), not filler |

### 6.4 Environmental Storytelling

- **Far-world content** (ruins, encounters, resource nodes) extends the same homestead vernacular, **cooled and decayed**. A ruin is Warmth-as-Reward run in reverse: an abandoned structure must read exactly as un-warm as raw terrain (Principle 1's own design test applied to a built-then-lost space) — that's what makes ruins read as loss, not props.
- **In-settlement storytelling** — unfinished projects, staged materials, a half-built roof — is a literal readout of Pillar 1: the build-in-progress state doubles as the settlement's diary.

### 6.5 Ambient Life & Motion

**Direct answer to the 2026-07-23 debrief's #1 finding: "direction right, but mood/atmosphere lacking — the world lacks life."** The slice-validated anchors (chunky textures, cliff treatment, golden-hour light, horizon fog, warm room lights) are the static foundation; everything below adds motion/life on top without touching it. Cost classes are art-direction-level; final budgets belong to the technical-artist (§8).

| Element | Mood Target Served | Cost Class | Notes |
|---|---|---|---|
| Grass/foliage wind-sway | Settlement (2.1) + Expedition (2.2) | Cheap — vertex-shader wind | Vegetation is already the one "soft" shape exception (§3.2) |
| Chimney/hearth smoke wisps | Settlement (2.1) — reinforces the "warmest pixel cluster" | Cheap — small GPUParticles3D | Only on *occupied/lit* buildings — smoke absence becomes a readable "nobody home" tell (Principle 1) |
| Leaf/pollen drift near trees | Settlement + Expedition | Cheap — low-count particles | "The air is alive" |
| Distant birds (billboard, simple path) | Settlement + Expedition — living sky | Cheap — no AI | Circling over settlement or ridgelines; reinforces scale |
| Villager idle behaviors (§5.6) | Settlement (2.1), Pillar 2 | Mid — reuses existing FSM | Highest mood-value-per-cost item on this list |
| Interior warm-detail clutter | Settlement (2.1) | Cheap — static props | Life via implied recent use — cheapest possible win |
| Torch/lantern flicker (carried + fixed) | Threshold (2.4) beacon read | Cheap — light-energy noise | **Must respect A5** (sub-3Hz) — no free pass on flicker rate |
| Water shimmer/ripple (lakes) | Expedition (2.2) | Cheap — shader | Biome exists in the slice terrain |
| Horizon fog drift / heat-shimmer | Expedition (2.2) + Principle 4 | Cheap — noise-scrolled shader | Makes the fog band feel alive, not just a color ramp |
| Squad banner/cape wind motion | §3.1's "this is mine" read | Cheap — shader/bone | Reinforces warm-accent legibility at range |
| Day/night behavioral cues (head home at dusk, lanterns light in sequence) | Settlement (2.1) dusk coziness window | Mid — schedule-driven | Reuses the planned needs/schedule system |
| Weather states (overcast, rain, gusts) | Settlement + Expedition | Mid–high — weather state machine | Highest cost; later pass |
| Ambient wildlife (small critters) | Settlement + Expedition | Mid — simple wander AI | Lower priority than villager idle behaviors (same goal, less direct) |

> **CONFIRMED (user decision 2026-07-23) — first production wave:** chimney smoke, foliage sway, villager idle behaviors, interior clutter, torch flicker — the cheapest items AND the ones targeting the debrief's specific gap (population life + warmth reinforcement). **Alternative considered:** leading with weather/day-night systems — bigger single mood swing, but more expensive and later. Weather and day/night cues remain on the list as the second wave.

---

## 7. UI/HUD Visual Direction

This section decides **presentation only** — behavior stays owned by `hud.md`, `villager-panel.md`, `interaction-patterns.md`. It builds on the slice-validated HUD and the two locked rules it must never contradict: **§3.4 UI Shape Grammar** and **§4.5 UI Palette Divergence**. The F3 debug console is a developer tool — exempt by scope. Drafted with an independent ux-designer requirements pass (20 checks, 6 conflict flags — resolutions below).

### 7.1 Diegetic vs. Screen-Space Split

| Layer | Elements | Renders in |
|---|---|---|
| **World-space** | Hover pre-glow, selection outline, build grid, ghost/preview overlay, overhead distress icons (billboarded) | The 3D scene |
| **Cursor-anchored (hybrid)** | Invalid-commit cue — screen-space marker pinned to the world-projected cursor | Screen-space, following a world coordinate |
| **Screen-space (chrome)** | Toolbar, context panel, time controls, toast stack, issues anchor, villager panel, projects panel, transition overlay | Fixed HUD zones |

**Palette rules binding the world-space layer (conflict resolutions):**

- **Hearth Gold has one semantic core — "this matters / is yours / is active" — in two structurally distinct channels:** (1) *permanent*, on Function-tier fixtures (§4.1's original scope); (2) *transient*, on the UI/overlay layer for focus and selection (armed tool, selected project card, villager/project selection outline). Neither channel ever touches the Material/terrain layer — that separation is what §4.1 was protecting, and it still holds. *(Resolves UX Conflict 1: the villager-panel Gold selection outline is channel 2, legal.)*
- **State Orange covers world-space "needs attention"/invalid signals** — invalid-commit cue, overhead distress icons, unreachable-job ghosts, **and dig/demolition order markers**. The slice's *red* demolition overlay does not survive into production — red is not in the palette (and red-green is forbidden). All same-hue-family markers MUST differ by **shape/icon**, never by saturation or pulse-timing alone. *(Resolves UX Conflict 2.)*
- **State Blue never appears in world-space** — no exceptions added.
- **Threshold Cool is fog-exclusive** — construction UI must never borrow it, even at low opacity.
- **Ghost previews render as a translucent tint of the ACTUAL material being placed** (slice-validated at 0.50 draft / 0.70 released alpha) — the preview shows the warmth being built toward (Principle 1). Invalid placement switches to the State Orange tint — reuse, no new state color.
- **Build grid:** low-opacity lines in a desaturated warm-neutral from the Ambient family (Valley Ochre) — world-space UI stays inside the five existing families.

> **CONFIRMED (user decision 2026-07-23):** material-tinted warm ghosts + Valley-Ochre-family grid, zero new hues. **Alternative considered:** genre-standard uniform "blueprint blue/white" — reads instantly as "not real yet" and is cheaper (one tint), but kills the Warmth-as-Reward preview and soft-collides with State Blue's reserved meaning in exactly the §4.6 tritanopia risk zone.

**New QA gate (from the ux pass, Conflict 3): the Dusk Test.** State-Orange-carrying elements (invalid cue, distress icons, demolition markers) must pass a screenshot legibility check under the game's WARMEST guaranteed lighting (golden-hour dusk) against every §4.3 height band — the warm ambient bias sits closest to orange exactly then. Companion to the Horizon Test.

### 7.2 Typography

**Personality:** "quiet competence, speed over ornament." Ruled out: rounded/geometric-soft sans (contradicts hard-edge language at the letterform level) and blackletter/fantasy display (fails the 16px floor).

> **CONFIRMED (user decision 2026-07-23):** neo-grotesque/humanist sans with squared terminals — Inter / IBM Plex Sans / Work Sans family; exact font locked at implementation against the checks below. **Alternative considered:** slab-serif (Roboto Slab family) — leans "sturdy toolmaker" and differentiates from the genre look, but stroke contrast risks the 16px floor and reads "document," not tool chrome.

Hierarchy comes from **weight, not size or opacity** (the A4 floor forbids smaller tiers; muted-opacity text would silently break the 4.5:1 contrast rule):

| Tier | Weight | Size | Used for |
|---|---|---|---|
| 1 — Header | Medium/Semibold | 18px+ | Panel/villager/project names, section titles |
| 2 — Primary body | Regular | 16–18px per element (A4) | Activity labels, why-strings, need labels |
| 3 — Meta/numeric | Regular or Medium | 16px floor | Raw values, counters, tooltips |

**Numeric figures:** tabular (fixed-width) for anything re-read every frame (need values, "N !" counters) — proportional digits jitter width, which reads as unintended motion against A5's spirit.
**Character set:** extended Latin (ä/ö/ü/ß) minimum; check glyph coverage against the documented +40% German/French expansion tolerance before locking the exact font.
**Verification before sign-off (ux pass items 11–13):** comfortable-unscaled check at 1600×900 in addition to 720p/1080p/1440p; contrast-checker report against the FINAL font weight; the ≥20-char one-line activity-label budget validated against the chosen font's real glyph widths.

### 7.3 Iconography

- **Style:** flat, single-weight glyphs — outlined or solid, never mixed within one family; no bevels/gradients/shadows (§3.4).
- **Stroke weight:** fixed ratio ~1/12 of the icon box (e.g. ~2px in a 24px box), constant across every family.
- **Corners:** macro containers stay sharp-square; glyphs carry the mandated **shape variety** (triangle/circle/diamond/square — where colorblind differentiation lives, A1), but each glyph's own corners stay hard — a filleted triangle would reintroduce the "friendly mobile-game" read Principle 2 rules out.
- **Grid tiers:** Primary (toolbar tools, largest), Inline (status/mood/distress, cap-height-aligned to Tier-2 text), World-space billboard (scaled for in-scene legibility at settlement range, Horizon-Test discipline — not a fixed screen size).
- **Shape budget (ux pass item 5):** one shared assignment table for ALL stateful icons (toast tiers, mood bands, distress subtypes, tool states, invalid cue, unreachable ghost, project states incl. draft/released/paused/done, dig/demolition markers) — no two unrelated states may reuse the same silhouette at HUD-icon size. The table is authored with the first production icon pass and lives beside §4.6.

### 7.4 UI Motion Rules

Baseline: §2.1's instant-swap calm. Everything not listed defaults to **instant swap, zero duration**.

| May animate | Cap |
|---|---|
| Toast retire fade | ≤ 0.2s |
| Invalid-commit cue fade | ~1s |
| Transition overlay fade | per scene-management spec |
| Value/progress bars | No easing — render the raw value every frame (a re-read, not an animation) |
| Distress icon pulse (reserved, NOT MVP) | sub-3Hz, amplitude-only, never on/off flash |

| Never animates |
|---|
| Panel show/hide (instant swap), screen shake (A5), >3Hz flicker (A5), parallax/vestibular effects (A5), ambient "breathing" chrome (idle glows/pulses — not committed anywhere; adding one breaks the calm baseline) |

### 7.5 Panel Anatomy

System for all current and future panels (exact dimensions lock at implementation against the final font):

- **Base spacing unit 8px** (half the committed 16px edge-inset — one rhythm, not two numbers). Panel internal padding 2 units; row spacing 1 unit.
- **Header divider:** 1px hairline one tonal step lighter than the chrome fill (a single reserved "chrome edge" tone — never a new hue), once per panel under the header only.
- **Panel outer edge:** 1px hairline in the same chrome-edge tone — never a drop shadow (elevation implies depth, contradicting §3.4). Needed because panels float over a variable-brightness world.
- **Corner radius: 0, universally** — the single rule that makes every future panel a sibling; never relitigated per-screen.
- **Icon+label rows:** inline icon tier + one spacing unit vertical padding, label baseline on the icon's vertical center.

All panels: fill `#262220`, sharp corners, Hearth Gold for active/selected, progress bars without easing. **The projects panel is slice-validated but has NO written UX spec — it needs `design/ux/projects-panel.md` before its production visual layout is locked** (ux pass Conflict 5); until then its slice layout is provisional guidance, checked against the existing overflow-home precedent rather than a new density pattern.

### 7.6 Open Handoffs from the UX Pass

| Item | Owner | Note |
|---|---|---|
| Door/window discoverability affordance | Production building-ui UX spec | The playtest's confirmed failure: "door = wall gap" was not discoverable. Needs a visual affordance class for "this gap functions as a door" — obeying shape+label-never-hue, no new geometry exception. Door/window ITEMS (already a production requirement) may solve this outright; the affordance question stands until they do. |
| Pause dim/desaturation values | §7 at implementation | Provisional: dim to ~60% brightness, desaturate chrome-free world only — **state-carrying markers (distress icons, unreachable ghosts, invalid afterglow) are exempt from desaturation** so A1's hue channel survives pause (ux pass Conflict 6). Values tuned on screenshots at implementation. |
| projects-panel.md UX spec | /ux-design | Prerequisite for locking the projects panel visual layout (7.5). |
| Dusk Test + grayscale pass | QA checklist | Added alongside the existing A1 grayscale gate (7.1). |

---

## 8. Asset Standards

Every asset serves Sections 1–4: it must read at settlement AND expedition distance (Principle 4), respect the warm/cool split (Principle 1), stay axis-aligned and hard-edged unless vegetation (§3.2), and trace its colors to a Section 4 swatch. §8.1–8.8 are the art standards; §8.9 the engine constraints (technical-artist, with measured numbers from ADR-0014/slice).

### 8.1 Asset Categories & Pipeline

| Category | Source Tool(s) | Godot Representation |
|---|---|---|
| Structural block textures | MagicaVoxel palette-ref or hand-painted tile → packed atlas | Chunked-mesher atlas UV on the canonical terrain ShaderMaterial |
| Fixture/furniture models | MagicaVoxel `.vox` → Blender (bake, vertex-color, export) | Packed `.tscn` (unique heroes) or MultiMesh (repeated) |
| Character models | MagicaVoxel `.vox` → Blender (rig, bake) | Packed `.tscn`, simple skeleton |
| Vegetation | MagicaVoxel clusters or Blender billboards | MultiMesh instances / billboarded quads |
| VFX textures | Hand-painted / Blender-baked | Sprite sheets, GPUParticles3D materials |
| UI icons | Vector source → flat PNG | Control textures, single UI atlas/theme |

### 8.2 Naming Convention

Extends `[category]_[name]_[variant]_[size].[ext]` — each category fixes what "size" means:

| Category | Pattern | Example |
|---|---|---|
| Structural textures | `env_[material]_[face]_##_texel.png` | `env_timber_side_01_texel.png` (`face` = top/side/bottom; literal `texel` suffix asserts the one approved density) |
| Fixtures | `prop_[name]_[material-variant]_[footprint].vox` | `prop_bed_oak_1x2.vox` (footprint = cell dimensions W×D) |
| Characters | `char_[name]_[variant]_[pose/anim]_##.vox` | `char_villager_male_idle_01.vox` |
| Vegetation | `veg_[type]_[variant]_[canopy-size].vox` | `veg_tree-pine_var01_large.vox` |
| VFX | `vfx_[effect]_[loop\|burst]_[size].png` | `vfx_ember_burst_small.png` |
| UI icons | `ui_icon_[name]_[state]_[px].png` | `ui_icon_hammer_default_24.png` |

### 8.3 Texture Resolution & Texel Density

The slice's Minecraft-readability look is a texel-density decision, locked as a standard:

> **CONFIRMED (user decision 2026-07-23): 16 px per block-face edge**, project-wide, one tier. **Alternative considered:** 8 px — chunkier/more toy-like, but too coarse for Hearth Gold trim to read as trim.

- **One texel tier, project-wide.** Mixing densities in one atlas breaks Blocky Honesty (some faces read "more real" than others) — hard forbid.
- **Filtering:** nearest-family only, no blur (engine specifics in §8.9.7 — mipmapped-nearest for world, pure nearest for UI). Distance falloff is carried by fog + height-band vertex color, never by texture blur.
- **No per-asset resolution exceptions.** Finer detail = more distinct per-face pattern within the same pixel budget, never a higher-res tile.

### 8.4 Palette Discipline

Every color must trace to a Section 4 swatch within these deviation bands:

| Family | Hue | Saturation | Value | Rationale |
|---|---|---|---|---|
| Function (Gold) & State (Blue/Orange) | locked, 0° | ±5% | ±10% | Meaning-carrying colors — re-hueing breaks the §4.6 assumptions |
| Material, Ambient, terrain bands | ±5° | ±10% | ±15% | Allows face-shading variants, weathering, "aged timber" without hue drift |
| Vegetation | inside Material family (greens/browns) | as needed | as needed | Never drifts into the Function-gold band (§3.2) |
| Threshold Cool, Corruption (§5.5) | locked | locked | locked | Atmosphere/threat values, not paintable swatches |

**Check:** sample the finished asset's palette against the nearest swatch — outside the band means wrong reference or off-model color; fix the asset, not the rule.

### 8.5 Voxel Model Resolution (Sub-Cell Detail)

> **CONFIRMED (user decision 2026-07-23): 16 voxels per cell edge** as the authoring density for fixtures and characters — the user explicitly chose the finer tier over the recommended 8 to give Function fixtures real crafted detail (flame cutouts, carved backs). **Cost caveat (technical-artist, binding):** 16 v/c doubles per-axis voxel count; the Blender bake MUST merge/optimize so exports still meet §8.9's triangle ceilings (voxel count ≠ triangle count) — the first fixture pass validates import/bake cost before the tier is beyond revisit.

- **One density tier across fixtures and characters** — hero/supporting differentiation comes from silhouette + Gold trim (§3.3), never from a finer grid on heroes.
- **Multi-cell footprints** (e.g. the 1×2 bed) are authored as ONE continuous model spanning the cells — footprint is a placement concept, not a modeling seam.
- **Characters:** 2 cells tall, §5.2 proportions, same density — villager and bed share one visual "grain" in the same frame.
- Sub-cell detail stays inside the cell bounding box; unmistakably blocky, never organic/smoothed.

### 8.6 LOD Expectations per Category

| Category | Settlement distance | Distant | Note |
|---|---|---|---|
| Structural blocks | Full mesher output | No texture LOD — distant read via vertex-color banding + fog, never mip-blur | Streaming per ADR-0014 |
| Fixtures | Full authored model | Silhouette-only proxy in the same palette family (the §2.6 landmark pattern) | Swap distance: §8.9 |
| Characters | Full model | §5.7 table — warm accent is the LAST thing to LOD out | Budgets: §8.9 |
| Vegetation | Full billboard/cluster | Folds into terrain banding; culls/impostors beyond settlement radius | Thresholds: §8.9 |
| VFX | Near-camera by nature | A distant beacon VFX inherits the carrying-element contrast rule, not a resolution rule | — |
| UI | Resolution-independent | N/A | — |

### 8.7 Export/Import Authoring Disciplines

- **Vertex color over flat texture** where the slice validated it (fixtures, characters, AO).
- **Flat per-face normals, no smoothing groups** — AO may gradient across a face; normals stay hard (smoothing fakes curvature, violating Principle 2).
- **Origin at the cell-grid minimum corner**, never centered — keeps snap math trivial; applied before export.
- **Palette baked at authoring time** — what passes the §8.4 check in the source tool is what ships; no runtime tint fixes.
- **Multi-cell models exported as one piece** (§8.5).
- **Color management:** Section 4 hex values must arrive in-engine with no unintended gamma shift (engine path: §8.9.10).

### 8.8 Review Checklist — "An asset passes when…"

1. **Silhouette test** (§3.1/§3.3): flat black at settlement distance (heroes/landmarks also at expedition distance) — category identifiable with zero color.
2. **Warmth test** (Principle 1): a Function fixture's unlit state reads visibly cooler/plainer than lit — warmth earned, never default-on.
3. **Grid honesty** (§3.2): flush, axis-aligned, no gaps/bevels/rounding; sub-cell detail inside its footprint box.
4. **Palette-swatch test** (§8.4): every color traces within band; Gold and State Orange never co-occur on one object.
5. **Density consistency** (§8.3/§8.5): one texel tier, one voxel tier — no asset quietly higher/lower fidelity than its peers.
6. **Hero/supporting hierarchy** (§3.3): next to a plain wall segment, a Function object visibly wins the eye.
7. **Colorblind pass** (§4.6): grayscale screenshot in context still communicates any state it carries. Plus the **Dusk Test** (§7.1) for orange-carrying elements.
8. **Naming & pipeline** (§8.1/§8.2): filename exact, produced via the specified chain, source file retained.

### 8.9 Technical Constraints (Engine & Performance — technical-artist)

> Cross-referenced to technical-preferences.md (60 FPS / ≤2000 draw calls / 4 GB) and ADR-0014. **MEASURED** = from the validated prototype; **PROPOSED** = needs sign-off once real assets exist. Godot 4.7 APIs post-dating the LLM cutoff are flagged — verify against `docs/engine-reference/godot/` before use.

#### 8.9.1 Terrain / Chunk Meshes (canonical)
- 1 ArrayMesh per 16×16-column full-height chunk. **MEASURED:** 1,293 draw calls max at view_radius 24 (~380 m); 1.1 ms avg rebuild per edit.
- Exactly **one** ShaderMaterial for all terrain (atlas + vertex-AO + y_cut) — canonical contract.
- No terrain LOD tier; distant read = vertex-color ramp + fog. Greedy meshing stays a named reserve (ADR-0014).
- **Open defect, scheduled:** faces wound OpenGL-CCW; Godot fronts are CW — slice ships CULL_DISABLED (doubles fragment/overdraw cost, NOT draw calls; 60 FPS held with ~10x headroom). **Rule: CW rewind + re-enabled culling lands before fixture/vegetation/character counts scale past slice levels.**
- **Reject if** any terrain surface introduces a new unique ShaderMaterial instead of a new atlas region — the fastest way to blow the draw-call budget.

#### 8.9.2 Fixtures
- **PROPOSED** LOD0 ≤150 tris (Function-tier heroes), ≤60 tris (Material-tier props); LOD1 ≤40/≤20, swap ~60 m or >150 instances in view.
- **≥~8 instances of a type ⇒ MultiMeshInstance3D mandatory**; individual MeshInstance3D reserved for unique low-count heroes.
- Fixtures sample the shared atlas/material wherever the language allows — color families are texture regions, not materials.
- **Deferred conflict (per-fixture decision when concepts exist):** unique hand-painted hero-fixture textures vs strict atlas discipline. Unique textures risk a second differently-filtered material (draw-call multiplication) + linear texture-memory growth; strict atlas risks flatter heroes than Warmth-as-Reward wants. Decide per fixture, art-director + technical-artist together.

#### 8.9.3 Characters & Animation
- **PROPOSED** LOD0 ≤600 tris; LOD1 ≤200 or billboard beyond ~100 m (squad-on-delve is the main far case).
- **Skeletal animation (Skeleton3D + AnimationPlayer/Tree)** — 6–10 bones, trivial skinning cost, standard glTF pipeline. ≤2 draw calls per character (body + one accessory sharing the atlas).
- IK: not now — SkeletonModifier3D IK is 4.6+ (post-cutoff, verify) and blocky cycles don't need foot-planting; revisit on visible contact issues.
- Vertex/shader animation rejected at single-digit character counts; **re-open if crowds (dozens visible) ever land** — at that count per-instance skeletal draw calls become the bottleneck.

#### 8.9.4 Vegetation
- Grass/small plants: cross-quad billboards 2–4 tris. Bushes/trees: ≤80 tris LOD0, billboard/impostor beyond ~100 m.
- **MultiMesh mandatory** — vegetation is high-instance by design; individual nodes here is exactly the GridMap failure mode ADR-0014 replaced.
- Alpha-cutout foliage may need the second atlas (8.9.7).

#### 8.9.5 VFX / Particles (reserved budget — the debrief's #1 gap)
- GPUParticles3D preferred. **Flag:** Windows defaults to D3D12 since 4.6 (post-cutoff) — verify particle/compute behavior on target hardware.
- **PROPOSED:** ambient emitters ≤50 particles; bursts ≤100; ≤20 concurrent systems (each is a draw call).
- **Explicitly reserve headroom for ambient-life VFX now** — do not let fixtures/vegetation fill the remaining ~700 calls first.
- `AreaLight3D` (new in 4.7, post-cutoff — verify) is worth a spike for the warm window/hearth beacon before particle-glow hacks.

#### 8.9.6 UI
- Single UI atlas/theme (nine-patch panels), standard CanvasItem batching.
- **World-space UI is not free:** billboarded icons are 3D draw calls — count against world headroom, not the UI budget.

#### 8.9.7 Atlas Strategy
- With the locked 16 px/face tier: **2048×2048 terrain atlas = 128×128 tile capacity** — generous; PROPOSED as the ceiling.
- **Hard cap: 2 atlases total** through early Production (terrain + one differently-filtered atlas for foliage-cutout or fixtures); a 3rd needs technical-director sign-off.
- **Filtering: NEAREST_WITH_MIPMAPS for world textures** (pure nearest shimmers/sparkles at the ~380 m view edge — fails the Horizon Test); **pure nearest reserved for UI icons** (fixed close distance). Confirmed as default with an art-director review hook once real assets exist. Anisotropic off/1× project-wide (realism cue that fights flat readability; revisit only on grazing-angle blur complaints).
- **UV padding (duplicate-edge borders sized to the deepest used mip) is mandatory** — prevents mip bleed between atlas regions.

#### 8.9.8 Draw-Call Ledger
- Terrain **MEASURED** ~1,293 of ≤2000 at full radius (driven by the view window, NOT world size) ⇒ **~700 calls of headroom for everything else — tight, which is why the MultiMesh rules are hard rules.**
- Extending view radius scales chunk count quadratically — distant reads use silhouette proxies (the §2.6 landmark pattern), never a bigger radius.
- CULL_DISABLED affects overdraw, not draw calls — do not conflate the two when discussing headroom.
- **Reject if** a new asset category lands without a stated worst-case draw-call cost (fixed MultiMesh batch count, not per-instance estimates).

#### 8.9.9 Memory Math — the 16k Question
- **MEASURED:** 172 MB full-world chunk data at 2000×2000×32, allocated at boot (ADR-0014).
- **Projected 16,000×16,000×32: ~64× area ⇒ ≈11 GB chunk data — ~3× OVER the 4 GB ceiling before any asset loads.** The "allocate full world at boot" premise does not survive 16k. **This is the headline question of the ADR-0014-successor streaming spike** (paged/on-demand chunks, sparse far-region representation, or reduced persisted footprint) — already tracked as a production requirement.
- Save files scale the same ~64× (worst-case ~10–16 GB uncompressed) — the spike also answers compression/partial persistence.
- Draw calls are NOT the 16k risk (view window decouples them); texture memory is not the bottleneck either — world storage dominates. Do not let the 16k conversation default to "LOD/culling work."

#### 8.9.10 Import Settings
- **Lossless (RGBA8) for the pixel atlases** — VRAM/block compression (BC/S3TC/ETC2) quantizes 4×4 blocks and smears the exact hard texel edges Principle 2 protects. The atlas is small and singular by design, so the uncompressed VRAM cost is acceptable; re-check once the atlas resolution is final. Skybox/continuous-tone textures may use VRAM compression.
- Mipmaps enabled (required by 8.9.7). Repeat off/clamped (mesher samples fixed UV rects). sRGB/linear path chosen so Section 4 hex values arrive unshifted (8.7).

#### 8.9.11 Hard "Reject If" Gate
1. New unique terrain ShaderMaterial instead of an atlas region.
2. ≥8-instance asset placed as individual MeshInstance3D instead of MultiMesh.
3. Character/fixture without LOD1, or over its tri ceiling, without a technical-artist exception.
4. Pixel-atlas imported VRAM-compressed instead of Lossless (exception: side-by-side comparison + sign-off).
5. New asset category without a stated worst-case draw-call cost against the ledger.

---

## 9. Style Prohibitions

Every prohibition below traces to a rule already locked in §1–8 or a failure mode this project already lived through. Nothing here is a new taste call — this is the guardrail layer, written so a contributor (human or AI) who has only read this section still can't drift off-model.

1. **Never round, bevel, chamfer, or gap structural geometry, and never fake curvature with smoothing groups.** Blocky Honesty (§3.2, Principle 2) is non-negotiable for wall/floor/roof/foundation blocks; readability is a texture/lighting/AO problem, never a geometry problem (§8.7's flat per-face normals rule exists for the same reason). The winding/culling saga (REPORT.md — Godot's CW-front convention vs. our CCW habit) is the same lesson at the pipeline level: a geometry rule audited only against internal convention, not the engine's actual behavior, produced the "missing faces" incident for weeks. Validate against the engine, not habit.

2. **Never introduce a hue outside the Section 4 swatch table — red included.** The slice's red demolition overlay did not survive into production for exactly this reason (§7.1): red is not a palette hue, and red–green is a forbidden accessibility axis regardless (`visual-direction-note.md` §3, carried into §4.6). Any "danger" read is State Orange, full stop.

3. **Never let a State color (Blue or Orange) touch world/terrain geometry.** §4.1 and §4.6 make this structural, not aesthetic: State color's entire colorblind-safety argument depends on it living only in UI/overlay chrome, paired with shape+label. A State hue on a block or the terrain mesher output breaks that assumption silently.

4. **Never let Hearth Gold appear on plain Material blocks, terrain, or vegetation base color.** Gold means "this fixture does something" (§3.3, §4.1) — its entire job is to win the eye against supporting geometry. Gold on a wall segment or a bush erases the very contrast Warmth-as-Reward depends on, and collapses the §8.4 palette-discipline check.

5. **Never light a default scene with neutral-white or harsh/"true-midday" light.** §2.1 commits to a *permanent* golden-hour bias — there is no neutral lighting state in this game's default mood. Reintroducing neutral-white light is the single fastest way to violate the One-Line Rule (§1): a built space stops reading warmer than its surroundings if the surroundings stop reading cool by comparison.

6. **Never let a grounding/darkening technique crush the frame's ambient-fill.** §2.1 specifies "soft, high-ambient-fill shadows, not dramatic ones" — this is a measured lesson, not a preference: the slice hit it twice (PSSM's blanket-shadowed-the-whole-scene defect, and SSAO at intensity 2.5 crushing the whole scene, both documented in `game_world.gd` and REPORT.md). The shipped fix — single orthogonal shadow split, SSAO disabled, gentle vertex-baked AO — is the floor, not a temporary workaround; any future lighting pass must re-clear this bar.

7. **Never source ambient light from the sky/environment map without an explicit warm override.** The slice's default sky-sourced ambient "tinted everything blue-grey and crushed the ground read" until overridden with a warm flat `AMBIENT_SOURCE_COLOR` (`game_world.gd`, found via A/B render). §2.1's warm-neutral base and §2.2's "cooler but not hostile" expedition light both depend on ambient color being an authored choice, never whatever the sky averages to.

8. **Never leave torch/lantern (or any) light-energy flicker uncapped.** §6.5 names this explicitly: flicker "must respect A5 (sub-3Hz) — no free pass on flicker rate," because the beacon-in-the-dark read (§2.4) depends on flicker signaling "alive," not registering as a flash trigger.

9. **Never build world geometry or materials in a PBR (albedo/normal/roughness/metallic) pipeline.** §6.2 is explicit and slice-validated: PBR's specular/roughness realism fights both Blocky Honesty and the permanent warm-diffuse lighting model. Procedural/hand-painted chunky-texel only.

10. **Never mix texel or voxel-authoring densities within a project, atlas, or side-by-side asset pair.** §8.3 (16px/face, one tier) and §8.5 (16 voxels/cell, one tier) both call this a "hard forbid" — mixed density makes some faces read "more real" than others, a direct Blocky Honesty violation, not a quality question.

11. **Never import a pixel atlas as VRAM-compressed (BC/S3TC/ETC2).** §8.9.10 requires Lossless RGBA8 for exactly one reason: block compression quantizes 4×4 texel blocks and smears the hard texel edges Principle 2 protects. This is a Reject-If gate item (§8.9.11), not a style suggestion.

12. **Never blur a texture, or rely on texture-mip falloff, to sell distance.** §8.3 and §8.9.7 assign that job entirely to fog and height-band vertex color — nearest-family filtering only. A blurred texture at range competes with the Horizon Test's silhouette-and-fog language instead of supporting it.

13. **Never round a UI panel corner, add a drop shadow, skeuomorph a control, or animate a panel's show/hide (including idle "breathing" glows/pulses) — and never encode a stateful signal in hue alone.** §3.4 and §7.5 lock corner-radius at 0 universally; drop shadows are rejected by name; §7.4 defaults everything unlisted to instant zero-duration swap and names ambient breathing chrome a non-starter. §4.6 (A1) closes the loop: every stateful icon needs shape + label — the rule the Dusk Test (§7.1) and grayscale pass (§8.8.7) exist to enforce.

14. **Never exceed the accessibility motion ceiling: no screen shake, no flicker/pulse above 3 Hz, no parallax or other vestibular effect.** A5 is a hard cap referenced throughout §2–§7 — never a per-feature judgment call, and no mood or "juice" argument overrides it.

15. **Never bring in Minecraft/Mojang assets, or any unsourced one-off import lacking a retained source file, or a centered (non-grid-minimum) origin.** REPORT.md is explicit: Minecraft supplies *style* reference only, never asset content ("blocks as in Minecraft: style yes, Mojang assets NO — own art per Art Bible"). §8.1/§8.2/§8.7 cover the rest: every asset traces through the named tool chain, keeps its source file, bakes its palette at authoring time, and exports with its origin at the cell-grid minimum corner — an asset skipping any step can't be verified against §8.4/§8.8 later.

16. **Never approve an asset that only reads correctly at close range.** Principle 4 (the Horizon Test) is the bible's most load-bearing rule at this world scale: every silhouette test in §3.1/§3.3/§5.2 and every LOD rule in §8.6 exists because "home," "wilderness," and "danger" must be distinguishable from ~380m through fog. An asset with no expedition-distance read has failed review even if it's polished up close.

**When in doubt:** run the One-Line Rule (§1) first — does this keep a built space reading warmer and more alive than its surroundings, from the doorway to the horizon? Then run whichever design test the affected principle names (§1's Design Tests, the Horizon Test, the Dusk Test §7.1, the grayscale/colorblind pass §4.6/§8.8). If a choice passes every named test and still isn't covered above, it's not a prohibition gap — flag it to the art-director for a new rule rather than treating silence as permission.
