import pathlib,subprocess,concurrent.futures,json
root=pathlib.Path('production/playtest-evidence/final-chapters-2026-09-22/regression');root.mkdir(exist_ok=True)
files=[p for p in pathlib.Path('tests/integration').glob('campaign_*test.gd') if 'late_sweep' not in p.name]
def run(p):
 with (root/(p.stem+'.log')).open('w') as f:
  try:
   r=subprocess.run(['/Applications/Godot.app/Contents/MacOS/Godot','--headless','--log-file','/tmp/late-reg-'+p.stem+'.log','--path','.', '--script','res://'+str(p),'--','--campaign-validation'],stdout=f,stderr=subprocess.STDOUT,timeout=180)
   code=r.returncode
  except subprocess.TimeoutExpired:code=124
 txt=(root/(p.stem+'.log')).read_text();ok=code==0 and 'SCRIPT ERROR' not in txt and 'CHECK_FAILED' not in txt and 'FAIL:' not in txt
 result={'test':str(p),'exit':code,'pass':ok};print(json.dumps(result),flush=True);return result
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,files))
(root/'results.json').write_text(json.dumps(results,indent=2))
