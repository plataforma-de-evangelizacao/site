'use strict';
(()=>{
 const app=document.getElementById('app'),card=document.getElementById('aurora-students-card'),button=document.getElementById('aurora-students-open');
 if(!app||!card||!button)return;
 const allowed=()=>!app.hidden&&window.PGEWorkspace?.can('users:manage')===true;
 const sync=()=>{card.hidden=!allowed();document.getElementById('aurora-students-menu').hidden=!allowed();document.body.classList.toggle('admin-authenticated',!app.hidden);document.getElementById('admin-module-search').hidden=app.hidden;};
 button.addEventListener('click',()=>{if(!allowed())return;window.pgeAdminBridge.openTab('users');const panel=document.getElementById('student-admin');if(panel){panel.open=true;panel.scrollIntoView({block:'start'});}});
 const metrics=document.getElementById('metrics'),bars=document.getElementById('admin-v50-bars');
 function draw(){if(!bars)return;bars.replaceChildren();const rows=[...metrics.querySelectorAll('.metric')].map(m=>({name:m.querySelector('span')?.textContent,value:Number(m.querySelector('strong')?.textContent)})).filter(r=>r.name&&Number.isFinite(r.value)&&r.value>=0);const max=Math.max(1,...rows.map(r=>r.value));for(const r of rows){const row=document.createElement('div');row.className='admin-v50-bar';const l=document.createElement('span');l.textContent=r.name;const p=document.createElement('progress');p.value=r.value;p.max=max;p.setAttribute('aria-label',r.name);const b=document.createElement('b');b.textContent=r.value;row.append(l,p,b);bars.append(row)}}
 document.getElementById('aurora-students-menu').addEventListener('click',()=>button.click());
 new MutationObserver(draw).observe(metrics,{childList:true,subtree:true});draw();
 document.getElementById('admin-module-query').addEventListener('input',e=>{const q=e.target.value.trim().toLowerCase();for(const b of document.querySelectorAll('.admin-sidebar nav button'))b.style.display=b.textContent.toLowerCase().includes(q)?'':'none';});
 document.getElementById('aurora-games-open').addEventListener('click',()=>{if(app.hidden)return;if(window.pgeAdminBridge.chooseDocument('dados/catalogo-conteudos.json'))window.pgeAdminBridge.openTab('documents');});
 new MutationObserver(sync).observe(app,{attributes:true,attributeFilter:['hidden']});sync();
})();
