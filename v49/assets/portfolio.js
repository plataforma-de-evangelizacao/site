(() => {
  'use strict';
  const C = window.PortfolioCore;
  const $ = id => document.getElementById(id);
  const icon = name => '<svg class="p-icon" aria-hidden="true"><use href="assets/portfolio-icons.svg#'+name+'"></use></svg>';
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const pref = {get(key) {try{return localStorage.getItem(key);}catch{return null;}},set(key,value){try{localStorage.setItem(key,value);}catch{}}};
  const requested = new URLSearchParams(location.search).get('lang');
  let lang = ['pt','en','es'].includes(requested) ? requested : (['pt','en','es'].includes(pref.get('pge.locale')) ? pref.get('pge.locale') : 'pt');
  let data, state, toastTimer, searchTimer, contactItem = '', routeKey = location.pathname+location.search;
  const t = (key, vars={}) => (window.PortfolioCopy[lang][key] || window.PortfolioCopy.pt[key] || key).replace(/\{(\w+)\}/g,(_,name)=>vars[name]??'');
  const l = value => C.local(value,lang);
  const scene = item => item.id==='P13' || item.id==='formacao-comunitaria-p13' ? 'music' : item.icon==='house' ? 'housing' : item.icon==='wheat' || item.id==='partilha-solidaria' ? 'food' : item.icon==='city' ? 'housing' : item.icon==='sprout' ? 'field' : item.icon==='headphones' ? 'editorial' : item.area==='health' ? 'health' : item.area==='care' || item.area==='community' ? 'care' : 'digital';
  function itemURL(id) { return C.stateURL({...state,item:id},lang,location.pathname); }
  function theme() {
    const light = document.documentElement.dataset.theme === 'light';
    $('theme-toggle').innerHTML=icon(light?'moon':'sun');
    $('theme-toggle').setAttribute('aria-label',t(light?'darkTheme':'lightTheme'));
    $('theme-toggle').title=t(light?'darkTheme':'lightTheme');
    $('theme-toggle').setAttribute('aria-pressed',String(light));
    document.querySelector('meta[name="theme-color"]').content=light?'#f2f8fc':'#050b18';
  }
  function translate() {
    document.documentElement.lang=lang==='pt'?'pt-BR':lang;
    $('locale-select').value=lang;
    document.querySelectorAll('[data-t]').forEach(el=>el.textContent=t(el.dataset.t));
    document.querySelectorAll('[data-label]').forEach(el=>el.setAttribute('aria-label',t(el.dataset.label)));
    document.querySelectorAll('[data-placeholder]').forEach(el=>el.placeholder=t(el.dataset.placeholder));
    document.querySelectorAll('a[href^="index.html"]').forEach(a=>{
      const url=new URL(a.getAttribute('href'),location.href);url.searchParams.set('lang',lang);a.setAttribute('href','index.html'+url.search+url.hash);
    });
    theme();
  }
  function card(item) {
    return '<article class="proposal-card"><a class="card-cover" data-open="'+esc(item.id)+'" href="'+esc(itemURL(item.id))+'" data-area="'+esc(item.area)+'" tabindex="-1" aria-hidden="true"><img src="assets/portfolio/'+scene(item)+'.svg" alt="" width="460" height="260" loading="lazy"><span class="cover-icon">'+icon(item.icon)+'</span></a><div class="card-content"><p class="card-type">'+t('tag_'+item.type)+'</p><h3 class="card-title"><a data-open="'+esc(item.id)+'" href="'+esc(itemURL(item.id))+'">'+esc(l(item.title))+'</a></h3><p class="card-summary">'+esc(l(item.summary))+'</p><div class="card-bottom"><span class="status-label">'+icon(item.status==='idea'?'spark':'clock')+t(item.status==='idea'?'concept':'planning')+'</span><a class="card-link" data-open="'+esc(item.id)+'" href="'+esc(itemURL(item.id))+'">'+t('view_'+item.type)+icon('plus')+'</a></div></div></article>';
  }
  function renderTabs() {
    const icons={all:'grid',project:'hands',training:'book',tool:'window',idea:'spark'};
    $('type-tabs').innerHTML=['project','training','tool','idea','all'].map(type=>'<button type="button" class="type-tab" data-type="'+type+'" aria-pressed="'+(state.type===type)+'">'+icon(icons[type])+'<span>'+t(type)+'</span><span class="tab-count">'+data.items.filter(r=>type==='all'||r.type===type).length+'</span></button>').join('');
  }
  function renderAreas() {
    const withoutArea=C.filter(data,{...state,area:'all'},lang);
    const rows=[{id:'all',title:{[lang]:t('allAreas')},icon:'grid'},...data.areas];
    $('area-filters').innerHTML=rows.map(area=>'<button type="button" class="area-button" data-area-filter="'+area.id+'" aria-pressed="'+(state.area===area.id)+'">'+icon(area.icon)+'<span>'+esc(l(area.title))+'</span><span class="area-count">'+withoutArea.filter(r=>area.id==='all'||r.area===area.id).length+'</span></button>').join('');
  }
  function renderPrograms() {
    $('program-panel').hidden=state.type!=='training';
    if(state.type!=='training')return;
    const program=data.programs.find(p=>p.id===state.program);
    $('program-panel').innerHTML='<h3>'+t('programTitle')+'</h3><p>'+t('programText')+'</p><label class="sr-only" for="program-filter">'+t('programLabel')+'</label><select id="program-filter"><option value="all">'+t('allPrograms')+'</option><option value="community">'+t('communityPrograms')+' (3)</option>'+data.programs.map(p=>'<option value="'+p.id+'">'+esc(l(p.title))+' ('+data.items.filter(r=>r.type==='training'&&r.programs.includes(p.id)).length+')</option>').join('')+'</select>'+(program?'<div class="program-description"><h4>'+esc(l(program.title))+'</h4><p>'+esc(l(program.summary))+'</p></div>':'');
    $('program-filter').value=state.program;
  }
  function renderActive() {
    const chips=[];
    if(state.area!=='all')chips.push(['area',l(data.areas.find(a=>a.id===state.area).title)]);
    if(state.stage!=='all')chips.push(['stage',t(state.stage==='idea'?'concept':state.stage)]);
    if(state.q)chips.push(['q','“'+state.q+'”']);
    if(state.program!=='all')chips.push(['program',state.program==='community'?t('communityPrograms'):l(data.programs.find(p=>p.id===state.program).title)]);
    $('active-filters').innerHTML=chips.map(([key,label])=>'<button type="button" class="filter-chip" data-clear-filter="'+key+'" aria-label="'+esc(t('clear')+': '+label)+'">'+esc(label)+icon('close')+'</button>').join('');
    $('filter-count').hidden=!chips.length; $('filter-count').textContent=chips.length;
  }
  function emptyState(title,text,error=false) {
    return icon(error?'chat':'compass')+'<h3>'+t(title)+'</h3><p>'+t(text)+'</p><button type="button" class="p-button secondary" '+(error?'id="retry-catalog"':'data-reset="true"')+'>'+t(error?'retry':'reset')+'</button>';
  }
  function renderCatalog() {
    $('catalog-view').hidden=false;$('detail-view').hidden=true;
    document.title=t('projects')+' · Plataforma Global de Evangelização';
    const items=C.filter(data,state,lang), shown=items.slice(0,state.limit);
    renderTabs();renderAreas();renderPrograms();renderActive();
    $('catalog-search').value=state.q;$('catalog-sort').value=state.sort;$('catalog-stage').value=state.stage;
    $('results-count').textContent=items.length===1?t('oneResult'):t('results',{n:items.length});
    $('catalog-grid').innerHTML=shown.map(card).join('');$('catalog-grid').setAttribute('aria-busy','false');
    $('catalog-state').hidden=!!items.length;
    if(!items.length)$('catalog-state').innerHTML=emptyState('emptyTitle',state.stage==='active'?'emptyActive':state.program==='rede-solidaria'?'noTraining':'emptyText');
    $('load-more').hidden=items.length<=shown.length;
    $('visible-count').textContent=items.length?(items.length===1?t('visibleOne'):t('visible',{n:shown.length,total:items.length})):'';
  }
  function renderDetail() {
    const item=data.items.find(r=>r.id===state.item);
    $('catalog-view').hidden=true;$('detail-view').hidden=false;
    const back='<a class="back-link" data-back="true" href="'+esc(C.stateURL({...state,item:''},lang,location.pathname))+'">'+icon('grid')+t('back')+'</a>';
    if(!item){$('detail-view').innerHTML=back+'<div class="catalog-state"><h1>'+t('notFoundTitle')+'</h1><p>'+t('notFoundText')+'</p></div>';document.title=t('notFoundTitle');return;}
    document.title=l(item.title)+' · '+t('projects')+' · PGE';
    const statusKey={project:'statusProject',training:'statusTraining',tool:'statusTool',idea:'statusIdea'}[item.type];
    const goals=l(item.goals)||[t({training:'detailGoalsTraining',tool:'detailGoalsTool',idea:'detailGoalsIdea'}[item.type]||'detailGoalsTraining')];
    const program=data.programs.find(p=>item.programs.includes(p.id));
    const area=data.areas.find(a=>a.id===item.area);
    const audience=l(item.audience)||t({training:'trainingAudience',tool:'toolAudience',idea:'ideaAudience'}[item.type]||'projectAudienceFallback');
    let body='<section class="detail-section"><p class="eyebrow">'+t('overview')+'</p><h2>'+t('goals')+'</h2><ul class="goals-list">'+goals.map(goal=>'<li>'+icon('check')+'<span>'+esc(goal)+'</span></li>').join('')+'</ul></section>';
    if(item.type==='training')body+='<section class="detail-section"><h2>'+t('curriculum')+'</h2><p>'+t(item.steps?'curriculumNote':'curriculumPending')+'</p>'+(item.steps?'<ul class="curriculum-list">'+item.steps.map(step=>'<li>'+icon(item.icon)+'<span>'+esc(l(step))+'</span></li>').join('')+'</ul>':'')+'</section>';
    body+='<section class="detail-section"><h2>'+t('materials')+'</h2><p>'+t(item.type==='tool'?'materialsTool':item.type==='idea'?'materialsIdea':'materialsText')+'</p></section>';
    const related=C.related(data,item);
    if(related.length)body+='<section class="detail-section"><h2>'+t(item.type==='project'?'relatedTraining':item.projects.length?'relatedProject':'relatedProgram')+'</h2><div class="related-grid">'+related.map(card).join('')+'</div></section>';
    let note=t('faithNote');
    if(['P04','P07','P14'].includes(item.id))note=t('clinicalNote')+' '+note;
    if(['P03','P05','P08','P12'].includes(item.id))note=t('protectionNote')+' '+note;
    if(item.id==='formacao-casais')note=t('couplesNote');
    body+='<p class="detail-note">'+note+'</p><section class="detail-cta"><h2>'+t('participationTitle')+'</h2><p>'+t('participationText')+'</p><button type="button" class="p-button secondary" data-contact="'+esc(item.id)+'">'+icon('chat')+t('talk')+'</button></section>';
    const fact=(label,value)=>'<div class="fact-row"><dt>'+t(label)+'</dt><dd>'+value+'</dd></div>';
    const facts=fact('audience',esc(audience))+fact('topic',esc(l(area.title)))+(item.duration?fact('duration',esc(l(item.duration))):'')+(item.type==='training'?fact('modality',t('toDefine')):'')+(program?fact('program','<button type="button" data-program-link="'+program.id+'">'+esc(l(program.title))+'</button>'):'');
    $('detail-view').innerHTML='<div class="detail-toolbar">'+back+'<button type="button" class="p-button secondary" id="share-proposal">'+icon('copy')+t('share')+'</button></div><div class="detail-hero"><div class="detail-hero-copy"><p class="card-type">'+icon(item.icon)+t('tag_'+item.type)+'</p><h1 id="detail-title" tabindex="-1">'+esc(l(item.title))+'</h1><p>'+esc(l(item.summary))+'</p><span class="status-label">'+icon(item.status==='idea'?'spark':'clock')+t(item.status==='idea'?'concept':'planning')+'</span></div><div class="card-cover detail-hero-art" data-area="'+item.area+'"><img src="assets/portfolio/'+scene(item)+'.svg" alt="" width="460" height="300"><span class="cover-icon">'+icon(item.icon)+'</span></div></div><div class="detail-columns"><div class="detail-body">'+body+'</div><aside class="detail-sidebar"><h2>'+t('statusTitle')+'</h2><p>'+t(statusKey)+'</p><dl class="detail-facts">'+facts+'</dl><button type="button" class="p-button primary" data-contact="'+esc(item.id)+'">'+icon('chat')+t('talk')+'</button><p class="detail-availability">'+t(item.type==='training'?'noEnrollment':item.type==='tool'?'noDownload':item.type==='idea'?'ideaNext':'heroNote')+'</p></aside></div>';
  }
  function render() { state.item?renderDetail():renderCatalog(); }
  function sync(push=false) {
    const url=C.stateURL(state,lang,location.pathname);
    history[push?'pushState':'replaceState']({scrollY:window.scrollY},'',url);
    routeKey=location.pathname+location.search;
  }
  function change(patch,{push=true,scroll=false}={}) {
    clearTimeout(searchTimer);
    const focus=document.activeElement;
    const focusKey=focus?.dataset?.type ? ['data-type',focus.dataset.type] : focus?.dataset?.areaFilter ? ['data-area-filter',focus.dataset.areaFilter] : null;
    const focusId=focus?.id;
    history.replaceState({scrollY:window.scrollY},'',location.href);
    state={...state,...patch,limit:6};sync(push);render();
    if(scroll){window.scrollTo({top:0,behavior:'instant'});if(state.item)$('detail-title')?.focus({preventScroll:true});}
    else if(focusKey)document.querySelector('['+focusKey[0]+'="'+focusKey[1]+'"]')?.focus({preventScroll:true});
    else if(focusId && !$(focusId)?.hidden)$(focusId)?.focus({preventScroll:true});
  }
  function reset(){change({q:'',area:'all',program:'all',stage:'all',sort:'featured',item:''});}
  function openContact(id) {
    contactItem=id;const item=data?.items.find(r=>r.id===id),title=item?l(item.title):t('generalSubject');
    $('contact-context').textContent=item?t('contactAbout',{title}):'';
    $('contact-email').href='mailto:marcoslucaspereira1@gmail.com?subject='+encodeURIComponent(t('emailSubject',{title}))+'&body='+encodeURIComponent(t('emailBody',{title}));
    if(!$('contact-dialog').open)$('contact-dialog').showModal();
  }
  function toast(message){clearTimeout(toastTimer);$('toast').textContent=message;$('toast').hidden=false;toastTimer=setTimeout(()=>$('toast').hidden=true,6000);}
  async function load() {
    $('catalog-grid').setAttribute('aria-busy','true');$('results-count').textContent=t('loading');$('catalog-state').hidden=true;
    try{
      const response=await fetch('assets/data/portfolio.json');if(!response.ok)throw new Error('Catalog unavailable');
      const next=await response.json();C.validate(next);data=next;state=C.readState(location.search,data);render();
    }catch{
      $('catalog-grid').setAttribute('aria-busy','false');$('catalog-grid').innerHTML='';$('results-count').textContent='';$('catalog-state').hidden=false;$('catalog-state').innerHTML=emptyState('errorTitle','errorText',true);
    }
  }
  document.addEventListener('click',async event=>{
    const target=event.target.closest('button,a');if(!target)return;
    if(target.dataset.close){$(target.dataset.close).close();return;}
    if(target.hasAttribute('data-contact')){openContact(target.dataset.contact);return;}
    if(target.id==='open-menu'){$('menu-dialog').showModal();return;}
    if(target.closest('#menu-dialog') && target.tagName==='A')$('menu-dialog').close();
    if(target.id==='theme-toggle'){document.documentElement.dataset.theme=document.documentElement.dataset.theme==='light'?'dark':'light';pref.set('pge.theme',document.documentElement.dataset.theme);theme();return;}
    if(target.id==='filter-toggle'){const open=!$('catalog-filters').classList.contains('is-open');$('catalog-filters').classList.toggle('is-open',open);target.setAttribute('aria-expanded',String(open));return;}
    if(target.id==='retry-catalog'){load();return;}
    if(!data)return;
    if(target.dataset.open){if(event.ctrlKey||event.metaKey||event.shiftKey||event.altKey)return;event.preventDefault();change({item:target.dataset.open},{scroll:true});return;}
    if(target.hasAttribute('data-back')){event.preventDefault();change({item:''},{scroll:true});$('explorar').scrollIntoView({block:'start',behavior:'instant'});$('catalog-search').focus({preventScroll:true});return;}
    if(target.dataset.type){change({type:target.dataset.type,area:'all',program:'all',stage:'all',q:''});return;}
    if(target.dataset.areaFilter){change({area:target.dataset.areaFilter});return;}
    if(target.dataset.clearFilter){change({[target.dataset.clearFilter]:target.dataset.clearFilter==='q'?'':'all'});return;}
    if(target.hasAttribute('data-reset')){reset();return;}
    if(target.dataset.programLink){change({type:'training',program:target.dataset.programLink,area:'all',stage:'all',q:'',item:''},{scroll:true});$('explorar').scrollIntoView({block:'start',behavior:'instant'});return;}
    if(target.id==='load-more'){
      const old=state.limit;state.limit+=6;renderCatalog();
      $('catalog-grid').children[old]?.querySelector('.card-title a')?.focus({preventScroll:true});return;
    }
    if(target.id==='share-proposal'){
      try{if(!navigator.clipboard?.writeText)throw new Error();await navigator.clipboard.writeText(new URL(itemURL(state.item),location.href).href);toast(t('copied'));}catch{toast(t('copyFallback'));}
    }
  });
  document.addEventListener('change',event=>{
    if(event.target.id==='locale-select'){
      lang=event.target.value;pref.set('pge.locale',lang);translate();if(data){sync();render();}if($('contact-dialog').open)openContact(contactItem);return;
    }
    if(!data)return;
    if(event.target.id==='catalog-sort')change({sort:event.target.value});
    if(event.target.id==='catalog-stage')change({stage:event.target.value});
    if(event.target.id==='program-filter')change({program:event.target.value,area:'all'});
  });
  $('catalog-search').addEventListener('input',event=>{
    clearTimeout(searchTimer);const value=event.target.value;
    searchTimer=setTimeout(()=>{if(data)change({q:value},{push:false});},160);
  });
  document.querySelectorAll('dialog').forEach(dialog=>dialog.addEventListener('click',event=>{const box=dialog.getBoundingClientRect();if(event.target===dialog&&(event.clientX<box.left||event.clientX>box.right||event.clientY<box.top||event.clientY>box.bottom))dialog.close();}));
  window.addEventListener('popstate',event=>{if(!data || routeKey===location.pathname+location.search)return;routeKey=location.pathname+location.search;state=C.readState(location.search,data);const urlLang=new URLSearchParams(location.search).get('lang');if(['pt','en','es'].includes(urlLang)){lang=urlLang;translate();}render();requestAnimationFrame(()=>window.scrollTo({top:event.state?.scrollY||0,behavior:'instant'}));});
  translate();load();
})();
