# Cocos Creator Networking — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — Major network API changes
- `cc.socket.io` removed — use `socket.io-client` npm package directly
- `cc.WebSocket` removed — use native browser `WebSocket`
- `cc.HttpRequest` → `XMLHttpRequest` (browser native) or `fetch()` (modern)

### v3.5 — `fetch` polyfill standardized
- All platforms (including mini-game) now support `fetch()` API
- Mini-game platforms have a `wx.request` wrapper that `fetch()` adapts to

### v3.8 — WebSocket reliability
- WebSocket reconnection helpers in standard library
- Server-sent events (SSE) helper on web platforms

## Current API Patterns

### HTTP / REST (use `fetch`)
```typescript
async function fetchPlayerProfile(playerId: string): Promise<PlayerProfile> {
    const response = await fetch(`https://api.example.com/players/${playerId}`, {
        method: 'GET',
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
}
```

### WebSocket (browser native)
```typescript
const ws = new WebSocket('wss://example.com/socket');

ws.onopen = () => console.log('connected');
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    // handle message
};
ws.onerror = (err) => console.error(err);
ws.onclose = () => console.log('disconnected');

// Send
ws.send(JSON.stringify({ type: 'move', x: 10, y: 20 }));
```

### Mini-game platform quirks
WeChat / ByteDance / Alipay mini-games require platform-specific APIs for some network operations:

```typescript
import { sys } from 'cc';

if (sys.platform === sys.WECHAT_GAME) {
    // Use wx.request for HTTPS calls (fetch is polyfilled but has quirks)
    wx.request({
        url: 'https://api.example.com/players',
        method: 'GET',
        success: (res) => { /* ... */ },
        fail: (err) => { /* ... */ },
    });

    // WebSocket: use wx.connectSocket
    const ws = wx.connectSocket({ url: 'wss://example.com/socket' });
    ws.onMessage((msg) => { /* ... */ });
}
```

### Server-authoritative pattern (recommended)
- All game state changes go through the server
- Client sends inputs (`{type: 'input', input: {...}, frame: 12}`)
- Server simulates and broadcasts authoritative state (`{type: 'state', entities: {...}}`)
- Client interpolates between received states (lerp at 10–20 Hz)

### Client-side prediction + reconciliation
```typescript
// Client predicts locally, replays inputs when server correction arrives
interface PendingInput { frame: number; input: PlayerInput; }
const pendingInputs: PendingInput[] = [];

function sendInput(input: PlayerInput) {
    const frame = currentFrame++;
    pendingInputs.push({ frame, input });
    ws.send(JSON.stringify({ type: 'input', frame, input }));
    applyInputLocally(input);  // optimistic
}

function onServerState(state: ServerState) {
    rewindTo(state.frame);
    while (pendingInputs.length && pendingInputs[0].frame <= state.frame) {
        pendingInputs.shift();  // acknowledged
    }
    for (const p of pendingInputs) applyInputLocally(p.input);  // replay
}
```

## Common Mistakes
- Using `cc.HttpRequest` (removed in 3.0) — use `fetch` or `XMLHttpRequest`
- Trusting client state — always validate server-side for multiplayer
- Not handling disconnects — WebSocket closes silently; reconnect logic required
- Sending inputs every frame — throttle to 20-30 Hz; interpolate
- JSON.stringify on every send — binary protocols (Protocol Buffers, FlatBuffers) cut bandwidth 5-10x
- Not handling mini-game platform differences — `fetch` works but `wx.request` is sometimes more reliable on WeChat
- Sending strings through WebSocket unnecessarily — server-side parsing overhead
- Not authoring a "demo mode" for offline — players on flaky networks rage-quit
