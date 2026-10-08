// Minimal DOM unit fixture. This validates renderer/filter logic, not browser appearance.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('database/previews/index.html','utf8');
const data=html.match(/<script id="catalog-data" type="application\/json">([\s\S]*?)<\/script>/)[1];
const code=[...html.matchAll(/<script(?: [^>]*)?>([\s\S]*?)<\/script>/g)].at(-1)[1];
class Element{constructor(tag,id){this.tagName=tag;this.id=id;this.value='';this.children=[];this.dataset={};this.textContent='';this.classList={contains:()=>false,toggle:()=>{}};}
append(...x){this.children.push(...x);}replaceChildren(...x){this.children=x;if(this.tagName==='select')this.value='';}addEventListener(name,fn){this.listener=fn;}after(e){this.afterNode=e;}remove(){this.removed=true;}}
const ids={};for(const id of ['catalog-data','summary','search','culture','region','history','institution','media','category','geology','status','count','rows','page','prev','next'])ids[id]=new Element(['culture','region','history','institution','media','category','geology','status'].includes(id)?'select':'div',id);
ids['catalog-data'].textContent=data;
const buttons=['objects','articles','candidates','exhibitions'].map(view=>{const b=new Element('button');b.dataset.view=view;return b;});
const context=vm.createContext({document:{getElementById:id=>ids[id],createElement:tag=>new Element(tag),querySelectorAll:()=>buttons},Option:class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=value;}},console});
vm.runInContext(code,context);let checks=0;const check=fn=>{fn();checks++;};
check(()=>assert.match(ids.summary.textContent,/1441.*100.*500.*8/));
check(()=>assert.equal(vm.runInContext('filtered.length',context),1441));check(()=>assert.equal(ids.rows.children.length,25));
ids.culture.value='中国历史文化';ids.culture.listener();check(()=>assert.ok(vm.runInContext('filtered.length',context)>=300));
buttons[1].onclick();check(()=>assert.equal(vm.runInContext('filtered.length',context),100));
ids.search.value='科林斯';ids.search.listener();check(()=>assert.equal(vm.runInContext('filtered.length',context),1));
ids.rows.children[0].onclick();check(()=>assert.match(ids.rows.children[0].afterNode.children[0].children[1].textContent,/真实性.*(?:疑问|争议)/));
buttons[2].onclick();check(()=>assert.equal(vm.runInContext('filtered.length',context),500));
ids.category.value='FOSSIL_SPECIMEN';ids.category.listener();check(()=>assert.equal(vm.runInContext('filtered.length',context),24));
ids.category.value='';ids.geology.value='Cretaceous';ids.geology.listener();check(()=>assert.ok(vm.runInContext('filtered.length',context)>0));
buttons[2].onclick();ids.status.value='CANDIDATE';ids.status.listener();check(()=>assert.equal(vm.runInContext('filtered.length',context),500));
ids.next.onclick();check(()=>assert.equal(ids.page.textContent,'2 / 20'));ids.prev.onclick();check(()=>assert.equal(ids.page.textContent,'1 / 20'));
ids.search.value='no such item 123xyz';ids.search.listener();check(()=>assert.equal(ids.rows.children.length,0));check(()=>assert.equal(ids.next.disabled,true));
check(()=>assert.ok(!html.match(/<img\b|<iframe\b|<script[^>]*\bsrc=/i)));check(()=>assert.ok(html.includes("connect-src 'none'")));
console.log(`${checks} preview DOM checks, 0 failures (no browser appearance claim)`);
