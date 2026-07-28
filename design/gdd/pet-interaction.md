# Pet Interaction System

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: Pillar 2 — Thú Cưng Là Hình Ảnh Của Bé (Mochi responds to bé's touch — the bond is real)

## Overview

Pet Interaction System định nghĩa **các cách bé chạm vào Mochi** trong Pet Room Screen và cách Mochi phản ứng lại. Đây là cầu nối cảm xúc trực tiếp nhất giữa bé và thú cưng — không cần task, không cần xu, chỉ cần một cái vuốt nhẹ.

**Infrastructure layer**: System nhận touch events từ Flame `TapCallbacks` / `DragCallbacks` trên Mochi sprite → map sang `InteractionType` enum → emit `GameEvent(petInteracted, InteractionType)` vào `GameEventBus` → Pet State Machine nhận và trigger PLEASED state.

**Player-facing layer**: Bé tap Mochi → Mochi nhắm mắt, wiggle nhẹ 2 giây. Bé swipe nhanh → Mochi spin vui. Những interaction này không ảnh hưởng đến energy hay xu — chúng là **pure joy moments**, tồn tại để củng cố emotional bond giữa bé và Mochi mỗi ngày.

MVP scope: **2 interaction types** — tap (vuốt ve) và swipe (tickle). Đủ để tạo cảm giác sống động mà không overscope art/animation.

## Player Fantasy

Mochi không phải một icon trên màn hình. Nó **sống**.

Khi bé đặt ngón tay lên Mochi và nhẹ nhàng vuốt, đôi mắt tròn xoe của nó từ từ nhắm lại — cái đầu lắc lắc một nhịp nhỏ như đang thưởng thức. Bé swipe nhanh thì Mochi quay tròn một vòng, tai vẫy lia lịa.

**Cảm xúc mục tiêu**: *"Con thú này thật sự thích mình."*

Interaction không cho xu, không tăng energy. Nó tồn tại vì một lý do duy nhất: **để bé muốn quay lại mở app chỉ để chào Mochi một cái** — dù hôm nay không có task nào cần làm.

Đây là sức mạnh của Tamagotchi: con thú không cần bạn làm gì cả. Nhưng nó nhớ bạn. Và bạn nhớ nó.

## Detailed Design

### Core Rules

1. Mochi sprite đăng ký `TapCallbacks` và `DragCallbacks` từ Flame. Toàn bộ bounding box của sprite là hit area.
2. Khi nhận tap event: emit `GameEvent(petInteracted, InteractionType.tap)` vào `GameEventBus`.
3. Khi nhận drag/swipe event (velocity > threshold): emit `GameEvent(petInteracted, InteractionType.SWIPE)`.
4. Sau mỗi interaction, set cooldown tương ứng. Trong cooldown, input bị ignore (không emit event).
5. Cooldown là per-type: TAP cooldown = 1.0s, SWIPE cooldown = 2.0s. Các loại không ảnh hưởng nhau.
6. Interaction không thay đổi `energyLevel`, `xuBalance`, hay bất kỳ persistent data nào. Chúng là pure visual/audio feedback.
7. **Tap hit area minimum**: Vùng nhận tap/drag trên Mochi sprite phải ≥ 80×80dp (registry: `tap_hitbox_min`) — bất kể kích thước hiển thị thật của sprite tại evolution stage hiện tại. Đây là requirement CỦA system này (không phải gợi ý), vì cooldown/threshold ở Core Rule 4-5 chỉ có ý nghĩa nếu tap/drag events thực sự register được với ngón tay trẻ em. Pet Room Screen UI (#18) sở hữu implementation cụ thể (layout, padding math — xem #18's Formula 2) để đảm bảo constraint này luôn đúng; hệ quả là #18's formula PHẢI luôn thỏa `hitBoxSize ≥ 80dp`.

### InteractionType Enum

```dart
enum InteractionType { tap, swipe }
```

### Swipe Detection Contract

- Swipe được nhận diện khi drag distance ≥ 40dp **và** drag duration ≤ 300ms.
- Dưới ngưỡng này (drag chậm): treat as tap.
- Direction của swipe không quan trọng (left/right/up đều trigger SWIPE như nhau).

### States and Transitions

**Lưu ý taxonomy (sửa lỗi so với bản trước)**: Pet State Machine (#6)'s Base Mood thật là `HAPPY/CONTENT/TIRED/SAD/SLEEPING` (không có `IDLE`/`HUNGRY` — 2 tên đó không tồn tại ở #6, là lỗi từ bản draft sớm chưa reconcile). PLEASED là 1 trong 5 Triggered States của #6 (`EXCITED/PLEASED/SHOWING_OFF/BOUNCING/LEVELING_UP`), duration 2s theo #6's Triggered State timer table — không redefine ở đây, chỉ tham chiếu.

| Base Mood khi tap/swipe | TAP | SWIPE |
|-----------|-----|-------|
| HAPPY / CONTENT / TIRED / SAD | → PLEASED (2s) → về đúng Base Mood cũ | → PLEASED (2s) → về đúng Base Mood cũ |
| (Triggered state khác đang chạy, vd PLEASED) | Ignore (đang animate — xem Edge Case "PLEASED đang chạy") | Ignore (đang animate) |
| SLEEPING | Visual only: hé mắt 0.5s, không đổi Base Mood, không trigger PLEASED | Visual only: hé mắt 0.5s, không đổi Base Mood, không trigger PLEASED |

*PLEASED là Triggered State (#6) — luôn quay về Base Mood hiện tại (tính từ energy, không phải "state trước đó" cố định) sau 2s. Theo #6's priority rule, nếu 1 Triggered State priority cao hơn (ví dụ LEVELING_UP) đang chạy, PLEASED bị chặn — xem #6's Core Rules cho priority order đầy đủ, GDD này không redefine.*

### Interactions with Other Systems

| System | Direction | Data |
|--------|-----------|------|
| Pet State Machine | OUT | `GameEvent(petInteracted, InteractionType)` via `GameEventBus` |
| Pet Room Screen UI | IN | Owns Flame component và mount Mochi sprite với callbacks |
| Audio System (future) | OUT | Interaction type → sound cue (định nghĩa khi Audio GDD được thiết kế) |

## Formulas

System này không có công thức toán học phức tạp. Các giá trị ngưỡng được định nghĩa dưới đây là tuning constants — xem Tuning Knobs để biết safe range.

**Swipe detection threshold:**
- `swipe_min_distance = 40dp`
- `swipe_max_duration = 300ms`
- Logic: `isSwipe = (dragDistance >= swipe_min_distance) && (dragDuration <= swipe_max_duration)`

**Worked example**: bé vuốt 55dp trong 250ms → `55 >= 40 && 250 <= 300` → `isSwipe = true` → emit `InteractionType.swipe`. Nếu cùng khoảng cách 55dp nhưng mất 450ms (vuốt chậm hơn) → `450 <= 300` là false → `isSwipe = false` → treat as tap, emit `InteractionType.tap`.

**Cooldown per type:**
- `tap_cooldown = 1000ms`
- `swipe_cooldown = 2000ms`

**PLEASED state duration:**
- `pleased_duration = 2000ms` (sau đó tự động quay về Base Mood hiện tại, tính từ energy — không phải "previous state" cố định lưu trữ riêng)

**SLEEPING peek duration:**
- `sleeping_peek_duration = 500ms` (hé mắt visual, không emit GameEvent)

## Edge Cases

- **If tap và swipe xảy ra đồng thời** (multi-touch): ưu tiên event nào được Flame dispatch trước; event sau bị ignore do cooldown.
- **If bé tap trong khi PLEASED animation đang chạy**: ignore hoàn toàn — Mochi không interrupt animation giữa chừng.
- **If drag distance ≥ 40dp nhưng duration > 300ms** (vuốt chậm): treat as tap — emit `InteractionType.tap`.
- **If drag distance < 40dp** (ngón tay hơi trượt khi tap): treat as tap — emit `InteractionType.tap`.
- **If Mochi đang SLEEPING và bé tap**: chạy sleeping_peek_duration (0.5s hé mắt) nhưng không emit `GameEvent` vào `GameEventBus` — Pet State Machine không nhận.
- **If app bị minimize giữa PLEASED animation**: animation bị discard khi app resume; Mochi quay về previous state ngay lập tức (không replay).
- **If cooldown timer chạy khi app minimize**: timer tiếp tục đếm bình thường qua Dart `Timer` — khi app resume, cooldown có thể đã hết.
- **If Mochi sprite chưa load xong** (first open lag): `TapCallbacks` không được đăng ký cho đến khi component `onMount()` hoàn tất — tap sớm bị silently drop.

## Dependencies

### Upstream Dependencies (system này cần)

| System | GDD | Interface cần |
|--------|-----|---------------|
| Pet State Machine | `pet-state-machine.md` ✅ | `GameEventBus.emit(GameEvent(petInteracted, InteractionType))` — Pet SM lắng nghe event này để trigger PLEASED state |
| Flutter-Flame State Bridge | `flutter-flame-state-bridge.md` ✅ | Singleton `GameEventBus` — phải khởi tạo trước khi Pet Room Screen mount |
| Pet Room Screen UI | GDD #18 (Approved ✅) | Flame `World` component nơi Mochi sprite được mount — interaction system sống bên trong screen này |

### Downstream Dependents (system này enables)

| System | GDD | Expects gì từ system này |
|--------|-----|--------------------------|
| Pet Room Screen UI | GDD #18 (Approved ✅) | `TapCallbacks`/`DragCallbacks` trên Mochi sprite, Core Rule 7's 80dp hit-area requirement (mà #18's Formula 2 implement), `InteractionType` enum cho callback wiring — quan hệ 2 chiều: #18 cũng là Upstream Dependency của #14 (hosts Flame World component) VÀ Downstream Dependent (#18 tiêu thụ hit-area contract) (thêm 2026-07-06, bidirectionality gap tìm thấy khi review-all-gdds — #18 tự nhận "7/7 upstream confirmed bidirectional" nhưng #14 chưa list #18 ở đây) |
| Audio System | GDD #22 (Not Started) | `InteractionType` enum value để map sang sound cue |
| Pet Animation System | Owned by Pet State Machine | PLEASED state animation được trigger bởi event từ system này |

### Hard vs. Soft Dependencies

- **Hard**: Pet State Machine + GameEventBus — system không hoạt động nếu thiếu.
- **Soft**: Audio System — interaction vẫn hoạt động (silently) nếu Audio chưa được implement.

## Tuning Knobs

| Knob | Default | Min | Max | Hậu quả nếu quá thấp | Hậu quả nếu quá cao |
|------|---------|-----|-----|----------------------|---------------------|
| `tap_cooldown` | 1000ms | 300ms | 3000ms | Bé spam tap → animation chồng nhau | Mochi cảm giác "lag", không responsive |
| `swipe_cooldown` | 2000ms | 500ms | 4000ms | Swipe spam → animation glitch | Cảm giác bị phạt khi swipe |
| `pleased_duration` | 2000ms | 1000ms | 4000ms | Animation quá ngắn, không thỏa mãn | Bé phải chờ quá lâu để interact tiếp |
| `swipe_min_distance` | 40dp | 20dp | 80dp | Mọi tap nhỏ đều thành swipe | Swipe khó trigger, trẻ em tay nhỏ thất vọng |
| `swipe_max_duration` | 300ms | 150ms | 500ms | Chỉ swipe rất nhanh mới được nhận | Vuốt chậm cũng thành swipe → mất phân biệt |
| `sleeping_peek_duration` | 500ms | 200ms | 1000ms | Hé mắt quá nhanh, không thấy | Mochi "thức" quá lâu khi đang ngủ |

**Knob interactions**: `pleased_duration` phải ≥ `tap_cooldown` để tránh trường hợp cooldown hết nhưng animation vẫn đang chạy (sẽ gây ignore tiếp).

## Visual/Audio Requirements

**Tap (vuốt ve) — PLEASED animation:**
- Mochi nhắm mắt từ từ (easing: ease-in, 0.2s)
- Đầu lắc nhẹ trái-phải 2 lần (amplitude: 8dp, 0.4s mỗi lắc)
- Đuôi vẫy 1 lần nhẹ nhàng
- Toàn bộ duration: 2000ms → eyes reopen, return to idle pose
- Particle: 2–3 hạt nhỏ hình tim nhỏ nổi lên từ đầu Mochi, fade out trong 0.8s
- Màu tim: hồng pastel `#FFB3C6` (theo art bible palette)

**Swipe (tickle) — PLEASED animation variant:**
- Mochi spin 360° (ease-out, 0.5s)
- Sau spin: nhảy nhẹ lên 12dp rồi bounce xuống (0.3s)
- Tai vẫy nhanh trong suốt animation
- Particle: 3–4 dấu ngoặc kép `hehe` nổi lên, fade out 1.0s
- Toàn bộ duration: 2000ms

**SLEEPING peek (khi tap lúc ngủ):**
- Mắt hé mở 30% (không mở hẳn), giữ 0.3s, nhắm lại 0.2s
- Không có particle
- Duration: 500ms total

**Audio (placeholder — Audio GDD sẽ xác nhận):**
- TAP: soft "mew" sound, pitch ~C5
- SWIPE: giggle/laugh short clip ~0.5s
- SLEEPING peek: quiet sleepy murmur
- Tất cả SFX volume ≤ 60% master để không startle bé

📌 **Asset Spec** — Visual/Audio requirements đã được định nghĩa. Sau khi art bible được approved, chạy `/asset-spec system:pet-interaction` để sinh per-asset specs và generation prompts.

## UI Requirements

System này không có UI riêng. Toàn bộ interaction xảy ra trực tiếp trên Mochi sprite component trong Pet Room Screen. Pet Room Screen UI (GDD #18) chịu trách nhiệm định nghĩa layout và đảm bảo Mochi sprite thỏa Core Rule 7 (minimum 80×80dp tap area) — xem #18's Formula 2 cho công thức padding cụ thể.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory.

- **AC-1** `[LOGIC]` BLOCKING — GIVEN Mochi ở bất kỳ Base Mood nào (HAPPY/CONTENT/TIRED/SAD, không phải SLEEPING), WHEN bé tap lên sprite, THEN `GameEvent(petInteracted, InteractionType.tap)` được emit vào `GameEventBus` trong vòng 1 frame.
- **AC-2** `[LOGIC]` BLOCKING — GIVEN Mochi ở bất kỳ Base Mood nào (không phải SLEEPING), WHEN bé swipe (≥40dp, ≤300ms) lên sprite, THEN `GameEvent(petInteracted, InteractionType.swipe)` được emit vào `GameEventBus`.
- **AC-3** `[LOGIC]` BLOCKING — GIVEN bé vừa tap Mochi, WHEN bé tap lại trong vòng 1000ms, THEN không có event nào được emit (cooldown active).
- **AC-4** `[LOGIC]` BLOCKING — GIVEN bé vừa swipe Mochi, WHEN bé swipe lại trong vòng 2000ms, THEN không có event nào được emit.
- **AC-5** `[LOGIC]` BLOCKING — GIVEN tap cooldown active nhưng swipe cooldown đã hết, WHEN bé swipe, THEN `InteractionType.swipe` được emit bình thường (per-type cooldown độc lập).
- **AC-6** `[LOGIC]` BLOCKING — GIVEN drag distance < 40dp, WHEN bé thả ngón tay, THEN treat as tap — emit `InteractionType.tap` (nếu không trong cooldown).
- **AC-7** `[LOGIC]` BLOCKING — GIVEN drag distance ≥ 40dp nhưng duration > 300ms, WHEN bé thả ngón tay, THEN treat as tap — emit `InteractionType.tap`.
- **AC-8** `[LOGIC]` BLOCKING — GIVEN Mochi ở Base Mood SLEEPING, WHEN bé tap, THEN sleeping peek animation chạy 500ms và KHÔNG có `GameEvent` nào được emit vào `GameEventBus`.
- **AC-9** `[LOGIC]` BLOCKING — GIVEN Mochi đang trong Triggered State PLEASED (đang animate), WHEN bé tap, THEN input bị ignore, animation không bị interrupt.
- **AC-10** `[INTEGRATION]` BLOCKING — GIVEN interaction xảy ra, THEN không có thay đổi nào đến `energyLevel`, `xuBalance`, hay Firestore documents.
- **AC-11** `[INTEGRATION]` BLOCKING — GIVEN app được minimize và resume giữa PLEASED animation, THEN Mochi trở về Base Mood hiện tại (tính từ energy) ngay — không replay animation.
- **AC-12** `[LOGIC]` BLOCKING — GIVEN Mochi sprite ở bất kỳ evolution stage nào (bất kỳ `spriteSize`), WHEN đo vùng nhận tap/drag thực tế, THEN vùng đó ≥ 80×80dp luôn đúng (Core Rule 7) — verify qua Pet Room Screen UI #18's Formula 2 output.

## Open Questions

1. **Interaction thứ 3?** — Long-press (giữ tay) có thể là interaction thứ 3 ("ôm Mochi"). Không đưa vào MVP. Owner: Game Designer. Target: Review sau vertical slice.
2. **Audio GDD integration** — Sound cues được ghi là placeholder. Khi Audio GDD (#22) được thiết kế, cần sync lại `InteractionType` → sound mapping. Owner: Audio Designer.
