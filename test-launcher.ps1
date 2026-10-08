param()

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Launcher = Join-Path $ScriptDir "launch-claude-game-studio.ps1"

function Invoke-LauncherCase {
    param(
        [string]$Name,
        [string]$AuthStatusJson,
        [int]$ExpectedExitCode,
        [string]$ExpectedText
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & powershell.exe -NoProfile -File $Launcher -DryRun -AuthStatusJson $AuthStatusJson 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $text = $output -join [Environment]::NewLine

    if ($exitCode -ne $ExpectedExitCode) {
        throw "$Name failed: expected exit code $ExpectedExitCode, got $exitCode. Output: $text"
    }

    if ($text -notlike "*$ExpectedText*") {
        throw "$Name failed: expected output containing '$ExpectedText'. Output: $text"
    }

    Write-Host "PASS $Name"
}

Invoke-LauncherCase -Name "logged-in" -AuthStatusJson '{"loggedIn":true}' -ExpectedExitCode 0 -ExpectedText "Logged in. Starting Claude Code..."
Invoke-LauncherCase -Name "logged-out" -AuthStatusJson '{"loggedIn":false}' -ExpectedExitCode 0 -ExpectedText "Claude Code is installed, but you are not logged in."
Invoke-LauncherCase -Name "malformed-json" -AuthStatusJson '{bad json' -ExpectedExitCode 1 -ExpectedText "Unable to read Claude login status."
