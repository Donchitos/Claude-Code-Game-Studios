# Web — Networking Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** none major — the recurring hazard is trusting the client, which is uniquely dangerous on the web

---

## Overview

| Transport | Reliability | Use for |
|-----------|-------------|---------|
| **WebSocket** | Reliable, ordered (TCP) | Turn-based, lobbies, chat, most games |
| **WebRTC data channel** | Configurable, can be unreliable/unordered | Fast-paced action needing low latency |
| **HTTP / fetch** | Reliable | Leaderboards, saves, matchmaking |

**Raw UDP is not available in a browser.** WebRTC data channels are the only way
to get unreliable, unordered delivery, and they cost significant connection
complexity (signalling server, ICE, STUN/TURN).

**Start with WebSocket.** It is enough for the large majority of web multiplayer
games and vastly simpler. Move to WebRTC only when measurement shows TCP
head-of-line blocking is actually hurting the game.

---

## The Security Rule

**The client is fully compromised. Always.**

On the web this is not a hypothetical: the player has DevTools open, can read
every line of your code, modify any variable, and replay or forge any message.
There is no obfuscation that survives an interested attacker, and minification
is not a security measure.

- **The server is authoritative for everything that matters.** Score, currency, inventory, position, hit registration
- The client sends *intent* ("I pressed left"), never *outcome* ("my score is 9999")
- Validate every message server-side against what is actually possible
- Rate-limit per connection
- Never ship API keys, secrets, or admin endpoints in the bundle

```ts
// ❌ Client asserts the result
socket.send({ type: 'scoreUpdate', score: 9999 });

// ✅ Client reports input; the server computes and owns the result
socket.send({ type: 'input', seq: 42, left: true, right: false });
```

---

## WebSocket

```ts
const ws = new WebSocket('wss://example.com/game');   // wss:// always
ws.binaryType = 'arraybuffer';

ws.addEventListener('message', (e) => {
  const msg = decode(e.data);
  applyServerState(msg);
});
```

- **`wss://` only.** A page served over HTTPS cannot open a plain `ws://` connection
- Handle `close` and reconnect with **exponential backoff plus jitter** — a server restart otherwise produces a synchronized reconnect stampede from every client
- Heartbeat/ping to detect dead connections; browsers do not reliably fire `close` on network loss
- Buffer outgoing messages while `readyState !== OPEN`

### Serialization
JSON is fine for turn-based games and easy to debug. For real-time, binary
(`ArrayBuffer` with `DataView`, or MessagePack) cuts bandwidth several-fold.
Validate parsed messages with Zod on the server regardless of format.

---

## Latency Handling

For anything real-time, three standard techniques:

**Client-side prediction** — apply local input immediately rather than waiting for the server round trip, or controls feel unresponsive.

**Server reconciliation** — the server's authoritative state arrives with the last input sequence it processed; replay unacknowledged inputs on top of it.

```ts
function onServerState(state: ServerState): void {
  world.setState(state);
  for (const input of pendingInputs.filter((i) => i.seq > state.lastSeq)) {
    world.applyInput(input);      // replay
  }
}
```

**Entity interpolation** — render other players slightly in the past (~100ms) and interpolate between received states, so their motion is smooth despite discrete updates.

These require a **deterministic fixed-timestep simulation**, which is the
architectural reason the fixed timestep matters beyond frame-rate independence.

---

## Colyseus

A room-based authoritative server framework that handles state sync, rooms, and
matchmaking. Removes most of the boilerplate above.

**Note the commitment:** it requires hosting a Node server. This is a real step
up from static hosting on itch.io or Netlify, with ongoing cost and ops. Factor
that into the design decision, not just the code decision.

See `../PLUGINS.md`.

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Connection blocked in production | `ws://` from an HTTPS page — use `wss://` |
| Server falls over after a restart | Reconnect without backoff/jitter |
| Cheating / impossible scores | Client-authoritative state |
| Controls feel laggy | No client-side prediction |
| Other players stutter | No entity interpolation |
| Desyncs that only appear under load | Non-deterministic simulation |
| Dead connections never detected | No heartbeat |

---

## Sources

- https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
- https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API
- https://colyseus.io/
- https://gafferongames.com/ (client prediction and reconciliation)
