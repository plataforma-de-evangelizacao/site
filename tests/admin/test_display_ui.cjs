'use strict';
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { join } = require('node:path');

// Test the current document-based editorial interface, not the retired
// automatic YouTube ingestion/metadata editor. No network or real records.
class Node {
  constructor(tag) { this.tag=tag; this.children=[]; this.textContent=''; this._value=''; this.disabled=false; this.hidden=false; }
  get value(){ return this._value; } set value(v){this._value=String(v??'');}
  append(...nodes){ for(const n of nodes){n.parent=this;this.children.push(n);} if(this.tag==='select' && !this.value && nodes[0])this.value=nodes[0].value; }
  prepend(...nodes){ for(const n of nodes)n.parent=this; this.children.unshift(...nodes); }
  replaceChildren(...nodes){ this.children=[];this.append(...nodes); }
  before(node){this.parent.prepend(node);}
  addEventListener(){}
  setAttribute(){}
  showModal(){this.open=true;}
  close(){this.open=false;this.onclose?.();}
  remove(){if(this.parent)this.parent.children=this.parent.children.filter(n=>n!==this);}
  reportValidity(){return true;}
}
const walk=n=>[n,...n.children.flatMap(walk)];
const find=(n,p)=>{const result=walk(n).find(p);assert.ok(result,'Expected UI element');return result;};
const button=(n,label)=>find(n,x=>x.tag==='button'&&x.textContent===label);
const input=(n,label)=>find(n,x=>x.tag==='label'&&x.textContent===label).children[0];
function setup(){
  const body=new Node('body'),nodes=new Map(),sent=[],messages=[],tabs=[];
  for(const id of ['published-list','published-search','published-status','blocked','blocked-search','invite-permissions','invite-form','content-workspace','content-form-body','content-form-title','form-dirty','content-visual-form','publish-content','show-archived-content']) {
    const n=new Node('div');n.id=id;nodes.set(id,n);body.append(n);
  }
  const docs=[{path:'dados/fontes-legitimas.json',sha:'fixture-revision-1',content:JSON.stringify({itens:[
    {id:'video-1',titulo:'Ester',descricao:'Descrição editorial original',tipo:'filme',source_status:'verified',source_url:'https://example.org/official',evidence:'Fonte oficial'},
    {id:'video-2',titulo:'Outro vídeo',descricao:'Outro conteúdo',tipo:'filme',source_status:'pending',source_url:'https://example.org/other'},
    {id:'video-3',titulo:'Arquivado',descricao:'Não publicado',tipo:'filme',source_status:'verified',_admin_hidden:true}
  ]})}];
  const document={body,createElement:tag=>new Node(tag),getElementById:id=>walk(body).find(n=>n.id===id),querySelectorAll:()=>[],addEventListener(){}};
  const window={adminText:s=>s};
  let fail=false;
  window.pgeAdminBridge={
    access:()=>({active:true,role:'superadmin'}),documents:()=>docs,areaLabel:()=> 'Audiovisual em fontes oficiais',
    chooseDocument(path){const doc=docs.find(d=>d.path===path);if(doc)window.PGEForms.open(doc);return Boolean(doc);},
    openTab:tab=>tabs.push(tab),message:s=>messages.push(s),
    async publishDocuments(changes){sent.push(structuredClone(changes));if(fail)throw Error('conflict_document_changed');
      for(const c of changes){const d=docs.find(d=>d.path===c.path);Object.assign(d,{content:c.content,sha:'fixture-revision-2'});}}
  };
  const context=vm.createContext({window,document,console,structuredClone,confirm:()=>true,setTimeout,Option:function(text,value){const n=new Node('option');n.textContent=text;n.value=value;return n;},fetch:async()=>({json:async()=>({templates:{}})})});
  for(const file of ['forms.js','workspace.js'])vm.runInContext(fs.readFileSync(join(__dirname,'../../admin',file),'utf8'),context,{filename:file});
  const view=()=>window.PGEWorkspace.render();
  const dialog=()=>find(body,n=>n.tag==='dialog'&&n.open);
  return {window,body,nodes,docs,sent,messages,tabs,view,dialog,setFail:()=>{fail=true;}};
}
(async()=>{
  const e=setup();const list=e.nodes.get('published-list');
  e.nodes.get('published-status').value='approved';e.view();
  assert.equal(list.children.length,1);assert.equal(list.children[0].children[0].textContent,'Ester');
  e.nodes.get('published-search').value='outro';e.view();assert.equal(list.children[0].textContent,'Nenhum conteúdo neste filtro.');
  e.nodes.get('published-search').value='';e.nodes.get('published-status').value='pending_review';e.view();
  assert.equal(list.children[0].children[0].textContent,'Outro vídeo');
  e.nodes.get('published-status').value='approved';e.view();button(list,'Abrir gestão').onclick();
  assert.equal(e.tabs.at(-1),'documents');
  let d=e.dialog();assert.equal(input(d,'Título').value,'Ester');assert.equal(input(d,'Descrição').value,'Descrição editorial original');
  input(d,'Título').value='Ester — edição';input(d,'Título').oninput();
  input(d,'Descrição').value='Descrição revisada';input(d,'Descrição').oninput();
  find(d,n=>n.tag==='form').onsubmit({preventDefault(){}});
  await new Promise(resolve=>setImmediate(resolve));
  assert.equal(e.sent.length,1);
  const change=e.sent[0][0];assert.equal(change.expected_sha,'fixture-revision-1');assert.equal(change.path,'dados/fontes-legitimas.json');
  const records=JSON.parse(change.content).itens;assert.equal(records[0].titulo,'Ester — edição');assert.equal(records[0].descricao,'Descrição revisada');
  assert.equal(records[0].source_url,'https://example.org/official');assert.equal(records[0].evidence,'Fonte oficial');assert.equal(records[1].titulo,'Outro vídeo');
  e.view();button(list,'Abrir gestão').onclick();d=e.dialog();input(d,'Título').value='Descartar';input(d,'Título').oninput();button(d,'Descartar').onclick();
  assert.equal(e.sent.length,1);
  e.view();button(list,'Abrir gestão').onclick();d=e.dialog();input(d,'Título').value='Conflito';input(d,'Título').oninput();e.setFail();
  find(d,n=>n.tag==='form').onsubmit({preventDefault(){}});await new Promise(resolve=>setImmediate(resolve));
  assert.equal(e.sent[1][0].expected_sha,'fixture-revision-2');assert.equal(e.messages.at(-1),'conflict_document_changed');
  assert.equal(JSON.parse(e.docs[0].content).itens[0].titulo,'Ester — edição');assert.equal(e.nodes.get('publish-content').disabled,false);
  console.log('Current editorial UI checks passed: published/pending filters, search, document editor, title/description, source preservation, revision guard, discard, conflict.');
})().catch(err=>{console.error(err);process.exitCode=1;});
