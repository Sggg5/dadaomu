"""Strict real Godot runner, retains failures and raw performance samples."""
from pathlib import Path
import subprocess,re,json,argparse,shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);a=p.parse_args()
rows=[];destination=ROOT/'docs/screenshots/phase_12a6'
def run(name,script,graph=False,extra=(),fixed=True):
    cmd=[a.godot,'--path',str(ROOT),'--script',script]
    if not graph:cmd+=['--headless']
    if fixed:cmd+=['--fixed-fps','60']
    if extra:cmd+=['--',*extra]
    r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=1200)
    output=r.stdout+r.stderr;(ROOT/f'logs/12a6_{name}.log').write_text(output,encoding='utf-8')
    counts=re.findall(r'(\d+) checks, (\d+) failures',output)
    failed=r.returncode!=0 or not counts or counts[-1][1]!='0' or bool(re.search(r'(?m)^(SCRIPT ERROR:|ERROR:)',output))
    row={'suite':name,'summary':counts[-1] if counts else None,'exit':r.returncode,'failed':failed};rows.append(row);print(json.dumps(row),flush=True)
    if failed:raise RuntimeError(name+' failed; retained full log')
    if name in ['new_graph','old_graph','new_benchmark','old_benchmark']:
        prefix=name.split('_')[0];kind='performance' if name.endswith('benchmark') else 'validation'
        shutil.copy2(ROOT/f'docs/screenshots/phase_12a5/after_focused_{kind}.json',destination/f'{prefix}_{kind}.json')
try:
    for key in ['phase12a1_smoke','phase12a2_space','phase12a2_regional','phase12a3_space','phase12a3_proportions','phase12a4_smoke','phase12a5_smoke']:
        run('regression_'+key,'tests/'+key+'.gd')
    for key in ['phase12a1_graphical','phase12a2_benchmark','phase12a3_benchmark']:
        run('regression_'+key,'tests/'+key+'.gd',True)
    run('regression_a1_graph_headless','tests/phase12a1_graphical.gd')
    for key in ['phase12a2_space','phase12a2_regional','phase12a3_space','phase12a3_proportions','phase12a4_smoke','phase12a5_smoke']:
        run('regression_graph_'+key,'tests/'+key+'.gd',True)
    run('regression_a4_selector','tests/phase12a4_playtest.gd',True,['--verify-switches'])
    run('regression_a5_old_graph','tests/phase12a5_smoke.gd',True,['--old-a'])
    run('regression_original_render_bench','tests/phase12_benchmark.gd',True)
    run('new_headless','tests/phase12a6_visual_smoke.gd')
    run('new_graph','tests/phase12a6_visual_smoke.gd',True)
    run('old_graph','tests/phase12a6_capture.gd',True,['--old-enemies'])
    run('actual_attack','tests/phase12a6_attack_probe.gd',True)
    # No capture/PNG/GIF writes in either sequential benchmark; both full AI active.
    run('old_benchmark','tests/phase12a6_capture.gd',True,['--benchmark','--old-enemies'],False)
    run('new_benchmark','tests/phase12a6_capture.gd',True,['--benchmark'],False)
finally:
    (ROOT/'logs/12a6_qa_results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
