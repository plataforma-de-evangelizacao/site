'use strict';
(()=>{
 const app=document.getElementById('app'),card=document.getElementById('aurora-students-card'),button=document.getElementById('aurora-students-open');
 if(!app||!card||!button)return;
 const allowed=()=>!app.hidden&&window.PGEWorkspace?.can('users:manage')===true;
 const sync=()=>{card.hidden=!allowed();document.body.classList.toggle('admin-authenticated',!app.hidden);};
 button.addEventListener('click',()=>{if(!allowed())return;window.pgeAdminBridge.openTab('users');const panel=document.getElementById('student-admin');if(panel){panel.open=true;panel.scrollIntoView({block:'start'});}});
 new MutationObserver(sync).observe(app,{attributes:true,attributeFilter:['hidden']});sync();
})();
