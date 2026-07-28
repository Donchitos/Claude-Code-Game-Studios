# PetQuest Core Loop — Vertical Slice

**VERTICAL SLICE — NOT FOR PRODUCTION.** Reference only; never import or refactor into production code.

## Hypothesis Being Tested

Does a player experience "pet mirrors real effort, no effort ever lost" (Pillar 1+2)
within 3–5 minutes, without developer guidance — and can the team build one full
[submit → seed → parent-approve → reward → pet-reacts] loop in 1–3 weeks at
representative code quality (not throwaway prototype quality)?

Full validation question, scope, and results: see `REPORT.md`.

## How to Run

Requires: Flutter 3.44.x, Firebase CLI, a JRE (for the Firestore Emulator).

```bash
# Terminal 1 — start the emulators (Auth + Firestore, no real Firebase project needed)
firebase emulators:start --project petquest-vertical-slice --only auth,firestore

# Terminal 2 — run the app
flutter run -d chrome
# or: flutter run -d web-server --web-port 8765 --web-hostname 127.0.0.1
```

Dev login PIN: `1234` (seeded automatically on first run — one family, one child,
no onboarding flow in this slice).

Firestore Emulator UI: `http://127.0.0.1:4000` (useful for inspecting `xuBalance`/
`storedEnergy` directly while testing).

## Current Status

**Concluded** — 2026-07-13. Verdict: **PROCEED**. See `REPORT.md` for full findings.

## Findings Summary

- Full submit → approve → reward → Mochi-reacts loop works end-to-end, unguided, in one playtest session.
- 5 real bugs/gaps found via self-test before playtest (2 real cross-cutting API drifts affecting ADR-0002/0003/0008, 1 tooling friction point cut from scope, 2 bugs in this slice's own code) — see `REPORT.md` Technical Findings / Lessons Learned.
- Real Firebase Auth is NOT used in this build (Auth Emulator on Flutter Web hit an unresolved `api-key-not-valid` error) — PIN-gated access is still real (PBKDF2), just not layered on a real Firebase Auth identity here.
- Emotional/fun feel was explicitly NOT assessable at this build's placeholder-art fidelity (confirmed directly by the playtester) — this is expected, not a loop-design failure.
