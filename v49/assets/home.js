(()=>{'use strict';
const data=JSON.parse(document.getElementById('home-data').textContent);
const $=id=>document.getElementById(id),modal=$('content-dialog'),mobile=$('menu-dialog');
const norm=x=>String(x||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/\s+/g,' ').trim();
const t=(text,values)=>window.pgeI18n.t(text,values),lang=()=>window.pgeI18n.lang;
let rows=[];function localizeRows(){rows=data.index.map(x=>({...x,...(lang()==='pt'?{}:x.traducoes?.[lang()]||{}),normalized:norm(x.title+' '+x.text+' '+x.aliases+' '+Object.values(x.traducoes||{}).map(v=>v.title+' '+v.text).join(' '))}));}localizeRows();
function el(tag,text,cls){const n=document.createElement(tag);if(text)n.textContent=text;if(cls)n.className=cls;return n;}
function paragraph(text,cls){return el('p',text,cls);}
function syncDialogs(){document.body.classList.toggle('dialog-open',Boolean(document.querySelector('dialog[open]')));}
function open(title,label,nodes){
 if(mobile.open)mobile.close();
 $('dialog-title').textContent=title;$('dialog-label').textContent=label;
 $('dialog-body').replaceChildren(...nodes);if(!modal.open)modal.showModal();syncDialogs();window.pgeI18n.render(modal);$('dialog-title').focus();
}
function sourceLink(id,label='Consultar no site atual'){
 const p=paragraph('', 'source-link'),a=el('a',label);a.href='https://plataforma-de-evangelizacao.github.io/site/#'+encodeURIComponent(id);a.target='_blank';a.rel='noopener noreferrer';p.append(a);return p;
}
function entry(id){
 const item=rows.find(x=>x.id===id);if(!item)return;
 open(item.title,'ESPAÇO DA VERSÃO ATUAL',[
  paragraph(item.text||'Este espaço já possui uma seção na versão atual da plataforma.'),
  paragraph('Nesta revisão estamos avaliando a Home. A tela completa deste destino será trabalhada em uma próxima revisão visual.','dialog-context'),sourceLink(id)
 ]);
}
function list(items,openItem){
 const ul=el('ul','', 'dialog-list');
 for(const item of items){const li=el('li'),button=el('button',item.title||item.titulo);button.type='button';button.addEventListener('click',()=>openItem(item));li.append(button);if(item.text||item.descricao)li.append(el('small',item.text||item.descricao));ul.append(li);}
 return ul;
}
function program(id){
 const p=data.programs.find(x=>x.id===id);if(!p)return;
 open(p.titulo,'PROGRAMA COMUNITÁRIO',[
  el('span','Em planejamento','status-tag'),paragraph(p.subtitulo),paragraph(p.descricao_completa||p.descricao),
  paragraph('Proposta em desenvolvimento. Não há oferta de curso, inscrição ou serviço ativo confirmada nesta prévia.','dialog-context'),sourceLink('projetos','Conhecer os programas na versão atual')
 ]);
}
function impact(id){const source=data.impacts.find(x=>x.id===id);if(!source)return;const item=lang()==='pt'?source:{...source,...source.traducoes?.[lang()]};open(item.titulo,t('FRENTE FUTURA'),[el('span',t('Proposta futura'),'status-tag'),paragraph(item.descricao),paragraph(t('Proposta em planejamento, a desenvolver com a comunidade e com profissionais. Não há serviço ou atendimento ativo anunciado nesta prévia.'),'dialog-context'),sourceLink('projetos')]);}
const infos={
 preview:()=>open('Home Aurora Azul · revisão 3','V49-VIS-01 · R3',[
  paragraph('Esta revisão inclui três idiomas, temas claro e escuro, fundo semitransparente com movimento, cuidado em destaque e conteúdos diários.'),
  paragraph('A oração e o louvor mudam a cada dia, pelo calendário de Nova Bandeirantes. A lista percorre as 2.000 orações e os 14 louvores disponíveis antes de iniciar um novo ciclo.'),
  paragraph('Esta tela aguarda a revisão de Marcos. Login, matrículas, pagamentos e envio de dados serão avaliados nas telas correspondentes.','dialog-context')
 ]),
 programs:()=>open('Programas para construir juntos','PROPOSTAS EM PLANEJAMENTO',[
  paragraph('Estes programas estão registrados na versão atual. A existência de uma proposta não significa que suas formações e serviços já estejam disponíveis.'),list(data.programs,p=>program(p.id))
 ]),
 directory:()=>open('Todos os espaços','MAPA DA PLATAFORMA',[
  paragraph('Encontre as seções da versão atual. Nesta etapa, a busca e a organização ajudam a revisar os caminhos da nova Home.'),list(rows,x=>entry(x.id))
 ]),
 daily:()=>open('Um momento de leitura por dia','PLANO BÍBLICO',[
  paragraph('O plano existente organiza três referências por dia, preservadas do documento de origem. A seleção diária segue o calendário de Nova Bandeirantes, Mato Grosso.'),
  paragraph('As orações e os louvores seguem uma sequência sem repetição dentro de cada ciclo. Os títulos das músicas permanecem no idioma original; a oração acompanha o idioma escolhido.'),sourceLink('estudo-diario','Consultar o estudo diário na versão atual')
 ]),
 contact:()=>open('Vamos conversar','CONTATO E PARTICIPAÇÃO',[
  paragraph('Apresente uma ideia, seu interesse em colaborar ou uma possibilidade de parceria com a Plataforma Global de Evangelização.'),
  paragraph('A versão atual reúne os canais de contato do responsável.'),sourceLink('conecte','Abrir os canais de contato')
 ]),
 student:()=>open('Área do Aluno','TELA PREVISTA PARA REVISÃO',[
  paragraph('A Área do Aluno terá sua própria revisão de acesso, cursos, aulas e materiais. O código da V48 será avaliado seletivamente para a V49.'),
  paragraph('Nesta Home não há cadastro, autenticação ou matrícula. O acesso real depende da integração e dos testes específicos.','dialog-context')
 ]),
 about:()=>open('Conhecer a Palavra. Compartilhar o cuidado.','SOBRE A PLATAFORMA',[
  paragraph('A Plataforma Global de Evangelização é uma iniciativa cristã de Marcos Lucas Pereira, em Nova Bandeirantes, Mato Grosso. Sua proposta reúne fé, conhecimento, conteúdos e participação comunitária.'),
  paragraph('Deus está no centro da abordagem. Perguntas, aprendizado e reflexão caminham com respeito às pessoas e cuidado com o próximo.'),sourceLink('missao','Conhecer a missão na versão atual')
 ]),
 donations:()=>open('Apoio voluntário à plataforma','DESTINO ÚNICO DE DOAÇÕES',[
  paragraph('Você pode participar compartilhando tempo, conhecimento e cuidado. O apoio financeiro é voluntário.'),
  paragraph('A tela de Doações será revisada com os dados oficiais do recebedor, instruções e acesso à transparência. Nesta prévia não há pagamento ou QR para transferência.','dialog-context'),sourceLink('doacoes','Consultar as instruções na versão atual')
 ]),
 atlas:()=>open('Atlas Solidário','MÓDULO EM PLANEJAMENTO',[
  paragraph('A proposta é reunir informações geográficas e indicadores agregados para apoiar o cuidado comunitário, com fontes, períodos e metodologia.'),
  paragraph('O Atlas terá sua própria tela. Esta revisão da Home apresenta apenas o destino de navegação; ainda não há mapa ou indicadores publicados aqui.','dialog-context')
 ])
};
function theme(query){
 const map={'Bíblia':['buscando','biblias','baixar-biblia','artigos-estudos','estudo-diario','historias-biblicas'], 'História':['fe-conhecimento','escola','biblioteca-ensino'], 'Ciência':['fe-conhecimento','escola','projetos'], 'Música':['musicas','playlists','palestras'], 'Educação':['escola','biblioteca-ensino','projetos'], 'Cuidado':['cuidar-de-si','acolhimento','solidariedade','seja-parceiro']};
 const titles={'Bíblia':'Bíblia e vida cristã','História':'Filosofia e História','Ciência':'Ciências e Tecnologia','Música':'Música e Artes','Educação':'Educação','Cuidado':'Vida e comunidade'};
 const items=(map[query]||[]).map(id=>rows.find(x=>x.id===id)).filter(Boolean);
 open(titles[query]||query,'EXPLORAR POR ASSUNTO',[
  paragraph('O novo catálogo multimídia está em preparação. Estes são espaços já presentes na versão atual que se relacionam com o tema.'),list(items,x=>entry(x.id))
 ]);
}
function route(hash){
 let id;try{id=decodeURIComponent(hash.replace(/^#/,''));}catch{return;}
 if(!id)return;
 const aliases={conhecer:'biblioteca-ensino',acompanhar:'biblioteca-ensino',solidariedade:'participar','home-library':'biblioteca-ensino','home-projects':'projetos','mapa-do-site':'directory'};
 const dialogs={doacoes:'donations','atlas-solidario':'atlas',conecte:'contact','seja-parceiro':'contact', 'mapa-do-site':'directory'};
 if(dialogs[id]){infos[dialogs[id]]();return;}
 const target=$(aliases[id]||id);
 if(target){if(modal.open)modal.close();if(mobile.open)mobile.close();syncDialogs();target.scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth',block:'start'});return;}
 entry(id);
}
document.addEventListener('click',event=>{
 const trigger=event.target.closest('[data-close],[data-info],[data-program],[data-impact],button[data-theme],a[href^="#"],.search-shortcut');if(!trigger)return;
 if(trigger.matches('[data-close]')){trigger.closest('dialog').close();syncDialogs();return;}
 if(trigger.dataset.info){infos[trigger.dataset.info]?.();return;}
 if(trigger.dataset.program){program(trigger.dataset.program);return;}
 if(trigger.dataset.impact){impact(trigger.dataset.impact);return;}
 if(trigger.dataset.theme){theme(trigger.dataset.theme);return;}
 if(trigger.classList.contains('search-shortcut')){if(mobile.open)mobile.close();$('home-search-input').focus();$('home-search-form').scrollIntoView({block:'center'});return;}
 if(trigger.matches('a[href^="#"]')){const hash=trigger.getAttribute('href');if(hash==='#principal')return;event.preventDefault();if(location.hash===hash)route(hash);else location.hash=hash;}
});
window.addEventListener('hashchange',()=>route(location.hash));
$('open-menu').addEventListener('click',()=>{mobile.showModal();syncDialogs();});
for(const d of [modal,mobile]){d.addEventListener('close',syncDialogs);d.addEventListener('click',e=>{if(e.target===d){const r=d.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom){d.close();syncDialogs();}}});}
function savePreference(key,value){try{localStorage.setItem(key,value);}catch{}}
function updateTheme(){const light=document.documentElement.dataset.theme==='light',button=$('theme-toggle'),label=t(light?'Ativar tema escuro':'Ativar tema claro');button.setAttribute('aria-pressed',String(light));button.setAttribute('aria-label',label);button.title=label;document.querySelector('meta[name="theme-color"]').content=light?'#f2f8fc':'#050b18';button.querySelector('use').setAttribute('href','assets/icones.svg#'+(light?'moon':'sun'));}
$('theme-toggle').addEventListener('click',()=>{document.documentElement.dataset.theme=document.documentElement.dataset.theme==='light'?'dark':'light';savePreference('pge.theme',document.documentElement.dataset.theme);updateTheme();});updateTheme();
const reduced=matchMedia('(prefers-reduced-motion: reduce)');let motionEnabled=true;try{motionEnabled=localStorage.getItem('pge.motion')!=='off';}catch{}
let scheduled=false;function paintGlobe(){scheduled=false;document.documentElement.style.setProperty('--globe-drift',motionEnabled&&!reduced.matches?(Math.min(128,innerHeight*.16)*Math.min(1,Math.max(0,scrollY/Math.max(1,document.documentElement.scrollHeight-innerHeight)))).toFixed(2)+'px':'0px');}
function updateMotion(){const off=!motionEnabled||reduced.matches;document.documentElement.dataset.motion=off?'off':'on';const button=$('motion-toggle');button.replaceChildren(document.createTextNode(t(off?'Ativar movimento':'Reduzir movimento')));button.setAttribute('aria-pressed',String(off));button.disabled=reduced.matches;paintGlobe();}
$('motion-toggle').addEventListener('click',()=>{motionEnabled=!motionEnabled;savePreference('pge.motion',motionEnabled?'on':'off');updateMotion();});reduced.addEventListener('change',updateMotion);addEventListener('scroll',()=>{if(!scheduled){scheduled=true;requestAnimationFrame(paintGlobe);}},{passive:true});updateMotion();
const input=$('home-search-input'),section=$('search-section'),results=$('home-search-results'),status=$('home-search-status');let timer;
function search(scroll=false){
 results.replaceChildren();const query=input.value.trim();
 if(norm(query).length<2){section.hidden=!query;if(query){status.textContent=t('Digite pelo menos duas letras para buscar.');}return;}
 section.hidden=false;const found=window.pgeSearchRank(rows,query);
 status.textContent=found.length?t('{count} espaço(s) encontrado(s) para “{query}”.',{count:found.length,query}):t('Nenhum espaço encontrado para “{query}”.',{query});
 if(!found.length){const box=el('div','', 'empty-state');box.append(paragraph('Tente outro assunto ou explore o mapa da plataforma.'));const button=el('button','Explorar os espaços','text-button');button.type='button';button.addEventListener('click',infos.directory);box.append(button);results.append(box);}
 for(const item of found){const article=el('article','','search-result'),h=el('h3'),button=el('button',item.title);button.type='button';button.addEventListener('click',()=>entry(item.id));h.append(button);article.append(h,paragraph(item.text||'Conheça este espaço na plataforma.'));results.append(article);}
 window.pgeI18n.render(section);
 if(scroll)section.scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth',block:'start'});
}
$('home-search-form').addEventListener('submit',e=>{e.preventDefault();clearTimeout(timer);search(true);});
input.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(()=>search(false),180);});
$('clear-search').addEventListener('click',()=>{input.value='';section.hidden=true;results.replaceChildren();status.textContent='';input.focus();});
window.addEventListener('pge-locale-change',()=>{localizeRows();updateTheme();updateMotion();if(input.value.trim())search(false);});
if(location.hash)requestAnimationFrame(()=>route(location.hash));
})();
