# SPIKE-NOTE: Firebase Multi-Device Real-Time Sync

**Date:** 2026-07-04
**Path:** HTML (Firebase JS SDK v10, two-tab demo against a real Firestore project)

## Question Tested

Can a Firestore write from one device (parent approving a task) propagate via
real-time listener (`onSnapshot`) to a second device (child's live game session)
fast enough and reliably enough for the approve → reward flow (xu balance update,
`LEVELING_UP` animation, `chestCount`) to feel instant?

## Result: YES (core question) / UNTESTED (offline sub-question)

**Core sync latency — confirmed YES.** Measured across two independent browser
clients against a real (non-emulator) Firestore project:

```
n=8 | avg=151ms | min=127ms | max=439ms
```

All 8 samples land well under the ~1000ms threshold where UI feedback starts to
read as "waited for" rather than instant. The average (151ms) is comfortably in
"feels instant" territory for a reward moment — a human reaction-time-scale delay,
not a network-wait-scale one. Functional confirmation matched the numbers: the
tester watched the child tab and confirmed the xu counter updated and Mochi
reacted after clicking Approve on the parent tab.

**Offline-reconnect sub-question — not run this session.** The spike built a
toggle for this (parent "Go offline" → approve while offline → "Go back online",
using Firestore's `disableNetwork()`/`enableNetwork()`), but it wasn't exercised
in this test session. Not a red flag — Firestore's SDK has documented, well-worn
offline-queue behavior — but it's an assumption Pet Leveling's Edge Case 3 leans
on that hasn't been independently verified here.

**Caveat on test conditions:** both clients were browser tabs on the same machine/
network, not two physically separate devices on different networks (e.g., parent
on cellular data away from home). Real-world cross-network latency could push
toward the higher end of the observed range, but is very unlikely to exceed ~1-2s
even in poor conditions — and even then, the write itself succeeds server-side
immediately; only the child's *visual* update would lag, which is a cosmetic
concern, not a data-integrity one.

## What to Do Next

- **Proceed with `/design-system parent-approval` (GDD #11)** treating real-time
  sync latency as a solved problem — no need for optimistic-UI workarounds or
  special latency mitigation in the design.
- **Do a quick manual check of the offline-reconnect path** during #11's actual
  implementation (not worth another full spike — a 10-minute manual test is
  enough) before relying on it for Pet Leveling's Edge Case 3 or any Parent
  Approval edge cases that assume offline-then-sync behavior.
- No architecture or scope changes indicated. This was a feasibility check, not
  a design decision — it confirms the "feels instant" assumption already baked
  into `pet-leveling-evolution.md`'s Player Fantasy section is realistic.
