# BRAWLZONE — Google Play Release Checkliste

## 1. Accounts einrichten (einmalig, ~1-2 Tage)

- [ ] **Google Play Console** — https://play.google.com/console
  - Einmalige Gebühr: $25
  - Konto mit trust.pulse1@gmail.com anlegen
- [ ] **Expo Account** — https://expo.dev
  - Kostenlos, für EAS Build benötigt
  - `npx eas login` im Terminal

---

## 2. Supabase Produktion einrichten

- [ ] Neues Supabase-Projekt anlegen (Prod, nicht Dev)
- [ ] SQL aus `server/src/db/schema.sql` ausführen
- [ ] `mobile/.env` erstellen (Kopie von `.env.example`, echte Keys eintragen)
- [ ] `server/.env` erstellen (Kopie von `.env.example`, echte Keys eintragen)
- [ ] Google OAuth in Supabase aktivieren:
  - Supabase Dashboard → Authentication → Providers → Google
  - Client ID + Secret aus Google Cloud Console eintragen
  - Redirect URL in Google Cloud eintragen

---

## 3. EAS Projekt verknüpfen

```bash
cd mobile
npx eas init          # erstellt Project ID auf expo.dev
# Project ID automatisch in app.json eingetragen
```

- [ ] `app.json` → `extra.eas.projectId` ist gesetzt

---

## 4. Server deployen (Produktion)

**Option A: Railway (empfohlen, einfachste Einrichtung)**
```bash
# railway.app → New Project → Deploy from GitHub
# Environment Variables setzen (aus server/.env.example)
# Port: 3001 (Railway setzt PORT automatisch)
```

**Option B: Render**
- render.com → New Web Service → GitHub Repo
- Build Command: `cd server && npm install && npm run build`
- Start Command: `cd server && npm start`

- [ ] Server läuft und `/health` antwortet mit 200
- [ ] `eas.json` → `production.env.EXPO_PUBLIC_SERVER_URL` auf echte URL setzen

---

## 5. APK/AAB bauen (EAS Build)

```bash
cd mobile

# Test-APK (intern, zum Testen auf Gerät)
npx eas build --platform android --profile preview

# Produktions-AAB (für Google Play)
npx eas build --platform android --profile production
```

- [ ] Preview-APK auf echtem Android-Gerät getestet
- [ ] Match-Flow komplett durchgespielt (Login → Queue → Match → Ergebnis)
- [ ] Kein Crash beim Start

---

## 6. Google Play Store Listing

### Grunddaten
- [ ] App-Name: **BRAWLZONE**
- [ ] Kurzbeschreibung (80 Zeichen): *Echtzeit PvP-Brawler — queue, fight, win!*
- [ ] Vollständige Beschreibung (4000 Zeichen max) — Gameplay, Modi, Features
- [ ] App-Kategorie: Spiele → Action

### Assets
- [ ] **Icon** 512x512 PNG — `assets/icon.png` skalieren oder neu erstellen
- [ ] **Feature Graphic** 1024x500 PNG — Banner für Store-Listing
- [ ] **Screenshots** mind. 2, empfohlen 4-8:
  - Home Screen (Mode-Auswahl)
  - Character Select
  - Match in Aktion (Arena + HUD)
  - Match Results
- [ ] Promo-Video (YouTube-Link, optional aber empfohlen)

### Inhaltsbewertung
- [ ] Fragebogen im Play Console ausfüllen → Gewalt: Gering (cartoon)
- [ ] Erwartetes Rating: **PEGI 7** / **USK 6**

---

## 7. Datenschutz & Rechtliches

- [ ] **Privacy Policy** (URL nötig, z.B. auf GitHub Pages oder Notion):
  - Welche Daten werden gesammelt (Email, Username, Spielstatistiken)
  - Supabase als Datenbasis nennen
  - Kontakt-Email eintragen
- [ ] **Data Safety** Formular in Play Console ausfüllen:
  - Daten gesammelt: Email-Adresse (Pflicht, verschlüsselt)
  - Daten geteilt: Keine
  - Sicherheitspraktiken: Daten in Transit verschlüsselt (HTTPS/WSS)

---

## 8. Testtrack → Production

```
Internal Testing → Closed Testing → Open Testing → Production
```

1. AAB in **Internal Testing** hochladen (sofort für Test-Accounts verfügbar)
2. Auf 2-3 echten Android-Geräten testen
3. Wenn stabil: auf **Closed Testing** hochstufen
4. Nach erfolgreichen Tests: **Production** Release beantragen
   - Google prüft ~3-7 Werktage

---

## 9. Schnell-Befehle Referenz

```bash
# Lokale Entwicklung
cd BRAWLZONE && npm run dev        # Server + Metro gleichzeitig

# Nur Server
cd server && npm run dev

# Android Emulator
cd mobile && npm run android

# Preview APK bauen (braucht Expo Account)
cd mobile && npx eas build --platform android --profile preview

# Build-Status prüfen
npx eas build:list

# Logs eines laufenden Builds
npx eas build:view
```

---

## Status (Stand 2026-05-26)

| Bereich | Status |
|---------|--------|
| Auth (Email + Google OAuth) | ✅ Implementiert |
| Matchmaking-Server (3 Modi) | ✅ Implementiert |
| Game Loop (Server-autoritativ 20Hz) | ✅ Implementiert |
| Match Screen + Arena | ✅ Implementiert |
| Touch Controls (Joystick + Angriff) | ✅ Implementiert |
| Match Results | ✅ Implementiert |
| Character System (3 Chars) | ✅ Implementiert |
| Character Select Screen | ✅ Implementiert |
| Bot AI (10s Fill-Timer) | ✅ Implementiert |
| EAS Build Konfiguration | ✅ Konfiguriert |
| Supabase Schema | ✅ Bereit |
| App Assets (Placeholder) | ✅ Placeholder |
| Google Play Account | ❌ Noch anlegen |
| Expo Account + EAS init | ❌ Noch anlegen |
| Prod-Server deployed | ❌ Noch deployen |
| Echte App-Icons | ❌ Designer nötig |
| Store Listing Assets | ❌ Screenshots nötig |
| Privacy Policy URL | ❌ Noch erstellen |
| Google OAuth konfiguriert | ❌ Supabase Prod |
