(()=>{
'use strict';
const $=id=>document.getElementById(id);
const get=(k)=>{try{return localStorage.getItem(k)}catch{return null}};
const put=(k,v)=>{try{localStorage.setItem(k,v)}catch{}};
const labels={pt:'Cuide-se',en:'Take care',es:'Cuídate'};
const copy={
en:['A SPACE FOR YOU','You deserve care. Explore ways to care for yourself and your community, at your own pace.','Educational space; not a substitute for professional care.','Back to home','Body and rest','Respect your limits, take breaks and maintain healthy sleep and movement habits.','Listening and support','Talk to someone you trust and seek professional support when needed.','Faith and spiritual life','Set aside time for prayer, reading and reflection.','Relationships and community','Cultivate connections, respect, fellowship and mutual support.','Food and nutrition','Value regular, varied meals and hydration.','Digital well-being','Take breaks, protect your privacy and choose content thoughtfully.','Recovery and new beginnings','Discover professional and community support for dependencies.','Inclusion and accessibility','Respect different needs and ways of participating.'],
es:['UN ESPACIO PARA TI','Mereces cuidado. Explora formas de cuidarte y cuidar a la comunidad, a tu ritmo.','Espacio educativo; no sustituye la atención profesional.','Volver al inicio','Cuerpo y descanso','Respeta tus límites, organiza pausas y mantén hábitos adecuados de sueño y movimiento.','Escucha y acogida','Habla con alguien de confianza y busca apoyo profesional cuando sea necesario.','Fe y vida espiritual','Reserva tiempo para la oración, la lectura y la reflexión.','Relaciones y comunidad','Cultiva vínculos, respeto, convivencia y apoyo mutuo.','Alimentación y nutrición','Valora las comidas regulares y variadas y la hidratación.','Bienestar digital','Establece pausas, protege tu privacidad y elige contenidos con discernimiento.','Recuperación y nuevos comienzos','Conoce vías de apoyo profesional y comunitario para las dependencias.','Inclusión y accesibilidad','Respeta diferentes necesidades y formas de participación.']
};
const nodes=[...document.querySelectorAll('[data-care]'),...document.querySelectorAll('.care-card > h2,.care-card > p')];copy.pt=nodes.map(e=>e.textContent);
let lang=new URLSearchParams(location.search).get('lang')||get('pge.locale')||'pt';if(!labels[lang])lang='pt';
function t(k){return k==='care'?labels[lang]:window.PortfolioCopy[lang][k]}
function theme(){const light=document.documentElement.dataset.theme==='light';const b=$('theme-toggle');b.querySelector('use').setAttribute('href','assets/portfolio-icons.svg#'+(light?'moon':'sun'));b.setAttribute('aria-label',t(light?'darkTheme':'lightTheme'));b.setAttribute('aria-pressed',String(light))}
function render(){document.documentElement.lang=lang==='pt'?'pt-BR':lang;document.title=labels[lang]+' · PGE';$('locale-select').value=lang;document.querySelectorAll('[data-t]').forEach(e=>{const s=t(e.dataset.t);if(s)e.textContent=s});document.querySelectorAll('[data-label]').forEach(e=>{const s=t(e.dataset.label);if(s)e.setAttribute('aria-label',s)});nodes.forEach((e,i)=>e.textContent=copy[lang][i]);theme()}
$('locale-select').addEventListener('change',e=>{lang=e.target.value;put('pge.locale',lang);render()});
$('theme-toggle').addEventListener('click',()=>{document.documentElement.dataset.theme=document.documentElement.dataset.theme==='light'?'dark':'light';put('pge.theme',document.documentElement.dataset.theme);theme()});
$('open-menu').addEventListener('click',()=>$('menu-dialog').showModal());
document.querySelectorAll('[data-close]').forEach(b=>b.addEventListener('click',()=>$(b.dataset.close).close()));
render();
})();
