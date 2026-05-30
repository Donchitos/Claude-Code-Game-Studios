# Remote Config / Live Tuning — Game Design Document

> **System**: Remote Config / Live Tuning
> **Priority**: VS (designed early in Block 2; implemented in Vertical Slice)
> **Layer**: Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

> **Quick reference** — Layer: `Infrastructure` · Priority: `Vertical Slice` · Key deps: `API Client, Authentication, Real-time Transport (Socket.io)`

---

## 1. Overview

Remote Config / Live Tuning is a centralized, server-managed key-value store of runtime-tunable game parameters that every downstream system reads instead of relying on hardcoded constants. The system owns the full lifecycle of a config value: definition (key, type, default), fetch (blocking at app launch via `GET /v1/config`), local persistence (AsyncStorage cache), hot distribution (Socket.io `config_update` event for mid-session pushes), and version compatibility enforcement. It is the primary operational lever that lets the live team change game behavior — balance multipliers, event availability, matchmaking rules, ad frequency, feature flags — without a client app-store update. For a mobile live-service brawler where the store review cycle takes 24–72 hours, this system is the difference between fixing a broken meta in an afternoon and waiting three days.

---

## 2. Player Fantasy

Players never see the Remote Config system directly, but they feel its effects constantly.

**For the live player:** A character that dominated the meta yesterday feels slightly more balanced today — not because of a week-long patch cycle, but because the live team pushed a balance overlay overnight. A weekend event appears on Saturday morning; an unplanned outage kills a specific game mode within seconds of the engineer flipping a flag. Players experience a game that is alive, responsive, and actively maintained.

**For the competitive player:** MMR K-factor adjustments tighten skill brackets during ranked season without requiring a restart. Queue timeout tuning eliminates the frustration of staring at a spinner for 90 seconds when population is thin at 3 AM.

**For the new player:** Tutorial flags can be toggled off for QA and beta testers without shipping a build. The onboarding team can A/B test tutorial flow variants to find which path produces the highest day-3 retention, then promote the winner without touching the codebase.

**For the monetization health of the game:** Ad frequency caps prevent interstitial fatigue from burning out free players — the live team can tune the cap in response to churn signals within minutes of reading the analytics dashboard.

The fantasy Remote Config enables is a game that never feels abandoned: it updates, it responds to problems, it experiments, and it improves — all without asking the player to download a patch.

---

## 3. Detailed Rules

### 3.1 Config Key Registry

Every key in this table is the authoritative source of truth for that parameter. Downstream GDDs MUST reference this table when citing a tunable value. The "Hot" column denotes whether the server may push the value to a connected client mid-session without requiring an app restart (see section 3.3).

| Key | Type | Default Value | Hot | Cold | Owning System | Description |
|-----|------|--------------|-----|------|--------------|-------------|
| `matchmaking.soloQueueEnabled` | `boolean` | `true` | — | Cold | Matchmaking Engine | Enables or disables the solo queue entry point. Disable to force party-only queuing or during server maintenance. |
| `matchmaking.mmrKFactorProvisional` | `number` | `32` | — | Cold | MMR / Ranked System | Elo K-factor applied to players in their provisional period (`provisional_match_count < 30`). Higher value produces faster initial placement convergence. Applied at match-result calculation time; changing mid-season affects next match only. |
| `matchmaking.mmrKFactorEstablished` | `number` | `16` | — | Cold | MMR / Ranked System | Elo K-factor applied to established players (`provisional_match_count ≥ 30`). Lower value stabilizes the ranked ladder. Applied at match-result calculation time; changing mid-season affects next match only. |
| `matchmaking.queueTimeoutSec` | `number` | `60` | Hot | — | Matchmaking Engine | Seconds before the matchmaker widens skill bracket or falls back to bot fill. Range: 15–120. |
| `matchmaking.botFillEnabled` | `boolean` | `true` | Hot | — | Matchmaking Engine | Whether thin-queue matches may be filled with Bot / Fallback AI opponents. |
| `matchmaking.maxSkillSpreadMMR` | `number` | `300` | — | Cold | Matchmaking Engine | Maximum MMR delta allowed between the highest- and lowest-skill players in a match before matchmaker widens brackets. |
| `character.balanceMultipliers` | `object` | `{}` (no overrides) | — | Cold | Character System | Per-character stat modifier map. Keys are `characterId` strings; values are objects with optional fields: `healthMult` (float), `damageMult` (float), `speedMult` (float). Multipliers are applied on top of base stats at character load. Missing keys mean no override (multiplier of 1.0). Example: `{"character:dash": {"damageMult": 0.92}}` |
| `character.maxAbilitySlots` | `number` | `2` | — | Cold | Character System | Maximum ability slots per character loadout. Changing mid-session is not permitted (Cold). |
| `gameMode.availableModes` | `string[]` | `["duel_1v1","squad_3v3","ffa_8"]` | Hot | — | Game Mode System | Array of mode IDs currently enabled for matchmaking entry. Remove an ID to disable that mode within seconds without a deploy. |
| `gameMode.eventModeActive` | `boolean` | `false` | Hot | — | Game Mode System | Whether a limited-time event mode is running. When `true`, the event mode entry point is visible and queueable. |
| `gameMode.eventModeId` | `string` | `""` | Hot | — | Game Mode System | The mode ID of the currently active event mode (only meaningful when `eventModeActive` is `true`). |
| `gameMode.matchDurationCapSec` | `number` | `600` | — | Cold | Game Mode System | Server-enforced match duration ceiling in seconds. Matches that exceed this are force-ended via sudden death or draw resolution rules. Must match server-side constant; changes require coordinated server + config deploy. |
| `ads.interstitialFrequencyCap` | `number` | `3` | Hot | — | Ad System | Minimum number of completed matches between interstitial ad impressions for a given session. Lower values increase ad revenue but risk session abandonment. |
| `ads.rewardedAdEnabled` | `boolean` | `true` | Hot | — | Ad System | Whether rewarded ad placements are shown. Disable to suppress during ad network outages. |
| `ads.adsEnabledForNewAccounts` | `boolean` | `true` | — | Cold | Ad System | Whether ads are shown to accounts created within the past N days (defined by `ads.newAccountGraceDays`). |
| `ads.newAccountGraceDays` | `number` | `3` | — | Cold | Ad System | Number of days after account creation during which interstitial ads are suppressed. |
| `onboarding.tutorialEnabled` | `boolean` | `true` | — | Cold | Tutorial / Onboarding | Master switch for the tutorial flow. Set `false` to bypass for QA testers and internal builds. Does not affect players who have already completed the tutorial. |
| `onboarding.forceTutorialForNewAccounts` | `boolean` | `true` | — | Cold | Tutorial / Onboarding | Whether new accounts are routed to tutorial before first match. Set `false` to skip for closed beta. |
| `featureFlags.partyQueueEnabled` | `boolean` | `false` | — | Cold | Party / Presence System | Gates the party queue UI and server-side party formation. Flip `true` to enable in VS milestone. |
| `featureFlags.reconnectEnabled` | `boolean` | `false` | — | Cold | Reconnect / Resume System | Gates mid-match reconnect flow. Flip `true` when Reconnect / Resume System is fully implemented. |
| `featureFlags.leaderboardEnabled` | `boolean` | `false` | — | Cold | UI / Social | Feature flag for the global leaderboard screen. |
| `featureFlags.shopEnabled` | `boolean` | `false` | — | Cold | Shop & Offers Screen | Feature flag for the shop tab. Enable in Alpha when economy is ready. |
| `featureFlags.battlePassEnabled` | `boolean` | `false` | — | Cold | Battle Pass / Play Pass | Feature flag for Battle Pass tab. Enable in Alpha when Battle Pass GDD is implemented. |
| `featureFlags.socialEnabled` | `boolean` | `false` | — | Cold | Party / Presence System | Gates all social features (friend list, party invite). |
| `server.maintenanceModeEnabled` | `boolean` | `false` | Hot | — | Infrastructure | When `true`, the client shows a maintenance banner and disables all queue entry points. Pushed via hot config during planned or emergency maintenance windows. |
| `server.minClientVersion` | `string` | `"1.0.0"` | — | Cold | Infrastructure | Minimum acceptable semver client version. Clients below this are shown a force-update prompt and cannot proceed. |
| `session.maxConcurrentMatchesPerPlayer` | `number` | `1` | — | Cold | Session Manager | Maximum active matches a single player account may be enrolled in simultaneously. |

### 3.2 Fetch Lifecycle

The fetch lifecycle governs how config values arrive on the client and how failures are handled. The sequence is strictly ordered:

```
App Launch
    │
    ▼
[1] Read AsyncStorage cache
    │   → If found: hold as "stale fallback"
    │   → If not found: use hardcoded defaults as fallback
    │
    ▼
[2] Auth token available?
    │   → Wait for Authentication to resolve (JWT must be present for
    │     segment targeting; anonymous fetch allowed if auth unavailable
    │     — server falls back to default segment)
    │
    ▼
[3] GET /v1/config?schema_version={CLIENT_SCHEMA_VERSION}
    │   with Authorization: Bearer {jwt}
    │
    ├── 200 OK → parse response JSON
    │       │
    │       ├── schema_version compatible?
    │       │       YES → store as active config
    │       │             write to AsyncStorage (update cache)
    │       │             resolve "config ready" gate
    │       │       NO  → see Edge Case 5.1 (config_incompatible)
    │       │
    │       └── validation pass? (all values match declared types)
    │               YES → proceed
    │               NO  → log warning, fall back to stale cache or defaults
    │                     (partial validation failure: use per-key fallback)
    │
    ├── Network error / timeout → retry with exponential backoff (see §4.2)
    │       │
    │       └── Retries exhausted → use stale AsyncStorage cache if present,
    │                                else use hardcoded defaults
    │                                resolve "config ready" gate with fallback
    │
    └── 4xx / 5xx → treat as unreachable; fall back per above
    
    ▼
[4] "Config ready" gate resolved
    Main menu renders
    All downstream systems initialize (reading from active config)
```

**The Main Menu is blocked from rendering until the "config ready" gate is resolved.** The gate always resolves (via fallback if necessary) — it never hangs indefinitely. The maximum time-to-gate-resolve is bounded by: `fetchTimeoutMs + (maxRetryAttempts * maxBackoffMs)`, defined in §7.

### 3.3 Cold vs. Hot Key Distinction

**Cold keys** apply only on the next app launch. If a cold key is updated on the server and pushed via a Socket.io event, the client MUST ignore the push for that key. The new value will be picked up when the player next opens the app (and a fresh fetch succeeds). Cold keys are safer for parameters that affect initialization-time state (character stat tables, slot counts, tutorial routing) where mid-session application would create inconsistent state.

**Hot keys** may be applied immediately to a running session without restart. The client listens for `config_update` Socket.io events (see §3.4). Hot keys are constrained to parameters where mid-session change is safe: mode availability, queue timeouts, ad frequency, maintenance flags, and event state.

**Classification rule for new keys:** A key is Hot if and only if all of the following hold:
1. Applying the new value mid-session produces no inconsistent game state.
2. The owning system exposes a runtime update method (not just a constructor parameter).
3. The parameter controls external/meta behavior (queue rules, UI availability, ad pacing) — not in-match simulation state.

**All in-match simulation parameters (character stats, damage, speed, health) are Cold.** Balance overlay changes via `character.balanceMultipliers` take effect on the next match load, not within an active match.

### 3.4 Hot Config Push via Socket.io

When the server needs to push updated values for one or more Hot keys to all connected clients, it emits a `config_update` Socket.io event.

**Event name:** `config_update`

**Payload schema:**
```json
{
  "schema_version": 1,
  "keys": {
    "matchmaking.queueTimeoutSec": 45,
    "gameMode.availableModes": ["duel_1v1", "squad_3v3"],
    "server.maintenanceModeEnabled": false
  }
}
```

**Client handling rules:**
1. Verify `schema_version` in the payload matches the client's declared schema version. If mismatched, discard the push and log a warning. Do not apply partial updates from an incompatible schema push.
2. For each key in `keys`:
   a. If the key is classified as Cold, discard the value for that key and log a warning (`"hot_push_cold_key_ignored"`).
   b. If the value type does not match the declared type for that key, discard and log a warning (`"hot_push_type_mismatch"`).
   c. Otherwise, apply the value to the active config immediately.
3. After applying all valid hot values, write the updated config to AsyncStorage.
4. Notify all downstream systems that subscribed to those keys via the Config Change event (see §6).
5. Debounce rapid successive pushes: if a second `config_update` arrives within `hotPushDebounceMs` of the previous one, queue it and apply after the debounce window expires (see §7).

**Hot keys list** (all other keys are Cold):

| Hot Key | Rationale |
|---------|-----------|
| `matchmaking.queueTimeoutSec` | Safe to change queue search behavior immediately |
| `matchmaking.botFillEnabled` | Safe to enable/disable bot fill mid-session |
| `gameMode.availableModes` | Mode list affects queue entry; safe to apply before next queue attempt |
| `gameMode.eventModeActive` | Event banner/entry point can appear/disappear safely |
| `gameMode.eventModeId` | Companion to eventModeActive; no in-match state impact |
| `ads.interstitialFrequencyCap` | Ad pacing affects next match-result screen, not current match |
| `ads.rewardedAdEnabled` | Ad placement suppression; no in-match impact |
| `server.maintenanceModeEnabled` | Emergency use; must propagate instantly to all clients |

### 3.5 A/B Experiment Model

The Remote Config system supports server-side A/B experiments that assign players to named buckets and return bucket-specific config values.

**Experiment structure:**
```
Experiment
├── name: string (e.g., "tutorial_flow_v2")
├── buckets: string[] (e.g., ["control", "variant_a", "variant_b"])
├── allocation: number[] (e.g., [0.5, 0.25, 0.25]) — must sum to 1.0
└── overrides: { [bucketName]: { [configKey]: value } }
```

**Assignment rules:**
- Assignment is **server-side** and **stable per userId**. The server computes the bucket using a deterministic hash of `(userId, experimentName)` mapped into the allocation ranges. The same player always gets the same bucket for a given experiment.
- The server includes the player's experiment assignments in the config response:
  ```json
  {
    "experiments": {
      "tutorial_flow_v2": "variant_a",
      "mmr_kfactor_test": "control"
    }
  }
  ```
- The client stores experiment assignments alongside config values. Assignments are read-only on the client — the client never computes or overrides its own bucket.
- **Assignment is frozen at session start.** If an experiment's allocation changes on the server after the player has launched the app, the player retains their original assignment for the current session. The new assignment takes effect on the next app launch and fresh config fetch. See Edge Case 5.4.

**How systems read experiment-overridden values:**
Systems call the standard config read API: `configService.get("matchmaking.mmrKFactorProvisional")` or `configService.get("matchmaking.mmrKFactorEstablished")`. The config service applies override priority internally (see §3.7) and returns the experiment-bucket value if applicable. Systems do not need to know about experiments; they just read keys.

**Experiment lifecycle:**
1. Engineer defines experiment on server with name, buckets, allocation, and overrides.
2. Server assigns bucket to each player on their next config fetch.
3. Analytics events automatically include active experiment bucket assignments (injected by config service before emitting).
4. To conclude experiment: promote winning variant to global default, or roll back to control. Remove experiment definition from server. On next player fetch, no experiment assignment is present; players read global default.

### 3.6 Config Schema Version

The config system uses an integer schema version to detect breaking changes between client expectations and server-provided values.

**Versioning rules:**
- The client declares `CLIENT_SCHEMA_VERSION` as a compile-time constant (e.g., `1`).
- Every config fetch includes `?schema_version=1` as a query parameter.
- The server stores the minimum compatible client schema version (`minCompatibleSchemaVersion`) and the current schema version (`currentSchemaVersion`).
- **Compatible response:** If `CLIENT_SCHEMA_VERSION >= minCompatibleSchemaVersion`, the server returns config values. The response includes a `schema_version` field equal to `currentSchemaVersion`.
- **Incompatible response:** If `CLIENT_SCHEMA_VERSION < minCompatibleSchemaVersion`, the server returns HTTP 409 with body:
  ```json
  {
    "error": "config_incompatible",
    "min_required_version": "2.1.0",
    "store_url_ios": "https://apps.apple.com/...",
    "store_url_android": "https://play.google.com/..."
  }
  ```
- On receiving `config_incompatible`, the client displays the force-update prompt (see Edge Case 5.2) and does not proceed to the main menu.

**Schema version increment rule:** Increment `minCompatibleSchemaVersion` only when a new key is added that a missing default would cause a crash or severe gameplay defect. Adding optional keys with safe defaults does not require a version bump. Renaming or removing a key always requires a bump.

### 3.7 Segment Targeting

The server may return different config values to different player segments. Segments are evaluated server-side only — the client has no knowledge of segment logic.

**Player attributes used for segmentation** (derived from JWT + server-side profile lookup):
- `platform`: `"ios"` | `"android"`
- `os_version`: semver string (e.g., `"17.4"`)
- `mmr`: current matchmaking rating (integer)
- `account_age_days`: days since account creation
- `beta_cohort`: boolean — whether player is in the closed beta group
- `client_version`: semver string from the app bundle

**Server-side evaluation order:**
1. Find all segment rules that match the player's attributes (multiple rules can match).
2. For each config key, select the value from the highest-priority matching segment rule. Segment rule priority is an explicit integer field set by the live team.
3. If no segment rule matches for a key, use the global default.

**Example segment rules (illustrative, not exhaustive):**
- iOS 17+ players: override `ads.interstitialFrequencyCap = 4` (iOS 17 SKAdNetwork limits require less-frequent ads for attribution accuracy).
- MMR > 1500 players: override `matchmaking.mmrKFactorEstablished = 16` (experienced players receive lower K-factor for rank stability).
- Beta cohort players: override `featureFlags.reconnectEnabled = true` (early access to reconnect feature).

**The client never receives segment rule logic** — it only receives the resolved config values appropriate for that player. This prevents reverse-engineering of segment criteria.

### 3.8 Override Priority

When multiple sources provide a value for the same config key, the following priority chain is applied (highest to lowest):

```
1. Experiment bucket override
      (player is assigned to a named experiment that overrides this key)
2. Segment override
      (a server-side segment rule matched this player and overrides this key)
3. Global default
      (the base value defined for all players with no overrides)
4. Hardcoded client default
      (the fallback value compiled into the client binary — used only when
       the server is unreachable and no AsyncStorage cache exists)
```

The config service resolves this priority chain server-side before sending the response. The client receives a single flat resolved value per key. The client does not store or evaluate the priority chain — only the server does.

**Exception:** The client must independently implement the fallback chain for the scenario where no server response is available (see §3.2, step 3 failure path): AsyncStorage cache (which contains the last server-resolved values, including any experiment/segment overrides that were active at last successful fetch) takes priority over hardcoded defaults.

---

## 4. Formulas

### 4.1 A/B Bucket Assignment (Server-Side, Stable Per userId)

The server assigns a player to an experiment bucket using a deterministic hash. The same input always produces the same output, ensuring assignment stability across sessions.

```
bucketIndex = floor( (hash(userId + ":" + experimentName) mod HASH_MODULUS) / HASH_MODULUS * bucketCount )
```

Where:

| Variable | Type | Value | Description |
|----------|------|-------|-------------|
| `userId` | `string` | UUID | Player's permanent Supabase user ID |
| `experimentName` | `string` | e.g., `"tutorial_flow_v2"` | Unique experiment identifier |
| `hash(x)` | `function` | FNV-1a 32-bit or xxHash32 | Deterministic non-cryptographic hash. Must produce uniform distribution across the userId space. |
| `HASH_MODULUS` | `integer` | `10000` | Fixed modulus. Yields 0–9999 range, allowing up to 0.01% allocation granularity. |
| `bucketCount` | `integer` | Number of buckets in experiment | e.g., 3 for `[control, variant_a, variant_b]` |
| `bucketIndex` | `integer` | 0 to `bucketCount - 1` | Index into the ordered bucket array |

**Allocation mapping example** — experiment with allocation `[0.5, 0.25, 0.25]` and `HASH_MODULUS = 10000`:
- Hash result 0–4999 → `control` (50%)
- Hash result 5000–7499 → `variant_a` (25%)
- Hash result 7500–9999 → `variant_b` (25%)

**Expected distribution**: With a uniform hash, 50% of players fall in `control`, 25% in each variant. Verify distribution after 1,000+ assignments using chi-squared test during experiment setup.

**Edge case**: If `bucketCount` is 0 or negative, return `"control"` as a safe fallback and log an error. Never throw or crash.

### 4.2 Config Fetch Retry Backoff

When the initial config fetch fails (network error, timeout, 5xx), the client retries with exponential backoff and jitter to prevent thundering-herd reconnects.

```
waitMs(attempt) = min(
    BASE_DELAY_MS * (2 ^ attempt) + jitter(MAX_JITTER_MS),
    MAX_BACKOFF_MS
)
```

Where:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `attempt` | `integer` | 0-indexed attempt number | 0 = first retry |
| `BASE_DELAY_MS` | `number` | `500` | Initial retry delay in milliseconds |
| `MAX_JITTER_MS` | `number` | `500` | Maximum random jitter added to each retry delay |
| `MAX_BACKOFF_MS` | `number` | `8000` | Hard ceiling on any single retry wait |
| `jitter(max)` | `function` | `floor(random() * max)` | Uniform random value in `[0, max)` |
| `maxRetryAttempts` | `integer` | `3` | Maximum number of retries before giving up (see §7) |

**Example retry schedule** (no jitter, for illustration):

| Attempt | Wait Before This Attempt |
|---------|--------------------------|
| 0 (initial) | 0ms |
| 1 (first retry) | 500ms |
| 2 (second retry) | 1000ms |
| 3 (third retry) | 2000ms |
| — Retries exhausted — | Fall back to cache/defaults |

**After `maxRetryAttempts` retries are exhausted**, the fallback chain (AsyncStorage cache → hardcoded defaults) is invoked and the "config ready" gate is resolved immediately, allowing the app to continue.

---

## 5. Edge Cases

| # | Scenario | Expected Behavior | Rationale |
|---|----------|------------------|-----------|
| 5.1 | **Config server unreachable at launch** | Retry with exponential backoff (§4.2). After `maxRetryAttempts` retries, load stale AsyncStorage cache if present. If no cache exists (first ever launch), load hardcoded defaults. Resolve "config ready" gate. Display a subtle non-blocking toast: "Playing with cached settings — check your connection." Do NOT block the main menu indefinitely. | Blocking indefinitely on config makes the app unusable on bad connections. Hardcoded defaults are designed to be safe and playable. Cache is always written after a successful fetch. |
| 5.2 | **Config response returns `config_incompatible` (schema version too old)** | Display force-update modal with store deep-link. Modal is non-dismissible (no "X" button, back gesture blocked). All queue entry points and navigation are disabled. The modal remains until the player updates or kills the app. | Running an incompatible client against a forward-migrated server produces undefined behavior. Force-update is the only safe path. |
| 5.3 | **Cached config is stale (version mismatch in cache)** | AsyncStorage cache stores the `schema_version` alongside config values. On cache read, if `cachedSchemaVersion < CLIENT_SCHEMA_VERSION`, discard the cache and fall back to hardcoded defaults. Attempt a fresh fetch as normal. | A cache from a previous app version may contain keys that no longer exist or types that have changed. Discarding and falling back to hardcoded defaults is safer than attempting to merge or interpret a structurally different cache. |
| 5.4 | **Hot key pushed with invalid type** | Discard the value for that key. Log a structured warning: `{ event: "hot_push_type_mismatch", key: "ads.interstitialFrequencyCap", expected: "number", received: "string", value: "unlimited" }`. Retain the previously active value for that key. Do not apply the partial push to other valid keys in the same event. | Type-mismatched pushes are likely server-side bugs. Failing silently and retaining the last known-good value prevents the client from entering an invalid state. Logging enables fast diagnosis. |
| 5.5 | **Experiment assignment changes mid-session (server re-rolls allocation)** | The client does not poll for experiment assignment changes during a session. The assignment fetched at app launch is frozen for the entire session. If the server re-rolls allocations (e.g., from 50/50 to 70/30), the new allocation takes effect for this player only on their next app launch and fresh config fetch. No mid-session notification or update is issued. | Mid-session assignment changes create inconsistent game-state experiences (e.g., a player starts the session with `variant_a` MMR K-factor and finishes with `control`). Stability per session is required for valid A/B measurement. |
| 5.6 | **Force-update required but player ignores prompt** | The force-update modal (§5.2) is non-dismissible. The player cannot access any game feature until they update. If the player kills and relaunches the app without updating, `config_incompatible` will be returned again and the modal will reappear. If the config server itself is also unreachable (combined failure), the client falls back to hardcoded defaults and proceeds — the `config_incompatible` error requires a valid server response to trigger. | A player who cannot dismiss the prompt has no game access — which is acceptable, because running an incompatible client is worse. The combined-failure escape (server unreachable + schema mismatch) is handled by the unreachable fallback path, which uses hardcoded defaults and bypasses the version check entirely. |
| 5.7 | **Cold key included in a `config_update` hot push** | The client detects that the key is marked Cold in its type registry, discards the value for that key, and logs a warning: `{ event: "hot_push_cold_key_ignored", key: "character.balanceMultipliers" }`. The push is not applied for that key. Other Hot keys in the same payload are applied normally. | Cold keys were classified Cold because applying them mid-session is unsafe. Discarding is the only safe behavior. Logging notifies the live team of a mis-configured push. |
| 5.8 | **Config fetch succeeds but response body fails JSON parse** | Treat as a network error. Retry per §4.2. If all retries fail, fall back to cache/defaults. Log: `{ event: "config_parse_error", error: "SyntaxError at offset 42" }`. | A malformed response body indicates a server-side serialization failure. It is indistinguishable from a network corruption event — the same fallback path applies. |
| 5.9 | **Player is mid-match when `server.maintenanceModeEnabled` is pushed to `true`** | The client receives the `config_update` hot push. The maintenance banner is shown on HUD overlay but the current match is NOT terminated client-side. The match server handles its own shutdown sequencing. The client disables queue re-entry after the current match ends. The player can finish their current match. | Abruptly killing an active match client-side creates a worse experience than letting it complete. The match server issues its own graceful shutdown. The client's role is to prevent new matches from starting. |
| 5.10 | **AsyncStorage write fails after successful config fetch** | Apply the fetched config as the active in-memory config (the session proceeds normally). Log the write failure. Do not block or retry — the next session will fetch fresh config from the server. | Persistent storage write failures on mobile are rare and usually transient. The cost is one session without a persistent cache, which is acceptable. Blocking on a write failure would punish the player for a storage issue outside the game's control. |

---

## 6. Dependencies

### 6.1 Upstream Dependencies (what Remote Config requires)

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| API Client | Remote Config depends on API Client | Config is fetched via `GET /v1/config` using the API Client's HTTP transport, retry wrapper, and auth header injection |
| Authentication | Remote Config depends on Authentication | JWT is required in the `Authorization` header for the server to evaluate segment targeting. Config fetch may proceed without JWT (anonymous fetch) but receives only global defaults with no segment overrides |
| Real-time Transport (Socket.io) | Remote Config depends on Real-time Transport | Hot config pushes are received via `config_update` Socket.io events. Remote Config subscribes to this event through the Real-time Transport's event bus |

### 6.2 Downstream Dependencies (systems that consume Remote Config values)

| System | Direction | Keys Consumed | Nature |
|--------|-----------|--------------|--------|
| Matchmaking Engine | Matchmaking depends on Remote Config | `matchmaking.soloQueueEnabled`, `matchmaking.mmrKFactorProvisional`, `matchmaking.mmrKFactorEstablished`, `matchmaking.queueTimeoutSec`, `matchmaking.botFillEnabled`, `matchmaking.maxSkillSpreadMMR` | Rule dependency — matchmaking queue rules, bot fill threshold, and skill bracket width are read from config at queue-start time |
| MMR / Ranked System | MMR depends on Remote Config | `matchmaking.mmrKFactorProvisional`, `matchmaking.mmrKFactorEstablished` | Data dependency — K-factors are read from config at match-result calculation time |
| Character System | Character depends on Remote Config | `character.balanceMultipliers`, `character.maxAbilitySlots` | Data dependency — balance overlays are applied to character base stats at character load time |
| Game Mode System | Game Mode depends on Remote Config | `gameMode.availableModes`, `gameMode.eventModeActive`, `gameMode.eventModeId`, `gameMode.matchDurationCapSec` | Rule dependency — available modes list gates queue entry; event mode flag controls event entry point; duration cap is passed to match server |
| Tutorial / Onboarding | Tutorial depends on Remote Config | `onboarding.tutorialEnabled`, `onboarding.forceTutorialForNewAccounts` | Rule dependency — tutorial routing gates depend on these flags |
| Ad System | Ad System depends on Remote Config | `ads.interstitialFrequencyCap`, `ads.rewardedAdEnabled`, `ads.adsEnabledForNewAccounts`, `ads.newAccountGraceDays` | Rule dependency — interstitial pacing and ad placement visibility are driven by these values |
| Settings & Accessibility | Settings depends on Remote Config | `featureFlags.*` (arbitrary feature flags) | Rule dependency — feature flag values control whether experimental settings options are visible |
| Party / Presence System | Party depends on Remote Config | `featureFlags.partyQueueEnabled`, `featureFlags.socialEnabled` | Rule dependency — party formation UI is gated behind feature flags |
| Reconnect / Resume System | Reconnect depends on Remote Config | `featureFlags.reconnectEnabled` | Rule dependency — reconnect flow is gated behind feature flag |
| Shop & Offers Screen | Shop depends on Remote Config | `featureFlags.shopEnabled` | Rule dependency — shop tab visibility |
| Battle Pass / Play Pass | Battle Pass depends on Remote Config | `featureFlags.battlePassEnabled` | Rule dependency — battle pass tab visibility |

### 6.3 Config Change Notification Interface

Downstream systems that need to react immediately to Hot key changes MUST register a change listener with the config service rather than polling:

```typescript
// Example subscription interface (not normative — see API Client / architecture GDD)
configService.subscribe("gameMode.availableModes", (newValue: string[]) => {
  gameModeSystem.updateAvailableModes(newValue);
});
```

Systems that only read config at initialization time (Cold keys) do not need to subscribe — they call `configService.get(key)` once during their own initialization.

---

## 7. Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `cacheTTLMs` | No explicit TTL (cache is "stale if older than one session" — refresh on every launch) | N/A — replaced by per-launch fetch | Longer TTL reduces server load but risks serving stale config longer after a hot fix | Shorter TTL increases server fetch frequency |
| `fetchTimeoutMs` | `5000` (5 seconds) | `2000`–`10000` | More tolerance for slow connections; users on 2G wait longer before seeing the main menu | Faster fail-over to cache/defaults; main menu appears sooner on bad connections but may miss a valid slow response |
| `maxRetryAttempts` | `3` | `1`–`5` | More retries means more attempts to reach a live config server before falling back; increases time-to-main-menu on total failures | Fewer retries means faster fallback to cache/defaults at the cost of potentially missing a transiently available server |
| `hotPushDebounceMs` | `250` | `100`–`1000` | Prevents a burst of rapid config pushes from triggering excessive downstream system updates; higher value means more lag between push and application | Lower debounce means pushes are applied faster; risk of rapid successive notifications causing UI flicker |
| `configFetchOnForegroundMs` | `300000` (5 minutes) | `60000`–`1800000` | Longer interval means fewer background refreshes; config stays stale longer if the player leaves the app open for hours | Shorter interval means fresher config at the cost of more background network requests |

**`configFetchOnForegroundMs`** — When the app returns to the foreground after being backgrounded for more than this duration, a background config refresh is triggered (non-blocking — does not show a loading screen). This ensures long-lived sessions do not run with very stale config.

**Cache invalidation:** The AsyncStorage cache does not have a TTL in the traditional sense — it is invalidated by schema version mismatch (see §5.3) and refreshed on every successful launch fetch. The cache exists purely as an offline fallback, not as a performance optimization.

---

## 8. Acceptance Criteria

### Launch Behavior
- [ ] On first app launch with a reachable config server, the main menu does not render until a successful config response has been parsed and stored. Time from launch to main menu render does not exceed `fetchTimeoutMs + (maxRetryAttempts × MAX_BACKOFF_MS)` under simulated network failure.
- [ ] On first app launch with an unreachable config server and no existing cache, the app falls back to hardcoded defaults and renders the main menu without crashing. All gameplay systems initialize without runtime errors using hardcoded defaults.
- [ ] On launch with an existing AsyncStorage cache and an unreachable server, the app uses the cached values and renders the main menu. The cache values are verified as the active config values read by at least one downstream system.
- [ ] On launch with an existing cache that has a `schema_version` lower than `CLIENT_SCHEMA_VERSION`, the cache is discarded and hardcoded defaults are used.

### Version Compatibility
- [ ] A client sending `schema_version=1` to a server that has set `minCompatibleSchemaVersion=2` receives a 409 `config_incompatible` response.
- [ ] On receiving `config_incompatible`, the force-update modal appears and no navigation away from it is possible (back gesture, Android back button, and swipe-to-dismiss are all blocked).
- [ ] If both `config_incompatible` and network unreachable occur simultaneously (e.g., server is returning 409 but then goes down), the client falls back to hardcoded defaults and proceeds to the main menu without showing the force-update modal. The `config_incompatible` path requires a valid server response.

### Hot Config Push
- [ ] When a `config_update` Socket.io event is received with valid keys, the active config values for those keys are updated within `hotPushDebounceMs + 50ms` of event receipt.
- [ ] When a `config_update` event includes a Cold key, that key's value is not updated in the active config. A warning log entry with `event: "hot_push_cold_key_ignored"` is present.
- [ ] When a `config_update` event includes a key with a type-mismatched value, that key's value is not updated. A warning log entry with `event: "hot_push_type_mismatch"` is present.
- [ ] Setting `server.maintenanceModeEnabled = true` via hot push results in the maintenance banner appearing in the client UI within `hotPushDebounceMs + 50ms`. Queue entry points become disabled. Any in-progress match is not terminated client-side.
- [ ] Setting `gameMode.availableModes` via hot push to remove a mode results in the corresponding queue entry point becoming unavailable before the next match can be queued.

### A/B Experiments
- [ ] Two test accounts with different userIds assigned to an active experiment receive stable, consistent bucket assignments across 10 consecutive app launches each (same bucket every launch).
- [ ] A player's experiment assignment does not change during an active session even if server allocation is modified mid-session.
- [ ] A system reading `configService.get("matchmaking.mmrKFactorProvisional")` or `configService.get("matchmaking.mmrKFactorEstablished")` for a player in the `variant_a` bucket of a `mmrKFactor` experiment receives the `variant_a` override value, not the global default.
- [ ] Experiment assignment is absent from the config response for experiments the player is not enrolled in. The system reads the global default for those keys.

### Segment Targeting
- [ ] A test account with MMR > 1500 receives `matchmaking.mmrKFactorEstablished = 16` when the server has a segment rule overriding that value. A test account with MMR < 1500 receives the global default.
- [ ] Segment override values are stored in the AsyncStorage cache alongside experiment-overridden values so that the correct per-player values are used as the fallback even when the server is unreachable on the subsequent launch.

### Downstream System Isolation
- [ ] All config keys listed in the registry (§3.1) have a hardcoded default value defined in the client source. No key has `undefined` or `null` as its hardcoded default.
- [ ] Every downstream system in §6.2 initializes successfully using hardcoded defaults alone (verified by running the app with config server blocked and no AsyncStorage cache present).
- [ ] No downstream system reads a config key that is not listed in the registry. Unlisted keys are a build-time lint error.

### Performance
- [ ] Config fetch, parse, and AsyncStorage write completes within 200ms on a fast connection (Wi-Fi, <10ms RTT).
- [ ] Config service `get(key)` call completes in under 1ms (synchronous in-memory read after initialization).
- [ ] Hot push handling (receive event, validate, apply, notify subscribers, write AsyncStorage) completes within `hotPushDebounceMs + 100ms`.
