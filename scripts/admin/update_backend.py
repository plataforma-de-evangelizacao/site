"""Deploy versioned backend from trusted main. Management credential never enters the site."""
import argparse,datetime as dt,hashlib,json,os,re,sys,time,uuid
from pathlib import Path
from urllib import request,error
from sync import Client
from telemetry import Reporter
ROOT=Path(__file__).resolve().parents[2]
class Failure(Exception):pass
def quote(s):return "'"+str(s).replace("'","''")+"'"
def inner(sql):
 # Shipped migrations have exactly one outer transaction. Inner function blocks remain intact.
 first=re.search(r'(?im)^begin;\s*',sql);last=re.search(r'(?im)^commit;\s*$',sql)
 if not first or not last or last.start()<first.end():raise Failure('invalid_migration_transaction')
 return sql[first.end():last.start()]
def load_release(root=ROOT):
 root=Path(root).resolve();release=json.loads((root/'backend/release.json').read_text());seen=set();items=[]
 if not re.fullmatch(r'[0-9.]+',release['version']):raise Failure('invalid_release')
 for item in release['migrations']:
  version=item['version'];path=(root/item['path']).resolve()
  if not re.fullmatch(r'[0-9]{10,16}',version) or version in seen or not path.is_relative_to(root) or path.suffix!='.sql':raise Failure('invalid_migration_manifest')
  raw=path.read_bytes();digest=hashlib.sha256(raw).hexdigest()
  if digest!=item['sha256']:raise Failure('migration_file_checksum_mismatch')
  seen.add(version);items.append({**item,'sql':raw.decode(),'checksum':digest})
 if not items:raise Failure('empty_migration_manifest')
 if [x['version'] for x in items]!=sorted(seen):raise Failure('unordered_migrations')
 if release.get('function')!='supabase/functions/admin-dispatch/index.ts':raise Failure('invalid_function_path')
 if "RELEASE='"+release['version']+"'" not in (root/release['function']).read_text():raise Failure('function_release_mismatch')
 public=json.loads((root/'admin/release.json').read_text())
 if public.get('version')!=release['version'] or public.get('migrations')!=[x['version'] for x in items]:raise Failure('frontend_release_mismatch')
 return release,items

def migration_bundle(items):
 bootstrap=inner((ROOT/'scripts/admin/maintenance.sql').read_text())
 parts=['begin;','select pg_advisory_xact_lock(842736201);',bootstrap]
 allowed=','.join(quote(x['version']) for x in items)
 parts.append("do $pge_guard_versions$ begin if exists(select 1 from public.pge_backend_migrations where version not in ("+allowed+")) then raise exception 'package_older_than_database'; end if; end; $pge_guard_versions$;")
 for item in items:
  v=item['version'];checksum=item['checksum'];tag='$pge_migrate_'+v+'$';body=inner(item['sql'])
  if tag in body:raise Failure('invalid_migration_delimiter')
  parts.append(f'''do {tag}
begin
 if exists(select 1 from public.pge_backend_migrations where version={quote(v)} and checksum<>{quote(checksum)}) then raise exception 'migration_checksum_conflict'; end if;
 if not exists(select 1 from public.pge_backend_migrations where version={quote(v)}) then
 {body}
 insert into public.pge_backend_migrations(version,checksum) values({quote(v)},{quote(checksum)});
 end if;
end; {tag};''')
 parts.extend(["notify pgrst,'reload schema';",'commit;']);return '\n'.join(parts)

class Management:
 def __init__(self,project,token,transport=None):self.project=project;self.token=token;self.transport=transport or request.urlopen
 def call(self,path,data=None,content_type='application/json',method='POST'):
  raw=data if isinstance(data,bytes) else json.dumps(data).encode() if data is not None else None
  req=request.Request('https://api.supabase.com/v1/projects/'+self.project+'/'+path,data=raw,method=method,headers={'Authorization':'Bearer '+self.token,'Content-Type':content_type})
  try:
   with self.transport(req,timeout=180) as r:
    body=r.read();return json.loads(body) if body else None
  except error.HTTPError as ex:raise Failure('supabase_management_http_'+str(ex.code)) from None
  except (error.URLError,TimeoutError,OSError):raise Failure('supabase_management_connection_failed') from None
 def migrate(self,release,items):return self.call('database/migrations',{'name':'pge_backend_'+release['version'].replace('.','_'),'query':migration_bundle(items)})
 def secrets(self,github_token):return self.call('secrets',[{'name':'GITHUB_DISPATCH_TOKEN','value':github_token}])
 def deploy(self,source):
  boundary='pge'+uuid.uuid4().hex;metadata=json.dumps({'entrypoint_path':'index.ts','name':'admin-dispatch','verify_jwt':False})
  parts=[f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n{metadata}\r\n'.encode(),f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="index.ts"\r\nContent-Type: application/typescript\r\n\r\n'.encode()+source+f'\r\n--{boundary}--\r\n'.encode()]
  return self.call('functions/deploy?slug=admin-dispatch',b''.join(parts),'multipart/form-data; boundary='+boundary)

def run_url():
 repo=os.getenv('GITHUB_REPOSITORY','');run=os.getenv('GITHUB_RUN_ID','')
 return 'https://github.com/'+repo+'/actions/runs/'+run if re.fullmatch(r'[\w.-]+/[\w.-]+',repo) and run.isdigit() else None

def set_state(client,release,status,stage,progress,message,details=None):
 payload=dict(id=True,target_release=release,status=status,stage=stage,progress=progress,message=message,run_url=run_url(),details=details or {},updated_at=dt.datetime.now(dt.timezone.utc).isoformat())
 if status=='ready':payload['installed_release']=release
 for attempt in range(6):
  try:
   client.call('pge_backend_status','on_conflict=id','POST',payload);return
  except error.HTTPError as ex:
   if ex.code!=404 or attempt==5:raise
   time.sleep(1)

def verify(client,version,items,transport=None,sleep=time.sleep):
 transport=transport or request.urlopen
 for attempt in range(6):
  try:
   rows=client.call('pge_backend_migrations','select=version,checksum');by_id={x['version']:x['checksum'] for x in rows}
   if any(by_id.get(x['version'])!=x['checksum'] for x in items):raise Failure('migration_verification_failed')
   headers={'apikey':client.key}
   if client.key.count('.')==2:headers['Authorization']='Bearer '+client.key
   req=request.Request(client.url+'/functions/v1/admin-dispatch?health=1',headers=headers)
   with transport(req,timeout=20) as response:health=json.load(response)
   if health.get('release')==version and health.get('dispatchReady') is True:return
  except Failure:raise
  except (error.HTTPError,error.URLError,ValueError,TimeoutError,OSError):pass
  if attempt<5:sleep(2)
 raise Failure('backend_health_not_confirmed')

def authorize_request(client):
 id=os.getenv('ADMIN_REQUEST','')
 if not id:return
 if not re.fullmatch(r'[0-9a-f-]{36}',id):raise Failure('invalid_request_id')
 rows=client.call('pge_commands','id=eq.'+id+'&select=*')
 if not rows or rows[0]['action']!='run_sync' or rows[0]['payload'].get('target')!='platform-update' or rows[0]['status'] not in ['pending','processing']:raise Failure('invalid_maintenance_request')
 if not client.call('pge_admins','user_id=eq.'+rows[0]['user_id']+'&select=user_id'):raise Failure('administrator_revoked')

def finish_command(client,ok,reason,version):
 id=os.getenv('ADMIN_REQUEST','')
 if not re.fullmatch(r'[0-9a-f-]{36}',id):return
 rows=client.call('pge_commands','id=eq.'+id+'&select=result,status,action,payload')
 if not rows or rows[0].get('action')!='run_sync' or rows[0].get('payload',{}).get('target')!='platform-update' or rows[0]['status'] in ['applied','failed','conflict']:return
 try:old=json.loads(rows[0].get('result') or '{}')
 except ValueError:old={}
 info={**old,'stage':'complete' if ok else 'failed','phase':reason,'heartbeat':dt.datetime.now(dt.timezone.utc).isoformat(),'release':version,'url':run_url()}
 info['finishedAt']=info['heartbeat']
 if ok:info['progress']=100
 else:info['error']=reason
 client.call('pge_commands','id=eq.'+id,'PATCH',dict(status='applied' if ok else 'failed',result=json.dumps(info,ensure_ascii=False),updated_at=info['heartbeat']))

def main():
 reporter=Reporter();client=Client();version='';state_available=False
 try:
  release,items=load_release();version=release['version'];authorize_request(client)
  reporter.emit('Validando o pacote e as permissões do backend',stage='backend_package',progress=15,force=True)
  token=os.getenv('SUPABASE_ACCESS_TOKEN','');github=os.getenv('GITHUB_DISPATCH_TOKEN','')
  if not token or not github:raise Failure('configure_github_secrets_SUPABASE_ACCESS_TOKEN_and_PLATFORM_DISPATCH_TOKEN')
  if not client.url or not client.key:raise Failure('configure_existing_SUPABASE_URL_and_SUPABASE_SERVICE_ROLE_KEY')
  project=client.url.removeprefix('https://').removesuffix('.supabase.co');manager=Management(project,token)
  reporter.emit('Aplicando somente migrações pendentes no Supabase',stage='migrations',progress=30,force=True)
  manager.migrate(release,items);state_available=True
  set_state(client,version,'processing','functions',65,'Banco atualizado. Configurando as funções do backend.')
  reporter.emit('Banco atualizado. Publicando funções de integração.',stage='functions',progress=65,stats={'migrationCount':len(items)},force=True)
  manager.secrets(github);manager.deploy((ROOT/release['function']).read_bytes())
  reporter.emit('Verificando versões e resposta da integração publicada',stage='backend_verify',progress=90,force=True)
  set_state(client,version,'processing','backend_verify',90,'Verificando o backend publicado.')
  verify(client,version,items)
  set_state(client,version,'ready','complete',100,'Backend atualizado. Pode continuar usando a plataforma.',{'migrationCount':len(items),'functionReady':True})
  finish_command(client,True,'Backend atualizado e integração verificada.',version)
  print('Backend atualizado e verificado: '+version);return 0
 except Exception as ex:
  reason=str(ex) if isinstance(ex,Failure) else 'backend_update_failed_'+type(ex).__name__
  if state_available:
   try:set_state(client,version,'failed','failed',0,reason)
   except Exception:pass
  try:finish_command(client,False,reason,version)
  except Exception:pass
  print('Atualização interrompida: '+reason);return 1
def record_workflow_failure():
 client=Client()
 if not client.url or not client.key:return 0
 version=''
 try:
  release,_=load_release();version=release['version'];rows=client.call('pge_backend_status','id=eq.true&select=status,run_url')
  if run_url() and rows and rows[0]['status']=='processing' and rows[0].get('run_url')==run_url():set_state(client,version,'failed','failed',0,'workflow_failed_or_interrupted')
 except Exception:print('O diagnóstico detalhado permanece no GitHub Actions.')
 try:finish_command(client,False,'workflow_failed_or_interrupted',version)
 except Exception:print('O resultado será reconciliado pelo painel.')
 return 0
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--record-failure',action='store_true');args=parser.parse_args();sys.exit(record_workflow_failure() if args.record_failure else main())
