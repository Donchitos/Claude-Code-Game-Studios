# Pet Leveling & Evolution

> **Status**: Approved ✅ — /design-review CONCERNS resolved 2026-07-03 (gacha_ticket → chestCount fix); propagated to #4, #5, #6
> **Author**: User + Agents
> **Last Updated**: 2026-07-03
> **Implements Pillar**: Pillar 2 — Thú Cưng Là Hình Ảnh Của Bé (Mochi grows as bé grows)

## Overview

Pet Leveling & Evolution theo dõi **tổng xu kiếm được** (`totalXuEarned`) của bé — một counter tăng dần mỗi khi task được approve, không bao giờ giảm dù bé tiêu xu. Khi `totalXuEarned` đạt ngưỡng, Mochi lên level và thay đổi hình dạng.

Mochi có **5 level**, chia thành 3 **evolution stage** có visual riêng: Baby (L1), Young (L2–L3), Grown (L4–L5). Mỗi lần level up: animation đặc biệt `LEVELING_UP` play, bé nhận **xu bonus + 1 Rương May Mắn miễn phí** (`chestCount += 1`, dùng chung field với Gacha/Loot System #12). Evolution (thay đổi sprite form) chỉ xảy ra ở L2 và L4.

**Tại sao dùng `totalXuEarned` thay vì tasks count**: Xu đã có weight (task khó = xu nhiều hơn) — không cần thêm XP system riêng. Bé không bị penalize khi tiêu xu.

MVP scope: 5 levels, 3 visual forms, level-up reward (xu + chest), `LEVELING_UP` triggered state.

## Player Fantasy

Bé mở app sau một tuần học bài chăm chỉ. Mochi đang ở góc màn hình — nhỏ nhắn, tròn trĩnh, đôi tai nhỏ xíu của baby form. Nhưng thanh progress bar bên dưới đang rung rinh... gần đầy rồi.

Bé submit task cuối cùng. Bố mẹ approve. Xu cộng vào. Màn hình rung nhẹ — ánh sáng vàng toả ra từ Mochi. Mochi *phát sáng*, lớn dần lên, tai dài ra, đuôi bồng lên. Tiếng nhạc level-up ngân vang. Text bay lên: **"Mochi lớn rồi! Level 2!"**

Và một rương gacha nhỏ rơi xuống: *"Phần thưởng cho bé chăm chỉ."*

**Cảm xúc mục tiêu**: *"Mochi lớn lên cùng mình. Mình đã thực sự nỗ lực."*

Mochi không lớn vì thời gian trôi qua. Mochi lớn vì bé *làm*. Đây là visual proof của tháng trời nỗ lực — không thể giả, không thể mua, không thể gian lận. Pillar 2 hiển thị rõ nhất ở đây: con thú cưng là gương phản chiếu đúng nghĩa.

## Detailed Design

### Core Rules

1. `totalXuEarned` là counter chỉ tăng — stored tại `children/{childId}.totalXuEarned` trong Firestore. Mỗi task approve: `totalXuEarned += task.xuReward` (atomic `FieldValue.increment`).
2. **5 levels, 3 evolution stages:**

| Level | Stage | Form | `totalXuEarned` ngưỡng | Xu bonus khi lên | Chest (`chestCount`) |
|-------|-------|------|-----------------------|------------------|--------------|
| L1 | Baby | Baby Mochi | 0 (start) | — | — |
| L2 | Young | Young Mochi | 150 | +75 xu | +1 |
| L3 | Young | Young Mochi | 400 | +100 xu | +1 |
| L4 | Grown | Grown Mochi | 900 | +125 xu | +1 |
| L5 | Grown | Grown Mochi | 1800 | +150 xu | +1 |

3. **Evolution** (sprite form thay đổi) xảy ra tại L2 và L4. L3, L5 không thay đổi form — chỉ nhận reward.
4. Khi `totalXuEarned` đạt ngưỡng:
   - Ghi `petLevel += 1` vào Firestore
   - `FieldValue.increment(+xuBonus)` vào `xuBalance`
   - `FieldValue.increment(+1)` vào `children/{childId}.chestCount` (field owned by Gacha/Loot System #12 — level-up dùng chung cơ chế free-chest, không tạo item mới)
   - Emit `GameEvent(petLeveledUp, newLevel)` → Pet State Machine trigger `LEVELING_UP` state
5. **`LEVELING_UP` triggered state** (mới, cần bổ sung vào Pet State Machine): animation đặc biệt 3s, không bị interrupt bởi bất kỳ triggered state nào khác — priority cao nhất.
6. Sau `LEVELING_UP` (3s): nếu là evolution level (L2/L4) → swap Mochi sprite sang form mới; return về Base Mood.
7. Không có level down — `petLevel` chỉ tăng.
8. **Evolution stage rendering là PURE FUNCTION của `petLevel`, không phải side-effect của transition event** (thêm 2026-07-06, fix Scenario 5 blocker từ review-all-gdds): `evolutionStage = f(petLevel)` — Baby nếu `petLevel==1`, Young nếu `petLevel` ∈ {2,3}, Grown nếu `petLevel` ∈ {4,5} — PHẢI được tính lại và render đúng MỖI LẦN app load/resume/reconnect, độc lập với việc `LEVELING_UP` animation có thực sự play hay không. **Lý do bắt buộc**: nếu bé offline lúc bố mẹ approve nhiều task liên tiếp làm `petLevel` nhảy qua 2+ ngưỡng (ví dụ 1→3) trong các transaction riêng biệt, client's `petLevelProvider` listener (đang không chạy lúc offline) rất có thể chỉ nhận ĐÚNG 1 snapshot cuối cùng khi reconnect (`petLevel=3`), không replay từng transition L1→L2→L3. Nếu evolution-swap CHỈ là side-effect của event `petLeveledUp` (như mô tả cũ ở Rule 6), sprite sẽ mãi kẹt ở Baby form — `petLevel` đúng trong Firestore, mọi xu/chest bonus đều credited đúng, nhưng Mochi's sprite sai vĩnh viễn, không có error signal nào. Fix: tách rời 2 concern — (a) `LEVELING_UP` animation là celebratory side-effect của EVENT, chỉ play khi client thực sự witness transition; (b) sprite form hiển thị LUÔN được derive lại từ `petLevel` hiện tại mỗi lần render/load, không phụ thuộc animation có chạy hay không.

### States and Transitions

```
[task approved]
      │
      ▼
totalXuEarned += xuReward
      │
      ├── totalXuEarned < nextLevelThreshold → no change
      │
      └── totalXuEarned >= nextLevelThreshold
            │
            ├── petLevel += 1
            ├── xuBalance += xuBonus
            ├── chestCount += 1
            └── emit GameEvent(petLeveledUp, newLevel)
                  │
                  ▼
            LEVELING_UP animation (3s, highest priority)
                  │
                  ├── if evolution level (L2/L4): swap sprite form
                  └── return Base Mood
```

### Interactions with Other Systems

| System | Direction | Data |
|--------|-----------|------|
| Currency System (#7) | IN trigger | Task approve → `totalXuEarned` tăng; OUT: `xuBalance += xuBonus` |
| Pet State Machine (#6) | OUT | `GameEvent(petLeveledUp)` → `LEVELING_UP` state |
| Data Persistence (#4) | IN/OUT | Read/write `petLevel`, `totalXuEarned`, `nextLevelThreshold` |
| Gacha / Loot System (#12) | OUT | `chestCount += 1` (shared field — same as #12's free-chest milestone grant) |
| Pet Room Screen UI (#18) | OUT | `petLevelProvider`, `levelProgressProvider` cho progress bar |

## Formulas

**Level threshold:**
```
nextLevelThreshold(level) =
  L2: 150
  L3: 400
  L4: 900
  L5: 1800
  L5+: maxLevel — no further leveling
```

**Progress bar display (Pet Room UI):**
```
progressPercent = (totalXuEarned - currentLevelFloor) / (nextLevelThreshold - currentLevelFloor) × 100

currentLevelFloor:
  L1: 0   L2: 150   L3: 400   L4: 900   L5: 1800
```

Ví dụ: bé ở L2 (`totalXuEarned` = 220)
→ `progressPercent` = (220 − 150) / (400 − 150) × 100 = 70/250 × 100 = **28%**

**Pace estimate** (với 2 tasks/ngày × 15 xu avg = 30 xu/ngày):
| Level up | Xu cần tích lũy | Ngày ước tính |
|----------|----------------|---------------|
| → L2 | 150 | ~5 ngày |
| → L3 | 400 | ~13 ngày |
| → L4 | 900 | ~30 ngày |
| → L5 | 1800 | ~60 ngày |

**Xu bonus formula:**
```
xuBonus(level) = level × 25 + 25
  L2: 75xu   L3: 100xu   L4: 125xu   L5: 150xu
```

## Edge Cases

1. **Multi-level skip trong 1 approve event** (vd: ở L1, nhận 500 xu từ nhiều approvals rapid-fire): threshold được xử lý tuần tự — L2 trigger trước, reward cộng, `LEVELING_UP` play, rồi mới kiểm tra L3. Tuy nhiên chỉ level up **1 lần mỗi approve event**, kể cả khi `totalXuEarned` vượt qua 2 ngưỡng trong cùng một batch write. Trong thực tế multi-level skip không xảy ra vì mỗi task chỉ cho tối đa 20 xu.

2. **Approve task trong khi `LEVELING_UP` đang chạy**: `totalXuEarned` vẫn tăng bình thường. Nếu đủ ngưỡng level tiếp theo, level-up event được queue — chỉ play sau khi animation `LEVELING_UP` hiện tại kết thúc (không interrupt).

3. **App crash giữa lúc ghi level-up** (sau khi `totalXuEarned` đã tăng, trước khi `petLevel` tăng): khi app restart, so sánh `totalXuEarned` với `nextLevelThreshold(petLevel)` — nếu `totalXuEarned >= nextLevelThreshold(currentLevel)`, trigger lại level-up. Xu bonus và `chestCount` increment phải **idempotent** — dùng Firestore transaction để tránh double-grant.

4. **Bé đã ở L5 (max level)**: `totalXuEarned` tiếp tục tăng nhưng không trigger level-up nữa. Progress bar ẩn hoặc hiển thị "MAX" — không đầy rồi loop lại về 0%.

5. **`LEVELING_UP` bị interrupt bởi app going background**: Flame game pause; animation resume khi foreground. Animation celebratory tiếp tục đúng, nhưng sprite form hiển thị vẫn luôn đúng theo Core Rule 8 (pure function của `petLevel` hiện tại) — không phụ thuộc animation đã hoàn thành hay chưa.

6. **Bé offline lúc bố mẹ approve nhiều task liên tiếp, `petLevel` nhảy qua 2+ ngưỡng trước khi client kịp reconnect** (ví dụ L1→L4, sửa 2026-07-07 — làm rõ worked example bị muddled trước đó, fix Scenario 5 blocker từ review-all-gdds): Client's `petLevelProvider` listener không chạy lúc offline, có thể chỉ nhận đúng 1 snapshot cuối (`petLevel=4`) khi reconnect, không replay từng transition L1→L2→L3→L4 riêng lẻ. Theo Core Rule 8: evolution stage KHÔNG chờ animation-per-transition — app load/reconnect luôn tính lại `evolutionStage = f(petLevel=4) = Grown` (đúng theo bảng: L4-L5 = Grown) và render đúng ngay, bất kể có bao nhiêu `LEVELING_UP` animation đã "bị bỏ lỡ" dọc đường (ở đây là 3 lần: L1→L2, L2→L3, L3→L4). Bé không xem được animation trung gian (chấp nhận được — không có ai xem lúc offline), nhưng sprite hiển thị PHẢI đúng ngay khi app mở lại, không kẹt ở form cũ (Baby hoặc Young).

7. **`chestCount` increment thất bại** (Firestore write error): log error + retry tối đa 3 lần. Nếu vẫn fail, hiển thị notification "Bé có 1 phần thưởng chưa nhận — mở lại app để nhận". Chest không bị mất — stored trong pending reward queue, nhận lại khi mở app.

## Dependencies

**Upstream:**
- **Parent Approval (#11)** ✅ Designed (design/gdd/parent-approval.md) — trigger gốc "task approved" gây ra `totalXuEarned` increment, thực hiện trong cùng Firestore `runTransaction` với level-up check (xem #11 Core Rules).
- **Currency System (#7)** ✅ — `xuBalance` increment pattern (`FieldValue.increment`) dùng cho xu bonus khi lên level
- **Data Persistence (#4)** ✅ — `petLevel` field đã có trong schema; **`totalXuEarned` và `nextLevelThreshold` chưa có** — cần bổ sung vào schema của #4
- **Pet State Machine (#6)** ✅ — cần bổ sung triggered state mới `LEVELING_UP` (priority cao nhất, non-interruptible) — hiện chưa có trong #6, cần propagate change

**Downstream:**
- **Gacha / Loot System (#12)** ✅ — `chestCount += 1` mỗi lần lên level, dùng chung field với milestone free-chest logic của #12 (không phải item riêng)
- **Flutter-Flame State Bridge (#5)** ✅ — propagate `GameEvent(petLeveledUp)` → `MochiComponent` để trigger sprite swap sau `LEVELING_UP`
- **Pet Room Screen UI (#18)** — đọc `petLevelProvider`, `levelProgressProvider` cho progress bar + "MAX" state ở L5

**Riverpod providers owned:**
```dart
final petLevelProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc('families/$parentId/children/$childId')
    .snapshots()
    .map((doc) => (doc.data()?['petLevel'] as int?) ?? 1);
});

final levelProgressProvider = StreamProvider<double>((ref) {
  // (totalXuEarned - currentLevelFloor) / (nextLevelThreshold - currentLevelFloor)
  // returns 1.0 and UI shows "MAX" when petLevel == 5
});
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| `nextLevelThreshold` (L2/L3/L4/L5) | 150 / 400 / 900 / 1800 | 100–2500, tăng dần | Bé mất động lực — level đầu tiên quá xa | Level lên quá nhanh — mất cảm giác thành tựu, hết nội dung sớm | Phải khớp với pace estimate (~5/13/30/60 ngày ở 30 xu/ngày); không đổi delta ratio (~2.5–2.7×/level) quá nhiều |
| `xuBonus(level)` = level × 25 + 25 | L2: 75, L3: 100, L4: 125, L5: 150 | 25–300 | Bonus lớn hơn effort để đạt ngưỡng kế → lạm phát economy | Bonus quá nhỏ → level-up không cảm thấy "đáng" | Phải nhỏ hơn nhiều so với threshold delta (không được trả lại toàn bộ xu vừa tiêu) |
| Chest per level-up | 1 | 1–2 | `chestCount` chồng chất, giảm giá trị mỗi chest | — (0 sẽ phá vỡ player fantasy "phần thưởng cho bé chăm chỉ") | Không nên đổi mà không re-cân bằng Gacha/Loot (#12) — cùng field với free-chest milestone |
| `LEVELING_UP` animation duration | 3s | 2–5s | Cảm giác chờ đợi, đặc biệt nếu bé lên level nhiều lần trong 1 session | Bé không kịp thấy hiệu ứng — mất "wow moment" | Không được interrupt bởi triggered state khác dù ngắn hay dài |
| Số levels / evolution stages | 5 levels, 3 stages (Baby/Young/Grown) | 3–7 levels | Cần thêm nhiều sprite form → art cost tăng | Ít cảm giác tiến triển dài hạn | Mỗi evolution stage cần asset riêng — đổi số lượng ảnh hưởng Art Bible + asset production |

## Acceptance Criteria

**GIVEN** bé ở L1 (`totalXuEarned` = 140), bố mẹ approve task +20 xu,
**WHEN** batch write commit (`totalXuEarned` = 160),
**THEN** `petLevel` = 2, `xuBalance += 75`, `chestCount += 1`, `LEVELING_UP` animation play 3s, sprite swap sang Young Mochi ngay sau khi animation kết thúc.

**GIVEN** bé ở L2 (`totalXuEarned` = 395), approve task +20 xu (`totalXuEarned` = 415, vượt ngưỡng L3 = 400),
**WHEN** batch write commit,
**THEN** `petLevel` = 3, `xuBalance += 100`, `chestCount += 1`, `LEVELING_UP` plays — nhưng KHÔNG sprite swap (L3 không phải evolution level), Mochi giữ nguyên Young form.

**GIVEN** bé đang ở L5 (max level, `totalXuEarned` ≥ 1800),
**WHEN** bố mẹ approve thêm task,
**THEN** `totalXuEarned` tăng nhưng `petLevel` không đổi, progress bar hiển thị "MAX", không trigger `LEVELING_UP`.

**GIVEN** `LEVELING_UP` animation đang chạy (từ 1 level-up trước đó),
**WHEN** bố mẹ approve thêm task đủ ngưỡng level tiếp theo,
**THEN** level-up event mới được queue — không interrupt animation hiện tại, chỉ play sau khi animation trước đã kết thúc hoàn toàn.

**GIVEN** app crash ngay sau khi `totalXuEarned` tăng nhưng trước khi `petLevel`/xu bonus/`chestCount` được ghi,
**WHEN** app restart,
**THEN** hệ thống detect `totalXuEarned >= nextLevelThreshold(petLevel hiện tại)` và trigger lại level-up đúng 1 lần — xu bonus và `chestCount` increment không bị double-grant nhờ Firestore transaction.

**GIVEN** app vào background trong lúc `LEVELING_UP` animation đang chạy,
**WHEN** app trở lại foreground,
**THEN** animation resume từ điểm pause (Flame pause/resume), sprite swap (nếu evolution level) chỉ xảy ra sau khi animation hoàn thành trọn vẹn.

**GIVEN** bé offline khi `petLevel` nhảy từ 1 lên 4 qua nhiều approve transaction riêng biệt (Core Rule 8, fix Scenario 5 blocker),
**WHEN** app mở lại và `petLevelProvider` nhận snapshot cuối `petLevel=4`,
**THEN** Mochi render đúng Grown form NGAY LẬP TỨC khi màn hình load — không kẹt ở Baby form, không chờ animation trung gian nào, kể cả khi các `LEVELING_UP` animation cho L2/L3 chưa từng được client witness.

**GIVEN** `chestCount` increment write thất bại do lỗi Firestore,
**WHEN** hệ thống retry 3 lần đều fail,
**THEN** hiển thị notification "Bé có 1 phần thưởng chưa nhận — mở lại app để nhận", chest được lưu vào pending reward queue, không bị mất.
