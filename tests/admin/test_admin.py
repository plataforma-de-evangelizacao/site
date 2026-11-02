import base64,re,copy,datetime as dt,importlib.util,json,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('admin_sync',ROOT/'scripts/admin/sync.py');bridge=importlib.util.module_from_spec(spec);spec.loader.exec_module(bridge)
ID='abc123def45'
def safe_public_config(cfg):
 if not isinstance(cfg,dict) or set(cfg)-{'supabaseUrl','publishableKey','siteUrl'}:return False
 url=cfg.get('supabaseUrl','');key=cfg.get('publishableKey','')
 if not isinstance(url,str) or not isinstance(key,str):return False
 if url and not re.fullmatch(r'https://[a-z0-9-]+\.supabase\.co',url):return False
 if not key:return True # Configuration may still be pending; runtime login stays disabled.
 if key.startswith('sb_publishable_'):
  return key.count('sb_publishable_')==1 and bool(re.fullmatch(r'sb_publishable_[A-Za-z0-9_-]{20,512}',key))
 try:
  parts=key.split('.')
  if len(parts)!=3:return False
  payload=json.loads(base64.urlsafe_b64decode(parts[1]+'='*((-len(parts[1]))%4)))
  return payload.get('role')=='anon' # Format check only; provider verifies signatures at runtime.
 except (ValueError,TypeError,UnicodeError):return False

class AdminTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name);self.old=bridge.ROOT;bridge.ROOT=self.root;self.addCleanup(setattr,bridge,'ROOT',self.old)
  (self.root/'biblioteca-controle').mkdir();(self.root/'biblioteca-controle/editorial.json').write_text('{}\n')
  (self.root/'dados').mkdir();(self.root/'dados/projetos.json').write_text('{"itens": []}\n')
  self.records={ID:dict(id=ID,sha='v1')}
 def command(self,decision='approved'):
  return dict(action='review_video',payload=dict(id=ID,expected_sha='v1',decision=decision,categoria='desenho',portuguese_confirmed=True))
 def test_approval_produces_editorial(self):
  path,text=bridge.apply_command(self.command(),self.records);entry=json.loads(text)[ID];self.assertEqual(path,'biblioteca-controle/editorial.json');self.assertTrue(entry['revisado']);self.assertEqual(entry['aprovacao'],'approved')
 def test_rejection(self):self.assertEqual(json.loads(bridge.apply_command(self.command('rejected'),self.records)[1])[ID]['aprovacao'],'rejected')
 def test_unconfirmed_language_rejected(self):
  c=self.command();c['payload']['portuguese_confirmed']=False
  with self.assertRaisesRegex(ValueError,'confirm_portuguese'):bridge.apply_command(c,self.records)
 def test_bad_id_rejected(self):
  c=self.command();c['payload']['id']='../../secret'
  with self.assertRaises(ValueError):bridge.apply_command(c,self.records)
 def test_stale_record_rejected(self):
  c=self.command();c['payload']['expected_sha']='old'
  with self.assertRaisesRegex(ValueError,'conflict'):bridge.apply_command(c,self.records)
 def test_invalid_decision(self):
  with self.assertRaises(ValueError):bridge.apply_command(self.command('execute'),self.records)
 def test_invalid_category(self):
  c=self.command();c['payload']['categoria']='javascript'
  with self.assertRaises(ValueError):bridge.apply_command(c,self.records)
 def test_file_allowlist(self):
  for path in ['.github/workflows/admin.yml','../secret','.env','admin/config.json','scripts/admin/sync.py','dados/../admin/config.json']:
   with self.subTest(path=path),self.assertRaises(ValueError):bridge.apply_command(dict(action='save_json',payload=dict(path=path)),{})
 def doc(self,text='{"itens": []}',expected=None):
  return dict(action='save_json',payload=dict(path='dados/projetos.json',expected_sha=expected or bridge.sha((self.root/'dados/projetos.json').read_text()),content=text))
 def test_json_syntax_rejected(self):
  with self.assertRaises(ValueError):bridge.apply_command(self.doc('{broken'),{})
 def test_document_version_conflict(self):
  with self.assertRaisesRegex(ValueError,'conflict'):bridge.apply_command(self.doc(expected='old'),{})
 def test_document_size_limit(self):
  with self.assertRaises(ValueError):bridge.apply_command(self.doc('x'*1048577),{})
 def test_save_json_keeps_original_until_commit(self):
  path,text=bridge.apply_command(self.doc('{"itens": [1]}'),{});self.assertEqual((self.root/path).read_text(),'{"itens": []}\n');self.assertEqual(json.loads(text)['itens'],[1])
 def test_expired_provider_metadata_not_exported(self):
  state={'records':{ID:{'id':ID,'titulo':'Fixture'}},'checks':{ID:{'verified':(dt.datetime.now(dt.timezone.utc)-dt.timedelta(days=30)).isoformat()}}};self.assertEqual(bridge.snapshot(state),[])
 def test_export_strips_sensitive_internal_fields(self):
  state={'records':{ID:{'id':ID,'titulo':'Fixture','raw':'PRIVATE','secret':'PRIVATE'}},'checks':{ID:{'verified':dt.datetime.now(dt.timezone.utc).isoformat()}}};out=bridge.snapshot(state)[0];self.assertNotIn('raw',out['record']);self.assertNotIn('secret',out['record'])
 def test_sql_rls_and_no_public_admin_enrollment(self):
  sql=(ROOT/'scripts/admin/schema.sql').read_text()
  for table in ['pge_admins','pge_videos','pge_documents','pge_commands']:self.assertIn('alter table public.'+table+' enable row level security',sql)
  self.assertNotIn('grant insert on public.pge_admins to authenticated',sql);self.assertIn('grant insert(id,user_id,action,payload)',sql);self.assertIn("status='pending'",sql)
 def test_no_credentials_in_frontend_config(self):
  cfg=json.loads((ROOT/'admin/config.json').read_text())
  self.assertTrue(safe_public_config(cfg),'admin/config.json: use somente Project URL e uma chave pública Publishable/anon, copiada uma vez; nunca uma chave secreta.')
 def test_no_browser_token_persistence(self):
  js=(ROOT/'admin/admin.js').read_text();self.assertNotIn('localStorage',js);self.assertNotIn('sessionStorage',js);self.assertNotIn('innerHTML',js)
 def test_artifact_excludes_admin_controls(self):
  sys.path.insert(0,str(ROOT/'scripts/biblioteca'));from run import build_site
  build_site(ROOT,self.root/'artifact');self.assertTrue((self.root/'artifact/admin/index.html').exists());self.assertFalse((self.root/'artifact/scripts/admin/schema.sql').exists());self.assertFalse((self.root/'artifact/biblioteca-controle').exists())
if __name__=='__main__':unittest.main()

class QueueTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name);self.oldroot=bridge.ROOT;bridge.ROOT=self.root;self.addCleanup(setattr,bridge,'ROOT',self.oldroot)
  (self.root/'biblioteca-controle').mkdir();(self.root/'biblioteca-controle/editorial.json').write_text('{}')
  self.oldgit=bridge.git;self.oldvalidate=bridge.validate_change;self.addCleanup(setattr,bridge,'git',self.oldgit);self.addCleanup(setattr,bridge,'validate_change',self.oldvalidate)
  old_reviews=bridge.current_reviews;self.addCleanup(setattr,bridge,'current_reviews',old_reviews);bridge.current_reviews=lambda:[dict(id=ID,sha='v1')]
  self.calls=[];bridge.git=lambda *args:self.calls.append(args) or '';bridge.validate_change=lambda *a:None
  self.command={'id':'11111111-1111-4111-8111-111111111111','user_id':'owner','action':'review_video','payload':{'id':ID,'expected_sha':'v1','decision':'rejected'}}
  outer=self
  class Fake:
   def __init__(self):self.patches=[]
   def call(self,table,query='',method='GET',data=None):
    if method=='PATCH':self.patches.append(data);return []
    return [outer.command] if table=='pge_commands' else [{'user_id':'owner'}] if table=='pge_admins' else [{'id':ID,'sha':'v1'}]
  self.client=Fake()
 def test_revoked_admin_cannot_change_git(self):
  self.command['user_id']='revoked';result=bridge.process(self.client);self.assertEqual(result['applied'],0);self.assertFalse(any(c[0]=='push' for c in self.calls));self.assertEqual(self.client.patches[-1]['result'],'administrator_revoked')
 def test_valid_command_commits_without_force(self):
  result=bridge.process(self.client);self.assertEqual(result['applied'],1);push=next(c for c in self.calls if c[0]=='push');self.assertEqual(push,('push','origin','HEAD:main'))
 def test_push_failure_leaves_recoverable_processing(self):
  def fail(*args):
   if args[0]=='push':raise RuntimeError('simulated')
   return ''
  bridge.git=fail
  with self.assertRaises(RuntimeError):bridge.process(self.client)
  self.assertEqual(self.client.patches[-1]['status'],'processing')
 def test_committed_command_is_not_reapplied(self):
  def committed(*args):self.calls.append(args);return 'pge-admin:'+self.command['id'] if args[0]=='log' else ''
  bridge.git=committed;bridge.process(self.client);self.assertEqual(self.client.patches[-1]['status'],'applied');self.assertFalse(any(c[0]=='push' for c in self.calls))

class PublicConfigTests(unittest.TestCase):
 def config(self,key=''):
  return {'supabaseUrl':'https://fixture-project.supabase.co','publishableKey':key,'siteUrl':'../'}
 def test_empty_template_allowed(self):self.assertTrue(safe_public_config(self.config()))
 def test_configured_publishable_allowed(self):self.assertTrue(safe_public_config(self.config('sb_publishable_'+'a'*32)))
 def test_duplicate_paste_rejected(self):
  key='sb_publishable_'+'a'*32;self.assertFalse(safe_public_config(self.config(key+key)))
 def test_secret_or_password_rejected(self):
  self.assertFalse(safe_public_config(self.config('sb_secret_'+'a'*32)))
  cfg=self.config();cfg['password']='fixture-not-a-password';self.assertFalse(safe_public_config(cfg))
 def test_legacy_roles(self):
  def jwt(role):return 'header.'+base64.urlsafe_b64encode(json.dumps({'role':role}).encode()).decode().rstrip('=')+'.signature'
  self.assertTrue(safe_public_config(self.config(jwt('anon'))));self.assertFalse(safe_public_config(self.config(jwt('service_role'))))
