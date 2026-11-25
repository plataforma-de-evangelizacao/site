(()=>{'use strict';const $=id=>document.getElementById(id),cache=new Map(),locale=()=>window.pgeI18n.lang,t=(text,values)=>window.pgeI18n.t(text,values);let request=0,lastKey='';
const load=(path,text=false)=>{if(!cache.has(path))cache.set(path,fetch(path,{credentials:'same-origin'}).then(r=>{if(!r.ok)throw new Error('Daily source unavailable');return text?r.text():r.json();}).catch(e=>{cache.delete(path);throw e;}));return cache.get(path);};
function text(id,value){$(id).replaceChildren(document.createTextNode(value));}
async function refresh(){
 const seq=++request,lang=locale(),day=window.pgeDailySchedule.dayAt();lastKey=day.key;
 text('daily-date',new Intl.DateTimeFormat({pt:'pt-BR',en:'en-US',es:'es'}[lang],{timeZone:'America/Cuiaba',weekday:'long',day:'numeric',month:'long',year:'numeric'}).format(new Date()));
 $('daily-error').hidden=true;
 try{
  const [prayerText,songs,plan,reflections]=await Promise.all([load('assets/data/'+lang+'/oracoes.txt',true),load('assets/data/'+lang+'/louvores.json'),load('assets/data/plano-biblico.json'),load('assets/data/pausa-diaria.json')]);
  if(seq!==request)return;
  const prayers=prayerText.split(/\r?\n/).map(x=>x.trim()).filter(x=>x&&!x.startsWith('#'));
  if(!prayers.length||!songs.length)throw new Error('Daily source empty');
  const prayerIndex=window.pgeDailySchedule.indexFor(day.serial,prayers.length,137),songIndex=window.pgeDailySchedule.indexFor(day.serial,songs.length,3),song=songs[songIndex];
  text('daily-prayer',prayers[prayerIndex]);$('daily-prayer').dataset.locale=lang;$('daily-prayer').lang=lang==='pt'?'pt-BR':lang;text('daily-song',song.titulo);
  $('daily-prayer').dataset.entry=String(prayerIndex);$('daily-song').dataset.entry=String(songIndex);$('daily-prayer').dataset.day=day.key;
  $('daily-song-link').href=song.link||'https://www.youtube.com/results?search_query='+encodeURIComponent(song.titulo);
  const reading=plan.dias[day.key.slice(5)],ul=$('daily-reading');ul.replaceChildren();
  if(reading){for(let i=0;i<reading.referencias.length;i++){const li=document.createElement('li'),a=document.createElement('a');a.textContent=reading.referencias[i];a.href=reading.links[i];a.target='_blank';a.rel='noopener noreferrer';li.append(a);ul.append(li);}}
  else{const li=document.createElement('li');li.textContent=t('Não há leitura cadastrada para esta data.');ul.append(li);}
  const reflection=reflections[window.pgeDailySchedule.indexFor(day.serial,reflections.length)],n={pt:0,en:1,es:2}[lang],box=$('daily-reflection');box.replaceChildren();
  const intro=document.createElement('div'),label=document.createElement('p'),heading=document.createElement('h3'),body=document.createElement('p'),practice=document.createElement('p'),link=document.createElement('a');
  label.className='eyebrow';label.textContent=t('REFLEXÃO PARA HOJE');heading.textContent=reflection.title[n];body.textContent=reflection.text[n];practice.className='daily-practice';practice.textContent=reflection.step[n];link.href=reflection.url;link.target='_blank';link.rel='noopener noreferrer';link.textContent=t('Ler a passagem')+' · '+reflection.ref;link.className='text-button';intro.append(label,heading,body);const next=document.createElement('div');next.append(practice,link);box.append(intro,next);
  window.pgeDailyState={date:day.key,prayerCount:prayers.length,songCount:songs.length,prayerIndex,songIndex,reading:reading?.referencias||[]};
 }catch{
  if(seq!==request)return;text('daily-prayer',t('A oração não carregou. Tente novamente em instantes.'));text('daily-song',t('O louvor não carregou.'));$('daily-song-link').removeAttribute('href');$('daily-error').hidden=false;$('daily-error').textContent=t('Não foi possível carregar as fontes diárias. Recarregue a página para tentar novamente.');
 }
}
window.addEventListener('pge-locale-change',refresh);document.addEventListener('visibilitychange',()=>{if(!document.hidden&&window.pgeDailySchedule.dayAt().key!==lastKey)refresh();});setInterval(()=>{if(window.pgeDailySchedule.dayAt().key!==lastKey)refresh();},60000);refresh();
})();
