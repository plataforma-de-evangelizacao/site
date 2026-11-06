#!/usr/bin/env python3
"""PGE recovery kit. Python 3.10+, local credentials, encrypted per-file snapshots.
No production action is performed by importing this module or by `verify`.
"""
from __future__ import annotations
import argparse,base64,mimetypes,datetime as dt,getpass,hashlib,json,os,pathlib,re,shutil,subprocess,sys,tempfile,time,urllib.request,urllib.error,urllib.parse,uuid
P=pathlib.Path
VERSION='2026.11.04.1'
class Failure(Exception):pass
class Log:
 def __init__(self):self.rows=[]
 def emit(self,step,status,detail=''):
  row=dict(at=dt.datetime.now(dt.timezone.utc).isoformat(),step=step,status=status,detail=detail)
  self.rows.append(row);print(f'[{status.upper()}] {step}'+(' — '+detail if detail else ''),flush=True)
 def save(self,path):P(path).write_text(json.dumps({'version':VERSION,'events':self.rows},indent=2,ensure_ascii=False)+'\n')
LOG=Log()
def run(args,env=None,input=None):
 try:r=subprocess.run(args,env=env,input=input,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=False)
 except FileNotFoundError:raise Failure('Dependência ausente: '+args[0])
 if r.returncode:raise Failure('Falha em '+args[0]+' (código '+str(r.returncode)+'). Confira a versão instalada, conexão e permissões. A saída bruta foi omitida para proteger credenciais.')
 return r.stdout
def dependencies():
 try:from cryptography.fernet import Fernet
 except ImportError:raise Failure('Instale as dependências com install-deps; depois use o Python do ambiente virtual criado.')
 return Fernet
def derive(password,salt):
 if len(password)<16:raise Failure('Use uma frase de recuperação com pelo menos 16 caracteres.')
 return base64.urlsafe_b64encode(hashlib.pbkdf2_hmac('sha256',password.encode(),salt,600000,32))
def master():return os.environ.get('PGE_BACKUP_PASSPHRASE') or getpass.getpass('Frase de recuperação (não aparece na tela): ')
def private_write(path,data):
 path=P(path);path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
 if os.name!='nt':path.chmod(0o600)
def seal_credentials(path,cfg,password):
 salt=os.urandom(16);private_write(path,b'PGE1'+salt+dependencies()(derive(password,salt)).encrypt(json.dumps(cfg).encode()))
def load_credentials(path,password):
 try:
  raw=P(path).read_bytes();assert raw[:4]==b'PGE1';return json.loads(dependencies()(derive(password,raw[4:20])).decrypt(raw[20:]))
 except Exception:raise Failure('Não foi possível abrir a configuração. Confira arquivo e frase de recuperação.')
def http(url,token=None,method='GET',body=None,headers=None,raw=False):
 h={'User-Agent':'PGE-Recovery/'+VERSION,**(headers or {})}
 if token:h['Authorization']='Bearer '+token
 if body is not None and not isinstance(body,bytes):body=json.dumps(body).encode();h.setdefault('Content-Type','application/json')
 req=urllib.request.Request(url,data=body,headers=h,method=method)
 for attempt in range(3):
  try:
   with urllib.request.urlopen(req,timeout=60) as r:data=r.read();return data if raw else json.loads(data) if data else {}
  except urllib.error.HTTPError as e:
   if e.code in [429,502,503,504] and attempt<2:time.sleep(2**attempt);continue
   raise Failure(f'HTTP {e.code} em {urllib.parse.urlsplit(url).hostname}. Verifique autorização e permissões; resposta não exposta.')
  except (urllib.error.URLError,TimeoutError):
   if attempt<2:time.sleep(2**attempt);continue
   raise Failure('Conexão indisponível: '+str(urllib.parse.urlsplit(url).hostname))
class GitHub:
 def __init__(self,c):self.c=c;self.token=c['github_token']
 def api(self,path,method='GET',body=None):return http('https://api.github.com/'+path,self.token,method,body,{'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'})
 def repo(self,name):
  if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',name):raise Failure('Use owner/repositorio válido.')
  return self.api('repos/'+name)
 def ensure(self,name,private=True):
  try:r=self.repo(name)
  except Failure as e:
   if 'HTTP 404' not in str(e):raise
   owner,repo=name.split('/');me=self.api('user')['login'];endpoint='user/repos' if owner.lower()==me.lower() else 'orgs/'+owner+'/repos'
   r=self.api(endpoint,'POST',dict(name=repo,private=private,auto_init=True,description='Cópias criptografadas de recuperação da PGE' if private else 'Restauração de teste da PGE'))
  if private and not r.get('private'):raise Failure('Backup recusado: repositório de destino precisa ser privado.')
  return r
 def clone(self,name,dest):
  # ASKPASS passes the credential only in the child environment; no token in URL/config/argv.
  with tempfile.TemporaryDirectory(prefix='pge-auth-') as authdir:
   helper=P(authdir)/'askpass.py';helper.write_text('#!'+sys.executable+'\nimport os,sys\nprint("x-access-token" if "username" in sys.argv[-1].lower() else os.environ["PGE_GIT_CREDENTIAL"])\n')
   if os.name!='nt':helper.chmod(0o700)
   if os.name=='nt':
    wrapper=P(authdir)/'askpass.cmd';wrapper.write_text('@"'+sys.executable+'" "'+str(helper)+'" %*\n');askpass=str(wrapper)
   else:askpass=str(helper)
   env={**os.environ,'GIT_ASKPASS':askpass,'GIT_TERMINAL_PROMPT':'0','PGE_GIT_CREDENTIAL':self.token}
   run(['git','clone','--mirror','https://github.com/'+name+'.git',str(dest)],env)
 def push_folder(self,name,folder,message):
  self.ensure(name,True)
  tree=[]
  for p in sorted(P(folder).rglob('*')):
   if not p.is_file():continue
   if p.stat().st_size>90*1024*1024:raise Failure('Arquivo maior que o limite de backup por objeto; use fragmentação.')
   blob=self.api('repos/'+name+'/git/blobs','POST',{'content':base64.b64encode(p.read_bytes()).decode(),'encoding':'base64'})
   tree.append({'path':P(folder).name+'/'+p.relative_to(folder).as_posix(),'mode':'100644','type':'blob','sha':blob['sha']})
  parent=None
  try:ref=self.api('repos/'+name+'/git/ref/heads/main');parent=ref['object']['sha']
  except Failure as e:
   if not any(x in str(e) for x in ['HTTP 404','HTTP 409']):raise
  base=None
  if parent:base=self.api('repos/'+name+'/git/commits/'+parent)['tree']['sha']
  body={'tree':tree};
  if base:body['base_tree']=base
  root=self.api('repos/'+name+'/git/trees','POST',body)
  commit=self.api('repos/'+name+'/git/commits','POST',{'message':message,'tree':root['sha'],'parents':[parent] if parent else []})
  if parent:self.api('repos/'+name+'/git/refs/heads/main','PATCH',{'sha':commit['sha'],'force':False})
  else:self.api('repos/'+name+'/git/refs','POST',{'ref':'refs/heads/main','sha':commit['sha']})
  self.api('repos/'+name,'PATCH',{'default_branch':'main'})
  return commit['sha']
 def secret(self,repo,name,value):
  if name.startswith('GITHUB_'):raise Failure('Nome de Secret reservado pelo GitHub.')
  try:from nacl.public import PublicKey,SealedBox
  except ImportError:raise Failure('PyNaCl é necessário para restaurar Secrets.')
  pub=self.api('repos/'+repo+'/actions/secrets/public-key');sealed=SealedBox(PublicKey(base64.b64decode(pub['key']))).encrypt(value.encode())
  self.api('repos/'+repo+'/actions/secrets/'+name,'PUT',{'encrypted_value':base64.b64encode(sealed).decode(),'key_id':pub['key_id']})
class Drive:
 def __init__(self,c):
  self.c=c;params=urllib.parse.urlencode({'client_id':c['google_client_id'],'client_secret':c['google_client_secret'],'refresh_token':c['google_refresh_token'],'grant_type':'refresh_token'}).encode()
  r=http('https://oauth2.googleapis.com/token',method='POST',body=params,headers={'Content-Type':'application/x-www-form-urlencoded'});self.token=r['access_token']
 def api(self,path,method='GET',body=None):return http('https://www.googleapis.com/drive/v3/'+path,self.token,method,body)
 def private_folder(self):
  folder=self.c['drive_folder_id'];r=self.api('files/'+folder+'?fields=id,mimeType,capabilities(canAddChildren)');
  if r.get('mimeType')!='application/vnd.google-apps.folder' or not r.get('capabilities',{}).get('canAddChildren'):raise Failure('Pasta Drive não permite gravar arquivos.')
  permissions=self.api('files/'+folder+'/permissions?fields=permissions(type,role)')
  if any(x['type'] in ('anyone','domain') for x in permissions.get('permissions',[])):raise Failure('Pasta de backup precisa ter acesso restrito, sem compartilhamento público ou por domínio.')
  return folder
 def folder(self,name,parent):return self.api('files?fields=id','POST',{'name':name,'parents':[parent],'mimeType':'application/vnd.google-apps.folder'})['id']
 def upload(self,root):
  parent=self.private_folder();top=self.folder(P(root).name,parent);dirs={'.':top}
  for p in sorted(P(root).rglob('*')):
   rel=p.relative_to(root);parent_key=rel.parent.as_posix()
   if p.is_dir():dirs[rel.as_posix()]=self.folder(p.name,dirs[parent_key]);continue
   boundary='pge'+uuid.uuid4().hex;metadata=json.dumps({'name':p.name,'parents':[dirs[parent_key]]}).encode();data=b'--'+boundary.encode()+b'\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'+metadata+b'\r\n--'+boundary.encode()+b'\r\nContent-Type: application/octet-stream\r\n\r\n'+p.read_bytes()+b'\r\n--'+boundary.encode()+b'--\r\n'
   http('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id',self.token,'POST',data,{'Content-Type':'multipart/related; boundary='+boundary})
  return top
 def download(self,folder,dest):
  dest=P(dest);dest.mkdir(parents=True,exist_ok=True);page=''
  while True:
   query=urllib.parse.urlencode({'q':"'"+folder+"' in parents and trashed=false",'fields':'files(id,name,mimeType),nextPageToken','pageSize':1000,**({'pageToken':page} if page else {})});r=self.api('files?'+query)
   for f in r.get('files',[]):
    if f['name'] in ('.','..') or '/' in f['name'] or '\\' in f['name']:raise Failure('Nome de arquivo inválido no backup remoto.')
    p=dest/f['name']
    if f['mimeType']=='application/vnd.google-apps.folder':self.download(f['id'],p)
    else:private_write(p,http('https://www.googleapis.com/drive/v3/files/'+f['id']+'?alt=media',self.token,raw=True))
   page=r.get('nextPageToken')
   if not page:break
class Database:
 def __init__(self,url):
  u=urllib.parse.urlsplit(url)
  if u.scheme not in ('postgres','postgresql') or not u.hostname:raise Failure('PGE_DATABASE_URL inválida.')
  self.env={**os.environ,'PGHOST':u.hostname,'PGPORT':str(u.port or 5432),'PGUSER':urllib.parse.unquote(u.username or ''),'PGPASSWORD':urllib.parse.unquote(u.password or ''),'PGDATABASE':u.path.lstrip('/') or 'postgres','PGSSLMODE':'require','PGCONNECT_TIMEOUT':'20'}
 def doctor(self):run(['psql','-X','-v','ON_ERROR_STOP=1','-Atc','select 1'],self.env);LOG.emit('Comunicação com banco','ok')
 def dump(self,dest):
  self.doctor()
  for name,args in [('public.dump',['--schema=public']),('auth.dump',['--data-only','--table=auth.users','--table=auth.identities']),('storage.dump',['--data-only','--table=storage.buckets'])]:
   path=P(dest)/name;run(['pg_dump','--format=custom','--no-owner','--file',str(path),*args],self.env);run(['pg_restore','--list',str(path)]);LOG.emit('Backup do banco: '+name,'ok')
 def restore(self,folder):
  self.doctor()
  # Restore into an explicitly selected, disposable/empty target. Never a guessed database.
  tables=run(['psql','-X','-v','ON_ERROR_STOP=1','-Atc',"select count(*) from pg_tables where schemaname='public'"],self.env).decode().strip()
  if tables!='0':raise Failure('Restauração recusada: use um projeto Supabase novo, com schema public vazio.')
  for name,args in [('auth.dump',['--data-only']),('public.dump',[]),('storage.dump',['--data-only'])]:
   run(['pg_restore','--exit-on-error','--no-owner','--dbname',self.env['PGDATABASE'],*args,str(P(folder)/name)],self.env);LOG.emit('Restauração: '+name,'ok')
  run(['psql','-X','-v','ON_ERROR_STOP=1','-Atc',"select count(*) from public.pge_documents"],self.env);LOG.emit('Consulta de conteúdo restaurado','ok')
def storage_export(c,dest):
 base=c['supabase_url'];key=c['supabase_service_role_key'];h={'apikey':key,'Authorization':'Bearer '+key};buckets=http(base+'/storage/v1/bucket',headers=h)
 def walk(bucket,prefix=''):
  offset=0
  while True:
   rows=http(base+'/storage/v1/object/list/'+urllib.parse.quote(bucket,safe=''),method='POST',headers=h,body={'prefix':prefix,'limit':100,'offset':offset,'sortBy':{'column':'name','order':'asc'}})
   for obj in rows:
    name=prefix+'/'+obj['name'] if prefix else obj['name']
    if '..' in P(name).parts:raise Failure('Caminho de Storage inválido.')
    if obj.get('id') is None:walk(bucket,name)
    else:private_write(P(dest)/bucket/name,http(base+'/storage/v1/object/'+urllib.parse.quote(bucket+'/'+name,safe='/'),headers=h,raw=True))
   if len(rows)<100:break
   offset+=len(rows)
 for bucket in buckets:walk(bucket['id'])
 LOG.emit('Objetos do Storage','ok',str(len(buckets))+' buckets verificados')
def storage_restore(c,root):
 h={'apikey':c['supabase_service_role_key'],'Authorization':'Bearer '+c['supabase_service_role_key'],'x-upsert':'true','Content-Type':'application/octet-stream'}
 for p in P(root).rglob('*'):
  if p.is_file():http(c['supabase_url']+'/storage/v1/object/'+urllib.parse.quote(p.relative_to(root).as_posix(),safe='/'),method='POST',headers={**h,'Content-Type':mimetypes.guess_type(p.name)[0] or 'application/octet-stream'},body=p.read_bytes())
 LOG.emit('Arquivos do Storage restaurados','ok')
def encrypt_tree(source,dest,password):
 dest=P(dest);dest.mkdir(parents=True,exist_ok=False);salt=os.urandom(16);f=dependencies()(derive(password,salt));manifest={'version':1,'created_at':dt.datetime.now(dt.timezone.utc).isoformat(),'salt':base64.b64encode(salt).decode(),'files':[]}
 for p in sorted(P(source).rglob('*')):
  if not p.is_file():continue
  rel=p.relative_to(source).as_posix();parts=[];digest=hashlib.sha256()
  with p.open('rb') as stream:
   i=0
   while True:
    data=stream.read(16*1024*1024)
    if not data and i:break
    digest.update(data);name=rel+'.part'+str(i)+'.enc';private_write(dest/name,f.encrypt(data));parts.append(name);i+=1
    if not data:break
  manifest['files'].append({'path':rel,'size':p.stat().st_size,'sha256':digest.hexdigest(),'parts':parts})
 raw=json.dumps(manifest,ensure_ascii=False,indent=2).encode();private_write(dest/'manifest.enc',f.encrypt(raw));private_write(dest/'snapshot.json',json.dumps({'format':'pge-encrypted-folder-v1','salt':manifest['salt'],'files':len(manifest['files'])}).encode());return manifest
def decrypt_tree(source,dest,password):
 source=P(source);dest=P(dest);meta=json.loads((source/'snapshot.json').read_text());f=dependencies()(derive(password,base64.b64decode(meta['salt'])));
 try:manifest=json.loads(f.decrypt((source/'manifest.enc').read_bytes()))
 except Exception:raise Failure('Frase incorreta ou manifesto corrompido.')
 for row in manifest['files']:
  rel=P(row['path'])
  if rel.is_absolute() or '..' in rel.parts:raise Failure('Caminho de restauração inválido.')
  out=dest/rel;out.parent.mkdir(parents=True,exist_ok=True);digest=hashlib.sha256()
  with out.open('wb') as stream:
   for part in row['parts']:
    if P(part).is_absolute() or '..' in P(part).parts:raise Failure('Fragmento inválido.')
    try:data=f.decrypt((source/part).read_bytes())
    except Exception:raise Failure('Backup corrompido: '+row['path'])
    digest.update(data);stream.write(data)
  if digest.hexdigest()!=row['sha256'] or out.stat().st_size!=row['size']:raise Failure('Checksum divergente: '+row['path'])
  if os.name!='nt':out.chmod(0o600)
 return manifest
def doctor(c,drive=True):
 for tool in ['git','pg_dump','pg_restore','psql']:
  if not shutil.which(tool):raise Failure('Dependência ausente: '+tool+'. Execute install-deps.')
  LOG.emit('Dependência '+tool,'ok')
 gh=GitHub(c);gh.repo(c['site_repo']);gh.ensure(c['backup_repo'],True);LOG.emit('GitHub e repositório privado','ok');Database(c['database_url']).doctor()
 if drive:Drive(c).private_folder();LOG.emit('API do Drive e pasta privada','ok')
 if c.get('site_url'):
  try:http(c['site_url'],raw=True);LOG.emit('Página pública HTTPS','ok')
  except Failure:LOG.emit('Página pública HTTPS','warning','Site indisponível; o backup do código e banco continuará.')
def managed_backup(c,plain,gh):
 repo=c['site_repo'];settings={}
 for key,path in [('repository',''),('variables','/actions/variables'),('secret_names','/actions/secrets'),('pages','/pages')]:
  try:settings[key]=gh.api('repos/'+repo+path)
  except Failure:LOG.emit('Configuração GitHub '+key,'warning','Não exportada; confira as permissões do token.')
 names=[x['name'] for x in settings.get('secret_names',{}).get('secrets',[])]
 missing=[n for n in names if not (c.get('github_secrets',{}).get(n) or n in ['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY'])]
 settings['secrets_not_captured']=missing
 private_write(P(plain)/'github-settings.json',json.dumps(settings).encode())
 if missing:LOG.emit('Secrets não recuperáveis pela API','warning',', '.join(missing)+'. Cadastre os valores no cofre local para permitir restauração.')
 token=c.get('github_secrets',{}).get('SUPABASE_ACCESS_TOKEN')
 if token:
  ref=urllib.parse.urlsplit(c['supabase_url']).hostname.split('.')[0]
  try:
   cfg=http('https://api.supabase.com/v1/projects/'+ref+'/config/auth',token)
   private_write(P(plain)/'auth-config.json',json.dumps(cfg).encode());LOG.emit('Configuração do Auth','ok')
  except Failure:LOG.emit('Configuração do Auth','warning','Token sem acesso à configuração; será necessário configurar redirecionamentos e SMTP no projeto restaurado.')
 else:LOG.emit('Configuração do Auth','not_backed_up','SUPABASE_ACCESS_TOKEN não cadastrado no cofre.')
 # PGE-specific storage policies are outside public schema and must be retained explicitly.
 db=Database(c['database_url'])
 query="select coalesce(json_agg(row_to_json(p)),'[]'::json) from pg_policies p where schemaname='storage' and policyname like 'pge_%'"
 raw=run(['psql','-X','-v','ON_ERROR_STOP=1','-Atc',query],db.env)
 private_write(P(plain)/'storage-policies.json',raw)
def managed_restore(c,target,root,repo,url,gh,db_url):
 token=c.get('github_secrets',{}).get('SUPABASE_ACCESS_TOKEN')
 dispatch=c.get('github_secrets',{}).get('PLATFORM_DISPATCH_TOKEN')
 if not token or not dispatch:raise Failure('Recuperação do backend requer SUPABASE_ACCESS_TOKEN e PLATFORM_DISPATCH_TOKEN no cofre local, válidos para o destino de teste.')
 ref=urllib.parse.urlsplit(target['supabase_url']).hostname.split('.')[0];base='https://api.supabase.com/v1/projects/'+ref+'/'
 # Reuse PGE storage policies after the public helper functions are restored.
 policy_file=root/'storage-policies.json'
 if policy_file.exists():
  def qi(x):return '"'+x.replace('"','""')+'"'
  for p in json.loads(policy_file.read_text()):
   roles=','.join(qi(x) for x in p['roles']);sql='drop policy if exists '+qi(p['policyname'])+' on storage.'+qi(p['tablename'])+'; create policy '+qi(p['policyname'])+' on storage.'+qi(p['tablename'])+' as '+p['permissive']+' for '+p['cmd']+' to '+roles
   if p.get('qual'):sql+=' using ('+p['qual']+')'
   if p.get('with_check'):sql+=' with check ('+p['with_check']+')'
   run(['psql','-X','-v','ON_ERROR_STOP=1','-c',sql],Database(db_url).env)
 auth={}
 if (root/'auth-config.json').exists():
  saved=json.loads((root/'auth-config.json').read_text())
  for key in ['disable_signup','mailer_autoconfirm','external_email_enabled','enable_refresh_token_rotation','security_refresh_token_reuse_interval','smtp_admin_email','smtp_host','smtp_port','smtp_user','smtp_pass','smtp_sender_name']:
   if saved.get(key) is not None:auth[key]=saved[key]
 auth.update(site_url=url,uri_allow_list=url+'admin/')
 http(base+'config/auth',token,'PATCH',auth);LOG.emit('URLs e configuração do Auth','ok')
 http(base+'secrets',token,'POST',[{'name':'GITHUB_DISPATCH_TOKEN','value':dispatch},{'name':'ADMIN_ALLOWED_ORIGIN','value':'https://'+repo.split('/')[0]+'.github.io'}])
 source=(root/'site/supabase/functions/admin-dispatch/index.ts').read_bytes();boundary='pge'+uuid.uuid4().hex
 meta=json.dumps({'entrypoint_path':'index.ts','name':'admin-dispatch','verify_jwt':False}).encode()
 body=b'--'+boundary.encode()+b'\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n'+meta+b'\r\n--'+boundary.encode()+b'\r\nContent-Disposition: form-data; name="file"; filename="index.ts"\r\nContent-Type: application/typescript\r\n\r\n'+source+b'\r\n--'+boundary.encode()+b'--\r\n'
 http(base+'functions/deploy?slug=admin-dispatch',token,'POST',body,{'Content-Type':'multipart/form-data; boundary='+boundary});LOG.emit('Função e segredos da integração','ok')
 if (root/'github-settings.json').exists():
  cfg=json.loads((root/'github-settings.json').read_text())
  for var in cfg.get('variables',{}).get('variables',[]):
   gh.api('repos/'+repo+'/actions/variables','POST',{'name':var['name'],'value':var['value']})

def backup(c,out,password,no_drive=False):
 doctor(c,not no_drive)
 stamp=dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ');snapshot=P(out)/('pge-'+stamp)
 with tempfile.TemporaryDirectory(prefix='pge-backup-') as tmp:
  root=P(tmp);plain=root/'plain';plain.mkdir();mirror=root/'repo.git';gh=GitHub(c);gh.clone(c['site_repo'],mirror)
  run(['git','-C',str(mirror),'bundle','create',str(plain/'repository.bundle'),'--all']);LOG.emit('Histórico Git e branches','ok')
  names=run(['git','-C',str(mirror),'ls-tree','-r','--name-only','HEAD']).decode().splitlines()
  for name in names:
   if '..' in P(name).parts or P(name).is_absolute():raise Failure('Caminho Git inválido.')
   private_write(plain/'site'/name,run(['git','-C',str(mirror),'show','HEAD:'+name]))
  db=plain/'database';db.mkdir();Database(c['database_url']).dump(db);storage_export(c,plain/'storage')
  managed_backup(c,plain,gh)
  private_write(plain/'credentials.json',json.dumps(c).encode());LOG.emit('Credenciais locais incluídas','ok','Valores protegidos; Secrets do GitHub não podem ser exportados pela API.')
  private_write(plain/'metadata.json',json.dumps({'version':VERSION,'repo':c['site_repo'],'files':len(names),'created_at':stamp}).encode())
  encrypt_tree(plain,snapshot,password)
  with tempfile.TemporaryDirectory(prefix='pge-verify-') as verify:manifest=decrypt_tree(snapshot,verify,password);run(['pg_restore','--list',str(P(verify)/'database/public.dump')])
  LOG.emit('Integridade e leitura do dump','ok',str(len(manifest['files']))+' arquivos')
 failures=[]
 try:gh.push_folder(c['backup_repo'],snapshot,'Backup criptografado '+stamp);LOG.emit('Cópia no GitHub privado','ok')
 except Failure as e:failures.append('github');LOG.emit('Cópia no GitHub','failed',str(e))
 if not no_drive:
  try:folder=Drive(c).upload(snapshot);LOG.emit('Cópia no Drive','ok','Pasta '+folder)
  except Failure as e:failures.append('drive');LOG.emit('Cópia no Drive','failed',str(e))
 LOG.save(snapshot/'relatorio-local.json')
 if failures:raise Failure('Backup local íntegro; destinos com falha: '+', '.join(failures)+'. Cópia local: '+str(snapshot))
 LOG.emit('Backup completo','ok',str(snapshot));return snapshot
def db_identity(url):
 u=urllib.parse.urlsplit(url)
 return ((u.hostname or '').lower(),u.port or 5432,urllib.parse.unquote(u.username or ''),u.path or '/postgres')
def schedule(config,output,hour,password):
 if not sys.platform.startswith('linux') or not shutil.which('systemctl'):raise Failure('Agendamento automático disponível com systemd no Linux. Em outros sistemas, use seu agendador com o comando backup.')
 if not 0<=hour<=23:raise Failure('Hora deve estar entre 0 e 23.')
 key=P.home()/'.config/pge-recovery/schedule.env'
 # This machine-local key is required for unattended decryption; never upload it to source/Drive.
 if '\n' in password or '\r' in password:raise Failure('Frase de agendamento não pode conter quebra de linha.')
 escaped=password.replace('\\','\\\\').replace('"','\\"')
 private_write(key,('PGE_BACKUP_PASSPHRASE="'+escaped+'"\n').encode())
 folder=P.home()/'.config/systemd/user';folder.mkdir(parents=True,exist_ok=True)
 def unitquote(x):return '"'+str(x).replace('\\','\\\\').replace('"','\\"').replace('%','%%')+'"'
 service='[Unit]\nDescription=Backup privado PGE\n[Service]\nType=oneshot\nUMask=0077\nEnvironmentFile='+unitquote(key)+'\nExecStart='+ ' '.join(unitquote(x) for x in [sys.executable,P(__file__).resolve(),'--config',P(config).resolve(),'backup','--output',P(output).resolve()])+'\n'
 private_write(folder/'pge-backup.service',service.encode());private_write(folder/'pge-backup.timer',('[Unit]\nDescription=Backup diario PGE\n[Timer]\nOnCalendar=*-*-* '+str(hour).zfill(2)+':00:00\nPersistent=true\n[Install]\nWantedBy=timers.target\n').encode())
 run(['systemctl','--user','daemon-reload']);run(['systemctl','--user','enable','--now','pge-backup.timer']);LOG.emit('Agendamento diário','ok','Hora local '+str(hour)+':00. Computador precisa estar ligado; confira journalctl --user -u pge-backup.service.')

def restore(c,snapshot,password,target_repo,target_db,execute=False,target_supabase=None):
 if target_repo.lower()==c['site_repo'].lower():raise Failure('Use um repositório de recuperação separado. O original é protegido.')
 if db_identity(target_db)==db_identity(c['database_url']):raise Failure('Use um banco de recuperação separado. O original é protegido.')
 with tempfile.TemporaryDirectory(prefix='pge-restore-') as tmp:
  manifest=decrypt_tree(snapshot,tmp,password);LOG.emit('Integridade dos arquivos','ok',str(len(manifest['files'])))
  root=P(tmp);run(['pg_restore','--list',str(root/'database/public.dump')]);LOG.emit('Dump legível','ok')
  if not execute:LOG.emit('Plano de restauração','ok','Nenhum serviço alterado. Use --execute e informe os destinos de teste.');return
  if not target_supabase:raise Failure('Informe --target-supabase-config com as novas chaves e a URL do projeto de teste, em arquivo local privado.')
  target={**c,**json.loads(P(target_supabase).read_text())}
  if target['supabase_url']==c['supabase_url']:raise Failure('O Supabase de produção é protegido contra restauração por este comando.')
  if not target_db:raise Failure('Informe a conexão do banco de teste pela variável solicitada.')
  if not target.get('supabase_url','').startswith('https://'):raise Failure('URL Supabase de teste inválida.')
  gh=GitHub(c)
  try:
   existing=gh.repo(target_repo)
   if existing.get('size',0)>0:raise Failure('O repositório de recuperação precisa ser novo ou vazio.')
  except Failure as e:
   if 'HTTP 404' not in str(e):raise
  ref=urllib.parse.urlsplit(target['supabase_url']).hostname.split('.')[0];dbu=urllib.parse.urlsplit(target_db)
  if not (dbu.hostname=='db.'+ref+'.supabase.co' or urllib.parse.unquote(dbu.username or '').endswith('.'+ref)):raise Failure('A conexão PostgreSQL não corresponde ao projeto Supabase de teste informado.')
  mgmt=c.get('github_secrets',{}).get('SUPABASE_ACCESS_TOKEN')
  if not mgmt or not c.get('github_secrets',{}).get('PLATFORM_DISPATCH_TOKEN'):raise Failure('Cadastre os tokens de gestão e disparo no cofre antes de restaurar.')
  http('https://api.supabase.com/v1/projects/'+ref+'/config/auth',mgmt)
  Database(target_db).restore(root/'database');storage_restore(target,root/'storage')
  oldbase=c['supabase_url'].replace("'","''");newbase=target['supabase_url'].replace("'","''")
  for table in ['pge_documents','pge_live_documents']:
   run(['psql','-X','-v','ON_ERROR_STOP=1','-c',"update public."+table+" set content=replace(content,'"+oldbase+"','"+newbase+"') where content like '%"+oldbase+"%'"],Database(target_db).env)
  # Public site only: credentials.json/database/storage snapshots NEVER enter the site repository.
  repo=gh.ensure(target_repo,False)
  # Write source files through the Git data API, allowing public site destination only here.
  tree=[]
  old_repo=c['site_repo'];new_owner,new_name=target_repo.split('/')
  new_url='https://'+new_owner+'.github.io/'+new_name+'/'
  # Prepare test repository references; snapshots/credentials remain outside public source.
  for file in (root/'site').rglob('*'):
   if not file.is_file():continue
   rel=file.relative_to(root/'site').as_posix()
   if file.name.startswith('.env') or file.name in ('credentials.json','credentials.enc','schedule.env','google.enc') or file.suffix in ('.pem','.key','.dump','.bundle'):raise Failure('Arquivo sensível no código público: '+rel)
   if file.suffix in ('.html','.js','.ts','.md','.yml','.json','.py'):
    try:text=file.read_text()
    except UnicodeError:continue
    if re.search(r'(?:ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}|sb_secret_[A-Za-z0-9_-]{20,})',text):raise Failure('Possível credencial no código público: '+rel)
    # Never transform immutable SQL migrations or historical checksum manifests.
    text=text.replace('https://'+old_repo.split('/')[0]+'.github.io/'+old_repo.split('/')[1]+'/',new_url).replace(old_repo,target_repo)
    if file.name=='index.ts':text=text.replace('https://'+old_repo.split('/')[0]+'.github.io','https://'+new_owner+'.github.io').replace('/site/admin/','/'+new_name+'/admin/')
    file.write_text(text)
  (root/'site/CNAME').unlink(missing_ok=True)
  config=root/'site/admin/config.json';config.parent.mkdir(parents=True,exist_ok=True);config.write_text(json.dumps({'supabaseUrl':target['supabase_url'],'publishableKey':target['supabase_publishable_key']}))
  for p in sorted((root/'site').rglob('*')):
   if not p.is_file():continue
   rel=p.relative_to(root/'site').as_posix()
   if p.stat().st_size>90*1024*1024:raise Failure('Arquivo grande demais para publicar: '+rel)
   blob=gh.api('repos/'+target_repo+'/git/blobs','POST',{'content':base64.b64encode(p.read_bytes()).decode(),'encoding':'base64'});tree.append({'path':rel,'mode':'100644','type':'blob','sha':blob['sha']})
  parent=None
  try:parent=gh.api('repos/'+target_repo+'/git/ref/heads/main')['object']['sha']
  except Failure as e:
   if not any(x in str(e) for x in ['HTTP 404','HTTP 409']):raise
  tr=gh.api('repos/'+target_repo+'/git/trees','POST',{'tree':tree});commit=gh.api('repos/'+target_repo+'/git/commits','POST',{'message':'Restaurar cópia verificada da PGE','tree':tr['sha'],'parents':[parent] if parent else []})
  managed_restore(c,target,root,target_repo,new_url,gh,target_db)
  # Configure secrets BEFORE pushing the main ref that triggers workflows.
  secrets={**c.get('github_secrets',{}),'SUPABASE_URL':target['supabase_url'],'SUPABASE_SERVICE_ROLE_KEY':target['supabase_service_role_key']}
  for name,value in secrets.items():
   if value:gh.secret(target_repo,name,value);LOG.emit('Secret restaurado','ok',name)
  if parent:gh.api('repos/'+target_repo+'/git/refs/heads/main','PATCH',{'sha':commit['sha'],'force':False})
  else:gh.api('repos/'+target_repo+'/git/refs','POST',{'ref':'refs/heads/main','sha':commit['sha']})
  gh.api('repos/'+target_repo,'PATCH',{'default_branch':'main'})
  # Restore the catalogue/state branch from the Git bundle, not only HEAD.
  mirror=root/'state.git';run(['git','clone','--mirror',str(root/'repository.bundle'),str(mirror)])
  refs=run(['git','-C',str(mirror),'for-each-ref','--format=%(refname)','refs/heads/biblioteca-estado']).decode().strip()
  if refs:
   state_tree=[]
   for name in run(['git','-C',str(mirror),'ls-tree','-r','--name-only','refs/heads/biblioteca-estado']).decode().splitlines():
    raw=run(['git','-C',str(mirror),'show','refs/heads/biblioteca-estado:'+name]);blob=gh.api('repos/'+target_repo+'/git/blobs','POST',{'content':base64.b64encode(raw).decode(),'encoding':'base64'});state_tree.append({'path':name,'mode':'100644','type':'blob','sha':blob['sha']})
   tr=gh.api('repos/'+target_repo+'/git/trees','POST',{'tree':state_tree});co=gh.api('repos/'+target_repo+'/git/commits','POST',{'message':'Restaurar estado do catálogo','tree':tr['sha'],'parents':[]});gh.api('repos/'+target_repo+'/git/refs','POST',{'ref':'refs/heads/biblioteca-estado','sha':co['sha']});LOG.emit('Branch de estado do catálogo','ok')
  try:gh.api('repos/'+target_repo+'/pages','POST',{'build_type':'workflow'})
  except Failure as e:
   if 'HTTP 409' not in str(e):raise
  gh.api('repos/'+target_repo+'/actions/workflows/biblioteca.yml/dispatches','POST',{'ref':'main','inputs':{'modo':'publicar-site'}})
  url='https://'+target_repo.split('/')[0]+'.github.io/'+target_repo.split('/')[1]+'/'
  LOG.emit('Publicação solicitada','ok',url)
  deadline=time.monotonic()+900
  while time.monotonic()<deadline:
   try:
    html=http(url,raw=True).decode(errors='replace');admin=http(url+'admin/',raw=True).decode(errors='replace')
    if 'Plataforma' in html and 'login-form' in admin:LOG.emit('Página pública e formulário administrativo','ok');break
   except Failure:pass
   LOG.emit('Aguardando Pages','waiting');time.sleep(10)
  else:raise Failure('A publicação não foi confirmada em 15 minutos; ambiente preservado para diagnóstico.')
  # Public read-back is distinct from authenticated write testing.
  h={'apikey':target['supabase_publishable_key'],'Content-Type':'application/json'}
  http(target['supabase_url']+'/rest/v1/rpc/pge_public_mode',method='POST',headers=h,body={});LOG.emit('Leitura pública do banco restaurado','ok')
  if os.environ.get('PGE_TEST_EMAIL') and os.environ.get('PGE_TEST_PASSWORD'):
   login=http(target['supabase_url']+'/auth/v1/token?grant_type=password',method='POST',headers=h,body={'email':os.environ['PGE_TEST_EMAIL'],'password':os.environ['PGE_TEST_PASSWORD']})
   ah={**h,'Authorization':'Bearer '+login['access_token']};access=http(target['supabase_url']+'/rest/v1/rpc/pge_my_access',method='POST',headers=ah,body={})
   if not access.get('active'):raise Failure('Usuário restaurado sem permissão administrativa.')
   docs=http(target['supabase_url']+'/rest/v1/pge_documents?path=eq.dados/programas.json&select=path,content,sha',headers=ah)
   if not docs:raise Failure('Documento de programas não acessível ao usuário de teste.')
   # Same-content write validates authorization/conflict handling without inventing public content.
   http(target['supabase_url']+'/rest/v1/rpc/pge_publish_documents',method='POST',headers=ah,body={'p_changes':[{'path':docs[0]['path'],'content':docs[0]['content'],'expected_sha':docs[0]['sha']}]});LOG.emit('Autenticação e escrita no ambiente de teste','ok')
  else:LOG.emit('Teste autenticado','not_tested','Configure PGE_TEST_EMAIL e PGE_TEST_PASSWORD localmente, ou teste no navegador. HTTP 200 sozinho não comprova edição.')
  LOG.emit('Restauração técnica','ok','Faça o login no navegador e execute o roteiro de edição. O ambiente de teste foi mantido; nenhuma exclusão automática foi realizada.')
def authorize_drive(client_json,output,password):
 import http.server,webbrowser,secrets
 config=json.loads(P(client_json).read_text()).get('installed')
 if not config:raise Failure('Baixe um cliente OAuth do tipo Aplicativo para computador no Google Cloud.')
 verifier=secrets.token_urlsafe(64);state=secrets.token_urlsafe(32);result={}
 class Callback(http.server.BaseHTTPRequestHandler):
  def do_GET(self):
   q=urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
   if q.get('state',[''])[0]!=state or not q.get('code'):self.send_response(400);self.end_headers();self.wfile.write(b'Autorizacao nao confirmada.');return
   result['code']=q['code'][0];self.send_response(200);self.end_headers();self.wfile.write(b'Autorizacao recebida. Pode fechar esta aba e voltar ao terminal.')
  def log_message(self,*args):pass
 with http.server.HTTPServer(('127.0.0.1',0),Callback) as server:
  redirect='http://127.0.0.1:'+str(server.server_port)+'/'
  params={'client_id':config['client_id'],'redirect_uri':redirect,'response_type':'code','scope':'https://www.googleapis.com/auth/drive.file','access_type':'offline','prompt':'consent','state':state,'code_challenge_method':'S256','code_challenge':base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b'=').decode()}
  url='https://accounts.google.com/o/oauth2/v2/auth?'+urllib.parse.urlencode(params)
  LOG.emit('Autorização Google','waiting','Entre somente no navegador local. Acesso restrito aos arquivos criados/autorizados para este aplicativo.');print(url,flush=True);webbrowser.open(url)
  server.timeout=2;deadline=time.monotonic()+180
  while 'code' not in result and time.monotonic()<deadline:server.handle_request()
 if 'code' not in result:raise Failure('Autorização Google não concluída em três minutos; nenhum token salvo.')
 payload=urllib.parse.urlencode({'client_id':config['client_id'],'client_secret':config['client_secret'],'code':result['code'],'redirect_uri':redirect,'grant_type':'authorization_code','code_verifier':verifier}).encode()
 token=http('https://oauth2.googleapis.com/token',method='POST',body=payload,headers={'Content-Type':'application/x-www-form-urlencoded'})
 if not token.get('refresh_token'):raise Failure('Google não devolveu refresh token; revise consentimento e tente novamente localmente.')
 cfg={'google_client_id':config['client_id'],'google_client_secret':config['client_secret'],'google_refresh_token':token['refresh_token']};drive=Drive(cfg);cfg['drive_folder_id']=drive.api('files?fields=id','POST',{'name':'PGE Backups Privados','mimeType':'application/vnd.google-apps.folder'})['id'];seal_credentials(output,cfg,password);LOG.emit('Drive autorizado e pasta privada criada','ok','Configuração cifrada salva localmente; execute configure usando a mesma frase.')

def configure(path,password):
 def ask(label,secret=False,default=''):return (getpass.getpass(label+': ') if secret else input(label+(' ['+default+']' if default else '')+': ')).strip() or default
 c={'site_repo':ask('Repositório do site',default='plataforma-de-evangelizacao/site'),'backup_repo':ask('Repositório PRIVADO de backup',default='plataforma-de-evangelizacao/backup'),'site_url':ask('URL pública',default='https://plataforma-de-evangelizacao.github.io/site/')}
 google_vault=P(path).parent/'google.enc'
 google=load_credentials(google_vault,password) if google_vault.exists() else {}
 c.update(google)
 for key,label in [('github_token','Token GitHub de backup/recuperação'),('database_url','Conexão PostgreSQL direta ou session pooler do Supabase'),('supabase_url','URL do Supabase'),('supabase_service_role_key','Chave de serviço Supabase'),('supabase_publishable_key','Chave pública Supabase'),('google_client_id','Google OAuth Client ID'),('google_client_secret','Google OAuth Client Secret'),('google_refresh_token','Google OAuth Refresh Token'),('drive_folder_id','ID da pasta PRIVADA do Drive')]:
  if key not in c:c[key]=ask(label,True)
 c['github_secrets']={}
 for name in ['SUPABASE_ACCESS_TOKEN','PLATFORM_DISPATCH_TOKEN','YOUTUBE_API_KEY']:c['github_secrets'][name]=ask('Valor local de '+name+' (vazio se indisponível)',True)
 seal_credentials(path,c,password);LOG.emit('Configuração criptografada','ok',str(path))
def install_deps():
 if sys.platform.startswith('linux') and P('/etc/os-release').exists() and 'ubuntu' in P('/etc/os-release').read_text().lower():
  LOG.emit('Dependências Ubuntu','info','Somente instalação; não executa upgrade do sistema. O sudo poderá pedir confirmação local.')
  release=dict(line.split('=',1) for line in P('/etc/os-release').read_text().splitlines() if '='in line);codename=release.get('VERSION_CODENAME','').strip('"')
  if codename not in ('jammy','noble'):raise Failure('Instalação automática validada para Ubuntu 22.04/24.04. Instale as dependências do seu sistema manualmente.')
  run(['sudo','apt-get','update']);run(['sudo','apt-get','install','-y','git','ca-certificates','python3-venv'])
  with tempfile.TemporaryDirectory(prefix='pge-pgdg-') as tmp:
   key=P(tmp)/'postgresql.asc';key.write_bytes(http('https://www.postgresql.org/media/keys/ACCC4CF8.asc',raw=True))
   run(['sudo','install','-d','/usr/share/postgresql-common/pgdg']);run(['sudo','install','-m','644',str(key),'/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc'])
   line='deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt '+codename+'-pgdg main\n'
   run(['sudo','tee','/etc/apt/sources.list.d/pge-pgdg.list'],input=line.encode())
  run(['sudo','apt-get','update']);run(['sudo','apt-get','install','-y','postgresql-client-17'])
 else:LOG.emit('Dependências','info','Instale Git e o cliente PostgreSQL para seu sistema; as bibliotecas Python serão isoladas.')
 venv=P.home()/'.pge-recovery-venv';run([sys.executable,'-m','venv',str(venv)]);python=venv/('Scripts/python.exe' if os.name=='nt' else 'bin/python');run([str(python),'-m','pip','install','cryptography>=43,<47','PyNaCl>=1.5,<2']);LOG.emit('Ambiente Python pronto','ok',str(python));LOG.emit('PostgreSQL','info','pg_dump precisa ter versão igual ou superior à do servidor. Se o cliente da distribuição for antigo, instale o cliente correspondente e ajuste PATH; o script falha sem produzir um falso sucesso.')
def parser():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--config',default=str(P.home()/'.config/pge-recovery/credentials.enc'));sub=p.add_subparsers(dest='command',required=True)
 sub.add_parser('configure');ga=sub.add_parser('authorize-drive');ga.add_argument('--client-json',required=True);ga.add_argument('--output',default=str(P.home()/'.config/pge-recovery/google.enc'));sub.add_parser('install-deps');sub.add_parser('doctor');sch=sub.add_parser('schedule');sch.add_argument('--hour',type=int,default=20);sch.add_argument('--output',default=str(P.home()/'PGE-Backups'))
 b=sub.add_parser('backup');b.add_argument('--output',default=str(P.home()/'PGE-Backups'));b.add_argument('--no-drive',action='store_true')
 v=sub.add_parser('verify');v.add_argument('snapshot')
 r=sub.add_parser('restore');r.add_argument('snapshot');r.add_argument('--target-repo',required=True);r.add_argument('--target-db-env',default='PGE_RESTORE_DATABASE_URL');r.add_argument('--target-supabase-config');r.add_argument('--execute',action='store_true');r.add_argument('--test-login',action='store_true')
 f=sub.add_parser('fetch');f.add_argument('--drive-folder');f.add_argument('--github',action='store_true');f.add_argument('--output',required=True)
 return p
def main(argv=None):
 args=parser().parse_args(argv)
 try:
  if args.command=='install-deps':install_deps();return 0
  password=master();dependencies()
  if args.command=='authorize-drive':authorize_drive(args.client_json,args.output,password);return 0
  if args.command=='configure':configure(args.config,password);return 0
  if args.command=='verify':
   with tempfile.TemporaryDirectory(prefix='pge-integrity-') as tmp:manifest=decrypt_tree(args.snapshot,tmp,password);LOG.emit('Integridade de todos os arquivos','ok',str(len(manifest['files'])))
   return 0
  c=load_credentials(args.config,password)
  if args.command=='schedule':schedule(args.config,args.output,args.hour,password)
  elif args.command=='doctor':doctor(c)
  elif args.command=='backup':backup(c,args.output,password,args.no_drive)
  elif args.command=='restore':
   target_db=os.environ.get(args.target_db_env,'')
   if args.execute and not target_db:target_db=getpass.getpass('Conexão PostgreSQL do projeto de TESTE (oculta): ')
   if args.test_login:
    os.environ['PGE_TEST_EMAIL']=input('E-mail do usuário restaurado: ').strip();os.environ['PGE_TEST_PASSWORD']=getpass.getpass('Senha do usuário restaurado (oculta): ')
   restore(c,args.snapshot,password,args.target_repo,target_db,args.execute,args.target_supabase_config)
  elif args.command=='fetch':
   if args.drive_folder:Drive(c).download(args.drive_folder,args.output)
   elif args.github:
    with tempfile.TemporaryDirectory(prefix='pge-fetch-') as tmp:
     mirror=P(tmp)/'backup.git';GitHub(c).clone(c['backup_repo'],mirror)
     for name in run(['git','-C',str(mirror),'ls-tree','-r','--name-only','HEAD']).decode().splitlines():
      if '..' in P(name).parts or P(name).is_absolute():raise Failure('Caminho inválido no backup remoto.')
      private_write(P(args.output)/name,run(['git','-C',str(mirror),'show','HEAD:'+name]))
   else:raise Failure('Escolha --drive-folder ou --github.')
   LOG.emit('Backup remoto baixado','ok',args.output)
  return 0
 except (Failure,KeyboardInterrupt,ValueError,KeyError,OSError) as e:LOG.emit('Operação interrompida','failed',str(e) if isinstance(e,Failure) else type(e).__name__+'; operação não concluída. Verifique configuração e permissões locais.');return 1
 finally:
  # Report intentionally contains no credentials, database URL or raw provider errors.
  try:LOG.save(P.cwd()/'pge-recovery-report.json')
  except OSError:pass
if __name__=='__main__':sys.exit(main())
