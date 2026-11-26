(()=>{'use strict';
const $=id=>document.getElementById(id),year=$('indicator-year'),region=$('indicator-region'),category=$('indicator-category'),out=$('indicator-results'),download=$('indicator-download');
let rows=[];
let selection={territory:'world',category:'all',names:['Mundo','World']};
const period=$('atlas-period');
const categories={
 housing:['Moradia','Água e saneamento'],food:['Alimentação'],clothes:['Vestuário e higiene'],care:['Acolhimento','Deslocamento'],health:['Saúde','Acessibilidade'],protection:['Proteção','Proteção infantil','Violência'],education:['Educação'],response:['Projetos e respostas']
};
const normalize=value=>String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim();
const exactRows=(id,cat,names)=>rows.filter(r=>{
 const territoryKey=String(r.territory_code||r.territory_id||r.iso2||'').toLowerCase();
 const byCode=territoryKey&&(territoryKey===id||id==='br'&&territoryKey==='bra'||id==='world'&&territoryKey==='wld'||id.startsWith('country-')&&id.slice(8)===territoryKey);
 const byName=names.some(name=>normalize(name)===normalize(r.region));
 return (byCode||byName)&&(cat==='all'||(categories[cat]||[]).some(label=>normalize(label)===normalize(r.category)))&&(period.value==='all'||String(r.year)===period.value);
});
const latest=list=>{
 const byLabel=new Map();
 for(const r of list){
   const old=byLabel.get(r.label);
   if(!old||Number(r.year)>Number(old.year)||Number(r.year)===Number(old.year)&&(Date.parse(r.collected_at)||0)>(Date.parse(old.collected_at)||0))byLabel.set(r.label,r);
 }
 return [...byLabel.values()];
};
const textValue=r=>new Intl.NumberFormat(document.documentElement.lang,{maximumFractionDigits:2}).format(r.value);
function updateTerritory(){
 const list=latest(exactRows(selection.territory,selection.category,selection.names));
 const kpis=$('territory-kpis');
 kpis.replaceChildren();
 const empty=document.querySelector('.atlas-info .atlas-no-data');
 empty.hidden=list.length>0;
 const meta=document.querySelector('.atlas-info dl');
 meta.hidden=true;
 $('atlas-coverage-count').textContent=list.length?String(list.length):'—';
 $('atlas-coverage-note').textContent=list.length?'Indicadores com dados no recorte':'Dados ainda não disponíveis';
 for(const r of list){
   const article=node('article','');
   article.className='atlas-kpi-item';
   const link=node('a',r.source||'Fonte');
   if(/^https?:\/\//i.test(r.url||''))link.href=r.url;
   article.append(node('span',r.label),node('strong',textValue(r)),node('small',[r.unit,r.year].filter(Boolean).join(' · ')),link);
   kpis.append(article);
 }
 for(const card of document.querySelectorAll('[data-need]')){
   const records=latest(exactRows(selection.territory,card.dataset.need,selection.names));
   if(!records.length)continue;
   const r=records[0];
   card.querySelector('strong').textContent=textValue(r);
   card.querySelector('small').textContent=[r.label,r.unit,r.year,r.source].filter(Boolean).join(' · ');
 }
 for(const layer of document.querySelectorAll('[data-layer]')) {
   const color=window.AtlasGeo.colors[layer.dataset.layer];
   if(color)layer.style.setProperty('--layer-color',color);
 }
 window.AtlasGeo.setCoverage((id,cat,names)=>exactRows(id,cat,names).length>0);
}
document.addEventListener('atlas-selection',event=>{selection=event.detail;updateTerritory()});
period.addEventListener('change',()=>document.dispatchEvent(new Event('atlas-period-change')));
 const jsonButton=$('indicator-json'),live=$('indicator-live-status');
const node=(tag,content)=>{const e=document.createElement(tag);e.textContent=content;return e};
const filtered=()=>rows.filter(r=>(year.value==='all'||String(r.year)===year.value)&&(region.value==='all'||r.region===region.value)&&(category.value==='all'||r.category===category.value));
function options(el,key){const values=[...new Set(rows.map(r=>r[key]))].sort((a,b)=>key==='year'?b-a:String(a).localeCompare(b,'pt'));el.replaceChildren(new Option('Todos','all'),...values.map(v=>new Option(v,v)))}
function render(){const list=filtered();out.replaceChildren();for(const r of list){const card=node('article','');card.className='atlas-stat';const link=node('a',r.source);link.href=r.url;card.append(node('span',r.category+' · '+r.region+' · '+r.year),node('h3',r.label),node('strong',r.value.toLocaleString('pt-BR')),node('small',[r.qualifier,r.unit,r.percent==null?'':r.percent.toLocaleString('pt-BR')+'% da população'].filter(Boolean).join(' · ')),node('p',r.note),link);out.append(card)}if(!list.length)out.append(node('p','Sem dados verificados para a seleção.'));download.disabled=!list.length;if(jsonButton)jsonButton.disabled=!list.length}
for(const el of [year,region,category])el.addEventListener('change',render);
const fields=['collected_at','year','region','category','label','value','unit','qualifier','percent','source','url','note'];
const quote=v=>'"'+String(v??'').replaceAll('"','""')+'"';
download.addEventListener('click',()=>{const csv=[fields.join(','),...filtered().map(r=>fields.map(k=>quote(r[k])).join(','))].join('\r\n');const url=URL.createObjectURL(new Blob(['\uFEFF'+csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='atlas-indicadores.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)});
jsonButton?.addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(filtered(),null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='atlas-indicadores.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)});
function show(data){rows=data;options(year,'year');options(region,'region');options(category,'category');options(period,'year');period.disabled=!rows.length;render();document.dispatchEvent(new Event('atlas-period-change'))}
async function load(){try{const config=await fetch('assets/data/atlas-config.json').then(r=>r.json());const headers={apikey:config.publishableKey};const all=[];for(let offset=0;;offset+=500){const response=await fetch(config.supabaseUrl+'/rest/v1/atlas_observations?select=payload,collected_at&order=id.asc&limit=500&offset='+offset,{headers});if(!response.ok)throw Error('HTTP '+response.status);const page=await response.json();if(!Array.isArray(page))throw Error();all.push(...page.map(x=>({...x.payload,collected_at:x.collected_at})));if(page.length<500)break}if(!all.length)throw Error();show(all);if(live){const timestamps=all.map(r=>Date.parse(r.collected_at)).filter(Number.isFinite);const last=timestamps.length?new Date(Math.max(...timestamps)).toLocaleString('pt-BR',{timeZone:'America/Campo_Grande'})+' (MT)':'não informada';live.textContent='Histórico · '+all.length+' registros · última coleta '+last;}}catch{try{const response=await fetch('assets/data/atlas-indicators.json');if(!response.ok)throw Error();show(await response.json());if(live)live.textContent='Cópia local de referência · histórico online indisponível.'}catch{if(live)live.textContent='Não foi possível carregar os indicadores.'}}}
download.disabled=true;if(jsonButton)jsonButton.disabled=true;load();

})();
