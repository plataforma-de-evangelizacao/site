"""Biblioteca V3: processamento local; chave somente no ambiente do runner."""
import unicodedata, copy, datetime as dt, hashlib, json, os, random, re, time
from metadata import enrich
from pathlib import Path
from urllib import request, parse, error
from zoneinfo import ZoneInfo
UTC=dt.timezone.utc
ALG='3.0.0'
VIDEO=re.compile(r'^[\w-]{11}$',re.ASCII)
class Stop(Exception): pass
class Temporary(Exception): pass
class Permanent(Exception): pass

def stamp(): return dt.datetime.now(UTC).isoformat()
def instant(s): return dt.datetime.fromisoformat(s.replace('Z','+00:00'))
def age(s,now): return (now-instant(s)).total_seconds()/86400 if s else float('inf')
def atomic(path,value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    raw=json.dumps(value,ensure_ascii=False,indent=2)+'\n'
    if path.exists() and path.read_text()==raw:return False
    tmp=path.with_suffix('.tmp');tmp.write_text(raw);os.replace(tmp,path);return True

def fresh_state():
    return dict(version=3,queues={k:[] for k in ['discovery','verification','maintenance']},rounds={},cache={},videos={},records={},checks={},quota={},reports=[],lastPublishedHash='')

def validate_state(s):
    assert s['version']==3 and all(isinstance(s[k],dict) for k in ['queues','rounds','cache','videos','records','checks','quota'])
    for q in s['queues'].values():
        assert isinstance(q,list) and len({t['id'] for t in q})==len(q)
        for t in q:assert t['state'] in ['pending','processing','completed','retry_wait','failed','cancelled']
    for id,r in s['records'].items():assert VIDEO.fullmatch(id) and r['id']==id

def query_key(op,params):
    params=copy.deepcopy(params)
    if op=='search' and 'target' in params:params['target']=' '.join(params['target'].split()).casefold()
    return hashlib.sha256(json.dumps([ALG,op,params],sort_keys=True,separators=(',',':')).encode()).hexdigest()

def enqueue(s,routine,op,target,params,now,round_id,priority=5):
    key=query_key(op,{'target':target,**params})
    q=s['queues'][routine]
    if any(t['key']==key and t['state'] not in ['completed','cancelled','failed'] for t in q):return
    q.append(dict(id=key+'-'+round_id,key=key,op=op,target=target,params=params,created=now.isoformat(),lastAttempt=None,attempts=0,state='pending',priority=priority,nextEligible=now.isoformat(),lastError=None,round=round_id))

class API:
    """Limites locais não conhecem o consumo por outras aplicações do mesmo projeto."""
    def __init__(self,key,cfg,s,save,transport=None,sleep=time.sleep):
        self.key=key;self.cfg=cfg;self.s=s;self.save=save;self.sleep=sleep
        self.transport=transport or self.http;self.calls={};self.runSearch=0;self.runOther=0;self.response_seconds=[];self.last_event={};self.on_event=None
    def notify(self,stage,endpoint,attempt):
        self.last_event={'stage':stage,'endpoint':endpoint,'attempt':attempt}
        if self.on_event:
            try:self.on_event(self.last_event)
            except Exception:pass
    def http(self,endpoint,params):
        url='https://www.googleapis.com/youtube/v3/'+endpoint+'?'+parse.urlencode(params)
        req=request.Request(url,headers={'X-Goog-Api-Key':self.key})
        with request.urlopen(req,timeout=25) as response:return json.load(response)
    def call(self,endpoint,**params):
        if not self.key:raise Stop('missing_credentials')
        day=dt.datetime.now(ZoneInfo('America/Los_Angeles')).date().isoformat()
        q=self.s['quota'].setdefault(day,dict(search=0,other=0))
        typ='search' if endpoint=='search' else 'other'
        margin=1-self.cfg['quotaSafetyMarginPercent']/100
        for attempt in range(self.cfg['maxRetries']+1):
            run=self.runSearch if typ=='search' else self.runOther
            maxrun=self.cfg['maxSearchCallsPerRun'] if typ=='search' else self.cfg['maxOtherCallsPerRun']
            limit=int(self.cfg['dailySearchCalls' if typ=='search' else 'dailyOtherUnits']*margin)
            if q[typ]>=limit or run>=maxrun:raise Stop('internal_budget_exhausted')
            q[typ]+=1
            if typ=='search':self.runSearch+=1
            else:self.runOther+=1
            self.calls[endpoint]=self.calls.get(endpoint,0)+1
            self.save() # reserve before request; crash cannot spend an uncounted call
            self.notify('api_request',endpoint,attempt+1)
            started=time.monotonic()
            try:
                out=self.transport(endpoint,params)
                if not isinstance(out,dict) or not isinstance(out.get('items'),list):raise Temporary('invalid_api_response')
                self.response_seconds=(self.response_seconds+[time.monotonic()-started])[-100:]
                self.notify('api_response',endpoint,attempt+1)
                return out
            except error.HTTPError as e:
                self.notify('api_retry',endpoint,attempt+1)
                reasons=[]
                try:reasons=[x.get('reason','') for x in json.loads(e.read()).get('error',{}).get('errors',[])]
                except (ValueError,AttributeError):pass
                if any(x in ['quotaExceeded','dailyLimitExceeded','dailyLimitExceededUnreg'] for x in reasons):raise Stop('youtube_quota_exhausted') from None
                if e.code in [401,403] and not any(x=='rateLimitExceeded' for x in reasons):raise Stop('authentication_or_permissions_'+str(e.code)) from None
                if e.code not in [429,500,502,503,504] and 'rateLimitExceeded' not in reasons:raise Permanent('api_http_'+str(e.code)) from None
                wait=e.headers.get('Retry-After','') if e.headers else ''
                try:wait=float(wait)
                except ValueError:
                    try:
                        from email.utils import parsedate_to_datetime
                        wait=max(0,(parsedate_to_datetime(wait)-dt.datetime.now(UTC)).total_seconds())
                    except Exception:wait=0
                if wait>30:raise Temporary('retry_after_deferred') from None
            except (error.URLError,TimeoutError,OSError,ValueError):
                self.notify('api_retry',endpoint,attempt+1);wait=0
            if attempt==self.cfg['maxRetries']:raise Temporary('temporary_api_failure') from None
            self.sleep(min(30,max(wait,2**attempt+random.random())))
        raise Temporary('temporary_api_failure')

def seconds(duration):
    m=re.fullmatch(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?',duration or '')
    return sum(int(x or 0)*w for x,w in zip(m.groups(),[3600,60,1])) if m else None

def technical(v,region):
    st=v.get('status',{});details=v.get('contentDetails',{})
    if st.get('privacyStatus')!='public' or st.get('uploadStatus') not in [None,'processed']:return 'unavailable'
    rr=details.get('regionRestriction',{})
    if region in rr.get('blocked',[]) or ('allowed' in rr and region not in rr['allowed']):return 'region_restricted'
    if not st.get('embeddable',False):return 'embed_restricted'
    return 'available'

def classify(v,editorial,cfg):
    sn=v.get('snippet',{});title=sn.get('title','')[:500];body=sn.get('description','')[:5000]
    n=(title+' '+body).casefold()
    blocked=any(x in title.casefold() for x in cfg['excludedTitleTerms'])
    categoria='desenho' if any(x in n for x in ['desenho','animaç','animaç','animated','animation']) else ('serie' if any(x in n for x in ['série','serie','episód','episod','temporada']) else ('filme' if 'filme' in n or 'movie' in n else None))
    ed=editorial or {};verified=ed.get('revisado') is True
    # Metadata is evidence for discovery, never a theological or age certificate.
    r=dict(id=v['id'],titulo=ed.get('tituloExibicao') or title,descricao=ed.get('descricaoExibicao') or ed.get('descricao',body),tituloOriginal=title,descricaoOriginal=body,testamento=ed.get('testamento'),livros=ed.get('livros',[]),referencias=ed.get('referencias',[]),personagens=ed.get('personagens',[]),temas=ed.get('temas',[]),categoria=ed.get('categoria',categoria),formato=ed.get('formato'),publico=ed.get('publico'),idioma=ed.get('idioma',sn.get('defaultAudioLanguage') or sn.get('defaultLanguage')),idiomaVerificado=bool(verified and ed.get('idiomaVerificado')),duracao=seconds(v.get('contentDetails',{}).get('duration')),canalId=sn.get('channelId'),canalNome=sn.get('channelTitle'),playlistId=ed.get('playlistId'),serieId=ed.get('serieId'),temporada=ed.get('temporada'),episodio=ed.get('episodio'),url='https://www.youtube.com/watch?v='+v['id'],thumbnail=next((x['url'] for k in ['high','medium','default'] if isinstance((x:=sn.get('thumbnails',{}).get(k)),dict) and str(x.get('url','')).startswith('https://i.ytimg.com/')),None),disponibilidade=technical(v,cfg['region']),aprovacao='pending_review',fonteClassificacao='metadados: sugestão automática; aguardando revisão')
    if ed.get('aprovacao') in ['rejected','archived']:r['aprovacao']=ed['aprovacao']
    elif verified and ed.get('aprovacao')=='pending_review':pass
    elif verified and ed.get('aprovacao')=='approved' and r['categoria'] in ['desenho','filme','serie']:
        r['aprovacao']='approved';r['fonteClassificacao']='revisão editorial por vídeo'
    elif cfg['autoApprovalEnabled'] and not blocked:
        for rule in cfg.get('approvedRules',[]):
            source_matches=rule.get('anyChannel') is True or sn.get('channelId')==rule.get('channelId')
            if not (rule.get('approved') and source_matches and re.search(rule['titlePattern'],title,re.I)):continue
            if rule.get('requireBiblicalTitle') and not re.search(rule['biblicalTitlePattern'],title,re.I):continue
            audio=sn.get('defaultAudioLanguage','')
            # Prefer explicit audio language; a conflicting audio declaration cannot be overridden by a title.
            pt_title=bool(re.search(r'portugu[eê]s|pt[ -]?br|dublad[oa].*portugu[eê]s',title,re.I))
            portuguese=audio.startswith('pt') or (not audio and pt_title)
            if rule.get('requirePortugueseMetadata') and not portuguese:continue
            if r['duracao'] is None or r['duracao']<rule.get('minDurationSeconds',0):continue
            if r['categoria'] not in ['desenho','filme','serie']:continue
            if r['categoria']=='filme' and r['duracao']<1200:continue
            r.update({k:rule[k] for k in ['categoria','idioma','idiomaVerificado','publico'] if k in rule})
            if rule.get('requirePortugueseMetadata'):
                r['idioma']=audio or 'pt';r['idiomaVerificado']=True
                r['verificacaoIdioma']='declaração de áudio da API' if audio else 'declaração explícita no título; não auditada por escuta'
            r['aprovacao']='approved';r['fonteClassificacao']='seleção automática por metadados: '+rule['id']+'; sem análise de fidelidade bíblica';break
    if blocked and r['aprovacao']=='pending_review':r['motivoRevisao']='Formato possivelmente excluído (trailer, análise, música ou pregação).'
    if v.get('status',{}).get('madeForKids') is True and 'publico' not in ed:r['publico']='infantil'
    r['tags']=[str(x)[:100] for x in sn.get('tags',[])[:40]] if isinstance(sn.get('tags'),list) else []
    r.update(source_status=ed.get('source_status','pending'),source_url=ed.get('source_url'),ai_generated=ed.get('ai_generated',False),theme=ed.get('theme','biblico'))
    return enrich(r,sn,protected=ed.keys())

def discovery_relevant(record):
    # Conservative metadata evidence for candidate discovery, never proof of rights or doctrine.
    text=' '.join(str(record.get(k) or '') for k in ['tituloOriginal','descricaoOriginal'])
    text=''.join(c for c in unicodedata.normalize('NFD',text) if not unicodedata.combining(c)).casefold()
    if record.get('livros') or record.get('personagens'):return True
    return bool(re.search(r'\b(biblic[oa]s?|biblia|jesus|cristo|cristaos?|cristas?|gospel|evangelico|deus|fe|superacao|esperanca|milagre|perdao|a cabana|quarto de guerra|desafiando gigantes)\b',text))

def validate_catalog(c,tax):
    assert c['versao']==3 and isinstance(c['itens'],list)
    if c['itens']:assert c.get('validUntil') and instant(c['validUntil']).tzinfo is not None
    ids=set();books={b['id']:b for b in tax['livros']}
    for r in c['itens']:
        assert VIDEO.fullmatch(r['id']) and r['id'] not in ids;ids.add(r['id'])
        assert r['aprovacao']=='approved' and r['disponibilidade'] in ['available','embed_restricted']
        assert r['categoria'] in ['desenho','filme','serie'] and isinstance(r['titulo'],str) and r['titulo'].strip()
        assert r['url']=='https://www.youtube.com/watch?v='+r['id']
        assert r.get('source_status')=='verified'
        assert isinstance(r['duracao'],(int,type(None))) and (r['duracao'] is None or r['duracao']>=0)
        for b in r['livros']:assert b in books
        assert r['testamento'] in [None,'antigo','novo']
        if r.get('temporada') is not None:assert isinstance(r['temporada'],int) and r['temporada']>0 and r.get('serieId')
        if r.get('episodio') is not None:assert isinstance(r['episodio'],int) and r['episodio']>0 and r.get('serieId')
        for ref in r['referencias']:
            assert ref['livro'] in books
            assert isinstance(ref['capitulo'],int) and 1<=ref['capitulo']<=books[ref['livro']]['capitulos']
            # Verse precision is editorial; do not infer a verse range from a title.
            assert ref.get('revisada') is True
            for k in ['versiculoInicial','versiculoFinal']:
                if k in ref:assert isinstance(ref[k],int) and ref[k]>0
            if 'versiculoInicial' in ref and 'versiculoFinal' in ref:assert ref['versiculoFinal']>=ref['versiculoInicial']

def public_catalog(s,tax,now,cfg):
    items=[]
    for id,r in sorted(s['records'].items()):
        check=s['checks'].get(id,{})
        if r['aprovacao']!='approved' or r['disponibilidade'] not in ['available','embed_restricted','suspected_unavailable']:continue
        if age(check.get('verified'),now)>=cfg['maxMetadataAgeDays']:continue
        if r.get('source_status')!='verified':continue
        item={k:v for k,v in r.items() if k!='motivoRevisao'}
        if item['disponibilidade']=='suspected_unavailable':item['disponibilidade']='available'
        items.append(item)
    validUntil=min(((instant(s['checks'][r['id']]['verified'])+dt.timedelta(days=cfg['maxMetadataAgeDays'])).isoformat() for r in items),default=None)
    c=dict(versao=3,itens=items,validUntil=validUntil);validate_catalog(c,tax);return c

class Engine:
    def __init__(self,root,state_path,api_factory=None,now=None):
        self.root=Path(root);self.path=Path(state_path);self.now=now or dt.datetime.now(UTC)
        ctl=self.root/'biblioteca-controle'
        self.cfg=json.loads((ctl/'config.json').read_text());self.sources=json.loads((ctl/'fontes.json').read_text());self.editorial=json.loads((ctl/'editorial.json').read_text())
        self.tax=json.loads((self.root/'dados/biblioteca/taxonomia.json').read_text())
        if self.cfg['allowPaidServices'] or self.cfg['allowAutomaticQuotaIncrease']:raise ValueError('paid_services_forbidden')
        if not 1<=self.cfg['maxVideoIdsPerBatch']<=50 or not 1<=self.cfg['maxSearchResultsPerPage']<=50:raise ValueError('api_batch_limit')
        if not 0<=self.cfg['quotaSafetyMarginPercent']<100:raise ValueError('quota_margin')
        self.s=json.loads(self.path.read_text()) if self.path.exists() else fresh_state();validate_state(self.s)
        self.metrics=dict(videoIdsRequested=0,newVideos=0,duplicatesAvoided=0,blockedIgnored=0,foundIds=0)
        self.started=time.monotonic();self.api=(api_factory(self) if api_factory else API(os.getenv('YOUTUBE_API_KEY',''),self.cfg,self.s,self.save))
    def save(self):validate_state(self.s);atomic(self.path,self.s)
    def schedule(self):
        intervals=dict(discovery=10,verification=15,maintenance=25)
        intervals.update(self.cfg['intervalDays'])
        for routine,days in intervals.items():
            q=self.s['queues'][routine];rd=self.s['rounds'].setdefault(routine,dict(nextDue=self.now.isoformat(),lastSuccess=None))
            # Recover confirmed progress and expired leases; never erase unfinished tasks.
            for t in q:
                if t['state']=='processing' and age(t['lastAttempt'],self.now)*86400>=self.cfg['leaseSeconds']:t['state']='pending'
            if instant(rd['nextDue'])>self.now:continue
            round_id=self.now.strftime('%Y%m%dT%H%M%S')
            if routine=='discovery':
                manual=self.root/'biblioteca-controle/links-para-revisao.json'
                if manual.exists():
                    entries=json.loads(manual.read_text());rows=entries.get('itens',[]) if isinstance(entries,dict) else entries
                    ids=[x.get('id','') for x in rows if isinstance(x,dict)]
                    if ids:enqueue(self.s,routine,'manual',','.join(ids),{},self.now,round_id,0)
                for ch in self.sources['canais']:
                    if ch.get('approved') and not ch.get('blocked'):enqueue(self.s,routine,'channel',ch['id'],{},self.now,round_id,1)
                for pl in self.sources['playlists']:
                    if pl.get('approved') and not pl.get('blocked'):enqueue(self.s,routine,'playlist',pl['id'],{},self.now,round_id,2)
                for query in self.sources['buscas']:enqueue(self.s,routine,'search',query,{},self.now,round_id,5)
            elif routine=='verification':
                ids=[id for id,r in self.s['records'].items() if r['aprovacao'] not in ['rejected','archived']]
                for i in range(0,len(ids),50):enqueue(self.s,routine,'verify',','.join(ids[i:i+50]),{},self.now,round_id,1)
            else:enqueue(self.s,routine,'audit','all',{},self.now,round_id)
            # Cadence preserved even while an older round remains open.
            due=instant(rd['nextDue'])
            while due<=self.now:due+=dt.timedelta(days=days)
            rd['nextDue']=due.isoformat()
        self.save()
    def details(self,ids,force=False,discovery=False):
        original_count=len(ids)
        ids=list(dict.fromkeys(x for x in ids if VIDEO.fullmatch(x)))
        self.metrics['duplicatesAvoided']+=original_count-len(ids)
        self.metrics['foundIds']+=len(ids)
        before=len(ids)
        ids=[x for x in ids if x not in self.sources['blockedVideos'] and self.editorial.get(x,{}).get('aprovacao') not in ['rejected','archived'] and (force or self.editorial.get(x,{}).get('reabrir') is True or self.s['records'].get(x,{}).get('aprovacao') not in ['rejected','archived'])]
        self.metrics['blockedIgnored']+=before-len(ids)
        needed=[x for x in ids if force or self.s['records'].get(x,{}).get('aprovacao')!='approved' and age(self.s['videos'].get(x,{}).get('at'),self.now)>=self.cfg['videoCacheDays']]
        self.metrics['duplicatesAvoided']+=len(ids)-len(needed)
        if not needed:return
        for start in range(0,len(needed),self.cfg['maxVideoIdsPerBatch']):
            batch=needed[start:start+self.cfg['maxVideoIdsPerBatch']];self.metrics['videoIdsRequested']+=len(batch);out=self.api.call('videos',part='snippet,contentDetails,status',id=','.join(batch),maxResults=50)
            returned={v.get('id'):v for v in out['items'] if isinstance(v,dict)}
            if any(id not in batch for id in returned):raise Temporary('unexpected_video_id')
            # Block mass unavailability including explicit privacy and regional changes.
            affected=[id for id in batch if id in self.s['records'] and self.s['records'][id].get('disponibilidade') in ['available','embed_restricted'] and (id not in returned or technical(returned[id],self.cfg['region']) not in ['available','embed_restricted'])]
            active=sum(id in self.s['records'] for id in batch)
            if force and active and len(affected)/active>self.cfg['massUnavailablePercent']/100:raise Temporary('mass_change_guard_requires_review')
            for id in batch:
                if id in self.sources['blockedVideos']:continue
                v=returned.get(id);
                blocked_channels={c['id'] for c in self.sources['canais'] if c.get('blocked')}
                if v and v.get('snippet',{}).get('channelId') in blocked_channels:
                    if id in self.s['records']:self.s['records'][id]['aprovacao']='rejected'
                    continue
                ck=self.s['checks'].setdefault(id,{})
                if not v:
                    ck['misses']=ck.get('misses',0)+1;ck['lastMissing']=self.now.isoformat()
                    if id in self.s['records']:
                        # Independent confirmation on a later daily task; do not remove on a transport error.
                        self.s['records'][id]['disponibilidade']='suspected_unavailable' if ck['misses']<2 else 'unavailable'
                    if ck['misses']<2:
                        enqueue(self.s,'verification','verify',id,{'confirmation':True},self.now,self.now.strftime('%Y%m%dT%H%M%S'),0)
                        for task in self.s['queues']['verification']:
                            if task['target']==id and task['params'].get('confirmation') and task['state']=='pending':task['nextEligible']=(self.now+dt.timedelta(days=1)).isoformat()
                    continue
                ck.update(verified=self.now.isoformat(),misses=0)
                self.s['videos'][id]=dict(at=self.now.isoformat(),data=v)
                ed=self.editorial.get(id,{})
                # Rejected IDs remain tombstones and cannot reappear by discovery.
                old=self.s['records'].get(id,{})
                if old.get('aprovacao') in ['rejected','archived'] and not ed.get('reabrir'):continue
                rec=classify(v,ed,self.cfg)
                if discovery and not ed.get('revisado') and not discovery_relevant(rec):
                    self.metrics['irrelevantIgnored']=self.metrics.get('irrelevantIgnored',0)+1;continue
                if not old:self.metrics['newVideos']+=1
                rec['dataInclusao']=old.get('dataInclusao',self.now.isoformat())
                relevant_old={k:v for k,v in old.items() if k!='ultimaVerificacao'}
                if relevant_old!={k:v for k,v in rec.items() if k!='ultimaVerificacao'}:
                    rec['ultimaVerificacao']=self.now.isoformat();self.s['records'][id]=rec
            self.save()
    def discover(self,t):
        op=t['op'];target=t['target'];params=t['params'];key=t['key'];cached=self.s['cache'].get(key)
        if cached and age(cached['at'],self.now)<self.cfg['discoveryCacheDays'] and cached['state']=='completed':
            self.details(cached['ids'],discovery=True);return
        if op=='channel':
            out=self.api.call('channels',part='contentDetails',id=target)
            for c in out['items']:
                pl=c.get('contentDetails',{}).get('relatedPlaylists',{}).get('uploads')
                if pl:enqueue(self.s,'discovery','playlist',pl,{},self.now,t['round'],1)
            return
        token=params.get('pageToken');call=dict(maxResults=self.cfg['maxSearchResultsPerPage'])
        if token:call['pageToken']=token
        if op=='playlist':out=self.api.call('playlistItems',part='contentDetails',playlistId=target,**call);ids=[x.get('contentDetails',{}).get('videoId','') for x in out['items']]
        else:
            call.update(part='snippet',type='video',q=target,relevanceLanguage='pt',regionCode=self.cfg['region'],safeSearch='strict',order='relevance')
            out=self.api.call('search',**call);ids=[x.get('id',{}).get('videoId','') for x in out['items']]
        ids=list(dict.fromkeys(x for x in ids if VIDEO.fullmatch(x)))
        self.s['cache'][key]=dict(at=self.now.isoformat(),expires=(self.now+dt.timedelta(days=self.cfg['discoveryCacheDays'])).isoformat(),ids=ids,params={'operation':op,'target':target,**params},algorithm=ALG,state='details_pending',pagination=out.get('nextPageToken'))
        # Persist returned IDs before any follow-up API call.
        self.save();self.details(ids,discovery=True)
        self.s['cache'][key]['state']='completed'
        page=params.get('page',1)
        if out.get('nextPageToken') and page<self.cfg['maxSearchPagesPerQuery']:
            enqueue(self.s,'discovery',op,target,{'pageToken':out['nextPageToken'],'page':page+1},self.now,t['round'],t['priority'])
    def audit(self):
        # Validate editorial/collection references deterministically; uncertain theology remains pending.
        all_ids=set(self.s['records'])
        collections=json.loads((self.root/'dados/biblioteca/colecoes.json').read_text())
        assert len({c['id'] for c in collections['itens']})==len(collections['itens'])
        for c in collections['itens']:
            assert isinstance(c['titulo'],str) and all(VIDEO.fullmatch(v) for v in c['videos'])
        episodes=set()
        for r in self.s['records'].values():
            if r.get('serieId') and r.get('episodio') is not None:
                key=(r['serieId'],r.get('temporada'),r['episodio'])
                if key in episodes:r['aprovacao']='pending_review';r['motivoRevisao']='Episódio com classificação conflitante.'
                episodes.add(key)
        # Drop expired provider metadata, retain only IDs and editorial decisions/history.
        stale=[id for id,v in self.s['videos'].items() if age(v['at'],self.now)>=self.cfg['maxMetadataAgeDays']]
        for id in stale:self.s['videos'].pop(id,None)
        for id,r in self.s['records'].items():
            if age(self.s['checks'].get(id,{}).get('verified'),self.now)>=self.cfg['maxMetadataAgeDays']:
                for k in ['titulo','descricao','tituloOriginal','descricaoOriginal','thumbnail','canalNome','idioma','duracao','tags']:r[k]=None
        for key in list(self.s['cache']):
            if age(self.s['cache'][key]['at'],self.now)>=self.cfg['maxMetadataAgeDays']:del self.s['cache'][key]
        for q in self.s['queues'].values():q[:]=[t for t in q if t['state'] not in ['completed','cancelled'] or age(t['created'],self.now)<25]
        public_catalog(self.s,self.tax,self.now,self.cfg)
    def apply_editorial(self):
        # Editorial tombstones survive metadata expiry and apply even without cached API data.
        for id,decision in self.editorial.items():
            if decision.get('aprovacao') in ['rejected','archived'] and id in self.s['records']:
                self.s['records'][id]['aprovacao']=decision['aprovacao']
        for id,entry in self.s['videos'].items():
            blocked_channels={c['id'] for c in self.sources['canais'] if c.get('blocked')}
            if id in self.sources['blockedVideos'] or entry['data'].get('snippet',{}).get('channelId') in blocked_channels:
                if id in self.s['records']:self.s['records'][id]['aprovacao']='rejected'
                continue
            if age(entry['at'],self.now)>=self.cfg['maxMetadataAgeDays']:continue
            old=self.s['records'].get(id,{})
            ed=self.editorial.get(id,{})
            if old.get('aprovacao') in ['rejected','archived'] and not ed.get('reabrir'):continue
            rec=classify(entry['data'],ed,self.cfg)
            rec['dataInclusao']=old.get('dataInclusao',self.now.isoformat())
            rec['ultimaVerificacao']=old.get('ultimaVerificacao',entry['at'])
            rec['disponibilidade']=old.get('disponibilidade',rec['disponibilidade'])
            self.s['records'][id]=rec
        self.save()
    def run(self,smoke=False):
        if smoke:
            # One configured videos.list request, no global search and no automatic publication.
            id=self.cfg.get('smokeVideoId','')
            if not VIDEO.fullmatch(id):raise ValueError('configure_smokeVideoId_first')
            self.details([id],force=True);self.save()
            if id not in self.s['videos']:raise ValueError('smoke_video_not_public')
            return {'smoke':'success','returned':id in self.s['videos'],'calls':self.api.calls}
        new_due=any(age(self.s['rounds'].get(k,{}).get('nextDue'),self.now)>=0 for k in ['discovery','verification','maintenance'])
        if not new_due:
            factor=self.cfg['backlogDailyPercent']/100
            self.api.cfg=dict(self.cfg,maxSearchCallsPerRun=max(1,int(self.cfg['maxSearchCallsPerRun']*factor)),maxOtherCallsPerRun=max(1,int(self.cfg['maxOtherCallsPerRun']*factor)))
        self.schedule();initial=sum(len([t for t in q if t['state'] in ['pending','retry_wait','processing']]) for q in self.s['queues'].values())
        processed=0;errors=[];stop=False
        # Round-robin tasks across queues, oldest first; deferred tasks do not starve another routine.
        while not stop:
            progress=False
            for name in ['verification','maintenance','discovery']:
                if time.monotonic()-self.started>self.cfg['maxRunSeconds']:stop=True;break
                q=sorted(self.s['queues'][name],key=lambda t:(t['created'],t['priority'],t['id']))
                eligible=[t for t in q if t['state'] in ['pending','retry_wait'] and instant(t['nextEligible'])<=self.now]
                if not eligible:continue
                t=eligible[0];t.update(state='processing',lastAttempt=self.now.isoformat(),attempts=t['attempts']+1);self.save()
                try:
                    if t['op']=='audit':self.audit()
                    elif t['op']=='manual':self.details(t['target'].split(','))
                    elif t['op']=='verify':self.details(t['target'].split(','),True)
                    else:
                        c=self.s['cache'].get(t['key'])
                        if c and c['state']=='details_pending':self.details(c['ids']);c['state']='completed'
                        else:self.discover(t)
                    t['state']='completed';t['lastError']=None;processed+=1;progress=True
                except Stop as ex:
                    t.update(state='retry_wait',lastError=str(ex),nextEligible=(self.now+dt.timedelta(days=1)).isoformat());errors.append(str(ex));stop=True
                except Temporary as ex:
                    t.update(state='failed' if t['attempts']>=10 else 'retry_wait',lastError=str(ex),nextEligible=(self.now+dt.timedelta(days=1)).isoformat());errors.append(str(ex));progress=True
                except Permanent as ex:t.update(state='failed',lastError=str(ex));errors.append(str(ex));progress=True
                self.save()
                if stop:break
            if not progress:break
        # Purge stale API data every day, independently of the 25-day editorial audit.
        self.audit()
        for name,q in self.s['queues'].items():
            if not any(t['state'] in ['pending','processing','retry_wait'] for t in q):self.s['rounds'][name]['lastSuccess']=self.now.isoformat()
        remaining=sum(t['state'] in ['pending','processing','retry_wait'] for q in self.s['queues'].values() for t in q)
        report=dict(**self.metrics,unavailable=sum(r['disponibilidade']=='unavailable' for r in self.s['records'].values()),estimatedQuota=dict(searchCalls=self.api.runSearch,otherUnits=self.api.runOther),routines={k:dict(nextDue=v['nextDue'],lastSuccess=v['lastSuccess']) for k,v in self.s['rounds'].items()},at=self.now.isoformat(),durationSeconds=round(time.monotonic()-self.started,2),initial=initial,completed=processed,remaining=remaining,errors=errors,calls=self.api.calls,pendingReview=sum(r['aprovacao']=='pending_review' for r in self.s['records'].values()),estimatedDailyRuns=(remaining+processed-1)//processed if processed else None)
        self.s['reports']=(self.s['reports']+[report])[-25:];self.save();return report
