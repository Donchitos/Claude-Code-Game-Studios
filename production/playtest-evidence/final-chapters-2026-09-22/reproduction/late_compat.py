import pathlib,subprocess,hashlib,json
r=pathlib.Path.cwd();out=r/'production/playtest-evidence/final-chapters-2026-09-22';old=r/'build/chapter-three-2026-09-17/SpiritNexus-ChapterThree.pck';new=r/'build/full-campaign-2026-09-22/SpiritNexus-FullCampaign.pck';stem='/tmp/late-compat-20260922-';script=r/'tests/integration/campaign_legacy_package_probe.gd'
assert not pathlib.Path(stem+'a.save').exists() and not pathlib.Path(stem+'b.save').exists()
def run(pack,mode):
 with (out/('compat-'+mode+'.log')).open('w') as f:
  p=subprocess.run(['/Applications/Godot.app/Contents/MacOS/Godot','--headless','--log-file','/tmp/late-compat-'+mode+'.log','--main-pack',str(pack),'--script',str(script),'--',mode,stem,'6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a'],cwd='/tmp',stdout=f,stderr=subprocess.STDOUT,timeout=30)
 log=(out/('compat-'+mode+'.log')).read_text();assert p.returncode==0 and 'LEGACY_PROBE_PASS' in log and 'SCRIPT ERROR' not in log,log
 print(mode,'PASS',flush=True)
def hashes():return {s:hashlib.sha256(pathlib.Path(stem+s+'.save').read_bytes()).hexdigest() for s in ['a','b']}
run(old,'prepare');before=hashes();run(new,'blocked');assert before==hashes();run(old,'finish');run(new,'home')
(out/'compatibility.json').write_text(json.dumps({'old_pck_sha':hashlib.sha256(old.read_bytes()).hexdigest(),'new_pck_sha':hashlib.sha256(new.read_bytes()).hexdigest(),'before_and_after_blocked':before,'zero_writes':True,'home_upgrade':True,'scope':'isolated old PCK battle; test abandonment only'},indent=2))
for s in ['a','b']:pathlib.Path(stem+s+'.save').unlink()
