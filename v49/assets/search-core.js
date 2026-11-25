/* Extraído de assets/search.js da main b87d7e00500d2db7a7c250c3e908763633ef8c31. Ranking preservado. */
(()=>{'use strict';
const norm=x=>String(x||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/\s+/g,' ').trim();
function rank(rows,query){const terms=norm(query).split(' ').filter(Boolean);return rows.filter(x=>terms.every(term=>x.normalized.includes(term))).map(x=>({...x,score:terms.reduce((s,term)=>s+(norm(x.title).includes(term)?5:1),0)})).sort((a,b)=>b.score-a.score||a.title.localeCompare(b.title));}
window.pgeSearchRank=rank;
})();
