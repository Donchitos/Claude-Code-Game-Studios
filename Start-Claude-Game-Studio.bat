@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -File "%SCRIPT_DIR%launch-claude-game-studio.ps1"
endlocal
