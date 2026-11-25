'use strict';
(()=>{
 const app=document.getElementById('app'),card=document.getElementById('aurora-students-card'),button=document.getElementById('aurora-students-open');
 if(!app||!card||!button)return;
 const allowed=()=>!app.hidden&&window.PGEWorkspace?.can('users:manage')===true;
 const sync=()=>{card.hidden=!allowed();document.getElementById('aurora-students-menu').hidden=!allowed();document.body.classList.toggle('admin-authenticated',!app.hidden);document.getElementById('admin-module-search').hidden=app.hidden;};
 button.addEventListener('click',()=>{if(!allowed())return;window.pgeAdminBridge.openTab('users');const panel=document.getElementById('student-admin');if(panel){panel.open=true;panel.scrollIntoView({block:'start'});}});
 const metrics=document.getElementById('metrics'),bars=document.getElementById('admin-v50-bars');
 function draw(){if(!bars)return;bars.replaceChildren();const rows=[...metrics.querySelectorAll('.metric')].map(m=>({name:m.querySelector('span')?.textContent,value:Number(m.querySelector('strong')?.textContent)})).filter(r=>r.name&&Number.isFinite(r.value)&&r.value>=0);const max=Math.max(1,...rows.map(r=>r.value));for(const r of rows){const row=document.createElement('div');row.className='admin-v50-bar';const l=document.createElement('span');l.textContent=r.name;const p=document.createElement('progress');p.value=r.value;p.max=max;p.setAttribute('aria-label',r.name);const b=document.createElement('b');b.textContent=r.value;row.append(l,p,b);bars.append(row)}}
 const chart = bars.closest('section');
 const analysis = document.createElement('div');
 analysis.className = 't077-analysis';
 chart.before(analysis);
 const summary = document.createElement('aside');
 summary.className = 'card t077-summary';
 const details = document.createElement('details');
 const caption = document.createElement('summary');
 caption.textContent = 'Ver todos os indicadores';
 const plot = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
 plot.setAttribute('viewBox', '0 0 640 260');
 plot.setAttribute('role','img');
 plot.setAttribute('aria-label','Totais por categoria, na ordem da lista de indicadores');
 bars.before(plot, details);
 details.append(caption, bars);
 analysis.append(chart, summary);
 function renderGraph() {
   draw();
   const values = [...bars.children].map(row => Number(row.lastChild.textContent));
   plot.replaceChildren();
   summary.replaceChildren();
   const heading = document.createElement('h2');
   heading.textContent = 'Plataforma em números';
   const emblem = document.createElement('div');
   emblem.className = 't077-ring';
   emblem.textContent = '✝';
   summary.append(heading, emblem);
   if (!values.length) return;
   const maximum = Math.max(1,...values);
   function shape(tag, attributes) {
     const element = document.createElementNS(plot.namespaceURI, tag);
     for (const [name,value] of Object.entries(attributes)) element.setAttribute(name,value);
     plot.append(element);
     return element;
   }
   for(let i=0;i<5;i++){
     const y=20+i*50;
     shape('line',{x1:48,x2:625,y1:y,y2:y,stroke:'#7987aa','stroke-opacity':0.25});
     shape('text',{x:4,y:y+4,fill:'var(--muted)','font-size':12}).textContent=Math.round(maximum*(1-i/4));
   }
   const points = values.map((value,index)=>[48+index*577/Math.max(1,values.length-1),220-200*value/maximum]);
   shape('polygon',{points:[[48,220],...points,[625,220]].join(' '),fill:'#1764d4','fill-opacity':0.22});
   shape('polyline',{points:points.join(' '),fill:'none',stroke:'#20bcf1','stroke-width':3,'stroke-linejoin':'round'});
   points.forEach(([cx,cy],index)=>{
     const dot=shape('circle',{cx,cy,r:4,fill:'#bd85f1'});
     const title=document.createElementNS(plot.namespaceURI,'title');
     title.textContent=bars.children[index].textContent;
     dot.append(title);
     shape('text',{x:cx,y:247,fill:'var(--muted)','text-anchor':'middle','font-size':12}).textContent=index+1;
   });
   for(const row of [...bars.children].slice(0,3)){
     const line=document.createElement('p');
     line.append(row.firstChild.cloneNode(true),row.lastChild.cloneNode(true));
     summary.append(line);
   }
 }
 document.getElementById('aurora-students-menu').addEventListener('click',()=>button.click());
 new MutationObserver(renderGraph).observe(metrics,{childList:true,subtree:true});renderGraph();
 document.getElementById('admin-module-query').addEventListener('input',e=>{const q=e.target.value.trim().toLowerCase();for(const b of document.querySelectorAll('.admin-sidebar nav button'))b.style.display=b.textContent.toLowerCase().includes(q)?'':'none';});
 document.getElementById('aurora-games-open').addEventListener('click',()=>{if(app.hidden)return;if(window.pgeAdminBridge.chooseDocument('dados/catalogo-conteudos.json'))window.pgeAdminBridge.openTab('documents');});
 new MutationObserver(sync).observe(app,{attributes:true,attributeFilter:['hidden']});sync();
})();
