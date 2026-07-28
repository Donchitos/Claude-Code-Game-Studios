# Time & Decay System

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-06-26
> **Implements Pillar**: Pillar 2 — Thú Cưng Là Hình Ảnh Của Bé (pet mood reflects real effort over time)

## Overview

Time & Decay System tính toán năng lượng hiện tại của Mochi dựa trên thời gian thực. Mỗi giờ không có approved task, Mochi mất một lượng energy nhỏ. Khi bố mẹ approve task, energy cộng thêm một lượng cố định. System chạy hoàn toàn offline — chỉ cần `DateTime.now()` và `lastApprovedAt` timestamp stored trong Firestore.

Khi bé mở app, system tính ngay: *"Bao nhiêu giờ đã trôi qua kể từ lần cuối có approved task?"* → tính energy hiện tại → feed vào Pet State Machine để quyết định Mochi đang ở mood nào.

**Thiết kế anti-punishment**: Energy không bao giờ về 0 sau một đêm bình thường (~8 giờ ngủ). Decay được calibrate để bé cảm thấy *Mochi cần mình* — không phải *Mochi sắp chết*. Pillar anti-pattern: không có countdown timer đỏ, không có "khẩn cấp" giả tạo.

## Player Fantasy

Bé mở app buổi sáng và thấy Mochi đang ngáp ngủ, màu hơi nhạt — *"Mochi nhớ mình rồi, để mình làm bài tập cho Mochi vui lại."* Không phải lo lắng. Không phải tội lỗi. Chỉ là sự kéo nhẹ nhàng của tình cảm.

Ngược lại, sau một tuần bé chăm chỉ, Mochi luôn sáng rực và nhảy tưng tưng khi mở app — đó là phần thưởng cảm xúc cho sự kiên trì thật sự. Bé nhìn vào Mochi và thấy hình ảnh của chính mình tuần này.

Time & Decay là hệ thống tạo ra *nhịp thở* của game — Mochi lên xuống theo cuộc sống thật của bé, không theo timer nhân tạo.

## Detailed Design

### Core Rules

**1. Energy Model**
- Energy range: `0–100` (float, 2 decimal places)
- Energy không bao giờ xuống dưới `minEnergy = 10` (floor — Mochi luôn còn sống)
- Energy không vượt quá `maxEnergy = 100` (cap)

**2. Decay Calculation (tính khi mở app)**
- Lấy `lastApprovedAt` từ Firestore (timestamp của approved task gần nhất)
- Tính `hoursElapsed = now.difference(lastApprovedAt).inMicroseconds / Duration.microsecondsPerHour` (KHÔNG dùng `now - lastApprovedAt` — `DateTime` không có `operator-`; KHÔNG dùng `.inMinutes / 60.0` — cắt mất phần lẻ dưới 1 phút, gây sai lệch tích lũy — xem ADR-0005 §2)
- `currentEnergy = max(minEnergy, storedEnergy - hoursElapsed × decayRate)`
- Không có background timer — tính một lần khi app foreground

**3. Recovery (khi bố mẹ approve task)**
- `newEnergy = min(maxEnergy, currentEnergy + energyPerTask)`
- Update `storedEnergy` và `lastApprovedAt` vào Firestore ngay lập tức

**4. Energy → Mood Mapping (output cho Pet State Machine)**

> ℹ️ **Ownership (ADR-0005)**: Bảng lookup energy→mood này do **Pet State Machine (#6)** sở hữu (authoritative — TR-petstate-002 "Mood = pure lookup on energy float"). Time & Decay chỉ xuất `currentEnergy` float qua `energyProvider`; #6 map float→mood. Bảng ở đây là **reference-only** — nếu chỉnh ranges, chỉnh ở #6 trước. Tránh double-ownership drift.

| Energy Range | Mood State | Mô tả |
|-------------|------------|-------|
| 80–100 | `HAPPY` | Mochi nhảy tưng tưng, sáng rực |
| 50–79 | `CONTENT` | Mochi bình thường, đủ năng lượng |
| 20–49 | `TIRED` | Mochi ngáp, màu nhạt hơn |
| 10–19 | `SAD` | Mochi nằm lịm, cần được chăm sóc |
| = 10 | `SLEEPING` | Mochi ngủ sâu — floor state |

---

### States and Transitions

```
App foreground
    │
    ▼
Calculate hoursElapsed
    │
    ▼
currentEnergy = max(10, stored - hours × decayRate)
    │
    ├─ 80–100 → HAPPY
    ├─ 50–79  → CONTENT
    ├─ 20–49  → TIRED
    ├─ 10–19  → SAD
    └─ =10    → SLEEPING
         │
         ▼ (bố mẹ approve task — via Parent Approval #11)
    currentEnergy += task.energyReward (capped at 100 by Cloud Function)
    [Firestore write owned by Parent Approval #11 + Data Persistence #4 batch contract]
```

> ⚠️ **Time & Decay là calculation system — không tự ghi Firestore.** Nó tính `newEnergy` và expose qua `energyProvider`. Firestore write (`storedEnergy`, `lastApprovedAt`) do Parent Approval (#11) thực hiện qua batch contract trong Data Persistence (#4).

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Pet State Machine (#6) | Time & Decay → | `currentEnergy` float, `MoodState` enum | `energyProvider` Riverpod |
| Parent Approval System (#11) | → Time & Decay | approved task event | triggers `+energyPerTask` |
| Data Persistence Layer (#4) | ↔ | `storedEnergy`, `lastApprovedAt` | Firestore `children/{childId}` |

## Formulas

**Formula 1 — Decay:**
```
currentEnergy = max(minEnergy, storedEnergy - hoursElapsed × decayRate)
```
| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Stored energy | `storedEnergy` | float | 10–100 | Energy lưu trong Firestore |
| Hours elapsed | `hoursElapsed` | float | 0–∞ | Giờ kể từ `lastApprovedAt` |
| Decay rate | `decayRate` | float/hr | 3.0 | Energy mất mỗi giờ |
| Min energy | `minEnergy` | float | 10 | Floor — không bao giờ xuống thấp hơn |
| Output | `currentEnergy` | float | 10–100 | Energy hiển thị khi mở app |

**Kiểm tra calibration:**
- Ngủ 8h (start 100): 100 − 8×3 = **76** → CONTENT ✓ (không sad khi thức dậy)
- 24h không task (start 100): 100 − 24×3 = **28** → TIRED ✓
- 48h không task (start 100): 100 − 48×3 = max(10, −44) = **10** → SLEEPING ✓

---

**Formula 2 — Recovery:**
```
newEnergy = min(maxEnergy, currentEnergy + task.energyReward)
```
| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Current energy | `currentEnergy` | float | 10–100 | Energy trước khi approve |
| Energy per task | `task.energyReward` | float | 20–30 | Stored in `tasks/{taskId}.energyReward`; Task Library GDD (#8) owns the value per category: study/arts=20, chores/sport/custom=25, helping=30 (sửa 2026-07-06 — decoupled reward axes, fix dominant-strategy blocker từ review-all-gdds; range cũ 25-30 nay mở rộng thành 20-30 vì study/arts giảm xuống 20, helping tăng lên 30). Fallback default=25 if categoryId invalid.
| Max energy | `maxEnergy` | float | 100 | Cap |
| Output | `newEnergy` | float | 10–100 | Energy sau approve |

**Kiểm tra calibration** (assuming default `task.energyReward = 25`):
- Từ SAD (15) + 1 task: 15 + 25 = **40** → TIRED ✓ (không instant HAPPY)
- Từ TIRED (40) + 2 tasks: 40 + 50 = **90** → HAPPY ✓
- Từ CONTENT (60) + 2 tasks: 60 + 50 = min(100, 110) = **100** → HAPPY ✓

## Edge Cases

- **Nếu `lastApprovedAt` là null** (bé mới tạo profile, chưa có task nào được approve): dùng `createdAt` làm baseline. `storedEnergy` khởi tạo = 70 (CONTENT — bé mới bắt đầu, Mochi đang ổn).

- **Nếu device clock bị chỉnh sai** (về quá khứ hoặc tương lai): `hoursElapsed` có thể âm hoặc cực lớn. Guard: `hoursElapsed = max(0, hoursElapsed)`. Nếu `hoursElapsed > 168` (7 ngày): cap tại `minEnergy = 10` — không tính thêm.

- **Nếu bố mẹ approve nhiều tasks cùng lúc** (backlog): mỗi task cộng `task.energyReward` riêng, capped tại 100. 5 tasks pending với default energyReward = 25 → approve hết → energy = min(100, current + 5×25). Không bao giờ vượt 100. Cap enforcement do Cloud Function `onTaskApproved` (Data Persistence GDD).

- **Nếu bé submit task nhưng chưa được approve**: `storedEnergy` và `lastApprovedAt` KHÔNG thay đổi — chỉ thay đổi sau khi bố mẹ approve. Seed Buffer Mechanic xử lý visual feedback trong thời gian chờ.

- **Nếu app mở liên tục nhiều giờ** (bé đang chơi): decay chỉ tính khi app foreground lần đầu. Không recalculate mỗi giây trong session — chỉ recalculate khi app resume từ background.

## Dependencies

**Upstream (Time & Decay cần):**
- **Data Persistence Layer (#4)** ✅: đọc `storedEnergy` và `lastApprovedAt` từ Firestore — required để tính decay khi app foreground

**Downstream (phụ thuộc vào Time & Decay):**
- **Pet State Machine (#6)**: đọc `currentEnergy` → quyết định `MoodState`
- **Data Persistence Layer (#4)**: lưu/đọc `storedEnergy`, `lastApprovedAt` tại `children/{childId}`

**Firestore fields owned by this system:**
```
children/{childId}/
  ├── storedEnergy: float      // 10–100
  └── lastApprovedAt: Timestamp // null nếu chưa có approved task
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| `decayRate` | 3.0/hr | 1.0–5.0 | SAD quá nhanh → bé lo lắng | Mochi không bao giờ buồn → mất urgency | Playtest với con gái trước khi lock |
| `energyPerTask` | 25 | 10–40 | 1 task = HAPPY ngay → mất progression | Bé phải làm 5+ tasks để thoát SAD → nản | **Default value** — Task Library GDD (#8) owns per-category values; this is the fallback if Task Library doesn't specify |
| `minEnergy` | 10 | 5–20 | Mochi trông quá ổn khi bỏ bê | <5 → quá gần "chết" → anti-pillar | Không bao giờ để về 0 |
| `initialEnergy` | 70 | 50–80 | Bé mới bắt đầu quá tốt → không cần làm gì | <50 → bé mới đã thấy Mochi mệt → discouraging | Reset về 70 khi tạo profile mới |
| `maxHoursElapsed` | 168hr | 48–336 | — | <48 → 2 ngày nghỉ lễ đã floor → quá khắt khe | Cap để tránh clock manipulation |

## Visual/Audio Requirements

Không áp dụng trực tiếp — Time & Decay output là `currentEnergy` float. Visuals thuộc Pet State Machine và Pet Room Screen UI. Tuy nhiên:
- Energy bar (nếu hiển thị) phải **không dùng màu đỏ** khi thấp — dùng Lavender Soft thay vì warning red (Art Bible Section 4: no pure red)
- Không có countdown timer visible — chỉ Mochi's mood là signal

## UI Requirements

Không có UI riêng. Energy được expose qua `energyProvider` — UI components đọc và hiển thị theo cách riêng của chúng.

## Acceptance Criteria

**GIVEN** bé mở app sau 8 giờ không có approved task (start energy = 100),
**WHEN** Time & Decay tính toán,
**THEN** `currentEnergy` = 76 và mood = CONTENT (không SAD).

**GIVEN** bé mở app sau 48 giờ không có approved task (start energy = 100),
**WHEN** Time & Decay tính toán,
**THEN** `currentEnergy` = 10 (floor) và mood = SLEEPING.

**GIVEN** Mochi đang SAD (energy = 15) và bố mẹ approve 1 task,
**WHEN** recovery tính toán,
**THEN** `currentEnergy` = 40, mood chuyển sang TIRED, `lastApprovedAt` được update trong Firestore.

**GIVEN** bé có 5 tasks pending và bố mẹ approve tất cả từ SLEEPING (energy = 10),
**WHEN** recovery tính toán,
**THEN** `currentEnergy` = min(100, 10 + 5×25) = 100, mood = HAPPY.

**GIVEN** `lastApprovedAt` là null (bé mới tạo profile),
**WHEN** Time & Decay tính toán,
**THEN** `storedEnergy` khởi tạo = 70, dùng `createdAt` làm baseline — không crash.

**GIVEN** device clock bị chỉnh về quá khứ (hoursElapsed âm),
**WHEN** Time & Decay tính toán,
**THEN** `hoursElapsed` được clamp về 0 — energy không tăng do clock manipulation.

## Open Questions

- **Task-weighted energy**: ~~Resolved~~ — Task Library GDD (#8) đã thiết lập per-category values (sửa 2026-07-06): study/arts=20, chores/sport/custom=25, helping=30. Weighting theo category đã được implement; không cần difficulty tier thêm trong MVP.
- **Weekend decay**: Cuối tuần bé không có bài tập — có nên giảm `decayRate` vào thứ 7, CN không? Cần playtest với gia đình thật.
- **Mochi recovery animation speed**: Khi energy tăng từ SAD → HAPPY, animation có nên instant hay gradual over 1-2 giây? Thuộc Pet State Machine GDD nhưng cần input từ đây.
