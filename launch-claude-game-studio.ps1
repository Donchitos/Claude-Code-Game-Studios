param(
    [switch]$DryRun,
    [string]$AuthStatusJson
)

$ErrorActionPreference = "Stop"

function Convert-ClaudeAuthStatus {
    param([string[]]$JsonText)

    if (-not $JsonText) {
        throw "claude auth status did not return a JSON response."
    }

    $auth = ($JsonText -join [Environment]::NewLine) | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $auth.loggedIn) {
        throw "claude auth status JSON is missing the loggedIn field."
    }

    return $auth
}

function Add-PathEntry {
    param([string]$PathEntry)
    if ($PathEntry -and (Test-Path -LiteralPath $PathEntry) -and ($env:Path -notlike "*$PathEntry*")) {
        $env:Path = "$PathEntry;$env:Path"
    }
}

function Require-Command {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Missing command: $Name"
    }
    return $cmd.Source
}

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ProjectDir

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath;$env:Path"

Add-PathEntry "C:\Program Files\Git\cmd"
Add-PathEntry "C:\Program Files\Git\bin"
Add-PathEntry "C:\Program Files\nodejs"
Add-PathEntry "$env:APPDATA\npm"
Add-PathEntry "$env:LOCALAPPDATA\Microsoft\WinGet\Links"

Write-Host ""
Write-Host "Claude Code Game Studios Launcher"
Write-Host "Project: $ProjectDir"
Write-Host ""

$required = @("git", "node", "npm", "bash", "jq", "claude")
foreach ($name in $required) {
    $source = Require-Command $name
    Write-Host ("OK  {0,-6} {1}" -f $name, $source)
}

Write-Host ""
Write-Host "Versions:"
git --version
node --version
npm --version
jq --version
claude --version

Write-Host ""
Write-Host "Checking Claude login..."
try {
    if ($PSBoundParameters.ContainsKey("AuthStatusJson")) {
        $auth = Convert-ClaudeAuthStatus $AuthStatusJson
    } else {
        $authJson = claude auth status 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "claude auth status exited with code $LASTEXITCODE."
        }

        $auth = Convert-ClaudeAuthStatus $authJson
    }
} catch {
    throw "Unable to read Claude login status. Run 'claude auth status' manually to see the underlying error. Details: $($_.Exception.Message)"
}

if (-not $auth.loggedIn) {
    Write-Host ""
    Write-Host "Claude Code is installed, but you are not logged in."
    Write-Host "A login window will open now. Finish login, then run this launcher again."
    Write-Host ""

    if (-not $DryRun) {
        claude auth login
    }

    exit 0
}

Write-Host "Logged in. Starting Claude Code..."
Write-Host ""
Write-Host "When Claude opens, type: /start"
Write-Host ""

if (-not $DryRun) {
    claude
}
