"""Isolated Phase 11I runner; failures and script errors are never suppressed."""
from pathlib import Path
import argparse,json,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--history',action='store_true');p.add_argument('--graphical',action='store_true');p.add_argument('--long-run',action='store_true');args=p.parse_args()
logs=ROOT/'logs';logs.mkdir(exist_ok=True);rows=[]
def run(name,script,extra=(),graphical=False):
 cmd=[args.godot,'--path',str(ROOT),'--fixed-fps','60','--quit-after','1000000','--script',script]
 if not graphical:cmd.append('--headless')
 if extra:cmd+=['--',*extra]
 result=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=1200)
 output=result.stdout+result.stderr;(logs/('11i_runner_'+name+'.log')).write_text(output,encoding='utf-8')
 summaries=re.findall(r'(\d+) checks, (\d+) failures',output)
 failed=result.returncode!=0 or not summaries or int(summaries[-1][1])!=0 or bool(re.search(r'(?m)^(SCRIPT ERROR:|ERROR:)',output))
 rows.append({'suite':name,'exit':result.returncode,'summary':summaries[-1] if summaries else None,'failed':failed});print(json.dumps(rows[-1]),flush=True)
 if failed:raise RuntimeError(name+' failed; see retained log')
 return output
HISTORY=['1', '2', '3', '4', '5a', '5b', '6', '6_5', '7a', '7b', '8a', '8b', '8c', '8d', '9a', '9b', '9b2', '9b3', '9b32', '9b33', 'geometry', 'softlock', 'baseline', '10a', '10d_bridge', '10d_media', '10d', '10d6', '11a', '11b_tombs', '11b_catalog', '11b', 'twin_death_hotfix', '11d1', '11d2', '11d3', '11d4', '11d5', '11d_flow', '11e1', '11e2', '11e3', '11e4', '11e5', '11f1', '11f2', '11f3', '11f4', '11f5', '11g1', '11g2', '11g3', '11g4', '11g5', '11h1', '11h2', '11h3', '11h4', '11h5']
try:
 if args.history:
  for phase in HISTORY:
   script={'softlock':'tests/phase_softlock_smoke.gd','baseline':'tests/phase_player_baseline_smoke.gd'}.get(phase,'tests/phase_'+phase+('.gd' if phase in ['10d_bridge','10d_media'] else '_smoke.gd'))
   run('history_'+phase,script)
 extra=['--progression']+(['--long-run'] if args.long_run else [])
 output=run('clean_flow','tests/phase_11i1_smoke.gd',extra)
 first=re.search(r'\[Earned checkpoint path\] (res://logs/11i_earned_\d+\.json)',output).group(1)
 mid=re.search(r'\[Midgame checkpoint\] (res://logs/11i_earned_midgame_\d+\.json)',output).group(1)
 for name,path in [('first_income',first),('midgame',mid)]:
  run('economy_'+name,'tests/phase_11i2_smoke.gd',['--checkpoint='+path,'--scenario='+name])
  run('disk_'+name,'tests/phase_11i4_smoke.gd',['--checkpoint='+path])
 if args.graphical:
  run('graphics_clean_flow','tests/phase_11i1_smoke.gd',['--capture'],True)
  run('graphics_empty_ui','tests/phase_11i3_graphical.gd',(),True)
  run('graphics_midgame_ui','tests/phase_11i3_graphical.gd',['--midgame'],True)
finally:
 (logs/'11i_runner_results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
