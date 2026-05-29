# Anti-Cheat / Validation — Game Design Document

> **System**: Anti-Cheat / Validation
> **Priority**: Full Vision
> **Layer**: Foundation
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## 1. Overview

The Anti-Cheat / Validation system defines BRAWLZONE's layered defense against unfair play. The primary defense is architectural: the server is authoritative for all game state — players send inputs only, and the server computes all positions, damage, ability resolution, and win conditions, making client-side memory manipulation and position spoofing structurally inert. On top of this baseline, the system adds five additional layers: per-tick input validation (within the 3ms Validation budget), statistical anomaly detection (async, post-match), best-effort client integrity signals, economy integrity enforcement, and FATAL-level cheat detection that triggers automatic account suspension via the Moderation system. Client integrity signals are treated as advisory only — the server-authoritative architecture is the trust boundary.

---

## 2. Player Fantasy

Players never interact with this system directly. What they feel is the consequence: ranked matches feel fair because speed hackers and damage exploiters are removed within hours, not days. Legitimate players are never falsely suspended — the FATAL triggers are set to thresholds that are physically impossible through any legitimate combination of lag, skill, and character ability. The appeal process is fast and transparent for the rare false positive. Anti-cheat is invisible when working correctly.

---

## 3. Detailed Rules

### 3.1 Server-Authoritative Baseline

The following cheat vectors are structurally prevented by the server-authoritative architecture and require no active detection:

| Cheat Vector | Why It Fails |
|-------------|-------------|
| Position injection | Server computes all positions from validated inputs; client-sent positions are ignored |
| Damage modification | Server computes all damage from character stats + ability definitions; client cannot inject damage values |
| Win condition trigger | Server evaluates all win conditions; client `game_over` messages are ignored |
| Ability cooldown bypass (client-side) | Server maintains authoritative cooldown state; client activation requests validated against server state |
| Health modification | Server maintains authoritative HP; client-sent HP values are not trusted |
| Speed hacks (client-side) | Server caps position delta per tick; any excess movement is clamped, not executed |

The server-authoritative baseline means a large class of traditional mobile cheats (memory editors, speed hacks, aim bots that inject positions) produce no gameplay effect. Anti-Cheat layers above this baseline focus on the remaining vectors: input flooding, statistical outliers, and network-layer attacks.

### 3.2 Input Validation Layer

All input validation runs within the **3ms Validation budget** of the server tick (Input Collection 2ms → **Validation 3ms** → Simulation 20ms → ...).

#### 3.2.1 Input Rate Limiting

```typescript
interface TickInputBatch {
  playerId: string;
  inputs: PlayerInput[];
  tickNumber: number;
}
```

- Maximum `MAX_INPUTS_PER_TICK` inputs per player per tick (default: 3 — one joystick update, one ability activation, one special action).
- Excess inputs are silently discarded and counted in a rolling `inputFloodCounter`.
- If `inputs.length > INPUT_FLOOD_THRESHOLD` in a single tick, a FATAL log is emitted (bot/macro detection).

#### 3.2.2 Joystick Magnitude Clamping

- Input `joystickMagnitude` is clamped to `[0.0, 1.0]`.
- Magnitude > 1.0 normalized to 1.0 before simulation. No movement speed exploit possible.
- Log at DEBUG level when clamping occurs (legitimate edge case on imprecise touch inputs).

#### 3.2.3 Ability Activation Validation

Before applying any ability:
1. Check `ability.ownerId === playerId` (character owns this ability).
2. Check `cooldownRemainingMs <= 0` (not on cooldown).
3. Check resource cost (if applicable) is available.
4. If any check fails: discard activation silently + increment `invalidAbilityCounter`.
5. If `cooldownRemainingMs > COOLDOWN_HACK_THRESHOLD_MS` at activation time: emit FATAL log.

#### 3.2.4 Position Delta Validation

Even though the server computes all positions, clients send a `clientPosition` hint for lag compensation context. This hint is validated:

- If `|clientPosition - lastKnownServerPosition| > MAX_POSITION_DELTA_LGU`, the hint is discarded and a WARN is logged.
- The simulation uses the server-computed position regardless; this validation only flags anomalous hints.

#### 3.2.5 Sequence Number Monotonicity

- Each client input carries a `sequenceNumber` (monotonically increasing per connection).
- Server rejects inputs with `sequenceNumber <= lastProcessedSeqNo` for that player.
- Prevents replay attacks (resending old inputs to trigger ability re-activations).

### 3.3 Statistical Anomaly Detection

Statistical checks run **asynchronously after match completion** and do not affect the match in progress. All anomalies feed the Moderation queue — they never trigger automatic bans (except via the separate FATAL mechanism in §3.6).

#### 3.3.1 Damage Output Anomaly

```
damageAnomalyScore = actualDamageDealt / expectedDamageDealt
```

`expectedDamageDealt` is derived from: character + equipped ability set + match duration + opponent character (HP pool). Expected values are pre-computed reference tables per character/mode combination.

- Flag if `damageAnomalyScore > DAMAGE_ANOMALY_MULTIPLIER` (default: 3.0) for the match.
- Flag is cumulative: flag 3+ consecutive matches → escalate to Moderation queue with HIGH priority.

#### 3.3.2 Aim Precision Anomaly

- Track `projectileHitRate = projectilesHit / projectilesFired` per match.
- Compare against 95th-percentile hit rate for the player's MMR bracket (pre-computed reference table, updated weekly from Analytics data).
- Flag if `projectileHitRate > AIM_ANOMALY_PCT_THRESHOLD` (default: 95th percentile + 15%) for 3+ consecutive matches.

#### 3.3.3 MMR Trajectory Anomaly

```
mmrGainRate = (currentMmr - mmr7DaysAgo) / 7  // MMR points per day
```

- Flag if `mmrGainRate > MMR_GAIN_ANOMALY_PER_DAY` (default: 150 MMR/day) over a 7-day window.
- Indicates possible account boosting, account sharing, or win-trading.
- Cross-reference: flag is strengthened if the player's device/IP hash overlaps with another recently-flagged account.

#### 3.3.4 Moderation Queue Integration

All statistical flags are written to `moderation_signals` (a companion table to `reports`) with:
- `signalType`: `DAMAGE_ANOMALY` | `AIM_ANOMALY` | `MMR_TRAJECTORY`
- `userId`, `matchId`, `signalValue`, `threshold`, `timestamp`
- `priority`: computed from cumulative flags (1 flag = LOW, 3+ = HIGH)

Human moderators review flagged accounts. No automatic ban from statistical signals alone.

### 3.4 Client Integrity Signals

Client-side signals are **best-effort advisory only**. A determined attacker can spoof any of them. They are logged and contribute to Moderation signal weighting, but the server-authoritative architecture is the actual trust boundary.

#### 3.4.1 Jailbreak / Root Detection

- On app launch: call `expo-device` heuristics (`isDevice`, `osBuildId` patterns).
- Result stored in `clientIntegrityFlags.isJailbroken` (boolean).
- Sent to server on Socket.io connection as part of `connection_ack` metadata.
- Server logs at INFO level. Does not block play. Contributes +0.1 to Moderation credibility penalty weight.

#### 3.4.2 APK Signature Verification (Android)

- On app launch: verify APK signature against `EXPECTED_APK_CERT_HASH` (Remote Config cold key).
- Mismatch → `clientIntegrityFlags.apkTampered = true` → WARN log + account flagged for review.
- Does not block play at MVP (disruptive to sideloaded installs that may be legitimate).

#### 3.4.3 Certificate Pinning

- API Client enforces TLS certificate pinning on all HTTPS connections to the backend.
- Expected certificate hash loaded from `CERT_PIN_HASH` Remote Config cold key.
- If certificate doesn't match: connection refused; logs FATAL (infrastructure-level concern, not player ban).
- Certificate rotation protocol: deploy new cert pin 2 weeks before old cert expires; ship app update with new hash; maintain both hashes during overlap window.

#### 3.4.4 Emulator Detection

- `expo-device` `isDevice === false` flag.
- Logged as INFO. Does not block play (legitimate dev/QA use case).
- If emulator flag + high-frequency suspicious play pattern: escalate to Moderation.

### 3.5 Economy Integrity

| Rule | Enforcement |
|------|-------------|
| All currency grants are server-side only | Currency System has no client-callable grant endpoint |
| IAP receipts validated server-side | RevenueCat webhook-only; no client-side grant |
| Ledger is append-only | No DELETE/UPDATE on `currency_ledger`; only INSERT |
| Inventory grants via `grantItem()` only | 11-step function with idempotency check; no direct table writes |
| Admin grant requires elevated JWT role | Supabase RLS + server middleware check |
| Balance cap enforced on every grant | Currency System truncates at `COIN_MAX_BALANCE` / `DIAMOND_MAX_BALANCE` |

These rules are enforced at the database and application level, not the client level. A compromised client cannot grant itself currency because there is no endpoint to call.

### 3.6 FATAL Cheat Detection + Auto-Suspension

The following conditions emit a FATAL log line immediately upon detection during the tick loop. A FATAL log triggers:
1. The Logging / Monitoring system pages on-call instantly.
2. The Moderation system auto-suspends the account for `AUTO_SUSPEND_DURATION_H` hours.
3. Human review is expected within that window; suspension lifted if cleared.

```typescript
interface FatalCheatEvidence {
  userId: string;
  matchId: string;
  detectionType: FatalCheatType;
  observedValue: number;
  threshold: number;
  tickNumber: number;
  rawInputSnapshot: PlayerInput[];
}

enum FatalCheatType {
  COOLDOWN_BYPASS     = 'COOLDOWN_BYPASS',
  TELEPORT_DETECTED   = 'TELEPORT_DETECTED',
  IMPOSSIBLE_DAMAGE   = 'IMPOSSIBLE_DAMAGE',
  INPUT_FLOOD         = 'INPUT_FLOOD',
}
```

| FATAL Trigger | Condition | Threshold Default |
|--------------|-----------|-------------------|
| **COOLDOWN_BYPASS** | Ability activated with `cooldownRemainingMs > COOLDOWN_HACK_THRESHOLD_MS` | 500 ms |
| **TELEPORT_DETECTED** | Client position hint delta > `TELEPORT_THRESHOLD_LGU` in one tick | see §4.1 |
| **IMPOSSIBLE_DAMAGE** | Single hit damage value > `MAX_THEORETICAL_DAMAGE` | see §4.2 |
| **INPUT_FLOOD** | `inputs.length > INPUT_FLOOD_THRESHOLD` in one tick | 20 inputs |

**Match continues normally** after a FATAL detection — the current match is not terminated. The ban is applied at the player's next login, not mid-match. This prevents disruption to other legitimate players in the match and avoids telegraphing detection to the cheater during the match.

---

## 4. Formulas

### 4.1 Maximum Legitimate Position Delta (Teleport Threshold)

```
maxLegitDelta = (MAX_SPEED_LGU_PER_SEC / TICK_RATE_HZ) × (1 + LAG_COMP_TICKS)
TELEPORT_THRESHOLD_LGU = maxLegitDelta × TELEPORT_SAFETY_MULTIPLIER
```

| Variable | Default | Notes |
|----------|---------|-------|
| `MAX_SPEED_LGU_PER_SEC` | 12.0 | Max character speed with 1.0× modifier stack |
| `TICK_RATE_HZ` | 20 | Server tick rate |
| `LAG_COMP_TICKS` | 4 | Max rewind ticks (floor(200ms / 50ms)) |
| `TELEPORT_SAFETY_MULTIPLIER` | 2.5 | Headroom for legitimate high-lag clients |

**Example**:
```
maxLegitDelta = (12.0 / 20) × (1 + 4) = 0.6 × 5 = 3.0 LGU
TELEPORT_THRESHOLD_LGU = 3.0 × 2.5 = 7.5 LGU
```

A position hint delta > 7.5 LGU in a single tick is physically impossible for any legitimate player, even with maximum lag compensation. **This is why legitimate high-latency players do not trigger false positives**: the lag compensation rewind cap of 4 ticks is already factored into the threshold calculation.

### 4.2 Maximum Theoretical Damage Per Hit

```
MAX_THEORETICAL_DAMAGE = MAX_BASE_DAMAGE × MAX_DAMAGE_MULTIPLIER × AFFINITY_BONUS
```

| Variable | Default | Notes |
|----------|---------|-------|
| `MAX_BASE_DAMAGE` | 180 | Highest base damage value of any ability in the game |
| `MAX_DAMAGE_MULTIPLIER` | 1.5 | Maximum damage modifier from any status effect stack |
| `AFFINITY_BONUS` | 1.1 | +10% affinity bonus (Deck / Loadout System) |

**Example**:
```
MAX_THEORETICAL_DAMAGE = 180 × 1.5 × 1.1 = 297 damage
```

Any single-hit damage value above 297 is impossible via legitimate play. FATAL triggers at > 297 (configurable via `MAX_THEORETICAL_DAMAGE` tuning knob).

### 4.3 Damage Anomaly Score

```
damageAnomalyScore = actualDamageDealt / expectedDamageDealt(character, abilitySet, matchDuration)
```

**Example**: Vex with default loadout in a 90s 1v1 Duel. Expected damage output: ~1,200 based on reference table. Player dealt 4,800 damage → `4800 / 1200 = 4.0`. This exceeds `DAMAGE_ANOMALY_MULTIPLIER = 3.0` → flagged.

### 4.4 MMR Gain Rate

```
mmrGainRate = (currentMmr - mmrSnapshot7DaysAgo) / 7  // units: MMR points per day
```

**Example**: Player at MMR 1800 today, was at MMR 800 seven days ago.
```
mmrGainRate = (1800 - 800) / 7 = 142.9 MMR/day
```
Default threshold `MMR_GAIN_ANOMALY_PER_DAY = 150`. This player is just below threshold — borderline, not flagged automatically, but watch-listed.

---

## 5. Edge Cases

**EC-01: High-latency legitimate player flagged for position delta anomaly.**
The `TELEPORT_THRESHOLD_LGU` formula explicitly accounts for the maximum lag compensation window (4 ticks × 50ms = 200ms). A player with 190ms RTT (near the compensation cap) will have their position hints rewound up to 4 ticks — this is factored into `maxLegitDelta` via the `(1 + LAG_COMP_TICKS)` multiplier. The `TELEPORT_SAFETY_MULTIPLIER = 2.5` adds 150% additional headroom above the theoretical maximum. A false positive here is therefore not possible without also exceeding the lag compensation cap, which produces a gameplay disconnect rather than a FATAL event. False positives from high-latency play are structurally prevented by the formula design.

**EC-02: Auto-suspension of a legitimate player (false positive).**
The player taps the appeal link in their suspension notification email. An on-call moderator reviews `FatalCheatEvidence` within `AUTO_SUSPEND_DURATION_H` hours. If the evidence is ambiguous or the threshold was misconfigured: moderator marks `fraudulent = false` in the `moderation_actions` table; `isBanned = false` and `banExpiresAt = null` written to player profile; Push notification sent: "Your appeal was reviewed — your account is restored." If the player appeals after the suspension expires naturally, the appeal is still reviewed for record-keeping.

**EC-03: Certificate pinning blocks legitimate app update.**
When deploying a new TLS certificate:
1. New cert hash added to `CERT_PIN_HASH` Remote Config cold key (as a comma-separated list: old hash + new hash).
2. App update shipped with both hashes in client config.
3. After `CERT_ROTATION_OVERLAP_DAYS` (default: 14) days, old hash removed from Remote Config.
4. Clients running very old versions with only the old hash will fail to connect → shown "Update Required" screen. This is acceptable: outdated clients are a security risk regardless.

**EC-04: Coordinated account sharing / MMR boosting across devices.**
MMR trajectory anomaly (§3.3.3) detects the symptom. Supporting signals: rapid MMR gain + multiple device hashes on same account within 24h + geographic/timezone inconsistency in play sessions. These signals are aggregated in the Moderation queue with a composite priority score. Human review determines if sharing or boosting is occurring. No automated ban from this signal alone.

**EC-05: Cheat detected during active match.**
FATAL log emitted → Moderation system schedules ban for next login. Current match proceeds to its natural conclusion. The cheating player's match result is recorded normally. Post-match, the Moderation team may review the match record and void the result if appropriate (manual action, not automated). The ban prevents future matches; it does not retroactively alter the current match outcome.

---

## 6. Dependencies

### 6.1 Upstream (Systems Anti-Cheat Reads / Monitors)

| System | What Anti-Cheat Consumes |
|--------|--------------------------|
| Match Server | Per-tick input batches; position hints; damage events; ability activations |
| Combat System | Damage values per hit; speed modifier stack |
| Ability / Skill System | Cooldown state per ability per player |
| Session Manager | Active session state; one-session-per-player enforcement |
| MMR / Ranked System | MMR snapshots for trajectory anomaly calculation |
| Authentication | JWT validation; admin role for elevated grants |
| Analytics / Telemetry | Behavioral telemetry feeds anomaly reference tables |
| Moderation / Reporting | FATAL events trigger auto-suspension via Moderation; human review queue |
| Player Profile | `isBanned`, `banExpiresAt` — enforced at login |
| Currency System | Append-only ledger constraint; no-client-grant enforcement |
| Inventory / Entitlements | `grantItem()` as sole write path; idempotency enforcement |

### 6.2 Downstream (Systems Anti-Cheat Writes / Notifies)

| System | What Is Written |
|--------|-----------------|
| Moderation / Reporting | `moderation_signals` table rows for statistical anomalies; FATAL trigger → auto-suspension |
| Player Profile | Ban state set via Moderation action (not directly by Anti-Cheat) |
| Logging / Monitoring | FATAL log lines for immediate on-call alert |
| Analytics / Telemetry | `cheat_detected` event (Tier 0) on FATAL trigger |

### 6.3 Non-Dependencies

- Anti-Cheat does not modify match state mid-match. It observes and reports.
- Anti-Cheat does not interact with the IAP System or Currency System write paths (those have their own integrity enforcement).

---

## 7. Tuning Knobs

All server values in `server/src/config/antiCheat.ts`. Client values in `mobile/src/config/antiCheat.ts`.

| Constant | Default | Hot/Cold | Safe Range | Description |
|----------|---------|----------|------------|-------------|
| `MAX_INPUTS_PER_TICK` | 3 | Cold | 1 – 10 | Max inputs accepted per player per tick |
| `INPUT_FLOOD_THRESHOLD` | 20 | Cold | 5 – 100 | Inputs/tick that triggers FATAL |
| `COOLDOWN_HACK_THRESHOLD_MS` | 500 | Cold | 100 – 2000 | Cooldown remaining (ms) at activation that triggers FATAL |
| `MAX_POSITION_DELTA_LGU` | 7.5 | Cold | 3.0 – 20.0 | Client hint delta before teleport FATAL; derived from formula |
| `TELEPORT_SAFETY_MULTIPLIER` | 2.5 | Cold | 1.5 – 5.0 | Headroom multiplier over theoretical max delta |
| `MAX_THEORETICAL_DAMAGE` | 297 | Cold | 200 – 999 | Single-hit damage above which FATAL fires |
| `DAMAGE_ANOMALY_MULTIPLIER` | 3.0 | Hot | 1.5 – 10.0 | Anomaly score threshold for statistical flagging |
| `DAMAGE_ANOMALY_CONSECUTIVE` | 3 | Hot | 2 – 10 | Consecutive anomalous matches before Moderation escalation |
| `AIM_ANOMALY_PCT_THRESHOLD` | 15 | Hot | 5 – 50 | Percentage points above 95th-percentile hit rate to flag |
| `AIM_ANOMALY_CONSECUTIVE` | 3 | Hot | 2 – 10 | Consecutive matches above aim threshold before escalation |
| `MMR_GAIN_ANOMALY_PER_DAY` | 150 | Hot | 50 – 500 | MMR gain rate (points/day) that triggers watch-listing |
| `AUTO_SUSPEND_DURATION_H` | 24 | Cold | 1 – 168 | Auto-suspension window (hours) on FATAL detection |
| `CERT_PIN_HASH` | (deploy value) | Cold | Valid SHA-256 | Expected TLS cert hash(es) for certificate pinning |
| `CERT_ROTATION_OVERLAP_DAYS` | 14 | Cold | 7 – 30 | Days to maintain both cert hashes during rotation |
| `EXPECTED_APK_CERT_HASH` | (deploy value) | Cold | Valid SHA-256 | Expected Android APK signing certificate hash |
| `BPXP_DEDUP_TTL_SEC` | — | — | — | (Defined in Battle Pass GDD) |

> **Operator warnings**: `DAMAGE_ANOMALY_MULTIPLIER < 1.5` risks false positives against high-skill players with unusual compositions; `MAX_INPUTS_PER_TICK > 10` allows macro-assisted input flooding without detection; `AUTO_SUSPEND_DURATION_H < 1` gives cheaters near-instant reinstatement.

---

## 8. Acceptance Criteria

**AC-AC-01: Server ignores client-sent position values.**
Given a client that sends fabricated `clientPosition` values. When the server processes inputs. Then the simulation uses server-computed position; client position hint is used only for lag compensation context, never as authoritative state.

**AC-AC-02: Joystick magnitude > 1.0 is clamped.**
Given input with `joystickMagnitude = 2.5`. When processed by Input Validation Layer. Then simulation receives `joystickMagnitude = 1.0`; no movement speed increase.

**AC-AC-03: Excess inputs per tick are discarded.**
Given a player sends 15 inputs in one tick; `MAX_INPUTS_PER_TICK = 3`. When the tick processes. Then only 3 inputs are simulated; 12 are discarded; counter incremented.

**AC-AC-04: Input flood triggers FATAL.**
Given `INPUT_FLOOD_THRESHOLD = 20`; player sends 25 inputs in one tick. When tick processes. Then FATAL log emitted with `detectionType: INPUT_FLOOD`; Moderation auto-suspension scheduled.

**AC-AC-05: Ability on cooldown is rejected.**
Given ability with `cooldownRemainingMs = 2000`; `COOLDOWN_HACK_THRESHOLD_MS = 500`. When activation request received. Then activation discarded; `invalidAbilityCounter` incremented; no FATAL (cooldown = 2000ms, threshold is 500ms — both conditions: reject activation AND below FATAL threshold).

**AC-AC-06: Ability activation with cooldown > COOLDOWN_HACK_THRESHOLD_MS triggers FATAL.**
Given ability with `cooldownRemainingMs = 800`; `COOLDOWN_HACK_THRESHOLD_MS = 500`. When activation request received. Then FATAL log emitted with `detectionType: COOLDOWN_BYPASS`; activation discarded.

**AC-AC-07: Position delta > TELEPORT_THRESHOLD_LGU triggers FATAL.**
Given `TELEPORT_THRESHOLD_LGU = 7.5`; client hint delta = 10.0 LGU. When processed. Then FATAL log emitted with `detectionType: TELEPORT_DETECTED`; hint discarded.

**AC-AC-08: Position delta within threshold does not trigger FATAL.**
Given 190ms RTT player; maximum lag-compensated position delta < 7.5 LGU. When hint processed. Then no FATAL emitted; hint used normally.

**AC-AC-09: Impossible damage value triggers FATAL.**
Given `MAX_THEORETICAL_DAMAGE = 297`; single hit value = 450. When damage event logged. Then FATAL emitted with `detectionType: IMPOSSIBLE_DAMAGE`.

**AC-AC-10: Replay attack rejected via sequence number.**
Given player sends input with `sequenceNumber = 100`; server has `lastProcessedSeqNo = 105`. When input received. Then input rejected; no simulation; no sequence number update.

**AC-AC-11: Damage anomaly flag escalates after consecutive matches.**
Given `DAMAGE_ANOMALY_MULTIPLIER = 3.0`; player has `damageAnomalyScore > 3.0` in 3 consecutive matches. When third match processed. Then `moderation_signals` row inserted with priority HIGH.

**AC-AC-12: Statistical anomaly alone does NOT auto-ban.**
Given player has 3 damage anomaly flags. When signals written to Moderation queue. Then account is NOT banned; `isBanned` remains false; human review required.

**AC-AC-13: FATAL auto-suspension fires within 5 seconds.**
Given FATAL log emitted. When Moderation system processes the event. Then `isBanned = true`, `banExpiresAt = now() + AUTO_SUSPEND_DURATION_H` written to player profile within 5 seconds of FATAL emission.

**AC-AC-14: Banned player cannot start a new match.**
Given `isBanned = true` at login. When player attempts to enter matchmaking queue. Then server returns `ACCOUNT_SUSPENDED` error; player shown suspension message and appeal link.

**AC-AC-15: Match continues after FATAL detection.**
Given FATAL detected during active match. When match continues. Then current match completes normally; other players are unaffected; ban applied at cheating player's next login only.

**AC-AC-16: Appeal restores account.**
Given suspended player's appeal reviewed and cleared by moderator. When moderator marks `fraudulent = false`. Then `isBanned = false`, `banExpiresAt = null` written; player receives push notification confirming restoration.

**AC-AC-17: APK signature mismatch logs WARN and flags account.**
Given Android client with non-matching APK cert hash. When app launches and connects. Then WARN logged; `clientIntegrityFlags.apkTampered = true` sent to server; account flagged for review; play not blocked.

**AC-AC-18: Certificate pinning rejects MITM connection.**
Given connection attempt with unexpected TLS cert. When API Client checks pin. Then connection refused; FATAL logged (infrastructure alert, not player ban).

**AC-AC-19: Currency ledger is append-only.**
Given any direct SQL `UPDATE` or `DELETE` on `currency_ledger`. When query executes. Then rejected by database constraint or RLS policy; no existing ledger entry modified.

**AC-AC-20: Admin grant requires elevated JWT role.**
Given JWT with standard player role. When grant endpoint called with `source: ADMIN_GRANT`. Then request rejected with 403; no currency granted.

**AC-AC-21: MMR trajectory anomaly flags boosting.**
Given player's `mmrGainRate > MMR_GAIN_ANOMALY_PER_DAY = 150` over 7 days. When anomaly job runs. Then `moderation_signals` row inserted with `signalType: MMR_TRAJECTORY`.

**AC-AC-22: Jailbreak detection does not block play.**
Given `isJailbroken = true` detected via expo-device. When player connects. Then connection proceeds normally; `clientIntegrityFlags.isJailbroken = true` logged at INFO; no ban triggered.

**AC-AC-23: Emulator detection does not block play.**
Given `isDevice = false` detected. When player connects. Then connection proceeds normally; flag logged at INFO.

**AC-AC-24: FatalCheatEvidence is logged with full context.**
Given any FATAL detection. When FATAL log emitted. Then log contains `userId`, `matchId`, `detectionType`, `observedValue`, `threshold`, `tickNumber`, `rawInputSnapshot`; no PII beyond userId UUID.

**AC-AC-25: Certificate rotation maintains continuity.**
Given new cert hash added to `CERT_PIN_HASH` alongside old hash. When app update ships with new hash only. Then connections with new cert succeed; connections with old cert rejected only after old hash removed from config (after `CERT_ROTATION_OVERLAP_DAYS`).

**AC-AC-26: Aim anomaly reference table is per-MMR-bracket.**
Given player at MMR 1800 (Diamond bracket). When aim anomaly evaluated. Then comparison uses Diamond bracket reference data, not global average.

**AC-AC-27: FATAL evidence stored for audit.**
Given FATAL detection fired. When auto-suspension processed. Then `FatalCheatEvidence` record persisted in `moderation_actions` table linked to the `moderation_signals` row; retained for 90 days (per Logging/Monitoring retention policy for ERROR/FATAL level).

**AC-AC-28: cheat_detected analytics event fires on FATAL.**
Given FATAL log emitted. When processed. Then Tier 0 `cheat_detected` analytics event fires with `detectionType`, `userId`, `matchId`.

**AC-AC-29: Input validation completes within 3ms budget.**
Given worst-case tick with all players at `MAX_INPUTS_PER_TICK`. When Validation phase runs. Then total validation time < 3ms measured in performance test environment (single-server, 8-player FFA match simulation).

**AC-AC-30: Server-authoritative state not affected by fabricated client inputs.**
Given a client that sends arbitrary position, damage, and ability values. When match simulates. Then game state computed purely from server physics and ability definitions; no fabricated value affects authoritative HP, position, or win condition.
