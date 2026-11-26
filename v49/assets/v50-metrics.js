'use strict';
(async()=>{
 const $=id=>document.getElementById(id);let portfolio,library,student;
 try{portfolio=await fetch('assets/data/portfolio.json').then(r=>r.json());library=await fetch('assets/data/library.json').then(r=>r.json())}catch{}
 try{student=await PGEPublicData.rpc('pge_student_public_metrics')}catch{}
 const set=(id,v)=>{if($(id))$(id).textContent=Number.isSafeInteger(v)&&v>=0?String(v):'—'};
 set('metric-projects',portfolio?.items.filter(x=>x.type==='project').length);set('metric-programs',portfolio?.programs.length);set('metric-training',portfolio?.items.filter(x=>x.type==='training').length);set('metric-library',library?.filter(x=>x.status!=='planning').length);
 for(const [id,k] of [['metric-students','students'],['student-public-enrollments','enrollments'],['student-public-courses','courses'],['student-public-students','students']])set(id,student?.[k]);
 const mount=$('v50-future');if(mount&&portfolio){for(const item of portfolio.items.filter(x=>x.type==='idea'||['P04','P06'].includes(x.id))){const a=document.createElement('a');a.href='projetos.html?item='+encodeURIComponent(item.id);a.className='v50-future-link';const strong=document.createElement('strong');strong.textContent=item.title.pt;const small=document.createElement('small');small.textContent=item.type==='idea'?'Ideia para o futuro':'Projeto em planejamento';const icon=document.createElementNS('http://www.w3.org/2000/svg','svg');icon.setAttribute('class','icon');icon.setAttribute('aria-hidden','true');const use=document.createElementNS(icon.namespaceURI,'use');use.setAttribute('href','assets/icones.svg#'+(item.id==='P04'?'hands':item.id==='P06'?'plate':'spark'));icon.append(use);a.append(icon,strong,small);mount.append(a)}}
})();
