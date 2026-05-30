# React Native (Expo SDK) — Version Reference

| Field | Value |
|-------|-------|
| **Stack** | React Native + Expo SDK |
| **Expo SDK Version** | Verify: `npx expo --version` in `mobile/` |
| **Node.js Version** | Verify: `node --version` |
| **TypeScript Version** | Verify: see `package.json` in `mobile/` and `server/` |
| **Project Pinned** | 2026-05-24 |
| **Last Docs Verified** | 2026-05-24 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | LOW — React Native and Expo are within LLM training data |

## Knowledge Gap Note

React Native and Expo SDK are well within the LLM's training data. No significant
API knowledge gaps expected. Features in Expo SDK releases after May 2025 may not
be known — verify via the [Expo changelog](https://expo.dev/changelog) when using
recently-added APIs.

## Key Dependencies (from game concept)

| Package | Purpose | Notes |
|---------|---------|-------|
| `socket.io-client` | Real-time match transport | Server tick target: 20Hz (50ms) |
| `@supabase/supabase-js` | Auth + PostgreSQL + Redis (via server) | JWT validated server-side |
| `react-native-purchases` | RevenueCat IAP + subscriptions | Diamond packs, Play Pass |
| `react-native-google-mobile-ads` | AdMob | Free players only; suppressed with `has_no_ads` |
| `expo-notifications` | Push notifications | Match reminders, event alerts |

## Verified Sources

- Expo SDK changelog: https://expo.dev/changelog
- React Native releases: https://reactnative.dev/blog
- Expo EAS Build docs: https://docs.expo.dev/build/introduction/
- Socket.io docs: https://socket.io/docs/v4/
