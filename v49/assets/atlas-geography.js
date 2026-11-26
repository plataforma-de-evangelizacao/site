(() => {
  'use strict';
  const features = new Map();
  const loaded = new Map();
  const colors = {housing:'#e8b977',food:'#f4c970',clothes:'#b49cf0',care:'#f39abf',health:'#7cdec5',protection:'#f9997d',education:'#83cbfb',response:'#b4e68e',all:'#74dbed'};
  const states = {
    11:['RO','Rondônia'],12:['AC','Acre'],13:['AM','Amazonas'],14:['RR','Roraima'],15:['PA','Pará'],16:['AP','Amapá'],17:['TO','Tocantins'],
    21:['MA','Maranhão'],22:['PI','Piauí'],23:['CE','Ceará'],24:['RN','Rio Grande do Norte'],25:['PB','Paraíba'],26:['PE','Pernambuco'],27:['AL','Alagoas'],28:['SE','Sergipe'],29:['BA','Bahia'],
    31:['MG','Minas Gerais'],32:['ES','Espírito Santo'],33:['RJ','Rio de Janeiro'],35:['SP','São Paulo'],41:['PR','Paraná'],42:['SC','Santa Catarina'],43:['RS','Rio Grande do Sul'],
    50:['MS','Mato Grosso do Sul'],51:['MT','Mato Grosso'],52:['GO','Goiás'],53:['DF','Distrito Federal']
  };
  const api = 'https://servicodados.ibge.gov.br/api/';
  let territories, refresh, hasData = () => false;
  const names = name => ({pt:name,en:name,es:name});
  const stateId = code => code === '51' ? 'mt' : 'uf-' + code;
  async function read(url) {
    const response = await fetch(url, {signal:AbortSignal.timeout(15000)});
    if (!response.ok) throw new Error('HTTP ' + response.status);
    return response.json();
  }
  function add(id, label, title, parent, polygons, level, center) {
    const corners = [180,90,-180,-90];
    for (const poly of polygons) for (const [x,y] of poly[0]) {
      corners[0]=Math.min(corners[0],x); corners[1]=Math.min(corners[1],y);
      corners[2]=Math.max(corners[2],x); corners[3]=Math.max(corners[3],y);
    }
    const [x,y] = center || [(corners[0]+corners[2])/2,(corners[1]+corners[3])/2];
    const zoom = Math.min(level===2?78:level===1?27:12, Math.max(2, 138/Math.max(.5,corners[2]-corners[0],corners[3]-corners[1])));
    features.set(id,{id,label,title,parent,polygons,level,corners,x,y});
    const entry = territories.find(item=>item[0]===id);
    if (entry) entry[5]=zoom;
    else territories.push([id,title,parent,x,y,zoom]);
  }
  function layer(key,load) {
    if (loaded.has(key)) return loaded.get(key);
    const pending=load().then(refresh).catch(()=>{
      loaded.delete(key);
      const status=document.getElementById('atlas-boundary-status');
      if (status) status.textContent='Limites locais indisponíveis no momento. Você pode continuar navegando no mapa.';
    });
    loaded.set(key,pending);
    return pending;
  }
  const polygons = feature => feature.geometry.type==='Polygon'?[feature.geometry.coordinates]:feature.geometry.coordinates;
  function loadStates(){
    return layer('states',async()=>{
      const args='?formato=application%2Fvnd.geo%2Bjson&intrarregiao=UF&qualidade=minima';
      const data=await read(api+'v4/malhas/paises/BR'+args);
      for(const feature of data.features){
        const code=String(feature.properties.codarea);
        if(!states[code]||!feature.geometry)continue;
        const [abbr,name]=states[code];
        add(stateId(code),abbr,names(name),'br',polygons(feature),1);
      }
    });
  }
  function loadCities(code){
    return layer('cities-'+code,async()=>{
      let data, lookup;
      try{
        [data,lookup]=await Promise.all([
          read(api+'v4/malhas/estados/'+code+'?formato=application%2Fvnd.geo%2Bjson&intrarregiao=municipio&qualidade=minima'),
          read(api+'v1/localidades/estados/'+code+'/municipios')
        ]);
      }catch{
        data=await read('https://raw.githubusercontent.com/tbrugz/geodata-br/master/geojson/geojs-'+code+'-mun.json');
        lookup=[];
      }
      const byId=new Map(lookup.map(({id,nome})=>[String(id),nome]));
      for(const feature of data.features){
        const p=feature.properties, id=String(p.codarea??p.id);
        const name=byId.get(id)||p.name;
        if(!name||!feature.geometry)continue;
        add(name==='Nova Bandeirantes'?'nb':'mun-'+id,name,names(name),stateId(code),polygons(feature),2);
      }
    });
  }
  async function loadChildren(id){
    if(id==='br'||id==='mt'||id==='nb'||id.startsWith('uf-')||id.startsWith('mun-')) await loadStates();
    if(id==='mt'||id==='nb') await loadCities('51');
    else if(id.startsWith('uf-')||id.startsWith('mun-')) await loadCities(id.slice(id.indexOf('-')+1,id.indexOf('-')+3));
  }
  function inside(ring,x,y){
    let found=false;
    for(let i=0,j=ring.length-1;i<ring.length;j=i++){
      const [xi,yi]=ring[i], [xj,yj]=ring[j];
      if(((yi>y)!==(yj>y))&&x<(xj-xi)*(y-yi)/(yj-yi)+xi) found=!found;
    }
    return found;
  }
  function hit(x,y,zoom){
    let best;
    for(const feature of features.values()){
      if(feature.level===1&&zoom<3||feature.level===2&&zoom<9||best&&best.level>=feature.level)continue;
      const [a,b,c,d]=feature.corners;
      if(x<a||x>c||y<b||y>d)continue;
      if(feature.polygons.some(poly=>inside(poly[0],x,y)&&!poly.slice(1).some(ring=>inside(ring,x,y))))best=feature;
    }
    return best?.id;
  }
  function paint({ctx,proj,line,width,height,zoom,territory,category,light}){
    for(const feature of features.values()){
      if(feature.level===1&&zoom<3||feature.level===2&&zoom<9)continue;
      const selected=feature.id===territory;
      const available=hasData(feature.id,category,Object.values(feature.title));
      ctx.strokeStyle=selected?'#f7d083':light?'#29475c99':'#c7ebf388';
      ctx.lineWidth=selected?2:feature.level?.7:.85;
      for(const poly of feature.polygons)for(const ring of poly)line(ring);
      const [x,y,z]=proj(feature.x,feature.y);
      if(z<=0||x<8||x>width-8||y<10||y>height-8)continue;
      if(available){
        ctx.fillStyle=colors[category]||colors.all;
        ctx.beginPath();
        ctx.arc(x,y,4,0,Math.PI*2);
        ctx.fill();
      }
      if(!selected&&zoom>=(feature.level===2?25:feature.level===1?5:1.8)){
        ctx.fillStyle=light?'#122c3e':'#eff8ff';
        ctx.font=feature.level===2?'11px system-ui':'600 12px system-ui';
        ctx.textAlign='center';
        ctx.fillText(feature.label,x,y-5,105);
      }
    }
  }
  function init(all,callback){
    territories=all;refresh=callback;
    layer('countries',async()=>{
      const countries=await read('assets/data/atlas-countries.json');
      for(const [id,abbr,name,parent,x,y,rings] of countries) add(id,abbr,name,parent,rings,0,[x,y]);
      all.sort((a,b)=> (b[0]==='world')-(a[0]==='world') || a[1].pt.localeCompare(b[1].pt,'pt-BR'));
    });
  }
  window.AtlasGeo={init,paint,hit,loadChildren,colors,setCoverage(fn){hasData=fn}};
})();
