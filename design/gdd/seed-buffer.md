# Seed Buffer Mechanic

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật (effort is acknowledged instantly, not after a delay)

## Overview

Seed Buffer Mechanic giải quyết vấn đề **Parent Latency** — khoảng thời gian chờ giữa lúc bé submit task và lúc bố mẹ approve. Thay vì bé nhận xu ngay (không an toàn — chưa được xác nhận) hoặc không nhận gì (mất instant gratification), Seed Buffer trao cho bé một **Hạt Giống bí ẩn** ngay lập tức khi tap "Đã xong!" — một phần thưởng tạm thời, trực quan, có thể cầm nắm được.

**Infrastructure layer**: `seedCount: int` trong `children/{childId}` (Data Persistence schema). Mỗi task submit tăng `seedCount` +1. Khi bố mẹ approve task, `seedCount` giảm -1 và xu + energy được credited. Nếu reject, `seedCount` giảm -1 và không có reward — hạt giống "tàn lụi".

**Player-facing layer**: Hạt giống rơi vào túi đồ với animation nhỏ (Mochi BOUNCING). Bé thấy "1 hạt giống đang chờ" trong UI — mỗi hạt là một lời hứa chờ được thực hiện. Khi bố mẹ approve, animation "hạt giống nở ra" → xu + energy xuất hiện. Khoảnh khắc approve trở thành **sự kiện đáng chờ đợi**, không còn là việc hành chính.

## Player Fantasy

Bé vừa quét nhà xong. Tay còn cầm điện thoại, tap "Đã xong!" — và nhìn thấy một **hạt giống nhỏ lấp lánh rơi xuống** vào góc màn hình. Mochi nhảy một cái. *"Mochi biết rồi. Mochi đang giữ hạt giống cho mình."*

Cảm giác này không phải là "chờ đợi" — đây là **sự kỳ vọng có hình dạng**. Bé không chờ bố mẹ trong vô vọng; bé đang trông nom một thứ gì đó có giá trị, đang nảy mầm.

Khi bố mẹ về nhà và approve, hạt giống **nở bung ra**: xu rơi xuống đếm lên, energy bar Mochi tăng, Mochi nhảy EXCITED. Khoảnh khắc đó là **reward kép** — bé đã chờ và xứng đáng được chờ. Không có instant gratification rẻ tiền, nhưng cũng không có sự im lặng đáng sợ sau khi làm xong việc.

Seed Buffer biến "chờ bố mẹ approve" từ một trải nghiệm thụ động thành một trải nghiệm chủ động: *"Mình có 2 hạt giống đang chờ nở. Hôm nay bố về mình sẽ được bao nhiêu xu nhỉ?"*

## Detailed Design

### Core Rules

**1. Seed Lifecycle**

```
[Bé tap "Đã xong!"] 
        │
        ▼
Task document created (status: 'pending')
        │
        ▼
Seed Buffer: seedCount += 1
Seed entry created: { taskId, taskTitle, submittedAt }
Mochi: BOUNCING triggered state (1s hop)
        │
        ├── [Bố mẹ tap Approve]
        │         │
        │         ▼
        │   seedCount -= 1
        │   Seed entry removed
        │   xu + energy credited (Parent Approval #11 owns batch)
        │   Mochi: EXCITED triggered state
        │   UI: "Hạt giống nở ra!" bloom animation
        │
        └── [Bố mẹ tap Reject]
                  │
                  ▼
            seedCount -= 1
            Seed entry removed
            No reward
            UI: seed "tàn lụi" animation (nhỏ, không gây tổn thương)
```

**2. Seed Identity**

Mỗi seed có identity riêng — không chỉ là số đếm:

```
Seed entry (held in memory / local state — không phải Firestore document riêng):
  taskId: String       ← links to tasks/{taskId}
  taskTitle: String    ← display name: "Hạt giống: Quét nhà"
  submittedAt: Timestamp
```

Seed entries không cần Firestore document riêng — chúng được derive từ `tasks` collection với `status: 'pending'`. `seedCount` trong `children/{childId}` là denormalized integer cho performance (không cần query tasks để hiển thị count).

**3. seedCount Write Rules**

| Event | seedCount change | Who writes |
|-------|-----------------|------------|
| Task submit | +1 | Task submission flow (client-side, atomic with task create) |
| Task approved | -1 | Parent Approval (#11) batch write |
| Task rejected | -1 | Parent Approval (#11) batch write |

`seedCount` không bao giờ âm. Minimum = 0. Không có maximum trên **data layer** (bố mẹ có thể có backlog lớn, `seedCount` field tự nó không cap).

**Reconcile với `seed_pending_list_max` = 10 (Tuning Knob)**: Cap 10 chỉ áp dụng ở **display/animation layer**, không phải data layer. Nếu backlog > 10, chỉ 10 seed cũ nhất được hiển thị dạng card (+ "N more" label) — các seed vượt quá 10 tồn tại trong data (`seedCount` vẫn đếm đúng, task documents vẫn ở đó) nhưng KHÔNG được render thành card riêng, nên cũng không cần animate riêng. Đây là lý do Task Management UI (#19)'s `catchup_total_duration` formula an toàn khi giả định `N ≤ 10` — N ở đó là "số card đang hiển thị," không phải "tổng seedCount," 2 khái niệm khác nhau dù cùng liên quan pending backlog.

**4. seedCount Consistency**

`seedCount` là denormalized cache — source of truth là số documents trong `tasks` collection với `status: 'pending'`. Nếu mất sync (edge case): `seedCount` có thể được recalculate bằng cách count pending tasks. Xử lý trong Parent Approval Cloud Function nếu cần.

**5. Visual Feedback Timing**

- **Seed drop** (task submit): tức thì — Mochi BOUNCING, seed animation vào túi
- **Seed bloom** (task approved): tức thì khi bé mở app và Riverpod stream nhận update từ Firestore
- Nếu bé đang offline khi approve xảy ra: bloom animation plays khi app reconnects và stream fires

---

### States and Transitions

| Seed State | Trigger | Visual |
|-----------|---------|--------|
| In flight | Task submitted | Hạt giống rơi vào túi đồ, Mochi BOUNCING |
| Waiting | Đang chờ approve | "Hạt giống: [taskTitle]" trong pending list |
| Blooming | Task approved | Bloom animation → xu + energy appear |
| Withered | Task rejected | Tàn lụi animation (subtle, không dramatic) |

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Task Library (#8) | → Seed Buffer | task submit event | `tasks/{taskId}` created with `status: 'pending'` |
| Data Persistence (#4) | ↔ | `seedCount` field + pending tasks list | `children/{childId}.seedCount` |
| Parent Approval (#11) | → Seed Buffer | approve/reject event | writes `seedCount -= 1` in batch |
| Pet State Machine (#6) | ← Seed Buffer | BOUNCING trigger (submit) | event via Flutter-Flame Bridge |
| Parent Approval (#11) | → Pet State Machine | EXCITED trigger (approve) — **owned và emit bởi Parent Approval (#11), KHÔNG phải Seed Buffer** (sửa lỗi so với bản trước — bloom animation của #10 chỉ là visual đi kèm khoảnh khắc approve, không phải nguồn phát EXCITED) | xem #11's Core Rules |
| Task Management UI (#19) | ← Seed Buffer | pending seeds list with titles | derived from `pendingTasksProvider` |
| Main Navigation Shell (#17) | ← Seed Buffer | Seed Badge count trên tab icon | `seedCountProvider` — #17 sở hữu rendering, xem #17's Core Rules |

## Formulas

Seed Buffer không có mathematical formulas. Thay vào đó, section này định nghĩa **seedCount invariant contract** — quy tắc toán học mà system phải luôn đảm bảo.

**seedCount Invariant:**

```
seedCount = COUNT(tasks WHERE status = 'pending')
```

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Pending task count | `pendingCount` | int | 0–∞ | Số task documents với `status: 'pending'` |
| Seed count | `seedCount` | int | 0–∞ | Denormalized cache trong `children/{childId}` |

**Invariant:** `seedCount == pendingCount` tại mọi thời điểm sau khi mỗi write operation hoàn thành.

**Drift detection:** Nếu `seedCount != pendingCount` (drift do race condition hoặc failed write): Parent Approval Cloud Function có thể recalculate và correct `seedCount` = actual pending count. Drift không gây data loss — chỉ gây visual glitch (wrong seed count badge).

**Worked example (drift detection)**: `pendingCount` thực tế = 3 (3 task documents với `status: 'pending'`), nhưng `seedCount` field trong Firestore đang lưu 5 (do 1 write bị fail trước đó không rollback đúng). Khi Parent Approval Cloud Function chạy lần approve tiếp theo, nó recalculate `pendingCount` = 3 và ghi đè `seedCount = 3` — badge hiển thị đúng lại 3, không phải 5 hay 4 (không phải chỉ decrement từ giá trị sai).

**seedCount delta per operation:**

| Operation | Delta | Result constraint |
|-----------|-------|------------------|
| Task submit | +1 | seedCount ≥ 1 |
| Task approved | -1 | seedCount ≥ 0 (clamp at 0) |
| Task rejected | -1 | seedCount ≥ 0 (clamp at 0) |

## Edge Cases

- **Nếu task submit thành công nhưng `seedCount += 1` write fails** (network issue): `seedCount` thấp hơn thực tế. Bé thấy ít hạt hơn thực tế — harmless visual glitch. Corrected khi Parent Approval batch runs (recalculate from pending count). Không mất task hay reward.

- **Nếu `seedCount` trở thành âm** (bug: approve/reject nhiều hơn pending count): Clamp tại 0 — `max(0, seedCount - 1)` trong mọi decrement operation. Không bao giờ hiển thị số âm.

- **Nếu bé submit task khi offline**: Task document được tạo trong Firestore local cache ngay lập tức (offline-first). `seedCount += 1` cũng write vào cache. Mochi BOUNCING animation plays. Khi online lại, mọi thứ sync. Bé không nhận ra sự gián đoạn.

- **Nếu bé có nhiều pending tasks và mở app lần đầu sau nhiều ngày** (ví dụ: 5 tasks đã được approve khi offline): Riverpod stream fires với tất cả updates. 5 bloom animations nên play lần lượt (staggered ~0.5s mỗi cái), không cùng lúc — tránh visual chaos. Animation queue là responsibility của Task Management UI (#19).

- **Nếu bố mẹ approve task nhưng bé đang mở app** (foreground): Firestore stream update tức thì → bloom animation plays ngay lập tức. Bé thấy hạt giống nở ra real-time — khoảnh khắc magic nhất của game.

- **Nếu `seedCount` drift lớn** (ví dụ: seedCount = 5 nhưng chỉ có 3 pending tasks): Parent Approval Cloud Function detect drift khi processing approve, recalculate và write correct value. Drift không block gameplay.

- **Nếu `taskTitle` null hoặc rỗng** khi tạo seed entry: Hiển thị fallback "Hạt giống bí ẩn" — không crash UI.

## Dependencies

**Upstream (Seed Buffer cần):**
- **Task Library (#8)** ✅ — task submit event (Firestore `tasks/{taskId}` created with `status: 'pending'`)
- **Pet State Machine (#6)** ✅ — BOUNCING triggered state (seed drop) + EXCITED triggered state (bloom)

**Downstream (phụ thuộc vào Seed Buffer):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Parent Approval (#11) | `seedCount -= 1` trong approve/reject batch | `children/{childId}.seedCount` write |
| Task Management UI (#19) | Seed list với titles + count badge | `pendingTasksProvider` (derive seeds from pending tasks) + `seedCountProvider` |
| Main Navigation Shell (#17) | Seed Badge count trên Tasks tab icon | `seedCountProvider` — #17 owns rendering (xem #17's Core Rules, Seed Badge ownership note) |

**Field owned:**
```
children/{childId}.seedCount: int   // owned by Seed Buffer, written by Task submission + Parent Approval
```

**Riverpod provider owned:**
```dart
final seedCountProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc('families/$parentId/children/$childId')
    .snapshots()
    .map((doc) {
      final raw = (doc.data()?['seedCount'] as num?)?.toInt() ?? 0;
      return raw < 0 ? 0 : raw;
    });
});
// Note: pending seed list derived from pendingTasksProvider (Task Library #8) — no separate provider needed
// Note: full write/read contract + drift-correction rationale — see ADR-0012 (Seed Buffer Derivation Strategy)
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Max seeds displayed in UI | 10 | 5–20 | UI list quá dài, bé bị overwhelm | <5 → không thể hiện được backlog | Hiển thị 10 seeds; nếu >10 → show "+N more" |
| Bloom animation stagger delay | 0.5s | 0.2–1.5s | Cảm giác chậm nếu nhiều seeds bloom cùng lúc | <0.2s → animations overlap, chaos | Khi nhiều tasks approved cùng lúc |
| Seed drop animation duration | 0.8s | 0.4–1.5s | Bé phải chờ lâu để tiếp tục | <0.4s → không kịp thấy | Sau khi tap "Đã xong!" |
| Bloom animation duration (registry: `seed_burst_duration`, "burst" là tên #19 dùng khi tái sử dụng giá trị này cho card animation của nó — cùng 1 giá trị, 2 tên gọi giữa 2 GDD, xem Open Questions) | 1.2s | 0.8–2.0s | Interrupt bé's next action | <0.8s → không đủ rewarding | Khoảnh khắc quan trọng nhất — đừng cắt ngắn |
| Wither animation duration (registry: `seed_wither_duration`) | 0.6s | 0.3–1.0s | Quá dramatic cho reject | <0.3s → bé không nhận ra reject | Nhẹ nhàng — không gây tổn thương |
| `seedCount` max display | 99 | 10–999 | UI badge overflow "99+" | — | Hiển thị "99+" nếu vượt |

## Visual/Audio Requirements

**Seed Drop (task submit):**
- Hạt giống sprite: hình tròn nhỏ (~24×24px), màu mint xanh với core vàng ánh, có particle glow nhẹ
- Animation: xuất hiện tại vị trí tap "Đã xong!" → arc bay vào góc dưới màn hình (seed bag icon) → scale 1.0 → 0.8 khi vào túi, duration 0.8s
- Art style: pastel, round, "muốn được cầm" — consistent với Art Bible

**Seed Bloom (task approved):**
- Animation: hạt giống trong túi scale up → burst thành xu particles + energy particles → particle count 8–12, duration 1.2s
- Xu particles: màu Honey Gold #FFD060 (Art Bible Section 4 canonical hex), rơi xuống và đếm lên trong xu counter
- Energy particles: màu Mint Breeze #A8E6CF, bay lên phía energy bar Mochi
- Sound: short chime (2–3 notes, ascending) — cheerful, không quá to. Tuning: volume 60% of master SFX

**Seed Wither (task rejected):**
- Animation: hạt giống fade out + small puff of smoke, duration 0.6s — subtle, không dramatic
- Màu: desaturate to grey trước khi fade
- Sound: soft "puff" — không sad chord, không alarming. Tuning: volume 40% of master SFX

**Seed Badge (waiting state):**
- Badge icon: 🌱 chibi style, 32×32px, đặt ở góc màn hình hoặc Task tab
- Count label: Honey Gold text, font bold, kích thước 14px
- Pulse animation: gentle 1.05× scale loop mỗi 3 giây — "đang sống, đang chờ"

📌 **Asset Spec** — Visual/Audio requirements defined. Run `/asset-spec system:seed-buffer` after art bible is approved to produce per-asset specs and generation prompts.

## UI Requirements

Seed Buffer contributes visual elements to 2 UI surfaces:

1. **Seed Badge** (persistent, góc màn hình hoặc Task tab nav item): hiển thị `seedCount` với 🌱 icon. Visible bất cứ khi nào `seedCount > 0`. **Sửa 2026-07-17 (reconcile với `design/ux/hud.md`, 2026-07-14, Complete)**: display-only tại MVP — KHÔNG tappable. Bản trước ghi "Tap → navigate đến Task Management UI (#19) pending list", mâu thuẫn trực tiếp với HUD spec's Interaction Robustness note ("HUD elements are display-only at MVP — no tap targets on the chips themselves"), vốn được review sau và cụ thể hơn cho hành vi chip. Bé vẫn tới được pending list bằng cách tap tab "Nhiệm vụ" bình thường (badge chỉ là indicator, không phải shortcut). Xem `design/ux/main-navigation-shell.md`'s Component Inventory cho quyết định đầy đủ.

2. **Pending Seeds List** (trong Task Management UI #19): danh sách seeds với title per seed ("Hạt giống: Quét nhà"), submittedAt timestamp, và trạng thái "Đang chờ bố/mẹ approve...". Max 10 displayed; "+N more" nếu vượt.

📌 **UX Flag — Seed Buffer**: Seed badge placement, bloom animation, VÀ wither animation integration cần `/ux-design` spec trước khi viết epics. Badge placement thuộc Main Navigation Shell (#17, không phải #18 — #17 sở hữu tab-icon rendering). Bloom animation liên quan Pet Room Screen (#18, Mochi's BOUNCING/EXCITED reaction) VÀ Task Management UI (#19, pending list card removal). Wither animation hoàn toàn thuộc #19 (screen sở hữu render, xem #19's Core Rule 2) — trước đây bị bỏ sót khỏi flag này dù cần cùng 1 quyết định screen-integration như Bloom.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory.

**AC-1 — Seed drop on submit** `[INTEGRATION]` BLOCKING
**GIVEN** bé tap "Đã xong!" và task document được tạo thành công,
**WHEN** task submission completes,
**THEN** `seedCount` tăng +1, Mochi plays BOUNCING animation (1s), seed entry "Hạt giống: [taskTitle]" xuất hiện trong pending list — tất cả trong <1 giây.

**AC-2 — Bloom on approve** `[INTEGRATION]` BLOCKING
**GIVEN** bố mẹ tap Approve trên task,
**WHEN** Parent Approval batch write commits,
**THEN** `seedCount` giảm -1, bloom animation plays (1.2s), xu và energy được credited — seed entry biến mất khỏi pending list.

**AC-3 — Wither on reject** `[INTEGRATION]` BLOCKING
**GIVEN** bố mẹ tap Reject trên task,
**WHEN** status update commits,
**THEN** `seedCount` giảm -1, wither animation plays (0.6s, subtle), không có xu hay energy credited — seed entry biến mất.

**AC-4 — Clamp at zero** `[LOGIC]` BLOCKING
**GIVEN** `seedCount = 0` và bố mẹ reject task (bug scenario),
**WHEN** decrement operation runs,
**THEN** `seedCount` clamps tại 0 — không trở thành âm, không crash.

**AC-5 — Offline submit sync** `[INTEGRATION]` BLOCKING
**GIVEN** bé offline và submit task,
**WHEN** app regains connection,
**THEN** task syncs lên Firestore, `seedCount` reflected correctly — seed entry đã hiển thị ngay cả khi offline (local cache).

**AC-6 — Multi-approve data-layer contract (KHÔNG assert animation timing — đó là AC của #19)** `[LOGIC]` BLOCKING
**GIVEN** bố mẹ approve 3 tasks cùng lúc (backlog),
**WHEN** bé mở app và stream updates arrive,
**THEN** `seedCount` giảm đúng 3, cả 3 seed entries bị remove khỏi `pendingTasksProvider`, xu/energy được credited đúng cho cả 3 task — animation playback (bloom timing, stagger) là trách nhiệm của Task Management UI (#19), verify ở #19's Acceptance Criteria, không re-test ở đây.

**AC-7 — Null title fallback** `[UI]`
**GIVEN** `taskTitle` là null hoặc empty string,
**WHEN** seed entry được tạo,
**THEN** UI hiển thị "Hạt giống bí ẩn" — không crash, không empty label.

**AC-8 — Drift recalculation** `[LOGIC]` BLOCKING
**GIVEN** `seedCount` drifts (seedCount = 5, actual pending = 3),
**WHEN** Parent Approval Cloud Function processes next approve,
**THEN** `seedCount` được recalculated và corrected to actual pending count (= 3, không phải chỉ decrement từ giá trị sai).

## Open Questions

- **Seed visual differentiation by category**: Có nên seeds có màu khác nhau theo category không? (study seed = xanh mint, chores seed = peach) Tạo thêm visual variety nhưng tăng art scope. Defer đến playtest feedback.
- **Seed cap**: Có nên giới hạn số seeds tối đa bé có thể có cùng lúc không? (ví dụ: max 10 seeds pending) Prevents extreme backlog nhưng thêm design tension. Defer đến Alpha.
- **Rejected seed UX**: Bé có được thông báo tên task nào bị reject không? Hiện tại wither animation là anonymous — bé có thể không biết cái nào bị từ chối. Cần input từ Parent Dashboard UX design.
- **Seed persistence across app sessions**: Seeds tồn tại vô thời hạn (derived from pending tasks) — không expire. Đúng không? Nếu bố mẹ quên approve 2 tuần, seeds vẫn ở đó. Xác nhận behavior này là intentional.
