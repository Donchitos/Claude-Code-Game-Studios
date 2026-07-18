# Prototypes Index

*Updated: 2026-06-25*

## Concept Prototypes

| Concept | Date | Path | Verdict | Notes |
|---------|------|------|---------|-------|
| [task-approval-loop](task-approval-loop-concept/REPORT.md) | 2026-06-25 | HTML | **PIVOT** | Pipeline đúng, thiếu emotional destination. See [PIVOT-NOTE](task-approval-loop-concept/PIVOT-NOTE.md) |
| [pet-emotional-loop](pet-emotional-loop-concept/REPORT.md) | 2026-06-25 | HTML | **PROCEED** ✅ | Emotional loop validated: Mochi sad → bé muốn cứu → làm task → mua đồ → Mochi vui |

## Spikes

*None yet.*

## Vertical Slices

| Concept | Date | Path | Verdict | Notes |
|---------|------|------|---------|-------|
| [petquest-core-loop](petquest-core-loop-vertical-slice/REPORT.md) | 2026-07-13 | Flutter/Flame | **PROCEED** ✅ | First-run slice (no prior PIVOT). 9 Foundation/Core systems, full submit→approve→react loop validated unguided in 1 playtest session. 5 real bugs found via self-test (2 real ADR-vs-actual-package API drifts: cloud_firestore Settings API, riverpod 3.x `.valueOrNull` removal). Emotional feel not yet assessable at placeholder-art fidelity (expected, not a loop failure). |

---

## PIVOT Chain

```
task-approval-loop (PIVOT #1)
  └─► pet-emotional-loop (PROCEED ✅)
```

## Key Learnings Across Prototypes

- **2026-06-25 (v1)**: "Show the destination before the journey" — shop/pet response phải visible ngay từ đầu. Instant gratification thật sự = tác động có ý nghĩa, không chỉ là visual feedback.
- **2026-06-25 (v2)**: Emotional hook > Mechanical reward. Bé làm task "vì Mochi" mạnh hơn "để có xu". Pet bond là core motivation — build everything around it.
