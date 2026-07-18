# Currency System

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-06-28
> **Implements Pillar**: Pillar 1 — Kỷ Luật Thật → Phần Thưởng Thật (xu only comes from real effort, never shortcuts)

## Overview

Currency System quản lý **xu** — đơn vị tiền tệ duy nhất của PetQuest. Xu được kiếm thông qua task approval (bố mẹ approve → xu cộng vào balance) và tiêu trong Shop để mua items cho Mochi. Không có cách kiếm xu nào khác: không có daily login bonus, không có in-app purchase, không có quảng cáo đổi xu.

Xu được lưu tại `children/{childId}.xuBalance` trong Firestore. Mọi thay đổi balance đều là atomic batch write (từ Data Persistence GDD) — không bao giờ có trạng thái "xu bị trừ nhưng item chưa nhận được".

**Tại sao chỉ một currency**: Hai currency (xu + premium coin) tạo ra pay-to-win path vi phạm Pillar 1. Một currency đơn giản = bé hiểu rõ giá trị công sức của mình.

## Player Fantasy

Bé nhìn vào con số xu góc màn hình và cảm thấy **tự hào về công sức của mình**. Mỗi xu là bằng chứng của một việc tốt đã làm — làm bài toán xong, quét nhà xong, luyện đàn xong. Khi số xu tăng lên, bé không nghĩ "tôi có tiền" mà nghĩ "tôi đã nỗ lực được nhiều thế này".

Khoảnh khắc tiêu xu mua được chiếc mũ phù thủy cho Mochi — đó là khoảnh khắc effort được chuyển hóa thành niềm vui hữu hình. Bé sẽ nhớ: "Cái mũ này tôi quét nhà 3 ngày mới mua được."

## Detailed Design

### Core Rules

**1. Earn Rules — chỉ từ task approval**
- Mỗi task có `xuReward` cố định (defined trong Task Library GDD #8)
- Xu được cộng khi bố mẹ approve — không phải khi bé submit
- Xu không có expiry — balance tích lũy vô thời hạn

**2. Spend Rules — chỉ trong Shop**
- Mua item: `xuBalance -= item.price` (atomic batch với inventory add)
- Không thể tiêu âm: nếu `xuBalance < item.price` → purchase blocked
- Không có refund — mua xong không hoàn lại

**3. Balance Integrity**
- Tất cả thay đổi balance dùng `FieldValue.increment()` — không set absolute value
- Prevents race condition khi 2 approvals xảy ra gần nhau
- Balance không bao giờ < 0 (enforced bởi Shop System trước khi deduct)

**4. Sources & Sinks**

| Source | Amount | Trigger |
|--------|--------|---------|
| Task approved | `task.xuReward` (10–20 xu) | Bố mẹ tap Approve |
| Gacha chest reward | `chest.xuBonus` (5–20 xu, uniform [5,10,15,20]) HOẶC `xuConsolation` (10 xu cố định, khi duplicate 2 lần liên tiếp) | Random, khi mở rương — 0 xu KHÔNG BAO GIỜ là kết quả có thể, đã sửa từ "0–20" (stale, không khớp #12's Formula 2/3) |

| Sink | Amount | Trigger |
|------|--------|---------|
| Buy shop item | `item.price` (10–200 xu) | Bé tap Mua |
| Buy Paid Chest | 50 xu (registry: `gacha_paid_chest_price`) | Bé tap mua Rương May Mắn trong Shop (thêm 2026-07-06, review-all-gdds W5 — sink này đã implement thật ở `shop-system.md`/`gacha-loot.md` nhưng chưa xuất hiện ở bảng ledger cấp cao này) |

---

### States and Transitions

```
[xuBalance: int]
    │
    ├── +xuReward  (task approved)    → FieldValue.increment(+N)
    ├── +xuBonus   (gacha chest)      → FieldValue.increment(+N)
    └── -item.price (shop purchase)  → FieldValue.increment(-N)
                                        (only if balance >= price)
```

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Data Persistence (#4) | ↔ | `xuBalance` field | `FieldValue.increment()` in batch write |
| Parent Approval (#11) | → Currency | `task.xuReward` | triggers increment on approve |
| Gacha/Loot (#12) | → Currency | `chest.xuBonus` | triggers increment on chest open |
| Shop System (#13) | ← Currency | `xuBalance` read + decrement | affordability check + purchase batch |
| Main Nav Shell (#17) | ← Currency | `xuBalance` display | `xuBalanceProvider` Riverpod |

## Formulas

**Balance after earn:**
```
xuBalance_new = xuBalance + xuReward
```
**Balance after spend:**
```
xuBalance_new = xuBalance - item.price   (only if xuBalance >= item.price)
```
Both implemented as `FieldValue.increment(±N)` — atomic, no absolute set.

**xuReward per task category (locked — Task Library GDD #8 owns final values, đã Approved, giá trị dưới đây khớp registry):**

**Sửa 2026-07-06 (review-all-gdds fix — dominant strategy + propagate #8's economy-designer redesign)**: `study`/`arts` tăng 20→25 xu (đổi lại giảm energy 30→20, xem #8), `helping` xu không đổi (10) nhưng energy tăng 20→30. Rationale column viết lại — không còn "highest reward" tuyệt đối, mà là trade-off có chủ đích (xu cao đánh đổi energy thấp).

| Category | xuReward | Rationale |
|----------|---------|-----------|
| Học bài / làm bài tập | 25 | Cao nhất về xu — đổi lại energyReward thấp nhất (20, xem #8) |
| Làm việc nhà | 15 | Mid tier cả 2 trục — daily contribution |
| Luyện tập thể thao | 15 | Mid tier cả 2 trục — physical health |
| Luyện nhạc / nghệ thuật | 25 | Cao nhất về xu — đổi lại energyReward thấp nhất (20, xem #8) |
| Giúp đỡ bố mẹ (khác) | 10 | Thấp nhất về xu — đổi lại energyReward CAO NHẤT (30, xem #8) — không còn "flexible/thấp mọi mặt" |

## Edge Cases

- **Nếu bé cố mua item khi không đủ xu**: Shop System check `xuBalance >= item.price` trước khi show "Mua" button — button disabled nếu không đủ. Không bao giờ deduct nếu không đủ.
- **Nếu hai approvals arrive cùng lúc** (Firestore offline sync): `FieldValue.increment()` là server-side atomic — cả hai increment đều được apply đúng, không có lost update.
- **Nếu xuBalance âm** (bug hoặc Firestore rule bypass): Display 0, không cho mua gì. Log error. Không crash.
- **Nếu `xuReward` = 0**: Task vẫn được approve (energy vẫn cộng), chỉ không có xu. Valid cho tasks "bonus" không có monetary reward.

## Dependencies

**Upstream:**
- **Auth & Account (#1)** ✅: `childId` để scope balance
- **Data Persistence (#4)** ✅: `xuBalance` field, `FieldValue.increment()` pattern

**Downstream:**
- **Shop System (#13)**: đọc balance để check affordability của items VÀ paid chests (sửa lỗi so với bản trước ghi nhầm #12 — Gacha/Loot không sở hữu affordability check, đó là Shop System's trách nhiệm; #12 chỉ nhận `chestCount += 1` sau khi #13 đã confirm đủ xu và trừ tiền) + decrement khi purchase
- **Main Nav Shell (#17)**: hiển thị balance real-time
- **Shop & Reward UI (#20)**: đọc `xuBalanceProvider` trực tiếp cho header display (không chỉ transitively qua #13) — xem #20's Core Rule 1

**Riverpod provider owned:**
```dart
// ADR-0008: dùng .doc(...).snapshots() — KHÔNG .collection(...).snapshots() (cái đó trả
// QuerySnapshot, không có .data() → không compile). Path qua FirestorePaths constant (ADR-0003),
// safe nullable accessor (.value trên riverpod 3.x — sửa 2026-07-13, xem ADR-0002 Correction
// note, trước đó ghi .valueOrNull), (x as num?)?.toInt() (ADR-0006, int/double ambiguity).
final xuBalanceProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (childId == null || parentId == null) return Stream.value(0);
  return FirebaseFirestore.instance
    .doc(FirestorePaths.child(parentId, childId))
    .snapshots()
    .map((doc) => (doc.data()?['xuBalance'] as num?)?.toInt() ?? 0);
});
```
> ⚠️ **Chống double-tap over-spend (ADR-0008)**: affordability check (`xuBalance >= cost`) và decrement batch là read-then-write có khoảng hở. Shop PHẢI có single-flight guard cấp màn hình — disable TẤT CẢ nút "Mua" (không chỉ nút vừa tap) khi có purchase đang bay — nếu không, bé tap 2 card khác nhau trước khi balance stream update → cả 2 check pass với balance cũ, cả 2 trừ tiền, bé nhận cả 2 item + balance âm. Đây là race của client bình thường, không phải modified-client.

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| xuReward per task | 10–20 | 5–50 | Shop items quá rẻ → hết mục tiêu nhanh | Bé mãi không đủ mua → nản | Balance với shop prices |

**Không định nghĩa lại** (thêm 2026-07-06, review-all-gdds W3): "Cheapest/Most expensive shop item" (10 xu / 200 xu) thuộc Item Database (#3)'s `item_price_min`/`item_price_max` (registry-tracked) — GDD này trước đây duplicate 2 giá trị này như tuning knob riêng, không cross-reference. Giá trị vẫn đúng, chỉ sửa ownership documentation.

## Visual/Audio Requirements

- **Wallet display**: số xu + icon xu (Honey Gold coin) ở top bar
- **Earn animation**: xu coins bay từ task card vào wallet (+N xu counter)
- **Spend animation**: xu coins fly ra từ wallet vào item card
- Audio: coin chime khi earn, soft click khi spend

## UI Requirements

- Wallet luôn visible ở Main Navigation Shell — bé luôn biết mình có bao nhiêu xu
- "Còn thiếu X xu" progress bar trong Shop khi không đủ tiền
- Xu display: integer only (không có decimals)

## Acceptance Criteria

**GIVEN** bố mẹ approve task có `xuReward = 20`,
**WHEN** batch write commit,
**THEN** `xuBalance` tăng đúng 20, `xuBalanceProvider` update trong <1s, earn animation play.

**GIVEN** bé có 50 xu và item giá 30 xu,
**WHEN** bé tap Mua,
**THEN** `xuBalance` = 20, item xuất hiện trong inventory, spend animation play.

**GIVEN** bé có 25 xu và item giá 30 xu,
**WHEN** bé vào Shop,
**THEN** Mua button disabled, "Còn thiếu 5 xu" hiển thị — không thể deduct.

**GIVEN** hai approvals arrive cùng lúc (offline sync), mỗi cái +20 xu,
**WHEN** Firestore sync,
**THEN** `xuBalance` tăng đúng 40 — không mất update nào.

**GIVEN** xuBalance = 0 (bất kỳ lý do gì),
**WHEN** UI render,
**THEN** hiển thị 0 (không âm), tất cả shop items disabled.

## Open Questions

- ~~**Xu từ gacha**: Khi mở rương gacha, có thể ra xu bonus (0–20). Tỷ lệ và amount sẽ được lock trong Gacha GDD (#12).**~~ **Resolved (đóng open question stale, tìm thấy khi review #12 ngày 2026-07-06)**: #12 đã lock giá trị từ lâu — xu bonus [5,10,15,20] uniform (30% tổng roll) hoặc 10 xu consolation (duplicate 2 lần). 0 xu không bao giờ là kết quả. Xem `gacha-loot.md`'s Formula 2/3.
- **Xu gifting**: Phase 2 — bé có thể gửi xu nhỏ cho bạn không? Ảnh hưởng đến economy balance — defer đến Phase 2 design.
- **Xu cap**: Có nên cap max xu (ví dụ: 9999) không? Hiện tại không cap — nếu bé tích lũy nhiều thì shop phải có đủ items để tiêu.
