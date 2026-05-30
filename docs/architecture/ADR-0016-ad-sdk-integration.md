# ADR-0016: Ad SDK Integration (AdMob Initialization Gate)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director

## Summary

AdMob (`react-native-google-mobile-ads`) is initialized only for free players without Play Pass. The `has_no_ads` flag in `player_profiles` (set on Play Pass purchase) suppresses all ad initialization. Ad reward grants are server-validated via a `POST /v1/ads/reward-grant` endpoint with a server-side ad token. This ADR defines the initialization gate, the reward grant flow, and the Play Pass suppression mechanism.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Foundation |
| **Knowledge Risk** | LOW — `react-native-google-mobile-ads` is within training data |
| **References Consulted** | `design/gdd/ad-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `react-native-google-mobile-ads` compatibility with current Expo SDK (managed workflow requires native module config) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004 (userId), ADR-0006 (Profile Store → has_play_pass flag) |
| **Enables** | Ad revenue for free players |
| **Blocks** | None — deferrable to Alpha milestone |
| **Ordering Note** | Deferrable; must be Accepted before AdMob implementation begins |

## Context

### Problem Statement

Free players see ads as part of the monetization model. Play Pass subscribers must never see ads. Ad reward grants (watch-an-ad-get-coins) must be server-validated to prevent fake reward claims.

### Constraints

- `has_play_pass = true` → AdMob SDK must not be initialized (GDPR surface, performance)
- Ad reward token must be validated server-side — client cannot self-grant coins for watching ads
- AdMob initialization requires `app-ads.txt` and AdMob App ID in `app.json`
- GDPR consent required for EU players before ad display

### Requirements

- Initialize AdMob only if `profile.has_play_pass === false` after profile load
- `POST /v1/ads/reward-grant { adToken, adType }` → server validates token → grants coins
- Ad token is generated server-side and sent to client before ad load; client returns it after ad completion
- `has_no_ads` flag in `player_profiles` = `has_play_pass` (same field, aliased for clarity in code)

## Decision

AdMob is conditionally initialized in `_layout.tsx` after the profile loads. The server generates a one-time `adToken` per rewarded ad opportunity and validates it on `reward-grant`. Play Pass → profile.has_play_pass flag → skip AdMob init.

### Architecture

```
CLIENT (_layout.tsx, after auth + profile load):
  const profile = useProfile();
  useEffect(() => {
    if (!profile?.has_play_pass) {
      MobileAds().initialize();  // Only for free players
    }
  }, [profile?.has_play_pass]);

REWARDED AD FLOW:
  1. Client calls GET /v1/ads/token → server returns { adToken: UUID, expiresAt }
  2. Client loads rewarded ad with AdMob SDK
  3. Client watches ad
  4. Client calls POST /v1/ads/reward-grant { adToken, adType: 'rewarded' }
  5. Server: validate adToken (exists in DB, not expired, not used) → creditCoins(+25)
  6. Server: DELETE adToken from DB (single-use)
  7. Server: emit profile:refresh

SERVER ENDPOINTS:
  GET  /v1/ads/token        → { adToken: string, expiresAt: number }  (JWT-protected)
  POST /v1/ads/reward-grant { adToken: string, adType: 'rewarded' }
                            → { coinsGranted: 25 } | 403 (invalid/expired token)
```

### Key Interfaces

```typescript
// Server: ad_tokens table
CREATE TABLE ad_tokens (
  token UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES player_profiles(user_id),
  ad_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,  -- now() + 10 minutes
  used_at TIMESTAMPTZ               -- null = unused
);

// Client: conditional init
import MobileAds from 'react-native-google-mobile-ads';
// Only initialize in useEffect when has_play_pass === false
```

### Implementation Guidelines

- Ad initialization is conditional and idempotent; calling `MobileAds().initialize()` twice is safe
- `has_play_pass` state changes propagate via `profile:refresh`; client re-evaluates ad state on every profile update
- For EU GDPR: show consent dialog before `MobileAds().initialize()` — use `@react-native-google-mobile-ads/consent` module
- adToken single-use: `UPDATE ad_tokens SET used_at=now() WHERE token=$token AND used_at IS NULL RETURNING *`; if no row returned → 403

## Consequences

### Positive

- Play Pass subscribers have zero AdMob SDK footprint — no performance overhead, no data collection
- Ad reward grants are server-validated — no fake coin farming

### Negative

- `react-native-google-mobile-ads` requires native module setup in Expo (app.json plugin); not compatible with Expo Go — requires dev client or production build
- AdMob GDPR compliance adds UX friction in EU markets

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| AdMob initialized after Play Pass purchase (before profile:refresh) | Low | Low | Profile:refresh clears has_play_pass; useEffect re-runs; calling init again is idempotent |

## Validation Criteria

- [ ] Play Pass subscriber: AdMob.initialize() never called (verify with network inspector)
- [ ] Free player: rewarded ad completes → `profile:refresh` shows +25 coins within 2s
- [ ] Duplicate reward-grant with same adToken → 403 returned; balance unchanged
- [ ] adToken expires after 10 minutes → 403 returned

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/ad-system.md` | Ads | AdMob for free players; suppressed for Play Pass | has_play_pass gate on MobileAds().initialize() |
| `design/gdd/ad-system.md` | Ads | Server-validated ad reward grants | adToken pattern defined |

## Related

- ADR-0006: Profile Store exposes `has_play_pass`; ad init reacts to it
- ADR-0008: Coin grant uses idempotency key (adToken serves as the key)
- ADR-0011: Play Pass purchase sets `has_play_pass = true` via IAP fulfillment
