/* Calendário civil único da plataforma. Cada ciclo é uma permutação completa. */
(()=>{'use strict';const DAY=86400000,EPOCH=Date.UTC(2026,10,24)/DAY;
const mod=(n,m)=>((n%m)+m)%m,gcd=(a,b)=>b?gcd(b,a%b):a;
function indexFor(serial,length,seed=0){if(!Number.isInteger(length)||length<1)throw new RangeError('Empty daily collection');let step=7919;while(gcd(step,length)!==1)step++;return mod((serial-EPOCH)*step+seed,length);}
function dayAt(now=new Date()){const parts=new Intl.DateTimeFormat('en',{timeZone:'America/Cuiaba',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(now),part=type=>parts.find(x=>x.type===type).value;return {key:part('year')+'-'+part('month')+'-'+part('day'),serial:Date.UTC(+part('year'),+part('month')-1,+part('day'))/DAY};}
const api={indexFor,dayAt};if(typeof window!=='undefined')window.pgeDailySchedule=api;if(typeof module!=='undefined'&&module.exports)module.exports=api;
})();
