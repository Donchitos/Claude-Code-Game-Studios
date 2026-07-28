# Game Concept: PetQuest

*Created: 2026-06-25*
*Status: Draft*

---

## Elevator Pitch

> PetQuest là game nuôi thú ảo dành cho trẻ em, nơi mỗi hành động kỷ luật ngoài đời thực — làm bài tập, quét nhà, tập đàn — biến thành năng lượng nuôi lớn thú cưng; bé trang trí phòng theo ý thích và khoe thú cưng của mình với nhóm bạn hàng xóm trong một khu xóm ảo chung.
>
> *10-second test*: "Tamagotchi nơi việc làm bài tập chính là thức ăn duy nhất cho thú cưng — và cả xóm cùng chơi."

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Life Sim / Virtual Pet / Social Casual |
| **Platform** | Mobile (iOS + Android) — Flutter + Flame |
| **Target Audience** | Trẻ em 6–10 tuổi + bố mẹ đồng hành |
| **Player Count** | Single-player core + Local social (nhóm bạn hàng xóm) |
| **Session Length** | 5–15 phút/ngày (submit tasks + chăm thú + thăm bạn) |
| **Monetization** | Chưa xác định — không pay-to-win theo thiết kế |
| **Estimated Scope** | Large (9 tháng, solo developer) |
| **Comparable Titles** | Tamagotchi Uni, Stardew Valley (cozy loop), My Talking Tom (pet bond) |

---

## Core Fantasy

> *"Tớ xứng đáng có thú mạnh nhất và phòng đẹp nhất trong xóm — vì tớ chăm chỉ nhất."*

Bé trải nghiệm cảm giác tự hào kép: tự hào vì đã hoàn thành việc thực tế, VÀ tự hào khi thú cưng của mình trở thành biểu tượng của sự nỗ lực đó. Không có shortcut nào — mỗi item, mỗi lần tiến hóa là bằng chứng của effort thật.

Đây là game đầu tiên nơi "làm bài tập xong" không chỉ được bố mẹ khen, mà còn được cả nhóm bạn thấy và ngưỡng mộ.

---

## Unique Hook

Như Tamagotchi, **AND ALSO** việc làm bài tập, quét nhà, tập đàn là thức ăn DUY NHẤT để thú cưng lớn mạnh — và cả xóm bạn bè cùng chứng kiến sự tiến bộ đó.

---

## Visual Identity Anchor

**Direction**: *Cozy Chibi Neighborhood* — thế giới pastel ấm áp, nhân vật chibi tròn trịa dễ thương, animation mềm mại như đang thở.

**Visual rule**: *"Mọi thứ phải trông như muốn được ôm."*

**Supporting visual principles**:
1. **Pastel warmth** — Màu sắc ấm, bão hòa vừa phải, không màu neon harsh. *Design test*: Nếu một màu trông "aggressive" — thay bằng pastel version.
2. **Round over sharp** — Mọi asset (thú, nhà, item) ưu tiên đường cong, góc bo tròn. *Design test*: Trẻ em có muốn ôm/chạm vào cái này không?
3. **Expressive animation** — Thú có ít nhất 5 emotional states được thể hiện rõ qua body language, không chỉ màu sắc. *Design test*: Có thể hiểu mood của thú chỉ qua animation, không cần UI text.

**Color philosophy**: Palette chính — cream nền, mint xanh, peach cam, lavender tím. Tránh đen và đỏ đậm ở primary elements.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Expression** (tự thể hiện, sáng tạo) | 1 | Trang trí phòng, chọn outfit cho thú, customize không gian sống |
| **Fellowship** (kết nối, cộng đồng) | 2 | Thăm nhà bạn, tặng quà, bảng xếp hạng xóm thân thiện |
| **Fantasy** (vai trò, make-believe) | 3 | Bé là "chủ nhân" chăm sóc thú cưng trong căn phòng riêng |
| **Submission** (thư giãn, thói quen) | 4 | Daily check-in nhẹ nhàng, không áp lực |
| **Sensation** | 5 | Âm thanh dễ thương, animation mềm mại khi tương tác |
| **Challenge** | N/A | Game không test skill — test discipline |
| **Narrative** | N/A | Không có story arc chính |
| **Discovery** | Supporting | Gacha rương bí ẩn, item rare ẩn trong seasonal events |

### Key Dynamics (Emergent behaviors)

- Trẻ tự nguyện làm thêm task để có đủ xu mua item muốn
- Bé A thấy bé B có item rare → hỏi cách kiếm → động lực lan truyền tự nhiên
- Bố mẹ và con có ritual approve hàng ngày → moment kết nối gia đình
- Bé tự tổ chức "tour" dẫn bạn thăm phòng → social pride loop

### Core Mechanics

1. **Task-to-Energy System**: Bé submit task ngoài đời → bố mẹ approve → nhận xu + cơ hội gacha
2. **Pet Care Loop**: Cho ăn, chăm sóc, dress-up thú cưng → pet level up → mở hình thức mới
3. **Room Customization**: Mua và đặt đồ trang trí trong phòng, sân vườn (Phase 2+)
4. **Social Layer**: Thăm phòng bạn, tặng quà nhỏ, bảng xếp hạng xóm (Phase 2)
5. **Economy System**: Xu cố định + gacha rương → shop items → không bao giờ dead-end

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Bé tự chọn trang trí phòng, chọn outfit thú, quyết định làm task nào | Core |
| **Competence** | Thú cưng lớn mạnh, phòng đẹp hơn = bằng chứng của sự nỗ lực thật | Core |
| **Relatedness** | Kết nối với bạn bè qua social layer; kết nối với bố mẹ qua approval ritual | Core |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — Level up pet, collect rare items, progression rõ ràng
- [ ] **Explorers** — Limited; gacha tạo chút discovery
- [x] **Socializers** — Thăm nhà bạn, tặng quà, khoe thú
- [ ] **Killers/Competitors** — Không có PvP; bảng xếp hạng chỉ inspirational

### Flow State Design

- **Onboarding**: 3 màn hướng dẫn → chọn thú → bố mẹ setup account → submit task đầu tiên ngay trong app
- **Difficulty scaling**: Không có skill difficulty — thay vào đó là "task effort scaling" (quét nhà = 10xu, học đàn 30 phút = 30xu)
- **Feedback clarity**: Thú có 5 emotional states hiển thị rõ; progress bar đơn giản cho pet level
- **Recovery from failure**: Pet không chết — chỉ buồn và ngủ lịm sau 2 ngày không có task. Bé làm 1 task là pet vui trở lại ngay.

---

## Core Loop

### Moment-to-Moment (30 giây)

Mở app → Thấy thú đang chờ/vui vẻ/buồn → Tap tương tác (vuốt ve, cho ăn nếu có xu, mặc outfit mới) → Thú phản ứng với animation dễ thương → Bé cảm thấy gắn kết và tự hào.

*Câu hỏi intrinsic satisfaction*: Tương tác với thú phải thú vị ngay cả khi không có progression — animation đủ cute và responsive để bé muốn tap chỉ vì vui.

### Short-Term (5–15 phút)

1. Submit task thực tế trong app (chọn task từ danh sách hoặc tự thêm)
2. Nhận "Hạt Giống Bí Ẩn" tạm thời (visual feedback tức thì, giải quyết parent latency)
3. Bố mẹ nhận notification → approve → Hạt nở ra: xu cố định + cơ hội rương gacha
4. Vào shop → mua item muốn hoặc mở rương → dress-up thú/phòng
5. Khoe với bạn (Phase 2+)

### Session-Level (30–60 phút/ngày)

Check pet mood → Submit tasks hôm nay (1–3 tasks) → Nhận rewards sau khi bố mẹ approve → Trang trí/upgrade → Thăm 1–2 nhà bạn (Phase 2) → Check bảng xóm → Đặt mục tiêu cho ngày mai ("còn 15xu nữa là mua được mũ rồng").

### Long-Term Progression

- **Tháng 1–3**: Pet level 1→5 (sửa 2026-07-06, reconcile với `pet-leveling-evolution.md` — 5 level là MVP cap thật, không phải 10; 10 là con số draft sớm chưa reconcile), mở 3 evolution stage (Baby/Young/Grown, tại L1/L2/L4) — room trong MVP là background cố định, KHÔNG "fill đầy" (Room Layout/Decoration Database là Alpha-tier, xem `pet-room-screen-ui.md`'s scope note)
- **Tháng 4–6**: Mở khu xóm, kết bạn, seasonal events
- **Tháng 7–9+**: Mở sân vườn, đảo riêng, build tự do, group quests

### Retention Hooks

- **Investment**: Pet gắn với identity của bé — không muốn bỏ
- **Social**: Bạn bè đang online, muốn thăm hoặc không muốn tụt hậu
- **Curiosity**: Rương gacha hôm nay ra cái gì? Seasonal event mới có item gì?
- **Mastery**: "Tuần này làm đủ 7 ngày liên tiếp để mở achievement đặc biệt"

---

## Game Pillars

### Pillar 1: Kỷ luật Thật → Phần thưởng Thật
Mọi item, mọi sự tiến hóa đều có nguồn gốc từ hành động thực tế — không có shortcut nào không đi qua effort.

*Design test*: Nếu debate "thêm daily login bonus không cần làm task" → KHÔNG. Phá vỡ tính toàn vẹn của vòng lặp cốt lõi.

### Pillar 2: Thú Cưng Là Hình Ảnh Của Bé
Appearance và mood của thú phản chiếu chính xác sự chăm chỉ của bé — nhìn vào thú là thấy bé tuần này như thế nào.

*Design test*: Nếu debate "cho phép mua xu bằng tiền thật" → KHÔNG. Thú của bé phải là thành tích thật, không phải ví tiền bố mẹ.

### Pillar 3: Khoe Đẹp, Không Đánh Nhau
Social layer là để truyền cảm hứng và kết nối, không phải cạnh tranh tiêu cực hay PvP.

*Design test*: Nếu debate "bé A có thể phá phòng bé B" → KHÔNG. Social phải an toàn và lành mạnh cho trẻ nhỏ.

### Pillar 4: Bố Mẹ Là Đồng Minh, Không Phải Cảnh Sát
Parent interface phải nhẹ nhàng, nhanh, và tạo kết nối bố mẹ-con — không phải surveillance tool.

*Design test*: Nếu debate "thêm GPS tracking bé khi làm task" → KHÔNG. Trust và approval đủ rồi.

### Pillar 5: Mỗi Bé Có Thế Giới Riêng
Không có bé nào có cùng một phòng, cùng một thú — customization là ngôn ngữ tự thể hiện của bé.

*Design test*: Nếu debate "dùng template phòng mặc định cho nhanh làm" → KHÔNG (áp dụng từ khi Room Layout System ship — Alpha-tier). **Sửa 2026-07-06 (reconcile với MVP Definition đã sửa cùng ngày — review-all-gdds Phase 3 flag)**: bar "≥3 layer customization" áp dụng đầy đủ từ **Alpha** (khi Room Layout + Decoration Database ship, cộng thêm room làm layer thứ 2-3). **MVP chỉ có 1 layer thật (pet outfit, 3 slot: body_outfit/hat/accessory)** — chấp nhận được cho MVP vì room là background cố định có chủ ý (không phải cắt giảm ngầm), nhưng đây LÀ 1 gap thật so với pitch gốc ("bé trang trí phòng theo ý thích") — không che giấu bằng cách đếm 3 slot outfit như 3 "layer" riêng biệt (chúng cùng 1 layer khái niệm: trang phục Mochi).

### Anti-Pillars (What This Game Is NOT)

- **KHÔNG pay-to-win**: Tiền thật không mua item exclusive — phá vỡ Pillar 1 và niềm tin của bé.
- **KHÔNG bạo lực/cạnh tranh tiêu cực**: Pet không chết, không bị tấn công — bảo vệ sức khỏe tâm lý trẻ.
- **KHÔNG dark patterns**: Không countdown gây lo lắng, không "pet sắp chết trong 1 giờ".
- **KHÔNG skip parental approval**: Bố mẹ là một phần không thể thiếu của core loop.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Tamagotchi Uni | Emotional bond với thú cưng ảo, daily care ritual | Energy đến từ real-world discipline, không phải timer | Chứng minh pet bond là powerful — sold out 2023 |
| Stardew Valley | Cozy loop: làm việc → nhận thưởng → phát triển; tặng quà cho NPC | Target trẻ em, bố mẹ là approval layer, social là bạn thật | Cozy loop + relationship depth = cực kỳ sticky |
| Khu Vườn Trên Mây | Social với người chơi thật, trang trí không gian chung | Real-world tasks là currency, không phải time/money | Social + beautiful world = retention mạnh |
| ClassDojo | Gamify behavior cho trẻ em, bố mẹ-giáo viên involvement | Game thật, không phải tool — fun first | 50M+ users validate nhu cầu behavior gamification |

**Non-game inspirations**: Khu chung cư Việt Nam (social proximity tạo "xóm" tự nhiên), tâm lý học hành vi trẻ em (Skinner's operant conditioning — reward behavior immediately), thiết kế đồ chơi Nhật Bản (cute = emotional safety).

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 6–10 tuổi (bé chơi); 28–40 tuổi (bố mẹ co-use) |
| **Gaming experience** | Casual — lần đầu chơi game có ý nghĩa |
| **Time availability** | 5–15 phút/ngày, sau giờ học |
| **Platform preference** | Tablet hoặc smartphone bố mẹ cho mượn |
| **Current games they play** | Subway Surfers, YouTube Kids, các app vẽ/tô màu |
| **What they're looking for** | Thú cưng ảo + tự do sáng tạo + được bạn bè ngưỡng mộ |
| **What would turn them away** | Quá khó, mất thú cưng vĩnh viễn, bố mẹ không tham gia |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Flutter + Flame — mobile-first, 1 codebase iOS+Android, UI rất mạnh cho game có nhiều menus/shop |
| **Backend** | Firebase (Firestore + FCM) — realtime data + push notifications cho parent approval |
| **Key Technical Challenges** | (1) Parent notification + approval flow; (2) Real-time neighbor visits (Phase 2); (3) Economy balance system; (4) Pet animation state machine |
| **Art Style** | Cute 2D chibi — pastel colors, round shapes, expressive animation |
| **Art Pipeline Complexity** | Medium — custom 2D sprites, nhưng không cần 3D hay complex shaders |
| **Audio Needs** | Moderate — ambient cozy music, SFX cho interactions (tap, reward, level up) |
| **Networking** | Client-Server (Firebase) — không phải real-time PvP, nên latency tolerance cao |
| **Content Volume** | MVP: 1 pet, 5 task categories, 30 items, 1 room template. Full: 10 pets, 100+ items, garden, island |
| **Procedural Systems** | Gacha loot table (weighted random) — không cần procedural generation |

---

## Risks and Open Questions

### Design Risks
- **Parent Latency**: Bé muốn thưởng ngay nhưng bố mẹ chưa về → Giải pháp: "Hạt Giống Bí Ẩn" tạm thời trước khi approve
- **Task Fatigue**: Game trở thành todolist khô khan → Giải pháp: Quest narrative framing ("Nạp năng lượng cho Khiên Ma Thuật")
- **Solo play dead-end**: Bé không có bạn cùng chơi → Phase 1 phải đủ vui khi chơi một mình

### Technical Risks
- **Firebase costs**: Khi scale lên nhiều users, Firebase có thể tốn kém → Cần model cost early
- **Push notification reliability**: iOS notification permissions phức tạp → Test early trên TestFlight
- **Real-time sync Phase 2**: Neighbor visits cần low-latency → Thiết kế async-first (không cần cùng online)

### Market Risks
- **Bố mẹ không tham gia**: Nếu bố mẹ không setup/approve → game chết → Marketing phải target bố mẹ, không chỉ trẻ em
- **Crowded kids app market**: App Store/Play Store có rất nhiều kids apps → Cần ASO và community marketing tốt
- **Monetization unclear**: Model hiện tại không rõ doanh thu → Cần quyết định trước khi launch

### Scope Risks
- **Art volume**: 100+ items cần nhiều sprites → Cần tìm artist hoặc asset packs sớm
- **Phase 2 multiplayer complexity**: Neighbor social layer có thể delay timeline đáng kể
- **Economy tuning**: Balance task reward vs. shop prices cần playtest nhiều lần

### Open Questions
- **Bao nhiêu task categories là đủ cho MVP?** → Prototype với 5 categories, playtest với con gái
- **Parent UX**: Approve bằng notification hay cần mở app? → Prototype parent flow sớm
- **Offline mode**: App có hoạt động khi không có internet không? → Quyết định kiến trúc sớm

---

## MVP Definition

**Core hypothesis**: *"Bé tự nguyện làm việc nhà/học bài vì muốn nhận xu để chăm sóc và trang trí cho thú cưng."*

**Sửa 2026-07-06 (reconcile với `systems-index.md` + GDD thật — fix drift flagged nhiều lần trong session này: gate-check's Creative Director finding, #18's Open Questions, #20's Overview scope note, review-all-gdds Phase 3)**: Mục này là early Draft (2026-06-25), viết trước khi 21 MVP GDD thực tế được thiết kế. 2 điểm dưới đây đã drift khỏi thực tế đã build — sửa lại để khớp, không phải ngược lại (`systems-index.md` + GDD thật là nguồn sự thật hiện tại, không phải Draft sớm này).

**Required for MVP**:
1. Task submission system + Parent approval via push notification
2. Xu economy (nhận xu sau approve, tiêu xu trong shop) **+ Gacha/Rương May Mắn** (sửa — Gacha ĐÃ là MVP-tier trong `systems-index.md`, KHÔNG defer, xem #12/#13/#20)
3. 1 pet với 5 base mood states (không phải "emotional states" tổng quát — 5 mood cụ thể: HAPPY/CONTENT/TIRED/SAD/SLEEPING, xem `pet-state-machine.md`) + dress-up (3 outfit slots: body_outfit/hat/accessory, xem `pet-equipment.md`)
4. **Room background cố định** (sửa — KHÔNG "10-15 placeable decorations"; Decoration Database + Room Layout System là Alpha-tier, chưa có GDD, xem `pet-room-screen-ui.md`'s scope note. Room customization thật của MVP chỉ có 1 layer — pet outfit — không phải room)
5. Pet level system (level 1–5, 3 evolution stages Baby/Young/Grown tại L1/L2/L4)

**Explicitly NOT in MVP**:
- Multiplayer / neighbor visits (Phase 2)
- Room decoration / placement (Decoration Database + Room Layout System — Alpha-tier, sửa từ "Gacha rương" đã bị xoá khỏi list này vì Gacha giờ LÀ MVP)
- Garden / island expansion (Phase 3)
- Multiple pet species
- Seasonal events

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 pet, 5 task categories, 30 items, 1 room (fixed background) | Task→Approve→Xu→Shop→**Gacha**→Dress-up→Pet levels (5, 3 evolution stages) | Tháng 1–3 |
| **Vertical Slice** | 3 pets, 15 task categories, 80 items | + Streak rewards | Tháng 4 |
| **Alpha** | 5 pets, full task library, basic garden | + Neighbor visits, + Tặng quà, + Leaderboard xóm, **+ Room decoration/placement** | Tháng 5–6 |
| **Full Vision** | 10 pets, garden, mini-island, seasonal events | + Build mode, + Group quests, + Achievement system | Tháng 7–9+ |

*(Sửa 2026-07-06: "Gacha rương" và "Pet evolution" đã chuyển từ Vertical Slice → MVP row để khớp thực tế; "Room decoration/placement" đã chuyển từ ngầm-định-trong-MVP → Alpha row, khớp `pet-room-screen-ui.md`'s scope note.)*

---

## Next Steps

- [ ] Run `/setup-engine` — configure Flutter + Flame, Firebase, populate technical-preferences.md
- [ ] Run `/prototype task-approval-loop` — validate: bé submit task → bố mẹ approve → nhận xu → mua item. Nếu flow này fun và smooth, mọi thứ khác build được xung quanh.
- [ ] Run `/art-bible` — define visual identity từ "Cozy Chibi Neighborhood" anchor
- [ ] Run `/map-systems` — decompose concept thành individual systems
- [ ] Run `/design-system [pet-care]` — GDD đầu tiên
- [ ] Run `/create-architecture` — master architecture blueprint
- [ ] Run `/gate-check` — validate readiness trước khi commit production
