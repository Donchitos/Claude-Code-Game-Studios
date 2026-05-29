# Moderation / Reporting — Game Design Document

> **System**: Moderation / Reporting
> **Priority**: Alpha
> **Layer**: Feature
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

The Moderation / Reporting system gives BRAWLZONE players a structured, safe mechanism for flagging disruptive match behavior — AFK/abandonment, intentional feeding, cheating/exploits, and unsportsmanlike conduct — while protecting the health of the competitive environment through human-reviewed ban decisions backed by automated behavioral signals. It owns the full pipeline from post-match report submission through evidence collection, moderation queue management, sanction enforcement at login, and email-based appeal resolution. Because BRAWLZONE has no in-game text chat at MVP, the system is scoped exclusively to match behavior; there is no display name or message-content reporting. Automated signals (AFK rate, disconnect rate, suspicious damage output) feed into a prioritized human review queue but do not trigger automatic bans, with the single exception of a temporary suspension on FATAL cheat detection from the Anti-Cheat stub. Sanctions are enforced server-side at login via the `isBanned` and `banExpiresAt` fields on the Player Profile — no moderation state is ever trusted from the client.

---

## 2. Player Fantasy

### The Honest Competitor

BRAWLZONE's fairness promise is simple: when you queue for a match, every opponent you face is there to play. The game is already skill-balanced through MMR — the moderation system enforces the behavioral contract that sits underneath MMR: players who waste other people's time by going AFK, feeding deliberately, or cheating are identified and removed from the pool.

The player fantasy for the reporting system is:

> "I just got matched with someone who stood still for the entire game. I hit Report at the end, picked AFK / Abandonment, and moved on. Two days later I saw a notification that my report was reviewed. I don't know what happened to that player — that's fine, it's private — but I know the game is paying attention. The bad actors don't stick around forever."

Players should feel that reports are **meaningful, not performative**. The system must communicate that human reviewers look at evidence and make real decisions — not that reports disappear into a void. At the same time, players must never feel that they have power over each other: no individual report triggers a ban, mass reporting is explicitly handled, and false-report abuse is discouraged through daily rate limits that apply without notification.

### The Wrongly-Accused Player

A player who receives a warning or ban must feel the process was fair and that a path to appeal exists. The ban notification includes a plain-language description of the reason, the duration, and a link to initiate an email appeal. An appeal-granted account restoration should feel like vindication — clean, immediate, and clearly communicated.

### The Moderator

Human moderators reviewing the queue need accurate, pre-assembled evidence that does not require them to reconstruct context. The `evidence_snapshot` attached to every report — kills, deaths, damage dealt, time connected, input rate — gives them a factual basis for a decision without requiring access to a full match replay at MVP.

---

## 3. Detailed Rules

### 3.1 Report Flow

Reports are filed through a post-match report screen that appears as a non-blocking overlay on the match results screen.

#### 3.1.1 Post-Match Report Screen Timing

- The report screen prompt is shown as part of the **Match Results** screen, rendered as an optional section below the core results UI.
- The prompt is available for **60 seconds** from the moment the results payload is delivered to the client.
- After 60 seconds, the report prompt collapses and disappears. The player does not need to act; dismissal is the default.
- Players can dismiss the prompt early at any time by tapping "Skip" or "Done".
- The prompt is shown regardless of match outcome (win or loss).
- The prompt is **not** shown for abandoned matches (no `match_results_payload` with performance data exists for abandoned sessions; see Match Flow GDD §3.5).

#### 3.1.2 Who Can Be Reported

- A player may report any **other** participant in the same completed match.
- A player may not report themselves.
- In 1v1 Duel: the reporting player sees one potential target (their opponent).
- In 3v3 Squad Brawl: the reporting player sees up to five potential targets (all players minus themselves; teammates and opponents alike are reportable).
- In 8-player FFA: the reporting player sees up to seven potential targets.

#### 3.1.3 Report Categories

Players select exactly one category per report:

| Category ID | Display Label | Intended Behavior |
|---|---|---|
| `afk_abandonment` | AFK / Abandonment | Player was idle or left the match early without reconnecting |
| `intentional_feeding` | Intentional Feeding / Sabotage | Player deliberately threw the match — feeding kills or sabotaging team objective |
| `cheating_exploit` | Cheating / Exploit | Player used unauthorized software, memory manipulation, or exploited a game bug for unfair advantage |
| `unsportsmanlike` | Unsportsmanlike Conduct | Disruptive match behavior not covered by other categories (spawn-camping, stalling, deliberate poor play that does not meet feeding threshold) |

Category selection is required before submission. A player cannot submit a blank report.

#### 3.1.4 One Report Per Reporter Per Match Per Target

- Each `(reporter_id, match_id, reported_id)` triple is unique. The database enforces this with a composite unique constraint.
- If a player attempts to file a second report against the same target in the same match, the submission is silently dropped client-side after the first is confirmed (the button grays out).
- A player **can** report multiple different players from the same match as separate reports, subject to the daily rate limit (see Section 3.5).

---

### 3.2 Report Storage

All reports are stored in a dedicated `reports` table in PostgreSQL (Supabase).

#### 3.2.1 Table Schema

```typescript
interface Report {
  report_id: string;           // UUID v4; primary key; server-generated
  reporter_id: string;         // UUID; FK → player_profiles.user_id
  reported_id: string;         // UUID; FK → player_profiles.user_id
  match_id: string;            // UUID; FK → matches.match_id
  category: ReportCategory;    // 'afk_abandonment' | 'intentional_feeding' | 'cheating_exploit' | 'unsportsmanlike'
  timestamp: string;           // ISO 8601; server time of receipt
  status: ReportStatus;        // 'pending' | 'under_review' | 'actioned' | 'dismissed'
  evidence_snapshot: EvidenceSnapshot;  // JSON blob; server-assembled at submission time
  moderator_id: string | null; // UUID of admin who reviewed; null until reviewed
  moderator_notes: string | null; // Internal notes; never exposed to players
  reviewed_at: string | null;  // ISO 8601; null until reviewed
  action_taken: SanctionType | null; // null until actioned
}

type ReportCategory =
  | 'afk_abandonment'
  | 'intentional_feeding'
  | 'cheating_exploit'
  | 'unsportsmanlike';

type ReportStatus =
  | 'pending'          // Awaiting moderator assignment
  | 'under_review'     // Assigned to a moderator
  | 'actioned'         // Sanction applied
  | 'dismissed';       // Report reviewed; no action taken

type SanctionType =
  | 'warn'
  | 'temp_ban_24h'
  | 'temp_ban_72h'
  | 'temp_ban_7d'
  | 'permanent_ban';
```

#### 3.2.2 Database Constraints

```sql
-- Enforce one report per (reporter, match, target)
UNIQUE (reporter_id, match_id, reported_id)

-- Indexes for moderation queue queries
CREATE INDEX idx_reports_status ON reports (status);
CREATE INDEX idx_reports_reported_id ON reports (reported_id);
CREATE INDEX idx_reports_match_id ON reports (match_id);
CREATE INDEX idx_reports_timestamp ON reports (timestamp DESC);
```

---

### 3.3 Evidence Snapshot

The evidence snapshot is **server-assembled** at report submission time. Players do not submit any evidence. The server reads the match result data for the reported player and attaches it automatically.

#### 3.3.1 Snapshot Schema

```typescript
interface EvidenceSnapshot {
  // Reported player's stats for this match
  kills: number;                  // Eliminations credited to reported player
  deaths: number;                 // Times the reported player was eliminated
  damage_dealt: number;           // Total damage dealt by reported player (all targets)
  time_connected_ms: number;      // Total time the reported player was connected during the match
  input_rate_avg: number;         // Average inputs per 30-second window (from Session Manager)

  // Match context
  match_duration_ms: number;      // Total match duration
  game_mode: 'duel_1v1' | 'squad_3v3' | 'ffa_8';
  reported_player_mmr: number;    // Reported player's MMR at match start (from mmrSnapshot)

  // Automated signal flags (pre-computed at snapshot time)
  afk_signal_triggered: boolean;  // true if input_rate_avg < AFK_INPUT_THRESHOLD
  disconnect_rate_signal: number; // voluntaryDisconnects / totalMatches over last DISCONNECT_SAMPLE_SIZE matches
  suspicious_damage_signal: boolean; // true if consecutive low-damage condition met (see §4.3)

  // Data source timestamps
  snapshot_generated_at: string;  // ISO 8601; when this snapshot was assembled
}
```

#### 3.3.2 Snapshot Assembly Timing

The server assembles the `evidence_snapshot` synchronously when the `POST /reports` endpoint receives a valid submission. All data is sourced from the match results record already written to PostgreSQL by Match Flow (see Match Flow GDD §3.4). No additional network calls are required; the snapshot is a read-only projection of existing match state.

If the match record is not found (e.g., report submitted after match record TTL; unlikely at MVP given the 60-second window), the report is rejected with HTTP 422 and a `REPORT_MATCH_NOT_FOUND` error. The client displays "Unable to submit report — match data unavailable."

---

### 3.4 Automated Signals

Automated signals are computed at report submission time and stored in the `evidence_snapshot`. They **feed into the moderation queue priority** but do **not** trigger automatic bans. A player whose report has multiple signals triggered is surfaced higher in the moderator queue.

Signals are also computed periodically (every 24 hours) by a background job that scans active player records — this allows the moderation team to proactively identify players who have not yet been reported but are exhibiting systemic behavioral patterns.

#### 3.4.1 AFK Signal

**Definition:** The reported player averaged fewer than `AFK_INPUT_THRESHOLD` inputs per `AFK_WINDOW_MS` during the active match phase.

- Input data is sourced from the Session Manager's per-player input event log.
- Only inputs during the `active` session phase are counted; inputs during character select, countdown, or reconnect grace period are excluded.
- A player on a legitimate network drop (INACTIVE state) has zero inputs during that window. The AFK signal must account for INACTIVE periods: `time_connected_ms` excludes time spent in INACTIVE state. The input rate is computed over connected time only.

**Threshold:** `input_rate_avg < AFK_INPUT_THRESHOLD` (default: 5 inputs per 30s)

**Signal label in snapshot:** `afk_signal_triggered: true`

#### 3.4.2 Early Disconnect Rate Signal

**Definition:** The reported player's voluntary disconnect rate over their last `DISCONNECT_SAMPLE_SIZE` matches exceeds `DISCONNECT_RATE_THRESHOLD`.

- Voluntary disconnects are identified by the Disconnect Handler: socket-closed-cleanly events where the player did not reconnect within the grace period. Network-drop disconnects (inferred from exhausted reconnect attempts) are counted separately and are NOT included in the voluntary disconnect numerator — this prevents penalizing players for legitimate network issues.
- "Last N matches" is the `DISCONNECT_SAMPLE_SIZE` most recent completed matches for this player (sorted by `timestamp DESC` from the match history).

**Threshold:** `disconnectRate > DISCONNECT_RATE_THRESHOLD` (default: 0.30 over last 10 matches)

**Signal label in snapshot:** `disconnect_rate_signal` (numeric value stored; threshold comparison happens in the moderation queue display layer)

#### 3.4.3 Suspicious Performance Signal

**Definition:** The reported player's damage output over their last `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` consecutive matches is below `SUSPICIOUS_DAMAGE_THRESHOLD` percent of expected output for their MMR bracket.

- Expected damage output per MMR bracket is a configurable lookup table (see Tuning Knobs §7).
- "Consecutive" means the last N matches with no breaks — if a player had one normal match in the middle, the streak resets.
- A single match with low damage is not flagged. The condition requires the full `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` consecutive matches to be below threshold.

**Threshold:** `damage_dealt < (expected_damage_for_mmr × SUSPICIOUS_DAMAGE_THRESHOLD)` for `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` consecutive matches (defaults: 5% threshold, 5 consecutive matches)

**Signal label in snapshot:** `suspicious_damage_signal: true`

---

### 3.5 Reporting Rate Limits

To prevent report bombing — a coordinated attempt to flood the queue with bad-faith reports against a single player — the following limits apply:

- **Per-reporter daily cap:** A player may file at most `MAX_REPORTS_PER_DAY` reports per calendar day (UTC). Default: 3.
- **Enforcement:** The server checks the count of reports filed by `reporter_id` since the start of the current UTC calendar day before accepting any new report. If the count is at or above the cap, the submission is rejected with HTTP 429.
- **Client behavior on 429:** The client silently suppresses the report prompt for the rest of the session after a 429 response. The player sees the report prompt disappear as normal (no error message shown — the player is not informed they hit the cap).
- **Cap resets:** The cap resets at 00:00 UTC daily. There is no carry-over of unused reports across days.
- **Cap does not apply to admins:** Users with the admin role (per Authentication GDD) bypass the daily cap for investigation purposes.

---

### 3.6 Moderation Queue

The moderation queue is the server-side prioritized list of `pending` and `under_review` reports that human moderators process.

#### 3.6.1 Queue Priority Scoring

Reports are surfaced to moderators in order of **queue priority score** (higher = reviewed sooner):

```
queuePriority = baseSignalScore
              + reportCountBonus
              + categoryBonus
              + reporterCredibilityBonus
```

| Component | Value | Notes |
|---|---|---|
| `baseSignalScore` | 0–3 | +1 for each automated signal that triggered (`afk_signal_triggered`, `disconnect_rate_signal > threshold`, `suspicious_damage_signal`) |
| `reportCountBonus` | min(reportCount, 5) | Count of unique reporters for same `(reported_id, match_id)`; capped at 5 to prevent mass-report inflation |
| `categoryBonus` | `cheating_exploit` = 2; `intentional_feeding` = 1; others = 0 | Cheating reports are highest severity |
| `reporterCredibilityBonus` | 0.0–1.0 (float) | Weighted sum of credibility scores of all reporters for this target+match; see §4.4 |

Queue is sorted by `queuePriority DESC`, then `timestamp ASC` (older reports of equal priority are reviewed first).

#### 3.6.2 Moderator Actions

When a moderator reviews a report or a cluster of reports for the same `(reported_id, match_id)`:

| Action | Sets `status` | Sets `action_taken` | Effect on Player Profile |
|---|---|---|---|
| Dismiss | `dismissed` | `null` | No change |
| Warn | `actioned` | `'warn'` | No ban fields changed; warning logged in `moderator_notes` |
| Temp Ban 24h | `actioned` | `'temp_ban_24h'` | `isBanned = true`, `banExpiresAt = now + 24h` |
| Temp Ban 72h | `actioned` | `'temp_ban_72h'` | `isBanned = true`, `banExpiresAt = now + 72h` |
| Temp Ban 7d | `actioned` | `'temp_ban_7d'` | `isBanned = true`, `banExpiresAt = now + 7 days` |
| Permanent Ban | `actioned` | `'permanent_ban'` | `isBanned = true`, `banExpiresAt = null` |

All moderator actions write to `reports.moderator_id`, `reports.moderator_notes`, `reports.reviewed_at`, and `reports.action_taken` in a single atomic transaction. The Player Profile update (setting `isBanned` / `banExpiresAt`) is included in the same transaction to ensure consistency.

---

### 3.7 Sanctions and Escalation

BRAWLZONE uses a **progressive sanction ladder** based on prior offense history.

#### 3.7.1 Sanction Ladder

| Offense Count | Default Sanction | Notes |
|---|---|---|
| 1st substantiated offense | Warn | No gameplay restriction; internal record only |
| 2nd substantiated offense | Temp ban 24h | Access blocked for 24 hours |
| 3rd substantiated offense | Temp ban 72h | Access blocked for 72 hours |
| 4th substantiated offense | Temp ban 7d | Access blocked for 7 days |
| 5th+ substantiated offense | Permanent ban | Account disabled indefinitely; appeal required to restore |

A "substantiated offense" is a report cluster reviewed by a moderator resulting in any sanction (warn through permanent ban). Dismissed reports do not increment the offense counter.

Moderators may **skip ladder steps** upward (e.g., apply a permanent ban on a first offense for egregious cheating) or **reset the ladder** if a successful appeal is granted. Skipping downward (applying a warn when a permanent ban is warranted) is discouraged and requires a moderator note explaining the rationale.

Offense history is stored in a `moderation_history` table referenced by `reported_id`. The ladder position is computed at review time by counting `actioned` records for the player.

```typescript
interface ModerationHistory {
  history_id: string;         // UUID v4; primary key
  player_id: string;          // UUID; FK → player_profiles.user_id
  report_id: string;          // UUID; FK → reports.report_id
  sanction_applied: SanctionType;
  applied_at: string;         // ISO 8601
  moderator_id: string;       // UUID; FK → admin user
  appeal_status: AppealStatus | null;  // null if no appeal filed
}

type AppealStatus = 'pending' | 'granted' | 'denied';
```

#### 3.7.2 Ban Enforcement at Login

On every login (after JWT validation by Authentication), the server reads `isBanned` and `banExpiresAt` from the Player Profile (PostgreSQL source of truth; Redis cache is checked first and falls through to PostgreSQL on cache miss).

```typescript
// Pseudo-code: executed server-side at login, after JWT validation
async function checkBanStatus(userId: string): Promise<void> {
  const profile = await playerProfileService.get(userId);  // Redis → PG

  if (profile.isBanned) {
    if (profile.banExpiresAt === null) {
      throw new BanError('PERMANENT_BAN');
    }
    const now = Date.now();
    const expiresAt = new Date(profile.banExpiresAt).getTime();
    if (now < expiresAt) {
      throw new BanError('TEMP_BAN', { expiresAt: profile.banExpiresAt });
    } else {
      // Ban expired — lift it
      await playerProfileService.update(userId, {
        isBanned: false,
        banExpiresAt: null
      });
      // Proceed with login normally
    }
  }
}
```

On a `BanError`, the server returns HTTP 403 with a structured body:

```typescript
interface BanResponse {
  error: 'ACCOUNT_BANNED';
  banType: 'permanent' | 'temporary';
  expiresAt: string | null;       // ISO 8601 for temporary; null for permanent
  appealUrl: string | null;       // Link to appeal form; provided for permanent bans and 7d bans
  message: string;                // Human-readable ban reason (generic; not specific to the report)
}
```

The client displays a modal with the ban reason and duration. The appeal link is shown for permanent bans and 7-day bans.

---

### 3.8 Appeal Process

At MVP, appeals are handled via **email**. In-app appeal flows are deferred post-MVP.

#### 3.8.1 Appeal Submission

- A player who is permanently banned or has received a 7-day ban sees an appeal link in the ban notification modal.
- The appeal link is a parameterized URL: `https://support.brawlzone.gg/appeal?userId=<uuid>&banType=<type>`. The `userId` is the player's UUID (not email; no PII in the URL).
- The support page prompts the player to describe their case and submit their email address for contact.
- Players banned for 24h or 72h do not receive an appeal link by default (the duration is short enough that appeal overhead is disproportionate). A moderator may manually provide an appeal link on a case-by-case basis.

#### 3.8.2 Appeal Review

- Appeals are reviewed by a senior moderator (admin role) distinct from the moderator who issued the original sanction, wherever possible.
- If the appeal is **granted**: the senior moderator sets `moderation_history.appeal_status = 'granted'`, updates `player_profiles.isBanned = false` and `banExpiresAt = null`, and logs the reversal. The Redis cache entry for the player profile is invalidated immediately. The player receives a confirmation email.
- If the appeal is **denied**: `moderation_history.appeal_status = 'denied'`. The player receives a denial email. The ban remains in effect.
- Appeal SLA target: 5 business days. No SLA is enforced programmatically at MVP; it is an operational commitment.

---

### 3.9 Reporter Feedback

Privacy is preserved throughout: **no specific outcome is ever disclosed to the reporter**.

After a report is reviewed (status transitions from `pending`/`under_review` to `actioned` or `dismissed`), the reporter receives a generic in-app notification:

> "We've reviewed your recent report. Thank you for helping keep BRAWLZONE fair."

No information about what action (if any) was taken is included. This policy is consistent with standard industry practice and protects both the reported player's privacy and the integrity of the moderation process.

Notification delivery is best-effort via push notification (Expo Notifications). If push is not available, the notification is stored server-side and displayed on the player's next app open.

---

### 3.10 Anti-Cheat Stub Integration

At MVP, the Anti-Cheat system is a stub that can emit `FATAL` cheat detection events via an internal event bus. The Moderation system subscribes to this channel.

On a `FATAL` cheat detection event:

```typescript
interface AntiCheatFatalEvent {
  playerId: string;          // UUID
  matchId: string;           // UUID
  detectionType: string;     // e.g., 'memory_manipulation', 'speed_hack'
  confidence: number;        // 0.0–1.0 (stub always emits 1.0 at MVP)
  timestamp: string;         // ISO 8601
}
```

The Moderation system responds to a `FATAL` event with **automatic temporary suspension**:

1. `isBanned = true`, `banExpiresAt = now + ANTI_CHEAT_AUTO_SUSPEND_DURATION_MS` is written to the Player Profile.
2. A `reports` record is created with `reporter_id = SYSTEM_USER_ID` (a reserved UUID for system-generated reports), `category = 'cheating_exploit'`, and status `under_review`.
3. A moderator is alerted (via the moderation queue priority system, which surfaces `cheating_exploit` + `FATAL` flag reports at the top).
4. The suspended player can continue the current match (ban is not applied mid-match; see Edge Case 5.4) but cannot log in again until the ban expires or is lifted by a moderator.

The automatic suspension is a **temporary hold**, not a permanent ban. A moderator reviews and confirms or reverses it. This is the only automated sanction at MVP.

---

## 4. Formulas

### 4.1 AFK Detection Threshold

```
afkSignalTriggered = (input_rate_avg < AFK_INPUT_THRESHOLD)

where:
  input_rate_avg   = total_inputs_during_active_connected_time
                     ÷ (time_connected_ms / AFK_WINDOW_MS)

  total_inputs_during_active_connected_time
                   = count of input events for this player during the match
                     while their session state was ACTIVE (excluding INACTIVE windows)

  AFK_INPUT_THRESHOLD  = 5     (inputs per AFK_WINDOW_MS)
  AFK_WINDOW_MS        = 30000 (30 seconds)
```

**Variable definitions:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `total_inputs_during_active_connected_time` | `integer` | — | Count of all player input events (movement, ability activation, targeting) while session state = ACTIVE |
| `time_connected_ms` | `integer` | — | Milliseconds the player was in ACTIVE state during the match; excludes INACTIVE (disconnect grace) windows |
| `AFK_INPUT_THRESHOLD` | `integer` | 5 | Minimum inputs per window to be considered engaged |
| `AFK_WINDOW_MS` | `integer` | 30 000 | Window size in milliseconds for input rate normalization |

**Example calculation:**

- Match duration: 3 minutes (180 000ms)
- Player time in ACTIVE state: 150 000ms (30s spent INACTIVE after a brief disconnect)
- Total inputs during ACTIVE windows: 8 (player barely moved)
- Number of windows: 150 000 / 30 000 = 5 windows
- `input_rate_avg` = 8 / 5 = **1.6 inputs per 30s**
- `AFK_INPUT_THRESHOLD` = 5
- 1.6 < 5 → `afk_signal_triggered = true`

**Network-drop disambiguation:** Because the formula excludes INACTIVE time from the denominator, a player who was legitimately disconnected for 20 seconds and then reconnected is not penalized for the time they were in INACTIVE state. Only the time they were connected and not providing inputs counts against them.

---

### 4.2 Disconnect Rate Signal

```
disconnectRate = voluntaryDisconnects / totalMatchesSampled

where:
  voluntaryDisconnects  = count of matches in the last DISCONNECT_SAMPLE_SIZE matches
                          where disconnect_type = 'voluntary' (socket closed cleanly, no reconnect)
  totalMatchesSampled   = min(total completed matches for player, DISCONNECT_SAMPLE_SIZE)

  DISCONNECT_SAMPLE_SIZE      = 10   (matches)
  DISCONNECT_RATE_THRESHOLD   = 0.30 (30%)
```

**Variable definitions:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `voluntaryDisconnects` | `integer` | — | Count of matches in sample where the player voluntarily left (clean socket close, no reconnect within grace period) |
| `totalMatchesSampled` | `integer` | — | Actual sample size; capped at `DISCONNECT_SAMPLE_SIZE`; uses actual match count for players with fewer than 10 completed matches |
| `DISCONNECT_SAMPLE_SIZE` | `integer` | 10 | Number of recent matches to examine |
| `DISCONNECT_RATE_THRESHOLD` | `float` | 0.30 | Rate above which the signal fires |

**Example calculation:**

- Player has 10 completed matches in history
- In the last 10 matches: 4 were voluntary disconnects (left early without reconnecting), 6 were natural completions
- `disconnectRate` = 4 / 10 = **0.40**
- `DISCONNECT_RATE_THRESHOLD` = 0.30
- 0.40 > 0.30 → disconnect rate signal fires (value stored in snapshot: `disconnect_rate_signal: 0.40`)

**New player handling:** A player with fewer than 3 completed matches is exempt from this signal. `totalMatchesSampled < 3` → signal is not computed; `disconnect_rate_signal` is stored as `null` in the snapshot.

---

### 4.3 Suspicious Performance Signal

```
suspiciousDamageSignal = (consecutiveLowDamageMatches >= SUSPICIOUS_DAMAGE_SAMPLE_SIZE)

where consecutiveLowDamageMatches is the longest unbroken streak ending at the
  most recent match where:

  damage_dealt_match < (expectedDamageForMMR(playerMmr) × SUSPICIOUS_DAMAGE_THRESHOLD)

  SUSPICIOUS_DAMAGE_SAMPLE_SIZE = 5  (consecutive matches)
  SUSPICIOUS_DAMAGE_THRESHOLD   = 0.05  (5% of expected)
```

**Variable definitions:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `damage_dealt_match` | `integer` | — | Total damage dealt by the player in a single match |
| `expectedDamageForMMR(mmr)` | `integer` | lookup table | Expected total damage for a player at the given MMR bracket; see Tuning Knobs §7 |
| `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` | `integer` | 5 | Number of consecutive below-threshold matches required to trigger the signal |
| `SUSPICIOUS_DAMAGE_THRESHOLD` | `float` | 0.05 | Fraction of expected damage below which a match is flagged |

**Example calculation:**

- Player MMR: 1200 → `expectedDamageForMMR(1200)` = 4 000 (example lookup value)
- `SUSPICIOUS_DAMAGE_THRESHOLD` = 0.05
- Threshold damage per match: 4 000 × 0.05 = **200 damage**
- Player's last 6 matches (most recent first): 85, 120, 95, 60, 150, 3 800
- Consecutive low-damage streak ending at most recent match: 5 (matches 1–5 are all below 200; match 6 = 3 800 is above threshold, breaking the streak)
- `consecutiveLowDamageMatches` = 5 ≥ `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` (5) → `suspicious_damage_signal = true`

---

### 4.4 Reporter Credibility Score

```
reporterCredibility(reporterId) = BASE_CREDIBILITY
                                  × (1 - CREDIBILITY_DECAY_PER_DISMISSED_REPORT
                                       × dismissedReportCount(reporterId))
                                  × (1 - CREDIBILITY_DECAY_PER_BAN
                                       × priorBanCount(reporterId))

Clamped to [MIN_CREDIBILITY, BASE_CREDIBILITY] = [0.10, 1.0]

where:
  BASE_CREDIBILITY                    = 1.0
  CREDIBILITY_DECAY_PER_DISMISSED_REPORT = 0.05
  CREDIBILITY_DECAY_PER_BAN          = 0.20
  dismissedReportCount(reporterId)   = count of reports filed by this player where
                                       status = 'dismissed'
  priorBanCount(reporterId)          = count of actioned moderation_history records
                                       for this player (i.e., they themselves have
                                       been sanctioned)
```

**Variable definitions:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `BASE_CREDIBILITY` | `float` | 1.0 | Starting credibility for all players |
| `CREDIBILITY_DECAY_PER_DISMISSED_REPORT` | `float` | 0.05 | Credibility reduction per previously dismissed report this player filed |
| `CREDIBILITY_DECAY_PER_BAN` | `float` | 0.20 | Credibility reduction per sanction on the reporter's own record |
| `MIN_CREDIBILITY` | `float` | 0.10 | Floor; a player with a poor history still has non-zero credibility |

**Example calculation:**

- Reporter has filed 4 previous reports that were dismissed; has received 1 prior ban.
- `credibility` = 1.0 × (1 - 0.05 × 4) × (1 - 0.20 × 1)
- = 1.0 × (1 - 0.20) × (1 - 0.20)
- = 1.0 × 0.80 × 0.80
- = **0.64**

**Queue priority application:**

```
reporterCredibilityBonus = sum(reporterCredibility(r) for r in uniqueReporters)
                           ÷ len(uniqueReporters)

(Average credibility across all reporters for this target+match combination)
Clamped to [0.0, 1.0]
```

---

### 4.5 Queue Priority Score — Full Example

Given a report cluster for a single `(reported_id, match_id)`:
- 3 unique reporters
- `afk_signal_triggered = true`, `disconnect_rate_signal = 0.40 > 0.30`, `suspicious_damage_signal = false`
- `category = 'afk_abandonment'` → `categoryBonus = 0`
- Reporter credibility scores: 1.0, 0.80, 0.64 → average = `(1.0 + 0.80 + 0.64) / 3 = 0.81`

```
baseSignalScore           = 2   (afk + disconnect signals)
reportCountBonus          = min(3, 5) = 3
categoryBonus             = 0
reporterCredibilityBonus  = 0.81

queuePriority = 2 + 3 + 0 + 0.81 = 5.81
```

---

## 5. Edge Cases

### 5.1 Reported Player Already Banned When Report Is Processed

**Scenario:** A report is filed against player X during match M. Before a moderator reviews the report, a separate report cluster results in player X being banned.

**Resolution:**
1. The report remains in the queue with `status = 'pending'` (or `'under_review'` if already assigned).
2. When the moderator opens the report, the player profile panel shows player X's current ban status.
3. The moderator reviews the evidence as normal. If the new evidence warrants additional sanction (e.g., the existing ban is a 24h temp ban but this offense warrants 7d), the moderator may escalate the sanction by updating the Player Profile directly. The ladder position is recalculated from `moderation_history` to determine the appropriate next step.
4. If the existing ban already covers or exceeds the warranted sanction, the moderator marks the report `actioned` with `moderator_notes` explaining the existing ban supersedes.
5. The report is never auto-dismissed solely because the player is already banned — each report is reviewed on its own merits.

---

### 5.2 Reporter Banned Before Report Is Reviewed

**Scenario:** Player A files a report against player B, then player A is subsequently banned (for unrelated conduct).

**Resolution:**
1. The report remains valid and is processed normally. A report is evidence of an event that occurred during a specific match — the reporter's subsequent conduct does not retroactively invalidate what they observed.
2. The reporter credibility score (§4.4) is re-evaluated at queue processing time using the reporter's current `priorBanCount` (which now includes the new ban). This reduces the `reporterCredibilityBonus` for that specific reporter's contribution to the queue priority, but does not remove the report from the queue.
3. No automated dismissal occurs. The moderator makes the final decision.

---

### 5.3 Mass Report — All Other Players in the Match Report the Same Target

**Scenario:** In an 8-player FFA, all 7 other players report player X from the same match. A coordinated false-reporting campaign is possible (e.g., a streamer's viewers all queue and spam reports against a streamer).

**Resolution:**
1. The `reportCountBonus` in the queue priority formula is capped at `min(reportCount, 5)`. Seven reports have the same queue priority weight as five — mass reporting provides no additional boost beyond the cap.
2. All 7 reports are stored in the database. The moderator sees the count (7 unique reporters) but is trained to evaluate the `evidence_snapshot` on its merits, not the report count.
3. The `reporterCredibilityBonus` is an average, not a sum — 7 low-credibility reporters averaging 0.30 credibility each do not score higher than 2 high-credibility reporters averaging 0.90 each (0.30 vs. 0.90).
4. No automatic ban is triggered. A human moderator must review.
5. If the mass report is identified as coordinated false-reporting (e.g., all 7 reporters have suspiciously similar account ages, same IP subnet, or prior dismissed-report history), the moderator may flag the reporters for counter-review. This is an operational decision, not an automated one.

---

### 5.4 Ban Expires While Player Is in an Active Match

**Scenario:** Player X has a 24h temp ban. The ban expires (`banExpiresAt` passes) while player X is in the middle of an active match (they were able to start the match before the ban was issued, or a timing edge case placed the expiry mid-match).

**Resolution:**
1. Ban enforcement happens **at login only** (see §3.7.2). The server does not monitor `banExpiresAt` during active sessions.
2. If the ban expiry occurs mid-match, the current match proceeds normally. The player is not disconnected.
3. At the player's **next login**, the ban-check code (§3.7.2) detects `now >= banExpiresAt`, lifts the ban (sets `isBanned = false`, `banExpiresAt = null`), and allows the login to proceed.
4. Edge case of reverse: if a ban is **issued** while the player is in an active match (e.g., a moderator reviews a report and applies a ban while match M is in progress), the ban takes effect at next login. The player finishes the current match. They cannot start a new match session after this match ends because the next login check blocks access.

---

### 5.5 False Positive AFK — Player on Poor Network

**Scenario:** Player X has an intermittent mobile connection causing frequent brief disconnects. Their `time_connected_ms` is fragmented by multiple INACTIVE windows. After the match, they are reported for AFK.

**Resolution:**
1. The AFK signal formula (§4.1) explicitly excludes INACTIVE time from the input rate denominator. If player X was connected for 60s out of a 180s match (the rest was INACTIVE), the formula evaluates their input rate over their 60s of connected time only.
2. If player X was genuinely active during their connected windows (> `AFK_INPUT_THRESHOLD` inputs per 30s while connected), `afk_signal_triggered = false` — the signal does not fire despite the disconnects.
3. If player X was INACTIVE for so long that their connected time is insufficient to form a meaningful window (less than one full `AFK_WINDOW_MS` of connected time), the AFK signal is set to `null` rather than `true`. An inconclusive signal is not a positive signal.
4. The moderator sees `time_connected_ms` alongside `input_rate_avg` in the evidence snapshot, enabling them to distinguish "low inputs while connected" from "mostly disconnected but active when connected."
5. The Disconnect Handler's `disconnect_type` classification (voluntary vs. network drop) is also available in the snapshot. Multiple network-drop disconnects alongside normal input rate is a clear false-positive pattern.

**Formal rule:** `afk_signal_triggered = null` when `time_connected_ms < AFK_WINDOW_MS` (less than one full window of connected time available).

---

### 5.6 Appeal Granted After Permanent Ban

**Scenario:** Player X was permanently banned. They filed an appeal and the appeal was granted.

**Resolution:**
1. The senior moderator sets `moderation_history.appeal_status = 'granted'` on the relevant history record.
2. The Player Profile is updated: `isBanned = false`, `banExpiresAt = null`. This is written to PostgreSQL directly.
3. The Redis cache entry for player X's profile is **immediately invalidated** (key deleted). The next read will fall through to PostgreSQL and return the updated, unbanned record.
4. The offense counter: the granted appeal does **not** automatically erase the offense from the `moderation_history` table. The history record remains for audit purposes. However, the moderator may annotate the record with `moderator_notes = 'appeal granted; offense not counted for future ladder position'` to instruct future moderators.
5. Player X receives a confirmation email at the address registered to their Supabase account. The email is sent from the support system, not the game server. The game server sets a `pendingNotification` field that the support system polls.
6. On next login, the ban check (§3.7.2) finds `isBanned = false` and proceeds normally. The player regains full access.
7. Reinstatement does not grant any compensation (Diamonds, XP) for banned time at MVP. Post-MVP, a compensation workflow may be added.

---

### 5.7 Report Filed After Match Record TTL

**Scenario:** A player waits longer than expected before filing a report (e.g., a device issue causes the results screen to be seen the next day from a screenshot). The match record may have been purged from the hot-read cache or aged out.

**Resolution:**
1. The 60-second post-match report window (enforced client-side) makes this scenario extremely unlikely during normal operation.
2. If the client somehow submits a report for a `match_id` that returns no record from the PostgreSQL `matches` table, the server returns HTTP 422 with `REPORT_MATCH_NOT_FOUND`.
3. The client displays: "Unable to submit report — match data unavailable." No retry is attempted.
4. Match records in PostgreSQL are retained for at minimum `MATCH_RECORD_RETENTION_DAYS` (see Tuning Knobs §7). Given the 60-second report window and normal match TTL, this should never occur in practice.

---

## 6. Dependencies

### 6.1 Upstream — Systems This System Depends On

| System | What Is Consumed | Contract |
|---|---|---|
| **Authentication** (`authentication.md`) | Supabase JWT for every API call. `userId` (UUID) extracted from validated JWT — never from request body. Admin role check for moderator-only endpoints. | Every `POST /reports` request requires a valid JWT. Ban check occurs after JWT validation. |
| **Player Profile** (`player-profile.md`) | `isBanned`, `banExpiresAt` fields read at login. Profile written on ban application (`isBanned = true`, `banExpiresAt`). Redis cache invalidated on ban state change. 26-field schema is the source of truth. | Player Profile owns the `isBanned` / `banExpiresAt` fields. Moderation writes to them via a dedicated `moderationService.applyBan(userId, banType)` method that Player Profile exposes. Moderation does not write directly to `player_profiles` table. |
| **Match Flow** (`match-flow.md`) | `matchId` and full participant list (to validate that reporter and reported were both in the match). Match results payload (kills, deaths, damage dealt, `matchDurationSec`) used to assemble `evidence_snapshot`. `mmrSnapshot` per player used for suspicious-damage MMR bracket lookup. | Match Flow writes the authoritative match record before reports can be filed. The 60-second report window ensures the match record is already committed. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Behavioral telemetry — AFK signals and disconnect rate data — consumed from the analytics event stream to build `evidence_snapshot`. Two-tier consent applies: Tier 0 data (session lifecycle) is always available; Tier 1 (behavioral) requires player consent and is used in moderation signals only with opt-in data. | Analytics owns the event schema. Moderation reads aggregate signals, not raw event streams. |
| **Logging / Monitoring** (`logging-monitoring.md`) | `ILogger` interface. PII policy: `userId` UUID only in all log lines — never `display_name` or email. Moderation events logged at `INFO`; ban actions logged at `WARN`; appeal actions logged at `INFO`. | Standard log level discipline. Correlation IDs per request enable end-to-end tracing of report submission through moderation action. |
| **Session Manager** (`session-manager.md`) | Per-player input event log (for AFK signal computation). Session state transitions used to classify INACTIVE vs. ACTIVE windows when computing `time_connected_ms`. | Session Manager exposes a `getPlayerInputRate(playerId, matchId)` query. Input log is ephemeral (Redis); must be queried before session data TTL. |
| **Disconnect Handler** (`disconnect-handler.md`) | `disconnect_type` classification (`voluntary` vs. `network_drop`) per player per match. Used to compute `disconnectRate` and disambiguate false-positive AFK signals. | Disconnect Handler writes `DisconnectAnalyticsEvent` to Analytics. Moderation reads the classification from the match record, not directly from the Disconnect Handler. |

### 6.2 Downstream — Systems That Depend on This System

| System | What Is Provided | Contract |
|---|---|---|
| **Player Profile** | Ban state writes (`isBanned`, `banExpiresAt`). Player Profile exposes the mutation API; Moderation calls it. | One-way: Moderation calls Player Profile's ban API. Player Profile enforces the schema. |
| **Authentication** | Login is blocked server-side when `isBanned = true` and ban has not expired. Authentication reads the ban check result from the Player Profile state that Moderation has set. | Authentication does not call Moderation directly; it reads from Player Profile. |
| **Match Flow (future)** | Post-MVP: matchmaking may exclude banned players from queue. At MVP this is enforced solely at login, so banned players cannot reach the matchmaking queue. | No direct runtime dependency at MVP. |

### 6.3 Dependency Diagram

```
Authentication ──────────────► Moderation/Reporting ──────────► Player Profile (ban writes)
Player Profile (ban read) ──►                       ──────────► Analytics (report events)
Match Flow ─────────────────►                       ──────────► Logging/Monitoring
Analytics/Telemetry ────────►
Session Manager ────────────►
Disconnect Handler (via Analytics)
```

---

## 7. Tuning Knobs

All constants are Remote Config–eligible unless noted. Changes take effect on the next report submission or moderation queue load; no server restart required.

| Knob | Constant Name | Default | Safe Range | Effect |
|---|---|---|---|---|
| **Report prompt duration** | `REPORT_PROMPT_DURATION_MS` | 60 000ms (60s) | 30 000 – 120 000ms | Longer = more time for players to file reports; longer results screen occupation. Below 30s: rushed on slow devices. Above 120s: delays re-queue. |
| **AFK input threshold** | `AFK_INPUT_THRESHOLD` | 5 | 2 – 15 | Lower = more lenient (fewer false positives); higher = stricter. Values below 2 risk false-negatives for genuine AFK. Values above 15 may flag players with reduced input frequency (e.g., trap characters with low inherent input cadence). |
| **AFK window size** | `AFK_WINDOW_MS` | 30 000ms (30s) | 15 000 – 60 000ms | Shorter windows make the signal more responsive but noisier. Must divide evenly into typical match durations for clean averaging. |
| **Disconnect sample size** | `DISCONNECT_SAMPLE_SIZE` | 10 | 5 – 20 | Smaller samples are more reactive (new behavior detected sooner); larger samples are more stable (less noise from occasional legitimate disconnects). |
| **Disconnect rate threshold** | `DISCONNECT_RATE_THRESHOLD` | 0.30 | 0.15 – 0.50 | Lower = stricter (more players flagged); higher = more lenient. Below 0.15 risks flagging players with legitimate network issues. Above 0.50 only catches severe cases. |
| **Suspicious damage sample size** | `SUSPICIOUS_DAMAGE_SAMPLE_SIZE` | 5 | 3 – 10 | Fewer consecutive matches required = faster detection but more false positives. More = slower detection but higher confidence. |
| **Suspicious damage threshold** | `SUSPICIOUS_DAMAGE_THRESHOLD` | 0.05 | 0.02 – 0.15 | Fraction of expected damage. Lower = only flags extreme outliers; higher = flags mild underperformance (more false positives for players learning a new character). |
| **Max reports per player per day** | `MAX_REPORTS_PER_DAY` | 3 | 1 – 10 | Lower = harder to report bomb but may frustrate players who encounter multiple bad actors in a session. Higher = more abuse risk. |
| **Anti-cheat auto-suspend duration** | `ANTI_CHEAT_AUTO_SUSPEND_DURATION_MS` | 86 400 000ms (24h) | 3 600 000 – 604 800 000ms (1h–7d) | Duration of automatic suspension on FATAL anti-cheat event. Shorter = less disruption if false positive; longer = stronger deterrent. |
| **Reporter credibility decay (dismissed)** | `CREDIBILITY_DECAY_PER_DISMISSED_REPORT` | 0.05 | 0.01 – 0.15 | Decay per dismissed report filed by the reporter. Higher = faster credibility loss for bad-faith reporters. |
| **Reporter credibility decay (banned)** | `CREDIBILITY_DECAY_PER_BAN` | 0.20 | 0.05 – 0.50 | Decay per sanction on the reporter's own record. Higher = players with their own ban history contribute less to queue priority. |
| **Minimum reporter credibility** | `MIN_CREDIBILITY` | 0.10 | 0.05 – 0.30 | Floor ensures even heavily penalized reporters still contribute marginally. Too low and their reports have negligible queue impact. |
| **Match record retention** | `MATCH_RECORD_RETENTION_DAYS` | 90 | 30 – 365 | Days match records are retained in PostgreSQL for report evidence retrieval. Must exceed the report filing window by a large margin. |
| **Report count bonus cap** | `REPORT_COUNT_BONUS_CAP` | 5 | 3 – 10 | Maximum `reportCountBonus` regardless of actual reporter count. Caps mass-report queue inflation. |

### Expected Damage Lookup Table by MMR Bracket

Used in the suspicious performance signal (§4.3). Values represent expected total damage dealt per match. Configurable in Remote Config as a JSON object.

| MMR Range | `expectedDamageForMMR` | Notes |
|---|---|---|
| 0 – 799 | 2 500 | New / low-skill bracket |
| 800 – 1199 | 3 500 | Developing bracket |
| 1200 – 1599 | 4 500 | Mid-skill bracket |
| 1600 – 1999 | 5 500 | High-skill bracket |
| 2000+ | 6 500 | Top-tier bracket |

These values are initial estimates and must be calibrated after 30 days of live data. The lookup key is the player's `mmrSnapshot` value from the match (not their current MMR).

### Tuning Interactions

- `AFK_WINDOW_MS` and `AFK_INPUT_THRESHOLD` interact: halving the window size without halving the threshold doubles the stringency of the signal. Adjust both when tuning AFK detection.
- `SUSPICIOUS_DAMAGE_THRESHOLD` should be calibrated separately per game mode if damage output patterns differ significantly between modes (1v1 vs. FFA). At MVP, a single threshold applies to all modes.
- `DISCONNECT_RATE_THRESHOLD` must be evaluated against the baseline voluntary disconnect rate observed in analytics before tightening. Do not set below the 75th percentile of the player population's natural disconnect rate.

---

## 8. Acceptance Criteria

### AC-MOD-01 — Report Submission: Valid Report Stored

**Given** a player completes a match and the report prompt is visible (within 60 seconds of results delivery)
**When** the player selects a target, selects a category, and submits
**Then** the server stores a `reports` record with `reporter_id`, `reported_id`, `match_id`, `category`, `timestamp`, and an assembled `evidence_snapshot` containing all fields defined in §3.3.1
**And** the record `status` = `'pending'`
**And** the server responds HTTP 201
**And** the client dismisses the report prompt

---

### AC-MOD-02 — Report Submission: Duplicate Report Rejected

**Given** player A has already filed a report against player B for match M
**When** player A submits a second report against player B for the same match M
**Then** the server returns HTTP 409 (or the client-side deduplication prevents the second request)
**And** no second record is created in the `reports` table
**And** the client UI grays out the already-reported target

---

### AC-MOD-03 — Report Prompt: 60-Second Timeout

**Given** the match results screen is shown to a player
**When** 60 seconds elapse without the player submitting a report
**Then** the report prompt collapses and disappears from the results screen
**And** no partial report is stored
**And** the player can still navigate the results screen normally

---

### AC-MOD-04 — Daily Rate Limit Enforced

**Given** player A has submitted `MAX_REPORTS_PER_DAY` (default: 3) reports in the current UTC calendar day
**When** player A attempts to submit a fourth report
**Then** the server returns HTTP 429
**And** no report record is created
**And** the client silently dismisses the report prompt without displaying an error to the player

---

### AC-MOD-05 — Evidence Snapshot: AFK Signal Fires Correctly

**Given** a player had an `input_rate_avg` of 1.6 inputs per 30s during the connected portion of a match (as computed per §4.1)
**When** a report is filed against this player
**Then** `evidence_snapshot.afk_signal_triggered = true` in the stored report
**And** `evidence_snapshot.input_rate_avg = 1.6`
**And** `evidence_snapshot.time_connected_ms` reflects only ACTIVE (non-INACTIVE) time

---

### AC-MOD-06 — Evidence Snapshot: AFK Signal Null When Insufficient Connected Time

**Given** a player was in INACTIVE state for all but 15 000ms of a match (less than `AFK_WINDOW_MS = 30 000ms`)
**When** a report is filed against this player
**Then** `evidence_snapshot.afk_signal_triggered = null`
**And** the moderation queue does not count this as a positive AFK signal for `baseSignalScore`

---

### AC-MOD-07 — Evidence Snapshot: Disconnect Rate Signal Computed

**Given** a player has a voluntary disconnect rate of 0.40 over their last 10 matches
**When** a report is filed against this player
**Then** `evidence_snapshot.disconnect_rate_signal = 0.40`
**And** the moderation queue `baseSignalScore` includes +1 for this signal (since 0.40 > `DISCONNECT_RATE_THRESHOLD = 0.30`)

---

### AC-MOD-08 — Evidence Snapshot: Disconnect Rate Null for New Players

**Given** a player has completed fewer than 3 total matches
**When** a report is filed against this player
**Then** `evidence_snapshot.disconnect_rate_signal = null`
**And** no disconnect rate signal contributes to `baseSignalScore`

---

### AC-MOD-09 — Ban Enforcement at Login: Temp Ban Blocks Access

**Given** a player has `isBanned = true` and `banExpiresAt` is a future timestamp
**When** the player attempts to log in
**Then** the server returns HTTP 403 with `{ error: 'ACCOUNT_BANNED', banType: 'temporary', expiresAt: <timestamp> }`
**And** the client displays a ban modal with the expiry time

---

### AC-MOD-10 — Ban Enforcement at Login: Expired Temp Ban Lifted

**Given** a player has `isBanned = true` and `banExpiresAt` is a past timestamp
**When** the player attempts to log in
**Then** the server sets `isBanned = false` and `banExpiresAt = null` on the Player Profile
**And** login proceeds normally
**And** the player is not shown a ban modal

---

### AC-MOD-11 — Ban Enforcement at Login: Permanent Ban Blocks Access

**Given** a player has `isBanned = true` and `banExpiresAt = null`
**When** the player attempts to log in
**Then** the server returns HTTP 403 with `{ error: 'ACCOUNT_BANNED', banType: 'permanent', expiresAt: null, appealUrl: '<url>' }`
**And** the client displays a ban modal with an appeal link

---

### AC-MOD-12 — Ban Does Not Interrupt Active Match

**Given** a moderator applies a ban to player X while player X is in an active match
**When** the ban is written to Player Profile
**Then** player X's current match session continues uninterrupted
**And** player X cannot log in to a new session after the match ends
**And** no mid-match disconnection is triggered by the ban

---

### AC-MOD-13 — Mass Report: No Auto-Ban

**Given** all 7 other players in an 8-player FFA file reports against the same target from the same match
**When** all reports are received
**Then** 7 `reports` records are stored in the database with `status = 'pending'`
**And** no automatic ban or suspension is applied (no Anti-Cheat FATAL event was triggered)
**And** the queue priority `reportCountBonus = min(7, REPORT_COUNT_BONUS_CAP) = 5` (default cap)
**And** a human moderator must review before any sanction is applied

---

### AC-MOD-14 — Queue Priority: Cheating Exploit Receives Category Bonus

**Given** a report is filed with `category = 'cheating_exploit'` with one automated signal
**And** another report is filed with `category = 'afk_abandonment'` with one automated signal
**And** both reports have identical `reportCountBonus` and `reporterCredibilityBonus`
**When** the moderation queue is sorted
**Then** the `cheating_exploit` report has a higher `queuePriority` (by `categoryBonus = 2` vs `0`)
**And** the cheating report is shown to the moderator first

---

### AC-MOD-15 — Anti-Cheat FATAL: Automatic Temporary Suspension Applied

**Given** the Anti-Cheat stub emits a `FATAL` cheat detection event for player X
**When** the Moderation system receives the event
**Then** `isBanned = true` and `banExpiresAt = now + ANTI_CHEAT_AUTO_SUSPEND_DURATION_MS` is written to player X's Profile
**And** a `reports` record is created with `reporter_id = SYSTEM_USER_ID` and `status = 'under_review'`
**And** the report appears at the top of the moderation queue
**And** player X cannot log in until the suspension expires or a moderator lifts it

---

### AC-MOD-16 — Reporter Feedback: Generic Notification Sent

**Given** a report transitions from `pending` or `under_review` to `actioned` or `dismissed`
**When** the report status update is written to the database
**Then** a push notification is dispatched to the original reporter with the message "We've reviewed your recent report. Thank you for helping keep BRAWLZONE fair."
**And** the notification contains no information about the sanction outcome or the reported player

---

### AC-MOD-17 — Appeal Granted: Account Restored and Cache Invalidated

**Given** player X is permanently banned and their appeal is granted by a senior moderator
**When** the appeal is processed
**Then** `player_profiles.isBanned = false` and `banExpiresAt = null` in PostgreSQL
**And** the Redis cache entry for player X's profile is invalidated immediately
**And** `moderation_history.appeal_status = 'granted'` is set
**And** player X can log in successfully on the next attempt
**And** a confirmation email is dispatched to player X's registered email address

---

### AC-MOD-18 — Reporter Credibility: Prior Dismissed Reports Reduce Queue Weight

**Given** reporter A has 4 previously dismissed reports and 1 prior ban
**When** reporter A files a report that enters the moderation queue
**Then** the `reporterCredibilityBonus` contribution from reporter A is calculated as `1.0 × (1 - 0.05 × 4) × (1 - 0.20 × 1) = 0.64`
**And** this value is reflected in the queue priority for the target report cluster

---

### AC-MOD-19 — PII Policy: No Email or Display Name in Logs

**Given** any moderation event is logged (report submission, ban action, appeal)
**When** the log line is written via `ILogger`
**Then** the log contains `userId` (UUID) only — never the player's `display_name` or email address
**And** moderator actions are logged at `WARN` level for ban actions and `INFO` level for warn sanctions and appeals

---

### AC-MOD-20 — Report Not Filed for Abandoned Matches

**Given** a match was abandoned (session state = `abandoned` per Match Flow)
**When** the client receives the abandoned session notification
**Then** no report prompt is displayed to any participant
**And** any attempt to call `POST /reports` with a `match_id` corresponding to an abandoned session is rejected with HTTP 422

---

*End of Document*
