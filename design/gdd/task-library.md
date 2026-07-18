# Task Library

> **Status**: Approved (reward table revised 2026-07-06 — dominant-strategy fix from review-all-gdds, economy-designer consulted, see Core Rule 1)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật (tasks are the real-world effort that powers everything)

## Overview

Task Library quản lý toàn bộ hệ thống nhiệm vụ của PetQuest — từ catalog 5 categories preset đến việc cho phép bố mẹ tạo custom tasks riêng cho gia đình. Mỗi task là một Firestore document trong `tasks/{taskId}` subcollection của child, với `xuReward` và `energyReward` được định nghĩa tại thời điểm tạo.

System này là **cầu nối giữa thế giới thực và thế giới ảo**: bé submit một task (đã làm xong việc nhà, học bài, tập đàn) → task document được tạo với status `pending` → bố mẹ approve → xu và energy được cộng. Task Library định nghĩa catalog preset, reward values per category, và lifecycle của một task từ lúc tạo đến khi được approve hoặc rejected.

**Task là one-shot**: mỗi lần bé submit là một document mới — không có recurring tasks trong MVP. Bố mẹ có thể tạo custom tasks ngoài 5 categories mặc định để phù hợp với thói quen riêng của gia đình (ví dụ: "Đọc sách 15 phút", "Dọn phòng ngủ").

## Player Fantasy

Bé nhìn vào danh sách tasks và thấy **những lựa chọn có ý nghĩa** — không phải todo list khô khan, mà là những "nhiệm vụ" mang sức mạnh thật: *"Nếu mình luyện đàn 20 phút hôm nay, Mochi sẽ nhảy vui và mình có thêm 20 xu."*

Khoảnh khắc bé tap "Đã xong!" sau khi hoàn thành task là khoảnh khắc **tự hào nhỏ bé nhưng thật sự** — bé vừa làm điều gì đó tốt ngoài đời, và game ghi nhận điều đó. Không phải bố mẹ nhắc nhở. Không phải bắt buộc. Bé tự chọn làm vì muốn thấy Mochi vui.

Với bố mẹ: nhận notification "Con đã submit task: Quét nhà" → một cái gật đầu nhỏ, tap Approve → cả hai cùng tham gia vào một khoảnh khắc kết nối thật sự. Task Library là nơi Pillar 4 trở thành hiện thực: bố mẹ không ra lệnh, bố mẹ đồng hành.

## Detailed Design

### Core Rules

**1. Task Categories & Reward Values**

**Sửa 2026-07-06 (fix dominant-strategy blocker từ review-all-gdds, economy-designer consulted)**: Bảng cũ khiến Study/Arts strictly dominate mọi category khác trên CẢ 2 trục (xu VÀ energy cùng lúc) — bé không có lý do gì để log Helping task. Bảng mới decouple 2 trục: mỗi category là 1 điểm trên Pareto frontier giảm dần (xu cao → energy thấp và ngược lại) — không category nào ≥ category khác trên cả 2 trục.

| Category | `categoryId` | `xuReward` | `energyReward` | Quest framing |
|----------|-------------|-----------|---------------|---------------|
| Học bài / làm bài tập | `study` | **25 xu** | **20 energy** | "Nạp trí tuệ cho Mochi" |
| Luyện nhạc / nghệ thuật | `arts` | **25 xu** | **20 energy** | "Truyền cảm hứng cho Mochi" |
| Làm việc nhà | `chores` | 15 xu | 25 energy | "Dọn năng lượng cho Mochi" |
| Luyện tập thể thao | `sport` | 15 xu | 25 energy | "Nạp sức mạnh cho Mochi" |
| Giúp đỡ bố mẹ (khác) | `helping` | 10 xu | **30 energy** | "Chia sẻ yêu thương với Mochi" |
| Custom (bố mẹ tạo) | `custom` | 15 xu | 25 energy | [bố mẹ tự đặt tên] |

**Trade-off rõ ràng (không còn hierachy tuyệt đối)**: Study/Arts (25xu/20energy) cao nhất về xu nhưng THẤP NHẤT về energy. Helping (10xu/30energy) thấp nhất về xu nhưng CAO NHẤT về energy — trở thành nguồn energy tốt nhất trong game, dù effort/xu thấp. Chores/Sport/Custom (15xu/25energy) ở giữa. Bé tối ưu xu (mua item) chọn Study/Arts; bé tối ưu energy (Mochi đang TIRED/SAD, cần phục hồi nhanh) chọn Helping. Không có "câu trả lời luôn đúng" nữa.

**2. Preset Task Examples per Category**

Mỗi category có 3–5 preset task templates bé có thể chọn nhanh (không cần gõ):

| Category | Preset tasks |
|----------|-------------|
| `study` | Làm bài tập toán · Đọc sách 15 phút · Ôn bài · Viết chính tả |
| `arts` | Tập đàn 20 phút · Vẽ tranh · Hát 1 bài · Làm thủ công |
| `chores` | Quét nhà · Rửa bát · Dọn phòng · Tưới cây · Gấp quần áo |
| `sport` | Chạy bộ · Đạp xe · Nhảy dây · Tập thể dục buổi sáng |
| `helping` | Đi chợ cùng mẹ · Trông em · Mang đồ cho bố · Nấu ăn cùng |

**3. Task Lifecycle**

```
[Bé tap "Đã xong!"]
        │
        ▼
tasks/{taskId}.set({
  title, flavorText, categoryId,
  xuReward, energyReward,        ← values from category table above (validated by Cloud Function)
  status: 'pending',
  submittedAt: now,
  approvedAt: null
})
        │
        ▼
[Bố mẹ tap Approve]          [Bố mẹ tap Reject]
        │                           │
        ▼                           ▼
status: 'approved'           status: 'rejected'
Batch: +xuReward,            No reward — task archived
       +energyReward
       ↑
       Batch write executed by Parent Approval (#11)
       Task Library defines reward values; not the write operation.
```

**4. Custom Task Creation (bố mẹ)**

- Bố mẹ vào Parent Dashboard → "Thêm nhiệm vụ mới" (UI owned by Parent Dashboard UI #21)
- Nhập: `title` (tên task) + chọn `categoryId` (để xác định reward tier)
- `xuReward` và `energyReward` tự động lấy từ category table — không cho phép bố mẹ override reward values (bảo vệ economy balance)
- **Lưu dưới dạng TEMPLATE, không phải task instance**: ghi vào collection mới `families/{parentId}/customTasks/{customTaskId}`: `{ title, categoryId, targetChildId, createdAt }` — không có `status`, `xuReward`, hay `energyReward` field (reward values re-derived từ `categoryId` tại thời điểm bé chọn template và submit, không cache trong template). Template này xuất hiện như một pickable option thêm trong task picker của bé (Task Management UI #19), cùng nhóm với 5 preset categories có sẵn.
- **Tại sao không tạo `tasks/{taskId}` với status='pending' ngay khi bố mẹ nhập**: vi phạm Rule 5.1 ("bé chỉ submit sau khi đã làm xong ngoài đời") — bố mẹ tạo template không phải hành động "đã làm xong", chỉ là thêm lựa chọn cho bé. Task instance thật (với `status: 'pending'`) chỉ được tạo khi bé chọn template và tap "Đã xong!" — thời điểm đó copy `title`/`categoryId` từ template, tính `xuReward`/`energyReward` từ category table như bình thường.

**Reward Integrity Guard:**
UI-layer enforcement is not sufficient. A Cloud Function `onTaskCreated` (hoặc Firestore Security Rule) phải validate rằng `xuReward` và `energyReward` trong document khớp với category reward table trước khi write được chấp nhận. Nếu client gửi giá trị không khớp → write bị reject, task không được tạo. Điều này bảo vệ economy khỏi client-side bugs và manipulation.

**5. Task Submission Rules**
- Bé chỉ submit task sau khi đã làm xong ngoài đời — không có "đặt trước"
- Không giới hạn số tasks submit per day (bố mẹ có thể approve có chọn lọc)
- Một task chỉ có thể submit một lần — không duplicate cùng task trong ngày (không enforce technically trong MVP, nhưng bố mẹ có thể reject)

---

### States and Transitions

| Status | Mô tả | Trigger |
|--------|-------|---------|
| `pending` | Bé đã submit, chờ bố mẹ | Bé tap "Đã xong!" |
| `approved` | Bố mẹ đã approve, rewards granted | Bố mẹ tap Approve → batch write |
| `rejected` | Bố mẹ từ chối, no reward | Bố mẹ tap Reject |

Không có `cancelled` state — bé không thể rút task đã submit (tránh gaming the system).

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Auth & Account (#1) | → Task Library | `parentId`, `childId` | `authStateProvider`, `activeChildProvider` |
| Data Persistence (#4) | ↔ | `tasks/{taskId}` read/write | Firestore batch contract |
| Parent Approval (#11) | → Task Library | approve/reject action | reads `tasks` pending list, writes `status` |
| Seed Buffer (#10) | ← Task Library | task submit event | visual feedback while pending |
| Task Management UI (#19) | ← Task Library | pending/approved task list | `pendingTasksProvider`, `taskHistoryProvider` |
| Push Notification (#9) | ← Task Library | task submitted event | triggers FCM to parent |

## Formulas

Task Library không có game-math formulas. Nhưng có **reward lookup contract** — quan trọng vì đây là nơi Time & Decay và Currency GDDs defer đến.

**Reward Lookup Contract:**

```
xuReward     = categoryRewardTable[task.categoryId].xuReward
energyReward = categoryRewardTable[task.categoryId].energyReward
```

| `categoryId` | `xuReward` | `energyReward` | Ratio (energy/xu) |
|-------------|-----------|---------------|------------------|
| `study` | 25 | 20 | 0.8 |
| `arts` | 25 | 20 | 0.8 |
| `chores` | 15 | 25 | 1.67 |
| `sport` | 15 | 25 | 1.67 |
| `helping` | 10 | 30 | 3.0 |
| `custom` | 15 | 25 | 1.67 |

> **Sửa 2026-07-06**: Ratio giờ thực sự load-bearing (khác biệt thật, không chỉ là commentary trên 1 bảng đã có hierarchy tuyệt đối từ trước). `helping`'s ratio cao (3.0) phản ánh đúng vị trí mới: xu thấp nhất NHƯNG energy cao nhất trong game — không còn "thấp ở mọi mặt", mà là "trade-off có chủ đích" (effort thấp, xu thấp, nhưng phục hồi energy Mochi tốt nhất).

**Daily earning potential (calibration check, sửa 2026-07-06 — 2 combo minh hoạ 2 mục tiêu tối ưu khác nhau):**

| Scenario | Tasks/day | xuEarned | energyEarned |
|----------|-----------|---------|-------------|
| Light (1 task) | 1× chores | 15 xu | 25 energy |
| Normal, tối ưu xu (2 tasks) | 1× study + 1× chores | 40 xu | 45 energy |
| Normal, tối ưu energy (2 tasks) | 1× helping + 1× chores | 25 xu | 55 energy |
| Busy, tối ưu xu (3 tasks) | 2× study + 1× chores | 65 xu | 65 energy |
| Busy, tối ưu energy (3 tasks) | 2× helping + 1× chores | 35 xu | 85 energy |

- Normal day (tối ưu xu): 40 xu → cheapest item (10 xu) reachable day 1 ✅
- Normal day (tối ưu xu): 45 energy from SLEEPING (10) → 55 → CONTENT ✅ (không instant HAPPY — matches Time & Decay calibration)
- Busy day (tối ưu energy): 10 + 85 = 95 → HAPPY ✅ — combo xu-tối-ưu 3 task (2×study+1×chores = 65 energy) chỉ đạt CONTENT (75), KHÔNG đạt HAPPY — minh hoạ trade-off: muốn HAPPY nhanh, cần ưu tiên energy category (helping/chores), không phải xu category (study/arts).

## Edge Cases

- **Nếu `parentId` hoặc `childId` là null** (chưa đăng nhập, hoặc chưa chọn child profile): cả `pendingTasksProvider` và `taskHistoryProvider` trả về empty list ngay lập tức — không issue Firestore query (tránh path `families/null/children/null/tasks`). Guard đã có trong provider code (`if (parentId == null || childId == null) return const Stream.empty()`).

- **Nếu bé submit task với `categoryId: 'custom'`** (dù custom là category dành cho bố mẹ tạo): reward fallback về `custom` tier (15 xu / 25 energy) — tương đương chores. Không exploitable về mặt economy. Cloud Function validate reward values khớp category table sẽ reject nếu giá trị sai, nhưng không cần block `custom` categoryId từ child-side.

- **Nếu bé submit cùng task nhiều lần trong 1 ngày** (ví dụ: "Quét nhà" × 3): Mỗi submit tạo một document riêng — không enforce uniqueness. Bố mẹ có thể approve tất cả hoặc chỉ approve 1. Không cần technical guard trong MVP — trust bố mẹ làm trọng tài.

- **Nếu `categoryId` không hợp lệ hoặc null** (bug hoặc custom task bị lỗi): **Bị reject ngay tại thời điểm tạo** bởi reward-integrity Security Rule (ADR-0009 §3) — `categoryId in rewardTable()` = false → write bị từ chối, task không được tạo. Vì vậy task với `categoryId` không hợp lệ KHÔNG thể tồn tại đến lúc approve. Approve-time `custom` fallback (15 xu, 25 energy) chỉ còn là lưới an toàn phòng thủ cho dữ liệu legacy/hỏng (nếu có), không phải path bình thường. (Sửa 2026-07-08, ADR-0009 — trước đây mô tả như thể task invalid-categoryId có thể tồn tại và được approve với fallback.)

- **Nếu bố mẹ reject task**: Task status = `rejected`, không có reward. Bé thấy task bị reject trong history. Không có penalty — bé có thể submit lại task mới. Không cần explanation field cho MVP (bố mẹ nói trực tiếp với bé).

- **Nếu task ở trạng thái `pending` quá lâu** (bố mẹ quên approve trong nhiều ngày): Task vẫn ở `pending` vô thời hạn — không auto-expire. Bố mẹ có thể approve backlog cùng lúc; Cloud Function `onTaskApproved` cap energy tại 100 như đã spec.

- **Nếu bố mẹ approve khi app offline**: Batch write vào Firestore cache → sync khi online. Energy và xu vẫn được credited đúng khi bé mở app sau.

- **Nếu `title` rỗng** (bé submit mà không chọn preset và không gõ tên): Validate ở UI layer trước khi cho submit — "Đặt tên cho nhiệm vụ của bạn". Task Library không nhận task không có title.

- **Nếu số tasks `pending` quá nhiều** (ví dụ: 20 tasks pending): Parent Dashboard vẫn hiển thị hết — không giới hạn. Bố mẹ approve theo thứ tự muốn. Không có UX issue vì approve là action nhanh.

- **Nếu child profile bị xóa**: Cloud Function `onChildProfileDelete` cascade delete toàn bộ `tasks/{taskId}` — không cần xử lý riêng tại Task Library.

## Dependencies

**Upstream:**
- **Auth & Account (#1)** ✅: `parentId`, `childId` để scope task collection
- **Data Persistence (#4)** ✅: `tasks/{taskId}` schema và batch write contract

**Downstream:**
- **Seed Buffer (#10)**: nhận task submit event để show visual feedback
- **Parent Approval (#11)**: đọc pending tasks list, ghi `status` + batch reward
- **Push Notification (#9)**: nhận task submitted event → FCM đến bố mẹ
- **Task Management UI (#19)**: hiển thị pending/history task lists + `customTasks` templates như picker options
- **Parent Dashboard UI (#21)**: viết `customTasks/{customTaskId}` templates qua "Thêm nhiệm vụ mới" UI

**Riverpod providers owned:**
```dart
// ADR-0009/0008: FirestorePaths constant, safe nullable accessor (.value trên riverpod 3.x —
// sửa 2026-07-13, xem ADR-0002 Correction note; trước đó ghi .valueOrNull),
// Stream.value(const []) khi null (không const Stream.empty()). Cả 2 provider cần null-guard.
final pendingTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);
  return FirebaseFirestore.instance
    .collection(FirestorePaths.tasks(parentId, childId))
    .where('status', isEqualTo: 'pending')
    .orderBy('submittedAt', descending: true)   // composite index (status + submittedAt desc)
    .snapshots()
    .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});

final taskHistoryProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);
  final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
  return FirebaseFirestore.instance
    .collection(FirestorePaths.tasks(parentId, childId))
    .where('status', whereIn: ['approved', 'rejected'])   // plain `in` (KHÔNG not-in — không combine
    .where('submittedAt', isGreaterThanOrEqualTo: cutoff)  //   được với range trên field khác)
    .orderBy('submittedAt', descending: true)   // composite index, submittedAt DESCENDING
    .snapshots()
    .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});
```

## Tuning Knobs

**Sửa 2026-07-06**: Ranges đổi để phản ánh Pareto-frontier mới (decoupled). Rule cấu trúc quan trọng phải giữ khi retune sau này: category nào tăng xu trong range của nó PHẢI giữ ở mức ≤ neighbor về energy, và ngược lại — đây là ràng buộc giữ dominance không tái xuất hiện.

| Knob | Default | Safe Range | Ghi chú |
|------|---------|------------|---------|
| `study`/`arts` xuReward | 25 | 20–30 | Highest xu tier — giữ trên `chores`/`sport` |
| `study`/`arts` energyReward | 20 | 15–25 | **Thấp nhất** energy tier (đảo ngược so với bản cũ) — giữ dưới `chores`/`sport` |
| `chores`/`sport` xuReward | 15 | 10–20 | Mid xu tier |
| `chores`/`sport` energyReward | 25 | 20–30 | Mid energy tier — default `energyPerTask` baseline từ Time & Decay |
| `helping` xuReward | 10 | 5–15 | Lowest xu tier — không đổi |
| `helping` energyReward | 30 | 25–35 | **Cao nhất** energy tier (đảo ngược so với bản cũ) — nguồn energy tốt nhất trong game |
| `custom` rewards | 15 xu / 25 energy | same as chores/sport | Bố mẹ không override — giữ economy ổn định |
| Max preset tasks per category | 5 | 3–10 | UI list phải cuộn nếu >7 |
| Task history retention | 30 days | 7–90 days | Archive older tasks để giữ query performance |

## Visual/Audio Requirements

Task Library là data/logic layer — không có visual output trực tiếp. Nhưng task submit event triggers 2 visual moments owned bởi other systems:
- **Seed drop animation** (Seed Buffer #10): khi bé tap "Đã xong!" → hạt giống rơi vào túi
- **Approve celebration** (Pet State Machine #6 via Bridge #5): Mochi EXCITED bounce khi approve

Task Library chỉ cần: task category icons (5 icons + 1 custom icon) cho Task Management UI:
- Format: SVG hoặc PNG 48×48px, pastel color per category
- `study`: sách/bút icon (Mint Breeze)
- `arts`: nốt nhạc/cọ vẽ icon (Lavender Soft)
- `chores`: chổi/nhà icon (Peach Glow)
- `sport`: bóng/giày icon (Honey Gold)
- `helping`: tay/tim icon (Cloud White với border)
- `custom`: dấu cộng / ngôi sao icon (neutral)

## UI Requirements

3 UI surfaces thuộc Task Library:

1. **Task Submission Screen** (bé): grid preset tasks per category + "Tự nhập" option + tap "Đã xong!" CTA
2. **Pending Tasks View** (trong Parent Dashboard): list pending tasks với Approve / Reject buttons per task
3. **Task History** (bé): list approved/rejected tasks với timestamps, 30-day rolling window

📌 **UX Flag — Task Library**: 3 screens cần `/ux-design` spec trước khi viết epics — Task Submission Screen, Pending Tasks View (Parent Dashboard), Task History. Quest framing ("Nạp trí tuệ cho Mochi") phải được thể hiện trong UI copy, không chỉ trong GDD.

## Acceptance Criteria

**GIVEN** bé tap preset task "Quét nhà" (category: `chores`) và tap "Đã xong!",
**WHEN** task document được tạo,
**THEN** `tasks/{taskId}` có `xuReward=15`, `energyReward=25`, `status='pending'`, `submittedAt=now`.

**GIVEN** bố mẹ tap Approve trên task `study`,
**WHEN** batch write commit,
**THEN** `xuBalance` tăng 25, `storedEnergy` tăng 20 (capped 100 by Cloud Function), `task.status='approved'` — tất cả atomic. (Giá trị sửa 2026-07-06 theo bảng reward mới decoupled.)

**GIVEN** bố mẹ tap Reject trên task,
**WHEN** status update,
**THEN** `task.status='rejected'`, `xuBalance` và `storedEnergy` không thay đổi.

**GIVEN** client cố tạo task với `categoryId = 'invalid_value'` (hoặc `xuReward`/`energyReward` không khớp category table),
**WHEN** write chạy,
**THEN** reward-integrity Security Rule (ADR-0009) **reject write** — task không được tạo. (Task invalid không bao giờ tồn tại đến approve; approve-time `custom` fallback chỉ là lưới phòng thủ cho legacy data.)

**GIVEN** bố mẹ tạo custom task với title "Đọc sách" và category `custom`,
**WHEN** task document được tạo,
**THEN** `xuReward=15`, `energyReward=25` — không cho phép bố mẹ set giá trị khác.

**GIVEN** bé submit task khi offline,
**WHEN** app regain connection,
**THEN** task document sync lên Firestore — xuất hiện trong Parent Dashboard để approve.

## Open Questions

- **Reject explanation**: Có nên cho bố mẹ gõ lý do reject không? (ví dụ: "Con chưa làm đúng") — Pillar 4 friendly nhưng thêm friction. Defer đến Parent Dashboard UX design.
- **Task proof**: Một số gia đình muốn bé upload ảnh/video làm bằng chứng trước khi approve. Tính năng này có vào MVP không? Ảnh hưởng lớn đến storage và UX complexity — **đề xuất: defer đến Alpha**.
- **Recurring tasks**: Có nên thêm flag `isRecurring: bool` cho MVP để bố mẹ setup "Quét nhà mỗi thứ 2/4/6"? Đơn giản hóa UX nhưng thêm scheduling logic — defer đến Vertical Slice scope.
- **Task difficulty within category**: Hiện tại "Đọc sách 5 phút" và "Làm bài toán 1 tiếng" cùng category `study` → cùng reward. Có nên thêm difficulty tier (easy/hard) trong category không? — Defer đến playtest feedback.
- **Parental task templates**: Bố mẹ có thể lưu custom tasks hay phải tạo lại mỗi lần? Template library cho gia đình — defer đến Alpha.
