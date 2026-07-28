# SPIKE: Firebase Multi-Device Real-Time Sync

## Hypothesis / Question

Can a Firestore write from one device (parent approving a task) propagate via
real-time listener (`onSnapshot`) to a second device (child's live game session)
fast enough and reliably enough for the approve → reward flow (xu balance update,
`LEVELING_UP` animation, `chestCount`) to feel instant?

This underpins the not-yet-designed **Parent Approval GDD (#11)** — the whole
"remote approval" value prop assumes the parent's device and the child's device
are physically separate, and that the reward feels immediate on the child's screen
without a manual refresh.

Secondary question: does the offline-queue assumption already written into
`pet-leveling-evolution.md` Edge Case 3 (parent writes while offline, child catches
up once the write flushes) actually work as Firestore's SDK claims?

## How to Run

Requires a free, disposable Firebase project (Firestore enabled, Native mode,
open rules — see comments in `firebase-config.js`). The local Firestore emulator
was not usable for this spike (no Java runtime available in the dev environment),
so this tests against a **real** Firestore backend over the real network — which
is arguably more honest for a "does this feel instant" question than a localhost
emulator would be anyway.

1. Create a free Firebase project, enable Firestore, copy the web app config into
   `firebase-config.js` (replace the `FILL_ME_IN` placeholders).
2. Serve this directory with any static file server — **do not** open the files
   via `file://`, browsers block ES module imports over `file://` due to CORS.
   ```
   npx serve .
   # or: python3 -m http.server 8000
   ```
3. Open `parent.html` in one browser tab/window and `child.html` in another
   (ideally a genuinely separate device on the same or different network — a
   second laptop, or your phone's browser pointed at your machine's LAN IP —
   to make "two devices" real rather than "two tabs on one machine").
4. Click **"Approve Task (+20 xu)"** on the parent page repeatedly. Watch the
   child page: Mochi should pulse, the xu counter should update, and a latency
   reading (ms from parent click to child update) should appear.
5. Click **"Go offline"** on the parent, click Approve 2-3 times while offline,
   then click **"Go back online"** — confirm the child eventually receives all
   the queued approvals once the parent reconnects.

## Current Status

Concluded.

## Findings

**YES** (core question) — measured against a real Firestore project across two
independent browser clients: `n=8 | avg=151ms | min=127ms | max=439ms` from
parent click to child update. Well within "feels instant" territory. Offline-
reconnect sub-question was built but not exercised this session — flagged as a
quick manual check to do during actual implementation, not a blocker.

Full detail and next steps: see `SPIKE-NOTE.md` in this directory.
