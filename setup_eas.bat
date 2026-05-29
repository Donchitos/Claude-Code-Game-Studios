@echo off
chcp 65001 >nul
echo.
echo  =========================================
echo   BRAWLZONE -- EAS Setup fuer Google Play
echo  =========================================
echo.

echo [1/4] Node.js Version pruefen...
node --version
npm --version
echo.

echo [2/4] EAS CLI global installieren...
call npm install -g eas-cli
echo.

echo [3/4] Expo Login (Browser wird geoeffnet -- bitte einloggen)...
cd /d "C:\Users\oerdo\BRAWLZONE\mobile"
call npx eas login
echo.

echo [4/4] EAS Projekt initialisieren (verknuepft app.json mit Expo)...
call npx eas init
echo.

echo  =========================================
echo   Setup abgeschlossen!
echo   Naechster Schritt: npx eas build starten
echo  =========================================
echo.
pause
