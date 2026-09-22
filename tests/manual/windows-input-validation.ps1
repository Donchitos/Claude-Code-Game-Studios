param(
    [string]$BuildDirectory = (Join-Path $PSScriptRoot '../../build/windows-pc-input-r3-r8'),
    [string]$ControllerModel = 'NOT_RECORDED'
)
$ErrorActionPreference = 'Stop'
$inputBuild = (Resolve-Path $BuildDirectory).Path
$inputExe = Join-Path $inputBuild 'TrialInternal.exe'
$inputPack = Join-Path $inputBuild 'TrialInternal.pck'
$inputStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$inputEvidence = Join-Path $inputBuild "input-evidence-$inputStamp"
New-Item -ItemType Directory -Path $inputEvidence -ErrorAction Stop | Out-Null
$inputChecks = @(
    'W01_START_HOME_KEYBOARD', 'W02_WASD_DIAGONAL_OPPOSITE',
    'W03_CONTROLLER_IDLE_DEADZONE', 'W04_KEYBOARD_STICK_ARBITRATION',
    'W05_HELD_KEY_PAUSE_NEUTRAL', 'W06_HELD_STICK_PAUSE_NEUTRAL',
    'W07_ALT_TAB_EXPLICIT_RESUME', 'W08_DISCONNECT_RECONNECT',
    'W09_STEAM_INPUT_REMAP', 'W10_UPGRADE_FOCUS_ONCE',
    'W11_SECOND_BATTLE_FIRST_PAUSE', 'W12_SETTLEMENT_HOME',
    'W13_RESOLUTION_FOCUS', 'W14_MULTI_CONTROLLER'
)
$inputReport = [ordered]@{
    schema_version = 1
    started_at = (Get-Date).ToString('o')
    os = [System.Environment]::OSVersion.VersionString
    cpu = (Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name)
    gpu = @(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name)
    controller_model = $ControllerModel
    exe_sha256 = (Get-FileHash $inputExe -Algorithm SHA256).Hash.ToLowerInvariant()
    pck_sha256 = (Get-FileHash $inputPack -Algorithm SHA256).Hash.ToLowerInvariant()
    launch_exit_code = $null
    physical_input_verified = $false
    checks = @($inputChecks | ForEach-Object { [ordered]@{ id = $_; status = 'NOT_RUN'; observation = ''; evidence_file = '' } })
}
$inputReportPath = Join-Path $inputEvidence 'results.json'
$inputReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $inputReportPath -Encoding UTF8
$inputLog = Join-Path $inputEvidence 'godot.log'
# Memory-only profile; test play does not load or write the user's progression.
$inputProcess = Start-Process -FilePath $inputExe -WorkingDirectory $inputBuild -ArgumentList @('--log-file', ('"' + $inputLog + '"'), '--', '--input-validation') -Wait -PassThru
$inputReport.launch_exit_code = $inputProcess.ExitCode
$inputReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $inputReportPath -Encoding UTF8
Write-Host "Evidence directory: $inputEvidence"
Write-Host 'Launch exit code is not an input PASS. Fill each NOT_RUN row from actual observation.'
