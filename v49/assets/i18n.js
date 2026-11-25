(()=>{'use strict';
const supported=['pt','en','es'],saved=()=>{try{return localStorage.getItem('pge.locale');}catch{return null;}},url=new URL(location.href);
let lang=[url.searchParams.get('lang'),saved(),'pt'].find(x=>supported.includes(x));
const originals=new WeakMap(),attributes=new WeakMap();
function t(text,values={}){const entry=window.PGE_TRANSLATIONS?.[text];let translated=lang==='pt'?text:entry?.[lang==='en'?0:1]||text;for(const [key,value] of Object.entries(values))translated=translated.replaceAll('{'+key+'}',String(value));return translated;}
function render(root=document.body){
 const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT,{acceptNode(node){return node.parentElement?.closest('script,style,option,[data-dynamic-locale]')?NodeFilter.FILTER_REJECT:NodeFilter.FILTER_ACCEPT;}});let node;
 while((node=walker.nextNode())){const original=originals.get(node)??node.nodeValue;originals.set(node,original);const key=original.trim();if(!key)continue;const translated=t(key);node.nodeValue=original.slice(0,original.indexOf(key))+translated+original.slice(original.indexOf(key)+key.length);}
 for(const element of root.querySelectorAll('[aria-label],[title],[placeholder]')){
  if(element.closest('[data-dynamic-locale]')||element.id==='theme-toggle'||element.id==='motion-toggle')continue;
  let initial=attributes.get(element);if(!initial){initial={};for(const attr of ['aria-label','title','placeholder'])if(element.hasAttribute(attr))initial[attr]=element.getAttribute(attr);attributes.set(element,initial);}
  for(const [attr,value] of Object.entries(initial))element.setAttribute(attr,t(value));
 }
}
function setLocale(value,announce=true){
 if(!supported.includes(value))return;lang=value;document.documentElement.lang={pt:'pt-BR',en:'en',es:'es'}[lang];
 const select=document.getElementById('locale-select');if(select)select.value=lang;
 document.title=t('Início · Plataforma Global de Evangelização · V50');render();
 if(announce){try{localStorage.setItem('pge.locale',lang);}catch{}const next=new URL(location.href);next.searchParams.set('lang',lang);history.replaceState(null,'',next);}
 window.dispatchEvent(new CustomEvent('pge-locale-change',{detail:{lang}}));
}
window.pgeI18n={t,render,get lang(){return lang;},setLocale};
document.getElementById('locale-select').addEventListener('change',e=>setLocale(e.target.value));setLocale(lang,false);
})();
