"""Isolated real-engine visual QA; retains logs and rejects script errors."""
from pathlib import Path
import argparse,subprocess,re,json
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--graphical',action='store_true');p.add_argument('--benchmark',action='store_true');a=p.parse_args();rows=[]
def run(name,script,extra=(),graphical=False,fixed=True):
 cmd=[a.godot,'--path',str(ROOT),'--script',script]
 if fixed:cmd+=['--fixed-fps','60']
 if not graphical:cmd+=['--headless']
 if extra:cmd+=['--',*extra]
 r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=1200);out=r.stdout+r.stderr
 (ROOT/'logs'/('12_'+name+'.log')).write_text(out,encoding='utf-8')
 summary=re.findall(r'(\d+) checks, (\d+) failures',out)
 failed=r.returncode!=0 or not summary or int(summary[-1][1])!=0 or bool(re.search(r'(?m)^(SCRIPT ERROR:|ERROR:)',out))
 row={'suite':name,'exit':r.returncode,'summary':summary[-1] if summary else None,'failed':failed};rows.append(row);print(json.dumps(row),flush=True)
 if failed:raise RuntimeError(name+' failed, retained log')
try:
 run('visual_smoke','tests/phase12_smoke.gd')
 if a.graphical:
  for mode in ['legacy','basic','enhanced']:
   run('flow_'+mode,'tests/phase12_graphical.gd',['--capture','--art-mode='+mode],True)
   run('museum_'+mode,'tests/phase12_museum_graphical.gd',['--art-mode='+mode],True)
  run('events','tests/phase12_events_graphical.gd',(),True)
 if a.benchmark:run('performance','tests/phase12_benchmark.gd',(),True,False)
finally:(ROOT/'logs/12_qa_results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
