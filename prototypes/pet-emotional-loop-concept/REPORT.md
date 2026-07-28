# Concept Prototype Report: Pet Emotional Loop

> **Date**: 2026-06-25
> **Prototype Path**: HTML
> **Pivot from**: task-approval-loop-concept (PIVOT #1)
> **Concept File**: design/gdd/game-concept.md

---

## Hypothesis

"Nếu bé thấy Mochi đang mệt/buồn VÀ thấy item cụ thể trong shop mình muốn mua,
bé sẽ chủ động submit task để có đủ xu/hạt.
**Evidence**: bé tự hỏi 'còn bao nhiêu nữa là đủ mua [item]?' trong vòng 5 phút."

---

## Riskiest Assumption Tested

**Emotional bond đủ mạnh để thay thế instant gratification.**
Giả thuyết: thấy Mochi buồn + thấy item cụ thể trong shop = motivation submit task.

**Kết quả: CONFIRMED.**
Bé phản ứng đúng như thiết kế: "Mochi đang mệt → con muốn làm bài tập để có xu mua đồ cho bé."
Đây chính xác là vòng lặp cảm xúc mục tiêu.

---

## Approach

**Path chosen:** HTML
**Reason for path:** Hypothesis là về emotional response và UX clarity, không phải game feel vật lý.

**Built:**
1. Mochi với 5 emotional states + CSS animation (buồn/ổn/vui/hạnh phúc/siêu vui)
2. Sad hint panel khi energy thấp — gợi ý rõ ràng "Mochi cần bạn!"
3. 3 tasks với flavor text + seed bag mechanic
4. Quick approve button (parent latency simulated)
5. Shop với 6 items + price visible + affordability highlight (border vàng)
6. Progress bar "còn thiếu X nữa" cho item gần nhất
7. Buy item → Mochi mặc item vào → mood boost → confetti + reaction quote

**Shortcuts taken (intentional):**
- Không có real parent approval latency (simulated bằng "Duyệt Tất Cả")
- CSS animation thay vì Flame sprite
- Không có persistence, accounts, sounds
- Không có multiplayer/social layer

---

## Result

**Hypothesis: CONFIRMED** ✅

- Bé thấy Mochi buồn → *tự* muốn làm task để cứu Mochi và mua đồ
- Moment hoạt động rõ nhất: "Mochi đang mệt → con muốn làm bài tập để có xu mua đồ cho bé"
- Surprise (tốt): Bé *muốn được duyệt ngay* — nghĩa là motivation đủ mạnh, vấn đề là UX latency chứ không phải thiếu motivation
- Không có điểm gãy hoặc confusion rõ ràng

**Key insight**: Vấn đề của v1 (thiếu emotional destination) đã được giải quyết.
Vấn đề còn lại là parent approval latency UX — bé muốn thấy kết quả ngay.
Đây là bài toán UX (giải pháp: "Hạt Giống" + energy preview nhỏ), không phải bài toán concept.

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | HTML |
| Prototype iteration | v2 (PIVOT #1) |
| Iterations to playable | 1 (one-shot) |
| Prototype duration | ~1.5 giờ build |
| Playtesters | 1 internal (developer + child observer) |
| Feel assessment | "Muốn được duyệt ngay" — motivation quá mạnh, latency là friction |
| Hypothesis verdict | **CONFIRMED** |

---

## Recommendation: PROCEED ✅

Emotional loop cốt lõi đã được validate:
**Mochi buồn → bé muốn cứu → làm task → mua đồ → Mochi vui → bé tự hào.**

Hai vòng lặp đã được prove:
1. **Emotional hook**: Mochi sad state tạo ra "pull motivation" (muốn cứu) thay vì "push motivation" (bị bắt làm)
2. **Destination clarity**: Shop visible từ đầu + progress bar = bé biết mình đang farm để mua gì

Vấn đề còn lại (parent latency) đã có giải pháp thiết kế (Seed bag + energy preview) — cần test trong MVP thật với parent thật, không phải trong prototype.

---

## If Proceeding

**Core tuning values discovered:**
- Mood threshold quan trọng: energy < 20 = sad state triggering emotional hook
- Energy boost khi mua item (moodBonus) cần cân bằng cẩn thận — không tăng quá nhanh
- Progress bar "còn thiếu X" là feature giữ retention — keep ngay từ MVP

**Assumptions confirmed:**
- Flavor text biến task thành quest — tester không phàn nàn về "làm bài tập"
- Seed bag + visible shop giải quyết "không biết mục đích"
- Item visual trên Mochi (mặc trang phục) tạo self-expression ngay lập tức

**Assumptions disproved:**
- ~~"Instant coin reward đủ để tạo motivation"~~ — REFUTED ở v1
- ~~"Hạt giống tự nó là đủ gratification"~~ — cần destination rõ ràng

**Emergent mechanics worth formalizing:**
- **"Còn thiếu X"** progress bar → bé tự đặt mục tiêu ngắn hạn mà không cần game giao
- **Pet tap** response → bé muốn tương tác với Mochi kể cả không có task → daily engagement loop
- **Mood state as social signal** → khi có social layer, bé sẽ không muốn bạn thấy Mochi buồn

**Next steps (theo thứ tự):**
1. `/art-bible` — visual identity trước khi bắt đầu code Flutter
2. `/map-systems` — decompose concept thành systems có thể implement
3. `/design-system pet-care` — GDD đầu tiên, dùng prototype learnings trong Tuning Knobs
4. `/design-system task-reward` — GDD cho task + approval + seed bag system
5. `/sprint-plan` — plan sprint đầu tiên hướng đến MVP

---

## Lessons Learned

- **"Show the destination before the journey"** — shop/item goal phải visible từ màn đầu tiên, không phải sau khi earn. Nguyên tắc này áp dụng cho mọi progression system trong game.

- **Emotional hook > Mechanical reward**: Bé làm task "vì Mochi" mạnh hơn làm task "để có xu". Thiết kế tất cả reward systems xung quanh pet bond thay vì currency.

- **Motivation quá mạnh cũng là data**: Bé muốn duyệt ngay = motivation confirmed, nhưng latency UX cần giải quyết kỹ trong MVP với parent flow thật.

- **Prototype v1 không fail — nó loại bỏ sai lầm rẻ nhất có thể**: Phát hiện ra "thiếu destination" trong HTML prototype (1 giờ) thay vì sau 2 sprint Flutter code (2 tuần) là đúng quy trình.

---

> *Prototype code location: `prototypes/pet-emotional-loop-concept/`*
> *This code is throwaway. Never refactor into production.*
