import subprocess,pathlib,sys
name=sys.argv[1];script=sys.argv[2];args=sys.argv[3:]
p=pathlib.Path('production/playtest-evidence/final-chapters-2026-09-22')/(name+'.log')
with p.open('w') as f:
 try:
  r=subprocess.run(['/Applications/Godot.app/Contents/MacOS/Godot','--headless','--log-file','/tmp/late-'+name+'-engine.log','--path','.', '--script',script,'--','--validation']+args,stdout=f,stderr=subprocess.STDOUT,timeout=900)
  print(name,'exit',r.returncode)
 except subprocess.TimeoutExpired: print(name,'TIMEOUT')
print(p.read_text()[-2000:])
