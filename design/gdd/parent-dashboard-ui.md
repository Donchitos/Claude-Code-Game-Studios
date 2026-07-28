# Parent Dashboard UI

> **Status**: Approved ✅ — /design-review NEEDS REVISION 2026-07-04, all 6 findings resolved (real PIN-reset mechanism designed and added to Auth & Account #1; false bidirectional claim fixed; banner 3rd-message permutation resolved; targetChildId re-tagged BLOCKING; Main Nav Shell stale entry + Open Question fixed; #19-picker assumption flagged provisional)
> **Author**: User + Agents
> **Last Updated**: 2026-07-04
> **Implements Pillar**: Pillar 4 — Bố Mẹ Là Đồng Minh, Không Phải Cảnh Sát

## Overview

Parent Dashboard UI là màn hình duy nhất bố mẹ tương tác với trong toàn bộ PetQuest — nơi 4 hành động chính diễn ra: (1) xem và approve/reject pending tasks (giao diện cho Parent Approval #11), (2) tạo custom task mới cho gia đình (Task Library #8's "Thêm nhiệm vụ mới"), (3) reset PIN cho child profile khi bé quên (Auth & Account #1), và (4) nhận in-app banner khi push notification đến lúc app đang mở foreground (Push Notification #9). **Không có tab badge trong MVP** (resolved với Main Navigation Shell #17's Open Question — chỉ banner, xem Core Rule 6).

Về kiến trúc: đây là Flutter widget layer thuần túy (Material 3), không có Flame rendering — sống ở route `/parent/dashboard` do Main Navigation Shell (#17) host, tách biệt hoàn toàn với child session (Auth #1's acceptance criterion đã fix: mở dashboard không logout bé đang chơi).

Về player-facing: bố mẹ chủ động mở dashboard — không phải passive hay automatic. Đây LÀ nơi Pillar 4 sống hay chết: nếu dashboard chậm, rối, hay giống một "công cụ quản trị," toàn bộ cảm giác "đồng minh" mà Parent Approval (#11) đã thiết kế cẩn thận (nút tap nhanh, không cần xác nhận rườm rà) sẽ bị phá vỡ ngay tại UI layer — thiết kế tốt ở #11 không có nghĩa gì nếu UI ở đây làm nó cảm thấy chậm hoặc đáng sợ.

**Ngoài phạm vi**: Task History (xem lại task đã approve/reject trong quá khứ) — **resolved 2026-07-05, KHÔNG thuộc GDD này**. Task Library (#8) đã quyết định rõ từ trước: `taskHistoryProvider` explicitly dành cho Task Management UI (#19), provider đã implement sẵn. Task History là child-facing, không phải parent-facing oversight — xem #19.

## Player Fantasy

**Mở dashboard**: Bố mẹ đang nghỉ trưa, mở app, tap vào tab "Bố mẹ". Không cần nhớ đăng nhập riêng biệt phức tạp — chỉ một bước xác thực nhẹ (password, theo Auth #1), và màn hình hiện ra: gọn, chuyên nghiệp, ít màu sắc hơn thế giới của con. Đây không phải "vào game" — đây là "kiểm tra tình hình," giống việc check tin nhắn từ trường của con.

**Approve/Reject** (bề mặt đã có player fantasy riêng ở Parent Approval #11 — không lặp lại ở đây, chỉ nối tiếp): dashboard là nơi khoảnh khắc "gật đầu số hóa" đó thực sự xảy ra — nếu list load chậm, nút phản hồi trễ, hay giao diện rối, cảm giác "nhẹ nhàng, nhanh" mà #11 đã thiết kế sẽ chết ngay tại đây.

**Tạo custom task**: Bố mẹ nghĩ "Con nên đọc sách mỗi tối" — tap "Thêm nhiệm vụ mới", gõ tên, chọn category, xong. Đây là khoảnh khắc bố mẹ *chủ động định hình* trò chơi của con theo giá trị gia đình riêng — không phải điền form hành chính, mà là "dạy con qua game theo cách của mình."

**Reset PIN**: Bé quên PIN, mách bố mẹ. Bố mẹ mở dashboard, vài giây sau bé lại chơi được — không drama, không phải gọi support. Khoảnh khắc này nhỏ nhưng quan trọng: nó nói "bố mẹ luôn có thể giúp con quay lại," không phải "con bị khóa và phải chờ."

**Banner khi đang mở app**: Bố mẹ đang xem dashboard thì banner nhẹ hiện lên: "Bông vừa hoàn thành X" — không phải popup chặn màn hình, mà như một tin nhắn đến nhẹ nhàng giữa lúc đang làm việc khác trong app.

**Cảm xúc chung**: Đây là không gian "làm bố mẹ tốt mà không cần cố gắng nhiều" — mọi hành động ở đây phải nhanh hơn việc bố mẹ nghĩ "mình có nên làm không." Nếu dashboard tạo cảm giác như một công cụ quản lý nhân viên, Pillar 4 đã thất bại ngay tại đây, bất kể #11's logic có đúng đến đâu.

## Detailed Design

### Core Rules

1. **Screen structure**: This GDD owns the *content* of the 2 tabs Main Navigation Shell (#17) already defined — Tab 1 "📋 Nhiệm vụ" (`/parent/dashboard`) and Tab 2 "👨‍👩‍👧 Gia đình" (`/parent/family`). Tab chrome (icons, labels, switching mechanics, nav bar styling) stays owned by #17 — not redefined here.

2. **Nhiệm vụ tab — Pending list**: Renders `pendingTasksProvider` (Task Library #8) as a scrollable list, one card per pending task. Each card shows: child avatar + name (families can have up to 4 children — Auth #1 — so this is required, not decorative), category icon + label, task title, "submitted X phút/giờ trước", and 2 buttons implementing Parent Approval (#11)'s exact button state machine verbatim (disable-on-tap, offline pre-check via `connectivity_plus`, error-reenable with "thất bại — thử lại"). List is **uncapped** — Task Library's decision, matches "bố mẹ approve theo thứ tự muốn." This is unrelated to Seed Buffer (#10)'s "max 10 seeds displayed" knob, which caps a *different, child-facing* screen (Task Management UI #19) — stated explicitly so a future reader doesn't mistake this for a contradiction.

3. **Nhiệm vụ tab — Create custom task**: FAB "+" → bottom sheet with: child selector (only shown if family has >1 child — **if family has exactly 1 child, the selector is hidden and `targetChildId` auto-assigns to that child's ID at Save time**), title text field, category dropdown (exactly the 5 real categories — `study`/`arts`/`chores`/`sport`/`helping`; the `custom` tag is never manually selectable, it's Task Library's fallback-only tag). Save writes to a **new collection** `families/{parentId}/customTasks/{customTaskId}`: `{ title, categoryId, targetChildId, createdAt }` — a template only, no `status` field. This appears as an extra pickable option in the child's task list (Task Management UI #19) alongside the 5 built-in presets. **This collection doesn't exist yet in Task Library (#8) or Data Persistence (#4) — needs propagation after this GDD is written.**

4. **Gia đình tab**: Lists all child profiles in the family (max 4, Auth #1's cap) — avatar, name, one action: **"Reset PIN"** → dialog with: title "Đặt lại PIN cho [tên bé]", một PIN input field (4 số, giống PIN entry của bé ở Child Selection flow), nút [Xác nhận]/[Hủy]. Tap Xác nhận (chỉ enable khi đã nhập đủ 4 số) → gọi `resetChildPin(childId, newPin)` (Auth & Account #1 Core Rule 6 — mechanism được định nghĩa ở đó, GDD này chỉ cung cấp UI). **Add/remove child profile is explicitly out of scope** — that's Auth & Account's onboarding flow, not modified here.

5. **"Chọn bé" (switch to child mode)**: A persistent action in the Parent Shell's app bar, visible on both tabs — tapping it follows Main Navigation Shell (#17)'s Rule 7 exactly: navigate to `/child-selector`.

6. **In-app FCM banner (foreground)**: A Riverpod listener wired at the Parent Shell scaffold level (not per-tab) subscribes to `FirebaseMessaging.onMessage` (Push Notification #9). Maintains a local `unseenCount` (int, starts 0, resets only per Edge Case 5's tap/dismiss rule). On each message: `unseenCount += 1`; nếu chưa có banner nào hiện → show banner mới; **nếu banner đã đang hiện (kể cả banner coalesced) → banner đó LIVE-UPDATE text tại chỗ để phản ánh `unseenCount` mới** (không tạo banner thứ 2, không queue riêng) — text hiển thị "[Tên bé] vừa hoàn thành [task]" khi `unseenCount == 1`, "N nhiệm vụ mới đang chờ" khi `unseenCount >= 2`. Tapping nó navigates to the Nhiệm vụ tab if not already there.

7. **Notification-permission-declined reminder**: Nếu bố mẹ declined the permission request during onboarding, show a dismissible reminder banner once per app session on the Nhiệm vụ tab (per Push Notification #9's UI Requirements — this GDD is where that reminder actually renders). **Session = process lifetime (cold start → app termination)**. `AppLifecycleState.resumed` (returning from background) does **not** start a new session — if the reminder was already dismissed earlier in the same process lifetime, it stays dismissed.

### States and Transitions

```
Parent Shell (app bar: avatar switcher "Chọn bé" | persistent across both tabs)
      │
      ├── Tab: Nhiệm vụ (/parent/dashboard)
      │     ├── [default] pending list (pendingTasksProvider)
      │     │     ├── tap Approve/Reject → #11's transaction (button state machine)
      │     │     └── tap FAB "+" → bottom sheet: create custom task
      │     │           └── Save → write customTasks/{id} → sheet closes, snackbar "Đã thêm nhiệm vụ"
      │     └── [FCM banner, if onMessage fires] dismissible banner, tap → stays on this tab
      │
      └── Tab: Gia đình (/parent/family)
            └── child profile list
                  └── tap "Reset PIN" on a child row → confirm dialog → [Auth #1 PIN reset flow]

[Long-press avatar on Child shell] → password → Parent Shell (Nhiệm vụ tab, default)
[Tap "Chọn bé" in Parent Shell app bar] → /child-selector → PIN entry → Child shell
```

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Parent Approval (#11) | IN | Pending list, button state machine | `pendingTasksProvider`, `approveTask()`/`rejectTask()` |
| Task Library (#8) | IN/OUT | Reads 5 categories for dropdown; writes new `customTasks` collection | New interface — needs propagation |
| Auth & Account (#1) | IN/OUT | Reads child profile list (≤4); triggers PIN reset | Existing reset mechanism, called not redefined |
| Push Notification (#9) | IN | Foreground FCM messages | `FirebaseMessaging.onMessage` stream |
| Main Navigation Shell (#17) | IN | Hosts this content inside `/parent/dashboard` and `/parent/family`; owns tab chrome and "Chọn bé" route | `StatefulShellRoute` (go_router) |

## Formulas

Parent Dashboard UI không có mathematical formulas hay data invariant riêng — mọi numeric contract nó phụ thuộc vào đã được định nghĩa ở system sở hữu: button state machine & batch write (Parent Approval #11), `seedCount` invariant (Seed Buffer #10), FCM delivery latency (Push Notification #9). Section này không lặp lại các contract đó.

## Edge Cases

1. **Không có pending task nào**: Nhiệm vụ tab hiển thị empty state ("Chưa có nhiệm vụ nào chờ duyệt") + FAB "+" vẫn khả dụng để tạo custom task mới. Không phải lỗi, không phải trạng thái đặc biệt cần xử lý riêng.

2. **Tap Save khi title trống trong form tạo custom task**: Save button disabled cho đến khi title có ít nhất 1 ký tự non-whitespace. Không cho phép submit title trống — tránh tạo template rác trong `customTasks` collection.

3. **Tạo custom task trùng tên với template đã có**: Không dedup — cho phép trùng tên. Không exploitable (chỉ là picker option cho bé chọn, không tự cấp reward khi tạo — reward chỉ xảy ra khi bé thực sự làm và submit).

4. **FCM banner đến khi bất kỳ modal đang mở** (bottom sheet tạo custom task TRÊN Nhiệm vụ tab, HOẶC confirm dialog Reset PIN trên Gia đình tab — cả hai đều là modal barrier trên cùng Parent Shell scaffold mà banner render vào): Banner bị defer — không hiện chồng lên modal, không render dimmed/unreachable phía sau. Hiện ngay sau khi modal đóng (Save/Cancel/Xác nhận/Cancel), nếu vẫn chưa bị dismiss/thay thế bởi banner mới hơn.

5. **Nhiều FCM messages đến liên tiếp trong thời gian ngắn** (ví dụ: 3 bé submit task gần nhau): Không stack nhiều banner riêng lẻ — chỉ 1 banner hiện tại một thời điểm, coalesce thành "N nhiệm vụ mới đang chờ" nếu `unseenCount >= 2`. Tap vào banner → Nhiệm vụ tab (đã có sẵn theo Core Rules 6). **"Chưa được xem" reset CHỈ khi**: (a) bố mẹ tap vào banner, hoặc (b) bố mẹ manually swipe-dismiss banner. Đơn thuần Nhiệm vụ tab trở nên visible (không tap/dismiss banner) **KHÔNG** reset counter — giữ nhất quán với Tuning Knob đã quyết định ("FCM banner behavior: Manual dismiss chỉ, không auto-dismiss").

   **Trường hợp đã tự nêu ra nhưng cần resolve rõ**: nếu 2 messages đến trong lúc modal đang mở (banner bị defer, `unseenCount=2`), modal đóng → banner "2 nhiệm vụ mới đang chờ" hiện ra, rồi message thứ 3 đến TRƯỚC khi bố mẹ tap/dismiss banner đó → theo Core Rule 6, banner KHÔNG tạo bản thứ 2 — nó live-update tại chỗ thành "3 nhiệm vụ mới đang chờ" (`unseenCount=3`). Không có banner nào biến mất rồi xuất hiện lại — chỉ đổi text.

6. **Bố mẹ tap "Reset PIN" rồi Cancel trong confirm dialog**: Không có side effect — dialog đóng, PIN giữ nguyên, không gọi Auth #1's reset mechanism.

7. **PIN được reset khi bé đang có active session đang chơi**: Reset chỉ áp dụng cho lần login TIẾP THEO — không kick bé ra khỏi session hiện tại. Tránh gián đoạn đột ngột, giữ đúng tinh thần "bố mẹ là đồng minh" (không phải hành động trừng phạt tức thì).

8. **Custom task template's `targetChildId` trỏ tới child profile đã bị xóa** (ngoài phạm vi GDD này, nhưng có thể xảy ra): Template trở thành orphaned — không hiện trong picker của bé nào nữa (child không tồn tại), không crash. Cleanup không cần thiết trong MVP — dữ liệu rác nhỏ, không ảnh hưởng gameplay.

9. **Bố mẹ chuyển tab (Nhiệm vụ ↔ Gia đình) khi một Approve/Reject transaction đang chạy**: Transaction tiếp tục độc lập với UI navigation — không bị cancel. Khi bố mẹ quay lại Nhiệm vụ tab, `pendingTasksProvider` stream tự phản ánh kết quả đúng, bất kể đã điều hướng đi đâu trong lúc transaction đang xử lý.

## Dependencies

**Upstream (Parent Dashboard UI cần — hard dependencies):**
- **Parent Approval (#11)** ✅ Approved — `pendingTasksProvider`, `approveTask()`/`rejectTask()`, button state machine
- **Task Library (#8)** ✅ Approved — 5 category values cho dropdown; `customTasks` collection interface propagated vào #8's Core Rule 4 + Dependencies (done — xem #8)
- **Auth & Account (#1)** ✅ Approved — child profile list (≤4); **PIN reset mechanism không tồn tại trước GDD này** — đã thêm Core Rule 6 (`resetChildPin()`) vào #1 để đóng gap này (bản đầu của GDD này giả định sai rằng mechanism đã có sẵn — corrected sau independent review)
- **Push Notification (#9)** ✅ Approved — `FirebaseMessaging.onMessage` stream, permission-declined reminder copy
- **Main Navigation Shell (#17)** ✅ Designed — hosts `/parent/dashboard` và `/parent/family` routes, owns tab chrome, định nghĩa route "Chọn bé" mà GDD này trigger

**Downstream**: **Sửa lỗi (2026-07-06, tìm thấy khi review-all-gdds)** — claim "không có" là SAI. Task Management UI (#19) có hard dependency vào `customTasks` collection của GDD này (làm picker templates) — đã resolve trong #19's Open Questions ("Resolved 2026-07-05") nhưng chưa bao giờ propagate vào table này.

| System | Cần gì | Interface |
|--------|--------|-----------|
| Task Management UI (#19) | `customTasks` collection làm template picker options | `families/{parentId}/customTasks` (Firestore, xem Core Rule 4) |

**Bidirectional check (re-verified sau independent review)**: Parent Approval (#11), Task Library (#8), Push Notification (#9) đều đã reference "#21"/"Parent Dashboard" đúng cách. Main Navigation Shell (#17) reference đúng nhưng Downstream table của #17 vẫn ghi #21 là "Not Started" — stale, cần fix ở #17. **Auth & Account (#1) ban đầu KHÔNG reference #21 ở Dependencies table** (chỉ có 2 mention rời rạc trong Edge Cases/Core Rules, không tính) — đã fix, thêm #21 vào #1's Downstream dependents table (xem trên). `customTasks` collection (interface mới) đã propagate xong tới Task Library (#8) và Data Persistence (#4) — không còn pending.

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Custom task title max length | 50 ký tự | 30–100 | Bị cắt trên task card, tràn UI | Không đủ diễn đạt tên task rõ ràng | Cùng convention với Push Notification's title truncation (#9) |
| FCM banner behavior | Manual dismiss chỉ (không auto-dismiss) | N/A — decided in Core Rules | — | — | Không phải knob số — quyết định cố ý ở Core Rules 6; nếu sau này muốn auto-dismiss, cần revisit Core Rules, không chỉ chỉnh số |

**Không định nghĩa lại**: "Max child profiles per parent" thuộc Auth & Account (#1) Tuning Knobs (default 4, range 1–8) — Gia đình tab hiển thị theo giá trị đó, không tạo bản sao ở đây.

## Visual/Audio Requirements

**Tone inheritance**: Kế thừa trực tiếp tone "professional, calm, trustworthy" đã thiết lập ở Main Navigation Shell (#17) — Navy `#2C3E50` (nav), Lavender Soft `#C5A3E0` (accent, theo Art Bible Section 4 "Parent zone" semantic + Section 2 "Parent Approval view" mood row: "Calm authority, trustworthy... Low, deliberate"). Không dùng palette trẻ em (Peach Glow, Petal Pink, Honey Gold) cho bất kỳ feedback nào ở đây — các màu đó signal "reward/celebration" ở child side, dùng sai chỗ sẽ làm hành động hành chính của bố mẹ trông giống một phần thưởng.

**Shape language (giữ nguyên, không tách biệt)**: Corner radius ≥12dp (buttons), 12–20dp (cards/panels/sheet) — theo Art Bible Section 3 UI Shape Grammar, áp dụng cho task card, bottom sheet, dialog Reset PIN, banner. Đây là điểm Parent Dashboard KHÔNG lệch khỏi Art Bible: bo góc là ngôn ngữ "tactile trust" chung toàn game, giữ nó tránh tạo "second visual language" (Section 3 cấm rõ điều này).

1. **Task card approve/reject**: Sau khi #11's transaction resolve thành công — flash 150ms (Approve: Mint Breeze `#A8E6CF` 20% overlay; Reject: neutral peach-grey, KHÔNG dùng đỏ), kèm icon ✓/✕ (colorblind safety, Section 4) → collapse (height→0 + fade) 200ms ease-out, list re-flow. Không particle/sparkle/confetti — vocabulary đó reserved cho Mochi celebration (P3).

2. **Custom task creation confirmation**: Sheet dismiss (200ms ease-in, reverse của slide-up mở sheet) → Material 3 SnackBar "Đã thêm nhiệm vụ", 3s auto-dismiss, leading checkmark icon màu Lavender Soft. Không dùng Honey Gold hay bất kỳ "reward" visual — tạo task không phải phần thưởng.

3. **Bottom sheet open/close (tạo custom task)**: Reuse verbatim motion spec của #17 cho parent-side bottom sheet — slide-up 250ms ease-out, scrim dim 40%. Không tạo motion spec riêng.

4. **FCM banner appear/dismiss**: MaterialBanner slide-down + fade-in 200ms, background Cloud White `#FFFFFF`, leading icon/accent bar Lavender Soft `#C5A3E0`. Dismiss (swipe hoặc tap) fade-out 150ms — không auto-dismiss (Tuning Knob đã quyết định). Banner coalesced ("N nhiệm vụ mới đang chờ") dùng CÙNG visual treatment với banner đơn — không escalate màu/size theo N, tránh cảm giác "cảnh báo dồn dập" (Pillar 4).

5. **Reset PIN confirm dialog**: `AlertDialog` Material 3 tiêu chuẩn, không cần custom art. Nút xác nhận dùng Lavender Soft accent — không đỏ, dù đây là action nhạy cảm (Section 4: never pure red/black in primary UI).

6. **Motion curve constraint (toàn màn hình)**: Chỉ dùng easing chuẩn Material (`easeInOut`/`easeOut`) — không elastic/bounce (đó là ngôn ngữ "expressive, playful" của P3, không thuộc parent-side).

7. **Audio**: Không thêm sound effect mới cho approve/reject hoặc banner. Giữ silent-by-default, nhất quán với #17 ("tab switch tick — off by default"). Nếu cần audio cue trong tương lai, reuse "soft chime" đã có ở #17, không tạo âm riêng.

**Loading state**: Pending list lúc initial load dùng skeleton/shimmer placeholder (subtle grey bars) — không dùng loading spinner có character/animation.

**Ghi chú Art Bible (for record, không blocking)**: Section 1's "mọi thứ phải trông như muốn được ôm" đọc literal có thể hiểu là áp dụng toàn game, nhưng Section 2's Mood table đã pre-authorize "Parent Approval view" khác biệt, và #17 đã set precedent (Navy, ít màu) từ trước. Quy tắc áp dụng ở đây: **geometry (bo góc) giữ chung toàn game; palette + motion energy phân nhánh theo actor**. Nên chính thức hóa quy tắc này khi Art Bible Section 7 (UI/HUD Visual Direction) được viết.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:parent-dashboard-ui` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## UI Requirements

Parent Dashboard UI đóng góp 5 screens/surfaces trong Parent Shell:
1. **Nhiệm vụ tab** (`/parent/dashboard`) — pending list + FAB "+"
2. **Create custom task bottom sheet** — child selector (conditional), title field, category dropdown
3. **Gia đình tab** (`/parent/family`) — child profile list
4. **Reset PIN dialog** (title + 4-digit PIN input field, không phải chỉ confirm) — per child row
5. **FCM foreground banner** — global overlay, Parent Shell scaffold level (không tab-specific)

Tất cả 5 surfaces render trong Parent Shell mà Main Navigation Shell (#17) đã host — GDD này không tạo route mới nào ngoài 2 route đã có (`/parent/dashboard`, `/parent/family`).

📌 **UX Flag — Parent Dashboard UI**: 5 surfaces này cần `/ux-design` spec trước khi viết epics — đặc biệt: (1) button state machine reuse từ #11 phải render đúng theo #11's spec (không tự sáng tạo state mới), (2) banner defer/coalesce logic (Core Rule 6, Edge Cases 4-5) cần wireframe rõ ràng trước khi implement vì đây là phần `[LOGIC]`-tier duy nhất của GDD, (3) child selector conditional-visibility (Core Rule 3) cần test trên cả 2 trường hợp gia đình (1 con, nhiều con) khi thiết kế layout.

## Acceptance Criteria

**Test tier note**: This GDD is predominantly **UI-type** (advisory gate — manual walkthrough or interaction test) per `.claude/docs/coding-standards.md`'s Story Type table. Two slices need the stricter BLOCKING tier: (1) **Logic-type** (automated unit test in `tests/unit/parent-dashboard-ui/`) — the FCM banner defer-queue + unseen-counter mechanism (Core Rule 6 + Edge Cases 4/5), a small state machine with input-dependent branching, same category as Parent Approval (#11)'s button state machine. The specific permutation this requires (2 messages arrive while a modal is open, banner shows "2 đang chờ," then a 3rd arrives before dismiss) is now resolved in Core Rule 6/Edge Case 5 — banner live-updates in place, never spawns a second banner. (2) **Logic/Integration-type** — `targetChildId` auto-assignment in Core Rule 3 (single-child families): a wrong ID silently corrupts data with zero observable UI symptom, so it needs a real read-back check, not a visual walkthrough. Criteria below are tagged accordingly.

**Core Rule 1 — Screen structure** `[UI]`
- **GIVEN** bố mẹ đã xác thực, **WHEN** họ ở `/parent/dashboard`, **THEN** nội dung hiển thị đúng "Nhiệm vụ" tab (pending list + FAB) — tab chrome (icon/label/switching) không kiểm ở đây, chỉ nội dung.
- **GIVEN** bố mẹ ở `/parent/family`, **THEN** nội dung hiển thị đúng child profile list — không lẫn nội dung 2 tab.

**Core Rule 2 — Pending list** `[UI]`
- **GIVEN** `pendingTasksProvider` trả về N pending tasks (test N=1 và N=15+), **WHEN** Nhiệm vụ tab mở, **THEN** đúng N card hiển thị, không pagination/cap, mỗi card có avatar+tên bé, category icon+label, task title, "submitted X phút/giờ trước", và 2 nút Approve/Reject.
- **GIVEN** family có nhiều hơn 1 bé, **WHEN** 2 bé cùng có pending task, **THEN** mỗi card hiển thị avatar+tên đúng bé tương ứng — không nhầm bé.
- **GIVEN** thiết bị offline, **WHEN** tap Approve, **THEN** offline pre-check (`connectivity_plus`) chặn trước khi gọi `approveTask()` — hành vi nút cụ thể (disable/re-enable/error text) là AC của #11, ở đây chỉ verify wiring đúng.

**Core Rule 3 — Create custom task** `[UI]` (form rendering/validation) + `[LOGIC]` (targetChildId assignment, tagged riêng — xem bullet cuối)
- **GIVEN** family có đúng 1 bé, **WHEN** bottom sheet tạo task mở, **THEN** child selector KHÔNG hiển thị. `[UI]`
- **GIVEN** family có ≥2 bé, **WHEN** bottom sheet mở, **THEN** child selector hiển thị đầy đủ tất cả bé trong gia đình. `[UI]`
- **GIVEN** category dropdown mở, **THEN** đúng 5 giá trị hiển thị (`study`/`arts`/`chores`/`sport`/`helping`), tag `custom` KHÔNG xuất hiện như option chọn được. `[UI]`
- **GIVEN** title field trống hoặc chỉ whitespace, **THEN** nút Save disabled (Edge Case 2). `[UI]`
- **GIVEN** title, category, child đã chọn hợp lệ, **WHEN** tap Save, **THEN** document mới tạo tại `families/{parentId}/customTasks/{customTaskId}` với đúng 4 field `{title, categoryId, targetChildId, createdAt}`, không có field `status`, sheet đóng, snackbar "Đã thêm nhiệm vụ" hiển thị. `[UI]`
- **GIVEN** family có đúng 1 bé, **WHEN** Save được gọi, **THEN** `targetChildId` được ghi đúng bằng ID của bé duy nhất đó — verify bằng cách đọc lại document sau khi ghi, không chỉ quan sát UI (sai ID silently corrupt data mà không có triệu chứng UI nào quan sát được). `[LOGIC/INTEGRATION]` — BLOCKING, cần automated integration test trong `tests/integration/parent-dashboard-ui/`, không phải chỉ manual walkthrough.

**Core Rule 4 — Gia đình tab** `[UI]`
- **GIVEN** family có N bé (1 ≤ N ≤ 4), **WHEN** Gia đình tab mở, **THEN** đúng N row hiển thị với avatar+tên.
- **GIVEN** tap "Reset PIN" trên row của bé X, **THEN** dialog hiện đúng title "Đặt lại PIN cho [tên X]" kèm 1 PIN input field 4 số.
- **GIVEN** PIN input chưa đủ 4 số, **THEN** nút Xác nhận disabled.
- **GIVEN** đã nhập đủ 4 số, **WHEN** tap Xác nhận, **THEN** `resetChildPin(childId, newPin)` (Auth #1 Core Rule 6) được gọi với đúng `childId` của bé X và `newPin` đúng giá trị đã nhập — không phải bé khác trong list.

**Core Rule 5 — "Chọn bé"** `[UI]`
- **GIVEN** bố mẹ ở Nhiệm vụ HOẶC Gia đình tab, **THEN** app bar luôn hiển thị action "Chọn bé".
- **GIVEN** tap "Chọn bé", **THEN** app navigate đúng `/child-selector` theo #17 Rule 7 (không redefine hành vi ở đây).

**Core Rule 6 — FCM banner (foreground)** `[LOGIC]`
- **GIVEN** app đang mở foreground (bất kỳ tab nào), **WHEN** `FirebaseMessaging.onMessage` fire, **THEN** MaterialBanner hiện ở top của tab đang hiển thị với text "[Tên bé] vừa hoàn thành [task]".
- **GIVEN** banner hiện trên Gia đình tab, **WHEN** tap banner, **THEN** navigate sang Nhiệm vụ tab.
- **GIVEN** banner hiện khi đã ở Nhiệm vụ tab, **WHEN** tap banner, **THEN** không navigate (no-op), banner dismiss.

**Core Rule 7 — Permission-declined reminder** `[UI]`
- **GIVEN** bố mẹ đã decline notification permission lúc onboarding, VÀ đây là session đầu (cold start) mở dashboard, **WHEN** Nhiệm vụ tab hiển thị, **THEN** reminder banner hiện đúng 1 lần trong session đó (session = process lifetime).
- **GIVEN** banner đã bị dismiss trong session hiện tại, **WHEN** bố mẹ chuyển tab đi rồi quay lại Nhiệm vụ tab (không kill app), **THEN** banner KHÔNG hiện lại.
- **GIVEN** app bị kill và mở lại (cold start mới), VÀ permission vẫn declined, **THEN** banner hiện lại 1 lần.

**Edge Case 1 — Empty pending list** `[UI]`
- **GIVEN** 0 pending task, **THEN** empty state text "Chưa có nhiệm vụ nào chờ duyệt" hiển thị, FAB "+" vẫn tap được.

**Edge Case 2 — Empty title on Save** `[UI]`
- **GIVEN** title trống/whitespace-only, **THEN** Save disabled; **GIVEN** ≥1 ký tự non-whitespace, **THEN** Save enabled.

**Edge Case 3 — Duplicate custom task title** `[UI]`
- **GIVEN** 2 custom task templates cùng title được tạo, **THEN** cả 2 đều tồn tại trong `customTasks`, không lỗi dedup.

**Edge Case 4 — Banner deferred during any modal** `[LOGIC]`
- **GIVEN** bất kỳ modal đang mở (bottom sheet tạo task HOẶC confirm dialog Reset PIN), **WHEN** FCM message đến, **THEN** banner KHÔNG hiện chồng lên; **WHEN** modal đóng, **THEN** banner hiện ngay sau đó nếu chưa bị thay bởi banner mới hơn.

**Edge Case 5 — Banner coalescing** `[LOGIC]`
- **GIVEN** ≥2 FCM messages đến mà chưa "được xem" (counter chỉ reset khi tap hoặc dismiss banner — KHÔNG reset chỉ vì tab được xem), **THEN** banner hiện coalesced "N nhiệm vụ mới đang chờ" thay vì N banner riêng; tap → Nhiệm vụ tab.
- **GIVEN** banner "2 nhiệm vụ mới đang chờ" đang hiện (`unseenCount=2`, chưa tap/dismiss), **WHEN** message thứ 3 đến, **THEN** banner live-update tại chỗ thành "3 nhiệm vụ mới đang chờ" (`unseenCount=3`) — KHÔNG có banner thứ 2 nào được tạo, KHÔNG có banner cũ biến mất rồi banner mới xuất hiện (không animation dismiss-then-show, chỉ đổi text).

**Edge Case 6 — Reset PIN cancel** `[UI]`
- **GIVEN** confirm dialog Reset PIN mở, **WHEN** tap Cancel, **THEN** dialog đóng, không gọi Auth #1's mechanism, PIN không đổi.

**Edge Case 7 — PIN reset during active child session** `[UI]`
- **GIVEN** bé đang có active session, **WHEN** bố mẹ reset PIN, **THEN** session hiện tại của bé KHÔNG bị kick; PIN mới chỉ áp dụng ở lần login tiếp theo.

**Edge Case 8 — Orphaned customTasks targetChildId** `[UI]` (advisory, ngoài phạm vi GDD này)
- **GIVEN** `customTasks` doc có `targetChildId` trỏ tới bé đã xóa, **THEN** doc không hiện ở picker nào, không crash app.

**Edge Case 9 — Tab switch during in-flight transaction** `[UI]`
- **GIVEN** Approve/Reject transaction đang chạy, **WHEN** bố mẹ chuyển tab đi rồi quay lại Nhiệm vụ tab sau khi transaction hoàn tất, **THEN** `pendingTasksProvider` phản ánh đúng kết quả (task đã biến mất khỏi pending list).

## Open Questions

- ~~**Task History ownership**~~ — **Resolved 2026-07-05**: thuộc Task Management UI (#19), không phải GDD này. Xem Overview.
- **"Đã xử lý bởi người khác" toast** (kế thừa từ Parent Approval #11's Open Question): khi race giữa 2 devices xảy ra (Edge Case 3 ở #11), người "thua" có cần thấy thông báo giải thích tại sao card biến mất không? Cần input từ `/ux-design`.
- **Reject reason** (kế thừa từ Seed Buffer #10 và Task Library #8's Open Questions tương tự): bé có được biết lý do bị reject không? Vẫn chưa quyết định ở bất kỳ GDD nào trong chuỗi Task Library → Seed Buffer → Parent Approval → Parent Dashboard UI — cần resolve ở `/ux-design` pass, không defer thêm nữa vì đây là GDD cuối cùng trong chuỗi đó.
- **Art Bible Section 7 formalization** (từ `art-director`'s review): quy tắc "geometry chung, palette/motion phân nhánh theo actor" nên được viết chính thức vào Art Bible khi Section 7 (UI/HUD Visual Direction) được author, để các GDD parent-facing tương lai không phải re-derive.
- ~~**customTasks collection propagation**~~ — **Done**: đã propagate tới Task Library (#8) và Data Persistence (#4).
- ~~**`customTasks` picker trong Task Management UI (#19) — PROVISIONAL**~~ — **Resolved 2026-07-05**: #19 đã được design và confirm chính xác assumption này (`customTasks` filtered bằng `targetChildId`, hiện như chip cùng nhóm với 5 built-in presets). Xem `design/gdd/task-management-ui.md` Core Rule 5.
