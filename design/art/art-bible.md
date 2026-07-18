# Art Bible: PetQuest

*Created: 2026-06-26*
*Last Updated: 2026-07-14*
*Status: Sections 1–5 Complete · Sections 6–9 Pending*
*Visual Identity Anchor: Cozy Chibi Neighborhood*
*AD-ART-BIBLE Sign-Off: Pending (Lean mode — skipped)*

---

## Sections

| # | Section | Status |
|---|---------|--------|
| 1 | Visual Identity Statement | ✅ Complete |
| 2 | Mood & Atmosphere | ✅ Complete |
| 3 | Shape Language | ✅ Complete |
| 4 | Color System | ✅ Complete |
| 5 | Character Design Direction | ✅ Complete (2026-07-14) |
| 6 | Environment Design Language | 🔲 Pending |
| 7 | UI/HUD Visual Direction | 🔲 Pending |
| 8 | Asset Standards | 🔲 Pending |
| 9 | Reference Direction | 🔲 Pending |

---

## Section 1: Visual Identity Statement

### One-Line Visual Rule

> *"Mọi thứ trong PetQuest phải trông như muốn được ôm — ấm áp, tròn trịa, và an toàn như một buổi chiều ở nhà."*

### Supporting Principles

**P1 — Pastel Warmth** *(serves Pillar 5: Mỗi bé có thế giới riêng)*

Palette giới hạn trong tông pastel bão hòa vừa phải. Không có màu neon, không có màu "aggressive". Mỗi màu phải pass test: *"Đây có phải màu bạn thấy trong một buổi chiều ấm áp ở nhà không?"*

- **Design test**: Nếu một element trông "cảnh báo" hoặc "nguy hiểm" với màu sắc → đổi sang pastel version hoặc dùng shape + text thay vì đỏ/đen.

**P2 — Round Over Sharp** *(serves Pillar 3: Khoe đẹp không đánh nhau)*

Mọi asset — thú cưng, nhà, item trang trí, button UI — ưu tiên đường cong và góc bo tròn. Không có góc nhọn ở primary elements. Góc nhọn chỉ xuất hiện ở decorative items hiếm (mũ phù thủy, kiếm đồ chơi) như điểm nhấn, không phải ngôn ngữ chính.

- **Design test**: *"Một đứa trẻ 6 tuổi có muốn chạm tay vào cái này không?"* Nếu không → bo tròn thêm.

**P3 — Expressive Animation** *(serves Pillar 2: Thú cưng là hình ảnh của bé)*

Thú cưng phải communicate mood hoàn toàn qua body language — không cần UI text. Mỗi emotional state có signature animation riêng. World elements cũng "thở" nhẹ: cây lay, đèn nhấp nháy, hoa lắc lư.

- **Design test**: *"Nếu tắt hết text/icon UI, người xem vẫn biết Mochi đang vui hay buồn không?"* Nếu không → animation chưa đủ expressive.

---

## Section 2: Mood & Atmosphere

### Game States & Mood Targets

| Game State | Emotion Target | Lighting Character | Atmosphere | Energy Level |
|---|---|---|---|---|
| **Pet Room (default)** | Ấm áp, tự hào, thư giãn | Ánh sáng chiều muộn — vàng ấm, low contrast | Cozy, sống động, còn đồ lung tung một chút | Contemplative |
| **Task Submission** | Hào hứng, phấn khởi | Flash sáng ngắn — warm white → trở về room light | Celebratory, brief burst | Measured |
| **Mochi SAD state** | Nhẹ lo lắng, muốn chăm sóc | Desaturated, xanh lạnh nhẹ, soft shadow | Quiet, một mình, chờ đợi | Low — gợi empathy |
| **Mochi HAPPY state** | Vui vẻ, tự hào, ấm áp | Warm golden, particles bay | Lively, sparkly, celebratory | Upbeat |
| **Shop** | Háo hức, mong chờ | Bright warm spotlight trên items | Boutique nhỏ, cuốn hút, magical | Measured excitement |
| **Social / Neighbor visit** | Thân thiện, tò mò | Warm outdoor light — như ban ngày trong khu xóm | Open, welcoming, slight wonder | Social, light |
| **Parent Approval view** | Tin tưởng, ấm lòng | Soft purple — phân biệt rõ với child view | Calm authority, trustworthy | Low, deliberate |

### Overarching Atmosphere Rule

PetQuest không có ngày xấu — ngay cả khi Mochi buồn, world vẫn cozy. Mood thay đổi là **invitation** (mời bé làm task), không phải **punishment** (trừng phạt bé).

Không bao giờ dùng: dark vignette, harsh shadow, desaturated hoàn toàn, hay bất kỳ thứ gì gợi cảm giác "thất bại" hoặc "nguy hiểm thật".

---

## Section 3: Shape Language

### Character Silhouette Philosophy

- **Thú cưng**: circular primary silhouette — body là hình tròn hoặc oval, đầu lớn hơn thân (head-to-body ratio 1:1 hoặc lớn hơn). Chibi cực đoan.
- **Thumbnail readability**: đọc được rõ ràng ở 48×48px — đây là kích thước icon trong social feed.
- **Distinguishing trait**: mỗi loại thú có một feature đặc trưng chiếm ≥30% silhouette (tai dài, đuôi cong, sừng nhỏ) — không cần nhìn màu vẫn nhận ra loại thú.
- **Accessories/items**: nhỏ hơn, float xung quanh pet — không che silhouette chính của thú.

### Environment Geometry

- **Nhà/phòng**: rounded rectangles — tường có góc bo, cửa sổ oval, mái cong nhẹ. Gợi nhớ đồ chơi dollhouse.
- **Props/đồ nội thất**: tỷ lệ hơi phóng đại (ghế to, bàn thấp) — world of a child's imagination.
- **Không có đường thẳng tuyệt đối** — mọi thứ hơi "wobbly" như vẽ tay, không phải CAD precision.

### UI Shape Grammar

- **Buttons**: pill-shaped hoặc rounded rectangle, corner radius ≥12dp. Không có sharp corners.
- **Cards/panels**: corner radius 12–20dp.
- **Icons**: outlined với stroke dày (2–3px), filled với solid pastel.
- **UI echoes world aesthetic**: dùng cùng màu palette và round language — không tạo "second visual language" tách biệt game và UI.

### Hero vs. Supporting Shapes

| Shape Role | Shape Type | Examples |
|---|---|---|
| **Hero** (draws eye) | Circles, large ovals | Pet body, primary CTA buttons, reward items |
| **Supporting** (recedes) | Soft rectangles | Room background, task cards, info panels |
| **Decorative** (variety) | Mixed | Shop items, seasonal decorations |

---

## Section 4: Color System

### Primary Palette

| Swatch | Name | Hex | Role |
|---|---|---|---|
| 🟡 | **Cream Ivory** | `#FFFDF0` | Background chính — nền của thế giới, ấm và sạch |
| 🟢 | **Mint Breeze** | `#A8E6CF` | Energy / nature / growth — energy bar, garden, healthy state |
| 🍑 | **Peach Glow** | `#FFCBA4` | Warmth / reward / celebration — header gradient, reward popups |
| 🩷 | **Petal Pink** | `#FFB5C8` | Joy / friendship / social — Mochi happy state, social elements |
| 🟣 | **Lavender Soft** | `#C5A3E0` | Parent / trust / approval — parent view, verified badges |
| 🟡 | **Honey Gold** | `#FFD060` | Achievement / coins / reward — xu currency, level badges |
| ⚪ | **Cloud White** | `#FFFFFF` | Cards, panels, clean surfaces — contrast layer |

### Semantic Color Usage

| Semantic | Color(s) | Backup Cue |
|---|---|---|
| Reward / positive | Honey Gold + Peach Glow | Icon + sound |
| Energy / health full | Mint Breeze → Peach Glow gradient | Bar width |
| Mochi SAD | Desaturate palette → grey-lavender, cool tint | Body language animation |
| Mochi SUPER HAPPY | Increased saturation + Petal Pink sparkles | Bounce animation |
| Parent zone | Lavender Soft dominant | Tab label + icon |
| Warning / alert nhẹ | Orange-peach với ⚠️ icon | KHÔNG dùng đỏ thuần |
| Seeds currency | Mint Breeze tông | 🌱 icon |
| Coins currency | Honey Gold | 🪙 icon |

**Rule**: Không bao giờ dùng `#FF0000` hoặc `#000000` thuần trong primary UI elements.

### Text Colors

| Usage | Color | Hex |
|---|---|---|
| Primary text | Warm dark brown | `#3D2B1F` |
| Secondary text | Warm medium brown | ~~`#9B7060`~~ **`#553826`** |
| Disabled text | Warm light brown | ~~`#C0A898`~~ **`#644A3C`** |
| ~~On-color text (buttons)~~ Button text | ~~White~~ **Primary text (warm dark brown)** | ~~`#FFFFFF`~~ **`#3D2B1F`** |

> ⚠️ **Sửa 2026-07-14** (tiếp tục contrast audit 2026-07-13, xem `design/accessibility-requirements.md`): Secondary và Disabled text đều fail contrast ở MỌI màu nền palette với hex gốc. Đã darken cả 2 để đạt ngưỡng WCAG thật, đo bằng contrast ratio thấp nhất trong 7 màu nền (worst-case, không phải trung bình):
> - **Secondary**: `#9B7060` (worst-case 1.99:1) → `#553826` (worst-case 4.89:1) — đạt chuẩn AA normal-text 4.5:1 ở TẤT CẢ 7 nền.
> - **Disabled**: `#C0A898` (worst-case 1.04:1) → `#644A3C` (worst-case 3.75:1) — đạt chuẩn AA large-text/UI-component 3:1 ở TẤT CẢ 7 nền (WCAG 1.4.3 miễn trừ strict rule cho inactive/disabled control, nhưng vẫn cần đọc được nếu mang thông tin thật).
> - Thứ tự đậm-nhạt vẫn giữ đúng phân cấp thị giác: Primary (`#3D2B1F`, đậm nhất) > Secondary (`#553826`) > Disabled (`#644A3C`, nhạt nhất) — chỉ đủ nhạt hơn để phân biệt cấp độ nhấn mạnh, không nhạt tới mức fail contrast như bản gốc.

Không dùng `#000000` thuần — tất cả shadow và dark elements dùng warm dark brown.

> ⚠️ **Sửa 2026-07-13** (contrast audit thật, xem `design/accessibility-requirements.md` §"Text legibility"): vai trò "On-color text (buttons) = White" đã bị loại bỏ — đo WCAG thực tế cho thấy chữ trắng **fail contrast ở TẤT CẢ 7 màu nền trong palette này**, không có ngoại lệ (ratio 1.00–2.17, thấp hơn cả ngưỡng 3:1 cho large text). **Quyết định (2026-07-13)**: mọi nút bấm/button dùng palette làm nền fill đều dùng **Primary text** (`#3D2B1F`) cho label, không bao giờ dùng trắng, bất kể màu nền fill là gì trong 7 màu palette hiện tại. Nếu tương lai cần một nút "hero" với nền đậm/bão hòa hơn (khác hẳn palette nền pastel hiện tại) thì màu nền đó phải được thêm mới vào bảng trên và tự audit contrast riêng — không tái sử dụng 7 màu pastel hiện có làm nền cho chữ trắng.
>
> **Secondary text và Disabled text cũng fail contrast ở mọi nền** (xem audit) — đây là vấn đề còn mở, CHƯA được quyết định trong lần sửa này (chỉ giải quyết vai trò chữ trắng theo yêu cầu). Cần quyết định riêng sau: darken 2 màu này, hoặc giới hạn chúng chỉ dùng cho mục đích trang trí không phải text.

### Per-Area Color Temperature

| Area | Dominant Colors |
|---|---|
| Pet Room | Cream Ivory + Peach Glow (warm) |
| Garden / Outdoor | Cream Ivory + Mint Breeze (warm-cool neutral) |
| Shop | Cream Ivory + Honey Gold spotlight (warm, boutique) |
| Parent view | Cloud White + Lavender Soft (cool-warm) |
| Social / Neighbor visit | Peach Glow + Mint Breeze (warm outdoor) |

### Colorblind Safety

| Potential Issue | Mitigation |
|---|---|
| Coins (gold) vs Seeds (green) | Khác biệt màu + icon riêng (🪙 vs 🌱) → safe |
| Approved (green) vs Pending (yellow) | Icon + text label, không chỉ màu |
| Mochi mood states | Body language + text label, không chỉ màu |
| Warning vs Normal | Icon ⚠️ required, không rely vào red/green distinction |

---

## Section 5: Character Design Direction

*Authored 2026-07-14. References: Pokémon evolution design philosophy (Jigglypuff/Ditto-style softness), "Mochi Animal/Monster" character design aesthetic, Supercell mobile game character style (e.g. MO.CO).*

### 5.1 Mochi's Visual Archetype

Mochi is a single, original creature — a soft rice-cake/dumpling body with no fixed real-world species reference, so nothing about its shape can accidentally read as "just a rabbit" or "just a cat." The archetype blends three references directly:

- **Jigglypuff/Ditto-style softness** (Pokémon): one continuous rounded silhouette, minimal internal linework, no visible joints.
- **"Mochi Monster" aesthetic**: a glossy dumpling texture, a soft fold/seam suggestion at the base of the body, blush cheeks.
- **Supercell (MO.CO) readability**: thick clean outline, 2-3 flat color zones maximum, oversized simple eyes, zero fine detail that would vanish at small render size.

**Base silhouette**: oval-to-circular body, head-to-body ratio ≥1:1 (per Section 3), no visible limbs at Baby stage, small stub-limb hints appearing from Young onward — never articulated joints, never fingers. Body is always wider than tall or perfectly round; it must never read as vertically "standing tall" the way a humanoid would, which would break the huggable-blob read.

**Distinguishing trait (Section 3's ≥30% silhouette rule)**: two long, soft, teardrop-shaped ears, rounded at the tip (never pointed — pointed ears would violate P2 Round-Over-Sharp). Ears are the primary mood-animation surface: wiggle = happy, perk = alert/proud, droop = tired, flatten = sad, tuck = sleeping. Because mood reads through ear *position* independent of color, this reinforces Section 4's colorblind-safety requirement ("Mochi mood states: body language + text label, not color alone").

**Secondary growth marker**: a small round poof tail, visible from side/back angles, growing fuller across evolution stages. This is not the primary distinguishing trait (it doesn't need to hit 30% on its own) — it exists specifically to pay off the leveling GDD's existing player-fantasy line ("tai dài ra, đuôi bồng lên"), giving the tail a formalized design role instead of leaving it as unstructured flavor text.

**Design test alignment**: at 48×48px thumbnail (Section 3's social-feed floor), the ear silhouette alone must be enough to identify Mochi with zero color information — this is the concrete, testable version of Section 1's "would a 6-year-old want to touch this?" and P3's "text-off" test applied specifically to the character.

### 5.2 Evolution Stages

Three stages, mapped directly to the leveling GDD's Baby (L1) / Young (L2-3) / Grown (L4-5) structure. The growth story is told entirely through **silhouette continuity with added detail and confidence**, never through added sharpness, added limbs/joints, or a shift away from roundness — growth must never look like "toughening up," because Pillar 3 (no fighting) and Pillar 2 (pet mirrors the child's own growth, not power) both rule that out.

| Stage | Render size | Silhouette | Ears | Tail | Detail budget |
|---|---|---|---|---|---|
| **Baby (L1)** | 72dp | Near-perfect sphere, fully limbless | Long, soft teardrop ears drooping down alongside the head, rounded tips, relaxed/passive posture, ~30% of silhouette (same target proportion as later stages — see below) | Tiny closed nub, barely visible | 2 color zones: body + belly patch. Eyes largest of all 3 stages (~40% of face height) — maximizes "baby schema" cuteness (large head/eyes reads as inherently endearing) |
| **Young (L2-3)** | 112dp | Slightly elongated oval, tiny stub-limb hints appear | Same long teardrop length as Baby, but visibly narrower/more tapered toward the tip (distinct silhouette, not just angle — see 2026-07-18 amendment below), and begins to lift/perk forward — more alert posture than Baby's passive droop | Visibly poofs — first "growing" cue, pays off leveling GDD's fantasy copy directly | 3 color zones: body + belly patch + one new fold/mark accent (e.g., small heart or star fold). Eyes ~35% of face — first subtle sign of "growing up" |
| **Grown (L4-5)** | 152dp | Most elongated/oval of the 3, still fully round — never angular | Same long teardrop length, adds a confident gentle fold/curl at the tip (reads assured even in profile) — the growth story finishes here through posture/detail, not further lengthening | Fully poofed, large soft round shape | 3-4 color zones: adds a small ear-tip or cheek accent marking. Eyes ~30% of face — smallest of the 3 but still oversized by any realistic standard: "confident, not aggressive" |

**Silhouette proportion consistency**: ears occupy roughly the same ~30% silhouette share at every stage (not growing *disproportionately* faster than the body) — this preserves the Pokémon-style "recognizable soft silhouette across evolution" the reference explicitly asked for. What changes is ear *shape/posture/detail*, not the ratio.

> **Sửa 2026-07-15** (Baby-stage ear length amendment, made during first-pass asset production for `mochi-baby-mood-sprites.md`): Baby's ears were changed from "short, rounded stubs" to the same long teardrop shape as Young/Grown, at a relaxed/drooping posture. Reason: the delivered Baby sprite art was produced against a user-selected reference image using long drooping ears (not short stubs), and this amendment brings the spec back in sync with the actual approved art rather than leaving them contradictory.
>
> **Downstream consequence — flagged, not fully resolved**: the old short→long progression was how this section paid off the leveling GDD's player-fantasy line "tai dài ra, đuôi bồng lên" (ears lengthen, tail poofs up) through the ear trait specifically. With Baby's ears already long, that literal payoff no longer exists in the sprite art — the growth story for ears must now be told through *posture and detail* (droop → perk → confident curl, as reworded above) rather than *length*. This reframing is actually more consistent with this section's own "ears occupy ~30% at every stage" rule than the old table was (a short-stub-to-full-length jump was arguably already a disproportionate change). Two follow-ups this amendment does **not** resolve:
> 1. Young/Grown ear art is still deferred/unspecced (see `asset-manifest.md`) — the posture-based wording above is a placeholder to keep this document internally consistent, not a locked final decision. Revisit when those stages are actually specced.
> 2. The leveling GDD's "tai dài ra" fantasy-copy line itself may need rewording now that ears no longer visibly lengthen — that line lives in a different document (pet leveling/evolution GDD), out of scope to silently edit here. Flagging as a cross-document follow-up for whoever next touches that GDD.
>
> **Sửa 2026-07-18** (Follow-up #1 above, resolved during Young-stage asset-spec authoring): with Baby's ears now long teardrops, Baby and Young shared the exact same ear silhouette primitive — differing only by angle/posture (droop vs. perk), which risked being too subtle to distinguish at the mandatory 48×48px static readability test (no animation to sell the distinction at that size). **Resolved**: Young's ears now taper more pronouncedly toward the tip — visibly narrower near the tip than the base (while staying fully rounded, no pointed tip, per the round-over-sharp rule) — making the two stages differ in silhouette shape, not just posture. This amends the Young row's ear description below from "gains a soft taper" to this more pronounced version.

**Sprite size — CONFIRMED FINAL (2026-07-14)**: 72 / 112 / 152dp, confirmed as final, not provisional. Growth ratio (Baby→Young +56%, Young→Grown +36%) mirrors the leveling GDD's own pacing — the first evolution (L1→L2) is the biggest dramatic "wow" jump in the player-fantasy copy, so it should also be the biggest size jump; L2/3→L4/5 reads as continuation, not equal drama. These sizes are also the actual render ceiling since `pet-room-screen-ui.md` fixes max scale at 1.0 (no runtime scale-up), so all LOD decisions in 5.7 are budgeted against 152dp as the largest Mochi will ever appear on screen. This unblocks `pet-room-screen-ui.md`'s hit-area formula (was citing these as "Art Director recommendation, not final pin").

### 5.3 Base Mood States — Pose & Body Language

These build directly on `pet-state-machine.md`'s named animation beats and GDD-specified color tints; this section defines the concrete pose so an animator has something to draw from.

**HAPPY** (energy 80-100, Mint Breeze `#A8E6CF`, GDD beat: "nhảy nhẹ, tai vẫy")
Light continuous vertical bounce (bob, not a full jump — reserved for EXCITED). Both ears up and forward, alternating left-right wiggle each bounce cycle. Eyes wide open with a small white sparkle highlight. Mouth: open smile curve. Tail up, gentle sway. Cheek blush at its most saturated.

**CONTENT** (50-79, Peach Glow `#FFCBA4`, GDD beat: "thở đều, mắt chớp")
This is the default/most-seen state, so it must read as pleasant, not merely neutral. Relaxed idle stance, slow steady breathing scale-pulse on the body only (ears stay still). Ears at relaxed neutral droop — not perked, not flat. Soft closed-mouth smile line. Blink cycle roughly every 1.5s. Tail resting still.

**TIRED** (20-49, pale Lavender Soft, GDD beat: "ngáp, vai xệ")
Upper-body/shoulder silhouette visibly compresses (~10% vertical squash) to read as slumping. Ears asymmetric — one droops fully, one stays half-up — this asymmetry reads as "fighting to stay awake" more clearly than two evenly-drooped ears would. Periodic yawn beat: wide oval open mouth, eyes squeeze shut briefly, then return to half-lidded. Tail low and still.

**SAD** (10-19, Lavender Soft, GDD beat: "nằm xuống, mắt buồn")
Body lies down flat/low — silhouette flattens noticeably more than TIRED's still-upright slump, so the two low-energy states stay visually distinct. Ears fully flattened against the back of the head (not just drooped). Large downturned sad-eyes at the outer corners; optional single static teardrop icon (per GDD's optional particle). Small downward mouth curve. Near-motionless breathing. Per Section 2's atmosphere rule ("mood change is invitation, not punishment"), this pose must read as *"come play with me,"* not as visual failure-shaming — no darkened tint, no vignette, just a quiet, still, slightly droopy creature.

**SLEEPING** (=10, faded Cloud White, GDD beat: "ngủ sâu, Zzz float")
Curls into the tightest, roundest silhouette of all 5 states — ears tuck in against the body, tail wraps in if visible. Eyes fully closed (flat lines, no pupils). Breathing scale-pulse is the largest-amplitude, slowest-paced motion in the whole idle set (bigger than CONTENT's subtle pulse), since facial expression is otherwise fully "off." Floating "Zzz" particle drifts up and fades per GDD. The tightest/roundest pose of the cast is intentional — it's the clearest "needs care" signal in the whole state set.

### 5.4 Triggered States — Pose & Body Language

Same approach: concrete pose on top of the GDD's named beat, duration, and priority.

**LEVELING_UP** (highest priority, non-interruptible, 3s, "glow + grow; sprite swap if evolution level")
Brief anticipatory inhale (~0.5s body inflate), then a warm Honey Gold radial glow blooms from the body center (ties to Section 4's "achievement" semantic). Body silhouette grows via a squash-stretch overshoot-then-settle (overshoot ~110%, settle to the new stage's base scale). Both ears fully perk and flare outward at the glow's peak — a confident "ta-da" posture, distinct from any other state. Eyes closed-happy (^ ^), mouth wide joyful open-smile. On evolution levels (L2/L4) only, a cross-dissolve/cut swaps to the new stage's neutral CONTENT pose at the end. This is the single most important "wow moment" in the character set — it's the direct visual payoff of the leveling GDD's player-fantasy copy ("ánh sáng vàng toả ra... Mochi phát sáng, lớn dần lên").

**EXCITED** (task-approval payoff, scale bounce ×1.3 + sparkles, 1.5s)
Sudden strong vertical squash-stretch jump — the biggest, fastest motion of any state, deliberately more energetic than HAPPY's idle bounce so it reads as a distinct celebratory spike rather than "extra happy idle." Ears whip up and flutter rapidly. Eyes flash to bright wide star-shapes for one beat, then settle to wide-open+highlight. Big open-mouth cheer. Honey Gold sparkle burst radiates outward (per GDD spec). This is *the* emotional payoff moment named in the brief and must be visually unambiguous as the biggest pose in the cast.

**PLEASED** (pet/stroke interaction, eyes close + wiggle, 2s)
Deliberately calmer and more intimate than EXCITED — no jump, no sparkle burst — because this is a quiet one-on-one affection beat (direct touch), not a public celebration (task reward); the two "happy" reactions need a different emotional register or they collapse into each other. Gentle full-body side-to-side wiggle. Eyes scrunch fully closed in a held contented squeeze (longer-held than EXCITED's brief star-eyes). Small closed-mouth smile. Ears flop softly side-to-side following the wiggle — relaxed, not perked/alert. Subtle blush increase.

**SHOWING_OFF** (equip new item, spin 360°, 2s — per `pet-equipment.md`'s existing spec: 0.5s ease-out spin + 0.3s 8dp bounce-settle)
During the spin, a proud "chest-out" puff (slight body-center silhouette widen reads as pride). Ears flare outward/up at spin start — same family as LEVELING_UP's ear-flare but snappier/shorter, since this is confident-display rather than milestone-triumph. Eyes bright and open, closed-mouth proud smile (composed, not exuberant like EXCITED's open-mouth cheer). Equipped overlays spin rigidly as child components per the existing z-index rule. Critically, the body should **not** do a big vertical bounce during this beat — the equipped items must stay centered and visible through the full spin, since this pose is the visual proof-point for Pillar 5 ("đây là Mochi của mình") and the whole point is showing off what's equipped, not the pet itself.

**BOUNCING** (receive seed/pending task, small hop, 1s)
Intentionally the least dramatic triggered state, roughly half the vertical amplitude of EXCITED's jump. Single small ear flick (not sustained wiggle). Expression is carried over unchanged from the current Base Mood — BOUNCING only adds the hop, per the GDD's own tuning note ("subtle, không phải hero animation"). This restraint is deliberate: BOUNCING marks a *pending* task (not yet parent-approved), so its visual weight must stay proportionally smaller than EXCITED's full payoff — teaching the child through motion intensity alone that this is anticipation, not the reward. Celebrating too early here would cheapen the real EXCITED payoff and undercut Pillar 2's honesty (the pet reflects real, confirmed effort, not a promise of it).

### 5.5 Equipment / Accessory Overlay System — Visual Rules

Builds on `pet-equipment.md`'s 3-slot system (`body_outfit`, `hat`, `accessory`) and existing z-index order (`base(0) < body_outfit(1) < accessory(2) < hat(3)`).

**Per-stage anchor variants — CONFIRMED 2026-07-14 (amends `pet-equipment.md`, see Dependencies)**: 3 authored art variants per equipment item, one per evolution stage, sharing a defined anchor point per slot — not a single asset uniformly scaled across stages. Reasoning: Mochi's proportions change *qualitatively* between stages (bigger head-to-body ratio at Baby, longer/tapered ears and fuller tail at Grown), so an item authored to sit correctly on Grown's head/ears would misalign if merely scaled onto Baby's stubbier proportions. This decision amends `pet-equipment.md`'s prior "scale đồng nhất" (uniform scale) wording — see that GDD's updated Core Rules and Asset Production notes.

**Anchor points per slot** (for the 3-variant approach):
- `hat`: anchored to a point between the ears at each stage's specific ear-base position (moves as ears lengthen/reposition across stages)
- `body_outfit`: anchored to the torso center, scaled to the stage's body silhouette
- `accessory`: anchored to neck/back position, clear of the tail-poof area at each stage

**Silhouette-preservation rule (extends Section 3's "accessories never obscure the main silhouette")**: the ≥30% ear trait and the tail growth marker must both remain identifiable even at full 3-slot accessorization:
- `hat` items must be notched/shaped so ears remain **at least 50% visible** (poking through a gap, or the hat sitting further back on the head) — a hat that fully encases the ears is not permitted at any stage.
- `body_outfit` items must not extend into sleeve/collar shapes that cover the ear base or the tail-poof area — outfits stay torso-scoped.
- `accessory` items (e.g., a scarf) must not extend over the tail-poof region.

This keeps Mochi recognizable as *Mochi* — not just "a dressed-up blob" — in every social-feed thumbnail and Visit-System view, regardless of what a given child has equipped.

### 5.6 Expression / Pose Style Target

Target: **Expressive-to-Exaggerated**, capped short of full slapstick — the Kirby / Supercell (MO.CO) blend the references pointed at.

- **Movement beats** (bounces, spins, growth): full squash-stretch, real overshoot-and-settle, genuine physical weight and snap.
- **Facial expression**: stays iconic and simple — 2-3 stable mouth/eye shapes per state, no anatomical muscle deformation, no realistic proportion shifts. Expression reads through *timing and shape-language*, not through detail.

This split is deliberate: pure "subtle" motion would fail the P3 text-off test (moods wouldn't read without UI labels); full slapstick/anatomical exaggeration would fight Section 1's calm, huggable "afternoon at home" mood target. Expressive-to-Exaggerated is the point where both hold at once.

### 5.7 LOD Philosophy (Render Budget at 72-152dp)

Since 152dp is the hard ceiling (no runtime scale-up per `pet-room-screen-ui.md`), detail is budgeted against the *smallest* stage (72dp Baby), not the largest — anything that only reads at 152dp but disappears at 72dp is not usable, since both must represent "the same character" clearly at their native sizes.

- **Color zones**: cap at 2 (Baby) → 3 (Young) → 3-4 (Grown) flat zones — no gradients, no soft shading below a simple flat drop-shadow. Kept "sticker"-flat both for legibility at small size and because gradients don't survive well at 72dp on mobile screens.
- **Outline**: fixed absolute stroke weight (~2-3px) regardless of dp scale, consistent with Section 3's existing icon-stroke spec — a stroke that scales proportionally with sprite size would vanish at 72dp.
  > **Sửa 2026-07-14** (làm rõ khi `technical-artist` viết asset spec cho Mochi Baby): "2-3px tuyệt đối" áp dụng theo **dp hiển thị cuối cùng trên màn hình**, không phải raw-pixel trong file nguồn ở mọi density export. Khi xuất file nguồn ở density cao hơn 1x (ví dụ 3x, 216px cho hiển thị 72dp), outline phải vẽ thô hơn theo đúng hệ số density (~6-9px trong file 216px) để sau khi engine downscale, kết quả hiển thị vẫn đúng ~2-3dp. Đọc theo nghĩa đen "raw-pixel không đổi bất kể density xuất" sẽ khiến outline gần biến mất khi downscale — không phải ý định của rule này.
- **Facial features**: eyes and mouth are large, simple geometric shapes occupying a large % of face area at every stage — never small "realistically proportioned" features, which is the first thing to fail legibility at these sizes.
- **Growth detail is added only two ways**: (1) silhouette change (ear length/taper, tail fullness, body proportion) and (2) exactly one new small color-accent per stage (per the table in 5.2) — never through fine linework or texture detail, which is the first thing to alias/disappear on mobile rendering at small dp.
- Flat, low-zone-count color also keeps sprite-atlas footprint small, supporting the ≤200 draw-call budget — exact batching/atlas strategy is technical-artist's call, not specified here.

---

## Sections 6–9: Pending

*Sections 6–9 chưa được authored. Chạy `/art-bible` lại khi cần hoàn thiện:*

- **Section 6**: Environment Design Language
- **Section 7**: UI/HUD Visual Direction
- **Section 8**: Asset Standards (Flutter + Flame, mobile — 60fps, ≤150MB RAM)
- **Section 9**: Reference Direction (Animal Crossing, Stardew Valley, Kirby, Tamagotchi)

---

*References noted for Sections 6–9: Animal Crossing (Pocket Camp / New Horizons), Stardew Valley, Kirby, Tamagotchi Uni*
