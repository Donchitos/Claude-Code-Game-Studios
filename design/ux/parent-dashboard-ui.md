# UX Spec: Parent Dashboard UI

> **Status**: Complete — `/ux-review` 2026-07-18: NEEDS REVISION (1 blocking + 4 advisory) → all 5 fixed inline → APPROVED
> **Author**: User + ux-designer
> **Last Updated**: 2026-07-18
> **Journey Phase(s)**: Unknown — no player-journey.md exists yet
> **Platform Target**: Mobile (iOS + Android), Touch only — from `technical-preferences.md` (added at `/ux-review` pass; not yet a convention in other existing specs)
> **Template**: UX Spec

---

## Purpose & Player Need

Bố mẹ mở Parent Dashboard để làm 1 trong 4 việc: xác nhận nhanh việc con vừa làm (approve/reject), thêm một nhiệm vụ mới phản ánh giá trị riêng của gia đình, giúp con quay lại chơi khi quên PIN, hoặc nhận biết ngay khi con vừa hoàn thành việc trong lúc đang mở app. Đây không phải "vào game" — đây là "kiểm tra tình hình," giống việc xem tin nhắn từ trường của con.

Nếu màn hình này không tồn tại hoặc khó dùng, toàn bộ chuỗi "nỗ lực thật → phần thưởng thật" (Pillar 1) mà Task Library → Seed Buffer → Parent Approval đã xây dựng cẩn thận sẽ chết ngay tại đây — logic transaction dù đúng đến đâu cũng vô nghĩa nếu bố mẹ không có cách nhanh, nhẹ nhàng để kích hoạt nó.

**"Bố mẹ đến màn hình này muốn ___"**: xác nhận nhanh những gì con đã làm — nhanh hơn cả việc bố mẹ tự hỏi "mình có nên làm không."

---

## Player Context on Arrival

Bố mẹ đến màn hình này qua 3 con đường: (1) đăng nhập trực tiếp (email/password, Auth #1) khi mở app lần đầu trong phiên, (2) long-press Profile chip từ một session của con đang active (Parent Override — xem qua rồi quay lại), hoặc (3) tap vào push notification (Push Notification #9's deep link) khi task được submit.

Ngay trước đó, bố mẹ có thể đang: làm việc khác ngoài app hoàn toàn (giờ nghỉ trưa, đang nấu cơm — theo GDD's Player Fantasy) và bị notification gọi vào, hoặc đang trong app dưới vai một actor khác (theo dõi con chơi) rồi chủ động chuyển sang.

Trạng thái cảm xúc giả định: **hiệu quả, không vội, không lo lắng** — đây là "kiểm tra tình hình" nhẹ nhàng như xem tin nhắn trường học, không phải một tác vụ có áp lực thời gian (khớp với Pillar 4 — không có đồng hồ đếm ngược nào ở đây, khác với Time & Decay #2's child-facing energy urgency). Luôn arrival tự nguyện — không bao giờ bị "thả" vào màn hình này mà không vừa thực hiện một hành động có chủ đích (login, override, hoặc tap notification).

---

## Navigation Position

Màn hình này sống tại: **[root GoRouter]** → **Parent Shell branch** (host bởi Main Navigation Shell #17) → **Tab Nhiệm vụ** (`/parent/dashboard`) hoặc **Tab Gia đình** (`/parent/family`).

Đây không phải một "top-level destination luôn reachable" theo nghĩa thông thường — nó chỉ hiện khi session state là `parentAuthed` hoặc `parentView` (override). Có thể đến từ nhiều nơi: Login screen (session mới), Profile chip long-press override (từ Child shell), hoặc push notification deep link (`petquest://parent/tasks/pending`) — cả 3 đều dẫn vào cùng Parent Shell, mặc định mở Tab Nhiệm vụ.

---

## Entry & Exit Points

| Entry Source | Trigger | Bố mẹ mang theo context gì |
|---|---|---|
| Login screen | Email/password đúng | Session mới, `parentAuthed` — không có gì đặc biệt, mặc định mở Tab Nhiệm vụ |
| Profile chip long-press (từ Child shell) | Password xác nhận trong bottom sheet | `parentView` (override) — **child session vẫn sống nguyên vẹn phía dưới**, không bị mất |
| Push notification tap | Deep link `petquest://parent/tasks/pending` | Nếu session `unauthenticated` → route qua auth guard trước; nếu đã có session → vào thẳng Tab Nhiệm vụ (không scope tới 1 task cụ thể — deep link mở cả pending list) |

| Exit Destination | Trigger | Ghi chú |
|---|---|---|
| App exit (OS) | Back-press ở tab root, KHÔNG trong override | Thoát trực tiếp, không confirm dialog (tone người lớn — theo Main Nav Shell) |
| Child session (Pet Room) | Back-press ở tab root **trong override**, HOẶC tap "Xong"/"Quay lại" | `parentOverrideProvider = false` — KHÔNG phải app exit, session con vẫn nguyên, không cần nhập lại PIN |
| `/select-child` | Tap "Chọn bé" trong app bar | Điều hướng sang (Core Rule 5), không phải "thoát" theo nghĩa terminate |

**Exit một chiều duy nhất** (kế thừa từ Main Nav Shell, không riêng của GDD này): token hết hạn giữa chừng có thể làm mất draft đang nhập dở (ví dụ: đang điền form tạo custom task hoặc nhập PIN reset) — đã được Main Nav Shell's GDD chấp nhận là harmless, không cần xử lý đặc biệt ở đây.

---

## Layout Specification

### Information Hierarchy

**Tab Nhiệm vụ** (ưu tiên cao nhất — đây là nơi Pillar 1 thành hiện thực):
- Phải thấy ngay: danh sách pending task cards (avatar+tên bé, icon+category, task title, "submitted X phút/giờ trước", 2 nút Approve/Reject)
- Phải thấy ngay: FAB "+" (luôn khả dụng, kể cả khi list rỗng)
- Theo ngữ cảnh: FCM banner (chỉ khi có message mới), reminder banner permission-declined (chỉ 1 lần/session)

**Tab Gia đình** (ưu tiên thấp hơn — hành động ít thường xuyên):
- Phải thấy ngay: danh sách child row (avatar+tên, action "Reset PIN")

**App bar** (persistent cả 2 tab, ưu tiên utility — không cạnh tranh với nội dung chính):
- "Chọn bé" action

**Bottom sheet tạo custom task** (khi mở):
- Phải thấy ngay: title field, category dropdown
- Theo ngữ cảnh: child selector (chỉ hiện nếu gia đình có >1 bé)

**Dialog Reset PIN** (khi mở):
- Phải thấy ngay: tên bé trong title, PIN input 4 số, nút Xác nhận/Hủy

**Xếp hạng tổng thể**: (1) Pending list + Approve/Reject — quan trọng nhất, (2) FCM banner — time-sensitive nhưng không được lấn át (Pillar 4, không escalate alarm), (3) FAB tạo task, (4) Gia đình tab / Reset PIN — ít thường xuyên hơn, (5) "Chọn bé" — utility, luôn có nhưng không nổi bật.

### Layout Zones

**Tab Nhiệm vụ**:
- **App bar** (top, persistent): title "Nhiệm vụ" + action "Chọn bé" (Core Rule 5)
- **Banner slot** (ngay dưới app bar, trong luồng scroll — không phải overlay nổi): 1 vị trí duy nhất, dùng chung cho FCM banner và reminder banner. FCM ưu tiên nếu cả hai đủ điều kiện hiện cùng lúc (banner conflict resolution, xem Open Questions/States).
- **Content area** (scrollable, chiếm phần còn lại): pending task list, hoặc empty state khi rỗng
- **FAB** (nổi, góc dưới-phải, đè lên content khi scroll): "+"

**Tab Gia đình**:
- **App bar** (top, persistent): title "Gia đình" + action "Chọn bé"
- **Content area** (scrollable): child row list

**Modal layers** (đè lên toàn bộ Parent Shell, cả 2 tab):
- Bottom sheet tạo custom task — slide lên từ dưới, chiếm phần dưới màn hình, scrim dim phần còn lại
- Dialog Reset PIN — `AlertDialog` giữa màn hình, scrim dim toàn bộ phía sau

**Banner conflict resolution** (gap found not covered by GDD, resolved during this UX pass): một banner slot duy nhất trên Tab Nhiệm vụ, dùng chung cho FCM banner (Core Rule 6) và reminder banner (Core Rule 7). Nếu FCM message đến trong lúc reminder đang hiện, FCM banner thay thế ngay — reminder coi như đã "được thấy" trong session đó, không hiện lại. Khớp tinh thần Pillar 4 (không chia màn hình thành nhiều cảnh báo chồng nhau).

### Component Inventory

| Zone | Component | Interactive? | Pattern Used |
|---|---|---|---|
| Tab Nhiệm vụ — app bar | Title + "Chọn bé" action | "Chọn bé" only | none (standard AppBar action) |
| Cả 2 tab — app bar *(thêm khi review chéo với main-navigation-shell.md)* | "Xong"/"Quay lại" button — **chỉ hiện khi `sessionState == parentView` (override)**, ẩn hoàn toàn khi parent đăng nhập trực tiếp | Tap → trả về `/child/pet-room`, session con nguyên vẹn, không re-PIN | Owned by Parent Dashboard (#21) per Main Navigation Shell's own spec — `main-navigation-shell.md` chỉ định nghĩa hành vi khi tap, KHÔNG định nghĩa vị trí/hình dạng nút; đây là gap được main-navigation-shell.md's /ux-review tìm ra và patch tại đây |
| Tab Nhiệm vụ — banner slot | FCM banner / reminder banner (shared) | Tap, swipe-dismiss | **P7** (Coalescing in-app banner) |
| Tab Nhiệm vụ — content | Pending task card: avatar+tên, category icon+label, title, "submitted X trước" | Display only (card itself) | none |
| Tab Nhiệm vụ — content | Approve button (per card) | Tap → write | **P1** (Single-flight guard) + **P8** (✓ icon, never color-alone) |
| Tab Nhiệm vụ — content | Reject button (per card) | Tap → write | **P1** + **P8** (✕ icon) |
| Tab Nhiệm vụ — content | Empty state | Display only | **P6** (Empty state) |
| Tab Nhiệm vụ — content | Initial-load skeleton | Display only | **P5** (Skeleton-shimmer) |
| Tab Nhiệm vụ — FAB | "+" button | Tap → mở bottom sheet | none (mở **P3**) |
| Bottom sheet tạo task | Toàn bộ sheet | — | **P3** (Inline bottom sheet) |
| Bottom sheet tạo task | Child selector (conditional, >1 con) | Chọn 1 giá trị | **P18** (Conditional selector — mới thêm vào library trong UX pass này) |
| Bottom sheet tạo task | Title text field | Nhập text | none (Material TextField chuẩn) |
| Bottom sheet tạo task | Category dropdown (5 giá trị) | Chọn 1 giá trị | none (Material Dropdown chuẩn) |
| Bottom sheet tạo task | Nút Save | Tap → write (`customTasks` doc) | **P1** (Single-flight guard) |
| Tab Gia đình — content | Child row (avatar+tên) | Display only | none |
| Tab Gia đình — content | "Reset PIN" action (per row) | Tap → mở dialog | none |
| Dialog Reset PIN | Title + PIN input 4 số | Nhập PIN | **P10** (PIN entry — dùng lại UI numpad/dot, dù đây là NHẬP PIN mới chứ không phải verify) |
| Dialog Reset PIN | Nút Xác nhận | Tap → write (`resetChildPin()`) | **P1** (Single-flight guard) |
| Dialog Reset PIN | Nút Hủy | Tap → đóng, không write | none |

**1 pattern mới đã thêm vào library**: **P18** — "Conditional selector" (hiện/ẩn theo số lượng con trong gia đình), thêm vào `design/ux/interaction-patterns.md` trong UX pass này.

### ASCII Wireframe

**Tab Nhiệm vụ** (banner đang hiện, 2 pending task):

```
┌─────────────────────────────────────┐
│ Nhiệm vụ                  [Chọn bé] │  ← App bar
├─────────────────────────────────────┤
│ 🔔 Bông vừa hoàn thành Quét nhà   ✕ │  ← Banner slot (P7, tap→no-op vì đã ở tab này)
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ 👤 Bông    🧹 Việc nhà        │   │
│ │ Quét nhà                      │   │  ← Pending task card
│ │ submitted 5 phút trước        │   │
│ │        [✕ Từ chối] [✓ Duyệt] │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 👤 Bi      📚 Học tập         │   │
│ │ Đọc sách 20 phút               │   │
│ │ submitted 1 giờ trước         │   │
│ │        [✕ Từ chối] [✓ Duyệt] │   │
│ └───────────────────────────────┘   │
│                                       │
│                              ┌─────┐ │
│                              │  +  │ │  ← FAB
│                              └─────┘ │
├─────────────────────────────────────┤
│   [📋 Nhiệm vụ]      [👨‍👩‍👧 Gia đình]  │  ← Bottom nav (owned by #17)
└─────────────────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | Nội dung thay đổi |
|---|---|---|
| Default (Nhiệm vụ) | Load bình thường, N pending task | Hiện N card, N≥1 |
| Empty (Nhiệm vụ) | 0 pending task | Empty state "Chưa có nhiệm vụ nào chờ duyệt" (Edge Case 1), FAB vẫn tap được |
| Empty (Gia đình) *(defensive, không phải GDD case chính)* | 0 child profile | GDD Core Rule 4 giả định `1 ≤ N ≤ 4` nên đây không phải trạng thái được thiết kế chính thức — nhưng vì hiện tại chưa có `createChildProfile()` write path nào trong codebase (gap đã flag riêng), thêm 1 empty state phòng thủ đơn giản ("Chưa có hồ sơ con nào") thay vì list rỗng im lặng hoặc lỗi, phòng khi trạng thái này thực sự xảy ra trước khi gap kia được đóng |
| Loading (cả 2 tab) | Initial fetch chưa resolve | Skeleton/shimmer placeholder (grey bars) — **P5** |
| Error (cả 2 tab) | `pendingTasksProvider`/child-list provider throw | *(gap, thêm ở UX pass này)* Inline error text "Không tải được danh sách — thử lại" + nút Thử lại, KHÔNG crash toàn màn hình — nhất quán với Xu chip's established "graceful degradation" pattern (Main Nav Shell) |
| Sheet — validation | Title trống/whitespace | Nút Save disabled (Edge Case 2) |
| Sheet — saving | Đang gọi write `customTasks` | Nút Save disabled, có thể hiện spinner nhỏ trong nút (P1) |
| Sheet — save error | Write thất bại | *(gap, thêm ở UX pass này)* Inline error "Không thêm được nhiệm vụ — thử lại", sheet KHÔNG tự đóng, Save re-enable — nhất quán với P1's "re-enable on failure" |
| Dialog Reset PIN — incomplete | PIN chưa đủ 4 số | Nút Xác nhận disabled |
| Dialog Reset PIN — saving | Đang gọi `resetChildPin()` | Nút Xác nhận disabled (P1) |
| Dialog Reset PIN — error | `resetChildPin()` throw | *(gap, thêm ở UX pass này)* Inline error "Đặt lại PIN thất bại — thử lại", dialog KHÔNG tự đóng, Xác nhận re-enable |
| Banner | FCM message / permission declined | Xem Layout Zones — 1 slot dùng chung, FCM ưu tiên |

---

## Interaction Map

Input context: Touch only (mobile, iOS+Android, no gamepad).

| Component | Action | Feedback ngay lập tức | Kết quả |
|---|---|---|---|
| Approve button | Tap | Disable ngay (P1) → flash Mint Breeze 20% + ✓ icon (150ms) → collapse card (200ms ease-out) | `approveTask()`, task biến mất khỏi list |
| Reject button | Tap | Disable ngay (P1) → flash neutral peach-grey + ✕ icon → collapse card | `rejectTask()` |
| FAB "+" | Tap | Sheet slide-up 250ms ease-out, scrim dim 40% | Mở bottom sheet tạo task |
| Child selector (sheet) | Tap chọn | Highlight lựa chọn | `targetChildId` set |
| Title field (sheet) | Nhập text | Save enable khi ≥1 ký tự non-whitespace | — |
| Category dropdown (sheet) | Tap chọn | Dropdown đóng, giá trị hiện | `categoryId` set |
| Save (sheet) | Tap | Disable (P1) → sheet dismiss 200ms ease-in + SnackBar "Đã thêm nhiệm vụ" 3s | Document mới trong `customTasks` |
| "Chọn bé" (app bar) | Tap | Điều hướng ngay | Navigate `/select-child` |
| "Xong"/"Quay lại" (app bar, chỉ khi `parentView`) | Tap | Điều hướng ngay, không animation đặc biệt | `parentOverrideProvider = false`, navigate `/child/pet-room`, session con nguyên vẹn (Main Navigation Shell #17's logic — nút này chỉ trigger, không tự implement) |
| "Reset PIN" (child row) | Tap | Dialog mở | Mở Reset PIN dialog |
| PIN input (dialog) | Nhập 4 số | Dot fill từng số (P10) | — |
| Xác nhận (dialog) | Tap | Disable (P1) → dialog đóng nếu thành công | `resetChildPin(childId, newPin)` |
| Hủy (dialog) | Tap | Dialog đóng ngay | Không side effect (Edge Case 6) |
| Banner | Tap | Banner dismiss | Navigate Nhiệm vụ tab nếu đang ở Gia đình; no-op nếu đã ở Nhiệm vụ |
| Banner | Swipe | Fade-out 150ms | `unseenCount` reset về 0, banner biến mất |

---

## Events Fired

| Hành động | Event phát ra | Payload | Ghi chú |
|---|---|---|---|
| Approve tap (sau khi transaction commit thành công) | `GameEvent(taskApproved)` luôn; `GameEvent(petLeveledUp)` nếu `result.leveledUp == true` | `taskApproved`: none; `petLeveledUp`: `newPetLevel` (int) | **Đây là nơi đầu tiên trong toàn app thực sự emit 2 event này** — theo ADR-0013 §2, `approveTask()` chỉ trả `ApproveResult?`, việc emit là trách nhiệm của `ConsumerWidget` này (`ref.listen`, ADR-0004 §3 adapter (a)). ⚠️ **Kích hoạt GameEventBus replay risk đã được flag ở Parent Approval epic's Known Risks** — implementer PHẢI đọc `production/epics/parent-approval/EPIC.md` trước khi viết story emit event này. |
| Reject tap | Không có `GameEvent` nào | — | Wither animation là UI-local, thuộc Task Management UI (#19) trên máy của bé — màn hình này (của bố mẹ) không tự render animation nào cho reject (GDD Core Rule 3) |
| Save (custom task) | Không bắt buộc theo GDD | — | Analytics event (nếu muốn) là optional, không thiết kế ở đây |
| Xác nhận Reset PIN | Không có `GameEvent` | — | Chỉ là data write qua Auth #1's mechanism |
| Banner tap | Không có `GameEvent` riêng | — | Chỉ là navigation (GoRouter), không phải game state event |

**Hành động ảnh hưởng persistent state cần chú ý đặc biệt**: Approve (nhiều field), Reject (seedCount), Save (customTasks doc mới), Reset PIN (credentials sub-doc) — cả 4 đã có transaction/write contract đầy đủ từ epic sở hữu (#11, #8, #1), UI này chỉ gọi đúng hàm, không tự phát minh write logic.

---

## Transitions & Animations

**Screen enter/exit**: Không định nghĩa riêng ở đây — thuộc Main Navigation Shell (#17): tab-switch fade-through 200ms, và toàn bộ Parent Shell enter/exit (login/override) đã thuộc phạm vi UX spec của #17.

**In-screen animations**:
- **Task card approve/reject**: flash 150ms (Approve: Mint Breeze `#A8E6CF` 20% overlay; Reject: neutral peach-grey, KHÔNG đỏ) kèm icon ✓/✕ → collapse (height→0 + fade) 200ms ease-out, list re-flow. Không particle/confetti.
- **Bottom sheet mở/đóng**: slide-up 250ms ease-out (mở), reverse 200ms ease-in (đóng) — reuse verbatim motion spec của #17, không tạo riêng.
- **Custom task confirmation**: sau sheet đóng → Material 3 SnackBar "Đã thêm nhiệm vụ", 3s auto-dismiss, leading checkmark Lavender Soft.
- **FCM banner**: slide-down + fade-in 200ms (hiện), fade-out 150ms (dismiss thủ công — KHÔNG auto-dismiss). Banner coalesced dùng cùng visual weight với banner đơn.
- **Reset PIN dialog**: `AlertDialog` chuẩn Material 3, không animation riêng.

**Motion curve constraint (toàn màn hình)**: Chỉ `easeInOut`/`easeOut` — không elastic/bounce (đó là ngôn ngữ P3 "expressive, playful", không thuộc parent-side theo Art Bible's actor-branching rule).

**Reduced-motion**: Chưa có yêu cầu cụ thể trong GDD cho màn hình này — flag ở Open Questions.

**Audio**: Không thêm sound effect mới — silent-by-default, nhất quán #17.

---

## Data Requirements

| Data | Source System | Read/Write | Notes |
|---|---|---|---|
| Pending task list | Task Library (#8) | Read | `pendingTasksProvider`, Firestore `snapshots()` stream — updates on any write to this family's `tasks` collection (create, approve, reject), uncapped |
| Approve/Reject action | Parent Approval (#11) | Write | `approveTask()`/`rejectTask()` |
| 5 category values | Task Library (#8) | Read | Static list cho dropdown |
| `customTasks` document | Task Library (#8) / Data Persistence (#4) | Write | Collection mới, đã propagate theo GDD's Dependencies |
| Child profile list (≤4) | Auth & Account (#1) | Read | Cho Gia đình tab + child selector trong sheet |
| Reset PIN action | Auth & Account (#1) | Write | `resetChildPin(childId, newPin)` |
| Foreground FCM stream | Push Notification (#9) | Read | `FirebaseMessaging.onMessage` |
| Permission-declined reminder copy | Push Notification (#9) | Read | Text nội dung reminder banner |
| Route hosting | Main Navigation Shell (#17) | N/A | Structural — `/parent/dashboard`, `/parent/family` đã tồn tại |

Không có concern kiến trúc nào cần flag — mọi write đều đi qua hàm đã có sẵn từ epic sở hữu (#11, #8, #1), UI này không tự sở hữu hay quản lý state nào.

---

## Accessibility

- **Touch target**: mọi nút (Approve/Reject/Save/Xác nhận/Hủy/FAB/Reset PIN action) tối thiểu 48×48dp (không áp dụng rule ≥80×80dp vì không có pet sprite ở màn hình này).
- **Color không phải tín hiệu duy nhất**: Approve/Reject dùng icon ✓/✕ kèm màu; không dùng đỏ/đen thuần cho bất kỳ action nào kể cả Reject/Reset PIN (Lavender Soft accent thay thế — đã trong GDD's Visual Requirements).
- **Text legibility**: body text ≥14sp, label ≥11sp, contrast WCAG AA 4.5:1 — kế thừa từ contrast audit đã chạy (2026-07-13), không cần audit riêng cho màn hình này.
- **No timing pressure**: không có đồng hồ đếm ngược nào ở màn hình này.
- **Motion**: các animation ở đây đều nhẹ (150-250ms flash/slide), KHÔNG thuộc nhóm "ceremony/celebration" cần reduced-motion variant riêng (khác Chest Open/level-up/Mochi bounce) — nhưng vẫn tôn trọng OS "Reduce Motion" nếu bật (giảm về cross-fade thay vì slide, áp dụng chung toàn app theo baseline).
- **Interaction robustness**: single-flight guard (P1) đã áp dụng cho mọi action ghi dữ liệu (Approve/Reject/Save/Xác nhận) — vừa là correctness fix vừa là accessibility requirement. Reset PIN đã có bước "confirm" qua chính PIN-entry field, khớp accessibility-requirements.md's item 7.
- **Screen reader**: Flutter widget chrome (buttons, list, dialog) kế thừa Flutter default semantics — không cần custom `Semantics` riêng cho MVP (màn hình này KHÔNG có Flame canvas, nên default semantics là đủ).

---

## Localization Considerations

Longest/layout-critical text: banner text ("N nhiệm vụ mới đang chờ" / "[Tên bé] vừa hoàn thành [task]") giới hạn 1-2 dòng trong `MaterialBanner`'s chiều cao cố định — text dài (tên bé dài, task title dài) cần truncate với ellipsis, không được đẩy banner cao lên chiếm quá nhiều màn hình. Task card title cũng cần truncate tương tự (custom task title đã giới hạn 50 ký tự per Tuning Knob, nhưng built-in task titles không giới hạn rõ — flag ở Open Questions).

Số liệu cần format theo locale: "submitted X phút/giờ trước" (relative time) — nếu sau này thêm ngôn ngữ khác ngoài tiếng Việt, cần dùng thư viện relative-time locale-aware, không hardcode chuỗi tiếng Việt.

Hiện tại app chỉ có tiếng Việt (chưa thấy kế hoạch đa ngôn ngữ chính thức trong tài liệu dự án) — mục này chủ yếu phòng ngừa cho tương lai, không phải yêu cầu MVP.

---

## Acceptance Criteria

- [ ] Tab Nhiệm vụ hiển thị pending list trong <500ms từ lúc tap tab; nếu load >200ms, hiện skeleton/shimmer (P5) thay vì màn trắng
- [ ] Tap "Chọn bé" từ bất kỳ tab nào điều hướng đúng tới `/select-child`
- [ ] Khi 0 pending task, empty state "Chưa có nhiệm vụ nào chờ duyệt" hiển thị, FAB vẫn tap được
- [ ] Mọi nút tương tác (Approve/Reject/Save/Xác nhận/FAB) có touch target ≥48×48dp; approve/reject có icon ✓/✕ đi kèm màu, không chỉ dựa vào màu
- [ ] Approve/Reject tuân theo single-flight guard (P1) — disable ngay khi tap, re-enable khi transaction resolve/fail, không double-grant
- [ ] Tạo custom task: child selector ẩn khi gia đình có đúng 1 con, hiện khi ≥2 con; Save tạo đúng document 4 field (`title`, `categoryId`, `targetChildId`, `createdAt`), không có field `status`
- [ ] **BLOCKING** (GDD Core Rule 3's own tagged requirement): GIVEN gia đình có đúng 1 bé, WHEN Save được gọi, THEN `targetChildId` trong document vừa ghi khớp đúng ID của bé đó — verify bằng cách đọc lại document sau khi ghi (không chỉ quan sát UI); sai ID silently corrupt data mà không có triệu chứng UI nào quan sát được, cần automated integration test trong `tests/integration/parent-dashboard-ui/`, không phải chỉ manual walkthrough
- [ ] Reset PIN: dialog hiện đúng tên bé trong title, Xác nhận disabled cho đến khi nhập đủ 4 số, gọi đúng `resetChildPin(childId, newPin)` với đúng `childId` của hàng vừa tap
- [ ] FCM banner: 2+ message coalesce thành "N nhiệm vụ mới đang chờ" tại chỗ (không tạo banner thứ 2); banner defer khi có modal đang mở, hiện lại sau khi modal đóng
- [ ] Banner conflict (quyết định mới của UX pass này): nếu reminder banner đang hiện và FCM message đến, FCM banner thay thế ngay tại cùng vị trí — không có 2 banner chồng nhau
- [ ] Chuyển tab (Nhiệm vụ ↔ Gia đình) trong lúc Approve/Reject transaction đang chạy không cancel transaction; `pendingTasksProvider` tự phản ánh đúng kết quả khi quay lại
- [ ] Task card, banner, và bottom sheet render đúng không bị cắt/overflow trên cả màn hình nhỏ (ví dụ iPhone SE, ~375dp width) và màn hình lớn (ví dụ tablet-size Android, ~600dp+ width)

---

## Open Questions

**Resolved trong UX pass này** (GDD yêu cầu quyết định dứt điểm, không defer thêm):

- **Reject reason — RESOLVED: Không hiển thị lý do.** Reject vẫn không cần nhập/hiển thị lý do cụ thể — bé chỉ thấy seed "tàn lụi" (Seed Buffer #10's animation), không biết lý do chi tiết. Giữ đúng tinh thần "đồng minh, không phải cảnh sát" (Pillar 4) và khớp với #11's chủ đích "không cần xác nhận rườm rà." Không cần sửa Reject's Interaction Map — không thêm field/step nào.
- **"Đã xử lý bởi người khác" toast — RESOLVED: Không hiển thị.** Khi 2-device race xảy ra (Edge Case 3, #11), card của người "thua" biến mất im lặng khỏi pending list — giống một lần list tự cập nhật bình thường, không có toast giải thích riêng. Race này cực hiếm (cửa sổ 150-439ms) — thêm toast cho trường hợp hiếm có thể gây rối hơn là giúp ích.

**Chưa resolved — mang sang bước sau**:

- **Player journey map chưa tồn tại** — thiết kế phần này chưa có player-journey.md để tham chiếu. Template có sẵn tại `.claude/docs/templates/player-journey.md`. Nên chạy sau khi spec này approved.
- **Built-in task title max length** chưa định nghĩa rõ (chỉ custom task có Tuning Knob 50 ký tự) — task title từ 5 category preset có giới hạn tự nhiên (do Task Library #8 định nghĩa sẵn), nhưng nếu Task Library sau này cho phép title tùy biến dài hơn, banner/card truncation cần verify lại. Không blocking cho epic này — flag cho `/create-stories` xem xét.
- **Reduced-motion cho các animation ở màn hình này** — không cần variant riêng (animation quá nhẹ so với ngưỡng "ceremony"), nhưng nên verify cross-fade fallback hoạt động đúng khi implement, không giả định.
- **Art Bible Section 7 formalization** (kế thừa từ GDD) — quy tắc "geometry chung, palette/motion phân nhánh theo actor" nên viết chính thức vào Art Bible khi Section 7 được author.
