# Parent Approval System

> **Status**: Approved ✅ — /design-review APPROVED WITH CONCERNS 2026-07-04, all findings resolved (math error in chestDelta worked example fixed, storedEnergy cap coordination noted, stale back-reference in #16 closed)
> **Author**: User + Agents
> **Last Updated**: 2026-07-04
> **Implements Pillar**: Pillar 4 — Bố Mẹ Là Đồng Minh, Không Phải Cảnh Sát

## Overview

Parent Approval System là lớp orchestration biến task đã submit của bé thành phần thưởng thật — một cách atomic. Khi bố mẹ tap Approve, một Firestore transaction duy nhất chạm vào mọi system có liên quan: task status chuyển sang `'approved'`, xu và energy được credited (Currency #7, Time & Decay #2), hạt giống đang chờ trong túi bé nở ra (`seedCount -= 1`, Seed Buffer #10), và bộ đếm nỗ lực trọn đời của Mochi tăng lên kèm level-up check (`totalXuEarned`, Pet Leveling #16). Khi Reject, cùng hình dạng transaction áp dụng nhưng không có reward, kèm hiệu ứng nhẹ nhàng hơn (seed "tàn lụi", theo Seed Buffer #10).

System này không sở hữu bất kỳ field nào nó chạm vào — Task Library, Currency, Seed Buffer, và Pet Leveling đều đã tự định nghĩa phần ghi của mình. Việc của Parent Approval là trở thành nơi duy nhất lắp ráp những mảnh đó thành một atomic operation, và quyết định thứ tự fire của các side effect — ví dụ, một animation level-up không thể bị cắt ngang bởi một Reject đua song song, và một crash giữa chừng không thể double-grant reward.

Về mặt player-facing, đây cũng là một tương tác thật, chủ động — không phải infrastructure thụ động: bố mẹ nhận push notification, mở một card hiển thị bé đã làm gì, và tap Approve hoặc Reject chỉ trong vài giây. Không có system này, mọi thứ Task Library tạo ra sẽ mãi mãi nằm đó — không có cơ chế nào thực sự trao "nỗ lực thật → phần thưởng thật" (Pillar 1) nếu thiếu một hành động approve chủ động. Và vì đây là một cái tap nhẹ nhàng, có chủ đích, chứ không phải một cổng review khắt khe, nó giữ đúng tinh thần Pillar 4: bố mẹ là đồng minh nói "bố/mẹ thấy con rồi," không phải trạm kiểm soát soi xét bằng chứng.

## Player Fantasy

**Bố mẹ's moment:** Điện thoại rung nhẹ. Bố mẹ đang ở công ty, hoặc đang nấu cơm. Nhìn xuống: *"Bông vừa hoàn thành Quét nhà. Hãy kiểm tra và approve nhé!"* (Push Notification #9). Tap vào, thấy một card nhỏ — tên task, ai làm, khi nào — và chỉ cần một cái tap: Approve. Không có form, không có câu hỏi xác nhận, không có "bạn có chắc không?". Chỉ là một cái gật đầu số hóa, nhanh như một cái gật đầu thật ngoài đời. Bố mẹ không cảm thấy mình đang "làm việc quản trị" — bố mẹ cảm thấy mình vừa nói với con, dù đang cách xa: *"Bố/mẹ thấy con rồi, giỏi lắm."*

**Bé's moment:** Bé đã tap "Đã xong!" từ nãy, hạt giống đang nằm trong túi chờ (Seed Buffer #10's fantasy — không lặp lại ở đây). Khi bố mẹ approve, hạt giống nở ra: xu rơi xuống, Mochi nhảy EXCITED. Bé không thấy "Parent Approval System" — bé chỉ thấy: *"Bố/mẹ đã thấy mình làm rồi. Mochi vui rồi."* Đây chính là khoảnh khắc Pillar 1 trở thành thật: không phải app tự động phát thưởng, mà là một người thật, xác nhận một việc thật.

**Vì sao đây là "đồng minh, không phải cảnh sát" (Pillar 4)**: Nếu approve flow chậm, cần nhiều bước, hay đòi hỏi bố mẹ "duyệt kỹ" như một cơ chế kiểm soát — nó phá vỡ toàn bộ cảm giác. Approve phải nhanh hơn việc lo lắng liệu mình có nên approve không. Tốc độ và sự nhẹ nhàng của tương tác NÀY, tự nó, chính là thông điệp: bố mẹ tin con.

## Detailed Design

### Core Rules

1. **Trigger**: Bố mẹ mở Parent Dashboard (trực tiếp hoặc qua deep link `petquest://parent/tasks/pending` từ push notification) → thấy danh sách pending tasks → tap **Approve** hoặc **Reject** trên từng task riêng lẻ. Không có "Approve All" trong MVP — mỗi task là một quyết định riêng, giữ đúng tinh thần "bố mẹ thấy từng việc con làm" thay vì rubber-stamp hàng loạt.

2. **Approve Transaction** — dùng Firestore `runTransaction` (không phải batch write đơn thuần), vì cần đọc giá trị hiện tại trước khi quyết định level-up:
   - **UI layer trước khi gọi transaction**: disable Approve/Reject button cho card đó ngay khi tap đầu tiên (trước khi transaction resolve) — đóng race window double-tap ở tầng UI, không chỉ dựa vào guard bên trong transaction.
   - **Đọc đầu tiên bên trong transaction (bắt buộc, không phải bước riêng trước transaction)**: `tasks/{taskId}.status` — nếu khác `'pending'`, **abort ngay tại đây**. Đây chính là bước đọc đầu tiên của `runTransaction`, không phải một pre-check tách rời — Firestore serialize các transaction đọc-cùng-document trên server, nên đặt check ở đây (chứ không phải trước khi gọi transaction) là điều duy nhất thực sự chặn được race 2 devices approve gần như đồng thời (Edge Case 3). Một pre-check tách rời sẽ bị TOCTOU race và không bảo vệ được gì.
   - **Đọc tiếp**: `children/{childId}` (để lấy `totalXuEarned`, `petLevel`, `approvedTaskCount` hiện tại), `tasks/{taskId}` (để lấy `xuReward`, `energyReward`).
   - **Tính toán** (trong transaction, trước khi ghi):
     - `newTotalXuEarned = totalXuEarned + task.xuReward`
     - `leveledUp = newTotalXuEarned >= nextLevelThreshold(petLevel)` — chỉ true nếu petLevel < 5 (Pet Leveling #16 Edge Case 4: max level không trigger nữa)
     - `newApprovedTaskCount = approvedTaskCount + 1`
     - `hitChestMilestone = newApprovedTaskCount % 5 == 0` (Gacha/Loot #12)
   - **Ghi** (tất cả trong cùng 1 transaction):
     - `tasks/{taskId}.status = 'approved'`, `approvedAt = now`
     - `xuBalance += task.xuReward` (Currency #7)
     - `storedEnergy += task.energyReward` (Time & Decay #2)
     - `children/{childId}.lastApprovedAt = FieldValue.serverTimestamp()` (Time & Decay #2 — **thêm 2026-07-07, ADR-0005**: đây là field reset "đồng hồ decay". Thiếu nó thì decay không bao giờ reset → nửa recovery của Time & Decay bất động. Dùng `serverTimestamp()` (không phải client `now`) để chống chỉnh giờ; an toàn khỏi lỗi null-until-ack vì approve là `runTransaction` (cần mạng, không apply optimistic vào cache).
     - `seedCount = max(0, seedCount - 1)` (Seed Buffer #10)
     - `totalXuEarned = newTotalXuEarned` (Pet Leveling #16)
     - `approvedTaskCount = newApprovedTaskCount` (Gacha/Loot #12)
     - **Nếu `leveledUp`**: `petLevel += 1`, `xuBalance += xuBonus(newLevel)` (thêm vào trên), `chestCount += 1`
     - **Nếu `hitChestMilestone`**: `chestCount += 1` (độc lập — nếu cả hai xảy ra cùng lúc, `chestCount += 2` tổng cộng; xem Edge Cases)
   - **Emit events** (sau khi transaction commit thành công): `GameEvent(taskApproved)` luôn fires (Seed Buffer bloom, trigger EXCITED) — **sửa 2026-07-06 (fix Scenario 1 blocker từ review-all-gdds)**: trước đây ghi `GameEvent(petMoodChanged → EXCITED)`, nhưng `petMoodChanged`'s payload type thật là `PetMood` enum (Base Mood), không phải Triggered State — type mismatch sẽ throw runtime `TypeError`. `taskApproved` là event type mới, đúng kiểu, do Bridge (#5) sở hữu. Nếu `leveledUp`, cũng emit `GameEvent(petLeveledUp)` → Pet State Machine tự xử lý priority (LEVELING_UP đè lên EXCITED, theo #6's rule đã có sẵn — GDD này không cần định nghĩa lại).

3. **Reject Transaction** — cũng dùng `runTransaction` (không phải write đơn thuần), vì cũng cần cùng idempotency guard như Approve:
   - **Đọc đầu tiên bên trong transaction**: `tasks/{taskId}.status` — nếu khác `'pending'`, abort ngay (cùng lý do như Approve — chặn double-tap và race giữa 2 devices).
   - Nếu vẫn `'pending'`: `tasks/{taskId}.status = 'rejected'`, `rejectedAt = now` (field mới — xem Dependencies, cần thêm vào Data Persistence #4)
   - `seedCount = max(0, seedCount - 1)` (Seed Buffer #10)
   - Không thay đổi `xuBalance`, `storedEnergy`, `totalXuEarned`, `approvedTaskCount`
   - Emit event: Seed Buffer "wither" animation (không qua Pet State Machine triggered state — seed wither là UI-local animation, không phải Mochi mood)

4. **Backlog handling**: Nếu bố mẹ có N pending tasks, mỗi task được approve/reject qua transaction RIÊNG BIỆT — không gộp thành 1 mega-transaction. Điều này khớp với Pet Leveling Edge Case 1 ("chỉ level up 1 lần mỗi approve event") — "1 approve event" nghĩa là 1 transaction cho 1 task, không phải 1 phiên Parent Dashboard.

5. **Xử lý lỗi transaction (thống nhất, không phân biệt nguyên nhân)**: Nếu `runTransaction` throw vì bất kỳ lý do gì — offline, transient backend error, hay bất kỳ `FirebaseException` nào khác — hành vi giống hệt nhau: re-enable Approve/Reject button, hiển thị "Approve thất bại — thử lại" (hoặc "Reject thất bại — thử lại"), `task.status` giữ nguyên `'pending'`. Không có retry loop tự động phía client — một lần tap mới của bố mẹ chính là lần retry. Không cần định nghĩa số lần retry cụ thể của Firestore SDK nội bộ (implementation detail, khác nhau theo phiên bản `cloud_firestore` — verify tại thời điểm implement, không giả định con số ở GDD level).
   - **Offline pre-check** (trước khi tap, không phải error handling): dùng `connectivity_plus` (hoặc tương đương) để disable Approve/Reject preemptively khi thiết bị không có kết nối mạng — hiển thị "Không có kết nối mạng — thử lại khi có mạng" thay vì để bố mẹ tap và chờ transaction fail. Đây là optimization UX, không phải cơ chế chặn duy nhất — nếu device báo có mạng nhưng Firestore thực tế không reachable, transaction vẫn sẽ throw và rơi vào nhánh xử lý lỗi thống nhất ở trên.

### States and Transitions

```
[Bố mẹ mở pending task card]
         │
         ├──────────────┐
         ▼              ▼
     [Approve]       [Reject]
         │              │
         ▼              ▼
  runTransaction:    runTransaction (simple):
  - check status=='pending', else ABORT
  - read totalXuEarned, petLevel, approvedTaskCount
  - task.status = 'approved', approvedAt = now
  - xuBalance += xuReward
  - storedEnergy += energyReward
  - seedCount = max(0, seedCount-1)
  - totalXuEarned += xuReward
  - approvedTaskCount += 1
  - if leveledUp: petLevel+=1, xuBalance+=bonus, chestCount+=1
  - if hitChestMilestone: chestCount+=1
         │              │
         ▼              ▼
  emit EXCITED       emit "wither" (Seed Buffer UI-local,
  (+ petLeveledUp     no Pet State Machine trigger)
   if leveledUp)      task.status='rejected', rejectedAt=now
                       seedCount = max(0, seedCount-1)
```

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Task Library (#8) | IN/OUT | Read `xuReward`, `energyReward`, `status`; write `status`, `approvedAt`/`rejectedAt` | `tasks/{taskId}` within transaction |
| Currency (#7) | OUT | `xuBalance += task.xuReward` (+ level-up bonus if any) | `FieldValue.increment` within transaction |
| Time & Decay (#2) | OUT | `storedEnergy += task.energyReward`; `lastApprovedAt = serverTimestamp()` (resets decay clock — ADR-0005) | within transaction |
| Seed Buffer (#10) | OUT | `seedCount -= 1` (both approve and reject) | within transaction |
| Pet Leveling (#16) | IN/OUT | Read `totalXuEarned`, `petLevel`; write `totalXuEarned`, `petLevel`, level-up `xuBalance`/`chestCount` bonus | within transaction, per #16's Core Rule 4 |
| Gacha/Loot (#12) | OUT | `approvedTaskCount += 1`; `chestCount += 1` on milestone or level-up | within transaction |
| Pet State Machine (#6) | OUT | `GameEvent(taskApproved (trigger EXCITED))`, `GameEvent(petLeveledUp)` if leveled up | via Flutter-Flame Bridge (#5), after transaction commits |
| Push Notification (#9) | IN | Deep link `petquest://parent/tasks/pending` opens this system's pending list | consumed, not written |
| Parent Dashboard UI (#21) | ← Parent Approval | Pending tasks list, Approve/Reject actions | `pendingTasksProvider` (Task Library), calls `approveTask()`/`rejectTask()` |

## Formulas

Parent Approval không có mathematical formula riêng của mình — `xuReward`/`energyReward` thuộc Task Library (#8), `nextLevelThreshold`/`xuBonus` thuộc Pet Leveling (#16). Thay vào đó, section này định nghĩa **hai contracts** mà system phải luôn đảm bảo.

**Contract 1 — Chest Delta (combination logic):**

Đây là nơi duy nhất hai trigger độc lập (level-up, chest milestone) có thể cộng dồn trong cùng một transaction — cần công thức rõ ràng để tránh double-count hoặc under-count:

```
chestDelta = [leveledUp] + [hitChestMilestone]
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Leveled up this approve | `leveledUp` | bool | {0,1} | 1 nếu `newTotalXuEarned >= nextLevelThreshold(petLevel)` VÀ `petLevel < 5` |
| Hit chest milestone | `hitChestMilestone` | bool | {0,1} | 1 nếu `newApprovedTaskCount % gacha_free_chest_milestone == 0` (registry: `gacha_free_chest_milestone` = 5) |
| Chest delta | `chestDelta` | int | 0–2 | Số chest được cộng vào `chestCount` trong transaction này |

**Output Range:** 0–2, không clamp — cả hai có thể cùng đúng (xem Core Rules quyết định: cả hai đều grant, không suppress lẫn nhau).

**Example:** `petLevel=2`, `totalXuEarned=380`, `nextLevelThreshold(2)=400` (ngưỡng để lên L3, theo Pet Leveling #16), task `xuReward=20` → `newTotalXuEarned=400` → `leveledUp=1`. Đồng thời `approvedTaskCount=24` → `newApprovedTaskCount=25` → `25 % 5 == 0` → `hitChestMilestone=1`. Kết quả: `chestDelta=2`, `chestCount += 2`.

**Write mechanism (làm rõ 2026-07-06, review-all-gdds W7)**: `chestCount += chestDelta` được viết bằng `FieldValue.increment(chestDelta)` bên trong `runTransaction`, KHÔNG phải absolute-set. Điều này composes an toàn với Gacha/Loot (#12)'s chest-open decrement (`FieldValue.increment(-1)`, cũng đã explicit hoá cùng ngày) — 2 write path độc lập trên cùng field, cả hai atomic, không có lost-update risk kể cả khi bé mở chest đúng lúc bố mẹ approve task khác đang chạy đồng thời. Đối xứng documentation với #12's reasoning, đóng gap asymmetry.

**Contract 2 — Latency Contract** (tham chiếu số liệu thật từ spike):

| Step | Expected | Worst case (đo được từ spike) |
|------|----------|--------------------------------|
| Firestore `runTransaction` commit (local write ack) | <100ms | — |
| Parent write → child device stream update (đo thật, `prototypes/firebase-multidevice-sync-spike-2026-07-03/`) | ~151ms avg | 439ms |
| **End-to-end (bố mẹ tap Approve → bé thấy bloom animation)** | **<200ms** | **<500ms** |

**Retry note:** Firestore's optimistic-concurrency retry (built-in SDK behavior, không cấu hình được) tự xử lý stale-read contention khi 2 devices approve gần như đồng thời. Không cần retry logic riêng — single-parent, single-write contention hiếm ở quy mô này.

## Edge Cases

1. **Bố mẹ's device offline khi tap Approve/Reject**: Detect qua `connectivity_plus` — nếu offline, nút bị disable preemptively, hiển thị "Không có kết nối mạng — thử lại khi có mạng," không có write attempt nào tới Firestore. Nếu device báo có mạng nhưng transaction vẫn throw (Firestore thực tế không reachable): rơi vào Edge Case 7 (xử lý lỗi thống nhất), không phải một nhánh riêng.

2. **Bố mẹ tap Approve 2 lần liên tiếp nhanh (double-tap) trên cùng 1 task**: Phòng vệ 2 lớp — (a) UI layer disable button ngay từ tap đầu tiên (trước khi transaction resolve), nên tap thứ hai thường không tới được đâu cả; (b) nếu vẫn lọt qua (ví dụ do render delay), transaction thứ hai đọc `task.status != 'pending'` ngay ở bước đọc đầu tiên bên trong `runTransaction` → abort êm, không ghi gì, không error hiển thị cho bố mẹ, không double-grant.

3. **Hai devices (bố và mẹ) cùng tap Approve trên cùng 1 task gần như đồng thời** (trong cửa sổ ~150-439ms trước khi listener cập nhật UI): Firestore serialize 2 transactions trên server — cái đến trước thắng và commit bình thường; cái đến sau đọc thấy `status` đã đổi, tự abort. Không double-grant, không error hiển thị cho người tap sau — UI của họ chỉ đơn giản thấy task đã biến mất khỏi pending list ngay sau đó.

4. **`leveledUp` và `hitChestMilestone` cùng true trong 1 approve** (xem Formulas Contract 1): `chestDelta = 2`, cả 2 chest được grant — không suppress lẫn nhau (đã quyết định ở Core Rules).

5. **`hitChestMilestone` true nhưng bé đã ở petLevel 5 (max)**: `leveledUp` luôn = 0 khi `petLevel >= 5` (theo định nghĩa biến ở Formulas) — chỉ `chestDelta = 1` từ milestone, không có level-up nào xảy ra hay được tính nhầm.

6. **`task.xuReward`/`energyReward` bị chỉnh sửa sau khi task được tạo (trước khi approve)** — có thể do bug hoặc client bị compromise: GDD này không tự validate lại giá trị (đó là trách nhiệm của Task Library #8's Reward Integrity Guard tại thời điểm CREATE). Parent Approval tin tưởng giá trị đọc được tại thời điểm approve là đúng. **Kiến trúc note**: cần Firestore Security Rule khóa `xuReward`/`energyReward` là immutable sau khi task document được tạo — flag cho Architecture phase, không giải quyết ở GDD level.

7. **`runTransaction` thất bại vì bất kỳ lý do gì** (transient backend error, Firestore không reachable dù device báo có mạng, hoặc lỗi khác): xử lý thống nhất — re-enable button, hiển thị "Approve thất bại — thử lại" (hoặc "Reject thất bại — thử lại"), `task.status` giữ nguyên `'pending'`, không có gì bị mất. Không có client-side retry loop tự động — một tap mới của bố mẹ chính là lần retry. Số lần retry nội bộ của Firestore SDK trước khi throw là implementation detail, khác nhau theo phiên bản `cloud_firestore` — verify tại thời điểm implement, GDD này không giả định con số cụ thể.

8. **Bố mẹ Reject nhầm, muốn đổi ý**: Không có "un-reject" trong MVP. Task giữ `status: 'rejected'` vĩnh viễn — bé phải submit lại task đó như một task mới nếu muốn thử lại.

9. **2 bé trong cùng gia đình được approve gần như đồng thời** (bố mẹ approve task của bé A rồi ngay lập tức approve task của bé B): 2 transactions độc lập hoàn toàn, path Firestore khác nhau (`children/{childIdA}` vs `children/{childIdB}`) — không có crosstalk, không có race condition giữa chúng.

10. **`storedEnergy` vượt quá 100 sau khi transaction commit**: `FieldValue.increment()` trong transaction của GDD này KHÔNG tự cap tại 100 — transaction chỉ cộng `task.energyReward` thẳng vào, có thể tạm thời vượt 100 (ví dụ: energy=90, task energy reward=25 → 115). Đây là hành vi đã biết và đã có giải pháp riêng: Cloud Function `onTaskApproved` (owned by Data Persistence #4) chạy sau khi transaction commit, set `storedEnergy` về 100 nếu vượt. Parent Approval không tự enforce cap — chỉ có một cửa sổ overshoot ngắn (client-side UI có thể hiển thị >100 trong khoảnh khắc trước khi Cloud Function correct lại). Xem `data-persistence-layer.md` Edge Cases để biết chi tiết cơ chế cap.

## Dependencies

**Upstream (Parent Approval cần — hard dependencies, không thể hoạt động thiếu):**
- **Task Library (#8)** ✅ Approved — task schema (`xuReward`, `energyReward`, `status`), reward values đã locked trong registry
- **Currency (#7)** ✅ Approved — `xuBalance` increment pattern
- **Time & Decay (#2)** ✅ Approved — `storedEnergy` increment pattern (Time & Decay tự nhận nó không ghi Firestore, Parent Approval là bên thực thi write)
- **Seed Buffer (#10)** Designed (pending review) — `seedCount` decrement, cả approve và reject
- **Pet Leveling (#16)** ✅ Approved — `totalXuEarned`, `petLevel`, `nextLevelThreshold()`, `xuBonus()` — level-up logic sống trong transaction của GDD này nhưng công thức thuộc #16
- **Gacha/Loot (#12)** ✅ Approved — `approvedTaskCount`, `chestCount`, milestone modulo logic
- **Push Notification (#9)** Designed (pending review) — deep link `petquest://parent/tasks/pending` là entry point vào pending list (soft dependency — hệ thống vẫn hoạt động nếu bố mẹ mở app thủ công thay vì qua notification)

**Downstream (phụ thuộc vào Parent Approval):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Parent Dashboard UI (#21) | Pending list, Approve/Reject actions | `pendingTasksProvider`, `approveTask()`/`rejectTask()` |
| Pet State Machine (#6) | `GameEvent(taskApproved)` → trigger EXCITED | via Flutter-Flame Bridge (#5) — #6 đã named #11 làm source (đã propagate, xem #6's Core Rules) |

**Functions owned:**
```dart
// Sửa 2026-07-18 (ADR-0013): approveTask trả về Future<ApproveResult?> chứ
// không phải Future<void> — null nghĩa là idempotent no-op (task đã được
// approve/reject rồi), non-null nghĩa là transaction vừa thật sự commit.
// Caller (Parent Dashboard ConsumerWidget) dùng kết quả này để quyết định có
// emit GameEvent(taskApproved)/(petLeveledUp) hay không — repository tự nó
// không bao giờ chạm vào GameEventBus (ADR-0004 §3: repository không phải 1
// trong 2 sanctioned emit adapter). Cả 2 hàm cũng thêm tham số parentId,
// khớp với convention thật đã dùng ở TaskRepository/CustomTaskRepository.
class ApproveResult {
  const ApproveResult({required this.leveledUp, this.newPetLevel});
  final bool leveledUp;
  final int? newPetLevel; // non-null iff leveledUp — payload for GameEvent(petLeveledUp), per the
  //                          already-registered game_event_bus contract (petLeveledUp→int, not null)
}
Future<ApproveResult?> approveTask({required String parentId, required String childId, required String taskId});
Future<void> rejectTask({required String parentId, required String childId, required String taskId});
// Cả hai throw nếu offline (per Edge Case 1) — UI layer bắt exception,
// hiển thị "Không có kết nối mạng" thay vì để lỗi generic lộ ra.
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Offline detection debounce | 0ms (immediate) | 0–500ms | Bố mẹ tap Approve khi mạng thực sự mất → transaction throw error thay vì bị block trước bởi UI (trải nghiệm xấu hơn) | Mạng chập chờn (flaky) → false positive "không có mạng" dù thực ra có, gây khó chịu | Tradeoff giữa catching offline sớm và tránh false positive trên mạng yếu |
| Loading spinner threshold (Approve/Reject tap) | 200ms | 100–500ms | Bố mẹ cảm thấy lag dù transaction đã xong — spinner xuất hiện không cần thiết | Spinner "nháy" cho những tap gần như tức thì → visual noise, trông giật | Dựa trên Formulas Contract 2: avg 151ms, worst-case 439ms — spinner chỉ nên xuất hiện khi vượt avg đáng kể |

**Không định nghĩa lại**: "Max pending tasks displayed" thuộc Seed Buffer (#10) Tuning Knobs (default 10, range 5–20) — Parent Dashboard UI hiển thị cùng danh sách, dùng chung knob đó, không tạo bản sao ở đây.

## Visual/Audio Requirements

Parent Approval không sở hữu asset riêng — nó trigger animation đã thuộc về system khác: Seed Buffer (#10)'s bloom/wither animation, Pet State Machine (#6)'s EXCITED/LEVELING_UP. Không cần thêm asset spec ở đây.

Một âm thanh nhỏ có thể cần riêng cho hành động Approve/Reject tự thân (khác với bloom/wither phía bé) — ví dụ: tiếng "tick" nhẹ khi bố mẹ tap Approve, xác nhận hành động đã đăng ký. Defer chi tiết cho `audio-director` khi audio pass toàn bộ Parent Dashboard UI (#21) được thiết kế.

## UI Requirements

Parent Approval đóng góp pattern tương tác cho Parent Dashboard UI (#21), không tự sở hữu screen:
- **Pending task card**: hiển thị tên bé, task title, category icon, thời gian submit; 2 nút Approve/Reject.
- **Button states cần implement chính xác theo Core Rules**: disabled ngay khi tap (trước khi transaction resolve), disabled khi offline (`connectivity_plus`), re-enable + error message khi transaction fail.
- **Không có "Approve All"** trong MVP — mỗi card độc lập.

📌 **UX Flag — Parent Approval**: Button state machine (idle → tapped/disabled → success-disappear hoặc error-reenable) cần `/ux-design` spec cho Parent Dashboard UI (#21) trước khi viết epics — đặc biệt là cách hiển thị lỗi "thất bại, thử lại" mà không tạo cảm giác đáng lo cho bố mẹ (giữ tinh thần Pillar 4).

## Acceptance Criteria

**Approve — normal path**
- **GIVEN** 1 pending task với `xuReward=X`, `energyReward=Y`, bé chưa đạt ngưỡng level tiếp theo hay milestone thứ 5, **WHEN** bố mẹ tap Approve, **THEN** `task.status='approved'`, `approvedAt` được set, `xuBalance` tăng đúng X, `storedEnergy` tăng đúng Y, `lastApprovedAt` được set = `serverTimestamp()` (reset đồng hồ decay — ADR-0005), `seedCount` giảm 1, `totalXuEarned` tăng đúng X, `approvedTaskCount` tăng 1 — không field nào khác trong `children/{childId}` thay đổi.
- **GIVEN** approve vừa commit thành công, **WHEN** transaction trả về, **THEN** `GameEvent(taskApproved (trigger EXCITED))` emit đúng 1 lần, không có `petLeveledUp` event nào.

**Approve — level-up only**
- **GIVEN** `newTotalXuEarned >= nextLevelThreshold(petLevel)` và `petLevel < 5`, và `newApprovedTaskCount % 5 != 0`, **WHEN** approve, **THEN** `leveledUp=1`, `hitChestMilestone=0`, `chestDelta=1`, `petLevel += 1`, `xuBalance` được cộng cả `task.xuReward` VÀ `xuBonus(newLevel)`, cả `taskApproved (trigger EXCITED)` và `petLeveledUp` đều emit.

**Approve — chest milestone only**
- **GIVEN** `newApprovedTaskCount % 5 == 0` nhưng `newTotalXuEarned < nextLevelThreshold(petLevel)`, **WHEN** approve, **THEN** `hitChestMilestone=1`, `leveledUp=0`, `chestDelta=1`, `chestCount += 1`, không `petLeveledUp` event nào emit.

**Approve — both triggers combo (Formulas Contract 1)**
- **GIVEN** cả `leveledUp=1` VÀ `hitChestMilestone=1` (ví dụ: `petLevel=2`, `totalXuEarned=380`, `nextLevelThreshold(2)=400`, task `xuReward=20`, `approvedTaskCount=24`), **WHEN** transaction commit, **THEN** `chestDelta=2`, `chestCount` tăng đúng 2, `petLevel` chỉ tăng 1 (không nhân đôi level-up), cả `taskApproved (trigger EXCITED)` lẫn `petLeveledUp` emit đúng 1 lần mỗi loại.
- **GIVEN** cả hai trigger đều false, **WHEN** approve, **THEN** `chestDelta=0`, `chestCount` không đổi.

**Reject**
- **GIVEN** 1 pending task, **WHEN** bố mẹ tap Reject, **THEN** `task.status='rejected'`, `rejectedAt` được set, `seedCount` giảm 1; `xuBalance`, `storedEnergy`, `totalXuEarned`, `approvedTaskCount` giữ nguyên.
- **GIVEN** reject vừa commit, **WHEN** transaction trả về, **THEN** chỉ UI-local "wither" animation chạy — không `GameEvent` nào emit tới Pet State Machine.

**Idempotency (Approve và Reject)**
- **GIVEN** task đã có `status='approved'` hoặc `'rejected'`, **WHEN** một transaction approve/reject khác chạy trên cùng task, **THEN** transaction abort ở bước đọc đầu tiên, không field nào bị ghi đè, không reward nào bị cấp lần 2, không error hiển thị cho bố mẹ.

**Double-tap (Edge Case 2)**
- **GIVEN** bố mẹ tap Approve 2 lần trong <200ms, **WHEN** cả 2 tap register, **THEN** button đã bị disable sau tap đầu nên tap thứ hai không kích hoạt hành động mới; nếu vẫn lọt qua, transaction thứ hai abort êm — task chỉ được credit đúng 1 lần.

**Two-device race (Edge Case 3)**
- **GIVEN** 2 thiết bị cùng tap Approve trên cùng task trong cửa sổ <439ms, **WHEN** Firestore server serialize 2 transactions, **THEN** transaction đến trước commit đầy đủ, transaction đến sau abort không lỗi hiển thị, `xuBalance`/`totalXuEarned`/`approvedTaskCount` chỉ cộng đúng 1 lần tổng cộng (test qua Firestore emulator, giả lập 2 client đồng thời).

**Max level + milestone (Edge Case 5)**
- **GIVEN** `petLevel=5` (max) và `newApprovedTaskCount % 5 == 0`, **WHEN** approve, **THEN** `leveledUp=0` bất kể `newTotalXuEarned`, `chestDelta=1`, `petLevel` không đổi, không `petLeveledUp` event.

**Tampered reward values (Edge Case 6)**
- Không kiểm ở đây — thuộc phạm vi Task Library (#8) Reward Integrity Guard test suite.

**Transaction failure (Edge Case 7)**
- **GIVEN** `runTransaction` throw (giả lập qua emulator/mock), **WHEN** lỗi xảy ra, **THEN** button re-enable, hiển thị "Approve thất bại — thử lại", `task.status` vẫn `'pending'`, không partial write nào tồn tại (verify bằng đọc lại `children/{childId}` và `tasks/{taskId}`).

**Offline block (Edge Case 1)**
- **GIVEN** `connectivity_plus` báo device offline, **WHEN** bố mẹ mở pending task card, **THEN** Approve/Reject bị disable, hiển thị "Không có kết nối mạng," không write attempt nào tới Firestore.

**No un-reject (Edge Case 8)**
- **GIVEN** task có `status='rejected'`, **WHEN** bố mẹ xem lại task, **THEN** không có action "un-reject" khả dụng.

**Two children, no crosstalk (Edge Case 9)**
- **GIVEN** approve task bé A rồi ngay lập tức approve task bé B, **WHEN** cả 2 transaction commit, **THEN** mỗi `children/{childId}` chỉ nhận đúng reward tương ứng, không crosstalk.

**Latency (Formulas Contract 2) — ADVISORY, không phải blocking gate**
- **GIVEN** điều kiện mạng ổn định giống spike, **WHEN** bố mẹ tap Approve, **THEN** bloom animation phía bé xuất hiện trong <500ms ở ≥95% của N≥20 lần đo (dùng script đo của `prototypes/firebase-multidevice-sync-spike-2026-07-03/`). Vượt ngưỡng → ghi nhận regression để điều tra, không fail cứng ngay lần đầu — đây là Config/Data-tier smoke check, không phải BLOCKING unit test (theo `.claude/docs/coding-standards.md` Testing Standards).

## Open Questions

- **"Đã xử lý bởi người khác" UX**: Nếu bố tap Reject đúng lúc mẹ vừa Approve xong (race, Edge Case 3) — bố's transaction abort êm theo spec, nhưng bố's UI đang thấy card đó biến mất bất ngờ mà không rõ lý do. Có cần toast "Mẹ đã xử lý task này rồi" không? Cần input từ `/ux-design` khi thiết kế Parent Dashboard (#21).
- **"Approve All" cho Alpha**: MVP cố tình không có (giữ tinh thần "thấy từng việc con làm"). Nếu backlog lớn (bố mẹ đi công tác 1 tuần) gây friction thật, có nên thêm ở Alpha không? Defer đến playtest feedback.
- **Reject reason**: Bé có được biết lý do bị reject không (hiện tại: không, wither animation là anonymous, giống Seed Buffer #10's Open Question tương tự)? Cần input từ Parent Dashboard UX design — cùng câu hỏi đã defer ở #10.
- **Multi-parent-device token** (kế thừa từ Push Notification #9's Open Question): khi cả bố và mẹ đều có app, cả 2 đều thấy cùng pending list qua Firestore stream (đã hoạt động tự nhiên) — nhưng chỉ 1 người nhận push notification (1 `fcmToken`). Không phải vấn đề của GDD này, nhưng đáng nhắc lại: UX nên rõ ràng rằng "ai cũng approve được, nhưng chỉ 1 người được báo."
