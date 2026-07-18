# Pet Equipment System

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: Pillar 5 — Mỗi Bé Có Thế Giới Riêng (Mochi's look is the child's identity)

## Overview

Pet Equipment System cho phép bé **chọn item từ inventory và mặc lên Mochi** — thay đổi diện mạo của Mochi ngay lập tức. Bé có thể equip tối đa 3 items cùng lúc (1 per slot: `body_outfit`, `hat`, `accessory`), unequip bất cứ lúc nào, và Mochi sẽ spin khoe đồ mới mỗi khi được mặc outfit vừa mua.

**Infrastructure layer**: System quản lý `equippedItems: Map<slotId, itemId>` trong Firestore `children/{childId}`. Khi bé equip item mới, system ghi `equippedItems[slot] = newItemId` vào Firestore, đọc `assetId` từ Item Database để overlay lên Mochi sprite trong Flame, và emit `GameEvent(itemEquipped)` vào `GameEventBus` để Pet State Machine trigger `SHOWING_OFF` state.

**Player-facing layer**: Mochi trông khác nhau mỗi ngày tùy theo bé chọn mặc gì. Bạn bè thấy outfit trong Visit System (Alpha). Đây là cách bé nói "đây là Mochi của mình" với cả nhóm.

MVP scope: Equip/unequip 3 slots, persistent across sessions, Flame sprite overlay.

## Player Fantasy

Bé mở Wardrobe, vuốt qua từng item trong inventory. Chiếc mũ phù thủy lấp lánh mà bé đã dành cả tuần làm task để mua — giờ đây đang đội lên đầu Mochi. Mochi spin một vòng, đuôi vẫy, như thể đang hỏi: *"Mình có đẹp không?"*

**Cảm xúc mục tiêu**: *"Mochi là của mình. Không ai có Mochi giống mình cả."*

Đây không phải chỉ là equip stat. Đây là **tự thể hiện**. Mỗi outfit combo là một câu trả lời cho câu hỏi: bé muốn Mochi của mình trông như thế nào trong mắt bạn bè? Bạn A có Mochi mặc đồ hiệp sĩ. Bạn B có Mochi mặc đồ tiên. Bé của mình có Mochi... là của riêng mình.

Khoảnh khắc equip outfit mới — đặc biệt là item vừa Gacha được hoặc vừa mua sau nhiều ngày phấn đấu — là **payoff** của toàn bộ vòng lặp: làm task → nhận xu → mua item → mặc cho Mochi → khoe với bạn. Pillar 5 sống ở đây.

## Detailed Design

### Core Rules

1. Mochi có 3 equipment slots: `body_outfit`, `hat`, `accessory`. Mỗi slot luôn có giá trị — khi không equip item nào, slot chứa ID của **default base item** cho slot đó (không thể null).
2. Default base items: `body_outfit` = `"base-body"`, `hat` = `"base-hat-none"`, `accessory` = `"base-accessory-none"`. Đây là invisible/plain sprites, không có trong Shop hay Inventory.
3. Khi bé equip item: `equippedItems[slot] = newItemId` ghi vào Firestore. Item cũ vẫn ở inventory — không mất.
4. Khi bé unequip item: `equippedItems[slot] = defaultItemId[slot]` ghi vào Firestore.
5. Flame sprite overlay: mỗi slot có một `SpriteComponent` riêng được mount lên Mochi base component. System load `assetId` từ `itemCatalogProvider` → render overlay đúng slot.
6. Sau khi equip thành công: emit `GameEvent(itemEquipped)` → Pet State Machine trigger `SHOWING_OFF` (spin 360°, 2s).
7. Bé chỉ equip được item mà mình đang sở hữu (có trong `inventory/{itemId}`). Shop UI (#20) và Wardrobe đều enforce rule này.

### States and Transitions

| Action | Firestore write | GameEvent emitted | Visual result |
|--------|----------------|-------------------|---------------|
| Equip new item | `equippedItems[slot] = itemId` | `itemEquipped` | Sprite overlay cập nhật + SHOWING_OFF |
| Unequip item | `equippedItems[slot] = defaultId` | Không | Sprite overlay về base |
| App open / resume | Read `equippedItems` → restore overlays | Không | Mochi render đúng outfit đã lưu |

### Wardrobe Flow

1. Bé tap lên Mochi sprite → context menu nhỏ hiện ra (3 option: "Thay đồ 👗", "Vuốt ve 🐾", "Đóng").
2. Bé chọn "Thay đồ" → mở Wardrobe bottom sheet.
3. Wardrobe hiển thị 3 slot tabs (`Hat`, `Body`, `Accessory`) + grid inventory items cho tab đang chọn.
4. Item đang equipped hiển thị checkmark ✓. Item chưa sở hữu không hiện ở đây (Wardrobe chỉ show owned items).
5. Bé tap item → equip ngay, Wardrobe không đóng (bé có thể thay tiếp slot khác).
6. Tap item đang equipped → unequip (về default).
7. Bé đóng Wardrobe → changes đã được persist (mỗi equip là 1 Firestore write, không có "Save" button).

### Interactions with Other Systems

| System | Direction | Data |
|--------|-----------|------|
| Item Database (#3) | IN | `assetId`, `slot`, `category` per itemId → `itemCatalogProvider` |
| Data Persistence (#4) | OUT | `equippedItems: Map<String,String>` ghi vào `children/{childId}` |
| Pet State Machine (#6) | OUT | `GameEvent(itemEquipped)` → trigger `SHOWING_OFF` |
| GameEventBus (#5) | OUT | emit channel |
| Shop & Reward UI (#20) | IN | "Equip now?" shortcut sau khi mua item mới HOẶC sau khi Gacha item reveal (cùng 1 prompt UI, 2 đường vào) — gọi trực tiếp equip action, SAU ĐÓ #20 tự navigate về `/child/pet-room` (thêm 2026-07-06, fix Scenario 2 blocker từ review-all-gdds) để đảm bảo SHOWING_OFF payoff thực sự được witness, không chỉ chạy ngầm trên tab Shop |
| Pet Room Screen UI (#18) | IN | Mount Wardrobe bottom sheet, nhận tap-on-Mochi callback |

## Formulas

System này không có công thức toán học. Các contracts dưới đây là rules mà downstream systems phụ thuộc vào.

**Slot resolution contract:**
```
displayedAssetId(slot) = equippedItems[slot] ?? defaultItemId[slot]
```
- `equippedItems[slot]`: giá trị từ Firestore (itemId string)
- `defaultItemId[slot]`: hardcoded per slot — `"base-body"` / `"base-hat-none"` / `"base-accessory-none"`
- Output: `assetId` string tra cứu trong `itemCatalogProvider`

**Worked example**: bé chưa equip gì ở slot `hat` → `equippedItems["hat"]` không tồn tại trong Firestore (hoặc = `"base-hat-none"` sau lần write đầu) → `displayedAssetId("hat") = "base-hat-none"` → render sprite invisible/plain. Sau khi bé equip `"wizard-hat"` → `equippedItems["hat"] = "wizard-hat"` → `displayedAssetId("hat") = "wizard-hat"` → render sprite mũ phù thủy.

**Overlay render order (z-index):**
```
z-index: base_mochi(0) < body_outfit(1) < accessory(2) < hat(3)
```
Hat luôn render trên cùng để không bị che bởi accessory.

**Worked example**: bé equip đồng thời `body_outfit="knight-armor"`, `accessory="scarf"`, `hat="wizard-hat"` → render order: Mochi base trước, rồi knight-armor overlay, rồi scarf overlay (đè lên armor), rồi wizard-hat overlay trên cùng (đè lên cả 2, không bị scarf che dù scarf ở vị trí cổ gần đầu).

**Ownership check:**
```
canEquip(itemId) = inventoryProvider.contains(itemId)
```
- `inventoryProvider`: `StreamProvider<Set<String>>` (owned by Shop System GDD #13)
- O(1) lookup

**Worked example**: `inventoryProvider` trả về `{"wizard-hat", "knight-armor"}`. `canEquip("wizard-hat") = true` (có trong set) → Wardrobe hiển thị item, cho phép tap-to-equip. `canEquip("dragon-hat") = false` (không có trong set) → item không hiển thị trong Wardrobe grid ở vị trí nào cả (không phải "hiển thị nhưng disabled" — ẩn hoàn toàn, theo Edge Case "bé không sở hữu item X").

## Edge Cases

- **If `equippedItems[slot]` là null trong Firestore** (document cũ trước khi field được thêm): fallback về `defaultItemId[slot]` — không crash.
- **If `itemId` trong `equippedItems` không tồn tại trong `itemCatalogProvider`** (item bị xóa khỏi catalog): render `defaultItemId[slot]` silently; log warning. Không thông báo bé — Mochi chỉ về base outfit.
- **If bé cố equip item không có trong inventory** (tampered state): `canEquip()` trả false → action bị block, không write Firestore. UI không bao giờ hiển thị nút equip cho unowned items.
- **If Firestore write fail** (offline + cache miss): equip vẫn apply local (Firestore offline cache), sync khi online. Nếu cache cũng fail: show snackbar "Không thể lưu thay đổi, thử lại sau" — outfit không thay đổi trên màn hình.
- **If bé equip item vào slot đang có item khác**: old item tự động về inventory (vẫn owned), new item vào slot. Không cần confirm dialog — equip là reversible.
- **If `SHOWING_OFF` animation đang chạy và bé equip thêm item thứ 2**: Pet State Machine priority rules xử lý (SHOWING_OFF = SHOWING_OFF priority → reset timer, replay spin với outfit mới).
- **If item có `category: 'special'`** (inventory-only trophy từ Item Database GDD): không hiện trong Wardrobe slot tabs — special items không equippable. UI filter ra.
- **If bé có 0 items trong inventory cho một slot**: Wardrobe hiển thị slot đó empty với message "Chưa có đồ — vào Shop để mua nhé!" — không crash.

## Dependencies

### Upstream Dependencies (system này cần)

| System | GDD | Interface cần |
|--------|-----|---------------|
| Item Database (#3) | `item-database.md` ✅ | `itemCatalogProvider` — lookup `assetId`, `slot`, `category` per itemId |
| Data Persistence (#4) | `data-persistence-layer.md` ✅ | `equippedItems: Map<String,String>` field trong `children/{childId}` |
| Flutter-Flame Bridge (#5) | `flutter-flame-state-bridge.md` ✅ | `GameEventBus.emit(GameEvent(itemEquipped))` |
| Pet State Machine (#6) | `pet-state-machine.md` ✅ | Lắng nghe `itemEquipped` event → trigger `SHOWING_OFF` state |
| Shop System (#13) | `shop-system.md` (Designed, chưa Approved — sửa checkmark sai trước đó) | `inventoryProvider: StreamProvider<Set<String>>` — ownership check |

### Downstream Dependents (system này enables)

| System | GDD | Expects gì từ system này |
|--------|-----|--------------------------|
| Pet Room Screen UI (#18) | Approved ✅ | Mochi sprite với overlays đã được render đúng; tap-on-Mochi → Wardrobe callback |
| Shop & Reward UI (#20) | Reviewed — NEEDS REVISION, đã fix (2026-07-06) | "Equip now?" action sau purchase HOẶC sau Gacha item reveal (cùng 1 prompt UI, 2 đường vào) — gọi equip flow trực tiếp |
| Visit System (#29) | Alpha | `equippedItems` snapshot để render Mochi của bạn bè |

### Hard vs. Soft Dependencies

- **Hard**: Item Database, Data Persistence, inventoryProvider (Shop System #13), Flutter-Flame Bridge/GameEventBus (#5) — không thể emit `itemEquipped` hoặc render overlay nếu thiếu (bỏ sót #5 ở bản trước dù đã list làm Upstream Dependency).
- **Soft**: Pet State Machine — SHOWING_OFF animation không chạy nhưng equip vẫn hoạt động; Visit System — chỉ cần khi Alpha.

## Tuning Knobs

| Knob | Default | Min | Max | Hậu quả nếu quá thấp | Hậu quả nếu quá cao |
|------|---------|-----|-----|----------------------|---------------------|
| `wardrobe_context_menu_timeout` | 3000ms | 1500ms | 6000ms | Menu biến mất quá nhanh trước khi bé chọn | Menu lơ lửng quá lâu, cản UI |
| `equip_write_debounce` | 300ms | 0ms | 500ms | Spam equip → nhiều Firestore writes liên tiếp | Outfit delay cảm giác lag |
| `overlay_load_timeout` | 2000ms | 500ms | 5000ms | Asset chưa load đã timeout → fallback base | Màn hình đứng chờ quá lâu khi load outfit |

**Không định nghĩa lại**: `showing_off_duration` (2000ms) thuộc Pet State Machine (#6)'s Tuning Knobs — #6 sở hữu timer cho TẤT CẢ Triggered States (EXCITED/PLEASED/SHOWING_OFF/BOUNCING/LEVELING_UP) trong 1 bảng thống nhất. Đã fix 2026-07-06 (review-all-gdds W2) — GDD này trước đây duplicate ownership giá trị này, gây rủi ro 2 nguồn sự thật nếu retune sau này.

**Knob interactions**: `showing_off_duration` (owned by #6) nên match với `swipe_cooldown` trong Pet Interaction GDD (2000ms) để tránh bé trigger swipe trong lúc SHOWING_OFF.

## Visual/Audio Requirements

**Equip animation (SHOWING_OFF)** — GDD này SỞ HỮU particle spec cho animation này (thay thế "Confetti" generic ở #6's bảng, đã reconcile 2026-07-06 khi review phát hiện conflict):
- Mochi spin 360° ease-out trong 0.5s, sau đó bounce nhẹ lên 8dp rồi về (0.3s)
- Equipped overlays (body_outfit/hat/accessory) spin THEO Mochi — hệ quả tự nhiên của Core Rule 5 (overlay là child component mount lên base, transform propagate xuống theo Flame's component tree). Không cần logic đồng bộ riêng.
- Trong lúc spin: sparkle particles (4–6 hạt) tỏa ra từ outfit area, fade 1.0s
- Màu sparkle: Honey Gold `#FFD060` (Art Bible Section 4 canonical hex, semantic "Achievement/reward") cho `body_outfit`/`hat`; cho `accessory` dùng Cloud White `#FFFFFF` với viền Lavender Soft `#C5A3E0` nhạt thay vì bạc `#C0C0C0` thuần (Art Bible không có "silver" trong palette — sửa từ giá trị chưa sourced trước đó)
- Total SHOWING_OFF duration: 2000ms

**Sprite overlay specs:**

> ⚠️ **Sửa 2026-07-14** (Art Bible Section 5.5, Character Design Direction — amend): dòng "scale đồng nhất" bên dưới đã bị thay thế. Mochi's proportions thay đổi CHẤT (head-to-body ratio, độ dài tai, độ đầy đuôi) qua 3 evolution stage — một asset outfit làm khớp với Grown sẽ bị lệch vị trí nếu chỉ scale đồng nhất xuống Baby's tỷ lệ thân hình khác hẳn. Mỗi equipment item giờ cần **3 biến thể art riêng, 1 cho mỗi evolution stage** (Baby/Young/Grown), mỗi biến thể có anchor point riêng theo stage (xem Art Bible §5.5 cho anchor rule chi tiết per slot). Đây là tăng chi phí sản xuất asset (3x thay vì 1x mỗi outfit) — chấp nhận đánh đổi để tránh outfit lệch vị trí nhìn thấy được.

- Mỗi slot overlay là `SpriteComponent` riêng, transparent background (PNG với alpha)
- ~~Kích thước overlay = kích thước Mochi base sprite (scale đồng nhất)~~ **Mỗi equipment item có 3 asset variant (Baby/Young/Grown), mỗi variant tự căn đúng theo anchor point của stage đó — không phải 1 asset scale đồng nhất.** Anchor points: `hat` = điểm giữa 2 tai theo vị trí gốc tai của từng stage; `body_outfit` = tâm thân, scale theo silhouette thân của stage; `accessory` = vị trí cổ/lưng, tránh vùng đuôi.
- Silhouette-preservation: `hat` phải để lộ ≥50% tai (không bao trọn tai ở bất kỳ stage nào); `body_outfit` không được che gốc tai hay vùng đuôi; `accessory` không phủ lên vùng đuôi.
- z-index render order: base(0) → body_outfit(1) → accessory(2) → hat(3)
- Khi load asset: hiển thị placeholder trong suốt (không flash) cho đến khi asset ready
- **Asset production impact**: mỗi item trong Shop catalog (Item Database #3) cần 3 file asset thay vì 1 — cập nhật Asset Standards (Art Bible Section 8, Pending) khi author, và tăng ước tính effort cho content-production epics.

**Wardrobe context menu:**
- Bottom sheet slide-up animation: 250ms ease-out
- Item grid: 3 cột, thumbnail vuông 64×64dp, checkmark ✓ overlay (Mint Breeze `#A8E6CF`, Art Bible Section 4 canonical hex — sửa từ Material green `#4CAF50` chưa sourced trước đó) cho item đang equipped
- Slot tabs highlight màu theo category: Hat=tím, Body=xanh, Accessory=hồng (theo art bible palette)

**Audio (placeholder — Audio GDD #22 sẽ xác nhận):**
- Equip sound: soft "whoosh" + chime ~0.4s
- Unequip sound: soft "pop" ~0.2s
- Wardrobe open: page-flip sound ~0.3s

📌 **Asset Spec** — Visual/Audio requirements đã được định nghĩa. Sau khi art bible được approved, chạy `/asset-spec system:pet-equipment` để sinh per-asset specs và generation prompts.

## UI Requirements

Wardrobe là bottom sheet Flutter (không phải Flame component) slide lên từ Pet Room Screen. Gồm: (1) 3 slot tabs trên cùng với icon + tên slot, (2) grid inventory items cho slot đang chọn, (3) nút "Đóng" hoặc tap ngoài để dismiss. Tap-on-Mochi context menu là Flutter overlay Widget (3 option: Thay đồ / Vuốt ve / Đóng). Pet Room Screen UI (#18) sở hữu layout — system này định nghĩa behavior, không phải pixel.

📌 **UX Flag — Pet Equipment**: System này có UI requirements. Trong Phase 4 (Pre-Production), chạy `/ux-design` để tạo UX spec cho Wardrobe screen và Mochi context menu trước khi viết epics.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory.

- **AC-1** `[INTEGRATION]` BLOCKING — GIVEN bé sở hữu item `"wizard-hat"` (slot: hat), WHEN bé tap item trong Wardrobe, THEN `equippedItems["hat"] = "wizard-hat"` được ghi vào Firestore và hat overlay render lên Mochi trong vòng 1 frame.
- **AC-2** `[INTEGRATION]` BLOCKING — GIVEN bé vừa equip item, THEN `GameEvent(itemEquipped)` được emit và Mochi chạy SHOWING_OFF animation (spin 360°, equipped overlays spin theo) trong 2000ms.
- **AC-3** `[LOGIC]` BLOCKING — GIVEN item đang equipped ở slot hat, WHEN bé tap lại item đó trong Wardrobe, THEN `equippedItems["hat"] = "base-hat-none"` và hat overlay về base sprite.
- **AC-4** `[LOGIC]` BLOCKING — GIVEN bé equip item ở slot A, WHEN bé equip item khác ở slot B, THEN cả hai slot được render độc lập — slot A không thay đổi.
- **AC-5** `[LOGIC]` BLOCKING — GIVEN `equippedItems["hat"]` là null trong Firestore, WHEN app mở, THEN Mochi render với `"base-hat-none"` — không crash.
- **AC-6** `[LOGIC]` BLOCKING — GIVEN item có `category: 'special'`, WHEN bé mở Wardrobe, THEN item đó không xuất hiện trong bất kỳ slot tab nào.
- **AC-7** `[LOGIC]` BLOCKING — GIVEN bé không sở hữu item X, THEN item X không xuất hiện trong Wardrobe grid — không có cách equip item chưa owned (regression risk: nếu logic lọc sai, bé có thể equip item chưa mua — silent economy bug, không có triệu chứng UI rõ ràng).
- **AC-8** `[INTEGRATION]` BLOCKING — GIVEN bé equip item khi offline, THEN outfit thay đổi ngay trên màn hình; khi online trở lại, Firestore sync đúng giá trị.
- **AC-9** `[UI]` — GIVEN bé có 0 items trong inventory cho slot `accessory`, WHEN bé mở tab Accessory trong Wardrobe, THEN hiển thị "Chưa có đồ — vào Shop để mua nhé!" — không crash.
- **AC-10** `[LOGIC]` BLOCKING — GIVEN Wardrobe đang mở, WHEN bé equip 3 items liên tiếp (mỗi slot 1 item), THEN mỗi equip ghi đúng Firestore và Mochi overlay cập nhật sau mỗi lần — không cần "Save".

## Open Questions

1. **Preview trước khi equip?** — Bé có thể "thử" outfit lên Mochi trước khi confirm equip không? Không đưa vào MVP (equip là instant + reversible đủ rồi). Owner: UX Designer. Target: Vertical Slice review.
2. **Outfit set / preset** — Bé save combo 3 slot thành 1 "look" và switch nhanh? Post-MVP feature. Owner: Game Designer.
3. **Item thumbnail assets** — 30 thumbnail 64×64dp cần được sinh trước khi Wardrobe có thể test. Owner: Art Director. Dependency: Art Bible approval.
