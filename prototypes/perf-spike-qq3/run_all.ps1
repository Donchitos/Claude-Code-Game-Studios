# Runs the windowed spike scenarios sequentially, capturing stdout per run.
# _console.exe blocks and keeps stdout attached (the GUI exe detaches instantly)
$godot = 'C:\Users\Leo\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe'
$proj = 'F:\Neues_Spiel\prototypes\perf-spike-qq3'
$runs = @(
    @{ s = 's1'; c = 'c1' },
    @{ s = 's1'; c = 'c2' },
    @{ s = 's2'; c = 'c2' }
)
foreach ($r in $runs) {
    $log = Join-Path $proj ("results\run_{0}_{1}.log" -f $r.s, $r.c)
    Write-Output ("RUN_START {0} {1}" -f $r.s, $r.c)
    & $godot --path $proj -- ("--scenario={0}" -f $r.s) ("--config={0}" -f $r.c) *> $log
    Write-Output ("RUN_EXIT {0} {1} code={2}" -f $r.s, $r.c, $LASTEXITCODE)
}
Write-Output 'ALL_RUNS_DONE'
