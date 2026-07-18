# Pet Room Screen UI

> **Status**: Approved ✅ (reviewed 2026-07-05 — APPROVED WITH CONCERNS, all 5 findings fixed same day). All 8 required + 3 optional sections complete, review mode: lean
> **Author**: User + Agents
> **Last Updated**: 2026-07-05
> **Implements Pillar**: Pillar 2 — Thú Cưng Là Hình Ảnh Của Bé

## Overview

Pet Room Screen UI là màn hình mặc định bé thấy mỗi khi mở app — nhà của Mochi. Đây là nơi 6 systems khác hội tụ thành một màn hình duy nhất: FlameGame canvas render `MochiComponent` (mood/energy từ Pet State Machine #6), tap/vuốt ve trực tiếp lên Mochi (Pet Interaction #14, tap area tối thiểu 80×80dp), tap-on-Mochi mở context menu 3 lựa chọn (Thay đồ/Vuốt ve/Đóng) dẫn tới Wardrobe bottom sheet (Pet Equipment #15), progress bar level + trạng thái "MAX" ở L5 (Pet Leveling #16), và room background cố định (xem scope note dưới).

**Scope note (MVP)**: GDD này scope MVP là **room background CỐ ĐỊNH** (art asset tĩnh, không phải hệ thống đặt đồ tương tác) — khớp với `game-concept.md`'s MVP Definition (đã reconcile 2026-07-06) và `systems-index.md`, vì Decoration Database (#27) và Room Layout System (#28) đều là Alpha-tier, chưa có GDD nào. (Trước 2026-07-06, `game-concept.md` từng liệt kê "10-15 đồ trang trí có thể đặt" là MVP-required — gap đó đã được đóng ở `game-concept.md` chứ không phải ở đây, nên không còn là contradiction sống.)

Về kiến trúc: route `/child/pet-room` (Main Navigation Shell #17, Tab 1 mặc định) — `GameWidget` host `FlameGame` instance (MochiComponent + room background), với Flutter overlay widgets phía trên (mood indicator, energy bar, level progress bar, Wardrobe bottom sheet, context menu). Một chi tiết quan trọng đã confirm ở #17: Flame component vẫn mounted và game loop tiếp tục chạy ngay cả khi bé chuyển sang tab khác (`StatefulShellRoute` không dispose) — nghĩa là triggered-state animations (BOUNCING khi submit task, EXCITED khi approve) có thể chạy và kết thúc mà bé không nhìn thấy nếu đang ở tab khác. Đây là hành vi CHỦ Ý, không phải bug — bé chỉ cần thấy Mochi đã "biết" khi quay lại, không cần xem trực tiếp mọi animation.

Player-facing: đây là màn hình bé nhìn vào TRƯỚC KHI làm gì cả — passive-until-tapped. Mood của Mochi phải truyền tải "tuần này bé thế nào" chỉ qua nhìn, không cần đọc text (Pillar 2's core test). Tương tác chủ động (tap/vuốt ve/thay đồ) là lớp phía trên, không phải điều kiện để cảm nhận được bond với Mochi.

## Player Fantasy

**Khoảnh khắc mở app (fantasy riêng của GDD này — không hệ thống nào khác sở hữu)**: Bé mở app. Trước khi tap gì cả, bé đã BIẾT — chỉ qua nhìn — Mochi đang vui, buồn, hay đang ngủ. Không cần đọc số liệu, không cần menu. Đây là "cái nhìn đầu tiên" mà `game-concept.md`'s Core Loop đã mô tả: *"Mở app → Thấy thú đang chờ/vui vẻ/buồn"*. Pet Room Screen UI là nơi khoảnh khắc đó thực sự xảy ra — nếu composition (bố cục Mochi, background, các bar/indicator) rối hay chậm load, cái nhìn đầu tiên đó — thứ mà toàn bộ Pillar 2 dựa vào — sẽ bị phá vỡ trước khi bé kịp cảm nhận gì.

**Tap/vuốt ve** (fantasy riêng đã có ở Pet Interaction #14 — không lặp lại): GDD này là sân khấu vật lý cho khoảnh khắc đó — đảm bảo Mochi đủ lớn, đủ dễ chạm, đúng vị trí để cái vuốt ve đó cảm thấy tự nhiên, không phải "cố tìm đúng chỗ tap".

**Thay đồ cho Mochi** (fantasy riêng đã có ở Pet Equipment #15 — không lặp lại): GDD này host Wardrobe bottom sheet, đảm bảo transition từ "đang nhìn Mochi" sang "đang chọn đồ" mượt mà, không phải rời khỏi không gian của Mochi để vào một "cửa hàng" tách biệt.

**Nhìn Mochi lớn lên** (fantasy riêng đã có ở Pet Leveling #16 — không lặp lại): progress bar ở đây là lời nhắc âm thầm, liên tục — không phải thông báo ồn ào.

**Cảm xúc tổng hợp — "về nhà"**: Đây là nơi TẤT CẢ những khoảnh khắc riêng lẻ đó cộng lại thành một cảm giác duy nhất: *"Đây là nhà của Mochi, và mình luôn có thể quay lại."* Không có system nào khác sở hữu cảm giác tổng hợp này — nó chỉ xuất hiện khi composition của GDD này đúng: Mochi ở trung tâm, mọi UI chrome (bar, progress, menu) hỗ trợ chứ không cạnh tranh sự chú ý với Mochi.

## Detailed Design

### Core Rules

1. **Screen composition (z-order, bottom to top)**:
   1. Room background (fixed art asset, MVP scope — static `Image`/Flame `SpriteComponent`, không tương tác)
   2. `MochiComponent` (Flame, center-weighted, per Pet State Machine #6's mood/triggered states)
   3. Persistent Flutter overlay chrome: "Mochi status row" (mood icon + energy bar, ngay dưới Child app bar) + level progress bar (nhỏ hơn, dưới status row — không cạnh tranh sự chú ý với Mochi, đúng Player Fantasy's nguyên tắc)
   4. Modal layers (chỉ khi triggered): tap-on-Mochi context menu, Wardrobe bottom sheet

2. **FlameGame hosting**: `GameWidget` wraps 1 `FlameGame` instance chứa `MochiComponent` + background. Route `/child/pet-room` (Main Navigation Shell #17, Tab 1 mặc định).

3. **GameEventBus initialization — KHÔNG thuộc trách nhiệm GDD này**: Pet Interaction (#14)'s Dependencies yêu cầu GameEventBus phải init trước khi Pet Room Screen mount. Theo Flutter-Flame Bridge (#5)'s Core Rules, GameEventBus là **app-level singleton, init 1 lần ở `main()`, dispose chỉ khi app terminate** — không phải per-screen. Constraint này tự động thỏa mãn vì singleton tồn tại trước bất kỳ screen nào render — GDD này chỉ subscribe, không init.

4. **Tap-on-Mochi**: `TapCallbacks` mixin trên `MochiComponent` (KHÔNG dùng `TapDetector` — deprecated theo `docs/engine-reference/flutter-flame/deprecated-apis.md`). Tap AREA tối thiểu 80×80dp (Pet Interaction #14's requirement) — **quan trọng: đây là hit box, không phải kích thước sprite hiển thị**. Baby Mochi (L1) có sprite nhỏ hơn 80dp về mặt hình ảnh — hit box vẫn phải đủ 80×80dp bằng cách mở rộng tap area vô hình xung quanh sprite nhỏ, không scale sprite lớn hơn thiết kế gốc.

5. **Tap-on-Mochi context menu**: Flutter overlay widget (không phải Flame component), 3 options: "Thay đồ" (→ đóng menu NGAY LẬP TỨC, sau đó mở Wardrobe bottom sheet — không có thời điểm nào cả 2 modal cùng mounted, giữ đúng invariant "1 modal layer tại 1 thời điểm" ở Core Rule 1), "Vuốt ve" (→ trigger Pet Interaction #14's pet action trực tiếp, đóng menu ngay), "Đóng" (dismiss, không hành động).

6. **Wardrobe bottom sheet**: Flutter bottom sheet slide lên từ Pet Room (không phải Flame component, theo Pet Equipment #15's quyết định). 3 slot tabs (icon + tên slot) trên cùng, grid inventory items cho slot đang chọn, nút "Đóng"/tap ngoài để dismiss. Item data từ Item Database (#3)'s `category`/`slot`/`source` fields.

7. **Mochi status row**: mood icon (từ Pet State Machine #6's 5 mood tiers) + energy bar (10-100 range, #6's color-coded thresholds) — hiển thị persistent, ngay dưới Child app bar (#17's territory, không lấn vào).

8. **Level progress bar**: đọc `petLevelProvider`/`levelProgressProvider` (Pet Leveling #16) — hiển thị % tiến độ tới level tiếp theo; tại L5 hiển thị "MAX" theo #16's Edge Case 4, không đầy rồi loop lại.

9. **Offscreen persistence (đã confirm ở Overview)**: Flame game loop tiếp tục chạy khi bé chuyển tab khác (`StatefulShellRoute` giữ mounted) — triggered-state animations (BOUNCING, EXCITED, LEVELING_UP) có thể hoàn thành mà bé không xem trực tiếp. GDD này KHÔNG cần logic interrupt/pause riêng cho animation — Pet State Machine's timer đã tự quản lý độc lập với screen visibility.

### States and Transitions

```
/child/pet-room (Tab 1, mặc định)
      │
      ├── [default] Mochi hiển thị theo Base Mood (Pet State Machine #6)
      │     └── Triggered states (BOUNCING/EXCITED/SHOWING_OFF/LEVELING_UP) override tạm thời
      │
      ├── tap Mochi → context menu (3 options)
      │     ├── "Thay đồ" → đóng menu NGAY → Wardrobe bottom sheet mở (không overlap 2 modal)
      │     │     └── chọn item → equip → SHOWING_OFF trigger (Pet Equipment #15) → đóng sheet
      │     ├── "Vuốt ve" → PLEASED trigger (Pet Interaction #14) → đóng menu ngay
      │     └── "Đóng" → dismiss, không hành động
      │
      └── [persistent chrome] Mood icon + Energy bar + Level progress bar — luôn hiển thị, update real-time qua providers
```

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Pet State Machine (#6) | IN | Mood, energy, triggered states | `petMoodProvider`, `petEnergyProvider` |
| Pet Interaction (#14) | IN/OUT | Tap/pet callbacks, mounts trong Flame World | `TapCallbacks` trên `MochiComponent` |
| Pet Equipment (#15) | IN/OUT | Wardrobe UI, equip callback, SHOWING_OFF trigger | Bottom sheet + equip function |
| Pet Leveling (#16) | IN | Level, progress %, MAX state | `petLevelProvider`, `levelProgressProvider` |
| Flutter-Flame State Bridge (#5) | IN | `GameEvent` stream (multiple event types) | `GameEventBus().stream` |
| Item Database (#3) | IN | Item category/slot/source cho Wardrobe grid | `itemCatalogProvider` |
| Main Navigation Shell (#17) | IN | Hosts `/child/pet-room`, giữ Flame mounted qua tab switch | `StatefulShellRoute` |

## Formulas

Pet Room Screen UI không recompute logic của 6 systems nó compose (mood/energy từ #6, level progress từ #16, v.v. — tất cả đọc trực tiếp qua providers, xem Interactions table). Section này chỉ định nghĩa 2 phép tính **mới**, thuộc sở hữu riêng của GDD này: một performance contract (vì đây là Flame-canvas-hosting screen đầu tiên trong project) và một hit-area formula (mà Pet Interaction #14 đã chủ động giao lại cho GDD này — xem #14 dòng "Pet Room Screen UI (GDD #18) chịu trách nhiệm định nghĩa layout và đảm bảo Mochi sprite có đủ tap area").

### Contract 1 — Flame Canvas Draw Call Budget Contract

```
drawCalls_sceneFlame = drawCalls_background + drawCalls_mochiBase + slotCount
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Background draw calls | `drawCalls_background` | int | {1} | Room background — 1 static `SpriteComponent` (MVP scope, không có decoration system tương tác — xem Overview's scope note) |
| Mochi base draw calls | `drawCalls_mochiBase` | int | {1} | `MochiComponent` base sprite — mood/triggered-state chỉ swap texture/animation frame, không tăng số component |
| Equipment slot count | `slotCount` | int | {3} | Pet Equipment #15's 3 slot luôn mounted (`body_outfit`, `hat`, `accessory`) — mỗi slot là 1 `SpriteComponent` riêng, kể cả khi hiển thị default/"none" item (#15 Core Rule 5: "Flame sprite overlay: mỗi slot có một SpriteComponent riêng"; #15 Core Rule 1 chỉ đảm bảo slot never-null ở data model, không phải claim render-component) |
| Total Flame draw calls | `drawCalls_sceneFlame` | int | 5 (fixed, MVP) | Tổng draw calls Flame canvas của screen này đóng góp mỗi frame |

**Output range:** Fixed tại 5 cho MVP — không phải giá trị bị clamp, chỉ là constant với các input hiện tại. **Scope quan trọng (interpretation, chưa phải ADR chính thức)**: con số này CHỈ tính draw calls trong `GameWidget`/Flame canvas. Flutter overlay chrome (mood icon, energy bar, level progress bar, Wardrobe bottom sheet, context menu) render qua compositing pipeline riêng của Flutter — GDD này ĐỌC budget ≤200 draw calls/frame trong `technical-preferences.md` như metric của engine/Skia-sprite rendering, không phải widget count, nhưng `technical-preferences.md` không nói rõ ràng điều này bằng văn bản. Đây là cách đọc hợp lý nhất hiện có (Flutter widget cuối cùng cũng compile xuống Skia canvas ops qua cùng engine, nên "loại trừ hoàn toàn" không phải sự thật hiển nhiên), không phải fact đã xác nhận. **Khuyến nghị**: technical-director nên chốt scope chính xác của budget này bằng một ADR trước khi GDD tương lai nào khác (mọi Flame-canvas-hosting screen sau #18) dựa vào cùng cách đọc này làm precedent.

**Worked example**: Không có item nào equipped (tất cả slot ở default) → `drawCalls_sceneFlame = 1 (background) + 1 (Mochi base) + 3 (body_outfit, hat, accessory — mỗi slot 1 SpriteComponent dù đang default) = 5`. So với budget ≤200 draw calls/frame → **2.5% utilization**, còn nhiều headroom cho Room Layout System #28 (Alpha-tier, ngoài scope MVP của GDD này) chi tiêu sau này.

**Forward-looking note (không phải scope của GDD này)**: Nếu Room Layout System #28 ship post-MVP với N đồ trang trí đặt được, formula mở rộng thành `drawCalls_sceneFlame = 5 + N_decorations`, và #28 cần tự verify `N_decorations ≤ 195` để giữ budget — trách nhiệm của GDD tương lai đó, chỉ flag ở đây để không bị quên.

### Formula 2 — Tap Hit-Area Padding

```
padding = max(0, (hitBoxMin - spriteSize) / 2)
hitBoxSize = spriteSize + 2 × padding
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Sprite size | `spriteSize` | float (dp) | >0, unbounded | Kích thước hiển thị của Mochi sprite tại evolution stage hiện tại (Baby/Young/Grown — #16), giả định hình vuông cho mục đích tính hit area |
| Minimum hit box | `hitBoxMin` | float (dp) | {80} | Tap area tối thiểu, constant sở hữu bởi Pet Interaction #14 Core Rules (registry: `tap_hitbox_min`) |
| Padding | `padding` | float (dp) | ≥0 | Vùng vô hình mở rộng đối xứng mỗi cạnh, thêm vào xung quanh sprite hiển thị |
| Final hit box size | `hitBoxSize` | float (dp) | ≥80, unbounded phía trên | Kích thước vùng tap-detection thực tế (`TapCallbacks` hit test region) — độc lập với kích thước sprite hiển thị |

**Output range:** Bị chặn dưới tại 80dp — không bao giờ nhỏ hơn `hitBoxMin` dù `spriteSize` nhỏ đến đâu. Không chặn trên — nếu sprite đã lớn hơn 80dp, không thêm padding và cũng không bị co lại.

**Worked example 1 (Baby Mochi, L1)**: `spriteSize` = 72dp (✅ CONFIRMED FINAL — Art Bible Section 5.2, 2026-07-14). `padding = max(0, (80-72)/2) = 4dp` → `hitBoxSize = 72 + 2×4 = 80dp`. Tap area canh giữa trên sprite, mở rộng vô hình 4dp mỗi cạnh ra ngoài sprite thấy được — padding nhỏ vì Baby sprite đã gần sát `hitBoxMin`.

**Worked example 2 (Grown Mochi, L4-L5)**: `spriteSize` = 152dp (✅ CONFIRMED FINAL — Art Bible Section 5.2). `padding = max(0, (80-152)/2) = max(0, -36) = 0` → `hitBoxSize = 152dp` (sprite đã tự thỏa mãn minimum, không cần mở rộng).

Cùng một expression xử lý cả 2 trường hợp (sprite nhỏ hơn hoặc lớn hơn minimum) không cần branching trong spec — unit-testable trực tiếp: `assert(hitBoxSize >= 80)` với mọi `spriteSize` input.

**Dependency note**: ✅ **Đã đóng (2026-07-14)** — giá trị `spriteSize` (72/112/152dp cho Baby/Young/Grown) nay là **final pin chính thức**, xác nhận tại Art Bible Section 5.2 (Character Design Direction, Complete). Không còn là recommendation tạm thời.

## Edge Cases

1. **Baby Mochi sprite nhỏ hơn 80dp**: Hit area tự động padding theo Formula 2 — không co giãn sprite lớn hơn thiết kế gốc, chỉ mở rộng vùng tap vô hình xung quanh.

2. **Bé tap ngoài hit area nhưng gần Mochi** (ví dụ tap vào background sát cạnh Mochi): Không trigger context menu — tap chỉ đăng ký trong `hitBoxSize` đã tính. Không cần feedback lỗi ("tap gần trúng") — hành vi giống mọi target UI khác.

3. **Context menu đang mở, bé tap ra ngoài menu**: Dismiss menu, không hành động — cùng pattern với các modal khác trong project (Wardrobe bottom sheet, Parent Dashboard's dialogs).

4. **Wardrobe đang mở, có `GameEvent` mới đến** (ví dụ bé approve xong 1 task ở device khác, `petLeveledUp` event fire): Event vẫn được `GameEventBus` deliver và Pet State Machine xử lý internal state — nhưng visual (`LEVELING_UP` animation, sprite swap) bị defer cho đến khi Wardrobe đóng, tương tự cách Task Management UI (#19) defer banner khi modal mở. Không hiển thị animation chồng lên bottom sheet.

5. **Mochi đang chạy LEVELING_UP animation (non-interruptible, Pet State Machine #6), bé tap vào Mochi**: Tap vẫn được `TapCallbacks` nhận, nhưng context menu KHÔNG mở trong lúc LEVELING_UP đang chạy — theo #6's priority rule (LEVELING_UP là highest priority, non-interruptible). Context menu chỉ mở sau khi animation hoàn tất.

6. **`itemCatalogProvider` (Item Database #3) chưa load xong khi Wardrobe mở**: Hiển thị skeleton/shimmer loading state trong grid — không crash, không hiển thị grid rỗng gây hiểu nhầm "chưa mua gì". **Nếu provider trả về `AsyncError`** (network/cache failure): grid hiển thị inline error state ("Không tải được đồ — Thử lại" + nút retry) thay cho shimmer — cùng lý do tránh grid rỗng gây hiểu nhầm, không crash sheet.

7. **Room background asset load thất bại** (network/cache issue hiếm gặp): Fallback về màu nền solid pastel (Cream Ivory, theo Art Bible) — không hiển thị lỗi, không màn hình trắng/đen.

## Dependencies

**Upstream (Pet Room Screen UI cần — hard dependencies):**
- **Pet State Machine (#6)** ✅ Approved — `petMoodProvider`, `petEnergyProvider`, triggered-state animations
- **Pet Interaction (#14)** Designed (pending review) — `TapCallbacks` trên `MochiComponent`, delegate hit-area math tới GDD này (Formula 2)
- **Pet Equipment (#15)** Designed (pending review) — Wardrobe bottom sheet content, equip callback, 3-slot always-mounted model (Formula 1's basis)
- **Pet Leveling (#16)** ✅ Approved — `petLevelProvider`, `levelProgressProvider`, MAX state
- **Flutter-Flame State Bridge (#5)** ✅ Approved — `GameEventBus().stream`, phải init trước khi screen mount (tự thỏa mãn — app-level singleton)
- **Item Database (#3)** ✅ Approved — `itemCatalogProvider` cho Wardrobe grid
- **Main Navigation Shell (#17)** ✅ Approved — hosts `/child/pet-room`, giữ Flame mounted qua tab switch

**Downstream**: không có hệ thống nào phụ thuộc vào Pet Room Screen UI — đây là điểm hội tụ (convergence point), không phải nguồn phát interface mới.

**Bidirectional check**: cả 7 upstream GDDs đã reference "#18"/"Pet Room Screen" đúng cách (confirmed qua grep trước khi bắt đầu design GDD này — xem context summary Phase 2).

**Riverpod providers consumed (không sở hữu, chỉ đọc):**
```dart
// Từ Pet State Machine #6, Pet Leveling #16, đã defined ở các GDD đó — liệt kê lại để rõ ràng dependency surface
final petMoodProvider = ...      // #6
final petEnergyProvider = ...    // #6
final petLevelProvider = ...     // #16
final levelProgressProvider = ... // #16
final itemCatalogProvider = ...  // #3
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Mochi vertical anchor (% từ top của canvas) | 55% | 40–70% | Mochi bị đẩy xuống thấp, background phía trên trống trải | Mochi quá cao, bị status row/level bar che khuất | Cần đủ khoảng trống trên đầu cho status row (mood+energy) và level bar |
| Mochi max scale (relative to base sprite, tại Grown stage) | 1.0 (không scale up) | 1.0–1.3 | Grown Mochi chiếm quá nhiều canvas, giảm cảm giác "phòng" | — (1.0 là an toàn nhất) | Nếu tăng, cần re-verify hit area formula vẫn đúng (Formula 2 vẫn hoạt động vì parametric) |

**Không định nghĩa lại**: "Tap hit box minimum" (80dp) thuộc Pet Interaction (#14) Core Rules, registry: `tap_hitbox_min` — GDD này chỉ áp dụng qua Formula 2, không tạo bản sao. "Equipment slot count" (3) thuộc Pet Equipment (#15) Core Rules — Formula 1 chỉ tham chiếu.

## Visual/Audio Requirements

**Room background (hybrid "stage set", MVP — constant across evolution stages):**

- Kiến trúc cơ bản: tường bo góc (Cream Ivory `#FFFDF0`), sàn nhà, một cửa sổ oval — theo Shape Language's "rounded rectangles, không đường thẳng tuyệt đối" (Art Bible Section 3).
- Nguồn sáng: ánh sáng vàng ấm từ cửa sổ, tạo một "vùng sáng" (light pool) trên sàn đúng tại vị trí Mochi's vertical anchor (55% từ top, theo Tuning Knob hiện có) — sáng hơn ở trung tâm, dịu dần ra biên. Đây là **warm vignette, không phải dark vignette** — Art Bible cấm dark vignette/harsh shadow tuyệt đối (Section 2), nên hiệu ứng dẫn mắt về Mochi phải đến từ ánh sáng ấm tăng dần, không phải làm tối các cạnh.
- Prop "sống động một chút" (theo mood target "còn đồ lung tung một chút"): tối đa 2–3 prop cố định (một tấm rug, một kệ nhỏ, một cây treo) đặt CHỈ ở góc/biên trái-phải-dưới màn hình — không đặt ở trung tâm hoặc 35% trên cùng của canvas (vùng đó dành cho Mochi + status row/level bar). Đây là ứng dụng trực tiếp của Hero vs. Supporting Shape table (Art Bible Section 3): prop là Supporting, phải recede, không cạnh tranh với Mochi (Hero).
- Màu prop: điểm nhấn Mint Breeze/Petal Pink nhỏ ở prop góc, giữ palette đa dạng nhưng không kéo mắt khỏi trung tâm.
- Level of detail: flat shading hoặc soft gradient, không texture rối, đường nét hơi "wobbly" tay vẽ (không CAD-precision) — đồng nhất style với world aesthetic chung.
- **Không đổi theo evolution stage** (Baby/Young/Grown dùng chung 1 background asset cho MVP). Lý do: background là placeholder cho Room Layout System (#28, Alpha-tier, chưa có GDD) — đầu tư 3 biến thể cho một asset sẽ bị thay thế là scope creep không cần thiết. Room progression theo stage (nếu muốn) nên là quyết định của #28, không pre-build ở đây.
- Asset hệ quả: 1 `SpriteComponent` tĩnh duy nhất (khớp Formula 1's `drawCalls_background = 1`). Fallback khi load lỗi (Edge Case 7): solid Cream Ivory — gần giống màu nền thật nên fallback không gây giật hình rõ rệt.

**Persistent chrome — floating translucent pill (mood/energy row + level bar):**

- Style: cả status row và level bar render dưới dạng pill/card bo tròn, Cream Ivory ~85% opacity, soft shadow nhẹ — **floating** phía trên background, không dock full-width sát 2 cạnh màn hình. Giữ đúng "UI echoes world aesthetic" (Section 3) bằng cách dùng cùng ngôn ngữ pill như button, và giữ background nhìn thấy được phía sau pill để không chia màn hình thành 2 khối "world" vs "dashboard" tách biệt.
- Status row (mood icon + energy bar): mood icon ~32dp — **backup cue**, không phải primary cue (Pillar 2's test thật là nhìn body language của Mochi; icon chỉ đảm bảo parity/colorblind-safety như mọi nơi khác trong Art Bible). Energy bar track ~10dp cao, fill theo Mint Breeze → Peach Glow gradient (Art Bible Semantic Color table), không hiển thị số raw.
- Level bar: pill riêng, mỏng hơn (~6dp), đặt ngay dưới status row pill — dùng Honey Gold `#FFD060` (Art Bible canonical hex) cho fill, đúng semantic "Achievement/reward". Tại L5/MAX: thay bar fill bằng badge/text "MAX" tĩnh, không hiển thị bar đầy-rồi-đứng-im (tránh cảm giác UI bị đứng/broken).
- Shape discipline: cả 2 pill dùng hình chữ nhật bo góc (Supporting shape) — không bao giờ dùng hình tròn/oval cho chrome, hình tròn/oval dành riêng cho Mochi (Hero shape, Art Bible Section 3's Hero vs. Supporting table).
- Ngân sách kích thước: status row + level bar cộng lại chiếm khoảng **12–15% chiều cao màn hình**, đặt sát dưới Child app bar, còn lại ~85–88% cho background + Mochi.

**Context menu và Wardrobe bottom sheet — placement trong Pet Room:**

- Context menu: render như popup có anchor tại vị trí Mochi (card bo góc nhỏ với "tail" chỉ về Mochi, giống speech-bubble), đặt phía trên/bên cạnh Mochi theo vertical anchor hiện tại — **không** dùng dialog center-screen chung. Lý do: đây là context menu VỀ Mochi, vị trí phải giữ liên kết không gian với Mochi, đúng vai trò "physical stage" mà GDD này tự nhận (Overview, Player Fantasy).
- Scrim (backdrop dim) cho cả context menu và Wardrobe sheet: dùng warm scrim nhạt — warm dark brown `#3D2B1F` tại ~20–25% opacity — **không** dùng scrim đen/tối tiêu chuẩn. Đây là hệ quả trực tiếp của Art Bible's cấm dark vignette/harsh shadow (Section 2), áp dụng cho mọi modal trong game, không riêng gì GDD này.
- Wardrobe bottom sheet height: cap tối đa **~60–65% chiều cao màn hình** — để đầu/phần trên của Mochi vẫn hiển thị phía trên mép sheet trong suốt lúc Wardrobe mở. Lý do trực tiếp từ Player Fantasy: mở Wardrobe không được cảm thấy như "rời khỏi Mochi để vào 1 cửa hàng riêng" — giữ Mochi visible cũng khiến Pet Equipment's AC-1 (outfit overlay update trong 1 frame khi tap item) thực sự QUAN SÁT ĐƯỢC bởi bé ngay lúc đang chọn đồ, không cần đóng sheet để xem kết quả.
- Chrome (status row + level bar) bị che sau scrim khi bất kỳ modal nào mở (đã đúng theo Core Rule 1's z-order) — chỉ Mochi cần giữ visible, chrome không cần.

**Mochi sprite size — ✅ CONFIRMED FINAL (Art Bible Section 5.2, 2026-07-14):**

| Evolution Stage | Sprite bounding-box height (dp, design scale) | Padding (Formula 2) | Ghi chú |
|---|---|---|---|
| Baby (L1) | 72dp | 4dp → hitBoxSize 80dp | Gần sát `hitBoxMin`, padding nhỏ nhưng vẫn dương |
| Young (L2–L3) | 112dp | 0dp → hitBoxSize 112dp | Đã vượt `hitBoxMin`, không cần mở rộng |
| Grown (L4–L5) | 152dp | 0dp → hitBoxSize 152dp | Thay thế placeholder 96dp cũ — đủ lớn để carry body-language mood cues mà Player Fantasy dựa vào |

- **Đã đóng (2026-07-14)**: Art Bible Section 5 (Character Design Direction) đã Complete và xác nhận chính thức 3 giá trị này là final pin — không còn là recommendation tạm thời.
- Nhất quán với Tuning Knob "Mochi max scale = 1.0 (không scale up)": vì không có runtime scale-up, sprite base PHẢI đã là kích thước hiển thị cuối cùng — nên các giá trị trên được chọn ở mức "final-size" ngay từ đầu, không phải placeholder nhỏ cần phóng to sau.

📌 **Asset Spec** — Visual/Audio requirements đã được định nghĩa (background hybrid stage-set, chrome floating pill, modal placement, sprite-size final). Art Bible Section 5 đã Complete — có thể chạy `/asset-spec system:pet-room-screen-ui` ngay.

## UI Requirements

Pet Room Screen UI đóng góp 4 surfaces trên 1 route (Main Navigation Shell #17):
1. **`/child/pet-room`** (Tab 1, mặc định) — FlameGame canvas (background + Mochi) + persistent chrome (status row + level bar)
2. **Tap-on-Mochi context menu** — Flutter overlay, anchor tại Mochi
3. **Wardrobe bottom sheet** — Flutter bottom sheet, cap 60-65% chiều cao
4. **Mochi status row + level progress bar** — floating pill chrome

📌 **UX Flag — Pet Room Screen UI**: Cần `/ux-design` spec trước khi viết epics — đặc biệt: (1) composition tổng thể (background + Mochi + chrome + modal) cần wireframe để verify "Mochi không bị chrome/prop cạnh tranh sự chú ý" thực sự đúng trên màn hình thật, không chỉ trên giấy; (2) context menu's speech-bubble anchor positioning cần test trên nhiều kích thước màn hình (Mochi's vertical anchor 55% có thể cần responsive adjustment); (3) Wardrobe's 60-65% height cap cần verify trên màn hình nhỏ (kích thước phone thấp) rằng vẫn đủ chỗ cho 3 slot tab + grid mà không cảm thấy chật.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards table, mọi criterion tag `[LOGIC]` hoặc `[INTEGRATION]` là BLOCKING (automated test bắt buộc trước Done) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory (manual walkthrough đủ). Trong GDD này: **9 criteria** mang tag `[LOGIC]`/`[INTEGRATION]` và đều BLOCKING — Core Rule 2, 3, 4, 9; Edge Case 1, 2, 4, 5; và cả 2 Formulas. Formula 1, Formula 2, và Edge Case 4 có annotation đường dẫn test cụ thể (`tests/unit/...`, `tests/integration/...`) vì chúng có contract toán học/integration rõ ràng nhất để viết test trước; các criteria `[LOGIC]`/`[INTEGRATION]` còn lại (Core Rule 2, 3, 4, 9; Edge Case 1, 2, 5) BLOCKING tương đương — chưa có đường dẫn test cụ thể gán sẵn, cần gán khi viết stories, không phải vì chúng ít quan trọng hơn.

**Core Rule 1 — Screen composition (z-order)** `[UI]`
- **GIVEN** `/child/pet-room` render với 0 modal nào mở, **WHEN** kiểm tra thứ tự layer, **THEN** đúng 3 layer tồn tại theo z-order: room background (thấp nhất) → `MochiComponent` (giữa) → Flutter overlay chrome (status row + level bar, cao nhất) — không có modal layer nào mounted.
- **GIVEN** bất kỳ modal nào đang mở (context menu HOẶC Wardrobe bottom sheet, không đồng thời), **THEN** modal đó render trên TẤT CẢ layer khác kể cả overlay chrome.

**Core Rule 2 — FlameGame hosting** `[INTEGRATION]`
- **GIVEN** app khởi động lần đầu, **WHEN** Main Navigation Shell (#17) render Tab 1 mặc định, **THEN** route active là `/child/pet-room` và `GameWidget` chứa đúng 1 `FlameGame` instance với `MochiComponent` + background component đã mounted trong component tree.

**Core Rule 3 — GameEventBus không tự init** `[INTEGRATION]`
- **GIVEN** `/child/pet-room` mount, **THEN** màn hình chỉ subscribe vào `GameEventBus().stream` — code của GDD này không gọi bất kỳ hàm `.init()`/reset method nào của bus (regression check chống double-init). **Lưu ý implementation**: vì `GameEventBus` dùng Dart factory-constructor singleton pattern, gọi `GameEventBus()` để lấy instance (bước bắt buộc để `.stream.listen(...)`) LUÔN hợp lệ — kể cả khi đây là lần gọi đầu tiên trong toàn app (sẽ trigger lazy-init an toàn, không phải "double-init"). Regression check chỉ nên fail nếu code gọi 1 hàm khởi tạo/reset RIÊNG (không phải factory constructor) — không fail chỉ vì gọi `GameEventBus()`.

**Core Rule 4 — Tap-on-Mochi hit area** `[LOGIC]` (xem Formula 2 cho case cụ thể)
- **GIVEN** `MochiComponent` dùng `TapCallbacks` mixin, **THEN** không có `TapDetector` nào được dùng ở component này (regression check theo `deprecated-apis.md`).
- **GIVEN** `spriteSize` bất kỳ giá trị >0, **WHEN** tap tại điểm nằm trong `hitBoxSize` đã tính (Formula 2) nhưng ngoài sprite hiển thị, **THEN** `onTapDown` vẫn fire.

**Core Rule 5 — Tap-on-Mochi context menu** `[UI]`
- **GIVEN** context menu đang mở, **WHEN** bé tap "Vuốt ve", **THEN** PLEASED trigger (#14) được gọi VÀ menu đóng ngay lập tức, không delay.
- **GIVEN** context menu đang mở, **WHEN** bé tap "Đóng", **THEN** menu dismiss, không có hành động nào khác được gọi.
- **GIVEN** context menu đang mở, **WHEN** bé tap "Thay đồ", **THEN** menu đóng NGAY VÀ Wardrobe bottom sheet bắt đầu mở — tại không thời điểm nào cả 2 modal cùng mounted.

**Core Rule 6 — Wardrobe bottom sheet** `[UI]`
- **GIVEN** Wardrobe bottom sheet mở, **THEN** đúng 3 slot tab hiển thị (icon + tên) và grid inventory hiển thị item khớp `slot` đang chọn, đọc từ `itemCatalogProvider`.
- **GIVEN** Wardrobe đang mở, **WHEN** bé tap "Đóng" HOẶC tap ngoài sheet, **THEN** sheet dismiss.

**Core Rule 7 — Mochi status row** `[UI]`
- **GIVEN** `petMoodProvider` trả về 1 trong 5 mood tier và `petEnergyProvider` trả về giá trị trong [10,100], **WHEN** `/child/pet-room` render, **THEN** mood icon và energy bar hiển thị đúng giá trị, ngay dưới Child app bar, không lấn vào #17's app bar territory.

**Core Rule 8 — Level progress bar** `[UI]`
- **GIVEN** `levelProgressProvider` trả về % bất kỳ trong [0,100) và level <5, **THEN** progress bar hiển thị đúng %.
- **GIVEN** level = 5 (MAX theo #16 Edge Case 4), **THEN** hiển thị text "MAX" — không hiển thị progress bar đầy rồi loop lại.

**Core Rule 9 — Offscreen persistence** `[INTEGRATION]`
- **GIVEN** triggered-state animation (BOUNCING/EXCITED/LEVELING_UP) bắt đầu chạy trong lúc bé đang ở `/child/pet-room`, **WHEN** bé chuyển sang tab khác trước khi animation hoàn tất, **THEN** Flame game loop KHÔNG bị dispose/pause — animation tiếp tục chạy tới hoàn tất dù không có ai xem.
- **GIVEN** animation đã hoàn tất trong lúc bé ở tab khác, **WHEN** bé quay lại `/child/pet-room`, **THEN** Mochi hiển thị đúng state cuối cùng (post-animation) — không replay animation, không snap về state cũ.

**Formula 1 — Draw call budget** `[LOGIC]` — BLOCKING, `tests/unit/pet-room-screen-ui/`
- **GIVEN** MVP scope (1 background, 1 Mochi base, 3 equipment slot luôn mounted), **THEN** `drawCalls_sceneFlame` = 5 chính xác (integer equality, không cần tolerance — mọi input là hằng số nguyên).
- **GIVEN** bất kỳ item nào equipped ở bất kỳ slot nào (kể cả default/"none"), **THEN** `drawCalls_sceneFlame` vẫn = 5 — equip/unequip không đổi draw call count.

**Formula 2 — Tap hit-area padding** `[LOGIC]` — BLOCKING, `tests/unit/pet-room-screen-ui/`
- **GIVEN** `spriteSize` = 56dp (< `hitBoxMin`), **THEN** `padding` = 12.0dp và `hitBoxSize` = 80.0dp (±0.01dp tolerance).
- **GIVEN** `spriteSize` = 96dp (> `hitBoxMin`), **THEN** `padding` = 0.0dp và `hitBoxSize` = 96.0dp (±0.01dp tolerance, verify `max(0, ...)` clamp hoạt động).
- **GIVEN** bất kỳ `spriteSize` ≥ 0, **THEN** `hitBoxSize` ≥ 80dp luôn đúng (property-based check).

**Edge Case 1 — Baby Mochi sprite < 80dp** `[LOGIC]`
- Trùng với Formula 2's worked example 1 — không cần AC riêng, tham chiếu lại.

**Edge Case 2 — Tap ngoài hit area nhưng gần Mochi** `[LOGIC]`
- **GIVEN** tap tại điểm ngoài `hitBoxSize` đã tính nhưng gần biên visual của sprite, **THEN** `onTapDown` KHÔNG fire, không có context menu nào mở, không hiển thị feedback lỗi nào.

**Edge Case 3 — Context menu tap ra ngoài** `[UI]`
- **GIVEN** context menu đang mở, **WHEN** bé tap bất kỳ đâu ngoài menu (kể cả trên Mochi), **THEN** menu dismiss, không hành động nào khác được trigger bởi cùng 1 tap đó.

**Edge Case 4 — Wardrobe mở + GameEvent mới đến** `[INTEGRATION]` — BLOCKING, `tests/integration/pet-room-screen-ui/`
- **GIVEN** Wardrobe bottom sheet đang mở, **WHEN** `petLeveledUp` (hoặc GameEvent tương tự) fire qua `GameEventBus`, **THEN** Pet State Machine (#6) xử lý internal state ngay (verify qua provider value đã update, không chỉ quan sát UI) — nhưng KHÔNG có animation/sprite-swap nào hiển thị chồng lên Wardrobe sheet.
- **GIVEN** cùng tình huống trên, **WHEN** Wardrobe đóng lại, **THEN** visual (LEVELING_UP animation) chạy đúng state đã được cập nhật trong lúc modal mở — không mất event, không animation sai state.

**Edge Case 5 — LEVELING_UP non-interruptible + tap** `[INTEGRATION]`
- **GIVEN** LEVELING_UP animation đang chạy, **WHEN** bé tap Mochi, **THEN** `onTapDown` vẫn fire nhưng context menu KHÔNG mở.
- **GIVEN** animation vừa hoàn tất, **WHEN** bé tap Mochi lại, **THEN** context menu mở bình thường.

**Edge Case 6 — `itemCatalogProvider` loading/error state** `[UI]`
- **GIVEN** `itemCatalogProvider` ở loading state khi Wardrobe mở, **THEN** grid hiển thị skeleton/shimmer — không crash, không hiển thị grid rỗng.
- **GIVEN** `itemCatalogProvider` trả về `AsyncError`, **THEN** grid hiển thị inline error state "Không tải được đồ — Thử lại" + nút retry — không crash sheet, không grid rỗng.

**Edge Case 7 — Room background load thất bại** `[UI]`
- **GIVEN** background asset load thất bại, **THEN** màn hình hiển thị solid pastel Cream Ivory thay thế — không lỗi hiển thị, không màn hình trắng/đen, Mochi và overlay chrome vẫn render bình thường phía trên.

## Open Questions

- ~~**Mochi sprite dp thật theo evolution stage**~~ — ✅ **Đã đóng (2026-07-14)**: Art Bible Section 5 (Character Design Direction) Complete, xác nhận final 72/112/152dp Baby/Young/Grown.
- **Room progression theo evolution stage**: Background hiện CONSTANT cho MVP (quyết định chủ ý, xem Overview + Visual/Audio Requirements). Nếu muốn room "lớn lên" cùng Mochi, đây nên là quyết định của Room Layout System (#28) khi được design, không retrofit vào GDD này.
- **Honey Gold hex inconsistency (cross-project, không riêng GDD này)**: Đã phát hiện và fix 4 instance trong session này — `seed-buffer.md`, `pet-equipment.md`, `gacha-loot.md`, `main-navigation-shell.md` (đều đã fix về `#FFD060`, canonical theo Art Bible). Pattern lặp lại đủ nhiều lần để không còn coi là ngẫu nhiên — khuyến nghị chạy `/consistency-check` toàn diện ngay sau khi GDD cuối cùng (#20 Shop & Reward UI) hoàn thành, thay vì tiếp tục flag-và-sửa ad-hoc từng GDD riêng lẻ.
