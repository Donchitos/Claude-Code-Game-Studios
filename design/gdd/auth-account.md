# Auth & Account

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-07-16 (Registration Flow added — see `design/quick-specs/parent-account-registration-2026-07-16.md`)
> **Implements Pillar**: Pillar 4 — Bố Mẹ Là Đồng Minh (family unit as co-players, not surveillance)

## Overview

Auth & Account quản lý identity của toàn bộ family unit trong PetQuest. Một **Parent Account** (email + password, Firebase Auth) liên kết với một hoặc nhiều **Child Profiles** (PIN 4 số + avatar, không có Firebase Auth riêng). Bố mẹ là account holder — họ setup, approve task, và quản lý family. Bé chọn profile của mình bằng PIN khi mở app trên device bố mẹ.

System này là nền tảng của mọi thứ: mọi Firestore document, mọi Riverpod provider, mọi push notification đều scope theo `parentId` và `childId`. Không có Auth & Account — không có cách nào biết xu của bé nào, task của gia đình nào, hay gửi notification đến đúng bố mẹ nào.

**Tác động player-facing**: Khi bố mẹ tạo account lần đầu và bé chọn avatar + đặt tên Mochi — đó là khoảnh khắc "ký hợp đồng" giữa bố mẹ và con. Game bắt đầu từ đây.

## Player Fantasy

**Bố mẹ cảm thấy**: "Tôi đang tạo ra một không gian an toàn cho con — game này biết con tôi là ai, và tôi là người kiểm soát." Setup account nhanh (<3 phút), không phức tạp, không yêu cầu con phải có email riêng.

**Bé cảm thấy**: "Đây là của tôi." Khi bé gõ PIN 4 số và thấy avatar của mình hiện lên cùng tên Mochi — bé đang "bước vào thế giới riêng của mình" trên device bố mẹ. PIN tạo ra ranh giới tâm lý: đây không phải điện thoại của bố mẹ nữa, đây là cổng vào PetQuest của bé.

**Ritual hàng ngày**: Mở app → gõ PIN → thấy Mochi → ngày mới bắt đầu. Đơn giản như khóa nhật ký bằng chìa khóa nhỏ.

## Detailed Design

### Core Rules

**1. Data Model — Family Unit**

> ⚠️ **Single source of truth cho schema**: `design/gdd/data-persistence-layer.md`. Phần này chỉ liệt kê các fields liên quan đến Auth — toàn bộ fields của `children/{childId}` (bao gồm `storedEnergy`, `lastApprovedAt`, `petLevel`, `equippedItems`) được định nghĩa trong Data Persistence GDD.

```
families/{parentId}/
  ├── email, displayName, fcmToken, createdAt    ← owned by Auth
  └── children/{childId}/
        ├── name, avatarId, mochiName             ← owned by Auth (profile fields)
        ├── private/credentials/ { pinHash, pinSalt }  ← owned by Auth, sub-doc (ADR-0002 §7 / ADR-0003)
        └── [full schema → see data-persistence-layer.md]
```
- `parentId` = Firebase Auth UID của bố mẹ
- `childId` = auto-generated Firestore document ID (không phải Firebase Auth UID)
- `pinHash`/`pinSalt` nằm ở sub-document `children/{childId}/private/credentials` (KHÔNG trên document children/{childId}) — chỉ `get()` lúc nhập PIN, không kéo vào profile-selection list. Xem ADR-0003.
- PIN được hash bằng **PBKDF2** — không lưu plain text, không dùng SHA-256 (xem Formulas)
- Tối đa **4 child profiles** per parent account (MVP)

**2. App Session States**

| State | Mô tả | Ai active |
|-------|--------|-----------|
| `unauthenticated` | Chưa login | Không ai |
| `parentAuthed` | Bố mẹ đã login Firebase Auth | Bố mẹ |
| `childSelected` | Bé đã gõ PIN đúng | Bé (childId active) |
| `parentView` | Bố mẹ vào dashboard từ child session | Bố mẹ (override) |

*(Đổi từ snake_case sang camelCase 2026-07-06 để khớp `SessionState` enum thật ở Riverpod Provider Contract — bản trước có 2 casing khác nhau cho cùng 1 khái niệm trong cùng file.)*

**2a. Registration Flow — Bố mẹ** *(thêm 2026-07-16, `design/quick-specs/parent-account-registration-2026-07-16.md`)*

Rule 3 bên dưới (Login Flow) mô tả những gì xảy ra SAU KHI credential đã tồn tại — rule này định nghĩa credential đó được tạo ra như thế nào lần đầu.

1. Bố mẹ điền Email + Password + Xác nhận Password trên màn đăng ký riêng.
2. Client-side: password và xác nhận password phải khớp trước khi submit (hint mềm, validation thật là từ phản hồi Firebase — cùng triết lý với hint format email ở Login Flow).
3. Firebase Auth `createUserWithEmailAndPassword()` → thành công thì ghi ngay `families/{parentId}`: `{email, displayName: <suy từ phần trước @ của email>, createdAt}`. `fcmToken` không ghi (để trống — Story 008's `onTokenRefresh` sẽ tự điền sau khi established).
4. `authStateProvider` tự động emit user mới (Firebase Auth's native `authStateChanges()` stream) → `sessionStateProvider` derive thành `parentAuthed` → chuyển đến Child Profile Selection screen, giống hệt luồng đăng nhập bình thường (Rule 3 bên dưới).

`displayName` không phải field riêng trong form đăng ký (giữ setup "<3 phút, không phức tạp" theo Player Fantasy) — suy ra tự động, không hiển thị ở UI nào hiện tại.

**3. Login Flow — Bố mẹ**
1. Email + Password → Firebase Auth `signInWithEmailAndPassword()`
2. On success: load `families/{parentId}` từ Firestore
3. Nếu document chưa tồn tại: first-time setup flow (tạo family document)
4. `authStateProvider` tự động emit `User` non-null (Firebase Auth's native `authStateChanges()` stream) — không cần set thủ công. `sessionStateProvider` derive thành `parentAuthed` tự động (xem Riverpod Provider Contract).
5. Navigate → Child Profile Selection screen

**4. Child Selection Flow**
1. Hiển thị danh sách child profiles (avatar + name)
2. Bé tap vào profile → nhập PIN 4 số
3. App hash PIN → so sánh với stored hash
4. Nếu đúng: set `activeChildProvider` → `childId`, navigate → Pet Room
5. Nếu sai 3 lần liên tiếp: lock 60 giây (chống brute-force)

**5. Parent Override (từ child session)**
- Nút "Bố/Mẹ" ở góc màn hình (nhỏ, không phá vỡ bé's experience)
- Tap → nhập password bố mẹ (không dùng PIN) → vào Parent Dashboard
- Không logout child session — khi bố mẹ xong, quay lại child session

**6. PIN Reset (bố mẹ)** — UI owned by Parent Dashboard UI (#21)'s Reset PIN dialog; function owned here.
- Bố mẹ nhập PIN mới (4 số) cho child profile trong dialog ở #21 — không auto-generate, không clear-then-force-child-to-set (bố mẹ chủ động chọn PIN mới rồi báo cho bé).
- `resetChildPin({required String childId, required String newPin})`:
  1. Validate `newPin` đúng 4 số (client-side, trước khi gọi)
  2. Generate salt mới (16-byte random, cùng cơ chế Rule 1/Formulas) — **không tái sử dụng salt cũ**
  3. Hash `newPin` bằng PBKDF2 với salt mới (cùng iteration count — xem Formulas)
  4. Write `children/{childId}.pinHash`, `children/{childId}.pinSalt` (overwrite)
  5. Reset `failCount` về 0 (trường hợp bé đang bị lock trước khi reset)
- Không kick active child session nếu bé đang chơi — PIN mới chỉ áp dụng ở lần nhập PIN tiếp theo (login mới hoặc sau khi app bị kill/restart).

---

### States and Transitions

```
[unauthenticated]
    │ login thành công
    ▼
[parent_authed]
    │ bé tap profile + PIN đúng
    ▼
[child_selected] ◄──────────────────┐
    │ bố mẹ tap override + password  │
    ▼                                │
[parent_view] ───── done ───────────┘
    │ logout
    ▼
[unauthenticated]
```

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Data Persistence Layer | → downstream | `parentId`, `childId` | Riverpod `authStateProvider`, `activeChildProvider` |
| Flutter-Flame Bridge | → downstream | `childId` (scope providers) | `activeChildProvider` |
| Currency System | → downstream | `childId` (scope xu balance) | `activeChildProvider` |
| Task Library | → downstream | `parentId`, `childId` | `authStateProvider` |
| Push Notification | → downstream | `fcmToken` of parent | stored in `families/{parentId}` |
| Main Navigation Shell | → downstream | session state (derived) | `sessionStateProvider` điều hướng screens — sửa từ `authStateProvider` (sai, không đủ để derive 4 session states) |

## Formulas

Không có mathematical formula. Nhưng có hai **security contracts**:

**PIN Hashing — PBKDF2 (không dùng SHA-256):**

> ❌ SHA-256 là fast hash — dễ bị rainbow-table, và cho phép so sánh hash chéo giữa các bé nếu không salt.  
> ✅ PBKDF2 + salt riêng mỗi bé: chống rainbow-table và chống so sánh hash chéo. Đây là lý do dùng PBKDF2 — KHÔNG dùng bare SHA-256.
>
> ⚠️ **Đính chính (ADR-0002)**: iteration count 100k **KHÔNG** làm brute-force "tốn hàng giờ" cho PIN 4 số. Keyspace chỉ 10,000 giá trị — một khi `pinHash`/`pinSalt` đã nằm trên device (luôn xảy ra, vì verify là client-side), toàn bộ keyspace bị vét cạn trong vài giây. **Phòng thủ thật sự chống đoán PIN là lockout online (Formulas bên dưới) — một UI control, không phải cơ chế mật mã.** Không cần tăng iteration hay đổi sang Argon2: threat model (anh/chị/em ruột dùng chung device) không đòi hỏi điều đó. Xem ADR-0002 mục "Non-Goals / Accepted Limitations".

```
salt       = SecureRandom.bytes(16)           // random, mỗi child profile 1 salt riêng
pinHash    = PBKDF2-HMAC-SHA256(raw_pin, salt, iterations=100_000, keyLength=32)
stored     = { pinHash: hex(pinHash), pinSalt: hex(salt) }  // lưu cả hai vào Firestore
```

| Variable | Type | Value | Mô tả |
|----------|------|-------|-------|
| `raw_pin` | String | 4 ký tự số | Bé nhập |
| `salt` | Bytes | 16 bytes random | Generated khi tạo/reset PIN, stored tại `children/{childId}.pinSalt` |
| `iterations` | int | 100,000 | Work factor — tăng lên 200,000 khi hardware cho phép |
| `pinHash` | String | 32-byte hex | Stored tại `children/{childId}.pinHash` |
| Package | — | `pointycastle: ^3.9.0` | Dart implementation của PBKDF2 |

**Verification flow**: lấy `pinSalt` từ Firestore → compute PBKDF2(input_pin, salt) → so sánh với stored `pinHash`.

**PIN Lockout — `failCount` lưu tại `flutter_secure_storage`:**

> `failCount` được lưu tại `flutter_secure_storage` (không phải Firestore, không phải plain `StateProvider`):
> - Tồn tại qua app force-close → không bypassable bằng kill app
> - Không tốn Firestore writes cho mỗi failed attempt
> - Bị reset khi uninstall (acceptable — device-level protection)

```
lock_until = now + lockDuration   (nếu failCount >= maxFails)
```

| Variable | Symbol | Type | Value | Storage | Mô tả |
|----------|--------|------|-------|---------|-------|
| Fail count | `failCount` | int | 0–3 | `flutter_secure_storage` key: `pin_fail_{childId}` | Reset về 0 khi đúng PIN |
| Lock timestamp | `lockUntil` | int | Unix ms | `flutter_secure_storage` key: `pin_lock_{childId}` | null nếu chưa bị lock |
| Max fails | `maxFails` | int | 3 | Tuning knob | Số lần sai tối đa |
| Lock duration | `lockDuration` | seconds | 60 | Tuning knob | Thời gian khóa |

## Edge Cases

- **Nếu bố mẹ quên password**: Firebase Auth `sendPasswordResetEmail()` — standard flow. Bé không bị ảnh hưởng (child profiles vẫn còn trong Firestore).

- **Nếu bé quên PIN**: Bố mẹ vào Parent Dashboard → reset PIN cho child profile. Bé không thể tự reset (không có email riêng).

- **Nếu bố mẹ xóa app và cài lại**: Firebase Auth token tự động restore nếu cùng device. Nếu device mới: login lại bằng email + password → Firestore data còn nguyên.

- **Nếu có 2 bé cùng dùng app cùng lúc** (tablet shared): Không hỗ trợ concurrent sessions — app chỉ có 1 `activeChildProvider` tại một thời điểm. Bé thứ hai phải đợi hoặc bé thứ nhất chuyển profile.

- **Nếu `fcmToken` của bố mẹ thay đổi** (app reinstall): `FirebaseMessaging.instance.onTokenRefresh` stream phải update `families/{parentId}.fcmToken` tự động.

- **Nếu child profile bị xóa**: Confirmation dialog hiển thị cảnh báo "Không thể hoàn tác — Toàn bộ dữ liệu của bé (xu, task, pet) sẽ bị xóa vĩnh viễn." Sau khi xác nhận, **Cloud Function `onChildProfileDelete`** thực hiện recursive delete toàn bộ `children/{childId}/` và các subcollections (Firestore **không** tự cascade delete subcollections — client-side delete không đáng tin cậy trên mobile). Cloud Function phải chạy với Admin SDK để đảm bảo atomic deletion kể cả khi app bị close giữa chừng.

- **Nếu `families/{parentId}` document không tồn tại** sau khi login: Redirect đến first-time setup, không crash. Trường hợp này xảy ra nếu user tạo Firebase Auth nhưng app crash trước khi tạo Firestore document.

- **COPPA/GDPR**: Bé dưới 13 tuổi không có Firebase Auth account riêng → compliant. Mọi data của bé nằm dưới parent account → bố mẹ có thể request xóa toàn bộ bằng cách xóa parent account.

## Dependencies

**Không có upstream dependencies** — Foundation system, zero dependencies.

**Downstream dependents (Auth & Account phải satisfy):**

| System | Cần gì từ Auth | Interface |
|--------|---------------|-----------|
| Data Persistence Layer (#4) | `parentId` để scope Firestore paths | `authStateProvider` |
| Flutter-Flame Bridge (#5) | `childId` để scope Riverpod providers | `activeChildProvider` |
| Currency System (#7) | `childId` để load/save xu balance | `activeChildProvider` |
| Task Library (#8) | `parentId` + `childId` để scope tasks | cả hai providers |
| Push Notification (#9) | `fcmToken` của bố mẹ | stored in Firestore, exposed via `parentProfileProvider` |
| Main Navigation Shell (#17) | session state để điều hướng đúng screen | `sessionStateProvider` (sửa 2026-07-06 — bản trước ghi `authStateProvider`, tự mâu thuẫn với Interactions table phía trên trong cùng file đã fix đúng) |
| Parent Dashboard UI (#21) | PIN reset function, child profile list | `resetChildPin()`, child profiles từ `families/{parentId}/children` |
| **Cloud Functions** | Cascade delete `children/{childId}/` khi xóa profile | `onChildProfileDelete` trigger |

**Riverpod Provider Contract — các providers này phải tồn tại:**
```dart
// Ai đang login (Firebase Auth user)
final authStateProvider = StreamProvider<User?>(...);

// Child profile đang active
final activeChildProvider = StateProvider<ChildProfile?>(...);

// Parent profile (family document)
final parentProfileProvider = FutureProvider<ParentProfile?>(...);

// Parent Override flag (Core Rule 5) — true khi bố mẹ đang ở Parent Dashboard
// từ trong 1 child session (KHÔNG logout child, chỉ tạm overlay parent view)
final parentOverrideProvider = StateProvider<bool>((ref) => false);

// Session state — DERIVED provider, đây là nguồn sự thật thật sự cho 4 App
// Session States ở Core Rule 2 (thêm 2026-07-06, đóng gap: Main Navigation Shell
// #17 đã tham chiếu 1 provider tên "sessionStateProvider" nhưng provider này
// chưa từng được định nghĩa ở đâu — #17 giả định nó tồn tại mà không thấy ai sở hữu)
enum SessionState { unauthenticated, parentAuthed, childSelected, parentView }

final sessionStateProvider = Provider<SessionState>((ref) {
  // ⚠️ Sửa 2026-07-13 (ADR-0002 Correction note): dùng safe nullable accessor
  // để tránh crash routing khi authStateChanges() gặp lỗi. Trên riverpod 3.x,
  // đó là `.value` (đã đổi hành vi — không còn rethrow trên AsyncError;
  // `.valueOrNull` đã bị xóa khỏi 3.x). Verify lại đúng version riverpod
  // production trước khi implement. Note: a plain Provider is not Listenable —
  // go_router needs an explicit refresh bridge (GoRouterRefreshStream), see ADR-0002 §5.
  final user = ref.watch(authStateProvider).value;
  if (user == null) return SessionState.unauthenticated;
  final activeChild = ref.watch(activeChildProvider);
  if (activeChild == null) return SessionState.parentAuthed;
  final isOverride = ref.watch(parentOverrideProvider);
  return isOverride ? SessionState.parentView : SessionState.childSelected;
});

// PIN reset (Core Rule 6) — called by Parent Dashboard UI (#21)
Future<void> resetChildPin({required String childId, required String newPin});
```
Tất cả downstream systems import từ `lib/providers/auth_providers.dart` — không tự tạo providers riêng. `sessionStateProvider` là provider chính thức cho route-guard logic — Main Navigation Shell (#17) đọc provider này, KHÔNG tự implement derivation riêng.

**`parentOverrideProvider` write contract**: set `true` khi bố mẹ hoàn tất "Parent Override" flow (Core Rule 5 — nhập password đúng, không logout child). Set `false` khi bố mẹ tap "xong"/"quay lại" ở Parent Dashboard, quay thẳng về `child_selected` — theo States/Transitions diagram bên dưới, KHÔNG cần bé nhập lại PIN (session vẫn còn nguyên, chỉ tạm ẩn UI parent).

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Max child profiles per parent | 4 | 1–8 | UI quá phức tạp, Firestore reads tăng | 1 → gia đình nhiều con không dùng được | Tăng lên 6 khi có demand |
| PIN length | 4 | 4–6 | Bé khó nhớ | <4 → brute-force dễ | Cố định 4 cho MVP |
| PIN fail lockout threshold | 3 | 2–5 | Quá khoan dung → brute-force | 2 → bé nhập nhầm 1 lần là bị lock | 3 là cân bằng tốt |
| PIN lockout duration | 60s | 30s–300s | Bé frustrated, bỏ app | <30s → lockout vô nghĩa | Reset sau mỗi lần mở khóa thành công |
| Session persistence | Until logout | — | — | — | Không có session timeout — bé không phải login lại mỗi ngày |

## Visual/Audio Requirements

Không áp dụng trực tiếp — nhưng các screens của system này (Login, Child Selection, PIN entry) phải tuân theo Art Bible Section 4 (Color System) và Section 3 (Shape Language):
- Parent view: Lavender Soft (#C5A3E0) dominant — visually distinct từ child zone
- PIN input: 4 chiếc ô tròn chibi, fill khi bé gõ — không dùng standard text field
- Child avatar selection: chibi illustrations, corner radius ≥12dp, pastel palette

## UI Requirements

3 screens thuộc system này — cần UX spec riêng trước khi code:
1. **Login Screen** (bố mẹ): email + password fields, "Quên mật khẩu" link
2. **Child Profile Selection Screen**: grid avatar + name cards, "Thêm bé" button
3. **PIN Entry Screen**: 4-dot display + numpad chibi, lockout countdown

📌 **UX Flag — Auth & Account**: System này có UI requirements. Trong Phase 4 (Pre-Production), run `/ux-design` để tạo UX spec cho 3 screens trên trước khi viết epics.

## Acceptance Criteria

**GIVEN** bố mẹ nhập email + password hợp lệ,
**WHEN** tap "Đăng nhập",
**THEN** app navigate đến Child Profile Selection screen trong <3 giây.

**GIVEN** bố mẹ nhập sai password,
**WHEN** tap "Đăng nhập",
**THEN** hiển thị thông báo lỗi "Sai mật khẩu" — không lộ thông tin email có tồn tại hay không.

**GIVEN** bé tap vào profile và nhập đúng PIN 4 số,
**WHEN** xác nhận PIN,
**THEN** app navigate đến Pet Room screen với `activeChildProvider` = đúng `childId`.

**GIVEN** bé nhập sai PIN 3 lần liên tiếp,
**WHEN** lần thứ 3 fail,
**THEN** PIN input bị disabled 60 giây, countdown hiển thị, không thể thử lại sớm hơn.

**GIVEN** bố mẹ tap nút override từ child session và nhập đúng password,
**WHEN** xác nhận,
**THEN** Parent Dashboard mở mà không logout child session — quay lại child session khi đóng dashboard.

**GIVEN** bố mẹ gọi `resetChildPin(childId, newPin)` với `newPin` hợp lệ (4 số),
**WHEN** function hoàn tất,
**THEN** `pinHash` và `pinSalt` của `childId` được overwrite với salt mới (khác salt cũ), `failCount` reset về 0, và PIN cũ không còn hoạt động ở lần login tiếp theo.

**GIVEN** bé đang có active session khi bố mẹ reset PIN của bé đó,
**WHEN** reset hoàn tất,
**THEN** session hiện tại của bé KHÔNG bị kick — PIN mới chỉ có hiệu lực ở lần nhập PIN tiếp theo.

**GIVEN** `fcmToken` thay đổi sau khi app reinstall,
**WHEN** bố mẹ login,
**THEN** `families/{parentId}.fcmToken` được update tự động trong Firestore.

**GIVEN** bố mẹ tạo account lần đầu và `families/{parentId}` chưa tồn tại,
**WHEN** login thành công,
**THEN** app redirect đến first-time setup flow — không crash, không blank screen.

**GIVEN** bố mẹ xóa child profile,
**WHEN** xác nhận xóa,
**THEN** confirmation dialog hiển thị cảnh báo "Không thể hoàn tác" trước khi xóa; sau khi xóa, toàn bộ `children/{childId}/` bị xóa khỏi Firestore.

## Open Questions

- **Forgot PIN UX cho bé**: Hiện tại bố mẹ phải reset — có nên thêm "Gọi bố/mẹ" button để bé không bị stuck một mình không?
- **Multi-device**: Bố mẹ có 2 điện thoại — có cần sync child session state giữa 2 device không? (MVP: không cần — bé chỉ chơi trên 1 device)
- **Account deletion**: Quy trình xóa toàn bộ parent account (GDPR right to erasure) cần được implement trước launch — cần Cloud Function hay client-side đủ không?
