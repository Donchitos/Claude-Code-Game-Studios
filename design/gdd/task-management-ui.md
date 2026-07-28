# Task Management UI

> **Status**: Approved ✅ — /design-review NEEDS REVISION 2026-07-05, all 7 findings resolved (sort-order contradiction with `pendingTasksProvider` fixed via client-side reverse; reject-path/Wither animation added throughout — was approve-only; interrupt-detection mechanism named + propagation flagged to #17; 2 stale "still pending" notes corrected; #21's now-resolved Open Question closed; Edge Case 6 re-tagged BLOCKING)
> **Author**: User + Agents
> **Last Updated**: 2026-07-05
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật

## Overview

Task Management UI là màn hình bé tương tác nhiều nhất trong PetQuest — nơi bé submit task thực tế đã làm ngoài đời và theo dõi kết quả. GDD này sở hữu 3 surfaces trên 2 route (Main Navigation Shell #17): **pending list** (`/child/tasks`, mặc định) hiển thị hạt giống đang chờ approve (derived từ Seed Buffer #10's `seedCount`, capped 10 + "+N more") và **task history** — 30 ngày task đã approved/rejected gần nhất, dùng `taskHistoryProvider` đã có sẵn từ Task Library (#8); và **task creation** (`/child/tasks/new`) nơi bé chọn category → preset task (5 built-in + `customTasks` templates bố mẹ tạo, Parent Dashboard UI #21) hoặc tự gõ tên task riêng → tap "Đã xong!" → tạo `tasks/{taskId}` với `status: 'pending'`.

**Sửa lại quyết định trước đó**: Parent Dashboard UI (#21) từng defer "Task History ownership" là ambiguous. Sai — Task Library (#8) đã quyết định rõ: `taskHistoryProvider` explicitly dành cho Task Management UI (#19), provider đã tồn tại sẵn. GDD này chính thức nhận Task History vào scope; sẽ sửa lại #21 sau khi GDD này viết xong.

Về kiến trúc: Flutter widget layer thuần túy (Material 3, theme "Cozy Chibi" của child side — không phải tone Navy/professional của parent side), không sống trong FlameGame canvas (canvas đó là Pet Room Screen #18's riêng). Một chi tiết cần rõ ràng: Seed Buffer's bloom animation (hạt giống nở → xu particles bay vào xu counter) có nguồn (seed trong list ở đây) và đích (xu counter, nằm ở Child app bar persistent — #17's territory) khác component nhau — GDD này định nghĩa trigger, không tự vẽ counter đó.

Player-facing: bé chủ động mở tab "Nhiệm vụ" — đây là bước ĐẦU TIÊN của mọi vòng lặp thưởng trong game. Không có system này, "làm task ngoài đời → nhận thưởng" (Pillar 1) không có cửa vào.

## Player Fantasy

**Chọn task**: Bé mở tab "Nhiệm vụ", tap "+". Không phải một cái form khô khan — mỗi category có icon riêng, quest framing riêng ("Nạp trí tuệ cho Mochi" cho học bài). Bé thấy những lựa chọn preset quen thuộc (đã làm nhiều lần), hoặc gõ task riêng của mình. Đây là khoảnh khắc bé *chọn* — không ai ép, chính bé quyết định hôm nay làm gì để Mochi vui.

**Tap "Đã xong!"** (bề mặt này đã có player fantasy riêng ở Task Library #8 — không lặp lại): đây là nơi khoảnh khắc đó xảy ra trên màn hình — hạt giống rơi vào túi, Mochi nhảy BOUNCING (Seed Buffer #10). GDD này là sân khấu cho khoảnh khắc đó, không viết lại nó.

**Nhìn pending list**: Bé quay lại tab này để ngắm những hạt giống đang chờ — không phải lo lắng "bao giờ được duyệt," mà là sự háo hức có hình dạng: *"Mình có 2 hạt giống đang chờ nở. Bố về là mình được xu ngay!"* Danh sách này là bằng chứng hữu hình của việc bé đã làm — nhìn vào là thấy công sức của chính mình.

**Xem Task History**: Vài ngày sau, bé lướt xuống thấy: "Quét nhà — Đã duyệt ✓", "Học bài — Đã duyệt ✓", một chuỗi liên tiếp. Đây không phải để khoe (đó là social layer, Phase 2) — đây là để BÉ tự thấy: *"Mình đã làm được nhiều thế này trong tuần qua."* Pillar 1 hiện rõ nhất ở đây: không phải ai nói bé giỏi, mà chính list này là bằng chứng không thể giả.

**Cảm xúc chung**: Đây là nơi effort thật của bé được ghi nhận, hiển thị, và trở thành động lực cho task tiếp theo — một vòng lặp tự củng cố không cần ai nhắc nhở.

## Detailed Design

### Core Rules

1. **Screen structure**: `/child/tasks` là 1 màn hình scrollable với 2 sections: **"Đang chờ"** (pending, mặc định expanded, ở trên) và **"Lịch sử gần đây"** (history, 30 ngày, collapsible/ở dưới). Không có route riêng cho history — cùng 1 route theo Main Navigation Shell (#17)'s route table. `/child/tasks/new` là sub-screen riêng cho task creation.

2. **Pending section**: Renders từ `pendingTasksProvider` (Task Library #8, cùng data với Seed Buffer #10's `seedCount`). **Provider trả về newest-first** (`orderBy('submittedAt', descending: true)` — implementation thật của #8, không phải giả định). Task Management UI (#19) **reverse client-side** (`.reversed.toList()` hoặc tương đương) để hiển thị **oldest-first** trong UI — task chờ lâu nhất xứng đáng nổi bật nhất, không bị chôn dưới task mới hơn. Không sửa provider chung (Parent Dashboard UI #21 cũng dùng provider này, không phụ thuộc order cụ thể). Mỗi card: category icon, task title, "Đang chờ bố/mẹ approve...". **Capped tại 10** (Seed Buffer #10's Tuning Knob) — nếu N>10, hiển thị 10 task CŨ NHẤT (sau khi reverse) + "+[N-10] more". Khi **approve** xảy ra: card đó chạy **local burst animation** (scale + fade, đúng 1.2s theo Seed Buffer's duration spec) rồi bị remove — KHÔNG particle bay sang xu counter ở app bar; counter (owned by #17) tự update qua Riverpod stream riêng, không cần cross-widget choreography. Khi **reject** xảy ra: card đó chạy **Seed Wither animation** (Seed Buffer #10's spec verbatim — fade out + puff of smoke, 0.6s, desaturate to grey trước khi fade) rồi bị remove — đây là screen sở hữu render Wither animation, vốn chưa có owner trước GDD này.

3. **Multiple approvals/rejections arrive at once (staggered)**: Nếu N tasks được approve HOẶC reject trong lúc bé không mở app (background/offline), khi mở lại: N cards chạy animation tương ứng (burst 1.2s cho approved, wither 0.6s cho rejected — mixed trong cùng queue, mỗi card dùng animation đúng theo status của nó) **staggered 0.5s mỗi cái** (Seed Buffer #10's Tuning Knob) theo thứ tự `submittedAt` tăng dần (sau khi reverse, cùng order với Core Rule 2) — không đồng loạt. Đây là trách nhiệm của GDD này (Seed Buffer's Edge Case đã delegate rõ).

4. **History section**: Renders từ `taskHistoryProvider` (Task Library #8, đã có sẵn — 30 ngày, `status IN ['approved','rejected']`). Mỗi row: category icon, task title, ngày, và trạng thái rõ ràng bằng icon+text (✓ "Đã duyệt" màu Mint Breeze / ✕ "Không duyệt" màu neutral peach-grey, KHÔNG dùng đỏ — colorblind safety). Không có animation đặc biệt — đây là dữ liệu tĩnh nhìn lại, không phải sự kiện realtime.

5. **Task creation flow** (`/child/tasks/new`): 2 bước —
   - **Bước 1 — chọn category**: 5 icon lớn (study/arts/chores/sport/helping), mỗi icon có quest framing text (Task Library #8's category table).
   - **Bước 2 — chọn task cụ thể**: hiển thị preset chips cho category đã chọn — gồm 5 built-in presets (Task Library #8) VÀ bất kỳ `customTasks` template nào (Parent Dashboard UI #21) có `categoryId` khớp và `targetChildId` = bé hiện tại. Nếu bé không thấy chip nào phù hợp: text field "Tự nhập tên nhiệm vụ" luôn có sẵn ở cuối danh sách chip.
   - **Xác nhận**: tap "Đã xong!" → tạo `tasks/{taskId}`: `title` (từ chip đã chọn hoặc tự nhập), `categoryId`, `xuReward`/`energyReward` (từ category table, KHÔNG cho bé tự nhập số — bảo vệ economy giống Reward Integrity Guard đã có ở #8), `status: 'pending'`, `submittedAt: now`.

6. **Back navigation**: `/child/tasks/new` back-press → `/child/tasks` (đã fix ở Main Navigation Shell #17's AC-12 — GDD này tuân theo, không redefine).

7. **Seed Badge (nav tab decoration) — KHÔNG thuộc scope GDD này**: hiển thị count trên icon tab "⚡ Nhiệm vụ" là data-driven bởi `seedCountProvider` (Seed Buffer #10) nhưng render bởi Main Navigation Shell (#17)'s tab bar widget, không phải nội dung màn hình này. **Đã propagate** — xem #17's Downstream table.

### States and Transitions

```
/child/tasks (mặc định khi vào tab "Nhiệm vụ")
      │
      ├── Section: Đang chờ (pendingTasksProvider, cap 10 + "+N more")
      │     └── [approve xảy ra] → local burst animation (1.2s) → card removed
      │           (nhiều cards → stagger 0.5s mỗi cái theo submittedAt)
      │
      ├── Section: Lịch sử gần đây (taskHistoryProvider, 30 ngày)
      │     └── static rows, ✓/✕ icon + text, không animation
      │
      └── tap FAB "+" → /child/tasks/new
                  │
                  ├── Bước 1: chọn category (5 icons)
                  ├── Bước 2: chọn preset chip (built-in + customTasks) HOẶC "Tự nhập"
                  ├── tap "Đã xong!" → tasks/{taskId} created (status: pending)
                  │     → quay về /child/tasks, card mới xuất hiện trong Đang chờ
                  └── back-press → /child/tasks (không tạo task)
```

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Task Library (#8) | IN/OUT | 5 categories + presets; reads/writes `tasks/{taskId}` | `pendingTasksProvider`, `taskHistoryProvider`, task creation write |
| Seed Buffer (#10) | IN | `seedCount`, staggered bloom animation ownership | `seedCountProvider` (badge only, not this screen's content) |
| Parent Dashboard UI (#21) | IN | `customTasks` templates cho category picker | `families/{parentId}/customTasks` (filtered by `targetChildId`) |
| Main Navigation Shell (#17) | IN/OUT | Hosts `/child/tasks`, `/child/tasks/new`; owns tab badge rendering (data từ #10) | `StatefulShellRoute` (go_router) |

## Formulas

Task Management UI hầu như không có formula riêng — reward values thuộc Task Library (#8), animation constants thuộc Seed Buffer (#10). Nhưng có **một giá trị derived thật**: tổng thời gian của staggered catch-up animation (Core Rule 3) — đây là composition của #10's 2 constants, GDD này là nơi compose nó nên formula thuộc đây.

**Staggered Catch-Up Animation Duration**

```
total_duration = burst_duration + (N - 1) × stagger_interval
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Số cards đang animate | `N` | int | 1–10 | Số task cards trong 1 catch-up sequence — bao gồm CẢ approved (burst) VÀ rejected (wither) resolutions, mixed trong cùng queue; hard-capped bởi pending-list cap, Seed Buffer #10's Tuning Knob |
| Burst duration | `burst_duration` | float (giây) | 1.2 (cố định, #10) | Thời gian 1 card's scale+fade burst |
| Stagger interval | `stagger_interval` | float (giây) | 0.5 (cố định, #10) | Khoảng cách bắt đầu giữa 2 cards liên tiếp, theo thứ tự `submittedAt` |
| Tổng thời gian | `total_duration` | float (giây) | 1.2–5.7 | Từ lúc card đầu bắt đầu đến lúc card cuối kết thúc |

**Output Range**: 1.2s (N=1, không cần stagger) đến 5.7s (N=10, cap tối đa từ #10 — formula không cần tự clamp vì N không bao giờ vượt 10).

**Example**: Bé mở app lại sau khi offline, 4 tasks đã được approve (N=4) → `total_duration = 1.2 + (4-1) × 0.5 = 2.7s`. Tại N=10 (max): `1.2 + 9 × 0.5 = 5.7s` — mốc trần để QA biết catch-up sequence dài nhất có thể kéo dài bao lâu.

**Test precision note**: `1.2` và `0.5` không phải giá trị binary-float chính xác — unit test so sánh `total_duration` phải dùng sai số floating-point **±0.001s**, không phải exact equality (`expect(value, 2.7)` có thể fail sai do float rounding, không phải logic bug). Đây là test cho **giá trị formula tính toán** (deterministic, LOGIC-tier, `tests/unit/`) — KHÔNG phải test cho animation playback thực tế trên màn hình, vốn thuộc "Visual/Feel" (không automate được, theo `.claude/docs/coding-standards.md`'s "What NOT to Automate").

**Ghi chú**: 30-ngày history window (`submittedAt >= now - 30d`) là data-query boundary, không phải computed formula — xử lý ở Edge Cases, không ở đây.

## Edge Cases

1. **Không có pending task**: "Đang chờ" section hiển thị empty state ("Chưa có nhiệm vụ nào đang chờ") + FAB "+" vẫn khả dụng.

2. **Không có task history trong 30 ngày**: "Lịch sử gần đây" section hiển thị empty state riêng ("Chưa có lịch sử gần đây") — không nhầm với pending empty state.

3. **Task được approve hơn 30 ngày trước**: Biến mất khỏi History section (query filter `submittedAt >= now-30d`) — đây là hành vi cố ý (recent-glance feature, không phải permanent archive), không phải bug. Task vẫn tồn tại trong Firestore, chỉ không hiện ở UI này.

4. **Catch-up animation bị interrupt** (bé navigate đi giữa sequence, ví dụ tap sang tab khác): **Cơ chế detect interrupt**: Main Navigation Shell (#17) dùng `StatefulShellRoute` — các tab branch KHÔNG bị dispose khi switch tab (giữ mounted, theo #17's Tab persistence contract), nên route disposal KHÔNG fire khi bé chuyển tab. Task Management UI lắng nghe #17's `activeChildBranchIndexProvider` (Riverpod `ref.listen`, đã propagate vào #17) — khi giá trị provider này khác branch index của Tasks tab (index 1), đó chính là interrupt signal, KHÔNG dựa vào widget lifecycle (`dispose()`/`RouteObserver`, vốn không fire cho sibling-branch switch trong `StatefulShellRoute`).
   - Sequence bị discard khi interrupt fire — animation state không resume khi quay lại.
   - **Card đang mid-animation đúng lúc interrupt fire được cho phép hoàn thành animation của nó một cách tự nhiên (không cắt ngang)** — cắt ngang giữa animation trông như lỗi/glitch.
   - Các cards CHƯA bắt đầu animate trong queue (nhưng data đã đổi status) sẽ biến mất khỏi pending list ngay lập tức không có animation riêng (snap-remove) khi bé quay lại — tránh phức tạp việc lưu/resume animation state cho toàn bộ queue.

5. **Approval mới đến trong lúc catch-up sequence đang chạy**: Card mới được APPEND vào cuối queue hiện tại (N tăng lên) — không restart sequence từ đầu, không tạo sequence thứ 2 song song.

6. **Bé tap "Đã xong!" 2 lần liên tiếp nhanh**: Button disable ngay khi tap đầu (cùng pattern defense-in-depth như Parent Dashboard UI #21) — tránh tạo 2 task documents trùng từ 1 hành động.

7. **Bé để trống "Tự nhập tên nhiệm vụ"**: Nút "Đã xong!" disabled cho đến khi có ít nhất 1 ký tự non-whitespace — cùng pattern validation như #21's custom task title.

## Dependencies

**Upstream (Task Management UI cần — hard dependencies):**
- **Task Library (#8)** ✅ Approved — `pendingTasksProvider`, `taskHistoryProvider` (đã có sẵn), 5 category values + presets, task creation write contract
- **Seed Buffer (#10)** Designed (pending review) — `seedCount`/`seedCountProvider`, pending-list cap (10), burst/stagger animation constants (1.2s/0.5s)
- **Parent Dashboard UI (#21)** ✅ Approved — `customTasks` collection, filtered bằng `targetChildId` cho category picker
- **Main Navigation Shell (#17)** ✅ Approved — hosts `/child/tasks`, `/child/tasks/new`; owns tab badge rendering (data từ #10); owns `activeChildBranchIndexProvider` (mới — propagated, xem Edge Case 4)

**Downstream**: không có — leaf UI system.

**Bidirectional check**: Task Library (#8), Seed Buffer (#10), Main Navigation Shell (#17), Parent Dashboard UI (#21), và Data Persistence (#4) đều đã reference "#19"/"Task Management UI" đúng cách. **Tất cả propagation đã done**: #17's tab badge ownership note + `activeChildBranchIndexProvider`; #21's "customTasks picker provisional" Open Question đã close.

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| Custom title max length (task creation) | 50 ký tự | 30–100 | Bị cắt trên card, tràn UI | Không đủ diễn đạt tên task | Cùng convention với Parent Dashboard UI #21's custom task title |
| History section default state | Collapsed | Collapsed/Expanded | Bé phải cuộn nhiều để thấy pending (section chính) | — | Pending là primary content, History là secondary — collapsed giữ pending nổi bật |

**Không định nghĩa lại**: 30-ngày history window thuộc Task Library (#8) — hardcoded trong `taskHistoryProvider`. Pending-list cap (10) và animation constants (1.2s burst / 0.5s stagger) thuộc Seed Buffer (#10) Tuning Knobs. GDD này chỉ tiêu thụ, không sở hữu các giá trị đó.

## Visual/Audio Requirements

**Shape language & tone (mở đầu)**

Toàn bộ screen dùng chung shape grammar với Parent Dashboard UI (#21) — corner radius ≥12dp, không sharp corner, không đỏ/đen thuần (Art Bible Section 3, Section 4) — đây là điểm KHÔNG lệch. Nhưng khác với #21's chủ động "subtract" khỏi expressive vocabulary (silent, no bounce, no particle), Task Management UI là nơi P3 — Expressive Animation (Art Bible Section 1) được áp dụng đầy đủ: category icon ở Bước 1 là "Hero" shape (Art Bible Section 3's Hero vs Supporting table — circles/large ovals draw the eye) — 72dp circular tap target, filled solid pastel khi selected (theo Section 3's icon rule "outlined khi rest, filled solid pastel khi active"). Card/chip là "Supporting" shape (Section 3 explicitly lists "task cards" here), radius 16–20dp (upper end của Section 3's 12–20dp range, vì đây vẫn là bề mặt gần "reward" hơn Parent Dashboard's plain rows).

**Nguyên tắc tổng quát**: hai màn hình là "hai phòng trong 1 căn nhà" — cùng palette token, cùng corner-radius rule, nhưng #21 chủ động im lặng (dùng `easeInOut`, không particle, không sound) còn #19 (GDD này) được phép "nói to" hơn (elastic/bounce, glint, chime) vì đây là màn hình mà effort của bé được celebrate. Nếu sau này có ai thấy #19 "quá tưng bừng" so với #21 và muốn làm phẳng nó cho giống — đó là SAI, hai tone này là chủ ý.

1. **Category icon selection (Bước 1, task creation)**
   - Rest: icon outline 2–3px stroke, màu category tương ứng (Task Library #8's mapping: `study`=Mint Breeze, `arts`=Lavender Soft, `chores`=Peach Glow, `sport`=Honey Gold, `helping`=Cloud White+border, `custom`=neutral), label dưới icon màu warm-brown secondary text, quest-framing text ẨN.
   - Selected: icon fill chuyển solid pastel (theo màu category), scale `1.0→1.08` spring bump (~150ms), quest-framing text (Task Library's text, ví dụ "Nạp trí tuệ cho Mochi") expand-in dưới icon (fade+slide-up nhẹ, 200ms).
   - Tap target: 72dp (trên mức tối thiểu 48dp — đây là hero moment của flow, xứng đáng target lớn).
   - Icon chưa chọn: dim nhẹ (opacity ~85%) sau khi 1 icon đã được chọn, hướng mắt bé — Gestalt figure-ground.

2. **Preset chip selection (Bước 2)**
   - Rest: pill shape, radius ≥12dp, Cloud White fill, warm-brown outline + text.
   - Selected: fill chuyển màu category đã chọn ở Bước 1 (visual thread nối 2 bước), text luôn dùng Primary text (`#3D2B1F`, warm dark brown) — KHÔNG BAO GIỜ trắng, theo quyết định Art Bible §"Text Colors" (sửa 2026-07-13, contrast audit: chữ trắng fail ở mọi màu category pastel) — scale `1.0→1.05` spring bump.
   - "Tự nhập tên nhiệm vụ" luôn ở cuối, border DASHED (khác solid của preset chips) — báo hiệu "gõ vào" khác "tap chọn" bằng shape, không chỉ text.
   - Header Bước 2 hiển thị lại quest-framing text đã chọn ở Bước 1 (dạng nhỏ hơn: "Bạn chọn: [quest framing]") — giữ continuity cảm xúc qua 2 bước.

3. **Task creation confirm ("Đã xong!")**
   - Tap → button disable ngay (Edge Case 6) → route về `/child/tasks` → card mới xuất hiện trong "Đang chờ" với fade+slide-in nhẹ (200ms, ease-out) — không bounce ở đây; đây là "arrival," không phải "reward" — bounce được để dành cho burst lúc approve (mục 4).

4. **Pending card approve burst** — echo của Seed Buffer's Seed Bloom (#10), KHÔNG phải particle clone:
   - Duration: 1.2s (khớp #10's bloom duration budget, Core Rule 2 đã fix giá trị này).
   - Motion: scale `1.0→1.06→0.0` với `elasticOut`-flavored overshoot (KHÔNG dùng `easeInOut` — điểm tương phản trực tiếp với #21's flash+collapse).
   - Glint: 1 icon ✓ nhỏ, màu Honey Gold `#FFD060` (Art Bible Section 4 — canonical hex; `seed-buffer.md` đã được fix để khớp giá trị này), crossfade-in 200ms ở giữa card khi bắt đầu scale, cùng fade với card.
   - KHÔNG particle bay ra khỏi card (giữ nguyên simplification đã quyết ở Core Rule 2) — glint + scale/fade là toàn bộ vocabulary, animation ở lại trong bounding box của card.
   - Sound: reuse Seed Buffer's bloom chime (2–3 note ascending, 60% SFX volume, #10's spec) — #21 im lặng hoàn toàn; sound ở đây là tín hiệu identity chủ ý.

5. **Staggered catch-up sequence** (N cards, Core Rule 3): mỗi card chạy animation y hệt mục 4, chỉ khác thời điểm bắt đầu (stagger 0.5s/card, theo #10's Tuning Knob) — không có treatment riêng.

6. **History rows** (static, không animation — Core Rule 4): category icon nhỏ (24×24px, cùng mapping mục 1), task title, ngày (warm medium-brown secondary text), trạng thái icon+text — ✓ "Đã duyệt" Mint Breeze `#A8E6CF` / ✕ "Không duyệt" neutral peach-grey (không đỏ). Không glow/scale — dữ liệu tĩnh không nên "sống lại" mỗi lần cuộn tới.

7. **Empty states**
   - Pending empty: text "Chưa có nhiệm vụ nào đang chờ" + Mochi IDLE sprite (asset có sẵn từ Pet State Machine #6, không cần art mới) đặt cạnh/trên text, ~64×64px.
   - History empty: text "Chưa có lịch sử gần đây" + cùng Mochi IDLE sprite, nhỏ hơn (~48×48px — section này collapsed-by-default/secondary). Cùng asset, khác text — tránh nhầm 2 empty state (Edge Case 2).
   - Không commission illustration riêng cho mỗi section — tái dùng 1 sprite sẵn có, giữ scope tương xứng "not a hero visual moment."

8. **Loading state** (initial fetch `pendingTasksProvider`/`taskHistoryProvider`): shimmer/skeleton placeholder, retint theo palette child-side (Cream Ivory `#FFFDF0` base, Peach Glow `#FFCBA4` shimmer sweep) — tái dùng #21's pattern (không character-animated loader), chỉ đổi màu để đúng "phòng."

**Motion curve constraint (toàn màn hình)**: elastic/spring overshoot ĐƯỢC PHÉP ở selection states và burst (mục 1, 2, 4, 5) — ngôn ngữ "expressive, playful" P3 mà #21 chủ động không dùng. Transition thường (route change, mục 3) vẫn dùng `easeOut` tiêu chuẩn — không phải MỌI thứ trên màn hình này bounce, chỉ khoảnh khắc "bé chủ động chọn" hoặc "reward xảy ra."

**Audio**: burst (mục 4/5) dùng chime đã có ở Seed Buffer #10. Category/chip selection (mục 1/2) dùng haptic/tap feedback tiêu chuẩn hệ thống, KHÔNG thêm SFX riêng — giữ chime của burst là âm thanh "đặc biệt" duy nhất trên màn hình, tương phản có chủ ý với #21's im lặng hoàn toàn (silence there vs. quiet-but-not-silent-with-one-special-sound here).

**Quest-framing text — visual home**: chỉ xuất hiện ở Bước 1 (icon selected, expand-in) và lặp lại dạng rút gọn ở header Bước 2 ("Bạn chọn: [quest framing]"). KHÔNG lặp lại trên pending card hay history row — nhiệm vụ của text này là làm hành động CHỌN có ý nghĩa; lặp lại mọi nơi biến nó thành wallpaper và chiếm chỗ trên card đã dày thông tin (category icon + title + trạng thái).

📌 **Asset Spec** — Visual/Audio requirements đã defined. Chạy `/asset-spec system:task-management-ui` sau khi art bible được approved để tạo per-asset spec và generation prompts. Assets mới theo convention: `ui_icon_category_[study|arts|chores|sport|helping|custom]_outline.svg` / `_filled.svg` (nếu chưa có từ #8's spec), `ui_chip_preset_[default|selected].png`, `char_mochi_idle_empty_state_small.png` (crop riêng nếu cần size khác từ sprite gốc).

## UI Requirements

Task Management UI đóng góp 3 surfaces trên 2 route (Main Navigation Shell #17):
1. **`/child/tasks`** — 2 sections trên 1 màn hình scrollable: "Đang chờ" (pending, mặc định expanded) và "Lịch sử gần đây" (history, collapsible)
2. **`/child/tasks/new`** — 2-step flow: chọn category → chọn preset/customTasks chip hoặc tự nhập
3. Seed Badge (tab decoration) — **KHÔNG thuộc scope GDD này**, render bởi #17, data từ Seed Buffer #10

📌 **UX Flag — Task Management UI**: Cần `/ux-design` spec trước khi viết epics — đặc biệt: (1) staggered catch-up animation timing (LOGIC-tier, cần wireframe rõ trước khi implement), (2) 2-step category→chip flow cần validate với target audience (trẻ 6-10 tuổi) rằng flow không quá nhiều bước, (3) visual thread giữa category color (Bước 1) và chip color (Bước 2) cần prototype để confirm dễ hiểu với trẻ nhỏ, không chỉ đẹp trên paper.

## Acceptance Criteria

**Test tier note**: GDD này chủ yếu là UI-type (advisory gate — manual walkthrough hoặc interaction test) per `.claude/docs/coding-standards.md`'s Story Type table. Bốn khu vực cần tier BLOCKING: (1) **Logic-type** — staggered catch-up animation sequence (Core Rule 3 + Formulas + Edge Cases 4/5, bao gồm cả approve VÀ reject resolutions mixed trong cùng queue), state machine input-dependent branching cùng hạng với Parent Dashboard UI (#21)'s FCM banner defer/coalesce logic. (2) **Logic-type** — formula `total_duration` cần unit test riêng verify N=1/4/10, sai số floating-point ±0.001s. (3) **Logic/Integration-type** — reward derivation trong task creation (Core Rule 5): sai giá trị corrupt economy mà không có triệu chứng UI quan sát được, cùng hạng rủi ro với #21's `targetChildId` case. (4) **Logic/Integration-type** — double-tap write-count verification (Edge Case 6): "chỉ 1 document" không có triệu chứng UI phân biệt được với "vô tình tạo 2 document."

**Core Rule 1 — Screen structure** `[UI]`
- **GIVEN** bé mở tab "Nhiệm vụ" lần đầu, **WHEN** `/child/tasks` render, **THEN** cả 2 section "Đang chờ" (expanded mặc định) và "Lịch sử gần đây" (collapsible) đều hiển thị trên cùng 1 route — không có route riêng cho history.
- **GIVEN** bé tap FAB "+", **WHEN** app navigate, **THEN** route đổi đúng sang `/child/tasks/new`.

**Core Rule 2 — Pending section** `[UI]`
- **GIVEN** `pendingTasksProvider` trả về N task (test N=0, N=1, N=10, N=13) theo thứ tự provider thật (`descending: true`, newest-first), **WHEN** `/child/tasks` render, **THEN**: bé thấy card sort theo oldest-first (đã reverse client-side); N≤10 → hiển thị đúng N card; N>10 → hiển thị đúng 10 task CŨ NHẤT (sau reverse) + text "+[N-10] more".
- **GIVEN** 1 card đang hiển thị, **WHEN** approve xảy ra trong lúc bé đang xem màn hình, **THEN** card đó chạy burst animation (scale+fade, 1.2s) rồi bị remove khỏi list — không particle bay sang app bar.
- **GIVEN** 1 card đang hiển thị, **WHEN** reject xảy ra trong lúc bé đang xem màn hình, **THEN** card đó chạy Seed Wither animation (fade+puff, 0.6s, desaturate to grey) rồi bị remove — animation khác biệt rõ với burst (không nhầm approve/reject bằng animation).

**Core Rule 3 — Staggered catch-up on reopen** `[LOGIC]`
- **GIVEN** bé mở app sau khi N task đã được approve/reject (mixed) trong lúc app đóng/background (test: N=4 toàn approve; N=4 toàn reject; N=4 mixed 2 approve+2 reject), **WHEN** `/child/tasks` render, **THEN** N card chạy animation ĐÚNG THEO status của từng card (burst cho approved, wither cho rejected) staggered đúng 0.5s giữa mỗi card bắt đầu, theo thứ tự `submittedAt` tăng dần (sau reverse) — verify bằng animation start-offsets: 0×0.5, 1×0.5, ..., (N-1)×0.5 giây kể từ t=0.
- **GIVEN** N=1, **THEN** không có stagger — chỉ 1 animation chạy ngay (burst hoặc wither tùy status).

**Formula verification — total_duration** `[LOGIC]`
- **GIVEN** N=1, **THEN** `total_duration` = 1.2s (±0.001s).
- **GIVEN** N=4, **THEN** `total_duration` = 2.7s (±0.001s).
- **GIVEN** N=10 (cap tối đa), **THEN** `total_duration` = 5.7s (±0.001s) — mốc trần, không cần test N>10.

**Core Rule 4 — History section** `[UI]`
- **GIVEN** `taskHistoryProvider` trả về M record (test M=0, M=1, M=30+) trong 30 ngày gần nhất, **WHEN** section "Lịch sử gần đây" expand, **THEN** đúng M row hiển thị, mỗi row có category icon, task title, ngày, và trạng thái icon+text đúng màu (✓ Mint Breeze cho approved, ✕ neutral peach-grey cho rejected — không dùng đỏ).
- **GIVEN** section đang collapsed (default state), **WHEN** bé tap để expand, **THEN** M row hiển thị đầy đủ không mất data.

**Core Rule 5 — Task creation flow** `[UI]` (form/flow) + `[LOGIC/INTEGRATION]` (reward derivation, tagged riêng — xem bullet cuối)
- **GIVEN** bé ở Bước 1, **WHEN** màn hình render, **THEN** đúng 5 category icon hiển thị (study/arts/chores/sport/helping), mỗi icon có quest framing text riêng. `[UI]`
- **GIVEN** bé chọn 1 category ở Bước 1, **WHEN** chuyển sang Bước 2, **THEN** preset chips hiển thị đúng: 5 built-in presets của category đó (#8) VÀ bất kỳ `customTasks` template nào có `categoryId` khớp và `targetChildId` = bé hiện tại — không hiện template của bé khác trong cùng gia đình. `[UI]`
- **GIVEN** không chip nào phù hợp, **THEN** text field "Tự nhập tên nhiệm vụ" luôn hiển thị ở cuối danh sách chip. `[UI]`
- **GIVEN** bé chọn 1 preset chip HOẶC nhập tên hợp lệ, **WHEN** tap "Đã xong!", **THEN** document mới được tạo tại `tasks/{taskId}` với đúng `title`, `categoryId`, `status: 'pending'`, `submittedAt: now`. `[UI]`
- **GIVEN** category đã chọn ở Bước 1, **WHEN** document được tạo, **THEN** `xuReward` và `energyReward` trong document PHẢI khớp chính xác giá trị category table (#8) — verify bằng đọc lại document sau khi ghi (read-back check), không chỉ quan sát UI, vì UI không hiển thị giá trị reward tại thời điểm submit. `[LOGIC/INTEGRATION]` — BLOCKING, `tests/integration/task-management-ui/`.
- **GIVEN** màn hình tạo task, **THEN** không có input field nào cho bé tự nhập số reward — regression check chống feature creep vô tình mở lỗ hổng economy. `[UI]`

**Core Rule 6 — Back navigation** `[UI]`
- **GIVEN** bé ở `/child/tasks/new`, **WHEN** back-press (không submit), **THEN** app quay về `/child/tasks` theo #17's AC-12 — chỉ verify wiring đúng route, không redefine hành vi.

**Core Rule 7 — Seed Badge**: không thuộc scope GDD này — không có AC ở đây (xem Main Navigation Shell #17).

**Edge Case 1 — Empty pending list** `[UI]`
- **GIVEN** 0 pending task, **THEN** "Đang chờ" section hiển thị empty state "Chưa có nhiệm vụ nào đang chờ", FAB "+" vẫn tap được.

**Edge Case 2 — Empty task history** `[UI]`
- **GIVEN** 0 task history trong 30 ngày, **THEN** "Lịch sử gần đây" hiển thị empty state riêng "Chưa có lịch sử gần đây" — khác text với Edge Case 1.

**Edge Case 3 — Task approved hơn 30 ngày trước** `[UI]`
- **GIVEN** 1 task có `submittedAt` cũ hơn 30 ngày và `status: approved`, **THEN** task đó KHÔNG hiện trong "Lịch sử gần đây" — task vẫn tồn tại Firestore, chỉ verify UI không hiển thị nó.

**Edge Case 4 — Catch-up animation bị interrupt** `[LOGIC]`
- **GIVEN** sequence catch-up chưa bắt đầu bất kỳ card nào, **WHEN** bé navigate đi rồi quay lại `/child/tasks`, **THEN** tất cả N card biến mất khỏi pending list ngay lập tức không animation (snap-remove toàn bộ).
- **GIVEN** 1 card đang mid-animation đúng lúc bé navigate đi, **WHEN** bé quay lại, **THEN** card đó đã hoàn thành animation của nó một cách tự nhiên (không bị cắt ngang giữa animation) trước khi biến mất; các card khác chưa bắt đầu animate snap-remove ngay.

**Edge Case 5 — Approval mới đến giữa sequence** `[LOGIC]`
- **GIVEN** catch-up sequence đang chạy với N card (chưa hoàn tất), **WHEN** 1 approval mới đến giữa lúc đó, **THEN** card mới được append vào cuối queue hiện tại (N tăng thành N+1) — không restart sequence từ đầu, không tạo sequence thứ 2 chạy song song.

**Edge Case 6 — Double-tap "Đã xong!"** `[UI]` (button disable) + `[LOGIC/INTEGRATION]` (write-count verification, tagged riêng)
- **GIVEN** bé tap "Đã xong!", **WHEN** tap lần 2 xảy ra trong lúc request đầu chưa resolve, **THEN** button đã disabled ngay sau tap đầu. `[UI]`
- **GIVEN** double-tap xảy ra (kể cả nếu button-disable bị bypass do race), **WHEN** verify sau đó, **THEN** đúng 1 document `tasks/{taskId}` được tạo — verify bằng đọc lại collection, không chỉ quan sát UI (giống lý do Core Rule 5's reward derivation cần tier này: "chỉ 1 document" không có triệu chứng UI nào phân biệt với "vô tình tạo 2 document"). `[LOGIC/INTEGRATION]` — BLOCKING, `tests/integration/task-management-ui/`.

**Edge Case 7 — Empty custom title** `[UI]`
- **GIVEN** "Tự nhập tên nhiệm vụ" trống hoặc chỉ whitespace, **THEN** "Đã xong!" disabled; **GIVEN** ≥1 ký tự non-whitespace, **THEN** enabled.

## Open Questions

- **`customTasks` template bị bố mẹ sửa/xóa đúng lúc bé đang xem picker** (từ qa-lead's review): bố mẹ không có delete feature trong Parent Dashboard UI (#21)'s scope hiện tại, nên tần suất rất thấp — nhưng nếu #21 thêm delete ở Alpha, cần xử lý race này. Defer đến khi #21 thêm delete feature.
- **2-step flow có quá nhiều bước với trẻ 6-10 tuổi không?** Cần playtest/prototype trước khi finalize UX spec (đã note ở UX Flag).
- **Task History — hiển thị bao nhiêu chi tiết?** Hiện tại: category icon + title + ngày + trạng thái. Có cần hiển thị xu/energy đã nhận không (thêm động lực nhìn lại)? Cân nhắc ở `/ux-design` pass.
