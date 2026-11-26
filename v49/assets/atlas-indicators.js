(()=>{'use strict';
const $=id=>document.getElementById(id),year=$('indicator-year'),region=$('indicator-region'),category=$('indicator-category'),out=$('indicator-results'),download=$('indicator-download');
let rows=[];
const node=(tag,content)=>{const e=document.createElement(tag);e.textContent=content;return e};
const filtered=()=>rows.filter(r=>(year.value==='all'||String(r.year)===year.value)&&(region.value==='all'||r.region===region.value)&&(category.value==='all'||r.category===category.value));
function options(el,key){const values=[...new Set(rows.map(r=>r[key]))].sort((a,b)=>key==='year'?b-a:String(a).localeCompare(b,'pt'));el.replaceChildren(new Option('Todos','all'),...values.map(v=>new Option(v,v)))}
function render(){const list=filtered();out.replaceChildren();for(const r of list){const card=node('article','');card.className='atlas-stat';const link=node('a',r.source);link.href=r.url;card.append(node('span',r.category+' · '+r.region+' · '+r.year),node('h3',r.label),node('strong',r.value.toLocaleString('pt-BR')),node('small',[r.qualifier,r.unit,r.percent==null?'':r.percent.toLocaleString('pt-BR')+'% da população'].filter(Boolean).join(' · ')),node('p',r.note),link);out.append(card)}if(!list.length)out.append(node('p','Sem dados verificados para a seleção.'));download.disabled=!list.length}
for(const el of [year,region,category])el.addEventListener('change',render);
const fields=['year','region','category','label','value','unit','qualifier','percent','source','url','note'];
const quote=v=>'"'+String(v??'').replaceAll('"','""')+'"';
download.addEventListener('click',()=>{const csv=[fields.join(','),...filtered().map(r=>fields.map(k=>quote(r[k])).join(','))].join('\r\n');const url=URL.createObjectURL(new Blob(['\uFEFF'+csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='atlas-indicadores.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)});
download.disabled=true;fetch('assets/data/atlas-indicators.json').then(r=>{if(!r.ok)throw Error();return r.json()}).then(data=>{rows=data;options(year,'year');options(region,'region');options(category,'category');render()}).catch(()=>out.replaceChildren(node('p','Não foi possível carregar os indicadores. Tente novamente.')));
})();
