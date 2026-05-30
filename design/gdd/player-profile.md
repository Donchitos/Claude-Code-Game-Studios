# Player Profile & Persistence — Game Design Document

> **System**: Player Profile & Persistence
> **Priority**: MVP
> **Layer**: Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The Player Profile & Persistence system is the canonical account state store for every player in BRAWLZONE. It is the single source of truth for who a player is, what they own, how they have performed, and what privileges they hold. Every other system that needs to know anything about a player reads from or writes to this system — no system maintains its own shadow copy of profile data.

### What This System Owns

| Domain | Fields |
|---|---|
| Identity | `user_id`, `display_name`, `avatar_id`, `region`, `created_at`, `last_seen_at` |
| Game Stats | `total_matches`, `wins`, `losses`, `kills`, `preferred_character_id` |
| Ranking | `mmr`, `peak_mmr`, `is_provisional`, `provisional_match_count` |
| Economy | `diamond_balance` |
| Entitlements | `has_no_ads`, `has_play_pass` |
| Progression | `xp`, `level` |
| Unlocks | `unlocked_character_ids` (earnable characters only) |
| Settings | `analytics_consent`, `display_name_last_changed_at` |

### What This System Does Not Own

- **Inventory** — cosmetic items, skins, emotes (owned by the Inventory system; profile only holds the `avatar_id` pointer).
- **Match history** — individual match records (owned by the Match History system; profile holds aggregated stats only).
- **Quest state** — active quest progress (owned by the Quest/Mission system; profile exposes XP/level as a hook).
- **Session tokens** — JWT issuance and validation (owned by Authentication / Supabase Auth).

### Role in the System Graph

Player Profile sits at the center of Block 2 infrastructure. Authentication creates the identity anchor (a stable `user_id` from Supabase Auth); Player Profile builds the game-state record on top of that anchor. All downstream systems — MMR/Ranked, Currency, Inventory, Matchmaking, Main Menu, XP & Progression, Quest/Mission, Moderation/Reporting, and Purchase Fulfillment — treat the profile record as the authoritative source and write back to it through defined, owned mutation paths.

---

## 2. Player Fantasy

### Identity and Ownership

Players should feel that their profile is their home in BRAWLZONE — a persistent record of everything they have built, earned, and achieved. The display name and avatar are the player's public face; every opponent they face sees these details in pre-match lobbies, scoreboards, and post-match screens. Owning a unique name and a distinctive avatar should feel meaningful, not arbitrary.

### Progression and History

Stats accumulate visibly. A player with 500 matches and a 58% win rate should feel the weight of that history — it took effort to get there, and the profile reflects it. The preferred character field surfaces naturally from play patterns, giving the player a sense that the game understands and remembers their playstyle.

MMR and rank are the clearest signal of competitive progress. The profile stores both the current MMR and the peak MMR, so a player who climbed to Diamond and fell back still has visible evidence of their best performance.

### Trust and Fairness

Economy fields (Diamond balance, entitlements) are never optimistically updated on the client. Players trust that their balance is real because every number they see was confirmed by the server. This matters most after a purchase or a match reward — the UI waits for server confirmation before showing updated values.

### Privacy

Players can withdraw analytics consent at any time. That flag is stored on the profile and respected immediately. Account deletion is handled within the GDPR right-to-erasure flow described in Section 5.

---

## 3. Detailed Rules

### 3.1 Full Profile Schema

All fields stored in the `player_profiles` PostgreSQL table (via Supabase). Fields marked **server-only** are never sent to the client. Fields marked **client-visible** are included in the profile payload returned to the authenticated client that owns the profile. Fields marked **public** are included in the trimmed profile payload visible to other players (opponents, leaderboards).

| Field | Type | Default | Visibility | Notes |
|---|---|---|---|---|
| `user_id` | `uuid` | — (from Supabase Auth) | client-visible, public | Primary key; immutable after creation |
| `display_name` | `varchar(20)` | `"Player_<6-char-alphanum>"` | client-visible, public | Unique; see display name rules |
| `avatar_id` | `varchar(64)` | `"default_avatar"` | client-visible, public | Foreign key into asset manifest; must be owned or default |
| `region` | `varchar(32)` | `"auto"` | client-visible | Set on first login from client-reported locale; used by Matchmaking |
| `created_at` | `timestamptz` | `NOW()` | client-visible | Immutable after creation |
| `last_seen_at` | `timestamptz` | `NOW()` | client-visible | Updated on every successful login |
| `total_matches` | `integer` | `0` | client-visible, public | Incremented by Match Server only |
| `wins` | `integer` | `0` | client-visible, public | Incremented by Match Server only |
| `losses` | `integer` | `0` | client-visible, public | Incremented by Match Server only |
| `kills` | `integer` | `0` | client-visible, public | Incremented by Match Server only |
| `preferred_character_id` | `varchar(64)` | `null` | client-visible, public | Set by Match Server to the character used most often; null until ≥1 match |
| `mmr` | `integer` | `1000` | client-visible, public | Mutated by MMR/Ranked system only; starting value 1000 |
| `peak_mmr` | `integer` | `1000` | client-visible, public | Updated by MMR/Ranked system whenever `mmr` exceeds `peak_mmr` |
| `is_provisional` | `boolean` | `true` | client-visible | Derived from `provisional_match_count < 30`; also stored as computed field |
| `provisional_match_count` | `integer` | `0` | server-only | Incremented by Match Server; drives `is_provisional`; hidden from client |
| `diamond_balance` | `integer` | `0` | client-visible | Mutated by Currency system only; non-negative enforced at DB level |
| `has_no_ads` | `boolean` | `false` | client-visible | Mutated by Purchase Fulfillment only |
| `has_play_pass` | `boolean` | `false` | client-visible | Mutated by Purchase Fulfillment only |
| `xp` | `integer` | `0` | client-visible | Mutated by XP & Progression system only |
| `level` | `integer` | `1` | client-visible, public | Mutated by XP & Progression system only; minimum 1 |
| `unlocked_character_ids` | `text[]` | `["character:vex","character:zook","character:sera"]` | client-visible | Array of character IDs; free characters pre-populated on creation; earnable characters appended by Character Unlock system |
| `analytics_consent` | `boolean` | `true` | client-visible | Mutable by the owning player via Settings; defaults to true per onboarding flow |
| `display_name_last_changed_at` | `timestamptz` | `null` | server-only | Used to enforce 30-day cooldown; not exposed to client |
| `is_deleted` | `boolean` | `false` | server-only | Soft-delete flag; set by Account Deletion flow; profile is excluded from all queries once true |
| `deleted_at` | `timestamptz` | `null` | server-only | Set at time of soft-delete |
| `deletion_scheduled_at` | `timestamptz` | `null` | server-only | Hard-delete scheduled 30 days after soft-delete for GDPR compliance |
| `schema_version` | `integer` | `1` | server-only | Incremented on migration; used for cache invalidation on schema change |

**Database-level constraints:**
- `diamond_balance >= 0` — enforced by `CHECK` constraint; cannot go negative.
- `level >= 1` — enforced by `CHECK` constraint.
- `display_name` — `UNIQUE` index; case-insensitive uniqueness enforced via `LOWER(display_name)` unique index.
- `provisional_match_count >= 0` — enforced by `CHECK` constraint.

### 3.2 Profile Creation Flow (First Login)

Triggered when Supabase Auth confirms a new `user_id` that has no corresponding row in `player_profiles`.

1. **Auth hook fires** — Supabase Auth `on_auth_user_created` trigger fires on the database.
2. **Default name generation** — Server generates a candidate display name: `"Player_" + random_alphanum(6)`. Check uniqueness against the `LOWER(display_name)` index. Retry up to 5 times if collision detected. If all 5 attempts collide (astronomically unlikely), use `user_id` prefix (first 8 hex chars) as fallback.
3. **Free character grant** — `unlocked_character_ids` is pre-populated with the 3 free character IDs: `["character:vex","character:zook","character:sera"]`.
4. **Profile row insert** — Single `INSERT` with all fields at their defaults (see schema above), using the `user_id` from Supabase Auth as the primary key.
5. **Idempotency guard** — The insert uses `INSERT ... ON CONFLICT (user_id) DO NOTHING` to prevent duplicate rows in the event of a race condition (see Edge Cases, Section 5).
6. **Redis warm** — After successful insert, the new profile is written to Redis under key `profile:{user_id}` with TTL = 300 seconds (5 minutes).
7. **Client response** — The full client-visible profile payload is returned to the client.

### 3.3 Read Path

```
Client requests profile
    │
    ▼
API Server receives GET /profile (authenticated JWT)
    │
    ▼
Extract user_id from verified JWT
    │
    ▼
Check Redis: key = profile:{user_id}
    │
    ├── HIT → deserialize → return client-visible fields to client
    │
    └── MISS ──▶ Query PostgreSQL: SELECT * FROM player_profiles WHERE user_id = $1 AND is_deleted = false
                      │
                      ├── ROW FOUND → write to Redis (TTL = 300s) → return client-visible fields
                      │
                      └── NO ROW FOUND → trigger profile creation flow (3.2) or return 404 (see Edge Cases 5.3)
```

**Cache key format:** `profile:{user_id}` (UUID string, no braces).
**Serialization format:** MessagePack (compact binary; faster than JSON for Redis round-trips).
**Cache TTL:** 300 seconds (5 minutes) for active sessions; no auto-refresh — TTL resets on any write.
**Freshness tolerance:** Client-visible profile data may be up to 300 seconds stale during an active session. Economy fields (`diamond_balance`, `has_play_pass`, `has_no_ads`) are always re-fetched from PostgreSQL after any transaction that touches them — the cached value is invalidated immediately on write (see 3.4). For non-economy fields (stats, XP, level), 300-second staleness is acceptable.

### 3.4 Write Path

All profile mutations originate server-side. The client never directly writes profile fields; it sends requests to system-specific API endpoints, which mutate the profile through the appropriate system.

```
System-specific mutation request arrives at API Server
    │
    ▼
Authenticate: verify JWT; verify caller is authorized for this field (see Field Ownership, 3.5)
    │
    ▼
Begin PostgreSQL transaction
    │
    ▼
Apply mutation(s) to player_profiles (one or more fields)
    │   ── If multiple fields must change atomically (e.g., xp + level), all within the same transaction
    │
    ▼
COMMIT transaction
    │
    ├── SUCCESS ──▶ DELETE Redis key: profile:{user_id}  (invalidate)
    │                   │
    │                   ▼
    │               Trigger async cache warm: re-fetch profile from PostgreSQL → write to Redis (TTL 300s)
    │                   │
    │                   ▼
    │               Return updated fields (or full profile) to caller
    │
    └── FAILURE ──▶ ROLLBACK → return 500 with error code; do not touch Redis
```

**Economy field writes** (diamond_balance, has_play_pass, has_no_ads): After commit, Redis cache for this profile is invalidated AND the client receives a forced profile refresh event via Socket.io (`profile:refresh` event) so the UI reflects the confirmed value immediately.

**Non-economy field writes** (stats, XP, level, preferred_character_id): Cache invalidated on write; client receives updated values on next profile read (within 300-second window). No forced push to client.

**Transactional atomicity requirements:**
- `xp` and `level` must update in the same transaction (level-up is a derived change from XP threshold crossing).
- `wins` (or `losses`) and `total_matches` must update in the same transaction.
- `mmr` and `peak_mmr` must update in the same transaction (peak can only increase, checked atomically).
- `diamond_balance` write must include a ledger entry in the `diamond_transactions` table (owned by Currency system) within the same transaction — this ensures balance and ledger never diverge.

### 3.5 Field Ownership Table

Only the listed authority may mutate each field. Any other system attempting to write a field it does not own must be rejected at the API layer with HTTP 403.

| Field | Owning Authority | Mutation Trigger |
|---|---|---|
| `display_name` | Player (via Settings API) | Explicit rename request |
| `avatar_id` | Player (via Settings API) | Avatar selection; validated against owned inventory |
| `region` | Player (via Settings API) + API Server (first-login auto-detect) | Manual region change or initial detection |
| `last_seen_at` | API Server (auth middleware) | Every successful authenticated request |
| `total_matches` | Match Server | Match result processing |
| `wins` | Match Server | Match result processing (win outcome only) |
| `losses` | Match Server | Match result processing (loss outcome only) |
| `kills` | Match Server | Match result processing |
| `preferred_character_id` | Match Server | After each match; set to most-used character in last 20 matches |
| `mmr` | MMR/Ranked System | Match result processing, post-Elo calculation |
| `peak_mmr` | MMR/Ranked System | Match result processing, when new mmr > peak_mmr |
| `is_provisional` | MMR/Ranked System | Derived from `provisional_match_count`; updated with match count |
| `provisional_match_count` | Match Server | Each completed match until count reaches 30 |
| `diamond_balance` | Currency System | Match reward, quest reward, IAP credit, spend event |
| `has_no_ads` | Purchase Fulfillment | IAP transaction confirmed by RevenueCat webhook |
| `has_play_pass` | Purchase Fulfillment | IAP transaction confirmed / subscription lapse |
| `xp` | XP & Progression System | Match result processing |
| `level` | XP & Progression System | XP threshold crossed (derived from XP, atomic with XP write) |
| `unlocked_character_ids` | Character Unlock System | Unlock condition met (earnable) or initial profile creation (free) |
| `analytics_consent` | Player (via Settings API) | Explicit consent toggle |
| `display_name_last_changed_at` | API Server (Settings API) | Atomically set with `display_name` change |
| `is_deleted`, `deleted_at`, `deletion_scheduled_at` | Account Deletion Service | GDPR erasure request |
| `schema_version` | Database migration scripts only | Schema migration event |

### 3.6 Display Name Rules

- **Minimum length:** 3 characters.
- **Maximum length:** 20 characters.
- **Allowed characters:** Alphanumeric (A–Z, a–z, 0–9), underscores (`_`), hyphens (`-`). No spaces. No other special characters.
- **Uniqueness:** Case-insensitive. `"BrawlKing"` and `"brawlking"` are the same name. Enforced via `LOWER(display_name)` unique index in PostgreSQL.
- **Prohibited patterns:** Names matching the profanity blocklist maintained by the Moderation system are rejected at validation time (HTTP 400, error code `DISPLAY_NAME_PROFANITY`).
- **Change cooldown:** 30 days from `display_name_last_changed_at`. Attempting a change before the cooldown expires returns HTTP 429 with error code `DISPLAY_NAME_COOLDOWN` and a `retry_after` timestamp (seconds until cooldown expires).
- **First-login default name:** The auto-generated `"Player_XXXXXX"` name does not consume the 30-day cooldown — `display_name_last_changed_at` is set to `null` on profile creation, meaning the first player-initiated rename is always permitted regardless of account age.
- **Validation order:** (1) length, (2) character allowlist, (3) profanity check, (4) uniqueness check, (5) cooldown check. Return the first failing check's error code; do not proceed to subsequent checks.

### 3.7 Public vs. Private Profile Payload

**Full profile payload** (returned to the authenticated owner of the profile):
All client-visible fields from the schema table (Section 3.1). Excludes all server-only fields.

**Public profile payload** (returned when one player views another's profile — opponent card, leaderboard row):
`user_id`, `display_name`, `avatar_id`, `level`, `mmr`, `peak_mmr`, `total_matches`, `wins`, `losses`, `kills`, `preferred_character_id`.

The public payload deliberately excludes: `diamond_balance`, `has_no_ads`, `has_play_pass`, `analytics_consent`, `region`, `created_at`, `last_seen_at`, `is_provisional`, `unlocked_character_ids`.

---

## 4. Formulas

### 4.1 Win Rate

```
win_rate = wins / total_matches   (if total_matches > 0)
win_rate = 0.0                    (if total_matches = 0)
```

- Expressed as a decimal in the range [0.0, 1.0].
- Display layer formats as a percentage (e.g., 0.583 → "58.3%").
- `win_rate` is NOT stored as a column — it is a computed value derived from `wins` and `total_matches` at read time (either in the API response serializer or client-side). This prevents any possibility of the stored win_rate drifting out of sync with the underlying win/total_matches counters.

### 4.2 Profile Completeness Score (Onboarding Nudge)

Used by the Main Menu system to surface onboarding nudges. Not stored persistently — computed on the fly when the main menu loads.

```
completeness_score = sum of completed_components / total_components
```

| Component | Weight | Condition for "complete" |
|---|---|---|
| Display name customized | 20 | `display_name` does not match `"Player_[A-Z0-9]{6}"` pattern |
| Avatar customized | 20 | `avatar_id != "default_avatar"` |
| First match played | 25 | `total_matches >= 1` |
| Region confirmed | 15 | `region != "auto"` |
| Analytics consent reviewed | 20 | Player has explicitly set `analytics_consent` (any value) — tracked by a separate `analytics_consent_reviewed` boolean set when the player first visits the consent toggle; not stored on profile, stored in a client-side flag until a dedicated settings-review event is added |

**Total weights sum to 100.** Score is expressed as an integer percentage (0–100).

Thresholds for nudge display:
- Score < 40: show "Complete your profile" banner on Main Menu.
- Score 40–79: show subtle indicator dot on profile icon.
- Score ≥ 80: no nudge shown.

> **Design note / open question:** The `analytics_consent_reviewed` flag has no server-side anchor in the current schema. Options: (a) add a `consent_reviewed_at` timestamptz column to the profile, (b) infer review from `created_at` age (if account > 7 days old, assume reviewed), or (c) treat analytics consent weight as complete if the account is > 24 hours old. **Recommend option (a) — add `consent_reviewed_at` in a follow-up schema revision.** This is flagged for the next design iteration.

### 4.3 Provisional Status Derivation

```
is_provisional = (provisional_match_count < 30)
```

Stored as a boolean column for query performance (used by Matchmaking as a filter). Must be kept in sync with `provisional_match_count` — updated atomically in the same transaction that increments `provisional_match_count`.

---

## 5. Edge Cases

### 5.1 Cache Miss on Profile Load

**Scenario:** A request arrives for a profile that exists in PostgreSQL but has no Redis entry (cold start, TTL expiry, Redis restart, or manual cache flush).

**Behavior:**
1. Redis MISS detected (key not found or key expired).
2. API server falls back to PostgreSQL: `SELECT * FROM player_profiles WHERE user_id = $1 AND is_deleted = false`.
3. If row found: write to Redis (TTL 300s), return client-visible fields. No error surfaced to client.
4. If Redis is unavailable (connection refused, timeout): serve directly from PostgreSQL. Log `WARN: Redis unavailable, serving profile from PostgreSQL`. Do not fail the request. Monitor Redis availability separately.

**Acceptable latency impact:** Cold PostgreSQL read adds ~10–30ms vs. Redis hit. Acceptable for the infrequent cache-miss case.

### 5.2 Concurrent Writes to the Same Field

**Scenario:** Two matches end simultaneously for the same player (possible in theory if the player somehow participates in two sessions — should be prevented by session guards, but must be handled defensively).

**Behavior:**
- All stat increments (`wins`, `losses`, `total_matches`, `kills`) use PostgreSQL atomic increment: `UPDATE player_profiles SET wins = wins + 1, total_matches = total_matches + 1 WHERE user_id = $1`.
- This is a single SQL statement and is serialized by PostgreSQL row-level locking. Both writes will succeed and be applied in sequence; the final values will reflect both increments. No lost update.
- `diamond_balance` similarly uses `diamond_balance = diamond_balance + $delta` (never a read-modify-write from application code) to prevent lost updates.
- `mmr` updates involve a calculation (Elo delta). If two match results attempt to update MMR simultaneously, they must use a PostgreSQL advisory lock on the `user_id` row, or use an optimistic concurrency check (`WHERE mmr = $expected_mmr`) with retry. **Recommended:** use `SELECT ... FOR UPDATE` within the MMR transaction to serialize concurrent MMR writes.
- After any concurrent write, Redis key is invalidated (deleted). The next read re-populates from the now-consistent PostgreSQL state.

### 5.3 Profile Not Found for a Valid JWT

**Scenario:** A valid, unexpired JWT is presented but no corresponding row exists in `player_profiles` (e.g., the profile creation step failed silently during the first-login flow, or the row was hard-deleted by a bug).

**Behavior:**
1. PostgreSQL query returns no row.
2. API server checks Supabase Auth to confirm the `user_id` from the JWT is a valid, non-deleted auth user.
3. If Supabase Auth confirms the user exists: trigger the profile creation flow (Section 3.2) as a recovery path. Log `WARN: Profile missing for valid auth user {user_id}, triggering recovery creation`.
4. If Supabase Auth cannot confirm the user (or returns an error): return HTTP 401 with error code `AUTH_USER_NOT_FOUND`. Do not create a profile.
5. If profile creation recovery fails: return HTTP 503 with error code `PROFILE_CREATION_FAILED`. Client should prompt the player to contact support.

### 5.4 Display Name Already Taken

**Scenario:** A player submits a display name change request and the name is already held by another player (race condition: two players submit the same name within milliseconds of each other).

**Behavior:**
1. Validation passes in-memory (name appears available at check time).
2. `UPDATE player_profiles SET display_name = $1 ...` is issued.
3. PostgreSQL unique index violation (`23505` error code) is caught.
4. Return HTTP 409 with error code `DISPLAY_NAME_TAKEN`. Do not consume the cooldown (the write was not committed, so `display_name_last_changed_at` is unchanged).
5. Client displays: "That name is already taken. Please choose another."

### 5.5 First Login Race Condition (Duplicate Profile Creation)

**Scenario:** A player logs in on two devices simultaneously. Both devices complete auth and both trigger the profile creation flow within milliseconds of each other.

**Behavior:**
1. Both API server instances attempt `INSERT INTO player_profiles ... ON CONFLICT (user_id) DO NOTHING`.
2. PostgreSQL ensures only one insert succeeds. The second `INSERT` is silently ignored (no error raised to the application because of `DO NOTHING`).
3. Both API server instances then query `SELECT * FROM player_profiles WHERE user_id = $1` and return the same profile row to both clients.
4. No duplicate profile exists. No error is surfaced to the player.

**Monitoring:** Log `INFO: Profile creation no-op (conflict) for user_id {user_id}` when the `ON CONFLICT DO NOTHING` path is taken. Track frequency — sustained elevation indicates a client-side retry loop bug.

### 5.6 Account Deletion Request (GDPR Right to Erasure)

**Scenario:** A player requests account deletion from the Settings screen or via a support ticket.

**Phase 1 — Soft Delete (immediate, within 1 hour of request):**
1. `is_deleted = true`, `deleted_at = NOW()`, `deletion_scheduled_at = NOW() + 30 days` written atomically.
2. `display_name` replaced with `"[deleted]"` and `avatar_id` replaced with `"default_avatar"` immediately (removes personally identifying display data from public-facing queries).
3. All active Redis sessions for this `user_id` invalidated (keys deleted).
4. Supabase Auth account disabled (user cannot log in).
5. Player receives confirmation email (sent by Account Deletion Service, not Player Profile system).
6. All queries in the system use `WHERE is_deleted = false` — this player is invisible to matchmaking, leaderboards, and public profile lookups immediately.

**Phase 2 — Hard Delete (30 days after soft delete, automated job):**
1. A scheduled job (cron, daily) scans for rows where `deletion_scheduled_at <= NOW()` and `is_deleted = true`.
2. Deletes the row from `player_profiles`.
3. Deletes associated rows from all dependent tables (match history, inventory, quest state, diamond transaction ledger).
4. Deletes Supabase Auth user record.
5. Logs the deletion event to a compliance audit log (stores only: `user_id`, `deleted_at`, `hard_deleted_at` — no PII).

**Cancellation window:** Player may cancel the deletion request within 30 days by logging in (which triggers a reactivation flow: `is_deleted = false`, `deleted_at = null`, `deletion_scheduled_at = null`, Supabase Auth re-enabled).

### 5.7 Redis Completely Unavailable

**Scenario:** Redis cluster is down for an extended period (not just a transient miss).

**Behavior:**
- All profile reads serve directly from PostgreSQL.
- All profile writes commit to PostgreSQL only (skip the Redis invalidation step, which is a no-op when Redis is unreachable).
- Log `ERROR: Redis unavailable` with timestamp. Alert on-call engineer.
- No player-facing degradation other than increased latency. The system degrades gracefully.
- When Redis recovers, the first write to any profile will populate the cache correctly. Stale cache entries are not a risk because the cache was entirely absent during the outage.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Dependency | What Profile Consumes |
|---|---|---|
| Authentication (Supabase Auth) | Hard dependency — must exist before profile can be created | `user_id` (UUID) from `auth.users`; JWT for request authentication |

### 6.2 Downstream Dependencies (Systems That Read or Write Profile Data)

| System | Direction | Fields Touched | Notes |
|---|---|---|---|
| MMR / Ranked | Reads + Writes | Reads: `mmr`, `is_provisional`, `provisional_match_count`. Writes: `mmr`, `peak_mmr`, `is_provisional` | Elo calculation reads current MMR; writes result delta |
| Currency System | Reads + Writes | Reads: `diamond_balance`. Writes: `diamond_balance` | Reads before spend (balance check); writes reward/spend delta. All writes atomic with ledger |
| Inventory System | Reads | Reads: `user_id` (to scope inventory), `unlocked_character_ids` (to verify entitlement before equip) | Inventory owns cosmetic items; profile owns character unlock list |
| Character Unlock System | Reads + Writes | Reads: `unlocked_character_ids`. Writes: `unlocked_character_ids` (append) | Checks current unlock state before granting; appends new unlock on condition met |
| Matchmaking Engine | Reads | Reads: `mmr`, `is_provisional`, `region`, `has_play_pass` | Pools players by MMR bracket and region; `has_play_pass` may affect queue priority (future feature) |
| Match Server | Writes | Writes: `total_matches`, `wins`, `losses`, `kills`, `preferred_character_id`, `provisional_match_count` | Post-match result processing; all stat increments are additive SQL operations |
| XP & Progression System | Writes | Writes: `xp`, `level` | Computes XP delta from match outcome formula; detects level threshold; writes both fields atomically |
| Quest / Mission System | Reads | Reads: `total_matches`, `wins`, `kills`, `preferred_character_id`, `level` | Reads stats to evaluate quest completion conditions; does not write profile fields |
| Main Menu | Reads | Reads: full client-visible profile payload | Displays display name, avatar, level, diamond balance, MMR on the home screen |
| Moderation / Reporting System | Reads + Writes | Reads: `user_id`, `display_name`. Writes: none directly — escalated bans are handled by Auth (account disable), not profile fields | Report lookups use `user_id` as the stable identifier |
| Purchase Fulfillment | Writes | Writes: `has_no_ads`, `has_play_pass`, `diamond_balance` (for IAP diamond packs) | RevenueCat webhook triggers fulfillment; fulfillment writes entitlements and/or diamonds |
| Leaderboard System | Reads | Reads: `user_id`, `display_name`, `avatar_id`, `mmr`, `peak_mmr`, `level` | Reads for ranked leaderboard rendering; uses public profile payload |
| Account Deletion Service | Writes | Writes: `is_deleted`, `deleted_at`, `deletion_scheduled_at`, `display_name` (anonymized), `avatar_id` (reset) | GDPR erasure flow |

---

## 7. Tuning Knobs

These parameters control system behavior and are configurable without a code deploy (stored in a server-side config table or environment variables).

| Parameter | Current Value | Range / Options | Effect of Change |
|---|---|---|---|
| `PROFILE_CACHE_TTL_SECONDS` | `300` | 60–3600 | Lower = fresher data, higher Redis read pressure. Higher = more staleness risk, lower DB load. Do not exceed 600 during active events. |
| `DISPLAY_NAME_CHANGE_COOLDOWN_DAYS` | `30` | 7–90 | Lower cooldown reduces brand stability (name-squatting risk). Higher cooldown frustrates new players who want to rename. |
| `PROVISIONAL_MATCH_THRESHOLD` | `30` | 10–50 | Lower = faster exit from provisional (less accurate initial placement). Higher = more accurate but longer uncertainty period for new players. |
| `PROFILE_FRESHNESS_TOLERANCE_SECONDS` | `300` | 0–600 | Matches `PROFILE_CACHE_TTL_SECONDS`. For economy fields, this is effectively always 0 (forced refresh on write). |
| `DISPLAY_NAME_MIN_LENGTH` | `3` | 2–5 | Lower allows very short names (more squatting risk). Raise to 4–5 to reduce profanity in short names. |
| `DISPLAY_NAME_MAX_LENGTH` | `20` | 15–32 | UI layouts assume ≤20 chars in opponent name display. Raising requires UI audit. |
| `ACCOUNT_DELETION_GRACE_PERIOD_DAYS` | `30` | 14–30 | Minimum 14 days for GDPR compliance. Longer grace period reduces accidental permanent deletion. |
| `PROFILE_CREATION_NAME_RETRY_LIMIT` | `5` | 3–10 | Max attempts to generate a unique default name before falling back to UUID prefix. |
| `MMR_STARTING_VALUE` | `1000` | 800–1200 | Affects initial matchmaking bracket. Lower starting MMR means new players face easier opponents initially. |
| `FREE_CHARACTER_IDS` | `["character:vex","character:zook","character:sera"]` | Content config | Changing this does not retroactively update existing profiles. Only affects new profile creation. |

---

## 8. Acceptance Criteria

All criteria are verifiable by QA against a test environment with a real PostgreSQL + Redis stack.

### AC-PP-01: Profile Creation on First Login
**Given** a new Supabase Auth user with no existing profile row  
**When** the user completes authentication and the client calls `GET /profile`  
**Then**:
- A new row is inserted into `player_profiles` with all default values.
- `unlocked_character_ids` contains exactly `["character:vex","character:zook","character:sera"]`.
- `display_name` matches pattern `"Player_[A-Z0-9]{6}"`.
- `diamond_balance` is `0`, `mmr` is `1000`, `level` is `1`, `xp` is `0`.
- `is_provisional` is `true`.
- HTTP 200 is returned with the full client-visible profile payload.
- The profile is cached in Redis under `profile:{user_id}`.

### AC-PP-02: Duplicate Profile Creation Race Condition
**Given** two simultaneous first-login requests for the same `user_id`  
**When** both requests race to create the profile  
**Then**:
- Exactly one row exists in `player_profiles` for this `user_id` after both requests complete.
- Both requests return HTTP 200 with the same profile data.
- No error is returned to either client.

### AC-PP-03: Profile Read — Cache Hit
**Given** a player with a cached profile in Redis  
**When** the player calls `GET /profile`  
**Then**:
- The response is served from Redis (no PostgreSQL query issued — verifiable via query log).
- Response time is < 50ms (p95).
- All client-visible fields are present in the response.
- All server-only fields (`display_name_last_changed_at`, `provisional_match_count`, `is_deleted`, etc.) are absent from the response.

### AC-PP-04: Profile Read — Cache Miss
**Given** a player whose Redis key has expired or been deleted  
**When** the player calls `GET /profile`  
**Then**:
- The API server queries PostgreSQL successfully.
- The profile is re-cached in Redis with TTL = 300 seconds.
- HTTP 200 is returned with the correct profile data.

### AC-PP-05: Profile Read — Redis Unavailable
**Given** Redis is unreachable  
**When** the player calls `GET /profile`  
**Then**:
- The API server serves the profile from PostgreSQL directly.
- HTTP 200 is returned with correct profile data (no error surfaced to client).
- A `WARN: Redis unavailable` log entry is emitted.

### AC-PP-06: Display Name Change — Success
**Given** a player whose last display name change was > 30 days ago (or null)  
**When** the player submits a valid new display name (3–20 chars, alphanumeric/underscore/hyphen, not taken, not profane)  
**Then**:
- `display_name` is updated in PostgreSQL.
- `display_name_last_changed_at` is updated to `NOW()` atomically.
- Redis cache for this profile is invalidated.
- HTTP 200 is returned with the updated `display_name`.

### AC-PP-07: Display Name Change — Cooldown Enforcement
**Given** a player who changed their display name 10 days ago  
**When** the player attempts another display name change  
**Then**:
- HTTP 429 is returned with error code `DISPLAY_NAME_COOLDOWN`.
- Response includes `retry_after` (seconds remaining until cooldown expires, approximately 20 days in seconds).
- `display_name` and `display_name_last_changed_at` are unchanged in PostgreSQL.

### AC-PP-08: Display Name Change — Name Already Taken
**Given** a player submitting a display name that is already held by another player  
**When** the rename request is processed  
**Then**:
- HTTP 409 is returned with error code `DISPLAY_NAME_TAKEN`.
- The requesting player's `display_name` and `display_name_last_changed_at` are unchanged.
- The cooldown is not consumed.

### AC-PP-09: Display Name Change — Validation Rules
**Given** a player submitting a display name that fails a validation rule  
**When** the rename request is processed  
**Then** (one test per case):
- Length < 3: HTTP 400, error code `DISPLAY_NAME_TOO_SHORT`.
- Length > 20: HTTP 400, error code `DISPLAY_NAME_TOO_LONG`.
- Disallowed characters (e.g., space, `!`, `@`): HTTP 400, error code `DISPLAY_NAME_INVALID_CHARS`.
- Profanity match: HTTP 400, error code `DISPLAY_NAME_PROFANITY`.

### AC-PP-10: Field Ownership Enforcement
**Given** an API call from a system attempting to write a field it does not own (e.g., a client-side request attempting to directly set `diamond_balance` or `wins`)  
**When** the request is processed  
**Then**:
- HTTP 403 is returned.
- No fields are mutated in PostgreSQL.
- No Redis invalidation occurs.

### AC-PP-11: Economy Field Write — No Optimistic Update
**Given** a diamond balance change (e.g., match reward)  
**When** the Currency system writes the new balance  
**Then**:
- The client does not display the updated balance until the server-confirmed write is complete.
- A `profile:refresh` Socket.io event is emitted to the player's socket after PostgreSQL commit.
- The client updates the displayed diamond balance only upon receiving this event.
- If the PostgreSQL commit fails, the client balance display remains at the pre-transaction value.

### AC-PP-12: Concurrent Stat Increments
**Given** two match results processed simultaneously for the same `user_id` (simulated in test)  
**When** both match servers attempt to increment `wins` and `total_matches`  
**Then**:
- `wins` and `total_matches` each reflect exactly 2 increments after both writes complete.
- No update is lost.
- No unique constraint or lock error is returned to either match server.

### AC-PP-13: Profile Not Found for Valid JWT
**Given** a valid JWT for a `user_id` that has no profile row (simulated by deleting the row in test)  
**When** the player calls `GET /profile`  
**Then**:
- The API server detects the missing row.
- The API server confirms the `user_id` is valid in Supabase Auth.
- The profile creation recovery flow triggers, creating a new default profile.
- HTTP 200 is returned with the new default profile.
- A `WARN: Profile missing for valid auth user` log entry is emitted.

### AC-PP-14: Soft Delete (GDPR Request)
**Given** a player submitting an account deletion request  
**When** the Account Deletion Service processes the request  
**Then**:
- `is_deleted = true`, `deleted_at` is set, `deletion_scheduled_at` is set to 30 days from now.
- `display_name` becomes `"[deleted]"`, `avatar_id` becomes `"default_avatar"`.
- Redis keys for this `user_id` are deleted.
- The player's `user_id` does not appear in matchmaking pool queries (`WHERE is_deleted = false` excludes them).
- The player cannot authenticate (Supabase Auth account disabled).
- HTTP 200 is returned to the deletion request.

### AC-PP-15: Win Rate Computation
**Given** a player with `wins = 37` and `total_matches = 63`  
**When** the profile is read  
**Then**:
- The serialized profile response includes `win_rate = 0.587` (rounded to 3 decimal places, or `58.7%` if formatted).
- No `win_rate` column exists in the database (computed at read time).

### AC-PP-16: Provisional Status Transition
**Given** a player with `provisional_match_count = 29`  
**When** the Match Server processes one additional match result  
**Then**:
- `provisional_match_count` becomes `30`.
- `is_provisional` becomes `false`.
- Both field updates occur in the same PostgreSQL transaction (verifiable: if one fails, neither commits).
- The client-visible `is_provisional` field reflects `false` on the next profile read.

### AC-PP-17: Profile Public Payload Exclusions
**Given** Player A requesting the public profile of Player B  
**When** `GET /profile/{player_b_user_id}/public` is called  
**Then**:
- Response includes: `user_id`, `display_name`, `avatar_id`, `level`, `mmr`, `peak_mmr`, `total_matches`, `wins`, `losses`, `kills`, `preferred_character_id`.
- Response excludes: `diamond_balance`, `has_no_ads`, `has_play_pass`, `analytics_consent`, `region`, `created_at`, `last_seen_at`, `is_provisional`, `unlocked_character_ids`.

---

## Design Questions and Risks

### Open Questions

1. **Profile completeness score — `analytics_consent_reviewed` anchor:** The completeness formula (Section 4.2) references a consent-reviewed state that has no server-side column. A `consent_reviewed_at timestamptz` column should be added to the schema in the next revision. Flagged for the XP & Progression / Main Menu design pass.

2. **`preferred_character_id` computation window:** The current spec says "most-used character in last 20 matches." This requires the Match Server to have access to recent match history per player to compute this. If match history is owned by a separate system, the Match Server may need a cross-system query. Consider simplifying to "character used in most recent match" (no history query needed) with a separate dedicated "main character" field computed by the XP system over a longer window.

3. **MMR concurrent write strategy:** The spec recommends `SELECT ... FOR UPDATE` for concurrent MMR writes. This creates a serialization bottleneck for players in many simultaneous matches (rare, but possible in FFA modes). Confirm whether the MMR/Ranked system design chooses `FOR UPDATE` vs. optimistic concurrency (retry on mismatch).

4. **`region` auto-detection:** The profile stores `region = "auto"` until the player explicitly confirms it. The Matchmaking Engine must handle `"auto"` as a fallback (match with any region) until the region is resolved. This handoff rule should be confirmed in the Matchmaking Engine GDD.

5. **Free character IDs as config:** The `FREE_CHARACTER_IDS` tuning knob in Section 7 affects only new profile creation. A mechanism is needed for retroactively granting a character if the free roster changes (e.g., a promotional free character grant). This is out of scope for this system but should be flagged for the Character Unlock System GDD.

### Risks

- **Redis dependency for performance:** The system degrades gracefully without Redis (Section 5.7), but PostgreSQL under full direct-read load (no cache) may become a bottleneck at scale. A connection pool (PgBouncer) should be confirmed as part of the deployment architecture.
- **Schema migration and cache invalidation:** The `schema_version` field on the profile is intended for cache invalidation on schema migration, but the mechanism (how the API server detects a stale cached profile with an old schema version) is not fully specified. This should be resolved before the first schema migration after launch.
- **GDPR hard-delete cascade:** The hard-delete job (Section 5.6, Phase 2) must delete rows from all dependent tables. The list of dependent tables must be maintained as new systems are added. A foreign key with `ON DELETE CASCADE` from all dependent tables to `player_profiles.user_id` is the recommended enforcement mechanism — this should be confirmed with the database schema owner.
