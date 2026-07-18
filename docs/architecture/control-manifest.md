# Control Manifest

> **Engine**: Flutter 3.44.4 / Flame 1.37.0 / Dart 3.12.2
> **Last Updated**: 2026-07-16
> **Manifest Version**: 2026-07-16
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011 (all Accepted)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change
> **Director Gate**: TD-MANIFEST skipped — Lean mode (per-skill gates only run in `full` mode; phase gates already validated this architecture at `/gate-check pre-production`, 2026-07-13, verdict CONCERNS)

This manifest is a programmer's quick-reference extracted from all 11 Accepted ADRs,
`.claude/docs/technical-preferences.md`, and the Flutter+Flame 1.37 engine reference
docs. For the reasoning behind each rule, see the referenced ADR.

> **Update 2026-07-13 (initial)**: the 3 GDDs previously flagged `Needs Revision` (`time-decay.md`,
> `data-persistence-layer.md`, `flutter-flame-state-bridge.md`) have been re-synced to
> their governing ADRs and restored to `Approved` in `systems-index.md`. `architecture.md`'s
> Traceability Coverage Check has also been re-synced (was reporting stale 1/104; now
> reflects the real 56/104 covered). See "Known GDD/ADR Drift" below — now empty.
>
> **Update 2026-07-13 (revision 2, post-`/vertical-slice`)**: the manifest previously
> forbade the *correct* Firestore persistence API and mandated a nonexistent one
> (`cacheSettings`/`PersistentCacheSettings` does not exist in the actually-resolved
> `cloud_firestore` 6.6.0 — the `persistenceEnabled`/`cacheSizeBytes` pair is correct;
> see ADR-0003 Correction note). The manifest also mandated `.valueOrNull` and forbade
> `.value` on `AsyncValue` — backwards for the actually-resolved `riverpod` 3.3.2, which
> removed `.valueOrNull` (`.value` is now the safe accessor; see ADR-0002 Correction
> note). Both corrected below, at every line they appeared. `GameEventBus`'s replay
> requirement (ADR-0004 §5) was also widened from app-background-only to any newly-
> mounted subscriber. Treat this revision as authoritative over the initial same-day
> version — re-verify both API corrections against whichever exact `cloud_firestore`/
> `riverpod` versions are ultimately pinned for production; these are snapshots against
> versions resolved on 2026-07-13, not permanent guarantees.
>
> **Update 2026-07-15 (revision 3, post-project-scaffold)**: scaffolding `src/pubspec.yaml`
> via `flutter pub add` against a live pub.dev resolution (Flutter 3.44.6/Dart 3.12.2) found
> `firebase_auth` resolves to `^6.5.6` and `firebase_messaging` to `^16.4.3` — both a major
> version ahead of the `^5.x`/`^15.x` this manifest and ADR-0002 assumed. `pointycastle`
> confirmed at `^4.0.0` (already assumed correctly below after the 07-13 revision). Corrected
> at every line below. **Open item, not yet verified**: ADR-0002 Decision §6's claim that
> `firebase_auth` consolidates `wrong-password`/`user-not-found` into `invalid-credential`
> was written against `^5.x` — this has not been independently re-confirmed against `^6.5.6`.
> Story 001/Story 006 implementers must check this before relying on it.

---

## Foundation Layer Rules

*Applies to: Auth & Account (ADR-0002), Time & Decay (ADR-0005), Item Catalog (ADR-0006)*

### Required Patterns
- Parent authenticates via Firebase Auth `signInWithEmailAndPassword`; a child is NOT a Firebase Auth principal — a Firestore doc `families/{parentId}/children/{childId}` with an auto-generated doc ID — source: ADR-0002
- PIN verification is client-side: compute `PBKDF2-HMAC-SHA256(rawPin, salt, iterations=100000, keyLength=32)` via `pointycastle`, compare to stored hash — source: ADR-0002
- PBKDF2 computation MUST run off the main isolate (`Isolate.run`/`compute`) — source: ADR-0002
- Per-child 16-byte random salt required (never bare SHA-256) — source: ADR-0002
- Lockout state (`failCount` 0–3, `lockUntil` Unix ms) lives in `flutter_secure_storage` under `pin_fail_{childId}`/`pin_lock_{childId}` (stored as strings) — source: ADR-0002
- 3 consecutive PIN failures → 60s lock — source: ADR-0002
- `sessionStateProvider` is the single derived routing source of truth; no other system re-derives session state — source: ADR-0002
- go_router redirect MUST use an explicit refresh bridge (`ref.listen(sessionStateProvider, ...)`) since a plain Riverpod `Provider` is not `Listenable`. `GoRouterRefreshStream` is NOT available — removed from `go_router` in v5.0.0, not re-exported by `go_router ^17.3.0` — **corrected 2026-07-15** — source: ADR-0002
- Use the safe nullable accessor on `authStateProvider` — on `riverpod` 3.x this is `.value` (which no longer rethrows on `AsyncError`; `.valueOrNull` was removed) — verify against the pinned production `riverpod` version. **Corrected 2026-07-13**, was previously (wrongly, for 3.x) documented as "use `.valueOrNull`, never `.value`" — source: ADR-0002
- **New 2026-07-16, revised 2026-07-16**: any `FutureProvider`/`StreamProvider` whose build can throw a plain `Exception` (this includes `FirebaseException`, which implements `Exception` not `Error`) MUST pass `retry: (retryCount, error) => null`. `riverpod` 3.3.2's `ProviderContainer.defaultRetry` (verified against installed source, `provider_container.dart`) silently retries such providers up to 10 times with exponential backoff (200ms→6.4s, ~38s total) before the `AsyncValue` ever becomes a terminal `AsyncError` — during those retries `.when()` reports `isLoading: true`, not `error`, so a UI-level "Thử lại" button (or any GDD-required degraded/empty state) never gets a chance to render for up to ~38s on a real failure. Found via `childProfilesProvider`'s own error-state test in Story 011 code review — fixed there. **Found again** in `itemCatalogProvider` (Item Database Story 002, 2026-07-16) while writing its own query-failure test — the test itself hung for ~38s against the retry window before the fix was applied, which is what surfaced it. Fixed there too. Given this is the SECOND independent provider found with this exact gap, treat this rule as applying to EVERY `FutureProvider`/`StreamProvider` in this codebase, not just ones with a known UI retry affordance — **other existing declarations still have not been fully audited** — source: ADR-0002 (§ Foundation Layer, `childProfilesProvider`), ADR-0006 (`itemCatalogProvider`)
- Parent override MUST use `user.reauthenticateWithCredential(EmailAuthProvider.credential(...))`, NOT a second `signInWithEmailAndPassword` — source: ADR-0002
- Catch `FirebaseAuthException` generically — do not branch per error code (firebase_auth `^5.x` was believed to consolidate `wrong-password`/`user-not-found` into `invalid-credential`; actual resolved version is `^6.5.6` — **re-verify this consolidation claim still holds before relying on it**, see 2026-07-15 revision note above) — source: ADR-0002. **Scoped exception, added 2026-07-16 (Story 013)**: this "no per-code branching" rule applies to *sign-in* specifically (its purpose is preventing email enumeration via login attempts). `AuthRepository.signUp()` DOES branch on `email-already-in-use`/`weak-password`/`invalid-email` — a deliberate, different threat model (registration necessarily reveals email-taken status as standard, unavoidable UX; that's not the same leak login-enumeration would be). Do not flag `signUp()`'s branching as an ADR-0002 violation — see `design/quick-specs/parent-account-registration-2026-07-16.md` for the full rationale.
- `pinHash`/`pinSalt` live in `children/{childId}/private/credentials`, fetched only at PIN-entry, never on the profile-list document — source: ADR-0002
- `onChildProfileDelete` (2nd-gen `onDocumentDeleted`) recursively deletes via Admin SDK `firestore.recursiveDelete(ref)` — source: ADR-0002
- GDPR erasure Cloud Function must recursively delete `families/{parentId}/` + delete the Firebase Auth user record — must land before launch — source: ADR-0002
- Never log raw PIN/pinHash/pinSalt; mask PIN text-field input from Crashlytics/Sentry breadcrumbs — source: ADR-0002
- **New 2026-07-16 (Story 013)**: `signUp()` creates the Firebase Auth account via `createUserWithEmailAndPassword` FIRST, then writes `families/{parentId}` (`email`, `displayName` derived from the email local-part, `createdAt` via `FieldValue.serverTimestamp()`) — never the reverse order. `fcmToken` is omitted (not written null) on this path — Story 008's `onTokenRefresh` fills it in — source: `design/quick-specs/parent-account-registration-2026-07-16.md`
- `resetChildPin()` generates a fresh salt, re-hashes, resets `failCount` to 0, never kicks the active session — source: ADR-0002
- `computeEnergy` is evaluated ONLY on app-foreground/resume — no timer, no per-second recalculation — source: ADR-0005
- `computeEnergy` is pure/side-effect-free and performs no Firestore writes — source: ADR-0005
- Use `now.difference(lastApprovedAt)` (`Duration`), NOT `now - lastApprovedAt` (no `operator-` on `DateTime`) — source: ADR-0005
- Clamp `hoursElapsed` to `[0, maxHoursElapsed]` (default 168) — clock-manipulation guard — source: ADR-0005
- Use `elapsed.inMicroseconds / Duration.microsecondsPerHour`, NOT `inMinutes / 60.0` (truncates sub-minute elapsed to 0) — source: ADR-0005
- `now` MUST be injected into `computeEnergy`, never read from the wall clock inside it — source: ADR-0005
- Null `lastApprovedAt` (new profile) → use `createdAt` baseline, treat `storedEnergy` as `initialEnergy = 70`; never crash on null — source: ADR-0005
- Energy→mood lookup table is owned by Pet State Machine (ADR-0007), not Time & Decay; Time & Decay's copy is reference-only — source: ADR-0005
- Parent Approval's approve transaction MUST write `children/{childId}.lastApprovedAt = FieldValue.serverTimestamp()` — source: ADR-0005
- `energyProvider` needs an explicit `resumeTickProvider` dependency incremented via `AppLifecycleListener(onResume: ...)` — source: ADR-0005
- Only `onResume` ticks the resume provider (not pause/inactive) — source: ADR-0005
- Catalog is a global `items/{itemId}` top-level collection, NOT scoped under `families/{parentId}` — source: ADR-0006
- Fetch once per session via `.orderBy('sortOrder').get()`, cached in `itemCatalogProvider` (`FutureProvider<List<ItemModel>>`) — source: ADR-0006
- `itemCatalogProvider` must NOT be `.autoDispose` — source: ADR-0006
- Security rule: `allow read: if request.auth != null; allow write: if false` — source: ADR-0006
- Catalog path constant lives in centralized path constants — source: ADR-0006
- Read served by `itemCatalogProvider`'s cached `get()`, not `PersistenceRepository` mutation methods (scoped exception to ADR-0003's repository rule) — source: ADR-0006
- Empty catalog → provider returns `[]`; consumers render empty state, never crash — source: ADR-0006
- Post-load missing-item lookup returns null → consumer renders placeholder, may re-fetch — source: ADR-0006
- Type the factory param as `QueryDocumentSnapshot<Map<String, dynamic>>` (guaranteed non-null `.data()`) — source: ADR-0006
- `slot` MUST parse as `data['slot'] as String?`, NOT `as String` (12/30 MVP items store `slot: null`) — source: ADR-0006
- `price`/`sortOrder` MUST parse as `(data['price'] as num).toInt()`, NOT `as int` — source: ADR-0006
- `source` field is acquisition-location only, not a visibility flag; filtering is Shop/Gacha's concern — source: ADR-0006

### Forbidden Approaches
- Never give each child their own Firebase Auth identity (anonymous/custom-token) — violates COPPA no-child-identity requirement and breaks offline-first — source: ADR-0002
- Never verify PIN server-side via Cloud Function — breaks offline-first, adds latency, delivers zero net security gain — source: ADR-0002
- Never treat the PIN as a Firestore-enforced access-control boundary — it is UI-only (Non-Goal) — source: ADR-0002
- Do not over-correct into Argon2 or longer PINs — threat model doesn't warrant it — source: ADR-0002
- Do not resurrect per-error-code branching (wrong-password/user-not-found) — source: ADR-0002
- Never implement a background timer/scheduled recalculation for energy — battery drain, iOS background limits, no player-visible benefit — source: ADR-0005
- Never compute energy server-side via Cloud Function — breaks offline core loop for a cosmetic, already-bounded value — source: ADR-0005
- Time & Decay must never be a second writer of `storedEnergy`/`lastApprovedAt` — source: ADR-0005
- Never use a realtime `snapshots()` listener on the item catalog — multiplies read cost for data that changes ~monthly — source: ADR-0006
- Never bundle the catalog as a local app asset (JSON) — loses server-side content updates — source: ADR-0006
- Never read `items/` ad-hoc outside `itemCatalogProvider` — source: ADR-0006
- No rarity system on items — differentiation is price + source only — source: ADR-0006

### Performance Guardrails
- PBKDF2 100k iterations off-isolate: one-shot per PIN entry, negligible steady-state — source: ADR-0002
- PIN verify is local, sub-frame after hash completes — source: ADR-0002
- Energy calc: one subtraction + clamp per foreground — negligible CPU, zero battery/network — source: ADR-0005
- Fully offline, deterministic and testable — source: ADR-0005
- One Firestore read per session per device for catalog; zero mid-session — source: ADR-0006
- Full catalog held in memory (≤500 small models) — negligible — source: ADR-0006
- Cold-start `get()` < 2s on 4G; cache-served thereafter — source: ADR-0006
- 500-item hard cap before pagination required (MVP = 30) — source: ADR-0006

---

## Core Layer Rules

*Applies to: Firestore Schema & Persistence (ADR-0003), Flutter-Flame Event Bridge (ADR-0004), Pet State Machine (ADR-0007), Currency & Balance Mutation (ADR-0008), Task Lifecycle & Reward Integrity (ADR-0009), Push Notification Delivery (ADR-0010)*

### Required Patterns
- Enable Firestore offline persistence BEFORE the first Firestore call in `main()`: `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` — source: ADR-0003 (**corrected 2026-07-13** — verified against actually-resolved `cloud_firestore` 6.6.0, which has no `cacheSettings`/`PersistentCacheSettings` parameter; re-verify against the exact production-pinned version before relying on this)
- Fallback tuning knob: `cacheSizeBytes: 50*1024*1024` if old devices report storage pressure — source: ADR-0003
- All balance/counter mutation MUST use `FieldValue.increment()`, never absolute `set()` — source: ADR-0003
- Predictable-ID writes use `set(merge:true)`/`update()`; tasks use auto-generated IDs; inventory uses `itemId` as doc ID (idempotent) — source: ADR-0003
- `runTransaction` for read-before-write mutations (approve/reject task); idempotency read must be the FIRST read inside the transaction — source: ADR-0003
- Child profile/economy fields read via `snapshots()` `StreamProvider` scoped to `activeChildProvider` — source: ADR-0003
- **Exception, added 2026-07-15 (Story 005)**: the profile-*selection* list (`childProfilesProvider`, listing all ≤4 children for the picker screen, pre-selection) uses one-shot `get()`/`FutureProvider`, NOT `snapshots()` — same exception pattern as the item catalog below. Rationale: the rule above ("scoped to `activeChildProvider`") already only covers the *single active* child's live economy data; the selection list is a different, pre-`childSelected` concern with no realtime requirement (adding a sibling happens from Parent Dashboard, a different session state, never while this screen is open) — source: ADR-0003 amendment note (see that file's §Decision)
- Task lists need a composite index (status filter + orderBy + 30-day range) — source: ADR-0003
- Item catalog: one-time `get()`, session-cached — NOT `snapshots()` — source: ADR-0003
- Credentials sub-doc: `get()` only at PIN-entry, never streamed — source: ADR-0003
- Security Rules must use explicit nested per-collection `match` blocks, NEVER a blanket recursive wildcard — rules are OR'd across matching blocks, so a wildcard makes stricter rules inert (amended by ADR-0009) — source: ADR-0003/ADR-0009
- `onTaskApproved` Cloud Function (2nd-gen `onDocumentUpdated`) caps `storedEnergy` at 100 post-commit — source: ADR-0003
- `onChildProfileDelete` (2nd-gen `onDocumentDeleted`) uses Admin SDK `firestore.recursiveDelete()` — source: ADR-0003
- `PersistenceRepository` is the ONLY module that touches Firestore paths directly; path constants centralized there — source: ADR-0003
- Increment literal type MUST match the target field's stored type (int reward → int increment; double energy → double increment) — source: ADR-0003
- Document size must stay under Firestore's 1MB hard limit — source: ADR-0003
- Composite indexes are direction-specific — both ascending and descending entries required if both `orderBy` directions are used — source: ADR-0003
- `GameEventBus` is a pure-Dart `StreamController<GameEvent>.broadcast()` singleton, app-lifetime, importing neither Flutter nor Flame — source: ADR-0004
- Constructed once at app root; disposed only at app termination, never per-screen — source: ADR-0004
- `emit()` guards `!_controller.isClosed` (silent no-op + warning log if called after dispose) — source: ADR-0004
- Each `GameEventType` owns a distinct payload shape; payload types must never be shared across event types — source: ADR-0004
- Every `_onEvent` handler checks `event.type` before casting `event.data` — source: ADR-0004
- Exactly two sanctioned emit adapters: (a) `ref.listen` in a `ConsumerWidget` (Flutter→Flame, lives in the widget only); (b) Flame component emitting directly via `TapCallbacks`/`DragCallbacks` (Flame→Bus→Flame only) — source: ADR-0004
- One-way invariant: data never flows Flame→Flutter/Riverpod — source: ADR-0004
- Flame subscribers subscribe in `onMount()`, NOT `onLoad()` — source: ADR-0004
- Handler guards `if (!isMounted) return;` — source: ADR-0004
- `_sub?.cancel()` MUST be called in `onRemove()` — source: ADR-0004
- Use `isMounted` (not `parent != null`) — source: ADR-0004
- `GameEventBus` replays the LAST event per type to any newly-subscribing listener (never full event history) — **scope widened 2026-07-13**: this covers any new subscriber (e.g. a Flame-canvas screen remounted by navigation), not just app-background→foreground recovery, which was the original (too-narrow) framing. Implement as a bus-level last-event-per-type cache, not a one-time app-cold-start seed — source: ADR-0004
- `StreamController.broadcast()` created WITHOUT `sync: true` (microtask-scheduled listeners, reentrancy-safe) — source: ADR-0004
- Base Mood is a pure Riverpod derivation (`petMoodProvider`) from `energyProvider` — source: ADR-0007
- Emit `petMoodChanged` only when the mood BAND changes, not every energy tick — source: ADR-0007
- Triggered State is Flame-side ephemeral only — never persisted, never mirrored to Riverpod — source: ADR-0007
- `MochiComponent` caches Base Mood from the `petMoodChanged` event, never by reading Riverpod directly — source: ADR-0007
- Cold-start seed required: emit `petMoodChanged` once with `ref.read(petMoodProvider)` at initial build (or pass into constructor) — source: ADR-0007
- Energy→mood lookup (owned here): SLEEPING=10, SAD 11–19, TIRED 20–49, CONTENT 50–79, HAPPY ≥80 — source: ADR-0007
- Triggered-state priority: LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING — source: ADR-0007
- LEVELING_UP non-interruptible: other triggers queue (single highest-priority) and replay after 3s — source: ADR-0007
- SLEEPING accepts only EXCITED and LEVELING_UP, ignores other triggers — source: ADR-0007
- Triggered-state duration driven by Flame's frame-ticked `TimerComponent`/`Timer` (`update(dt)`), NOT wall-clock — source: ADR-0007
- Prefer one clock per triggered state — drive off the `Effect`'s own `onComplete` rather than a parallel `TimerComponent` — source: ADR-0007
- Construct a fresh `TimerComponent` per activation (or call `.start()` on retrigger, never just mutate `.limit`) — source: ADR-0007
- Use explicit priority map (`levelingUp:5,...,bouncing:1`) — NEVER `TriggeredState.index` — source: ADR-0007
- `_clearEffects()` before adding the next effect — required correctness, not polish, for transform-based states — source: ADR-0007
- "Prior effect cleared" validation must assert after a subsequent tick, not synchronously — source: ADR-0007
- Nothing may set `pauseWhenBackgrounded=false` on the shared `FlameGame`; any `lifecycleStateChange()` override must call `super` — source: ADR-0007
- Single currency (xu) only; all balance changes via `FieldValue.increment(±N)`, never absolute `set()` — source: ADR-0008
- Sources closed to: task approval (+xuReward) and Gacha chest reward only — source: ADR-0008
- Sinks closed to: Shop item purchase (−price) and Paid Chest purchase (−50) only — source: ADR-0008
- ≥0 floor enforced by Shop pre-write: check `xuBalance >= cost` before decrement batch — source: ADR-0008
- Shop MUST hold a screen-scoped `isPurchasing` single-flight guard disabling ALL purchase buttons while any purchase is in flight — mandatory — source: ADR-0008
- `xuBalanceProvider` is a realtime `StreamProvider<int>` scoped to active child, via `FirestorePaths` constant, using the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x — corrected 2026-07-13, was `.valueOrNull`) — source: ADR-0008
- `xuBalanceProvider` must NOT be `.autoDispose` — source: ADR-0008
- Negative-balance defense: UI displays 0, disables purchases, logs the value; never crash/render negative — source: ADR-0008
- Read `xuBalance` as `(x as num?)?.toInt()`, never `as int` — source: ADR-0008
- Task lifecycle: `pending → approved | rejected`, one doc per submission, no `cancelled`, no withdrawal — source: ADR-0009
- Authoritative reward table (owned here): study 25/20, arts 25/20, chores 15/25, sport 15/25, helping 10/30, custom 15/25 (fallback) — source: ADR-0009
- Security Rule MUST reject mismatched `xuReward`/`energyReward` vs category table on `create`; reward/category fields immutable on `update` — source: ADR-0009
- Rules map-literal keys MUST be quoted CEL strings, not JS-style bare keys — source: ADR-0009
- `onTaskApproved` additionally reconciles granted reward against `categoryId` (defense-in-depth) — source: ADR-0009
- `customTasks` are templates (`title, categoryId, targetChildId, createdAt` only) — NO `status`/`xuReward`/`energyReward` fields — source: ADR-0009
- `pendingTasksProvider`: `where(status=='pending').orderBy(submittedAt desc)` — 1 composite index — source: ADR-0009
- `taskHistoryProvider`: `where(status, whereIn:[...]).where(submittedAt range).orderBy(submittedAt desc)`, index DESCENDING; use `whereIn`, NOT `not-in` — source: ADR-0009
- Both task providers scoped via `FirestorePaths` + the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x — corrected 2026-07-13, was `.valueOrNull`) + null-guard returning `Stream.value([])` — source: ADR-0009
- Pending→approved/rejected status-transition constraint lives in the `tasks` match block itself, not a broader match — source: ADR-0009
- Cloud Function trigger MUST be 2nd-gen `onDocumentCreated` (not `onWrite` + manual guard) — source: ADR-0010
- Payload contract fixed shape: `notification{title,body}`, `data{type,taskId,childId,deepLink}` (all data values STRINGS), `android.priority:high`, `apns.headers['apns-priority']:10` — source: ADR-0010
- Title truncated ≤50 chars, body ≤80 chars, truncated before send — source: ADR-0010
- Client requests permission ONCE at onboarding via `FirebaseMessaging.instance.requestPermission()` — source: ADR-0010
- iOS reminder MUST deep-link to Settings (`UIApplication.openSettingsURLString`), NOT re-call `requestPermission()` — source: ADR-0010
- MUST read `getNotificationSettings().authorizationStatus` before branching reminder logic — source: ADR-0010
- Android may re-prompt normally — source: ADR-0010
- `data.deepLink` fixed as `petquest://parent/tasks/pending` — source: ADR-0010
- MVP ships with retry DISABLED — source: ADR-0010
- If retry ever enabled, handler MUST add an event-staleness guard (`event.time` > 60s → return) — source: ADR-0010
- Function memory config uses v2 `MemoryOption` string enum (e.g. `'256MiB'`), not a bare number — source: ADR-0010
- Null/empty token → log + exit (task still created); invalid-token error → log, NO retry, NO token delete — source: ADR-0010
- iOS permission/deep-link flow MUST be validated on real TestFlight hardware before considered done — source: ADR-0010

### Forbidden Approaches
- Never route core-loop mutations (submit/approve/buy) through a Cloud Function as the primary path — breaks offline-first — source: ADR-0003
- Never let systems build Firestore paths by hand — source: ADR-0003
- Server-authoritative writes (all mutations via Cloud Functions) rejected — breaks offline-first pillar — source: ADR-0003
- Hybrid client/server write split rejected — approve-task (most important offline moment) is exactly an economy write, still requires connectivity — source: ADR-0003
- Never let Flame components watch Riverpod directly via `ProviderContainer` — couples display to state layer, untestable, blurs one-way boundary — source: ADR-0004
- Never allow bidirectional bus / Flame→Flutter callbacks — destroys single-source-of-truth — source: ADR-0004
- Never subscribe in `onLoad()` — `isMounted` stays false the whole time, silently drops events during load→mount; no teardown pairing; runs once ever vs. re-add cycles — source: ADR-0004
- Never allow a third emit path (Notifier emitting directly, or a component writing a provider) — source: ADR-0004
- Do not copy the reference spike's `onLoad()` subscribe pattern into production — source: ADR-0004
- Never model triggered states as Riverpod state — wall-clock timer wouldn't pause with the loop, breaking the background-pause requirement — source: ADR-0007
- Never compute Base Mood inside the Flame game loop — untestable, forces a forbidden Flame→Flutter path for UI — source: ADR-0007
- Never expose a Currency-owned guarded-decrement method / centralize the ≥0 floor in Currency or Security Rules — extra transaction cost not justified — source: ADR-0008
- Never implement dual currency / premium coin — opens pay-to-win, violates Pillar 1 — source: ADR-0008
- Never use absolute `set()` on `xuBalance` (registered `absolute_set_on_balance_or_counters` forbidden pattern) — source: ADR-0008
- Never use inline Firestore path strings in `xuBalanceProvider` — source: ADR-0008
- Never validate rewards via Cloud Function at creation only — asynchronous, a parent could approve before the function runs — source: ADR-0009
- Never re-derive reward at approve time instead of trusting the write-validated stored value — approve is a client-side transaction, re-derivation is equally client-controlled — source: ADR-0009
- Never let a parent set reward values directly on `customTasks` templates — source: ADR-0009
- Do not "simplify" the history query to `not-in` — source: ADR-0009
- Never send FCM directly from the client — exposes server key, submitting device is usually the child's, can't work offline — source: ADR-0010
- Never use scheduled/polling notification instead of push — defeats "instant" pillar, battery/background cost — source: ADR-0010
- Do not enable `retry:true` for MVP — time-window-bounded not attempt-bounded, risks many duplicate pushes — source: ADR-0010
- Do not use `onWrite` + manual `before.data==null` guard — source: ADR-0010

### Performance Guardrails
- Cold start reads from local cache first (instant), syncs in background — source: ADR-0003
- Each `snapshots()` listener = 1 read per change (cost flagged at 1000+ families, not MVP-blocking) — source: ADR-0003
- Unlimited cache can grow on-device; 50MB fallback knob available — source: ADR-0003
- Local bridge delivery <1ms; end-to-end (parent approve → child Mochi) measured avg 151ms / max 439ms — source: ADR-0004
- Broadcast stream dispatch is synchronous in-isolate — negligible CPU — source: ADR-0004
- One subscription per subscribing component, freed on `onRemove()` — source: ADR-0004
- Mochi + triggered animation counts against ADR-0001's ≤200 Flame-canvas draw-call budget (Pet Room tally = 5) — source: ADR-0007
- Base Mood lookup + one component/timer — negligible CPU/memory — source: ADR-0007
- No extra transaction on the currency hot path — spends are batches (pre-ADR-0011), not transactions — source: ADR-0008
- One realtime balance listener per active child (shared, not per-widget) — source: ADR-0008
- Rule evaluation per task write — negligible CPU — source: ADR-0009
- Bounded task lists (30-day history window + tuning-knob caps) — source: ADR-0009
- 2 realtime listeners (pending, history) per active child — source: ADR-0009
- End-to-end push latency target <10s / worst-case <60s (test asserts 60s) — source: ADR-0010
- Cold-start latency up to ~30s acceptable (within 60s contract) — source: ADR-0010
- One FCM send per task submit; one Firestore read set per invocation — source: ADR-0010

---

## Feature Layer Rules

*Applies to: Shop Purchase Pipeline & Idempotency Fix (ADR-0011)*

### Required Patterns
- Regular item purchase MUST use `runTransaction` gated on the natural key `inventory/{itemId}`; existing doc → no-op `PurchaseResult.alreadyOwned` — source: ADR-0011
- ALL reads before ANY writes inside the transaction — source: ADR-0011
- SDK transaction defaults (maxAttempts:5, exponential backoff, ~30s timeout) used as-is, not overridden — source: ADR-0011
- Server-side balance re-check (`balance < price` → `insufficientFunds`) happens inside the transaction — source: ADR-0011
- Paid Chest purchase MUST use `runTransaction` gated on a client-generated `purchaseId` (UUID v4) checked against a `purchaseLog` doc read before any write — source: ADR-0011
- `purchaseId` generated ONCE per logical purchase attempt, reused across a manual retry after perceived failure; a NEW id only after success or abandoning the flow — source: ADR-0011
- `paidChestPrice` sourced from registry constant `gacha_paid_chest_price` (=50 xu), not a fresh literal — source: ADR-0011
- Purchases require connectivity — `connectivity_plus` pre-check disables buttons offline with "Cần kết nối mạng để mua"; no write attempted — source: ADR-0011
- Any `runTransaction` throw handled identically: re-enable buttons, "Mua không thành công, thử lại" toast, balances unchanged — source: ADR-0011
- No client-side automatic retry loop — a new tap is the retry — source: ADR-0011
- `onAnimationComplete` is a plain Flutter callback (`PurchaseAnimationCompleteCallback`), NOT a `GameEventBus` event — source: ADR-0011
- Callback fires exactly once per successful Paid Chest purchase, AFTER the transaction commits — source: ADR-0011
- Callback never fires for `alreadyProcessed`/`insufficientFunds`/failure — only fresh `success` — source: ADR-0011
- `purchaseLog` Security Rule MUST be an explicit nested match block: `allow read, write: if request.auth.uid == parentId` — source: ADR-0011
- New path constants `FirestorePaths.inventoryItem()` and `FirestorePaths.purchaseLog()` required — source: ADR-0011
- ADR-0008's single-flight guard stays in force unchanged (this ADR backstops it, doesn't replace it) — source: ADR-0011

### Forbidden Approaches
- Never keep `WriteBatch` + Cloud Function reconciliation as substitute for synchronous prevention — async correction collides with the No-Refund Rule — source: ADR-0011
- Never regenerate `purchaseId` on retry — silently defeats the idempotency guard, reproducing the double-charge this ADR prevents — source: ADR-0011
- Never use a client token as the uniform mechanism for items — items already have a free natural key (`inventory/{itemId}`) — source: ADR-0011

### Performance Guardrails
- One additional document read per purchase, inside a transaction already touching the child doc — negligible — source: ADR-0011
- One extra small doc per Paid Chest purchase; no memory impact for items — source: ADR-0011
- Purchases now require an active connection — the main network-behavior change — source: ADR-0011

---

## Presentation Layer Rules

*Applies to: Draw-Call Budget Scope (ADR-0001) — cross-cutting: applies to any screen hosting a Flame canvas, not just Pet Room*

### Required Patterns
- The ≤200 draw-call budget applies to the Flame canvas ONLY — each unbatched renderable component = 1 draw call; logic-only nodes that paint nothing don't count — source: ADR-0001
- Use `SpriteBatch` to reduce repeated sprites to fewer submitted calls — source: ADR-0001
- Flutter widget compositing is governed by a SEPARATE metric (frame build/raster time, DevTools Performance view, 16.6ms budget) — NOT folded into the 200-call count — source: ADR-0001
- Overlay widgets must use targeted `Consumer`/`Selector` rebuild scoping (Riverpod `select`), not rebuilding large subtrees on every tick — source: ADR-0001
- `drawCalls_sceneFlame(screen) = Σ(Flame render calls, post-SpriteBatch)` is the ONLY quantity checked against ≤200 — source: ADR-0001
- If frame time regresses, use Timeline events (`debugProfilePaintsEnabled`) or platform-native GPU capture to localize the cause; do not assume DevTools alone can isolate the Flutter layer's contribution — source: ADR-0001

### Forbidden Approaches
- Never fold Flutter widget cost into the 200-draw-call count — source: ADR-0001
- Whole-app Skia/Impeller output count rejected — not measurable at GDD-authoring time, produces a number nobody can act on — source: ADR-0001

### Performance Guardrails
- ≤200 draw calls/frame (Flame canvas only) — source: ADR-0001 / technical-preferences.md
- 16.6ms/frame budget shared by Flame canvas + Flutter overlay (60fps target) — source: ADR-0001
- Validation requires 3 physical-device profiling passes (Android Impeller/Vulkan, Android OpenGLES fallback, iOS Impeller/Metal), all within 16.6ms/frame — source: ADR-0001
- No automated CI check currently enforces the frame-time side of this budget (process gap, flagged — not yet resolved) — source: ADR-0001

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Classes / Components | PascalCase | `PetStateMachine`, `GameEventBus` |
| Variables / functions | camelCase | `xuBalance`, `computeEnergy()` |
| Signals/Events | camelCase stream names | `onPetMoodChanged`, `petInteracted` |
| Files | snake_case matching primary class | `pet_state_machine.dart` |
| Constants | camelCase preferred; `SCREAMING_SNAKE_CASE` acceptable for compile-time constants | `maxHealth`, `MAX_LEVEL` |

*Source: `.claude/docs/technical-preferences.md`*

### Performance Budgets
| Target | Value |
|--------|-------|
| Framerate | 60fps |
| Frame budget | 16.6ms |
| Draw calls | ≤200 per frame (Flame canvas only — see ADR-0001 scoping) |
| Memory ceiling | ≤150MB RAM on mid-range Android devices (2019+) |

*Source: `.claude/docs/technical-preferences.md`, scoped by ADR-0001*

### Approved Libraries / Addons
- Formalized 2026-07-15 in `src/pubspec.yaml` (real `flutter pub add` resolution against Flutter 3.44.6/Dart 3.12.2): `pointycastle ^4.0.0` (PBKDF2, ADR-0002), `flutter_secure_storage ^10.3.1` (ADR-0002), `cloud_firestore ^6.7.1`, `firebase_auth ^6.5.6`, `firebase_messaging ^16.4.3`, `firebase_core ^4.12.1`, `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, `flame ^1.37.0`. `connectivity_plus` (ADR-0011) not yet added — pending the Shop Purchase Pipeline epic. `.claude/docs/technical-preferences.md`'s "Allowed Libraries/Addons" section still reads "[None configured yet]" — update it to match `src/pubspec.yaml` next time that file is touched.
- **`functions/` (Cloud Functions, Node.js/TypeScript — different runtime, Story 009, 2026-07-15)**: `firebase-functions ^7.2.5`, `firebase-admin ^13.10.0` (NOT `^14.x` — `firebase-functions@7.2.5`'s peerDependency caps at `^13.0.0`, real `npm install` conflict, verified), `typescript ^6.0.3` (NOT `^7.x` — `ts-jest@29.4.11`'s peerDependency caps at `<7`, real conflict; TypeScript 7.0.2 is genuinely released, just not yet supported by the test toolchain), `jest ^30.4.2`, `ts-jest ^29.4.11`, `@types/jest ^30.0.0`. `tsconfig.json` uses `"module"/"moduleResolution": "nodenext"` (NOT `"node"` — deprecated as of TS 6.0, real compiler error otherwise) + `"isolatedModules": true` (required by `ts-jest` for `nodenext`, otherwise a real warning). Root-level `firebase.json`/`.firebaserc` (distinct from `src/firebase.json`, which is FlutterFire's client config, different schema/purpose) point at `functions/` and project `pet-quest-39d38`. No Java Runtime is available in this dev environment — the Firestore/Functions emulator suite cannot run here; Cloud Function tests use `jest.mock` against `firebase-admin`, not a live emulator (documented per-file). Future Cloud Functions in other epics (`onTaskApproved` ADR-0003/0009, `onTaskSubmitted` ADR-0010) should reuse this same `functions/` project and dependency versions rather than re-resolving the same peer-dependency conflicts.

### Forbidden APIs (Flutter 3.44.4 / Flame 1.37.0)
- `TapDetector` mixin — deprecated since Flame 1.21, use `TapCallbacks` instead
- `DoubleTapDetector` — deprecated since Flame 1.21, use `DoubleTapCallbacks` instead
- `LongPressDetector` — deprecated since Flame 1.21, use `LongPressCallbacks` instead
- `DragDetector` — deprecated since Flame 1.21, use `DragCallbacks` instead
- `HoverCallbacks` (old, non-event-based) — deprecated since Flame 1.24, use the new event-based `HoverCallbacks` API instead
- `component.shrinkwrap` — removed entirely in Flame 1.30, set `size` explicitly instead
- `HasGameRef` mixin — ongoing deprecation, use `FlameGame` direct reference / `findGame()` or dependency injection instead
- `Color(0xFFRRGGBB)` int constructor — deprecated since Flutter 3.27, use `Color.fromARGB()`/`Color.fromRGBO()` instead
- `WillPopScope` — removed in Flutter 3.22+, use `PopScope` instead
- `MaterialStateProperty` — deprecated since Flutter 3.22, use `WidgetStateProperty` instead
- `MaterialState` enum — deprecated since Flutter 3.22, use `WidgetState` enum instead
- Old `ThemeData` color fields (e.g. `primaryColor`) — deprecated since Flutter 3.22+ (Material 3), use `ColorScheme` fields instead

*Source: `docs/engine-reference/flutter-flame/deprecated-apis.md`*

> **Removed 2026-07-13**: this list previously included `Settings(persistenceEnabled:/cacheSizeBytes:)` as forbidden/deprecated, directing implementers to the nonexistent `cacheSettings`/`PersistentCacheSettings` API instead. Verified wrong against the actually-resolved `cloud_firestore` 6.6.0 (see ADR-0003 Correction note, 2026-07-13) — `persistenceEnabled`/`cacheSizeBytes` is the correct, non-deprecated API for that version and is now the Required Pattern in the Core Layer section above.

### Cross-Cutting Constraints
- Never use absolute `set()` on a balance or counter field — always `FieldValue.increment()` (registered `absolute_set_on_balance_or_counters`) — source: ADR-0003, ADR-0008
- Never write a blanket recursive wildcard Firestore Security Rule (`match /{document=**}`) — rules OR across matching blocks, making stricter nested rules inert; always use explicit nested per-collection matches (registered `blanket_recursive_firestore_rule`) — source: ADR-0003 (amended), ADR-0009, reaffirmed ADR-0011
- Never build Firestore paths as inline strings — always use centralized `FirestorePaths` constants — source: ADR-0003 intent, ADR-0006, ADR-0008, ADR-0009, ADR-0011
- Never subscribe to `GameEventBus` in a Flame component's `onLoad()` — always `onMount()`, with `isMounted` guard and `.cancel()` in `onRemove()` — source: ADR-0004, reaffirmed ADR-0007
- Never let a Flame component read Riverpod/`ProviderContainer` directly — one-way Flutter→Flame flow only — source: ADR-0004, ADR-0007
- Never use whichever `AsyncValue` accessor rethrows on `AsyncError` for routing-critical or balance-critical state — use the safe nullable accessor instead. **Corrected 2026-07-13**: for `riverpod` 3.x this means use `.value` (which is now itself the safe accessor) and NOT `.valueOrNull` (removed in 3.x) — the opposite of this constraint's original wording, which was never compiled against a real package version. Re-verify against the pinned production `riverpod` version — source: ADR-0002, reaffirmed ADR-0003, ADR-0008, ADR-0009
- Gameplay/economy values must be data-driven from a registry/constants source, never hardcoded literals — source: `.claude/docs/coding-standards.md`, reaffirmed ADR-0011
- Cast Firestore numeric fields as `(x as num?)?.toInt()`/`.toDouble()`, never a direct `as int`/`as String`, when a field can be null or int/double-ambiguous — source: ADR-0006, ADR-0008

---

## Known GDD/ADR Drift (do not implement from these GDD sections)

**All clear as of 2026-07-13.** Every drift item found by `/architecture-review`
(2026-07-11) and re-confirmed still-live by `/gate-check pre-production` (2026-07-13)
has been resolved and re-verified against the actual file content:

| GDD | Was | Resolved to | Status |
|---|---|---|---|
| `design/gdd/time-decay.md` L35 | `(now - lastApprovedAt).inMinutes / 60.0` (invalid Dart, truncates) | `.difference().inMicroseconds / Duration.microsecondsPerHour` per ADR-0005 §2 | ✅ Fixed 2026-07-13 |
| `design/gdd/data-persistence-layer.md` L199–209 | Blanket wildcard Firestore rule | Explicit nested per-collection matches per ADR-0003 §5 (amended) / ADR-0009 §3 | ✅ Fixed 2026-07-13 |
| `design/gdd/flutter-flame-state-bridge.md` L203 | AC said subscribe in `onLoad()` | Subscribe in `onMount()` per ADR-0004 §4 / Core Rule 5 | ✅ Fixed 2026-07-13 |
| `design/gdd/pet-leveling-evolution.md` xuBonus | 3-way contradiction (+50/80/120/200 vs 75/100/125/150 vs +75/100 AC) | Reconciled to 75/100/125/150 (Formula/Tuning Knob/AC set) per Creative + Technical Director recommendation | ✅ Fixed 2026-07-13 |

All 3 GDDs previously flagged `Needs Revision` restored to `Approved` in `systems-index.md`.
`docs/architecture/architecture.md`'s Traceability Coverage Check re-synced from stale
1/104 to the real 56/104. See `production/gate-checks/gate-check-2026-07-13.md` for the
original exit-criteria list this closes.
