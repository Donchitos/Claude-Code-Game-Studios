# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file).
**Update**: Add a core-mechanic entry each sprint as systems are implemented.

## Core Stability (always run)

1. App launches to the Login screen without crash (iOS + Android).
2. Parent can sign in (Firebase Auth email/password) → Child Profile Selection.
3. Child can enter PIN → Pet Room loads (Mochi renders).
4. App survives background → foreground without crash or frozen game loop.

## Core Loop (update per sprint as implemented)

<!-- Add the primary mechanic for each sprint here as it ships. -->
5. [Task submit] Child taps "Đã xong!" → task appears pending + seed drop animation.
6. [Approve] Parent approves (on 2nd device or Parent view) → xu + energy credited,
   Mochi reacts (EXCITED) within ~200ms of the write syncing.
7. [Shop] Child with enough xu buys an item → xu debited once, item in inventory,
   double-tapping two cards does NOT overspend (single-flight guard — ADR-0008).
8. [Pet Room] Mood indicator + energy bar reflect current energy (no red at low).

## Data Integrity (offline-first — Pillar 1)

9. Submit a task while OFFLINE → appears immediately from cache, no spinner/error.
10. Reconnect → the pending write syncs, no data loss, no user action needed.
11. Kill + relaunch app → child profile, xu, energy, inventory all restored.

## Platform / Notifications

12. Task submit → parent device receives FCM notification within 60s (real device).
13. iOS: declining notification permission does NOT block onboarding; reminder
    deep-links to Settings (does NOT re-prompt — ADR-0010).

## Performance (per technical-preferences.md)

14. Pet Room holds 60fps on a mid-range 2019+ Android device (no visible drops).
15. No memory growth over 5 minutes in the Pet Room (≤150MB ceiling).
