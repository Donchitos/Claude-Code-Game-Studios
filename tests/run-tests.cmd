@echo off
:: Runs all GdUnit4 tests headless (unit + integration).
:: Set GODOT_BIN to your Godot executable; falls back to the known local install.
setlocal
if "%GODOT_BIN%"=="" set "GODOT_BIN=C:\Users\Leo\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
if not exist "%GODOT_BIN%" (
    echo Godot executable not found: %GODOT_BIN%
    echo Set GODOT_BIN to your Godot 4.7 executable and retry.
    exit /b 1
)
"%GODOT_BIN%" --headless --path "%~dp0..\neues-spiel" -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/unit -a res://tests/integration
exit /b %ERRORLEVEL%
