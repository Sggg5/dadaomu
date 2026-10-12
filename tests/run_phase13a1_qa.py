"""Reproducible Phase13A.1 QA. All GameFlow tests use isolated memory/disk fixtures."""
from pathlib import Path
import argparse,ast,json,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--godot',required=True)
p.add_argument('--history',action='store_true')
p.add_argument('--long-run',action='store_true')
p.add_argument('--graphical',action='store_true')
a=p.parse_args();logs=ROOT/'logs';logs.mkdir(exist_ok=True);rows=[]
def run(name,cmd,summary=True):
 result=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=1800)
 text=result.stdout+result.stderr
 (logs/f'13a1_qa_{name}.log').write_text(text,encoding='utf-8')
 found=re.findall(r'(\d+) checks, (\d+) failures',text)
 failed=result.returncode!=0 or bool(re.search(r'(?m)^(SCRIPT ERROR:|ERROR:|Unicode parsing error:)',text)) or (summary and (not found or int(found[-1][1])>0))
 row={'suite':name,'exit':result.returncode,'summary':found[-1] if found else None,'failed':failed};rows.append(row);print(json.dumps(row),flush=True)
 (logs/'13a1_qa_results.json').write_text(json.dumps(rows,indent=2))
 if failed:raise RuntimeError(f'{name} failed; retained log')
def godot(name,script,graphical=False,extra=()):
 cmd=[a.godot,'--path',str(ROOT),'--fixed-fps','60','--quit-after','1000000','--script',script]
 if not graphical:cmd.append('--headless')
 if extra:cmd+=['--',*extra]
 run(name,cmd)
run('import',[a.godot,'--headless','--path',str(ROOT),'--editor','--quit'],False)
run('python',[sys.executable,'-m','unittest','discover','-s','database/tests'],False)
if a.history:
 tree=ast.parse((ROOT/'tests/run_phase_11i_qa.py').read_text(encoding='utf-8-sig'))
 phases=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='HISTORY' for t in n.targets))
 for phase in phases:
  script={'softlock':'tests/phase_softlock_smoke.gd','baseline':'tests/phase_player_baseline_smoke.gd'}.get(phase,'tests/phase_'+phase+('.gd' if phase in ['10d_bridge','10d_media'] else '_smoke.gd'))
  godot('history_'+phase,script)
 for phase in ['12','12a1','12a4','12a5','12a6_visual']:godot('history_'+phase,f'tests/phase{phase}_smoke.gd')
if a.long_run:run('11i_30_days',[sys.executable,'tests/run_phase_11i_qa.py','--godot',a.godot,'--long-run'],False)
for kind in ['model','runtime']:godot(kind,f'tests/phase_13a_{kind}_smoke.gd')
godot('distribution','tests/phase_13a1_distribution_smoke.gd')
for case in ['MOJIN','FAQIU','BANSHAN','XIELING','XIELING_DEATH']:
 extra=['--case='+case]+(['--seed=142'] if case.startswith('XIELING') else ['--run-seed=192034'])
 godot('actual_'+case,'tests/phase_13a1_flow_smoke.gd',extra=extra)
 if a.graphical:godot('graphical_'+case,'tests/phase_13a1_flow_smoke.gd',True,extra)
print('All selected suites passed; human acceptance remains pending.')
