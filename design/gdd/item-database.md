# Item Database

> **Status**: Approved
> **Author**: User + Agents
> **Last Updated**: 2026-07-01
> **Implements Pillar**: Pillar 5 — Mỗi Bé Có Thế Giới Riêng (items are the vocabulary of self-expression)

## Overview

Item Database là module data catalog thuần túy của PetQuest — không có runtime logic, không có state machine. Nó định nghĩa toàn bộ các item có thể nhận được trong game: outfit cho Mochi, đồ trang trí phòng, và items đặc biệt. Mỗi item entry bao gồm định danh, giá xu, loại, slot trang bị, và asset reference.

Item data được lưu trong Firestore collection `items/` ở cấp global (không scoped theo family) — tất cả bé đều đọc từ cùng một catalog. Data tĩnh: items không thay đổi theo runtime. Shop System (#13) đọc catalog để hiển thị, Gacha/Loot (#12) đọc để xác định loot table, Pet Equipment (#15) đọc để render sprite đúng lên Mochi.

MVP catalog: **30 items**, chia thành các categories: outfit Mochi, phụ kiện Mochi, và đồ trang trí phòng. Catalog được thiết kế để có thể mở rộng không cần code change — thêm item mới = thêm Firestore document.

## Player Fantasy

Bé không nhìn thấy "Item Database" — bé nhìn thấy **chiếc mũ phù thủy lấp lánh trong Shop** và nghĩ: *"Còn 15 xu nữa là mua được rồi."*

Item Database là nơi mà ước mơ của bé tồn tại trước khi bé biết mình muốn nó. Khi một item mới được thêm vào catalog và xuất hiện trong Shop — đó là khoảnh khắc bé phát hiện ra một mục tiêu mới để phấn đấu. Khi Gacha roll ra một item rare từ catalog — đó là khoảnh khắc bất ngờ và vui sướng.

Tính đa dạng của catalog là điều đảm bảo rằng không bé nào có cùng một Mochi: 30 items với các style khác nhau — cute, cool, cozy — đủ để mỗi bé tìm thấy identity của mình trong đó. Catalog phong phú = Pillar 5 được sống.

## Detailed Design

### Core Rules

**1. Item Schema**

Mỗi item trong Firestore `items/{itemId}` có cấu trúc:

```
items/{itemId}
  ├── itemId: String          // unique key, kebab-case (e.g. "wizard-hat")
  ├── name: String            // display name ("Mũ Phù Thủy")
  ├── description: String     // flavor text ("Huyền bí và đáng yêu")
  ├── category: String        // 'mochi_outfit' | 'room_decoration' | 'special'
  ├── slot: String | null     // 'body_outfit' | 'hat' | 'accessory' | null (room items)
  ├── price: int              // xu price (10–200)
  ├── source: String          // 'shop' | 'gacha' | 'both'
  ├── assetId: String         // sprite asset reference key
  └── sortOrder: int          // display order in Shop UI — must be unique; assigned by seed script/admin convention. Duplicate sortOrder values cause non-deterministic ordering.
```

**2. Item Categories**

| Category | Mô tả | Slot | MVP count |
|----------|-------|------|-----------|
| `mochi_outfit` | Trang phục và phụ kiện cho Mochi | `body_outfit`, `hat`, hoặc `accessory` | 18 items |
| `room_decoration` | Đồ vật trang trí phòng Mochi | null (placed in room) | 10 items |
| `special` | Items đặc biệt — trophy/collectible. **Inventory-only**: không equip lên Mochi, không đặt vào phòng. Display-only bragging right. | null | 2 items |

**3. Equipment Slots**

Mochi có 3 slot trang bị (khớp với `equippedItems: Map<slotId, itemId>` trong Data Persistence GDD):

| Slot | Key | Mô tả | Ví dụ |
|------|-----|-------|-------|
| Body outfit | `body_outfit` | Trang phục toàn thân | Áo hoàng tử, Váy tiên |
| Hat | `hat` | Mũ, headband, tai | Mũ phù thủy, Vương miện |
| Accessory | `accessory` | Nhỏ gọn — kính, cà vạt, hoa | Kính tròn, Nơ hồng |

Mỗi slot chỉ chứa 1 item tại một thời điểm. Equip item mới → overwrite slot cũ (item cũ không mất, vẫn ở inventory).

**4. No Rarity System**

Items không có rarity tier. Differentiation chỉ qua `price` (xu cost) và `source` ('shop' / 'gacha' / 'both'). Items gacha-only tạo cảm giác "đặc biệt" mà không cần rarity label. Đơn giản cho MVP — có thể thêm rarity sau nếu Gacha GDD (#12) yêu cầu.

**5. Data Access Pattern**

- Item catalog: `get()` one-time khi app load (static data) → cached in Riverpod `itemCatalogProvider`
- Không dùng `snapshots()` stream — catalog không thay đổi trong session
- Full catalog cached locally sau lần đầu load

---

### States and Transitions

Item Database là pure data — không có state transitions. Items không thay đổi trạng thái. Ownership state (owned/not-owned) thuộc về `inventory/{itemId}` của từng child, không phải item catalog.

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Shop System (#13) | → reads | Full item catalog, `price`, `source`, `sortOrder` | `itemCatalogProvider` Riverpod |
| Gacha/Loot (#12) | → reads | `itemId` list by `source: 'gacha'\|'both'` | `itemCatalogProvider` filtered |
| Pet Equipment (#15) | → reads | `assetId`, `slot` for render | `itemCatalogProvider` lookup by itemId |
| Data Persistence (#4) | ← stores | `inventory/{itemId}` ownership records | batch write contract |

## Formulas

Item Database không có mathematical formulas. Thay vào đó, section này định nghĩa **price distribution contract** và **catalog load contract** — hai "formulas" dưới dạng rules mà downstream systems phụ thuộc vào.

**Price Distribution Contract:**

```
item.price ∈ [priceMin, priceMax]
```

| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Min price | `priceMin` | int | 10 | Cheapest item — reachable trong 1 ngày làm task |
| Max price | `priceMax` | int | 200 | Most expensive — aspirational goal (~2 tuần) |
| Recommended tiers | — | — | 10 / 30 / 60 / 100 / 150 / 200 | 6 price tiers để phân bổ 30 items |

**Recommended price distribution (30 MVP items):**

| Tier | Price | Count | Rationale |
|------|-------|-------|-----------|
| Starter | 10 xu | 5 | Tức thì có được — tạo cảm giác thành công sớm |
| Easy | 30 xu | 8 | 2 ngày làm task — reachable, satisfying |
| Mid | 60 xu | 8 | 4 ngày — cần kế hoạch ngắn hạn |
| Aspirational | 100 xu | 5 | ~1 tuần chăm chỉ |
| Premium | 150 xu | 3 | ~10 ngày — special items |
| Rare | 200 xu | 1 | ~2 tuần — the crown jewel item |

**Catalog Load Contract:**

```
loadTime = O(N) where N = itemCount
```

| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Item count (MVP) | `itemCount` | int | 30 | Tổng items trong catalog |
| Max catalog size | `maxItems` | int | 500 | Hard cap — trên đây phải paginate |
| Cache TTL | — | — | App session | Re-fetch khi app cold start, không re-fetch trong session |

## Edge Cases

- **Nếu `items/` collection rỗng hoặc chưa có data** (first deploy, Firestore chưa được seed): `itemCatalogProvider` trả về empty list. Shop hiển thị "Chưa có items" placeholder — không crash. Cần seed script chạy trước khi launch.

- **Nếu item có `slot = null` nhưng bé cố equip** (bug hoặc bad data): Pet Equipment System (#15) phải guard — chỉ render items với slot matching. `null` slot items là room decorations, không thể equip lên Mochi. Validate tại Pet Equipment layer, không phải Item Database.

- **Nếu `assetId` trỏ đến asset không tồn tại**: Pet Equipment (#15) và Shop (#13) phải render placeholder sprite (question mark hoặc empty silhouette) — không crash. Log warning để phát hiện missing asset sớm.

- **Nếu `price` vượt ngoài range [10–200]** (data entry lỗi): Shop System vẫn hiển thị và bán được — Item Database không enforce range. Range là design contract cho content creators, không phải runtime validation. Firestore Security Rules enforce `price >= 10 && price <= 200` (matching `priceMax` default) như một soft guard.

- **Nếu Gacha roll ra `itemId` được thêm vào Firestore sau khi session cache đã load**: `itemCatalogProvider.lookup(itemId)` trả về null — Gacha/Loot (#12) phải handle case này (render placeholder, re-fetch catalog nếu cần). Known limitation của one-time-load cache pattern — bé không bị crash nhưng item mới sẽ chỉ hiển thị đúng sau khi app restart.

- **Nếu `itemId` bị duplicate** (2 documents cùng ID): Firestore document ID là unique key — không thể duplicate. Impossible by design.

- **Nếu bé mua item đã có trong inventory**: Shop System (#13) và Data Persistence (#4) xử lý — `inventory/{itemId}` dùng `set()` idempotent. Item Database không liên quan.

- **Nếu catalog update mid-session** (admin thêm item mới vào Firestore): Bé không thấy item mới cho đến lần app restart tiếp theo (do `get()` one-time + session cache). Acceptable — items không cần real-time.

- **Nếu `source = 'gacha'` nhưng item xuất hiện trong Shop**: `source` field là source-of-acquisition, không phải visibility flag. Shop System (#13) phải filter `source != 'gacha'` khi render shop list. Item Database chỉ lưu data — visibility logic thuộc Shop GDD.

## Dependencies

**Upstream (Item Database cần):**
- Không có — zero upstream dependencies. Foundation system.

**Downstream (phụ thuộc vào Item Database):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Shop System (#13) | Full item catalog để hiển thị + filter | `itemCatalogProvider` |
| Gacha/Loot (#12) | List itemIds có `source: 'gacha'\|'both'` để roll | `itemCatalogProvider` filtered |
| Pet Equipment (#15) | `assetId` + `slot` cho từng itemId trong `equippedItems` | `itemCatalogProvider` lookup |
| Pet Room Screen UI (#18) | `itemCatalogProvider` trực tiếp cho Wardrobe grid display | `itemCatalogProvider` (thêm 2026-07-06, bidirectionality gap tìm thấy khi review-all-gdds — #18 đọc provider này trực tiếp, không chỉ qua #15, nhưng chưa được list ở đây) |

**Riverpod provider owned:**
```dart
final itemCatalogProvider = FutureProvider<List<ItemModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('items')
      .orderBy('sortOrder')
      .get();
  return snapshot.docs
      .map((doc) => ItemModel.fromFirestore(doc))
      .toList();
});
```

**Firestore collection owned:**
```
items/{itemId}          // global catalog — not scoped per family
  └── [full schema — see Core Rules]
```

**Firestore Security Rules (read-only for all authenticated users):**
```
match /items/{itemId} {
  allow read: if request.auth != null;
  allow write: if false;  // admin-only via Firebase console / seed script
}
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Total MVP items | 30 | 20–50 | Art scope quá lớn → delays | <20 → shop trống rỗng, bé hết mục tiêu nhanh | Tăng theo sprint; không giảm sau launch |
| `mochi_outfit` count | 18 | 12–30 | Art bottleneck | <12 → ít variety, Mochi trông giống nhau | 3 slots × 6 options mỗi slot = good baseline |
| `room_decoration` count | 10 | 6–20 | Room quá đông | <6 → phòng trống sau 1 tuần | Tăng khi có Room Layout GDD |
| `priceMin` | 10 xu | 5–20 | Quá xa tầm với bé mới | <5 → starter items mất giá trị tâm lý | Phải reachable trong 1 ngày làm task |
| `priceMax` | 200 xu | 100–500 | Bé bỏ cuộc trước khi đạt | <100 → không có aspirational goal dài hạn | Target: ~2 tuần chăm chỉ |
| Starter tier count (10 xu) | 5 | 3–8 | Bé mua hết quá nhanh → mất early-game goals | <3 → không có quick win sớm | First-session experience depends on this |
| `maxItems` (catalog cap) | 500 | 100–1000 | Catalog load time tăng | — | Paginate nếu vượt; MVP không gần con số này |

## Visual/Audio Requirements

Item Database là pure data — không có visual hoặc audio output trực tiếp. Tuy nhiên, section này định nghĩa **asset requirements** mà art pipeline phải deliver cho catalog:

**Sprite Requirements per Item:**
- Format: PNG với transparent background
- Mochi outfit sprites: 128×128px (rendered overlaid lên Mochi base sprite)
- Room decoration sprites: variable size, tối thiểu 64×64px, tối đa 256×256px
- Each item cần 2 variants: **preview thumbnail** (64×64, Shop grid) + **full render** (128×128, equip/room view)

**Visual Style (từ Art Bible):**
- Pastel palette — không có màu neon hay đen đậm
- Round shapes, corner radius ≥8px trên thumbnails
- "Muốn được ôm" test: mỗi item phải trông dễ thương khi ở kích thước 64×64

📌 **Asset Spec** — Visual/Audio requirements định nghĩa. Sau khi art bible được approve, chạy `/asset-spec system:item-database` để produce per-item visual specs, dimensions, và generation prompts.

## UI Requirements

Item Database không own UI screens. Tuy nhiên data schema của nó drive trực tiếp 2 UI systems:

- **Shop UI (#20)**: hiển thị `name`, `description`, `price`, thumbnail từ `assetId`, filter theo `category` và `source`
- **Pet Equipment UI (trong Pet Room Screen #18)**: hiển thị equipped items per slot, cho phép swap

📌 **UX Flag — Item Database**: Item data model drives Shop & Reward UI (#20) và Pet Room Screen UI (#18). Khi design các screens này, run `/ux-design` và reference Item Database schema (đặc biệt `category`, `slot`, `source` fields) để đảm bảo filter và sort UX phù hợp với data model.

## Acceptance Criteria

**GIVEN** app cold start và `items/` collection có 30 documents,
**WHEN** `itemCatalogProvider` load,
**THEN** trả về list 30 `ItemModel` objects, ordered by `sortOrder` — trong <2 giây trên 4G.

**GIVEN** `itemCatalogProvider` đã load trong session,
**WHEN** bé navigate giữa các screens nhiều lần,
**THEN** không có Firestore `get()` calls lặp lại — catalog được served từ Riverpod cache.

**GIVEN** một item có `category: 'mochi_outfit'` và `slot: 'hat'`,
**WHEN** Pet Equipment (#15) render `equippedItems`,
**THEN** item's `assetId` được lookup đúng từ catalog và sprite render tại slot `hat`.

**GIVEN** một item có `source: 'gacha'`,
**WHEN** Shop System (#13) render shop list,
**THEN** item không xuất hiện trong shop (filtered out) — chỉ available qua Gacha.

**GIVEN** `items/` collection rỗng (chưa seed),
**WHEN** app load,
**THEN** `itemCatalogProvider` trả về empty list, Shop hiển thị empty state — không crash, không NullPointerException.

**GIVEN** item có `assetId` trỏ đến asset không tồn tại,
**WHEN** Shop hoặc Pet Equipment render item,
**THEN** placeholder sprite hiển thị — không crash, warning được log.

**GIVEN** `itemCatalogProvider` đã load session với 30 items,
**WHEN** Shop queries items với `price <= 10`,
**THEN** ít nhất 5 items được trả về (starter tier count ≥ 5 per Tuning Knobs).

## Open Questions

- **Seed script**: Ai viết và maintain Firestore seed script cho 30 MVP items? Cần quyết định trước production sprint để có data cho dev/testing.
- **Room decoration placement**: Room decoration items có thêm field `dimensions` (width/height in room grid units) không? Cần input từ Room Layout System GDD (khi được design).
- **Gacha-exclusive visual distinction**: Gacha-only items (`source: 'gacha'`) có cần visual indicator đặc biệt (sparkle border, star badge) không? Cần input từ Gacha GDD (#12) và Shop UI (#20).
- **Item preview animation**: Items trong Shop có cần idle animation (sprite sheet) hay static PNG là đủ cho MVP? Ảnh hưởng đến asset production scope.
- **Content pipeline**: Sau MVP, ai có quyền thêm items mới? Firebase console (admin-only) hay cần một simple CMS tool?
- **`special` category**: 2 items trong category `special` là gì? Cần xác định trước art production — placeholder hoặc tạm đặt là seasonal items.
