'use strict';
window.PGEPublicData=(()=>{
 let config;
 async function rpc(name,body={}){
   if(!['pge_student_public_metrics','pge_public_document'].includes(name))throw Error('unsupported public resource');
   config??=fetch('admin/config.json',{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('config');return r.json()});
   const c=await config;if(!/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(c.supabaseUrl)||typeof c.publishableKey!=='string'||!c.publishableKey.startsWith('sb_publishable_'))throw Error('config');
   const r=await fetch(c.supabaseUrl+'/rest/v1/rpc/'+name,{method:'POST',headers:{apikey:c.publishableKey,'Content-Type':'application/json'},body:JSON.stringify(body),cache:'no-store'});
   if(!r.ok)throw Error('public data unavailable');return r.json();
 }
 function gameUrl(value){
   try{const u=new URL(value,location.href),base=new URL('./',location.href);
    if(u.origin!==base.origin||!u.pathname.startsWith(base.pathname+'jogos/')||!/^jogos\/[a-z0-9][a-z0-9-]*\/index\.html$/.test(u.pathname.slice(base.pathname.length))||u.search||u.hash)return '';
    return u.href;
   }catch{return ''}
 }
 async function games(){
   const doc=await rpc('pge_public_document',{p_path:'dados/catalogo-conteudos.json'});
   const data=doc.exists?JSON.parse(doc.content):await fetch('dados/catalogo-conteudos.json').then(r=>r.json());
   return (data.itens||[]).filter(x=>x.tipo==='jogo'&&x.status==='publicado'&&!x._admin_hidden&&gameUrl(x.link)&&typeof x.titulo==='string'&&x.titulo.trim()).map((x,i)=>({id:'game-'+String(x.id||i),kind:'game',area:'knowledge',title:{pt:x.titulo,en:x.traducoes?.en?.titulo||x.titulo,es:x.traducoes?.es?.titulo||x.titulo},summary:{pt:[x.descricao,x.categoria].filter(Boolean).join(' · '),en:x.traducoes?.en?.descricao||x.descricao||'',es:x.traducoes?.es?.descricao||x.descricao||''},url:gameUrl(x.link),language:'multi',tags:[String(x.categoria||'')]}));
 }
 return {rpc,games,gameUrl};
})();
