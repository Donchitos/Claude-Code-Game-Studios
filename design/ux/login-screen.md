# UX Spec: Login Screen

> **Status**: Complete
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-16
> **Journey Phase(s)**: unknown — no `design/player-journey.md` yet
> **Template**: UX Spec
> **Source GDD**: `design/gdd/auth-account.md` (#1) — UI Requirements #1, Login Flow (Rule 3)

---

## Purpose & Player Need

Bố mẹ đến màn hình này muốn **xác thực danh tính để mở khóa quyền truy cập gia đình** — không phải để "chơi", mà để làm cổng bảo vệ cho dữ liệu và tài khoản của các con. Nếu màn hình này khó dùng hoặc chậm, cả gia đình bị chặn ngoài cửa trước khi chạm vào bất kỳ phần vui nào của game (Pillar 4: Bố Mẹ Là Đồng Minh — trải nghiệm phải nhẹ nhàng, nhanh).

*"Bố mẹ đến màn hình này muốn ___"* → **đăng nhập nhanh và tin tưởng rằng dữ liệu con mình được bảo vệ, rồi rời khỏi màn hình này càng sớm càng tốt để giao máy lại cho con.**

---

## Player Context on Arrival

Bố mẹ gặp màn hình này lần đầu khi setup app cho con (thường sau khi tải app từ store), rồi định kỳ sau đó — mỗi khi app bị đăng xuất (force-close lâu ngày, đổi thiết bị, hoặc chủ động logout). Ngay trước đó họ vừa mở app từ home screen, thường trong bối cảnh bận rộn (sau giờ làm, chuẩn bị đưa máy cho con). Trạng thái cảm xúc giả định: **trung tính đến hơi vội** — không stress, nhưng không có thời gian rảnh để "khám phá" UI. Luôn là chủ động/tự nguyện (không ai ép bố mẹ đăng nhập).

---

## Navigation Position

Login Screen là **top-level destination, luôn reachable khi `sessionStateProvider == unauthenticated`** (route guard, ADR-0002/nav #17) — không nằm dưới bất kỳ tab/shell nào. Đây là màn hình gốc của toàn app khi chưa đăng nhập.

`[root] → Login Screen` (chỉ khi unauthenticated — route guard tự động redirect về đây nếu session rớt về unauthenticated từ bất kỳ đâu, kể cả giữa chừng session khác).

---

## Entry & Exit Points

| Entry Source | Trigger | Player carries |
|---|---|---|
| App cold start (chưa từng login) | `sessionStateProvider == unauthenticated` | Không gì (first-time) |
| Logout / session expired | Route guard redirect | Không gì — session bị xóa hoàn toàn |

| Exit Destination | Trigger | Notes |
|---|---|---|
| Child Profile Selection Screen | Login thành công | `authStateProvider` emit `User` non-null → `sessionStateProvider` tự derive `parentAuthed` → route guard tự chuyển, không cần navigate thủ công |

Không có exit nào khác — đây là dead-end cho tới khi login thành công (không có "Skip", không có back navigation ra ngoài app trừ OS back/home).

---

## Layout Specification

### Information Hierarchy

1. **Email field** — điểm bắt đầu, luôn thấy ngay
2. **Password field** — ngay dưới email
3. **Nút "Đăng nhập" (CTA chính)** — hành động duy nhất cần thực hiện
4. **"Quên mật khẩu"** — discoverable nhưng không cạnh tranh với CTA chính (thứ yếu, dành cho trường hợp hiếm)
5. **Thông báo lỗi** (khi có) — xuất hiện theo ngữ cảnh, không phải mặc định visible

Không có "Đăng ký mới" trên màn hình này — bố mẹ nhận tài khoản qua một flow riêng (onboarding/setup), Login Screen chỉ xác thực, không tạo tài khoản mới tại đây.

### Layout Zones

**Centered vertical stack** — chosen. Từ trên xuống:
1. **Header zone**: Mochi Baby HAPPY sprite mascot (96×96dp, static frame) trong Peach Glow soft backdrop, không full-bleed + tên app, căn giữa
2. **Form zone**: email field → password field, khoảng cách đều, căn giữa màn hình theo chiều dọc
3. **Action zone**: nút "Đăng nhập" (CTA chính, full-width trong safe margin) ngay dưới form
4. **Secondary zone**: link "Quên mật khẩu" — nhỏ hơn, căn giữa, dưới CTA
5. **Error zone**: inline, xuất hiện ngay trên/dưới form khi có lỗi (không phải toast/snackbar — bố mẹ cần đọc kỹ, không tự biến mất)

Bố cục này an toàn khi bàn phím ảo bật (form nằm giữa, không bị che), đơn giản để dựng, và là pattern quen thuộc với bố mẹ (giống mọi app login khác họ đã dùng — không cần học lại).

### Component Inventory

| Zone | Component | Loại | Nội dung | Interactive? | Pattern |
|---|---|---|---|---|---|
| Header | App logo/mascot | Image | Mochi Baby HAPPY sprite (static, 96×96dp) + tên "PetQuest" | Không | — |
| Form | Email field | Material 3 `TextField` | Placeholder "Email" | Có | Standard field (không có pattern riêng — P10 chỉ dành cho PIN trẻ em) |
| Form | Password field | Material 3 `TextField` (obscured) | Placeholder "Mật khẩu", icon con mắt để toggle hiện/ẩn | Có | Standard field |
| Action | Nút "Đăng nhập" | `FilledButton` | Text "Đăng nhập" | Có | P1 (single-flight guard — disable trong khi chờ Firebase Auth resolve) |
| Secondary | Link "Quên mật khẩu" | `TextButton` | Text "Quên mật khẩu?" | Có (mở flow riêng, ngoài phạm vi spec này) | — |
| Error | Thông báo lỗi | Inline text, Primary text color + icon ⚠️ | "Sai email hoặc mật khẩu" | Không | P8 (icon+color, không chỉ dựa màu) |

Login dùng standard Material text field — không có pattern riêng trong thư viện vì đây là input chuẩn (không phải trẻ em dùng). Không thêm entry mới vào pattern library — quá cơ bản để cần một entry riêng.

### ASCII Wireframe

```
┌───────────────────────────┐
│                            │
│        [Mochi mascot]     │  ← Header zone
│         PetQuest          │
│                            │
│                            │
│  ┌───────────────────┐    │
│  │ Email              │    │  ← Form zone
│  └───────────────────┘    │
│  ┌───────────────────┐    │
│  │ Mật khẩu       👁  │    │
│  └───────────────────┘    │
│                            │
│  [⚠️ Sai email hoặc mật khẩu]  ← Error zone (khi có lỗi)
│                            │
│  ┌───────────────────┐    │
│  │     Đăng nhập      │    │  ← Action zone (CTA)
│  └───────────────────┘    │
│                            │
│      Quên mật khẩu?       │  ← Secondary zone
│                            │
└───────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | Điều gì thay đổi |
|---|---|---|
| **Default** | Mở màn hình lần đầu | Form trống, CTA enabled, không lỗi |
| **Filling** | Bố mẹ đang gõ | Validation inline nhẹ (định dạng email) — không block gõ |
| **Submitting** | Tap "Đăng nhập" | CTA disabled + spinner nhỏ trong nút (P1 single-flight guard) — form fields cũng disabled để tránh sửa giữa chừng |
| **Error — sai thông tin** | Firebase Auth reject (generic, không phân biệt email/password sai) | Error zone hiện "Sai email hoặc mật khẩu" (P8: icon ⚠️ + text, không dùng màu đỏ — Art Bible), CTA + fields re-enabled ngay, password field tự clear (email giữ nguyên) |
| **Error — mất mạng** | Network timeout/no connection | Error zone hiện thông báo khác: "Không có kết nối mạng — thử lại" — phân biệt rõ với sai mật khẩu để bố mẹ không nhầm lẫn debug sai hướng |
| **Success** | Login thành công | Không có state hiển thị riêng — route guard chuyển màn hình ngay lập tức (không cần loading transition riêng, xem Transitions & Animations) |

Không có empty state (P6) vì đây không phải data list. Không có locked/premium variant.

---

## Interaction Map

*Input context: Touch-only (mobile), không gamepad.*

| Component | Action | Input | Feedback tức thì | Kết quả |
|---|---|---|---|---|
| Email field | Tap để focus, gõ | Touch tap + keyboard | Field border highlight, con trỏ nhấp nháy | Cập nhật giá trị local state |
| Password field | Tap để focus, gõ | Touch tap + keyboard | Field border highlight, ký tự ẩn (•••) | Cập nhật giá trị local state |
| Password field — icon con mắt | Tap để toggle hiện/ẩn | Touch tap | Icon đổi trạng thái, text hiện/ẩn ngay | Không ghi state, chỉ UI-local |
| Nút "Đăng nhập" | Tap | Touch tap | Nút disable + spinner ngay lập tức (P1) | Gọi `AuthRepository.signIn()` → thành công: route guard chuyển màn hình; thất bại: hiện Error state |
| Link "Quên mật khẩu" | Tap | Touch tap | Ripple effect chuẩn Material | Mở flow quên mật khẩu (ngoài phạm vi spec này — flag ở Open Questions) |

Tất cả tap target đạt tối thiểu 48×48dp (accessibility baseline).

---

## Events Fired

| Hành động | Event | Payload |
|---|---|---|
| Tap "Đăng nhập" (submit) | `loginAttempted` | Không gồm password/email thật (privacy — chỉ đếm attempt) |
| Login thành công | `loginSucceeded` | `parentId` |
| Login thất bại (sai thông tin) | `loginFailed` | Lý do generic ("invalid_credentials"), KHÔNG log email/password (Pillar 4 — không phải surveillance tool, và bảo mật) |
| Tap "Quên mật khẩu" | `forgotPasswordTapped` | Không có |
| Toggle hiện/ẩn password | *Không fire event* | UI-local, không cần track |

Đây là màn hình duy nhất chứa dữ liệu nhạy cảm (password) — event payload không bao giờ chứa raw password, khớp với coding-standards.md's "never log raw PIN/pinHash/pinSalt" mở rộng sang password nói chung.

---

## Transitions & Animations

- **Screen enter**: fade in nhẹ (200ms) khi app cold-start hoặc redirect từ logout — không cần slide (root screen, không có "quay lại" khái niệm)
- **Screen exit** (login thành công → Child Profile Selection): fade out + fade in màn hình mới (200ms), khớp route-guard-driven transition (không phải navigate thủ công)
- **State-change animation**:
  - Submitting → error: error zone fade-in 150ms (không slam/shake — tránh cảm giác "báo động", Pillar 4 + accessibility §6)
  - Error → re-typing: error zone fade-out khi user bắt đầu sửa input (150ms)
- **Reduced-motion**: tất cả fade trên đã nhẹ sẵn (không scale/spin lớn) — khi OS bật Reduce Motion, rút ngắn xuống gần như instant cross-fade (accessibility §6); không cần biến thể riêng phức tạp vì animation gốc đã tối giản.

Không có motion nào có nguy cơ gây khó chịu tiền đình (vestibular) — mọi transition đều là fade, không xoay/scale lớn.

---

## Data Requirements

| Data | Hệ thống sở hữu | Đọc/Ghi | Ghi chú |
|---|---|---|---|
| `email`, `password` (input) | UI-local (không ghi vào Firestore trực tiếp) | — | Đưa thẳng vào Firebase Auth SDK, không qua Firestore |
| Firebase Auth session/`User` | Firebase Auth (`authStateProvider`) | Read (sau khi SDK ghi qua `signInWithEmailAndPassword`) | Đã implement — `AuthRepository.signIn()` (Story 001) |
| `families/{parentId}` document | Data Persistence Layer | Read (kiểm tra tồn tại, để biết first-time setup hay không) | Đã implement — `AuthRepository.getParentProfile()` (Story 001) |

Không có write trực tiếp nào từ màn hình này ngoài việc gọi Firebase Auth SDK's own write (session token). Không có real-time/time-sensitive data.

---

## Accessibility

Đối chiếu với **Kid-Touch Baseline** (`accessibility-requirements.md`):

- **Touch target**: Nút "Đăng nhập", link "Quên mật khẩu", icon con mắt, và cả 2 field đều ≥48×48dp
- **Color không phải tín hiệu duy nhất**: Error dùng icon ⚠️ + text, không dựa màu đỏ (P8, Art Bible — "sensitive" state dùng Lavender Soft accent + icon)
- **Contrast**: Text dùng Primary text color (`#3D2B1F`) đã pass AA 4.5:1 trên mọi background pastel (audit 2026-07-13/14); nút CTA dùng Primary text trên fill, không dùng trắng-trên-pastel (đã resolved trong audit)
- **Không timing pressure**: Không có countdown/timeout tự động ép buộc — lỗi hiển thị và ở lại cho tới khi user tự sửa
- **Ngôn ngữ đơn giản**: "Sai email hoặc mật khẩu" — ngắn gọn, không thuật ngữ kỹ thuật
- **Motion**: Đã cover ở Transitions & Animations — chỉ fade nhẹ, có reduced-motion variant
- **Interaction robustness**: Double-tap CTA không gây double-submit (P1 single-flight guard)

**Không cần** (ngoài MVP baseline): screen-reader canvas support (đây là Flutter widget chuẩn, tự động thừa hưởng Flutter semantics mặc định — không cần custom authoring); dynamic type ngoài +30% không cam kết.

---

## Localization Considerations

- Text dài nhất: "Sai email hoặc mật khẩu" — không layout-critical (error zone wrap tự do, không giới hạn 1 dòng)
- **Layout-critical**: Nút "Đăng nhập" — label ngắn, tiếng Anh "Sign In"/"Log In" cũng ngắn tương đương → rủi ro thấp với +40% text expansion
- Không có số/ngày/currency cần format theo locale trên màn hình này
- MVP là tiếng Việt-first — không cần i18n đầy đủ ngay, nhưng string nên externalize (không hardcode) để dễ mở rộng sau

---

## Acceptance Criteria

- [ ] Bố mẹ nhập email + password hợp lệ, tap "Đăng nhập" → app navigate đến Child Profile Selection screen trong <3 giây (GDD AC)
- [ ] Bố mẹ nhập sai password, tap "Đăng nhập" → hiển thị "Sai email hoặc mật khẩu" — không lộ thông tin email có tồn tại hay không (GDD AC)
- [ ] Mất kết nối mạng khi tap "Đăng nhập" → hiển thị thông báo lỗi mạng riêng biệt, không nhầm với sai mật khẩu
- [ ] Double-tap nhanh vào "Đăng nhập" chỉ kích hoạt 1 lần gọi Firebase Auth (P1 single-flight guard) — không double-submit
- [ ] Mọi element tương tác (2 field, CTA, link, icon con mắt) đạt tối thiểu 48×48dp tap target
- [ ] Error message dùng icon ⚠️ kèm text, không dựa màu đỏ để truyền đạt trạng thái lỗi (WCAG 1.4.1)

---

## Open Questions

- "Quên mật khẩu" flow (nội dung/màn hình sau khi tap) chưa được thiết kế — ngoài phạm vi spec này, cần một UX spec riêng khi được ưu tiên.
- Player journey map (`design/player-journey.md`) chưa tồn tại — Section "Player Context on Arrival" dựa trên suy luận từ GDD, nên validate lại khi player journey được tạo.
- Network-error copy cụ thể ("Không có kết nối mạng — thử lại") là placeholder — cần xác nhận với localization/copy owner trước khi hardcode.
