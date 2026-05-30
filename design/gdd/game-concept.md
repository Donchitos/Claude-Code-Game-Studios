# BRAWLZONE — Game Concept Document

**Platform**: iOS + Android (React Native / Expo)
**Genre**: Real-time Action PvP
**Session Length**: 3–10 minutes per match
**Version**: 0.1.0 | **Status**: Pre-Production

---

## 1. Overview

BRAWLZONE is a mobile-first real-time PvP brawler where players choose a character and compete in short-form matches across three modes: 1v1 Duel, 3v3 Squad Brawl, and 8-player Free-for-All. Matches are capped at 10 minutes and designed for mobile play sessions. The game monetizes through cosmetics and optional subscriptions, with a free-to-play base that never gates competitive ability behind paywalls.

---

## 2. Player Fantasy

The player feels like a skilled fighter rising through the ranks — picking their champion, reading opponents, landing perfect combos, and walking away with loot. Winning feels earned. Losing feels close. Every match is over fast enough to try again immediately.

---

## 3. Detailed Rules

### Game Modes

| Mode | Players | Win Condition | Max Duration |
|------|---------|---------------|--------------|
| 1v1 Duel | 2 | Last alive | 10 min |
| 3v3 Squad Brawl | 6 | Team eliminations | 10 min |
| 8-Player FFA | 8 | Most score at time-out or last alive | 10 min |

### Characters (Launch Roster — 8 total)

| Unlock Type | Count | Details |
|-------------|-------|---------|
| Free (default) | 3 | Available to all accounts |
| Earnable | 3 | Unlocked via in-game progression (XP, match wins) |
| Premium (Diamond-only) | 2 | Purchased with Diamonds; cosmetically distinct, balanced identically |

All characters are statistically balanced. Premium characters offer visual differentiation only — no mechanical advantage.

### Skins

| Tier | Source | Notes |
|------|--------|-------|
| Free | In-game rewards, events | Earnable without payment |
| Diamond | Diamond IAP store | Cosmetic only |
| Play Pass Exclusive | Active Play Pass subscription | Lost access if subscription lapses |

### Match Flow

1. Matchmaking (rating-based, same mode)
2. 3-second countdown
3. Active match (real-time, server-authoritative)
4. End screen (scores, rewards, XP)
5. Reward distribution (Diamonds, XP, seasonal points)

---

## 4. Formulas

### Matchmaking Rating (MMR)

```
new_rating = old_rating + K × (outcome - expected_outcome)
expected_outcome = 1 / (1 + 10^((opponent_rating - player_rating) / 400))
K = 32  (provisional), 16 (established, >30 matches)
outcome = 1 (win), 0.5 (draw), 0 (loss)
```

### Match Reward (Diamonds)

```
diamonds_earned = base_reward × win_multiplier × play_pass_bonus
base_reward     = 3 (loss) | 5 (win)
win_multiplier  = 1.0 (loss) | 2.0 (win)
play_pass_bonus = 1.0 (none) | 1.25 (active Play Pass)
```

### XP per Match

```
xp = 100 + (50 × kills) + (200 × win_bonus)
win_bonus = 1 (win) | 0 (loss)
```

---

## 5. Edge Cases

- **Disconnect mid-match**: Player's character is marked inactive; remaining players continue. If < 2 active players remain in Duel, match ends immediately and the connected player wins.
- **Draw (FFA time-out tie)**: All tied players share the win bonus equally.
- **Play Pass lapses**: Exclusive skins are hidden (not deleted) until subscription resumes. Diamonds bonus stops immediately.
- **Premium character purchased by non-Play Pass user**: Full Diamond purchase; no subscription required.
- **Queue timeout (no match found in 60s)**: Player is notified and returned to lobby; queue position is preserved on re-entry.
- **Match start with a player not ready**: 3-second grace period, then match starts without them (treated as disconnect).

---

## 6. Dependencies

- **Auth system**: Supabase Auth (JWT issued on login, validated by game server)
- **IAP system**: RevenueCat (handles Diamond packs, Play Pass subscription, No-Ads lifetime)
- **Ad system**: AdMob (shown to free players only; suppressed when `has_no_ads = true`)
- **Real-time transport**: Socket.io over WebSocket (Node.js game server)
- **Persistence**: PostgreSQL (accounts, match history, economy) + Redis (matchmaking queues, session cache)
- **Push notifications**: Expo Notifications (match reminders, event alerts)

---

## 7. Tuning Knobs

| Parameter | Default | Notes |
|-----------|---------|-------|
| Match max duration | 600s | Per mode, configurable per-mode |
| Matchmaking timeout | 60s | Before queue notification |
| Countdown duration | 3s | Before match starts |
| K-factor (MMR) | 32 / 16 | Provisional / established |
| Base win reward | 5 diamonds | Adjust for economy balance |
| Play Pass Diamond bonus | +25% | Subscription value lever |
| Server tick rate | 50ms (20 Hz) | Mobile bandwidth target |

---

## 8. Acceptance Criteria

- [ ] Player can create an account and log in via Supabase Auth
- [ ] Player can join a matchmaking queue for any of the 3 modes
- [ ] Match found within 60 seconds (real users) or immediately (bots in beta)
- [ ] Real-time match runs at ≥20 Hz tick rate without visible lag on 4G
- [ ] Match ends correctly in all termination conditions (win, loss, draw, disconnect)
- [ ] Rewards (Diamonds, XP) are credited within 5 seconds of match end
- [ ] Diamond IAP completes end-to-end via RevenueCat in both sandbox and production
- [ ] Play Pass subscription gates exclusive skins and Diamond bonus correctly
- [ ] AdMob ads appear only for free players (suppressed for No-Ads and Play Pass users)
- [ ] Beta: IP-tagging applied at registration, Founder Skin airdropped to qualified accounts
