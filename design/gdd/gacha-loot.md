# Gacha / Loot System

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật (gacha rewards are earned through discipline, not purchased)

## Overview

Gacha / Loot System quản lý **Rương May Mắn** (Lucky Chest) — cơ chế phần thưởng bí ẩn tạo ra yếu tố bất ngờ và dopamine spike trong PetQuest. System này là một **probability engine** phía sau và một **chest-opening ceremony** phía trước.

Bé nhận Rương theo 2 con đường: (1) **miễn phí** — tự động nhận sau mỗi N tasks được approve (milestone reward, không tốn xu); (2) **mua bằng xu** — trong Shop với giá cố định (xu sink có chủ ý).

Khi mở Rương, system roll ngẫu nhiên từ loot pool gồm các items có `source: 'gacha'` hoặc `'both'` trong Item Database. Kết quả là một **item** (thêm vào inventory) hoặc một **xu bonus** (credited vào balance). Không có rarity tiers trong MVP — differentiation hoàn toàn qua `source` field và price range của items.

Kiến trúc: loot table logic chạy client-side trong MVP (đơn giản hóa) — không cần Cloud Function. Item catalog đã cached trong `itemCatalogProvider`; gacha chỉ filter và random-pick từ đó.

## Player Fantasy

Bé nhìn vào Rương May Mắn trong túi đồ — hộp nhỏ bóng lên, lung linh. *"Không biết trong đó có gì?"*

Khoảnh khắc tap mở Rương là một trong những khoảnh khắc đáng nhớ nhất trong PetQuest. Không phải vì phần thưởng quá lớn — mà vì **sự không biết**. Bé vừa làm 5 nhiệm vụ, xứng đáng được một điều bí ẩn. Rương xoay, rung nhẹ, rồi bật ra: một chiếc áo phù thủy hiếm không có trong Shop thường, hoặc 15 xu bổ sung vào ví.

Khác với Shop (nơi bé biết chính xác mình mua gì), Gacha tạo ra **câu chuyện ngẫu nhiên**: *"Tớ được áo rồng đó vì tớ đã làm bài tập 5 ngày liên tiếp!"* — một câu chuyện bé sẽ kể với bạn bè trong khu xóm ảo.

Gacha không thay thế Shop — nó là **phần thưởng của sự kiên trì**, một lớp delight nằm trên vòng lặp chính. Bé không chơi PetQuest để mở rương; bé mở rương vì đã chơi PetQuest chăm chỉ.

## Detailed Design

### Core Rules

**1. Chest Acquisition**

| Type | How to get | Cost | Frequency |
|------|-----------|------|-----------|
| **Free chest** | Tự động sau mỗi 5 tasks được approve | 0 xu | ~1 lần/tuần (pace bình thường) |
| **Paid chest** | Mua trong Shop | 50 xu | Tùy bé |

Free chest counter: `approvedTaskCount` mod 5 = 0 → grant chest. Counter tracked in `children/{childId}.approvedTaskCount: int` (new field, owned by Gacha System).

**2. Chest Inventory**

Bé có thể tích lũy nhiều chests trước khi mở. Lưu trong `children/{childId}.chestCount: int`. Không có max limit — bé chọn khi nào mở.

**3. Loot Table — Roll Logic**

Khi bé mở 1 chest:

```
Step 1: Roll result type
  70% → Item reward
  30% → Xu bonus reward

Step 2a (if Item): 
  Filter itemCatalogProvider for source IN ['gacha', 'both']
  Random pick 1 item (uniform distribution, no weights in MVP)
  
  If item already in inventory:
    Re-roll once. If still owned → give xu consolation (10 xu)

Step 2b (if Xu bonus):
  Roll xuBonus from [5, 10, 15, 20] xu (uniform, each 25%)
```

**4. Chest Open Results**

**Sửa lỗi so với bản trước**: Bảng dưới đây đã được tính lại cho ĐÚNG với Formula 3's re-roll rule (Step 2a ở trên cho phép re-roll 1 lần nếu duplicate) — bản trước dùng single-roll approximation (0.70×0.9 và 0.70×0.1) mà bỏ qua re-roll, sai lệch đáng kể (đặc biệt consolation rate sai gần 10 lần).

Với `p` = xác suất 1 lần roll ngẫu nhiên trúng item đã sở hữu (giả định minh hoạ p=10%, xem Formula 3):
- New item = `0.70 × (1 - p²)` = `0.70 × (1 - 0.01)` = **69.3%** (thành công ở lần roll đầu HOẶC lần re-roll)
- Consolation (cả 2 lần đều duplicate) = `0.70 × p²` = `0.70 × 0.01` = **0.7%**

| Result | Probability (tại p=10% minh hoạ) | Details |
|--------|------------|---------|
| New item (gacha/both source) | **69.3%** | Item added to inventory — thành công ở roll đầu hoặc re-roll |
| Duplicate item → xu consolation | **0.7%** | 10 xu (cả 2 lần roll đều duplicate — hiếm, vì cần trúng "đã sở hữu" 2 lần liên tiếp) |
| Xu bonus 5 xu | 7.5% | Direct xu credit |
| Xu bonus 10 xu | 7.5% | Direct xu credit |
| Xu bonus 15 xu | 7.5% | Direct xu credit |
| Xu bonus 20 xu | 7.5% | Direct xu credit |

**Lưu ý quan trọng**: `p` (tỷ lệ pool đã sở hữu) tăng dần theo thời gian khi bé sưu tập nhiều hơn — bảng trên chỉ là minh hoạ tại p=10%, không phải hằng số cố định. Khi `p` tăng (ví dụ bé sở hữu 50% pool), New item giảm còn `0.70×0.75=52.5%`, Consolation tăng lên `0.70×0.25=17.5%`. Formula 3 (bên dưới) là nguồn sự thật toán học; bảng này chỉ minh hoạ 1 điểm dữ liệu.

**5. Result Application**

- **Item result**: add to `inventory/{itemId}` + show item reveal animation
- **Xu bonus**: `FieldValue.increment(+xuBonus)` on `xuBalance` — same atomic pattern as Currency GDD
- **`chestCount` decrement PHẢI dùng `FieldValue.increment(-1)`** trong `WriteBatch`, KHÔNG phải read-modify-write (đọc giá trị hiện tại rồi set giá trị mới) — sửa lỗi so với bản trước chỉ ghi "chestCount -= 1" bằng prose, không rõ cơ chế. Lý do bắt buộc: Parent Approval (#11) có thể tăng `chestCount` cùng lúc (level-up hoặc milestone, bên trong `runTransaction`) trong khi bé đang mở chest ở client khác/cùng lúc — `WriteBatch` không có bước đọc nên read-modify-write không an toàn (lost update), chỉ `FieldValue.increment(-1)` mới atomic đúng cách trên field dùng chung này.

**6. Pity System (MVP)**

Không có pity system trong MVP. Nếu playtest shows frustration với duplicate rate → add pity counter in Alpha (guaranteed new item after N duplicates).

---

### States and Transitions

```
[Chest acquired (free or purchased)]
        │
        ▼
chestCount += 1
        │
[Bé tap "Mở Rương"]
        │
        ▼
Roll result type (70% item / 30% xu)
        │
        ├── Item → check inventory → new? add item : consolation xu
        └── Xu  → roll amount [5/10/15/20] → increment balance
        │
        ▼
chestCount -= 1
Result displayed (reveal animation)
```

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Item Database (#3) | → Gacha | Loot pool (items với `source: 'gacha'\|'both'`) | `itemCatalogProvider` filtered |
| Currency System (#7) | ← Gacha | `xuBonus` increment | `FieldValue.increment(+xuBonus)` on `xuBalance` |
| Data Persistence (#4) | ↔ | `chestCount`, `approvedTaskCount` fields | batch write on open + acquire |
| Parent Approval (#11) | → Gacha | `approvedTaskCount += 1` per approve | triggers free chest grant at milestones |
| Parent Approval (#11) | → Gacha | `chestCount` CŨNG được tăng độc lập bởi pet level-up (không chỉ milestone) — registry: `chest_delta` formula (`= [leveledUp] + [hitChestMilestone]`, owned by #11) có thể cộng 2 trong cùng 1 approve transaction | xem #11's Core Rules + `chest_delta` trong `entities.yaml` |
| Shop System (#13) / Shop & Reward UI (#20) | → Gacha | `inventoryProvider` (owned by #13) — cần đọc để check duplicate ở Step 2a/Formula 3 | `StreamProvider<Set<String>>`, xem #13's Dependencies |
| Shop System (#13) | → Gacha | paid chest purchase → `chestCount += 1` | xu deduct + chest grant batch |
| Shop & Reward UI (#20) | ← Gacha | chest open animation + result display | chest reveal ceremony |

## Formulas

**Formula 1 — Free Chest Grant:**

```
grantFreeChest = (approvedTaskCount % freeChestMilestone == 0) AND (approvedTaskCount > 0)
```

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Approved task count | `approvedTaskCount` | int | 0–∞ | Tổng tasks đã được approve (lifetime, không reset) |
| Free chest milestone | `freeChestMilestone` | int | 5 (default) | Số tasks cần để nhận 1 free chest |
| Grant chest? | `grantFreeChest` | bool | true/false | True khi đạt milestone |

**Output:** Mỗi 5 approvals → 1 free chest. Tại `approvedTaskCount` = 5, 10, 15, 20… `chestCount += 1`.

**Example:** approvedTaskCount = 14 → approve task → count = 15 → 15 % 5 = 0 → grant chest ✅

---

**Formula 2 — Loot Roll:**

```
resultType = random(0, 1) < itemProbability ? 'item' : 'xu'
```

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Item probability | `itemProbability` | float | 0.70 | Xác suất roll item (vs xu) |
| Gacha pool size | `poolSize` | int | ≥1 | Số items với `source: 'gacha'\|'both'` in catalog |
| Xu bonus options | `xuOptions` | int[] | [5, 10, 15, 20] | Possible xu amounts |

**Output Range:** Item (70%) hoặc xu 5–20 (30% tổng, phân bổ đều 7.5% mỗi tier).

**Example:** random() = 0.45 → 0.45 < 0.70 → item roll → pick random from gacha pool.

**Testability note**: `random()` PHẢI injectable (dependency injection, không phải singleton/global RNG trực tiếp gọi trong hàm) — cần thiết để `[LOGIC]`-tier test dưới đây verify được chính xác 70/30 split và re-roll behavior với seed cố định, theo `coding-standards.md`'s rule "no random seeds trong test" (nghĩa là code test không dùng random thật — phải mock/inject RNG trả về giá trị xác định).

---

**Formula 3 — Duplicate Resolution:**

```
if (rolledItem in inventory):
  reRoll once
  if (reRolledItem in inventory): xuConsolation = 10
  else: grantItem = reRolledItem
```

| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Consolation xu | `xuConsolation` | int | 10 | Xu khi cả 2 lần roll đều ra item đã có |

**Output:** Tối đa 2 rolls per chest open. Luôn có kết quả — không bao giờ kết thúc mà không trao gì.

## Edge Cases

- **Nếu gacha item pool rỗng** (không có item nào với `source: 'gacha'|'both'` trong catalog): Roll type forced sang xu bonus — không crash. Log warning. Catalog seed script phải đảm bảo ít nhất 1 gacha item tồn tại trước launch.

- **Nếu bé own toàn bộ gacha pool** (đã sưu tập hết): Cả 2 lần roll đều là duplicate → xuConsolation = 10 xu mỗi chest. Bé vẫn có lý do mở rương (xu bonus) nhưng cảm giác diminished. Log khi `ownedGachaItems / poolSize > 0.8` để cảnh báo content team cần thêm items.

- **Nếu `approvedTaskCount` overflow**: int 64-bit trong Firestore — tại 5 tasks/ngày × 365 ngày = 1,825 tasks/năm, không cần guard trong MVP.

- **Nếu bé mua paid chest nhưng `xuBalance < 50`**: Shop System check affordability trước khi process — chest không được grant nếu không đủ xu. Gacha không nhận `chestCount += 1` nếu purchase bị block.

- **Nếu `chestCount` = 0 và bé cố mở**: UI disabled "Mở Rương" button khi `chestCount = 0`. Không có way to trigger roll with 0 chests.

- **Nếu loot roll xảy ra khi `itemCatalogProvider` chưa load**: Block chest open UI cho đến khi catalog loaded — show loading state. Không roll against empty pool.

- **Nếu item được roll là `category: 'special'`** (inventory-only trophy): Add to inventory bình thường — special items có thể trong gacha pool. `slot: null` — không equip, chỉ collect. Valid gacha outcome.

- **Nếu bé offline khi mở chest**: Client-side roll vẫn xảy ra (không cần server round-trip trong MVP). Batch write (chestCount--, inventory add / xuBalance++) vào Firestore local cache → sync khi online. Kết quả consistent vì roll đã xong trước write.

- **Nếu bé tap "Mở Rương" 2 lần nhanh** (double-tap, trước khi lần đầu resolve): Button disabled NGAY sau tap đầu tiên — cùng pattern với Parent Approval (#11)'s Approve/Reject buttons và Shop System (#13)'s Confirm button. Chỉ 1 batch write xảy ra, `chestCount` chỉ giảm đúng 1 lần dù bé tap nhiều lần. Re-enable sau khi write resolve hoặc fail.

## Dependencies

**Upstream (Gacha cần):**
- **Item Database (#3)** ✅ — loot pool (items với `source: 'gacha'|'both'`), `itemCatalogProvider`
- **Currency System (#7)** ✅ — `xuBalance` increment pattern (`FieldValue.increment`)
- **Data Persistence (#4)** ✅ — `chestCount`, `approvedTaskCount` fields in schema
- **Shop System (#13)** — `inventoryProvider: StreamProvider<Set<String>>` — cần thiết cho duplicate-check ở Formula 3/Step 2a (dependency bị bỏ sót ở bản trước — Gacha KHÔNG tự query Firestore riêng cho ownership check, tái sử dụng provider đã cached của #13 để tránh 2 read path khác nhau cho cùng 1 dữ liệu)

**Downstream (phụ thuộc vào Gacha):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Shop System (#13) | Paid chest purchase → `chestCount += 1` | xu deduct + chest grant batch |
| Parent Approval (#11) | `approvedTaskCount += 1` per approve → free chest milestone | batch write on approve |
| Shop & Reward UI (#20) | `chestCount` display + chest open ceremony | `chestCountProvider` Riverpod |

**Fields owned:** *(Note: must be added to Data Persistence GDD schema)*
```
children/{childId}.chestCount: int          // số chests chưa mở
children/{childId}.approvedTaskCount: int   // lifetime approved task count (free chest milestone tracker)
```

**Riverpod provider owned:**
```dart
final chestCountProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc('families/$parentId/children/$childId')
    .snapshots()
    .map((doc) => (doc.data()?['chestCount'] as int?) ?? 0);
});

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| `freeChestMilestone` | 5 tasks | 3–10 | Chest quá hiếm → bé quên gacha exists | <3 → chest quá thường, mất giá trị | Gating knob quan trọng nhất |
| `paidChestPrice` | 50 xu | 30–100 | Không ai mua | Quá rẻ → cannibalizes shop spending | Phải cảm thấy như "trade-off có ý nghĩa" |
| `itemProbability` | 0.70 | 0.50–0.85 | Item pool depletes nhanh → duplicate frustration | <0.50 → cảm giác chest chỉ cho xu, không exciting | 70% item / 30% xu là sweet spot |
| `xuOptions` | [5, 10, 15, 20] | min 5, max 30 | Max xu > 20 → gacha beats shop in xu/action ratio | Max <5 → xu reward cảm thấy insignificant | Tổng kỳ vọng xu = 12.5 (average of 4 options) |
| `xuConsolation` | 10 xu | 5–20 | Consolation > average shop item → farming incentive | <5 → duplicate cảm thấy punishing | Phải nhỏ hơn paid chest value |
| Max `chestCount` | unlimited | — | Bé tích trữ 50 chests → mở hết cùng lúc gây chaos | — | Cân nhắc soft cap ở Alpha nếu cần |

## Visual/Audio Requirements

**Chest Idle (in inventory):**
- Sprite: hộp gỗ nhỏ (~64×64px), có khóa vàng, glow nhẹ pulsing mỗi 2s
- Màu: Honey Gold #FFD060 (Art Bible Section 4 canonical hex) viền, thân màu Peach Glow ấm
- "Muốn được mở" test: chest phải trông enticing khi ở kích thước 48×48 trong UI badge

**Chest Open Ceremony (khi bé tap Mở):**
- Phase 1 (0–0.3s): Chest shake nhẹ 3 lần (anticipation)
- Phase 2 (0.3–0.8s): Chest scale up ×1.2, glow tăng mạnh, sparkle particles xung quanh
- Phase 3 (0.8–1.5s): Lid bật lên, item sprite hoặc xu coins bay ra từ chest
- Phase 4 (1.5–2.5s): Item/xu lands, reveal label hiện với bounce-in animation
- Total duration: ~2.5s — đủ dramatic mà không gây impatient

**Item Reveal:**
- Item sprite full size (128×128) với spotlight background (white radial gradient)
- Item name + "Thêm vào tủ đồ!" label bên dưới
- Confetti particles 12–16 pieces màu pastel burst

**Xu Bonus Reveal:**
- Coin stack animation, số xu đếm lên (0 → N trong 0.8s)
- Màu Honey Gold, font bold

**Duplicate / Consolation Reveal:**
- Subtle — không sad, nhưng không grandiose
- "Hạt giống đổi thành xu 🪙" message thay vì "Trùng lặp!"
- 10 xu đếm lên, tone bình thường

**Sound:**
- Chest shake: soft rattle SFX
- Lid open: pop + chime ascending
- Item reveal: fanfare short (2–3 notes)
- Xu reveal: coin clink × count
- Volume: 70% master SFX

📌 **Asset Spec** — Run `/asset-spec system:gacha-loot` after art bible approved.

## UI Requirements

Gacha contributes to 2 UI surfaces:

1. **Chest Badge** (trong main nav hoặc Shop tab): `chestCount` với chest icon. Tap → navigate đến chest open screen. Pulse animation khi `chestCount > 0`.

2. **Chest Open Screen** (full-screen modal, trong Shop & Reward UI #20): chest idle animation → tap to open → ceremony plays → result displayed với "Equip now" / "OK" CTA. **Làm rõ ownership**: "Equip now?" prompt là UI CỦA Shop System (#13) tái sử dụng nguyên bản (xem #20's Core Rule 5), KHÔNG phải thiết kế riêng của GDD này — Gacha chỉ trigger hiển thị nó khi kết quả là item mới.

📌 **UX Flag — Gacha/Loot**: Chest open ceremony và result reveal screen cần `/ux-design` spec cho Shop & Reward UI (#20) trước khi viết epics — animation timing và CTA placement critical for delight moment.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory. Hệ thống này có economic risk cao (flagged High-Risk trong `systems-index.md`) — mọi formula-driven criterion PHẢI BLOCKING.

**AC-1 — Free chest milestone grant** `[LOGIC]` BLOCKING
**GIVEN** bé có `approvedTaskCount = 4` và bố mẹ approve 1 task,
**WHEN** approve batch commits,
**THEN** `approvedTaskCount = 5`, `chestCount += 1` — free chest granted automatically.

**AC-2 — Milestone repeats** `[LOGIC]` BLOCKING
**GIVEN** bé có `approvedTaskCount = 10` (milestone 2),
**WHEN** approve fires,
**THEN** `chestCount` tăng lại — milestone repeats every 5, không chỉ 1 lần.

**AC-3 — Paid chest atomic purchase** `[INTEGRATION]` BLOCKING
**GIVEN** bé có 50 xu và paid chest giá 50 xu,
**WHEN** bé mua chest trong Shop,
**THEN** `xuBalance = 0`, `chestCount += 1` — atomic batch, không thể có xu deduct mà không có chest grant.

**AC-4 — Chest open decrement + single result** `[LOGIC]` BLOCKING
**GIVEN** `chestCount > 0` và bé tap "Mở Rương",
**WHEN** loot roll runs,
**THEN** `chestCount -= 1` (verify via `FieldValue.increment(-1)`, không phải absolute set) và kết quả là item (chưa có trong inventory) HOẶC xu bonus [5/10/15/20] HOẶC consolation 10 xu — luôn có đúng 1 kết quả.

**AC-5 — Duplicate re-roll** `[LOGIC]` BLOCKING
**GIVEN** item được roll đã có trong inventory,
**WHEN** duplicate detected,
**THEN** re-roll once; nếu re-roll cũng duplicate → 10 xu consolation credited, không crash.

**AC-6 — Statistical roll distribution (mock RNG, seed cố định)** `[LOGIC]` BLOCKING
**GIVEN** RNG được inject với 10,000 giá trị uniform giả lập (deterministic, không dùng random thật),
**WHEN** chạy loot roll 10,000 lần với `p` (pool-owned proportion) cố định giả lập = 10%,
**THEN** phân bổ kết quả thực tế khớp Formula 2/3's tính toán trong sai số thống kê hợp lý (~69.3% new item, ~0.7% consolation, 30% xu bonus tổng — xem Core Rule 4's bảng đã sửa) — đây là test trực tiếp bắt được lỗi loại "table không khớp formula" đã tìm thấy ở lần review đầu tiên.

**AC-7 — Empty pool fallback** `[LOGIC]` BLOCKING
**GIVEN** gacha item pool rỗng (0 items với `source: 'gacha'|'both'`),
**WHEN** item roll attempted,
**THEN** result forced sang xu bonus — không crash, warning logged.

**AC-8 — Catalog-not-loaded guard** `[INTEGRATION]` BLOCKING
**GIVEN** `itemCatalogProvider` chưa load,
**WHEN** bé tap "Mở Rương",
**THEN** button disabled/loading state — không trigger roll trước khi catalog ready.

**AC-9 — Offline sync correctness** `[INTEGRATION]` BLOCKING
**GIVEN** bé offline khi mở chest,
**WHEN** app regains connection,
**THEN** batch write syncs — `chestCount` decremented và item/xu credited đúng, không duplicate grant.

**AC-10 — Double-tap guard** `[LOGIC]` BLOCKING
**GIVEN** bé tap "Mở Rương" 2 lần trong <200ms,
**WHEN** cả 2 tap register,
**THEN** chỉ 1 batch write xảy ra — `chestCount` chỉ giảm đúng 1 lần, không mở 2 chest cho 1 lần double-tap.

## Open Questions

- **Client-side roll security**: MVP dùng client-side random — không thể cheat vì inventory write phải qua Firestore Security Rules (bé chỉ write inventory của mình). Nhưng determined attacker có thể manipulate client. Acceptable risk cho children's game MVP — Cloud Function roll in Alpha nếu cần.
- **Pity system**: Sau bao nhiêu consecutive xu results (không có item) thì guaranteed item? Defer đến playtest — cần data trước khi set threshold.
- **Gacha history log**: Có nên lưu lịch sử mở rương không? (bé và bố mẹ xem lại) Adds Firestore subcollection. Defer đến Alpha.
- **Chest visual differentiation**: Free chest vs paid chest — cùng 1 sprite hay khác nhau? Paid chest có thể có gold trim để cảm thấy premium hơn. Defer đến art production.
- **`approvedTaskCount` reset**: Có reset về 0 sau mỗi milestone không, hay cộng dồn mãi? Hiện tại: cộng dồn (mod 5 check). Nếu reset: cần guard tránh double-grant tại boundary.
