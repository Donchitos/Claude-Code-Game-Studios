# BRAWLZONE — Deployment Guide

## Stack
- **Server**: Node.js 22 on Railway
- **Database**: PostgreSQL via Supabase
- **Cache**: Redis (Railway add-on)
- **Auth**: Supabase Auth (JWT RS256)
- **Mobile**: React Native + Expo EAS Build (iOS + Android)

---

## 1. Supabase Setup

### Create project
1. Go to https://supabase.com → New Project
2. Note your **Project URL** and **anon key** (for mobile) and **service key** (for server)
3. Note your **JWT Secret** (Settings → API → JWT Settings)

### Apply schema
1. Open Supabase Dashboard → SQL Editor
2. Run `server/src/db/schema.sql` — this creates all tables and the auto-profile trigger

### Enable Auth providers
- Email/Password: enabled by default
- Google OAuth: Authentication → Providers → Google → enable + add OAuth credentials
- Apple OAuth: Authentication → Providers → Apple → enable + add Apple credentials

---

## 2. Server Deployment (Railway)

### Environment variables
```
PORT=3001
NODE_ENV=production
CLIENT_ORIGIN=exp://your-expo-app-url   # or your production app URL
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=eyJ...             # service role key (never expose to client)
SUPABASE_JWT_SECRET=your-jwt-secret
DATABASE_URL=postgresql://...           # from Supabase: Settings → Database → Connection string
REDIS_URL=redis://...                   # from Railway Redis add-on
```

### Deploy
```bash
# Push to main — Railway auto-deploys
git push origin main

# Or manually via CLI
railway up
```

### Verify
```
curl https://your-railway-url.railway.app/health
# → { "status": "ok", "ts": 1234567890 }
```

---

## 3. Mobile App (Expo EAS)

### Environment variables
Create `mobile/.env` (gitignored):
```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...    # anon/public key (safe to expose)
EXPO_PUBLIC_SERVER_URL=https://your-railway-url.railway.app
```

### Build
```bash
cd mobile
npm install

# Development build (runs on Expo Go or dev client)
npx expo start

# Production build via EAS
eas build --platform ios
eas build --platform android

# Submit to stores
eas submit --platform ios
eas submit --platform android
```

### OTA updates
```bash
eas update --branch production --message "Bug fix"
```

---

## 4. Local Development

### Prerequisites
- Node.js 22+
- Redis running locally (`redis-server`)
- Supabase local OR use cloud Supabase with development project

### Start server
```bash
cd server
cp .env.example .env   # fill in your values
npm install
npm run dev            # starts on :3001 with hot reload
```

### Start mobile
```bash
cd mobile
npm install
npx expo start         # opens Expo Go QR code
```

### Run all server tests
```bash
cd server
npm test               # 276 tests, ~10s
```

---

## 5. Architecture Overview

```
Mobile App (React Native/Expo)
  ↕ Supabase Auth (JWT)
  ↕ REST API: /v1/profile, /v1/catalog
  ↕ Socket.io: matchmaking, game state, profile:refresh
         ↕
Server (Node.js / Railway)
  - 20Hz authoritative game loop (GameRoom.ts)
  - Matchmaking with bot backfill (MatchmakingQueue.ts, BracketMatcher)
  - Session state machine (forming → char_select → active → ended)
  - Economy systems (Currency, Inventory, XP, MMR, Rewards)
  - Content Catalog (35 records: 8 chars, 18 abilities, 3 modes, 6 maps)
         ↕
Supabase (PostgreSQL + Auth)
  - player_profiles, entitlements, economy_transactions
  - character_xp, xp_grants, match_records
```

---

## 6. Game Features

| Feature | Status |
|---|---|
| Email/password auth | ✅ |
| Google OAuth | ✅ |
| Matchmaking: 1v1 Duel, 3v3 Squad, FFA 8-player | ✅ |
| Bot backfill (45s timeout) | ✅ |
| 20Hz authoritative server game loop | ✅ |
| 8 characters (Vex, Zook, Sera, Fen, Grim, Dash, Colt, Nyx) | ✅ |
| 18 abilities with cooldowns, status effects | ✅ |
| 3 game modes with win conditions | ✅ |
| BURNING bypasses SHIELDED | ✅ |
| Joystick + attack/skill/dodge controls | ✅ |
| HP bars, match timer | ✅ |
| Match results with XP + diamond rewards | ✅ |
| Player profile with MMR (Elo) | ✅ |
| Economy (coins, diamonds, inventory) | ✅ |
| Session persistence (disconnect → reconnect grace) | ✅ |
| Structured JSON logging (pino) | ✅ |
| Analytics event system | ✅ |
| Remote config / live tuning | ✅ |
| Content catalog with overlay | ✅ |
