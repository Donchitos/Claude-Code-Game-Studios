@echo off
setlocal enabledelayedexpansion

:: Initialize variables
set "godot_binary="
set "filtered_args="

:: Process all arguments
set "i=0"
:parse_args
if "%~1"=="" goto end_parse_args

if "%~1"=="--godot_binary" (
    set "godot_binary=%~2"
    shift
    shift
) else (
    set "filtered_args=!filtered_args! %~1"
    shift
)
goto parse_args
:end_parse_args

:: If --godot_binary wasn't provided, fallback to environment variable
if "!godot_binary!"=="" (
    set "godot_binary=%GODOT_BIN%"
)

:: Check if we have a godot_binary value from any source
if "!godot_binary!"=="" (
    echo Godot binary path is not specified.
    echo Please either:
    echo   - Set the environment variable: set GODOT_BIN=C:\path\to\godot.exe
    echo   - Or use the --godot_binary argument: --godot_binary C:\path\to\godot.exe
    exit /b 1
)

:: Check if the Godot binary exists
if not exist "!godot_binary!" (
    echo Error: The specified Godot binary '!godot_binary!' does not exist.
    exit /b 1
)

:: Get Godot version and check if it's a mono build
for /f "tokens=*" %%i in ('"!godot_binary!" --version') do set GODOT_VERSION=%%i
echo !GODOT_VERSION! | findstr /I "mono" >nul
if !errorlevel! equ 0 (
    echo Godot .NET detected
    echo Compiling c# classes ... Please Wait
    dotnet build --debug
    echo done !errorlevel!
)

:: Run the tests with the filtered arguments.
:: --remote-debug tcp://127.0.0.1:0 prevents Godot from activating its local interactive
:: CLI debugger, which would cause an endless 'debug>' loop on script parse errors.
:: Port 0 is used intentionally as it is never bound, so the connection is always refused.
"!godot_binary!" --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd !filtered_args!
set exit_code=%ERRORLEVEL%
echo Run tests ends with %exit_code%

:: Run the copy log command
"!godot_binary!" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd !filtered_args! > nul
set exit_code2=%ERRORLEVEL%
exit /b %exit_code%
