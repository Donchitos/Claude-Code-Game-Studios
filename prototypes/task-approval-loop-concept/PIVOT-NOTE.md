# PIVOT NOTE — Task Approval Loop → Pet Emotional Loop

**Date**: 2026-06-25
**Original hypothesis**: "Hạt Giống Bí Ẩn tạo ra instant gratification đủ để bé muốn submit thêm task"
**Result**: REFUTED — không có cảm giác háo hức hay mong đợi sau khi submit

---

## What to KEEP

1. **Seed Bag mechanic** (Input→Buffer→Approval pipeline) — cấu trúc đúng, giữ nguyên
2. **Flavor Text / Quest framing** — "Nạp Khiên Ma Thuật" > "Làm bài tập toán"
3. **Gacha rương variable reward** — đúng cơ chế, chỉ thiếu context

## What to CHANGE (single most important)

**Thêm emotional destination VISIBLE ngay từ đầu:**
- Mochi hiển thị rõ đang mệt/buồn → tạo emotional hook "bé làm task vì Mochi"
- Shop với 3 item cụ thể + giá hiển thị trước → "còn bao nhiêu nữa là đủ mua X?"
- Reward flow: Hạt rơi vào túi → bố mẹ "tưới nước" → hạt nở → tiêu trong shop → Mochi vui

## Revised Hypothesis for v2

"Nếu bé thấy Mochi đang mệt/buồn VÀ thấy trước item cụ thể trong shop mình muốn mua,
bé sẽ chủ động submit task để có đủ xu/hạt.
**Evidence**: bé tự hỏi 'còn bao nhiêu nữa là đủ mua [item]?' trong vòng 5 phút."

## Next Prototype

`/prototype pet-emotional-loop`

Scope v2:
1. Mochi với 3 emotional states rõ ràng (buồn/bình thường/vui) + animation đơn giản
2. 2-3 tasks với flavor text
3. Seed bag mechanic (giữ nguyên)
4. **MỚI**: Mini shop với 3 item hiển thị giá rõ (1 hạt + 10xu / 2 hạt + 15xu / ...)
5. Khi mua item → Mochi mặc item vào → Mochi vui → feedback tức thì

Cắt: bố mẹ approve (test emotional loop trước, test parent UX sau)
