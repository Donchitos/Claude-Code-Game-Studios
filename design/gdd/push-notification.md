# Push Notification System

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all 4 required findings fixed same day)
> **Author**: User + Agents
> **Last Updated**: 2026-07-01
> **Implements Pillar**: Pillar 4 — Bố Mẹ Là Đồng Minh (parent is instantly informed when bé acts)

## Overview

Push Notification System là module infrastructure chịu trách nhiệm gửi Firebase Cloud Messaging (FCM) notifications đến device của bố mẹ khi có sự kiện quan trọng xảy ra trong game. System này không có gameplay logic — nó là một **event router thuần túy**: nhận trigger từ game events, gọi Cloud Function, Cloud Function gửi FCM đến `fcmToken` của bố mẹ.

MVP scope: **1 trigger duy nhất** — khi bé submit task (status → `pending`), bố mẹ nhận được notification trên điện thoại: *"[Tên bé] vừa hoàn thành [tên task]. Hãy kiểm tra và approve nhé!"*

Kiến trúc: Firestore `onWrite` Cloud Function trigger (không cần client SDK gọi trực tiếp) → đọc `fcmToken` từ `families/{parentId}` → gửi FCM message qua Firebase Admin SDK. Token lifecycle (refresh, invalid token cleanup) được quản lý bởi Auth & Account GDD (#1).

## Player Fantasy

Bố mẹ không nghĩ đến "Push Notification System" — bố mẹ chỉ cảm thấy: điện thoại rung nhẹ lúc 4 giờ chiều, nhìn xuống thấy: *"Bông vừa hoàn thành Quét nhà. Hãy kiểm tra và approve nhé!"*

Khoảnh khắc đó không phải là thông báo kỹ thuật. Đó là **con đang gõ cửa và khoe với bố mẹ**: "Con đã làm xong rồi!" — và bố mẹ có thể gật đầu từ xa, dù đang ở công ty hay đang nấu cơm.

Không có notification = bố mẹ không biết con đã submit task = bố mẹ về nhà mới approve = bé đã tụt hứng từ 2 tiếng trước. Push Notification là sợi dây kết nối thời gian thực giữa effort của bé và sự ghi nhận của bố mẹ — Pillar 4 không tồn tại nếu không có nó.

## Detailed Design

### Core Rules

**1. Trigger Event (MVP)**

Một trigger duy nhất trong MVP: **task document created với `status: 'pending'`**

```
Firestore trigger (2nd-gen): onDocumentCreated
  Path: families/{parentId}/children/{childId}/tasks/{taskId}
  (create-only by definition — KHÔNG cần manual `before == null` guard. Sửa 2026-07-08, ADR-0010:
   bản cũ ghi onWrite + manual condition; dùng dedicated create trigger — onCreate ở 1st-gen,
   onDocumentCreated ở 2nd-gen — thì không cần guard. Task tạo mới với status 'pending' luôn hợp lệ
   vì reward Security Rule của ADR-0009 đã reject task sai tại write-time.)
```

**2. Cloud Function Architecture**

```
[Bé tap "Đã xong!"]
        │
        ▼
Firestore: tasks/{taskId} created (status: 'pending')
        │
        ▼
Cloud Function: onTaskSubmitted (Firestore onWrite trigger)
        │
        ├─ Đọc task.title, task.categoryId
        ├─ Đọc child.name từ families/{parentId}/children/{childId}
        ├─ Đọc families/{parentId}.fcmToken
        │
        ▼
Firebase Admin SDK: send FCM message
        │
        ├─ Success → log delivery
        └─ Failure (invalid token) → log warning, no retry
```

**3. Notification Payload**

```json
{
  "token": "[fcmToken]",
  "notification": {
    "title": "[childName] vừa hoàn thành nhiệm vụ! 🎉",
    "body": "[taskTitle] — Hãy kiểm tra và approve nhé!"
  },
  "data": {
    "type": "task_submitted",
    "taskId": "[taskId]",
    "childId": "[childId]",
    "deepLink": "petquest://parent/tasks/pending"
  },
  "android": { "priority": "high" },
  "apns": { "headers": { "apns-priority": "10" } }
}
```

**4. Device-side Grouping**

Không có server-side batching. Mỗi task submit = 1 FCM message. Android/iOS notification tray tự group các notifications cùng app — bố mẹ thấy một nhóm "PetQuest (3)" thay vì 3 notifications riêng lẻ. Zero extra logic phía Cloud Function.

**5. Permission Request**

Client app (bố mẹ) phải request notification permission khi setup account. Nếu từ chối: app vẫn hoạt động bình thường — bố mẹ chỉ không nhận được push, phải mở app thủ công để xem pending tasks. Không block onboarding.

**iOS-specific behavior (khác Android, cần xử lý riêng)**: `FirebaseMessaging.instance.requestPermission()` (Dart plugin method — `requestAuthorization` là native iOS symbol; code Flutter gọi `requestPermission()`) trên iOS chỉ hiện system dialog **đúng 1 lần cho mỗi lần install** — gọi lại lần 2 sẽ silently resolve theo status hiện tại, KHÔNG hiện lại dialog. Hệ quả: nếu bố mẹ từ chối lần đầu, "reminder" ở Parent Dashboard (#21) KHÔNG THỂ re-trigger permission dialog trên iOS — reminder phải deep-link sang Settings app (`UIApplication.openSettingsURLString`) thay vì gọi lại `requestPermission()`. Trước khi rẽ nhánh (re-prompt vs mở Settings), client PHẢI đọc `FirebaseMessaging.instance.getNotificationSettings().authorizationStatus` (enum `AuthorizationStatus`: authorized/denied/notDetermined/provisional — **sửa 2026-07-16, Push Notification Story 002**: bản cũ liệt kê thêm `ephemeral`, nhưng phiên bản `firebase_messaging_platform_interface` thực tế đã resolve (4.9.2) chỉ có 4 giá trị này, không có `ephemeral`) để biết dialog one-shot đã fire chưa. Android không có giới hạn này (có thể re-prompt). (`provisional` authorization — tier thông báo yên lặng không cần prompt — là lever tương lai nếu friction reminder cần giảm; không phải MVP.) #21's reminder UI phải phân biệt 2 platform behavior này khi implement — flagged ở đây vì Push Notification System sở hữu permission contract. Theo `game-concept.md`'s Technical Risk ("iOS notification permissions phức tạp → Test early trên TestFlight"): permission flow này PHẢI được test trên TestFlight thật trước khi coi là hoàn thành — simulator không phản ánh đúng iOS permission/APNs behavior.

**6. Token Management** *(delegated to Auth & Account #1)*

- Token lưu tại `families/{parentId}.fcmToken`
- Refresh tự động via `FirebaseMessaging.instance.onTokenRefresh` (Auth GDD owns this)
- Push Notification System chỉ đọc token — không ghi

---

### States and Transitions

Push Notification là stateless — không có states. Mỗi trigger là một fire-and-forget event.

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Auth & Account (#1) | → Push Notification | `fcmToken`, `parentId` | `families/{parentId}.fcmToken` (Firestore read) |
| Data Persistence (#4) | → Push Notification | task document `onWrite` | Firestore trigger |
| Task Library (#8) | → Push Notification | task submit event | Firestore `tasks/{taskId}` creation |
| Parent Approval (#11) | ← Push Notification | (future) approve → notify child | Not in MVP |

## Formulas

Push Notification System không có mathematical formulas. Thay vào đó, section này định nghĩa **delivery contract** mà các system khác phụ thuộc vào.

**Delivery Latency Contract:**

| Step | Expected latency | Worst case |
|------|-----------------|------------|
| Firestore write → Cloud Function trigger | <2 giây | <30 giây (cold start) |
| Cloud Function → FCM delivery | <5 giây | Platform-dependent (FCM SLA) |
| **End-to-end (task submit → bố mẹ thấy notification)** | **<10 giây** | **<60 giây** |

**Retry Policy:** Fire-and-forget cho FCM-level errors. Cloud Function gửi một lần — không retry nếu FCM trả về lỗi (ví dụ invalid token). Rationale: FCM invalid token errors cần được xử lý bằng cách update token (Auth GDD), không phải retry. Network-transient errors (function execution failure): retry KHÔNG tự động — 2nd-gen có option `retry: true`.

> ⚠️ **Sửa 2026-07-08 (ADR-0010)**: 2nd-gen `retry: true` **KHÔNG bounded theo số lần** — nó retry cùng 1 event với exponential backoff cho đến khi success HOẶC event vượt quá retry-age window (bound theo THỜI GIAN, không phải số attempt). **Không có knob "tối đa 3 lần"** ở API surface này (bản cũ ghi sai). Hệ quả: nếu handler fail có hệ thống, bố mẹ có thể nhận RẤT NHIỀU duplicate push trong 1 window dài, không phải "2-3 lần rung". **MVP ship với retry DISABLED** (safe default) — miss 1 notification khi transient failure là chấp nhận được (bố mẹ thấy task khi mở app). Nếu sau này bật `retry: true`, handler PHẢI thêm event-staleness guard (`if (Date.now() - Date.parse(event.time) > 60_000) return;`).

**Idempotency (chấp nhận trade-off cho MVP)**: Retry (nếu enable) có thể khiến function chạy lại trên cùng 1 document create event → duplicate FCM push cho cùng 1 task submit. Chấp nhận rủi ro này cho MVP thay vì thêm dedup-key infrastructure: (1) notification chỉ là thông báo tham khảo, không mutate data — bố mẹ tap 1 trong 2 duplicate notifications đều dẫn đến cùng `deepLink`; (2) approve action ở Parent Approval (#11) đã tự idempotent qua `runTransaction` (đã verify ở #11's review) — 2 lần tap không thể double-approve. Duplicate push, nếu xảy ra, chỉ là phiền nhẹ (2 lần rung điện thoại), không phải data bug. Không cần dedup key trong MVP.

**Rate limit:** Không có server-side rate limiting trong MVP. FCM platform limit: 1 message/device/second (ample for this use case).

## Edge Cases

- **Nếu `fcmToken` là null hoặc rỗng** (bố mẹ chưa grant permission hoặc token chưa được lưu): Cloud Function kiểm tra token trước khi gửi — nếu null/empty, log warning và exit silently. Task vẫn được tạo bình thường; bố mẹ chỉ không nhận được push.

- **Nếu FCM trả về `messaging/registration-token-not-registered`** (token cũ, app bị uninstall/reinstall): Cloud Function log warning. Không xóa token từ Firestore (Auth GDD owns cleanup via onTokenRefresh). Bố mẹ sẽ nhận được token mới tự động lần mở app tiếp theo.

- **Nếu Cloud Function cold start** (first invocation sau thời gian idle): latency có thể tăng lên ~30 giây. Acceptable — notification vẫn đến, chỉ chậm hơn. Không ảnh hưởng đến gameplay.

- **Nếu bé submit nhiều tasks nhanh** (ví dụ 5 tasks trong 2 phút): 5 FCM messages được gửi riêng lẻ. Android/iOS group chúng thành "PetQuest (5)" — bố mẹ không bị spam. Nếu bố mẹ đã mở notification tray, chỉ thấy 1 group.

- **Nếu bố mẹ đang mở app lúc notification đến** (foreground): FCM gửi nhưng notification system tray không hiện (iOS/Android behavior). App phải handle `FirebaseMessaging.onMessage` stream và hiển thị in-app banner hoặc badge trên Parent Dashboard tab. Responsibility: Parent Dashboard UI (#21) — Push Notification chỉ define payload.

- **Nếu bố mẹ có 2 child profiles và cả 2 bé submit task cùng lúc**: 2 Cloud Function invocations độc lập, mỗi cái dùng cùng `fcmToken`. Bố mẹ nhận 2 notifications — cả 2 đều correct. Không có race condition.

- **Nếu Cloud Function bị throttled bởi Firebase** (quota exceeded): notification không được gửi cho lần đó. Task vẫn pending — bố mẹ sẽ thấy khi mở app. Log lỗi để monitor quota usage.

- **Nếu `taskTitle` quá dài** (bố mẹ tạo custom task với title >100 ký tự): truncate ở 80 ký tự với "..." trong notification body. Cloud Function xử lý truncation trước khi gửi.

- **Nếu retry (network-transient, nếu enable) khiến function chạy lại trên cùng document event**: Duplicate FCM push có thể xảy ra — chấp nhận là MVP trade-off (xem Formulas' Idempotency note), không dedup. Không phải data bug vì notification không mutate state.

- **Nếu Task Library (#8)'s `onTaskCreated` validation function invalidate task ngay sau khi document được tạo** (race giữa 2 Firestore triggers độc lập trên cùng document-create event): Cả 2 triggers fire độc lập, không có ordering guarantee giữa chúng. Trường hợp hiếm này có thể khiến bố mẹ nhận notification về 1 task vừa bị invalidate — chấp nhận được cho MVP (bố mẹ mở app sẽ thấy task đã không còn pending, không mất dữ liệu, chỉ là thông báo lệch nhịp hiếm gặp).

## Dependencies

**Upstream (Push Notification cần):**
- **Auth & Account (#1)** ✅ — `fcmToken` stored in `families/{parentId}`, token refresh lifecycle
- **Data Persistence (#4)** ✅ — Firestore schema defines where token lives; `onWrite` trigger path

**Downstream (phụ thuộc vào Push Notification):**

| System | Cần gì | Interface |
|--------|--------|-----------|
| Task Library (#8) | Task submit fires notification automatically | Firestore `onWrite` — no direct interface |
| Parent Approval (#11) | Parent tapped notification → deep link into pending tasks view | `deepLink: petquest://parent/tasks/pending` in payload data |
| Parent Dashboard UI (#21) | In-app banner when notification arrives in foreground | `FirebaseMessaging.onMessage` stream — UI owns the handler |

**Cloud Functions owned:**
```
onTaskSubmitted   // Firestore onWrite trigger
  Path: families/{parentId}/children/{childId}/tasks/{taskId}
  Condition: created with status == 'pending'
  Action: send FCM to families/{parentId}.fcmToken
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Notification title max length | 50 ký tự | 30–80 | Bị cắt bởi OS | Thiếu context | OS truncates ~50–65 chars; stay under |
| Notification body max length | 80 ký tự | 50–100 | Bị cắt | Thiếu task name | Cloud Function truncates trước khi gửi |
| Cloud Function memory | 256MB | 128–512MB | Chi phí Firebase tăng | OOM nếu logic phức tạp | FCM send rất nhẹ, 256MB là overkill nhưng safe |
| Cloud Function timeout | 60 giây | 30–540 giây | Firebase billing tăng | Function bị kill trước khi gửi xong | FCM call thường <5s; 60s là buffer lớn |
| FCM retry (2nd-gen `retry`) | **disabled** (MVP) | on/off | Nhiều duplicate push (time-window-bounded, KHÔNG phải 3 lần) | miss khi network flaky | **Sửa 2026-07-08 (ADR-0010)**: KHÔNG phải số-attempt knob — là boolean on/off, retry cho đến khi success/timeout. Không có "3 lần". MVP = off. Nếu bật → cần event-staleness guard. |

## Visual/Audio Requirements

Push Notification System không own visual hay audio assets. Tuy nhiên system xác định 2 yêu cầu với các systems khác:

- **Notification sound**: Dùng default system notification sound của iOS/Android — không custom sound trong MVP. (Nếu muốn custom sound trong Alpha: cần asset `petquest_notify.aiff` / `.mp3`, khai báo trong FCM payload `apns.aps.sound` / `android.notification.sound`)
- **App icon badge**: FCM payload có thể set badge count trên app icon (iOS). MVP: không set badge — defer đến Parent Dashboard UI (#21) để quyết định UX.
- **In-app visual feedback** khi foreground: thuộc Parent Dashboard UI (#21) — Push Notification chỉ fire `FirebaseMessaging.onMessage` event.

## UI Requirements

Push Notification System own 1 UI moment: **Notification Permission Request** dialog.

- Timing: Sau khi bố mẹ tạo xong child profile đầu tiên (onboarding flow), trước khi navigate về màn hình chính.
- Copy: *"Cho phép PetQuest gửi thông báo khi con hoàn thành nhiệm vụ nhé?"* — framing tích cực (không phải "allow notifications")
- Nếu từ chối: hiển thị 1 lần reminder trong Parent Dashboard: *"Bật thông báo để biết ngay khi con submit task →"* (dismissable, không spam)

📌 **UX Flag — Push Notification**: Permission request dialog và foreground in-app banner cần `/ux-design` spec trước khi viết epics — thuộc Parent Dashboard UI (#21) scope nhưng driven bởi Push Notification payload contract.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration". Chỉ `[UI]` là advisory. Toàn bộ 8 criteria dưới đây là `[LOGIC]`/`[INTEGRATION]` — **tất cả BLOCKING**, không có criterion nào `[UI]`-only trong GDD này (hệ quả tự nhiên của việc đây là pure backend/Cloud Function system, không có UI riêng ngoài 1 permission dialog đã delegate cho #21).

**AC-1 — Task submit → notification delivery** `[INTEGRATION]` BLOCKING
**GIVEN** bé tap "Đã xong!" và task document được tạo với `status: 'pending'`,
**WHEN** Cloud Function `onTaskSubmitted` chạy,
**THEN** bố mẹ nhận FCM notification trong vòng **60 giây** (hard test threshold, khớp Formula's worst-case) — title chứa tên bé, body chứa tên task. 10 giây là target/typical latency (tracked as a metric), KHÔNG phải test assertion boundary — test phải assert against 60s, không phải 10s.

**AC-2 — Null token guard** `[LOGIC]` BLOCKING
**GIVEN** `families/{parentId}.fcmToken` là null,
**WHEN** bé submit task,
**THEN** Cloud Function log warning và exit — không throw exception, task document vẫn được tạo thành công.

**AC-3 — Invalid token handling** `[LOGIC]` BLOCKING
**GIVEN** FCM trả về `messaging/registration-token-not-registered`,
**WHEN** Cloud Function nhận response,
**THEN** lỗi được log, không retry, không xóa token từ Firestore — function kết thúc cleanly.

**AC-4 — Title truncation** `[LOGIC]` BLOCKING
**GIVEN** bé submit task với `taskTitle` dài 120 ký tự,
**WHEN** notification được gửi,
**THEN** notification body hiển thị tối đa 80 ký tự với "..." — không bị cắt đột ngột bởi OS.

**AC-5 — Foreground behavior handoff** `[INTEGRATION]` BLOCKING
**GIVEN** bố mẹ đang mở app (foreground) khi task được submit,
**WHEN** FCM message đến,
**THEN** system tray notification không hiện (OS behavior) VÀ `FirebaseMessaging.onMessage` stream fire đúng payload — Parent Dashboard UI (#21) chịu trách nhiệm hiển thị in-app indicator từ payload này.

**AC-6 — Concurrent multi-child correctness** `[LOGIC]` BLOCKING
**GIVEN** 2 bé trong cùng gia đình submit task cùng lúc,
**WHEN** cả 2 Cloud Function invocations chạy,
**THEN** bố mẹ nhận đúng 2 notifications với đúng tên bé và task tương ứng — không bị nhầm lẫn (regression risk: sai tên bé/task không có triệu chứng UI rõ ràng nếu code đọc nhầm biến giữa 2 invocation).

**AC-7 — No permission granted** `[INTEGRATION]` BLOCKING
**GIVEN** bố mẹ chưa grant notification permission,
**WHEN** bé submit task,
**THEN** app không crash, task được tạo, Cloud Function chạy nhưng FCM delivery fails silently — onboarding không bị block.

**AC-8 — iOS permission reminder deep-links to Settings, không re-prompt** `[INTEGRATION]` BLOCKING
**GIVEN** bố mẹ đã từ chối permission trên iOS (kiểm tra qua `getNotificationSettings().authorizationStatus == denied`), **WHEN** bố mẹ tap reminder ở Parent Dashboard (#21), **THEN** app mở Settings app (`UIApplication.openSettingsURLString`) — KHÔNG gọi lại `requestPermission()` (sẽ silently no-op trên iOS, không hiện dialog).

## Open Questions

- **Notification for approval** (post-MVP): Khi bố mẹ approve task, có nên gửi notification đến bé không? Cần 2nd Cloud Function + device management cho child's device. Defer đến Alpha.
- **Multiple parent devices**: Nếu bố và mẹ cùng dùng app (2 devices, 1 account), chỉ 1 `fcmToken` được lưu → chỉ 1 người nhận notification. Cần multi-device token support (array of tokens). Defer đến Alpha — MVP assume 1 parent device.
- **Notification analytics**: Có nên track notification open rate (tap vs dismiss) không? Cần Firebase Analytics events. Defer đến Analytics System (#32).
- **Quiet hours**: Có nên cho bố mẹ set "đừng gửi notification sau 10pm" không? UX nice-to-have, thêm scheduling logic vào Cloud Function. Defer đến Alpha.
- **Deep link handling**: `petquest://parent/tasks/pending` cần Flutter deep link setup (`go_router` hoặc `flutter_deep_link`). Khai báo ở Architecture phase — Push Notification chỉ định nghĩa URI scheme.
