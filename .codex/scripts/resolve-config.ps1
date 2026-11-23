#Requires -Version 7.0
[CmdletBinding()]
param(
    [string[]] $Keys,
    [string] $System,
    [string] $Root = (Join-Path $PSScriptRoot '../..')
)

$ErrorActionPreference = 'Stop'
$rootItem = Get-Item -LiteralPath $Root
if (-not $rootItem.PSIsContainer) { throw "CCGS project root must be a directory: $Root" }
$Root = $rootItem.FullName
$frameworkRoot = Join-Path $PSScriptRoot '../..'
$notes = [System.Collections.Generic.List[string]]::new()

# The same tables drive the Claude reader and writer. Read their literal data
# from the checked-in helper, without loading it as executable code.
$canonical = Get-Content -Raw -LiteralPath (Join-Path $frameworkRoot '.claude/hooks/yaml-helper.sh')
function Read-CanonicalTable([string] $Name) {
    $match = [regex]::Match($canonical, ('(?m)^_yaml_helper_' + $Name + '="(?<body>[^"]+)"\r?$'))
    if (-not $match.Success) { throw "The CCGS configuration table '$Name' was not found in yaml-helper.sh." }
    $match.Groups['body'].Value -split '\r?\n' | Where-Object { $_ -ne '\' }
}

function Read-KeyValueTable([string[]] $Rows, [string] $Delimiter) {
    $table = [hashtable]::new([StringComparer]::Ordinal)
    foreach ($row in $Rows) {
        $key, $value = $row -csplit $Delimiter, 2
        if (-not $key -or -not $value) { throw "Invalid CCGS configuration table row '$row'." }
        $table.Add($key, $value)
    }
    $table
}

$enums = Read-KeyValueTable (Read-CanonicalTable enums) '::'
$enums['testing.strict'] = $enums['testing.strict.logic']
$defaults = Read-KeyValueTable (Read-CanonicalTable defaults) '::'
$localKeys = @(Read-CanonicalTable locally_overridable)
$legacyFiles = Read-KeyValueTable (Read-CanonicalTable legacy_files) '::'
$rigorRows = Read-KeyValueTable (Read-CanonicalTable rigor_expansion) '::'

function Read-Scalar([string] $Value) {
    $Value = $Value.Trim()
    if ($Value.StartsWith('#')) { return '' }
    if ($Value.StartsWith('"') -or $Value.StartsWith("'")) {
        $end = $Value.IndexOf($Value[0], 1)
        if ($end -ge 0) { return $Value.Substring(1, $end - 1) }
        return $Value.Substring(1)
    }
    ($Value -csplit ' #', 2)[0].TrimEnd()
}

function Read-InlineList([string] $Value) {
    # Anchor each element to the previous one. Quoted commas and brackets are data.
    $element = '\G(?:\[|,)\s*(?:"(?<item>[^"]*)"|''(?<item>[^'']*)''|(?<item>[^"'',\]]*?))\s*(?=[,\]])'
    foreach ($match in [regex]::Matches($Value, $element)) {
        $valueText = $match.Groups['item'].Value.Trim()
        if ($valueText) { $valueText }
    }
}

function Read-ProjectYaml([string] $Name) {
    # CCGS project files use indented mappings, scalar values and flat lists.
    # A repeated mapping merges; a later scalar or list replaces its prior value.
    $map = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
    $file = Join-Path $Root $Name
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $map }

    $lines = [IO.File]::ReadAllLines($file)
    if ($Name -eq 'project.yaml' -and -not $lines.Count) { $notes.Add('project.yaml is EMPTY; defaults in use') }
    $parents = [System.Collections.Generic.Stack[object]]::new()
    $parents.Push(@{ Indent = -1; Value = $map; Path = '' })
    $seen = [hashtable]::new([StringComparer]::Ordinal)
    $blockIndent = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].TrimStart(' ')
        if ($line -match '^\s*(?:#|$)') { continue }
        $indent = $lines[$i].Length - $line.Length
        if ($blockIndent -ge 0 -and $indent -gt $blockIndent) { continue }
        $blockIndent = -1
        if ($line.StartsWith("`t")) {
            $notes.Add("${Name}: tab indentation on line $($i + 1); ignored")
            continue
        }
        while ($parents.Peek().Indent -ge $indent) { $null = $parents.Pop() }
        $parent = $parents.Peek()
        if ($line -match '^-[ ]+(?<item>.+)$') {
            $item = Read-Scalar $Matches.item
            if ($item -match '^[|>][-+0-9]*$') { $blockIndent = $indent; continue }
            if ($parent.Indent -ge 0 -and $parent.Value -is [System.Collections.IDictionary] -and $parent.Value.Count -eq 0) {
                $parent.Value = [System.Collections.Generic.List[string]]::new()
                $parent.Owner[$parent.Key] = $parent.Value
            }
            if ($item -and $parent.Value -is [System.Collections.Generic.List[string]]) { $parent.Value.Add($item) }
            continue
        }
        if ($parent.Value -isnot [System.Collections.IDictionary] -or $line -notmatch '^(?<key>[^:#\s][^:]*?)\s*:\s*(?<value>.*)$') { continue }
        $key = $Matches.key
        $rawValue = $Matches.value.Trim()
        $path = if ($parent.Path) { "$($parent.Path).$key" } else { $key }
        if ($seen.ContainsKey($path)) { $notes.Add("${Name}: duplicate key $path (lines $($seen[$path]), $($i + 1)); merged mappings or used the later value") }
        $seen[$path] = $i + 1

        if ($rawValue.StartsWith('[')) {
            $parent.Value[$key] = @(Read-InlineList $rawValue)
            continue
        }
        $value = Read-Scalar $rawValue
        if ($value) {
            $parent.Value[$key] = $value
            if ($rawValue -match '^[|>][-+0-9]*\s*(#.*)?$') { $blockIndent = $indent }
            continue
        }
        if ($parent.Value[$key] -isnot [System.Collections.IDictionary]) {
            $parent.Value[$key] = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
        }
        $parents.Push(@{ Indent = $indent; Value = $parent.Value[$key]; Path = $path; Key = $key; Owner = $parent.Value })
    }
    $map
}

function Get-YamlNode([System.Collections.IDictionary] $Map, [string] $Path) {
    $node = $Map
    foreach ($key in $Path.Split('.')) {
        if ($node -isnot [System.Collections.IDictionary]) { return }
        $node = $node[$key]
    }
    return ,$node
}

function Get-YamlScalar([System.Collections.IDictionary] $Map, [string] $Path) {
    $value = Get-YamlNode $Map $Path
    if ($value -is [string] -and $value -notin @('null', '~')) { $value }
}

function Get-YamlList([System.Collections.IDictionary] $Map, [string] $Path) {
    $value = Get-YamlNode $Map $Path
    if ($value -is [System.Collections.IList]) { $value }
}

function Test-Allowed([string] $Path, [string] $Value, [string] $Source) {
    if (-not $Value) { return $false }
    if ($enums.ContainsKey($Path) -and $Value -cnotin $enums[$Path].Split('|')) {
        $notes.Add("${Source}: invalid value '$Value' for $Path; expected $($enums[$Path]); ignored")
        return $false
    }
    return $true
}

function Find-LocalLockedKeys([System.Collections.IDictionary] $Map, [string] $Parent) {
    foreach ($key in $Map.Keys) {
        $path = if ($Parent) { "$Parent.$key" } else { $key }
        if ($path -ceq 'schema_version' -or $path -ceq 'framework' -or $path -cin $localKeys) { continue }
        if ($Map[$key] -is [System.Collections.IDictionary] -and $Map[$key].Count) {
            Find-LocalLockedKeys $Map[$key] $path
        } elseif ($Map[$key] -isnot [System.Collections.IDictionary]) {
            $path
        }
    }
}

$project = Read-ProjectYaml 'project.yaml'
$local = Read-ProjectYaml 'project.local.yaml'
$localEnabled = Test-Path -LiteralPath (Join-Path $Root 'project.yaml') -PathType Leaf
if (-not $localEnabled) {
    $notes.Add('project.yaml absent; defaults and legacy mirrors in use')
    if (Test-Path -LiteralPath (Join-Path $Root 'project.local.yaml') -PathType Leaf) {
        $notes.Add('project.local.yaml requires a project.yaml base; ignored')
    }
}
$locked = @(Find-LocalLockedKeys $local '')
if ($locked.Count) { $notes.Add("project.local.yaml: not locally overridable, ignored: $($locked -join ', ')") }

# Validate the YAML sources once, including settings outside the requested keys.
foreach ($path in ($enums.Keys | Sort-Object)) {
    foreach ($source in @('project.yaml', 'project.local.yaml')) {
        $map = if ($source -eq 'project.yaml') { $project } else { $local }
        $value = Get-YamlScalar $map $path
        if ($value -and -not (Test-Allowed $path $value $source)) {
            $node = $map
            $parts = $path.Split('.')
            foreach ($part in ($parts | Select-Object -SkipLast 1)) { $node = $node[$part] }
            $node.Remove($parts[-1])
        }
    }
}

$rigor = (Get-YamlScalar $project 'modes.rigor') ?? $defaults['modes.rigor']
$expanded = Read-KeyValueTable ($rigorRows[$rigor].Split(',')) '='

function Resolve-Setting([string] $Path) {
    if ($localEnabled -and $Path -cin $localKeys) {
        $value = Get-YamlScalar $local $Path
        if ($value) { return @{ Value = $value; Source = 'project.local.yaml' } }
    }
    $value = Get-YamlScalar $project $Path
    if ($value) { return @{ Value = $value; Source = 'project.yaml' } }
    if ($legacyFiles.ContainsKey($Path)) {
        $mirror = $legacyFiles[$Path]
        $file = Join-Path $Root $mirror
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $value = [string] (Get-Content -LiteralPath $file | Where-Object { $_.Trim() } | Select-Object -First 1)
            $value = $value.Trim()
            if (Test-Allowed $Path $value $mirror) { return @{ Value = $value; Source = $mirror } }
        }
    }
    if ($expanded.ContainsKey($Path)) { return @{ Value = $expanded[$Path]; Source = "rigor:$rigor" } }
    if ($defaults.ContainsKey($Path)) { return @{ Value = $defaults[$Path]; Source = 'default' } }
    return @{ Value = $null; Source = 'unset' }
}

$preferences = '.claude/docs/technical-preferences.md'
$preferencesFile = Join-Path $Root $preferences
$legacyPreferences = if (Test-Path -LiteralPath $preferencesFile -PathType Leaf) { Get-Content -LiteralPath $preferencesFile -Raw }
function Get-LegacyPreference([string] $Label) {
    if (-not $legacyPreferences) { return }
    $pattern = '(?m)^[ \t]*(?:[-*][ \t]+)?(?:\*\*)?' + [regex]::Escape($Label) + '(?:\*\*)?[ \t]*:[ \t]*(?<value>[^\r\n]+)'
    $legacyValue = [regex]::Match($legacyPreferences, $pattern).Groups['value'].Value.Trim()
    if ($legacyValue -and $legacyValue -notmatch 'TO BE CONFIGURED') { $legacyValue }
}

function Format-Tagged([hashtable] $Setting) {
    if ($Setting.Value) { return "$($Setting.Value)($($Setting.Source))" }
    return 'unset'
}

function Join-Items([string[]] $Items) {
    ($Items | ForEach-Object { if ($_.Contains(',')) { '"' + $_ + '"' } else { $_ } }) -join ', '
}

function Get-EngineSettings {
    $engineLine = Get-LegacyPreference 'Engine'
    $legacyEngine = if ($engineLine -match '^(?<name>.+) (?<version>\d\S*)$') {
        @{ name = $Matches.name; version = $Matches.version }
    } else {
        @{ name = $engineLine }
    }
    $legacyEngine.language = Get-LegacyPreference 'Language'
    $settings = @{}
    foreach ($key in @('name', 'version', 'language')) {
        $value = Get-YamlScalar $project "engine.$key"
        $settings[$key] = if ($value) { @{ Value = $value; Source = 'project.yaml' } }
        else { @{ Value = $legacyEngine[$key]; Source = $preferences } }
    }
    $settings
}

function Resolve-EngineFolder([string] $Kind, [string] $Default, [string] $Source) {
    $key = "engine.${Kind}_root"
    $value = Get-YamlScalar $project $key
    if (-not $value -or $value.StartsWith('[')) {
        if ($Default -and $Default -ne '-') { return "$Default($Source)" }
        if ($Kind -eq 'code') {
            $candidates = @(Get-ChildItem -LiteralPath $Root -Directory | Where-Object Name -CIn @('src', 'Assets', 'Source'))
            if ($candidates.Count -eq 1) { return "$($candidates[0].Name)(detected)" }
        }
        return 'unset'
    }

    if ($value -match '^[~/]|^[A-Za-z]:' -or $value.Contains('\')) { return "invalid($key must be relative and use / separators: $value)" }
    $path = ($value -replace '^(?:\./)+', '').TrimEnd('/')
    if (-not $path -or $path -eq '.') { return ".($key)" }
    $parts = $path.Split('/')
    $excluded = @('.claude', '.git', 'production', 'design', 'docs', 'studio-tests', 'prototypes')
    if ($Kind -eq 'code') { $excluded += 'tests' }
    if ($parts[0] -in $excluded) { return "invalid($key points to a framework folder: $value)" }

    $folder = $Root
    foreach ($part in $parts) {
        if ($part -in @('', '.', '..') -or $part.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            return "invalid($key is not a plain folder path: $value)"
        }
        $entry = Get-ChildItem -LiteralPath $folder -Directory -Force | Where-Object Name -CEQ $part | Select-Object -First 1
        if (-not $entry) { return "invalid($key has no folder spelled '$part' in '$value')" }
        $folder = $entry.FullName
    }
    return "$path($key)"
}

$labels = @{
    rigor = 'modes.rigor'
    review_mode = 'modes.review_mode'
    automation = 'modes.automation'
    workflow = 'modes.workflow'
    'docs.density' = 'docs.density'
    story_granularity = 'modes.story_granularity'
    'qa.level' = 'qa.level'
    'team.size' = 'team.size'
    'project.stage' = 'project.stage'
    'performance.enforce' = 'performance.enforce'
    framework_version = 'framework.version'
}
$defaultKeys = @('rigor', 'review_mode', 'automation', 'workflow', 'docs.density', 'story_granularity', 'qa.level', 'team.size', 'project.stage', 'automation_always_ask', 'engine', 'testing.strict', 'performance.enforce', 'cert_tier', 'system_overrides')
$selection = if ($Keys) { @($Keys -split ',' | ForEach-Object { $_.Trim() }) } else { $defaultKeys }
$overrides = Get-YamlNode $project 'workflow_overrides.system_overrides'
$rows = @(
    foreach ($label in $selection) {
        if ($labels.ContainsKey($label)) {
            $setting = Resolve-Setting $labels[$label]
            "${label}: $($setting.Value ?? 'not set') ($($setting.Source))"
            continue
        }
        switch ($label) {
            'automation_always_ask' {
                $path = 'modes.automation_always_ask'
                $items = if ($localEnabled) { Get-YamlList $local $path }
                $source = 'project.local.yaml'
                if (-not $items) { $items = Get-YamlList $project $path; $source = 'project.yaml' }
                if (-not $items) { $items = Read-CanonicalTable always_ask_default; $source = 'default' }
                "automation_always_ask: $(Join-Items $items) ($source)"
            }
            'engine' {
                $name = Get-YamlScalar $project 'engine.name'
                $version = Get-YamlScalar $project 'engine.version'
                if ($name) { "engine: $(($name, $version -join ' ').Trim()) (project.yaml)" }
                else { "engine: unset (fall back to $preferences)" }
            }
            { $_ -in @('testing.strict', 'gate_level') } {
                $all = Resolve-Setting 'testing.strict'
                $levels = foreach ($type in @('logic', 'integration', 'visual', 'ui', 'config')) {
                    $setting = Resolve-Setting "testing.strict.$type"
                    if (-not $setting.Value -and $all.Value) { $setting = $all }
                    if ($label -eq 'testing.strict') { "$type=$($setting.Value ?? 'unset')" }
                    elseif ($setting.Value -eq 'true') { "$type=blocking($($setting.Source))" }
                    elseif ($setting.Value -eq 'false') { "$type=advisory($($setting.Source))" }
                    elseif ($type -eq 'config') { 'config=advisory(default; /smoke-check: blocking)' }
                    else { "$type=blocking(default)" }
                }
                $description = if ($label -eq 'testing.strict') { ' (unset = each skill applies its own default)' }
                "${label}: $($levels -join ' ')$description"
            }
            { $_ -in @('cert_tier', 'platform.cert_tier') } {
                $cert = Resolve-Setting 'platform.cert_tier'
                if ($cert.Value) { "platform.cert_tier: $($cert.Value) ($($cert.Source))" }
                else { 'platform.cert_tier: (unset; ask which platforms are in scope)' }
            }
            'system_overrides' {
                $pairs = if ($overrides -is [System.Collections.IDictionary]) {
                    foreach ($key in $overrides.Keys) {
                        if ($overrides[$key] -is [string]) { "$key=$($overrides[$key])" }
                    }
                }
                if ($pairs) { "system_overrides: $($pairs -join ' ')" } else { 'system_overrides: none' }
            }
            'review_gate' {
                $mode = Resolve-Setting 'modes.review_mode'
                $skill = if ($mode.Value -eq 'full') { 'run' } else { 'skip' }
                $phase = if ($mode.Value -in @('full', 'lean')) { 'run' } else { 'skip' }
                "review_gate: skill-gates=$skill phase-gates=$phase (review_mode $($mode.Value), $($mode.Source); a --review flag overrides)"
            }
            'engine_values' {
                $engine = Get-EngineSettings
                $values = foreach ($key in @('name', 'version', 'language')) { "$key=$(Format-Tagged $engine[$key])" }
                "engine_values: $($values -join ' ')"
            }
            'specialists' {
                $engine = Get-EngineSettings
                $primary = @{ Value = $(switch -Wildcard ($engine.name.Value) {
                    'Godot' { 'godot-specialist' }
                    'Unity' { 'unity-specialist' }
                    'Unreal*' { 'unreal-specialist' }
                    'Web' { 'lead-programmer' }
                }); Source = 'engine.name' }
                if (-not $primary.Value) { $primary = @{ Value = (Get-LegacyPreference 'Primary'); Source = $preferences } }
                $slots = [ordered]@{ code = 'Language/Code Specialist'; shader = 'Shader Specialist'; ui = 'UI Specialist' }
                $block = Get-YamlNode $project 'specialists'
                $source = if ($block -is [System.Collections.IDictionary] -and $block.Count) { 'project.yaml' } else { $preferences }
                $values = foreach ($key in $slots.Keys) {
                    $value = if ($source -eq 'project.yaml') { Get-YamlScalar $project "specialists.$key" }
                    else { Get-LegacyPreference $slots[$key] }
                    "${key}=$($value ?? 'unset')"
                }
                $additional = if ($source -eq 'project.yaml') {
                    Join-Items @(Get-YamlList $project 'specialists.additional' | Where-Object { $_ -notin @('null', '~') })
                } else { Get-LegacyPreference 'Additional Specialists' }
                "specialists: primary=$(Format-Tagged $primary) $($values -join ' ') additional=$($additional ? $additional : 'none') ($source; unset = skip that specialist)"
            }
            'input_methods' {
                $block = Get-YamlNode $project 'platform'
                if ($block -is [System.Collections.IDictionary] -and $block.Count) {
                    $primary = Get-YamlScalar $project 'platform.primary_input'
                    $methods = @(
                        if (@(Get-YamlList $project 'platform.targets') -match '^(PC|Web)$') { 'keyboard/mouse' }
                        if ((Get-YamlScalar $project 'platform.gamepad_support') -in @('Full', 'Partial')) { 'gamepad' }
                        if ((Get-YamlScalar $project 'platform.touch_support') -in @('Full', 'Partial')) { 'touch' }
                        if ($primary) {
                            switch -Regex (($primary -replace ' ', '').ToLowerInvariant()) {
                                '^(keyboard|mouse|keyboard[/+&-]mouse|mouse[/+&-]keyboard|keyboardandmouse|mouseandkeyboard|kbm|kb/m|kb\+m|m\+kb|mkb)$' { 'keyboard/mouse'; break }
                                '^(gamepad|controller|gamecontroller|joypad)$' { 'gamepad'; break }
                                '^(touch|touchscreen)$' { 'touch'; break }
                                default { $_ }
                            }
                        }
                    ) | Select-Object -Unique
                    "input_methods: $($methods ? ($methods -join ', ') : 'none') (project.yaml platform; primary: $($primary ?? 'unset'))"
                } else {
                    $methods = Get-LegacyPreference 'Input Methods'
                    $primary = Get-LegacyPreference 'Primary Input'
                    if ($methods) { "input_methods: $methods ($preferences; primary: $($primary ?? 'unset'))" }
                    else { 'input_methods: unset (no platform block in project.yaml, no Input Methods line)' }
                }
            }
            'perf_budgets' {
                $budgets = foreach ($key in @('target_framerate', 'frame_budget_ms', 'draw_call_limit', 'memory_ceiling_mb')) {
                    "$key=$((Get-YamlScalar $project "performance.$key") ?? 'unset')"
                }
                "perf_budgets: $($budgets -join ' ') (project.yaml)"
            }
            'engine_row' {
                $tablePath = '.claude/engines/engines.tsv'
                $engine = (Get-EngineSettings).name
                $row = Import-Csv -LiteralPath (Join-Path $frameworkRoot $tablePath) -Delimiter "`t" |
                    Where-Object engine -EQ ($engine.Value -replace '^Unreal.*$', 'Unreal') | Select-Object -First 1
                $source = if ($engine.Source -eq 'project.yaml') { 'engine.name' } else { $engine.Source }
                $code = Resolve-EngineFolder code $row.code_root $source
                $test = Resolve-EngineFolder test $row.test_root $source
                $commands = foreach ($key in @('run', 'build', 'test', 'smoke')) {
                    $value = if ($row -and $row.$key -ne '-') { '"' + $row.$key + '"' } else { '-' }
                    "${key}=$value"
                }
                "engine_row: engine=$(Format-Tagged $engine) code_root=$code test_root=$test asset_root=$($row.asset_root ?? '-') $($commands -join ' ') ($tablePath; - = not in the table)"
            }
            default { throw "Unsupported CCGS configuration label '$label'. See docs/CODEX.md for supported labels." }
        }
    }
    if ($System) {
        $override = if ($overrides -is [System.Collections.IDictionary]) { $overrides[$System] }
        if ($override -is [string] -and $override -notin @('null', '~')) { "workflow[${System}]: $override (system_overrides)" }
        else { "workflow[${System}]: $((Resolve-Setting 'modes.workflow').Value) (no override; project value)" }
    }
)

if (-not $Keys) { '=== CCGS Resolved Config ===' }
$rows
if ($notes.Count) { "notes: $(($notes | Select-Object -Unique) -join '; ')" }
elseif (-not $Keys) { 'notes: none' }
if (-not $Keys) { '=== end CCGS config ===' }
