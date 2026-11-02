"""Ponte Supabase → GitHub. Sem dependências externas, sem credenciais públicas."""
import argparse, copy, datetime as dt, hashlib, json, os, re, subprocess, sys
from pathlib import Path
from urllib import request,parse
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
   content=file.read_text();json.loads(content)
   docs.append(dict(path=path,content=content,sha=sha(content),updated_at=dt.datetime.now(dt.timezone.utc).isoformat()))
 if docs:client.call('pge_documents','on_conflict=path','POST',docs)
 return dict(videos=len(rows),documents=len(docs))

def apply_command(command,records):
 payload=command['payload']
 if command['action']=='review_video':
  id=payload.get('id','')
  if not VIDEO.fullmatch(id):raise ValueError('invalid_video_id')
  current=records.get(id)
  if not current or payload.get('expected_sha')!=current['sha']:raise ValueError('conflict_video_changed')
  decision=payload.get('decision')
  if decision not in ['approved','rejected','archived','pending_review']:raise ValueError('invalid_decision')
  file=ROOT/'biblioteca-controle/editorial.json';data=json.loads(file.read_text());entry=data.setdefault(id,{})
  if decision=='approved':
   if payload.get('portuguese_confirmed') is not True:raise ValueError('confirm_portuguese_first')
   if payload.get('categoria') not in ['desenho','filme','serie']:raise ValueError('select_category')
   entry.update(revisado=True,aprovacao=decision,reabrir=True,categoria=payload['categoria'],idioma='pt-BR',idiomaVerificado=True)
  else:entry.update(aprovacao=decision,revisado=True,reabrir=decision=='pending_review')
  return 'biblioteca-controle/editorial.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n'
 if command['action']=='save_json':
  path=payload.get('path')
  if path not in ALLOWED:raise ValueError('path_not_allowed')
  file=ROOT/path;current=file.read_text()
  if payload.get('expected_sha')!=sha(current):raise ValueError('conflict_document_changed')
  text=payload.get('content')
  if not isinstance(text,str) or len(text.encode())>1048576:raise ValueError('invalid_content_size')
  json.loads(text)
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
 return {k:v for k,v in command.get('payload',{}).items() if k in ['id','path','decision','expected_sha']}

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
