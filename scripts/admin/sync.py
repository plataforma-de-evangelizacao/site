"""Ponte Supabase → GitHub. Sem dependências externas, sem credenciais públicas."""
import argparse, copy, datetime as dt, hashlib, json, os, re, subprocess, sys
from pathlib import Path
from urllib import request,parse,error
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts/biblioteca'))
from core import VIDEO,atomic,instant
ALLOWED={
 'dados/projetos.json':'Projetos e cursos','dados/rede-parceiros.json':'Parceiros e comunidades',
 'dados/agenda-solidaria.json':'Agenda solidária','dados/prestacao-contas.json':'Prestação de contas',
 'dados/parcerias.json':'Contato e parcerias','dados/louvores.json':'Louvores',
 'dados/leituras.json':'Cronograma de leituras','dados/lives.json':'Lives',
 'dados/spotify.json':'Spotify','dados/artigos.json':'Artigos','dados/estudos.json':'Estudos',
 'dados/livros.json':'Livros','dados/materiais-ensino.json':'Biblioteca de ensino',
 'dados/comunidades.json':'Celebrações e comunidades','dados/atividades-parcerias.json':'Atividades',
 'dados/biblioteca/colecoes.json':'Coleções audiovisuais',
 'biblioteca-controle/editorial.json':'Decisões editoriais dos vídeos'}

# Author-managed content; generated API catalogs and security settings remain excluded.
for path,label in {'dados/acoes.json': 'Acoes', 'dados/acolhimento.json': 'Acolhimento', 'dados/agenda-solidaria.json': 'Agenda solidaria', 'dados/artigos.json': 'Artigos', 'dados/atividades-parcerias.json': 'Atividades parcerias', 'dados/autocuidado.json': 'Autocuidado', 'dados/biblias-e-apps.json': 'Biblias e apps', 'dados/biblias-pdf.json': 'Biblias pdf', 'dados/biblioteca/colecoes.json': 'Colecoes', 'dados/buscando.json': 'Buscando', 'dados/catalogo-conteudos.json': 'Catalogo conteudos', 'dados/comunidades.json': 'Comunidades', 'dados/corpo-escolhas.json': 'Corpo escolhas', 'dados/en/acoes.json': 'Acoes · English', 'dados/en/acolhimento.json': 'Acolhimento · English', 'dados/en/artigos.json': 'Artigos · English', 'dados/en/autocuidado.json': 'Autocuidado · English', 'dados/en/biblias-e-apps.json': 'Biblias e apps · English', 'dados/en/biblias-pdf.json': 'Biblias pdf · English', 'dados/en/buscando.json': 'Buscando · English', 'dados/en/catalogo.txt': 'Catalogo · English', 'dados/en/corpo-escolhas.json': 'Corpo escolhas · English', 'dados/en/espirito-santidade.json': 'Espirito santidade · English', 'dados/en/estudos.json': 'Estudos · English', 'dados/en/fe-conhecimento.json': 'Fe conhecimento · English', 'dados/en/interface.json': 'Interface · English', 'dados/en/leituras.json': 'Leituras · English', 'dados/en/lives.json': 'Lives · English', 'dados/en/livros.json': 'Livros · English', 'dados/en/louvores.json': 'Louvores · English', 'dados/en/materiais-ensino.json': 'Materiais ensino · English', 'dados/en/midias-biblicas.json': 'Midias biblicas · English', 'dados/en/oracoes.txt': 'Oracoes · English', 'dados/en/pagina-inicial.json': 'Pagina inicial · English', 'dados/en/palestras.json': 'Palestras · English', 'dados/en/parceiros.json': 'Parceiros · English', 'dados/en/parcerias.json': 'Parcerias · English', 'dados/en/pausa-diaria.json': 'Pausa diaria · English', 'dados/en/pecado.json': 'Pecado · English', 'dados/en/recursos-santidade.txt': 'Recursos santidade · English', 'dados/en/reflexoes.txt': 'Reflexoes · English', 'dados/en/spotify.json': 'Spotify · English', 'dados/en/temas-biblicos.json': 'Temas biblicos · English', 'dados/en/versiculos.json': 'Versiculos · English', 'dados/en/youtube.json': 'Youtube · English', 'dados/es/acoes.json': 'Acoes · Español', 'dados/es/acolhimento.json': 'Acolhimento · Español', 'dados/es/artigos.json': 'Artigos · Español', 'dados/es/autocuidado.json': 'Autocuidado · Español', 'dados/es/biblias-e-apps.json': 'Biblias e apps · Español', 'dados/es/biblias-pdf.json': 'Biblias pdf · Español', 'dados/es/buscando.json': 'Buscando · Español', 'dados/es/catalogo.txt': 'Catalogo · Español', 'dados/es/corpo-escolhas.json': 'Corpo escolhas · Español', 'dados/es/espirito-santidade.json': 'Espirito santidade · Español', 'dados/es/estudos.json': 'Estudos · Español', 'dados/es/fe-conhecimento.json': 'Fe conhecimento · Español', 'dados/es/interface.json': 'Interface · Español', 'dados/es/leituras.json': 'Leituras · Español', 'dados/es/lives.json': 'Lives · Español', 'dados/es/livros.json': 'Livros · Español', 'dados/es/louvores.json': 'Louvores · Español', 'dados/es/materiais-ensino.json': 'Materiais ensino · Español', 'dados/es/midias-biblicas.json': 'Midias biblicas · Español', 'dados/es/oracoes.txt': 'Oracoes · Español', 'dados/es/pagina-inicial.json': 'Pagina inicial · Español', 'dados/es/palestras.json': 'Palestras · Español', 'dados/es/parceiros.json': 'Parceiros · Español', 'dados/es/parcerias.json': 'Parcerias · Español', 'dados/es/pausa-diaria.json': 'Pausa diaria · Español', 'dados/es/pecado.json': 'Pecado · Español', 'dados/es/recursos-santidade.txt': 'Recursos santidade · Español', 'dados/es/reflexoes.txt': 'Reflexoes · Español', 'dados/es/spotify.json': 'Spotify · Español', 'dados/es/temas-biblicos.json': 'Temas biblicos · Español', 'dados/es/versiculos.json': 'Versiculos · Español', 'dados/es/youtube.json': 'Youtube · Español', 'dados/espirito-santidade.json': 'Espirito santidade', 'dados/estudos.json': 'Estudos', 'dados/fe-conhecimento.json': 'Fe conhecimento', 'dados/formacoes.json': 'Formacoes', 'dados/ideias-sociais.json': 'Ideias sociais', 'dados/leituras.json': 'Leituras', 'dados/lives.json': 'Lives', 'dados/livros.json': 'Livros', 'dados/louvores.json': 'Louvores', 'dados/materiais-ensino.json': 'Materiais ensino', 'dados/midias-biblicas.json': 'Midias biblicas', 'dados/oracoes.txt': 'Oracoes', 'dados/pagina-inicial.json': 'Pagina inicial', 'dados/palestras.json': 'Palestras', 'dados/parceiros.json': 'Parceiros', 'dados/parcerias.json': 'Parcerias', 'dados/pausa-diaria.json': 'Pausa diaria', 'dados/pecado.json': 'Pecado', 'dados/planejamento.json': 'Planejamento', 'dados/prestacao-contas.json': 'Prestacao contas', 'dados/projetos.json': 'Projetos', 'dados/recursos-santidade.txt': 'Recursos santidade', 'dados/rede-parceiros.json': 'Rede parceiros', 'dados/reflexoes.txt': 'Reflexoes', 'dados/spotify.json': 'Spotify', 'dados/temas-biblicos.json': 'Temas biblicos', 'dados/versiculos.json': 'Versiculos', 'dados/youtube.json': 'Youtube'}.items():
 ALLOWED.setdefault(path,label)

def sha(text):return hashlib.sha256(text.encode()).hexdigest()
def canonical(v):return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':'))
def git(*args):
 p=subprocess.run(['git','-C',str(ROOT),*args],capture_output=True,text=True)
 if p.returncode:raise RuntimeError('git_failed_'+args[0])
 return p.stdout.strip()

class Client:
 def __init__(self):
  self.url=os.getenv('SUPABASE_URL','').rstrip('/');self.key=os.getenv('SUPABASE_SERVICE_ROLE_KEY','')
  if self.url and not re.fullmatch(r'https://[a-z0-9-]+\.supabase\.co',self.url):raise ValueError('invalid_supabase_url')
 def call(self,table,query='',method='GET',data=None):
  headers={'apikey':self.key,'Content-Type':'application/json','Prefer':'return=minimal,resolution=merge-duplicates'}
  if self.key.count('.')==2:headers['Authorization']='Bearer '+self.key
  payload=None if data is None else json.dumps(data,ensure_ascii=False).encode()
  req=request.Request(self.url+'/rest/v1/'+table+('?' +query if query else ''),data=payload,method=method,headers=headers)
  with request.urlopen(req,timeout=30) as response:
   raw=response.read();return json.loads(raw) if raw else []

def snapshot(state):
 rows=[];now=dt.datetime.now(dt.timezone.utc)
 for id,r in state.get('records',{}).items():
  checked=state.get('checks',{}).get(id,{}).get('verified')
  if not checked or (now-instant(checked)).total_seconds()>=29*86400 or not r.get('titulo'):continue
  # Don't export raw provider responses or internal logs to the browser.
  record={k:r.get(k) for k in ['id','titulo','descricao','categoria','idioma','idiomaVerificado','aprovacao','disponibilidade','fonteClassificacao','canalNome','duracao','ultimaVerificacao']}
  rows.append(dict(id=id,record=record,sha=sha(canonical(record)),expires_at=(instant(checked)+dt.timedelta(days=29)).isoformat(),updated_at=now.isoformat()))
 return rows

def load_remote_state():
 git('fetch','--no-tags','origin','refs/heads/biblioteca-estado')
 return json.loads(git('show','FETCH_HEAD:estado.json'))

def export(client,state=None):
 state=state if state is not None else load_remote_state()
 rows=snapshot(state)
 for i in range(0,len(rows),100):client.call('pge_videos','on_conflict=id','POST',rows[i:i+100])
 client.call('pge_videos','expires_at=lt.'+parse.quote(dt.datetime.now(dt.timezone.utc).isoformat(),safe=''),'DELETE')
 docs=[]
 for path in ALLOWED:
  file=ROOT/path
  if file.exists():
   content=file.read_text()
   if path.endswith('.json'):json.loads(content)
   docs.append(dict(path=path,content=content,sha=sha(content),updated_at=dt.datetime.now(dt.timezone.utc).isoformat()))
 if docs:client.call('pge_documents','on_conflict=path','POST',docs)
 return dict(videos=len(rows),documents=len(docs))

def apply_command(command,records):
 payload=command['payload']
 if command['action']=='review_video':
  # One authorized command/commit can hold up to 300 independent decisions.
  items=payload.get('items',[payload])
  if not isinstance(items,list) or not 1<=len(items)<=300:raise ValueError('invalid_batch_size')
  file=ROOT/'biblioteca-controle/editorial.json';data=json.loads(file.read_text());seen=set()
  for item in items:
   if not isinstance(item,dict):raise ValueError('invalid_batch_item')
   id=item.get('id','')
   if not isinstance(id,str) or not VIDEO.fullmatch(id) or id in seen:raise ValueError('invalid_video_id')
   seen.add(id);operation=item.get('operation','review');entry=data.get(id,{})
   if operation=='restore':
    if entry.get('aprovacao') not in ['rejected','archived']:raise ValueError('conflict_not_blocked')
    if item.get('expected_block_sha')!=sha(canonical(entry)):raise ValueError('conflict_block_changed')
    entry.update(aprovacao='pending_review',revisado=True,reabrir=True)
   else:
    current=records.get(id)
    if not current or item.get('expected_sha')!=current['sha']:raise ValueError('conflict_video_changed')
    if operation=='category':
     if entry.get('aprovacao') in ['rejected','archived']:raise ValueError('conflict_video_blocked')
     if item.get('categoria') not in ['desenho','filme','serie']:raise ValueError('select_category')
     entry.update(categoria=item['categoria'],revisado=True) # Does not approve or confirm language.
     if 'aprovacao' not in entry:entry['aprovacao']=current.get('record',{}).get('aprovacao','pending_review')
     if entry['aprovacao']=='approved':
      record=current.get('record',{})
      if not record.get('idiomaVerificado') or not str(record.get('idioma','')).startswith('pt'):raise ValueError('confirm_portuguese_first')
      entry.update(revisado=True,reabrir=True,idioma=record['idioma'],idiomaVerificado=True)
    elif operation=='review':
     decision=item.get('decision')
     if decision not in ['approved','rejected','archived','pending_review']:raise ValueError('invalid_decision')
     if decision=='approved':
      if item.get('portuguese_confirmed') is not True:raise ValueError('confirm_portuguese_first')
      if item.get('categoria') not in ['desenho','filme','serie']:raise ValueError('select_category')
      entry.update(revisado=True,aprovacao=decision,reabrir=True,categoria=item['categoria'],idioma='pt-BR',idiomaVerificado=True)
     else:entry.update(aprovacao=decision,revisado=True,reabrir=decision=='pending_review')
    else:raise ValueError('invalid_video_operation')
   data[id]=entry
  return 'biblioteca-controle/editorial.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n'
 if command['action']=='save_json':
  path=payload.get('path')
  if path not in ALLOWED:raise ValueError('path_not_allowed')
  file=ROOT/path;current=file.read_text()
  if payload.get('expected_sha')!=sha(current):raise ValueError('conflict_document_changed')
  text=payload.get('content')
  if not isinstance(text,str) or len(text.encode())>1048576:raise ValueError('invalid_content_size')
  if path.endswith('.json'):json.loads(text)
  elif not text.strip():raise ValueError('invalid_empty_text')
  return path,text if text.endswith('\n') else text+'\n'
 raise ValueError('action_not_allowed')

def validate_change(path,text):
 file=ROOT/path;old=file.read_text()
 try:
  file.write_text(text)
  check=subprocess.run([sys.executable,str(ROOT/'scripts/validar_site.py')],cwd=ROOT,capture_output=True,text=True)
  if check.returncode:raise ValueError('site_validation_failed')
  if path=='biblioteca-controle/editorial.json':
   data=json.loads(text)
   if not isinstance(data,dict):raise ValueError('invalid_editorial')
   for id,r in data.items():
    if not VIDEO.fullmatch(id) or not isinstance(r,dict) or r.get('aprovacao') not in ['approved','rejected','archived','pending_review']:raise ValueError('invalid_editorial_record')
    if r.get('aprovacao')=='approved' and (r.get('revisado') is not True or r.get('categoria') not in ['desenho','filme','serie'] or r.get('idiomaVerificado') is not True or not str(r.get('idioma','')).startswith('pt')):raise ValueError('invalid_editorial_approval')
    books={b['id']:b for b in json.loads((ROOT/'dados/biblioteca/taxonomia.json').read_text())['livros']}
    for ref in r.get('referencias',[]):
     if ref.get('livro') not in books or not isinstance(ref.get('capitulo'),int) or not 1<=ref['capitulo']<=books[ref['livro']]['capitulos'] or ref.get('revisada') is not True:raise ValueError('invalid_scripture_reference')
 finally:file.write_text(old)

def current_reviews():
 return snapshot(load_remote_state())

def brief_payload(command):
 payload=command.get('payload',{})
 if 'items' in payload:
  return {'items':[{k:v for k,v in item.items() if k in ['id','operation','decision','categoria']} for item in payload['items']], 'count':len(payload['items'])}
 return {k:v for k,v in payload.items() if k in ['id','path','decision','expected_sha','operation','categoria','target']}


def dispatch_library(command,mode):
 token=os.getenv('GH_TOKEN','');repo=os.getenv('GITHUB_REPOSITORY','')
 if not token or not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',repo):raise ValueError('invalid_github_dispatch_configuration')
 id=command['id']
 if not re.fullmatch(r'[0-9a-f-]{36}',id):raise ValueError('invalid_request_id')
 body=json.dumps({'ref':'main','inputs':{'modo':mode,'admin_request':id}}).encode()
 req=request.Request('https://api.github.com/repos/'+repo+'/actions/workflows/biblioteca.yml/dispatches',data=body,method='POST',headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','Content-Type':'application/json','X-GitHub-Api-Version':'2022-11-28'})
 with request.urlopen(req,timeout=30) as response:response.read()

def sync_command(client,command):
 target=command.get('payload',{}).get('target')
 if target not in ['video-discovery','site-publication','panel-sync']:raise ValueError('invalid_sync_target')
 # Never dispatch a second workflow for a command already handed to GitHub.
 if command.get('status')=='processing':
  # A callback can be interrupted; reconcile on later scheduled runs using this request's run title.
  repo=os.getenv('GITHUB_REPOSITORY','');token=os.getenv('GH_TOKEN','')
  if not token or not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',repo):return
  req=request.Request('https://api.github.com/repos/'+repo+'/actions/workflows/biblioteca.yml/runs?event=workflow_dispatch&per_page=100',headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json'})
  with request.urlopen(req,timeout=30) as response:runs=json.load(response).get('workflow_runs',[])
  found=next((run for run in runs if run.get('display_title','').endswith(command['id'])),None)
  query='id=eq.'+parse.quote(command['id'],safe='')
  if found and found.get('status')=='completed':
   ok=found.get('conclusion')=='success';info={'target':target,'progress':100 if ok else 10,'phase':'Workflow concluído no GitHub Actions' if ok else 'Falha no workflow. Abra os detalhes no GitHub Actions.','url':found['html_url']}
   client.call('pge_commands',query,'PATCH',dict(status='applied' if ok else 'failed',result=json.dumps(info,ensure_ascii=False)))
  elif not found and (dt.datetime.now(dt.timezone.utc)-instant(command['created_at'])).total_seconds()>3600:
   client.call('pge_commands',query,'PATCH',dict(status='failed',result=json.dumps({'target':target,'progress':0,'phase':'Não houve confirmação de início. Confira o Actions antes de solicitar novamente.'},ensure_ascii=False)))
  return
 query='id=eq.'+parse.quote(command['id'],safe='')
 info={'progress':5,'phase':'Preparando atualização','target':target}
 client.call('pge_commands',query,'PATCH',dict(status='processing',result=json.dumps(info,ensure_ascii=False)))
 if target=='panel-sync':
  export(client)
  info.update(progress=100,phase='Dados do painel sincronizados')
  client.call('pge_commands',query,'PATCH',dict(status='applied',result=json.dumps(info,ensure_ascii=False)))
 else:
  info.update(progress=10,phase='Aguardando início no GitHub Actions')
  client.call('pge_commands',query,'PATCH',dict(result=json.dumps(info,ensure_ascii=False)))
  try:dispatch_library(command,'buscar-agora' if target=='video-discovery' else 'publicar-site')
  except error.HTTPError as ex:
   if ex.code in [400,401,403,404,422]:raise ValueError('invalid_github_dispatch_permissions') from None
   raise

def process(client):
 # Replay after uncertain commit: command UUID is embedded in the commit subject.
 git('fetch','--no-tags','origin','main');git('merge','--ff-only','FETCH_HEAD')
 pending=client.call('pge_commands','status=in.(pending,processing)&order=created_at.asc&limit=20')
 admins={x['user_id'] for x in client.call('pge_admins','select=user_id')}
 videos={x['id']:x for x in current_reviews()}
 applied=0;failed=0
 for command in pending:
  id=command['id'];query='id=eq.'+parse.quote(id,safe='')
  try:
   if command['user_id'] not in admins:raise ValueError('administrator_revoked')
   if command['action']=='run_sync':
    sync_command(client,command);continue
   history=git('log','origin/main','--format=%s','-100')
   if 'pge-admin:'+id in history:
    client.call('pge_commands',query,'PATCH',dict(status='applied',payload=brief_payload(command),result='Alteração já gravada no GitHub.'));applied+=1;continue
   client.call('pge_commands',query,'PATCH',dict(status='processing',result=None,updated_at=dt.datetime.now(dt.timezone.utc).isoformat()))
   path,text=apply_command(command,videos);validate_change(path,text)
   file=ROOT/path;old=file.read_text();file.write_text(text)
   try:
    if text!=old:
     git('add','--',path)
     git('-c','user.name=Painel da plataforma','-c','user.email=painel@users.noreply.github.com','commit','-m','pge-admin:'+id)
     git('push','origin','HEAD:main') # no force: concurrent source edits are never overwritten
    client.call('pge_commands',query,'PATCH',dict(status='applied',payload=brief_payload(command),result='Gravado no GitHub; aguardando publicação.',updated_at=dt.datetime.now(dt.timezone.utc).isoformat()));applied+=1
   except Exception:
    # Unknown push outcome is retried using commit UUID, not reported as applied.
    raise RuntimeError('commit_or_push_failed') from None
  except ValueError as ex:
   reason=str(ex) if str(ex).startswith(('conflict_','invalid_','path_','action_','confirm_','select_','site_','administrator_')) else 'validation_failed'
   client.call('pge_commands',query,'PATCH',dict(status='conflict' if reason.startswith('conflict_') else 'failed',payload=brief_payload(command),result=reason));failed+=1
  except Exception:
   # Leave processing for replay; never put transport messages/tokens in logs.
   raise RuntimeError('admin_processing_retry_required') from None
 return dict(applied=applied,failed=failed)

def main():
 p=argparse.ArgumentParser();p.add_argument('--export-only',action='store_true');p.add_argument('--state');args=p.parse_args();client=Client()
 if not client.url or not client.key:print('Painel não configurado: sincronização ignorada.');return 0
 try:
  result=export(client,json.loads(Path(args.state).read_text()) if args.state else None) if args.export_only else process(client)
  print(json.dumps(result,ensure_ascii=False))
  output=os.getenv('GITHUB_OUTPUT')
  if output:
   with open(output,'a') as f:f.write('applied='+str(result.get('applied',0))+'\n')
  return 0
 except Exception as ex:print('Falha na sincronização administrativa: '+type(ex).__name__);return 1
if __name__=='__main__':sys.exit(main())
