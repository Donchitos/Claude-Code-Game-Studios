# Story 004: Ping/Pong RTT Measurement & Connection Quality

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: Client emits `ping { clientTimestamp }` every 2000ms; server echoes `pong { clientTimestamp, serverTimestamp }`; client computes RTT = `now() - clientTimestamp`; 5-sample moving average; HUD quality thresholds.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-07**: Client emits `ping { clientTimestamp: T }` → server responds with `pong { clientTimestamp: T, serverTimestamp: S }` within 50ms; client computes `RTT = now() - T`
- [ ] **AC-RT-08**: 5 RTT samples [80, 90, 100, 110, 120]ms → `avgRTT = 100ms` (exact)
- [ ] **AC-RT-16**: `avgRTT = 160ms` → `connectionQuality.quality === "poor"` and `connectionQuality.avgRttMs === 160`
- [ ] Quality thresholds: good <100ms, fair 100-150ms, poor 150-200ms, critical >200ms
- [ ] `connectionQuality` is a reactive object consumed by HUD; updates after every pong

---

## Implementation Notes

- Client: `setInterval(() => socket.emit('ping', { clientTimestamp: Date.now() }), PING_INTERVAL_MS)` (default 2000ms)
- Server ping handler: `socket.on('ping', ({ clientTimestamp }) => socket.emit('pong', { clientTimestamp, serverTimestamp: Date.now() }))`
- Client pong handler: compute RTT; push to circular buffer (5 slots); compute moving average; update `connectionQuality` reactive object
- Jitter: `|RTT_n - avgRTT_{n-1}|`; moving average over 5 samples
- Packet loss estimate: `(100 - received_deltas_last_100) / 100` from tick counter gaps (§4.6 formula)

---

## QA Test Cases

- **AC-RT-07**: Pong echoes clientTimestamp
  - Given: Client emits `ping { clientTimestamp: 1716000000000 }`
  - When: Server receives
  - Then: Server responds with `pong { clientTimestamp: 1716000000000, serverTimestamp: <server_now> }` within 50ms

- **AC-RT-08**: Moving average calculation
  - Given: 5 consecutive RTT samples: 80, 90, 100, 110, 120 (ms)
  - When: `avgRTT` computed
  - Then: `avgRTT === 100` (exact, no floating point error)

- **AC-RT-16**: Quality threshold mapping
  - Given: `avgRTT = 160`
  - When: `connectionQuality` read
  - Then: `{ quality: "poor", avgRttMs: 160 }`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/ping-pong-rtt_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (connection established)
- Unlocks: No direct dependency chain
