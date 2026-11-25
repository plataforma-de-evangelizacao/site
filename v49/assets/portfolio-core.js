(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PortfolioCore = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const types = ['all', 'project', 'training', 'tool', 'idea'];
  function normalize(value) { return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim(); }
  function local(value, lang) { return value && typeof value === 'object' ? value[lang] || value.pt || '' : value || ''; }
  function readState(search, data) {
    const q = new URLSearchParams(search);
    return {type: types.includes(q.get('type')) ? q.get('type') : 'project', area: data.areas.some(a => a.id === q.get('area')) ? q.get('area') : 'all', program: q.get('program') === 'community' || data.programs.some(p => p.id === q.get('program')) ? q.get('program') : 'all', stage: ['planning','idea','active'].includes(q.get('stage')) ? q.get('stage') : 'all', sort: q.get('sort') === 'az' ? 'az' : 'featured', q: (q.get('q') || '').slice(0,160), item: q.get('item') || '', limit: 6};
  }
  function filter(data, state, lang = 'pt') {
    const words = normalize(state.q).split(/\s+/).filter(Boolean);
    let items = data.items.filter(item => {
      if (state.type !== 'all' && item.type !== state.type) return false;
      if (state.area !== 'all' && item.area !== state.area) return false;
      if (state.stage !== 'all' && item.status !== state.stage) return false;
      if (state.program === 'community' && !item.community) return false;
      if (state.program !== 'all' && state.program !== 'community' && !(item.programs || []).includes(state.program)) return false;
      const area = data.areas.find(a => a.id === item.area);
      const programNames = data.programs.filter(p => (item.programs || []).includes(p.id)).map(p => local(p.title, lang));
      const text = normalize([item.id,local(item.title,lang),local(item.summary,lang),local(item.audience,lang),local(area?.title,lang),...programNames].join(' '));
      return words.every(word => text.includes(word));
    });
    if (state.sort === 'az') items.sort((a,b) => local(a.title,lang).localeCompare(local(b.title,lang),lang));
    else {
      const highlights = ['P13','P01','P06','P04','P14','P05','P02','P03','P07','P08','P09','P10','P11','P12','formacao-comunitaria-p13','formacao-comunitaria-p01','formacao-casais'];
      items = items.map((item,index) => ({item,score:highlights.includes(item.id)? highlights.indexOf(item.id) : highlights.length + index})).sort((a,b)=>a.score-b.score).map(x=>x.item);
    }
    return items;
  }
  function related(data, item) {
    const direct = data.items.filter(r => (item.related || []).includes(r.id));
    if (direct.length) return direct;
    if (item.type === 'training' || item.type === 'tool') return data.items.filter(r => r.id !== item.id && (r.type === 'training' || r.type === 'tool') && r.programs.some(p => item.programs.includes(p))).slice(0,3);
    return [];
  }
  function stateURL(state, lang, pathname = 'projetos.html') {
    const q = new URLSearchParams(); q.set('lang',lang);
    for (const key of ['type','area','program','stage','sort','q','item']) {
      const value = state[key];
      if (value && value !== 'all' && !(key === 'type' && value === 'project') && !(key === 'sort' && value === 'featured')) q.set(key,value);
    }
    return pathname + '?' + q.toString();
  }
  function validate(data) {
    const ids = new Set();
    for (const item of data.items) {
      if (ids.has(item.id)) throw new Error('Duplicate catalog ID: '+item.id);
      ids.add(item.id);
      if (!types.includes(item.type) || item.type === 'all') throw new Error('Invalid type: '+item.id);
      if (!['planning','idea'].includes(item.status)) throw new Error('Unverified operational status: '+item.id);
      if (!data.areas.some(a => a.id === item.area)) throw new Error('Missing area: '+item.id);
      for (const field of ['title','summary']) for (const lang of ['pt','en','es']) if (!item[field]?.[lang]) throw new Error('Missing translation: '+item.id+'/'+field+'/'+lang);
      for (const program of item.programs) if (!data.programs.some(p => p.id === program)) throw new Error('Missing program: '+item.id);
    }
    for (const item of data.items) for (const id of [...item.related,...item.projects]) if (!ids.has(id)) throw new Error('Missing relation: '+id);
    return true;
  }
  return {normalize,local,readState,filter,related,stateURL,validate,types};
});
