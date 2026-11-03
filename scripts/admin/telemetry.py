"""Private workflow telemetry. Counters describe work actually performed, never a timer."""
import datetime as dt,json,os,re,time
from pathlib import Path
from sync import Client
class Reporter:
 def __init__(self):self.id=os.getenv('ADMIN_REQUEST','');self.client=Client();self.last=0;self.enabled=bool(re.fullmatch(r'[0-9a-f-]{36}',self.id) and self.client.url and self.client.key)
 def emit(self,phase,stage='api',progress=None,stats=None,force=False):
  if not self.enabled or (not force and time.monotonic()-self.last<1):return
  self.last=time.monotonic()
  try:
   query='id=eq.'+self.id;rows=self.client.call('pge_commands',query+'&select=status,result')
   if not rows or rows[0]['status'] in ['applied','failed','conflict']:return
   try:old=json.loads(rows[0].get('result') or '{}')
   except (ValueError,TypeError):old={}
   info={**old,'stage':stage,'phase':phase,'heartbeat':dt.datetime.now(dt.timezone.utc).isoformat()}
   if progress is not None:info['progress']=max(old.get('progress',0),min(99,progress))
   if stats is not None:info['stats']={**old.get('stats',{}),**stats}
   repo=os.getenv('GITHUB_REPOSITORY','');run=os.getenv('GITHUB_RUN_ID','')
   if re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',repo) and run.isdigit():info['url']='https://github.com/'+repo+'/actions/runs/'+run
   self.client.call('pge_commands',query,'PATCH',dict(status='processing',result=json.dumps(info,ensure_ascii=False),updated_at=info['heartbeat']))
  except Exception:pass # A progress outage must not destroy a persisted batch.
 def engine(self,engine,phase='Consultando a API do YouTube',force=False):
  if not self.enabled:return
  tasks=[t for q in engine.s['queues'].values() for t in q];complete=sum(t['state']=='completed' for t in tasks);remaining=sum(t['state'] in ['pending','processing','retry_wait'] for t in tasks)
  api=engine.api
  stats={**engine.metrics,'completedTasks':complete,'remainingTasks':remaining,'pendingReview':sum(r['aprovacao']=='pending_review' for r in engine.s['records'].values()),'searchCalls':api.runSearch,'otherCalls':api.runOther,'maxSearchCalls':api.cfg['maxSearchCallsPerRun'],'maxOtherCalls':api.cfg['maxOtherCallsPerRun'],'dailySearchLimit':api.cfg['dailySearchCalls'],'quotaSafetyMarginPercent':api.cfg['quotaSafetyMarginPercent'],'maxSeconds':engine.cfg['maxRunSeconds'],'elapsedSeconds':round(time.monotonic()-engine.started),'etaSeconds':None}
  samples=getattr(api,'response_seconds',[]);event=getattr(api,'last_event',{});stage=event.get('stage','api')
  if samples:stats.update(meanResponseSeconds=round(sum(samples)/len(samples),3),lastResponseSeconds=round(samples[-1],3),responseSamples=len(samples))
  stats['requestTimeoutSeconds']=25
  if phase=='Consultando a API do YouTube':phase={'api_request':'GitHub Actions consultando o YouTube. Aguardando resposta da API.','api_response':'Resposta do YouTube recebida. Classificando os metadados.','api_retry':'Nova tentativa de conexão com o YouTube.'}.get(stage,phase)
  self.emit(phase,stage=stage,progress=35+int(40*complete/max(1,complete+remaining)),stats=stats,force=force)
