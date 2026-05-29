# ADR-0006: Client State Management (Profile, Inventory, Match State)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, UI Programmer

## Summary

The React Native client manages three independent state domains: Player Profile + Economy (Zustand store, invalidated by `profile:refresh`), Inventory/Entitlements (Zustand store, invalidated by `inventory:updated`), and Match State (interpolated buffer updated at 20Hz from `match_state` events). The client never polls for updates; all changes are server-pushed. This ADR defines the store interfaces, invalidation strategy, and interpolation approach.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | UI / Core |
| **Knowledge Risk** | LOW — Zustand and React Native patterns are within training data |
| **References Consulted** | `design/gdd/player-profile.md`, `design/gdd/realtime-transport.md`, `design/gdd/match-results.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm Zustand v4 compatibility with current Expo SDK React version |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002 (Socket.io events), ADR-0004 (Supabase session) |
| **Enables** | All client UI screens (Profile Store drives most screens) |
| **Blocks** | Main Menu, Lobby, Match HUD, Match Results, Shop — all read from these stores |
| **Ordering Note** | Store interfaces must be defined before any screen is implemented |

## Context

### Problem Statement

A mobile game client needs to display real-time match state at 60fps, instantly reflect economy changes (coin balance, new items), and never show stale data after a purchase or match reward. Without a clear invalidation strategy, screens end up polling or holding stale cache indefinitely.

### Current State

`mobile/stores/gameStore.ts` is scaffolded. No Zustand stores are implemented.

### Constraints

- React Native JS thread must stay ≤16.6ms; heavy state updates cannot block the render cycle
- `profile:refresh` is the server's single push event for all economy changes — client must not poll
- Match state arrives at 20Hz from server; client renders at 60fps → interpolation required
- No polling of any kind — battery and network efficiency on mobile

### Requirements

- Profile Store: cached `PlayerProfile`; invalidated by `profile:refresh` socket event
- Inventory Cache: cached `EntitlementList`; invalidated by `inventory:updated` socket event
- Match State: ring buffer of last 3 ticks; interpolated at 60fps render time
- All stores initialize on successful auth; cleared on sign-out
- Stores are the single source of truth for UI; screens never fetch directly from API in render path

## Decision

Use **Zustand** for Profile Store and Inventory Cache. Use a **custom interpolation buffer** (not a Zustand store) for Match State — match state updates too frequently for React re-renders to be the primary consumer; the match HUD reads directly from the buffer in its animation frame callback.

### Architecture

```
SOCKET.IO CLIENT
  │
  ├── on('profile:refresh', profile)
  │     └── ProfileStore.setProfile(profile)  → triggers React re-renders
  │
  ├── on('inventory:updated', entitlements)
  │     └── InventoryStore.setInventory(entitlements)  → triggers React re-renders
  │
  └── on('match_state', snapshot)
        └── MatchStateBuffer.push(snapshot)  → no React re-render; HUD reads via rAF

ZUSTAND STORES:
  ProfileStore:
    { profile: PlayerProfile | null, isLoading: boolean }
    setProfile(p)       — called by profile:refresh handler
    invalidate()        — sets profile to null; triggers re-fetch
    fetchProfile()      — GET /v1/profile; sets profile on success

  InventoryStore:
    { entitlements: EntitlementList | null }
    setInventory(e)     — called by inventory:updated handler
    fetchInventory()    — GET /v1/inventory; sets entitlements on success

MATCH STATE BUFFER:
  CircularBuffer<MatchSnapshot>[3]  — holds last 3 ticks
  push(snapshot)        — overwrites oldest slot
  getInterpolated(renderTime): InterpolatedState
    — lerps between tick N and tick N+1 based on (renderTime - tickTimestamp) / 50ms
    — clamped: never extrapolates beyond last known tick
```

### Key Interfaces

```typescript
// Profile Store (Zustand)
interface ProfileStore {
  profile: PlayerProfile | null;
  isLoading: boolean;
  setProfile: (p: PlayerProfile) => void;
  invalidate: () => void;
  fetchProfile: () => Promise<void>;
}
const useProfileStore = create<ProfileStore>(...)

// Inventory Store (Zustand)
interface InventoryStore {
  entitlements: EntitlementList | null;
  setInventory: (e: EntitlementList) => void;
  fetchInventory: () => Promise<void>;
}
const useInventoryStore = create<InventoryStore>(...)

// Match State Buffer (singleton, not a Zustand store)
class MatchStateBuffer {
  push(snapshot: MatchSnapshot): void;
  getInterpolated(renderTime: number): InterpolatedPlayerState[];
}

// React hook for screens that need profile
function useProfile(): PlayerProfile | null {
  return useProfileStore(s => s.profile);
}

// React hook for match HUD — reads from buffer, not store
function useMatchHUD(): {
  requestAnimationFrame(callback: () => void): void;
  // HUD component sets up its own rAF loop reading from MatchStateBuffer
}
```

### Implementation Guidelines

- `ProfileStore.fetchProfile()` is called once on app start (after auth resolves) and on `invalidate()`
- `profile:refresh` handler calls `setProfile(profile)` directly — no refetch needed; server pushes the new state
- Never call `fetchProfile()` in a component's `useEffect` with no deps — it runs on every render; only call it explicitly after invalidation
- `MatchStateBuffer` is a module-level singleton; match screen subscribes its rAF loop on mount, clears on unmount
- Interpolation: linear lerp for position; snap for HP, status effects (discrete values don't lerp)
- On sign-out: call `useProfileStore.getState().invalidate()` and `useInventoryStore.getState().setInventory(null)`

## Alternatives Considered

### Alternative 1: React Query / TanStack Query

- **Description**: Use React Query for all server state, including profile and inventory.
- **Pros**: Built-in caching, refetch strategies, loading/error states; widely used in React Native.
- **Cons**: React Query is polling-oriented; its refetch-on-focus and stale-time model conflicts with the socket-push invalidation model; adds complexity without benefit here.
- **Rejection Reason**: Server-push invalidation (`profile:refresh`) is simpler and more efficient than any polling strategy; Zustand's minimal API is sufficient.

### Alternative 2: Redux Toolkit

- **Description**: Use Redux with RTK Query for all client state.
- **Pros**: Mature; strong DevTools support; RTK Query handles caching.
- **Cons**: Significant boilerplate; Redux slices for simple profile cache is overengineered.
- **Rejection Reason**: Zustand is lighter, simpler, and sufficient for the three independent state domains.

## Consequences

### Positive

- No polling paths anywhere in the client — battery and network efficient
- Match HUD bypasses React re-renders entirely for 20Hz state — frame budget preserved
- Profile Store is the single contract for all economy UI — no ad-hoc API calls in screens

### Negative

- Match State Buffer is a bespoke implementation; must be tested carefully for interpolation edge cases (late packets, out-of-order ticks)
- Two separate store systems (Zustand + custom buffer) — slightly more cognitive overhead

### Neutral

- Zustand stores must be cleared on sign-out; this is a manual step that must be audited in the sign-out flow

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Stale profile shown after economy mutation | Medium | Medium | Test: grant coins → `profile:refresh` → UI shows new balance within 500ms |
| Match State Buffer overflow (push faster than consume) | Low | Low | Buffer is fixed-size ring (3 slots); oldest slot overwritten; client always renders latest interpolated |
| Memory leak from Match HUD rAF not cancelled | Medium | Medium | HUD component must cancel rAF in cleanup function; enforce in code review |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Profile update latency (push → UI) | — | ≤100ms | — |
| Match HUD frame time (JS thread) | — | ≤16.6ms | 16.6ms |
| Zustand re-renders per profile:refresh | — | Only subscribed screens | — |

## Migration Plan

New project.

**Rollback plan**: Replace Zustand with Redux — `ProfileStore` and `InventoryStore` interfaces are unchanged; only the implementation changes.

## Validation Criteria

- [ ] `profile:refresh` → UI shows updated coin balance within 500ms (manual test)
- [ ] Match HUD renders at 60fps with no frame drops during 8-player match (Flipper profile)
- [ ] Sign-out clears both stores; subsequent sign-in with different account shows correct profile
- [ ] `MatchStateBuffer.getInterpolated()` returns positions between two ticks, not before/after

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/player-profile.md` | Player Profile | Client caches profile; invalidated by profile:refresh | ProfileStore + socket handler defined above |
| `design/gdd/realtime-transport.md` | Transport | Client interpolates match state between server ticks | MatchStateBuffer with lerp interpolation |
| `design/gdd/match-results.md` | Match Results | Show mmrDelta, xp gain, coins — all in match_end payload | ProfileStore invalidated by profile:refresh after match_end |

## Related

- ADR-0001: Client is display-only; stores enforce this by never running game logic
- ADR-0002: Socket.io events (`profile:refresh`, `match_state`) are the write triggers for stores
- ADR-0004: Supabase session resolves → ProfileStore.fetchProfile() is the app entry sequence
