(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const filters = {year:$('indicator-year'),region:$('indicator-region'),category:$('indicator-category')};
  const period = $('atlas-period');
  const csv = $('indicator-download'), json = $('indicator-json'), more = $('indicator-more');
  const definitions = {
    housing:['Moradia'],
    food:['Alimentação'],
    clothes:['Vestuário e higiene'],
    care:['Acolhimento'],
    health:['Saúde','Acessibilidade'],
    protection:['Proteção','Proteção infantil','Violência'],
    education:['Educação'],
    response:['Projetos e respostas'],
    water:['Água e saneamento'],
    displacement:['Deslocamento'],
    poverty:['Pobreza']
  };
  const explanations = {
    'Moradia':'Condições habitacionais, incluindo assentamentos precários.',
    'Alimentação':'Subalimentação e insegurança alimentar aguda são medidas distintas.',
    'Vestuário e higiene':'Acesso a roupas e itens de higiene, com lacunas nas séries públicas.',
    'Acolhimento':'Apoio e serviços de acolhimento com cobertura identificada.',
    'Saúde':'Indicadores de saúde e acesso a cuidados.',
    'Acessibilidade':'Indicadores com recorte de deficiência e acessibilidade quando disponíveis.',
    'Proteção':'Violência, homicídios e proteção infantil, em séries separadas.',
    'Educação':'Acesso à educação e população fora da escola.',
    'Projetos e respostas':'Propostas vinculadas ao catálogo da plataforma, com a situação informada na ficha.',
    'Água e saneamento':'Acesso a serviços de água e saneamento com a definição da fonte.',
    'Deslocamento':'Pessoas deslocadas conforme o recorte e a definição da fonte.',
    'Pobreza':'Pobreza segundo a linha e o método declarados pela fonte.'
  };
  const wbIndicators = {
    'SN.ITK.DEFC.ZS':['Alimentação','Prevalência de subalimentação','% da população'],
    'SH.HOMC.P2':['Violência','Homicídios intencionais','por 100 mil habitantes'],
    'SH.H2O.SMDW.ZS':['Água e saneamento','Água potável gerida com segurança','% da população'],
    'SH.STA.SMSS.ZS':['Água e saneamento','Saneamento gerido com segurança','% da população'],
    'SI.POV.DDAY':['Pobreza','População abaixo da linha internacional de pobreza','% da população'],
    'SE.PRM.UNER.ZS':['Educação','Crianças em idade escolar primária fora da escola','% da faixa etária'],
    'SH.DYN.MORT':['Saúde','Mortalidade de menores de cinco anos','por mil nascidos vivos']
  };
  const external = [
    ...[{"year":2024,"region":"Brasil · Norte","territory_code":"br-norte","category":"Alimentação","label":"Domicílios em insegurança alimentar grave","value":6.3,"unit":"% dos domicílios","qualifier":"Grandes Regiões · Escala Brasileira de Insegurança Alimentar","source":"IBGE · PNAD Contínua","url":"https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/724f23c52823528787ba0ef28b7940e3.pdf","note":"Domicílios particulares permanentes. O percentual se refere a domicílios e à definição da EBIA."},{"year":2024,"region":"Brasil · Nordeste","territory_code":"br-nordeste","category":"Alimentação","label":"Domicílios em insegurança alimentar grave","value":4.8,"unit":"% dos domicílios","qualifier":"Grandes Regiões · Escala Brasileira de Insegurança Alimentar","source":"IBGE · PNAD Contínua","url":"https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/724f23c52823528787ba0ef28b7940e3.pdf","note":"Domicílios particulares permanentes. O percentual se refere a domicílios e à definição da EBIA."},{"year":2024,"region":"Brasil · Sudeste","territory_code":"br-sudeste","category":"Alimentação","label":"Domicílios em insegurança alimentar grave","value":2.3,"unit":"% dos domicílios","qualifier":"Grandes Regiões · Escala Brasileira de Insegurança Alimentar","source":"IBGE · PNAD Contínua","url":"https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/724f23c52823528787ba0ef28b7940e3.pdf","note":"Domicílios particulares permanentes. O percentual se refere a domicílios e à definição da EBIA."},{"year":2024,"region":"Brasil · Sul","territory_code":"br-sul","category":"Alimentação","label":"Domicílios em insegurança alimentar grave","value":1.7,"unit":"% dos domicílios","qualifier":"Grandes Regiões · Escala Brasileira de Insegurança Alimentar","source":"IBGE · PNAD Contínua","url":"https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/724f23c52823528787ba0ef28b7940e3.pdf","note":"Domicílios particulares permanentes. O percentual se refere a domicílios e à definição da EBIA."},{"year":2024,"region":"Brasil · Centro-Oeste","territory_code":"br-centro-oeste","category":"Alimentação","label":"Domicílios em insegurança alimentar grave","value":2.8,"unit":"% dos domicílios","qualifier":"Grandes Regiões · Escala Brasileira de Insegurança Alimentar","source":"IBGE · PNAD Contínua","url":"https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/724f23c52823528787ba0ef28b7940e3.pdf","note":"Domicílios particulares permanentes. O percentual se refere a domicílios e à definição da EBIA."}],
    {year:2026,region:'Sudão',territory_code:'SDN',category:'Alimentação',label:'Insegurança alimentar aguda · IPC fase 3+',value:19500000,unit:'pessoas',percent:41,qualifier:'Fevereiro a maio de 2026 · estimativa nacional',source:'IPC',url:'https://www.ipcinfo.org/ipc-country-analysis/details-map/en/c/1163315/',note:'Estimativa aproximada para fevereiro a maio de 2026. As projeções posteriores do mesmo relatório têm cobertura geográfica parcial.'},
    {year:2026,region:'Chade',territory_code:'TCD',category:'Alimentação',label:'Insegurança alimentar aguda · CH fase 3+',value:3180000,unit:'pessoas',percent:17,qualifier:'Junho a agosto de 2026 · população analisada',source:'Cadre Harmonisé · FAO GIEWS',url:'https://www.fao.org/giews/countrybrief/country.jsp?code=TCD',note:'Estimativa aproximada da população analisada. Uma análise separada da população refugiada não foi somada.'}
  ];
  const normalize = value => String(value??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim();
  const format = new Intl.NumberFormat('pt-BR',{maximumFractionDigits:2});
  const requests = new Map(), series = new Map(), unavailable = new Set();
  let baseline = [], rows = external, limit = 8, mapCoverage;
  let selection = {territory:'world',category:'all',names:['Mundo','World'],compared:[]};

  function make(tag,text='',className=''){
    const el=document.createElement(tag);
    el.textContent=text;
    if(className)el.className=className;
    return el;
  }
  const territoryCode = id => ({br:'BRA',world:'WLD'}[id] || (/^country-[a-z]{3}$/.test(id)?id.slice(8).toUpperCase():''));
  const exactTerritory = (row,target) => {
    const code=normalize(row.territory_code||row.territory_id||row.iso2);
    return code
      ? [normalize(territoryCode(target.territory)),normalize(target.territory)].includes(code)
      : target.names.some(name=>normalize(name)===normalize(row.region));
  };
  const inCategory = (row,category) => category==='all'||(definitions[category]||[]).some(label=>normalize(label)===normalize(row.category));
  function group(list){
    const groups=new Map();
    for(const row of list){
      if(typeof row.value!=='number'||!Number.isFinite(row.value))continue;
      const key=JSON.stringify([row.territory_code||row.territory_id||row.region,row.label,row.unit,row.source]);
      if(!groups.has(key))groups.set(key,new Map());
      const years=groups.get(key), old=years.get(row.year);
      if(!old||(Date.parse(row.collected_at)||0)>(Date.parse(old.collected_at)||0))years.set(row.year,row);
    }
    return [...groups.values()].map(values=>[...values.values()].sort((a,b)=>a.year-b.year));
  }
  function chart(items){
    const latest=items.at(-1);
    const fig=make('figure','','atlas-indicator-chart');
    const annual=items.filter(r=>r.year>=2020&&r.year<=2026);
    if(annual.length>1&&annual.every(r=>r.value>=0)){
      const bars=make('div','','atlas-chart-bars');
      bars.setAttribute('role','img');
      bars.setAttribute('aria-label','Série anual: '+Array.from({length:7},(_,i)=>{
        const yr=2020+i, match=annual.find(r=>r.year===yr);
        return yr+' '+(match?format.format(match.value):'sem dados');
      }).join(', ')+'. Unidade: '+latest.unit);
      const max=Math.max(1,...annual.map(r=>r.value));
      for(let yr=2020;yr<=2026;yr++){
        const item=annual.find(r=>r.year===yr);
        const col=make('div','','atlas-chart-col');
        const bar=make('span','',item?'atlas-chart-bar':'atlas-chart-bar is-missing');
        bar.style.setProperty('--bar-size',(item?item.value/max*100:0)+'%');
        col.title=yr+' · '+(item?format.format(item.value)+' '+latest.unit:'sem dados');
        col.append(bar,make('span',String(yr).slice(2)));
        bars.append(col);
      }
      fig.append(bars,make('figcaption','2020–2026 · hachurado: sem dados'));
      return fig;
    }
    const share=latest.percent??(latest.unit.startsWith('%')?latest.value:null);
    if(typeof share==='number'&&share>=0&&share<=100){
      const ring=make('div','','atlas-chart-ring');
      ring.style.setProperty('--slice',share+'%');
      ring.append(make('span',format.format(share)+'%'));
      fig.append(ring,make('figcaption','Proporção na população de referência'));
      return fig;
    }
    return null;
  }
  function indicatorCard(items, compact=false){
    const row=items.at(-1);
    const card=make('article','',compact?'atlas-kpi-item':'atlas-stat');
    card.append(make('small',[row.region,row.category,row.year].filter(Boolean).join(' · ')),
      make(compact?'h4':'h3',row.label),make('strong',format.format(row.value)),
      make('small',[row.unit,row.qualifier].filter(Boolean).join(' · ')));
    const figure=chart(items);
    if(figure)card.append(figure);
    const details=make('details');
    details.append(make('summary','Detalhes e fonte'));
    if(row.note)details.append(make('p',row.note));
    if(items.length>1)details.append(make('p',items.map(r=>r.year+': '+format.format(r.value)).join(' · ')));
    if(/^https:\/\//i.test(row.url||'')){
      const link=make('a',row.source||'Fonte');link.href=row.url;details.append(link);
    }
    card.append(details);
    return card;
  }
  function updateTerritory(){
    const targets=[selection,...selection.compared.filter(t=>t.territory!==selection.territory)];
    const panel=$('territory-kpis');
    panel.replaceChildren();
    for(const target of targets){
      const items=group(rows.filter(r=>exactTerritory(r,target)&&inCategory(r,selection.category)&&(period.value==='all'||String(r.year)===period.value)));
      const part=make('section');
      if(targets.length>1)part.append(make('h3',target.names[0]));
      for(const values of items)part.append(indicatorCard(values,true));
      if(!items.length&&targets.length>1)part.append(make('p','Sem dados para este recorte e período.'));
      panel.append(part);
    }
    const count=panel.querySelectorAll('article').length;
    document.querySelector('.atlas-info .atlas-no-data').hidden=count>0||targets.length>1;
    document.querySelector('.atlas-info dl').hidden=true;
    const selectedCount=panel.firstElementChild?.querySelectorAll('article').length||0;
    $('atlas-coverage-count').textContent=selectedCount?String(selectedCount):'—';
    $('atlas-coverage-note').textContent=selectedCount?'Indicadores com dados no recorte':'Dados ainda não disponíveis';
    for(const card of document.querySelectorAll('[data-need]')){
      const col=card.dataset.need;
      if(col==='response')continue;
      const records=group(rows.filter(r=>exactTerritory(r,selection)&&inCategory(r,col)&&(period.value==='all'||String(r.year)===period.value)));
      const recent=records.map(list=>list.at(-1)).sort((a,b)=>b.year-a.year)[0];
      card.querySelector('strong').textContent=recent?format.format(recent.value):'—';
      card.querySelector('small').textContent=recent?[recent.label,recent.unit,recent.year,recent.source].filter(Boolean).join(' · '):'Sem dados verificados';
    }
    for(const layer of document.querySelectorAll('[data-layer],.legend-data')){
      const color=window.AtlasGeo.colors[layer.dataset.layer||selection.category]||window.AtlasGeo.colors.all;
      layer.style.setProperty('--layer-color',color);
      if(layer.matches('.legend-data'))layer.style.backgroundColor=color;
    }
    const key=territoryCode(selection.territory);
    $('territory-series-status').textContent=key&&requests.has(key)&&!series.has(key)&&!unavailable.has(key)
      ?'Consultando séries internacionais…':key&&unavailable.has(key)?'Consulta internacional indisponível. Exibindo os dados disponíveis no Atlas.':'';
    if(mapCoverage!==rows){
      mapCoverage=rows;
      window.AtlasGeo.setCoverage((id,cat,names)=>rows.some(r=>exactTerritory(r,{territory:id,names})&&inCategory(r,cat)&&(period.value==='all'||String(r.year)===period.value)));
    }
  }
  const categoryMatches=(r,value)=>value==='all'||(definitions[value]?inCategory(r,value):r.category===value);
  const filtered=()=>rows.filter(r=>(filters.year.value==='all'||String(r.year)===filters.year.value)&&(filters.region.value==='all'||r.region===filters.region.value)&&categoryMatches(r,filters.category.value));
  function options(el,choices,label){
    const previous=el.value;
    el.replaceChildren(new Option(label,'all'),...choices.map(([value,title])=>new Option(title,value)));
    if([...el.options].some(o=>o.value===previous))el.value=previous;
  }
  function renderObservatory(){
    const list=filtered(), grouped=group(list), results=$('indicator-results');
    results.replaceChildren();
    for(const values of grouped.slice(0,limit))results.append(indicatorCard(values));
    if(!grouped.length)results.append(make('p','Sem dados verificados para esta seleção.'));
    more.hidden=grouped.length<=limit;
    csv.disabled=json.disabled=!list.length;
  }
  function refresh(){
    const unique=new Map();
    for(const row of [...external,...[...series.values()].flat(),...baseline]){
      const key=JSON.stringify([row.territory_code||row.territory_id||row.region,row.year,row.label,row.unit,row.source,row.qualifier||'']);
      const old=unique.get(key);
      if(!old||(Date.parse(row.collected_at)||0)>=(Date.parse(old.collected_at)||0))unique.set(key,row);
    }
    rows=[...unique.values()];
    const years=[...new Set(rows.map(r=>r.year))].sort((a,b)=>b-a).map(y=>[String(y),String(y)]);
    const regions=[...new Set(rows.map(r=>r.region))].filter(Boolean).sort((a,b)=>a.localeCompare(b,'pt-BR')).map(x=>[x,x]);
    const categoryLabels=Object.entries(definitions).map(([k,v])=>[k,v[0]]);
    options(filters.year,years,'Todos os anos');options(period,years,'Todos os períodos');period.disabled=false;
    options(filters.region,regions,'Todos os territórios');options(filters.category,categoryLabels,'Todas as categorias');
    renderObservatory();
    updateTerritory();
    document.dispatchEvent(new Event('atlas-period-change'));
    $('indicator-external-status').textContent='Consultas do Banco Mundial nesta sessão: '+[...series.values()].filter(x=>x.length).length+' territórios com séries.';
  }
  async function loadCountry(target){
    const code=territoryCode(target.territory);
    if(!code||requests.has(code))return;
    const task=(async()=>{
      const indicators=Object.keys(wbIndicators).join(';');
      const url='https://api.worldbank.org/v2/country/'+code+'/indicator/'+indicators+'?format=json&source=2&date=2020:2026&per_page=100';
      const response=await fetch(url,{signal:AbortSignal.timeout(12000)});
      if(!response.ok)throw Error('HTTP '+response.status);
      const data=await response.json();
      if(!Array.isArray(data)||!Array.isArray(data[1])||Number(data[0]?.pages)>1)throw Error('Série indisponível');
      return data[1].flatMap(item=>{
        const id=item?.indicator?.id, fields=wbIndicators[id], year=Number(item?.date);
        if(!fields||item.countryiso3code!==code||year<2020||year>2026||typeof item.value!=='number'||!Number.isFinite(item.value))return [];
        const [category,label,unit]=fields;
        return [{year,region:target.names[0],territory_code:code,category,label,unit,value:item.value,source:'Banco Mundial · WDI',url:'https://data.worldbank.org/indicator/'+id+'?locations='+code,note:'Série anual. Data do indicador é o ano de referência registrado na fonte.'}];
      });
    })();
    requests.set(code,task);
    updateTerritory();
    try{series.set(code,await task);refresh();}
    catch{unavailable.add(code);updateTerritory();}
  }
  async function loadBaseline(){
    const live=$('indicator-live-status');
    try{
      const config=await fetch('assets/data/atlas-config.json').then(r=>r.json());
      const all=[];
      for(let offset=0;;offset+=500){
        const url=config.supabaseUrl+'/rest/v1/atlas_observations?select=payload,collected_at&order=id.asc&limit=500&offset='+offset;
        const response=await fetch(url,{headers:{apikey:config.publishableKey},signal:AbortSignal.timeout(12000)});
        if(!response.ok)throw Error('HTTP '+response.status);
        const page=await response.json();
        if(!Array.isArray(page))throw Error('Formato inesperado');
        all.push(...page.map(x=>({...x.payload,collected_at:x.collected_at})));
        if(page.length<500)break;
      }
      baseline=all;
      const timestamps=all.map(r=>Date.parse(r.collected_at)).filter(Number.isFinite);
      const last=timestamps.length?new Date(Math.max(...timestamps)).toLocaleString('pt-BR',{timeZone:'America/Campo_Grande'})+' (MT)':'não informada';
      live.textContent='Histórico · '+all.length+' registros · última coleta '+last+'.';
    }catch{
      try{
        const response=await fetch('assets/data/atlas-indicators.json');
        if(!response.ok)throw Error();
        baseline=await response.json();
        live.textContent='Cópia local de referência · histórico online indisponível.';
      }catch{live.textContent='Histórico indisponível nesta sessão.';}
    }
    refresh();
  }
  const fields=['collected_at','year','region','territory_code','category','label','value','unit','qualifier','percent','source','url','note'];
  const quote=value=>{
    let s=String(value??'');
    if(typeof value==='string'&&/^\s*[=+\-@]/.test(s))s="'"+s;
    return '"'+s.replaceAll('"','""')+'"';
  };
  function download(content,type,extension){
    const url=URL.createObjectURL(new Blob([content],{type}));
    const link=make('a');link.href=url;link.download='atlas-indicadores.'+extension;
    link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
  csv.addEventListener('click',()=>download('\uFEFF'+[fields.join(','),...filtered().map(r=>fields.map(k=>quote(r[k])).join(','))].join('\r\n'),'text/csv;charset=utf-8','csv'));
  json.addEventListener('click',()=>download(JSON.stringify(filtered(),null,2),'application/json','json'));
  Object.values(filters).forEach(el=>el.addEventListener('change',()=>{limit=8;renderObservatory();}));
  more.addEventListener('click',()=>{limit+=8;renderObservatory();});
  period.addEventListener('change',()=>document.dispatchEvent(new Event('atlas-period-change')));
  document.addEventListener('atlas-selection',({detail})=>{
    selection=detail;updateTerritory();
    for(const target of [selection,...selection.compared])loadCountry(target);
  });
  for(const [title,description] of Object.entries(explanations)){
    const card=make('article','','atlas-source');
    card.append(make('h3',title),make('p',description));
    $('indicator-explanations').append(card);
  }
  refresh();
  loadBaseline();
})();
