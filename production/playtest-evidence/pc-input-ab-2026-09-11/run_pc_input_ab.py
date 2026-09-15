from pathlib import Path
import subprocess, json, time, hashlib, sys

root = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(Path('/tmp/pc-input-ab-path.txt').read_text())
engine = '/Applications/Godot.app/Contents/MacOS/Godot'
mode = sys.argv[1] if len(sys.argv) > 1 else 'default'
out = root / ('results-' + mode)
out.mkdir(exist_ok=True)
def capture(command):
    return subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30).stdout
if mode == 'default':
    for arm in ['baseline', 'current']:
        with (out / (arm + '-import.log')).open('w') as log:
            result = subprocess.run([engine, '--headless', '--editor', '--path', str(root / arm), '--import'], stdout=log, stderr=subprocess.STDOUT, timeout=90)
        if result.returncode != 0:
            raise RuntimeError('Import failed: ' + arm)
environment = {'created_at': time.strftime('%Y-%m-%dT%H:%M:%S%z'), 'engine_version': capture([engine, '--version']), 'system': capture(['sw_vers']), 'thermal': capture(['pmset', '-g', 'therm']), 'processes_before': capture(['ps', '-axo', 'pid,ppid,pcpu,comm'])}
(out / 'environment.json').write_text(json.dumps(environment, indent=2))
summary = []
for index, arm in enumerate(['baseline', 'current', 'current', 'baseline', 'baseline', 'current'], 1):
    flags = ['--dense']
    if mode == 'no-vsync':
        flags += ['--no-vsync']
    command = [engine, '--path', str(root / arm), '--script', 'res://tests/integration/performance_probe.gd', '--'] + flags
    started = time.time()
    logfile = out / f'{index:02d}-{arm}.log'
    with logfile.open('w') as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    source = root / arm / 'production/playtest-evidence/performance-graphical-dense.json'
    if result.returncode or not source.exists():
        print(json.dumps({'run': index, 'arm': arm, 'exit': result.returncode, 'log': str(logfile)}), flush=True)
        raise RuntimeError('A/B execution failed')
    report = json.loads(source.read_text())
    report['ab_arm'] = arm
    report['ab_order'] = index
    report['elapsed_seconds'] = time.time() - started
    report['command'] = command
    report['probe_sha256'] = hashlib.sha256((root/arm/'tests/integration/performance_probe.gd').read_bytes()).hexdigest()
    (out / f'{index:02d}-{arm}.json').write_text(json.dumps(report, indent=2))
    row = report['cases'][0]
    brief = {'run': index, 'arm': arm, 'passed_execution': report['passed_execution'], 'simulation_p95_ms': row['simulation_p95_ms'], 'frame_p95_ms': row['frame_interval_p95_ms'], 'frame_p99_ms': row['frame_interval_p99_ms'], 'vsync': report['vsync_mode_observed'], 'renderer': report['rendering_method']}
    summary.append(brief)
    (out / 'summary.json').write_text(json.dumps(summary, indent=2))
    print(json.dumps(brief), flush=True)
    if not report['passed_execution']:
        raise RuntimeError('A/B fixture failed')
environment['processes_after'] = capture(['ps', '-axo', 'pid,ppid,pcpu,comm'])
(out / 'environment.json').write_text(json.dumps(environment, indent=2))
