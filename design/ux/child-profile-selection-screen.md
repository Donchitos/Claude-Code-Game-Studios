# UX Spec: Child Profile Selection Screen

> **Status**: Complete
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-16
> **Journey Phase(s)**: unknown — no `design/player-journey.md` yet
> **Template**: UX Spec
> **Source GDD**: `design/gdd/auth-account.md` (#1) — UI Requirements #2, Child Selection Flow (Rule 4)

---

## Purpose & Player Need

Bé (6–10 tuổi) đến màn hình này muốn **tìm và chọn đúng hồ sơ của mình** trong số tối đa 4 anh chị em dùng chung thiết bị — đây là bước "nhận diện bản thân" trước khi vào thế giới riêng của mình (Pillar 5: Mỗi Bé Có Thế Giới Riêng). Nếu màn hình này khó phân biệt các profile hoặc chọn nhầm dễ dàng, bé có thể vô tình vào nhầm phòng của anh/chị/em — phá vỡ cảm giác "đây là không gian CỦA RIÊNG mình".

*"Bé đến màn hình này muốn ___"* → **nhận ra ngay avatar/tên của mình giữa các anh chị em, tap vào, và được xác nhận (qua PIN) rằng đây đúng là không gian của mình.**

---

## Player Context on Arrival

Bé gặp màn hình này **mỗi lần bố mẹ mở app và đưa máy** — đây là bước trung gian bắt buộc mỗi ngày, thường ngay sau khi bố mẹ vừa login (bố mẹ đăng nhập rồi đưa máy cho con). Trạng thái cảm xúc: **háo hức/mong chờ** — bé vừa được giao máy, sắp được gặp thú cưng của mình, đây là khoảnh khắc tích cực, không có gì căng thẳng. Luôn tự nguyện, nhưng thời điểm arrival do bố mẹ quyết định (không phải bé tự mở app).

---

## Navigation Position

Top-level destination, reachable khi `sessionStateProvider == parentAuthed`.

`[root] → Login Screen → Child Profile Selection Screen` (chỉ khi `parentAuthed` — route guard tự động điều hướng tới đây ngay sau login thành công, và quay lại đây nếu bé logout/session bị reset về parentAuthed).

---

## Entry & Exit Points

| Entry Source | Trigger | Bé mang theo gì |
|---|---|---|
| Login Screen | Login thành công | `parentId` scope (session) |
| PIN Entry Screen (back/hủy) | Bé bấm back/hủy khi đang nhập PIN | Không gì — quay lại chọn profile khác |
| Parent Override kết thúc | Bố mẹ đóng Parent Dashboard khi chưa có child nào được chọn | Hiếm — thường override chỉ xảy ra từ `childSelected`, không phải từ đây |

| Exit Destination | Trigger | Ghi chú |
|---|---|---|
| PIN Entry Screen | Tap vào 1 profile card | Mang theo `childId` đã chọn |
| **TBD — out of scope** | Tap "Thêm bé" | Chưa có flow "thêm hồ sơ bé mới" nào được implement hay spec ở đâu trong dự án (gap đã biết từ Story 005's Completion Notes — không story nào sở hữu việc enforce giới hạn tối đa 4 hồ sơ hoặc luồng tạo mới). Nút vẫn được thiết kế trong spec này (đúng GDD UI Requirement), nhưng đích đến khi tap chưa xác định — xem Open Questions. |

---

## Layout Specification

### Information Hierarchy

1. **Grid các profile card** (avatar + tên) — trung tâm tuyệt đối của màn hình, đây là lý do bé đến đây
2. **Nút "Thêm bé"** — thứ yếu, chỉ hiển thị khi còn slot trống (<4 profile) — không cạnh tranh với các profile card
3. **Trạng thái đang tải** (nếu có delay) — tạm thời, không phải nội dung chính

Không cần tiêu đề lớn kiểu "Chọn hồ sơ của bạn" — với target 6-10 tuổi, avatar + tên tự nói lên chức năng, không cần đọc hiểu văn bản dài.

### Layout Zones

**2×2 grid, căn giữa màn hình** — chosen. Từ trên xuống:
1. **Grid zone**: 4 ô grid (2 cột × 2 hàng), mỗi ô 1 profile card (avatar + tên) — nếu ít hơn 4 profile, các ô còn lại trống hoặc hiện nút "Thêm bé" thay thế
2. **Action zone**: nút "Thêm bé" — nằm trong 1 ô grid trống (không phải thanh riêng bên dưới) nếu còn slot; ẩn hoàn toàn nếu đã đủ 4

Grid căn giữa dọc + ngang màn hình, không có header/app-bar phức tạp — giữ cảm giác "đây là cửa vào nhà mình", tối giản.

### Component Inventory

| Zone | Component | Loại | Nội dung | Interactive? | Pattern |
|---|---|---|---|---|---|
| Grid | Profile card | Custom card, corner radius ≥12dp (Art Bible §3) | Chibi avatar illustration + tên bé | Có (tap) | Mới — không có pattern sẵn cho "profile card"; đủ đơn giản để không cần thêm vào pattern library riêng, nhưng cần nhất quán về corner radius/shadow với các card khác trong game |
| Grid | Nút "Thêm bé" | Card dạng dashed-border hoặc icon "+" lớn, cùng kích cỡ ô grid | Icon "+" + text "Thêm bé" | Có (đích đến TBD) | — |
| — | Loading placeholder | Skeleton shimmer, 4 ô | — | Không | P5 |
| — | Empty state (0 profile — hiếm, first-time family) | Text + minh họa | "Chưa có hồ sơ nào — hãy thêm bé đầu tiên!" | Không (nhưng nút "Thêm bé" vẫn active) | P6 |

**Lưu ý pattern**: "Profile card" không khớp hoàn toàn với các pattern hiện có (P3 là bottom sheet, không phải grid card) — không đủ phức tạp để cần entry riêng trong pattern library, nhưng nếu tương lai có thêm màn hình dùng grid-card-chọn tương tự, nên cân nhắc formalize.

### ASCII Wireframe

Ví dụ với 3 profile + 1 nút "Thêm bé":

```
┌───────────────────────────┐
│                            │
│                            │
│   ┌───────┐ ┌───────┐     │
│   │  🐶    │ │  🐱    │     │
│   │  An    │ │ Bình   │     │
│   └───────┘ └───────┘     │
│                            │
│   ┌───────┐ ┌───────┐     │
│   │  🐰    │ │   +    │     │
│   │  Chi   │ │Thêm bé │     │
│   └───────┘ └───────┘     │
│                            │
│                            │
└───────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | Điều gì thay đổi |
|---|---|---|
| **Loading** | `childProfilesProvider` đang fetch (cold start) | Skeleton shimmer 4 ô (P5) |
| **Default (1-4 profile)** | Data load xong, có ≥1 profile | Grid hiện đúng số card, ô còn lại (nếu <4) hiện nút "Thêm bé" ở ô đầu tiên trống |
| **Full (4/4 profile)** | Đã đủ 4 profile | Không có nút "Thêm bé" — grid đầy 4 card |
| **Empty (0 profile)** | Gia đình mới, chưa từng thêm bé nào | P6 empty state: text "Chưa có hồ sơ nào — hãy thêm bé đầu tiên!" + nút "Thêm bé" chiếm vị trí trung tâm |
| **Error** | `childProfilesProvider` AsyncError (mất mạng lần đầu load) | Thông báo lỗi + nút "Thử lại" (P5's "no crash on null-before-first-snapshot") |
| **Malformed doc bị skip** | 1 trong các profile bị lỗi dữ liệu (Story 005's skip-and-log) | Card đó đơn giản không hiện — bé thấy ít hơn số card thật có trên Firestore, không có thông báo lỗi hiển thị (âm thầm theo thiết kế backend đã có) |

Không có "premium/locked" variant — không có khái niệm khóa profile theo trả phí.

---

## Interaction Map

*Input context: Touch-only (mobile).*

| Component | Action | Input | Feedback tức thì | Kết quả |
|---|---|---|---|---|
| Profile card | Tap | Touch tap | Card scale-down nhẹ (press feedback) + ripple | Navigate → PIN Entry Screen, mang theo `childId` đã chọn |
| Nút "Thêm bé" | Tap | Touch tap | Ripple effect | Đích đến TBD — xem Open Questions |

Chỉ 2 loại tương tác — màn hình rất đơn giản, không gesture phức tạp (không swipe, không long-press). Card ≥48×48dp (thực tế lớn hơn nhiều — mỗi ô chiếm gần 1/4 màn hình).

---

## Events Fired

| Hành động | Event | Payload |
|---|---|---|
| Tap profile card | `childProfileSelected` | `childId` |
| Tap "Thêm bé" | `addChildTapped` | Không có (đích đến TBD) |
| Màn hình hiện (view) | `childSelectionScreenViewed` | `profileCount` (số hồ sơ hiện có) |

---

## Transitions & Animations

- **Screen enter**: fade in 200ms (route-guard driven, giống Login Screen)
- **Screen exit** (chọn profile → PIN Entry): fade 200ms — nhất quán đơn giản với các root-level transitions khác trong flow auth
- **Card tap feedback**: scale-down 95% trong 100ms khi press, bounce back khi release — cảm giác "đàn hồi" khớp visual rule "mọi thứ phải trông như muốn được ôm"
- **Loading → Loaded**: skeleton fade-out + card fade-in, 200ms (P5 chuẩn)
- **Reduced-motion**: card scale feedback rút gọn thành opacity-only nếu Reduce Motion bật

---

## Data Requirements

| Data | Hệ thống sở hữu | Đọc/Ghi | Ghi chú |
|---|---|---|---|
| Danh sách profile (avatar, tên, `childId`) | `childProfilesProvider` (Story 005) | Read | `FutureProvider<List<ChildProfile>>`, one-shot `get()`, resolves `[]` nếu chưa có ai — không phải `snapshots()` (ADR-0003 exception đã quyết định) |
| Số lượng profile hiện có (để tính có hiện nút "Thêm bé" không) | Derived từ `childProfilesProvider.length` | Read | Không cần provider riêng |

Không có write từ màn hình này — thuần đọc + điều hướng.

---

## Accessibility

- **Touch target**: Mỗi profile card lớn hơn nhiều so với 48×48dp tối thiểu (chiếm ~1/4 màn hình) — an toàn cho ngón tay trẻ em kém chính xác
- **Color không phải tín hiệu duy nhất**: Không có trạng thái nào dựa màu để phân biệt (mỗi profile phân biệt bằng avatar + tên, không phải màu)
- **Contrast**: Tên bé dùng Primary text color trên nền card pastel — đã pass AA (audit đã resolve)
- **Không timing pressure**: Không có timeout nào trên màn hình này
- **Ngôn ngữ đơn giản**: Chỉ cần đọc tên của chính mình — với bé chưa đọc thạo, avatar minh họa là tín hiệu chính, tên chỉ là xác nhận phụ
- **Motion**: Card tap feedback đã có reduced-motion variant (Transitions)
- **Interaction robustness**: Double-tap vào 1 card không gây double-navigate

**Ghi chú đặc biệt cho target 6-10 tuổi**: Đây là màn hình bé tương tác trực tiếp (không phải bố mẹ) — avatar illustration phải đủ khác biệt để phân biệt nhanh mà không cần đọc tên (hỗ trợ bé chưa đọc thạo tiếng Việt).

---

## Localization Considerations

- Text ngắn nhất có thể — chỉ tên bé (bố mẹ nhập, không kiểm soát độ dài) và "Thêm bé" — cần truncate + ellipsis nếu tên dài để không vỡ layout card cố định
- Không có số/ngày/currency
- Copy "Chưa có hồ sơ nào — hãy thêm bé đầu tiên!" không layout-critical (empty state có nhiều không gian)

---

## Acceptance Criteria

- [ ] Danh sách profile hiển thị đúng avatar + tên cho tất cả child profiles của gia đình (tối đa 4)
- [ ] Bé tap vào 1 profile → navigate đến PIN Entry Screen với đúng `childId` đã chọn
- [ ] Khi 0 profile tồn tại, hiển thị empty state thân thiện thay vì màn hình trắng/lỗi
- [ ] Khi đã đủ 4 profile, nút "Thêm bé" không hiển thị
- [ ] Mỗi profile card đạt tối thiểu 48×48dp tap target (thực tế lớn hơn nhiều)
- [ ] Nếu 1 profile doc bị lỗi dữ liệu, các profile hợp lệ khác vẫn hiển thị bình thường (không crash toàn bộ danh sách — Story 005's skip-and-log)

---

## Open Questions

- **RESOLVED 2026-07-16 (user decision)**: Dialog xác nhận xóa hồ sơ bé (P2 pattern, ownership gap flagged trong Story 009's Out of Scope và Story 011's AC #5) thuộc về **Parent Dashboard (epic #21)**, KHÔNG phải Child Profile Selection Screen. Màn hình này là nơi bé chọn hồ sơ của mình — xóa hồ sơ là hành động của bố mẹ, không thuộc phạm vi màn hình này. Spec này không có affordance xóa nào, đúng như đã thiết kế.
- **Nút "Thêm bé" dẫn tới đâu?** — chưa có flow tạo hồ sơ bé mới trong dự án (không story, không epic nào sở hữu rõ ràng). Cần quyết định trước khi implement Story 011: hoặc để nút này disabled/ẩn tạm thời cho MVP, hoặc ưu tiên thiết kế flow này trước.
- Player journey map chưa tồn tại — "Player Context on Arrival" dựa trên suy luận từ GDD.
- Avatar illustration set (bao nhiêu lựa chọn, ai chọn — bố mẹ hay bé) chưa được xác định — thuộc phạm vi Art/asset pipeline, không phải UX spec này.
