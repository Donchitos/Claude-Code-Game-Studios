# Game Mode System — Game Design Document
> **System**: Game Mode System
> **Priority**: MVP
> **Layer**: Compound Features
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

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

The Game Mode System is the authoritative source of truth for what a match *is* — its rules, player structure, win conditions, scoring, and time boundaries. It sits at the intersection of nearly every other system in BRAWLZONE, translating static mode definitions from the Content Catalog into live match behavior registered with the Match Server.

### What the Game Mode System Owns

| Responsibility | Description |
|---|---|
| **Mode Definitions** | Static config records loaded from Content Catalog at startup and kept warm in memory. Each record defines player counts, team structure, map pool, win condition type, tiebreaker rule, scoring rules, and duration cap. |
| **Win Condition Evaluators** | A typed `WinConditionEvaluator` function per mode, registered with Match Server on server init. Called every server tick (20 Hz); returns match-over verdict when conditions are satisfied. |
| **Mode Availability Gating** | Reads `gameMode.availableModes` from Remote Config on match-start request and on hot-push event. Blocks new queue entries for disabled modes; notifies and dequeues players mid-queue if a mode is toggled off live. |
| **Scoring Logic** | Tracks per-player and per-team score within match state. Owns the elimination event handler, assist window, and survival bonus accumulation. |
| **Timer Management** | Maintains a countdown timer per match session, initialized from `maxDurationSec`. Timer state is embedded in every `state_snapshot` emitted by Match Server. At `T=0` the system triggers the timeout win condition path. |
| **Event Mode Hook** | When `gameMode.eventModeActive = true`, loads the event mode config from Content Catalog by `gameMode.eventModeId` and splices it into the available queue pool at runtime. |

### What the Game Mode System Does NOT Own

- Zone shrink geometry and radius state (owned by Map/Arena System — Game Mode reads zone state only)
- Player matchmaking and team formation (owned by Matchmaking Engine — teams are passed in)
- Match server loop execution (owned by Match Server — Game Mode registers evaluators, it does not run the loop)
- MMR delta calculation (owned by Match Flow — Game Mode emits result type `win|draw|timeout`, Match Flow consumes it)
- HUD rendering (owned by In-Match HUD — Game Mode declares `hudOverlayType`, HUD renders accordingly)

---

## 2. Player Fantasy

Different players open BRAWLZONE in different emotional states. The Game Mode System is the mechanism that routes them to the experience that matches their mood and skills at that moment.

### 1v1 Duel — "Prove Yourself"

The Duel mode serves the player who wants a clean, zero-excuses test of individual skill. There is no teammate to blame, no crowd to hide in. Every loss is personal, every win is earned. The fantasy is the fighting game mentality: read your opponent, outplay them mechanically, and walk away knowing you were simply better in that moment. The absence of respawn and the instant-end-on-elimination creates extreme stakes that make each encounter feel heavy and deliberate.

**Target mood**: Competitive, focused, solo. "I want to prove I'm better than someone right now."

### 3v3 Squad Brawl — "We Win Together"

Squad Brawl serves the player who finds depth in coordination and shared victory. A win here is a team win — you can carry, but you cannot solo-carry in the way Duel allows. The mode creates natural moments of communication: do we push now? Who focuses the tank? The surviving player count tiebreaker means a team that protects its members is strategically rewarded, not just one that deals damage fastest.

**Target mood**: Social, strategic, cooperative. "I want to play *with* someone, not just next to them."

### 8-Player FFA — "Controlled Chaos"

FFA serves the player who wants energy, opportunism, and the dopamine rush of watching a plan come together in a messy situation they don't fully control. Sitting back while others fight, picking off weakened targets, surviving the zone collapse while everyone else panics — these are the joys of FFA. The scoring system rewards aggression *and* patience, because assists and survival bonuses mean purely defensive play is not dead weight.

**Target mood**: Casual-competitive, impulsive, risk-tolerant. "I want something exciting to happen right now."

---

## 3. Detailed Rules

### 3.1 Mode Data Schema

Each mode is stored as a static record in the Content Catalog. The canonical TypeScript interface:

```typescript
interface ModeConfig {
  id: string;                    // e.g. "duel_1v1", "squad_3v3", "ffa_8"
  name: string;                  // Display name: "1v1 Duel", "3v3 Squad Brawl", "8-Player FFA"
  playerCount: number;           // Total players in match (2, 6, 8)
  teamCount: number;             // 2 for Duel/Squad, 8 for FFA (each player = own team)
  teamSize: number;              // 1 for Duel/FFA, 3 for Squad
  mapPool: string[];             // Array of map IDs compatible with this mode
  winCondition: WinConditionType; // Enum: LAST_ALIVE | TEAM_ELIMINATION | SCORE_OR_LAST_ALIVE
  tiebreakerRule: TiebreakerRule; // Enum: HIGHER_HP_PCT | TEAM_HP_PCT | HIGHEST_SCORE | DRAW
  scoringRules: ScoringRules | null; // null for Duel (no score tracking needed)
  maxDurationSec: number;        // Default from Remote Config; overridable per mode
  hudOverlayType: HudOverlayType; // Enum: DUEL | SQUAD | FFA
  botFillMinPlayers: number | null; // null = no bot fill; 3 for FFA
}

interface ScoringRules {
  eliminationPoints: number;     // Points awarded to killer per elimination
  assistPoints: number;          // Points awarded to each assisting player
  survivalBonusRatePerSec: number; // Points per second of survival (fractional, applied at end)
  assistWindowSec: number;       // Seconds to look back for assist eligibility
  assistMinDamagePct: number;    // Minimum % of victim's total HP dealt to qualify as assist
}

type WinConditionType = 'LAST_ALIVE' | 'TEAM_ELIMINATION' | 'SCORE_OR_LAST_ALIVE';
type TiebreakerRule = 'HIGHER_HP_PCT' | 'TEAM_HP_PCT_SUM' | 'HIGHEST_SCORE' | 'DRAW';
type HudOverlayType = 'DUEL' | 'SQUAD' | 'FFA';
```

#### Concrete Mode Records

**1v1 Duel**
```json
{
  "id": "duel_1v1",
  "name": "1v1 Duel",
  "playerCount": 2,
  "teamCount": 2,
  "teamSize": 1,
  "mapPool": ["<maps with mode_compatibility containing 'duel_1v1'>"],
  "winCondition": "LAST_ALIVE",
  "tiebreakerRule": "HIGHER_HP_PCT",
  "scoringRules": null,
  "maxDurationSec": 180,
  "hudOverlayType": "DUEL",
  "botFillMinPlayers": null
}
```

**3v3 Squad Brawl**
```json
{
  "id": "squad_3v3",
  "name": "3v3 Squad Brawl",
  "playerCount": 6,
  "teamCount": 2,
  "teamSize": 3,
  "mapPool": ["<maps with mode_compatibility containing 'squad_3v3'>"],
  "winCondition": "TEAM_ELIMINATION",
  "tiebreakerRule": "TEAM_HP_PCT_SUM",
  "scoringRules": null,
  "maxDurationSec": 300,
  "hudOverlayType": "SQUAD",
  "botFillMinPlayers": null
}
```

**8-Player FFA**
```json
{
  "id": "ffa_8",
  "name": "8-Player FFA",
  "playerCount": 8,
  "teamCount": 8,
  "teamSize": 1,
  "mapPool": ["<maps with mode_compatibility containing 'ffa_8'>"],
  "winCondition": "SCORE_OR_LAST_ALIVE",
  "tiebreakerRule": "HIGHEST_SCORE",
  "scoringRules": {
    "eliminationPoints": 10,
    "assistPoints": 3,
    "assistWindowSec": 5,
    "assistMinDamagePct": 10,
    "survivalBonusRatePerSec": 0.1
  },
  "maxDurationSec": 480,
  "hudOverlayType": "FFA",
  "botFillMinPlayers": 3
}
```

---

### 3.2 Win Condition Evaluator Interface

The Game Mode System registers one `WinConditionEvaluator` per mode with Match Server at server initialization. Match Server calls the registered evaluator every tick (20 Hz) for each active match.

```typescript
type WinConditionEvaluator = (
  matchState: MatchState
) => WinConditionResult;

interface WinConditionResult {
  isOver: boolean;
  winners: PlayerId[];          // Empty array = draw
  result: 'win' | 'draw' | 'timeout';
}

interface MatchState {
  matchId: string;
  modeId: string;
  tick: number;
  timerRemainingMs: number;
  players: PlayerMatchState[];
  teams: TeamMatchState[];       // Length 1 per player for FFA
  zoneState?: ZoneState;         // Populated for FFA; read-only from Map/Arena
}

interface PlayerMatchState {
  playerId: string;
  teamId: string;
  isAlive: boolean;
  currentHp: number;
  maxHp: number;
  score: number;                 // FFA only; always 0 for Duel/Squad
  survivalTimeMs: number;
  damageDealtLog: DamageEntry[]; // Rolling 5s window maintained by Combat System
}

interface TeamMatchState {
  teamId: string;
  playerIds: string[];
  alivePlayers: string[];
  totalCurrentHp: number;
  totalMaxHp: number;
}
```

#### Evaluator Registration

```typescript
// Called once at server startup, before any matches begin
matchServer.registerWinConditionEvaluator('duel_1v1', duelEvaluator);
matchServer.registerWinConditionEvaluator('squad_3v3', squadEvaluator);
matchServer.registerWinConditionEvaluator('ffa_8', ffaEvaluator);
// Event modes registered dynamically when eventModeActive becomes true
```

---

### 3.3 Win Condition Logic — Per Mode

#### 3.3.1 1v1 Duel Evaluator

Checked every tick. Elimination events are the primary signal; timer expiry is the fallback.

```
GIVEN matchState for duel_1v1:

1. Count alive players: aliveCount = players.filter(p => p.isAlive).length

2. IF aliveCount == 1:
   → winner = the alive player
   → RETURN { isOver: true, winners: [winner.playerId], result: 'win' }

3. IF aliveCount == 0 (simultaneous elimination):
   → RETURN { isOver: true, winners: [], result: 'draw' }

4. IF timerRemainingMs <= 0 (timeout path):
   a. Sort players by (currentHp / maxHp) descending
   b. IF player[0].hpPct > player[1].hpPct:
      → RETURN { isOver: true, winners: [player[0].playerId], result: 'timeout' }
   c. ELSE (equal HP%):
      → RETURN { isOver: true, winners: [], result: 'draw' }

5. ELSE:
   → RETURN { isOver: false, winners: [], result: N/A }
```

**Design notes**: "Equal HP%" is defined as the HP percentages being identical when truncated to 2 decimal places (e.g., 45.67% vs 45.67%). This prevents floating-point noise from deciding matches; true draws are intentionally rare.

#### 3.3.2 3v3 Squad Brawl Evaluator

```
GIVEN matchState for squad_3v3:

1. FOR each team in teams:
   aliveCount[team.teamId] = team.alivePlayers.length

2. eliminatedTeams = teams.filter(t => aliveCount[t.teamId] == 0)

3. IF eliminatedTeams.length == 1:
   → winner = the OTHER team
   → RETURN { isOver: true, winners: winner.playerIds, result: 'win' }

4. IF eliminatedTeams.length == 2 (both teams eliminated simultaneously):
   → RETURN { isOver: true, winners: [], result: 'draw' }

5. IF timerRemainingMs <= 0 (timeout path):
   a. survivorCountA = aliveCount[teamA.teamId]
   b. survivorCountB = aliveCount[teamB.teamId]
   
   c. IF survivorCountA != survivorCountB:
      → RETURN { isOver: true, winners: [team with more survivors].playerIds, result: 'timeout' }
   
   d. ELSE (equal survivor counts — apply HP% tiebreaker):
      hpPctA = teamA.totalCurrentHp / teamA.totalMaxHp
      hpPctB = teamB.totalCurrentHp / teamB.totalMaxHp
      
      IF hpPctA > hpPctB (truncated to 2dp):
         → RETURN { isOver: true, winners: teamA.playerIds, result: 'timeout' }
      ELSE IF hpPctB > hpPctA:
         → RETURN { isOver: true, winners: teamB.playerIds, result: 'timeout' }
      ELSE:
         → RETURN { isOver: true, winners: [], result: 'draw' }

6. ELSE:
   → RETURN { isOver: false, winners: [], result: N/A }
```

**Design notes**: Survivor count is checked *before* HP% in the timeout tiebreaker. A team that protected more players is rewarded over a team that did more damage. This incentivizes defensive play and creates meaningful late-match decisions about whether to press or protect.

#### 3.3.3 8-Player FFA Evaluator

FFA has two live win condition triggers: last-player-alive and timer expiry. Zone shrink is handled by Map/Arena; the evaluator reads `zoneState` to emit `force_end_countdown` when the zone reaches minimum radius.

```
GIVEN matchState for ffa_8:

1. aliveCount = players.filter(p => p.isAlive).length

2. IF aliveCount == 1:
   → winner = the alive player
   → RETURN { isOver: true, winners: [winner.playerId], result: 'win' }

3. IF aliveCount == 0 (simultaneous final elimination):
   → RETURN { isOver: true, winners: [], result: 'draw' }

4. IF zoneState exists AND zoneState.isAtMinimumRadius AND !countdownEmitted:
   → EMIT force_end_countdown event to Match Server
   → SET countdownEmitted = true (per-match flag)
   (match continues; force_end_countdown begins a 10s grace timer in Match Server)

5. IF timerRemainingMs <= 0 OR force_end_countdown grace timer expired:
   a. IF aliveCount == 1:
      → RETURN { isOver: true, winners: [alivePlayer.playerId], result: 'win' }
   
   b. IF aliveCount >= 2 (timer expired with multiple alive):
      → Calculate final score for all alive players (survival bonus applied here — see §4)
      → Sort all players (alive + eliminated) by score descending
      → topScore = players[0].score
      → topPlayers = players.filter(p => p.score == topScore)
      
      IF topPlayers.length == 1:
         → RETURN { isOver: true, winners: [topPlayers[0].playerId], result: 'timeout' }
      ELSE:
         → RETURN { isOver: true, winners: [], result: 'draw' }

6. ELSE:
   → RETURN { isOver: false, winners: [], result: N/A }
```

---

### 3.4 Mode Availability and Remote Config Gating

#### On Match Start Request

When Matchmaking Engine requests a match for a given `modeId`:

```
1. CALL remoteConfig.get('gameMode.availableModes') → string[]
2. IF modeId NOT IN availableModes:
   → REJECT queue entry with reason: MODE_UNAVAILABLE
   → Matchmaking Engine notifies player in-app
3. ELSE:
   → CALL getModeConfig(modeId) → ModeConfig
   → Proceed with match initialization
```

#### getModeConfig Function

```typescript
function getModeConfig(modeId: string): ModeConfig {
  // Check event mode first
  const eventActive = remoteConfig.get('gameMode.eventModeActive');
  const eventModeId = remoteConfig.get('gameMode.eventModeId');
  if (eventActive && modeId === eventModeId) {
    const eventConfig = contentCatalog.getModeConfig(eventModeId);
    if (!eventConfig) {
      logger.error(`EVENT_MODE_CONFIG_MISSING: modeId=${eventModeId}`);
      throw new Error('EVENT_MODE_UNAVAILABLE');
    }
    return eventConfig;
  }
  // Standard modes
  return contentCatalog.getModeConfig(modeId);
}
```

#### Hot Push — Mode Disabled Mid-Queue

Remote Config emits a `config_updated` event when `gameMode.availableModes` changes. The Game Mode System subscribes to this event:

```
ON config_updated WHERE key == 'gameMode.availableModes':
  newAvailableModes = event.newValue
  FOR each player in Matchmaking Engine queue:
    IF player.queuedModeId NOT IN newAvailableModes:
      → DEQUEUE player
      → SEND notification: { type: 'MODE_DISABLED', modeId: player.queuedModeId }
      → Matchmaking Engine returns player to mode selection screen

Active matches in the affected mode: NO ACTION. Active matches continue to completion.
Reason: mid-match cancellation creates negative player experience and corrupts match history.
A mode being "disabled" is an operations/content decision; it does not retroactively invalidate
in-progress sessions.
```

---

### 3.5 Timer Management

- Timer is initialized from `ModeConfig.maxDurationSec` at match start.
- The `gameMode.matchDurationCapSec` Remote Config key (default: 600, Cold) is a hard cap applied at initialization: `effectiveMaxDurationSec = min(ModeConfig.maxDurationSec, matchDurationCapSec)`.
- Every server tick (50ms at 20 Hz), Match Server decrements `timerRemainingMs` by `tickDeltaMs`.
- Timer state is included in every `state_snapshot` payload sent to clients.
- At `timerRemainingMs <= 0`, Match Server calls the registered `WinConditionEvaluator` with a forced-timeout flag (equivalent to the evaluator's timer check reaching 0).
- Timer does NOT pause for disconnected players (see Edge Case §5.3).

> **Session Manager contract**: Session Manager reads `maxDurationSec` from the Game Mode config record when constructing `MatchConfig`. The per-mode values are authoritative; Session Manager must not hardcode a duration.

---

### 3.6 Team Assignment — 3v3 Squad Brawl

Teams are formed by Matchmaking Engine and passed to Game Mode System as part of the match initialization payload. The Game Mode System does not perform its own team balancing.

Matchmaking uses **MMR-interleaved assignment** (highest MMR → Team A, second → Team B, third → Team A, etc.) to produce balanced teams from a 6-player pool. The Game Mode System receives:

```typescript
interface MatchInitPayload {
  matchId: string;
  modeId: string;
  teams: {
    teamId: string;
    playerIds: string[];
  }[];
}
```

Team state is instantiated from this payload and tracked per-session in match state. The Game Mode System does not reassign players to teams after match start under any circumstances (including disconnects — see Edge Case §5.2).

---

### 3.7 FFA Scoring — Event Handling

Score is tracked per player in `PlayerMatchState.score`. The Game Mode System registers handlers for two Combat System events:

#### Elimination Event Handler

```
ON elimination_event:
  { victimId, killerId, assistantIds[] }  // assistantIds computed by Combat System

  matchState.players[killerId].score += eliminationPoints  // default: 10

  FOR each assistantId in assistantIds:
    matchState.players[assistantId].score += assistPoints  // default: 3
```

Assist eligibility is determined by Combat System (which has access to the full damage log) and passed pre-computed in the `elimination_event` payload. The Game Mode System consumes the result; it does not re-compute assist eligibility.

#### Assist Eligibility Rule (owned by Combat System, specified here for completeness)

A player qualifies as an assistant on a kill if:
- They dealt damage to the victim within the last `assistWindowSec` seconds (default: 5s)
- The total damage they dealt in that window equals or exceeds `assistMinDamagePct`% (default: 10%) of the victim's `maxHp`
- They are not the killer themselves
- They are alive at the time of the elimination event (dead players do not receive assist credit)

#### Survival Bonus (applied at match end)

Survival bonus is not incremental — it is calculated once when the match ends, using `survivalTimeMs` from each player's match state.

```
survivalBonus(player) = floor(player.survivalTimeMs / 10000) * survivalBonusRatePerSec * 10
```

(Simplified: 1 point per 10 seconds alive, at default rate. See §4 for full formula.)

This bonus is added to `player.score` immediately before the `WinConditionEvaluator` resolves the final ranking at timeout.

---

### 3.8 Event Mode Hook

```
ON server_startup OR config_updated WHERE key IN ['gameMode.eventModeActive', 'gameMode.eventModeId']:

  IF remoteConfig.get('gameMode.eventModeActive') == true:
    eventModeId = remoteConfig.get('gameMode.eventModeId')
    eventConfig = contentCatalog.getModeConfig(eventModeId)
    
    IF eventConfig == null:
      logger.error(`EVENT_MODE_CONFIG_MISSING: id=${eventModeId}`)
      // Event mode is treated as unavailable; standard modes unaffected
      eventModeAvailable = false
    ELSE:
      eventModeAvailable = true
      ADD eventModeId to in-memory available modes pool
      REGISTER WinConditionEvaluator for eventModeId (derived from eventConfig.winCondition type)
  
  ELSE:
    REMOVE event mode from available modes pool (if present)
    // Active event-mode matches continue to completion
```

---

## 4. Formulas

### 4.1 FFA Score Formula

Final score for a player at match end:

```
finalScore(p) = eliminationScore(p) + assistScore(p) + survivalBonus(p)

eliminationScore(p) = eliminations(p) × ELIMINATION_POINTS
                    = eliminations(p) × 10  [default]

assistScore(p) = assists(p) × ASSIST_POINTS
               = assists(p) × 3  [default]

survivalBonus(p) = floor(survivalTimeSec(p) / 10) × 1
                 = floor(survivalTimeMs(p) / 10000) × 1  [default rate: 0.1 pts/sec → 1pt/10s]
```

Where `survivalTimeSec(p)` is seconds from match start until the player was eliminated, or until match end if the player survived.

**General form (for tuning)**:
```
survivalBonus(p) = floor(survivalTimeSec(p) × SURVIVAL_BONUS_RATE_PER_SEC / SURVIVAL_BONUS_INTERVAL_SEC)
                   × SURVIVAL_BONUS_INTERVAL_SEC
```
At defaults: `floor(survivalTimeSec × 0.1 / 10) × 10 = floor(survivalTimeSec / 100) × 10`
Simplified: 1 point per complete 10-second interval alive.

### 4.2 3v3 HP% Tiebreaker Formula

Applied when timer expires and both teams have equal survivor counts.

```
teamHpPct(team) = (Σ currentHp(p) for p in team.players) / (Σ maxHp(p) for p in team.players)

winner = argmax(teamHpPct)
draw   = when |teamHpPct(A) - teamHpPct(B)| < 0.005  (i.e., rounds to same 2dp value)
```

Note: `totalMaxHp` in `TeamMatchState` is the sum of all team members' max HP, including eliminated players. This means a team that lost members is not unfairly penalized by having a smaller denominator — eliminated players contribute 0 HP to the numerator, dragging the team's percentage down.

### 4.3 Survival Bonus Formula (standalone)

```
survivalBonus(p) = floor(survivalTimeSec(p) / SURVIVAL_INTERVAL_SEC) × SURVIVAL_PTS_PER_INTERVAL

Default values:
  SURVIVAL_INTERVAL_SEC      = 10
  SURVIVAL_PTS_PER_INTERVAL  = 1
  (derived from SURVIVAL_BONUS_RATE_PER_SEC = 0.1 pts/sec)

Example:
  Player alive for 73 seconds:
  floor(73 / 10) × 1 = 7 points survival bonus
```

### 4.4 Assist Window Formula

The assist eligibility check is performed by Combat System on each elimination event. The relevant formula:

```
assistEligible(attacker, victim, killTime) =
  LET recentDamage = Σ damage dealt by attacker to victim
                     WHERE damageTimestamp ∈ [killTime - ASSIST_WINDOW_SEC, killTime]
  IN  recentDamage >= (victim.maxHp × ASSIST_MIN_DAMAGE_PCT / 100)
  AND attacker ≠ killer
  AND attacker.isAlive == true at killTime

Default values:
  ASSIST_WINDOW_SEC       = 5
  ASSIST_MIN_DAMAGE_PCT   = 10
```

---

## 5. Edge Cases

### 5.1 All Players Eliminated Simultaneously in FFA

**Scenario**: The final two (or more) players in an FFA match eliminate each other on the same tick — both `isAlive` flags flip to `false` in the same state update.

**Handling**:
- The FFA evaluator checks `aliveCount == 0` before `aliveCount == 1`.
- If `aliveCount == 0`, the evaluator returns `{ isOver: true, winners: [], result: 'draw' }`.
- All players in the match receive draw outcome.
- MMR impact: all players in the match receive equal draw-level MMR adjustment (no positive gain, no negative loss).
- Match is recorded in history with result type `DRAW`.

**Implementation note**: Match Server must guarantee that all elimination events generated in a single simulation tick are processed before the WinConditionEvaluator is called for that tick. A per-tick event batch flush must happen before evaluation.

### 5.2 3v3 Match with 2 Disconnects on One Team (1v3 Scenario)

**Scenario**: Both teammates on Team A disconnect, leaving 1 player on Team A against the full Team B (3 players).

**Handling**:
- The match continues with no force-balancing, bot substitution, or forfeit.
- Disconnected players are treated as alive-but-inactive for the purposes of the win condition evaluator. Their HP does not drain passively.
- The surviving Team A player can still win if they eliminate all 3 Team B players.
- If Team A's last player is eliminated (or disconnects), Team B wins normally.
- **Rationale**: Introducing mid-match bot substitution or force-balance at MVP adds significant complexity and creates exploitable behaviors (intentional disconnect to get a bot). The design accepts the rough experience in exchange for simplicity. Post-MVP, an abandonment penalty + bot fill system is scoped separately.

### 5.3 Timer Expires with Exactly One Player Alive in FFA

**Scenario**: Timer reaches 0 and `aliveCount == 1`.

**Handling**:
- This is a clean win for the surviving player; no score comparison is needed.
- Survival bonus is still calculated (the player was alive the entire match duration, so they earn maximum survival bonus).
- The evaluator returns `{ isOver: true, winners: [player.playerId], result: 'timeout' }` — `result: 'timeout'` because the timer triggered the evaluation, even though it is functionally a last-player-alive win.
- Match Flow and MMR system treat `timeout` + `winners.length == 1` as a standard win for ranking purposes.

### 5.4 Event Mode Config Missing from Content Catalog

**Scenario**: `gameMode.eventModeActive = true` and `gameMode.eventModeId = "halloween_ffa"` but the Content Catalog has no record for `"halloween_ffa"`.

**Handling**:
- `getModeConfig("halloween_ffa")` returns `null`.
- Game Mode System logs: `ERROR: EVENT_MODE_CONFIG_MISSING id=halloween_ffa`
- The event mode is treated as unavailable; it is NOT added to the available modes pool.
- Standard modes (`duel_1v1`, `squad_3v3`, `ffa_8`) are completely unaffected.
- No crash or degraded service to live matches.
- Operator resolution path: push the missing config to Content Catalog; on next `config_updated` event (or server restart), the event mode will attempt to load again.

### 5.5 Mode Toggled Off via Remote Config While 100 Players Are in Queue

**Scenario**: An operator hot-pushes `gameMode.availableModes` removing `"squad_3v3"` while 100 players are queued for it.

**Handling**:
1. Remote Config emits `config_updated` event; Game Mode System receives it within Remote Config's propagation SLA.
2. Game Mode System iterates all queued players for `squad_3v3` (sourced from Matchmaking Engine's queue state via internal API call).
3. Each affected player is dequeued atomically. Notification payload:
   ```json
   { "type": "MODE_DISABLED", "modeId": "squad_3v3", "message": "This mode is temporarily unavailable." }
   ```
4. Matchmaking Engine returns each player to the mode selection screen.
5. Active `squad_3v3` matches continue to completion — no interruption.
6. **Bulk dequeue performance**: The iteration must be handled asynchronously with rate-limiting if the queue is large. A synchronous loop over 100 players is acceptable at this scale; above 1,000 queued players, a batched async dequeue with progress tracking should be used.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Interface Used | What Game Mode System Needs |
|---|---|---|
| **Combat System** | `elimination_event` payload, damage log | Elimination events with pre-computed `assistantIds[]`; rolling damage log for assist window verification |
| **Match Server** | `registerWinConditionEvaluator()`, `state_snapshot`, tick loop | Evaluator registration API; guaranteed per-tick event flush before evaluator call; timer state in snapshot |
| **Map/Arena System** | `ZoneState` (read-only), `mode_compatibility[]` | Zone radius and `isAtMinimumRadius` flag for FFA; map pool filtering by `mode_compatibility` |
| **Content Catalog** | `getModeConfig(modeId)` | Static `ModeConfig` records for all modes including event modes |
| **Remote Config** | `get(key)`, `config_updated` event subscription | `availableModes`, `eventModeActive`, `eventModeId`, `matchDurationCapSec` |

### 6.2 Downstream Consumers

| System | What It Consumes from Game Mode System |
|---|---|
| **Matchmaking Engine** | Available modes pool (for queue eligibility); mode dequeue notifications on hot-push |
| **Match Flow** | `WinConditionResult` (`winners[]`, `result` type) for MMR delta calculation and match record writing |
| **In-Match HUD** | `hudOverlayType` from `ModeConfig` to render mode-appropriate UI (timer display, score panel, team health bars) |
| **Match Results Screen** | Mode-specific scoring breakdowns (FFA: per-player score with elimination/assist/survival split; Squad: team survivor count; Duel: HP% at timeout if applicable) |

---

## 7. Tuning Knobs

These values are the primary levers available to designers and operators to adjust game mode behavior without code changes. All are expressed as defaults; most are adjustable via Content Catalog (per-mode) or Remote Config (global overrides).

| Knob | Default | Owner | Notes |
|---|---|---|---|
| **Duel maxDurationSec** | 180 | Content Catalog / ModeConfig | Hard-capped by `matchDurationCapSec` (Remote Config, default 600) |
| **Squad maxDurationSec** | 300 | Content Catalog / ModeConfig | |
| **FFA maxDurationSec** | 480 | Content Catalog / ModeConfig | Should be > `ZONE_SHRINK_START_SEC` to allow zone to force engagement |
| **matchDurationCapSec** | 600 | Remote Config (Cold) | Global hard cap across all modes; prevents runaway matches in edge cases |
| **FFA Zone Shrink Start (ZONE_SHRINK_START_SEC)** | 90 | Map/Arena System (passed as parameter) | Game Mode System passes this value to Map/Arena on match init; should be ≥ 60s to give early-game free-roam period |
| **FFA eliminationPoints** | 10 | Content Catalog / ScoringRules | Increasing rewards aggression; decreasing rewards survival |
| **FFA assistPoints** | 3 | Content Catalog / ScoringRules | Should stay below `eliminationPoints`; at parity it creates kill-steal incentive |
| **FFA survivalBonusRatePerSec** | 0.1 | Content Catalog / ScoringRules | At 0.1 pts/sec: a player alive all 480s earns 48 survival pts vs. 10 pts per kill. Adjust to tune kill-vs-camp balance |
| **FFA assistWindowSec** | 5 | Content Catalog / ScoringRules | Shorter window rewards finishing; longer window rewards sustained pressure |
| **FFA assistMinDamagePct** | 10 | Content Catalog / ScoringRules | Lower values = more assists distributed; higher values = assists reserved for significant contributors |
| **FFA botFillMinPlayers** | 3 | Content Catalog / ModeConfig | Minimum real players required before bots fill the remaining slots (up to playerCount=8) |

### Tuning Guidance

**"FFA feels too campy"**: Increase `eliminationPoints` relative to `survivalBonusRatePerSec`, or decrease `ZONE_SHRINK_START_SEC` to force engagement earlier.

**"Nobody is going for assists in FFA"**: Decrease `assistMinDamagePct` (easier to qualify) or increase `assistPoints` (more rewarding).

**"Duel matches feel too long / too rushed"**: Adjust `Duel maxDurationSec`. 180s (3 min) is designed to be a brisk but not panicked pace. Below 120s may feel too frantic for mobile controls.

**"3v3 timeouts happen too often"**: Decrease `Squad maxDurationSec` to force resolution, or review map pool for maps with excessive cover that stall fights.

---

## 8. Acceptance Criteria

All criteria are testable via automated integration tests against a headless match server instance unless marked [Manual].

### 8.1 Win Conditions

| ID | Criterion | Test Method |
|---|---|---|
| WC-01 | 1v1 Duel ends immediately when one player is eliminated; the alive player is the winner | Unit test: WinConditionEvaluator with one player `isAlive=false` |
| WC-02 | 1v1 Duel ends in draw when both players are eliminated on the same tick | Unit test: both `isAlive=false`, evaluate same tick |
| WC-03 | 1v1 Duel at timer expiry: player with higher HP% wins | Unit test: timer=0, p1.hp=60/100, p2.hp=40/100 → p1 wins |
| WC-04 | 1v1 Duel at timer expiry with equal HP% (to 2dp): draw | Unit test: timer=0, both players at 50.00% HP → draw |
| WC-05 | 3v3 Squad Brawl ends when all 3 players on one team are eliminated | Integration test: eliminate team B's 3 players sequentially |
| WC-06 | 3v3 timer expiry: team with more survivors wins | Unit test: timer=0, teamA alive=2, teamB alive=1 → teamA wins |
| WC-07 | 3v3 timer expiry, equal survivors: team with higher total HP% wins | Unit test: timer=0, each team alive=2, teamA totalHpPct=0.65, teamB=0.58 → teamA wins |
| WC-08 | 3v3 timer expiry, equal survivors, equal HP% (to 2dp): draw | Unit test: timer=0, both teams equal survivors and equal HP% |
| WC-09 | FFA ends immediately when only one player remains alive | Unit test: 7 players eliminated, 1 alive → winner declared |
| WC-10 | FFA at timer expiry with multiple alive: player with highest total score wins | Integration test: run FFA to timeout, verify winner is top scorer |
| WC-11 | FFA at timer expiry with tied scores among alive players: draw | Unit test: timer=0, top 2 players tied score → draw |
| WC-12 | FFA `force_end_countdown` event is emitted exactly once when zone reaches minimum radius | Integration test with Map/Arena mock: verify event emitted once |

### 8.2 Scoring

| ID | Criterion | Test Method |
|---|---|---|
| SC-01 | Killer receives `eliminationPoints` (10) when elimination event fires | Unit test: elimination_event handler, verify score delta |
| SC-02 | Each eligible assisting player receives `assistPoints` (3) on elimination | Unit test: elimination_event with assistantIds=[A,B], verify both get +3 |
| SC-03 | Dead players do not receive assist credit (covered by Combat System, verified at integration boundary) | Integration test: player eliminated before kill resolves, no assist credit |
| SC-04 | Survival bonus is applied at match end, not incrementally during play | Unit test: check score mid-match (no survival pts) vs. post-match (survival pts present) |
| SC-05 | Survival bonus = floor(survivalTimeSec / 10) × 1 at default settings | Unit test: player alive 73s → bonus = 7 |
| SC-06 | Eliminated player's survival time stops at time of elimination | Unit test: player eliminated at T=45s in 300s match → survivalTime=45s |

### 8.3 Mode Availability Gating

| ID | Criterion | Test Method |
|---|---|---|
| MA-01 | Queue attempt for a mode not in `availableModes` is rejected with MODE_UNAVAILABLE | Unit test: `availableModes=["duel_1v1"]`, attempt to queue for `squad_3v3` → rejected |
| MA-02 | Hot push removing a mode dequeues all players in that mode's queue | Integration test: 10 players queued for `squad_3v3`, push `availableModes` without it, verify all dequeued |
| MA-03 | Dequeued players receive MODE_DISABLED notification | Integration test: verify notification payload for each dequeued player |
| MA-04 | Active matches in a disabled mode continue to completion | Integration test: start match, disable mode via config push, verify match completes normally |
| MA-05 | Event mode is added to available pool when `eventModeActive=true` and config exists | Integration test: set event flags, verify mode appears in available pool |
| MA-06 | Event mode is NOT added when config is missing; ERROR is logged; standard modes unaffected | Unit test: mock ContentCatalog to return null, verify error log and no pool mutation |
| MA-07 | `matchDurationCapSec` (600) is applied as hard cap on all mode durations | Unit test: mode with maxDurationSec=700, cap=600, effective duration=600 |

### 8.4 Edge Cases

| ID | Criterion | Test Method |
|---|---|---|
| EC-01 | FFA simultaneous final elimination → draw result, all players get draw MMR | Integration test: simultaneous elimination trigger |
| EC-02 | 3v3 with 2 disconnects on one team: match continues, no force-balance | Integration test: disconnect 2 players, verify match state continues |
| EC-03 | FFA timer expiry with exactly 1 alive player: that player wins, result type = 'timeout' | Unit test: timer=0, aliveCount=1 → winner declared, result='timeout' |
| EC-04 | Event mode config missing: mode unavailable, ERROR logged, no server error thrown | Unit test: mock missing config, verify no exception propagates |
| EC-05 | 100 players dequeued when mode disabled: all receive notification, no partial dequeue | Load test: 100 queued players, hot push, verify all notified atomically |

### 8.5 Timer Management

| ID | Criterion | Test Method |
|---|---|---|
| TM-01 | Timer state is present in every `state_snapshot` payload | Integration test: capture snapshots, verify `timerRemainingMs` field present |
| TM-02 | Timer counts down from `effectiveMaxDurationSec` at 20 Hz | Unit test: advance 20 ticks (1 second), verify timerRemainingMs reduced by 1000ms |
| TM-03 | At `timerRemainingMs=0`, WinConditionEvaluator is called with timeout trigger | Unit test: advance timer to 0, verify evaluator called with forced timeout |
| TM-04 | Timer does NOT pause when a player disconnects | Integration test: disconnect player, verify timer continues |

---

*End of Document — Game Mode System GDD v1.0 (Draft)*
