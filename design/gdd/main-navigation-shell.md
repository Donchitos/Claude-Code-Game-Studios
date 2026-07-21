# Main Navigation Shell

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all 5 blocking + 6 moderate findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-06
> **Implements Pillar**: **Sửa 2026-07-06 (fix từ review-all-gdds — Design Theory Phase 3f)**: header trước đây trích dẫn "Pillar 3 — Trải Nghiệm Đơn Giản Cho Bé" — pillar này KHÔNG tồn tại trong `game-concept.md`. Pillar 3 thật là "Khoe Đẹp, Không Đánh Nhau" (anti-PvP/social), không liên quan gì đến navigation. GDD này là Foundation/Infrastructure system, không map trực tiếp vào 1 trong 5 pillar chính thức — nó hỗ trợ cấu trúc cho **Pillar 4** (Bố Mẹ Là Đồng Minh — giao diện bố mẹ phải nhanh/đơn giản cho routine 30 giây mỗi tối) và bảo vệ **Pillar 2** (trải nghiệm của bé không bị gián đoạn bởi công cụ của bố mẹ), nhưng không "implement" 1 pillar cụ thể theo nghĩa hẹp — giống cách `flutter-flame-state-bridge.md` (#5) tự nhận thẳng "không có player fantasy trực tiếp" thay vì gán 1 pillar giả.

> **Correction (2026-07-14 — HUD spec cross-reference check, `design/ux/hud.md`)**: mọi tham chiếu "Child app bar" trong GDD này đã được sửa thành "floating chip cluster" (Profile chip + Xu chip top-left, Contextual badge chip top-right) — HUD spec chọn layout floating-pill (Option A, không có thanh app-bar liên tục) thay vì 1 `AppBar` widget như bản gốc giả định. Hành vi/data contract (Rule 5/6, xuBalance contract, long-press gesture, AC-6/7/8) **không đổi** — chỉ đổi widget/rendering ownership: HUD spec sở hữu visual/animation spec của Xu chip + Contextual badge chip; GDD này vẫn sở hữu Profile chip's long-press-to-parent-override interaction logic.

> **Correction (2026-07-18 — ADR-0014 authoring, GDD Sync Check)**: mọi tham chiếu `/child-selector` trong GDD này đã sửa thành `/select-child` — route path thật sự đã được code hóa trong Auth & Account epic (đã Complete) dùng `AppRoutes.selectChild = '/select-child'`, khác với path GDD gốc giả định. Phát hiện lần đầu khi implement Parent Dashboard UI's Story 001 (`/dev-story`, 2026-07-18), sau đó lan truyền sửa sang `design/ux/main-navigation-shell.md`, `design/ux/parent-dashboard-ui.md`, và ADR-0014. Hành vi/route logic không đổi — chỉ đổi path string.

## Overview

Main Navigation Shell là Flutter widget bao bọc toàn bộ app — nó đọc session state từ Auth & Account và render đúng UI tree cho từng actor.

**Infrastructure layer**: Shell là `GoRouter` với 2 nhánh route riêng biệt: nhánh **Child** (bottom navigation bar: Pet Room / Tasks / Shop) và nhánh **Parent** (bottom navigation bar: Dashboard / Family Settings). Auth guard tự động redirect về Login nếu `unauthenticated`, về Child Selector nếu `parent_authed` nhưng chưa chọn bé.

**Player-facing layer**: Bé thấy 3 tab đơn giản với icon to, rõ ràng — không chữ nếu có thể, hoặc chữ tối giản. Bố mẹ thấy giao diện riêng với tone khác (chuyên nghiệp hơn, ít màu sắc hơn). Hai thế giới không bao giờ trộn lẫn: shell đảm bảo bé không thể accidentally vào Parent Dashboard, và bố mẹ không nhìn thấy game của con.

MVP scope: 2 navigation trees (Child / Parent), route guard theo session state, `xuBalance` display trong floating chip cluster (HUD spec, `design/ux/hud.md` — **sửa 2026-07-14**: không phải `AppBar` widget nữa, xem Rule 5 note), back-button behavior per screen.

## Player Fantasy

**Bé (6–10 tuổi)**: Mở app, gõ PIN → màn hình Mochi hiện ra ngay. Dưới màn hình là 3 icon to: 🏠 nhà (Pet Room), ⚡ nhiệm vụ (Tasks), 🛍️ shop. Không cần đọc chữ. Không cần hướng dẫn. Bé 6 tuổi biết nhấn vào cái nhà để về phòng Mochi.

**Cảm xúc mục tiêu cho bé**: *"Đây là thế giới của mình — mình biết đi đâu."*

**Bố mẹ**: Mở app, login → thấy ngay Dashboard với danh sách task đang chờ duyệt. Không phải game, không phải màu sắc rực rỡ — một giao diện rõ ràng, đủ tin cậy để bố mẹ dùng 30 giây trước khi ngủ để approve task cho con.

**Cảm xúc mục tiêu cho bố mẹ**: *"Đơn giản. Tôi biết mình cần làm gì."*

Shell phân tách hai trải nghiệm này hoàn toàn. Bé không bị distract bởi controls của bố mẹ. Bố mẹ không bị confused bởi game của con. Mỗi người thấy đúng thứ họ cần.

## Detailed Design

### Core Rules

1. Shell là `GoRouter` root widget — wrap toàn bộ app. Mọi navigation ĐỊA CHỈ ĐƯỢC (addressable, deep-linkable) đều qua GoRouter; không dùng `Navigator.push` trực tiếp cho những route này. **Ngoại lệ đã xác nhận (2026-07-06, reconcile với #20)**: full-screen ephemeral overlay/ceremony KHÔNG cần deep-link (ví dụ Shop & Reward UI #20's Chest Open ceremony) ĐƯỢC PHÉP dùng `Navigator.push`. Core Rule này chỉ áp dụng cho navigation giữa các SCREEN thật (có route path riêng).
   - **Sửa 2026-07-06 (fix Scenario 3 blocker từ review-all-gdds)**: nếu overlay đó là **non-dismissible** (ví dụ #20's ceremony trong Phase 1-3), PHẢI dùng **ROOT navigator** (`Navigator.of(context, rootNavigator: true).push(...)`), KHÔNG phải branch-scoped Navigator — vì bottom nav bar sống ở tầng Scaffold, NGOÀI branch Navigator; push branch-scoped để lại bottom nav vẫn visible/tappable phía trên overlay, cho phép bé tap sang tab khác giữa lúc ceremony đang "non-dismissible" — mâu thuẫn trực tiếp với chính thiết kế đó. Root-navigator push che luôn bottom nav, chặn hoàn toàn tab-switch trong lúc overlay còn mở.
2. Shell đọc `sessionStateProvider` (từ Auth & Account #1 — provider derive, KHÔNG PHẢI `authStateProvider` thô) mỗi khi rebuild. Route guard redirect tự động:
   - `unauthenticated` → `/login`
   - `parentAuthed` (chưa chọn bé) → `/select-child`
   - `childSelected` → `/child/pet-room` (default tab)
   - `parentView` (bố mẹ override từ trong child session — xem #1's Core Rule 5): `/parent/dashboard`, KHÔNG dispose child session bên dưới
3. **Child navigation tree** (3 tabs, bottom nav bar):
   - Tab 1: 🏠 "Nhà" → `/child/pet-room`
   - Tab 2: ⚡ "Nhiệm vụ" → `/child/tasks`
   - Tab 3: 🛍️ "Shop" → `/child/shop`
4. **Parent navigation tree** (2 tabs, bottom nav bar):
   - Tab 1: 📋 "Nhiệm vụ" → `/parent/dashboard`
   - Tab 2: 👨‍👩‍👧 "Gia đình" → `/parent/family`
5. **Sửa 2026-07-14 (reconcile với HUD spec `design/ux/hud.md`)**: Child screen hiển thị 3 floating chip độc lập — không phải 1 `AppBar` widget. Chip cluster top-left: **Profile chip** (avatar bé + tên bé, sở hữu bởi #17 — Rule 6) đặt cạnh **Xu chip** (icon xu + `xuBalance`, sở hữu bởi Currency System #7's data, rendering bởi HUD spec). Top-right riêng biệt: Contextual badge chip (Seed/Chest — HUD spec sở hữu, xem #10/#12). Cả 3 chip là các floating pill độc lập (Round-Over-Sharp, Art Bible §3), KHÔNG fuse thành 1 thanh liên tục — xem `design/ux/hud.md` Layout Zones cho spec đầy đủ.
6. **Switch to parent mode (Parent Override)**: Long-press vào **Profile chip** (avatar bé, top-left floating chip — không còn là "app bar" theo Rule 5's sửa) → bottom sheet xác nhận "Chuyển sang tài khoản bố/mẹ?" → [Xác nhận] → yêu cầu parent password → set `parentOverrideProvider = true` (Auth #1) → navigate về `/parent/dashboard`. Child session KHÔNG bị logout/dispose.
7. **Switch to child mode (thoát Parent Override)**: Từ Parent Dashboard (khi `sessionState == parentView`) → tap "Xong"/"Quay lại" → set `parentOverrideProvider = false` → navigate thẳng về `/child/pet-room`, KHÔNG qua `/select-child`, KHÔNG cần bé gõ lại PIN (theo Auth #1's States/Transitions: `parent_view` → `done` → `child_selected` trực tiếp, session vẫn nguyên — sửa lỗi so với bản trước yêu cầu re-PIN, mâu thuẫn với #1's diagram).
8. Back button behavior: **Child tab root screens** (Pet Room, Tasks, Shop) → dialog "Thoát PetQuest?" theo Edge Cases (kid-styled). **Parent tab root screens** (Dashboard, Gia đình) → back button EXIT APP TRỰC TIẾP, không hiện dialog kid-styled ("Thoát PetQuest?" không phù hợp tone người lớn) — nếu `sessionState == parentView` (override từ child session), back button thay vào đó QUAY VỀ child session (`parentOverrideProvider = false` → `/child/pet-room`) thay vì exit app, vì app vẫn đang chạy dưới danh nghĩa bé. Sub-screens (cả 2 bên) → back về tab root.

### States and Transitions

**Lưu ý (sửa 2026-07-06)**: Dùng đúng 4 tên `SessionState` từ Auth & Account (#1)'s `sessionStateProvider` — bản trước dùng 3 tên khác nhau không nhất quán ("parent_dashboard", "Parent Dashboard active") cho cùng 1 khái niệm, và bỏ sót `parentView` hoàn toàn.

| Session State | Route shown | Nav bar |
|---------------|-------------|---------|
| `unauthenticated` | `/login` | Không có |
| `parentAuthed` | `/select-child` | Không có |
| `childSelected` | `/child/pet-room` (default) | Child bottom nav (3 tabs) |
| `parentView` | `/parent/dashboard` | Parent bottom nav (2 tabs) — child session vẫn sống bên dưới, không dispose |

### Route Map

```
/login
/select-child
/child/
  pet-room          ← Tab 1 (default)
  tasks             ← Tab 2
  tasks/new         ← Sub-screen
  shop              ← Tab 3
/parent/
  dashboard         ← Tab 1 (default)
  family            ← Tab 2
```

**Đã loại bỏ 3 entry orphaned (2026-07-06, tìm thấy khi review)**: `shop/item/:id` (Shop & Reward UI #20 không có item-detail route riêng — tương tác inline trong catalog grid qua bottom sheet của Shop System #13), `dashboard/task/:id` (Parent Dashboard UI #21 approve/reject inline trên card, không có task-detail sub-screen), `family/add-child` (Parent Dashboard UI #21 Core Rule 4 nói rõ "Add/remove child profile explicitly out of scope" — route cho tính năng bị exclude không nên tồn tại). Route Map trước đây được viết sớm (trước khi #19/#20/#21 thực sự được design) và chưa reconcile.

### Interactions with Other Systems

| System | Direction | Data |
|--------|-----------|------|
| Auth & Account (#1) | IN | `sessionStateProvider` → route guard decisions |
| Currency System (#7) | IN | `xuBalanceProvider` → display trong Xu chip (floating, HUD spec) |
| Pet Room Screen UI (#18) | OUT | Hosts `/child/pet-room` |
| Task Management UI (#19) | OUT | Hosts `/child/tasks` |
| Shop & Reward UI (#20) | OUT | Hosts `/child/shop` |
| Parent Dashboard UI (#21) | OUT | Hosts `/parent/dashboard` |

## Formulas

System này không có công thức toán học phức tạp. Contracts dưới đây là routing rules mà các system phụ thuộc vào — viết lại theo format variable-table (2026-07-06) để nhất quán với các GDD khác.

**Route guard contract:**

`route = f(sessionState, hasChildSelected)`

| Variable | Symbol | Type | Range | Mô tả |
|----------|--------|------|-------|-------|
| Session state | `sessionState` | `SessionState` enum | `{unauthenticated, parentAuthed, childSelected, parentView}` | Từ Auth & Account #1's `sessionStateProvider` — xem #1's Riverpod Provider Contract |
| Route đích | `route` | String (path) | 1 trong 5 giá trị bên dưới | Route GoRouter redirect tới |

```
if sessionState == unauthenticated → redirect("/login")
else if sessionState == parentAuthed → redirect("/select-child")
else if sessionState == childSelected → allow "/child/*", default "/child/pet-room"
else if sessionState == parentView → allow "/parent/*", default "/parent/dashboard"
```

**Worked example**: bé đang ở `/child/tasks` (sessionState = `childSelected`), Firebase token hết hạn giữa chừng → `authStateProvider` emit `null` → `sessionStateProvider` derive lại thành `unauthenticated` → route guard redirect ngay `/login`, bất kể route hiện tại là gì.

**xuBalance display contract:**
```
displayXu = xuBalanceProvider.value ?? 0
```
- Hiển thị `0` nếu provider chưa load xong — không hiển thị loading spinner trong Xu chip.
- Format: `"${displayXu} xu"` hoặc icon xu + số nguyên (không decimal).

**Tab persistence contract:**
- GoRouter `StatefulShellRoute` giữ tab state khi switch giữa các tab — Pet Room screen không rebuild khi bé switch sang Tasks rồi quay lại. Vì các branch KHÔNG bị dispose khi switch, `dispose()`/`RouteObserver` KHÔNG fire cho sibling-branch switch — screens cần detect "tôi không còn active" phải tự watch provider dưới đây, không dựa vào widget lifecycle.

**Active branch index provider** (mới — propagated từ Task Management UI #19's Edge Case 4, cần cho interrupt-detection):
```dart
final activeChildBranchIndexProvider = StateProvider<int>((ref) => 0);
// 0 = Pet Room, 1 = Tasks, 2 = Shop.
```
**Wiring (sửa mô tả sai — `StatefulShellRoute` KHÔNG có `onTap`)**: giá trị này được cập nhật bởi bottom-nav widget's `onTap` callback, gọi `StatefulNavigationShell.goBranch(index)` (API thật của `go_router`) VÀ ghi `activeChildBranchIndexProvider.state = index` cùng lúc — không phải `StatefulShellRoute` tự expose `onTap`. Bất kỳ screen nào cần biết "tôi còn active hay không" (ví dụ Task Management UI #19's staggered catch-up animation) watch provider này, so sánh với branch index của chính nó.

## Edge Cases

- **If `sessionStateProvider` emit `unauthenticated` trong khi bé đang ở `/child/tasks`** (token expired): GoRouter guard redirect ngay về `/login` — không flash màn hình, không data loss (task draft chưa submit bị mất; acceptable).
- **If bé back-press trên tab root screen** (Pet Room / Tasks / Shop): Android back button hiện dialog "Thoát PetQuest?" — [Thoát] exit app, [Ở lại] dismiss. iOS không có back gesture ở root.
- **If long-press avatar trigger khi bé đang ở sub-screen** (ví dụ `/child/tasks/new`): bottom sheet vẫn hiện — xác nhận switch mode sẽ discard sub-screen state. Bottom sheet warning: "Dữ liệu chưa lưu sẽ bị mất."
- **If `xuBalanceProvider` throw error**: hiển thị `"— xu"` trong Xu chip, không crash.
- **If bé navigate sang tab khác trong khi Flame game loop đang chạy** (Pet Room): Flame component vẫn mounted nhờ `StatefulShellRoute` — game loop không bị dispose. Khi bé quay lại, Pet Room resume ngay.
- **If parent password sai khi long-press switch**: bottom sheet hiện error inline "Mật khẩu không đúng" — không navigate, không logout.
- **If deep link vào `/child/shop/item/xyz` nhưng session là `unauthenticated`**: route guard redirect về `/login`, sau khi login thành công redirect về intended route (GoRouter `redirect` chain).
- **If 2 bé dùng app cùng lúc trên 2 thiết bị**: mỗi device có session độc lập — không conflict vì Firestore là source of truth.

## Dependencies

### Upstream Dependencies

| System | GDD | Interface cần |
|--------|-----|---------------|
| Auth & Account (#1) | `auth-account.md` ✅ | `sessionStateProvider` → route guard; `childId`, `parentId` cho scope |
| Currency System (#7) | `currency-system.md` ✅ | `xuBalanceProvider` → display trong Xu chip (floating, HUD spec) |

### Downstream Dependents

| System | GDD | Expects gì |
|--------|-----|------------|
| Pet Room Screen UI (#18) | Approved ✅ | Shell host `/child/pet-room`, `StatefulShellRoute` giữ Flame alive |
| Task Management UI (#19) | Approved ✅ | Shell host `/child/tasks` và `/child/tasks/new`; #17 sở hữu Seed Badge rendering trên tab icon (data từ Seed Buffer #10's `seedCountProvider`) — #19 không tự render badge này. #17 owns `activeChildBranchIndexProvider` (xem Core Rules) — #19's catch-up animation interrupt-detection (Edge Case 4) watch provider này. |
| Shop & Reward UI (#20) | Approved ✅ | Shell host `/child/shop` |
| Parent Dashboard UI (#21) | Approved ✅ | Shell host `/parent/dashboard` |

### Hard vs. Soft Dependencies

- **Hard**: Auth & Account — shell không thể route nếu không có session state.
- **Soft**: Currency System — `xuBalance` display là cosmetic; shell vẫn function nếu provider lỗi (hiển thị "—").

## Tuning Knobs

| Knob | Default | Min | Max | Hậu quả nếu quá thấp | Hậu quả nếu quá cao |
|------|---------|-----|-----|----------------------|---------------------|
| `long_press_duration` | 600ms | 400ms | 1000ms | Bé vô tình trigger switch mode | Khó trigger, bố mẹ frustrated |
| `switch_mode_confirm_timeout` | 0 (không auto-dismiss) | — | 10s | — | Bottom sheet lơ lửng mãi nếu bé bỏ điện thoại |
| `back_press_exit_confirm` | true | — | — | Bé bấm back nhiều lần không thoát được | Không áp dụng |
| `tab_animation_duration` | 200ms | 100ms | 400ms | Tab switch cảm giác snap | Sluggish, lag |

**Knob interactions**: Ban đầu cân nhắc `long_press_duration` > `tap_cooldown` của Pet Interaction (1000ms) để tránh trigger nhầm, nhưng đây là so sánh sai loại — long-press (gesture riêng, đo bằng thời gian giữ) và tap-cooldown (đo bằng thời gian GIỮA 2 tap) không cùng cơ chế, không cần ràng buộc lẫn nhau. `long_press_duration = 600ms` được giữ nguyên vì Flutter's `GestureDetector.onLongPress` tự phân biệt long-press với tap dựa trên duration+lack-of-movement, không dựa vào so sánh với cooldown của hệ thống khác.

## Visual/Audio Requirements

- Child bottom nav: icon size 28dp, label font size 11sp, active tab = accent color (Peach Glow `#FFCBA4`), inactive = grey `#9E9E9E`
- Profile chip (floating, top-left): avatar circle 32dp, tên bé font bold 16sp. Xu chip (floating, adjacent to Profile chip): icon xu 18dp + số 14sp Honey Gold `#FFD060` (Art Bible Section 4 canonical hex). Full visual/animation spec owned by `design/ux/hud.md`.
- Parent bottom nav: icon 24dp, label 12sp, màu tối hơn (Navy `#2C3E50`) — tone professional
- Tab switch animation: fade-through 200ms (Material 3 pattern)
- Switch mode bottom sheet: slide-up 250ms ease-out, overlay dim 40% opacity
- Audio: tab switch — subtle "tick" 0.1s (optional, off by default). Switch mode confirm — soft chime.

## UI Requirements

- Child shell: `Scaffold` với `bottomNavigationBar` (Material 3 `NavigationBar`) + floating chip cluster overlay (Profile chip, Xu chip, Contextual badge chip — **không phải `AppBar` widget**, sửa 2026-07-14 per `design/ux/hud.md`)
- Parent shell: `Scaffold` riêng với `NavigationBar` 2 tabs — không share widget với Child shell
- `StatefulShellRoute` từ `go_router` để giữ tab state
- Child Selector screen: full-screen, không có nav bar
- Login screen: full-screen, không có nav bar

📌 **UX Flag — Main Navigation Shell**: System này có UI requirements. Trong Phase 4 (Pre-Production), chạy `/ux-design` để tạo UX spec cho Child Shell, Parent Shell, Child Selector, và Login screen trước khi viết epics.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory.

- **AC-1** `[INTEGRATION]` BLOCKING — GIVEN app khởi động với session `unauthenticated`, THEN GoRouter redirect về `/login` — không flash bất kỳ screen nào khác.
- **AC-2** `[INTEGRATION]` BLOCKING — GIVEN bố mẹ login thành công, WHEN chưa chọn bé, THEN redirect về `/select-child` tự động.
- **AC-3** `[INTEGRATION]` BLOCKING — GIVEN bé gõ PIN đúng trên Child Selector, THEN redirect về `/child/pet-room` và Child bottom nav (3 tabs) hiển thị.
- **AC-4** `[UI]` — GIVEN bé ở `/child/pet-room`, WHEN tap tab "Nhiệm vụ", THEN navigate sang `/child/tasks` trong 200ms; tab "Nhà" không còn active.
- **AC-5** `[INTEGRATION]` BLOCKING — GIVEN bé ở `/child/tasks`, WHEN tap tab "Nhà" quay lại, THEN Pet Room screen resume ngay — không rebuild, Flame game loop vẫn running (silent-failure risk: nếu game loop bị dispose nhầm, không có triệu chứng UI rõ ràng ngoài animation bị reset).
- **AC-6** `[UI]` — GIVEN `xuBalanceProvider` có giá trị 75, THEN Xu chip (floating, top-left) hiển thị "75 xu" (hoặc icon + "75").
- **AC-7** `[INTEGRATION]` BLOCKING — GIVEN `xuBalanceProvider` throw error, THEN Xu chip hiển thị "— xu" — không crash.
- **AC-8** `[UI]` — GIVEN bé long-press avatar ≥ 600ms trên Profile chip (floating, top-left), THEN bottom sheet "Chuyển sang tài khoản bố/mẹ?" hiện ra.
- **AC-9** `[INTEGRATION]` BLOCKING — GIVEN bố mẹ nhập đúng password trong switch mode flow, THEN `parentOverrideProvider = true`, navigate về `/parent/dashboard`, Parent bottom nav (2 tabs) hiển thị, VÀ child session không bị logout (verify `activeChildProvider` vẫn giữ giá trị cũ).
- **AC-10** `[UI]` — GIVEN bé back-press trên Child tab root screen, THEN dialog "Thoát PetQuest?" hiện — [Ở lại] dismiss dialog, [Thoát] exit app.
- **AC-11** `[INTEGRATION]` BLOCKING — GIVEN session expire khi bé ở `/child/shop`, THEN GoRouter redirect về `/login` — không stuck ở `/child/shop`.
- **AC-12** `[UI]` — GIVEN bé ở `/child/tasks/new` (sub-screen), WHEN back-press, THEN navigate về `/child/tasks` — không về Pet Room.
- **AC-13** `[INTEGRATION]` BLOCKING — GIVEN `sessionState == parentView` (bố mẹ đang override), WHEN bố mẹ back-press trên `/parent/dashboard`, THEN quay về `/child/pet-room` (`parentOverrideProvider = false`) — KHÔNG exit app, KHÔNG hiện dialog "Thoát PetQuest?" kid-styled.
- **AC-14** `[INTEGRATION]` BLOCKING — GIVEN bố mẹ ở `/parent/dashboard` sau khi override, WHEN tap "Xong"/"Quay lại", THEN quay thẳng về `/child/pet-room` KHÔNG qua `/select-child`, bé KHÔNG cần nhập lại PIN — session vẫn nguyên.

## Open Questions

1. ~~**Notification badge trên tab** — Nếu có task pending approve, Parent Dashboard tab có hiển thị badge số không?~~ **Resolved 2026-07-04 (Parent Dashboard UI #21)**: KHÔNG có tab badge trong MVP — #21 chỉ dùng in-app FCM banner (Core Rule 6), không thêm badge count trên tab icon. Defer tab badge đến Alpha nếu playtest cho thấy banner-only không đủ rõ.
2. **Child Selector screen design** — Screen này có cần GDD riêng không, hay đủ để spec trong Auth & Account GDD? Tạm thời: spec trong Navigation Shell UX doc. Owner: UX Designer.
