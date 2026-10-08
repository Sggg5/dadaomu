from contextlib import closing
"""Offline, read-only, paginated Fork research index. Never loads into Godot."""
import argparse,html,json,sqlite3
from pathlib import Path

def connect(path):
 db=sqlite3.connect(path.resolve().as_uri()+'?mode=ro',uri=True);db.row_factory=sqlite3.Row;return db

def search(db,keyword='',museum='',category='',kind='',rights='',page=1,size=50):
 clauses=['active=1'];params=[]
 for field,value in [('museum_code',museum),('category_label',category),('record_kind',kind),('rights_verdict',rights)]:
  if value:clauses.append(field+'=?');params.append(value)
 if keyword:clauses.append('(original_name LIKE ? OR original_dynasty LIKE ? OR record_id LIKE ?)');params.extend(['%'+keyword+'%']*3)
 where=' AND '.join(clauses);total=db.execute('SELECT count(*) FROM wenwu_entries WHERE '+where,params).fetchone()[0]
 size=max(1,min(size,250));page=max(1,page)
 rows=[dict(r) for r in db.execute('SELECT record_id,museum_code,original_name,original_dynasty,category_label,record_kind,official_url,rights_verdict,review_status FROM wenwu_entries WHERE '+where+' ORDER BY record_id LIMIT ? OFFSET ?',params+[size,(page-1)*size])]
 return {'total':total,'page':page,'page_size':size,'records':rows}

def export(db,out):
 out.mkdir(parents=True,exist_ok=True)
 rows=search(db,size=250);total=rows['total'];pages=(total+249)//250
 for page in range(1,pages+1):
  result=search(db,page=page,size=250)
  body=''.join('<tr><td>'+ '</td><td>'.join(html.escape(str(r.get(k) or '未知')) for k in ['record_id','museum_code','original_name','original_dynasty','category_label','record_kind','rights_verdict','review_status'])+'</td><td><a rel="noreferrer" href="'+html.escape(r['official_url'],quote=True)+'">官方来源</a></td></tr>' for r in result['records'])
  nav=' '.join(f'<a href="page-{i}.html">{i}</a>' for i in range(1,pages+1))
  (out/f'page-{page}.html').write_text('<!doctype html><meta charset="utf-8"><title>文物来源研究目录</title><style>body{font:15px sans-serif;margin:24px}td{padding:6px;border-bottom:1px solid #bbb}nav{line-height:2}</style><h1>研究来源索引 · 非玩家馆藏</h1><p>全部待审核，品种记录不计独立实物；无图片下载。</p><a href="index.html">搜索</a><nav>'+nav+'</nav><table>'+body+'</table>',encoding='utf-8')
 allrows=[dict(r) for r in db.execute('SELECT record_id,museum_code,original_name,original_dynasty,category_label,record_kind,rights_verdict,review_status FROM wenwu_entries WHERE active=1 ORDER BY record_id')]
 payload=json.dumps(allrows,ensure_ascii=False).replace('<','\\u003c')
 template='''<!doctype html><meta charset="utf-8"><title>文物研究搜索</title><h1>Fork研究目录（离线）</h1><p>来源索引并非正式馆藏或已批准游戏定义。搜索名称、朝代、机构、类别、授权或记录类型。</p><input id="q" placeholder="搜索"><button id="prev">上一页</button><button id="next">下一页</button><p id="count"></p><div id="results"></div><a href="page-1.html">完整分页目录与官方链接</a><script type="application/json" id="data">PAYLOAD</script><script>const data=JSON.parse(document.getElementById('data').textContent);let page=0;function render(){let q=document.getElementById('q').value.toLowerCase();let rows=data.filter(r=>Object.values(r).join(' ').toLowerCase().includes(q));page=Math.max(0,Math.min(page,Math.max(0,Math.ceil(rows.length/50)-1)));document.getElementById('count').textContent=rows.length+'条 / 第'+(page+1)+'页';let box=document.getElementById('results');box.replaceChildren();for(let r of rows.slice(page*50,page*50+50)){let p=document.createElement('p');p.textContent=Object.values(r).join(' | ');box.append(p)}}document.getElementById('q').oninput=()=>{page=0;render()};document.getElementById('prev').onclick=()=>{page--;render()};document.getElementById('next').onclick=()=>{page++;render()};render();</script>'''
 (out/'index.html').write_text(template.replace('PAYLOAD',payload),encoding='utf-8');return pages

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--db',type=Path,required=True);p.add_argument('--keyword',default='');p.add_argument('--museum',default='');p.add_argument('--category',default='');p.add_argument('--kind',default='');p.add_argument('--rights',default='');p.add_argument('--page',type=int,default=1);p.add_argument('--export',type=Path)
 a=p.parse_args()
 with closing(connect(a.db)) as db:
  if a.export:print(json.dumps({'pages':export(db,a.export)}))
  else:print(json.dumps(search(db,a.keyword,a.museum,a.category,a.kind,a.rights,a.page),ensure_ascii=False,indent=2))
if __name__=='__main__':main()
