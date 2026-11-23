#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$sync = Join-Path $PSScriptRoot 'sync-adapter.ps1'
$resolver = Join-Path $PSScriptRoot 'resolve-config.ps1'
$pwsh = (Get-Process -Id $PID).Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Set-FixtureFile {
    param([string]$RelativePath, [string]$Content)
    $path = Join-Path $fixture $RelativePath
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
    [IO.File]::WriteAllText($path, $Content)
}

function Assert-ConfigRows {
    param([string[]]$Output, [string[]]$Expected)
    foreach ($row in $Expected) {
        Assert-True ($row -cin $Output) "Missing config row '$row'. Output:`n$($Output -join "`n")"
    }
}

function Invoke-RegisteredHook {
    param([string]$Directory, [string]$Payload, [switch]$PowerShell)

    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.WorkingDirectory = $Directory
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    if ($PowerShell) {
        $start.FileName = $pwsh
        foreach ($argument in '-NoProfile', '-NonInteractive', '-Command', $hook.command) {
            $start.ArgumentList.Add($argument)
        }
    } elseif ($IsWindows) {
        $start.FileName = $env:ComSpec ?? 'cmd.exe'
        # Match Codex's Windows command runner, including the outer quotes.
        $command = $hook.commandWindows ?? $hook.command
        $start.Arguments = '/C "' + $command + '"'
    } else {
        $start.FileName = '/bin/sh'
        $start.ArgumentList.Add('-c')
        $start.ArgumentList.Add($hook.command)
    }

    $process = [Diagnostics.Process]::Start($start)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write($Payload)
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(15000)) {
            $process.Kill($true)
            throw 'The SessionStart hook did not finish within 15 seconds.'
        }
        Assert-True ($process.ExitCode -eq 0) "SessionStart failed: $($stderr.GetAwaiter().GetResult())"
        Assert-True ([string]::IsNullOrWhiteSpace($stderr.GetAwaiter().GetResult())) 'SessionStart wrote to stderr.'
        return $stdout.GetAwaiter().GetResult().Trim()
    } finally {
        $process.Dispose()
    }
}

# Check the complete set of checked-in adapters and their source pointers.
& $pwsh -NoProfile -File $sync -Check
Assert-True ($LASTEXITCODE -eq 0) 'The checked-in skill and agent entries are out of sync.'
foreach ($directory in Get-ChildItem -Directory -LiteralPath (Join-Path $root '.claude/skills')) {
    $name = $directory.Name
    $source = ".claude/skills/$name/SKILL.md"
    if (-not [IO.File]::Exists((Join-Path $root $source))) { continue }
    $entry = ".agents/skills/$name/SKILL.md"
    Assert-True ([IO.File]::ReadAllText((Join-Path $root $entry)).Contains($source)) "$entry does not point to $source."
}
foreach ($agent in Get-ChildItem -File -Filter '*.md' -LiteralPath (Join-Path $root '.claude/agents')) {
    $source = ".claude/agents/$($agent.Name)"
    $entry = ".codex/agents/$($agent.BaseName).toml"
    Assert-True ([IO.File]::ReadAllText((Join-Path $root $entry)).Contains($source)) "$entry does not point to $source."
}

# Check that the command can load settings from the working checkout.
$settings = & $pwsh -NoProfile -File $resolver -Keys 'framework_version,workflow,project.stage'
Assert-True ($LASTEXITCODE -eq 0) 'Could not resolve settings for the working checkout.'
foreach ($key in 'framework_version', 'workflow', 'project.stage') {
    Assert-True ([bool]($settings -clike "${key}: *")) "Settings for the working checkout omit '$key'."
}

$tempRoot = [IO.Path]::GetTempPath()
$fixtureName = 'ccgs adapter ' + [guid]::NewGuid().ToString('N')
$fixture = Join-Path $tempRoot $fixtureName
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    # A standalone checkout exercises sync without altering project adapters.
    Set-FixtureFile '.codex/scripts/sync-adapter.ps1' ([IO.File]::ReadAllText($sync))
    Set-FixtureFile '.claude/skills/demo/SKILL.md' @'
---
name: demo
description: >-
  A sample workflow with "quotes" and
  a second description line.
disable-model-invocation: true
---
Canonical workflow body.
'@
    Set-FixtureFile '.claude/agents/example.md' @'
---
name: example
description: 'A specialist''s description.'
tools: Read, Bash
---
Canonical role body.
'@
    Set-FixtureFile '.agents/skills/local/SKILL.md' 'Handwritten skill'
    Set-FixtureFile '.codex/agents/local.toml' 'Handwritten agent'
    $fixtureSync = Join-Path $fixture '.codex/scripts/sync-adapter.ps1'
    & $pwsh -NoProfile -File $fixtureSync
    Assert-True ($LASTEXITCODE -eq 0) 'Could not generate the fixture adapters.'

    $skillPath = Join-Path $fixture '.agents/skills/demo/SKILL.md'
    $agentPath = Join-Path $fixture '.codex/agents/example.toml'
    $policyPath = Join-Path $fixture '.agents/skills/demo/agents/openai.yaml'
    $skillText = [IO.File]::ReadAllText($skillPath)
    $agentText = [IO.File]::ReadAllText($agentPath)
    Assert-True ($skillText.Contains('.claude/skills/demo/SKILL.md') -and
        $skillText.Contains('and a second description line.')) 'Skill adapter lost its source pointer or description.'
    Assert-True ($agentText.Contains('.claude/agents/example.md') -and
        $agentText.Contains("A specialist's description.")) 'Agent adapter lost its source pointer or description.'
    Assert-True ([IO.File]::ReadAllText($policyPath).Contains('allow_implicit_invocation: false')) 'Explicit invocation policy was lost.'

    $beforeSync = (Get-Item -LiteralPath $skillPath).LastWriteTimeUtc
    $syncOutput = & $pwsh -NoProfile -File $fixtureSync
    Assert-True ($LASTEXITCODE -eq 0 -and $syncOutput -like '*0 file changes*' -and
        (Get-Item -LiteralPath $skillPath).LastWriteTimeUtc -eq $beforeSync) 'A repeat sync rewrote the generated skill.'

    $stalePath = '.codex/agents/retired.toml'
    Set-FixtureFile $stalePath $agentText
    [IO.File]::AppendAllText($skillPath, "`nDrift.`n")
    [IO.File]::Delete($agentPath)
    $driftOutput = & $pwsh -NoProfile -File $fixtureSync -Check 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -ne 0 -and $driftOutput -match 'Changed .*SKILL\.md' -and
        $driftOutput -match 'Missing .*example\.toml' -and $driftOutput -match 'Stale .*retired\.toml') 'Check did not report each form of adapter drift.'
    Assert-True ([IO.File]::ReadAllText($skillPath).Contains('Drift.') -and -not [IO.File]::Exists($agentPath) -and
        [IO.File]::Exists((Join-Path $fixture $stalePath))) 'Check altered files while reporting drift.'

    & $pwsh -NoProfile -File $fixtureSync
    Assert-True ($LASTEXITCODE -eq 0) 'Could not repair adapter drift.'
    & $pwsh -NoProfile -File $fixtureSync -Check
    Assert-True ($LASTEXITCODE -eq 0) 'Drift persisted after sync.'
    Assert-True ([IO.File]::ReadAllText((Join-Path $fixture '.agents/skills/local/SKILL.md')) -ceq 'Handwritten skill' -and
        [IO.File]::ReadAllText((Join-Path $fixture '.codex/agents/local.toml')) -ceq 'Handwritten agent') 'Sync altered handwritten entries.'
    Write-Host 'PASS: entry coverage, metadata, no-op sync, and read-only drift detection'

    $projectSettings = @'
schema_version: 1
framework:
  version: 1.3.0
modes:
  rigor: full
  workflow: standard
modes:
   review_mode: 'lean' # quoted scalar
   automation: guided
project:
  stage: Technical Setup
'@
    $windowsYaml = $projectSettings -replace '\r?\n', "`r`n"
    [IO.File]::WriteAllText((Join-Path $fixture 'project.yaml'), $windowsYaml, [Text.UTF8Encoding]::new($true))
    Set-FixtureFile 'project.local.yaml' @'
modes:
  automation: autonomous
  review_mode: typo
  rigor: minimal
'@
    Set-FixtureFile 'production/stage.txt' 'Systems Design'
    Set-FixtureFile 'production/review-mode.txt' 'solo'
    $keys = 'automation,review_mode,workflow,docs.density,project.stage'
    $settings = & $pwsh -NoProfile -File $resolver -Root $fixture -Keys $keys
    Assert-True ($LASTEXITCODE -eq 0) 'Could not resolve the configured test project.'
    Assert-ConfigRows $settings @(
        'automation: autonomous (project.local.yaml)'
        'review_mode: lean (project.yaml)'
        'workflow: standard (project.yaml)'
        'docs.density: thorough (rigor:full)'
        'project.stage: Technical Setup (project.yaml)'
    )
    $notes = $settings -clike 'notes: *'
    Assert-True ($notes -match 'invalid value' -and $notes -match 'not locally overridable' -and
        $notes -match 'duplicate key') 'Config diagnostics lost invalid, locked, or duplicate settings.'

    Set-FixtureFile 'project.yaml' @'
schema_version: 1
framework:
  version: 1.3.0
modes:
  rigor: standard
'@
    $settings = & $pwsh -NoProfile -File $resolver -Root $fixture -Keys $keys
    Assert-True ($LASTEXITCODE -eq 0) 'Could not resolve settings with legacy fallbacks.'
    Assert-ConfigRows $settings @(
        'review_mode: solo (production/review-mode.txt)'
        'project.stage: Systems Design (production/stage.txt)'
        'workflow: standard (rigor:standard)'
        'docs.density: balanced (rigor:standard)'
    )
    Write-Host 'PASS: project settings, precedence, provenance, and diagnostics'

    $hookConfig = Get-Content -Raw -LiteralPath (Join-Path $root '.codex/hooks.json') | ConvertFrom-Json
    $hooks = @($hookConfig.hooks.SessionStart.hooks)
    Assert-True ($hooks.Count -eq 1 -and $hooks[0].type -ceq 'command') 'Expected one SessionStart command hook.'
    $hook = $hooks[0]
    foreach ($path in '.codex/scripts/session-start.ps1', '.codex/scripts/resolve-config.ps1', '.claude/hooks/yaml-helper.sh') {
        Set-FixtureFile $path ([IO.File]::ReadAllText((Join-Path $root $path)))
    }
    git -C $fixture init --quiet
    Assert-True ($LASTEXITCODE -eq 0) 'Could not initialize the hook test checkout.'

    $nested = Join-Path $fixture 'nested project folder'
    [IO.Directory]::CreateDirectory($nested) | Out-Null
    $sessions = @(
        @{ Directory = $fixture; Cwd = $fixture }
        @{ Directory = $nested; Cwd = $nested }
        @{ Directory = $nested; Cwd = $nested; PowerShell = $true }
        if ($IsWindows -and $nested -match '^[A-Za-z]:\\') {
            @{ Directory = $nested; Cwd = '\\?\' + $nested }
        }
    )
    foreach ($session in $sessions) {
        $payload = @{ cwd = $session.Cwd; hook_event_name = 'SessionStart'; source = 'startup' } | ConvertTo-Json -Compress
        $output = Invoke-RegisteredHook $session.Directory $payload -PowerShell:([bool]$session.PowerShell) | ConvertFrom-Json
        Assert-True ($output.hookSpecificOutput.hookEventName -ceq 'SessionStart') 'Hook did not return a SessionStart response.'
        $context = $output.hookSpecificOutput.additionalContext -split '\r?\n'
        Assert-ConfigRows $context @(
            'CCGS project settings at session start'
            'automation: autonomous (project.local.yaml)'
            'project.stage: Systems Design (production/stage.txt)'
        )
        Assert-True (-not ($context -clike 'notes: *')) 'SessionStart context included raw configuration diagnostics.'
    }
    $invalid = Invoke-RegisteredHook $fixture '{invalid'
    Assert-True ($invalid -eq '') 'Malformed hook input produced output.'
    $payload = @{ cwd = $fixture; hook_event_name = 'Stop' } | ConvertTo-Json -Compress
    $otherEvent = Invoke-RegisteredHook $fixture $payload
    Assert-True ($otherEvent -eq '') 'An unrelated hook event produced output.'
    $payload = @{ cwd = $tempRoot; hook_event_name = 'SessionStart' } | ConvertTo-Json -Compress
    $foreign = Invoke-RegisteredHook $fixture $payload
    Assert-True ($foreign -eq '') 'A hook input outside the checkout produced output.'
    Write-Host 'PASS: registered SessionStart command, path handling, and ignored input'
} finally {
    $resolved = (Resolve-Path -LiteralPath $fixture).ProviderPath
    if ([IO.Path]::GetRelativePath($tempRoot, $resolved) -ceq $fixtureName) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
