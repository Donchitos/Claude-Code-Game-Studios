# Shop System

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-11 (ADR-0011 GDD sync — purchase mechanism moved WriteBatch→runTransaction)
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật (xu earned through effort is spent here)

## Overview

Shop System là nơi bé **tiêu xu** — đổi công sức thành vật phẩm cho Mochi. Đây là điểm cuối của vòng lặp kinh tế: Task → Xu → Shop → Item → Mochi đẹp hơn.

**Infrastructure layer**: Shop là một purchase pipeline gồm 3 bước: (1) hiển thị catalog items có `source: 'shop'|'both'` từ `itemCatalogProvider`, (2) affordability check (`xuBalance >= item.price`), (3) atomic batch write — `xuBalance -= item.price` và `inventory/{itemId}` được thêm cùng lúc. Không có refund, không có negative balance.

**Player-facing layer**: Bé browse catalog items được sắp xếp theo `sortOrder`, thấy giá và so sánh với số xu mình có. Items chưa đủ xu hiển thị "Còn thiếu X xu" progress bar. Mua thành công → item vào inventory, animation coins bay ra, bé có thể equip ngay.

Shop cũng bán **Paid Chest** (50 xu) — interface vào Gacha System. Paid chest được hiển thị như một special item trong shop, không phải tab riêng.

## Player Fantasy

Bé mở Shop và thấy chiếc **Vương Miện Vàng** đang chờ — 100 xu. Nhìn lại ví: 85 xu. *"Còn 15 xu nữa thôi."*

Cái thanh progress "Còn thiếu 15 xu" không phải là sự thất vọng — nó là **mục tiêu cụ thể**. Bé đóng Shop, làm thêm 1 bài tập toán, quét nhà một lần nữa. Ngày hôm sau mở Shop: 100 xu. Tap Mua. Coins bay ra. Vương Miện xuất hiện trong inventory. Mochi đội lên — xoay một vòng SHOWING_OFF.

Khoảnh khắc đó là **phần thưởng kép**: tự hào vì đã kiên trì đủ lâu, VÀ niềm vui thẩm mỹ khi thấy Mochi của mình trở nên độc đáo hơn. Không bé nào trong nhóm bạn có Mochi giống bé — vì không ai đã làm chính xác những việc bé đã làm.

Shop là nơi **effort trở thành identity**.

## Detailed Design

### Core Rules

**1. Catalog Display Rules**

- Show only items with `source: 'shop'|'both'` — never `source: 'gacha'` only
- Items already owned (in `inventory/{itemId}`) show "Đã có" badge — still visible, cannot re-purchase
- Paid Chest (50 xu) displayed as a special entry at top of catalog — always available regardless of inventory
- Catalog sorted by `sortOrder` (ascending) within each tab

**2. Tab Structure**

| Tab | Filter | Includes |
|-----|--------|---------|
| Tất cả | `source: 'shop'\|'both'` | All purchasable items + Paid Chest |
| Trang phục | `category: 'mochi_outfit'` | Body outfits, hats, accessories |
| Trang trí phòng | `category: 'room_decoration'` | Room items |
| Đặc biệt | `category: 'special'` | Trophy/collectible items |
| 🎲 Rương | Paid Chest entry | 1 entry: "Rương May Mắn — 50 xu" |

**3. Purchase Flow**

**Sửa lỗi so với bản trước (2026-07-11, ADR-0011)**: Purchase write đã đổi từ `WriteBatch` sang `runTransaction` — xem Dependencies/Firestore writes bên dưới. Lý do: `WriteBatch` không idempotent trên `xuBalance` dưới race 2 lần mua trùng (TR-shop-003/QQ-01), `runTransaction` đọc `inventory/{itemId}` trước khi quyết định ghi, tự nhiên idempotent theo item ID. Hệ quả: mua hàng giờ cần kết nối mạng (runTransaction không queue offline) — cùng tradeoff Parent Approval (#11) đã chấp nhận.

```
[Bé tap item card]
        │
        ▼
Affordability check (client pre-check, UX only): xuBalance >= item.price?
        │
        ├── YES → Show "Mua" confirm button
        │           │
        │           ▼
        │     connectivity_plus check: offline?
        │       ├── YES → "Cần kết nối mạng để mua" — không gọi transaction
        │       └── NO ↓
        │           │
        │           ▼
        │     runTransaction (single-flight guard đã disable mọi nút Mua khác):
        │       đọc inventory/{itemId} trước — đã tồn tại? → no-op, PurchaseResult.alreadyOwned
        │       đọc xuBalance (server-side re-check) — không đủ? → PurchaseResult.insufficientFunds
        │       đủ điều kiện → FieldValue.increment(-item.price) trên xuBalance
        │                    + inventory/{itemId}.set({ itemId, acquiredAt: serverTimestamp(), source: 'shop' })
        │           │
        │           ▼
        │     Thành công → Purchase animation → "Equip now?" prompt
        │     Thất bại (bất kỳ lý do — offline phát hiện muộn, transient error, contention) →
        │       re-enable nút Mua, toast "Mua không thành công, thử lại" — không có gì bị mất
        │
        └── NO → Show disabled state + "Còn thiếu X xu" progress bar
                  No transaction triggered
```

**4. Paid Chest Purchase**

Paid Chest là special purchase — không tạo `inventory/{itemId}`, nên không có natural idempotency key như item thường. Dùng client-generated `purchaseId` (UUID v4) làm idempotency token thay thế:
```
runTransaction (purchaseId được generate 1 LẦN khi tap "Mua Rương", giữ nguyên xuyên suốt
mọi lần retry của CÙNG 1 lần mua — KHÔNG generate mới mỗi lần tap):
  đọc purchaseLog/{purchaseId} trước — đã tồn tại? → no-op, PurchaseResult.alreadyProcessed
  đọc xuBalance (server-side re-check) — không đủ? → PurchaseResult.insufficientFunds
  đủ điều kiện →
    FieldValue.increment(-50) on xuBalance
    FieldValue.increment(+1) on chestCount
    purchaseLog/{purchaseId}.set({ purchaseId, type: 'paidChest', processedAt: serverTimestamp() })
        │
        ▼ (thành công)
Purchase animation plays (cùng animation spec ở Visual/Audio Requirements — coins-fly 500ms +
card-pop 300ms — nhưng "Mua thành công!" toast bị SUPPRESS riêng cho path này, theo quyết định
của Shop & Reward UI #20's Core Rule 1, vì ceremony sắp tới đã re-confirm kết quả)
        │
        ▼
onAnimationComplete callback (PurchaseAnimationCompleteCallback, typedef void Function() —
xem ADR-0011 Key Interfaces) fires → Shop & Reward UI (#20) subscribe callback này để unlock
navLocked guard và auto-navigate vào Chest Open ceremony (Gacha UI). Chỉ fire khi
PurchaseResult.success — KHÔNG fire khi alreadyProcessed/insufficientFunds/thất bại.
```
**Sửa lỗi so với bản trước (2026-07-06)**: Core Rule này trước đây bỏ qua bước Purchase Animation hoàn toàn, mô tả navigate như xảy ra ngay lập tức sau batch write — điều này không khớp với #20's Formula 1, vốn cần ~800ms animation window để `onAnimationComplete` callback có ý nghĩa. Animation PHẢI chạy (silent, không toast) trước khi navigate, không phải optional hay bị bỏ qua.

**Sửa lỗi so với bản trước (2026-07-11, ADR-0011)**: Write mechanism đổi từ `WriteBatch` sang `runTransaction` + `purchaseId` idempotency token — đóng gap TR-shop-003/QQ-01 cho Paid Chest (không có natural key như item, nên cần token riêng). Xem AC-9 và Edge Cases bên dưới.

**5. No-Refund Rule**

Không có refund flow. Mua xong → item trong inventory vĩnh viễn. Confirm step ("Bạn có muốn mua không?") trước khi batch write để tránh accidental purchase.

**6. Already-Owned Items**

Items đã có trong inventory vẫn hiển thị trong Shop với "Đã có ✓" badge. Mua button disabled. Bé có thể xem lại items đã sưu tập — không bị ẩn.

---

### States and Transitions

```
[Item card]
    │
    ├── affordable + not owned → [Mua] button active
    ├── not affordable + not owned → [disabled] + "Còn thiếu N xu"
    └── owned → [Đã có ✓] badge, Mua disabled

[Tap Mua] → Confirm dialog → [Confirm] → batch write → purchase animation
                             → [Cancel] → return to item card
```

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Item Database (#3) | → Shop | Full item catalog, filtered by `source` | `itemCatalogProvider` |
| Currency System (#7) | ↔ Shop | `xuBalance` read (affordability) + decrement (purchase) | `xuBalanceProvider` + `FieldValue.increment(-price)` |
| Gacha/Loot (#12) | ← Shop | Paid chest purchase → `chestCount += 1` | batch write on chest purchase |
| Data Persistence (#4) | ← Shop | `inventory/{itemId}` write + `xuBalance` decrement | Firestore batch contract |
| Shop & Reward UI (#20) | ← Shop | Catalog display, purchase states, animations | `itemCatalogProvider`, `xuBalanceProvider`, `inventoryProvider` |
| Shop & Reward UI (#20) | ← Shop | `onAnimationComplete` callback trên Paid Chest's purchase animation (nay đã explicit ở Core Rule 4) — #20's `navLocked` guard (Formula 1) subscribe callback này để biết khi nào unlock Chest badge và auto-navigate vào Chest Open ceremony. Interface mới, chưa implement — Visual/Audio Requirements hiện tại chỉ có duration bằng prose, cần expose 1 API completion signal thật khi implement (sửa hướng mũi tên — data flow là Shop → #20, cùng chiều với row phía trên, không phải ngược lại) | `onAnimationComplete` callback (mới, cần thêm khi implement, chỉ cho Paid Chest path) |

## Formulas

Shop System không có mathematical formulas. Thay vào đó, section này định nghĩa **purchase validity contract** và **affordability display contract**.

**Purchase Validity Contract:**

```
canPurchase = (xuBalance >= item.price) AND (itemId NOT IN inventory)
```

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Current balance | `xuBalance` | int | 0–∞ | Từ `xuBalanceProvider` |
| Item price | `item.price` | int | 10–200 | Từ `itemCatalogProvider` |
| Item owned? | `isOwned` | bool | true/false | Check `inventory/{itemId}` exists |
| Can purchase | `canPurchase` | bool | true/false | Computed pre-render |

**Affordability Gap Display:**

```
xuNeeded = item.price - xuBalance   (only shown when xuBalance < item.price)
progressFraction = xuBalance / item.price   (0.0–1.0, for progress bar fill)
```

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Xu still needed | `xuNeeded` | int | 1–200 | Shown as "Còn thiếu N xu" |
| Progress fraction | `progressFraction` | float | 0.0–1.0 | Progress bar fill width |

**Example:** item.price = 100, xuBalance = 85 → xuNeeded = 15, progressFraction = 0.85 → bar 85% full, label "Còn thiếu 15 xu".

## Edge Cases

- **Nếu `xuBalance` thay đổi trong khi bé đang xem item** (approve xảy ra real-time): `xuBalanceProvider` stream update → UI re-renders affordability state tự động. Item vừa không đủ xu có thể trở thành đủ xu mà không cần bé refresh.

- **Nếu bé tap Mua và `xuBalance` giảm xuống dưới `item.price` trước khi transaction commit** (race condition guard) — **RESOLVED (ADR-0011)**: `runTransaction` đọc `xuBalance` bên trong transaction ngay trước khi ghi (server-side re-check) — nếu không đủ, trả `PurchaseResult.insufficientFunds`, không ghi gì. Không cần Security Rule/Cloud Function riêng cho việc này.

- **Nếu `itemCatalogProvider` chưa load khi bé vào Shop**: Hiển thị loading skeleton — không render empty shop. Mua button disabled cho đến khi catalog ready.

- **Nếu inventory check fails** (Firestore offline): Assume not owned — show item as purchasable. `runTransaction` sẽ tự re-verify ownership thật khi transaction chạy (đọc `inventory/{itemId}` là bước đầu tiên bên trong transaction) — kể cả khi client-side `inventoryProvider` cache sai, transaction vẫn không double-grant.

- **Nếu bé tap Mua Paid Chest khi `xuBalance < 50`**: Affordability check blocks — entry hiển thị "Còn thiếu N xu". Transaction không trigger (client pre-check); nếu vẫn lọt qua, server-side re-check bên trong transaction chặn lại (`PurchaseResult.insufficientFunds`).

- **Nếu `item.source = 'gacha'`** (data error): Shop filter `source IN ['shop', 'both']` loại item này khỏi display. Defense-in-depth.

- **Nếu bé tap Confirm 2 lần nhanh** (double-tap): Confirm button disabled ngay sau tap đầu tiên (single-flight guard, ADR-0008) — transaction chỉ xảy ra 1 lần. Re-enable sau khi transaction completes hoặc fails.

- **Nếu device offline khi bé tap Mua** — **MỚI (ADR-0011)**: `connectivity_plus` pre-check disable nút Mua, hiển thị "Cần kết nối mạng để mua" — không có transaction attempt nào tới Firestore. Nếu device báo có mạng nhưng Firestore thực tế không reachable: transaction vẫn throw, rơi vào nhánh xử lý lỗi thống nhất bên dưới (cùng pattern Parent Approval #11 Edge Case 1/7).

- **Nếu transaction fails** (bất kỳ lý do — offline phát hiện muộn, transient backend error, contention exhausted sau internal retry của SDK): Không partial write nào tồn tại (transaction all-or-nothing) — `xuBalance`/`inventory`/`chestCount` không đổi. Error toast "Mua không thành công, thử lại", nút Mua re-enable. Không có client-side retry loop tự động — 1 tap mới của bé chính là lần retry.

- **Nếu 2 lần mua CÙNG 1 item commit gần như đồng thời** (2 devices cùng account, hoặc 1 transaction bị client coi là fail nhưng thực ra đã commit, rồi bé tap mua lại) — **RESOLVED (ADR-0011)**: `runTransaction` đọc `inventory/{itemId}` TRƯỚC KHI quyết định ghi — nếu đã tồn tại, no-op (`PurchaseResult.alreadyOwned`), không decrement lần 2. Item ID chính là idempotency key tự nhiên — đúng với MỌI số lần retry, không phụ thuộc client có generate token mới hay không. Xem ADR-0011 Decision §1 + Validation Criteria.

- **Nếu 2 lần mua Paid Chest commit gần như đồng thời** — **MỚI (ADR-0011)**: Paid Chest không có document tự nhiên để idempotency-check như item (mua 2 rương là hợp lệ). Dùng `purchaseId` (UUID, generate 1 LẦN khi tap, giữ nguyên xuyên suốt mọi lần retry của CÙNG 1 lần mua — KHÔNG generate mới mỗi lần tap) làm idempotency token, check qua `purchaseLog/{purchaseId}` bên trong transaction. 2 lần mua với CÙNG `purchaseId` → chỉ 1 lần commit (`PurchaseResult.alreadyProcessed` cho lần thứ 2). 2 lần mua với `purchaseId` KHÁC nhau (2 rương thật sự riêng biệt) → cả 2 đều thành công bình thường. Xem ADR-0011 Decision §2 + Validation Criteria.

## Dependencies

**Upstream (Shop cần):**
- **Item Database (#3)** ✅ — item catalog (`source`, `price`, `category`, `sortOrder`, `assetId`)
- **Currency System (#7)** ✅ — `xuBalance` read + `FieldValue.increment(-price)` pattern
- **Gacha/Loot (#12)** ✅ — `chestCount` increment contract for paid chest purchase
- **ADR-0011 (Shop Purchase Pipeline & Idempotency Fix)** ✅ — `runTransaction` idempotency mechanism, offline-blocking behavior, `onAnimationComplete` interface, `purchaseLog` Security Rule (added 2026-07-11)

**Downstream (phụ thuộc vào Shop):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Shop & Reward UI (#20) | Catalog display, purchase states, affordability data | `itemCatalogProvider`, `xuBalanceProvider`, `inventoryProvider` |
| Pet Equipment System (#15) | `inventoryProvider` cho ownership check (`canEquip()`) trước khi cho phép equip | `inventoryProvider: StreamProvider<Set<String>>` (được thêm 2026-07-06 — bidirectionality gap tìm thấy khi review #15: #15 đã consume provider này nhưng #13 chưa list #15 làm downstream) |
| Gacha/Loot System (#12) | `inventoryProvider` cho duplicate-check ở Formula 3/Step 2a (bé đã sở hữu item roll được chưa) | `inventoryProvider: StreamProvider<Set<String>>` (được thêm 2026-07-06 — cùng loại bidirectionality gap như #15: #12's review ngày 2026-07-06 đã list #13 làm upstream dependency, nhưng #13 chưa list #12 làm downstream ngược lại) |

**Riverpod provider owned:**
```dart
final inventoryProvider = StreamProvider<Set<String>>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .collection('families/$parentId/children/$childId/inventory')
    .snapshots()
    .map((s) => s.docs.map((d) => d.id).toSet());
});
// Returns Set<itemId> — O(1) ownership lookup for affordability checks
```

**Firestore writes owned (ADR-0011 — `runTransaction`, không phải `WriteBatch`):**
```dart
// Regular item purchase — idempotent on inventory/{itemId} (natural key)
Future<PurchaseResult> buyItem(String parentId, String childId, ItemModel item) {
  final childRef = FirestorePaths.child(parentId, childId);
  final invRef = FirestorePaths.inventoryItem(parentId, childId, item.id);
  return FirebaseFirestore.instance.runTransaction((txn) async {
    final invSnap = await txn.get(invRef);
    if (invSnap.exists) return PurchaseResult.alreadyOwned;
    final childSnap = await txn.get(childRef);
    final balance = (childSnap.data()?['xuBalance'] as num?)?.toInt() ?? 0;
    if (balance < item.price) return PurchaseResult.insufficientFunds;
    txn.update(childRef, { 'xuBalance': FieldValue.increment(-item.price) });
    txn.set(invRef, { 'itemId': item.id, 'acquiredAt': FieldValue.serverTimestamp(), 'source': 'shop' });
    return PurchaseResult.success;
  });
}

// Paid chest purchase — idempotent on purchaseLog/{purchaseId} (client-generated token)
Future<PurchaseResult> buyPaidChest(String parentId, String childId, String purchaseId) {
  final childRef = FirestorePaths.child(parentId, childId);
  final logRef = FirestorePaths.purchaseLog(parentId, childId, purchaseId);
  return FirebaseFirestore.instance.runTransaction((txn) async {
    final logSnap = await txn.get(logRef);
    if (logSnap.exists) return PurchaseResult.alreadyProcessed;
    final childSnap = await txn.get(childRef);
    final balance = (childSnap.data()?['xuBalance'] as num?)?.toInt() ?? 0;
    if (balance < paidChestPrice) return PurchaseResult.insufficientFunds;
    txn.update(childRef, { 'xuBalance': FieldValue.increment(-paidChestPrice), 'chestCount': FieldValue.increment(1) });
    txn.set(logRef, { 'purchaseId': purchaseId, 'type': 'paidChest', 'processedAt': FieldValue.serverTimestamp() });
    return PurchaseResult.success;
  });
}
```
Full detail (idempotency mechanism, offline behavior, `onAnimationComplete` interface, Security Rule): see **ADR-0011: Shop Purchase Pipeline & Idempotency Fix**.

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Items per tab (visible without scroll) | 6 | 4–12 | Catalog cảm thấy overwhelming | <4 → shop trống rỗng | Grid 2×3 tối ưu cho mobile |
| Confirm dialog timeout | None (manual) | — | — | — | Không auto-confirm — bé phải chủ động tap |
| Paid Chest position in catalog | Top of "Tất cả" + tab riêng | — | — | — | Always prominent; không ẩn sâu trong list |
| "Còn thiếu X xu" progress bar | Always shown when not affordable | — | — | — | Core motivational mechanic — không tắt |
| Double-tap guard cooldown | Until write resolves | 0.5–3s | Bé không thể retry nhanh nếu lỗi | <0.5s → double-tap still possible | Reset to enabled after success/fail |

## Visual/Audio Requirements

**Item Card (in catalog):**
- Thumbnail: 64×64px item sprite + item name label + price badge (Honey Gold coin icon + number)
- "Đã có ✓" state: green checkmark overlay, desaturated card background
- "Còn thiếu" state: grey Mua button, progress bar below card (Mint Breeze fill on Cloud White bg)
- Card border: rounded 12px, subtle drop shadow

**Purchase Animation (after Confirm):**
- Xu coins (3–5 pieces) fly from wallet icon to item card, duration 0.5s
- Item card scales 1.0 → 1.1 → 1.0 (pop), duration 0.3s
- "Mua thành công!" green toast appears, auto-dismiss 2s

**"Equip now?" Prompt:**
- Bottom sheet (half-screen) with item preview (128×128) + "Mặc ngay" / "Để sau" buttons
- Art style consistent with Art Bible: pastel, rounded, soft shadow

**Sound:**
- Tap item card: soft "click" SFX (hover feedback)
- Purchase confirm: coin chime (same as Currency earn animation but reversed direction)
- "Đã có ✓": no sound — silent to avoid negative feedback

📌 **Asset Spec** — Run `/asset-spec system:shop-system` after art bible approved.

## UI Requirements

Shop System owns the **Shop Screen** — 5-tab layout (Tất cả / Trang phục / Trang trí / Đặc biệt / 🎲 Rương) with scrollable item grid per tab.

Key UI components:
1. **Xu balance header** — always visible at top, live from `xuBalanceProvider`
2. **Item grid** — 2-column, scrollable, item cards with price + ownership state
3. **Item detail sheet** — tap card → bottom sheet with larger preview, description, Mua/Đã có CTA
4. **Confirm dialog** — "Mua [item name] với [N] xu?" → Confirm / Cancel
5. **Progress bar** — "Còn thiếu N xu" when not affordable, below item name in card

📌 **UX Flag — Shop System**: Shop Screen (5 tabs + item grid + purchase flow) cần `/ux-design` spec cho Shop & Reward UI (#20) trước khi viết epics — affordability progress bar và confirm flow are critical conversion moments.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory.

**AC-1 — Affordable item state** `[LOGIC]` BLOCKING
**GIVEN** bé có 50 xu và item giá 30 xu,
**WHEN** bé vào Shop,
**THEN** item hiển thị "Mua" button active — không disabled, không "Còn thiếu" bar.

**AC-2 — Unaffordable item state** `[LOGIC]` BLOCKING
**GIVEN** bé có 25 xu và item giá 30 xu,
**WHEN** bé vào Shop,
**THEN** item hiển thị "Còn thiếu 5 xu" progress bar (83.3% filled), Mua button disabled.

**AC-3 — Atomic purchase write** `[INTEGRATION]` BLOCKING
**GIVEN** bé tap Mua và Confirm trên item 30 xu,
**WHEN** batch write commits,
**THEN** `xuBalance -= 30` (atomic), `inventory/{itemId}` created, purchase animation plays — tất cả trong <1s.

**AC-4 — Already-owned display** `[LOGIC]` BLOCKING
**GIVEN** item đã có trong inventory,
**WHEN** bé vào Shop,
**THEN** item hiển thị "Đã có ✓" badge, Mua button disabled — item vẫn visible trong catalog.

**AC-5 — Paid Chest atomic purchase + animation handoff** `[INTEGRATION]` BLOCKING
**GIVEN** bé có 50 xu và tap mua Paid Chest,
**WHEN** batch write commits,
**THEN** `xuBalance -= 50`, `chestCount += 1`, purchase animation plays (toast suppressed), `onAnimationComplete` fires, navigate đến Chest Open screen — khớp #20's Formula 1 timing contract.

**AC-6 — Gacha-only items filtered out** `[LOGIC]` BLOCKING
**GIVEN** item với `source: 'gacha'` tồn tại trong catalog,
**WHEN** Shop renders,
**THEN** item không xuất hiện trong bất kỳ tab nào — filtered out hoàn toàn.

**AC-7 — Double-tap guard** `[LOGIC]` BLOCKING
**GIVEN** bé tap Confirm 2 lần trong <200ms,
**WHEN** cả 2 taps register,
**THEN** chỉ 1 batch write xảy ra — `xuBalance` chỉ bị trừ 1 lần, inventory chỉ thêm 1 entry.

**AC-8 — Write failure rollback** `[INTEGRATION]` BLOCKING
**GIVEN** batch write fails (network error),
**WHEN** write returns error,
**THEN** `xuBalance` và `inventory` không thay đổi, error toast hiển thị "Mua không thành công, thử lại", Mua button re-enabled.

**AC-9 — Duplicate-purchase-of-same-item race** `[INTEGRATION]` BLOCKING
**GIVEN** 2 purchase request cho CÙNG 1 item commit gần như đồng thời (2 devices hoặc retry),
**WHEN** cả 2 transaction đều cố gắng thực thi,
**THEN** `inventory/{itemId}` chỉ có đúng 1 entry, VÀ `xuBalance` chỉ bị trừ ĐÚNG 1 LẦN — không phải 2 lần. Mechanism: `runTransaction` đọc `inventory/{itemId}` trước khi ghi (ADR-0011 Decision §1), không phải khuyến nghị nữa — bắt buộc.

**AC-10 — Duplicate-purchase-of-Paid-Chest race** `[INTEGRATION]` BLOCKING (thêm 2026-07-11, ADR-0011)
**GIVEN** 2 purchase request cho Paid Chest CÙNG `purchaseId` commit gần như đồng thời (retry với token cũ),
**WHEN** cả 2 transaction đều cố gắng thực thi,
**THEN** `xuBalance` chỉ bị trừ 50 xu ĐÚNG 1 LẦN, `chestCount` chỉ tăng ĐÚNG 1 LẦN — lần thứ 2 trả `PurchaseResult.alreadyProcessed`. NGƯỢC LẠI, 2 lần mua Paid Chest với `purchaseId` KHÁC nhau (2 rương thật sự riêng biệt) PHẢI cả 2 đều thành công — `chestCount` tăng 2, `xuBalance` trừ 100.

## Open Questions

- **Sort options**: Có nên cho bé sort catalog theo giá (thấp → cao) hoặc "Sắp mua được" (closest to affordable)? UX nice-to-have. Defer đến playtest.
- **New item indicator**: Khi admin thêm item mới vào Firestore, có nên hiển thị "Mới!" badge trên item card không? Cần timestamp tracking. Defer đến Alpha.
- **Wishlist**: Bé có thể "bookmark" items chưa đủ xu không? Creates goals. Adds `wishlist` subcollection. Defer đến Alpha.
- ~~**Race condition guard**: Edge case khi `xuBalance` giảm đột ngột ngay khi bé đang confirm purchase — cần Security Rule hoặc Cloud Function guard. Defer implementation đến Architecture phase.~~ **RESOLVED 2026-07-11 (ADR-0011)**: `runTransaction`'s server-side balance re-check đóng gap này — xem Edge Cases.
- **Paid Chest always available**: Ngay cả khi bé không đủ 50 xu, Paid Chest entry vẫn hiển thị (với "Còn thiếu" bar). Design intent: yes — chest luôn visible như aspirational item.
