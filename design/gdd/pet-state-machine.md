# Pet State Machine

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-06-28
> **Implements Pillar**: Pillar 2 — Thú Cưng Là Hình Ảnh Của Bé (pet mood mirrors real effort)

## Overview

Pet State Machine quản lý trạng thái cảm xúc và hành vi của Mochi — chú thú cưng trung tâm của PetQuest. Nó đọc `currentEnergy` từ Time & Decay System và dịch thành một trong 5 `MoodState`: HAPPY, CONTENT, TIRED, SAD, SLEEPING. Mỗi mood state định nghĩa animation set, màu sắc, và âm thanh của Mochi trong Flame game loop.

State machine còn xử lý các **triggered states** ngắn hạn — Mochi phản ứng tức thì với các sự kiện như nhận xu (EXCITED), mặc outfit mới (SHOWING_OFF), hoặc bị vuốt ve (PLEASED) — trước khi quay về mood state cơ bản từ energy.

Đây là system mà bé tương tác cảm xúc nhiều nhất — Mochi phải luôn cảm thấy *sống động* và *có phản ứng*, không phải một sprite đứng yên.

## Player Fantasy

Mochi là gương phản chiếu của bé. Khi bé nhìn vào Mochi:
- **Mochi nhảy tưng tưng, màu xanh mint sáng rực** → "Mình đã làm tốt tuần này."
- **Mochi ngáp ngủ, màu nhạt** → "Mochi đang cần mình, để mình làm bài tập đi."
- **Mochi bật dậy bounce khi approve đến** → khoảnh khắc magic mà bé muốn tạo ra mỗi ngày.

Triggered states tạo ra *surprise và delight*: bé vuốt ve Mochi → Mochi nhắm mắt rung rung hạnh phúc. Bé mặc outfit mới cho Mochi → Mochi xoay một vòng khoe. Những khoảnh khắc này không liên quan đến progression — chúng là **niềm vui thuần túy** của việc có một người bạn ảo thực sự phản ứng.

## Detailed Design

### Core Rules

**1. Two-Layer State Model**

Mochi có 2 lớp state đồng thời:
- **Base Mood** (persistent): từ energy — HAPPY/CONTENT/TIRED/SAD/SLEEPING
- **Triggered State** (temporary, 1–3 giây): từ events — EXCITED/PLEASED/SHOWING_OFF/BOUNCING

Triggered state override animation trong thời gian ngắn rồi tự return về Base Mood. Không thay đổi energy hay Base Mood.

**2. Base Mood States (từ Time & Decay GDD)**

| State | Energy | Idle Animation | Color | Loop |
|-------|--------|----------------|-------|------|
| HAPPY | 80–100 | Nhảy nhẹ, tai vẫy | Mint Breeze #A8E6CF | 2s |
| CONTENT | 50–79 | Thở đều, mắt chớp | Peach Glow #FFCBA4 | 3s |
| TIRED | 20–49 | Ngáp, vai xệ | Lavender Soft #C5A3E0 nhạt | 4s |
| SAD | 10–19 | Nằm xuống, mắt buồn | Lavender Soft #C5A3E0 | 5s |
| SLEEPING | =10 | Ngủ sâu, Zzz float | Cloud White mờ | 6s |

**3. Triggered States**

| Trigger | State | Animation | Duration | Return to |
|---------|-------|-----------|----------|-----------|
| Pet level up (Pet Leveling #16) | LEVELING_UP | Glow + grow; sprite swap if evolution level | 3s | Base Mood |
| Approve task | EXCITED | Scale bounce ×1.3 + sparkles | 1.5s | Base Mood |
| Pet/vuốt ve | PLEASED | Eyes close + wiggle | 2s | Base Mood |
| Equip new item | SHOWING_OFF | Spin 360° | 2s | Base Mood |
| Receive seed | BOUNCING | Small hop | 1s | Base Mood |

**4. Transition Rules**
- Base Mood transition: tức thì khi `currentEnergy` thay đổi qua threshold
- Triggered → Base Mood: sau `duration` giây, dùng `TimerComponent` trong Flame
- Triggered state priority (high → low): **LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING** — nếu trigger mới có priority cao hơn, reset timer và play animation mới; nếu thấp hơn, bỏ qua
- **LEVELING_UP là non-interruptible**: khác với các Triggered states khác, một khi LEVELING_UP đang play, KHÔNG trigger nào (kể cả EXCITED) được phép reset hay override nó giữa chừng — mọi trigger khác đến trong lúc này bị queue và replay sau khi LEVELING_UP kết thúc (xem Pet Leveling GDD #16, Edge Case 2)
- SLEEPING không nhận Triggered states thường — nhưng LEVELING_UP vẫn có thể fire kể cả khi ở SLEEPING (level-up không phụ thuộc energy); chỉ approve task (EXCITED) mới đánh thức khỏi SLEEPING theo cách thông thường

---

### States and Transitions

```
[Energy Input]
      │
      ▼
   energy >= 80 → HAPPY
   energy 50–79 → CONTENT
   energy 20–49 → TIRED
   energy 10–19 → SAD
   energy = 10  → SLEEPING
      │
      │ (event trigger — except SLEEPING)
      ▼
 EXCITED / PLEASED / SHOWING_OFF / BOUNCING
      │ (after duration)
      ▼
 [return to Base Mood]
```

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Time & Decay (#2) | → Pet State Machine | `currentEnergy` float | `energyProvider` StreamProvider |
| Flutter-Flame Bridge (#5) | → Pet State Machine | `GameEvent(petMoodChanged, MoodState)` | `GameEventBus` stream |
| Pet Interaction (#14) | → Pet State Machine | tap/swipe trigger | `GameEvent(petInteracted, InteractionType)` |
| Pet Equipment (#15) | → Pet State Machine | equip trigger | `GameEvent(itemEquipped, itemId)` |
| Pet Room Screen UI (#18) | ← Pet State Machine | current mood, energy | `petMoodProvider` Riverpod |

## Formulas

**Mood threshold formula (từ Time & Decay GDD — không thay đổi):**
```
MoodState = SLEEPING  if energy = 10
          = SAD       if 10 < energy <= 19
          = TIRED     if 20 <= energy <= 49
          = CONTENT   if 50 <= energy <= 79
          = HAPPY     if energy >= 80
```
Không có formula riêng — state machine là pure lookup table trên `currentEnergy`.

**Triggered state timer:**
```
returnAt = now + triggeredDuration
```
| Triggered State | `triggeredDuration` |
|----------------|-------------------|
| LEVELING_UP | 3.0s (non-interruptible) |
| EXCITED | 1.5s |
| PLEASED | 2.0s |
| SHOWING_OFF | 2.0s |
| BOUNCING | 1.0s |

## Edge Cases

- **Nếu energy thay đổi liên tục nhanh** (nhiều tasks approve cùng lúc): mỗi energy update trigger mood recalculation — Flame component nhận nhiều `petMoodChanged` events liên tiếp. `_clearEffects()` phải chạy trước mỗi animation mới (đã validate trong spike).

- **Nếu SLEEPING và approve task đến**: SLEEPING là ngoại lệ duy nhất nhận EXCITED trigger — Mochi "thức dậy" với bounce animation, sau đó transition lên Base Mood mới dựa trên energy sau recovery.

- **Nếu hai Triggered states trigger đồng thời** (bé vuốt ve đúng lúc approve): EXCITED ưu tiên hơn PLEASED — reset timer về EXCITED duration (1.5s), play EXCITED animation.

- **Nếu app foreground trong khi Triggered state đang chạy**: Flame game loop resume, `TimerComponent` tiếp tục đếm từ chỗ pause — không restart animation.

- **Nếu energy thay đổi nhưng mood state không đổi** (ví dụ: 85 → 90, vẫn HAPPY): không emit `petMoodChanged` event — chỉ update `energyProvider` value. Không gây unnecessary Flame re-render.

- **Nếu Mochi component chưa mounted khi event đến**: `isMounted` guard trong `_onEvent()` — event bị bỏ qua silently (từ Flutter-Flame Bridge GDD).

## Dependencies

**Upstream:**
- **Time & Decay (#2)** ✅: cung cấp `currentEnergy` và mood thresholds — không được thay đổi thresholds trong GDD này
- **Data Persistence (#4)** ✅: đọc `storedEnergy` khi app load; ghi không có (state machine là read-only với persistence)

**Downstream:**
- **Flutter-Flame Bridge (#5)** ✅: nhận `MoodState` changes → emit `GameEvent` → `MochiComponent`
- **Parent Approval (#11)**: gửi `GameEvent(taskApproved)` → EXCITED (xem GDD #11 Core Rules — emit sau khi approve transaction commit; event type riêng, thêm 2026-07-06, KHÔNG phải `petMoodChanged` — xem Flutter-Flame Bridge #5's GameEventType enum)
- **Seed Buffer Mechanic (#10)**: gửi task-submit trigger → BOUNCING (xem GDD #10 Core Rule 1 — "seed drop" moment)
- **Pet Interaction (#14)**: gửi interaction triggers → nhận Triggered states
- **Pet Equipment (#15)**: gửi equip trigger → SHOWING_OFF
- **Pet Leveling (#16)**: gửi level-up trigger → `LEVELING_UP` (non-interruptible, priority cao nhất) — xem GDD #16 Detailed Design rule 5
- **Pet Room Screen UI (#18)**: hiển thị mood indicator, energy bar

**Riverpod providers owned:**
```dart
// Base Mood = pure DERIVATION from energy (ADR-0007), KHÔNG phải settable StateProvider —
// mood là hàm thuần của energy (energy→mood lookup owned by Pet State Machine per ADR-0005).
// Dùng StateProvider sẽ cho phép set mood trực tiếp, bỏ qua lookup — cấm.
final petMoodProvider = Provider<MoodState>((ref) {
  final energy = ref.watch(energyProvider);   // Time & Decay #2 (ADR-0005)
  return _moodForEnergy(energy);
});
final petEnergyProvider = Provider<double>((ref) => ref.watch(energyProvider)); // passthrough 10–100 cho energy bar
```
> Triggered State (EXCITED/PLEASED/…) KHÔNG nằm ở Riverpod — nó là Flame-side ephemeral trong MochiComponent (ADR-0007). Base Mood ở Riverpod, Triggered State ở Flame.

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| EXCITED duration | 1.5s | 0.5–3s | Annoyingly long | Too quick to notice | Playtest với bé |
| PLEASED duration | 2.0s | 1–4s | Blocks next interaction | Blink-and-miss | Cảm giác "được vuốt ve" |
| SHOWING_OFF duration | 2.0s | 1–3s | Delay trước khi bé tương tác tiếp | Không đủ thấy outfit mới | 360° spin phải hoàn thành |
| BOUNCING duration | 1.0s | 0.5–2s | Quá nhiều distraction | Không nhận ra | Subtle, không phải hero animation |
| Mood threshold values | Từ Time & Decay GDD | Không thay đổi ở đây | — | — | Chỉ thay đổi trong Time & Decay GDD |

## Visual/Audio Requirements

**Visual (REQUIRED — phải spec trước khi asset production):**

> ⚠️ **Sửa 2026-07-14** (phát hiện khi `technical-artist` viết asset spec cho Mochi Baby, xem `design/assets/specs/mochi-baby-mood-sprites.md`): `fps` của 5 Base Mood states (HAPPY-SLEEPING) trước đây không khớp với cột **Loop** ở bảng "State Definitions" (dòng ~39-45) — tính `frames ÷ fps` ra chu kỳ thật nhanh hơn Loop đã ghi từ 3 đến 18 lần (SLEEPING: 0.33s thay vì 6s). Nếu build đúng theo `fps` cũ, SAD/SLEEPING sẽ nhấp nháy nhanh thay vì "gần bất động"/"ngủ sâu" như Art Bible §5.3 mô tả — phá vỡ P3 text-off test. **Quyết định (user, 2026-07-14)**: sửa `fps` để khớp đúng cột Loop đã duyệt (giữ nguyên `frames` count và giá trị Loop, chỉ tính lại `fps = frames ÷ Loop`). `frames` count không đổi so với bản trước.

| State | Sprite Set | Color Tint | Particle Effect |
|-------|-----------|------------|----------------|
| HAPPY | happy_idle (4 frames, 2fps — Loop 2s, không đổi) | Mint Breeze #A8E6CF | Tiny stars float (optional) |
| CONTENT | content_idle (3 frames, 1fps — Loop 3s) | Peach Glow #FFCBA4 | None |
| TIRED | tired_idle (3 frames, 0.75fps — Loop 4s) | Lavender Soft 70% opacity | None |
| SAD | sad_idle (2 frames, 0.4fps — Loop 5s) | Lavender Soft #C5A3E0 | Tiny teardrops (optional) |
| SLEEPING | sleep_idle (2 frames, ~0.33fps — Loop 6s) | Cloud White 60% opacity | Zzz float text |
| EXCITED | excited_burst (6 frames, 8fps) | Honey Gold #FFD060 flash | Sparkle burst |
| PLEASED | pleased_wiggle (4 frames, 6fps) | Peach Glow warm | None |
| SHOWING_OFF | showoff_spin (8 frames, 12fps) | Current Base color | **Owned bởi Pet Equipment (#15)'s Visual/Audio Requirements** — sparkle particles màu theo slot type (Honey Gold cho body_outfit/hat, Cloud White+Lavender Soft cho accessory — sửa "vàng/bạc" stale wording 2026-07-07, xem #15 cho spec chính xác), KHÔNG phải Confetti generic (sửa lỗi conflict tìm thấy khi review #15: 2 GDD từng độc lập định nghĩa particle khác nhau cho cùng 1 animation) |
| BOUNCING | bounce_hop (4 frames, 8fps) | Current Base color | None |

**Lưu ý**: EXCITED/PLEASED/SHOWING_OFF/BOUNCING (triggered states) không có cột Loop tương ứng ở bảng State Definitions — `fps` của 4 state này không nằm trong phạm vi lỗi vừa sửa, giữ nguyên như cũ.

**Audio:**
- HAPPY idle: soft melodic hum loop
- SAD/SLEEPING: muted, slow ambient
- EXCITED: short chime (approve sound)
- PLEASED: soft purr/coo
- SHOWING_OFF: short fanfare (2 notes)

📌 **Asset Spec** — Visual/Audio requirements defined. After art bible approved, run `/asset-spec system:pet-state-machine`.

## UI Requirements

Pet Room Screen UI (#18) phải hiển thị:
- **Mood indicator**: icon hoặc emoji nhỏ tương ứng mood state (không dùng text)
- **Energy bar**: fill % = `currentEnergy / 100`, không dùng màu đỏ khi thấp (Art Bible rule)
- Không hiển thị số energy raw cho bé — chỉ visual bar

📌 **UX Flag — Pet State Machine**: mood indicator + energy bar cần `/ux-design` spec.

## Acceptance Criteria

**GIVEN** `currentEnergy` = 85,
**WHEN** Pet State Machine tính toán Base Mood,
**THEN** `petMoodProvider` = HAPPY, `MochiComponent` hiển thị happy_idle animation với Mint Breeze tint.

**GIVEN** Mochi đang CONTENT (energy = 60) và bố mẹ approve task (+25 energy),
**WHEN** energy update → 85,
**THEN** Base Mood chuyển sang HAPPY tức thì, EXCITED triggered state play 1.5s rồi return HAPPY.

**GIVEN** Mochi đang SLEEPING (energy = 10) và bố mẹ approve task,
**WHEN** EXCITED trigger đến,
**THEN** Mochi "thức dậy" với EXCITED animation, sau 1.5s return Base Mood mới (TIRED nếu energy = 35).

**GIVEN** bé vuốt ve Mochi (PLEASED trigger) và approve đến trong cùng 0.5s (EXCITED trigger),
**WHEN** cả hai trigger cùng fire,
**THEN** EXCITED ưu tiên — PLEASED bị cancel, EXCITED animation play đủ 1.5s.

**GIVEN** energy thay đổi từ 85 → 90 (vẫn HAPPY),
**WHEN** Pet State Machine recalculate,
**THEN** không emit `petMoodChanged` event — `MochiComponent` không re-render.

**GIVEN** Mochi đang SHOWING_OFF (spin 360°, 2s),
**WHEN** bé tap vuốt ve trong lúc đang spin,
**THEN** SHOWING_OFF tiếp tục đủ duration — PLEASED không interrupt spin.

## Open Questions

- ~~**Outfit visual overlay**: Khi Mochi đang SHOWING_OFF spin, equipped items có spin theo không? Cần quyết định khi design Pet Equipment GDD (#15).~~ **Resolved (đóng khi review #15, 2026-07-06)**: CÓ, equipped overlays spin theo Mochi. Đây là hệ quả tự nhiên của #15's Core Rule 5 (mỗi slot overlay là `SpriteComponent` MOUNT lên Mochi base component, tức là con trong component tree) — transform (rotation) áp lên component cha tự động propagate xuống children trong Flame's component tree model, không cần logic riêng để đồng bộ spin.
- ~~**Level-up animation**: Khi pet level up, có cần một Triggered state đặc biệt (LEVELING_UP) không? Cần input từ Pet Leveling GDD (#16).~~ **Resolved 2026-07-03**: Có — `LEVELING_UP`, 3.0s, non-interruptible, priority cao nhất trong tất cả Triggered states. Xem Core Rules #3, Formulas, và Pet Leveling GDD (#16).
- **Sad notification**: Nếu Mochi SAD khi bé không mở app 2 ngày, có gửi push notification "Mochi nhớ bạn" không? Liên quan đến Push Notification GDD (#9).
