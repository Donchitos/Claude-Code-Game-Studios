# Shop & Reward UI

> **Status**: Approved ✅ (reviewed 2026-07-06 — NEEDS REVISION found, all 4 findings fixed same day). All 8 required + 3 optional sections complete, review mode: lean
> **Author**: User + Agents
> **Last Updated**: 2026-07-11 (ADR-0011 GDD sync — onAnimationComplete interface resolved)
> **Implements Pillar**: Pillar 1 — Kỷ luật Thật → Phần thưởng Thật

## Overview

Shop & Reward UI là màn hình `/child/shop` (Tab 3, Main Navigation Shell #17) — bề mặt trình bày duy nhất nơi bé nhìn thấy và tương tác với 3 systems kinh tế đã được thiết kế đầy đủ từ trước: Shop System (#13, danh mục mua bán 5 tab), Gacha/Loot System (#12, rương may mắn), và Currency System (#7, số dư xu). GDD này KHÔNG định nghĩa lại catalog logic, purchase flow, hay loot roll — #13 và #12 đã specify đầy đủ Core Rules, Formulas, Visual/Audio, và UI Requirements cho riêng phần của mình, và cả 2 đều đã đặt 📌 UX Flag chỉ thẳng vào GDD này. Công việc riêng của GDD này là **lớp composition**: cách 2 trải nghiệm rất khác nhau về nhịp điệu (mua sắm — bé quyết định có chủ đích; mở rương — bất ngờ, không kiểm soát) được ghép vào MỘT route mạch lạc, cách bé di chuyển giữa chúng, và cách state hiển thị (xuBalance, chestCount) đồng bộ xuyên suốt cả hai.

**Scope note (MVP, tương tự cách #18 xử lý)**: `game-concept.md`'s MVP Definition (early Draft, 2026-06-25) liệt kê Gacha rương là "KHÔNG trong MVP — thêm sau khi core loop validate", nhưng `systems-index.md` và 2 GDD đã Designed (`gacha-loot.md`, `shop-system.md`) đều coi Gacha là MVP-tier, với Paid Chest đã là 1 entry cố định trong shop catalog. GDD này theo `systems-index.md` + 2 GDD đã tồn tại làm nguồn sự thật hiện tại (game-concept.md là draft sớm, chưa được reconcile) — nghĩa là Chest Badge + Chest Open ceremony LÀ MVP scope của GDD này, không phải defer. Gap giữa 2 tài liệu được flag rõ, không tự quyết định ngầm; ai reconcile `game-concept.md`'s MVP Definition sau này nên biết quyết định này đã được đưa ra ở đây.

Về kiến trúc: route `/child/shop` là 1 Flutter screen thuần (không có Flame canvas — khác #18) chứa `TabController` khớp 5 tab #13 định nghĩa (Tất cả/Trang phục/Trang trí/Đặc biệt/🎲 Rương) cộng 1 full-screen modal riêng cho Chest Open ceremony (#12). Screen đọc 4 provider đã tồn tại (`itemCatalogProvider` #3, `xuBalanceProvider` #7, `inventoryProvider` #13, `chestCountProvider` #12) — không sở hữu provider mới nào cho core economy data, chỉ có thể sở hữu local UI state (tab đang chọn, sheet/modal visibility).

Player-facing: Bé mở tab Shop, thấy ngay ví xu ở đầu và catalog items sắp theo tab đang chọn. Nếu có rương chờ mở, badge 🎲 Rương nhấp nháy mời bé ghé. Mua item hay mở rương đều nằm trong CÙNG một không gian liền mạch — Shop không cảm giác như ghép 2 app con lại với nhau.

## Player Fantasy

**Mua sắm có chủ đích** (fantasy đã có ở Shop System #13 — không lặp lại): GDD này chỉ host catalog, không sở hữu cảm xúc "còn 15 xu nữa thôi".

**Mở rương bí ẩn** (fantasy đã có ở Gacha/Loot #12 — không lặp lại): GDD này chỉ host ceremony, không sở hữu cảm xúc "không biết trong đó có gì".

**Fantasy riêng của GDD này — "mọi con đường đều dẫn về cùng 1 nơi"**: Bé vừa mua Paid Chest xong — khoảnh khắc chuyển tiếp từ "vừa tiêu xu" sang "sắp được mở rương" phải cảm giác liền mạch, không gián đoạn — không phải "thoát Shop, vào 1 màn hình khác hoàn toàn rồi tự quay lại". Tương tự, bé vừa mở rương free (từ milestone task) xong, muốn xem luôn "vậy giờ mình đủ xu mua gì chưa" — quay lại catalog phải ngay tắc thì, không cần navigate qua nhiều bước. Shop và Rương KHÔNG phải 2 tính năng tách biệt bé phải "nhớ đi đâu" — cả hai là MỘT con đường dẫn về cùng 1 đích: Mochi đẹp hơn. Không system nào khác sở hữu cảm giác "kinh tế của mình là MỘT thể thống nhất, không phải nhiều mảnh rời rạc" — đây chỉ xuất hiện khi composition của GDD này đúng.

## Detailed Design

### Core Rules

1. **Screen structure**: `/child/shop` (Main Navigation Shell #17, Tab 3) = 1 Scaffold với: (a) fixed header row ở trên cùng — Xu balance card (từ `xuBalanceProvider` #7, thoả mãn #13's UI Requirement "Xu balance header always visible") + Chest badge card (từ `chestCountProvider` #12) — hiển thị trên MỌI tab, không chỉ riêng tab 🎲; (b) `TabBar` 5 tab đúng như #13 định nghĩa (Tất cả/Trang phục/Trang trí/Đặc biệt/🎲 Rương); (c) `TabBarView` render catalog grid per tab — toàn bộ catalog logic/card design là #13's, GDD này chỉ host layout.

2. **Chest badge tap** (`chestCount > 0`): mở Chest Open ceremony như full-screen modal (`Navigator.of(context, rootNavigator: true).push()` với fullscreen `PageRoute` — **PHẢI dùng root navigator, không phải branch-scoped**, xem Main Navigation Shell #17's Core Rule 1 exception — giữ nguyên `/child/shop` ở underneath, modal dismiss quay lại đúng tab đang xem trước đó). Ceremony content/animation hoàn toàn là #12's spec, GDD này chỉ sở hữu navigation. **Sửa 2026-07-06 (fix Scenario 3 blocker từ review-all-gdds)**: root-navigator push che luôn bottom nav bar — bé KHÔNG thể tap sang tab khác trong lúc ceremony đang mở (Phase 1-3 non-dismissible VÀ Phase 4 dismissible đều bị chặn tab-switch, nhất quán với "modal đang mở" nói chung), tránh race giữa non-dismissible design intent và khả năng tab-switch âm thầm bỏ ngang ceremony.

3. **Chest badge tap** (`chestCount == 0`): badge hiển thị trạng thái muted (không pulse, desaturate về warm neutral `#644A3C` — xem Visual/Audio Requirements, KHÔNG dùng grey thuần vì Art Bible cấm màu xám/đen tuyệt đối) — tap không mở modal, không có hành động nào (im lặng, không cần error/toast — giống pattern "tap ngoài hit area" ở các GDD khác).

4. **Paid Chest purchase → auto-navigate**: Sau khi batch write của Paid Chest purchase commit thành công (xuBalance -=50, chestCount +=1 — owned by #13 Core Rule 4), #13's purchase animation chạy xong trước (không bị cắt ngắn), RỒI GDD này tự động mở luôn Chest Open ceremony (cùng full-screen modal ở Core Rule 2) — không cần bé tap thêm lần nữa để "xem mình vừa mua gì". Trực tiếp phục vụ Player Fantasy — "mọi con đường dẫn về cùng 1 nơi".

5. **Item reveal → Equip prompt (được quyết định ở GDD này)**: Khi Chest Open ceremony kết thúc với kết quả là 1 item (không phải xu bonus/consolation), GDD này hiển thị CÙNG "Equip now?" bottom sheet mà #13 đã thiết kế cho Shop purchase (tái sử dụng UI, không thiết kế lại) — ngay sau item reveal animation (#12's spec), trước khi dismiss modal. Nếu kết quả là xu bonus/consolation: không có equip prompt (không có gì để mua/mặc) — modal tự dismiss về Shop sau khi xu-count-up animation xong.

6. **Live state sync**: Header row (Xu balance + Chest badge) và catalog affordability states (#13's "Còn thiếu N xu") đều là `StreamProvider`-driven — cập nhật real-time nếu approve xảy ra ở device khác trong lúc bé đang ở Shop (cùng pattern đã xác nhận ở #13's Edge Case 1) — không cần bé refresh thủ công.

6b. **"Mặc ngay" → auto-navigate về Pet Room (mới, quyết định 2026-07-06, fix Scenario 2 blocker từ review-all-gdds)**: Khi bé tap "Mặc ngay" trên "Equip now?" prompt — TỪ CẢ 2 ĐƯỜNG (mua item trong Shop HOẶC gacha item reveal) — sau khi equip action (#15) hoàn tất VÀ Firestore write commit, GDD này tự động `context.go('/child/pet-room')` để bé thực sự XEM được SHOWING_OFF animation live. Lý do bắt buộc: Mochi's sprite và SHOWING_OFF spin chỉ tồn tại trong Pet Room Screen (#18)'s FlameGame — nếu bé equip từ Shop tab và ở lại đó, "payoff" mà Pet Equipment (#15)'s Player Fantasy mô tả ("phần thưởng của cả vòng lặp") không bao giờ được witness qua 2 đường equip phổ biến nhất. Nếu bé tap "Để sau" thay vì "Mặc ngay": KHÔNG navigate, ở lại Shop bình thường (hành vi cũ, không đổi).

7. **Không deep-link từ hệ thống khác vào MVP**: Không có GDD nào khác yêu cầu navigate thẳng vào Shop từ bên ngoài (ví dụ: Pet Room's Wardrobe không có nút "mua thêm" dẫn sang Shop) — out of scope, không xây dựng đầu vào suy đoán.

### States and Transitions

```
/child/shop (Tab 3)
      │
      ├── [header, luôn hiển thị] Xu balance card + Chest badge card
      │
      ├── TabBar: Tất cả / Trang phục / Trang trí / Đặc biệt / 🎲 Rương
      │     └── (nội dung mỗi tab — owned by Shop System #13, xem #13's States)
      │
      ├── tap item có thể mua → (owned by #13's purchase flow)
      │     └── mua thành công (item thường) → #13's "Equip now?" prompt (không thay đổi)
      │     └── mua thành công (Paid Chest) → chestCount+=1 → [auto] Chest Open modal mở (Core Rule 4)
      │
      ├── tap Chest badge (chestCount > 0) → Chest Open modal mở (Core Rule 2)
      │     └── ceremony chạy (owned by #12) → kết quả:
      │           ├── item → reveal → "Equip now?" prompt (Core Rule 5) → dismiss → quay lại Shop, đúng tab trước đó
      │           └── xu bonus/consolation → reveal → auto-dismiss → quay lại Shop, đúng tab trước đó
      │
      └── tap Chest badge (chestCount == 0) → không hành động (Core Rule 3)
```

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Shop System (#13) | IN | Catalog content, purchase flow, affordability states, "Equip now?" prompt UI | `itemCatalogProvider`, `xuBalanceProvider`, `inventoryProvider` |
| Gacha/Loot (#12) | IN | Chest count, ceremony animation/content, roll result | `chestCountProvider`, ceremony widget (owned by #12) |
| Currency System (#7) | IN | `xuBalance` display in header | `xuBalanceProvider` |
| Pet Equipment (#15) | OUT | Equip callback khi bé chọn "Equip now?" (từ cả 2 đường: mua hoặc gacha) | equip function (owned by #15) |
| Main Navigation Shell (#17) | IN | Hosts `/child/shop` | `StatefulShellRoute` |

## Formulas

Đại đa số logic toán học của định hướng kinh tế (giá cả, xác suất loot) đã thuộc #13/#12. GDD này chỉ sở hữu 2 formula mới — cả hai đều là **timing handoff contracts** giữa 2 animation đã tồn tại (owned by #13 và #12), không phải thuật toán kinh tế mới.

### Formula 1 — Purchase-to-Ceremony Handoff Timing

`T_total(entryTrigger) = T_purchaseAnim(entryTrigger) + T_modalTransition + T_ceremony`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Entry trigger | `entryTrigger` | enum | `{badge_tap, chest_purchase}` | Core Rule 2 (manual badge tap) với Core Rule 4 (auto sau Paid Chest purchase) |
| Purchase animation duration | `T_purchaseAnim` | int (ms) | 0 (badge_tap) hoặc 800 (chest_purchase) | #13's coins-fly (500ms) + card-pop (300ms); **toast "Mua thành công!" bị suppress cho riêng chest_purchase path** — quyết định của GDD này, không thay đổi #13's default cho item thường |
| Modal transition duration | `T_modalTransition` | int (ms) | 300 (default, safe range 200–400) | Thời gian push full-screen modal — **tham số mới, sở hữu bởi GDD này**, không #13 hay #12 định nghĩa |
| Ceremony duration | `T_ceremony` | int (ms) | 2500 (fixed) | #12's Phase 1–4 tổng thời gian |
| Nav-lock guard | `navLocked` | bool | true/false | **Điều khiển bởi flag hoàn thành animation thật, KHÔNG phải timer đơn thuần** — set `true` ngay khi Paid Chest batch write commit, set `false` khi #13's purchase animation thực sự phát xong (callback `onAnimationComplete`, không phải `Future.delayed(800ms)`). `navLockMs` (0 hoặc 800) chỉ là **fallback ceiling** — nếu vì lý do nào đó (frame drop/jank) animation callback không fire trong `navLockMs + 500ms buffer`, force-unlock để tránh badge bị khóa vĩnh viễn. Lý do: nếu dùng timer thuần, animation chạy chậm hơn dự kiến (jank) sẽ khiến lock hết hạn TRƯỚC KHI animation thật xong — mở lại đúng race mà guard này tồn tại để chặn. **Lifecycle constraint (bắt buộc)**: `navLocked` VÀ fallback timer của nó phải sống trong state SỐNG LÂU HƠN widget animation (ví dụ: 1 Riverpod `StateProvider<bool>`/notifier scoped ở tầng screen, KHÔNG phải local `State` của animation widget) — nếu cả 2 sống chung trong cùng widget và widget đó bị dispose giữa animation (navigate away, hot-reload, v.v.), fallback timer cũng bị dispose theo, không bao giờ fire, và badge bị khóa vĩnh viễn — chính bug mà fallback ceiling này tồn tại để tránh |
| Total wall-clock | `T_total` | int (ms) | 2800 (badge_tap) / 3600 (chest_purchase) | Từ tap/purchase-commit đến ceremony's Phase 4 label hiển thị |

**Worked example (chest_purchase, đường thường)**: t=0 batch commit (chestCount+=1, `navLocked=true`) → 0–500ms coins fly → 500–800ms card pop (toast KHÔNG hiện) → t=800ms animation `onAnimationComplete` fires → `navLocked=false`, `Navigator.push` → 800–1100ms modal transition → t=1100ms ceremony bắt đầu (Phase 1: 1100–1400, Phase 2: 1400–1900, Phase 3: 1900–2600, Phase 4: 2600–3600) → **T_total = 3600ms**.

**Worked example (chest_purchase, đường jank — minh hoạ vì sao cần callback thay vì timer thuần)**: t=0 batch commit, `navLocked=true` → animation bị frame drop, thực tế chạy đến t=950ms mới `onAnimationComplete` (chậm hơn 800ms danh nghĩa) → nếu dùng timer thuần 800ms, badge đã unlock tại t=800ms — nếu bé tap badge ở t=850ms (animation vẫn đang chạy), sẽ trigger `Navigator.push` thủ công TRƯỚC KHI auto-navigate ở t=950ms cũng cố push → double-push. Với callback-driven guard: `navLocked` vẫn `true` cho đến t=950ms thật sự — tap ở t=850ms bị swallow đúng như Edge Case 1, không có double-push.

**Worked example (badge_tap, chestCount có sẵn từ trước)**: t=0 tap badge → 0–300ms modal transition → t=300ms ceremony bắt đầu → **T_total = 2800ms**.

### Formula 2 — Ceremony-to-Equip-Prompt Handoff (item result only)

`T_equipPromptStart = T_ceremony_end + T_revealBuffer`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Reveal buffer | `T_revealBuffer` | int (ms) | 250 (default, safe range 200–300) | Khoảng dừng ngắn sau khi Phase 4's reveal label hiện đầy đủ — để bé kịp đọc tên item trước khi "Equip now?" sheet trượt lên che bớt reveal |
| Equip prompt start | `T_equipPromptStart` | int (ms), relative to ceremony start | `T_ceremony + T_revealBuffer` = 2750 (khi kết quả là item) | Thời điểm "Equip now?" bottom sheet (tái sử dụng UI của #13) bắt đầu trượt lên |

**Áp dụng điều kiện**: Chỉ fire nếu kết quả ceremony là item (không phải xu bonus/consolation) — xem Core Rule 5. Nếu xu bonus: không có equip prompt, modal auto-dismiss sau khi xu-count-up animation (#12's spec) xong.

**Worked example**: ceremony bắt đầu t=0 (relative), Phase 4 kết thúc t=2500ms với kết quả là item → t=2750ms "Equip now?" sheet bắt đầu trượt lên.

## Edge Cases

1. **Bé tap Chest badge trong lúc `navLocked == true`** (ngay sau khi mua Paid Chest, trước khi purchase animation THẬT SỰ hoàn tất — xem Formula 1's callback-driven guard, không phải timer đơn thuần): Tap bị swallow — không mở modal lần 2. Không feedback lỗi — bé sẽ thấy modal tự mở ngay sau đó (khi `onAnimationComplete` fires), cảm giác giống như tap đã "thành công". Guard này đúng ngay cả khi animation chạy chậm hơn dự kiến (jank) vì `navLocked` gắn với callback thật, không phải deadline cố định.

2. **`chestCountProvider` throw error** (mất kết nối/cache failure): Chest badge hiển thị "—" thay vì số (cùng pattern với Main Nav Shell #17's `xuBalanceProvider` error handling) — badge trở thành non-interactive (không biết chính xác `chestCount > 0` hay không, an toàn hơn là giả định sai). Không crash.

3. **App bị minimize giữa Chest Open ceremony đang chạy** (Phase 1–4): Ceremony animation bị discard khi resume — modal hiển thị thẳng kết quả cuối cùng (item/xu đã được roll và xác định trước khi animation bắt đầu chạy, theo #12's kiến trúc client-side-roll-trước-write) — không replay từ đầu, không mất kết quả, không roll lại.

4. **Bé cố dismiss modal (tap ngoài, back button/gesture) trong lúc ceremony đang chạy (Phase 1–3, trước khi kết quả hiển thị)**: Modal KHÔNG dismiss được — non-dismissible cho đến khi kết quả (Phase 4) hiển thị xong. Sau Phase 4 (hoặc sau Equip prompt nếu kết quả là item), modal trở thành dismissible bình thường.

5. **`chestCount` > 1 khi bé mở ceremony** (ví dụ đang có 3 rương chờ): Mỗi lần mở ceremony chỉ tiêu thụ đúng 1 chest (`chestCount -=1`, theo #12's Core Rule 5) — không auto-loop mở hết tất cả. Sau khi dismiss, badge vẫn hiển thị `chestCount` còn lại (ví dụ 2), bé tap lại để mở tiếp từng cái một.

6. **Kết nối mất giữa lúc ceremony đang hiển thị** (sau khi roll đã xảy ra client-side): Kết quả vẫn hiển thị bình thường (roll không cần round-trip server) — batch write (`chestCount--`, item/xu credit) vào Firestore local cache, sync khi online (đã owned by #12's Edge Case "nếu bé offline khi mở chest" — GDD này không định nghĩa lại, chỉ confirm UI render KHÔNG bị gate bởi write acknowledgment; phần batch-write/sync-on-reconnect là AC của #12, không kiểm tra lại ở đây).

7. **Bé mua Paid Chest lần 2 trong khi `navLocked == true` của lần mua thứ nhất** (ví dụ: bé bấm Mua liên tiếp 2 lần trên Paid Chest entry trước khi lần đầu kịp animate xong — giả định #13's existing "Double-tap guard cooldown" chặn double-SUBMIT của cùng 1 lần mua, nhưng không nhất thiết chặn 1 lần mua MỚI sau khi write đầu đã resolve nhưng animation đầu chưa xong): Chỉ CÓ TỐI ĐA 1 auto-navigate pending tại một thời điểm — nếu purchase thứ 2 commit trong khi purchase thứ nhất vẫn đang `navLocked`, `chestCount` vẫn tăng đúng (+1 mỗi lần mua, theo #13/#12's batch write, không bị mất), nhưng KHÔNG có auto-navigate thứ 2 nào được queue. Khi purchase thứ nhất's animation hoàn tất, auto-navigate fires MỘT LẦN — mở ceremony cho 1 chest (tiêu thụ 1, theo Edge Case 5's "một lúc một cái"). Chest còn lại (từ purchase thứ 2) vẫn nằm trong `chestCount`, bé tap badge mở tiếp sau đó như flow bình thường — không có chest nào bị mất, chỉ có UX là "mở lần lượt" thay vì "mở dồn 2 cùng lúc".

8. **Bé cố tap sang tab khác (Pet Room/Tasks) trong lúc Chest Open modal đang mở** (tìm thấy khi review-all-gdds, Scenario 3): Không thể — bottom nav bar bị che bởi root-navigator-pushed modal (xem Core Rule 2), không có gesture nào chạm được tab bar trong lúc modal còn tồn tại. Đây là hệ quả tự động của root-navigator push, không cần logic guard riêng.

**Cơ chế suppression (cụ thể hoá, không để ngầm định)**: `navLocked` là ĐÚNG 1 flag mutable duy nhất, scoped ở tầng screen (cùng nơi sống với Lifecycle constraint ở Formula 1) — KHÔNG phải per-purchase-instance guard riêng cho mỗi animation. Khi purchase thứ 2 commit trong lúc `navLocked` đã `true` từ lần 1, purchase thứ 2 KHÔNG tạo animation/callback instance riêng để chờ auto-navigate của chính nó — nó chỉ tăng `chestCount` qua batch write bình thường (đã owned bởi #13/#12) và không tương tác gì với flag `navLocked` đang có. Chỉ animation của purchase thứ NHẤT (chủ sở hữu flag hiện tại) mới có quyền set `navLocked=false` và trigger auto-navigate — đảm bảo tại mọi thời điểm, tối đa 1 completion-callback nào "sở hữu" flag và có quyền unlock/navigate.

## Dependencies

**Upstream (Shop & Reward UI cần — hard dependencies):**
- **Shop System (#13)** Designed — catalog content, purchase flow, affordability states, "Equip now?" prompt UI
- **Gacha/Loot (#12)** Designed — chest count, ceremony content/animation, roll result
- **Currency System (#7)** ✅ Approved — `xuBalanceProvider` cho header display
- **Pet Equipment (#15)** Designed — equip callback (từ cả 2 đường: mua hoặc gacha reveal)
- **Main Navigation Shell (#17)** ✅ Approved — hosts `/child/shop`

**Downstream**: không có hệ thống nào phụ thuộc vào Shop & Reward UI — giống #18, đây là convergence point (presentation layer), không phải nguồn interface mới.

**Giả định phụ thuộc vào #13 (đã confirm, không cần thay đổi #13)**: Formula 1's `navLockMs`/`navLocked` guard giả định #13's "Double-tap guard cooldown" Tuning Knob (Confirm button disabled "Until write resolves") chặn double-SUBMIT của CÙNG một lần mua Paid Chest. Guard đó không nhất thiết chặn việc mua Paid Chest LẦN 2 (mới) ngay sau khi lần đầu's write đã resolve nhưng animation vẫn đang chạy — trường hợp này được GDD này tự xử lý ở Edge Case 7 (không phải trách nhiệm của #13 phải mở rộng guard).

**Interface với #13 — RESOLVED 2026-07-11 (ADR-0011)**: Formula 1's `navLockMs`/`navLocked` guard subscribe vào `PurchaseAnimationCompleteCallback` (`typedef void Function()`), owned bởi Shop (#13), expose qua `PaidChestCard.onAnimationComplete` — xem ADR-0011 Decision §5 + Key Interfaces. Fired đúng 1 lần, chỉ khi purchase transaction trả `PurchaseResult.success` (KHÔNG fire khi `alreadyProcessed`/`insufficientFunds`/thất bại — transaction luôn chạy xong TRƯỚC KHI animation bắt đầu, theo #13 Core Rule 4's sequence). Áp dụng riêng cho Paid Chest purchase path, không cần cho item thường (item không có ceremony handoff).

**Bidirectional check**: 5/5 upstream GDD đã reference "#20"/"Shop & Reward UI" đúng cách — xác nhận qua grep trước khi viết section này. 1 gap thật đã tìm thấy và fix: `currency-system.md`'s Downstream table thiếu #20 (chỉ có #12/#13/#17) dù #20 đọc `xuBalanceProvider` trực tiếp, không chỉ gián tiếp qua #13 — đã thêm dòng mới vào `currency-system.md`.

**Riverpod providers consumed (không sở hữu, chỉ đọc):**
```dart
// Từ các GDD khác, liệt kê lại để rõ dependency surface
final xuBalanceProvider = ...     // #7
final itemCatalogProvider = ...   // #3 (qua #13)
final inventoryProvider = ...     // #13
final chestCountProvider = ...    // #12
```

**Providers mới sở hữu bởi GDD này (local UI state, không phải economy data)**:
```dart
final selectedShopTabProvider = StateProvider<int>((ref) => 0);
// UI-only — tab đang active trong TabBar, không persist, reset về 0 mỗi khi screen remount
```

## Tuning Knobs

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| `T_modalTransition` | 300ms | 200–400ms | Cảm giác modal mở chậm, lỡ nhịp "liền mạch" của Player Fantasy | <200ms cảm giác giật, không đủ thời gian mắt theo kịp | Ảnh hưởng cả 2 đường vào modal (badge tap và auto-nav sau purchase) |
| `T_revealBuffer` | 250ms | 200–300ms | Bé chờ lâu hơn cần trước khi equip prompt hiện | <200ms equip sheet che reveal label trước khi bé kịp đọc tên item | Chỉ áp dụng khi kết quả là item (không phải xu bonus) |
| Chest badge muted-state opacity | 40% | 30–50% | Badge khó thấy, bé tưởng đã bị ẩn | >50% trông giống active state, gây nhầm bé tap vô ích khi `chestCount = 0` | Áp dụng khi `chestCount = 0` (Edge Case — xem Core Rule 3) |

**Không định nghĩa lại** (thuộc GDD khác, GDD này chỉ tham chiếu):
- Giá item, giá Paid Chest (50 xu), tỷ lệ loot — thuộc #13/#12
- Purchase animation timing (coins-fly 500ms, card-pop 300ms) — thuộc #13
- Ceremony phase timing (Phase 1–4, tổng 2500ms) — thuộc #12
- `tap_hitbox_min` (80dp) — không áp dụng cho GDD này (không có Flame canvas/sprite tap, chỉ có Flutter widget tap với target size chuẩn Material 48×48dp)

## Visual/Audio Requirements

**Phạm vi**: Toàn bộ item card, purchase animation, "Equip now?" sheet (#13) và chest sprite, ceremony phases, item/xu reveal (#12) đã được specify đầy đủ ở GDD gốc — KHÔNG lặp lại ở đây. GDD này chỉ sở hữu composition chrome: header row, 2 trạng thái Chest badge, modal transition, scrim trong lúc transition, và SFX riêng của chrome.

**Header row (Xu balance card + Chest badge)**:
- Không dùng "floating pill" treatment của #18 — #18 float pill để tránh chia Flame canvas thành 2 khối "world"/"dashboard"; Shop không có Flame canvas (thuần Flutter, xem Overview) nên không có "world" nào cần bảo vệ. Header dock flush ở trên `TabBar`, nền kế thừa Cream Ivory `#FFFDF0` (Art Bible Section 4) của screen, ranh giới dưới là hairline/soft shadow nhẹ (cùng độ sâu với #13's item card shadow).
- Chiều cao: đủ chứa tap target tối thiểu 48×48dp (`technical-preferences.md`) + padding, ~56–64dp.
- **Xu balance card = Supporting shape** (Art Bible Section 3's Hero vs. Supporting table: rounded rectangle cho info panel): bo góc 12dp (khớp #13's item card radius), nền Cloud White `#FFFFFF`, icon xu Honey Gold `#FFD060` (Section 4 Semantic Color: "Coins currency") + số dư màu `#3D2B1F`. Non-interactive — không dùng pill/button language vì đây là readout, không phải nút bấm.
- **Chest badge = Hero shape** (hình tròn, không phải pill) — Section 3's table gán "reward items"/"primary CTA" cho hình tròn; đây là element duy nhất trong header vừa tappable vừa mang reward. Đây cũng là echo trực tiếp pattern Hero-vs-Supporting đã dùng ở #18 (Mochi tròn giữa chrome hình chữ nhật) — cố ý lặp lại ngôn ngữ hình học này, không phải shape lạc loài.

**Chest badge — 2 trạng thái**:
- **Active (`chestCount > 0`)**: nền Peach Glow `#FFCBA4` (echo trực tiếp #12's chest sprite "thân màu Peach Glow ấm"), viền Honey Gold `#FFD060` 2px (echo #12's chest viền), icon chest filled solid pastel + số đếm `#3D2B1F`. Pulse animation KHÔNG định nghĩa lại ở đây — dùng UI Requirement có sẵn của #12 ("Pulse animation khi chestCount > 0").
- **Muted (`chestCount == 0`)**: opacity 40% (Tuning Knob đã có) CỘNG THÊM 3 cue độc lập không phụ thuộc màu: (1) fill desaturate sang warm neutral `#644A3C` — Art Bible Section 4's canonical Disabled-text hex, không dùng grey thuần (Art Bible cấm `#000000`/grey tuyệt đối cho mọi UI element); (2) viền bị xoá hoàn toàn — border-presence tự nó là 1 cue nhị phân độc lập; (3) icon chuyển từ filled solid pastel sang outlined stroke 2-3px (Section 3's icon philosophy variant thứ 2), cùng màu `#644A3C`. 4 cue xếp chồng (opacity + hue-shift + border-removal + fill→outline) đủ an toàn cho colorblind theo Art Bible Section 4's Colorblind Safety table (luôn cần icon/shape backup, không chỉ màu).

**Modal transition (Chest Open ceremony)**:
- **Vào**: scale-from-badge — modal phóng to từ đúng vị trí Chest badge (hình tròn) ra full-screen (hình chữ nhật) trong `T_modalTransition` (300ms, Tuning Knob đã có). Áp dụng cho CẢ 2 đường vào (badge tap thủ công VÀ auto-nav sau Paid Chest purchase) vì cả 2 đều dẫn về cùng vị trí badge (chestCount tăng trong cùng batch write trước khi badge từng được tap, theo Formula 1).
- **Ra**: đảo ngược — modal thu nhỏ lại về đúng vị trí Chest badge rồi fade, quay lại đúng tab bé đang xem trước đó (đã có ở Edge Cases). Củng cố cảm giác Player Fantasy "chưa từng thực sự rời đi" — pattern tương tự #18's context-menu neo tại vị trí Mochi thay vì center-screen dialog (đang trở thành convention chung của project: modal/popup neo về nguồn gốc kích hoạt, không teleport).
- Exit chỉ khả dụng sau khi modal dismissible (sau Phase 4, hoặc sau Equip prompt nếu kết quả là item) — theo Edge Case 4, không có rule mới ở đây.

**Scrim trong lúc transition**: Áp dụng warm scrim đã xác nhận là project-wide convention (từ #18: warm dark brown `#3D2B1F` ~20-25% opacity, không dùng scrim đen tiêu chuẩn, theo Art Bible Section 2's cấm dark vignette). Vì modal này là full-screen (khác #13/#18's sheet chỉ che 1 phần), scrim chỉ cần thiết trong lúc CHUYỂN TIẾP (0-300ms modal đang phóng to, phần Shop screen còn hở ở rìa được dim đồng bộ với animation) — khi modal đã full-opaque, không còn gì phía sau để scrim.

**Sound (chỉ SFX của chrome, không lặp lại SFX của #13/#12)**:
- Chest badge tap (`chestCount > 0`, modal mở): swoosh-chime ngắn (~150-200ms), pitch tăng dần — khác timbre với #13's "click" phẳng và #12's rattle (chỉ bắt đầu sau khi modal đã đến nơi). Giữ tone sparkle nhẹ, khớp Shop's mood target (Art Bible Section 2: "Boutique nhỏ, cuốn hút, magical").
- Chest badge tap (`chestCount == 0`): KHÔNG có âm thanh — cùng lý do #13's "Đã có ✓" pattern (im lặng để tránh negative feedback).
- Modal đóng: "settle" sound nhẹ — bản pitch thấp hơn, đảo ngược của swoosh-chime mở (~150ms).
- Volume: 70% master SFX (khớp #12's convention hiện có).

📌 **Asset Spec** — Sau khi approved, chạy `/asset-spec system:shop-reward-ui` cho 2 trạng thái Chest badge mới và 2 SFX chrome mới — mọi thứ khác (item card, ceremony content, sound hiện có) đã được asset-spec dưới #13/#12.

## UI Requirements

Shop & Reward UI đóng góp 2 surfaces trên 1 route (Main Navigation Shell #17):
1. **`/child/shop`** (Tab 3) — header row (Xu balance card + Chest badge) + 5-tab `TabBar`/`TabBarView` (nội dung mỗi tab owned by #13)
2. **Chest Open modal** — full-screen `PageRoute` push từ `/child/shop`, không phải GoRouter sub-route — host ceremony content (#12) + "Equip now?" prompt (tái sử dụng UI của #13) khi kết quả là item

📌 **UX Flag — Shop & Reward UI**: Cần `/ux-design` spec trước khi viết epics — đặc biệt: (1) header row's Hero-circle-badge-bên-cạnh-Supporting-rectangle-card composition cần wireframe verify trên nhiều kích thước màn hình (badge có đủ khoảng cách với balance card không bị chật trên màn hình nhỏ); (2) scale-from-badge modal transition cần test thật trên device — animation phóng to từ 1 điểm nhỏ (48dp) ra full-screen có thể cảm giác khác với thiết kế trên giấy, đặc biệt ở `T_modalTransition` = 300ms; (3) navLockMs guard (Formula 1) cần verify implementation thật không cho phép double-navigation khi bé tap nhanh liên tục.

## Acceptance Criteria

**Test tier note**: Theo `coding-standards.md`'s Testing Standards, mọi criterion tag `[LOGIC]`/`[INTEGRATION]` là BLOCKING (automated test bắt buộc) — không có tier "advisory Logic/Integration", không có ngoại lệ carve-out nào. Chỉ `[UI]` là advisory. GDD này có **15 criteria BLOCKING**: Core Rule 2, 3a, 4, 5, 6 (5) + Formula 1a, 1b, 2 (3) + Edge Case 1, 2, 3, 4, 5, 6, 7 (7) = 15. Edge Case 6 CŨNG là BLOCKING dù phạm vi test hẹp hơn các criteria khác (chỉ verify 1 claim cụ thể của GDD này, không re-test #12's sync-on-reconnect AC) — phạm vi hẹp không đồng nghĩa với advisory. Core Rule 7 (no deep-link) KHÔNG có AC riêng — đây là absence-of-feature claim, giữ nguyên dạng design-intent note trong Core Rules, không ép thành testable criterion.

**Core Rule 1 — Screen structure** `[UI]`
- **GIVEN** `/child/shop` render, **THEN** header row (Xu balance + Chest badge) hiển thị trên CẢ 5 tab, không chỉ riêng tab 🎲.

**Core Rule 2 — Badge tap mở modal** `[INTEGRATION]` BLOCKING
- **GIVEN** `chestCount > 0`, **WHEN** bé tap Chest badge, **THEN** đúng 1 lần `Navigator.push` full-screen modal fires, `/child/shop` vẫn active underneath.
- **GIVEN** modal đang mở từ tab đang xem (ví dụ tab "Trang phục"), **WHEN** modal dismiss, **THEN** quay lại đúng tab đó — không reset về tab 0.

**Core Rule 3a — No-op khi chestCount == 0** `[LOGIC]` BLOCKING
- **GIVEN** `chestCount == 0`, **WHEN** bé tap Chest badge, **THEN** KHÔNG có `Navigator.push` nào được gọi, KHÔNG error/toast nào hiện.

**Core Rule 3b — Muted visual state** `[UI]`
- **GIVEN** `chestCount == 0`, **THEN** badge hiển thị opacity 40%, fill `#644A3C`, không viền, icon outlined.

**Core Rule 4 — Paid Chest purchase → auto-navigate** `[INTEGRATION]` BLOCKING
- **GIVEN** Paid Chest purchase batch write commit thành công, **WHEN** purchase animation's `onAnimationComplete` fires, **THEN** modal auto-mở đúng 1 lần, khớp `T_total(chest_purchase)`.

**Core Rule 5 — Item reveal → Equip prompt branch** `[INTEGRATION]` BLOCKING
- **GIVEN** kết quả ceremony là item, **THEN** "Equip now?" sheet hiện tại `T_equipPromptStart`.
- **GIVEN** kết quả là xu bonus/consolation, **THEN** không có equip prompt, modal auto-dismiss sau xu-count-up animation.

**Core Rule 6b — Auto-navigate to Pet Room sau "Mặc ngay"** `[INTEGRATION]` BLOCKING
- **GIVEN** bé tap "Mặc ngay" (từ purchase path HOẶC gacha path), **WHEN** equip action (#15) commit thành công, **THEN** app navigate đến `/child/pet-room` — bé thấy SHOWING_OFF animation live trên Mochi.
- **GIVEN** bé tap "Để sau", **THEN** KHÔNG navigate, ở lại Shop.

**Core Rule 6 — Live state sync** `[INTEGRATION]` BLOCKING
- **GIVEN** `xuBalance`/`chestCount` thay đổi qua StreamProvider trong lúc bé ở Shop, **THEN** header + affordability states cập nhật mà không cần refresh thủ công.

**Formula 1a — T_total timing** `[LOGIC]` BLOCKING
- **GIVEN** mỗi `entryTrigger`, **THEN** `T_total` = 2800ms (badge_tap) / 3600ms (chest_purchase), ±1ms tolerance.

**Formula 1b — navLocked callback-driven guard** `[INTEGRATION]` BLOCKING (highest-risk item trong GDD này)
- **GIVEN** purchase commit, **THEN** `navLocked` giữ `true` cho đến khi `onAnimationComplete` callback THẬT SỰ fire — KHÔNG phải fixed timer. Verify qua test với animation giả lập chạy chậm hơn `navLockMs` danh nghĩa: lock phải vẫn giữ `true` quá thời điểm đó.

**Formula 2 — T_equipPromptStart timing** `[LOGIC]` BLOCKING
- **GIVEN** kết quả là item, **THEN** `T_equipPromptStart` = 2750ms tính từ lúc ceremony bắt đầu, ±1ms.

**Edge Case 1 — Tap trong navLocked window** `[INTEGRATION]` BLOCKING
- **GIVEN** `navLocked == true`, **WHEN** bé tap badge, **THEN** tap bị swallow, không double-push khi lock sau đó release.

**Edge Case 2 — Provider error state** `[INTEGRATION]` BLOCKING
- **GIVEN** `chestCountProvider` throw error, **THEN** badge hiển thị "—", tap không tạo hành động nào (không chỉ muted về visual — thực sự non-functional).

**Edge Case 3 — App minimize giữa ceremony** `[INTEGRATION]` BLOCKING
- **GIVEN** app bị minimize giữa ceremony, **WHEN** resume, **THEN** kết quả cuối cùng hiển thị thẳng — không replay, không roll lại.

**Edge Case 4 — Non-dismissible trong Phase 1–3** `[INTEGRATION]` BLOCKING
- **GIVEN** ceremony đang ở Phase 1–3, **WHEN** bé cố dismiss (tap ngoài/back), **THEN** modal vẫn mở.

**Edge Case 5 — chestCount > 1, tiêu thụ đúng 1** `[LOGIC]` BLOCKING
- **GIVEN** `chestCount > 1`, **WHEN** 1 ceremony hoàn tất, **THEN** đúng 1 chest bị tiêu thụ, không auto-loop.

**Edge Case 6 — Offline result display** `[INTEGRATION]` BLOCKING (phạm vi hẹp — chỉ verify claim của GDD này, không re-test #12's sync-on-reconnect AC)
- **GIVEN** kết quả đã roll xong client-side, **THEN** render không bị gate bởi Firestore write acknowledgment (sync/reconnect behavior là AC của #12, không kiểm tra lại ở đây).

**Edge Case 7 — 2 purchase chồng lấn** `[INTEGRATION]` BLOCKING
- **GIVEN** purchase Paid Chest lần 2 commit trong khi `navLocked == true` từ lần 1, **THEN** chỉ đúng 1 auto-navigate fire, `chestCount` vẫn phản ánh đúng cả 2 lần mua, không có chest nào bị mất.

**Edge Case 8 — Tab-switch blocked trong lúc modal mở** `[INTEGRATION]` BLOCKING
- **GIVEN** Chest Open modal đang mở (bất kỳ Phase nào), **WHEN** bé cố tap vào bottom nav tab khác, **THEN** không có gesture nào chạm được tab bar — modal (pushed qua root navigator) che hoàn toàn bottom nav, route hiện tại vẫn là màn hình chứa modal.

## Open Questions

1. **game-concept.md's MVP Definition reconciliation**: Overview flagged rằng `game-concept.md` (early Draft, 2026-06-25) vẫn liệt kê Gacha là KHÔNG trong MVP, mâu thuẫn với `systems-index.md` + 2 GDD đã Designed. GDD này theo systems-index làm nguồn sự thật hiện tại. Ai chính thức update `game-concept.md`'s MVP Definition sau này nên biết quyết định này đã được đưa ra ở đây, không phải ngầm — owner: người chạy revision pass cho `game-concept.md` trong tương lai.
2. **Header row layout (Xu balance trái, Chest badge phải)**: art-director flag đây là quyết định low-risk, reversible, không ảnh hưởng hex/shape — mở cho `/ux-design` xem lại trong wireframe pass.
3. **Honey Gold hex-drift pattern**: Không re-flag chi tiết ở đây — đã track đầy đủ ở #18's Open Questions (4 instance tìm+fix trong session này). Màu của GDD này (`#FFD060` cho coin icon, badge ring) đã sourced đúng từ Art Bible Section 4 ngay từ đầu — không có instance mới nào. `/consistency-check` (chạy sau khi GDD này hoàn thành) xác nhận PASS — 18/18 registry entries clean, 11/11 hex `#FFD` hits trong toàn bộ corpus đều là `#FFD060` chính xác, không còn instance sai nào.
4. **`navLockMs` fallback-ceiling giá trị chính xác**: Formula 1 định nghĩa "timer as fallback ceiling" (`navLockMs + 500ms buffer`) phòng khi animation-complete callback không bao giờ fire (ví dụ widget bị dispose giữa animation) — buffer 500ms là placeholder, chưa validate với dữ liệu jank thật trên device. Defer tuning đến implementation/QA phase khi có thể đo animation performance thật.
