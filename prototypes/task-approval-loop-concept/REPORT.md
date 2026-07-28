# Concept Prototype Report: Task Approval Loop

> **Date**: 2026-06-25
> **Prototype Path**: HTML
> **Concept File**: design/gdd/game-concept.md

---

## Hypothesis

"Nếu bé submit một task và thấy 'Hạt Giống Bí Ẩn' rơi vào túi ngay lập tức,
sau đó bố mẹ approve và hạt nở ra xu + cơ hội mở rương — bé sẽ cảm thấy
phần thưởng có giá trị và muốn submit task tiếp theo.
**Evidence**: tester tự hỏi 'tôi làm thêm task được không?' trong vòng 5 phút đầu."

---

## Riskiest Assumption Tested

**Parent Latency**: nếu không có gì xảy ra tức thì khi bé submit task, bé sẽ tụt hứng
trước khi bố mẹ kịp approve. "Hạt Giống" là giải pháp đề xuất.

**Kết quả**: Rủi ro này KHÔNG được giải quyết đầy đủ bởi cơ chế seed đơn thuần.
Vấn đề sâu hơn là thiếu **emotional destination** — bé không biết hạt giống dùng để làm gì,
nên kể cả khi có hạt ngay lập tức, cũng không tạo ra cảm giác háo hức chờ đợi.

---

## Approach

**Path chosen:** HTML
**Reason for path:** Hypothesis là về UX logic và feedback timing, không phải game feel vật lý.
Browser latency không ảnh hưởng đến câu trả lời.

**Built:**
1. Child view: 3 tasks với flavor text → "Xong!" → seed rơi vào túi với animation
2. Parent view (tab): approve seed → coins + optional gacha chest
3. Reward popup: coins animation + gacha chest với weighted loot table (8 items)
4. Pet energy bar: visual feedback theo 4 mood states

**Shortcuts taken (intentional):**
- Thú cưng là emoji tĩnh, không có animation thật
- Không có shop/phòng để tiêu xu
- Không có data persistence
- Không có âm thanh
- Không có login/accounts
- Không có balance thật

---

## Result

**Verdict từ tester (developer + parent = primary user):**

- **Hypothesis: REFUTED** — không xuất hiện cảm giác muốn submit thêm task
- "Chỉ là danh sách task bấm vào submit xong không có cảm giác gì"
- "Action xong không có cảm giác háo hức hay mong đợi"
- "Cảm giác đơn điệu và không biết mục đích — xong rồi, được approve rồi sẽ làm gì"

**Điều chẩn đoán đúng:**
Prototype test đúng luồng submit/approve nhưng cắt mất thứ tạo ra cảm giác háo hức:
- Con thú Mochi không có biểu hiện cần được cứu (không có emotional hook)
- Xu nhận được không có nơi để tiêu → xu vô nghĩa
- Không có "destination" → không có anticipation

**Thứ HOẠT ĐỘNG:**
- Túi Hạt Giống mechanic: tester đánh giá cao ý tưởng này như giải pháp parent latency
- Flavor text ("Nạp Khiên Ma Thuật", "Thu thập Mảnh Lâu Đài") — được nhận xét là "rất xuất sắc"
- Gacha rương variable reward — cơ chế đúng hướng, chỉ thiếu context

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | HTML |
| Iterations to playable | 1 (one-shot) |
| Prototype duration | ~1 giờ build |
| Playtesters | 1 internal (developer/parent) |
| Feel assessment | "Đơn điệu — không biết mục đích sau khi xong" |
| Hypothesis verdict | **REFUTED** |

---

## Recommendation: PIVOT

Input→Buffer→Approval pipeline đã được validate là cấu trúc đúng. Thứ bị thiếu là
**emotional loop closure**: bé cần thấy Mochi đang mệt/cần được cứu, và biết rõ
xu/hạt giống sẽ mua được gì cụ thể. Không có destination → không có motivation.

Đây không phải lỗi của concept — đây là lỗi của scope prototype. Chúng ta đã cắt
đúng thứ giúp vòng lặp có ý nghĩa.

---

## If Pivoting

**Vấn đề cốt lõi:** Vòng lặp cảm xúc bị thiếu "Mochi đang mệt → tôi MUỐN cứu nó" làm anchor.

**Giữ lại:**
1. **Túi Hạt Giống mechanic** — vẫn là giải pháp tốt nhất cho parent latency
2. **Flavor Text / Quest framing** — "Nạp Khiên Ma Thuật" > "Làm bài tập toán"
3. **Gacha rương variable reward** — cơ chế đúng, chỉ cần context

**Thay đổi quan trọng nhất cho v2:**
1. **Mochi biểu hiện cần được cứu** — animated mood states: buồn/mệt rõ ràng, bé làm task "vì Mochi" không phải vì xu
2. **Shop/Destination có thể nhìn thấy** — 3 item cụ thể với giá = "1 hạt + 10xu = mũ phù thủy cho Mochi" → bé biết mình đang farm để mua gì
3. **Reward flow mới**: Hạt "Cần Duyệt" → bố mẹ "Tưới nước" (approve) → Hạt nở → tiêu trong shop → Mochi vui

**Hypothesis mới cho v2:**
"Nếu bé thấy Mochi đang mệt/buồn VÀ thấy trước item cụ thể mình muốn mua trong shop,
bé sẽ chủ động submit task để có đủ xu/hạt. Evidence: bé hỏi 'còn bao nhiêu nữa là đủ mua X?'"

**Next step:** `/prototype pet-emotional-loop`

---

## Lessons Learned

- **Assumption bị phá vỡ khi build thực tế:**
  "Instant gratification = thấy hạt rơi vào túi ngay" — SAI.
  Instant gratification thật sự = thấy *tác động có ý nghĩa* ngay lập tức.
  Hạt rơi vào túi không có ý nghĩa nếu không biết túi dùng để làm gì.

- **Điều bất ngờ không xuất hiện trong brainstorm:**
  Vòng lặp cảm xúc phụ thuộc vào việc OUTPUT (shop/pet response) phải VISIBLE ngay
  từ màn đầu tiên, không phải là thứ mở ra sau khi đã earn đủ điều kiện.
  "Show the destination before the journey" là nguyên tắc bị bỏ quên.

- **Test khác đi thế nào vào lần sau:**
  Prototype v2 phải cho bé thấy Mochi đang buồn + shop với 1 item cụ thể ngay màn đầu.
  Test với đứa trẻ thật (6-10 tuổi), không phải developer.
  Quan sát im lặng: bé có tự tap vào Mochi không? Bé có hỏi về item trong shop không?

---

> *Prototype code location: `prototypes/task-approval-loop-concept/`*
> *This code is throwaway. Never refactor into production.*
