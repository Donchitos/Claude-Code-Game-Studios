#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

if (-not [Console]::IsInputRedirected) { return }

function Get-ComparablePath([string] $Path) {
    if ($IsWindows) {
        # Codex can send a verbatim Windows path for the same directory.
        $Path = $Path -replace '^\\\\\?\\UNC\\', '\\' -replace '^\\\\\?\\(?=[A-Za-z]:\\)', ''
    }
    [IO.Path]::GetFullPath($Path)
}

try {
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
    $event = [Console]::In.ReadToEnd() | ConvertFrom-Json -AsHashtable -Depth 32 -NoEnumerate
    if ($event -isnot [System.Collections.IDictionary] -or $event.hook_event_name -cne 'SessionStart' -or
        $event.cwd -isnot [string] -or -not [IO.Path]::IsPathFullyQualified($event.cwd)) { return }

    $root = Get-ComparablePath (Join-Path $PSScriptRoot '../..')
    $relativeCwd = [IO.Path]::GetRelativePath($root, (Get-ComparablePath $event.cwd)).Replace('\', '/')
    if ($relativeCwd -eq '..' -or $relativeCwd.StartsWith('../') -or [IO.Path]::IsPathRooted($relativeCwd)) {
        return
    }
} catch {
    return
}

$resolver = Join-Path $PSScriptRoot 'resolve-config.ps1'
if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) { return }

try {
    # Keep diagnostics with the on-demand resolver, where their YAML excerpts are useful.
    $settings = & $resolver -Root $root -Keys 'project.stage,automation,review_mode' |
        Where-Object { $_ -cnotlike 'notes:*' }
    $context = @(
        'CCGS project settings at session start'
        $settings
        'Resolve configuration again when a workflow needs current settings.'
    ) -join "`n"
    @{
        hookSpecificOutput = @{
            hookEventName = 'SessionStart'
            additionalContext = $context
        }
    } | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
} catch {
    @{ systemMessage = 'CCGS could not read project settings. Run .codex/scripts/resolve-config.ps1 for details.' } |
        ConvertTo-Json -Compress
}
