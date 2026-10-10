"""Wait for prior graphic QA, then collect uncontended-by-own-tests final samples."""
from pathlib import Path
import subprocess,json,re,shutil,argparse,time
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);a=p.parse_args()
path=ROOT/'logs/12a6_extra_results.json';deadline=time.monotonic()+1800
while not path.exists():
    if time.monotonic()>deadline:raise TimeoutError('extra graphical QA not finished')
    time.sleep(2)
rows=json.loads(path.read_text())
assert rows[-1]['suite']=='final_a6_graph' and all(not r['failed'] for r in rows)
dest=ROOT/'docs/screenshots/phase_12a6'
for prefix in ['old','new']:
    source=dest/(prefix+'_performance.json')
    if source.exists():shutil.copy2(source,dest/('initial_concurrent_'+prefix+'_performance.json'))
final=[]
cases=[('final_probe','tests/phase12a6_attack_probe.gd',['--fixed-fps','60'],[]),('final_old_benchmark','tests/phase12a6_capture.gd',[],['--benchmark','--old-enemies']),('final_new_benchmark','tests/phase12a6_capture.gd',[],['--benchmark'])]
try:
    for name,script,flags,extra in cases:
        cmd=[a.godot,'--path',str(ROOT),'--script',script,*flags]+(['--',*extra] if extra else [])
        result=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=1200)
        output=result.stdout+result.stderr;(ROOT/f'logs/12a6_{name}.log').write_text(output,encoding='utf-8')
        counts=re.findall(r'(\d+) checks, (\d+) failures',output)
        failed=result.returncode!=0 or not counts or counts[-1][1]!='0' or bool(re.search(r'(?m)^(SCRIPT ERROR:|ERROR:)',output))
        row={'suite':name,'summary':counts[-1] if counts else None,'exit':result.returncode,'failed':failed};final.append(row);print(json.dumps(row),flush=True)
        if failed:raise RuntimeError(name)
        if 'benchmark' in name:
            prefix='old' if 'old' in name else 'new'
            shutil.copy2(ROOT/'docs/screenshots/phase_12a5/after_focused_performance.json',dest/(prefix+'_performance.json'))
    subprocess.run(['python' if not __import__('sys').executable else __import__('sys').executable,str(ROOT/'tools/build_phase12a6_evidence.py')],cwd=ROOT,check=True)
finally:
    (ROOT/'logs/12a6_final_results.json').write_text(json.dumps(final,indent=2),encoding='utf-8')
