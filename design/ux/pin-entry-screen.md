# UX Spec: PIN Entry Screen

> **Status**: Complete
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-16
> **Journey Phase(s)**: unknown — no `design/player-journey.md` yet
> **Template**: UX Spec
> **Source GDD**: `design/gdd/auth-account.md` (#1) — UI Requirements #3, Child Selection Flow (Rule 4)
> **Governing Pattern**: P10 — PIN entry (dot display + numpad + lockout) (`design/ux/interaction-patterns.md`)

---

## Purpose & Player Need

Bé đến màn hình này muốn **chứng minh nhanh chóng "đây là hồ sơ của mình"** để vào phòng thú cưng — đây là bước bảo mật nhẹ nhàng cuối cùng trước khi được "về nhà" với Mochi. PIN không phải là bức tường bảo mật thật (chỉ là UI boundary chống anh chị em nghịch, theo ADR-0002), nên trải nghiệm phải nhanh và không gây lo lắng — nếu màn hình này cảm giác như một "bài kiểm tra" căng thẳng, nó phá vỡ cảm giác chào đón của Pillar 2.

*"Bé đến màn hình này muốn ___"* → **gõ nhanh 4 số quen thuộc và được vào ngay phòng của mình, không phải suy nghĩ nhiều.**

---

## Player Context on Arrival

Bé đến ngay sau khi tap profile của mình ở Child Profile Selection Screen — trong vòng 1-2 giây, cùng một phiên sử dụng. Trạng thái cảm xúc: **vẫn háo hức**, tiếp nối từ màn hình trước — đây không phải một "chặng" riêng biệt về mặt cảm xúc, mà là bước cuối của cùng một khoảnh khắc "vào nhà". Hiếm khi bé quay lại màn hình này sau khi đã sai PIN — vẫn háo hức nhưng có thể hơi bối rối/frustrated nhẹ nếu gõ sai (không phải lo lắng nghiêm trọng vì hậu quả thấp — không mất gì khi sai).

---

## Navigation Position

Không phải top-level destination — chỉ reachable từ Child Profile Selection Screen với `childId` đã chọn (không có route guard riêng dựa trên `sessionStateProvider`, vì đây là bước trung gian trong `parentAuthed`, chưa chuyển sang `childSelected`).

`[root] → Login → Child Profile Selection → PIN Entry Screen (childId=X)` — chỉ vào được bằng cách chọn 1 profile cụ thể, không có URL/deep-link trực tiếp tới đây mà không qua bước chọn.

---

## Entry & Exit Points

| Entry Source | Trigger | Bé mang theo gì |
|---|---|---|
| Child Profile Selection Screen | Tap 1 profile card | `childId` đã chọn |

| Exit Destination | Trigger | Ghi chú |
|---|---|---|
| Pet Room Screen | PIN đúng | `activeChildProvider` set → `sessionStateProvider` derive `childSelected` — route guard tự chuyển (khớp `pet-room-screen.md`'s Entry: "PIN entry (cold start) → correct PIN → childSelected") |
| Child Profile Selection Screen | Bấm back/hủy | Không set gì — `childId` bị bỏ, quay lại chọn profile khác |

Không có exit "logout hoàn toàn" từ đây — back chỉ lùi lại 1 bước tới Selection, không tới Login.

---

## Layout Specification

### Information Hierarchy

P10 đã quy định 2 thành phần cốt lõi:

1. **4 ô chấm tròn (dot display)** — trung tâm tuyệt đối, hiển thị tiến trình gõ PIN
2. **Numpad chibi (0-9)** — công cụ nhập, chiếm phần lớn không gian còn lại
3. **Tên/avatar bé đã chọn** (xác nhận nhẹ "đây đúng là bạn") — phụ, không cạnh tranh với dot display
4. **Lockout countdown** — chỉ xuất hiện khi bị khóa, thay thế tạm thời numpad hoặc overlay lên nó
5. **Nút back/hủy** — góc màn hình, nhỏ, không phải hành động chính

### Layout Zones

Bố cục chuẩn cho numpad mobile (tối ưu tầm với ngón tay cái):

1. **Header zone**: avatar nhỏ + tên bé đã chọn (xác nhận), nút back góc trên-trái
2. **Dot display zone**: 4 ô chấm tròn, căn giữa, ngay dưới header
3. **Numpad zone**: lưới 3×4 (số 0-9 + nút xóa), chiếm nửa dưới màn hình — vùng dễ với ngón cái nhất trên mobile
4. **Lockout overlay** (khi active): thay thế numpad zone bằng countdown lớn, dot display vẫn hiện nhưng disabled

### Component Inventory

| Zone | Component | Loại | Nội dung | Interactive? | Pattern |
|---|---|---|---|---|---|
| Header | Avatar + tên | Image + text nhỏ | Avatar + tên bé đã chọn | Không | — |
| Header | Nút back | Icon button | Icon mũi tên/X | Có | — |
| Dot display | 4 ô chấm chibi | Custom widget | Rỗng/fill theo số chữ số đã gõ | Không (chỉ hiển thị) | P10 (chibi dot slots) |
| Numpad | 10 phím số + nút xóa | Chibi-style button grid | 0-9 + icon xóa (⌫) | Có | P10 (chibi numpad) |
| Lockout | Countdown display | Text/circular timer lớn | "Thử lại sau 60s" + số đếm ngược | Không | P10 (60s lockout, visible countdown) |

Cả 2 pattern cốt lõi (dot display + numpad) đã có sẵn đầy đủ trong P10 — spec này chỉ cần định vị chúng vào layout, không phát minh hành vi mới.

### ASCII Wireframe

```
┌───────────────────────────┐
│ ←              🐶 An      │  ← Header
│                            │
│       ● ● ○ ○             │  ← Dot display
│                            │
│    ┌───┐┌───┐┌───┐        │
│    │ 1 ││ 2 ││ 3 │        │
│    └───┘└───┘└───┘        │
│    ┌───┐┌───┐┌───┐        │
│    │ 4 ││ 5 ││ 6 │        │  ← Numpad
│    └───┘└───┘└───┘        │
│    ┌───┐┌───┐┌───┐        │
│    │ 7 ││ 8 ││ 9 │        │
│    └───┘└───┘└───┘        │
│    ┌───┐┌───┐┌───┐        │
│    │   ││ 0 ││ ⌫ │        │
│    └───┘└───┘└───┘        │
└───────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | Điều gì thay đổi |
|---|---|---|
| **Default** | Vừa vào màn hình | Dot display rỗng (0/4), numpad active |
| **Filling** | Đang gõ (1-3 số) | Dot tương ứng fill dần |
| **Verifying** | Đã gõ đủ 4 số | Numpad tạm disable trong lúc PBKDF2 tính toán (rất nhanh, off-isolate — không cần spinner riêng, chỉ disable ngắn) |
| **Wrong PIN (lần 1-2)** | Sai PIN, chưa đủ 3 lần | Dot display "rung nhẹ" (shake, ngắn) rồi reset về rỗng, numpad re-active ngay để gõ lại — KHÔNG có thông báo lỗi text (P10 không đề cập text lỗi, dot shake đã đủ tín hiệu) |
| **Locked (sau 3 lần sai)** | Lần sai thứ 3 | Numpad ẩn/disable, hiện lockout countdown 60s (P10) — dot display vẫn hiện nhưng mờ đi |
| **Unlocked (hết 60s)** | Countdown về 0 | Numpad re-active tự động, dot display reset về rỗng |
| **Correct PIN** | Đúng | Dot display fill xanh/mint (không phải chờ, chuyển màn hình gần như ngay) |
| **Credentials chưa sync (offline-first-sync edge case — ADR-0002 Risk, Story 004)** | Hồ sơ bé mới, thiết bị chưa từng online lúc profile được tạo | Thay numpad bằng thông báo rõ ràng: "Cần kết nối mạng để đồng bộ lần đầu — vui lòng thử lại khi có internet" — **không** hiển thị như "sai PIN" (AC4 của Story 004: never a silent false-negative) |
| **Data error (hiếm)** | `PinVerificationActions.verifyChildPin()` throws `VerifiedChildProfileMissing` (Story 004 code-review addition — PIN đúng nhưng không tìm thấy `ChildProfile` khớp, data-integrity edge case) | Thay numpad bằng thông báo lỗi chung ("Có lỗi xảy ra, vui lòng thử lại") + nút quay lại Child Profile Selection — KHÔNG crash app, KHÔNG hiển thị như sai PIN (đây không phải lỗi người dùng) |

---

## Interaction Map

*Input context: Touch-only (mobile).*

| Component | Action | Input | Feedback tức thì | Kết quả |
|---|---|---|---|---|
| Phím số (0-9) | Tap | Touch tap | Phím scale-down + bounce, dot tương ứng fill ngay | Thêm 1 chữ số vào PIN buffer local |
| Nút xóa (⌫) | Tap | Touch tap | Dot cuối cùng đã fill trở về rỗng | Xóa chữ số cuối khỏi PIN buffer |
| Nút back (header) | Tap | Touch tap | Ripple | Quay lại Child Profile Selection, không set gì |
| *(Tự động khi đủ 4 số)* | Không cần tap thêm | — | Numpad disable ngắn (Verifying state) | Gọi `PinVerificationActions.verifyChildPin()` |

Không cần nút "Xác nhận" riêng — PIN 4 số tự động verify ngay khi đủ 4 chữ số (giảm 1 bước tap không cần thiết cho trẻ em).

---

## Events Fired

| Hành động | Event | Payload |
|---|---|---|
| PIN đủ 4 số, verify thành công | `pinVerified` | `childId` (KHÔNG bao giờ chứa PIN thật) |
| PIN đủ 4 số, verify sai | `pinVerificationFailed` | `childId`, `attemptNumber` (1/2/3) — KHÔNG chứa PIN đã nhập |
| Lockout kích hoạt (lần sai thứ 3) | `pinLockoutTriggered` | `childId` |
| Lockout hết hạn | `pinLockoutExpired` | `childId` |
| Credentials chưa sync | `pinCredentialsUnavailable` | `childId` |

Cùng nguyên tắc bảo mật như Login Screen: event payload không bao giờ chứa raw PIN, khớp coding-standards.md và ADR-0002's "never log raw PIN/pinHash/pinSalt".

---

## Transitions & Animations

- **Screen enter**: fade 200ms từ Child Profile Selection (nhất quán với 2 màn trước)
- **Screen exit** (PIN đúng → Pet Room): fade 200ms
- **Dot fill**: scale-pop nhẹ (100ms) khi 1 chữ số được gõ
- **Wrong PIN shake**: dot display rung ngang nhẹ (~300ms, biên độ nhỏ) rồi reset — đủ rõ để bé hiểu "sai" mà không cần đọc text, nhưng biên độ nhỏ để không giật mạnh (accessibility §6, tránh cảm giác "báo động" theo Pillar 4)
- **Correct PIN**: dot display đổi màu (mint/xanh) fill nhanh 150ms trước khi chuyển màn hình
- **Lockout countdown**: số đếm ngược cập nhật mỗi giây, không animation phức tạp — tránh cảm giác "đồng hồ đếm ngược khẩn cấp" (accessibility §4: PIN lockout là "cool-down bé chờ", không phải task deadline)
- **Reduced-motion**: shake animation rút gọn thành flash màu ngắn thay vì di chuyển vị trí (tránh vestibular discomfort — đây là animation có nguy cơ cao nhất trong 3 màn hình vì có chuyển động ngang)

---

## Data Requirements

| Data | Hệ thống sở hữu | Đọc/Ghi | Ghi chú |
|---|---|---|---|
| `pinHash`/`pinSalt` của child đã chọn | `ChildProfileRepository.getChildCredentials()` (Story 005) | Read (một lần, khi bắt đầu verify) | `get()`, không phải `snapshots()` — ADR-0002 §7 |
| `failCount`/`lockUntil` | `PinVerificationRepository` (Story 004, `flutter_secure_storage`) | Read + Write | Local-only, không phải Firestore |
| `activeChildProvider` | `PinVerificationActions.verifyChildPin()` (Story 004) | Write (chỉ khi verify thành công) | Set thành `ChildProfile` khớp `childId` |

Không đọc trực tiếp `pinHash`/`pinSalt` trong UI layer — toàn bộ nằm sau `PinVerificationActions.verifyChildPin({childId, rawPin})`, UI chỉ gọi hàm này và nhận `bool`.

---

## Accessibility

- **Touch target**: Mỗi phím numpad ≥48×48dp (thực tế nên lớn hơn — đây là bàn phím chính cho trẻ 6-10 tuổi, ngón tay chưa chính xác)
- **Color không phải tín hiệu duy nhất**: Dot fill dùng hình dạng (rỗng→đầy) không chỉ màu; wrong-PIN dùng shake (chuyển động) + màu, không chỉ đỏ
- **Contrast**: Số trên numpad + countdown text dùng Primary text color đã pass AA
- **Timing pressure — ngoại lệ có chủ đích**: Đây là màn hình DUY NHẤT trong app có countdown thật (60s lockout) — nhưng accessibility-requirements.md đã minh định đây là "cool-down bé chờ", không phải task deadline gây lo lắng, được chấp nhận như một exception đã note rõ trong baseline
- **Ngôn ngữ đơn giản**: Không cần đọc chữ để dùng numpad (chỉ số) — phù hợp bé chưa đọc thạo
- **Motion**: Shake animation là rủi ro cao nhất, đã có reduced-motion fallback (Transitions)
- **Interaction robustness**: Double-tap nhanh vào phím số không gây double-input (mỗi tap = đúng 1 chữ số, debounce chuẩn)

---

## Localization Considerations

- Numpad chỉ dùng số (0-9) — không có text cần dịch trong thành phần chính
- Text duy nhất cần dịch: "Cần kết nối mạng để đồng bộ lần đầu — vui lòng thử lại khi có internet" và countdown label ("Thử lại sau Xs") — cả 2 không layout-critical (thay thế toàn bộ numpad zone, có nhiều không gian)
- Số đếm ngược (60, 59, 58...) không cần format locale đặc biệt — số nguyên đơn giản

---

## Acceptance Criteria

- [ ] Bé tap vào profile và nhập đúng PIN 4 số → app navigate đến Pet Room screen với `activeChildProvider` = đúng `childId` (GDD AC)
- [ ] Bé nhập sai PIN 3 lần liên tiếp → PIN input bị disabled 60 giây, countdown hiển thị, không thể thử lại sớm hơn (GDD AC)
- [ ] Nhập sai PIN lần 1-2 → dot display reset về rỗng để gõ lại ngay, không bị khóa
- [ ] Hồ sơ chưa từng sync credentials (offline-first-sync edge case) → hiển thị thông báo "cần kết nối mạng", không hiển thị như sai PIN
- [ ] Nếu `verifyChildPin` throw `VerifiedChildProfileMissing` (data-integrity edge case) → hiển thị lỗi chung, không crash app, không hiển thị như sai PIN
- [ ] Mỗi phím numpad đạt tối thiểu 48×48dp tap target
- [ ] Sau khi lockout hết hạn (60s), numpad tự động active lại mà không cần bé tap gì thêm

---

## Open Questions

- Player journey map chưa tồn tại — validate lại "Player Context on Arrival" khi có.
- Copy chính xác cho thông báo "credentials chưa sync" cần xác nhận với localization/copy owner.
- P10 không đề cập rõ: có haptic feedback (rung điện thoại) khi tap phím không? Đề xuất dùng nếu platform hỗ trợ dễ dàng, nhưng không phải yêu cầu chặn implement.
